﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(BulkEmail, Parameters)
	EventLogParameters = EventLogParameters(BulkEmail);
	If EventLogParameters = Undefined Then
		ShowMessageBox(, NStr("ru = 'Рассылка еще не выполнялась.'; en = 'Bulk email was not performed yet.'; pl = 'Bulk email was not performed yet.';de = 'Bulk email was not performed yet.';ro = 'Bulk email was not performed yet.';tr = 'Bulk email was not performed yet.'; es_ES = 'Bulk email was not performed yet.'"));
		Return;
	EndIf;
	OpenForm("DataProcessor.EventLog.Form", EventLogParameters, ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EventLogParameters(BulkEmail)
	Return ReportMailing.EventLogParameters(BulkEmail);
EndFunction

#EndRegion
