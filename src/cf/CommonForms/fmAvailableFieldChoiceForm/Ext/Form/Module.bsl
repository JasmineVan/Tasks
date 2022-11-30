
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	Mode = Parameters.Mode;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Parameters.DataCompositionSchema));
	ComposerSettings = SettingsComposer.Settings;
	
	Items.GroupSelectionAvailableFields.Visible       = False;
	Items.GroupGroupFieldsAvailableFields.Visible = False;
	Items.GroupFilterAvailableFields.Visible       = False;
	Items.GroupOrderAvailableFields.Visible     = False;
	
	If Mode = "Group" Then
		
		Title = NStr("en='Select group field';ru='Выбор поля группировки'");
		Items.GroupGroupFieldsAvailableFields.Visible = True;
		AvailableFieldsItems = Items.GroupFieldsAvailableFields;
		AvailableFieldsSettings = ComposerSettings.GroupAvailableFields;
		
		FictiveRowGroup = ComposerSettings.Structure.Add(Type("DataCompositionGroup"));
		Items.Settings.CurrentRow = ComposerSettings.GetIDByObject(FictiveRowGroup);

	ElsIf Mode = "CASE" Then
		
		Title = NStr("en='Select field';ru='Выбор поля'");
		Items.GroupSelectionAvailableFields.Visible = True;
		AvailableFieldsItems = Items.SelectionAvailableFields;
		AvailableFieldsSettings = ComposerSettings.SelectionAvailableFields;
		
	ElsIf Mode = "Filter" Then	
		
		Title = NStr("en='Select filter field';ru='Выбор поля отбора'");
		Items.GroupFilterAvailableFields.Visible = True;
		AvailableFieldsItems = Items.FilterAvailableFields;
		AvailableFieldsSettings = ComposerSettings.FilterAvailableFields;
		
	ElsIf Mode = "Order" Then
		
		Title = NStr("en='Select sorting field';ru='Выбор поля сортировки'");
		Items.GroupOrderAvailableFields.Visible = True;
		AvailableFieldsItems = Items.OrderAvailableFields;
		AvailableFieldsSettings = ComposerSettings.OrderAvailableFields;
		
	Else
		Raise NStr("en='Invalid form call mode';ru='Неверный режим вызова формы'");
	EndIf;
	
	For Each Field In Parameters.DeniedFields Do
		
		Restriction = AvailableFieldsItems.UseRestrictions.Add();	
		Restriction.Field = New DataCompositionField(Field);
		Restriction.Enabled = False;

	EndDo;
	
	If Parameters.CurrentRow <> Undefined Then
		
		AvailableField = AvailableFieldsSettings.FindField(New DataCompositionField(Parameters.CurrentRow));
		If AvailableField <> Undefined Then
			
			ID = AvailableFieldsSettings.GetIDByObject(AvailableField);
			AvailableFieldsItems.CurrentRow = ID;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandOK(Command)
	
	CurrentData = Undefined;
	If Mode = "Group" Then
		CurrentData = Items.GroupFieldsAvailableFields.CurrentRow;
		AvailableField = SettingsComposer.Settings.GroupAvailableFields.GetObjectByID(CurrentData);
	ElsIf Mode = "CASE" Then
		CurrentData = Items.SelectionAvailableFields.CurrentRow;
		AvailableField = SettingsComposer.Settings.SelectionAvailableFields.GetObjectByID(CurrentData);
	ElsIf Mode = "Filter" Then
		CurrentData = Items.FilterAvailableFields.CurrentRow;
		AvailableField = SettingsComposer.Settings.FilterAvailableFields.GetObjectByID(CurrentData);
	ElsIf Mode = "Order" Then
		CurrentData = Items.OrderAvailableFields.CurrentRow;
		AvailableField = SettingsComposer.Settings.OrderAvailableFields.GetObjectByID(CurrentData);
	EndIf;
	
	If NOT AvailableField.Folder Then
		SelectedFieldParameters = New Structure;
		SelectedFieldParameters.Insert("Field"     , String(AvailableField.Field));
		SelectedFieldParameters.Insert("Title", AvailableField.Title);
		If Mode = "Filter" Then
			If AvailableField.AvailableCompareTypes.Count() > 0 Then
				SelectedFieldParameters.Insert("ComparisonType", AvailableField.AvailableCompareTypes[0].Value);
			Else
				SelectedFieldParameters.Insert("ComparisonType", DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		Close(SelectedFieldParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupFieldsAvailableFieldsChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CommandOK(Undefined);
	
EndProcedure

&AtClient
Procedure SelectionAvailableFieldsChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CommandOK(Undefined);
	
EndProcedure

&AtClient
Procedure OrderAvailableFieldsChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CommandOK(Undefined);
	
EndProcedure

&AtClient
Procedure FilterAvailableFieldsChoice(Item, SelectedRow, Field, StandardProcessing)
	
	CommandOK(Undefined);
	
EndProcedure


