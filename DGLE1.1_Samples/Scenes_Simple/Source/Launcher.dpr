program Launcher;

uses
  SysUtils, Windows, Classes, 
  DGLEngine_header in '..\..\..\System\DGLEngine_header.pas';

{$R Ico.res}

{
 ������ ����������:
 1. �������� � ��������� ����� �� �����
 2. ���������� ShadowMap ����� (�� ����� �� ������� � �������� :)
 3. �������� ����������� ������� � ������� ����������� ShadowMap
}

var
HARD : boolean = FALSE;           //����� �� ������ ������ �� ����
SELF_SHADOWING : boolean  = TRUE; //����� ���/���� ������������� ��� �� �������� ���������
const
SHADOW_ALPHA = 0.40;    //������������ ����� �� 0.0 �� 1.0

var Scene, PShader : cardinal;
ShadowTex : cardinal;

LightMovment : single = 200;
LightCamera : TCamera;


function vertex (x,y,z : single) : Tvertex; inline;
begin
  result.X:=x;
  result.Y:=y;
  result.Z:=z;
end;

procedure EngineInit;
var s : TStringList;
begin

 if not IsPShadersSupported then //���� ��� ��������, �� ������������ � �������� �� �����
    MessageBox(0,PChar('No Shaders - No Love!'+#13+'Shader Model 2.0 requerd.'),'Attention', MB_OK or MB_ICONINFORMATION);

 if not IsShadowMapsSupported then //� ���� � ����� ��� �� ���� ����������� ��� ������ ���������� ���� "�����" �����
 begin
  MessageBox(0,PChar('Your card doesnt support shadow maps at all! :('),'Attention', MB_OK or MB_ICONINFORMATION);
  //�� ��� �� ������ �� ���� �� ���������, ������ ��� ������� :)
  //QuitEngine;
  //Exit;
 end;

 LightCamera.Eye:=vertex(0,0,0);
 LightCamera.Center:=vertex(0,0,0);


 s:=TStringList.Create();
 s.LoadFromFile('Data\PixelShader.txt');
 PShader:=LoadShader(FRAGMENT_PROGRAM,s.Text);
 s.Free;

 TextureMipMapping(true);
 Scene:=LoadScene('Data\scene.dsc','Data\meshs','..\Scenes_Advanced\Data\maps');
 TextureMipMapping(false);

 ActivateMultitexturingLayer(MTEX_LAYER1);
 ShadowTex:=CreateShadowMap(1024);
 ActivateMultitexturingLayer(MTEX_LAYER0);

end;

procedure UpdateShadow;
begin
ActivateMultitexturingLayer(MTEX_LAYER1);

 CullFace(CULL_FRONT); //���� ������������� �� ���������� ������� ����� � �������� �� ������ ��������� ������ ���������

 StartRenderToTexture(ShadowTex);
  SetCamera(LightCamera);
  CalculateFrustum;
  //� �� ���� ��� �� ��������� �� ������� ����� ������� ��������������, �� ����� �� ����� ���������� ���� � �� �����������
  SceneSetObjActive(Scene,GetSceneObjectIdent(Scene,'Plane01'),false); //������������ ��� ������ ��� �� ���������� ������������� �� �������
  DrawScene(Scene);
  SceneSetObjActive(Scene,GetSceneObjectIdent(Scene,'Plane01'),true);
 EndRenderToTexture;

ActivateMultitexturingLayer(MTEX_LAYER0);
end;

procedure Draw;
var t : TSceneMesh;
begin

 UpdateShadow;

 Position3D(0,0,-400);
 RotateX(45);

 CalculateFrustum;
 //����� ������� �������� ��� ������ �������� ���������� ������������� ����

 SetLight(LIGHT0,LightCamera.Eye.X,LightCamera.Eye.Y,LightCamera.Eye.Z);

 ActivateMultitexturingLayer(MTEX_LAYER1);
 CastShadowMap(ShadowTex,LightCamera);
 ActivateMultitexturingLayer(MTEX_LAYER0);

 if not HARD then
 SetShader(PShader);
 GiveShaderParams(PShader,0,vertex(0,0,0),1.0-SHADOW_ALPHA); //�������� ������� ���������, ������ 3 ��� �� �����, � ��������� - ������������ ����

 CullFace(CULL_BACK);

 if not SELF_SHADOWING then
 begin
 //��������� �� ����� ��������� � ������ ������ �� � �������� "��������" ����, ����� ��������� ������������� ���� � ������ ��������� �����
 t:=SceneGetObj(Scene,GetSceneObjectIdent(Scene,'Plane01'));
 SceneSetObjActive(Scene,GetSceneObjectIdent(Scene,'Plane01'),false);

 BeginObj3D;
  Position3D(t.Pos.X,t.Pos.Y,t.Pos.Z);
  Color3D(RGB(t.Material.diffuse[0],t.Material.diffuse[1],t.Material.diffuse[2]));
  Scale3D(t.Scale);
  SetTexture(t.Texture);
  DrawModel(t.Mesh);
 EndObj3D;

 ActivateMultitexturingLayer(MTEX_LAYER1);
 DisableProjector;
 ActivateMultitexturingLayer(MTEX_LAYER0);
 end;

 DrawScene(Scene);

 SetShader(NULL_FRAGMENT_PROGRAM);

 if SELF_SHADOWING then
 begin
 ActivateMultitexturingLayer(MTEX_LAYER1);
 DisableProjector;
 ActivateMultitexturingLayer(MTEX_LAYER0);
 end;

 DeactiveLight();
end;

procedure Process;
begin

 if IsKeyPressed(Key_F1) then SELF_SHADOWING:=true;
 if IsKeyPressed(Key_F2) then SELF_SHADOWING:=false;

 if IsKeyPressed(Key_F3) then HARD:=true;
 if IsKeyPressed(Key_F4) then HARD:=false;

 LightMovment:=LightMovment+0.005;
 LightCamera.Eye:=vertex(cos(LightMovment*1.5)*250,sin(LightMovment)*500,320);

 ApplicationName(PChar('FPS:'+IntToStr(GetFPS)+' F1/F2 - ���./����. �������������, F3/F4 - ���./����. ������ �� �������.'));
 if IsKeyPressed(Key_Escape) then
 QuitEngine;

end;


begin
 if LoadDGLEngineDLL('..\..\System\DGLEngine.dll') then
 begin
  RegProcedure(PROC_DRAW,@Draw);
  RegProcedure(PROC_PROCESS,@Process);
  RegProcedure(PROC_INIT,@EngineInit);

  SetEngineInitParametrs(1024,768,32,0,false,false,false);
  SetCutingPlanes(1.0,2000.0);
  StartEngine;

  FreeDGLEngineDLL;
 end;

end.
