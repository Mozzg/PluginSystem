object Form3: TForm3
  Left = 0
  Top = 0
  OnAlignInsertBefore = FormAlignInsertBefore
  Caption = 'Form3'
  ClientHeight = 528
  ClientWidth = 1365
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  OnDestroy = FormDestroy
  OnDragOver = FormDragOver
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnMouseDown = FormMouseDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Load and init'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 455
    Top = 8
    Width = 562
    Height = 501
    ScrollBars = ssBoth
    TabOrder = 1
    OnChange = Memo1Change
  end
  object Button2: TButton
    Left = 8
    Top = 101
    Width = 75
    Height = 25
    Caption = 'Unload'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 250
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Test3 load'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 250
    Top = 39
    Width = 75
    Height = 25
    Caption = 'GetIntf'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 250
    Top = 101
    Width = 75
    Height = 25
    Caption = 'Finalize'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 250
    Top = 70
    Width = 75
    Height = 25
    Caption = 'RefCount'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 251
    Top = 137
    Width = 75
    Height = 25
    Caption = 'Button7'
    TabOrder = 7
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 8
    Top = 39
    Width = 75
    Height = 25
    Caption = 'RefCount'
    TabOrder = 8
    OnClick = Button8Click
  end
  object Button9: TButton
    Left = 8
    Top = 168
    Width = 75
    Height = 25
    Caption = 'Create weak ref'
    TabOrder = 9
    OnClick = Button9Click
  end
  object Button10: TButton
    Left = 8
    Top = 199
    Width = 75
    Height = 25
    Caption = 'Test weak ref'
    TabOrder = 10
    OnClick = Button10Click
  end
  object Button11: TButton
    Left = 8
    Top = 230
    Width = 75
    Height = 25
    Caption = 'Free weak ref'
    TabOrder = 11
    OnClick = Button11Click
  end
  object Button12: TButton
    Left = 112
    Top = 168
    Width = 75
    Height = 25
    Caption = 'Create'
    TabOrder = 12
    OnClick = Button12Click
  end
  object Button13: TButton
    Left = 112
    Top = 230
    Width = 75
    Height = 25
    Caption = 'Free'
    TabOrder = 13
    OnClick = Button13Click
  end
  object Button14: TButton
    Left = 112
    Top = 199
    Width = 75
    Height = 25
    Caption = 'Test'
    TabOrder = 14
    OnClick = Button14Click
  end
  object Button15: TButton
    Left = 200
    Top = 168
    Width = 75
    Height = 25
    Caption = 'Gen weak ref'
    TabOrder = 15
    OnClick = Button15Click
  end
  object Button16: TButton
    Left = 200
    Top = 199
    Width = 75
    Height = 25
    Caption = 'Test weakref2'
    TabOrder = 16
    OnClick = Button16Click
  end
  object Button17: TButton
    Left = 8
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Status'
    TabOrder = 17
    OnClick = Button17Click
  end
  object Button18: TButton
    Left = 8
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Get events1'
    TabOrder = 18
    OnClick = Button18Click
  end
  object Button19: TButton
    Left = 89
    Top = 39
    Width = 75
    Height = 25
    Caption = 'List events'
    TabOrder = 19
    OnClick = Button19Click
  end
  object Button20: TButton
    Left = 89
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Subscribe event'
    TabOrder = 20
    OnClick = Button20Click
  end
  object Memo2: TMemo
    Left = 1032
    Top = 8
    Width = 325
    Height = 501
    ScrollBars = ssBoth
    TabOrder = 21
  end
  object Button21: TButton
    Left = 170
    Top = 39
    Width = 75
    Height = 25
    Caption = 'List windows'
    TabOrder = 22
    OnClick = Button21Click
  end
  object Button22: TButton
    Left = 170
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Show wnd'
    TabOrder = 23
    OnClick = Button22Click
  end
  object Button23: TButton
    Left = 89
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Get events2'
    TabOrder = 24
    OnClick = Button23Click
  end
  object Button24: TButton
    Left = 8
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Get published'
    TabOrder = 25
    OnClick = Button24Click
  end
  object Button25: TButton
    Left = 8
    Top = 487
    Width = 75
    Height = 25
    Caption = 'Form2'
    TabOrder = 26
    OnClick = Button25Click
  end
  object Button26: TButton
    Left = 170
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Get events3'
    TabOrder = 27
    OnClick = Button26Click
  end
  object Button27: TButton
    Left = 8
    Top = 384
    Width = 75
    Height = 25
    Caption = 'Hook methods'
    TabOrder = 28
    OnClick = Button27Click
  end
  object Button28: TButton
    Left = 8
    Top = 415
    Width = 75
    Height = 25
    Caption = 'Unhook methods'
    TabOrder = 29
    OnClick = Button28Click
  end
  object Button29: TButton
    Left = 251
    Top = 350
    Width = 75
    Height = 25
    Caption = 'Get events4'
    TabOrder = 30
    OnClick = Button29Click
  end
  object Panel1: TPanel
    Left = 89
    Top = 392
    Width = 176
    Height = 128
    TabOrder = 31
    OnEnter = Panel1Enter
    object TabControl1: TTabControl
      Left = 12
      Top = 15
      Width = 157
      Height = 98
      TabOrder = 0
      Tabs.Strings = (
        'First'
        'Second'
        'Third')
      TabIndex = 0
      OnChanging = TabControl1Changing
      object TestButton: TButton
        Left = 11
        Top = 32
        Width = 75
        Height = 25
        Caption = 'TestButton'
        TabOrder = 0
        OnClick = TestButtonClick
      end
    end
  end
  object Button30: TButton
    Left = 170
    Top = 319
    Width = 75
    Height = 25
    Caption = 'Change params'
    TabOrder = 32
    OnClick = Button30Click
  end
  object Button31: TButton
    Left = 170
    Top = 350
    Width = 75
    Height = 25
    Caption = 'Del params'
    TabOrder = 33
    OnClick = Button31Click
  end
  object ListBox1: TListBox
    Left = 281
    Top = 168
    Width = 168
    Height = 176
    ItemHeight = 13
    TabOrder = 34
  end
end
