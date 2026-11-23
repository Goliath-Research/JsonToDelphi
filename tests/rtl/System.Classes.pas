unit System.Classes;

{ Test host. TStringList is Classes.TStringList.
  ExtractStrings forwards to rtl/objpas/classes/classes.inc. }

{$mode delphi}
{$H+}

interface

uses
  Classes, SysUtils;

type
  TStrings = Classes.TStrings;
  TStringList = Classes.TStringList;
  TResourceStream = Classes.TResourceStream;
  TDuplicates = Classes.TDuplicates;

function ExtractStrings(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings): Integer;

implementation

function ExtractStrings(Separators, WhiteSpace: TSysCharSet; Content: PChar;
  Strings: TStrings): Integer;
begin
  Result := Classes.ExtractStrings(Separators, WhiteSpace, Content, Strings);
end;

end.
