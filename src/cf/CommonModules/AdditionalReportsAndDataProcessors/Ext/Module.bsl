///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Attaches an external report or data processor and returns the name of the attached report or data processor.
// Then registers the report or data processor in the application with a unique name. You can use 
// this name to create a report or data processor object or open its forms.
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a data processor to attach.
//
// Returns:
//   * String       - a name of the attached report or data processor.
//   * Undefined - if an invalid reference is passed.
//
Function AttachExternalDataProcessor(Ref) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	SaaSIntegration.OnAttachExternalDataProcessor(Ref, StandardProcessing, Result);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
		
	// Validating the passed parameters.
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	
	// Attaching.
#If ThickClientOrdinaryApplication Then
	DataProcessorName = GetTempFileName();
	DataProcessorStorage = Common.ObjectAttributeValue(Ref, "DataProcessorStorage");
	BinaryData = DataProcessorStorage.Get();
	BinaryData.Write(DataProcessorName);
	Return DataProcessorName;
#EndIf
	
	Kind = Common.ObjectAttributeValue(Ref, "Kind");
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Manager = ExternalReports;
	Else
		Manager = ExternalDataProcessors;
	EndIf;
	
	StartParameters = Common.ObjectAttributesValues(Ref, "SafeMode, DataProcessorStorage");
	AddressInTempStorage = PutToTempStorage(StartParameters.DataProcessorStorage.Get());
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If UseSecurityProfiles Then
		
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		SafeMode = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Ref);
		
		If SafeMode = Undefined Then
			SafeMode = True;
		EndIf;
		
	Else
		
		SafeMode = GetFunctionalOption("StandardSubsystemsSaaS") Or StartParameters.SafeMode;
		
		If SafeMode Then
			PermissionsQuery = New Query(
				"SELECT TOP 1
				|	AdditionalReportsAndDataProcessorsPermissions.LineNumber,
				|	AdditionalReportsAndDataProcessorsPermissions.PermissionKind
				|FROM
				|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS AdditionalReportsAndDataProcessorsPermissions
				|WHERE
				|	AdditionalReportsAndDataProcessorsPermissions.Ref = &Ref");
			PermissionsQuery.SetParameter("Ref", Ref);
			HasPermissions = Not PermissionsQuery.Execute().IsEmpty();
			
			CompatibilityMode = Common.ObjectAttributeValue(Ref, "PermissionsCompatibilityMode");
			If CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2
				AND HasPermissions Then
				SafeMode = False;
			EndIf;
		EndIf;
		
	EndIf;
	
	WriteComment(Ref, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Подключение, БезопасныйРежим = ""%1"".'; en = 'Attachment, SafeMode = ""%1.""'; pl = 'Połączenie, SafeMode = ""%1"".';de = 'Verbindung, AbgesicherterModus = ""%1"".';ro = 'Conexiune, SafeMode = ""%1"".';tr = 'Bağlantı, GüvenliMod = ""%1"".'; es_ES = 'Conexión, ModoSeguro = ""%1"".'"), SafeMode));
	DataProcessorName = Manager.Connect(AddressInTempStorage, , SafeMode,
		Common.ProtectionWithoutWarningsDetails());
	Return DataProcessorName;
	
EndFunction

// Returns an object of an external report or data processor.
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report or a data processor to attach.
//
// Returns:
//   * ExternalDataProcessorObject - an object of the attached data processor.
//   * ExternalReportObject     - an attached report object.
//   * Undefined           - if an invalid reference is passed.
//
Function ExternalDataProcessorObject(Ref) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	SaaSIntegration.OnCreateExternalDataProcessor(Ref, StandardProcessing, Result);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	// Attaching.
	DataProcessorName = AttachExternalDataProcessor(Ref);
	
	// Validating the passed parameters.
	If DataProcessorName = Undefined Then
		Return Undefined;
	EndIf;
	
	// Getting an object instance.
	If Ref.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		OR Ref.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Manager = ExternalReports;
	Else
		Manager = ExternalDataProcessors;
	EndIf;
	
	Return Manager.Create(DataProcessorName);
	
EndFunction

// Generates a print form based on an external source.
//
// Parameters:
//   AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - an external data processor.
//   SourceParameters            - Structure - a structure with the following properties:
//       * CommandID - String - a list of comma-separated templates.
//       * RelatedObjects    - Array
//   PrintFormsCollection - ValueTable - generated spreadsheet documents (return parameter).
//   PrintObjects         - ValueList - a map between objects and names of spreadsheet document 
//                                             print areas. Value - Object, Presentation - a name of 
//                                             the area the object (return parameter) was displayed in.
//   OutputParameters       - Structure       - additional parameters of generated spreadsheet 
//                                             documents (return parameter).
//
Procedure PrintByExternalSource(AdditionalDataProcessorRef, SourceParameters, PrintFormsCollection,
	PrintObjects, OutputParameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.PrintByExternalSource(
			AdditionalDataProcessorRef,
			SourceParameters,
			PrintFormsCollection,
			PrintObjects,
			OutputParameters);
	EndIf;
	
EndProcedure

// Generates a details template for an external report or data processor to be filled in later.
//
// Parameters:
//   SSLVersion - String - the Standard Subsystems Library version expected by the external data 
//                        processor or report. See StandardSubsystemsServer.LibraryVersion. 
//
// Returns:
//   Structure - parameters of an external report or a data processor:
//       * Kind - String - a kind of the external report or data processor. To specify the kind, use functions
//           AdditionalReportsAndDataProcessorsClientServer.DataProcessorKind<KindName>.
//           You can also specify the kind explicitly:
//           "PrintForm",
//           "ObjectFilling",
//           "RelatedObjectsCreation",
//           "Report",
//           "MessageTemplate",
//           "AdditionalDataProcessor", or
//           "AdditionalReport".
//       
//       * Version - String - a version of the report or data processor (later on data processor).
//           Conforms to "<Senior number>.<Junior number>" format.
//       
//       * Assignment - Array - full names of the configuration objects (String) for which the data processor is intended for.
//                               Optional property.
//       
//       * Description - String - a presentation for the administrator (a catalog item description).
//                                 If empty, a presentation of an external data processor metadata object is used.
//                                 Optional property.
//       
//       * SafeMode - Boolean - indicates whether the external data processor is attached in safe mode.
//                                    True by default (data processor runs in safe mode).
//                                    In safe mode:
//                                     Privileged mode is ignored.
//                                     The following external (relative to the 1C:Enterprise platform) actions are prohibited:
//                                      COM;
//                                      Importing add-ins
//                                      Running external applications and operating system commands
//                                      Accessing file system except for temporary files
//                                      Accessing the Internet.
//                                    Optional property.
//       
//       * Permissions - Array - additional permissions required for the external data processor in safe mode.
//                               ArrayElement - XDTODataObject - a permission of type
//                               {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}PermissionBase.
//                               To generate permission details, use functions
//                               SafeModeManager.Permission<PermissionKind>(<PermissionParameters>).
//                               Optional property.
//       
//       * Information - String - short information on the external data processor.
//                               It is recommended that you provide the data processor functionality for the administrator in this parameter.
//                               If empty, a comment of an external data processor metadata object is used.
//       
//       * SSLVersion - String - optional. Library version expected by the external data processor mechanisms.
//                              See StandardSubsystemsServer.LibraryVersion. 
//                              Optional property.
//       
//       * DefineFormSettings - Boolean - only for the additional reports attached to the ReportForm common form.
//                                             Allows you to override some settings of the common 
//                                             report form and subscribe to its events.
//                                             If True, define the procedure in the report object module using the following template:
//           
//           // Define settings of the "Report options" subsystem common report form.
//           //
//           // Parameters:
//           //   Form - ManagedForm, Undefined - a report form or a report settings form.
//           //      Undefined when called without a context.
//           //   OptionKey - String, Undefined - a predefined report option name
//           //       or a UUID of a custom one.
//           //      Undefined when called without a context.
//           //   Settings - Structure - see the return value of
//           //       ReportsClientServer.GetDefaultReportSettings().
//           //
//           Procedure DefineFormSettings(Form, VariantKey, Settings) Export
//           	// Procedure code.
//           EndProcedure
//           
//           For more information, see help for subsystems "Additional reports and data processors" and "Report options".
//           Optional property.
//       
//       * Commands - ValueTable - settings of the commands provided by the external data processor (optional for reports):
//           ** ID - String - an internal command name. For external print forms (when Kind = "PrintForm"):
//                 ID can contain comma-separated names of one or more print commands.
//                  For more information, see details of column ID in function 
//                 CreatePrintCommandsCollection() of common module PrintManager. 
//           ** Presentation - String - a user presentation of the command.
//           ** Usage - String - a command type:
//               "ClientMethodCall",
//               "ServerMethodCall",
//               "FillingForm",
//               "FormOpening", or
//               "ScenarioInSafeMode".
//               To get command types, use functions
//               AdditionalReportsAndDataProcessorsClientServer.CommandType<TypeName>.
//               Comments to these functions also contain templates of command handler procedures.
//           ** ShowNotification - Boolean - if True, show "Executing command..." notification upon command execution.
//              It is used for all command types except for commands for opening a form (Usage = "FormOpening".)
//           ** Modifier - String - an additional command classification.
//               For external print forms (when Kind = "PrintForm"):
//                 "MXLPrinting" - for print forms generated on the basis of spreadsheet templates.
//               For data import from file (when Kind = "PrintForm" and Usage = "DataImportFromFiles"):
//                 Modifier is required. It must contain the full name of the metadata object 
//                 (catalog) the data is being imported for.
//                 
//           ** Hide - Boolean - optional. Indicates whether it is an internal command.
//               If True, the command is hidden from the additional object card.
//
Function ExternalDataProcessorInfo(SSLVersion = "") Export
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Kind", "");
	RegistrationParameters.Insert("Version", "0.0");
	RegistrationParameters.Insert("Purpose", New Array);
	RegistrationParameters.Insert("Description", Undefined);
	RegistrationParameters.Insert("SafeMode", True);
	RegistrationParameters.Insert("Information", Undefined);
	RegistrationParameters.Insert("SSLVersion", SSLVersion);
	RegistrationParameters.Insert("DefineFormSettings", False);
	
	TabularSectionAttributes = Metadata.Catalogs.AdditionalReportsAndDataProcessors.TabularSections.Commands.Attributes;
	
	CommandsTable = New ValueTable;
	CommandsTable.Columns.Add("Presentation", TabularSectionAttributes.Presentation.Type);
	CommandsTable.Columns.Add("ID", TabularSectionAttributes.ID.Type);
	CommandsTable.Columns.Add("Use", New TypeDescription("String"));
	CommandsTable.Columns.Add("ShowNotification", TabularSectionAttributes.ShowNotification.Type);
	CommandsTable.Columns.Add("Modifier", TabularSectionAttributes.Modifier.Type);
	CommandsTable.Columns.Add("Hide",      TabularSectionAttributes.Hide.Type);
	CommandsTable.Columns.Add("CommandsToReplace", TabularSectionAttributes.CommandsToReplace.Type);
	
	RegistrationParameters.Insert("Commands", CommandsTable);
	RegistrationParameters.Insert("Permissions", New Array);
	
	Return RegistrationParameters;
EndFunction

// Executes a data processor command and returns the result.
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   CommandParameters - Structure - parameters of the command.
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - a catalog item.
//       * CommandID - String - a name of the command being executed.
//       * RelatedObjects - Array - references to the objects the data processor is running for. 
//                                         Mandatory for assignable data processors.
//   ResultAddress - String - optional. Address of a temporary storage where the execution result 
//                              will be stored.
//
// Returns:
//   Structure - an execution result to be passed to client.
//   Undefined - if ResultAddress is passed.
//
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	If TypeOf(CommandParameters.AdditionalDataProcessorRef) <> Type("CatalogRef.AdditionalReportsAndDataProcessors")
		Or CommandParameters.AdditionalDataProcessorRef = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	
	ExternalObject = ExternalDataProcessorObject(CommandParameters.AdditionalDataProcessorRef);
	CommandID = CommandParameters.CommandID;
	ExecutionResult = ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, ResultAddress);
	
	Return ExecutionResult;
	
EndFunction

// Executes a data processor command directly from the external object form and returns the execution result.
// For a usage example, see AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground(). 
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   CommandID - String    - a command name as it is specified in function ExternalDataProcessorInfo() in the object module.
//   CommandParameters     - Structure - command execution parameters.
//                                      See AdditionalReportsAndDataProcessorsClient. ExecuteCommandInBackground().
//   Form                - ManagedForm - a form to return the result to.
//
// Returns:
//   Structure - for internal use.
//
Function ExecuteCommandFromExternalObjectForm(CommandID, CommandParameters, Form) Export
	
	ExternalObject = Form.FormAttributeToValue("Object");
	ExecutionResult = ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, Undefined);
	Return ExecutionResult;
	
EndFunction

// Generates a list of sections where the additional report calling command is available.
//
// Returns:
//   Array - an array of Subsystem metadata objects - metadata of the sections where the list of 
//                                                    commands of additional reports is displayed.
//
Function AdditionalReportSections() Export
	MetadataSections = New Array;
	
	AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalReports(MetadataSections);
	
	If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		ModuleDataProcessorsControlPanelSSL = Common.CommonModule("DataProcessors.SSLAdministrationPanel");
		ModuleDataProcessorsControlPanelSSL.OnDefineSectionsWithAdditionalReports(MetadataSections);
	EndIf;
	
	Return MetadataSections;
EndFunction

// Generates a list of sections where the additional data processor calling command is available.
//
// Returns:
//   Array - an array of Subsystem metadata objects - metadata of the sections where the list of 
//   commands of additional data processors is displayed.
//
Function AdditionalDataProcessorSections() Export
	MetadataSections = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		ModuleDataProcessorsControlPanelSSL = Common.CommonModule("DataProcessors.SSLAdministrationPanel");
		ModuleDataProcessorsControlPanelSSL.OnDefineSectionsWithAdditionalDataProcessors(MetadataSections);
	EndIf;
	
	AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalDataProcessors(MetadataSections);
	
	Return MetadataSections;
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ExternalDataProcessorObject instead.
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report or a data processor to attach.
//
// Returns:
//   * ExternalDataProcessorObject - an object of the attached data processor.
//   * ExternalReportObject     - an attached report object.
//   * Undefined           - if an invalid reference is passed.
//
Function GetExternalDataProcessorsObject(Ref) Export
	
	Return ExternalDataProcessorObject(Ref);
	
EndFunction

// Obsolete. Use AttachableCommands.OnCreateAtServer.
//
// Parameters:
//   Form - ManagedForm - a form.
//   FormType - String - a form type.
//
Procedure OnCreateAtServer(Form, FormType = Undefined) Export
	Return;
EndProcedure

// Obsolete. Use AttachableCommands.ExecuteCommand.
//
// Executes an assignable command in context from the related object form.
// Intended to be called by the subsystem code from the form of an assignable object item (for 
// example, a catalog or a document).
//
// Important: Checking functional option UseAdditionalReportsAndDataProcessors
// must be executed by the calling code.
//
// Parameters:
//   Form               - ManagedForm - a form the command is called from.
//   ItemName         - String           - a name of the form command that is being executed.
//   ExecutionResult - Structure        - for internal use.
//
Procedure ExecuteAssignableCommandAtServer(Form, ItemName, ExecutionResult = Undefined) Export
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Determines a list of metadata objects to which an assignable data processor of the passed kind can be applied.
//
// Parameters:
//   Kind - EnumRef.AdditionalReportsAndDataProcessorsKinds - a kind of an external data processor.
//
// Returns:
//   ValueTable - metadata object details.
//       * Metadata - MetadataObject - a metadata object attached to this kind.
//       * FullName - String - a full name of the metadata object, for example, Catalog.Currencies.
//       * Ref     - CatalogRef.MetadataObjectsIDs - a metadata object reference.
//       * Kind        - String - a metadata object kind.
//       * Presentation       - String - a metadata object presentation.
//       * FullPresentation - String - a presentation of a metadata object name and kind.
//   Undefined - if invalid Kind is passed.
//
Function AttachedMetadataObjects(Kind) Export
	Result = New ValueTable;
	Result.Columns.Add("Metadata");
	Result.Columns.Add("FullName", New TypeDescription("String"));
	Result.Columns.Add("Ref", New TypeDescription("CatalogRef.MetadataObjectIDs, CatalogRef.ExtensionObjectIDs"));
	Result.Columns.Add("Kind", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("FullPresentation", New TypeDescription("String"));
	
	Result.Indexes.Add("Ref");
	Result.Indexes.Add("Kind");
	Result.Indexes.Add("FullName");
	
	TypesOrMetadataArray = New Array;
	
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation Then
		
		TypesOrMetadataArray = Metadata.DefinedTypes.ObjectWithAdditionalCommands.Type.Types();
		
	ElsIf Kind = Enums.AdditionalReportsAndDataProcessorsKinds.MessageTemplate Then
		
		If Common.SubsystemExists("StandardSubsystems.MessageTemplates") Then
			ModuleMessagesTemplatesInternal = Common.CommonModule("MessageTemplatesInternal");
			TypesOrMetadataArray = ModuleMessagesTemplatesInternal.MessagesTemplatesSources()
		Else
			Return Result;
		EndIf;
		
	ElsIf Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		
		If Common.SubsystemExists("StandardSubsystems.Print") Then
			ModulePrintManager = Common.CommonModule("PrintManagement");
			TypesOrMetadataArray = ModulePrintManager.PrintCommandsSources()
		Else
			Return Result;
		EndIf;
		
	ElsIf Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		
		TypesOrMetadataArray = AdditionalDataProcessorSections();
		
	ElsIf Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		TypesOrMetadataArray = AdditionalReportSections();
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	For Each TypeOrMetadata In TypesOrMetadataArray Do
		If TypeOf(TypeOrMetadata) = Type("Type") Then
			MetadataObject = Metadata.FindByType(TypeOrMetadata);
			If MetadataObject = Undefined Then
				Continue;
			EndIf;
		Else
			MetadataObject = TypeOrMetadata;
		EndIf;
		
		TableRow = Result.Add();
		TableRow.Metadata = MetadataObject;
		
		If MetadataObject = AdditionalReportsAndDataProcessorsClientServer.StartPageName() Then
			TableRow.FullName = AdditionalReportsAndDataProcessorsClientServer.StartPageName();
			TableRow.Ref = Catalogs.MetadataObjectIDs.EmptyRef();
			TableRow.Kind = "Subsystem";
			TableRow.Presentation = NStr("ru = 'Начальная страница'; en = 'Home page'; pl = 'Strona podstawowa';de = 'Startseite';ro = 'Pagina principală';tr = 'Ana sayfa'; es_ES = 'Página principal'");
		Else
			TableRow.FullName = MetadataObject.FullName();
			TableRow.Ref = Common.MetadataObjectID(MetadataObject);
			TableRow.Kind = Left(TableRow.FullName, StrFind(TableRow.FullName, ".") - 1);
			TableRow.Presentation = MetadataObject.Presentation();
		EndIf;
		
		TableRow.FullPresentation = TableRow.Presentation + " (" + TableRow.Kind + ")";
	EndDo;
	
	Return Result;
EndFunction

// Generates a new query used to get a command table for additional reports or data processors.
//
// Parameters:
//   DataProcessorsKind - EnumRef.AdditionalReportsAndDataProcessorsKinds - a data processor kind.
//   Placement - CatalogRef.MetadataObjectsIDs, String - a reference or a full name of the metadata 
//       object linked to the searched additional reports and data processors.
//       Global data processors are located in sections, while context ones are used in catalogs and documents.
//   IsObjectForm - Boolean - optional.
//       Type of forms that contain context additional reports and data processors.
//       True - only reports and data processors linked to object forms.
//       False - only reports and data processors linked to list forms.
//   CommandsTypes - EnumRef.AdditionalReportsAndDataProcessorsPublicationOptions - a type of commands to get.
//       - Array - types of commands to get.
//           * EnumRef.AdditionalReportsAndDataProcessorsPublicationOptions
//   EnabledOnly - Boolean - optional.
//       Type of forms that contain context additional reports and data processors.
//       True - only reports and data processors linked to object forms.
//       False - only reports and data processors linked to list forms.
//
// Returns:
//   ValueTable - commands of additional reports or data processors.
//       * Ref - CatalogRef.AdditionalReportsAndDataProcessors - a reference of an additional report or data processor.
//       * ID - String - a command ID as it is specified by the developer of the additional object.
//       * StartupOption - EnumRef.AdditionalDataProcessorsCallMethods - 
//           a method of calling the additional object command.
//       * Presentation - String - a command name in the user interface.
//       * ShowNotification - Boolean - show user notification when a command is executed.
//       * Modifier - String - a command modifier.
//
Function NewQueryByAvailableCommands(DataProcessorsKind, Placement, IsObjectForm = Undefined, CommandsTypes = Undefined, EnabledOnly = True) Export
	Query = New Query;
	
	If TypeOf(Placement) = Type("CatalogRef.MetadataObjectIDs") Then
		ParentOrSectionRef = Placement;
	Else
		If ValueIsFilled(Placement) Then
			ParentOrSectionRef = Common.MetadataObjectID(Placement);
		Else
			ParentOrSectionRef = Undefined;
		EndIf;
	EndIf;
	
	If ParentOrSectionRef <> Undefined Then // Filter by parent is set.
		AreGlobalDataProcessors = (
			DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport
			Or DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor);
		
		// Calls used for global and for assignable data processors are fundamentally different.
		If AreGlobalDataProcessors Then
			QueryText =
			"SELECT ALLOWED DISTINCT
			|	AdditionalReportsAndDataProcessors.Ref
			|INTO ttRefs
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Sections AS TableSections
			|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|		ON (TableSections.Section = &SectionRef)
			|			AND TableSections.Ref = AdditionalReportsAndDataProcessors.Ref
			|WHERE
			|	AdditionalReportsAndDataProcessors.Kind = &Kind
			|	AND NOT AdditionalReportsAndDataProcessors.DeletionMark
			|	AND AdditionalReportsAndDataProcessors.Publication = &Publication
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	CommandsTable.Ref,
			|	CommandsTable.ID,
			|	CommandsTable.CommandsToReplace,
			|	CommandsTable.StartupOption,
			|	CommandsTable.Presentation,
			|	CommandsTable.ShowNotification,
			|	CommandsTable.Modifier,
			|	ISNULL(QuickAccess.Available, FALSE) AS Use
			|INTO SummaryTable
			|FROM
			|	ttRefs AS ReferencesTable
			|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
			|		ON ReferencesTable.Ref = CommandsTable.Ref
			|			AND (CommandsTable.Hide = FALSE)
			|			AND (CommandsTable.StartupOption IN (&CommandsTypes))
			|		LEFT JOIN InformationRegister.DataProcessorAccessUserSettings AS QuickAccess
			|		ON (CommandsTable.Ref = QuickAccess.AdditionalReportOrDataProcessor)
			|			AND (CommandsTable.ID = QuickAccess.CommandID)
			|			AND (QuickAccess.User = &CurrentUser)
			|WHERE
			|	ISNULL(QuickAccess.Available, FALSE)";
			Query.SetParameter("SectionRef", ParentOrSectionRef);
			
			If Not EnabledOnly Then
				QueryText = StrReplace(QueryText,
					"WHERE
					|	ISNULL(QuickAccess.Available, FALSE)",
					"");
			EndIf;
			
		Else
			
			QueryText =
			"SELECT ALLOWED DISTINCT
			|	AssignmentTable.Ref
			|INTO ttRefs
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS AssignmentTable
			|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|		ON (AssignmentTable.RelatedObject = &ParentRef)
			|			AND AssignmentTable.Ref = AdditionalReportsAndDataProcessors.Ref
			|			AND (AdditionalReportsAndDataProcessors.DeletionMark = FALSE)
			|			AND (AdditionalReportsAndDataProcessors.Kind = &Kind)
			|			AND (AdditionalReportsAndDataProcessors.Publication = &Publication)
			|			AND (AdditionalReportsAndDataProcessors.UseForListForm = TRUE)
			|			AND (AdditionalReportsAndDataProcessors.UseForObjectForm = TRUE)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	CommandsTable.Ref,
			|	CommandsTable.ID,
			|	CommandsTable.CommandsToReplace,
			|	CommandsTable.StartupOption,
			|	CommandsTable.Presentation,
			|	CommandsTable.ShowNotification,
			|	CommandsTable.Modifier,
			|	UNDEFINED AS Use
			|INTO SummaryTable
			|FROM
			|	ttRefs AS ReferencesTable
			|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
			|		ON ReferencesTable.Ref = CommandsTable.Ref
			|			AND (CommandsTable.Hide = FALSE)
			|			AND (CommandsTable.StartupOption IN (&CommandsTypes))";
			
			Query.SetParameter("ParentRef", ParentOrSectionRef);
			
		EndIf;
		
	Else
		
		QueryText =
		"SELECT ALLOWED
		|	CommandsTable.Ref,
		|	CommandsTable.ID,
		|	CommandsTable.CommandsToReplace,
		|	CommandsTable.StartupOption,
		|	CommandsTable.Presentation AS Presentation,
		|	CommandsTable.ShowNotification,
		|	CommandsTable.Modifier,
		|	UNDEFINED AS Use
		|INTO SummaryTable
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
		|		ON CommandsTable.Ref = AdditionalReportsAndDataProcessors.Ref
		|			AND (AdditionalReportsAndDataProcessors.Kind = &Kind)
		|			AND (CommandsTable.StartupOption IN (&CommandsTypes))
		|			AND (AdditionalReportsAndDataProcessors.Publication = &Publication)
		|			AND (AdditionalReportsAndDataProcessors.DeletionMark = FALSE)
		|			AND (AdditionalReportsAndDataProcessors.UseForListForm = TRUE)
		|			AND (AdditionalReportsAndDataProcessors.UseForObjectForm = TRUE)
		|			AND (CommandsTable.Hide = FALSE)";
		
	EndIf;
	
	// Disabling filters by list and object form.
	If IsObjectForm <> True Then
		QueryText = StrReplace(QueryText, "AND (AdditionalReportsAndDataProcessors.UseForObjectForm = TRUE)", "");
	EndIf;
	If IsObjectForm <> False Then
		QueryText = StrReplace(QueryText, "AND (AdditionalReportsAndDataProcessors.UseForListForm = TRUE)", "");
	EndIf;
	
	If CommandsTypes = Undefined Then
		QueryText = StrReplace(QueryText, "AND (CommandsTable.StartupOption IN (&CommandsTypes))", "");
	Else
		Query.SetParameter("CommandsTypes", CommandsTypes);
	EndIf;
	
	Query.SetParameter("Kind", DataProcessorsKind);
	If AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		QueryText = StrReplace(QueryText, "Publication = &Publication", "Publication <> &Publication");
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled);
	Else
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used);
	EndIf;
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.Text = QueryText;
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.AdditionalReportsAndDataProcessorsSaaS") 
		AND Common.DataSeparationEnabled() Then
		RegisterName = "UseSuppliedAdditionalReportsAndProcessorsInDataAreas";
		Query.Text = Query.Text + ";
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SummaryTable.Ref,
		|	SummaryTable.ID,
		|	SummaryTable.CommandsToReplace,
		|	SummaryTable.StartupOption,
		|	SummaryTable.Presentation AS Presentation,
		|	SummaryTable.ShowNotification,
		|	SummaryTable.Modifier,
		|	SummaryTable.Use
		|FROM
		|	SummaryTable AS SummaryTable
		|		INNER JOIN &FullRegisterName AS Installations
		|		ON SummaryTable.Ref = Installations.DataProcessorToUse
		|
		|ORDER BY
		|	Presentation";
		Query.Text = StrReplace(Query.Text, "&FullRegisterName", "InformationRegister." + RegisterName);
	Else
		Query.Text = StrReplace(Query.Text, "INTO SummaryTable", "");
		Query.Text = Query.Text + "
		|
		|ORDER BY
		|	Presentation";
	EndIf;
	
	Return Query;
EndFunction

// Handler of the attached filling command.
//
// Parameters
//   RefsArrray - Array - an array of selected object references, for which the command is running.
//   ExecutionParameters - Structure - a command context.
//       * CommandDetails - Structure - information about the running command.
//          ** ID - String - a command ID.
//          ** Presentation - String - a command presentation on a form.
//          ** Name - String - a command name on a form.
//       * Form - ManagedForm - a form the command is called from.
//       * Source - FormDataStructure, FormTable - an object or a form list with the Reference field.
//
Procedure PopulateCommandHandler(Val RefsArray, Val ExecutionParameters) Export
	CommandToExecute = ExecutionParameters.CommandDetails.AdditionalParameters;
	
	ExternalObject = ExternalDataProcessorObject(CommandToExecute.Ref);
	
	CommandParameters = New Structure;
	CommandParameters.Insert("ThisForm", ExecutionParameters.Form);
	CommandParameters.Insert("AdditionalDataProcessorRef", CommandToExecute.Ref);
	
	ExecuteExternalObjectCommand(ExternalObject, CommandToExecute.ID, CommandParameters, Undefined);
EndProcedure

Function AdditionalReportsAndDataProcessorsAreUsed() Export
	Return GetFunctionalOption("UseAdditionalReportsAndDataProcessors");
EndFunction

Function IsAdditionalReportOrDataProcessorType(Type) Export
	Return (Type = Type("CatalogRef.AdditionalReportsAndDataProcessors"));
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.

// Delete subsystems references before their deletion.
Procedure BeforeDeleteMetadataObjectID(MetadataObjectIDObject, Cancel) Export
	If MetadataObjectIDObject.DataExchange.Load Then
		Return;
	EndIf;
	
	MetadataObjectIDRef = MetadataObjectIDObject.Ref;
	Query = New Query(
		"SELECT DISTINCT
		|	ReportAndDataProcessorSections.Ref
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Sections AS ReportAndDataProcessorSections
		|WHERE
		|	ReportAndDataProcessorSections.Section = &Subsystem
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ReportAndDataProcessorSections.Ref
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS ReportAndDataProcessorSections
		|WHERE
		|	ReportAndDataProcessorSections.RelatedObject = &Subsystem");
	Query.SetParameter("Subsystem", MetadataObjectIDRef);
	ObjectsToChange = Query.Execute().Unload().UnloadColumn("Ref");
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each CatalogRef In ObjectsToChange Do
			LockItem = Lock.Add(Metadata.Catalogs.AdditionalReportsAndDataProcessors.FullName());
			LockItem.SetValue("Ref", CatalogRef);
		EndDo;
		Lock.Lock();
		
		For Each CatalogRef In ObjectsToChange Do
			CatalogObject = CatalogRef.GetObject();
			
			FoundItems = CatalogObject.Sections.FindRows(New Structure("Section", MetadataObjectIDRef));
			For Each TableRow In FoundItems Do
				CatalogObject.Sections.Delete(TableRow);
			EndDo;
			
			FoundItems = CatalogObject.Purpose.FindRows(New Structure("RelatedObject", MetadataObjectIDRef));
			For Each TableRow In FoundItems Do
				CatalogObject.Purpose.Delete(TableRow);
			EndDo;
			
			CatalogObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;	
EndProcedure

// Updates reports and data processors in the catalog from common templates.
//
// Parameters:
//   ReportsAndDataProcessors - ValueTable - a table of reports and data processors in common templates.
//       * MetadataObject - MetadataObject - a report or a data processor from the configuration.
//       * OldObjectsNames - Array - old names of objects used while searching for old versions of the report or data processor.
//           ** String - an old name of the object.
//       * OldFilesNames - Array - old names of files used while searching for old versions of the report or data processor.
//           ** String - an old name of the file.
//
Procedure ImportAdditionalReportsAndDataProcessorsFromMetadata(ReportsAndDataProcessors) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	MapConfigurationDataProcessorsWithCatalogDataProcessors(ReportsAndDataProcessors);
	If ReportsAndDataProcessors.Count() = 0 Then
		Return; // The update is not required.
	EndIf;
	
	ExportReportsAndDataProcessorsToFiles(ReportsAndDataProcessors);
	If ReportsAndDataProcessors.Count() = 0 Then
		Return; // Export failed.
	EndIf;
	
	RegisterReportsAndDataProcessors(ReportsAndDataProcessors);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.1";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.UpdateDataProcessorUserAccessSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "2.0.1.4";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.FillObjectNames";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.2";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.ReplaceMetadataObjectNamesWithReferences";
	
	If NOT Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.ExecuteInMandatoryGroup = True;
		Handler.SharedData                  = True;
		Handler.HandlerManagement      = False;
		Handler.ExclusiveMode             = True;
		Handler.Version    = "2.1.3.22";
		Handler.Procedure = "AdditionalReportsAndDataProcessors.EnableFunctionalOption";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.2.25";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.FillPermissionCompatibilityMode";
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(
		Total, "2.3.3.3", "Role.AdditionalReportsAndDataProcessorsUsage", "Role.ReadAdditionalReportsAndDataProcessors", Library);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave. 
Procedure OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender) Export
	
	OnGetAdditionalDataProcessor(DataItem, GetItem);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster. 
Procedure OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender) Export
	
	OnGetAdditionalDataProcessor(DataItem, GetItem);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	If Common.DataSeparationEnabled()
		Or Not AccessRight("Edit", Metadata.Catalogs.AdditionalReportsAndDataProcessors)
		Or Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled("AdditionalReportsAndDataProcessors") Then
		Return; // The to-do is disabled in the overridable module.
	EndIf;
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject("Catalog.AdditionalReportsAndDataProcessors");
	Else
		Sections = New Array;
		Sections.Add(Subsystem);
	EndIf;
	
	OutputUserTask = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "AdditionalReportsAndDataProcessors");
	If VersionChecked <> Undefined Then
		ArrayVersion  = StrSplit(Metadata.Version, ".", True);
		CurrentVersion = ArrayVersion[0] + ArrayVersion[1] + ArrayVersion[2];
		If VersionChecked = CurrentVersion Then
			OutputUserTask = False; // Additional reports and data processors were checked on the current version.
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	COUNT(DISTINCT AdditionalReportsAndDataProcessors.Ref) AS Count
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|WHERE
	|	AdditionalReportsAndDataProcessors.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
	|	AND AdditionalReportsAndDataProcessors.DeletionMark = FALSE
	|	AND AdditionalReportsAndDataProcessors.IsFolder = FALSE";
	Count = Query.Execute().Unload()[0].Count;
	
	For Each Section In Sections Do
		SectionID = "CheckCompatibilityWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = "AdditionalReportsAndDataProcessors";
		ToDoItem.HasToDoItems      = OutputUserTask AND Count > 0;
		ToDoItem.Presentation = NStr("ru = 'Дополнительные отчеты и обработки'; en = 'Additional reports and data processors'; pl = 'Dodatkowe raporty i opracowania';de = 'Zusätzliche Berichte und Datenverarbeiter';ro = 'Rapoarte și procesări suplimentare';tr = 'Ek raporlar ve veri işlemcileri'; es_ES = 'Informes adicionales y procesadores de datos'");
		ToDoItem.Count    = Count;
		ToDoItem.Form         = "Catalog.AdditionalReportsAndDataProcessors.Form.AdditionalReportsAndDataProcessorsCheck";
		ToDoItem.Owner      = SectionID;
		
		// Checking whether the to-do group exists. If a group is missing, add it.
		UserTaskGroup = ToDoList.Find(SectionID, "ID");
		If UserTaskGroup = Undefined Then
			UserTaskGroup = ToDoList.Add();
			UserTaskGroup.ID = SectionID;
			UserTaskGroup.HasToDoItems      = ToDoItem.HasToDoItems;
			UserTaskGroup.Presentation = NStr("ru = 'Проверить совместимость'; en = 'Check compatibility'; pl = 'Kontrola zgodności';de = 'Überprüfen Sie die Kompatibilität';ro = 'Verificați compatibilitatea';tr = 'Uygunluğu kontrol et'; es_ES = 'Revisar la compatibilidad'");
			If ToDoItem.HasToDoItems Then
				UserTaskGroup.Count = ToDoItem.Count;
			EndIf;
			UserTaskGroup.Owner = Section;
		Else
			If Not UserTaskGroup.HasToDoItems Then
				UserTaskGroup.HasToDoItems = ToDoItem.HasToDoItems;
			EndIf;
			
			If ToDoItem.HasToDoItems Then
				UserTaskGroup.Count = UserTaskGroup.Count + ToDoItem.Count;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds. 
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "AdditionalReportsAndDataProcessors";
	AccessKind.Presentation = NStr("ru = 'Дополнительные отчеты и обработки'; en = 'Additional reports and data processors'; pl = 'Dodatkowe raporty i opracowania';de = 'Zusätzliche Berichte und Datenverarbeiter';ro = 'Rapoarte și procesări suplimentare';tr = 'Ek raporlar ve veri işlemcileri'; es_ES = 'Informes adicionales y procesadores de datos'");
	AccessKind.ValuesType   = Type("CatalogRef.AdditionalReportsAndDataProcessors");
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.AdditionalReportsAndDataProcessors, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKindUsage. 
Procedure OnFillAccessKindUsage(AccessKind, Usage) Export
	
	SetPrivilegedMode(True);
	
	If AccessKind = "AdditionalReportsAndDataProcessors" Then
		Usage = Constants.UseAdditionalReportsAndDataProcessors.Get();
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionsKinds. 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(Details) Export
	
	If NOT Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	If ModuleAccessManagementInternal.AccessKindExists("AdditionalReportsAndDataProcessors") Then
		
		Details = Details + "
		|
		|Catalog.AdditionalReportsAndDataProcessors.Read.AdditionalReportsAndDataProcessors
		|";
	EndIf;
	
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadAdditionalReportsAndDataProcessors.Name);
	
EndProcedure

// See UsersOverridable.OnGetOtherSettings. 
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	// Gets additional report and data processor settings for a passed user.
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors")
		Or Not AccessRight("Update", Metadata.InformationRegisters.DataProcessorAccessUserSettings) Then
		Return;
	EndIf;
	
	// Settings string name to be displayed in the data processor settings tree.
	SettingName = NStr("ru = 'Настройки быстрого доступа к дополнительным отчетам и обработкам'; en = 'Settings for additional report and data processor quick access'; pl = 'Ustawienia szybkiego dostępu dla dodatkowych sprawozdań i przetwarzania danych';de = 'Einstellungen für den Schnellzugriff auf zusätzliche Berichte und Datenprozessoren';ro = 'Setările de acces rapid la rapoartele și procesările suplimentare și procesoare de date';tr = 'Ek raporlara ve veri işlemcilere hızlı erişim ayarları'; es_ES = 'Configuraciones del acceso rápido para los informes adicionales y los procesadores de datos'");
	
	// Settings string picture
	PictureSettings = "";
	
	// List of additional reports and data processors the user can quickly access.
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataProcessorAccessUserSettings.AdditionalReportOrDataProcessor AS Object,
	|	DataProcessorAccessUserSettings.CommandID AS ID,
	|	DataProcessorAccessUserSettings.User AS User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS DataProcessorAccessUserSettings
	|WHERE
	|	User = &User";
	
	Query.Parameters.Insert("User", UserInfo.UserRef);
	
	QueryResult = Query.Execute().Unload();
	
	QuickAccessSetting = New Structure;
	QuickAccessSetting.Insert("SettingName", SettingName);
	QuickAccessSetting.Insert("PictureSettings", PictureSettings);
	QuickAccessSetting.Insert("SettingsList",    QueryResult);
	
	Settings.Insert("QuickAccessSetting", QuickAccessSetting);
	
EndProcedure

// See UsersOverridable.OnSaveOtherSetings. 
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	// Saves additional report and data processor commands for the specified users.
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	If Settings.SettingID <> "QuickAccessSetting" Then
		Return;
	EndIf;
	
	For Each RowItem In Settings.SettingValue Do
		
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = RowItem.Value;
		Record.CommandID             = RowItem.Presentation;
		Record.User                     = UserInfo.UserRef;
		Record.Available                         = True;
		
		Record.Write(True);
		
	EndDo;
	
EndProcedure

// See UsersOverridable.OnDeleteOtherSettings. 
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	// Clears additional report and data processor commands for the specified user.
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	If Settings.SettingID <> "QuickAccessSetting" Then
		Return;
	EndIf;
	
	For Each RowItem In Settings.SettingValue Do
		
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = RowItem.Value;
		Record.CommandID             = RowItem.Presentation;
		Record.User                     = UserInfo.UserRef;
		
		Record.Read();
		
		Record.Delete();
		
	EndDo;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.AdditionalReportsAndDataProcessors.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds. 
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	If AttachableCommandsKinds.Find("ObjectsFilling", "Name") = Undefined Then
		Kind = AttachableCommandsKinds.Add();
		Kind.Name         = "ObjectsFilling";
		Kind.SubmenuName  = "FillSubmenu";
		Kind.Title   = NStr("ru = 'Заполнить'; en = 'Fill in'; pl = 'Wypełnij wg';de = 'Ausfüllen';ro = 'Completați';tr = 'Doldur'; es_ES = 'Rellenar'");
		Kind.Picture    = PictureLib.FillForm;
		Kind.Representation = ButtonRepresentation.Picture;
	EndIf;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject. 
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If Not AccessRight("Read", Metadata.InformationRegisters.AdditionalDataProcessorsPurposes) Then 
		Return;
	EndIf;
	
	If FormSettings.IsObjectForm Then
		FormType = AdditionalReportsAndDataProcessorsClientServer.ObjectFormType();
	Else
		FormType = AdditionalReportsAndDataProcessorsClientServer.ListFormType();
	EndIf;
	
	SetFOParameters = (Metadata.CommonCommands.Find("RelatedObjectsCreation") <> Undefined);
	If SetFOParameters Then
		FormSettings.FunctionalOptions.Insert("AdditionalReportsAndDataProcessorsRelatedObject", Catalogs.MetadataObjectIDs.EmptyRef());
		FormSettings.FunctionalOptions.Insert("AdditionalReportsAndDataProcessorsFormType",         FormType);
	EndIf;
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	MOIDs = New Array;
	QuickSearchByMOIDs = New Map;
	For Each Source In Sources.Rows Do
		For Each DocumentRecorder In Source.Rows Do
			MOIDs.Add(DocumentRecorder.MetadataRef);
			QuickSearchByMOIDs.Insert(DocumentRecorder.MetadataRef, DocumentRecorder);
		EndDo;
		MOIDs.Add(Source.MetadataRef);
		QuickSearchByMOIDs.Insert(Source.MetadataRef, Source);
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Purpose.RelatedObject,
	|	Purpose.UseObjectFilling AS UseObjectFilling,
	|	Purpose.UseReports AS UseReports,
	|	Purpose.UseRelatedObjectCreation AS UseRelatedObjectCreation
	|FROM
	|	InformationRegister.AdditionalDataProcessorsPurposes AS Purpose
	|WHERE
	|	Purpose.RelatedObject IN(&MOIDs)
	|	AND Purpose.FormType = &FormType";
	Query.SetParameter("MOIDs", MOIDs);
	If FormType = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND Purpose.FormType = &FormType", "");
	Else
		Query.SetParameter("FormType", FormType);
	EndIf;
	
	ObjectFillingTypes = New Array;
	ReportsTypes = New Array;
	RelatedObjectsCreationTypes = New Array;
	
	RegisterTable = Query.Execute().Unload();
	For Each TableRow In RegisterTable Do
		Source = QuickSearchByMOIDs[TableRow.RelatedObject];
		If Source = Undefined Then
			Continue;
		EndIf;
		If TableRow.UseObjectFilling Then
			AttachableCommands.SupplyTypesArray(ObjectFillingTypes, Source.DataRefType);
		EndIf;
		If TableRow.UseReports Then
			AttachableCommands.SupplyTypesArray(ReportsTypes, Source.DataRefType);
		EndIf;
		If TableRow.UseRelatedObjectCreation Then
			AttachableCommands.SupplyTypesArray(RelatedObjectsCreationTypes, Source.DataRefType);
		EndIf;
	EndDo;
	
	If ObjectFillingTypes.Count() > 0 Then
		Command = Commands.Add();
		If Common.SubsystemExists("StandardSubsystems.ObjectsFilling") Then
			Command.Kind           = "ObjectsFilling";
			Command.Presentation = NStr("ru = 'Дополнительные обработки заполнения...'; en = 'Object filling additional data processors...'; pl = 'Dodatkowe procedury wypełnienia...';de = 'Zusätzliche Verarbeitungen ausfüllen...';ro = 'Procesări suplimentare de completare...';tr = 'Doldurulmanın ek veri işlemcileri...'; es_ES = 'Procesamientos adicionales de relleno...'");
			Command.Importance      = "SeeAlso";
		Else
			Command.Kind           = "CommandBar";
			Command.Presentation = NStr("ru = 'Заполнение...'; en = 'Filling...'; pl = 'Wypełnienie';de = 'Füllung ...';ro = 'Completare...';tr = 'Dolgu...'; es_ES = 'Rellenar...'");
		EndIf;
		Command.ChangesSelectedObjects = True;
		Command.Order            = 50;
		Command.Handler         = "AdditionalReportsAndDataProcessorsClient.OpenCommandList";
		Command.WriteMode        = "Write";
		Command.MultipleChoice = True;
		Command.ParameterType       = New TypeDescription(ObjectFillingTypes);
		Command.AdditionalParameters = New Structure("Kind, IsReport", AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling(), False);
	ElsIf FormSettings.IsObjectForm Then
		OnDetermineFillingCommandsAttachedToObject(Commands, MOIDs, QuickSearchByMOIDs);
	EndIf;
	
	If ReportsTypes.Count() > 0 Then
		Command = Commands.Add();
		If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
			Command.Kind           = "Reports";
			Command.Importance      = "SeeAlso";
			Command.Presentation = NStr("ru = 'Дополнительные отчеты...'; en = 'Additional reports...'; pl = 'Sprawozdania dodatkowe...';de = 'Zusätzliche Berichte...';ro = 'Rapoarte suplimentare...';tr = 'Ek raporlar...'; es_ES = 'Informes adicionales...'");
		Else
			Command.Kind           = "CommandBar";
			Command.Presentation = NStr("ru = 'Отчеты...'; en = 'Reports...'; pl = 'Raporty…';de = 'Berichte ...';ro = 'Rapoarte...';tr = 'Raporlar ...'; es_ES = 'Informes...'");
		EndIf;
		Command.Order            = 50;
		Command.Handler         = "AdditionalReportsAndDataProcessorsClient.OpenCommandList";
		Command.WriteMode        = "Write";
		Command.MultipleChoice = True;
		Command.ParameterType       = New TypeDescription(ReportsTypes);
		Command.AdditionalParameters = New Structure("Kind, IsReport", AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport(), True);
	EndIf;
	
	If RelatedObjectsCreationTypes.Count() > 0 Then
		If SetFOParameters AND MOIDs.Count() = 1 Then
			FormSettings.FunctionalOptions.Insert("AdditionalReportsAndDataProcessorsRelatedObject", MOIDs[0]);
		Else
			Command = Commands.Add();
			Command.Kind                = ?(SetFOParameters, "CommandBar", "CreationBasedOn");
			Command.Presentation      = NStr("ru = 'Создание связанных объектов...'; en = 'Creating related objects...'; pl = 'Utworzenie powiązanych obiektów...';de = 'Verknüpfte Objekte erstellen ...';ro = 'Crearea obiectelor conexe...';tr = 'Bağlantılı nesneler oluşturuluyor ...'; es_ES = 'Creando objetos vinculados...'");
			Command.Picture           = PictureLib.InputOnBasis;
			Command.Order            = 50;
			Command.Handler         = "AdditionalReportsAndDataProcessorsClient.OpenCommandList";
			Command.WriteMode        = "Write";
			Command.MultipleChoice = True;
			Command.ParameterType       = New TypeDescription(RelatedObjectsCreationTypes);
			Command.AdditionalParameters = New Structure("Kind, IsReport", AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation(), False);
		EndIf;
	EndIf;
	
EndProcedure

// Adds the reports of the "Additional reports and data processors" subsystem whose object modules 
//   contain procedure DefineFormSettings().
//
// Parameters:
//   ReportsWithSettings - Array - references of the reports whose object modules contain procedure DefineFormSettings().
//
// Usage locations:
//   ReportsOptionsCached.Parameters().
//
Procedure OnDetermineReportsWithSettings(ReportsWithSettings) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If NOT AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	AdditionalReportsAndDataProcessors.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|WHERE
	|	AdditionalReportsAndDataProcessors.UseOptionStorage
	|	AND AdditionalReportsAndDataProcessors.DeepIntegrationWithReportForm
	|	AND NOT AdditionalReportsAndDataProcessors.DeletionMark
	|	AND AdditionalReportsAndDataProcessors.Kind IN(&ReportsKinds)";
	ReportsKinds = New Array;
	ReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	ReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	Query.SetParameter("ReportsKinds", ReportsKinds);
	
	SetPrivilegedMode(True);
	AdditionalReportsWithSettings = Query.Execute().Unload().UnloadColumn("Ref");
	For Each Ref In AdditionalReportsWithSettings Do
		If Not IsSuppliedDataProcessor(Ref) Then
			Continue;
		EndIf;
		ReportsWithSettings.Add(Ref);
	EndDo;
	
EndProcedure

// Gets an additional report reference, provided that the report is attached to the "Report options" subsystem storage.
//
// Parameters:
//   ReportInformation - Structure - see ReportsOptions.GenerateReportInformationByFullName(). 
//
Procedure OnDetermineTypeAndReferenceIfReportIsAuxiliary(ReportInformation) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	AdditionalReportsAndDataProcessors.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|WHERE
	|	AdditionalReportsAndDataProcessors.ObjectName = &ObjectName
	|	AND AdditionalReportsAndDataProcessors.DeletionMark = FALSE
	|	AND AdditionalReportsAndDataProcessors.UseOptionStorage = TRUE
	|	AND AdditionalReportsAndDataProcessors.Kind IN (&KindAdditionalReport, &ReportKind)
	|	AND AdditionalReportsAndDataProcessors.Publication = &PublicationAvailable";
	If ReportInformation.ByDefaultAllConnectedToStorage Then
		Query.Text = StrReplace(Query.Text, "AND AdditionalReportsAndDataProcessors.UseOptionStorage = TRUE", "");
	EndIf;
	Query.SetParameter("ObjectName", ReportInformation.ReportName);
	Query.SetParameter("ReportKind",               Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	Query.SetParameter("KindAdditionalReport", Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	Query.SetParameter("PublicationAvailable", Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used);
	
	// Required to ensure integrity of the data being generted. Access rights will be applied during the data usage phase.
	RefsArray = Query.Execute().Unload().UnloadColumn("Ref");
	For Each Ref In RefsArray Do
		If Not IsSuppliedDataProcessor(Ref) Then
			Continue;
		EndIf;
		ReportInformation.Report = Ref;
	EndDo;
	
EndProcedure

// Supplements the array with references to additional reports the current user can access.
//
// Parameters:
//   Result - Array of <see Catalogs.ReportsOptions.Attributes.Report> -
//       references to the reports the current user can access.
//
// Usage locations:
//   ReportsOptions.CurrentUserReports().
//
Procedure OnAddAdditionalReportsAvailableForCurrentUser(AvailableReports) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	AdditionalReportsAndDataProcessors.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|WHERE
	|	AdditionalReportsAndDataProcessors.UseOptionStorage
	|	AND AdditionalReportsAndDataProcessors.Kind IN (&KindAdditionalReport, &ReportKind)
	|	AND NOT AdditionalReportsAndDataProcessors.Ref IN (&AvailableReports)";
	
	Query.SetParameter("AvailableReports", AvailableReports);
	Query.SetParameter("ReportKind",               Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	Query.SetParameter("KindAdditionalReport", Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not IsSuppliedDataProcessor(Selection.Ref) Then
			Continue;
		EndIf;
		AvailableReports.Add(Selection.Ref);
	EndDo;
	
EndProcedure

// Supplements the array with references to additional reports the current user can access.
//
// Parameters:
//   Result - Array - full report names available to the specified user.
//
// Usage locations:
//   DataProcessor.UsersSettings.ReportsAvailableToUser().
//
Procedure OnAddAdditionalReportsAvailableToSpecifiedUser(AvailableReports, InfobaseUser, UserRef) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors, InfobaseUser) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref AS Ref,
	|	AdditionalReportsAndDataProcessors.ObjectName AS ObjectName
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|		INNER JOIN InformationRegister.DataProcessorAccessUserSettings AS AccessSettings
	|		ON (AccessSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref)
	|			AND (AccessSettings.Available = TRUE)
	|			AND (AccessSettings.User = &User)
	|			AND (AdditionalReportsAndDataProcessors.Kind IN (&KindAdditionalReport, &ReportKind))";
	
	Query.SetParameter("User",           UserRef);
	Query.SetParameter("ReportKind",               Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	Query.SetParameter("KindAdditionalReport", Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not IsSuppliedDataProcessor(Selection.Ref) Then
			Continue;
		EndIf;
		FullReportName = "ExternalReport." + Selection.ObjectName;
		AvailableReports.Add(FullReportName);
	EndDo;
	
EndProcedure

// Attaches a report from the "Additional reports and data processors" subsystem.
// Exception handling is performed by the control code.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report to initialize.
//   ReportParameters - Structure - a set of parameters got while checking and attaching a report.
//       See ReportDistribution.InitializeReport(). 
//   Result - Boolean, Undefined - an attachment result.
//       True - an additional report is attached.
//       False - failed to attach an additional report.
//
// Usage locations:
//   ReportsOptions.AttachReportObject().
//   ReportDistribution.InitializeReport().
//
Procedure OnAttachAdditionalReport(Ref, ReportParameters, Result, GetMetadata) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		ReportParameters.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Элемент ""%1"" не подключен, потому что ""Дополнительные отчеты и обработки"" отключены в настройках программы.'; en = 'Cannot attach %1. Additional reports and data processors are disabled in program settings.'; pl = 'Element ""%1"" nie jest podłączony, ponieważ ""Dodatkowe raporty i przetwarzanie"" są wyłączone w ustawieniach programu.';de = 'Das Element ""%1"" ist nicht verbunden, da ""Zusätzliche Berichte und Bearbeitung"" in den Programmeinstellungen deaktiviert ist.';ro = 'Elementul ""%1"" nu este conectat, deoarece ""Rapoartele și procesările suplimentare"" sunt dezactivate în setările programului.';tr = '""%1""Öğesi bağlı değil çünkü"" ek raporlar ve işlemler "" program ayarlarında devre dışı bırakıldı.'; es_ES = 'El elemento ""%1"" no está conectado porque ""Procesamientos e informes adicionales"" están desactivados en los ajustes del programa.'"),
			"'" + String(Ref) + "'");
		Return;
	EndIf;
	
	Kind = Common.ObjectAttributeValue(Ref, "Kind");
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		OR Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		Try
			ReportParameters.Name = AttachExternalDataProcessor(Ref);
			ReportParameters.Object = ExternalReports.Create(ReportParameters.Name);
			If GetMetadata Then
				ReportParameters.Metadata = ReportParameters.Object.Metadata();
			EndIf;
			Result = True;
		Except
			ReportParameters.ErrorText = 
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'При подключении дополнительного отчета ""%1"" возникла ошибка:'; en = 'An error occurred while attaching additional report ""%1"":'; pl = 'Wystąpił błąd podczas łączenia dodatkowego sprawozdania ""%1"":';de = 'Beim Verbinden des zusätzlichen Berichts ""%1"" ist ein Fehler aufgetreten:';ro = 'Eroare la conectarea raportului suplimentar ""%1"":';tr = '""%1"" ek rapor bağlanırken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al conectar el informe adicional ""%1"":'"), String(Ref))
				+ Chars.LF + DetailErrorDescription(ErrorInfo());
			Result = False;
		EndTry;
		
	Else
		
		ReportParameters.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Элемент %1 не является дополнительным отчетом'; en = '%1 is not an additional report.'; pl = 'Element %1nie jest dodatkowym sprawozdaniem';de = 'Artikel %1 ist kein zusätzlicher Bericht';ro = 'Punctul %1 nu este un raport suplimentar';tr = 'Öğe %1 ek bir rapor değildir'; es_ES = 'Artículo %1 no es un informe adicional'"),
			"'"+ String(Ref) +"'");
		
		Result = False;
		
	EndIf;
	
EndProcedure

// Attaches a report from the "Additional reports and data processors" subsystem.
//   Exception handling is performed by the control code.
//
// Parameters:
//   Context - Structure - a set of parameters got while checking and attaching a report.
//       See ReportsOptions.OnAttachReport(). 
//
// Usage locations:
//   ReportsOptions.OnAttachReport().
//
Procedure OnAttachReport(Context) Export
	Ref = CommonClientServer.StructureProperty(Context, "Report");
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В процедуру ""%1"" не передан отчет'; en = 'The ""%1"" procedure did not get a report'; pl = 'Do procedury ""%1"" nie przekazano sprawozdania';de = 'Es wurde kein Bericht an die Prozedur ""%1"" gesendet';ro = 'În procedura ""%1"" nu este transmis raportul';tr = '""%1"" prosedürüne rapor verilmedi'; es_ES = 'No se ha enviado el informe al procedimiento ""%1""'"),
			"AdditionalReportsAndDataProcessors.OnAttachReport");
	EndIf;
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Raise NStr("ru = '""Дополнительные отчеты и обработки"" отключена в настройках программы.'; en = 'The Additional reports and data processors feature is disabled in program settings.'; pl = '""Dodatkowe raporty i przetwarzanie"" są wyłączone w ustawieniach programu.';de = '""Zusätzliche Berichte und Bearbeitungen"" ist in den Programmeinstellungen deaktiviert.';ro = '""Rapoarte și procesări suplimentare"" este dezactivată în setările programului.';tr = '""Ek raporlar ve işlemler"" program ayarlarında devre dışı bırakılır.'; es_ES = '""Procesamientos e informes adicionales"" está desactivada en los ajustes del programa.'");
	EndIf;
	
	Kind = Common.ObjectAttributeValue(Ref, "Kind");
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		Context.ReportName = AttachExternalDataProcessor(Ref);
		Context.Connected = True;
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Объект ""%1"" не является дополнительным отчетом'; en = '%1 is not an additional report.'; pl = 'Obiekt ""%1"" nie jest sprawozdaniem dodatkowym';de = 'Das Objekt ""%1"" ist kein zusätzlicher Bericht';ro = 'Obiectul ""%1"" nu este un raport suplimentar';tr = 'Öğe %1 ek bir rapor değildir'; es_ES = 'El objeto ""%1"" no es un informe adicional'"), String(Ref));
	EndIf;
	
EndProcedure

Procedure OnDetermineReportsAvailability(AddlReportsRefs, Result) Export
	SubsystemEnabled = True;
	HasReadRight = True;
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		SubsystemEnabled = False;
	ElsIf Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		HasReadRight = False;
	EndIf;
	
	For Each Report In AddlReportsRefs Do
		FoundItems = Result.FindRows(New Structure("Report", Report));
		For Each TableRow In FoundItems Do
			If Not SubsystemEnabled Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Отчет ""%1"" недоступен, т.к. дополнительные отчеты и обработки отключены в настройках программы.'; en = '<Report ""%1"" is unavailable as additional reports and data processors are disabled in the application settings.'; pl = '<Sprawozdanie ""%1"" jest niedostępne, ponieważ sprawozdania dodatkowe i przetwarzania są odłączone w ustawieniach programu.';de = '<Bericht ""%1"" ist nicht verfügbar, da zusätzliche Berichte und Verarbeitungen in den Programmeinstellungen deaktiviert sind.';ro = '<Raportul ""%1"" este inaccesibil, deoarece rapoartele și procesările suplimentare sunt dezactivate în setările programului.';tr = '< Rapor ""%1"" kullanılamaz, çünkü ek raporlar ve işlemler program ayarlarında devre dışı bırakıldı.'; es_ES = '<El informe ""%1"" no está disponible porque los informes adicionales y los procesamientos están desactivados en los ajustes del programa.'"),
					TableRow.Presentation);
			ElsIf Not HasReadRight Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Отчет ""%1"" недоступен, т.к. отсутствует право чтения дополнительных отчетов и обработок.'; en = '<Report ""%1"" is unavailable as you do not have the rights to read additional reports and processors.'; pl = '<Sprawozdanie ""%1"" jest niedostępne, ponieważ brak uprawnień do odczytu dodatkowych sprawozdań i przetwarzań.';de = '<Bericht ""%1"" ist nicht verfügbar, da es kein Recht gibt, zusätzliche Berichte und Verarbeitungen zu lesen.';ro = '<Raportul ""%1"" este inaccesibil, deoarece lipsește dreptul de citire a rapoartelor și procesărilor suplimentare.';tr = '< Rapor ""%1"" kullanılamaz, çünkü ek raporlar ve işlemler okunamıyor.'; es_ES = '<El informe ""%1"" no está disponible porque no hay derecho de leer los informes adicionales y los procesamientos.'"),
					TableRow.Presentation);
			ElsIf Not IsSuppliedDataProcessor(Report) Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Отчет ""%1"" недоступен в модели сервиса.'; en = '<Report ""%1"" is unavailable in SaaS mode.'; pl = '<Raport ""%1"" jest niedostępny w trybie SaaS.';de = '<Bericht ""%1"" ist im SaaS-Modus nicht verfügbar.';ro = '<Report> ""%1"" nu este disponibil în modul SaaS.';tr = '<Rapor ""%1"", SaaS modunda kullanılamıyor.'; es_ES = '<Informe ""%1"" no está disponible en el modo SaaS.'"),
					TableRow.Presentation);
			Else
				TableRow.Available = True;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// Adds external print forms to the print command list.
//
// Parameters:
//   PrintCommands - ValueTable - see PrintManager.CreatePrintCommandsCollection(). 
//   ObjectName    - String          - a full name of the metadata object to obtain the list of 
//                                     print commands for.
//
// Usage locations:
//   PrintManager.FormPrintCommands().
//
Procedure OnReceivePrintCommands(PrintCommands, ObjectName) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;

	Query = NewQueryByAvailableCommands(Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm, ObjectName);
	CommandsTable = Query.Execute().Unload();
	
	If CommandsTable.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow In CommandsTable Do
		If Not IsSuppliedDataProcessor(TableRow.Ref) Then
			Continue;
		EndIf;
		PrintCommand = PrintCommands.Add();
		
		// Mandatory parameters.
		FillPropertyValues(PrintCommand, TableRow, "ID, Presentation");
		// Parameters used as subsystem IDs.
		PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors";
		
		// Additional parameters.
		PrintCommand.AdditionalParameters = New Structure("Ref, Modifier, StartupOption, ShowNotification");
		FillPropertyValues(PrintCommand.AdditionalParameters, TableRow);
	EndDo;
	
EndProcedure

// Fills a list of print forms from external sources.
//
// Parameters:
//   ExternalPrintForms - ValueList - print forms.
//       Value      - String - a print form ID.
//       Presentation - String - a print form name.
//   FullMetadataObjectName - String - a full name of the metadata object to obtain the list of 
//       print forms for.
//
// Usage locations:
//   PrintManager.OnReceiveExternalPrintFormList().
//
Procedure OnReceiveExternalPrintFormList(ExternalPrintForms, FullMetadataObjectName) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If NOT AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Query = NewQueryByAvailableCommands(Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm, FullMetadataObjectName);
	CommandsTable = Query.Execute().Unload();
	
	For Each Command In CommandsTable Do
		If Not IsSuppliedDataProcessor(Command.Ref) Then
			Continue;
		EndIf;
		If StrFind(Command.ID, ",") = 0 Then // Ignoring sets.
			ExternalPrintForms.Add(Command.ID, Command.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

// Returns a reference to an external print form object.
//
// Usage locations:
//   PrintManager.OnReceiveExternalPrintForm().
//
Procedure OnReceiveExternalPrintForm(ID, FullMetadataObjectName, ExternalPrintFormRef) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If NOT AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Query = NewQueryByAvailableCommands(Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm, FullMetadataObjectName);
	
	CommandsTable = Query.Execute().Unload();
	
	Command = CommandsTable.Find(ID, "ID");
	If Command <> Undefined Then 
		ExternalPrintFormRef = Command.Ref;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// [1.0.7.1] Procedure used to update the records on additional data processor availability.
Procedure UpdateDataProcessorUserAccessSettings() Export
	
	UsersWithAddlDataProcessors = UsersWithAccessToAdditionalDataProcessors();
	
	QueryText =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref AS DataProcessor,
	|	AdditionalReportsAndDataProcessorsCommands.ID AS ID
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
	|		ON (AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref)";
	
	Query = New Query;
	Query.Text = QueryText;
	DataProcessorsWithCommands = Query.Execute().Unload();
	
	RecordsTable = New ValueTable;
	RecordsTable.Columns.Add("DataProcessor",     New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"));
	RecordsTable.Columns.Add("ID", New TypeDescription("String"));
	RecordsTable.Columns.Add("User",  New TypeDescription("CatalogRef.Users"));
	RecordsTable.Columns.Add("Available",      New TypeDescription("Boolean"));
	
	For Each DataProcessorCommand In DataProcessorsWithCommands Do
		For Each User In UsersWithAddlDataProcessors Do
			NewRow = RecordsTable.Add();
			NewRow.DataProcessor     = DataProcessorCommand.DataProcessor;
			NewRow.ID = DataProcessorCommand.ID;
			NewRow.User  = User;
			NewRow.Available   = True;
		EndDo;
	EndDo;
	
	QueryText =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref AS DataProcessor,
	|	AdditionalReportsAndDataProcessorsCommands.ID AS ID,
	|	Users.Ref AS User,
	|	DataProcessorAccessUserSettings.Available AS Available
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
	|		ON (AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref)
	|		INNER JOIN InformationRegister.DataProcessorAccessUserSettings AS DataProcessorAccessUserSettings
	|		ON (DataProcessorAccessUserSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref)
	|			AND (DataProcessorAccessUserSettings.CommandID = AdditionalReportsAndDataProcessorsCommands.ID)
	|		INNER JOIN Catalog.Users AS Users
	|		ON (Users.Ref = DataProcessorAccessUserSettings.User)";
	
	Query = New Query;
	Query.Text = QueryText;
	PersonalAccessExceptions = Query.Execute().Unload();
	
	RowsSearch = New Structure("DataProcessor, ID, User");
	For Each PersonalAccessException In PersonalAccessExceptions Do
		FillPropertyValues(RowsSearch, PersonalAccessException);
		FoundItems = RecordsTable.FindRows(RowsSearch);
		For Each TableRow In FoundItems Do
			TableRow.Available = NOT PersonalAccessException.Available; // Inverting with access exception.
		EndDo; 
	EndDo;
	
	For Each User In UsersWithAddlDataProcessors Do
		RecordSet = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordSet();
		RecordSet.Filter.User.Set(User);
		QuickAccessRecords = RecordsTable.FindRows(New Structure("User,Available", User, True));
		For Each QuickAccessRecord In QuickAccessRecords Do
			NewRecord = RecordSet.Add();
			NewRecord.AdditionalReportOrDataProcessor = QuickAccessRecord.DataProcessor;
			NewRecord.CommandID			= QuickAccessRecord.ID;
			NewRecord.User					= User;
			NewRecord.Available						= True;
		EndDo;
		InfobaseUpdate.WriteData(RecordSet);
	EndDo;
	
EndProcedure

// [2.0.1.4] Filling the ObjectName attribute (name used to register the object in the application).
//   For objects with the "Available" publication option, additional check for Object name 
//   uniqueness is performed. If reports (data processors) with non-unique Object names for all 
//   items except the first one are found, Publication option is changed from "Available" to "Debug 
//   mode".
//
Procedure FillObjectNames() Export
	QueryText =
	"SELECT
	|	AdditionalReports.Ref,
	|	AdditionalReports.ObjectName,
	|	AdditionalReports.DataProcessorStorage,
	|	CASE
	|		WHEN AdditionalReports.Kind IN (&AddlReportsKinds)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsReport,
	|	CASE
	|		WHEN AdditionalReports.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS InPublication,
	|	CASE
	|		WHEN AdditionalReports.ObjectName = """"
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FillObjectNameRequired
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReports
	|WHERE
	|	AdditionalReports.IsFolder = FALSE
	|	AND NOT AdditionalReports.DataProcessorStorage IS NULL ";
	
	AddlReportsKinds = New Array;
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	
	Query = New Query;
	Query.SetParameter("AddlReportsKinds", AddlReportsKinds);
	Query.Text = QueryText;
	
	AllAddlReports = Query.Execute().Unload();
	
	SearchForDuplicates = New Structure("ObjectName, IsReport, InPublication");
	SearchForDuplicates.InPublication = True;
	
	// Additional reports and data processors that require filling the object name.
	AddlReportsToFill = AllAddlReports.FindRows(New Structure("FillObjectNameRequired", True));
	For Each TableRow In AddlReportsToFill Do
		
		// Storing the report's or data processor's binary data to a temporary storage.
		AddressInTempStorage = PutToTempStorage(TableRow.DataProcessorStorage.Get());
		
		// Defining the manager
		Manager = ?(TableRow.IsReport, ExternalReports, ExternalDataProcessors);
		
		// Getting an object instance.
		Object = TableRow.Ref.GetObject();
		
		// Setting object name
		Object.ObjectName = TrimAll(Manager.Connect(AddressInTempStorage, , True,
			Common.ProtectionWithoutWarningsDetails()));
		
		// If a report or data processor name is already used by another published report or data processor, 
		// the current object is a duplicate. It is necessary to set its publication option to "Debug mode" (or disable it).
		If TableRow.InPublication Then
			SearchForDuplicates.ObjectName = Object.ObjectName;
			SearchForDuplicates.IsReport   = TableRow.IsReport;
			If AllAddlReports.FindRows(SearchForDuplicates).Count() > 0 Then
				DisableConflictingDataProcessor(Object);
			EndIf;
		EndIf;
		
		// Recording the used object name in the duplicate control table.
		TableRow.ObjectName = Object.ObjectName;
		
		// Writing object
		InfobaseUpdate.WriteData(Object);
		
	EndDo;
	
EndProcedure

// [2.1.3.2] Replacing names of related objects with references from the MetadataObjectsIDs catalog.
Procedure ReplaceMetadataObjectNamesWithReferences() Export
	
	QueryText =
	"SELECT
	|	AssignmentTable.Ref AS CatalogRef,
	|	AssignmentTable.LineNumber AS LineNumber,
	|	CatalogMOID.Ref AS RelatedObject
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS AssignmentTable
	|		LEFT JOIN Catalog.MetadataObjectIDs AS CatalogMOID
	|		ON AssignmentTable.DeleteMetadataObjectFullName = CatalogMOID.FullName
	|TOTALS BY
	|	CatalogRef";
	
	Query = New Query;
	Query.Text = QueryText;
	
	ReferencesSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	While ReferencesSelection.Next() Do
		CatalogObject = ReferencesSelection.CatalogRef.GetObject();
		ArrayOfRowsToDelete = New Array;
		RowsSelection = ReferencesSelection.Select();
		While RowsSelection.Next() Do
			TabularSectionRow = CatalogObject.Purpose.Get(RowsSelection.LineNumber - 1);
			TabularSectionRow.RelatedObject = RowsSelection.RelatedObject;
			If ValueIsFilled(TabularSectionRow.RelatedObject) Then
				TabularSectionRow.DeleteMetadataObjectFullName = "";
			Else
				ArrayOfRowsToDelete.Add(TabularSectionRow);
			EndIf;
		EndDo;
		For Each TabularSectionRow In ArrayOfRowsToDelete Do
			CatalogObject.Purpose.Delete(TabularSectionRow);
		EndDo;
		InfobaseUpdate.WriteData(CatalogObject);
	EndDo;
	
	InformationRegisters.AdditionalDataProcessorsPurposes.Refresh(True);
	
EndProcedure

// [2.1.3.22] Enabling functional option UseAdditionalReportsAndDataProcessors for local mode.
Procedure EnableFunctionalOption() Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Constants.UseAdditionalReportsAndDataProcessors.Set(True);
	
EndProcedure

// [2.2.2.25] Filling attribute PermissionsCompatibilityMode for catalog AdditionalReportsAndDataProcessors.
Procedure FillPermissionCompatibilityMode() Export
	
	BeginTransaction();
	
	Try
		
		Lock = New DataLock();
		Lock.Add("Catalog.AdditionalReportsAndDataProcessors");
		Lock.Lock();
		
		Selection = Catalogs.AdditionalReportsAndDataProcessors.Select();
		While Selection.Next() Do
			
			If Not Selection.IsFolder AND Not ValueIsFilled(Selection.PermissionsCompatibilityMode) Then
				
				LockDataForEdit(Selection.Ref);
				
				Object = Selection.GetObject();
				
				Try
					
					DataProcessorObject = ExternalDataProcessorObject(Selection.Ref);
					RegistrationData = DataProcessorObject.ExternalDataProcessorInfo();
					
					If RegistrationData.Property("SSLVersion") Then
						If CommonClientServer.CompareVersions(RegistrationData.SSLVersion, "2.2.2.0") > 0 Then
							CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2;
						Else
							CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
						EndIf;
					Else
						CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
					EndIf;
					
					Publication = Object.Publication;
					
				Except
					
					// If it is impossible to attach the data processor, switching to permission compatibility with SSL 
					// 2.1.3 and enabling a temporary lock.
					ErrorText = """" + Object.Description + """:"
						+ Chars.LF + NStr("ru = 'Не удалось определить режим совместимости разрешений по причине:'; en = 'Cannot identify permissions compatibility mode. Reason:'; pl = 'Nie udało się określić tryb kompatybilności zezwoleń z powodu:';de = 'Der Kompatibilitätsmodus der Berechtigungen konnte aus folgendem Grund nicht ermittelt werden:';ro = 'Eșec la determinarea regimului de compatibilitate a permisiunilor din motivul:';tr = 'Aşağıdaki nedenle izin uyumluluk modu belirlenemedi:'; es_ES = 'No se ha podido determinar el modo de compatibilidad de extensiones a causa de:'")
						+ Chars.LF + DetailErrorDescription(ErrorInfo())
						+ Chars.LF
						+ Chars.LF + NStr("ru = 'Объект заблокирован в режиме совместимости с версией 2.1.3.'; en = 'The object is locked in compatibility mode with version 2.1.3.'; pl = 'Obiekt jest zablokowany w trybie kompatybilności z wersją 2.1.3.';de = 'Das Objekt wird im Kompatibilitätsmodus mit der Version 2.1.3 gesperrt.';ro = 'Obiectul este blocat în regimul de compatibilitate cu versiunea 2.1.3.';tr = 'Nesne sürüm 2.1.3 ile uyumluluk modunda kilitlendi.'; es_ES = 'El objeto está bloqueado en el modo de compatibilidad con la versión 2.1.3.'");
					WriteWarning(Object.Ref, ErrorText);
					CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
					Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled;
					
				EndTry;
				
				Object.PermissionsCompatibilityMode = CompatibilityMode;
				Object.Publication = Publication;
				InfobaseUpdate.WriteData(Object);
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled jobs

// StartingDataProcessors scheduled job instance handler.
//   Starts a global data processor handler for the scheduled job using the specified command ID.
//   
//
// Parameters:
//   ExternalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors - a reference to the data processor being executed.
//   CommandID - String - an ID of the command being executed.
//
Procedure ExecuteDataProcessorByScheduledJob(ExternalDataProcessor, CommandID) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.StartingAdditionalDataProcessors);
	
	// Event log record
	WriteInformation(ExternalDataProcessor, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Команда %1: Запуск.'; en = 'Command %1: Start.'; pl = 'Polecenie %1: Start.';de = 'Befehl %1: Start.';ro = '%1 comanda: Start.';tr = 'Komut%1: Başlat.'; es_ES = 'Comando %1: Iniciar.'"), CommandID));
	
	// Executing the command
	Try
		ExecuteCommand(New Structure("AdditionalDataProcessorRef, CommandID", ExternalDataProcessor, CommandID), Undefined);
	Except
		WriteError(
			ExternalDataProcessor,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Команда %1: Ошибка выполнения:
				|%2'; 
				|en = 'Command %1: Execution error:
				|%2'; 
				|pl = 'Polecenie %1: Błąd wykonania:
				|%2';
				|de = 'Befehl %1: Ausführungsfehler:
				|%2';
				|ro = 'Comanda %1: Eroare de executare:
				| %2';
				|tr = 'Komut%1: yürütme hatası:
				|%2'; 
				|es_ES = 'Comando %1: Error de ejecutar:
				|%2'"),
				CommandID, DetailErrorDescription(ErrorInfo())));
	EndTry;
	
	// Event log record
	WriteInformation(ExternalDataProcessor, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Команда %1: Завершение.'; en = 'Command %1: Complete.'; pl = 'Polecenie %1: Zakończ.';de = 'Befehl %1: Ende.';ro = 'Comanda %1: Sfârșit.';tr = 'Komut %1: Son.'; es_ES = 'Comando %1: Final.'"), CommandID));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Returns True when the specified additional report (data processor) kind is global.
//
// Parameters:
//   Kind - EnumRef.AdditionalReportsAndDataProcessorsKinds - a kind of an external data processor.
//
// Returns:
//    True - a data processor is global.
//    False - a data processor is assignable.
//
Function CheckGlobalDataProcessor(Kind) Export
	
	Return Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport;
	
EndFunction

// Transforms an additional report (data processor) kind from a string constant to an enumeration reference.
//
// Parameters:
//   StringPresentation - String - a string presentation of the kind.
//
// Returns:
//   EnumRef.AdditionalReportsAndDataProcessorsKinds - a reference of the kind.
//
Function GetDataProcessorKindByKindStringPresentation(StringPresentation) Export
	
	If StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.Report;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindMessageTemplate() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.MessageTemplate;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport() Then
		Return Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport;
	EndIf;
	
EndFunction

// Transforms an additional report (data processor) kind from an enumeration reference to a string constant.
Function KindToString(KindRef) Export
	
	If KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.MessageTemplate Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindMessageTemplate();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
		
	ElsIf KindRef = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport();
		
	Else
		Return "";
	EndIf;
	
EndFunction

// Returns a command workstation name.
Function SectionPresentation(Section) Export
	If Section = AdditionalReportsAndDataProcessorsClientServer.StartPageName()
		Or Section = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return NStr("ru = 'Начальная страница'; en = 'Home page'; pl = 'Strona podstawowa';de = 'Startseite';ro = 'Pagina principală';tr = 'Ana sayfa'; es_ES = 'Página principal'");
	EndIf;
	Return MetadataObjectPresentation(Section);
EndFunction

// Returns a command workstation name.
Function MetadataObjectPresentation(Object) Export
	If TypeOf(Object) = Type("CatalogRef.MetadataObjectIDs") Then
		MetadataObject = Common.MetadataObjectByID(Object, False);
		If TypeOf(MetadataObject) <> Type("MetadataObject") Then
			Return NStr("ru = '<Не существует>'; en = '<does not exist>'; pl = '<Nie istnieje>';de = '<Existiert nicht>';ro = '<Nu există>';tr = '< Mevcut değil>'; es_ES = '<No existe>'");
		EndIf;
	ElsIf TypeOf(Object) = Type("MetadataObject") Then
		MetadataObject = Object;
	Else
		MetadataObject = Metadata.Subsystems.Find(Object);
	EndIf;
	Return MetadataObject.Presentation();
EndFunction

// Verifies the right to add additional reports and data processors.
Function InsertRight(Val AdditionalDataProcessor = Undefined) Export
	
	Result = False;
	StandardProcessing = True;
	
	SaaSIntegration.OnCheckInsertRight(AdditionalDataProcessor, Result, StandardProcessing);
	
	If StandardProcessing Then
		
		If Common.DataSeparationEnabled()
		   AND Common.SeparatedDataUsageAvailable() Then
			
			Result = Users.IsFullUser(, True);
		Else
			Result = AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether an additional report or data processor can be exported to a file.
//
// Parameters:
//   DataProcessor - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean
//
Function CanExportDataProcessorToFile(Val DataProcessor) Export
	
	Result = False;
	StandardProcessing = True;
	
	SaaSIntegration.OnCheckCanExportDataProcessorToFile(DataProcessor, Result, StandardProcessing);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
		
	Return True;
	
EndFunction

// Checks whether an additional data processor already existing in the infobase can be imported from a file.
//
// Parameters:
//   DataProcessor - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean
//
Function CanImportDataProcessorFromFile(Val DataProcessor) Export
	
	Result = False;
	StandardProcessing = True;
	SaaSIntegration.OnCheckCanImportDataProcessorFromFile(DataProcessor, Result, StandardProcessing);
		
	If Not StandardProcessing Then
		Return Result;
	EndIf;
		
	Return True;
	
EndFunction

// Returns a flag specifying whether extended information on an additional report or a data processor must be displayed to the user.
//
// Parameters:
//   DataProcessor - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean
//
Function DisplayExtendedInformation(Val DataProcessor) Export
	
	Return True;
	
EndFunction

// Publication kinds unavailable for use in the current application mode.
Function NotAvailablePublicationKinds() Export
	
	Result = New Array;
	SaaSIntegration.OnFillUnavailablePublicationKinds(Result);
	Return Result;
	
EndFunction

Function IsSuppliedDataProcessor(Ref)
	
	If Common.DataSeparationEnabled() 
		AND Common.SubsystemExists("SaaSTechnology.SaaS.AdditionalReportsAndDataProcessorsSaaS") Then
		
		ModuleAdditionalReportsAndDataProcessorsSaaS = Common.CommonModule("AdditionalReportsAndDataProcessorsSaaS");
		Return ModuleAdditionalReportsAndDataProcessorsSaaS.IsSuppliedDataProcessor(Ref);
		
	EndIf;
	Return True; // including local operation mode
	
EndFunction	
	
// The function is called on generating a new query used to get a command table for additional reports or data processors.
// Writing an error to the event log dedicated to the additional report (data processor).
Procedure WriteError(Ref, MessageText) Export
	WriteToLog(EventLogLevel.Error, Ref, MessageText);
EndProcedure

// Writing a warning to the event log dedicated to the additional report (data processor).
Procedure WriteWarning(Ref, MessageText)
	WriteToLog(EventLogLevel.Warning, Ref, MessageText);
EndProcedure

// Writing information to the event log dedicated to the additional report (data processor).
Procedure WriteInformation(Ref, MessageText)
	WriteToLog(EventLogLevel.Information, Ref, MessageText);
EndProcedure

// Writing a comment to the event log dedicated to the additional report (data processor).
Procedure WriteComment(Ref, MessageText)
	WriteToLog(EventLogLevel.Note, Ref, MessageText);
EndProcedure

// Writing an event to the event log dedicated to the additional report (data processor).
Procedure WriteToLog(Level, Ref, Text)
	WriteLogEvent(SubsystemDescription(), Level, Metadata.Catalogs.AdditionalReportsAndDataProcessors,
		Ref, Text);
EndProcedure

// Generates a subsystem description to write an event to the event log.
//
Function SubsystemDescription()
	Return NStr("ru = 'Дополнительные отчеты и обработки'; en = 'Additional reports and data processors'; pl = 'Dodatkowe sprawozdania i przetwarzanie danych';de = 'Zusätzliche Berichte und Datenverarbeiter';ro = 'Rapoarte și procesări suplimentare';tr = 'İlave raporlar ve veri işlemcileri'; es_ES = 'Informes adicionales y procesadores de datos'", Common.DefaultLanguageCode());
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions.

// For internal use.
Function UsersWithAccessToAdditionalDataProcessors()
	
	Result = New Array;
	
	RolesToCheck = "ReadAdditionalReportsAndDataProcessors, AddEditAdditionalReportsAndDataProcessors";
	
	Query = New Query("SELECT Ref FROM Catalog.Users");
	AllUsers = Query.Execute().Unload().UnloadColumn("Ref");
	
	For Each User In AllUsers Do
		If Users.RolesAvailable(RolesToCheck, User, False) Then
			Result.Add(User);
		EndIf;
	EndDo;
	
	QueryText =
	"SELECT DISTINCT
	|	AccessSettings.User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS AccessSettings
	|WHERE
	|	NOT AccessSettings.User IN (&UsersAddedEarlier)";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("UsersAddedEarlier", Result);
	UsersInRegister = Query.Execute().Unload().UnloadColumn("User");
	
	For Each User In UsersInRegister Do
		Result.Add(User);
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use.
Procedure ExecuteAdditionalReportOrDataProcessorCommand(ExternalObject, Val CommandID, CommandParameters, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters);
		
	Else
		
		If CommandParameters = Undefined Then
			
			ExternalObject.ExecuteCommand(CommandID);
			
		Else
			
			ExternalObject.ExecuteCommand(CommandID, CommandParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use.
Procedure ExecuteAssignableAdditionalReportOrDataProcessorCommand(ExternalObject, Val CommandID, CommandParameters, RelatedObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, RelatedObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.ExecuteCommand(CommandID, RelatedObjects);
		Else
			ExternalObject.ExecuteCommand(CommandID, RelatedObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use.
Procedure ExecuteRelatedObjectsCreationCommand(ExternalObject, Val CommandID, CommandParameters, RelatedObjects, ModifiedObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		CommandParameters.Insert("ModifiedObjects", ModifiedObjects);
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, RelatedObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.ExecuteCommand(CommandID, RelatedObjects, ModifiedObjects);
		Else
			ExternalObject.ExecuteCommand(CommandID, RelatedObjects, ModifiedObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use.
Procedure ExecutePrintFormCreationCommand(ExternalObject, Val CommandID, CommandParameters, RelatedObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, RelatedObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.Print(CommandID, RelatedObjects);
		Else
			ExternalObject.Print(CommandID, RelatedObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// Executes an additional report (data processor) command from an object.
Function ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, ResultAddress)
	
	ExternalObjectInfo = ExternalObject.ExternalDataProcessorInfo();
	
	DataProcessorKind = GetDataProcessorKindByKindStringPresentation(ExternalObjectInfo.Kind);
	
	PassParameters = (
		ExternalObjectInfo.Property("SSLVersion")
		AND CommonClientServer.CompareVersions(ExternalObjectInfo.SSLVersion, "1.2.1.4") >= 0);
	
	ExecutionResult = CommonClientServer.StructureProperty(CommandParameters, "ExecutionResult");
	If TypeOf(ExecutionResult) <> Type("Structure") Then
		CommandParameters.Insert("ExecutionResult", New Structure());
	EndIf;
	
	CommandDetails = ExternalObjectInfo.Commands.Find(CommandID, "ID");
	If CommandDetails = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Команда %1 не обнаружена.'; en = 'Command %1 is not found.'; pl = 'Polecenie %1 nie znaleziono.';de = 'Befehl %1 nicht gefunden.';ro = 'Comanda %1 nu a fost găsită.';tr = 'Komut %1 bulunamadı.'; es_ES = 'Comando %1 no se ha encontrado.'"), CommandID);
	EndIf;
	
	IsScenarioInSafeMode = (CommandDetails.Use = "ScenarioInSafeMode");
	
	ModifiedObjects = Undefined;
	
	If DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor
		OR DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		ExecuteAdditionalReportOrDataProcessorCommand(
			ExternalObject,
			CommandID,
			?(PassParameters, CommandParameters, Undefined),
			IsScenarioInSafeMode);
		
	ElsIf DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation Then
		
		ModifiedObjects = New Array;
		ExecuteRelatedObjectsCreationCommand(
			ExternalObject,
			CommandID,
			?(PassParameters, CommandParameters, Undefined),
			CommandParameters.RelatedObjects,
			ModifiedObjects,
			IsScenarioInSafeMode);
		
	ElsIf DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling
		OR DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.Report
		OR DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		
		RelatedObjects = Undefined;
		CommandParameters.Property("RelatedObjects", RelatedObjects);
		
		If DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
			
			// Only arbitrary printing here. MXL printing is performed through the Printing subsystem.
			ExecutePrintFormCreationCommand(
				ExternalObject,
				CommandID,
				?(PassParameters, CommandParameters, Undefined),
				RelatedObjects,
				IsScenarioInSafeMode);
			
		Else
			
			ExecuteAssignableAdditionalReportOrDataProcessorCommand(
				ExternalObject,
				CommandID,
				?(PassParameters, CommandParameters, Undefined),
				RelatedObjects,
				IsScenarioInSafeMode);
			
			If DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling Then
				ModifiedObjects = RelatedObjects;
			EndIf;
		EndIf;
		
	EndIf;
	
	CommandParameters.ExecutionResult.Insert("NotifyForms", StandardSubsystemsServer.PrepareFormChangeNotification(ModifiedObjects));
	
	If TypeOf(ResultAddress) = Type("String") AND IsTempStorageURL(ResultAddress) Then
		PutToTempStorage(CommandParameters.ExecutionResult, ResultAddress);
	EndIf;
	
	Return CommandParameters.ExecutionResult;
	
EndFunction

// For internal use.
Procedure ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, RelatedObjects = Undefined)
	
	SafeModeExtension = AdditionalReportsAndDataProcessorsSafeModeInternal;
	
	ExternalObject = ExternalDataProcessorObject(CommandParameters.AdditionalDataProcessorRef);
	CommandID = CommandParameters.CommandID;
	
	Scenario = ExternalObject.GenerateScenario(CommandID, CommandParameters);
	SessionKey = AdditionalReportsAndDataProcessorsSafeModeInternal.GenerateSafeModeExtensionSessionKey(
		CommandParameters.AdditionalDataProcessorRef);
	
	SafeModeExtension.ExecuteSafeModeScenario(
		SessionKey, Scenario, ExternalObject, CommandParameters, Undefined, RelatedObjects);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures used for data exchange.

// Overrides standard behavior during data import.
// Attribute GUIDScheduledJob of the Commands tabular section cannot be transferred because it is 
// related to a scheduled job of the current infobase.
//
Procedure OnGetAdditionalDataProcessor(DataItem, GetItem)
	
	If GetItem = DataItemReceive.Ignore Then
		
		// No overriding for standard data processor.
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.AdditionalReportsAndDataProcessors")
		AND DataItem.Type = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		
		// The table of scheduled job UUIDs.
		QueryText =
		"SELECT
		|	Commands.Ref AS Ref,
		|	Commands.ID AS ID,
		|	Commands.GUIDScheduledJob AS GUIDScheduledJob
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Commands AS Commands
		|WHERE
		|	Commands.Ref = &Ref";
		
		Query = New Query(QueryText);
		Query.Parameters.Insert("Ref", DataItem.Ref);
		
		ScheduledJobsIDs = Query.Execute().Unload();
		
		// Filling in the command table with the scheduled job IDs based on the current database data.
		For Each StringCommand In DataItem.Commands Do
			FoundItems = ScheduledJobsIDs.FindRows(New Structure("ID", StringCommand.ID));
			If FoundItems.Count() = 0 Then
				StringCommand.GUIDScheduledJob = CommonClientServer.BlankUUID();
			Else
				StringCommand.GUIDScheduledJob = FoundItems[0].GUIDScheduledJob;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Mapping catalog items with configuration metadata objects.

Procedure MapConfigurationDataProcessorsWithCatalogDataProcessors(ReportsAndDataProcessors)
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref,
	|	AdditionalReportsAndDataProcessors.Version,
	|	AdditionalReportsAndDataProcessors.ObjectName,
	|	AdditionalReportsAndDataProcessors.FileName
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors";
	
	DataProcessorsFromConfiguration = Query.Execute().Unload();
	For Each ConfigurationDataProcessor In DataProcessorsFromConfiguration Do
		ConfigurationDataProcessor.ObjectName = Upper(ConfigurationDataProcessor.ObjectName);
		ConfigurationDataProcessor.FileName   = Upper(ConfigurationDataProcessor.FileName);
	EndDo;
	DataProcessorsFromConfiguration.Columns.Add("Found", New TypeDescription("Boolean"));
	
	ReportsAndDataProcessors.Columns.Add("Name");
	ReportsAndDataProcessors.Columns.Add("FileName");
	ReportsAndDataProcessors.Columns.Add("FullName");
	ReportsAndDataProcessors.Columns.Add("Kind");
	ReportsAndDataProcessors.Columns.Add("Extension");
	ReportsAndDataProcessors.Columns.Add("Manager");
	ReportsAndDataProcessors.Columns.Add("Info");
	ReportsAndDataProcessors.Columns.Add("DataFromCatalog");
	ReportsAndDataProcessors.Columns.Add("Ref");
	
	ReverseIndex = ReportsAndDataProcessors.Count();
	While ReverseIndex > 0 Do
		ReverseIndex = ReverseIndex - 1;
		TableRow = ReportsAndDataProcessors[ReverseIndex];
		
		TableRow.Name = TableRow.MetadataObject.Name;
		TableRow.FullName = TableRow.MetadataObject.FullName();
		TableRow.Kind = Upper(StrSplit(TableRow.FullName, ".")[0]);
		If TableRow.Kind = "REPORT" Then
			TableRow.Extension = "erf";
			ManagerFromConfigurationMetadata = Reports[TableRow.Name];
		ElsIf TableRow.Kind = "DATAPROCESSOR" Then
			TableRow.Extension = "epf";
			ManagerFromConfigurationMetadata = DataProcessors[TableRow.Name];
		Else
			ReportsAndDataProcessors.Delete(ReverseIndex);
			Continue; // Unsupported metadata object kind.
		EndIf;
		TableRow.FileName = TableRow.Name + "." + TableRow.Extension;
		TableRow.OldFilesNames.Insert(0, TableRow.FileName);
		TableRow.OldObjectsNames.Insert(0, TableRow.Name);
		
		TableRow.Info = ManagerFromConfigurationMetadata.Create().ExternalDataProcessorInfo();
		
		// Searching the catalog.
		DataFromCatalog = Undefined;
		For Each FileName In TableRow.OldFilesNames Do
			DataFromCatalog = DataProcessorsFromConfiguration.Find(Upper(FileName), "FileName");
			If DataFromCatalog <> Undefined Then
				Break;
			EndIf;
		EndDo;
		If DataFromCatalog = Undefined Then
			For Each ObjectName In TableRow.OldObjectsNames Do
				DataFromCatalog = DataProcessorsFromConfiguration.Find(Upper(ObjectName), "ObjectName");
				If DataFromCatalog <> Undefined Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If DataFromCatalog = Undefined Then
			Continue; // Registering a new data processor.
		EndIf;
		
		If VersionAsNumber(DataFromCatalog.Version) >= VersionAsNumber(TableRow.Info.Version)
			AND TableRow.Info.Version <> Metadata.Version Then
			// Update is not required because the catalog contains the latest version of the data processor.
			ReportsAndDataProcessors.Delete(ReverseIndex);
		Else
			// Registering a reference for update.
			TableRow.Ref = DataFromCatalog.Ref;
		EndIf;
		DataProcessorsFromConfiguration.Delete(DataFromCatalog);
		
	EndDo;
	
	ReportsAndDataProcessors.Columns.Delete("OldFilesNames");
	ReportsAndDataProcessors.Columns.Delete("OldObjectsNames");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Exporting configuration reports and data processors to files of external reports and data processors.

Procedure ExportReportsAndDataProcessorsToFiles(ReportsAndDataProcessors)
	
	ReportsAndDataProcessors.Columns.Add("BinaryData");
	Parameters = New Structure;
	Parameters.Insert("WorkingDirectory", FileSystem.CreateTemporaryDirectory("ARADP"));
	StartupCommand = New Array;
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(Parameters.WorkingDirectory);
	DataExported = DesignerBatchRun(Parameters, StartupCommand);
	If Not DataExported.Success Then
		ErrorText = TrimAll(
			NStr("ru = 'Не удалось выгрузить отчеты и обработки конфигурации во внешние файлы:'; en = 'Failed to export reports and configuration data processors to external files:'; pl = 'Nie udało się przesłać sprawozdania i przetwarzania konfiguracji do plików zewnętrznych:';de = 'Berichte und Konfigurationsverarbeitung konnten nicht in externe Dateien hochgeladen werden:';ro = 'Eșec la descărcarea rapoartelor și procesărilor configurației în fișierele externe:';tr = 'Dış dosyalara rapor ve yapılandırma işleme yüklenemedi:'; es_ES = 'No se ha podido subir los informes y los procesamientos de la configuración en los archivos externos:'")
			+ Chars.LF + DataExported.InBrief
			+ Chars.LF + DataExported.More);
		WriteWarning(Undefined, ErrorText);
		ReportsAndDataProcessors.Clear();
	EndIf;
	
	ReverseIndex = ReportsAndDataProcessors.Count();
	While ReverseIndex > 0 Do
		ReverseIndex = ReverseIndex - 1;
		TableRow = ReportsAndDataProcessors[ReverseIndex];
		
		If TableRow.Kind = "REPORT" Then
			KindDirectory = Parameters.WorkingDirectory + "Reports" + GetPathSeparator();
		ElsIf TableRow.Kind = "DATAPROCESSOR" Then
			KindDirectory = Parameters.WorkingDirectory + "DataProcessors" + GetPathSeparator();
		Else
			WriteError(TableRow.Ref, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Неподдерживаемый вид объектов метаданных: ""1""'; en = 'Invalid metadata object kind: ""1""'; pl = 'Nieobsługiwany rodzaj obiektów metadanych: ""1""';de = 'Nicht unterstützte Ansicht von Metadatenobjekten: ""1""';ro = 'Tip nesusținut al obiectelor de metadate: ""1""';tr = 'Desteklenmeyen meta veri nesne görünümü: ""1""'; es_ES = 'Tipo de los objetos de metadatos no admitido: ""1""'"), TableRow.Kind));
			ReportsAndDataProcessors.Delete(ReverseIndex);
			Continue;
		EndIf;
		
		FullObjectSchemaName = KindDirectory + TableRow.Name + ".xml";
		SchemaText = ReadTextFile(FullObjectSchemaName);
		If SchemaText = Undefined Then
			WriteError(TableRow.Ref, 
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не обнаружен файл ""%1"".'; en = 'Cannot find file: %1.'; pl = 'Nie znaleziono pliku ""%1"".';de = 'Datei ""%1"" wurde nicht gefunden.';ro = 'Nu a fost găsit fișierul ""%1"".';tr = '""%1"" dosya bulunamadı.'; es_ES = 'Archivo no encontrado ""%1"".'"), 
					FullObjectSchemaName));
			ReportsAndDataProcessors.Delete(ReverseIndex);
			Continue;
		EndIf;
		If TableRow.Kind = "REPORT" Then
			SchemaText = StrReplace(SchemaText, "Report", "ExternalReport");
			SchemaText = StrReplace(SchemaText, "ExternalReportTabularSection", "ReportTabularSection");
		ElsIf TableRow.Kind = "DATAPROCESSOR" Then
			SchemaText = StrReplace(SchemaText, "DataProcessor", "ExternalDataProcessor");
		EndIf;
		WriteTextFile(FullObjectSchemaName, SchemaText);
		
		If TableRow.Kind = "DATAPROCESSOR" Then
			DocumentDOM = ReadDOMDocument(FullObjectSchemaName);
			Dereferencer = New DOMNamespaceResolver(DocumentDOM);
			XMLChanged = False;
			
			SearchExpressionsForNodesToDelete = New Array;
			SearchExpressionsForNodesToDelete.Add("//xmlns:Command");
			SearchExpressionsForNodesToDelete.Add("//*[contains(@name, 'ExternalDataProcessorManager.')]");
			SearchExpressionsForNodesToDelete.Add("//xmlns:UseStandardCommands");
			SearchExpressionsForNodesToDelete.Add("//xmlns:IncludeHelpInContents");
			SearchExpressionsForNodesToDelete.Add("//xmlns:ExtendedPresentation");
			SearchExpressionsForNodesToDelete.Add("//xmlns:Explanation");
			
			For Each Expression In SearchExpressionsForNodesToDelete Do
				XPathResult = EvaluateXPathExpression(Expression, DocumentDOM, Dereferencer);
				DOMElement = XPathResult.IterateNext();
				While DOMElement <> Undefined Do
					DOMElement.ParentNode.RemoveChild(DOMElement);
					XMLChanged = True;
					DOMElement = XPathResult.IterateNext();
				EndDo;
			EndDo;
			
			If XMLChanged Then
				WriteDOMDocument(DocumentDOM, FullObjectSchemaName);
			EndIf;
		EndIf;
		
		FullFileName = Parameters.WorkingDirectory + TableRow.FileName;
		StartupCommand = New Array;
		StartupCommand.Add("/LoadExternalDataProcessorOrReportFromFiles");
		StartupCommand.Add(FullObjectSchemaName);
		StartupCommand.Add(FullFileName);
		CreateDataProcessor = DesignerBatchRun(Parameters, StartupCommand);
		If Not CreateDataProcessor.Success Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать ""%1"" из внешнего файла ""%2"":
					|%3
					|%4'; 
					|en = 'Cannot create %1 from the external file %2:
					|%3
					|%4'; 
					|pl = 'Nie udało się utworzyć  ""%1"" z pliku zewnętrznego ""%2"":
					|%3
					|%4';
					|de = 'Es konnte kein ""%1"" aus einer externen Datei ""%2"" erstellt werden:
					|%3
					|%4';
					|ro = 'Eșec la crearea ""%1"" din fișierul extern ""%2"":
					|%3
					|%4';
					|tr = 'Harici dosyadan ""%1"" oluşturulamadı ""%2"":
					|%3
					|%4'; 
					|es_ES = 'No se ha podido crear ""%1"" del archivo externo ""%2"":
					|%3
					|%4'"),
				TableRow.FullName, FullObjectSchemaName, 
				CreateDataProcessor.InBrief, CreateDataProcessor.More);
			WriteWarning(Undefined, ErrorText);
			ReportsAndDataProcessors.Delete(ReverseIndex);
			Continue;
		EndIf;
		TableRow.BinaryData = New BinaryData(FullFileName);
	EndDo;
	
	If Parameters.OneCDCopyDirectory <> Undefined Then
		FileSystem.DeleteTemporaryDirectory(Parameters.OneCDCopyDirectory);
	EndIf;
	FileSystem.DeleteTemporaryDirectory(Parameters.WorkingDirectory);
	
EndProcedure

Function DesignerBatchRun(Parameters, PassedStartupCommands)
	Result = New Structure("Success, InBrief, More", False, "", "");
	ParametersSample = New Structure("WorkingDirectory, User, Password, BINDirectory, ConfigurationPath, OneCDCopyDirectory");
	CommonClientServer.SupplementStructure(Parameters, ParametersSample, False);
	If Not ValueIsFilled(Parameters.User) Then
		Parameters.User = UserName();
	EndIf;
	If Not FileExists(Parameters.WorkingDirectory) Then
		CreateDirectory(Parameters.WorkingDirectory);
	EndIf;
	If Not ValueIsFilled(Parameters.BINDirectory) Then
		Parameters.BINDirectory = BinDir();
	EndIf;
	If Not ValueIsFilled(Parameters.ConfigurationPath) Then
		Parameters.ConfigurationPath = InfoBaseConnectionString();
		If DesignerIsOpen() Then
			If Common.FileInfobase() Then
				InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(Parameters.ConfigurationPath).file;
				Parameters.OneCDCopyDirectory = Parameters.WorkingDirectory + "BaseCopy" + GetPathSeparator();
				CreateDirectory(Parameters.OneCDCopyDirectory);
				FileCopy(InfobaseDirectory + "\1Cv8.1CD", Parameters.OneCDCopyDirectory + "1Cv8.1CD");
				Parameters.ConfigurationPath = StringFunctionsClientServer.SubstituteParametersToString(
					"File=""%1"";", Parameters.OneCDCopyDirectory);
			Else
				Result.InBrief = NStr("ru = 'Для выгрузки модулей необходимо закрыть конфигуратор.'; en = 'To export modules, close Designer.'; pl = 'W celu przesłania modułów należy zamknąć konfigurator.';de = 'Um die Module hochzuladen, muss der Konfigurator geschlossen werden.';ro = 'Pentru descărcarea modulelor trebuie să închideți designerul.';tr = 'Modülleri dışa aktarmak için yapılandırıcıyı kapatmanız gerekir.'; es_ES = 'Para subir los módulos es necesario cerrar el configurador.'");
				Return Result;
			EndIf;
		EndIf;
	EndIf;
	
	MessagesFileName = Parameters.WorkingDirectory + "DataExported.log";
	
	StartupCommand = New Array;
	StartupCommand.Add(Parameters.BINDirectory + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(Parameters.ConfigurationPath);
	StartupCommand.Add("/N");
	StartupCommand.Add(Parameters.User);
	StartupCommand.Add("/P");
	StartupCommand.Add(Parameters.Password);
	CommonClientServer.SupplementArray(StartupCommand, PassedStartupCommands);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	CommandRunParameters = FileSystem.ApplicationStartupParameters();
	CommandRunParameters.WaitForCompletion = True;
	
	RunResult = FileSystem.StartApplication(StartupCommand, CommandRunParameters);
	
	ReturnCode = RunResult.ReturnCode;
	If ReturnCode = 0 Then
		Result.Success = True;
		Return Result;
	EndIf;
	
	Result.InBrief = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось выгрузить конфигурацию в XML (код ошибки ""%1"")'; en = 'Cannot dump configuration to XML. Error code: %1.'; pl = 'Nie udało się przesłać konfigurację do XML (kod błędu ""%1"")';de = 'Fehler beim Hochladen der Konfiguration in XML (Fehlercode ""%1"")';ro = 'Eșec la descărcarea configurației în XML (codul erorii ""%1"")';tr = 'Yapılandırma XML''e aktarılamadı (hata kodu ""%1"")'; es_ES = 'No se ha podido subir la configuración en XML (código de error ""%1"")'"),
		ReturnCode);
	If FileExists(MessagesFileName) Then
		TextReader = New TextReader(MessagesFileName, , , , False);
		Messages = TrimAll(TextReader.Read());
		TextReader.Close();
		If Messages <> "" Then
			Result.More = StrReplace(Chars.LF + Messages, Chars.LF, Chars.LF + Chars.Tab);
		EndIf;
	EndIf;
	Return Result;
	
EndFunction

Function FileExists(FullFileName)
	File = New File(FullFileName);
	Return File.Exist();
EndFunction

Function DesignerIsOpen()
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Upper(Session.ApplicationName) = "DESIGNER" Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

Function ReadTextFile(FullFileName)
	If Not FileExists(FullFileName) Then
		Return Undefined;
	EndIf;
	TextReader = New TextReader(FullFileName);
	Text = TextReader.Read();
	TextReader.Close();
	Return Text;
EndFunction

Procedure WriteTextFile(FullFileName, Text)
	TextWriter = New TextWriter(FullFileName, TextEncoding.UTF8);
	TextWriter.Write(Text);
	TextWriter.Close();
EndProcedure

Function ReadDOMDocument(PathToFile)
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	DOMBuilder = New DOMBuilder;
	DocumentDOM = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DocumentDOM;
EndFunction

Function EvaluateXPathExpression(Expression, DocumentDOM, Dereferencer)
	Return DocumentDOM.EvaluateXPathExpression(Expression, DocumentDOM, Dereferencer);
EndFunction

Procedure WriteDOMDocument(DocumentDOM, FileName)
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(FileName);
	DOMWriter = New DOMWriter;
	DOMWriter.Write(DocumentDOM, XMLWriter);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Performs batch registration of external reports and data processors in the catalog.

Procedure RegisterReportsAndDataProcessors(ReportsAndDataProcessors)
	
	For Each TableRow In ReportsAndDataProcessors Do
		// Updating/adding.
		If TableRow.Ref = Undefined Then
			CatalogObject = Catalogs.AdditionalReportsAndDataProcessors.CreateItem();
			CatalogObject.UseForObjectForm = True;
			CatalogObject.UseForListForm  = True;
			CatalogObject.EmployeeResponsible               = Users.CurrentUser();
		Else
			CatalogObject = TableRow.Ref.GetObject();
		EndIf;
		
		IsReport      = (TableRow.Kind = "REPORT");
		DataAddress   = PutToTempStorage(TableRow.BinaryData);
		Manager      = ?(IsReport, ExternalReports, ExternalDataProcessors);
		ObjectName = Manager.Connect(DataAddress, , True,
			Common.ProtectionWithoutWarningsDetails());
		ExternalObject = Manager.Create(ObjectName);
		
		ExternalObjectMetadata = ExternalObject.Metadata();
		DataProcessorInfo = TableRow.Info;
		If DataProcessorInfo.Description = Undefined OR DataProcessorInfo.Information = Undefined Then
			If DataProcessorInfo.Description = Undefined Then
				DataProcessorInfo.Description = ExternalObjectMetadata.Presentation();
			EndIf;
			If DataProcessorInfo.Information = Undefined Then
				DataProcessorInfo.Information = ExternalObjectMetadata.Comment;
			EndIf;
		EndIf;
		
		FillPropertyValues(CatalogObject, DataProcessorInfo, "Description, SafeMode, Version, Information");
		
		// Exporting command settings that can be changed by administrator.
		JobsSearch = New Map;
		For Each ObsoleteCommand In CatalogObject.Commands Do
			If ValueIsFilled(ObsoleteCommand.GUIDScheduledJob) Then
				JobsSearch.Insert(Upper(ObsoleteCommand.ID), ObsoleteCommand.GUIDScheduledJob);
			EndIf;
		EndDo;
		
		RegistrationParameters = New Structure;
		RegistrationParameters.Insert("DataProcessorDataAddress", DataAddress);
		RegistrationParameters.Insert("IsReport", IsReport);
		RegistrationParameters.Insert("DisableConflicts", False);
		RegistrationParameters.Insert("FileName", TableRow.FileName);
		RegistrationParameters.Insert("DisablePublication", False);
		
		CatalogObject.ObjectName = Undefined;
		CatalogObject.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
		CatalogObject.Kind        = GetDataProcessorKindByKindStringPresentation(
			DataProcessorInfo.Kind);
		
		Result = RegisterDataProcessor(CatalogObject, RegistrationParameters);
		If Not Result.Success AND Result.ObjectNameUsed Then
			RegistrationParameters.Insert("DisableConflicts", True);
			RegistrationParameters.Insert("Conflicting", Result.Conflicting);
			Result = RegisterDataProcessor(CatalogObject, RegistrationParameters);
		EndIf;
		If Not Result.Success Then
			If Result.ObjectNameUsed Then
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Имя ""%1"" занято объектами ""%2""'; en = 'Name %1 is assigned to objects %2.'; pl = 'Nazwa ""%1"" jest zajęta przez obiekty ""%2""';de = 'Der Name ""%1"" wird von den Objekten ""%2"" besetzt';ro = 'Numele ""%1"" este ocupat de obiectele ""%2""';tr = '""%1"" adı ""%2"" nesne tarafından kullanılıyor'; es_ES = 'El nombre ""%1"" está ocupado por objetos ""%2""'"),
					ObjectName,
					String(Result.Conflicting));
			EndIf;
			WriteLogEvent(
				SubsystemDescription(),
				EventLogLevel.Error,
				Metadata.CommonTemplates.Find(TableRow.TemplateName),
				,
				Result.ErrorText);
			Continue;
		EndIf;
		
		CatalogObject.DataProcessorStorage = New ValueStorage(TableRow.BinaryData);
		CatalogObject.ObjectName         = ExternalObjectMetadata.Name;
		CatalogObject.FileName           = TableRow.FileName;
		
		// Clearing and importing new commands.
		For Each Command In CatalogObject.Commands Do
			GUIDScheduledJob = JobsSearch.Get(Upper(Command.ID));
			If GUIDScheduledJob <> Undefined Then
				Command.GUIDScheduledJob = GUIDScheduledJob;
				JobsSearch.Delete(Upper(Command.ID));
			EndIf;
		EndDo;
		
		// Deleting outdated jobs.
		For Each KeyAndValue In JobsSearch Do
			Try
				Job = ScheduledJobsServer.Job(KeyAndValue.Value);
				Job.Delete();
			Except
				WriteLogEvent(
					InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,
					Metadata.Catalogs.AdditionalReportsAndDataProcessors,
					CatalogObject.Ref,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка при удалении задания ""%1"":%2'; en = 'Error deleting job %1: %2'; pl = 'Błąd podczas usuwania zadania ""%1"":%2';de = 'Fehler beim Löschen der Aufgabe ""%1"":%2';ro = 'Eroare la ștergerea însărcinării ""%1"":%2';tr = '""%2"" görevi kaldırırken bir hata oluştu: %1'; es_ES = 'Error al eliminar la tarea ""%1"":%2'"),
						KeyAndValue.Value,
						Chars.LF + DetailErrorDescription(ErrorInfo())));
			EndTry;
		EndDo;
		
		If CheckGlobalDataProcessor(CatalogObject.Kind) Then
			MetadataObjectsTable = AttachedMetadataObjects(CatalogObject.Kind);
			For Each TableRow In MetadataObjectsTable Do
				SectionRef = TableRow.Ref;
				SectionRow = CatalogObject.Sections.Find(SectionRef, "Section");
				If SectionRow = Undefined Then
					SectionRow = CatalogObject.Sections.Add();
					SectionRow.Section = SectionRef;
				EndIf;
			EndDo;
		Else
			For Each AssignmentDetails In DataProcessorInfo.Purpose Do
				MetadataObject = Metadata.FindByFullName(AssignmentDetails);
				If MetadataObject = Undefined Then
					Continue;
				EndIf;
				RelatedObjectRef = Common.MetadataObjectID(MetadataObject);
				AssignmentRow = CatalogObject.Purpose.Find(RelatedObjectRef, "RelatedObject");
				If AssignmentRow = Undefined Then
					AssignmentRow = CatalogObject.Purpose.Add();
					AssignmentRow.RelatedObject = RelatedObjectRef;
				EndIf;
			EndDo;
		EndIf;
		
		InfobaseUpdate.WriteObject(CatalogObject, , True);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other

// Sets the data processor publication kind used for conflicting additional reports and data processors.
Procedure DisableConflictingDataProcessor(DataProcessorObject)
	KindDebugMode = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
	AvailableKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	If AvailableKinds.Find(KindDebugMode) Then
		DataProcessorObject.Publication = KindDebugMode;
	Else
		DataProcessorObject.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled;
	EndIf;
EndProcedure

// For internal use.
Function RegisterDataProcessor(Val Object, Val RegistrationParameters) Export
	
	KindAdditionalDataProcessor = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor;
	KindAdditionalReport     = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport;
	ReportKind                   = Enums.AdditionalReportsAndDataProcessorsKinds.Report;
	
	// Gets a data processor file from a temporary storage, attempts to create an external data 
	// processor (report) object, and gets information from the external data processor (report) object.
	
	If RegistrationParameters.DisableConflicts Then
		For Each ListItem In RegistrationParameters.Conflicting Do
			ConflictingObject = ListItem.Value.GetObject();
			DisableConflictingDataProcessor(ConflictingObject);
			ConflictingObject.Write();
		EndDo;
	ElsIf RegistrationParameters.DisablePublication Then
		DisableConflictingDataProcessor(Object);
	EndIf;
	
	Result = New Structure("ObjectName, OldObjectName, Success, ObjectNameUsed, Conflicting, ErrorText, BriefErrorPresentation");
	Result.ObjectNameUsed = False;
	Result.Success = False;
	If Object.IsNew() Then
		Result.OldObjectName = Object.ObjectName;
	Else
		Result.OldObjectName = Common.ObjectAttributeValue(Object.Ref, "ObjectName");
	EndIf;
	
	RegistrationData = GetRegistrationData(Object, RegistrationParameters, Result);
	If RegistrationData = Undefined
		Or RegistrationData.Count() = 0
		Or ValueIsFilled(Result.ErrorText)
		Or ValueIsFilled(Result.BriefErrorPresentation) Then
		Return Result;
	EndIf;
	
	If RegistrationData.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		AND Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Result.ErrorText = NStr("ru = 'Работа с печатными формами не поддерживается.'; en = 'Print forms are not supported.'; pl = 'Praca z formularzami wydruku nie jest obsługiwana.';de = 'Die Arbeit mit Druckformularen wird nicht unterstützt.';ro = 'Lucrul cu formele de tipar nu este susținut.';tr = 'Basılı formlar ile çalışma desteklenmez.'; es_ES = 'No se admite el uso de los formularios de impresión.'");
		Return Result;
	EndIf;
	
	// If the report is published, a check for uniqueness of the object name used to register the 
	// additional report in the application is performed.
	If Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used Then
		// Checking the name
		QueryText =
		"SELECT
		|	CatalogTable.Ref AS Ref,
		|	CatalogTable.Presentation AS Presentation
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS CatalogTable
		|WHERE
		|	CatalogTable.ObjectName = &ObjectName
		|	AND CatalogTable.Kind IN(&AdditionalReportsAndDataProcessorsKinds)
		|	AND CatalogTable.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
		|	AND CatalogTable.DeletionMark = FALSE
		|	AND CatalogTable.Ref <> &Ref";
		
		AdditionalReportsAndDataProcessorsKinds = New Array;
		AdditionalReportsAndDataProcessorsKinds.Add(KindAdditionalReport);
		AdditionalReportsAndDataProcessorsKinds.Add(ReportKind);
		
		Query = New Query;
		Query.SetParameter("ObjectName",     Result.ObjectName);
		Query.SetParameter("AdditionalReportsAndDataProcessorsKinds", AdditionalReportsAndDataProcessorsKinds);
		Query.SetParameter("Ref", Object.Ref);
		
		If Not RegistrationParameters.IsReport Then
			QueryText = StrReplace(QueryText, "CatalogTable.Kind", "NOT CatalogTable.Kind"); // do not localize.
		EndIf;
		
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		Conflicting = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Conflicting.Count() > 0 Then
			Result.ObjectNameUsed = True;
			Result.Conflicting = New ValueList;
			For Each TableRow In Conflicting Do
				Result.Conflicting.Add(TableRow.Ref, TableRow.Presentation);
			EndDo;
			Return Result;
		EndIf;
	EndIf;
	
	If Not RegistrationData.SafeMode AND Not Users.IsFullUser(, True) Then
		Result.ErrorText = NStr("ru = 'Для подключения обработки, запускаемой в небезопасном режиме, требуются административные права.'; en = 'To attach a data processor that runs in unsafe mode, administrative rights are required.'; pl = 'Aby podłączyć przetwarzanie danych uruchamiane w trybie niebezpiecznym, wymagane są uprawnienia administracyjne.';de = 'Um den Datenprozessor im unsicheren Modus auszuführen, sind Administratorrechte erforderlich.';ro = 'Pentru a conecta procesarea lansată în regim nesecurizat sunt necesare drepturi administrative.';tr = 'Güvenli olmayan modda çalışan veri işlemcisini bağlamak için yönetimsel haklar gereklidir.'; es_ES = 'Para conectar el procesador de datos, lanzar en el modo inseguro, se requieren los derechos administrativos.'");
		Return Result;
	EndIf;
	
	IsExternalReport = RegistrationData.Kind = KindAdditionalReport OR RegistrationData.Kind = ReportKind;
	If NOT Object.IsNew() AND RegistrationData.Kind <> Object.Kind Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Вид загружаемого объекта (%1) не соответствует текущему (%2).
				|Для загрузки нового объекта нажмите ""Создать"".'; 
				|en = 'Object kind mismatch. Imported object: %1. Current object: %2.
				|To import a new object, select Create.'; 
				|pl = 'Zaimportowany typ obiektu (%1) nie odpowiada bieżącemu (%2).
				|Aby zaimportować nowy obiekt, kliknij Utwórz.';
				|de = 'Importierte Objektart (%1) entspricht nicht der aktuellen (%2). 
				|Um ein neues Objekt zu importieren, klicken Sie auf Erstellen.';
				|ro = 'Tipul de obiect importat (%1) nu corespunde cu cel curent (%2).
				|Pentru a importa un obiect nou tastați ""Creare"".';
				|tr = 'İçe aktarılan nesne türü (%1) mevcut olanla (%2) uyuşmuyor. 
				|Yeni bir nesneyi içe aktarmak için Oluştur''u tıklayın.'; 
				|es_ES = 'Tipo del objeto importado (%1) no corresponde al actual (%2).
				|Para importar un nuevo objeto, hacer clic en Crear.'"),
			String(RegistrationData.Kind),
			String(Object.Kind));
		Return Result;
	ElsIf RegistrationParameters.IsReport <> IsExternalReport Then
		Result.ErrorText = NStr("ru = 'Вид обработки, указанный в сведениях о внешней обработке, не соответствует ее расширению.'; en = 'The kind of the data processor specified in the data processor details does not match the actual extension.'; pl = 'Typ opracowania z zewnętrznego przetwarzania danych nie odpowiada jego rozszerzeniu.';de = 'Datenverarbeitertyp aus externen Datenprozessordaten entspricht nicht seiner Erweiterung.';ro = 'Tipul procesării, indicat în informațiile despre procesarea externă, nu corespunde extensiei sale.';tr = 'Harici veri işlemcisi bilgilerinde belirtilen veri işlemcisi türü, uzantısına uymuyor.'; es_ES = 'Tipo del procesador de datos de los datos del procesador de datos externo no corresponde a su extensión.'");
		Return Result;
	EndIf;
	
	Object.Description    = RegistrationData.Description;
	Object.Version          = RegistrationData.Version;
	Object.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
	If RegistrationData.Property("SSLVersion") 
		AND CommonClientServer.CompareVersions(RegistrationData.SSLVersion, "2.2.2.0") > 0 Then
		Object.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2;
	EndIf;
	
	If RegistrationData.Property("SafeMode") Then
		Object.SafeMode = RegistrationData.SafeMode;
	EndIf;
	
	Object.Information      = RegistrationData.Information;
	Object.FileName        = RegistrationParameters.FileName;
	Object.ObjectName      = Result.ObjectName;
	
	Object.UseOptionStorage = False;
	If IsExternalReport Then
		Object.UseOptionStorage = (RegistrationData.VariantsStorage = "ReportsVariantsStorage"
			OR (Metadata.ReportsVariantsStorage <> Undefined
				AND Metadata.ReportsVariantsStorage.Name = "ReportsVariantsStorage"));
		RegistrationData.Property("DefineFormSettings", Object.DeepIntegrationWithReportForm);
	EndIf;
	
	// A different data processor is imported (an object name or a data processor kind was changed).
	If Object.IsNew() OR Object.ObjectName <> Result.ObjectName OR Object.Kind <> RegistrationData.Kind Then
		Object.Purpose.Clear();
		Object.Sections.Clear();
		Object.Kind = RegistrationData.Kind;
	EndIf;
	
	// If the assignment is not specified, setting the value from the data processor.
	If Object.Purpose.Count() = 0 AND NOT IsExternalReport Then
		
		If RegistrationData.Property("Purpose") Then
			MetadataObjectsTable = AttachedMetadataObjects(Object.Kind);
			
			For Each FullMetadataObjectName In RegistrationData.Purpose Do
				PointPosition = StrFind(FullMetadataObjectName, ".");
				If Mid(FullMetadataObjectName, PointPosition + 1) = "*" Then // For example, [Catalog.*].
					Search = New Structure("Kind", Left(FullMetadataObjectName, PointPosition - 1));
				Else
					Search = New Structure("FullName", FullMetadataObjectName);
				EndIf;
				
				FoundItems = MetadataObjectsTable.FindRows(Search);
				For Each TableRow In FoundItems Do
					AssignmentRow = Object.Purpose.Add();
					AssignmentRow.RelatedObject = TableRow.Ref;
				EndDo;
			EndDo;
		EndIf;
		
		Object.Purpose.GroupBy("RelatedObject", "");
		
	EndIf;
	
	Object.Commands.Clear();
	
	// Initializing commands
	For Each DetailsCommand In RegistrationData.Commands Do
		
		If NOT ValueIsFilled(DetailsCommand.StartupOption) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для команды ""%1"" не определен способ запуска.'; en = 'Startup option is not specified for command %1.'; pl = 'Metoda uruchamiania nie jest zdefiniowana dla polecenia ""%1"".';de = 'Die Startmethode ist nicht für den Befehl ""%1"" definiert.';ro = 'Pentru comanda ""%1"" metoda de lansare nu este definită.';tr = '""%1"" komutu için başlatma yöntemi tanımlanmadı.'; es_ES = 'El método de lanzamiento no está definido para el comando ""%1"".'"), DetailsCommand.Presentation));
		EndIf;
		Command = Object.Commands.Add();
		FillPropertyValues(Command, DetailsCommand);
		
	EndDo;
	
	// Reading permissions required by the additional data processor.
	Object.Permissions.Clear();
	Permissions = Undefined;
	If RegistrationData.Property("Permissions", Permissions) Then
		
		For Each Permission In Permissions Do
			
			XDTOType = Permission.Type();
			
			TSRow = Object.Permissions.Add();
			TSRow.PermissionKind = XDTOType.Name;
			
			Parameters = New Structure();
			
			For Each XDTOProperty In XDTOType.Properties Do
				
				Container = Permission.GetXDTO(XDTOProperty.Name);
				
				If Container <> Undefined Then
					Parameters.Insert(XDTOProperty.Name, Container.Value);
				Else
					Parameters.Insert(XDTOProperty.Name);
				EndIf;
				
			EndDo;
			
			TSRow.Parameters = New ValueStorage(Parameters);
			
		EndDo;
		
	EndIf;
	
	Object.EmployeeResponsible = Users.CurrentUser();
	Result.Success = True;
	Return Result;
	
EndFunction

// For internal use.
Function GetRegistrationData(Val Object, Val RegistrationParameters, Val RegistrationResult)

	RegistrationData = New Structure;
	StandardProcessing = True;
	
	SaaSIntegration.OnGetRegistrationData(Object, RegistrationData, StandardProcessing);
	If StandardProcessing Then
		OnGetRegistrationData(Object, RegistrationData, RegistrationParameters, RegistrationResult);
	EndIf;
	
	Return RegistrationData;
EndFunction

// For internal use.
Procedure OnGetRegistrationData(Object, RegistrationData, RegistrationParameters, RegistrationResult)
	
	// Attaching and getting the name to be used when attaching the object.
	Manager = ?(RegistrationParameters.IsReport, ExternalReports, ExternalDataProcessors);
	
	ErrorInformation = Undefined;
	Try
#If ThickClientOrdinaryApplication Then
		RegistrationResult.ObjectName = GetTempFileName();
		BinaryData = GetFromTempStorage(RegistrationParameters.DataProcessorDataAddress);
		BinaryData.Write(RegistrationResult.ObjectName);
#Else
		RegistrationResult.ObjectName =
			TrimAll(Manager.Connect(RegistrationParameters.DataProcessorDataAddress, , True,
				Common.ProtectionWithoutWarningsDetails()));
#EndIf
		
		// Getting information about an external data processor.
		ExternalObject = Manager.Create(RegistrationResult.ObjectName);
		ExternalObjectMetadata = ExternalObject.Metadata();
		
		ExternalDataProcessorInfo = ExternalObject.ExternalDataProcessorInfo();
		CommonClientServer.SupplementStructure(RegistrationData, ExternalDataProcessorInfo, True);
	Except
		ErrorInformation = ErrorInfo();
	EndTry;
	#If ThickClientOrdinaryApplication Then
		Try
			DeleteFiles(RegistrationResult.ObjectName);
		Except
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при получении регистрационных данных:
				|Ошибка при удалении временного файла ""%1"":
				|%2'; 
				|en = 'Error receiving registration data.
				|Deletion of temp file %1 failed:
				|%2'; 
				|pl = 'Błąd podczas pobierania danych rejestracyjnych:
				|Błąd podczas usuwania pliku tymczasowego ""%1"":
				|%2';
				|de = 'Fehler beim Empfangen von Registrierungsdaten:
				|Fehler beim Löschen einer temporären Datei ""%1"":
				|%2';
				|ro = 'Eroare la primirea datelor de înregistrare:
				|Eroare la ștergerea fișierului temporar ""%1"":
				|%2';
				|tr = 'Kayıt alma hatası: 
				| ""%1"" geçici dosya silme hatası : 
				|%2'; 
				|es_ES = 'Error al recibir los datos de registro:
				|Error al eliminar el archivo temporal ""%1"":
				|%2'"),
				RegistrationResult.ObjectName,
				DetailErrorDescription(ErrorInfo()));
			WriteWarning(Object.Ref, WarningText);
		EndTry;
	#EndIf
	If ErrorInformation <> Undefined Then
		If RegistrationParameters.IsReport Then
			ErrorText = NStr("ru='Невозможно подключить дополнительный отчет из файла.
			|Возможно, он не подходит для этой версии программы.'; 
			|en = 'Cannot attach an additional report from a file.
			|It might not be compatible with this application version.'; 
			|pl = 'Nie można włączyć dodatkowego sprawozdania z pliku.
			|Może on być niezgodny z wersją aplikacji.';
			|de = 'Der zusätzliche Bericht aus der Datei kann nicht aktiviert werden. 
			|Es ist möglicherweise nicht mit der Anwendungsversion kompatibel.';
			|ro = 'Raportul suplimentar din fișier nu poate fi activat.
			|Posibil, el nu este compatibil cu versiunea aplicației.';
			|tr = 'Dosyadan ek rapor etkinleştirilemiyor. 
			|Uygulama sürümü ile uyumlu olmayabilir.'; 
			|es_ES = 'No se puede activar el informe adicional desde el archivo.
			|Puede ser no compatible con la versión de la aplicación.'");
		Else
			ErrorText = NStr("ru='Невозможно подключить дополнительную обработку из файла.
			|Возможно, она не подходит для этой версии программы.'; 
			|en = 'Cannot attach an additional data processor from a file.
			|It might not be compatible with this application version.'; 
			|pl = 'Nie można włączyć dodatkowego przetwarzania danych z pliku.
			|Może ono nie odpowiadać tej wersji aplikacji.';
			|de = 'Der zusätzliche Prozessor kann nicht aus der Datei aktiviert werden. 
			| Möglicherweise ist er für diese Version der Anwendung nicht geeignet.';
			|ro = 'Procesarea suplimentară din fișier nu poate fi activată.
			|Posibil, ea nu este compatibilă cu versiunea aplicației.';
			|tr = 'Dosyadan ek işlemci etkinleştirilemiyor. 
			|Uygulama sürümü ile uyumlu olmayabilir.'; 
			|es_ES = 'No se puede activar el procesador adicional desde el archivo.
			|Puede ser no apto para esta versión de la aplicación.'");
		EndIf;
		ErrorText = ErrorText + Chars.LF + Chars.LF + NStr("ru = 'Техническая информация:'; en = 'Technical information:'; pl = 'Informacja techniczna:';de = 'Technische Information:';ro = 'Informații tehnice:';tr = 'Teknik bilgi:'; es_ES = 'Información técnica:'") + Chars.LF;
		RegistrationResult.BriefErrorPresentation = BriefErrorDescription(ErrorInformation);
		RegistrationResult.ErrorText = ErrorText + RegistrationResult.BriefErrorPresentation;
		WriteError(Object.Ref, ErrorText + DetailErrorDescription(ErrorInformation));
		Return;
	ElsIf RegistrationParameters.IsReport
		AND Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		WarningText = "";
		
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		OptionsStorageCorrect = ModuleReportsOptions.AdditionalReportOptionsStorageCorrect(
			ExternalObjectMetadata, WarningText);
		
		If Not OptionsStorageCorrect Then 
			WriteWarning(Object.Ref, WarningText);
		EndIf;
	EndIf;
	
	If RegistrationData.Description = Undefined OR RegistrationData.Information = Undefined Then
		If RegistrationData.Description = Undefined Then
			RegistrationData.Description = ExternalObjectMetadata.Presentation();
		EndIf;
		If RegistrationData.Information = Undefined Then
			RegistrationData.Information = ExternalObjectMetadata.Comment;
		EndIf;
	EndIf;
	
	If TypeOf(RegistrationData.Kind) <> Type("EnumRef.AdditionalReportsAndDataProcessorsKinds") Then
		RegistrationData.Kind = Enums.AdditionalReportsAndDataProcessorsKinds[RegistrationData.Kind];
	EndIf;
	
	RegistrationData.Insert("VariantsStorage");
	If RegistrationData.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport
		Or RegistrationData.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		If ExternalObjectMetadata.VariantsStorage <> Undefined Then
			RegistrationData.VariantsStorage = ExternalObjectMetadata.VariantsStorage.Name;
		EndIf;
	EndIf;
	
	RegistrationData.Commands.Columns.Add("StartupOption");
	
	For Each DetailsCommand In RegistrationData.Commands Do
		DetailsCommand.StartupOption = Enums.AdditionalDataProcessorsCallMethods[DetailsCommand.Use];
	EndDo;
	
	#If ThickClientOrdinaryApplication Then
		RegistrationResult.ObjectName = ExternalObjectMetadata.Name;
	#EndIf
EndProcedure

// Displays filling commands in object forms.
Procedure OnDetermineFillingCommandsAttachedToObject(Commands, MOIDs, QuickSearchByMOIDs)
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Ref,
	|	Table.Commands.(
	|		ID,
	|		StartupOption,
	|		Presentation,
	|		ShowNotification,
	|		Hide
	|	),
	|	Table.Purpose.(
	|		RelatedObject
	|	)
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS Table
	|WHERE
	|	Table.Purpose.RelatedObject IN(&MOIDs)
	|	AND Table.Kind = &Kind
	|	AND Table.UseForObjectForm = TRUE
	|	AND Table.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
	|	AND Table.Publication <> VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled)
	|	AND Table.DeletionMark = FALSE";
	Query.SetParameter("MOIDs", MOIDs);
	Query.SetParameter("Kind", Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling);
	If AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Query.Text = StrReplace(Query.Text, "AND Table.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)", "");
	Else
		Query.Text = StrReplace(Query.Text, "AND Table.Publication <> VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Disabled)", "");
	EndIf;
	
	HandlerParametersKeys = "Ref, ID, StartupOption, Presentation, ShowNotification, IsReport";
	FillingForm = Enums.AdditionalDataProcessorsCallMethods.FillingForm;
	
	Table = Query.Execute().Unload();
	For Each ReportOrDataProcessor In Table Do
		If Not IsSuppliedDataProcessor(ReportOrDataProcessor.Ref) Then
			Continue;
		EndIf;
		
		ObjectFillingTypes = New Array;
		For Each AssignmentTableRow In ReportOrDataProcessor.Purpose Do
			Source = QuickSearchByMOIDs[AssignmentTableRow.RelatedObject];
			If Source = Undefined Then
				Continue;
			EndIf;
			AttachableCommands.SupplyTypesArray(ObjectFillingTypes, Source.DataRefType);
		EndDo;
		
		For Each TableRow In ReportOrDataProcessor.Commands Do
			If TableRow.Hide Then
				Continue;
			EndIf;
			Command = Commands.Add();
			Command.Kind            = "ObjectsFilling";
			Command.Presentation  = TableRow.Presentation;
			Command.Importance       = "SeeAlso";
			Command.Order        = 50;
			Command.ChangesSelectedObjects = True;
			If TableRow.StartupOption = FillingForm Then
				Command.Handler  = "AdditionalReportsAndDataProcessors.PopulateCommandHandler";
				Command.WriteMode = "DoNotWrite";
			Else
				Command.Handler  = "AdditionalReportsAndDataProcessorsClient.PopulateCommandHandler";
				Command.WriteMode = "Write";
			EndIf;
			Command.ParameterType = New TypeDescription(ObjectFillingTypes);
			Command.AdditionalParameters = New Structure(HandlerParametersKeys);
			FillPropertyValues(Command.AdditionalParameters, TableRow);
			Command.AdditionalParameters.Ref = ReportOrDataProcessor.Ref;
			Command.AdditionalParameters.IsReport = False;
		EndDo;
	EndDo;
EndProcedure

// Converts a string presentation of a version to a number presentation.
//
Function VersionAsNumber(VersionAsString)
	If IsBlankString(VersionAsString) Or VersionAsString = "0.0.0.0" Then
		Return 0;
	EndIf;
	
	Digit = 0;
	
	Result = 0;
	
	TypeDescriptionNumber = New TypeDescription("Number");
	Balance = VersionAsString;
	PointPosition = StrFind(Balance, ".");
	While PointPosition > 0 Do
		NumberAsString = Left(Balance, PointPosition - 1);
		Number = TypeDescriptionNumber.AdjustValue(NumberAsString);
		Result = Result * 1000 + Number;
		Balance = Mid(Balance, PointPosition + 1);
		PointPosition = StrFind(Balance, ".");
		Digit = Digit + 1;
	EndDo;
	
	Number = TypeDescriptionNumber.AdjustValue(Balance);
	Result = Result * 1000 + Number;
	Digit = Digit + 1;
	
	// The version numbers after the fourth dot are returned after comma.
	// For example, returns 1002003004,005006007 for version "1.2.3.4.5.6.7".
	If Digit > 4 Then
		Result = Result / Pow(1000, Digit - 4);
	EndIf;
	
	Return Result;
EndFunction

#EndRegion
