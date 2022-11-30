///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.AfterStart. 
Procedure AfterStart() Export
	
	ClientRunParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParametersOnStart.DisplayPermissionSetupAssistant Then
		
		If ClientRunParametersOnStart.CheckExternalResourceUsagePermissionsApplication Then
			
			AfterCheckApplicabilityOfPermissionsToUseExternalResources(
				ClientRunParametersOnStart.PermissionsToUseExternalResourcesApplicabilityCheck);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Switching between the external resource permissions setup wizard operations.
// 
//

// Starts external resource permissions setup wizard.
//
// Parameters:
//  IDs - Array - IDs (UUID) of requests to use external resources, for which the wizard is called.
//    
//  OwnerForm - ManagedForm, Undefined - a form, for which the wizard is opened.
//  ClosingNotification - NotifyDescription or Undefined - details of a notification that must be 
//    processed after closing the wizard,
//  EnablingMode - Boolean - indicates that the wizard is called upon enabling usage for the 
//    security profile infobase,
//  DisablingMode - Boolean - indicates that the wizard is called upon disabling usage for the 
//                             security profile infobase,
//  RecoveryMode - Boolean - indicates that the wizard is called to restore settings of security 
//    profiles in the server cluster (according to the current infobase data).
//
// Operation result is form opening
// "DataProcessor.ExternalResourcePermissionSetup.Form.PermissionRequiestInitialization", for which 
// a procedure is set as closing notification details
// AfterInitializeRequestForPermissionsToUseExternalResources().
//
Procedure StartInitializingRequestForPermissionsToUseExternalResources(
		Val IDs,
		Val OwnerForm,
		Val ClosingNotification,
		Val EnablingMode = False,
		Val DisablingMode = False,
		Val RecoveryMode = False) Export
	
	If EnablingMode OR DisplayPermissionSetupAssistant() Then
		
		State = RequestForPermissionsToUseExternalResourcesState();
		State.RequestIDs = IDs;
		State.NotifyDescription = ClosingNotification;
		State.OwnerForm = OwnerForm;
		State.EnablingMode = EnablingMode;
		State.DisablingMode = DisablingMode;
		State.RecoveryMode = RecoveryMode;
		
		FormParameters = New Structure();
		FormParameters.Insert("IDs", IDs);
		FormParameters.Insert("EnablingMode", State.EnablingMode);
		FormParameters.Insert("DisablingMode", State.DisablingMode);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		NotifyDescription = New NotifyDescription(
			"AfterInitializeRequestForPermissionsToUseExternalResources",
			ExternalResourcePermissionSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.PermissionsRequestInitialization",
			FormParameters,
			OwnerForm,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

// Starts the security profile permission setup dialog.
// Operation result is form opening:
// "DataProcessor.ExternalResourcePermissionSetup.Form.ExternalResourcePermissionSetup", for which a 
// procedure is set as closing notification details
// AfterSetUpPermissionsToUseExternalResources or abnormal wizard termination.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of external resource 
//                                   permissions application wizard (used values are OK and Cancel),
//  State - a structure that describes a permissions setup wizard state (see
//              RequestForPermissionsToUseExternalResourcesState))).
//
//
Procedure AfterInitializeRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If TypeOf(Result) = Type("Structure") AND Result.ReturnCode = DialogReturnCode.OK Then
		
		InitializationState = GetFromTempStorage(Result.StateStorageAddress);
		
		If InitializationState.PermissionApplicationRequired Then
			
			State.StorageAddress = InitializationState.StorageAddress;
			
			FormParameters = New Structure();
			FormParameters.Insert("StorageAddress", State.StorageAddress);
			FormParameters.Insert("RecoveryMode", State.RecoveryMode);
			FormParameters.Insert("CheckMode", State.CheckMode);
			
			NotifyDescription = New NotifyDescription(
				"AfterSetUpPermissionsToUseExternalResources",
				ExternalResourcePermissionSetupClient,
				State);
			
			OpenForm(
				"DataProcessor.ExternalResourcePermissionSetup.Form.ExternalResourcePermissionSetup",
				FormParameters,
				State.OwnerForm,
				,
				,
				,
				NotifyDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			// The requested permissions are redundant, no changes required to be made in the server cluster.
			// 
			CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
			
		EndIf;
		
	Else
		
		PermissionsToUseExternalResourcesSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Starts the dialog of waiting for server cluster security profile settings to be applied.
// Operation result is form opening:
// "DataProcessor.ExternalResourcePermissionSetup.FormPermissionRequestEnd", for which a procedure 
// is set as a closing notification details
// AfterCompleteRequestForPermissionsToUseExternalResources or abnormal wizard termination.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of external resource 
//                                   permissions application wizard (used values are OK, Skip, and Cancel).
//                                   Ignore value is used if no changes were made to the security 
//                                   profile settings but requests to use external resources must be 
//                                   considered applied (for example, if permissions to use all 
//                                   external resources being requested have already been granted),
//  State - a structure that describes a permissions setup wizard state (see
//                          RequestForPermissionsToUseExternalResourcesState))).
//
Procedure AfterSetUpPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK OR Result = DialogReturnCode.Ignore Then
		
		PlanPermissionApplyingCheckAfterOwnerFormClose(
			State.OwnerForm,
			State.RequestIDs);
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", State.StorageAddress);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		If Result = DialogReturnCode.OK Then
			FormParameters.Insert("Duration", ChangeApplyingTimeout());
		Else
			FormParameters.Insert("Duration", 0);
		EndIf;
		
		NotifyDescription = New NotifyDescription(
			"AfterCompleteRequestForPermissionsToUseExternalResources",
			ExternalResourcePermissionSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.PermissionsRequestEnd",
			FormParameters,
			ThisObject,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		PermissionsToUseExternalResourcesSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Processes the data entered to the external resource permission application wizard.
// The operation result is processing of the notification description, which was initially passed 
// from the form for which the the wizard was opened.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of external resource 
//                                   permissions application wizard (used values are OK and Cancel),
//  State - Structure - describes a permissions setup wizard state.
//                          See RequestForPermissionsToUseExternalResourcesState. 
//
Procedure AfterCompleteRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Then
		
		ShowUserNotification(NStr("ru = 'Настройка разрешений'; en = 'Permission settings'; pl = 'Permission settings';de = 'Permission settings';ro = 'Permission settings';tr = 'Permission settings'; es_ES = 'Permission settings'"),,
			NStr("ru = 'Внесены изменения в настройки профилей безопасности в кластере серверов.'; en = 'Security profile settings are changed in the server cluster.'; pl = 'Security profile settings are changed in the server cluster.';de = 'Security profile settings are changed in the server cluster.';ro = 'Security profile settings are changed in the server cluster.';tr = 'Security profile settings are changed in the server cluster.'; es_ES = 'Security profile settings are changed in the server cluster.'"));
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	Else
		
		PermissionsToUseExternalResourcesSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Asynchronously (relative to the code, from which the wizard was called) processes the 
// notification details that were initially passed from the form, for which the wizard was opened returning the return code OK.
//
// Parameters:
//  NotifyDescription - NotifyDescription - that was passed from the calling code.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	
	AttachIdleHandler("FinishExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Asynchronously (relative to the code, from which the wizard was called) processes the 
// notification details that were initially passed from the form, for which the wizard was opened returning the return code Cancel.
//
// Parameters:
//  NotifyDescription - NotifyDescription - that was passed from the calling code.
//
Procedure CancelSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	
	AttachIdleHandler("CancelExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Synchronously (relative to the code, from which the wizard was called) processes the notification 
// details that were initially passed from the form, for which the wizard was opened.
//
// Parameters:
//  ReturnCode - DialogReturnCode.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesSynchronously(Val ReturnCode) Export
	
	ClosingNotification = ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"];
	ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"] = Undefined;
	If ClosingNotification <> Undefined Then
		ExecuteNotifyProcessing(ClosingNotification, ReturnCode);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// External resource permissions setup wizard call logic for checking whether the operations whence 
// requests for permissions to use external resources were applied are completed.
// 
//

// Starts the wizard in operation completion check mode. In this mode, the wizard checks whether the 
// operation whence requests for permissions to use external resources were applied is completed.
//
// Parameters:
//  Result - Arbitrary - a result of closing the form, for which external resource permissions setup 
//                             wizard was opened. Does not used in the procedure body, the parameter 
//                             is required for defining a form closing notification description procedure.
//  State - Structure - describes a state of operation completion check.
//                          See PermissionsApplicabilityCheckStateAfterCloseOwnerForm. 
//
// The result of the procedure is a startup of the external resource permissions setup wizard in 
// operation completion check mode. Once the wizard is closed, the 
// PermissionApplyingAfterCheckAfterOwnerFormClose() procedure is used for processing the 
// notification description.
// AfterCheckPermissionsApplicabilityAfterCloseOwnerForm.
//
Procedure CheckPermissionsAppliedAfterOwnerFormClose(Result, State) Export
	
	OriginalOnCloseNotifyDescription = State.NotifyDescription;
	If OriginalOnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OriginalOnCloseNotifyDescription, Result);
	EndIf;
	
	CheckSSL = PermissionsToUseExternalResourcesSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	AfterCheckApplicabilityOfPermissionsToUseExternalResources(CheckSSL);
	
EndProcedure

// Checks whether requests to use external resources were applied.
//
// Parameters:
//  Check - Structure - a state of checking whether permissions to use external resources were applied
//             See ExternalResourcesPermissionsSetupServerCall. CheckApplyPermissionsToUseExternalResources.
//
Procedure AfterCheckApplicabilityOfPermissionsToUseExternalResources(Val CheckSSL)
	
	If Not CheckSSL.CheckResult Then
		
		ApplyingState = RequestForPermissionsToUseExternalResourcesState();
		
		ApplyingState.RequestIDs = CheckSSL.RequestIDs;
		ApplyingState.StorageAddress = CheckSSL.StateTemporaryStorageAddress;
		ApplyingState.CheckMode = True;
		
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.OK);
		Result.Insert("StateStorageAddress", CheckSSL.StateTemporaryStorageAddress);
		
		AfterInitializeRequestForPermissionsToUseExternalResources(
			Result, ApplyingState);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calling the external resource permissions setup wizard in special modes.
// 
//

// Calls the external resource permissions setup wizard in infobase security profile enabling mode.
// 
//
// Parameters:
//  OwnerForm - ManagedForm - a form to be locked before permissions are applied,
//  ClosingNotification - NotifyDescription - it will be called once permissions are granted.
//
Procedure StartEnablingSecurityProfilesUsage(OwnerForm, ClosingNotification = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification, True, False, False);
	
EndProcedure

// Calls the external resource permissions setup wizard in infobase security profile disabling mode.
// 
//
// Parameters:
//  OwnerForm - ManagedForm - a form to be locked before permissions are applied,
//  ClosingNotification - NotifyDescription - it will be called once permissions are granted.
//
Procedure StartDisablingSecurityProfilesUsage(OwnerForm, ClosingNotification = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification, False, True, False);
	
EndProcedure

// Calls the external resource permissions setup wizard in server cluster security profile settings 
// recovery mode based on the current infobase state.
// 
//
// Parameters:
//  OwnerForm - ManagedForm - a form to be locked before permissions are applied,
//  ClosingNotification - NotifyDescription - it will be called once permissions are granted.
//
Procedure StartRestoringSecurityProfiles(OwnerForm, ClosingNotification = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification, False, False, True);
	
EndProcedure

// Checks whether external (relative to 1C:Enterprise server cluster) resource permissions setup 
// wizard must be shown.
//
// Returns:
//   Boolean.
//
Function DisplayPermissionSetupAssistant()
	
	Return StandardSubsystemsClient.ClientParametersOnStart().DisplayPermissionSetupAssistant;
	
EndFunction

// Creates a structure used for storing the external resource permissions setup wizard state.
// 
//
// Returns:
//   Structure - for field details, see the function body.
//
Function RequestForPermissionsToUseExternalResourcesState()
	
	Result = New Structure();
	
	// IDs of requests to use external resources to be provided - Array(UUID).
	// 
	Result.Insert("RequestIDs", New Array());
	
	// Original notification description to be called once the request for permissions is applied.
	// 
	Result.Insert("NotifyDescription", Undefined);
	
	// Address in a temporary storage for storing data passed between forms.
	Result.Insert("StorageAddress", "");
	
	// Form whence the initial application of requests to use external resources was called.
	// 
	Result.Insert("OwnerForm");
	
	// Enabling mode - indicates whether security profiles are being enabled.
	Result.Insert("EnablingMode", False);
	
	// Disabling mode - indicates whether security profiles are being disabled.
	Result.Insert("DisablingMode", False);
	
	// Recovery mode - indicates whether security profile permissions are being recovered (the request 
	// for permissions is executed from scratch ignoring information on the previously granted 
	// permissions.
	Result.Insert("RecoveryMode", False);
	
	// Check mode - indicates whether the operation, which granted new permissions in the security 
	// profiles, is completed (for example, security profile permissions were granted upon writing the 
	// catalog item but the catalog item was not written).
	Result.Insert("CheckMode", False);
	
	Return Result;
	
EndFunction

// Creates a structure used for storing a state of check for completion of the operation where the 
// requests for permissions to use external resources were applied.
//
// Returns:
//   Structure - for field details, see the function body.
//
Function PermissionsApplicabilityCheckStateAfterCloseOwnerForm()
	
	Result = New Structure();
	
	// Address in a temporary storage for storing data passed between forms.
	Result.Insert("StorageAddress", Undefined);
	
	// Original owner form notification description to be called once the permissions are applied.
	// 
	Result.Insert("NotifyDescription", Undefined);
	
	Return Result;
	
EndFunction

// Returns the duration of waiting for changes in server cluster security profile settings to be 
// applied.
//
// Returns:
//   Number - duration of waiting for changes to be applied (in seconds).
//
Function ChangeApplyingTimeout()
	
	Return 20; // Inteval that rphost uses to update the current security profile settings from rmngr.
	
EndFunction

// Plans (by substituting a value to OnCloseNotifyDescription form property) a wizard call to check 
// whether the action is complete when the form that called the master is closed.
//
// As a result, the
// PermissionsApplicabilityCheckAfterOwnerFormClose procedure is called after closing the form, for 
// which external resource permissions setup wizard was opened.
//
// Parameters:
//  OwnerForm - ManagedForm, Undefined - when this form is closed, the procedure will check 
//    completion of operations that included requests for permissions to use external resources.
//    
//  RequestsIDs - Array - IDs (UUID) of requests for permissions to use external resources applied 
//    within the operation, the completion of which is being checked.
//
Procedure PlanPermissionApplyingCheckAfterOwnerFormClose(FormOwner, RequestsIDs)
	
	If TypeOf(FormOwner) = Type("ManagedForm") Then
		
		InitialNotifyDescription = FormOwner.OnCloseNotifyDescription;
		If InitialNotifyDescription <> Undefined Then
			
			If InitialNotifyDescription.Module = ExternalResourcePermissionSetupClient
					AND InitialNotifyDescription.ProcedureName = "CheckPermissionsAppliedAfterOwnerFormClose" Then
				Return;
			EndIf;
			
		EndIf;
		
		State = PermissionsApplicabilityCheckStateAfterCloseOwnerForm();
		State.NotifyDescription = InitialNotifyDescription;
		
		PermissionsApplicabilityCheckNotifyDescription = New NotifyDescription(
			"CheckPermissionsAppliedAfterOwnerFormClose",
			ExternalResourcePermissionSetupClient,
			State);
		
		FormOwner.OnCloseNotifyDescription = PermissionsApplicabilityCheckNotifyDescription;
		
	EndIf;
	
EndProcedure

#EndRegion