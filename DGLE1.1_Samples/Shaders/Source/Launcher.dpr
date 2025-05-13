program Launcher;

uses
  Classes, Windows,
  DGLEngine_header in '..\..\..\System\DGLEngine_header.pas';

{$R Ico.res}

const

{
���� ������ ���������� ��� ������� � ������������� �������.
� DGLE ������� ����� ����������� ��� � 2D ��� � 3D �������.

� DGLE ������������ ������� �� ���������� ��� GPU ������ ����� ����� GLSL,
��� ������� �� ���� ��� � �� ���� ������ ������������ � ������ ������ ������
������������ ������� � �� ����� ��� 2.0 ������ �� ����� � �������� ��� �������.

��� ��������� ������� ���������� �������� ��� ��������:
}

//��� ����� ������ ������ ������� ������ ����� ���� :)
//�� �������� ����� ����������� ���������� ���� ���������� ������ ��� ���������������������
Simplest_PixelShader : string =
'!!ARBfp1.0'+#13+ //������������ ��������� �������
'TEMP   texelColor;'+#13+ //��������� ���������� 4D ������ � ������� ������� ���� ������� � �������� ��� �������� �������
'TXP    texelColor, fragment.texcoord, texture, 2D;'+#13+ //����� �� ���������� ����������� ��� ����� ������� ���� ������� �� ������� ��������
'MUL    result.color, texelColor, fragment.color.primary;'+#13+ //�������� ���� �� �������� �� ���� ��������� � ������� � ���������� �������� (�.�. Color3D + ����������� ���������) ��������� ��������� � ����� �������� ������ ����� �������
'END';//������������ ������ ���������� �������

//��� ����� ������� ������ �������� R ���������� �������
PixelShader_noR : string =
'!!ARBfp1.0'+#13+
'TEMP   texelColor;'+#13+
'TXP    texelColor, fragment.texcoord, texture, 2D;'+#13+
'MUL    result.color, texelColor, fragment.color.primary;'+#13+
'MOV    result.color.r, 0.0;'+#13+ //� ����������� ���� � R ���������� 0
'END';

//������ ��������� �� ���������� ��������� � �������� ���������� ����������
PixelShader_TexCoord : string =
'!!ARBfp1.0'+#13+
'PARAM  koeff=program.local[0];'+#13+ //�������� 4D ������ ���������� �� ����������  (4-� �������� �������� �� �������)
'ATTRIB inTexCoord = fragment.texcoord;'+#13+
'TEMP   texelColor, texcoord;'+#13+
'ADD    texcoord, koeff, inTexCoord;'+#13+//���������� � ���������� ����������� ������� ������ ���������� �� ����������
'TXP    texelColor, texcoord, texture[0], 2D;'+#13+
'MUL    result.color, texelColor, fragment.color.primary;'+#13+
'END';

//��� ��� ������ ���� ���������� �� - ������� ���������������� ����� �� ��������
PixelShader_Cos : string =
'!!ARBfp1.0'+#13+
'PARAM  koeff=program.local[0];'+#13+
'ATTRIB inTexCoord = fragment.texcoord;'+#13+
'TEMP   texelColor, texcoord, t1, t2, t3;'+#13+
'ADD    t2.w, koeff.w, inTexCoord.y;'+#13+
'COS    t3, t2.w;'+#13+
'ADD    t1.x, 1, t3.w;'+#13+
'ADD    texcoord, t1, inTexCoord;'+#13+
'TXP    texelColor, texcoord, texture[0], 2D;'+#13+
'MUL    result.color, texelColor, fragment.color.primary;'+#13+
'END';

//����� ���� ��� � ���� �� ��������������
PixelShader_Sin_Fast : string =
'!!ARBfp1.0'+#13+
'PARAM  koeff=program.local[0];'+#13+
'ATTRIB inTexCoord = fragment.texcoord;'+#13+
'TEMP   texelColor, texcoord, t1, t2, t3;'+#13+
'MUL    t2.w, koeff.w, inTexCoord.y;'+#13+
'SIN    t3.w, t2.w;'+#13+
'MUL    t2.w, t3.w, 0.25;'+#13+
'ADD    t3.x, 0, t2.w;'+#13+
'MUL    t1.x, t3.x, 0.25;'+#13+
'ADD    texcoord, t1, inTexCoord;'+#13+
'#ADD    texcoord, t2, inTexCoord;'+#13+//������������ ��� ������� � ����� ������ ������� ������ )
'TXP    texelColor, texcoord, texture[0], 2D;'+#13+
'MUL    result.color, texelColor, fragment.color.primary;'+#13+
'END';

//������ �� ����� �� �� ������� )
PixelShader_Disort : string =
'!!ARBfp1.0'+#13+
'PARAM  koeff=program.local[0];'+#13+
'ATTRIB inTexCoord = fragment.texcoord;'+#13+
'TEMP   texelColor, t1, t2, t3, a1, a2;'+#13+
'OUTPUT oColor = result.color;'+#13+
'TXP    texelColor, inTexCoord, texture[0], 2D;'+#13+
'MUL    oColor, texelColor, fragment.color.primary;'+#13+
'MUL    t3.w, koeff.w, inTexCoord.y;'+#13+
'SIN    t2.w, t3.w;'+#13+
'CMP    a1.w, t2.w, 0.5, 0.0;'+#13+
'MUL    t3.w, koeff.w, inTexCoord.x;'+#13+
'COS    t2.w, t3.w;'+#13+
'CMP    a2.w, t2.w, 0.5, 0.0;'+#13+
'ADD    t1.w, a1.w, a2.w;'+#13+
'MOV    oColor.a, t1.w;'+#13+
'END';

var
Texture, Texture2 : cardinal;
Angle : single = 0.0;
PixShader, PixShader2, PixShader3, VertexShader : cardinal;

vertex : Tvertex;

procedure EngineInit;
var
S : TStringList;
begin

 if not IsVShadersSupported or not IsPShadersSupported then //���� ��� ��������, �� ������� �������� ��� �� ������
    MessageBox(0,PChar('No Shaders - No Love!'+#13+'Shader Model 2.0 requerd.'),'Attention', MB_OK or MB_ICONINFORMATION);

  vertex.X:=0;
  vertex.Y:=0;
  vertex.Z:=0;

 Texture:=LoadTextureFromFile('..\..\Samples\Beginner\Hello World 3D\Texture.bmp');

 Texture2:=LoadTextureFromFile('..\..\Samples\Advanced\Projected Textures\projector.JPG');
 TextureParametrs(Texture2,TEXTURE_CLAMP);

 //����� ������ ���������� ������ ��������� ��������� ���� � ���������� �� ���������
 PixShader:=LoadShader(FRAGMENT_PROGRAM,PixelShader_Cos);
 PixShader2:=LoadShader(FRAGMENT_PROGRAM,PixelShader_Sin_Fast);
 PixShader3:=LoadShader(FRAGMENT_PROGRAM,PixelShader_Disort);

 //������ ���������� ������ �� �����
 s:=TStringList.Create;
 s.LoadFromFile('Simple_Vertex_Shader.txt');
 VertexShader:=LoadShader(VERTEX_PROGRAM,s.Text);
 s.Free;

end;

procedure Draw;
begin

SetLight(LIGHT0,-0.5,0,0);


SetShader(PixShader);

GiveShaderParams(PixShader,0,vertex,Angle/10);

BeginObj3D;
 Position3D(1,0,-4);
 RotateY(-Angle*2);
 SetTexture(Texture);
 DrawCube(0.5,0.5,0.5);
EndObj3D;

SetShader(VertexShader);

GiveShaderParams(PixShader,0,vertex,-Angle);

BeginObj3D;
 Position3D(-1,0,-4);
 RotateY(-Angle*2);
 SetTexture(Texture);
 DrawCube(0.5,0.5,0.5);
EndObj3D;

SetShader(NULL_PROGRAMS);

Begin2D;

SetShader(PixShader2);
GiveShaderParams(PixShader2,0,vertex,sin(Angle/50)*100);
 DrawTexture2D(Texture2,350,150,256,256,0,200,$FFFFFF,true);
SetShader(NULL_FRAGMENT_PROGRAM);

SetShader(PixShader3);
GiveShaderParams(PixShader3,0,vertex,sin(Angle/100)*250);
 DrawTexture2D(Texture2,0,150,256,256,0,200,$FFFFFF,true);
SetShader(NULL_FRAGMENT_PROGRAM);

End2D;

end;

procedure Process;
begin

 Angle:=Angle+0.2;

 if IsKeyPressed(Key_Escape) then
 QuitEngine;

end;


begin
 if LoadDGLEngineDLL('..\..\System\DGLEngine.dll') then
 begin
  RegProcedure(PROC_DRAW,@Draw);
  RegProcedure(PROC_PROCESS,@Process);
  RegProcedure(PROC_INIT,@EngineInit);

  SetEngineInitParametrs(800,600,32,85,false,false,false);

  StartEngine;

  FreeDGLEngineDLL;
 end;

end.
