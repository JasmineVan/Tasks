﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// All methods accessible via API work with job parameters. Accessibility of any given parameter 
// depends on the selected method and, in some cases, on the values of other parameters.
//  For more information, see method descriptions.
//
// Parameter details:
//   DataArea - Number - job data area separator value.
//    -For unseparated jobs 1. If session separation is enabled
//    session value will be used.
//   ID - CatalogRef.JobQueue,
//     CatalogRef.DataAreaJobQueue - job ID.
//   Usage - Boolean - job usage flag.
//   ScheduledStartTime - Data (DateTime) - scheduled job launch date (as adjusted for the data area 
//    time zone).
//   JobState - EnumRef.JobStates - queued job state.
//   ExclusiveExecution - Boolean - if this flag is set, the job will be executed even if session 
//    start is prohibited in the data area. If any jobs with this flag are available in a data area, 
//    they will be executed first.
//   Template - CatalogRef.QueueJobTemplates - job template, used for separated queue jobs only.
//     
//   MethodName - String - Job handler method name (or alias). Not applicable to jobs created from 
//    templates.
//    Only methods with aliases registered via the OnDefineHandlerAliases procedure of the 
//    JobQueueOverridable common module can be used.
//   Parameters - Array - parameters to be passed to job handler.
//   Key - String - job key. Duplicate jobs with identical keys and method names are not allowed 
//    within the same data area.
//   RestartIntervalOnFailure - Number - time interval in seconds between job failure and job 
//     restart. Measured from the moment of failed job completion.
//      Used only in combination with RestartCountOnFailure parameter.
//     
//   Schedule - JobSchedule - a job schedule.
//     If it is not specified, the job will be executed once only.
//   RestartCountOnFailure - Number - number of repeated job execution attempts in case of failure.
//    

// Receives queue jobs by specified filter.
// Inconsistent data can be received.
//
// Parameters:
//  Filter - Structure - job filtering values (combined by conjunction). Allowed structure keys:
//            * DataArea - Number - data area,
//            * MethodName - String - method name,
//            * ID - UUID - job ID,
//            * JobState - EnumRef.JobStates - job state,
//            * Key - String - job key,
//            * Template - CatalogRef.QueueJobTemplates - job template,
//            * Usage - Boolean - job usage.
//        - Array - contains structure with the following properties:
//            * ComparisonType - ComparisonType - only the following values are allowed:
//                ComparisonType.Equal
//                ComparisonType.NotEqual
//                ComparisonType.InList
//                ComparisonType.NotInList
//            * Value - Filter value for InList and NotInList comparison types - an array of values 
//                for the Equal and NotEqual comparison types - the values.
//
// Returns:
//  ValueTable - identified jobs table. Each column corresponds to a job parameter.
//
Function GetJobs(Val Filter) Export
	
	CheckJobParameters(Filter, "Filter");
	
	// Generating a table with filter conditions.
	ConditionTable = New ValueTable;
	ConditionTable.Columns.Add("Field", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	ConditionTable.Columns.Add("ComparisonType", New TypeDescription("ComparisonType"));
	ConditionTable.Columns.Add("Parameter", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	ConditionTable.Columns.Add("Value");
	
	ParametersDetailsCollection = JobsQueueInternalCached.QueueJobParameters();
	
	GetSeparated = True;
	GetUnseparated = True;
	
	For each KeyAndValue In Filter Do
		
		ParameterDetails = ParametersDetailsCollection.Find(Upper(KeyAndValue.Key), "UpperCaseName");
		
		If ParameterDetails.DataSeparation Then
			SeparationControl = True;
		Else
			SeparationControl = False;
		EndIf;
		
		If TypeOf(KeyAndValue.Value) = Type("Array") Then
			For Index = 0 To KeyAndValue.Value.UBound() Do
				FilterDetails = KeyAndValue.Value[Index];
				
				Condition = ConditionTable.Add();
				Condition.Field = ParameterDetails.Field;
				Condition.ComparisonType = FilterDetails.ComparisonType;
				Condition.Parameter = ParameterDetails.Name + IndexFormat(Index);
				Condition.Value = FilterDetails.Value;
				
				If SeparationControl Then
					DefineFilterByCatalogSeparation(
						FilterDetails.Value,
						ParameterDetails,
						GetSeparated,
						GetUnseparated);
				EndIf;
				
			EndDo;
		Else
			
			Condition = ConditionTable.Add();
			Condition.Field = ParameterDetails.Field;
			Condition.ComparisonType = ComparisonType.Equal;
			Condition.Parameter = ParameterDetails.Name;
			Condition.Value = KeyAndValue.Value;
			
			If SeparationControl Then
				DefineFilterByCatalogSeparation(
					KeyAndValue.Value,
					ParameterDetails,
					GetSeparated,
					GetUnseparated);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Preparing query
	Query = New Query;
	
	DataAreaJobSeparator = SaaS.AuxiliaryDataSeparator();
	
	JobCatalogs = JobsQueueInternalCached.GetJobCatalogs();
	QueryText = "";
	For Each CatalogJob In JobCatalogs Do
		
		Cancel = False;
		CatalogName = Metadata.FindByType(TypeOf(CatalogJob)).FullName();
		
		If Not GetSeparated Then
			
			If SaaSCached.IsSeparatedConfiguration() AND SaaS.IsSeparatedMetadataObject(CatalogName, DataAreaJobSeparator) Then
				Continue;
			EndIf;
			
		EndIf;
		
		If Not GetUnseparated Then
			
			If Not SaaSCached.IsSeparatedConfiguration() OR Not SaaS.IsSeparatedMetadataObject(CatalogName, DataAreaJobSeparator) Then
				Continue;
			EndIf;
			
		EndIf;
		
		If Not IsBlankString(QueryText) Then
			
			QueryText = QueryText + "
			|
			|UNION ALL
			|"
			
		EndIf;
		
		SelectionFields = JobsQueueInternalCached.JobQueueSelectionFields(CatalogName);
		
		ConditionsLine = "";
		If ConditionTable.Count() > 0 Then
			
			ComparisonKinds = JobsQueueInternalCached.JobFilterComparisonTypes();
			
			For Each Condition In ConditionTable Do
				
				If Condition.Field = DataAreaJobSeparator Then
					If Not SaaSCached.IsSeparatedConfiguration() OR Not SaaS.IsSeparatedMetadataObject(CatalogName, DataAreaJobSeparator) Then
						Cancel = True;
						Continue;
					EndIf;
				EndIf;
				
				If NOT IsBlankString(ConditionsLine) Then
					ConditionsLine = ConditionsLine + Chars.LF + Chars.Tab + "AND ";
				EndIf;
				
				ConditionsLine = ConditionsLine + "Queue." + Condition.Field + " "
					+ ComparisonKinds.Get(Condition.ComparisonType) + " (&" + Condition.Parameter + ")";
				
				Query.SetParameter(Condition.Parameter, Condition.Value);
			EndDo;
			
		EndIf;
		
		If Cancel Then
			Continue;
		EndIf;
		
		If SaaSCached.IsSeparatedConfiguration() AND SaaS.IsSeparatedMetadataObject(CatalogName, SaaS.AuxiliaryDataSeparator()) Then
			
			QueryText = QueryText + StringFunctionsClientServer.SubstituteParametersToString(
				"SELECT
				|" + SelectionFields + ",
				|	ISNULL(TimeZones.Value, """") AS TimeZone
				|FROM
				|	%1 AS Queue LEFT JOIN Constant.DataAreaTimeZone AS TimeZones
				|		ON Queue.DataAreaAuxiliaryData = TimeZones.DataAreaAuxiliaryData",
				CatalogJob.EmptyRef().Metadata().FullName());
			
		Else
			
			QueryText = QueryText + StringFunctionsClientServer.SubstituteParametersToString(
				"SELECT
				|" + SelectionFields + ",
				|	"""" AS TimeZone
				|FROM
				|	%1 AS Queue",
				CatalogJob.EmptyRef().Metadata().FullName());
			
		EndIf;
		
		If Not IsBlankString(ConditionsLine) Then
			
			QueryText = QueryText + "
			|WHERE
			|	" + ConditionsLine;
			
		EndIf;
		
	EndDo;
	
	If IsBlankString(QueryText) Then
		Raise NStr("ru = 'Некорректное значение отбора - не обнаружено на одного справочника, задания из которого подходили бы под условия в отборе.'; en = 'Incorrect filter value. No catalog found whose tasks meet the filter conditions.'; pl = 'Niepoprawna wartość selekcji - nie ujawniono żadnego katalogu, zadania z którego odpowiadają warunkom selekcji.';de = 'Ungültiger Auswahlwert - in keinem Verzeichnis gefunden, die Aufgaben, aus denen die Bedingungen in der Auswahl passen würden.';ro = 'Valoare incorectă a filtrului - nu a fost găsit nici un clasificator, sarcinile căruia îndeplinesc condițiile de filtrare.';tr = 'Yanlış filtre değeri. Görevleri filtre koşullarına uygun olan katalog bulunamadı.'; es_ES = 'Valor del filtro incorrecto. Ningún catálogo cuyas tareas cumplen las condiciones del filtro se ha encontrado.'");
	EndIf;
	
	Query.Text = QueryText;
	
	// Getting data
	If TransactionActive() Then
		Result = Query.Execute().Unload();
	Else
		Result = SaaS.ExecuteQueryOutsideTransaction(Query).Unload();
	EndIf;
	
	// Processing results
	Result.Columns.Schedule.Name = "ScheduleStorage";
	Result.Columns.Parameters.Name = "ParametersStorage";
	Result.Columns.Add("Schedule", New TypeDescription("JobSchedule, Undefined"));
	Result.Columns.Add("Parameters", New TypeDescription("Array"));
	
	For each JobRow In Result Do
		JobRow.Schedule = JobRow.ScheduleStorage.Get();
		JobRow.Parameters = JobRow.ParametersStorage.Get();
		
		AreaTimeZone = JobRow.TimeZone;
		If Not ValueIsFilled(AreaTimeZone) Then
			AreaTimeZone = Undefined;
		EndIf;
		
		JobRow.ScheduledStartTime = 
			ToLocalTime(JobRow.ScheduledStartTime, AreaTimeZone);
	EndDo;
	
	Result.Columns.Delete("ScheduleStorage");
	Result.Columns.Delete("ParametersStorage");
	Result.Columns.Delete("TimeZone");
	
	Return Result;
	
EndFunction

// Adds a new job to the queue.
// If called from within a transaction, object lock is set for the job.
// 
// Parameters:
//  JobParameters - Structure - parameters of the job to be added. The following keys can be used:
//   DataArea
//   Usage
//   ScheduledStartTime
//   ExclusiveExecution.
//   MethodName - mandatory.
//   Parameters
//   Key
//   RestartIntervalOnFailure.
//   Schedule
//   RestartCountOnFailure.
//
// Returns:
//  CatalogRef.JobQueue, CatalogRef.DataAreaJobQueue - added job ID.
// 
Function AddJob(JobParameters) Export
	
	CheckJobParameters(JobParameters, "Insert");
	
	// Checking method name
	If NOT JobParameters.Property("MethodName") Then
		Raise(NStr("ru = 'Не задан обязательный параметр задания ИмяМетода'; en = 'Mandatory parameter not set for job MethodName'; pl = 'Nie określono wymaganego parametru zadania MethodName';de = 'Erforderlicher Parameter des Jobs MethodName ist nicht angegeben';ro = 'Parametrul obligatoriu al sarcinii MethodName nu este specificat';tr = 'Yöntem Adı işinin gerekli parametresi belirtilmemiş'; es_ES = 'Parámetro requerido de la tarea MethodName no está especificado'"));
	EndIf;
	
	CheckJobHandlerRegistration(JobParameters.MethodName);
	
	// Checking key for uniqueness.
	If JobParameters.Property("Key") AND ValueIsFilled(JobParameters.Key) Then
		Filter = New Structure;
		Filter.Insert("MethodName", JobParameters.MethodName);
		Filter.Insert("Key", JobParameters.Key);
		Filter.Insert("DataArea", JobParameters.DataArea);
		Filter.Insert("JobState", New Array);
		
		// Ignore completed jobs.
		FilterDetails = New Structure;
		FilterDetails.Insert("ComparisonType", ComparisonType.NotEqual);
		FilterDetails.Insert("Value", Enums.JobsStates.Completed);
		
		Filter.JobState.Add(FilterDetails);
		
		If GetJobs(Filter).Count() > 0 Then
			Raise GetJobsWithSameKeyDuplicationErrorMessage();
		EndIf;
	EndIf;
	
	// Defaults
	If NOT JobParameters.Property("Use") Then
		JobParameters.Insert("Use", True);
	EndIf;
	
	PlannedStartTime = Undefined;
	If JobParameters.Property("ScheduledStartTime", PlannedStartTime) Then
		
		StandardProcessing = True;
		If SaaSCached.IsSeparatedConfiguration() Then
			
			ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobQueueInternalDataSeparation");
			ModuleJobQueueInternalDataSeparation.OnDefineScheduledStartTime(
				JobParameters,
				PlannedStartTime,
				StandardProcessing);
			
		EndIf;
		
		If StandardProcessing Then
			PlannedStartTime = ToUniversalTime(PlannedStartTime);
		EndIf;
		
		JobParameters.Insert("ScheduledStartTime", PlannedStartTime);
		
		StartTimeSet = True;
		
	Else
		
		JobParameters.Insert("ScheduledStartTime", CurrentUniversalDate());
		StartTimeSet = False;
		
	EndIf;
	
	// Types that will be saved to a value storage.
	If JobParameters.Property("Parameters") Then
		JobParameters.Insert("Parameters", New ValueStorage(JobParameters.Parameters));
	Else
		JobParameters.Insert("Parameters", New ValueStorage(New Array));
	EndIf;
	
	If JobParameters.Property("Schedule") 
		AND JobParameters.Schedule <> Undefined Then
		
		JobParameters.Insert("Schedule", New ValueStorage(JobParameters.Schedule));
	Else
		JobParameters.Insert("Schedule", Undefined);
	EndIf;
	
	// Generating job record.
	
	CatalogForJob = Catalogs.JobQueue;
	StandardProcessing = True;
	
	If SaaSCached.IsSeparatedConfiguration() Then
		ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobQueueInternalDataSeparation");
		OverriddenCatalog = ModuleJobQueueInternalDataSeparation.OnSelectCatalogForJob(JobParameters);
		If OverriddenCatalog <> Undefined Then
			CatalogForJob = OverriddenCatalog;
		EndIf;
	EndIf;
	
	Job = CatalogForJob.CreateItem();
	For each ParameterDetails In JobsQueueInternalCached.QueueJobParameters() Do
		If JobParameters.Property(ParameterDetails.Name) Then
			If ParameterDetails.DataSeparation Then
				If Not SaaSCached.IsSeparatedConfiguration() OR Not SaaS.IsSeparatedMetadataObject(Job.Metadata(), SaaS.AuxiliaryDataSeparator()) Then
					Continue;
				EndIf;
			EndIf;
			Job[ParameterDetails.Field] = JobParameters[ParameterDetails.Name];
		EndIf;
	EndDo;
	
	If Job.Use
		AND (StartTimeSet OR JobParameters.Schedule = Undefined) Then
			
		Job.JobState = Enums.JobsStates.Scheduled;
	Else
		Job.JobState = Enums.JobsStates.NotScheduled;
	EndIf;
	
	JobRef = CatalogForJob.GetRef();
	Job.SetNewObjectRef(JobRef);
	
	If TransactionActive() Then
		
		LockDataForEdit(JobRef);
		// Lock will be automatically removed once the transaction is completed.
	EndIf;
	
	SaaS.WriteAuxiliaryData(Job);
	
	Return Job.Ref;
	
EndFunction

// Changes the job with the specified attribute.
// If called from within a transaction, object lock is set for the job.
// 
// Parameters:
//  ID - CatalogRef.JobQueue, CatalogRef.DataAreaJobQueue - a job ID
//  JobParameters - Structure - job parameters, allowed keys:
//   
//   Usage
//   ScheduledStartTime
//   ExclusiveExecution
//   MethodName.
//   Parameters
//   Key
//   RestartIntervalOnFailure.
//   Schedule
//   RestartCountOnFailure.
//   
//   If the job is based on a template, only the following keys are allowed:
//   
//		Usage,
//		ScheduledStartTime,
//		ExclusiveExecution,
//		RestartIntervalOnFailure,
//		Schedule,
//		RestartCountOnFailure.
// 
Procedure ChangeJob(ID, JobParameters) Export
	
	CheckJobParameters(JobParameters, "Update");
	
	Job = JobDescriptionByID(ID);
	
	// Checking for attempts to change a job in another area.
	If SaaS.DataSeparationEnabled()
		AND SaaS.SeparatedDataUsageAvailable()
		AND Job.DataArea <> SaaS.SessionSeparatorValue() Then
		
		Raise(GetExceptionTextToReceiveDataFromOtherAreas());
	EndIf;
	
	// Checking for attempts to change parameters for a template-based job.
	If SaaSCached.IsSeparatedConfiguration() AND SaaS.IsSeparatedMetadataObject(
				ID.Metadata().FullName(),
				SaaS.AuxiliaryDataSeparator()) Then
		If ValueIsFilled(Job.Template) Then
			ParametersDetailsCollection = JobsQueueInternalCached.QueueJobParameters();
			For each KeyAndValue In JobParameters Do
				ParameterDetails = ParametersDetailsCollection.Find(Upper(KeyAndValue.Key), "UpperCaseName");
				If Not ParameterDetails.Template Then
					MessageTemplate = NStr("ru = 'Задание очереди с идентификатором %1 создано на основе шаблона.
						|Изменение параметра %2 заданий с установленным шаблоном запрещено.'; 
						|en = 'Queue job with ID %1 is created from the template.
						|Changing parameter %2 of jobs with the set template is prohibited.'; 
						|pl = 'Zadanie kolejki z identyfikatorem %1 jest tworzone z szablonu.
						|Nie można zmienić parametru %2 zadań z ustawionym szablonem.';
						|de = 'Warteschlangenjob mit ID %1 wird aus Vorlage erstellt. 
						| Parameter %2 von Jobs können nicht mit der gesetzten Vorlage geändert werden.';
						|ro = 'Sarcina din coadă cu ID %1 este creată din șablon.
						|Este interzisă modificarea parametrului %2 sarcinilor cu șablonul setat.';
						|tr = '%1ID''li sıra işi şablondan oluşturuldu. 
						|Ayar şablonundaki işlerin parametresi %2 değiştirilemez.'; 
						|es_ES = 'Tarea de la solicitud con el identificador %1 se ha creado desde el modelo.
						|No se puede cambiar el parámetro %2 de tarea con el modelo de conjuntos.'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ID, ParameterDetails.Name);
					Raise(MessageText);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Checking key for uniqueness.
	If JobParameters.Property("Key") AND ValueIsFilled(JobParameters.Key) Then
		Filter = New Structure;
		Filter.Insert("MethodName", JobParameters.MethodName);
		Filter.Insert("Key", JobParameters.Key);
		Filter.Insert("DataArea", Job.DataArea);
		Filter.Insert("ID", New Array);
		
		// Ignore the changed job.
		FilterDetails = New Structure;
		FilterDetails.Insert("ComparisonType", ComparisonType.NotEqual);
		FilterDetails.Insert("Value", ID);
		
		Filter.ID.Add(FilterDetails);
		
		If GetJobs(Filter).Count() > 0 Then
			Raise GetJobsWithSameKeyDuplicationErrorMessage();
		EndIf;
	EndIf;
	
	ScheduledStartTime = Undefined;
	If JobParameters.Property("ScheduledStartTime", ScheduledStartTime)
			AND ValueIsFilled(JobParameters.ScheduledStartTime) Then
		
		StandardProcessing = True;
		If SaaSCached.IsSeparatedConfiguration() Then
			
			ModuleJobQueueInternalDataSeparation = Common.CommonModule("JobQueueInternalDataSeparation");
			ModuleJobQueueInternalDataSeparation.OnDefineScheduledStartTime(
				JobParameters,
				ScheduledStartTime,
				StandardProcessing);
			
		EndIf;
		
		If StandardProcessing Then
			ScheduledStartTime = ToUniversalTime(ScheduledStartTime);
		EndIf;
		
		JobParameters.Insert("ScheduledStartTime", ScheduledStartTime);
		
		StartTimeSet = True;
	Else
		StartTimeSet = False;
	EndIf;
	
	// Types that will be saved to a value storage.
	If JobParameters.Property("Parameters") Then
		JobParameters.Insert("Parameters", New ValueStorage(JobParameters.Parameters));
	EndIf;
	
	If JobParameters.Property("Schedule")
		AND JobParameters.Schedule <> Undefined Then
		
		JobParameters.Insert("Schedule", New ValueStorage(JobParameters.Schedule));
	EndIf;
	
	// Rescheduling a scheduled job.
	If NOT JobParameters.Property("ScheduledStartTime", ScheduledStartTime)
		AND JobParameters.Property("Schedule") Then
		
		JobParameters.Insert("ScheduledStartTime", ScheduledStartTime);
	EndIf;
	
	// Locking a job record
	LockDataForEdit(ID);
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add(ID.Metadata().FullName());
		LockItem.SetValue("Ref", ID);
		Lock.Lock();
		
		// Generating job record.
		
		If Not Common.RefExists(ID) Then
			MessageTemplate = NStr("ru = 'Задание с идентификатором %1 к изменению не найдено. Область данных: %2'; en = 'Job with ID %1 to change is not found. Data area: %2'; pl = 'Nie znaleziono zadania z identyfikatorem %1 do zmiany. Obszar danych: %2';de = 'Job mit zu ändernder ID %1 wurde nicht gefunden. Datenbereich: %2';ro = 'Postarea cu ID %1 pentru schimbare nu a fost găsită. Zona de date: %2';tr = 'Değiştirilecek %1ID''e sahip iş bulunamadı. Veri alanı:%2'; es_ES = 'Tarea con el identificador %1 para cambiar no se ha encontrado. Área de datos: %2'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ID, Job.DataArea);
			Raise(MessageText);
		EndIf;
		
		Job = ID.GetObject();
		
		For each ParameterDetails In JobsQueueInternalCached.QueueJobParameters() Do
			If JobParameters.Property(ParameterDetails.Name) Then
				Job[ParameterDetails.Field] = JobParameters[ParameterDetails.Name];
			EndIf;
		EndDo;
		
		If Job.Use
			AND (StartTimeSet 
			OR NOT JobParameters.Property("Schedule")
			OR JobParameters.Schedule = Undefined) Then
				
			Job.JobState = Enums.JobsStates.Scheduled;
		Else
			Job.JobState = Enums.JobsStates.NotScheduled;
		EndIf;
		
		SaaS.WriteAuxiliaryData(Job);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	If NOT TransactionActive() Then // Otherwise, lock will be removed once the transaction is completed.
		UnlockDataForEdit(ID);
	EndIf;
	
EndProcedure

// Removes a job from the job queue.
// Removing the template-based jobs is prohibited.
// If called from within a transaction, object lock is set for the job.
// 
// Parameters:
//  ID - CatalogRef.JobQueue, CatalogRef.DataAreaJobQueue, - job ID.
// 
Procedure DeleteJob(ID) Export
	
	Job = ID.GetObject();
	
	If SaaSCached.IsSeparatedConfiguration() AND SaaS.IsSeparatedMetadataObject(
				Job.Metadata().FullName(),
				SaaS.AuxiliaryDataSeparator()) Then
		If ValueIsFilled(Job.Template) Then
			MessageTemplate = NStr("ru = 'Задание очереди с идентификатором %1 создано на основе шаблона.
				|Удаление заданий с установленным шаблоном запрещено.'; 
				|en = 'Queue job with ID %1 is created from the template.
				|Deleting jobs with the set template is prohibited.'; 
				|pl = 'Zadanie kolejki z identyfikatorem %1 jest tworzone z szablonu.
				|Usuwanie zadań z zainstalowanym szablonem jest zabronione.';
				|de = 'Warteschlangenjob mit ID %1 wird aus der Vorlage erstellt.
				|Das Löschen von Aufgaben mit der installierten Vorlage ist untersagt.';
				|ro = 'Sarcina din coadă cu ID %1 este creată din șablon.
				|Este interzisă ștergerea sarcinilor cu șablonul setat.';
				|tr = '%1ID''li sıra işi şablondan oluşturulur. 
				|Yüklenen şablonla görevlerin silinmesi yasaktır.'; 
				|es_ES = 'Tarea de la solicitud con el identificador %1 se ha creado desde el modelo.
				|Eliminación de tareas con el modelo instalado está prohibida.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ID);
			Raise(MessageText);
		EndIf;
	EndIf;
	
	LockDataForEdit(ID);
	
	Job.DataExchange.Load = True;
	SaaS.DeleteAuxiliaryData(Job);
	
	If NOT TransactionActive() Then // Otherwise, lock will be removed once the transaction is completed.
		UnlockDataForEdit(ID);
	EndIf;
	
EndProcedure

// Returns a queue job template corresponding to the name of a predefined scheduled job used to 
// create the template.
//
// Parameters:
//  Name - String - name of the predefined scheduled job.
//   
//
// Returns:
//  CatalogRef.QueueJobTemplates - job template.
//
Function TemplateByName(Val Name) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	QueueJobTemplates.Ref AS Ref
	|FROM
	|	Catalog.QueueJobTemplates AS QueueJobTemplates
	|WHERE
	|	QueueJobTemplates.Name = &Name";
	Query.SetParameter("Name", Name);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		MessageTemplate = NStr("ru = 'Не найден шаблон задания с именем %1'; en = 'Job template %1 not found'; pl = 'Nie znaleziono szablonu o nazwie %1';de = 'Jobvorlage mit Name %1 wurde nicht gefunden';ro = 'Șablonul cu numele %1 nu a fost găsit';tr = '%1 isimli iş şablonu bulunamadı'; es_ES = 'Modelo de tareas con el nombre %1 no se ha encontrado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Name);
		Raise(MessageText);
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

// Returns error text related to an attempt to run two jobs with identical keys simultaneously.
//
// Returns:
//   String - exception text.
//
Function GetJobsWithSameKeyDuplicationErrorMessage() Export
	
	Return NStr("ru = 'Дублирование заданий с одинаковым значения поля ''Ключ'' не допустимо.'; en = 'Job duplication with the same value of the ''Key'' field is not allowed.'; pl = 'Powielanie zadań o tej samej wartości pola ""Klucz""  jest niedozwolone.';de = 'Jobverdopplung mit dem gleichen Wert des ''Schlüssel'' Feldes ist nicht erlaubt.';ro = 'Repetarea lucrărilor cu aceeași valoare a câmpului ""cheie"" nu este permisă.';tr = '''Anahtar'' alanının aynı değeriyle iş çoğaltma işlemine izin verilmez.'; es_ES = 'No se admite la duplicación de las tareas con el mismo valor del campo ''Clave''.'");
	
EndFunction

// Returns a list of templates for queued jobs.
//
// Returns:
//  Array - names of predefined shared scheduled jobs to be used as queue job templates.
//           
//
Function QueueJobTemplates() Export
	
	Templates = New Array;
	
	SSLSubsystemsIntegration.OnGetTemplateList(Templates);
	JobsQueueOverridable.OnGetTemplateList(Templates);
	
	Return Templates;
	
EndFunction

#EndRegion

#Region Private

// Checks the passed parameter structure for compliance with subsystem requirements:
// 
//  - key list
//  - parameter types.
//
// Parameters:
//  Parameters - Structure - job parameters.
//  Mode - String - mode used for parameter check.
//   The following values are available:
//    Filter - checking parameters for filtering.
//    Adding - checking parameters for adding.
//    Changing - checking parameters for changing.
// 
Procedure CheckJobParameters(Parameters, Mode)
	
	If TypeOf(Parameters) <> Type("Structure") Then
		MessageTemplate = NStr("ru = 'Передан недопустимый тип набора параметров задания - %1'; en = 'Invalid job parameter set type passed - %1'; pl = 'Przekazano nieprawidłowy typ parametrów zadania - %1';de = 'Ungültiger Typ von Aufgabenparametern - %1 wurde übertragen';ro = 'A fost transmis tipul inadmisibil al setului de parametri ai sarcinii - %1';tr = 'Geçersiz görev parametresi türü - %1 iletildi'; es_ES = 'Tipo inválido de los parámetros de la tarea - %1 se ha pasado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TypeOf(Parameters));
		Raise(MessageText);
	EndIf;
	
	Filter = Mode = "Filter";
	
	ParametersDetailsCollection = JobsQueueInternalCached.QueueJobParameters();
	
	ComparisonKinds = JobsQueueInternalCached.JobFilterComparisonTypes();
	
	FilterDescriptionKeys = New Array;
	FilterDescriptionKeys.Add("ComparisonType");
	FilterDescriptionKeys.Add("Value");
	
	For each KeyAndValue In Parameters Do
		ParameterDetails = ParametersDetailsCollection.Find(Upper(KeyAndValue.Key), "UpperCaseName");
		If ParameterDetails = Undefined 
			OR NOT ParameterDetails[Mode] Then
			
			MessageTemplate = NStr("ru = 'Передан недопустимый параметр задания - %1'; en = 'Invalid job parameter passed - %1'; pl = 'Podano nieprawidłowy parametr zadania: %1.';de = 'Ungültiger Aufgabenparameter übergeben: %1.';ro = 'A fost transmis parametrul inadmisibil al sarcinii - %1';tr = 'Geçersiz görev parametresi iletildi: %1'; es_ES = 'Parámetro de la tarea inválido pasado: %1.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, KeyAndValue.Key);
			Raise(MessageText);
		EndIf;
		
		If Filter AND TypeOf(KeyAndValue.Value) = Type("Array") Then
			// Filter description array
			For each FilterDetails In KeyAndValue.Value Do
				If TypeOf(FilterDetails) <> Type("Structure") Then
					MessageTemplate = NStr("ru = 'Передан недопустимый тип %1 в коллекции описания отбора %2'; en = 'Invalid type %1 passed in filter description collection %2'; pl = 'W kolekcji opisu filtrów %2 przekazano nieprawidłowy typ %1';de = 'In der Filterbeschreibungssammlung wurde ein ungültiger Typ %1 übertragen %2';ro = 'A fost transmis tipul inadmisibil %1 în colecția de descriere a filtrării %2';tr = 'Filtre tanımı %1 koleksiyonunda geçersiz tür iletildi%2'; es_ES = 'Tipo inválido %1 se ha pasado en la colección de descripciones de filtros %2'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TypeOf(FilterDetails), KeyAndValue.Key);
					Raise(MessageText);
				EndIf;
				
				// Checking keys
				For each KeyName In FilterDescriptionKeys Do
					If NOT FilterDetails.Property(KeyName) Then
						MessageTemplate = NStr("ru = 'Передано недопустимое описание отбора в коллекции описания отбора %1.
							|Отсутствует свойство %2.'; 
							|en = 'Invalid filter description in the filter description collection %1. 
							|Property %2 is missing.'; 
							|pl = 'W kolekcji opisu filtrów %1 przekazano nieprawidłowy opis filtru.
							|Brak właściwości %2.';
							|de = 'Ungültige Filterbeschreibung in der Filterbeschreibungssammlung %1 wird übertragen. 
							|Es gibt keine Eigenschaft %2.';
							|ro = 'A fost transmisă descrierea inadmisibilă a filtrului din colecția de descriere a filtrului %1.
							|Lipsește proprietatea %2.';
							|tr = 'Filtre açıklama koleksiyonunda geçersiz filtre açıklaması %1 iletildi.
							|Özellik%2 yok.'; 
							|es_ES = 'Descripción del filtro inválida en la colección de descripciones de filtros %1 está pasada.
							|No hay propiedad %2.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, KeyAndValue.Key, KeyName);
						Raise(MessageText);
					EndIf;
				EndDo;
				
				// Checking comparison type
				If ComparisonKinds.Get(FilterDetails.ComparisonType) = Undefined Then
					MessageTemplate = NStr("ru = 'Передан недопустимый вид сравнения в описании отбора в коллекции описания отбора %1'; en = 'Invalid comparison type passed in filter description in filter description collection %1'; pl = 'W opisie filtru w kolekcji opisu filtrów %1 przekazano nieprawidłowy rodzaj porównania.';de = 'Ungültige Vergleichsart in der Filterbeschreibung in der Filterbeschreibungssammlung %1';ro = 'A fost transmis tipul inadmisibil al comparației în descrierea filtrului din colecția de descriere a filtrului %1';tr = 'Filtre açıklama koleksiyonunda filtre açıklamasında geçersiz karşılaştırma türü%1'; es_ES = 'Tipo de comparación inválido en la descripción del filtro en la colección de descripciones de filtros %1'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, KeyAndValue.Key);
					Raise(MessageText);
				EndIf;
				
				// Value check
				If FilterDetails.ComparisonType = ComparisonType.InList
					OR FilterDetails.ComparisonType = ComparisonType.NotInList Then
					
					If TypeOf(FilterDetails.Value) <> Type("Array") Then
						MessageTemplate = NStr("ru = 'Передан недопустимый тип %1 в описании отбора в коллекции описания отбора %2.
							|Для вида сравнения %3 ожидается тип Массив.'; 
							|en = 'Invalid type %1 was passed in filter description collection %2.
							|For comparison kind %3, type Array is expected.'; 
							|pl = 'W opisie filtru w kolekcji opisu filtrów %2 przekazano nieprawidłowy typ %1.
							|Dla danego typu%3 oczekuje się typu Tablica.';
							|de = 'Ein ungültiger Typ %1 in der Filterbeschreibung in der Filterbeschreibungssammlung %2 wird übertragen.
							|Für den Übereinstimmungstyp %3 wird der Array-Typ erwartet.';
							|ro = 'A fost transmis tipul inadmisibil %1 în descrierea filtrului din colecția de descriere a filtrului %2.
							|Pentru tipul de comparație %3 este așteptat tipul Mulțime.';
							|tr = 'Filtre açıklaması koleksiyonundaki filtre açıklamasında %1  geçersiz tür iletildi. %2Eşleme türü için 
							|Dizilim türü%3 beklenir.'; 
							|es_ES = 'Tipo inválido%1 en la descripción del filtro en la colección de descripciones de filtros %2 está pasado.
							|Para el tipo correspondiente %3 el tipo de Conjunto está esperado.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TypeOf(FilterDetails.Value), KeyAndValue.Key, FilterDetails.ComparisonType);
						Raise(MessageText);
					EndIf;
					
					For each FilterValue In FilterDetails.Value Do
						CheckValueForComplianceWithParameterDescription(FilterValue, ParameterDetails);
					EndDo;
				Else
					CheckValueForComplianceWithParameterDescription(FilterDetails.Value, ParameterDetails);
				EndIf;
			EndDo;
		Else
			CheckValueForComplianceWithParameterDescription(KeyAndValue.Value, ParameterDetails);
		EndIf;
	EndDo;
	
	// Data area
	If SaaS.DataSeparationEnabled()
		AND SaaS.SeparatedDataUsageAvailable() Then
		
		If Parameters.Property("DataArea") Then
			If Parameters.DataArea <> SaaS.SessionSeparatorValue() Then
				Raise(NStr("ru = 'В данном сеансе недопустимо обращение к данным из другой области данных.'; en = 'Cannot access data from another data area in this session.'; pl = 'Nie można uzyskać dostępu do danych z innego obszaru danych w tej sesji.';de = 'In dieser Sitzung kann nicht auf Daten von einem anderen Datenbereich zugegriffen werden.';ro = 'Nu puteți accesa date din altă zonă de date în această sesiune.';tr = 'Bu oturumdaki başka bir veri alanından veriye erişilemiyor.'; es_ES = 'No se puede acceder a los datos desde otra área de datos en esta sesión.'"));
			EndIf;
		Else
			ParameterDetails = ParametersDetailsCollection.Find(Upper("DataArea"), "UpperCaseName");
			If ParameterDetails[Mode] Then
				Parameters.Insert("DataArea", SaaS.SessionSeparatorValue());
			EndIf;
		EndIf;
		
	EndIf;
	
	// ScheduledStartTime
	If Parameters.Property("ScheduledStartTime")
		AND NOT ValueIsFilled(Parameters.ScheduledStartTime) Then
		
		MessageTemplate = NStr("ru = 'Передано недопустимое значение %1 параметра задания %2'; en = 'Invalid value %1 of job parameter %2 passed'; pl = 'Przekazano nieprawidłową wartość %1 parametru zadania %2';de = 'Ungültiger Wert %1 des Aufgabenparameters %2 wurde übertragen';ro = 'A fost transmisă valoarea inadmisibilă %1 a parametrului sarcinii %2';tr = 'Geçersiz görev parametresi %1  değeri %2 iletildi'; es_ES = 'Valor inválido %1 del parámetro de la tarea %2 se ha pasado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
			Parameters.ScheduledStartTime, 
			ParametersDetailsCollection.Find(Upper("ScheduledStartTime"), "UpperCaseName").Name);
		Raise(MessageText);
	EndIf;
	
EndProcedure

Procedure CheckValueForComplianceWithParameterDescription(Val Value, Val ParameterDetails)
	
	If NOT ParameterDetails.Type.ContainsType(TypeOf(Value)) Then
		MessageTemplate = NStr("ru = 'Передан недопустимый тип %1 параметра задания %2'; en = 'Invalid type %1 of job parameter %2 passed'; pl = 'Przekazano nieprawidłowy typ %1 parametru zadania %2';de = 'Ungültiger Typ %1 des %2Aufgabenparameters wurde übertragen';ro = 'A fost transmis tipul inadmisibil %1 al parametrului sarcinii %2';tr = 'Geçersiz görev parametresi %1 türü %2 iletildi'; es_ES = 'Tipo inválido %1 del %2 parámetro de la tarea se ha pasado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TypeOf(Value), ParameterDetails.Name);
		Raise(MessageText);
	EndIf;
	
EndProcedure

Function IndexFormat(Val Index)
	
	Return Format(Index, "NZ=0; NG=")
	
EndFunction

Procedure CheckJobHandlerRegistration(Val MethodName)
	
	If JobsQueueInternalCached.MapBetweenMethodNamesAndAliases().Get(Upper(MethodName)) = Undefined Then
		MessageTemplate = NStr("ru = 'Не зарегистрирован псевдоним метода %1 для использования в качестве обработчика задания очереди.'; en = 'Alias not registered for method %1 to be used as queue job handler.'; pl = 'Alias metody %1 nie jest zarejestrowany do zastosowania jako procedura obsługi w kolejce zadań.';de = 'Die Alias-Methode %1 ist nicht als Jobwarteschlangen-Anwender registriert.';ro = 'Pseudonimul metodei %1 nu este înregistrat pentru a fi utilizat în calitate de handler al sarcinii din rândul de așteptare.';tr = 'Metod takma adı%1, bir iş kuyruğu işleyicisi olarak kullanılmak üzere kaydedilmedi.'; es_ES = 'Alias del método %1 no está registrado para utilizarse como un manipulador de la cola de tareas.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, MethodName);
		Raise(MessageText);
	EndIf;
	
EndProcedure

Function JobDescriptionByID(Val ID)
	
	If Not ValueIsFilled(ID) OR Not Common.RefExists(ID) Then
		MessageTemplate = NStr("ru = 'Передано недопустимое значение %1 параметра задания Идентификатор'; en = 'Invalid value %1 of job parameter ID passed'; pl = 'Przekazano nieprawidłową wartość %1 parametru zadania Identyfikator';de = 'Der ungültige Wert %1 der Jobparameter-ID wurde übertragen';ro = 'A fost transmisă valoarea inadmisibilă %1 a parametrului sarcinii Identificator';tr = 'Geçersiz iş parametresi %1 değeri iletildi'; es_ES = 'Valor inválido %1 del identificador del parámetro de la tarea se ha pasado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ID);
		Raise(MessageText);
	EndIf;
	
	Jobs = GetJobs(New Structure("ID", ID));
	If Jobs.Count() = 0 Then
		MessageTemplate = NStr("ru = 'Задание очереди с идентификатором %1 не найдено'; en = 'Queue job with ID %1 not found'; pl = 'Nie znaleziono kolejki zadań z identyfikatorem %1';de = 'Warteschlangenauftrag mit ID %1 wurde nicht gefunden';ro = 'Sarcina din rândul de așteptare cu ID %1 nu a fost găsită';tr = '%1Kimlikli iş kuyruğu bulunamadı'; es_ES = 'Tarea de la cola con el identificador %1 no se ha encontrado'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ID);
		Raise(MessageText);
	EndIf;
	
	Return Jobs[0];
	
EndFunction

// Returns error text related to an attempt to get job list for another data area while in a session 
// with separator values set.
//
// Returns:
//   String - exception text.
//
Function GetExceptionTextToReceiveDataFromOtherAreas()
	
	Return NStr("ru = 'В данном сеансе недопустимо обращение к данным из другой области данных.'; en = 'Cannot access data from another data area in this session.'; pl = 'Nie można uzyskać dostępu do danych z innego obszaru danych w tej sesji.';de = 'In dieser Sitzung kann nicht auf Daten von einem anderen Datenbereich zugegriffen werden.';ro = 'Nu puteți accesa date din altă zonă de date în această sesiune.';tr = 'Bu oturumdaki başka bir veri alanından veriye erişilemiyor.'; es_ES = 'No se puede acceder a los datos desde otra área de datos en esta sesión.'");
	
EndFunction

Procedure DefineFilterByCatalogSeparation(Val Value, Val ParameterDetails, GetSeparated, GetUnseparated)
	
	ValueType = TypeOf(Value);
	ValueTypeArray = New Array();
	ValueTypeArray.Add(ValueType);
	TypesDetails = New TypeDescription(ValueTypeArray);
	DefaultValue = TypesDetails.AdjustValue(
		ParameterDetails.ValueForUnseparatedJobs);
	If Value = DefaultValue Then
		
		GetSeparated = False;
		
	Else
		
		GetUnseparated = False;
		
	EndIf;
	
EndProcedure

#EndRegion
