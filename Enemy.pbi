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
  #EnemyStateDropingBomb
  #EnemyStateGoingToSafety
EndEnumeration

Enumeration EEnemyType
  #EnemyRedDemon
  #EnemyRedArmoredDemon
EndEnumeration

Prototype SetPatrollingEnemyProc(*Enemy)
Prototype.a SpawnEnemyProc(*Data)
Prototype.a ChooseTileToDropBomb(*Enemy, *ReturnDropBombTileCoords, *ReturnSafetyTileCoords)

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
  ObjectiveTileDirection.a
  ObjectiveSafetyTileCoords.TVector2D
  BombPower.f
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
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  ;set the coords for the objective tile
  *Enemy\ObjectiveTileCoords\x = *ObjectiveTileCoords\x
  *Enemy\ObjectiveTileCoords\y = *ObjectiveTileCoords\y
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords\y - EnemyTileCoords\y)
  
  ;set the direction for the objective tile
  *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
  
  *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * 50
  *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * 50
  
  SwitchStateEnemy(*Enemy, #EnemyStateGoingToObjectiveTile)
  
EndProcedure

Procedure.a ChooseRandomTileToDropBombEnemy(*Enemy.TEnemy, *ReturnDropBombTileCoords.TVector2D, *SafetyTileCoords.TVector2D)
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @EnemyTileCoords)
  Protected WalkableRandomDirection.a = GetRandomWalkableDirectionFromOriginTile(*Enemy\GameMap, EnemyTileCoords\x, EnemyTileCoords\y)
  If WalkableRandomDirection = #MAP_DIRECTION_NONE
    ;no free random direction, so we can't choose a tile tp drop a bomb
    ProcedureReturn #False
  EndIf
  
  Protected ObjectiveRandomTileCoords.TVector2D
  GetRandomWalkableTileFromOriginTile(*Enemy\GameMap, EnemyTileCoords\x, EnemyTileCoords\y, WalkableRandomDirection,
                                      @ObjectiveRandomTileCoords)
  
  ;can we drop the bomb and go to safety?
  ;WalkableRandomDirection is the direction we'll head to
  ;let's just check on the opposite direction, one more tile thatn the bomb power
  Protected OppositeDirection.TMapDirection
  OppositeDirection\x = Map_All_Directions(WalkableRandomDirection)\x * -1
  OppositeDirection\y = Map_All_Directions(WalkableRandomDirection)\y * -1
  
  If IsTileWalkable(*Enemy\GameMap, ObjectiveRandomTileCoords\x + (OppositeDirection\x * *Enemy\BombPower) + (OppositeDirection\x),
                    ObjectiveRandomTileCoords\y + (OppositeDirection\y * *Enemy\BombPower) + (OppositeDirection\y))
    ;great we can go to safety
    *SafetyTileCoords\x = ObjectiveRandomTileCoords\x + (OppositeDirection\x * *Enemy\BombPower) + (OppositeDirection\x)
    *SafetyTileCoords\y = ObjectiveRandomTileCoords\y + (OppositeDirection\y * *Enemy\BombPower) + (OppositeDirection\y)
    
    *ReturnDropBombTileCoords\x = ObjectiveRandomTileCoords\x
    *ReturnDropBombTileCoords\y = ObjectiveRandomTileCoords\y
    
    ProcedureReturn #True
    
  EndIf
  
  ;we can't find a safety tile after dropping the bomb
  ProcedureReturn #False
  
EndProcedure

Procedure.a SwitchToDropingBomb(*Enemy.TEnemy, *GetTileToDropBomb.ChooseTileToDropBomb = #Null)
  If *GetTileToDropBomb = #Null
    *GetTileToDropBomb = @ChooseRandomTileToDropBombEnemy()
  EndIf
  
  Protected TileToDropBombCoords.TVector2D, SafetyTileCoords.TVector2D
  If Not *GetTileToDropBomb(*Enemy, @TileToDropBombCoords, @SafetyTileCoords)
    ;couldn't find a tile do drop a bomb
    ProcedureReturn #False
  EndIf
  
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  ;set the coords for the objective tile
  *Enemy\ObjectiveTileCoords\x = TileToDropBombCoords\x
  *Enemy\ObjectiveTileCoords\y = TileToDropBombCoords\y
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords\y - EnemyTileCoords\y)
  
  ;set the direction for the objective tile
  *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
  
  *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * 50
  *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * 50
  
  *Enemy\ObjectiveSafetyTileCoords = SafetyTileCoords
  
  SwitchStateEnemy(*Enemy, #EnemyStateDropingBomb)
  
  ProcedureReturn #True
  
  
EndProcedure

Procedure SwitchToGoingToSafety(*Enemy.TEnemy)
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  ;set the coords for the objective tile
  *Enemy\ObjectiveTileCoords\x = *Enemy\ObjectiveSafetyTileCoords\x
  *Enemy\ObjectiveTileCoords\y = *Enemy\ObjectiveSafetyTileCoords\y
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords\y - EnemyTileCoords\y)
  
  ;set the direction for the objective tile
  *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
  
  *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * 50
  *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * 50
  
  SwitchStateEnemy(*Enemy, #EnemyStateGoingToSafety)
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
  If *Enemy\CurrentState = #EnemyStateGoingToObjectiveTile
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Outlined)
    Protected x.f = *Enemy\ObjectiveTileCoords\x * #MAP_GRID_TILE_WIDTH
    Protected y.f = *Enemy\ObjectiveTileCoords\y * #MAP_GRID_TILE_HEIGHT
    Box(x, y, 16, 16, RGB(255, 0, 0))
    StopDrawing()
  EndIf
  
EndProcedure

Procedure GoToObjectiveTileEnemy(*Enemy.TEnemy, TimeSlice)
  Protected ObjectiveTilePosition.TVector2D
  ObjectiveTilePosition\x = *Enemy\ObjectiveTileCoords\x * #MAP_GRID_TILE_WIDTH
  ObjectiveTilePosition\y = *Enemy\ObjectiveTileCoords\y * #MAP_GRID_TILE_HEIGHT
  
  Protected ObjectiveTileMiddlePosition.TVector2D
  ObjectiveTileMiddlePosition\x = ObjectiveTilePosition\x + #MAP_GRID_TILE_WIDTH / 2
  ObjectiveTileMiddlePosition\y = ObjectiveTilePosition\y + #MAP_GRID_TILE_HEIGHT / 2
  
  Protected EnemyPositonCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyPositonCoords)
  
  Protected DeltaSign.TVector2D
  DeltaSign\x = Sign(ObjectiveTilePosition\x - *Enemy\Position\x)
  DeltaSign\y = Sign(ObjectiveTilePosition\y - *Enemy\Position\y)
  
  Protected CurrentDirecton.a = GetMapDirectionByDeltaSign(DeltaSign\x, DeltaSign\y)
  If CurrentDirecton <> *Enemy\ObjectiveTileDirection
    ;the direction changed so we passed the objective tile
    ;we must position the enemy on the objective tile and signal the we arrived
    *Enemy\Position\x = (ObjectiveTileMiddlePosition\x) - *Enemy\Width / 2
    *Enemy\Position\y = (ObjectiveTileMiddlePosition\y) - *Enemy\Height / 2
    ;returning true means that we arrrived
    ProcedureReturn #True
  EndIf
  
  ;returning false means that we didn't arrive yet
  ProcedureReturn #False
EndProcedure

Procedure.a DropBombEnemy(*Enemy.TEnemy)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Enemy\Projectiles)
  If *Projectile = #Null
    ;couldn't allocate the memory for a bomb :(
    ProcedureReturn #False
  EndIf
  
  Protected BombTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @BombTileCoords)
  
  InitProjectile(*Projectile, @BombTileCoords, #True, #SPRITES_ZOOM, #ProjectileBomb1, *Enemy\GameMap,
                 *Enemy\DrawList, *Enemy\BombPower, *Enemy)
  
  AddDrawItemDrawList(*Enemy\DrawList, *Projectile)
  
  ProcedureReturn #True
EndProcedure

Procedure UpdateEnemyRedDemon(*RedDemon.TEnemy, TimeSlice.f)
  If *RedDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedDemon\MiddlePosition, @TileCoords)
    Protected WalkableRandomDirection.a = GetRandomWalkableDirectionFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y)
    If WalkableRandomDirection = #MAP_DIRECTION_NONE
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*RedDemon, 3.0)
      ProcedureReturn
    EndIf
    
    Protected ObjectiveRandomTileCoords.TVector2D
    GetRandomWalkableTileFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y, WalkableRandomDirection,
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
    If GoToObjectiveTileEnemy(*RedDemon, TimeSlice)
      ;reached the objetive tile
      If RandomFloat() <= 0.5
        Debug "try to drop bomb"
        If Not SwitchToDropingBomb(*RedDemon)
          ;could not drop bomb let's just wait
          SwitchToWaitingEnemy(*RedDemon, 3.0)
        EndIf
        ProcedureReturn
      Else
        SwitchToWaitingEnemy(*RedDemon, 3.0)
      EndIf
      
      
      ProcedureReturn
    EndIf
  ElseIf *RedDemon\CurrentState = #EnemyStateDropingBomb
    If GoToObjectiveTileEnemy(*RedDemon, TimeSlice)
      ;reached the objective tile, time to drop the bomb
      DropBombEnemy(*RedDemon)
      SwitchToGoingToSafety(*RedDemon)
    EndIf
    
  ElseIf *RedDemon\CurrentState = #EnemyStateGoingToSafety
    If GoToObjectiveTileEnemy(*RedDemon, TimeSlice)
      ;reached the safety tile
      Debug "safety"
      SwitchToWaitingEnemy(*RedDemon, 3.0)
    EndIf
    
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
  
  *Enemy\BombPower = 1.0
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedDemonSprite, 0, 0, 16, 16)
  
  
  
EndProcedure

Procedure UpdateEnemyRedArmoredDemon(*RedArmoredDemon.TEnemy, TimeSlice.f)
  If *RedArmoredDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedArmoredDemon\MiddlePosition, @TileCoords)
    
    
    
  EndIf
EndProcedure

Procedure InitEnemyRedArmoredDemon(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                                   *DrawList.TDrawList, *GameMap.TMap, *PosMapCoords.TVector2D)
  
  ;store the middle x and y of the grid at *PosMapCoords
  Protected GridTileMiddlePosition.TVector2D\x = *PosMapCoords\x * #MAP_GRID_TILE_WIDTH + #MAP_GRID_TILE_WIDTH / 2
  GridTileMiddlePosition\y = *PosMapCoords\y * #MAP_GRID_TILE_HEIGHT + #MAP_GRID_TILE_HEIGHT / 2
  
  Protected EnemyWidth.u, EnemyHeight.u
  EnemyWidth = 16 * #SPRITES_ZOOM
  EnemyHeight = 16 * #SPRITES_ZOOM
  
  Protected Position.TVector2D\x = GridTileMiddlePosition\x - EnemyWidth / 2
  Position\y = GridTileMiddlePosition\y - EnemyHeight / 2
  
  InitGameObject(*Enemy, @Position, #EnemyRedArmoredDemonSprite, @UpdateEnemyRedArmoredDemon(), @DrawEnemy(), #True, 16, 16,
                 #SPRITES_ZOOM, #EnemyDrawOrder)
  
  InitEnemy(*Enemy, *Player, *ProjectileList, *DrawList, #EnemyRedArmoredDemon, *GameMap)
  
  *Enemy\BombPower = 2.0
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedDemonSprite, 0, 0, 16, 16)
  
EndProcedure



DisableExplicit