///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var StorageAddress;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StorageAddressAtServer = Parameters.StorageAddress;
	RequestsProcessingResult = GetFromTempStorage(StorageAddressAtServer);
	
	If GetFunctionalOption("UseSecurityProfiles") AND Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get() Then
		If Parameters.CheckMode Then
			Items.PagesHeader.CurrentPage = Items.ObsoletePermissionsCancellationRequiredInClusterHeaderPage;
		ElsIf Parameters.RecoveryMode Then
			Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnRecoveryHeaderPage;
		Else
			Items.PagesHeader.CurrentPage = Items.ChangesInClusterRequiredHeaderPage;
		EndIf;
	Else
		Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnEnableHeaderPage;
	EndIf;
	
	RequestsApplyingScenario = RequestsProcessingResult.Scenario;
	
	If RequestsApplyingScenario.Count() = 0 Then
		ChangesInSecurityProfilesRequired = False;
		Return;
	EndIf;
	
	PermissionsPresentation = RequestsProcessingResult.Presentation;
	
	ChangesInSecurityProfilesRequired = True;
	InfobaseAdministrationParametersRequired = False;
	For Each ScenarioStep In RequestsApplyingScenario Do
		If ScenarioStep.Operation = Enums.SecurityProfileAdministrativeOperations.Purpose
				Or ScenarioStep.Operation = Enums.SecurityProfileAdministrativeOperations.AssignmentDeletion Then
			InfobaseAdministrationParametersRequired = True;
			Break;
		EndIf;
	EndDo;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	
	If Common.SeparatedDataUsageAvailable() Then
		
		InfobaseUser = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
		If InfobaseUser <> Undefined Then
			IBAdministratorID = InfobaseUser.UUID;
		EndIf;
		
	EndIf;
	
	ConnectionType = AdministrationParameters.ConnectionType;
	ServerClusterPort = AdministrationParameters.ClusterPort;
	
	ServerAgentAddress = AdministrationParameters.ServerAgentAddress;
	ServerAgentPort = AdministrationParameters.ServerAgentPort;
	
	AdministrationServerAddress = AdministrationParameters.AdministrationServerAddress;
	AdministrationServerPort = AdministrationParameters.AdministrationServerPort;
	
	NameInCluster = AdministrationParameters.NameInCluster;
	ClusterAdministratorName = AdministrationParameters.ClusterAdministratorName;
	
	InfobaseUser = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
	If InfobaseUser <> Undefined Then
		IBAdministratorID = InfobaseUser.UUID;
	EndIf;
	
	Users.FindAmbiguousIBUsers(Undefined, IBAdministratorID);
	IBAdministrator = Catalogs.Users.FindByAttribute("IBUserID", IBAdministratorID);
	
	Items.AdministrationGroup.Visible = InfobaseAdministrationParametersRequired;
	Items.RestartRequiredWarningGroup.Visible = InfobaseAdministrationParametersRequired;
	
	Items.FormAllow.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Next >';de = 'Next >';ro = 'Next >';tr = 'Next >'; es_ES = 'Next >'");
	Items.FormBack.Visible = False;
	
	VisibilityManagement();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If MobileClient Then
		ShowMessageBox(, NStr("ru = 'Для корректной работы необходим режим тонкого или толстого клиента.'; en = 'Thin or thick client mode is required.'; pl = 'Thin or thick client mode is required.';de = 'Thin or thick client mode is required.';ro = 'Thin or thick client mode is required.';tr = 'Thin or thick client mode is required.'; es_ES = 'Thin or thick client mode is required.'"));
		Cancel = True;
		Return;
	#EndIf
	
	#If WebClient Then
		ShowErrorOperationNotSupportedInWebClient();
		Return;
	#EndIf
	
	If ChangesInSecurityProfilesRequired Then
		
		StorageAddress = StorageAddressAtServer;
		
	Else
		
		Close(DialogReturnCode.Ignore);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If InfobaseAdministrationParametersRequired Then
		
		If Not ValueIsFilled(IBAdministrator) Then
			Return;
		EndIf;
		
		FieldName = "IBAdministrator";
		InfobaseUser = GetIBAdministrator();
		If InfobaseUser = Undefined Then
			Common.MessageToUser(NStr("ru = 'Указанный пользователь не имеет доступа к информационной базе.'; en = 'This user is not allowed to access the infobase.'; pl = 'This user is not allowed to access the infobase.';de = 'This user is not allowed to access the infobase.';ro = 'This user is not allowed to access the infobase.';tr = 'This user is not allowed to access the infobase.'; es_ES = 'This user is not allowed to access the infobase.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
		If Not Users.IsFullUser(InfobaseUser, True) Then
			Common.MessageToUser(NStr("ru = 'У пользователя нет административных прав.'; en = 'This user has no administrative rights.'; pl = 'This user has no administrative rights.';de = 'This user has no administrative rights.';ro = 'This user has no administrative rights.';tr = 'This user has no administrative rights.'; es_ES = 'This user has no administrative rights.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConnectionTypeOnChange(Item)
	
	VisibilityManagement();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Next(Command)
	
	If Items.PagesGroup.CurrentPage = Items.PermissionsPage Then
		
		ErrorText = "";
		Items.ErrorGroup.Visible = False;
		Items.FormAllow.Title = NStr("ru = 'Настроить разрешения в кластере серверов'; en = 'Set up permissions in server cluster'; pl = 'Set up permissions in server cluster';de = 'Set up permissions in server cluster';ro = 'Set up permissions in server cluster';tr = 'Set up permissions in server cluster'; es_ES = 'Set up permissions in server cluster'");
		Items.PagesGroup.CurrentPage = Items.ConnectionPage;
		Items.FormBack.Visible = True;
		
	ElsIf Items.PagesGroup.CurrentPage = Items.ConnectionPage Then
		
		ErrorText = "";
		Try
			
			ApplyPermissions();
			FinishApplyingRequests(StorageAddress);
			WaitForSettingsApplyingInCluster();
			
		Except
			ErrorText = BriefErrorDescription(ErrorInfo()); 
			Items.ErrorGroup.Visible = True;
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.PagesGroup.CurrentPage = Items.ConnectionPage Then
		Items.PagesGroup.CurrentPage = Items.PermissionsPage;
		Items.FormBack.Visible = False;
		Items.FormAllow.Title = NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Next >';de = 'Next >';ro = 'Next >';tr = 'Next >'; es_ES = 'Next >'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ReregisterCOMConnector(Command)
	
	CommonClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VisibilityManagement()
	
	If ConnectionType = "COM" Then
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.COMClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisibility = True;
	Else
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.RASClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisibility = False;
	EndIf;
	
	Items.COMConnectorVersionErrorGroup.Visible = COMConnectorVersionErrorGroupVisibility;
	
EndProcedure

&AtServer
Procedure ShowErrorOperationNotSupportedInWebClient()
	
	Items.PagesGlobal.CurrentPage = Items.OperationNotSupportedInWebClientPage;
	
EndProcedure

&AtServer
Function GetIBAdministrator()
	
	If Not ValueIsFilled(IBAdministrator) Then
		Return Undefined;
	EndIf;
	
	Return InfoBaseUsers.FindByUUID(
		IBAdministrator.IBUserID);
	
EndFunction

&AtServerNoContext
Function InfobaseUserName(Val User)
	
	If ValueIsFilled(User) Then
		
		IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
		InfobaseUser = InfoBaseUsers.FindByUUID(IBUserID);
		Return InfobaseUser.Name;
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

&AtClient
Procedure ApplyPermissions()
	
	ApplyPermissionsAtServer(StorageAddress);
	
EndProcedure

&AtServer
Function StartApplyingRequests(Val StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	RequestsApplyingScenario = Result.Scenario;
	
	OperationKinds = New Structure();
	For Each EnumValue In Metadata.Enums.SecurityProfileAdministrativeOperations.EnumValues Do
		OperationKinds.Insert(EnumValue.Name, Enums.SecurityProfileAdministrativeOperations[EnumValue.Name]);
	EndDo;
	
	Return New Structure("OperationKinds, RequestApplyingScenario, InfobaseAdministrationParametersRequired",
		OperationKinds, RequestsApplyingScenario, InfobaseAdministrationParametersRequired);
	
EndFunction

&AtServer
Procedure FinishApplyingRequests(Val StorageAddress)
	
	DataProcessors.ExternalResourcePermissionSetup.CommitRequests(GetFromTempStorage(StorageAddress).State);
	SaveAdministrationParameters();
	
EndProcedure

&AtServer
Procedure SaveAdministrationParameters()
	
	AdministrationParametersToSave = New Structure();
	
	// Cluster administration parameters.
	AdministrationParametersToSave.Insert("ConnectionType", ConnectionType);
	AdministrationParametersToSave.Insert("ServerAgentAddress", ServerAgentAddress);
	AdministrationParametersToSave.Insert("ServerAgentPort", ServerAgentPort);
	AdministrationParametersToSave.Insert("AdministrationServerAddress", AdministrationServerAddress);
	AdministrationParametersToSave.Insert("AdministrationServerPort", AdministrationServerPort);
	AdministrationParametersToSave.Insert("ClusterPort", ServerClusterPort);
	AdministrationParametersToSave.Insert("ClusterAdministratorName", ClusterAdministratorName);
	AdministrationParametersToSave.Insert("ClusterAdministratorPassword", "");
	
	// Infobase administration parameters.
	AdministrationParametersToSave.Insert("NameInCluster", NameInCluster);
	AdministrationParametersToSave.Insert("InfobaseAdministratorName", InfobaseUserName(IBAdministrator));
	AdministrationParametersToSave.Insert("InfobaseAdministratorPassword", "");
	
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParametersToSave);
	
EndProcedure

&AtClient
Procedure WaitForSettingsApplyingInCluster()
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtServer
Procedure ApplyPermissionsAtServer(StorageAddress)
	
	ApplyingParameters = StartApplyingRequests(StorageAddress);
	
	OperationKinds = ApplyingParameters.OperationKinds;
	Scenario = ApplyingParameters.RequestApplyingScenario;
	IBAdministrationParametersRequired = ApplyingParameters.InfobaseAdministrationParametersRequired;
	
	ClusterAdministrationParameters = ClusterAdministration.ClusterAdministrationParameters();
	ClusterAdministrationParameters.ConnectionType = ConnectionType;
	ClusterAdministrationParameters.ServerAgentAddress = ServerAgentAddress;
	ClusterAdministrationParameters.ServerAgentPort = ServerAgentPort;
	ClusterAdministrationParameters.AdministrationServerAddress = AdministrationServerAddress;
	ClusterAdministrationParameters.AdministrationServerPort = AdministrationServerPort;
	ClusterAdministrationParameters.ClusterPort = ServerClusterPort;
	ClusterAdministrationParameters.ClusterAdministratorName = ClusterAdministratorName;
	ClusterAdministrationParameters.ClusterAdministratorPassword = ClusterAdministratorPassword;
	
	If IBAdministrationParametersRequired Then
		IBAdministrationParameters = ClusterAdministration.ClusterInfobaseAdministrationParameters();
		IBAdministrationParameters.NameInCluster = NameInCluster;
		IBAdministrationParameters.InfobaseAdministratorName = InfobaseUserName(IBAdministrator);
		IBAdministrationParameters.InfobaseAdministratorPassword = IBAdministratorPassword;
	Else
		IBAdministrationParameters = Undefined;
	EndIf;
	
	ApplyPermissionsChangesInSecurityProfilesInServerCluster(
		OperationKinds, Scenario, ClusterAdministrationParameters, IBAdministrationParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Applying the requests for permissions to use external resources.
//

// Applies the security profile permission changes in server cluster by the scenario.
//
// Parameters:
//  OperationKinds - a structure that describes values of the SecurityProfileAdministrativeOperations enumeration:
//                   * Key - String - an enumeration value name,
//                   * Value - EnumRef.SecurityProfileAdministrativeOperations,
//  PermissionsApplyingScenario - Array(Structure) - a scenario of applying changes in permissions 
//    to use security profiles in the server cluster. Array values are structures with the following 
//    fields:
//                   * Operation - EnumRef.SecurityProfileAdministrativeOperations - an operation to 
//                      be executed,
//                   * Profile - String - a security profile name,
//                   * Permissions - Structure - security profile property details, see
//                      ClusterAdministration.SecurityProfileProperties().
//  ClusterAdministrationParameters - Structure - server cluster administration parameters, see
//    ClusterAdministration.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - administration parameters of the infobase, see 
//    ClusterAdministration.ClusterInfobaseAdministrationParameters(). 
//
&AtServerNoContext
Procedure ApplyPermissionsChangesInSecurityProfilesInServerCluster(Val OperationKinds, Val PermissionsApplyingScenario, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined)
	
	IBAdministrationParametersRequired = (InfobaseAdministrationParameters <> Undefined);
	
	ClusterAdministration.CheckAdministrationParameters(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		True,
		IBAdministrationParametersRequired);
	
	For Each ScenarioItem In PermissionsApplyingScenario Do
		
		If ScenarioItem.Operation = OperationKinds.Creating Then
			
			If ClusterAdministration.SecurityProfileExists(ClusterAdministrationParameters, ScenarioItem.Profile) Then
				
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Профиль безопасности %1 уже присутствует в кластере серверов. Настройки в профиле безопасности будут замещены...'; en = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...'; pl = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...';de = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...';ro = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...';tr = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...'; es_ES = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced...'"), ScenarioItem.Profile));
				
				ClusterAdministration.SetSecurityProfileProperties(ClusterAdministrationParameters, ScenarioItem.Permissions);
				
			Else
				
				ClusterAdministration.CreateSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Permissions);
				
			EndIf;
			
		ElsIf ScenarioItem.Operation = OperationKinds.Purpose Then
			
			ClusterAdministration.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, ScenarioItem.Profile);
			
		ElsIf ScenarioItem.Operation = OperationKinds.Update Then
			
			ClusterAdministration.SetSecurityProfileProperties(ClusterAdministrationParameters, ScenarioItem.Permissions);
			
		ElsIf ScenarioItem.Operation = OperationKinds.Delete Then
			
			If ClusterAdministration.SecurityProfileExists(ClusterAdministrationParameters, ScenarioItem.Profile) Then
				
				ClusterAdministration.DeleteSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Profile);
				
			Else
				
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Профиль безопасности %1 отсутствует в кластере серверов. Возможно, профиль безопасности был удален ранее...'; en = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...'; pl = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...';de = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...';ro = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...';tr = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...'; es_ES = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier...'"), ScenarioItem.Profile));
				
			EndIf;
			
		ElsIf ScenarioItem.Operation = OperationKinds.AssignmentDeletion Then
			
			ClusterAdministration.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, "");
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion