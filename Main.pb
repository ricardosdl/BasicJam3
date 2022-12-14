XIncludeFile "GameState.pbi"
XIncludeFile "Sound.pbi"

EnableExplicit

Global SimulationTime.q = 0, RealTime.q, GameTick = 5
Global LastTimeInMs.q, Is_Full_Screen.a = #False

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
    MessageRequester("ERROR", "Error loading sprites! Couldn't find data.")
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
  ;Player\DrawGameObject(@Player)
  ;Banana\DrawGameObject(@Banana)
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

InitSprite()
InitKeyboard()
InitMouse()
InitializeSound()

Define IsFullScreen.a = IsFullScreen()
InitScreen(IsFullScreen)






UsePNGImageDecoder()
UseOGGSoundDecoder()

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
  Define Event
  If Not Is_Full_Screen
    Event = WindowEvent()
  EndIf
  
  
  ExamineKeyboard()
  ;ExamineMouse()
  
  ;Update
  While SimulationTime < LastTimeInMs
    SimulationTime + GameTick
    UpdateWorld(GameTick / 1000.0)
  Wend
  
  ;Draw
  ClearScreen(#Black)  
  DrawWorld()
  FlipBuffers()
Until Event = #PB_Event_CloseWindow Or QuitGame
End