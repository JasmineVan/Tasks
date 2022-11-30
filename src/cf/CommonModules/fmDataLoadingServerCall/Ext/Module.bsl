
////////////////////////////////////////////////////////////////////////////////
//ОБЩИЕ

//Функция возвращает массив объектов XDTO из пакета
//
Function GetIterationCollection(ObjectXDTO)
	
	If TypeOf(ObjectXDTO) = Type("XDTODataObject") Then
		Collection = New Array;
		Collection.Add(ObjectXDTO);
		Return Collection;
	ElsIf TypeOf(ObjectXDTO) = Type("XDTOList") Then
		Return ObjectXDTO;
	Else
		Return Undefined
	EndIf;
	
EndFunction

//Функция ищет справочник по наименованию
//
Function FindCatalogByDescriptionWithoutParent(Description, Manager, IsFolder, ParametersStructure)
	
	Query = New Query;
	Query.Text = "SELECT
	|	"+Manager+".Ref
	|FROM
	|	Catalog."+Manager+" AS "+Manager+"
	|WHERE
	|	"+Manager+".Description = &Description
	|	"+?(Metadata.Catalogs[Manager].Hierarchical AND Metadata.Catalogs[Manager].HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems," AND "+Manager+".IsFolder = &IsFolder" ,"")+"
	|	";
	Query.SetParameter("IsFolder", IsFolder);
	Query.SetParameter("Description", Description);
	Selection = Query.Execute().SELECT();
	If Selection.Count()>1 Then
		AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='More than one catalog item ""%1"" is found with name <%2>.';ru='Обнаружено более одного элемента справочника ""%1"" с наименованием <%2>.'"), Manager,  Description));
		Return Catalogs[Manager].EmptyRef();
	EndIf;
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs[Manager].EmptyRef();
	EndIf;
	
EndFunction

Function GetProperty(Object, PropertyName)
	Try
		Return Object[PropertyName];
	Except
		Return Undefined;
	EndTry;
EndFunction

Function GetNumber(NumberPresentation)
	Try
		Return Number(NumberPresentation);
	Except
		Return 0;
	EndTry;
EndFunction // ПолучитьЧисло()

Function GetBoolean(BooleanPresentation)
	Return BooleanPresentation="true";
EndFunction

////////////////////////////////////////////////////////////////////////////////
//Загрузка в Бюджет

// Функция является точкой входа для создания/обновления загружаемых документов уфБюджет
// Входящие данные:
// -Пакет XDTO ФорматЗагрузкиСведенийОДиР подготовленный согласно его структуре
// Возвращаемое значение:
// -Булево (Истина загрузка прошла успешно). (Ложь с ошибкой Дополнительно в структуре параметров в случае ошибки дабавляется поле "ОписаниеОшибки")
Function LoadBatchXDTOInBudget(Batch, ParametersStructure) Export
	
	//ПРОВЕРКИ
	Try //Проверить пакет на соответствие схеме XDTO
		Batch.Validate();
	Except
		AddErrorDescription(ParametersStructure, ErrorDescription());
		Return False;
	EndTry;
	
	//Здесь будем хранить результат загрузки каждого документа
	ParametersStructure.Insert("DocumentImportResult", New Array);
	//Здесь будем хранить ссылки на успешно проведённые документы
	ParametersStructure.Insert("SuccessfullyLoadedDocuments", New Array);
	
	Try //ПОПЫТКА
		//Загрузка в документ ВводСведенийОДоходахИРасходах если в пакете
		If Batch.InputData <> Undefined Then
			CollectionXDTO_Documents = GetIterationCollection(Batch.InputData.Document);
			For Each objXDTO_Document In CollectionXDTO_Documents Do
				LoadBudget(objXDTO_Document, ParametersStructure);
			EndDo;
		EndIf;
	Except
		ParametersStructure.Insert("ErrorDescription", ErrorDescription());
	EndTry;
	
	If ParametersStructure.Property("ErrorDescription") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction // ЗагрузитьПакетXDTOвБюджет()

//Поиск ссылки при загрузке документа
//
Function FindRef(ObjectXDTO, CatalogName, ParametersStructure, CreateNew, AttributeName)
	
	CatalogManager	= Catalogs[CatalogName];
	
	RefIsSpecified		= NOT IsBlankString(ObjectXDTO.UID);
	CodeIsSpecified			= NOT IsBlankString(ObjectXDTO.Code);
	DescriptionIsSpecified	= NOT IsBlankString(ObjectXDTO.Description);
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// определение способа поиска
	If ParametersStructure.Property(AttributeName) Then;
		LoadingMethod = ParametersStructure[AttributeName];
	Else
		If RefIsSpecified Then
			LoadingMethod = "ByRef";
		Else
			If DescriptionIsSpecified Then
				LoadingMethod = "ByDescription";
			ElsIf CodeIsSpecified Then
				LoadingMethod = "ByCode";
			Else
				CatalogPresentation = Metadata.Catalogs.Find(CatalogName).Presentation();
				AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='The search type for ""%1"" catalog is not defined.';ru='Неопределен тип поиска для справочника ""%1"".'"),CatalogPresentation ));
				Return Undefined;
			EndIf;
		EndIf;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Поиск
	If LoadingMethod = "ByRef" Then
		Ref = CatalogManager.GetRef(New UUID(ObjectXDTO.UID));
	ElsIf LoadingMethod = "ByCode" Then
		Ref = CatalogManager.FindByCode(ObjectXDTO.Code);
	Else
		//Так как эта обработка не должна создавать новые то ищем только по наименованию
		//Существует вероятность одинаковых наименований в разных группах и это будет ошибка 
		Ref = FindCatalogByDescriptionWithoutParent(ObjectXDTO.Description, CatalogName, GetBoolean(GetProperty(ObjectXDTO, "IsFolder")), ParametersStructure);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Контроль результата поиска
	If Ref = CatalogManager.EmptyRef() Then
		If CreateNew Then
			If GetProperty(ObjectXDTO, "IsFolder") <> Undefined AND GetBoolean(ObjectXDTO.IsFolder) Then
				Object = CatalogManager.CreateFolder();
			Else
				Object = CatalogManager.CreateItem();
			EndIf;
			Object.Code = ObjectXDTO.Code;
			Object.Description = ObjectXDTO.Description;
			Object.Write();
			Ref = Object.Ref;
		Else
			CatalogPresentation = Metadata.Catalogs.Find(CatalogName).Presentation();
			If LoadingMethod = "ByRef" Then
				AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='Failed to find catalog item ""%1"" by link: ""%2"".';ru='Не удалось найти элемент справочника ""%1"" по ссылке: ""%2"".'"), CatalogPresentation, ObjectXDTO.GUID));
			Else
				AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='Failed to find the catalog item ""%1"" by code/name: ""%2"" / ""%3"".';ru='Не удалось найти элемент справочника ""%1"" по коду/наименованию: ""%2"" / ""%3"".'"), CatalogPresentation, ObjectXDTO.Code, ObjectXDTO.Description));
			EndIf;
			Return Undefined;
		EndIf;
	EndIf;
		
	Return Ref;
	
EndFunction // НайтиСсылку()

//Загрузка одного Документ.уфБюджет
//
Procedure LoadBudget(ObjectXDTO, ParametersStructure)
	
	DocumentRowsLimit = 99999;
	Cancel = False;
	
	////////////////////////////////////////////////////////////////////////
	// 0 -  получение списка документов по подразделениям
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	fmBudget.Ref AS Ref
	               |INTO TTBudgets
	               |FROM
	               |	Document.fmBudget AS fmBudget
	               |WHERE
	               |	fmBudget.BeginOfPeriod = &BeginOfPeriod
	               |	AND fmBudget.OperationType = &OperationType
	               |	AND fmBudget.Department = &Department
	               |	AND fmBudget.Scenario = &Scenario
	               |	AND NOT fmBudget.DeletionMark
	               |	AND fmBudget.Currency = &Currency
	               |	AND fmBudget.Project = &Project
	               |	AND (CAST(fmBudget.Comment AS String(25))) = ""Loaded FROM File Excel""
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTBudgets.Ref AS Ref
	               |FROM
	               |	TTBudgets AS TTBudgets
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	fmBudgetBudgetData.Period AS Period,
	               |	fmBudgetBudgetData.RecordType AS RecordType,
	               |	fmBudgetBudgetData.Item AS Item,
	               |	fmBudgetBudgetData.CorItem AS CorItem,
	               |	fmBudgetBudgetData.CorDepartment AS CorDepartment,
	               |	SUM(fmBudgetBudgetData.Amount) AS Amount,
	               |	fmBudgetBudgetData.Analytics1 AS Analytics1,
	               |	fmBudgetBudgetData.Analytics2 AS Analytics2,
	               |	fmBudgetBudgetData.Analytics3 AS Analytics3,
	               |	fmBudgetBudgetData.CorProject AS CorProject
	               |FROM
	               |	Document.fmBudget.BudgetsData AS fmBudgetBudgetData
	               |WHERE
	               |	fmBudgetBudgetData.Ref IN
	               |			(SELECT
	               |				TTBudgets.Ref
	               |			FROM
	               |				TTBudgets AS TTBudgets)
	               |
	               |GROUP BY
	               |	fmBudgetBudgetData.RecordType,
	               |	fmBudgetBudgetData.Analytics1,
	               |	fmBudgetBudgetData.CorDepartment,
	               |	fmBudgetBudgetData.Analytics2,
	               |	fmBudgetBudgetData.Analytics3,
	               |	fmBudgetBudgetData.Item,
	               |	fmBudgetBudgetData.CorProject,
	               |	fmBudgetBudgetData.CorItem,
	               |	fmBudgetBudgetData.Period";
	Query.SetParameter("BeginOfPeriod", ObjectXDTO.BeginOfPeriod);
	OperationType = Enums.fmBudgetOperationTypes[ObjectXDTO.OperationType];
	Query.SetParameter("OperationType", OperationType);
	ReOnScenario = FindRef(ObjectXDTO.Scenario, "fmBudgetingScenarios", ParametersStructure, False, "Scenario");
	Query.SetParameter("Scenario",	ReOnScenario);
	RefOnDepartment = FindRef(ObjectXDTO.Department, "fmDepartments", ParametersStructure, False, "Department");
	RefOnCurrency = FindRef(ObjectXDTO.Currency, "Currencies", ParametersStructure, False, "Currency");
	If GetProperty(ObjectXDTO, "Project")<>Undefined Then
		RefOnProject = FindRef(ObjectXDTO.Project, "fmProjects", ParametersStructure, False, "Project");
	Else
		RefOnProject = Catalogs.fmProjects.EmptyRef();
	EndIf;
	If RefOnDepartment = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	Query.SetParameter("Department", RefOnDepartment);
	Query.SetParameter("Currency", RefOnCurrency);
	Query.SetParameter("Project", RefOnProject);
	Result = Query.ExecuteBatch();
	Selection = Result[1].SELECT();
	DocumentsArray = New Array;
	While Selection.Next() Do
		// уже существуют документы данные которых надо поместить в "ТЧ_ДанныеБюджетов"
		DocumentsArray.Add(Selection.Ref);
	EndDo;
	
	TS_BudgetsData = Result[2].Unload();
	If ParametersStructure.UpdateExistingDocuments = 2 Then
		TS_BudgetsData.Clear();
	EndIf;
	
	TabularSection = GetIterationCollection(ObjectXDTO.BudgetsData.DocumentRow);
	
	ExistingUpdateMode	= ( ParametersStructure.UpdateExistingDocuments = 1 );
	ExistingAddMode= ( ParametersStructure.UpdateExistingDocuments = 3 );
	
	RowsFilter = New Structure("Period, CorDepartment, Item, Analytics1, Analytics2, Analytics3, RecordType, CorProject, CorItem");
	
	For Each CurRow In TabularSection Do
		
		// Значения строк табличной части.
		Period = CurRow.Period;
		RecordType = Enums.fmBudgetFlowOperationTypes[CurRow.RecordType];
		// Статья.
		If OperationType=Enums.fmBudgetOperationTypes.Cashflows Then
			Prefix = "fm";
			ManagerName = "fmCashflowItems";
		Else
			Prefix = "";
			ManagerName = "fmIncomesAndExpensesItems";
		EndIf;
		If GetProperty(CurRow, "Item")<>Undefined Then
			Item = FindRef(CurRow.Item, ManagerName, ParametersStructure, False, "Item");
			If NOT ValueIsFilled(Item) Then
				Cancel = True;
			EndIf;
		Else
			Cancel = True;
		EndIf;
		If Cancel Then
			Continue; // в случае возникновения ошибок поиска дальнейшее заполнение бессмысленно т.к. документ не будет сохранен
		EndIf;
		// Кор. статья.
		If GetProperty(CurRow, "CorItem")<>Undefined Then
			CorItem = FindRef(CurRow.CorItem, ManagerName, ParametersStructure, False, "CorItem");
		Else
			CorItem = Undefined;
		EndIf;
		// Кор. подразделение.
		If GetProperty(CurRow, "CorDepartment")<>Undefined Then
			CorDepartment = FindRef(CurRow.CorDepartment, "fmDepartments", ParametersStructure, False, "CorDepartment");
		Else
			CorDepartment = Catalogs.fmDepartments.EmptyRef();
		EndIf;
		// Кор. проект.
		If GetProperty(CurRow, "CorProject")<>Undefined Then
			CorProject = FindRef(CurRow.CorProject, "fmProjects", ParametersStructure, False, "CorProject");
		Else
			CorProject = Catalogs.fmProjects.EmptyRef();
		EndIf;
		// Универсальная аналитика.
		If GetProperty(CurRow, "Analytics1")<>Undefined AND ValueIsFilled(Item[Prefix+"AnalyticsType1"]) Then
			ManagerName = StrReplace(Metadata.FindByType(Item[Prefix+"AnalyticsType1"].ValueType.Types()[0]).FullName(), "Catalog.", "");
			Analytics1 = FindRef(CurRow.Analytics1, ManagerName, ParametersStructure, False, "Analytics1");
		Else
			Analytics1 = Undefined;
		EndIf;
		If GetProperty(CurRow, "Analytics2")<>Undefined AND ValueIsFilled(Item[Prefix+"AnalyticsType2"]) Then
			ManagerName = StrReplace(Metadata.FindByType(Item[Prefix+"AnalyticsType2"].ValueType.Types()[0]).FullName(), "Catalog.", "");
			Analytics2 = FindRef(CurRow.Analytics2, ManagerName, ParametersStructure, False, "Analytics2");
		Else
			Analytics2 = Undefined;
		EndIf;
		If GetProperty(CurRow, "Analytics3")<>Undefined AND ValueIsFilled(Item[Prefix+"AnalyticsType3"]) Then
			ManagerName = StrReplace(Metadata.FindByType(Item[Prefix+"AnalyticsType3"].ValueType.Types()[0]).FullName(), "Catalog.", "");
			Analytics3 = FindRef(CurRow.Analytics3, ManagerName, ParametersStructure, False, "Analytics3");
		Else
			Analytics3 = Undefined;
		EndIf;
		
		If NOT ParametersStructure.UpdateExistingDocuments = 2 Then
			
			RowsFilter.Period			= Period;
			RowsFilter.CorDepartment = CorDepartment;
			RowsFilter.Item			= Item;
			RowsFilter.RecordType		= RecordType;
			RowsFilter.Analytics1		= Analytics1;
			RowsFilter.Analytics2		= Analytics2;
			RowsFilter.Analytics3		= Analytics3;
			RowsFilter.CorItem		= CorItem;
			RowsFilter.CorProject		= CorProject;
			
			//Необходимо найти строку если такая есть
			TSRows = TS_BudgetsData.FindRows(RowsFilter);
			
			If TSRows.Count() > 0 Then
				TSRow = TSRows[0];
				//! Во всех режимах нулевое значение суммы документа всегда заменяется на пришедшее из файла !
				// СУММА
				If TSRow.Amount = 0 Then
					TSRow.Amount = GetNumber(CurRow.Amount);
				ElsIf GetNumber(CurRow.Amount) <> 0 AND ExistingUpdateMode Then
					TSRow.Amount = GetNumber(CurRow.Amount);
				ElsIf ExistingAddMode Then
					TSRow.Amount = TSRow.Amount + GetNumber(CurRow.Amount);
				EndIf;
				Continue;
			Else
				// несуществующие данные всегда добавляются
				NewLine = TS_BudgetsData.Add();
			EndIf;
			
		Else
			//Пришедшие данные полностью заменюят данные документа
			NewLine = TS_BudgetsData.Add();
		EndIf;
		
		NewLine.Period			= Period;
		NewLine.CorDepartment= CorDepartment;
		If ValueIsFilled(CorDepartment) Then
			NewLine.CorBalanceUnit = CorDepartment.BalanceUnit;
		EndIf;
		NewLine.Item			= Item;
		NewLine.RecordType		= RecordType;
		NewLine.Amount			= GetNumber(CurRow.Amount);
		NewLine.Analytics1		= Analytics1;
		NewLine.Analytics2		= Analytics2;
		NewLine.Analytics3		= Analytics3;
		NewLine.CorItem		= CorItem;
		NewLine.CorProject		= CorProject;
		
	EndDo;
	
	////////////////////////////////////////////////////////////////////////
	// 3 - создание и/или заполнение документов
	
	DocumentIndex = 0;
	TotalRows = TS_BudgetsData.Count();
	ProcessedRows = 0;
	
	BudgetVersioning = Constants.fmBudgetVersioning.Get();
	DepartmentStructuresBinding = Constants.fmDepartmentStructuresBinding.Get();
	
	While ProcessedRows<TotalRows Do
		
		If DocumentsArray.Count() >= DocumentIndex + 1 Then
			// получение уже существующего документа
			DocumentObject = DocumentsArray[DocumentIndex].GetObject();
			DocumentObject.BudgetsData.Clear();
		Else
			DocumentObject = Documents.fmBudget.CreateDocument();
			If BudgetVersioning=Enums.fmBudgetVersioning.EveryDay Then
				DocumentObject.ActualVersion = BegOfDay(CurrentSessionDate());
			ElsIf BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
				DocumentObject.ActualVersion = BegOfMonth(CurrentSessionDate());
			EndIf;
			DocumentObject.OperationType = OperationType;
			DocumentObject.BeginOfPeriod = ObjectXDTO.BeginOfPeriod;
			DocumentObject.Department = RefOnDepartment;
			DocumentObject.BalanceUnit = RefOnDepartment.BalanceUnit;
			DocumentObject.Scenario = ReOnScenario;
			DocumentObject.Currency = RefOnCurrency;
			DocumentObject.Project = RefOnProject;
			DocumentObject.DATE = CurrentSessionDate();
			DocumentObject.SetNewNumber();
			DocumentObject.Responsible = Users.CurrentUser();
			DocumentObject.Comment = NStr("en='Imported  from Excel';ru='Загружено из файла эксель'");
			fmCurrencyRatesProcessing.FormTableOfCurrencyRates(DocumentObject.CurrencyRates, DocumentObject.Currency, DocumentObject.BeginOfPeriod, DocumentObject.Scenario);
			If DepartmentStructuresBinding AND NOT OperationType=Enums.fmBudgetOperationTypes.InternalSettlements Then
				DocumentObject.InfoStructure = fmBudgeting.GetBasicStructure(DocumentObject.Department, DocumentObject.OperationType);
			EndIf;
		EndIf;
		DocumentIndex = DocumentIndex + 1;
		
		DocumentRowsLoaded = 0;
		// проверка - можно ли отправить в ТЧ то, что есть.
		While DocumentRowsLoaded <= DocumentRowsLimit AND ProcessedRows<TotalRows Do 
			NewLine = DocumentObject.BudgetsData.Add();
			FillPropertyValues(NewLine, TS_BudgetsData[ProcessedRows]);
			NewLine.VersionPeriod = DocumentObject.ActualVersion;
			ProcessedRows = ProcessedRows + 1;
			DocumentRowsLoaded = DocumentRowsLoaded + 1;
		EndDo;
		
		If NOT Cancel Then
			If DocumentRowsLoaded > 0 Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
					ParametersStructure.DocumentImportResult.Add(StrTemplate(NStr("en='The document is successfully imported: ""%1"" for period <%2> by department <%3> and scenario <%4>.';ru='Успешно загружен документ: ""%1"" за период <%2> по подразделению <%3> и сценарию <%4>.'"), DocumentObject.Ref, DocumentObject.BeginOfPeriod, DocumentObject.Department, DocumentObject.Scenario));
					ParametersStructure.SuccessfullyLoadedDocuments.Add(DocumentObject.Ref);
				Except
					AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='The document was not created. You must fix errors from the messages! Error: %1';ru='Документ не был создан. Необходимо устранить ошибки из сообщений! Error: %1'"),ErrorDescription()));
				EndTry;
			Else
				If NOT DocumentObject.IsNew() Then
					// в результате загрузки в документе нет строк - он больше не нужен
					DocumentObject.SetDeletionMark(True);
				EndIf;
			EndIf;
		Else
			If DocumentObject.IsNew() Then
				AddErrorDescription(ParametersStructure, NStr("en='The document was not created. You must fix errors from the messages!';ru='Документ не был создан. Необходимо устранить ошибки из сообщений!'"));
			Else
				AddErrorDescription(ParametersStructure, StrTemplate(NStr("en='Document ""%1"" was not changed. You must fix errors from the messages!';ru='Документ ""%1"" не был изменён. Необходимо устранить ошибки из сообщений!'"), String(DocumentObject.Ref)));
			EndIf;
		EndIf;
		
	EndDo;
	
	// остальные неактуальные оставшиеся документы очистить и пометить на удаление
	While True Do
		If DocumentsArray.Count() >= DocumentIndex + 1 Then
			// получение уже существующего документа
			DocumentObject = DocumentsArray[DocumentIndex].GetObject();
			DocumentObject.BudgetsData.Clear();
			DocumentObject.SetDeletionMark(True);
			DocumentIndex = DocumentIndex + 1;
		Else
			Break
		EndIf;
	EndDo;
	
	TS_BudgetsData.Clear(); // уборка за собой
	
EndProcedure // ЗагрузитьБюджет()

Procedure AddErrorDescription(ParametersStructure, VAL ErrorDescription, Cancel = True)
	
	Cancel = True;
	If ParametersStructure.Property("ErrorDescription") Then
		Messages = ParametersStructure.ErrorDescription;
		If Messages.Find(ErrorDescription) = Undefined Then
			Messages.Add(ErrorDescription);
			ParametersStructure.ErrorDescription = Messages;
		EndIf;
	Else
		Messages = New Array;
		Messages.Add(ErrorDescription);
		ParametersStructure.Insert("ErrorDescription", Messages);
	EndIf;
	
EndProcedure //ДобавитьОписаниеОшибки()



















