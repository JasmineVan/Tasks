
&AtClient
Procedure Analytics2StartChoice(Item, ChoiceData, StandardProcessing)
	Items[Item.Name].ChoiceParameters = New FixedArray(New Array());
	If ValueIsFilled(Analytics1) AND TypeOf(Analytics1) = Type("CatalogRef.fmCounterparties") Then
		NewParameter = New ChoiceParameter("Filter.Owner", Analytics1);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items[Item.Name].ChoiceParameters = NewParameters;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Analytics1 = Parameters.Analytics1;
	Analytics2 = Parameters.Analytics2;
	Analytics3 = Parameters.Analytics3;
	For Num=1 To 3 Do
		If ValueIsFilled(Parameters.ItemSetting["AnalyticsType"+Num]) AND Parameters.AnalyticsAreKnown Then
			Items["Analytics"+Num].TypeRestriction = Parameters.ItemSetting["AnalyticsType"+Num];
		Else
			Items["Analytics"+Num].Enabled = False;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure OK(Command)
	Notify("IEAnalytics", New Structure("Analytics1, Analytics2, Analytics3", Analytics1, Analytics2, Analytics3));
	Close();
EndProcedure



