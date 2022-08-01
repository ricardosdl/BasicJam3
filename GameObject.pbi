XIncludeFile "Math.pbi"

EnableExplicit

Prototype UpdateGameObjectProc(*GameObject, TimeSlice.f)
Prototype DrawGameObjectProc(*GameObject)
Prototype.a GetCollisionRectGameObjectProc(*GameObject, *CollisonRect.TRect)

Structure TGameObject
  Position.TVector2D
  MiddlePosition.TVector2D
  LastPosition.TVector2D
  OriginalWidth.u
  OriginalHeight.u
  ZoomFactor.f
  Width.u
  Height.u
  
  SpriteNum.i
  
  Acceleration.TVector2D
  Velocity.TVector2D
  MaxVelocity.TVector2D
  Drag.TVector2D
  
  Update.UpdateGameObjectProc
  Draw.DrawGameObjectProc
  
  Active.a
  
  Health.f
  
  DrawOrder.l
  
  GetCollisionRect.GetCollisionRectGameObjectProc
  
  
  
EndStructure

Procedure GetSpriteOriginalWidthAndHeight(SpriteNum.i, *OriginalWidth.Integer, *OriginalHeight.Integer)
  ;saves the current width and height
  Protected CurrentWidth, CurrentHeight
  CurrentWidth = SpriteWidth(SpriteNum)
  CurrentHeight = SpriteHeight(SpriteNum)
  
  ;restore the orignal dimensions
  ZoomSprite(SpriteNum, #PB_Default, #PB_Default)
  
  *OriginalWidth\i = SpriteWidth(SpriteNum)
  *OriginalHeight\i = SpriteHeight(SpriteNum)
  
  ;restore the current dimensions
  ZoomSprite(SpriteNum, CurrentWidth, CurrentHeight)
  
  
EndProcedure

Procedure.a GetCollisionRectGameObject(*GameObject.TGameObject, *CollisionRect.TRect)
  ;this default implementation just uses the current position, width and height of
  ;*GameObject and always returns the *GameObject as collidable
  *CollisionRect\Position = *GameObject\Position
  *CollisionRect\Width = *GameObject\Width
  *CollisionRect\Height = *GameObject\Height
  ProcedureReturn #True
EndProcedure


Procedure InitGameObject(*GameObject.TGameObject, *Position.TVector2D, SpriteNum.i,
                         *UpdateProc.UpdateGameObjectProc, *DrawProc.DrawGameObjectProc,
                         Active.a, ZoomFactor.f = 1.0, DrawOrder.l = 0)
  
  *GameObject\Position\x = *Position\x
  *GameObject\Position\y = *Position\y
  
  
  Protected OriginalWidth.Integer, OriginalHeight.Integer
  GetSpriteOriginalWidthAndHeight(SpriteNum, @OriginalWidth, @OriginalHeight)
  
  *GameObject\OriginalWidth = OriginalWidth\i
  *GameObject\OriginalHeight = OriginalHeight\i
  *GameObject\ZoomFactor = ZoomFactor
  *GameObject\Width = OriginalWidth\i * ZoomFactor
  *GameObject\Height = OriginalHeight\i * ZoomFactor
  *GameObject\SpriteNum = SpriteNum
  ZoomSprite(*GameObject\SpriteNum, OriginalWidth\i * ZoomFactor, OriginalHeight\i * ZoomFactor)
  
  *GameObject\Update = *UpdateProc
  *GameObject\Draw = *DrawProc
  
  *GameObject\Active = Active
  
  *GameObject\DrawOrder = DrawOrder
  
  *GameObject\GetCollisionRect = @GetCollisionRectGameObject()
  
  
  
  
EndProcedure

Procedure DrawGameObject(*GameObject.TGameObject, Intensity = 255)
  DisplayTransparentSprite(*GameObject\SpriteNum, Int(*GameObject\Position\x),
                           Int(*GameObject\Position\y), Intensity)
EndProcedure

Macro UpdateMiddlePositionGameObject(GameObject)
  GameObject\MiddlePosition\x = GameObject\Position\x + GameObject\Width / 2
  GameObject\MiddlePosition\y = GameObject\Position\y + GameObject\Height / 2
EndMacro

Procedure UpdateGameObject(*GameObject.TGameObject, TimeSlice.f)
  *GameObject\Velocity\x + *GameObject\Acceleration\x * TimeSlice
  *GameObject\Velocity\y + *GameObject\Acceleration\y * TimeSlice
  
  If Abs(*GameObject\Velocity\x) > *GameObject\MaxVelocity\x
    *GameObject\Velocity\x = Sign(*GameObject\Velocity\x) * *GameObject\MaxVelocity\x
  EndIf
  
  If Abs(*GameObject\Velocity\y) > *GameObject\MaxVelocity\y
    *GameObject\Velocity\y = Sign(*GameObject\Velocity\y) * *GameObject\MaxVelocity\y
  EndIf
  
  *GameObject\Position\x + *GameObject\Velocity\x * TimeSlice
  *GameObject\Position\y + *GameObject\Velocity\y * TimeSlice
  
  *GameObject\MiddlePosition\x = *GameObject\Position\x + *GameObject\Width / 2
  *GameObject\MiddlePosition\y = *GameObject\Position\y + *GameObject\Height / 2
  
  
EndProcedure

Procedure GetRandomRectAroundGameObject(*GameObject.TGameObject, RectWidth.f, RectHeight.f,
                                    *RectAroundPlayer.TRect)
  Protected NumOffsets.a = 4
  Dim RandomOffsets.TVector2D(NumOffsets - 1)
  RandomOffsets(0)\x = 0 : RandomOffsets(1)\y = -1
  RandomOffsets(1)\x = 1 : RandomOffsets(1)\y = 0
  RandomOffsets(2)\x = 0 : RandomOffsets(2)\y = 1
  RandomOffsets(3)\x = -1 : RandomOffsets(3)\y = 0
  
  Protected RandomRect.TRect
  Protected MaxIdxRandomOffsets.a = ArraySize(RandomOffsets())
  
  Protected RandomOffset.TVector2D = RandomOffsets(Random(MaxIdxRandomOffsets, 0))
  RandomRect\Width = RectWidth : RandomRect\Height = RectHeight
  ;If RandomOffset\x = 0 Or RandomOffset\y = 0
  If RandomOffset\x = 0
    ;just center the randomrect on the x axis with the player
    RandomRect\Position\x = *GameObject\Position\x - (RandomRect\Width / 2)
    ;the random rect will be above or bellow the player
    RandomRect\Position\y = *GameObject\Position\y + RandomOffset\y * RandomRect\Height
  ElseIf RandomOffset\y = 0
    ;just center the randomrect on the y axis with the player
    RandomRect\Position\y = *GameObject\Position\y - (RandomRect\Height / 2)
    ;the random rect will be left or right the player
    RandomRect\Position\x = *GameObject\Position\x + RandomOffset\x * RandomRect\Width
  EndIf
  
  CopyStructure(@RandomRect, *RectAroundPlayer, TRect)
  
EndProcedure






DisableExplicit