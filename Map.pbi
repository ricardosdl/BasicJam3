XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "DrawText.pbi"
XIncludeFile "Resources.pbi"

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
  
  #MAP_DIRECTION_UP_RIGHT
  #MAP_DIRECTION_DOWN_RIGHT
  #MAP_DIRECTION_DOWN_LEFT
  #MAP_DIRECTION_UP_LEFT
  
EndEnumeration

#MAP_NUM_DIRECTIONS = 9
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

#MAP_GRID_TILE_WIDTH = 16 * #SPRITES_ZOOM
#MAP_GRID_TILE_HEIGHT = 16 * #SPRITES_ZOOM
#MAP_GRID_TILE_HALF_WIDTH = #MAP_GRID_TILE_WIDTH / 2
#MAP_GRID_TILE_HALF_HEIGHT = #MAP_GRID_TILE_HEIGHT / 2

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

Map_All_Directions(#MAP_DIRECTION_UP_RIGHT)\x = 1 : Map_All_Directions(#MAP_DIRECTION_UP_RIGHT)\y = -1

Map_All_Directions(#MAP_DIRECTION_DOWN_RIGHT)\x = 1 : Map_All_Directions(#MAP_DIRECTION_DOWN_RIGHT)\y = 1

Map_All_Directions(#MAP_DIRECTION_DOWN_LEFT)\x = -1 : Map_All_Directions(#MAP_DIRECTION_DOWN_LEFT)\y = 1

Map_All_Directions(#MAP_DIRECTION_UP_LEFT)\x = -1 : Map_All_Directions(#MAP_DIRECTION_UP_LEFT)\y = -1

Procedure IsTileWalkable(*GameMap.TMap, TileX.w, TileY.w)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable
  
EndProcedure

Procedure GetTileCoordsByPosition(*Position.TVector2D, *TileCoords.TVector2D)
  *TileCoords\x = Int(*Position\x / #MAP_GRID_TILE_WIDTH)
  *TileCoords\y = Int(*Position\y / #MAP_GRID_TILE_HEIGHT)
EndProcedure

Procedure.a IsPositionOnMap(*GameMap.TMap, *Position.TVector2D, *ReturnMapCoords.TVector2D)
  Protected MinMapPositionX.w = *GameMap\Position\x
  Protected MinMapPositionY.w = *GameMap\Position\y
  
  Protected MaxMapPositionX.w = *GameMap\Position\x + #MAP_GRID_WIDTH * #MAP_GRID_TILE_WIDTH
  Protected MaxMapPositionY.w = *GameMap\Position\y + #MAP_GRID_HEIGHT * #MAP_GRID_TILE_HEIGHT
  
  If *Position\x < MinMapPositionX Or *Position\x > MaxMapPositionX
    ProcedureReturn #False
  EndIf
  
  If *Position\y < MinMapPositionY Or *Position\y > MaxMapPositionY
    ProcedureReturn #False
  EndIf
  
  GetTileCoordsByPosition(*Position, *ReturnMapCoords)
  
  ProcedureReturn #True
  
  
    
  
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

Procedure ReconstructPath(*Node.TNode, List PathList.TVector2d())
  NewList Path.TVector2D()
  Protected *Current.TNode = *Node
  While *Current <> #Null
    Protected *NewPathElement.TVector2D = AddElement(Path())
    *NewPathElement\x = *Current\x
    *NewPathElement\y = *Current\y
    *Current = *Current\Parent
  Wend
  ReversePathList(Path(), PathList())
EndProcedure


Procedure AStar2(*GameMap.TMap, StartX.w, StartY.w, EndX.w, EndY.w, List PathList.TVector2D())
  ;list of TNodes that we use to allocate all nodes
  NewList Nodes.TNode()
  
  Protected *StartNode.TNode = AddElement(Nodes())
  InitNode(*StartNode, #Null, StartX, StartY)
  
  Protected *EndNode.TNode = AddElement(Nodes())
  InitNode(*EndNode, #Null, EndX, EndY)
  
  If Not IsTileWalkable(*GameMap, *StartNode\x, *StartNode\y)
    ProcedureReturn #False
  EndIf
  
  If Not IsTileWalkable(*GameMap, *EndNode\x, *EndNode\y)
    ProcedureReturn #False
  EndIf
  
  
  NewList *OpenList.TNode()
  NewList *ClosedList.TNode()
  
  AddElement(*OpenList())
  *OpenList() = *StartNode
  
  Protected.l NumIterations = 0, MaxIterations = #MAP_GRID_WIDTH * #MAP_GRID_HEIGHT / 2
  
  While ListSize(*OpenList()) > 0
    NumIterations + 1
    If NumIterations > MaxIterations
      ProcedureReturn #False
    EndIf
    
    Protected *CurrentElement = SelectElement(*OpenList(), 0)
    Protected *Current.TNode = *OpenList()
    Protected LowestF = *Current\f
    
    ForEach *OpenList()
      If *OpenList()\f < *Current\f
        *Current = *OpenList()
        LowestF = *Current\f
        *CurrentElement = @*OpenList()
      EndIf
    Next
    
    If IsEqualNodes(*Current, *EndNode)
      ReconstructPath(*Current, PathList())
      ProcedureReturn #True
    EndIf
    
    ChangeCurrentElement(*OpenList(), *CurrentElement)
    DeleteElement(*OpenList())
    
    AddElement(*ClosedList())
    *ClosedList() = *Current
    
    NewList *Neighbors.TNode()
    
    Protected DirectionIdx.a
    For DirectionIdx = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
      ;get node position
      Protected NodePosition.TVector2D\x = *Current\x + Map_All_Directions(DirectionIdx)\x
      NodePosition\y = *Current\y + Map_All_Directions(DirectionIdx)\y
      
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
      InitNode(*NewNode, *Current, NodePosition\x, NodePosition\y)
      
      *NewNode\g = *Current\g + 1
      *NewNode\h = Abs(*NewNode\x - *EndNode\x) + Abs(*NewNode\y - *EndNode\y)
      *NewNode\f = *NewNode\g + *NewNode\h
      
      ;append
      AddElement(*Neighbors())
      *Neighbors() = *NewNode
      
    Next
    
    If ListSize(*Neighbors()) = 0
      ;no neighbors proabably menas a surrounded walkable tile
      Continue
    EndIf
    
    
    
    Protected *NeighborCurrentElement = SelectElement(*Neighbors(), 0)
    Protected *CurrentNeighbor.TNode = *Neighbors()
    Protected NeighborLowestF = *CurrentNeighbor\f
    ForEach *Neighbors()
      
      Protected IsOnClosedList.a = #False
      ForEach *ClosedList()
        If IsEqualNodes(*Neighbors(), *ClosedList())
          IsOnClosedList = #True
          Break
        EndIf
      Next
      If IsOnClosedList
        Continue
      EndIf
      
      Protected IsOnOpenList.a = #False
      ForEach *OpenList()
        If IsEqualNodes(*Neighbors(), *OpenList()) And *Neighbors()\g > *OpenList()\g
          IsOnOpenList = #True
          Break
        EndIf
      Next
      If IsOnOpenList
        Continue
      EndIf
      
      AddElement(*OpenList())
      *OpenList() = *Neighbors()
    Next
  Wend
  
  ProcedureReturn #False
  
EndProcedure

Procedure.a GetMapDirectionByDeltaSign(DeltaSignX.f, DeltaSignY.f, *ReturnDirection.TMapDirection = #Null)
  Protected IdxDirection.a
  For IdxDirection = #MAP_DIRECTION_UP To #MAP_DIRECTION_NONE
    If Map_All_Directions(IdxDirection)\x = DeltaSignX And Map_All_Directions(IdxDirection)\y = DeltaSignY
      If *ReturnDirection <> #Null
        *ReturnDirection\x = Map_All_Directions(IdxDirection)\x
        *ReturnDirection\y = Map_All_Directions(IdxDirection)\y
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
        ;can be used to draw the tiles positions
;         Protected.f FontWidth = 3.5, Fontheight = 6
;         Protected PositonText.s = Str(Mapx) + "," + Str(MapY)
;         Protected PositionTextWidth.u = Len(PositonText) * FontWidth
;         Protected FontX.f = (StartX + MapX * #MAP_GRID_TILE_WIDTH) + (#MAP_GRID_TILE_WIDTH / 2) - (PositionTextWidth / 2)
;         Protected FontY.f = (StartY + MapY * #MAP_GRID_TILE_HEIGHT) + (#MAP_GRID_TILE_HEIGHT / 2) - (Fontheight / 2)
;         DrawTextWithStandardFont(FontX, FontY, Str(Mapx) + "," + Str(MapY), FontWidth, Fontheight)
      EndIf
 
      
      
    Next MapY
  Next MapX
  
  ;draw tiles positions
  
  
  
  
  
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

Procedure.a GetRandomWalkableTile(*GameMap.TMap, *TileCoords.TVector2D, NumTries.u = #MAP_GRID_WIDTH * #MAP_GRID_HEIGHT * 1.2)
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

Procedure.a GetListWalkableTilesAroundOriginTile(*GameMap.TMap, *OriginTileCoords.TVector2D, BombPower.f, List SafetyTiles.TVector2D())
  ClearList(SafetyTiles())
  Protected DirectionIdx.a
  
  ;the direction which we'll analyze
  Protected Direction.TMapDirection
  ;the tile coords of candidate safety tile
  Protected CandidateSafetyTile.TVector2D
  
  ;cardinal directions
;   For DirectionIdx = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
;     Direction = Map_All_Directions(DirectionIdx)
;     CandidateSafetyTile\x = *OriginTileCoords\x + (Direction\x * (BombPower + 1))
;     CandidateSafetyTile\y = *OriginTileCoords\y + (Direction\y * (BombPower + 1))
;     
;     If IsTileWalkable(*GameMap, CandidateSafetyTile\x, CandidateSafetyTile\y)
;       AddElement(SafetyTiles())
;       SafetyTiles() = CandidateSafetyTile
;     EndIf
;     
;   Next
  
  ;in-between cardinal directions
  For DirectionIdx = #MAP_DIRECTION_UP_RIGHT To #MAP_DIRECTION_UP_LEFT
    Direction = Map_All_Directions(DirectionIdx)
    ;bombs don't explode in diagonal direction
    CandidateSafetyTile\x = *OriginTileCoords\x + Direction\x
    CandidateSafetyTile\y = *OriginTileCoords\y + Direction\y
    
    If IsTileWalkable(*GameMap, CandidateSafetyTile\x, CandidateSafetyTile\y)
      AddElement(SafetyTiles())
      SafetyTiles() = CandidateSafetyTile
    EndIf
  Next
  
  ProcedureReturn Bool(ListSize(SafetyTiles()) > 0)
EndProcedure

Procedure InitMap(*GameMap.TMap, *Position.TVector2D)
  InitGameObject(*GameMap, *Position, -1, @UpdateGameObject(), @DrawMap(), #True, 1.0, #MapDrawOrder)
  InitMapGrid(@*GameMap\MapGrid, ".\data\maps\main-map-grid.csv")
  SetRandomBreakableWallsMap(*GameMap)
  SetTopLeftCornerPlayableByPlayer(*GameMap)
EndProcedure



DisableExplicit