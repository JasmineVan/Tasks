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
	
	DigitalSignatureInternal.SetCertificateListConditionalAppearance(List);
	
	Parameters.Filter.Property("Company", Company);
	
	CloseOnChoice = False;
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		
		QueryText = List.QueryText;
		ProcessingApplicationForNewQualifiedCertificateIssue.UpdateCertificateListQuery(
			QueryText);
	Else
		QueryText = StrReplace(List.QueryText, "&AdditionalCondition", "TRUE");
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	UsersGroupOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates")
	   AND Parameter.Property("IsNew") Then
		
		Items.List.Refresh();
		Items.List.CurrentRow = Source;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsersGroupUseOnChange(Item)
	
	UsersGroupOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure UsersGroupOnChange(Item)
	
	UsersGroupOnChangeAtServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	
	If Not Clone Then
		CreationParameters = New Structure;
		CreationParameters.Insert("ToPersonalList", True);
		CreationParameters.Insert("Company",   Company);
		
		DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice(
			"ToEncryptOnly", CreationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Add(Command)
	
	Items.List.AddRow();
	
EndProcedure

&AtClient
Procedure AddFromFile(Command)
	
	CreationParameters = New Structure;
	CreationParameters.Insert("ToPersonalList", True);
	CreationParameters.Insert("Company",   Company);
	
	DigitalSignatureInternalClient.AddCertificateOnlyToEncryptFromFile(CreationParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UsersGroupOnChangeAtServer()
	
	CommonClientServer.SetDynamicListParameter(
		List, "UsersGroup", UsersGroup, UsersGroupUsage);
	
EndProcedure

#EndRegion
