unit testeditor_utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, editor_utils;

type

  TTestEditorUtils= class(TTestCase)
  published
    procedure TestNormalizeResourceName;
    procedure TestLEtoNinPlace;
  end;

implementation

procedure TTestEditorUtils.TestNormalizeResourceName;
var path: string;
var ptrPath: PChar;
begin

  path := '/pp\bin/win32\ppc386.txt';
  UniqueString(path);
  AssertEquals('/PP/BIN/WIN32/PPC386', NormalizeResourceName(PChar(path)));
  AssertEquals('/pp\bin/win32\ppc386.txt', path);

  ptrPath := '/pp\bin/win32\ppc386.txt';
  AssertEquals(PChar('/PP/BIN/WIN32/PPC386'), NormalizeResourceName(ptrPath));
  AssertEquals(PChar('/pp\bin/win32\ppc386.txt'), ptrPath);

end;

procedure TTestEditorUtils.TestLEtoNinPlace;
var elVal: LongInt;
begin

  elVal := $FF;
  LEtoNinPlace(elVal);
  AssertEquals(LongInt($FF), elVal);

  elVal := $FF000000;
  LEtoNinPlace(elVal);
  AssertEquals(LongInt($FF000000), elVal);

  elVal := $12345678;
  LEtoNinPlace(elVal);
  AssertEquals(LongInt($12345678), elVal);

end;



initialization

  RegisterTest(TTestEditorUtils);
end.

