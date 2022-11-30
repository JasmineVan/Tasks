///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var FormClosingConfirmation;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Scenario = "RefsSearch" OR Parameters.Scenario = "PastingFromClipboard" Then
		ImportType = "PastingFromClipboard";
	ElsIf ValueIsFilled(Parameters.FullTabularSectionName) Then
		ImportType = "TabularSection";
	ElsIf NOT Users.IsFullUser() Then
		Raise(NStr("ru = 'Недостаточно прав для открытия загрузки данных из файла'; en = 'Insufficient rights to open data import from file'; pl = 'Niewystarczające uprawnienia do otwiarcia importu danych z pliku';de = 'Unzureichende Rechte zum Öffnen des Datenimports aus der Datei';ro = 'Insufficient rights to open data import from file';tr = 'Dosyadan veri içe aktarma için yetersiz haklar'; es_ES = 'Insuficientes derechos para abrir la importación de datos desde el archivo'"));
	EndIf;
	
	CreateIfUnmapped = 1;
	UpdateExistingItems = 0;
	AdditionalParameters = Parameters.AdditionalParameters;
	
	SetDataAppearance();
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	SetFormItemsVisibility();
	
	If ImportType = "PastingFromClipboard" Then
		InsertFromClipboardInitialization();
	ElsIf ImportType = "TabularSection" Then
		MappingObjectName = DataProcessors.ImportDataFromFile.FullTabularSectionObjectName(Parameters.FullTabularSectionName);
		
		TableColumnsInformation = Common.CommonSettingsStorageLoad("ImportDataFromFile", MappingObjectName,, UserName());
		If TableColumnsInformation = Undefined Then
			TableColumnsInformation = FormAttributeToValue("ColumnsInformation");
		Else
			If TableColumnsInformation.Columns.Find("Parent") = Undefined Then
				TableColumnsInformation = FormAttributeToValue("ColumnsInformation");
			EndIf;
		EndIf;
		
		ImportParameters = New Structure;
		ImportParameters.Insert("ImportType", ImportType);
		ImportParameters.Insert("FullObjectName", MappingObjectName);
		ImportParameters.Insert("Template", ?(ValueIsFilled(Parameters.DataStructureTemplateName), Parameters.DataStructureTemplateName, "ImportFromFile"));
		ImportParameters.Insert("AdditionalParameters", AdditionalParameters);
		
		If Parameters.Property("TemplateColumns") AND Parameters.TemplateColumns <> Undefined Then
			DefineDynamicTemplate(TableColumnsInformation, Parameters.TemplateColumns);
			Items.ChangeTemplate.Visible = False;
			Items.ChangeTemplateFillTable.Visible = False;
			ImportDataFromFile.AddStatisticalInformation("RunMode.ImportToTabularSection.DynamicTemplate",, Parameters.FullTabularSectionName);
		Else
			DataProcessors.ImportDataFromFile.DetermineColumnsInformation(ImportParameters, TableColumnsInformation);
			ChangeTemplateByColumnsInformation();
			ImportDataFromFile.AddStatisticalInformation("RunMode.ImportToTabularSection.StaticTemplate",, Parameters.FullTabularSectionName);
			If Cancel Then
				Return;
			EndIf;
		EndIf;
		ValueToFormAttribute(TableColumnsInformation, "ColumnsInformation");
		
		ShowInfoBarAboutRequiredColumns();
		ChangeTemplateByColumnsInformation();
		
	Else
		FillDataImportTypeList();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If FormClosingConfirmation = Undefined Then
		Return;
	EndIf;
	
	Cancel = Cancel Or (FormClosingConfirmation <> True);
	If Exit Then
		WarningText = NStr("ru = 'Введенные данные не будут записаны.'; en = 'The data that you entered will be lost.'; pl = 'Wprowadzone dane nie zostaną zapisane.';de = 'Die eingegebenen Daten werden nicht gespeichert.';ro = 'Datele introduse nu vor fi înregistrate.';tr = 'Girilen veriler kaydedilmeyecektir.'; es_ES = 'Los datos introducidos no serán guardados.'");
		Return;
	EndIf;
		
	If Cancel Then
		Notification = New NotifyDescription("FormClosingCompletion", ThisObject);
		QuestionText = NStr("ru = 'Введенные данные не будут записаны. Закрыть форму?'; en = 'The data that you entered will be lost. Do you want to close the window?'; pl = 'Wprowadzone dane nie zostaną zapisane. Zamknąć formularz?';de = 'Die eingegebenen Daten werden nicht aufgezeichnet. Formular schließen?';ro = 'Datele introduse nu vor fi înregistrate. Închideți forma?';tr = 'Girilen veriler kaydedilmeyecektir.  Form kapatılsın mı?'; es_ES = 'Los datos introducidos no serán guardados. ¿Cerrar el formulario?'");
		ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
	Else
		If OpenCatalogAfterCloseWizard Then 
			OpenForm(ListForm(MappingObjectName));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportFilterOnChange(Item)

	ReportAtClientBackgroundJob(False);
	
	If ReportFilter = "Skipped" Then
		Items.ChangeAttributes.Enabled=False;
	Else
		Items.ChangeAttributes.Enabled=True;
	EndIf;
EndProcedure

&AtClient
Procedure MappingTableFilterOnChange(Item)
	SetMappingTableFiltering();
EndProcedure

&AtClient
Procedure SetMappingTableFiltering()

	Filter = MappingTableFilter;
	
	If ImportType = "TabularSection" Then
		If Filter = "Mapped" Then
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "RowMapped");
		ElsIf Filter = "Unmapped" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Not");
		ElsIf Filter = "Ambiguous" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Conflict");
		Else
			Items.DataMappingTable.RowFilter = Undefined;
		EndIf;
	ElsIf ImportType = "PastingFromClipboard" Then
		If Filter = "Mapped" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "RowMapped");
		ElsIf Filter = "Unmapped" Then
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Not");
		ElsIf Filter = "Ambiguous" Then
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Conflict");
		Else
			Items.DataMappingTable.RowFilter = Undefined;
		EndIf;
	Else
		If Filter = "Mapped" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "RowMapped");
		ElsIf Filter = "Unmapped" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Not");
		ElsIf Filter = "Ambiguous" Then 
			Items.DataMappingTable.RowFilter = New FixedStructure("RowMappingResult", "Conflict"); 
		Else
			Items.DataMappingTable.RowFilter = Undefined;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure MappingColumnsListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If MapByColumn.Count() = 0 Then
		For each ColumnInfo In ColumnsInformation Do
			If (TypeOf(ColumnInfo.ColumnType) = Type("String")
				 AND ColumnInfo.ColumnType.StringQualifiers.Length = 0)
				 OR StrStartsWith(ColumnInfo.ColumnName, "Property_") Then
					Continue;
			EndIf;
			ColumnPresentation = ?(IsBlankString(ColumnInfo.Synonym), ColumnInfo.ColumnPresentation, ColumnInfo.Synonym);
			MapByColumn.Add(ColumnInfo.ColumnName, ColumnPresentation);
		EndDo;
	EndIf;
	
	FormParameters      = New Structure("ColumnsList", MapByColumn);
	NotifyDescription  = New NotifyDescription("AfterColumnsChoiceForMapping", ThisObject);
	OpenForm("DataProcessor.ImportDataFromFile.Form.SelectColumns", FormParameters, ThisObject, , , , NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterColumnsChoiceForMapping(Result, Parameter) Export
	
	If Result = Undefined Then 
		Return;
	EndIf;
		 
	MapByColumn = Result;
	ColumnsToString = "";
	Separator = "";
	SelectedColumnsCount = 0;
	For each Item In MapByColumn Do 
		If Item.Check Then 
			ColumnsToString = ColumnsToString + Separator + Item.Presentation;
			Separator = ", ";
			SelectedColumnsCount = SelectedColumnsCount + 1;
		EndIf;
	EndDo;
	
	MappingColumnsList = ColumnsToString;
	RunMapping();
EndProcedure

&AtClient
Procedure ImportOptionOnChange(Item)
	
	If ImportOption = 0 Then
		Items.FillWithDataPages.CurrentPage = Items.FillTableOptionPage;
	Else
		Items.FillWithDataPages.CurrentPage = Items.ImportFromFileOptionPage;
	EndIf;
	
	ShowInfoBarAboutRequiredColumns();
	
EndProcedure

&AtClient
Procedure DataImportTypeValueChoice(Item, Value, StandardProcessing)
	StandardProcessing = False;
	ProceedToNextStepOfDataImport();
EndProcedure

&AtClient
Procedure DataImportTypeBeforeStartChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportOnActivateAreaTable(Item)
	If ReportTable.CurrentArea.Bottom = 1 AND ReportTable.CurrentArea.Top = 1 Then
		Items.ChangeAttributes.Enabled = False;
	Else
		Items.ChangeAttributes.Enabled = True;
	EndIf;
EndProcedure

#EndRegion

#Region TemplateWithDataFormTableItemsEventHandlers

&AtClient
Procedure DataTemplateOnActivateArea(Item)
	Item.Protection = ?(Item.CurrentArea.Top > TemplateWithDataHeaderHeight, False, True);
EndProcedure

#EndRegion

#Region DataMappingTableFormTableItemsEventHandlers

&AtClient
Procedure DataMappingTableOnEditEnd(Item, NewRow, CancelEdit)
	
	If ImportType <> "TabularSection" Then
		If ValueIsFilled(Item.CurrentData.MappingObject) Then 
			Item.CurrentData.RowMappingResult = "RowMapped";
		Else
			Item.CurrentData.RowMappingResult = "NotMapped";
		EndIf;
	Else
		Filter = New Structure("Required", True);
		RequiredColumns = ColumnsInformation.FindRows(Filter);
		RowMappingResult = "RowMapped";
		For each TableColumn In RequiredColumns Do
			If NOT ValueIsFilled(Item.CurrentData["TabularSection_" + TableColumn.Parent]) Then
				RowMappingResult = ?(ValueIsFilled(Item.CurrentData.ErrorDescription), "Conflict", "NotMapped");
				Break;
			EndIf;
		EndDo;
		Item.CurrentData.RowMappingResult = RowMappingResult;
	EndIf;
	
	AttachIdleHandler("ShowMappingStatisticsImportFromFile", 0.2, True);
	
EndProcedure

&AtClient
Procedure DataMappingTableOnActivateCell(Item)
	Items.ResolveConflict.Enabled = False;
	Items.DataMappingTableContextMenuResolveConflict.Enabled = False;
	
	If Item.CurrentData <> Undefined AND ValueIsFilled(Item.CurrentData.RowMappingResult) Then 
		If ImportType = "TabularSection" Then 
			If StrLen(Item.CurrentItem.Name) > 3 AND StrStartsWith(Item.CurrentItem.Name, "TabularSection_") Then
				ColumnName = Mid(Item.CurrentItem.Name, 4);
				If StrFind(Item.CurrentData.ErrorDescription, ColumnName) > 0 Then 
					Items.ResolveConflict.Enabled = True;
					Items.DataMappingTableContextMenuResolveConflict.Enabled = True;
				EndIf;
			EndIf;
		ElsIf Item.CurrentData.RowMappingResult = "Conflict" Then 
			Items.ResolveConflict.Enabled = True;
			Items.DataMappingTableContextMenuResolveConflict.Enabled = True;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DataMappingTableSelection(Item, RowSelected, Field, StandardProcessing)
	OpenResolveConflictForm(RowSelected, Field.Name, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CancelMapping(Command)
	Notification = New NotifyDescription("AfterCancelMappingPrompt", ThisObject);
	ShowQueryBox(Notification, NStr("ru = 'Отменить сопоставление?'; en = 'Do you want to clear the mapping?'; pl = 'Anuluj mapowanie?';de = 'Zuordnung abbrechen?';ro = 'Revocați confruntarea?';tr = 'Eşleştirmeyi iptal et?'; es_ES = '¿Cancelar el mapeo?'"), QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure ChangeTemplate(Command)
	OpenChangeTemplateForm();
EndProcedure

&AtClient
Procedure ResolveConflict(Command)
	OpenResolveConflictForm(Items.DataMappingTable.CurrentRow,Items.DataMappingTable.CurrentItem.Name, True);
EndProcedure

&AtClient
Procedure AddToList(Command)
	CloseFormAndReturnRefArray();
EndProcedure

&AtClient
Procedure Next(Command)
	ProceedToNextStepOfDataImport();
EndProcedure

&AtClient
Procedure AfterAddToTabularSectionPrompt(Result, AdditionalParameters) Export 
	If Result = DialogReturnCode.Yes Then 
		ImportedDataAddress = MappingTableAddressInStorage();
		Close(ImportedDataAddress);
	EndIf;
EndProcedure

&AtClient
Procedure CloseFormAndReturnRefArray()
	FormClosingConfirmation = True;
	RefsArray = New Array;
	For each Row In DataMappingTable Do
		If ValueIsFilled(Row.MappingObject) Then
			RefsArray.Add(Row.MappingObject);
		EndIf;
	EndDo;
	
	Close(RefsArray);
EndProcedure

&AtClient
Procedure Back(Command)
	
	StepBack();
	
EndProcedure

&AtClient
Procedure StepBack()
	
	If Items.WizardPages.CurrentPage = Items.FillTableWithData Then
		
		Items.WizardPages.CurrentPage = Items.SelectCatalogToImport;
		Items.Back.Visible = False;
		ThisObject.Title = NStr("ru = 'Загрузка данных в справочник'; en = 'Import data to catalog'; pl = 'Import danych do katalogu';de = 'Datenimport in den Katalog';ro = 'Importul datelor în catalog';tr = 'Kataloga veri içe aktarma'; es_ES = 'Importación de datos al catálogo'");
		ClearTable();
		
	ElsIf Items.WizardPages.CurrentPage = Items.DataToImportMapping
		OR Items.WizardPages.CurrentPage = Items.NotFound
		OR Items.WizardPages.CurrentPage = Items.MappingResults
		OR Items.WizardPages.CurrentPage = Items.TimeConsumingOperations Then
		
		Items.WizardPages.CurrentPage = Items.FillTableWithData;
		Items.AddToList.Visible = False;
		Items.Next.DefaultButton = True;
		Items.Next.Visible = True;
		Items.Next.Enabled = True;
		Items.Next.Title = ?(ImportType = "PastingFromClipboard",
				NStr("ru = 'Вставить в список'; en = 'Add to list'; pl = 'Dodaj do listy';de = 'Zur Liste hinzufügen';ro = 'Adaugă în listă';tr = 'Listeye ekle'; es_ES = 'Agregar a la lista'"), NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'"));
		
		If ImportType = "TabularSection" OR ImportType = "PastingFromClipboard" Then
			Items.Back.Visible = False;
		Else
			Items.Back.Enabled = True;
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.DataImportReport Then
		
		Items.OpenCatalogAfterCloseWizard.Visible = False;
		Items.WizardPages.CurrentPage = Items.DataToImportMapping;
		
	EndIf;

EndProcedure

&AtClient
Procedure ExportTemplateToFile(Command)
	
	Notification = New NotifyDescription("ExportTemplateToFileCompletion", ThisObject);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ImportTemplateFromFile(Command)
	
	FileName = GenerateFileNameForMetadataObject(MappingObjectName);
	
	Notification = New NotifyDescription("ImportDataFromFileToTemplate", ThisObject);
	ImportDataFromFileClient.FileImportDialog(Notification, FileName);
	
EndProcedure

&AtClient
Procedure BatchEditAttributes(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		If ReportTable.CurrentArea.Top = 1 Then
			UpperPosition = 2;
		Else
			UpperPosition = ReportTable.CurrentArea.Top;
		EndIf;
		RefsArray = BatchAttributesModificationAtServer(UpperPosition, ReportTable.CurrentArea.Bottom);
		If RefsArray.Count() > 0 Then
			FormParameters = New Structure("ObjectsArray", RefsArray);
			ObjectName = "DataProcessor.";
			OpenForm(ObjectName + "BatchEditAttributes.Form", FormParameters);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

/////////////////////////////////////// CLIENT ///////////////////////////////////////////

// Ending the form closing dialog.
&AtClient
Procedure FormClosingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		FormClosingConfirmation = True;
		Close();
	Else 
		FormClosingConfirmation = False;
	EndIf;
EndProcedure

&AtClient
Procedure ProceedToNextStepOfDataImport()
	
	If Items.WizardPages.CurrentPage = Items.SelectCatalogToImport Then
		SelectionRowDetails = Items.DataImportKind.CurrentData.Value;
		ExecuteStepFillTableWithDataAtServer(SelectionRowDetails);
		ExecuteStepFillTableWithDataAtClient();
	ElsIf Items.WizardPages.CurrentPage = Items.FillTableWithData Then
		MapDataToImport();
	ElsIf Items.WizardPages.CurrentPage = Items.MappingResults Then
		Items.WizardPages.CurrentPage = Items.DataToImportMapping;
		Items.AddToList.Visible = False;
		Items.Next.Title = NStr("ru = 'Вставить в список'; en = 'Add to list'; pl = 'Dodaj do listy';de = 'Zur Liste hinzufügen';ro = 'Adaugă în listă';tr = 'Listeye ekle'; es_ES = 'Agregar a la lista'");
		Items.Next.DefaultButton = True;
		Items.Back.Title = NStr("ru = '< В начало'; en = '< Go to beginning'; pl = '< do Strony Głównej';de = '< Zum Anfang';ro = '< Salt la prima pagină';tr = '< Başa'; es_ES = '< Ir a la página principal'");
	ElsIf Items.WizardPages.CurrentPage = Items.DataToImportMapping Then
		Items.AddToList.Visible = False;
		FormClosingConfirmation = True;
		If ImportType = "TabularSection" Then
			Filter = New Structure("RowMappingResult", "NotMapped");
			Rows = DataMappingTable.FindRows(Filter);
			If Rows.Count() > 0 Then
				Notification = New NotifyDescription("AfterAddToTabularSectionPrompt", ThisObject);
				ShowQueryBox(Notification, NStr("ru = 'Строки, в которых не заполнены обязательные колонки, будут пропущены.'; en = 'Lines where required columns are blank will be skipped.'; pl = 'Wiersze, w których nie są wypełnione wymagane kolumny, będą pomijane.';de = 'Zeilen, die keine Pflichtspalten enthalten, werden übersprungen.';ro = 'Vor fi omise rândurile, în care nu sunt completate coloanele obligatorii.';tr = 'Boş gerekli sütunları olan satırlar atlanacaktır.'; es_ES = 'Líneas con las columnas en blanco requeridas se saltarán.'")
					+ Chars.LF + NStr("ru = 'Продолжить?'; en = 'Do you want to continue?'; pl = 'Kontynuować?';de = 'Fortsetzen?';ro = 'Continuați?';tr = 'Devam et?'; es_ES = '¿Continuar?'"), QuestionDialogMode.YesNo);
				Return;
			EndIf;
			
			ImportedDataAddress = MappingTableAddressInStorage();
			Close(ImportedDataAddress);
		ElsIf ImportType = "PastingFromClipboard" Then
			Items.Back.Title = NStr("ru = '< В начало_'; en = '< To the beginning'; pl = '< Do początku_';de = '< Zum Anfang_';ro = '< Salt la prima pagină_';tr = '< Başa dön'; es_ES = '< Al inicio_'");
			CloseFormAndReturnRefArray();
		Else
			Items.WizardPages.CurrentPage = Items.TimeConsumingOperations;
			WriteDataToImportClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterMappingConflicts(Result, Parameter) Export
	
	If ImportType  = "TabularSection" Then
		If Result <> Undefined Then
			Row = DataMappingTable.FindByID(Parameter.ID);
			
			Row["TabularSection_" +  Parameter.Name] = Result;
			Row.ErrorDescription = StrReplace(Row.ErrorDescription, Parameter.Name+";", "");
			Row.RowMappingResult = ?(StrLen(Row.ErrorDescription) = 0, "RowMapped", "NotMapped");
		EndIf;
	Else
		Row = DataMappingTable.FindByID(Parameter.ID);
		Row.MappingObject = Result;
		If Result <> Undefined Then
			Row.RowMappingResult = "RowMapped";
			Row.ConflictsList = Undefined;
		Else 
			If Row.RowMappingResult <> "Conflict" Then 
				Row.RowMappingResult = "NotMapped";
				Row.ConflictsList = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
	ShowMappingStatisticsImportFromFile();
	
EndProcedure

&AtClient
Procedure RunMapping()
	ItemsMappedByColumnsCount = 0;
	ColumnsList = "";
	ExecuteMappingBySelectedAttribute(ItemsMappedByColumnsCount, ColumnsList);
	ShowUserNotification(NStr("ru = 'Выполнено сопоставление'; en = 'Mapping completed'; pl = 'Zmapowany';de = 'Zugeordnet';ro = 'Este executată confruntarea';tr = 'Eşlendi'; es_ES = 'Mapeado'"),, NStr("ru = 'Сопоставлено элементов:'; en = 'Items mapped:'; pl = 'Elementy zmapowane:';de = 'Artikel zugeordnet:';ro = 'Elementele mapate:';tr = 'Eşlenmiş öğeler:'; es_ES = 'Artículos mapeados:'") + " " + String(ItemsMappedByColumnsCount));
	ShowMappingStatisticsImportFromFile();
EndProcedure

&AtClient
Function AllDataMapped()
	Filter = New Structure("RowMappingResult", "RowMapped");
	Result = DataMappingTable.FindRows(Filter);
	MappedItemsCount = Result.Count();
	
	If DataMappingTable.Count() = MappedItemsCount Then 
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Function MappingStatistics()
	
	Filter                    = New Structure("RowMappingResult", "RowMapped");
	Result                = DataMappingTable.FindRows(Filter);
	MappedItemsCount = Result.Count();
	
	If ImportType = "PastingFromClipboard" Then
		Filter                   = New Structure("RowMappingResult", "NotMapped");
		Result               = DataMappingTable.FindRows(Filter);
		ConflictingItemsCount = DataMappingTable.Count() - MappedItemsCount - Result.Count();
	Else
		Filter                   = New Structure("ErrorDescription", "");
		Result               = DataMappingTable.FindRows(Filter);
		ConflictingItemsCount = DataMappingTable.Count() - Result.Count();
	EndIf;
	UnmappedItemsCount  = DataMappingTable.Count() - MappedItemsCount;
	
	Result = New Structure;
	Result.Insert("Total",            DataMappingTable.Count());
	Result.Insert("Mapped",   MappedItemsCount);
	Result.Insert("Ambiguous",    ConflictingItemsCount);
	Result.Insert("Notmapped", UnmappedItemsCount);
	Result.Insert("NotFound",        UnmappedItemsCount - ConflictingItemsCount);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ShowMappingStatisticsImportFromFile()
	
	Statistics = MappingStatistics();
	
	AllText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Все (%1)'; en = 'All (%1)'; pl = 'Wszystko (%1)';de = 'Alle (%1)';ro = 'Toate (%1)';tr = 'Tümü (%1)'; es_ES = 'Todo (%1)'"), Statistics.Total);
	
	Items.CreateIfUnmapped.Title = NStr("ru = 'Несопоставленные ('; en = 'Unmapped items ('; pl = 'Odwzorowany (';de = 'Nicht zugeordnet (';ro = 'Nemapate (';tr = 'Eşlenmedi ('; es_ES = 'No mapeado ('") + Statistics.NotMapped + ")";
	Items.UpdateExistingItems.Title       = NStr("ru = 'Сопоставленные элементы ('; en = 'Mapped items ('; pl = 'Zmapowane elementy (';de = 'Zugeordnete Artikel (';ro = 'Elementele confruntate (';tr = 'Eşlenen öğeler ('; es_ES = 'Artículos mapeados ('") + String(Statistics.Mapped) + ")";
	
	ChoiceList = Items.MappingTableFilter.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("All", AllText, True);
	ChoiceList.Add("Unmapped", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Несопоставленные (%1 из %2)'; en = 'Unmapped items (%1 out of %2)'; pl = 'Odwzorowany (%1 z %2)';de = 'Nicht zugeordnet (%1 aus %2)';ro = 'Nemapate (%1 din %2)';tr = 'Eşlenmemiş (%1''nin %2)'; es_ES = 'No mapeado (%1 de %2)'"),
		Statistics.NotMapped, Statistics.Total));
	ChoiceList.Add("Mapped", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сопоставленные (%1 из %2)'; en = 'Mapped items (%1 of %2)'; pl = 'Dopasowane (%1 z %2)';de = 'Zugeordnet (%1 von %2)';ro = 'Mapat (%1 din %2)';tr = 'Eşlenmiş (%1 / %2)'; es_ES = 'Mapeado (%1 de %2)'"),
		Statistics.Mapped, Statistics.Total));
	ChoiceList.Add("Ambiguous", StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неоднозначные (%1 из %2)'; en = 'Ambiguous items (%1 out of %2)'; pl = 'Dwuznaczne (%1 z %2)';de = 'Mehrdeutig (%1 aus %2)';ro = 'Ambiguă (%1 din %2)';tr = 'Belirsiz (%1''nin %2)'; es_ES = 'Ambiguo (%1 de %2)'"),
		Statistics.Ambiguous, Statistics.Total));
	
	If Statistics.Ambiguous > 0 Then
		Items.ConflictDetails.Visible = True;
		Items.ConflictDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '(неоднозначностей: %1)'; en = '(conflicts: %1)'; pl = '(dwuznaczności:%1)';de = '(Mehrdeutigkeiten :%1)';ro = '(ambiguități:%1)';tr = '(belirsizlik: %1)'; es_ES = '(ambigüedades:%1)'"),
			Statistics.Ambiguous);
	Else
		Items.ConflictDetails.Visible = False;
	EndIf;
	
	If NOT ValueIsFilled(MappingTableFilter) Then 
		MappingTableFilter = "Unmapped";
	EndIf;
	
	If ImportType = "PastingFromClipboard" Then
		SetMappingTableFiltering();
	Else
		SetMappingTableFiltering();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportTemplateToFileCompletion(Attached, AdditionalParameters) Export
	
	If Attached Then
		Notification = New NotifyDescription("AfterFileChoiceForSaving", ThisObject);
		FileName = GenerateFileNameForMetadataObject(MappingObjectName);
		FileSelectionDialog = New FileDialog(FileDialogMode.Save);
		FileSelectionDialog.Filter                      = NStr("ru='Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Текстовый документ c разделителями (*.csv)|*.csv|Табличный документ (*.mxl)|*.mxl'; en = 'Excel Workbook 97 (*.xls)|*.xls|Excel Workbook 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Comma-separated text (*.csv)|*.csv|Spreadsheet document (*.mxl)|*.mxl'; pl = 'Księga Excel 97 (*.xls)|*.xls|Księga Excel 2007 (*.xlsx)|*.xlsx|Tablica elektroniczna OpenDocument (*.ods)|*.ods| Dokument tekstowy c przegródkami (*.csv)|*.csv|Dokument tabelaryczny (*.mxl)|*.mxl';de = 'Excel 97 (*.xls)|*.xls|Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Tabellenkalkulation (*.ods)|*.ods|Textdokument mit Trennzeichen (*.csv)|*.csv|Tabellendokument (*.mxl)|*.mxl';ro = 'Cartea Excel 97 (*.xls)|*.xls|Cartea Excel 2007 (*.xlsx)|*.xlsx|Tabel electronic OpenDocument (*.ods)|*.ods|Document text cu separatori (*.csv)|*.csv|Document tabelar (*.mxl)|*.mxl';tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|Virgüllerle ayrılmış değerler dosyası (*.csv)|*.csv|Tablo belgesi (*.mxl)|*.mxl'; es_ES = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabla electrónica OpenDocument (*.ods)|*.ods|Documento de texto con separadores (*.csv)|*.csv|Documento de tabla (*.mxl)|*.mxl'");
		FileSelectionDialog.DefaultExt                  = "xls";
		FileSelectionDialog.Multiselect = False;
		FileSelectionDialog.FilterIndex               = 0;
		FileSelectionDialog.FullFileName = FileName;
		FileSystemClient.ShowSelectionDialog(Notification, FileSelectionDialog);
	Else
		Notification = New NotifyDescription("AfterFileExtensionChoice", ThisObject);
		OpenForm("DataProcessor.ImportDataFromFile.Form.FileExtention",, ThisObject, True,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

/////////////////////////////////////// SERVER ///////////////////////////////////////////

&AtServer
Procedure InsertFromClipboardInitialization()
	MappingTableFilter = "Unmapped";
	
	If Parameters.Property("FieldPresentation") Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вставка из буфера обмена (%1)'; en = 'Paste (%1)'; pl = 'Wstaw ze schowka (%1)';de = 'Aus der Zwischenablage einfügen (%1)';ro = 'Inserare din clipboard (%1)';tr = 'Panodan kopyala (%1)'; es_ES = 'Inserción del portapapeles (%1)'"), Parameters.FieldPresentation);
	Else
		Title = NStr("ru = 'Вставка из буфера обмена'; en = 'Paste'; pl = 'Wstaw ze schowka';de = 'Aus der Zwischenablage einfügen';ro = 'Inserare din clipboard';tr = 'Panodan kopyalama'; es_ES = 'Inserción del portapapeles'");
	EndIf;
	
	ImportDataFromFile.AddStatisticalInformation("RunMode.PastingFromClipboard");
	
	DataProcessors.ImportDataFromFile.SetInsertModeFromClipboard(TemplateWithData, ColumnsInformation, Parameters.TypeDescription);
	CreateMappingTableByColumnsInformationAuto(Parameters.TypeDescription);
	
	If ColumnsInformation.Count() = 1 Then
		Items.FillWithDataPages.CurrentPage = Items.SingleColumnPage;
		Items.ImportOption.Visible = False;
		Items.AddToList.Visible = False;
		Items.Next.Title = NStr("ru = 'Вставить в список'; en = 'Add to list'; pl = 'Dodaj do listy';de = 'Zur Liste hinzufügen';ro = 'Adaugă în listă';tr = 'Listeye ekle'; es_ES = 'Agregar a la lista'");
	Else
		Items.FillWithDataPages.CurrentPage = Items.FillTableOptionPage;
	EndIf;

EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	ThisObject.Title = ?(IsBlankString(Parameters.Title), NStr("ru = 'Загрузка данных в справочник'; en = 'Import data to catalog'; pl = 'Import danych do katalogu';de = 'Datenimport in den Katalog';ro = 'Importul datelor în catalog';tr = 'Kataloga veri içe aktarma'; es_ES = 'Importación de datos al catálogo'"), Parameters.Title);
	
	If Common.IsWebClient() Then
		Items.FillTableOptionPage.Visible = False;
		Items.FillWithDataPages.CurrentPage = Items.ImportFromFileOptionPage;
		Items.ImportOption.Visible = False;
		Items.SelectCatalogToImportNote.Title = NStr("ru = 'Выбор справочника для загрузки данных из электронных таблиц, расположенных во внешних файлах 
		| (например: Microsoft Office Excel, OpenOffice Calc и др.).'; 
		|en = 'Select a catalog to import data from external spreadsheet files
		|(such as Microsoft Office Excel or OpenOffice Calc Spreadsheet).'; 
		|pl = 'Wybór przewodnika dla pobierania danych z tablic elektronicznych, znajdujących się w zewnętrznych plikach
		| (na przykład: Microsoft Office Excel, OpenOffice Calc i inne).';
		|de = 'Wählen Sie ein Verzeichnis aus, um Daten aus Tabellenkalkulationen in externen Dateien 
		| (z.B. Microsoft Office Excel, OpenOffice Calc, etc.) herunterzuladen.';
		|ro = 'Selectarea clasificatorului pentru importul de date din tabelele electronice amplasate în fișierele externe 
		|(de exemplu: Microsoft Office Excel, OpenOffice Calc etc.).';
		|tr = 'Harici  dosyalarda
		| bulunan elektronik tablolardan veri almak için bir katalog  seçin (örneğin: Microsoft Office Excel, OpenOffice Calc, vb.).'; 
		|es_ES = 'Seleccionar un catálogo para importar los datos desde las hojas de cálculo ubicadas en los archivos externos 
		| (por ejemplo: Microsoft Office Excel, Cálculo de OpenOffice, etc).'");
	EndIf;
	
	If ImportType = "PastingFromClipboard" Then
		Items.WizardPages.CurrentPage = Items.FillTableWithData;
		Items.MappingSettingsGroup.Visible = False;
		Items.MappingColumnsList.Visible = False;
		Items.Close.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
	ElsIf ImportType = "TabularSection" Then
		Items.WizardPages.CurrentPage = Items.FillTableWithData;
		Items.MappingSettingsGroup.Visible = False;
		Items.MappingColumnsList.Visible = False;
	Else
		Items.WizardPages.CurrentPage = Items.SelectCatalogToImport;
	EndIf;
	
EndProcedure



#Region SelectImportOptionStep

&AtServer
Procedure FillDataImportTypeList()
	DataProcessors.ImportDataFromFile.CreateCatalogsListForImport(ImportOptionsList);
EndProcedure 

#EndRegion

#Region FillTableWithDataStep

&AtClient
Procedure ExecuteStepFillTableWithDataAtClient()
	
	Items.WizardPages.CurrentPage = Items.FillTableWithData;
	Items.Back.Visible = True;
	TemplateWithDataHeaderHeight = ?(ImportDataFromFileClientServer.ColumnsHaveGroup(ColumnsInformation), 2, 1);
	
EndProcedure

&AtClient
Function EmptyDataTable()
	If ColumnsInformation.Count() = 1 AND TemplateWithData.TableHeight < 2 Then
		If NOT ValueIsFilled(TemplateWithDataSingleColumn) Then
			Return True;
		EndIf;
		CopySingleColumnToTemplateWithData();
	Else 
		If TemplateWithData.TableHeight < 2 Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtClient
Procedure OpenChangeTemplateForm()
	
	Var Notification, FormParameters;
	
	FormParameters = New Structure();
	FormParameters.Insert("ColumnsInformation", ColumnsInformation);
	FormParameters.Insert("MappingObjectName", MappingObjectName);
	FormParameters.Insert("ImportParameters", ImportParameters);
	
	Notification = New NotifyDescription("AfterCallFormChangeTemplate", ThisObject);
	OpenForm("DataProcessor.ImportDataFromFile.Form.EditTemplate", FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServerNoContext
Function GetFullMetadataObjectName(Name)
	MetadataObject = Metadata.Catalogs.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	MetadataObject = Metadata.Documents.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	MetadataObject = Metadata.ChartsOfCharacteristicTypes.Find(Name);
	If MetadataObject <> Undefined Then 
		Return MetadataObject.FullName();
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Procedure ExecuteStepFillTableWithDataAtServer(SelectionRowDetails)
	
	If StrFind(SelectionRowDetails.FullMetadataObjectName, ".") > 0 Then
		MappingObjectName = SelectionRowDetails.FullMetadataObjectName;
	Else
		MappingObjectName = GetFullMetadataObjectName(SelectionRowDetails.FullMetadataObjectName);
	EndIf;
	
	ImportType = SelectionRowDetails.Type;
	If ImportType = "ExternalImport" Then
		ExternalDataProcessorRef = SelectionRowDetails.Ref;
		CommandID = SelectionRowDetails.ID;
	EndIf;
	ImportDataFromFile.AddStatisticalInformation("RunMode.ImportToCatalog." + MappingObjectName,, ImportType);
	
	If TypeOf(SelectionRowDetails) = Type("Structure") AND SelectionRowDetails.Property("Presentation") Then
		ThisObject.Title = NStr("ru='Загрузка данных в справочник'; en = 'Import data to catalog'; pl = 'Import danych do katalogu';de = 'Datenimport in den Katalog';ro = 'Importul datelor în catalog';tr = 'Kataloga veri içe aktarma'; es_ES = 'Importación de datos al catálogo'") + " """ +SelectionRowDetails.Presentation + """";
	Else
		ThisObject.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Загрузка данных в справочник ""%1""'; en = 'Import data to catalog ""%1""'; pl = 'Ładowanie danych do katalogu ""%1""';de = 'Hochladen von Daten in das Verzeichnis ""%1""';ro = 'Importul datelor în clasificator ""%1""';tr = '""%1"" Kataloga veri içe aktarma'; es_ES = 'Importar datos al catálogo ""%1""'"), CatalogPresentation(MappingObjectName));
	EndIf;

	GenerateTemplateByImportType();
	CreateMappingTableByColumnsInformation();
	ShowInfoBarAboutRequiredColumns();
	
EndProcedure

&AtServer
Procedure GenerateTemplateByImportType()
	
	ImportParameters = New Structure;
	If ImportType = "UniversalImport" Then
		ThisObject.AutoTitle = False;
	ElsIf ImportType = "AppliedImport" Then
		DefineImportParameters(ImportParameters);
		ThisObject.AutoTitle = False;
		If ImportParameters.Property("Title") Then
			ThisObject.Title = ImportParameters.Title;
		EndIf;
	ElsIf ImportType = "ExternalImport" Then
		ImportParameters.Insert("DataStructureTemplateName", "ImportDataFromFile");
		DataProcessors.ImportDataFromFile.ParametersOfImportFromFileExternalDataProcessor(CommandID,
			ExternalDataProcessorRef, ImportParameters);
	EndIf;
	ImportParameters.Insert("ImportType", ImportType);
	ImportParameters.Insert("FullObjectName", MappingObjectName);
	
	ColumnsInformationTable = Common.CommonSettingsStorageLoad("ImportDataFromFile", MappingObjectName,, UserName());
	If ColumnsInformationTable = Undefined Then
		ColumnsInformationTable = FormAttributeToValue("ColumnsInformation");
	EndIf;
	DataProcessors.ImportDataFromFile.DetermineColumnsInformation(ImportParameters, ColumnsInformationTable);
	ValueToFormAttribute(ColumnsInformationTable, "ColumnsInformation");
	
	ChangeTemplateByColumnsInformation();
EndProcedure

&AtServer
Procedure SaveTableToCSVFile(FullFileName)
	DataProcessors.ImportDataFromFile.SaveTableToCSVFile(FullFileName, ColumnsInformation);
EndProcedure

#EndRegion

#Region ImportedDataMappingStep

&AtServer
Procedure CopySingleColumnToTemplateWithData()
	
	ClearTemplateWithData();
	
	RowsCount = StrLineCount(TemplateWithDataSingleColumn);
	RowNumberInTemplate = 2;
	For RowNumber = 1 To RowsCount Do 
		Row = StrGetLine(TemplateWithDataSingleColumn, RowNumber);
		If ValueIsFilled(Row) Then
			Cell = TemplateWithData.GetArea(RowNumberInTemplate, 1, RowNumberInTemplate, 1);
			Cell.CurrentArea.Text = Row;
			TemplateWithData.Put(Cell);
			RowNumberInTemplate = RowNumberInTemplate + 1;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure MapDataToImportAtServer()
	
	ImportDataFromFile.AddStatisticalInformation(?(ImportOption = 0,
		"ImportOption.FillTable", "ImportOption.FromExternalFile"));
	
	TableColumnsInformation = FormAttributeToValue("ColumnsInformation");
	If ImportType = "TabularSection" Then
		ImportedDataAddress = "";
		TabularSectionCopyAddress = "";
		ConflictsList = CreateTableWithConflictsList();
		
		DataProcessors.ImportDataFromFile.SpreadsheetDocumentIntoValuesTable(TemplateWithData, TableColumnsInformation, ImportedDataAddress);
		
		CopyTabularSectionStructure(TabularSectionCopyAddress);
		
		ObjectManager = ObjectManager(MappingObjectName);
		ObjectManager.MapDataToImport(ImportedDataAddress, TabularSectionCopyAddress, ConflictsList, MappingObjectName, AdditionalParameters);
		
		If NOT AttributesCreated Then
			CreateMappingTableByColumnsInformationForTS();
		EndIf;
		PutDataInMappingTable(ImportedDataAddress, TabularSectionCopyAddress, ConflictsList);
		
	ElsIf ImportType = "PastingFromClipboard" Then
		MappingTable = FormAttributeToValue("DataMappingTable");
		DataProcessors.ImportDataFromFile.FillMappingTableWithDataFromTemplate(TemplateWithData, MappingTable, ColumnsInformation);
		DataProcessors.ImportDataFromFile.MapAutoColumnValue(MappingTable, "References");
		ValueToFormAttribute(MappingTable, "DataMappingTable");
	EndIf;
	
EndProcedure

&AtServer
Function CreateTableWithConflictsList()
	ConflictsList = New ValueTable;
	ConflictsList.Columns.Add("ID");
	ConflictsList.Columns.Add("Column");
	
	Return ConflictsList;
EndFunction

&AtServer
Procedure ExecuteDataToImportMappingStepAfterMapAtServer(ResultAddress)
	
	MappingTable = GetFromTempStorage(ResultAddress);
	
	If ImportType = "AppliedImport" Then
		MapDataAppliedImport(MappingTable);
		Items.AppliedImportNote.Title = StrReplace(Items.AppliedImportNote.Title, "%1",
			CatalogPresentation(MappingObjectName));
	ElsIf ImportType = "ExternalImport" Then
		MapDataExternalDataProcessor(MappingTable);
	EndIf;
	
	Items.AppliedImportNote.Title = StrReplace(Items.AppliedImportNote.Title, "%1",
		CatalogPresentation(MappingObjectName));
	
	ValueToFormAttribute(MappingTable, "DataMappingTable");
	
EndProcedure

&AtClient
Procedure MapDataToImport()
	
	If EmptyDataTable() Then
		If ImportType = "PastingFromClipboard" Then
			ShowMessageBox(, (NStr("ru ='Для вставки сопоставленных данных в список, необходимо заполнить текстовое поле.'; en = 'To add mapped data to the list, fill in the text field.'; pl = 'Aby wstawić dopasowane dane do listy, należy wypełnić pole tekstowe.';de = 'Um die übereinstimmenden Daten in die Liste einzufügen, müssen Sie das Textfeld ausfüllen.';ro = 'Pentru lipirea datelor confruntate în listă trebuie să completați caseta de text.';tr = 'Eşlenen verileri bir listeye eklemek için bir metin kutusu doldurulmalıdır.'; es_ES = 'Para pegar los datos mapeados en la lista es necesario rellenar el campo de texto.'")));
			Return;
		EndIf;
		
		If ImportOption = 0 Then
			ShowMessageBox(, (NStr("ru ='Для сопоставления и загрузки данных, необходимо заполнить таблицу.'; en = 'To map and import data, fill in the table.'; pl = 'Dla dopasowania i pobierania danych, należy wypełnić tabelę.';de = 'Um die Daten vergleichen und herunterladen zu können, müssen Sie die Tabelle ausfüllen.';ro = 'Pentru confruntarea și încărcarea datelor trebuie să completați tabelul.';tr = 'Verileri eşlemek ve yüklemek için tablo doldurulmalıdır.'; es_ES = 'Para mapear y cargar los datos es necesario rellenar la tabla.'")));
		Else
			ShowMessageBox(, (NStr("ru ='Невозможно выполнить сопоставление данных, т.к данные не были загружены в таблицу. 
			|Возможно, имена колонок в файле не соответствуют колонкам в бланке.'; 
			|en = 'Cannot map data as the data was not imported to the table.
			|Probably the column names in the file are different from the column names in the template.'; 
			|pl = 'Nie można wykonać dopasowania danych, ponieważ dane nie zostały przesłane do tabeli.
			|Możliwie, nazwy kolumn w pliku nie są zgodne z kolumnami w arkuszu.';
			|de = 'Ein Datenvergleich ist nicht möglich, da die Daten nicht in die Tabelle geladen wurden. 
			|Es ist möglich, dass die Namen der Spalten in der Datei nicht mit den Spalten im Formular übereinstimmen.';
			|ro = 'Nu puteți executa confruntarea datelor, deoarece datele nu au fost încărcate în tabel. 
			| Posibil, numele coloanelor în fișier nu corespund coloanelor în formular.';
			|tr = 'Veri eşlemesi gerçekleştirilemiyor çünkü veri tabloya yüklenmedi. 
			|Muhtemelen dosyadaki sütun adları boştaki sütunlarla eşleşmemektedir.'; 
			|es_ES = 'Es necesario mapear los datos porque los datos no están cargados en la tabla. 
			|Es posible que los nombres de columnas en el archivo no coincidan a la columna en el impreso.'")));
		EndIf;
		ExecuteStepFillTableWithDataAtClient();
		CommandBarButtonsAvailability(True);
		Return;
	EndIf;
	
	FormClosingConfirmation = False;
	UnfilledColumnsList = NotFilledRequiredColumns();
	If UnfilledColumnsList.Count() > 0 Then
		If UnfilledColumnsList.Count() = 1 Then
			TextAboutColumns = NStr("ru = 'Обязательная колонка""'; en = 'Required column ""'; pl = 'Obowiązkowa kolumna ""';de = 'Pflichtspalte ""';ro = 'Coloană obligatorie""';tr = 'Zorunlu sütun ""'; es_ES = 'Columna obligatoria""'") + " " + UnfilledColumnsList[0]
				+ NStr("ru = '"" содержит незаполненные строки, эти строки будут пропущены при загрузке.'; en = '"" contains blank lines. These lines will be skipped during the data import.'; pl = '""zawiera puste wiersze, wiersze te będą pomijane podczas ładowania.';de = '"" enthält Leerzeilen, diese Zeilen werden beim Start übersprungen.';ro = '"" conține rânduri goale, aceste rânduri vor fi omise în timpul importului.';tr = '""boş dizeleri içerir, içe aktarma sırasında bu dizeler dikkate alınmaz.'; es_ES = '"" contiene líneas vacías, estas líneas se ignorarán durante la importación.'");
		Else
			TextAboutColumns = NStr("ru = 'Обязательные колонки""'; en = 'Required columns ""'; pl = 'Obowiązkowe kolumny ""';de = 'Pflichtspalten ""';ro = 'Coloane obligatorii""';tr = 'Zorunlu sütunlar ""'; es_ES = 'Columnas obligatorias ""'") + " " + StrConcat(UnfilledColumnsList,", ")
				+ NStr("ru = '"" содержат незаполненные строки, эти строки будут пропущены при загрузке.'; en = '"" contain blank lines. These lines will be skipped during the data import.'; pl = '""zawierają puste wiersze, wiersze te będą pomijane podczas ładowania.';de = '"" enthalten Leerzeilen, diese Zeilen werden beim Start übersprungen.';ro = '"" conțin rânduri goale, aceste rânduri vor fi omise în timpul importului.';tr = '""boş dizeleri içerir, bu dizeler içe aktarma sırasında yok sayılır.'; es_ES = '"" contienen línea vacías, estas líneas se ignorarán durante la importación.'");
		EndIf;
		TextAboutColumns = TextAboutColumns + Chars.LF + NStr("ru = 'Продолжить?'; en = 'Do you want to continue?'; pl = 'Kontynuować?';de = 'Fortsetzen?';ro = 'Continuați?';tr = 'Devam et?'; es_ES = '¿Continuar?'");
		
		Notification = New NotifyDescription("AfterQuestionAboutBlankStrings", ThisObject);
		ShowQueryBox(Notification, TextAboutColumns, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	Else
		ExecuteDataToImportMappingStepAfterCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionAboutBlankStrings(Result, Parameter) Export
	If Result = DialogReturnCode.Yes Then 
		ExecuteDataToImportMappingStepAfterCheck();
	Else
		StepBack();
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteDataToImportMappingStepAfterCheck()
	
	CommandBarButtonsAvailability(False);
	
	If ImportType = "PastingFromClipboard" OR ImportType = "TabularSection" Then
		MapDataToImportAtServer();
		If AllDataMapped() AND ImportType = "PastingFromClipboard" Then
			CloseFormAndReturnRefArray();
		Else
			ExecuteDataToImportMappingStepClient();
		EndIf;
	Else
		ExecutionProgressNotification = New NotifyDescription("ExecutionProgress", ThisObject);
		BackgroundJob = MapDataToImportAtServerUniversalImport();
		If BackgroundJob.Status = "Running" Then
			Items.WizardPages.CurrentPage = Items.TimeConsumingOperations;
		EndIf;
	
		WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		WaitSettings.OutputIdleWindow = False;
		WaitSettings.ExecutionProgressNotification = ExecutionProgressNotification;
		
		Handler = New NotifyDescription("AfterMapImportedData", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandBarButtonsAvailability(Availability)
	
	Items.Back.Enabled = Availability;
	Items.Next.Enabled = Availability;

EndProcedure

&AtClient
Procedure GoToPage(DisplayedPage)
	
	CommandBarButtonsAvailability(True);
	Items.WizardPages.CurrentPage = DisplayedPage;
EndProcedure

#Region TimeConsumingOperations

&AtClient
Procedure WriteDataToImportClient()
	
	CommandBarButtonsAvailability(False);
	
	ObjectName = CatalogPresentation(MappingObjectName);
	Items.OpenCatalogAfterCloseWizard.Title = 
		StrReplace(Items.OpenCatalogAfterCloseWizard.Title, "%1", ObjectName);
	Items.ImportReportNote.Title = 
		StrReplace(Items.ImportReportNote.Title, "%1", ObjectName);
	
	If ImportType <> "UniversalImport" Then
		SaveDataToImportReport();
		ReportAtClientBackgroundJob();
	Else
		BackgroundJobPercentage = 0;
		BackgroundJob = RecordDataToImportReportUniversalImport();
		If BackgroundJob.Status = "Running" Then
			Items.WizardPages.CurrentPage = Items.TimeConsumingOperations;
		EndIf;
		
		ExecutionProgressNotification = New NotifyDescription("ExecutionProgress", ThisObject);
		WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		WaitSettings.OutputIdleWindow = False;
		WaitSettings.ExecutionProgressNotification = ExecutionProgressNotification;
		
		Handler = New NotifyDescription("AfterSaveDataToImportReport", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportAtClientBackgroundJob(DontOutputWaitWindow = True)
	
	BackgroundJob = GenerateReportOnImport(ReportFilter, DontOutputWaitWindow);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = NOT DontOutputWaitWindow;
		
	Handler = New NotifyDescription("AfterCreateReport", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtClient
Procedure ShowReport(ResultAddress)
	
	Report = GetFromTempStorage(ResultAddress);
	
	If Items.WizardPages.CurrentPage <> Items.DataImportReport Then
		ExecuteDataImportReportStepClient();
	EndIf;
	
	CreatedItemsTotalReport = Report.Created;
	TotalItemsUpdatedReport = Report.Updated;
	SkippedItemsTotalReport = Report.Skipped;
	TotalInvalidItemsReport = Report.Invalid;
	
	Items.ReportFilter.ChoiceList.Clear();
	Items.ReportFilter.ChoiceList.Add("AllItems", NStr("ru = 'Все ('; en = 'All ('; pl = 'Wszyscy (';de = 'Alle (';ro = 'Toate (';tr = 'Tümü ('; es_ES = 'Todo ('") + Report.Total + ")");
	Items.ReportFilter.ChoiceList.Add("NewProperties", NStr("ru = 'Новые ('; en = 'New items ('; pl = 'Nowe (';de = 'Neu (';ro = 'Nou (';tr = 'Yeni ('; es_ES = 'Nuevo ('") + Report.Created+ ")");
	Items.ReportFilter.ChoiceList.Add("Updated", NStr("ru = 'Обновленные ('; en = 'Updated items ('; pl = 'Zaktualizowane (';de = 'Aktualisiert (';ro = 'Actualizat (';tr = 'Güncellenen ('; es_ES = 'Actualizado ('") + Report.Updated+ ")");
	Items.ReportFilter.ChoiceList.Add("Skipped", NStr("ru = 'Пропущенные ('; en = 'Skipped items ('; pl = 'Pominięte (';de = 'Verpasst (';ro = 'Omise (';tr = 'Boş bırakılan ('; es_ES = 'Falta ('") + Report.Skipped+ ")");
	ReportFilter = Report.ReportType;

	ReportTable = Report.ReportTable;
	
EndProcedure

&AtClient
Procedure OutputErrorMessage(ErrorTextForUser, TechnicalInformation)
	ErrorMessageText = ErrorTextForUser + Chars.LF
		+ NStr("ru = 'Возможная причина: Загружаемые данные некорректные.
					|Техническая информация: %1'; 
					|en = 'Possible reason: the data to be imported is invalid.
					|Details: %1'; 
					|pl = 'Możliwa przyczyna: Pobierane dane są nieprawidłowe.
					|Informacje techniczne:%1';
					|de = 'Mögliche Ursache: Die heruntergeladenen Daten sind falsch.
					|Technische Informationen: %1 ';
					|ro = 'Cauza posibilă: Datele încărcate sunt incorecte.
					|Informații tehnice: %1';
					|tr = 'Olası neden: Girilen veriler yanlış. 
					| Teknik bilgi: %1'; 
					|es_ES = 'Causa posible: Datos cargados incorrectos.
					|Información técnica: %1'");
	ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageText, TechnicalInformation);
	CommonClient.MessageToUser(ErrorMessageText);
EndProcedure

#EndRegion

&AtClient
Procedure ExecuteDataToImportMappingStepClient()
	
	If ImportType = "PastingFromClipboard" Then
		Statistics = MappingStatistics();
		
		If Statistics.Mapped > 0 Then
			TextFound = NStr("ru = 'Из %1 введенных строк в список будут вставлены: %2.'; en = '%2 out of %1 entered lines will be added to the list.'; pl = '%2 z %1 wprowadzonych wierszy zostanie dodanych do listy.';de = '%2 aus der %1 eingegebenen Zeilen werden der Liste hinzugefügt.';ro = '%2 din %1 liniile introduse vor fi adăugate în listă.';tr = 'Girilen %2 satırdan %1 listeye eklenecektir.'; es_ES = '%2 de %1 líneas introducidas se agregarán a la lista.'");
			Items.MappingResultLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(TextFound,
				Statistics.Total, Statistics.Mapped);
			
			If Statistics.Ambiguous > 0 AND Statistics.NotFound > 0 Then 
				TextNotFound = NStr("ru = '%3 строк будут пропущены:'; en = '%3 lines will be skipped:'; pl = '%3 wierszy będzie pominiętych:';de = '%3 Zeilen werden übersprungen:';ro = '%3 rânduri vor fi omise:';tr = '%3 satır atlatılacak:'; es_ES = '%3 líneas se ignorarán:'") + Chars.LF + "  - " + NStr("ru = 'Нет данных в программе: %1'; en = 'No matches in the application: %1.'; pl = 'Brak danych w aplikacji: %1';de = 'Keine Daten in der Anwendung: %1';ro = 'Nu există date în aplicație: %1';tr = 'Uygulamada veri yok:  %1'; es_ES = 'No hay datos en la aplicación: %1'") 
					+ Chars.LF + "  - " +NStr("ru = 'Несколько вариантов для вставки: %2'; en = 'Multiple matches: %2.'; pl = 'Kilka wariantów do wstawienia: %2';de = 'Mehrere Varianten zum Einfügen: %2';ro = 'Mai multe variante de inserat: %2';tr = 'Eklenecek çeşitli seçenekler: %2'; es_ES = 'Varias variantes para insertar: %2'");
				TextNotFound = NStr("ru = 'Будет пропущено строк: %3
				|  - Нет данных в программе: %1
				|  - Несколько вариантов для вставки: %2'; 
				|en = '%3 lines will be skipped:
				| - No matches in the application: %1.
				| - Multiple matches: %2.'; 
				|pl = 'Zostaną pominięte wiersze: %3
				| - Brak danych w programie: %1
				| - Kilka opcji dla wstawienia: %2';
				|de = 'Folgende Zeilen werden übersprungen:%3
				|  - Keine Daten im Programm: %1
				|  - Mehrere Optionen zum Einfügen: %2';
				|ro = 'Vor fi omise rândurile: %3
				|  - Lipsesc datele în program: %1
				|  - Mai multe variante pentru inserare: %2';
				|tr = 'Atlatılacak satırlar: %3
				|  - Uygulamada veri yok: %1
				|  - Eklemek için birkaç seçenek: %2'; 
				|es_ES = 'Se ignorarán líneas: %3
				| - No hay datos en el programa: %1
				| -Unas variantes para pegar: %2'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersToString(TextNotFound, Statistics.NotFound, Statistics.Ambiguous, Statistics.Notmapped);
			ElsIf Statistics.Ambiguous > 0 Then
				TextNotFound = NStr("ru = 'Строки, для которых в программе имеется несколько вариантов, будут пропущены: %1'; en = '%1 lines with multiple matches to be skipped.'; pl = 'Wiersze, dla których istnieje wiele wariantów w aplikacji, zostaną pominięte: %1';de = 'Zeichenfolgen, für die es in der Anwendung mehrere Varianten gibt, werden übersprungen: %1';ro = 'Rândurile, pentru care în program există mai multe variante, vor fi omise: %1';tr = 'Uygulamada birden fazla seçenek bulunan dizeler atlanacaktır: %1'; es_ES = 'Líneas para las cuales hay variantes múltiples en la aplicación se saltarán: %1'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersToString(TextNotFound, Statistics.Ambiguous);
			ElsIf Statistics.NotFound > 0 Then
				TextNotFound = NStr("ru = 'Строки, для которых в программе нет соответствующих данных, будут пропущены: %1'; en = '%1 lines with no matches in the application will be skipped.'; pl = 'Wiersze, dla których nie istnieją żadne dane pasujące w aplikacji, zostaną pominięte: %1';de = 'Zeichenfolgen, für die keine übereinstimmenden Daten in der Anwendung vorhanden sind, werden übersprungen: %1';ro = 'Rândurile, pentru care în program nu există date respective, vor fi omise: %1';tr = 'Uygulamada eşleşen veri bulunmayan dizeler atlanacaktır: %1'; es_ES = 'Líneas para las cuales no hay datos emparejados en la aplicación se saltarán: %1'");
				TextNotFound = StringFunctionsClientServer.SubstituteParametersToString(TextNotFound, Statistics.NotFound);
			EndIf;
			TextNotFound = TextNotFound + Chars.LF + NStr("ru = 'Для просмотра пропущенных строк и подбора данных для вставки нажмите ""Далее"".'; en = 'To view skipped lines and map their data manually, click ""Next"".'; pl = 'Aby wyświetlić pominięte linie i wybór danych do wstawienia, kliknij przycisk Dalej.';de = 'Klicken Sie auf Weiter, um die übersprungenen Zeilen und die Datenauswahl zum Einfügen anzuzeigen.';ro = 'Pentru vizualizarea rândurilor omise și selectarea datelor pentru inserare, tastați ""Înainte"".';tr = 'Atlanan satırları ve ekleme için veri seçimini görüntülemek için İleri''yi tıklatın.'; es_ES = 'Para ver las líneas saltadas y la selección de datos para insertar, hacer clic en Siguiente.'");
			Items.NotFoundAndConflictsDecoration.Title = TextNotFound;
			
			Items.WizardPages.CurrentPage = Items.MappingResults;
			Items.Back.Visible = True;
			Items.AddToList.Visible = True;
			Items.Next.Visible = True;
			Items.Back.Title = NStr("ru = '< Назад'; en = '< Back'; pl = '< Wstecz';de = '< Zurück';ro = '< Înapoi';tr = '< Geri'; es_ES = '< Atrás'");
			Items.Next.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'");
			Items.Next.DefaultItem = False;
			Items.AddToList.DefaultItem = True;
			Items.AddToList.DefaultButton = True;
			
			ShowMappingStatisticsImportFromFile();
			SetAppearanceForMappingPage(False, Items.RefSearchNote, False, NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'"));
		Else
			Items.WizardPages.CurrentPage = Items.NotFound;
			Items.Close.Title = NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'");
			Items.Back.Visible = True;
			Items.AddToList.Visible = False;
			Items.Next.Visible = False;
		EndIf;
		
	Else 
		Items.WizardPages.CurrentPage = Items.DataToImportMapping;
		ShowMappingStatisticsImportFromFile();
		
		If ImportType = "UniversalImport" Then
			SetAppearanceForMappingPage(True, Items.DataMappingNote, True, NStr("ru = 'Загрузить данные >'; en = 'Import data >'; pl = 'Importuj dane >';de = 'Daten importieren>';ro = 'Importă datele >';tr = 'Veri içe aktar >'; es_ES = 'Importar datos >'"));
		ElsIf ImportType = "TabularSection" Then
			If DataMappingTable.FindRows(New Structure("RowMappingResult", "NotMapped")).Count() = 0
				AND DataMappingTable.FindRows(New Structure("RowMappingResult", "Conflict")).Count() = 0 Then
				// All rows are mapped
				ProceedToNextStepOfDataImport();
			EndIf;
			
			SetAppearanceForMappingPage(False, Items.TabularSectionNote, True, NStr("ru = 'Загрузить данные'; en = 'Import data'; pl = 'Importuj dane';de = 'Daten importieren';ro = 'Importă datele';tr = 'Veri içe aktar'; es_ES = 'Importar datos'"));
			SetAppearanceForConflictFields(New Structure("RowMappingResult", "Conflict"));
		ElsIf ImportType = "ExternalImport" Then
			SetAppearanceForMappingPage(False, Items.AppliedImportNote, False, NStr("ru = 'Загрузить данные >'; en = 'Import data >'; pl = 'Importuj dane >';de = 'Daten importieren>';ro = 'Importă datele >';tr = 'Veri içe aktar >'; es_ES = 'Importar datos >'"));
		Else
			SetAppearanceForMappingPage(False, Items.AppliedImportNote, False, NStr("ru = 'Загрузить данные >'; en = 'Import data >'; pl = 'Importuj dane >';de = 'Daten importieren>';ro = 'Importă datele >';tr = 'Veri içe aktar >'; es_ES = 'Importar datos >'"));
		EndIf;
	EndIf;
	
	CommandBarButtonsAvailability(True);

EndProcedure

&AtClient
Procedure SetAppearanceForMappingPage(MappingButtonVisibility, ExplanatoryTextItem, ButtonVisibilityResolveConflict, NextButtonText)
	
	Items.MappingColumnsList.Visible = MappingButtonVisibility;
	Items.Back.Visible = True;
	Items.AppliedImportNote.Visible = False;
	Items.TabularSectionNote.Visible = False;
	Items.RefSearchNote.Visible = False;
	If ExplanatoryTextItem = Items.TabularSectionNote Then
		Items.TabularSectionNote.Visible = True;
	ElsIf ExplanatoryTextItem = Items.RefSearchNote Then
		Items.RefSearchNote.Visible = True;
		Items.DataMappingNote.ShowTitle = False;
	ElsIf ExplanatoryTextItem = Items.AppliedImportNote Then
		Items.AppliedImportNote.Visible = True;
	EndIf;
	
	Items.ResolveConflict.Visible = ButtonVisibilityResolveConflict;
	Items.Next.Title = NextButtonText;
	
EndProcedure

&AtClient
Procedure OpenResolveConflictForm(SelectedRow, NameField, StandardProcessing)
	Row = DataMappingTable.FindByID(SelectedRow);
	
	If ImportType = "TabularSection" Then
		If Row.RowMappingResult = "Conflict" AND StrLen(Row.ErrorDescription) > 0 Then
			If StrLen(NameField) > 3 AND StrStartsWith(NameField, "DataMappingTable_TabularSection_") Then
				Name = Mid(NameField, StrLen("DataMappingTable_TabularSection_") + 1);
				If StrFind(Row.ErrorDescription, Name) Then
					StandardProcessing = False;
					TableRow = New Array;
					ValuesOfColumnsToImport = New Structure();
					For each Column In ColumnsInformation Do
						ColumnsArray = New Array();
						ColumnsArray.Add(Column.ColumnName);
						ColumnsArray.Add(Column.ColumnPresentation);
						ColumnsArray.Add(Row["IND_" + Column.ColumnName]);
						ColumnsArray.Add(Column.ColumnType);
						TableRow.Add(ColumnsArray);
						If Name = Column.Parent Then
							ValuesOfColumnsToImport.Insert(Column.ColumnName, Row["IND_" + Column.ColumnName]);
						EndIf;
					EndDo;
					
					FormParameters = New Structure();
					FormParameters.Insert("ImportType", ImportType);
					FormParameters.Insert("Name", Name);
					FormParameters.Insert("TableRow", TableRow);
					FormParameters.Insert("ValuesOfColumnsToImport", ValuesOfColumnsToImport);
					FormParameters.Insert("ConflictsList", Undefined);
					FormParameters.Insert("FullTabularSectionName", MappingObjectName);
					FormParameters.Insert("AdditionalParameters", AdditionalParameters);
					
					Parameter = New Structure();
					Parameter.Insert("ID", SelectedRow);
					Parameter.Insert("Name", Name);
					
					Notification = New NotifyDescription("AfterMappingConflicts", ThisObject, Parameter);
					OpenForm("DataProcessor.ImportDataFromFile.Form.ResolveConflicts", FormParameters, ThisObject, True , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
				EndIf;
			EndIf;
		EndIf;
	Else
		If Row.RowMappingResult = "Conflict" Then
			StandardProcessing = False;
			
			TableRow = New Array;
			For each Column In ColumnsInformation Do 
				ColumnsArray = New Array();
				ColumnsArray.Add(Column.ColumnName);
				ColumnsArray.Add(Column.ColumnPresentation);
				ColumnsArray.Add(Row[Column.ColumnName]);
				ColumnsArray.Add(Column.ColumnType);
				TableRow.Add(ColumnsArray);
			EndDo;
			
			MappingColumns = New ValueList;
			For each Item In MapByColumn Do 
				If Item.Check Then
					MappingColumns.Add(Item.Value);
				EndIf;
			EndDo;
			
			FormParameters = New Structure();
			FormParameters.Insert("TableRow", TableRow);
			FormParameters.Insert("ConflictsList", Row.ConflictsList);
			FormParameters.Insert("MappingColumns", MappingColumns);
			FormParameters.Insert("ImportType", ImportType);
			
			Parameter = New Structure("ID", SelectedRow);
			
			Notification = New NotifyDescription("AfterMappingConflicts", ThisObject, Parameter);
			OpenForm("DataProcessor.ImportDataFromFile.Form.ResolveConflicts", FormParameters, ThisObject, True , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MapDataAppliedImport(DataMappingTableServer)
	
	ManagerObject = ObjectManager(MappingObjectName);
	
	ManagerObject.MapDataToImportFromFile(DataMappingTableServer);
	For each Row In DataMappingTableServer Do 
		If ValueIsFilled(Row.MappingObject) Then 
			Row.RowMappingResult = "RowMapped";
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ImportReportStep

&AtServer
Procedure SaveDataToImportReport()
	
	MappedData = FormAttributeToValue("DataMappingTable");
	
	If ImportType = "ExternalImport" Then
		WriteMappedDataExternalDataProcessor(MappedData);
		ValueToFormAttribute(MappedData, "DataMappingTable");
	Else
		WriteMappedDataAppliedImport(MappedData);
		ValueToFormAttribute(MappedData, "DataMappingTable");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataImportReportStepClient()
	
	Items.WizardPages.CurrentPage = Items.DataImportReport;
	Items.OpenCatalogAfterCloseWizard.Visible = True;
	Items.Close.Title = "Finish";
	Items.Next.Visible = False;
	Items.Back.Visible = False;
	
EndProcedure

#EndRegion

&AtServer
Procedure DefineDynamicTemplate(TableColumnsInformation, TemplateColumns)
	
	TableColumnsInformation = FormAttributeToValue("ColumnsInformation");
	TableColumnsInformation.Clear();
	Index = 1;
	For each Column In TemplateColumns Do
		If Column.Position <> Undefined Then
			Row = TableColumnsInformation.Add();
			Row.ColumnName = Column.Name;
			Row.Width = 20;
			If Column.Position = 0 Then
				Row.Position = Index;
				Index = Index + 1;
			Else
				Row.Position = Column.Position;
				Index = Column.Position + 1;
			EndIf;
			FillPropertyValues(Row, Column);
			Row.Visible = True;
			Row.ColumnPresentation = Column.Title;
			Row.ColumnType = Column.Type;
			If IsBlankString(Row.Group) Then
				Row.Group = Column.Title;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearTable()
	
	DataMappingTableServer = FormAttributeToValue("DataMappingTable");
	DataMappingTableServer.Columns.Clear();
	ColumnsInformation.Clear();
	
	While Items.DataMappingTable.ChildItems.Count() > 0 Do
		ThisObject.Items.Delete(Items.DataMappingTable.ChildItems.Get(0));
	EndDo;
	TemplateWithData = New SpreadsheetDocument;
	
	MappingTableAttributes = ThisObject.GetAttributes("DataMappingTable");
	AttributePathsArray = New Array;
	For each TableAttribute In MappingTableAttributes Do
		AttributePathsArray.Add("DataMappingTable." + TableAttribute.Name);
	EndDo;
	If AttributePathsArray.Count() > 0 Then
		ChangeAttributes(,AttributePathsArray);
	EndIf;
	
EndProcedure

&AtClient
Function SetAppearanceForConflictFields(Filter)
	
	Rows = DataMappingTable.FindRows(Filter);
	If Rows.Count() > 0 Then
		ColumnsList = New Array;
		For each DataString In Rows Do
			If StrCompare(DataString.RowMappingResult, "Conflict") = 0 Then
				ColumnsArray = StrSplit(DataString.ErrorDescription, ";", False);
				For each ColumnName In ColumnsArray Do
					ColumnsList.Add(ColumnName);
				EndDo;
			EndIf;
		EndDo;
	Else 
		Return False;
	EndIf;
	
	SetDataAppearance(ColumnsList);
	Return True;
EndFunction

&AtServer
Procedure SetDataAppearance(ColumnsList = Undefined)
	
	
	If ImportType = "PastingFromClipboard" Then 
		TextObjectNotFound = NStr("ru='<Не найден>'; en = '<Not found>'; pl = '<Nieokreślony>';de = '<Nicht angegeben>';ro = '<Nu a fost găsit>';tr = '<Bulunamadı>'; es_ES = '<No especificado>'");
		ColorObjectNotFound = StyleColors.InaccessibleCellTextColor;
		ColorConflict = StyleColors.ErrorNoteText;
	Else
		TextObjectNotFound = NStr("ru='<Новый>'; en = '<New>'; pl = '<Nowy>';de = '<Neu>';ro = '<Nou>';tr = '<Yeni>'; es_ES = '<Nuevo>'");
		ColorObjectNotFound = StyleColors.SuccessResultColor;
		ColorConflict = StyleColors.ErrorNoteText;
	EndIf;
	
	ConditionalAppearance.Items.Clear();
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("MappingObject");
	AppearanceField.Use = True;
	
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataMappingTable.MappingObject"); 
	FilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", ColorObjectNotFound);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", TextObjectNotFound);
	
	If ValueIsFilled(ColumnsList) Then
		For each ColumnName In ColumnsList Do
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
			AppearanceField.Field = New DataCompositionField("DataMappingTable_TabularSection_" + ColumnName);
			AppearanceField.Use = True;
			FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.LeftValue = New DataCompositionField("DataMappingTable.RowMappingResult");
			FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
			FilterItem.RightValue = "Conflict";
			FilterItem.Use = True;
			ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", ColorConflict);
			ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
			ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru='<неоднозначность>'; en = '<ambiguity>'; pl = '<dwuznaczność>';de = '<Mehrdeutigkeit>';ro = '<ambiguitate>';tr = '<belirsizlik>'; es_ES = '<ambigüedad>'"));
		EndDo;
	Else
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField("DataMappingTable_MappingObject");
		AppearanceField.Use = True;
		FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue = New DataCompositionField("DataMappingTable.RowMappingResult");
		FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		FilterItem.RightValue = "Conflict";
		FilterItem.Use = True;
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", ColorConflict);
		ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru='<неоднозначность>'; en = '<ambiguity>'; pl = '<dwuznaczność>';de = '<Mehrdeutigkeit>';ro = '<ambiguitate>';tr = '<belirsizlik>'; es_ES = '<ambigüedad>'"));
		
	EndIf;
	
EndProcedure

&AtServer
Function ColumnInformation(ColumnName)
	Filter = New Structure("ColumnName", ColumnName);
	Result = ColumnsInformation.FindRows(Filter);
	If Result.Count() > 0 Then
		Return Result[0];
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Function MetadataObjectInfoByType(FullObjectType)
	ObjectDetails = New Structure("ObjectType, ObjectName");
	FullName = Metadata.FindByType(FullObjectType).FullName();
	Result = StrSplit(FullName, ".", False);
	If Result.Count()>1 Then
		ObjectDetails.ObjectType = Result[0];
		ObjectDetails.ObjectName = Result[1];
		
		Return ObjectDetails;
	Else
		Return Undefined;
	EndIf;
	
EndFunction 

&AtServer
Function ConditionsBySelectedColumns(CatalogName)
	
	SeparatorAnd  = "";
	ComparisonTypeSSL  = " = ";
	withWhere          = "";
	StringCondition = "";
	TabularSection = "";
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ContactInformationKinds = ModuleContactsManager.ObjectContactInformationKinds(Catalogs[CatalogName].EmptyRef());
	EndIf;
	
	For each Item In MapByColumn Do
		If Item.Check Then
			Column = ColumnInformation(Item.Value);
			
			If Column <> Undefined Then
				// Creating a query depending on the data types.
				
				If StrStartsWith(Column.ColumnName, "ContactInformation_") Then
					
					CIKindName = StandardSubsystemsServer.TransformAdaptedColumnDescriptionToString(Mid(Column.ColumnName, StrLen("ContactInformation_") + 1));
					FoundKinds = ContactInformationKinds.Find(CIKindName, "Description");
					
					TabularSection = "ContactInformation";
					StringCondition = StringCondition + SeparatorAnd + "CAST(CatalogMapping.Presentation
						| AS String(500)) = CAST(MappingTable." + Column.ColumnName + " AS  String(500)) ";
					If FoundKinds <> Undefined Then
						StringCondition = StringCondition + " AND CatalogMapping.Kind.Description = """ + FoundKinds.Ref.Description + """";
					EndIf;
					withWhere = withWhere + " AND CatalogMapping.Presentation <> """"";
					SeparatorAnd = " AND ";
					Continue;
					
				ElsIf StrStartsWith(Column.ColumnName, "AdditionalAttribute_") Then
					CatalogColumnName = "Value";
					TabularSection = "AdditionalAttributes";
					StringCondition = StringCondition + SeparatorAnd + " CatalogMapping.Value =  MappingTable." + Column.ColumnName;
					
					ColumnType = Column.ColumnType.Types()[0];
					If TypeOf(ColumnType) = Type("String") AND Column.ColumnType.StringQualifiers.Length = 0 Then
						Continue; // It is not allowed to compare lines of unlimited length.
					EndIf;
					
					ColumnTypeObjects = Metadata.FindByType(ColumnType);
					If ColumnTypeObjects <> Undefined Then
						withWhere = withWhere + " AND CatalogMapping.Value <> VALUE(" +  ColumnTypeObjects.FullName() + ".EmptyRef)";
					EndIf;
					SeparatorAnd = " AND ";
					Continue;
				EndIf;
				
				CatalogColumnName = "Ref." + Column.ColumnName;
				
				ColumnType = Column.ColumnType.Types()[0];
				If ColumnType = Type("String") Then
					If Column.ColumnType.StringQualifiers.Length = 0 Then
						StringCondition = StringCondition + SeparatorAnd + "CAST(CatalogMapping." + CatalogColumnName 
							+ " AS String(500)) = CAST(MappingTable." + Column.ColumnName + " AS  String(500))";
						withWhere = withWhere + " AND CatalogMapping." + CatalogColumnName + " <> """"";
					Else
						StringCondition = StringCondition + SeparatorAnd + "CatalogMapping." + CatalogColumnName
							+  " = MappingTable." + Column.ColumnName;
						withWhere = withWhere + " AND CatalogMapping." + CatalogColumnName + " <> """"";
					EndIf;
				ElsIf ColumnType = Type("Number") Then
					StringCondition = StringCondition + SeparatorAnd + "CatalogMapping." + CatalogColumnName + " =  MappingTable." + Column.ColumnName;
				ElsIf ColumnType = Type("Date") Then 
					StringCondition = StringCondition + SeparatorAnd + "CatalogMapping." + CatalogColumnName + " =  MappingTable." + Column.ColumnName;
				ElsIf ColumnType = Type("Boolean") Then 
					StringCondition = StringCondition + SeparatorAnd + "CatalogMapping." + CatalogColumnName + " =  MappingTable." + Column.ColumnName;
				Else
					InfoObject = MetadataObjectInfoByType(ColumnType);
					If InfoObject.ObjectType = "Catalog" Then
						Catalog = Metadata.Catalogs.Find(InfoObject.ObjectName);
						ConditionTextCatalog = "";
						SeparatorOR = "";
						For each InputString In Catalog.InputByString Do 
							If InputString.Name = "Code" AND NOT Catalog.Autonumbering Then 
								InputByStringConditionText = "CatalogMapping." + CatalogColumnName + ".Code " + ComparisonTypeSSL + " MappingTable." + Column.ColumnName;
							Else
								InputByStringConditionText = "CatalogMapping." + CatalogColumnName + "." + InputString.Name  + ComparisonTypeSSL + " MappingTable." + Column.ColumnName;
							EndIf;
							ConditionTextCatalog = ConditionTextCatalog + SeparatorOR + InputByStringConditionText;
							SeparatorOR = " OR ";
						EndDo;
						StringCondition = StringCondition + SeparatorAnd + " ( "+ ConditionTextCatalog + " )";
					ElsIf InfoObject.ObjectType = "Enum" Then
						StringCondition = StringCondition + SeparatorAnd + "CatalogMapping." + CatalogColumnName + " =  MappingTable." + Column.ColumnName;	
					EndIf;
				EndIf;
				
			EndIf;
			
			SeparatorAnd = " AND ";
			
		EndIf;
	EndDo;
	
	Conditions = New Structure("JoinCondition , Where, TabularSection");
	Conditions.JoinCondition  = StringCondition;
	Conditions.Where = withWhere;
	Conditions.TabularSection = TabularSection;
	Return Conditions;
	
EndFunction

&AtServer
Procedure ExecuteMappingBySelectedAttribute(MappedItemsCount = 0, MappingColumnsList = "")
	
	ObjectStructure = DataProcessors.ImportDataFromFile.SplitFullObjectName(MappingObjectName);
	CatalogName   = ObjectStructure.ObjectName;
	Conditions          = ConditionsBySelectedColumns(CatalogName);
	
	If Not ValueIsFilled(Conditions.JoinCondition) Then
		Return;
	EndIf;
	
	If ValueIsFilled(Conditions.TabularSection) Then
		CatalogName = CatalogName + "." + Conditions.TabularSection;
	EndIf;
	
	MappingTable = FormAttributeToValue("DataMappingTable");
	
	ColumnsList = "";
	Separator   = "";
	
	For each Column In MappingTable.Columns Do
		If Column.Name <> "ConflictsList" AND Column.Name <> "RowMappingResult" AND Column.Name <> "ErrorDescription" Then
			ColumnsList = ColumnsList + Separator + Column.Name;
			Separator   = ", ";
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT " + ColumnsList + "
	|INTO MappingTable
	|FROM &MappingTable AS MappingTable
	|;
	|SELECT
	|	CatalogMapping.Ref, MappingTable.ID
	|FROM
	|	MappingTable AS MappingTable
	|		LEFT JOIN Catalog." + CatalogName + " AS CatalogMapping
	|		ON " + Conditions.JoinCondition + "
	|WHERE
	|	CatalogMapping.Ref.DeletionMark = FALSE " + Conditions.Where + "
	|	ORDER BY MappingTable.ID TOTALS BY MappingTable.ID";
	
	Query.SetParameter("MappingTable", MappingTable);
	
	QueryResult = Query.Execute();
	DetailedRecordsSelection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While DetailedRecordsSelection.Next() Do
		Row = MappingTable.Find(DetailedRecordsSelection.ID, "ID");
		
		If ValueIsFilled(Row.MappingObject) Then
			Continue;
		EndIf;
		
		DetailedRecordsSelectionGroup = DetailedRecordsSelection.Select();
		
		If DetailedRecordsSelectionGroup.Count() > 1 Then
			ConflictsList = New ValueList;
			While DetailedRecordsSelectionGroup.Next() Do
				ConflictsList.Add(DetailedRecordsSelectionGroup.Ref);
			EndDo;
			Row.RowMappingResult = "Conflict";
			Row.ErrorDescription = MappingColumnsList;
			Row.ConflictsList = ConflictsList;
		Else
			DetailedRecordsSelectionGroup.Next();
			MappedItemsCount = MappedItemsCount + 1;
			Row.RowMappingResult = "RowMapped";
			Row.ErrorDescription = "";
			Row.MappingObject = DetailedRecordsSelectionGroup.Ref;
		EndIf;
	EndDo;
	
	MappingColumnsList = "";
	Separator = "";
	For each Column In MapByColumn Do
		If Column.Check Then
			MappingColumnsList = MappingColumnsList + Separator + Column.Presentation;
			Separator = ", ";
		EndIf;
	EndDo;
	ImportDataFromFile.AddStatisticalInformation("ColumnMapping", MappedItemsCount, MappingColumnsList);
	
	ValueToFormAttribute(MappingTable, "DataMappingTable");
	
EndProcedure

&AtServer
Procedure PutDataInMappingTable(ImportedDataAddress, TabularSectionCopyAddress, ConflictsList)
	
	TabularSection =  GetFromTempStorage(TabularSectionCopyAddress);
	
	If TabularSection = Undefined OR TypeOf(TabularSection) <> Type("ValueTable") OR TabularSection.Count() = 0 Then
		Return;
	EndIf;
	
	Filter = New Structure("Required", True);
	FilteredColumnsRequiredForTableFilling = ColumnsInformation.FindRows(Filter);
	RequiredColumns = New Map;
	For each TableColumn In FilteredColumnsRequiredForTableFilling  Do
		RequiredColumns.Insert(TableColumn.Parent, True);
	EndDo;
	
	DataMappingTable.Clear();
	DataToImport = GetFromTempStorage(ImportedDataAddress);
	
	TabularSectionColumns = New Map();
	For each Column In TabularSection.Columns Do
		TabularSectionColumns.Insert(Column.Name, True);
	EndDo;
	
	For each Row In TabularSection Do
		NewRow = DataMappingTable.Add();
		NewRow.ID = Row.ID;
		AllRequiredColumnsFilled = True;
		For each Column In TabularSection.Columns Do
			If Column.Name <> "ID" Then
				NewRow["TabularSection_" + Column.Name] = Row[Column.Name];
			EndIf;
			
			If ValueIsFilled(RequiredColumns.Get(Column.Name))
				AND AllRequiredColumnsFilled
				AND NOT ValueIsFilled(Row[Column.Name]) Then
					AllRequiredColumnsFilled = False;
			EndIf;
		EndDo;
		
		NewRow["RowMappingResult"] = ?(AllRequiredColumnsFilled, "RowMapped", "NotMapped");
		
		Filter = New Structure("ID", Row.ID); 
		
		Conflicts = ConflictsList.FindRows(Filter);
		If Conflicts.Count() > 0 Then 
			NewRow["RowMappingResult"] = "Conflict";
			For each Conflict In Conflicts Do
				NewRow["ErrorDescription"] = NewRow["ErrorDescription"] + Conflict.Column+ ";";
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
				AppearanceField.Field = New DataCompositionField("TabularSection_" + Conflict.Column);
				AppearanceField.Use = True;
				FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterItem.LeftValue = New DataCompositionField("DataMappingTable.ErrorDescription"); 
				FilterItem.ComparisonType = DataCompositionComparisonType.Contains; 
				FilterItem.RightValue = Conflict.Column; 
				FilterItem.Use = True;
				ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
				ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
				ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru='<неоднозначность>'; en = '<ambiguity>'; pl = '<dwuznaczność>';de = '<Mehrdeutigkeit>';ro = '<ambiguitate>';tr = '<belirsizlik>'; es_ES = '<ambigüedad>'"));
			EndDo;
		EndIf;
	EndDo;
	
	For each Row In DataToImport Do
		Filter = New Structure("ID", Row.ID);
		Rows = DataMappingTable.FindRows(Filter);
		If Rows.Count() > 0 Then 
			NewRow = Rows[0];
			For each Column In DataToImport.Columns Do
				If Column.Name <> "ID" AND Column.Name <> "RowMappingResult" AND Column.Name <> "ErrorDescription" Then
					NewRow["IND_" + Column.Name] = Row[Column.Name];
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function MappingTableAddressInStorage()
	Table = FormAttributeToValue("DataMappingTable");
	
	TableForTS = New ValueTable;
	For Each Column In Table.Columns Do
		If StrStartsWith(Column.Name, "TabularSection_") Then
			TableForTS.Columns.Add(Mid(Column.Name, StrLen( "TabularSection_") + 1), Column.ValueType, Column.Title, Column.Width);
		ElsIf  Column.Name = "RowMappingResult" OR Column.Name = "ErrorDescription" OR Column.Name = "ID" Then
			TableForTS.Columns.Add(Column.Name, Column.ValueType, Column.Title, Column.Width);
		EndIf;
	EndDo;
	
	For Each Row In Table Do
		NewRow = TableForTS.Add();
		For Each Column In TableForTS.Columns Do
			If Column.Name = "ID" Then 
				NewRow[Column.Name] = Row[Column.Name];
			ElsIf Column.Name <> "RowMappingResult" AND Column.Name <> "ErrorDescription" Then
				NewRow[Column.Name] = Row["TabularSection_"+ Column.Name];
			EndIf;
		EndDo;
	EndDo;
	
	Return PutToTempStorage(TableForTS);
EndFunction

&AtServerNoContext
Function CatalogPresentation(FullMetadataObjectName)
	Return Metadata.FindByFullName(FullMetadataObjectName).Presentation();
EndFunction

&AtServerNoContext
Function ObjectManager(MappingObjectName)
		ObjectArray = DataProcessors.ImportDataFromFile.SplitFullObjectName(MappingObjectName);
		If ObjectArray.ObjectType = "Document" Then
			ObjectManager = Documents[ObjectArray.ObjectName];
		ElsIf ObjectArray.ObjectType = "Catalog" Then
			ObjectManager = Catalogs[ObjectArray.ObjectName];
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Объект ""%1"" не найден'; en = 'Object ""%1"" is not found.'; pl = 'Obiekt ""%1"" nie został znaleziony.';de = 'Objekt ""%1"" wird nicht gefunden';ro = 'Obiectul ""%1"" nu a fost găsit';tr = '""%1"" Nesnesi bulunamadı'; es_ES = 'Objeto ""%1"" no se ha encontrado'"), MappingObjectName);
		EndIf;
		
		Return ObjectManager;
EndFunction

&AtServerNoContext
Function ListForm(MappingObjectName)
	MetadataObject = Metadata.FindByFullName(MappingObjectName);
	If MetadataObject.DefaultListForm <> Undefined Then
		Return MetadataObject.DefaultListForm.FullName();
	Else
		Return MetadataObject.FullName() + ".ListForm";
	EndIf;
EndFunction

&AtServer
Function TypeDetailsByMetadata(FullMetadataObjectName)
	Result = DataProcessors.ImportDataFromFile.SplitFullObjectName(FullMetadataObjectName);
	If Result.ObjectType = "Catalog" Then 
		Return New TypeDescription("CatalogRef." +  Result.ObjectName);
	ElsIf Result.ObjectType = "Document" Then 
		Return New TypeDescription("DocumentRef." +  Result.ObjectName);
	EndIf;
	
	Return Undefined;
EndFunction

&AtServer
Function NotFilledRequiredColumns()
	ColumnsNameWithoutData = New Array;
	
	Filter = New Structure("Required", True);
	
	Header = TableTemplateHeaderArea(TemplateWithData);
	For ColumnNumber = 1 To Header.TableWidth Do 
		Cell = Header.GetArea(1, ColumnNumber, 1, ColumnNumber);
		ColumnName = TrimAll(Cell.CurrentArea.Text);
		
		ColumnInformation = Undefined;
		Filter = New Structure("ColumnPresentation", ColumnName);
		ColumnsFilter = ColumnsInformation.FindRows(Filter);
		
		If ColumnsFilter.Count() > 0 Then
			ColumnInformation = ColumnsFilter[0];
		Else
			Filter = New Structure("ColumnName", ColumnName);
			ColumnsFilter = ColumnsInformation.FindRows(Filter);
			
			If ColumnsFilter.Count() > 0 Then
				ColumnInformation = ColumnsFilter[0];
			EndIf;
		EndIf;
		If ColumnInformation <> Undefined Then
			If ColumnInformation.Required Then
				For RowNumber = 2 To TemplateWithData.TableHeight Do
					Cell = TemplateWithData.GetArea(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
					If NOT ValueIsFilled(Cell.CurrentArea.Text) Then
						ColumnsNameWithoutData.Add(ColumnInformation.ColumnPresentation);
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	Return ColumnsNameWithoutData;
EndFunction

#Region ExternalImport

&AtServer
Procedure MapDataExternalDataProcessor(DataMappingTableServer )
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ExternalObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(ExternalDataProcessorRef);
		ExternalObject.MapDataToImportFromFile(CommandID, DataMappingTableServer);
		
		For each Row In DataMappingTableServer Do
			If ValueIsFilled(Row.MappingObject) Then
				Row.RowMappingResult = "RowMapped";
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure WriteMappedDataExternalDataProcessor(MappedData) 
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ExternalObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(ExternalDataProcessorRef);
	EndIf;
	
	Cancel = False;
	ImportParameters = New Structure();
	ImportParameters.Insert("CreateNewItems", CreateIfUnmapped);
	ImportParameters.Insert("UpdateExistingItems", UpdateExistingItems);
	ExternalObject.LoadFromFile(CommandID, MappedData, ImportParameters, Cancel); 
	
EndProcedure

#EndRegion

#Region ImportFromFile

&AtServer
Procedure WriteMappedDataAppliedImport(MappedData)
	
	ObjectManager = ObjectManager(MappingObjectName);
	
	Cancel = False;
	ImportParameters = New Structure();
	ImportParameters.Insert("CreateNewItems", CreateIfUnmapped);
	ImportParameters.Insert("UpdateExistingItems", UpdateExistingItems);
	ObjectManager.LoadFromFile(MappedData, ImportParameters, Cancel)
	
EndProcedure

#EndRegion

#Region ImportToTabularSection

&AtServer
Procedure CopyTabularSectionStructure(TabularSectionAddress)
	
	DataForTabularSection = New ValueTable;
	DataForTabularSection.Columns.Add("ID", New TypeDescription("Number"), "ID");
	
	If ValueIsFilled(MappingObjectName) Then
		TabularSection = Metadata.FindByFullName(MappingObjectName);
	
		For each TabularSectionAttribute In TabularSection.Attributes Do
			DataForTabularSection.Columns.Add(TabularSectionAttribute.Name, TabularSectionAttribute.Type, TabularSectionAttribute.Presentation());	
		EndDo;
	Else
		For each Column In ColumnsInformation Do
			DataForTabularSection.Columns.Add(Column.ColumnName, Column.ColumnType, Column.ColumnPresentation);
		EndDo;
	EndIf;
	
	
	TabularSectionAddress = PutToTempStorage(DataForTabularSection);
	
EndProcedure

#EndRegion

&AtServer
Function TableTemplateHeaderArea(Template)
	MetadataTableHeaderArea = Template.Areas.Find("Header");
	
	If MetadataTableHeaderArea = Undefined Then 
		TableHeaderArea = Template.GetArea("R1");
	Else 
		TableHeaderArea = Template.GetArea("Header"); 
	EndIf;
	
	Return TableHeaderArea;
	
EndFunction

&AtServer
Procedure ShowInfoBarAboutRequiredColumns()
	
	If Items.FillWithDataPages.CurrentPage = Items.ImportFromFileOptionPage Then
		TooltipText = NStr("ru = 'Для загрузки данных необходимо, сохранить бланк в файл для заполнения в другой программе. 
		|Затем загрузить заполненную таблицу в одном из форматов:
		|• Книги Microsoft Excel 97 (.xls) и Excel 2007 (.xlsx)
		|• Электронные таблицы LibreOffice Calc (.ods)
		|• Текст с разделителями (.csv)
		|• Табличный документ (.mxl)'; 
		|en = 'To import data, save the template to a file and populate it in a third-party application. 
		|Then import the populated table in one of the following formats: 
		|• Microsoft Excel 97 Workbook (.xls) or Microsoft Excel 2007 Workbook (.xlsx)
		|• LibreOffice Calc Spreadsheet (.ods)
		|• Comma-separated text (.csv)
		|• Spreadsheet document (.mxl)'; 
		|pl = 'Dla pobierania danych należy zapisać formularz do pliku dla wypełnienia w innym programie.
		|Następnie przesłać wypełnioną tabelę w jednym z formatów:
		|• Księgi Microsoft Excel 97 (.xls) i Excel 2007 (.xlsx)
		|•tablice elektroniczne LibreOffice Calc (.ods)
		|• Tekst rozdzielany (.csv)
		|• Tabelaryczny dokument (.mxl)';
		|de = 'Um die Daten herunterzuladen, müssen Sie das Formular in einer Datei speichern, die in einem anderen Programm ausgefüllt werden kann. 
		|Laden Sie dann die fertige Tabelle in eines der Formate:
		|• Bücher Microsoft Excel 97 (.xls) und Excel 2007 (.xlsx)
		|• Tabellenkalkulationen LibreOffice Сalс (.ods)
		|• Text mit Trennzeichen (.csv) 
		|• Tabellen-Dokument (.mxl)';
		|ro = 'Pentru importul de date trebuie să salvați formularul în fișier pentru completare în alt program. 
		|Apoi încărcați tabelul completat în unul din formatele:
		|• Registre Microsoft Excel 97 (.xls) și Excel 2007 (.xlsx)
		|• Tabele electronice LibreOffice Calc (.ods)
		|• Text cu separatori (.csv)
		|• Document tabelar (.mxl)';
		|tr = 'Verileri yüklemek için, başka bir programda doldurmak için bir dosyaya formu kaydetmek gerekir.
		|Sonra aşağıdaki biçimlerden birinde doldurulmuş tabloyu içe aktarın: 
		|• Microsoft Excel 97 (.xls) ve Excel 2007 (.xlsx) dosyaları 
		|• Elektronik tablolar LibreOffice Сalс (.ods) 
		|• Virgüllerle ayrılmış değer dosyası (.csv) 
		|• Tablo dosyası (.mxl)'; 
		|es_ES = 'Para cargar los datos es necesario guardar el impreso en el archivo para rellenarlo en otro programa. 
		|Después subir la tabla rellenada en uno de los formatos:
		|• Libros Microsoft Excel 97 (.xls) y Excel 2007 (.xlsx)
		|• Tablas electrónicas LibreOffice Сalс (.ods)
		|• Texto con separadores (.csv) 
		|• Documento de tabla (.mxl)'") + Chars.LF;
	Else
		TooltipText = NStr("ru = 'Для заполнения таблицы необходимо скопировать данные в таблицу из внешнего файла через буфер обмена.'; en = 'To fill in the table, copy data from an external file through the clipboard.'; pl = 'Aby wypełnić tabelę, skopiuj dane do tabeli z zewnętrznego pliku używając schowka.';de = 'Um die Tabelle auszufüllen, kopieren Sie Daten aus der externen Datei über die Zwischenablage in die Tabelle.';ro = 'Pentru completarea tabelului trebuie să copiați datele în tabel din fișierul extern prin clipboard.';tr = 'Tabloyu doldurmak için verileri pano aracılığı ile harici dosyadan tabloya kopyalayın.'; es_ES = 'Para rellenar la tabla, copiar datos a la tabla del archivo externo mediante un portapapeles.'") + Chars.LF;
	EndIf;
	
	Filter = New Structure("Required", True);
	RequiredColumns= ColumnsInformation.FindRows(Filter);
	
	If RequiredColumns.Count() > 0 Then 
		ColumnsList = "";
		
		For each Column In RequiredColumns Do 
			If ValueIsFilled(Column.Synonym) Then
				ColumnsList = ColumnsList + ", """ + Column.Synonym + """";
			Else
				ColumnsList = ColumnsList + ", """ + Column.ColumnPresentation + """";
			EndIf;
		EndDo;
		ColumnsList = Mid(ColumnsList, 3);
		
		If RequiredColumns.Count() = 1 Then
			TooltipText = TooltipText + NStr("ru = 'Колонка, обязательная для заполнения:'; en = 'Required column:'; pl = 'Kolumna, obowiązkowa do wypełnienia:';de = 'Eine Spalte, die ausgefüllt werden muss:';ro = 'Coloana obligatorie pentru completare:';tr = 'Doldurulması zorunlu sütun:'; es_ES = 'Columna requerida:'") + " " + ColumnsList;
		Else
			TooltipText = TooltipText + NStr("ru = 'Колонки, обязательные для заполнения:'; en = 'Required columns:'; pl = 'Kolumny, obowiązkowe do wypełnienia:';de = 'Spalten, die ausgefüllt werden müssen:';ro = 'Coloanele obligatorii pentru completare:';tr = 'Doldurulması zorunlu sütunlar:'; es_ES = 'Columnas requeridas:'") + " " + ColumnsList;
		EndIf;
		
	EndIf;
	
	Items.FillingHintLabel.Title = TooltipText;
	Items.ImportFromFileOptionNote.Title = TooltipText;
	
EndProcedure

&AtServer
Procedure DefineImportParameters(ImportFromFileParameters)
	
	ObjectMetadata = Metadata.FindByFullName(MappingObjectName);
	ImportFromFileParameters = DataProcessors.ImportDataFromFile.ImportFromFileParameters(ObjectMetadata);
	ObjectManager(MappingObjectName).GetDataImportFromFileParameters(ImportFromFileParameters);
	
EndProcedure

&AtServer
Procedure AddStandardColumnsToMappingTable(TemporarySpecification, MappingObjectStructure, AddID,
		AddErrorDescription, AddRowMappingResult, AddConflictsList)
		
	If AddID Then 
		TemporarySpecification.Columns.Add("ID", New TypeDescription("Number"), NStr("ru = 'п/п'; en = '#'; pl = 'element';de = 'artikel';ro = 'articol';tr = 'öğe'; es_ES = 'artículo'"));
	EndIf;
	If ValueIsFilled(MappingObjectStructure) Then 
		If Not ValueIsFilled(MappingObjectStructure.Synonym) Then
			ColumnHeader = "";
			If MappingObjectStructure.MappingObjectTypeDetails.Types().Count() > 1 Then 
				ColumnHeader = "Objects";
			Else
				ColumnHeader = String(MappingObjectStructure.MappingObjectTypeDetails.Types()[0]);
			EndIf;
			
		Else
			ColumnHeader = MappingObjectStructure.Synonym;
		EndIf;
		TemporarySpecification.Columns.Add("MappingObject", MappingObjectStructure.MappingObjectTypeDetails, ColumnHeader);
	EndIf;
	If AddRowMappingResult Then 
		TemporarySpecification.Columns.Add("RowMappingResult", New TypeDescription("String"), NStr("ru = 'Результат'; en = 'Result'; pl = 'Wynik';de = 'Ergebnis';ro = 'Rezultat';tr = 'Sonuç'; es_ES = 'Resultado'"));
	EndIf;
	If AddErrorDescription Then
		TemporarySpecification.Columns.Add("ErrorDescription", New TypeDescription("String"), NStr("ru = 'Причина'; en = 'Reason'; pl = 'Powód';de = 'Grund';ro = 'Motiv';tr = 'Sebep'; es_ES = 'Razón'"));
	EndIf;

	If AddConflictsList Then 
		VLType = New TypeDescription("ValueList");
		TemporarySpecification.Columns.Add("ConflictsList", VLType, "ConflictsList");
	EndIf;
EndProcedure

&AtServer
Procedure AddStandardColumnsToAttributesArray(AttributesArray, MappingObjectStructure , AddID, 
		AddErrorDescription, AddRowMappingResult, AddConflictsList)
		
		StringType = New TypeDescription("String");
		If AddID Then 
			NumberType = New TypeDescription("Number");
			AttributesArray.Add(New FormAttribute("ID", NumberType, "DataMappingTable", "ID"));
		EndIf;
		If ValueIsFilled(MappingObjectStructure) Then 
			AttributesArray.Add(New FormAttribute("MappingObject", MappingObjectStructure.MappingObjectTypeDetails, "DataMappingTable", MappingObjectName));
		EndIf;
		
		If AddRowMappingResult Then
			AttributesArray.Add(New FormAttribute("RowMappingResult", StringType, "DataMappingTable", "Result"));
		EndIf;
		If AddErrorDescription Then 
			AttributesArray.Add(New FormAttribute("ErrorDescription", StringType, "DataMappingTable", "Reason"));
		EndIf;

	If AddConflictsList Then 
		VLType = New TypeDescription("ValueList");
		AttributesArray.Add(New FormAttribute("ConflictsList", VLType, "DataMappingTable", "ConflictsList"));
	EndIf;

EndProcedure

&AtServer
Procedure CreateMappingTableByColumnsInformationAuto(MappingObjectTypeDetails)
	
	AttributesArray = New Array;
	
	TemporarySpecification = FormAttributeToValue("DataMappingTable");
	TemporarySpecification.Columns.Clear();
	
	MappingObjectStructure = New Structure("MappingObjectTypeDetails, Synonym", MappingObjectTypeDetails, "");
	AddStandardColumnsToMappingTable(TemporarySpecification, MappingObjectStructure, True, False, True, True);
	AddStandardColumnsToAttributesArray(AttributesArray, MappingObjectStructure, True, False, True, True);
	
	For each Column In ColumnsInformation Do
		TemporarySpecification.Columns.Add(Column.ColumnName, Column.ColumnType, Column.ColumnPresentation);
		AttributesArray.Add(New FormAttribute(Column.ColumnName, Column.ColumnType, "DataMappingTable", Column.ColumnPresentation));
	EndDo;
	
	ChangeAttributes(AttributesArray);
	
	ValueToFormAttribute(TemporarySpecification, "DataMappingTable");
	
	For Each Column In TemporarySpecification.Columns Do
		NewItem = Items.Add("DataMappingTable_" + Column.Name, Type("FormField"), Items.DataMappingTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMappingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ReadOnly = True;
		If NewItem.Type <> FormFieldType.LabelField Then
			Required = ThisColumnRequired(Column.Name);
			NewItem.AutoMarkIncomplete  = Required;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
			
		EndIf;
		If Column.Name = "MappingObject" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.BackColor = StyleColors.MasterFieldBackground;
			NewItem.HeaderPicture = PictureLib.Change;
			NewItem.ReadOnly = False;
			
			NewItem.EditMode = ColumnEditMode.Directly;
			NewItem.CreateButton = False;
			NewItem.OpenButton = True;
			NewItem.ChoiceButton = True;
			NewItem.TextEdit = True;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		ElsIf Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 4;
		ElsIf Column.Name = "RowMappingResult" OR Column.Name = "ConflictsList" Then
			NewItem.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateMappingTableByColumnsInformation()
	
	AttributesArray = New Array;
	
	MetadataObject = Metadata.FindByFullName(MappingObjectName);
	MappingObjectTypeDetails = TypeDetailsByMetadata(MappingObjectName);
	
	TemporarySpecification = FormAttributeToValue("DataMappingTable");
	TemporarySpecification.Columns.Clear();
	
	Synonym = MetadataObject.Synonym;
	MappingObjectStructure = New Structure("MappingObjectTypeDetails, Synonym", MappingObjectTypeDetails, Synonym);
	AddStandardColumnsToMappingTable(TemporarySpecification, MappingObjectStructure, True, True, True, True);
	AddStandardColumnsToAttributesArray(AttributesArray, MappingObjectStructure, True, True, True, True);
	
	For each Column In ColumnsInformation Do 
		If TemporarySpecification.Columns.Find(Column.ColumnName) = Undefined Then
			ColumnPresentation = Column.ColumnPresentation;
			TemporarySpecification.Columns.Add(Column.ColumnName, Column.ColumnType, ColumnPresentation);
			AttributesArray.Add(New FormAttribute(Column.ColumnName, Column.ColumnType, "DataMappingTable", ColumnPresentation));
		EndIf;
	EndDo;
	
	ChangeAttributes(AttributesArray);
	
	For Each Column In TemporarySpecification.Columns Do
		NewItem = Items.Add("DataMappingTable_" + Column.Name, Type("FormField"), Items.DataMappingTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMappingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ReadOnly = True;
		If NewItem.Type <> FormFieldType.LabelField Then 
			Required = ThisColumnRequired(Column.Name);
			NewItem.AutoMarkIncomplete  = Required;
			NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		EndIf;
		If Column.Name = "MappingObject" Then 
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.BackColor = StyleColors.MasterFieldBackground;
			NewItem.HeaderPicture = PictureLib.Change;
			NewItem.ReadOnly = False;
			NewItem.EditMode =  ColumnEditMode.Directly;
			NewItem.IncompleteChoiceMode = IncompleteChoiceMode.OnActivate;
		ElsIf Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 4;
		ElsIf Column.Name = "RowMappingResult" OR Column.Name = "ErrorDescription" OR Column.Name = "ConflictsList" Then
			NewItem.Visible = False;
		EndIf;
		
		Filter = New Structure("ColumnName", Column.Name);
		Columns = ColumnsInformation.FindRows(Filter);
		If Columns.Count() > 0 Then 
			NewItem.Visible = Columns[0].Visible;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(TemporarySpecification, "DataMappingTable");
EndProcedure

&AtServer
Procedure CreateMappingTableByColumnsInformationForTS() 
	
	AttributesArray = New Array;
	StringType = New TypeDescription("String");
	
	TemporarySpecification = FormAttributeToValue("DataMappingTable"); 
	TemporarySpecification.Columns.Clear();
	
	AddStandardColumnsToMappingTable(TemporarySpecification, Undefined, True, True, True, False);
	AddStandardColumnsToAttributesArray(AttributesArray, Undefined, True, True, True, False);

	RequiredColumns = New Array;
	ColumnsContainingChoiceParametersLinks = New Map;
	TSAttributes = Metadata.FindByFullName(MappingObjectName).Attributes;
	For each Column In TSAttributes Do
		
		If Column.FillChecking = FillChecking.ShowError Then
			RequiredColumns.Add("TabularSection_" + Column.Name);
		EndIf;
		If Column.ChoiceParameterLinks.Count() > 0 Then
			ColumnsContainingChoiceParametersLinks.Insert(Column.Name, Column.ChoiceParameterLinks);
		EndIf;
		TemporarySpecification.Columns.Add("TabularSection_" + Column.Name, Column.Type, Column.Presentation());
		AttributesArray.Add(New FormAttribute("TabularSection_" + Column.Name, Column.Type, "DataMappingTable", Column.Presentation()));
	EndDo;
	
	For each Column In ColumnsInformation Do
		TemporarySpecification.Columns.Add("IND_" + Column.ColumnName, StringType, Column.ColumnPresentation);
		AttributesArray.Add(New FormAttribute("IND_" + Column.ColumnName, StringType, "DataMappingTable", Column.ColumnPresentation));
	EndDo;
	
	ChangeAttributes(AttributesArray);
	AttributesCreated = True;
	
	DataToImportColumnsGroup = Items.Add("DataToImport", Type("FormGroup"), Items.DataMappingTable);
	DataToImportColumnsGroup.Group = ColumnsGroup.Horizontal;
	
	For Each Column In TemporarySpecification.Columns Do
		
		If StrStartsWith(Column.Name, "TabularSection_") Then
			TSDataToImportColumnsGroup = Items.Add("DataToImport_" + Column.Name , Type("FormGroup"), DataToImportColumnsGroup);
			TSDataToImportColumnsGroup.Group = ColumnsGroup.Vertical;
			Parent = TSDataToImportColumnsGroup;
		ElsIf StrStartsWith(Column.Name, "IND_") Then
			Continue;
		Else
			Parent = DataToImportColumnsGroup;
		EndIf;
		
		NewItem = Items.Add("DataMappingTable_" + Column.Name, Type("FormField"), Parent);
		
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "DataMappingTable." + Column.Name;
		NewItem.Title = Column.Title;
		NewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		
		If StrLen(Column.Name) > 3 AND StrStartsWith(Column.Name, "TabularSection_") Then
			Filter = New Structure("ColumnName", Mid(Column.Name, 4));
			Columns = ColumnsInformation.FindRows(Filter);
			If Columns.Count() > 0 Then 
				NewItem.Visible = Columns[0].Visible;
			EndIf;
		EndIf;
		
		If Column.Name = "ID" Then
			NewItem.FixingInTable = FixingInTable.Left;
			NewItem.ReadOnly = True;
			NewItem.Width = 1;
		ElsIf Column.Name = "RowMappingResult" OR Column.Name = "ErrorDescription" Then
			NewItem.Visible = False;
		EndIf;
		
		If RequiredColumns.Find(Column.Name) <> Undefined Then 
			NewItem.AutoMarkIncomplete = True;
		EndIf;
		
		If StrStartsWith(Column.Name, "TabularSection_") Then
			ColumnType = Metadata.FindByType(Column.ValueType.Types()[0]);
			If ColumnType <> Undefined AND StrFind(ColumnType.FullName(), "Catalog") > 0 Then
				NewItem.HeaderPicture = PictureLib.Change;
			EndIf;
			
			ColumnChoiceParametersLink = ColumnsContainingChoiceParametersLinks.Get(Mid(Column.Name, 4));
			If ColumnChoiceParametersLink <> Undefined Then 
				NewArray = New Array();
				For each ChoiceParameterLink In ColumnChoiceParametersLink Do
					Position = StrFind(ChoiceParameterLink.DataPath, ".", SearchDirection.FromEnd);
					If Position > 0 Then
						ItemName = Mid(ChoiceParameterLink.DataPath, Position + 1);
						NewLink = New ChoiceParameterLink(ChoiceParameterLink.Name, "Items.DataMappingTable.CurrentData.TabularSection_" + ItemName, ChoiceParameterLink.ValueChange);
						NewArray.Add(NewLink);
					EndIf;
				EndDo;
				NewLinks = New FixedArray(NewArray);
				NewItem.ChoiceParameterLinks = NewLinks;
			EndIf;
			
			Filter = New Structure("Parent", Mid(Column.Name, 4));
			GroupColumns = ColumnsInformation.FindRows(Filter);
			
			If GroupColumns.Count() = 1 Then
				
				ColumnLevel2 = TemporarySpecification.Columns.Find("IND_" + GroupColumns[0].ColumnName);
				If ColumnLevel2 <> Undefined Then 
					NewItem = Items.Add(ColumnLevel2.Name, Type("FormField"), Parent);
					NewItem.Type = FormFieldType.InputField;
					NewItem.DataPath = "DataMappingTable." + ColumnLevel2.Name;
					ColumnType = Metadata.FindByType(ColumnLevel2.ValueType.Types()[0]);
					If ColumnType <> Undefined AND StrFind(ColumnType.FullName(), "Catalog") > 0 Then
						NewItem.Title = NStr("ru = 'Данные из файла'; en = 'Data from file'; pl = 'Dane z pliku';de = 'Daten aus der Datei';ro = 'Datele din fișier';tr = 'Dosyadan veriler'; es_ES = 'Datos desde el archivo'");
					Else
						NewItem.Title = " ";
					EndIf;
					NewItem.ReadOnly = True;
					NewItem.TextColor = StyleColors.NoteText;
				EndIf;
				
			ElsIf GroupColumns.Count() > 1 Then
				TSDataToImportColumnsGroup = Items.Add("DataToImport_Individual_" + Column.Name , Type("FormGroup"), Parent);
				TSDataToImportColumnsGroup.Group = ColumnsGroup.InCell;
				Parent = TSDataToImportColumnsGroup;
				
				Prefix = NStr("ru = 'Данные из файла:'; en = 'Data from file:'; pl = 'Dane z pliku:';de = 'Daten aus der Datei:';ro = 'Datele din fișier:';tr = 'Dosya verileri:'; es_ES = 'Datos desde el archivo:'");
				For each GroupColumn In GroupColumns Do
					Column2 = TemporarySpecification.Columns.Find("IND_" + GroupColumn.ColumnName);
					If Column2 <> Undefined Then 
						NewItem = Items.Add(Column2.Name, Type("FormField"), Parent); 
						NewItem.Type = FormFieldType.InputField;
						NewItem.DataPath = "DataMappingTable." + Column2.Name;
						NewItem.Title = Prefix + Column2.Title;
						NewItem.ReadOnly = True;
						NewItem.TextColor = StyleColors.NoteText;
						
						If StrLen(Column.Name) > 3 AND StrStartsWith(Column.Name, "IND_") Then
						Filter = New Structure("ColumnName", Mid(Column.Name, 4));
						Columns = ColumnsInformation.FindRows(Filter);
							If Columns.Count() > 0 Then 
								NewItem.Visible = Columns[0].Visible;
							EndIf;
						EndIf;
						
					EndIf;
					Prefix = "";
				EndDo;
			Else
				NewItem.Visible = False;
			EndIf;
		EndIf;
	EndDo;
	
	ValueToFormAttribute(TemporarySpecification, "DataMappingTable");
EndProcedure

&AtServer
Function ThisColumnRequired(ColumnName)
	Filter = New Structure("ColumnName", ColumnName);
	Column =  ColumnsInformation.FindRows(Filter);
	If Column.Count()>0 Then 
		Return Column[0].Required;
	EndIf;
	
	Return False;
EndFunction

&AtServer
Procedure ClearTemplateWithData()
	RowNumberWithTableHeader = ?(ImportDataFromFileClientServer.ColumnsHaveGroup(ColumnsInformation), 2, 1);
	
	HeaderArea = TemplateWithData.GetArea(1, 1, RowNumberWithTableHeader, TemplateWithData.TableWidth);
	TemplateWithData.Clear();
	TemplateWithData.Put(HeaderArea);
EndProcedure

&AtServer
Function BatchAttributesModificationAtServer(UpperPosition, LowerPosition)
	RefsArray = New Array;
	For Position = UpperPosition To LowerPosition Do 
		Cell = ReportTable.GetArea(Position, 2, Position, 2);	
		If ValueIsFilled(Cell.CurrentArea.Details) Then 
			RefsArray.Add(Cell.CurrentArea.Details);
		EndIf;
	EndDo;
	Return RefsArray;
EndFunction

////////////////////// File operations //////////////////////

&AtClient
Procedure AfterFileChoiceForSaving(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		PathToFile = Result[0];
		SelectedFile = CommonClientServer.ParseFullFileName(PathToFile);
		FileExtention = CommonClientServer.ExtensionWithoutPoint(SelectedFile.Extension);
	
		If ValueIsFilled(SelectedFile.Name) Then
			If FileExtention = "csv" Then
				SaveTableToCSVFile(PathToFile);
			Else
				If FileExtention = "xlsx" Then
					FileType = SpreadsheetDocumentFileType.XLSX;
				ElsIf FileExtention = "mxl" Then
					FileType = SpreadsheetDocumentFileType.MXL;
				ElsIf FileExtention = "xls" Then
					FileType = SpreadsheetDocumentFileType.XLS;
				ElsIf FileExtention = "ods" Then
					FileType = SpreadsheetDocumentFileType.ODS;
				Else
					ShowMessageBox(, NStr("ru = 'Шаблон файла не был сохранен.'; en = 'The file template is not saved.'; pl = 'Szablon pliku nie został zapisany.';de = 'Dateivorlage wurde nicht gespeichert.';ro = 'Șablonul de fișier nu a fost salvat.';tr = 'Dosya şablonu kaydedilmedi.'; es_ES = 'Modelo del archivo no se ha guardado.'"));
					Return;
				EndIf;
				Notification = New NotifyDescription("AfterSaveSpreadsheetDocumentToFile", ThisObject);
				TemplateWithData.BeginWriting(Notification, PathToFile, FileType);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AfterSaveSpreadsheetDocumentToFile(Result, AdditionalParameters) Export
	If Result = False Then
		ShowMessageBox(, NStr("ru = 'Шаблон файла не был сохранен.'; en = 'The file template is not saved.'; pl = 'Szablon pliku nie został zapisany.';de = 'Dateivorlage wurde nicht gespeichert.';ro = 'Șablonul de fișier nu a fost salvat.';tr = 'Dosya şablonu kaydedilmedi.'; es_ES = 'Modelo del archivo no se ha guardado.'"));
	EndIf;
EndProcedure

&AtClient
Procedure ImportDataFromFileToTemplate(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		CommandBarButtonsAvailability(False);
		Items.WizardPages.CurrentPage = Items.TimeConsumingOperations;
		FileName                 = Result.Name;
		TempStorageAddress = Result.Location;
		Extension = CommonClientServer.ExtensionWithoutPoint(CommonClientServer.GetFileNameExtension(FileName));
	
		BackgroundJob = ImportFileWithDataToSpreadsheetDocumentAtServer(TempStorageAddress, Extension);
		WaitSettings                                = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		WaitSettings.OutputIdleWindow           = False;
		WaitSettings.ExecutionProgressNotification = New NotifyDescription("ExecutionProgress", ThisObject);
		Handler = New NotifyDescription("AfterImportDataFileToSpreadsheetDocument", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(BackgroundJob, Handler, WaitSettings);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterFileExtensionChoice(Result, Parameter) Export
	If ValueIsFilled(Result) Then
		AddressInTempStorage = ThisObject.UUID;
		SaveTemplateToTempStorage(Result, AddressInTempStorage);
		GetFile(AddressInTempStorage, MappingObjectName + "." + Result, True);
	EndIf;
EndProcedure

&AtServer
Procedure SaveTemplateToTempStorage(FileExtention, AddressInTempStorage)
	
	FileName = GetTempFileName(FileExtention);
	If FileExtention = "csv" Then 
		SaveTableToCSVFile(FileName);
	ElsIf FileExtention = "xlsx" Then
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.XLSX);
	ElsIf FileExtention = "xls" Then
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.XLS);
	ElsIf FileExtention = "ods" Then
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.ODS);
	Else 
		TemplateWithData.Write(FileName, SpreadsheetDocumentFileType.MXL);
	EndIf;
	BinaryData = New BinaryData(FileName);
	
	AddressInTempStorage = PutToTempStorage(BinaryData, AddressInTempStorage);
	
	FileSystem.DeleteTempFile(FileName);
	
EndProcedure

&AtServerNoContext
Function GenerateFileNameForMetadataObject(MetadataObjectName)
	CatalogMetadata = Metadata.FindByFullName(MetadataObjectName);
	
	If CatalogMetadata <> Undefined Then 
		FileName = TrimAll(CatalogMetadata.Synonym);
		If StrLen(FileName) = 0 Then 
			FileName = MetadataObjectName;	
		EndIf;
	Else
		FileName = MetadataObjectName;
	EndIf;
	
	FileName = StrReplace(FileName,":","");
	FileName = StrReplace(FileName,"*","");
	FileName = StrReplace(FileName,"\","");
	FileName = StrReplace(FileName,"/","");
	FileName = StrReplace(FileName,"&","");
	FileName = StrReplace(FileName,"<","");
	FileName = StrReplace(FileName,">","");
	FileName = StrReplace(FileName,"|","");
	FileName = StrReplace(FileName,"""","");
	
	Return FileName;
EndFunction 

&AtClient
Procedure AfterCancelMappingPrompt(Result, Parameter) Export
	
	If Result = DialogReturnCode.Yes Then
		For each TableRow In DataMappingTable Do
			TableRow.MappingObject = Undefined;
			TableRow.RowMappingResult = "NotMapped";
			TableRow.ConflictsList = Undefined;
			TableRow.ErrorDescription = "";
		EndDo;
		ShowMappingStatisticsImportFromFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCallFormChangeTemplate(Result, Parameter) Export
	
	If Result <> Undefined Then
		If Result.Count() > 0 Then
			For Each TableRow In Result Do
				FilterParameters = New Structure("ColumnName", TableRow.ColumnName);
				FoundRows = ColumnsInformation.FindRows(FilterParameters);
				If FoundRows.Count() > 0 Then
					FillPropertyValues(FoundRows[0], TableRow);
				EndIf;
				SaveSettings = True;
			EndDo;
		Else
			ColumnsInformation.Clear();
			GenerateTemplateByImportType();
			SaveSettings = False;
		EndIf;
		ColumnsInformation.Sort("Position Asc");
		UpdateMappingTableColumnsDescriptions();
		ChangeTemplateByColumnsInformation(, SaveSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateMappingTableColumnsDescriptions()
	
	For each TableRow In ColumnsInformation Do 
		Column = Items.DataMappingTable.ChildItems.Find(TableRow.ColumnName);
		If Column <> Undefined Then
			Column.Title = ?(NOT IsBlankString(TableRow.Synonym), 
				TableRow.Synonym + " (" + TableRow.ColumnPresentation +")", 
				TableRow.ColumnPresentation);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure ChangeTemplateByColumnsInformation(Template = Undefined, SaveSettings = False)

	If Template = Undefined Then 
		Template = TemplateWithData;
	EndIf;
	
	ColumnsTable = FormAttributeToValue("ColumnsInformation");
	If SaveSettings Then
		Common.CommonSettingsStorageSave("ImportDataFromFile", MappingObjectName, ColumnsTable,, UserName());
	EndIf;
	
	Template.Clear();
	Header = DataProcessors.ImportDataFromFile.HeaderOfTemplateForFillingColumnsInformation(ColumnsTable);
	Template.Put(Header);
	ShowInfoBarAboutRequiredColumns();
	
EndProcedure

&AtClient
Procedure TemplateWithDataOnChange(Item)
	FormClosingConfirmation = False;
EndProcedure

#Region BackgroundJobs

// Background import of file with data

&AtServer
Function ImportFileWithDataToSpreadsheetDocumentAtServer(TempStorageAddress, Extension)
	
	TempFileName = GetTempFileName(Extension);
	BinaryData = GetFromTempStorage(TempStorageAddress);
	BinaryData.Write(TempFileName);
	
	ClearTemplateWithData();
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("Extension", Extension);
	ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
	ServerCallParameters.Insert("TempFileName", TempFileName);
	ServerCallParameters.Insert("ColumnsInformation", FormAttributeToValue("ColumnsInformation"));
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("ru = 'Подсистема ЗагрузкаДанныхИзФайла: Выполнение серверного метода загрузка данных из файла'; en = 'ImportDataFromFile subsystem: import data from file using the server method'; pl = 'Podsystem DataLoadFromFile: Wykonanie metody importu danych z serwera przetwarzania z pliku';de = 'ImportDataFromFile Subsystem: Importieren von Daten aus einer Datei mit der Server-Methode';ro = 'Subsistem ImportDataFromFile: Importați date din fișier folosind metoda server-ului';tr = 'DosyadanVeriAl alt sistemi: Sunucu yöntemini kullanarak dosyadan veri almak'; es_ES = 'El subsistema ImportDataFromFile: Importar los datos del archivo usando el método del servidor'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ImportDataFromFile.ImportFileToTable",
		ServerCallParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterImportDataFileToSpreadsheetDocument(BackgroundJob, AdditionalParameters) Export

	If BackgroundJob.Status = "Completed" Then
		TemplateWithData = GetFromTempStorage(BackgroundJob.ResultAddress);
		MapDataToImport();
	Else
		OutputErrorMessage(NStr("ru = 'Не удалось произвести загрузку данных.'; en = 'Cannot import data.'; pl = 'Nie udało się przeprowadzić pobieranie danych.';de = 'Die Daten konnten nicht heruntergeladen werden.';ro = 'Eșec la încărcarea datelor.';tr = 'Veri yüklenemedi.'; es_ES = 'No se ha podido realizar el cargo de datos.'"), BackgroundJob.BriefErrorPresentation);
	EndIf;

EndProcedure

// Background mapping of imported data

&AtServer
Function MapDataToImportAtServerUniversalImport()
	
	ImportDataFromFile.AddStatisticalInformation(?(ImportOption = 0,
		"ImportOption.FillTable", "ImportOption.FromExternalFile"));
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
	ServerCallParameters.Insert("MappingTable", FormAttributeToValue("DataMappingTable"));
	ServerCallParameters.Insert("ColumnsInformation", FormAttributeToValue("ColumnsInformation"));
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("ru = 'Заполнение таблицы сопоставления загруженными данными из файла.'; en = 'Populate mapping table with data imported from file.'; pl = 'Wypełnienie tabeli porównania pobranymi danymi z pliku.';de = 'Füllen Sie die entsprechende Tabelle mit den heruntergeladenen Daten aus der Datei.';ro = 'Completarea tabelului de confruntare cu datele importate din fișier.';tr = 'Eşleme tablosunu dosyadan yüklenen verilerle doldur.'; es_ES = 'El relleno de la tabla de mapeo con los datos cargados del archivo.'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ImportDataFromFile.FillMappingTableWithDataFromTemplateBackground", 
		ServerCallParameters, BackgroundExecutionParameters);
	
	
	Return BackgroundJob;
EndFunction

&AtClient
Procedure AfterMapImportedData(BackgroundJob, AdditionalParameters) Export

	If BackgroundJob.Status = "Completed" Then
		ExecuteDataToImportMappingStepAfterMapAtServer(BackgroundJob.ResultAddress);
		ExecuteDataToImportMappingStepClient();
	ElsIf BackgroundJob.Status = "Error" Then
		OutputErrorMessage(NStr("ru = 'Не удалось произвести сопоставление данных.'; en = 'Cannot map data.'; pl = 'Nie udało się przeprowadzić porównanie danych.';de = 'Datenzuordnung konnte nicht durchgeführt werden.';ro = 'Eșec la confruntarea datelor.';tr = 'Veri eşlemesi başarısız oldu.'; es_ES = 'No se ha podido realizar el mapeo de datos.'"),
			BackgroundJob.BriefErrorPresentation);
	EndIf;

EndProcedure

// Background recording of imported data

&AtServer
Function RecordDataToImportReportUniversalImport()
	
	ImportParameters = New Structure();
	ImportParameters.Insert("CreateIfUnmapped", CreateIfUnmapped);
	ImportParameters.Insert("UpdateExistingItems", UpdateExistingItems);

	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("MappedData", FormAttributeToValue("DataMappingTable"));
	ServerCallParameters.Insert("ImportParameters", ImportParameters);
	ServerCallParameters.Insert("MappingObjectName", MappingObjectName);
	ServerCallParameters.Insert("ColumnsInformation", FormAttributeToValue("ColumnsInformation"));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Запись загруженных данных из файла'; en = 'Save data imported from file'; pl = 'Zapis pobranych danych z pliku';de = 'Heruntergeladene Daten aus einer Datei aufzeichnen';ro = 'Înregistrarea datelor importate din fișier';tr = 'Dosyadan indirilen verilerin kaydı'; es_ES = 'Guardar los datos cargados del archivo'");
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.ImportDataFromFile.WriteMappedData", 
		ServerCallParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure AfterSaveDataToImportReport(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob.Status = "Error" Then
		OutputErrorMessage(NStr("ru = 'Не удалось произвести запись данных.'; en = 'Cannot save data.'; pl = 'Nie udało się zapisać danych.';de = 'Die Daten konnten nicht aufgezeichnet werden.';ro = 'Eșec la înregistrarea datelor.';tr = 'Veriler kaydedilemedi.'; es_ES = 'No se ha podido guardar los datos.'"), BackgroundJob.BriefErrorPresentation);
	ElsIf BackgroundJob.Status = "Completed" Then
		FillMappingTableFromTempStorage(BackgroundJob.ResultAddress);
		ReportAtClientBackgroundJob();
	EndIf;

EndProcedure

&AtServer
Procedure FillMappingTableFromTempStorage(AddressInTempStorage)
	MappedData = GetFromTempStorage(AddressInTempStorage);
	ValueToFormAttribute(MappedData, "DataMappingTable");
EndProcedure


// Background report generation

&AtServer
Function GenerateReportOnImport(ReportType = "AllItems",  CalculateProgressPercent = False)
	
	MappedData        = FormAttributeToValue("DataMappingTable");
	TableColumnsInformation = FormAttributeToValue("ColumnsInformation");
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("ReportTable", ReportTable);
	ServerCallParameters.Insert("ReportType", ReportType);
	ServerCallParameters.Insert("MappedData", MappedData);
	ServerCallParameters.Insert("TemplateWithData", TemplateWithData);
	ServerCallParameters.Insert("MappingObjectName", MappingObjectName);
	ServerCallParameters.Insert("CalculateProgressPercent", CalculateProgressPercent);
	ServerCallParameters.Insert("ColumnsInformation", TableColumnsInformation);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Создание отчета о загрузке данных из файла'; en = 'Create report on data import from file'; pl = 'Tworzenie raportu na temat ładowania danych z pliku';de = 'Erstellen eines Berichts zum Herunterladen von Daten aus der Datei';ro = 'Crearea raportului despre importul de date din fișier';tr = 'Dosyadan veri yükleme raporu oluşturma'; es_ES = 'Crear el informe del cargo de los datos del archivo'");
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.ImportDataFromFile.GenerateReportOnBackgroundImport",
		ServerCallParameters, ExecutionParameters);
		
EndFunction

&AtClient
Procedure AfterCreateReport(Job, AdditionalResults) Export

	If Job.Status = "Completed" Then
		ShowReport(Job.ResultAddress);
		FormClosingConfirmation = True;
	ElsIf Job.Status = "Error" Then
		CommonClient.MessageToUser(Job.BriefErrorPresentation);
		GoToPage(Items.DataToImportMapping);
	Else
		GoToPage(Items.DataToImportMapping);
	EndIf;
	
EndProcedure

// display progress

&AtClient
Procedure ExecutionProgress(Result, AdditionalParameters) Export
	
	If Result.Status = "Running" Then
		Progress = ReadProgress(Result.JobID);
		If Progress <> Undefined Then
			BackgroundJobPercentage = Progress.Percent;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function ReadProgress(JobID)
	Return TimeConsumingOperations.ReadProgress(JobID);
EndFunction

#EndRegion

#EndRegion
