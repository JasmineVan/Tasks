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
	
	If Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Мои дополнительные обработки (%1)'; en = 'My additional data processors (%1)'; pl = 'Moje dodatkowe procedury przetwarzania (%1)';de = 'Meine zusätzlichen Bearbeitungen (%1)';ro = 'Procesările mele suplimentare (%1)';tr = 'Ek veri işlemcilerim (%1)'; es_ES = 'Mis procesamientos adicionales (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	ElsIf Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Мои дополнительные отчеты (%1)'; en = 'My additional reports (%1)'; pl = 'Moje sprawozdania dodatkowe (%1)';de = 'Meine zusätzlichen Berichte (%1)';ro = 'Rapoartele mele suplimentare (%1)';tr = 'Ek raporlarım (%1)'; es_ES = 'Mis informes adicionales (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	EndIf;
	
	CommandsTypes = New Array;
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ClientMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.OpeningForm);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode);
	
	Query = AdditionalReportsAndDataProcessors.NewQueryByAvailableCommands(Parameters.DataProcessorsKind, Parameters.SectionRef, , CommandsTypes, False);
	ResultTable = Query.Execute().Unload();
	UsedCommands.Load(ResultTable);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ClearAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = False;
	EndDo;
EndProcedure

&AtClient
Procedure SelectAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = True;
	EndDo;
EndProcedure

&AtClient
Procedure OK(Command)
	WriteUserDataProcessorsSet();
	NotifyChoice("MyReportsAndDataProcessorsSetupDone");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteUserDataProcessorsSet()
	Table = UsedCommands.Unload();
	Table.Columns.Ref.Name        = "AdditionalReportOrDataProcessor";
	Table.Columns.ID.Name = "CommandID";
	Table.Columns.Use.Name = "Available";
	DimensionValues = New Structure("User", Users.AuthorizedUser());
	ResourcesValues  = New Structure;
	SetPrivilegedMode(True);
	InformationRegisters.DataProcessorAccessUserSettings.WriteSettingsPackage(Table, DimensionValues, ResourcesValues, False);
EndProcedure

#EndRegion
