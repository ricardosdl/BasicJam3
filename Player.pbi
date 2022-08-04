XIncludeFile "GameObject.pbi"
XIncludeFile "Resources.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "Map.pbi"
XIncludeFile "Projectile.pbi"

EnableExplicit

Structure TPlayer Extends TGameObject
  *GameMap.TMap
  PositionMapCoords.TVector2D
  BombPower.f
  CurrentBombsLimit.a;max num of bombs that the player can evacuate
  *ProjectileList.TProjectileList
  CurrentBombType.a
  *DrawList.TDrawList
EndStructure

Procedure PutBombPlayer(*Player.TPlayer)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Player\ProjectileList)
  If *Projectile = #Null
    ;couldn't allocate the memory for a bomb :(
    ProcedureReturn #False
  EndIf
  
  Protected BombTileCoords.TVector2D
  GetTileCoordsByPosition(*Player\MiddlePosition, @BombTileCoords)
  
  InitProjectile(*Projectile, @BombTileCoords, #True, #SPRITES_ZOOM, *Player\CurrentBombType, *Player\GameMap,
                 *Player\DrawList, *Player\BombPower, *Player)
  
  AddDrawItemDrawList(*Player\DrawList, *Projectile)
  
  ProcedureReturn #True
  
EndProcedure

Procedure UpdatePlayer(*Player.TPlayer, TimeSlice.f)
  Protected Up, Right, Down, Left, PutBomb
  Up = KeyboardReleased(#PB_Key_Up)
  Right = KeyboardReleased(#PB_Key_Right)
  Down = KeyboardReleased(#PB_Key_Down)
  Left = KeyboardReleased(#PB_Key_Left)
  PutBomb = KeyboardReleased(#PB_Key_Z)
  
  Protected NextCoords.TVector2D = *Player\PositionMapCoords
  
  If Up
    NextCoords\y - 1
  EndIf
  
  If Right
    NextCoords\x + 1
  EndIf
  
  If Down
    NextCoords\y + 1
  EndIf
  
  If Left
    NextCoords\x - 1
  EndIf
  
  If IsTileWalkable(*Player\GameMap, NextCoords\x, NextCoords\y)
    *Player\PositionMapCoords = NextCoords
  EndIf
  
  Protected NewPosition.TVector2D\x = *Player\GameMap\Position\x + (*Player\PositionMapCoords\x * #MAP_GRID_TILE_WIDTH)
  NewPosition\y = *Player\GameMap\Position\y + (*Player\PositionMapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  *Player\Position = NewPosition
  
  If PutBomb
    ;pressed the key to put a bomb
    ;get the num of active bombs for the player
    Protected NumActiveBombsPlayer = GetNumActiveOwnedProjectiles(*Player\ProjectileList, *Player)
    If NumActiveBombsPlayer < *Player\CurrentBombsLimit
      ;the player can put a bomb
      PutBombPlayer(*Player)
    EndIf
    
    
    
  EndIf
  
  
  UpdateGameObject(*Player, TimeSlice)
  
  
EndProcedure

Procedure DrawPlayer(*Player.TPlayer)
  DrawGameObject(*Player)
EndProcedure

Procedure.a GetCollisionRectPlayer(*Player.TPlayer, *CollisionRect.TRect)
  *CollisionRect\Width = *Player\Width * 0.3
  *CollisionRect\Height = *Player\Height * 0.3
  
  *CollisionRect\Position\x = (*Player\Position\x + *Player\Width / 2) - *CollisionRect\Width / 2
  *CollisionRect\Position\y = (*Player\Position\y + *Player\Height / 2) - *CollisionRect\Height / 2
  
  ProcedureReturn #True
  
EndProcedure

Procedure InitPlayer(*Player.TPlayer, *MapCoords.TVector2D, ZoomFactor.f, *DrawList.TDrawList, *GameMap.TMap,
                     *ProjectileList.TProjectileList)
  ;the player has a reference to the game map
  *Player\GameMap = *GameMap
  *Player\PositionMapCoords\x = *MapCoords\x
  *Player\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*Player\PositionMapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*Player\PositionMapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  
  InitGameObject(*Player, @Position, #Player1, @UpdatePlayer(), @DrawPlayer(), #True, ZoomFactor,
                 #PlayerDrawOrder)
  
  ClipSprite(#Player1, 0, 0, 16, 16)
  
  *Player\DrawList = *DrawList
  
  *Player\GetCollisionRect = @GetCollisionRectPlayer()
  
  *Player\Health = 5.0
  
  *Player\BombPower = 1.0
  
  *Player\ProjectileList = *ProjectileList
  
  *Player\CurrentBombsLimit = 1
  
  *Player\CurrentBombType = #ProjectileBomb1
  
EndProcedure

Procedure HurtPlayer(*Player.TPlayer, Power.f)
  *Player\Health - Power
  
  If *Player\Health <= 0
    ;TODO: kill the player
    Debug "player died"
  EndIf
  
EndProcedure





DisableExplicit