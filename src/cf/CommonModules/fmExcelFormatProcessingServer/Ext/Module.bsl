
Procedure LoadAtServer(ObjectStructure, ParametersStructure, Template) Export
	
	Query = New Query("SELECT
	                      |	LoadTemplatesLoadSettings.ReadMethod,
	                      |	LoadTemplatesLoadSettings.SynchronizationMethod,
	                      |	LoadTemplatesLoadSettings.Attribute,
	                      |	LoadTemplatesLoadSettings.EvalCode,
	                      |	LoadTemplatesLoadSettings.FixedValue
	                      |FROM
	                      |	Catalog.fmLoadTemplates.LoadSettings AS LoadTemplatesLoadSettings
	                      |WHERE
	                      |	LoadTemplatesLoadSettings.Ref = &Template");
	Query.SetParameter("Template", Template);
	Settings = Query.Execute().Unload();
	Settings.Columns.Add("Type");
	Settings.Indexes.Add("Attribute");
	
	// Объявим основные значение XDTO.
	DB = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "DB"));
	DB.InputData = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "InputData"));
	Document = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "Document"));
	DB.InputData.Document.Add(Document);
	//Табличная часть
	BudgetsData = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "BudgetsData"));
	Document.BudgetsData = BudgetsData;
	
	// Соберем документ в пакет XDTO.
	For Each CurAttribute In ObjectStructure Do
		If TypeOf(CurAttribute.Value) = Type("Structure") Then
			// Значения табличных частей.
			If CurAttribute.Value.Rows.Count()=0 Then
				// Нет ни строк, ни колонок.
				BudgetsData.DocumentRow.Add(XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "DocumentRow")));
			Else
				For Each CurRow In CurAttribute.Value.Rows Do
					String = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "DocumentRow"));
					For Each CurColumn In CurRow.Value Do
						If CurColumn.Key="RecordType" Then
							String[CurColumn.Key] = EvaluateEnumValue("fmBudgetFlowOperationTypes", CurColumn, Settings.Find(CurColumn.Key, "Attribute"), ObjectStructure);
						Else
							FillBatchValue(String[CurColumn.Key], CurColumn.Value, Settings.Find(CurColumn.Key, "Attribute"), ObjectStructure);
						EndIf;
					EndDo;
					BudgetsData.DocumentRow.Add(String);
				EndDo;
			EndIf;
			// Заполним таблицу единичными значениями.
			For Each CurValue In CurAttribute.Value.Values Do
				Setting = Settings.Find(CurValue.Key, "Attribute");
				For Each CurRow In BudgetsData.DocumentRow Do
					If CurValue.Key="RecordType" Then
						CurRow[CurValue.Key] = EvaluateEnumValue("fmBudgetFlowOperationTypes", CurValue, Setting, ObjectStructure);
					Else
						FillBatchValue(CurRow[CurValue.Key], CurValue.Value, Setting, ObjectStructure);
					EndIf;
				EndDo;
			EndDo;
		Else
			// Значения реквизитов.
			// Проанализиурем считанные параметры для заполнения
			Setting = Settings.Find(CurAttribute.Key, "Attribute");
			If CurAttribute.Key = "OperationType" Then
				Document.OperationType = EvaluateEnumValue("fmBudgetOperationTypes", CurAttribute, Setting, ObjectStructure);
			ElsIf CurAttribute.Key = "BeginOfPeriod" Then
				// Если есть код вычисления результата, то выполним его в контексте сервера.
				Value = CurAttribute.Value;
				If ValueIsFilled(Setting.EvalCode) Then
					EvaluateExpressionValue(Value, Setting, ObjectStructure);
				EndIf;
				Document[CurAttribute.Key] = Value;
			Else
				FillBatchValue(Document[CurAttribute.Key], CurAttribute.Value, Setting, ObjectStructure);
			EndIf;
		EndIf;
	EndDo;
	
	// Загрузим через XDTO пакет считанные данные.
	fmDataLoadingServerCall.LoadBatchXDTOInBudget(DB, ParametersStructure);
	
	If ParametersStructure.Property("ErrorDescription") AND TypeOf(ParametersStructure.ErrorDescription)=Type("String") AND ValueIsFilled(ParametersStructure.ErrorDescription) Then
		CommonClientServer.MessageToUser(ParametersStructure.ErrorDescription);
	ElsIf ParametersStructure.Property("ErrorDescription") AND TypeOf(ParametersStructure.ErrorDescription)=Type("Array") Then
		For Each CurrMessage In ParametersStructure["ErrorDescription"] Do
			CommonClientServer.MessageToUser(CurrMessage);
		EndDo;
	EndIf;
	
	If ParametersStructure.Property("DocumentImportResult") AND TypeOf(ParametersStructure.DocumentImportResult)=Type("Array") Then
		For Each CurrMessage In ParametersStructure.DocumentImportResult Do
			CommonClientServer.MessageToUser(CurrMessage);
		EndDo;
	EndIf;
	
EndProcedure // ЗагрузитьНаСервере()

Function EvaluateEnumValue(EnumName, CurAttribute, Setting, ObjectStructure)
	
	If Setting.ReadMethod = Enums.fmReadMethods.FixedValue Then
		Return Metadata.Enums[EnumName].EnumValues.Get(Enums[EnumName].IndexOf(CurAttribute.Value)).Name;
	Else
		// Если есть код вычисления результата, то выполним его в контексте сервера.
		Value = CurAttribute.Value;
		If ValueIsFilled(Setting.EvalCode) Then
			EvaluateExpressionValue(Value, Setting, ObjectStructure);
		EndIf;
		For Each CurrEnum In Metadata.Enums[EnumName].EnumValues Do
			If Lower(CurrEnum.Synonym) = Lower(Value) Then
				Return CurrEnum.Name;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndFunction

Procedure EvaluateExpressionValue(Value, Setting, ObjectStructure)
	
	Attributes = ObjectStructure;
	Attributes = New Structure();
	For Each CurProperty In ObjectStructure Do
		Attributes.Insert(CurProperty.Key, CurProperty.Value);
	EndDo;
	Value = Value;
	Try
		Execute(Setting.EvalCode);
	Except
		MessageText = NStr("en='An error occurred while executing a calculation code for ""%1"" setting.';ru='При выполнении кода вычисления для настройки ""%1"" произошла ошибка! '");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Setting.Attribute);
		Raise MessageText + ErrorDescription();
	EndTry;
	If Find(Setting.EvalCode, "Value") = 0 Then
		Value = Value;
	EndIf;
	
EndProcedure

Procedure FillBatchValue(Attribute, VAL Value, Setting, Attributes) Export
	
	// Если есть код вычисления результата, то выполним его в контексте сервера.
	If ValueIsFilled(Setting.EvalCode) Then
		EvaluateExpressionValue(Value, Setting, Attributes);
	EndIf;
	
	// Пустое значение не заполняем.
	If NOT ValueIsFilled(Value) Then Return EndIf;
	
	CodeAndDescription = Undefined;
	If Setting.Attribute = "Department"
	OR Setting.Attribute = "CorDepartment"
	OR Setting.Attribute = "Item"
	OR Setting.Attribute = "CorItem"
	OR Setting.Attribute = "Currency"
	OR Setting.Attribute = "Analytics1"
	OR Setting.Attribute = "Analytics2"
	OR Setting.Attribute = "Analytics3"
	OR Setting.Attribute = "Project"
	OR Setting.Attribute = "CorProject"
	OR Setting.Attribute = "Scenario" Then
		CodeAndDescription = XDTOFactory.Create(XDTOFactory.Type("http://www.rarus.ru/ItemEng", "CodeDescription"));
		CodeAndDescription.Code = "";
		CodeAndDescription.Description = "";
		CodeAndDescription.UID = "";
	EndIf;
	
	If CodeAndDescription = Undefined Then
		Attribute = Value;
	Else
		// В зависимости от способа считывания
		If Setting.ReadMethod = Enums.fmReadMethods.FixedValue Then
			// Если фикс., тогда или код или наименование.
			If Setting.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByCode Then
				CodeAndDescription.Code = Value.Code;
				CodeAndDescription.Description = "";
			ElsIf Setting.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription Then
				CodeAndDescription.Description = Value.Description;
			Else
				CodeAndDescription.UID = String(Value.UUID());
			EndIf;
		Else
			If ValueIsFilled(Value) Then
				If Setting.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByCode Then
					CodeAndDescription.Code = Value;
					CodeAndDescription.Description = "";
				ElsIf Setting.SynchronizationMethod = Enums.fmCatalogSearchMethod.ByDescription Then
					CodeAndDescription.Code = "";
					CodeAndDescription.Description = Value;
				Else
					CodeAndDescription.UID = String(Value.UUID());
				EndIf;
			Else
				CodeAndDescription = Undefined;
			EndIf;
		EndIf;
		Attribute = CodeAndDescription;
	EndIf;
	
EndProcedure // ЗаполнитьЗначениеПакета()

Function GetTemplateParameters(Template) Export
	
	// Вернем в структуре "Лист по умолчанию" и табл. часть "Настройки загрузки".
	LoadSettings = New Array();
	ColumnsRowsSettings = New Array();
	TemplateParameters = New Structure("DefaultSheet, LoadSettings, ColumnsRowsSettings", Template.DefaultSheet, LoadSettings, ColumnsRowsSettings);
	
	// Соберем массив настроек из структур для передачи на клиента.
	Query = New Query("SELECT
	                      |	LoadTemplatesLoadSettings.ReadMethod,
	                      |	LoadTemplatesLoadSettings.RowNum,
	                      |	LoadTemplatesLoadSettings.ColumnNum,
	                      |	LoadTemplatesLoadSettings.SpanBegin,
	                      |	LoadTemplatesLoadSettings.SpanEnd,
	                      |	LoadTemplatesLoadSettings.FixedValue,
	                      |	LoadTemplatesLoadSettings.Shift,
	                      |	LoadTemplatesLoadSettings.Sheet,
	                      |	LoadTemplatesLoadSettings.TSName,
	                      |	LoadTemplatesLoadSettings.BackColor,
	                      |	LoadTemplatesLoadSettings.TextColor,
	                      |	LoadTemplatesLoadSettings.Font,
	                      |	LoadTemplatesLoadSettings.Attribute,
	                      |	LoadTemplatesLoadSettings.BackColorCondition,
	                      |	LoadTemplatesLoadSettings.TextColorFilter,
	                      |	LoadTemplatesLoadSettings.FontFilter,
	                      |	LoadTemplatesLoadSettings.ValueType,
	                      |	LoadTemplatesLoadSettings.SynchronizationMethod,
	                      |	LoadTemplatesLoadSettings.Size,
	                      |	LoadTemplatesLoadSettings.Bold,
	                      |	LoadTemplatesLoadSettings.Italic,
	                      |	LoadTemplatesLoadSettings.Underlined
	                      |FROM
	                      |	Catalog.fmLoadTemplates.LoadSettings AS LoadTemplatesLoadSettings
	                      |WHERE
	                      |	LoadTemplatesLoadSettings.Ref = &Ref
	                      |	AND (LoadTemplatesLoadSettings.ReadMethod = Value(Enum.fmReadMethods.Cell)
	                      |			OR LoadTemplatesLoadSettings.ReadMethod = Value(Enum.fmReadMethods.FixedValue))
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	LoadTemplatesLoadSettings.ReadMethod,
	                      |	LoadTemplatesLoadSettings.RowNum,
	                      |	LoadTemplatesLoadSettings.ColumnNum,
	                      |	LoadTemplatesLoadSettings.SpanBegin,
	                      |	LoadTemplatesLoadSettings.SpanEnd,
	                      |	LoadTemplatesLoadSettings.FixedValue,
	                      |	LoadTemplatesLoadSettings.Shift,
	                      |	LoadTemplatesLoadSettings.Sheet,
	                      |	LoadTemplatesLoadSettings.TSName,
	                      |	LoadTemplatesLoadSettings.ValueCondition,
	                      |	LoadTemplatesLoadSettings.BackColor,
	                      |	LoadTemplatesLoadSettings.TextColor,
	                      |	LoadTemplatesLoadSettings.Font,
	                      |	LoadTemplatesLoadSettings.Attribute,
	                      |	LoadTemplatesLoadSettings.BackColorCondition,
	                      |	LoadTemplatesLoadSettings.TextColorFilter,
	                      |	LoadTemplatesLoadSettings.FontFilter,
	                      |	LoadTemplatesLoadSettings.ValueType,
	                      |	LoadTemplatesLoadSettings.SynchronizationMethod,
	                      |	LoadTemplatesLoadSettings.Size,
	                      |	LoadTemplatesLoadSettings.Bold,
	                      |	LoadTemplatesLoadSettings.Italic,
	                      |	LoadTemplatesLoadSettings.Underlined,
	                      |	LoadTemplatesLoadSettings.RowCountValueByCondition,
	                      |	LoadTemplatesLoadSettings.LineNumber,
	                      |	LoadTemplatesLoadSettings.ConditionByValue,
	                      |	LoadTemplatesLoadSettings.BackColorNotEqual,
	                      |	LoadTemplatesLoadSettings.TextColorNotEqual,
	                      |	LoadTemplatesLoadSettings.FontNotEqual,
	                      |	LoadTemplatesLoadSettings.ResourceShiftByRow,
	                      |	LoadTemplatesLoadSettings.ResourceShiftByColumn,
	                      |	LoadTemplatesLoadSettings.ParentAttribute,
	                      |	LoadTemplatesLoadSettings.FilterByIndent,
	                      |	LoadTemplatesLoadSettings.Indent,
	                      |	LoadTemplatesLoadSettings.FilterByValue,
	                      |	LoadTemplatesLoadSettings.ValueNotEqual,
	                      |	LoadTemplatesLoadSettings.Value,
	                      |	LoadTemplatesLoadSettings.ValueNotEqualCondition,
	                      |	LoadTemplatesLoadSettings.BoldCondition,
	                      |	LoadTemplatesLoadSettings.ItalicCondition,
	                      |	LoadTemplatesLoadSettings.IndentCondition,
	                      |	LoadTemplatesLoadSettings.UnderlinedCondition,
	                      |	LoadTemplatesLoadSettings.SizeCondition,
	                      |	LoadTemplatesLoadSettings.IndentCondition,
	                      |	LoadTemplatesLoadSettings.TextColorCondition,
	                      |	LoadTemplatesLoadSettings.BackColorCondition,
	                      |	LoadTemplatesLoadSettings.ConditionByFont,
	                      |	LoadTemplatesLoadSettings.TextColorNotEqualCondition,
	                      |	LoadTemplatesLoadSettings.TextColorCondition,
	                      |	LoadTemplatesLoadSettings.BackColorNotEqualCondition,
	                      |	LoadTemplatesLoadSettings.BackColorCondition,
	                      |	LoadTemplatesLoadSettings.FontNotEqualCondition,
	                      |	LoadTemplatesLoadSettings.FontCondition,
	                      |	LoadTemplatesLoadSettings.RowCountConditionByIndent,
	                      |	LoadTemplatesLoadSettings.RowCountConditionByTextColor,
	                      |	LoadTemplatesLoadSettings.RowCountConditionByBackColor,
	                      |	LoadTemplatesLoadSettings.RowCountConditionByFont,
	                      |	LoadTemplatesLoadSettings.ValueConditionBegin,
	                      |	LoadTemplatesLoadSettings.RowCountConditionByValue,
	                      |	LoadTemplatesLoadSettings.ConditionBeginByValue,
	                      |	LoadTemplatesLoadSettings.ValueNotEqualConditionBegin,
	                      |	LoadTemplatesLoadSettings.BoldConditionBegin,
	                      |	LoadTemplatesLoadSettings.ItalicConditionBegin,
	                      |	LoadTemplatesLoadSettings.IndentConditionBegin,
	                      |	LoadTemplatesLoadSettings.UnderlinedConditionBegin,
	                      |	LoadTemplatesLoadSettings.SizeConditionBegin,
	                      |	LoadTemplatesLoadSettings.IndentConditionBegin,
	                      |	LoadTemplatesLoadSettings.ConditionBeginByTextColor,
	                      |	LoadTemplatesLoadSettings.ConditionBeginByBackColor,
	                      |	LoadTemplatesLoadSettings.ConditionBeginByFont,
	                      |	LoadTemplatesLoadSettings.TextColorNotEqualConditionBegin,
	                      |	LoadTemplatesLoadSettings.TextColorConditionBegin,
	                      |	LoadTemplatesLoadSettings.BackColorNotEqualConditionBegin,
	                      |	LoadTemplatesLoadSettings.BackColorConditionBegin,
	                      |	LoadTemplatesLoadSettings.FontNotEqualConditionBegin,
	                      |	LoadTemplatesLoadSettings.FontConditionBegin,
	                      |	LoadTemplatesLoadSettings.RowCountConditionBeginByIndent,
	                      |	LoadTemplatesLoadSettings.RowCountConditionBeginByTextColor,
	                      |	LoadTemplatesLoadSettings.RowCountConditionBeginByBackColor,
	                      |	LoadTemplatesLoadSettings.RowCountConditionBeginByFont
	                      |FROM
	                      |	Catalog.fmLoadTemplates.LoadSettings AS LoadTemplatesLoadSettings
	                      |WHERE
	                      |	LoadTemplatesLoadSettings.Ref = &Ref
	                      |	AND (LoadTemplatesLoadSettings.ReadMethod = Value(Enum.fmReadMethods.Column)
	                      |			OR LoadTemplatesLoadSettings.ReadMethod = Value(Enum.fmReadMethods.Row)
	                      |			OR LoadTemplatesLoadSettings.ReadMethod = Value(Enum.fmReadMethods.Resource))");
	Query.SetParameter("Ref", Template);
	Result = Query.ExecuteBatch();
	// Настройки для единичных значений.
	VTLoadingSettingTemplate = Result[0].Unload();
	For Each CurRow In VTLoadingSettingTemplate Do
		SettingsRow = New Structure("ReadMethod, RowNum, ColumnNum, SpanBegin, SpanEnd, FixedValue,
		|Shift, Sheet, TSName, ReadingEnd, ColumnRowOfReadingEnd, BackColor, TextColor, Font, Size, Bold, Italic, Underlined, 
		|Attribute, BackColorCondition, TextColorFilter, FontFilter, MetadataName, SynchronizationMethod");
		FillPropertyValues(SettingsRow, CurRow);
		Try
			SettingsRow.MetadataName = Metadata.FindByType(CurRow.ValueType.Get().Types()[0]).Name;
		Except
		EndTry;
		LoadSettings.Add(SettingsRow);
	EndDo;
	// Настройки для строк, колонок и ресурсов.
	VTSettingsOfRowsColumns = Result[1].Unload();
	LineNumber=0;
	For Each CurRow In VTSettingsOfRowsColumns Do
		SettingsRow = New Structure("ReadMethod, RowNum, ColumnNum, SpanBegin, SpanEnd, FixedValue,
		|Shift, Sheet, TSName, ValueCondition, ConditionByValue, RowCountValueByCondition, BackColor, TextColor, Font, 
		|Size, Bold, Italic, Underlined, Attribute, BackColorCondition, TextColorFilter, FontFilter, MetadataName, SynchronizationMethod, 
		|LineNumber, BackColorNotEqual, TextColorNotEqual, FontNotEqual, ResourceShiftByRow, ResourceShiftByColumn, ParentAttribute, 
		|FilterByIndent, Indent, FilterByValue, ValueNotEqual, Value, ValueNotEqualCondition, BoldCondition, ItalicCondition, IndentCondition,
		|UnderlinedCondition, SizeCondition, IndentCondition, TextColorCondition, BackColorCondition, ConditionByFont, TextColorNotEqualCondition,
		|TextColorCondition, BackColorNotEqualCondition, BackColorCondition, FontNotEqualCondition, FontCondition, RowCountConditionByIndent, RowCountConditionByTextColor,
		|RowCountConditionByBackColor, RowCountConditionByFont, ValueConditionBegin, RowCountConditionByValue, ConditionBeginByValue, 
		|ValueNotEqualConditionBegin, BoldConditionBegin, ItalicConditionBegin, IndentConditionBegin, UnderlinedConditionBegin, SizeConditionBegin,
		|IndentConditionBegin, ConditionBeginByTextColor, ConditionBeginByBackColor, FontConditionBegin, TextColorNotEqualConditionBegin, 
		|TextColorConditionBegin, BackColorNotEqualConditionBegin, BackColorConditionBegin, FontNotEqualConditionBegin, ConditionBeginByFont,
		|RowCountConditionBeginByIndent, RowCountConditionBeginByTextColor, RowCountConditionBeginByBackColor, RowCountConditionBeginByFont");
		FillPropertyValues(SettingsRow, CurRow);
		SettingsRow.LineNumber = LineNumber;
		Try
			SettingsRow.MetadataName = Metadata.FindByType(CurRow.ValueType.Get().Types()[0]).Name;
		Except
		EndTry;
		ColumnsRowsSettings.Add(SettingsRow);
		LineNumber=LineNumber+1;
	EndDo;
	
	Return TemplateParameters;
	
EndFunction // ПолучитьПараметрыШаблона()









