///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Updates the list of commands depending on the current context.
//
// Parameters:
//   Form - ManagedForm - a form that requires an update of commands.
//   Source - FormDataStructure - FormTable - a context to check conditions (Form.Object or Form.Items.List).
//
Procedure UpdateCommands(Form, Source) Export
	Structure = New Structure("AttachableCommandsParameters", Null);
	FillPropertyValues(Structure, Form);
	ClientParameters = Structure.AttachableCommandsParameters;
	If TypeOf(ClientParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("FormTable") Then
		CommandsAvailability = (Source.CurrentRow <> Undefined);
	Else
		CommandsAvailability = True;
	EndIf;
	If CommandsAvailability <> ClientParameters.CommandsAvailability Then
		ClientParameters.CommandsAvailability = CommandsAvailability;
		For Each ButtonOrSubmenuName In ClientParameters.RootSubmenuAndCommands Do
			ButtonOrSubmenu = Form.Items[ButtonOrSubmenuName];
			ButtonOrSubmenu.Enabled = CommandsAvailability;
			If TypeOf(ButtonOrSubmenu) = Type("FormGroup") AND ButtonOrSubmenu.Type = FormGroupType.Popup Then
				HideShowAllSubordinateButtons(ButtonOrSubmenu, CommandsAvailability);
				CapCommand = Form.Items.Find(ButtonOrSubmenuName + "Stub");
				If CapCommand <> Undefined Then
					CapCommand.Visible = Not CommandsAvailability;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Not CommandsAvailability Or Not ClientParameters.HasVisibilityConditions Then
		Return;
	EndIf;
	
	SelectedObjects = New Array;
	CheckTypesDetails = False;
	
	If TypeOf(Source) = Type("FormTable") Then
		SelectedRows = Source.SelectedRows;
		For Each SelectedRow In SelectedRows Do
			If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
				Continue;
			EndIf;
			CurrentRow = Source.RowData(SelectedRow);
			If CurrentRow <> Undefined Then
				SelectedObjects.Add(CurrentRow);
			EndIf;
		EndDo;
		CheckTypesDetails = True;
	Else
		SelectedObjects.Add(Source);
	EndIf;
	
	For Each SubmenuShortInfo In ClientParameters.SubmenuWithVisibilityConditions Do
		HasVisibleCommands = False;
		Submenu = Form.Items.Find(SubmenuShortInfo.Name);
		ChangeVisible = (TypeOf(Submenu) = Type("FormGroup") AND Submenu.Type = FormGroupType.Popup);
		
		For Each Command In SubmenuShortInfo.CommandsWithVisibilityConditions Do
			CommandItem = Form.Items[Command.NameOnForm];
			Visibility = True;
			For Each Object In SelectedObjects Do
				If CheckTypesDetails
					AND TypeOf(Command.ParameterType) = Type("TypeDescription")
					AND Not Command.ParameterType.ContainsType(TypeOf(Object.Ref)) Then
					Visibility = False;
					Break;
				EndIf;
				If TypeOf(Command.VisibilityConditions) = Type("Array")
					AND Not ConditionsBeingExecuted(Command.VisibilityConditions, Object) Then
					Visibility = False;
					Break;
				EndIf;
			EndDo;
			If ChangeVisible Then
				CommandItem.Visible = Visibility;
			Else
				CommandItem.Enabled = Visibility;
			EndIf;
			HasVisibleCommands = HasVisibleCommands Or Visibility;
		EndDo;
		
		If Not SubmenuShortInfo.HasCommandsWithoutVisibilityConditions Then
			CapCommand = Form.Items.Find(SubmenuShortInfo.Name + "Stub");
			If CapCommand <> Undefined Then
				CapCommand.Visible = Not HasVisibleCommands;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Region Private

// Template of the second command handler parameter.
//
// Returns:
//   Structure - auxiliary parameters.
//       * CommandDetails - Structure - command details.
//           The structure is equal to the AttachableCommands.CommandsTable().
//           ** ID - String - a command ID.
//           ** Presentation - String - a command presentation on a form.
//           ** AdditionalParameters - Structure - command additional parameters.
//       * Form - ManagedForm - a form the command is called from.
//       * IsObjectForm - Boolean - True if the command is called from the object form.
//       * Source - FormTable, FormDataStructure - an object or a form list with the Reference field.
//
Function CommandExecutionParametersTemplate() Export
	Structure = New Structure("CommandDetails, Form, Source");
	Structure.Insert("IsObjectForm", False);
	Return Structure;
EndFunction

Function ConditionsBeingExecuted(Conditions, AttributesValues)
	For Each Condition In Conditions Do
		AttributeName = Condition.Attribute;
		If Not AttributesValues.Property(AttributeName) Then
			Continue;
		EndIf;
		ConditionBeingExecuted = True;
		If Condition.ComparisonType = ComparisonType.Equal
			Or Condition.ComparisonType = DataCompositionComparisonType.Equal Then
			ConditionBeingExecuted = AttributesValues[AttributeName] = Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.Greater
			Or Condition.ComparisonType = DataCompositionComparisonType.Greater Then
			ConditionBeingExecuted = AttributesValues[AttributeName] > Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.GreaterOrEqual
			Or Condition.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
			ConditionBeingExecuted = AttributesValues[AttributeName] >= Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.Less
			Or Condition.ComparisonType = DataCompositionComparisonType.Less Then
			ConditionBeingExecuted = AttributesValues[AttributeName] < Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.LessOrEqual
			Or Condition.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
			ConditionBeingExecuted = AttributesValues[AttributeName] <= Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.NotEqual
			Or Condition.ComparisonType = DataCompositionComparisonType.NotEqual Then
			ConditionBeingExecuted = AttributesValues[AttributeName] <> Condition.Value;
		ElsIf Condition.ComparisonType = ComparisonType.InList
			Or Condition.ComparisonType = DataCompositionComparisonType.InList Then
			ConditionBeingExecuted = Condition.Value.Find(AttributesValues[AttributeName]) <> Undefined;
		ElsIf Condition.ComparisonType = ComparisonType.NotInList
			Or Condition.ComparisonType = DataCompositionComparisonType.NotInList Then
			ConditionBeingExecuted = Condition.Value.Find(AttributesValues[AttributeName]) = Undefined;
		ElsIf Condition.ComparisonType = DataCompositionComparisonType.Filled Then
			ConditionBeingExecuted = ValueIsFilled(AttributesValues[AttributeName]);
		ElsIf Condition.ComparisonType = DataCompositionComparisonType.NotFilled Then
			ConditionBeingExecuted = Not ValueIsFilled(AttributesValues[AttributeName]);
		EndIf;
		If Not ConditionBeingExecuted Then
			Return False;
		EndIf;
	EndDo;
	Return True;
EndFunction

Procedure HideShowAllSubordinateButtons(FormGroup, Visibility)
	For Each SubordinateItem In FormGroup.ChildItems Do
		If TypeOf(SubordinateItem) = Type("FormGroup") Then
			HideShowAllSubordinateButtons(SubordinateItem, Visibility);
		ElsIf TypeOf(SubordinateItem) = Type("FormButton") Then
			SubordinateItem.Visible = Visibility;
		EndIf;
	EndDo;
EndProcedure

#EndRegion