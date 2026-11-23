unit System.IOUtils;

{$mode delphi}
{$H+}

interface

type
  TPath = record
  public
    class var DirectorySeparatorChar: Char;
    class function GetDirectoryName(const FileName: string): string; static;
  end;

implementation

class function TPath.GetDirectoryName(const FileName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := Length(FileName) downto 1 do
    if FileName[I] = DirectorySeparatorChar then
      Exit(Copy(FileName, 1, I - 1));
end;

initialization
  TPath.DirectorySeparatorChar := '/';

end.
