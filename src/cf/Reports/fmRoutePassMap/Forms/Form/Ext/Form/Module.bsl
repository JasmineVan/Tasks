
&AtServer
// Процедура вывода отчета
//
Procedure OutputReport()
	RoutePassingMap = FormAttributeToValue("Report");
	RoutePassingMap.WebClient        = True;
	RoutePassingMap.GenerateReport(SpreadsheetDocumentField);
	DetailsList = RoutePassingMap.DetailsList;
	Report.Comments = RoutePassingMap.Comments;
EndProcedure

&AtClient
// Процедура обработчика расшифровки отчета
//
Procedure SpreadsheetDocumentFieldDetailProcessing(Item, DetailsID, StandardProcessing)
	
	StandardProcessing = False;
	Return;
	
	Details = GetDetails(DetailsList, DetailsID);
	
	If TypeOf(Details) = Type("Structure") AND Details.Property("StageDetail") Then
		
		If ValueIsFilled(Details.Period) Then 
			
			Department = Undefined;
			If Details.Departments.Count() = 1 Then 
				Department = Details.Departments[0];
			ElsIf Details.Departments.Count() > 1 Then 
				DepartmentList = New ValueList();
				DepartmentList.LoadValues(Details.Departments);
				Result = ChooseFromMenu(DepartmentList, Item);
				If Result = Undefined Then 
					Return;
				Else
					Department = Result.Value;
				EndIf;
			Else
				Return;
			EndIf;
			
			DimensionValues = New Structure();
			DimensionValues.Insert("Period", Details.Period);
			DimensionValues.Insert("RouteDocument", Details.RouteDocument);
			DimensionValues.Insert("RouteModel", Details.RouteModel);
			DimensionValues.Insert("RoutePoint", Details.RoutePoint);
			DimensionValues.Insert("Department", Department);
			ParametersArray = New Array();
			ParametersArray.Add(DimensionValues);
			RecordKey = New(Type("InformationRegisterRecordKey.fmRouteStates"), ParametersArray);
			FormParameters = New Structure("Key", RecordKey);
			
			OpenForm("InformationRegister.fmRouteStates.Form.RecordForm", FormParameters, ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			
			OutputReport();
			DetailsOpening = True;
			
		Else 
			// открытие пустой записи
			// сохранено на случай возможности перехода на произвольную
			// точку согласования
			//ПараметрыФормы = Новый Структура();
			//ПараметрыФормы.Вставить("ДосрочноеСогласование", Истина);
			//ПараметрыФормы.Вставить("ДокументМаршрута", Расшифровка.ДокументМаршрута);
			//ПараметрыФормы.Вставить("МодельМаршрута", Расшифровка.МодельМаршрута);
			//ПараметрыФормы.Вставить("ТочкаМаршрута", Расшифровка.ТочкаМаршрута);
			
			//ОткрытьФормуМодально("РегистрСведений.СостоянияПрохожденияМаршрута.Форма.ФормаЗаписи", ПараметрыФормы);
			//
			//ВывестиОтчет();
			//
			//ОткрытиеРасшифровки = Истина;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
// Процедура - обработчик события "ДокументПроцессаПриИзменении"
//
Function GetDocumentName(Ref)
	Return Ref.Metadata().Name;
EndFunction // ПолучитьИмяДокумента()

&AtServerNoContext
// Процедура - обработчик события "ДокументПроцессаПриИзменении"
//
Function GetDetails(DetailsList, IndexOf)
	
	Try 
		Result = DetailsList[Number(String(IndexOf))].Value;
	Except
		Result = IndexOf;
	EndTry;
	
	Return Result;
	
EndFunction // ПолучитьРасшифровку()

&AtServerNoContext
// Процедура - обработчик события "ДокументПроцессаПриИзменении"
//
Procedure ProcessDocumentOnChange(RouteDocument, RouteModel)
	If ValueIsFilled(RouteDocument) Then
		RouteDocumentRouteModel = RouteDocument.AgreementRoute;
		If ValueIsFilled(RouteDocumentRouteModel) Then
			RouteModel = RouteDocumentRouteModel;
		EndIf;
	EndIf;
EndProcedure // ДокументПроцессаПриИзменении()

&AtServerNoContext
// Процедура - обработчик события "ШаблонПроцессаНачалоВыбора"
//
Function GetRouteModelFilter(RouteDocument, RouteModel)
	Query = New Query("SELECT ALLOWED DISTINCT
	                      |	PassingRouteStates.AgreementRoute AS AgreementRoute
	                      |FROM
	                      |	InformationRegister.fmRouteStates AS PassingRouteStates
	                      |WHERE
	                      |	PassingRouteStates.Document = &RouteDocument");
	Query.SetParameter("RouteDocument", RouteDocument);
	FilterList = New ValueList();
	FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("AgreementRoute")); 
	Return FilterList;
EndFunction // ШаблонПроцессаНачалоВыбора()

&AtClient
// Обработчик события ДокументМаршрутаПриИзменении
//
Procedure RouteDocumentOnChange(Item)
	ProcessDocumentOnChange(Report.RouteDocument, Report.RouteModel);
EndProcedure // ДокументМаршрутаПриИзменении()

&AtClient
// Обработчик события МодельМаршрутаНачалоВыбора
//
Procedure RouteModelStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(Report.RouteDocument) Then		
		
		FilterList = GetRouteModelFilter(Report.RouteDocument, Report.RouteModel);
		
		If FilterList.Count() = 0 Then
			CommonClientServer.MessageToUser(NStr("en='The document did NOT undergo any of the approval routes.';ru='Указанный документ НЕ проходил ни по одному Из маршрутов согласования!'"));
			Return;
		Else
			
			ChoiceForm = GetForm("Catalog.fmAgreementRoutes.ChoiceForm", , Item);
			
			NewFilter = ChoiceForm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			NewFilter.LeftValue    = New DataCompositionField("Ref");
			NewFilter.ComparisonType     = DataCompositionComparisonType.InList;
			NewFilter.RightValue   = FilterList;
			NewFilter.Use    = True;
			NewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			
			ChoiceForm.Items.List.CurrentRow = Report.RouteModel;
			ChoiceForm.Open();
			
		EndIf;	
	Else
		CommonClientServer.MessageToUser(NStr("en='You should specify the route document.';ru='Необходимо указать документ маршрута!'"));
		Return;
	EndIf;
EndProcedure // ДокументМаршрутаПриИзменении()

&AtClient
// Обработчик события Настройка
//
Procedure Generate(Command)
	If NOT ValueIsFilled(Report.RouteDocument) Then 
		CommonClientServer.MessageToUser(NStr("en='The document is not filled in.';ru='Не заполнен документ.'"));
		Return;
	EndIf;
	If NOT ValueIsFilled(Report.RouteModel) Then 
		CommonClientServer.MessageToUser(NStr("en='The approval route is not filled in.';ru='Не заполнен маршрут согласования.'"));
		Return;
	EndIf;
	OutputReport();
EndProcedure

&AtClient
// Обработчик события Настройка
//
Procedure Setting(Command)
	SettingForm = GetForm("Report.fmRoutePassMap.Form.ReportSetting");
	FillPropertyValues(SettingForm, Report);
	Result = SettingForm.DoModal();
	If Result <> Undefined AND Result Then
		FillPropertyValues(Report, SettingForm);
		OutputReport();
	EndIf;
EndProcedure // Настройка()

&AtServer
// Обработчик события ПриСозданииНаСервере
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("RouteModel") Then 
		Report.RouteModel = Parameters.RouteModel;
	EndIf;
	If Parameters.Property("Version") Then 
		Report.Version = Parameters.Version;
	EndIf;
	If Parameters.Property("RefToDocument") Then 
		Report.RouteDocument = Parameters.RefToDocument;
		If NOT ValueIsFilled(Report.RouteModel) Then 
			Report.RouteModel = Report.RouteDocument.AgreementRoute;
		EndIf;
	EndIf;
	If ValueIsFilled(Report.RouteDocument) AND ValueIsFilled(Report.RouteModel) Then 
		OutputReport();
	EndIf;
	DetailsOpening = False;
EndProcedure // ПриСозданииНаСервере()

