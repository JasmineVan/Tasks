
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
// Процедура отклонения маршрута 
//
Procedure RejectServer(VAL SelectedRows, Comment = "")
	
	For Each String In SelectedRows Do
		If String = Undefined OR TypeOf(String) = Type("DynamicalListGroupRow") Then 
			Continue;
		EndIf;
		fmProcessManagement.RejectDocument(String, String.AgreementRoute, Comment);
	EndDo;
	
EndProcedure //ОтклонитьСервер()

&AtServer
// Процедура согласования маршрута по всем точкам
//
Procedure AgreeServer(VAL SelectedRows, Comment = "")
	
	For Each String In SelectedRows Do
		If String = Undefined OR TypeOf(String) = Type("DynamicalListGroupRow") Then 
			Continue;
		EndIf;
		fmProcessManagement.AgreeDocumentByAllPoints(String, String.AgreementRoute, Comment);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetAgreementDocuments()
	
	Query = New Query("SELECT
	|	fmResponsiblesReplacements.Responsible AS Responsible
	|INTO TTReplacements
	|FROM
	|	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	|WHERE
	|	fmResponsiblesReplacements.ResponsibleReplacing = &Responsible
	|	AND (fmResponsiblesReplacements.BeginDate <= &CurrentDate
	|			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	|	AND (fmResponsiblesReplacements.EndDate >= &CurrentDate
	|			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	fmRouteStates.Document AS Document
	|FROM
	|	InformationRegister.fmRouteStates AS fmRouteStates
	|WHERE
	|	fmRouteStates.Responsible = &Responsible
	|	AND fmRouteStates.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	|
	|GROUP BY
	|	fmRouteStates.Document
	|
	|UNION ALL
	|
	|SELECT
	|	fmRouteStates.Document
	|FROM
	|	InformationRegister.fmRouteStates AS fmRouteStates
	|WHERE
	|	fmRouteStates.Responsible IN
	|			(SELECT
	|				TTReplacements.Responsible AS Responsible
	|			FROM
	|				TTReplacements AS TTReplacements)
	|	AND fmRouteStates.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	|
	|GROUP BY
	|	fmRouteStates.Document");
	Query.SetParameter("Responsible", Users.CurrentUser());
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Return Query.Execute().Unload().UnloadColumn("Document");
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	fmCommonUseServer.SetFilterByMainBalanceUnit(ThisForm);
	
	StatesColoring = Catalogs.fmDocumentState.GetSettings();
	For Each Item In StatesColoring Do
		fmCommonUseClientServer.AddConditionalAppearanceItem("List", ConditionalAppearance, "List.State",, Item.Ref, Item.Color, "TextColor");
	EndDo;
	
	// Настройка видимости кнопок согласования.
	If GetAgreementDocuments().Count()=0 Then
		Items.Agreement.Visible = False;
		Items.AgreeForm.Visible = False;
		Items.DocumentsForAgreement.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	fmCommonUseServer.RestoreListFilter(List, Settings, "BalanceUnit");
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "fmListRefresh" Then 
		Items.List.Refresh();
		DocumentsForAgreementOnChange(Undefined);
	EndIf;
EndProcedure


/////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД

&AtClient
Procedure Reject(Command)
	RejectServer(Items.List.SelectedRows);
	Notify("fmListRefresh");
EndProcedure

&AtClient
Procedure RejectWithComment(Command)
	OpenForm("CommonForm.fmCommentForm", , , , , , New NotifyDescription("RejectWithCommentEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure RejectWithCommentEnd(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		RejectServer(Items.List.SelectedRows, Result);
		Notify("fmListRefresh");
	EndIf;
EndProcedure // ОтклонитьСКомментарием()

&AtClient
Procedure Agree(Command)
	AgreeServer(Items.List.SelectedRows);
	Notify("fmListRefresh");
EndProcedure

&AtClient
Procedure AgreeWithComment(Command)
	OpenForm("CommonForm.fmCommentForm", , , , , , New NotifyDescription("AgreeWithCommentEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure AgreeWithCommentEnd(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		AgreeServer(Items.List.SelectedRows, Result);
		Notify("fmListRefresh");
	EndIf;
EndProcedure // СогласоватьСКомментарием()

&AtClient
Procedure DocumentsForAgreementOnChange(Item)
	If DocumentsForAgreement Then
		fmCommonUseClientServer.ChangeListFilterItem(List, "Ref", GetAgreementDocuments(), True, DataCompositionComparisonType.InList);
	Else
		fmCommonUseClientServer.ChangeListFilterItem(List, "Ref");
	EndIf;
EndProcedure


