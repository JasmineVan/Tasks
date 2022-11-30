///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, Metadata.Reports.ExternalResourcesInUse, "");
	OptionSettings.Description = NStr("ru = 'Внешние ресурсы, используемые программой и дополнительными модулями'; en = 'External resources that the application and additional modules use'; pl = 'External resources that the application and additional modules use';de = 'External resources that the application and additional modules use';ro = 'External resources that the application and additional modules use';tr = 'External resources that the application and additional modules use'; es_ES = 'External resources that the application and additional modules use'");
	OptionSettings.Details = 
		NStr("ru = 'Интернет-ресурсы, внешние компоненты, COM-классы и прочее.
		           |Параметры окружения, которые помогут администратору
		           |выполнить настройку компьютера и провести аудит безопасности.'; 
		           |en = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.'; 
		           |pl = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.';
		           |de = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.';
		           |ro = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.';
		           |tr = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.'; 
		           |es_ES = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.'");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("ru = 'Имя и идентификатор COM-класса
		           |Имя компьютера
		           |Адрес
		           |Чтение данных
		           |Запись данных
		           |Имя макета или файла компоненты
		           |Контрольная сумма
		           |Шаблон командной строки
		           |Протокол
		           |Адрес Интернет-ресурса
		           |Порт'; 
		           |en = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port'; 
		           |pl = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port';
		           |de = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port';
		           |ro = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port';
		           |tr = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port'; 
		           |es_ES = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Write data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port'");
	
	// Filters and parameters are not available for the report.
	OptionSettings.SearchSettings.FilterParameterDescriptions = "#";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// For internal use only.
//
Function RequestsForPermissionsToUseExternalResoursesPresentation(Val AdministrationOperations, Val PermissionsToAddDetails, Val PermissionsToDeleteDetails, Val AsRequired = False) Export
	
	Template = GetTemplate("PermissionsPresentations");
	OffsetArea = Template.GetArea("Indent");
	SpreadsheetDocument = New SpreadsheetDocument();
	
	AllProgramModules = New Map();
	
	For Each Details In AdministrationOperations Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Details.ModuleType, Details.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each Details In PermissionsToAddDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Details.ModuleType, Details.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each Details In PermissionsToDeleteDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Details.ModuleType, Details.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	ModulesTable = New ValueTable();
	ModulesTable.Columns.Add("ProgramModule", Common.AllRefsTypeDetails());
	ModulesTable.Columns.Add("IsConfiguration", New TypeDescription("Boolean"));
	
	For Each KeyAndValue In AllProgramModules Do
		Row = ModulesTable.Add();
		Row.ProgramModule = KeyAndValue.Key;
		Row.IsConfiguration = (KeyAndValue.Key = Catalogs.MetadataObjectIDs.EmptyRef());
	EndDo;
	
	ModulesTable.Sort("IsConfiguration DESC");
	
	For Each ModulesTableRow In ModulesTable Do
		
		SpreadsheetDocument.Put(OffsetArea);
		
		Properties = SafeModeManagerInternal.PropertiesForPermissionRegister(
			ModulesTableRow.ProgramModule);
		
		Filter = New Structure();
		Filter.Insert("ModuleType", Properties.Type);
		Filter.Insert("ModuleID", Properties.ID);
		
		GenerateOperationsPresentation(SpreadsheetDocument, Template, AdministrationOperations.FindRows(Filter));
		
		IsConfigurationProfile = (Properties.Type= Catalogs.MetadataObjectIDs.EmptyRef());
		
		If IsConfigurationProfile Then
			
			Dictionary = ConfigurationModuleDictionary();
			ModuleDescription = Metadata.Synonym;
			
		Else
			
			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Properties.Type, Properties.ID);
			
			ExternalModuleManager = SafeModeManagerInternal.ExternalModuleManager(ProgramModule);
			
			Dictionary = ExternalModuleManager.ExternalModuleContainerDictionary();
			Icon = ExternalModuleManager.ExternalModuleIcon(ProgramModule);
			ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
			
		EndIf;
		
		ItemsToAdd = PermissionsToAddDetails.Copy(Filter);
		If ItemsToAdd.Count() > 0 Then
			
			If AsRequired Then
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Для %1 ""%2"" требуется использование следующих внешних ресурсов:'; en = '%2 %1 requires the following external resources:'; pl = '%2 %1 requires the following external resources:';de = '%2 %1 requires the following external resources:';ro = '%2 %1 requires the following external resources:';tr = '%2 %1 requires the following external resources:'; es_ES = '%2 %1 requires the following external resources:'"),
					Lower(Dictionary.GenitiveCase),
					ModuleDescription);
				
			Else
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Для %1 ""%2"" будут предоставлены следующие разрешения на использование внешних ресурсов:'; en = 'The following permissions to use external resources will be granted for %2 %1:'; pl = 'The following permissions to use external resources will be granted for %2 %1:';de = 'The following permissions to use external resources will be granted for %2 %1:';ro = 'The following permissions to use external resources will be granted for %2 %1:';tr = 'The following permissions to use external resources will be granted for %2 %1:'; es_ES = 'The following permissions to use external resources will be granted for %2 %1:'"),
					Lower(Dictionary.GenitiveCase),
					ModuleDescription);
				
			EndIf;
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Icon"] = Icon;
				
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			SpreadsheetDocument.Put(OffsetArea);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, ItemsToAdd, AsRequired);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		PermissionsToDelete = PermissionsToDeleteDetails.Copy(Filter);
		If PermissionsToDelete.Count() > 0 Then
			
			If AsRequired Then
				Raise NStr("ru = 'Некорректный запрос разрешений'; en = 'Incorrect permission request'; pl = 'Incorrect permission request';de = 'Incorrect permission request';ro = 'Incorrect permission request';tr = 'Incorrect permission request'; es_ES = 'Incorrect permission request'");
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Будут удалены следующие ранее предоставленные для %1 ""%2"" разрешения на использование внешних ресурсов:'; en = 'The following granted permissions to use external resources will be removed for %2 %1:'; pl = 'The following granted permissions to use external resources will be removed for %2 %1:';de = 'The following granted permissions to use external resources will be removed for %2 %1:';ro = 'The following granted permissions to use external resources will be removed for %2 %1:';tr = 'The following granted permissions to use external resources will be removed for %2 %1:'; es_ES = 'The following granted permissions to use external resources will be removed for %2 %1:'"),
					Lower(Dictionary.GenitiveCase),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Icon"] = Icon;
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, PermissionsToDelete, False);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		If ItemsToAdd.Count() > 0 Or PermissionsToDelete.Count() > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Generates a presentation of external resource permission administration operations.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument, in which an operation presentation will be displayed,
//  Template - SpreadsheetDocument received from the PermissionsPresentations report template,
//  AdministrationOperations - ValueTable, see
//                              DataProcessors.ExternalResourcesPermissionsSetup.AdministrationOperationsInRequests().
//
Procedure GenerateOperationsPresentation(SpreadsheetDocument, Val Template, Val AdministrationOperations)
	
	For Each Details In AdministrationOperations Do
		
		If Details.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			
			IsConfigurationProfile = (Details.ModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
			
			If IsConfigurationProfile Then
				
				Dictionary = ConfigurationModuleDictionary();
				ModuleDescription = Metadata.Synonym;
				
			Else
				
				ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
					Details.ModuleType, Details.ModuleID);
				Dictionary = SafeModeManagerInternal.ExternalModuleManager(ProgramModule).ExternalModuleContainerDictionary();
				ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
				
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Будет удален профиль безопасности для %1 ""%2"".'; en = 'Security profile will be deleted for %2 %1.'; pl = 'Security profile will be deleted for %2 %1.';de = 'Security profile will be deleted for %2 %1.';ro = 'Security profile will be deleted for %2 %1.';tr = 'Security profile will be deleted for %2 %1.'; es_ES = 'Security profile will be deleted for %2 %1.'"),
					Lower(Dictionary.GenitiveCase),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
			EndIf;
			Area.Parameters["Icon"] = PictureLib.Delete;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.PutHorizontalPageBreak();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates a permission presentation.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a document, in which an operation presentation will be displayed,
//  PermissionsSets - Structure - see DataProcessors.ExternalResourcesPermissionsSetup. PermissionsTables(),
//  Template - SpreadsheetDocument - a document received from the PermissionsPresentations report template,
//  AsRequired - Boolean - indicates whether terms of "the following resources are required" kind are used in the presentation instead of
//                          "the following resources will be granted."
//
Procedure GeneratePermissionsPresentation(Val SpreadsheetDocument, Val Template, Val PermissionsSets, Val AsRequired = False)
	
	OffsetArea = Template.GetArea("Indent");
	
	Types = PermissionsSets.Copy();
	Types.GroupBy("Type");
	Types.Columns.Add("Order", New TypeDescription("Number"));
	
	SortingOrder = PermissionsTypesSortingOrder();
	For Each TypeRow In Types Do
		TypeRow.Order = SortingOrder[TypeRow.Type];
	EndDo;
	
	Types.Sort("Order ASC");
	
	For Each TypeRow In Types Do
		
		PermissionType = TypeRow.Type;
		
		Filter = New Structure();
		Filter.Insert("Type", TypeRow.Type);
		PermissionsRows = PermissionsSets.FindRows(Filter);
		
		Count = 0;
		For Each PermissionsRow In PermissionsRows Do
			Count = Count + PermissionsRow.Permissions.Count();
		EndDo;
		
		If Count > 0 Then
			
			GroupArea = Template.GetArea("Group" + PermissionType);
			FillPropertyValues(GroupArea.Parameters, New Structure("Count", Count));
			SpreadsheetDocument.Put(GroupArea);
			
			SpreadsheetDocument.StartRowGroup(PermissionType, True);
			
			HeaderArea = Template.GetArea("Header" + PermissionType);
			SpreadsheetDocument.Put(HeaderArea);
			
			RowArea = Template.GetArea("Row" + PermissionType);
			
			For Each PermissionsRow In PermissionsRows Do
				
				For Each KeyAndValue In PermissionsRow.Permissions Do
					
					Permission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
					
					If PermissionType = "AttachAddin" Then
						
						FillPropertyValues(RowArea.Parameters, Permission);
						SpreadsheetDocument.Put(RowArea);
						
						SpreadsheetDocument.StartRowGroup(Permission.TemplateName);
						
						PermissionAddition = PermissionsRow.PermissionsAdditions.Get(KeyAndValue.Key);
						If PermissionAddition = Undefined Then
							PermissionAddition = New Structure();
						Else
							PermissionAddition = Common.ValueFromXMLString(PermissionAddition);
						EndIf;
						
						For Each AdditionKeyAndValue In PermissionAddition Do
							
							FileRowArea = Template.GetArea("AttachAddinRowAdditional");
							
							FillPropertyValues(FileRowArea.Parameters, AdditionKeyAndValue);
							SpreadsheetDocument.Put(FileRowArea);
							
						EndDo;
						
						SpreadsheetDocument.EndRowGroup();
						
					Else
						
						PermissionAddition = New Structure();
						
						If PermissionType = "FileSystemAccess" Then
							
							If Permission.Path = "/temp" Then
								PermissionAddition.Insert("Path", NStr("ru = 'Каталог временных файлов'; en = 'Temporary directory'; pl = 'Temporary directory';de = 'Temporary directory';ro = 'Temporary directory';tr = 'Temporary directory'; es_ES = 'Temporary directory'"));
							EndIf;
							
							If Permission.Path = "/bin" Then
								PermissionAddition.Insert("Path", NStr("ru = 'Каталог, в который установлен сервер 1С:Предприятия'; en = '1C:Enterprise server installation directory'; pl = '1C:Enterprise server installation directory';de = '1C:Enterprise server installation directory';ro = '1C:Enterprise server installation directory';tr = '1C:Enterprise server installation directory'; es_ES = '1C:Enterprise server installation directory'"));
							EndIf;
							
						EndIf;
						
						FillPropertyValues(RowArea.Parameters, Permission);
						FillPropertyValues(RowArea.Parameters, PermissionAddition);
						
						SpreadsheetDocument.Put(RowArea);
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			SpreadsheetDocument.EndRowGroup();
			
			SpreadsheetDocument.Put(OffsetArea);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
//
Function PermissionsTypesSortingOrder()
	
	Result = New Structure();
	
	Result.Insert("InternetResourceAccess", 1);
	Result.Insert("FileSystemAccess", 2);
	Result.Insert("AttachAddin", 3);
	Result.Insert("CreateComObject", 4);
	Result.Insert("RunApplication", 5);
	Result.Insert("ExternalModule", 6);
	Result.Insert("ExternalModulePrivilegedModeAllowed", 7);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a dictionary of configuration properties.
//
// Returns - Structure:
//                         * Nominative - a module kind synonym in the nominative case.
//                         * Genitive - a module kind synonym in the genitive case.
//
Function ConfigurationModuleDictionary()
	
	Result = New Structure();
	
	Result.Insert("NominativeCase", NStr("ru = 'Программа'; en = 'Application'; pl = 'Application';de = 'Application';ro = 'Application';tr = 'Application'; es_ES = 'Application'"));
	Result.Insert("GenitiveCase", NStr("ru = 'Программы'; en = 'Applications'; pl = 'Applications';de = 'Applications';ro = 'Applications';tr = 'Applications'; es_ES = 'Applications'"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf