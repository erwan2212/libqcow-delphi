unit umain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls,LibQCOW;

type
  TForm1 = class(TForm)
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    Button2: TButton;
    pb_img: TProgressBar;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;



var
  Form1: TForm1;
  //
  QCOW:TlibQCOW;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
mediaSize:int64;
begin
memo1.Clear ;
OpenDialog1.Filter :='QCOW|*.QCOW';
if OpenDialog1.Execute=false then exit; 
QCOW:=TLibQCOW.create ;
if qcow.libqcow_open_wide (widestring(OpenDialog1.FileName) )=0 then
  begin
  mediaSize:=qcow.libqcow_get_media_size ;
  memo1.Lines.Add('size:'+inttostr(mediasize)); 
  end;
qcow.libqcow_close ;
FreeAndNil(qcow);
end;



procedure TForm1.Button2Click(Sender: TObject);
var
ipos,mediasize:int64;
lengthRead:integer;
buffer:array of byte;
//buffer:pointer;
memsize,BufferSize:integer;
byteswritten:cardinal;
ret:boolean;
hDevice_dst:thandle;
dst,src:string;
start:cardinal;
begin
OutputDebugString(pchar('start'));
memo1.Clear ;
memsize:=1024*64;BufferSize:=memsize;
ipos:=0;

OpenDialog1.Filter :='QCOW|*.QCOW';
if OpenDialog1.Execute =false then exit;
src:=OpenDialog1.FileName ;

dst:=ChangeFileExt(src,'.dd'); 
{$i-}deletefile(dst);{$i-}

qcow:=TLibqcow.create ;
try
if qcow.libqcow_open_wide (widestring(src),LIBqcow_OPEN_READ)=0 then
  begin
    mediaSize:=qcow.libqcow_get_media_size ;
    pb_img.Max :=100;
    memo1.lines.add('starting');
    //VirtualAlloc (buffer,memsize,MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
    setlength(buffer,memsize );
    hDevice_dst := CreateFile(pchar(dst), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_NEW, 0 , 0);
    start:=GetTickCount ;
    while (lengthRead>0)  do
    begin
    if ipos+BufferSize >mediasize then BufferSize :=mediasize -ipos;
    lengthRead:=qcow.libqcow_read_buffer_at_offset(@buffer[0], BufferSize, ipos);
    if lengthRead>0 then
      begin
      ret:=WriteFile (hDevice_dst, buffer[0], lengthRead, byteswritten, nil);
      if (ret=false) or (byteswritten<>lengthRead) then memo1.Lines.Add('writefile failed');
    end;
    ipos:=ipos+BufferSize ;
    pb_img.Position :=ipos * 100 div mediasize;
    end; //while
    closehandle(hDevice_dst);
    memo1.lines.add('done in '+inttostr(GetTickCount -start)+'ms');
    //virtualfree(buffer,memsize ,MEM_RELEASE );
    //fLibEWF.libewf_close; //will be done in the free/destroy
  end;//if fLibEWF.libewf_open
finally
FreeAndNil(qcow);
end;
end;

function _Get_FileSize2(const FileName: string): TULargeInteger;
// by nico
var
  Find: THandle;
  Data: TWin32FindData;
begin
  Result.QuadPart := 0;
  Find := FindFirstFile(PChar(FileName), Data);
  if (Find <> INVALID_HANDLE_VALUE) then
  begin
    Result.LowPart  := Data.nFileSizeLow;
    Result.HighPart := Data.nFileSizeHigh;
    Windows.FindClose(Find);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
buffer:array of byte;
memsize,BufferSize:integer;
ipos,mediasize:int64;
hDevice_Src:thandle;
src,dst:string;
ret:boolean;
bytesread,byteswritten,start:cardinal;
begin
memo1.Clear ;
memsize:=1024*64;BufferSize:=memsize;

OpenDialog1.Filter :='img|*.img;*.dd';
if OpenDialog1.Execute =false then exit;
src:=OpenDialog1.FileName ;

dst:=ChangeFileExt(src,'.qcow');
{$i-}deletefile(dst);{$i-}

mediasize:=_Get_FileSize2(src).QuadPart ;
pb_img.Max :=mediasize;
ipos:=0;
setlength(buffer,memsize );
qcow:=TLibqcow.create;
try

if qcow.libqcow_open_wide(dst,LIBqcow_OPEN_WRITE)=0 then
  begin
  memo1.lines.add('starting');
  hDevice_Src := CreateFile(pchar(src), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  ret:=true;
  start:=GetTickCount ;
  while ret<>false do
    begin
    if ipos+BufferSize >mediasize then BufferSize :=mediasize -ipos;
    ret:=ReadFile (hDevice_Src, buffer[0], buffersize, bytesread, nil);
    if bytesread=0 then break;
    if ret=true
      then byteswritten:=qcow.libqcow_write_buffer(@buffer[0], BufferSize, ipos)
      else memo1.Lines.Add('readfile failed');
    ipos:=ipos+BufferSize ;
    pb_img.Position :=ipos;
    end; //while
  memo1.lines.add('done in '+inttostr(GetTickCount -start)+'ms');
  closehandle(hDevice_Src);
  //fLibqcow.libqcow_close;
  end;
finally
FreeAndNil(qcow);
end;
end;

end.
