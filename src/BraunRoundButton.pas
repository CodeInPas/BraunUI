unit BraunRoundButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  // PERBAIKAN: Menambahkan deklarasi TBraunControlState
  TBraunControlState = (bcsNormal, bcsHover, bcsPressed, bcsDisabled);

  TBraunRoundButton = class(TGraphicControl)
  private
    FState: TBraunControlState;
    FThemeColor: TBraunThemeColor;
    procedure SetThemeColor(const Value: TBraunThemeColor);
    procedure UpdateState(NewState: TBraunControlState);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure EnabledChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeColor: TBraunThemeColor read FThemeColor write SetThemeColor default btcSilver;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunRoundButton }

constructor TBraunRoundButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;
  Width := 60;
  Height := 60;
  FState := bcsNormal;
  FThemeColor := btcSilver;
end;

procedure TBraunRoundButton.SetThemeColor(const Value: TBraunThemeColor);
begin
  if FThemeColor = Value then Exit;
  FThemeColor := Value;
  Invalidate;
end;

procedure TBraunRoundButton.UpdateState(NewState: TBraunControlState);
begin
  if not Enabled then NewState := bcsDisabled;
  if FState = NewState then Exit;
  FState := NewState;
  Invalidate;
end;

procedure TBraunRoundButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
    UpdateState(bcsPressed);
end;

procedure TBraunRoundButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  // Periksa apakah kursor masih berada di dalam area tombol saat dilepas
  if (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
    UpdateState(bcsHover)
  else
    UpdateState(bcsNormal);
end;

procedure TBraunRoundButton.MouseEnter;
begin
  inherited MouseEnter;
  if Enabled and (FState <> bcsPressed) then
    UpdateState(bcsHover);
end;

procedure TBraunRoundButton.MouseLeave;
begin
  inherited MouseLeave;
  if Enabled then
    UpdateState(bcsNormal);
end;

procedure TBraunRoundButton.EnabledChanged;
begin
  inherited EnabledChanged;
  if Enabled then
    UpdateState(bcsNormal)
  else
    UpdateState(bcsDisabled);
end;

procedure TBraunRoundButton.Paint;
var
  Bmp: TBGRABitmap;
  CX, CY, Radius, InnerRadius: Single;
  BaseColor: TBGRAPixel;
  GradBezel, GradOverlay: TBGRAGradientScanner;
  BezelTop, BezelBottom: TBGRAPixel;
  OverlayTop, OverlayBottom: TBGRAPixel;
  PressOffset: Single;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    Radius := Min(Width, Height) * 0.5 - 4; // Margin untuk bayangan
    InnerRadius := Radius - (Radius * 0.15); // Proporsi ring luar

    PressOffset := 0;
    if FState = bcsPressed then PressOffset := 1.5;

    // 1. Gambar Bayangan Luar (Drop Shadow statis untuk efisiensi)
    if FState <> bcsPressed then
      Bmp.FillEllipseAntialias(CX, CY + 3, Radius, Radius, BGRA(0, 0, 0, 40));

    // 2. Gambar Bezel Luar (Ring Metal/Plastik)
    BezelTop := clrBraunPlasticHighlight;
    BezelBottom := clrBraunPlasticShadow;
    GradBezel := TBGRAGradientScanner.Create(BezelTop, BezelBottom, gtLinear,
                                             PointF(0, 0), PointF(0, Height));
    try
      Bmp.FillEllipseAntialias(CX, CY + PressOffset, Radius, Radius, GradBezel);
    finally
      GradBezel.Free;
    end;

    // 3. Gambar Batas Dalam (Inner Ring Shadow)
    Bmp.FillEllipseAntialias(CX, CY + PressOffset, InnerRadius + 1, InnerRadius + 1, BGRA(150, 150, 150, 255));

    // 4. Gambar Dasar Tombol Dalam (Solid Fill)
    BaseColor := GetBraunThemeColor(FThemeColor, FState <> bcsDisabled);

    // Sedikit gelapkan warna dasar jika sedang di-hover
    if FState = bcsHover then
      BaseColor := BGRA(Max(0, BaseColor.red - 20),
                        Max(0, BaseColor.green - 20),
                        Max(0, BaseColor.blue - 20), 255);

    Bmp.FillEllipseAntialias(CX, CY + PressOffset, InnerRadius, InnerRadius, BaseColor);

    // 5. Gambar Efek 3D pada Tombol Dalam (Overlay Gradient)
    // Menggunakan alpha blending dari putih ke hitam untuk menciptakan efek cahaya tanpa merusak warna dasar
    if FState = bcsPressed then
    begin
      // Cekung (Deboss) saat ditekan
      OverlayTop := BGRA(0, 0, 0, 100);
      OverlayBottom := BGRA(255, 255, 255, 30);
    end
    else
    begin
      // Cembung (Emboss) saat normal
      OverlayTop := BGRA(255, 255, 255, 120);
      OverlayBottom := BGRA(0, 0, 0, 60);
    end;

    GradOverlay := TBGRAGradientScanner.Create(OverlayTop, OverlayBottom, gtLinear,
                                               PointF(0, CY - InnerRadius),
                                               PointF(0, CY + InnerRadius));
    try
      Bmp.FillEllipseAntialias(CX, CY + PressOffset, InnerRadius, InnerRadius, GradOverlay);
    finally
      GradOverlay.Free;
    end;

    // Render bitmap ke Canvas kontrol (mendukung transparency)
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
