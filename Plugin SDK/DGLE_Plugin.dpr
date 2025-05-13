library DGLE_Plugin;

uses
  Windows,
  Messages,
  DGLEngine_header in 'DGLEngine_header.pas';

{$R *.res}

var
PluginLoaded : boolean = false;

procedure SampleProc; stdcall;
begin
//������ ���������������� �������������� ���������
end;

//���������� ����� ����� �������� ������� �������
procedure Init(DGLE_Handle : THandle; EngWinHandle : HWND; ProcessInterval : byte); stdcall;
begin
//�������� ������ ��� �������� ������ �� ��� ��� ������ ������� ������ ������
DGLEngineDLL_Handle:=DGLE_Handle;
InitDGLE_1_0;

PluginLoaded:=true;
end;

//���������� ��� ���������� �������
procedure Free; stdcall;
begin

PluginLoaded:=false;
end;

//���������� � ����� ��������� ������, �� ������ ��������� �� EXE
procedure DrawPre; stdcall;
begin
//
end;

//���������� � ����� ��������� ������, ����� ������ ��������� �� EXE
procedure DrawPost; stdcall;
begin
//
end;

//���������� �� �������� ������, �� ������ �������� �� EXE
procedure Process; stdcall;
begin
//
end;

//���������� ��������� ����������� ���� ������, ���������� �� ������ ����������� ��������� ������ ������
procedure OnMessage(var Msg : tagMSG); stdcall;
begin
 if Msg.message=WM_KEYUP then
  if Msg.wParam=119{F8} then ;
end;

exports
//��������� �������������� ���������
Init,
Free,
DrawPre,
DrawPost,
Process,
OnMessage,


//���������������� �������������� �������/���������
SampleProc;

begin
//��������� ������������� �������, ���������� �� ��������� INIT � ���� ������ ����� ����������� �������, �� �� ������ ������
end.
