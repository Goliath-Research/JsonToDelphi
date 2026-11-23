unit System.SysUtils;

{ Test host for the Delphi System.SysUtils surface this generator uses.
  String helpers forward to the Free Pascal helpers in syshelps.inc.
  AnsiQuotedStr follows rtl/objpas/sysutils/sysstr.inc. }

{$mode delphi}
{$modeswitch typehelpers}
{$H+}

interface

uses
  SysUtils;

type
  Exception = SysUtils.Exception;
  EConvertError = SysUtils.EConvertError;
  TStringBuilder = SysUtils.TAnsiStringBuilder;

  TStringHelper = type helper(SysUtils.TAnsiStringHelper) for AnsiString
  end;

function SameText(const S1, S2: string): Boolean;
function CompareStr(const S1, S2: string): Integer;
function AnsiQuotedStr(const S: string; Quote: Char): string;
function Format(const Fmt: string; const Args: array of const): string;
function TryStrToInt(const S: string; out Value: Integer): Boolean;
function TryStrToInt64(const S: string; out Value: Int64): Boolean;
function TryStrToFloat(const S: string; out Value: Extended): Boolean;
function TryStrToBool(const S: string; out Value: Boolean): Boolean;
function TryJsonToFloat(const S: string; out Value: Double): Boolean;
function UpperCase(const S: string): string;
procedure FreeAndNil(var Obj);

implementation

function SameText(const S1, S2: string): Boolean;
begin
  Result := SysUtils.SameText(S1, S2);
end;

function CompareStr(const S1, S2: string): Integer;
begin
  Result := SysUtils.CompareStr(S1, S2);
end;

function AnsiQuotedStr(const S: string; Quote: Char): string;
var
  i, j, count: Integer;
begin
  Result := '' + Quote;
  count := Length(S);
  i := 0;
  j := 0;
  while i < count do
  begin
    i := i + 1;
    if S[i] = Quote then
    begin
      Result := Result + Copy(S, 1 + j, i - j) + Quote;
      j := i;
    end;
  end;
  if i <> j then
    Result := Result + Copy(S, 1 + j, i - j);
  Result := Result + Quote;
end;

function Format(const Fmt: string; const Args: array of const): string;
begin
  Result := SysUtils.Format(Fmt, Args);
end;

function TryStrToInt(const S: string; out Value: Integer): Boolean;
begin
  Result := SysUtils.TryStrToInt(S, Value);
end;

function TryStrToInt64(const S: string; out Value: Int64): Boolean;
begin
  Result := SysUtils.TryStrToInt64(S, Value);
end;

function TryStrToFloat(const S: string; out Value: Extended): Boolean;
begin
  Result := SysUtils.TryStrToFloat(S, Value);
end;

function TryStrToBool(const S: string; out Value: Boolean): Boolean;
begin
  Result := SysUtils.TryStrToBool(S, Value);
end;

function TryJsonToFloat(const S: string; out Value: Double): Boolean;
var
  FS: TFormatSettings;
  E: Extended;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := SysUtils.TryStrToFloat(S, E, FS);
  if Result then
    Value := E;
end;

function UpperCase(const S: string): string;
begin
  Result := SysUtils.UpperCase(S);
end;

procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  TObject(Obj) := nil;
  Temp.Free;
end;

end.
