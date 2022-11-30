///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Core subsystem.
// Common server procedures and functions to manage:
// - Managing permissions in the security profiles from the current infobase.
//
////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Logic of external resource permissions setup wizard.
//

// For internal use.
//
Procedure ExecuteRequestProcessing(Val RequestsIDs, Val TempStorageAddress, Val StateTemporaryStorageAddress, Val AddClearingRequestsBeforeApplying = False) Export
	
	Manager = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionsApplicationManager(RequestsIDs);
	
	If AddClearingRequestsBeforeApplying Then
		Manager.AddClearingPermissionsBeforeApplying();
	EndIf;
	
	State = New Structure();
	
	If Manager.MustApplyPermissionsInServersCluster() Then
		
		State.Insert("PermissionApplicationRequired", True);
		
		Result = New Structure();
		Result.Insert("Presentation", Manager.Presentation());
		Result.Insert("Scenario", Manager.ApplyingScenario());
		Result.Insert("State", Manager.WriteStateToXMLString());
		PutToTempStorage(Result, TempStorageAddress);
		
		State.Insert("StorageAddress", TempStorageAddress);
		
	Else
		
		State.Insert("PermissionApplicationRequired", False);
		Manager.CompleteApplyRequestsToUseExternalResources();
		
	EndIf;
	
	PutToTempStorage(State, StateTemporaryStorageAddress);
	
EndProcedure

// For internal use.
//
Procedure ExecuteUpdateRequestProcessing(Val TempStorageAddress, Val StateTemporaryStorageAddress) Export
	
	CallWithDisabledProfiles = Not Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
	
	If CallWithDisabledProfiles Then
		
		BeginTransaction();
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
		RequestsIDs = SafeModeManagerInternal.RequestsToUpdateApplicationPermissions();
		RequestsSerialization = InformationRegisters.RequestsForPermissionsToUseExternalResources.WriteRequestsToXMLString(RequestsIDs);
		
	EndIf;
	
	ExecuteRequestProcessing(RequestsIDs, TempStorageAddress, StateTemporaryStorageAddress);
	
	If CallWithDisabledProfiles Then
		
		RollbackTransaction();
		InformationRegisters.RequestsForPermissionsToUseExternalResources.ReadRequestsFromXMLString(RequestsSerialization);
		
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure ExecuteDisableRequestProcessing(Val TempStorageAddress, Val StateTemporaryStorageAddress) Export
	
	Queries = New Array();
	
	BeginTransaction();
	
	Try
		
		IBProfileDeletionRequestID = SafeModeManagerInternal.RequestToDeleteSecurityProfile(
			Catalogs.MetadataObjectIDs.EmptyRef());
		
		Queries.Add(IBProfileDeletionRequestID);
		
		QueryText =
			"SELECT DISTINCT
			|	ExternalModulesAttachmentModes.ModuleType AS ModuleType,
			|	ExternalModulesAttachmentModes.ModuleID AS ModuleID
			|FROM
			|	InformationRegister.ExternalModulesAttachmentModes AS ExternalModulesAttachmentModes";
		Query = New Query(QueryText);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Queries.Add(SafeModeManagerInternal.RequestToDeleteSecurityProfile(
				SafeModeManagerInternal.ReferenceFormPermissionRegister(Selection.ModuleType, Selection.ModuleID)));
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	ExecuteRequestProcessing(Queries, TempStorageAddress, StateTemporaryStorageAddress);
	
EndProcedure

// For internal use.
//
Procedure ExecuteRecoveryRequestProcessing(Val TempStorageAddress, Val StateTemporaryStorageAddress) Export
	
	BeginTransaction();
	
	ClearPermissions(, False);
	
	RequestsIDs = New Array();
	CommonClientServer.SupplementArray(RequestsIDs, InformationRegisters.RequestsForPermissionsToUseExternalResources.ReplacementRequestsForAllGrantedPermissions());
	CommonClientServer.SupplementArray(RequestsIDs, SafeModeManagerInternal.RequestsToUpdateApplicationPermissions(False));
	
	Serialization = InformationRegisters.RequestsForPermissionsToUseExternalResources.WriteRequestsToXMLString(RequestsIDs);
	
	ExecuteRequestProcessing(RequestsIDs, TempStorageAddress, StateTemporaryStorageAddress, True);
	
	RollbackTransaction();
	
	InformationRegisters.RequestsForPermissionsToUseExternalResources.ReadRequestsFromXMLString(Serialization);
	
EndProcedure

// For internal use.
//
Function ExecuteApplicabilityCheckRequestsProcessing() Export
	
	If TransactionActive() Then
		Raise NStr("ru = 'Транзакция активна'; en = 'Transaction is active'; pl = 'Transaction is active';de = 'Transaction is active';ro = 'Transaction is active';tr = 'Transaction is active'; es_ES = 'Transaction is active'");
	EndIf;
	
	Result = New Structure();
	
	BeginTransaction();
	
	RequestsIDs = New Array();
	CommonClientServer.SupplementArray(RequestsIDs, InformationRegisters.RequestsForPermissionsToUseExternalResources.ReplacementRequestsForAllGrantedPermissions());
	CommonClientServer.SupplementArray(RequestsIDs, SafeModeManagerInternal.RequestsToUpdateApplicationPermissions(False));
	
	Manager = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionsApplicationManager(RequestsIDs);
	
	Serialization = InformationRegisters.RequestsForPermissionsToUseExternalResources.WriteRequestsToXMLString(RequestsIDs);
	
	RollbackTransaction();
	
	If Manager.MustApplyPermissionsInServersCluster() Then
		
		TempStorageAddress = PutToTempStorage(Undefined, New UUID());
		
		InformationRegisters.RequestsForPermissionsToUseExternalResources.ReadRequestsFromXMLString(Serialization);
		
		Result.Insert("CheckResult", False);
		Result.Insert("RequestIDs", RequestsIDs);
		
		PermissionRequestState = New Structure();
		PermissionRequestState.Insert("Presentation", Manager.Presentation());
		PermissionRequestState.Insert("Scenario", Manager.ApplyingScenario());
		PermissionRequestState.Insert("State", Manager.WriteStateToXMLString());
		
		PutToTempStorage(PermissionRequestState, TempStorageAddress);
		Result.Insert("TempStorageAddress", TempStorageAddress);
		
		StateTemporaryStorageAddress = PutToTempStorage(Undefined, New UUID());
		
		State = New Structure();
		State.Insert("PermissionApplicationRequired", True);
		State.Insert("StorageAddress", TempStorageAddress);
		
		PutToTempStorage(State, StateTemporaryStorageAddress);
		Result.Insert("StateTemporaryStorageAddress", StateTemporaryStorageAddress);
		
	Else
		
		If Manager.RecordPermissionsToRegisterRequired() Then
			Manager.CompleteApplyRequestsToUseExternalResources();
		EndIf;
		
		Result.Insert("CheckResult", True);
		
	EndIf;
	
	Return Result;
	
EndFunction

// For internal use.
//
Procedure CommitRequests(Val State) Export
	
	Manager = Create();
	Manager.ReadStateFromXMLString(State);
	
	Manager.CompleteApplyRequestsToUseExternalResources();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Processing registers used for storing granted permissions to use external resources.
// 
//

// Sets an exclusive managed lock for tables of all registers used for storing a list of granted 
// permissions.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the catalog item that corresponds to the external module 
//    whose information on previously granted permissions must be cleared. If the parameter value is 
//    not specified, information on granted permissions in all external modules will be blocked.
//   LockAttachmentModes - Boolean - indicates that additional lock of external module attachment 
//    modes is required.
//
Procedure LockRegistersOfGrantedPermissions(Val ProgramModule = Undefined, Val LockAttachmentModes = True) Export
	
	If Not TransactionActive() Then
		Raise NStr("ru = 'Должна быть активная транзакция'; en = 'There must be an active transaction'; pl = 'There must be an active transaction';de = 'There must be an active transaction';ro = 'There must be an active transaction';tr = 'There must be an active transaction'; es_ES = 'There must be an active transaction'");
	EndIf;
	
	Lock = New DataLock();
	
	Registers = New Array();
	Registers.Add(InformationRegisters.PermissionsToUseExternalResources);
	
	If LockAttachmentModes Then
		Registers.Add(InformationRegisters.ExternalModulesAttachmentModes);
	EndIf;
	
	For Each Register In Registers Do
		RegisterLock = Lock.Add(Register.CreateRecordSet().Metadata().FullName());
		If ProgramModule <> Undefined Then
			ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
			RegisterLock.SetValue("ModuleType", ModuleProperties.Type);
			RegisterLock.SetValue("ModuleID", ModuleProperties.ID);
		EndIf;
	EndDo;
	
	Lock.Lock();
	
EndProcedure

// Clears information registers used for storing the list of granted permissions in the infobase.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to the catalog item that corresponds to the external module 
//    whose information on previously granted permissions must be cleared. If the parameter value is 
//    not specified, information on granted permissions in all external modules will be cleared.
//   ClearAttachmentModes - Boolean - indicates whether additional clearing of external module 
//    attachment modes is required.
//
Procedure ClearPermissions(Val ProgramModule = Undefined, Val ClearAttachmentModes = True) Export
	
	BeginTransaction();
	
	Try
		
		LockRegistersOfGrantedPermissions(ProgramModule, ClearAttachmentModes);
		
		Managers = New Array();
		Managers.Add(InformationRegisters.PermissionsToUseExternalResources);
		
		If ClearAttachmentModes Then
			Managers.Add(InformationRegisters.ExternalModulesAttachmentModes);
		EndIf;
		
		For Each Manager In Managers Do
			Set = Manager.CreateRecordSet();
			If ProgramModule <> Undefined Then
				ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
				Set.Filter.ModuleType.Set(ModuleProperties.Type);
				Set.Filter.ModuleID.Set(ModuleProperties.ID);
			EndIf;
			Set.Write(True);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Processing permission tables.
//

// Returns a permission table row that meets the filter condition.
// If the table does not contain rows meeting the filter condition, a new one can be added.
// If the table contains more than one row meeting the filter condition, an exception is generated.
//
// Parameters:
//  PermissionsTable - ValueTable,
//  Filter - Structure,
//  AddIfAbsent - Boolean.
//
// Returns: ValueTableRow or Undefined.
//
Function PermissionsTableRow(Val PermissionsTable, Val Filter, Val AddIfAbsent = True) Export
	
	Rows = PermissionsTable.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		
		If AddIfAbsent Then
			
			Row = PermissionsTable.Add();
			FillPropertyValues(Row, Filter);
			Return Row;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	ElsIf Rows.Count() = 1 Then
		
		Return Rows.Get(0);
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Нарушение уникальности строк в таблице разрешений по отбору %1'; en = 'Rows uniqueness violation in permission table by the filter %1'; pl = 'Rows uniqueness violation in permission table by the filter %1';de = 'Rows uniqueness violation in permission table by the filter %1';ro = 'Rows uniqueness violation in permission table by the filter %1';tr = 'Rows uniqueness violation in permission table by the filter %1'; es_ES = 'Rows uniqueness violation in permission table by the filter %1'"),
			Common.ValueToXMLString(Filter));
		
	EndIf;
	
EndFunction

#EndRegion

#EndIf

