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
	
	RelativeSize = Parameters.RelativeSize;
	MinEffect = Parameters.MinEffect;
	Items.MinEffect.Visible = Parameters.RebuildMode;
	Title = ?(Parameters.RebuildMode,
	              NStr("ru='Параметры перестроения'; en = 'Rebuild parameters'; pl = 'Rebuild parameters';de = 'Rebuild parameters';ro = 'Rebuild parameters';tr = 'Rebuild parameters'; es_ES = 'Rebuild parameters'"),
	              NStr("ru='Параметр расчета оптимальных агрегатов'; en = 'Parameter of optimal aggregate calculation'; pl = 'Parameter of optimal aggregate calculation';de = 'Parameter of optimal aggregate calculation';ro = 'Parameter of optimal aggregate calculation';tr = 'Parameter of optimal aggregate calculation'; es_ES = 'Parameter of optimal aggregate calculation'"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("RelativeSize, MinEffect");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
