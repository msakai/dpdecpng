{ Translated from "dp_add.h" by Masahiro Sakai <ZVM01052@nifty.ne.jp> }

{ --------------------------------------------------------------------
	D-Pixed ver.2.08 or Later

	D-Pixed  Add-In  SDK

		Header for Add-In

	1996-1997	Coypright(C) DOIchan!

	dp_add.h

------------------------------------------------------------------------
All Add-in tool should include this header file.
----------------------------------------------------------------------- }

unit Dp_Add;

interface

uses
  Windows, Messages;

//--------------------------------------------------------------------
//	information for Decoder and Encoder
//--------------------------------------------------------------------

type
  PDP_EncDecInfo = ^TDP_EncDecInfo;
  TDP_EncDecInfo = packed record
    dwSize   : DWORD;
    dwFlag   : DWORD;
    keyColor : Integer;
    bgColor  : Integer;
    nPicture : DWORD;
    pDibBuf  : ^PBITMAPINFOHEADER;
    pBitBuf  : ^Pointer;
  end;

const
  DPDECENC_HANDLE          = $00000001;
  DPDECENC_SEPARATED       = $00000002;
  DPDECENC_KEYCOLOR        = $00000010;
  DPDECENC_BACKGROUNDCOLOR = $00000020;

//---------------------------------------------------------------------
//		information for Filter
//---------------------------------------------------------------------

type
  PDP_FilterInfo = ^TDP_FilterInfo;
  TDP_FilterInfo = packed record
    dwSize: DWORD;
    pDib: PBITMAPINFOHEADER;
    pBits, pMaskBits: PByte;
    pRefDib: PBITMAPINFOHEADER;
    pRefBits: PByte;
    dwFlag: DWORD;
    hwndDIB: Hwnd;
    leftColor, rightColor, keyColor, bgColor,
    mix, selectedSx, selectedSy, selectedWidth, selectedHeight :Integer;
  end;

const
  DPFILTER_MASKPLANE 	   = $00000001;		//Use maskplane
  DPFILTER_MASKON 	   = $00000002;		//Enable mask
  DPFILTER_USEKEYCOLOR 	   = $00000004;		//Enable transparent color
  DPFILTER_SELECTED 	   = $00000010;		//Area Selected
  DPFILTER_ENABLEREFERENCE = $00000020;		//Enable reference DIB
  DPFILTER_CURRENTIMAGE    = $00000100;		//Image is Current DIB

  DPFILTER_PALETTECHANGED  = $00010000;		//palette changed

//-------------------------------------------------------
// Pen Add-In information
//-------------------------------------------------------

type
  PDP_PenInfo = ^TDP_PenInfo;
  TDP_PenInfo = packed record
    dwSize: DWORD;
    pDib: PBITMAPINFOHEADER;
    pBits, pMaskBits, pOffscreen: PByte;
    pPenDib: PBITMAPINFOHEADER;
    pPenBits: PByte;
    dwFlag: DWORD;
    leftColor, rightColor, keyColor, bgColor, mix: Integer;
    x, y: LongInt;
    redrawRect: TRect;
    hdc: HDC;
    reserved: hWnd ;
    //---Ver.2.08-----
    pAreaBits: PByte;
    areaRect,dragRect: TRect;
  end;

//Flag for Pen Add-In
const
  DPWF_MASKON		   = $00000010;		//Enable Mask
  DPWF_MASK		   = $00000020;		//pBits is Mask plane
  DPWF_USETRANSPARENTCOLOR = $00001000;		//Enable keyColor

  DPWF_WANTREDRAW 	   = $03000000;		//Enable redrawRect and redraw image
  DPWF_SETPALETTE 	   = $04000000;		//Palette Select by Add-In
  DPWF_SETMIX 		   = $08000000;		//Set Mix Value by Add-In
  DPWF_NOINVALIDATE 	   = $80000000;		//Only Blt Offscreen to Display

//Message for Pen Add-In

//Post from DIB Window
  DPWM_ACTIVATE        =  WM_USER + 1;		//DIB Window Activate
  DPWM_PALETTECHANGED  =  WM_USER + 2;		//Palette Table Changed
  DPWM_SELECTPALETTE   =  WM_USER + 4;		//User Select Palette
  DPWM_COMMANDCHANGED  =  WM_USER + 9;		//User Select Other Pen tool
  DPWM_COMMANDSELECTED =  WM_USER + 10;		//User Select Pen tool

//Post from Pen Add-In
  DPWM_DISPMESSAGE     =  WM_USER + 12;		//Show Message on Status bar
  DPWM_DIB2SCREEN      =  WM_USER + 30;		//Compute DIB point to Screen Point
  DPWM_SCREEN2DIB      =  WM_USER + 31;		//Compute Screen point to DIB point
  DPWM_UPDATEOFFSCREEN =  WM_USER + 32;		//Update Offscreen buffer
  DPWM_BLTOFFSCREEN    =  WM_USER + 33;		//Blit ofscreen to Display
  DPWM_GETINFO 	       =  WM_USER + 34;		//Get Pen Add-In Info

//---------------------------------------------------------
//	information of Add-in tool
//---------------------------------------------------------

type
  PDP_AddinInfo = ^TDP_AddinInfo;
  TDP_AddinInfo = packed record
    dwSize : DWORD;
    dwType : DWORD;
    Name   : PChar;
    Description : PChar;
    DefExt      : PChar;
    Copyright   : PChar;
    Version     : PChar;
    AddinDescription:PChar;
  end;

const
//Add-In types
  DPADDIN_ENCODER 	      =	$00002001;		//Encoder
  DPADDIN_DECODER 	      =	$00002002;		//Decoder
  DPADDIN_FILTER 	      =	$00002004;		//Filter
  DPADDIN_PEN 		      =	$00002008;		//Pen

  DPADDIN_PEN_ENABLEMODE      =	$00010000;		//Drawing Mode Change
  DPADDIN_PEN_DISABLEFREEMODE = $00020000;		//Free-Hand Mode Not Supported
  DPADDIN_PEN_ENABLEPENMOVE   =	$01000000;		//Enable Pen Outline

{
// Procedure definitions for Add-In tools

 //	Procedure for Decoder
function DPDecode(AFileName: PChar; var Info: TDP_EncDecInfo): Bool; cdecl;

//	Procedure for Encoder
function DPEncode(AFileName: PChar; var Info: TDP_EncDecInfo): Bool; cdecl;

//	Procedure for Filter
function DPFilter(var Info: TDP_FilterInfo): Bool; cdecl;

//
//Procedure for Pen
function DPPen(hwnd: THandle; msg: UINT; wParam: WParam; lParam: LParam; var Info: TDP_PenInfo): LongInt; cdecl;

//
//	Procedure to get information (Always this must exist)
function DPGetInfo(var Info: TDP_AddinInfo): Bool; cdecl;

exports
	DPGetInfo name '_DPGetInfo',
	DPDecode  name '_DPDecode',
        DPEncode  name '_DPEncode',
	DPFilter  name '_DPFilter';
}


implementation

end.
