///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetLastPackage()
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ISNULL(MAX(PackagesToSend.PackageNumber), 0) AS LastPackage
	|FROM
	|	InformationRegister.PackagesToSend AS PackagesToSend
	|";
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.LastPackage;	
EndFunction

Procedure WriteNewPackage(RecordDate, JSONStructure, NextPackageNumber) Export
	JSONStructure.Insert("pn", Format(NextPackageNumber, "NZ=0; NG=0"));
	JSONStructure.Insert("Configuration", String(Metadata.Name));
	JSONStructure.Insert("ConfigurationVersion", String(Metadata.Version));
	
	PackageBody = MonitoringCenterInternal.JSONStructureToString(JSONStructure);
	MD5Hash = New DataHashing(HashFunction.MD5);
	MD5Hash.Append(PackageBody + "hashSalt");
	HASH = MD5Hash.HashSum;
	HASH = StrReplace(String(HASH), " ", "");
	
	RecordSet = CreateRecordSet();
	NewRecord = RecordSet.Add();
	NewRecord.Period = RecordDate;
	NewRecord.PackageNumber = NextPackageNumber;
	NewRecord.PackageBody = PackageBody;
	NewRecord.PackageHash = HASH;
	
	RecordSet.DataExchange.Load = True;
	RecordSet.Write(False);
EndProcedure

Procedure DeleteOldPackages() Export
	Query = New Query;
	Query.Text = "
	|SELECT
	|	COUNT(*) AS TotalPackageCount
	|FROM
	|	InformationRegister.PackagesToSend AS PackagesToSend
	|";
	PackagesToSend = MonitoringCenterInternal.GetMonitoringCenterParameters("PackagesToSend");
		
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	TotalPackageCount = Selection.TotalPackageCount;
	
	If TotalPackageCount > PackagesToSend Then
		LastPackage = GetLastPackage();
		
		Query.Text = "
		|SELECT TOP %PackagesToDelete
		|	PackagesToSend.PackageNumber AS PackageNumber
		|FROM
		|	InformationRegister.PackagesToSend AS PackagesToSend
		|WHERE
		|	PackagesToSend.PackageNumber < &LastPackage
		|ORDER BY
		|	PackagesToSend.PackageNumber DESC
		|";
		
		Query.Text = StrReplace(Query.Text, "%PackagesToDelete", Format(TotalPackageCount - PackagesToSend, "NG=")); 
		
		Query.SetParameter("LastPackage", LastPackage);
		Result = Query.Execute();
		Selection = Result.Select();
		
		BeginTransaction();
		Try
			RecordSet = CreateRecordSet();
			While Selection.Next() Do
				RecordSet.Filter.PackageNumber.Set(Selection.PackageNumber);
				RecordSet.Write(True);
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Error = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("ru='УдалитьСтарыеПакеты'; en = 'DeleteOldPackages'; pl = 'DeleteOldPackages';de = 'DeleteOldPackages';ro = 'DeleteOldPackages';tr = 'DeleteOldPackages'; es_ES = 'DeleteOldPackages'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
			Raise Error;
		EndTry;
		
	EndIf;
EndProcedure

Procedure DeletePackage(PackageNumber) Export
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	PackagesToSend.PackageNumber AS PackageNumber
	|FROM
	|	InformationRegister.PackagesToSend AS PackagesToSend
	|WHERE
	|	PackagesToSend.PackageNumber = &PackageNumber
	|";
	
	Query.SetParameter("PackageNumber", PackageNumber);
	Result = Query.Execute();
	Selection = Result.Select();
	
	BeginTransaction();
	Try
		RecordSet = CreateRecordSet();
		While Selection.Next() Do
			RecordSet.Filter.PackageNumber.Set(Selection.PackageNumber);
			RecordSet.Write(True);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("ru='УдалитьПакеты'; en = 'DeletePackages'; pl = 'DeletePackages';de = 'DeletePackages';ro = 'DeletePackages';tr = 'DeletePackages'; es_ES = 'DeletePackages'", Common.DefaultLanguageCode()), EventLogLevel.Error, Metadata.CommonModules.MonitoringCenterInternal,,Error);
		Raise Error;
	EndTry;
EndProcedure

Function GetPackage(PackageNumber) Export
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	PackagesToSend.PackageNumber,
	|	PackagesToSend.PackageBody,
	|	PackagesToSend.PackageHash
	|FROM
	|	InformationRegister.PackagesToSend AS PackagesToSend
	|WHERE
	|	PackagesToSend.PackageNumber = &PackageNumber
	|";
		
	Query.SetParameter("PackageNumber", PackageNumber);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Package = Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Package = New Structure;
		Package.Insert("PackageNumber", Selection.PackageNumber);
		Package.Insert("PackageBody", Selection.PackageBody);
		Package.Insert("PackageHash", Selection.PackageHash);	
	EndIf;
	
	Return Package;
EndFunction

Function GetPackagesNumbers() Export
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	PackagesToSend.PackageNumber
    |FROM
    |	InformationRegister.PackagesToSend AS PackagesToSend
    |ORDER BY
    |	PackagesToSend.PackageNumber
	|";
	
	Result = Query.Execute();
	PackagesNumbers = New Array;
	If NOT Result.IsEmpty() Then
		Selection = Result.Select();
		While Selection.Next() Do
			PackagesNumbers.Add(Selection.PackageNumber);
		EndDo;
	EndIf;
	
	Return PackagesNumbers;
EndFunction

Procedure Clear() Export
    
    RecordSet = CreateRecordSet();
    RecordSet.Write(True);
    
EndProcedure

#EndRegion

#EndIf
