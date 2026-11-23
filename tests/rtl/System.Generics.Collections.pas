unit System.Generics.Collections;

{ TObjectList is Generics.Collections.TObjectList. Sort is forwarded through
  ComparerBridge so the generator's own name comparison orders the fields. }

{$mode delphi}
{$H+}

interface

uses
  Generics.Collections,
  System.Generics.Defaults,
  ComparerBridge;

type
  TObjectList<T: class> = class(Generics.Collections.TObjectList<T>)
  public
    constructor Create(AOwnsObjects: Boolean = True);
    procedure Sort(const AComparer: IComparer<T>); reintroduce;
  end;

  TDictionary<TKey, TValue> = class
  private
    FKeys: array of TKey;
    FValues: array of TValue;
  public
    procedure Add(const AKey: TKey; const AValue: TValue);
    function TryGetValue(const AKey: TKey; out AValue: TValue): Boolean;
    function ContainsValue(const AValue: TValue): Boolean;
    procedure Clear;
  end;

implementation

constructor TObjectList<T>.Create(AOwnsObjects: Boolean);
begin
  inherited Create(AOwnsObjects);
end;

procedure TObjectList<T>.Sort(const AComparer: IComparer<T>);
begin
  inherited Sort(BridgeComparer<T>(
    function(const Left, Right: T): Integer
    begin
      Result := AComparer.Compare(Left, Right);
    end));
end;

procedure TDictionary<TKey, TValue>.Add(const AKey: TKey; const AValue: TValue);
var
  N: Integer;
begin
  N := Length(FKeys);
  SetLength(FKeys, N + 1);
  SetLength(FValues, N + 1);
  FKeys[N] := AKey;
  FValues[N] := AValue;
end;

function TDictionary<TKey, TValue>.TryGetValue(const AKey: TKey; out AValue: TValue): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FKeys) do
    if FKeys[I] = AKey then
    begin
      AValue := FValues[I];
      Exit(True);
    end;
  AValue := Default(TValue);
  Result := False;
end;

function TDictionary<TKey, TValue>.ContainsValue(const AValue: TValue): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FValues) do
    if FValues[I] = AValue then
      Exit(True);
  Result := False;
end;

procedure TDictionary<TKey, TValue>.Clear;
begin
  SetLength(FKeys, 0);
  SetLength(FValues, 0);
end;

end.
