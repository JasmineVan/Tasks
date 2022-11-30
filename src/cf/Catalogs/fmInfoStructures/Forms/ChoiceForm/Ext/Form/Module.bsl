
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("StructureType") Then
		fmCommonUseClientServer.SetListFilterItem(List, "StructureType", Parameters.StructureType);
	EndIf;
	If Parameters.Property("Key") AND ValueIsFilled(Parameters.Key) Then
		Items.List.CurrentRow = Parameters.Key;
	EndIf;
EndProcedure

&AtClient
Procedure WithoutStructure(Command)
	Close(PredefinedValue("Catalog.fmInfoStructures.EmptyRef"));
EndProcedure

#EndRegion


