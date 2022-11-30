
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	
	If NOT IsFolder Then
		
		If StepType = Enums.fmBudgetAllocationStepTypes.DistributionBaseAssemble Then
			CheckingAttributes.Delete(CheckingAttributes.Find("BudgetSection"));
		ElsIf StepType = Enums.fmBudgetAllocationStepTypes.DistributionByBasesOnDepartments Then
			CheckingAttributes.Delete(CheckingAttributes.Find("DepartmentTurnover"));
		ElsIf StepType = Enums.fmBudgetAllocationStepTypes.Reclass Then
			CheckingAttributes.Delete(CheckingAttributes.Find("DistributionBase"));
			CheckingAttributes.Delete(CheckingAttributes.Find("DepartmentTurnover"));
		ElsIf StepType = Enums.fmBudgetAllocationStepTypes.ReversalOfPreviousVersionsAllocation Then
			CheckingAttributes.Delete(CheckingAttributes.Find("DistributionBase"));
			CheckingAttributes.Delete(CheckingAttributes.Find("DepartmentTurnover"));
			CheckingAttributes.Delete(CheckingAttributes.Find("BudgetSection"));
		EndIf;
		
	EndIf;
EndProcedure

#EndIf
