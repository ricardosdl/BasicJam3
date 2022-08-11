XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "Map.pbi"

EnableExplicit

Enumeration EProjectileTypes
  #ProjectileBomb1
  #ProjectileExplosion
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
  
  Protected Direction.a
  For Direction = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
    Protected CurrentPosition.TVector2D\x = Map_All_Directions(Direction)\x + CurrentTileX
    CurrentPosition\y = Map_All_Directions(Direction)\y + CurrentTileY
    
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
      CurrentPosition\x + Sign(Map_All_Directions(Direction)\x)
      CurrentPosition\y + Sign(Map_All_Directions(Direction)\y)
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
      
  EndSelect
EndProcedure

Procedure InitProjectile(*Projectile.TProjectile, *MapCoords.TVector2D, ProjectileType.a, *GameMap.TMap,
                         *DrawList.TDrawList, Power.a = 1, *Owner.TGameObject = #Null)
  
  *Projectile\PositionMapCoords\x = *MapCoords\x
  *Projectile\PositionMapCoords\y = *MapCoords\y
  
  *Projectile\ProjectileType = ProjectileType
  
  *Projectile\GameMap = *GameMap
  
  *Projectile\DrawList = *DrawList
  
  *Projectile\Power = Power
  
  *Projectile\Owner = *Owner
  
EndProcedure

Procedure InitProjectileBomb1(*Projectile.TProjectile, *MapCoords.TVector2D, *GameMap.TMap, *DrawList.TDrawList, Power.f,
                              *Owner.TGameObject)
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*MapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*MapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Projectile, @Position, #Bomb1, @UpdateProjectile(), @DrawProjectile(),
                 #True, 16, 16, #SPRITES_ZOOM, #ProjectileDrawOrder)
  
  InitProjectile(*Projectile, *MapCoords, #ProjectileBomb1, *GameMap, *DrawList, Power, *Owner)
  
  *Projectile\Health = 1.0
  
  *Projectile\HasAliveTimer = #True
  *Projectile\AliveTimer = 3.0;in seconds
  
  
  
  
  
  ClipSprite(#Bomb1, 0, 0, 16, 16)
  
EndProcedure

DisableExplicit