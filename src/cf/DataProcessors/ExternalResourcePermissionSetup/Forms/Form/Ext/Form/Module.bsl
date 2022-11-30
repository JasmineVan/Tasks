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
	
	Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor is not intended for direct usage.'; pl = 'The data processor is not intended for direct usage.';de = 'The data processor is not intended for direct usage.';ro = 'The data processor is not intended for direct usage.';tr = 'The data processor is not intended for direct usage.'; es_ES = 'The data processor is not intended for direct usage.'");
	
EndProcedure

#EndRegion
