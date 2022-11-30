
#Region EventsHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecutionParameter)

	FormParameters = New Structure;
	FormParameters.Insert("Account", CommandParameter);
	OpenForm("AccountingRegister.fmBudgeting.ListForm", FormParameters);
	
EndProcedure

#EndRegion
