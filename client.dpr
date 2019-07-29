program client;

uses
  Forms,
  umain in 'umain.pas' {Form1},
  LibQCOW in 'libqcow.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
