
#Region FormCommandsHandlers

&AtClient
Procedure RefreshLevels(Command)
	RefreshLevelsServer();
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure RefreshLevelsServer()
	InformationRegisters.fmDepartmentHierarchy.RefreshLevelsAtServer();
EndProcedure

#EndRegion
