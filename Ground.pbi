XIncludeFile "GameObject.pbi"
XIncludeFile "DrawOrders.pbi"


EnableExplicit

Structure TGround Extends TGameObject
  
EndStructure

Procedure DrawGround(*Ground.TGround)
  Protected x, y
  Protected NumGroundsWidth = ScreenWidth() / *Ground\Width
  Protected NumGroundsHeight = ScreenHeight() / *Ground\Height
  For x = 0 To NumGroundsWidth - 1
    For y = 0 To NumGroundsHeight - 1
      DisplayTransparentSprite(*Ground\SpriteNum, x * *Ground\Width, y * *Ground\Height)
    Next y
  Next x
  
EndProcedure

Procedure InitGround(*Ground.TGround)
  
  Protected Position.TVector2D\x = 0
  Position\y = 0
  
  InitGameObject(*Ground, @Position, #Ground, #Null, @DrawGround(), #True, #SPRITES_ZOOM,
                 #GroundDrawOrder)
  
  
EndProcedure




DisableExplicit