///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetRef(Description, CollectConfigurationStatistics = False) Export
	DescriptionHash = DescriptionHash(Description);
	
	Ref = FindByHash(DescriptionHash);
	If Ref = Undefined Then
		Ref = CreateNew(Description, DescriptionHash, CollectConfigurationStatistics);
	EndIf;
		
	Return Ref;
EndFunction

Function CollectConfigurationStatistics(Description) Export
	DescriptionHash = DescriptionHash(Description);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	StatisticsAreas.CollectConfigurationStatistics
	|FROM
	|	InformationRegister.StatisticsAreas AS StatisticsAreas
	|WHERE
	|	StatisticsAreas.DescriptionHash = &DescriptionHash
	|";
	Query.SetParameter("DescriptionHash", DescriptionHash);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		CollectConfigurationStatistics = False;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		CollectConfigurationStatistics = Selection.CollectConfigurationStatistics;
	EndIf;
	
	Return CollectConfigurationStatistics
EndFunction

Function DescriptionHash(Description)
	DataHashing = New DataHashing(HashFunction.SHA1);
	DataHashing.Append(Description);
	DescriptionHash = StrReplace(String(DataHashing.HashSum), " ", "");
	
	Return DescriptionHash;
EndFunction

Function FindByHash(Hash)
	Query = New Query;
	Query.Text = "
	|SELECT
	|	StatisticsAreas.AreaID
	|FROM
	|	InformationRegister.StatisticsAreas AS StatisticsAreas
	|WHERE
	|	StatisticsAreas.DescriptionHash = &DescriptionHash
	|";
	Query.SetParameter("DescriptionHash", Hash);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Ref = Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Ref = Selection.AreaID;
	EndIf;
	
	Return Ref;
EndFunction

Function CreateNew(Description, DescriptionHash, CollectConfigurationStatistics)
	BeginTransaction();
	
	Try
		Lock = New DataLock;
		
		LockItem = Lock.Add("InformationRegister.StatisticsAreas");
		LockItem.SetValue("DescriptionHash", DescriptionHash);
				
		Lock.Lock();
		
		Ref = FindByHash(DescriptionHash);
		
		If Ref = Undefined Then
			Ref = New UUID();
			
			RecordSet = CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			NewRecord = RecordSet.Add();
			NewRecord.DescriptionHash = DescriptionHash;
			NewRecord.AreaID = Ref;
			NewRecord.Description = Description;
			NewRecord.CollectConfigurationStatistics = CollectConfigurationStatistics;
			RecordSet.Write(False);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Ref;
EndFunction

#EndRegion

#EndIf
