///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

// OnlineUserSupport.AddInsReceipt

// Returns the table of add-ins details to be updated from the 1C:ITS Portal automatically.
//
// Returns:
//  ValueTable - see AddInsReceipt.AddInsDetails of the AddInsReceipt subsystem of the online user  
//          support library (OUSL).
//
Function AutomaticallyUpdatedAddIns() Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	AddIns.ID AS ID,
			|	AddIns.Version AS Version
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.UpdateFrom1CITSPortal";
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		AddInsDetails = ModuleGetAddIns.AddInsDetails();
		
		While Selection.Next() Do
			ComponentDetails = AddInsDetails.Add();
			ComponentDetails.ID = Selection.ID;
			ComponentDetails.Version = Selection.Version;
		EndDo;
		
		Return AddInsDetails;
		
	Else
		Raise 
			NStr("ru = 'Ожидается существование подсистемы ""ИнтернетПоддержкаПользователей.ПолучениеВнешнихКомпонент""'; en = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; pl = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';de = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';ro = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';tr = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; es_ES = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'");
	EndIf;
	
EndFunction

// Updates add-ins.
//
// Parameters:
//  AddInsData - ValueTable - table of add-ins to update.
//    ** ID - String - ID.
//    ** Version - String - version.
//    ** VersionDate - String - version date.
//    ** Description - String - description.
//    ** FileName – String – a file name.
//    ** FileAddress - String - file address.
//    ** ErrorCode - String - error code.
//  ResultAddress - String - (optional) address of the temporary storage.
//      If it is specified, it contains operation result details.
//
Procedure UpdateAddIns(AddInsData, ResultAddress = Undefined) Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
	
		Result = "";
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	AddIns.Ref AS Ref,
			|	AddIns.ID AS ID
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.ID IN(&IDs)";
		
		Query.SetParameter("IDs", AddInsData.UnloadColumn("ID"));
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		// Query Result Iteration.
		For each ResultString In AddInsData Do
			
			AddInPresentation = AddInsInternal.AddInPresentation(
				ResultString.ID, 
				ResultString.Version);
			
			ErrorCode = ResultString.ErrorCode;
			
			If ValueIsFilled(ErrorCode) Then
				
				If ErrorCode = "LatestVersion" Then
					Result = Result + AddInPresentation + " - " + NStr("ru = 'Актуальная версия.'; en = 'Latest version.'; pl = 'Latest version.';de = 'Latest version.';ro = 'Latest version.';tr = 'Latest version.'; es_ES = 'Latest version.'") + Chars.LF;
					Continue;
				EndIf;
				
				ErrorInformation = "";
				If ErrorCode = "ComponentNotFound" Then 
					ErrorInformation = NStr("ru = 'В сервисе внешних компонент не обнаружена внешняя компонента'; en = 'Add-in is not found in the add-in service'; pl = 'Add-in is not found in the add-in service';de = 'Add-in is not found in the add-in service';ro = 'Add-in is not found in the add-in service';tr = 'Add-in is not found in the add-in service'; es_ES = 'Add-in is not found in the add-in service'");
				ElsIf ErrorCode = "FileNotImported" Then 
					ErrorInformation = NStr("ru = 'При попытке загрузить файл внешней компоненты из сервиса, возникла ошибка'; en = 'An error occurred while trying to import add-in file from service'; pl = 'An error occurred while trying to import add-in file from service';de = 'An error occurred while trying to import add-in file from service';ro = 'An error occurred while trying to import add-in file from service';tr = 'An error occurred while trying to import add-in file from service'; es_ES = 'An error occurred while trying to import add-in file from service'");
				EndIf;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'При загрузке внешней компоненты %1 возникала ошибка:
					           |%2'; 
					           |en = 'An error occurred while importing add-in %1:
					           |%2'; 
					           |pl = 'An error occurred while importing add-in %1:
					           |%2';
					           |de = 'An error occurred while importing add-in %1:
					           |%2';
					           |ro = 'An error occurred while importing add-in %1:
					           |%2';
					           |tr = 'An error occurred while importing add-in %1:
					           |%2'; 
					           |es_ES = 'An error occurred while importing add-in %1:
					           |%2'"),
					AddInPresentation,
					ErrorInformation);
				
				Result = Result + AddInPresentation + " - " + ErrorInformation + Chars.LF;
				
				WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					ErrorText);
				
				Continue;
			EndIf;
			
			Information = AddInsInternal.InformationOnAddInFromFile(ResultString.FileAddress, False);
			
			If Not Information.Disassembled Then 
				
				Result = Result + AddInPresentation + " - " + Information.ErrorDescription + Chars.LF;
				
				WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, Information.ErrorDescription);
					
				Continue;
			EndIf;
			
			// Link search 
			Filter = New Structure("ID", ResultString.ID);
			If Selection.FindNext(Filter) Then 
				
				Object = Selection.Ref.GetObject();
				
				// If the earlier add-in than on 1C:ITS Portal is imported, it should not be updated.
				If Object.VersionDate > ResultString.VersionDate Then 
					Continue;
				EndIf;
				
				FillPropertyValues(Object, Information.Attributes); // By manifest data.
				FillPropertyValues(Object, ResultString);     // By data from the website.
				
				Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
				
				Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Загружена с Портала 1С:ИТС. %1.'; en = 'Imported from 1C:ITS Portal. %1.'; pl = 'Imported from 1C:ITS Portal. %1.';de = 'Imported from 1C:ITS Portal. %1.';ro = 'Imported from 1C:ITS Portal. %1.';tr = 'Imported from 1C:ITS Portal. %1.'; es_ES = 'Imported from 1C:ITS Portal. %1.'"),
					CurrentSessionDate());
				
				Try
					Object.Write();
					Result = Result 
						+ AddInPresentation + " - " + NStr("ru = 'Успешно обновлена.'; en = 'Updated.'; pl = 'Updated.';de = 'Updated.';ro = 'Updated.';tr = 'Updated.'; es_ES = 'Updated.'") + Chars.LF;
				Except
					Result = Result 
						+ AddInPresentation + " - " + BriefErrorDescription(ErrorInfo()) + Chars.LF;
					WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
							Common.DefaultLanguageCode()),
						EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
				EndTry;
				
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(ResultAddress) Then 
			PutToTempStorage(Result, ResultAddress);
		EndIf;
		
	Else
		Raise 
			NStr("ru = 'Ожидается существование подсистемы ""ИнтернетПоддержкаПользователей.ПолучениеВнешнихКомпонент""'; en = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; pl = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';de = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';ro = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';tr = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; es_ES = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'");
	EndIf;
	
EndProcedure

// Parameter structure for the UpdateSharedAddIn procedure.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * ID - String - ID.
//      * Version - String - version.
//      * VersionDate - Date - version date.
//      * Description - String - description.
//      * FileName – String – a file name.
//      * PathToFile - String - path to file.
//
Function SuppliedSharedAddInDetails() Export
	
	Details = New Structure;
	Details.Insert("ID");
	Details.Insert("Version");
	Details.Insert("VersionDate");
	Details.Insert("Description");
	Details.Insert("FileName");
	Details.Insert("PathToFile");
	Return Details;
	
EndFunction

// Updates add-ins shares.
//
// Parameters:
//  AddInDetails - Structure - see the SuppliedSharedAddInDetails function.
//
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.UpdateSharedAddIn(ComponentDetails);
	EndIf;
	
EndProcedure

// End OnlineUserSupport.AddInsReceipt

#EndRegion

#EndRegion