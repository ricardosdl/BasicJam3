XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "Projectile.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "Map.pbi"

EnableExplicit

Enumeration EEnemyStates
  #EnemyStateNoState
  #EnemyStateGoingToObjectiveTile
  #EnemyStateWaiting
EndEnumeration

Enumeration EEnemyType
  #EnemyRedDemon
EndEnumeration

Prototype SetPatrollingEnemyProc(*Enemy)
Prototype.a SpawnEnemyProc(*Data)

Structure TEnemy Extends TGameObject
  *Player.TGameObject
  CurrentState.a
  StateTimer.f
  LastState.a
  EnemyType.a
  *GameMap.TMap
  *Projectiles.TProjectileList
  *DrawList.TDrawList
  ObjectiveTileCoords.TVector2D
EndStructure

Procedure InitEnemy(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                    *DrawList.TDrawList, EnemyType.a, *GameMap.TMap)
  *Enemy\Player = *Player
  *Enemy\Projectiles = *ProjectileList
  
  *Enemy\DrawList = *DrawList
  *Enemy\EnemyType = EnemyType
  *Enemy\GameMap = *GameMap
EndProcedure

Procedure SwitchStateEnemy(*Enemy.TEnemy, NewState.a)
  *Enemy\LastState = *Enemy\CurrentState
  *Enemy\CurrentState = NewState
EndProcedure

Procedure SwitchToWaitingEnemy(*Enemy.TEnemy, WaitTimer.f = 1.5)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  *Enemy\StateTimer = WaitTimer
  SwitchStateEnemy(*Enemy, #EnemyStateWaiting)
EndProcedure

Procedure SwitchToGoingToObjectiveTile(*Enemy.TEnemy, *ObjectiveTileCoords.TVector2D)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  *Enemy\ObjectiveTileCoords\x = *ObjectiveTileCoords\x
  *Enemy\ObjectiveTileCoords\y = *ObjectiveTileCoords\y
  SwitchStateEnemy(*Enemy, #EnemyStateGoingToObjectiveTile)
  
EndProcedure

Procedure KillEnemy(*Enemy.TEnemy)
  *Enemy\Active = #False
EndProcedure


Procedure HurtEnemy(*Enemy.TEnemy, Power.f)
  *Enemy\Health - Power
  If *Enemy\Health <= 0.0
    KillEnemy(*Enemy)
  EndIf
  
EndProcedure

Procedure DrawEnemy(*Enemy.TEnemy)
  DrawGameObject(*Enemy)
EndProcedure

Procedure UpdateEnemyRedDemon(*RedDemon.TEnemy, TimeSlice.f)
  If *RedDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedDemon\MiddlePosition, @TileCoords)
    Protected FreeRandomDirection.a = GetRandomFreeDirectionFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y)
    If FreeRandomDirection = #MAP_DIRECTION_NONE
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*RedDemon, 3.0)
      Debug "no free direction"
      ProcedureReturn
    EndIf
    
    Debug "free random direction:" + FreeRandomDirection
    
    Protected ObjectiveRandomTileCoords.TVector2D
    GetRandomFreeTileFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y, FreeRandomDirection,
                                    @ObjectiveRandomTileCoords)
    
    SwitchToGoingToObjectiveTile(*RedDemon, @ObjectiveRandomTileCoords)
    
    ProcedureReturn
  EndIf
  
  If *RedDemon\CurrentState = #EnemyStateWaiting
    If *RedDemon\StateTimer <= 0
      SwitchStateEnemy(*RedDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
    *RedDemon\StateTimer - TimeSlice
    
  ElseIf *RedDemon\CurrentState = #EnemyStateGoingToObjectiveTile
    ;going to tile
    Debug "going to tile"
  EndIf
  
  
  
  UpdateGameObject(*RedDemon, TimeSlice)
  
  
  
EndProcedure

Procedure InitEnemyRedDemon(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                            *DrawList.TDrawList, *GameMap.TMap, *PosMapCoords.TVector2D)
  
  ;store the middle x and y of the grid at *PosMapCoords
  Protected GridTileMiddlePosition.TVector2D\x = *PosMapCoords\x * #MAP_GRID_TILE_WIDTH + #MAP_GRID_TILE_WIDTH / 2
  GridTileMiddlePosition\y = *PosMapCoords\y * #MAP_GRID_TILE_HEIGHT + #MAP_GRID_TILE_HEIGHT / 2
  
  Protected EnemyWidth.u, EnemyHeight.u
  EnemyWidth = 16 * #SPRITES_ZOOM
  EnemyHeight = 16 * #SPRITES_ZOOM
  
  Protected Position.TVector2D\x = GridTileMiddlePosition\x - EnemyWidth / 2
  Position\y = GridTileMiddlePosition\y - EnemyHeight / 2
  
  InitGameObject(*Enemy, @Position, #EnemyRedDemonSprite, @UpdateEnemyRedDemon(), @DrawEnemy(), #True, 16, 16,
                 #SPRITES_ZOOM, #EnemyDrawOrder)
  
  InitEnemy(*Enemy, *Player, *ProjectileList, *DrawList, #EnemyRedDemon, *GameMap)
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedDemonSprite, 0, 0, 16, 16)
  
  
  
EndProcedure


DisableExplicit