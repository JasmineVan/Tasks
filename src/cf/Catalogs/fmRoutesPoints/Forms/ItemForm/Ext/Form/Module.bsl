
&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Route")
		AND Parameters.Property("RoutePoint") Then 
		Object.Owner = Parameters.Route;
		NewLine = Object.PointsPredecessors.Add();
		NewLine.RoutePoint = Parameters.RoutePoint;
	EndIf;
	
	SetParametersOfStatesList();
	FormManagement(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик "ПослеЗаписи" 
//
Procedure AfterWrite(RecordParameters)
	
	SetParametersOfStatesList();
	FormManagement(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
// Процедура обработчик "УправлениеФормой" 
//
Procedure FormManagement(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	Items.Department.Visible          = False;
	Items.DepartmentLevel.Visible   = False;
	Items.User.Visible = False;
	Items.ManageType.Visible = False;
	
	Items.PointStates.Enabled = NOT Form.Parameters.Key.IsEmpty();
	Items.InfoLabel.Visible = Form.Parameters.Key.IsEmpty();
	
	If Object.AccessTypeToRoutePoint = PredefinedValue("Enum.fmAccessTypeToRoutePoint.FixedUser") Then
		Items.User.Visible = True;
	ElsIf Object.AccessTypeToRoutePoint = PredefinedValue("Enum.fmAccessTypeToRoutePoint.FixedDepartment") Then
		Items.Department.Visible = True;
	ElsIf Object.AccessTypeToRoutePoint = PredefinedValue("Enum.fmAccessTypeToRoutePoint.DocumentDepartment") Then 
		Items.DepartmentLevel.Visible = True;
	ElsIf Object.AccessTypeToRoutePoint = PredefinedValue("Enum.fmAccessTypeToRoutePoint.ManageType") Then
		Items.ManageType.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
// Процедура обработчик "ПроверитьЗаписьЭлемента" 
//
Procedure CheckItemWrite(Cancel)
	
	If NOT ValueIsFilled(Parameters.Key) Then
		
		Response = DoQueryBox(NStr("en='You should write the route point. Do you want to continue?';ru='Необходимо записать точку маршрута. Продолжить?'"), QuestionDialogMode.YesNo);
		If Response = DialogReturnCode.No Then
			Cancel = NOT Cancel;
			Return;
		EndIf;
		
		Try
			RecordResult = Write();
			If NOT RecordResult Then 
				Cancel = NOT Cancel;
				Return;
			EndIf;
		Except	
			Cancel = NOT Cancel;
			Return;
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
// Процедура обработчик события "СостояниеСогласованияНачалоВыбора" 
//
Procedure AgreementStateStartChoice(Item, ChoiceData, StandardProcessing)
	CheckItemWrite(StandardProcessing);
EndProcedure

&AtClient
// Процедура обработчик события "ВидДоступаКТочкеМаршрутаПриИзменении" 
//
Procedure AccessTypeToRoutePointOnChange(Item)
	FormManagement(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик события "СостоянияТочкиПередНачаломДобавления" 
//
Procedure PointStatesBeforeAddRow(Item, Cancel, Copy, Parent, Group)
	CheckItemWrite(Cancel);
EndProcedure

&AtClient
// Процедура обработчик события "СостояниеОтклоненияНачалоВыбора" 
//
Procedure DeviationStateStartChoice(Item, ChoiceData, StandardProcessing)
	CheckItemWrite(StandardProcessing);
EndProcedure

&AtServer
// Устанавливает параметры списка состояний
//
Procedure SetParametersOfStatesList()
	
	PointStates.Filter.Items.Clear();
	fmCommonUseClientServer.SetListFilterItem(PointStates, "Owner", Object.Ref);
	Items.PointStates.Refresh();
	
EndProcedure

&AtClient
// Обработчик нажатия кнопки СостояниеСогласованияПоУмолчанию
//
Procedure SetDefaultAgreementState(CurRow)
	CurRow = Items.PointStates.CurrentRow;
	If CurRow <> Undefined Then 
		PreviousState = Object.AgreementState;
		Object.AgreementState = CurRow;
		If NOT Write() Then 
			Object.AgreementState = PreviousState;
		EndIf;
	EndIf;
EndProcedure

&AtClient
// Обработчик нажатия кнопки СостояниеОтклоненияПоУмолчанию
//
Procedure SetDefaultDeviationState(CurRow)
	CurRow = Items.PointStates.CurrentRow;
	If CurRow <> Undefined Then 
		PreviousState = Object.DeviationState;
		Object.DeviationState = CurRow;
		If NOT Write() Then 
			Object.DeviationState = PreviousState;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure PointStatesChoice(Item, SelectedRow, Field, StandardProcessing)
	CurColumn = Items.PointStates.CurrentItem;
	If CurColumn.Name = "PointStatesByDefault" Then 
		StandardProcessing = False;
		If Items.PointStates.CurrentData.StageCompleted = 1 Then 
			SetDefaultAgreementState(Items.PointStates.CurrentRow);
		Else
			SetDefaultDeviationState(Items.PointStates.CurrentRow);
		EndIf;
	EndIf;
EndProcedure

