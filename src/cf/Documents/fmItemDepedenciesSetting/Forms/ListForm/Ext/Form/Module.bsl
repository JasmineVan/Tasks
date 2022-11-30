
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(Parameters.IEItem) Then
		fmCommonUseClientServer.SetListFilterItem(List, "Item", Parameters.IEItem, DataCompositionComparisonType.Equal);
	EndIf;
EndProcedure

#EndRegion

