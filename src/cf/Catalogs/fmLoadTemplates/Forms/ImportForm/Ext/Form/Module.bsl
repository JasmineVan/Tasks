
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
Procedure FillMaps()
	
	// Заполним из метаданных соответствие имени реквизита его синониму.
	NameSynonymMap = New Structure();
	For Each CurAttribute In Metadata.Documents.fmBudget.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert(CurAttribute.Name, CurAttribute.Synonym);
		EndIf;
	EndDo;
	NameSynonymMap.Insert("DATE", NStr("en='Date';ru='Дата'"));
	NameSynonymMap.Insert("Scenario", NStr("en='Scenario';ru='Сценарий'"));
	For Each CurAttribute In Metadata.Documents.fmBudget.TabularSections.BudgetsData.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert("BudgetsData"+CurAttribute.Name, CurAttribute.Synonym);
		EndIf;
	EndDo;
	
EndProcedure // ЗаполнитьСоответствия()

&AtClientAtServerNoContext
Function GetSynonym(CurRow, NameSynonymMap)
	If TypeOf(CurRow) = Type("String") Then
		AttributeName = CurRow;
	Else 
		If ValueIsFilled(CurRow.TSName) Then
			AttributeName = CurRow.TSName + CurRow.Attribute;
		Else
			AttributeName = CurRow.Attribute;
		EndIf;
	EndIf;
	Try
		Return NameSynonymMap[AttributeName];
	Except
		If TypeOf(CurRow) = Type("String") Then
			Return AttributeName;
		Else
			Return StrReplace(AttributeName, CurRow.TSName, "");
		EndIf;
	EndTry;
EndFunction // ПолучитьСиноним()

&AtServer
Procedure LoadTemplateOnChangeServer()
	
	// Подставим путь к файлу по умолчанию, если он есть.
	If ValueIsFilled(LoadTemplate.File) Then
		File = LoadTemplate.File;
		DefaultSheet = LoadTemplate.DefaultSheet;
	EndIf;
	
	// Заполним реквизитами со способом считывания "Фикс. значения" для возможности перевыбора.
	Attributes.Clear();
	For Each CurRow In LoadTemplate.LoadSettings Do
		If CurRow.ReadMethod = Enums.fmReadMethods.FixedValue Then
			NewLine = Attributes.Add();
			FillPropertyValues(NewLine, CurRow);
			NewLine.Value = CurRow.FixedValue;
			NewLine.TypeRestriction = CurRow.ValueType.Get();
			NewLine.Presentation = GetSynonym(NewLine, NameSynonymMap);
		EndIf;
	EndDo;
	
EndProcedure // ШаблонЗагрузкиПриИзмененииСервер()


//////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД И РЕКВИЗИТОВ ФОРМЫ

&AtClient
Procedure Load(Command)
	
	IsError=False;
	For Each CurRow In Attributes Do
		If NOT ValueIsFilled(CurRow.Value) Then
			CommonClientServer.MessageToUser(NStr("en='The attribute value is not specified ""';ru='Не указано значение реквизита ""'")+CurRow.Presentation+"""", , "Attributes", , IsError);
		EndIf;
	EndDo;
	If IsError Then Return; EndIf;
	
	// Выполним проверки перед загрузкой.
	If NOT ValueIsFilled(LoadTemplate) Then
		CommonClientServer.MessageToUser(NStr("en='The import template is not specified.';ru='Не указан шаблон загрузки!'"), , "LoadTemplate");
		Return;
	ElsIf NOT ValueIsFilled(File) Then
		CommonClientServer.MessageToUser(NStr("en='The load file path is not specified.';ru='Не указан путь к файлу загрузки!'"), , "File");
		Return;
	ElsIf NOT ValueIsFilled(DefaultSheet) Then
		CommonClientServer.MessageToUser(NStr("en='The default import sheet is not specified.';ru='Не указан лист загрузки по-умолчанию!'"), , "DefaultSheet");
		Return;
	EndIf;
	
	ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(File, DefaultSheet, LoadTemplate, Attributes, UpdateExistingDocuments);
	If TypeOf(ParametersStructure)=Type("Structure") Then
		// Выведем загруженные документы.
		LoadedDocuments.Clear();
		If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
			For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
				NewLine=LoadedDocuments.Add();
				NewLine.Document=CurDocument;
			EndDo;
			If LoadedDocuments.Count()>0 Then
				Items.GroupPages.CurrentPage=Items.GroupPageLoadedDocuments;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadTemplateOnChange(Item)
	// Уходим на сервер только если шаблон выбран.
	If ValueIsFilled(LoadTemplate) Then
		LoadTemplateOnChangeServer();
	EndIf;
EndProcedure // ШаблонЗагрузкиПриИзменении()

&AtClient
Procedure FileOpen(Item, StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(File) Then
		Try
			NotDescr = New NotifyDescription("FileOpenEnd", ThisObject);
			BeginRunningApplication(NotDescr, File);
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the file.';ru='Не удалось открыть файл!'"));
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The file path is not specified.';ru='Не указан путь к файлу!'"));
	EndIf;
EndProcedure // ФайлОткрытие()

&AtClient
Procedure FileOpenEnd(Response, Parameter) Export
	
EndProcedure

&AtClient
Procedure FileStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FileChoice = New FileDialog(FileDialogMode.Open);
	FileChoice.Multiselect = False;
	FileChoice.Filter = "Excel (*.xls;*.xlsx)|*.xls;*.xlsx";
	FileChoice.Title = NStr("en='Select an excel file...';ru='Выберите файл excel...'");
	FileChoice.Show(New NotifyDescription("FileStartChoiceEnd", ThisObject, New Structure("FileChoice", FileChoice)));	
EndProcedure

&AtClient
Procedure FileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileChoice = AdditionalParameters.FileChoice;
	If (SelectedFiles <> Undefined) Then
		File = FileChoice.SelectedFiles[0];
		ReadPages(Undefined);
	EndIf;

EndProcedure // ФайлНачалоВыбора()

&AtClient
Procedure AttributesOnActivateRow(Item)
	// Установим тип значения для фиксированного значения.
	CurRow = Items.Attributes.CurrentData;
	If NOT CurRow = Undefined Then
		Items.AttributesValue.TypeRestriction = CurRow.TypeRestriction;
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadDocumentsChoice(Item, SelectedRow, Field, StandardProcessing)
	CurRow = Items.LoadedDocuments.CurrentData;
	If NOT CurRow=Undefined Then
		ShowValue( , CurRow.Document);
	EndIf;
EndProcedure

&AtClient
Procedure ReadPages(Command)
	
	// Доступ из 1С к Excel производится посредством OLE.
	Try
		AppExcel = New COMObject("Excel.Application"); 
	Except
		CommonClientServer.MessageToUser(NStr("en='File error! ';ru='Ошибка при работе с файлом! '") + ErrorDescription()); 
		Return;
	EndTry;
	
	// Откроем файл.
	If ValueIsFilled(File) Then
		Try
			ExcelFile = AppExcel.WorkBooks.Open(File);
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the file.';ru='Не удалось открыть файл '") + ErrorDescription());
			fmExcelFormatProcessingClient.CloseExcel(AppExcel);
			Return;
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The file path is not specified.';ru='Не указан путь к файлу!'"));
		fmExcelFormatProcessingClient.CloseExcel(AppExcel);
		Return;
	EndIf;
	
	// Создадим список листов.
	SheetList = New ValueList();
	SheetCount = ExcelFile.Sheets.Count;
	For Num=1 To SheetCount Do
		SheetList.Add(ExcelFile.Sheets(Num).Name);
	EndDo;
	
	// Заполним списки для выбора.
	Items.DefaultSheet.ChoiceList.LoadValues(SheetList.UnloadValues());
	
	// Подставим первый лист при необходимости.
	If SheetList.Count()>0 AND SheetList.FindByValue(DefaultSheet)=Undefined Then
		DefaultSheet = SheetList[0].Value;
	EndIf;
	
	fmExcelFormatProcessingClient.CloseExcel(AppExcel);
	
EndProcedure // ПрочитатьСтраницы()

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FillMaps();
	// Если передали параметры, то подставим их.
	If Parameters.Property("Department") Then
		NewLine = Attributes.Add();
		NewLine.Attribute = "Department";
		NewLine.Value = Parameters.Department;
		NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmDepartments");
	EndIf;
	If Parameters.Property("BeginOfPeriod") Then
		NewLine = Attributes.Add();
		NewLine.Attribute = "BeginOfPeriod";
		NewLine.Value = Parameters.BeginOfPlanningPeriod;
		NewLine.TypeRestriction = New TypeDescription("DATE", , , New DateQualifiers(DateFractions.DATE));
	EndIf;
	If Parameters.Property("Scenario") Then
		NewLine = Attributes.Add();
		NewLine.Attribute = "Scenario";
		NewLine.Value = Parameters.Scenario;
		NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmBudgetingScenarios");
	EndIf;
	// Если передали шаблон загрузки, то подставим его сразу.
	If Parameters.Property("LoadTemplate") Then
		LoadTemplate = Parameters.LoadTemplate;
		LoadTemplateOnChangeServer();
	EndIf;
EndProcedure
