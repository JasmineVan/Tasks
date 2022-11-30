
&AtServer
// Процедура вывода отчета
//
Procedure OutputReport()
	RoutePassingMap = FormAttributeToValue("Report");
	RoutePassingMap.WebClient        = True;
	RoutePassingMap.GenerateReport(SpreadsheetDocumentField);
	DetailsList = RoutePassingMap.DetailsList;
	StagesList.Load(RoutePassingMap.StagesTS); 
EndProcedure

&AtClient
// Процедура обработчика расшифровки отчета
//
Procedure SpreadsheetDocumentFieldDetailProcessing(Item, DetailsID, StandardProcessing)
	
	Details = GetDetails(DetailsList, DetailsID);
	
	If TypeOf(Details) = Type("Structure") Then 
		
		StandardProcessing = False;
		
		ShowValue(, Details.RoutePoint);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddExistingStage(RoutePoint)
	
	FoundStages = StagesList.FindRows(New Structure("Stage", RoutePoint));
	If FoundStages.Count() > 0 Then 
		LevelL = FoundStages[0].LevelL;
		
		ChoiceList = New ValueList();
		For Each Stage In StagesList Do
			If Stage.LevelL > LevelL Then 
				ChoiceList.Add(Stage.Stage);
			EndIf;
		EndDo;
		
		If ChoiceList.Count() > 0 Then 
			Result = ChoiceList.ChooseItem(NStr("en='Select item';ru='Select Item'"));
			If Result <> Undefined Then 
				AddExistingStageServer(Result.Value, RoutePoint);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddExistingStageServer(RoutePoint, Predecessor)
	
	PointObject = RoutePoint.GetObject();
	Try
		NewLine = PointObject.PointsPredecessors.Add();
		NewLine.RoutePoint = Predecessor;
		PointObject.Write();
	Except
		CommonClientServer.MessageToUser(NStr("en='Failed to delete the point.';ru='Не удалось удалить точку. '") + ErrorDescription());
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
		CommonClientServer.MessageToUser(NStr("en='Failed to delete the point.';ru='Не удалось удалить точку. '")  + ErrorDescription());
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
			PointObject.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.NoLimit;
		EndIf;
		
		Try
			PointObject.Write();
		Except
			RollbackTransaction();
			CommonClientServer.MessageToUser(NStr("en='Failed to delete the point.';ru='Не удалось удалить точку. '")  + ErrorDescription());
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

&AtClient
// Обработчик события Настройка
//
Procedure Generate(Command)
	OutputReport();
EndProcedure

&AtClient
// Обработчик события Настройка
//
Procedure Setting(Command)
	SettingForm = GetForm("Report.fmRouteMap.Form.ReportSetting");
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
	If ValueIsFilled(Report.RouteModel) Then
		OutputReport();
	EndIf;
	DetailsOpening = False;
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnOpen(Cancel)
	If FormOwner <> Undefined Then 
		Items.RouteModel.Visible = False;
	EndIf;
EndProcedure




