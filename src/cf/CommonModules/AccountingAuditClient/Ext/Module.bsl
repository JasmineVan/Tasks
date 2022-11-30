///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a report on all issues of the passed issue type.
//
// Parameters:
//   ChecksKind - CatalogRef.ChecksKinds - a reference to a check kind.
//               - String - a string ID of the Property1 check kind.
//               - Array - string IDs of the Property1...PropertyN check kind.
//
// Example:
//   OpenIssuesReport("SystemChecks");
//
Procedure OpenIssuesReport(ChecksKind) Export
	
	// Validity of the passed ChecksKind parameter is checked in the OnCreateAtServer procedure of the 
	// AccountingAuditResult report module.
	
	AccountingAuditInternalClient.OpenIssuesReport(ChecksKind);
	
EndProcedure

// Open the report form when clicking the hyperlink that informs of having issues.
//
//  Parameters:
//     Form                - ManagedForm - a managed form of a problem object.
//     ObjectWithIssue - ObjectRef - a reference to an object with issues.
//     StandardProcessing - Boolean - a flag indicating whether the standard (system) event 
//                            processing is executed is passed to this parameter.
//
// Example:
//    AccountingAuditClient.OpenObjectProblemsReport(ThisObject, Object.Ref, StandardProcessing);
//
Procedure OpenObjectIssuesReport(Form, ObjectWithIssue, StandardProcessing) Export
	
	// Validity of the passed Form, ObjectWithIssue, and StandardProcessing parameters is checked in the 
	// OnCreateAtServer procedure of the AccountingAuditResult report module.
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectRef", ObjectWithIssue);
	
	OpenForm("Report.AccountingCheckResults.Form", FormParameters);
	
EndProcedure

// Open the report form, double clicking the cell of the list form table with a picture, which 
// informs that the selected object has some issues.
//
//  Parameters:
//     Form                   - ManagedForm - a managed form of an object with issues.
//     ListName - String - a name of form attribute linked to a dynamic list.
//     Field                    - FormField - a column containing picture that informs of existing 
//                               issues.
//     StandardProcessing    - Boolean - this parameter is used to indicate whether the standard 
//                               (system) event processing is performed.
//     AdditionalParameters - Structure, Undefined - contains additional properties in case you need 
//                               to use them.
//
// Example:
//    AccountingAuditClient.OpenListedIssuesReport("ThisObject", "List", Field, StandardProcessing);
//
Procedure OpenListedIssuesReport(Form, ListName, Field, StandardProcessing, AdditionalParameters = Undefined) Export
	
	ProcedureName = "AccountingAuditClient.OpenListedIssuesReport";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ManagedForm"));
	CommonClientServer.CheckParameter(ProcedureName, "ListName", ListName, Type("String"));
	CommonClientServer.CheckParameter(ProcedureName, "Field", Field, Type("FormField"));
	CommonClientServer.CheckParameter(ProcedureName, "StandardProcessing", StandardProcessing, Type("Boolean"));
	If AdditionalParameters <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalParameters", AdditionalParameters, Type("Structure"));
	EndIf;
	
	AdditionalProperties = Form[ListName].SettingsComposer.Settings.AdditionalProperties;
	
	If Not (AdditionalProperties.Property("IndicatorColumn")
		AND AdditionalProperties.Property("MetadataObjectKind")
		AND AdditionalProperties.Property("MetadataObjectName")
		AND AdditionalProperties.Property("ListName")) Then
		StandardProcessing = True;
	Else
		
		FormTable   = Form.Items.Find(AdditionalProperties.ListName);
		
		If Field.Name <> AdditionalProperties.IndicatorColumn Then
			StandardProcessing = True;
		Else
			StandardProcessing = False;
			
			ContextData = New Structure;
			ContextData.Insert("SelectedRows",     FormTable.SelectedRows);
			ContextData.Insert("MetadataObjectKind", AdditionalProperties.MetadataObjectKind);
			ContextData.Insert("MetadataObjectName", AdditionalProperties.MetadataObjectName);
			
			FormParameters = New Structure;
			FormParameters.Insert("ContextData", ContextData);
			OpenForm("Report.AccountingCheckResults.Form", FormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
