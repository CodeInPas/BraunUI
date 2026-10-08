unit BraunSlideSwitch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, LCLIntf, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner, BraunUIUtils;

type
  TBraunSlideSwitch = class(TGraphicControl)
  private
    FIsOn: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetIsOn(const Value: Boolean);
  protected
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsOn: Boolean read FIsOn write SetIsOn default False;
    property Align;
    property Anchors;
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

{ TBraunSlideSwitch }

constructor TBraunSlideSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;
  Width := 60;
  Height := 30;
  FIsOn := False;
end;

procedure TBraunSlideSwitch.SetIsOn(const Value: Boolean);
begin
  if FIsOn = Value then Exit;
  FIsOn := Value;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TBraunSlideSwitch.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
    IsOn := not FIsOn;
end;

procedure TBraunSlideSwitch.Paint;
var
  Bmp, ThumbBmp: TBGRABitmap;
  TrackRect, ThumbRect: TRect;
  TrackRadius, ThumbRadius: Single;
  GradTrack: TBGRAGradientScanner;
  ThumbX, ThumbW: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    // 1. Kalkulasi Track (Jalur geser)
    TrackRect := Rect(0, 0, Width, Height);
    InflateRect(TrackRect, -2, -4); // Margin aman untuk bayangan (InflateRect kini dikenali karena unit Types & LCLIntf ditambahkan)
    TrackRadius := (TrackRect.Bottom - TrackRect.Top) * 0.5;

    // Gradient Track untuk efek celah/lekukan gelap (Inner Shadow Simulation)
    GradTrack := TBGRAGradientScanner.Create(BGRA(20, 20, 20, 255), BGRA(80, 80, 80, 255), gtLinear,
                                             PointF(0, TrackRect.Top), PointF(0, TrackRect.Bottom));
    try
      Bmp.FillRoundRectAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Bottom,
                                 TrackRadius, TrackRadius, GradTrack);
    finally
      GradTrack.Free;
    end;

    // Highlight putih tipis di bagian bawah track untuk efek 3D lekukan
    // PERBAIKAN: BGRABitmap tidak memiliki DrawRoundRectAntialias secara default.
    // Menggunakan DrawLineAntialias untuk menggambar highlight di tepi bawah lurus (yang secara visual sudah sangat cukup untuk efek bevel).
    Bmp.DrawLineAntialias(TrackRect.Left + TrackRadius, TrackRect.Bottom + 1,
                          TrackRect.Right - TrackRadius, TrackRect.Bottom + 1,
                          clrBraunPlasticHighlight, 1.0);

    // 2. Kalkulasi dan Gambar Thumb (Tombol Geser)
    ThumbW := TrackRect.Bottom - TrackRect.Top; // Lebar thumb dibuat proporsional
    ThumbRadius := ThumbW * 0.5;

    ThumbBmp := TBGRABitmap.Create(Width, Height,BGRAPixelTransparent);
    try
      if FIsOn then
        ThumbX := TrackRect.Right - ThumbW
      else
        ThumbX := TrackRect.Left;

      ThumbRect := Rect(ThumbX, TrackRect.Top, ThumbX + ThumbW, TrackRect.Bottom);
      InflateRect(ThumbRect, 2, 2); // Buat thumb sedikit lebih menonjol keluar track

      // Gambar permukaan plastik Thumb menggunakan utilitas
      DrawBraunPlasticSurface(ThumbBmp, ThumbRect, ThumbRadius, False);

      // Gambar tekstur/grip pada Thumb
      ThumbBmp.DrawLineAntialias(ThumbRect.Left + ThumbRadius - 3, ThumbRect.Top + 5,
                                 ThumbRect.Left + ThumbRadius - 3, ThumbRect.Bottom - 5,
                                 BGRA(160, 160, 160, 255), 1.0);
      ThumbBmp.DrawLineAntialias(ThumbRect.Left + ThumbRadius + 3, ThumbRect.Top + 5,
                                 ThumbRect.Left + ThumbRadius + 3, ThumbRect.Bottom - 5,
                                 BGRA(160, 160, 160, 255), 1.0);

      // 3. Terapkan Drop Shadow pada Thumb ke Bmp utama
      DrawBraunDropShadow(Bmp, ThumbBmp, 2, 2, 3, 100);

      // 4. Blend Thumb ke kanvas utama
      Bmp.BlendImage(0, 0, ThumbBmp, boLinearBlend);
    finally
      ThumbBmp.Free;
    end;

    // Render ke komponen
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
