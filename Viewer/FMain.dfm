object FrmMain: TFrmMain
  Left = 256
  Top = 273
  Width = 625
  Height = 394
  Caption = 'Resource Leaks Report'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object SplitterVert: TSplitter
    Left = 169
    Top = 0
    Height = 360
  end
  object Tree: TTreeView
    Left = 0
    Top = 0
    Width = 169
    Height = 360
    Align = alLeft
    Color = clInfoBk
    HideSelection = False
    Images = Images
    Indent = 19
    ReadOnly = True
    TabOrder = 0
    OnChange = TreeChange
  end
  object PnlClient: TPanel
    Left = 172
    Top = 0
    Width = 445
    Height = 360
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object SplitterHorz: TSplitter
      Left = 0
      Top = 125
      Width = 445
      Height = 3
      Cursor = crVSplit
      Align = alTop
    end
    object PnlStackTrace: TPanel
      Left = 0
      Top = 128
      Width = 445
      Height = 20
      Align = alTop
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Caption = 'Stack trace'
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clCaptionText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Memo: TMemo
      Left = 0
      Top = 0
      Width = 445
      Height = 125
      Align = alTop
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object LVStackTrace: TListView
      Left = 0
      Top = 148
      Width = 445
      Height = 212
      Align = alClient
      Color = 16244940
      Columns = <
        item
          Caption = 'Address'
          Width = 70
        end
        item
          Caption = 'Symbol'
          Width = 170
        end
        item
          Caption = 'Unit'
          Width = 130
        end
        item
          Alignment = taRightJustify
          Caption = 'Line'
        end>
      ColumnClick = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
    end
  end
  object Images: TImageList
    Left = 4
    Top = 4
    Bitmap = {
      494C010105000900040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000003000000001002000000000000030
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000080800000808000008080000080800000808000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000080
      8000008080000080800000808000008080000080800000808000008080000080
      8000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008080000080
      8000008080000080800000808000008080000080800000808000008080000080
      8000008080000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000808000008080000080
      8000000000000000000000808000008080000080800000000000000000000080
      8000008080000080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000808000008080000080
      8000000000000000000000808000008080000000000000000000008080000080
      8000008080000080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080800000808000008080000080
      8000000000000000000000808000000000000000000000808000008080000080
      8000008080000080800000808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080800000808000008080000080
      8000000000000000000000000000000000000080800000808000008080000080
      8000008080000080800000808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080800000808000008080000080
      8000000000000000000000000000008080000080800000808000008080000080
      8000008080000080800000808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080800000808000008080000080
      8000000000000000000000000000000000000080800000808000008080000080
      8000008080000080800000808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080800000808000008080000080
      8000000000000000000000808000000000000000000000808000008080000080
      8000008080000080800000808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000808000008080000080
      8000000000000000000000808000008080000000000000000000008080000080
      8000008080000080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000808000008080000080
      8000000000000000000000808000008080000080800000000000000000000080
      8000008080000080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008080000080
      8000008080000080800000808000008080000080800000808000008080000080
      8000008080000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000080
      8000008080000080800000808000008080000080800000808000008080000080
      8000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000080800000808000008080000080800000808000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000FF000000FF000000FF000000FF000000FF00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008000000080000000800000008000000080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008080000080800000808000008080000080800000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008000800080008000800080008000800080008000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF00000000000000000000000000000000000000000000000000000000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000000000000000000000000000000000000000000000000000000000008080
      0000808000008080000080800000808000008080000080800000808000008080
      0000000000000000000000000000000000000000000000000000000000008000
      8000800080008000800080008000800080008000800080008000800080008000
      80000000000000000000000000000000000000000000000000000000FF000000
      FF000000FF000000FF000000FF00000000000000FF000000FF000000FF000000
      FF000000FF000000000000000000000000000000000000000000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000000000000000000000000000000000000000000000808000008080
      0000808000008080000080800000808000008080000080800000808000008080
      0000808000000000000000000000000000000000000000000000800080008000
      8000800080008000800080008000800080008000800080008000800080008000
      800080008000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000080000000800000000000
      0000000000008000000080000000000000008000000080000000000000000000
      0000800000008000000000000000000000000000000080800000808000008080
      0000808000000000000000000000000000000000000000000000808000008080
      0000808000008080000000000000000000000000000080008000800080008000
      8000800080000000000000000000000000000000000000000000000000008000
      800080008000800080000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF00000000000000FF000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000080000000800000000000
      0000000000008000000080000000000000008000000080000000000000000000
      0000800000008000000000000000000000000000000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000000000000000000000000000080008000800080008000
      8000000000000000000080008000800080000000000000000000000000008000
      8000800080008000800000000000000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF00000000008000000080000000800000000000
      0000000000008000000000000000000000000000000080000000000000000000
      0000800000008000000080000000000000008080000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000080800000000000008000800080008000800080008000
      8000000000000000000080008000800080008000800000000000000000008000
      8000800080008000800080008000000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF00000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF00000000008000000080000000800000000000
      0000000000008000000000000000000000000000000080000000000000000000
      0000800000008000000080000000000000008080000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000080800000000000008000800080008000800080008000
      8000000000000000000080008000800080008000800000000000000000008000
      8000800080008000800080008000000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF00000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF00000000008000000080000000800000000000
      0000000000000000000000000000800000000000000000000000000000000000
      0000800000008000000080000000000000008080000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000080800000000000008000800080008000800080008000
      8000000000000000000080008000000000000000000000000000000000008000
      8000800080008000800080008000000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF00000000008000000080000000800000000000
      0000000000000000000000000000800000000000000000000000000000000000
      0000800000008000000080000000000000008080000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000080800000000000008000800080008000800080008000
      8000000000000000000080008000800080008000800080008000800080008000
      8000800080008000800080008000000000000000FF000000FF000000FF000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF00000000008000000080000000800000000000
      0000000000000000000080000000800000008000000000000000000000000000
      0000800000008000000080000000000000008080000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000080800000000000008000800080008000800080008000
      8000000000000000000080008000800080008000800080008000800080008000
      800080008000800080008000800000000000000000000000FF000000FF000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000080000000800000000000
      0000000000000000000080000000800000008000000000000000000000000000
      0000800000008000000000000000000000000000000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000000000000000000000000000080008000800080008000
      8000000000000000000080008000800080008000800000000000000000008000
      800080008000800080000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000080000000800000000000
      0000000000008000000080000000800000008000000080000000000000000000
      0000800000008000000000000000000000000000000080800000808000008080
      0000000000000000000080800000808000008080000000000000000000008080
      0000808000008080000000000000000000000000000080008000800080008000
      8000800080000000000000000000000000000000000000000000800080008000
      80008000800080008000000000000000000000000000000000000000FF000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000000000000000000000000000000000000000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000000000000000000000000000000000000000000000808000008080
      0000808000008080000080800000808000008080000080800000808000008080
      0000808000000000000000000000000000000000000000000000800080008000
      8000800080008000800080008000800080008000800080008000800080008000
      8000800080000000000000000000000000000000000000000000000000000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF00000000000000000000000000000000000000000000000000000000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000000000000000000000000000000000000000000000000000000000008080
      0000808000008080000080800000808000008080000080800000808000008080
      0000000000000000000000000000000000000000000000000000000000008000
      8000800080008000800080008000800080008000800080008000800080008000
      8000000000000000000000000000000000000000000000000000000000000000
      0000000000000000FF000000FF000000FF000000FF000000FF00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008000000080000000800000008000000080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008080000080800000808000008080000080800000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008000800080008000800080008000800080008000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000300000000100010000000000800100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FFFF000000000000F83F000000000000
      E00F000000000000C0070000000000008C630000000000008CC3000000000000
      0D810000000000000F010000000000000E010000000000000F01000000000000
      0D810000000000008CC30000000000008C63000000000000C007000000000000
      E00F000000000000F83F000000000000FFFFFFFFFFFFFFFFF83FF83FF83FF83F
      E00FE00FE00FE00FC107C007C007C0078383993387C387E3810399338C638CE3
      00011BB10C610C6101011BB10C610C6101011EF10C610DE103811EF10C610C01
      03811C710C610C0183839C738C638C63838398338C6387C3C007C007C007C007
      E00FE00FE00FE00FF83FF83FF83FF83F00000000000000000000000000000000
      000000000000}
  end
end