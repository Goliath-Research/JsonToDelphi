unit System.Json;

{ JSON DOM for the calls in Pkg.Json.Mapper and Pkg.Json.JsonValueHelper:
  ParseJSONValue, class tests, pair and array enumeration, JsonString.Value,
  and AsType<string>. }

{$mode delphi}
{$H+}

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TJsonValue = class
  public
    function AsType<T>: T;
    function GetAsString: string; virtual;
  end;

  TJSONString = class(TJsonValue)
  private
    FValue: string;
  public
    constructor Create(const AValue: string);
    function GetAsString: string; override;
    property Value: string read FValue;
  end;

  TJSONNumber = class(TJsonValue)
  private
    FLiteral: string;
  public
    constructor Create(const ALiteral: string);
    function GetAsString: string; override;
  end;

  TJSONTrue = class(TJsonValue)
  public
    function GetAsString: string; override;
  end;

  TJSONFalse = class(TJsonValue)
  public
    function GetAsString: string; override;
  end;

  TJSONNull = class(TJsonValue)
  public
    function GetAsString: string; override;
  end;

  TJSONPair = class
  private
    FJsonString: TJSONString;
    FJsonValue: TJsonValue;
  public
    constructor Create(const AName: string; AValue: TJsonValue);
    destructor Destroy; override;
    property JsonString: TJSONString read FJsonString;
    property JSONValue: TJsonValue read FJsonValue;
  end;

  TJSONObject = class(TJsonValue)
  private type
    TPairList = TObjectList<TJSONPair>;
  public type
    TEnumerator = class
    private
      FList: TPairList;
      FIndex: Integer;
      function GetCurrent: TJSONPair;
    public
      constructor Create(AList: TPairList);
      function MoveNext: Boolean;
      property Current: TJSONPair read GetCurrent;
    end;
  private
    FPairs: TPairList;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddPair(const AName: string; AValue: TJsonValue);
    function GetEnumerator: TEnumerator;
    class function ParseJSONValue(const AJson: string): TJsonValue;
    property Count: Integer read GetCount;
  end;

  TJSONArray = class(TJsonValue)
  private type
    TValueList = TObjectList<TJsonValue>;
  public type
    TEnumerator = class
    private
      FList: TValueList;
      FIndex: Integer;
      function GetCurrent: TJsonValue;
    public
      constructor Create(AList: TValueList);
      function MoveNext: Boolean;
      property Current: TJsonValue read GetCurrent;
    end;
  private
    FItems: TValueList;
    function GetItem(Index: Integer): TJsonValue;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AValue: TJsonValue);
    function GetEnumerator: TEnumerator;
    property Items[Index: Integer]: TJsonValue read GetItem; default;
    property Count: Integer read GetCount;
  end;

implementation

function TJsonValue.GetAsString: string;
begin
  Result := '';
end;

function TJsonValue.AsType<T>: T;
var
  S: string;
begin
  S := GetAsString;
  if TypeInfo(T) <> TypeInfo(string) then
    raise Exception.Create('AsType only supports string');
  Move(S, Result, SizeOf(Pointer));
  { The string now has two owners. Keep the local alive by clearing without release. }
  Pointer(S) := nil;
end;

constructor TJSONString.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

function TJSONString.GetAsString: string;
begin
  Result := FValue;
end;

constructor TJSONNumber.Create(const ALiteral: string);
begin
  inherited Create;
  FLiteral := ALiteral;
end;

function TJSONNumber.GetAsString: string;
begin
  Result := FLiteral;
end;

function TJSONTrue.GetAsString: string;
begin
  Result := 'true';
end;

function TJSONFalse.GetAsString: string;
begin
  Result := 'false';
end;

function TJSONNull.GetAsString: string;
begin
  Result := '';
end;

constructor TJSONPair.Create(const AName: string; AValue: TJsonValue);
begin
  inherited Create;
  FJsonString := TJSONString.Create(AName);
  FJsonValue := AValue;
end;

destructor TJSONPair.Destroy;
begin
  FJsonString.Free;
  FJsonValue.Free;
  inherited;
end;

constructor TJSONObject.TEnumerator.Create(AList: TPairList);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TJSONObject.TEnumerator.GetCurrent: TJSONPair;
begin
  Result := FList[FIndex];
end;

function TJSONObject.TEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

constructor TJSONObject.Create;
begin
  inherited Create;
  FPairs := TPairList.Create(True);
end;

destructor TJSONObject.Destroy;
begin
  FPairs.Free;
  inherited;
end;

function TJSONObject.GetCount: Integer;
begin
  Result := FPairs.Count;
end;

procedure TJSONObject.AddPair(const AName: string; AValue: TJsonValue);
begin
  FPairs.Add(TJSONPair.Create(AName, AValue));
end;

function TJSONObject.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(FPairs);
end;

constructor TJSONArray.TEnumerator.Create(AList: TValueList);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TJSONArray.TEnumerator.GetCurrent: TJsonValue;
begin
  Result := FList[FIndex];
end;

function TJSONArray.TEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

constructor TJSONArray.Create;
begin
  inherited Create;
  FItems := TValueList.Create(True);
end;

destructor TJSONArray.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TJSONArray.Add(AValue: TJsonValue);
begin
  FItems.Add(AValue);
end;

function TJSONArray.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(FItems);
end;

function TJSONArray.GetItem(Index: Integer): TJsonValue;
begin
  Result := FItems[Index];
end;

function TJSONArray.GetCount: Integer;
begin
  Result := FItems.Count;
end;

type
  TParser = class
  private
    FJson: string;
    FPos: Integer;
    function Peek: Char;
    function Next: Char;
    procedure SkipWs;
    function ParseValue: TJsonValue;
    function ParseString: string;
    function ParseNumber: TJsonValue;
    function ParseObject: TJSONObject;
    function ParseArray: TJSONArray;
  public
    constructor Create(const AJson: string);
    function Parse: TJsonValue;
  end;

constructor TParser.Create(const AJson: string);
begin
  inherited Create;
  FJson := AJson;
  FPos := 1;
end;

function TParser.Peek: Char;
begin
  if FPos > Length(FJson) then
    Result := #0
  else
    Result := FJson[FPos];
end;

function TParser.Next: Char;
begin
  Result := Peek;
  if Result <> #0 then
    Inc(FPos);
end;

procedure TParser.SkipWs;
begin
  while Peek in [#9, #10, #13, ' '] do
    Next;
end;

function TParser.ParseString: string;
var
  C: Char;
  Hex: string;
  Code: Integer;
begin
  if Next <> '"' then
    raise Exception.Create('JSON string expected');
  Result := '';
  while True do
  begin
    C := Next;
    if C = #0 then
      raise Exception.Create('Unterminated JSON string');
    if C = '"' then
      Exit;
    if C = '\' then
    begin
      C := Next;
      case C of
        '"', '\', '/': Result := Result + C;
        'b': Result := Result + #8;
        'f': Result := Result + #12;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        't': Result := Result + #9;
        'u':
          begin
            Hex := Next + Next + Next + Next;
            if not TryStrToInt('$' + Hex, Code) then
              raise Exception.Create('Bad JSON escape');
            Result := Result + Chr(Code);
          end;
      else
        raise Exception.Create('Bad JSON escape');
      end;
    end
    else
      Result := Result + C;
  end;
end;

function TParser.ParseNumber: TJsonValue;
var
  Start: Integer;
begin
  Start := FPos;
  if Peek in ['+', '-'] then
    Next;
  while Peek in ['0'..'9', '.', 'e', 'E', '+', '-'] do
    Next;
  Result := TJSONNumber.Create(Copy(FJson, Start, FPos - Start));
end;

function TParser.ParseObject: TJSONObject;
var
  Name: string;
begin
  if Next <> '{' then
    raise Exception.Create('JSON object expected');
  Result := TJSONObject.Create;
  try
    SkipWs;
    if Peek = '}' then
    begin
      Next;
      Exit;
    end;
    while True do
    begin
      SkipWs;
      Name := ParseString;
      SkipWs;
      if Next <> ':' then
        raise Exception.Create('JSON colon expected');
      Result.AddPair(Name, ParseValue);
      SkipWs;
      if Peek = ',' then
      begin
        Next;
        Continue;
      end;
      if Peek = '}' then
      begin
        Next;
        Exit;
      end;
      raise Exception.Create('JSON object not closed');
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseArray: TJSONArray;
begin
  if Next <> '[' then
    raise Exception.Create('JSON array expected');
  Result := TJSONArray.Create;
  try
    SkipWs;
    if Peek = ']' then
    begin
      Next;
      Exit;
    end;
    while True do
    begin
      Result.Add(ParseValue);
      SkipWs;
      if Peek = ',' then
      begin
        Next;
        Continue;
      end;
      if Peek = ']' then
      begin
        Next;
        Exit;
      end;
      raise Exception.Create('JSON array not closed');
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseValue: TJsonValue;
begin
  SkipWs;
  case Peek of
    '{': Result := ParseObject;
    '[': Result := ParseArray;
    '"': Result := TJSONString.Create(ParseString);
    't':
      begin
        if Copy(FJson, FPos, 4) <> 'true' then
          raise Exception.Create('JSON true expected');
        Inc(FPos, 4);
        Result := TJSONTrue.Create;
      end;
    'f':
      begin
        if Copy(FJson, FPos, 5) <> 'false' then
          raise Exception.Create('JSON false expected');
        Inc(FPos, 5);
        Result := TJSONFalse.Create;
      end;
    'n':
      begin
        if Copy(FJson, FPos, 4) <> 'null' then
          raise Exception.Create('JSON null expected');
        Inc(FPos, 4);
        Result := TJSONNull.Create;
      end;
    '-', '0'..'9': Result := ParseNumber;
  else
    raise Exception.Create('JSON value expected');
  end;
end;

function TParser.Parse: TJsonValue;
begin
  Result := ParseValue;
  SkipWs;
  if Peek <> #0 then
  begin
    Result.Free;
    raise Exception.Create('Trailing JSON');
  end;
end;

class function TJSONObject.ParseJSONValue(const AJson: string): TJsonValue;
var
  Parser: TParser;
begin
  Parser := TParser.Create(AJson);
  try
    try
      Result := Parser.Parse;
    except
      Result := nil;
    end;
  finally
    Parser.Free;
  end;
end;

end.
