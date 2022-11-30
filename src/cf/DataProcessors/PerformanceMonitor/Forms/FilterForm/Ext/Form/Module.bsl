///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DirectionOnChange(Item)
	
	GenerateCondition();
	
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	
	GenerateCondition();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("Direction, State");
	SelectionResult.Direction = Direction;
	SelectionResult.State = State;
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateCondition()
	
	If Direction > 0 Then
		If Upper(State) = "GOOD" Then
			Limit = 0.93;
		ElsIf Upper(State) = "FAIR" Then
			Limit = 0.84;
		ElsIf Upper(State) = "FRUSTRATED" Then
			Limit = 0.69;
		EndIf;
		Condition = "apdex > " + Limit;
	ElsIf Direction < 0 Then
		If Upper(State) = "GOOD" Then
			Limit = 0.85;
		ElsIf Upper(State) = "FAIR" Then
			Limit = 0.7;
		ElsIf Upper(State) = "FRUSTRATED" Then
			Limit = 0.5;
		EndIf;
		Condition = "apdex < " + Limit;
	EndIf;
	
EndProcedure

#EndRegion
