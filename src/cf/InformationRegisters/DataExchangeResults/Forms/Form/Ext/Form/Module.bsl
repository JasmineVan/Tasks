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
	
	SetConditionalAppearance();
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		
		Items.UnpostedDocumentsContextMenu.ChildItems.UnpostedDocumentsContextMenuEditSelectedDocuments.Visible = False;
		Items.UnpostedDocumentsEditSelectedDocuments.Visible = False;
		Items.BlankAttributesContextMenu.ChildItems.BlankAttributesContextMenuEditSelectedObjects.Visible = False;
		Items.BlankAttributesEditSelectedObjects.Visible = False;
		
	EndIf;
	
	PeriodClosingDatesEnabled = 
		Common.SubsystemExists("StandardSubsystems.PeriodClosingDates");
	
	VersioningUsed = DataExchangeCached.VersioningUsed(, True);
	
	If VersioningUsed Then
		
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.InitializeDynamicListOfCorruptedVersions(Conflicts, "Conflicts");
		
		If PeriodClosingDatesEnabled Then
			ModuleObjectsVersioning.InitializeDynamicListOfCorruptedVersions(RejectedDueToDate, "RejectedDueToDate");
		EndIf;
		
	EndIf;
	
	Items.ConflictPage.Visible                = VersioningUsed;
	Items.RejectedByRestrictionDatePage.Visible = VersioningUsed AND PeriodClosingDatesEnabled;
	
	// Setting filters of dynamic lists and saving them in the attribute to manage them.
	SetUpDynamicListFilters(DynamicListsFiltersSettings);
	
	If Common.DataSeparationEnabled() AND VersioningUsed Then
		Items.ConflictsAnotherVersionAuthor.Title = NStr("ru = 'Версия получена из приложения'; en = 'Version is received from the application'; pl = 'Wersja pobrana z aplikacji';de = 'Version wird von der Anwendung erhalten';ro = 'Versiunea este primită din aplicație';tr = 'Sürüm, uygulamadan alındı'; es_ES = 'Versión se ha recibido de la aplicación'");
	EndIf;
	
	FillNodeList();
	UpdateFiltersAndIgnored();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	Notify("DataExchangeResultFormClosed");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	UpdateAtServer();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	UpdateFiltersAndIgnored();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchStringOnChange(Item)
	
	UpdateFilterByReason();
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	UpdateFilterByPeriod();
	
EndProcedure

&AtClient
Procedure InfobaseNodeClearing(Item, StandardProcessing)
	
	InfobaseNode = Undefined;
	UpdateFilterByNode();
	
EndProcedure

&AtClient
Procedure InfobaseNodeOnChange(Item)
	
	UpdateFilterByNode();
	
EndProcedure

&AtClient
Procedure InfobaseNodeStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not Items.InfobaseNode.ListChoiceMode Then
		
		StandardProcessing = False;
		
		Handler = New NotifyDescription("InfobaseNodeStartChoiceCompletion", ThisObject);
		Mode = FormWindowOpeningMode.LockOwnerWindow;
		OpenForm("CommonForm.SelectExchangePlanNodes",,,,,, Handler, Mode);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InfobaseNodeStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	InfobaseNode = ClosingResult;
	UpdateFilterByNode();
	
EndProcedure

&AtClient
Procedure InfobaseNodeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	InfobaseNode = ValueSelected;
	
EndProcedure

&AtClient
Procedure DataExchangeResultsOnCurrentPageChange(Item, CurrentPage)
	
	If Item.ChildItems.ConflictPage = CurrentPage Then
		Items.SearchString.Enabled = False;
	Else
		Items.SearchString.Enabled = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region UnpostedDocumentsFormTableItemsEventHandlers

&AtClient
Procedure UnpostedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenObject(Items.UnpostedDocuments);
	
EndProcedure

&AtClient
Procedure UnpostedDocumentsBeforeRowChange(Item, Cancel)
	
	ObjectChange();
	Cancel = True;
	
EndProcedure

#EndRegion

#Region BlankAttributesFormTableItemsEventHandlers

&AtClient
Procedure BlankAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenObject(Items.BlankAttributes);
	
EndProcedure

&AtClient
Procedure BlankAttributesBeforeRowChange(Item, Cancel)
	
	ObjectChange();
	Cancel = True;
	
EndProcedure

#EndRegion

#Region XDTOErrorsFormTableItemsEventHandlers

&AtClient
Procedure XDTOObjectErrorsChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenObject(Items.XDTOObjectErrors);

EndProcedure

&AtClient
Procedure XDTOObjectErrorsBeforeRowChange(Item, Cancel)
	
	ObjectChange();
	Cancel = True;

EndProcedure

#EndRegion

#Region ConflictFormTableItemsEventHandlers

&AtClient
Procedure ConflictsBeforeRowChange(Item, Cancel)
	
	ObjectChange();
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ConflictsOnActivateRow(Item)
	
	If Item.CurrentData <> Undefined Then
		
		If Item.CurrentData.OtherVersionAccepted Then
			
			ConflictReason = NStr("ru = 'Конфликт был разрешен автоматически в пользу программы ""%1"".
				|Версия в этой программе была заменена на версию из другой программы.'; 
				|en = 'The conflict was automatically resolved for application ""%1"". 
				|This application version was replaced with the version of another application.'; 
				|pl = 'Konflikt został rozwiązany automatycznie na korzyść aplikacji ""%1"".
				|Wersja tej aplikacji została zmieniona na wersję z innej aplikacji.';
				|de = 'Konflikt wurde automatisch zugunsten der Anwendung ""%1"" erlaubt.
				|Version in dieser Anwendung wurde von einer anderen Anwendung in Version geändert.';
				|ro = 'Conflictul a fost soluționat automat în favoarea aplicației ""%1"".
				|Versiunea în această aplicație a fost înlocuită cu versiunea din altă aplicație.';
				|tr = 'Uyuşmazlık, ""%1"" uygulamasının lehine otomatik çolarak çözüldü. 
				|Bu uygulamadaki sürüm başka bir uygulamadan sürüme değiştirildi.'; 
				|es_ES = 'Conflicto se ha permitido automáticamente a favor de la aplicación ""%1"".
				|Versión en esta aplicación se ha cambiado a la versión de otra aplicación.'");
			ConflictReason = StringFunctionsClientServer.SubstituteParametersToString(ConflictReason, Item.CurrentData.OtherVersionAuthor);
			
		Else
			
			ConflictReason =NStr("ru = 'Конфликт был разрешен автоматически в пользу этой программы.
				|Версия в этой программе была сохранена, версия из другой программы была отклонена.'; 
				|en = 'The conflict was automatically resolved for this application.
				|This application version was saved, the other application version was rejected.'; 
				|pl = 'Konflikt został rozwiązany automatycznie na korzyść danej aplikacji.
				|Wersja w tej aplikacji została zapisana, wersja z innej aplikacji została odrzucona.';
				|de = 'Der Konflikt wurde automatisch zugunsten dieser Anwendung zugelassen.
				|Version in dieser Anwendung wurde gespeichert, Version von einer anderen Anwendung wurde abgelehnt.';
				|ro = 'Conflictul a fost soluționat automat în favoarea acestei aplicații.
				|Versiunea în această aplicație a fost salvată, versiunea din altă aplicație a fost respinsă.';
				|tr = 'Uyuşmazlık, bu uygulamasının lehine otomatik çolarak çözüldü. 
				|Bu uygulamadaki sürüm kaydedildi, başka bir uygulamadan sürüme reddedildi.'; 
				|es_ES = 'Conflicto se ha permitido automáticamente a favor de esta aplicación.
				|Versión en esta aplicación se ha guardado, la versión de otra aplicación se ha rechazado.'");
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DeclinedByDateFormTableItemsEventHandlers

&AtClient
Procedure DeclinedByDateBeforeRowChange(Item, Cancel)
	
	ObjectChange();
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DeclinedByDateOnActivateRow(Item)
	
	If Item.CurrentData <> Undefined Then
		
		If Item.CurrentData.NewObject Then
			
			Items.DeclinedByDateAcceptVersion.Enabled = False;
			
		Else
			
			Items.DeclinedByDateAcceptVersion.Enabled = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ShowInformationForTechnicians(Command)
	
	LogFilterParameters = PrepareEventLogFilters();
	OpenForm("DataProcessor.EventLog.Form", LogFilterParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Change(Command)
	
	ObjectChange();
	
EndProcedure

&AtClient
Procedure IgnoreDocument(Command)
	
	Ignore(Items.UnpostedDocuments.SelectedRows, True, "UnpostedDocuments");
	
EndProcedure

&AtClient
Procedure DontIgnoreDocument(Command)
	
	Ignore(Items.UnpostedDocuments.SelectedRows, False, "UnpostedDocuments");
	
EndProcedure

&AtClient
Procedure DontIgnoreObject(Command)
	
	Ignore(Items.BlankAttributes.SelectedRows, False, "BlankAttributes");
	
EndProcedure

&AtClient
Procedure IgnoreObject(Command)
	
	Ignore(Items.BlankAttributes.SelectedRows, True, "BlankAttributes");
	
EndProcedure

&AtClient
Procedure DontIgnoreError(Command)
	
	Ignore(Items.XDTOObjectErrors.SelectedRows, False, "XDTOObjectErrors");
	
EndProcedure

&AtClient
Procedure IgnoreError(Command)
	
	Ignore(Items.XDTOObjectErrors.SelectedRows, True, "XDTOObjectErrors");
	
EndProcedure

&AtClient
Procedure EditSelectedDocuments(Command)
	
	ChangeSelectedItems(Items.UnpostedDocuments);
	
EndProcedure

&AtClient
Procedure EditSelectedObjects(Command)
	
	ChangeSelectedItems(Items.BlankAttributes);
	
EndProcedure

&AtClient
Procedure ChangeSelectedCheckErrors(Command)
	
	ChangeSelectedItems(Items.XDTOObjectErrors);
	
EndProcedure

&AtClient
Procedure Update(Command)
	
	UpdateAtServer();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	ClearMessages();
	PostDocuments(Items.UnpostedDocuments.SelectedRows);
	UpdateAtServer("UnpostedDocuments");
	
EndProcedure

&AtClient
Procedure ShowDifferencesRejectedItems(Command)
	
	ShowDifferences(Items.RejectedDueToDate);
	
EndProcedure

&AtClient
Procedure OpenVersionDeclined(Command)
	
	If Items.RejectedDueToDate.CurrentData = Undefined Then
		Return;
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(Items.RejectedDueToDate.CurrentData.OtherVersionNumber);
	OpenVersionComparisonReport(Items.RejectedDueToDate.CurrentData.Ref, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure OpenVersionDeclinedInThisApplication(Command)
	
	If Items.RejectedDueToDate.CurrentData = Undefined Then
		Return;
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(Items.RejectedDueToDate.CurrentData.ThisVersionNumber);
	OpenVersionComparisonReport(Items.RejectedDueToDate.CurrentData.Ref, VersionsToCompare);

EndProcedure

&AtClient
Procedure ShowDifferencesConflicts(Command)
	
	ShowDifferences(Items.Conflicts);
	
EndProcedure

&AtClient
Procedure IgnoreConflict(Command)
	
	IgnoreVersion(Items.Conflicts.SelectedRows, True, "Conflicts");
	
EndProcedure

&AtClient
Procedure IgnoreDeclined(Command)
	
	IgnoreVersion(Items.RejectedDueToDate.SelectedRows, True, "RejectedDueToDate");
	
EndProcedure

&AtClient
Procedure DoNotIgnoreConflict(Command)
	
	IgnoreVersion(Items.Conflicts.SelectedRows, False, "Conflicts");
	
EndProcedure

&AtClient
Procedure DoNotIgnoreDeclined(Command)
	
	IgnoreVersion(Items.RejectedDueToDate.SelectedRows, False, "RejectedDueToDate");
	
EndProcedure

&AtClient
Procedure AcceptVersionDeclined(Command)
	
	NotifyDescription = New NotifyDescription("AcceptVersionNotAcceptedCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Принять версию, несмотря на запрет загрузки?'; en = 'Do you want to accept the version even though import is restricted?'; pl = 'Zaakceptować wersję pomimo zakazu importu danych?';de = 'Version akzeptieren trotz Importverbot?';ro = 'Acceptați versiunea în ciuda interdicției de import?';tr = 'İçe aktarma yasağına rağmen sürümü kabul etmek istiyor musunuz?'; es_ES = '¿Aceptar la versión a pesar de la prohibición de la importación?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure AcceptVersionNotAcceptedCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		AcceptRejectVersionAtServer(Items.RejectedDueToDate.SelectedRows, "RejectedDueToDate");
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPreConflictVersion(Command)
	
	CurrentData = Items.Conflicts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	OpenVersionAtClient(Items.Conflicts.CurrentData, CurrentData.ThisVersionNumber);
	
EndProcedure

&AtClient
Procedure OpenConflictVersion(Command)
	
	CurrentData = Items.Conflicts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	OpenVersionAtClient(Items.Conflicts.CurrentData, CurrentData.OtherVersionNumber);
	
EndProcedure

&AtClient
Procedure ShowIgnoredConflicts(Command)
	
	ShowIgnoredConflicts = Not ShowIgnoredConflicts;
	ShowIgnoredConflictsAtServer();
	
EndProcedure

&AtClient
Procedure ShowIgnoredBlankItems(Command)
	
	ShowIgnoredBlankItems = Not ShowIgnoredBlankItems;
	ShowIgnoredBlankItemsAtServer();
	
EndProcedure

&AtClient
Procedure ShowIgnoredErrors(Command)
	
	ShowIgnoredErrors = Not ShowIgnoredErrors;
	ShowIgnoredErrorsAtServer();
	
EndProcedure

&AtClient
Procedure ShowIgnoredRejectedItems(Command)
	
	ShowIgnoredRejectedItems = Not ShowIgnoredRejectedItems;
	ShowIgnoredRejectedItemsAtServer();
	
EndProcedure

&AtClient
Procedure ShowIgnoredUnpostedItems(Command)
	
	ShowIgnoredUnpostedItems = Not ShowIgnoredUnpostedItems;
	ShowIgnoredUnpostedItemsAtServer();
	
EndProcedure

&AtClient
Procedure ChangeConflictResult(Command)
	
	If Items.Conflicts.CurrentData <> Undefined Then
		
		If Items.Conflicts.CurrentData.OtherVersionAccepted Then
			
			QuestionText = NStr("ru = 'Заменить версию, полученную из другой программы, на версию из этой программы?'; en = 'Do you want to replace the object version from another application with the object version from this application?'; pl = 'Zamienić wersję pobraną z innej aplikacji na wersję z danej aplikacji?';de = 'Ersetzen Sie die von einer anderen Anwendung erhaltene Version durch die Version dieser Anwendung?';ro = 'Înlocuiți versiunea primită de la altă aplicație cu versiunea din această aplicație?';tr = 'Başka bir uygulamadan alınan sürüm bu uygulamanın sürümü ile değiştirilsin mi?'; es_ES = '¿Reemplazar la versión recibida de otra aplicación con la versión de esta aplicación?'");
			
		Else
			
			QuestionText = NStr("ru = 'Заменить версию этой программы на версию, полученную из другой программы?'; en = 'Do you want to replace the object version from this application with the object version from another application?'; pl = 'Zamienić wersję z danej aplikacji na wersję pobraną z innej aplikacji?';de = 'Ersetzen Sie eine Version dieser Anwendung durch die von einer anderen Anwendung erhaltene Version?';ro = 'Înlocuiți versiunea acestei aplicații cu versiunea primită de la o altă aplicație?';tr = 'Bu uygulamanın bir sürümü başka bir uygulamadan alınan sürümle değiştirilsin mi?'; es_ES = '¿Reemplazar una versión de esta aplicación con la versión recibida de otra aplicación?'");
			
		EndIf;
		
		NotifyDescription = New NotifyDescription("ChangeConflictResultCompletion", ThisObject);
		ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeConflictResultCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		AcceptRejectVersionAtServer(Items.Conflicts.SelectedRows, "Conflicts");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PrepareEventLogFilters();
	
	WarningsLevels = New Array();
	WarningsLevels.Add(String(EventLogLevel.Error));
	WarningsLevels.Add(String(EventLogLevel.Warning));
	
	LogFilterParameters = New Structure;
	LogFilterParameters.Insert("EventLogEvent", DataExchangeServer.EventLogMessageTextDataExchange());
	LogFilterParameters.Insert("Level",                   WarningsLevels);   
	
	Return LogFilterParameters;
	
EndFunction

&AtServer
Procedure Ignore(Val SelectedRows, Ignore, ItemName)
	
	For Each SelectedRow In SelectedRows Do
		
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
	
		InformationRegisters.DataExchangeResults.Ignore(SelectedRow.ObjectWithIssue, SelectedRow.IssueType, Ignore);
	
	EndDo;
	
	UpdateAtServer(ItemName);
	
EndProcedure

&AtServer
Procedure ShowIgnoredConflictsAtServer(Update = True)
	
	Items.ConflictsShowIgnoredConflicts.Check = ShowIgnoredConflicts;
	
	Filter = Conflicts.SettingsComposer.Settings.Filter;
	FilterItem = Filter.GetObjectByID( DynamicListsFiltersSettings.Conflicts.VersionIgnored );
	FilterItem.RightValue = ShowIgnoredConflicts;
	FilterItem.Use  = Not ShowIgnoredConflicts;
	
	If Update Then
		UpdateAtServer("Conflicts");
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowIgnoredBlankItemsAtServer(Update = True)
	
	Items.BlankAttributesShowIgnoredBlankItems.Check = ShowIgnoredBlankItems;
	
	Filter = BlankAttributes.SettingsComposer.Settings.Filter;
	FilterItem = Filter.GetObjectByID( DynamicListsFiltersSettings.BlankAttributes.Skipped );
	FilterItem.RightValue = ShowIgnoredBlankItems;
	FilterItem.Use  = Not ShowIgnoredBlankItems;
	
	If Update Then
		UpdateAtServer("BlankAttributes");
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowIgnoredErrorsAtServer(Update = True)
	
	Items.XDTOObjectErrorsShowIgnored.Check = ShowIgnoredErrors;
	Filter = XDTOObjectErrors.SettingsComposer.Settings.Filter;
	FilterItem = Filter.GetObjectByID( DynamicListsFiltersSettings.XDTOObjectErrors.Skipped );
	FilterItem.RightValue = ShowIgnoredErrors;
	FilterItem.Use  = Not ShowIgnoredErrors;
	
	If Update Then
		UpdateAtServer("BlankAttributes");
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowIgnoredRejectedItemsAtServer(Update = True)
	
	Items.DeclinedByDateShowIgnoredDeclinedItems.Check = ShowIgnoredRejectedItems;
	
	Filter = RejectedDueToDate.SettingsComposer.Settings.Filter;
	FilterItem = Filter.GetObjectByID( DynamicListsFiltersSettings.RejectedDueToDate.VersionIgnored );
	FilterItem.RightValue = ShowIgnoredRejectedItems;
	FilterItem.Use  = Not ShowIgnoredRejectedItems;
	
	If Update Then
		UpdateAtServer("RejectedDueToDate");
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowIgnoredUnpostedItemsAtServer(Update = True)
	
	Items.UnpostedDocumentsShowIgnoredUnpostedItems.Check = ShowIgnoredUnpostedItems;
	
	Filter = UnpostedDocuments.SettingsComposer.Settings.Filter;
	FilterItem = Filter.GetObjectByID( DynamicListsFiltersSettings.UnpostedDocuments.Skipped );
	FilterItem.RightValue = ShowIgnoredUnpostedItems;
	FilterItem.Use  = Not ShowIgnoredUnpostedItems;
	
	If Update Then
		UpdateAtServer("UnpostedDocuments");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(List)
	
	If CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		ModuleBatchObjectModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
		ModuleBatchObjectModificationClient.ChangeSelectedItems(List);
	EndIf;
	
EndProcedure

&AtServer
Procedure PostDocuments(Val SelectedRows)
	
	For Each SelectedRow In SelectedRows Do
		
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		
		DocumentObject = SelectedRow.ObjectWithIssue.GetObject();
		
		If DocumentObject.CheckFilling() Then
			
			DocumentObject.Write(DocumentWriteMode.Posting);
			
		EndIf;
	
	EndDo;
	
EndProcedure

&AtServer
Procedure FillNodeList()
	
	NoneExchangeByRules  = True;
	NoneXDTOExchange        = True;
	NoneDIBExchange         = True;
	NoneStandardExchange = True;
	
	ContextOpening = ValueIsFilled(Parameters.ExchangeNodes);
	
	ExchangeNodes = ?(ContextOpening, Parameters.ExchangeNodes, NodesArrayOnOpenOutOfContext());
	Items.InfobaseNode.ChoiceList.LoadValues(ExchangeNodes);
	
	For Each ExchangeNode In ExchangeNodes Do
		
		ExchangePlanName               = DataExchangeCached.GetExchangePlanName(ExchangeNode);
		IsXDTOExchangePlanNode       = DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName);
		IsDIBExchangePlanNode        = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
		IsExchangePlanNodeByRules = DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules");
		
		If IsXDTOExchangePlanNode Then			
			NoneXDTOExchange = False;
		EndIf;
		
		If IsExchangePlanNodeByRules Then
			NoneExchangeByRules = False;
		EndIf;
		
		If IsDIBExchangePlanNode Then
			NoneDIBExchange = False;
		EndIf;
		
		If Not IsXDTOExchangePlanNode
			AND Not IsExchangePlanNodeByRules 
			AND Not IsDIBExchangePlanNode Then
		    NoneStandardExchange = False;
		EndIf;
		
	EndDo;
	
	SetFilterByNodes(ExchangeNodes);
	NodesList = New ValueList;
	NodesList.LoadValues(ExchangeNodes);
	
	If ExchangeNodes.Count() < 2 Then
		
		InfobaseNode = Undefined;
		Items.InfobaseNode.Visible = False;
		Items.UnpostedDocumentsInfobaseNode.Visible = False;
		Items.BlankAttributesInfobaseNode.Visible = False;
		Items.XDTOObjectErrorsInfobaseNode.Visible = False;
		
		If VersioningUsed Then
			Items.ConflictsAnotherVersionAuthor.Visible = False;
			Items.DeclinedByDateAnotherVersionAuthor.Visible = False;
		EndIf;
		
	ElsIf ExchangeNodes.Count() >= 7 Then
		
		Items.InfobaseNode.ListChoiceMode = False;
		
	EndIf;
	
	Items.SearchString.Visible = True;
	
	If NoneExchangeByRules AND NoneXDTOExchange AND NoneStandardExchange Then
		
		Title = NStr("ru = 'Конфликты при синхронизации данных'; en = 'Data synchronization conflicts'; pl = 'Podczas synchronizacji danych wystąpił konflikt';de = 'Konflikte während der Datensynchronisation';ro = 'Conflicte în timpul sincronizării datelor';tr = 'Veri senkronizasyonu sırasında çakışmalar'; es_ES = 'Conflictos durante la sincronización de datos'");
		Items.SearchString.Visible = False;
		Items.DataExchangeResults.CurrentPage = Items.DataExchangeResults.ChildItems.ConflictPage;
		Items.DataExchangeResults.PagesRepresentation = FormPagesRepresentation.None;
		
	Else
		
		Items.XDTOErrorPage.Visible             = Not NoneXDTOExchange;
		Items.BlankAttributesPage.Visible = Not NoneXDTOExchange Or Not NoneExchangeByRules;
		Items.UnpostedDocumentsPage.Visible = Not NoneXDTOExchange Or Not NoneExchangeByRules;		
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFilterByNodes(ExchangeNodes)
	
	FilterByNodesDocument = DynamicListFilterItem(UnpostedDocuments,
		DynamicListsFiltersSettings.UnpostedDocuments.NodeInList);
	FilterByNodesDocument.Use = True;
	FilterByNodesDocument.RightValue = ExchangeNodes;
	
	FilterByNodesObject = DynamicListFilterItem(BlankAttributes,
		DynamicListsFiltersSettings.BlankAttributes.NodeInList);
	FilterByNodesObject.Use = True;
	FilterByNodesObject.RightValue = ExchangeNodes;
	
	FilterByNodesObject = DynamicListFilterItem(XDTOObjectErrors,
		DynamicListsFiltersSettings.XDTOObjectErrors.NodeInList);
	FilterByNodesObject.Use = True;
	FilterByNodesObject.RightValue = ExchangeNodes;

	
	If VersioningUsed Then
		
		FilterByNodesConflict = DynamicListFilterItem(Conflicts,
			DynamicListsFiltersSettings.Conflicts.AuthorInList);
		FilterByNodesConflict.Use = True;
		FilterByNodesConflict.RightValue = ExchangeNodes;
		
		FilterByNodesNotAccepted = DynamicListFilterItem(RejectedDueToDate,
			DynamicListsFiltersSettings.RejectedDueToDate.AuthorInList);
		FilterByNodesNotAccepted.Use = True;
		FilterByNodesNotAccepted.RightValue = ExchangeNodes;
		
	EndIf;
	
EndProcedure

&AtServer
Function NodesArrayOnOpenOutOfContext()
	
	ExchangeNodes = New Array;
	
	ExchangePlanList = DataExchangeCached.SSLExchangePlans();
	
	For Each ExchangePlanName In ExchangePlanList Do
		
		If Not AccessRight("Read", ExchangePlans[ExchangePlanName].EmptyRef().Metadata()) Then
			Continue;
		EndIf;	
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	ExchangePlanTable.Ref AS ExchangeNode
		|FROM
		|	&ExchangePlanTable AS ExchangePlanTable
		|WHERE
		|	NOT ExchangePlanTable.ThisNode
		|	AND ExchangePlanTable.Ref.DeletionMark = FALSE
		|
		|ORDER BY
		|	Presentation";
		Query.Text = StrReplace(Query.Text, "&ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			ExchangeNodes.Add(Selection.ExchangeNode);
			
		EndDo;
		
	EndDo;
	
	Return ExchangeNodes;
	
EndFunction

&AtServer
Procedure UpdateFilterByNode(Update = True)
	
	Usage = ValueIsFilled(InfobaseNode);
	
	FilterByNodeDocument = DynamicListFilterItem(UnpostedDocuments,
		DynamicListsFiltersSettings.UnpostedDocuments.NodeEqual);
	FilterByNodeDocument.Use = Usage;
	FilterByNodeDocument.RightValue = InfobaseNode;
	
	FilterByNodeObject = DynamicListFilterItem(BlankAttributes,
		DynamicListsFiltersSettings.BlankAttributes.NodeEqual);
	FilterByNodeObject.Use = Usage;
	FilterByNodeObject.RightValue = InfobaseNode;
	
	FilterByNodeObject = DynamicListFilterItem(XDTOObjectErrors,
		DynamicListsFiltersSettings.XDTOObjectErrors.NodeEqual);
	FilterByNodeObject.Use = Usage;
	FilterByNodeObject.RightValue = InfobaseNode;

	
	If VersioningUsed Then
		
		FilterByNodeConflicts = DynamicListFilterItem(Conflicts,
			DynamicListsFiltersSettings.Conflicts.AuthorEqual);
		FilterByNodeConflicts.Use = Usage;
		FilterByNodeConflicts.RightValue = InfobaseNode;
		
		FilterByNodeNotAccepted = DynamicListFilterItem(RejectedDueToDate,
			DynamicListsFiltersSettings.RejectedDueToDate.AuthorEqual);
		FilterByNodeNotAccepted.Use = Usage;
		FilterByNodeNotAccepted.RightValue = InfobaseNode;
		
	EndIf;
	
	If Update Then
		UpdateAtServer();
	EndIf;
EndProcedure

&AtServer
Function NotAcceptedCount()
	
	ExchangeNodes = ?(ValueIsFilled(InfobaseNode), InfobaseNode, NodesList);
	
	QueryParameters = DataExchangeServer.QueryParametersVersioningIssuesCount();
	
	QueryParameters.IsConflictCount      = False;
	QueryParameters.IncludingIgnored = ShowIgnoredConflicts;
	QueryParameters.Period                     = Period;
	QueryParameters.SearchString               = SearchString;
	
	Return DataExchangeServer.VersioningIssuesCount(ExchangeNodes, QueryParameters);
	
EndFunction

&AtServer
Function ConflictCount()
	
	ExchangeNodes = ?(ValueIsFilled(InfobaseNode), InfobaseNode, NodesList);
	
	QueryParameters = DataExchangeServer.QueryParametersVersioningIssuesCount();
	
	QueryParameters.IsConflictCount      = True;
	QueryParameters.IncludingIgnored = ShowIgnoredConflicts;
	QueryParameters.Period                     = Period;
	QueryParameters.SearchString               = SearchString;
	
	Return DataExchangeServer.VersioningIssuesCount(ExchangeNodes, QueryParameters);
	
EndFunction

&AtServer
Function BlankAttributeCount()
	
	ExchangeNodes = ?(ValueIsFilled(InfobaseNode), InfobaseNode, NodesList);
	
	SearchParameters = InformationRegisters.DataExchangeResults.IssueSearchParameters();
	SearchParameters.IssueType                = Enums.DataExchangeIssuesTypes.BlankAttributes;
	SearchParameters.IncludingIgnored = ShowIgnoredBlankItems;
	SearchParameters.Period                     = Period;
	SearchParameters.SearchString               = SearchString;
	SearchParameters.ExchangePlanNodes            = ExchangeNodes;
	
	Return InformationRegisters.DataExchangeResults.IssuesCount(SearchParameters);
	
EndFunction

&AtServer
Function UnpostedDocumentCount()
	
	ExchangeNodes = ?(ValueIsFilled(InfobaseNode), InfobaseNode, NodesList);
	
	SearchParameters = InformationRegisters.DataExchangeResults.IssueSearchParameters();
	SearchParameters.IssueType                = Enums.DataExchangeIssuesTypes.UnpostedDocument;
	SearchParameters.IncludingIgnored = ShowIgnoredUnpostedItems;
	SearchParameters.Period                     = Period;
	SearchParameters.SearchString               = SearchString;
	SearchParameters.ExchangePlanNodes            = ExchangeNodes;	
	
	Return InformationRegisters.DataExchangeResults.IssuesCount(SearchParameters);
	
EndFunction

&AtServer
Function XDTOErrorsCount()
	
	ExchangeNodes = ?(ValueIsFilled(InfobaseNode), InfobaseNode, NodesList);
	
	SearchParameters = InformationRegisters.DataExchangeResults.IssueSearchParameters();
	SearchParameters.IssueType                = Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError;
	SearchParameters.IncludingIgnored = ShowIgnoredErrors;
	SearchParameters.Period                     = Period;
	SearchParameters.SearchString               = SearchString;
	SearchParameters.ExchangePlanNodes            = ExchangeNodes;	
	
	Return InformationRegisters.DataExchangeResults.IssuesCount(SearchParameters);
	
EndFunction

&AtServer
Procedure SetPageTitle(Page, Title, Count)
	
	AdditionalString = ?(Count > 0, " (" + Count + ")", "");
	Title = Title + AdditionalString;
	Page.Title = Title;
	
EndProcedure

&AtClient
Procedure OpenObject(Item)
	
	If Item.CurrentRow = Undefined Or TypeOf(Item.CurrentRow) = Type("DynamicalListGroupRow") Then
		ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для указанного объекта.'; en = 'Cannot run the command for the specified object.'; pl = 'Polecenie nie może być wykonane dla określonego obiektu.';de = 'Der Befehl kann für das angegebene Objekt nicht ausgeführt werden.';ro = 'Comanda nu poate fi executată pentru obiectul indicat.';tr = 'Belirtilen nesne için komut çalıştırılamaz.'; es_ES = 'No se puede ejecutar el comando para el objeto especificado.'"));
		Return;
	Else
		ShowValue(, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectChange()
	
	ResultsPages = Items.DataExchangeResults;
	
	If ResultsPages.CurrentPage = ResultsPages.ChildItems.UnpostedDocumentsPage Then
		
		OpenObject(Items.UnpostedDocuments); 
		
	ElsIf ResultsPages.CurrentPage = ResultsPages.ChildItems.BlankAttributesPage Then
		
		OpenObject(Items.BlankAttributes);
		
	ElsIf ResultsPages.CurrentPage = ResultsPages.ChildItems.XDTOErrorPage Then
		
		OpenObject(Items.XDTOObjectErrors); 		
		
	ElsIf ResultsPages.CurrentPage = ResultsPages.ChildItems.ConflictPage Then
		
		OpenObject(Items.Conflicts);
		
	ElsIf ResultsPages.CurrentPage = ResultsPages.ChildItems.RejectedByRestrictionDatePage Then
		
		OpenObject(Items.RejectedDueToDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowDifferences(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	VersionsToCompare = New Array;
	
	If Item.CurrentData.ThisVersionNumber <> 0 Then
		VersionsToCompare.Add(Item.CurrentData.ThisVersionNumber);
	EndIf;
	
	If Item.CurrentData.OtherVersionNumber <> 0 Then
		VersionsToCompare.Add(Item.CurrentData.OtherVersionNumber);
	EndIf;
	
	If VersionsToCompare.Count() <> 2 Then
		
		CommonClient.MessageToUser(NStr("ru = 'Нет версии для сравнения.'; en = 'No object version to compare.'; pl = 'Brak wersji do porównania.';de = 'Es gibt keine zu vergleichende Version.';ro = 'Nu există nici o versiune de comparat.';tr = 'Karşılaştırılacak bir sürüm yok.'; es_ES = 'No hay una versión para comparar.'"));
		Return;
		
	EndIf;
	
	OpenVersionComparisonReport(Item.CurrentData.Ref, VersionsToCompare);
	
EndProcedure

&AtServer
Procedure UpdateFilterByReason(Update = True)
	
	SearchStringSpecified = ValueIsFilled(SearchString);
	
	CommonClientServer.SetDynamicListFilterItem(
		UnpostedDocuments, "Reason", SearchString, DataCompositionComparisonType.Contains, , SearchStringSpecified);
	
	CommonClientServer.SetDynamicListFilterItem(
		BlankAttributes, "Reason", SearchString, DataCompositionComparisonType.Contains, , SearchStringSpecified);
		
	CommonClientServer.SetDynamicListFilterItem(
		XDTOObjectErrors, "Reason", SearchString, DataCompositionComparisonType.Contains, , SearchStringSpecified);
		
	If VersioningUsed Then
	
		CommonClientServer.SetDynamicListFilterItem(
			RejectedDueToDate, "ProhibitionReason", SearchString, DataCompositionComparisonType.Contains, , SearchStringSpecified);
		
	EndIf;
	
	If Update Then
		UpdateAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFilterByPeriod(Update = True)
	
	Usage = ValueIsFilled(Period);
	
	// Unposted documents
	FilterByPeriodDocumentFrom = DynamicListFilterItem(UnpostedDocuments,
		DynamicListsFiltersSettings.UnpostedDocuments.StartDate);
	FilterByPeriodDocumentTo = DynamicListFilterItem(UnpostedDocuments,
		DynamicListsFiltersSettings.UnpostedDocuments.EndDate);
		
	FilterByPeriodDocumentFrom.Use  = Usage;
	FilterByPeriodDocumentTo.Use = Usage;
	
	FilterByPeriodDocumentFrom.RightValue  = Period.StartDate;
	FilterByPeriodDocumentTo.RightValue = Period.EndDate;
	
	// Blank attributes
	FilterByPeriodObjectFrom = DynamicListFilterItem(BlankAttributes,
		DynamicListsFiltersSettings.BlankAttributes.StartDate);
	FilterByPeriodObjectTo = DynamicListFilterItem(BlankAttributes,
		DynamicListsFiltersSettings.BlankAttributes.EndDate);
		
	FilterByPeriodObjectFrom.Use  = Usage;
	FilterByPeriodObjectTo.Use = Usage;
	
	FilterByPeriodObjectFrom.RightValue  = Period.StartDate;
	FilterByPeriodObjectTo.RightValue = Period.EndDate;
	
	// XDTO object errors
	FilterByPeriodObjectFrom = DynamicListFilterItem(XDTOObjectErrors,
		DynamicListsFiltersSettings.XDTOObjectErrors.StartDate);
	FilterByPeriodObjectTo = DynamicListFilterItem(XDTOObjectErrors,
		DynamicListsFiltersSettings.XDTOObjectErrors.EndDate);
		
	FilterByPeriodObjectFrom.Use  = Usage;
	FilterByPeriodObjectTo.Use = Usage;
	
	FilterByPeriodObjectFrom.RightValue  = Period.StartDate;
	FilterByPeriodObjectTo.RightValue = Period.EndDate;
	
	If VersioningUsed Then
		
		FilterByPeriodConflictsFrom = DynamicListFilterItem(Conflicts,
			DynamicListsFiltersSettings.Conflicts.StartDate);
		FilterByPeriodConflictTo = DynamicListFilterItem(Conflicts,
			DynamicListsFiltersSettings.Conflicts.EndDate);
		
		FilterByPeriodConflictsFrom.Use  = Usage;
		FilterByPeriodConflictTo.Use = Usage;
		
		FilterByPeriodConflictsFrom.RightValue  = Period.StartDate;
		FilterByPeriodConflictTo.RightValue = Period.EndDate;
		
		FilterByPeriodNotAcceptedFrom = DynamicListFilterItem(RejectedDueToDate,
			DynamicListsFiltersSettings.RejectedDueToDate.StartDate);
		FilterByPeriodNotAcceptedTo = DynamicListFilterItem(RejectedDueToDate,
			DynamicListsFiltersSettings.RejectedDueToDate.EndDate);
		
		FilterByPeriodNotAcceptedFrom.Use  = Usage;
		FilterByPeriodNotAcceptedTo.Use = Usage;
		
		FilterByPeriodNotAcceptedFrom.RightValue  = Period.StartDate;
		FilterByPeriodNotAcceptedTo.RightValue = Period.EndDate;
		
	EndIf;
	
	If Update Then
		UpdateAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure IgnoreVersion(Val SelectedRows, Ignore, ItemName)
	
	For Each SelectedRow In SelectedRows Do
		
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
			ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
			ModuleObjectsVersioning.IgnoreObjectVersion(SelectedRow.Object,
				SelectedRow.VersionNumber, Ignore);
		EndIf;
		
	EndDo;
	
	UpdateAtServer(ItemName);
	
EndProcedure

&AtServer
Procedure UpdateAtServer(UpdatedItem = "")
	
	UpdateFormLists(UpdatedItem);
	UpdatePageTitles();
	
EndProcedure

&AtServer
Procedure UpdateFormLists(UpdatedItem)
	
	If ValueIsFilled(UpdatedItem) Then
		
		Items[UpdatedItem].Refresh();
		
	Else
		
		Items.UnpostedDocuments.Refresh();
		Items.BlankAttributes.Refresh();
		Items.XDTOObjectErrors.Refresh();		
		
		If VersioningUsed Then
			Items.Conflicts.Refresh();
			Items.RejectedDueToDate.Refresh();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePageTitles()
	
	SetPageTitle(Items.UnpostedDocumentsPage, NStr("ru= 'Непроведенные документы'; en = 'Unposted documents'; pl = 'Niezaksięgowane dokumenty';de = 'Nicht hochgeladene Dokumente';ro = 'Documente neîncărcate';tr = 'Gönderilmemiş belgeler'; es_ES = 'Documentos sin enviar'"), UnpostedDocumentCount());
	SetPageTitle(Items.BlankAttributesPage, NStr("ru= 'Незаполненные реквизиты'; en = 'Blank attributes'; pl = 'Puste atrybuty';de = 'Leere Attribute';ro = 'Atribute necompletate';tr = 'Doldurulmamış özellikler'; es_ES = 'Atributos en blanco'"), BlankAttributeCount());
	SetPageTitle(Items.XDTOObjectErrors,              NStr("ru= 'Ошибки проверки конвертируемых объектов'; en = 'Error checking convertible objects'; pl = 'Błędy sprawdzania obiektów zamiennych';de = 'Fehler bei der Verifizierung von konvertierbaren Objekten';ro = 'Erori de verificare a obiectelor convertite';tr = 'Dönüştürülen nesneleri doğrulama hatası'; es_ES = 'Errores de comprobar los objetos convertidos'"), XDTOErrorsCount());	
	
	If VersioningUsed Then
		SetPageTitle(Items.ConflictPage, NStr("ru= 'Конфликты'; en = 'Conflicts'; pl = 'Konflikty';de = 'Konflikte';ro = 'Conflicte';tr = 'Uyuşmazlıklar'; es_ES = 'Conflictos'"), ConflictCount());
		SetPageTitle(Items.RejectedByRestrictionDatePage, NStr("ru= 'Непринятые по дате запрета'; en = 'Items rejected due to restriction date'; pl = 'Niezaakceptowane wg daty zamknięcia';de = 'Nicht akzeptiert bis zum Sperrdatum';ro = 'Neacceptate conform datei de interdicție';tr = 'Kapanış tarihine göre kabul edilmeyenler'; es_ES = 'No aceptado antes de la fecha de cierre'"), NotAcceptedCount());
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenVersionAtClient(CurrentData, Version)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(Version);
	OpenVersionComparisonReport(CurrentData.Ref, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OpenVersionComparisonReport(Ref, VersionsToCompare);
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptRejectVersionAtServer(Val SelectedRows, ItemName)
	
	For Each SelectedRow In SelectedRows Do
		
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
			ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
			ModuleObjectsVersioning.OnStartUsingNewObjectVersion(SelectedRow.Object,
				SelectedRow.VersionNumber);
		EndIf;
		
	EndDo;
	
	UpdateAtServer(ItemName);
	
EndProcedure

&AtServer
Procedure SetUpDynamicListFilters(Result)
	
	Result = New Structure;
	
	// Unposted documents
	Filter = UnpostedDocuments.SettingsComposer.Settings.Filter;
	Result.Insert("UnpostedDocuments", New Structure);
	Setting = Result.UnpostedDocuments;
	
	Setting.Insert("Skipped", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Skipped", DataCompositionComparisonType.Equal, False, ,True)));
	Setting.Insert("StartDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.GreaterOrEqual, '00010101', , True)));
	Setting.Insert("EndDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.LessOrEqual, '00010101', , True)));
	Setting.Insert("NodeEqual", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.Equal, Undefined, , False)));
	Setting.Insert("Reason", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Reason", DataCompositionComparisonType.Contains, Undefined, , False)));
	Setting.Insert("NodeInList", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.InList, Undefined, , False)));
		
	// Blank attributes
	Filter = BlankAttributes.SettingsComposer.Settings.Filter;
	Result.Insert("BlankAttributes", New Structure);
	Setting = Result.BlankAttributes;
	
	Setting.Insert("Skipped", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Skipped", DataCompositionComparisonType.Equal, False, ,True)));
	Setting.Insert("StartDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.GreaterOrEqual, '00010101', , True)));
	Setting.Insert("EndDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.LessOrEqual, '00010101', , True)));
	Setting.Insert("NodeEqual", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.Equal, Undefined, , False)));
	Setting.Insert("Reason", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Reason", DataCompositionComparisonType.Contains, Undefined, , False)));
	Setting.Insert("NodeInList", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.InList, Undefined, , False)));
		
	// XDTO errors
	Filter = XDTOObjectErrors.SettingsComposer.Settings.Filter;
	Result.Insert("XDTOObjectErrors", New Structure);
	Setting = Result.XDTOObjectErrors;
	
	Setting.Insert("Skipped", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Skipped", DataCompositionComparisonType.Equal, False, ,True)));
	Setting.Insert("StartDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.GreaterOrEqual, '00010101', , True)));
	Setting.Insert("EndDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OccurrenceDate", DataCompositionComparisonType.LessOrEqual, '00010101', , True)));
	Setting.Insert("NodeEqual", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.Equal, Undefined, , False)));
	Setting.Insert("Reason", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Reason", DataCompositionComparisonType.Contains, Undefined, , False)));
	Setting.Insert("NodeInList", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "InfobaseNode", DataCompositionComparisonType.InList, Undefined, , False)));
		
	If VersioningUsed Then
		
		// Conflicts
		Filter = Conflicts.SettingsComposer.Settings.Filter;
		Result.Insert("Conflicts", New Structure);
		Setting = Result.Conflicts;
		
		Setting.Insert("AuthorEqual", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OtherVersionAuthor", DataCompositionComparisonType.Equal, Undefined, ,False)));
		Setting.Insert("StartDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Date", DataCompositionComparisonType.GreaterOrEqual, '00010101', , True)));
		Setting.Insert("EndDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Date", DataCompositionComparisonType.LessOrEqual, '00010101', , True)));
		Setting.Insert("VersionIgnored", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "VersionIgnored", DataCompositionComparisonType.Equal, False, , True)));
		Setting.Insert("AuthorInList", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OtherVersionAuthor", DataCompositionComparisonType.InList, Undefined, ,False)));
		
		// Items rejected due to restriction date
		Filter = RejectedDueToDate.SettingsComposer.Settings.Filter;
		Result.Insert("RejectedDueToDate", New Structure);
		Setting = Result.RejectedDueToDate;
		
		Setting.Insert("AuthorEqual", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OtherVersionAuthor", DataCompositionComparisonType.Equal, Undefined, ,False)));
		Setting.Insert("StartDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Date", DataCompositionComparisonType.GreaterOrEqual, '00010101', , True)));
		Setting.Insert("EndDate", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "Date", DataCompositionComparisonType.LessOrEqual, '00010101', , True)));
		Setting.Insert("ProhibitionReason", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "ProhibitionReason", DataCompositionComparisonType.Equal, Undefined, , False)));
		Setting.Insert("VersionIgnored", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "VersionIgnored", DataCompositionComparisonType.Equal, False, , True)));
		Setting.Insert("AuthorInList", Filter.GetIDByObject(
		CommonClientServer.AddCompositionItem(Filter, "OtherVersionAuthor", DataCompositionComparisonType.InList, Undefined, ,False)));
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DynamicListFilterItem(Val DynamicList, Val ID)
	Return DynamicList.SettingsComposer.Settings.Filter.GetObjectByID(ID);
EndFunction

&AtServer
Procedure UpdateFiltersAndIgnored()
	
	UpdateFilterByPeriod(False);
	UpdateFilterByNode(False);
	UpdateFilterByReason(False);
	
	ShowIgnoredUnpostedItemsAtServer(False);
	ShowIgnoredBlankItemsAtServer(False);
	ShowIgnoredErrorsAtServer(False);
	
	If VersioningUsed Then
		ShowIgnoredConflictsAtServer(False);
		ShowIgnoredRejectedItemsAtServer(False);
	EndIf;
	
	UpdateAtServer();
	
	If Not Items.DataExchangeResults.CurrentPage = Items.DataExchangeResults.ChildItems.ConflictPage Then
		
		For Each Page In Items.DataExchangeResults.ChildItems Do
			
			If StrFind(Page.Title, "(") Then
				Items.DataExchangeResults.CurrentPage = Page;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Unposted documents.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnpostedDocuments.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UnpostedDocuments.Skipped");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"UnpostedDocuments.DocumentDate",
		Items.UnpostedDocumentsDocumentDate.Name);
	
	// Conflicts.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Conflicts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Conflicts.VersionIgnored");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Conflicts, other version is accepted, text color.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConflictsAnotherVersionAccepted.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Conflicts.VersionIgnored");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Conflicts.OtherVersionAccepted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnacceptedVersion);
	
	// Conflicts, other version is accepted, text.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConflictsAnotherVersionAccepted.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Conflicts.OtherVersionNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Удалена'; en = 'Deleted'; pl = 'Usunięte';de = 'Gelöscht';ro = 'Eliminat';tr = 'Silindi'; es_ES = 'Borrado'"));
	
	// Blank attributes.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BlankAttributes.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BlankAttributes.Skipped");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// XDTO conversion errors.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.XDTOObjectErrors.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("XDTOObjectErrors.Skipped");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	
	// Data declined by date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RejectedDueToDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RejectedDueToDate.VersionIgnored");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Declined due to date, reference.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeclinedByDateRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RejectedDueToDate.NewObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Отсутствуют'; en = 'Missing'; pl = 'Brak';de = 'Fehlt';ro = 'Dispărut';tr = 'Eksik'; es_ES = 'Falta'"));
	
	// Data declined by date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeclinedByDateAnotherVersionAuthor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RejectedDueToDate.VersionIgnored");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnacceptedVersion);
	
EndProcedure

#EndRegion
