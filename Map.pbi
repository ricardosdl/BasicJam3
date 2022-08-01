XIncludeFile "GameObject.pbi"
XIncludeFile "Math.pbi"
XIncludeFile "Util.pbi"
XIncludeFile "DrawList.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Enumeration
  
EndEnumeration

Structure TTile
  Walkable.a
  Destructable.a
  DrawOrder.u
  SpriteNum
EndStructure

#MAP_GRID_WIDTH = 30
#MAP_GRID_HEIGHT = 30

#MAP_GRID_TILE_WIDTH = 16
#MAP_GRID_TILE_HEIGHT = 16

Structure TMapGrid
  Array TilesGrid.TTile(#MAP_GRID_WIDTH - 1, #MAP_GRID_HEIGHT - 1)
EndStructure


Structure TMap
  
  MapGrid.TMapGrid
  
EndStructure







DisableExplicit