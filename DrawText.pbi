XIncludeFile "Resources.pbi"

EnableExplicit

#STANDARD_FONT_WIDTH = 6
#STANDARD_FONT_HEIGHT = 8

Procedure DrawTextWithStandardFont(x.f, y.f, Text.s, CharWidthPx.f = #STANDARD_FONT_WIDTH,
                                   CharHeightPx.f = #STANDARD_FONT_HEIGHT, Intensity = 255)
  ;remove any clipping
  ClipSprite(#StandardFont, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
  ;remove any zoom
  ZoomSprite(#StandardFont, #PB_Default, #PB_Default)
  Protected i, LenText = Len(Text)
  For i.i = 1 To LenText;loop the string Text char by char
    Protected AsciiValue.a = Asc(Mid(Text, i, 1))
    Protected LetterColumn = (AsciiValue - 32) % 16
    Protected PaddingColumn = (LetterColumn + 1)
    
    Protected LetterLine = (AsciiValue - 32) / 16
    Protected PaddingLine = LetterLine + 1
    ClipSprite(#StandardFont, LetterColumn * #STANDARD_FONT_WIDTH + PaddingColumn,
               LetterLine * #STANDARD_FONT_HEIGHT + PaddingLine, #STANDARD_FONT_WIDTH,
               #STANDARD_FONT_HEIGHT)
    ZoomSprite(#StandardFont, CharWidthPx, CharHeightPx)
    DisplayTransparentSprite(#StandardFont, Int(x + (i - 1) * CharWidthPx), Int(y))
  Next
  
EndProcedure



DisableExplicit