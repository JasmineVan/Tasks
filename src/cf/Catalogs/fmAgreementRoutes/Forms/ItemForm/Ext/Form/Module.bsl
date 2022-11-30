
&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//РедактированиеРазрешено = РедактированиеРазрешено(Параметры.Ключ);
	EditingIsAllowed = True;
	Items.SpreadsheetDocumentField.ReadOnly = NOT EditingIsAllowed;
	
	Parameters.CopyObject = Parameters.CopyingValue;
	If NOT Parameters.Key.IsEmpty() Then 
		OutputReport();
	Else
		Items.SpreadsheetDocumentField.StatePresentation.Visible = True;
		Items.SpreadsheetDocumentField.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		Items.SpreadsheetDocumentField.StatePresentation.Text = NStr("en='It is necessary to save the route to add some route points!';ru='Для добавления точек маршрута необходимо сохранить маршрут!'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EditingIsAllowed(Ref)
	
	If NOT ValueIsFilled(Ref) Then 
		Return True;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	PassingRouteStates.AgreementRoute
	|FROM
	|	InformationRegister.fmRouteStates AS PassingRouteStates
	|WHERE
	|	PassingRouteStates.AgreementRoute = &AgreementRoute";
	Query.SetParameter("AgreementRoute", Ref);
	Return Query.Execute().IsEmpty();
	
EndFunction

&AtServer
// Процедура обработчик "ПриЗаписиНаСервере" 
//
Procedure OnWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	If ValueIsFilled(Parameters.CopyObject) Then
		ErrorHeader = StrTemplate(NStr("en='Approval route: ""%1"" cannot be saved:';ru='Маршрут согласования: ""%1"" не может быть записан:'"), CurrentObject.Ref);
		CopyBudgetLinkedInfo(Parameters.CopyObject, Cancel, CurrentObject.Ref, ErrorHeader);
	EndIf;
	
EndProcedure

&AtServer
// Процедура обработчик "КопироватьМаршрутСервер" 
//
Procedure CopyBudgetLinkedInfo(RouteModel, Cancel, NewRoute, ErrorHeader)
	
	PointsMap = New Map();
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	RoutesPoints.Description AS Description,
	|	RoutesPoints.Department AS Department,
	|	RoutesPoints.AccessTypeToRoutePoint AS AccessTypeToRoutePoint,
	|	RoutesPoints.DepartmentLevel AS DepartmentLevel,
	|	RoutesPoints.User AS User,
	|	RoutesPoints.AgreementState AS AgreementState,
	|	RoutesPoints.DeviationState AS DeviationState,
	|	RoutesPoints.ManageType AS ManageType,
	|	RoutesPoints.Ref AS Ref,
	|	RoutesPoints.PointsPredecessors.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		RoutePoint AS RoutePoint
	|	) AS PointsPredecessors
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	RoutesPoints.Owner = &Owner
	|	AND NOT RoutesPoints.DeletionMark";
	
	Query.SetParameter("Owner", RouteModel);
	Result = Query.Execute();
	
	Points = Result.SELECT();
	
	While Points.Next() Do
		
		NewPoint = Catalogs.fmRoutesPoints.CreateItem();
		
		NewPoint.Owner                 = NewRoute.Ref;
		NewPoint.Description             = Points.Description;
		NewPoint.AccessTypeToRoutePoint = Points.AccessTypeToRoutePoint;
		NewPoint.User             = Points.User;
		NewPoint.Department            = Points.Department;
		NewPoint.DepartmentLevel     = Points.DepartmentLevel;
		NewPoint.ManageType         = Points.ManageType;
		
		Try
			NewPoint.Write();
			PointsMap.Insert(Points.Ref, NewPoint.Ref);
		Except
			CommonClientServer.MessageToUser(ErrorDescription(), , , , Cancel);
			RollbackTransaction();
			Return;
		EndTry;
		
	EndDo;
	
	Points.Reset();
	While Points.Next() Do
		
		CurPoint = PointsMap.Get(Points.Ref).GetObject();
		
		For Each RowPointPredecessor In Points.PointsPredecessors.Unload() Do
			NewLine = CurPoint.PointsPredecessors.Add();
			NewLine.RoutePoint = PointsMap.Get(RowPointPredecessor.RoutePoint);
		EndDo;
		
		Try
			CurPoint.Write();
		Except
			CommonClientServer.MessageToUser(ErrorDescription(), , , , Cancel);
			RollbackTransaction();
			Return;
		EndTry;
		
	EndDo;
	
	Parameters.CopyObject = PredefinedValue("Catalog.fmAgreementRoutes.EmptyRef");
	
EndProcedure

&AtServer
// Процедура вывода отчета
//
Procedure OutputReport()
	
	If NOT EditingIsAllowed Then 
		Items.SpreadsheetDocumentField.StatePresentation.Visible                      = True;
		Items.SpreadsheetDocumentField.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		Items.SpreadsheetDocumentField.StatePresentation.Text = NStr("en='There is coordinated data on this route. Editing is prohibited.';ru='По данному маршруту есть согласованные данные. Редактирование запрещено!'");
	Else
		Items.SpreadsheetDocumentField.StatePresentation.Visible                      = False;
		Items.SpreadsheetDocumentField.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	EndIf;
	
	RoutePassingMap = Reports.fmRouteMap.Create();
	RoutePassingMap.RouteModel = Object.Ref;
	RoutePassingMap.WebClient        = True;
	RoutePassingMap.GenerateReport(SpreadsheetDocumentField);
	DetailsList = RoutePassingMap.DetailsList;
	StagesList.Load(RoutePassingMap.StagesTS);
	StagesList.Clear();
	For Each Point In RoutePassingMap.StagesTS Do
		NewLine = StagesList.Add();
		NewLine.Stage = Point.Stage;
		NewLine.LevelL = Point.LevelL;
		NewLine.PointsPredecessors.Load(Point.PointsPredecessors);
	EndDo;
	
EndProcedure

&AtClient
// Процедура обработчика расшифровки отчета
//
Procedure SpreadsheetDocumentFieldDetailProcessing(Item, DetailsID, StandardProcessing)
	
	If NOT EditingIsAllowed Then 
		StandardProcessing = False;
		Return;
	EndIf;
	
	Details = GetDetails(DetailsList, DetailsID);
	
	If TypeOf(Details) = Type("Structure") Then 
		
		StandardProcessing = False;
		
		ChoiceListForConnection = DefinePointsListForConnection(Details.RoutePoint);
		
		MenuList = New ValueList();
		MenuList.Add("Open", "Open", , PictureLib.Magnifier);
		MenuList.Add("Add", "Add next point", , PictureLib.AddListItem);
		If ChoiceListForConnection.Count() > 0 Then 
			MenuList.Add("AddExisting", NStr("en='Connect with the point of the lower level';ru='Соединить с точкой нижнего уровня'"), , PictureLib.NewWindow);
		EndIf;
		If StagesList.Count() > 1 Then 
			MenuList.Add("Delete", NStr("en='Delete';ru='Удалить'"), , PictureLib.DeleteListItem);
		EndIf;
		AddParameters = New Structure("Details, ChoiceListForConnection", Details, ChoiceListForConnection);
		ND = New NotifyDescription("AfterMenuChoice", ThisObject, AddParameters);
		ShowChooseFromMenu(ND, MenuList, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterMenuChoice(Result, AddParameters) Export
	
	If Result <> Undefined Then 
		If Result.Value = "Open" Then 
			OpenForm("Catalog.fmRoutesPoints.ObjectForm", New Structure("Key", AddParameters.Details.RoutePoint), , , , , New NotifyDescription("AfterFormClose", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
		ElsIf Result.Value = "Add" Then 
			OpenForm("Catalog.fmRoutesPoints.ObjectForm", AddParameters.Details, ThisForm, , , , New NotifyDescription("AfterFormClose", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
		ElsIf Result.Value = "AddExisting" Then
			ND = New NotifyDescription("AfterItemChoice", ThisObject, New Structure("Details", AddParameters.Details));
			AddParameters.ChoiceListForConnection.ShowChooseItem(ND, "Select Item");
		ElsIf Result.Value = "Delete" Then
			ND = New NotifyDescription("AfterQueryShow", ThisObject, New Structure("Details", AddParameters.Details));
			ShowQueryBox(ND, StrTemplate(NStr("en='Do you want to delete route point ""%1""?';ru='Удалить точку маршрута ""%1""?'"), TrimAll(AddParameters.Details.RoutePoint)), QuestionDialogMode.YesNo);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterFormClose(Result, AddParameters) Export
	OutputReport();
EndProcedure

&AtClient
Procedure AfterItemChoice(Result, AddParameters) Export
	If Result <> Undefined Then 
		AddExistingStageServer(Result.Value, AddParameters.Details.RoutePoint);
		OutputReport();
	EndIf;	
EndProcedure

&AtClient
Procedure AfterQueryShow(Result, AddParameters) Export
	If Result = DialogReturnCode.Yes Then
		DeleteStage(AddParameters.Details.RoutePoint);
		OutputReport();
	EndIf;	
EndProcedure

&AtClient
Function DefinePointsListForConnection(RoutePoint)
	
	ChoiceList = New ValueList();
	
	FoundStages = StagesList.FindRows(New Structure("Stage", RoutePoint));
	If FoundStages.Count() > 0 Then 
		LevelL = FoundStages[0].LevelL;
		
		ChoiceList = New ValueList();
		For Each Stage In StagesList Do
			If Stage.LevelL > LevelL AND 
				Stage.PointsPredecessors.FindRows(New Structure("RoutePoint", RoutePoint)).Count() = 0 Then 
				ChoiceList.Add(Stage.Stage);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return ChoiceList;
	
EndFunction

&AtServerNoContext
Procedure AddExistingStageServer(RoutePoint, Predecessor)
	
	PointObject = RoutePoint.GetObject();
	Try
		NewLine = PointObject.PointsPredecessors.Add();
		NewLine.RoutePoint = Predecessor;
		PointObject.Write();
	Except
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to delete the point. %1';ru='Не удалось удалить точку.  %1'"), ErrorDescription()));
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure DeleteStage(RoutePoint)
	
	BeginTransaction();
	
	PointObject = RoutePoint.GetObject();
	
	Try
		PointObject.SetDeletionMark(True);
	Except
		RollbackTransaction();
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to delete the point. %1';ru='Не удалось удалить точку.  %1'"), ErrorDescription()));
		Return;
	EndTry;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	RoutesPointsPointsPredecessors.Ref AS Ref
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|WHERE
	|	RoutesPointsPointsPredecessors.RoutePoint = &RoutePoint
	|	AND NOT RoutesPointsPointsPredecessors.Ref.DeletionMark
	|
	|GROUP BY
	|	RoutesPointsPointsPredecessors.Ref";
	Query.SetParameter("RoutePoint", RoutePoint);
	Result =Query.Execute().SELECT();
	While Result.Next() Do
		
		PointObject = Result.Ref.GetObject();
		DeletedRowsArray = PointObject.PointsPredecessors.FindRows(New Structure("RoutePoint", RoutePoint));
		For Each CurRow In DeletedRowsArray Do
			PointObject.PointsPredecessors.Delete(CurRow);
		EndDo;
		
		If PointObject.PointsPredecessors.Count() = 0 Then
			For Each CurRow In RoutePoint.PointsPredecessors Do
				NewLine = PointObject.PointsPredecessors.Add();
				NewLine.RoutePoint = CurRow.RoutePoint;
			EndDo;
		EndIf;
		
		If PointObject.PointsPredecessors.Count() = 0 Then 
			PointObject.AccessTypeToRoutePoint = Enums.AccessTypeToRoutePoint.NoLimit;
		EndIf;
		
		Try
			PointObject.Write();
		Except
			RollbackTransaction();
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to delete the point. %1';ru='Не удалось удалить точку.  %1'"), ErrorDescription()));
			Return;
		EndTry;
	EndDo;
	
	CommitTransaction();
	
EndProcedure

&AtServerNoContext
// Процедура - обработчик события "ДокументПроцессаПриИзменении"
//
Function GetDetails(DetailsList, IndexOf)
	
	If TypeOf(IndexOf) = Type("DataCompositionDetailsID") Then 
		Result = DetailsList[Number(String(IndexOf))].Value;
	ElsIf TypeOf(IndexOf) = Type("Number") Then 
		Result = DetailsList[IndexOf].Value;
	Else
		Result = IndexOf;
	EndIf;
	
	Return Result;
	
EndFunction // ПолучитьРасшифровку()

&AtServer
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)
	
	EditingIsAllowed = EditingIsAllowed(Parameters.Key);
	Items.SpreadsheetDocumentField.ReadOnly = NOT EditingIsAllowed;
	
	// Если у маршрута нет точек, 
	// создадим начальную точку автоматически
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	RoutesPoints.Ref
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	RoutesPoints.Owner = &Owner";
	Query.SetParameter("Owner", Object.Ref);
	Result = Query.Execute().SELECT();
	
	If NOT Result.Next() Then 
		
		InitialPoint = Catalogs.fmRoutesPoints.CreateItem();
		InitialPoint.Owner = Object.Ref;
		InitialPoint.Description = NStr("en='Start of approval';ru='Старт согласования'");
		InitialPoint.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.NoLimit;
		Try
			InitialPoint.Write();
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to create the start point of the route.';ru='Не удалось создать начальную точку маршрута.'"));
		EndTry;
		
	EndIf;
	
	OutputReport();
	
EndProcedure

&AtClient
// Процедура обработчик команды "Проверить" 
//
Procedure Check(Command)
	If ValueIsFilled(Object.Ref) Then
		fmProcessManagement.RouteCorrectnessCheck(Object.Ref);
	Else
		CommonClientServer.MessageToUser(NStr("en='You should save the route.';ru='Необходимо сохранить маршрут!'"));
	EndIf;
EndProcedure


