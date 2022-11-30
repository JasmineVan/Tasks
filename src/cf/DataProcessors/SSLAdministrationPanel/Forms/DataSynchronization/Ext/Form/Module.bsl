///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	SubsystemExistsDataExchange         = Common.SubsystemExists("StandardSubsystems.DataExchange");
	SubsystemExistsPeriodClosingDates = Common.SubsystemExists("StandardSubsystems.PeriodClosingDates");
	
	SetVisibility();
	SetAvailability();
	
	ApplicationSettingsOverridable.DataSynchronizationOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NotificationsHandler(EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseDataSynchronizationOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

&AtClient
Procedure DistributedInfobaseNodePrefixOnChange(Item)
	
	BackgroundJob = StartIBPrefixChangeInBackgroundJob();
	
	If BackgroundJob <> Undefined
		AND BackgroundJob.Status = "Running" Then
		
		Items.DistributedInfobaseNodePrefix.Enabled = False;
		Items.WaitForPrefixChangeDecoration.Visible = True;
		
	EndIf;
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;;
	
	Handler = New NotifyDescription("AfterChangePrefix", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function StartIBPrefixChangeInBackgroundJob()
	
	ProcedureParameters = New Structure("NewIBPrefix, ContinueNumbering",
		ConstantsSet.DistributedInfobaseNodePrefix, True);
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Изменение префикса'; en = 'Change prefix'; pl = 'Zmiana prefiksu';de = 'Präfix ändern';ro = 'Modificarea prefixului';tr = 'Önek değişikliği'; es_ES = 'Cambiar el prefijo'");
	ExecutionParameters.WaitForCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground("ObjectsPrefixesInternal.ChangeIBPrefix", ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure AfterChangePrefix(BackgroundJob, AdditionalParameters) Export

	If Not Items.DistributedInfobaseNodePrefix.Enabled Then
		Items.DistributedInfobaseNodePrefix.Enabled = True;
	EndIf;
	If Items.WaitForPrefixChangeDecoration.Visible Then
		Items.WaitForPrefixChangeDecoration.Visible = False;
	EndIf;
	
	If BackgroundJob <> Undefined
		AND BackgroundJob.Status = "Completed" Then
		
		ShowUserNotification(NStr("ru = 'Префикс изменен.'; en = 'The prefix is changed.'; pl = 'Prefiks został zmieniony.';de = 'Präfix geändert.';ro = 'Prefixul este modificat.';tr = 'Önek değiştirildi.'; es_ES = 'Prefijo cambiado.'"));
		
	Else
		
		ConstantsSet.DistributedInfobaseNodePrefix = PrefixReadFromInfobase();
		Items.DistributedInfobaseNodePrefix.UpdateEditText();
		
		If BackgroundJob <> Undefined Then
			ErrorText = NStr("ru='Не удалось изменить префикс.
				|См. подробности в журнале регистрации.'; 
				|en = 'Cannot change the prefix.
				|For details, see the event log.'; 
				|pl = 'Nie udało się zmienić prefiks.
				|Szczegóły w dzienniku rejestracji.';
				|de = 'Das Präfix konnte nicht geändert werden.
				|Siehe das Ereignisprotokoll für Details.';
				|ro = 'Eșec la modificarea prefixului.
				|Detalii vezi în registrul logare.';
				|tr = 'Önek değiştirilemedi. 
				|Ayrıntılar için kayıt günlüğüne bakın.'; 
				|es_ES = 'No se ha podido cambiar el prefijo.
				|Véase más en el registro.'");
			CommonClient.MessageToUser(ErrorText);
		EndIf;
		
	EndIf;

EndProcedure

&AtServerNoContext
Function PrefixReadFromInfobase()
	
	Return Constants.DistributedInfobaseNodePrefix.Get();
	
EndFunction

&AtClient
Procedure DataExchangeMessagesDirectoryForWindowsOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

&AtClient
Procedure DataExchangeMessagesDirectoryForLinuxOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ConfigureImportRestrictionDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenDataImportRestrictionDates(ThisObject);
	EndIf;
	
EndProcedure

// Processing notifications from other open forms.
//
// Parameters:
//   EventName - String - an event name. It can be used for forms to identify messages they accept.
//   Parameter - Arbitrary - a message parameter. You can pass any data.
//   Source - Arbitrary - an event source. For example, another form can be specified as a source.
//
// Example:
//   If EventName = "ConstantsSet.DistributedInfobaseNodePrefix" Then
//     ConstantsSet.DistributedInfobaseNodePrefix = Parameter;
//   EndIf;
//
&AtClient
Procedure NotificationsHandler(EventName, Parameter, Source)
	
	
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshSecurityProfilesPermissions(Item)
	
	ClosingNotification = New NotifyDescription("RefreshSecurityProfilesPermissionsCompletion", ThisObject, Item);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		QueriesArray = CreateRequestToUseExternalResources(Item.Name);
		
		If QueriesArray = Undefined Then
			Return;
		EndIf;
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			QueriesArray, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources(ConstantName)
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() = ConstantValue Then
		Return Undefined;
	EndIf;
	
	If ConstantName = "UseDataSynchronization" Then
		
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		If ConstantValue Then
			Query = ModuleDataExchangeServer.RequestToUseExternalResourcesOnEnableExchange();
		Else
			Query = ModuleDataExchangeServer.RequestToClearPermissionsToUseExternalResources();
		EndIf;
		Return Query;
		
	Else
		
		ValueManager = ConstantManager.CreateValueManager();
		ConstantID = Common.MetadataObjectID(ValueManager.Metadata());
		
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		If IsBlankString(ConstantValue) Then
			
			Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(ConstantID);
			
		Else
			
			Permissions = CommonClientServer.ValueInArray(
				ModuleSafeModeManager.PermissionToUseFileSystemDirectory(ConstantValue, True, True));
			Query = ModuleSafeModeManager.RequestToUseExternalResources(Permissions, ConstantID);
			
		EndIf;
		
		Return CommonClientServer.ValueInArray(Query);
		
	EndIf;
	
EndFunction

&AtClient
Procedure RefreshSecurityProfilesPermissionsCompletion(Result, Item) Export
	
	If Result = DialogReturnCode.OK Then
	
		Attachable_OnChangeAttribute(Item);
		
	Else
		
		ThisObject.Read();
	
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetVisibility()
	
	If DataSeparationEnabled Then
		Items.SectionDetails.Title = NStr("ru = 'Синхронизация данных с моими приложениями.'; en = 'Synchronize data with my applications.'; pl = 'Synchronizacja danych z moimi aplikacjami.';de = 'Synchronisation von Daten mit meinen Anwendungen.';ro = 'Sincronizarea datelor cu aplicațiile mele.';tr = 'Uygulamalarım ile veri senkronizasyonu'; es_ES = 'Sincronización de datos con mis aplicaciones.'");
	EndIf;
	
	If SubsystemExistsDataExchange Then
		AvailableVersionsArray = New Map;
		ModuleDataExchangeOverridable = Common.CommonModule("DataExchangeOverridable");
		ModuleDataExchangeOverridable.OnGetAvailableFormatVersions(AvailableVersionsArray);
		
		Items.EnterpriseDataLoadingGroup.Visible = ?(AvailableVersionsArray.Count() = 0, False, True);
		
		Items.DistributedInfobaseNodePrefixGroup.ExtendedTooltip.Title =
			Metadata.Constants.DistributedInfobaseNodePrefix.Tooltip;
			
		If DataSeparationEnabled Then
			Items.UseDataSynchronizationGroup.Visible   = False;
			Items.TemporaryServerClusterDirectoriesGroup.Visible = False;
			
			Items.DistributedInfobaseNodePrefix.Title = NStr("ru = 'Префикс в этой программе'; en = 'Prefix in this application'; pl = 'Prefiks w tym programie';de = 'Das Präfix in diesem Programm';ro = 'Prefixul în acest program';tr = 'Bu uygulamadaki önek'; es_ES = 'Prefijo en este programa'");
		Else
			Items.TemporaryServerClusterDirectoriesGroup.Visible = Not Common.FileInfobase()
				AND Users.IsFullUser(, True);
		EndIf;
	Else
		Items.DataSynchronizationGroup.Visible = False;
		Items.DistributedInfobaseNodePrefixGroup.Visible = False;
		Items.DataSynchronizationMoreGroup.Visible  = False;
		Items.TemporaryServerClusterDirectoriesGroup.Visible = False;
	EndIf;
	
	If SubsystemExistsPeriodClosingDates Then
		ModulePeriodClosingDatesInternal = Common.CommonModule("PeriodClosingDatesInternal");
		SectionsProperties = ModulePeriodClosingDatesInternal.SectionsProperties();
		
		Items.ImportRestrictionDatesGroup.Visible = SectionsProperties.ImportRestrictionDatesImplemented;
		
		If DataSeparationEnabled
			AND SectionsProperties.ImportRestrictionDatesImplemented Then
			Items.UseImportForbidDates.ExtendedTooltip.Title =
				NStr("ru = 'Запрет загрузки данных прошлых периодов из других приложений.
				           |Не влияет на загрузку данных из автономных рабочих мест.'; 
				           |en = 'Deny importing data of closed periods from other applications.
				           |This has no effect on importing data from standalone workstations.'; 
				           |pl = 'Zapobiegaj wczytywaniu danych ubiegłych okresów z innych aplikacji.
				           |Nie wpływa to na ładowanie danych z offline stacji roboczych.';
				           |de = 'Das Herunterladen historischer Daten aus anderen Anwendungen ist untersagt.
				           |Beeinflusst nicht den Download von Daten von Einzelarbeitsplätzen.';
				           |ro = 'Interdicția de încărcare a perioadelor precedente din alte aplicații.
				           |Nu influențează încărcarea datelor din locurile de lucru autonome.';
				           |tr = 'Diğer uygulamalardan geçmiş dönemlerin veri indirme yasağı.
				           |Çevrimdışı işlerden veri yüklemeyi etkilemez.'; 
				           |es_ES = 'La prohibición de la carga de datos de los períodos anteriores de otras aplicaciones.
				           |No influye en la carga de datos de los lugares de trabajo autónomos.'");
		EndIf;
	Else
		Items.ImportRestrictionDatesGroup.Visible = False;
	EndIf;
	
	Items.WaitForPrefixChangeDecoration.Visible = False;
	
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseImportForbidDates"
			Or DataPathAttribute = "")
		AND SubsystemExistsPeriodClosingDates Then
		
		Items.ConfigureImportRestrictionDates.Enabled = ConstantsSet.UseImportForbidDates;
			
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseDataSynchronization"
			Or DataPathAttribute = "")
		AND SubsystemExistsDataExchange Then
		
		Items.DataSyncSettings.Enabled            = ConstantsSet.UseDataSynchronization;
		Items.ImportRestrictionDatesGroup.Enabled               = ConstantsSet.UseDataSynchronization;
		Items.DataSynchronizationResults.Enabled           = ConstantsSet.UseDataSynchronization;
		Items.TemporaryServerClusterDirectoriesGroup.Enabled = ConstantsSet.UseDataSynchronization;
		
	EndIf;
	
EndProcedure

#EndRegion
