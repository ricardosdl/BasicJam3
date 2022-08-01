EnableExplicit

Structure TVector2D
  x.f
  y.f
EndStructure

Structure TRect
  Position.TVector2D
  Width.f
  Height.f
EndStructure

Structure TCircle
  Position.TVector2D
  Radius.f
EndStructure

Procedure RotateAroundPoint(*PointOfRotation.TVector2D, *PointToRotate.TVector2D, Angle.f)
  
  Protected s.f, c.f
  s = Sin(Angle)
  c = Cos(Angle)
  
  ;translate *pointtorotate to the origin
  *PointToRotate\x = *PointToRotate\x - *PointOfRotation\x
  *PointToRotate\y = *PointToRotate\y - *PointOfRotation\y
  
  Protected NewX.f, NewY.f
  Newx = *PointToRotate\x * c - *PointToRotate\y * s
  NewY = *PointToRotate\x * s + *PointToRotate\y * c
  
  ;translate *pointotorotate back 
  *PointToRotate\x = newx + *PointOfRotation\x
  *PointToRotate\y = newy + *PointOfRotation\y
  
EndProcedure





DisableExplicit