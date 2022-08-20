XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "Map.pbi"
XIncludeFile "SpriteAnimation.pbi"

EnableExplicit

Enumeration EProjectileTypes
  #ProjectileBomb1
  #ProjectileExplosion
EndEnumeration

#BOMB1_TIMER = 3.0
#EXPLOSION_ANIMATION_FPS = 12
#EXPLOSION_EXPANSION_TIMER = 250.0 / 1000.0

Structure TExplosionAnimation Extends TSpriteAnimation
  Position.TVector2D
  Timer.f
  Active.a
EndStructure

Structure TExplosionExpansion
  ExplosionExpansionTimer.f;seconds after the explosion will expand to the next tile
  Array OpenDirections.a(#MAP_NUM_LOOKING_DIRECTIONS - 1)
  CurrentExpansion.a
EndStructure

Structure TProjectile Extends TGameObject
  *GameMap.TMap
  PositionMapCoords.TVector2D
  ProjectileType.a
  Power.a;how many tiles the bomb fills when it explodes
  HasAliveTimer.a
  AliveTimer.f
  *Owner.TGameObject
  *DrawList.TDrawList
  *ProjectileList.TProjectileList
  ExplosionStarted.a
  List *ExplosionAnimations.TExplosionAnimation()
  ExplosionExpansion.TExplosionExpansion
EndStructure

Structure TProjectileList
  List Projectiles.TProjectile()
EndStructure

Declare InitProjectileExplosion(*Projectile.TProjectile, *MapCoords.TVector2D, *GameMap.TMap, *DrawList.TDrawList, Power.f,
                                  *Owner.TGameObject)

Global NewList ExplosionsAnimations.TExplosionAnimation()

Procedure GetInactiveExplosionAnimaton(AddIfNotFound.a = #True)
  ForEach ExplosionsAnimations()
    If Not ExplosionsAnimations()\Active
      ProcedureReturn @ExplosionsAnimations()
    EndIf
  Next
  
  If AddIfNotFound
    AddElement(ExplosionsAnimations())
    ProcedureReturn @ExplosionsAnimations()
  EndIf
  
  ProcedureReturn #Null
  
EndProcedure



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

Procedure IsThereActiveBombOnTile(*ProjectileList.TProjectileList, *TileCoords.TVector2D, *Owner.TGameObject = #Null)
  Protected *Bomb.TProjectile
  ForEach *ProjectileList\Projectiles()
    *Bomb = @*ProjectileList\Projectiles()
    If Not *Bomb\Active
      Continue
    EndIf
    
    If *Bomb\ProjectileType <> #ProjectileBomb1
      Continue
    EndIf
    
    If *Bomb\PositionMapCoords\x = *TileCoords\x And *Bomb\PositionMapCoords\y = *TileCoords\y
      ;is active and is a bomb, and is on the especified *tilecoords
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False
  
EndProcedure

Procedure IsThereActiveProjectileOnTile(*ProjectileList.TProjectileList, *TileCoords.TVector2D, *Owner.TGameObject = #Null)
  Protected *Projectile.TProjectile
  ForEach *ProjectileList\Projectiles()
    *Projectile = @*ProjectileList\Projectiles()
    If Not *Projectile\Active
      Continue
    EndIf
    
    If *Projectile\PositionMapCoords\x = *TileCoords\x And *Projectile\PositionMapCoords\y = *TileCoords\y
      ;is active and is a bomb, and is on the especified *tilecoords
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False
  
EndProcedure

Procedure DrawProjectile(*Projectile.TProjectile)
  DrawGameObject(*Projectile)
EndProcedure

Procedure ExplodeProjectile(*Projectile.TProjectile, TimeSlice.f)
  Protected CurrentTileX.u, CurrentTileY.u
  CurrentTileX = *Projectile\PositionMapCoords\x
  CurrentTileY = *Projectile\PositionMapCoords\y
  
  Protected *Explosion.TProjectile = GetInactiveProjectile(*Projectile\ProjectileList)
  If *Explosion = #Null
    ;no explosion :(
    ProcedureReturn
  EndIf
  
  
  InitProjectileExplosion(*Explosion, @*Projectile\PositionMapCoords, *Projectile\GameMap, *Projectile\DrawList,
                          *Projectile\Power, #Null)
  
  AddDrawItemDrawList(*Projectile\DrawList, *Explosion)
  
  
  
  
  
EndProcedure

Procedure KillProjectile(*Projectile.TProjectile)
  ForEach *Projectile\ExplosionAnimations()
    Protected *ExplosionAnimation.TExplosionAnimation = *Projectile\ExplosionAnimations()
    *ExplosionAnimation\Active = #False
    DeleteElement(*Projectile\ExplosionAnimations())
  Next
  
  *Projectile\Active = #False
  
EndProcedure

Procedure UpdateBomb1(*Projectile.TProjectile, TimeSlice.f)
  If *Projectile\HasAliveTimer And *Projectile\AliveTimer <= 0.0
    ;explode
    ExplodeProjectile(*Projectile, TimeSlice)
    KillProjectile(*Projectile)
    ProcedureReturn
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

Procedure.a GetCollisionCoordsProjectile(*Projectile.TProjectile, *CollisionCoords.TRect)
  GetTileCoordsByPosition(@*Projectile\MiddlePosition, @*CollisionCoords\Position)
  ProcedureReturn #True
EndProcedure

Procedure InitProjectile(*Projectile.TProjectile, *MapCoords.TVector2D, ProjectileType.a, *GameMap.TMap,
                         *DrawList.TDrawList, *ProjectileList.TProjectileList, Power.a = 1, *Owner.TGameObject = #Null)
  
  *Projectile\PositionMapCoords\x = *MapCoords\x
  *Projectile\PositionMapCoords\y = *MapCoords\y
  
  *Projectile\ProjectileType = ProjectileType
  
  *Projectile\GameMap = *GameMap
  
  *Projectile\DrawList = *DrawList
  
  *Projectile\Power = Power
  
  *Projectile\Owner = *Owner
  
  *Projectile\ProjectileList = *ProjectileList
  
  *Projectile\GetCollisionRect = @GetCollisionCoordsProjectile()
  
EndProcedure

Procedure InitProjectileBomb1(*Projectile.TProjectile, *MapCoords.TVector2D, *GameMap.TMap, *DrawList.TDrawList, Power.f,
                              *Owner.TGameObject, *ProjectileList.TProjectileList)
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*MapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*MapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Projectile, @Position, #Bomb1, @UpdateBomb1(), @DrawProjectile(),
                 #True, 16, 16, #SPRITES_ZOOM, #ProjectileDrawOrder)
  
  InitProjectile(*Projectile, *MapCoords, #ProjectileBomb1, *GameMap, *DrawList, *ProjectileList, Power, *Owner)
  
  *Projectile\Health = 1.0
  
  *Projectile\HasAliveTimer = #True
  *Projectile\AliveTimer = #BOMB1_TIMER;in seconds
  
  
  
  
  
  ClipSprite(#Bomb1, 0, 0, 16, 16)
  
EndProcedure

Procedure DrawExplosion(*Explosion.TProjectile)
  Protected *ExplosionAnimation.TExplosionAnimation
  ForEach *Explosion\ExplosionAnimations()
    *ExplosionAnimation = *Explosion\ExplosionAnimations()
    *ExplosionAnimation\Draw(*ExplosionAnimation, *ExplosionAnimation\Position\x, *ExplosionAnimation\Position\y)
  Next
  
EndProcedure

Procedure AddExplosionAnimation(*Explosion.TProjectile, *PositionCoords.TVector2D)
  ;add an explosion animation on the tile where the explosion starts
  Protected *ExplosionAnimation.TExplosionAnimation = GetInactiveExplosionAnimaton()
  If *ExplosionAnimation = #Null
    ;nothing to do? this is an error?
    ProcedureReturn
  EndIf
  
  InitSpriteAnimation(*ExplosionAnimation, #ExplosionSprite, 16, 16, 10, 0, #EXPLOSION_ANIMATION_FPS, #True, #SPRITES_ZOOM)
  
  ;the explosionanimation timer allows for the full animation to be played
  ;meaning all 10 frames will be displayed
  *ExplosionAnimation\Timer = 1 / #EXPLOSION_ANIMATION_FPS * 10
  *ExplosionAnimation\Active = #True
  
  *ExplosionAnimation\Position\x = (*PositionCoords\x * #MAP_GRID_TILE_WIDTH) +
                                   (#MAP_GRID_TILE_HALF_WIDTH) - (*ExplosionAnimation\ZoomedWidth / 2)
  *ExplosionAnimation\Position\y = (*PositionCoords\y * #MAP_GRID_TILE_HEIGHT) +
                                   (#MAP_GRID_TILE_HALF_HEIGHT) - (*ExplosionAnimation\ZoomedHeight / 2)
  
  AddElement(*Explosion\ExplosionAnimations())
  *Explosion\ExplosionAnimations() = *ExplosionAnimation
  ProcedureReturn *ExplosionAnimation
EndProcedure

Procedure UpdateExplosionExpansion(*Explosion.TProjectile, TimeSlice.f)
  If *Explosion\ExplosionExpansion\ExplosionExpansionTimer <= 0
    If *Explosion\ExplosionExpansion\CurrentExpansion > *Explosion\Power
      ;the expansion has reached its maximum
      ProcedureReturn
    EndIf
    
    *Explosion\ExplosionExpansion\ExplosionExpansionTimer = #EXPLOSION_EXPANSION_TIMER
    
    ;time to expand the explosion in the cardinal directions
    Protected DirectionIdx.a
    For DirectionIdx = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
      If Not *Explosion\ExplosionExpansion\OpenDirections(DirectionIdx)
        ;the explosion expansion ended in this direction, go to the next
        Continue
      EndIf
      
      Protected MapDirection.TMapDirection = Map_All_Directions(DirectionIdx)
      
      Protected PositionCoord.TVector2D
      PositionCoord\x = *Explosion\PositionMapCoords\x + *Explosion\ExplosionExpansion\CurrentExpansion * MapDirection\x
      PositionCoord\y = *Explosion\PositionMapCoords\y + *Explosion\ExplosionExpansion\CurrentExpansion * MapDirection\y
      
      If IsTileWalkable(*Explosion\GameMap, PositionCoord\x, PositionCoord\y)
        ;this tile is walkable just add an explosion animation on it
        AddExplosionAnimation(*Explosion, @PositionCoord)
        Continue
      EndIf
      
      Protected IsBreakable.a = IsTileBreakable(*Explosion\GameMap, PositionCoord\x, PositionCoord\y)
      If IsBreakable
        ;this tile is breakable, we add an explosion animation, but the explosion ends here in this current direction
        ;this tile is walkable just add an explosion animation on it
        AddExplosionAnimation(*Explosion, @PositionCoord)
        *Explosion\ExplosionExpansion\OpenDirections(DirectionIdx) = #False
        MakeTileWalkable(*Explosion\GameMap, PositionCoord\x, PositionCoord\y)
        AddExplodedTileMap(*Explosion\GameMap, @PositionCoord)
        Continue
      Else
        ;the tile is unbreakable, don't add explosion animation, but end the expansion on this direction
        *Explosion\ExplosionExpansion\OpenDirections(DirectionIdx) = #False
      EndIf
      
      
      
    Next
    *Explosion\ExplosionExpansion\CurrentExpansion + 1
    
  EndIf
  
  *Explosion\ExplosionExpansion\ExplosionExpansionTimer - TimeSlice
EndProcedure

Procedure UpdateExplosion(*Explosion.TProjectile, TimeSlice.f)
  
  Protected *ExplosionAnimation.TExplosionAnimation
  
  If Not *Explosion\ExplosionStarted
    *Explosion\ExplosionStarted = #True
    *ExplosionAnimation = AddExplosionAnimation(*Explosion, @*Explosion\PositionMapCoords)
    ProcedureReturn
  EndIf
  
  ForEach *Explosion\ExplosionAnimations()
    *ExplosionAnimation = *Explosion\ExplosionAnimations()
    
    If *ExplosionAnimation\Timer <= 0
      ;if the timer expired let's inactivate the animation and remove it from the current explosion list of animations
      *ExplosionAnimation\Active = #False
      DeleteElement(*Explosion\ExplosionAnimations())
      Continue
    EndIf
    
    ;the explosion animation is still active
    *ExplosionAnimation\Timer - TimeSlice
    ;update the animation
    *ExplosionAnimation\Update(*ExplosionAnimation, TimeSlice)
    
  Next
  
  If ListSize(*Explosion\ExplosionAnimations()) < 1
    ;the explosion ended
    KillProjectile(*Explosion)
    ProcedureReturn
  EndIf
  
  UpdateExplosionExpansion(*Explosion, TimeSlice)
  
  UpdateGameObject(*Explosion, TimeSlice)
EndProcedure

Procedure InitExplosionExpansion(*ExplosionExpansion.TExplosionExpansion, ExpansionTimer.f)
  *ExplosionExpansion\ExplosionExpansionTimer = ExpansionTimer
  *ExplosionExpansion\CurrentExpansion = 1
  Protected DirectionIdx.a
  For DirectionIdx = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
    *ExplosionExpansion\OpenDirections(DirectionIdx) = #True
  Next
  
EndProcedure


Procedure InitProjectileExplosion(*Projectile.TProjectile, *MapCoords.TVector2D, *GameMap.TMap, *DrawList.TDrawList, Power.f,
                                  *Owner.TGameObject)
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*MapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*MapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Projectile, @Position, -1, @UpdateExplosion(), @DrawExplosion(),
                 #True, 16, 16, #SPRITES_ZOOM, #ProjectileDrawOrder)
  
  InitProjectile(*Projectile, *MapCoords, #ProjectileExplosion, *GameMap, *DrawList, #Null, Power, *Owner)
  
  *Projectile\Health = 1.0
  
  *Projectile\HasAliveTimer = #False
  *Projectile\AliveTimer = 0
  
  *Projectile\ExplosionStarted = #False
  
  ClearList(*Projectile\ExplosionAnimations())
  
  InitExplosionExpansion(@*Projectile\ExplosionExpansion, #EXPLOSION_EXPANSION_TIMER)
  
  ClipSprite(#Bomb1, 0, 0, 16, 16)
  
  
  
EndProcedure

Procedure.a CheckCollisonProjectileExplosionMiddlePosition(*Explosion.TProjectile, *GameObject.TGameObject)
  
  Protected GameObjectCoords.TRect
  If *GameObject\GetCollisionRect(*GameObject, @GameObjectCoords) = #False
    ;the game object don't want to be collied with
    ProcedureReturn #False
  EndIf
  
  
  Protected *ExplosionAnimation.TExplosionAnimation
  ForEach *Explosion\ExplosionAnimations()
    *ExplosionAnimation = *Explosion\ExplosionAnimations()
    Protected ExplosionCoords.TVector2D
    GetTileCoordsByPosition(@*ExplosionAnimation\Position, @ExplosionCoords)
    If ExplosionCoords\x = GameObjectCoords\Position\x And ExplosionCoords\y = GameObjectCoords\Position\y
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False
  
  
  
  
  
EndProcedure


DisableExplicit