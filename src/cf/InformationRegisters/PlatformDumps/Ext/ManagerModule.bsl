///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetDumpsToDelete() Export
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PlatformDumps.RegistrationDate,
		|	PlatformDumps.DumpOption,
		|	PlatformDumps.PlatformVersion,
		|	PlatformDumps.FileName
		|FROM
		|	InformationRegister.PlatformDumps AS PlatformDumps
		|WHERE
		|	PlatformDumps.FileName <> &FileName";
	
	Query.SetParameter("FileName", "");
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	DumpsToDelete = New Array;
	While DetailedRecordsSelection.Next() Do
		DumpToDelete = New Structure;
		DumpToDelete.Insert("RegistrationDate", DetailedRecordsSelection.RegistrationDate);
		DumpToDelete.Insert("DumpOption", DetailedRecordsSelection.DumpOption);
		DumpToDelete.Insert("PlatformVersion", DetailedRecordsSelection.PlatformVersion);
		DumpToDelete.Insert("FileName", DetailedRecordsSelection.FileName);
		
		DumpsToDelete.Add(DumpToDelete);
	EndDo;

	Return DumpsToDelete;
EndFunction

Procedure ChangeRecord(Record) Export
	RecordManager = CreateRecordManager();
	RecordManager.RegistrationDate = Record.RegistrationDate;
	RecordManager.DumpOption = Record.DumpOption;
	RecordManager.PlatformVersion = Record.PlatformVersion;
	RecordManager.FileName = Record.FileName;
	RecordManager.Write();
EndProcedure

Function GetRegisteredDumps(Dumps) Export
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PlatformDumps.FileName
		|FROM
		|	InformationRegister.PlatformDumps AS PlatformDumps
		|WHERE
		|	PlatformDumps.FileName IN(&Dumps)";
	
	Query.SetParameter("Dumps", Dumps);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	HasDumps = New Map;
	While DetailedRecordsSelection.Next() Do
		HasDumps.Insert(DetailedRecordsSelection.FileName, True);
	EndDo;
	
	Return HasDumps;
EndFunction

Function GetTopOptions(StartDate, EndDate, Count, Val PlatformVersion = Undefined) Export
	StartDateSM = (StartDate - Date(1,1,1)) * 1000;
	EndDateSM = (EndDate - Date(1,1,1)) * 1000;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP %TOP
		|	DumpOption,
		|	OptionsCount
		|FROM
		|	(SELECT
		|		PlatformDumps.DumpOption AS DumpOption,
		|		COUNT(1) AS OptionsCount
		|	FROM
		|		InformationRegister.PlatformDumps AS PlatformDumps
		|	WHERE
		|		PlatformDumps.RegistrationDate BETWEEN &StartDateSM AND &EndDateSM
		|		%CondPlatformVersion
		|	GROUP BY
		|		PlatformDumps.DumpOption
		|	) AS Selection
		|ORDER BY
		|	OptionsCount DESC
		|";
		
	Query.Text = StrReplace(Query.Text, "%TOP", Format(Count, "NG=0"));
	Query.SetParameter("StartDateSM", StartDateSM);
	Query.SetParameter("EndDateSM", EndDateSM);
	If PlatformVersion <> Undefined Then
		PlatformVersionNumber = MonitoringCenterInternal.PlatformVersionToNumber(PlatformVersion);
		Query.Text = StrReplace(Query.Text, "%CondPlatformVersion", "AND PlatformDumps.PlatformVersion = &PlatformVersion");
		Query.SetParameter("PlatformVersion", PlatformVersionNumber);
	Else
		Query.Text = StrReplace(Query.Text, "%CondPlatformVersion", "");
	EndIf;
		
	QueryResult = Query.Execute();
	
	Return QueryResult;
EndFunction

#EndRegion

#EndIf