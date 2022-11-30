///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// Optional form parameters:
//
//    SimplifiedMode - Boolean - a flag showing whether a simplified report is generated.
//

#Region EventHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.FormReportSettings.Visible = False;
	
	ThisDataProcessor = ThisObject();
	If IsBlankString(Parameters.ObjectAddress) Then
		SourceObject = ThisDataProcessor.InitializeThisObject(Parameters.ObjectSettings);
	Else
		SourceObject = ThisDataProcessor.InitializeThisObject(Parameters.ObjectAddress) 
	EndIf;
	
	// Editing filter according to the node scenario and imitating global filter.
	If SourceObject.ExportOption=3 Then
		SourceObject.ExportOption = 2;
		
		SourceObject.AllDocumentsFilterComposer = Undefined;
		SourceObject.AllDocumentsFilterPeriod      = Undefined;
		
		DataExchangeServer.FillValueTable(SourceObject.AdditionalRegistration, SourceObject.AdditionalNodeScenarioRegistration);
	EndIf;
	SourceObject.AdditionalNodeScenarioRegistration.Clear();
		
	ThisObject(SourceObject);
	
	If Not ValueIsFilled(Object.InfobaseNode) Then
		Text = NStr("ru='Настройка обмена данными не найдена.'; en = 'The data exchange setting is not found.'; pl = 'Ustawienia wymiany danych nie zostały znalezione.';de = 'Datenaustauscheinstellung wurde nicht gefunden.';ro = 'Setarea schimbului de date nu a fost găsită.';tr = 'Veri değişimi ayarı bulunmadı.'; es_ES = 'Configuración del intercambio de datos no se ha encontrado.'");
		DataExchangeServer.ReportError(Text, Cancel);
		Return;
	EndIf;
	
	Title = Title + " (" + Object.InfobaseNode + ")";
	BaseNameForForm = ThisDataProcessor.BaseNameForForm();
	
	Parameters.Property("SimplifiedMode", SimplifiedMode);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GenerateClientSpreadsheetDocument();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	OnCloseAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
//

&AtClient
Procedure DetailProcessingResult(Item, Details, StandardProcessing)
	StandardProcessing = False;
	
	DetailsParameters = FirstLevelDetailParameters(Details);
	If DetailsParameters <> Undefined Then
		If DetailsParameters.RegistrationObjectMetadataName = DetailsParameters.FullMetadataName Then
			DetailsType = TypeOf(DetailsParameters.RegistrationObject);
			
			If DetailsType = Type("Array") Or DetailsType = Type("ValueList") Then
				// List details
				DetailsParameters.Insert("ObjectSettings", Object);
				DetailsParameters.Insert("SimplifiedMode", SimplifiedMode);
				
				OpenForm(BaseNameForForm + "Form.ExportComposition", DetailsParameters);
				Return;
			EndIf;
			
			// Object details
			FormParameters = New Structure("Key", DetailsParameters.RegistrationObject);
			OpenForm(DetailsParameters.FullMetadataName + ".ObjectForm", FormParameters);

		ElsIf Not IsBlankString(DetailsParameters.ListPresentation) Then
			// Opening this form with new parameters.
			DetailsParameters.Insert("ObjectSettings", Object);
			DetailsParameters.Insert("SimplifiedMode", SimplifiedMode);
			
			OpenForm(BaseNameForForm + "Form.ExportComposition", DetailsParameters);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers
//

&AtClient
Procedure GenerateReport(Command)
	
	GenerateClientSpreadsheetDocument();
	
EndProcedure

&AtClient
Procedure ReportSettings(Command)
	Items.FormReportSettings.Check = Not Items.FormReportSettings.Check;
	Items.SettingsComposerUserSettings.Visible = Items.FormReportSettings.Check;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessJobExecutionResult()
	
	ImportReportResultServer();
	
	StatePresentation = Items.Result.StatePresentation;
	StatePresentation.Visible = False;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	
EndProcedure

&AtServer
Function ThisObject(NewObject=Undefined)
	If NewObject=Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(NewObject, "Object");
	Return Undefined;
EndFunction

&AtClient
Procedure GenerateClientSpreadsheetDocument()
	
	BackgroundJobStartResult = GenerateSpreadsheetDocumentServer();
	
	If BackgroundJobStartResult.Status = "Running" Then
		
		StatePresentation = Items.Result.StatePresentation;
		StatePresentation.Visible                      = True;
		StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		StatePresentation.Picture                       = PictureLib.TimeConsumingOperation48;
		StatePresentation.Text                          = NStr("ru = 'Отчет формируется...'; en = 'Generating report...'; pl = 'Generowanie sprawozdania...';de = 'Den Bericht erstellen...';ro = 'Are loc generarea raportului...';tr = 'Rapor oluşturma...'; es_ES = 'Generando el informe...'");
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(BackgroundJobStartResult, CompletionNotification, IdleParameters);
		
	Else
		AttachIdleHandler("ImportReportResultClient", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Function GenerateSpreadsheetDocumentServer()
	
	StopReportGeneration();
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorStructure",  ThisObject().ThisObjectInStructureForBackgroundJob());
	JobParameters.Insert("FullMetadataName", Parameters.FullMetadataName);
	JobParameters.Insert("Presentation",       Parameters.ListPresentation);
	JobParameters.Insert("SimplifiedMode",     SimplifiedMode);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = 
		NStr("ru='Формирование отчета по составу данных для отправки при синхронизации'; en = 'Generate report on data to be sent during synchronization'; pl = 'Wygeneruj raport, dotyczący zawartości danych, który ma zostać wysłany podczas synchronizacji';de = 'Generieren Sie einen Bericht über den Dateninhalt';ro = 'Generarea raportului privind componența datelor pentru trimitere la sincronizare';tr = 'Senkronizasyon sırasında gönderilecek veri içeriği hakkında bir rapor oluşturun'; es_ES = 'Generar un informe del contenido de datos para enviar durante la sincronización'");
	
	BackgroundJobStartResult = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeServer.InteractiveExportModification_GenerateUserTableDocument",
		JobParameters,
		ExecutionParameters);
	
	BackgroundJobID   = BackgroundJobStartResult.JobID;
	BackgroundJobResultAddress = BackgroundJobStartResult.ResultAddress;
	
	Return BackgroundJobStartResult;
	
EndFunction

&AtClient
Procedure BackgroundJobCompletion(BackgroundJobStartResult, AdditionalParameters) Export
	
	ImportReportResultClient();
	
EndProcedure

&AtClient
Procedure ImportReportResultClient()
	ProcessJobExecutionResult();
EndProcedure

&AtServer
Procedure StopReportGeneration()
	
	TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
	If Not IsBlankString(BackgroundJobResultAddress) Then
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	
	BackgroundJobResultAddress = "";
	BackgroundJobID = Undefined;
	
EndProcedure

&AtServer
Procedure ImportReportResultServer()
	
	ReportData = Undefined;
	
	If Not IsBlankString(BackgroundJobResultAddress) Then
		ReportData = GetFromTempStorage(BackgroundJobResultAddress);
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	
	StopReportGeneration();
	
	If TypeOf(ReportData)<>Type("Structure") Then
		Return;
	EndIf;
	
	Result = ReportData.SpreadsheetDocument;
	ClearDetails();
	
	DetailsDataAddress = PutToTempStorage(ReportData.Details, New UUID);
	CompositionSchemaAddress   = PutToTempStorage(ReportData.CompositionSchema, New UUID);
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	StopReportGeneration();
	ClearDetails();
EndProcedure

&AtServer
Procedure ClearDetails()
	
	If Not IsBlankString(DetailsDataAddress) Then
		DeleteFromTempStorage(DetailsDataAddress);
	EndIf;
	If Not IsBlankString(CompositionSchemaAddress) Then
		DeleteFromTempStorage(CompositionSchemaAddress);
	EndIf;
	
EndProcedure

&AtServer
Function FirstLevelDetailParameters(Details)
	
	DetailProcessing = New DataCompositionDetailsProcess(
		DetailsDataAddress,
		New DataCompositionAvailableSettingsSource(CompositionSchemaAddress));
	
	MetadataNameField = New DataCompositionField("FullMetadataName");
	Settings = DetailProcessing.DrillDown(Details, MetadataNameField);
	
	DetailsParameters = New Structure("FullMetadataName, ListPresentation, RegistrationObject, RegistrationObjectMetadataName");
	DetailLevelGroupAnalysis(Settings.Filter, DetailsParameters);
	
	If IsBlankString(DetailsParameters.FullMetadataName) Then
		Return Undefined;
	EndIf;
	
	Return DetailsParameters;
EndFunction

&AtServer
Procedure DetailLevelGroupAnalysis(Filter, DetailsParameters)
	
	MetadataNameField = New DataCompositionField("FullMetadataName");
	PresentationField = New DataCompositionField("ListPresentation");
	ObjectField        = New DataCompositionField("RegistrationObject");
	
	For Each Item In Filter.Items Do
		If TypeOf(Item)=Type("DataCompositionFilterItemGroup") Then
			DetailLevelGroupAnalysis(Item, DetailsParameters);
			
		ElsIf Item.LeftValue=MetadataNameField Then
			DetailsParameters.FullMetadataName = Item.RightValue;
			
		ElsIf Item.LeftValue=PresentationField Then
			DetailsParameters.ListPresentation = Item.RightValue;
			
		ElsIf Item.LeftValue=ObjectField Then
			RegistrationObject = Item.RightValue;
			DetailsParameters.RegistrationObject = RegistrationObject;
			
			If TypeOf(RegistrationObject) = Type("Array") AND RegistrationObject.Count()>0 Then
				Option = RegistrationObject[0];
			ElsIf TypeOf(RegistrationObject) = Type("ValueList") AND RegistrationObject.Count()>0 Then
				Option = RegistrationObject[0].Value;
			Else
				Option = RegistrationObject;
			EndIf;
			
			Meta = Metadata.FindByType(TypeOf(Option));
			DetailsParameters.RegistrationObjectMetadataName = ?(Meta = Undefined, Undefined, Meta.FullName());
		EndIf;
		
	EndDo;
EndProcedure

#EndRegion
