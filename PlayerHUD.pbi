XIncludeFile "GameObject.pbi"
XIncludeFile "Player.pbi"
XIncludeFile "DrawOrders.pbi"

EnableExplicit

Structure TPlayerHUD Extends TGameObject
  *Player.TPlayer
  Level.a;is updated by gamestate
EndStructure

#PLAYER_HUD_Y_OFFSET = 15.0

Global Player_HUD_Name_Y_Offset.f = 0
Global Player_HUD_Bomb_Power_Y_Offset.f
Global Player_HUD_Bombs_Y_Offset.f
Global Player_HUD_Hearts_Y_Offset.f
Global Player_HUD_Level_Y_Offset.f


Procedure DrawPlayerName(*PlayerHUD.TPlayerHUD)
  Protected PosX.f, PosY.f
  PosX = *PlayerHUD\Position\x
  PosY = *PlayerHUD\Position\y + Player_HUD_Name_Y_Offset
  DrawTextWithStandardFont(PosX, PosY, "PLAYER 1",
                           (#STANDARD_FONT_WIDTH * 1.5) * #SPRITES_ZOOM, (#STANDARD_FONT_HEIGHT * 1.5) * #SPRITES_ZOOM)
  Player_HUD_Bomb_Power_Y_Offset = ((#STANDARD_FONT_HEIGHT * 1.5) * #SPRITES_ZOOM) + #PLAYER_HUD_Y_OFFSET
EndProcedure

Procedure DrawPlayerBombPower(*PlayerHUD.TPlayerHUD)
  Protected PosX.f,PosY.f
  PosX = *PlayerHUD\Position\x
  PosY = Player_HUD_Bomb_Power_Y_Offset
  
  Protected BombPowerText.s = "BOMB POWER:" + StrF(*PlayerHUD\Player\BombPower)
  
  DrawTextWithStandardFont(PosX, PosY, BombPowerText, (#STANDARD_FONT_WIDTH * 1.5) * #SPRITES_ZOOM,
                           (#STANDARD_FONT_HEIGHT * 1.5) * #SPRITES_ZOOM)
  
  Player_HUD_Bombs_Y_Offset = PosY + #PLAYER_HUD_Y_OFFSET
  
EndProcedure

Procedure DrawPlayerBombs(*PlayerHUD.TPlayerHUD)
  Protected PosX.f, PosY.f
  PosX = *PlayerHUD\Position\x
  PosY = Player_HUD_Bombs_Y_Offset
  
  Protected BombsText.s = "BOMBS:" + Str(*PlayerHUD\Player\CurrentBombsLimit)
  
  DrawTextWithStandardFont(PosX,PosY, BombsText, (#STANDARD_FONT_WIDTH * 1.5) * #SPRITES_ZOOM,
                           (#STANDARD_FONT_HEIGHT * 1.5) * #SPRITES_ZOOM)
  
  Player_HUD_Hearts_Y_Offset = Player_HUD_Bombs_Y_Offset + #PLAYER_HUD_Y_OFFSET
  
EndProcedure

Procedure DrawPlayerHearts(*PlayerHUD.TPlayerHUD)
  Protected i
  Protected PosX.f, PosY.f
  PosX = *PlayerHUD\Position\x
  For i = 0 To *PlayerHUD\Player\Health - 1
    Protected Column.l = i % 4
    PosX = *PlayerHUD\Position\x + (Column) * (SpriteWidth(#PlayerHeartSprite) * #SPRITES_ZOOM)
    Protected Row.l = i / 4
    PosY = Player_HUD_Hearts_Y_Offset + (Row) * (SpriteHeight(#PlayerHeartSprite) * #SPRITES_ZOOM)
    DisplayTransparentSprite(#PlayerHeartSprite, PosX, PosY)
  Next
  
  Player_HUD_Level_Y_Offset = PosY + #PLAYER_HUD_Y_OFFSET
  
EndProcedure

Procedure DrawPlayerLevel(*PlayerHUD.TPlayerHUD)
  Protected PosX.f, PosY.f
  PosX = *PlayerHUD\Position\x
  PosY = *PlayerHUD\Position\y + Player_HUD_Level_Y_Offset
  DrawTextWithStandardFont(PosX, PosY, "Level:" + *PlayerHUD\Level,
                           (#STANDARD_FONT_WIDTH * 1.5) * #SPRITES_ZOOM, (#STANDARD_FONT_HEIGHT * 1.5) * #SPRITES_ZOOM)
EndProcedure


Procedure DrawPlayerHUD(*PlayerHUD.TPlayerHUD)
  DrawPlayerName(*PlayerHUD)
  DrawPlayerBombPower(*PlayerHUD)
  DrawPlayerBombs(*PlayerHUD)
  DrawPlayerHearts(*PlayerHUD)
  DrawPlayerLevel(*PlayerHUD)
EndProcedure

Procedure InitPlayerHUD(*PlayerHUD.TPlayerHUD, *Player.TPlayer, *Position.TVector2D)
  InitGameObject(*PlayerHUD, *Position, -1, @UpdateGameObject(), @DrawPlayerHUD(), #True,
                 16, 16, #SPRITES_ZOOM, #PlayerHUDDrawOrder)
  
  *PlayerHUD\Player = *Player
  
EndProcedure


DisableExplicit
