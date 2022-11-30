///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is executed upon starting a scheduled job.
//
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	
	
	
	
	
	
	
	
EndProcedure

// This procedure defines default settings applied to subsystem objects.
//
// Parameters:
//   Settings - Structure - a subsystem settings collection. Attributes:
//       * EnableNotifications - Boolean - a default value for user notifications:
//           True - by default, the system administrator is notified, for example, if there is no "To do list" subsystem.
//           False - by default, the system administrator is not notified.
//           The default value depends on availability of the "To do list" subsystem.
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

#EndRegion
