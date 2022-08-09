XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration
  #TILE_UNBREAKABLE_WALL
  #TILE_WALKABLE_PATH
  #TILE_BREAKABLE_WALL_1
EndEnumeration

Enumeration EMapDirections
  #MAP_DIRECTION_UP
  #MAP_DIRECTION_RIGHT
  #MAP_DIRECTION_DOWN
  #MAP_DIRECTION_LEFT
  #MAP_DIRECTION_NONE
EndEnumeration

#MAP_NUM_DIRECTIONS = 5
#MAP_NUM_LOOKING_DIRECTIONS = 4

Structure TTile
  Walkable.a
  Breakable.a
  DrawOrder.u
  SpriteNum.i
  Health.f
EndStructure

#MAP_GRID_WIDTH = 30
#MAP_GRID_HEIGHT = 30

#MAP_GRID_TILE_WIDTH = 16
#MAP_GRID_TILE_HEIGHT = 16

#MAP_PLAY_AREA_START_X = 1
#MAP_PLAY_AREA_END_X = #MAP_GRID_WIDTH - 2
#MAP_PLAY_AREA_START_Y = 1
#MAP_PLAY_AREA_END_Y = #MAP_GRID_HEIGHT - 2


Structure TMapGrid
  Array TilesGrid.TTile(#MAP_GRID_WIDTH - 1, #MAP_GRID_HEIGHT - 1)
EndStructure


Structure TMap Extends TGameObject
  
  MapGrid.TMapGrid
  
EndStructure

Structure TMapDirection Extends TVector2D
  
EndStructure

Structure TNode
  x.w
  y.w
  *Parent.TNode
  g.w
  h.w
  f.w
EndStructure

Global.TMapDirection Map_Direction_Up, Map_Direction_Right, Map_Direction_Down, Map_Direction_Left, Map_Direction_None
Global Dim Map_All_Directions.TMapDirection(#MAP_NUM_DIRECTIONS - 1)

Map_All_Directions(#MAP_DIRECTION_UP)\x = 0 : Map_All_Directions(#MAP_DIRECTION_UP)\y = -1

Map_All_Directions(#MAP_DIRECTION_RIGHT)\x = 1 : Map_All_Directions(#MAP_DIRECTION_RIGHT)\y = 0

Map_All_Directions(#MAP_DIRECTION_DOWN)\x = 0 : Map_All_Directions(#MAP_DIRECTION_DOWN)\y = 1

Map_All_Directions(#MAP_DIRECTION_LEFT)\x = -1 : Map_All_Directions(#MAP_DIRECTION_LEFT)\y = 0

Map_All_Directions(#MAP_DIRECTION_NONE)\x = 0 : Map_All_Directions(#MAP_DIRECTION_NONE)\y = 0

Procedure IsTileWalkable(*GameMap.TMap, TileX.w, TileY.w)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable
  
EndProcedure

Procedure InitNode(*Node.TNode, *Parent.TNode, x.w, y.w)
  *Node\Parent = *Parent
  *Node\x = x
  *Node\y = y
  *Node\g = 0
  *Node\h = 0
  *Node\f = 0
EndProcedure

Procedure.a IsEqualNodes(*Node1.TNode, *Node2.TNode)
  ProcedureReturn Bool((*Node1\x = *Node2\x) And (*Node1\y = *Node2\y))
EndProcedure

Procedure ReversePathList(List PathList.TVector2D(), List ReversedList.TVector2D())
  ClearList(ReversedList())
  
  While ListSize(PathList()) > 0
    LastElement(PathList())
    AddElement(ReversedList())
    ReversedList()\x = PathList()\x
    ReversedList()\y = PathList()\y
    DeleteElement(PathList())
  Wend
  
  
EndProcedure

Procedure AStar(*GameMap.TMap, StartX.w, StartY.w, EndX.w, EndY.w, List PathList.TVector2D())
  ;auxiliary list where all nodes will be allocated
  NewList Nodes.TNode()
  
  ;create the star and end node
  Protected *StartNode.TNode = AddElement(Nodes())
  InitNode(*StartNode, #Null, StartX, StartY)
  
  *StartNode\g = 0
  *StartNode\h = 0
  *StartNode\f = 0
  
  Protected *EndNode.TNode = AddElement(Nodes())
  InitNode(*EndNode, #Null, EndX, EndY)
  *EndNode\g = 0
  *EndNode\h = 0
  *EndNode\f = 0
  
  ;initialize both open and closed lists
  NewList OpenList()
  NewList ClosedList()
  
  AddElement(OpenList())
  OpenList() = *StartNode
  
  ;Adding a stop condition
  Protected OuterIterations = 0
  Protected MaxIterations = #MAP_GRID_WIDTH * #MAP_GRID_HEIGHT / 2
  
  While ListSize(OpenList()) > 0
    
    OuterIterations + 1
    If OuterIterations > MaxIterations
      ;If we hit this point Return the path such As it is
      ;it will Not contain the destination
      ProcedureReturn #False
    EndIf
    
    
    
    ;get the current node
    SelectElement(OpenList(), 0)
    Protected *CurrentNode.TNode = OpenList()
    DeleteElement(OpenList())
    
    AddElement(ClosedList())
    ClosedList() = *CurrentNode
    
    ;found the goal
    If IsEqualNodes(*CurrentNode, *EndNode)
      NewList Path.TVector2D()
      Protected *Current.TNode = *CurrentNode
      While *Current <> #Null
        Protected *NewPathElement.TVector2D = AddElement(Path())
        *NewPathElement\x = *Current\x
        *NewPathElement\y = *Current\y
        
        *Current = *Current\Parent
      Wend
      
      ReversePathList(Path(), PathList())
      ProcedureReturn #True
      
    EndIf
    
    NewList Children()
    
    Protected DirectionIdx.a
    For DirectionIdx = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
      ;get node position
      Protected NodePosition.TVector2D\x = *CurrentNode\x + Map_All_Directions(DirectionIdx)\x
      NodePosition\y = *CurrentNode\y + Map_All_Directions(DirectionIdx)\y
      
      ;make sure within range
      If NodePosition\x < #MAP_PLAY_AREA_START_X Or NodePosition\x > #MAP_PLAY_AREA_END_X
        Continue
      EndIf
  
      If NodePosition\y < #MAP_PLAY_AREA_START_Y Or NodePosition\y > #MAP_PLAY_AREA_END_Y
        Continue
      EndIf
      
      ;make sure is walkable tile
      If Not IsTileWalkable(*GameMap, NodePosition\x, NodePosition\y)
        Continue
      EndIf
      
      ;create a new node
      Protected *NewNode.TNode = AddElement(Nodes())
      InitNode(*NewNode, *CurrentNode, NodePosition\x, NodePosition\y)
      
      ;append
      AddElement(Children())
      Children() = *NewNode
      
    Next
    
    
    ForEach Children()
      Protected *Child.TNode = Children()
      
      Protected IsOnClosedList.a = #False
      ForEach ClosedList()
        Protected *ClosedChild.TNode = ClosedList()
        If IsEqualNodes(*Child, *ClosedChild)
          IsOnClosedList = #True
          Continue
        EndIf
      Next
      If IsOnClosedList
        Continue
      EndIf
      
      
      ;Create the f, g, And h values
      *Child\g = *CurrentNode\g + 1
      *Child\h = Abs(*Child\x - *EndNode\x) + Abs(*Child\y - *EndNode\y)
      *Child\f = *Child\g + *Child\h
      
      ;Child is already in the open List
      Protected IsOnOpenList.a = #False
      ForEach OpenList()
        Protected *OpenNode.TNode = OpenList()
        If IsEqualNodes(*Child, *OpenNode) And *Child\g > *OpenNode\g
          IsOnOpenList = #True
          Continue
        EndIf
      Next
      If IsOnOpenList
        Continue
      EndIf
      
      
      ;add the child to open list
      AddElement(OpenList())
      OpenList() = *Child
      
      
    Next
    
    
    
    
    
  Wend
  
  ProcedureReturn #False
  
  
  
EndProcedure

Procedure.a GetMapDirectionByDeltaSign(DeltaSignX.f, DeltaSignY.f, *ReturnDirection.TMapDirection = #Null)
  Protected IdxDirection.a
  For IdxDirection = #MAP_DIRECTION_UP To #MAP_DIRECTION_NONE
    If Map_All_Directions(IdxDirection)\x = DeltaSignX And Map_All_Directions(IdxDirection)\y = DeltaSignY
      If *ReturnDirection <> #Null
        *ReturnDirection = Map_All_Directions(IdxDirection)
      EndIf
      
      ProcedureReturn IdxDirection
    EndIf
  Next
  
  If *ReturnDirection <> #Null
    *ReturnDirection = Map_All_Directions(#MAP_DIRECTION_NONE)
  EndIf
  ProcedureReturn #MAP_DIRECTION_NONE
  
EndProcedure

Procedure MakeTileWalkable(*GameMap.TMap, TileX.w, TileY.w)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Breakable = #False
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable = #True
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Health = 1.0
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\SpriteNum = #Ground
  
  ProcedureReturn #True
EndProcedure

Procedure IsTileBreakable(*GameMap.TMap, TileX.w, TileY.w)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn *GameMap\MapGrid\TilesGrid(TileX, TileY)\Breakable
EndProcedure

Procedure GetTileCoordsByPosition(*Position.TVector2D, *TileCoords.TVector2D)
  *TileCoords\x = Int(*Position\x / #MAP_GRID_TILE_WIDTH)
  *TileCoords\y = Int(*Position\y / #MAP_GRID_TILE_HEIGHT)
EndProcedure

Procedure.i InitMapGrid(*MapGrid.TMapGrid, MapGridFile.s)
  Protected FileNum = ReadFile(#PB_Any, MapGridFile)
  If FileNum = 0
    ;error reading the mapgridfile
    ProcedureReturn #False
  EndIf
  
  
  Protected LineNum = 0
  While Eof(FileNum) = 0
    Protected Line.s = ReadString(FileNum)
    Protected LineLength = Len(Line)
    Protected Column = 0, ColumnNum = 0
    For Column = 0 To LineLength - 1
      Protected ColumnValue.s = Mid(Line, Column + 1, 1)
      If ColumnValue = ";"
        Continue
      EndIf
      
      Protected ColumnValueInt = Val(ColumnValue)
      
      Select ColumnValueInt
        Case #TILE_UNBREAKABLE_WALL
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Breakable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Walkable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Health = 1.0
          *MapGrid\TilesGrid(ColumnNum, LineNum)\SpriteNum = #UnbreakableWall
        Case #TILE_WALKABLE_PATH
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Breakable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Walkable = #True
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Health = 1.0
          *MapGrid\TilesGrid(ColumnNum, LineNum)\SpriteNum = #Ground
          
        Case #TILE_BREAKABLE_WALL_1
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Breakable = #True
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Walkable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Health = 1.0
          *MapGrid\TilesGrid(ColumnNum, LineNum)\SpriteNum = #BreakableWall1
          
      EndSelect
      
      ColumnNum + 1
      
      
    Next
    
    LineNum + 1
    
  Wend
  
  ProcedureReturn #True
  
EndProcedure

Procedure DrawMap(*GameMap.TMap)
  Protected StartX.f = *GameMap\Position\x
  Protected StartY.f = *GameMap\Position\y
  
  Protected MapX, MapY
  For MapX = 0 To #MAP_GRID_WIDTH - 1
    For MapY = 0 To #MAP_GRID_HEIGHT - 1
      Protected SpriteToDraw = *GameMap\MapGrid\TilesGrid(MapX, MapY)\SpriteNum
      
      If IsSprite(SpriteToDraw)
        DisplayTransparentSprite(SpriteToDraw, StartX + MapX * #MAP_GRID_TILE_WIDTH, StartY + MapY * #MAP_GRID_TILE_HEIGHT)
      EndIf
 
      
      
    Next MapY
  Next MapX
  
  
  
  
EndProcedure

Procedure SetRandomBreakableWallsMap(*GameMap.TMap)
  Protected MapX, MapY
  
  For MapX = #MAP_PLAY_AREA_START_X To #MAP_PLAY_AREA_END_X
    For MapY = #MAP_PLAY_AREA_START_Y To #MAP_PLAY_AREA_END_Y
      If RandomFloat() <= 0.3
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Breakable = #True
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Walkable = #False
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Health = 1.0
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\SpriteNum = #BreakableWall1
      EndIf
      
    Next MapY
    
  Next MapX
  
EndProcedure

Procedure SetTopLeftCornerPlayableByPlayer(*GameMap.TMap)
  ;we need to make sure that the top left corner is walkable like this:
  ;wwwwwwwww...
  ;w##wwwwww...
  ;w#wwwwwww...
  ;wwwwwwwww...
  ;...
  ;the tiles with # should be walkable
  ;*GameMap\MapGrid\TilesGrid(#MAP_PLAY_AREA_START_X, #MAP_PLAY_AREA_START_Y)
  MakeTileWalkable(*GameMap, #MAP_PLAY_AREA_START_X, #MAP_PLAY_AREA_START_Y)
  MakeTileWalkable(*GameMap, #MAP_PLAY_AREA_START_X + 1, #MAP_PLAY_AREA_START_Y)
  MakeTileWalkable(*GameMap, #MAP_PLAY_AREA_START_X, #MAP_PLAY_AREA_START_Y + 1)
  
EndProcedure

Procedure.a GetRandomWalkableTile(*GameMap.TMap, *TileCoords.TVector2D)
  Protected MAX_TRIES = #MAP_GRID_WIDTH * #MAP_GRID_HEIGHT * 1.2
  Protected NumTries = MAX_TRIES
  While NumTries
    Protected TileX.w, TileY.w
    TileX = Random(#MAP_PLAY_AREA_END_X, #MAP_PLAY_AREA_START_X)
    TileY = Random(#MAP_PLAY_AREA_END_Y, #MAP_PLAY_AREA_START_Y)
    If *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable
      *TileCoords\x = TileX
      *TileCoords\y = TileY
      ProcedureReturn #True
    EndIf
    
    NumTries - 1
  Wend
  
  ProcedureReturn #False
  
EndProcedure

Procedure.a GetRandomWalkableDirectionFromOriginTile(*GameMap.TMap, OriginTileX.w, OriginTileY.w)
  Protected i.a
  NewList FreeDirections.a()
  For i = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
    Protected CurrentTileX.w, CurrentTileY.w
    CurrentTileX = OriginTileX + Map_All_Directions(i)\x
    CurrentTileY = OriginTileY + Map_All_Directions(i)\y
    If IsTileWalkable(*GameMap, CurrentTileX, CurrentTileY)
      AddElement(FreeDirections())
      FreeDirections() = i
    EndIf
  Next
  
  If ListSize(FreeDirections()) > 0
    RandomizeList(FreeDirections())
    SelectElement(FreeDirections(), 0)
    ProcedureReturn FreeDirections()
  EndIf
  
  ProcedureReturn #MAP_DIRECTION_NONE
  
  
EndProcedure

Procedure.a GetRandomWalkableTileFromOriginTile(*GameMap.TMap, OriginTileX.w, OriginTileY.w, Direction.a, *ReturnTileCoords.TVector2D)
  If Direction = #MAP_DIRECTION_NONE
    ;no direction to follow
    ProcedureReturn #False
  EndIf
  
  ;TODO: implement this
  NewList RandomTileCoords.TVector2D()
  Protected MapDirection.TMapDirection = Map_All_Directions(Direction)
  
  Protected CurrentTileX.w = OriginTileX + MapDirection\x
  Protected CurrentTileY.w = OriginTileY + MapDirection\y
  
  While IsTileWalkable(*GameMap, CurrentTileX, CurrentTileY)
    ;this current tile in this direction is walkable
    AddElement(RandomTileCoords())
    RandomTileCoords()\x = CurrentTileX
    RandomTileCoords()\y = CurrentTileY
    
    ;update the current tile in the direction given
    CurrentTileX + MapDirection\x
    CurrentTileY + MapDirection\y
    
  Wend
  
  If ListSize(RandomTileCoords()) = 0
    ;no walkable tile found
    ProcedureReturn #False
  EndIf
  
  RandomizeList(RandomTileCoords())
  SelectElement(RandomTileCoords(), 0)
  *ReturnTileCoords\x = RandomTileCoords()\x
  *ReturnTileCoords\y = RandomTileCoords()\y
  
  
  
  
  
  
  
  
EndProcedure


Procedure InitMap(*GameMap.TMap, *Position.TVector2D)
  InitGameObject(*GameMap, *Position, -1, @UpdateGameObject(), @DrawMap(), #True, 1.0, #MapDrawOrder)
  InitMapGrid(@*GameMap\MapGrid, ".\data\maps\main-map-grid.csv")
  SetRandomBreakableWallsMap(*GameMap)
  SetTopLeftCornerPlayableByPlayer(*GameMap)
EndProcedure



DisableExplicit