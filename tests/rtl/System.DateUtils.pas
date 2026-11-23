unit System.DateUtils;

{ Recognizes the ISO-8601 shapes Pkg.Json.JsonValueHelper passes to
  TryISO8601ToDate: a calendar date, or that date with a time and optional
  fraction and Z or numeric offset. }

{$mode delphi}
{$H+}

interface

function TryISO8601ToDate(const AValue: string; out ADateTime: TDateTime): Boolean;

implementation

uses
  SysUtils;

function Digits(const S: string; Index, Count: Integer; out N: Integer): Boolean;
var
  I, V: Integer;
begin
  V := 0;
  if (Index < 1) or (Index + Count - 1 > Length(S)) then
    Exit(False);
  for I := 0 to Count - 1 do
  begin
    if not (S[Index + I] in ['0'..'9']) then
      Exit(False);
    V := V * 10 + (Ord(S[Index + I]) - Ord('0'));
  end;
  N := V;
  Result := True;
end;

function TryISO8601ToDate(const AValue: string; out ADateTime: TDateTime): Boolean;
var
  Year, Month, Day, Hour, Minute, Second, P, MSec: Integer;
  D: TDateTime;
  Tm: TDateTime;
begin
  Result := False;
  ADateTime := 0;
  if not Digits(AValue, 1, 4, Year) then
    Exit;
  if (Length(AValue) < 10) or (AValue[5] <> '-') or (AValue[8] <> '-') then
    Exit;
  if not Digits(AValue, 6, 2, Month) then
    Exit;
  if not Digits(AValue, 9, 2, Day) then
    Exit;
  if not TryEncodeDate(Year, Month, Day, D) then
    Exit;
  P := 11;
  Hour := 0;
  Minute := 0;
  Second := 0;
  MSec := 0;
  if P <= Length(AValue) then
  begin
    if not (AValue[P] in ['T', 't', ' ']) then
      Exit;
    Inc(P);
    if not Digits(AValue, P, 2, Hour) then
      Exit;
    if (P + 2 > Length(AValue)) or (AValue[P + 2] <> ':') then
      Exit;
    if not Digits(AValue, P + 3, 2, Minute) then
      Exit;
    if (P + 5 > Length(AValue)) or (AValue[P + 5] <> ':') then
      Exit;
    if not Digits(AValue, P + 6, 2, Second) then
      Exit;
    P := P + 8;
    if (P <= Length(AValue)) and (AValue[P] = '.') then
    begin
      Inc(P);
      while (P <= Length(AValue)) and (AValue[P] in ['0'..'9']) do
        Inc(P);
    end;
    if P <= Length(AValue) then
    begin
      if (AValue[P] = 'Z') or (AValue[P] = 'z') then
      begin
        if P <> Length(AValue) then
          Exit;
      end
      else if AValue[P] in ['+', '-'] then
      begin
        if P + 5 <> Length(AValue) then
          Exit;
        if (AValue[P + 3] <> ':') then
          Exit;
        if not Digits(AValue, P + 1, 2, MSec) then
          Exit;
        if not Digits(AValue, P + 4, 2, MSec) then
          Exit;
      end
      else
        Exit;
    end;
    if not TryEncodeTime(Hour, Minute, Second, 0, Tm) then
      Exit;
    D := D + Tm;
  end;
  ADateTime := D;
  Result := True;
end;

end.
