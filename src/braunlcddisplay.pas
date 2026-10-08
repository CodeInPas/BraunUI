unit BraunLCDDisplay;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunLCDTheme = (bltClassicGreen, bltNeutralGrey);

  TBraunLCDDisplay = class(TCustomControl)
  private
    FValueText: String;
    FAlignment: TAlignment;
    FLCDTheme: TBraunLCDTheme;

    procedure SetValueText(const Value: String);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetLCDTheme(const Value: TBraunLCDTheme);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ValueText: String read FValueText write SetValueText;
    property Alignment: TAlignment read FAlignment write SetAlignment default taRightJustify;
    property LCDTheme: TBraunLCDTheme read FLCDTheme write SetLCDTheme default bltClassicGreen;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Visible;
    property Font;

    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunLCDDisplay }

constructor TBraunLCDDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Dihapus csOpaque agar background form bisa di-render (transparan)
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];

  Width := 160;
  Height := 50;

  FValueText := '12345678';
  FAlignment := taRightJustify;
  FLCDTheme := bltClassicGreen;

  Font.Name := 'Arial';
  Font.Size := 20;
  Font.Style := [fsBold];
end;

procedure TBraunLCDDisplay.SetValueText(const Value: String);
begin
  if FValueText = Value then Exit;
  FValueText := Value;
  Invalidate;
end;

procedure TBraunLCDDisplay.SetAlignment(const Value: TAlignment);
begin
  if FAlignment = Value then Exit;
  FAlignment := Value;
  Invalidate;
end;

procedure TBraunLCDDisplay.SetLCDTheme(const Value: TBraunLCDTheme);
begin
  if FLCDTheme = Value then Exit;
  FLCDTheme := Value;
  Invalidate;
end;

procedure TBraunLCDDisplay.Paint;
var
  Bmp: TBGRABitmap;
  LCDColor, TextColor, ShadowC: TBGRAPixel;
  TextSize: TSize;
  TX, TY: Integer;
  GradGlass: TBGRAGradientScanner;
  CornerRad: Single;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Inisialisasi bitmap kanvas utama murni transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CornerRad := 4.0;

    // 1. Tentukan Palet Warna Layar
    if FLCDTheme = bltClassicGreen then
    begin
      LCDColor := BGRA(158, 171, 149, 255); // Hijau Zaitun khas Braun ET66
      TextColor := BGRA(35, 40, 35, 240);   // Hitam/Hijau sangat gelap
    end
    else
    begin
      LCDColor := BGRA(190, 195, 195, 255); // Abu-abu netral LCD modern
      TextColor := BGRA(30, 30, 30, 240);
    end;

    if not Enabled then
    begin
      LCDColor := BGRA(130, 130, 130, 255); // Redup jika disabled
      TextColor := BGRA(100, 100, 100, 150);
    end;

    // 2. Gambar Layar (Base Color) dengan efek cekung/cutout (Deboss)
    // Kita menumpuk 4 layer filled rectangle untuk membentuk border dan shadow tanpa memakai fungsi "outline"

    // Layer 1: Bevel Bawah-Kanan (Highlight pantulan cahaya tepi bawah bodi plastik)
    Bmp.FillRoundRectAntialias(1, 1, Width, Height, CornerRad, CornerRad, clrBraunPlasticHighlight);

    // Layer 2: Bevel Atas-Kiri (Inner shadow tajam yang mensimulasikan kedalaman lubang)
    Bmp.FillRoundRectAntialias(0, 0, Width - 1, Height - 1, CornerRad, CornerRad, clrBraunPlasticShadow);

    // Layer 3: Extra inner shadow agar transisi lebih mulus (Soft shadow)
    Bmp.FillRoundRectAntialias(1, 1, Width - 2, Height - 2, CornerRad - 1, CornerRad - 1, BGRA(0, 0, 0, 70));

    // Layer 4: Base Layar LCD Utama (Permukaan Kaca)
    Bmp.FillRoundRectAntialias(2, 2, Width - 3, Height - 3, CornerRad - 1, CornerRad - 1, LCDColor);

    // Tambahan shadow soft di bagian tepi atas kaca
    Bmp.DrawLineAntialias(2, 2, Width - 3, 2, BGRA(0, 0, 0, 40), 2.0);

    // 3. Render Teks LCD
    if FValueText <> '' then
    begin
      Bmp.FontHeight := Abs(Font.Height);
      if Bmp.FontHeight = 0 then Bmp.FontHeight := Height - 16;
      Bmp.FontName := Font.Name;
      Bmp.FontStyle := Font.Style;
      Bmp.FontAntialias := True;

      TextSize := Bmp.TextSize(FValueText);
      TY := (Height - TextSize.cy) div 2;

      case FAlignment of
        taLeftJustify: TX := 10;
        taRightJustify: TX := Width - TextSize.cx - 10;
        taCenter: TX := (Width - TextSize.cx) div 2;
      end;

      // Bayangan tipis pada teks LCD
      ShadowC := BGRA(LCDColor.red div 2, LCDColor.green div 2, LCDColor.blue div 2, 60);
      Bmp.TextOut(TX + 1, TY + 1, FValueText, ShadowC);

      // Teks Utama
      Bmp.TextOut(TX, TY, FValueText, TextColor);
    end;

    // 4. Lapisan Pantulan Kaca (Glass Reflection Overlay)
    GradGlass := TBGRAGradientScanner.Create(BGRA(255, 255, 255, 60), BGRA(255, 255, 255, 5), gtLinear,
                                             PointF(0, 0), PointF(0, Height * 0.5));
    try
      Bmp.FillRect(2, 2, Width - 3, Round(Height * 0.5), GradGlass, dmDrawWithTransparency);
      Bmp.DrawLineAntialias(2, Height * 0.5, Width - 3, Height * 0.5, BGRA(255, 255, 255, 20), 1.0);
    finally
      GradGlass.Free;
    end;

    // 5. Gambar ke Kanvas (dengan Alpha Blending)
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
