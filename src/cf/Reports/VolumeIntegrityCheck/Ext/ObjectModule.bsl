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
	
	FilesTableOnHardDrive = New ValueTable;
	FilesTableOnHardDrive.Columns.Add("Name");
	FilesTableOnHardDrive.Columns.Add("File");
	FilesTableOnHardDrive.Columns.Add("BaseName");
	FilesTableOnHardDrive.Columns.Add("FullName");
	FilesTableOnHardDrive.Columns.Add("Path");
	FilesTableOnHardDrive.Columns.Add("Volume");
	FilesTableOnHardDrive.Columns.Add("Extension");
	FilesTableOnHardDrive.Columns.Add("VerificationStatus");
	FilesTableOnHardDrive.Columns.Add("Count");
	FilesTableOnHardDrive.Columns.Add("WasEditedBy");
	FilesTableOnHardDrive.Columns.Add("ModificationDate");
	
	ParameterVolume = SettingsComposer.Settings.DataParameters.Items.Find("Volume");
	
	If ParameterVolume <> Undefined Then
		VolumePath = FilesOperationsInternal.FullVolumePath(ParameterVolume.Value);
	EndIf;
	
	FilesArray = FindFiles(VolumePath,"*", True);
	For Each File In FilesArray Do
		If Not File.IsFile() Then 
			Continue;
		EndIf;
		NewRow = FilesTableOnHardDrive.Add();
		NewRow.Name = File.Name;
		NewRow.BaseName = File.BaseName;
		NewRow.FullName = File.FullName;
		NewRow.Path = File.Path;
		NewRow.Extension = File.Extension;
		NewRow.VerificationStatus = NStr("ru = 'Лишние файлы (есть на диске, но сведения о них отсутствуют)'; en = 'Excess files (they exist on disk but no information on them is available)'; pl = 'Zbędne pliki (są na dysku, ale brakuje o nich informacji)';de = 'Nicht benötigte Dateien (es gibt einige auf der Festplatte, aber keine Informationen darüber sind verfügbar)';ro = 'Fișiere nedorite (există pe disc, dar informațiile despre ele lipsesc)';tr = 'Fazlalık dosyalar (diskte mevcut, ancak onlar ile ilgili veri yok)'; es_ES = 'Archivos innecesarios (hay en el disco pero no hay información de ellos)'");
		NewRow.Count = 1;
		NewRow.Volume = ParameterVolume.Value;
	EndDo;
	
	FilesOperationsInternal.CheckFilesIntegrity(FilesTableOnHardDrive, ParameterVolume.Value);
	
	StandardProcessing = False;
	
	ResultDocument.Clear();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Settings = SettingsComposer.GetSettings();
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("VolumeCheckTable", FilesTableOnHardDrive);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", FilesTableOnHardDrive.Count() = 0);
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ReportSettings = SettingsComposer.GetSettings();
	Volume = ReportSettings.DataParameters.Items.Find("Volume").Value;
	
	If Not ValueIsFilled(Volume) Then
		Common.MessageToUser(
			NStr("ru = 'Не заполнено значение параметра Том'; en = 'Please fill the ""Volume"" parameter.'; pl = 'Wartość parametru Wolumin nie jest wypełniona';de = 'Nicht ausgefüllter Volume-Wert';ro = 'Nu este completată valoarea parametrului Volum';tr = 'Birim parametresinin değeri doldurulmadı'; es_ES = 'No se ha rellenado el valor del parámetro Tomo'"), , );
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf