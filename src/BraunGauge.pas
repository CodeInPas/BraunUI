unit BraunGauge;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types, LCLIntf,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunGauge = class(TCustomControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FIsDragging: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetMin(const Value: Integer);
    procedure SetMax(const Value: Integer);
    procedure SetPosition(const Value: Integer);

    function GetCenter: TPointF;
    function GetRadius: Single;
    function AngleToPosition(AAngle: Single): Integer;
    function PositionToAngle: Single;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Min: Integer read FMin write SetMin default 10;
    property Max: Integer read FMax write SetMax default 30;
    property Position: Integer read FPosition write SetPosition default 10;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property Font;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunGauge }

constructor TBraunGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 120;
  Height := 120;
  FMin := 10;
  FMax := 30;
  FPosition := 10;
  FIsDragging := False;
end;

procedure TBraunGauge.SetMin(const Value: Integer);
begin
  if FMin = Value then Exit;
  FMin := Value;
  if FMin > FMax then FMax := FMin;
  if FPosition < FMin then Position := FMin else Invalidate;
end;

procedure TBraunGauge.SetMax(const Value: Integer);
begin
  if FMax = Value then Exit;
  FMax := Value;
  if FMax < FMin then FMin := FMax;
  if FPosition > FMax then Position := FMax else Invalidate;
end;

procedure TBraunGauge.SetPosition(const Value: Integer);
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

function TBraunGauge.GetCenter: TPointF;
begin
  Result.X := Width - 20;
  Result.Y := Height - 20;
end;

function TBraunGauge.GetRadius: Single;
begin
  Result := Math.Min(Width, Height) - 40;
end;

function TBraunGauge.PositionToAngle: Single;
begin
  if FMax <= FMin then Exit(180.0);
  Result := 180.0 + ((FPosition - FMin) / (FMax - FMin)) * 90.0;
end;

function TBraunGauge.AngleToPosition(AAngle: Single): Integer;
var
  Ratio: Single;
begin
  if FMax <= FMin then Exit(FMin);

  if AAngle < 180.0 then AAngle := 180.0;
  if AAngle > 270.0 then AAngle := 270.0;

  Ratio := (AAngle - 180.0) / 90.0;
  Result := Round(FMin + Ratio * (FMax - FMin));
  Result := EnsureRange(Result, FMin, FMax);
end;

procedure TBraunGauge.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    MouseMove(Shift, X, Y);
  end;
end;

procedure TBraunGauge.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  C: TPointF;
  Angle: Single;
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
  begin
    C := GetCenter;
    Angle := ArcTan2(Y - C.Y, X - C.X) * 180.0 / PI;
    if Angle < 0 then Angle := Angle + 360.0;

    if Angle < 90 then Angle := 270
    else if Angle < 180 then Angle := 180;

    Position := AngleToPosition(Angle);
  end;
end;

procedure TBraunGauge.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FIsDragging := False;
end;

procedure TBraunGauge.MouseLeave;
begin
  inherited MouseLeave;
  FIsDragging := False;
end;

procedure TBraunGauge.Paint;
var
  Bmp: TBGRABitmap;
  C: TPointF;
  R, ThumbAngle, AngleRad: Single;
  TrackThickness: Single;
  i, TickCount, TickVal: Integer;
  TickAngleRad, TX, TY: Single;
  ThumbCX, ThumbCY: Single;

  Pts: array of TPointF;
  j, NumPts: Integer;
  a: Single;

  ThumbHalfW, ThumbHalfH: Single;
  CosA, SinA: Single;
  PolyShadow, PolyBase, PolyInner: array of TPointF;

  // PERBAIKAN: Fungsi lokal harus dideklarasikan di sini, SEBELUM "begin" utama prosedur Paint
  procedure CalcRotatedRect(CX, CY, HW, HH: Single; OffsetX, OffsetY: Single; var OutPoly: array of TPointF);
  begin
    OutPoly[0].X := CX + (-HW * CosA - (-HH) * SinA) + OffsetX;
    OutPoly[0].Y := CY + (-HW * SinA + (-HH) * CosA) + OffsetY;
    OutPoly[1].X := CX + (HW * CosA - (-HH) * SinA) + OffsetX;
    OutPoly[1].Y := CY + (HW * SinA + (-HH) * CosA) + OffsetY;
    OutPoly[2].X := CX + (HW * CosA - HH * SinA) + OffsetX;
    OutPoly[2].Y := CY + (HW * SinA + HH * CosA) + OffsetY;
    OutPoly[3].X := CX + (-HW * CosA - HH * SinA) + OffsetX;
    OutPoly[3].Y := CY + (-HW * SinA + HH * CosA) + OffsetY;
  end;

begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    C := GetCenter;
    R := GetRadius;
    TrackThickness := 6.0;

    // 1. Gambar Jalur Lengkung
    NumPts := 45;
    SetLength(Pts, NumPts + 1);

    for j := 0 to NumPts do
    begin
      a := (180.0 + (j / NumPts) * 90.0) * PI / 180.0;
      Pts[j].X := C.X + cos(a) * R;
      Pts[j].Y := C.Y + sin(a) * R;
    end;

    Bmp.DrawPolyLineAntialias(Pts, clrBraunDarkBase, TrackThickness);

    for j := 0 to NumPts do
    begin
      Pts[j].X := Pts[j].X + 1.0;
      Pts[j].Y := Pts[j].Y + 1.0;
    end;
    Bmp.DrawPolyLineAntialias(Pts, clrBraunPlasticHighlight, TrackThickness * 0.3);

    // 2. Gambar Skala Angka & Ticks
    Bmp.FontHeight := Abs(Font.Height);
    if Bmp.FontHeight = 0 then Bmp.FontHeight := 10;
    Bmp.FontName := Font.Name;
    Bmp.FontStyle := Font.Style;
    Bmp.FontAntialias := True;

    TickCount := 2;
    for i := 0 to TickCount do
    begin
      TickVal := FMin + Round((FMax - FMin) * (i / TickCount));
      TickAngleRad := (180.0 + (i / TickCount) * 90.0) * PI / 180.0;

      TX := C.X + cos(TickAngleRad) * (R + 18);
      TY := C.Y + sin(TickAngleRad) * (R + 18);

      Bmp.TextOut(Round(TX), Round(TY - (Bmp.FontHeight div 2)), IntToStr(TickVal), clrBraunTextDark, taCenter);
    end;

    // 3. Kalkulasi dan Gambar Thumb (Tombol Tuas) yang Berotasi
    ThumbAngle := PositionToAngle;
    AngleRad := ThumbAngle * PI / 180.0;

    ThumbCX := C.X + cos(AngleRad) * R;
    ThumbCY := C.Y + sin(AngleRad) * R;

    ThumbHalfW := 12.0;
    ThumbHalfH := 5.0;

    CosA := cos(AngleRad - PI/2);
    SinA := sin(AngleRad - PI/2);

    SetLength(PolyShadow, 4);
    SetLength(PolyBase, 4);
    SetLength(PolyInner, 4);

    // A. Bayangan (Drop shadow manual dengan polygon bergeser +2, +3)
    CalcRotatedRect(ThumbCX, ThumbCY, ThumbHalfW, ThumbHalfH, 2, 3, PolyShadow);
    Bmp.FillPolyAntialias(PolyShadow, BGRA(0, 0, 0, 100));

    // B. Base Base Gelap (Outline/Housing)
    CalcRotatedRect(ThumbCX, ThumbCY, ThumbHalfW, ThumbHalfH, 0, 0, PolyBase);
    Bmp.FillPolyAntialias(PolyBase, clrBraunDarkBase);

    // C. Inner Grip Terang (Silver inner)
    CalcRotatedRect(ThumbCX, ThumbCY, ThumbHalfW - 1.5, ThumbHalfH - 1.5, 0, 0, PolyInner);
    Bmp.FillPolyAntialias(PolyInner, clrBraunPlasticHighlight);

    // D. Tambahan Garis Highlight di tengah inner grip (memanjang searah track)
    Bmp.DrawLineAntialias(
      ThumbCX - (ThumbHalfW - 3) * CosA, ThumbCY - (ThumbHalfW - 3) * SinA,
      ThumbCX + (ThumbHalfW - 3) * CosA, ThumbCY + (ThumbHalfW - 3) * SinA,
      BGRA(255,255,255,200), 1.0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
