
#Region EventsHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecutionParameter)
	OpenForm("DataProcessor.fmBudgetingDataAllocation.Form", , CommandExecutionParameter.Source, CommandExecutionParameter.Uniqueness, CommandExecutionParameter.Window, CommandExecutionParameter.URL);
EndProcedure

#EndRegion
