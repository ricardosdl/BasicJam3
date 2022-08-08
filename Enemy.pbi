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
  #EnemyStateLookingForPlayer
  #EnemyStateFollowingPlayer
EndEnumeration

Enumeration EEnemyType
  #EnemyRedDemon
  #EnemyRedArmoredDemon
EndEnumeration

Prototype SetPatrollingEnemyProc(*Enemy)
Prototype.a SpawnEnemyProc(*Data)
Prototype.a ChooseTileToDropBomb(*Enemy, *ReturnDropBombTileCoords, *ReturnSafetyTileCoords)

Structure TEnemyLookingDirection
  CurrentLookingDirection.a
  TimePerLookingDirection.f
  CurrentTimePerLookingDirection.f
EndStructure

Structure TEnemy Extends TGameObject
  *Player.TGameObject
  CurrentState.a
  StateTimer.f
  LastState.a
  EnemyType.a
  *GameMap.TMap
  *Projectiles.TProjectileList
  *DrawList.TDrawList
  List ObjectiveTileCoords.TVector2D()
  ObjectiveTileDirection.a
  ObjectiveSafetyTileCoords.TVector2D
  BombPower.f
  EnemyLookingDirection.TEnemyLookingDirection
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

Procedure SetPathObjectiveTile(*Enemy.TEnemy, *GoalTileCoords.TVector2D)
  ;clear the list of objectivetilecoords
  ClearList(*Enemy\ObjectiveTileCoords())
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  ;used to get the path of tiles
  Protected CurrentTileCoords.TVector2D = EnemyTileCoords
  
  Protected DeltaSign.TVector2D
  DeltaSign\x = Sign(*GoalTileCoords\x - EnemyTileCoords\x)
  DeltaSign\y = Sign(*GoalTileCoords\y - EnemyTileCoords\y)
  
  Repeat
    CurrentTileCoords\x + DeltaSign\x
    CurrentTileCoords\y + DeltaSign\y
    AddElement(*Enemy\ObjectiveTileCoords())
    *Enemy\ObjectiveTileCoords()\x = CurrentTileCoords\x
    *Enemy\ObjectiveTileCoords()\y = CurrentTileCoords\y
    
  Until CurrentTileCoords\x = *GoalTileCoords\x And CurrentTileCoords\y = *GoalTileCoords\y
  
  
  ;set the first element
  FirstElement(*Enemy\ObjectiveTileCoords())
EndProcedure

Procedure SwitchToGoingToObjectiveTile(*Enemy.TEnemy, *ObjectiveTileCoords.TVector2D)
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  SetPathObjectiveTile(*Enemy, *ObjectiveTileCoords)
  
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords()\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords()\y - EnemyTileCoords\y)
  
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
  SetPathObjectiveTile(*Enemy, @TileToDropBombCoords)
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords()\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords()\y - EnemyTileCoords\y)
  
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
  SetPathObjectiveTile(*Enemy, @*Enemy\ObjectiveSafetyTileCoords)
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords()\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords()\y - EnemyTileCoords\y)
  
  ;set the direction for the objective tile
  *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
  
  *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * 50
  *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * 50
  
  SwitchStateEnemy(*Enemy, #EnemyStateGoingToSafety)
EndProcedure

Procedure SwitchToLookingForPlayer(*Enemy.TEnemy)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  *Enemy\EnemyLookingDirection\CurrentLookingDirection = #MAP_DIRECTION_UP
  *Enemy\StateTimer = 4.0;one second for each direction
  *Enemy\EnemyLookingDirection\TimePerLookingDirection = *Enemy\StateTimer / #MAP_NUM_LOOKING_DIRECTIONS
  *Enemy\EnemyLookingDirection\CurrentTimePerLookingDirection = *Enemy\EnemyLookingDirection\TimePerLookingDirection
  
  SwitchStateEnemy(*Enemy, #EnemyStateLookingForPlayer)
  
  
EndProcedure

Procedure SwitchToFollowingPlayer(*Enemy.TEnemy, *PlayerCoords.TVector2D, *Velocity.TVector2D)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  SetPathObjectiveTile(*Enemy, *PlayerCoords)
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected DeltaSignX.f, DeltaSignY.f
  DeltaSignX = Sign(*Enemy\ObjectiveTileCoords()\x - EnemyTileCoords\x)
  DeltaSignY = Sign(*Enemy\ObjectiveTileCoords()\y - EnemyTileCoords\y)
  
  ;set the direction for the objective tile
  *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
  
  *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * *Velocity\x
  *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * *Velocity\y
  
  SwitchStateEnemy(*Enemy, #EnemyStateFollowingPlayer)
  
  
  
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
    Protected x.f = *Enemy\ObjectiveTileCoords()\x * #MAP_GRID_TILE_WIDTH
    Protected y.f = *Enemy\ObjectiveTileCoords()\y * #MAP_GRID_TILE_HEIGHT
    Box(x, y, 16, 16, RGB(255, 0, 0))
    StopDrawing()
  EndIf
  
EndProcedure

Procedure GoToObjectiveTileEnemy(*Enemy.TEnemy, TimeSlice)
  Protected ObjectiveTilePosition.TVector2D
  FirstElement(*Enemy\ObjectiveTileCoords())
  ObjectiveTilePosition\x = *Enemy\ObjectiveTileCoords()\x * #MAP_GRID_TILE_WIDTH
  ObjectiveTilePosition\y = *Enemy\ObjectiveTileCoords()\y * #MAP_GRID_TILE_HEIGHT
  
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
    DeleteElement(*Enemy\ObjectiveTileCoords())
    FirstElement(*Enemy\ObjectiveTileCoords())
    If ListSize(*Enemy\ObjectiveTileCoords()) = 0
      ;returning true means that we arrrived
      ProcedureReturn #True
    EndIf
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

Procedure LookForPlayerInDirection(*Enemy.TEnemy, Direction.a, *ReturnPlayerTileCoords.TVector2D)
  Protected CurrentDirection.TMapDirection = Map_All_Directions(Direction)
  
  Protected CurrentEnemyMapCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @CurrentEnemyMapCoords)
  
  Protected PlayerMapCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\Player\MiddlePosition, @PlayerMapCoords)
  
  Protected CurrentTileX.w = CurrentEnemyMapCoords\x + CurrentDirection\x
  Protected CurrentTileY.w = CurrentEnemyMapCoords\y + CurrentDirection\y
  
  While IsTileWalkable(*Enemy\GameMap, CurrentTileX, CurrentTileY)
    If PlayerMapCoords\x = CurrentTileX And PlayerMapCoords\y = CurrentTileY
      ;found the player
      *ReturnPlayerTileCoords\x = CurrentTileX : *ReturnPlayerTileCoords\y = CurrentTileY
      ProcedureReturn #True
    EndIf
    CurrentTileX + CurrentDirection\x
    CurrentTileY + CurrentDirection\y
  Wend
  
  
EndProcedure

Procedure LookForPlayerInAllDirections(*Enemy.TEnemy, *ReturnPlayerTileCoords.TVector2D)
  Protected CurrentEnemyMapCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @CurrentEnemyMapCoords)
  
  Protected PlayerMapCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\Player\MiddlePosition, @PlayerMapCoords)
  
  Protected CurrentDirection.a = #MAP_DIRECTION_UP
  For CurrentDirection = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
    Protected Direction.TMapDirection = Map_All_Directions(CurrentDirection)
    
    Protected CurrentTileX.w = CurrentEnemyMapCoords\x + Direction\x
    Protected CurrentTileY.w = CurrentEnemyMapCoords\y + Direction\y
    
    While IsTileWalkable(*Enemy\GameMap, CurrentTileX, CurrentTileY)
      If PlayerMapCoords\x = CurrentTileX And PlayerMapCoords\y = CurrentTileY
        ;found the player
        *ReturnPlayerTileCoords\x = CurrentTileX : *ReturnPlayerTileCoords\y = CurrentTileY
        ProcedureReturn #True
      EndIf
      CurrentTileX + Direction\x
      CurrentTileY + Direction\y
    Wend
  Next
  
  ProcedureReturn #False
  
EndProcedure


Procedure UpdateEnemyRedArmoredDemon(*RedArmoredDemon.TEnemy, TimeSlice.f)
  If *RedArmoredDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedArmoredDemon\MiddlePosition, @TileCoords)
    Protected WalkableRandomDirection.a = GetRandomWalkableDirectionFromOriginTile(*RedArmoredDemon\GameMap, TileCoords\x, TileCoords\y)
    If WalkableRandomDirection = #MAP_DIRECTION_NONE
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*RedArmoredDemon, 3.0)
      ProcedureReturn
    EndIf
    
    Protected ObjectiveRandomTileCoords.TVector2D
    GetRandomWalkableTileFromOriginTile(*RedArmoredDemon\GameMap, TileCoords\x, TileCoords\y, WalkableRandomDirection,
                                    @ObjectiveRandomTileCoords)
    
    SwitchToGoingToObjectiveTile(*RedArmoredDemon, @ObjectiveRandomTileCoords)
    
    ProcedureReturn
    
    
  EndIf
  
  Protected PlayerCoords.TVector2D
  
  If *RedArmoredDemon\CurrentState = #EnemyStateWaiting
    If *RedArmoredDemon\StateTimer <= 0
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
    *RedArmoredDemon\StateTimer - TimeSlice
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateGoingToObjectiveTile
    ;going to tile
    If GoToObjectiveTileEnemy(*RedArmoredDemon, TimeSlice)
      ;reached the objetive tile
      SwitchToLookingForPlayer(*RedArmoredDemon)
      
      
      ProcedureReturn
    EndIf
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateLookingForPlayer
    If *RedArmoredDemon\StateTimer <= 0
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    *RedArmoredDemon\StateTimer - TimeSlice
    
    If *RedArmoredDemon\EnemyLookingDirection\CurrentTimePerLookingDirection <= 0
      If *RedArmoredDemon\EnemyLookingDirection\CurrentLookingDirection = #MAP_DIRECTION_LEFT
        ;we looked at the last direction
      Else
        ;the directions go from #MAP_DIRECTION_UP to #MAP_DIRECTION_LEFT
        *RedArmoredDemon\EnemyLookingDirection\CurrentLookingDirection + 1
        *RedArmoredDemon\EnemyLookingDirection\CurrentTimePerLookingDirection = *RedArmoredDemon\EnemyLookingDirection\TimePerLookingDirection
      EndIf
    EndIf
    *RedArmoredDemon\EnemyLookingDirection\CurrentTimePerLookingDirection - TimeSlice
    
    If LookForPlayerInDirection(*RedArmoredDemon, *RedArmoredDemon\EnemyLookingDirection\CurrentLookingDirection, @PlayerCoords)
      ;found the player in this direction
      Protected FollowingVelocity.TVector2D\x = 150
      FollowingVelocity\y = 150
      SwitchToFollowingPlayer(*RedArmoredDemon, @PlayerCoords, @FollowingVelocity)
      ProcedureReturn
    EndIf
    
  ElseIf  *RedArmoredDemon\CurrentState = #EnemyStateFollowingPlayer
    If LookForPlayerInAllDirections(*RedArmoredDemon, @PlayerCoords)
      
    EndIf
    
    
    
  EndIf
  
  UpdateGameObject(*RedArmoredDemon, TimeSlice)
  
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
  
  ClipSprite(#EnemyRedArmoredDemonSprite, 0, 0, 16, 16)
  
EndProcedure



DisableExplicit