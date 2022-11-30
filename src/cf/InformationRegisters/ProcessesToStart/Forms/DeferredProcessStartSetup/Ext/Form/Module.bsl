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
	
	If Not ValueIsFilled(Parameters.BusinessProcess) Then
		Cancel = True;
	EndIf;
	
	BusinessProcess = Parameters.BusinessProcess;
	DueDate = Parameters.DueDate;
	
	// Filling settings.
	FillFormAttributes();
	// Specifying setting availability.
	SetFormItemsProperties();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshIntervalRepresentation();
	UpdateTimeSelectionList();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeferredProcessStartOnChange(Item)
	
	SetDeferredProcessStartState();
	
EndProcedure

&AtClient
Procedure DeferredStartDateOnChange(Item)
	
	OnChangeDateTime();
	
EndProcedure

&AtClient
Procedure DeferredStartDateTimeOnChange(Item)
	
	OnChangeDateTime();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Finish(Command)
	
	If FormIsFilledInCorrectly() Then
		WriteSettingsOnClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnChangeDateTime()

	RefreshIntervalRepresentation();
	UpdateTimeSelectionList();

EndProcedure

// Writes settings.
//
&AtClient
Procedure WriteSettingsOnClient()
	
	SaveSettings();
	Close();
	
	DeferredStartSettings = New Structure;
	DeferredStartSettings.Insert("BusinessProcess", BusinessProcess);
	DeferredStartSettings.Insert("Deferred", PostponedProcessStart);
	DeferredStartSettings.Insert("DeferredStartDate", DeferredStartDate);
	DeferredStartSettings.Insert("State", State);
	
	Notify("DeferredStartSettingsChanged", DeferredStartSettings);
	
	If PostponedProcessStart <> DeferredProcessStartOnOpen Then 
		
		NotificationText = ?(PostponedProcessStart, NStr("ru = 'Отложенный старт:'; en = 'Deferred start:'; pl = 'Deferred start:';de = 'Deferred start:';ro = 'Deferred start:';tr = 'Deferred start:'; es_ES = 'Deferred start:'"), NStr("ru = 'Отложенный старт отменен:'; en = 'Deferred start canceled:'; pl = 'Deferred start canceled:';de = 'Deferred start canceled:';ro = 'Deferred start canceled:';tr = 'Deferred start canceled:'; es_ES = 'Deferred start canceled:'"));
		ProcessURL = GetURL(BusinessProcess);
		
		ShowUserNotification(
			NotificationText,
			ProcessURL,
			BusinessProcess,
			PictureLib.Information32);
			
		NotifyChanged(BusinessProcess);
		NotifyChanged(Type("InformationRegisterRecordKey.BusinessProcessesData"));
			
	EndIf;
	
EndProcedure

// Fills in the State form attribute and sets availability of the DeferredStartDate and 
// DeferredStartDateTime fields.
//
&AtServer
Procedure SetDeferredProcessStartState()
	
	If PostponedProcessStart Then
		State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart");
	Else
		State = PredefinedValue("Enum.ProcessesStatesForStart.EmptyRef");
	EndIf;
	
	SetFormItemsProperties();
	
EndProcedure

// Saves deferred start settings in the register.
//
&AtServer
Procedure SaveSettings()
	
	If PostponedProcessStart Then
		BusinessProcessesAndTasksServer.AddProcessForDeferredStart(BusinessProcess, DeferredStartDate);
	Else
		BusinessProcessesAndTasksServer.DisableProcessDeferredStart(BusinessProcess);
	EndIf;
	
EndProcedure

// Fills in the DecorationInterval decoration title.
//
&AtClient
Procedure RefreshIntervalRepresentation()
	
	If NOT ValueIsFilled(DeferredStartDate)
		OR ProcessIsStarted Then
		
		Items.IntervalDecoration.Title = "";
		Return;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"IntervalDecoration",
		"Title",
		IntevalText(CurrentServerDate, DeferredStartDate));
			
EndProcedure

// Fills in the selection list for the DeferredStartDateTime form item with time values.
// 
//
&AtClient
Procedure UpdateTimeSelectionList()
	
	Items.DeferredStartDateTime.ChoiceList.Clear();
	
	BlankDate = BegOfDay(DeferredStartDate);
	
	For Ind = 1 To 48 Do
		Items.DeferredStartDateTime.ChoiceList.Add(BlankDate, Format(BlankDate, "DF=HH:mm"));
		BlankDate = BlankDate + 1800;
	EndDo;
	
EndProcedure

&AtClient
Function IntevalText(StartDate, EndDate)

	If StartDate > EndDate Then
		Return NStr("ru = 'Дата запуска задания находится в прошлом.'; en = 'Job start date is in the past.'; pl = 'Job start date is in the past.';de = 'Job start date is in the past.';ro = 'Job start date is in the past.';tr = 'Job start date is in the past.'; es_ES = 'Job start date is in the past.'");
	EndIf;	
	
	If UseDateAndTimeInTaskDeadlines Then
		NumberOfHours = Round((EndDate - StartDate) / (60*60));
		NumberOfDays = Round(NumberOfHours / 24);
		NumberOfHours = NumberOfHours - NumberOfDays * 24;
	Else
		NumberOfHours = 0;
		NumberOfDays = (BegOfDay(EndDate) - BegOfDay(StartDate)) / (60*60*24);
	EndIf;
		
	If NumberOfHours < 0 Then
		NumberOfDays = NumberOfDays - 1;
		NumberOfHours = NumberOfHours + 24;
	EndIf;
	
	DateDiff = "";
	Prefix = NStr("ru = 'Задание будет запущено'; en = 'Job will be started'; pl = 'Job will be started';de = 'Job will be started';ro = 'Job will be started';tr = 'Job will be started'; es_ES = 'Job will be started'") + " ";
	Root = NStr("ru = 'через'; en = 'in'; pl = 'in';de = 'in';ro = 'in';tr = 'in'; es_ES = 'in'") + " ";
	If UseDateAndTimeInTaskDeadlines Then
		If NumberOfDays > 0 AND NumberOfHours > 0 Then
			DateDiff = Root + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 дн. и %2 ч.'; en = '%1 days and %2 hours'; pl = '%1 days and %2 hours';de = '%1 days and %2 hours';ro = '%1 days and %2 hours';tr = '%1 days and %2 hours'; es_ES = '%1 days and %2 hours'"),
				String(NumberOfDays),
				String(NumberOfHours));
		ElsIf NumberOfDays > 0 Then
			DateDiff = Root + StringFunctionsClientServer.SubstituteParametersToString("%1 days.", String(NumberOfDays));
		ElsIf NumberOfHours > 0 Then
			DateDiff = Root + StringFunctionsClientServer.SubstituteParametersToString("%1 h.", String(NumberOfHours));
		Else
			DateDiff = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'менее чем через час.'; en = 'less than in an hour.'; pl = 'less than in an hour.';de = 'less than in an hour.';ro = 'less than in an hour.';tr = 'less than in an hour.'; es_ES = 'less than in an hour.'"), String(NumberOfHours));
		EndIf;
	Else
		If NumberOfDays > 0 Then
			DateDiff = Root + StringFunctionsClientServer.SubstituteParametersToString("%1 days.", String(NumberOfDays));
		Else
			DateDiff = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'менее чем через день.'; en = 'less than in a day.'; pl = 'less than in a day.';de = 'less than in a day.';ro = 'less than in a day.';tr = 'less than in a day.'; es_ES = 'less than in a day.'"), String(NumberOfDays));
		EndIf;
	EndIf;
	
	Return Prefix + DateDiff;
	
EndFunction

&AtServer
Procedure FillFormAttributes()
	
	ProcessAttributes = Common.ObjectAttributesValues(
		Parameters.BusinessProcess, "Started, Completed");
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	CurrentServerDate = CurrentSessionDate();
	
	ProcessIsStarted = ProcessAttributes.Started;
	ProcessCompleted = ProcessAttributes.Completed;
	
	Setting = BusinessProcessesAndTasksServer.DeferredProcessParameters(Parameters.BusinessProcess);
	
	If ValueIsFilled(Setting) Then
		// If the process is already deferred, filling the attributes for it.
		FillPropertyValues(ThisObject, Setting);
		
		PostponedProcessStart = (Setting.State = Enums.ProcessesStatesForStart.ReadyToStart);
		DeferredProcessStartOnOpen = PostponedProcessStart;
		
	ElsIf NOT ProcessIsStarted Then
		// If it is not deferred, filling with default values.
		DeferredProcessStartOnOpen = False;
		PostponedProcessStart = True;
		DeferredStartDate = BegOfDay(CurrentSessionDate() + 86400);
		State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsProperties()
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"PostponedProcessStart",
		"ReadOnly",
		ProcessIsStarted);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupInfoLabel",
		"Visible",
		ProcessIsStarted);
		
	If ProcessIsStarted Then
		Items.CommandsPages.CurrentPage = Items.ProcessIsStartedPage;
		CommonClientServer.SetFormItemProperty(Items, "Close", "DefaultButton", True);

		If ProcessCompleted Then
			Items.FooterPages.CurrentPage = Items.JobIsCompletedPage;
		Else
			Items.FooterPages.CurrentPage = Items.JobStartedPage;
		EndIf;
	Else
		Items.CommandsPages.CurrentPage = Items.ProcessIsNotStartedPage;
		CommonClientServer.SetFormItemProperty(Items, "Finish", "DefaultButton", True);
		
		If State = PredefinedValue("Enum.ProcessesStatesForStart.StartCanceled") Then
			Items.FooterPages.CurrentPage = Items.CancelStartPage;
		Else
			Items.FooterPages.CurrentPage = Items.EmptyPage;
		EndIf;
	EndIf;
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"DeferredStartDate",
		"ReadOnly",
		ProcessIsStarted OR NOT PostponedProcessStart);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"DeferredStartDateTime",
		"Visible",
		UseDateAndTimeInTaskDeadlines);
	CommonClientServer.SetFormItemProperty(
		Items,
		"DeferredStartDateTime",
		"ReadOnly",
		ProcessIsStarted OR NOT PostponedProcessStart);
		
EndProcedure

&AtClient
Function FormIsFilledInCorrectly()
	
	FilledInCorrectly = True;
	ClearMessages();
	
	If PostponedProcessStart AND DeferredStartDate < CurrentServerDate Then
		CommonClient.MessageToUser(NStr("ru = 'Дата и время отложенного старта должны быть больше текущей даты.'; en = 'Date and time of the deferred start must be greater than the current date.'; pl = 'Date and time of the deferred start must be greater than the current date.';de = 'Date and time of the deferred start must be greater than the current date.';ro = 'Date and time of the deferred start must be greater than the current date.';tr = 'Date and time of the deferred start must be greater than the current date.'; es_ES = 'Date and time of the deferred start must be greater than the current date.'"),,
			"DeferredStartDate");
		FilledInCorrectly = False;
	EndIf;
		
	If PostponedProcessStart AND DeferredStartDate > DueDate Then
		CommonClient.MessageToUser(NStr("ru = 'Дата и время отложенного старта должны быть меньше срока исполнения задания.'; en = 'Date and time of the deferred start must be less than the job due date.'; pl = 'Date and time of the deferred start must be less than the job due date.';de = 'Date and time of the deferred start must be less than the job due date.';ro = 'Date and time of the deferred start must be less than the job due date.';tr = 'Date and time of the deferred start must be less than the job due date.'; es_ES = 'Date and time of the deferred start must be less than the job due date.'"),,
			"DeferredStartDate");
		FilledInCorrectly = False;
	EndIf;
	
	Return FilledInCorrectly;
	
EndFunction

#EndRegion

