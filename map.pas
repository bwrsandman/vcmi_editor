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
unit Map;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, Math, editor_types, terrain, editor_classes;

const
  MAP_DEFAULT_SIZE = 512;
  MAP_DEFAULT_LEVELS = 1;

  MAP_PLAYER_COUNT = 8;

type
  TVCMIMap = class;

  IMapWriter = interface
    procedure Write(AStream: TStream; AMap: TVCMIMap);
  end;


  //TMapDiscreteSize = (S = 36, M = 72, L = 108, XL = 144);

  TMapCreateParams = object
  public
    Width: Integer;
    Height: Integer;
    Levels: Integer;
  end;

  {$push}
  {$m+}

  { TCustomHero }

  TCustomHero = class (TCollectionItem)
  private
    FName: string;
    FPortrait: THeroID;
    procedure SetName(AValue: string);
    procedure SetPortrait(AValue: THeroID);
  published
    property Portrait:THeroID read FPortrait write SetPortrait;
    property Name: string read FName write SetName;
  end;

  { TCustomHeros }

  TCustomHeros = class (TArrayCollection)
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TPlayerAttr }

  TPlayerAttr = class
  private
    FAITactics: TAITactics;
    FAllowedFactions: TFactions;
    FAreAllowerFactionsSet: Boolean;
    FCanComputerPlay: boolean;
    FCanHumanPlay: boolean;
    FCustomHeros: TCustomHeros;
    FGenerateHeroAtMainTown: boolean;
    FHasMainTown: boolean;
    FIsFactionRandom: boolean;
    FMainHeroName: string;
    FMainHeroPortrait: TCustomID;
    FMainTownL: Integer;
    FMainTownType: TFactionID;
    FMainTownX: Integer;
    FMainTownY: Integer;
    FRandomHero: Boolean;
    FMainHeroClass: THeroClassID;
    FTeamId: Integer;
    procedure SetAITactics(AValue: TAITactics);
    procedure SetAreAllowerFactionsSet(AValue: Boolean);
    procedure SetCanComputerPlay(AValue: boolean);
    procedure SetCanHumanPlay(AValue: boolean);
    procedure SetGenerateHeroAtMainTown(AValue: boolean);
    procedure SetHasMainTown(AValue: boolean);
    procedure SetIsFactionRandom(AValue: boolean);
    procedure SetMainHeroName(AValue: string);
    procedure SetMainHeroPortrait(AValue: TCustomID);
    procedure SetMainTownL(AValue: Integer);
    procedure SetMainTownType(AValue: TFactionID);
    procedure SetMainTownX(AValue: Integer);
    procedure SetMainTownY(AValue: Integer);
    procedure SetRandomHero(AValue: Boolean);
    procedure SetMainHeroClass(AValue: THeroClassID);
    procedure SetTeamId(AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property AITactics: TAITactics read FAITactics write SetAITactics;
    property AreAllowerFactionsSet: Boolean read FAreAllowerFactionsSet write SetAreAllowerFactionsSet; //???
    property AllowedFactions: TFactions read FAllowedFactions;
    property IsFactionRandom: boolean read FIsFactionRandom write SetIsFactionRandom;

    property CanComputerPlay: boolean read FCanComputerPlay write SetCanComputerPlay;
    property CanHumanPlay: boolean read FCanHumanPlay write SetCanHumanPlay;

    property CustomHeros: TCustomHeros read FCustomHeros;
    property GenerateHeroAtMainTown: boolean read FGenerateHeroAtMainTown write SetGenerateHeroAtMainTown;
    property HasMainTown: boolean read FHasMainTown write SetHasMainTown;

    property MainTownType: TFactionID read FMainTownType write SetMainTownType;
    property MainTownX: Integer read FMainTownX write SetMainTownX;
    property MainTownY: Integer read FMainTownY write SetMainTownY;
    property MainTownL: Integer read FMainTownL write SetMainTownL;


    property MainHeroClass: THeroClassID read FMainHeroClass write SetMainHeroClass;
    property MainHeroPortrait:TCustomID read FMainHeroPortrait write SetMainHeroPortrait;
    property MainHeroName:string read FMainHeroName write SetMainHeroName;

    property RandomHero:Boolean read FRandomHero write SetRandomHero;
    property TeamId: Integer read FTeamId write SetTeamId;
  end;

  { TPlayerAttrs }

  TPlayerAttrs = class
  private
    FColors : array[TPlayerColor] of TPlayerAttr;
  public
    constructor Create;
    destructor Destroy; override;

    function GetAttr(color: Integer): TPlayerAttr;

  published
    property Red:TPlayerAttr index Integer(TPlayerColor.Red) read GetAttr ;
    property Blue:TPlayerAttr index Integer(TPlayerColor.Blue) read GetAttr;
    property Tan:TPlayerAttr index Integer(TPlayerColor.Tan) read GetAttr;
    property Green:TPlayerAttr index Integer(TPlayerColor.Green) read GetAttr;

    property Orange:TPlayerAttr index Integer(TPlayerColor.Orange) read GetAttr;
    property Purple:TPlayerAttr index Integer(TPlayerColor.Purple) read GetAttr;
    property Teal:TPlayerAttr index Integer(TPlayerColor.Teal) read GetAttr;
    property Pink:TPlayerAttr index Integer(TPlayerColor.Pink) read GetAttr;
  end;

  { TMapObjectTemplate }

  TMapObjectTemplate = class (TCollectionItem)
  private
    FID: TObjectTypeID;
    FMask: TStringList;
    FFilename: string;
    FSubID: TCustomID;
    FZIndex: Integer;
    function GetMask: TStrings;
    procedure SetFilename(AValue: string);
    procedure SetID(AValue: TObjectTypeID);
    procedure SetSubID(AValue: TCustomID);
    procedure SetZIndex(AValue: Integer);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
  published
    property Filename:string read FFilename write SetFilename;

    property Mask:TStrings read GetMask;

    property Id: TObjectTypeID read FID write SetID;
    property SubId: TCustomID read FSubID write SetSubID;

    property ZIndex: Integer read FZIndex write SetZIndex;
  end;

  { TMapObjectTemplates }

  TMapObjectTemplates = class (TArrayCollection)
  public
    constructor Create;

  end;

  { TMapTile }
  TMapTile = class
  strict private
    FFlags: UInt8;
    FRiverDir: UInt8;
    FRiverType: UInt8;
    FRoadDir: UInt8;
    FRoadType: UInt8;
    FTerType: TTerrainType;
    FTerSubtype: UInt8;
    procedure SetFlags(AValue: UInt8);
    procedure SetRiverDir(AValue: UInt8);
    procedure SetRiverType(AValue: UInt8);
    procedure SetRoadDir(AValue: UInt8);
    procedure SetRoadType(AValue: UInt8);
    procedure SetTerSubtype(AValue: UInt8);
    procedure SetTerType(AValue: TTerrainType);
  public
    constructor Create();

    procedure Render(mgr: TTerrainManager; X,Y: Integer); inline;
  published
    property TerType: TTerrainType read FTerType write SetTerType;
    property TerSubType: UInt8 read FTerSubtype write SetTerSubtype;

    property RiverType:UInt8 read FRiverType write SetRiverType;
    property RiverDir:UInt8 read FRiverDir write SetRiverDir;
    property RoadType:UInt8 read FRoadType write SetRoadType;
    property RoadDir:UInt8 read FRoadDir write SetRoadDir;
    property Flags:UInt8 read FFlags write SetFlags;
  end;

  { TVCMIMap }

  TVCMIMap = class (TPersistent)
  private
    FCurrentLevel: Integer;
    FDescription: string;
    FDifficulty: TDifficulty;

    FHeight: Integer;
    FHeroLevelLimit: Integer;
    FName: string;
    FPlayerAttributes: TPlayerAttrs;
    FTemplates: TMapObjectTemplates;
    FTerrainManager: TTerrainManager;
    FWigth: Integer;
    FLevels: Integer;

    FIsDirty: boolean;

    FTerrain: array of array of array of TMapTile; //levels, X, Y

    procedure Changed;

    procedure DestroyTiles();
    procedure RecreateTerrainArray;
    procedure SetCurrentLevel(AValue: Integer);
    procedure SetDescription(AValue: string);
    procedure SetDifficulty(AValue: TDifficulty);
    procedure SetHeroLevelLimit(AValue: Integer);
    procedure SetName(AValue: string);
    procedure SetTerrainManager(AValue: TTerrainManager);
  public
    //create with default params
    constructor Create(tm: TTerrainManager);
    //create with specified params
    constructor Create(tm: TTerrainManager; Params: TMapCreateParams);
    destructor Destroy; override;

    procedure SetTerrain(X, Y: Integer; TT: TTerrainType); overload; //set default terrain
    procedure SetTerrain(Level, X, Y: Integer; TT: TTerrainType; TS: UInt8); overload; //set concete terrain
    procedure FillLevel(TT: TTerrainType);

    function GetTile(Level, X, Y: Integer): TMapTile;

    //Left, Right, top, Bottom - clip rect in Tiles
    procedure Render(Left, Right, Top, Bottom: Integer);

    property CurrentLevel: Integer read FCurrentLevel write SetCurrentLevel;

    procedure SaveToStream(ADest: TStream; AWriter: IMapWriter);

    property IsDirty: Boolean read FIsDirty;

  published
    property Height: Integer read FHeight;
    property Width: Integer read FWigth;
    property Levels: Integer read FLevels;

    property Name:string read FName write SetName;
    property Description:string read FDescription write SetDescription;

    property Difficulty: TDifficulty read FDifficulty write SetDifficulty;
    property HeroLevelLimit: Integer read FHeroLevelLimit write SetHeroLevelLimit;

    property PlayerAttributes: TPlayerAttrs read FPlayerAttributes;

    property Templates: TMapObjectTemplates read FTemplates;
  end;

  {$pop}

implementation

uses editor_str_consts;

{ TMapObjectTemplates }

constructor TMapObjectTemplates.Create;
begin
  inherited Create(TMapObjectTemplate);
end;

{ TMapObjectTemplate }

constructor TMapObjectTemplate.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FMask := TStringList.Create;
end;

destructor TMapObjectTemplate.Destroy;
begin
  FMask.Free;
  inherited Destroy;
end;

function TMapObjectTemplate.GetMask: TStrings;
begin
  Result := FMask;
end;

procedure TMapObjectTemplate.SetFilename(AValue: string);
begin
  if FFilename = AValue then Exit;
  FFilename := AValue;
end;

procedure TMapObjectTemplate.SetID(AValue: TObjectTypeID);
begin
  if FID = AValue then Exit;
  FID := AValue;
end;

procedure TMapObjectTemplate.SetSubID(AValue: TCustomID);
begin
  if FSubID = AValue then Exit;
  FSubID := AValue;
end;

procedure TMapObjectTemplate.SetZIndex(AValue: Integer);
begin
  if FZIndex = AValue then Exit;
  FZIndex := AValue;
end;

{ TCustomHeros }

constructor TCustomHeros.Create;
begin
  inherited Create(TCustomHero);
end;

destructor TCustomHeros.Destroy;
begin
  inherited Destroy;
end;

{ TCustomHero }

procedure TCustomHero.SetName(AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
end;

procedure TCustomHero.SetPortrait(AValue: THeroID);
begin
  if FPortrait = AValue then Exit;
  FPortrait := AValue;
end;

constructor TPlayerAttr.Create;
begin
  FAllowedFactions := TFactions.Create;
  FCustomHeros := TCustomHeros.Create;
end;

destructor TPlayerAttr.Destroy;
begin
  FCustomHeros.Free;
  FAllowedFactions.Free;
  inherited Destroy;
end;

procedure TPlayerAttr.SetAITactics(AValue: TAITactics);
begin
  if FAITactics = AValue then Exit;
  FAITactics := AValue;
end;

procedure TPlayerAttr.SetAreAllowerFactionsSet(AValue: Boolean);
begin
  if FAreAllowerFactionsSet = AValue then Exit;
  FAreAllowerFactionsSet := AValue;
end;

procedure TPlayerAttr.SetCanComputerPlay(AValue: boolean);
begin
  if FCanComputerPlay = AValue then Exit;
  FCanComputerPlay := AValue;
end;

procedure TPlayerAttr.SetCanHumanPlay(AValue: boolean);
begin
  if FCanHumanPlay = AValue then Exit;
  FCanHumanPlay := AValue;
end;

procedure TPlayerAttr.SetGenerateHeroAtMainTown(AValue: boolean);
begin
  if FGenerateHeroAtMainTown = AValue then Exit;
  FGenerateHeroAtMainTown := AValue;
end;

procedure TPlayerAttr.SetHasMainTown(AValue: boolean);
begin
  if FHasMainTown = AValue then Exit;
  FHasMainTown := AValue;
end;

procedure TPlayerAttr.SetIsFactionRandom(AValue: boolean);
begin
  if FIsFactionRandom = AValue then Exit;
  FIsFactionRandom := AValue;
end;

procedure TPlayerAttr.SetMainTownL(AValue: Integer);
begin
  if FMainTownL = AValue then Exit;
  FMainTownL := AValue;
end;

procedure TPlayerAttr.SetMainTownType(AValue: TFactionID);
begin
  if FMainTownType = AValue then Exit;
  FMainTownType := AValue;
end;

procedure TPlayerAttr.SetMainTownX(AValue: Integer);
begin
  if FMainTownX = AValue then Exit;
  FMainTownX := AValue;
end;

procedure TPlayerAttr.SetMainTownY(AValue: Integer);
begin
  if FMainTownY = AValue then Exit;
  FMainTownY := AValue;
end;

procedure TPlayerAttr.SetRandomHero(AValue: Boolean);
begin
  if FRandomHero = AValue then Exit;
  FRandomHero := AValue;
end;

procedure TPlayerAttr.SetTeamId(AValue: Integer);
begin
  if FTeamId = AValue then Exit;
  FTeamId := AValue;
end;

procedure TPlayerAttr.SetMainHeroClass(AValue: THeroClassID);
begin
  if FMainHeroClass = AValue then Exit;
  FMainHeroClass := AValue;
end;

procedure TPlayerAttr.SetMainHeroName(AValue: string);
begin
  if FMainHeroName = AValue then Exit;
  FMainHeroName := AValue;
end;

procedure TPlayerAttr.SetMainHeroPortrait(AValue: TCustomID);
begin
  if FMainHeroPortrait = AValue then Exit;
  FMainHeroPortrait := AValue;
end;

{ TPlayerAttrs }

constructor TPlayerAttrs.Create;
var
  color: TPlayerColor;
begin
  for color in TPlayerColor do
    FColors[color] := TPlayerAttr.Create;
end;

destructor TPlayerAttrs.Destroy;
var
  color: TPlayerColor;
begin
  for color in TPlayerColor do
    FColors[color].Free;
  inherited Destroy;
end;

function TPlayerAttrs.GetAttr(color: Integer): TPlayerAttr;
begin
  Result := FColors[TPlayerColor(color)];
end;

{ TMapTile }

constructor TMapTile.Create;
begin
  //todo: set defaults
end;

procedure TMapTile.Render(mgr: TTerrainManager; X, Y: Integer);
begin
  mgr.Render(FTerType,FTerSubtype,X,Y,Flags);
end;

procedure TMapTile.SetFlags(AValue: UInt8);
begin
  if FFlags = AValue then Exit;
  FFlags := AValue;
end;

procedure TMapTile.SetRiverDir(AValue: UInt8);
begin
  if FRiverDir = AValue then Exit;
  FRiverDir := AValue;
end;

procedure TMapTile.SetRiverType(AValue: UInt8);
begin
  if FRiverType = AValue then Exit;
  FRiverType := AValue;
end;

procedure TMapTile.SetRoadDir(AValue: UInt8);
begin
  if FRoadDir = AValue then Exit;
  FRoadDir := AValue;
end;

procedure TMapTile.SetRoadType(AValue: UInt8);
begin
  if FRoadType = AValue then Exit;
  FRoadType := AValue;
end;

procedure TMapTile.SetTerSubtype(AValue: UInt8);
begin
  if FTerSubtype = AValue then Exit;
  FTerSubtype := AValue;
end;

procedure TMapTile.SetTerType(AValue: TTerrainType);
begin
  if FTerType = AValue then Exit;
  FTerType := AValue;
end;

{ TVCMIMap }

procedure TVCMIMap.Changed;
begin
  FIsDirty := True;
end;

constructor TVCMIMap.Create(tm: TTerrainManager);
var
  params: TMapCreateParams;
begin
  params.Height := MAP_DEFAULT_SIZE;
  params.Width := MAP_DEFAULT_SIZE;
  params.Levels := MAP_DEFAULT_LEVELS;

  Create(tm,params);


end;

constructor TVCMIMap.Create(tm: TTerrainManager; Params: TMapCreateParams);
begin
  SetTerrainManager(tm);

  FHeight := Params.Height;
  FWigth := Params.Width;
  FLevels := Params.Levels;

  RecreateTerrainArray;
  CurrentLevel := 0;

  Name := rsDefaultMapName;

  FIsDirty := True;

  FPlayerAttributes := TPlayerAttrs.Create;
  FTemplates := TMapObjectTemplates.Create;
end;

destructor TVCMIMap.Destroy;
begin
  FTemplates.Free;
  FPlayerAttributes.Free;
  inherited Destroy;
end;

procedure TVCMIMap.DestroyTiles;
var
  Level: Integer;
  X: Integer;
  Y: Integer;
begin
  if Length(FTerrain)<>0 then
  begin
    for Level := 0 to Length(FTerrain) - 1 do
    begin
      for X := 0 to Length(FTerrain[Level]) - 1 do
      begin
        for Y := 0 to Length(FTerrain[Level,X]) - 1 do
        begin
          FTerrain[Level][X][Y].Free();
        end;
      end;
    end;
  end;
end;

procedure TVCMIMap.FillLevel(TT: TTerrainType);
var
  x: Integer;
  Y: Integer;
begin
  for x := 0 to FWigth - 1 do
  begin
    for Y := 0 to FHeight - 1 do
    begin
      SetTerrain(x,y,tt);
    end;

  end;

end;

function TVCMIMap.GetTile(Level, X, Y: Integer): TMapTile;
begin
  Result := (FTerrain[Level][X][Y]); //todo: check
end;

procedure TVCMIMap.RecreateTerrainArray;
var
  Level: Integer;
  X: Integer;
  Y: Integer;

  tt: TTerrainType;
begin
  DestroyTiles();

  SetLength(FTerrain, FLevels);

  for Level := 0 to FLevels-1 do
  begin

    tt := FTerrainManager.GetDefaultTerrain(Level);

    SetLength(FTerrain[Level],FWigth);
    for X := 0 to FWigth - 1 do
    begin
      SetLength(FTerrain[Level, X],FHeight);
      for Y := 0 to FHeight - 1 do
      begin
        FTerrain[Level][X][Y] := TMapTile.Create();
        FTerrain[Level][X][Y].TerType :=  tt;
        FTerrain[Level][X][Y].TerSubtype := FTerrainManager.GetRandomNormalSubtype(tt);
      end;
    end;
  end;
end;

procedure TVCMIMap.Render(Left, Right, Top, Bottom: Integer);
var
  i: Integer;
  j: Integer;
begin

  Right := Min(Right, FWigth - 1);
  Bottom := Min(Bottom, FHeight - 1);

  for i := Left to Right do
  begin
    for j := Top to Bottom do
    begin
      FTerrain[FCurrentLevel][i][j].Render(FTerrainManager,i,j);
    end;
  end;
end;

procedure TVCMIMap.SaveToStream(ADest: TStream; AWriter: IMapWriter);
begin
  AWriter.Write(ADest,Self);
  FIsDirty := False;
end;

procedure TVCMIMap.SetCurrentLevel(AValue: Integer);
begin
  if FCurrentLevel = AValue then Exit; //TODO: check
  FCurrentLevel := AValue;
end;

procedure TVCMIMap.SetDescription(AValue: string);
begin
  if FDescription = AValue then Exit;
  FDescription := AValue;
  Changed;
end;

procedure TVCMIMap.SetDifficulty(AValue: TDifficulty);
begin
  if FDifficulty = AValue then Exit;
  FDifficulty := AValue;
  Changed;
end;

procedure TVCMIMap.SetHeroLevelLimit(AValue: Integer);
begin
  if FHeroLevelLimit = AValue then Exit;
  FHeroLevelLimit := AValue;
  Changed;
end;

procedure TVCMIMap.SetName(AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed;
end;

procedure TVCMIMap.SetTerrain(Level, X, Y: Integer; TT: TTerrainType; TS: UInt8
  );
begin
  FTerrain[Level][X][Y].TerType := TT;
  FTerrain[Level][X][Y].TerSubtype := TS;

  Changed;
end;

procedure TVCMIMap.SetTerrain(X, Y: Integer; TT: TTerrainType);
begin
  SetTerrain(CurrentLevel,X,Y,TT,FTerrainManager.GetRandomNormalSubtype(TT));
end;

procedure TVCMIMap.SetTerrainManager(AValue: TTerrainManager);
begin
  if FTerrainManager = AValue then Exit;
  FTerrainManager := AValue;
end;

end.

