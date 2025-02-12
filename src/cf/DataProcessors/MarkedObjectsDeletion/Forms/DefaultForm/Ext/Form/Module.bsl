﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.IsFullUser() Then
		ErrorText = NStr("ru = 'Недостаточно прав для выполнения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Niewystarczające uprawnienia do wykonania operacji.';de = 'Unzureichende Rechte zum Ausführen der Operation.';ro = 'Drepturi suficiente pentru a efectua operațiunea.';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación.'");
		Return; // Cancel is set in OnOpen.
	EndIf;
	
	If Common.DataSeparationEnabled()
		AND Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = NStr("ru = 'Для удаления помеченных необходимо войти в область данных.'; en = 'Sign in to a data area for deleting marked objects.'; pl = 'Aby usunąć zaznaczone elementy, wejdź do obszaru danych.';de = 'Um markierte Objekte zu löschen, geben Sie den Datenbereich ein.';ro = 'Pentru a șterge cele marcate, intrați în domeniul de date.';tr = 'Işaretlenenleri silmek için veri alanına girilmelidir.'; es_ES = 'Para borrar los artículos marcados, introducir el área de datos.'");
		Return; // Cancel is set in OnOpen.
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectDetection") Then
		Items.NotDeletedItemsReplaceWith.Visible = False;
		Items.NotDeletedItemsReplaceWithFromMenu.Visible = False;
	EndIf;
	
	ScheduledJob = ScheduledJobsFindPredefinedItem();
	
	CheckBoxVisibility = (ScheduledJob <> Undefined);
	If CheckBoxVisibility Then
		DeleteMarkedObjectsID = ScheduledJob.UUID;
		DeleteMarkedObjectsUsage = ScheduledJob.Use;
		DeleteMarkedObjectsSchedule    = ScheduledJob.Schedule;
	EndIf;
	
	ScheduleVisibility = CheckBoxVisibility
		AND Not Common.DataSeparationEnabled()
		AND Users.IsFullUser(, True);
	
	Items.DeleteMarkedObjectsUsage.Visible           = CheckBoxVisibility;
	Items.DeleteMarkedObjectsConfigureSchedule.Visible     = ScheduleVisibility;
	Items.DeleteMarkedObjectsSchedulePresentation.Visible = ScheduleVisibility;
	If Not ScheduleVisibility Then 
		Items.DeleteMarkedObjectsUsage.Title = NStr("ru = 'Автоматически удалять помеченные объекты'; en = 'Automatically delete marked objects'; pl = 'Automatycznie usuwać zaznaczone obiekty';de = 'Markierte Objekte automatisch löschen';ro = 'Șterge automat obiectele marcate';tr = 'Işaretli nesneleri otomatik olarak sil.'; es_ES = 'Eliminar automáticamente los objetos marcados'");
	EndIf;
	
	SetAvailability();
	
	QuickSearch = New Structure;
	QuickSearch.Insert("FullMetadataObjectsNames", New Map);
	
	Exclusive = True;
	DeletionMode = "Full";
	SetDataProcessorNoteTextOnCreateAtServer();
	VisibleEnabled(ThisObject);
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(ErrorText) Then
		ShowMessageBox(, ErrorText);
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ShowDialogBeforeClose Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Удаление помеченных еще выполняется.
		|Прервать?'; 
		|en = 'Deletion of marked objects is in progress.
		|Stop?'; 
		|pl = 'Trwa jeszcze usuwanie zaznaczonych.
		|Czy chcesz przerwać?';
		|de = 'Die markierten werden noch gelöscht. 
		|Wollen Sie abbrechen?';
		|ro = 'Încă se execută ștergerea celor marcate.
		|Doriți să renunțați?';
		|tr = 'İşaretli olanlar silinmeye devam ediyor.
		|İptal edilsin mi?'; 
		|es_ES = 'Los marcados aún se están borrando.
		|¿Quiere anular?'");
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Abort);
	Buttons.Add(DialogReturnCode.Ignore, NStr("ru = 'Не прерывать'; en = 'Do not stop'; pl = 'Nie przerywać';de = 'Nicht unterbrechen';ro = 'Nu întrerupe';tr = 'Kesme'; es_ES = 'No interrumpir'"));
	Handler = New NotifyDescription("AfterConfirmCancelJob", ThisObject);
	ShowQueryBox(Handler, QuestionText, Buttons, 60, DialogReturnCode.Ignore);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeletionModeOnChange(Item)
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure DataProcessorNoteURLProcessing(Item, Ref, StandardProcessing)
	StandardProcessing = False;
	FormParameters = New Structure("ApplicationNameFilter", "1CV8,1CV8C,WebClient");
	StandardSubsystemsClient.OpenActiveUserList(FormParameters);
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, DetailedErrorText);
EndProcedure

&AtClient
Procedure DeleteMarkedObjectsUseOnChange(Item)
	If DeleteMarkedObjectsUsage AND Items.DeleteMarkedObjectsSchedulePresentation.Visible Then
		If Items.DeleteMarkedObjectsSchedulePresentation.Visible Then
			ScheduledJobsChangeSchedule();
			Return;
		EndIf;
	EndIf;
	Changes = New Structure("Use", DeleteMarkedObjectsUsage);
	ScheduledJobsSave(Changes);
EndProcedure

#EndRegion

#Region MarkedForDeletionItemsTreeFormTableItemsEventHandlers

&AtClient
Procedure MarkedForDeletionItemsTreeMarkOnChange(Item)
	CurrentData = Items.MarkedForDeletionItemsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	MarkedForDeletionItemsTreeSetMarkInList(CurrentData, CurrentData.Check, True);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region NotDeletedItemsFormTableItemsEventHandlers

&AtClient
Procedure NotDeletedItemsOnActivateRow(Item)
	AttachIdleHandler("ShowNotDeletedItemsLinksAtClient", 0.1, True);
EndProcedure

&AtClient
Procedure NotDeletedItemsBeforeRowChange(Item, Cancel)
	Cancel = True;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsBeforeDelete(Item, Cancel)
	Cancel = True;
	MarkSelectedTableObjectsForDeletion(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsPresentationOpen(Item, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region NotDeletedItemsLinksFormTableItemsEventHandlers

&AtClient
Procedure NotDeletedItemsLinksBeforeRowChange(Item, Cancel)
	Cancel = True;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsLinksBeforeDelete(Item, Cancel)
	Cancel = True;
	MarkSelectedTableObjectsForDeletion(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsLinksChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextCommand(Command)
	RunBackgroundJobClient(1);
EndProcedure

&AtClient
Procedure BackCommand(Command)
	Items.Pages.CurrentPage = Items.DeletionModeSelectionPage;
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeSelectAll(Command)
	
	ListItems = MarkedForDeletionItemsTree.GetItems();
	For Each Item In ListItems Do
		MarkedForDeletionItemsTreeSetMarkInList(Item, True, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			MarkedForDeletionItemsTreeCheckParent(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeClearAll(Command)
	
	ListItems = MarkedForDeletionItemsTree.GetItems();
	For Each Item In ListItems Do
		MarkedForDeletionItemsTreeSetMarkInList(Item, False, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			MarkedForDeletionItemsTreeCheckParent(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeChange(Command)
	ShowTableObject(Items.MarkedForDeletionItemsTree);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeUpdate(Command)
	RunBackgroundJobClient(2);
EndProcedure

&AtClient
Procedure NotDeletedItemsReplaceWith(Command)
	IDsArray = Items.NotDeletedItems.SelectedRows;
	If IDsArray.Count() = 0 Then
		Return;
	EndIf;
	
	RefsArray = New Array;
	For Each ID In IDsArray Do
		TableRow = NotDeletedItems.FindByID(ID);
		If TypeOf(TableRow.ItemToDeleteRef) = Type("String") Then
			Continue; // Skip groups
		EndIf;
		RefsArray.Add(TableRow.ItemToDeleteRef);
	EndDo;
	
	If RefsArray.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Выберите объекты'; en = 'Select objects'; pl = 'Wybierz obiekty';de = 'Wählen Sie Objekte aus';ro = 'Selectați obiecte';tr = 'Nesneleri seç'; es_ES = 'Seleccionar objetos'"));
		Return;
	EndIf;
	
	// The subsystem is checked in OnCreateAtServer.
	ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("FindAndDeleteDuplicatesDuplicatesClient");
	ModuleDuplicateObjectsDetectionClient.ReplaceSelected(RefsArray);
EndProcedure

&AtClient
Procedure NotDeletedItemsDelete(Command)
	MarkSelectedTableObjectsForDeletion(Items.NotDeletedItems);
EndProcedure

&AtClient
Procedure NotDeletedItemsLinksDelete(Command)
	MarkSelectedTableObjectsForDeletion(Items.NotDeletedItemRelations);
EndProcedure

&AtClient
Procedure DeleteMarkedObjectsConfigureSchedule(Command)
	ScheduledJobsChangeSchedule();
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure ShowNotDeletedItemsLinksAtClient()
	If NotDeletedItemsCurrentRowID = Items.NotDeletedItems.CurrentRow Then
		Return;
	EndIf;
	ShowNotDeletedItemsLinksAtServer();
EndProcedure

&AtServer
Procedure ShowNotDeletedItemsLinksAtServer()
	NotDeletedItemsCurrentRowID = Items.NotDeletedItems.CurrentRow;
	If NotDeletedItemsCurrentRowID = Undefined Then
		TreeRow = Undefined;
	Else
		TreeRow = NotDeletedItems.FindByID(NotDeletedItemsCurrentRowID);
	EndIf;
	ShowErrorText = True;
	ErrorText = "";
	DetailedErrorText = "";
	If TreeRow = Undefined Or TreeRow.PictureNumber < 1 Then
		// Nothing or a group is selected.
		NotDeletedItemsTooltip = NStr("ru = 'Выберите объект, чтобы узнать причину,
		|по которой его не удалось удалить.'; 
		|en = 'Select an object to find out the reason
		|why it cannot be deleted.'; 
		|pl = 'Wybierz obiekt, aby dowiedzieć się 
		| z jakiej przyczyny jego nie udało się usunąć.';
		|de = 'Wählen Sie ein Objekt aus, um herauszufinden, 
		|warum es nicht gelöscht wurde.';
		|ro = 'Selectați obiectul pentru a determina motivul
		|pentru care nu a fost șters.';
		|tr = 'Nesnenin silinememesinin nedenini öğrenmek için nesneyi seçin
		|.'; 
		|es_ES = 'Seleccionar el objeto para determinar el motivo
		| por qué se ha fallado a borrarse.'");
	Else
		// Reference to a not deleted object is selected.
		ItemsToHide = NotDeletedItemRelations.FindRows(New Structure("Visible", True));
		For Each TableRow In ItemsToHide Do
			TableRow.Visible = False;
		EndDo;
		
		Items.NotDeletedItemRelations.RowFilter = New FixedStructure("ItemToDeleteRef", TreeRow.ItemToDeleteRef);
		NotDeletedItemsTooltip = " ";
		ItemsToShow = NotDeletedItemRelations.FindRows(New Structure("ItemToDeleteRef", TreeRow.ItemToDeleteRef));
		For Each TableRow In ItemsToShow Do
			TableRow.Visible = True;
			If TableRow.IsError Then
				ErrorText = TableRow.FoundItemReference;
				DetailedErrorText = TableRow.Presentation;
			Else
				If ShowErrorText Then
					Items.NotDeletedItemRelations.CurrentRow = TableRow.GetID();
					ShowErrorText = False;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If ShowErrorText Then
		CurrentPage = Items.ErrorTextPage;
		Items.DetailsRef.Visible = ValueIsFilled(DetailedErrorText);
		Items.ErrorText.Title = ErrorText;
	Else
		CurrentPage = Items.ReasonsForNotDeletionPage;
		Template = NStr("ru = 'Места использования объекта ""%1"" (%2):'; en = 'Usage locations of object ""%1"" (%2):'; pl = 'Lokalizacje korzystania z obiektu ""%1"" (%2):';de = 'Verwendungsorte des Objekts ""%1"" (%2):';ro = 'Utilizarea locațiilor obiectului ""%1"" (%2):';tr = 'Nesnenin kullanım yerleri ""%1"" (%2):'; es_ES = 'Ubicaciones de uso del objeto ""%1"" (%2):'");
		NotDeletedItemsTooltip = StringFunctionsClientServer.SubstituteParametersToString(Template, TreeRow.Presentation, Format(TreeRow.LinkCount, "NZ=0; NG="));
	EndIf;
	If Items.ReasonsDisplayOptionsPages.CurrentPage <> CurrentPage Then
		Items.ReasonsDisplayOptionsPages.CurrentPage = CurrentPage;
	EndIf;
EndProcedure

&AtClient
Procedure ShowTableObject(TableItem)
	TableRow = TableItem.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	Value = Undefined;
	If Not TableRow.Property("Value", Value)
		AND Not TableRow.Property("FoundItemReference", Value)
		AND Not TableRow.Property("ItemToDeleteRef", Value) Then
		Return;
	EndIf;
	
	If TypeOf(Value) = Type("String") Then
		If TableRow.Property("IsConstant") AND TableRow.IsConstant Then
			FormPath = Value + ".ConstantsForm";
		Else
			FormPath = Value + ".ListForm";
		EndIf;
		OpenForm(FormPath);
	Else
		ShowValue(, Value);
	EndIf;
EndProcedure

&AtClient
Procedure MarkSelectedTableObjectsForDeletion(TableItem)
	Var Value;
	
	IDsArray = TableItem.SelectedRows;
	CountSelected = IDsArray.Count();
	If CountSelected = 0 Then
		Return;
	EndIf;
	
	TableName = TableItem.Name;
	If TableName = "MarkedForDeletionItemsTree" Then
		ValueAttributeName = "Value";
		AreNotDeletedItemsLinks = False;
	ElsIf TableName = "NotDeletedItems" Then
		ValueAttributeName = "ItemToDeleteRef";
		AreNotDeletedItemsLinks = False;
	ElsIf TableName = "NotDeletedItemRelations" Then
		ValueAttributeName = "FoundItemReference";
		AreNotDeletedItemsLinks = True;
	EndIf;
	
	TableAttribute = ThisObject[TableName];
	TableRowsArray = New Array;
	ArrayOfReferencesToItemsMarkedForDeletion = New Array;
	ArrayOfReferencesToObjectsNotMarkedForDeletion = New Array;
	SetMark = False;
	HasRegistersRecords = False;
	HasConstants = False;
	For Each ID In IDsArray Do
		TableRow = TableAttribute.FindByID(ID);
		If AreNotDeletedItemsLinks Then
			If Not TableRow.Visible Then
				Continue; // Bypass specifics with CTRL + A.
			ElsIf TableRow.IsConstant Then
				HasConstants = True;
				Continue;
			ElsIf Not TableRow.ReferenceType Then
				HasRegistersRecords = True;
				Continue;
			EndIf;
		EndIf;
		TableRow.Property(ValueAttributeName, Value);
		If TypeOf(Value) = Type("String") Then
			CountSelected = CountSelected - 1; // Do not consider groups as selected.
			Continue; // Skip groups
		EndIf;
		If TableRow.DeletionMark Then
			ArrayOfReferencesToItemsMarkedForDeletion.Add(Value);
		Else
			SetMark = True;
			ArrayOfReferencesToObjectsNotMarkedForDeletion.Add(Value);
		EndIf;
		If TypeOf(TableAttribute) = Type("FormDataCollection") Then
			FoundItems = TableAttribute.FindRows(New Structure(ValueAttributeName, Value));
			For Each RowByReference In FoundItems Do
				TableRowsArray.Add(RowByReference);
			EndDo;
		Else
			TableRowsArray.Add(TableRow);
		EndIf;
	EndDo;
	
	RefsArray = ?(SetMark, ArrayOfReferencesToObjectsNotMarkedForDeletion, ArrayOfReferencesToItemsMarkedForDeletion);
	CountCanDelete = RefsArray.Count();
	If CountCanDelete = 0 Then
		ErrorText = NStr("ru = 'Выберите объект.'; en = 'Select an object.'; pl = 'Wybierz obiekt.';de = 'Wählen Sie ein Objekt aus.';ro = 'Selectați obiectul.';tr = 'Nesneyi seçin.'; es_ES = 'Seleccionar el objeto.'");
		If CountSelected = 1 Then
			If HasRegistersRecords Then
				ErrorText = NStr("ru = 'Удаление записи регистра выполняется из ее карточки.'; en = 'A register record can be deleted only from its card.'; pl = 'Usuwane wpisu rejestru jest wykonywane z jego karty.';de = 'Registersätze werden von ihren Karten gelöscht.';ro = 'Înregistrarea din registru se șterge din fișa acesteia.';tr = 'Sicil kaydının silinmesi kartından yapılır.'; es_ES = 'Grabaciones del registro se han borrado de sus tarjetas.'");
			ElsIf HasConstants Then
				ErrorText = NStr("ru = 'Очистка значения константы выполняется из ее карточки.'; en = 'A constant value can be cleared only from its card.'; pl = 'Została oczyszczona stała wartość z jego karty.';de = 'Der konstante Wert wird von seiner Karte bereinigt.';ro = 'Valoarea constantei se golește din fișa acesteia.';tr = 'Sabit değeri temizleme kartından yapılır.'; es_ES = 'Valor constante se ha eliminado de su tarjeta.'");
			EndIf;
		Else
			If HasRegistersRecords Or HasConstants Then
				ErrorText = NStr("ru = 'Удаление записей регистров или очистка значений констант выполняется из их карточек.'; en = 'Register record deletion or constant value cleanup is carried out from their cards.'; pl = 'Usuwane wpisów rejestrów albo oczyszczanie wartości stałych odbywa się z ich kart.';de = 'Das Löschen von Registerdatensätzen oder das Bereinigen von konstanten Werten wird von ihren Karten ausgeführt.';ro = 'Înregistrarea ștergerii sau curățarea valorii constante se efectuează din cărțile lor.';tr = 'Kayıt silme veya sabit değer temizleme kartlarından gerçekleştirilir.'; es_ES = 'Eliminación de grabaciones del registro o la eliminación del valor constante se ha llevado a cabo desde sus tarjetas.'");
			EndIf;
		EndIf;
		ShowMessageBox(, ErrorText);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("TableName", TableName);
	ExecutionParameters.Insert("TableRowsArray", TableRowsArray);
	ExecutionParameters.Insert("RefsArray", RefsArray);
	ExecutionParameters.Insert("ValueAttributeName", ValueAttributeName);
	ExecutionParameters.Insert("SetMark", SetMark);
	
	Handler = New NotifyDescription("MarkSelectedTableObjectsForDeletionCompletion", ThisObject, ExecutionParameters);
	
	If CountCanDelete = 1 Then
		If SetMark Then
			QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
		Else
			QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to clear a deletion mark for ""%1""?'; pl = 'Oczyścić znacznik usunięcia dla ""%1""?';de = 'Löschzeichen für ""%1"" löschen?';ro = 'Scoateți marcajul la ștergere de pe ""%1""?';tr = '""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Eliminar la marca para borrar para ""%1""?'");
		EndIf;
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, TableRowsArray[0].Presentation);
	Else
		If SetMark Then
			QuestionText = NStr("ru = 'Пометить выделенные объекты (%1) на удаление?'; en = 'Do you want to mark the selected objects (%1) for deletion?'; pl = 'Zaznaczyć wybrane obiekty (%1) do usunięcia?';de = 'Markieren Sie die ausgewählten Objekte (%1) zum Löschen?';ro = 'Marcați obiectele selectate (%1) pentru ștergere?';tr = 'Işaretlenmiş nesneler (%1) silinecek olarak işaretlensin mi?'; es_ES = '¿Marcar los objetos seleccionado (%1) para borrar?'");
		Else
			QuestionText = NStr("ru = 'Снять с выделенных объектов (%1) пометку на удаление?'; en = 'Do you want to clear deletion marks for the selected objects (%1)?'; pl = 'Oczyścić zaznaczenia wybranych do usunięcia obiektów (%1)?';de = 'Löschmarkierungen für die ausgewählten Objekte löschen (%1)?';ro = 'Eliminați marcajele la ștergere de pe obiectele selectate (%1)?';tr = 'Seçilmiş nesnelerden ""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Quitar las marcas de borrado para los objetos seleccionados (%1)?'");
		EndIf;
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Format(CountCanDelete, "NZ=0; NG="));
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes);
	Buttons.Add(DialogReturnCode.No);
	
	ShowQueryBox(Handler, QuestionText, Buttons, 60, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure MarkSelectedTableObjectsForDeletionCompletion(Response, ExecutionParameters) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ChangesNotification = ChangeObjectsDeletionMark(ExecutionParameters.RefsArray, ExecutionParameters.SetMark);
	
	ObjectsCount = ExecutionParameters.RefsArray.Count();
	If ObjectsCount > 0 Then
		StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "NotDeletedItems", "*", True);
	EndIf;
	
	StandardSubsystemsClient.NotifyFormsAboutChange(ChangesNotification,
		New Structure("DeletionMark", ExecutionParameters.SetMark));
	
	NotificationText = Undefined;
	NotificationRef = Undefined;
	If ObjectsCount = 0 Then
		NotificationTitle = NStr("ru = 'Объект не найден'; en = 'Object not found'; pl = 'Obiekt nie został znaleziony';de = 'Objekt wird nicht gefunden';ro = 'Obiectul nu a fost găsit';tr = 'Nesne bulunamadı'; es_ES = 'Objeto no encontrado'");
	Else
		If ExecutionParameters.SetMark Then
			NotificationTitle = NStr("ru = 'Пометка удаления установлена'; en = 'Deletion mark set'; pl = 'Znacznik usunięcia jest zaznaczony';de = 'Löschzeichen ist ausgewählt';ro = 'Marcajul la ștergere este setat';tr = 'Silme işareti yerleştirildi'; es_ES = 'Marca de borrado se ha seleccionado'");
		Else
			NotificationTitle = NStr("ru = 'Пометка удаления снята'; en = 'Deletion mark cleared'; pl = 'Znacznik usunięcia zostanie oczyszczony';de = 'Löschzeichen ist gelöscht';ro = 'Marcajul la ștergere este scos';tr = 'Silme işareti kaldırıldı'; es_ES = 'Marca de borrado se ha quitado'");
		EndIf;
		If ObjectsCount = 1 Then
			NotificationRef = ExecutionParameters.RefsArray[0];
			NotificationText  = String(NotificationRef);
		Else
			NotificationTitle = NotificationTitle + " (" + Format(ObjectsCount, "NZ=0; NG=") + ")";
		EndIf;
	EndIf;
	ShowUserNotification(NotificationTitle, NotificationRef, NotificationText);
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeSetMarkInList(Data, Checkmark, CheckParent)
	
	// Set the mark of a subordinate item.
	RowItems = Data.GetItems();
	
	For Each Item In RowItems Do
		Item.Check = Checkmark;
		MarkedForDeletionItemsTreeSetMarkInList(Item, Checkmark, False);
	EndDo;
	
	// Check the parent item.
	Parent = Data.GetParent();
	
	If CheckParent AND Parent <> Undefined Then 
		MarkedForDeletionItemsTreeCheckParent(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemsTreeCheckParent(Parent)
	
	ParentMark = True;
	RowItems = Parent.GetItems();
	For Each Item In RowItems Do
		If Not Item.Check Then
			ParentMark = False;
			Break;
		EndIf;
	EndDo;
	Parent.Check = ParentMark;
	
EndProcedure

&AtClient
Procedure ScheduledJobsChangeSchedule()
	Handler = New NotifyDescription("ScheduledJobsAfterChangeSchedule", ThisObject);
	Dialog = New ScheduledJobDialog(DeleteMarkedObjectsSchedule);
	Dialog.Show(Handler);
EndProcedure

&AtClient
Procedure ScheduledJobsAfterChangeSchedule(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		DeleteMarkedObjectsUsage = False;
		Return;
	EndIf;
	
	DeleteMarkedObjectsSchedule = Schedule;
	DeleteMarkedObjectsUsage = True;
	
	Changes = New Structure("Schedule", Schedule);
	Changes.Insert("Use", True);
	ScheduledJobsSave(Changes);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Procedure VisibleEnabled(Form)
	Items = Form.Items;
	CurrentPage = Items.Pages.CurrentPage;
	
	Items.NextButton.Title = NStr("ru = 'Удалить'; en = 'Delete'; pl = 'Usuń';de = 'Löschen';ro = 'Ștergeți';tr = 'Sil'; es_ES = 'Borrar'");
	Items.CloseButton.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
	Items.BackButton.Title = NStr("ru = '< В начало'; en = '< To beginning'; pl = '< do Strony Głównej';de = '< Zum Anfang';ro = '< Salt la prima pagină';tr = '< Başa'; es_ES = '< Ir a la página principal'");
	
	If CurrentPage = Items.DeletionModeSelectionPage Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = True;
		If Form.DeletionMode <> "Full" Then
			Items.NextButton.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = ' Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
		EndIf;
		Items.NextButton.DefaultButton = True;
		Items.CloseButton.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	ElsIf CurrentPage = Items.MarkedForDeletionItemsPage Then
		Items.BackButton.Visible = True;
		Items.BackButton.Title = NStr("ru = '< Назад'; en = '< Back'; pl = '< Wstecz';de = '< Zurück';ro = '< Înapoi';tr = '< Geri'; es_ES = '< Atrás'");
		Items.NextButton.Visible = True;
		Items.NextButton.Title = NStr("ru = 'Удалить'; en = 'Delete'; pl = 'Usuń';de = 'Löschen';ro = 'Ștergeți';tr = 'Sil'; es_ES = 'Borrar'");
		Items.NextButton.DefaultButton = True;
	ElsIf CurrentPage = Items.TimeConsumingOperationPage Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = False;
		Items.CloseButton.Title = NStr("ru = 'Прервать и закрыть'; en = 'Stop and close'; pl = 'Zatrzymaj i zamknij';de = 'Stoppen und schließen';ro = 'Oprire și închidere';tr = 'Durdur ve kapat'; es_ES = 'Parar y cerrar'");
	ElsIf CurrentPage = Items.DeletionFailureReasonsPage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = True;
		Items.NextButton.Title = NStr("ru = 'Повторить удаление'; en = 'Retry deletion'; pl = 'Powtórz usunięcie';de = 'Löschen wiederholen';ro = 'Repetare ștergerea';tr = 'Tekrar sil'; es_ES = 'Volver a eliminar'");
		Items.NextButton.DefaultButton = True;
	ElsIf CurrentPage = Items.DeletionNotRequiredPage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
		Items.CloseButton.DefaultButton = True;
	ElsIf CurrentPage = Items.DonePage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
		Items.CloseButton.DefaultButton = True;
	ElsIf CurrentPage = Items.ErrorPage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function PictureNumber(ReferenceOrData, ReferenceType, Kind, DeletionMark)
	If ReferenceType Then
		If Kind = "CATALOG"
			Or Kind = "CHARTOFCHARACTERISTICTYPES" Then
			PictureNumber = 3;
		ElsIf Kind = "DOCUMENT" Then
			PictureNumber = 12;
		ElsIf Kind = "CHARTOFACCOUNTS" Then
			PictureNumber = 15;
		ElsIf Kind = "CHARTOFCALCULATIONTYPES" Then
			PictureNumber = 17;
		ElsIf Kind = "BUSINESSPROCESS" Then
			PictureNumber = 19;
		ElsIf Kind = "TASK" Then
			PictureNumber = 21;
		ElsIf Kind = "EXCHANGEPLAN" Then
			PictureNumber = 23;
		Else
			PictureNumber = -2;
		EndIf;
		If DeletionMark Then
			PictureNumber = PictureNumber + 1;
		EndIf;
	Else
		If Kind = "CONSTANT" Then
			PictureNumber = 25;
		ElsIf Kind = "INFORMATIONREGISTER" Then
			PictureNumber = 26;
		ElsIf Kind = "ACCUMULATIONREGISTER" Then
			PictureNumber = 28;
		ElsIf Kind = "ACCOUNTINGREGISTER" Then
			PictureNumber = 34;
		ElsIf Kind = "CALCULATIONREGISTER" Then
			PictureNumber = 38;
		ElsIf ReferenceOrData = Undefined Then
			PictureNumber = 11;
		Else
			PictureNumber = 8;
		EndIf;
	EndIf;
	
	Return PictureNumber;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Function ItemsMarkedForDeletionFromResultPage()
	Result = New Array;
	
	ValuesTree = FormAttributeToValue("NotDeletedItems");
	FoundItems = ValuesTree.Rows.FindRows(New Structure("DeletionMark", True), True);
	For Each TreeRow In FoundItems Do
		If TypeOf(TreeRow.ItemToDeleteRef) <> Type("String")
			AND Result.Find(TreeRow.ItemToDeleteRef) = Undefined Then
			Result.Add(TreeRow.ItemToDeleteRef);
		EndIf;
	EndDo;
	
	ValueTable = FormAttributeToValue("NotDeletedItemRelations");
	If DeletionMode = "Full" Then
		Filter = New Structure("DeletionMark", True);
	Else
		Filter = New Structure("DeletionMark, DeletionMarkModified", True, True);
	EndIf;
	FoundItems = ValueTable.FindRows(Filter);
	For Each TreeRow In FoundItems Do
		If TypeOf(TreeRow.FoundItemReference) <> Type("String")
			AND Result.Find(TreeRow.FoundItemReference) = Undefined Then
			Result.Add(TreeRow.FoundItemReference);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ItemsMarkedForDeletionFromCheckBoxesSettingPage()
	Result = New Array;
	
	ValuesTree = FormAttributeToValue("MarkedForDeletionItemsTree");
	FoundItems = ValuesTree.Rows.FindRows(New Structure("Check", True), True);
	For Each TreeRow In FoundItems Do
		If TypeOf(TreeRow.Value) <> Type("String") Then
			Result.Add(TreeRow.Value);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ChangeObjectsDeletionMark(RefsArray, DeletionMark)
	
	Count = RefsArray.Count();
	For Number = 1 To Count Do
		ReverseIndex = Count - Number;
		ObjectToChange = RefsArray[ReverseIndex].GetObject();
		If ObjectToChange = Undefined Then
			RefsArray.Delete(ReverseIndex);
		Else
			ObjectToChange.SetDeletionMark(DeletionMark);
		EndIf;
	EndDo;
	
	ObjectsCount = RefsArray.Count();
	
	If ObjectsCount > 0 Then
		ValuesTree = FormAttributeToValue("NotDeletedItems");
		ValueTable = FormAttributeToValue("NotDeletedItemRelations");
		
		For Each Ref In RefsArray Do
			FoundItems = ValuesTree.Rows.FindRows(New Structure("ItemToDeleteRef", Ref), True);
			For Each TreeRow In FoundItems Do
				If TreeRow.DeletionMark = DeletionMark Then
					Continue;
				EndIf;
				TreeRow.DeletionMark = DeletionMark;
				TreeRow.PictureNumber   = TreeRow.PictureNumber + ?(DeletionMark, 1, -1);
			EndDo;
			
			FoundItems = ValueTable.FindRows(New Structure("FoundItemReference", Ref));
			For Each TableRow In FoundItems Do
				If TableRow.DeletionMark = DeletionMark Then
					Continue;
				EndIf;
				TableRow.DeletionMark = DeletionMark;
				TableRow.PictureNumber   = TableRow.PictureNumber + ?(DeletionMark, 1, -1);
				TableRow.DeletionMarkModified = True;
			EndDo;
		EndDo;
		
		LoadCollection("NotDeletedItems", ValuesTree, "ItemToDeleteRef");
		LoadCollection("NotDeletedItemRelations", ValueTable, "ItemToDeleteRef, FoundItemReference");
	EndIf;
	
	Return StandardSubsystemsServer.PrepareFormChangeNotification(RefsArray);
	
EndFunction

&AtServer
Procedure LoadCollection(TableName, TableData, KeyColumns)
	SelectedRows = RememberSelectedRows(TableName, KeyColumns);
	ValueToFormAttribute(TableData, TableName);
	RestoreSelectedRows(TableName, SelectedRows);
EndProcedure

&AtServer
Function RememberSelectedRows(TableName, KeyColumns)
	TableAttribute = ThisObject[TableName];
	TableItem = Items[TableName];
	
	Result = New Structure;
	Result.Insert("Selected", New Array);
	Result.Insert("Current", Undefined);
	
	CurrentRowID = TableItem.CurrentRow;
	If CurrentRowID <> Undefined Then
		TableRow = TableAttribute.FindByID(CurrentRowID);
		If TableRow <> Undefined Then
			RowData = New Structure(KeyColumns);
			FillPropertyValues(RowData, TableRow);
			Result.Current = RowData;
		EndIf;
	EndIf;
	
	SelectedRows = TableItem.SelectedRows;
	If SelectedRows <> Undefined Then
		For Each SelectedID In SelectedRows Do
			If SelectedID = CurrentRowID Then
				Continue;
			EndIf;
			TableRow = TableAttribute.FindByID(SelectedID);
			If TableRow <> Undefined Then
				RowData = New Structure(KeyColumns);
				FillPropertyValues(RowData, TableRow);
				Result.Selected.Add(RowData);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure RestoreSelectedRows(TableName, TableRows)
	TableAttribute = ThisObject[TableName];
	TableItem = Items[TableName];
	
	TableItem.SelectedRows.Clear();
	
	If TableRows.Current <> Undefined Then
		FoundItems = FindTableRows(TableAttribute, TableRows.Current);
		If FoundItems <> Undefined AND FoundItems.Count() > 0 Then
			For Each TableRow In FoundItems Do
				If TableRow <> Undefined Then
					ID = TableRow.GetID();
					TableItem.CurrentRow = ID;
					TableItem.SelectedRows.Add(ID);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	For Each RowData In TableRows.Selected Do
		FoundItems = FindTableRows(TableAttribute, RowData);
		If FoundItems <> Undefined AND FoundItems.Count() > 0 Then
			For Each TableRow In FoundItems Do
				If TableRow <> Undefined Then
					TableItem.SelectedRows.Add(TableRow.GetID());
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function FindTableRows(TableAttribute, RowData)
	If TypeOf(TableAttribute) = Type("FormDataCollection") Then // Value table.
		Return TableAttribute.FindRows(RowData);
	ElsIf TypeOf(TableAttribute) = Type("FormDataTree") Then // Value tree.
		Return FindRecursively(TableAttribute.GetItems(), RowData);
	Else
		Return Undefined;
	EndIf;
EndFunction

&AtServer
Function FindRecursively(RowsSet, RowData, FoundItems = Undefined)
	If FoundItems = Undefined Then
		FoundItems = New Array;
	EndIf;
	For Each TableRow In RowsSet Do
		ValuesMatch = True;
		For Each KeyAndValue In RowData Do
			If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
				ValuesMatch = False;
				Break;
			EndIf;
		EndDo;
		If ValuesMatch Then
			FoundItems.Add(TableRow);
		EndIf;
		FindRecursively(TableRow.GetItems(), RowData, FoundItems);
	EndDo;
	Return FoundItems;
EndFunction

&AtServer
Procedure ScheduledJobsSave(Changes)
	ScheduledJobsServer.ChangeJob(DeleteMarkedObjectsID, Changes);
	SetAvailability();
EndProcedure

&AtServer
Function ScheduledJobsFindPredefinedItem()
	Filter = New Structure("Metadata", "MarkedObjectsDeletion");
	FoundItems = ScheduledJobsServer.FindJobs(Filter);
	Job = ?(FoundItems.Count() = 0, Undefined, FoundItems[0]);
	Return Job;
EndFunction

&AtServer
Procedure SetAvailability()
	
	If Items.DeleteMarkedObjectsConfigureSchedule.Visible Then
		Items.DeleteMarkedObjectsConfigureSchedule.Enabled   = DeleteMarkedObjectsUsage;
		Items.DeleteMarkedObjectsSchedulePresentation.Visible = DeleteMarkedObjectsUsage;
		If DeleteMarkedObjectsUsage Then
			SchedulePresentation = String(DeleteMarkedObjectsSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = NStr("ru = '<Отключено>'; en = '<Disabled>'; pl = '<Wyłączone>';de = '<Deaktiviert>';ro = '<Dezactivat>';tr = '<Devre dışı>'; es_ES = '<Desactivado>'");
		EndIf;
		Items.DeleteMarkedObjectsSchedulePresentation.Title = Presentation;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DisableExclusiveMode()
	SetExclusiveMode(False);
	If Common.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
		ModuleIBConnections = Common.CommonModule("IBConnections");
		ModuleIBConnections.AllowUserAuthorization();
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure SetDataProcessorNoteTextOnCreateAtServer()
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		ConnectionsCount = 0;
		OutputSignature = False;
		OutputCount = False;
	ElsIf Common.FileInfobase() Then
		ConnectionsCount = 0;
		ThisSessionNumber = InfoBaseSessionNumber();
		For Each InfoBaseSession In GetInfoBaseSessions() Do
			If InfoBaseSession.SessionNumber = ThisSessionNumber Then
				Continue;
			EndIf;
			If InfoBaseSession.ApplicationName = "1CV8" // Thick client.
				Or InfoBaseSession.ApplicationName = "1CV8C" // Thin client.
				Or InfoBaseSession.ApplicationName = "WebClient" Then // Web client.
				ConnectionsCount = ConnectionsCount + 1;
			EndIf;
		EndDo;
		OutputSignature = (ConnectionsCount > 0);
		OutputCount = True;
	Else
		ConnectionsCount = 0;
		OutputSignature = True;
		OutputCount = False;
	EndIf;
	
	CaptionPattern = Items.DataProcessorNote.Title;
	If Not OutputSignature Then
		Items.DataProcessorNote.Title = Left(CaptionPattern, StrFind(CaptionPattern, "<1/>") - 1);
		WindowOptionsKey = "1";
	Else
		Balance = StrReplace(CaptionPattern, "<1/>", "");
		RowsArray = New Array;
		
		Position = StrFind(Balance, "<a");
		RowsArray.Add(Left(Balance, Position - 1));
		Balance = Mid(Balance, Position);
		
		Position = StrFind(Balance, "</a>");
		HyperlinkDefinition = Left(Balance, Position -1);
		Balance = Mid(Balance, Position + 4);
		
		Position = StrFind(HyperlinkDefinition, """");
		HyperlinkDefinition = Mid(HyperlinkDefinition, Position + 1);
		
		Position = StrFind(HyperlinkDefinition, """");
		HyperlinkAddress = Left(HyperlinkDefinition, Position - 1);
		HyperlinkAnchorText = Mid(HyperlinkDefinition, Position + 2);
		If OutputCount Then
			HyperlinkAnchorText = HyperlinkAnchorText + " (" + Format(ConnectionsCount, "NG=") + ")";
		EndIf;
		
		RowsArray.Add(New FormattedString(HyperlinkAnchorText, , , , HyperlinkAddress));
		RowsArray.Add(Balance);
		
		Items.DataProcessorNote.Title = New FormattedString(RowsArray);
		WindowOptionsKey = "2";
	EndIf;
EndProcedure

&AtServer
Procedure FillCollectionOfRemainingObjects(BackgroundExecutionResult)
	
	ItemsPreventingDeletion = BackgroundExecutionResult.ItemsPreventingDeletion;
	TypesInformation = BackgroundExecutionResult.TypesInformation;
	
	NotDeletedItemsTree = FormAttributeToValue("NotDeletedItems");
	NotDeletedItemsTree.Rows.Clear();
	NotDeletedItemsLinksTable = FormAttributeToValue("NotDeletedItemRelations");
	NotDeletedItemsLinksTable.Clear();
	
	NotDeletedItemsGroups = New Map;
	NotDeletedItemsRows = New Map;
	
	ReferenceObjectsFoundNotMarked = False;
	RegistersFound = False;
	
	For Each Reason In ItemsPreventingDeletion Do
		NotDeletedItemRow = NotDeletedItemsRows.Get(Reason.ItemToDeleteRef);
		If NotDeletedItemRow = Undefined Then
			ItemToDeleteInfo = TypesInformation.Get(Reason.TypeToDelete);
			If ItemToDeleteInfo.Technical Then
				Continue;
			EndIf;
			
			NotDeletedItemGroup = NotDeletedItemsGroups.Get(Reason.TypeToDelete);
			If NotDeletedItemGroup = Undefined Then
				NotDeletedItemGroup = NotDeletedItemsTree.Rows.Add();
				NotDeletedItemGroup.PictureNumber   = -1;
				NotDeletedItemGroup.ItemToDeleteRef = ItemToDeleteInfo.FullName;
				NotDeletedItemGroup.Presentation   = ItemToDeleteInfo.ListPresentation;
				
				NotDeletedItemsGroups.Insert(Reason.TypeToDelete, NotDeletedItemGroup);
				QuickSearch.FullMetadataObjectsNames.Insert(Reason.TypeToDelete, ItemToDeleteInfo.FullName);
			EndIf;
			
			NotDeletedItemGroup.LinkCount = NotDeletedItemGroup.LinkCount + 1;
			
			NotDeletedItemRow = NotDeletedItemGroup.Rows.Add();
			NotDeletedItemRow.ItemToDeleteRef = Reason.ItemToDeleteRef;
			NotDeletedItemRow.Presentation   = String(Reason.ItemToDeleteRef);
			NotDeletedItemRow.DeletionMark = True;
			
			NotDeletedItemRow.PictureNumber = PictureNumber(
				NotDeletedItemRow.ItemToDeleteRef,
				True,
				ItemToDeleteInfo.Kind,
				NotDeletedItemRow.DeletionMark);
			
			NotDeletedItemsRows.Insert(Reason.ItemToDeleteRef, NotDeletedItemRow);
		EndIf;
		
		NotDeletedItemRow.LinkCount = NotDeletedItemRow.LinkCount + 1;
		
		RowOfItemPreventingDeletion = NotDeletedItemsLinksTable.Add();
		RowOfItemPreventingDeletion.ItemToDeleteRef    = Reason.ItemToDeleteRef;
		RowOfItemPreventingDeletion.FoundItemReference = Reason.FoundItemReference;
		RowOfItemPreventingDeletion.DeletionMark    = Reason.FoundDeletionMark;
		RowOfItemPreventingDeletion.IsError          = (Reason.FoundType = Type("String"));
		
		If RowOfItemPreventingDeletion.IsError Then
			RowOfItemPreventingDeletion.Presentation = Reason.More;
		Else
			FoundItemInfo = TypesInformation.Get(Reason.FoundType);
			
			RowOfItemPreventingDeletion.ReferenceType = FoundItemInfo.Reference;
			
			If FoundItemInfo.Kind = "INFORMATIONREGISTER"
				Or FoundItemInfo.Kind = "ACCUMULATIONREGISTER"
				Or FoundItemInfo.Kind = "ACCOUNTINGREGISTER"
				Or FoundItemInfo.Kind = "CALCULATIONREGISTER" Then
				RegistersFound = True;
			EndIf;
			
			If Not ReferenceObjectsFoundNotMarked // Optimization.
				AND FoundItemInfo.Reference
				AND BackgroundExecutionResult.NotDeletedItems.Find(Reason.FoundItemReference) = Undefined Then
				ReferenceObjectsFoundNotMarked = False;
			EndIf;
			
			If Reason.FoundItemReference = Undefined Then // Constant
				RowOfItemPreventingDeletion.FoundItemReference = FoundItemInfo.FullName;
				RowOfItemPreventingDeletion.IsConstant = True;
				RowOfItemPreventingDeletion.Presentation = FoundItemInfo.ItemPresentation + " (" + NStr("ru = 'Константа'; en = 'Constant'; pl = 'Stała';de = 'Konstant ';ro = 'Constant';tr = 'Sabit'; es_ES = 'Constante'") + ")";
			Else
				RowOfItemPreventingDeletion.Presentation = String(Reason.FoundItemReference) + " (" + FoundItemInfo.ItemPresentation + ")";
				QuickSearch.FullMetadataObjectsNames.Insert(Reason.FoundType, FoundItemInfo.FullName);
			EndIf;
			
			RowOfItemPreventingDeletion.PictureNumber = PictureNumber(
				RowOfItemPreventingDeletion.FoundItemReference,
				RowOfItemPreventingDeletion.ReferenceType,
				FoundItemInfo.Kind,
				RowOfItemPreventingDeletion.DeletionMark);
		EndIf;
	EndDo;
	
	For Each NotDeletedItemGroup In NotDeletedItemsTree.Rows Do
		NotDeletedItemGroup.Presentation = NotDeletedItemGroup.Presentation + " (" + Format(NotDeletedItemGroup.LinkCount, "NZ=0; NG=") + ")";
	EndDo;
	
	FooterTitle = Items.LabelInFooter.Title;
	SignatureAdded = (StrOccurrenceCount(FooterTitle, ".") = 2);
	If RegistersFound AND Not ReferenceObjectsFoundNotMarked Then
		If Not SignatureAdded Then
			Items.LabelInFooter.Title = FooterTitle + " "
				+ NStr("ru = 'Для устранения сложных зависимостей рекомендуется повторить удаление с включенным флажком ""Заблокировать всю работу в программе и ускорить удаление"" (нажмите кнопку ""< В начало"").'; en = 'To resolve complex dependencies, try the deletion with the selected check box ""Block all operations in the application and speed up the deletion"" (click ""< Home"").'; pl = 'Do usunięcia złożonych zależności zaleca się powtórzyć z włączonym zaznaczeniem ""Заблокировать всю работу в программе и ускорить удаление"" (naciśnij przycisk ""< В начало"").';de = 'Um komplexe Abhängigkeiten zu beseitigen, wird empfohlen, das Löschen mit dem aktivierten Kontrollkästchen ""Alle Arbeiten im Programm blockieren und das Löschen beschleunigen"" zu wiederholen (Schaltfläche ""<Zum Anfang"" drücken).';ro = 'Pentru a înlătura interdependențele complexe, recomandăm să repetați ștergerea cu bifa activată ""Blocare toată activitatea în program și grăbire ștergerea"" (tastați butonul ""< Salt la prima pagină"").';tr = 'Karmaşık bağımlılıkları gidermek için, ""Programdaki tüm çalışmaları engelle ve kaldırmayı hızlandır"" onay kutusunu kullanarak kaldırmayı tekrarlamanız önerilir (""<Başa"" düğmesine basın).'; es_ES = 'Para eliminar las dependencias compuestas se recomienda volver a eliminar con la casilla ""Desbloquear todo el trabajo en el programa y aumentar la eliminación"" puesta (pulse el botón ""< Al inicio"").'");
		EndIf;
	Else
		If SignatureAdded Then
			Items.LabelInFooter.Title = Left(FooterTitle, StrFind(FooterTitle, "."));
		EndIf;
	EndIf;
	
	NotDeletedItemsTree.Rows.Sort("Presentation", True);
	NotDeletedItemsLinksTable.Sort("ItemToDeleteRef, Presentation");
	
	ValueToFormAttribute(NotDeletedItemsTree,       "NotDeletedItems");
	ValueToFormAttribute(NotDeletedItemsLinksTable, "NotDeletedItemRelations");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Time-consuming operations

&AtClient
Procedure RunBackgroundJobClient(Mode)
	MethodParameters = New Structure;
	MethodParameters.Insert("SearchMarked", False);
	MethodParameters.Insert("DeleteMarked", False);
	MethodParameters.Insert("ReadItemsMarkedFromResultsPage", False);
	MethodParameters.Insert("ReadItemsMarkedFromCheckBoxesSettingPage", False);
	
	If Mode = 1 Then
		CurrentPage = Items.Pages.CurrentPage;
		If CurrentPage = Items.DeletionModeSelectionPage Then
			If DeletionMode = "Full" Then
				MethodParameters.SearchMarked = True;
				MethodParameters.DeleteMarked = True;
			Else
				MethodParameters.SearchMarked = True;
			EndIf;
		ElsIf CurrentPage = Items.MarkedForDeletionItemsPage Then
			MethodParameters.ReadItemsMarkedFromCheckBoxesSettingPage = True;
			MethodParameters.DeleteMarked = True;
		ElsIf CurrentPage = Items.DeletionFailureReasonsPage Then
			If DeletionMode = "Full" Then
				MethodParameters.SearchMarked = True;
			Else
				MethodParameters.ReadItemsMarkedFromResultsPage = True;
			EndIf;
			MethodParameters.DeleteMarked = True;
		EndIf;
	ElsIf Mode = 2 Then
		MethodParameters.SearchMarked = True;
		MethodParameters.ReadItemsMarkedFromCheckBoxesSettingPage = True;
	Else
		Return;
	EndIf;
	
	If MethodParameters.SearchMarked Then
		Text = NStr("ru = 'Поиск помеченных на удаление объектов...'; en = 'Search for objects marked for deletion...'; pl = 'Wyszukaj obiekty, zaznaczone do usunięcia...';de = 'Suche nach Objekten, die zum Löschen markiert sind...';ro = 'Căutați obiecte marcate pentru ștergere ...';tr = 'Silinmek üzere işaretlenmiş nesneleri arayın...'; es_ES = 'Buscar los objetos marcados para borrar...'");
	Else
		Text = NStr("ru = 'Удаляются объекты, помеченные на удаление...'; en = 'Marked objects are being deleted...'; pl = 'Usuwanie obiektów, zaznaczonych do usunięcia...';de = 'Löschen der zum Löschen markierten Objekte...';ro = 'Are loc ștergerea obiectelor marcate la ștergere...';tr = 'Silinecek olarak işaretlenen nesneler siliniyor...'; es_ES = 'Eliminando los objetos marcados para borrar...'");
	EndIf;
	Items.TimeConsumingOperationLabel.Title = Text;
	
	Job = RunBackgroundJob(MethodParameters);
	If Job = Undefined Then
		Return; // Deletion is not required.
	ElsIf Job.ErrorOnSetExclusiveMode Then
		If CommonClient.SubsystemExists("StandardSubsystems.UserSessionsCompletion") Then
			Notification = New NotifyDescription("AfterSetExclusiveMode", ThisObject, Mode);
			FormParameters = New Structure("MarkedObjectsDeletion", True);
			ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
			ModuleIBConnectionsClient.OnOpenExclusiveModeSetErrorForm(Notification, FormParameters);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось заблокировать работу в программе по причине: 
				           |%1'; 
				           |en = 'Cannot block operations in the application due to:
				           |%1'; 
				           |pl = 'Nie udało się zablokować pracę w programie z powodu: 
				           |%1';
				           |de = 'Es war aus diesem Grund nicht möglich, die Arbeit im Programm zu blockieren: 
				           |%1';
				           |ro = 'Eșec la blocarea lucrului utilizatorilor în program din motivul: 
				           |%1';
				           |tr = 'Aşağıdaki nedenle programdaki çalışma kilitlenemedi: 
				           |%1'; 
				           |es_ES = 'No se ha podido bloquear el trabajo en el programa a causa de: 
				           |%1'"),
				Job.ExclusiveModeSettingErrorText);
		EndIf;
		Return;
	EndIf;
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	WaitSettings.OutputProgressBar = True;
	WaitSettings.ExecutionProgressNotification = New NotifyDescription("OnUpdateBackgroundJobProgress", ThisObject);
	
	Handler = New NotifyDescription("AfterCompleteBackgroundJob", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
EndProcedure

&AtServer
Function RunBackgroundJob(Val MethodParameters)
	If MethodParameters.DeleteMarked AND Exclusive Then
		ErrorInformation = Undefined;
		Try
			SetExclusiveMode(True);
		Except
			ErrorInformation = ErrorInfo();
		EndTry;
		If ErrorInformation <> Undefined Then
			Result = New Structure;
			Result.Insert("ErrorOnSetExclusiveMode", True);
			Result.Insert("ExclusiveModeSettingErrorText", BriefErrorDescription(ErrorInformation));
			Return Result;
		EndIf;
	EndIf;
	
	// Run the background job
	If Not MethodParameters.SearchMarked Then
		If MethodParameters.ReadItemsMarkedFromResultsPage Then
			UserObjects = ItemsMarkedForDeletionFromResultPage();
		ElsIf MethodParameters.ReadItemsMarkedFromCheckBoxesSettingPage Then
			UserObjects = ItemsMarkedForDeletionFromCheckBoxesSettingPage();
		EndIf;
		If UserObjects.Count() = 0 Then
			Items.Pages.CurrentPage = Items.DeletionNotRequiredPage;
			VisibleEnabled(ThisObject);
			Return Undefined;
		EndIf;
		MethodParameters.Insert("UserObjects", UserObjects);
	EndIf;
	
	MethodParameters.Insert("RecordPeriod", 3); // Seconds
	MethodParameters.Insert("Exclusive", Exclusive);
	
	// Switching to a time-consuming operation page.
	ShowDialogBeforeClose = True;
	
	ShowDonut = MethodParameters.DeleteMarked AND Exclusive;
	Items.BackgroundJobAnimation.Visible = ShowDonut;
	Items.BackgroundJobPercentage.Visible  = Not ShowDonut;
	Items.Pages.CurrentPage         = Items.TimeConsumingOperationPage;
	If ShowDonut Then
		Items.TimeConsumingOperationLabel.Title = NStr("ru = 'Пожалуйста, подождите...'; en = 'Please wait...'; pl = 'Proszę czekać…';de = 'Bitte warten...';ro = 'Așteptați...';tr = 'Lütfen bekleyin...'; es_ES = 'Por favor, espere...'");
		Items.TimeConsumingOperationLabel.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
		Items.BackgroundJobStatus.HorizontalAlign = ItemHorizontalLocation.Left;
	ElsIf MethodParameters.DeleteMarked Then
		Items.TimeConsumingOperationLabel.Title = NStr("ru = 'Удаляются объекты, помеченные на удаление...'; en = 'Marked objects are being deleted...'; pl = 'Usuwanie obiektów, zaznaczonych do usunięcia...';de = 'Löschen der zum Löschen markierten Objekte...';ro = 'Are loc ștergerea obiectelor marcate la ștergere...';tr = 'Silinecek olarak işaretlenen nesneler siliniyor...'; es_ES = 'Eliminando los objetos marcados para borrar...'");
		Items.TimeConsumingOperationLabel.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
		Items.BackgroundJobStatus.HorizontalAlign = ItemHorizontalLocation.Center;
	Else
		Items.TimeConsumingOperationLabel.Title = NStr("ru = 'Поиск объектов, помеченных на удаление...'; en = 'Search for objects marked for deletion...'; pl = 'Wyszukaj obiekty, zaznaczone do usunięcia...';de = 'Suche nach Objekten, die zum Löschen markiert sind...';ro = 'Căutarea obiectelor marcate la ștergere...';tr = 'Silinecek olarak işaretlenmiş nesneleri arama...'; es_ES = 'Buscar los objetos marcados para borrar...'");
		Items.TimeConsumingOperationLabel.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
		Items.BackgroundJobStatus.HorizontalAlign = ItemHorizontalLocation.Center;
	EndIf;
	
	VisibleEnabled(ThisObject);
	
	// Define start parameters.
	MethodName = "DataProcessors.MarkedObjectsDeletion.DeleteMarkedObjectsInteractively";
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = NStr("ru = 'Удаление помеченных объектов (интерактивное)'; en = 'Deletion of marked objects (interactive)'; pl = 'Usunięcie oznaczonych obiektów (interaktywny)';de = 'Löschen von markierten Objekten (interaktiv)';ro = 'Ștergerea obiectelor marcate (interactive)';tr = 'İşaretli nesneleri silme (interaktif)'; es_ES = 'Eliminación de los objetos marcados (interactiva)'");
	
	Job = TimeConsumingOperations.ExecuteInBackground(MethodName, MethodParameters, StartSettings);
	Job.Insert("ErrorOnSetExclusiveMode", False);
	Job.Insert("ExclusiveModeSettingErrorText", Undefined);
	
	Return Job;
EndFunction

&AtClient
Procedure AfterSetExclusiveMode(Result, Mode) Export
	If Result = False Then // The exclusive mode is set.
		RunBackgroundJobClient(Mode);
	EndIf;
EndProcedure

&AtClient
Procedure OnUpdateBackgroundJobProgress(Job, AdditionalParameters) Export
	If Job.Progress <> Undefined Then
		BackgroundJobPercentage   = Job.Progress.Percent;
		BackgroundJobStatus = Job.Progress.Text;
	EndIf;
EndProcedure

&AtClient
Procedure AfterCompleteBackgroundJob(Job, AdditionalParameters) Export
	ShowDialogBeforeClose = False;
	If Exclusive Then
		DisableExclusiveMode();
	EndIf;
	
	// The job is canceled.
	If Job = Undefined Then 
		Return;
	EndIf;
	
	Activate();
	
	If Job.Status = "Completed" Then
		
		Result = LoadBackgroundJobResult(Job.ResultAddress);
		If Result = Undefined Then
			OutputError(NStr("ru = 'Не удалось прочитать результат удаления помеченных'; en = 'Cannot read the result of deleting marked objects'; pl = 'Nie udało się przeczytać rezultat usunięcia zaznaczonych';de = 'Das Ergebnis des Löschvorgangs konnte nicht gelesen werden';ro = 'Eșec la citirea rezultatului ștergerii celor marcate';tr = 'Işaretlenenleri silme sonucu okunamadı'; es_ES = 'No se ha podido leer el resultado de la eliminación de los marcados'"), "");
			Return;
		EndIf;
		
		StandardSubsystemsClient.NotifyFormsAboutChange(
			Result.ChangesNotification,
			New Structure("MarkedObjectsDeletion", True));
		
		If Not IsBlankString(Result.NotificationText) Then
			ShowUserNotification(
				NStr("ru = 'Удаление помеченных'; en = 'Deletion of marked objects'; pl = 'Usunięcie oznaczonych obiektów';de = 'Löschen von markierten Objekten';ro = 'Ștergerea celor marcate';tr = 'İşaretli nesneleri silme'; es_ES = 'Eliminación de los objetos marcados'"),
				URL,
				Result.NotificationText,
				Result.NotificationPicture);
		EndIf;
		
		If Result.ExpandMarkedForDeletionItemsTree Then
			StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "MarkedForDeletionItemsTree");
		EndIf;
		
	Else
		
		OutputError(Job.BriefErrorPresentation, Job.DetailedErrorPresentation);
		
	EndIf;
	
EndProcedure

&AtServer
Function LoadBackgroundJobResult(ResultAddress)
	If Exclusive Then
		DisableExclusiveMode();
	EndIf;
	
	// Get the result.
	BackgroundExecutionResult = GetFromTempStorage(ResultAddress);
	If BackgroundExecutionResult = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ChangesNotification", New Map);
	Result.Insert("NotificationText", "");
	Result.Insert("NotificationPicture", Undefined);
	Result.Insert("ExpandMarkedForDeletionItemsTree", False);
	
	If BackgroundExecutionResult.DeleteMarked Then
		
		Result.ChangesNotification = StandardSubsystemsServer.PrepareFormChangeNotification(BackgroundExecutionResult.DeletedItems);
		
		DeletedItemsCount = BackgroundExecutionResult.DeletedItems.Count();
		NotDeletedItemsCount = BackgroundExecutionResult.NotDeletedItems.Count();
		
		If DeletedItemsCount = 0 AND NotDeletedItemsCount = 0 Then
			Items.Pages.CurrentPage = Items.DeletionNotRequiredPage;
		ElsIf NotDeletedItemsCount = 0 Then
			Items.Pages.CurrentPage = Items.DonePage;
			Result.NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Удалено объектов: %1.'; en = 'Deleted objects: %1.'; pl = 'Usunięto obiektów: %1.';de = 'Gelöschte Objekte: %1.';ro = 'Obiecte șterse: %1.';tr = 'Silinen nesne: %1'; es_ES = 'Eliminado objetos: %1.'"),
				Format(DeletedItemsCount, "NZ=0; NG="));
			Items.DoneLabel.Title = Result.NotificationText;
		Else
			Items.Pages.CurrentPage = Items.DeletionFailureReasonsPage;
			Result.NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Удалено: %1, не удалено: %2.'; en = 'Deleted: %1, not deleted: %2.'; pl = 'Usunięto: %1, nie usunięto: %2.';de = 'Gelöscht: %1,nicht gelöscht: %2.';ro = 'Șterse cu succes: %1, nu au fost șterse: %2.';tr = 'Silindi:%1, silinmedi: %2.'; es_ES = 'Eliminado: %1, no eliminado: %2.'"),
				Format(DeletedItemsCount, "NZ=0; NG="),
				Format(NotDeletedItemsCount, "NZ=0; NG="));
			Result.NotificationPicture = PictureLib.Warning32;
			
			If DeletedItemsCount = 0 Then
				Items.PartialDeletionResultsLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не получилось удалить объекты, помеченные на удаление (%1):'; en = 'Cannot delete objects marked for deletion (%1):'; pl = 'Nie można usunąć obiektów oznaczonych do usunięcia (%1):';de = 'Objekte, die zum Löschen markiert sind, können nicht gelöscht werden (%1):';ro = 'Nu se pot șterge obiectele marcate pentru ștergere (%1):';tr = 'Silinmek üzere işaretlenen nesneleri kaldıramıyor (%1):'; es_ES = 'No se puede borrar los objetos marcados para borrar (%1):'"),
					Format(NotDeletedItemsCount, "NZ=0; NG="));
			Else
				Items.PartialDeletionResultsLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Успешно удалено: %1 из %2, остальные объекты не удалены (%3):'; en = 'Successfully deleted: %1 out of %2, other objects are not deleted (%3):'; pl = 'Pomyślnie usunięto: %1 z %2, inne obiekty nie są usuwane (%3):';de = 'Erfolgreich gelöscht: %1 von %2, andere Objekte werden nicht gelöscht (%3):';ro = 'Au fost șterse cu succes: %1 din %2, celelalte obiecte nu sunt șterse (%3):';tr = 'Başarı ile silindi: %1''dan %2, diğer nesneler silinmedi (%3):'; es_ES = 'Borrado con éxito: %1 de %2, otros objetos no se han borrado (%3):'"),
					Format(DeletedItemsCount, "NZ=0; NG="),
					Format(DeletedItemsCount+NotDeletedItemsCount, "NZ=0; NG="),
					Format(NotDeletedItemsCount, "NZ=0; NG="));
			EndIf;
			
			Template = Items.NotDeletedItemsGroup.Title;
			Template = Left(Template, StrFind(Template, "("));
			Items.NotDeletedItemsGroup.Title = Template + Format(NotDeletedItemsCount, "NZ=0; NG=") + ")";
			
			FillCollectionOfRemainingObjects(BackgroundExecutionResult);
			
			NotDeletedItemsGroups = NotDeletedItems.GetItems();
			If NotDeletedItemsGroups.Count() > 0 Then
				FirstGroupItems = NotDeletedItemsGroups[0].GetItems();
				If FirstGroupItems.Count() > 0 Then
					Items.NotDeletedItems.CurrentRow = FirstGroupItems[0].GetID();
					ShowNotDeletedItemsLinksAtServer();
				EndIf;
			EndIf;
			
		EndIf;
		
	Else
		
		// Fill the tree of objects marked for deletion.
		Marked = ItemsMarkedForDeletionFromResultPage();
		MarksAreSetSelectively = (Marked.Count() > 0);
		
		ValuesTree = FormAttributeToValue("MarkedForDeletionItemsTree");
		ValuesTree.Rows.Clear();
		ValuesTree.Columns.Add("Count");
		
		FirstLevelNodes = New Map;
		
		UserObjects = BackgroundExecutionResult.UserObjects;
		For Each ItemToDeleteRef In UserObjects Do
			ItemToDeleteType = TypeOf(ItemToDeleteRef);
			ItemToDeleteInfo = DataProcessors.MarkedObjectsDeletion.GenerateTypesInformation(BackgroundExecutionResult, ItemToDeleteType);
			
			NodeOfType = FirstLevelNodes.Get(ItemToDeleteType);
			If NodeOfType = Undefined Then
				NodeOfType = ValuesTree.Rows.Add();
				NodeOfType.Value      = ItemToDeleteInfo.FullName;
				NodeOfType.Presentation = ItemToDeleteInfo.ListPresentation;
				NodeOfType.Check       = True;
				NodeOfType.Count    = 0;
				NodeOfType.PictureNumber = -1;
				FirstLevelNodes.Insert(ItemToDeleteType, NodeOfType);
				QuickSearch.FullMetadataObjectsNames.Insert(ItemToDeleteType, ItemToDeleteInfo.FullName);
			EndIf;
			NodeOfType.Count = NodeOfType.Count + 1;
			
			NodeOfItemToDelete = NodeOfType.Rows.Add();
			NodeOfItemToDelete.Value      = ItemToDeleteRef;
			NodeOfItemToDelete.Presentation = String(ItemToDeleteRef);
			NodeOfItemToDelete.Check       = True;
			NodeOfItemToDelete.PictureNumber = PictureNumber(ItemToDeleteRef, True, ItemToDeleteInfo.Kind, True);
			
			If MarksAreSetSelectively AND Marked.Find(ItemToDeleteRef) = Undefined Then
				NodeOfItemToDelete.Check = False;
				NodeOfType.Check       = False;
			EndIf;
			
		EndDo;
		
		For Each NodeOfType In ValuesTree.Rows Do
			NodeOfType.Presentation = NodeOfType.Presentation + " (" + NodeOfType.Count + ")";
		EndDo;
		
		ValuesTree.Columns.Delete(ValuesTree.Columns.Count);
		ValuesTree.Rows.Sort("Presentation", True);
		
		ValueToFormAttribute(ValuesTree, "MarkedForDeletionItemsTree");
		
		TypesCount = FirstLevelNodes.Count();
		
		If TypesCount = 0 Then
			Items.Pages.CurrentPage = Items.DeletionNotRequiredPage;
		Else
			Items.Pages.CurrentPage = Items.MarkedForDeletionItemsPage;
			If TypesCount = 1 Then
				Result.ExpandMarkedForDeletionItemsTree = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	DeleteFromTempStorage(ResultAddress);
	VisibleEnabled(ThisObject);
	
	Return Result;
EndFunction

&AtClient
Procedure OutputError(BriefErrorPresentation, DetailedErrorPresentation);
	BriefDescription = NStr("ru = 'Удаление не выполнено по причине:'; en = 'Deletion failed due to:'; pl = 'Nie zostało usunięto z powodu:';de = 'Löschen fehlgeschlagen wegen:';ro = 'Ștergerea nu este executată din motivul:';tr = 'Фşağıdaki nedenle silinmez:'; es_ES = 'Eliminación no ejecutada a causa de:'") + Chars.LF + BriefErrorPresentation;
	DetailedErrorText = BriefDescription + Chars.LF + Chars.LF + DetailedErrorPresentation;
	Items.ErrorTextLabel.Title = BriefDescription;
	Items.Pages.CurrentPage = Items.ErrorPage;
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		ShowDialogBeforeClose = False;
		Close();
	EndIf;
EndProcedure

#EndRegion