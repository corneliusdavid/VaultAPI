unit ufrmVaultAPIMgrMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Rtti, System.Bindings.Outputs, System.Actions, Data.Bind.Components,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.DialogService, FMX.TabControl,
  FMX.StdCtrls, FMX.Gestures, FMX.Controls.Presentation, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit,
  FMX.ActnList, FMX.Layouts, FMX.ListBox, Data.Bind.EngExt, Fmx.Bind.DBEngExt,
  Fmx.Bind.Editors,
  udmVaultAPI, FMX.Ani, FMX.Objects;

type
  TfrmVaultAPIMgrMain = class(TForm)
    VaultTabs: TTabControl;
    tabExplore: TTabItem;
    tabFile: TTabItem;
    GestureManager1: TGestureManager;
    lblBrowsePath: TLabel;
    edtBrowsePath: TEdit;
    AccountExpander: TExpander;
    btnBrowsePath: TButton;
    btnBrowseRoot: TButton;
    aclVaultMgr: TActionList;
    actBrowsePath: TAction;
    actBrowseRoot: TAction;
    lbFolders: TListBox;
    lblFolders: TLabel;
    lbFiles: TListBox;
    lblContent: TLabel;
    AniIndicator: TAniIndicator;
    lblFilePath: TLabel;
    BindingsList1: TBindingsList;
    lblContentName: TLabel;
    LinkFillControlToPropertyText: TLinkFillControlToProperty;
    mmoFile: TMemo;
    lblFileDates: TLabel;
    actPreviousTab: TPreviousTabAction;
    actNextTab: TNextTabAction;
    StyleBook: TStyleBook;
    btnBack: TSpeedButton;
    pnlEncryptKey: TPanel;
    actGetEncryptKey: TAction;
    btnGetCurrentEncryptionKey: TButton;
    btnNewEncryptionKey: TButton;
    actNewKey: TAction;
    actDeleteKey: TAction;
    btnDeleteEncryptionKey: TButton;
    chkUseCustomEncryptionKey: TCheckBox;
    edtEncryptionKey: TEdit;
    btnDeleteContent: TButton;
    btnNewContent: TButton;
    actNewContent: TAction;
    actDeleteContent: TAction;
    edtNewContentName: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    actNewContentCancel: TAction;
    actNewContentSave: TAction;
    grpStats: TGroupBox;
    lblRateLimitDay: TLabel;
    lblRateLimitMonth: TLabel;
    lblRateLimitRemainingDay: TLabel;
    lblRateLimitRemainingMonth: TLabel;
    edtAPIKey: TEdit;
    lblAPIKey: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actBrowseRootExecute(Sender: TObject);
    procedure actBrowsePathExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure edtAPIKeyExit(Sender: TObject);
    procedure lbFoldersDblClick(Sender: TObject);
    procedure lbFilesDblClick(Sender: TObject);
    procedure VaultTabsChange(Sender: TObject);
    procedure actGetEncryptKeyExecute(Sender: TObject);
    procedure actNewKeyExecute(Sender: TObject);
    procedure actDeleteKeyExecute(Sender: TObject);
    procedure actNewContentExecute(Sender: TObject);
    procedure actDeleteContentExecute(Sender: TObject);
    procedure actNewContentCancelExecute(Sender: TObject);
    procedure actNewContentSaveExecute(Sender: TObject);
    procedure AccountExpanderExpandedChanged(Sender: TObject);
  private
    const
      INI_SECTION = 'General';
      INI_APIKEY = 'APIKey';
      PARENT_FOLDER = '<Up One>';
    var
      FdmVaultAPI: TdmVaultAPI;
    function  DataFileName: string;
    function  FileFromSelected: TVaultFile;
    procedure SaveAPIKey;
    procedure LoadAPIKey;
    procedure SetAPIKey;
    procedure ClearStats;
    procedure ShowRateLimits(Sender: TObject);
    procedure SetStats(const RateLimitDay, RateLimitMonth, RateLimitRamainingDay, RateLimitRemainingMonth: Integer);
    procedure ShowFileContents;
    procedure ShowError;
    procedure ShowInfo(const InfoMsg: string);
    procedure ListFolders;
    procedure ListFiles;
    procedure BrowseCurrentPath;
    procedure BrowseAppendedPath(const SubFolderName: string);
    procedure DeleteCurrentContent;
  end;

var
  frmVaultAPIMgrMain: TfrmVaultAPIMgrMain;

implementation

{$R *.fmx}
{$R *.NmXhdpiPh.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}
{$R *.Macintosh.fmx MACOS}

uses
  System.IOUtils, System.StrUtils, System.IniFiles, System.Threading;

procedure TfrmVaultAPIMgrMain.FormCreate(Sender: TObject);
begin
  // default active tab at runtime
  VaultTabs.ActiveTab := tabExplore;
  VaultTabs.TabPosition := TTabPosition.None;
  btnBack.Text := EmptyStr;
  btnBack.Visible := False;

  FdmVaultAPI := TdmVaultAPI.Create(self);
  FdmVaultAPI.OnRateLimitsSet := ShowRateLimits;
end;

procedure TfrmVaultAPIMgrMain.AccountExpanderExpandedChanged(Sender: TObject);
begin
//  grpStats.Width := AccountExpander.Width - 40;
  lblContent.Visible := not AccountExpander.IsExpanded;
  lblBrowsePath.Visible := not AccountExpander.IsExpanded;
  edtBrowsePath.Visible := not AccountExpander.IsExpanded;
end;

procedure TfrmVaultAPIMgrMain.actBrowsePathExecute(Sender: TObject);
begin
  if edtBrowsePath.Text.IsEmpty then
    actBrowseRoot.Execute
  else
    BrowseCurrentPath;
end;

procedure TfrmVaultAPIMgrMain.actBrowseRootExecute(Sender: TObject);
begin
  edtBrowsePath.Text := '/';
  BrowseCurrentPath;
end;

procedure TfrmVaultAPIMgrMain.actDeleteContentExecute(Sender: TObject);
begin
  if lbFiles.ItemIndex > -1 then begin
    TDialogService.MessageDialog(Format('This will DELETE the selected content item named "%s".' + sLineBreak + sLineBreak +
                                        'Are you SURE you want to do this?', [lbFiles.Items[lbFiles.ItemIndex]]),
                                 TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
                                 procedure (const AResult: TModalResult)
                                 begin
                                   if AResult = mrYes then
                                     DeleteCurrentContent;
                                 end);
  end;
end;

procedure TfrmVaultAPIMgrMain.actDeleteKeyExecute(Sender: TObject);
var
  Success: Boolean;
begin
  Success := False;
  edtEncryptionKey.Text := EmptyStr;

  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;

  TTask.Create(procedure begin
      try
        if FdmVaultAPI.DeleteEncryptionKey then begin
          edtEncryptionKey.Text := FdmVaultAPI.EncryptionKey;
          Success := True;
        end;
      finally
        TThread.Synchronize(nil, procedure begin
          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if Success then
            ShowInfo(FdmVaultAPI.LastError)
          else
            if FdmVaultAPI.LastStatus = 200 then
              ShowInfo('There is no encryption key currently associated with your account. Please create a new key.')
            else
              ShowError;
        end);
      end;
    end).Start;
end;

procedure TfrmVaultAPIMgrMain.actGetEncryptKeyExecute(Sender: TObject);
var
  Success: Boolean;
begin
  Success := False;

  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;

  TTask.Create(procedure begin
      try
        if FdmVaultAPI.GetEncryptionKey then begin
          edtEncryptionKey.Text := FdmVaultAPI.EncryptionKey;
          Success := True;
        end;
      finally
        TThread.Synchronize(nil, procedure begin
          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if Success then
            ShowInfo('The current encryption key associated with your account is displayed in the text box at the bottom of the application.')
          else
            ShowError;
        end);
      end;
    end).Start;
end;

procedure TfrmVaultAPIMgrMain.actNewContentCancelExecute(Sender: TObject);
begin
  actNewContentSave.Visible := False;
  actNewContentCancel.Visible := False;
  edtNewContentName.Visible := False;
  actPreviousTab.Visible := True;
  actPreviousTab.Execute;
end;

procedure TfrmVaultAPIMgrMain.actNewContentExecute(Sender: TObject);
begin
  actNewContentSave.Visible := True;
  actNewContentCancel.Visible := True;
  edtNewContentName.Visible := True;
  edtNewContentName.Text := EmptyStr;
  mmoFile.Lines.Clear;
  lblContentName.Text := 'New Content Name:';
  lblFileDates.Text := '< not yet saved >';
  actPreviousTab.Visible := False;
  actNextTab.Execute;
end;

procedure TfrmVaultAPIMgrMain.actNewContentSaveExecute(Sender: TObject);
var
  Success: Boolean;
  LPath: string;
  LContent: string;
  LEncryptionKey: string;
begin
  Success := False;

  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;

  LPath := edtBrowsePath.Text;
  if not EndsText('/', LPath) then
    LPath := LPath + '/';
  LPath := LPath + edtNewContentName.Text;
  LContent := mmoFile.Text;

  if chkUseCustomEncryptionKey.IsChecked then
    LEncryptionKey := edtEncryptionKey.Text
  else
    LEncryptionKey := EmptyStr;

  TTask.Create(procedure begin
      try
        if FdmVaultAPI.NewContent(LContent, LPath, LEncryptionKey) then
          Success := True;
      finally
        TThread.Synchronize(nil, procedure begin
          actNewContentCancel.Visible := False;
          actNewContentSave.Visible := False;
          edtNewContentName.Visible := False;
          actPreviousTab.Execute;

          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if Success then begin
            if FdmVaultAPI.BrowsePath(edtBrowsePath.Text) then
              ListFiles;
            ShowInfo('The new named content has been added.');
          end else
            ShowError;
        end);
      end;
    end).Start;
end;

procedure TfrmVaultAPIMgrMain.actNewKeyExecute(Sender: TObject);
var
  Success: Boolean;
begin
  Success := False;

  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;

  TTask.Create(procedure begin
      try
        if FdmVaultAPI.NewEncryptionKey then begin
          edtEncryptionKey.Text := FdmVaultAPI.EncryptionKey;
          Success := True;
        end;
      finally
        TThread.Synchronize(nil, procedure begin
          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if Success then
            ShowInfo('A new encryption key has been generated and stored with your account. It is displayed in the text box at the bottom of the application.')
          else
            ShowError;
        end);
      end;
    end).Start;
end;

procedure TfrmVaultAPIMgrMain.BrowseAppendedPath(const SubFolderName: string);
begin
  if SameText(SubFolderName, PARENT_FOLDER) then
    edtBrowsePath.Text := ReplaceStr(TPath.GetPathRoot(edtBrowsePath.Text), '\', '/')
  else
    edtBrowsePath.Text := ReplaceStr(TPath.Combine(edtBrowsePath.Text, SubFolderName), '\', '/');

  BrowseCurrentPath;
end;

procedure TfrmVaultAPIMgrMain.BrowseCurrentPath;
begin
  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;

  TTask.Create(procedure begin
      if FdmVaultAPI.BrowsePath(edtBrowsePath.Text) then begin
        TThread.Synchronize(nil, procedure begin
          ListFolders;
          ListFiles;
        end);
      end;
      TThread.Synchronize(nil, procedure begin
        AniIndicator.Enabled := False;
        AniIndicator.Visible := False;
      end);
    end).Start;
end;

procedure TfrmVaultAPIMgrMain.edtAPIKeyExit(Sender: TObject);
begin
  SetAPIKey;
end;

function TfrmVaultAPIMgrMain.FileFromSelected: TVaultFile;
begin
  if lbFiles.ItemIndex >= 0 then
    Result := lbFiles.Items.Objects[lbFiles.ItemIndex] as TVaultFile
  else
    Result := nil;
end;

procedure TfrmVaultAPIMgrMain.FormActivate(Sender: TObject);
begin
  LoadAPIKey;
  SetAPIKey;
end;

procedure TfrmVaultAPIMgrMain.lbFilesDblClick(Sender: TObject);
begin
  ShowFileContents;
end;

procedure TfrmVaultAPIMgrMain.lbFoldersDblClick(Sender: TObject);
begin
  BrowseAppendedPath(lbFolders.Selected.Text);
end;

procedure TfrmVaultAPIMgrMain.ListFiles;
begin
  lbFiles.Items.Clear;
  for var AFile in FdmVaultAPI.Files do
    lbFiles.Items.AddObject(Format('%s (%d bytes)', [AFile.Filename, AFile.FileSize]), AFile);
end;

procedure TfrmVaultAPIMgrMain.ListFolders;
begin
  lbFolders.Items.Clear;
  for var AFolder in FdmVaultAPI.Folders do
    lbFolders.Items.Add(AFolder.FolderName);

  // if not at root, add link to go up
  if edtBrowsePath.Text.Length > 1 then
    lbFolders.Items.Insert(0, PARENT_FOLDER);
end;

procedure TfrmVaultAPIMgrMain.ClearStats;
begin
  SetStats(0, 0, 0, 0);
end;

procedure TfrmVaultAPIMgrMain.SetStats(const RateLimitDay, RateLimitMonth, RateLimitRamainingDay,
  RateLimitRemainingMonth: Integer);
begin
  lblRateLimitDay.Text := 'Daily Rate Limit = ' + IntToStr(RateLimitDay);
  lblRateLimitMonth.Text := 'Monthly Rate Limit = ' + IntToStr(RateLimitMonth);
  lblRateLimitRemainingDay.Text := 'Rate Limit Remaining Today = ' + IntToStr(RateLimitRamainingDay);
  lblRateLimitRemainingMonth.Text := 'Rate Limit Remaining This Month = ' + IntToStr(RateLimitRemainingMonth);
end;

procedure TfrmVaultAPIMgrMain.ShowError;
var
  s: string;
begin
  s := 'Error returned from the Vault API: ' + sLineBreak + sLineBreak;

  if FdmVaultAPI.LastStatus > 0 then
    s := s + FdmVaultAPI.LastStatus.ToString + ': ';

  s := s + FdmVaultAPI.LastError;

  TDialogService.MessageDialog(s, TMsgDlgType.mtError,
                               [TMsgDlgBtn.mbCancel], TMsgDlgBtn.mbCancel, 0, nil);
end;

procedure TfrmVaultAPIMgrMain.ShowInfo(const InfoMsg: string);
begin
  TDialogService.MessageDialog(InfoMsg, TMsgDlgType.mtInformation,
                               [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
end;

procedure TfrmVaultAPIMgrMain.ShowFileContents;
var
  LEncryptionKey: string;
  LSuccess: Boolean;
begin
  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;
  LSuccess := False;

  if chkUseCustomEncryptionKey.IsChecked then
    LEncryptionKey := edtEncryptionKey.Text
  else
    LEncryptionKey := EmptyStr;

  if lbFiles.ItemIndex >= 0 then
    TTask.Create(procedure begin
        var SelectedFile := FileFromSelected;
        if FdmVaultAPI.GetContent(edtBrowsePath.Text + '/' + SelectedFile.Filename, LEncryptionKey) then begin
          LSuccess := True;
          TThread.Synchronize(nil, procedure begin
            actNextTab.Execute;
            btnBack.Visible := True;
            lblFilePath.Text := edtBrowsePath.Text;
            lblFileDates.Text := Format('Date Created: %s  Last Updated: %s', [
                                        FormatDateTime('yyyy-mm-dd hh:nn', SelectedFile.TimeCreated),
                                        FormatDateTime('yyyy-mm-dd hh:nn', SelectedFile.LastUpdated)]);
            lblFileDates.TextSettings.Font.Style := [];
            mmoFile.Text := FdmVaultAPI.LastContent;
          end);
        end;

        TThread.Synchronize(nil, procedure begin
          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if not LSuccess then
            ShowError;
        end);
      end).Start;
end;

procedure TfrmVaultAPIMgrMain.ShowRateLimits(Sender: TObject);
begin
  SetStats(FdmVaultAPI.RateLimitDaily,
           FdmVaultAPI.RateLimitMonthly,
           FdmVaultAPI.RateLimitRemainingDay,
           FdmVaultAPI.RateLimitRemainingMonth);
end;

procedure TfrmVaultAPIMgrMain.VaultTabsChange(Sender: TObject);
begin
  actPreviousTab.Visible := VaultTabs.ActiveTab = tabFile;
end;

function TfrmVaultAPIMgrMain.DataFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'VaultAPIMgr.ini');
end;

procedure TfrmVaultAPIMgrMain.DeleteCurrentContent;
var
  LSuccess: Boolean;
  LPath: string;
begin
  AniIndicator.Enabled := True;
  AniIndicator.Visible := True;
  LSuccess := False;
  if EndsText('/', edtBrowsePath.Text) then
    LPath := edtBrowsePath.Text
  else
    LPath := edtBrowsePath.Text + '/';

  if lbFiles.ItemIndex >= 0 then
    TTask.Create(procedure begin

        var SelectedFile := FileFromSelected;
        if FdmVaultAPI.DeleteContent(LPath + SelectedFile.Filename) then
          LSuccess := True;

        TThread.Synchronize(nil, procedure begin
          AniIndicator.Enabled := False;
          AniIndicator.Visible := False;

          if LSuccess then begin
            lbFiles.Items.Delete(lbFiles.ItemIndex);
            //ListFiles;
          end else
            ShowError;
        end);
      end).Start;
end;

procedure TfrmVaultAPIMgrMain.LoadAPIKey;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(DataFileName);
  try
    if IniFile.ValueExists(INI_SECTION, INI_APIKEY) then
      edtAPIKey.Text := IniFile.ReadString(INI_SECTION, INI_APIKEY, EmptyStr);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmVaultAPIMgrMain.SaveAPIKey;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(DataFileName);
  try
    IniFile.WriteString(INI_SECTION, INI_APIKEY, edtAPIKey.Text);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmVaultAPIMgrMain.SetAPIKey;
begin
  if not edtAPIKey.Text.IsEmpty then begin
    FdmVaultAPI.ApiKey := edtAPIKey.Text;
    ClearStats;
    SaveAPIKey;
  end;
end;

end.
