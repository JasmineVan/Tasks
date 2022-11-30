&AtClient
Procedure ChangePicture(Command)
	BeginPutFile(New NotifyDescription("ChangePictureAfterPutFile", ThisForm), , , True, UUID);
EndProcedure

&AtClient
Procedure ChangePictureAfterPutFile(Result, Address, SelectedFileName, AdditionalParameters) Export
	If Result Then
		PictureAddress = Address;
	EndIf;
EndProcedure

#Region SystemEvent
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not Parameters.Key.IsEmpty() Then	
		CurrentObject = Parameters.Key.GetObject();
		PictureAddress = PutToTempStorage(CurrentObject.Picture.Get());
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	If Not IsBlankString(PictureAddress) Then
		Picture = GetFromTempStorage(PictureAddress);
		PictureAddress = PictureAddress;
		IF Picture <> Undefined Then       
			CurrentObject.Picture = New ValueStorage(Picture);
			CurrentObject.Write();    
		EndIf;
	EndIf;
EndProcedure

#EndRegion	