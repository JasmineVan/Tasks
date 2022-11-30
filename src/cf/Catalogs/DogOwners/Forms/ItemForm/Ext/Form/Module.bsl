
//<< Thuong TV

&AtClient
Procedure AfterWrite(WriteParameters)
	If isFromDogOwnerList Then
		ThisForm.Close(Parameters);	
	EndIf
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("FromDogOwnerList") Then
		isFromDogOwnerList = Parameters.FromDogOwnerList;
	Else
		isFromDogOwnerList = False;
	EndIf;		
EndProcedure

//>>Thuong TV

