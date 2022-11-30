
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
Procedure GenerateReportAtServer(Cancel = False, Expand = False, Collapse = False, RereadStructure = False, Action = "")

	If NOT CheckFilling() Then
		Return;
	EndIf;

	ConnectionLineTypeChange= False;

	//#Обасть ФормированиеСтруктурыДопПараметов
	// ДОПОЛНИТЕЛЬНЫЕ ПАРАМЕТРЫ ОТЧЕТА
	If NOT IsTempStorageURL(Report.AdditionalReportParameters) Then
		AddParametersStructure = New Structure;
	Else
		AddParametersStructure = GetFromTempStorage(Report.AdditionalReportParameters);
	EndIf;
	//////////
	ConnectionLineType_WithoutSpaces = StrReplace(ConnectionLineType," ","");

	If AddParametersStructure.Property("ConnectionLine") Then
		ConnectionLineTypeChange = (AddParametersStructure.ConnectionLine <> New Line(SpreadsheetDocumentCellLineType[ConnectionLineType_WithoutSpaces]));
	EndIf;

	ConnectionLineType_WithoutSpaces = StrReplace(ConnectionLineType," ","");
	AddParametersStructure.Insert("ConnectionLine",	New Line(SpreadsheetDocumentCellLineType[ConnectionLineType_WithoutSpaces]));

	AddParametersStructure.Insert("DescriptionAreaTextColor",	NameAreaColorText);
	AddParametersStructure.Insert("DescriptionAreaTextFont",	NameAreaTextFont);
	AddParametersStructure.Insert("ManagerAreaColorText",		ManagerAreaColorText);
	AddParametersStructure.Insert("ManagerAreaTextFont",		ManagerAreaTextFont);
	AddParametersStructure.Insert("FRAreaTextColor",				FRAreaTextColor);
	AddParametersStructure.Insert("FRAreaTextFont",				FRAreaTextFont);

	PutToTempStorage(AddParametersStructure,	Report.AdditionalReportParameters);
	//#КонецОбасти


	////////////////////////////////////


	//#Область ДополнениеПараметровВыполненияОтчета
	ParametersStructure = GetFromTempStorage(ReportExecutionParameters);

	///////////
	FinResWasFormed	= ?( ParametersStructure.Property("BudgetingFRFlag"), ParametersStructure.BudgetingFRFlag, False);
	_DepPresentation	= ?( ParametersStructure.Property("DepPresentation"), ParametersStructure.DepPresentation, Report.DepPresentation);
	
	ChangesInFinResFormingParameters = False;
	If FinResWasFormed Then
		// измененность параметров получения Финреза
		ChangesInFinResFormingParameters = (NOT ParametersStructure.Scenario = Report.Scenario);
		
	EndIf;
	
	SettingsInfoManager= ?( ParametersStructure.Property("ManagerInfo"), ParametersStructure.ManagerInfo, False);
	InfoWithMarked				= ?( ParametersStructure.Property("InfoWithMarked"), ParametersStructure.InfoWithMarked, False); // помеченные на удаление подразделения
	BeginOfPeriod 	= ?(ParametersStructure.Property("BeginOfPeriod"), ParametersStructure.BeginOfPeriod, Report.BeginningOfBudgetingPeriod);
	EndOfPeriod 	= ?(ParametersStructure.Property("EndOfPeriod"), ParametersStructure.EndOfPeriod, Report.EndOfBudgetingPeriod);
	_StructureVersion 	= ?(ParametersStructure.Property("StructureVersion"), ParametersStructure.StructureVersion, Report.StructureVersion);

	If  ( ParametersStructure.Property("RootDepartment")
			AND NOT ParametersStructure.RootDepartment = Report.Department ) OR
		NOT FinResWasFormed = Report.BudgetingFRFlag OR		// изменён флаг получения финроза
		ChangesInFinResFormingParameters OR					// изменены параметры получения Финреза
		NOT Report.InfoManager = SettingsInfoManager OR 
		NOT _DepPresentation = Report.DepPresentation OR
		NOT InfoWithMarked = Report.IncludeMarkedOnDeletion OR
		NOT BeginOfPeriod = Report.BeginningOfBudgetingPeriod OR
		NOT EndOfPeriod = Report.EndOfBudgetingPeriod  OR
		NOT _StructureVersion = Report.StructureVersion
		Then
			
		ParametersStructure.Insert("FullReportRegeneration");
			
	ElsIf ConnectionLineTypeChange Then;
		
		ParametersStructure.Insert("ConnectionLineTypeChange");
		
	ElsIf ParametersStructure.Property("ColorFill")
		AND NOT ParametersStructure.ColorFill = Report.ColorFill Then
		
		ParametersStructure.Insert("ColorFillRefresh");
		
	EndIf;
	
	ParametersStructure.Insert("RootDepartment",	Report.Department);
	ParametersStructure.Insert("GenerateForWebClient",IsWebClient);
	ParametersStructure.Insert("Expand",				Expand);
	ParametersStructure.Insert("Collapse",				Collapse);
	ParametersStructure.Insert("ManagerInfo",	Report.InfoManager);
	ParametersStructure.Insert("ColorFill",			Report.ColorFill);
	ParametersStructure.Insert("DepPresentation",		Report.DepPresentation);
	ParametersStructure.Insert("BeginOfPeriod",			Report.BeginningOfBudgetingPeriod);
	ParametersStructure.Insert("EndOfPeriod",			Report.EndOfBudgetingPeriod);
	
	// Параметры получения финреза
	ParametersStructure.Insert("BudgetingFRFlag",	Report.BudgetingFRFlag);
	ParametersStructure.Insert("Scenario",	Report.Scenario);
	ParametersStructure.Insert("InfoWithMarked", Report.IncludeMarkedOnDeletion);
	ParametersStructure.Insert("StructureVersion", 		Report.StructureVersion);
	
	If RereadStructure 
		AND ParametersStructure.Property("DepartmentTree") Then
		
		ParametersStructure.Delete("DepartmentTree");
	EndIf;
	
	PutToTempStorage(ParametersStructure, ReportExecutionParameters);
	//#КонецОбласти
	
	ThisReport = FormAttributeToValue("Report");
	ThisReport.GenerateOrgStructureReport(Result, ReportExecutionParameters, Cancel);
	If Cancel Then
		Return;
	EndIf;

	fmReportsClientServer.SetState(ThisForm, True);

EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ДЕЙСТВИЯ КОМАНДНЫХ ПАНЕЛЕЙ ФОРМЫ

&AtClient
Procedure GenerateReport(Command)
	
	Cancel = False;
	ClearMessages();
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGenerating");
	
	GenerateReportAtServer(Cancel,,, True);
	
 	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	
	If Cancel Then
		ShowMessageBox(, NStr("en='The report is not generated. See error reports.';ru='Отчет не сформирован. См. сообщения об ошибках.'") );
	EndIf;
	
EndProcedure // СформироватОтчет()

&AtClient
Procedure GenerateReportAtServerCollapseExpansion(Expand = True)

	Cancel = False;
	ClearMessages();
	GenerateReportAtServer(Cancel, Expand, NOT Expand);
	If Cancel Then
		ShowMessageBox(, NStr("en='The report is not generated. See error reports.';ru='Отчет не сформирован. См. сообщения об ошибках.'") );
	EndIf;


EndProcedure // СформироватОтчет()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ И ЭЛЕМЕНТОВ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	fmReportsClientServer.ChangeButtonTitleSettingsPanel(
		ThisForm.Items.SettingsPanel, ThisForm.Items.GroupSettingsPanel.Visible);
	
	DetailsData 					= PutToTempStorage(DetailsData,	UUID);
	ExpandedNodes 					= PutToTempStorage(New Array,		UUID);
	Report.AdditionalReportParameters	= PutToTempStorage(New Structure,	UUID);
	ProcessedNode					= PutToTempStorage(Undefined,		UUID);
	OutputAreaAddress					= PutToTempStorage(New Map,	UUID);

	ReportExecutionParameters			= PutToTempStorage(New Structure("ExpandedNodesAddress, OutputAreaAddress",
			ExpandedNodes, OutputAreaAddress),
		UUID);
	
	Report.InfoManager = True;

	SetDefaultSettingsAtServer();

	FillFromExternalReportParameters(Parameters, Report, ThisForm);

	FormManagement(ThisForm);


	/////////////////////////////////////////////////////////////////////////////////////////////
	// Определение в интерфейсе возможности выбора типа соединительной линии между блоками

	Items.LineType.ChoiceList.Add(SpreadsheetDocumentCellLineType.ThinDashed,NStr("en='Dashed';ru='Редкий пунктир'"));
	Items.LineType.ChoiceList.Add(SpreadsheetDocumentCellLineType.Solid,		NStr("ru = 'Сплошной'; en = 'Solid'"));
	//Элементы.ТипЛинии.СписокВыбора.Добавить(ТипЛинииЯчейкиТабличногоДокумента.Сплошная,		НСтр("en='Thick solid';ru='Толстая сплошная'"));

	ConnectionLineIndex = 1; // тонкая сплошная
	ConnectionLineType = Items.LineType.ChoiceList[ConnectionLineIndex].Presentation;
	
	DepartmentVersioning = Constants.fmDepartmentsStructuresVersions.Get();
	ThisForm.Title = GetFormTitle(ThisForm.FormName);
	Items.GroupStructureVersion.Visible = DepartmentVersioning;
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnOpen(Cancel)

	
	//ОбщегоНазначенияКлиент.ВнешнийОтчетПриОткрытии(Отказ, ЭтаФорма);
	If NOT DepartmentVersioning Then
		Report.StructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	EndIf;

	//Сформируем отчет при открытии, если отчет вызван из справочника Подразделения
	If GenerateOnOpen Then
		ClearMessages();
		GenerateReportAtServer();
	EndIf;


	IsWebClient = False;
	#If WebClient Then
		IsWebClient = True;
	#EndIf

	//заполняем первоначальный список выбора Периода
	fmPeriodChoiceClient.FillPeriodList(ThisObject, Items.BudgetingPeriod, BudgetingPeriodType, Report.BeginningOfBudgetingPeriod);
	
EndProcedure // ПриОткрытии()

&AtClient
Procedure SettingsPanel(Command)
	
	Items.GroupSettingsPanel.Visible = NOT Items.GroupSettingsPanel.Visible;
	fmReportsClientServer.ChangeButtonTitleSettingsPanel(
		Items.SettingsPanel, Items.GroupSettingsPanel.Visible);

EndProcedure

&AtClient
Procedure DetailsProcessingResult_MenuEnd(SelectedAction, Parameter) Export
	Item = Parameter.Item;
	Details = Parameter.Details;
	If SelectedAction = Undefined Then
			Return;
	EndIf;
		
	If SelectedAction.Value = "OpenValue" Then
			
		StandardProcessing = False;
		//ОткрытьЗначение(Расшифровка);
		OpenDepartmentCatItem(Details);
			
	ElsIf SelectedAction.Value = "AddChild" Then
		
		OpenForm("Catalog.fmDepartments.ObjectForm", 
			New Structure("FillingValues", New Structure("Parent", Details)),ThisForm);
		
	ElsIf SelectedAction.Value = "MoveInGroup" Then
			
			
			FormParameters		= New Structure("StructureVersion",Report.StructureVersion);
			
			AddPar = New Structure("Details", Details);
			Handler = New NotifyDescription("DetailsProcessingResult_End2", ThisObject, AddPar);
			If DepartmentVersioning Then
				OpenForm("Catalog.fmDepartments.Form.VersionChoiceForm", FormParameters, Item,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
			Else
				OpenForm("Catalog.fmDepartments.Form.ChoiceForm", , Item,,,, Handler, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;	
	ElsIf SelectedAction.Value = "SetDeletionMark"
		OR SelectedAction.Value = "ResetDeletionMark" Then
		
		
		ActionString	= ?(SelectedAction.Value = "SetDeletionMark", "Set", "Reset");
		ActionStrinEN	= ?(SelectedAction.Value = "SetDeletionMark", "Mark", "Unmark");
		
		QueryText = NStr("en='%1% mark for deletion?';ru='%1% пометку удаления?'");
		QueryText = StrReplace(QueryText, "%1%", ActionString);
		QueryText = StrReplace(QueryText, "%2%", ActionStrinEN);
		
		ShowQueryBox(New NotifyDescription("DetailsProcessingResultEnd1", ThisObject, New Structure("Details, ActionStrinEN, ActionString, QueryText", Details, ActionStrinEN, ActionString, QueryText)), QueryText, QuestionDialogMode.YesNo);

		
	EndIf;
EndProcedure

&AtClient
Procedure DetailsProcessingResult(Item, Details, StandardProcessing)

	//Если расшифровка фин результата
	If TypeOf(Details) = Type("Structure") Then

		If Details.Property("TreeRow") Then

			StandardProcessing = False;
			DepartmentCode = "";
			RegisterNodeExpansionAtServer(Details.TreeRow, Details.Openned, Details.BranchDepartment, ExpandedNodes, ReportExecutionParameters, DepartmentCode);
			GenerateReportAtServer();
			
			// позиционирование на юните
			SDArea = Result.Areas.Find("Item_" + DepartmentCode);
			If NOT SDArea = Undefined Then
				Items.Result.CurrentArea = SDArea;
				ThisForm.CurrentItem = Items.Result;
			EndIf;

		EndIf;
	ElsIf TypeOf(Details) = Type("CatalogRef.fmDepartments") Then
		
		If Details.IsEmpty() Then
		
			Return;
		EndIf; 
		
		StandardProcessing = False;
		
		MenuItemsList = GetMenuItemsList(Details);
		
		AddPar = New Structure;
		AddPar.Insert("Item", Item);
		AddPar.Insert("Details", Details);
		NotDescr = New NotifyDescription("DetailsProcessingResult_MenuEnd", ThisObject, AddPar);
		ThisForm.ShowChooseFromMenu(NotDescr, MenuItemsList, Item);
		
			
			
	ElsIf Details = "CreateNewRoot" Then
		
		StandardProcessing = False;
		
		
		OpenForm("Catalog.fmDepartments.ObjectForm", 
			New Structure("FillingValues"), 
			ThisForm);
			
	Else
			
		StandardProcessing = False;
	EndIf;

EndProcedure

&AtClient
Procedure DetailsProcessingResultEnd3(SelectedItem, AdditionalParameters) Export
	
	Details = AdditionalParameters.Details;
	
	
	SelectedAction = SelectedItem;
	
	If SelectedAction = Undefined Then
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure DetailsProcessingResultEnd1(QueryResult, AdditionalParameters) Export
	
	If QueryResult = DialogReturnCode.Yes Then
		Details = AdditionalParameters.Details;
	
		DetailsProcessingResultFragment(Details);
	EndIf;
EndProcedure

&AtClient
Procedure DetailsProcessingResultFragment(VAL Details)
	
	DeletionMarkInteractiveControl(Details);

EndProcedure

&AtClient
Procedure DetailsProcessingResult_End2(ChoiceValue, Parameter) Export
	
	Details = Parameter.Details;
	If NOT ChoiceValue = Undefined Then
		
		Cancel = False;
		MovementFromRoot = False;
		DepartmentMovementInGroup(Details, ChoiceValue, Cancel, ReportExecutionParameters, MovementFromRoot, Report.StructureVersion);
		
		If NOT Cancel Then
			
			
			DetailsProcessingResult_End2Fragment(MovementFromRoot);

			
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsProcessingResult_End2End(QueryResult, AdditionalParameters) Export
	
	MovementFromRoot = AdditionalParameters.MovementFromRoot;
	Details = AdditionalParameters.Details;
	
	
	If QueryResult = DialogReturnCode.Yes Then
		
		LinkedDepartments = FindLinkedDepartments(Details);
		For Each LinkedDepartment In LinkedDepartments Do
			ChangeLinkedDepartmentParent(Details, LinkedDepartment);
		EndDo;
	EndIf;
	
	DetailsProcessingResult_End2Fragment(MovementFromRoot);

EndProcedure

&AtClient
Procedure DetailsProcessingResult_End2Fragment(VAL MovementFromRoot)
	
	GenerateReport(New Structure("Name", ?(MovementFromRoot, "RereadStructure", "")));

EndProcedure

&AtClient
Procedure OpenDepartmentCatItem(RefOnDepartment)
	
		FormParameters = New Structure;
		FormParameters.Insert("Key", RefOnDepartment);
		
		If ValueIsFilled(Report.StructureVersion) Then
			ItemParent = fmBudgeting.DepartmentParentByVersion(RefOnDepartment, Report.StructureVersion);
			FormParameters.Insert("Parent", ItemParent);
		Else
		//	//родителя получим из дерева на форме
		//	ТекДанныеДерева = Элементы.Дерево2.ТекущиеДанные;
		//	Если ТекДанныеДерева = Неопределено Тогда
		//		Возврат;
		//	КонецЕсли;
		//	ВыбрЗначение = ТекДанныеДерева.Подразделение;
		//	РодительВДереве = ТекДанныеДерева.ПолучитьРодителя();
		//	Если НЕ РодительВДереве = Неопределено Тогда
		//		РодительЭлемента = РодительВДереве.Подразделение;
		//	Иначе
		//		РодительЭлемента = ПредопределенноеЗначение("Справочник.Подразделения.ПустаяСсылка");
		//	КонецЕсли;
		EndIf;
		
		//ПараметрыФормы.Вставить("Родитель", РодительЭлемента); 
		FormParameters.Insert("StructureVersion", Report.StructureVersion);
		
		OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters,ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);

	
EndProcedure

&AtClient
Procedure AdditionalDetailsProcessingResult(Item, Details, StandardProcessing)

	//Расшифровка = Неопределено;
	DetailsProcessingResult(Item, Details, StandardProcessing);

EndProcedure

&AtServerNoContext
Procedure RegisterNodeExpansionAtServer(_Department, Collapse, BranchDepartment, ExpandedNodesAddress, AddressReportExecutionParameters, DepartmentCode = Undefined)
	
	If TypeOf(Collapse) = Type("Boolean") Then
		
		ArrayExpandedNodes = GetFromTempStorage(ExpandedNodesAddress);
		
		Index = ArrayExpandedNodes.Find(_Department);
		
		If NOT Collapse Then
			
			If Index = Undefined Then
				
				ArrayExpandedNodes.Add(_Department);
			EndIf;
			
		Else
			
			If NOT Index = Undefined Then
				ArrayExpandedNodes.Delete(Index);
			EndIf;
			
		EndIf;
		
		PutToTempStorage(ArrayExpandedNodes, ExpandedNodesAddress);
		
	EndIf;
	
	//////////////////////////////////////////////////////////////////////////
	//// ОЧИСТКА КЭШИРОВАННЫХ ОБЛАСТЕЙ ВЫВОДА, КОТОРЫЕ НАДО ПЕРЕРИСОВАТЬ 
	//ОбластиВывода = ПолучитьИзВременногоХранилища(АдресОбластейВывода);
	//
	//Если Не ОбластиВывода[ПодразделениеВетви] = Неопределено Тогда
	//	
	//	ОбластиВывода.Удалить(ПодразделениеВетви);
	//КонецЕсли;
	//
	//ПоместитьВоВременноеХранилище(ОбластиВывода, АдресОбластейВывода);
	
	//////////////////////////////////////////////////////////////////////////
	ParametersStructure = GetFromTempStorage(AddressReportExecutionParameters);
	ParametersStructure.Insert("EventDepartment", _Department);
	DepartmentCode = _Department.Code;
	PutToTempStorage(ParametersStructure, AddressReportExecutionParameters);
	
EndProcedure // ЗарегистрироватьРазверткуУзела()

&AtClient
Procedure DepartmentOnChange(Item)
	
	ArrayExpandedNodes = GetFromTempStorage(ExpandedNodes);
	ArrayExpandedNodes.Clear();
	PutToTempStorage(ArrayExpandedNodes, ExpandedNodes);
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	DepartmentBeforeChange = Report.Department;
	
EndProcedure

&AtClient
Procedure DepPresentationOnChange(Item)
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
EndProcedure

&AtClient
Procedure MonetaryIndicatorOnChange(Item)
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ГРУППЫ "ОСНОВНЫЕ НАСТРОЙКИ"

/////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ПОЛЯ ТАБЛИЧНОГО ДОКУМЕНТА

&AtClient
Procedure ScenarioOnChange(Item)
	
	ScenarioOnChangeAtServer();
	
EndProcedure


&AtServer
Procedure ScenarioOnChangeAtServer()
		
	If Report.BudgetingFRFlag Then
		fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure //СценарийПриИзменении()

&AtClient
Procedure BudgetingFRFlagOnChange(Item)
	
	BudgetingFRFlagOnChangeAtServer();
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	
EndProcedure //ФлагФРБюджетированияПриИзменении()

&AtServer
Procedure BudgetingFRFlagOnChangeAtServer()
	
	If Report.BudgetingFRFlag Then
		//При включении флага расчета финансового результата бюджетирования
		//флаг расчета финансового результата первичного учета выключаем
		//При установленном флаге расчета финансового результата бюджетирования поле "Сценарий планирования становится обязательным к заполнению"
		Items.Scenario.AutoMarkIncomplete 	= True;
		Items.Scenario.MarkIncomplete 		= True;
	Else
		Items.Scenario.AutoMarkIncomplete 	= False;
		Items.Scenario.MarkIncomplete 		= False;
	EndIf;
	
EndProcedure //ФлагФРБюджетированияПриИзменении()

&AtServer
Procedure SetMainScenario()

	Report.Scenario = fmCommonUseServer.GetDefaultValue("MainScenario");

EndProcedure

&AtClient
Procedure DefaultSettings(Command)

	SetDefaultSettings();

EndProcedure

&AtServer
Procedure OnLoadUserSettingsAtServer(Settings)
	fmReportsServerCall.OnLoadUserSettingsAtServer(ThisForm, Settings);
	
	If Settings.AdditionalProperties.Property("ReportData") Then
	
		AdditionalProperties = Settings.AdditionalProperties.ReportData.Get();
		For Each StructureItem In AdditionalProperties Do
			
			// Восстановление реквизитов отчета
			If ThisForm.Report.Property(StructureItem.Key) Then
				If TypeOf(StructureItem.Value) = Type("ValueTable") Then
					ThisForm.Report[StructureItem.Key].Load(StructureItem.Value);
				Else
					ThisForm.Report[StructureItem.Key] = StructureItem.Value;
				EndIf;
			EndIf;

			If StructureItem.Key = "ConnectionLineType" Then

				ThisForm[StructureItem.Key] = StructureItem.Value;

			ElsIf StructureItem.Key = "BudgetingPeriodType" Then

				ThisForm[StructureItem.Key] = StructureItem.Value;

				If StructureItem.Key = "BudgetingPeriodType" Then

					ThisForm.Report.BeginningOfBudgetingPeriod	= fmReportsClientServer.ReportBegOfPeriod(ThisForm.BudgetingPeriodType, ThisForm.Report.BeginningOfBudgetingPeriod, ThisForm);
					ThisForm.Report.EndOfBudgetingPeriod	= fmReportsClientServer.ReportEndOfPeriod(ThisForm.BudgetingPeriodType, ThisForm.Report.EndOfBudgetingPeriod, ThisForm);
				EndIf;

			ElsIf (Find(StructureItem.Key, "AreaTextColor") > 0 OR Find(StructureItem.Key, "AreaTextFont") > 0) 
				AND Find(StructureItem.Key, "Position") = 0 Then
				
				ThisForm[StructureItem.Key] = StructureItem.Value;
			EndIf;

		EndDo;

		FormManagement(ThisForm);

		fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

	EndIf;
	
EndProcedure // ПриЗагрузкеПользовательскихНастроекНаСервере()

&AtServer
Procedure OnSaveUserSettingsAtServer(Settings)

	ReportObject = ThisForm.FormAttributeToValue("Report");

	ReportMetadata = ReportObject.Metadata();

	// Сохранение реквизитов отчета
	AdditionalProperties = New Structure;
	For Each Attribute In ReportMetadata.Attributes Do

		If ( TypeOf(ReportObject[Attribute.Name]) = Type("String")
			AND IsTempStorageURL(ReportObject[Attribute.Name]) )
			OR (Attribute.Name = "BeginningOfBudgetingPeriod"
				OR Attribute.Name = "EndOfBudgetingPeriod") Then

			Continue;
		EndIf;

		AdditionalProperties.Insert(Attribute.Name, ReportObject[Attribute.Name]);
	EndDo;

	//Для Каждого Реквизит Из ОтчетМетаданные.ТабличныеЧасти Цикл
	//	ДополнительныеСвойства.Вставить(Реквизит.Имя, ОтчетОбъект[Реквизит.Имя].Выгрузить());
	//КонецЦикла;

	AdditionalProperties.Insert("BudgetingPeriodType",	BudgetingPeriodType);
	AdditionalProperties.Insert("ConnectionLineType",		ConnectionLineType);

	////////////////////////////////////////////////////////////////////////
	AdditionalProperties.Insert("NameAreaColorText",			ThisForm.NameAreaColorText);
	AdditionalProperties.Insert("ManagerAreaColorText",	ThisForm.ManagerAreaColorText);
	AdditionalProperties.Insert("FRAreaTextColor",			ThisForm.FRAreaTextColor);

	AdditionalProperties.Insert("NameAreaTextFont",		ThisForm.NameAreaTextFont);
	AdditionalProperties.Insert("ManagerAreaTextFont",	ThisForm.ManagerAreaTextFont);
	AdditionalProperties.Insert("FRAreaTextFont",			ThisForm.FRAreaTextFont);
	AdditionalProperties.Insert("SettingsPanelVisible",      Items.GroupSettingsPanel.Visible);
	////////////////////////////////////////////////////////////////////////

	Settings.AdditionalProperties.Insert("ReportData", New ValueStorage(AdditionalProperties));

EndProcedure // ПриСохраненииПользовательскихНастроекНаСервере()

&AtClient
Procedure SetDefaultSettings()

	SetDefaultSettingsAtServer();

	//ВидПериодаБюджетированияПриИзменении_(ЭтаФорма,
	//	Отчет.НачалоПериодаБюджетирования,
	//	Отчет.КонецПериодаБюджетирования,
	//	ДоступныеПериодыОтчета.Месяц);

	OnOpen(False);

EndProcedure // УстановитьНастройкиПоУмолчнаию()

&AtServer
Procedure SetDefaultSettingsAtServer()


	//Управление выбором периода бюджетирования
	//При открытии формы сделаем вид периода бюджетирования - месяц, период бюджетирования - текущий месяц
	Report.BeginningOfBudgetingPeriod = BegOfMonth(CurrentDate());
	Report.EndOfBudgetingPeriod = EndOfMonth(CurrentDate());

	///////////////////////////////////////////////////////////////////////////////
	AvailableReportPeriods = fmReportsServerCall.GetAvailableReportPeriods();
	fmReportsServerCall.GetAvailablePeriodList(AvailableReportPeriods.Month,
		Items.BudgetingPeriodType.ChoiceList,
		AvailableReportPeriods.Month);
	BudgetingPeriodType = Items.BudgetingPeriodType.ChoiceList[0].Value;

	//По умолчанию представление подразделений в виде наименования
	Report.DepPresentation = "Description";

	//По умолчанию точность вывода цифр - "единица"
	Report.MonetaryIndicator = 2;
	
	SetMainScenario();
	
	Report.WrapDepartmentDescription = True;
	
	NameAreaTextFont		= New Font("Arial", 11);
	ManagerAreaTextFont	= New Font("Arial", 9);
	FRAreaTextFont		= New Font("Arial", 9);
	
	NameAreaColorText		= New Color;
	ManagerAreaColorText	= NameAreaColorText;
	FRAreaTextColor			= NameAreaColorText;
	
	Report.StructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	
EndProcedure // УстановитьНастройкиПоУмолчнаиюНаСервере()

&AtServer
Procedure FormManagement(Form)


	BudgetingPeriod = fmReportsClientServer.GetReportPeroidRepresentation(Form.BudgetingPeriodType,
		Report.BeginningOfBudgetingPeriod,
		Report.EndOfBudgetingPeriod,
		Form);


	BudgetingFRFlagOnChangeAtServer();

EndProcedure

&AtClient
Procedure CommandCollapseAll(Command)

	GenerateReportAtServerCollapseExpansion(False);

EndProcedure

&AtClient
Procedure CommandExpandAll(Command)

	GenerateReportAtServerCollapseExpansion(True);

EndProcedure

&AtServerNoContext
// <Описание процедуры>
//
// Параметры
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
Procedure FillFromExternalReportParameters(Parameters, Report, Form)

	If Parameters.Property("GetBudgetingFR") Then
		Report.BudgetingFRFlag = True;
	EndIf;

	BudgetingPeriodIsSet = False;
	If Parameters.Property("BeginningOfBudgetingPeriod") Then
		Report.BeginningOfBudgetingPeriod = Parameters.BeginningOfBudgetingPeriod;
		BudgetingPeriodIsSet = True;
	EndIf;

	If Parameters.Property("EndOfBudgetingPeriod") Then
		Report.EndOfBudgetingPeriod = Parameters.EndOfBudgetingPeriod;
		BudgetingPeriodIsSet = True;
	EndIf;

	If BudgetingPeriodIsSet Then
		Form.BudgetingPeriodType =fmReportsClientServer.GetPeriodType(
			Report.BeginningOfBudgetingPeriod,
			Report.EndOfBudgetingPeriod,
			Form);
	EndIf;

	//Заполним подразделение, если отчет вызван из справочника Подразделения
	If Parameters.Property("Department") Then
		
		Report.Department = Parameters.Department;
		Form.DepartmentBeforeChange = Report.Department;
	EndIf;

	If Parameters.Property("Scenario") Then
		Report.Scenario = Parameters.Scenario;
	EndIf;

	//Если отчет вызван из справочники Подразделения, тогд СформироватьПриОткрытии = Истина, иначе - Ложь
	If Parameters.Property("GenerateOnOpen") Then
		Form.GenerateOnOpen = Parameters.GenerateOnOpen;
	EndIf;

	If Parameters.Property("OpennedFromDetails") Then
		Form.OpennedFromDetails = Parameters.OpennedFromDetails;
	EndIf;

	If Parameters.Property("ParentReportID") Then
		Form.ParentReportID = Parameters.ParentReportID;
	EndIf;
	
	If Parameters.Property("StructureVersion") Then
		Report.StructureVersion = Parameters.StructureVersion;
	EndIf;

EndProcedure // ЗаполнитьПередаваемыеПараметрыОтчета()

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangeOfDepartmentInfo" 
		OR EventName = "DepartmentResponsibleEvent"
		OR EventName = "DepartmentInfoChange" Then
		
			GenerateReport(ThisForm.Commands.Find("RereadStructure"));
		
	ElsIf EventName = "NewDepartmentCreation" Then
		
			
			//предварительно изменения в струткре надо отразить и для версии
			WriteDepartmentStructureVersion(Parameter, Report.StructureVersion);
			
			If ValueIsFilled(Parameter.Parent) Then
				// Родитель вновь созданного подразделения должен быть развернут
				RefreshBranchOutputAtServer(Parameter.Parent, False, True);  // Метод регистрации события для подразделения, с последующим формированием отчета
			Else
				// создание нового корневого подразделения
				GenerateReport(ThisForm.Commands.Find("RereadStructure")); // Метод формирования отчета
			EndIf;
		
	EndIf;
	
EndProcedure //ОбработкаОповещения()

&AtServerNoContext
Procedure WriteDepartmentStructureVersion(Parameter, StructureVersion)

	InformationRegisters.DepartmentHierarchy.RecordDepartment(Parameter.Ref, Parameter.Owner, StructureVersion, Parameter.Parent);

EndProcedure // ЗаписатьВерсиюСтруктурыПодразделения()

&AtServer
Procedure RefreshBranchOutputAtServer(Department, Collapse = Undefined, RereadStructure = False)
	
	ThisReport = FormAttributeToValue("Report");
	InfoStructure = ThisReport.GetInfoAboutTreeRow(Department, ThisForm.ReportExecutionParameters);
	
	If NOT InfoStructure = Undefined Then
		
		_ReportExecutionParameters = GetFromTempStorage(ThisForm.ReportExecutionParameters);
		_ReportExecutionParameters.Insert("BranchRefresh"); // когда изменены данные о подразделении или добавлено новое
		PutToTempStorage(_ReportExecutionParameters, ThisForm.ReportExecutionParameters);
		
		RegisterNodeExpansionAtServer(Department, Collapse, InfoStructure.BranchDepartment, ExpandedNodes, ReportExecutionParameters);
	EndIf;
	
	GenerateReportAtServer(,,, RereadStructure);
	
EndProcedure //ОбновитьВыводВетвиНаСервере()

&AtServerNoContext
Procedure DepartmentMovementInGroup(Department, VAL NewGroup, Cancel = False, AddressReportExecutionParameters, MovementFromRoot = False, StructureVersion = Undefined)
	
	If TypeOf(Department) = Type("CatalogRef.fmDepartments") AND
		NOT Department.IsEmpty() Then
		
		// ПРОВЕРКА НА ЗАЦИКЛИВАНИЕ УРОВНЕЙ ПРИ СМЕНЕ РОДИТЕЛЯ
		If Department = NewGroup  								// перемещение в саму себя
			OR NewGroup.BelongsToItem(Department) Then	// перемещение в дочернюю группу
			
			Message( NStr("en='Attempt of catalog level looping.';ru='Попытка зацикливания уровней справочника.'") );
			Cancel  = True;
			Return;
			
		EndIf;
		
		_Department = New Array;
		
		DepartmentObject = Department.GetObject();
		MovementFromRoot = DepartmentObject.Parent.IsEmpty();
		If NOT DepartmentObject.Parent.IsEmpty() Then
			_Department.Add(DepartmentObject.Parent);
		EndIf;
		DepartmentObject.Parent = NewGroup;
		If NOT NewGroup.IsEmpty() Then
			_Department.Add(NewGroup);
		EndIf;
		Try
			//ПодразделениеОбъект.ВерсияСтруктурыПараметр = ВерсияСтруктуры;
			DepartmentObject.Write();
			// Поменяем родителя в РС Иерархия подразделений
			If NOT StructureVersion = Undefined Then
				RecordSet = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
				RecordSet.Filter.Department.Set(Department);
				RecordSet.Filter.StructureVersion.Set(StructureVersion);
				RecordSet.Read();
				
				For Each SetRecord In RecordSet Do
					SetRecord.DepartmentParent = NewGroup;
				EndDo;
				
				Try
					RecordSet.Write();
				Except
					//Сообщить("Ошибка записи регистра сведений Иерархия подразделений.");
				EndTry;
			EndIf;
			
		Except
			Message( ErrorDescription() );
			Cancel  = True;
		EndTry;
		
		ParametersStructure = GetFromTempStorage(AddressReportExecutionParameters);
		ParametersStructure.Insert("EventDepartment", _Department);
		ParametersStructure.Insert("BranchRefresh");
		If NOT NewGroup.IsEmpty() Then
			ParametersStructure.Insert("MovementPurpose", NewGroup);
		EndIf;
		PutToTempStorage(ParametersStructure, AddressReportExecutionParameters);
		
	EndIf;
	
EndProcedure // ПеремещениеПодразделенияВГруппу()

&AtServer
Procedure DeletionMarkInteractiveControl(Department)

	DepartmentObject = Department.GetObject();
	
	
	Try
		
		DeletedDepartmentsArray = New Array;
		DeletedDepartmentsArray.Add(DepartmentObject.Ref);
		
		ArRec = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
		ArRec.Filter.StructureVersion.Set(Report.StructureVersion);
		ArRec.Filter.Department.Set(Department);
		ArRec.Read();
		If ArRec.Count() = 0 Then
			MarkIsSet = DepartmentObject.DeletionMark;		
		Else
			MarkIsSet = ArRec[0].DeletionMark;		
		EndIf;
		
		UnmarkOnDeletion = MarkIsSet;
		//если же мы снимаеи пометку на удаление, либо у подразделения по текущей версии нет бюджетов, мы меняем запись в регистре
		For Each DeletedDep In DeletedDepartmentsArray Do
			//меняем запись регистра
			IRRecordSet = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
			IRRecordSet.Filter.StructureVersion.Set(Report.StructureVersion);
			IRRecordSet.Filter.Department.Set(DeletedDep);
			IRRecordSet.Read();
			For Each ARecord In IRRecordSet Do
				ARecord.DeletionMark = NOT UnmarkOnDeletion;
			EndDo;
			
			IRRecordSet.Write();
			
			//эмулируем перезапись элемента
			CatObject = DeletedDep.GetObject();
						
			CatObject.AdditionalProperties.Insert("StructureVersion", Report.StructureVersion);
			CatObject.AdditionalProperties.Insert("DeletionMark", NOT UnmarkOnDeletion);
			
			If NOT UnmarkOnDeletion Then
				IRRecordSet = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
				IRRecordSet.Filter.Department.Set(DeletedDep);
				IRRecordSet.Read();
				For Each ARecord In IRRecordSet Do
					ARecord.DeletionMark = True;
				EndDo;
			EndIf;
			
			
			Try
				CatObject.Write();
			Except
				Continue;
			EndTry;
		EndDo;
		
		
		GenerateReportAtServer(,,, True);
	Except
		
		Message( ErrorDescription() );
	EndTry;
	

EndProcedure //ИнтерактивноеУправлениеПометкойУдаления()

&AtServer
Function GetMenuItemsList(Department)
	
	ThisReport = FormAttributeToValue("Report");
	InfoStructure = ThisReport.GetInfoAboutTreeRow(Department, ThisForm.ReportExecutionParameters);
	
	MenuItemsList = New ValueList;
	MenuItemsList.Add("OpenValue",		NStr("en='Open a value';ru='Открыть значение'"));
	
	If IsInRole("FullRights") Then
		If Report.StructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion() Then
			MenuItemsList.Add("MoveInGroup",	NStr("en='Move to group';ru='Переместить в группу'"));
			MenuItemsList.Add("AddChild",	NStr("en='Create subsidiaries';ru='Создать дочернее подразделение'"));
			
			//пометку удаления будем смотреть по регистру
			//СтруктураИнформации.ПодразделениеВетви
			ArRec = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
			ArRec.Filter.StructureVersion.Set(Report.StructureVersion);
			ArRec.Filter.Department.Set(Department);//СтруктураИнформации.ПодразделениеВетви);
			ArRec.Read();
			If ArRec.Count() = 0 Then
				MarkIsSet = Department.DeletionMark;		
			Else
				MarkIsSet = ArRec[0].DeletionMark;		
			EndIf;
			
			MenuItemsList.Add(?(NOT MarkIsSet, "Set", "Reset") + "DeletionMark",	NStr("en='Mark/unmark for deletion';ru='Установка/снятие пометки удаления'"));
		EndIf;
	EndIf;
	
	Return MenuItemsList;
	
EndFunction //ПолучитьСписокПунктовМеню()

&AtServerNoContext
Function GetFormTitle(FormName, AddInfo = "")
	
	_FormName = FormName;
	PointPos = Find(_FormName, ".");
	If PointPos > 0 Then
		
		ObjectID = Left(_FormName, PointPos - 1);
		

		RowWithoutID = Right(_FormName, StrLen(_FormName) - PointPos);
		PointPos = Find(RowWithoutID, ".");
		If PointPos > 0 Then
			
			ObjectName = Left(RowWithoutID, PointPos - 1);
			Return NStr("en='Organizational structure';ru='Организационная структура подразделений'") + " " + AddInfo;
		Else
			
			Return "";
		EndIf;
	Else
		
		Return "";
	EndIf;

EndFunction // ПолучитьЗаголовокФормы()

&AtServerNoContext
Function FindLinkedDepartments(Ref)
	Query = New Query("SELECT UNIQUE
	                      |	MainLinkDepartments.Ref
	                      |In
	                      |	Catalog.Departments.MainLink AS MainLinkDepartments
	                      |WHERE
	                      |	NOT MainLinkDepartments.Ref.DeletionMark
	                      |	AND MainLinkDepartments.Department = &Ref
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT UNIQUE
	                      |	MainLinkDepartments.Department
	                      |In
	                      |	Catalog.Departments.MainLink AS MainLinkDepartments
	                      |WHERE
	                      |	MainLinkDepartments.Ref = &Ref
	                      |	AND NOT MainLinkDepartments.Department.DeletionMark");
	Query.SetParameter("Ref", Ref);
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

&AtServerNoContext
Procedure ChangeLinkedDepartmentParent(Department, LinkedDepartment)
	Object = LinkedDepartment.GetObject();
	ParentCode = Department.Parent.Code;
	NewParentOfLinked = Catalogs.fmDepartments.FindByCode(ParentCode, , , Object.Owner);
	If NOT NewParentOfLinked.IsEmpty() Then
		Object.Parent = NewParentOfLinked;
		Try
			Object.Write();
		Except
			UserMessage = StrTemplate(NStr("en='Error occurred while changing the parent unit for ""%1"" related department of ""%2"" hierarchy type:';ru='Ошибка смены родителя связанного подразделения ""%1"" вида иерархии ""%2"":'"), String(Department), String(Object.Owner));
			Message(UserMessage);
			Message(ErrorDescription());
		EndTry;
	Else
		UserMessage = StrTemplate(NStr("en='A new parent department with code ""%1"" for related department ""%3"" of hierarchy type ""%2""is not found. The parent department is not changed for ""%4"".';ru='Не найдено новое родительское подразделение с кодом ""%1"" для связанного подразделения ""%2"" вида иерархии ""%3"". Смена родителя для ""%4"" не была произведена.'"), ParentCode, String(Department), String(Object.Owner), String(Department));
		Message(UserMessage);
	EndIf;
EndProcedure //СменитьРодителяСвязанногоПодразделения()

&AtClient
Procedure InfoManagerOnChange(Item)
	
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	
EndProcedure // ИнфоМенеджерПриИзменении()

&AtClient
Procedure IncludeMarkedOnDeletionOnChange(Item)
	
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	
EndProcedure

&AtClient
Procedure ChooseReportArbitraryPeriod(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity, IsPeriodicityChange=False) 
	
	BudgetingPeriod = fmReportsClientServer.GetReportPeroidRepresentation(Form.BudgetingPeriodType, 
		BeginOfPeriod, EndOfPeriod, Form);

EndProcedure

&AtClient
Procedure ChooseReportArbitraryBudgetingPeriod_End(PeriodSetting, Parameters) Export

	Form = Parameters.Form;
	
	If NOT PeriodSetting = Undefined Then
	BeginOfPeriod = PeriodSetting.BeginOfPeriod;
	EndOfPeriod  = PeriodSetting.EndOfPeriod;
	
	Form.BudgetingPeriodType = fmReportsClientServer.GetPeriodType(BeginOfPeriod, EndOfPeriod, Form);
	BudgetingPeriod     = fmReportsClientServer.GetReportPeroidRepresentation(Form.BudgetingPeriodType, 
		PeriodSetting.BeginOfPeriod, PeriodSetting.EndOfPeriod, Form);	
	EndIf;
EndProcedure

&AtClient
Procedure PeriodTypeChangeProcessing(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity) Export
	
	If Form.BudgetingPeriodType = Form.AvailableReportPeriods.ArbitraryPeriod Then
		ChooseReportArbitraryPeriod(Form, BeginOfPeriod, EndOfPeriod, MinimumPeriodicity, True);
	Else
		If ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = fmReportsClientServer.ReportBegOfPeriod(Form.BudgetingPeriodType, BeginOfPeriod, Form);
			EndOfPeriod  = fmReportsClientServer.ReportEndOfPeriod(Form.BudgetingPeriodType, BeginOfPeriod, Form);
		Else
			BeginOfPeriod = Undefined;
			EndOfPeriod  = Undefined;
		EndIf;
		
		List = fmReportsClientServer.GetPeriodList(BeginOfPeriod, Form.BudgetingPeriodType, Form);
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
				Form.BudgetingPeriod = ListItem.Presentation;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetingPeriodTypeOnChange(Item)
	PeriodTypeChangeProcessing(ThisForm, Report.BeginningOfBudgetingPeriod,
		Report.EndOfBudgetingPeriod, 
		AvailableReportPeriods.Day);
EndProcedure

&AtClient
Procedure BudgetingPeriodStartChoice(Item, ChoiceData, StandardProcessing)
	If ThisForm.BudgetingPeriodType = ThisForm.AvailableReportPeriods.ArbitraryPeriod Then
		PeriodSettingDialog = New StandardPeriodEditDialog();
		PeriodSettingDialog.Period.BeginDate = Report.BeginningOfBudgetingPeriod;
		PeriodSettingDialog.Period.EndDate = Report.EndOfBudgetingPeriod;
		PeriodSettingDialog.Show(New NotifyDescription("ArbitraryPeriodChoiceEnd", ThisObject, New Structure("PeriodSettingDialog", PeriodSettingDialog)));
	Else
		NotifyDescription = New NotifyDescription("PeriodPresentationStartChoiceEnd", ThisObject);
		fmPeriodChoiceClient.PeriodStartChoice(
		ThisObject, 
		Item, 
		StandardProcessing, 
		BudgetingPeriodType, 
		Report.BeginningOfBudgetingPeriod, 
		NotifyDescription);
	EndIf;
	fmReportsClientServer.SetState(ThisForm);

EndProcedure

&AtClient
Procedure ArbitraryPeriodChoiceEnd(Period, AdditionalParameters) Export
	
	PeriodSettingDialog = AdditionalParameters.PeriodSettingDialog;
	If Period <> Undefined Then 
		BudgetingPeriod = fmReportsClientServer.GetReportPeroidRepresentation(ThisForm.BudgetingPeriodType, 
			BegOfDay(PeriodSettingDialog.Period.BeginDate), EndOfDay(PeriodSettingDialog.Period.EndDate), ThisForm);
		Report.BeginningOfBudgetingPeriod = PeriodSettingDialog.Period.BeginDate;
		Report.EndOfBudgetingPeriod  = PeriodSettingDialog.Period.EndDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoiceEnd(PeriodStructure, AdditionalParameters) Export
	
	// Установим полученный период
	If PeriodStructure <> Undefined Then
		BudgetingPeriod  = fmReportsClientServer.GetReportPeroidRepresentation(ThisForm.BudgetingPeriodType, 
			BegOfDay(PeriodStructure.BeginOfPeriod), EndOfDay(PeriodStructure.EndOfPeriod), ThisForm);
		//Элементы.СравниваемыеДанные.ТекущиеДанные.Период = СтруктураПериода.Период;
		Report.BeginningOfBudgetingPeriod = BegOfDay(PeriodStructure.BeginOfPeriod);
		Report.EndOfBudgetingPeriod = EndOfDay(PeriodStructure.EndOfPeriod);

	EndIf;
	
	Modified = True;
	
	
EndProcedure

&AtClient
Procedure NegativeNumbersPresentationOnChange(Item)
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
EndProcedure

&AtClient
Procedure ColorFillOnChange(Item)
	fmReportsClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
EndProcedure


