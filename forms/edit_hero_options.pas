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

unit edit_hero_options;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, map, lists_manager, base_options_frame, hero_frame,
  hero_definition_frame;

type

  { TEditHeroOptions }

  TEditHeroOptions = class(TForm)
    btCancel: TButton;
    btOk: TButton;
    pcMain: TPageControl;
    tsMain: TTabSheet;
    procedure btOkClick(Sender: TObject);
  private
    FEditors: TBaseOptionsFrameList;
    function GetListsManager: TListsManager;
    function GetMap: TVCMIMap;
    procedure SetListsManager(AValue: TListsManager);
    procedure SetMap(AValue: TVCMIMap);
  public
    constructor Create(TheOwner: TComponent); override;
    property Map: TVCMIMap read GetMap write SetMap;
    property ListsManager: TListsManager read GetListsManager write SetListsManager;

    procedure EditObject(AObject: THeroDefinition);
  end;


implementation

{$R *.lfm}

{ TEditHeroOptions }

procedure TEditHeroOptions.btOkClick(Sender: TObject);
begin
  FEditors.Commit;
end;

procedure TEditHeroOptions.SetMap(AValue: TVCMIMap);
begin
  FEditors.Map := AValue;
end;

procedure TEditHeroOptions.SetListsManager(AValue: TListsManager);
begin
  FEditors.ListsManager := AValue;
end;

function TEditHeroOptions.GetListsManager: TListsManager;
begin
  Result := FEditors.ListsManager;
end;

function TEditHeroOptions.GetMap: TVCMIMap;
begin
  Result := FEditors.Map;
end;

constructor TEditHeroOptions.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FEditors := TBaseOptionsFrameList.Create(Self);
end;

procedure TEditHeroOptions.EditObject(AObject: THeroDefinition);
begin
  FEditors.AddFrame(THeroDefinitionFrame, AObject, tsMain);

  ShowModal;
end;

end.

