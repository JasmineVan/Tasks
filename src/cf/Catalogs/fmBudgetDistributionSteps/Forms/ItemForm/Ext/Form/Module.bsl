
#Region CommonProceduresAndFunctions

&AtServerNoContext
Procedure StepCreationCheckRun(CurrentPositionListItem, VAL Object, ChangedParameters, Cancel, UserMessage)
	Catalogs.fmBudgetDistributionSteps.StepCreationCheck(CurrentPositionListItem, Object, ChangedParameters, Cancel, UserMessage);
EndProcedure // ПроверкаСозданияШагаЗапустить()

&AtServerNoContext
Procedure CheckQueryTextServer(QueryText, Base)
	
	Try
		QueryBuilder = New QueryBuilder(QueryText);
		QueryBuilder.FillSettings();
		CommonClientServer.MessageToUser(NStr("en='Syntax errors are not found';ru='Синтаксических ошибок не обнаружено!'"));
	Except
		CommonClientServer.MessageToUser(ErrorDescription());
		Return;
	EndTry;
	
	If Base.BaseType = Enums.fmDistributionBaseTypes.DepartmentsBase Then
		AnalyticsField = "Department";
	ElsIf Base.BaseType = Enums.fmDistributionBaseTypes.ProjectsBase Then
		AnalyticsField = "Project";
	Else
		AnalyticsField = "Department";
	EndIf;
		
	If QueryBuilder.AvailableFields.Find(AnalyticsField) = Undefined Then
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='The ""%1"" dimension field is not found.';ru='Не найдено поле аналитики ""%1""!'"), AnalyticsField));
	EndIf;
	
	If QueryBuilder.AvailableFields.Find("BaseValue") = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='The ""BaseValue"" field is not found.';ru='Не найдено поле ""ЗначениеБазы""!'"));
	EndIf;
	
EndProcedure // ПроверитьТекстЗапросаСервер()

&AtServer
Procedure FillQueryParametersServer()

	ParametersStructure = New Structure();
	QueryText = Object.BaseAssembleAlgorithm;
	
	If NOT IsBlankString(QueryText) Then
		
		Query = New Query(QueryText);
		Try
			FoundParameters = Query.FindParameters();
		Except
			Message(ErrorDescription());
			Return;
		EndTry;
		
		For Each QueryParameter In FoundParameters Do
			FoundParameter = Object.BaseAssembleQueryParameters.FindRows(New Structure("ParameterName", QueryParameter.Name));
			If FoundParameter.Count()=0 Then
				NewParameter = Object.BaseAssembleQueryParameters.Add();
				NewParameter.ParameterName = QueryParameter.Name;
				NewParameter.ParameterValue = QueryParameter.ValueType.AdjustValue(Undefined);
			Else
				//Параметр есть, приведем его тип к новой типизации параметра.
				FoundParameter.ParameterValue[0] = QueryParameter.ValueType.AdjustValue(FoundParameter.ParameterValue);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure // ЗаполнитьПараметрыЗапросаСервер()

&AtServer
Procedure RefreshNoteToBasesQuery()
	
	If NOT ValueIsFilled(Object.DistributionBase) Then
		Items.BaseQueryDescription.Title = "";
		Return;
	EndIf;
	
	If Object.DistributionBase.BaseType = Enums.fmDistributionBaseTypes.DepartmentsBase Then
		Items.BaseQueryDescription.Title = 
		NStr("en='The query must contain the following fields:"
"Department (with the ""Department"" catalog type) and BaseValue of the number type. You can use the following query parameters: BaseStartPeriod and BaseEndPeriod.';ru='В запросе должны присутствовать поля:"
"Подразделение (типа справочник ""Подразделения"") и ЗначениеБазы типа число. Допустимо использование параметров запроса НачалоПериодаБазы и ОкончаниеПериодаБазы.'");
	ElsIf Object.DistributionBase.BaseType = Enums.fmDistributionBaseTypes.ProjectsBase Then
		Items.BaseQueryDescription.Title = 
		NStr("en='The query must contain the following fields:"
"Project (with the ""Projects""catalog type) and BaseValue of the number type. You can use the following query parameters: BaseStartPeriod and BaseEndPeriod.';ru='В запросе должны присутствовать поля:"
"Проект (типа справочник ""Проекты"") и ЗначениеБазы типа число. Допустимо использование параметров запроса НачалоПериодаБазы и ОкончаниеПериодаБазы.'");
	Else
		Items.BaseQueryDescription.Title = "";
	EndIf;
	
EndProcedure // ОбновитьПримечаниеКЗапросуБаз()

&AtServer
Procedure SetFieldsVisibility()
	
	Items.RecipientDepartment.Visible = False;
	If Object.StepType = Enums.fmBudgetAllocationStepTypes.DistributionBaseAssemble Then
		If NOT ValueIsFilled(Object.DistributionBasePeriodicity) Then
			Object.DistributionBasePeriodicity = Enums.fmAvailableReportPeriods.Year;
		EndIf;
		Items.BaseAssemble.Visible = True;
		Items.DistributionWhatHow.Visible = False;
		Items.ExplanationHowUseAssembleBase.Title = NStr("en='The department, scenario, and project define ""Allocation department"", ""Scenario"", and ""Allocation project"" of the resulting document for the allocation base.';ru='Подразделение, сценарий и проект определяют ""Подразделение распределения"", ""Сценарий"" и ""Проект распределения"" результирующего документа баз распределения.'");
		RefreshNoteToBasesQuery();
		Items.Department1.AutoChoiceIncomplete = True;
		Items.Department1.AutoMarkIncomplete = True;
	ElsIf Object.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
		Items.BaseAssemble.Visible = False;
		Items.DistributionWhatHow.Visible = True;
		Items.Department1.AutoChoiceIncomplete = False;
		Items.Department1.AutoMarkIncomplete = False;
		Items.DistributionBase.Visible = True;
		Array = New Array();
		Array.Add(Enums.fmDistributionBaseTypes.DepartmentsBase);
		ParametersArray = New Array();
		ChoiceParameter = New ChoiceParameter("Filter.BaseType", New FixedArray(Array));
		ParametersArray.Add(ChoiceParameter);
		Items.DistributionBase.ChoiceParameters = New FixedArray(ParametersArray);
	ElsIf Object.StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnProjects Then
		Items.BaseAssemble.Visible = False;
		Items.DistributionWhatHow.Visible = True;
		Items.Department1.AutoChoiceIncomplete = False;
		Items.Department1.AutoMarkIncomplete = False;
		Items.DistributionBase.Visible = True;
		Array = New Array();
		Array.Add(Enums.fmDistributionBaseTypes.ProjectsBase);
		ParametersArray = New Array();
		ChoiceParameter = New ChoiceParameter("Filter.BaseType", New FixedArray(Array));
		ParametersArray.Add(ChoiceParameter);
		Items.DistributionBase.ChoiceParameters = New FixedArray(ParametersArray);
	ElsIf Object.StepType = Enums.fmBudgetAllocationStepTypes.Reclass Then
		Items.BaseAssemble.Visible = False;
		Items.DistributionWhatHow.Visible = True;
		Items.Department1.AutoChoiceIncomplete = False;
		Items.Department1.AutoMarkIncomplete = False;
		Items.DistributionBase.Visible = False;
		Items.RecipientDepartment.Visible = True;
	ElsIf Object.StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
		Items.BaseAssemble.Visible = False;
		Items.DistributionWhatHow.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion


#Region FormEventsHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If NOT ValueIsFilled(Parameters.Key) Then
		
		// Это новый
		CurrentPositionListItem = ThisForm.FormOwner.CurrentRow;
		UserMessage = "";
		ChangedParameters = "";
		StepCreationCheckRun(CurrentPositionListItem, Object, ChangedParameters, Cancel, UserMessage);
		If Cancel Then
			ShowMessageBox(, UserMessage);
			Return;
		EndIf;
		
		If ValueIsFilled(ChangedParameters) Then
			FillPropertyValues(Object, ChangedParameters);	
		EndIf;
		// При записи все номера, более поздних шагов, чем создаваемый, должны увеличиться на 1. Если первая дырка, то прерываемся.
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetFieldsVisibility();
	TemporaryModule.OnCreateAtServerDistributionSteps(Cancel);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	If NOT ValueIsFilled(Parameters.Key) Then
		
		// Это новый
		Query = New Query("SELECT
		                      |	fmBudgetDistributionSteps.Ref AS Ref,
		                      |	fmBudgetDistributionSteps.Order AS Order,
		                      |	fmBudgetDistributionSteps.Parent AS Parent,
		                      |	fmBudgetDistributionSteps.Parent.Order AS ParentOrder
		                      |FROM
		                      |	Catalog.fmBudgetDistributionSteps AS fmBudgetDistributionSteps
		                      |WHERE
		                      |	NOT fmBudgetDistributionSteps.DeletionMark
		                      |	AND NOT IsFolder
		                      |	AND fmBudgetDistributionSteps.Owner = &Owner
		                      |	AND fmBudgetDistributionSteps.Order >= &Order
		                      |
		                      |ORDER BY
		                      |	fmBudgetDistributionSteps.Order");
		Query.SetParameter("Owner",	Object.Owner);
		Query.SetParameter("Order",	Object.Order);
		Selection = Query.Execute().SELECT();
		
		BeginTransaction();
		
		Counter = Object.Order;
		
		ProcessedBlocks = New Array;
		
		While Selection.Next() Do
			
			// Найдена "дырка", дальше сдвигать элементы смысла нет.
			If Counter < Selection.Order Then
				Break;
			EndIf;
			
			OrderObject = Selection.Ref.GetObject();
			OrderObject.Order = Selection.Order + 1;
			OrderObject.DataExchange.Load = True;
			Try
				OrderObject.Write();
			Except
				RollbackTransaction();
				Return;
			EndTry;
			
			// Сдвинем также номер блока (только один раз). Не нужно сдвигать блок, в который добавляется шаг.
			If Object.Order < Selection.ParentOrder Then
				If ProcessedBlocks.Find(Selection.Parent) = Undefined Then
					ParentObject = Selection.Parent.GetObject();
					ParentObject.Order = ParentObject.Order + 1;
					ParentObject.DataExchange.Load = True;
					Try
						ParentObject.Write();
					Except
						RollbackTransaction();
						Return;
					EndTry;
					ProcessedBlocks.Add(Selection.Parent)	
				EndIf;	
			EndIf;
			
			Counter = Counter + 1;
			
		EndDo;
		
		CommitTransaction();
		
	EndIf;
	
EndProcedure

#EndRegion


#Region FormItemsEventsHandlers

&AtClient
Procedure StepTypeOnChange(Item)
	SetFieldsVisibility();
EndProcedure

&AtClient
Procedure CheckQueryText(Command)
	CheckQueryTextServer(Object.BaseAssembleAlgorithm, Object.DistributionBase);
EndProcedure

&AtClient
Procedure QueryWizard(Command)
	#If ThickClientManagedApplication OR ThickClientOrdinaryApplication Then
		If ValueIsFilled(Object.BaseAssembleAlgorithm) Then
			Wizard = New QueryWizard(Object.BaseAssembleAlgorithm);
		Else
			Wizard = New QueryWizard();
		EndIf;
		If Wizard.DoModal() Then
			Object.BaseAssembleAlgorithm = Wizard.Text;
		Else
			Modified = False;
		EndIf;
		
	#Else
		ShowMessageBox(, NStr("en='The query builder is only available in the thick client mode.';ru='Конструктор запроса доступен только в режиме толстого клиента.'"));		
	#EndIf
EndProcedure

&AtClient
Procedure FillQueryParameters(Command)
	FillQueryParametersServer();
EndProcedure

&AtClient
Procedure DistributionBase1OnChange(Item)
	RefreshNoteToBasesQuery();
EndProcedure

#EndRegion




