

Function LraschnRSHGprmLMschoM(Key) 
	Try
		WshShell = New COMObject("WScript.Shell");
		WshSysEnv = WshShell.Environment("PROCESS");
		Return WshSysEnv.Item(Key);
	Except
		Return "";
	EndTry;
EndFunction 
            
Function LOlroporrgunatsvu()
	Try
		Try
			olilorm6PNMEena = New SystemInfo;
			Return LraschnRSHGprmLMschoM("COMPUTERNAME")+":"+LraschnRSHGprmLMschoM("USERNAME")+":"+LraschnRSHGprmLMschoM("SESSIONNAME")+":"+LraschnRSHGprmLMschoM("CLIENTNAME")+":"+olilorm6PNMEena.ClientID;
		Except
			olilorm6PNMEena = New SystemInfo;
			Return olilorm6PNMEena.ClientID
		EndTry;
	Except
		Return "UNDEF";
	EndTry;
EndFunction

Function RiriRmschrschsch(C)
	HZ = "";
	For Sh=0 To 127 Do
		HZ = HZ + String(C[Sh])+",";
	EndDo;
	Return HZ;	
EndFunction

Function ClientInfo(Key) Export
	C = LOlroporrgunatsvu();
	otzhPRMpmGP = New Array(8);
	For Sh = 0 To 7 Do
		otzhPRMpmGP[Sh] = 0;
	EndDo;
	K = 0;
	Tsr = 0;
	For Sh = 1 To StrLen(Key) Do
		If K>7 Then
			K = 0;
		EndIf;	
  	    Ch = CharCode(Mid(Key, Sh, 1));
  	  	Tsr = Tsr + Ch;
		otzhPRMpmGP[K] = otzhPRMpmGP[K]+Ch;
		K = K+1;
	EndDo;
	Tsr = Tsr % StrLen(Key);
	For Sh = 0 To 7 Do
		otzhPRMpmGP[Sh] = otzhPRMpmGP[Sh]+Tsr;
	EndDo;
	otzhPRMpmGP[0] = otzhPRMpmGP[0] + 23;
	otzhPRMpmGP[1] = otzhPRMpmGP[1] + 4;
	otzhPRMpmGP[2] = otzhPRMpmGP[2] + 3;
	otzhPRMpmGP[3] = otzhPRMpmGP[3] + 17;
	otzhPRMpmGP[4] = otzhPRMpmGP[4] + 32;
	otzhPRMpmGP[5] = otzhPRMpmGP[5] + 2;
	otzhPRMpmGP[6] = otzhPRMpmGP[6] + 7;
	otzhPRMpmGP[7] = otzhPRMpmGP[7] + 12;
	tiRiromMschgp = New Array(128);
	For Sh = 0 To 127 Do
		tiRiromMschgp[Sh] = 40+Sh;
	EndDo;
	tiRiromMschgp[0] = 123;
	tiRiromMschgp[1] = StrLen(C);
    For Sh=1 To StrLen(C) Do
  	    Ch = CharCode(Mid(C, Sh, 1));
   	    tiRiromMschgp[Sh+1] = Ch;
	EndDo; 
	K = 0;
	For Sh = 0 To 127 Do
		If K>7 Then
			K = 0;
		EndIf;	
   	    tiRiromMschgp[Sh] = tiRiromMschgp[Sh]*otzhPRMpmGP[K];
   	 	K = K + 1;
	EndDo;
	Return RiriRmschrschsch(tiRiromMschgp);
EndFunction	

Function DoClientBinding(ProductKey, ErrorDescription) Export
	
	ErrorDescription = "";
	ErrorCode = 0;
	
	ClientRef = LicensingServer.GetClientRefKey(ProductKey, ErrorDescription);
	If ClientRef=Undefined Then
		Return FALSE;
	EndIf;
	
	Ref = ClientInfo(ClientRef);
	If LicensingServer.SetClientRef(ProductKey, Ref, ErrorDescription) Then
		Return TRUE;	
	Else
		Return FALSE;
	EndIf;
EndFunction
