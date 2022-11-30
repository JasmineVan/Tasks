///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// For calling from the dashboard.

Procedure OpenPeriodEndClosingDates(OwnerForm) Export
	
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates",, OwnerForm);
	
EndProcedure	

Procedure OpenDataImportRestrictionDates(OwnerForm) Export
	
	FormParameters = New Structure("DataImportRestrictionDates", True);
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates", FormParameters, OwnerForm);
	
EndProcedure	

#EndRegion
