XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration EProjectileTypes
  #ProjectileBomb1
EndEnumeration


Structure TProjectile Extends TGameObject
  *GameMap.TMap
  PositionMapCoords.TVector2D
  ProjectileType.a
  Power.f;how many tiles the bomb fills when it explodes
  HasAliveTimer.a
  AliveTimer.f
  *Owner.TGameObject
EndStructure

Structure TProjectileList
  List Projectiles.TProjectile()
EndStructure

Procedure GetActiveOwnedProjectile(*Owner.TGameObject, *Projectiles.TProjectileList)
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
      ProcedureReturn @*Projectiles\Projectiles()
    Else
      ;error allocating the element in the list
      ProcedureReturn #Null
    EndIf
  EndIf
  
  
  ProcedureReturn #Null
  
  
  
EndProcedure

Procedure GetNumActiveOwnedProjectiles(*ProjectileList.TProjectileList, *Owner.TGameObject)
  Protected NumProjectiles = 0
  ForEach *ProjectileList\Projectiles()
    If *ProjectileList\Projectiles()\Active And *ProjectileList\Projectiles()\Owner = *Owner
      NumProjectiles + 1
    EndIf
  Next
  
  ProcedureReturn NumProjectiles
  
EndProcedure

Procedure DrawProjectile(*Projectile.TProjectile)
  DrawGameObject(*Projectile)
EndProcedure

Procedure UpdateProjectile(*Projectile.TProjectile, TimeSlice.f)
  If *Projectile\HasAliveTimer And *Projectile\AliveTimer <= 0.0
    ;explode
    *Projectile\Active = #False
  EndIf
  
  If *Projectile\HasAliveTimer
    *Projectile\AliveTimer - TimeSlice
  EndIf
  
  
  UpdateGameObject(*Projectile, TimeSlice)
EndProcedure

Procedure HurtProjectile(*Projectile.TProjectile, Power.f)
  *Projectile\Health - Power
  If *Projectile\Health <= 0
    *Projectile\Active = #False
  EndIf
  
EndProcedure

Procedure SetProjectileAliveTimer(*Projectile.TProjectile, ProjectileType.a)
  Select ProjectileType
    Case #ProjectileBomb1
      *Projectile\HasAliveTimer = #True
      *Projectile\AliveTimer = 2.0;in seconds
  EndSelect
EndProcedure

Procedure InitProjectile(*Projectile.TProjectile, *MapCoords.TVector2D, Active.a,
                         ZoomFactor.f, ProjectileType.a, *GameMap.TMap, Power.f = 1.0, *Owner.TGameObject = #Null)
  
  *Projectile\PositionMapCoords\x = *MapCoords\x
  *Projectile\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*Projectile\PositionMapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*Projectile\PositionMapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Projectile, @Position, #Bomb1, @UpdateProjectile(), @DrawProjectile(),
                 Active, ZoomFactor, #ProjectileDrawOrder)
  
  ClipSprite(#Bomb1, 0, 0, 16, 16)
  
  *Projectile\ProjectileType = ProjectileType
  
  *Projectile\Power = Power
  
  *Projectile\Health = 1.0
  
  SetProjectileAliveTimer(*Projectile, ProjectileType)
  
  *Projectile\Owner = *Owner
  
EndProcedure

DisableExplicit