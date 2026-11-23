program CrossUserSettingsTests;

{ Spec for process-wide generator options.
  These checks fail while naming and date attributes are read from
  TSettings.Instance. They pass when a mobile conversion, which never
  writes options, is built from the generator defaults even if an earlier
  web conversion stored other options on that singleton. }

{$mode delphi}
{$H+}

uses
  SysUtils,
  Pkg.Json.Settings,
  Pkg.Json.Mapper;

const
  SampleJson =
    '{"user_name":"ada","profile":{"created_at":"2013-05-28T15:47:57.962Z"}}';

var
  Failures: Integer;

procedure ApplyWebCheckboxes(UsePascalCase, SuppressZeroDate, AddJsonPropertyAttributes, PostFixClassNames: Boolean);
var
  JsonSettings: TSettings;
begin
  { unigui/web/Main.pas UniFormCreate stores the singleton, and
    btnGenerateClick copies the four checkboxes onto it. }
  JsonSettings := TSettings.Instance;
  JsonSettings.UsePascalCase := UsePascalCase;
  JsonSettings.SuppressZeroDate := SuppressZeroDate;
  JsonSettings.AddJsonPropertyAttributes := AddJsonPropertyAttributes;
  JsonSettings.PostFixClassNames := PostFixClassNames;
end;

function GenerateLikeMobile(const Json: string): string;
var
  Mapper: TPkgJsonMapper;
begin
  { unigui/mobile/Mainm.pas btnGenerateClick creates a mapper and parses.
    It does not write settings. }
  Mapper := TPkgJsonMapper.Create;
  try
    Mapper.DestinationUnitName := 'RootUnit';
    Mapper.Parse(Json);
    Result := Mapper.GenerateUnit;
  finally
    Mapper.Free;
  end;
end;

procedure Check(const Name, UnitText, Marker: string; Expected: Boolean);
var
  Found: Boolean;
begin
  Found := Pos(Marker, UnitText) > 0;
  if Found <> Expected then
  begin
    Inc(Failures);
    Writeln('FAIL ', Name, ' marker ', Marker, ' expected ', Expected);
  end
  else
    Writeln('PASS ', Name, ' marker ', Marker);
end;

procedure ExpectDefaults(const Name, UnitText: string);
begin
  Check(Name, UnitText, 'property UserName:', True);
  Check(Name, UnitText, 'property CreatedAt:', True);
  Check(Name, UnitText, 'property User_Name:', False);
  Check(Name, UnitText, 'property Created_At:', False);
  Check(Name, UnitText, 'TProfile =', True);
  Check(Name, UnitText, 'TRoot =', True);
  Check(Name, UnitText, 'TProfileDTO', False);
  Check(Name, UnitText, 'TRootDTO', False);
  Check(Name, UnitText, 'SuppressZero', True);
  Check(Name, UnitText, 'TDateTime', True);
  Check(Name, UnitText, 'JSONName(''profile'')', False);
  Check(Name, UnitText, 'JSONName(''user_name'')', True);
  Check(Name, UnitText, 'JSONName(''created_at'')', True);
end;

procedure TestMobileUsesDefaultsAfterWebOptions;
var
  UnitText: string;
begin
  ApplyWebCheckboxes(False, False, True, True);
  UnitText := GenerateLikeMobile(SampleJson);
  ExpectDefaults('mobile after web checkboxes', UnitText);
  if Failures > 0 then
  begin
    Writeln('--- mobile unit ---');
    Writeln(UnitText);
    Writeln('--- end ---');
  end;
end;

procedure TestEachOptionIsRequestLocal;
var
  UnitText: string;
begin
  ApplyWebCheckboxes(False, True, False, False);
  UnitText := GenerateLikeMobile(SampleJson);
  Check('pascal case stays on for mobile', UnitText, 'property UserName:', True);
  Check('pascal case stays on for mobile', UnitText, 'property User_Name:', False);

  ApplyWebCheckboxes(True, True, False, True);
  UnitText := GenerateLikeMobile(SampleJson);
  Check('class postfix stays off for mobile', UnitText, 'TProfile =', True);
  Check('class postfix stays off for mobile', UnitText, 'TProfileDTO', False);

  ApplyWebCheckboxes(True, False, False, False);
  UnitText := GenerateLikeMobile(SampleJson);
  Check('zero dates stay suppressed for mobile', UnitText, 'SuppressZero', True);

  ApplyWebCheckboxes(True, True, True, False);
  UnitText := GenerateLikeMobile(SampleJson);
  Check('json attributes stay off the matching name', UnitText, 'JSONName(''profile'')', False);
end;

begin
  Failures := 0;
  try
    TestMobileUsesDefaultsAfterWebOptions;
    TestEachOptionIsRequestLocal;
  except
    on E: Exception do
    begin
      Inc(Failures);
      Writeln('FAIL exception ', E.ClassName, ' ', E.Message);
    end;
  end;
  if Failures = 0 then
  begin
    Writeln('ALL PASSED');
    Halt(0);
  end;
  Writeln(Failures, ' FAILED');
  Halt(1);
end.
