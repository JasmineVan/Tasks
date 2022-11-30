///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region AdditionalPropertiesFormTableItemsEventHandlers

&AtClient
Procedure ObjectPropertiesOnChange(Item)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateTableRowsCounters()
	
	SetPageTitle(Items.AdditionalPropertiesPage, Object.ObjectProperties, NStr("ru = 'Дополнительные свойства'; en = 'Additional properties'; pl = 'Additional properties';de = 'Additional properties';ro = 'Additional properties';tr = 'Additional properties'; es_ES = 'Additional properties'"));
	
EndProcedure

&AtClient
Procedure SetPageTitle(PageItem, AttributeTabularSection, DefaultTitle)
	
	PageHeader = DefaultTitle;
	If AttributeTabularSection.Count() > 0 Then
		PageHeader = DefaultTitle + " (" + AttributeTabularSection.Count() + ")";
	EndIf;
	PageItem.Title = PageHeader;
	
EndProcedure

#EndRegion