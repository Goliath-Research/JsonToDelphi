unit Rest.Json;

{ Compile-only surface for Pkg.Json.DTO methods the leak tests do not call. }

interface

uses
  SysUtils, System.Json;

type
  TJsonOption = (joDateIsUTC, joDateFormatISO8601);
  TJsonOptions = set of TJsonOption;

  EConversionError = class(Exception);

  TJSONUnMarshal = class
  public
    procedure SetFieldArray(Data: TObject; const Field: string; Value: TJSONArray);
  end;

  TJson = class
  public
    class function ObjectToJsonString(AObject: TObject; Options: TJsonOptions): string;
    class function JsonToObject(AObject: TObject; AJSONObject: TJSONObject; Options: TJsonOptions): TObject;
  end;

implementation

procedure TJSONUnMarshal.SetFieldArray(Data: TObject; const Field: string; Value: TJSONArray);
begin
end;

class function TJson.ObjectToJsonString(AObject: TObject; Options: TJsonOptions): string;
begin
  Result := '';
end;

class function TJson.JsonToObject(AObject: TObject; AJSONObject: TJSONObject; Options: TJsonOptions): TObject;
begin
  Result := AObject;
end;

end.
