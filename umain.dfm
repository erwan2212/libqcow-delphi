object Form1: TForm1
  Left = 192
  Top = 124
  Width = 524
  Height = 281
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 48
    Top = 56
    Width = 73
    Height = 25
    Caption = 'size'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 48
    Top = 104
    Width = 273
    Height = 81
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Button2: TButton
    Left = 128
    Top = 56
    Width = 75
    Height = 25
    Caption = 'restore'
    TabOrder = 2
    OnClick = Button2Click
  end
  object pb_img: TProgressBar
    Left = 48
    Top = 192
    Width = 273
    Height = 25
    TabOrder = 3
  end
  object Button3: TButton
    Left = 216
    Top = 56
    Width = 75
    Height = 25
    Caption = 'backup'
    TabOrder = 4
    OnClick = Button3Click
  end
  object OpenDialog1: TOpenDialog
    Left = 88
    Top = 8
  end
end
