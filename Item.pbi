﻿XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "Map.pbi"
XIncludeFile "Player.pbi"


EnableExplicit

Enumeration EItemType
  #ItemTypeBombPower
  #ItemTypeIncreaseBombs
EndEnumeration

#ITEM_TIMER = 30.0;in seconds
;for the the DONT_EXPLODE_TIMER, the item can't be exploded
#ITEM_DONT_EXPLODE_TIMER = 5.0;in seconds

Structure TItem Extends TGameObject
  PositionMapCoords.TVector2D
  ItemType.a
  AliveTimer.f
  Enabled.a;when enabled the item is visible and can be interacted with
  
EndStructure

Structure TItemList
  List Items.TItem()
EndStructure

Procedure GetInactiveItem(*ItemList.TItemList, AddIfNotFound.a = #True)
  ForEach *ItemList\Items()
    If Not *ItemList\Items()\Active
      ProcedureReturn @*ItemList\Items()
    EndIf
  Next
  
  If AddIfNotFound
    If AddElement(*ItemList\Items()) <> 0
      ;sucessfully added a new element, now return it
      ProcedureReturn @*ItemList\Items()
    Else
      ;error allocating the element in the list
      ProcedureReturn #Null
    EndIf
  EndIf
  
  ProcedureReturn #Null
  
EndProcedure

Procedure KillItem(*Item.TItem)
  *Item\Active = #False
EndProcedure

Procedure UpdateItem(*Item.TItem, TimeSlice.f)
  If *Item\AliveTimer <= 0.0
    KillItem(*Item)
    ProcedureReturn
  EndIf
  
  *Item\AliveTimer - (TimeSlice * Bool(*Item\Enabled))
  
  UpdateGameObject(*Item, TimeSlice)
  
EndProcedure

Procedure DrawItem(*Item.TItem)
  If *Item\Enabled
    DrawGameObject(*Item)
  EndIf
  DrawGameObject(*Item)
EndProcedure

Procedure.a GetCollisionCoordsItem(*Item.TItem, *CollisionCoords.TRect)
  If *Item\AliveTimer + #ITEM_DONT_EXPLODE_TIMER >= #ITEM_TIMER
    ProcedureReturn #False
  EndIf
  
  GetTileCoordsByPosition(@*Item\MiddlePosition, @*CollisionCoords\Position)
  ProcedureReturn #True
  
EndProcedure

Procedure InitItemBombPower(*Item.TItem, *GameMap.TMap, *MapCoords.TVector2D, ItemType.a, Enabled.a)
  
  *Item\PositionMapCoords\x = *MapCoords\x
  *Item\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*MapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*MapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Item, @Position, #ItemBombPowerSprite, @UpdateItem(), @DrawItem(),
                 #True, 16, 16, #SPRITES_ZOOM, #ItemDrawOrder)
  
  *Item\Health = 1.0
  
  *Item\AliveTimer = #ITEM_TIMER;in seconds
  
  *item\ItemType = ItemType
  
  *Item\Enabled = Enabled
  
  *Item\GetCollisionRect = @GetCollisionCoordsItem()
  
  ClipSprite(#ItemBombPowerSprite, 0, 0, 16, 16)
  
EndProcedure

Procedure EnableItem(*Item.TItem)
  *item\Enabled = #True
EndProcedure

Procedure ApplyItemOnPlayer(*Player.TPlayer, *Item.TItem)
  Select *Item\ItemType
    Case #ItemTypeBombPower
      *Player\BombPower + 1
      KillItem(*Item)
      Debug "increased player's bomb power"
  EndSelect
  
  
EndProcedure



DisableExplicit