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
	
	ShowWarningOnFormClose = True;
	
	// Checking whether the form is opened from 1C:Enterprise script.
	If Not Parameters.Property("ExchangeMessageFileName") Then
		
		NString = NStr("ru = 'Форма не может быть открыта интерактивно.'; en = 'The form cannot be opened interactively.'; pl = 'Formularza nie można otworzyć interaktywnie.';de = 'Das Formular kann nicht interaktiv geöffnet werden.';ro = 'Formularul nu poate fi deschis în mod interactiv.';tr = 'Form etkileşimli olarak açılamaz.'; es_ES = 'El formulario puede abrirse de manera interactiva.'");
		Common.MessageToUser(NString,,,, Cancel);
		Return;
		
	EndIf;
	
	// Initializing the data processor with the passed parameters.
	FillPropertyValues(Object, Parameters,, "UsedFieldsList, TableFieldsList");
	
	MaxUserFields         = Parameters.MaxUserFields;
	UnapprovedMappingTableTempStorageAddress = Parameters.UnapprovedMappingTableTempStorageAddress;
	UsedFieldsList  = Parameters.UsedFieldsList;
	TableFieldsList       = Parameters.TableFieldsList;
	MappingFieldsList = Parameters.MappingFieldsList;
	
	// setting the form title.
	Title = Parameters.Title;
	
	AutomaticObjectMappingScenario();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SwitchNumber = 0;
	
	// Selecting the second wizard step.
	SetNavigationNumber(2);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Object.AutomaticallyMappedObjectsTable.Count() = 0
		Or ShowWarningOnFormClose <> True Then
		Return;
	EndIf;
			
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	ShowMessageBox(, NStr("ru = 'Форма содержит данные автоматического сопоставления. Действие отменено.'; en = 'The form contains automatic mapping data. The action is canceled.'; pl = 'Formularz zawiera dane automatycznego mapowania. Działanie zostało anulowane.';de = 'Das Formular enthält automatische Zuordnungsdaten. Die Aktion wird abgebrochen.';ro = 'Formularul conține date automate de mapare. Acțiunea este anulată.';tr = 'Form otomatik eşlenme verileri içerir. Eylem iptal edildi.'; es_ES = 'El formulario contiene los datos de mapeo automático. La acción se ha cancelado.'"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Apply(Command)
	
	ShowWarningOnFormClose = False;
	
	// Context server call
	NotifyChoice(PutAutomaticallyMappedObjectsTableInTempStorage());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ShowWarningOnFormClose = False;
	
	NotifyChoice(Undefined);
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	SetAllMarksAtServer(False);
	
EndProcedure

&AtClient
Procedure SelectAll(Command)
	
	SetAllMarksAtServer(True);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	ShowWarningOnFormClose = False;
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeNavigationNumber(Iterator)
	
	ClearMessages();
	
	SetNavigationNumber(SwitchNumber + Iterator);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > SwitchNumber);
	
	SwitchNumber = Value;
	
	If SwitchNumber < 0 Then
		
		SwitchNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Executing navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Setting page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.MainPanel.CurrentPage = Items[NavigationRowCurrent.MainPageName];
	
	If IsMoveNext AND NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation AND Not IsMoveNext Then
		
		SetNavigationNumber(SwitchNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(SwitchNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(SwitchNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("SwitchNumber", SwitchNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("ru = 'Не определена страница для отображения.'; en = 'Page to be displayed is not specified.'; pl = 'Strona do wyświetlenia nie jest zdefiniowana.';de = 'Die Seite für die Anzeige ist nicht definiert.';ro = 'Pagina pentru afișare nu este definită.';tr = 'Gösterilecek sayfa tanımlanmamış.'; es_ES = 'Página para visualizar no se ha definido.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(SwitchNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(SwitchNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(SwitchNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NavigationTableNewRow(NavigationNumber,
									MainPageName,
									OnOpenHandlerName = "",
									TimeConsumingOperation = False,
									TimeConsumingOperationHandlerName = "")
	NewRow = NavigationTable.Add();
	
	NewRow.SwitchNumber = NavigationNumber;
	NewRow.MainPageName = MainPageName;
	
	NewRow.OnOpenHandlerName = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = TimeConsumingOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
EndProcedure

&AtServer
Function PutAutomaticallyMappedObjectsTableInTempStorage()
	
	Return PutToTempStorage(Object.AutomaticallyMappedObjectsTable.Unload(New Structure("Check", True), "DestinationUUID, SourceUUID, SourceType, DestinationType"));
	
EndFunction

&AtServer
Procedure SetTableFieldVisible(Val FormTableName, Val MaxUserFieldsCount)
	
	SourceFieldName = StrReplace("#FormTableName#SourceFieldNN","#FormTableName#", FormTableName);
	DestinationFieldName = StrReplace("#FormTableName#DestinationFieldNN","#FormTableName#", FormTableName);
	
	// Making all mapping table fields invisible.
	For FieldNumber = 1 To MaxUserFieldsCount Do
		
		SourceField = StrReplace(SourceFieldName, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName, "NN", String(FieldNumber));
		
		Items[SourceField].Visible = False;
		Items[DestinationField].Visible = False;
		
	EndDo;
	
	// Making all mapping table fields that are selected by user visible.
	For Each Item In Object.UsedFieldsList Do
		
		FieldNumber = Object.UsedFieldsList.IndexOf(Item) + 1;
		
		SourceField = StrReplace(SourceFieldName, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName, "NN", String(FieldNumber));
		
		// Setting field visibility.
		Items[SourceField].Visible = Item.Check;
		Items[DestinationField].Visible = Item.Check;
		
		// Setting field titles.
		Items[SourceField].Title = Item.Presentation;
		Items[DestinationField].Title = Item.Presentation;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAllMarksAtServer(Checkmark)
	
	ValueTable = Object.AutomaticallyMappedObjectsTable.Unload();
	
	ValueTable.FillValues(Checkmark, "Check");
	
	Object.AutomaticallyMappedObjectsTable.Load(ValueTable);
	
EndProcedure

&AtClient
Procedure GoToNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure GoBack()
	
	ChangeNavigationNumber(-1);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Idle handlers

&AtClient
Procedure BackgroundJobIdleHandler()
	
	TimeConsumingOperationCompleted = False;
	
	State = DataExchangeServerCall.JobState(JobID);
	
	If State = "Active" Then
		
		AttachIdleHandler("BackgroundJobIdleHandler", 5, True);
		
	ElsIf State = "Completed" Then
		
		TimeConsumingOperation = False;
		TimeConsumingOperationCompleted = True;
		
		GoToNext();
		
	Else // Failed
		
		TimeConsumingOperation = False;
		
		GoBack();
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Navigation event handlers.

// Page 1: Automatic object mapping error.
//
&AtClient
Function Attachable_ObjectMappingError_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.Close1.DefaultButton = True;
	
	Return Undefined;
	
EndFunction

// Page 1 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectMappingWait_TimeConsumingOperationProcessing(Cancel, GoToNext)
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	JobID        = Undefined;
	TempStorageAddress    = "";
	
	Result = ScheduledJobStartAtServer(Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If Result.Status = "Running" Then
		
		GoToNext                = False;
		TimeConsumingOperation          = True;
		TimeConsumingOperationCompleted = False;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.OutputMessages    = True;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Page 2 Handler of background job completion notification.
&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	
	If Result.Status = "Error" Or Result.Status = "Canceled" Then
		RecordError(Result.DetailedErrorPresentation);
		GoBack();
	Else
		GoToNext();
	EndIf;
	
EndProcedure

// Page 1 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectsMappingWait_TimeConsumingOperationCompletion_TimeConsuminOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted Then
		
		ExecuteObjectMappingCompletion(Cancel);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Page 4: Operations with the automatic object mapping result.
//
&AtClient
Function Attachable_ObjectsMapping_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.Apply.DefaultButton = True;
	
	If EmptyResult Then
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Page 5: Empty result of automatic object mapping.
//
&AtClient
Function Attachable_BlankObjectsMappingResultBlankObjectsMappingResult_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.Close.DefaultButton = True;
	
	Return Undefined;
	
EndFunction

// Page 2: Object mapping.
//
&AtServer
Function ScheduledJobStartAtServer(Cancel)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UsedFieldsList",  UsedFieldsList);
	FormAttributes.Insert("TableFieldsList",       TableFieldsList);
	FormAttributes.Insert("MappingFieldsList", MappingFieldsList);
	
	JobParameters = New Structure;
	JobParameters.Insert("ObjectContext",             DataExchangeServer.GetObjectContext(FormAttributeToValue("Object")));
	JobParameters.Insert("FormAttributes",              FormAttributes);
	JobParameters.Insert("UnapprovedMappingTable", GetFromTempStorage(UnapprovedMappingTableTempStorageAddress));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Автоматическое сопоставление объектов'; en = 'Automatic object mapping'; pl = 'Automatyczne mapowanie obiektów';de = 'Automatische Objektzuordnung';ro = 'Maparea automată a obiectelor';tr = 'Otomatik nesne tanımlanması'; es_ES = 'Mapeo de objetos automático'");
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InfobaseObjectMapping.ExecuteAutomaticObjectMapping",
		JobParameters,
		ExecutionParameters);
		
	If Result = Undefined Then
		Cancel = True;
		Return Undefined;
	EndIf;
	
	JobID     = Result.JobID;
	TempStorageAddress = Result.ResultAddress;
	
	If Result.Status = "Error" Or Result.Status = "Canceled" Then
		Cancel = True;
		RecordError(Result.DetailedErrorPresentation);
	EndIf;
	
	Return Result;
	
EndFunction

// Page 3: Object mapping.
//
&AtServer
Procedure ExecuteObjectMappingCompletion(Cancel)
	
	Try
		AfterObjectMapping(GetFromTempStorage(TempStorageAddress));
	Except
		Cancel = True;
		RecordError(DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

&AtServer
Procedure AfterObjectMapping(Val MappingResult)
	
	DataProcessorObject = DataProcessors.InfobaseObjectMapping.Create();
	DataExchangeServer.ImportObjectContext(MappingResult.ObjectContext, DataProcessorObject);
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	EmptyResult = MappingResult.EmptyResult;
	
	If Not EmptyResult Then
		
		Modified = True;
		
		// Setting titles and table field visibility on the form.
		SetTableFieldVisible("AutomaticallyMappedObjectsTable", MaxUserFields);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordError(DetailedErrorPresentation)
	WriteLogEvent(
		NStr("ru = 'Помощник сопоставления объектов.Автоматическое сопоставление'; en = 'Object mapping wizard.Automatic object mapping'; pl = 'Kreator mapowania obiektów.Automatyczne mapowanie';de = 'Objekt-Zuordnungs-Assistent. Automatische Zuordnung';ro = 'Asistentul de confruntare a obiectelor.Confruntarea automată';tr = 'Nesne tanımlanma sihirbazı.  Otomatik eşlenme'; es_ES = 'Asistente de mapeo de objetos.Mapeo automático'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,DetailedErrorPresentation);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Filling wizard navigation table.

&AtServer
Procedure AutomaticObjectMappingScenario()
	
	NavigationTable.Clear();
	
	NavigationTableNewRow(1, "ObjectMappingError", "ObjectMappingError_OnOpen");
	
	// Waiting for object mapping.
	NavigationTableNewRow(2, "ObjectMappingWait",, True, "ObjectMappingWaiting_TimeConsumingOperationProcessing");
	NavigationTableNewRow(3, "ObjectMappingWait",, True, "ObjectMappingWaitingTimeConsumingOperationCompletion_TimeConsumingOperationProcessing");
	
	// Operations with the automatic object mapping result.
	NavigationTableNewRow(4, "ObjectMapping", "ObjectMapping_OnOpen");
	NavigationTableNewRow(5, "EmptyObjectMappingResult", "EmptyObjectMappingResultEmptyObjectMappingResult_OnOpen");
	
EndProcedure

#EndRegion
