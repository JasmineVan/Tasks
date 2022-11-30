////////////////////////////////////////////////////////////////////////////////
// INTERFACE


Procedure OnAddSubsystem(Description) Export
	
	Description.Name    = "Licensing";
	Description.Version = Metadata.Subsystems.Licensing.Comment;
	
	// Using internal events and internal event handlers
	//Description.AddInternalEvents = True;
	Description.AddInternalEventHandlers = True;
	
	//Description.MainServerModule = "LicensingServer";
	
	// Standard subsystems library is required
	Description.RequiredSubsystems.Add("StandardSubsystems");
	
EndProcedure

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	a = 2;
EndProcedure

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// Client handlers
	ClientHandlers["StandardSubsystems.BaseFunctionality\BeforeStart"].Add("LicensingInternalClient");
	//ClientHandlers["StandardSubsystems.BaseFunctionality\OnExit"]     .Add("LicensingInternalClient");
	
	// Server handlers
	ServerHandlers["StandardSubsystems.BaseFunctionality\SessionParameterSettingHandlersOnAdd"].Add("LicensingInternal");
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnAddClientParametersOnStart"].        Add("LicensingInternal");
	
EndProcedure

// Adds the Infobase data update handler procedures 
// for all supported versions of the library or configuration to the list.
// Called before the beginning of Infobase data update to build the update plan.
//
// Parameters:
//  Handlers - ValueTable - for field description, see the InfobaseUpdate.NewUpdateHandlerTable procedure.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version        = "1.0.0.0";
//  Handler.Procedure      = "InfobaseUpdate.GoToVervion_1_0_0_0";
//  Handler.ExclusiveMode  = False;
//  Handler.Optional       = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
EndProcedure

// The procedure is called before the infobase data update handler procedures.
//
Procedure InfobaseBeforeUpdate() Export
	
EndProcedure

// The procedure is called after the infobase data is updated.
//		
// Parameters:
//   PreviousVersion   - String    - version before update. "0.0.0.0" for an empty infobase.
//   CurrentVersion    - String    - version after update.
//   ExecutedHandlers  - ValueTree - The list of executed handlers grouped by version number.
//   ShowUpdateDetails - Boolean   - (return value) If True, the update description form is displayed. 
//                                   The default value is True.
//   ExclusiveMode     - Boolean   - flag specifying whether the update was performed in exclusive mode.
//		
// Example of iteration through executed update handlers:
//		
// For Each Version In CompletedHandlers.Rows Do
//		
// 	If Version.Version = "*" Then
// 		  // Handler that is executed with each version change
// 	Else
// 		  // Handler that is executed for a certain version
// 	EndIf;
//		
// 	For Each Handler In Version.Rows Do
// 		...
// 	EndDo;
//		
// EndDo;
//
Procedure AfterInfobaseUpdate(Val PreviousVersion, Val CurrentVersion, Val ExecutedHandlers, ShowUpdateDetails, ExclusiveMode) Export
	
EndProcedure

// Called when preparing the spreadsheet document with the application update list.
//
// Parameters:
//   Template - SpreadsheetDocument - all libraries and configuration update description.
//              Template can be supplemented or replaced.
//              See also common ApplicationReleaseNotes layout.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ СИСТЕМЫ

// Returns the mapping between session parameter names and their initialization handlers.
//
Procedure SessionParameterSettingHandlersOnAdd(Handlers) Export
	
	Handlers.Insert("CurrentLicensingServerAddress", "LicensingInternal.SessionParametersSetting");
	Handlers.Insert("LicensingServerAddress",        "LicensingInternal.SessionParametersSetting");
	Handlers.Insert("CertificateList",                "LicensingInternal.SessionParametersSetting");
	Handlers.Insert("ComponentStoragePlace",           "LicensingInternal.SessionParametersSetting");
	Handlers.Insert("UnsafeOperationProtectionIsOn",   "LicensingInternal.SessionParametersSetting");
	
EndProcedure

// Fills the CurrentUser or CurrentExternalUser session parameter with user 
// that matches the current session infobase user.
// 
//  If the user is not found in the catalog and administrative rights are granted,
//  a new user is created in the catalog. If administrative rights are denied, an exception is thrown.
// 
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If NOT(ParameterName="CurrentLicensingServerAddress" OR ParameterName="LicensingServerAddress" OR ParameterName="CertificateList" OR ParameterName="ComponentStoragePlace" OR ParameterName="UnsafeOperationProtectionIsOn") Then
		Return;
	EndIf;
	
	LicensingServer.SetSessionParameters();
	
	SpecifiedParameters.Add("CurrentLicensingServerAddress");
	SpecifiedParameters.Add("LicensingServerAddress");
	SpecifiedParameters.Add("CertificateList");
	SpecifiedParameters.Add("ComponentStoragePlace");
	SpecifiedParameters.Add("UnsafeOperationProtectionIsOn");
	
EndProcedure

// Fills the parameters that are used by the client code on configuration start.
//
// Parameters:
//   Parameters - Structure - Start parameters.
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	// Производим последовательную инициализацию компонент защиты входящих в состав продукта
	LaunchResults = New Array;
	Error            = FALSE;
	
	// Инициализируем параметры сеанса, If они NOT были инициализированы
	LicensingServerAddress = SessionParameters.CurrentLicensingServerAddress;
	
	For Each ServerAddress In LicensingServer.LicensingServerAddressList() Do
		
		LicensingServer.SetSessionParameterLicensingServerCurrentAddress(ServerAddress);
		
		For Each Product In LicensingSupport.GetProductList() Do
			
			LaunchParameters = New Structure("DataProcessorName,ProductName,ErrorDescription,ErrorCode", Product.Key, Product.Value, "", 0);
			
			If NOT LicensingServer.LicensingSystemStart(Product.Key, LaunchParameters.ErrorDescription, LaunchParameters.ErrorCode) Then
				Error = TRUE;
			EndIf;
			
			LaunchResults.Add(LaunchParameters);
			
		EndDo;
		
		If (NOT Error) OR (NOT LicensingServer.IsErrorConnectionWithServer(LaunchResults)) Then
			Break;
		EndIf;
		
	EndDo;
	
	// Получаем In параметров сеанса кеш значений Производим получение 
	Parameters.Insert("ProtectionSystemState", New Structure("LaunchResults,Error", LaunchResults, Error));
	
EndProcedure






