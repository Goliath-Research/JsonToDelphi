unit Pkg.Json.Settings;

interface

uses
  Pkg.Json.DTO;

Type
  TSettings = class(TJsonDTO)
  private
    class var FInstance: TSettings;

  var
    FAddJsonPropertyAttributes: Boolean;
    FPostFix: string;
    FPostFixClassNames: Boolean;
    FUsePascalCase: Boolean;
    FSuppressZeroDate: Boolean;
  public
    constructor Create; override;
    class function Instance: TSettings; deprecated 'Code generation does not read this object. Use TPkgJsonMapper.Settings';
    function GetPostFix: string;
    property AddJsonPropertyAttributes: Boolean read FAddJsonPropertyAttributes write FAddJsonPropertyAttributes;
    property PostFixClassNames: Boolean read FPostFixClassNames write FPostFixClassNames;
    property PostFix: string read FPostFix write FPostFix;
    property UsePascalCase: Boolean read FUsePascalCase write FUsePascalCase;
    property SuppressZeroDate: Boolean read FSuppressZeroDate write FSuppressZeroDate;
  end;

implementation

uses
  System.SysUtils, System.Strutils;

{ TSettings }

constructor TSettings.Create;
begin
  inherited Create;
  FUsePascalCase := True;
  FAddJsonPropertyAttributes := False;
  FPostFixClassNames := False;
  FPostFix := 'DTO';
  FSuppressZeroDate := True;
end;

function TSettings.GetPostFix: string;
begin
  Result := IfThen(PostFixClassNames, PostFix, string.empty);
end;

class function TSettings.Instance: TSettings;
begin
  if not Assigned(FInstance) then
    FInstance := TSettings.Create;
  Result := FInstance;
end;

initialization

finalization

TSettings.FInstance.Free;

end.
