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
	
	If Not ValueIsFilled(Parameters.Account) Or Parameters.Account.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
		
	Account = Parameters.Account;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailProcessingRules.Ref AS Rule,
	|	FALSE AS Apply,
	|	EmailProcessingRules.FilterPresentation,
	|	EmailProcessingRules.PutInFolder
	|FROM
	|	Catalog.EmailProcessingRules AS EmailProcessingRules
	|WHERE
	|	EmailProcessingRules.Owner = &Owner
	|	AND (NOT EmailProcessingRules.DeletionMark)
	|
	|ORDER BY
	|	EmailProcessingRules.AddlOrderingAttribute";
	
	Query.SetParameter("Owner", Parameters.Account);
	Query.SetParameter("Incoming", NStr("ru = 'Входящие'; en = 'Incoming'; pl = 'Incoming';de = 'Incoming';ro = 'Incoming';tr = 'Incoming'; es_ES = 'Incoming'"));
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then
		Rules.Load(Result.Unload());
	EndIf;
	
	If ValueIsFilled(Parameters.ForEmailsInFolder) Then
		ForEmailsInFolder = Parameters.ForEmailsInFolder;
	Else 
		
		Query.Text = "
		|SELECT
		|	EmailMessageFolders.Ref
		|FROM
		|	Catalog.EmailMessageFolders AS EmailMessageFolders
		|WHERE
		|	EmailMessageFolders.PredefinedFolder
		|	AND EmailMessageFolders.Owner = &Owner
		|	AND EmailMessageFolders.Description = &Incoming";
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			Selection = Result.Select();
			Selection.Next();
			ForEmailsInFolder = Selection.Ref;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	AtLeastOneRuleSelected = False;
	Cancel = False;
	
	For each Rule In Rules Do
		
		If Rule.Apply Then
			AtLeastOneRuleSelected = True;
			Break;
		EndIf;
		
	EndDo;
	
	If Not AtLeastOneRuleSelected Then
		CommonClient.MessageToUser(
			NStr("ru = 'Необходимо выбрать хотя бы одно правило для применения'; en = 'Select at least one rule to apply'; pl = 'Select at least one rule to apply';de = 'Select at least one rule to apply';ro = 'Select at least one rule to apply';tr = 'Select at least one rule to apply'; es_ES = 'Select at least one rule to apply'"),,"List");
		Cancel = True;
	EndIf;
	
	If ForEmailsInFolder.IsEmpty() Then
		CommonClient.MessageToUser(
			NStr("ru = 'Не выбрана папка к письмам которой будут применены правила'; en = 'Folder to which emails rules will be applied is not selected'; pl = 'Folder to which emails rules will be applied is not selected';de = 'Folder to which emails rules will be applied is not selected';ro = 'Folder to which emails rules will be applied is not selected';tr = 'Folder to which emails rules will be applied is not selected'; es_ES = 'Folder to which emails rules will be applied is not selected'"),,"ForEmailsInFolder");
		Cancel = True;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	TimeConsumingOperation = ApplyRulesAtServer();
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed" Then
		Notify("MessageProcessingRulesApplied");
	ElsIf TimeConsumingOperation.Status = "Running" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CompletionNotification = New NotifyDescription("ApplyRulesCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyAllRules(Command)
	
	For each Row In Rules Do
		Row.Apply = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure DontApplyAllRules(Command)
	
	For each Row In Rules Do
		Row.Apply = False;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ApplyRulesAtServer()
	
	ProcedureParameters = New Structure;
	
	ProcedureParameters.Insert("RulesTable", Rules.Unload());
	ProcedureParameters.Insert("ForEmailsInFolder", ForEmailsInFolder);
	ProcedureParameters.Insert("IncludeSubordinateSubsystems", IncludeSubordinateSubsystems);
	ProcedureParameters.Insert("Account", Account);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Применение правил'; en = 'Applying rules'; pl = 'Applying rules';de = 'Applying rules';ro = 'Applying rules';tr = 'Applying rules'; es_ES = 'Applying rules'") + " ";
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
			"Catalogs.EmailProcessingRules.ApplyRules",
			ProcedureParameters,
			ExecutionParameters);
			
	If TimeConsumingOperation.Status = "Completed" Then
		ImportResult(TimeConsumingOperation.ResultAddress);
	EndIf;
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure ApplyRulesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	ElsIf Result.Status = "Completed" Then
		ImportResult(Result.ResultAddress);
		Notify("MessageProcessingRulesApplied");
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportResult(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	If TypeOf(Result) = Type("String")
		AND ValueIsFilled(Result) Then 
		Common.MessageToUser(Result);
	EndIf;
	
EndProcedure

#EndRegion
