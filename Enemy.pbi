XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "Projectile.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration EEnemyStates
  #EnemyNoState
  #EnemyGoingToObjectiveRect
  #EnemyWaiting
  #EnemyPatrolling
  #EnemyShooting
  #EnemyFollowingPlayer
EndEnumeration

Enumeration EEnemyType
  #EnemyBanana
  #EnemyApple
  #EnemyGrape
  #EnemyWatermelon
  #EnemyTangerine
  #EnemyPineapple
  #EnemyLemon
  #EnemyCoconut
  #EnemyJabuticaba
  #EnemyTomato
  #EnemySpawner_
EndEnumeration

Prototype SetPatrollingEnemyProc(*Enemy)
Prototype.a SpawnEnemyProc(*Data)

;the clone is just a position and a timer
;we use it to show a "clone", a copy of the
;enemy sprite in a postion for the duration of the timer
Structure TEnemyClone Extends TVector2D
  Timer.f
  Active.a
EndStructure

Structure TEnemy Extends TGameObject
  *Player.TGameObject
  CurrentState.a
  LastState.a
  ObjectiveRect.TRect;a rect that can be used as an objective point for the enemy to reach
  WaitTimer.f
  StateTimer.f
  *ShootingTarget.TGameObject
  ShootingArea.TRect
  ShootingTimer.f
  *Projectiles.TProjectileList
  NumShots.a
  TimerBetweenShots.f
  CurrentTimerBetweenShots.f
  CurrentAngleShot.f
  JumpPosition.TVector2D
  JumpVelocity.f
  JumpYDeslocation.f
  Gravity.f
  IsOnGround.a
  Shadow.TGameObject
  *DrawList.TDrawList
  List Clones.TEnemyClone()
  CloneTimer.f
  *SpawnEnemy.SpawnEnemyProc
  EnemyType.a
EndStructure

#TOMATO_CLONING_TIMER = 0.15
#TOMATO_CLONE_TIMER = 7 * #TOMATO_CLONING_TIMER

Procedure.a GetRandomEnemyType(StartEnemyType.a, EndEnemyType.a)
  If StartEnemyType < #EnemyBanana
    StartEnemyType = #EnemyBanana
  EndIf
  
  If EndEnemyType > #EnemyTomato
    EndEnemyType = #EnemyTomato
  EndIf
  
  ProcedureReturn Random(EndEnemyType, StartEnemyType)
  
  
EndProcedure


Procedure InitEnemy(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                    *DrawList.TDrawList, EnemyType.a)
  *Enemy\Player = *Player
  *Enemy\Projectiles = *ProjectileList
  
  *Enemy\IsOnGround = #True
  *Enemy\DrawList = *DrawList
  *Enemy\EnemyType = EnemyType
EndProcedure

Procedure SetVelocityPatrollingBananaEnemy(*BananaEnemy.TEnemy)
  UpdateMiddlePositionGameObject(*BananaEnemy)
  If *BananaEnemy\MiddlePosition\x < (ScreenWidth() / 2)
    ;to the left of screen, will move up or down
    If *BananaEnemy\MiddlePosition\y < (ScreenHeight() / 2)
      ;move up
      *BananaEnemy\Velocity\y = -100
    Else
      ;move down
      *BananaEnemy\Velocity\y = 100
    EndIf
    
  Else
    ;to the right of screen, will move left or right
    If *BananaEnemy\MiddlePosition\y < (ScreenHeight() / 2)
      ;move left
      *BananaEnemy\Velocity\x = -100
    Else
      ;move right
      *BananaEnemy\Velocity\x = 100
    EndIf
    
  EndIf
  
EndProcedure

Procedure HasReachedObjectiveRectEnemy(*Enemy.TEnemy)
  Protected EnemyRect.TRect, ObjectiveRect.TRect
  EnemyRect\Position = *Enemy\Position
  EnemyRect\Width = *Enemy\Width
  EnemyRect\Height = *Enemy\Height
  
  ObjectiveRect = *Enemy\ObjectiveRect
  
  ProcedureReturn CollisionRectRect(EnemyRect\Position\x, EnemyRect\Position\y,
                                    EnemyRect\Width, EnemyRect\Height,
                                    ObjectiveRect\Position\x, ObjectiveRect\Position\y,
                                    ObjectiveRect\Width, ObjectiveRect\Height)
EndProcedure

Procedure GetRandomRectAroundPlayer(*Player.TGameObject, *RectAroundPlayer.TRect,
                                    RectWidth.f, RectHeight.f, ObjectiveRectWidth.f = 4,
                                    ObjectiveRectHeight.f = 4)
  Protected RectAroundPlayer.TRect
  GetRandomRectAroundGameObject(*Player, RectWidth, RectHeight,
                                @RectAroundPlayer)
  RectAroundPlayer\Position\x = ClampF(RectAroundPlayer\Position\x, 0, ScreenWidth() - 1)
  RectAroundPlayer\Position\y = ClampF(RectAroundPlayer\Position\y, 0, ScreenHeight() - 1)
  
  ;clamp the rect width and height if necessary to stay inside the screen
  If RectAroundPlayer\Position\x + RectAroundPlayer\Width > ScreenWidth() - 1
    RectAroundPlayer\Width - (RectAroundPlayer\Position\x + RectAroundPlayer\Width - (ScreenWidth() - 1))
  EndIf
  
  If RectAroundPlayer\Position\y + RectAroundPlayer\Height > ScreenHeight() - 1
    RectAroundPlayer\Height - (RectAroundPlayer\Position\y + RectAroundPlayer\Height - (ScreenHeight() - 1))
  EndIf
  
  
  
  ;lets get a random point inside the rect around the player
  Protected RandomPoint.TVector2D\x = Random(RectAroundPlayer\Position\x +
                                             RectAroundPlayer\Width,
                                             RectAroundPlayer\Position\x)
  RandomPoint\y = Random(RectAroundPlayer\Position\y + RectAroundPlayer\Height,
                         RectAroundPlayer\Position\y)
  
  
  Protected ObjectiveRect.TRect\Width = ObjectiveRectWidth
  ObjectiveRect\Height = ObjectiveRectHeight
  
  ;make sure the point is inside
  RandomPoint\x = ClampF(RandomPoint\x, 0, ScreenWidth() - ObjectiveRect\Width)
  RandomPoint\y = ClampF(RandomPoint\y, 0, ScreenHeight() - ObjectiveRect\Height)
  
  ObjectiveRect\Position = RandomPoint
  CopyStructure(@ObjectiveRect, *RectAroundPlayer, TRect)
EndProcedure

Procedure SwitchStateEnemy(*Enemy.TEnemy, NewState.a)
  *Enemy\LastState = *Enemy\CurrentState
  *Enemy\CurrentState = NewState
EndProcedure

Procedure SwitchToGoingToObjectiveRectEnemy(*Enemy.TEnemy, *ObjectiveRect.TRect, StateTimer.f = 1.0)
  CopyStructure(*ObjectiveRect, @*Enemy\ObjectiveRect, TRect)
  
  UpdateMiddlePositionGameObject(*Enemy)
  
  Protected DeltaX.f = *ObjectiveRect\Position\x - *Enemy\MiddlePosition\x
  Protected DeltaY.f = *ObjectiveRect\Position\y - *Enemy\MiddlePosition\y
  
  Protected Angle.f = ATan2(DeltaX, DeltaY)
  
  *Enemy\Velocity\x = Cos(Angle) * *Enemy\MaxVelocity\x
  *Enemy\Velocity\y = Sin(Angle) * *Enemy\MaxVelocity\y
  
  *Enemy\StateTimer = StateTimer
  SwitchStateEnemy(*Enemy, #EnemyGoingToObjectiveRect)
EndProcedure

Procedure SwitchToWaitingEnemy(*Enemy.TEnemy, WaitTimer.f = 1.5)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  *Enemy\WaitTimer = WaitTimer
  SwitchStateEnemy(*Enemy, #EnemyWaiting)
EndProcedure

Procedure KillEnemy(*Enemy.TEnemy)
  *Enemy\Active = #False
  *Enemy\Shadow\Active = #False
EndProcedure


Procedure HurtEnemy(*Enemy.TEnemy, Power.f)
  *Enemy\Health - Power
  If *Enemy\Health <= 0.0
    KillEnemy(*Enemy)
  EndIf
  
EndProcedure

Procedure UpdateBananaEnemy(*BananaEnemy.TEnemy, TimeSlice.f)
  
  If *BananaEnemy\CurrentState = #EnemyNoState
    SwitchToWaitingEnemy(*BananaEnemy, 1.0)
    ProcedureReturn
  EndIf
  
  If *BananaEnemy\CurrentState = #EnemyGoingToObjectiveRect
    If HasReachedObjectiveRectEnemy(*BananaEnemy)
      SwitchToWaitingEnemy(*BananaEnemy)
      ProcedureReturn
    EndIf
  ElseIf *BananaEnemy\CurrentState = #EnemyWaiting
    *BananaEnemy\WaitTimer - TimeSlice
    If *BananaEnemy\WaitTimer <= 0.0
      Protected ObjectiveRect.TRect
      Protected *Player.TGameObject = *BananaEnemy\Player
      GetRandomRectAroundPlayer(*Player, @ObjectiveRect, *Player\Width * 10,
                            *Player\Height * 10, *BananaEnemy\Width, *BananaEnemy\Height)
      SwitchToGoingToObjectiveRectEnemy(*BananaEnemy, @ObjectiveRect)
      ProcedureReturn
    EndIf
  EndIf
  
  
  
  UpdateGameObject(*BananaEnemy, TimeSlice)
  
  
EndProcedure

Procedure DrawEnemy(*Enemy.TEnemy)
  If *Enemy\CurrentState = #EnemyGoingToObjectiveRect
    StartDrawing(ScreenOutput())
    
    Box(*Enemy\Position\x, *Enemy\Position\y,
        *Enemy\Width, *Enemy\Height, RGB(123, 255, 255))
    
    Box(*Enemy\ObjectiveRect\Position\x, *Enemy\ObjectiveRect\Position\y,
        *Enemy\ObjectiveRect\Width, *Enemy\ObjectiveRect\Height, RGB(100, 123, 255))
    StopDrawing()
  EndIf
  
  DrawGameObject(*Enemy)
EndProcedure

Procedure InitBananaEnemy(*BananaEnemy.TEnemy, *Player.TGameObject, *Position.TVector2D,
                          SpriteNum.i, ZoomFactor.f, *ProjectileList.TProjectileList,
                          *DrawList.TDrawList)
  
  InitEnemy(*BananaEnemy, *Player, *ProjectileList, *DrawList, #EnemyBanana)
  
  *BananaEnemy\Health = 1.0
  
  InitGameObject(*BananaEnemy, *Position, SpriteNum, @UpdateBananaEnemy(), @DrawEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *BananaEnemy\MaxVelocity\x = 100.0
  *BananaEnemy\MaxVelocity\y = 100.0
  
  *BananaEnemy\CurrentState = #EnemyNoState
  
  ;some initialization for the bananaenemy
  
  
  
  
EndProcedure

Procedure SwitchToFollowingPlayerEnemy(*Enemy.TEnemy, StateTimer.f = 1.0)
  Protected *Player.TGameObject = *Enemy\Player
  
  UpdateMiddlePositionGameObject(*Enemy)
  UpdateMiddlePositionGameObject(*Player)
  
  Protected DeltaX.f = *Player\MiddlePosition\x - *Enemy\MiddlePosition\x
  Protected DeltaY.f = *Player\MiddlePosition\y - *Enemy\MiddlePosition\y
  Protected Angle.f = ATan2(DeltaX, DeltaY)
  
  *Enemy\Velocity\x = Cos(Angle) * *Enemy\MaxVelocity\x
  *Enemy\Velocity\y = Sin(Angle) * *Enemy\MaxVelocity\y
  *Enemy\StateTimer = StateTimer
  SwitchStateEnemy(*Enemy, #EnemyFollowingPlayer)
EndProcedure

Procedure.a IsCloseEneoughToPlayerEnemy(*Enemy.TEnemy, CloseEnoughDistance.f)
  
  UpdateMiddlePositionGameObject(*Enemy)
  UpdateMiddlePositionGameObject(*Enemy\Player)
  
  Protected DistanceToPlayer.f = DistanceBetweenPoints(*Enemy\MiddlePosition\x,
                                                       *Enemy\MiddlePosition\y,
                                                       *Enemy\Player\MiddlePosition\x,
                                                       *Enemy\Player\MiddlePosition\y)
  ProcedureReturn Bool(DistanceToPlayer <= CloseEnoughDistance)
  
EndProcedure

Procedure SwitchToShootingTargetEnemy(*Enemy.TEnemy, ShootingTimer.f, *Target.TGameObject,
                                      NumShots.a = 1, TimerBetweenShots.f = 0.0)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  *Enemy\ShootingTarget = *Target
  *Enemy\ShootingTimer = ShootingTimer
  *Enemy\NumShots = NumShots
  *Enemy\TimerBetweenShots = TimerBetweenShots
  *Enemy\CurrentTimerBetweenShots = TimerBetweenShots
  SwitchStateEnemy(*Enemy, #EnemyShooting)
EndProcedure

Procedure SwitchToShootingAreaEnemy(*Enemy.TEnemy, *TargetArea.TRect, ShootingTimer.f, NumShots.a = 1,
                                    TimerBetweenShots.f = 0.0)
  CopyStructure(*TargetArea, *Enemy\ShootingArea, TRect)
  *Enemy\ShootingTimer = ShootingTimer
  *Enemy\NumShots = NumShots
  *Enemy\TimerBetweenShots = TimerBetweenShots
  *Enemy\CurrentTimerBetweenShots = TimerBetweenShots
  SwitchStateEnemy(*Enemy, #EnemyShooting)
EndProcedure

Procedure ShootAppleEnemy(*AppleEnemy.TEnemy)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*AppleEnemy\Projectiles)
  
  UpdateMiddlePositionGameObject(*AppleEnemy)
  UpdateMiddlePositionGameObject(*AppleEnemy\ShootingTarget)
  
  Protected *Target.TGameObject = *AppleEnemy\ShootingTarget
  
  Protected DeltaX.f, DeltaY.f, Distance.f
  DeltaX = *Target\MiddlePosition\x - *AppleEnemy\MiddlePosition\x
  DeltaY = *Target\MiddlePosition\y - *AppleEnemy\MiddlePosition\y
  Distance = Sqr(DeltaX * DeltaX + DeltaY * DeltaY)
  
  Protected Angle.f = ATan2(DeltaX, DeltaY)
  
  Protected Position.TVector2D
  
  InitProjectile(*Projectile, @Position, #True, #SPRITES_ZOOM, Angle, #ProjectileBarf1)
  Position\x = *AppleEnemy\MiddlePosition\x - *Projectile\Width / 2
  Position\y = *AppleEnemy\MiddlePosition\y - *Projectile\Height / 2
  
  *Projectile\Position = Position
  
  Protected ProjectileAliveTimer.f = Distance / *Projectile\Velocity\x + 0.1
  *Projectile\HasAliveTimer = #True
  *Projectile\AliveTimer = ProjectileAliveTimer
  
  AddDrawItemDrawList(*AppleEnemy\DrawList, *Projectile)
  
EndProcedure


Procedure UpdateAppleEnemy(*AppleEnemy.TEnemy, TimeSlice.f)
  If *AppleEnemy\CurrentState = #EnemyNoState
    SwitchToFollowingPlayerEnemy(*AppleEnemy)
    ProcedureReturn
  EndIf
  
  If *AppleEnemy\CurrentState = #EnemyFollowingPlayer
    If IsCloseEneoughToPlayerEnemy(*AppleEnemy, 6 * *AppleEnemy\Width)
      ;Debug "close enough to shoot"
      SwitchToShootingTargetEnemy(*AppleEnemy, 0.5, *AppleEnemy\Player)
      ;ProcedureReturn
    EndIf
    
    *AppleEnemy\StateTimer - TimeSlice
    If *AppleEnemy\StateTimer <= 0
      ;readjust with the current player's position
      SwitchToFollowingPlayerEnemy(*AppleEnemy)
      ProcedureReturn
    EndIf
    
  ElseIf *AppleEnemy\CurrentState = #EnemyShooting
    *AppleEnemy\ShootingTimer - TimeSlice
    If *AppleEnemy\ShootingTimer <= 0
      ShootAppleEnemy(*AppleEnemy)
      SwitchToWaitingEnemy(*AppleEnemy, 2)
    EndIf
    
  ElseIf *AppleEnemy\CurrentState = #EnemyWaiting
    *AppleEnemy\WaitTimer - TimeSlice
    If *AppleEnemy\WaitTimer <= 0
      SwitchToFollowingPlayerEnemy(*AppleEnemy)
      ProcedureReturn
    EndIf
    
    
    
  EndIf
  
  
  UpdateGameObject(*AppleEnemy, TimeSlice)
  
EndProcedure

Procedure DrawAppleEnemy(*AppleEnemy.TEnemy)
  DrawEnemy(*AppleEnemy)
  UpdateMiddlePositionGameObject(*AppleEnemy)
  UpdateMiddlePositionGameObject(*AppleEnemy\Player)
  
  If IsCloseEneoughToPlayerEnemy(*AppleEnemy, 6 * *AppleEnemy\Width)
    
    
    StartDrawing(ScreenOutput())
    LineXY(*AppleEnemy\MiddlePosition\x, *AppleEnemy\MiddlePosition\y, *AppleEnemy\Player\MiddlePosition\x,
           *AppleEnemy\Player\MiddlePosition\y, RGB(150, 30, 30))
    StopDrawing()
    ;Debug "close enough to shoot"
    ;SwitchToShootingTargetEnemy(*AppleEnemy, *AppleEnemy\Player)
    ;ProcedureReturn
  EndIf
EndProcedure

Procedure InitAppleEnemy(*AppleEnemy.TEnemy, *Player.TGameObject, *Position.TVector2D,
                         SpriteNum.i, ZoomFactor.f, *ProjectileList.TProjectileList,
                         *DrawList.TDrawList)
  
  InitEnemy(*AppleEnemy, *Player, *ProjectileList, *DrawList, #EnemyApple)
  
  *AppleEnemy\Health = 2.0
  
  InitGameObject(*AppleEnemy, *Position, SpriteNum, @UpdateAppleEnemy(), @DrawAppleEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *AppleEnemy\MaxVelocity\x = 80.0
  *AppleEnemy\MaxVelocity\y = 80.0
  
  *AppleEnemy\CurrentState = #EnemyNoState
  
  
EndProcedure

Procedure ShootGrapeEnemy(*GrapeEnemy.TEnemy, TimeSlice.f)
  *GrapeEnemy\CurrentTimerBetweenShots - TimeSlice
  If *GrapeEnemy\CurrentTimerBetweenShots <= 0 And *GrapeEnemy\NumShots > 0
    *GrapeEnemy\CurrentTimerBetweenShots = *GrapeEnemy\TimerBetweenShots
    
    Protected *Projectile.TProjectile = GetInactiveProjectile(*GrapeEnemy\Projectiles)
    
    UpdateMiddlePositionGameObject(*GrapeEnemy)
    UpdateMiddlePositionGameObject(*GrapeEnemy\ShootingTarget)
    
    Protected *Target.TGameObject = *GrapeEnemy\ShootingTarget
    
    Protected DeltaX.f, DeltaY.f, Distance.f
    DeltaX = *Target\MiddlePosition\x - *GrapeEnemy\MiddlePosition\x
    DeltaY = *Target\MiddlePosition\y - *GrapeEnemy\MiddlePosition\y
    Distance = Sqr(DeltaX * DeltaX + DeltaY * DeltaY)
    
    Protected Angle.f = ATan2(DeltaX, DeltaY)
    Angle + *GrapeEnemy\CurrentAngleShot
    *GrapeEnemy\CurrentAngleShot + Radian(30.0 / 3)
    
    Protected Position.TVector2D
    
    InitProjectile(*Projectile, @Position, #True, #SPRITES_ZOOM, Angle, #ProjectileGrape1)
    Position\x = *GrapeEnemy\MiddlePosition\x - *Projectile\Width / 2
    Position\y = *GrapeEnemy\MiddlePosition\y - *Projectile\Height / 2
    
    *Projectile\Position = Position
    
    AddDrawItemDrawList(*GrapeEnemy\DrawList, *Projectile)
    
    *GrapeEnemy\NumShots - 1
    If *GrapeEnemy\NumShots < 1
      ;ended the shots
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
    
    
    ;Protected ProjectileAliveTimer.f = Distance / *Projectile\Velocity\x + 0.1
    ;*Projectile\HasAliveTimer = #True
    ;*Projectile\AliveTimer = ProjectileAliveTimer
  EndIf
  
  ProcedureReturn #False
  
EndProcedure


Procedure UpdateGrapeEnemy(*GrapeEnemy.TEnemy, TimeSlice.f)
  If *GrapeEnemy\CurrentState = #EnemyNoState
    SwitchToFollowingPlayerEnemy(*GrapeEnemy)
    ProcedureReturn
  EndIf
  
  If *GrapeEnemy\CurrentState = #EnemyFollowingPlayer
    If IsCloseEneoughToPlayerEnemy(*GrapeEnemy, 8 * *GrapeEnemy\Width)
      
      SwitchToShootingTargetEnemy(*GrapeEnemy, 1, *GrapeEnemy\Player, 3, 0.5)
      ;the first shot is off -30/3 degrees from the target
      *GrapeEnemy\CurrentAngleShot = Radian(-30.0 / 3)
    EndIf
    
    *GrapeEnemy\StateTimer - TimeSlice
    If *GrapeEnemy\StateTimer <= 0
      ;readjust with the current player's position
      SwitchToFollowingPlayerEnemy(*GrapeEnemy)
      ProcedureReturn
    EndIf
    
  ElseIf *GrapeEnemy\CurrentState = #EnemyShooting
    *GrapeEnemy\ShootingTimer - TimeSlice
    If *GrapeEnemy\ShootingTimer <= 0
      If ShootGrapeEnemy(*GrapeEnemy, TimeSlice)
        ;ended all shots
        SwitchToWaitingEnemy(*GrapeEnemy, 2)
      EndIf
      
      
    EndIf
    
  ElseIf *GrapeEnemy\CurrentState = #EnemyWaiting
    *GrapeEnemy\WaitTimer - TimeSlice
    If *GrapeEnemy\WaitTimer <= 0
      SwitchToFollowingPlayerEnemy(*GrapeEnemy)
      ProcedureReturn
    EndIf
    
    
    
  EndIf
  
  
  UpdateGameObject(*GrapeEnemy, TimeSlice)
EndProcedure

Procedure InitGrapeEnemy(*GrapeEnemy.TEnemy, *Player.TGameObject, *Position.TVector2D,
                         SpriteNum.i, ZoomFactor.f, *ProjectileList.TProjectileList,
                         *DrawList.TDrawList)
  
  InitEnemy(*GrapeEnemy, *Player, *ProjectileList, *DrawList, #EnemyGrape)
  
  *GrapeEnemy\Health = 2.0
  
  InitGameObject(*GrapeEnemy, *Position, SpriteNum, @UpdateGrapeEnemy(), @DrawAppleEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *GrapeEnemy\MaxVelocity\x = 80.0
  *GrapeEnemy\MaxVelocity\y = 80.0
  
  *GrapeEnemy\CurrentState = #EnemyNoState
  
  
EndProcedure

Procedure ShootWatermelonEnemy(*WatermelonEnemy.TEnemy, TimeSlice.f)
  
  *WatermelonEnemy\CurrentTimerBetweenShots - TimeSlice
  If *WatermelonEnemy\CurrentTimerBetweenShots <= 0 And *WatermelonEnemy\NumShots > 0
    ;restore the timer
    *WatermelonEnemy\CurrentTimerBetweenShots = *WatermelonEnemy\TimerBetweenShots
    
    UpdateMiddlePositionGameObject(*WatermelonEnemy)
    
    ;the shots are distributed over the targetarea in 3x3 rows and cols
    Protected ShotsPerRow.a = 3
    
    Protected *TargetArea.TRect = @*WatermelonEnemy\ShootingArea
    
    Protected *Projectile.TProjectile = GetInactiveProjectile(*WatermelonEnemy\Projectiles)
    
    Protected.a TargetRow, TargetCol
    ;get the targetrow (0..2) and target col(0..2)
    TargetRow = (*WatermelonEnemy\NumShots - 1) / ShotsPerRow
    TargetCol = (*WatermelonEnemy\NumShots - 1) % ShotsPerRow
    
    ;the position where the projectile will land
    Protected TargetPosition.TVector2D
    
    ;the width of each row
    Protected QuadrantWidth.f = *TargetArea\Width / ShotsPerRow
    ;the height of each col
    Protected QuadrantHeight.f = *TargetArea\Height / ShotsPerRow
    
    ;the target position is centralized inside each quadrant
    TargetPosition\x = *TargetArea\Position\x + (QuadrantWidth) * TargetCol + (QuadrantWidth / 2)
    TargetPosition\y = *TargetArea\Position\y + (QuadrantHeight) * TargetRow + (QuadrantHeight / 2)
    
    ;get the distance and the angle in which the projectile will travel
    Protected DeltaX.f, DeltaY.f, Distance.f
    DeltaX = TargetPosition\x - *WatermelonEnemy\MiddlePosition\x
    DeltaY = TargetPosition\y - *WatermelonEnemy\MiddlePosition\y
    Distance = Sqr(DeltaX * DeltaX + DeltaY * DeltaY)
    
    Protected Angle.f = ATan2(DeltaX, DeltaY)
    
    Protected Position.TVector2D
    
    InitProjectile(*Projectile, @Position, #True, #SPRITES_ZOOM, Angle, #ProjectileSeed1)
    Position\x = *WatermelonEnemy\MiddlePosition\x - *Projectile\Width / 2
    Position\y = *WatermelonEnemy\MiddlePosition\y - *Projectile\Height / 2
    
    *Projectile\Position = Position
    *Projectile\Angle = RandomInterval(2 * #PI, 0)
    
    ;the projectile velocity on both axis
    Protected ProjectileVel.f = Sqr(*Projectile\Velocity\x * *Projectile\Velocity\x +
                                    *Projectile\Velocity\y * *Projectile\Velocity\y)
    
    Protected ProjectileAliveTimer.f = Distance / ProjectileVel
    *Projectile\HasAliveTimer = #True
    *Projectile\AliveTimer = ProjectileAliveTimer
    
    AddDrawItemDrawList(*WatermelonEnemy\DrawList, *Projectile)
    
    *WatermelonEnemy\NumShots - 1
    
    If *WatermelonEnemy\NumShots < 1
      ProcedureReturn #True
    EndIf
  EndIf
  
  
  ProcedureReturn #False
  
EndProcedure

Procedure UpdateWatermelonEnemy(*WatermelonEnemy.TEnemy, TimeSlice.f)
  If *WatermelonEnemy\CurrentState = #EnemyNoState
    SwitchToFollowingPlayerEnemy(*WatermelonEnemy)
    ProcedureReturn
  EndIf
  
  If *WatermelonEnemy\CurrentState = #EnemyFollowingPlayer
    If IsCloseEneoughToPlayerEnemy(*WatermelonEnemy, 10 * *WatermelonEnemy\Width)
      
      ;SwitchToShootingTargetEnemy(*WatermelonEnemy, 1, *WatermelonEnemy\Player, 3, 0.5)
      Protected AreaAroundPlayer.TRect
      AreaAroundPlayer\Width = *WatermelonEnemy\Player\Width * 5
      AreaAroundPlayer\Height = *WatermelonEnemy\Player\Height * 5
      AreaAroundPlayer\Position\x = *WatermelonEnemy\Player\Position\x - (AreaAroundPlayer\Width / 2)
      AreaAroundPlayer\Position\y = *WatermelonEnemy\Player\Position\y - (AreaAroundPlayer\Height / 2)
      
      
      SwitchToShootingAreaEnemy(*WatermelonEnemy, @AreaAroundPlayer, 1.5, 9, 0.3)
      ;stop the enemy movement
      *WatermelonEnemy\Velocity\x = 0
      *WatermelonEnemy\Velocity\y = 0
    EndIf
    
    *WatermelonEnemy\StateTimer - TimeSlice
    If *WatermelonEnemy\StateTimer <= 0
      ;readjust with the current player's position
      SwitchToFollowingPlayerEnemy(*WatermelonEnemy)
      ProcedureReturn
    EndIf
    
  ElseIf *WatermelonEnemy\CurrentState = #EnemyShooting
    *WatermelonEnemy\ShootingTimer - TimeSlice
    If *WatermelonEnemy\ShootingTimer <= 0
      If ShootWatermelonEnemy(*WatermelonEnemy, TimeSlice)
        ;ended all shots
        SwitchToWaitingEnemy(*WatermelonEnemy, 2)
      EndIf
      
      
    EndIf
    
  ElseIf *WatermelonEnemy\CurrentState = #EnemyWaiting
    *WatermelonEnemy\WaitTimer - TimeSlice
    If *WatermelonEnemy\WaitTimer <= 0
      SwitchToFollowingPlayerEnemy(*WatermelonEnemy)
      ProcedureReturn
    EndIf
    
    
    
  EndIf
  
  
  UpdateGameObject(*WatermelonEnemy, TimeSlice)
EndProcedure

Procedure DrawWatermelonEnemy(*WatermelonEnemy.TEnemy)
  DrawEnemy(*WatermelonEnemy)
EndProcedure

Procedure InitWatermelonEnemy(*WatermelonEnemy.TEnemy, *Player.TGameObject, *Position.TVector2D,
                              SpriteNum.i, ZoomFactor.f, *ProjectileList.TProjectileList,
                              *DrawList.TDrawList)
  
  InitEnemy(*WatermelonEnemy, *Player, *ProjectileList, *DrawList, #EnemyWatermelon)
  
  *WatermelonEnemy\Health = 3.0
  
  InitGameObject(*WatermelonEnemy, *Position, SpriteNum, @UpdateWatermelonEnemy(), @DrawWatermelonEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *WatermelonEnemy\MaxVelocity\x = 80.0
  *WatermelonEnemy\MaxVelocity\y = 80.0
  
  *WatermelonEnemy\CurrentState = #EnemyNoState
  
  
EndProcedure

Procedure ShootTangerineEnemy(*TangerineEnemy.TEnemy, TimeSlice.f)
  Protected *Projectile.TProjectile = GetOwnedProjectile(*TangerineEnemy, *TangerineEnemy\Projectiles)
  If *Projectile <> #Null
    If *Projectile\EndedWayPoints
      *Projectile\Active = #False
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
    
  Else
    ;need to shoot a new one here
    *Projectile = GetInactiveProjectile(*TangerineEnemy\Projectiles)
    If *Projectile = #Null
      ProcedureReturn #True
    EndIf
    
    Protected Position.TVector2d
    
    Protected *Target.TGameObject = *TangerineEnemy\ShootingTarget
    
    UpdateMiddlePositionGameObject(*TangerineEnemy)
    UpdateMiddlePositionGameObject(*Target)
    
    
    Protected DeltaX.f, DeltaY.f, Distance.f
    DeltaX = *Target\MiddlePosition\x - *TangerineEnemy\MiddlePosition\x
    DeltaY = *Target\MiddlePosition\y - *TangerineEnemy\MiddlePosition\y
    ;Distance = Sqr(DeltaX * DeltaX + DeltaY * DeltaY)
    Protected Angle.f = ATan2(DeltaX, DeltaY)
    Debug Degree(Angle)
    
    InitProjectile(*Projectile, @Position, #True, #SPRITES_ZOOM, Angle, #ProjectileGomo1,
                   #False, 0, *TangerineEnemy)
    
    
    Position\x = *TangerineEnemy\MiddlePosition\x - (*Projectile\Width / 2)
    Position\y = *TangerineEnemy\MiddlePosition\y - (*Projectile\Height / 2)
    
    *Projectile\Position = Position
    
    NewList WayPoints.TRect()
    
    ;the first waypoint is the target positon
    Protected FirstWayPoint.TRect
    FirstWayPoint\Position\x = *Target\MiddlePosition\x
    FirstWayPoint\Position\y = *Target\MiddlePosition\y
    AddElement(WayPoints())
    WayPoints() = FirstWayPoint
    
    ;the second point is beyond (to the left or tight) of the first
    Protected SecondWayPoint.TRect\Position = FirstWayPoint\Position
    Protected.f CosSecondWayPoint, SinSecondWayPoint
    ;CosSecondWayPoint = Cos(Angle + Radian(40 * Sign(Angle)))
    ;SinSecondWayPoint = Sin(Angle + Radian(40 * Sign(Angle)))
    CosSecondWayPoint = Cos(Angle)
    SinSecondWayPoint = Sin(Angle)
    SecondWayPoint\Position\x + CosSecondWayPoint * 4 * *Target\Width
    SecondWayPoint\Position\y + SinSecondWayPoint * 4 * *Target\Width
    
    AddElement(WayPoints())
    WayPoints()\Position = SecondWayPoint\Position
    
    ;the third way point is the first one rotated 60 degrees around the tangerine position
    Protected ThirdWayPoint.TRect\Position = FirstWayPoint\Position
    Protected.f CosThirdWayPoint, SinThirdWayPoint
    CosThirdWayPoint = Cos(Angle + Radian(40 * Sign(Angle)))
    SinThirdWayPoint = Sin(Angle + Radian(40 * Sign(Angle)))
    ThirdWayPoint\Position\x + CosThirdWayPoint * 4 * *Target\Width
    ThirdWayPoint\Position\y + SinThirdWayPoint * 4 * *Target\Width
    
    AddElement(WayPoints())
    WayPoints()\Position = ThirdWayPoint\Position
    
    
    ;the fourth waypoint is at the tangerineenemy position, because the projectile will
    ;return to the enemy
    AddElement(WayPoints())
    WayPoints()\Position = *TangerineEnemy\MiddlePosition
    
    
    ;all waypoints have the same width and height
    ForEach WayPoints()
      WayPoints()\Width = *Projectile\Width * 0.8
      WayPoints()\Height = *Projectile\Height * 0.8
    Next
    
    SetWayPointsProjectile(*Projectile, WayPoints())
    
    AddDrawItemDrawList(*TangerineEnemy\DrawList, *Projectile)
    
    ProcedureReturn #False
    
    
    
    
    
  EndIf
  
EndProcedure

Procedure UpdateTangerineEnemy(*TangerineEnemy.TEnemy, TimeSlice.f)
  Protected *Player.TGameObject = *TangerineEnemy\Player
  If *TangerineEnemy\CurrentState = #EnemyNoState
    UpdateMiddlePositionGameObject(*TangerineEnemy)
    UpdateMiddlePositionGameObject(*Player)
    
    Protected DeltaX.f = *TangerineEnemy\MiddlePosition\x - *Player\MiddlePosition\x
    Protected DeltaY.f = *TangerineEnemy\MiddlePosition\y - *Player\MiddlePosition\y
    Protected Angle.f = ATan2(DeltaX, DeltaY)
    
    Protected ObjectiveRect.TRect\Width = *TangerineEnemy\Width * 0.8
    ObjectiveRect\Height = *TangerineEnemy\Height * 0.8
    
    Protected Radius.f = *Player\Width * 5
    
    ObjectiveRect\Position\x = *Player\MiddlePosition\x + Radius * Cos(angle)
    ObjectiveRect\Position\y = *Player\MiddlePosition\y + Radius * Sin(angle)
    
    
    SwitchToGoingToObjectiveRectEnemy(*TangerineEnemy, @ObjectiveRect, 0.5)
    ProcedureReturn
  EndIf
  
  If *TangerineEnemy\CurrentState = #EnemyGoingToObjectiveRect
    If HasReachedObjectiveRectEnemy(*TangerineEnemy)
      SwitchToShootingTargetEnemy(*TangerineEnemy, 0.5, *TangerineEnemy\Player)
      ProcedureReturn
    EndIf
    
    *TangerineEnemy\StateTimer - TimeSlice
    If *TangerineEnemy\StateTimer <= 0
      ;so we can go end retarget the objective rect
      SwitchStateEnemy(*TangerineEnemy, #EnemyNoState)
      ProcedureReturn
    EndIf
  ElseIf *TangerineEnemy\CurrentState = #EnemyShooting
    *TangerineEnemy\ShootingTimer - TimeSlice
    If *TangerineEnemy\ShootingTimer <= 0
      If ShootTangerineEnemy(*TangerineEnemy, TimeSlice)
        ;ended all shots
        SwitchStateEnemy(*TangerineEnemy, #EnemyNoState)
      EndIf
      
      
    EndIf
    
  EndIf
  
  
  UpdateGameObject(*TangerineEnemy, TimeSlice)
EndProcedure

Procedure DrawTangerineEnemy(*TangerineEnemy.TEnemy)
  If *TangerineEnemy\CurrentState = #EnemyGoingToObjectiveRect
    StartDrawing(ScreenOutput())
    Box(*TangerineEnemy\ObjectiveRect\Position\x, *TangerineEnemy\ObjectiveRect\Position\y,
        *TangerineEnemy\ObjectiveRect\Width, *TangerineEnemy\ObjectiveRect\Height, RGB($55, $65, $47))
    StopDrawing()
  EndIf
  
  DrawEnemy(*TangerineEnemy)
EndProcedure

Procedure InitTangerineEnemy(*TangerineEnemy.TEnemy, *Player.TGameObject, *Position.TVector2D,
                             SpriteNum.i, ZoomFactor.f, *ProjectileList.TProjectileList,
                             *DrawList.TDrawList)
  
  InitEnemy(*TangerineEnemy, *Player, *ProjectileList, *DrawList, #EnemyTangerine)
  
  *TangerineEnemy\Health = 4.0
  
  InitGameObject(*TangerineEnemy, *Position, SpriteNum, @UpdateTangerineEnemy(), @DrawTangerineEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *TangerineEnemy\MaxVelocity\x = 80.0
  *TangerineEnemy\MaxVelocity\y = 80.0
  
  *TangerineEnemy\CurrentState = #EnemyNoState
  
  
EndProcedure

;switch *enemy to patrolling state
;*setpatrollingenemy if set must be a procedure that will change values
;for the *enemy as it enters the patrolling state
;timerpatrolling is the time that *enemy will spend on this state
Procedure SwitchToPatrollingEnemy(*Enemy.TEnemy,
                                  *SetPatrollingEnemy.SetPatrollingEnemyProc = #Null,
                                  TimerPatrolling.f = 1.0)
  SwitchStateEnemy(*Enemy, #EnemyPatrolling)
  *Enemy\StateTimer = TimerPatrolling
  If *SetPatrollingEnemy <> #Null
    *SetPatrollingEnemy(*Enemy)
  EndIf
  
EndProcedure

Procedure SetPatrollingPineapple(*Pineapple.TEnemy)
  Protected HalfScreenWidth.f = ScreenWidth() / 2
  Protected HalfScreenHeight.f = ScreenHeight() / 2
  
  UpdateMiddlePositionGameObject(*Pineapple)
  
  If *Pineapple\MiddlePosition\x < HalfScreenWidth
    *Pineapple\Velocity\x = 100
  Else
    *Pineapple\Velocity\x = -100
  EndIf
  
  If *Pineapple\MiddlePosition\y < HalfScreenHeight
    *Pineapple\Velocity\y = 100
  Else
    *Pineapple\Velocity\y = -100
  EndIf
  
  
  
  
  
EndProcedure

Procedure UpdatePineappleEnemy(*Pineapple.TEnemy, TimeSlice.f)
  If *Pineapple\CurrentState = #EnemyNoState
    ;SwitchStateEnemy(*Pineapple, #EnemyPatrolling)
    SwitchToPatrollingEnemy(*Pineapple, @SetPatrollingPineapple(), 2.0)
    ProcedureReturn
  EndIf
  
  ;put more states here...
  If *Pineapple\CurrentState = #EnemyPatrolling
    *Pineapple\StateTimer - TimeSlice
    If *Pineapple\StateTimer <= 0
      SwitchToWaitingEnemy(*Pineapple, 2.0)
      ProcedureReturn
    EndIf
  ElseIf *Pineapple\CurrentState = #EnemyWaiting
    ;check if the player is near enough to attack it
    UpdateMiddlePositionGameObject(*Pineapple)
    UpdateMiddlePositionGameObject(*Pineapple\Player)
    
    Protected PositionPineapple.TVector2d = *Pineapple\MiddlePosition
    Protected PositionPlayer.TVector2D = *Pineapple\Player\MiddlePosition
    
    If DistanceBetweenPoints(PositionPineapple\x, PositionPineapple\y, PositionPlayer\x,
                             PositionPlayer\y) <= *Pineapple\Width * 5
      
      SwitchToFollowingPlayerEnemy(*Pineapple, 2.0)
      
      ProcedureReturn
    EndIf
    
    *Pineapple\WaitTimer - TimeSlice
    If *Pineapple\WaitTimer <= 0
      SwitchStateEnemy(*Pineapple, #EnemyNoState)
      ProcedureReturn
    EndIf
    
  ElseIf *Pineapple\CurrentState = #EnemyFollowingPlayer
    Protected *Player.TGameObject = *Pineapple\Player
    
    UpdateMiddlePositionGameObject(*Pineapple)
    UpdateMiddlePositionGameObject(*Player)
    
    Protected DeltaX.f = *Player\MiddlePosition\x - *Pineapple\MiddlePosition\x
    Protected DeltaY.f = *Player\MiddlePosition\y - *Pineapple\MiddlePosition\y
    Protected Angle.f = ATan2(DeltaX, DeltaY)
    
    *Pineapple\Velocity\x = Cos(Angle) * *Pineapple\MaxVelocity\x * 1.5
    *Pineapple\Velocity\y = Sin(Angle) * *Pineapple\MaxVelocity\y * 1.5
    
    *Pineapple\StateTimer - TimeSlice
    If *Pineapple\StateTimer <= 0
      SwitchStateEnemy(*Pineapple, #EnemyNoState)
      ProcedureReturn
    EndIf
    
    
  EndIf
  
  UpdateGameObject(*Pineapple, TimeSlice)
  
  
EndProcedure

Procedure DrawPineappleEnemy(*Pineapple.TEnemy)
  If *Pineapple\CurrentState = #EnemyGoingToObjectiveRect
    StartDrawing(ScreenOutput())
    Box(*Pineapple\ObjectiveRect\Position\x, *Pineapple\ObjectiveRect\Position\y,
        *Pineapple\ObjectiveRect\Width, *Pineapple\ObjectiveRect\Height, RGB($87, $198, $127))
    StopDrawing()
  EndIf
  
  DrawEnemy(*Pineapple)
  
EndProcedure

Procedure InitPineappleEnemy(*Pineapple.TEnemy, *Player.TGameObject, *Position.TVector2D,
                             SpriteNum.i, ZoomFactor.f, *DrawList.TDrawList)
  
  InitEnemy(*Pineapple, *Player, #Null, *DrawList, #EnemyPineapple)
  
  *Pineapple\Health = 5.0
  
  InitGameObject(*Pineapple, *Position, SpriteNum, @UpdatePineappleEnemy(), @DrawPineappleEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *Pineapple\MaxVelocity\x = 100.0
  *Pineapple\MaxVelocity\y = 100.0
  
  *Pineapple\CurrentState = #EnemyNoState
  
  
EndProcedure

Procedure SetPatrollingLemon(*Lemon.TEnemy)
  Dim Directions.b(3)
  ;   y -axis           x - axis            y - axis             x - axis
  Directions(0) = -1 : Directions(1) = 1 : Directions(2) = 1 : Directions(3) = -1
  
  Protected RandomDirection.a = Random(3, 0)
  If RandomDirection % 2
    ;y axis
    *Lemon\Velocity\x = 0.0
    *Lemon\Velocity\y = Directions(RandomDirection) * 120.0
  Else
    ;x axis
    *Lemon\Velocity\x = Directions(RandomDirection) * 120.0
    *Lemon\Velocity\y = 0.0
  EndIf
  
  
  
  
  
EndProcedure

Procedure ShootLemonEnemy(*Lemon.TEnemy, TimeSlice.f)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Lemon\Projectiles)
  If *Projectile = #Null
    ProcedureReturn #True
  EndIf
  
  Protected RandomAngle.f = Radian(Random(359, 0))
  
  InitProjectile(*Projectile, @*Lemon\Position, #True, #SPRITES_ZOOM, RandomAngle,
                 #ProjectileAcid1, #True, 5.0)
  
  AddDrawItemDrawList(*Lemon\DrawList, *Projectile)
  
  ProcedureReturn #True
  
EndProcedure

Procedure UpdateLemon(*Lemon.TEnemy, TimeSlice.f)
  If *Lemon\CurrentState = #EnemyNoState
    SwitchToPatrollingEnemy(*Lemon, @SetPatrollingLemon(), 3.0)
    ProcedureReturn
  EndIf
  
  If *Lemon\CurrentState = #EnemyPatrolling
    *Lemon\StateTimer - TimeSlice
    If *Lemon\StateTimer <= 0
      Protected ShotArea.TRect\Position\x = *Lemon\Position\x
      ShotArea\Position\y = *Lemon\Position\y
      ShotArea\Width = *Lemon\Width
      ShotArea\Height = *Lemon\Height
      
      *Lemon\Velocity\x = 0
      *Lemon\Velocity\y = 0
      
      SwitchToShootingAreaEnemy(*Lemon, @ShotArea, 1.0, 1)
      ProcedureReturn
    EndIf
    
    ;check if is going outside game area
    If *Lemon\Position\x < 0 Or (*Lemon\Position\x + *Lemon\Width) > ScreenWidth() - 1
      *Lemon\Velocity\x * -1
    EndIf
    
    If *Lemon\Position\y < 0 Or (*Lemon\Position\y + *Lemon\Height) > ScreenHeight() - 1
      *Lemon\Velocity\y * -1
    EndIf
    
    
  ElseIf *Lemon\CurrentState = #EnemyShooting
    *Lemon\ShootingTimer - TimeSlice
    If *Lemon\ShootingTimer <= 0
      If ShootLemonEnemy(*Lemon, TimeSlice)
        ;ended shooting
        SwitchStateEnemy(*Lemon, #EnemyNoState)
        ProcedureReturn
      EndIf
      
    EndIf
    
    
  EndIf
  
  UpdateGameObject(*Lemon, TimeSlice)
  
  
EndProcedure

Procedure InitLemonEnemy(*Lemon.TEnemy, *Player.TGameObject, *Position.TVector2D,
                         SpriteNum.i, ZoomFactor.f, *ProjectilesList.TProjectileList,
                         *DrawList.TDrawList)
  
  InitEnemy(*Lemon, *Player, *ProjectilesList, *DrawList, #EnemyLemon)
  
  *Lemon\Health = 6.0
  
  InitGameObject(*Lemon, *Position, SpriteNum, @UpdateLemon(), @DrawEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *Lemon\MaxVelocity\x = 100.0
  *Lemon\MaxVelocity\y = 100.0
  
  *Lemon\CurrentState = #EnemyNoState
  
EndProcedure

Procedure SetPatrollingCoconut(*Coconut.TEnemy)
  *Coconut\Velocity\x = 0
  *Coconut\Velocity\y = 0
  UpdateMiddlePositionGameObject(*Coconut)
  If Random(1, 0) = 1
    ;move vertically
    If *Coconut\MiddlePosition\y < ScreenHeight() / 2
      *Coconut\Velocity\y = *Coconut\MaxVelocity\y
    Else
      *Coconut\Velocity\y = *Coconut\MaxVelocity\y * -1
    EndIf
  Else
    ;move horizontally
    If *Coconut\MiddlePosition\x < ScreenWidth() / 2
      *Coconut\Velocity\x = *Coconut\MaxVelocity\x
    Else
      *Coconut\Velocity\x = *Coconut\MaxVelocity\x * -1
    EndIf
    
    
  EndIf
  
EndProcedure

Procedure ShootCoconutEnemy(*Coconut.TEnemy, TimeSlice.f)
  Protected NumShots.a = 4
  Protected AngleIncrease.f = Radian(360 / NumShots)
  Protected AngleStart.f
  If Random(1, 0) = 1
    AngleStart = Radian(0)
  Else
    AngleStart = Radian(45)
  EndIf
  
  UpdateMiddlePositionGameObject(*Coconut)
  
  
  Protected *Projectile.TProjectile = #Null
  
  While NumShots
    *Projectile = GetInactiveProjectile(*Coconut\Projectiles)
    If *Projectile = #Null
      NumShots - 1
      Continue
    EndIf
    
    Protected ProjectilePos.TVector2D
    
    InitProjectile(*Projectile, @ProjectilePos, #True, #SPRITES_ZOOM, AngleStart,
                   #ProjectileCocoSlice1, #False)
    
    *Projectile\Position\x = *Coconut\MiddlePosition\x - *Projectile\Width / 2
    *Projectile\Position\y = *Coconut\MiddlePosition\y - *Projectile\Height / 2
    
    AddDrawItemDrawList(*Coconut\DrawList, *Projectile)
    
    AngleStart + AngleIncrease
    
    NumShots - 1
  Wend
  
  ProcedureReturn #True
  
  
EndProcedure

Procedure UpdateCoconut(*Coconut.TEnemy, TimeSlice.f)
  If *Coconut\CurrentState = #EnemyNoState
    SwitchToPatrollingEnemy(*Coconut, @SetPatrollingCoconut(), 2.0)
    ProcedureReturn
  EndIf
  
  If *Coconut\CurrentState = #EnemyPatrolling
    *Coconut\StateTimer - TimeSlice
    If *Coconut\StateTimer <= 0
      SwitchToWaitingEnemy(*Coconut, 2.0)
      ProcedureReturn
    EndIf
    
    ;check if is going outside game area
    If *Coconut\Position\x < 0 Or (*Coconut\Position\x + *Coconut\Width) > ScreenWidth() - 1
      *Coconut\Velocity\x * -1
    EndIf
    
    If *Coconut\Position\y < 0 Or (*Coconut\Position\y + *Coconut\Height) > ScreenHeight() - 1
      *Coconut\Velocity\y * -1
    EndIf
    
  ElseIf *Coconut\CurrentState = #EnemyWaiting
    *Coconut\WaitTimer - TimeSlice
    If *Coconut\WaitTimer <= 0
      SwitchStateEnemy(*Coconut, #EnemyNoState)
      ProcedureReturn
    EndIf
    
    If IsCloseEneoughToPlayerEnemy(*Coconut, 4 * *Coconut\Width)
      SwitchToShootingTargetEnemy(*Coconut, 2.0, *Coconut\Player, 1)
      ProcedureReturn
    EndIf
    
  ElseIf *Coconut\CurrentState = #EnemyShooting
    *Coconut\ShootingTimer - TimeSlice
    If *Coconut\ShootingTimer <= 0
      If ShootCoconutEnemy(*Coconut, TimeSlice)
        ;ended shooting
        SwitchStateEnemy(*Coconut, #EnemyNoState)
        HurtEnemy(*Coconut, *Coconut\Health)
        ProcedureReturn
      EndIf
    EndIf
    
    
  EndIf
  
  
  UpdateGameObject(*Coconut, TimeSlice)
EndProcedure

Procedure DrawCoconut(*Coconut.TEnemy)
  If *Coconut\CurrentState = #EnemyShooting
    ;let's flash the coconut red to show that it will explode
    
    ;convert the shooting timer to ms
    Protected ShootingTimerMs = *Coconut\ShootingTimer * 1000
    
    ;after each 100 ms we will display the enemy using the red color
    If (ShootingTimerMs / 100) % 2
      ;if ShootingTimerMs / 100 is odd, we show the red
      DisplayTransparentSprite(*Coconut\SpriteNum, Int(*Coconut\Position\x),
                               Int(*Coconut\Position\y), $7f, RGB($eb, $1d, $13))
    Else
      ;if ShootingTimerMs / 100 is even, we show the regular sprite
      DrawEnemy(*Coconut)
    EndIf
    
    ProcedureReturn
    
  EndIf
  
  DrawEnemy(*Coconut)
EndProcedure

Procedure InitCoconutEnemy(*Coconut.TEnemy, *Player.TGameObject, *Position.TVector2D,
                           SpriteNum.i, ZoomFactor.f, *ProjectilesList.TProjectileList,
                           *DrawList.TDrawList)
  
  InitEnemy(*Coconut, *Player, *ProjectilesList, *DrawList, #EnemyCoconut)
  
  *Coconut\Health = 6.0
  
  InitGameObject(*Coconut, *Position, SpriteNum, @UpdateCoconut(), @DrawCoconut(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *Coconut\MaxVelocity\x = 100.0
  *Coconut\MaxVelocity\y = 100.0
  
  *Coconut\CurrentState = #EnemyNoState
  
EndProcedure

Procedure DrawJabuticabaShadow(*JabuticabaShadow.TGameObject)
  DrawGameObject(*JabuticabaShadow)
EndProcedure

Procedure SetJumpingJabuticaba(*Jabuticaba.TEnemy)
  
  *Jabuticaba\JumpVelocity = -250
  *Jabuticaba\Gravity = 180
  *Jabuticaba\JumpYDeslocation = 0.0
  
  *Jabuticaba\JumpPosition = *Jabuticaba\Position
  *Jabuticaba\IsOnGround = #False
  
  Protected IsCloseToPlayer.a = IsCloseEneoughToPlayerEnemy(*Jabuticaba,
                                                            6 * *Jabuticaba\Width)
  
  Protected ObjectiveJumpPosition.TVector2D
  If IsCloseToPlayer
    ObjectiveJumpPosition = *Jabuticaba\Player\MiddlePosition
  Else
    Protected MinX.f = *Jabuticaba\MiddlePosition\x - 6 * *Jabuticaba\Width
    Protected MaxX.f = *Jabuticaba\MiddlePosition\x + 6 * *Jabuticaba\Width
    MinX = ClampF(MinX, 0, ScreenWidth() - 1)
    MaxX = ClampF(MaxX, 0, ScreenWidth() - 1)
    
    ObjectiveJumpPosition\x = RandomInterval(MaxX, MinX)
    
    Protected MinY.f = *Jabuticaba\MiddlePosition\y - 6 * *Jabuticaba\Height
    Protected MaxY.f = *Jabuticaba\MiddlePosition\y + 6 * *Jabuticaba\Height
    
    MinY = ClampF(MinY, 0, ScreenHeight() - 1)
    MaxY = ClampF(MaxY, 0, ScreenHeight() - 1)
    
    ObjectiveJumpPosition\y = RandomInterval(MaxY, MinY)
  EndIf
  
  
  
    
  
  Protected DeltaX.f, DeltaY.f
  DeltaX = ObjectiveJumpPosition\x - *Jabuticaba\MiddlePosition\x
  DeltaY = ObjectiveJumpPosition\y - *Jabuticaba\MiddlePosition\y
  
  Protected Angle.f = ATan2(DeltaX, DeltaY)
  
  Protected ObjectiveRect.TRect\Width = *Jabuticaba\Width * 0.3
  ObjectiveRect\Height = *Jabuticaba\Height * 0.3
  
  ;we put the objective rect on the extreme of a circle around the player,
  ;with the radius as half the player width
  ;this way the jabuticaba enemy will land around the middle of the player
  Protected Radius.f = *Jabuticaba\Player\Width / 2
  ObjectiveRect\Position\x = (ObjectiveJumpPosition\x) + Cos(Angle) * Radius
  ObjectiveRect\Position\y = (ObjectiveJumpPosition\y) + Sin(Angle) * Radius
  
  
  DeltaX = ObjectiveRect\Position\x - *Jabuticaba\MiddlePosition\x
  DeltaY = ObjectiveRect\Position\y - *Jabuticaba\MiddlePosition\y
  
  Angle = ATan2(DeltaX, DeltaY)
  
  *Jabuticaba\Velocity\x = Cos(Angle) * *Jabuticaba\MaxVelocity\x
  *Jabuticaba\Velocity\y = Sin(Angle) * *Jabuticaba\MaxVelocity\y
  
  
  
  *Jabuticaba\ObjectiveRect = ObjectiveRect
  
  AddDrawItemDrawList(*Jabuticaba\DrawList, @*Jabuticaba\Shadow)
  InitGameObject(@*Jabuticaba\Shadow, @*Jabuticaba\Position, #JabuticabaShadow, #Null,
                 @DrawJabuticabaShadow(), #True, #SPRITES_ZOOM, #ShadowDrawOrder)
  

  
EndProcedure

Procedure UpdateJabuticabaEnemy(*Jabuticaba.TEnemy, TimeSlice.f)
  If *Jabuticaba\CurrentState = #EnemyNoState
    SwitchToWaitingEnemy(*Jabuticaba, 3.0)
    ProcedureReturn
  EndIf
  
  If *Jabuticaba\CurrentState = #EnemyWaiting
    *Jabuticaba\WaitTimer - TimeSlice
    If *Jabuticaba\WaitTimer <= 0.0
      ;jump towards player
      SwitchToPatrollingEnemy(*Jabuticaba, @SetJumpingJabuticaba())
      ProcedureReturn
    EndIf
    
  ElseIf *Jabuticaba\CurrentState = #EnemyPatrolling
    ;we use #enemypatrolling as the jumping state
    
    If Not *Jabuticaba\IsOnGround
      *Jabuticaba\JumpVelocity + *Jabuticaba\Gravity * TimeSlice
      Protected JumpFrameDeslocation.f = *Jabuticaba\JumpVelocity * TimeSlice
      
      ;we store how much the enemy has deslocated "up" when jumping
      *Jabuticaba\JumpYDeslocation + JumpFrameDeslocation
      
      *Jabuticaba\JumpPosition\y = *Jabuticaba\Position\y + *Jabuticaba\JumpYDeslocation
      
      *Jabuticaba\JumpPosition\x = *Jabuticaba\Position\x
    EndIf
  
    
    Protected EndedJump.a = #False
    
    If (Not *Jabuticaba\IsOnGround) And *Jabuticaba\JumpYDeslocation >= 0
      ;hit the gorund
      *Jabuticaba\JumpPosition\y = *Jabuticaba\Position\y
      *Jabuticaba\IsOnGround = #True
      
      EndedJump = #True
      ;deactivate the shadow
      *Jabuticaba\Shadow\Active = #False
    Else
      ;update the position of the shadow
      *Jabuticaba\Shadow\Position = *Jabuticaba\Position
      
    EndIf
    
    Protected ReachedObjectiveRect.a = HasReachedObjectiveRectEnemy(*Jabuticaba)
    If ReachedObjectiveRect
      *Jabuticaba\Velocity\x = 0
      *Jabuticaba\Velocity\y = 0
    EndIf
    
    
    If EndedJump
      SwitchStateEnemy(*Jabuticaba, #EnemyNoState)
      ProcedureReturn
    EndIf
    
    
    
    
    
  EndIf
  
  
  
  
  UpdateGameObject(*Jabuticaba, TimeSlice)
EndProcedure

Procedure DrawJabuticabaEnemy(*Jabuticaba.TEnemy)
  DisplayTransparentSprite(*Jabuticaba\SpriteNum, Int(*Jabuticaba\JumpPosition\x),
                           Int(*Jabuticaba\JumpPosition\y))
  If *Jabuticaba\CurrentState = #EnemyPatrolling
    ;DisplayTransparentSprite(#JabuticabaShadow, *Jabuticaba\Position\x, *Jabuticaba\Position\y)
    StartDrawing(ScreenOutput())
    
    Box(*Jabuticaba\ObjectiveRect\Position\x, *Jabuticaba\ObjectiveRect\Position\y,
        *Jabuticaba\ObjectiveRect\Width, *Jabuticaba\ObjectiveRect\Height, RGB(55, 200, 55))
    
    StopDrawing()
  ElseIf *Jabuticaba\CurrentState = #EnemyWaiting
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(*Jabuticaba\MiddlePosition\x, *Jabuticaba\MiddlePosition\y, 6 * *Jabuticaba\Width,
           RGB(75, 233, 125))
    
    StopDrawing()
    
  EndIf
  
EndProcedure

Procedure.a GetCollisionRectJabuticaba(*Jabuticaba.TEnemy, *CollisionRect.TRect)
  If *Jabuticaba\CurrentState <> #EnemyPatrolling
    ;use the regular collision code
    ProcedureReturn GetCollisionRectGameObject(*Jabuticaba, *CollisionRect)
  EndIf
  
  ;the *jabuticaba enemy is jumping, or the currentstate is #EnemyPatrolling
  ;so we just return that the enemy is not collidable for now
  ProcedureReturn #False
  
EndProcedure

Procedure InitJabuticabaEnemy(*Jabuticaba.TEnemy, *Player.TGameObject, *Position.TVector2D,
                              SpriteNum.i, ZoomFactor.f, *ProjectilesList.TProjectileList,
                              *DrawList.TDrawList)
  
  InitEnemy(*Jabuticaba, *Player, *ProjectilesList, *DrawList, #EnemyJabuticaba)
  
  *Jabuticaba\Health = 6.0
  
  InitGameObject(*Jabuticaba, *Position, SpriteNum, @UpdateJabuticabaEnemy(), @DrawJabuticabaEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *Jabuticaba\MaxVelocity\x = 100.0
  *Jabuticaba\MaxVelocity\y = 100.0
  
  *Jabuticaba\CurrentState = #EnemyNoState
  
  *Jabuticaba\JumpPosition = *Jabuticaba\Position
  
  ;overwirte the default collision code
  *Jabuticaba\GetCollisionRect = @GetCollisionRectJabuticaba()
  
EndProcedure

Procedure GetInativeTomatoClone(*Tomato.TEnemy)
  ForEach *Tomato\Clones()
    If Not *Tomato\Clones()\Active
      ;return an existing one
      ProcedureReturn @*Tomato\Clones()
    EndIf
  Next
  
  ;we need to create a new one
  Protected *TomatoClone = AddElement(*Tomato\Clones())
  If *TomatoClone <> 0
    ProcedureReturn *TomatoClone
  EndIf
  
  ProcedureReturn #Null
  
EndProcedure

Procedure UpdateTomatoEnemy(*Tomato.TEnemy, TimeSlice.f)
  If *Tomato\CurrentState = #EnemyNoState
    SwitchToWaitingEnemy(*Tomato, 0.150)
    ProcedureReturn
  EndIf
  
  If *Tomato\CurrentState = #EnemyWaiting
    *Tomato\WaitTimer - TimeSlice
    If *Tomato\WaitTimer <= 0.0
      ;get an random objective rect arund the tomato position
      Protected RandomRect.TRect\Width = *Tomato\Width * 0.8
      RandomRect\Height = *Tomato\Height * 0.8
      Protected Radius.f = RandomInterval(12 * *Tomato\Width, 8 * *Tomato\Width)
      Protected Angle.f = Radian(Random(359, 0))
      
      RandomRect\Position\x = *Tomato\Position\x + Cos(Angle) * Radius
      RandomRect\Position\y = *Tomato\Position\y + Sin(Angle) * Radius
      
      RandomRect\Position\x = ClampF(RandomRect\Position\x, 0, ScreenWidth() - 1 - RandomRect\Width)
      RandomRect\Position\y = ClampF(RandomRect\Position\y, 0, ScreenHeight() - 1 - RandomRect\Height)
      
      SwitchToGoingToObjectiveRectEnemy(*Tomato, RandomRect)
      *Tomato\CloneTimer = 0;after this time the *tomato will generate a clone
      ProcedureReturn
    EndIf
  ElseIf  *Tomato\CurrentState = #EnemyGoingToObjectiveRect
    If HasReachedObjectiveRectEnemy(*Tomato)
      SwitchStateEnemy(*Tomato, #EnemyNoState)
      ProcedureReturn
    EndIf
    
    *Tomato\CloneTimer - TimeSlice
    If *Tomato\CloneTimer <= 0.0
      ;time to generate a clone
      Protected *TomatoClone.TEnemyClone = GetInativeTomatoClone(*Tomato)
      If *TomatoClone <> #Null
        ;we got an available clone
        *TomatoClone\Active = #True
        ;we add 0.5 + timeslice because the clone will be processed at this frame
        *TomatoClone\Timer = #TOMATO_CLONE_TIMER + TimeSlice
        *TomatoClone\x = *Tomato\Position\x
        *TomatoClone\y = *Tomato\Position\y
      EndIf
      
      *Tomato\CloneTimer = #TOMATO_CLONING_TIMER
      
    EndIf
    
    
  EndIf
  
  ForEach *Tomato\Clones()
    If Not *Tomato\Clones()\Active
      Continue
    EndIf
    *Tomato\Clones()\Timer - TimeSlice
    If *Tomato\Clones()\Timer <= 0
      *Tomato\Clones()\Active = #False
    EndIf
    
    
  Next
  
  
  
  
  UpdateGameObject(*Tomato, TimeSlice)
  
  
EndProcedure

Procedure DrawTomatoEnemy(*Tomato.TEnemy)
  DrawEnemy(*Tomato)
  
  ForEach *Tomato\Clones()
    If *Tomato\Clones()\Active
      Protected Position.TVector2D\x = *Tomato\Clones()\x
      Position\y = *Tomato\Clones()\y
      
      DisplayTransparentSprite(*Tomato\SpriteNum, Int(Position\x), Int(Position\y))
    EndIf
    
  Next
  
EndProcedure

Procedure InitTomatoClones(*Tomato.TEnemy)
  ForEach *Tomato\Clones()
    *Tomato\Clones()\Active = #False
    *Tomato\Clones()\Timer = 0.0
  Next
  
EndProcedure

Procedure InitTomatoEnemy(*Tomato.TEnemy, *Player.TGameObject, *Position.TVector2D,
                              SpriteNum.i, ZoomFactor.f, *ProjectilesList.TProjectileList,
                              *DrawList.TDrawList)
  
  InitEnemy(*Tomato, *Player, *ProjectilesList, *DrawList, #EnemyTomato)
  
  *Tomato\Health = 7.0
  
  InitGameObject(*Tomato, *Position, SpriteNum, @UpdateTomatoEnemy(), @DrawTomatoEnemy(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *Tomato\MaxVelocity\x = 120.0
  *Tomato\MaxVelocity\y = 120.0
  
  *Tomato\CurrentState = #EnemyNoState
  
  *Tomato\CloneTimer = 0.0
  InitTomatoClones(*Tomato)
  
EndProcedure

Procedure UpdateEnemySpawner(*EnemySpawner.TEnemy, TimeSlice.f)
  If *EnemySpawner\CurrentState = #EnemyNoState
    SwitchToWaitingEnemy(*EnemySpawner, 5.0)
    ProcedureReturn
  EndIf
  
  If *EnemySpawner\CurrentState = #EnemyWaiting
    *EnemySpawner\WaitTimer - TimeSlice
    If *EnemySpawner\WaitTimer <= 0.0
      *EnemySpawner\SpawnEnemy(*EnemySpawner)
      KillEnemy(*EnemySpawner)
      ProcedureReturn
    EndIf
  EndIf
  
  UpdateGameObject(*EnemySpawner, TimeSlice)
  
EndProcedure

Procedure DrawEnemySpawner(*EnemySpawner.TEnemy)
  
  Protected TimerMs = *EnemySpawner\WaitTimer * 1000
  Protected IsOpaque = (TimerMs / 30) % 2
  ;after each 30 ms we will display the player transparent
  DrawGameObject(*EnemySpawner, 255 * IsOpaque)
EndProcedure

Procedure InitEnemySpawnerEnemy(*EnemySpawner.TEnemy, *Player.TGameObject, *Position.TVector2D,
                           SpriteNum.i, ZoomFactor.f, *ProjectilesList.TProjectileList,
                           *DrawList.TDrawList, *SpawnEnemy.SpawnEnemyProc)
  
  InitEnemy(*EnemySpawner, *Player, *ProjectilesList, *DrawList, #EnemySpawner_)
  
  *EnemySpawner\Health = 3.0
  
  InitGameObject(*EnemySpawner, *Position, SpriteNum, @UpdateEnemySpawner(), @DrawEnemySpawner(),
                 #True, ZoomFactor, #EnemyDrawOrder)
  
  *EnemySpawner\CurrentState = #EnemyNoState
  
  *EnemySpawner\SpawnEnemy = *SpawnEnemy
  
EndProcedure





DisableExplicit