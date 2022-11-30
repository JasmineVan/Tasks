
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Function GetBlockSteps(Block) Export
	
	Query = New Query("SELECT
	|	fmBudgetDistributionSteps.Ref,
	|	fmBudgetDistributionSteps.Order AS Order,
	|	fmBudgetDistributionSteps.Parent
	|FROM
	|	Catalog.fmBudgetDistributionSteps AS fmBudgetDistributionSteps
	|WHERE
	|	fmBudgetDistributionSteps.Parent = &Block
	|	AND NOT fmBudgetDistributionSteps.DeletionMark
	|
	|ORDER BY
	|	Order");
	Query.SetParameter("Block", Block);
	Return Query.Execute().Unload();
	
EndFunction // ПолучитьШагиБлока()

Procedure StepCreationCheck(CurrentStep, NewStep, ChangedParameters, Cancel = False, Message = "") Export

	ChangedParameters = New Structure("Order");
	
	// Если текущая позиция - блок, то позиция этого шага должна быть равна
	//  - номеру первого шага блока
	//
	// Если блок не пуст, то низлежащие шаги подлежат сдвигу.
	
	// Если шаг, то ввод в следующую за шагом позицию
	// Т.е. номер текущего шага должен быть на 1 больше, чем номер шага, на котором стоим.
	// ТАКОЙ ЖЕ ПОДХОД И ДЛЯ ШАГА
	
	// ОТДЕЛЬНЫЕ проверки для шага и блока.
	// Если вводим шаг в сценарий, где еще нет блоков, то сообщать и отказываться.
	// Если вводим шаг в сценарий, но не в блок, то привязывать его к блоку.
	
	// Если вводим блок в позицию шага, то создавать его после текущего блока.
	
	// Отработаем создание блока
	If NewStep.IsFolder Then
		
		// Создаваемые родители помещаются в корень.
		If ValueIsFilled(NewStep.Parent) Then
			ChangedParameters.Insert("Parent", Catalogs.fmBudgetDistributionSteps.EmptyRef() );
		EndIf;
		
		If NOT ValueIsFilled(CurrentStep) Then
			ChangedParameters.Order = 0;
		Else
			If NOT CurrentStep.IsFolder Then
				// Если текущий шаг - это шаг, то +1 к номеру его блока.
				AnalyzingBlock = CurrentStep.Parent;
			Else
				AnalyzingBlock = CurrentStep;
			EndIf;
			
			// Получим список шагов после текущего шага
			BlockSteps = GetBlockSteps(AnalyzingBlock);
			If BlockSteps.Count() = 0 Then
				// Для пустого блока прибавляем 1 к его номеру.
				ChangedParameters.Order = AnalyzingBlock.Order + 1;
			Else
				// Для непустого блока прибавляем 1 к номеру его последнего шага.
				ChangedParameters.Order = BlockSteps[BlockSteps.Count() - 1].Order + 1;
			EndIf;
			
		EndIf;
		
	Else
		
		// Отработаем создание шага
		// Если текущая позиция - блок, то позиция этого шага должна быть равна
		If NOT ValueIsFilled(CurrentStep) Then
			Message = NStr("en='You can create a step only inside a block.';ru='Можно создавать шаг только внутри какого-либо блока.'");
			Cancel = True;
		ElsIf CurrentStep.IsFolder Then
			//    - номеру первого шага блока, если блок не пустой.
			//    - равна номеру блока, если блок пустой
			BlockSteps = GetBlockSteps(CurrentStep);
			If BlockSteps.Count() <> 0 Then
				// Если блок не пуст, то низлежащие шаги подлежат сдвигу.
				ChangedParameters.Order = BlockSteps[0].Order;
				// Лежащие ниже шаги должны быть сдвинуты до "дырки", а если ее нет, до конца.
			Else
				
				Query = New Query;
				Query.Text = "SELECT
				|	fmBudgetDistributionSteps.Ref
				|INTO BlocksBeforeCurrent
				|FROM
				|	Catalog.fmBudgetDistributionSteps AS fmBudgetDistributionSteps
				|WHERE
				|	fmBudgetDistributionSteps.Owner = &Scenario
				|	AND NOT fmBudgetDistributionSteps.DeletionMark
				|	AND fmBudgetDistributionSteps.IsFolder
				|	AND fmBudgetDistributionSteps.Order <= &CurrentStepNumber
				|
				|INDEX BY
				|	fmBudgetDistributionSteps.Ref
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	MAX(fmBudgetDistributionSteps.Order) AS Order
				|FROM
				|	Catalog.fmBudgetDistributionSteps AS fmBudgetDistributionSteps
				|		INNER JOIN BlocksBeforeCurrent AS BlocksBeforeCurrent
				|		ON (BlocksBeforeCurrent.Ref = fmBudgetDistributionSteps.Parent)
				|WHERE
				|	NOT fmBudgetDistributionSteps.DeletionMark
				|
				|HAVING
				|	MAX(fmBudgetDistributionSteps.Order) IS NOT NULL 
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP BlocksBeforeCurrent";
				Query.SetParameter("CurrentStepNumber", CurrentStep.Order);
				Query.SetParameter("Scenario", CurrentStep.Owner);
				Selection = Query.Execute().SELECT();
				If Selection.Next() Then
					ChangedParameters.Order = Selection.Order + 1;
				Else
					ChangedParameters.Order = 0;
				EndIf;
				
			EndIf;
				
		Else
			// Если шаг, то ввод в следующую за шагом позицию
			// Т.е. номер текущего шага должен быть на 1 больше, чем номер шага, на котором стоим.
			ChangedParameters.Order = CurrentStep.Order + 1;
			// Родитель и так присвоен автоматически.
			// Лежащие ниже шаги должны быть сдвинуты до "дырки", а если ее нет, до конца.
		EndIf;
		
	EndIf;
	
EndProcedure // ПроверкаСозданияШага()

#EndIf
