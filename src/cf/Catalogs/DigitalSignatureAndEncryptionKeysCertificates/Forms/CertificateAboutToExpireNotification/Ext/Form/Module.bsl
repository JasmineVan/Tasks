///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Certificate = Parameters.Certificate;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	If DontRemindAgain Then
		SetMarkAtServer(Certificate);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMarkAtServer(Certificate)
	
	CertificateObject = Certificate.GetObject();
	CertificateObject.UserNotifiedOfExpirationDate = True;
	CertificateObject.Write();
	
EndProcedure

#EndRegion
