﻿XIncludeFile "GameObject.pbi"
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

Procedure SetPathObjectiveTile(*Enemy.TEnemy, *GoalTileCoords.TVector2D, *FirstObjectiveTile.TVector2D = #Null)
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
  EndIf
  
  ;delete the first element because is is the current tile coords for the enemy
  FirstElement(*Enemy\ObjectiveTileCoords())
  DeleteElement(*Enemy\ObjectiveTileCoords())
  
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

Procedure SwitchToFollowingPlayer(*Enemy.TEnemy, *PlayerCoords.TVector2D, *Velocity.TVector2D, *FirstObjectiveTile.TVector2D = #Null)
  *Enemy\Velocity\x = 0
  *Enemy\Velocity\y = 0
  
  SetPathObjectiveTile(*Enemy, *PlayerCoords, *FirstObjectiveTile)
  
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

Procedure.a DropBombEnemy(*Enemy.TEnemy)
  Protected *Projectile.TProjectile = GetInactiveProjectile(*Enemy\Projectiles)
  If *Projectile = #Null
    ;couldn't allocate the memory for a bomb :(
    ProcedureReturn #False
  EndIf
  
  Protected BombTileCoords.TVector2D
  GetTileCoordsByPosition(*Enemy\MiddlePosition, @BombTileCoords)
  
  InitProjectileBomb1(*Projectile, @BombTileCoords, *Enemy\GameMap, *Enemy\DrawList, *Enemy\BombPower, *Enemy, *Enemy\Projectiles)
  
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
      SwitchToGoingToSafety(*RedDemon)
    EndIf
    
  ElseIf *RedDemon\CurrentState = #EnemyStateGoingToSafety
    If GoToObjectiveTileEnemy(*RedDemon)
      ;reached the safety tile
      ;Debug "safety"
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
      
      SwitchToFollowingPlayer(*RedArmoredDemon, @PlayerCoords, @FollowingVelocity)
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
      
      ;Debug "should drop bomb on player!!!"
      ProcedureReturn
    EndIf
    
    Protected ReachedCurrentObjectiveTile.Ascii
    If GoToObjectiveTileEnemy(*RedArmoredDemon, @ReachedCurrentObjectiveTile)
      SwitchStateEnemy(*RedArmoredDemon, #EnemyStateNoState)
      ProcedureReturn
    EndIf
    
    If ReachedCurrentObjectiveTile\a = #True And LookForPlayerInAllDirections(*RedArmoredDemon, @PlayerCoords)
      
      ;if we reached the current objective tile, but not reached the end of path
      ;and found the player when looking in all for directions
      ;Debug "found player again"
      SwitchToFollowingPlayer(*RedArmoredDemon, @PlayerCoords, @FollowingVelocity, #Null)
      ProcedureReturn
    EndIf
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateDropingBomb
    If GoToObjectiveTileEnemy(*RedArmoredDemon)
      ;reached the objective tile, time to drop the bomb
      DropBombEnemy(*RedArmoredDemon)
      SwitchToGoingToSafety(*RedArmoredDemon)
    EndIf
    
  ElseIf *RedArmoredDemon\CurrentState = #EnemyStateGoingToSafety
    If GoToObjectiveTileEnemy(*RedArmoredDemon)
      ;reached the safety tile
      ;Debug "safety"
      SwitchToWaitingEnemy(*RedArmoredDemon, 2.5)
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
  
  *Enemy\MaxVelocity\x = 500
  *Enemy\MaxVelocity\y = 500
  
  SwitchStateEnemy(*Enemy, #EnemyStateNoState)
  
  ClipSprite(#EnemyRedArmoredDemonSprite, 0, 0, 16, 16)
  
EndProcedure



DisableExplicit