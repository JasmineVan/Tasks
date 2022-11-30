///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ClientParameters Export;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	SaveCertificateWithSignature = PersonalSettings.SaveCertificateWithSignature;
	SaveCertificateWithSignatureSourceValue = SaveCertificateWithSignature;
	
	SaveAllSignatures = Parameters.SaveAllSignatures;
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Not Parameters.ShowComment Then
		Items.SignaturesTableComment.Visible = False;
	EndIf;
	
	FillSignatures(Parameters.Object);
	
	DontAskAgain = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If SaveAllSignatures Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, ClientParameters.CurrentPresentationsList);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveSignature(Command)
	
	If DontAskAgain Or (SaveCertificateWithSignature <> SaveCertificateWithSignatureSourceValue)Then
		SaveSettings(DontAskAgain, SaveCertificateWithSignature);
		RefreshReusableValues();
		Notify("Write_PersonalSettingsForDigitalSignatureAndEncryption", New Structure, "ActionsOnSavingWithDS, SaveCertificateWithSignature");
	EndIf;
	
	Close(SignatureTable);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	DigitalSignatureInternal.RegisterSignaturesList(ThisObject, "SignatureTable");
	
EndProcedure

&AtServer
Procedure FillSignatures(Object)
	
	If TypeOf(Object) = Type("String") Then
		SignaturesCollection = GetFromTempStorage(Object);
	Else
		SignaturesCollection = DigitalSignature.SetSignatures(Object);
	EndIf;
	
	For each AllSignatureProperties In SignaturesCollection Do
		NewRow = SignatureTable.Add();
		FillPropertyValues(NewRow, AllSignatureProperties);
		
		NewRow.SignatureAddress = PutToTempStorage(
			AllSignatureProperties.Signature, UUID);
		
		DataByCertificate = DigitalSignatureInternal.DataByCertificate(AllSignatureProperties, UUID);
		FillPropertyValues(NewRow, DataByCertificate);
		
		NewRow.Check = True;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure SaveSettings(DontAskAgain, SaveCertificateWithSignature)
	
	SettingsSection = New Structure;
	If DontAskAgain Then
		SettingsSection.Insert("ActionsOnSavingWithDS", "SaveAllSignatures");
	EndIf;
	SettingsSection.Insert("SaveCertificateWithSignature", SaveCertificateWithSignature);
	DigitalSignatureInternal.SavePersonalSettings(SettingsSection);
	RefreshReusableValues();
	
EndProcedure

#EndRegion
