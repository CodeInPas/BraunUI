unit BraunThemeManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics, BraunUIUtils; // PERBAIKAN: Menambahkan unit Graphics

type
  TBraunThemeManager = class(TComponent)
  private
    FTheme: TBraunThemeStyle;
    procedure SetTheme(const Value: TBraunThemeStyle);
    procedure RepaintAllControls(AWinControl: TWinControl);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Theme: TBraunThemeStyle read FTheme write SetTheme default btsClassicLight;
  end;

implementation

{ TBraunThemeManager }

constructor TBraunThemeManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTheme := btsClassicLight;
end;

// Fungsi rekursif untuk menyuruh SEMUA komponen di dalam Form menggambar ulang
procedure TBraunThemeManager.RepaintAllControls(AWinControl: TWinControl);
var
  i: Integer;
  Ctrl: TControl;
begin
  if AWinControl = nil then Exit;

  AWinControl.Invalidate;

  for i := 0 to AWinControl.ControlCount - 1 do
  begin
    Ctrl := AWinControl.Controls[i];
    Ctrl.Invalidate; // Paksa komponen menggambar ulang dengan warna baru

    // Jika komponen ini adalah kontainer (seperti TPanel atau TBraunGrillePanel),
    // masuk ke dalamnya dan update juga isinya
    if Ctrl is TWinControl then
      RepaintAllControls(TWinControl(Ctrl));
  end;
end;

procedure TBraunThemeManager.SetTheme(const Value: TBraunThemeStyle);
begin
  if FTheme = Value then Exit;
  FTheme := Value;

  // 1. Ubah variabel global di BraunUIUtils
  ApplyBraunTheme(FTheme);

  // 2. Beritahu Form (Owner) dan seluruh isinya untuk di-repaint seketika
  if (Owner <> nil) and (Owner is TCustomForm) then
  begin
    TCustomForm(Owner).Color := RGBToColor(clrBraunPlasticBody.red, clrBraunPlasticBody.green, clrBraunPlasticBody.blue);
    RepaintAllControls(TCustomForm(Owner));
  end;
end;

end.
