unit BraunRotaryKnob;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types, LCLIntf,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunRotaryKnob = class(TCustomControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FIsDragging: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetMin(const Value: Integer);
    procedure SetMax(const Value: Integer);
    procedure SetPosition(const Value: Integer);

    function PositionToAngle: Single;
    function AngleToPosition(AAngle: Single): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 0;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunRotaryKnob }

constructor TBraunRotaryKnob.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Pastikan csOpaque tidak ada di ControlStyle
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 80;
  Height := 80;
  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FIsDragging := False;
end;

procedure TBraunRotaryKnob.SetMin(const Value: Integer);
begin
  if FMin = Value then Exit;
  FMin := Value;
  if FMin > FMax then FMax := FMin;
  if FPosition < FMin then Position := FMin else Invalidate;
end;

procedure TBraunRotaryKnob.SetMax(const Value: Integer);
begin
  if FMax = Value then Exit;
  FMax := Value;
  if FMax < FMin then FMin := FMax;
  if FPosition > FMax then Position := FMax else Invalidate;
end;

procedure TBraunRotaryKnob.SetPosition(const Value: Integer);
var
  NewPos: Integer;
begin
  NewPos := EnsureRange(Value, FMin, FMax);
  if FPosition = NewPos then Exit;
  FPosition := NewPos;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TBraunRotaryKnob.PositionToAngle: Single;
begin
  if FMax <= FMin then Exit(-135.0);
  // Sudut putar 270 derajat: dari -135 (Min) ke +135 (Max) dengan 0 di posisi atas (Jam 12)
  Result := -135.0 + ((FPosition - FMin) / (FMax - FMin)) * 270.0;
end;

function TBraunRotaryKnob.AngleToPosition(AAngle: Single): Integer;
begin
  if FMax <= FMin then Exit(FMin);
  Result := Round(FMin + ((AAngle + 135.0) / 270.0) * (FMax - FMin));
  Result := EnsureRange(Result, FMin, FMax);
end;

procedure TBraunRotaryKnob.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    MouseMove(Shift, X, Y);
  end;
end;

procedure TBraunRotaryKnob.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CX, CY, DX, DY, Angle: Single;
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
  begin
    CX := Width * 0.5;
    CY := Height * 0.5;
    DX := X - CX;
    DY := Y - CY;

    // Kalkulasi sudut berdasarkan kursor (0 derajat = arah atas)
    Angle := ArcTan2(DX, -DY) * 180.0 / PI;

    // Pembatasan sudut agar tidak melewati batas rotasi (Wrap-around guard)
    if Angle > 135.0 then
    begin
      if Angle > 160.0 then Angle := -135.0 else Angle := 135.0;
    end
    else if Angle < -135.0 then
    begin
      if Angle < -160.0 then Angle := 135.0 else Angle := -135.0;
    end;

    Position := AngleToPosition(Angle);
  end;
end;

procedure TBraunRotaryKnob.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FIsDragging := False;
end;

procedure TBraunRotaryKnob.MouseLeave;
begin
  inherited MouseLeave;
  FIsDragging := False;
end;

procedure TBraunRotaryKnob.Paint;
var
  Bmp, KnobBmp: TBGRABitmap;
  CX, CY, KnobRadius, IndRadius: Single;
  i: Integer;
  AngleRad, IndX, IndY: Single;
  GradTop: TBGRAGradientScanner;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Inisialisasi bitmap kanvas utama dengan transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    KnobRadius := Math.Min(Width, Height) * 0.5 - 6; // Radius luar kenop dikurangi margin shadow

    KnobBmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    try
      // 1. Gambar Tekstur Tepi bergerigi (Ribs/Grooves)
      for i := 0 to 71 do // 72 gerigi
      begin
        AngleRad := (i * 5) * PI / 180.0;
        IndX := CX + cos(AngleRad) * KnobRadius;
        IndY := CY + sin(AngleRad) * KnobRadius;
        KnobBmp.DrawLineAntialias(CX, CY, IndX, IndY, clrBraunPlasticShadow, 2.0);
        KnobBmp.DrawLineAntialias(CX, CY, IndX - 1, IndY - 1, clrBraunPlasticHighlight, 1.0);
      end;

      // 2. Gambar Permukaan Atas Kenop (Halus/Smooth) menutupi bagian tengah gerigi
      // Menggunakan radial gradient dari sumber cahaya di kiri-atas untuk efek cembung realistis
      GradTop := TBGRAGradientScanner.Create(clrBraunPlasticHighlight, BGRA(210, 210, 210, 255), gtRadial,
                                             PointF(CX - KnobRadius * 0.2, CY - KnobRadius * 0.2),
                                             PointF(CX + KnobRadius * 0.8, CY + KnobRadius * 0.8));
      try
        KnobBmp.FillEllipseAntialias(CX, CY, KnobRadius * 0.9, KnobRadius * 0.9, GradTop);
      finally
        GradTop.Free;
      end;

      // 3. Tambahkan inner bevel pada permukaan atas
      KnobBmp.EllipseAntialias(CX, CY, KnobRadius * 0.9, KnobRadius * 0.9, BGRA(0, 0, 0, 30), 1.0);

      // 4. Kalkulasi dan Gambar Indikator Titik (Dot Indicator)
      // Rotasi matematika standar (0 di kanan, berputar berlawanan jarum jam)
      // diubah menjadi (0 di atas, berputar searah jarum jam)
      AngleRad := (PositionToAngle - 90.0) * PI / 180.0;
      IndRadius := KnobRadius * 0.65;
      IndX := CX + cos(AngleRad) * IndRadius;
      IndY := CY + sin(AngleRad) * IndRadius;

      // Dasar titik indikator (gelap/lubang)
      KnobBmp.FillEllipseAntialias(IndX, IndY, KnobRadius * 0.1, KnobRadius * 0.1, clrBraunDarkBase);
      // Highlight pada titik untuk efek lekukan (emboss)
      KnobBmp.FillEllipseAntialias(IndX, IndY + 1, KnobRadius * 0.08, KnobRadius * 0.08, BGRA(0, 0, 0, 180));

      KnobBmp.EllipseAntialias(IndX, IndY, KnobRadius * 0.1, KnobRadius * 0.1, BGRA(255, 255, 255, 100), 1.0);

      // 5. Terapkan efek Drop Shadow dari Kenop ke dasar
      DrawBraunDropShadow(Bmp, KnobBmp, 3, 4, 5.0, 120);

      // 6. Blend kenop ke canvas utama
      Bmp.BlendImage(0, 0, KnobBmp, boLinearBlend);
    finally
      KnobBmp.Free;
    end;

    // Render Bmp final ke Canvas komponen (dengan alpha blending menyatu ke Parent)
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
