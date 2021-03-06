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
unit edit_object_options;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, object_options, map, editor_str_consts, base_options_frame,
  monster_frame, abandoned_frame, scholar_frame, creature_set_frame,
  resource_frame, pandoras_reward_frame, local_event_frame, hero_frame,
  hero_artifacts_frame, message_frame, hero_options_frame;

type

  { TEditObjectOptions }

  TEditObjectOptions = class(TForm, IObjectOptionsVisitor)
    btOk: TButton;
    btCancel: TButton;
    lbNothingToEdit: TLabel;
    pcMain: TPageControl;
    tsArtifacts: TTabSheet;
    tsArmy: TTabSheet;
    tsObject: TTabSheet;
    tsCommon: TTabSheet;
    procedure btOkClick(Sender: TObject);
  strict private
    FMap: TVCMIMap;

    FActiveEditors: TBaseOptionsFrameList;

    procedure HideAllTabs;

    procedure SaveChanges;

    procedure VisitDwelling(AOptions: TObjectOptions);
    procedure VisitGuardedObject(AOptions: TObjectOptions);
    procedure VisitArmedObject(AOptions: TObjectOptions);
  strict private //IObjectOptionsVisitor
    procedure VisitLocalEvent(AOptions: TLocalEventOptions);//+
    procedure VisitSignBottle(AOptions: TSignBottleOptions); //+
    procedure VisitHero(AOptions: THeroOptions);
    procedure VisitMonster(AOptions: TMonsterOptions);//+
    procedure VisitSeerHut(AOptions: TSeerHutOptions);
    procedure VisitWitchHut(AOptions: TWitchHutOptions);//+
    procedure VisitScholar(AOptions: TScholarOptions);//+
    procedure VisitGarrison(AOptions: TGarrisonOptions);//+
    procedure VisitArtifact(AOptions: TArtifactOptions);//+
    procedure VisitSpellScroll(AOptions: TSpellScrollOptions);//+
    procedure VisitResource(AOptions: TResourceOptions);//+
    procedure VisitTown(AOptions: TTownOptions);
    procedure VisitAbandonedMine(AOptions: TAbandonedOptions);//+
    procedure VisitShrine(AOptions: TShrineOptions);//+
    procedure VisitPandorasBox(AOptions: TPandorasOptions); //+
    procedure VisitGrail(AOptions: TGrailOptions); //+
    procedure VisitRandomDwelling(AOptions: TRandomDwellingOptions);//+
    procedure VisitRandomDwellingLVL(AOptions: TRandomDwellingLVLOptions);//+
    procedure VisitRandomDwellingTown(AOptions: TRandomDwellingTownOptions);//+
    procedure VisitQuestGuard(AOptions:TQuestGuardOptions);
    procedure VisitHeroPlaseholder(AOptions: THeroPlaceholderOptions);

    procedure VisitOwnedObject(AOptions: TOwnedObjectOptions);//+

  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure EditObject(Obj: TMapObject);

  end;


implementation

uses
  grail_frame, flaggable_object_frame, witchhut_frame,
  shrine_frame, spellscroll_frame, dwelling_frame, root_manager;

{$R *.lfm}

{ TEditObjectOptions }

procedure TEditObjectOptions.btOkClick(Sender: TObject);
begin
  SaveChanges;
end;

constructor TEditObjectOptions.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FActiveEditors := TBaseOptionsFrameList.Create(Self);
end;

destructor TEditObjectOptions.Destroy;
begin
  FActiveEditors.Free;
  inherited Destroy;
end;

procedure TEditObjectOptions.EditObject(Obj: TMapObject);
begin
  FActiveEditors.Clear;
  FMap := Obj.GetMap;

  FActiveEditors.Map:=FMap;
  FActiveEditors.ListsManager := RootManager.ListsManager;

  HideAllTabs;
  Obj.Options.ApplyVisitor(Self);
  Caption:=Format('Object %s::%s at %d %d %d',[Obj.&type, Obj.subtype,Obj.X,Obj.Y,Obj.L]);
  ShowModal;
end;

procedure TEditObjectOptions.HideAllTabs;
var
  i: Integer;
begin
  for i := 0 to pcMain.PageCount - 1 do
  begin
    pcMain.Pages[i].TabVisible := False;
  end;

  tsCommon.TabVisible := True;
  pcMain.ActivePage := tsCommon;
end;

procedure TEditObjectOptions.SaveChanges;
begin
  FActiveEditors.Commit;
end;

procedure TEditObjectOptions.VisitDwelling(AOptions: TObjectOptions);
begin
  FActiveEditors.AddFrame(TFlaggableFrame,AOptions,tsCommon);
  FActiveEditors.AddFrame(TDwellingFrame, AOptions,tsObject);
  tsObject.TabVisible:=true;
end;

procedure TEditObjectOptions.VisitGuardedObject(AOptions: TObjectOptions);
begin
  FActiveEditors.AddFrame(TCreatureSetFrame, AOptions, tsArmy);
  tsArmy.Caption := rsGuards;
end;

procedure TEditObjectOptions.VisitArmedObject(AOptions: TObjectOptions);
begin
  FActiveEditors.AddFrame(TCreatureSetFrame, AOptions, tsArmy);
  tsArmy.Caption := rsArmy;
end;

procedure TEditObjectOptions.VisitAbandonedMine(AOptions: TAbandonedOptions);
begin
  FActiveEditors.AddFrame(TAbandonedFrame, AOptions, tsCommon);
end;

procedure TEditObjectOptions.VisitArtifact(AOptions: TArtifactOptions);
begin
  FActiveEditors.AddFrame(TMessageFrame, AOptions, tsCommon);
  VisitGuardedObject(AOptions);
end;

procedure TEditObjectOptions.VisitGarrison(AOptions: TGarrisonOptions);
begin
  VisitOwnedObject(AOptions);
  VisitArmedObject(AOptions);
end;

procedure TEditObjectOptions.VisitGrail(AOptions: TGrailOptions);
begin
  FActiveEditors.AddFrame(TGrailFrame,AOptions,tsCommon);
end;

procedure TEditObjectOptions.VisitHero(AOptions: THeroOptions);
begin
  FActiveEditors.AddFrame(THeroOptionsFrame, AOptions,tsCommon);
  VisitArmedObject(AOptions);
  FActiveEditors.AddFrame(THeroArtifactsFrame,AOptions,tsArtifacts);
end;

procedure TEditObjectOptions.VisitHeroPlaseholder(
  AOptions: THeroPlaceholderOptions);
begin
  VisitArmedObject(AOptions);
end;

procedure TEditObjectOptions.VisitLocalEvent(AOptions: TLocalEventOptions);
begin
  FActiveEditors.AddFrame(TLocalEventFrame, AOptions,tsCommon);
  FActiveEditors.AddFrame(TPandorasRewardFrame,AOptions,tsObject);
  VisitGuardedObject(AOptions);
end;

procedure TEditObjectOptions.VisitMonster(AOptions: TMonsterOptions);
begin
  FActiveEditors.AddFrame(TMonsterFrame, AOptions, tsCommon);
end;

procedure TEditObjectOptions.VisitOwnedObject(AOptions: TOwnedObjectOptions);
begin
  FActiveEditors.AddFrame(TFlaggableFrame,AOptions,tsCommon);
end;

procedure TEditObjectOptions.VisitPandorasBox(AOptions: TPandorasOptions);
begin
  FActiveEditors.AddFrame(TMessageFrame,AOptions,tsCommon);
  FActiveEditors.AddFrame(TPandorasRewardFrame,AOptions,tsObject);
  VisitGuardedObject(AOptions);
end;

procedure TEditObjectOptions.VisitQuestGuard(AOptions: TQuestGuardOptions);
begin

end;

procedure TEditObjectOptions.VisitRandomDwelling(
  AOptions: TRandomDwellingOptions);
begin
  VisitDwelling(AOptions);
end;

procedure TEditObjectOptions.VisitRandomDwellingLVL(
  AOptions: TRandomDwellingLVLOptions);
begin
  VisitDwelling(AOptions);
end;

procedure TEditObjectOptions.VisitRandomDwellingTown(
  AOptions: TRandomDwellingTownOptions);
begin
  VisitDwelling(AOptions);
end;

procedure TEditObjectOptions.VisitResource(AOptions: TResourceOptions);
begin
  FActiveEditors.AddFrame(TResourceFrame, AOptions, tsCommon);
  VisitGuardedObject(AOptions);
end;

procedure TEditObjectOptions.VisitScholar(AOptions: TScholarOptions);
begin
  FActiveEditors.AddFrame(TScholarFrame, AOptions, tsCommon);
end;

procedure TEditObjectOptions.VisitSeerHut(AOptions: TSeerHutOptions);
begin

end;

procedure TEditObjectOptions.VisitShrine(AOptions: TShrineOptions);
begin
  FActiveEditors.AddFrame(TShrineFrame,AOptions,tsCommon);
end;

procedure TEditObjectOptions.VisitSignBottle(AOptions: TSignBottleOptions);
begin
  FActiveEditors.AddFrame(TMessageFrame,AOptions,tsCommon);
end;

procedure TEditObjectOptions.VisitSpellScroll(AOptions: TSpellScrollOptions);
begin
  FActiveEditors.AddFrame(TSpellScrollFrame,AOptions,tsCommon);
  VisitGuardedObject(AOptions);
end;

procedure TEditObjectOptions.VisitTown(AOptions: TTownOptions);
begin
  VisitArmedObject(AOptions);
end;

procedure TEditObjectOptions.VisitWitchHut(AOptions: TWitchHutOptions);
begin
  FActiveEditors.AddFrame(TWitchHutFrame,AOptions,tsCommon);
end;

end.

