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
	
	If Catalogs.AllRefsType().ContainsType(TypeOf(Parameters.RespondentType)) Then
		
		ListPropertiesStructure = Common.DynamicListPropertiesStructure();
		ListPropertiesStructure.MainTable = Parameters.RespondentType.Metadata().FullName();
		
		Common.SetDynamicListProperties(Items.Respondents, ListPropertiesStructure);
		
	Else
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RespondentsChoice(Item, RowSelected, Field, StandardProcessing)
	
	ArrayToPass = New Array;
	
	For each ArrayElement In RowSelected Do
		If NOT Items.Respondents.RowData(ArrayElement).Property("IsFolder") 
			OR NOT Items.Respondents.RowData(ArrayElement).IsFolder Then
			ArrayToPass.Add(ArrayElement);
		EndIf;
	EndDo;
	
	ProcessRespondentChoice(ArrayToPass);
	
EndProcedure

&AtClient
Procedure RespondentsValueChoice(Item, Value, StandardProcessing)
	
	ProcessRespondentChoice(Value);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessRespondentChoice(ChoiceArray)
	
	Notify("SelectRespondents",New Structure("SelectedRespondents",ChoiceArray));
	
EndProcedure

#EndRegion



