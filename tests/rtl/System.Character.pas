unit System.Character;

{ Test host. Letter tests call Character.TCharacter, the Free Pascal Unicode data. }

{$mode delphi}
{$modeswitch typehelpers}
{$H+}

interface

uses
  Character;

type
  TCharHelper = type helper for AnsiChar
    function IsLetter: Boolean;
    function IsLetterOrDigit: Boolean;
  end;

implementation

function TCharHelper.IsLetter: Boolean;
begin
  Result := TCharacter.IsLetter(UnicodeChar(Byte(Self)));
end;

function TCharHelper.IsLetterOrDigit: Boolean;
begin
  Result := TCharacter.IsLetterOrDigit(UnicodeChar(Byte(Self)));
end;

end.
