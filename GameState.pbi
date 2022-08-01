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
  Player.TPlayer
  
  Ground.TGround
  
  DrawList.TDrawList
  
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

Procedure InitGroundPlayState(*PlayState.TPlayState)
  InitGround(*PlayState\Ground)
  
  AddDrawItemDrawList(*PlayState\DrawList, *PlayState\Ground)
  
  
EndProcedure

Procedure StartPlayState(*PlayState.TPlayState)
  ;InitGroundPlayState(*PlayState)
  
  
EndProcedure

Procedure EndPlayState(*PlayState.TPlayState)
EndProcedure

Procedure UpdatePlayState(*PlayState.TPlayState, TimeSlice.f)
EndProcedure

Procedure DrawPlayState(*PlayState.TPlayState)
  DrawDrawList(*PlayState\DrawList)
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