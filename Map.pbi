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
  

Global.TMapDirection Map_Direction_Up, Map_Direction_Right, Map_Direction_Down, Map_Direction_Left, Map_Direction_None
Global Dim Map_All_Directions.TMapDirection(#MAP_NUM_DIRECTIONS - 1)

Map_All_Directions(#MAP_DIRECTION_UP)\x = 0 : Map_All_Directions(#MAP_DIRECTION_UP)\y = -1

Map_All_Directions(#MAP_DIRECTION_RIGHT)\x = 1 : Map_All_Directions(#MAP_DIRECTION_RIGHT)\y = 0

Map_All_Directions(#MAP_DIRECTION_DOWN)\x = 0 : Map_All_Directions(#MAP_DIRECTION_DOWN)\y = 1

Map_All_Directions(#MAP_DIRECTION_LEFT)\x = -1 : Map_All_Directions(#MAP_DIRECTION_LEFT)\y = 0

Map_All_Directions(#MAP_DIRECTION_NONE)\x = 0 : Map_All_Directions(#MAP_DIRECTION_NONE)\y = 0


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

Procedure IsTileWalkable(*GameMap.TMap, TileX.w, TileY.w)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable
  
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