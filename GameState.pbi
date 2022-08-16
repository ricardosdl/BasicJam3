XIncludeFile "Math.pbi"
XIncludeFile "GameObject.pbi"
XIncludeFile "Enemy.pbi"
XIncludeFile "Player.pbi"
XIncludeFile "Projectile.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "Ground.pbi"
XIncludeFile "DrawText.pbi"
XIncludeFile "Map.pbi"

EnableExplicit

Prototype StartGameStateProc(*GameState)
Prototype EndGameStateProc(*GameState)
Prototype UpdateGameStateProc(*GameState, TimeSlice.f)
Prototype DrawGameStateProc(*GameState)

Enumeration EGameStates
  #NoGameState
  #MainMenuState
  #PlayState
  #GameOverState
EndEnumeration
#NUM_GAME_STATES = 4

#MAX_ENEMIES = 100


Structure TGameState
  GameState.a
  *StartGameState.StartGameStateProc
  *EndGameState.EndGameStateProc
  *UpdateGameState.UpdateGameStateProc
  *DrawGameState.DrawGameStateProc
EndStructure

Structure TGameStateManager
  Array *GameStates.TGameState(#NUM_GAME_STATES - 1)
  CurrentGameState.b
  LastGameState.b
EndStructure

Structure TPlayState Extends TGameState
  GameMap.TMap
  
  Ground.TGround
  
  DrawList.TDrawList
  
  Player.TPlayer
  
  ProjectileList.TProjectileList
  
  Array Enemies.TEnemy(#MAX_ENEMIES - 1)
  
  SelectedStartTile.TVector2D
  SelectedEndTile.TVector2D
  ShowAStar.a
  List AStarPath.TVector2D()
  
  Level.a
  
  
EndStructure

Structure TMainMenuState Extends TGameState
  GameTitle.s
  GameTitleX.f
  GameTitleY.f
  GameTitleFontWidth.f
  GameTitleFontHeight.f
  
  GameStart.s
  GameStartX.f
  GameStartY.f
  GameStartFontWidth.f
  GameStartFontHeight.f
EndStructure

Global GameStateManager.TGameStateManager, PlayState.TPlayState, MainMenuState.TMainMenuState

Procedure DrawCurrentStateGameSateManager(*GameStateManager.TGameStateManager)
  Protected *GameState.TGameState = *GameStateManager\GameStates(*GameStateManager\CurrentGameState)
  *GameState\DrawGameState(*GameState)
EndProcedure

Procedure UpdateCurrentStateGameStateManager(*GameStateManager.TGameStateManager, TimeSlice.f)
  Protected *GameState.TGameState = *GameStateManager\GameStates(*GameStateManager\CurrentGameState)
  *GameState\UpdateGameState(*GameState, TimeSlice)
EndProcedure

Procedure SwitchGameState(*GameStateManager.TGameStateManager, NewGameState.a)
  Protected *CurrentGameState.TGameState = #Null
  If *GameStateManager\CurrentGameState <> #NoGameState
    *CurrentGameState = *GameStateManager\GameStates(*GameStateManager\CurrentGameState)
  EndIf
  
  If *CurrentGameState <> #Null
    *CurrentGameState\EndGameState(*CurrentGameState)
  EndIf
  
  *GameStateManager\LastGameState = *GameStateManager\CurrentGameState
  *GameStateManager\CurrentGameState = NewGameState
  
  Protected *NewGameState.TGameState = *GameStateManager\GameStates(NewGameState)
  *NewGameState\StartGameState(*NewGameState)
EndProcedure

Procedure.i GetInactiveEnemyPlayState(*PlayState.TPlayState)
  Protected i = 0, EnemiesSize = ArraySize(*PlayState\Enemies())
  For i = 0 To EnemiesSize
    Protected *Enemy.TEnemy = @*PlayState\Enemies(i)
    If *Enemy\Active = #False
      ProcedureReturn *Enemy
    EndIf
  Next
  
  ProcedureReturn #Null
  
    
EndProcedure

Procedure InitGroundPlayState(*PlayState.TPlayState)
  InitGround(*PlayState\Ground)
  
  AddDrawItemDrawList(*PlayState\DrawList, *PlayState\Ground)
  
  
EndProcedure

Procedure InitPlayerPlayState(*PlayState.TPlayState)
  Protected PlayerMapCoords.TVector2D\x = 1
  PlayerMapCoords\y = 1
  InitPlayer(@*PlayState\Player, @PlayerMapCoords, #SPRITES_ZOOM, @*PlayState\DrawList, @*PlayState\GameMap, @*PlayState\ProjectileList)
  AddDrawItemDrawList(@*PlayState\DrawList, @*PlayState\Player)
EndProcedure


Procedure InitMapPlayState(*PlayState.TPlayState)
  
  InitDrawList(@*PlayState\DrawList)
  
  Protected MapPosition.TVector2D\x = 0
  MapPosition\y = 0
  InitMap(@*PlayState\GameMap, @MapPosition)
  
  AddDrawItemDrawList(@*PlayState\DrawList, @*PlayState\GameMap)
EndProcedure

Procedure InitEnemiesPlayState(*PlayState.TPlayState)
  Protected NumEnemiesToAdd.a = *PlayState\Level * 1.6
  
  While NumEnemiesToAdd
    Protected *Enemy.TEnemy = GetInactiveEnemyPlayState(*PlayState)
    Protected RandomCoords.TVector2D
    If Not GetRandomWalkableTile(@*PlayState\GameMap, @RandomCoords)
      Continue
    EndIf
    
    If RandomFloat() <= 0.6
      InitEnemyRedArmoredDemon(*Enemy, @*PlayState\Player, @*PlayState\ProjectileList, *PlayState\DrawList, @*PlayState\GameMap,
                               @RandomCoords)
    Else
      InitEnemyRedDemon(*Enemy, @*PlayState\Player, @*PlayState\ProjectileList, @*PlayState\DrawList, @*PlayState\GameMap,
                        @RandomCoords)
    EndIf
    
    
    AddDrawItemDrawList(@*PlayState\DrawList, *Enemy)
    
    NumEnemiesToAdd - 1
    
  Wend
  
  
  
  
  
EndProcedure

Procedure StartPlayState(*PlayState.TPlayState)
  *PlayState\Level = 1
  
  InitMapPlayState(*PlayState)
  
  InitPlayerPlayState(*PlayState)
  
  InitEnemiesPlayState(*PlayState)
  
  *PlayState\SelectedStartTile\x = -1
  *PlayState\SelectedStartTile\y = -1
  
  *PlayState\SelectedEndTile\x = -1
  *PlayState\SelectedEndTile\y = -1
  
  
EndProcedure

Procedure EndPlayState(*PlayState.TPlayState)
EndProcedure

Procedure.a BeatLevelPlayState(*PlayState.TPlayState)
  Protected EnemyIdx.l, EndEnemyIdx.l = ArraySize(*PlayState\Enemies())
  Protected NoActiveEnemy.a = #True
  For EnemyIdx = 0 To EndEnemyIdx
    If *PlayState\Enemies(EnemyIdx)\Active
      NoActiveEnemy = #False
      Break
    EndIf
  Next
  ProcedureReturn NoActiveEnemy
  
EndProcedure

Procedure.a IsGameOverPlayState(*PlayState.TPlayState)
EndProcedure


Procedure UpdatePlayState(*PlayState.TPlayState, TimeSlice.f)
  *PlayState\Player\Update(@*PlayState\Player, TimeSlice)
  
  ForEach *PlayState\ProjectileList\Projectiles()
    If *PlayState\ProjectileList\Projectiles()\Active
      *PlayState\ProjectileList\Projectiles()\Update(@*PlayState\ProjectileList\Projectiles(), TimeSlice)
    EndIf
    
  Next
  
  Protected EnemyIdx, EndEnemiesIdx = ArraySize(*PlayState\Enemies())
  For EnemyIdx = 0 To EndEnemiesIdx
    If *PlayState\Enemies(EnemyIdx)\Active
      *PlayState\Enemies(EnemyIdx)\Update(@*PlayState\Enemies(EnemyIdx), TimeSlice)
    EndIf
    
  Next
  
  If BeatLevelPlayState(*PlayState)
    Debug "beat the current level"
  EndIf
  
  If IsGameOverPlayState(*PlayState)
  EndIf
  
  
  
  
  Protected MousePosition.TVector2D
  
  If MouseButton(#PB_MouseButton_Left)
    MousePosition\x = MouseX()
    MousePosition\y = MouseY()
    
    Protected MouseCoords.TVector2D
    
    
      ;already selected the start tile so we want to change it
      If IsPositionOnMap(@*PlayState\GameMap, @MousePosition, @MouseCoords)
        *PlayState\SelectedStartTile\x = MouseCoords\x
        *PlayState\SelectedStartTile\y = MouseCoords\y
      EndIf
    
  EndIf
  
  If MouseButton(#PB_MouseButton_Right)
    MousePosition\x = MouseX()
    MousePosition\y = MouseY()
    
    
    If IsPositionOnMap(@*PlayState\GameMap, @MousePosition, @MouseCoords)
      *PlayState\SelectedEndTile\x = MouseCoords\x
      *PlayState\SelectedEndTile\y = MouseCoords\y
      
    EndIf
    
    
  EndIf
  
  
  If KeyboardReleased(#PB_Key_Space)
    If *PlayState\ShowAStar
      *PlayState\ShowAStar = #False
    Else
      *PlayState\ShowAStar = #True
    EndIf
    If *PlayState\ShowAStar
      ClearList(*PlayState\AStarPath())
      If Not AStar2(@*PlayState\GameMap, *PlayState\SelectedStartTile\x, *PlayState\SelectedStartTile\y,
                    *PlayState\SelectedEndTile\x, *PlayState\SelectedEndTile\y, *PlayState\AStarPath())
        
        Debug "no path"
        
      EndIf
      
    EndIf
    
  EndIf
  
  
  
  
  
  
;   NewList Path.TVector2d()
;   AStar2(@*PlayState\GameMap, 1, 1, 5, 6, Path())
;   Protected i = 0
;   ForEach Path()
;     i + 1
;     Debug "Node " + Str(i) + ": x " + StrF(Path()\x)
;     Debug "Node " + Str(i) + ": y " + StrF(Path()\y)
;   Next
;   Debug "============"
  
  
  
  
EndProcedure

Procedure DrawPlayState(*PlayState.TPlayState)
  DrawDrawList(*PlayState\DrawList)
  
  ;draw cursor
  Protected DrawCursor.a = #True
  If DrawCursor
    Protected MouseX.l = MouseX()
    Protected MouseY.l = MouseY()
    
    DisplayTransparentSprite(#CursorSprite, MouseX, MouseY)
  EndIf
  
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Outlined)
  If *PlayState\ShowAStar
    ForEach *PlayState\AStarPath()
      Protected XPath.u = *PlayState\GameMap\Position\x + *PlayState\AStarPath()\x * #MAP_GRID_TILE_WIDTH
      Protected YPath.u = *PlayState\GameMap\Position\y + *PlayState\AStarPath()\y * #MAP_GRID_TILE_HEIGHT
      Box(XPath, YPath, #MAP_GRID_TILE_WIDTH, #MAP_GRID_TILE_HEIGHT, RGB(0, 214, 0))
    Next
    
  EndIf
  
  StopDrawing()
  
EndProcedure

Procedure StartMainMenuState(*MainMenuState.TMainMenuState)
  Protected MainMenuHeightOffset.f = ScreenHeight() / 5
  
  ;game title text
  *MainMenuState\GameTitle = "FRUIT WARS v0.9999..."
  *MainMenuState\GameTitleFontWidth = #STANDARD_FONT_WIDTH * (#SPRITES_ZOOM + 2.5)
  *MainMenuState\GameTitleFontHeight = #STANDARD_FONT_HEIGHT * (#SPRITES_ZOOM + 2.5)
  Protected GameTitleWidth.f = Len(*MainMenuState\GameTitle) * *MainMenuState\GameTitleFontWidth
  
  *MainMenuState\GameTitleX = (ScreenWidth() / 2) - GameTitleWidth / 2
  *MainMenuState\GameTitleY = MainMenuHeightOffset
  
  ;start game text
  *MainMenuState\GameStart = "PRESS ENTER TO START"
  *MainMenuState\GameStartFontWidth = #STANDARD_FONT_WIDTH * (#SPRITES_ZOOM)
  *MainMenuState\GameStartFontHeight = #STANDARD_FONT_HEIGHT * (#SPRITES_ZOOM)
  Protected GameStartWidth.f = Len(*MainMenuState\GameStart) * *MainMenuState\GameStartFontWidth
  
  *MainMenuState\GameStartX = (ScreenWidth() / 2) - GameStartWidth / 2
  *MainMenuState\GameStartY = MainMenuHeightOffset + *MainMenuState\GameTitleFontHeight + 40
  
EndProcedure

Procedure EndMainMenuState(*MainMenuState.TMainMenuState)
  
EndProcedure

Procedure UpdateMainMenuState(*MainMenuState.TMainMenuState, TimeSlice.f)
  If KeyboardPushed(#PB_Key_Return)
    SwitchGameState(@GameStateManager, #PlayState)
    ProcedureReturn
  EndIf
  
  
EndProcedure

Procedure DrawMainMenuState(*MainMenuState.TMainMenuState, TimeSlice.f)
  DrawTextWithStandardFont(*MainMenuState\GameTitleX, *MainMenuState\GameTitleY,
                           *MainMenuState\GameTitle, *MainMenuState\GameTitleFontWidth,
                           *MainMenuState\GameTitleFontHeight)
  
  DrawTextWithStandardFont(*MainMenuState\GameStartX, *MainMenuState\GameStartY, *MainMenuState\GameStart,
                           *MainMenuState\GameStartFontWidth, *MainMenuState\GameStartFontHeight)
EndProcedure

Procedure InitGameSates()
  ;@GameStateManager\GameStates(#PlayState)
  PlayState\GameState = #PlayState
  
  PlayState\StartGameState = @StartPlayState()
  PlayState\EndGameState = @EndPlayState()
  PlayState\UpdateGameState = @UpdatePlayState()
  PlayState\DrawGameState = @DrawPlayState()
  
  MainMenuState\GameState = #MainMenuState
  MainMenuState\StartGameState = @StartMainMenuState()
  MainMenuState\EndGameState = @EndMainMenuState()
  MainMenuState\UpdateGameState = @UpdateMainMenuState()
  MainMenuState\DrawGameState = @DrawMainMenuState()
  
  GameStateManager\GameStates(#PlayState) = @PlayState
  GameStateManager\GameStates(#MainMenuState) = @MainMenuState
  
  GameStateManager\CurrentGameState = #NoGameState
  GameStateManager\LastGameState = #NoGameState
  
EndProcedure




DisableExplicit