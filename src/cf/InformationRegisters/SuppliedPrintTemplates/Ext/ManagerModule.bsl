///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure UpdateTemplatesCheckSum(Parameters) Export
	
	TemplateVersion = Metadata.Version;
	
	If Parameters.Property("TemplatesRequiringChecksumUpdate") Then
		TemplatesToProcess = Parameters.TemplatesRequiringChecksumUpdate;
	Else
		TemplatesToProcess = AllConfigurationPrintFormsTemplates();
	EndIf;
	
	TemplatesRequiringChecksumUpdate = New Map;
	ErrorsList = New Array;
	
	For Each TemplateDetails In TemplatesToProcess Do
		Owner = TemplateDetails.Value;
		OwnerName = ?(Owner = Metadata.CommonTemplates, "CommonTemplate", Owner.FullName());
		OwnerMetadataObjectID = ?(Owner = Metadata.CommonTemplates, Undefined, Common.MetadataObjectID(Owner));
		Template = TemplateDetails.Key;
		TemplateName = Template.Name;
		
		If Owner = Metadata.CommonTemplates Then
			TemplateData = GetCommonTemplate(Template);
		Else
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			
			TemplateData = Common.ObjectManagerByFullName(Owner.FullName()).GetTemplate(Template);
			
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
		EndIf;
		
		Checksum = Common.CheckSumString(TemplateData);
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.InformationRegisters.SuppliedPrintTemplates.FullName());
		DataLockItem.SetValue("TemplateName", TemplateName);
		DataLockItem.SetValue("Object", OwnerMetadataObjectID);
		
		BeginTransaction();
		Try
			DataLock.Lock();
			
			RecordManager = InformationRegisters.SuppliedPrintTemplates.CreateRecordManager();
			RecordManager.TemplateName = Template.Name;
			RecordManager.Object = OwnerMetadataObjectID;
			RecordManager.Read();
		
			If Not RecordManager.Selected() Then
				RecordManager.TemplateName = Template.Name;
				RecordManager.Object = OwnerMetadataObjectID;
			EndIf;
			
			If RecordManager.TemplateVersion = TemplateVersion Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			RecordManager.TemplateVersion = TemplateVersion;
			RecordManager.PreviousCheckSum = RecordManager.Checksum;
			RecordManager.Checksum = Checksum;
			RecordManager.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInformation = ErrorInfo();
			
			ErrorText = NStr("ru = 'Не удалось записать сведения о макете'; en = 'Failed to write layout info'; pl = 'Nie udało się zapisać informacji o szablonie';de = 'Fehler beim Schreiben der Layout-Informationen';ro = 'Eșec la înregistrarea informațiilor despre machetă';tr = 'Mizanpaj bilgisi yazılamadı.'; es_ES = 'No se ha podido guardar la información de modelo'") + Chars.LF
				+ Template.FullName() + Chars.LF
				+ DetailErrorDescription(ErrorInformation);
			
			WriteLogEvent(NStr("ru = 'Контроль изменения поставляемых макетов'; en = 'Build-in layout edit monitor'; pl = 'Zmień kontrolę dostarczonych szablonów';de = 'Kontrolle der Änderungen in den bereitgestellten Layouts';ro = 'Monitorizarea modificării machetelor furnizate';tr = 'Tedarik edilen düzenlerin kontrolünü değiştir'; es_ES = 'Control de cambios de modelos suministrados'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Template, , ErrorText);
			
			ErrorsList.Add(OwnerName + "." + TemplateName + ": " + BriefErrorDescription(ErrorInfo()));
			TemplatesRequiringChecksumUpdate.Insert(TemplateDetails.Key, TemplateDetails.Value);
		EndTry;
	EndDo;
	
	If ValueIsFilled(TemplatesRequiringChecksumUpdate) Then
		ErrorsList.Insert(0, NStr("ru = 'Не удалось записать сведения о макетах печатных форм:'; en = 'Failed to write print form layout info:'; pl = 'Nie udało się zapisać informacji o szablonach formularzy do wydruku:';de = 'Fehler beim Schreiben der Layout-Informationen für das Druckformular:';ro = 'Eșec la înregistrarea informațiilor despre machetele formelor de tipar:';tr = 'Yazdırma formu düzen bilgisi yazılamadı:'; es_ES = 'No se ha podido guardar la información de modelos de formularios de impresión:'"));
		Parameters.Insert("TemplatesRequiringChecksumUpdate", TemplatesRequiringChecksumUpdate);
		ErrorText = StrConcat(ErrorsList, Chars.LF);
		Raise ErrorText;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AllConfigurationPrintFormsTemplates() Export
	
	Result = New Map;
	
	MetadataObjectsCollections = New Array;
	MetadataObjectsCollections.Add(Metadata.Catalogs);
	MetadataObjectsCollections.Add(Metadata.Documents);
	MetadataObjectsCollections.Add(Metadata.DataProcessors);
	MetadataObjectsCollections.Add(Metadata.BusinessProcesses);
	MetadataObjectsCollections.Add(Metadata.Tasks);
	MetadataObjectsCollections.Add(Metadata.DocumentJournals);
	MetadataObjectsCollections.Add(Metadata.Reports);
	
	For Each MetadataObjectsCollection In MetadataObjectsCollections Do
		For Each MetadataObject In MetadataObjectsCollection Do
			For Each Template In MetadataObject.Templates Do
				If StrFind(Template.Name, "PF_") > 0 Then
					If (MetadataObjectsCollection = Metadata.DataProcessors Or MetadataObjectsCollection = Metadata.Reports)
						AND Not AccessRight("View", MetadataObject) Then
						Continue;
					EndIf;
					Result.Insert(Template, MetadataObject);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	For Each Template In Metadata.CommonTemplates Do
		If StrFind(Template.Name, "PF_") > 0 Then
			Result.Insert(Template, Metadata.CommonTemplates);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Generates print forms.
//
// Parameters:
//  ObjectsArray - Array - references to objects to be printed.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated spreadsheet documents (output parameter), see 
//                                            PrintManager.PreparePrintFormsCollection. 
//  PrintObjects - ValueList - value - a reference to the object.
//                                            presentation - a name of the area where the object is 
//                                                            displayed (output parameter).
//  OutputParameters - Structure - additional parameters of generated spreadsheet documents (output 
//                                            parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GuideToCreateFacsimileAndStamp");
	If PrintForm <> Undefined Then
		PrintForm.TemplateSynonym = NStr("ru = 'Как сделать факсимильную подпись и печать'; en = 'How to create facsimile signatures and stamps'; pl = 'Jak zrobić podpis faksymile i pieczęć';de = 'Wie erstellt man eine Faksimile-Signatur und einen Stempel';ro = 'Cum faceți semnătura și ștampila prin fax';tr = 'Faks imzası ve damgası nasıl yapılır'; es_ES = 'Como hacer firma y sello facsimilar'");
		PrintForm.SpreadsheetDocument = GetCommonTemplate("GuideToCreateFacsimileAndStamp");
		PrintForm.FullTemplatePath = "CommonTemplate.GuideToCreateFacsimileAndStamp";
	EndIf;
	
EndProcedure

#EndRegion

#EndIf