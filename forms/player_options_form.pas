{ This file is a part of Map editor for VCMI project

  Copyright (C) 2015 Alexander Shishkin alexvins@users.sourceforge,net

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
unit player_options_form;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, map, editor_types, player_options_frame;

type

  { TPlayerOptionsForm }

  TPlayerOptionsForm = class(TForm)
    btCancel: TButton;
    btOk: TButton;
    pcMain: TPageControl;
    procedure btOkClick(Sender: TObject);
  private
    FEditors: array[TPlayerColor] of TPlayerOptionsFrame;
    FMap: TVCMIMap;
    procedure SetMap(AValue: TVCMIMap);
    procedure ReadData;
    procedure Commit;
  public
    constructor Create(TheOwner: TComponent); override;
    property Map: TVCMIMap read FMap write SetMap;
  end;

implementation

{$R *.lfm}

{ TPlayerOptionsForm }

procedure TPlayerOptionsForm.btOkClick(Sender: TObject);
begin
  Commit;
end;

procedure TPlayerOptionsForm.SetMap(AValue: TVCMIMap);
begin
  if FMap=AValue then Exit;
  FMap:=AValue;
  if Assigned(FMap) then ReadData;
end;

procedure TPlayerOptionsForm.ReadData;
var
  Player: TPlayer;
  page: TTabSheet;
begin
  for Player in TPlayerColor do
  begin
    page := FEditors[Player].Parent as TTabSheet;
    page.Caption:=FMap.ListsManager.PlayerName[Player];

    FEditors[Player].Map := FMap;
    FEditors[Player].EditObject(FMap.Players.GetAttr(Integer(Player)));
  end;
end;

procedure TPlayerOptionsForm.Commit;
var
  Player: TPlayer;
begin
  for Player in TPlayerColor do
  begin
    FEditors[Player].Commit;
  end;
end;

constructor TPlayerOptionsForm.Create(TheOwner: TComponent);
var
  Player: TPlayer;
  editor: TPlayerOptionsFrame;
  page: TTabSheet;
begin
  inherited Create(TheOwner);

  for Player in TPlayerColor do
  begin
    page := TTabSheet.Create(pcMain);
    page.PageControl := pcMain;
    page.TabVisible:=true;

    editor := TPlayerOptionsFrame.Create(page);
    editor.Visible:=true;
    editor.Parent:=page;
    editor.Align:=alClient;

    FEditors[Player] := editor;
  end;
end;

end.

