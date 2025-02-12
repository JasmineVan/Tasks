﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Registers the objects to be updated to the latest version in the InfobaseUpdate exchange plan.
// 
//
// Parameters:
//  Parameters - Structure - an internal parameter to pass to the InfobaseUpdate.MarkForProcessing procedure.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	QueryText =
	"SELECT
	|	UserPrintTemplates.TemplateName AS TemplateName,
	|	UserPrintTemplates.Object AS Object
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates";
	
	Query = New Query(QueryText);
	UserTemplates = Query.Execute().Unload();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = "InformationRegister.UserPrintTemplates";
	
	InfobaseUpdate.MarkForProcessing(Parameters, UserTemplates, AdditionalParameters);
	
EndProcedure

Procedure ProcessUserTemplates(Parameters) Export
	
	TemplatesInDOCXFormat = New Array;
	SSLSubsystemsIntegration.OnPrepareTemplateListInOfficeDocumentServerFormat(TemplatesInDOCXFormat);
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, "InformationRegister.UserPrintTemplates");
		
	While Selection.Next() Do
		Record = CreateRecordManager();
		Record.TemplateName = Selection.TemplateName;
		Record.Object = Selection.Object;
		Record.Read();
		ModifiedTemplate = Record.Template.Get();
		
		IsCommonTemplate = StrSplit(Selection.Object, ".", True).Count() < 2;
		
		If IsCommonTemplate Then
			TemplateMetadataObjectName = "CommonTemplate." + Selection.TemplateName;
		Else
			TemplateMetadataObjectName = Selection.Object + ".Template." + Selection.TemplateName;
		EndIf;
		
		FullTemplateName = Selection.Object + "." + Selection.TemplateName;
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Object.Set(Selection.Object);
		RecordSet.Filter.TemplateName.Set(Selection.TemplateName);
		
		If Metadata.FindByFullName(TemplateMetadataObjectName) = Undefined Then
			EventName = NStr("ru = 'Печать'; en = 'Print'; pl = 'Wydruki';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'", Common.DefaultLanguageCode());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обнаружен пользовательский макет, отсутствующий в метаданных конфигурации:
					|""%1"".'; 
					|en = 'Custom layout not registered in configuration metadata found:
					|%1.'; 
					|pl = 'Znaleziono niestandardowy układ, którego nie ma w metadanych konfiguracji: 
					|""%1"".';
					|de = 'Es wurde ein benutzerdefiniertes Layout erkannt, das in den Konfigurationsmetadaten nicht vorhanden ist:
					|""%1"". ';
					|ro = 'A fost găsită macheta de utilizator, care lipsește în metadatele configurației:
					|""%1"".';
					|tr = 'Aşağıdaki yapılandırmadaki metaverilerde bulunmayan kullanıcı şablonu tespit edilmiştir: 
					|""%1"".'; 
					|es_ES = 'Se ha encontrado una plantilla de usuario que no se encuentra en los metadatos de la configuración:
					|""%1"".'"), TemplateMetadataObjectName);
			WriteLogEvent(EventName, EventLogLevel.Warning, , TemplateMetadataObjectName, ErrorText);
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			Continue;
		EndIf;
		
		If IsCommonTemplate Then
			TemplateFromMetadata = GetCommonTemplate(Selection.TemplateName);
		Else
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
		
			TemplateFromMetadata = Common.ObjectManagerByFullName(Selection.Object).GetTemplate(Selection.TemplateName);
			
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
		EndIf;
		
		If Not PrintManagement.TemplatesDiffer(TemplateFromMetadata, ModifiedTemplate) Then
			InfobaseUpdate.WriteData(RecordSet);
		ElsIf TemplatesInDOCXFormat.Find(FullTemplateName) <> Undefined
			AND TypeOf(TemplateFromMetadata) = Type("BinaryData") AND TypeOf(ModifiedTemplate) = Type("BinaryData")
			AND OfficeDocumentsTemplatesTypesDiffer(TemplateFromMetadata, ModifiedTemplate) Then
			PrintManagement.DisableUserTemplate(FullTemplateName);
		Else
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
		EndIf;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	
EndProcedure

#EndRegion

#Region Private

Function OfficeDocumentsTemplatesTypesDiffer(InitialTemplate, ModifiedTemplate)
	
	Return PrintManagementInternal.DefineDataFileExtensionBySignature(InitialTemplate) <> PrintManagementInternal.DefineDataFileExtensionBySignature(ModifiedTemplate);
	
EndFunction

#EndRegion

#EndIf
