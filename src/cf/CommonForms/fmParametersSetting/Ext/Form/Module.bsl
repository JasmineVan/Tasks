
#Region FormsEventsHandlers

&AtClient
Var RefreshInterface;
&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Проверим возможность редактирования валют.
	Query = New Query();
	Query.Text = "SELECT ALLOWED TOP 1
	               |	fmBudgeting.Recorder AS Recorder
	               |FROM
	               |	AccountingRegister.fmBudgeting AS fmBudgeting
	               |
	               |UNION ALL
	               |
	               |SELECT TOP 1
	               |	fmIncomesExpanses.Recorder
	               |FROM
	               |	AccumulationRegister.fmIncomesAndExpenses AS fmIncomesExpanses
	               |
	               |UNION ALL
	               |
	               |SELECT TOP 1
	               |	fmCashflowBudget.Recorder
	               |FROM
	               |	AccumulationRegister.fmCashflowBudget AS fmCashflowBudget";
	HasRecordsMA = (NOT Query.Execute().IsEmpty());
	
	Items.fmCurrencyOfManAccounting.ReadOnly = HasRecordsMA;
	
	ReadOnly = NOT IsInRole("FullRights") 
		AND NOT IsInRole("DataAreaFullRights") 
		AND NOT IsInRole("AddChangeAccountingSettings");
		
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	If NOT fmBudgeting.ViewAndInputAllowedCombination(ConstantsSet.fmEditFormat, ConstantsSet.fmViewFormat) Then
		CommonClientServer.MessageToUser(NStr("en='Edit format cannot be larger than view format!';ru='Format редактировния NOT может быть больше, чем Format отображения!'"), , "ConstantsSet.fmEditFormat", , Cancel);
		ConstantsSet.fmViewFormat = ConstantsSet.fmEditFormat;
	EndIf;
EndProcedure

&AtClient
// Процедура обработчик "ПослеЗаписи" 
//
Procedure AfterWrite(RecordParameters)
	Notify("AccountingSettingsChanging");
EndProcedure

#EndRegion

#Region FormHeaderItemsEventsHandlers
&AtClient
// Процедура обработчик команды "ЗаписатьИЗакрыть" 
//
Procedure SaveAndClose(Command)
	
	Write();
	Close();
	
EndProcedure

&AtClient
// Процедура обработчик команды "КомандаЗакрыть" 
//
Procedure CommandClose(Command)
	
	If Window.IsMain Then
		GotoURL("e1cib/navigationpoint/CatalogsAndAccountingSettings");
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	RefreshProgramInterface();
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

#Region Client

&AtClient
Procedure RefreshProgramInterface()
	#If NOT WebClient Then
	If RefreshInterface = True Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;
	#EndIf
	
EndProcedure

&AtClient
Procedure fmDepartmentsStructuresVersionsOnChange(Item)
	RefreshInterface = True;
EndProcedure

#EndRegion

#EndRegion















