
EnableExplicit

#MAX_SPRITE_ANIMATION_FRAMES = 127

Prototype UpdateSpriteAnimation(*SpriteAnimation, TimeSlice.f)
Prototype DrawSpriteAnimation(*SpriteAnimation, x.l, y.l, Intensity.a = 255, *Color = #Null)

Structure TSpriteAnimation
  Sprite.i
  Width.u : Height.u;the original width and height of the sprite, before zooming
  ZoomedWidth.f : ZoomedHeight.f;width and height after the zoom has been applyed
  NumFrames.a
  CurrentFrame.b
  AnimationFPS.f;frame per second for the animation
  AnimationTimer.f;calculated as 1 / AnimationFPS
  IsAnimated.a
  ZoomLevel.f;the actual width or height it must be multiplied by the zoomlevel value
  Update.UpdateSpriteAnimation
  Draw.DrawSpriteAnimation
EndStructure

Structure TColor
  r.a
  g.a
  b.a
  a.a
EndStructure

Procedure UpdateSpriteAnimation(*SpriteAnimation.TSpriteAnimation, TimeSlice.f)
  If *SpriteAnimation\AnimationTimer <= 0.0
    *SpriteAnimation\CurrentFrame = (*SpriteAnimation\CurrentFrame + 1) % *SpriteAnimation\NumFrames
    *SpriteAnimation\AnimationTimer = 1 / *SpriteAnimation\AnimationFPS
  EndIf
  
  *SpriteAnimation\AnimationTimer - TimeSlice
  
  
  
EndProcedure

Procedure DrawSpriteAnimation(*SpriteAnimation.TSpriteAnimation, x.l, y.l, Intensity.a = 255, *Color.TColor = #Null)
  ClipSprite(*SpriteAnimation\Sprite, *SpriteAnimation\CurrentFrame * *SpriteAnimation\Width, 0,
             *SpriteAnimation\Width, *SpriteAnimation\Height);here we clip the current frame that we want to display
  
  
  ;the zoom must be applied after the clipping(https://www.purebasic.fr/english/viewtopic.php?p=421807#p421807)
  ZoomSprite(*SpriteAnimation\ZoomLevel, *SpriteAnimation\Width * *SpriteAnimation\ZoomLevel,
             *SpriteAnimation\Height * *SpriteAnimation\ZoomLevel)
  If *Color = #Null
    DisplayTransparentSprite(*SpriteAnimation\Sprite, x, y, Intensity)
  Else
    DisplayTransparentSprite(*SpriteAnimation\Sprite, x, y, Intensity, RGB(*Color\r, *Color\g, *Color\b))
  EndIf
  
  
EndProcedure

Procedure InitSpriteAnimation(*SpriteAnimation.TSpriteAnimation, Sprite.i, Width.u, Height.u, NumFrames.a, CurrentFrame.b,
                              AnimationFPS.f, IsAnimated.a = #True, ZoomLevel.f = 1.0)
  
  With *SpriteAnimation
    \Sprite = Sprite
    \Width = Width
    \Height = Height
    \ZoomedWidth = Width * ZoomLevel
    \ZoomedHeight = Height * ZoomLevel
    \NumFrames = NumFrames
    \CurrentFrame = CurrentFrame
    \AnimationFPS = AnimationFPS
    \AnimationTimer = 1 / AnimationFPS
    \IsAnimated = IsAnimated
    \ZoomLevel = ZoomLevel
    \Update = @UpdateSpriteAnimation()
    \Draw = @DrawSpriteAnimation()
  EndWith
  
  If *SpriteAnimation\NumFrames > #MAX_SPRITE_ANIMATION_FRAMES
    *SpriteAnimation\NumFrames = #MAX_SPRITE_ANIMATION_FRAMES
  EndIf
  
  If *SpriteAnimation\AnimationFPS <= 0
    *SpriteAnimation\AnimationFPS = 1.0
  EndIf
  
  
  
  
  
  
EndProcedure


DisableExplicit