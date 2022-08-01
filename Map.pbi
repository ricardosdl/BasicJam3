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

Structure TTile
  Walkable.a
  Destructable.a
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

Procedure MakeTileWalkable(*GameMap.TMap, TileX.u, TileY.u)
  If TileX < #MAP_PLAY_AREA_START_X Or TileX > #MAP_PLAY_AREA_END_X
    ProcedureReturn #False
  EndIf
  
  If TileY < #MAP_PLAY_AREA_START_Y Or TileY > #MAP_PLAY_AREA_END_Y
    ProcedureReturn #False
  EndIf
  
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Destructable = #False
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Walkable = #True
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\Health = 1.0
  *GameMap\MapGrid\TilesGrid(TileX, TileY)\SpriteNum = #Ground
  
  ProcedureReturn #True
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
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Destructable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Walkable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Health = 1.0
          *MapGrid\TilesGrid(ColumnNum, LineNum)\SpriteNum = #UnbreakableWall
        Case #TILE_WALKABLE_PATH
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Destructable = #False
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Walkable = #True
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Health = 1.0
          *MapGrid\TilesGrid(ColumnNum, LineNum)\SpriteNum = #Ground
          
        Case #TILE_BREAKABLE_WALL_1
          *MapGrid\TilesGrid(ColumnNum, LineNum)\Destructable = #True
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
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Destructable = #True
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


Procedure InitMap(*GameMap.TMap, *Position.TVector2D)
  InitGameObject(*GameMap, *Position, -1, @UpdateGameObject(), @DrawMap(), #True, 1.0, #MapDrawOrder)
  InitMapGrid(@*GameMap\MapGrid, ".\data\maps\main-map-grid.csv")
  SetRandomBreakableWallsMap(*GameMap)
  SetTopLeftCornerPlayableByPlayer(*GameMap)
EndProcedure



DisableExplicit