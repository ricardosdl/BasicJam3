XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "DrawList.pbi"

EnableExplicit

Enumeration EProjectileTypes
  #ProjectileBomb1
EndEnumeration


Structure TProjectile Extends TGameObject
  *GameMap.TMap
  PositionMapCoords.TVector2D
  ProjectileType.a
  Power.a;how many tiles the bomb fills when it explodes
  HasAliveTimer.a
  AliveTimer.f
  *Owner.TGameObject
  *DrawList.TDrawList
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

Procedure ExplodeProjectile(*Projectile.TProjectile, TimeSlice.f)
  Protected CurrentTileX.u, CurrentTileY.u
  CurrentTileX = *Projectile\PositionMapCoords\x
  CurrentTileY = *Projectile\PositionMapCoords\y
  
  Protected *GameMap.TMap = *Projectile\GameMap
  
  Protected BombPower.a = *Projectile\Power
  Protected NumPositions = 4
  Dim PositionsToCheck.TVector2D(NumPositions - 1)
  ;up position
  PositionsToCheck(0)\x = 0
  PositionsToCheck(0)\y = -1
  
  ;right position
  PositionsToCheck(1)\x = 1
  PositionsToCheck(1)\y = 0
  
  ;down position
  PositionsToCheck(2)\x = 0
  PositionsToCheck(2)\y = 1
  
  ;left position
  PositionsToCheck(3)\x = -1
  PositionsToCheck(3)\y = 0
  
  Protected i
  For i = 0 To NumPositions - 1
    Protected CurrentPosition.TVector2D\x = PositionsToCheck(i)\x + CurrentTileX
    CurrentPosition\y = PositionsToCheck(i)\y + CurrentTileY
    
    Protected TilesToCheck = BombPower
    While TilesToCheck
      Protected IsWalkable = IsTileWalkable(*GameMap, CurrentPosition\x, CurrentPosition\y)
      Protected IsBreakable = IsTileBreakable(*GameMap, CurrentPosition\x, CurrentPosition\y)
      
      If IsWalkable And Not IsBreakable
        ;hit clear path
        ;TODO: something to do later?
      ElseIf IsBreakable And Not IsWalkable
        ;hit a breakabe wall
        MakeTileWalkable(*GameMap, CurrentPosition\x, CurrentPosition\y)
        ;the explosion ends here
        Break
      ElseIf (Not IsWalkable) And (Not IsBreakable)
        ;hit a unbreakable wall
        ;the explosion ends here
        Break
      EndIf
      
      TilesToCheck - 1
      CurrentPosition\x + Sign(PositionsToCheck(i)\x)
      CurrentPosition\y + Sign(PositionsToCheck(i)\y)
    Wend
    
    
  Next
  
  
  
  
  
EndProcedure

Procedure UpdateProjectile(*Projectile.TProjectile, TimeSlice.f)
  If *Projectile\HasAliveTimer And *Projectile\AliveTimer <= 0.0
    ;explode
    ExplodeProjectile(*Projectile, TimeSlice)
    *Projectile\Active = #False
  EndIf
  
  If *Projectile\HasAliveTimer
    *Projectile\AliveTimer - TimeSlice
  EndIf
  
  
  UpdateGameObject(*Projectile, TimeSlice)
EndProcedure

Procedure SetProjectileAliveTimer(*Projectile.TProjectile, ProjectileType.a)
  Select ProjectileType
    Case #ProjectileBomb1
      *Projectile\HasAliveTimer = #True
      *Projectile\AliveTimer = 2.0;in seconds
  EndSelect
EndProcedure

Procedure InitProjectile(*Projectile.TProjectile, *MapCoords.TVector2D, Active.a,
                         ZoomFactor.f, ProjectileType.a, *GameMap.TMap, *DrawList.TDrawList, Power.a = 1, *Owner.TGameObject = #Null)
  
  *Projectile\PositionMapCoords\x = *MapCoords\x
  *Projectile\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*Projectile\PositionMapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*Projectile\PositionMapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Projectile, @Position, #Bomb1, @UpdateProjectile(), @DrawProjectile(),
                 Active, ZoomFactor, #ProjectileDrawOrder)
  
  ClipSprite(#Bomb1, 0, 0, 16, 16)
  
  *Projectile\ProjectileType = ProjectileType
  
  *Projectile\GameMap = *GameMap
  
  *Projectile\DrawList = *DrawList
  
  *Projectile\Power = Power
  
  *Projectile\Health = 1.0
  
  SetProjectileAliveTimer(*Projectile, ProjectileType)
  
  *Projectile\Owner = *Owner
  
EndProcedure

DisableExplicit