
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
Function TabSectionItemsCount_Bases()
	Return Object.Bases.Count();
EndFunction

&AtServer
Procedure BaseSpecificWeightCalculation(NewCalculation = False)
	
	TotalSpecificWeight	= 0;
	MAX		= 0;
	TotalOfBase		= Object.Bases.Total("BaseValue");
	RowMax		= Undefined;
	
	For Each BaseItem In Object.Bases Do
		BaseItem.BaseSpecificWeight = ?(
			TotalOfBase <> 0,
			Round((BaseItem.BaseValue / TotalOfBase) * 100, 3),
			0);
		TotalSpecificWeight = TotalSpecificWeight + BaseItem.BaseSpecificWeight;
		If MAX = 0 Then
			MAX = BaseItem.BaseSpecificWeight
		EndIf;
		If Min(MAX, BaseItem.BaseSpecificWeight) = BaseItem.BaseSpecificWeight Then
			RowMax = BaseItem;
		EndIf;
	EndDo;
	
	Delta = ?(TotalSpecificWeight > 0, 100 - TotalSpecificWeight, 0);
	If NOT Delta = 0 Then
		RowMax.BaseSpecificWeight = RowMax.BaseSpecificWeight + Delta;
	EndIf;
	
EndProcedure

&AtServer
Function SetupVisibility()
	If DistributionBaseType=Enums.fmDistributionBaseTypes.ProjectsBase Then
		Items.BasesDepartment.Visible = False;
		Items.BasesProject.Visible = True;
		Items.DistributionDepartment.AutoChoiceIncomplete = True;
		Items.DistributionDepartment.AutoMarkIncomplete = True;
	Else
		Items.BasesDepartment.Visible = True;
		Items.BasesProject.Visible = False;
		Items.DistributionDepartment.AutoChoiceIncomplete = False;
		Items.DistributionDepartment.AutoMarkIncomplete = False;
	EndIf;
EndFunction // НастроитьВидимость()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

//Обработчик события формы "ПриСозданииНаСервере" 
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DistributionBaseType = Object.DistributionBase.BaseType;
	SetupVisibility();
	BaseSpecificWeightCalculation();
	If Object.OperationType = Enums.fmDistributionBaseOperationTypes.CalculatedBase Then
		Items.BudgetDistributionStep.Visible = True;
	EndIf;
	
EndProcedure //ПриСозданииНаСервере()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ЭЛЕМЕНТОВ ФОРМЫ

&AtClient
Procedure BasesBaseValueOnChange(Item)
	BaseSpecificWeightCalculation();
EndProcedure

&AtClient
Procedure BasesOnStartEdit(Item, NewLine, Copy)
	
	If NewLine AND NOT Copy AND Item.CurrentData <> Undefined Then
		Item.CurrentData.Active = True;
	EndIf;
	
	If Copy Then
		BaseSpecificWeightCalculation(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BasesAfterDeleteRow(Item)
	BaseSpecificWeightCalculation(True);
EndProcedure

//Обработчик события при изменении базы распределения
//
&AtClient
Procedure DistributionBaseOnChange(Item)
	DistributionBaseOnChangeServer();
EndProcedure //БазаРаспределенияПриИзменении()

//Обработчик события при изменении базы распределения
//
&AtServer
Procedure DistributionBaseOnChangeServer()
	If NOT DistributionBaseType=Object.DistributionBase.BaseType Then
		Object.Bases.Clear();
		DistributionBaseType=Object.DistributionBase.BaseType;
		SetupVisibility();
	EndIf;
EndProcedure //БазаРаспределенияПриИзменении()






