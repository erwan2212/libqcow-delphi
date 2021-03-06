//QCOW read only operations

unit LibQCOW;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{/*
  * Module providing Delphi bindings for the Library libqcow
  *
  * Copyright (c) 2014, Erwan LABALEC <erwan2212@gmail.com>,
  *
  * This software is free software: you can redistribute it and/or modify
  * it under the terms of the GNU Lesser General Public License as published by
  * the Free Software Foundation, either version 3 of the License, or
  * (at your option) any later version.
  *
  * This software is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  * GNU General Public License for more details.
  *
  * You should have received a copy of the GNU Lesser General Public License
  * along with this software.  If not, see <http://www.gnu.org/licenses/>.
  */}


interface

uses
  Windows,
  SysUtils ;

type
  TINT16 = short;
  TUINT16 = word;
  TUINT8 = byte;
  PlibHDL = pointer;
  TSIZE = longword;
  TSIZE64 = int64;
  PSIZE64 = ^int64;

 Tlibqcowhandleinitialize=function(handle : PLIBHDL;error:pointer) : integer; cdecl; //pointer to PLIBHDL
 Tlibqcowhandlefree=function(handle : PLIBHDL;error:pointer) : integer; cdecl;  //pointer to PLIBHDL
 Tlibqcowhandleopen=function(handle : PLIBHDL;filename : pansichar; flags : integer;error:pointer) : integer; cdecl;
 Tlibqcowhandleopenwide=function(handle : PLIBHDL;filename : pwidechar; flags : integer;error:pointer) : integer; cdecl;
 Tlibqcowhandleclose=function(handle : PLIBHDL;error:pointer) : integer; cdecl;
 Tlibqcowhandlegetmediasize = function(handle : PLIBHDL; media_size : PSIZE64;error:pointer) : integer; cdecl;
 Tlibqcowhandlewritebuffer = function(handle : PLIBHDL; buffer : pointer; size : TSIZE; offset : TSIZE64;error:pointer) : integer; cdecl;
 Tlibqcowhandlereadbufferatoffset = function(handle : PLIBHDL; buffer : pointer; size : TSIZE; offset : TSIZE64;error:pointer) : integer; cdecl;
 Tlibqcowhandleseekoffset= function(handle : PLIBHDL; offset : TSIZE64;whence:integer;error:pointer) : TSIZE64; cdecl;
 Tlibqcowhandlereadbuffer=function(handle : PLIBHDL; buffer : pointer; size : TSIZE; error:pointer) : integer; cdecl;

  TLibqcow = class(TObject)
  private
        fLibHandle : THandle;
        fCurHandle : PlibHDL;

        flibqcowhandleopen:Tlibqcowhandleopen ;
        flibqcowhandleopenwide:Tlibqcowhandleopenwide ;
        flibqcowhandleclose:Tlibqcowhandleclose ;
        flibqcowhandleinitialize:Tlibqcowhandleinitialize ;
        flibqcowhandlefree:Tlibqcowhandlefree ;
        flibqcowhandlereadbufferatoffset:Tlibqcowhandlereadbufferatoffset;
        flibqcowhandlewritebuffer:Tlibqcowhandlewritebuffer;
        flibqcowhandlegetmediasize:Tlibqcowhandlegetmediasize;
        flibqcowhandleseekoffset:Tlibqcowhandleseekoffset;
        flibqcowhandlereadbuffer:Tlibqcowhandlereadbuffer;

  public
        constructor create();
        destructor destroy(); override;
        function libqcow_open(const filename : ansistring;flag:byte=$1) : integer;
        function libqcow_open_wide(const filename : widestring;flag:byte=$1) : integer;
        function libqcow_read_buffer_at_offset(buffer : pointer; size : longword; offset : int64) : integer;
        function libqcow_write_buffer(buffer : pointer; size : longword; offset : int64) : integer;
        function libqcow_get_media_size() : int64;
        function libqcow_close() : integer;
  end;

const
        libqcow_OPEN_READ = $01;
        libqcow_OPEN_WRITE = $02;

        SEEK_CUR =   1;
        SEEK_END =   2;
        SEEK_SET  =  0;

implementation

constructor TLibqcow.create();
var
        libFileName : ansistring;
begin
        fLibHandle:=0;
        fCurHandle:=nil;

        //libFileName:=ExtractFilePath(Application.ExeName)+'libqcow.dll';
        libFileName:=ExtractFilePath(ParamStr(0))+'libqcow.dll';
        if fileExists(libFileName) then
        begin
                fLibHandle:=LoadLibraryA(PAnsiChar(libFileName));
                if fLibHandle<>0 then
                begin
                        @flibqcowhandleinitialize:=GetProcAddress(fLibHandle,'libqcow_file_initialize');
                        @flibqcowhandlefree:=GetProcAddress(fLibHandle,'libqcow_file_free');
                        @flibqcowhandleopen:=GetProcAddress(fLibHandle,'libqcow_file_open');
                        @flibqcowhandleopenwide:=GetProcAddress(fLibHandle,'libqcow_file_open_wide');
                        @flibqcowhandleclose:=GetProcAddress(fLibHandle,'libqcow_file_close');
                        @flibqcowhandlereadbufferatoffset:=GetProcAddress(fLibHandle,'libqcow_file_read_buffer_at_offset');
                        @flibqcowhandlewritebuffer:=GetProcAddress(fLibHandle,'libqcow_file_write_buffer');
                        @flibqcowhandlegetmediasize:=GetProcAddress(fLibHandle,'libqcow_file_get_media_size');
                        @flibqcowhandleseekoffset:=GetProcAddress(fLibHandle,'libqcow_file_seek_offset');
                        @flibqcowhandlereadbuffer:=GetProcAddress(fLibHandle,'libqcow_file_read_buffer');
                 end;
        end
        else raise exception.create('could not find libqcow.dll');
end;

destructor Tlibqcow.destroy();
begin
        if (fCurHandle<>nil) then
        begin
                libqcow_close();
                FreeLibrary(fLibHandle);
        end;
        inherited;
end;


{/*
  * Open an entire (even multipart)  file.
  * @param filename - the first (.e01) file name.
  * @return 0 if successful and valid, -1 otherwise.
  */}
function Tlibqcow.libqcow_open(const filename : ansistring;flag:byte=$1) : integer;
var
        err:pointer;
        ret:integer;
begin
        err:=nil;
        Result:=-1;
        ret:=flibqcowhandleinitialize (@fCurHandle,@err); //pointer to pointer = ** in c
        if ret=1
           then if flibqcowhandleopen (fCurHandle,pchar(fileName), flag,@err)<>1
                then {raise exception.Create('flibqcowhandleopen failed')};
        if fCurHandle<>nil then  Result:=0;
end;

function Tlibqcow.libqcow_open_wide(const filename : widestring;flag:byte=$1) : integer;
var
        err:pointer;
        ret:integer;
begin
        err:=nil;
        Result:=-1;
        ret:=flibqcowhandleinitialize (@fCurHandle,@err); //pointer to pointer = ** in c
        if ret=1
           then if flibqcowhandleopenwide (fCurHandle,pwidechar(fileName), flag,@err)<>1
                then {raise exception.Create('flibqcowhandleopen failed')};
        if fCurHandle<>nil then  Result:=0;
end;


{/*
  * Read an arbitrary part of the  file.
  * @param buffer : pointer - pointer to a preallocated buffer (byte array) to read into.
  * @param size - The number of bytes to read
  * @param offset - The position within the  file.
  * @return The number of bytes successfully read, -1 if unsuccessful.
  */}
function Tlibqcow.libqcow_read_buffer_at_offset(buffer : pointer; size : longword; offset : int64) : integer;
var
err:pointer;
begin
        err:=nil;
        Result:=-1;
        if fLibHandle<>0 then
        begin
        {if flibqcowhandleseekoffset (fCurHandle ,offset,seek_set,@err)<>-1
          then result:=flibqcowhandlereadbuffer(fCurHandle ,buffer,size,@err);}
        Result:=flibqcowhandlereadbufferatoffset(fCurHandle, buffer, size, offset,@err);
        end;
end;

{/*
  * write an arbitrary part of the  file.
  * @param buffer : pointer - pointer to a preallocated buffer (byte array) to write from.
  * @param size - The number of bytes to write
  * @param offset - The position within the  file.
  * @return The number of bytes successfully written, -1 if unsuccessful.
  */}
function Tlibqcow.libqcow_write_buffer(buffer : pointer; size : longword; offset : int64) : integer;
var
err:pointer;
begin
        err:=nil;
        Result:=-1;
        if fLibHandle<>0 then
        begin
        Result:=flibqcowhandlewritebuffer(fCurHandle, buffer, size, offset,@err);
        end;
end;



{/*
  * Get the total true size of the  file.
  * @return The size of the  file in bytes, -1 if unsuccessful.
  */}
function Tlibqcow.libqcow_get_media_size() : int64;
var
        resInt64 :Int64;
        err:pointer;
begin
        err:=nil;
        Result:=-1;
        resInt64:=-1;
        if (fLibHandle<>0) and (fCurHandle<>nil) then
        begin
          flibqcowhandlegetmediasize (fCurHandle,@resInt64,@err);
          Result:=resInt64;
        end;
end;


{/*
  * Close the  file.
  * @return 0 if successful, -1 otherwise.
  */}
function Tlibqcow.libqcow_close() : integer;
var
err:pointer;
begin
        err:=nil;
        if fLibHandle<>0 then
        begin
        Result:=flibqcowhandleclose (fCurHandle,@err);
        if result=0 then result:=flibqcowhandlefree (@fCurHandle,@err);
        fCurHandle:=0;
        end;
end;

end.

