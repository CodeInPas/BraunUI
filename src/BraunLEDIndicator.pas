unit BraunLEDIndicator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
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
    property Visible;
  end;

implementation

{ TBraunLEDIndicator }

constructor TBraunLEDIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;
  Width := 20;
  Height := 20;
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
  CX, CY, Radius, GlowRadius: Single;
  ColorBase, ColorGlow: TBGRAPixel;
  Grad: TBGRAGradientScanner;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    // Menyisakan ruang untuk efek pendaran cahaya (glow)
    Radius := Min(Width, Height) * 0.25;

    // 1. Gambar lubang dudukan LED (Recessed bevel)
    Bmp.FillEllipseAntialias(CX, CY, Radius + 1, Radius + 1, clrBraunPlasticShadow);
    Bmp.FillEllipseAntialias(CX, CY, Radius, Radius, clrBraunDarkBase);

    if FIsOn then
    begin
      ColorBase := GetBraunThemeColor(FThemeColor, True);
      GlowRadius := Min(Width, Height) * 0.5;

      // 2. Gambar pendaran cahaya (Glow)
      ColorGlow := ColorBase;
      ColorGlow.alpha := 0; // Transparan di tepi

      Grad := TBGRAGradientScanner.Create(ColorBase, ColorGlow, gtRadial, PointF(CX, CY), PointF(CX + GlowRadius, CY));
      try
        Bmp.FillEllipseAntialias(CX, CY, GlowRadius, GlowRadius, Grad);
      finally
        Grad.Free;
      end;

      // 3. Gambar inti lampu yang menyala (Bright Center)
      Bmp.FillEllipseAntialias(CX, CY, Radius * 0.8, Radius * 0.8, ColorBase);

      // 4. Highlight putih untuk efek kaca/plastik memantul
      Bmp.FillEllipseAntialias(CX - (Radius * 0.25), CY - (Radius * 0.25),
                               Radius * 0.3, Radius * 0.3, BGRA(255, 255, 255, 200));
    end
    else
    begin
      // Jika Off, gunakan warna redup dan gambar refleksi kaca gelap
      ColorBase := GetBraunThemeColor(FThemeColor, False);
      Bmp.FillEllipseAntialias(CX, CY, Radius * 0.8, Radius * 0.8, ColorBase);
      Bmp.FillEllipseAntialias(CX - (Radius * 0.2), CY - (Radius * 0.2),
                               Radius * 0.2, Radius * 0.2, BGRA(255, 255, 255, 50));
    end;

    // Render ke kanvas kontrol
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

