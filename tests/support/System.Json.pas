unit System.Json;

{ Minimal JSON DOM for the class-generator tests.
  Covers the operations Pkg.Json.Mapper, Pkg.Json.JsonValueHelper and
  Pkg.Json.DTO.PrettyPrintJSON actually call: ParseJSONValue, object and
  array enumeration, Pairs/Items/Count, JsonString.Value, AsType<string>,
  and ToString. Parents own their children, matching TJSONValue.Free in
  TPkgJsonMapper.Parse. }

interface

type
  TJsonValue = class
  protected
    FRaw: string;
    function GetNull: Boolean; virtual;
  public
    class function ParseJSONValue(const Data: string): TJsonValue;
    function AsType<T>: T;
    function ToString: string; virtual;
    property Null: Boolean read GetNull;
  end;

  TJSONNull = class(TJsonValue)
  public
    constructor Create;
  end;

  TJSONNumber = class(TJsonValue)
  public
    constructor Create(const ARaw: string);
  end;

  TJsonString = class(TJsonValue)
  public
    constructor Create(const ARaw: string);
    function ToString: string; override;
    property Value: string read FRaw;
  end;

  TJSONTrue = class(TJsonValue)
  public
    constructor Create;
  end;

  TJSONFalse = class(TJsonValue)
  public
    constructor Create;
  end;

  TJSONPair = class
  private
    FJsonString: TJsonString;
    FJSONValue: TJsonValue;
  public
    constructor Create(const AName: string; AValue: TJsonValue);
    destructor Destroy; override;
    property JsonString: TJsonString read FJsonString;
    property JSONValue: TJsonValue read FJSONValue;
  end;

  TJSONObjectEnumerator = class
  private
    FPairs: TObject;
    FIndex: Integer;
    function GetCurrent: TJSONPair;
  public
    constructor Create(APairs: TObject);
    function MoveNext: Boolean;
    property Current: TJSONPair read GetCurrent;
  end;

  TJSONArrayEnumerator = class
  private
    FItems: TObject;
    FIndex: Integer;
    function GetCurrent: TJsonValue;
  public
    constructor Create(AItems: TObject);
    function MoveNext: Boolean;
    property Current: TJsonValue read GetCurrent;
  end;

  TJSONObject = class(TJsonValue)
  private
    FPairs: array of TJSONPair;
    function GetCount: Integer;
    function GetPair(Index: Integer): TJSONPair;
  public
    destructor Destroy; override;
    function GetEnumerator: TJSONObjectEnumerator;
    procedure AddPair(const AName: string; AValue: TJsonValue);
    property Count: Integer read GetCount;
    property Pairs[Index: Integer]: TJSONPair read GetPair;
  end;

  TJSONArray = class(TJsonValue)
  private
    FItems: array of TJsonValue;
    function GetCount: Integer;
    function GetItem(Index: Integer): TJsonValue;
  public
    destructor Destroy; override;
    function GetEnumerator: TJSONArrayEnumerator;
    procedure Add(AValue: TJsonValue);
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TJsonValue read GetItem;
  end;

implementation

uses
  SysUtils, TypInfo;

type
  TJsonParser = class
  private
    FData: string;
    FIndex: Integer;
    function Peek: Char;
    function Done: Boolean;
    procedure SkipWs;
    function ParseValue: TJsonValue;
    function ParseObject: TJSONObject;
    function ParseArray: TJSONArray;
    function ParseString: string;
    function ParseNumber: TJSONNumber;
  public
    constructor Create(const AData: string);
    function ParseRoot: TJsonValue;
  end;

function TJsonValue.GetNull: Boolean;
begin
  Result := Self is TJSONNull;
end;

function TJsonValue.AsType<T>: T;
begin
  if TypeInfo(T) <> TypeInfo(string) then
    raise Exception.Create('System.Json test shim only supports AsType<string>');
  PString(@Result)^ := FRaw;
end;

function TJsonValue.ToString: string;
begin
  Result := FRaw;
end;

class function TJsonValue.ParseJSONValue(const Data: string): TJsonValue;
var
  Parser: TJsonParser;
begin
  Parser := TJsonParser.Create(Data);
  try
    Result := Parser.ParseRoot;
  finally
    Parser.Free;
  end;
end;

constructor TJSONNull.Create;
begin
  inherited Create;
  FRaw := 'null';
end;

constructor TJSONNumber.Create(const ARaw: string);
begin
  inherited Create;
  FRaw := ARaw;
end;

constructor TJsonString.Create(const ARaw: string);
begin
  inherited Create;
  FRaw := ARaw;
end;

function TJsonString.ToString: string;
begin
  Result := '"' + FRaw + '"';
end;

constructor TJSONTrue.Create;
begin
  inherited Create;
  FRaw := 'true';
end;

constructor TJSONFalse.Create;
begin
  inherited Create;
  FRaw := 'false';
end;

constructor TJSONPair.Create(const AName: string; AValue: TJsonValue);
begin
  inherited Create;
  FJsonString := TJsonString.Create(AName);
  FJSONValue := AValue;
end;

destructor TJSONPair.Destroy;
begin
  FJsonString.Free;
  FJSONValue.Free;
  inherited;
end;

constructor TJSONObjectEnumerator.Create(APairs: TObject);
begin
  inherited Create;
  FPairs := APairs;
  FIndex := -1;
end;

function TJSONObjectEnumerator.GetCurrent: TJSONPair;
begin
  Result := TJSONObject(FPairs).Pairs[FIndex];
end;

function TJSONObjectEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < TJSONObject(FPairs).Count;
end;

constructor TJSONArrayEnumerator.Create(AItems: TObject);
begin
  inherited Create;
  FItems := AItems;
  FIndex := -1;
end;

function TJSONArrayEnumerator.GetCurrent: TJsonValue;
begin
  Result := TJSONArray(FItems).Items[FIndex];
end;

function TJSONArrayEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < TJSONArray(FItems).Count;
end;

function TJSONObject.GetCount: Integer;
begin
  Result := Length(FPairs);
end;

function TJSONObject.GetPair(Index: Integer): TJSONPair;
begin
  Result := FPairs[Index];
end;

destructor TJSONObject.Destroy;
var
  Pair: TJSONPair;
begin
  for Pair in FPairs do
    Pair.Free;
  inherited;
end;

function TJSONObject.GetEnumerator: TJSONObjectEnumerator;
begin
  Result := TJSONObjectEnumerator.Create(Self);
end;

procedure TJSONObject.AddPair(const AName: string; AValue: TJsonValue);
begin
  SetLength(FPairs, Length(FPairs) + 1);
  FPairs[High(FPairs)] := TJSONPair.Create(AName, AValue);
end;

function TJSONArray.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TJSONArray.GetItem(Index: Integer): TJsonValue;
begin
  Result := FItems[Index];
end;

destructor TJSONArray.Destroy;
var
  Item: TJsonValue;
begin
  for Item in FItems do
    Item.Free;
  inherited;
end;

function TJSONArray.GetEnumerator: TJSONArrayEnumerator;
begin
  Result := TJSONArrayEnumerator.Create(Self);
end;

procedure TJSONArray.Add(AValue: TJsonValue);
begin
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := AValue;
end;

constructor TJsonParser.Create(const AData: string);
begin
  inherited Create;
  FData := AData;
  FIndex := 1;
end;

function TJsonParser.Done: Boolean;
begin
  Result := FIndex > Length(FData);
end;

function TJsonParser.Peek: Char;
begin
  if Done then
    Result := #0
  else
    Result := FData[FIndex];
end;

procedure TJsonParser.SkipWs;
begin
  while not Done and (Peek <= ' ') do
    Inc(FIndex);
end;

function TJsonParser.ParseString: string;
begin
  if Peek <> '"' then
    raise Exception.Create('JSON string expected');
  Inc(FIndex);
  Result := '';
  while not Done and (Peek <> '"') do
  begin
    if Peek = '\' then
    begin
      Inc(FIndex);
      if Done then
        Break;
      case Peek of
        '"', '\', '/': Result := Result + Peek;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        't': Result := Result + #9;
      else
        Result := Result + Peek;
      end;
    end
    else
      Result := Result + Peek;
    Inc(FIndex);
  end;
  if Peek = '"' then
    Inc(FIndex);
end;

function TJsonParser.ParseNumber: TJSONNumber;
var
  Start: Integer;
begin
  Start := FIndex;
  if Peek = '-' then
    Inc(FIndex);
  while not Done and (Peek in ['0'..'9', '.', 'e', 'E', '+', '-']) do
    Inc(FIndex);
  Result := TJSONNumber.Create(Copy(FData, Start, FIndex - Start));
end;

function TJsonParser.ParseObject: TJSONObject;
var
  Name: string;
begin
  Result := TJSONObject.Create;
  try
    Inc(FIndex); { skip '{' }
    SkipWs;
    if Peek = '}' then
    begin
      Inc(FIndex);
      Exit;
    end;
    repeat
      SkipWs;
      Name := ParseString;
      SkipWs;
      if Peek = ':' then
        Inc(FIndex);
      Result.AddPair(Name, ParseValue);
      SkipWs;
      if Peek = ',' then
      begin
        Inc(FIndex);
        Continue;
      end;
      if Peek = '}' then
      begin
        Inc(FIndex);
        Break;
      end;
      raise Exception.Create('JSON object not closed');
    until False;
  except
    Result.Free;
    raise;
  end;
end;

function TJsonParser.ParseArray: TJSONArray;
begin
  Result := TJSONArray.Create;
  try
    Inc(FIndex);
    SkipWs;
    if Peek = ']' then
    begin
      Inc(FIndex);
      Exit;
    end;
    repeat
      Result.Add(ParseValue);
      SkipWs;
      if Peek = ',' then
      begin
        Inc(FIndex);
        Continue;
      end;
      if Peek = ']' then
      begin
        Inc(FIndex);
        Break;
      end;
      raise Exception.Create('JSON array not closed');
    until False;
  except
    Result.Free;
    raise;
  end;
end;

function TJsonParser.ParseValue: TJsonValue;
begin
  SkipWs;
  if Done then
    Exit(nil);
  case Peek of
    '{': Result := ParseObject;
    '[': Result := ParseArray;
    '"': Result := TJsonString.Create(ParseString);
    't':
      begin
        Inc(FIndex, 4);
        Result := TJSONTrue.Create;
      end;
    'f':
      begin
        Inc(FIndex, 5);
        Result := TJSONFalse.Create;
      end;
    'n':
      begin
        Inc(FIndex, 4);
        Result := TJSONNull.Create;
      end;
    '-', '0'..'9': Result := ParseNumber;
  else
    Result := nil;
  end;
end;

function TJsonParser.ParseRoot: TJsonValue;
begin
  try
    Result := ParseValue;
    SkipWs;
    if not Done then
    begin
      Result.Free;
      Result := nil;
    end;
  except
    Result := nil;
  end;
end;

end.
