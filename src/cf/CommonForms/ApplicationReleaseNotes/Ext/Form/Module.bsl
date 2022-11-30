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
	
	SubsystemSettings  = InfobaseUpdateInternal.SubsystemSettings();
	FormAddressInApplication = SubsystemSettings.ApplicationChangeHistoryLocation;
	
	If ValueIsFilled(FormAddressInApplication) Then
		Items.FormAddressInApplication.Title = FormAddressInApplication;
	EndIf;
	
	If Not Parameters.ShowOnlyChanges Then
		Items.FormAddressInApplication.Visible = False;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Что нового в конфигурации %1'; en = 'What''s new in %1'; pl = 'Co nowego w %1';de = 'Was ist neu in der Konfiguration %1';ro = 'Ce este nou în configurație %1';tr = 'Yapılandırmadaki yenilikler%1'; es_ES = 'Qué hay de nuevo en la configuración %1'"), Metadata.Synonym);
	
	If ValueIsFilled(Parameters.UpdateStartTime) Then
		UpdateStartTime = Parameters.UpdateStartTime;
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
	Sections = InfobaseUpdateInternal.NotShownUpdateDetailSections();
	LatestVersion = InfobaseUpdateInternal.SystemChangesDisplayLastVersion();
	
	If Sections.Count() = 0 Then
		DocumentUpdateDetails = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
		If DocumentUpdateDetails <> Undefined
			AND (LatestVersion = Undefined
				Or Not Parameters.ShowOnlyChanges) Then
			AllSections = InfobaseUpdateInternal.UpdateDetailsSections();
			If TypeOf(AllSections) = Type("ValueList")
				AND AllSections.Count() <> 0 Then
				For Each Item In AllSections Do
					Sections.Add(Item.Presentation);
				EndDo;
				DocumentUpdateDetails = InfobaseUpdateInternal.DocumentUpdateDetails(Sections);
			Else
				DocumentUpdateDetails = GetCommonTemplate(DocumentUpdateDetails);
			EndIf;
		Else
			DocumentUpdateDetails = New SpreadsheetDocument();
		EndIf;
	Else
		DocumentUpdateDetails = InfobaseUpdateInternal.DocumentUpdateDetails(Sections);
	EndIf;
	
	If DocumentUpdateDetails.TableHeight = 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Конфигурация успешно обновлена на версию %1'; en = 'The application is updated to version %1.'; pl = 'Konfiguracja została pomyślnie zaktualizowana do wersji %1';de = 'Die Anwendungsversion wurde erfolgreich auf Version %1 aktualisiert';ro = 'Versiunea aplicației a fost actualizată cu succes cu versiunea %1';tr = 'Uygulama %1 sürümüne başarıyla güncellendi'; es_ES = 'La versión de la aplicación se ha actualizado con éxito para la versión %1'"), Metadata.Version);
		DocumentUpdateDetails.Area("R1C1:R1C1").Text = Text;
	EndIf;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If NOT ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnPrepareUpdateDetailsTemplate(DocumentUpdateDetails);
	EndDo;
	InfobaseUpdateOverridable.OnPrepareUpdateDetailsTemplate(DocumentUpdateDetails);
	
	UpdateDetails.Clear();
	UpdateDetails.Put(DocumentUpdateDetails);
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdateStartTime = UpdateInfo.UpdateStartTime;
	UpdateEndTime = UpdateInfo.UpdateEndTime;
	
	If Not Common.SeparatedDataUsageAvailable()
		Or UpdateInfo.DeferredUpdateCompletedSuccessfully <> Undefined
		Or UpdateInfo.HandlersTree <> Undefined
			AND UpdateInfo.HandlersTree.Rows.Count() = 0 Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
	If Common.FileInfobase() Then
		MessageTitle = NStr("ru = 'Необходимо выполнить дополнительные процедуры обработки данных'; en = 'Additional data processing required'; pl = 'Wykonaj dodatkowe procedury przetwarzania danych';de = 'Führen Sie zusätzliche Datenverarbeitungsverfahren aus';ro = 'Este necesară executarea procedurilor suplimentare de procesare a datelor';tr = 'Ek veri işleme prosedürlerini yürütme'; es_ES = 'Ejecutar los procedimientos del procesamiento de datos adicionales'");
		Items.DeferredDataUpdate.Title = MessageTitle;
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Items.DeferredDataUpdate.Title =
			NStr("ru = 'Не выполнены дополнительные процедуры обработки данных'; en = 'Additional data processing skipped'; pl = 'Dodatkowe procedury przetwarzania danych nie zostały wykonane';de = 'Zusätzliche Datenverarbeitungsprozeduren wurden nicht ausgeführt';ro = 'Procedurile suplimentare de procesare a datelor nu au fost executate';tr = 'Ek veri işleme prosedürleri uygulanmadı'; es_ES = 'Procedimientos del procesamiento de datos adicionales no se han ejecutado'");
	EndIf;
	
	If Not ValueIsFilled(UpdateStartTime) AND Not ValueIsFilled(UpdateEndTime) Then
		Items.TechnicalInformationOnUpdateResult.Visible = False;
	ElsIf Users.IsFullUser() AND Not Common.DataSeparationEnabled() Then
		Items.TechnicalInformationOnUpdateResult.Visible = True;
	Else
		Items.TechnicalInformationOnUpdateResult.Visible = False;
	EndIf;
	
	ClientServerInfobase = Not Common.FileInfobase();
	
	// Displaying the information on disabled scheduled jobs.
	If Not ClientServerInfobase
		AND Users.IsFullUser(, True) Then
		ClientLaunchParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
		ScheduledJobsDisabled = StrFind(ClientLaunchParameter, "ScheduledJobsDisabled") <> 0;
		If Not ScheduledJobsDisabled Then
			Items.ScheduledJobsDisabledGroup.Visible = False;
		EndIf;
	Else
		Items.ScheduledJobsDisabledGroup.Visible = False;
	EndIf;
	
	Items.UpdateDetails.HorizontalScrollBar = ScrollBarUse.DontUse;
	
	InfobaseUpdateInternal.SetShowDetailsToCurrentVersionFlag();
	
	If Common.IsMobileClient() Then
		Items.FormCommandBar.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ClientServerInfobase Then
		AttachIdleHandler("UpdateDeferredUpdateStatus", 60);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdateDetailsChoice(Item, Area, StandardProcessing)
	
	If StrFind(Area.Text, "http://") = 1 Or StrFind(Area.Text, "https://") = 1 Then
		FileSystemClient.OpenURL(Area.Text);
	EndIf;
	
	InfobaseUpdateClientOverridable.OnClickUpdateDetailsDocumentHyperlink(Area);
	
EndProcedure

&AtClient
Procedure ShowUpdateResultInfoClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowErrorsAndWarnings", True);
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DeferredDataUpdate(Command)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredIBUpdateProgressIndicator");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateDeferredUpdateStatus()
	
	UpdateDeferredUpdateStatusAtServer();
	
EndProcedure

&AtServer
Procedure UpdateDeferredUpdateStatusAtServer()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateEndTime <> Undefined Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessingScheduledJobsDisabled(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	Notification = New NotifyDescription("DisabledScheduledJobsURLProcessingCompletion", ThisObject);
	QuestionText = NStr("ru = 'Перезапустить программу?'; en = 'Do you want to restart the application?'; pl = 'Zrestartować aplikację?';de = 'Neustart der Anwendung?';ro = 'Reporniți aplicația?';tr = 'Uygulama yeniden başlatılsın mı?'; es_ES = '¿Reiniciar la aplicación?'");
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure DisabledScheduledJobsURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		NewStartupParameter = StrReplace(LaunchParameter, "ScheduledJobsDisabled", "");
		NewStartupParameter = StrReplace(NewStartupParameter, "StartInfobaseUpdate", "");
		NewStartupParameter = "/C """ + NewStartupParameter + """";
		Terminate(True, NewStartupParameter);
	EndIf;
	
EndProcedure

#EndRegion
