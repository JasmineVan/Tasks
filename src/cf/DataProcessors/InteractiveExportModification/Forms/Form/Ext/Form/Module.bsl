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
	
	If NOT Parameters.Property("OpenByScenario") Then
		Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor cannot be opened manually.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	ThisDataProcessor = ThisObject();
	If IsBlankString(Parameters.ObjectAddress) Then
		ThisObject( ThisDataProcessor.InitializeThisObject(Parameters.ObjectSettings) );
	Else
		ThisObject( ThisDataProcessor.InitializeThisObject(Parameters.ObjectAddress) );
	EndIf;
	
	If Not ValueIsFilled(Object.InfobaseNode) Then
		Text = NStr("ru='Настройка обмена данными не найдена.'; en = 'The data exchange setting is not found.'; pl = 'Ustawienia wymiany danych nie zostały znalezione.';de = 'Datenaustauscheinstellung wurde nicht gefunden.';ro = 'Setarea schimbului de date nu a fost găsită.';tr = 'Veri değişimi ayarı bulunmadı.'; es_ES = 'Configuración del intercambio de datos no se ha encontrado.'");
		DataExchangeServer.ReportError(Text, Cancel);
		Return;
	EndIf;
	
	Title = Title + " (" + Object.InfobaseNode + ")";
	BaseNameForForm = ThisDataProcessor.BaseNameForForm();
	
	CurrentSettingsItemPresentation = "";
	Items.FiltersSettings.Visible = AccessRight("SaveUserData", Metadata);
	
	ResetTableCountLabel();
	UpdateTotalCountLabel();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	StopCountCalcultion();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdditionalRegistrationChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.AdditionalRegistrationFilterAsString Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	CurrentData = Items.AdditionalRegistration.CurrentData;
	
	NameOfFormToOpen = BaseNameForForm + "Form.PeriodAndFilterEdit";
	FormParameters = New Structure;
	FormParameters.Insert("Title",           CurrentData.Presentation);
	FormParameters.Insert("ChoiceAction",      - Items.AdditionalRegistration.CurrentRow);
	FormParameters.Insert("SelectPeriod",        CurrentData.SelectPeriod);
	FormParameters.Insert("SettingsComposer", SettingsComposerByTableName(CurrentData.FullMetadataName, CurrentData.Presentation, CurrentData.Filter));
	FormParameters.Insert("DataPeriod",        CurrentData.Period);
	
	FormParameters.Insert("FromStorageAddress", UUID);
	
	OpenForm(NameOfFormToOpen, FormParameters, Items.AdditionalRegistration);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
	If Clone Then
		Return;
	EndIf;
	
	OpenForm(BaseNameForForm + "Form.SelectNodeCompositionObjectKind",
		New Structure("InfobaseNode", Object.InfobaseNode),
		Items.AdditionalRegistration);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeDelete(Item, Cancel)
	Selected = Items.AdditionalRegistration.SelectedRows;
	Count = Selected.Count();
	If Count>1 Then
		PresentationText = NStr("ru='выбранные строки'; en = 'the selected lines'; pl = 'Wybór i ustawienia';de = 'Ausgewählte Zeilen';ro = 'rândurile selectate';tr = 'Seçilen satırlar'; es_ES = 'Líneas seleccionadas'");
	ElsIf Count=1 Then
		PresentationText = Items.AdditionalRegistration.CurrentData.Presentation;
	Else
		Return;
	EndIf;
	
	// The AdditionalRegistrationBeforeDeleteEnd procedure is called from the user confirmation dialog.
	Cancel = True;
	
	QuestionText = NStr("ru='Удалить из дополнительных данных %1 ?'; en = 'Do you want to delete %1 from the additional data?'; pl = 'Usunąć z dodatkowych danych %1 ?';de = 'Löschen von zusätzlichen Daten %1 ?';ro = 'Ștergeți din datele suplimentare %1?';tr = 'Ek verilerden %1 silinsin mi?'; es_ES = '¿Borrar de los datos adicionales %1 ?'");    
	QuestionText = StrReplace(QuestionText, "%1", PresentationText);
	
	QuestionTitle = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	
	Notification = New NotifyDescription("AdditionalRegistrationBeforeDeleteEnd", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("SelectedRows", Selected);
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

&AtClient
Procedure AdditionalRegistrationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	SelectedValueType = TypeOf(ValueSelected);
	If SelectedValueType=Type("Array") Then
		// Adding new row
		Items.AdditionalRegistration.CurrentRow = AddingRowToAdditionalCompositionServer(ValueSelected);
		
	ElsIf SelectedValueType= Type("Structure") Then
		If ValueSelected.ChoiceAction=3 Then
			// Restoring settings
			SettingPresentation = ValueSelected.SettingPresentation;
			If Not IsBlankString(CurrentSettingsItemPresentation) AND SettingPresentation<>CurrentSettingsItemPresentation Then
				QuestionText  = NStr("ru='Восстановить настройки ""%1""?'; en = 'Do you want to restore ""%1"" settings?'; pl = 'Przywróć ustawienia ""%1""?';de = 'Einstellungen wiederherstellen ""%1""?';ro = 'Restabiliți setările ""%1""?';tr = 'Ayarları eski haline getir ""%1""?'; es_ES = '¿Restablecer las configuraciones ""%1""?'");
				QuestionText  = StrReplace(QuestionText, "%1", SettingPresentation);
				TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
				
				Notification = New NotifyDescription("AdditionalRegistrationChoiceProcessingEnd", ThisObject, New Structure);
				Notification.AdditionalParameters.Insert("SettingPresentation", SettingPresentation);
				
				ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , , TitleText);
			Else
				CurrentSettingsItemPresentation = SettingPresentation;
			EndIf;
		Else
			// Editing filter condition, negative line number.
			Items.AdditionalRegistration.CurrentRow = FilterStringEditingAdditionalCompositionServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalRegistrationAfterDeleteLine(Item)
	UpdateTotalCountLabel();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ConfirmSelection(Command)
	NotifyChoice( ChoiseResultServer() );
EndProcedure

&AtClient
Procedure ShowCommonParametersText(Command)
	OpenForm(BaseNameForForm +  "Form.CommonSynchronizationSettings",
		New Structure("InfobaseNode", Object.InfobaseNode));
EndProcedure

&AtClient
Procedure ExportComposition(Command)
	OpenForm(BaseNameForForm + "Form.ExportComposition",
		New Structure("ObjectAddress", AdditionalExportObjectAddress() ));
EndProcedure

&AtClient
Procedure RefreshCountClient(Command)
	
	Result = UpdateCountServer();
	
	If Result.Status = "Running" Then
		
		Items.CountCalculationPicture.Visible = True;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		CompletionNotification = New NotifyDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
		
	Else
		AttachIdleHandler("ImportQuantityValuesCLient", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure FiltersSettings(Command)
	
	// Select from the list menu
	VariantList = ReadSettingsVariantListServer();
	
	Text = NStr("ru='Сохранить текущую настройку...'; en = 'Save current setting...'; pl = 'Zapisuję bieżącą konfigurację...';de = 'Die aktuelle Konfiguration speichern...';ro = 'Salvați setarea curentă...';tr = 'Mevcut ayarlar kaydediliyor...'; es_ES = 'Guardando la configuración actual...'");
	VariantList.Add(1, Text, , PictureLib.SaveReportSettings);
	
	Notification = New NotifyDescription("FiltersSettingsOptionSelectionCompletion", ThisObject);
	
	ShowChooseFromMenu(Notification, VariantList, Items.FiltersSettings);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportQuantityValuesCLient()
	Items.CountCalculationPicture.Visible = False;
	ImportCountsValuesServer();
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	ImportQuantityValuesCLient();
EndProcedure

&AtClient
Procedure FiltersSettingsOptionSelectionCompletion(Val SelectedItem, Val AdditionalParameters) Export
	If SelectedItem = Undefined Then
		Return;
	EndIf;
		
	SettingPresentation = SelectedItem.Value;
	If TypeOf(SettingPresentation)=Type("String") Then
		TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
		QuestionText   = NStr("ru='Восстановить настройки ""%1""?'; en = 'Do you want to restore ""%1"" settings?'; pl = 'Przywróć ustawienia ""%1""?';de = 'Einstellungen wiederherstellen ""%1""?';ro = 'Restabiliți setările ""%1""?';tr = 'Ayarları eski haline getir ""%1""?'; es_ES = '¿Restablecer las configuraciones ""%1""?'");
		QuestionText   = StrReplace(QuestionText, "%1", SettingPresentation);
		
		Notification = New NotifyDescription("FilterSettingsCompletion", ThisObject, New Structure);
		Notification.AdditionalParameters.Insert("SettingPresentation", SettingPresentation);
		
		ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , , TitleText);
		
	ElsIf SettingPresentation=1 Then
		
		// Form that displays all settings.
		
		SettingsFormParameters = New Structure;
		SettingsFormParameters.Insert("CloseOnChoice", True);
		SettingsFormParameters.Insert("ChoiceAction", 3);
		SettingsFormParameters.Insert("Object", Object);
		SettingsFormParameters.Insert("CurrentSettingsItemPresentation", CurrentSettingsItemPresentation);
		
		SettingsFormName = BaseNameForForm + "Form.SettingsCompositionEdit";
		
		OpenForm(SettingsFormName, SettingsFormParameters, Items.AdditionalRegistration);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterSettingsCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetSettingsServer(AdditionalParameters.SettingPresentation);
EndProcedure

&AtClient
Procedure AdditionalRegistrationChoiceProcessingEnd(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetSettingsServer(AdditionalParameters.SettingPresentation);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeDeleteEnd(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeletionTable = Object.AdditionalRegistration;
	SubjectToDeletion = New Array;
	For Each RowID In AdditionalParameters.SelectedRows Do
		RowToDelete = DeletionTable.FindByID(RowID);
		If RowToDelete<>Undefined Then
			SubjectToDeletion.Add(RowToDelete);
		EndIf;
	EndDo;
	For Each RowToDelete In SubjectToDeletion Do
		DeletionTable.Delete(RowToDelete);
	EndDo;
	
	UpdateTotalCountLabel();
EndProcedure

&AtServer
Function ChoiseResultServer()
	ObjectResult = New Structure("InfobaseNode, ExportOption, AllDocumentsFilterComposer, AllDocumentsFilterPeriod");
	FillPropertyValues(ObjectResult, Object);
	
	ObjectResult.Insert("AdditionalRegistration", 
		TableIntoStrucrureArray( FormAttributeToValue("Object.AdditionalRegistration")) );
	
	Return New Structure("ChoiceAction, ObjectAddress", 
		Parameters.ChoiceAction, PutToTempStorage(ObjectResult, UUID));
EndFunction

&AtServer
Function TableIntoStrucrureArray(Val ValueTable)
	Result = New Array;
	
	ColumnsNames = "";
	For Each Column In ValueTable.Columns Do
		ColumnsNames = ColumnsNames + "," + Column.Name;
	EndDo;
	ColumnsNames = Mid(ColumnsNames, 2);
	
	For Each Row In ValueTable Do
		StringStructure = New Structure(ColumnsNames);
		FillPropertyValues(StringStructure, Row);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ThisObject(NewObject = Undefined)
	If NewObject=Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(NewObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Function AddingRowToAdditionalCompositionServer(ChoiseArray)
	
	If ChoiseArray.Count()=1 Then
		Row = AddToAdditionalExportComposition(ChoiseArray[0]);
	Else
		Row = Undefined;
		For Each ChoiceItem In ChoiseArray Do
			TestRow = AddToAdditionalExportComposition(ChoiceItem);
			If Row=Undefined Then
				Row = TestRow;
			EndIf;
		EndDo;
	EndIf;
	
	Return Row;
EndFunction

&AtServer 
Function FilterStringEditingAdditionalCompositionServer(ChoiceStructure)
	
	CurrentData = Object.AdditionalRegistration.FindByID(-ChoiceStructure.ChoiceAction);
	If CurrentData=Undefined Then
		Return Undefined
	EndIf;
	
	CurrentData.Period       = ChoiceStructure.DataPeriod;
	CurrentData.Filter        = ChoiceStructure.SettingsComposer.Settings.Filter;
	CurrentData.FilterString = FilterPresentation(CurrentData.Period, CurrentData.Filter);
	CurrentData.Count   = NStr("ru='Не рассчитано'; en = 'Not calculated'; pl = 'Nie obliczone';de = 'Nicht berechnet';ro = 'Nu se calculează';tr = 'Hesaplanmadı'; es_ES = 'No calculado'");
	
	UpdateTotalCountLabel();
	
	Return ChoiceStructure.ChoiceAction;
EndFunction

&AtServer
Function AddToAdditionalExportComposition(Item)
	
	ExistingRows = Object.AdditionalRegistration.FindRows( 
		New Structure("FullMetadataName", Item.FullMetadataName));
	If ExistingRows.Count()>0 Then
		Row = ExistingRows[0];
	Else
		Row = Object.AdditionalRegistration.Add();
		FillPropertyValues(Row, Item,,"Presentation");
		
		Row.Presentation = Item.ListPresentation;
		Row.FilterString  = FilterPresentation(Row.Period, Row.Filter);
		Object.AdditionalRegistration.Sort("Presentation");
		
		Row.Count = NStr("ru='Не рассчитано'; en = 'Not calculated'; pl = 'Nie obliczone';de = 'Nicht berechnet';ro = 'Nu se calculează';tr = 'Hesaplanmadı'; es_ES = 'No calculado'");
		UpdateTotalCountLabel();
	EndIf;
	
	Return Row.GetID();
EndFunction

&AtServer
Function FilterPresentation(Period, Filter)
	Return ThisObject().FilterPresentation(Period, Filter);
EndFunction

&AtServer
Function SettingsComposerByTableName(TableName, Presentation, Filter)
	Return ThisObject().SettingsComposerByTableName(TableName, Presentation, Filter, UUID);
EndFunction

&AtServer
Procedure StopCountCalcultion()
	
	TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
	If Not IsBlankString(BackgroundJobResultAddress) Then
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	
	BackgroundJobResultAddress = "";
	BackgroundJobID   = Undefined;
	
EndProcedure

&AtServer
Function UpdateCountServer()
	
	StopCountCalcultion();
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorStructure", ThisObject().ThisObjectInStructureForBackgroundJob());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = 
		NStr("ru='Расчет количества объектов для отправки при синхронизации'; en = 'Calculate the number of objects to send during synchronization'; pl = 'Obliczenie liczby obiektów do wysłania podczas synchronizacji';de = 'Berechnen der Anzahl der Objekte, die während der Synchronisation gesendet werden sollen';ro = 'Calculul numărului de obiecte pentru trimitere la sincronizare';tr = 'Senkronizasyon sırasında gönderilecek nesnelerin sayısının hesaplanması'; es_ES = 'Calculando el número de objetos para enviar durante la sincronización'");

	BackgroundJobStartResult = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeServer.InteractiveExportModification_GenerateValueTree",
		JobParameters,
		ExecutionParameters);
		
	BackgroundJobID   = BackgroundJobStartResult.JobID;
	BackgroundJobResultAddress = BackgroundJobStartResult.ResultAddress;
	
	Return BackgroundJobStartResult;
	
EndFunction

&AtServer
Procedure ImportCountsValuesServer()
	
	CountTree = Undefined;
	If Not IsBlankString(BackgroundJobResultAddress) Then
		CountTree = GetFromTempStorage(BackgroundJobResultAddress);
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	If TypeOf(CountTree) <> Type("ValueTree") Then
		CountTree = New ValueTree;
	EndIf;
	
	If CountTree.Rows.Count() = 0 Then
		UpdateTotalCountLabel(Undefined);
		Return;
	EndIf;
	
	ThisDataProcessor = ThisObject();
	
	CountRows = CountTree.Rows;
	For Each Row In Object.AdditionalRegistration Do
		
		TotalQuantity = 0;
		CountExport = 0;
		StringComposition = ThisDataProcessor.EnlargedMetadataGroupComposition(Row.FullMetadataName);
		For Each TableName In StringComposition Do
			DataString = CountRows.Find(TableName, "FullMetadataName", False);
			If DataString <> Undefined Then
				CountExport = CountExport + DataString.ToExportCount;
				TotalQuantity     = TotalQuantity     + DataString.CommonCount;
			EndIf;
		EndDo;
		
		Row.Count = Format(CountExport, "NZ=") + " / " + Format(TotalQuantity, "NZ=");
	EndDo;
	
	// Grand totals
	DataString = CountRows.Find(Undefined, "FullMetadataName", False);
	UpdateTotalCountLabel(?(DataString = Undefined, Undefined, DataString.ToExportCount));
	
EndProcedure

&AtServer
Procedure UpdateTotalCountLabel(Count = Undefined) 
	
	StopCountCalcultion();
	
	If Count = Undefined Then
		CountText = NStr("ru='<не рассчитано>'; en = '<not calculated>'; pl = '<nie obliczone>';de = '<nicht berechnet>';ro = '<nu se calculează>';tr = '<hesaplanmadı>'; es_ES = '<no calculado>'");
	Else
		CountText = NStr("ru = 'Объектов: %1'; en = 'Objects: %1'; pl = 'Obiekty: %1';de = 'Objekte: %1';ro = 'Obiecte: %1';tr = 'Nesneler: %1'; es_ES = 'Objetos: %1'");
		CountText = StrReplace(CountText, "%1", Format(Count, "NZ="));
	EndIf;
	
	Items.UpdateCount.Title  = CountText;
EndProcedure

&AtServer
Procedure ResetTableCountLabel()
	CountsText = NStr("ru='Не рассчитано'; en = 'Not calculated'; pl = 'Nie obliczone';de = 'Nicht berechnet';ro = 'Nu se calculează';tr = 'Hesaplanmadı'; es_ES = 'No calculado'");
	For Each Row In Object.AdditionalRegistration Do
		Row.Count = CountsText;
	EndDo;
	Items.CountCalculationPicture.Visible = False;
EndProcedure

&AtServer
Function ReadSettingsVariantListServer()
	VariantFilter = New Array;
	VariantFilter.Add(Object.ExportOption);
	
	Return ThisObject().ReadSettingsListPresentations(Object.InfobaseNode, VariantFilter);
EndFunction

&AtServer
Procedure SetSettingsServer(SettingPresentation)
	
	ConstantData = New Structure("InfobaseNode, ExportOption, AllDocumentsFilterComposer, AllDocumentsFilterPeriod");
	FillPropertyValues(ConstantData, Object);
	
	ThisDataProcessor = ThisObject();
	ThisDataProcessor.RestoreCurrentAttributesFromSettings(SettingPresentation);
	ThisObject(ThisDataProcessor);
	
	FillPropertyValues(Object, ConstantData);
	
	ResetTableCountLabel();
	UpdateTotalCountLabel();
EndProcedure

&AtServer
Function AdditionalExportObjectAddress()
	Return ThisObject().SaveThisObject(UUID);
EndFunction

#EndRegion
