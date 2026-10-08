unit BraunUIReg;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  BraunLEDIndicator,
  BraunRoundButton,
  BraunToggleSwitch,
  BraunSlideSwitch,
  BraunRockerSwitch,
  BraunFader,
  BraunRotaryKnob,
  BraunRotarySelector,
  BraunGauge,
  Braungrillepanel,
  BraunLatchingButton,
  BraunLCDDisplay,
  BraunThemeManager,
  BraunSquareButtonGroup;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Braun UI', [
    TBraunLEDIndicator,
    TBraunRoundButton,
    TBraunToggleSwitch,
    TBraunSlideSwitch,
    TBraunRockerSwitch,
    TBraunFader,
    TBraunRotaryKnob,
    TBraunRotarySelector,
    TBraunGauge,
    TBraunLatchingButton,
    TBraunLCDDisplay,
    TBraunThemeManager,
    TBraunSquareButtonGroup
  ]);
end;

end.

