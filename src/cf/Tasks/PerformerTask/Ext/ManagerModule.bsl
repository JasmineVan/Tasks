///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Author");
	Result.Add("Importance");
	Result.Add("CompletionDate");
	Result.Add("StartDate");
	Result.Add("AcceptForExecutionDate");
	Result.Add("Topic");
	Result.Add("AcceptedForExecution");
	Result.Add("DueDate");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS PerformerTask
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
	|ON
	|	PerformerTask.PerformerRole = TaskPerformers.PerformerRole
	|	AND PerformerTask.MainAddressingObject = TaskPerformers.MainAddressingObject
	|	AND PerformerTask.AdditionalAddressingObject = TaskPerformers.AdditionalAddressingObject
	|;
	|AllowRead
	|WHERE
	|	ValueAllowed(Author)
	|	OR ValueAllowed(Performer)
	|	OR ValueAllowed(TaskPerformers.Performer)
	|	OR ObjectReadingAllowed(BusinessProcess)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Performer)
	|	OR ValueAllowed(TaskPerformers.Performer)";
	
	Restriction.TextForExternalUsers =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Performer)
	|	OR ValueAllowed(Author)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" AND Parameters.Property("Key") Then
		FormParameters = BusinessProcessesAndTasksServerCall.TaskExecutionForm(Parameters.Key);
		TaskFormName = "";
		Result = FormParameters.Property("FormName", TaskFormName);
		If Result Then
			SelectedForm = TaskFormName;
			StandardProcessing = False;
			CommonClientServer.SupplementStructure(Parameters, FormParameters.FormParameters, False);
		EndIf; 
	EndIf;

EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	Fields.Add("Description");
	Fields.Add("Date");
	StandardProcessing = False;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	Description = ?(IsBlankString(Data.Description), NStr("ru = 'Без описания'; en = 'No description'; pl = 'No description';de = 'No description';ro = 'No description';tr = 'No description'; es_ES = 'No description'"), Data.Description);
	Date = Format(Data.Date, ?(GetFunctionalOption("UseDateAndTimeInTaskDeadlines"), "DLF=DT", "DLF=D"));
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 от %2'; en = '%1 from %2'; pl = '%1 from %2';de = '%1 from %2';ro = '%1 from %2';tr = '%1 from %2'; es_ES = '%1 from %2'"), Description, Date);
	StandardProcessing = False;
	
EndProcedure

#EndRegion

