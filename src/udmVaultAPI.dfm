object dmVaultAPI: TdmVaultAPI
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 495
  Width = 1509
  PixelsPerInch = 168
  object restcliVault: TRESTClient
    Accept = 'application/json, text/plain; q=0.9, text/html;q=0.8,'
    AcceptCharset = 'utf-8, *;q=0.8'
    BaseURL = 'https://api.apilayer.com/vault'
    Params = <>
    SynchronizedEvents = False
    Left = 84
    Top = 70
  end
  object reqBrowse: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Params = <
      item
        Kind = pkURLSEGMENT
        Name = 'path'
        Options = [poDoNotEncode, poAutoCreated]
        Value = '/'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end>
    Resource = 'browse?path={path}'
    Response = respBrowse
    SynchronizedEvents = False
    Left = 182
    Top = 168
  end
  object respBrowse: TRESTResponse
    ContentType = 'application/json'
    Left = 182
    Top = 280
  end
  object reqNewKey: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Method = rmPOST
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end>
    Resource = 'key'
    Response = respNewKey
    SynchronizedEvents = False
    Left = 518
    Top = 168
  end
  object respNewKey: TRESTResponse
    ContentType = 'application/json'
    Left = 518
    Top = 266
  end
  object reqGetKey: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end>
    Resource = 'key'
    Response = respGetKey
    SynchronizedEvents = False
    Left = 686
    Top = 168
  end
  object respGetKey: TRESTResponse
    ContentType = 'application/json'
    Left = 686
    Top = 266
  end
  object reqDeleteKey: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Method = rmDELETE
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end>
    Resource = 'key'
    Response = respDeleteKey
    SynchronizedEvents = False
    Left = 1008
    Top = 168
  end
  object respDeleteKey: TRESTResponse
    ContentType = 'application/json'
    Left = 1008
    Top = 266
  end
  object reqNewContent: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Method = rmPOST
    Params = <
      item
        Kind = pkURLSEGMENT
        Name = 'path'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end
      item
        Kind = pkREQUESTBODY
        Name = 'body'
        ContentTypeStr = 'text/plain'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'encryption_key'
        Options = [poDoNotEncode]
        ContentTypeStr = 'text/plain'
      end>
    Resource = 'content?path={path}'
    Response = respNewContent
    SynchronizedEvents = False
    Left = 336
    Top = 168
  end
  object respNewContent: TRESTResponse
    ContentType = 'application/json'
    Left = 336
    Top = 266
  end
  object reqGetContent: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Params = <
      item
        Kind = pkURLSEGMENT
        Name = 'path'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'encryption_key'
        Options = [poDoNotEncode]
        ContentTypeStr = 'text/plain'
      end>
    Resource = 'content?path={path}'
    Response = respGetContent
    SynchronizedEvents = False
    OnHTTPProtocolError = reqGetContentHTTPProtocolError
    Left = 840
    Top = 168
  end
  object respGetContent: TRESTResponse
    ContentType = 'application/json'
    Left = 840
    Top = 268
  end
  object reqDeleteContent: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = restcliVault
    Method = rmDELETE
    Params = <
      item
        Kind = pkURLSEGMENT
        Name = 'path'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'apikey'
      end>
    Resource = 'content?path={path}'
    Response = respDeleteContent
    SynchronizedEvents = False
    Left = 1176
    Top = 182
  end
  object respDeleteContent: TRESTResponse
    ContentType = 'application/json'
    Left = 1176
    Top = 280
  end
end
