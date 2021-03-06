{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013 Alexander Shishkin alexvins@users.sourceforge,net

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit base_options_frame;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, gvector, FileUtil,  LCLType,  Forms, Controls, ComCtrls, Spin, Grids,
  editor_types,
  object_options, map,
  lists_manager, editor_consts;

type

  { TBaseOptionsFrame }

  TBaseOptionsFrame = class(TFrame,IObjectOptionsVisitor)
  private
    FListsManager: TListsManager;
    FMap: TVCMIMap;
    procedure SetListsManager(AValue: TListsManager);
    procedure SetMap(AValue: TVCMIMap);
  protected
    procedure ReadResourceSet(AParentControl: TWinControl; ASrc: TResourceSet);
    procedure SaveResourceSet(AParentControl: TWinControl; ADest: TResourceSet);

    procedure VisitNormalHero({%H-}AOptions: THeroOptions);virtual;
    procedure VisitRandomHero({%H-}AOptions: THeroOptions);virtual;
    procedure VisitPrison({%H-}AOptions: THeroOptions);virtual;

    procedure HandleStringGridKeyDown(Sender: TObject;  var Key: Word; Shift: TShiftState);
    procedure HandleStringGridResize(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    procedure Commit; virtual;

  public //IObjectOptionsVisitor
    procedure VisitLocalEvent({%H-}AOptions: TLocalEventOptions); virtual;
    procedure VisitSignBottle({%H-}AOptions: TSignBottleOptions);virtual;
    procedure VisitHero({%H-}AOptions: THeroOptions);virtual;
    procedure VisitMonster({%H-}AOptions: TMonsterOptions);virtual;
    procedure VisitSeerHut({%H-}AOptions: TSeerHutOptions);virtual;
    procedure VisitWitchHut({%H-}AOptions: TWitchHutOptions);virtual;
    procedure VisitScholar({%H-}AOptions: TScholarOptions);virtual;
    procedure VisitGarrison({%H-}AOptions: TGarrisonOptions);virtual;
    procedure VisitArtifact({%H-}AOptions: TArtifactOptions);virtual;
    procedure VisitSpellScroll({%H-}AOptions: TSpellScrollOptions);virtual;
    procedure VisitResource({%H-}AOptions: TResourceOptions);virtual;
    procedure VisitTown({%H-}AOptions: TTownOptions);virtual;
    procedure VisitAbandonedMine({%H-}AOptions: TAbandonedOptions); virtual;
    procedure VisitShrine({%H-}AOptions: TShrineOptions);virtual;
    procedure VisitPandorasBox({%H-}AOptions: TPandorasOptions);virtual;
    procedure VisitGrail({%H-}AOptions: TGrailOptions);virtual;
    procedure VisitRandomDwelling({%H-}AOptions: TRandomDwellingOptions);virtual;
    procedure VisitRandomDwellingLVL({%H-}AOptions: TRandomDwellingLVLOptions);virtual;
    procedure VisitRandomDwellingTown({%H-}AOptions: TRandomDwellingTownOptions);virtual;
    procedure VisitQuestGuard({%H-}AOptions:TQuestGuardOptions);virtual;
    procedure VisitHeroPlaseholder({%H-}AOptions: THeroPlaceholderOptions);virtual;

    procedure VisitOwnedObject({%H-}AOptions: TOwnedObjectOptions);virtual;
  public //map options

    procedure VisitHeroDefinition({%H-}AOptions: THeroDefinition); virtual;

  public
    property ListsManager: TListsManager read FListsManager write SetListsManager;
    property Map: TVCMIMap read FMap write SetMap;
  end;

  TBaseOptionsFrameClass = class of TBaseOptionsFrame;

  { TBaseOptionsFrameList }

  TBaseOptionsFrameVector = specialize TVector<TBaseOptionsFrame>;

  TBaseOptionsFrameList = class(TComponent)
  private
    FListsManager: TListsManager;
    FMap: TVCMIMap;

    FData:  TBaseOptionsFrameVector;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddFrame(AClass: TBaseOptionsFrameClass; AOptions: TObjectOptions; AParent:TTabSheet);
    procedure AddFrame(AClass: TBaseOptionsFrameClass; AOptions: THeroDefinition; AParent:TTabSheet);
    procedure Clear;

    procedure Commit;

    property ListsManager: TListsManager read FListsManager write FListsManager;
    property Map: TVCMIMap read FMap write FMap;
  end;

implementation

{ TBaseOptionsFrameList }

constructor TBaseOptionsFrameList.Create(AOwner: TComponent);
begin
  FData := TBaseOptionsFrameVector.Create;
  inherited Create(AOwner);

end;

destructor TBaseOptionsFrameList.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TBaseOptionsFrameList.AddFrame(AClass: TBaseOptionsFrameClass;
  AOptions: TObjectOptions; AParent: TTabSheet);
var
  F: TBaseOptionsFrame;
begin
  Assert(Assigned(FMap));
  Assert(Assigned(FListsManager));

  F := AClass.Create(Self);
  F.Parent := AParent;
  F.Align := alClient;
  F.ListsManager := ListsManager;
  F.Map := Map;
  AOptions.ApplyVisitor(F); //do AFTER assign properties
  FData.PushBack(F);
  AParent.TabVisible := true;
end;

procedure TBaseOptionsFrameList.AddFrame(AClass: TBaseOptionsFrameClass;
  AOptions: THeroDefinition; AParent: TTabSheet);
var
  F: TBaseOptionsFrame;
begin
  Assert(Assigned(FMap));
  Assert(Assigned(FListsManager));

  F := AClass.Create(Self);
  F.Parent := AParent;
  F.Align := alClient;
  F.ListsManager := ListsManager;
  F.Map := Map;
  F.VisitHeroDefinition(AOptions); //do AFTER assign properties
  FData.PushBack(F);
  AParent.TabVisible := true;

end;

procedure TBaseOptionsFrameList.Clear;
begin
  FData.Clear;
end;

procedure TBaseOptionsFrameList.Commit;
var
  i: SizeInt;
begin
  for i := 0 to FData.Size - 1 do
  begin
    FData[i].Commit;
  end;

end;

{$R *.lfm}

{ TBaseOptionsFrame }

procedure TBaseOptionsFrame.Commit;
begin

end;

constructor TBaseOptionsFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
end;

procedure TBaseOptionsFrame.SetListsManager(AValue: TListsManager);
begin
  if FListsManager = AValue then Exit;
  FListsManager := AValue;
end;

procedure TBaseOptionsFrame.SetMap(AValue: TVCMIMap);
begin
  if FMap=AValue then Exit;
  FMap:=AValue;
end;

procedure TBaseOptionsFrame.ReadResourceSet(AParentControl: TWinControl;
  ASrc: TResourceSet);
var
  res_type: TResType;
  c: TControl;
  res_name: String;
  editor: TCustomSpinEdit;
begin
  for res_type in TResType do
  begin
    res_name := RESOURCE_NAMES[res_type];

    c := AParentControl.FindChildControl('ed'+res_name);

    if not Assigned(c) then
    begin
      Assert(false, 'no editor control for '+res_name);
    end;

    if not (c is TCustomSpinEdit) then
    begin
      Assert(false, 'wrong conrol class for '+res_name+ ' '+c.ClassName);
    end;

    editor := TCustomSpinEdit(c);

    editor.Value := ASrc.Amount[res_type];
  end;
end;

procedure TBaseOptionsFrame.SaveResourceSet(AParentControl: TWinControl;
  ADest: TResourceSet);
var
  res_type: TResType;
  c: TControl;
  res_name: String;
  editor: TCustomSpinEdit;
begin
  for res_type in TResType do
  begin
    res_name := RESOURCE_NAMES[res_type];

    c := AParentControl.FindChildControl('ed'+res_name);

    if not Assigned(c) then
    begin
      Assert(false, 'no editor control for '+res_name);
    end;

    if not (c is TCustomSpinEdit) then
    begin
       Assert(false, 'wrong conrol class for '+res_name+ ' '+c.ClassName);
    end;

    editor := TCustomSpinEdit(c);

    ADest.Amount[res_type] := editor.Value;
  end;

end;

procedure TBaseOptionsFrame.VisitNormalHero(AOptions: THeroOptions);
begin

end;

procedure TBaseOptionsFrame.VisitRandomHero(AOptions: THeroOptions);
begin

end;

procedure TBaseOptionsFrame.VisitPrison(AOptions: THeroOptions);
begin

end;

procedure TBaseOptionsFrame.HandleStringGridKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (key = VK_DELETE) and (Shift=[]) then
  begin
    (Sender as TCustomStringGrid).DeleteRow((Sender as TCustomStringGrid).Row);
    Exit;
  end;

  if (key = VK_INSERT) and (Shift=[]) then
  begin
    (Sender as TCustomStringGrid).InsertColRow(false, (Sender as TCustomStringGrid).Row+1);
    Exit;
  end;
end;

procedure TBaseOptionsFrame.HandleStringGridResize(Sender: TObject);
var
  grid: TCustomStringGrid;
begin
  grid := Sender as TCustomStringGrid;

  if grid.EditorMode then
    grid.Editor.BoundsRect := grid.CellRect(grid.Col,grid.Row);
end;

procedure TBaseOptionsFrame.VisitAbandonedMine(AOptions: TAbandonedOptions
  );
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitArtifact(AOptions: TArtifactOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitGarrison(AOptions: TGarrisonOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitGrail(AOptions: TGrailOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitHero(AOptions: THeroOptions);
begin
  case AOptions.MapObject.GetID of
    TYPE_HERO: VisitNormalHero(AOptions);
    TYPE_PRISON: VisitPrison(AOptions);
    TYPE_RANDOMHERO: VisitRandomHero(AOptions);
  end;
end;

procedure TBaseOptionsFrame.VisitHeroPlaseholder(
  AOptions: THeroPlaceholderOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitLocalEvent(AOptions: TLocalEventOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitMonster(AOptions: TMonsterOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitOwnedObject(AOptions: TOwnedObjectOptions
  );
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitHeroDefinition(AOptions: THeroDefinition);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitPandorasBox(AOptions: TPandorasOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitQuestGuard(AOptions: TQuestGuardOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitRandomDwelling(
  AOptions: TRandomDwellingOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitRandomDwellingLVL(
  AOptions: TRandomDwellingLVLOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitRandomDwellingTown(
  AOptions: TRandomDwellingTownOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitResource(AOptions: TResourceOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitScholar(AOptions: TScholarOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitSeerHut(AOptions: TSeerHutOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitShrine(AOptions: TShrineOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitSignBottle(AOptions: TSignBottleOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitSpellScroll(AOptions: TSpellScrollOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitTown(AOptions: TTownOptions);
begin
  //do nothig
end;

procedure TBaseOptionsFrame.VisitWitchHut(AOptions: TWitchHutOptions);
begin
  //do nothig
end;

end.

