object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 579
  ClientWidth = 776
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 384
    Top = 8
    Width = 384
    Height = 563
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Load DLL'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 296
    Top = 8
    Width = 75
    Height = 25
    Caption = 'TestInterface'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 8
    Top = 39
    Width = 75
    Height = 25
    Caption = 'LoadAPI'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 8
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Abort'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 8
    Top = 101
    Width = 75
    Height = 25
    Caption = 'Access violation'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 8
    Top = 132
    Width = 75
    Height = 25
    Caption = 'Win32 exc'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 8
    Top = 163
    Width = 75
    Height = 25
    Caption = 'Software exc'
    TabOrder = 7
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 296
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Emulate leak'
    TabOrder = 8
    OnClick = Button8Click
  end
  object Button9: TButton
    Left = 296
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Test inherits'
    TabOrder = 9
    OnClick = Button9Click
  end
  object Button10: TButton
    Left = 296
    Top = 120
    Width = 75
    Height = 25
    Caption = 'Test exception'
    TabOrder = 10
    OnClick = Button10Click
  end
  object Button11: TButton
    Left = 296
    Top = 151
    Width = 75
    Height = 25
    Caption = 'List interfaces'
    TabOrder = 11
    OnClick = Button11Click
  end
  object Button12: TButton
    Left = 296
    Top = 200
    Width = 75
    Height = 25
    Caption = 'Test compatibility'
    TabOrder = 12
    OnClick = Button12Click
  end
  object Button13: TButton
    Left = 296
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Create intf'
    TabOrder = 13
    OnClick = Button13Click
  end
  object Button14: TButton
    Left = 296
    Top = 287
    Width = 75
    Height = 25
    Caption = 'Request intf'
    TabOrder = 14
    OnClick = Button14Click
  end
end
