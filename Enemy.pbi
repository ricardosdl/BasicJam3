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
  #EnemyStateSummoning
EndEnumeration

Enumeration EEnemyType
  #EnemyRedDemon
  #EnemyRedArmoredDemon
  #EnemyMagnetoBomb
  #EnemySummoner
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
  List ObjectiveTileCoords.TVector2D()
  ObjectiveTileDirection.a
  ObjectiveSafetyTileCoords.TVector2D
  BombPower.f
  LookingDirection.TMapDirection
  HurtTimer.f
  AliveTimer.f
  HasAliveTimer.a
  SummonTile.TVector2D
  *SpawnEnemy.SpawnEnemyProc
EndStructure

Procedure GetCollisionCoordsEnemy(*Enemy.TEnemy, *CollisionCoords.TRect)
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @*CollisionCoords\Position)
  ProcedureReturn #True
EndProcedure

Procedure InitEnemy(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                    *DrawList.TDrawList, EnemyType.a, *GameMap.TMap, HurtTimer.f = 0.0)
  *Enemy\Player = *Player
  *Enemy\Projectiles = *ProjectileList
  
  *Enemy\DrawList = *DrawList
  *Enemy\EnemyType = EnemyType
  *Enemy\GameMap = *GameMap
  *Enemy\GetCollisionRect = @GetCollisionCoordsEnemy()
  *Enemy\HurtTimer = HurtTimer
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

Procedure.a SetPathObjectiveTile(*Enemy.TEnemy, *GoalTileCoords.TVector2D, *FirstObjectiveTile.TVector2D = #Null)
  ;clear the list of objectivetilecoords
  ClearList(*Enemy\ObjectiveTileCoords())
  
  If *FirstObjectiveTile <> #Null
    AddElement(*Enemy\ObjectiveTileCoords())
    *Enemy\ObjectiveTileCoords()\x = *FirstObjectiveTile\x
    *Enemy\ObjectiveTileCoords()\y = *FirstObjectiveTile\y
  EndIf
  
    
  
  ;get the current enemy middle position coords 
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyTileCoords)
  Protected IsPossibleToReachGoal.a = AStar2(*Enemy\GameMap, EnemyTileCoords\x, EnemyTileCoords\y, *GoalTileCoords\x, *GoalTileCoords\y, *Enemy\ObjectiveTileCoords())
  If Not IsPossibleToReachGoal
    Debug "this shouldn't be possible"
    ProcedureReturn #False
  EndIf
  
  ;delete the first element because is is the current tile coords for the enemy
  FirstElement(*Enemy\ObjectiveTileCoords())
  DeleteElement(*Enemy\ObjectiveTileCoords())
  
  ;set the first element
  FirstElement(*Enemy\ObjectiveTileCoords())
  ProcedureReturn #True
EndProcedure

Procedure SwitchToGoingToObjectiveTile(*Enemy.TEnemy, *ObjectiveTileCoords.TVector2D)
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  If Not SetPathObjectiveTile(*Enemy, *ObjectiveTileCoords)
    ProcedureReturn #False
  EndIf
  
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
  ProcedureReturn #True
  
EndProcedure

Procedure.a ChooseRandomTileToDropBombEnemy(*Enemy.TEnemy, *ReturnDropBombTileCoords.TVector2D, *SafetyTileCoords.TVector2D)
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @EnemyTileCoords)
  Protected WalkableRandomDirection.a = GetRandomWalkableDirectionFromOriginTile(*Enemy\GameMap, EnemyTileCoords\x, EnemyTileCoords\y)
  If WalkableRandomDirection = #MAP_DIRECTION_NONE
    ;no free random direction, so we can't choose a tile tp drop a bomb
    ProcedureReturn #False
  EndIf
  
  Protected BombTileCoords.TVector2D
  GetRandomWalkableTileFromOriginTile(*Enemy\GameMap, EnemyTileCoords\x, EnemyTileCoords\y, WalkableRandomDirection,
                                      @BombTileCoords)
  
  ;can we drop the bomb and go to safety?
  NewList PossibleSafetyTiles.TVector2D()
  
  GetListWalkableTilesAroundOriginTile(*Enemy\GameMap, @BombTileCoords, *Enemy\BombPower, PossibleSafetyTiles())
  
  RandomizeList(PossibleSafetyTiles())
  Protected FoundSafetyTile.a = #False
  ForEach PossibleSafetyTiles()
    NewList PathToSafetyTile.TVector2D()
    If AStar2(*Enemy\GameMap, BombTileCoords\x, BombTileCoords\y, PossibleSafetyTiles()\x, PossibleSafetyTiles()\y, PathToSafetyTile())
      ;it is possible to go to this safety tile
      FoundSafetyTile = #True
      Break
    EndIf
  Next
  
  If FoundSafetyTile
    *SafetyTileCoords\x = PossibleSafetyTiles()\x
    *SafetyTileCoords\y = PossibleSafetyTiles()\y
    
    *ReturnDropBombTileCoords\x = BombTileCoords\x
    *ReturnDropBombTileCoords\y = BombTileCoords\y
    
    ProcedureReturn #True
  EndIf
  
  ;can't drop bomb and find safety tile
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
  If Not SetPathObjectiveTile(*Enemy, @TileToDropBombCoords)
    ProcedureReturn #False
  EndIf
  
  
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

Procedure SetDirectionAndVelEnemy(*Enemy.TEnemy, *Velocity.TVector2D)
  If ListSize(*Enemy\ObjectiveTileCoords()) < 1
    ProcedureReturn
  EndIf
  
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
EndProcedure

Procedure.a SwitchToGoingToSafety(*Enemy.TEnemy)
  ;stop movement for now
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  ;set the coords for the objective tile
  If Not SetPathObjectiveTile(*Enemy, @*Enemy\ObjectiveSafetyTileCoords)
    ProcedureReturn #False
  EndIf
  
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
  ProcedureReturn #True
EndProcedure

Procedure SwitchToFollowingPlayer(*Enemy.TEnemy, *PlayerCoords.TVector2D, *Velocity.TVector2D, *FirstObjectiveTile.TVector2D = #Null)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  If Not SetPathObjectiveTile(*Enemy, *PlayerCoords, *FirstObjectiveTile)
    ProcedureReturn #False
  EndIf
  
  
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
  
  ProcedureReturn #True
  
EndProcedure

Procedure.a DropBombEnemy(*Enemy.TEnemy, BombAlpha.a = 255, *ReturnProjectile.TPointer = #Null)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Enemy\Projectiles)
  If *Projectile = #Null
    ;couldn't allocate the memory for a bomb :(
    ProcedureReturn #False
  EndIf
  
  Protected BombTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @BombTileCoords)
  
  InitProjectileBomb1(*Projectile, @BombTileCoords, *Enemy\GameMap, *Enemy\DrawList, *Enemy\BombPower, *Enemy, *Enemy\Projectiles)
  
  AddDrawItemDrawList(*Enemy\DrawList, *Projectile)
  If *ReturnProjectile <> #Null
    *ReturnProjectile\Address = *Projectile
  EndIf
  
  
  ProcedureReturn #True
EndProcedure

Procedure KillEnemy(*Enemy.TEnemy)
  If *Enemy\EnemyType = #EnemyMagnetoBomb
    Protected ProjectilePointer.TPointer
    DropBombEnemy(*Enemy, 0, @ProjectilePointer)
    Protected *Projectile.TProjectile = ProjectilePointer\Address
    *Projectile\AliveTimer = 0.0;explode imediately
  EndIf
  ClearList(*Enemy\ObjectiveTileCoords())
  *Enemy\Active = #False
  
  
EndProcedure


Procedure.a HurtEnemy(*Enemy.TEnemy, Power.f)
  If *Enemy\HurtTimer > 0
    ProcedureReturn #False
  EndIf
  
  *Enemy\Health - Power
  If *Enemy\Health <= 0.0
    KillEnemy(*Enemy)
  EndIf
  
EndProcedure

Procedure ExplodeEnemy(*Enemy.TEnemy)
  KillEnemy(*Enemy)
EndProcedure

Procedure DrawEnemy(*Enemy.TEnemy)
  Protected Intensity.a = 255
  If *Enemy\HurtTimer > 0
    Protected HurtTimer.w = *Enemy\HurtTimer * 1000
    Intensity = Bool((HurtTimer / 125) % 2) * Intensity
  EndIf
  DrawGameObject(*Enemy, Intensity)
  
;   If *Enemy\CurrentState = #EnemyStateGoingToObjectiveTile
;     StartDrawing(ScreenOutput())
;     DrawingMode(#PB_2DDrawing_Outlined)
;     Protected x.f = *Enemy\ObjectiveTileCoords()\x * #MAP_GRID_TILE_WIDTH
;     Protected y.f = *Enemy\ObjectiveTileCoords()\y * #MAP_GRID_TILE_HEIGHT
;     Box(x, y, 16, 16, RGB(255, 0, 0))
;     StopDrawing()
;   EndIf
  
EndProcedure

Procedure GoToObjectiveTileEnemy(*Enemy.TEnemy, *ReturnReachedCurrentObjectiveTile.Ascii = #Null)
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
  
  Protected CurrentDirecton.a = GetMapDirectionByDeltaSign(DeltaSign\x, DeltaSign\y, @*Enemy\LookingDirection)
  If CurrentDirecton <> *Enemy\ObjectiveTileDirection
    ;the direction changed so we passed the objective tile
    ;we must position the enemy on the objective tile and signal the we arrived
    *Enemy\Position\x = (ObjectiveTileMiddlePosition\x) - *Enemy\Width / 2
    *Enemy\Position\y = (ObjectiveTileMiddlePosition\y) - *Enemy\Height / 2
    
    ;since the enemy is now on the current tile we can signal it
    If *ReturnReachedCurrentObjectiveTile <> #Null
      *ReturnReachedCurrentObjectiveTile\a = #True
    EndIf
    
    
    DeleteElement(*Enemy\ObjectiveTileCoords())
    FirstElement(*Enemy\ObjectiveTileCoords())
    If ListSize(*Enemy\ObjectiveTileCoords()) = 0
      ;returning true means that we arrrived
      ProcedureReturn #True
    EndIf
    
    Protected Velocity.TVector2D\x = 50
    Velocity\y = 50
    SetDirectionAndVelEnemy(*Enemy, @Velocity)
    
  EndIf
  
  ;returning false means that we didn't arrive yet
  ProcedureReturn #False
EndProcedure

Procedure IsThereBombsOnDirection(*Enemy.TEnemy, Direction.a, LookForAllProjectiles.a,
                                  MaxTileDistance.a = 5)
  Protected EnemyCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @EnemyCoords)
  
  Protected MapDirection.TMapDirection = Map_All_Directions(Direction)
  Protected TileDistance.a = 1
  While TileDistance <= MaxTileDistance
    Protected CurrentTileCoords.TVector2D
    CurrentTileCoords\x = EnemyCoords\x + TileDistance * MapDirection\x
    CurrentTileCoords\y = EnemyCoords\y + TileDistance * MapDirection\y
    
    If Not IsTileWalkable(*Enemy\GameMap, CurrentTileCoords\x, CurrentTileCoords\y)
      ;it's not walakble so no bombs here, and we do not continue looking
      ProcedureReturn #False
    EndIf
    
    Protected FoundSomething.a = #False
    If LookForAllProjectiles
      FoundSomething = IsThereActiveProjectileOnTile(*Enemy\Projectiles, @CurrentTileCoords)
    Else
      FoundSomething = IsThereActiveBombOnTile(*Enemy\Projectiles, @CurrentTileCoords)
    EndIf
    
    If FoundSomething
      ProcedureReturn #True
    EndIf
    
    TileDistance + 1
  Wend
  
  ProcedureReturn #False
  
EndProcedure

Procedure UpdateEnemyRedDemon(*RedDemon.TEnemy, TimeSlice.f)
  If *RedDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedDemon\MiddlePosition, @TileCoords)
    
    NewList WalkableDirections.a()
    
    Protected FoundWalkableDirections.a = GetWalkableDirectionsFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y, WalkableDirections())
    If Not FoundWalkableDirections
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*RedDemon, 3.0)
      ProcedureReturn
    EndIf
    
    RandomizeList(WalkableDirections())
    Protected FoundBombFreeWalkableDirection.a = #False
    Protected BombFreeWalkableDirection.a
    ForEach WalkableDirections()
      If Not IsThereBombsOnDirection(*RedDemon, WalkableDirections(), #False, 4)
        FoundBombFreeWalkableDirection = #True
        BombFreeWalkableDirection = WalkableDirections()
        Break
      EndIf
    Next
    
    If FoundBombFreeWalkableDirection
      Protected ObjectiveTileCoords.TVector2D
      GetRandomWalkableTileFromOriginTile(*RedDemon\GameMap, TileCoords\x, TileCoords\y, BombFreeWalkableDirection,
                                          @ObjectiveTileCoords, 4)
      If SwitchToGoingToObjectiveTile(*RedDemon, @ObjectiveTileCoords)
        ;were able to find a path to the objective tile
        ProcedureReturn
      EndIf
      ;couldn't find a path, let's just wait
      SwitchToWaitingEnemy(*RedDemon, 3.0)
      ProcedureReturn
    EndIf
    
    ;there is bombs on all directions, just wait then
    SwitchToWaitingEnemy(*RedDemon, 3.0)
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
    If GoToObjectiveTileEnemy(*RedDemon)
      ;reached the objetive tile
      If RandomFloat() <= 0.5
        ;Debug "try to drop bomb"
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
    If GoToObjectiveTileEnemy(*RedDemon)
      ;reached the objective tile, time to drop the bomb
      DropBombEnemy(*RedDemon)
      If SwitchToGoingToSafety(*RedDemon)
        ProcedureReturn
      EndIf
      
      SwitchStateEnemy(*RedDemon, #EnemyStateNoState)
      
    EndIf
    
  ElseIf *RedDemon\CurrentState = #EnemyStateGoingToSafety
    If GoToObjectiveTileEnemy(*RedDemon)
      ;reached the safety tile
      ;Debug "safety"
      Protected WaitingTimer.f = #BOMB1_TIMER + *RedDemon\BombPower * #EXPLOSION_EXPANSION_TIMER + 0.1
      SwitchToWaitingEnemy(*RedDemon, WaitingTimer)
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
  
  *Enemy\HurtTimer = 0.0
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedDemonSprite, 0, 0, 16, 16)
  
  
  
EndProcedure

Procedure LookForPlayerInDirection(*Enemy.TEnemy, Direction.a, *ReturnPlayerTileCoords.TVector2D)
  If Direction = #MAP_DIRECTION_NONE
    ;no direction to look
    ProcedureReturn #False
  EndIf
  
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

Procedure CloseEnoughToPlayerInAnyDirection(*Enemy.TEnemy, *ReturnPlayerDirection.TMapDirection, CloseEnoughDistance.u = 2)
  Protected CurrentEnemyCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @CurrentEnemyCoords)
  
  Protected PlayerCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\Player\MiddlePosition, @PlayerCoords)
  
  Protected Direction.a, Distance.u
  For Direction = #MAP_DIRECTION_UP To #MAP_DIRECTION_LEFT
    Distance = CloseEnoughDistance
    Protected CurrentDirection.TMapDirection = Map_All_Directions(Direction)
    Protected CurrentLookingTile.TVector2D
    CurrentLookingTile\x = CurrentEnemyCoords\x
    CurrentLookingTile\y = CurrentEnemyCoords\y
    While Distance
      CurrentLookingTile\x + CurrentDirection\x
      CurrentLookingTile\y + CurrentDirection\y
      If IsTileWalkable(*Enemy\GameMap, CurrentLookingTile\x, CurrentLookingTile\y)
        If PlayerCoords\x = CurrentLookingTile\x And PlayerCoords\y = CurrentLookingTile\y
          ;CallDebugger
          *ReturnPlayerDirection\x = Map_All_Directions(Direction)\x
          *ReturnPlayerDirection\y = Map_All_Directions(Direction)\y
          ProcedureReturn #True
        EndIf
        
      Else
        Break
      EndIf
      
      Distance - 1
    Wend
    
  Next
  
  ProcedureReturn #False
  
EndProcedure

Procedure GetTileToDropBombPlayer(*Enemy.TEnemy, *ReturnDropBombTileCoords.TVector2D, *ReturnSafetyTileCoords.TVector2D)
  Protected EnemyTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @EnemyTileCoords)
  
  Protected PlayerTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\Player\MiddlePosition, @PlayerTileCoords)
  
  NewList WalkableTilesAroundPlayer.TVector2D()
  GetListWalkableTilesAroundOriginTile(*Enemy\GameMap, @PlayerTileCoords, *Enemy\BombPower, WalkableTilesAroundPlayer())
  RandomizeList(WalkableTilesAroundPlayer())
  Protected FoundSafetyTile.a = #False
  NewList PathList.TVector2D()
  ForEach WalkableTilesAroundPlayer()
    
    If AStar2(*Enemy\GameMap, PlayerTileCoords\x, PlayerTileCoords\y, WalkableTilesAroundPlayer()\x,
              WalkableTilesAroundPlayer()\y, PathList())
      ;found a safety tile
      FoundSafetyTile = #True
      Break
    EndIf
    
  Next
  
  If FoundSafetyTile
    *ReturnDropBombTileCoords\x = PlayerTileCoords\x
    *ReturnDropBombTileCoords\y = PlayerTileCoords\y
    
    *ReturnSafetyTileCoords\x = WalkableTilesAroundPlayer()\x
    *ReturnSafetyTileCoords\y = WalkableTilesAroundPlayer()\y
    ProcedureReturn #True
  EndIf
  
  ;can't drop bomb and find safety tile
  ProcedureReturn #False
EndProcedure

Procedure UpdateEnemyRedArmoredDemon(*RedArmoredDemon.TEnemy, TimeSlice.f)
  If *RedArmoredDemon\CurrentState = #EnemyStateNoState
    Protected TileCoords.TVector2D
    GetTileCoordsByPosition(*RedArmoredDemon\MiddlePosition, @TileCoords)
    
    NewList WalkableDirections.a()
    Protected ThereIsWalkableDirections.a = GetWalkableDirectionsFromOriginTile(*RedArmoredDemon\GameMap, TileCoords\x,
                                                                                TileCoords\y, WalkableDirections())
    
    If Not ThereIsWalkableDirections
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*RedArmoredDemon, 3.0)
      ProcedureReturn
    EndIf
    
    RandomizeList(WalkableDirections())
    Protected FoundBombFreeWalkableDirection.a = #False
    Protected BombFreeWalkableDirection.a
    ForEach WalkableDirections()
      If Not IsThereBombsOnDirection(*RedArmoredDemon, WalkableDirections(), #True)
        FoundBombFreeWalkableDirection = #True
        BombFreeWalkableDirection = WalkableDirections()
        Break
      EndIf
    Next
    
    If FoundBombFreeWalkableDirection
      Protected ObjectiveTileCoords.TVector2D
      GetRandomWalkableTileFromOriginTile(*RedArmoredDemon\GameMap, TileCoords\x, TileCoords\y, BombFreeWalkableDirection,
                                          @ObjectiveTileCoords, 5)
      If SwitchToGoingToObjectiveTile(*RedArmoredDemon, @ObjectiveTileCoords)
        ;could find a path, we are fine
        ProcedureReturn
      EndIf
      
      ;couldn't find a path, let's wait
      ;there is bombs on all directions, just wait then
      SwitchToWaitingEnemy(*RedArmoredDemon, 3.0)
      ProcedureReturn
    EndIf
    
    ;there is bombs on all directions, just wait then
    SwitchToWaitingEnemy(*RedArmoredDemon, 3.0)
    ProcedureReturn
    
    
    
  EndIf
  
  Protected PlayerCoords.TVector2D
  Protected LookingDirection.TMapDirection
  
  Protected FollowingVelocity.TVector2D\x = 100
  FollowingVelocity\y = 100
  
  If *RedArmoredDemon\CurrentState = #EnemyStateWaiting
    If *RedArmoredDemon\StateTimer <= 0
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
    *RedArmoredDemon\StateTimer - TimeSlice
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateGoingToObjectiveTile
    ;going to tile
    If GoToObjectiveTileEnemy(*RedArmoredDemon)
      If RandomFloat() <= 0.5
        If Not SwitchToDropingBomb(*RedArmoredDemon)
          ;could not drop bomb let's just wait
          SwitchToWaitingEnemy(*RedArmoredDemon, 1.0)
          ProcedureReturn
        EndIf
        ;Debug "dropped tha bomb"
        ProcedureReturn
      Else
        SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      EndIf
      ProcedureReturn
    EndIf
    
    Protected CurrentLookingDirection.a = GetMapDirectionByDeltaSign(*RedArmoredDemon\LookingDirection\x,
                                                                     *RedArmoredDemon\LookingDirection\y)
    
    If LookForPlayerInDirection(*RedArmoredDemon, CurrentLookingDirection, @PlayerCoords)
      ;Debug "found player"
      ;found the player in this direction
      If SwitchToFollowingPlayer(*RedArmoredDemon, @PlayerCoords, @FollowingVelocity)
        ProcedureReturn
      EndIf
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
  ElseIf  *RedArmoredDemon\CurrentState = #EnemyStateFollowingPlayer
    Protected PlayerDirecton.TMapDirection
    If CloseEnoughToPlayerInAnyDirection(*RedArmoredDemon, @PlayerDirecton)
      If Not SwitchToDropingBomb(*RedArmoredDemon, @GetTileToDropBombPlayer())
        ;could not drop bomb
        SwitchToWaitingEnemy(*RedArmoredDemon, 1.0)
        ProcedureReturn
      EndIf
    EndIf
    
    Protected ReachedCurrentObjectiveTile.Ascii
    If GoToObjectiveTileEnemy(*RedArmoredDemon, @ReachedCurrentObjectiveTile)
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateDropingBomb
    If GoToObjectiveTileEnemy(*RedArmoredDemon)
      ;reached the objective tile, time to drop the bomb
      DropBombEnemy(*RedArmoredDemon)
      If SwitchToGoingToSafety(*RedArmoredDemon)
        ProcedureReturn
      EndIf
      
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
      
    EndIf
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateGoingToSafety
    If GoToObjectiveTileEnemy(*RedArmoredDemon)
      ;reached the safety tile
      ;Debug "safety"
      Protected WaitingTimer.f = #BOMB1_TIMER + *RedArmoredDemon\BombPower * #EXPLOSION_EXPANSION_TIMER
      SwitchToWaitingEnemy(*RedArmoredDemon, WaitingTimer)
      ProcedureReturn
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
  
  *Enemy\HurtTimer = 0.0
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedArmoredDemonSprite, 0, 0, 16, 16)
  
EndProcedure

Procedure UpdateEnemyMagnetoBomb(*MagnetoBomb.TEnemy, TimeSlice.f)
  If *MagnetoBomb\CurrentState = #EnemyStateNoState
    ;just wait
    SwitchToWaitingEnemy(*MagnetoBomb, 1.0)
    ProcedureReturn
  EndIf
  
  Protected CurrentMapCoords.TVector2D
  GetTileCoordsByPosition(@*MagnetoBomb\MiddlePosition, @CurrentMapCoords)
  
  Protected PlayerMapCoords.TVector2D
  GetTileCoordsByPosition(@*MagnetoBomb\Player\MiddlePosition, @PlayerMapCoords)
  
  Protected FollingVelocity.TVector2D
  FollingVelocity\x = 120
  FollingVelocity\y = 120
  
  If *MagnetoBomb\CurrentState = #EnemyStateWaiting
    If *MagnetoBomb\StateTimer <= 0
      If IsTileInRange(*MagnetoBomb\GameMap, @CurrentMapCoords, @PlayerMapCoords, 5)
        ;found the player so we set the objective to the current player position,
        ;also we start the alive timer, the enemy will explode!
        If SwitchToGoingToObjectiveTile(*MagnetoBomb, @PlayerMapCoords)
          ;path found, let's go!
          ProcedureReturn
        EndIf
      EndIf
      ;let's go back to the initial state
      SwitchStateEnemy(*MagnetoBomb, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
    *MagnetoBomb\StateTimer - TimeSlice
    
  ElseIf *MagnetoBomb\CurrentState = #EnemyStateGoingToObjectiveTile
    ;going to tile
    If GoToObjectiveTileEnemy(*MagnetoBomb)
      If PlayerMapCoords\x = CurrentMapCoords\x And PlayerMapCoords\y = CurrentMapCoords\y
        ;arrived at the objectivetile and the player is there, let's explode
        *MagnetoBomb\HasAliveTimer = #True
        *MagnetoBomb\AliveTimer = 3.0
        ;we just wait until the alivetimer runs out, wait a little more just to be sure 
        SwitchToWaitingEnemy(*MagnetoBomb, 3.1)
        ProcedureReturn
      EndIf
      ;no player there, so we restart the cycle for looking for the player
      SwitchStateEnemy(*MagnetoBomb, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
  EndIf
  
  If *MagnetoBomb\HasAliveTimer
    If *MagnetoBomb\AliveTimer <= 0.0
      KillEnemy(*MagnetoBomb)
    EndIf
    *MagnetoBomb\AliveTimer - TimeSlice
    
  EndIf
  
  *MagnetoBomb\HurtTimer - TimeSlice * (Bool(*MagnetoBomb\HurtTimer > 0.0))
  
  UpdateGameObject(*MagnetoBomb, TimeSlice)
    
  
EndProcedure

Procedure InitMagnetoBomb(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                            *DrawList.TDrawList, *GameMap.TMap, *PosMapCoords.TVector2D)
  
  ;store the middle x and y of the grid at *PosMapCoords
  Protected GridTileMiddlePosition.TVector2D\x = *PosMapCoords\x * #MAP_GRID_TILE_WIDTH + #MAP_GRID_TILE_WIDTH / 2
  GridTileMiddlePosition\y = *PosMapCoords\y * #MAP_GRID_TILE_HEIGHT + #MAP_GRID_TILE_HEIGHT / 2
  
  Protected EnemyWidth.u, EnemyHeight.u
  EnemyWidth = 16 * #SPRITES_ZOOM
  EnemyHeight = 16 * #SPRITES_ZOOM
  
  Protected Position.TVector2D\x = GridTileMiddlePosition\x - EnemyWidth / 2
  Position\y = GridTileMiddlePosition\y - EnemyHeight / 2
  
  InitGameObject(*Enemy, @Position, #EnemyMagnetoBombSprite, @UpdateEnemyMagnetoBomb(), @DrawEnemy(), #True, 16, 16,
                 #SPRITES_ZOOM, #EnemyDrawOrder)
  
  InitEnemy(*Enemy, *Player, *ProjectileList, *DrawList, #EnemyMagnetoBomb, *GameMap, 1.5)
  
  *Enemy\BombPower = 3.0
  
  *Enemy\HasAliveTimer = #False
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
EndProcedure

Procedure.a SwitchToSummoning(*Enemy.TEnemy)
  Protected CurrentTileCoords.TVector2D
  GetTileCoordsByPosition(@*Enemy\MiddlePosition, @CurrentTileCoords)
  
  Protected NewList WalkableDirections.a()
  
  Protected ThereIsWalkableDirections.a = GetWalkableDirectionsFromOriginTile(*Enemy\GameMap, CurrentTileCoords\x,
                                                                              CurrentTileCoords\y, WalkableDirections())
  
  If Not ThereIsWalkableDirections
    ;no free direction for the summoning
    ProcedureReturn #False
  EndIf
  
  RandomizeList(WalkableDirections())
  Protected FoundBombFreeWalkableDirection.a = #False
  Protected BombFreeWalkableDirection.a
  ForEach WalkableDirections()
    If Not IsThereBombsOnDirection(*Enemy, WalkableDirections(), #True, 5)
      ;found a direction with no projectile on it
      FoundBombFreeWalkableDirection = #True
      BombFreeWalkableDirection = WalkableDirections()
      Break
    EndIf
  Next
  
  If FoundBombFreeWalkableDirection
    ;this will be the breakable tile that we'll use to "summon" a new enemy
    Protected SummonTile.TVector2D
    Protected FoundIt.a = GetClosestBreakableTileFromOriginTile(*Enemy\GameMap, @CurrentTileCoords,
                                                                BombFreeWalkableDirection, @SummonTile)
    
    If FoundIt
      ;we set the enemy to go to the walkable tile before the summoning tile, because it is a walkable tile
      Protected ReverseDirection.TMapDirection = Map_All_Directions(BombFreeWalkableDirection)
      ;multiplying by -1 make the reverse direction
      ReverseDirection\x = ReverseDirection\x * -1
      ReverseDirection\y = ReverseDirection\y * -1
      Protected GoalTile.TVector2D\x = SummonTile\x + ReverseDirection\x
      GoalTile\y = SummonTile\y + ReverseDirection\y
      If Not SetPathObjectiveTile(*Enemy, @GoalTile)
        ;could not set path to the adjacent tile in reverse direction of the summin tile
        ProcedureReturn #False
      EndIf
      
      *Enemy\SummonTile = SummonTile
      
      Protected DeltaSignX.f, DeltaSignY.f
      DeltaSignX = Sign(*Enemy\ObjectiveTileCoords()\x - CurrentTileCoords\x)
      DeltaSignY = Sign(*Enemy\ObjectiveTileCoords()\y - CurrentTileCoords\y)
      
      ;set the direction for the objective tile
      *Enemy\ObjectiveTileDirection = GetMapDirectionByDeltaSign(DeltaSignX, DeltaSignY)
      
      *Enemy\Velocity\x = Cos(ATan2(DeltaSignX, DeltaSignY)) * 50
      *Enemy\Velocity\y = Sin(ATan2(DeltaSignX, DeltaSignY)) * 50
      
      SwitchStateEnemy(*Enemy, #EnemyStateSummoning)
      ProcedureReturn #True
      
    Else
      ;could not get a breakable tile to summon an enemy
      ProcedureReturn #False
      
    EndIf
    
    
  EndIf
  
  ;bombs on all sides
  ProcedureReturn #False
  
EndProcedure

Procedure UpdateEnemySummoner(*Summoner.TEnemy, TimeSlice.f)
  
  Protected TileCoords.TVector2D
  GetTileCoordsByPosition(*Summoner\MiddlePosition, @TileCoords)
  
  If *Summoner\CurrentState = #EnemyStateNoState
    NewList WalkableDirections.a()
    Protected ThereIsWalkableDirections.a = GetWalkableDirectionsFromOriginTile(*Summoner\GameMap, TileCoords\x,
                                                                                TileCoords\y, WalkableDirections())
    
    If Not ThereIsWalkableDirections
      ;no free random direction for the enemy
      ;let's just wait
      SwitchToWaitingEnemy(*Summoner, 3.0)
      ProcedureReturn
    EndIf
    
    RandomizeList(WalkableDirections())
    Protected FoundBombFreeWalkableDirection.a = #False
    Protected BombFreeWalkableDirection.a
    ForEach WalkableDirections()
      If Not IsThereBombsOnDirection(*Summoner, WalkableDirections(), #True, 5)
        FoundBombFreeWalkableDirection = #True
        BombFreeWalkableDirection = WalkableDirections()
        Break
      EndIf
    Next
    
    If FoundBombFreeWalkableDirection
      Protected ObjectiveTileCoords.TVector2D
      GetRandomWalkableTileFromOriginTile(*Summoner\GameMap, TileCoords\x, TileCoords\y, BombFreeWalkableDirection,
                                          @ObjectiveTileCoords, 5)
      If SwitchToGoingToObjectiveTile(*Summoner, @ObjectiveTileCoords)
        ;could find a path, we are fine
        ProcedureReturn
      EndIf
    EndIf
    
    ;there is bombs on all directions, just wait then
    SwitchToWaitingEnemy(*Summoner, 3.0)
    ProcedureReturn
    
  EndIf
  
  If *Summoner\CurrentState = #EnemyStateWaiting
    If *Summoner\StateTimer <= 0.0
      If RandomFloat() <= 0.1
        ;try to summon new wenemy
        If SwitchToSummoning(*Summoner)
          ;great we'll go the summonning state
          ProcedureReturn
        EndIf
        
        ;couldn't meet the conditions to summon an enemy (very much like nen users in the hunter x hunter anime)
        SwitchStateEnemy(*Summoner, #EnemyStateNoState)
      Else
        SwitchStateEnemy(*Summoner, #EnemyStateNoState)
      EndIf
      ProcedureReturn
    EndIf
    
    *Summoner\StateTimer - TimeSlice
    
  ElseIf *Summoner\CurrentState = #EnemyStateGoingToObjectiveTile
    If GoToObjectiveTileEnemy(*Summoner)
      SwitchToWaitingEnemy(*Summoner, 3.0)
      ProcedureReturn
    EndIf
    
  ElseIf *Summoner\CurrentState = #EnemyStateSummoning
    If GoToObjectiveTileEnemy(*Summoner)
      ;summon new enemy
      MakeTileWalkable(*Summoner\GameMap, *Summoner\SummonTile\x, *Summoner\SummonTile\y)
      *Summoner\SpawnEnemy(@*Summoner\SummonTile)
      SwitchStateEnemy(*Summoner, #EnemyStateNoState)
      PlaySoundEffect(#SummonEnemySound, #True)
      ProcedureReturn
    EndIf
    
  EndIf
  
  
  
  UpdateGameObject(*Summoner, TimeSlice)
  
  
  
  
  
  
EndProcedure

Procedure InitEnemySummoner(*Enemy.TEnemy, *Player.TGameObject, *ProjectileList.TProjectileList,
                       *DrawList.TDrawList, *GameMap.TMap, *PosMapCoords.TVector2D, *SpawnEnemy.SpawnEnemyProc)
  
  ;store the middle x and y of the grid at *PosMapCoords
  Protected GridTileMiddlePosition.TVector2D\x = *PosMapCoords\x * #MAP_GRID_TILE_WIDTH + #MAP_GRID_TILE_WIDTH / 2
  GridTileMiddlePosition\y = *PosMapCoords\y * #MAP_GRID_TILE_HEIGHT + #MAP_GRID_TILE_HEIGHT / 2
  
  Protected EnemyWidth.u, EnemyHeight.u
  EnemyWidth = 16 * #SPRITES_ZOOM
  EnemyHeight = 16 * #SPRITES_ZOOM
  
  Protected Position.TVector2D\x = GridTileMiddlePosition\x - EnemyWidth / 2
  Position\y = GridTileMiddlePosition\y - EnemyHeight / 2
  
  InitGameObject(*Enemy, @Position, #EnemySummonerSprite, @UpdateEnemySummoner(), @DrawEnemy(), #True, 16, 16,
                 #SPRITES_ZOOM, #EnemyDrawOrder)
  
  InitEnemy(*Enemy, *Player, *ProjectileList, *DrawList, #EnemySummoner, *GameMap)
  
  *Enemy\BombPower = 3.0
  
  *Enemy\HasAliveTimer = #False
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  *Enemy\SpawnEnemy = *SpawnEnemy
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemySummonerSprite, 0, 0, 16, 16)
  
EndProcedure



DisableExplicit