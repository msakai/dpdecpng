{
    PNG Decoder Add-in for D-Pixed version 1.00
    Copyright (C) 1999  Masahiro Sakai <ZVM01052@nifty.ne.jp>
}

{
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}

library dpdecpng;

uses
  Windows, SysUtils, Classes, dp_add;

type
  PPictureInfo = ^TPictureInfo;
  TPictureInfo = packed record
      Left: LongInt;
      Top: LongInt;
      Width: LongInt;
      Height: LongInt;
      x_density: WORD;
      y_density: WORD;
      ColorDepth: SmallInt;
      hInfo: THandle;
  end;

  TProgressCallBack = function(nNum, nDenom: Integer; lData: LongInt): LongBool; stdcall;

  TGetPluginInfo  = function(InfoNo: Integer; Buf: PChar;
    BufLen: Integer): Integer; stdcall;

  TGetPictureInfo = function(buf: PChar; len: Integer; flag: Integer;
    var Info: TPictureInfo): Integer; stdcall;

  TGetPicture = function(buf: PChar; len: LongInt; flag: Integer;
    var HBInfo, HBm: THandle; PrgressCallback: TProgressCallBack; lData: LongInt)
    :Integer; stdcall;

  TIsSupported = function(FileName: PChar; dw: DWORD): LongBool; stdcall;


resourcestring
  SPIName        = 'ifpng.spi';
  FailureMsg     = 'Failed in opening the file.';
  UnsupportedMsg = 'Unsupported File.';

var
  GetPictureInfo: TGetPictureInfo;
  GetPicture:     TGetPicture;
  IsSupported:    TIsSupported;


function DPGetInfo(pInfo: PDP_ADDININFO): Bool; cdecl;
begin
    with pInfo^ do begin
        dwType           := DPADDIN_DECODER;
        Name             := 'PNG Decoder';
        CopyRight        := 'Copyright 1999  Masahiro Sakai';
        Version          := '1.01';
        AddinDescription := 'using Susie Plug-in(ifpng.spi)';
        DefExt           := 'png';
        Description      := 'Portable Network Graphics(*.png)';
        // Description      := 'PNG''s not GIF(*.png)';
    end;
    Result := True;
end;

function DPDecode(AFileName: PChar; pinfo: PDP_ENCDECINFO): Bool; cdecl;
    function AddOffset(p: Pointer; Offset: LongInt): Pointer;
    begin
        Result := Pointer(LongInt(p) + Offset);
    end;
    function Bits(x: Byte): Byte;
    begin
        Result := 1 shl x;
    end;
const
  MacBinSize = 128;
var
  h:Thandle;
  FileHandle: THandle;
  PictureInfo: TPictureInfo;
  Ret: Integer;
  hBData: THandle;
  hBInfo: THandle;
  pBData: Pointer;
  pBInfo: PBitmapInfo;
  PalCount, LineSize, ImageSize, SrcLineSize: Integer;
  x, y: Integer;
  pSrcBits, pDestBits: PByteArray;
begin
    Result := False;

    h := LoadLibrary(PChar(SPIName));
    if h > HINSTANCE_ERROR then
    begin
        @IsSupported    := GetProcAddress(h, 'IsSupported');
        @GetPictureInfo := GetProcAddress(h, 'GetPictureInfo');
        @GetPicture     := GetProcAddress(h, 'GetPicture');
        if (@IsSupported = nil) or (@GetPictureInfo = nil) or (@GetPicture = nil) then begin
            MessageBox(0, PChar(FailureMsg), nil, MB_OK);
            Exit;
        end;
    end else begin
        MessageBox(0, PChar(FailureMsg), nil, MB_OK);
        Exit;
    end;

    try
        FileHandle := FileOpen(AFileName, fmOpenRead or fmShareDenyNone);
        if not (FileHandle > 0) then Exit;

        try
            if not IsSupported(AFileName, FileHandle) then begin
                MessageBox(0, PChar(UnsupportedMsg), nil, MB_OK);
                Exit;
            end;

            Ret := GetPictureInfo(AFileName, 0, 0, PictureInfo);
            if Ret = 2 then
                Ret := GetPictureInfo(AFileName, MacBinSize, 0, PictureInfo);

            if Ret <> 0 then begin
                MessageBox(0, PChar(FailureMsg), nil, MB_OK);
                Exit;
            end;

            if (Ret <> 0) or (PictureInfo.ColorDepth > 8) then begin
                MessageBox(0, PChar(UnsupportedMsg), nil, MB_OK);
                Exit;
            end;

            Ret := GetPicture(AFileName, 0, 0, hBInfo, hBData, nil, 0);
            if Ret = 2 then
                Ret := GetPicture(AFileName, 128, 0, hBInfo, hBData, nil, 0);

            if Ret <> 0 then begin
                MessageBox(0, PChar(FailureMsg), nil, MB_OK);
                Exit;
            end;
        finally
            FileClose(FileHandle);
        end;

        pBData := LocalLock(hBData);
        pBInfo := LocalLock(hBInfo);
        try
            if (pBInfo.bmiHeader.biCompression <> BI_RGB) or (pBInfo.bmiHeader.biBitCount > 8) then begin
                MessageBox(0, PChar(UnsupportedMsg), nil, MB_OK);
                Exit;
            end;

            with pInfo^ do begin
                nPicture := 1;
                dwFlag   := 0;
                pDibBuf  := Pointer(GlobalAlloc(GPTR, Sizeof(Pointer)));
                pBitBuf  := Pointer(GlobalAlloc(GPTR, Sizeof(Pointer)));
            end;

            LineSize  := ((pBInfo^.bmiHeader.biWidth + 3) div 4) * 4;
            ImageSize := LineSize * pBInfo.bmiHeader.biHeight;

            pInfo^.pDibBuf^ := Pointer(GlobalAlloc(GPTR, pBInfo.bmiHeader.biSize + SizeOf(TRGBQuad) * 256 + ImageSize));
            pInfo^.pBitBuf^ := AddOffset(pInfo^.pDibBuf^, pBInfo.bmiHeader.biSize + SizeOf(TRGBQuad) * 256);

            if pInfo^.pDibBuf^ = nil then begin
                MessageBox(0, PChar(FailureMsg), nil, MB_OK);
                Exit;
            end;

            PalCount := pBInfo.bmiHeader.biClrUsed;
            if PalCount = 0 then
                PalCount := 1 shl pBInfo.bmiHeader.biBitCount;

            Move(pBInfo^.bmiHeader, pInfo^.pDibBuf^^, pBInfo.bmiHeader.biSize + SizeOf(TRGBQuad) * PalCount);

            SrcLineSize  := ((pBInfo^.bmiHeader.biWidth * pBInfo^.bmiHeader.biBitCount div 8 + 3) div 4) * 4;
            case pBInfo.bmiHeader.biBitCount of
              8: Move(pBData^, pInfo^.pBitBuf^^, ImageSize);
              4: begin
                     for y := 0 to pBInfo^.bmiHeader.biHeight - 1 do begin
                         pSrcBits  := AddOffset(pBData, SrcLineSize * y);
                         pDestBits := AddOffset(pInfo^.pBitBuf^, LineSize * y);
                         for x := 0 to pBInfo^.bmiHeader.biWidth - 1 do begin
                             if Odd(x) then
                                 pDestBits[x] := pSrcBits[x div 2] and $0F
                             else
                                 pDestBits[x] := pSrcBits[x div 2] shr 4;
                         end;
                     end;
                 end;
              1: begin
                     for y := 0 to pBInfo^.bmiHeader.biHeight - 1 do begin
                         pSrcBits  := AddOffset(pBData, SrcLineSize * y);
                         pDestBits := AddOffset(pInfo^.pBitBuf^, LineSize * y);
                         for x := 0 to pBInfo^.bmiHeader.biWidth - 1 do begin
                             pDestBits^[x] := (pSrcBits^[x div 8] and Bits(7 - (x mod 8))) shr (7 - (x mod 8));
                         end;
                     end;
                 end;
              else begin
                  MessageBox(0, PChar(UnsupportedMsg), nil, MB_OK);
                  Exit;
              end;
            end;

            Result := True;
        finally
            LocalUnlock(hBData);
            LocalUnlock(hBInfo);
            LocalFree(hBData);
            LocalFree(hBInfo);
        end;

    finally
        FreeLibrary(h);
    end;
end;


exports
	DPGetInfo name '_DPGetInfo',
	DPDecode  name '_DPDecode';

end.
