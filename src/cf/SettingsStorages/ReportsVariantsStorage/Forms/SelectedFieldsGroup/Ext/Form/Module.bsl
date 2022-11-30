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
	
	DefineBehaviorInMobileClient();
	
	Parameters.Property("GroupTitle", GroupTitle);
	
	Location = Undefined;
	If Not Parameters.Property("Placement", Location) Then
		Raise NStr("ru = 'Не передан служебный параметр ""Расположение"".'; en = 'Location service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ""Położenie"".';de = 'Der Serviceparameter "" Standort "" wird nicht übertragen.';ro = 'Parametrul de service ""Locația"" nu este transmis.';tr = '""Düzen"" servis parametresi aktarılamadı.'; es_ES = 'No se ha pasado el parámetro de servicio ""Situación"".'");
	EndIf;
	If Location = DataCompositionFieldPlacement.Auto Then
		GroupPlacement = "Auto";
	ElsIf Location = DataCompositionFieldPlacement.Vertically Then
		GroupPlacement = "Vertically";
	ElsIf Location = DataCompositionFieldPlacement.Together Then
		GroupPlacement = "Together";
	ElsIf Location = DataCompositionFieldPlacement.Horizontally Then
		GroupPlacement = "Horizontally";
	ElsIf Location = DataCompositionFieldPlacement.SpecialColumn Then
		GroupPlacement = "SpecialColumn";
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Некорректное значение параметра ""Расположение"": ""%1"".'; en = 'Location parameter contains invalid value: %1.'; pl = 'Niepoprawna wartość parametru ""Lokalizacja"": ""%1"".';de = 'Falscher Wert des Parameters ""Standort"": ""%1"".';ro = 'Valoare incorectă a parametrului ""Locația"": ""%1"".';tr = '""Konum"" parametresinin yanlış değeri: ""%1"".'; es_ES = 'Valor incorrecto del parámetro ""Ubicación"": ""%1"".'"), String(Location));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	SelectAndClose();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtClient
Procedure SelectAndClose()
	SelectionResult = New Structure;
	SelectionResult.Insert("GroupTitle", GroupTitle);
	SelectionResult.Insert("Placement", DataCompositionFieldPlacement[GroupPlacement]);
	NotifyChoice(SelectionResult);
	If IsOpen() Then
		Close(SelectionResult);
	EndIf;
EndProcedure

#EndRegion