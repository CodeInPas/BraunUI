unit BraunRockerSwitch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunRockerSwitch = class(TGraphicControl)
  private
    FIsOn: Boolean;
    FThemeColor: TBraunThemeColor;
    FOnChange: TNotifyEvent;
    procedure SetIsOn(const Value: Boolean);
    procedure SetThemeColor(const Value: TBraunThemeColor);
  protected
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property ThemeColor: TBraunThemeColor read FThemeColor write SetThemeColor default btcOrange;
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

{ TBraunRockerSwitch }

constructor TBraunRockerSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Dihapus csOpaque agar Form menggambar latar belakang terlebih dahulu
  ControlStyle := ControlStyle + [csDoubleClicks];
  Width := 50;
  Height := 70;
  FIsOn := False;
  FThemeColor := btcOrange;
end;

procedure TBraunRockerSwitch.SetIsOn(const Value: Boolean);
begin
  if FIsOn = Value then Exit;
  FIsOn := Value;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBraunRockerSwitch.SetThemeColor(const Value: TBraunThemeColor);
begin
  if FThemeColor = Value then Exit;
  FThemeColor := Value;
  Invalidate;
end;

procedure TBraunRockerSwitch.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
    IsOn := not FIsOn;
end;

procedure TBraunRockerSwitch.Paint;
var
  Bmp, BezelBmp, RockerBmp: TBGRABitmap;
  RectBase, RectRocker: TRect;
  BaseColor, BrightC, DarkC: TBGRAPixel;
  GradHighlight, GradShadow, GradRocker: TBGRAGradientScanner;
  Radius, RidgeY: Single;
  RWidth, RHeight: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Membuat Base Bitmap dalam kondisi benar-benar transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    RectBase := Rect(0, 0, Width, Height);
    InflateRect(RectBase, -4, -6); // Margin untuk drop shadow
    Radius := 4.0;

    // 1. Gambar Housing/Bezel Luar di bitmap terpisah yang transparan
    BezelBmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    try
      DrawBraunPlasticSurface(BezelBmp, RectBase, Radius, False);
      DrawBraunDropShadow(Bmp, BezelBmp, 2, 4, 5.0, 80);
      Bmp.BlendImage(0, 0, BezelBmp, boLinearBlend);
    finally
      BezelBmp.Free;
    end;

    // 2. Kalkulasi Area Tuas Rocker (Lebih kecil dari bezel, menciptakan celah)
    RectRocker := RectBase;
    InflateRect(RectRocker, -4, -4);

    // Bayangan dalam (Inner Shadow) untuk lubang bezel
    Bmp.FillRoundRectAntialias(RectRocker.Left - 1, RectRocker.Top - 1,
                               RectRocker.Right + 1, RectRocker.Bottom + 1,
                               Radius - 1, Radius - 1, BGRA(20, 20, 20, 220));

    // 3. Kalkulasi Warna Translusen/Glossy
    BaseColor := GetBraunThemeColor(FThemeColor, Enabled);
    BrightC := BGRA(Min(255, BaseColor.red + 100), Min(255, BaseColor.green + 100), Min(255, BaseColor.blue + 100), 255);
    DarkC := BGRA(Max(0, BaseColor.red - 80), Max(0, BaseColor.green - 80), Max(0, BaseColor.blue - 80), 255);

    RWidth := RectRocker.Right - RectRocker.Left;
    RHeight := RectRocker.Bottom - RectRocker.Top;

    RockerBmp := TBGRABitmap.Create(RWidth, RHeight, BGRAPixelTransparent);
    try
      // Warna dasar switch berdasarkan posisi
      if FIsOn then
        GradRocker := TBGRAGradientScanner.Create(BaseColor, DarkC, gtLinear, PointF(0, 0), PointF(0, RHeight))
      else
        GradRocker := TBGRAGradientScanner.Create(DarkC, BaseColor, gtLinear, PointF(0, 0), PointF(0, RHeight));

      try
        RockerBmp.FillRoundRectAntialias(0, 0, RWidth, RHeight, 2, 2, GradRocker);
      finally
        GradRocker.Free;
      end;

      if FIsOn then
      begin
        // Posisi ON: Tekan atas, ridge di 1/4 bagian atas
        RidgeY := RHeight * 0.25;

        // Highlight kaca di bagian atas
        GradHighlight := TBGRAGradientScanner.Create(BGRA(255, 255, 255, 200), BGRA(255, 255, 255, 0), gtLinear, PointF(0, 0), PointF(0, RidgeY));
        try
          RockerBmp.FillRect(1, 1, RWidth - 1, Round(RidgeY), GradHighlight, dmDrawWithTransparency);
        finally
          GradHighlight.Free;
        end;

        // Garis lekukan (Ridge)
        RockerBmp.DrawLineAntialias(0, RidgeY, RWidth, RidgeY, BGRA(0, 0, 0, 100), 1.0);
        RockerBmp.DrawLineAntialias(0, RidgeY + 1, RWidth, RidgeY + 1, BrightC, 1.0);
      end
      else
      begin
        // Posisi OFF: Tekan bawah, ridge di 3/4 bagian bawah
        RidgeY := RHeight * 0.75;

        // Shadow ekstra di bagian atas
        GradShadow := TBGRAGradientScanner.Create(BGRA(0, 0, 0, 0), BGRA(0, 0, 0, 120), gtLinear, PointF(0, 0), PointF(0, RidgeY));
        try
          RockerBmp.FillRect(1, 1, RWidth - 1, Round(RidgeY), GradShadow, dmDrawWithTransparency);
        finally
          GradShadow.Free;
        end;

        // Highlight kaca di bagian bawah
        GradHighlight := TBGRAGradientScanner.Create(BrightC, BGRA(255, 255, 255, 0), gtLinear, PointF(0, RHeight), PointF(0, RidgeY));
        try
          RockerBmp.FillRect(1, Round(RidgeY), RWidth - 1, RHeight - 1, GradHighlight, dmDrawWithTransparency);
        finally
          GradHighlight.Free;
        end;

        // Garis lekukan (Ridge)
        RockerBmp.DrawLineAntialias(0, RidgeY - 1, RWidth, RidgeY - 1, BGRA(0, 0, 0, 100), 1.0);
        RockerBmp.DrawLineAntialias(0, RidgeY, RWidth, RidgeY, BGRA(255, 255, 255, 100), 1.0);
      end;

      // Inner stroke putih transparan (efek glossy tepi plastik)
      RockerBmp.RoundRect(1, 1, RWidth - 2, RHeight - 2, 2, 2, BGRA(255, 255, 255, 90), BGRA(0, 0, 0, 0));
      // Outer border gelap tipis untuk menegaskan batas
      RockerBmp.RoundRect(0, 0, RWidth - 1, RHeight - 1, 2, 2, BGRA(0, 0, 0, 120), BGRA(0, 0, 0, 0));

      // Bersihkan sudut yang bocor (karena radius kecil)
      RockerBmp.SetPixel(0, 0, BGRA(0, 0, 0, 0));
      RockerBmp.SetPixel(RWidth - 1, 0, BGRA(0, 0, 0, 0));
      RockerBmp.SetPixel(0, RHeight - 1, BGRA(0, 0, 0, 0));
      RockerBmp.SetPixel(RWidth - 1, RHeight - 1, BGRA(0, 0, 0, 0));

      // Gabungkan tuas ke kanvas utama
      Bmp.BlendImage(RectRocker.Left, RectRocker.Top, RockerBmp, boLinearBlend);
    finally
      RockerBmp.Free;
    end;

    // Menggambar Bmp final ke Canvas komponen dengan Opaque = False
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
