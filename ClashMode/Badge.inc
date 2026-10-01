[Metadata]
Name=ClashBadge
Author=local
Information=Clash mode badge. Sizes are integer pixels in each skin file.
Version=1.5

[MeasureClash]
Measure=WebParser
URL=http://127.0.0.1:9097/configs
Header=Authorization: Bearer change-me
ProxyServer=/none
Flags=ForceReload
RegExp=(?siU)"mode"\s*:\s*"([^"]*)"
StringIndex=1
UpdateRate=1
ErrorString=Offline
FinishAction=[!UpdateMeasure MeasureText][!UpdateMeter *][!Redraw]

[MeasureText]
Measure=String
String=[MeasureClash]
DynamicVariables=1
RegExpSubstitute=1
Substitute="(?i)^global$":"Global","(?i)^rule$":"Rule","(?i)^direct$":"Direct","^$":"Offline"
IfMatch=Global
IfMatchAction=[!SetVariable NextMode direct][!SetOption MeterBg RightGrad "270 | 52,208,88,255 ; 0.0 | 40,167,69,255 ; 1.0"][!UpdateMeter MeterBg][!Redraw]
IfMatch2=Direct
IfMatchAction2=[!SetVariable NextMode global][!SetOption MeterBg RightGrad "270 | 158,158,158,255 ; 0.0 | 122,122,122,255 ; 1.0"][!UpdateMeter MeterBg][!Redraw]
IfMatch3=Rule
IfMatchAction3=[!SetVariable NextMode direct][!SetOption MeterBg RightGrad "270 | 0,146,218,255 ; 0.0 | 0,100,160,255 ; 1.0"][!UpdateMeter MeterBg][!Redraw]
IfMatch4=Offline
IfMatchAction4=[!SetVariable NextMode direct][!SetOption MeterBg RightGrad "270 | 130,130,130,255 ; 0.0 | 96,96,96,255 ; 1.0"][!UpdateMeter MeterBg][!Redraw]

[MeterModeGauge]
Meter=String
Text=Global
FontFace=#FontFace#
FontSize=#Font#
FontWeight=#FontWeight#
FontColor=0,0,0,0
AntiAlias=1
X=([MeterLabel:X]+[MeterLabel:W]+#Gap#)
Y=#LabelY#
DynamicVariables=1

[MeterBg]
Meter=Shape
DynamicVariables=1
Shape=Rectangle 0,0,([MeterLabel:X]+[MeterLabel:W]+#Gap#+[MeterModeGauge:W]+#Pad#),#H#,#R# | Fill LinearGradient RightGrad | StrokeWidth 0
Shape2=Rectangle 0,0,([MeterLabel:X]+[MeterLabel:W]+#Pad#),#H#,#R# | Fill LinearGradient LeftGrad | StrokeWidth 0
Shape3=Rectangle ([MeterLabel:X]+[MeterLabel:W]+#Seam#),0,#SeamW#,#H# | Fill LinearGradient LeftGrad | StrokeWidth 0
LeftGrad=270 | 68,77,86,255 ; 0.0 | 36,41,46,255 ; 1.0
RightGrad=270 | 52,208,88,255 ; 0.0 | 40,167,69,255 ; 1.0

[MeterIcon]
Meter=Image
ImageName=#@#mark.png
X=#IconX#
Y=#IconY#
W=#Icon#
H=#Icon#
AntiAlias=1
PreserveAspectRatio=1
DynamicVariables=1

[MeterLabelShadow]
Meter=String
Text=Clash
FontFace=#FontFace#
FontSize=#Font#
FontWeight=#FontWeight#
FontColor=1,1,1,77
X=#LabelX#
Y=#ShadowY#
AntiAlias=1
DynamicVariables=1

[MeterLabel]
Meter=String
Text=Clash
FontFace=#FontFace#
FontSize=#Font#
FontWeight=#FontWeight#
FontColor=255,255,255,255
X=#LabelX#
Y=#LabelY#
AntiAlias=1
DynamicVariables=1

[MeterModeShadow]
Meter=String
MeasureName=MeasureText
Text=%1
FontFace=#FontFace#
FontSize=#Font#
FontWeight=#FontWeight#
FontColor=1,1,1,77
StringAlign=Center
X=([MeterLabel:X]+[MeterLabel:W]+#Gap#+([MeterModeGauge:W]/2))
Y=#ShadowY#
AntiAlias=1
DynamicVariables=1

[MeterMode]
Meter=String
MeasureName=MeasureText
Text=%1
FontFace=#FontFace#
FontSize=#Font#
FontWeight=#FontWeight#
FontColor=255,255,255,255
StringAlign=Center
X=([MeterLabel:X]+[MeterLabel:W]+#Gap#+([MeterModeGauge:W]/2))
Y=#LabelY#
AntiAlias=1
DynamicVariables=1
