library Stg1;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters.

  Important note about VCL usage: when this DLL will be implicitly
  loaded and this DLL uses TWicImage / TImageCollection created in
  any unit initialization section, then Vcl.WicImageInit must be
  included into your library's USES clause. }

uses
  System.SysUtils,
  Winapi.Windows,
  System.Classes,
  Vcl.Forms,
  FStg1 in 'FStg1.pas' {FrmStg1};

{$R *.res}

function _Open : TForm;  stdcall;
begin
  Result := TFrmStg1.Create(nil);
end;

procedure DllMain(dwReason: DWORD);
begin
  case dwReason of
    // process attaches = 1
    DLL_PROCESS_ATTACH: begin
//      OutputDebugString('Process Attach!');
    end;
    // thread attaches = 2
    DLL_THREAD_ATTACH: begin
//      OutputDebugString('Thread Attach');
    end;
    // thread detaches = 3
    DLL_THREAD_DETACH: begin
//      OutputDebugString('Thread Detach');
    end;
    // process detaches = 0
    DLL_PROCESS_DETACH: begin
//      OutputDebugString('Detach!');
//      if StgForm <> nil then
//        StgForm.Free;

    end;
  end;
end;

exports _Open;

begin
//  StgForm := nil;
//  FMethod := TTmpMethod.Create;
  DLLProc:=@DllMain;

end.


