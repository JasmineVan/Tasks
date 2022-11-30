
&AtServer
// Процедура установки доступности формы
//
Procedure SetFormAvailability()
	// Если состояние точки указано, то редактировать может только последнее звено.
	If EditAllowed Then
		If ValueIsFilled(Record.PointState) Then
			ReadOnly = True;
		ElsIf Parameters.AheadAgreement Then
			ReadOnly = True;
		Else
			ReadOnly = False;
		EndIf;
	Else	
		ReadOnly = True;
	EndIf;	
EndProcedure // УстановитьДоступностьФормы()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
// Процедура обработчик "ПередЗаписьюНаСервере" 
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	// При досрочном согласовании можно только утвердить.
	If Parameters.AheadAgreement AND Record.PointState.StageCompleted <> 1 Then
		CommonClientServer.MessageToUser("Допустимо только досрочное согласование документа!", , , ,Cancel);
	EndIf;
	
	// Проверим указание состояния для точки маршрута.
	If NOT ValueIsFilled(Record.PointState) Then
		CommonClientServer.MessageToUser("Не заполнено состояние точки!", , , ,Cancel);
	EndIf;
	
	// Проверим, а есть ли в БД такая точка.
	If NOT Parameters.AheadAgreement Then
		QueryCheck = New Query(
		"SELECT
		|	PassingRouteStates.PointState
		|FROM
		|	InformationRegister.fmRouteStates AS PassingRouteStates
		|WHERE
		|	PassingRouteStates.Document = &Document
		|	AND PassingRouteStates.AgreementRoute = &AgreementRoute
		|	AND PassingRouteStates.RoutePoint = &RoutePoint
		|	AND PassingRouteStates.Period = &Period");
		QueryCheck.SetParameter("Document", Record.Document);
		QueryCheck.SetParameter("RouteModel", Record.AgreementRoute);
		QueryCheck.SetParameter("RoutePoint", Record.RoutePoint);
		QueryCheck.SetParameter("Period", InitialPeriod);
		Result = QueryCheck.Execute().SELECT();
		If NOT Result.Next() Then
			CommonClientServer.MessageToUser("Данная точка маршрута была удалена при возврате или досрочном согласовании!", , , ,Cancel);
			Return;
		EndIf;
	EndIf;
	
	// Установим дату изменения состояния точки.
	CurrentObject.Period = CurrentSessionDate();
	
EndProcedure

&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Определим некоторые параметры при открытии формы.
	CurUser = SessionParameters.CurrentUser;
	InitialPeriod = Record.Period;
	
	If NOT ValueIsFilled(Record.Document) Then
		CommonClientServer.MessageToUser("Интерактивное добавление запрещено!", Cancel);
		Return;
	EndIf;
	
	QueryPointParameters = New Query(
	"SELECT ALLOWED
	|	RoutesPoints.Ref AS RoutePoint,
	|	RoutesPoints.AccessTypeToRoutePoint AS AccessType,
	|	RoutesPoints.DepartmentLevel,
	|	RoutesPoints.User,
	|	RoutesPoints.Department,
	|	RoutesPoints.ManageType,
	|	Value(Catalog.fmDepartments.EmptyRef) AS DocumentDepartment
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	RoutesPoints.Ref = &RoutePoint
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	fmResponsiblesReplacements.Responsible
	|FROM
	|	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	|WHERE
	|	fmResponsiblesReplacements.ResponsibleReplacing = &CurUser
	|	AND (fmResponsiblesReplacements.BeginDate <= &CurrentDate
	|			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	|	AND (fmResponsiblesReplacements.EndDate >= &CurrentDate
	|			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))");
	
	QueryPointParameters.SetParameter("Document", Record.Document);
	QueryPointParameters.SetParameter("RoutePoint", Record.RoutePoint);
	QueryPointParameters.SetParameter("CurUser", CurUser);
	QueryPointParameters.SetParameter("CurrentDate", BegOfDay(CurrentDate()));
	ResultBatch = QueryPointParameters.ExecuteBatch();
	PointParameters = ResultBatch[0].Unload();
	PointParameters[0].DocumentDepartment = Record.Department;
	ReplacingList = ResultBatch[1].Unload().UnloadColumn("Responsible");
	
	EditAllowed = NOT fmProcessManagement.DenyPointProcessing(PointParameters[0], CurUser, ReplacingList, CurrentSessionDate());
	FinalStage = fmProcessManagement.FinalStage(Record.RoutePoint);
	
	SetFormAvailability();
	
EndProcedure

&AtServer
// Процедура обработчик "ПослеЗаписиНаСервере" 
//
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)
	SetFormAvailability();
EndProcedure
