XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration
  #TILE_UNBREAKABLE_WALL
  #TILE_PASSABLE_PATH
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
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Destructable = #False
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Walkable = #False
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Health = 1.0
          *MapGrid\TilesGrid(LineNum, ColumnNum)\SpriteNum = #UnbreakableWall
        Case #TILE_PASSABLE_PATH
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Destructable = #False
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Walkable = #True
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Health = 1.0
          *MapGrid\TilesGrid(LineNum, ColumnNum)\SpriteNum = #Ground
          
        Case #TILE_BREAKABLE_WALL_1
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Destructable = #True
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Walkable = #False
          *MapGrid\TilesGrid(LineNum, ColumnNum)\Health = 1.0
          *MapGrid\TilesGrid(LineNum, ColumnNum)\SpriteNum = #BreakableWall1
          
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
      If RandomFloat() < 0.25
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Destructable = #True
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Walkable = #False
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\Health = 1.0
        *GameMap\MapGrid\TilesGrid(MapX, MapY)\SpriteNum = #BreakableWall1
      EndIf
      
    Next MapY
    
  Next MapX
  
EndProcedure
  

Procedure InitMap(*GameMap.TMap, *Position.TVector2D)
  InitGameObject(*GameMap, *Position, -1, @UpdateGameObject(), @DrawMap(), #True, 1.0, #MapDrawOrder)
  InitMapGrid(@*GameMap\MapGrid, ".\data\maps\main-map-grid.csv")
  SetRandomBreakableWallsMap(*GameMap)
EndProcedure



DisableExplicit