unit Pkg.Json.DTO;

{ Ancestor of TSettings. TSettings.MakeSingleton only calls inherited Create.
  The real constructor in Pkg.Json.DTO.pas sets JSON serialization options that
  TSettings never reads. This stand-in is that constructor's effect on TSettings. }

{$mode delphi}
{$H+}

interface

type
  TJsonDTO = class
  public
    constructor Create; virtual;
  end;

implementation

constructor TJsonDTO.Create;
begin
  inherited Create;
end;

end.
