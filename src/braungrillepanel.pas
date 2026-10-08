unit Braungrillepanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics,
  BGRABitmap, BGRABitmapTypes, BraunUIUtils;

type
  TBraunGrillePanel = class(TCustomControl)
  private
    FDotSize: Integer;
    FSpacing: Integer;
    FGrilleMargin: Integer;
    procedure SetDotSize(const Value: Integer);
    procedure SetSpacing(const Value: Integer);
    procedure SetGrilleMargin(const Value: Integer);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DotSize: Integer read FDotSize write SetDotSize default 3;
    property Spacing: Integer read FSpacing write SetSpacing default 8;
    property GrilleMargin: Integer read FGrilleMargin write SetGrilleMargin default 12;
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Color;
    property Enabled;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnResize;
  end;

implementation

{ TBraunGrillePanel }

constructor TBraunGrillePanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // csAcceptsControls mengizinkan panel ini menampung komponen lain di dalamnya
  ControlStyle := ControlStyle + [csAcceptsControls, csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := False;
  Color := clDefault; // Jika default, akan menggunakan warna BraunPlasticBody
  Width := 200;
  Height := 150;
  FDotSize := 3;
  FSpacing := 8;
  FGrilleMargin := 12;
end;

procedure TBraunGrillePanel.SetDotSize(const Value: Integer);
begin
  if FDotSize = Value then Exit;
  FDotSize := Value;
  if FDotSize < 1 then FDotSize := 1;
  Invalidate;
end;

procedure TBraunGrillePanel.SetSpacing(const Value: Integer);
begin
  if FSpacing = Value then Exit;
  FSpacing := Value;
  if FSpacing < FDotSize + 2 then FSpacing := FDotSize + 2; // Hindari overlap berlebihan
  Invalidate;
end;

procedure TBraunGrillePanel.SetGrilleMargin(const Value: Integer);
begin
  if FGrilleMargin = Value then Exit;
  FGrilleMargin := Value;
  if FGrilleMargin < 0 then FGrilleMargin := 0;
  Invalidate;
end;

procedure TBraunGrillePanel.Paint;
var
  Bmp, TileBmp: TBGRABitmap;
  X, Y: Integer;
  Cols, Rows: Integer;
  StartX, StartY: Integer;
  Radius: Single;
  DrawArea: TRect;
  DotColor, HighlightColor: TBGRAPixel;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height);
  try
    // 1. Gambar Base Panel
    if Color = clDefault then
      Bmp.Fill(clrBraunPlasticBody)
    else
      Bmp.Fill(ColorToBGRA(ColorToRGB(Color)));

    // 2. Kalkulasi Area Grid
    DrawArea := Rect(FGrilleMargin, FGrilleMargin, Width - FGrilleMargin, Height - FGrilleMargin);

    if (DrawArea.Right > DrawArea.Left) and (DrawArea.Bottom > DrawArea.Top) and (FSpacing > 0) then
    begin
      Cols := (DrawArea.Right - DrawArea.Left) div FSpacing;
      Rows := (DrawArea.Bottom - DrawArea.Top) div FSpacing;

      // Kalkulasi titik awal agar grid otomatis berada persis di tengah panel (Centered)
      StartX := DrawArea.Left + ((DrawArea.Right - DrawArea.Left) - (Cols * FSpacing)) div 2;
      StartY := DrawArea.Top + ((DrawArea.Bottom - DrawArea.Top) - (Rows * FSpacing)) div 2;

      Radius := FDotSize * 0.5;
      DotColor := BGRA(15, 15, 15, 240); // Lubang sangat gelap
      HighlightColor := BGRA(255, 255, 255, 160); // Highlight untuk efek deboss/cekung

      // 3. Buat Master Tile (Ubin pola) untuk performa rendering yang sangat cepat
      TileBmp := TBGRABitmap.Create(FSpacing, FSpacing, BGRAPixelTransparent);
      try
        // Highlight putih di tepi bawah-kanan (Efek cahaya jatuh)
        TileBmp.FillEllipseAntialias((FSpacing * 0.5) + 0.5, (FSpacing * 0.5) + 1.0, Radius, Radius, HighlightColor);
        // Lubang utama (Hitam/Gelap)
        TileBmp.FillEllipseAntialias(FSpacing * 0.5, FSpacing * 0.5, Radius, Radius, DotColor);
        // Inner shadow tipis di lubang
        TileBmp.EllipseAntialias(FSpacing * 0.5, FSpacing * 0.5, Radius, Radius, BGRA(0, 0, 0, 100), 1.0);

        // 4. Stamping Tile ke Kanvas Utama secara berulang
        for Y := 0 to Rows do
        begin
          for X := 0 to Cols do
          begin
            Bmp.BlendImage(StartX + (X * FSpacing), StartY + (Y * FSpacing), TileBmp, boLinearBlend);
          end;
        end;
      finally
        TileBmp.Free;
      end;
    end;

    // 5. Render ke layar (False = menimpa sepenuhnya, karena ini adalah base panel)
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
