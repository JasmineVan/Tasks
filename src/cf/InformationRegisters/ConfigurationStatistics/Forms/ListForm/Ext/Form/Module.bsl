///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	List.Parameters.SetParameterValue("Metadata", NStr("ru='Метаданные'; en = 'Metadata'; pl = 'Metadata';de = 'Metadata';ro = 'Metadata';tr = 'Metadata'; es_ES = 'Metadata'"));
	List.Parameters.SetParameterValue("FunctionalOption", NStr("ru='Функциональная опция'; en = 'Functional option'; pl = 'Functional option';de = 'Functional option';ro = 'Functional option';tr = 'Functional option'; es_ES = 'Functional option'"));
EndProcedure

#EndRegion
