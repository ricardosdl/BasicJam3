EnableExplicit

Procedure.f RandomSinValue()
  Protected RandomAngle.f = Random(359, 0)
  ProcedureReturn Sin(Radian(RandomAngle))
EndProcedure

Procedure.a CollisionRectRect(x1.f, y1.f, w1.f, h1.f, x2.f, y2.f, w2.f, h2.f)
  Protected RightAndLeft.a = Bool(x1 + w1 > x2 And x1 < x2 + w2)
  Protected TopAndBottom.a = Bool(y1 + h1 > y2 And y1 < y2 + h2)
  ProcedureReturn Bool(RightAndLeft And TopAndBottom)
EndProcedure

Procedure.f ClampF(Value.f, Min.f, Max.f)
  If Value < Min
    ProcedureReturn Min
  EndIf
  
  If Value > Max
    ProcedureReturn Max
  EndIf
  
  ProcedureReturn Value
  
  
EndProcedure

Procedure.f DistanceBetweenPoints(x1.f, y1.f, x2.f, y2.f)
  Protected DistX.f = x1 - x2
  Protected DistY.f = y1 - y2
  ProcedureReturn Sqr((DistX * DistX) + (DistY * DistY))
EndProcedure

Procedure.f RandomFloat()
  ProcedureReturn Random(10000, 0) / 10000.0
EndProcedure

Procedure.f RandomInterval(Max.f, Min.f)
  Protected Range.f = Abs(Max - Min)
  ProcedureReturn Min + Range * RandomFloat()
EndProcedure


DisableExplicit