///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(OptionRef, CommandExecuteParameters)
	Option = OptionRef;
	Form = CommandExecuteParameters.Source;
	If TypeOf(Form) = Type("ManagedForm") Then
		If Form.FormName = "Catalog.ReportsOptions.Form.ListForm" Then
			Option = Form.Items.List.CurrentData;
		ElsIf Form.FormName = "Catalog.ReportsOptions.Form.ItemForm" Then
			Option = Form.Object;
		EndIf;
	Else
		Form = Undefined;
	EndIf;
	
	ReportsOptionsClient.OpenReportForm(Form, Option);
EndProcedure

#EndRegion
