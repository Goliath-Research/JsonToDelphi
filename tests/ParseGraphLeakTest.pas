program ParseGraphLeakTest;

{ These tests fail while TPkgJsonMapper.Parse drops the previous stub-class
  graph without freeing it. They pass once every stub class from an earlier
  parse is freed before the next graph is built, including when the next
  document is rejected.

  Call sites that parse more than once on one mapper:
    unigui/mobile/Mainm.pas TMainmForm.btnGenerateClick
    fmx/uMainForm.pas TMainForm.VisualizeClass
    fmx/uMainForm.pas TMainForm.PreviewUnitClick

  unigui/web/Main.pas creates a mapper, parses once and frees it. That path
  is covered by TestFreshMapperPerParseDoesNotRetain and already releases
  its single graph from TPkgJsonMapper.Destroy. }

{$mode delphiunicode}

uses
  cwstring,
  SysUtils,
  Pkg.Json.DTO,
  Pkg.Json.Mapper,
  Pkg.Json.StubField;

var
  Failures: Integer;

function HeapUsed: PtrUInt;
begin
  Result := GetFPCHeapStatus.CurrHeapUsed;
end;

function ObjectDocument(ACount: Integer): string;
var
  Index: Integer;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.Append('{');
    for Index := 0 to ACount - 1 do
    begin
      if Index > 0 then
        Builder.Append(',');
      Builder.Append('"item');
      Builder.Append(Index);
      Builder.Append('":{"value":');
      Builder.Append(Index);
      Builder.Append('}');
    end;
    Builder.Append('}');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function ArrayDocument(ACount: Integer): string;
var
  Index: Integer;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.Append('[');
    for Index := 0 to ACount - 1 do
    begin
      if Index > 0 then
        Builder.Append(',');
      Builder.Append('{"value":');
      Builder.Append(Index);
      Builder.Append('}');
    end;
    Builder.Append(']');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

procedure Fail(const AName, ADetail: string);
begin
  Inc(Failures);
  Writeln('FAIL ', AName, ': ', ADetail);
end;

procedure Pass(const AName: string);
begin
  Writeln('PASS ', AName);
end;

procedure MobileGenerate(AMapper: TPkgJsonMapper; const AJson: string);
var
  Pretty: string;
  Generated: string;
begin
  { Same calls as TMainmForm.btnGenerateClick after the short-input check:
    pretty-print the visitor's document, keep one mapper, parse, generate. }
  Pretty := TJsonDTO.PrettyPrintJSON(AJson);
  if Length(Pretty) <= 4 then
    raise Exception.Create('pretty printer dropped the document');
  AMapper.DestinationUnitName := 'RootUnit';
  AMapper.Parse(Pretty);
  Generated := AMapper.GenerateUnit;
  if (AMapper.StubClasses = nil) or (AMapper.StubClasses.Count < 2) then
    raise Exception.Create('parse did not build a class graph');
  if Pos('RootUnit', Generated) = 0 then
    raise Exception.Create('generate did not emit the destination unit');
end;

procedure TestReusedMapperRetainsPreviousObjectGraphs;
const
  Repeats = 6;
var
  Mapper: TPkgJsonMapper;
  Json: string;
  Baseline, AfterFirst, AfterRepeat, AfterFree: PtrUInt;
  OneGraph: PtrUInt;
  Extra, Retained: Int64;
  Index: Integer;
  Listed: Integer;
begin
  Json := ObjectDocument(80);
  Mapper := TPkgJsonMapper.Create;
  try
    MobileGenerate(Mapper, Json);
    AfterFirst := HeapUsed;
    Listed := Mapper.StubClasses.Count;
    for Index := 2 to Repeats do
      MobileGenerate(Mapper, Json);
    AfterRepeat := HeapUsed;
    if Mapper.StubClasses.Count <> Listed then
      raise Exception.Create('class list grew across parses');
  finally
    Mapper.Free;
  end;
  AfterFree := HeapUsed;

  { Re-measure one graph with a mapper that is freed immediately, so the
    repeated-parse delta is compared with a graph that Destroy reclaims. }
  Baseline := HeapUsed;
  Mapper := TPkgJsonMapper.Create;
  try
    MobileGenerate(Mapper, Json);
    OneGraph := HeapUsed - Baseline;
  finally
    Mapper.Free;
  end;

  Extra := Int64(AfterRepeat) - Int64(AfterFirst);
  Retained := Int64(AfterFree) - (Int64(AfterFirst) - Int64(OneGraph));
  Writeln('object-reuse extra=', Extra, ' oneGraph=', OneGraph,
    ' retainedAfterFree=', Retained, ' listed=', Listed);

  if OneGraph < 50000 then
    Fail('TestReusedMapperRetainsPreviousObjectGraphs', 'graph was too small to measure')
  else if Extra > OneGraph div 2 then
    Fail('TestReusedMapperRetainsPreviousObjectGraphs',
      'repeated Parse kept earlier class graphs (' + IntToStr(Extra) +
      ' bytes for ' + IntToStr(Repeats - 1) + ' extra parses; one graph is ' +
      IntToStr(OneGraph) + ')')
  else if Retained > OneGraph div 2 then
    Fail('TestReusedMapperRetainsPreviousObjectGraphs',
      'freeing the mapper did not reclaim earlier graphs')
  else
    Pass('TestReusedMapperRetainsPreviousObjectGraphs');
end;

procedure TestReusedMapperRetainsPreviousArrayGraphs;
const
  Repeats = 10;
var
  Mapper: TPkgJsonMapper;
  Json: string;
  Mark, OneGraph: PtrUInt;
  FreshDelta, ReusedDelta, StubExtra: Int64;
  Index: Integer;
begin
  Json := ArrayDocument(80);

  { Parse's array branch assigns the root into JSONValue and then reuses that
    variable for `for JSONValue in JsonArray`. The finally block therefore
    frees the last element, and the JSON tree itself stays allocated on every
    array parse, including a mapper that is freed after one parse. That cost
    is subtracted below so this test measures the stub-class graphs only. }
  Mark := HeapUsed;
  for Index := 1 to Repeats do
  begin
    Mapper := TPkgJsonMapper.Create;
    try
      Mapper.Parse(Json);
      if Mapper.StubClasses.Count < 2 then
        raise Exception.Create('array parse did not build a class graph');
    finally
      Mapper.Free;
    end;
  end;
  FreshDelta := Int64(HeapUsed) - Int64(Mark);

  Mark := HeapUsed;
  Mapper := TPkgJsonMapper.Create;
  try
    for Index := 1 to Repeats do
      Mapper.Parse(Json);
  finally
    Mapper.Free;
  end;
  ReusedDelta := Int64(HeapUsed) - Int64(Mark);

  Mapper := TPkgJsonMapper.Create;
  try
    OneGraph := HeapUsed;
    Mapper.Parse(Json);
    OneGraph := HeapUsed - OneGraph;
  finally
    Mapper.Free;
  end;

  StubExtra := ReusedDelta - FreshDelta;
  Writeln('array-reuse stubExtra=', StubExtra, ' freshDelta=', FreshDelta,
    ' reusedDelta=', ReusedDelta, ' oneGraph=', OneGraph);
  if OneGraph < 8000 then
    Fail('TestReusedMapperRetainsPreviousArrayGraphs', 'graph was too small to measure')
  else if StubExtra > Int64(OneGraph) div 4 then
    Fail('TestReusedMapperRetainsPreviousArrayGraphs',
      'repeated array Parse kept earlier class graphs (' + IntToStr(StubExtra) +
      ' bytes beyond the per-parse JSON tree; one graph is ' + IntToStr(OneGraph) + ')')
  else
    Pass('TestReusedMapperRetainsPreviousArrayGraphs');
end;

procedure TestRejectedDocumentStillReclaimsPreviousGraph;
var
  Mapper: TPkgJsonMapper;
  Json, Pretty: string;
  Before, AfterCreate, AfterParse, AfterReject: PtrUInt;
  Graph: PtrUInt;
begin
  Json := ObjectDocument(80);
  Before := HeapUsed;
  Mapper := TPkgJsonMapper.Create;
  try
    AfterCreate := HeapUsed;
    MobileGenerate(Mapper, Json);
    AfterParse := HeapUsed;
    Graph := AfterParse - AfterCreate;
    { A document longer than the mobile form's 4-character check, which
      PrettyPrintJSON does not reject, and which Parse then refuses. }
    Pretty := TJsonDTO.PrettyPrintJSON('{"broken":');
    try
      Mapper.DestinationUnitName := 'RootUnit';
      Mapper.Parse(Pretty);
      Fail('TestRejectedDocumentStillReclaimsPreviousGraph', 'invalid document was accepted');
      Exit;
    except
      on EJsonMapper do
        ;
    end;
    AfterReject := HeapUsed;
  finally
    Mapper.Free;
  end;

  Writeln('reject graph=', Graph, ' stillHeld=', Int64(AfterReject) - Int64(AfterCreate),
    ' before=', Before);
  if Graph < 50000 then
    Fail('TestRejectedDocumentStillReclaimsPreviousGraph', 'graph was too small to measure')
  else if Int64(AfterReject) - Int64(AfterCreate) > Int64(Graph) div 2 then
    Fail('TestRejectedDocumentStillReclaimsPreviousGraph',
      'Parse cleared the previous graph without freeing it before rejecting the document')
  else
    Pass('TestRejectedDocumentStillReclaimsPreviousGraph');
end;

procedure TestFreshMapperPerParseDoesNotRetain;
const
  Repeats = 6;
var
  Mapper: TPkgJsonMapper;
  Json: string;
  Baseline, After: PtrUInt;
  Index: Integer;
begin
  Json := ObjectDocument(40);
  Mapper := TPkgJsonMapper.Create;
  try
    Mapper.Parse(Json);
  finally
    Mapper.Free;
  end;
  Baseline := HeapUsed;
  for Index := 1 to Repeats do
  begin
    Mapper := TPkgJsonMapper.Create;
    try
      Mapper.DestinationUnitName := 'RootUnit';
      Mapper.Parse(Json);
      if Pos('RootUnit', Mapper.GenerateUnit) = 0 then
        raise Exception.Create('fresh mapper did not generate');
    finally
      Mapper.Free;
    end;
  end;
  After := HeapUsed;
  Writeln('fresh-mapper delta=', Int64(After) - Int64(Baseline));
  if Int64(After) > Int64(Baseline) + 200000 then
    Fail('TestFreshMapperPerParseDoesNotRetain',
      'creating a mapper per parse still retained ' + IntToStr(After - Baseline) + ' bytes')
  else
    Pass('TestFreshMapperPerParseDoesNotRetain');
end;

begin
  SetHeapTraceOutput('/dev/null');
  Failures := 0;
  try
    TestFreshMapperPerParseDoesNotRetain;
    TestReusedMapperRetainsPreviousObjectGraphs;
    TestReusedMapperRetainsPreviousArrayGraphs;
    TestRejectedDocumentStillReclaimsPreviousGraph;
  except
    on E: Exception do
    begin
      Inc(Failures);
      Writeln('FAIL unhandled: ', E.ClassName, ': ', E.Message);
    end;
  end;
  if Failures <> 0 then
  begin
    Writeln(Failures, ' test(s) failed');
    Halt(1);
  end;
  Writeln('all tests passed');
end.
