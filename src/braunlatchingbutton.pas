unit BraunLatchingButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunLatchingButton = class(TGraphicControl)
  private
    FIsPressed: Boolean;
    FThemeColor: TBraunThemeColor;
    FOnChange: TNotifyEvent;

    procedure SetIsPressed(const Value: Boolean);
    procedure SetThemeColor(const Value: TBraunThemeColor);
  protected
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsPressed: Boolean read FIsPressed write SetIsPressed default False;
    // PERBAIKAN: Mengganti btcBlack menjadi btcOrange agar dikenali oleh BraunUIUtils
    property ThemeColor: TBraunThemeColor read FThemeColor write SetThemeColor default btcOrange;

    property Align;
    property Anchors;
    property BorderSpacing;
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

{ TBraunLatchingButton }

constructor TBraunLatchingButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Dihapus csOpaque agar latar belakang selalu transparan
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 46;
  Height := 46;
  FIsPressed := False;
  // PERBAIKAN: Mengganti inisialisasi awal ke btcOrange
  FThemeColor := btcOrange;
end;

procedure TBraunLatchingButton.SetIsPressed(const Value: Boolean);
begin
  if FIsPressed = Value then Exit;
  FIsPressed := Value;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBraunLatchingButton.SetThemeColor(const Value: TBraunThemeColor);
begin
  if FThemeColor = Value then Exit;
  FThemeColor := Value;
  Invalidate;
end;

procedure TBraunLatchingButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  // Toggle status saat diklik di dalam area komponen
  if (Button = mbLeft) and (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
  begin
    IsPressed := not FIsPressed;
  end;
end;

procedure TBraunLatchingButton.Paint;
var
  Bmp, PlungerBmp: TBGRABitmap;
  CX, CY, BezelRad, HoleRad, PlungerRad: Single;
  GradBezel, GradPlunger: TBGRAGradientScanner;
  BaseC, BrightC, DarkC: TBGRAPixel;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    BezelRad := Min(Width, Height) * 0.5 - 2;
    HoleRad := BezelRad * 0.85;
    PlungerRad := HoleRad - 1.5; // Beri sedikit celah/gap mekanis

    // 1. Gambar Dudukan Luar (Outer Bezel / Casing)
    GradBezel := TBGRAGradientScanner.Create(clrBraunPlasticHighlight, clrBraunPlasticShadow, gtLinear,
                                             PointF(CX - BezelRad, CY - BezelRad),
                                             PointF(CX + BezelRad, CY + BezelRad));
    try
      Bmp.FillEllipseAntialias(CX, CY, BezelRad, BezelRad, GradBezel);
    finally
      GradBezel.Free;
    end;

    // 2. Gambar Lubang Dudukan (Hole Background)
    // Warna dasar gelap untuk menstimulasikan rongga di dalam casing
    Bmp.FillEllipseAntialias(CX, CY, HoleRad, HoleRad, clrBraunDarkBase);

    // Inner shadow di dalam lubang dudukan (Tepi kiri-atas gelap, kanan-bawah terang)
    Bmp.EllipseAntialias(CX, CY, HoleRad, HoleRad, BGRA(0, 0, 0, 150), 1.5);
    Bmp.EllipseAntialias(CX + 1, CY + 1, HoleRad, HoleRad, BGRA(255, 255, 255, 100), 1.0);

    // 3. Persiapkan Warna Plunger (Tombol yang bergerak)
    BaseC := GetBraunThemeColor(FThemeColor, Enabled);

    // 4. Kalkulasi & Gambar Plunger berdasarkan State
    PlungerBmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    try
      if not FIsPressed then
      begin
        // STATUS: NAIK (UNPRESSED)
        BrightC := BGRA(Min(255, BaseC.red + 40), Min(255, BaseC.green + 40), Min(255, BaseC.blue + 40), 255);
        DarkC := BGRA(Max(0, BaseC.red - 40), Max(0, BaseC.green - 40), Max(0, BaseC.blue - 40), 255);

        GradPlunger := TBGRAGradientScanner.Create(BrightC, DarkC, gtLinear,
                                                   PointF(CX - PlungerRad, CY - PlungerRad),
                                                   PointF(CX + PlungerRad, CY + PlungerRad));
        try
          PlungerBmp.FillEllipseAntialias(CX, CY, PlungerRad, PlungerRad, GradPlunger);
        finally
          GradPlunger.Free;
        end;

        // Highlight keras di tepi kiri atas tombol
        PlungerBmp.EllipseAntialias(CX - 0.5, CY - 0.5, PlungerRad, PlungerRad, BGRA(255, 255, 255, 90), 1.0);

        // Drop shadow jatuh dari tombol ke dalam lubang casing
        DrawBraunDropShadow(Bmp, PlungerBmp, 1, 2, 3, 130);
        Bmp.BlendImage(0, 0, PlungerBmp, boLinearBlend);
      end
      else
      begin
        // STATUS: MASUK/TERKUNCI (PRESSED)
        // Warna tombol sedikit lebih gelap karena berada di bawah bayangan
        BrightC := BGRA(Max(0, BaseC.red - 20), Max(0, BaseC.green - 20), Max(0, BaseC.blue - 20), 255);
        DarkC := BGRA(Max(0, BaseC.red - 80), Max(0, BaseC.green - 80), Max(0, BaseC.blue - 80), 255);

        // Gradasi dibalik (cahaya dari bawah) untuk memberi ilusi cekung/datar di dalam lubang
        GradPlunger := TBGRAGradientScanner.Create(DarkC, BrightC, gtLinear,
                                                   PointF(CX - PlungerRad, CY - PlungerRad),
                                                   PointF(CX + PlungerRad, CY + PlungerRad));
        try
          // Radius dikurangi sedikit (0.5px) untuk ilusi bahwa benda menjauh/turun
          PlungerBmp.FillEllipseAntialias(CX, CY, PlungerRad - 0.5, PlungerRad - 0.5, GradPlunger);
        finally
          GradPlunger.Free;
        end;

        Bmp.BlendImage(0, 0, PlungerBmp, boLinearBlend);

        // Inner shadow kuat yang dijatuhkan dari casing ke atas permukaan tombol
        Bmp.EllipseAntialias(CX, CY, PlungerRad - 0.5, PlungerRad - 0.5, BGRA(0, 0, 0, 180), 2.0);
        Bmp.EllipseAntialias(CX - 1, CY - 1, PlungerRad - 0.5, PlungerRad - 0.5, BGRA(0, 0, 0, 100), 1.0);
      end;
    finally
      PlungerBmp.Free;
    end;

    // Render ke Form
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
