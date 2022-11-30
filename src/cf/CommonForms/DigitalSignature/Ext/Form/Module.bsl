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
	
	FillPropertyValues(ThisObject, Parameters.SignatureProperties);
	
	If Parameters.SignatureProperties.SignatureCorrect Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
		Items.Instruction.Visible     = False;
		Items.ErrorDescription.Visible = False;
	Else
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ErrorDescription");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureClient.SaveSignature(SignatureAddress);
	
EndProcedure

&AtClient
Procedure OpenCertificate(Command)
	
	If ValueIsFilled(CertificateAddress) Then
		DigitalSignatureClient.OpenCertificate(CertificateAddress);
		
	ElsIf ValueIsFilled(Thumbprint) Then
		DigitalSignatureClient.OpenCertificate(Thumbprint);
	EndIf;
	
EndProcedure

#EndRegion
