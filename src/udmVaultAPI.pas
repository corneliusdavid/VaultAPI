unit udmVaultAPI;
(*
 * as: udmVaultAPI.pas
 * by: David Cornelius
 * of: Cornelius Concepts, LLC
 * in: Delphi 11
 * on: July, 2022
 * to: encapsulate APILayer's Vault API (https://apilayer.com/marketplace/vault-api)
 *
 * "Full featured encrypted data store and key management backend."
 *)

interface

uses
  System.SysUtils, System.Classes, REST.Types, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, REST.Response.Adapter, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope,
  System.Generics.Collections;

type
  // Vault stores its data in "files" organized and accessed through a tree of "folders"
  TVaultFolder = class
  private
    FFolderName: string;
  public
    constructor Create(const NewFolderName: string);
    property FolderName: string read FFolderName write FFolderName;
  end;

  TVaultFolders = TList<TVaultFolder>;

  TVaultFile = class
  private
    FFilename: string;
    FFileSize: Integer;
    FTimeCreated: TDateTime;
    FLastUpdated: TDateTime;
  public
    constructor Create(const NewFilename: string; const NewFileSize: Integer;
                       const NewTimeCreated, NewLastUpdated: TDateTime);
    property Filename: string read FFilename write FFilename;
    property FileSize: Integer read FFileSize write FFileSize;
    property TimeCreated: TDateTime read FTimeCreated write FTimeCreated;
    property LastUpdated: TDateTime read FLastUpdated write FLastUpdated;
  end;

  TVaultFiles = TList<TVaultFile>;

  TdmVaultAPI = class(TDataModule)
    restcliVault: TRESTClient;
    reqBrowse: TRESTRequest;
    respBrowse: TRESTResponse;
    reqNewKey: TRESTRequest;
    respNewKey: TRESTResponse;
    reqGetKey: TRESTRequest;
    respGetKey: TRESTResponse;
    reqDeleteKey: TRESTRequest;
    respDeleteKey: TRESTResponse;
    reqNewContent: TRESTRequest;
    respNewContent: TRESTResponse;
    reqGetContent: TRESTRequest;
    respGetContent: TRESTResponse;
    reqDeleteContent: TRESTRequest;
    respDeleteContent: TRESTResponse;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure reqGetContentHTTPProtocolError(Sender: TCustomRESTRequest);
  private
    // required API Key for accessing your account
    FApiKey: string;
    // current encryption key used if you don't specify a custom one
    FEncryptionKey: string;
    // list of folders and files when browsing Vault
    FVaultFolders: TVaultFolders;
    FVaultFiles: TVaultFiles;
    // every API call result scrapes rate limits passed in the REST header
    FRateLimitDaily: Integer;
    FRateLimitMonthly: Integer;
    FRateLimitRemainingDay: Integer;
    FRateLimitRemainingMonth: Integer;
    // the LastStatus and LastError is set after every API call; LastError is also set in other cases
    FLastStatus: Integer;
    FLastError: string;
    // for storing the result of GetContent--and a copy of what was sent in NewContent
    FLastContent: string;
    // event handler fields
    FOnAPIResult: TNotifyEvent;
    FOnRateLimitsSet: TNotifyEvent;
    procedure SetApiKey(const Value: string);
    procedure SetApiKeyRequestParam(ARESTRequest: TRESTRequest);
    procedure SetPathRequestParam(ARESTRequest: TRESTRequest; const APath: string);
    procedure SetEncryptionKeyParam(ARESTRequest: TRESTRequest; const AEncKey: string);
    procedure SetBodyRequestParam(ARESTRequest: TRESTRequest; const ABody: string);
    procedure SetRateLimitsFromResponseHeader(ARESTResponse: TRESTResponse);
    function ParseVaultDateTime(const ADateTimeStr: string): TDateTime;
    function ExecuteRequest(ARESTRequest: TRESTRequest; ARESTResponse: TRESTResponse): Boolean;
    function BrowseRequest(const Path: string): Boolean;
  protected
    procedure DoOnAPIResult;
    procedure DoOnRateLimitsSet;
  public
    const
      ERROR_APIKEY_NOT_SET = 'Vault API Key is not set';
    function IsApiKeySet: Boolean;
    {$REGION 'encryption key'}
    /// <summary>
    ///   Gets the encryption key
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Gets the current encryption key for your account used for encrypting data with NewContent and
    ///   sets the "EncryptionKey" property to it.
    /// </remarks>
    function GetEncryptionKey: Boolean;
    /// <summary>
    ///   Deletes the encryption key
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   If there was a previously defined encryption key, it is restored and set active in your accout
    ///   and sets the "EncryptionKey" property to it.
    /// </remarks>
    function DeleteEncryptionKey: Boolean;
    /// <summary>
    ///   Generates a new encryption key
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   <para>This generates and sets active, a new encryption key for your account and sets the "EncryptionKey" property to it.
    ///   Any data sent in NewContent is encrypted with this new key--you cannot use a different key than the currently active one
    ///   to encrypt content. If you generate a new key after you called NewContent, you will get an Internal Server Error when trying to
    ///   retrieve that content until you delete the new key and restore the previous one that was used to encrypt the data.
    ///   There is an optional "Path" parameter defined in the API but it was not found to affect anything nor restrict encryption
    ///   to that path, so it is not supported in this implementation.
    /// </remarks>
    function NewEncryptionKey: Boolean;
    {$ENDREGION}
    {$REGION 'browse'}
    /// <summary>
    ///   Browses a vault with a Unix like file system structure; Path is hardcoded to the root (/).
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Fills "VaultFolder" and "VaultFiles" with the results of the browse.
    /// </remarks>
    function BrowseRoot: Boolean;
    /// <summary>
    ///   Browses a vault with a Unix like file system structure.
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Fills "VaultFolder" and "VaultFiles" with the results of the browse.
    /// </remarks>
    function BrowsePath(const Path: string): Boolean;
    {$ENDREGION}
    {$REGION 'content'}
    /// <summary>
    ///   Inserts or updates a content.
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Encrypts "AContent" with the current EncryptionKey and associates it with "APath". NOTE: If a new encryption key
    ///   is generated, this content will not be accessible and trying to get it will result in an Internal Server Error.
    /// </remarks>
    function NewContent(const AContent, APath: string; const AEncryptionKey: string = ''): Boolean;
    /// <summary>
    ///   Gets a content from a path.
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Retrieves and decrypts the data associated with "APath" using the current encryption key in your Vault account
    ///   and stores it in the "Content" property.
    ///   NOTE1: If the current encryption key was not used to encrypt the data, it will result in an Internal Server Error.
    ///   NOTE2: The Vault API supports and optional "encryption_key" but testing found it had no effect on the retrieval of
    ///   of data so it was left out of this impelementation.
    /// </remarks>
    function GetContent(const APath: string; const AEncryptionKey: string = ''): Boolean;
    /// <summary>
    ///   Deletes a content
    /// </summary>
    /// <returns>
    ///   Returns True if API call successful; False otherwise.
    /// </returns>
    /// <remarks>
    ///   Deletes the content associated with "APath".
    ///   NOTE: The Vault API supports and optional "encryption_key" but testing found it had no effect so it was left out of this impelementation.
    /// </remarks>
    function DeleteContent(const APath: string): Boolean;
    {$ENDREGION}
    // properties
    property EncryptionKey: string read FEncryptionKey write FEncryptionKey;
    property ApiKey: string read FApiKey write SetApiKey;
    property RateLimitDaily: Integer read FRateLimitDaily write FRateLimitDaily;
    property RateLimitMonthly: Integer read FRateLimitMonthly write FRateLimitMonthly;
    property RateLimitRemainingDay: Integer read FRateLimitRemainingDay write FRateLimitRemainingDay;
    property RateLimitRemainingMonth: Integer read FRateLimitRemainingMonth write FRateLimitRemainingMonth;
    property LastContent: string read FLastContent write FLastContent;
    property LastStatus: Integer read FLastStatus write FLastStatus;
    property LastError: string read FLastError write FLastError;
    property Folders: TVaultFolders read FVaultFolders;
    property Files: TVaultFiles read FVaultFiles;
    // event handlers
    property OnAPIResult: TNotifyEvent read FOnAPIResult write FOnAPIResult;
    property OnRateLimitsSet: TNotifyEvent read FOnRateLimitsSet write FOnRateLimitsSet;
  end;


implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

uses
  System.JSON, System.StrUtils;

{ TdmVaultAPI }

procedure TdmVaultAPI.DataModuleCreate(Sender: TObject);
begin
  FVaultFolders := TList<TVaultFolder>.Create;
  FVaultFiles := TList<TVaultFile>.Create;
end;

procedure TdmVaultAPI.DataModuleDestroy(Sender: TObject);
begin
  FVaultFiles.Free;
  FVaultFolders.Free;
end;

function TdmVaultAPI.IsApiKeySet: Boolean;
begin
  Result := not FApiKey.IsEmpty;
  if Result then
    FLastError := EmptyStr
  else
    FLastError := ERROR_APIKEY_NOT_SET;
end;

procedure TdmVaultAPI.SetApiKey(const Value: string);
begin
  FApiKey := Trim(Value);
end;

procedure TdmVaultAPI.SetApiKeyRequestParam(ARESTRequest: TRESTRequest);
begin
  ARESTRequest.Params.ParameterByName('apikey').Value := FApiKey;
end;

procedure TdmVaultAPI.SetBodyRequestParam(ARESTRequest: TRESTRequest; const ABody: string);
begin
  ARESTRequest.Params.ParameterByName('body').Value := ABody;
end;

procedure TdmVaultAPI.SetEncryptionKeyParam(ARESTRequest: TRESTRequest; const AEncKey: string);
begin
  ARESTRequest.Params.ParameterByName('encryption_key').Value := AEncKey;
end;

procedure TdmVaultAPI.SetPathRequestParam(ARESTRequest: TRESTRequest; const APath: string);
begin
  ARESTRequest.Params.ParameterByName('path').Value := APath;
end;

procedure TdmVaultAPI.SetRateLimitsFromResponseHeader(ARESTResponse: TRESTResponse);
begin
  TryStrToInt(ARESTResponse.Headers.Values['X-RateLimit-Limit-Day'], FRateLimitDaily);
  TryStrToInt(ARESTResponse.Headers.Values['X-RateLimit-Limit-Month'], FRateLimitMonthly);
  TryStrToInt(ARESTResponse.Headers.Values['X-RateLimit-Remaining-Day'], FRateLimitRemainingDay);
  TryStrToInt(ARESTResponse.Headers.Values['X-RateLimit-Remaining-Month'], FRateLimitRemainingMonth);
  DoOnRateLimitsSet;
end;

function TdmVaultAPI.ExecuteRequest(ARESTRequest: TRESTRequest; ARESTResponse: TRESTResponse): Boolean;
begin
  try
    ARESTRequest.Execute;

    FLastStatus := ARESTResponse.StatusCode;
    FLastError := ARESTResponse.StatusText;

    Result := ARESTResponse.Status.SuccessOK_200;
  except
    on e:Exception do begin
      FLastStatus := -1;
      FLastError := e.Message;
      Result := False;
    end;
  end;
end;

function TdmVaultAPI.NewEncryptionKey: Boolean;
begin
  Result := False;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqNewKey);
    Result := ExecuteRequest(reqNewKey, respNewKey);

    if Result then
      FEncryptionKey := respNewKey.JSONValue.P['key'].Value;
  end;
end;

function TdmVaultAPI.ParseVaultDateTime(const ADateTimeStr: string): TDateTime;
{ incoming format: 18-07-22 18:34:42 }
var
  Day, Mon, Year, Hour, Min, Sec: string;
begin
  if ADateTimeStr.Length < 17 then
    Result := 0
  else begin
    Day  := LeftStr(ADateTimeStr, 2);
    Mon  := MidStr(ADateTimeStr, 4, 2);
    Year := MidStr(ADateTimeStr, 7, 2);
    Hour := MidStr(ADateTimeStr, 10, 2);
    Min  := MidStr(ADateTimeStr, 13, 2);
    Sec  := RightStr(ADateTimeStr, 2);
    Result := EncodeDate(StrToInt(Year) + 2000, StrToInt(Mon), StrToInt(Day)) +
              EncodeTime(StrToInt(Hour), StrToInt(Min), StrToInt(Sec), 0);
  end;
end;

procedure TdmVaultAPI.reqGetContentHTTPProtocolError(Sender: TCustomRESTRequest);
begin
  FLastError := 'protocol error';
end;

function TdmVaultAPI.GetEncryptionKey: Boolean;
begin
  Result := False;
  FEncryptionKey := EmptyStr;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqGetKey);
    Result := ExecuteRequest(reqGetKey, respGetKey);
    SetRateLimitsFromResponseHeader(respGetKey);

    if Result then begin
      if respGetKey.Content.Contains('"message"') then
        FLastError := respGetKey.JSONValue.P['message'].Value;
      if respGetKey.Content.Contains('"key"') then
        FEncryptionKey := respGetKey.JSONValue.P['key'].Value;

      Result := FEncryptionKey.Length > 0;
    end;
  end;
end;

function TdmVaultAPI.DeleteEncryptionKey: Boolean;
begin
  Result := False;
  FEncryptionKey := EmptyStr;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqDeleteKey);
    Result := ExecuteRequest(reqDeleteKey, respDeleteKey);
    DoOnAPIResult;
    SetRateLimitsFromResponseHeader(respDeleteKey);

    if Result then
      if StartsText('null', respDeleteKey.Content) then
        Result := False
      else begin
        if respDeleteKey.Content.Contains('"message"') then
          FLastError := respDeleteKey.JSONValue.P['message'].Value;
        if respDeleteKey.Content.Contains('"key"') then
          FEncryptionKey := respDeleteKey.JSONValue.P['key'].Value;

        Result := FEncryptionKey.Length > 0;
      end;
  end;
end;

procedure TdmVaultAPI.DoOnAPIResult;
begin
  if Assigned(FOnAPIResult) then
    FOnAPIResult(self);
end;

procedure TdmVaultAPI.DoOnRateLimitsSet;
begin
  if Assigned(FOnRateLimitsSet) then
    FOnRateLimitsSet(self);
end;

function TdmVaultAPI.BrowseRequest(const Path: string): Boolean;
var
  BrowseResponse: TJSONValue;
  BrowseMessage: TJSONValue;
  BrowseFolders: TJSONArray;
  BrowseFiles: TJSONArray;
begin
  Result := False;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqBrowse);
    SetPathRequestParam(reqBrowse, Path);

    if ExecuteRequest(reqBrowse, respBrowse) then begin
      BrowseResponse := respBrowse.JSONValue;
      if BrowseResponse.TryGetValue<TJSONValue>('message', BrowseMessage) then
        FLastError := BrowseMessage.Value
      else begin
        FVaultFolders.Clear;
        FVaultFiles.Clear;

        BrowseFolders := TJSONArray(BrowseResponse.P['folders']);
        BrowseFiles := TJSONArray(BrowseResponse.P['files']);

        for var i := 0 to BrowseFolders.Count - 1 do
          FVaultFolders.Add(TVaultFolder.Create(BrowseFolders[i].Value));

        for var i := 0 to BrowseFiles.Count - 1 do begin
          var LFile := BrowseFiles[i];
          FVaultFiles.Add(TVaultFile.Create(LFile.P['name'].Value,
                                            LFile.P['size'].AsType<Integer>,
                                            ParseVaultDateTime(LFile.P['time_created'].Value),
                                            ParseVaultDateTime(LFile.P['last_updated'].Value)));
        end;

        SetRateLimitsFromResponseHeader(respBrowse);

        Result := True;
      end;
    end;
  end;
end;

function TdmVaultAPI.BrowseRoot: Boolean;
begin
  Result := BrowseRequest('/');
end;

function TdmVaultAPI.BrowsePath(const Path: string): Boolean;
begin
  Result := BrowseRequest(Path);
end;

function TdmVaultAPI.NewContent(const AContent, APath: string; const AEncryptionKey: string = ''): Boolean;
begin
  Result := False;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqNewContent);
    SetPathRequestParam(reqNewContent, APath);
    SetEncryptionKeyParam(reqNewContent, AEncryptionKey);

    SetBodyRequestParam(reqNewContent, AContent);

    Result := ExecuteRequest(reqNewContent, respNewContent);
    SetRateLimitsFromResponseHeader(respNewContent);

    if Result then
      FLastContent := AContent;
  end;
end;

function TdmVaultAPI.GetContent(const APath: string; const AEncryptionKey: string = ''): Boolean;
begin
  Result := False;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqGetContent);
    SetPathRequestParam(reqGetContent, APath);
    SetEncryptionKeyParam(reqGetContent, AEncryptionKey);

    Result := ExecuteRequest(reqGetContent, respGetContent);
    SetRateLimitsFromResponseHeader(respGetContent);

    if Result then
      FLastContent := respGetContent.JSONValue.P['data'].Value;
  end;
end;

function TdmVaultAPI.DeleteContent(const APath: string): Boolean;
begin
  Result := False;

  if IsApiKeySet then begin
    SetApiKeyRequestParam(reqDeleteContent);
    SetPathRequestParam(reqDeleteContent, APath);

    Result := ExecuteRequest(reqDeleteContent, respDeleteContent);
    SetRateLimitsFromResponseHeader(respDeleteContent);
  end;
end;

{ TVaultFolder }

constructor TVaultFolder.Create(const NewFolderName: string);
begin
  FFolderName := NewFolderName;
end;

{ TVaultFile }

constructor TVaultFile.Create(const NewFilename: string; const NewFileSize: Integer;
                              const NewTimeCreated, NewLastUpdated: TDateTime);
begin
  FFilename := NewFilename;
  FFileSize := NewFileSize;
  FTimeCreated := NewTimeCreated;
  FLastUpdated := NewLastUpdated;
end;

end.
