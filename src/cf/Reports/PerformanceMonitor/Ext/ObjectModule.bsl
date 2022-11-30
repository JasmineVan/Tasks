///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	PeriodSetting = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	PeriodUserSetting = SettingsComposer.UserSettings.Items.Find(PeriodSetting.UserSettingID);
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("BeginOfPeriod");
	DataParameter.Value = ToUniversalTime(PeriodUserSetting.Value.StartDate);
	DataParameter.Use = True;
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("EndOfPeriod");
	DataParameter.Value = ToUniversalTime(PeriodUserSetting.Value.EndDate);
	DataParameter.Use = True;
	
	ComparisonPeriodSetting = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriod");
	ComparisonPeriodUserSetting = SettingsComposer.UserSettings.Items.Find(ComparisonPeriodSetting.UserSettingID);
	
	If ComparisonPeriodUserSetting <> Undefined
		AND ComparisonPeriodUserSetting.Use Then
	
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodStartNumber");
		DataParameter.Value = (ToUniversalTime(ComparisonPeriodUserSetting.Value.StartDate) - Date(1,1,1)) * 1000;
		DataParameter.Use = True;
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodEndNumber");
		DataParameter.Value = (ToUniversalTime(ComparisonPeriodUserSetting.Value.EndDate) - Date(1,1,1)) * 1000;
		DataParameter.Use = True;
		
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonType");
		DataParameterComparisonType = SettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If DataParameterComparisonType.Value = "LeftJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "LEFT JOIN");
		ElsIf DataParameterComparisonType.Value = "InnerJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "INNER JOIN");
		ElsIf DataParameterComparisonType.Value = "FullJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "FULL JOIN");
		EndIf;
	Else
		
		If ComparisonPeriodUserSetting = Undefined Then
			ComparisonPeriodSetting.Use = False;
			DataParameterComparisonType = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonType");
			DataParameterComparisonType.Use = False;
		EndIf;
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodStartNumber");
        DataParameter.Value = 2;
        DataParameter.Use = True;
        
        DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodEndNumber");
        DataParameter.Value = 1;
        DataParameter.Use = True;
        
		QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
		DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "LEFT JOIN");
	EndIf;

	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf