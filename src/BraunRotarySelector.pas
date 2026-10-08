unit BraunRotarySelector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunRotarySelector = class(TCustomControl)
  private
    FItems: TStrings;
    FItemIndex: Integer;
    FIsDragging: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetItems(Value: TStrings);
    procedure SetItemIndex(Value: Integer);
    procedure ItemsChange(Sender: TObject);
    function AngleToIndex(Angle: Single): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TStrings read FItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default 0;
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

{ TBraunRotarySelector }

constructor TBraunRotarySelector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Pastikan csOpaque dihapus agar Lazarus menggambar background form/grid di bawahnya
  ControlStyle := ControlStyle + [csDoubleClicks] - [csOpaque];
  Width := 110;
  Height := 110;
  FItems := TStringList.Create;
  TStringList(FItems).OnChange := @ItemsChange;
  FItems.Add('UV');
  FItems.Add('0');
  FItems.Add('IR');
  FItemIndex := 1;
  FIsDragging := False;
end;

destructor TBraunRotarySelector.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TBraunRotarySelector.SetItems(Value: TStrings);
begin
  FItems.Assign(Value);
  Invalidate;
end;

procedure TBraunRotarySelector.ItemsChange(Sender: TObject);
begin
  if FItemIndex >= FItems.Count then
    FItemIndex := Max(0, FItems.Count - 1);
  Invalidate;
end;

procedure TBraunRotarySelector.SetItemIndex(Value: Integer);
begin
  if (Value >= 0) and (Value < FItems.Count) then
  begin
    if FItemIndex <> Value then
    begin
      FItemIndex := Value;
      Invalidate;
      if Assigned(FOnChange) then
        FOnChange(Self);
    end;
  end;
end;

function TBraunRotarySelector.AngleToIndex(Angle: Single): Integer;
var
  TotalSpread, AngleStep: Single;
begin
  if FItems.Count <= 1 then Exit(0);

  TotalSpread := 120.0;
  AngleStep := TotalSpread / (FItems.Count - 1);

  // Menyesuaikan sudut mulai (-60 derajat dari titik 0/atas)
  Result := Round((Angle + 60.0) / AngleStep);
  Result := EnsureRange(Result, 0, FItems.Count - 1);
end;

procedure TBraunRotarySelector.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    MouseMove(Shift, X, Y);
  end;
end;

procedure TBraunRotarySelector.MouseMove(Shift: TShiftState; X, Y: Integer);
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

    // Kalkulasi sudut 0 di posisi atas (Jam 12)
    Angle := ArcTan2(DX, -DY) * 180.0 / PI;

    // Wrap-around guard untuk mencegah loncatan nilai drastis
    if Angle > 100.0 then Angle := 60.0
    else if Angle < -100.0 then Angle := -60.0;

    ItemIndex := AngleToIndex(Angle);
  end;
end;

procedure TBraunRotarySelector.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FIsDragging := False;
end;

procedure TBraunRotarySelector.MouseLeave;
begin
  inherited MouseLeave;
  FIsDragging := False;
end;

procedure TBraunRotarySelector.Paint;
var
  Bmp, KnobBmp: TBGRABitmap;
  CX, CY, KnobRadius, LabelRadius: Single;
  TotalSpread, AngleStep, DrawAngle, AngleRad: Single;
  BarL, BarThickness: Single;
  X1, Y1, X2, Y2, NX, NY, IX1, IY1, IX2, IY2, IndStartL, IndEndL: Single;
  LX, LY: Single;
  i: Integer;
  GradTop: TBGRAGradientScanner;
  TxtColor: TBGRAPixel;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Membuat Base Bitmap dalam kondisi benar-benar transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CX := Width * 0.5;
    CY := Height * 0.5;
    KnobRadius := Min(Width, Height) * 0.5 - 22;

    // 1. Menggambar Teks Label (Indikator Posisi)
    if FItems.Count > 0 then
    begin
      Bmp.FontHeight := Abs(Font.Height);
      if Bmp.FontHeight = 0 then Bmp.FontHeight := 12;
      Bmp.FontName := Font.Name;
      Bmp.FontStyle := Font.Style;
      Bmp.FontAntialias := True;

      TotalSpread := 120.0;
      AngleStep := 0;
      if FItems.Count > 1 then
        AngleStep := TotalSpread / (FItems.Count - 1);

      LabelRadius := KnobRadius + 15;

      for i := 0 to FItems.Count - 1 do
      begin
        DrawAngle := -60.0 + (i * AngleStep);
        AngleRad := (DrawAngle - 90.0) * PI / 180.0;

        LX := CX + cos(AngleRad) * LabelRadius;
        LY := CY + sin(AngleRad) * LabelRadius;

        // Penyesuaian warna teks berdasar gambar referensi
        if (FItems[i] = 'UV') or (FItems[i] = 'IR') then
          TxtColor := GetBraunThemeColor(btcRed, Enabled)
        else
          TxtColor := clrBraunTextDark;

        if not Enabled then
          TxtColor := BGRA(150, 150, 150, 255);

        Bmp.TextOut(Round(LX), Round(LY - (Bmp.FontHeight div 2)), FItems[i], TxtColor, taCenter);
      end;
    end;

    // 2. Menggambar Body Kenop Utama
    KnobBmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    try
      // Base / Outer Bezel
      GradTop := TBGRAGradientScanner.Create(clrBraunPlasticHighlight, clrBraunPlasticShadow, gtLinear,
                                             PointF(CX - KnobRadius, CY - KnobRadius),
                                             PointF(CX + KnobRadius, CY + KnobRadius));
      try
        KnobBmp.FillEllipseAntialias(CX, CY, KnobRadius, KnobRadius, GradTop);
      finally
        GradTop.Free;
      end;

      // Menggambar Inner Shadow dan Base Lingkaran Dalam
      KnobBmp.FillEllipseAntialias(CX, CY, KnobRadius * 0.9, KnobRadius * 0.9, clrBraunPlasticBody);

      // Soft Inner Shadow berlapis untuk kedalaman yang realistis
      for i := 0 to 4 do
        KnobBmp.EllipseAntialias(CX, CY, KnobRadius * 0.9 - i, KnobRadius * 0.9 - i, BGRA(0, 0, 0, 60 - (i * 12)), 1.5);

      // Inner highlight di sisi pantulan
      KnobBmp.EllipseAntialias(CX, CY, KnobRadius * 0.9, KnobRadius * 0.9, BGRA(255, 255, 255, 100), 1.0);

      // 3. Kalkulasi dan Menggambar Bilah Tuas (Raised Bar melintang penuh simetris)
      TotalSpread := 120.0;
      AngleStep := 0;
      if FItems.Count > 1 then AngleStep := TotalSpread / (FItems.Count - 1);

      DrawAngle := -60.0 + (FItemIndex * AngleStep);
      AngleRad := (DrawAngle - 90.0) * PI / 180.0;

      BarL := KnobRadius * 0.98; // Menjangkau hampir ke tepi dalam bezel
      BarThickness := KnobRadius * 0.28; // Ketebalan tuas proporsional

      X1 := CX + cos(AngleRad + PI) * BarL; // Ujung bawah
      Y1 := CY + sin(AngleRad + PI) * BarL;
      X2 := CX + cos(AngleRad) * BarL;      // Ujung atas (penunjuk)
      Y2 := CY + sin(AngleRad) * BarL;

      // Drop shadow pada tuas
      KnobBmp.DrawLineAntialias(X1 + 2, Y1 + 3, X2 + 2, Y2 + 3, BGRA(0, 0, 0, 70), BarThickness);

      // Base plastik tuas
      KnobBmp.DrawLineAntialias(X1, Y1, X2, Y2, clrBraunPlasticBody, BarThickness);

      // Kalkulasi Normal Vector untuk efek Bevel
      NX := cos(AngleRad - PI/2);
      NY := sin(AngleRad - PI/2);

      // Highlight di sisi atas/kiri tuas
      KnobBmp.DrawLineAntialias(X1 + NX * (BarThickness * 0.35), Y1 + NY * (BarThickness * 0.35),
                                X2 + NX * (BarThickness * 0.35), Y2 + NY * (BarThickness * 0.35),
                                clrBraunPlasticHighlight, BarThickness * 0.3);

      // Bayangan di sisi bawah/kanan tuas
      KnobBmp.DrawLineAntialias(X1 - NX * (BarThickness * 0.35), Y1 - NY * (BarThickness * 0.35),
                                X2 - NX * (BarThickness * 0.35), Y2 - NY * (BarThickness * 0.35),
                                clrBraunPlasticShadow, BarThickness * 0.3);

      // Titik tengah / flat surface
      KnobBmp.DrawLineAntialias(X1, Y1, X2, Y2, BGRA(255, 255, 255, 180), BarThickness * 0.4);

      // 4. Indikator (Garis Cekung/Debossed Line)
      IndStartL := BarL * 0.50; // Dimulai dari tengah
      IndEndL := BarL * 0.85;   // Berakhir sebelum ujung

      IX1 := CX + cos(AngleRad) * IndStartL;
      IY1 := CY + sin(AngleRad) * IndStartL;
      IX2 := CX + cos(AngleRad) * IndEndL;
      IY2 := CY + sin(AngleRad) * IndEndL;

      // Garis gelap cekungan (Inner shadow)
      KnobBmp.DrawLineAntialias(IX1, IY1, IX2, IY2, clrBraunTextDark, BarThickness * 0.15);
      // Highlight garis cekungan untuk menegaskan efek deboss
      KnobBmp.DrawLineAntialias(IX1 + 1, IY1 + 1, IX2 + 1, IY2 + 1, BGRA(255, 255, 255, 180), BarThickness * 0.05);

      // 5. Menerapkan Bayangan ke Tuas dan Kenop, lalu gabungkan ke Bmp Utama
      DrawBraunDropShadow(Bmp, KnobBmp, 2, 3, 5, 100);
      Bmp.BlendImage(0, 0, KnobBmp, boLinearBlend);
    finally
      KnobBmp.Free;
    end;

    // Menggambar Bmp final ke Canvas komponen dengan Opaque = False
    // Hal ini akan memungkinkan alpha blending membaur dengan latar belakang Parent (form grid)
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
