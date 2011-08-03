{
 * UBDiff.pas
 *
 * Main program logic for BDiff.
 *
 * Based on bdiff.c by Stefan Reuther, copyright (c) 1999 Stefan Reuther
 * <Streu@gmx.de>.
 *
 * Copyright (c) 2003-2011 Peter D Johnson (www.delphidabbler.com).
 *
 * $Rev$
 * $Date$
 *
 * THIS SOFTWARE IS PROVIDED "AS-IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTY.
 * IN NO EVENT WILL THE AUTHORS BE HELD LIABLE FOR ANY DAMAGES ARISING FROM THE
 * USE OF THIS SOFTWARE.
 *
 * For conditions of distribution and use see the LICENSE file of visit
 * http://www.delphidabbler.com/software/bdiff/license
}


unit UBDiff;


interface


{ Program's main interface code: called from the project file }
procedure Main;


implementation

{$IOCHECKS OFF}

uses
  // Delphi
  SysUtils, Windows,
  // Project
  UAppInfo, UBDiffParams, UBDiffTypes, UBDiffUtils, UBlkSort, UErrors,
  UFileData, UPatchWriters;

const
  FORMAT_VERSION  = '02';       // binary diff file format version
  BUFFER_SIZE     = 4096;       // size of buffer used to read files


{ Structure for a matching block }
type
  TMatch = record
    OldOffset: size_t;
    NewOffset: size_t;
    BlockLength: size_t;
  end;
  PMatch = ^TMatch;

{ Global variables }
var
  gMinMatchLength: size_t = 24;   // default minimum match length
  gFormat: TFormat = FMT_QUOTED;  // default output format
  gVerbose: Boolean;              // verbose mode defaults to off / false

function LastOSError: EOSError;
var
  LastError: Integer;
begin
  LastError := GetLastError;
  if LastError <> 0 then
    Result := EOSError.Create(SysErrorMessage(LastError))
  else
    Result := EOSError.Create('Unknown operating system error');
  Result.ErrorCode := LastError;
end;

{ Find maximum-length match }
procedure FindMaxMatch(RetVal: PMatch; Data: PSignedAnsiCharArray;
  SortedData: PBlock; DataSize: size_t; SearchText: PSignedAnsiChar;
  SearchTextLength: size_t);
var
  FoundPos: size_t;
  FoundLen: size_t;
begin
  RetVal^.BlockLength := 0;  {no match}
  RetVal^.NewOffset := 0;
  while (SearchTextLength <> 0) do
  begin
    FoundLen := find_string(
      Data, SortedData, DataSize, SearchText, SearchTextLength, @FoundPos
    );
    if FoundLen >= gMinMatchLength then
    begin
      RetVal^.OldOffset := FoundPos;
      RetVal^.BlockLength := FoundLen;
      Exit;
    end;
    Inc(SearchText);
    Inc(RetVal^.NewOffset);
    Dec(SearchTextLength);
  end;
end;

{ Print log message, if enabled. Log messages go to stderr because we may be
  writing patch file contents to stdout }
procedure LogStatus(const Msg: string);
begin
  if gVerbose then
    WriteStrFmt(stderr, '%s: %s'#13#10, [ProgramFileName, Msg]);
end;

{ Main routine: generate diff }
procedure CreateDiff(OldFileName, NewFileName: string);
var
  OldFile: TFileData;
  NewFile: TFileData;
  NewOffset: size_t;
  ToDo: size_t;
  SortedOldData: PBlock;
  Match: TMatch;
  PatchWriter: TPatchWriter;
begin
  { initialize }
  OldFile := nil;
  NewFile := nil;
  SortedOldData := nil;
  PatchWriter := TPatchWriterFactory.Instance(gFormat);
  try
    LogStatus('loading old file');
    OldFile := TFileData.Create(OldFileName);
    LogStatus('loading new file');
    NewFile := TFileData.Create(NewFileName);
    LogStatus('block sorting old file');
    SortedOldData := block_sort(OldFile.Data, OldFile.Size);
    if not Assigned(SortedOldData) then
      Error('virtual memory exhausted');
    LogStatus('generating patch');
    PatchWriter.Header(OldFile.Name, NewFile.Name, OldFile.Size, NewFile.Size);
    { main loop }
    ToDo := NewFile.Size;
    NewOffset := 0;
    while (ToDo <> 0) do
    begin
      { invariant: nofs + todo = len2 }
      FindMaxMatch(
        @Match, OldFile.Data, SortedOldData, OldFile.Size,
        @NewFile.Data[NewOffset], ToDo
      );
      if Match.BlockLength <> 0 then
      begin
        { found a match }
        if Match.NewOffset <> 0 then
          { preceded by a "copy" block }
          PatchWriter.Add(@NewFile.Data[NewOffset], Match.NewOffset);
        Inc(NewOffset, Match.NewOffset);
        Dec(ToDo, Match.NewOffset);
        PatchWriter.Copy(
          NewFile.Data, NewOffset, Match.OldOffset, Match.BlockLength
        );
        Inc(NewOffset, Match.BlockLength);
        Dec(ToDo, Match.BlockLength);
      end
      else
      begin
        PatchWriter.Add(@NewFile.Data[NewOffset], ToDo);
        Break;
      end;
    end;
    LogStatus('done');
  finally
    // finally section new to v1.1
    if Assigned(SortedOldData) then
      FreeMem(SortedOldData);
    OldFile.Free;
    NewFile.Free;
    PatchWriter.Free;
  end;
end;

{ Display help screen  }
procedure DisplayHelp;
begin
  WriteStrFmt(
    stdout,
    '%0:s: binary ''diff'' - compare two binary files'#13#10#13#10
      + 'Usage: %0:s [options] old-file new-file [>patch-file]'#13#10#13#10
      + 'Difference between old-file and new-file written to standard output'
      + #13#10#13#10
      + 'Valid options:'#13#10
      + ' -q                   Use QUOTED format'#13#10
      + ' -f                   Use FILTERED format'#13#10
      + ' -b                   Use BINARY format'#13#10
      + '       --format=FMT   Use format FMT (''quoted'', ''filter[ed]'' '
      + 'or ''binary'')'#13#10
      + ' -m N  --min-equal=N  Minimum equal bytes to recognize an equal chunk'
      + #13#10
      + ' -o FN --output=FN    Set output file name (instead of stdout)'#13#10
      + ' -V    --verbose      Show status messages'#13#10
      + ' -h    --help         Show this help screen'#13#10
      + ' -v    --version      Show version information'#13#10
      + #13#10
      + '(c) copyright 1999 Stefan Reuther <Streu@gmx.de>'#13#10
      + '(c) copyright 2003-2009 Peter Johnson (www.delphidabbler.com)'#13#10,
    [ProgramFileName]
  );
end;

{ Display version }
procedure DisplayVersion;
begin
  // NOTE: original code displayed compile date using C's __DATE__ macro. Since
  // there is no Pascal equivalent of __DATE__ we display update date of program
  // file instead
  WriteStrFmt(
    stdout, '%s-%s %s '#13#10, [ProgramBaseName, ProgramVersion, ProgramExeDate]
  );
end;

{ Main routine: parses arguments and creates diff using CreateDiff() }
procedure Main;
var
  PatchFileHandle: Integer;
  Params: TParams;
begin
  ExitCode := 0;

  Params := TParams.Create;
  try
    try
      Params.Parse;

      if Params.Help then
      begin
        DisplayHelp;
        Exit;
      end;

      if Params.Version then
      begin
        DisplayVersion;
        Exit;
      end;

      gMinMatchLength := Params.MinEqual;
      gFormat := Params.Format;
      gVerbose := Params.Verbose;

      if (Params.PatchFileName <> '') and (Params.PatchFileName <> '-') then
      begin
        // redirect StdOut to patch file
        PatchFileHandle := FileCreate(Params.PatchFileName);
        if PatchFileHandle <= 0 then
          raise LastOSError;
        RedirectStdOut(PatchFileHandle);
      end;

      // create the diff
      CreateDiff(Params.OldFileName, Params.NewFileName);

    finally
      Params.Free;
    end;
  except
    on E: Exception do
    begin
      ExitCode := 1;
      WriteStrFmt(StdErr, '%0:s: %1:s'#13#10, [ProgramFileName, E.Message]);
    end;
  end;
end;

end.

