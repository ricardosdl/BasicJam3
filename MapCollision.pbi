XIncludeFile "Map.pbi"
XIncludeFile "GameObject.pbi"

EnableExplicit

Structure TMapCollision
  *GameObject.TGameObject
  *GameMap.TMap
  *GetCollisionRect.GetCollisionRectGameObjectProc
  
EndStructure



DisableExplicit