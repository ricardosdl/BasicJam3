XIncludeFile "GameObject.pbi"
XIncludeFile "Player.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Structure TPlayerHUD Extends TGameObject
  *Player.TPlayer
EndStructure

#PLAYER_HUD_NAME_Y_OFFSET = 0


Procedure DrawPlayerName(*PlayerHUD.TPlayerHUD)
  Protected PosX.f, PosY.f
  PosX = *PlayerHUD\Position\x
  PosY = *PlayerHUD\Position\y + #PLAYER_HUD_NAME_Y_OFFSET
  DrawTextWithStandardFont(PosX, PosY, "PLAYER 1")
EndProcedure

Procedure DrawPlayerHUD(*PlayerHUD.TPlayerHUD)
  DrawPlayerName(*PlayerHUD)
EndProcedure

Procedure InitPlayerHUD(*PlayerHUD.TPlayerHUD, *Player.TPlayer, *Position.TVector2D)
  InitGameObject(*PlayerHUD, *Position, -1, @UpdateGameObject(), @DrawPlayerHUD(), #True,
                 16, 16, #SPRITES_ZOOM, #PlayerHUDDrawOrder)
  
  *PlayerHUD\Player = *Player
  
EndProcedure


DisableExplicit
