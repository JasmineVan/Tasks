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
	
	If Not DigitalSignature.UseEncryption()
	   AND Not DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
	EndIf;
	
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
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates")
	   AND Parameter.Property("IsNew") Then
		
		Items.List.Refresh();
		Items.List.CurrentRow = Source;
	EndIf;
	
	// When changing usage settings.
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("UseDigitalSignature")
	 Or Upper(Source) = Upper("UseEncryption") Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	If Not Clone Then
		
		CreationParameters = New Structure;
		CreationParameters.Insert("ToPersonalList", True);
		CreationParameters.Insert("Company", Company);
		
		DigitalSignatureInternalClient.AddCertificate(CreationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	If DigitalSignatureClient.UseEncryption()
	 Or DigitalSignatureClient.CommonSettings().CertificateIssueRequestAvailable Then
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreate", "Title", NStr("ru = 'Добавить...'; en = 'Add...'; pl = 'Add...';de = 'Add...';ro = 'Add...';tr = 'Add...'; es_ES = 'Add...'"));
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreate", "Title", NStr("ru = 'Добавить...'; en = 'Add...'; pl = 'Add...';de = 'Add...';ro = 'Add...';tr = 'Add...'; es_ES = 'Add...'"));
	Else
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
	EndIf;
	
EndProcedure

#EndRegion
