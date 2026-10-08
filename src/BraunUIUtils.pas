unit BraunUIUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Graphics,
  BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TBraunThemeColor = (btcRed, btcOrange, btcGreen, btcBlue, btcBlack, btcWhite, btcSilver);

  // Tipe tema baru untuk Global Theme Manager
  TBraunThemeStyle = (btsClassicLight, btsStudioDark, btsSilverAluminum);

var
  // Variabel Global Palet Warna (Bisa berubah saat runtime)
  clrBraunPlasticBody: TBGRAPixel;
  clrBraunPlasticHighlight: TBGRAPixel;
  clrBraunPlasticShadow: TBGRAPixel;
  clrBraunDarkBase: TBGRAPixel;
  clrBraunTextDark: TBGRAPixel;

// Deklarasi fungsi & prosedur global
function GetBraunThemeColor(AThemeColor: TBraunThemeColor; AEnabled: Boolean = True): TBGRAPixel;
procedure ApplyBraunTheme(ATheme: TBraunThemeStyle);

// Deklarasi utilitas visual
procedure DrawBraunDropShadow(ADest, ASrc: TBGRABitmap; OffsetX, OffsetY: Integer; BlurRadius: Single; Alpha: Byte);
procedure DrawBraunPlasticSurface(Bmp: TBGRABitmap; ARect: TRect; Radius: Single; IsDark: Boolean = False);

implementation

// 1. Fungsi Mengambil Warna Aksen (LED, Tuas, Indikator)
function GetBraunThemeColor(AThemeColor: TBraunThemeColor; AEnabled: Boolean = True): TBGRAPixel;
begin
  if not AEnabled then Exit(BGRA(150, 150, 150, 255));
  case AThemeColor of
    btcRed:    Result := BGRA(220, 50, 40, 255);
    btcOrange: Result := BGRA(240, 110, 20, 255);
    btcGreen:  Result := BGRA(40, 180, 80, 255);
    btcBlue:   Result := BGRA(30, 120, 210, 255);
    btcBlack:  Result := BGRA(40, 40, 40, 255);
    btcWhite:  Result := BGRA(240, 240, 240, 255);
    btcSilver: Result := BGRA(180, 180, 185, 255);
    else       Result := clrBraunDarkBase;
  end;
end;

// 2. Prosedur Menerapkan Tema Utama (Light/Dark/Aluminum)
procedure ApplyBraunTheme(ATheme: TBraunThemeStyle);
begin
  case ATheme of
    btsClassicLight:
    begin
      clrBraunPlasticBody := BGRA(235, 235, 230, 255); // Off-white (Putih gading tulang)
      clrBraunPlasticHighlight := BGRA(255, 255, 255, 255);
      clrBraunPlasticShadow := BGRA(190, 190, 185, 255);
      clrBraunDarkBase := BGRA(30, 30, 30, 255);
      clrBraunTextDark := BGRA(20, 20, 20, 255);
    end;
    btsStudioDark:
    begin
      clrBraunPlasticBody := BGRA(45, 45, 48, 255); // Hitam Doff / Dark Grey
      clrBraunPlasticHighlight := BGRA(75, 75, 80, 255);
      clrBraunPlasticShadow := BGRA(20, 20, 22, 255);
      clrBraunDarkBase := BGRA(10, 10, 10, 255);
      clrBraunTextDark := BGRA(230, 230, 230, 255); // Teks menjadi terang
    end;
    btsSilverAluminum:
    begin
      clrBraunPlasticBody := BGRA(200, 205, 210, 255); // Abu-abu metalik
      clrBraunPlasticHighlight := BGRA(245, 250, 255, 255);
      clrBraunPlasticShadow := BGRA(150, 155, 160, 255);
      clrBraunDarkBase := BGRA(40, 45, 50, 255);
      clrBraunTextDark := BGRA(30, 30, 35, 255);
    end;
  end;
end;

// 3. Utilitas Visual: Bayangan Jatuh (Drop Shadow)
procedure DrawBraunDropShadow(ADest, ASrc: TBGRABitmap; OffsetX, OffsetY: Integer; BlurRadius: Single; Alpha: Byte);
var
  Shadow, Blurred: TBGRABitmap;
  i: Integer;
  p: PBGRAPixel;
begin
  if (ADest = nil) or (ASrc = nil) then Exit;

  Shadow := ASrc.Duplicate as TBGRABitmap;
  p := Shadow.Data;
  for i := 0 to Shadow.NbPixels - 1 do
  begin
    p^.red := 0;
    p^.green := 0;
    p^.blue := 0;
    p^.alpha := (p^.alpha * Alpha) div 255;
    Inc(p);
  end;

  if BlurRadius > 0 then
  begin
    Blurred := Shadow.FilterBlurRadial(Round(BlurRadius), rbFast) as TBGRABitmap;
    ADest.BlendImage(OffsetX, OffsetY, Blurred, boLinearBlend);
    Blurred.Free;
  end
  else
    ADest.BlendImage(OffsetX, OffsetY, Shadow, boLinearBlend);

  Shadow.Free;
end;

// 4. Utilitas Visual: Permukaan Bodi Plastik melengkung
procedure DrawBraunPlasticSurface(Bmp: TBGRABitmap; ARect: TRect; Radius: Single; IsDark: Boolean = False);
var
  Grad: TBGRAGradientScanner;
  C1, C2, StrokeColor: TBGRAPixel;
begin
  if IsDark then
  begin
    C1 := clrBraunDarkBase;
    C2 := BGRA(10, 10, 10, 255);
    StrokeColor := BGRA(0, 0, 0, 150); // Garis tepi gelap
  end
  else
  begin
    C1 := clrBraunPlasticHighlight;
    C2 := clrBraunPlasticShadow;
    StrokeColor := BGRA(255, 255, 255, 100); // Garis tepi terang (glossy)
  end;

  // PERBAIKAN STACKING: Layer 1 (Warna Outline / Stroke penuh)
  Bmp.FillRoundRectAntialias(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom, Radius, Radius, StrokeColor);

  // PERBAIKAN STACKING: Layer 2 (Bodi Gradien utama).
  // Ukuran diperkecil (inset) +1 dan -1 pixel untuk mengekspos Layer 1 sebagai garis batas.
  Grad := TBGRAGradientScanner.Create(C1, C2, gtLinear, PointF(ARect.Left + 1, ARect.Top + 1), PointF(ARect.Right - 1, ARect.Bottom - 1));
  try
    Bmp.FillRoundRectAntialias(ARect.Left + 1, ARect.Top + 1, ARect.Right - 1, ARect.Bottom - 1, Radius - 1, Radius - 1, Grad);
  finally
    Grad.Free;
  end;
end;

// Inisialisasi otomatis
initialization
  ApplyBraunTheme(btsClassicLight);

end.
