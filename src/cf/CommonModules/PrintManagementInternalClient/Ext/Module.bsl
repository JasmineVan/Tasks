///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// The attached command handler.
//
// Parameters
//   RefsArrray - Array - an array of selected object references, for which the command is running.
//   ExecutionParameters - Structure - a command context.
//       * CommandDetails - Structure - information about the running command.
//          ** ID - String - a command ID.
//          ** Presentation - String - a command presentation on a form.
//          ** Name - String - a command name on a form.
//       * Form - ManagedForm - a form the command is called from.
//       * Source - FormDataStructure, FormTable - an object or a form list with the Reference field.
//
Procedure CommandHandler(Val RefsArray, Val ExecutionParameters) Export
	ExecutionParameters.Insert("PrintObjects", RefsArray);
	CommonClientServer.SupplementStructure(ExecutionParameters.CommandDetails, ExecutionParameters.CommandDetails.AdditionalParameters, True);
	RunAttachablePrintCommandCompletion(True, ExecutionParameters);
EndProcedure

// Generates a spreadsheet document in the Print subsystem form.
Procedure ExecutePrintFormOpening(DataSource, CommandID, RelatedObjects, Form, StandardProcessing) Export
	
	Parameters = New Structure;
	Parameters.Insert("Form",                Form);
	Parameters.Insert("DataSource",       DataSource);
	Parameters.Insert("CommandID", CommandID);
	If StandardProcessing Then
		NotifyDescription = New NotifyDescription("ExecutePrintFormOpeningCompletion", ThisObject, Parameters);
		PrintManagementClient.CheckDocumentsPosting(NotifyDescription, RelatedObjects, Form);
	Else
		ExecutePrintFormOpeningCompletion(RelatedObjects, Parameters);
	EndIf;
	
EndProcedure

// Opens a form for command visibility setting in the Print submenu.
Procedure OpenPrintSubmenuSettingsForm(Filter) Export
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	OpenForm("CommonForm.PrintCommandsSetup", OpeningParameters, , , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// Opening a form to select attachment format options
//
// Parameters:
//  FormatSettings - Structure - settings description
//       * PackToArchive   - Boolean - shows whether it is necessary to archive attachments.
//       * SaveFormats - Array - a list of selected save formats.
//  Notification - NotifyDescription - a notification called after closing the form for processing 
//                                          the selection result.
//
Procedure OpenAttachmentsFormatSelectionForm(FormatSettings, Notification) Export
	FormParameters = New Structure("FormatSettings", FormatSettings);
	OpenForm("CommonForm.SelectAttachmentFormat", FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region Private

// Continues the PrintManagerClient.RunAttachablePrintCommand procedure.
Procedure RunAttachablePrintCommandCompletion(FileSystemExtensionAttached, AdditionalParameters)
	
	If Not FileSystemExtensionAttached Then
		Return;
	EndIf;
	
	CommandDetails = AdditionalParameters.CommandDetails;
	Form = AdditionalParameters.Form;
	PrintObjects = AdditionalParameters.PrintObjects;
	
	CommandDetails = CommonClient.CopyRecursive(CommandDetails);
	CommandDetails.Insert("PrintObjects", PrintObjects);
	
	If CommonClient.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		
		IndicatorName = NStr("ru = 'Печать'; en = 'Print'; pl = 'Drukuj';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'") + StringFunctionsClientServer.SubstituteParametersToString("/%1/%2/%3/%4/%5/%6/%7",
			CommandDetails.ID,
			CommandDetails.PrintManager,
			CommandDetails.Handler,
			Format(CommandDetails.PrintObjects.Count(), "NG=0"),
			?(CommandDetails.SkipPreview, "Printer", ""),
			CommandDetails.SaveFormat,
			?(CommandDetails.FixedSet, "Fixed", ""));
		
		ModulePerformanceMonitorClient.StartTechologicalTimeMeasurement(True, Lower(IndicatorName));
	EndIf;
	
	If CommandDetails.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" 
		AND CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessorsClient = CommonClient.CommonModule("AdditionalReportsAndDataProcessorsClient");
			ModuleAdditionalReportsAndDataProcessorsClient.ExecuteAssignablePrintCommand(CommandDetails, Form);
			Return;
	EndIf;
	
	If Not IsBlankString(CommandDetails.Handler) Then
		CommandDetails.Insert("Form", Form);
		HandlerName = CommandDetails.Handler;
		If StrOccurrenceCount(HandlerName, ".") = 0 AND IsReportOrDataProcessor(CommandDetails.PrintManager) Then
			DefaultForm = GetForm(CommandDetails.PrintManager + ".Form", , Form, True);
			HandlerName = "DefaultForm." + HandlerName;
		EndIf;
		Handler = HandlerName + "(CommandDetails)";
		Result = Eval(Handler);
		Return;
	EndIf;
	
	If CommandDetails.SkipPreview Then
		PrintManagementClient.ExecutePrintToPrinterCommand(CommandDetails.PrintManager, CommandDetails.ID,
			PrintObjects, CommandDetails.AdditionalParameters);
	Else
		PrintManagementClient.ExecutePrintCommand(CommandDetails.PrintManager, CommandDetails.ID,
			PrintObjects, Form, CommandDetails);
	EndIf;
	
EndProcedure

// Continues execution of the PrintManagerClient.CheckDocumentsPosted procedure.
Procedure CheckDocumentsPostedPostingDialog(Parameters) Export
	
	If PrintManagementServerCall.HasRightToPost(Parameters.UnpostedDocuments) Then
		If Parameters.UnpostedDocuments.Count() = 1 Then
			QuestionText = NStr("ru = 'Для того чтобы распечатать документ, его необходимо предварительно провести. Выполнить проведение документа и продолжить?'; en = 'Cannot print unposted document. Do you want to post the document and continue?'; pl = 'Aby wydrukować dokument, najpierw go zaksięguj. Zaksięgować dokument i kontynuować?';de = 'Um das Dokument zu drucken, veröffentlichen Sie es zuerst. Das Dokument veröffentlichen und fortfahren?';ro = 'Pentru a imprima documentul, validați-l mai întâi. Validați documentul și continuați?';tr = 'Belgeyi yazdırmak için önce onaylayın. Belgeyi onayla ve devam et?'; es_ES = 'Para imprimir el documento, enviarlo primero. ¿Enviar el documento y continuar?'");
		Else
			QuestionText = NStr("ru = 'Для того чтобы распечатать документы, их необходимо предварительно провести. Выполнить проведение документов и продолжить?'; en = 'Cannot print unposted document. Do you want to post the document and continue?'; pl = 'Aby wydrukować dokumenty, należy je najpierw zaksięgować. Zaksięgować dokumenty i kontynuować?';de = 'Um Dokumente zu drucken, müssen diese zuerst veröffentlicht werden. Dokumente veröffentlichen und fortfahren?';ro = 'Pentru a imprima documentele, mai întâi trebuie să le validați. Validați documentele și continuați?';tr = 'Belgeyi yazdırmak için onu önce onaylamak gerekir. Belgeyi onayla ve devam et?'; es_ES = 'Para imprimir los documentos, se requiere enviarlos primero. ¿Enviar los documentos y continuar?'");
		EndIf;
	Else
		If Parameters.UnpostedDocuments.Count() = 1 Then
			WarningText = NStr("ru = 'Для того чтобы распечатать документ, его необходимо предварительно провести. Недостаточно прав для проведения документа, печать невозможна.'; en = 'Cannot print unposted document. You have insufficient rights to post the document. Cannot print.'; pl = 'Aby wydrukować dokument, najpierw go zaksięguj. Niewystarczające uprawnienia do księgowania dokumentu, drukowanie nie jest możliwe.';de = 'Um das Dokument zu drucken, veröffentlichen Sie es zuerst. Unzureichende Rechte zum Veröffentlichen des Dokuments können nicht gedruckt werden.';ro = 'Pentru a imprima documentul, validați-l mai întâi. Drepturile insuficiente pentru validarea documentului nu pot fi tipărite.';tr = 'Belgeyi yazdırmak için onu önce onaylayın. Belgeyi göndermek için yetersiz haklar, yazdırılamıyor.'; es_ES = 'Para imprimir el documento, enviarlo primero. Insuficientes derechos para enviar el documento, no se puede imprimir.'");
		Else
			WarningText = NStr("ru = 'Для того чтобы распечатать документы, их необходимо предварительно провести. Недостаточно прав для проведения документов, печать невозможна.'; en = 'Cannot print unposted document. You have insufficient rights to post the document. Cannot print.'; pl = 'Aby wydrukować dokumenty, najpierw je zaksięguj. Niewystarczające uprawnienia do księgowania dokumentów, drukowanie nie jest możliwe.';de = 'Um die Dokumente zu drucken, veröffentlichen Sie sie zuerst. Unzureichende Rechte zum Veröffentlichen der Dokumente können nicht gedruckt werden.';ro = 'Pentru a imprima documentele, trimiteți-le mai întâi. Drepturile insuficiente pentru validarea documentelor nu pot fi imprimate.';tr = 'Belgeleri yazdırmak için onları önce onaylayın. Belgeleri göndermek için yetersiz haklar, yazdırılamıyor.'; es_ES = 'Para imprimir los documentos, enviarlo primero. Insuficientes derechos para enviar los documentos, no se puede imprimir.'");
		EndIf;
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	NotifyDescription = New NotifyDescription("CheckDocumentsPostedDocumentsPosting", ThisObject, Parameters);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continues execution of the PrintManagerClient.CheckDocumentsPosted procedure.
Procedure CheckDocumentsPostedDocumentsPosting(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	UnpostedDocumentsData = CommonServerCall.PostDocuments(AdditionalParameters.UnpostedDocuments);
	
	MessageTemplate = NStr("ru = 'Документ %1 не проведен: %2'; en = 'Document %1 is unposted: %2'; pl = 'Dokument %1 nie został zaksięgowany: %2';de = 'Dokument %1 ist nicht veröffentlicht: %2';ro = 'Documentul %1 nu este validat: %2';tr = 'Belge %1 onaylanmadı:%2'; es_ES = 'Documento %1 no está enviado: %2'");
	UnpostedDocuments = New Array;
	For Each DocumentInformation In UnpostedDocumentsData Do
		CommonClient.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(DocumentInformation.Ref), DocumentInformation.ErrorDescription),
			DocumentInformation.Ref);
		UnpostedDocuments.Add(DocumentInformation.Ref);
	EndDo;
	PostedDocuments = CommonClientServer.ArraysDifference(AdditionalParameters.DocumentsList, UnpostedDocuments);
	ModifiedDocuments = CommonClientServer.ArraysDifference(AdditionalParameters.UnpostedDocuments, UnpostedDocuments);
	
	AdditionalParameters.Insert("UnpostedDocuments", UnpostedDocuments);
	AdditionalParameters.Insert("PostedDocuments", PostedDocuments);
	
	CommonClient.NotifyObjectsChanged(ModifiedDocuments);
	
	// If the command is called from a form, read the up-to-date (posted) copy from the infobase.
	If TypeOf(AdditionalParameters.Form) = Type("ManagedForm") Then
		Try
			AdditionalParameters.Form.Read();
		Except
			// If the Read method is unavailable, printing was executed from a location other than the object form.
		EndTry;
	EndIf;
		
	If UnpostedDocuments.Count() > 0 Then
		// Asking a user whether they want to continue printing if there are unposted documents.
		DialogText = NStr("ru = 'Не удалось провести один или несколько документов.'; en = 'Failed to post one or several documents.'; pl = 'Nie można zaksięgować jednego lub kilku dokumentów.';de = 'Ein oder mehrere Dokumente können nicht veröffentlicht werden.';ro = 'Nu se pot publica unul sau mai multe documente.';tr = 'Bir veya birkaç belge onaylanmaz.'; es_ES = 'No se puede enviar uno o varios documentos.'");
		
		DialogButtons = New ValueList;
		If PostedDocuments.Count() > 0 Then
			DialogText = DialogText + " " + NStr("ru = 'Продолжить?'; en = 'Continue?'; pl = 'Kontynuować?';de = 'Fortsetzen?';ro = 'Continuați?';tr = 'Devam et?'; es_ES = '¿Continuar?'");
			DialogButtons.Add(DialogReturnCode.Ignore, NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
			DialogButtons.Add(DialogReturnCode.Cancel);
		Else
			DialogButtons.Add(DialogReturnCode.OK);
		EndIf;
		
		NotifyDescription = New NotifyDescription("CheckDocumentsPostedCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(NotifyDescription, DialogText, DialogButtons);
		Return;
	EndIf;
	
	CheckDocumentsPostedCompletion(Undefined, AdditionalParameters);
	
EndProcedure

// Continues execution of the PrintManagerClient.CheckDocumentsPosted procedure.
Procedure CheckDocumentsPostedCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> Undefined AND QuestionResult <> DialogReturnCode.Ignore Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.CompletionProcedureDetails, AdditionalParameters.PostedDocuments);
	
EndProcedure

// Checks if a print manager is a report or a data processor.
Function IsReportOrDataProcessor(PrintManager)
	If Not ValueIsFilled(PrintManager) Then
		Return False;
	EndIf;
	SubstringsArray = StrSplit(PrintManager, ".");
	If SubstringsArray.Count() = 0 Then
		Return False;
	EndIf;
	Kind = Upper(TrimAll(SubstringsArray[0]));
	Return Kind = "REPORT" Or Kind = "DATAPROCESSOR";
EndFunction

// Continues execution of the ExecutePrintFormOpening procedure.
Procedure ExecutePrintFormOpeningCompletion(RelatedObjects, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	SourceParameters = New Structure;
	SourceParameters.Insert("CommandID", AdditionalParameters.CommandID);
	SourceParameters.Insert("RelatedObjects",    RelatedObjects);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DataSource",     AdditionalParameters.DataSource);
	OpeningParameters.Insert("SourceParameters", SourceParameters);
	OpeningParameters.Insert("CommandParameter", RelatedObjects);
	
	OpenForm("CommonForm.PrintDocuments", OpeningParameters, Form);
	
EndProcedure

// Synchronous analog of CommonClient.CreateTempDirectory for backward compatibility.
//
Function CreateTemporaryDirectory(Val Extension = "") Export 
	
	DirectoryName = TempFilesDir() + "v8_" + String(New UUID);
	If Not IsBlankString(Extension) Then 
		DirectoryName = DirectoryName + "." + Extension;
	EndIf;
	CreateDirectory(DirectoryName);
	Return DirectoryName;
	
EndFunction

#EndRegion
