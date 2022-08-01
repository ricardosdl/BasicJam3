XIncludeFile "GameState.pbi"

EnableExplicit

InitSprite()
InitKeyboard()

OpenWindow(1, 0,0,800,600,"Foo Game", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
OpenWindowedScreen(WindowID(1),0,0,800,600,0,0,0)

Global SimulationTime.q = 0, RealTime.q, GameTick = 5
Global LastTimeInMs.q

Procedure.a LoadSprites()
  Protected LoadedAll = #True
  LoadedAll = LoadedAll & Bool(LoadSprite(#StandardFont, "data\img\font.png", #PB_Sprite_AlphaBlending))
  ProcedureReturn LoadedAll
EndProcedure

Procedure.a LoadResources()
  If LoadSprites() = #False
    MessageRequester("ERROR", "Error loading sprites! Couldn't find data.")
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
EndProcedure

Procedure UpdateWorld(TimeSlice.f)
  UpdateCurrentStateGameStateManager(@GameStateManager, TimeSlice)
EndProcedure

Procedure DrawWorld()
  DrawCurrentStateGameSateManager(@GameStateManager)
  ;Player\DrawGameObject(@Player)
  ;Banana\DrawGameObject(@Banana)
EndProcedure

Procedure StartGame()
  
EndProcedure


UsePNGImageDecoder()

If (LoadResources() = #False)
  ;error loading resources, can't ryb the game this way
  End 1
EndIf


InitGameSates()
SwitchGameState(@GameStateManager, #MainMenuState)

SimulationTime = ElapsedMilliseconds()

Repeat
  LastTimeInMs = ElapsedMilliseconds()
  
  ;RealTime = ElapsedMilliseconds()
  Define Event = WindowEvent()
  
  ExamineKeyboard()
  
  ;Update
  While SimulationTime < LastTimeInMs
    SimulationTime + GameTick
    UpdateWorld(GameTick / 1000.0)
  Wend
  
  ;Draw
  ClearScreen(#Black)  
  DrawWorld()
  FlipBuffers()
Until event = #PB_Event_CloseWindow Or KeyboardPushed(#PB_Key_Escape)
End