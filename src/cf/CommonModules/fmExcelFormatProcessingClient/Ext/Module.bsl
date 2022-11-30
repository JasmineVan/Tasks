
Procedure CloseExcel(AppExcel) Export
	
	Try
		AppExcel.Workbooks.Close();
		AppExcel.Quit();
	Except
		CommonClientServer.MessageToUser(ErrorDescription());
	EndTry;
	AppExcel = Undefined;
	
EndProcedure // ЗакрытьЭксель()

Function GetSheetNumberByName(SheetName, ExcelFile) Export
	
	// Найдем номер листа по имени.
	SheetCount = ExcelFile.Sheets.Count;
	For Num=1 To SheetCount Do
		If ExcelFile.Sheets(Num).Name = SheetName Then
			Return Num;
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

Function AddValue(Value, CurRow, String=Undefined, ObjectStructure)
	
	If ValueIsFilled(CurRow.TSName) AND NOT ObjectStructure.Property(CurRow.TSName) Then
		// Это значение для таблицы, которая еще не обрабатывалась. Таблица хранится в формате структуры из:
		// 1 - единичные значения для всех строк колонки
		// 2 - все считанные значения по методу "Строка"
		// 3 - все считанные значения по методу "Колонка"
		TableStructure = New Structure("Values, Rows", New Structure(), New ValueList());
		ObjectStructure.Insert(CurRow.TSName, TableStructure);
	EndIf;
	
	// В зависимости от способа считывания.
	If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Cell") 
	OR CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.FixedValue") Then
		If ValueIsFilled(CurRow.TSName) Then
			// Значение для таблицы.
			ObjectStructure[CurRow.TSName].Values.Insert(CurRow.Attribute, Value);
		Else
			// Значение для реквизита.
			ObjectStructure.Insert(CurRow.Attribute, Value);
		EndIf;
	Else
		If String=Undefined Then
			// Еще ничего не добавляли.
			Return ObjectStructure[CurRow.TSName].Rows.Add(New Structure(CurRow.Attribute, Value));
		ElsIf NOT String.Value.Property(CurRow.Attribute) Then
			// Такого реквизита еще не добавляли.
			String.Value.Insert(CurRow.Attribute, Value);
			Return String;
		Else
			// Такой реквизит уже есть, поэтому все что до него копируем и вставляем новый реквизит.
			СтруктураСтрока = New Structure();
			For Each CurProperty In String.Value Do
				If CurProperty.Key = CurRow.Attribute Then Break; EndIf;
				СтруктураСтрока.Insert(CurProperty.Key, CurProperty.Value);
			EndDo;
			СтруктураСтрока.Insert(CurRow.Attribute, Value);
			Return ObjectStructure[CurRow.TSName].Rows.Add(СтруктураСтрока);
		EndIf;
	EndIf;
	
EndFunction // ДобавитьЗначение()

Function LoadExcelFile(File, DefaultSheet, LoadTemplate, Attributes, UpdateExistingDocuments) Export
	
	// Доступ из 1С к Excel производится посредством OLE.
	Try
		AppExcel = New COMObject("Excel.Application");
	Except
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Excel error! MS Excel is not installed or it might be damaged.  %1';ru='Ошибка при работе с Excel! Возможно он не установлен или поврежден. %1'"), ErrorDescription())); 
		Return False;
	EndTry;
	
	// Проверим существование указанного файла.
	FoundFiles = FindFiles(File);
	If FoundFiles.Count()=0 Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='File %1 does not exist.';ru='Файл %1 не существует!'"), File)); 
		Return False;
	EndIf;
	// Откроем файл.
	Try
		ExcelFile = AppExcel.WorkBooks.Open(File);
	Except
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to open file %1! %2';ru='Не удалось открыть файл %1! %2'"), File, ErrorDescription())); 
		fmExcelFormatProcessingClient.CloseExcel(AppExcel);
		Return False;
	EndTry;
	
	// Получим параметры шаблона.
	TemplateParameters = fmExcelFormatProcessingServer.GetTemplateParameters(LoadTemplate);
	ColumnsRowsSettings = TemplateParameters.ColumnsRowsSettings;
	
	SheetNumber = GetSheetNumberByName(DefaultSheet, ExcelFile);
	If SheetNumber=0 Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Sheet ""%1"" is not found!';ru='Лист ""%1"" не обнаружен!'"), DefaultSheet));
		fmExcelFormatProcessingClient.CloseExcel(AppExcel);
		Return False;
	EndIf;
	
	// Получим основной лист для считывания.
	Sheet = ExcelFile.WorkSheets(SheetNumber);
	
	// Соберем все загружаемые данные в структуру для загрузки на сервере.
	ObjectStructure = New Structure();
	
	// Соберем необходимые дополнительные параметры для загрузки данных через XDTO пакет.
	ParametersStructure = New Structure("UpdateExistingCatalogs, UpdateExistingDocuments", False, UpdateExistingDocuments);
	
	// Пойдем по настройкам загрузки единичных значений.
	For Each CurRow In TemplateParameters.LoadSettings Do
		// Все зависит от способа считывания или наличия переданного реквизита.
		FixValue = Attributes.FindRows(New Structure("Attribute", CurRow.Attribute));
		If FixValue.Count()=0 Then
			// Для ячейки лист считывания может быть переопределен.
			If CurRow.Sheet = TemplateParameters.DefaultSheet Then
				CellSheet = Sheet;
			Else
				CellSheetNumber = GetSheetNumberByName(CurRow.Sheet, ExcelFile);
				If CellSheetNumber=0 Then
					CommonClientServer.MessageToUser(StrTemplate(NStr("en='Sheet ""%1"" is not found!';ru='Лист ""%1"" не обнаружен!'"), CurRow.Sheet));
					fmExcelFormatProcessingClient.CloseExcel(AppExcel);
					Return False;
				EndIf;
				CellSheet = ExcelFile.WorkSheets(CellSheetNumber);
			EndIf;
			AddValue(CellSheet.Cells(CurRow.RowNum, ConvertColumnNumber(CurRow.ColumnNum, Sheet)).Value, CurRow, , ObjectStructure);
		Else
			AddValue(FixValue[0].Value, CurRow, , ObjectStructure);
		EndIf;
		// Сохраним параметр синхронизации для справочников.
		If ValueIsFilled(CurRow.MetadataName) 
		AND (CurRow.Attribute = "Item" OR CurRow.Attribute = "CorItem"
		OR CurRow.Attribute = "Department" OR CurRow.Attribute = "CorDepartment"
		OR CurRow.Attribute = "Analytics1" OR CurRow.Attribute = "Analytics2" OR CurRow.Attribute = "Analytics3"
		OR CurRow.Attribute = "Currency" OR CurRow.Attribute = "Scenario"
		OR CurRow.Attribute = "Project" OR CurRow.Attribute = "CorProject") Then
			If CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.ByCode") Then
				ParametersStructure.Insert(CurRow.Attribute, "ByCode");
			ElsIf CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.ByDescription") Then
				ParametersStructure.Insert(CurRow.Attribute, "ByDescription");
			Else
				ParametersStructure.Insert(CurRow.Attribute, "ByRef");
			EndIf;
		EndIf;
	EndDo;
	
	// Сохраним параметр синхронизации для справочников из настроек дерева.
	For Each CurRow In TemplateParameters.ColumnsRowsSettings Do
		If ValueIsFilled(CurRow.MetadataName) 
		AND (CurRow.Attribute = "Item" OR CurRow.Attribute = "CorItem"
		OR CurRow.Attribute = "Department" OR CurRow.Attribute = "CorDepartment"
		OR CurRow.Attribute = "Analytics1" OR CurRow.Attribute = "Analytics2" OR CurRow.Attribute = "Analytics3"
		OR CurRow.Attribute = "Currency"
		OR CurRow.Attribute = "Project" OR CurRow.Attribute = "CorProject") Then
			If CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.ByCode") Then
				ParametersStructure.Insert(CurRow.Attribute, "ByCode");
			ElsIf CurRow.SynchronizationMethod = PredefinedValue("Enum.fmCatalogSearchMethod.ByDescription") Then
				ParametersStructure.Insert(CurRow.Attribute, "ByDescription");
			Else
				ParametersStructure.Insert(CurRow.Attribute, "ByRef");
			EndIf;
		EndIf;
	EndDo;
	
	// Считаем строки и колонки.
	If ColumnsRowsSettings.Count()>0 Then
		ReadRowColumns(ColumnsRowsSettings[0], Sheet, ColumnsRowsSettings, ObjectStructure);
	EndIf;
	
	// Закроем ексель.
	fmExcelFormatProcessingClient.CloseExcel(AppExcel);
		
	// Загрузим прочитанные данные на сервере, если есть считанные данные.
	If ObjectStructure.Property("BudgetsData") Then
		fmExcelFormatProcessingServer.LoadAtServer(ObjectStructure, ParametersStructure, LoadTemplate);
	Else
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='While reading file ""%1"", sheet ""%2"" by template ""%3"", data was not found!';ru='При считывании файла ""%1"" на листе ""%2"" шаблоном ""%3"" не были обнаружены данные!'"), File, DefaultSheet, TrimAll(LoadTemplate)));
		Return False;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

Function ConvertColumnNumber(ColumnNum, Sheet) Export
	Try
		Return Number(ColumnNum);
	Except
		Try
			Return Sheet.Cells(1, ColumnNum).Column;
		Except
			Raise(StrTemplate(NStr("en='Failed to transform column value ""%1"" to the number.';ru='Не удалось преобразовать значение колонки ""%1"" в число!'"), ColumnNum));
		EndTry;
	EndTry;
EndFunction // ПреобразоватьНомерКолонки()

Procedure ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, CurRowColumn, PreviousAttribute) Export
	
	// Рекурсинвый вызов для след. настройки или обработка ресурсов.
	If CurRow.LineNumber+1 < ColumnsRowsSettings.Count() Then
		NextCurRow = ColumnsRowsSettings[CurRow.LineNumber+1];
		If NextCurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Resource") Then
			// Пошли ресурсы, по ним цикл и конец, так как далее ничего не должно быть.
			CurRowRowNumber = CurRow.LineNumber;
			While CurRowRowNumber+1 < ColumnsRowsSettings.Count() Do
				// Получим еще раз для удобства написания цикла.
				NextCurRow = ColumnsRowsSettings[CurRowRowNumber+1];
				AddValue(Sheet.Cells(NumberForResource+NextCurRow.ResourceShiftByColumn, CurRowColumn+NextCurRow.ResourceShiftByRow).Value, NextCurRow, VTRow, ObjectStructure);
				CurRowRowNumber = CurRowRowNumber + 1;
			EndDo;
		Else
			If CurRow.ReadMethod=NextCurRow.ReadMethod AND CurRow.ParentAttribute<>NextCurRow.ParentAttribute Then
				ReadRowColumns(NextCurRow, Sheet, ColumnsRowsSettings, ObjectStructure, VTRow, CurRowColumn+CurRow.Shift, , True, PreviousAttribute);
			ElsIf CurRow.ReadMethod=NextCurRow.ReadMethod AND CurRow.ParentAttribute=NextCurRow.ParentAttribute Then
				// Пошли "плоские" считывания, по ним цикл до изменения способа считывания.
				CurRowRowNumber = CurRow.LineNumber;
				While CurRowRowNumber+1 < ColumnsRowsSettings.Count() AND CurRow.ReadMethod=NextCurRow.ReadMethod Do
					// Получим еще раз для удобства написания цикла.
					If NextCurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
						ColumnNumber = ConvertColumnNumber(NextCurRow.ColumnNum, Sheet);
						LineNumber = CurRowColumn;
					Else
						ColumnNumber = CurRowColumn;
						LineNumber = NextCurRow.RowNum;
					EndIf;
					AddValue(Sheet.Cells(LineNumber, ColumnNumber).Value, NextCurRow, VTRow, ObjectStructure);
					CurRowRowNumber = CurRowRowNumber + 1;
					Try
						NextCurRow = ColumnsRowsSettings[CurRowRowNumber+1];
					Except
					EndTry;
				EndDo;
				// Далее может следовать чтение колонок или ресурсов.
				If CurRowRowNumber+1 < ColumnsRowsSettings.Count() Then
					NextCurRow = ColumnsRowsSettings[CurRowRowNumber+1];
					If NextCurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Column") Then
						ReadRowColumns(NextCurRow, Sheet, ColumnsRowsSettings, ObjectStructure, VTRow, , CurRowColumn, True, PreviousAttribute);
					Else
						// Пошли ресурсы, по ним цикл и конец, так как далее ничего не должно быть.
						While CurRowRowNumber+1 < ColumnsRowsSettings.Count() Do
							// Получим еще раз для удобства написания цикла.
							NextCurRow = ColumnsRowsSettings[CurRowRowNumber+1];
							AddValue(Sheet.Cells(NumberForResource+NextCurRow.ResourceShiftByColumn, CurRowColumn+NextCurRow.ResourceShiftByRow).Value, NextCurRow, VTRow, ObjectStructure);
							CurRowRowNumber = CurRowRowNumber + 1;
						EndDo;
					EndIf;
				EndIf;
			Else
				ReadRowColumns(NextCurRow, Sheet, ColumnsRowsSettings, ObjectStructure, VTRow, , CurRowColumn, True, PreviousAttribute);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function FontsAreEqual(ExcelFont, OneCFont, EndFont=False) Export
	
	If EndFont Then
		// Название шрифта.
		If ValueIsFilled(OneCFont.FontCondition) AND NOT ExcelFont.Name = OneCFont.FontCondition Then
			Return False;
		EndIf;
		// Размер шрифта.
		If ValueIsFilled(OneCFont.SizeCondition) AND NOT ExcelFont.Size = OneCFont.SizeCondition Then
			Return False;
		EndIf;
		// Жирный шрифт.
		If NOT ExcelFont.Bold = OneCFont.BoldCondition Then
			Return False;
		EndIf;
		// Наклонный шрифт.
		If NOT ExcelFont.Italic = OneCFont.ItalicCondition Then
			Return False;
		EndIf;
		// Подчеркнутый шрифт.
		If OneCFont.UnderlinedCondition AND NOT ExcelFont.Underline=2 Then
			Return False;
		EndIf;
		Return True;
	Else
		// Название шрифта.
		If ValueIsFilled(OneCFont.Font) AND NOT ExcelFont.Name = OneCFont.Font Then
			Return False;
		EndIf;
		// Размер шрифта.
		If ValueIsFilled(OneCFont.Size) AND NOT ExcelFont.Size = OneCFont.Size Then
			Return False;
		EndIf;
		// Жирный шрифт.
		If NOT ExcelFont.Bold = OneCFont.Bold Then
			Return False;
		EndIf;
		// Наклонный шрифт.
		If NOT ExcelFont.Italic = OneCFont.Italic Then
			Return False;
		EndIf;
		// Подчеркнутый шрифт.
		If OneCFont.Underlined AND NOT ExcelFont.Underline=2 Then
			Return False;
		EndIf;
		Return True;
	EndIf;

EndFunction // ШрифтыРавны()

Procedure ReadRowColumns(CurRow, Sheet, ColumnsRowsSettings, ObjectStructure, VTRow=Undefined, VAL CurRowColumn=Undefined, NumberForResource=Undefined, IsRecursion=False, VAL PreviousAttribute="") Export
	
	// Сделаем расчет строк и колонок в зависимости от способа считывания.
	If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
		If CurRowColumn=Undefined Then
			Column = ConvertColumnNumber(CurRow.SpanBegin, Sheet);
		Else
			Column = CurRowColumn;
		EndIf;
		String = CurRow.RowNum;
	ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
		If CurRowColumn=Undefined Then
			String = ConvertColumnNumber(CurRow.SpanBegin, Sheet);
		Else
			String = CurRowColumn;
		EndIf;
		Column = ConvertColumnNumber(CurRow.ColumnNum, Sheet);
	EndIf;
	
	// Бесконечный рекурсивный цикл, выход рассчитывается внутри.
	LoopCounter=0;
	ReadingHasStarted = False;
	While True Do
		
		// Проверка бесконечного зацикливания.
		If LoopCounter>100000 Then
			Raise StrTemplate(NStr("en='An infinite loop of reading is found according to setting ""%1"".';ru='Обнаружен бесконечный цикл считывания по настройке ""%1""!'"), CurRow.Attribute);
		EndIf;
		LoopCounter=LoopCounter+1;
		
		// Получаем текущую ячейку.
		CurCell = Sheet.Cells(String, Column);
		
		// БЛОК АНАЛИЗА УСЛОВИЙ НАЧАЛА СЧИТЫВАНИЯ
		If CurRow.ConditionBeginByValue AND NOT ReadingHasStarted Then
			CurCellValue = CurCell.Value;
			If ValueIsFilled(CurRow.RowCountConditionByValue) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionByValue, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellValue = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Value;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellValue = Sheet.Cells(String, CurRowColumnsReadingEndRow).Value;
				EndIf;
			EndIf;
			If NOT CurRow.ValueConditionBegin = CurCellValue Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Условие по отступу.
		If CurRow.IndentConditionBegin AND NOT ReadingHasStarted Then
			CurCellIndent = CurCell.IndentLevel;
			If ValueIsFilled(CurRow.RowCountConditionBeginByIndent) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionBeginByIndent, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellIndent = Sheet.Cells(CurRowColumnsReadingEndRow, Column).IndentLevel;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellIndent = Sheet.Cells(String, CurRowColumnsReadingEndRow).IndentLevel;
				EndIf;
			EndIf;
			If NOT CurRow.IndentConditionBegin = CurCellIndent Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем условие по цвету текста ячейки при необходимости.
		If CurRow.ConditionBeginByTextColor AND NOT ReadingHasStarted Then
			CurCellColor = CurCell.Font.Color;
			If ValueIsFilled(CurRow.RowCountConditionBeginByTextColor) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionBeginByTextColor, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellColor = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Font.Color;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellColor = Sheet.Cells(String, CurRowColumnsReadingEndRow).Font.Color;
				EndIf;
			EndIf;
			ColorsAreEqual = CurCellColor=CurRow.TextColorConditionBegin;
			If (ColorsAreEqual AND CurRow.TextColorNotEqualConditionBegin) OR (NOT ColorsAreEqual AND NOT CurRow.TextColorNotEqualConditionBegin) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем условие ячейки при необходимости по цвету фона.
		If CurRow.ConditionBeginByBackColor AND NOT ReadingHasStarted Then
			CurCellBackColor = CurCell.Interior.Color;
			If ValueIsFilled(CurRow.RowCountConditionBeginByBackColor) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionBeginByBackColor, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellBackColor = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Interior.Color;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellBackColor = Sheet.Cells(String, CurRowColumnsReadingEndRow).Interior.Color;
				EndIf;
			EndIf;
			ColorsAreEqual = CurCellBackColor=CurRow.BackColorConditionBegin;
			If (ColorsAreEqual AND CurRow.BackColorNotEqualConditionBegin) OR (NOT ColorsAreEqual AND NOT CurRow.BackColorNotEqualConditionBegin) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем условие шрифта текста ячейки при необходимости.
		If CurRow.ConditionBeginByFont AND NOT ReadingHasStarted Then
			CurCellBackFont = CurCell.Font;
			If ValueIsFilled(CurRow.RowCountConditionBeginByFont) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionBeginByFont, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellBackFont = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Font;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellBackFont = Sheet.Cells(String, CurRowColumnsReadingEndRow).Font;
				EndIf;
			EndIf;
			FontsAreEqual = FontsAreEqual(CurCellBackFont, CurRow, True);
			If (FontsAreEqual AND CurRow.FontNotEqualConditionBegin) OR (NOT FontsAreEqual AND NOT CurRow.FontNotEqualConditionBegin) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		ReadingHasStarted = True;
		
		// БЛОК АНАЛИЗА УСЛОВИЙ ОКОНЧАНИЯ СЧИТЫВАНИЯ
		// Если указан конец диапозона и вышли за его пределы, то конец считывания.
		ColumnRow = ?(CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column"), Column, String);
		If ValueIsFilled(CurRow.SpanEnd) AND ColumnRow > ConvertColumnNumber(CurRow.SpanEnd, Sheet) Then
			If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
				ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
			EndIf;
			Break;
		EndIf;
		// Если указано значения конца считывания диапозона, то возможно конец считывания.
		If CurRow.ConditionByValue Then
			CurCellValue = CurCell.Value;
			If ValueIsFilled(CurRow.RowCountValueByCondition) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountValueByCondition, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellValue = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Value;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellValue = Sheet.Cells(String, CurRowColumnsReadingEndRow).Value;
				EndIf;
			EndIf;
			If CurRow.ValueCondition = CurCellValue Then
				If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
					ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
				EndIf;
				Break;
			EndIf;
		EndIf;
		// Условие по отступу.
		If CurRow.IndentCondition Then
			CurCellIndent = CurCell.IndentLevel;
			If ValueIsFilled(CurRow.RowCountConditionByIndent) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionByIndent, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellIndent = Sheet.Cells(CurRowColumnsReadingEndRow, Column).IndentLevel;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellIndent = Sheet.Cells(String, CurRowColumnsReadingEndRow).IndentLevel;
				EndIf;
			EndIf;
			If CurRow.IndentCondition = CurCellIndent Then
				If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
					ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
				EndIf;
				Break;
			EndIf;
		EndIf;
		// Проанализируем условие по цвету текста ячейки при необходимости.
		If CurRow.TextColorCondition Then
			CurCellColor = CurCell.Font.Color;
			If ValueIsFilled(CurRow.RowCountConditionByTextColor) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionByTextColor, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellColor = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Font.Color;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellColor = Sheet.Cells(String, CurRowColumnsReadingEndRow).Font.Color;
				EndIf;
			EndIf;
			ColorsAreEqual = CurCellColor=CurRow.TextColorCondition;
			If (ColorsAreEqual AND NOT CurRow.TextColorNotEqualCondition) OR (NOT ColorsAreEqual AND CurRow.TextColorNotEqualCondition) Then
				If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
					ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
				EndIf;
				Break;
			EndIf;
		EndIf;
		// Проанализируем условие ячейки при необходимости по цвету фона.
		If CurRow.BackColorCondition Then
			CurCellBackColor = CurCell.Interior.Color;
			If ValueIsFilled(CurRow.RowCountConditionByBackColor) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionByBackColor, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellBackColor = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Interior.Color;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellBackColor = Sheet.Cells(String, CurRowColumnsReadingEndRow).Interior.Color;
				EndIf;
			EndIf;
			ColorsAreEqual = CurCellBackColor=CurRow.BackColorCondition;
			If (ColorsAreEqual AND NOT CurRow.BackColorNotEqualCondition) OR (NOT ColorsAreEqual AND CurRow.BackColorNotEqualCondition) Then
				If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
					ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
				EndIf;
				Break;
			EndIf;
		EndIf;
		// Проанализируем условие шрифта текста ячейки при необходимости.
		If CurRow.ConditionByFont Then
			CurCellBackFont = CurCell.Font;
			If ValueIsFilled(CurRow.RowCountConditionByFont) Then
				CurRowColumnsReadingEndRow = ConvertColumnNumber(CurRow.RowCountConditionByFont, Sheet);
				If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
					CurCellBackFont = Sheet.Cells(CurRowColumnsReadingEndRow, Column).Font;
				ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
					CurCellBackFont = Sheet.Cells(String, CurRowColumnsReadingEndRow).Font;
				EndIf;
			EndIf;
			FontsAreEqual = FontsAreEqual(CurCellBackFont, CurRow, True);
			If (FontsAreEqual AND NOT CurRow.FontNotEqualCondition) OR (NOT FontsAreEqual AND CurRow.FontNotEqualCondition) Then
				If NOT CurRow.Attribute=PreviousAttribute AND ValueIsFilled(PreviousAttribute) AND CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
					ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column), PreviousAttribute);
				EndIf;
				Break;
			EndIf;
		EndIf;
		
		// БЛОК АНАЛИЗА ОТБОРОВ.
		// Проанализируем ячейку при необходимости по цвету фона.
		If CurRow.BackColorCondition Then
			ColorsAreEqual = CurCell.Interior.Color=CurRow.BackColor;
			If (ColorsAreEqual AND CurRow.BackColorNotEqual) OR (NOT ColorsAreEqual AND NOT CurRow.BackColorNotEqual) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем цвет текста ячейки при необходимости.
		If CurRow.TextColorFilter Then
			ColorsAreEqual = CurCell.Font.Color=CurRow.TextColor;
			If (ColorsAreEqual AND CurRow.TextColorNotEqual) OR (NOT ColorsAreEqual AND NOT CurRow.TextColorNotEqual) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем шрифт текста ячейки при необходимости.
		If CurRow.FontFilter Then
			FontsAreEqual = FontsAreEqual(CurCell.Font, CurRow);
			If (FontsAreEqual AND CurRow.FontNotEqual) OR (NOT FontsAreEqual AND NOT CurRow.FontNotEqual) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		// Проанализируем отступ ячейки при необходимости.
		If CurRow.FilterByIndent AND NOT CurCell.IndentLevel = CurRow.Indent Then
			ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
			Continue;
		EndIf;
		// Проанализируем значение ячейки при необходимости.
		If CurRow.FilterByValue Then
			If (CurCell.Value = CurRow.Value AND CurRow.ValueNotEqual)
			OR (NOT CurCell.Value = CurRow.Value AND NOT CurRow.ValueNotEqual) Then
				ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True);
				Continue;
			EndIf;
		EndIf;
		
		// Если дошли сюда, значит можно читать значение.
		VTRow = AddValue(CurCell.Value, CurRow, VTRow, ObjectStructure);
		// Сохраним 
		If CurRow.ReadMethod=PredefinedValue("Enum.fmReadMethods.Row") Then
			PreviousAttribute=CurRow.Attribute;
		EndIf;
		
		// Рекурсинвый вызов для след. настройки или обработка ресурсов.
		ReadSetting(CurRow, ObjectStructure, ColumnsRowsSettings, VTRow, Sheet, NumberForResource, ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, True), PreviousAttribute);
		
		// Совсем новая строка может появится только при прохождении цикла первого вызова (то есть нерекурсивного).
		If NOT IsRecursion Then VTRow = Undefined; EndIf;
		
	EndDo;
	
EndProcedure // ПрочитатьКолонкиСтроки()

Function ShiftColumnRow(CurRow, ColumnsRowsSettings, String, Column, Shift=False) Export
	// Сдвигаем колонку/строку для следующей итерации.
	If CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Column") Then
		CurRowColumn = Column;
		If Shift Then
			Column = Column + CurRow.Shift;
		ElsIf ValueIsFilled(CurRow.ParentAttribute) Then
			For Each CurR In ColumnsRowsSettings Do
				If CurR.Attribute=CurRow.ParentAttribute Then
					Column = Column - CurR.Shift;
					Return Column;
				EndIf;
			EndDo;
		EndIf;
	ElsIf CurRow.ReadMethod = PredefinedValue("Enum.fmReadMethods.Row") Then
		CurRowColumn = String;
		If Shift Then
			String = String + CurRow.Shift;
		ElsIf ValueIsFilled(CurRow.ParentAttribute) Then
			For Each CurR In ColumnsRowsSettings Do
				If CurR.Attribute=CurRow.ParentAttribute Then
					String = String - CurR.Shift;
					Return String;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return CurRowColumn;
EndFunction // СчитатьНастройку()






