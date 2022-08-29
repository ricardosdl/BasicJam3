EnableExplicit

Structure TMultiChannelSound
  Sound.i
  Channel.i
EndStructure

Global SoundStarted, VolumeMusic = 50, VolumeSoundEffects = 50



Global NewList MultiChannelSounds.TMultiChannelSound()

Procedure.a InitializeSound()
  SoundStarted = InitSound()
  Debug SoundStarted
  ProcedureReturn Bool(SoundStarted <> 0)
EndProcedure

Procedure.a IsSoundInitialized()
  ProcedureReturn Bool(SoundStarted <> 0)
EndProcedure

Procedure TurnOffSound()
  SoundStarted = 0
EndProcedure

Procedure.a AddMultiChannelSound(Sound, Channel)
  If AddElement(MultiChannelSounds()) = 0
    ProcedureReturn #False
  EndIf
  
  MultiChannelSounds()\Sound = Sound
  MultiChannelSounds()\Channel = Channel
  ProcedureReturn #True
EndProcedure

Procedure PlaySoundEffect(Sound.a, IsMultiChannel.a, Music.a = #False)
  If Not SoundStarted
    ProcedureReturn
  EndIf
  If Music
    PlaySound(Sound, #PB_Sound_Loop, VolumeMusic)
  Else
    If IsMultiChannel
      Protected NewChannel = PlaySound(Sound, #PB_Sound_MultiChannel, VolumeSoundEffects)
      AddMultiChannelSound(Sound, NewChannel)
    Else
      PlaySound(Sound, 0, VolumeSoundEffects)
    EndIf
    
  EndIf
EndProcedure

Procedure StopSoundEffect(Sound.a)
  If Not SoundStarted
    ProcedureReturn
  EndIf
  
  StopSound(Sound)
  
EndProcedure

Procedure PauseSoundEffect(Sound.a)
  If Not SoundStarted
    ProcedureReturn
  EndIf
  
  PauseSound(Sound)
  
EndProcedure

Procedure ResumeSoundEffect(Sound.a)
  If Not SoundStarted
    ProcedureReturn
  EndIf
  
  ResumeSound(Sound)
  
EndProcedure

Procedure UpdateMultiChannelSounds()
  ForEach MultiChannelSounds()
    Protected Status = SoundStatus(MultiChannelSounds()\Sound, MultiChannelSounds()\Channel)
    If Status = #PB_Sound_Stopped
      StopSound(MultiChannelSounds()\Sound, MultiChannelSounds()\Channel)
      DeleteElement(MultiChannelSounds())
    EndIf
  Next
EndProcedure

Procedure UpdateSound()
  UpdateMultiChannelSounds()
EndProcedure
  

DisableExplicit
