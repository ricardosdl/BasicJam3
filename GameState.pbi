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
XIncludeFile "Item.pbi"
XIncludeFile "PlayerHUD.pbi"

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
  
  ItemList.TItemList
  
  PlayerHUD.TPlayerHUD
  
  IsGameOver.a
  
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
  Protected MapPosition.TVector2D\x = 0
  MapPosition\y = 0
  InitMap(@*PlayState\GameMap, @MapPosition)
  
  AddDrawItemDrawList(@*PlayState\DrawList, @*PlayState\GameMap)
EndProcedure

Procedure.a SpawnEnemySummoner(*MapCoords.TVector2D)
  Protected *Enemy.TEnemy = GetInactiveEnemyPlayState(PlayState)
  If *Enemy = #Null
    ProcedureReturn #False
  EndIf
  
  If RandomFloat() < 0.5
    InitEnemyRedArmoredDemon(*Enemy, @PlayState\Player, @PlayState\ProjectileList, @PlayState\DrawList, @PlayState\GameMap,
                             *MapCoords)
  Else
    InitEnemyRedDemon(*Enemy, @PlayState\Player, @PlayState\ProjectileList, @PlayState\DrawList, @PlayState\GameMap,
                      *MapCoords)
  EndIf
  
  
  
  
  AddDrawItemDrawList(@PlayState\DrawList, *Enemy)
  
  ProcedureReturn #True
EndProcedure

Procedure.a SpawnEnemy(*MapCoords.TVector2D)
  Protected *Enemy.TEnemy = GetInactiveEnemyPlayState(PlayState)
  If *Enemy = #Null
    ProcedureReturn #False
  EndIf
  
  Protected RandomChance.f = RandomFloat()
  
  If RandomChance < 0.7
    If RandomFloat() < 0.5
      InitEnemyRedArmoredDemon(*Enemy, @PlayState\Player, @PlayState\ProjectileList, @PlayState\DrawList, @PlayState\GameMap,
                               *MapCoords)
    Else
      InitEnemyRedDemon(*Enemy, @PlayState\Player, @PlayState\ProjectileList, @PlayState\DrawList, @PlayState\GameMap,
                        *MapCoords)
    EndIf
    
  Else
    InitEnemySummoner(*Enemy, @PlayState\Player, @PlayState\ProjectileList, @PlayState\DrawList, @PlayState\GameMap,
                      *MapCoords, @SpawnEnemySummoner())
  EndIf
  
  
  AddDrawItemDrawList(@PlayState\DrawList, *Enemy)
  
  ProcedureReturn #True
  
EndProcedure

Procedure InitEnemiesPlayState(*PlayState.TPlayState)
  Protected NumEnemiesToAdd.a = *PlayState\Level * 1.6
  
  Protected RandomCoords.TVector2D
  Protected.TVector2D RangeStart, RangeEnd
  RangeStart\x = #MAP_PLAY_AREA_START_X + 2
  RangeStart\y = #MAP_PLAY_AREA_START_Y + 2
  
  RangeEnd\x = #MAP_PLAY_AREA_END_X
  RangeEnd\y = #MAP_PLAY_AREA_END_Y
  
  While NumEnemiesToAdd
    Protected *Enemy.TEnemy = GetInactiveEnemyPlayState(*PlayState)
    
    
    If Not GetRandomWalkableTileInRange(@*PlayState\GameMap, @RangeStart, @RangeEnd, @RandomCoords)
      Continue
    EndIf
    
    SpawnEnemy(@RandomCoords)
    
    NumEnemiesToAdd - 1
  Wend
  
  
  
  
  
EndProcedure

Procedure ClearItemsPlayState(*PlayState.TPlayState)
  ForEach *PlayState\ItemList\Items()
    *PlayState\ItemList\Items()\Active = #False
  Next
EndProcedure

Procedure InitItemsPlayState(*PlayState.TPlayState)
  
  ClearItemsPlayState(*PlayState)
  
  Dim NumItemTypes.a(#ItemTypeIncreaseBombs)
  
  NumItemTypes(#ItemTypeBombPower) = 2
  NumItemTypes(#ItemTypeIncreaseBombs) = 3
  
  Protected Idx.a
  For Idx = 0 To #ItemTypeIncreaseBombs
    While NumItemTypes(Idx)
      NumItemTypes(Idx) - 1
      
      Protected TileCoords.TVector2D
      
      If Not GetRandomBreakableTile(@*PlayState\GameMap, @TileCoords)
        ;could'nt find a random breakable tile :(
        Continue
      EndIf
      
      Protected *Item.TItem = GetInactiveItem(@*PlayState\ItemList)
      If *Item = #Null
        ;couldn't allocate item :(
        Continue
      EndIf
      
      Select Idx
        Case #ItemTypeBombPower
          InitItemBombPower(*Item, @*PlayState\GameMap, @TileCoords, #False)
        Case #ItemTypeIncreaseBombs
          InitItemIncreaseBombs(*Item, @*PlayState\GameMap, @TileCoords, #False)
      EndSelect
      
      AddDrawItemDrawList(@*PlayState\DrawList, *Item)
      
    Wend
  Next
  
EndProcedure

Procedure InitPlayerHUDPlayState(*PlayState.TPlayState)
  Protected PlayerHUDPos.TVector2D
  PlayerHUDPos\x = #MAP_GRID_WIDTH * #MAP_GRID_TILE_WIDTH + 10
  PlayerHUDPos\y = 10
  InitPlayerHUD(*PlayState\PlayerHUD, *PlayState\Player, @PlayerHUDPos)
  AddDrawItemDrawList(*PlayState\DrawList, @*PlayState\PlayerHUD)
EndProcedure

Procedure StartPlayState(*PlayState.TPlayState)
  
  InitDrawList(@*PlayState\DrawList)
  
  *PlayState\Level = 1
  
  InitMapPlayState(*PlayState)
  
  InitPlayerPlayState(*PlayState)
  
  InitEnemiesPlayState(*PlayState)
  
  InitItemsPlayState(*PlayState)
  
  InitPlayerHUDPlayState(*PlayState)
  
  *PlayState\IsGameOver = #False
  
  *PlayState\SelectedStartTile\x = -1
  *PlayState\SelectedStartTile\y = -1
  
  *PlayState\SelectedEndTile\x = -1
  *PlayState\SelectedEndTile\y = -1
  
  
EndProcedure

Procedure ClearEnemiesPlayState(*PlayState.TPlayState)
  Protected EnemyIdx.a
  For EnemyIdx = 0 To #MAX_ENEMIES - 1
    If *PlayState\Enemies(EnemyIdx)\Active
      KillEnemy(@*PlayState\Enemies(EnemyIdx))
    EndIf
    
  Next
  
  
EndProcedure

Procedure InitProjectilesPlayState(*PlayState.TPlayState)
  ForEach *PlayState\ProjectileList\Projectiles()
    KillProjectile(@*PlayState\ProjectileList\Projectiles())
  Next
EndProcedure

Procedure EndPlayState(*PlayState.TPlayState)
  ClearEnemiesPlayState(*PlayState)
  
  ClearItemsPlayState(*PlayState)
  
  InitProjectilesPlayState(*PlayState)
EndProcedure

Procedure.a BeatLevelPlayState(*PlayState.TPlayState)
  Protected EnemyIdx.l, EndEnemyIdx.l = ArraySize(*PlayState\Enemies())
  
  For EnemyIdx = 0 To EndEnemyIdx
    If *PlayState\Enemies(EnemyIdx)\Active
      ;there still active enemies, not beat the level yet
      ProcedureReturn #False
    EndIf
  Next
  
  ;beat all enemies, let's check if there is explosions
  If IsThereActiveProjectileByType(@*PlayState\ProjectileList, #ProjectileExplosion)
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
  
EndProcedure

Procedure.a IsGameOverPlayState(*PlayState.TPlayState)
  ProcedureReturn Bool(*PlayState\Player\Active = #False)
EndProcedure

Procedure GoToNextLevelPlayState(*PlayState.TPlayState)
  *PlayState\Level + 1
  
  RestartMapGrid(@*PlayState\GameMap)
  
  Protected PlayerMapCoords.TVector2D\x = 1
  PlayerMapCoords\y = 1
  Protected PlayerPosition.TVector2D
  
  SetPlayerMapPosition(@*PlayState\Player, @*PlayState\GameMap, @PlayerMapCoords, @PlayerPosition)
  *PlayState\Player\Position = PlayerPosition
  
  RestartPlayer(@*PlayState\Player, *PlayState\Player\Health, *PlayState\Player\BombPower, *PlayState\Player\CurrentBombsLimit)
  
  InitEnemiesPlayState(*PlayState)
  
  InitItemsPlayState(*PlayState)
  
  InitProjectilesPlayState(*PlayState)
  
  
  
EndProcedure

Procedure CheckExplosionsAgainstEnemies(*PlayState.TPlayState, List *ActiveExplosions.TProjectile())
  Protected EnemyIdx.l, EndEnemyIdx.l = ArraySize(*PlayState\Enemies())
  Protected *Enemy.TEnemy
  For EnemyIdx = 0 To EndEnemyIdx
    *Enemy = @*PlayState\Enemies(EnemyIdx)
    If Not *Enemy\Active
      Continue
    EndIf
    
    ForEach *ActiveExplosions()
      Protected *Explosion.TProjectile = *ActiveExplosions()
      If CheckCollisonProjectileExplosionMiddlePosition(*Explosion, *Enemy)
        HurtEnemy(*Enemy, 1.0)
        Break
      EndIf
      
    Next
    
    
    
  Next
  
EndProcedure

Procedure CheckExplosionsAgainstBombs(*PlayState.TPlayState, List *ActiveExplosions.TProjectile())
  Protected *Bomb.TProjectile
  ForEach *PlayState\ProjectileList\Projectiles()
    *Bomb = @*PlayState\ProjectileList\Projectiles()
    If Not *Bomb\Active
      Continue
    EndIf
    
    If *Bomb\ProjectileType <> #ProjectileBomb1
      Continue
    EndIf
    
    ForEach *ActiveExplosions()
      Protected *Explosion.TProjectile = *ActiveExplosions()
      If CheckCollisonProjectileExplosionMiddlePosition(*Explosion, *Bomb)
        *Bomb\AliveTimer = 0.0;forces explosion on the next game update
        Break
      EndIf
      
    Next
    
    
    
  Next
  
EndProcedure

Procedure CheckExplosionsAgainstPlayer(*PlayState.TPlayState, List *ActiveExplosions.TProjectile())
  ForEach *ActiveExplosions()
    If CheckCollisonProjectileExplosionMiddlePosition(*ActiveExplosions(), @*PlayState\Player)
      HurtPlayer(@*PlayState\Player, 1.0)
    EndIf
  Next
  
EndProcedure

Procedure CheckExplosionAgainstItems(*PlayState.TPlayState, List *ActiveExplosions.TProjectile())
  ForEach *PlayState\ItemList\Items()
    If Not *PlayState\ItemList\Items()\Active
      Continue
    EndIf
    
    ForEach *ActiveExplosions()
      If CheckCollisonProjectileExplosionMiddlePosition(*ActiveExplosions(), *PlayState\ItemList\Items())
        *PlayState\ItemList\Items()\Active = #False
      EndIf
      
    Next
    
    
  Next
  
  
  
EndProcedure

Procedure CheckExplosionsCollisionsPlayState(*PlayState.TPlayState)
  
  NewList *ActiveExplosions.TProjectile()
  
  Protected *Projectile.TProjectile
  ForEach *PlayState\ProjectileList\Projectiles()
    *Projectile = @*PlayState\ProjectileList\Projectiles()
    If Not *Projectile\Active
      Continue
    EndIf
    
    If *Projectile\ProjectileType <> #ProjectileExplosion
      Continue
    EndIf
    
    AddElement(*ActiveExplosions())
    *ActiveExplosions() = *Projectile
  Next
  
  CheckExplosionsAgainstEnemies(*PlayState, *ActiveExplosions())
  
  CheckExplosionsAgainstBombs(*PlayState, *ActiveExplosions())
  
  CheckExplosionsAgainstPlayer(*PlayState, *ActiveExplosions())
  
  CheckExplosionAgainstItems(*PlayState, *ActiveExplosions())
  
    
EndProcedure

Procedure CheckExplodedTilesPlayState(*PlayState.TPlayState)
  If Not *PlayState\GameMap\ExplodedTileAdded
    ProcedureReturn
  EndIf
  
  NewList ExplodedTiles.TVector2D()
  GetExplodedTiles(@*PlayState\GameMap, ExplodedTiles())
  
  ForEach ExplodedTiles()
    ;check items
    ForEach *PlayState\ItemList\Items()
      Protected *Item.TItem = @*PlayState\ItemList\Items()
      If Not *Item\Active
        Continue
      EndIf
      
      If *Item\PositionMapCoords\x = ExplodedTiles()\x And *Item\PositionMapCoords\y = ExplodedTiles()\y
        EnableItem(*Item)
      EndIf
      
      
    Next
    
    If RandomFloat() < 0.1
      Protected *Enemy.TEnemy = GetInactiveEnemyPlayState(*PlayState)
      InitMagnetoBomb(*Enemy, @*PlayState\Player, @PlayState\ProjectileList, @*PlayState\DrawList, @*PlayState\GameMap,
                      @ExplodedTiles())
      AddDrawItemDrawList(@*PlayState\DrawList, *Enemy)
    EndIf
    
    
  Next
  
  
  
EndProcedure

Procedure CheckItemsAgainstPlayer(*PlayState.TPlayState)
  
  ForEach *PlayState\ItemList\Items()
    If Not *PlayState\ItemList\Items()\Active
      Continue
    EndIf
    
    Protected *Item.TItem = *PlayState\ItemList\Items()
    Protected PlayerCoords.TVector2D
    GetTileCoordsByPosition(@*PlayState\Player\MiddlePosition, @PlayerCoords)
    If *Item\PositionMapCoords\x = PlayerCoords\x And *Item\PositionMapCoords\y = PlayerCoords\y
      ApplyItemOnPlayer(@*PlayState\Player, *Item)
      Continue
    EndIf
  Next
  
EndProcedure

Procedure UpdatePlayState(*PlayState.TPlayState, TimeSlice.f)
  If *PlayState\Player\Active
    *PlayState\Player\Update(@*PlayState\Player, TimeSlice)
  EndIf
  
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
  
  ForEach *PlayState\ItemList\Items()
    If Not *PlayState\ItemList\Items()\Active
      Continue
    EndIf
    *PlayState\ItemList\Items()\Update(@*PlayState\ItemList\Items(), TimeSlice)
  Next
  
  *PlayState\GameMap\Update(@*PlayState\GameMap, TimeSlice)
  
  CheckExplodedTilesPlayState(*PlayState)
  
  CheckExplosionsCollisionsPlayState(*PlayState)
  
  CheckItemsAgainstPlayer(*PlayState)
  
  If BeatLevelPlayState(*PlayState)
    GoToNextLevelPlayState(*PlayState)
    ProcedureReturn
  EndIf
  
  If Not *PlayState\IsGameOver And IsGameOverPlayState(*PlayState)
    *PlayState\IsGameOver = #True
  EndIf
  
  If *PlayState\IsGameOver And KeyboardReleased(#PB_Key_Return)
    SwitchGameState(@GameStateManager, #PlayState)
    ProcedureReturn
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

Procedure DrawGameOverTextPlayState(*PlayState.TPlayState)
  Protected GameOverText.s = "GAME OVER"
  Protected GameOverTextLen = Len(GameOverText)
  Protected.f GameOverTextPosX, GameOverTextPosY
  Protected GameOverFontWidth.f, GameOverFontHeight.f
  GameOverFontWidth = #STANDARD_FONT_WIDTH * 5 * #SPRITES_ZOOM
  GameOverFontHeight = #STANDARD_FONT_HEIGHT * 5 * #SPRITES_ZOOM
  GameOverTextPosX = (ScreenWidth() / 3) - ((GameOverTextLen * GameOverFontWidth) / 2)
  GameOverTextPosY = (ScreenHeight() / 3) - GameOverFontHeight / 2
  DrawTextWithStandardFont(GameOverTextPosX, GameOverTextPosY, GameOverText, GameOverFontWidth, GameOverFontHeight)
  
  Protected LevelReachedText.s = "Level Reached:" + Str(*PlayState\Level)
  Protected LevelReachedTextLen = Len(LevelReachedText)
  Protected.f LevelReachedTextPosX, LevelReachedTextPosY
  Protected LevelReachedFontWidth.f, LevelReachedFontHeight.f
  
  LevelReachedFontWidth = #STANDARD_FONT_WIDTH * 2.5 * #SPRITES_ZOOM
  LevelReachedFontHeight = #STANDARD_FONT_HEIGHT * 2.5 * #SPRITES_ZOOM
  LevelReachedTextPosX = (ScreenWidth() / 3) - ((LevelReachedTextLen * LevelReachedFontWidth) / 2)
  LevelReachedTextPosY = GameOverTextPosY + LevelReachedFontHeight + 20
  DrawTextWithStandardFont(LevelReachedTextPosX, LevelReachedTextPosY, LevelReachedText, LevelReachedFontWidth, LevelReachedFontHeight)
  
  Protected BestLevelText.s = "Best:" + Str(*PlayState\Level)
  Protected BestLevelTextLen = Len(BestLevelText)
  Protected.f BestLevelTextPosX, BestLevelTextPosY
  Protected.f BestLevelFontWidth, BestLevelFontHeight
  
  BestLevelFontWidth = #STANDARD_FONT_WIDTH * 2.5 * #SPRITES_ZOOM
  BestLevelFontHeight = #STANDARD_FONT_HEIGHT * 2.5 * #SPRITES_ZOOM
  BestLevelTextPosX = (ScreenWidth() / 3) - ((BestLevelTextLen * BestLevelFontWidth) / 2)
  BestLevelTextPosY = LevelReachedTextPosY + 20
  DrawTextWithStandardFont(BestLevelTextPosX, BestLevelTextPosY, BestLevelText, BestLevelFontWidth, BestLevelFontHeight)
  
  Protected RestartText.s = "Press enter to restart"
  Protected RestartTextLen = Len(RestartText)
  Protected.f RestartTextPosX, RestartTextPosY
  Protected.f RestartFontWidth, RestartFontHeight
  
  RestartFontWidth = #STANDARD_FONT_WIDTH * 1.875 * #SPRITES_ZOOM
  RestartFontHeight = #STANDARD_FONT_HEIGHT * 1.875 * #SPRITES_ZOOM
  RestartTextPosX = (ScreenWidth() / 3) - ((RestartTextLen * RestartFontWidth) / 2)
  RestartTextPosY = BestLevelTextPosY + 20
  DrawTextWithStandardFont(RestartTextPosX, RestartTextPosY, RestartText, RestartFontWidth, RestartFontHeight)
  
  
EndProcedure

Procedure DrawGameOverScreenPlayState(*PlayState.TPlayState)
  DisplayTransparentSprite(#GameOverOverlaySprite, 0, 0)
  DrawGameOverTextPlayState(*PlayState)
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
  
  If *PlayState\ShowAStar
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Outlined)
    
    ForEach *PlayState\AStarPath()
      Protected XPath.u = *PlayState\GameMap\Position\x + *PlayState\AStarPath()\x * #MAP_GRID_TILE_WIDTH
      Protected YPath.u = *PlayState\GameMap\Position\y + *PlayState\AStarPath()\y * #MAP_GRID_TILE_HEIGHT
      Box(XPath, YPath, #MAP_GRID_TILE_WIDTH, #MAP_GRID_TILE_HEIGHT, RGB(0, 214, 0))
    Next
    
    StopDrawing()
  EndIf
  
  If *PlayState\IsGameOver
    DrawGameOverScreenPlayState(*PlayState)
  EndIf
  
  
  
  
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