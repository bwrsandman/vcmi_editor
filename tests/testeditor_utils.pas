unit testeditor_utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, editor_utils;

type

  TTestEditorUtils= class(TTestCase)
  published
    procedure TestNormalizeResourceName;
  end;

implementation

procedure TTestEditorUtils.TestNormalizeResourceName;
var path: string;
var ptrPath: PChar;
begin

  path := '/pp\bin/win32\ppc386.txt';
  UniqueString(path);
  AssertEquals('/PP/BIN/WIN32/PPC386', NormalizeResourceName(path));
  AssertEquals('/pp\bin/win32\ppc386.txt', path);

  ptrPath := '/pp\bin/win32\ppc386.txt';
  AssertEquals(PChar('/PP/BIN/WIN32/PPC386'), NormalizeResourceName(ptrPath));
  AssertEquals(PChar('/pp\bin/win32\ppc386.txt'), ptrPath);

end;



initialization

  RegisterTest(TTestEditorUtils);
end.

