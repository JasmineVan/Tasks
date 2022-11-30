///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = NStr("ru='Настройка очистки файлов:'; en = 'File cleanup settings:'; pl = 'Ustawienia oczyszczania plików:';de = 'Einstellen der Dateibereinigung:';ro = 'Setarea golirii fișierelor:';tr = 'Dosya temizleme ayarı:'; es_ES = 'Ajuste de vaciar los archivos:'")
		+ " " + Record.FileOwner;
	
	If AttributesArrayWithDateType.Count() = 0 Then
		Items.AddConditionByDate.Enabled = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.SettingRuleFilterColumnGroupApply.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.FilterRule = New ValueStorage(Rule.GetSettings());
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If ValueIsFilled(CurrentObject.FileOwner) Then
		InitializeComposer();
	EndIf;
	If CurrentObject.FilterRule.Get() <> Undefined Then
		Rule.LoadSettings(CurrentObject.FilterRule.Get());
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If ChoiceSource.FormName = "InformationRegister.FilesClearingSettings.Form.FormAddConditionByDate" Then
		AddToFilterIntervalException(SelectedValue);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeComposer()
	
	If Not ValueIsFilled(Record.FileOwner) Then
		Return;
	EndIf;
	
	Rule.Settings.Filter.Items.Clear();
	
	DCS = New DataCompositionSchema;
	DataSource = DCS.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	
	DCS.TotalFields.Clear();
	
	DCS.DataSets[0].Query = GetQueryText();
	
	DataCompositionSchema = PutToTempStorage(DCS, UUID);
	
	Rule.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Rule.Refresh(); 
	Rule.Settings.Structure.Clear();
	
EndProcedure

&AtServer
Function GetQueryText()
	
	AttributesArrayWithDateType.Clear();
	If TypeOf(Record.FileOwner) = Type("CatalogRef.MetadataObjectIDs") Then
		ObjectType = Record.FileOwner;
	Else
		ObjectType = Common.MetadataObjectID(TypeOf(Record.FileOwner));
	EndIf;
	AllCatalogs = Catalogs.AllRefsType();
	AllDocuments = Documents.AllRefsType();
	QueryText = 
		"SELECT
		|	" + ObjectType.Name + ".Ref,";
	If AllCatalogs.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
		Catalog = Metadata.Catalogs[ObjectType.Name];
		For Each Attribute In Catalog.Attributes Do
			QueryText = QueryText + Chars.LF + ObjectType.Name + "." + Attribute.Name + ",";
		EndDo;
	ElsIf
		AllDocuments.ContainsType(TypeOf(ObjectType.EmptyRefValue)) Then
		Document = Metadata.Documents[ObjectType.Name];
		For Each Attribute In Document.Attributes Do
			QueryText = QueryText + Chars.LF + ObjectType.Name + "." + Attribute.Name + ",";
			If Attribute.Type.ContainsType(Type("Date")) Then
				AttributesArrayWithDateType.Add(Attribute.Name, Attribute.Synonym);
				QueryText = QueryText + Chars.LF + "DATEDIFF(" + Attribute.Name + ", &CurrentDate, DAY) AS DaysBeforeDeletionFrom" + Attribute.Name + ",";
			EndIf;
		EndDo;
	EndIf;
	
	// Deleting an extra comma
	QueryText= Left(QueryText, StrLen(QueryText) - 1);
	QueryText = QueryText + "
	               |FROM
	               |	" + ObjectType.FullName+ " AS " + ObjectType.Name;
	
	Return QueryText;
	
EndFunction

&AtClient
Procedure AddConditionByDate(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ArrayOfValues", AttributesArrayWithDateType);
	OpenForm("InformationRegister.FilesClearingSettings.Form.FormAddConditionByDate", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure AddToFilterIntervalException(SelectedValue)
	
	FilterByInterval = Rule.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterByInterval.LeftValue = New DataCompositionField("DaysBeforeDeletionFrom" + SelectedValue.DateTypeAttribute);
	FilterByInterval.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	FilterByInterval.RightValue = SelectedValue.IntervalException;
	PresentationOfAttributeWithDateType = AttributesArrayWithDateType.FindByValue(SelectedValue.DateTypeAttribute).Presentation;
	PresentationText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Очищать спустя %1 дней относительно даты (%2)'; en = 'Clean up in %1 days after ""%2""'; pl = 'Oczyszczaj po %1 dniach w stosunku do daty (%2)';de = 'Bereinigen nach %1 Tagen relativ zum Datum (%2)';ro = 'Golire peste %1 zile în raport cu data (%2)';tr = '(%1) tarihe göre %2 gün sonra temizle'; es_ES = 'Vaciar pasados %1 días de la fecha (%2)'"), 
		SelectedValue.IntervalException, PresentationOfAttributeWithDateType);
	FilterByInterval.Presentation = PresentationText;

EndProcedure

#EndRegion