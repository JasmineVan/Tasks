
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	// Insert handler content.
	//FormParameters = New Structure("", );
	OpenForm("CommonForm.ActivityList", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
