///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts the procedure execution in a background job if possible.
// A job runs in a main thread, not in a background, if any of the following conditions is met:
//  * The procedure is called in a file infobase through an external connection (this mode has no background job support).
//  * The application was started in debug mode using /C DebugMode command-line parameter (this is for configuration debug purposes).
//  * The file infobase already has active background jobs (this is to avoid slow application response to user actions).
//  * The procedure belongs to an external data processor module or external report module.
//
// Do not use this function if the background job must be started unconditionally.
// You can use it together with TimeConsumingOperationsClient.WaitForCompletion function.
// 
// Parameters:
//  ProcedureName           - String    - the name of the export procedure in a common module, 
//                                       object manager module, or data processor module that you want to start in a background job.
//                                       Examples: "MyCommonModule.MyProcedure", "Reports.ImportedData.Generate"
//                                       or "DataProcessors.DataImport.ObjectModule.Import".
//                                       The procedure must have two or three formal parameters:
//                                        * Parameters       - Structure - arbitrary parameters ProcedureParameters.
//                                        * ResultAddress - String    - the address of the temporary 
//                                          storage where the procedure puts its result. This parameter is mandatory.
//                                        * AdditionalResultAddress - String - if 
//                                          ExecutionParameters include the AdditionalResult 
//                                          parameter, this parameter contains the address of the additional temporary storage where the procedure puts its result. This parameter is optional.
//                                       If you need to run a function in background, it is 
//                                       recommended that you wrap it in a function and return its result in the second parameter ResultAddress.
//  ProcedureParameters     - Structure - arbitrary parameters used to call the ProcedureName procedure.
//  ExecutionParameters    - Structure - see function TimeConsumingOperations.BackgroundExecutionParameters.
//
// Returns:
//  Structure              - job execution parameters: 
//   * Status               - String - "Running" if the job is running.
//                                     "Completed " if the job has completed.
//                                     "Error" if the job has completed with error.
//                                     "Canceled" if the job is canceled by a user or by an administrator.
//   * JobID - UUID - contains the ID of the running background job if Status = "Running".
//                                     
//   * ResultAddress       - String  - the address of the temporary storage where the procedure 
//                                     result must be (or already is) stored.
//   * AdditionalResultAddress - String - if the AdditionalResult parameter is set, it contains the 
//                                     address of the additional temporary storage where the 
//                                     procedure result must be (or already is) stored.
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
// 
// Example:
//  Generally, running a time-consuming operation and processing its results is organized as follows:
//
//   1) The procedure to run in background is added to the object manager module or common server module:
//    Procedure ExecuteAction(Parameters, ResultAddress) Export
//     ...
//     PutInTempStorage(Result, ResultAddress);
//    EndProcedure
//
//   2) The operation is started at server, and the idle handler is attached:
//    &AtClient
//    Procedure ExecuteAction()
//     TimeConsumingOperation = StartExecuteAtServer();
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     ...
//     CompletionNotification = New NotifyDescription("ExecuteActionCompletion", ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecuteAtServer()
//     ProcedureParameters = New Structure;
//     ...
//     ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
//     ...
//     Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.MyDataProcessor.ExecuteAction", 
//     ProcedureParameters, ExecutionParameters);
//    EndFunction
//    
//   3) The operation result is processed:
//    &AtClient
//    Procedure ExecuteActionCompletion(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf.
//     OutputResult(Result);
//    EndProcedure
//  
Function ExecuteInBackground(Val ProcedureName, Val ProcedureParameters, Val ExecutionParameters) Export
	
	CommonClientServer.CheckParameter("TimeConsumingOperations.ExecuteInBackground", "ExecutionParameters", 
		ExecutionParameters, Type("Structure")); 
	If ExecutionParameters.RunNotInBackground AND ExecutionParameters.RunInBackground Then
		Raise NStr("ru = 'Параметры ""ВсегдаНеВФоне"" и ""ВсегдаВФоне""
			|не могут одновременно принимать значение Истина в ДлительныеОперации.ВыполнитьВФоне.'; 
			|en = 'Parameters ""RunNotInBackground"" and ""RunInBackground""
			|cannot both be True at the same time in TimeConsumingOperations.ExecuteInBackground.'; 
			|pl = 'Parametry  ""ВсегдаНеВФоне"" и ""ВсегдаВФоне"" 
			|nie mogą jednocześnie przyjmować wartość Prawda w ДлительныеОперации.ВыполнитьВФоне.';
			|de = 'Die Einstellungen ""ImmerNichtImHintergrund"" und ""ImmerImHintergrund""
			|können nicht gleichzeitig auf Wahrheit bei LangenAktionen gesetzt werden.ImHintergrundAusführen.';
			|ro = 'Parametrii ""ВсегдаНеВФоне"" și ""ВсегдаВФоне""
			|nu pot accepta concomitent valoarea Adevărat în ДлительныеОперации.ВыполнитьВФоне.';
			|tr = '""HerZamanArkaPlandaDeğil"" ve ""HerZamanArkaPlanda"" parametreleri 
			| aynı anda Uzunİşlemler.ArkaPlandaYürüt ''te Doğru değerini alamaz.'; 
			|es_ES = 'Los parámetros ""RunNotInBackground"" y ""RunInBackground""
			|no pueden obtener el valor Verdadero simultáneamente en TimeConsumingOperations.ExecuteInBackground.'");
	EndIf;
#If ExternalConnection Then
	FileInfobase = Common.FileInfobase();
	If ExecutionParameters.NoExtensions AND FileInfobase Then
		Raise NStr("ru = 'Фоновое задание не может быть запущено с параметром ""БезРасширений""
			|в файловой информационной базе в ДлительныеОперации.ВыполнитьВФоне.'; 
			|en = 'Cannot start a background job with ""NoExtensions"" parameter
			|in a file infobase in TimeConsumingOperations.ExecuteInBackground.'; 
			|pl = 'Zadanie w tle nie może być uruchomione z parametrem """"БезРасширений""
			|w plikowej bazie informacyjnej w OДлительныеОперации.ВыполнитьВФоне.';
			|de = 'Die Hintergrundaufgabe kann nicht mit dem Parameter ""OhneErweiterungen""
			|in der Dateiinformationsdatenbank in LangeAktionen gestartet werden.ImHintergrundAusführen.';
			|ro = 'Sarcina de fundal nu poate fi lansată cu parametrul ""БезРасширений""
			|în baza de informații de tip fișier ДлительныеОперации.ВыполнитьВФоне.';
			|tr = 'Arkaplan görevi, Uzunİşlemler dosya veri tabanında Uzunİşlemler.ArkaPlandaYürüt ""UzantıOlmadan"" parametresi 
			|ile yürütülemez. '; 
			|es_ES = 'La tarea del fondo no puede ser lanzada con el parámetro ""TimeConsumingOperations.ExecuteInBackground""
			|en la base de información de archivo en TimeConsumingOperations.ExecuteInBackground.'");
	EndIf;
#EndIf
	
	ResultAddress = ?(ExecutionParameters.ResultAddress <> Undefined, 
	    ExecutionParameters.ResultAddress,
		PutToTempStorage(Undefined, ExecutionParameters.FormID));
	
	Result = New Structure;
	Result.Insert("Status",    "Running");
	Result.Insert("JobID", Undefined);
	Result.Insert("ResultAddress", ResultAddress);
	Result.Insert("AdditionalResultAddress", "");
	Result.Insert("BriefErrorPresentation", "");
	Result.Insert("DetailedErrorPresentation", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	If ExecutionParameters.NoExtensions Then
		ExecutionParameters.NoExtensions = ValueIsFilled(SessionParameters.AttachedExtensions);
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(ProcedureParameters);
	ExportProcedureParameters.Add(ResultAddress);
	
	If ExecutionParameters.AdditionalResult Then
		Result.AdditionalResultAddress = PutToTempStorage(Undefined, ExecutionParameters.FormID);
		ExportProcedureParameters.Add(Result.AdditionalResultAddress);
	EndIf;
	
#If ExternalConnection Then
	ExecuteWithoutBackgroundJob = FileInfobase 
		Or Common.DebugMode() Or ExecutionParameters.RunNotInBackground
		Or (BackgroundJobsExistInFileIB() AND Not ExecutionParameters.RunInBackground) 
		Or Not CanRunInBackground(ProcedureName);
#Else
	ExecuteWithoutBackgroundJob = Not ExecutionParameters.NoExtensions
		AND (Common.DebugMode() Or ExecutionParameters.RunNotInBackground
			Or (BackgroundJobsExistInFileIB() AND Not ExecutionParameters.RunInBackground) 
			Or Not CanRunInBackground(ProcedureName));
#EndIf

	// Executing in the main thread.
	If ExecuteWithoutBackgroundJob Then
		Try
			ExecuteProcedure(ProcedureName, ExportProcedureParameters);
			Result.Status = "Completed";
		Except
			Result.Status = "Error";
			Result.BriefErrorPresentation = BriefErrorDescription(ErrorInfo());
			Result.DetailedErrorPresentation = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("ru = 'Ошибка выполнения'; en = 'Runtime error'; pl = 'Błąd wykonania';de = 'Ausführungsfehler';ro = 'Eroare de executare';tr = 'Uygulama hatası'; es_ES = 'Error de ejecución'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , Result.DetailedErrorPresentation);
		EndTry;
		Return Result;
	EndIf;
	
	// Executing in background.
	Try
		Job = RunBackgroundJobWithClientContext(ProcedureName, ExecutionParameters, ExportProcedureParameters);
	Except
		Result.Status = "Error";
		If Job <> Undefined AND Job.ErrorInfo <> Undefined Then
			Result.BriefErrorPresentation = BriefErrorDescription(Job.ErrorInfo);
			Result.DetailedErrorPresentation = DetailErrorDescription(Job.ErrorInfo);
		Else
			Result.BriefErrorPresentation = BriefErrorDescription(ErrorInfo());
			Result.DetailedErrorPresentation = DetailErrorDescription(ErrorInfo());
		EndIf;
		Return Result;
	EndTry;
	
	If Job <> Undefined AND Job.ErrorInfo <> Undefined Then
		Result.Status = "Error";
		Result.BriefErrorPresentation = BriefErrorDescription(Job.ErrorInfo);
		Result.DetailedErrorPresentation = DetailErrorDescription(Job.ErrorInfo);
		Return Result;
	EndIf;
	
	Result.JobID = Job.UUID;
	JobCompleted = False;
	
	If ExecutionParameters.WaitForCompletion <> 0 Then
		Try
			Job.WaitForCompletion(ExecutionParameters.WaitForCompletion);
			JobCompleted = True;
		Except
			// No special processing is required. Perhaps the exception was raised because a timeout occurred.
		EndTry;
	EndIf;
	
	If JobCompleted Then
		ProgressAndMessages = ReadProgressAndMessages(Job.UUID, "ProgressAndMessages");
		Result.Messages = ProgressAndMessages.Messages;
	EndIf;
	
	FillPropertyValues(Result, ActionCompleted(Job.UUID), , "Messages");
	Return Result;
	
EndFunction

// Returns a new structure for the ExecutionParameters parameter of the ExecuteInBackground function.
//
// Parameters:
//   FormID - UUID - a UUID of the form containing the temporary storage where the procedure puts 
//                               its result.
//
// Returns:
//   Structure - with the following properties:
//     * FormID      - UUID - a UUID of the form containing the temporary storage where the 
//                               procedure puts its result.
//     * AdditionalResult - Boolean     - the flag indicates whether additional temporary storage is 
//                                 to be used to pass the result from the background job to the parent session. The default value is False.
//     * WaitForCompletion       - Number, Undefined - background job completion timeout, in seconds.
//                               Wait for completion if Undefined.
//                               If set to 0, means "do not wait for completion."
//                               The default value is 2 seconds (or 4 seconds for slow connections).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey      - String    - the unique key for active background jobs that have the same procedure name.
//                                              Not set by default.
//     * ResultAddress          - String -  the address of the temporary storage where the procedure 
//                                           result must be stored. If the address is not set, it is generated automatically.
//     * RunInBackground           - Boolean - if True, the job always runs in background, unless in 
//                               debug mode.
//                               When in file mode, if any other jobs are running, the new job is 
//                               queued and does not start running until all previous jobs are completed.
//     * RunNotInBackground         - Boolean - if True, the job always runs naturally rather than 
//                               in background.
//     * NoExtensions            - Boolean - if True, no configuration extensions are attached to 
//                               run the background job.
//
Function BackgroundExecutionParameters(Val FormID) Export
	
	Result = New Structure;
	Result.Insert("FormID", FormID); 
	Result.Insert("AdditionalResult", False);
	Result.Insert("WaitForCompletion", ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 0.8));
	Result.Insert("BackgroundJobDescription", "");
	Result.Insert("BackgroundJobKey", "");
	Result.Insert("ResultAddress", Undefined);
	Result.Insert("RunNotInBackground", False);
	Result.Insert("RunInBackground", False);
	Result.Insert("NoExtensions", False);
	Return Result;
	
EndFunction

// Records progress of a time-consuming operation.
// To read the recorded information, use the TimeConsumingOperations.ReadProgress function.
// To avoid excessive memory usage and memory leaks, try to run no more than 100 progress reports 
// during a time-consuming operation.
//
// Parameters:
//  Percentage                 - Number        - completion percentage.
//  Text                   - String       - information about the current operation.
//  AdditionalParameters - Arbitrary - any additional information that must be passed to the client.
//                                           The value must be serialized into the XML string.
//
Procedure ReportProgress(Val Percent = Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export
	
	If GetCurrentInfoBaseSession().GetBackgroundJob() = Undefined Then
		Return;
	EndIf;
		
	ValueToPass = New Structure;
	If Percent <> Undefined Then
		ValueToPass.Insert("Percent", Percent);
	EndIf;
	If Text <> Undefined Then
		ValueToPass.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		ValueToPass.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	TextToPass = Common.ValueToXMLString(ValueToPass);
	
	Text = "{" + ProgressMessage() + "}" + TextToPass;
	Common.MessageToUser(Text);
	
EndProcedure

// Read information on the time-consuming operation progress that was recorded by the 
// TimeConsumingOperations.ReportProgress function.
//
// Parameters:
//   JobID - UUID - the background job ID.
//
// Returns:
//   Undefined, Structure - background job progress information that was recorded by the ReportProgress function:
//    * Percentage                 - Number  - optional. Progress percentage.
//    * Text                   - String - optional. Details on the current action.
//    * AdditionalParameters - Arbitrary - optional. Any additional information.
//
Function ReadProgress(Val JobID) Export
	
	Return ReadProgressAndMessages(JobID, "Progress").Progress;
	
EndFunction

// Cancels background job execution by the passed ID.
// If the transactions are opened in time-consuming operation, the last open transaction will be rolled back.
//
// Thus, if the time-consuming operation is processing (recording) data, record in one transaction 
// to cancel the whole operation completely (in this case the whole operation will be canceled).
// If it is enough not to cancel time-consuming operation completely, but to cancel it at the 
// achieved level, then it is not required to open one time-consuming transaction.
// 
// Parameters:
//  JobID - UUID - the background job ID received when starting a time-consuming operation.
//                                                    See TimeConsumingOperations. ExecuteInBackground.
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	If SessionParameters.CanceledTimeConsumingOperations.Find(JobID) = Undefined Then
		CanceledTimeConsumingOperations = New Array(SessionParameters.CanceledTimeConsumingOperations);
		CanceledTimeConsumingOperations.Add(JobID);
		SessionParameters.CanceledTimeConsumingOperations = New FixedArray(CanceledTimeConsumingOperations);
	EndIf;
	SetPrivilegedMode(False);
	
	Job = FindJobByID(JobID);
	If Job = Undefined	Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// It is possible that the job has completed at that moment and no error has occurred.
		WriteLogEvent(NStr("ru = 'Длительные операции.Отмена выполнения фонового задания'; en = 'Time-consuming operations.Cancel background job'; pl = 'Długotrwałe operacje. Anulowanie zadania w tle';de = 'Lange Aktionen. Abbruch der Hintergrundjobausführung';ro = 'Operații îndelungate.Revocarea executării sarcinii de fundal';tr = 'Uzun işlemler. Arkaplan iş yürütme iptali'; es_ES = 'Acciones largas. Cancelación de la ejecución de la tarea de fondo'", Common.DefaultLanguageCode()),
			EventLogLevel.Information, , , BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Checks background job state by the passed ID.
// If the job terminates abnormally, raises the exception that was generated or a common exception 
// "Cannot perform the operation. See the event log for details.
//
// Parameters:
//  JobID - UUID - the background job ID.
//
// Returns:
//  Boolean - job execution status.
// 
Function JobCompleted(Val JobID) Export
	
	Job = FindJobByID(JobID);
	
	If Job <> Undefined
		AND Job.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	ActionNotExecuted = True;
	ShowFullErrorText = False;
	If Job = Undefined Then
		WriteLogEvent(NStr("ru = 'Длительные операции.Фоновое задание не найдено'; en = 'Time-consuming operations.Background job not found'; pl = 'Operacje długotrwałe.Zadanie w tle nie znaleziono';de = 'Lange Aktionen. Der Hintergrundjob wurde nicht gefunden';ro = 'Operații îndelungate.Sarcina de fundal nu a fost găsită';tr = 'Uzunİşlemler.Arkaplan görevi bulunamadı'; es_ES = 'Operaciones duraderas.Tarea de fondo no encontrada'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , String(JobID));
	Else
		If Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				ShowFullErrorText = True;
			EndIf;
		ElsIf Job.State = BackgroundJobState.Canceled Then
			WriteLogEvent(
				NStr("ru = 'Длительные операции.Фоновое задание отменено администратором'; en = 'Time-consuming operations.Background job canceled by administrator'; pl = 'Długotrwała operacja. Zadanie w tle zostało anulowane przez administratora';de = 'Lange Aktionen. Der Hintergrundjob wird vom Administrator abgebrochen';ro = 'Operații îndelungate.Sarcina de fundal este anulată de administrator';tr = 'Uzun işlemler. Arka plan iş yönetici tarafından iptal edildi'; es_ES = 'Acciones largas. Tarea de fondo se ha cancelado por el administrador'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				NStr("ru = 'Задание завершилось с неизвестной ошибкой.'; en = 'The job completed with an unknown error.'; pl = 'Zadanie zakończone z nieznanym błędem.';de = 'Job wurde mit einem unbekannten Fehler beendet.';ro = 'Sarcina a fost finalizată cu o eroare necunoscută.';tr = 'İş bilinmeyen bir hatayla tamamlandı.'; es_ES = 'Tarea se ha finalizado con un error desconocido.'"));
		Else
			Return True;
		EndIf;
	EndIf;
	
	If ShowFullErrorText Then
		ErrorText = BriefErrorDescription(Job.ErrorInfo);
		Raise(ErrorText);
	ElsIf ActionNotExecuted Then
		Raise(NStr("ru = 'Не удалось выполнить данную операцию. 
		                             |Подробности см. в Журнале регистрации.'; 
		                             |en = 'Cannot perform the operation. 
		                             |For more information, see the event log.'; 
		                             |pl = 'Nie udało się wykonać tej operacji. 
		                             |Szczegóły zob. w Dzienniku rejestracji.';
		                             |de = 'Dieser Vorgang konnte nicht ausgeführt werden.
		                             |Weitere Informationen finden Sie im Protokoll.';
		                             |ro = 'Eșec la executarea acestei operații. 
		                             |Detalii vezi în Registrul logare.';
		                             |tr = 'Bu işlem yürütülemiyor. 
		                             |Kayıt günlüğündeki ayrıntıları arayın.'; 
		                             |es_ES = 'No se puede ejecutar esta operación. 
		                             |Ver los detalles en el Registro de eventos.'"));
	EndIf;
	
EndFunction

// Gets messages intended for the user, and blocks system messages regarding the time-consuming operation status.
// 
// Parameters:
//  DeleteReceived    - Boolean                  - the flag indicates whether the received messages need to be deleted.
//  JobID - UUID - the ID of the background job corresponding to a time-consuming operation that 
//                                                   generates messages intended for the user.
//                                                   If not set, the messages intended for the user 
//                                                   are returned from the current user session.
// 
// Returns:
//  FixedArray - UserMessage objects that were generated in the background job.
//
// Example:
//   Operation = TimeConsumingOperations.ExecuteInBackground(...);
//   ...
//   Messages = TimeConsumingOperations.UserMessages(True, Operation.JobID);
//
Function UserMessages(DeleteReceived = False, JobID = Undefined) Export
	
	If ValueIsFilled(JobID) Then
		BackgroundJob = BackgroundJobs.FindByUUID(JobID);
		If BackgroundJob <> Undefined Then
			AllMessages = BackgroundJob.GetUserMessages(DeleteReceived);
		EndIf;
	Else
		AllMessages = GetUserMessages(DeleteReceived);
	EndIf;
	
	Result = New Array;
	
	For Each Message In AllMessages Do
		If StrStartsWith(Message.Text, "{" + ProgressMessage() + "}") Then
			If DeleteReceived Then
				Message.Message();
			EndIf;
		Else
			Result.Add(Message);
		EndIf;
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ExecuteInBackground instead.
//
// Executes procedures in a background job.
// Similar to ExecuteInBackground but with less functionality. Intended for backward compatibility.
// 
// Parameters:
//  FormID     - UUID - the ID of the form used to start the time-consuming operation. 
//                           
//  ExportProcedureName - String - the name of the export procedure that must be run in background.
//                           
//  Parameters              - Structure - all parameters required to execute the ExportProcedureName 
//                           procedure.
//  JobDescription    - String - the description of the background job. 
//                           If JobDescription is not specified, it is identical to ExportProcedureName.
//  UseAdditionalTempStorage - Boolean - the flag indicates whether additional temporary storage is 
//                           to be used to pass data from the background job to the parent session.
//                            The default value is False.
//
// Returns:
//  Structure              - job execution parameters: 
//   * StorageAddress  - String     - the address of the temporary storage where the job result must 
//                                    be stored.
//   * AdditionalStorageAddress - String - the address of the additional temporary storage where the 
//                                    job result must be stored (can only be used when 
//                                    UseAdditionalTempStorage is set).
//   * JobID - UUID - the unique ID of the running background job.
//   * JobCompleted - Boolean - True if the job is completed successfully during the function call.
// 
Function StartBackgroundExecution(Val FormID, Val ExportProcedureName, Val Parameters,
	Val JobDescription = "", UseAdditionalTempStorage = False) Export
	
	StorageAddress = PutToTempStorage(Undefined, FormID);
	
	Result = New Structure;
	Result.Insert("StorageAddress",       StorageAddress);
	Result.Insert("JobCompleted",     False);
	Result.Insert("JobID", Undefined);
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTempStorage Then
		StorageAddressAdditional = PutToTempStorage(Undefined, FormID);
		ExportProcedureParameters.Add(StorageAddressAdditional);
	EndIf;
	
	JobsRunning = 0;
	If Common.FileInfobase()
		AND Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunning = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	
	If Common.DebugMode()
		Or JobsRunning > 0 Then
		Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Result.JobCompleted = True;
	Else
		Timeout = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 2);
		ExecutionParameters = BackgroundExecutionParameters(Undefined);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		Job = RunBackgroundJobWithClientContext(ExportProcedureName,
			ExecutionParameters, ExportProcedureParameters);
		Try
			Job.WaitForCompletion(Timeout);
		Except
			// No special processing is required. Perhaps the exception was raised because a time-out occurred.
		EndTry;
		
		Status = ActionCompleted(Job.UUID);
		Result.JobCompleted = Status.Status = "Completed";
		Result.JobID = Job.UUID;
	EndIf;
	
	If UseAdditionalTempStorage Then
		Result.Insert("StorageAddressAdditional", StorageAddressAdditional);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function ActionCompleted(Val JobID, Val ExceptionOnError = False, Val OutputProgressBar = False, 
	Val OutputMessages = False) Export
	
	Result = New Structure;
	Result.Insert("Status", "Running");
	Result.Insert("BriefErrorPresentation", Undefined);
	Result.Insert("DetailedErrorPresentation", Undefined);
	Result.Insert("Progress", Undefined);
	Result.Insert("Messages", Undefined);
	
	Job = FindJobByID(JobID);
	If Job = Undefined Then
		Note = NStr("ru = 'Операция не выполнена из-за аварийного завершения фонового задания.
			|Фоновое задание не найдено'; 
			|en = 'Cannot perform the operation due to abnormal termination of a background job.
			|The background job is not found'; 
			|pl = 'Operacja nie powiodła się z powodu nieprawidłowego zakończenia zadania w tle.
			|Nie znaleziono zadania w tle';
			|de = 'Der Vorgang ist aufgrund einer abnormalen Beendigung des Hintergrundjobs fehlgeschlagen.
			|Der Hintergrundjob wurde nicht gefunden';
			|ro = 'Operația nu este executată din cauza finalizării forțate a sarcinii de fundal.
			|Sarcina de fundal nu a fost găsită';
			|tr = 'Arka plan görevinin çökmesi nedeniyle işlem başarısız oldu. 
			|Arka plan görevi bulunamadı'; 
			|es_ES = 'La operación no se ha establecido a causa de la finalización de la tarea de fondo.
			|La tarea de fondo no encontrado'") + ": " + String(JobID);
		WriteLogEvent(NStr("ru = 'Длительные операции'; en = 'Time-consuming operations'; pl = 'Długie operacje';de = 'Lange Aktionen';ro = 'Operații îndelungate';tr = 'Uzun eylmler'; es_ES = 'Acciones largas'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Note);
		If ExceptionOnError Then
			Raise(NStr("ru = 'Не удалось выполнить данную операцию.'; en = 'Cannot perform the operation.'; pl = 'Nie można wykonać tej operacji.';de = 'Dieser Vorgang konnte nicht ausgeführt werden.';ro = 'Eșec la executarea operației date.';tr = 'Bu işlem yapılamıyor.'; es_ES = 'No se ha podido realizar esta operación.'"));
		EndIf;
		Result.Status = "Error";
		Result.BriefErrorPresentation = NStr("ru = 'Операция не выполнена из-за аварийного завершения фонового задания.'; en = 'Cannot perform the operation due to abnormal termination of a background job.'; pl = 'Operacja nie powiodła się z powodu nieprawidłowego zakończenia zadania w tle.';de = 'Der Vorgang ist aufgrund einer abnormalen Beendigung des Hintergrundjobs fehlgeschlagen.';ro = 'Operația nu este executată din cauza finalizării forțate a sarcinii de fundal.';tr = 'Arka plan görevinin çökmesi nedeniyle işlem başarısız oldu.'; es_ES = 'La operación no se ha realizado a causa de la finalización de urgencia de la tarea de fondo.'");
		Return Result;
	EndIf;
	
	If OutputProgressBar Then
		ProgressAndMessages = ReadProgressAndMessages(JobID, ?(OutputMessages, "ProgressAndMessages", "Progress"));
		Result.Progress = ProgressAndMessages.Progress;
		If OutputMessages Then
			Result.Messages = ProgressAndMessages.Messages;
		EndIf;
	ElsIf OutputMessages Then
		Result.Messages = Job.GetUserMessages(True);
	EndIf;
	
	If Job.State = BackgroundJobState.Active Then
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Canceled Then
		SetPrivilegedMode(True);
		If SessionParameters.CanceledTimeConsumingOperations.Find(JobID) = Undefined Then
			Result.Status = "Error";
			If Job.ErrorInfo <> Undefined Then
				Result.BriefErrorPresentation   = NStr("ru = 'Операция отменена администратором.'; en = 'Operation canceled by administrator.'; pl = 'Operacja została anulowana przez administratora.';de = 'Die Operation wurde vom Administrator abgebrochen.';ro = 'Operația este revocată de administrator.';tr = 'Işlem yönetici tarafından iptal edildi.'; es_ES = 'La operación ha sido cancelada por el administrador.'");
				Result.DetailedErrorPresentation = Result.BriefErrorPresentation;
			EndIf;
			If ExceptionOnError Then
				If Not IsBlankString(Result.BriefErrorPresentation) Then
					MessageText = Result.BriefErrorPresentation;
				Else
					MessageText = NStr("ru = 'Не удалось выполнить данную операцию.'; en = 'Cannot perform the operation.'; pl = 'Nie można wykonać tej operacji.';de = 'Dieser Vorgang konnte nicht ausgeführt werden.';ro = 'Eșec la executarea operației date.';tr = 'Bu işlem yapılamıyor.'; es_ES = 'No se ha podido realizar esta operación.'");
				EndIf;
				Raise MessageText;
			EndIf;
		Else
			Result.Status = "Canceled";
		EndIf;
		SetPrivilegedMode(False);
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Failed 
		Or Job.State = BackgroundJobState.Canceled Then
		
		Result.Status = "Error";
		If Job.ErrorInfo <> Undefined Then
			Result.BriefErrorPresentation   = BriefErrorDescription(Job.ErrorInfo);
			Result.DetailedErrorPresentation = DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		If ExceptionOnError Then
			If Not IsBlankString(Result.BriefErrorPresentation) Then
				MessageText = Result.BriefErrorPresentation;
			Else
				MessageText = NStr("ru = 'Не удалось выполнить данную операцию.'; en = 'Cannot perform the operation.'; pl = 'Nie można wykonać tej operacji.';de = 'Dieser Vorgang konnte nicht ausgeführt werden.';ro = 'Eșec la executarea operației date.';tr = 'Bu işlem yapılamıyor.'; es_ES = 'No se ha podido realizar esta operación.'");
			EndIf;
			Raise MessageText;
		EndIf;
		Return Result;
	EndIf;
	
	Result.Status = "Completed";
	Return Result;
	
EndFunction

Function ProgressMessage() Export
	Return "StandardSubsystems.TimeConsumingOperations";
EndFunction

Procedure RunDataProcessorObjectModuleProcedure(Parameters, StorageAddress) Export 
	If Parameters.IsExternalDataProcessor Then
		Ref = CommonClientServer.StructureProperty(Parameters, "AdditionalDataProcessorRef");
		If ValueIsFilled(Ref) AND Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			DataProcessor = Common.CommonModule("AdditionalReportsAndDataProcessors").ExternalDataProcessorObject(Ref);
		Else
			VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
			DataProcessor = ExternalDataProcessors.Create(Parameters.DataProcessorName, SafeMode());
		EndIf;
	Else
		DataProcessor = DataProcessors[Parameters.DataProcessorName].Create();
	EndIf;
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(DataProcessor, Parameters.MethodName, MethodParameters);
EndProcedure

Procedure RunReportObjectModuleProcedure(Parameters, StorageAddress) Export
	If Parameters.IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtReports", Metadata);
		Report = ExternalReports.Create(Parameters.ReportName, SafeMode());
	Else
		Report = Reports[Parameters.ReportName].Create();
	EndIf;
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(Report, Parameters.MethodName, MethodParameters);
EndProcedure

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "CanceledTimeConsumingOperations" Then
		SessionParameters.CanceledTimeConsumingOperations = New FixedArray(New Array);
		SpecifiedParameters.Add("CanceledTimeConsumingOperations");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ActionsCompleted(Val Jobs) Export
	
	Result = New Map;
	For each Job In Jobs Do
		Result.Insert(Job.JobID, 
			ActionCompleted(Job.JobID, False, Job.OutputProgressBar, Job.OutputMessages));
	EndDo;
	Return Result;
	
EndFunction

Function RunBackgroundJobWithClientContext(ProcedureName,
	ExecutionParameters, ProcedureParameters = Undefined) Export
	
	BackgroundJobKey = ExecutionParameters.BackgroundJobKey;
	BackgroundJobDescription = ?(IsBlankString(ExecutionParameters.BackgroundJobDescription),
		ProcedureName, ExecutionParameters.BackgroundJobDescription);
		
	AllParameters = New Structure;
	AllParameters.Insert("ProcedureName",       ProcedureName);
	AllParameters.Insert("ProcedureParameters", ProcedureParameters);
	AllParameters.Insert("ClientParametersAtServer", StandardSubsystemsServer.ClientParametersAtServer());
	
	BackgroundJobProcedureParameters = New Array;
	BackgroundJobProcedureParameters.Add(AllParameters);
	
	Return RunBackgroundJob(ExecutionParameters,
		"TimeConsumingOperations.ExecuteWithClientContext", BackgroundJobProcedureParameters,
		BackgroundJobKey, BackgroundJobDescription);
	
EndFunction

// Continuation of the RunBackgroundJobWithClientContext procedure.
Procedure ExecuteWithClientContext(AllParameters) Export
	
	SetPrivilegedMode(True);
	If AccessRight("Set", Metadata.SessionParameters.ClientParametersAtServer) Then
		SessionParameters.ClientParametersAtServer = AllParameters.ClientParametersAtServer;
	EndIf;
	Catalogs.ExtensionsVersions.RegisterExtensionsVersionUsage();
	SetPrivilegedMode(False);
	
	ExecuteProcedure(AllParameters.ProcedureName, AllParameters.ProcedureParameters);
	
EndProcedure

Procedure ExecuteProcedure(ProcedureName, ProcedureParameters)
	
	NameParts = StrSplit(ProcedureName, ".");
	IsDataProcessorModuleProcedure = (NameParts.Count() = 4) AND Upper(NameParts[2]) = "OBJECTMODULE";
	If Not IsDataProcessorModuleProcedure Then
		Common.ExecuteConfigurationMethod(ProcedureName, ProcedureParameters);
		Return;
	EndIf;
	
	IsDataProcessor = Upper(NameParts[0]) = "DATAPROCESSOR";
	IsReport = Upper(NameParts[0]) = "REPORT";
	If IsDataProcessor Or IsReport Then
		ObjectManager = ?(IsReport, Reports, DataProcessors);
		DataProcessorReportObject = ObjectManager[NameParts[1]].Create();
		Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], ProcedureParameters);
		Return;
	EndIf;
	
	IsExternalDataProcessor = Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR";
	IsExternalReport = Upper(NameParts[0]) = "EXTERNALREPORT";
	If IsExternalDataProcessor Or IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
		ObjectManager = ?(IsExternalReport, ExternalReports, ExternalDataProcessors);
		DataProcessorReportObject = ObjectManager.Create(NameParts[1], SafeMode());
		Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], ProcedureParameters);
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Неверный формат параметра ИмяПроцедуры (переданное значение: %1)'; en = 'Invalid format of ProcedureName parameter (passed value: %1)'; pl = 'Błędny format parametru ProcedureName (przekazana wartość: %1)';de = 'Ungültiges Format der Parameter des ProcedureName (übertargener Wert: %1)';ro = 'Format incorect al parametrului ProcedureName (valoarea transmisă: %1)';tr = 'ProcedureName parametresinin yanlış biçimi (verilen değer: %1)'; es_ES = 'Formato incorrecto del parámetro ProcedureName (valor transmitido: %1)'"), ProcedureName);
	
EndProcedure

Function FindJobByID(Val JobID)
	
	If TypeOf(JobID) = Type("String") Then
		JobID = New UUID(JobID);
	EndIf;
	
	Job = BackgroundJobs.FindByUUID(JobID);
	Return Job;
	
EndFunction

// Reads background job execution process details and messages that were generated.
//
// Parameters:
//   JobID - UUID - the background job ID.
//   Mode                - String - "ProgressAndMessages", "Progress", or "Messages".
//
// Returns:
//   Structure - with the following properties:
//    * Progress  - Undefined, Structure - background job progress information that was recorded by the ReportProgress function:
//     ** Percentage                 - Number  - optional. Progress percentage.
//     ** Text                   - String - optional. Details on the current action.
//     ** AdditionalParameters - Arbitrary - optional. Any additional information.
//    * Messages - FixedArray - the array of UserMessage objects that were generated in the background job.
//
Function ReadProgressAndMessages(Val JobID, Val Mode = "ProgressAndMessages")
	
	Messages = New FixedArray(New Array);
	Result = New Structure("Messages, Progress", Messages, Undefined);
	
	Job = BackgroundJobs.FindByUUID(JobID);
	If Job = Undefined Then
		Return Result;
	EndIf;
	
	MessagesArray = Job.GetUserMessages(True);
	If MessagesArray = Undefined Then
		Return Result;
	EndIf;
	
	Count = MessagesArray.Count();
	Messages = New Array;
	MustReadMessages = (Mode = "ProgressAndMessages" Or Mode = "Messages"); 
	MustReadProgress  = (Mode = "ProgressAndMessages" Or Mode = "Progress"); 
	
	If MustReadMessages AND Not MustReadProgress Then
		Result.Messages = New FixedArray(MessagesArray);
		Return Result;
	EndIf;
	
	For Number = 0 To Count - 1 Do
		Message = MessagesArray[Number];
		
		If MustReadProgress AND StrStartsWith(Message.Text, "{") Then
			Position = StrFind(Message.Text, "}");
			If Position > 2 Then
				MechanismID = Mid(Message.Text, 2, Position - 2);
				If MechanismID = ProgressMessage() Then
					ReceivedText = Mid(Message.Text, Position + 1);
					Result.Progress = Common.ValueFromXMLString(ReceivedText);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		If MustReadMessages Then
			Messages.Add(Message);
		EndIf;
	EndDo;
	
	Result.Messages = New FixedArray(Messages);
	Return Result;
	
EndFunction

Function BackgroundJobsExistInFileIB()
	
	JobsRunningInFileIB = 0;
	If Common.FileInfobase() AND Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunningInFileIB = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	Return JobsRunningInFileIB > 0;

EndFunction

Function CanRunInBackground(ProcedureName)
	
	NameParts = StrSplit(ProcedureName, ".");
	If NameParts.Count() = 0 Then
		Return False;
	EndIf;
	
	IsExternalDataProcessor = (Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR");
	IsExternalReport = (Upper(NameParts[0]) = "EXTERNALREPORT");
	Return Not (IsExternalDataProcessor Or IsExternalReport);

EndFunction

Function RunBackgroundJob(ExecutionParameters, MethodName, Parameters, varKey, Description)
	
	If CurrentRunMode() = Undefined
		AND Common.FileInfobase() Then
		
		Session = GetCurrentInfoBaseSession();
		If ExecutionParameters.WaitForCompletion = Undefined AND Session.ApplicationName = "BackgroundJob" Then
			Raise NStr("ru = 'В файловой информационной базе невозможно одновременно выполнять более одного фонового задания'; en = 'In a file infobase, only one background job can run at a time.'; pl = 'W bazie informacji o pliku nie można jednocześnie wykonać więcej niż jednego zadania w tle.';de = 'Es ist nicht möglich, mehr als einen Hintergrundjob gleichzeitig in der Dateidatenbank auszuführen';ro = 'În baza de informații de tip fișier nu puteți executa concomitent mai mult decât o sarcină de fundal';tr = 'Dosya veritabanında birden fazla arkaplan görevi aynı anda yürütülemez'; es_ES = 'En la base de información de archivo es imposible realizar más de una tarea de fondo simultáneamente'");
		ElsIf Session.ApplicationName = "COMConnection" Then
			Raise NStr("ru = 'В файловой информационной базе можно запустить фоновое задание только из клиентского приложения'; en = 'In a file infobase, background jobs can only be started from the client application.'; pl = 'W bazie informacji o plikach można uruchomić zadanie w tle tylko z aplikacji klienta';de = 'In der Dateiinformationsdatenbank können Sie die Hintergrundaufgabe nur aus der Client-Anwendung heraus starten';ro = 'În baza de informații de tip fișier puteți lansa sarcina de fundal numai din aplicația de client';tr = 'Dosya bilgi tabanında, yalnızca istemci uygulamasından bir arka plan görevi çalıştırabilirsiniz'; es_ES = 'En la base de información de archivo se puede lanzar una tarea de fondo solo de la aplicación cliente'");
		EndIf;
		
	EndIf;
	
	If ExecutionParameters.NoExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(MethodName, Parameters, varKey, Description);
	Else
		Return BackgroundJobs.Execute(MethodName, Parameters, varKey, Description);
	EndIf;
	
EndFunction

#EndRegion
