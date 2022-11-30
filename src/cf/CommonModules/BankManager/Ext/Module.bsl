///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets data from the BankClassifier catalog by BIC and a correspondent bank account number values.
// 
// Parameters:
//  BIC          - String - the bank identifier code.
//  CorrAccount     - String - a corresponding bank account number.
//  RecordAboutBank - CatalogRef, String - (returned) a found bank.
Procedure GetClassifierData(BIC = "", CorrAccount = "", RecordAboutBank = "") Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Parameters = New Structure;
		Parameters.Insert("BIC", BIC);
		Parameters.Insert("CorrAccount", CorrAccount);
		Parameters.Insert("RecordAboutBank", RecordAboutBank);
		StandardProcessing = True;
		DataProcessors[DataProcessorName].OnGetClassifierData(Parameters, StandardProcessing);
		If Not StandardProcessing Then
			BIC = Parameters.BIC;
			CorrAccount = Parameters.CorrAccount;
			RecordAboutBank = Parameters.RecordAboutBank;
			Return;
		EndIf;
	EndIf;
	
	If Not IsBlankString(BIC) Then
		RecordAboutBank = Catalogs.BankClassifier.FindByCode(BIC);
	ElsIf Not IsBlankString(CorrAccount) Then
		RecordAboutBank = Catalogs.BankClassifier.FindByAttribute("CorrAccount", CorrAccount);
	Else
		RecordAboutBank = "";
	EndIf;
	If RecordAboutBank = Catalogs.BankClassifier.EmptyRef() Then
		RecordAboutBank = "";
	EndIf;
	
EndProcedure

// Returns text comment on a reason a bank is marked as inactive.
//
// Parameters:
//  Bank - CatalogRef.BankClassifier - the bank to get the text comment for.
//
// Returns:
//  FormattedString - the comment.
//
Function InvalidBankNote(Bank) Export
	
	BankDescription = Common.ObjectAttributeValue(Bank, "Description");
	
	QueryText =
	"SELECT
	|	BankClassifier.Ref,
	|	BankClassifier.Code AS BIC
	|FROM
	|	Catalog.BankClassifier AS BankClassifier
	|WHERE
	|	BankClassifier.Ref <> &Ref
	|	AND BankClassifier.Description = &Description
	|	AND NOT BankClassifier.OutOfBusiness";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Bank);
	Query.SetParameter("Description", BankDescription);
	Selection = Query.Execute().Select();
	
	NewBankDetails = Undefined;
	If Selection.Next() Then
		NewBankDetails = New Structure("Ref, BIC", Selection.Ref, Selection.BIC);
	EndIf;
	
	If ValueIsFilled(Bank) AND ValueIsFilled(NewBankDetails) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'БИК банка изменился на <a href = ""%1"">%2</a>'; en = 'BIC was changed to <a href = ""%1"">%2</a>'; pl = 'Zmieniono BIC banku na <a href = ""%1"">%2</a>';de = 'Bank BIC geändert zu <a href = ""%1"">%2</a>';ro = 'BIC bancă s-a schimbat la <a href = ""%1"">%2</a>';tr = 'Banka BIC <a href = ""%1"">%2</a> olarak değiştirildi'; es_ES = 'BIC del banco se ha cambiado <a href = ""%1"">%2</a>'"),
			GetURL(NewBankDetails.Ref), NewBankDetails.BIC);
	Else
		Result = NStr("ru = 'Деятельность банка прекращена'; en = 'Bank activity is ceased'; pl = 'Działalność banku została zakończona';de = 'Banktätigkeit wurde beendet';ro = 'Activitatea băncii a încetat';tr = 'Banka aktivitesi durdurulmuştur'; es_ES = 'Actividad bancaria cesada'");
	EndIf;
	
	Return StringFunctionsClientServer.FormattedString(Result);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use GetClassifierData() instead.
// Gets data from the BankClassifier catalog by BIC and a correspondent bank account number values.
// 
// Parameters:
//  BIC          - String - the bank identifier code.
//  CorrAccount     - String - a corresponding bank account number.
//  RecordAboutBank - CatalogRef, String - (returned) a found bank.
Procedure GetNationalClassifierData(BIC = "", CorrAccount = "", RecordAboutBank = "") Export
	GetClassifierData(BIC, CorrAccount, RecordAboutBank);
EndProcedure

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Metadata.DataProcessors.Find("ImportBankClassifier") <> Undefined Then
		DataProcessors["ImportBankClassifier"].OnAddUpdateHandlers(Handlers);
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Import to BankClassifier is denied.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.BankClassifier.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.BankClassifier.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForSystemUsersOnly.
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.AddEditBanks.Name);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		DataProcessors[DataProcessorName].OnDefineScheduledJobSettings(Dependencies);
	EndIf;
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefsMapOnImport. 
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.BankClassifier);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) = Undefined Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Common.DataSeparationEnabled() // Automatic update in SaaS mode.
		Or Common.IsSubordinateDIBNode() // The distributed infobase node is updated automatically.
		Or Not AccessRight("Update", Metadata.Catalogs.BankClassifier)
		Or ModuleToDoListServer.UserTaskDisabled("BankClassifier") Then
		Return;
	EndIf;
	
	Result = DataProcessors[DataProcessorName].BankClassifierRelevance();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.BankClassifier.FullName());
	
	For Each Section In Sections Do
		
		IdentifierBanks = "BankClassifier" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = IdentifierBanks;
		ToDoItem.HasToDoItems       = Result.ClassifierOutdated;
		ToDoItem.Important         = Result.ClassifierExpired;
		ToDoItem.Presentation  = NStr("ru = 'Классификатор банков устарел'; en = 'Bank classifier is outdated'; pl = 'Klasyfikator bankowy jest nieaktualny';de = 'Bank-Klassifikator ist veraltet';ro = 'Bank classifier is outdated';tr = 'Banka sınıflandırıcı zaman aşımına uğramış'; es_ES = 'Clasificador de bancos está desactualizado'");
		ToDoItem.ToolTip      = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Последнее обновление %1 назад'; en = 'The last update was %1 ago.'; pl = 'Ostatnia aktualizacja miała miejsce %1 temu';de = 'Letzte Aktualisierung war vor %1';ro = 'Ultima actualizare a fost %1 în urmă';tr = 'Son güncelleme %1önceydi'; es_ES = 'Última actualización se ha hecho hace %1'"), Result.ExpiredPeriodString);
		ToDoItem.Form          = "DataProcessor.ImportBankClassifier.Form.ImportClassifier";
		ToDoItem.FormParameters = New Structure("OpeningFromList", True);
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OutputMessageOnInvalidity = (
		Not Common.DataSeparationEnabled() // Automatic update in SaaS mode.
		AND Not Common.IsSubordinateDIBNode() // The distributed infobase node is updated automatically.
		AND AccessRight("Update", Metadata.Catalogs.BankClassifier) //  A user with sufficient rights.
		AND Not ClassifierUpToDate()); // Classifier is already updated.
	
	EnableNotifications = Not Common.SubsystemExists("StandardSubsystems.ToDoList");
	BankOperationsOverridable.OnDetermineIfOutdatedClassifierWarningRequired(EnableNotifications);
	
	Parameters.Insert("Banks", New FixedStructure("OutputMessageOnInvalidity", (OutputMessageOnInvalidity AND EnableNotifications)));
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	PermissionRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions()));
	
EndProcedure

// See OnlineSupportOverridable.OnSaveOnlineSupportUserAuthenticationData. 
Procedure OnSaveOnlineSupportUserAuthenticationData(UserData) Export
	
	If Metadata.DataProcessors.Find("ImportBankClassifier") <> Undefined Then
		DataProcessors["ImportBankClassifier"].OnSaveOnlineSupportUserAuthenticationData(UserData);
	EndIf;
	
EndProcedure

// See OnlineSupportOverridable.OnDeleteOnlineSupportUserAuthenticationData. 
Procedure OnDeleteOnlineSupportUserAuthenticationData() Export
	
	If Metadata.DataProcessors.Find("ImportBankClassifier") <> Undefined Then
		DataProcessors["ImportBankClassifier"].OnDeleteOnlineSupportUserAuthenticationData();
	EndIf;
	
EndProcedure


#EndRegion

#Region Private

// Returns a list of permissions required to import a bank classifier.
//
// Returns:
//  An array.
//
Function Permissions()
	
	Permissions = New Array;
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		DataProcessors[DataProcessorName].AddPermissions(Permissions);
	EndIf;
	
	Return Permissions;
	
EndFunction

Procedure ImportBankClassifier() Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		DataProcessors[DataProcessorName].ImportBankClassifier();
	EndIf;
	
EndProcedure

// Determines if classifier data update is necessary.
//
Function ClassifierUpToDate() Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Return DataProcessors[DataProcessorName].ClassifierUpToDate();
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion
