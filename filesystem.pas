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
unit filesystem;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils,FileUtil,
  gmap, gqueue, fgl,
  lazutf8classes, LazFileUtils,
  vcmi_json,
  editor_classes,
  filesystem_base, lod, editor_types, fpjson, zipper ;

  {
  real FS
    ROOT\
      CONFIG\
        filesystem.json
      DATA\
      MODS\
        ONE_MOD\
          mod.json (use DATA and SPRITES paths)
          CONTENT ?
          DATA ?
            OBJECTS ?

          first.lod ?
          second.pack ?

   VFS
     ROOT\
       CONFIG\

       DATA\
         eobjects.txt
         zebjcts.txt
       SPRITES\
         foo.def
         bar.def

         smth.json
         SMTH\
           carde1
           carde2



  }

type

  TVFSDir = (DATA, SPRITES, CONFIG);
const
  VFS_PATHS: array [TVFSDir] of string = ('DATA/','SPRITES/','CONFIG/');

  VFS_FILTERS: array [TVFSDir] of TResourceTypes = (
    [TResourceType.Text],
    [TResourceType.Animation, TResourceType.Json],
    [TResourceType.Json,TResourceType.Text]);

type

  { TFilesystemConfigItem }

  TFilesystemConfigItem = class(TCollectionItem)
  private
    FPath: string;
    FType: string;
    procedure SetPath(AValue: string);
    procedure SetType(AValue: string);
  published
    property &Type:string read FType write SetType;
    property Path: string read FPath write SetPath;
  end;

  { TFilesystemConfigItems }

  TFilesystemConfigItems = class(specialize TGArrayCollection<TFilesystemConfigItem>)
  public

    constructor Create;
    destructor Destroy; override;
  end;

  { TFilesystemConfigPath }

  TFilesystemConfigPath = class(TNamedCollectionItem, IEmbeddedCollection)
  private
    FItems: TFilesystemConfigItems;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    property Items: TFilesystemConfigItems read FItems;

    //IEmbeddedCollection
    function GetCollection: TCollection;
  end;


  { TFilesystemConfig }

  TFilesystemConfig = class (specialize TGNamedCollection<TFilesystemConfigPath>)
  private

  public
    constructor Create;
    destructor Destroy; override;
  end;

  {$push}
  {$M+}

  { TBaseConfig }

  TBaseConfig = class abstract
  private
    FArtifacts: TStringList;
    FCreatures: TStringList;
    FFactions: TStringList;
    FHeroClasses: TStringList;
    FHeroes: TStringList;
    FSpells: TStringList;
    FObjects: TStringList;
    function GetArtifacts: TStrings;
    function GetConfigPath(AMetaClass: AnsiString): TStrings;
    function GetCreatures: TStrings;
    function GetFactions: TStrings;
    function GetHeroClasses: TStrings;
    function GetHeroes: TStrings;
    function GetObjects: TStrings;
    function GetSpells: TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    property ConfigPath[AMetaClass: AnsiString]:TStrings read GetConfigPath;
  published
    property Artifacts: TStrings read GetArtifacts ;
    property Creatures: TStrings read GetCreatures ;
    property Factions: TStrings read GetFactions ;
    property HeroClasses: TStrings read GetHeroClasses ;
    property Heroes: TStrings read GetHeroes;
    property Spells: TStrings read GetSpells;
    property Objects: TStrings read GetObjects;
  end;

  { TGameConfig }

  TGameConfig = class (TBaseConfig)
  public
    constructor Create;
  end;


  { TModConfig }

  TModConfig =class (TBaseConfig)
  private
    FConflicts: TStringList;
    FDepends: TStringList;
    FDescription: string;
    FDisabled: Boolean;
    FFilesystem: TFilesystemConfig;
    FID: TModId;
    FName: string;
    FPath: String;

    function GetConflicts: TStrings;
    function GetDepends: TStrings;
    procedure SetDescription(AValue: string);
    procedure SetDisabled(AValue: Boolean);
    procedure SetID(AValue: TModId);
    procedure SetName(AValue: string);
    procedure SetPath(AValue: String);
  public
    constructor Create;
    destructor Destroy; override;

    property Disabled:Boolean read FDisabled write SetDisabled;
    property ID: TModId read FID write SetID;
    //realtive (to mod root) mod path
    property Path: String read FPath write SetPath;
    procedure MayBeSetDefaultFSConfig;
  published
    //short decription
    property Name: string read FName write SetName;
    //long description
    property Description: string read FDescription write SetDescription;
    //list of IDs
    property Depends: TStrings read GetDepends;
    //list of IDs
    property Conflicts: TStrings read GetConflicts;

    property Filesystem: TFilesystemConfig read FFilesystem;

  end;
{$pop}

  TModConfigs = specialize TFPGObjectList<TModConfig>;

  TIdToModMap = specialize TFPGMap<TModId,TModConfig>;

  TIdToConfigMap = specialize TFPGMap<TModId,TBaseConfig>;

  TPathToPathMap = specialize TFPGMap<TFilename,TFilename>;

  TModQueue = specialize TQueue<TModConfig>;

  //index = index in TModConfigs
  //TModDependencyMatrix[i,j] === TModConfigs[i] depends on TModConfigs[j]
  TModDependencyMatrix = array of array of boolean;


  TLocationType = (InLod, InFile, InArchive);

  { TResLocation }

  TResLocation = object
    lt: TLocationType;
    //for files: Real path; for archive: archive filename
    path: TFilename;
    //for lods
    lod:TLod;
    FileHeader: TLodItem;
    //for archive
    archive: TUnZipper;

    procedure SetLod(ALod: TLod; AFileHeader: TLodItem);
    procedure SetFile(AFullPath: string);
    procedure SetArchive(AArchive: TUnZipper;APath: TFilename);
  end;

  TResId = record
    VFSPath: String;
    Typ: TResourceType;
  end;

  { TResIDCompare }

  TResIDCompare = class
  public
    class function c(a,b :TResId):boolean;
  end;

  TResIDToLcationMap = specialize TMap<TResId, TResLocation,TResIDCompare>;

  TArchiveList = specialize TFPGObjectList<TUnZipper>;

  { TFSManager }

  TFSManager = class (TComponent,IResourceLoader)
  private
    FConfig: TFilesystemConfig;
    FGameConfig: TGameConfig;
    FResMap: TResIDToLcationMap;
    FLodList: TLodList;
    FArchiveList: TArchiveList;

    FUnzipBuffer: TMemoryStream;

    FVpathMap: TPathToPathMap; //key subtituted by value

    FConfigMap: TIdToConfigMap; //includes core mod
    FModMap: TIdToModMap;
    FMods: TModConfigs;

    FGamePath: TStringList;

    FCurrentFilter:TResourceTypes;
    FCurrentVFSPath: string;
    FCurrentRelPath: string;
    FCurrentRootPath: string;

    FEnabledModList: TStringListUTF8;

    function GetPrivateConfigPath: string;

    procedure SetCurrentVFSPath(ACurrentVFSPath: TVFSDir);
    procedure SetCurrentVFSPath(ACurrentVFSPath: string);

    function MakeFullPath(ARootPath: string; RelPath: string):string;

    function MatchFilter(AExt: string; out AType: TResourceType): boolean;

    procedure OnLodItemFound(Alod: TLod; constref AItem: TLodItem);
    procedure ScanLod(LodRelPath: string; ARootPath: TStrings);

    procedure OnFileFound(FileIterator: TFileIterator);
    procedure OnDirectoryFound(FileIterator: TFileIterator);
    procedure OnArchiveFound(FileIterator: TFileIterator);

    procedure ScanDir(RelDir: string; ARootPath: TStrings);

    procedure ScanMap(MapPath: string; ARootPath: TStrings);

    procedure ScanArchive(item: TFilesystemConfigItem; RelDir: string; ARootPath: TStrings);

    procedure LoadFileResource(AResource: IResource; APath: TFilename);

    procedure UnzipperCreateStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);
    procedure UnzipperDoneStream(Sender : TObject; var AStream : TStream; AItem : TFullZipFileEntry);

    procedure LoadArchiveResource(AResource: IResource; AArchive: TUnZipper; AArchivePath: TFilename);

    procedure ProcessConfigItem(APath: TFilesystemConfigPath; ARootPath: TStrings);
    procedure ProcessFSConfig(AConfig: TFilesystemConfig; ARootPath: TStrings);

    procedure LoadFSConfig;
    procedure ScanFilesystem;

    procedure AddModPathsTo(sl:TStrings);

    procedure ProcessModConfig(AParentModID: AnsiString; APath: TFilename; out AModID: AnsiString);

    procedure DoScanMods(AParentModID: AnsiString; AModRoot: TFilename);

    procedure ScanMods;
    procedure ResolveDeps;

    procedure LoadGameConfig;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Load(AProgress: IProgressCallback);

    procedure LoadResource(AResource: IResource; AResType: TResourceType;
      AName: string);
  public
    property GameConfig: TGameConfig read FGameConfig; deprecated;
    property Configs:TIdToConfigMap read FConfigMap;
  end;


implementation
uses
  LazLoggerBase, editor_consts, editor_utils;

const
  GAME_PATH_CONFIG = 'gamepath.txt';

  RES_TO_EXT: array[TResourceType] of string = (
    'TXT','JSON','DEF', 'MSK'
  );

  CONFIG = 'config';

  FS_CONFIG = CONFIG+DirectorySeparator+'filesystem.json';
  FS_CONFIG_FIELD = 'filesystem';

  GAME_CONFIG = CONFIG+DirectorySeparator+'gameConfig';

  MOD_CONFIG = 'mod.json';
  MOD_ROOT = '/Content';

function ComapreModId(const a, b: TModId): integer;
begin
  Result := CompareText(a,b);
end;

{ TGameConfig }

constructor TGameConfig.Create;
begin
  inherited;
  FHeroClasses.Add('CONFIG\heroClasses');
  FArtifacts.Add('CONFIG\artifacts');
end;

{ TBaseConfig }

constructor TBaseConfig.Create;
begin
  FArtifacts := TStringList.Create;
  FCreatures := TStringList.Create;
  FFactions := TStringList.Create;
  FHeroClasses := TStringList.Create;
  FHeroes := TStringList.Create;
  FSpells := TStringList.Create;
  FObjects := TStringList.Create;
end;

destructor TBaseConfig.Destroy;
begin
  FObjects.Free;
  FSpells.Free;
  FHeroes.Free;
  FHeroClasses.Free;
  FFactions.Free;
  FCreatures.Free;
  FArtifacts.Free;

  inherited Destroy;
end;

function TBaseConfig.GetArtifacts: TStrings;
begin
  Result := FArtifacts;
end;

function TBaseConfig.GetConfigPath(AMetaClass: AnsiString): TStrings;
begin
  case AMetaClass of
    ARTIFACT_METACLASS: Result := Artifacts;
    CREATURE_METACLASS: Result := Creatures;
    FACTION_METACLASS: Result := Factions;
    HEROCLASS_METACLASS: Result := HeroClasses ;
    HERO_METACLASS: Result := Heroes ;
    OBJECT_METACLASS: Result := Objects ;
    SPELL_METACLASS: Result := Spells ;
  else
    raise Exception.CreateFmt('Invalid metaclass %s',[AMetaClass]);
  end;
end;

function TBaseConfig.GetCreatures: TStrings;
begin
  Result := FCreatures;
end;

function TBaseConfig.GetFactions: TStrings;
begin
  Result := FFactions;
end;

function TBaseConfig.GetHeroClasses: TStrings;
begin
  Result := FHeroClasses;
end;

function TBaseConfig.GetHeroes: TStrings;
begin
  Result := FHeroes;
end;

function TBaseConfig.GetObjects: TStrings;
begin
  Result := FObjects;
end;

function TBaseConfig.GetSpells: TStrings;
begin
  Result := FSpells;
end;

{ TResLocation }

procedure TResLocation.SetFile(AFullPath: string);
begin
  lt := TLocationType.InFile;
  path := AFullPath;
  lod := nil;
end;

procedure TResLocation.SetArchive(AArchive: TUnZipper; APath: TFilename);
begin
  lt := TLocationType.InArchive;
  archive := AArchive;
  path := APath;
end;

procedure TResLocation.SetLod(ALod: TLod; AFileHeader: TLodItem);
begin
  lt := TLocationType.InLod;
  lod := ALod;
  FileHeader := AFileHeader;

  path := '';
end;

{ TResIDCompare }

class function TResIDCompare.c(a, b: TResId): boolean;
var
  cres:Integer;
begin
  cres := CompareStr(a.VFSPath , b.VFSPath);
  Result := (cres< 0) or ((cres=0) and (a.Typ < b.Typ));
end;

{ TFilesystemConfigPath }

constructor TFilesystemConfigPath.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FItems := TFilesystemConfigItems.Create;
end;

destructor TFilesystemConfigPath.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TFilesystemConfigPath.GetCollection: TCollection;
begin
  Result := FItems;
end;

{ TFilesystemConfigItems }

constructor TFilesystemConfigItems.Create;
begin
  inherited Create;
end;

destructor TFilesystemConfigItems.Destroy;
begin
  inherited Destroy;
end;

{ TFilesystemConfigItem }

procedure TFilesystemConfigItem.SetPath(AValue: string);
begin
  if FPath = AValue then Exit;
  FPath := AValue;
end;

procedure TFilesystemConfigItem.SetType(AValue: string);
begin
  if FType = AValue then Exit;
  FType := AValue;
end;

{ TFilesystemConfig }

constructor TFilesystemConfig.Create;
begin
  inherited Create;
end;

destructor TFilesystemConfig.Destroy;
begin
  inherited Destroy;
end;


{ TModConfig }

constructor TModConfig.Create;
begin
  inherited;
  FFilesystem := TFilesystemConfig.Create;

  FConflicts := TStringList.Create;
  FDepends := TStringList.Create;

end;

destructor TModConfig.Destroy;
begin
  FDepends.Free;
  FConflicts.Free;

  FFilesystem.Free;
  inherited Destroy;
end;

function TModConfig.GetConflicts: TStrings;
begin
  Result := FConflicts;
end;

function TModConfig.GetDepends: TStrings;
begin
  Result := FDepends;
end;

procedure TModConfig.MayBeSetDefaultFSConfig;
var
  cur_path: TFilesystemConfigPath;
  item: TFilesystemConfigItem;
begin
  if Filesystem.Count = 0 then
  begin
    cur_path := Filesystem.Add;
    cur_path.DisplayName := '';

    item :=  cur_path.Items.Add;
    item.&Type := 'dir';
    item.Path := MOD_ROOT;
  end;
end;

procedure TModConfig.SetDescription(AValue: string);
begin
  if FDescription = AValue then Exit;
  FDescription := AValue;
end;

procedure TModConfig.SetDisabled(AValue: Boolean);
begin
  if FDisabled = AValue then Exit;
  FDisabled := AValue;
end;

procedure TModConfig.SetID(AValue: TModId);
begin
  if FID = AValue then Exit;
  FID := AValue;
end;

procedure TModConfig.SetName(AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
end;

procedure TModConfig.SetPath(AValue: String);
begin
  if FPath = AValue then Exit;
  FPath := AValue;
end;



{ TFSManager }

constructor TFSManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGamePath := TStringList.Create;
  FConfig := TFilesystemConfig.Create;
  FResMap := TResIDToLcationMap.Create;
  FLodList := TLodList.Create(True);
  FMods := TModConfigs.Create(True);
  FModMap := TIdToModMap.Create;
  FModMap.OnKeyCompare := @ComapreModId; //todo: use only FConfigMap

  FGameConfig := TGameConfig.Create;
  FVpathMap := TPathToPathMap.Create;

  FArchiveList := TArchiveList.Create(true);

  FConfigMap := TIdToConfigMap.Create;
  FConfigMap.OnKeyCompare := @ComapreModId;

  FEnabledModList := TStringListUTF8.Create;
  FEnabledModList.Sorted := false;

  FUnzipBuffer := TMemoryStream.Create;
end;

destructor TFSManager.Destroy;
begin
  FUnzipBuffer.Free;

  FEnabledModList.Free;
  FConfigMap.Free;
  FArchiveList.Free;
  FVpathMap.Free;
  FGameConfig.Free;
  FModMap.Free;
  FMods.Free;
  FLodList.Free;
  FResMap.Free;
  FConfig.Free;
  FGamePath.Free;
  inherited Destroy;
end;

procedure TFSManager.AddModPathsTo(sl: TStrings);
var
  s: String;
begin
  for s in FGamePath do
  begin
    sl.Append(IncludeTrailingPathDelimiter(s)+ 'Mods');
  end;
end;

procedure TFSManager.ProcessModConfig(AParentModID: AnsiString;
  APath: TFilename; out AModID: AnsiString);
var
  stm: TFileStreamUTF8;
  destreamer: TVCMIJSONDestreamer;
  mod_path: String;
  mod_config: TModConfig;
begin
  //APath points to mod.json

  mod_path := IncludeTrailingPathDelimiter(ExtractFileDir(APath));

  AModID := NormalizeModId(ExtractFileNameOnly(ExcludeTrailingBackslash(mod_path)));

  if AParentModID <> '' then
  begin
    AModID := AParentModID +'.'+ AModID;
  end;

  DebugLn(['Loading mod ',AModID]);

  destreamer := TVCMIJSONDestreamer.Create(nil);
  stm := TFileStreamUTF8.Create(APath,fmOpenRead or fmShareDenyWrite);
  try
    mod_config := TModConfig.Create;
    mod_config.ID := AModID;
    mod_config.Path := ExtractFileNameOnly(ExcludeTrailingBackslash(ExtractFilePath(mod_path)));
    destreamer.JSONStreamToObject(stm, mod_config,'');
    mod_config.MayBeSetDefaultFSConfig;

    if AParentModID <> '' then
    begin
      mod_config.Depends.Add(AParentModID);
    end;

    FMods.Add(mod_config);
    FModMap.Add(mod_config.ID,mod_config);
    FConfigMap.Add(mod_config.ID,mod_config);
  finally
    stm.Free;
    destreamer.Free;
  end;
end;


procedure TFSManager.OnDirectoryFound(FileIterator: TFileIterator);
var
  srch: TFileSearcher;
  p: string;

begin
  srch := TFileSearcher.Create;
  srch.OnFileFound := @OnFileFound;
  srch.OnDirectoryFound:=@OnDirectoryFound;
  try
    p := IncludeTrailingPathDelimiter(FileIterator.FileName);
    srch.Search(p);
  finally
    srch.Free;
  end;
end;

procedure TFSManager.OnArchiveFound(FileIterator: TFileIterator);
var
  arch: TUnZipper;
  i: Integer;

var
  res_id: TResId;
  res_loc: TResLocation;
  res_typ: TResourceType;

  src_file_name: string;

  file_name: String;
  file_ext: String;

  rel_path: string;

begin
  arch := TUnZipper.Create;
  arch.OnCreateStream:=@UnzipperCreateStream;
  arch.OnDoneStream:=@UnzipperDoneStream;

  FArchiveList.Add(arch); //to make it freed

  arch.FileName:=FileIterator.FileName;

  arch.Examine;

  for i := 0 to arch.Entries.Count - 1 do
  begin

    if arch.Entries[i].IsDirectory then
      Continue;

    res_loc.SetArchive(arch, arch.Entries[i].ArchiveFileName);

    src_file_name := arch.Entries[i].ArchiveFileName;

    file_ext := ExtractFileExt(src_file_name);

    if not MatchFilter(file_ext,res_typ) then
      Continue;

    rel_path := CreateRelativePath(ExtractFilePath(src_file_name), MakeFullPath(FCurrentRootPath, FCurrentRelPath)); //???

    if rel_path <> '' then
       rel_path := IncludeTrailingPathDelimiter(rel_path);

    file_name := ExtractFileNameOnly(src_file_name);

    res_id.Typ := res_typ;
    res_id.VFSPath := SetDirSeparators(UpperCase(FCurrentVFSPath+ExtractFilePath(rel_path)+file_name));//

    FResMap.Insert(res_id,res_loc);
  end;
end;

function TFSManager.GetPrivateConfigPath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

procedure TFSManager.Load(AProgress: IProgressCallback);
begin
  ScanFilesystem;
  ScanMods;
  LoadGameConfig;
end;

procedure TFSManager.LoadFileResource(AResource: IResource; APath: TFilename);
var
  stm: TFileStream;
begin
  stm := TFileStream.Create(APath,fmOpenRead or fmShareDenyWrite);
  try
    stm.Seek(0,soBeginning);
    AResource.LoadFromStream(stm);
  finally
    stm.Free;
  end;
end;

procedure TFSManager.UnzipperCreateStream(Sender: TObject;
  var AStream: TStream; AItem: TFullZipFileEntry);
begin
  FUnzipBuffer.Clear;
  AStream := FUnzipBuffer;
end;

procedure TFSManager.UnzipperDoneStream(Sender: TObject; var AStream: TStream;
  AItem: TFullZipFileEntry);
begin
  Assert(AStream = FUnzipBuffer);
end;

procedure TFSManager.LoadArchiveResource(AResource: IResource;
  AArchive: TUnZipper; AArchivePath: TFilename);
begin
  AArchive.Files.Clear;
  AArchive.Files.Add(AArchivePath);

  AArchive.UnZipAllFiles;

  FUnzipBuffer.Seek(0, soBeginning);
  AResource.LoadFromStream(FUnzipBuffer);

  AArchive.Files.Clear;
end;

procedure TFSManager.LoadFSConfig;
var
  config_res: TJsonResource;
begin
  config_res := TJsonResource.Create(FGamePath[0]+FS_CONFIG);
  try
    LoadFileResource(config_res, FGamePath[0]+FS_CONFIG);
    config_res.DestreamTo(FConfig,FS_CONFIG_FIELD);
  finally
    config_res.Free;
  end;
end;

procedure TFSManager.LoadGameConfig;
var
  res: TJsonResource;
begin
  res := TJsonResource.Create(GAME_CONFIG);
  try
    res.Load(Self);
    res.DestreamTo(FGameConfig);
  finally
    res.Free;
  end;
  FConfigMap.Add(MODID_CORE,FGameConfig);
end;

procedure TFSManager.LoadResource(AResource: IResource;
  AResType: TResourceType; AName: string);
var
  res_id: TResId;
  res_loc: TResLocation;
  it : TResIDToLcationMap.TIterator;
begin
  AName := NormalizeResourceName(PChar(AName));

  if FVpathMap.IndexOf(AName) >=0 then
  begin
    AName := FVpathMap.KeyData[AName];
  end;

  res_id.VFSPath := AName;
  res_id.Typ := AResType;

  it := FResMap.Find(res_id);

  if not Assigned(it) then
  begin
    raise Exception.Create('Res not found '+AName);
  end;

  res_loc := it.Value;
  it.Free;

  case res_loc.lt of
    TLocationType.InLod: res_loc.lod.LoadResource(AResource,res_loc.FileHeader) ;
    TLocationType.InFile: LoadFileResource(AResource,res_loc.path);
    TLocationType.InArchive: LoadArchiveResource(AResource, res_loc.archive, res_loc.path);
  end;
end;

procedure TFSManager.ScanLod(LodRelPath: string; ARootPath: TStrings);
var
  lod: TLod;
  root_path: String;
  lod_file_exists: Boolean;
  current_path: String;
begin
  //TODO: no duplicates

  LodRelPath := SetDirSeparators(LodRelPath);

  //find lod in all paths

  lod_file_exists := false;

  for root_path in ARootPath do
  begin

    current_path := MakeFullPath(root_path, LodRelPath);

    if FileExistsUTF8(current_path) then
    begin
      if lod_file_exists then
        raise Exception.Create('Duplicated lod file '+LodRelPath);

      lod_file_exists:=true;

      lod := TLod.Create(current_path);

      lod.Scan(@OnLodItemFound);

      FLodList.Add(lod);
    end;
  end;

  //if not lod_file_exists then
  //begin
  //   raise Exception.Create('Lod file not found '+LodRelPath);
  //end;

end;

procedure TFSManager.ScanMods;
var

  mod_roots, mod_paths: TStringListUTF8;
  mod_paths_config: String;
  mod_id: String;
  mod_idx: Integer;
  i: Integer;
  APath: String;

  AMod: TModConfig;
begin
  //find mods

  mod_roots := TStringListUTF8.Create;
  mod_paths := TStringListUTF8.Create;

  try
    mod_paths_config := GetPrivateConfigPath + 'modpath.txt';
    if FileExistsUTF8(mod_paths_config) then
      mod_roots.LoadFromFile(mod_paths_config);
    AddModPathsTo(mod_roots);

    for i := 0 to mod_roots.Count - 1 do
    begin
      DoScanMods('',mod_roots[i]);
    end;

    ResolveDeps;

    for i := 0 to FEnabledModList.Count - 1 do
    begin
      mod_id := NormalizeModId(FEnabledModList[i]);

      mod_idx := FModMap.IndexOf(mod_id);

      if mod_idx >=0 then
      begin
        AMod := FModMap.Data[mod_idx];
        mod_paths.Clear;

        for APath in mod_roots do
        begin
          mod_paths.Append( IncludeTrailingPathDelimiter(APath) + AMod.Path);
        end;


        for APath in mod_roots do
        begin
          ProcessFSConfig(FModMap.Data[mod_idx].Filesystem,mod_paths);
        end;
      end;
    end;

  finally
    mod_roots.Free;
    mod_paths.Free;
  end;

  //configs loaded at this point
end;

procedure TFSManager.ResolveDeps;
var
  Initial, Resolved, ToResolve: TStringList;


  function IsResolved(AConfig: TModConfig): Boolean;
  var
    mod_id: AnsiString;
  begin
    for mod_id in AConfig.Depends do
    begin
      if Resolved.IndexOf(mod_id) = 0 then
      begin
        Result := false;
        exit;
      end;
      Result := true;
    end;
  end;

var
  i: Integer;
  mod_id: AnsiString;
begin
  FEnabledModList.Clear;

  Initial := TStringList.Create;
  Initial.Sorted:=true;
  Initial.Duplicates:=dupError;

  Resolved := TStringList.Create;
  Resolved.Sorted := true;
  Resolved.Duplicates:=dupIgnore;

  ToResolve := TStringList.Create;
  ToResolve.Sorted := true;
  ToResolve.Duplicates:=dupIgnore;

  try

    for i := 0 to FModMap.Count - 1 do
      Initial.Add(FModMap.Keys[i]);

    while Initial.Count > 0 do
    begin
      ToResolve.Clear;

      i := 0;

      while i < Initial.Count do
      begin
        mod_id := Initial[i];
        if IsResolved(FModMap.KeyData[mod_id]) then
        begin
          ToResolve.Add(mod_id);
          FEnabledModList.Add(mod_id);
          Initial.Delete(i);
        end
        else
          inc(i);
      end;

      for mod_id in ToResolve do
        Resolved.Add(mod_id);
    end;
  finally
    Initial.Free;
    Resolved.Free;
    ToResolve.Free;
  end;

end;

procedure TFSManager.SetCurrentVFSPath(ACurrentVFSPath: string);
begin
  FCurrentVFSPath := SetDirSeparators(ACurrentVFSPath);
end;

procedure TFSManager.SetCurrentVFSPath(ACurrentVFSPath: TVFSDir);
begin
  SetCurrentVFSPath(VFS_PATHS[ACurrentVFSPath]);
  FCurrentFilter := VFS_FILTERS[ACurrentVFSPath];
end;

function TFSManager.MakeFullPath(ARootPath: string; RelPath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ARootPath)+ ExcludeLeadingPathDelimiter(RelPath);
  //Result := IncludeTrailingPathDelimiter(Result);
end;

function TFSManager.MatchFilter(AExt: string; out AType: TResourceType
  ): boolean;
var
  fltr: TResourceType;
begin
  Result := (FCurrentFilter = []); //empty filter = all files match
  if Result then
    Exit;
  AExt  := Trim(UpperCase(AExt));
  for fltr in FCurrentFilter do
  begin
    if AExt = '.'+RES_TO_EXT[fltr] then
    begin
      Result := True;
      AType:=  fltr;
      Exit;
    end;
  end;
end;

procedure TFSManager.OnFileFound(FileIterator: TFileIterator);
var
  res_id: TResId;
  res_loc: TResLocation;
  res_typ: TResourceType;

  file_name: String;
  file_ext: String;

  rel_path: string;
begin
  if FileIterator.IsDirectory then
    Exit;
  file_ext := ExtractFileExt(FileIterator.FileName);

  if not MatchFilter(file_ext,res_typ) then
    Exit;

  rel_path := CreateRelativePath(FileIterator.Path, MakeFullPath(FCurrentRootPath, FCurrentRelPath)); //???

  if rel_path <> '' then
     rel_path := IncludeTrailingPathDelimiter(rel_path);

  file_name := ExtractFileNameOnly(FileIterator.FileName);

  res_id.Typ := res_typ;
  res_id.VFSPath := SetDirSeparators(UpperCase(FCurrentVFSPath+ExtractFilePath(rel_path)+file_name));//

  res_loc.SetFile(FileIterator.FileName);

  FResMap.Insert(res_id,res_loc);
end;

procedure TFSManager.OnLodItemFound(Alod: TLod; constref AItem: TLodItem);
var
  file_name: String;
  file_ext: String;


  res_id: TResId;
  res_loc: TResLocation;
  res_typ: TResourceType;
begin
  file_name := AItem.Filename;
  file_name := Trim(file_name);
  file_name := upcase(file_name);

  file_ext := ExtractFileExt(file_name); //including "."

  file_name := ExtractFileNameWithoutExt(file_name);


  if not  MatchFilter(file_ext,res_typ) then
    exit;

  res_id.Typ := res_typ;
  res_id.VFSPath := FCurrentVFSPath+file_name;//

  res_loc.SetLod(Alod, AItem);

  FResMap.Insert(res_id,res_loc);

end;

procedure TFSManager.DoScanMods(AParentModID: AnsiString; AModRoot: TFilename);
var
  mod_dirs: TStringList;
  mod_dir: String;
  mod_header_path: String;

  mod_id: AnsiString;
begin


  //DebugLn(['Processing mods in ',AModRoot,', parent =',AParentModID]);

  mod_dirs := FindAllDirectories(AModRoot, False);
  try

    for mod_dir in mod_dirs do
    begin
      //DebugLn(['Processing mod dir ',mod_dir]);

      mod_header_path := IncludeTrailingPathDelimiter(mod_dir) + MOD_CONFIG;

      if FileExistsUTF8(mod_header_path) then
      begin
        //DebugLn(['Found mod config in ',mod_header_path]);

        ProcessModConfig(AParentModID, mod_header_path, mod_id);

        DoScanMods(mod_id, IncludeTrailingPathDelimiter(mod_dir)+'Mods');
      end;
    end;

  finally
    mod_dirs.Free;
  end;
end;

procedure TFSManager.ProcessConfigItem(APath: TFilesystemConfigPath;
  ARootPath: TStrings);
var
  vfs_path: String;
  item: TFilesystemConfigItem ;
  rel_path: String;
  i: Integer;
begin
  vfs_path := APath.DisplayName;

  SetCurrentVFSPath(vfs_path);

  FCurrentFilter := [TResourceType.Text,TResourceType.Animation,TResourceType.Json];

  for i := 0 to APath.Items.Count - 1 do
  begin
    item := APath.Items.Items[i];

    rel_path := item.Path;

    if rel_path = '' then
      Continue;

    case item.&Type of
      'lod':begin
        ScanLod(rel_path,ARootPath);
      end;
      'dir':begin
        if item.Path = MOD_ROOT then
        begin
          ScanArchive(item, rel_path, ARootPath);
          ScanDir(rel_path,ARootPath);
        end
        else begin
          ScanDir(rel_path,ARootPath);
        end;
      end;
      'map':begin
         ScanMap(rel_path,ARootPath);
      end;
    end;
  end;
end;

procedure TFSManager.ProcessFSConfig(AConfig: TFilesystemConfig;
  ARootPath: TStrings);
var
  i: Integer;
begin
  for i := 0 to AConfig.Count - 1 do
  begin
    ProcessConfigItem(AConfig[i],ARootPath);
  end;
end;

procedure TFSManager.ScanDir(RelDir: string; ARootPath: TStrings);
var
  srch: TFileSearcher;
  p: string;
  root_path: String;
begin

  for root_path in ARootPath do
  begin
    srch := TFileSearcher.Create;
    srch.OnFileFound := @OnFileFound;
    //srch.OnDirectoryFound:=@OnDirectoryFound;
    try
      FCurrentRelPath := RelDir;
      FCurrentRootPath := root_path;
      p := IncludeTrailingPathDelimiter(MakeFullPath(root_path,RelDir));
      srch.Search(p);
    finally
      srch.Free;
    end;
  end;
end;

procedure TFSManager.ScanMap(MapPath: string; ARootPath: TStrings);
var
  root_path: String;
  current_path: String;
  map_config: TJsonResource;
  item: TJSONEnum;
  KeyVPath: String;
  ValueVPath: TJSONStringType;
begin
  for root_path in ARootPath do
  begin
    current_path := MakeFullPath(root_path,MapPath);
     if FileExistsUTF8(current_path) then
     begin
       map_config:=TJsonResource.Create(current_path);
       LoadFileResource(map_config,current_path);

       for item in map_config.Root do
       begin
          KeyVPath :=  item.Key;
          KeyVPath := IncludeTrailingPathDelimiter(ExtractFilePath(KeyVPath)) + ExtractFileNameOnly(KeyVPath);
          KeyVPath := NormalizeResourceName(PChar(KeyVPath));

          ValueVPath := item.Value.AsString;
          ValueVPath := IncludeTrailingPathDelimiter(ExtractFilePath(ValueVPath)) + ExtractFileNameOnly(ValueVPath);
          ValueVPath := NormalizeResourceName(PChar(ValueVPath));

          FVpathMap.KeyData[KeyVPath] := ValueVPath;
       end;
       map_config.Free;
     end;

  end
end;

procedure TFSManager.ScanArchive(item: TFilesystemConfigItem; RelDir: string;
  ARootPath: TStrings);
var
  srch: TFileSearcher;
  root_path: String;
  p: String;
  smask: String;
begin
  for root_path in ARootPath do
  begin
    srch := TFileSearcher.Create;
    srch.OnFileFound := @OnArchiveFound;
    try
      FCurrentRelPath := RelDir;
      FCurrentRootPath := root_path;
      p := IncludeTrailingPathDelimiter(root_path);
      smask := 'Content.zip';
      srch.Search(p, smask);
    finally
      srch.Free;
    end;
  end;
end;

procedure TFSManager.ScanFilesystem;
var
  s: String;
  i: Integer;

begin
  s := GetPrivateConfigPath+GAME_PATH_CONFIG;
  if FileUtil.FileExistsUTF8(s) then
  begin
    FGamePath.LoadFromFile(s);
  end
  else begin
    FGamePath.Append(ExtractFilePath(ParamStr(0)));
  end;

  for i := 0 to FGamePath.Count - 1 do
  begin
    FGamePath[i] := IncludeTrailingPathDelimiter(FGamePath[i]);
  end;

  LoadFSConfig;
  ProcessFSConfig(FConfig,FGamePath);

end;

end.

