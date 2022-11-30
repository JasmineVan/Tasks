
////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	
	// Для счетов-групп всю строку выделяем желтым цветом.

	CAItem = ConditionalAppearance.Items.Add();
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "List");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.DenyUsingInEntries", DataCompositionComparisonType.Equal, True);
	
	CAItem.Appearance.SetParameterValue("BackColor", WebColors.LightYellow);


	// Активные счета

	CAItem = ConditionalAppearance.Items.Add();
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "Type");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.Type", DataCompositionComparisonType.Equal, AccountType.Active);
	
	CAItem.Appearance.SetParameterValue("Text", NStr("ru = 'a'"));


	// Пассивные счета

	CAItem = ConditionalAppearance.Items.Add();
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "Type");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.Type", DataCompositionComparisonType.Equal, AccountType.Passive);
	
	CAItem.Appearance.SetParameterValue("Text", NStr("ru = 'p'"));


	// Активно-пассивные счета

	CAItem = ConditionalAppearance.Items.Add();
	
	fmDataCompositionClientServer.AddAppearanceField(CAItem.Fields, "Type");
	
	CommonClientServer.AddCompositionItem(CAItem.Filter,
		"List.Type", DataCompositionComparisonType.Equal, AccountType.ActivePassive);
	
	CAItem.Appearance.SetParameterValue("Text", NStr("ru = 'ap'"));

EndProcedure
