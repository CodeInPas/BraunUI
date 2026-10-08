unit BraunToggleSwitch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunToggleSwitch = class(TGraphicControl)
  private
    FIsOn: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetIsOn(const Value: Boolean);
  protected
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunToggleSwitch }

constructor TBraunToggleSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 30;
  Height := 60;
  FIsOn := False;
end;

procedure TBraunToggleSwitch.SetIsOn(const Value: Boolean);
begin
  if FIsOn = Value then Exit;
  FIsOn := Value;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBraunToggleSwitch.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
    IsOn := not FIsOn;
end;

procedure TBraunToggleSwitch.Paint;
var
  Bmp, LeverBmp: TBGRABitmap;
  CX, CY, NutRadius, LeverWidth, LeverLength: Single;
  GradBase, GradLever: TBGRAGradientScanner;
  LTop, LBottom, LLeft, LRight: Single;
  ShadowOffsetY: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Membuat Base Bitmap dalam kondisi benar-benar transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    NutRadius := Min(Width, Height) * 0.35;
    LeverWidth := NutRadius * 0.5;
    LeverLength := NutRadius * 2.0;

    // 1. Gambar Dudukan/Baut Metal (Nut Base)
    GradBase := TBGRAGradientScanner.Create(clrBraunPlasticHighlight, clrBraunPlasticShadow, gtLinear,
                                            PointF(CX - NutRadius, CY - NutRadius),
                                            PointF(CX + NutRadius, CY + NutRadius));
    try
      // Ring luar
      Bmp.FillEllipseAntialias(CX, CY, NutRadius, NutRadius, GradBase);
      // Lubang dalam (Pivot Hole)
      Bmp.FillEllipseAntialias(CX, CY, NutRadius * 0.7, NutRadius * 0.7, BGRA(30, 30, 30, 255));
    finally
      GradBase.Free;
    end;

    // 2. Gambar Tuas (Lever) pada bitmap terpisah agar bisa diberi bayangan
    // PERBAIKAN: Variabel yang di-create adalah LeverBmp
    LeverBmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    try
      LLeft := CX - (LeverWidth * 0.5);
      LRight := CX + (LeverWidth * 0.5);

      if FIsOn then
      begin
        LTop := CY - LeverLength;
        LBottom := CY;
        ShadowOffsetY := 2; // Bayangan jatuh ke bawah
      end
      else
      begin
        LTop := CY;
        LBottom := CY + LeverLength;
        ShadowOffsetY := -2; // Bayangan jatuh ke atas
      end;

      // Gradasi silinder untuk memberikan efek 3D pada tuas
      GradLever := TBGRAGradientScanner.Create(BGRA(90, 90, 90, 255), BGRA(15, 15, 15, 255), gtLinear,
                                               PointF(LLeft, 0), PointF(LRight, 0));
      try
        // Batang utama
        LeverBmp.FillRectAntialias(LLeft, LTop, LRight, LBottom, GradLever);

        // Ujung membulat tuas (Top/Bottom Caps)
        LeverBmp.FillEllipseAntialias(CX, LTop, LeverWidth * 0.5, LeverWidth * 0.5, GradLever);
        LeverBmp.FillEllipseAntialias(CX, LBottom, LeverWidth * 0.5, LeverWidth * 0.5, GradLever);
      finally
        GradLever.Free;
      end;

      // 3. Terapkan Bayangan Jatuh (Drop Shadow) dari Tuas ke Base
      DrawBraunDropShadow(Bmp, LeverBmp, 3, ShadowOffsetY, 3, 120);

      // 4. Gabungkan Tuas ke Canvas Utama
      Bmp.BlendImage(0, 0, LeverBmp, boLinearBlend);
    finally
      LeverBmp.Free;
    end;

    // Menggambar Bmp final ke Canvas komponen dengan Opaque = False
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
