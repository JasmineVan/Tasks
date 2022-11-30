
////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ОБЪЕКТА

// Процедура обработчик "ОбработкаПроверкиЗаполнения" 
//
Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Временное свойство для проведения обновления ИБ.
	IBUpdate = False;
	If AdditionalProperties.Property("IBUpdate", IBUpdate) AND IBUpdate Then
		Return;
	EndIf;
	
	// При необходимости проверим заполнение реквизита БалансоваяЕдиница
	If AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedDepartment
	AND NOT ValueIsFilled(Department) Then
		CommonClientServer.MessageToUser(NStr("en='The ""Department"" field is not filled in';ru='Поле ""Подразделение"" не заполнено'"), , , , Cancel);
	EndIf;
	
	// При необходимости проверим заполнение ответственного в БалансоваяЕдиница
	If AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedDepartment 
		AND ValueIsFilled(Department) Then
		fmProcessManagement.GetDepartmentResponsible(Department); 
	EndIf;
	
	// При необходимости проверим заполнение реквизита Пользователь
	If AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedUser
	AND NOT ValueIsFilled(User) Then	
		CommonClientServer.MessageToUser(NStr("en='The ""User"" field is not filled in';ru='Поле ""Пользователь"" не заполнено'"), , , , Cancel);
	EndIf;
	
	// При необходимости проверим заполнение реквизита Тип управления
	If AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.ManageType
	AND NOT ValueIsFilled(ManageType) Then
		CommonClientServer.MessageToUser(NStr("en='The ""Management type"" field is not filled in';ru='Поле ""Тип управления"" не заполнено'"), , , , Cancel);
	EndIf;
	
	// Проверим возможность записи точки маршрута по точкам-предшественникам.
	For Each CurRow In PointsPredecessors Do
		If NOT CurRow.RoutePoint.Owner = Owner Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='In row number %1, the predecessor point belonging to the other route is specified.';ru='В строке номер %1 указана точка-предшественник из другого маршрута!'"), CurRow.LineNumber), , , , Cancel);
		EndIf;
		
		If CurRow.RoutePoint = Ref Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='In row number %1, the stored point is specified as a predecessor point.';ru='В строке номер %1 в качестве точки-предшественника указана сохраняемая точка!'"), CurRow.LineNumber), , , , Cancel);
		EndIf;	
	EndDo;
	
	// Проверим выбранное состояние согласования по умолчанию.
	If ValueIsFilled(AgreementState) Then
		If NOT AgreementState.Owner = Ref Then
			CommonClientServer.MessageToUser(NStr("en='The specified approval status does not apply to this point by default.';ru='Указанное состояние согласования по умолчанию не относится к данной точке!'"), , , , Cancel);
		EndIf;
		If NOT AgreementState.StageCompleted = 1 Then
			CommonClientServer.MessageToUser(NStr("en='The specified approval status is not an approval status by default.';ru='Указанное состояние согласования по умолчанию не является состоянием согласования!'"), , , , Cancel);
		EndIf;	
	EndIf;	
	
	// Проверим выбранное состояние отклонения по умолчанию.
	If ValueIsFilled(DeviationState) Then
		If NOT DeviationState.Owner = Ref Then
			CommonClientServer.MessageToUser(NStr("en='The specified deviation status does not apply to this point by default.';ru='Указанное состояние отклонения по умолчанию не относится к данной точке!'"), , , , Cancel);
		EndIf;
		If NOT DeviationState.StageCompleted = 0 Then
			CommonClientServer.MessageToUser(NStr("en='The specified deviation status is not a deviation status by default.';ru='Указанное состояние отклонения по умолчанию не является состоянием отклонения!'"), , , , Cancel);
		EndIf;
	EndIf;
	
	// Если точка является точкой входа в маршрут согласования.
	If PointsPredecessors.Count() = 0 Then
		// Проверим доступ - для первой точки без ограничений.
		If NOT AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.NoLimit Then
			CommonClientServer.MessageToUser(NStr("en='For the route start point, the ""Without restrictions"" access type can be set only.';ru='Для начальной точки маршрута может быть установлен только вид доступа ""Без ограничений""!'"), , , , Cancel);
		EndIf;	
		// Проверим общее количество точек входа в данный маршрут при необходимости.
		InitialPoints = fmProcessManagement.GetInitialRouteModelPoints(Owner);
		If InitialPoints.Count()>0 Then 
			If NOT InitialPoints[0].Point = Ref Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Entry point ""%1"" for this route already exists. Can you specify the predecessor point, please?';ru='Для данного маршрута уже имеется точка входа ""%1"". Укажите точки-предшественники!'"), TrimAll(InitialPoints[0].Point)), , , , Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	// Для нового объекта удалим проверку точек по умолчанию, так как создадим их.
	Если IsNew() Тогда
		CommonClientServer.DeleteValueFromArray(CheckingAttributes, "AgreementState");
		CommonClientServer.DeleteValueFromArray(CheckingAttributes, "DeviationState");
	КонецЕсли;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	WritePoint = False;
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	""Agr"" AS Field1
	|FROM
	|	Catalog.fmRoutePointsStates AS RoutePointsStates
	|WHERE
	|	RoutePointsStates.StageCompleted = 1
	|	AND RoutePointsStates.Owner = &Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	""Dev"" AS Field1
	|FROM
	|	Catalog.fmRoutePointsStates AS RoutePointsStates
	|WHERE
	|	RoutePointsStates.StageCompleted = 0
	|	AND RoutePointsStates.Owner = &Owner";
	Query.SetParameter("Owner", Ref);
	Result = Query.ExecuteBatch();
	
	If Result[0].IsEmpty() Then
		NewState = Catalogs.fmRoutePointsStates.CreateItem();
		NewState.Owner = Ref;
		NewState.StageCompleted = 1;
		NewState.Description = NStr("en='Approved';ru='Согласован'");
		NewState.ColorType = "Absolute";
		NewState.Red = 200;
		NewState.Green = 250;
		NewState.Blue   = 200;
		
		Try
			NewState.Write();
			If NOT ValueIsFilled(AgreementState) Then 
				AgreementState = NewState.Ref;
				WritePoint = True;
			EndIf;
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to create the approval point.';ru='Не удалось создать точку согласования!'"));
		EndTry;
		
	EndIf;
	
	If Result[1].IsEmpty() Then
		NewState = Catalogs.fmRoutePointsStates.CreateItem();
		NewState.Owner = Ref;
		NewState.StageCompleted = 0;
		NewState.Description = NStr("en='Rejected';ru='Отклонен'");
		NewState.ColorType = "Absolute";
		NewState.Red = 250;
		NewState.Green = 200;
		NewState.Blue   = 200;
		
		Try
			NewState.Write();
			If NOT ValueIsFilled(DeviationState) Then 
				DeviationState = NewState.Ref;
				WritePoint = True;
			EndIf;
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to create the deviation point.';ru='Не удалось создать точку отклонения!'"));
		EndTry;
		
	EndIf;
	
	If WritePoint Then 
		Write();
	EndIf;
	
EndProcedure

Procedure OnCopy(CopyObject)
	AgreementState = Catalogs.fmRoutePointsStates.EmptyRef();
	DeviationState   = Catalogs.fmRoutePointsStates.EmptyRef();
EndProcedure

