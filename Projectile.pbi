XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration EProjectileTypes
  #ProjectileLaser1
  #ProjectileBarf1
  #ProjectileGrape1
  #ProjectileSeed1
  #ProjectileGomo1
  #ProjectileAcid1
  #ProjectileCocoSlice1
EndEnumeration


Structure TProjectile Extends TGameObject
  Angle.f;in radians
  Type.a
  Power.f
  HasAliveTimer.a
  AliveTimer.f
  *Owner.TGameObject
  List WayPoints.TRect()
  CurrentWayPoint.a
  EndedWayPoints.a
EndStructure

Structure TProjectileList
  List Projectiles.TProjectile()
EndStructure

Procedure GetOwnedProjectile(*Owner.TGameObject, *Projectiles.TProjectileList)
  ForEach *Projectiles\Projectiles()
    If *Projectiles\Projectiles()\Active And *Projectiles\Projectiles()\Owner = *Owner
      ProcedureReturn @*Projectiles\Projectiles()
    EndIf
    
  Next
  
  ProcedureReturn #Null
  
EndProcedure

Procedure GetInactiveProjectile(*Projectiles.TProjectileList, AddIfNotFound.a = #True)
  ForEach *Projectiles\Projectiles()
    If *Projectiles\Projectiles()\Active = #False
      ProcedureReturn @*Projectiles\Projectiles()
    EndIf
  Next
  
  If AddIfNotFound
    If AddElement(*Projectiles\Projectiles()) <> 0
      ;sucessfully added a new element, now return it
      ProcedureReturn *Projectiles\Projectiles()
    Else
      ;error allocating the element in the list
      ProcedureReturn #Null
    EndIf
  EndIf
  
  
  ProcedureReturn #Null
  
  
  
EndProcedure

Procedure DrawProjectile(*Projectile.TProjectile)
  RotateSprite(*Projectile\SpriteNum, Degree(*Projectile\Angle), #PB_Absolute)
  DrawGameObject(*Projectile)
  
  If ListSize(*Projectile\WayPoints())
    StartDrawing(ScreenOutput())
    Protected WayPointNum.a = 1
    ForEach *Projectile\WayPoints()
      Box(*Projectile\WayPoints()\Position\x, *Projectile\WayPoints()\Position\y,
          *Projectile\WayPoints()\Width, *Projectile\WayPoints()\Height, RGB($78, $23, $78))
      DrawText(*Projectile\WayPoints()\Position\x, *Projectile\WayPoints()\Position\y, StrU(WayPointNum, #PB_Byte))
      WayPointNum + 1
    Next
    
    StopDrawing()
  EndIf
  
  
  
EndProcedure

Procedure UpdateProjectile(*Projectile.TProjectile, TimeSlice.f)
  UpdateGameObject(*Projectile, TimeSlice)
  Protected ScreenRect.TRect\Position\x = 0
  ScreenRect\Position\y = 0
  ScreenRect\Width = ScreenWidth()
  ScreenRect\Height = ScreenHeight()
  
  Protected NoWayPoints.a = Bool(ListSize(*Projectile\WayPoints()) = 0)
  
  If NoWayPoints And Not CollisionRectRect(ScreenRect\Position\x, ScreenRect\Position\y, ScreenRect\Width,
                           ScreenRect\Height, *Projectile\Position\x, *Projectile\Position\y,
                           *Projectile\Width, *Projectile\Height)
    
    ;the projectile is outside of the visible screen
    *Projectile\Active = #False
    
  EndIf
  
  If *Projectile\HasAliveTimer
    *Projectile\AliveTimer - TimeSlice
    If *Projectile\AliveTimer <= 0
      *Projectile\Active = #False
    EndIf
    
  EndIf
  
  
  
EndProcedure

Procedure HurtProjectile(*Projectile.TProjectile, Power.f)
  *Projectile\Health - Power
  If *Projectile\Health <= 0
    *Projectile\Active = #False
  EndIf
  
EndProcedure

Procedure UpdateSeed1Projectile(*Projectile.TProjectile, TimeSlice.f)
  *Projectile\Angle + Radian(200.0) * TimeSlice
  UpdateProjectile(*Projectile, TimeSlice)
EndProcedure

Procedure.f GetProjectileVelocity(Type.a)
  Select Type
    Case #ProjectileLaser1
      
      ProcedureReturn 500.0
      
    Case #ProjectileBarf1
      
      ProcedureReturn 100.0
      
    Case #ProjectileGrape1
      
      ProcedureReturn 100.0
      
    Case #ProjectileSeed1
      
      ProcedureReturn 80.0
      
    Case #ProjectileGomo1
      
      ProcedureReturn 150.0
      
    Case #ProjectileCocoSlice1
      ProcedureReturn 175.0
      
  EndSelect
EndProcedure

Procedure UpdateGomo1Projectile(*Projectile.TProjectile, TimeSlice.f)
  SelectElement(*Projectile\WayPoints(), *Projectile\CurrentWayPoint - 1)
  Protected CurrentWayPoint.TRect = *Projectile\WayPoints()
  
  If CollisionRectRect(*Projectile\Position\x, *Projectile\Position\y, *Projectile\Width,
                       *Projectile\Height, CurrentWayPoint\Position\x,
                       CurrentWayPoint\Position\y, CurrentWayPoint\Width, CurrentWayPoint\Height)
    
    ;goes to the next way point
    *Projectile\CurrentWayPoint + 1
    
    If SelectElement(*Projectile\WayPoints(), *Projectile\CurrentWayPoint - 1) = 0
      ;end of way points
      *Projectile\Velocity\x = 0
      *Projectile\Velocity\y = 0
      *Projectile\EndedWayPoints = #True
    Else
      
      
      Protected DeltaX.f, DeltaY.f
      DeltaX = *Projectile\WayPoints()\Position\x - *Projectile\Position\x
      DeltaY = *Projectile\WayPoints()\Position\y - *Projectile\Position\y
      Protected Angle.f = ATan2(DeltaX, DeltaY)
      
      *Projectile\Velocity\x = Cos(Angle) * GetProjectileVelocity(*Projectile\Type)
      *Projectile\Velocity\y = Sin(Angle) * GetProjectileVelocity(*Projectile\Type)
      
    EndIf
    
    
    
    
    
  EndIf
  
  
  
  *Projectile\Angle + Radian(-200.0) * TimeSlice
  UpdateProjectile(*Projectile, TimeSlice)
EndProcedure

Procedure UpdateAcid1Projectile(*Acid1.TProjectile, TimeSlice.f)
  *Acid1\Velocity\x = 0.0
  *Acid1\Velocity\y = 0.0
  
  UpdateProjectile(*Acid1, TimeSlice)
EndProcedure

Procedure InitProjectile(*Projectile.TProjectile, *Pos.TVector2D, Active.a,
                         ZoomFactor.f, Angle.f, Type.a, HasAliveTimer.a = #False,
                         AliveTimer.f = 0.0, *Owner.TGameObject = #Null)
  
  Protected SpriteNum, Velocity.f, Power.f, Health.f, DrawOrder.l
  Protected *UpdateProjectileProc = @UpdateProjectile()
  
  Select Type
    Case #ProjectileLaser1
      SpriteNum = #Laser1
      
      Power = 1.0
      Health = 1.0
    Case #ProjectileBarf1
      SpriteNum = #Barf1
      
      Power = 1.0
      Health = 1.0
    Case #ProjectileGrape1
      SpriteNum = #Grape1
      
      Power = 1.0
      Health = 1.0
    Case #ProjectileSeed1
      SpriteNum = #Seed1
      
      Power = 2.0
      Health = 1.0
      *UpdateProjectileProc = @UpdateSeed1Projectile()
    Case #ProjectileGomo1
      SpriteNum = #Gomo1
      
      Power = 2.0
      Health = 1.0
      *UpdateProjectileProc = @UpdateGomo1Projectile()
      
    Case #ProjectileAcid1
      SpriteNum = #Acid1
      Power = 3.0
      Health = 1.0
      *UpdateProjectileProc = @UpdateAcid1Projectile()
      
    Case #ProjectileCocoSlice1
      SpriteNum = #CocoSlice1
      Power = 3.0
      Health = 1.0
      *UpdateProjectileProc = @UpdateSeed1Projectile()
  EndSelect
  
  DrawOrder = #ProjectileDrawOrder
  
  Velocity = GetProjectileVelocity(Type)
  
  InitGameObject(*Projectile, *Pos, SpriteNum, *UpdateProjectileProc, @DrawProjectile(),
                 Active, ZoomFactor, DrawOrder)
  *Projectile\Velocity\x = Cos(Angle) * Velocity
  *Projectile\Velocity\y = Sin(Angle) * Velocity
  
  *Projectile\Angle = Angle
  
  *Projectile\Type = Type
  
  *Projectile\Power = Power
  
  *Projectile\Health = Health
  
  *Projectile\HasAliveTimer = HasAliveTimer
  *Projectile\AliveTimer = AliveTimer
  
  *Projectile\Owner = *Owner
  
  *Projectile\MaxVelocity\x = 1000
  *Projectile\MaxVelocity\y = 1000
  
  ClearList(*Projectile\WayPoints())
  *Projectile\CurrentWayPoint = 1
  
  *Projectile\EndedWayPoints = #False
  
EndProcedure

Procedure SetWayPointsProjectile(*Projectile.TProjectile, List WayPoints.TRect())
  CopyList(WayPoints(), *Projectile\WayPoints())
  FirstElement(*Projectile\WayPoints())
  UpdateMiddlePositionGameObject(*Projectile)
  Protected DeltaX.f, DeltaY.f
  DeltaX = *Projectile\WayPoints()\Position\x - *Projectile\MiddlePosition\x
  DeltaY = *Projectile\WayPoints()\Position\y - *Projectile\MiddlePosition\y
  
  Protected Angle.f = ATan2(DeltaX, DeltaY)
  
  *Projectile\Velocity\x = Cos(Angle) * GetProjectileVelocity(*Projectile\Type)
  *Projectile\Velocity\y = Sin(Angle) * GetProjectileVelocity(*Projectile\Type)
  
EndProcedure

Procedure ResetWayPointsProjectile(*Projectile.TProjectile)
  ResetList(*Projectile\WayPoints())
  *Projectile\CurrentWayPoint = 1
EndProcedure



DisableExplicit