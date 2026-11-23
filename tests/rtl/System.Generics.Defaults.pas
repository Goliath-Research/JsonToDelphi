unit System.Generics.Defaults;

{ Names the Delphi comparer types. TComparer.Construct stores the comparison
  the generator passes in, which is an anonymous function in Pkg.Json.StubField. }

{$mode delphi}
{$H+}

interface

type
  TComparison<T> = reference to function(const Left, Right: T): Integer;

  IComparer<T> = interface
    function Compare(const Left, Right: T): Integer;
  end;

  TFuncComparer<T> = class(TInterfacedObject, IComparer<T>)
  private
    FCompare: TComparison<T>;
  public
    constructor Create(const AComparison: TComparison<T>);
    function Compare(const Left, Right: T): Integer;
  end;

  TComparer<T> = class
  public
    class function Construct(const AComparison: TComparison<T>): IComparer<T>;
  end;

implementation

constructor TFuncComparer<T>.Create(const AComparison: TComparison<T>);
begin
  inherited Create;
  FCompare := AComparison;
end;

function TFuncComparer<T>.Compare(const Left, Right: T): Integer;
begin
  Result := FCompare(Left, Right);
end;

class function TComparer<T>.Construct(const AComparison: TComparison<T>): IComparer<T>;
begin
  Result := TFuncComparer<T>.Create(AComparison);
end;

end.
