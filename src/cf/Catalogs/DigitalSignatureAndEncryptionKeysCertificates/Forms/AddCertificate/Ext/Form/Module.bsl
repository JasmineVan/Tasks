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
	
	If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable
	   AND Not Parameters.HideApplication Then
		
		CertificateAddMethod = "CertificateIssueRequest";
		If Not DigitalSignature.UseEncryption() Then
			Items.Pages.CurrentPage = Items.CertificateAddMethodWithoutEncryptionPage;
		EndIf;
	Else
		Items.CertificateAddMethodPage.Visible = False;
		Items.CertificateAddMethodWithoutEncryptionPage.Visible = False;
	EndIf;
	
	Purpose = "ToSignEncryptAndDecrypt";
	If Not ValueIsFilled(CertificateAddMethod) Then
		Items.Pages.CurrentPage = Items.AssignmentPage;
	EndIf;
	
	If Not DigitalSignature.UseDigitalSignature() Then
		Purpose = "ToEncryptAndDecrypt";
		If Not ValueIsFilled(CertificateAddMethod) Then
			Items.Pages.CurrentPage = Items.AssignmentWithoutDigitalSignaturePage;
		EndIf;
		
	ElsIf Not DigitalSignature.UseEncryption()
	        AND Not ValueIsFilled(CertificateAddMethod) Then
		Cancel = True;
		Return;
	EndIf;
	
	SetCommandsCompositionForEncryptionOnly(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CertificateAdditionMethodOnChange(Item)
	
	SetCommandsCompositionOnChangeCertificateAdditionMethod();
	
EndProcedure

&AtClient
Procedure AssignmentOnChange(Item)
	
	SetCommandsCompositionForEncryptionOnly(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Add(Command)
	
	If Items.Pages.CurrentPage = Items.CertificateAddMethodPage
	 Or Items.Pages.CurrentPage = Items.CertificateAddMethodWithoutEncryptionPage Then
		
		Close(CertificateAddMethod);
	Else
		Close(Purpose);
	EndIf;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	If DigitalSignatureClient.UseDigitalSignature() Then
		Items.Pages.CurrentPage = Items.AssignmentPage;
		Purpose = "ToSignEncryptAndDecrypt";
	Else
		Items.Pages.CurrentPage = Items.AssignmentWithoutDigitalSignaturePage;
		Purpose = "ToEncryptAndDecrypt";
	EndIf;
	
	Items.FormAdd.Visible = True;
	Items.FormNext.Visible = False;
	Items.FormBack.Visible = True;
	Items.FormAdd.DefaultButton = True;
	
	SetCommandsCompositionForEncryptionOnly(ThisObject);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.CertificateAddMethodPage;
	Items.FormBack.Visible = False;
	
	SetCommandsCompositionOnChangeCertificateAdditionMethod();
	
EndProcedure

&AtClient
Procedure AddFromFile(Command)
	
	Close("OnlyForEncryptionFromFile");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetCommandsCompositionOnChangeCertificateAdditionMethod()
	
	AddRequest = CertificateAddMethod = "CertificateIssueRequest";
	
	Items.FormAdd.Visible = AddRequest;
	Items.FormNext.Visible = Not AddRequest;
	Items.FormAdd.DefaultButton = AddRequest;
	Items.FormNext.DefaultButton = Not AddRequest;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCommandsCompositionForEncryptionOnly(Form)
	
	Items = Form.Items;
	FromFile = Form.Purpose = "ToEncryptOnly";
	
	Items.AddFromFile1.Visible = FromFile;
	Items.AddFromFile2.Visible = FromFile;
	
EndProcedure

#EndRegion
