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
  CollisionRect.a
EndStructure

Procedure PutBombPlayer(*Player.TPlayer)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Player\ProjectileList)
  If *Projectile = #Null
    ;couldn't allocate the memory for a bomb :(
    ProcedureReturn #False
  EndIf
  
  InitProjectile(*Projectile, @*Player\PositionMapCoords, #True, #SPRITES_ZOOM, *Player\CurrentBombType, *Player\GameMap,
                 *Player\DrawList, *Player\BombPower, *Player)
  
  AddDrawItemDrawList(*Player\DrawList, *Projectile)
  
  ProcedureReturn #True
  
EndProcedure

Procedure GetMapCollisionRectPlayer(*Player.TPlayer, *CollisionRect.TRect)
  *CollisionRect\Width = *Player\Width  * 0.6
  *CollisionRect\Height = *Player\Height * 0.6
  *CollisionRect\Position\x = (*Player\Position\x + *Player\Width / 2) - (*CollisionRect\Width / 2)
  *CollisionRect\Position\y = (*Player\Position\y + *Player\Height / 2) - (*CollisionRect\Height / 2)
EndProcedure

Procedure UpdateGameObjectPlayer(*Player.TPlayer, TimeSlice.f)
  *Player\LastPosition = *Player\Position
  
  ;update the horizontal axis position
  *Player\Position\x + *Player\Velocity\x * TimeSlice
  
  ;check collision with gamemap tiles around the player
  Protected StartColumn.u = Int(*Player\Position\x / #MAP_GRID_TILE_WIDTH)
  Protected EndColumn.u = Int((*Player\Position\x + *Player\Width) / #MAP_GRID_TILE_WIDTH)
  
  Protected StartRow.u = Int(*Player\Position\y / #MAP_GRID_TILE_HEIGHT)
  Protected EndRow.u = Int((*Player\Position\y + *Player\Height) / #MAP_GRID_TILE_HEIGHT)
  
  Protected CollisionRect.TRect
  GetMapCollisionRectPlayer(*Player, @CollisionRect)
  
  Protected TileRect.TRect\Width = #MAP_GRID_TILE_WIDTH
  TileRect\Height = #MAP_GRID_TILE_HEIGHT
  
  Protected IsTileWalkable.a
  
  Protected Column.u, Row.u
  For Column = StartColumn To EndColumn
    For Row = StartRow To EndRow
      If IsTileWalkable(*Player\GameMap, Column, Row)
        Continue
      EndIf
      
      TileRect.TRect\Position\x = Column * #MAP_GRID_TILE_WIDTH
      TileRect\Position\y = Row * #MAP_GRID_TILE_HEIGHT
      If CollisionRectRect(TileRect\Position\x, TileRect\Position\y, TileRect\Width, TileRect\Height,
                           CollisionRect\Position\x, CollisionRect\Position\y, CollisionRect\Width, CollisionRect\Height)
        ;if collided with the gamemap tiles we revert to the last position
        *Player\Position = *Player\LastPosition
        ;changed the position, we need to update the collisionrect
        GetMapCollisionRectPlayer(*Player, @CollisionRect)
      EndIf
    Next
  Next
  
  ;if we updated the x position, we se the last positon here
  *Player\LastPosition\x = *Player\Position\x
  
  ;update the vertical axis position
  *Player\Position\y + *Player\Velocity\y * TimeSlice
  
  StartColumn = Int(*Player\Position\x / #MAP_GRID_TILE_WIDTH)
  EndColumn = Int((*Player\Position\x + *Player\Width) / #MAP_GRID_TILE_WIDTH)
  
  StartRow = Int(*Player\Position\y / #MAP_GRID_TILE_HEIGHT)
  EndRow = Int((*Player\Position\y + *Player\Height) / #MAP_GRID_TILE_HEIGHT)
  
  GetMapCollisionRectPlayer(*Player, @CollisionRect)
  
  ;check collision with the gamemap tiles
  For Column = StartColumn To EndColumn
    For Row = StartRow To EndRow
      If IsTileWalkable(*Player\GameMap, Column, Row)
        Continue
      EndIf
      
      TileRect.TRect\Position\x = Column * #MAP_GRID_TILE_WIDTH
      TileRect\Position\y = Row * #MAP_GRID_TILE_HEIGHT
      If CollisionRectRect(TileRect\Position\x, TileRect\Position\y, TileRect\Width, TileRect\Height,
                           CollisionRect\Position\x, CollisionRect\Position\y, CollisionRect\Width, CollisionRect\Height)
        ;if collided with the gamemap tiles we revert to the last position
        *Player\Position = *Player\LastPosition
        ;changed the position, we need to update the collisionrect
        GetMapCollisionRectPlayer(*Player, @CollisionRect)
      EndIf
    Next
  Next
  
  *Player\MiddlePosition\x = *Player\Position\x + *Player\Width / 2
  *Player\MiddlePosition\y = *Player\Position\y + *Player\Height / 2
EndProcedure

Procedure UpdatePlayer(*Player.TPlayer, TimeSlice.f)
  *Player\Velocity\x = 0
  *Player\Velocity\y = 0
  
  Protected Up, Right, Down, Left, PutBomb
  Up = KeyboardPushed(#PB_Key_Up)
  Right = KeyboardPushed(#PB_Key_Right)
  Down = KeyboardPushed(#PB_Key_Down)
  Left = KeyboardPushed(#PB_Key_Left)
  PutBomb = KeyboardReleased(#PB_Key_Z)
  
  If Up
    *Player\Velocity\y = -100
  ElseIf Down
    *Player\Velocity\y = 100
  EndIf
  
  If Right
    *Player\Velocity\x = 100
  ElseIf Left
    *Player\Velocity\x = -100
  EndIf
  
  If PutBomb
    ;pressed the key to put a bomb
    ;get the num of active bombs for the player
    Protected NumActiveBombsPlayer = GetNumActiveOwnedProjectiles(*Player\ProjectileList, *Player)
    If NumActiveBombsPlayer < *Player\CurrentBombsLimit
      ;the player can put a bomb
      PutBombPlayer(*Player)
    EndIf
    
    
    
  EndIf
  
  
  UpdateGameObjectPlayer(*Player, TimeSlice)
  
  
  
  
EndProcedure

Procedure.a GetCollisionRectPlayer(*Player.TPlayer, *CollisionRect.TRect)
  *CollisionRect\Width = *Player\Width * 0.5
  *CollisionRect\Height = *Player\Height * 0.5
  
  *CollisionRect\Position\x = (*Player\Position\x + *Player\Width / 2) - *CollisionRect\Width / 2
  *CollisionRect\Position\y = (*Player\Position\y + *Player\Height / 2) - *CollisionRect\Height / 2
  
  ProcedureReturn #True
  
EndProcedure

Procedure DrawPlayer(*Player.TPlayer)
  DrawGameObject(*Player)
  Protected CollisionRect.TRect
  GetMapCollisionRectPlayer(*Player, @CollisionRect)
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(CollisionRect\Position\x, CollisionRect\Position\y, CollisionRect\Width, CollisionRect\Height, RGB(255, 0, 0))
  StopDrawing()
EndProcedure

Procedure InitPlayer(*Player.TPlayer, *MapCoords.TVector2D, ZoomFactor.f, *DrawList.TDrawList, *GameMap.TMap,
                     *ProjectileList.TProjectileList)
  ;the player has a reference to the game map
  *Player\GameMap = *GameMap
  *Player\PositionMapCoords\x = *MapCoords\x
  *Player\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*Player\PositionMapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*Player\PositionMapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  
  InitGameObject(*Player, @Position, #Player1, @UpdatePlayer(), @DrawPlayer(), #True, 16, 16, ZoomFactor,
                 #PlayerDrawOrder)
  
  ClipSprite(#Player1, 0, 0, 16, 16)
  
  *Player\MaxVelocity\x = 200
  *Player\MaxVelocity\y = 200
  
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