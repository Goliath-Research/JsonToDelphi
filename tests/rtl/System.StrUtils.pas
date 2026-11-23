unit System.StrUtils;

{$mode delphi}
{$H+}

interface

function IfThen(AValue: Boolean; const ATrue: string; const AFalse: string = ''): string; overload;

implementation

function IfThen(AValue: Boolean; const ATrue: string; const AFalse: string): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

end.
