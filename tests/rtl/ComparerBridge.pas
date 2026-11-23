unit ComparerBridge;

{ Turns the generator's comparison function into the comparer type that
  Generics.Collections.TObjectList.Sort was compiled against. }

{$mode delphi}
{$H+}

interface

uses
  Generics.Defaults;

type
  TComparerBridge<T> = class(TInterfacedObject, IComparer<T>)
  private
    FCompare: TComparison<T>;
  public
    constructor Create(const ACompare: TComparison<T>);
    function Compare(const Left, Right: T): Integer;
  end;

function BridgeComparer<T>(const ACompare: TComparison<T>): IComparer<T>;

implementation

constructor TComparerBridge<T>.Create(const ACompare: TComparison<T>);
begin
  inherited Create;
  FCompare := ACompare;
end;

function TComparerBridge<T>.Compare(const Left, Right: T): Integer;
begin
  Result := FCompare(Left, Right);
end;

function BridgeComparer<T>(const ACompare: TComparison<T>): IComparer<T>;
begin
  Result := TComparerBridge<T>.Create(ACompare);
end;

end.
