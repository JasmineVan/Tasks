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
	
	If NOT Users.IsFullUser(, True) Then
		Raise NStr("ru = 'Недостаточно прав доступа.
		                             |
		                             |Изменение свойств регламентного задания
		                             |выполняется только администраторами.'; 
		                             |en = 'Insufficient access rights.
		                             |
		                             |Only administrators can change
		                             | properties of a scheduled job.'; 
		                             |pl = 'Niewystarczające uprawnienia dostępu.
		                             |
		                             |Zmiana właściwości zaplanowanego zadania
		                             |jest wykonywana tylko przez administratorów.';
		                             |de = 'Unzureichende Zugriffsrechte.
		                             |
		                             |Ändern der Eigenschaften eines
		                             |geplanten Jobs wird nur von Administratoren ausgeführt.';
		                             |ro = 'Drepturi de acces insuficiente.
		                             |
		                             |Modificarea proprietăților sarcinii reglementare
		                             |este executată numai de administratori.';
		                             |tr = 'Yetersiz erişim hakları.
		                             |
		                             | Zamanlanmış 
		                             |işin özellikleri yalnızca yöneticiler tarafından değiştirilir.'; 
		                             |es_ES = 'Insuficientes derechos de acceso.
		                             |
		                             |Cambio de propiedades de la
		                             |tarea programada se ha ejecutado solo por administradores.'");
	EndIf;
	
	Action = Parameters.Action;
	
	If StrFind(", Add, Copy, Change,", ", " + Action + ",") = 0 Then
		
		Raise NStr("ru = 'Неверные параметры открытия формы ""Регламентное задание"".'; en = 'Incorrect opening parameters of the ""Scheduled job"" form.'; pl = 'Niepoprawne parametry otwierania formularza ""Zaplanowane zlecenie"".';de = 'Falsche Parameter beim Öffnen des Formulars ""Geplanter Job"".';ro = 'Parametri incorecți de deschidere a formei ""Sarcina reglementară"".';tr = '""Zamanlanmış iş"" açılış formun yanlış parametreleri.'; es_ES = 'Parámetros incorrectos de la apertura del formulario ""Tarea programada"".'");
	EndIf;
	
	If Action = "Add" Then
		
		FilterParameters        = New Structure;
		ParameterizedJobs = New Array;
		JobDependencies     = ScheduledJobsInternal.ScheduledJobsDependentOnFunctionalOptions();
		
		FilterParameters.Insert("IsParameterized", True);
		SearchResult = JobDependencies.FindRows(FilterParameters);
		
		For Each TableRow In SearchResult Do
			ParameterizedJobs.Add(TableRow.ScheduledJob);
		EndDo;
		
		Schedule = New JobSchedule;
		
		For Each ScheduledJobMetadata In Metadata.ScheduledJobs Do
			If ParameterizedJobs.Find(ScheduledJobMetadata) <> Undefined Then
				Continue;
			EndIf;
			
			ScheduledJobMetadataDetailsCollection.Add(
				ScheduledJobMetadata.Name
					+ Chars.LF
					+ ScheduledJobMetadata.Synonym
					+ Chars.LF
					+ ScheduledJobMetadata.MethodName,
				?(IsBlankString(ScheduledJobMetadata.Synonym),
				  ScheduledJobMetadata.Name,
				  ScheduledJobMetadata.Synonym) );
		EndDo;
	Else
		Job = ScheduledJobsServer.GetScheduledJob(Parameters.ID);
		FillPropertyValues(
			ThisObject,
			Job,
			"Key,
			|Predefined,
			|Use,
			|Description,
			|UserName,
			|RestartIntervalOnFailure,
			|RestartCountOnFailure");
		
		ID = String(Job.UUID);
		If Job.Metadata = Undefined Then
			MetadataName        = NStr("ru = '<нет метаданных>'; en = '<no metadata>'; pl = '<nie ma metadanych>';de = '<Keine Metadaten>';ro = '<nu sunt metadate>';tr = '<metaveri yok>'; es_ES = '<no hay metadatos>'");
			MetadataSynonym    = NStr("ru = '<нет метаданных>'; en = '<no metadata>'; pl = '<nie ma metadanych>';de = '<Keine Metadaten>';ro = '<nu sunt metadate>';tr = '<metaveri yok>'; es_ES = '<no hay metadatos>'");
			MetadataMethodName  = NStr("ru = '<нет метаданных>'; en = '<no metadata>'; pl = '<nie ma metadanych>';de = '<Keine Metadaten>';ro = '<nu sunt metadate>';tr = '<metaveri yok>'; es_ES = '<no hay metadatos>'");
		Else
			MetadataName        = Job.Metadata.Name;
			MetadataSynonym    = Job.Metadata.Synonym;
			MetadataMethodName  = Job.Metadata.MethodName;
		EndIf;
		Schedule = Job.Schedule;
		
		UserMessagesAndErrorDescription = ScheduledJobsInternal
			.ScheduledJobMessagesAndErrorDescriptions(Job);
	EndIf;
	
	If Action <> "Change" Then
		ID = NStr("ru = '<будет создан при записи>'; en = '<will be created when writing>'; pl = '<będzie stworzony przy zapisie>';de = '<wird beim Schreiben erstellt>';ro = '<va fi creat atunci când scrieți>';tr = '<yazarken oluşturulacak>'; es_ES = '<se creará al grabar>'");
		Use = False;
		
		Description = ?(
			Action = "Add",
			"",
			ScheduledJobsInternal.ScheduledJobPresentation(Job));
	EndIf;
	
	// Filling the user name selection list.
	UsersArray = InfoBaseUsers.GetUsers();
	
	For each User In UsersArray Do
		Items.UserName.ChoiceList.Add(User.Name);
	EndDo;
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	If Action = "Add" Then
		AttachIdleHandler("SelectNewScheduledJobTemplate", 0.1, True);
	Else
		RefreshFormTitle();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	RefreshFormTitle();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Write(Command)
	
	WriteScheduledJob();
	
EndProcedure

&AtClient
Procedure WriteAndCloseComplete()
	
	WriteAndCloseCompletion();
	
EndProcedure

&AtClient
Procedure SetScheduleExecute()

	Dialog = New ScheduledJobDialog(Schedule);
	Dialog.Show(New NotifyDescription("OpenScheduleEnd", ThisObject));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseCompletion(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteScheduledJob();
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure SelectNewScheduledJobTemplate()
	
	// Scheduled job template selection (metadata).
	ScheduledJobMetadataDetailsCollection.ShowChooseItem(
		New NotifyDescription("SelectNewScheduledJobTemplateCompletion", ThisObject),
		NStr("ru = 'Выберите шаблон регламентного задания'; en = 'Select a scheduled job template'; pl = 'Wybierz szablon zaplanowanego zadania.';de = 'Wählen Sie eine geplante Jobvorlage aus';ro = 'Selectați șablonul sarcinii reglementare';tr = 'Zamanlanmış bir iş şablonu seçin'; es_ES = 'Seleccinar un modelo de la tarea programada'"));
	
EndProcedure

&AtClient
Procedure SelectNewScheduledJobTemplateCompletion(ListItem, Context) Export
	
	If ListItem = Undefined Then
		Close();
		Return;
	EndIf;
	
	MetadataName       = StrGetLine(ListItem.Value, 1);
	MetadataSynonym   = StrGetLine(ListItem.Value, 2);
	MetadataMethodName = StrGetLine(ListItem.Value, 3);
	Description        = ListItem.Presentation;
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure OpenScheduleEnd(NewSchedule, Context) Export

	If NewSchedule <> Undefined Then
		Schedule = NewSchedule;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteScheduledJob()
	
	If NOT ValueIsFilled(MetadataName) Then
		Return;
	EndIf;
	
	CurrentID = ?(Action = "Change", ID, Undefined);
	
	WriteScheduledJobAtServer();
	RefreshFormTitle();
	
	Notify("Write_ScheduledJobs", CurrentID);
	
EndProcedure

&AtServer
Procedure WriteScheduledJobAtServer()
	
	If Action = "Change" Then
		Job = ScheduledJobsServer.GetScheduledJob(ID);
	Else
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs[MetadataName]);
		
		Job = ScheduledJobsServer.AddJob(JobParameters);
		
		ID = String(Job.UUID);
		Action = "Change";
	EndIf;
	
	FillPropertyValues(
		Job,
		ThisObject,
		"Key, 
		|Description,
		|Use,
		|UserName,
		|RestartIntervalOnFailure,
		|RestartCountOnFailure");
	
	Job.Schedule = Schedule;
	Job.Write();
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure RefreshFormTitle()
	
	If NOT IsBlankString(Description) Then
		Presentation = Description;
		
	ElsIf NOT IsBlankString(MetadataSynonym) Then
		Presentation = MetadataSynonym;
	Else
		Presentation = MetadataName;
	EndIf;
	
	If Action = "Change" Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (Регламентное задание)'; en = '%1 (Scheduled job)'; pl = '%1(Zaplanowane zadanie)';de = '%1 (Geplanter Job)';ro = '%1 (Program de lucru)';tr = '%1 (Zamanlanmış iş)'; es_ES = '%1 (Tarea programada)'"), Presentation);
	Else
		Title = NStr("ru = 'Регламентное задание (создание)'; en = 'Scheduled job (creation)'; pl = 'Zaplanowane zadanie (tworzenie)';de = 'Geplanter Job (Erstellung)';ro = 'Program de lucru (creare)';tr = 'Zamanlanmış iş (oluşturma)'; es_ES = 'Tarea programada (creación)'");
	EndIf;
	
EndProcedure

#EndRegion
