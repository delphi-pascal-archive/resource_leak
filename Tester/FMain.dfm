object FrmMain: TFrmMain
  Left = 301
  Top = 130
  ActiveControl = CBLeak
  BorderStyle = bsDialog
  Caption = 'Resource Monitor Tester'
  ClientHeight = 313
  ClientWidth = 602
  Color = clInfoBk
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 120
  TextHeight = 16
  object PnlMemory: TPanel
    Left = 10
    Top = 34
    Width = 287
    Height = 130
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = 16244940
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 1
    object LblMemory: TLabel
      Left = 0
      Top = 0
      Width = 285
      Height = 25
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'Memory'
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clCaptionText
      Font.Height = -17
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object BtnGetMem: TButton
      Left = 10
      Top = 34
      Width = 267
      Height = 26
      Caption = '&GetMem w/o FreeMem'
      TabOrder = 0
      OnClick = BtnGetMemClick
    end
    object BtnNew: TButton
      Left = 10
      Top = 64
      Width = 267
      Height = 26
      Caption = '&New w/o Dispose'
      TabOrder = 1
      OnClick = BtnNewClick
    end
    object BtnCreate: TButton
      Left = 10
      Top = 94
      Width = 267
      Height = 25
      Caption = '&Create w/o Free'
      TabOrder = 2
      OnClick = BtnCreateClick
    end
  end
  object PnlUSER32: TPanel
    Left = 305
    Top = 34
    Width = 287
    Height = 130
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = 16244940
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 2
    object LblUSER32: TLabel
      Left = 0
      Top = 0
      Width = 285
      Height = 25
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'USER32 Resources'
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clCaptionText
      Font.Height = -17
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object BtnLoadBitmap: TButton
      Left = 10
      Top = 34
      Width = 267
      Height = 26
      Caption = 'Load&Bitmap w/o DeleteObject'
      TabOrder = 0
      OnClick = BtnLoadBitmapClick
    end
    object BtnCreateMenu: TButton
      Left = 10
      Top = 64
      Width = 267
      Height = 26
      Caption = 'Create&Menu w/o DestroyMenu'
      TabOrder = 1
      OnClick = BtnCreateMenuClick
    end
    object BtnSetTimer: TButton
      Left = 10
      Top = 94
      Width = 267
      Height = 25
      Caption = '&SetTimer w/o KillTimer (TTimer)'
      TabOrder = 2
      OnClick = BtnSetTimerClick
    end
  end
  object CBLeak: TCheckBox
    Left = 10
    Top = 10
    Width = 119
    Height = 21
    Caption = 'Create &leaks'
    Checked = True
    State = cbChecked
    TabOrder = 0
    OnClick = CBLeakClick
  end
  object BtnClose: TButton
    Left = 305
    Top = 276
    Width = 287
    Height = 26
    Cancel = True
    Caption = 'Close'
    TabOrder = 5
    OnClick = BtnCloseClick
  end
  object PnlGDI32: TPanel
    Left = 10
    Top = 172
    Width = 287
    Height = 130
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = 16244940
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 3
    object LblGDI32: TLabel
      Left = 0
      Top = 0
      Width = 285
      Height = 25
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'GDI32 Resources'
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clCaptionText
      Font.Height = -17
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object BtnCreateCompatibleDC: TButton
      Left = 10
      Top = 34
      Width = 267
      Height = 26
      Caption = 'CreateCompatible&DC w/o DeleteDC'
      TabOrder = 0
      OnClick = BtnCreateCompatibleDCClick
    end
    object BtnCreateSolidBrush: TButton
      Left = 10
      Top = 64
      Width = 267
      Height = 26
      Caption = 'C&reateSolidBrush w/o DeleteObject'
      TabOrder = 1
      OnClick = BtnCreateSolidBrushClick
    end
    object BtnCreatePen: TButton
      Left = 10
      Top = 94
      Width = 267
      Height = 25
      Caption = 'Create&Pen w/o DeleteObject (TPen)'
      TabOrder = 2
      OnClick = BtnCreatePenClick
    end
  end
  object PnlKERNEL32: TPanel
    Left = 305
    Top = 172
    Width = 287
    Height = 100
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = 16244940
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 4
    object LblKERNEL32: TLabel
      Left = 0
      Top = 0
      Width = 285
      Height = 25
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'KERNEL32 Resources'
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clCaptionText
      Font.Height = -17
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object BtnCreateFileDirect: TButton
      Left = 10
      Top = 34
      Width = 267
      Height = 26
      Caption = 'Create&File w/o CloseHandle (direct)'
      TabOrder = 0
      OnClick = BtnCreateFileDirectClick
    end
    object BtnCreateFileStream: TButton
      Left = 10
      Top = 64
      Width = 267
      Height = 26
      Caption = 'Create&File w/o CloseHandle (TFileStream)'
      TabOrder = 1
      OnClick = BtnCreateFileStreamClick
    end
  end
end
