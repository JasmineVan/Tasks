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
	
	FormTitleText = Parameters.FormCaption;
	DefaultTitle = IsBlankString(FormTitleText);
	If NOT DefaultTitle Then
		Title = FormTitleText;
	EndIf;
	
	TitleText = "";
	
	If Parameters.TaskCount > 1 Then
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (%2)'; en = '%1 (%2)'; pl = '%1 (%2)';de = '%1 (%2)';ro = '%1 (%2)';tr = '%1 (%2)'; es_ES = '%1 (%2)'"),
			?(DefaultTitle, NStr("ru = 'Выбрано задач'; en = 'Selected tasks'; pl = 'Selected tasks';de = 'Selected tasks';ro = 'Selected tasks';tr = 'Selected tasks'; es_ES = 'Selected tasks'"), FormTitleText),
			String(Parameters.TaskCount));
	ElsIf Parameters.TaskCount = 1 Then
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 %2'; en = '%1 %2'; pl = '%1 %2';de = '%1 %2';ro = '%1 %2';tr = '%1 %2'; es_ES = '%1 %2'"),
			?(DefaultTitle, NStr("ru = 'Выбранная задача'; en = 'Selected task'; pl = 'Selected task';de = 'Selected task';ro = 'Selected task';tr = 'Selected task'; es_ES = 'Selected task'"), FormTitleText),
			String(Parameters.Task));
	Else
		Items.TitleDecoration.Visible = False;
	EndIf;
	Items.TitleDecoration.Title = TitleText;
	
	SetAddressingObjectTypes();
	SetItemsState();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If AddressingType = 0 Then
		If NOT ValueIsFilled(Performer) Then
			Common.MessageToUser(
				NStr("ru = 'Не указан исполнитель задачи.'; en = 'The task assignee is not specified.'; pl = 'The task assignee is not specified.';de = 'The task assignee is not specified.';ro = 'The task assignee is not specified.';tr = 'The task assignee is not specified.'; es_ES = 'The task assignee is not specified.'"),,,
				"Performer",
				Cancel);
		EndIf;
		Return;
	EndIf;
	
	If Role.IsEmpty() Then
		Common.MessageToUser(
			NStr("ru = 'Не указана роль исполнителей задачи.'; en = 'The task assignee role is not specified.'; pl = 'The task assignee role is not specified.';de = 'The task assignee role is not specified.';ro = 'The task assignee role is not specified.';tr = 'The task assignee role is not specified.'; es_ES = 'The task assignee role is not specified.'"),,,
			"Role",
			Cancel);
		Return;
	EndIf;
	
	MainAddressingObjectTypesAreSet = UsedByAddressingObjects
		AND ValueIsFilled(MainAddressingObjectTypes);
	TypesOfAditionalAddressingObjectAreSet = UsedByAddressingObjects 
		AND ValueIsFilled(AdditionalAddressingObjectTypes);
	
	If MainAddressingObjectTypesAreSet AND MainAddressingObject = Undefined Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле ""%1"" не заполнено.'; en = 'The ""%1"" field is required.'; pl = 'The ""%1"" field is required.';de = 'The ""%1"" field is required.';ro = 'The ""%1"" field is required.';tr = 'The ""%1"" field is required.'; es_ES = 'The ""%1"" field is required.'"),	Role.MainAddressingObjectTypes.Description),,,
			"MainAddressingObject",
			Cancel);
		Return;
	ElsIf TypesOfAditionalAddressingObjectAreSet AND AdditionalAddressingObject = Undefined Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле ""%1"" не заполнено.'; en = 'The ""%1"" field is required.'; pl = 'The ""%1"" field is required.';de = 'The ""%1"" field is required.';ro = 'The ""%1"" field is required.';tr = 'The ""%1"" field is required.'; es_ES = 'The ""%1"" field is required.'"), Role.AdditionalAddressingObjectTypes.Description),,,
			"AdditionalAddressingObject",
			Cancel);
		Return;
	EndIf;
	
	If NOT IgnoreWarnings 
		AND NOT BusinessProcessesAndTasksServer.HasRolePerformers(Role, MainAddressingObject, AdditionalAddressingObject) Then
		Common.MessageToUser(
			NStr("ru = 'На указанную роль не назначено ни одного исполнителя. (Чтобы проигнорировать это предупреждение, установите флажок.)'; en = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).'; pl = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).';de = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).';ro = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).';tr = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).'; es_ES = 'No assignee is assigned to the specified role. (To ignore this warning, select the check box).'"),,,
			"Role",
			Cancel);
		Items.IgnoreWarnings.Visible = True;
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PerformerOnChange(Item)
	
	AddressingType = 0;
	MainAddressingObject = Undefined;
	AdditionalAddressingObject = Undefined;
	SetAddressingObjectTypes();
	SetItemsState();
	
EndProcedure

&AtClient
Procedure RoleOnChange(Item)
	
	AddressingType = 1;
	Performer = Undefined;
	MainAddressingObject = Undefined;
	AdditionalAddressingObject = Undefined;
	SetAddressingObjectTypes();
	SetItemsState();
	
EndProcedure

&AtClient
Procedure AddressingTypeOnChange(Item)
	SetItemsState();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If NOT CheckFilling() Then
		Return;
	EndIf;
	Close(ClosingParameters());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAddressingObjectTypes()
	
	MainAddressingObjectTypes = Role.MainAddressingObjectTypes.ValueType;
	AdditionalAddressingObjectTypes = Role.AdditionalAddressingObjectTypes.ValueType;
	UsedByAddressingObjects = Role.UsedByAddressingObjects;
	UsedWithoutAddressingObjects = Role.UsedWithoutAddressingObjects;
	
EndProcedure

&AtServer
Procedure SetItemsState()
	
	Items.Performer.MarkIncomplete = False;
	Items.Performer.AutoMarkIncomplete = AddressingType = 0;
	Items.Performer.Enabled = AddressingType = 0;
	Items.Role.MarkIncomplete = False;
	Items.Role.AutoMarkIncomplete = AddressingType <> 0;
	Items.Role.Enabled = AddressingType <> 0;
	
	MainAddressingObjectTypesAreSet = UsedByAddressingObjects
		AND ValueIsFilled(MainAddressingObjectTypes);
	TypesOfAditionalAddressingObjectAreSet = UsedByAddressingObjects 
		AND ValueIsFilled(AdditionalAddressingObjectTypes);
		
	Items.MainAddressingObject.Title = Role.MainAddressingObjectTypes.Description;
	Items.OneMainAddressingObject.Title = Role.MainAddressingObjectTypes.Description;
	
	If MainAddressingObjectTypesAreSet AND TypesOfAditionalAddressingObjectAreSet Then
		Items.OneAddressingObjectGroup.Visible = False;
		Items.TwoAddressingObjectsGroup.Visible = True;
	ElsIf MainAddressingObjectTypesAreSet Then
		Items.OneAddressingObjectGroup.Visible = True;
		Items.TwoAddressingObjectsGroup.Visible = False;
	Else	
		Items.OneAddressingObjectGroup.Visible = False;
		Items.TwoAddressingObjectsGroup.Visible = False;
	EndIf;
		
	Items.AdditionalAddressingObject.Title = Role.AdditionalAddressingObjectTypes.Description;
	
	Items.MainAddressingObject.AutoMarkIncomplete = MainAddressingObjectTypesAreSet
		AND NOT UsedWithoutAddressingObjects;
	Items.OneMainAddressingObject.AutoMarkIncomplete = MainAddressingObjectTypesAreSet
		AND NOT UsedWithoutAddressingObjects;
	Items.AdditionalAddressingObject.AutoMarkIncomplete = TypesOfAditionalAddressingObjectAreSet
		AND NOT UsedWithoutAddressingObjects;
	Items.OneMainAddressingObject.TypeRestriction = MainAddressingObjectTypes;
	Items.MainAddressingObject.TypeRestriction = MainAddressingObjectTypes;
	Items.AdditionalAddressingObject.TypeRestriction = AdditionalAddressingObjectTypes;
	
EndProcedure

&AtClient
Function ClosingParameters()
	
	Result = New Structure;
	Result.Insert("Performer", ?(ValueIsFilled(Performer), Performer, Undefined));
	Result.Insert("PerformerRole", Role);
	Result.Insert("MainAddressingObject", MainAddressingObject);
	Result.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	Result.Insert("Comment", Comment);
	
	If Result.MainAddressingObject <> Undefined AND Result.MainAddressingObject.IsEmpty() Then
		Result.MainAddressingObject = Undefined;
	EndIf;
	
	If Result.AdditionalAddressingObject <> Undefined AND Result.AdditionalAddressingObject.IsEmpty() Then
		Result.AdditionalAddressingObject = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
