///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a form with available commands.
//
// Parameters:
//   CommandParameter - Arbitrary - passed "as is" from the command handler parameters.
//   CommandExecuteParameters - CommandExecuteParameters - passed "as is" from the command handler parameters.
//   Kind - String - a data processor kind that can be obtained from the function series:
//       AdditionalReportsAndDataProcessorsClientServer.DataProcessorKind<...>.
//   SectionName - String - a name of the command interface section the command is called from.
//
Procedure OpenAdditionalReportAndDataProcessorCommandsForm(CommandParameter, CommandExecuteParameters, Kind, SectionName = "") Export
	
	RelatedObjects = New ValueList;
	If TypeOf(CommandParameter) = Type("Array") Then // assignable data processor
		RelatedObjects.LoadValues(CommandParameter);
	ElsIf CommandParameter <> Undefined Then
		RelatedObjects.Add(CommandParameter);
	EndIf;
	
	Parameters = New Structure("RelatedObjects, Kind, SectionName, WindowOpeningMode");
	Parameters.RelatedObjects = RelatedObjects;
	Parameters.Kind = Kind;
	Parameters.SectionName = SectionName;
	Parameters.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ManagedForm") Then // assignable data processor
		Parameters.Insert("FormName", CommandExecuteParameters.Source.FormName);
	EndIf;
	
	If TypeOf(CommandExecuteParameters) = Type("CommandExecuteParameters") Then
		RefForm = CommandExecuteParameters.URL;
	Else
		RefForm = Undefined;
	EndIf;
	
	OpenForm(
		"CommonForm.AdditionalReportsAndDataProcessors", 
		Parameters,
		CommandExecuteParameters.Source,
		,
		,
		RefForm);
	
EndProcedure

// Opens an additional report form with the specified report option.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - an additional report reference.
//   OptionKey - String - a name of the additional report option.
//
Procedure OpenAdditionalReportOption(Ref, OptionKey) Export
	
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	NameOfReport = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(Ref);
	OpeningParameters = New Structure("VariantKey", OptionKey);
	Uniqueness = "ExternalReport." + NameOfReport + "/VariantKey." + OptionKey;
	OpenForm("ExternalReport." + NameOfReport + ".Form", OpeningParameters, Undefined, Uniqueness);
	
EndProcedure

// Returns a blank structure of parameters of command execution in the background.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a reference to a report or data processor being executed.
//
// Returns:
//   Structure - a template of parameters for background command execution.
//      * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - passed "as 
//                                                                                          is" from the form parameters.
//      * AccompanyingText - String - a text of a time-consuming operation.
//      * RelatedObjects - Array - references to the objects the command is being executed for.
//          It is used for additional data processors to assign.
//      * CreatedObjects - Array - references to the objects created while executing the command.
//          It is used for assignable additional data processors of the "Related object creation" kind.
//      * OwnerForm - ManagedForm - an object form or a list form the command is called from.
//
Function CommandExecuteParametersInBackground(Ref) Export
	
	Result = New Structure("AdditionalDataProcessorRef", Ref);
	Result.Insert("AccompanyingText");
	Result.Insert("RelatedObjects");
	Result.Insert("CreatedObjects");
	Result.Insert("OwnerForm");
	Return Result;
	
EndFunction

// Executes command CommandID in the background using the time-consuming operation mechanism.
// It is intended for use in forms of external reports and data processors.
//
// Parameters:
//   CommandID - String - a command name as it is specified in function ExternalDataProcessorInfo in the object module.
//   CommandParameters - Structure - command execution parameters.
//       For parameters, see function CommandExecuteParametersInBackground.
//       Also includes an internal parameter reserved by the subsystem:
//         * CommandID - String - a name of the command being executed. Matches the CommandID parameter.
//       In addition to standard parameters, the procedure can have custom parameters used in the command handler.
//       It is recommended that you add a prefix, such as "Context...", to custom parameter names to 
//       avoid exact matches with standard parameter names.
//   Handler - NotifyDescription - details of the procedure that gets the background job result.
//       See details of the second parameter (CompletionNotification) of procedure TimeConsumingOperationsClient.WaitForCompletion().
//       Procedure parameters:
//         * Job - Structure, Undefined - background job information.
//             ** Status - String - Completed (the job is completed) or Error (the job threw an exception).
//             ** ResultAddress - String - an address of the temporary storage for the procedure result.
//                 The result is filled in the ExecutionParameters.ExecutionResult structure of the command handler.
//             ** BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//             ** DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//             ** Messages - FixedArray, Undefined - messages from the background job.
//         * AdditionalParameters - a value that was specified on creating the NotifyDescription object.
//
// Example:
//	&AtClient
//	Procedure CommandHandler(Command)
//		CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef).
//		CommandParameters.AccompanyingText = NStr("en = 'Executing command...'").
//		Handler = New NotifyDescription("<ExportProcedureName>", ThisObject).
//		AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground(Command.Name, CommandParameters, Handler).
//	EndProcedure
//
Procedure ExecuteCommandInBackground(Val CommandID, Val CommandParameters, Val Handler) Export
	
	ProcedureName = "AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground";
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandID",
		CommandID,
		Type("String"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters",
		CommandParameters,
		Type("Structure"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters.AdditionalDataProcessorRef",
		CommonClientServer.StructureProperty(CommandParameters, "AdditionalDataProcessorRef"),
		Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"Handler",
		Handler,
		New TypeDescription("NotifyDescription, ManagedForm"));
	
	CommandParameters.Insert("CommandID", CommandID);
	MustReceiveResult = CommonClientServer.StructureProperty(CommandParameters, "MustReceiveResult", False);
	
	Form = Undefined;
	If CommandParameters.Property("OwnerForm", Form) Then
		CommandParameters.OwnerForm = Undefined;
	EndIf;
	If TypeOf(Handler) = Type("NotifyDescription") Then
		CommonClientServer.CheckParameter(ProcedureName, "Handler.Module",
			Handler.Module,
			Type("ManagedForm"));
		Form = ?(Form <> Undefined, Form, Handler.Module);
	Else
		Form = Handler;
		Handler = Undefined;
		MustReceiveResult = True; // For backward compatibility
	EndIf;
	
	Job = AdditionalReportsAndDataProcessorsServerCall.StartTimeConsumingOperation(Form.UUID, CommandParameters);
	
	AccompanyingText = CommonClientServer.StructureProperty(CommandParameters, "AccompanyingText", "");
	Title = CommonClientServer.StructureProperty(CommandParameters, "Title");
	If ValueIsFilled(Title) Then
		AccompanyingText = TrimAll(Title + Chars.LF + AccompanyingText);
	EndIf;
	If Not ValueIsFilled(AccompanyingText) Then
		AccompanyingText = NStr("ru = 'Команда выполняется.'; en = 'Command running.'; pl = 'Polecenie jest wykonywane.';de = 'Der Befehl wird ausgeführt.';ro = 'Are loc executarea comenzii.';tr = 'Komut yapılıyor.'; es_ES = 'Ejecutando el comando.'");
	EndIf;
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Form);
	WaitSettings.MessageText       = AccompanyingText;
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MustReceiveResult    = MustReceiveResult; // For backward compatibility
	WaitSettings.OutputMessages    = True;
	
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
	
EndProcedure

// Returns the form name that can be used to get a time-consuming operation result.
//
// Returns:
//   String - see ExecuteCommandInBackground. 
//
Function TimeConsumingOperationFormName() Export
	
	Return "CommonForm.TimeConsumingOperation";
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Displays the command execution result.
//
// Parameters:
//   Form - ManagedForm - a form.
//   ExecutionResult - Structure - an execution result.
//
Procedure ShowCommandExecutionResult(Form, ExecutionResult) Export
	Return;
EndProcedure

// Obsolete. Use AttachableCommandsClient.ExecuteCommand.
//
// Executes an assignable command on the client using only out-of-context server calls.
//   Returns False if a server call is required to execute the command.
//
// Parameters:
//   Form - ManagedForm - a form the command is called from.
//   ItemName - String - a name of the form command that is being executed.
//
// Returns:
//   Boolean - an execution method.
//       True - a data processor command is being executed out of context.
//       False - a context server call is required to execute the command.
//
Function ExecuteAssignableCommandAtClient(Form, ItemName) Export
	Return False;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Opens the form for picking additional reports.
// Usage locations:
//   Catalog.ReportsMailings.Form.ItemForm.AddAdditionalReport.
//
// Parameters:
//   FormItem - Arbitrary - a form item the items are picked for.
//
Procedure ReportDistributionPickAddlReport(FormItem) Export
	
	AdditionalReport = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport");
	Report               = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report");
	
	FilterByKind = New ValueList;
	FilterByKind.Add(AdditionalReport, AdditionalReport);
	FilterByKind.Add(Report, Report);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode",  FormWindowOpeningMode.Independent);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("Filter",              New Structure("Kind", FilterByKind));
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ChoiceForm", ChoiceFormParameters, FormItem);
	
EndProcedure

// External print command handler.
//
// Parameters:
//  CommandParameters - Structure        - a structure from the command table row, see
//                                        AdditionalReportsAndDataProcessors.OnReceivePrintCommands.
//  Form            - ManagedForm - a form where the print command is being executed.
//
Procedure ExecuteAssignablePrintCommand(CommandToExecute, Form) Export
	
	// Moving additional parameters passed by this subsystem to the structure root.
	For Each KeyAndValue In CommandToExecute.AdditionalParameters Do
		CommandToExecute.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	// Writing fixed parameters.
	CommandToExecute.Insert("IsReport", False);
	CommandToExecute.Insert("Kind", PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm"));
	
	// Starting the data processor method that matches the command context.
	StartupOption = CommandToExecute.StartupOption;
	If StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		OpenDataProcessorForm(CommandToExecute, Form, CommandToExecute.PrintObjects);
	ElsIf StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		ExecuteDataProcessorClientMethod(CommandToExecute, Form, CommandToExecute.PrintObjects);
	Else
		ExecutePrintFormOpening(CommandToExecute, Form, CommandToExecute.PrintObjects);
	EndIf;
	
EndProcedure

// Handler of the command that opens the list of commands of additional reports and data processors.
//
// Parameters:
//   RefsArrray - Array - an array of selected object references, for which the command is running.
//   ExecutionParameters - Structure - a command context.
//       * CommandDetails - Structure - information about the running command.
//          ** ID - String - a command ID.
//          ** Presentation - String - a command presentation on a form.
//          ** Name - String - a command name on a form.
//       * Form - ManagedForm - a form the command is called from.
//       * Source - FormDataStructure, FormTable - an object or a form list with the Reference field.
//
Procedure OpenCommandList(Val RefsArray, Val ExecutionParameters) Export
	Context = New Structure;
	Context.Insert("Source", ExecutionParameters.Form);
	Kind = ExecutionParameters.CommandDetails.AdditionalParameters.Kind;
	OpenAdditionalReportAndDataProcessorCommandsForm(RefsArray, Context, Kind);
EndProcedure

// Filling command handler.
//
// Parameters:
//   RefsArrray - Array - an array of selected object references, for which the command is running.
//   ExecutionParameters - Structure - a command context.
//       * CommandDetails - Structure - information about the running command.
//          ** ID - String - a command ID.
//          ** Presentation - String - a command presentation on a form.
//          ** Name - String - a command name on a form.
//       * Form - ManagedForm - a form the command is called from.
//       * Source - FormDataStructure, FormTable - an object or a form list with the Reference field.
//
Procedure PopulateCommandHandler(Val RefsArray, Val ExecutionParameters) Export
	Form              = ExecutionParameters.Form;
	Object             = ExecutionParameters.Source;
	CommandToExecute = ExecutionParameters.CommandDetails.AdditionalParameters;
	
	ServerCallParameters = New Structure;
	ServerCallParameters.Insert("CommandID",          CommandToExecute.ID);
	ServerCallParameters.Insert("AdditionalDataProcessorRef", CommandToExecute.Ref);
	ServerCallParameters.Insert("RelatedObjects",             New Array);
	ServerCallParameters.Insert("FormName",                      Form.FormName);
	ServerCallParameters.RelatedObjects.Add(Object.Ref);
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	// Getting details on the execution result is only supported for server methods.
	// When a form is opened or a client method is called, the execution result is displayed by the data processor.
	If CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			OpenForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			ExternalObjectForm = GetForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			ExternalObjectForm = GetForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		ExternalObjectForm.ExecuteCommand(ServerCallParameters.CommandID, ServerCallParameters.RelatedObjects);
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
		
		ServerCallParameters.Insert("ExecutionResult", New Structure);
		AdditionalReportsAndDataProcessorsServerCall.ExecuteCommand(ServerCallParameters, Undefined);
		Form.Read();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Displays a notification before command run.
Procedure ShowNotificationOnCommandExecution(CommandToExecute)
	If CommandToExecute.ShowNotification Then
		ShowUserNotification(NStr("ru = 'Команда выполняется...'; en = 'Command running...'; pl = 'Wykonywanie polecenia...';de = 'Ausführen des Befehls...';ro = 'Are loc executarea comenzii...';tr = 'Komut yapılıyor...'; es_ES = 'Ejecutando el comando...'"), , CommandToExecute.Presentation);
	EndIf;
EndProcedure

// Opens a data processor form.
Procedure OpenDataProcessorForm(CommandToExecute, Form, RelatedObjects) Export
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName, SessionKey");
	ProcessingParameters.CommandID          = CommandToExecute.ID;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);
	ProcessingParameters.SessionKey = CommandToExecute.Ref.UUID();
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для отчета или обработки ""%1"" не назначена основная форма,
				|или основная форма не предназначена для запуска в обычном приложении.
				|Команда ""%2"" не может быть выполнена.'; 
				|en = '%1 report or data processor is missing the main form,
				|or the main form does not support standard applications.
				|Command %2 failed.'; 
				|pl = 'Dla sprawozdania lub przetwarzania ""%1""nie określono formularzu podstawowego,
				|lub formularz podstawowy nie jest przeznaczony do uruchomienia w zwykłej aplikacji.
				|Polecenie ""%2"" nie może być wykonane.';
				|de = 'Das Hauptformular ist dem Bericht oder der Verarbeitung ""%1"" nicht zugeordnet
				|oder das Hauptformular ist nicht für die Ausführung in einer Standardanwendung vorgesehen.
				|Der Befehl ""%2"" kann nicht ausgeführt werden.';
				|ro = 'Pentru raportul sau procesarea ""%1"" nu este specificată forma principală,
				|sau forma principală nu este destinată pentru lansare în aplicația simplă.
				|Comanda""%2"" nu poate fi executată.';
				|tr = 'Rapor veya veri işlemcisi için ""%1"" ana form 
				|atanmamış veya ana formun, normal uygulamada başlatılması amaçlanmamıştır. 
				|Komut ""%2"" çalıştırılamıyor.'; 
				|es_ES = 'Para el informe o el procesador de datos ""%1"" el formulario principal no está asignado,
				|o el formulario principal no tiene la intención de ser lanzado en la aplicación habitual.
				|Puede ser que el comando ""%2"" no se lance.'"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
		DataProcessorForm.Open();
		DataProcessorForm = Undefined;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport." + DataProcessorName + ".Form", ProcessingParameters, Form);
		Else
			OpenForm("ExternalDataProcessor." + DataProcessorName + ".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
EndProcedure

// Executes a data processor client method.
Procedure ExecuteDataProcessorClientMethod(CommandToExecute, Form, RelatedObjects) Export
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName");
	ProcessingParameters.CommandID          = CommandToExecute.ID;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);;
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для отчета или обработки ""%1"" не назначена основная форма,
				|или основная форма не предназначена для запуска в обычном приложении.
				|Команда ""%2"" не может быть выполнена.'; 
				|en = '%1 report or data processor is missing the main form,
				|or the main form does not support standard applications.
				|Command %2 failed.'; 
				|pl = 'Dla sprawozdania lub przetwarzania ""%1""nie określono formularzu podstawowego,
				|lub formularz podstawowy nie jest przeznaczony do uruchomienia w zwykłej aplikacji.
				|Polecenie ""%2"" nie może być wykonane.';
				|de = 'Das Hauptformular ist dem Bericht oder der Verarbeitung ""%1"" nicht zugeordnet
				|oder das Hauptformular ist nicht für die Ausführung in einer Standardanwendung vorgesehen.
				|Der Befehl ""%2"" kann nicht ausgeführt werden.';
				|ro = 'Pentru raportul sau procesarea ""%1"" nu este specificată forma principală,
				|sau forma principală nu este destinată pentru lansare în aplicația simplă.
				|Comanda""%2"" nu poate fi executată.';
				|tr = 'Rapor veya veri işlemcisi için ""%1"" ana form 
				|atanmamış veya ana formun, normal uygulamada başlatılması amaçlanmamıştır. 
				|Komut ""%2"" çalıştırılamıyor.'; 
				|es_ES = 'Para el informe o el procesador de datos ""%1"" el formulario principal no está asignado,
				|o el formulario principal no tiene la intención de ser lanzado en la aplicación habitual.
				|Puede ser que el comando ""%2"" no se lance.'"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			DataProcessorForm = GetForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters, Form);
		Else
			DataProcessorForm = GetForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
	
	If CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor")
		Or CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation") Then
		
		CreatedObjects = New Array;
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, RelatedObjects, CreatedObjects);
		
		CreatedObjectTypes = New Array;
		
		For Each CreatedObject In CreatedObjects Do
			Type = TypeOf(CreatedObject);
			If CreatedObjectTypes.Find(Type) = Undefined Then
				CreatedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In CreatedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm") Then
		
		DataProcessorForm.Print(CommandToExecute.ID, RelatedObjects);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.ObjectFilling") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, RelatedObjects);
		
		ModifiedObjectTypes = New Array;
		
		For Each ModifiedObject In RelatedObjects Do
			Type = TypeOf(ModifiedObject);
			If ModifiedObjectTypes.Find(Type) = Undefined Then
				ModifiedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In ModifiedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, RelatedObjects);
		
	EndIf;
	
	DataProcessorForm = Undefined;
	
EndProcedure

// Generates a spreadsheet document in the Print subsystem form.
Procedure ExecutePrintFormOpening(CommandToExecute, Form, RelatedObjects) Export
	
	StandardProcessing = True;
	AdditionalReportsAndDataProcessorsClientOverridable.BeforeExecuteExternalPrintFormPrintCommand(RelatedObjects, StandardProcessing);
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
		ModulePrintManagerInternalClient.ExecutePrintFormOpening(
			CommandToExecute.Ref,
			CommandToExecute.ID,
			RelatedObjects,
			Form,
			StandardProcessing);
	EndIf;
	
EndProcedure

// Shows the extension installation dialog box, and then exports additional report or data processor data.
Procedure ExportToFile(ExportParameters) Export
	Var Address;
	
	ExportParameters.Property("DataProcessorDataAddress", Address);
	If Not ValueIsFilled(Address) Then
		Address = AdditionalReportsAndDataProcessorsServerCall.PutInStorage(ExportParameters.Ref, Undefined);
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.SuggestionText = NStr("ru = 'Для выгрузки внешней обработки (отчета) в файл рекомендуется установить расширение для веб-клиента 1С:Предприятие.'; en = 'It is recommended that you install the file system extension before exporting the external report or data processor to a file.'; pl = 'Aby wyeksportować zewnętrzne przetwarzanie danych (sprawozdanie) do pliku, zainstaluj rozszerzenie dla klienta webowego 1C:Enterprise.';de = 'Um einen externen Datenprozessor (Bericht) in die Datei zu exportieren, installieren Sie die Erweiterung für 1C: Enterprise Web Client.';ro = 'Pentru exportul procesării suplimentare (raportului) în fișier recomandăm să instalați extensia pentru web-clientul 1C:Enterprise.';tr = 'Harici bir veri işlemcisini (rapor) dosyaya aktarmak için, 1C: İşletmesinin web istemcisi için uzantıyı yükleyin.'; es_ES = 'Para exportar un procesador de datos externo (informe) al archivo, instalar la extensión para el cliente web de la 1C:Empresa.'");
	SavingParameters.Dialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	SavingParameters.Dialog.Title = NStr("ru = 'Укажите файл'; en = 'Select file'; pl = 'Wskaż plik';de = 'Datei angeben';ro = 'Specificați fișierul';tr = 'Dosyayı belirtin'; es_ES = 'Especificar el archivo'");
	SavingParameters.Dialog.FilterIndex = ?(ExportParameters.IsReport, 1, 2);
	SavingParameters.Dialog.FullFileName = ExportParameters.FileName;
	
	FileSystemClient.SaveFile(Undefined, Address, ExportParameters.FileName, SavingParameters);
	
EndProcedure

#EndRegion
