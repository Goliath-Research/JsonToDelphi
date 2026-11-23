unit JsonCompat;

{ Delphi's System.SysUtils.TryJsonToFloat, which Pkg.Json.JsonValueHelper calls
  for JSON numbers. Free Pascal's SysUtils does not declare that function.
  The test build adds this unit to the copied helper's uses clause only. }

interface

function TryJsonToFloat(const Value: string; out AValue: Double): Boolean;

implementation

uses
  SysUtils;

function TryJsonToFloat(const Value: string; out AValue: Double): Boolean;
begin
  Result := TryStrToFloat(Value, AValue);
end;

end.
