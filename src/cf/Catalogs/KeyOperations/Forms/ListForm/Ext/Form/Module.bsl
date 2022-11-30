﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ItemOverallPerformance = PerformanceMonitorInternal.GetOverallSystemPerformanceItem();
	If ValueIsFilled(ItemOverallPerformance) Then
		PerformanceMonitorClientServer.SetDynamicListFilterItem(
			List, "Ref", ItemOverallPerformance,
			DataCompositionComparisonType.NotEqual, , ,
			DataCompositionSettingsItemViewMode.Normal);
	EndIf;
EndProcedure

#EndRegion
