unit BraunFader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunFaderThumbStyle = (bftsBlack, bftsSilver, bftsSilverRidged);

  TBraunFader = class(TCustomControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FThumbStyle: TBraunFaderThumbStyle;
    FIsDragging: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetMin(const Value: Integer);
    procedure SetMax(const Value: Integer);
    procedure SetPosition(const Value: Integer);
    procedure SetThumbStyle(const Value: TBraunFaderThumbStyle);

    function GetThumbHeight: Integer;
    function GetThumbWidth: Integer;
    function PositionToY: Integer;
    function YToPosition(Y: Integer): Integer;
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
    property ThumbStyle: TBraunFaderThumbStyle read FThumbStyle write SetThumbStyle default bftsSilver;
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

{ TBraunFader }

constructor TBraunFader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 60;
  Height := 160;
  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FThumbStyle := bftsSilver;
  FIsDragging := False;
end;

procedure TBraunFader.SetMin(const Value: Integer);
begin
  if FMin = Value then Exit;
  FMin := Value;
  if FMin > FMax then FMax := FMin;
  if FPosition < FMin then Position := FMin else Invalidate;
end;

procedure TBraunFader.SetMax(const Value: Integer);
begin
  if FMax = Value then Exit;
  FMax := Value;
  if FMax < FMin then FMin := FMax;
  if FPosition > FMax then Position := FMax else Invalidate;
end;

procedure TBraunFader.SetPosition(const Value: Integer);
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

procedure TBraunFader.SetThumbStyle(const Value: TBraunFaderThumbStyle);
begin
  if FThumbStyle = Value then Exit;
  FThumbStyle := Value;
  Invalidate;
end;

function TBraunFader.GetThumbHeight: Integer;
begin
  Result := 16;
end;

function TBraunFader.GetThumbWidth: Integer;
begin
  Result := 28;
end;

function TBraunFader.PositionToY: Integer;
var
  TrackH: Integer;
begin
  if FMax <= FMin then Exit(Height div 2);
  TrackH := Height - GetThumbHeight - 20;
  Result := 10 + (GetThumbHeight div 2) + Round((1.0 - ((FPosition - FMin) / (FMax - FMin))) * TrackH);
end;

function TBraunFader.YToPosition(Y: Integer): Integer;
var
  TrackH: Integer;
  PosRatio: Double;
begin
  TrackH := Height - GetThumbHeight - 20;
  if TrackH <= 0 then Exit(FMin);

  PosRatio := 1.0 - ((Y - 10 - (GetThumbHeight div 2)) / TrackH);
  Result := FMin + Round(PosRatio * (FMax - FMin));
  Result := EnsureRange(Result, FMin, FMax);
end;

procedure TBraunFader.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    Position := YToPosition(Y);
  end;
end;

procedure TBraunFader.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
    Position := YToPosition(Y);
end;

procedure TBraunFader.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FIsDragging := False;
end;

procedure TBraunFader.MouseLeave;
begin
  inherited MouseLeave;
  FIsDragging := False;
end;

procedure TBraunFader.Paint;
var
  Bmp, ThumbBmp: TBGRABitmap;
  TrackX, ThumbY, i, TickY: Integer;
  TrackTop, TrackBottom: Integer;
  GradThumb: TBGRAGradientScanner;
  TickCount, TickVal, TxtX: Integer;
  TxtStr: String;
  ColorTop, ColorBottom, TxtColor: TBGRAPixel;
  RidgeY: Single;
  Margin: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    TrackX := Width - 24;
    TrackTop := 10 + (GetThumbHeight div 2);
    TrackBottom := Height - 10 - (GetThumbHeight div 2);
    ThumbY := PositionToY;

    // 1. Gambar Skala dan Angka
    Bmp.FontHeight := Abs(Font.Height);
    if Bmp.FontHeight = 0 then Bmp.FontHeight := 10;
    Bmp.FontName := Font.Name;
    Bmp.FontStyle := Font.Style;
    Bmp.FontAntialias := True;

    if Enabled then TxtColor := BGRA(150, 150, 150, 255) else TxtColor := BGRA(200, 200, 200, 255);

    TickCount := 4; // Jumlah jeda utama (5 angka total)
    for i := 0 to TickCount do
    begin
      TickVal := FMin + Round((FMax - FMin) * (i / TickCount));
      TickY := TrackBottom - Round((i / TickCount) * (TrackBottom - TrackTop));

      Bmp.DrawLineAntialias(TrackX - 8, TickY, TrackX - 3, TickY, TxtColor, 1.0);

      TxtStr := IntToStr(TickVal);
      TxtX := TrackX - 12 - Bmp.TextSize(TxtStr).cx;
      Bmp.TextOut(TxtX, TickY - (Bmp.FontHeight div 2), TxtStr, TxtColor);
    end;

    for i := 0 to (TickCount * 2) - 1 do
    begin
      if (i mod 2) <> 0 then
      begin
        TickY := TrackBottom - Round((i / (TickCount * 2)) * (TrackBottom - TrackTop));
        Bmp.DrawLineAntialias(TrackX - 5, TickY, TrackX - 3, TickY, TxtColor, 1.0);
      end;
    end;

    // 2. Gambar Slot / Track
    Bmp.DrawLineAntialias(TrackX - 1, TrackTop - 4, TrackX - 1, TrackBottom + 4, clrBraunDarkBase, 2.0);
    Bmp.DrawLineAntialias(TrackX + 1, TrackTop - 4, TrackX + 1, TrackBottom + 4, clrBraunPlasticHighlight, 1.0);

    // 3. Gambar Thumb (Tombol Geser Silinder)
    // PERBAIKAN: Memberi Margin luas di sekitar tombol agar drop shadow tidak terpotong (kotak hitam)
    Margin := 8;
    ThumbBmp := TBGRABitmap.Create(GetThumbWidth + (Margin * 2), GetThumbHeight + (Margin * 2), BGRAPixelTransparent);
    try
      if FThumbStyle = bftsBlack then
      begin
        ColorTop := BGRA(90, 90, 90, 255);
        ColorBottom := clrBraunDarkBase;
      end
      else
      begin
        ColorTop := clrBraunPlasticHighlight;
        ColorBottom := BGRA(180, 180, 180, 255);
      end;

      GradThumb := TBGRAGradientScanner.Create(ColorTop, ColorBottom, gtLinear, PointF(Margin, Margin), PointF(Margin, Margin + GetThumbHeight));
      try
        ThumbBmp.FillRoundRectAntialias(Margin, Margin, Margin + GetThumbWidth, Margin + GetThumbHeight, 2, 2, GradThumb);
      finally
        GradThumb.Free;
      end;

      if FThumbStyle = bftsBlack then
        ThumbBmp.RoundRect(Margin, Margin, Margin + GetThumbWidth - 1, Margin + GetThumbHeight - 1, 2, 2, BGRA(0, 0, 0, 180), BGRA(0, 0, 0, 0))
      else
        ThumbBmp.RoundRect(Margin, Margin, Margin + GetThumbWidth - 1, Margin + GetThumbHeight - 1, 2, 2, BGRA(0, 0, 0, 60), BGRA(0, 0, 0, 0));

      if FThumbStyle = bftsSilverRidged then
      begin
        for i := 1 to 3 do
        begin
          RidgeY := Margin + (GetThumbHeight / 4) * i;
          ThumbBmp.DrawLineAntialias(Margin + 2, RidgeY, Margin + GetThumbWidth - 2, RidgeY, BGRA(0, 0, 0, 40), 1.0);
          ThumbBmp.DrawLineAntialias(Margin + 2, RidgeY + 1, Margin + GetThumbWidth - 2, RidgeY + 1, clrBraunPlasticHighlight, 1.0);
        end;
      end
      else
      begin
        if FThumbStyle = bftsBlack then
          ThumbBmp.DrawLineAntialias(Margin + 1, Margin + GetThumbHeight * 0.4, Margin + GetThumbWidth - 1, Margin + GetThumbHeight * 0.4, BGRA(255, 255, 255, 60), 1.5)
        else
          ThumbBmp.DrawLineAntialias(Margin + 1, Margin + GetThumbHeight * 0.4, Margin + GetThumbWidth - 1, Margin + GetThumbHeight * 0.4, BGRA(255, 255, 255, 200), 2.0);
      end;

      // 4. Tambahkan Drop Shadow
      DrawBraunDropShadow(Bmp, ThumbBmp, 0, 3, 5, 120);

      // PERBAIKAN: Sesuaikan koordinat BlendImage karena ThumbBmp kini memiliki Margin
      Bmp.BlendImage(TrackX - (GetThumbWidth div 2) - Margin, ThumbY - (GetThumbHeight div 2) - Margin, ThumbBmp, boLinearBlend);
    finally
      ThumbBmp.Free;
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
