///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.AddressingGroup.Enabled = NOT Object.Predefined;
	If NOT Object.Predefined Then
		Items.AddressingObjectsTypesGroup.Enabled = Object.UsedByAddressingObjects;
	EndIf;
	
	UpdateAvailability();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_RoleAddressing", WriteParameters, Object.Ref);
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectExchangePlanNodes") Then
		If ValueIsFilled(SelectedValue) Then
			Object.ExchangeNode = SelectedValue;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.UsedByAddressingObjects AND NOT Object.UsedWithoutAddressingObjects Then
		For each TableRow In Object.Purpose Do
			If TypeOf(TableRow.UsersType) <> TypeOf(Catalogs.Users.EmptyRef()) Then
				PurposeDescription = Metadata.FindByType(TypeOf(TableRow.UsersType)).Presentation();
				Common.MessageToUser( 
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Роль не может использоваться с обязательным уточнением для назначения: %1.'; en = 'Role cannot be used with required specification for assignment: %1.'; pl = 'Role cannot be used with required specification for assignment: %1.';de = 'Role cannot be used with required specification for assignment: %1.';ro = 'Role cannot be used with required specification for assignment: %1.';tr = 'Role cannot be used with required specification for assignment: %1.'; es_ES = 'Role cannot be used with required specification for assignment: %1.'"), PurposeDescription ),,,
						"UsedByAddressingObjects", Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsedInOtherAddressingDimensionsContextOnChange(Item)
	Items.AddressingObjectsTypesGroup.Enabled = Object.UsedByAddressingObjects;
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SelectAssignment(Command)
	NotifyDescription = New NotifyDescription("AfterAssignmentChoice", ThisObject);
	UsersInternalClient.SelectPurpose(ThisObject, NStr("ru = 'Выбор назначения роли'; en = 'Select role assignment'; pl = 'Select role assignment';de = 'Select role assignment';ro = 'Select role assignment';tr = 'Select role assignment'; es_ES = 'Select role assignment'"),,, NotifyDescription);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAvailability()
	
	Items.UsedWithoutOtherAddressingDimensionsContext.Enabled = True;
	Items.UsedInOtherAddressingDimensionsContext.Enabled = True;
	Items.MainAddressingObjectTypes.Enabled = True;
	Items.AdditionalAddressingObjectTypes.Enabled = True;
	
	If GetFunctionalOption("UseExternalUsers") Then
		If Object.Purpose.Count() > 0 Then
			SynonymArray = New Array;
			For each TableRow In Object.Purpose Do
				SynonymArray.Add(TableRow.UsersType.Metadata().Synonym);
			EndDo;
			Items.SelectPurpose.Title = StrConcat(SynonymArray, ", ");
		EndIf;
	Else
		Items.AssignmentGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssignmentChoice(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		Modified = True;
	EndIf;
EndProcedure


#EndRegion
