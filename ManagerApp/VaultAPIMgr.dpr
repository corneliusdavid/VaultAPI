program VaultAPIMgr;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmVaultAPIMgrMain in 'ufrmVaultAPIMgrMain.pas' {frmVaultAPIMgrMain},
  udmVaultAPI in '..\src\udmVaultAPI.pas' {dmVaultAPI: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait, TFormOrientation.InvertedPortrait];
  Application.CreateForm(TfrmVaultAPIMgrMain, frmVaultAPIMgrMain);
  Application.Run;
end.
