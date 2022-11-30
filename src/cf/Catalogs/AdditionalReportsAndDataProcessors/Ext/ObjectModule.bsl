///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var IsGlobalDataProcessor;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If IsFolder Then
		Return;
	EndIf;
	
	ItemCheck = True;
	If AdditionalProperties.Property("ListCheck") Then
		ItemCheck = False;
	EndIf;
	
	If NOT AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind) Then
		If NOT UseForObjectForm AND NOT UseForListForm 
			AND Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled Then
			Common.MessageToUser(
				NStr("ru = 'Необходимо отключить публикацию или выбрать для использования как минимум одну из форм'; en = 'Make the report or data processor unavailable or select at least one of its forms'; pl = 'Wyłącz publikowanie lub wybierz przynajmniej jeden z używanych formularzy';de = 'Deaktivieren Sie die Veröffentlichung oder wählen Sie mindestens eines der zu verwendenden Formulare aus';ro = 'Trebuie să dezactivați publicarea sau să selectați pentru utilizare cel puțin una din forme';tr = 'Yayımlamayı devre dışı bırak veya kullanılacak formlardan en az birini seç'; es_ES = 'Desactivar el envío o seleccionar como mínimo uno de los formularios para utilizar'")
				,
				,
				,
				"Object.UseForObjectForm",
				Cancel);
		EndIf;
	EndIf;
	
	// When you publish a report, ensure that the object that contains the report has a unique ID.
	//     
	If Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used Then
		
		// Checking the name
		QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReports
		|WHERE
		|	AdditionalReports.ObjectName = &ObjectName
		|	AND &AdditReportCondition
		|	AND AdditionalReports.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
		|	AND AdditionalReports.DeletionMark = FALSE
		|	AND AdditionalReports.Ref <> &Ref";
		
		AddlReportsKinds = New Array;
		AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
		AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
		
		If AddlReportsKinds.Find(Kind) <> Undefined Then
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "AdditionalReports.Kind IN (&AddlReportsKinds)");
		Else
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "NOT AdditionalReports.Kind IN (&AddlReportsKinds)");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("ObjectName",     ObjectName);
		Query.SetParameter("AddlReportsKinds", AddlReportsKinds);
		Query.SetParameter("Ref",         Ref);
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		Conflicting = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Conflicting.Count() > 0 Then
			Cancel = True;
			If ItemCheck Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Имя ""%1"", используемое данным отчетом (обработкой), уже занято другим опубликованным дополнительным отчетом (обработкой). 
					|
					|Для продолжения необходимо изменить вид Публикации с ""%2"" на ""%3"" или ""%4"".'; 
					|en = 'The report or data processor name %1 is not unique.
					|
					|To continue, change availability from ""%2"" to ""%3"" or ""%4"".'; 
					|pl = 'Nazwa ""%1"" używana przez to sprawozdanie (przetwarzanie danych) jest już używana przez inne opublikowane sprawozdanie dodatkowe  (przetwarzanie danych)
					|
					|. Aby kontynuować, należy zmienić rodzaj publikacji z ""%2"" na ""%3"" lub ""%4"".';
					|de = 'Der von diesem Bericht (Datenprozessor) verwendete Name ""%1"" wird bereits von einem anderen, zusätzlich veröffentlichten Bericht (Datenprozessor) verwendet. 
					|
					|Um fortzufahren, ist es notwendig, die Publikationsart von ""%2"" in ""%3"" oder ""%4"" zu ändern.';
					|ro = 'Numele ""%1"" folosit de acest raport (procesare) este deja ocupat de alt raport publicat (procesare). 
					|
					| Pentru a continua, este necesar să modificați tipul Publicării din ""%2"" în ""%3"" sau ""%4"".';
					|tr = 'Bu raporda kullanılan ""%1"" adı (veri işlemcisi) yayınlanan başka bir ek rapor (veri işlemcisi) tarafından zaten kullanılıyor. 
					|
					|Devam etmek için Yayın türün ""%2"",  ""%3"" veya ""%4""olarak değiştirmelidir.'; 
					|es_ES = 'Nombre ""%1"" utilizado por este informe (procesador de datos) está ya utilizado por otro informe adicional enviado (procesador de datos).
					|
					|Para continuar es necesario cambiar el tipo de Envío de ""%2"" a ""%3"" o ""%4"".'"),
					ObjectName,
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled));
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Имя ""%1"", используемое отчетом (обработкой) ""%2"", уже занято другим опубликованным дополнительным отчетом (обработкой).'; en = 'The name %1 of the %2 report or data processor is not unique. The same name is assigned to another report or data processor.'; pl = 'Nazwa ""%1"" używana przez sprawozdanie (przetwarzanie danych) ""%2"" jest już używana przez inne opublikowany sprawozdanie dodatkowe  (przetwarzanie danych).';de = 'Der Name ""%1"", der vom Bericht verwendet wird (Datenprozessor) ""%2"" wird bereits von einem anderen veröffentlichten Zusatzbericht (Datenprozessor) verwendet.';ro = 'Numele ""%1"" folosit de acest raport (procesare) ""%2"" este deja ocupat de alt raport publicat (procesare).';tr = '""%2"" raporda kullanılan ""%1"" adı (veri işlemcisi) yayınlanan başka bir ek rapor (veri işlemcisi) tarafından zaten kullanılıyor. '; es_ES = 'Nombre ""%1"" utilizado por el informe (procesador de datos) ""%2"" está ya utilizado por otro informe adicional enviado (procesador de datos).'"),
					ObjectName,
					Common.ObjectAttributeValue(Ref, "Description"));
			EndIf;
			Common.MessageToUser(ErrorText, , "Object.Publication");
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SaaSIntegration.BeforeWriteAdditionalDataProcessor(ThisObject, Cancel);
	
	If IsNew() AND NOT AdditionalReportsAndDataProcessors.InsertRight(ThisObject) Then
		Raise NStr("ru = 'Недостаточно прав для добавления дополнительных отчетов или обработок.'; en = 'Insufficient rights to add additional reports or data processors.'; pl = 'Niewystarczające uprawnienia do dodawania dodatkowych sprawozdań lub przetwarzania danych.';de = 'Unzureichende Rechte zum Hinzufügen zusätzlicher Berichte oder Datenprozessoren.';ro = 'Drepturi insuficiente pentru adăugarea rapoartelor sau procesărilor suplimentare.';tr = 'Ek raporlar veya veri işlemcileri eklemek için yetersiz haklar.'; es_ES = 'Derechos insuficientes para añadir informes adicionales o procesadores de datos.'");
	EndIf;
	
	// Preliminary checks
	If NOT IsNew() AND Kind <> Common.ObjectAttributeValue(Ref, "Kind") Then
		Common.MessageToUser(
			NStr("ru = 'Невозможно сменить вид существующего дополнительного отчета или обработки.'; en = 'Cannot change the kind of additional report or data processor.'; pl = 'Nie można zmienić rodzaju istniejącego dodatkowego sprawozdania lub przetwarzania danych.';de = 'Die Art des vorhandenen zusätzlichen Berichts oder Datenprozessors kann nicht geändert werden.';ro = 'Nu se poate modifica tipul de raport suplimentar existent sau de procesor de date.';tr = 'Mevcut ek raporun veya veri işlemcisinin türü değiştirilemez.'; es_ES = 'No se puede cambiar el tipo del informe adicional existente o el procesador de datos.'"),,,,
			Cancel);
		Return;
	EndIf;
	
	// Attribute connection with deletion mark.
	If DeletionMark Then
		Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled;
	EndIf;
	
	// Cache of standard checks
	AdditionalProperties.Insert("PublicationAvailable", Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used);
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			BeforeWriteGlobalDataProcessors(Cancel);
		EndIf;
		Purpose.Clear();
	Else
		BeforeWriteAssignableDataProcessor(Cancel);
		Sections.Clear();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	QuickAccess = CommonClientServer.StructureProperty(AdditionalProperties, "QuickAccess");
	If TypeOf(QuickAccess) = Type("ValueTable") Then
		DimensionValues = New Structure("AdditionalReportOrDataProcessor", Ref);
		ResourcesValues = New Structure("Available", True);
		InformationRegisters.DataProcessorAccessUserSettings.WriteSettingsPackage(QuickAccess, DimensionValues, ResourcesValues, True);
	EndIf;
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			OnWriteGlobalDataProcessor(Cancel);
		EndIf;
	Else
		OnWriteAssignableDataProcessors(Cancel);
	EndIf;
	
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		OnWriteReport(Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SaaSIntegration.BeforeDeleteAdditionalDataProcessor(ThisObject, Cancel);
	
	If AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind) Then
		
		SetPrivilegedMode(True);
		// Deleting all jobs.
		For Each Command In Commands Do
			If ValueIsFilled(Command.GUIDScheduledJob) Then
				ScheduledJobsServer.DeleteJob(Command.GUIDScheduledJob);
			EndIf;
		EndDo;
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function IsGlobalDataProcessor()
	
	If IsGlobalDataProcessor = Undefined Then
		IsGlobalDataProcessor = AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind);
	EndIf;
	
	Return IsGlobalDataProcessor;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Global data processors

Procedure BeforeWriteGlobalDataProcessors(Cancel)
	If Cancel OR NOT AdditionalProperties.Property("RelevantCommands") Then
		Return;
	EndIf;
	
	CommandsTable = AdditionalProperties.RelevantCommands;
	
	JobsToUpdate = New Map;
	
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	// Clearing jobs whose commands are deleted from the table.
	If Not IsNew() Then
		For Each ObsoleteCommand In Ref.Commands Do
			If ValueIsFilled(ObsoleteCommand.GUIDScheduledJob)
				AND CommandsTable.Find(ObsoleteCommand.GUIDScheduledJob, "GUIDScheduledJob") = Undefined Then
				ScheduledJobsServer.DeleteJob(ObsoleteCommand.GUIDScheduledJob);
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the set of scheduled jobs before writing their IDs to the tabular section.
	For Each RelevantCommand In CommandsTable Do
		Command = Commands.Find(RelevantCommand.ID, "ID");
		
		If PublicationEnabled AND RelevantCommand.ScheduledJobSchedule.Count() > 0 Then
			Schedule    = RelevantCommand.ScheduledJobSchedule[0].Value;
			Usage = RelevantCommand.ScheduledJobUsage
				AND AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Schedule);
		Else
			Schedule = Undefined;
			Usage = False;
		EndIf;
		
		Job = ScheduledJobsServer.Job(RelevantCommand.GUIDScheduledJob);
		If Job = Undefined Then // Not found
			If Usage Then
				// Creating and registering a scheduled job.
				JobParameters = New Structure;
				JobParameters.Insert("Metadata", Metadata.ScheduledJobs.StartingAdditionalDataProcessors);
				JobParameters.Insert("Use", False);
				Job = ScheduledJobsServer.AddJob(JobParameters);
				JobsToUpdate.Insert(RelevantCommand, Job);
				Command.GUIDScheduledJob = ScheduledJobsServer.UUID(Job);
			Else
				// No action required
			EndIf;
		Else // Found
			If Usage Then
				// Register.
				JobsToUpdate.Insert(RelevantCommand, Job);
			Else
				// Delete.
				ScheduledJobsServer.DeleteJob(RelevantCommand.GUIDScheduledJob);
				Command.GUIDScheduledJob = CommonClientServer.BlankUUID();
			EndIf;
		EndIf;
	EndDo;
	
	AdditionalProperties.Insert("JobsToUpdate", JobsToUpdate);
	
EndProcedure

Procedure OnWriteGlobalDataProcessor(Cancel)
	If Cancel Or Not AdditionalProperties.Property("RelevantCommands") Then
		Return;
	EndIf;
	
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	For Each KeyAndValue In AdditionalProperties.JobsToUpdate Do
		Command = KeyAndValue.Key;
		Job = KeyAndValue.Value;
		
		Changes = New Structure;
		Changes.Insert("Use", False);
		Changes.Insert("Schedule", Undefined);
		Changes.Insert("Description", Left(JobPresentation(Command), 120));
		
		If PublicationEnabled AND Command.ScheduledJobSchedule.Count() > 0 Then
			Changes.Schedule    = Command.ScheduledJobSchedule[0].Value;
			Changes.Use = Command.ScheduledJobUsage
				AND AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Changes.Schedule);
		EndIf;
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(Ref);
		ProcedureParameters.Add(Command.ID);
		
		Changes.Insert("Parameters", ProcedureParameters);
		
		SaaSIntegration.BeforeUpdateJob(ThisObject, Command, Job, Changes);
		If Changes <> Undefined Then
			ScheduledJobsServer.ChangeJob(Job, Changes);
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operations with scheduled jobs.

Function ScheduleSetupRight()
	// Checks whether a user has rights to schedule the execution of additional reports and data processors.
	Return AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors);
EndFunction

Function JobPresentation(Command)
	// '[ObjectKind]: [ObjectDescription] / Command: [CommandPresentation]'
	Return (
		TrimAll(Kind)
		+ ": "
		+ TrimAll(Description)
		+ " / "
		+ NStr("ru = 'Команда'; en = 'Command'; pl = 'Polecenie';de = 'Befehl';ro = 'Comandă';tr = 'Komut'; es_ES = 'Comando'")
		+ ": "
		+ TrimAll(Command.Presentation));
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Assignable data processors.

Procedure BeforeWriteAssignableDataProcessor(Cancel)
	AssignmentTable = Purpose.Unload();
	AssignmentTable.GroupBy("RelatedObject");
	Purpose.Load(AssignmentTable);
	
	MetadataObjectsRefs = AssignmentTable.UnloadColumn("RelatedObject");
	
	If NOT IsNew() Then
		For Each TableRow In Ref.Purpose Do
			If MetadataObjectsRefs.Find(TableRow.RelatedObject) = Undefined Then
				MetadataObjectsRefs.Add(TableRow.RelatedObject);
			EndIf;
		EndDo;
	EndIf;
	
	AdditionalProperties.Insert("MetadataObjectsRefs", MetadataObjectsRefs);
EndProcedure

Procedure OnWriteAssignableDataProcessors(Cancel)
	If Cancel OR NOT AdditionalProperties.Property("MetadataObjectsRefs") Then
		Return;
	EndIf;
	
	InformationRegisters.AdditionalDataProcessorsPurposes.UpdateDataByMetadataObjectsRefs(AdditionalProperties.MetadataObjectsRefs);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Global reports

Procedure OnWriteReport(Cancel)
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		
		Try
			If IsNew() Then
				ExternalObject = ExternalReports.Create(ObjectName);
			Else
				ExternalObject = AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
			EndIf;
		Except
			ErrorText = NStr("ru = 'Ошибка подключения:'; en = 'Attachment error:'; pl = 'Błąd połączenia:';de = 'Verbindungsfehler';ro = 'Eroare de conexiune:';tr = 'Bağlantı hatası:'; es_ES = 'Error de conexión:'") + Chars.LF + DetailErrorDescription(ErrorInfo());
			AdditionalReportsAndDataProcessors.WriteError(Ref, ErrorText);
			AdditionalProperties.Insert("ConnectionError", ErrorText);
			ExternalObject = Undefined;
		EndTry;
		
		AdditionalProperties.Insert("Global", IsGlobalDataProcessor());
		
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		ModuleReportsOptions.OnWriteAdditionalReport(ThisObject, Cancel, ExternalObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf