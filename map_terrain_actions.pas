{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013,2014 Alexander Shishkin alexvins@users.sourceforge,net

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

unit map_terrain_actions;

{$I compilersetup.inc}
{$MODESWITCH ADVANCEDRECORDS}
{$MODESWITCH NESTEDPROCVARS}

interface

uses
  Classes, SysUtils, Math, Map, gvector, gset, undo_map, undo_base, editor_types,
  terrain, map_actions, transitions;

type
  TTerrainBrushMode = (none, fixed, area, fill);

type
  TTileTerrainInfo = record
    X,Y: integer;
    TerType: TTerrainType;
    TerSubtype: UInt8;
    mir: UInt8;
  end;

  TTileTerrainInfos = specialize TVector<TTileTerrainInfo>;

  { TTileCompare }

  TTileCompareByCoord = class
  public
    class function c(a,b: TTileTerrainInfo): boolean;
  end;

  TTileSet = specialize TSet<TTileTerrainInfo,TTileCompareByCoord> ;


  { TTerrainBrush }

  TTerrainBrush = class abstract (TMapBrush)
  protected
    function GetMode: TTerrainBrushMode; virtual; abstract;
  public
    property Mode: TTerrainBrushMode read GetMode;
    procedure Execute(AManager: TAbstractUndoManager; AMap: TVCMIMap); override;
    procedure RenderCursor(AMap: TVCMIMap;X,Y: integer); override;
  end;


  { TFixedTerrainBrush }

  TFixedTerrainBrush = class(TTerrainBrush)
  protected
    procedure AddTile(AMap: TVCMIMap;X,Y: integer); override;
    function GetMode: TTerrainBrushMode; override;
  public
  end;

  { TAreaTerrainBrush }

  TAreaTerrainBrush = class(TTerrainBrush)
  strict private
    FStartCoord: TMapCoord;
    FEndCooord: TMapCoord;
  protected
    procedure AddTile(AMap: TVCMIMap;X,Y: integer);override;
    function GetMode: TTerrainBrushMode; override;
  public
    procedure RenderSelection(); override;
    procedure TileMouseDown(AMap: TVCMIMap;X,Y: integer);override;
    procedure TileMouseUp(AMap: TVCMIMap;X,Y: integer);override;
  end;


  { TInvalidTiles }

  TInvalidTiles = class
  public
    ForeignTiles, NativeTiles: TTileSet;
    constructor Create();
    destructor Destroy; override;

  end;

  { TEditTerrain }

  TEditTerrain = class(TMultiTileMapAction)
  strict private

    FInQueue: TTileSet;
    FOutQueue : TTileSet;

    FInvalidated: TTileSet;

    function GetTinfo(x, y: integer): TTileTerrainInfo;
    procedure UndoTile(constref Tile: TTileTerrainInfo);
    //no checking
    function GetTileInfo(x,y: Integer): TTileTerrainInfo;
    //safe, with checking
    function GetTileInfo(x,y: Integer; out Info: TTileTerrainInfo): boolean;

    function ValidateTerrainView(info: TTileTerrainInfo; pattern: TPattern; recDepth: integer = 0): TValidationResult;
    function ValidateTerrainViewInner(info: TTileTerrainInfo; pattern: TPattern; recDepth: integer = 0): TValidationResult;
  strict private
    FOldTileInfos: TTileTerrainInfos;
    FNewTileInfos: TTileTerrainInfos;

    FTerrainType: TTerrainType;
    procedure SetTerrainType(AValue: TTerrainType);

    function ExtendTileAround(X,Y: integer):TMapRect;
    function SafeExtendTileAround(X,Y: integer):TMapRect;

    procedure InvalidateTerrainViews(X,Y: integer);

    function GetInvalidTiles(center: TTileTerrainInfo): TInvalidTiles;

    procedure UpdateTerrainTypes();
    procedure	UpdateTerrainViews();
  public
    constructor Create(AMap: TVCMIMap); override;
    destructor Destroy; override;

    procedure Redo; override;
    procedure Undo; override;
    procedure Execute; override;
    function GetDescription: string; override;

    procedure AddTile(X,Y: integer); override;

    property TerrainType: TTerrainType read FTerrainType write SetTerrainType;
  end;

implementation

uses
  editor_gl, editor_consts, editor_str_consts;

{ TTileCompareByCoord }

class function TTileCompareByCoord.c(a, b: TTileTerrainInfo): boolean;
begin
  Result := (a.X < b.X) or ((a.X=b.X) and (a.y<b.Y));
end;

{ TTerrainBrush }

procedure TTerrainBrush.Execute(AManager: TAbstractUndoManager; AMap: TVCMIMap);
var
  action: TEditTerrain;
begin
  action := TEditTerrain.Create(AMap);
  action.Level := AMap.CurrentLevelIndex;
  action.TerrainType := tt;

  FillActionObjectTiles(action);

  if not Selection.IsEmpty then
    AManager.ExecuteItem(action); //execute only if there are changes

  Clear;
end;

procedure TTerrainBrush.RenderCursor(AMap: TVCMIMap; X, Y: integer);
begin

  if Mode = TTerrainBrushMode.fixed then
    inherited RenderCursor(X,Y, Size);
end;

{ TAreaTerrainBrush }

procedure TAreaTerrainBrush.AddTile(AMap: TVCMIMap; X, Y: integer);
begin
  FEndCooord.Reset(x,y);
end;

function TAreaTerrainBrush.GetMode: TTerrainBrushMode;
begin
  Result := TTerrainBrushMode.area;
end;

procedure TAreaTerrainBrush.RenderSelection;
var
  dim,cx,cy: Integer;
  r:TMapRect;
begin
  if Dragging then
  begin
    editor_gl.CurrentContextState.StartDrawingRects;
    r.SetFromCorners(FStartCoord,FEndCooord);

    cx := r.FTopLeft.X * TILE_SIZE;
    cy := r.FTopLeft.Y * TILE_SIZE;

    editor_gl.CurrentContextState.RenderRect(cx,cy,r.FWidth * TILE_SIZE ,r.FHeight * TILE_SIZE);
    editor_gl.CurrentContextState.StopDrawing;
  end;
end;

procedure TAreaTerrainBrush.TileMouseDown(AMap: TVCMIMap; X, Y: integer);
begin
  inherited TileMouseDown(amap, X, Y);
  FStartCoord.Reset(X,Y);
end;

procedure TAreaTerrainBrush.TileMouseUp(AMap: TVCMIMap; X, Y: integer);
  procedure ProcessTile(const Coord: TMapCoord; var Stop: Boolean);
  begin
    Selection.Insert(Coord);
  end;
var
  r:TMapRect;
begin
  inherited TileMouseUp(amap, X, Y);
  r.SetFromCorners(FStartCoord,FEndCooord);
  r.Iterate(@ProcessTile);
end;

{ TFixedTerrainBrush }

procedure TFixedTerrainBrush.AddTile(AMap: TVCMIMap; X, Y: integer);
  procedure ProcessTile(const Coord: TMapCoord; var Stop: Boolean);
  begin
    Selection.Insert(Coord);
  end;

var
  r: TMapRect;
begin
  r.Create();
  r.FTopLeft.Reset(X,Y);
  r.FHeight := Size;
  r.FWidth := Size;
  r.Iterate(@ProcessTile);
end;

function TFixedTerrainBrush.GetMode: TTerrainBrushMode;
begin
  Result := TTerrainBrushMode.fixed;
end;

{ TInvalidTiles }

constructor TInvalidTiles.Create;
begin
  ForeignTiles := TTileSet.Create;
  NativeTiles := TTileSet.Create;
end;

destructor TInvalidTiles.Destroy;
begin
  ForeignTiles.Free;
  NativeTiles.Free;
  inherited Destroy;
end;

{ TEditTerrain }

procedure TEditTerrain.AddTile(X, Y: integer);
var
  info: TTileTerrainInfo;
begin

  if not FMap.IsOnMap(Level,X,Y) then
  begin
    exit; //silently ignore
  end;

  info.TerType := TerrainType;
  info.TerSubtype := 0; //will be randomized by pattern selection algorithm
  info.X := X;
  info.Y := Y;
  info.mir := 0;

  FNewTileInfos.PushBack(info);

  //TODO: if brush mode = fill, ignore transitions
end;

constructor TEditTerrain.Create(AMap: TVCMIMap);
begin
  inherited Create(AMap);
  FOldTileInfos := TTileTerrainInfos.Create;
  FNewTileInfos := TTileTerrainInfos.Create;
end;

destructor TEditTerrain.Destroy;
begin
  FOldTileInfos.Free;
  FNewTileInfos.Free;

  inherited Destroy;
end;

procedure TEditTerrain.Execute;
var
  old_info, new_info: TTileTerrainInfo;

  i:SizeInt;

  it: TTileSet.TIterator;
begin
  FInQueue := TTileSet.Create;
  FOutQueue := TTileSet.Create;
  FInvalidated := TTileSet.Create;

  for i := 0 to SizeInt(FNewTileInfos.Size) - 1 do
  begin
    InvalidateTerrainViews(FNewTileInfos[i].X,FNewTileInfos[i].Y);
  end;

  for i := 0 to SizeInt(FNewTileInfos.Size) - 1 do
  begin
     FInQueue.Insert(FNewTileInfos[i]);
  end;

  UpdateTerrainTypes();
	UpdateTerrainViews();

  //process out queue

  FNewTileInfos.Clear;

  Assert(FInQueue.IsEmpty);

  it := FOutQueue.Min;

  if Assigned(it) then
  begin
    repeat
      FNewTileInfos.PushBack(it.data);
    until not it.next ;
    FreeAndNil(it);
  end;

  //save old state
  FOldTileInfos.Clear;
  for i := 0 to SizeInt(FNewTileInfos.Size) - 1 do
  begin
    new_info := FNewTileInfos[i];

    old_info := GetTileInfo(new_info.x,new_info.y);

    FOldTileInfos.PushBack(old_info);
  end;
  //apply new state
  Redo;

  FOutQueue.Free;
  FInQueue.Free;
  FInvalidated.Free;
end;

function TEditTerrain.GetDescription: string;
begin
  Result := rsEditTerrainDescription;
end;

function TEditTerrain.GetTinfo(x,y: integer): TTileTerrainInfo;
var
  tmp: TTileTerrainInfo;
  n: TTileSet.PNode;
begin
  tmp.X := x;
  tmp.Y := Y;

  n := FOutQueue.NFind(tmp);

  if Assigned(n) then
  begin
    getTinfo := n^.Data;
    exit;
  end;

  n := FInQueue.NFind(tmp);

  if Assigned(n) then
  begin
    getTinfo := n^.Data;
    exit;
  end;

  getTinfo := GetTileInfo(x,y);
end;

function TEditTerrain.GetTileInfo(x, y: Integer): TTileTerrainInfo;
var
  t: PMapTile;
begin

  t := FMap.GetTile(Level,X,Y);

  Result.X := X;
  Result.Y := Y;
  Result.TerType := t^.TerType;
  Result.TerSubtype := t^.TerSubType;
  Result.mir := t^.Flags mod 4;
end;

function TEditTerrain.GetTileInfo(x, y: Integer; out Info: TTileTerrainInfo): boolean;
begin
  Result := False;
  if FMap.IsOnMap(Level,x,y) then
  begin
    info := GetTileInfo(x,y);
    Result := true;
  end;
end;

procedure TEditTerrain.Redo;
var
  new_info: TTileTerrainInfo;
  i: Integer;
begin
  for i := 0 to FNewTileInfos.Size - 1 do
  begin
    new_info := FNewTileInfos[i];

    FMap.SetTerrain(Level,
      new_info.X,
      new_info.Y,
      new_info.TerType,
      new_info.TerSubtype,
      new_info.mir);
  end;

end;

procedure TEditTerrain.SetTerrainType(AValue: TTerrainType);
begin
  if FTerrainType = AValue then Exit;
  FTerrainType := AValue;
end;


function TEditTerrain.ExtendTileAround(X, Y: integer): TMapRect;
begin
  Result.SetFromCenter(x,y,3,3);
end;

function TEditTerrain.SafeExtendTileAround(X, Y: integer): TMapRect;
begin
  Result := TMapRect.DimOfMap(FMap).Intersect(ExtendTileAround(x,y));
end;

procedure TEditTerrain.InvalidateTerrainViews(X, Y: integer);

  procedure ProcessTile(const Coord: TMapCoord; var Stop: Boolean);
  begin
    FInvalidated.Insert(GetTinfo(Coord.X, Coord.Y));
  end;
begin
  SafeExtendTileAround(x,y).Iterate(@ProcessTile);
end;

function TEditTerrain.GetInvalidTiles(center: TTileTerrainInfo): TInvalidTiles;
var
  centerTile: TTileTerrainInfo;

  config: TTerrainPatternConfig;

  res:TInvalidTiles;

  procedure ProcessTile(const Coord: TMapCoord; var Stop: Boolean);
  const
    WATER_ROCK_P: array[0..1] of string = ('s1','s2');
    OTHER_P: array[0..1] of string = ('n2','n3');
  var
    valid: Boolean;
    curTile: TTileTerrainInfo;
    pName: string;
  begin
    curTile := GetTinfo(Coord.X, Coord.Y);

    valid := ValidateTerrainView(curTile,config.GetTerrainTypePatternById('n1')).result;

    // Special validity check for rock & water

    if valid and (centerTile.TerType<>curTile.TerType) and (curTile.TerType in [TTerrainType.water, TTerrainType.rock]) then
    begin
      for pName in WATER_ROCK_P do
      begin
         valid := not ValidateTerrainView(curTile,config.GetTerrainTypePatternById(pName)).result;
         if not valid then
           break;
      end;
    end
    // Additional validity check for non rock OR water
    else if (not valid and not (curTile.TerType in [TTerrainType.water, TTerrainType.rock])) then
    begin
      for pName in OTHER_P do
      begin
         valid := ValidateTerrainView(curTile,config.GetTerrainTypePatternById(pName)).result;
         if valid then
           break;
      end;
    end;

    if not valid then
    begin
      if curTile.TerType = centerTile.TerType then
        Res.NativeTiles.Insert(curTile)
      else
        Res.ForeignTiles.Insert(curTile)
    end;
  end;

begin
  Res := TInvalidTiles.Create;
  config :=  fmap.TerrainManager.PatternConfig;

  centerTile := GetTinfo(center.X,center.Y);

  SafeExtendTileAround(center.X,center.Y).Iterate(@ProcessTile);

  Exit(res)
end;

procedure TEditTerrain.UpdateTerrainTypes;
var
  tiles: TInvalidTiles;
  centerTile:TTileTerrainInfo;

  procedure UpdateTerrain(tile:TTileTerrainInfo; RequiresValidation: Boolean);
  begin
    tile.TerType:=centerTile.TerType;
    if RequiresValidation then
      FInQueue.Insert(tile)
    else
      FOutQueue.Insert(tile);
    InvalidateTerrainViews(tile.X,tile.Y);

  end;
const
  SHIFTS: array[1..8] of TMapCoord = (
    (x:0; y:-1),(x:-1; y:0),(x:0; y:1),(x:1; y:0),
    (x:-1; y:-1),(x:-1; y:1),(x:1; y:1),(x:1; y:-1));

var
  i: Integer;
  tmp:TTileTerrainInfo;

  it: TTileSet.TIterator;
  it2: TTileSet.PNode;
  rect: TMapRect;
  SuitableTiles: TTileSet;

  TestTile: TTileTerrainInfo;

  invalidForeignTilesCnt,invalidNativeTilesCnt,nativeTilesCntNorm: Integer;
  j: Integer;

  invalid: TInvalidTiles;
  tileRequiresValidation: Boolean;

  currentCoord: TMapCoord;
  delta: TMapCoord;
begin
   while not FInQueue.IsEmpty do
   begin
     centerTile := FInQueue.NMin^.Data;

     tiles := GetInvalidTiles(centerTile);

     it := tiles.ForeignTiles.Min;

     if Assigned(it)  then
     begin
       repeat
          UpdateTerrain(it.data, true);
       until not it.Next;
     end;

     FreeAndNil(it);

     it:=tiles.NativeTiles.Find(centerTile);

     if Assigned(it) then
     begin
       rect := SafeExtendTileAround(centerTile.x, centerTile.y);
       SuitableTiles := TTileSet.Create;

       invalidForeignTilesCnt:=MaxInt;
       invalidNativeTilesCnt:=0;

        for i := 0 to rect.FWidth - 1 do
        begin
          for j := 0 to rect.FHeight - 1 do
          begin
            TestTile := GetTinfo(rect.FTopLeft.X+i, rect.FTopLeft.Y+j);

            if TestTile.TerType <> centerTile.TerType then
            begin
              TestTile.TerType:=centerTile.TerType;
              FOutQueue.Insert(TestTile);

              invalid := GetInvalidTiles(TestTile);

              nativeTilesCntNorm:=ifthen(invalid.NativeTiles.IsEmpty, MaxInt, invalid.NativeTiles.Size);

              if (nativeTilesCntNorm > invalidNativeTilesCnt)
                or ((nativeTilesCntNorm = invalidNativeTilesCnt) and (invalid.ForeignTiles.Size < invalidForeignTilesCnt) ) then
              begin
                invalidNativeTilesCnt := nativeTilesCntNorm;
                invalidForeignTilesCnt:=invalid.ForeignTiles.Size;
                SuitableTiles.Free;
                SuitableTiles := TTileSet.Create;

                SuitableTiles.Insert(TestTile);

              end
              else if (nativeTilesCntNorm = invalidNativeTilesCnt) and (invalid.ForeignTiles.Size = invalidForeignTilesCnt) then
              begin
                SuitableTiles.Insert(TestTile);
              end;

              invalid.Free;
              FOutQueue.Delete(TestTile);
            end;
          end;
        end;

        tileRequiresValidation := invalidForeignTilesCnt > 0;

        if SuitableTiles.Size = 1 then
        begin
          UpdateTerrain(SuitableTiles.NMin^.Data, tileRequiresValidation);
        end
        else
        begin
          //first suitable tile around center

          //TODO: why is it needed?
          for delta in SHIFTS do
          begin
             currentCoord.x := centerTile.X;
             currentCoord.Y := centerTile.Y;

             currentCoord += delta;

             tmp.X:=currentCoord.X;
             tmp.Y:=currentCoord.Y;

             it2 := SuitableTiles.NFind(tmp);

             if Assigned(it2) then
             begin
                UpdateTerrain(it2^.Data, tileRequiresValidation);
                Break;
             end;
          end;
        end;
        SuitableTiles.Free;
     end
     else begin
        FInQueue.Delete(centerTile);
        FOutQueue.Insert(centerTile);
     end;
     FreeAndNil(it);

     tiles.Free;
   end;

end;

procedure TEditTerrain.UpdateTerrainViews;
var
  it: TTileSet.TIterator;
  groupPatterns: TPatternsVector;
  info: TTileTerrainInfo;
  BestPattern: Integer;
  vr: TValidationResult;
  pattern: TPattern;
  Mapping: TMapping;
  k: Integer;
  FramesPerRotation: Integer;
  Flip: Integer;
  oqIt:  TTileSet.PNode;
  FirstFrame, x, y: Integer;
begin
  it  := FInvalidated.Min;

  if Assigned(it) then
  begin
    repeat
      x := it.data.x;
      y := it.data.y;
      info := GetTinfo(x,y);
      groupPatterns := fmap.TerrainManager.PatternConfig.GetTerrainViewPatternsForGroup(TERRAIN_GROUPS[info.TerType]);

      BestPattern := -1;
      vr.result:=false;
      vr.flip:=0;

      for k := 0 to groupPatterns.Count - 1 do
      begin
        pattern := groupPatterns[k];

        vr := ValidateTerrainView(info, pattern);
        if vr.result then
        begin
          BestPattern := k;
          Break;
        end;
      end;

      if BestPattern = -1 then
      begin
        //raise Exception.Create('No pattern found');
        Continue;
      end;

      pattern := groupPatterns[BestPattern];

      if vr.transitionReplacement = '' then
      begin
        Mapping := pattern.Mappings[0];
      end
      else begin
         if vr.transitionReplacement = RULE_DIRT then
           Mapping := pattern.Mappings[0]
         else
            Mapping := pattern.Mappings[1];
      end;

      if not pattern.DiffImages then
      begin
        info.TerSubtype:=system.Random(Mapping.Upper-Mapping.Lower)+Mapping.Lower;
        info.mir:=vr.flip;
      end
      else begin

        FramesPerRotation := (Mapping.Upper-Mapping.Lower+1) div pattern.RotationTypesCount;

        Flip := ifthen((pattern.rotationTypesCount = 2) and (vr.flip = 2),1, vr.flip);
        FirstFrame := Mapping.Lower + Flip*FramesPerRotation;

        info.TerSubtype:= FirstFrame + system.Random(FramesPerRotation-1);
        info.mir:=0;
      end;

      oqIt := FOutQueue.NFind(info);

      if Assigned(oqIt) then
      begin
        FOutQueue.Delete(info); //it was queued with old values
      end;

      FOutQueue.Insert(info);

    until not it.next;
    FreeAndNil(it);
  end;
end;

procedure TEditTerrain.Undo;
var
  i: SizeInt;
begin
  for i := 0 to SizeInt(FOldTileInfos.Size) - 1 do
  begin
    UndoTile(FOldTileInfos[i]);
  end;
end;

procedure TEditTerrain.UndoTile(constref Tile: TTileTerrainInfo);
begin
  FMap.SetTerrain(Level, Tile.X, Tile.Y,Tile.TerType, Tile.TerSubtype, Tile.mir);
end;

function TEditTerrain.ValidateTerrainView(info: TTileTerrainInfo; pattern: TPattern;
  recDepth: integer): TValidationResult;
var
  flip: integer;
  flipped: TPattern;
begin
  Result.result := False;
  Result.transitionReplacement := '';
  Result.flip := 0;

  for flip := 0 to 4 - 1 do
  begin
    flipped := FMap.TerrainManager.PatternConfig.GetFlippedPattern(pattern,flip);

    Result := ValidateTerrainViewInner(info,flipped, recDepth);

    if Result.result then
    begin
      Result.flip:=flip;
      Exit;
    end;
  end;
end;

function TEditTerrain.ValidateTerrainViewInner(info: TTileTerrainInfo;
  pattern: TPattern; recDepth: integer): TValidationResult;

  function isSandType(tt: TTerrainType ): Boolean;
  begin
    case tt of
      TTerrainType.water,TTerrainType.sand, TTerrainType.rock:isSandType := True  ;
    else
      isSandType := False;
    end;
  end;

var
  centerTerGroup: TTerrainGroup;

  totalPoints: Integer;
  transitionReplacement: String;

  currentPos: TMapCoord;

  cur_tinfo: TTileTerrainInfo;

  i: Integer;
  j: Integer;
  cx: Integer;
  cy: Integer;
  isAlien: Boolean;
  topPoints: Integer;
  rule: TWeightedRule;
  patternForRule: TPattern;
  rslt: TValidationResult;

  procedure applyValidationRslt(AResult:Boolean);
  begin
    if AResult then
    begin
      topPoints := Max(topPoints,rule.points);
    end;
  end;
var

  nativeTestOk: Boolean;
  nativeTestStrongOk: Boolean;
  dirtTestOk: Boolean;
  sandTestOK: Boolean;
begin
  Result.result:=false;
  Result.flip:=0;
  Result.transitionReplacement:='';

  centerTerGroup :=TERRAIN_GROUPS[info.TerType];

  totalPoints:=0;
  transitionReplacement:='';

  for i := 0 to 9 - 1 do
  begin

    if i = 4 then
      Continue;// The center, middle cell can be skipped

    cx := info.x + (i mod 3) - 1;
    cy := info.Y + (i div 3) - 1;

    currentPos.X:=cx;
    currentPos.y:=cy;

    isAlien := false;


    if not FMap.IsOnMap(Level, cx,cy) then
    begin
      cur_tinfo := info;
    end
    else
    begin
      cur_tinfo := getTinfo(cx,cy);

      if cur_tinfo.TerType <> info.TerType then
        isAlien := True;
    end;

    // Validate all rules per cell

    topPoints:=-1;
    for j := 0 to pattern.RData[i].Count - 1 do
    begin
      rule := pattern.RData[i][j].Clone;

      if not rule.IsStandartRule then
      begin
        if (recDepth = 0) and FMap.IsOnMap(Level, currentPos.X,currentPos.Y) then
        begin
          if cur_tinfo.TerType = info.TerType  then
          begin
            patternForRule := FMap.TerrainManager.PatternConfig.GetTerrainViewPatternById(centerTerGroup, rule.name);

            if Assigned(patternForRule) then
            begin
                rslt := ValidateTerrainView(cur_tinfo,patternForRule,1);
                if rslt.result then
                begin
                  topPoints := Max(topPoints,rule.points);
                end;
            end;

          end;
          rule.free;
          Continue;
        end
        else
        begin
          rule.name := RULE_NATIVE;
        end;
      end;

      // Validate cell with the ruleset of the pattern

      nativeTestOk := ((rule.name = RULE_NATIVE) or (rule.name = RULE_NATIVE_STRONG)) and not isAlien;
      nativeTestStrongOk:=nativeTestOk;

      case centerTerGroup of
        TTerrainGroup.NORMAL:
        begin
          dirtTestOk := (rule.IsDirt or rule.IsTrans)
            and isAlien and not isSandType(cur_tinfo.TerType);

          sandTestOK := (rule.IsSand or rule.IsTrans)
           and isSandType(cur_tinfo.TerType);

          if (transitionReplacement = '')
            and (rule.IsTrans)
            and (dirtTestOk or sandTestOK) then
          begin
            if dirtTestOk then
            begin
              transitionReplacement := RULE_DIRT;
            end
            else begin
              transitionReplacement := RULE_SAND;
            end;
          end;

          if rule.IsTrans then
          begin
            applyValidationRslt(
              (dirtTestOk and (transitionReplacement <> RULE_SAND))
              or (sandTestOK and (transitionReplacement <> RULE_DIRT))
            );
          end
          else begin
            applyValidationRslt( rule.IsAny or dirtTestOk or sandTestOK or nativeTestOk);
          end;
        end;
        TTerrainGroup.DIRT:
        begin
          nativeTestOk:=rule.IsNative and not isSandType(cur_tinfo.TerType);

          sandTestOK := (rule.IsSand or rule.IsTrans) and isSandType(cur_tinfo.TerType);

          applyValidationRslt(rule.IsAny or sandTestOK or nativeTestOk or nativeTestStrongOk);
        end;
        TTerrainGroup.SAND:
        begin
          applyValidationRslt(true);
        end;
        TTerrainGroup.WATER,
        TTerrainGroup.ROCK:
        begin
          sandTestOK := (rule.IsSand or rule.IsTrans) and isAlien;
          applyValidationRslt(rule.IsAny or sandTestOK or nativeTestOk);
        end;
      end;

      rule.free;
    end;

    if topPoints = -1 then
       Exit
    else
       totalPoints+=topPoints;
  end;

  if (totalPoints >= pattern.MinPoints) and (totalPoints <= pattern.MaxPoints) then
  begin
    Result.result:=true;
    Result.transitionReplacement:=transitionReplacement;
  end

end;

end.

