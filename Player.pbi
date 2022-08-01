XIncludeFile "GameObject.pbi"
XIncludeFile "Projectile.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

#PLAYER_SHOOT_TIMER = 1.0 / 3.0

Structure TPlayer Extends TGameObject
  *Projectiles.TProjectileList
  IsShooting.a
  ShootTimer.f
  LastMovementAngle.f;in radians
  *DrawList.TDrawList
  HurtTimer.f
EndStructure

Procedure PlayerShoot(*Player.TPlayer, TimeSlice.f)
  *Player\ShootTimer + TimeSlice
  If *Player\ShootTimer >= #PLAYER_SHOOT_TIMER
    ;shoot
    Protected PlayerShootingAngle.f = *Player\LastMovementAngle
    Protected *Projectile.TProjectile = GetInactiveProjectile(*Player\Projectiles)
    
    Protected Position.TVector2D
    InitProjectile(*Projectile, @Position, #True, #SPRITES_ZOOM, PlayerShootingAngle, #ProjectileLaser1)
    
    AddDrawItemDrawList(*Player\DrawList, *Projectile)
    
    Position\x = *Player\MiddlePosition\x - *Projectile\Width / 2
    Position\y = *Player\MiddlePosition\y - *Projectile\Height / 2
    
    *Projectile\Position = Position
    
    *Player\ShootTimer = 0.0
    
  EndIf
  
EndProcedure

Procedure UpdatePlayer(*Player.TPlayer, TimeSlice.f)
  *Player\Velocity\x = 0
  *Player\Velocity\y = 0
  
  If KeyboardPushed(#PB_Key_Left)
    *Player\IsShooting = #True
    *Player\Velocity\x = -200
  EndIf
  
  If KeyboardPushed(#PB_Key_Right)
    *Player\IsShooting = #True
    *Player\Velocity\x = 200
  EndIf
  
  If KeyboardPushed(#PB_Key_Up)
    *Player\IsShooting = #True
    *Player\Velocity\y = -200
  EndIf
  
  If KeyboardPushed(#PB_Key_Down)
    *Player\IsShooting = #True
    *Player\Velocity\y = 200
  EndIf
  
  If (*Player\Velocity\x <> 0) Or (*Player\Velocity\y <> 0)
    *Player\LastMovementAngle = ATan2(*Player\Velocity\x, *Player\Velocity\y)
  EndIf
  
    
  
  If *Player\IsShooting
    PlayerShoot(*Player, TimeSlice)
  EndIf
  
  If *Player\HurtTimer > 0.0
    *Player\HurtTimer - TimeSlice
  EndIf
  
  
  UpdateGameObject(*Player, TimeSlice)
  
  ;limits the playe to the play area (game screen)
  If *Player\Position\x < 0
    *Player\Position\x = 0
  EndIf
  
  If *Player\Position\y < 0
    *Player\Position\y = 0
  EndIf
  
  If *Player\Position\x + *Player\Width > ScreenWidth() - 1
    *Player\Position\x = (ScreenWidth() - 1) - *Player\Width
  EndIf
  
  If *Player\Position\y + *Player\Height > ScreenHeight() - 1
    *Player\Position\y = (ScreenHeight() - 1) - *Player\Height
  EndIf
  
  
  
  
    
  
EndProcedure

Procedure DrawPlayer(*Player.TPlayer)
  If *Player\HurtTimer <= 0
    DrawGameObject(*Player)
  Else
    Protected HurtTimerMs = *Player\HurtTimer * 1000
    
    Protected IsOpaque = (HurtTimerMs / 100) % 2
    
    ;after each 100 ms we will display the player transparent
    DrawGameObject(*Player, 255 * IsOpaque)
  EndIf
  
  Protected PlayerRect.TRect
  *Player\GetCollisionRect(*Player, @PlayerRect)
  StartDrawing(ScreenOutput())
  Box(PlayerRect\Position\x, PlayerRect\Position\y, PlayerRect\Width, PlayerRect\Height,
      RGB(192, 33, 87))
  StopDrawing()
EndProcedure

Procedure.a GetCollisionRectPlayer(*Player.TPlayer, *CollisionRect.TRect)
  *CollisionRect\Width = *Player\Width * 0.3
  *CollisionRect\Height = *Player\Height * 0.3
  
  *CollisionRect\Position\x = (*Player\Position\x + *Player\Width / 2) - *CollisionRect\Width / 2
  *CollisionRect\Position\y = (*Player\Position\y + *Player\Height / 2) - *CollisionRect\Height / 2
  
  ;if the player is hurt we don't return it as collidable
  ProcedureReturn Bool(*Player\HurtTimer <= 0)
  
EndProcedure

Procedure InitPlayer(*Player.TPlayer, *ProjectilesList.TProjectileList, *Pos.TVector2D, IsShooting.a, ZoomFactor.f, *DrawList.TDrawList)
  InitGameObject(*Player, *Pos, #Player1, @UpdatePlayer(), @DrawPlayer(), #True, ZoomFactor,
                 #PlayerDrawOrder)
  
  *Player\Projectiles = *ProjectilesList
  
  *Player\IsShooting = IsShooting
  
  *Player\DrawList = *DrawList
  
  *Player\MaxVelocity\x = 500
  *Player\MaxVelocity\y = 500
  
  *Player\GetCollisionRect = @GetCollisionRectPlayer()
  
  *Player\Health = 5.0
  
  *Player\HurtTimer = 0.0
  
EndProcedure

Procedure HurtPlayer(*Player.TPlayer, Power.f)
  *Player\Health - Power
  *Player\HurtTimer = 2.5
  If *Player\Health <= 0
    ;TODO: kill the player
    Debug "player died"
  EndIf
  
EndProcedure





DisableExplicit