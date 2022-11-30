
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	CAItem = ConditionalAppearance.Items.Add();
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "List");
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.DenyUsingInEntries", DataCompositionComparisonType.Equal, True);
	CAItem.Appearance.SetParameterValue("BackColor", WebColors.LightYellow);
EndProcedure

#EndRegion
