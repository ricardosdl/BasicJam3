﻿XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawOrders.pbi"
XIncludeFile "Map.pbi"


EnableExplicit

Enumeration EItemType
  #ItemTypeBombPower
EndEnumeration

#ITEM_TIMER = 30.0;in seconds

Structure TItem Extends TGameObject
  PositionMapCoords.TVector2D
  ItemType.a
  AliveTimer.f
  Enabled.a;when enabled the item is visible and can be interacted with
EndStructure

Structure TItemList
  List Items.TItem()
EndStructure

Procedure UpdateItem(*Item.TItem, TimeSlice.f)
  If *Item\AliveTimer <= 0.0
    *Item\Active = #False
    ProcedureReturn
  EndIf
  
  *Item\AliveTimer - TimeSlice
  
  UpdateGameObject(*Item, TimeSlice)
  
EndProcedure

Procedure InitItemBombPower(*Item.TItem, *GameMap.TMap, *MapCoords.TVector2D, ItemType.a, Enabled.a)
  
  *Item\PositionMapCoords\x = *MapCoords\x
  *Item\PositionMapCoords\y = *MapCoords\y
  
  Protected Position.TVector2D\x = *GameMap\Position\x + (*MapCoords\x * #MAP_GRID_TILE_WIDTH)
  Position\y = *GameMap\Position\y + (*MapCoords\y * #MAP_GRID_TILE_HEIGHT)
  
  InitGameObject(*Item, @Position, #ItemBombPowerSprite, @UpdateItem(), @DrawGameObject(),
                 #True, 16, 16, #SPRITES_ZOOM, #ItemDrawOrder)
  
  *Item\Health = 1.0
  
  *Item\AliveTimer = #ITEM_TIMER;in seconds
  
  *item\ItemType = ItemType
  
  *Item\Enabled = Enabled
  
  ClipSprite(#ItemBombPowerSprite, 0, 0, 16, 16)
  
EndProcedure


DisableExplicit