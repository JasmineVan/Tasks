///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// The settings of the common report form of the "Reports options" subsystem.
//
// Parameters:
//   Form - ManagedForm, Undefined - a report form or a report settings form.
//       Undefined when called without a context.
//   OptionKey - String, Undefined - a name of a predefined report option or a UUID of a 
//       user-defined report option.
//       Undefined when called without a context.
//   Settings - Structure - see the return value of
//       ReportsClientServer.GetDefaultReportSettings().
//
Procedure DefineFormSettings(Form, OptionKey, Settings) Export
	Settings.GenerateImmediately = True;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	// Regenerating a title by a reference set.
	Settings = SettingsComposer.GetSettings();
	RefSet = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("RefSet") );
	If RefSet <> Undefined Then
		RefSet = RefSet.Value;
	EndIf;
	Title = TitleByRefSet(RefSet);
	SettingsComposer.FixedSettings.OutputParameters.SetParameterValue("Title", Title);
	
	CompositionProcessor = CompositionProcessor(DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
EndProcedure

#EndRegion

#Region Private

Function CompositionProcessor(DetailsData = Undefined, GeneratorType = "DataCompositionTemplateGenerator")
	
	Settings = SettingsComposer.GetSettings();
	
	// List of references from parameters.
	ParameterValue = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("RefSet") ).Value;
	ValueType = TypeOf(ParameterValue);
	If ValueType = Type("ValueList") Then
		RefsArray = ParameterValue.UnloadValues();
	ElsIf ValueType = Type("Array") Then
		RefsArray = ParameterValue;
	Else
		RefsArray = New Array;
		If ParameterValue <>Undefined Then
			RefsArray.Add(ParameterValue);
		EndIf;
	EndIf;
	
	// Parameters of output from fixed parameters.
	For Each OutputParameter In SettingsComposer.FixedSettings.OutputParameters.Items Do
		If OutputParameter.Use Then
			Item = Settings.OutputParameters.FindParameterValue(OutputParameter.Parameter);
			If Item <> Undefined Then
				Item.Use = True;
				Item.Value      = OutputParameter.Value;
			EndIf;
		EndIf;
	EndDo;
	
	// Data source tables
	UsageInstances = Common.UsageInstances(RefsArray);
	
	// Checking whether there are all references.
	For Each Ref In RefsArray Do
		If UsageInstances.Find(Ref, "Ref") = Undefined Then
			AdditionalInformation = UsageInstances.Add();
			AdditionalInformation.Ref = Ref;
			AdditionalInformation.AuxiliaryData = True;
		EndIf;
	EndDo;
		
	ExternalData = New Structure;
	ExternalData.Insert("UsageInstances", UsageInstances);
	
	// Execution
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData, , Type(GeneratorType));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, ExternalData, DetailsData);
	
	Return CompositionProcessor;
EndFunction

Function TitleByRefSet(Val RefSet)

	If TypeOf(RefSet) = Type("ValueList") Then
		TotalRefs = RefSet.Count();
		If TotalRefs = 1 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Места использования %1'; en = '%1 usage locations'; pl = 'Miejsca użycia %1';de = 'Verwendungsorte %1';ro = 'Locații de utilizare %1';tr = 'Kullanım yerleri %1'; es_ES = 'Ubicaciones de uso %1'"), Common.SubjectString(RefSet[0].Value));
		ElsIf TotalRefs > 1 Then
		
			EqualType = True;
			FirstRefType = TypeOf(RefSet[0].Value);
			For Position = 0 To TotalRefs - 1 Do
				If TypeOf(RefSet[Position].Value) <> FirstRefType Then
					EqualType = False;
					Break;
				EndIf;
			EndDo;
			
			If EqualType Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Места использования элементов ""%1"" (%2)'; en = '%1 (%2) usage locations'; pl = 'Miejsca zastosowania elementów ""%1"" (%2)';de = 'Verwendungsorte der Elemente ""%1"" (%2)';ro = 'Locurile de utilizare a elementelor ""%1"" (%2)';tr = 'Nesne kullanım konumları ""%1"" (%2)'; es_ES = 'Lugares de uso de los elementos ""%1"" (%2)'"), 
					RefSet[0].Value.Metadata().Presentation(),
					TotalRefs);
			Else		
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Места использования элементов (%1)'; en = '%1 usage locations'; pl = 'Miejsca zastosowania elementów (%1)';de = 'Verwendungsorte der Elemente (%1)';ro = 'Locurile de utilizare a elementelor (%1)';tr = 'Nesne kullanım konumları (%1)'; es_ES = 'Lugares de uso de los elementos (%1)'"), 
					TotalRefs);
			EndIf;
		EndIf;
		
	EndIf;
		
	Return NStr("ru = 'Места использования элементов'; en = 'Item usage locations'; pl = 'Miejsca użycia elementów';de = 'Artikel Verwendungsorte';ro = 'Locurile de utilizare a elementelor';tr = 'Öğe kullanım yerleri'; es_ES = 'Ubicaciones de uso de artículos'");

EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf