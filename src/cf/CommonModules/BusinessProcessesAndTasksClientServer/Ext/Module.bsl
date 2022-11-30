///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.

// Adding fields on whose basis a business process presentation will be generated.
//
// Parameters:
//  ObjectManager      - BusinessProcessManager - a business process manager.
//  Fields                 - Structure - fields used to generate a business process presentation.
//  StandardProcessing - Boolean - if False, the standard filling processing is skipped.
//                                  
//
Procedure BusinessProcessPresentationFieldsGetProcessing(ObjectManager, Fields, StandardProcessing) Export
	
	Fields.Add("Description");
	Fields.Add("Date");
	StandardProcessing = False;

EndProcedure

// CAC:547-off is called in the GetBusinessProcessPresentation event subscription.

// Use BusinessProcessesAndTasksClient.BusinessProcessPresentationGetProcessing for client calls
// Use BusinessProcessesAndTasksServer.BusinessProcessPresentationGetProcessing for server calls
// Processing for getting a business process presentation based on data fields.
//
// Parameters:
//  ObjectManager      - BusinessProcessManager - a business process manager.
//  Data               - Structure - the fields used to generate a business process presentation.
//  Presentation        - String - a business process presentation.
//  StandardProcessing - Boolean - if False, the standard filling processing is skipped.
//                                  
//
Procedure BusinessProcessPresentationGetProcessing(ObjectManager, Data, Presentation, StandardProcessing) Export
	
#If Server Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Or ExternalConnection Then
	Date = Format(Data.Date, ?(GetFunctionalOption("UseDateAndTimeInTaskDeadlines"), "DLF=DT", "DLF=D"));
	Presentation = Metadata.FindByType(TypeOf(ObjectManager)).Presentation();
#Else	
	Date = Format(Data.Date, "DLF=D");
	Presentation = NStr("ru = 'Бизнес-процесс'; en = 'Business process'; pl = 'Business process';de = 'Business process';ro = 'Business process';tr = 'Business process'; es_ES = 'Business process'");
#EndIf
	
	BusinessProcessPresentationGet(ObjectManager, Data, Date, Presentation, StandardProcessing);
	
EndProcedure

// CAC:547-on is called in the GetBusinessProcessPresentation event subscription.

#EndRegion

#Region Private

// Data processor of receiving a business process presentation based on data fields.
//
// Parameters:
//  ObjectManager      - BusinessProcessManager - a business process manager.
//  Data               - Structure - the fields used to generate a business process presentation.
//  Date                 - Date   - a business process creation date.
//  Presentation        - String - a business process presentation.
//  StandardProcessing - Boolean - if False, the standard filling processing is skipped.
//                                  
//
Procedure BusinessProcessPresentationGet(ObjectManager, Data, Date, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	PresentationTemplate  = NStr("ru = '%1 от %2 (%3)'; en = '%1 dated %2 (%3)'; pl = '%1 dated %2 (%3)';de = '%1 dated %2 (%3)';ro = '%1 dated %2 (%3)';tr = '%1 dated %2 (%3)'; es_ES = '%1 dated %2 (%3)'");
	Description         = ?(IsBlankString(Data.Description), NStr("ru = 'Без описания'; en = 'No description'; pl = 'No description';de = 'No description';ro = 'No description';tr = 'No description'; es_ES = 'No description'"), Data.Description);
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(PresentationTemplate, Description, Date, Presentation);
	
EndProcedure


#EndRegion

