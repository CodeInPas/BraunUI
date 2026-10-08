{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit braunui;

{$warn 5023 off : no warning about unused units}
interface

uses
  BraunUIReg, BraunUIUtils, BraunLEDIndicator, BraunRoundButton, 
  BraunToggleSwitch, BraunSlideSwitch, BraunRockerSwitch, BraunFader, 
  BraunRotaryKnob, BraunRotarySelector, BraunGauge, BraunSquareButtonGroup, 
  BraunLCDDisplay, BraunLatchingButton, BraunThemeManager, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('BraunUIReg', @BraunUIReg.Register);
end;

initialization
  RegisterPackage('braunui', @Register);
end.
