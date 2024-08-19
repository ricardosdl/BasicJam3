XIncludeFile "GameState.pbi"
XIncludeFile "Sound.pbi"

EnableExplicit

#TOTAL_SPRITES = 18
#TOTAL_SOUNDS = 9

Global SimulationTime.q = 0, RealTime.q, GameTick = 5
Global LastTimeInMs.q, Is_Full_Screen.a = #False, Event, ExitGame.a = #False

Procedure.a LoadSprites()
  Protected LoadedAll = #True
  LoadedAll = LoadedAll & Bool(LoadSprite(#StandardFont, "data\img\font.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#UnbreakableWall, "data\img\unbreakable-wall.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#Ground, "data\img\ground.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#BreakableWall1, "data\img\breakable-wall-1.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#Player1, "data\img\PurpleDemon.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#Bomb1, "data\img\FireballProjectile.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#EnemyRedDemonSprite, "data\img\RedDemon.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#EnemyRedArmoredDemonSprite, "data\img\ArmouredRedDemon.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#CursorSprite, "data\img\cursor.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#ExplosionSprite, "data\img\Explosion.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#ItemBombPowerSprite, "data\img\bombpower.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#ItemIncreaseBombsSprite, "data\img\increasebombs.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#PlayerHeartSprite, "data\img\playerheart.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#GameOverOverlaySprite, "data\img\gameoveroverlay.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#EnemyMagnetoBombSprite, "data\img\magnetobomb.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#EnemySummonerSprite, "data\img\Grum.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#ItemRevealItemsSprite, "data\img\revealitems.png", #PB_Sprite_AlphaBlending))
  LoadedAll = LoadedAll & Bool(LoadSprite(#MainMenuSplashSprite, "data\img\splash2.png", #PB_Sprite_AlphaBlending))
  ProcedureReturn LoadedAll
EndProcedure

Procedure.a LoadSounds()
  If SoundStarted = 0
    ProcedureReturn #False
  EndIf
  
  Protected LoadedAll.a = #True
  LoadedAll = LoadedAll & Bool(LoadSound(#MainMusicSound, "data\sounds\BossTheme.ogg"))
  LoadedAll = LoadedAll & Bool(LoadSound(#ExplosionSound, "data\sounds\explosion.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#ItemRevealedSound, "data\sounds\itemrevealed.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#PowerUpSound, "data\sounds\powerup.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#PlayerHitSound, "data\sounds\playerhit.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#DropBombSound, "data\sounds\dropbomb.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#SummonEnemySound, "data\sounds\summonenemy.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#PauseSound, "data\sounds\pausesound.wav"))
  LoadedAll = LoadedAll & Bool(LoadSound(#GameOverSound, "data\sounds\gameoversound.wav"))
  
  
  ProcedureReturn LoadedAll
  
EndProcedure

Procedure.a LoadResources()
  If LoadSprites() = #False
    CompilerIf #PB_Compiler_OS = #PB_OS_Web
      MessageRequester("Error loading sprites! Couldn't find data.")
    CompilerElse
      MessageRequester("ERROR", "Error loading sprites! Couldn't find data.")
    CompilerEndIf
    
    
    ProcedureReturn #False
  EndIf
  
  Protected ErrorLoadingSounds.a = #False
  If LoadSounds() = #False
    ErrorLoadingSounds = #True
  EndIf
  
  If ErrorLoadingSounds
    TurnOffSound()
  EndIf
  
  
  
  ProcedureReturn #True
  
EndProcedure

Procedure UpdateWorld(TimeSlice.f)
  UpdateCurrentStateGameStateManager(@GameStateManager, TimeSlice)
EndProcedure

Procedure DrawWorld()
  DrawCurrentStateGameSateManager(@GameStateManager)
EndProcedure

Procedure IsFullScreen()
  Protected FullScreenParameter.s = ProgramParameter(0)
  
  If Len(FullScreenParameter) = 0
    ProcedureReturn #False
  EndIf
  
  If FullScreenParameter = "-f" Or FullScreenParameter = "-F"
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
  
EndProcedure

Procedure InitScreen(IsFullScreen.a = #False)
  If Not IsFullScreen
    OpenWindow(1, 0 , 0, 640, 480, "Bomber Escape", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
    OpenWindowedScreen(WindowID(1),0,0,640,480,0,0,0)
    Is_Full_Screen = #False
    ProcedureReturn
  EndIf
  
  Protected OpenScreenResult = OpenScreen(640, 480, 32, "Bomber Escape")
  
  If OpenScreenResult = 0
    ;couldn't open full screen
    OpenWindow(1, 0 , 0, 640, 480, "Bomber Escape", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
    OpenWindowedScreen(WindowID(1),0,0,640,480,0,0,0)
    Is_Full_Screen = #False
    ProcedureReturn
  EndIf
  
  Is_Full_Screen = #True
  
  
EndProcedure

Procedure LoadingHandler(Type, FileName.s, ObjectId)
  Static LoadedSprites.a = 0
  Static LoadedSounds.a = 0
  
  If Type = #PB_Loading_Sprite
    LoadedSprites + 1
  EndIf
  
  If LoadedSprites >= #TOTAL_SPRITES
    InitGameSates()
    SwitchGameState(@GameStateManager, #MainMenuState)
    ;loaded all sprites can start rendering
    SimulationTime = ElapsedMilliseconds()
    FlipBuffers()
  EndIf
  
  If Type = #PB_Loading_Sound
    LoadedSounds + 1
  EndIf
  
  If LoadedSounds >= #TOTAL_SOUNDS
    SoundStarted = 1
    
  EndIf
  
  
EndProcedure

Procedure LoadingError()
EndProcedure

Procedure RenderFrame()
  LastTimeInMs = ElapsedMilliseconds()
  CompilerIf #PB_Compiler_OS <> #PB_OS_Web
    Repeat; Always process all the events to flush the queue at every frame
      Event = WindowEvent()
      Select Event
        Case #PB_Event_CloseWindow
          ExitGame = #True
      EndSelect
    Until Event = 0 ; Quit the event loop only when no more events are available
  CompilerEndIf
  
  
  ExamineKeyboard()
  ;ExamineMouse()
  
  ;Update
  Debug "simulationtime:" + SimulationTime
  Debug "LastTimeInMs:" + LastTimeInMs
  While SimulationTime < LastTimeInMs
    SimulationTime + GameTick
    Debug "SimulationTime updated:" + SimulationTime
    ;UpdateWorld(GameTick / 1000.0)
  Wend
  Debug "============="
  
  If KeyboardPushed(#PB_Key_Return)
    Debug "return pushed here:" + ElapsedMilliseconds()
    
    
  ;Else
  ;  Debug "nothing inputed"
    
    
  EndIf
  
  
  ExitGame = QuitGame
  
  ;Draw
  ClearScreen(#Black)  
  DrawWorld()
  FlipBuffers()
  
EndProcedure

InitSprite()
InitKeyboard()
InitMouse()
InitializeSound()

Define IsFullScreen.a = IsFullScreen()
InitScreen(IsFullScreen)





CompilerIf #PB_Compiler_OS <> #PB_OS_Web
  UsePNGImageDecoder()
  UseOGGSoundDecoder()
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Web
  BindEvent(#PB_Event_Loading, @LoadingHandler())
  BindEvent(#PB_Event_LoadingError, @LoadingError())
  BindEvent(#PB_Event_RenderFrame, @RenderFrame())
  SoundStarted = 0
CompilerEndIf

If (LoadResources() = #False)
  ;error loading resources, can't ryb the game this way
  End 1
EndIf

CompilerIf #PB_Compiler_OS <> #PB_OS_Web
  InitGameSates()
  SwitchGameState(@GameStateManager, #MainMenuState)
CompilerEndIf

CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
  Repeat
    RenderFrame()
  Until ExitGame
CompilerEndIf


End