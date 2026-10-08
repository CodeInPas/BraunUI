unit BraunLedIndcator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunLEDIndicator = class(TGraphicControl)
  private
    FIsOn: Boolean;
    FThemeColor: TBraunThemeColor;
    procedure SetIsOn(const Value: Boolean);
    procedure SetThemeColor(const Value: TBraunThemeColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property ThemeColor: TBraunThemeColor read FThemeColor write SetThemeColor default btcRed;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseDown;
    property OnMouseUp;
  end;

implementation

{ TBraunLEDIndicator }

constructor TBraunLEDIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Pastikan csOpaque tidak diaktifkan agar transparan sempurna
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 24;
  Height := 24;
  FIsOn := False;
  FThemeColor := btcRed;
end;

procedure TBraunLEDIndicator.SetIsOn(const Value: Boolean);
begin
  if FIsOn = Value then Exit;
  FIsOn := Value;
  Invalidate;
end;

procedure TBraunLEDIndicator.SetThemeColor(const Value: TBraunThemeColor);
begin
  if FThemeColor = Value then Exit;
  FThemeColor := Value;
  Invalidate;
end;

procedure TBraunLEDIndicator.Paint;
var
  Bmp: TBGRABitmap;
  CX, CY, LEDRadius: Single;
  BaseC, BrightC, DarkC: TBGRAPixel;
  GradDome, GradGlow: TBGRAGradientScanner;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Bitmap utama murni transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;

    // Radius LED dibuat lebih kecil (sekitar 35% dari ukuran) untuk memberi ruang pada efek Glow
    LEDRadius := Min(Width, Height) * 0.35;

    // Ambil warna dasar berdasarkan tema
    BaseC := GetBraunThemeColor(FThemeColor, Enabled);

    // 1. Gambar Efek Glow (Pendaran Cahaya) jika LED Menyala
    if FIsOn and Enabled then
    begin
      // Gradasi radial dari warna solid (transparan parsial) ke sepenuhnya transparan
      GradGlow := TBGRAGradientScanner.Create(BGRA(BaseC.red, BaseC.green, BaseC.blue, 180),
                                              BGRA(BaseC.red, BaseC.green, BaseC.blue, 0),
                                              gtRadial,
                                              PointF(CX, CY), PointF(CX + LEDRadius * 1.8, CY + LEDRadius * 1.8));
      try
        Bmp.FillEllipseAntialias(CX, CY, LEDRadius * 2.0, LEDRadius * 2.0, GradGlow);
      finally
        GradGlow.Free;
      end;
    end;

    // 2. Kalkulasi Warna Kubah Kaca (Glass Dome)
    if FIsOn and Enabled then
    begin
      // Saat menyala: Inti (kiri atas) sangat terang mendekati putih, tepi luar warna dasar
      BrightC := BGRA(Min(255, BaseC.red + 180), Min(255, BaseC.green + 180), Min(255, BaseC.blue + 180), 255);
      DarkC := BaseC;
    end
    else
    begin
      // Saat mati: Inti warna dasar, tepi luar sangat gelap
      if Enabled then
      begin
        BrightC := BGRA(Max(0, BaseC.red - 30), Max(0, BaseC.green - 30), Max(0, BaseC.blue - 30), 255);
        DarkC := BGRA(Max(0, BaseC.red - 150), Max(0, BaseC.green - 150), Max(0, BaseC.blue - 150), 255);
      end
      else
      begin
        // Warna abu-abu redup jika Disabled
        BrightC := BGRA(120, 120, 120, 255);
        DarkC := BGRA(60, 60, 60, 255);
      end;
    end;

    // 3. Gambar Kubah Kaca LED
    // Gradasi radial digeser ke kiri atas (offset) untuk mensimulasikan arah datang cahaya
    GradDome := TBGRAGradientScanner.Create(BrightC, DarkC, gtRadial,
                                            PointF(CX - (LEDRadius * 0.3), CY - (LEDRadius * 0.3)),
                                            PointF(CX + LEDRadius, CY + LEDRadius));
    try
      Bmp.FillEllipseAntialias(CX, CY, LEDRadius, LEDRadius, GradDome);
    finally
      GradDome.Free;
    end;

    // Bezel/Garis batas gelap tipis di sekeliling LED agar terpisah tegas dari panel
    Bmp.EllipseAntialias(CX, CY, LEDRadius, LEDRadius, BGRA(0, 0, 0, 120), 1.0);

    // 4. Gambar Pantulan Cahaya (Specular Highlight) pada Kaca Cembung
    // Kita menggambar bentuk oval/elips pipih berwarna putih semi-transparan di area atas-kiri
    if Enabled then
    begin
      // Highlight besar, agak transparan
      Bmp.FillEllipseAntialias(CX - (LEDRadius * 0.25), CY - (LEDRadius * 0.35),
                               LEDRadius * 0.4, LEDRadius * 0.2, BGRA(255, 255, 255, 140));

      // Titik highlight inti yang lebih kecil dan tajam
      Bmp.FillEllipseAntialias(CX - (LEDRadius * 0.35), CY - (LEDRadius * 0.45),
                               LEDRadius * 0.15, LEDRadius * 0.1, BGRA(255, 255, 255, 220));
    end;

    // Render ke kanvas kontrol
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
