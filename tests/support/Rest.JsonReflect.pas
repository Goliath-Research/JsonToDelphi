unit Rest.JsonReflect;

{ Compile-only surface for the attribute types declared in Pkg.Json.DTO. }

interface

type
  TListOfObjects = array of TObject;
  TConverterType = (ctObjects, ctString);
  TReverterType = (rtObjects, rtString);

  TJSONInterceptor = class
  public
    function ObjectsConverter(Data: TObject; Field: string): TListOfObjects; virtual;
    function StringConverter(Data: TObject; Field: string): string; virtual;
    procedure StringReverter(Data: TObject; Field: string; Arg: string); virtual;
  end;

  JsonReflectAttribute = class
  public
    constructor Create(AConverterType: TConverterType; AReverterType: TReverterType;
      AInterceptor: TClass; APopulationCustomizer: TObject; ARequired: Boolean); overload;
    constructor Create(AConverterType: TConverterType; AReverterType: TReverterType;
      AInterceptor: TClass); overload;
  end;

implementation

function TJSONInterceptor.ObjectsConverter(Data: TObject; Field: string): TListOfObjects;
begin
  SetLength(Result, 0);
end;

function TJSONInterceptor.StringConverter(Data: TObject; Field: string): string;
begin
  Result := '';
end;

procedure TJSONInterceptor.StringReverter(Data: TObject; Field: string; Arg: string);
begin
end;

constructor JsonReflectAttribute.Create(AConverterType: TConverterType; AReverterType: TReverterType;
  AInterceptor: TClass; APopulationCustomizer: TObject; ARequired: Boolean);
begin
  inherited Create;
end;

constructor JsonReflectAttribute.Create(AConverterType: TConverterType; AReverterType: TReverterType;
  AInterceptor: TClass);
begin
  inherited Create;
end;

end.
