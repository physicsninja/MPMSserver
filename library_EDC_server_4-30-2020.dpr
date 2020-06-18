library two_meters_one_source;

uses
  SysUtils,
  Classes,
  Windows,
  Dialogs,
  MpmsUnit,
  MpmsExports,
  MpmsOleDll,
  MpmsDefinitions,
  IdBaseComponent, //these are the components of INDY 10 for the TCP client to work
  IdComponent, 
  StrUtils,
  IdTCPConnection, 
  IdTCPClient, 
  ScktComp;

var
  ExitProcSave : Pointer; {Default Exit procedure pointer, Do Not Remove.}
  SourceCurrent : Single;
  VoltageLimit6220Str : string;
  {------------------- Start of User Code ------------------------}
  {User defined types go here}
const
	CRLF : string = #13#10;
  Delaytime : Integer = 0;

function SendToGPIB(const address: integer, const command :string): Boolean;
var
  success : Boolean;
begin
  success := Mpms.send(address, command + CRLF);
  Result := success;
end;


function QueryGPIB(const address: integer; const command :string) : string;
var
  measurement : string;
  numbytes : Integer;
begin
  numbytes := Mpms.SendRead(address,command + CRLF, measurement); 
  Result := measurement;
end;

procedure ReadfromGPIB(const address: integer, var measurement : string);
begin
  Mpms.Read(address, measurement);                 
end;

function GetFromMPMS(command: string): Single ;
var
  remainder: string;
  mpms_command: string;
begin
  remainder := Copy(command,6,MaxInt);
  mpms_command := Copy(remainder,1,5); //get the 5 letter command
  if CompareText('field',mpms_command) = 0 then
  begin
  Result := Mpms.GetField();
  end
  else if CompareText('stemp',mpms_command) = 0 then
  begin
  Result := Mpms.GetSystemTemp();
  end
  else Abort;

  end;

function get_approach(option : integer): emDAMPING_TYPE;
begin
  case option of
    1: Result := OSCILLATE;
    2: Result := NO_OVERSHOOT;
    3: Result := HYST_MODE;
  else Abort
  end
end;

function get_resolution(option : integer): emRESOLUTION_TYPE;
begin
  case option of
    1: Result := HI_RES;
    2: Result := LO_RES;
  else Abort
  end
end;


function SetMPMS(command: string): Boolean ;
var
  index: integer;
  remainder: string;
  arguments : string;
  mpms_command: string;
  setpoint : single;
  opt1 : integer;
  opt2 : integer;
  rate : single;
begin
  remainder := Copy(command,6,MaxInt); // basically cut away the mset:
  index :=AnsiPos(':',remainder);
  if index = 0 then Abort;  //command is malformed so abort

  mpms_command := Copy(remainder,1,5); //get the 5 letter command
  arguments := Copy(remainder,7,MaxInt); //drop the field: or stemp: piece
  index := AnsiPos(':',arguments);


  if CompareText('field',mpms_command) = 0 then
  begin
    setpoint := StrToFloat(Copy(arguments,1,index-1));

    if Length(Copy(arguments,index+1,MaxInt)) <> 2 then Abort;
    opt1 := StrToInt(Copy(arguments,index+1,1));
    opt2 := StrToInt(Copy(arguments,index+2,1));
    Result := Mpms.SetField(setpoint,get_approach(opt1),get_resolution(opt2));

    end
    else if CompareText('stemp',mpms_command) = 0 then
  begin
    setpoint := StrToFloat(Copy(arguments,1,index-1));
    rate := StrToFloat(Copy(arguments,index+1,MaxInt));
    Result := Mpms.SetTemp(setpoint,rate);
  end
  else Abort;
  end;

function SetGPIB(command: string): Boolean ;
var
  remainder: string;
  gpib_command: string;
  gpib_address: integer;
  index : integer;
  success: Boolean;
begin
  remainder := Copy(command,6,MaxInt);
  index :=  AnsiPos(':',remainder); //this is necessary because GPIB address can be <10
  gpib_address := StrToInt(Copy(remainder,1,index-1));
  gpib_command := Copy(remainder, index+1,MaxInt);
  success := SendToGPIB(gpib_address,gpib_command);
  Result:= success;
  end;

function GetGPIB(command: string): string ;
var
  remainder: string;
  gpib_command: string;
  gpib_address: integer;
  index : integer;
begin
  remainder := Copy(command,6,MaxInt);
  index :=  AnsiPos(':',remainder); //this is necessary because GPIB address can be <10
  gpib_address := StrToInt(Copy(remainder,1,index-1));
  gpib_command := Copy(remainder, index+1,MaxInt);
  Result:= QueryGPIB(gpib_address,gpib_command);
  end;


  {==================== End of User Code =========================}

//////////////////////////////////////////////////////////////////
function Initialize : Integer; cdecl;
  {------------------- Start of User Code ------------------------}
  {Users local variable definitions go here.}


  {==================== End of User Code =========================}
begin
  try  {Do not remove}

  {------------------- Start of User Code ------------------------}
    {Users initialization code goes here.}

    Result := Good;  {function result returned to MultiVu}
  {==================== End of User Code =========================}

  except {Do not modify code in this exception handler}
    on EAbort do
      begin
      Result := Bad;
      end;
  end;

end;

//////////////////////////////////////////////////////////////////
function ExecuteEDC(const measureText : pChar) : Integer; cdecl;
  {------------------- Start of User Code ------------------------}
  {Users local variable definitions go here.}
var
  quitting : Boolean;
  quitter: string;
  heartbeat_response : string;
  heartbeat : string;
  MPMS_identifier :string;
  response : String;
  reply: String;
  left: String;
  IdTCPClient1: TIdTCPClient;

  {==================== End of User Code ==========================}
begin
  try {Do not remove}

  {------------------- Start of User Code ------------------------}
 // Initialize local variable
    
    quitting := False;
    quitter := 'quit:';
    heartbeat_response := 'yeet:'; 		//what the MPMS expects the server to respond. why yeet? Because. 
    heartbeat := 'heartbeat'; 			//msg to send to ask for updates, say 'I'm here'
    MPMS_identifier := 'MPMS:'; 		//what the MPMS sends to the server to identify itself as the MPMS
    IdTCPClient1 := TIdTCPClient.Create(nil); 	//create an instance of the IndyTCPClient
    IdTCPClient1.Host := '127.0.0.1'; 		//localhost
    IdTCPClient1.Port := 8081; 			// arbitrary
    IdTCPClient1.ConnectTimeout := 2000; 	// 2 second time strikes a nice balance between responsive and responsible
    repeat

      IdTCPClient1.Connect; //connect to the server
      IdTCPClient1.IOHandler.Write(MPMS_identifier +heartbeat); // let the server know we are still around
      response := IdTCPClient1.IOHandler.AllData; 		// listen to what the server has to say to us
      IdTCPClient1.Disconnect; 					// disconnect from the server so we don't leave any loose ends
      left := Copy(response,0,5); 				// get the leftmost 5 characters to figure out what to do
      if CompareText(heartbeat_response,left) = 0 then begin 	// we got "yeet:" back
            reply := 'heartyeet';
            end
      else if CompareText('mget:',left) = 0 then begin		// we got a request for data from the MPMS
            reply := 'MPMS:reporting:' + FloatToStr(GetFromMPMS(response));
            end
      else if CompareText('mset:',left) = 0 then begin		// we got a request to set some parameter of the MPMS 
              if SetMpms(response) then
                reply := 'MPMS:reporting:success';
            end
      else if CompareText('gget:',left) = 0 then begin		// we got a request to get something from a GPIB connnected instrument
            reply := 'MPMS:reporting:' + GetGPIB(response);
            end
      else if CompareText('gset:',left) = 0 then begin		// we got a request to set something on a GPIB connected instrument
            if SetGPIB(response) then reply := 'MPMS:reporting:success'
            else reply := 'MPMS:reporting:failure';
            end
      else if CompareText(quitter,left) = 0 then begin		// we were told to give up and shut down
            quitting := True;
            end
      else							// we received a commmand we didn't understand, server is borked?, give up
         begin
         reply := '400:quitting';
         IdTCPClient1.Connect;
         IdTCPClient1.IOHandler.Write(reply);
         response := IdTCPClient1.IOHandler.AllData;
         IdTCPClient1.Disconnect;
         quitting := True;
         end ;

      if (quitting = False) and (CompareText(reply,'heartyeet')<>0) then // do we have data to send to the server? send it.
        begin
          IdTCPClient1.Connect;
          IdTCPClient1.IOHandler.Write(reply);
          response := IdTCPClient1.IOHandler.AllData;
          IdTCPClient1.Disconnect;
        end

    until quitting = True;
    IdTCPClient1.Free;
        Result := Good;  {function result returned to MultiVu}
  {==================== End of User Code =========================}

  except  {Do not modify code in this exception handler}
    on EAbort do
      begin
      Result := Bad;
      end;
    on EConvertError do
      begin
      Result := 2;
      end;
  end;
end;

//////////////////////////////////////////////////////////////////
function Finish : Integer; cdecl;
  {------------------- Start of User Code ------------------------}
  {Users local variable definitions go here.}


  {==================== End of User Code =========================}
begin {Implementation code for ExecuteEDC function}
  try
  {------------------- Start of User Code ------------------------}
    {Users finalization code goes here.}


    Result := Good;  {function result returned to MultiVu}

  {==================== End of User Code =========================}
  except  {Do not modify code in this exception handler}
    on EAbort do
      begin
      Result := Bad;
      end;
  end;
end;

{Do not modify these export declarations unless you add more}
exports
  Initialize,
  ExecuteEDC,
  Finish;

//////////////////////////////////////////////////////////////////
procedure EDCExitProc;
begin
  {------------------- Start of User Code ------------------------}
  {Users DLL exit code goes here.}


  {==================== End of User Code =========================}
  {Do Not Remove}
  ExitProc := ExitProcSave; // restore the existing ExitProc address
end;


//////////////////////////////////////////////////////////////////
begin
  {------------------- Start of User Code ------------------------}
  {Users DLL initialization code goes here.}




  {==================== End of User Code =========================}

  {This code saves the exit procedure address and installs the
  EDCExitProc which will be called when the DLL is removed from
  memory at the end of an Mpms MultiVu sequence.}
  {Do Not Remove}
  ExitProcSave := ExitProc; // save the existing ExitProc address
  ExitProc := @EDCExitProc; // Install EDC exit procedure

end.
