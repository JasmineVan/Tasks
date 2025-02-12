﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ObjectRef = Parameters.Ref;
	
	CommonTemplate = InformationRegisters.ObjectsVersions.GetTemplate("StandardObjectPresentationTemplate");
	
	LightGrayColor = StyleColors.InaccessibleCellTextColor;
	VioletRedColor = StyleColors.DeletedAttributeTitleBackground;
	
	If TypeOf(Parameters.VersionsToCompare) = Type("Array") Then
		VersionsToCompare = New ValueList;
		For Each VersionNumber In Parameters.VersionsToCompare Do
			VersionsToCompare.Add(VersionNumber, VersionNumber);
		EndDo;
	ElsIf TypeOf(Parameters.VersionsToCompare) = Type("ValueList") Then
		VersionsToCompare = Parameters.VersionsToCompare;
	Else // Using the passed object version.
		SerializedObject = GetFromTempStorage(Parameters.SerializedObjectAddress);
		If Parameters.ByVersion Then // Using single-version report.
			ReportTable = ObjectsVersioning.ReportOnObjectVersion(ObjectRef, SerializedObject);
		EndIf;
		Return;
	EndIf;
		
	VersionsToCompare.SortByValue();
	If VersionsToCompare.Count() > 1 Then
		VersionNumberString = "";
		For Each Version In VersionsToCompare Do
			VersionNumberString = VersionNumberString + String(Version.Presentation) + ", ";
			ObjectVersion = ObjectsVersioning.ObjectVersionInfo(ObjectRef, Version.Value).ObjectVersion;
			If TypeOf(ObjectVersion) = Type("Structure") AND ObjectVersion.Property("SpreadsheetDocuments") Then
				SpreadsheetDocuments.Add(ObjectVersion.SpreadsheetDocuments);
			EndIf;
		EndDo;
		
		VersionNumberString = Left(VersionNumberString, StrLen(VersionNumberString) - 2);
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сравнение версий ""%1"" (№№ %2)'; en = 'Comparing versions of ""%1"" (#%2)'; pl = 'Porównanie wersji ""%1"" (NrNr %2)';de = 'Versionsvergleich ""%1"" (Nr. %2)';ro = 'Compararea versiunilor ""%1"" (Nr.Nr. %2)';tr = '""%1"" (no.%2) sürümünü karşılaştır'; es_ES = 'Comparar las versiones ""%1"" (№№ %2)'"),
			Common.SubjectString(ObjectRef), VersionNumberString);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Версия объекта ""%1"" №%2'; en = 'Object %1 version #%2'; pl = 'Wersja nr %2 obiektu ""%1""';de = 'Revision #%2 des Objekts ""%1"".';ro = 'Versiunea Nr.%2 a obiectului ""%1""';tr = '""%1"" nesnesinin no.%2 revizyonu'; es_ES = 'Revisión #%2 del objeto ""%1""'"),
			ObjectRef, String(VersionsToCompare[0].Presentation));
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Generate();
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportTableChoice(Item, Area, StandardProcessing)
	
	Details = Area.Details;
	
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If Details.Property("Compare") Then
			OpenSpreadsheetDocumentsComparisonForm(Details.Compare, Details.Version0, Details.Version1);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Generate()
	If VersionsToCompare.Count() = 1 Then
		GenerateVersionReport();
	Else
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ReportTable, "ReportGeneration");
		AttachIdleHandler("StartGenerateVersionsReport", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure StartGenerateVersionsReport()
	TimeConsumingOperation = GenerateVersionsReport();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotifyDescription = New NotifyDescription("OnCompleteGenerateReport", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
EndProcedure

&AtServer
Function GenerateVersionsReport()
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
	ReportParameters = New Structure;
	ReportParameters.Insert("ObjectRef", ObjectRef);
	ReportParameters.Insert("VersionsList", VersionsToCompare);
	Return TimeConsumingOperations.ExecuteInBackground("InformationRegisters.ObjectsVersions.GenerateReportOnChanges", ReportParameters, ExecutionParameters);
EndFunction

&AtClient
Procedure OnCompleteGenerateReport(Result, AdditionalParameters) Export
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ReportTable, "DontUse");
	If Result.Status = "Completed" Then
		ReportTable = GetFromTempStorage(Result.ResultAddress);
	Else
		Raise Result.BriefErrorPresentation;
	EndIf;
EndProcedure

&AtServer
Procedure GenerateVersionReport()
	ReportTable = ObjectsVersioning.ReportOnObjectVersion(ObjectRef, VersionsToCompare[0].Value, VersionsToCompare[0].Presentation);
EndProcedure

&AtClient
Procedure OpenSpreadsheetDocumentsComparisonForm(SpreadsheetDocumentName, Version0, Version1)
	
	TitleTemplate = NStr("ru='Версия №%1'; en = 'Version #%1'; pl = 'Wersja Nr%1';de = 'Version Nr.%1';ro = 'Versiunea nr.%1';tr = 'Sürüm No%1'; es_ES = 'Versión №%1'");
	VersionNumber0 = Format(VersionsToCompare[Version0], "NG=0");
	VersionNumber1 = Format(VersionsToCompare[Version1], "NG=0");
	TitleLeft = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate, VersionNumber1);
	TitleRight = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate, VersionNumber0);
	
	SpreadsheetDocumentsAddress = GetSpreadsheetDocumentsAddress(SpreadsheetDocumentName, Version1, Version0);
	FormOpenParameters = New Structure("SpreadsheetDocumentsAddress, TitleLeft, TitleRight", 
		SpreadsheetDocumentsAddress, TitleLeft, TitleRight);
	OpenForm("CommonForm.CompareSpreadsheetDocuments",
		FormOpenParameters, ThisObject);
	
EndProcedure

&AtServer
Function GetSpreadsheetDocumentsAddress(SpreadsheetDocumentName, Left, Right) 
	
	SpreadsheetDocumentLeft = SpreadsheetDocuments[Left].Value[SpreadsheetDocumentName].Data;
	SpreadsheetDocumentRight = SpreadsheetDocuments[Right].Value[SpreadsheetDocumentName].Data;
	
	SpreadsheetDocumentsStructure = New Structure("Left, Right", SpreadsheetDocumentLeft, SpreadsheetDocumentRight);
	
	Return PutToTempStorage(SpreadsheetDocumentsStructure, UUID);
	
EndFunction

#EndRegion


