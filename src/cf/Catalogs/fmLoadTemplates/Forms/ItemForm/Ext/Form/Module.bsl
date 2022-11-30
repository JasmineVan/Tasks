
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

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

&AtClient
Function GenerateConditionsText(NewLine, BeginConditions=False)
	// Сформируем текст настроек отбора считывания.
	Text = ?(BeginConditions, NStr("en='Start-of-import routine conditions customized';ru='Настроены условия начала'"), NStr("en='End-of-import routine conditions customized';ru='Настроены условия окончания'"));
	If ?(BeginConditions, NewLine.ConditionBeginByBackColor, NewLine.ConditionByBackColor) Then
		Text = Text + NStr("en=' by background color,';ru=' по цвету фона,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByTextColor, NewLine.ConditionByTextColor) Then
		Text = Text + NStr("en=' by text color,';ru=' по цвету текста,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByFont, NewLine.ConditionByFont) Then
		Text = Text + NStr("en=' by font,';ru=' по шрифту,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByIndent, NewLine.ConditionByIndent) Then
		Text = Text + NStr("en=' by indent,';ru=' по отступу,'");
	EndIf;
	If ?(BeginConditions, NewLine.ConditionBeginByValue, NewLine.ConditionByValue) Then
		Text = Text + NStr("en=' by value,';ru=' по значению,'");
	EndIf;
	If Text = ?(BeginConditions, NStr("en='Start-of-import routine conditions customized';ru='Настроены условия начала'"), NStr("en='End-of-import routine conditions customized';ru='Настроены условия окончания'")) Then 
		Text = ?(BeginConditions, NStr("en='Configure condition of beginning';ru='Set up условия начала'"), NStr("en='Configure condition of ending';ru='Set up условия окончания'"));
	Else
		Text = Left(Text, StrLen(Text)-1);
	EndIf;
	Return Text;
EndFunction // СформироватьТекстУсловий()

&AtClient
Function GenerateFilterText(NewLine)
	// Сформируем текст настроек отбора считывания.
	FilterText = NStr("en='Filters customized';ru='Настроены отборы'");
	If NewLine.BackColorFilter Then
		FilterText = FilterText + NStr("en=' by background color,';ru=' по цвету фона,'");
	EndIf;
	If NewLine.TextColorFilter Then
		FilterText = FilterText + NStr("en=' by text color,';ru=' по цвету текста,'");
	EndIf;
	If NewLine.FontFilter Then
		FilterText = FilterText + NStr("en=' by font,';ru=' по шрифту,'");
	EndIf;
	If NewLine.FilterByIndent Then
		FilterText = FilterText + NStr("en=' by indent,';ru=' по отступу,'");
	EndIf;
	If NewLine.FilterByValue Then
		FilterText = FilterText + NStr("en=' by value,';ru=' по значению,'");
	EndIf;
	If FilterText = NStr("en='Filters customized';ru='Настроены отборы'") Then 
		FilterText = NStr("en='Configure filters';ru='Настроить отборы'");
	Else
		FilterText = Left(FilterText, StrLen(FilterText)-1);
	EndIf;
	Return FilterText;
EndFunction // СформироватьТекстОтбора()

&AtClient
Function GetName(CurRow, SynonymNameMap)
	If TypeOf(CurRow)=Type("String") Then
		AttributeSynonym = fmBudgetingClientServer.DeleteSymbols(CurRow);
	ElsIf ValueIsFilled(CurRow.TSName) Then
		AttributeSynonym = CurRow.TSName + fmBudgetingClientServer.DeleteSymbols(CurRow.Attribute);
	Else
		AttributeSynonym = fmBudgetingClientServer.DeleteSymbols(CurRow.Attribute);
	EndIf;
	Try
		Return SynonymNameMap[AttributeSynonym];
	Except
		Try
			Return StrReplace(AttributeSynonym, CurRow.TSName, "");
		Except
			Return CurRow;
		EndTry;
	EndTry;
EndFunction // ПолучитьСиноним()

&AtServer
Procedure FillMaps()
	
	// Заполним из метаданных соответствие имени реквизита его синониму.
	// Заполним из метаданных соответствие синонима реквизита его имени.
	NameSynonymMap = New Structure();
	SynonymNameMap = New Structure();
	For Each CurAttribute In Metadata.Documents.fmBudget.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert(CurAttribute.Name, CurAttribute.Synonym);
			SynonymNameMap.Insert(fmBudgetingClientServer.DeleteSymbols(CurAttribute.Synonym), CurAttribute.Name);
		EndIf;
	EndDo;
	NameSynonymMap.Insert("DATE", NStr("en='Date';ru='Дата'"));
	SynonymNameMap.Insert(NStr("en='Date';ru='Дата'"), "DATE");
	NameSynonymMap.Insert("Scenario", NStr("en='Scenario';ru='Сценарий'"));
	SynonymNameMap.Insert(NStr("en='Scenario';ru='Сценарий'"), "Scenario");
	For Each CurAttribute In Metadata.Documents.fmBudget.TabularSections.BudgetsData.Attributes Do
		If ValueIsFilled(CurAttribute.Synonym) Then
			NameSynonymMap.Insert("BudgetsData"+CurAttribute.Name, CurAttribute.Synonym);
			SynonymNameMap.Insert("BudgetsData"+fmBudgetingClientServer.DeleteSymbols(CurAttribute.Synonym), CurAttribute.Name);
		EndIf;
	EndDo;
	
EndProcedure // ЗаполнитьСоответствия()

&AtClient
Function GetParent(CurRow)
	CurParent = CurRow.GetParent();
	If CurParent = Undefined Then
		Return CurRow;
	Else
		Return GetParent(CurParent);
	EndIf;
EndFunction // ПолучитьРодителя()

&AtClient
Procedure Load(Command)
	If Modified OR Object.Ref.IsEmpty() Then
		Response = Undefined;
		ShowQueryBox(New NotifyDescription("LoadEnd", ThisObject), NStr("en='You have to save the template to continue. Do you want to continue?';ru='Для продолжения работы необходимо сохранить шаблон. Продолжить?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	LoadFragment();
EndProcedure

&AtClient
Procedure LoadEnd(QueryResult, AdditionalParameters) Export
	
	Response = QueryResult;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	Try
		If NOT Write() Then 
			Return;
		EndIf;
	Except	
		CommonClientServer.MessageToUser(NStr("en='An error occurred while saving a template. ';ru='При сохранении шаблона произошла ошибка! '") + ErrorDescription());
		Return;
	EndTry;
	
	LoadFragment();

EndProcedure

&AtClient
Procedure LoadFragment()
	
	OpeningParameters = New Structure("LoadTemplate", Object.Ref);
	OpenForm("Catalog.fmLoadTemplates.Form.ImportForm", OpeningParameters);

EndProcedure

&AtClient
Procedure CheckColumnNumber(ColumnNum, OnlyNumber = False)
	
	If NOT ValueIsFilled(ColumnNum) Then Return EndIf;
	
	LetterArray = New Array();
	LetterArray.Add("A");
	LetterArray.Add("B");
	LetterArray.Add("C");
	LetterArray.Add("D");
	LetterArray.Add("E");
	LetterArray.Add("F");
	LetterArray.Add("G");
	LetterArray.Add("H");
	LetterArray.Add("I");
	LetterArray.Add("J");
	LetterArray.Add("K");
	LetterArray.Add("L");
	LetterArray.Add("M");
	LetterArray.Add("N");
	LetterArray.Add("O");
	LetterArray.Add("P");
	LetterArray.Add("Q");
	LetterArray.Add("R");
	LetterArray.Add("S");
	LetterArray.Add("T");
	LetterArray.Add("U");
	LetterArray.Add("V");
	LetterArray.Add("W");
	LetterArray.Add("X");
	LetterArray.Add("Y");
	LetterArray.Add("Z");
	
	// Приведем к верхнему регистру для проверки.
	ColumnNum = Upper(ColumnNum);
	Try
		Number = Number(ColumnNum);
	Except
		If OnlyNumber Then
			CommonClientServer.MessageToUser(NStr("en='The column name must be numerical.';ru='Обозначение колонки может быть только числовым!'"));
			ColumnNum = "";
		Else
			Num = 1;
			While Num <= StrLen(ColumnNum) Do
				If LetterArray.Find(Mid(ColumnNum, Num, 1)) = Undefined Then
					CommonClientServer.MessageToUser(NStr("en='The row (of the column) must be literal or numerical.';ru='Обозначение строки(колонки) может быть или буквенным или числовым!'"));
					ColumnNum = "";
					Return;
				EndIf;
				Num = Num + 1;
			EndDo;
		EndIf;
	EndTry;
	
EndProcedure // ПроверитьНомерКолонки()

&AtClient
Function SelectedInTree(Attribute, Tree=Undefined)
	If Tree = Undefined Then
		Tree = SettingsTree;
	EndIf;
	CurItems = Tree.GetItems();
	For Each CurRow In CurItems Do
		If CurRow.Attribute = Attribute AND NOT CurRow.PredefinedRow Then
			Return True;
		EndIf;
		If SelectedInTree(Attribute, CurRow) Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction // ВыбраноВДереве()

&AtClient
Function FormList(Attribute)
	// Соберем список выбора для реквизита.
	// Возможность выбора есть только из тех, что еще не использованы.
	AttributeList = New ValueList();
	For Each CurRow In TSAttributes Do
		Filter = New Structure("Attribute, TSName", CurRow.Attribute, CurRow.TSName);
		If LoadSettings.FindRows(Filter).Count()=0 
		AND NOT SelectedInTree(CurRow.Attribute) Then
			AttributeList.Add(CurRow.Attribute, CurRow.Attribute);
		EndIf;
	EndDo;
	If ValueIsFilled(Attribute) Then
		AttributeList.Add(Attribute, Attribute);
	EndIf;
	Return AttributeList
EndFunction // СформироватьСписок()


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Заполним строками по умолчанию для новых элементов.
	If NOT ValueIsFilled(Object.Ref) Then
		
		FillMaps();
		Object.DefaultSheet = NStr("en='Sheet1';ru='Лист1'");
		
		SettingsTreeVT = FormDataToValue(SettingsTree, Type("ValueTree"));
		LoadSettingsVT = FormDataToValue(LoadSettings, Type("ValueTable"));
		
		TemporaryModule.LoadTemplateOnCreateAtServer(SettingsTreeVT, LoadSettingsVT, Parameters.CopyingValue, NameSynonymMap, SynonymNameMap);
		
		ValueToFormData(SettingsTreeVT, SettingsTree);
		ValueToFormData(LoadSettingsVT, LoadSettings);	
		
	EndIf;
	
	// Список реквизитов ТЧ.
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Period";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = New TypeDescription("DATE", , , New DateQualifiers(DateFractions.DATE));
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "RecordType";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = New TypeDescription("EnumRef.fmBudgetFlowOperationTypes");
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Item";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmIncomesAndExpensesItems, CatalogRef.fmCashflowItems");
	NewLine.SynchronizationIsAvailable = True;
	NewLine.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription;
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics1";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type;
	NewLine.SynchronizationIsAvailable = True;
	NewLine.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription;
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics2";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type;
	NewLine.SynchronizationIsAvailable = True;
	NewLine.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription;
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Analytics3";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type;
	NewLine.SynchronizationIsAvailable = True;
	NewLine.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription;
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "CorDepartment";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = New TypeDescription("CatalogRef.fmDepartments");
	NewLine.SynchronizationIsAvailable = True;
	NewLine.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription;
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	NewLine = TSAttributes.Add();
	NewLine.Attribute = "Amount";
	NewLine.TSName = "BudgetsData";
	NewLine.TypeRestriction = New TypeDescription("Number", New NumberQualifiers(15, 2));
	NewLine.Attribute = GetSynonym(NewLine, NameSynonymMap);
	
	// Запомним значение листа по-умолчанию.
	DefaultObjectSheet = Object.DefaultSheet;
	
	// Если ИмяТЧ не заполнено, то это предопределенная строка.
	For Each CurRow In LoadSettings Do
		If NOT ValueIsFilled(CurRow.TSName) Then
			CurRow.PredefinedRow = True;
		EndIf;
	EndDo;
	
EndProcedure // ПриСозданииНаСервере()

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	TemporaryModule.LoadTemplateBeforeWriteAtServer(CurrentObject, FormDataToValue(SettingsTree, Type("ValueTree")), FormDataToValue(LoadSettings, Type("ValueTable")), SynonymNameMap, Cancel);
	
	// Если есть ресурсы, то надо проверить что есть строки и колонки.
	If NOT CurrentObject.LoadSettings.Find(Enums.fmReadMethods.Resource, "ReadMethod") = Undefined Then
		If CurrentObject.LoadSettings.Find(Enums.fmReadMethods.Column, "ReadMethod") = Undefined Then
			CommonClientServer.MessageToUser(NStr("en='You can use settings of the ""Resource"" type strictly subject to the availability of the ""Column"" type setting.';ru='Настройки вида ""Ресурс"" допустимо использовать только при наличии настройки вида ""Колонка""!'"), , , , Cancel);
		EndIf;
		If CurrentObject.LoadSettings.Find(Enums.fmReadMethods.Row, "ReadMethod") = Undefined Then
			CommonClientServer.MessageToUser(NStr("en='You can use settings of the ""Resource"" type strictly subject to the availability of the ""Row"" type setting.';ru='Настройки вида ""Ресурс"" допустимо использовать только при наличии настройки вида ""Строка""!'"), , , , Cancel);
		EndIf;
	EndIf;
	
EndProcedure // ПередЗаписьюНаСервере()

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillMaps();
	
	SettingsTreeVT = FormDataToValue(SettingsTree, Type("ValueTree"));
	LoadSettingsVT = FormDataToValue(LoadSettings, Type("ValueTable"));
	
	TemporaryModule.LoadTemplateOnReadAtServer(CurrentObject, SettingsTreeVT, LoadSettingsVT, NameSynonymMap, SynonymNameMap);
	
	ValueToFormData(SettingsTreeVT, SettingsTree);
	ValueToFormData(LoadSettingsVT, LoadSettings);
	
EndProcedure // ПриЧтенииНаСервере()

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	
	// Проведем проверку заполнения.
	For Each CurRow In LoadSettings Do
		LineNumber = LoadSettings.IndexOf(CurRow);
		// В зависимости от способа считывания.
		If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Cell") Then
			If NOT ValueIsFilled(CurRow.RowNum) Then
				CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Row number"" is required.';ru=' не указан ""№ строки""!'"), , "LoadSettings["+LineNumber+"].RowNum", , Cancel);
			EndIf;
			If NOT ValueIsFilled(CurRow.ColumnNum) Then
				CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Column number"" is required.';ru=' не указан ""№ колонки""!'"), , "LoadSettings["+LineNumber+"].ColumnNum", , Cancel);
			EndIf;
		ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.FixedValue") AND NOT ValueIsFilled(CurRow.FixedValue) Then
			CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Fixed value"" is required.';ru=' не указано ""Фиксированное значение""!'"), , "LoadSettings["+LineNumber+"].FixedValue", , Cancel);
		EndIf;
		// Вне зависимости от способа считывания
		If CurRow.SynchronizationIsAvailable AND NOT (CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.FixedValue") OR CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.DontRead")) AND NOT ValueIsFilled(CurRow.SynchronizationMethod) Then
			CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Synchronization way"" is required.';ru=' необходимо указать ""Способ синхронизации""!'"), , "LoadSettings["+LineNumber+"].SynchronizationMethod", , Cancel);
		EndIf;
		If NOT ValueIsFilled(CurRow.ReadMethod) Then
			CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Import method"" is required.';ru=' необходимо указать ""Способ считывания""!'"), , "LoadSettings["+LineNumber+"].ReadMethod", , Cancel);
		EndIf;
		If NOT ValueIsFilled(CurRow.Sheet) Then
			CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Sheet"" is required.';ru=' необходимо указать ""Лист""!'"), , "LoadSettings["+LineNumber+"].Sheet", , Cancel);
		EndIf;
		If NOT ValueIsFilled(CurRow.Attribute) Then
			CommonClientServer.MessageToUser(NStr("en='In row No.';ru='В строке №'") + (LineNumber+1) + NStr("en='the ""Attribute"" is required.';ru=' необходимо указать ""Реквизит""!'"), , "LoadSettings["+LineNumber+"].Attribute", , Cancel);
		EndIf;
	EndDo;
	
EndProcedure // ПередЗаписью()


//////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД И РЕКВИЗИТОВ ФОРМЫ

&AtClient
Procedure FileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Modified = True;
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
		Object.File = FileChoice.SelectedFiles[0];
		ReadPages(Undefined);
	EndIf;

EndProcedure // ФайлНачалоВыбора()

&AtClient
Procedure FileOpen(Item, StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(Object.File) Then
		Try
			NotDesc = New NotifyDescription("ReferenceFileOpenEnd", ThisObject);
			BeginRunningApplication(NotDesc, Object.File); 
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the file.';ru='Не удалось открыть файл!'"));
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The file path is not specified.';ru='Не указан путь к файлу!'"));
	EndIf;
EndProcedure // ФайлОткрытие()

&AtClient
Procedure ReferenceFileOpenEnd(Res, Parameter) Export
	
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
	If ValueIsFilled(Object.File) Then
		Try
			ExcelFile = AppExcel.WorkBooks.Open(Object.File);
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
	Items.LoadSettingsSheet.ChoiceList.LoadValues(SheetList.UnloadValues());
	
	// Подставим первый лист при необходимости.
	If SheetList.Count()>0 AND SheetList.FindByValue(Object.DefaultSheet)=Undefined Then
		Object.DefaultSheet = SheetList[0].Value;
		DefaultSheetOnChange(Undefined);
	EndIf;
	
	fmExcelFormatProcessingClient.CloseExcel(AppExcel);
	
EndProcedure // ПрочитатьСтраницы()

&AtClient
Procedure DefaultSheetOnChange(Item)
	// Пройдемся по таблице и заменим лист.
	For Each CurRow In LoadSettings Do
		If CurRow.Sheet = DefaultObjectSheet Then
			CurRow.Sheet = Object.DefaultSheet;
		EndIf;
	EndDo;
	DefaultObjectSheet = Object.DefaultSheet;
EndProcedure

&AtClient
Procedure LoadSettingsOnActivateRow(Item)
	
	CurRow = Items.LoadSettings.CurrentData;
	
	// Установим тип значения для фиксированного значения.
	Items.LoadSettingsFixedValue.TypeRestriction = CurRow.TypeRestriction;
	
	// Нельзя удалять предопределенные строки.
	Items.LoadSettingsDelete.Enabled = NOT CurRow.PredefinedRow;
	Items.LoadSettingsPopupMenuDelete.Enabled = NOT CurRow.PredefinedRow;
	
EndProcedure // НастройкиЗагрузкиПриАктивизацииСтроки()

&AtClient
Procedure LoadSettingsColumnNumOnChange(Item)
	CurRow = Items.LoadSettings.CurrentData;
	CheckColumnNumber(CurRow.ColumnNum);
EndProcedure // НастройкиЗагрузкиНомКолонкиПриИзменении()

&AtClient
Procedure SpanBeginOnChange(Item)
	CurRow = Items.SettingsTree.CurrentData;
	Parent = GetParent(CurRow);
	If Parent.Attribute = NStr("en='Rows';ru='Строки'") Then
		CheckColumnNumber(CurRow.SpanBegin, True);
	Else
		CheckColumnNumber(CurRow.SpanBegin);
	EndIf;
EndProcedure // НастройкиЗагрузкиНачалоДиапозонаПриИзменении()

&AtClient
Procedure SpanEndOnChange(Item)
	CurRow = Items.SettingsTree.CurrentData;
	Parent = GetParent(CurRow);
	If Parent.Attribute = NStr("en='Rows';ru='Строки'") Then
		CheckColumnNumber(CurRow.SpanEnd, True);
	Else
		CheckColumnNumber(CurRow.SpanEnd);
	EndIf;
EndProcedure // НастройкиЗагрузкиКонецДиапозонаПриИзменении()

&AtClient
Procedure SettingsTreeOnActivateRow(Item)
	
	CurRow = Items.SettingsTree.CurrentData;
	
	// В ресурсы можно добавить только строки 1-го уровня подчинения иерархии.
	CurParent = CurRow.GetParent();
	
	EnableAdd = True;
	// Если есть иерархия +1 уровня, то уже нельзя добавлять, так как плоские считывания в самом низу.
	CurItems = CurRow.GetItems();
	For Each CurItem In CurItems Do
		If CurItem.GetItems().Count()>0 Then
			EnableAdd = False;
			Break;
		EndIf;
	EndDo;
	// Если есть плоские считывания (1-го уровня), то уже нельзя добавлять +1 иерархию.
	If NOT CurParent = Undefined AND CurParent.GetItems().Count()>1 Then
		EnableAdd = False;
	EndIf;
	// У ресурсов только плоские описания.
	If (NOT CurParent = Undefined AND CurParent.Attribute = NStr("en='Resources';ru='Ресурсы'") AND CurParent.PredefinedRow) Then
		EnableAdd = False;
	EndIf;
	
	// Установим доступность кнопки "Добавить".
	Items.SettingsTreeAdd.Enabled = EnableAdd;
	Items.SettingsTreePopupMenuAdd.Enabled = EnableAdd;
	
	// Нельзя удалять предопределенные строки.
	Items.SettingsTreeDelete.Enabled = NOT CurRow.PredefinedRow;
	Items.SettingsTreePopupMenuDelete.Enabled = NOT CurRow.PredefinedRow;
	
EndProcedure // ДеревоНастроекПриАктивизацииСтроки()

&AtClient
Procedure SettingsTreeBeforeDelete(Item, Cancel)
	CurRow = Items.SettingsTree.CurrentData;
	Cancel = CurRow.PredefinedRow;
	If NOT Cancel AND NOT CurRow.IsResource Then
		CurParent = CurRow.GetParent();
		CurParentItems = CurParent.GetItems();
		// Если удаляем первый плоский элемент, то следующий надо сделать не плоским.
		If CurParentItems.Count()>1 Then
			If CurParentItems[0].GetID()=CurRow.GetID() Then
				CurParentItems[1].Shift=1;
				CurParentItems[1].FlatSetting=False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ДеревоНастроекПередУдалением()

&AtClient
Procedure SettingsTreeOnActivateCell(Item)
	If Item.CurrentItem.Name = "SettingsTreeAttribute" Then
		CurRow = Items.SettingsTree.CurrentData;
		Items.SettingsTreeAttribute.ChoiceList.LoadValues(FormList(CurRow.Attribute).UnloadValues());
	EndIf;
EndProcedure // ДеревоНастроекПриАктивизацииЯчейки()

&AtClient
Procedure LoadSettingsOnActivateCell(Item)
	If Item.CurrentItem.Name = "LoadSettingsAttributeName" Then
		CurRow = Items.LoadSettings.CurrentData;
		If NOT CurRow=Undefined Then
			Items.LoadSettingsAttributeName.ChoiceList.LoadValues(FormList(CurRow.Attribute).UnloadValues());
		EndIf;
	EndIf;
EndProcedure // НастройкиЗагрузкиПриАктивизацииЯчейки()

&AtClient
Procedure LoadSettingsBeforeDelete(Item, Cancel)
	CurRow = Items.LoadSettings.CurrentData;
	Cancel = CurRow.PredefinedRow;
EndProcedure // НастройкиЗагрузкиПередУдалением()

&AtClient
Procedure SettingsTreeAttributeOnChange(Item)
	CurRow = Items.SettingsTree.CurrentData;
	CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.EmptyRef");
	If ValueIsFilled(CurRow.Attribute) Then
		Filter = New Structure("Attribute", CurRow.Attribute);
		SettingsRow = TSAttributes.FindRows(Filter);
		FillPropertyValues(CurRow, SettingsRow[0]);
		AttributeName = GetName(CurRow, SynonymNameMap);
	EndIf;
EndProcedure // ДеревоНастроекРеквизитПриИзменении()

&AtClient
Procedure LoadSettingsAttributeNameOnChange(Item)
	CurRow = Items.LoadSettings.CurrentData;
	CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.EmptyRef");
	If ValueIsFilled(CurRow.Attribute) Then
		Filter = New Structure("Attribute", CurRow.Attribute);
		SettingsRow = TSAttributes.FindRows(Filter);
		FillPropertyValues(CurRow, SettingsRow[0]);
		Items.LoadSettingsFixedValue.TypeRestriction = CurRow.TypeRestriction;
		AttributeName = GetName(CurRow, SynonymNameMap);
	EndIf;
EndProcedure // НастройкиЗагрузкиИмяРеквизитаПриИзменении()

&AtClient
Procedure LoadSettingsOnStartEdit(Item, NewLine, Copy)
	If NewLine Then
		CurRow = Items.LoadSettings.CurrentData;
		CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Cell");
		CurRow.Sheet = Object.DefaultSheet;
	EndIf;
EndProcedure // НастройкиЗагрузкиПриНачалеРедактирования()

&AtClient
Procedure SettingsTreeColumnNumOnChange(Item)
	CurRow = Items.SettingsTree.CurrentData;
	Parent = GetParent(CurRow);
	If Parent.Attribute = NStr("en='Columns';ru='Колонки'") Then
		CheckColumnNumber(CurRow.ColumnRowNum, True);
	Else
		CheckColumnNumber(CurRow.ColumnRowNum);
	EndIf;
EndProcedure // ДеревоНастроекНомКолонкиСтрокиПриИзменении()

&AtClient
Procedure LoadSettingsEvaluationCodeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	Modified = True;
	CurRow = Items.LoadSettings.CurrentData;
	ParametersStructure = New Structure("Code", CurRow.EvalCode);
	AddParameters = New Structure("ItemName", "LoadSettings");
	Handler = New NotifyDescription("LoadSettingsEvaluationCodeStartChoice_End", ThisObject, AddParameters);
	OpenForm("Catalog.fmLoadTemplates.Form.CodeEditingForm",ParametersStructure, ThisForm,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // НастройкиЗагрузкиКодВычисленияНачалоВыбора()

&AtClient
Procedure LoadSettingsEvaluationCodeStartChoice_End(Result, Parameter) Export
	If NOT Result = Undefined Then
		CurRow = Items[Parameter.ItemName].CurrentData;
		CurRow.EvalCode = Result;
	EndIf;
EndProcedure

&AtClient
Procedure SettingsTreeEvaluationCodeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	Modified = True;
	CurRow = Items.SettingsTree.CurrentData;
	ParametersStructure = New Structure("Code", CurRow.EvalCode);
	AddParameters = New Structure("ItemName", "SettingsTree");
	Handler = New NotifyDescription("LoadSettingsEvaluationCodeStartChoice_End", ThisObject, AddParameters);
	OpenForm("Catalog.fmLoadTemplates.Form.CodeEditingForm",ParametersStructure, ThisForm,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ДеревоНастроекКодВычисленияНачалоВыбора()

&AtClient
Procedure SettingsTreeColumnRowOfReadingEnd(Item)
	CurRow = Items.SettingsTree.CurrentData;
	Parent = GetParent(CurRow);
	If Parent.Attribute = NStr("en='Columns';ru='Колонки'") Then
		CheckColumnNumber(CurRow.ColumnRowOfReadingEnd, True);
	Else
		CheckColumnNumber(CurRow.ColumnRowOfReadingEnd);
	EndIf;
EndProcedure

&AtClient
Procedure SettingsTreeBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	If Copy Then Cancel=True; EndIf;
EndProcedure // ДеревоНастроекПередНачаломДобавления()

&AtClient
Procedure SettingsTreeOnStartEdit(Item, NewLine, Copy)
	CurRow = Items.SettingsTree.CurrentData;
	CurParent = CurRow.GetParent();
	If NewLine Then 
		If CurParent.Attribute = NStr("en='Resources';ru='Ресурсы'") AND CurParent.PredefinedRow Then
			CurRow.IsResource = True;
		ElsIf CurParent.GetItems().Count()=1 Then
			CurRow.Shift = 1;
			CurRow.FiltersSettings = NStr("en='Configure filters';ru='Настроить отборы'");
			CurRow.EndConditions = NStr("en='Configure condition of ending';ru='Set up условия окончания'");
			CurRow.BeginConditions = NStr("en='Configure condition of beginning';ru='Set up условия начала'");
		ElsIf CurParent.GetItems().Count()>1 Then
			CurRow.FlatSetting = True;
		EndIf;
	EndIf;
EndProcedure // ДеревоНастроекПриНачалеРедактирования()

&AtClient
Procedure SettingsTreeChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CurRow = Items.SettingsTree.CurrentRow;
	CurData = Items.SettingsTree.CurrentData;
	
	If Field.Name = "SettingsTreeFiltersSetting" Then
		StandardProcessing = False;

		If NOT (CurData.IsResource OR CurData.PredefinedRow OR CurData.FlatSetting) Then
			Modified = True;
			ParametersStructure = New Structure("Font, Size, Bold, Italic, Underlined, FontFilter, 
			|FontNotEqual, BackColorFilter, BackColor, BackColorNotEqual, TextColorFilter, TextColor, TextColorNotEqual, 
			|FilterByIndent, Indent, FilterByValue, ValueNotEqual, Value");
			FillPropertyValues(ParametersStructure, CurData);
			ParametersStructure.Insert("CurRow", CurRow);
			Handler = New NotifyDescription("SettingsTreeChoice_End1", ThisObject, ParametersStructure);
			OpenForm("Catalog.fmLoadTemplates.Form.FiltersEditingForm",ParametersStructure, ThisForm,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	ElsIf Field.Name = "SettingsTreeEndConditions" Then
		StandardProcessing = False;
		If NOT (CurData.IsResource OR CurData.PredefinedRow OR CurData.FlatSetting) Then
			Modified = True;
			ParametersStructure = New Structure("FontCondition, SizeCondition, BoldCondition, ItalicCondition, UnderlinedCondition, ConditionByFont, 
			|FontNotEqualCondition, ConditionByBackColor, BackColorCondition, BackColorNotEqualCondition, ConditionByTextColor, TextColorCondition, TextColorNotEqualCondition, 
			|ConditionByIndent, IndentCondition, ConditionByValue, ValueNotEqualCondition, ValueCondition, RowCountValueByCondition, RowCountConditionByIndent,
			|RowCountConditionByTextColor, RowCountConditionByBackColor, RowCountConditionByFont, ReadMethod");
			FillPropertyValues(ParametersStructure, CurData);
			ParametersStructure.Insert("CurRow", CurRow);
			Handler = New NotifyDescription("SettingsTreeChoice_End2", ThisObject, ParametersStructure);
			OpenForm("Catalog.fmLoadTemplates.Form.ConditionsEditingForm",ParametersStructure, ThisForm,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	ElsIf Field.Name = "SettingsTreeBeginConditions" Then
		StandardProcessing = False;
		
		If NOT (CurData.IsResource OR CurData.PredefinedRow OR CurData.FlatSetting) Then
			Modified = True;
			ParametersStructure = New Structure("FontCondition, SizeCondition, BoldCondition, ItalicCondition, UnderlinedCondition, ConditionByFont, 
			|FontNotEqualCondition, ConditionByBackColor, BackColorCondition, BackColorNotEqualCondition, ConditionByTextColor, TextColorCondition, TextColorNotEqualCondition, 
			|ConditionByIndent, IndentCondition, ConditionByValue, ValueNotEqualCondition, ValueCondition, RowCountValueByCondition, RowCountConditionByIndent,
			|RowCountConditionByTextColor, RowCountConditionByBackColor, RowCountConditionByFont, ReadMethod, BeginConditions", CurData.FontConditionBegin, CurData.SizeConditionBegin, 
			CurData.BoldConditionBegin, CurData.ItalicConditionBegin, CurData.UnderlinedConditionBegin, CurData.ConditionBeginByFont, CurData.FontNotEqualConditionBegin,
			CurData.ConditionBeginByBackColor, CurData.BackColorConditionBegin, CurData.BackColorNotEqualConditionBegin, CurData.ConditionBeginByTextColor, CurData.TextColorConditionBegin, 
			CurData.TextColorNotEqualConditionBegin, CurData.ConditionBeginByIndent, CurData.IndentConditionBegin, CurData.ConditionBeginByValue, CurData.ValueNotEqualConditionBegin,
			CurData.ValueConditionBegin, CurData.RowCountConditionByValue, CurData.RowCountConditionBeginByIndent, CurData.RowCountConditionBeginByTextColor, 
			CurData.RowCountConditionBeginByBackColor, CurData.RowCountConditionBeginByFont, CurData.ReadMethod, True);
			
			ParametersStructure.Insert("CurRow", CurRow);
			Handler = New NotifyDescription("SettingsTreeChoice_End3", ThisObject, ParametersStructure);
			OpenForm("Catalog.fmLoadTemplates.Form.ConditionsEditingForm",ParametersStructure, ThisForm,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure  SettingsTreeChoice_End3(Result, Parameter) Export
	
	CurData = Items.SettingsTree.CurrentData;
	If NOT Result = Undefined Then
		For Each CurAttribute In Result Do
			CurData[StrReplace(CurAttribute.Key, "Condition", "ConditionBegin")] = CurAttribute.Value;
		EndDo;
		CurData.BeginConditions = GenerateConditionsText(CurData, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure  SettingsTreeChoice_End1(Result, Parameter) Export
	
	CurData = Items.SettingsTree.CurrentData;
	If NOT Result = Undefined Then
		FillPropertyValues(CurData, Result);
		CurData.FiltersSettings = GenerateFilterText(CurData);
	EndIf;
	
EndProcedure

&AtClient
Procedure  SettingsTreeChoice_End2(Result, Parameter) Export
	
	CurData = Items.SettingsTree.CurrentData;
	If NOT Result = Undefined Then
		FillPropertyValues(CurData, Result);
		CurData.EndConditions = GenerateConditionsText(CurData);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadSettingsReadingMethodOnChange(Item)
	CurRow = Items.LoadSettings.CurrentData;
	If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.FixedValue") 
	OR CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.DontRead") Then
		CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.EmptyRef");
	ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Cell") 
	AND NOT ValueIsFilled(CurRow.SynchronizationMethod) Then
		CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.ByDescription");
	EndIf;
EndProcedure




