unit BraunSquareButtonGroup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunSquareButtonGroup = class(TCustomControl)
  private
    FButtonCount: Integer;
    FItemIndex: Integer;
    FDownIndex: Integer;
    FOnChange: TNotifyEvent;

    procedure SetButtonCount(const Value: Integer);
    procedure SetItemIndex(const Value: Integer);
    function GetButtonRect(AIndex: Integer): TRect;
    function GetIndexAtPoint(X, Y: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ButtonCount: Integer read FButtonCount write SetButtonCount default 4;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default 1;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ TBraunSquareButtonGroup }

constructor TBraunSquareButtonGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  Width := 240;
  Height := 60;
  FButtonCount := 4;
  FItemIndex := 1;
  FDownIndex := -1;
end;

procedure TBraunSquareButtonGroup.SetButtonCount(const Value: Integer);
begin
  if (FButtonCount = Value) or (Value < 1) then Exit;
  FButtonCount := Value;
  if FItemIndex >= FButtonCount then FItemIndex := FButtonCount - 1;
  Invalidate;
end;

procedure TBraunSquareButtonGroup.SetItemIndex(const Value: Integer);
begin
  if (FItemIndex = Value) or (Value < -1) or (Value >= FButtonCount) then Exit;
  FItemIndex := Value;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TBraunSquareButtonGroup.GetButtonRect(AIndex: Integer): TRect;
var
  BtnWidth: Single;
begin
  if FButtonCount < 1 then Exit(Rect(0, 0, 0, 0));
  BtnWidth := Width / FButtonCount;
  Result.Left := Round(AIndex * BtnWidth);
  Result.Top := 0;
  Result.Right := Round((AIndex + 1) * BtnWidth);
  Result.Bottom := Height;
end;

function TBraunSquareButtonGroup.GetIndexAtPoint(X, Y: Integer): Integer;
var
  BtnWidth: Single;
begin
  if (X < 0) or (X > Width) or (Y < 0) or (Y > Height) then Exit(-1);
  if FButtonCount < 1 then Exit(-1);

  BtnWidth := Width / FButtonCount;
  Result := Math.Floor(X / BtnWidth);
  if Result >= FButtonCount then Result := FButtonCount - 1;
end;

procedure TBraunSquareButtonGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAtPoint(X, Y);
    Invalidate;
  end;
end;

procedure TBraunSquareButtonGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    UpIndex := GetIndexAtPoint(X, Y);
    if (FDownIndex = UpIndex) and (UpIndex <> -1) then
      ItemIndex := UpIndex;

    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBraunSquareButtonGroup.MouseLeave;
begin
  inherited MouseLeave;
  if FDownIndex <> -1 then
  begin
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBraunSquareButtonGroup.Paint;
var
  Bmp: TBGRABitmap;
  i: Integer;
  BtnRect: TRect;
  CX, CY, DentRadius, DotRadius: Single;
  GradOuter, GradDent: TBGRAGradientScanner;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    // 1. Gambar Base Frame / Panel Luar
    GradOuter := TBGRAGradientScanner.Create(clrBraunPlasticShadow, clrBraunPlasticHighlight, gtLinear,
                                             PointF(0, 0), PointF(0, Height));
    try
      Bmp.FillRoundRectAntialias(0, 0, Width, Height, 4, 4, GradOuter);
    finally
      GradOuter.Free;
    end;

    Bmp.FillRoundRectAntialias(1, 1, Width - 1, Height - 1, 3, 3, clrBraunPlasticBody);

    // PERBAIKAN: Mengganti DrawRoundRectAntialias (yang tidak didukung) dengan RoundRect standar
    // Argumen terakhir digunakan untuk warna tepi/outline (PenColor) dan warna isi (BrushColor) yang transparan
    Bmp.RoundRect(1, 1, Width - 1, Height - 1, 3, 3, BGRA(0, 0, 0, 40), BGRA(0, 0, 0, 0));

    // 2. Iterasi untuk menggambar setiap tombol
    for i := 0 to FButtonCount - 1 do
    begin
      BtnRect := GetButtonRect(i);

      // Garis pemisah antar tombol
      if i > 0 then
      begin
        Bmp.DrawLineAntialias(BtnRect.Left, 2, BtnRect.Left, Height - 2, BGRA(0, 0, 0, 40), 1.0);
        Bmp.DrawLineAntialias(BtnRect.Left + 1, 2, BtnRect.Left + 1, Height - 2, clrBraunPlasticHighlight, 1.0);
      end;

      CX := BtnRect.Left + (BtnRect.Right - BtnRect.Left) * 0.5;
      CY := BtnRect.Top + (BtnRect.Bottom - BtnRect.Top) * 0.5;
      DentRadius := Min(BtnRect.Right - BtnRect.Left, BtnRect.Bottom - BtnRect.Top) * 0.38;

      // 3. Efek Cekungan Bola (Spherical Dent)
      // Jika tombol sedang ditekan, bayangan sedikit lebih gelap
      if i = FDownIndex then
        GradDent := TBGRAGradientScanner.Create(BGRA(150, 150, 150, 255), clrBraunPlasticHighlight, gtLinear,
                                                PointF(CX - DentRadius, CY - DentRadius),
                                                PointF(CX + DentRadius, CY + DentRadius))
      else
        GradDent := TBGRAGradientScanner.Create(BGRA(190, 190, 190, 255), clrBraunPlasticHighlight, gtLinear,
                                                PointF(CX - DentRadius, CY - DentRadius),
                                                PointF(CX + DentRadius, CY + DentRadius));
      try
        // Batas transisi halus cekungan
        Bmp.FillEllipseAntialias(CX, CY, DentRadius + 1, DentRadius + 1, BGRA(0, 0, 0, 15));
        Bmp.FillEllipseAntialias(CX, CY, DentRadius, DentRadius, GradDent);
      finally
        GradDent.Free;
      end;

      // 4. Indikator Tombol Aktif (Red Dot)
      if i = FItemIndex then
      begin
        DotRadius := DentRadius * 0.25;
        // Bayangan dot
        Bmp.FillEllipseAntialias(CX, CY + 1, DotRadius, DotRadius, BGRA(0, 0, 0, 100));
        // Base warna merah
        Bmp.FillEllipseAntialias(CX, CY, DotRadius, DotRadius, GetBraunThemeColor(btcRed, Enabled));
        // Highlight pada dot
        Bmp.FillEllipseAntialias(CX - (DotRadius * 0.2), CY - (DotRadius * 0.2),
                                 DotRadius * 0.3, DotRadius * 0.3, BGRA(255, 255, 255, 180));
      end;
    end;

    // Render ke kanvas kontrol
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
