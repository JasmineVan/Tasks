
&AtClient
Procedure SetupAvailability()
	For Num=1 To 3 Do
		If ThisForm["AnalyticsFillingOption"+Num]=PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.FixedValue") Then
			If Parameters.ItemSetting.Count()>0 AND ValueIsFilled(Parameters.ItemSetting[0]["AnalyticsType"+Num]) AND Parameters.AnalyticsAreKnown Then
				Items["Analytics"+Num].Enabled = True;
			Else
				Items["Analytics"+Num].Enabled = NOT Parameters.AnalyticsAreKnown;
			EndIf;
		Else
			Items["Analytics"+Num].Enabled = False;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Analytics1 = Parameters.Analytics1;
	Analytics2 = Parameters.Analytics2;
	Analytics3 = Parameters.Analytics3;
	AnalyticsFillingOption1 = Parameters.DependentAnalyticsFillingVariant1;
	AnalyticsFillingOption2 = Parameters.DependentAnalyticsFillingVariant2;
	AnalyticsFillingOption3 = Parameters.DependentAnalyticsFillingVariant3;
		
	For Num=1 To 3 Do
		If Parameters.ItemSetting.Count()>0 AND ValueIsFilled(Parameters.ItemSetting[0]["AnalyticsType"+Num]) Then
			Items["AnalyticsFillingOption"+Num].Enabled = True;
		Else
			Items["AnalyticsFillingOption"+Num].Enabled = NOT Parameters.AnalyticsAreKnown;
		EndIf;
		If Parameters.ItemSetting.Count()>0 AND ValueIsFilled(Parameters.ItemSetting[0]["AnalyticsType"+Num]) AND Parameters.AnalyticsAreKnown Then
			Items["Analytics"+Num].TypeRestriction = Parameters.ItemSetting[0]["AnalyticsType"+Num];
		Else
			Items["Analytics"+Num].TypeRestriction = Metadata.ChartsOfCharacteristicTypes.fmAnalyticsTypes.Type;
			Items["AnalyticsFillingOption"+Num].Enabled = NOT Parameters.AnalyticsAreKnown;
		EndIf;
	EndDo;
	
	Title = StrTemplate(NStr("en='Setting of cash flow item dimension ""%1""';ru='Настройка аналитик статьи ДДС ""%1""'"), TrimAll(Parameters.Item));
	
EndProcedure

&AtClient
Procedure FixedValue2StartChoice(Item, ChoiceData, StandardProcessing)
	Items[Item.Name].ChoiceParameters = New FixedArray(New Array());
	If ValueIsFilled(Analytics1) AND TypeOf(Analytics1) = Type("CatalogRef.fmCounterparties") Then
		NewParameter = New ChoiceParameter("Filter.Owner", Analytics1);
		NewArray = New Array();
		NewArray.Add(NewParameter);
		NewParameters = New FixedArray(NewArray);
		Items[Item.Name].ChoiceParameters = NewParameters;
	EndIf;
EndProcedure

&AtClient
Procedure OK(Command)
	For Num=1 To 3 Do
		If NOT ValueIsFilled(ThisForm["AnalyticsFillingOption"+Num]) Then
			CommonClientServer.MessageToUser("Необходимо указать все варианты заполнения аналитик!");
			Return;
		ElsIf ThisForm["AnalyticsFillingOption"+Num]=PredefinedValue("Enum.fmDependentAnalyticsFillingVariants.FixedValue")
		AND NOT ValueIsFilled(ThisForm["Analytics"+Num]) Then
			CommonClientServer.MessageToUser("Необходимо указать фиксированное значение аналитики " + Num + "!");
			Return;
		EndIf;
	EndDo;
	Notify("CashflowAnalytics", New Structure("Analytics1, Analytics2, Analytics3, DependentAnalyticsFillingVariant1, DependentAnalyticsFillingVariant2, DependentAnalyticsFillingVariant3", Analytics1, Analytics2, Analytics3, AnalyticsFillingOption1, AnalyticsFillingOption2, AnalyticsFillingOption3));
	Close();
EndProcedure

&AtClient
Procedure AnalyticsFillingOptionOnChange(Item)
	SetupAvailability();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetupAvailability();
EndProcedure









