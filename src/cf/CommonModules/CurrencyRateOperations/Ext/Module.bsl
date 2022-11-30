///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Adds currencies from the classifier to the currency catalog.
//
// Parameters:
//   Codes - Array - numeric codes for the currencies to be added.
//
// Returns:
//   Array, CatalogRef.Currencies - references to the created currencies.
//
Function AddCurrenciesByCode(Val Codes) Export
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		Result = DataProcessors["ImportCurrenciesRates"].AddCurrenciesByCode(Codes);
	Else
		Result = New Array();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a currency rate for a specific date.
//
// Parameters:
//   Currency    - CatalogRef.Currencies - the currency, for which the exchange rate is calculated.
//   RateDate - Date - the date the exchange rate is calculated for.
//
// Returns:
//   Structure - exchange rate parameters:
//    * Rate      - Number - the currency rate as of the specified date.
//    * Repetition - Number - currency rate multiplier as of the specified date.
//    * Currency    - CatalogRef.Currencies - reference to currency.
//    * RateDate - Date - the exchange rate date.
//
Function GetCurrencyRate(Currency, RateDate) Export
	
	Result = InformationRegisters.ExchangeRates.GetLast(RateDate, New Structure("Currency", Currency));
	
	Result.Insert("Currency",    Currency);
	Result.Insert("RateDate", RateDate);
	
	Return Result;
	
EndFunction

// Generates a presentation of an amount of a given currency in words.
//
// Parameters:
//   AmontAsNumber - Number - the amount to be presented in words.
//   Currency - CatalofRef.Currencies - the currency the amount must be presented in.
//   OutputAmountWithoutFractionalPart - Boolean - shows whether the amount presentation contains the fractional part.
//
// Returns:
//   String - the amount in words.
//
Function GenerateAmountInWords(AmountAsNumber, Currency, OutputAmountWithoutFractionalPart = False) Export
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		Result = DataProcessors["ImportCurrenciesRates"].GenerateAmountInWords(AmountAsNumber, Currency, OutputAmountWithoutFractionalPart);
	Else	
		Result = "";
	EndIf;
	Return Result;
	
EndFunction

// Converts an amount from one currency to another.
//
// Parameters:
//  Amount          - Number - the source amount.
//  SourceCurrency - CatalogRef.Currencies - the source currency.
//  NewCurrency    - CatalogRef.Currencies - the new currency.
//  Date           - Date - the exchange rate date.
//
// Returns:
//  Number - the converted amount.
//
Function ConvertToCurrency(Sum, SourceCurrency, NewCurrency, Date) Export
	
	Return CurrenciesExchangeRatesClientServer.ConvertAtRate(Sum,
		GetCurrencyRate(SourceCurrency, Date),
		GetCurrencyRate(NewCurrency, Date));
		
EndFunction

// Used in constructor of the Number for money fields type.
//
// Parameters:
//  AllowedSignOfField - AllowedSign - indicates the allowed sign of a number. Value by default - AllowedSign.Any.
// 
// Returns:
//  TypesDetails - type of a value for a money field.
//
Function MoneyFieldTypeDescription(Val AllowedSignOfField = Undefined) Export
	
	If AllowedSignOfField = Undefined Then
		AllowedSignOfField = AllowedSign.Any;
	EndIf;
	
	If AllowedSignOfField = AllowedSign.Any Then
		Return Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type;
	EndIf;
	
	Return Metadata.DefinedTypes.MonetaryAmountNonNegative.Type;
	
EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	MetadataObject = Metadata.DataProcessors.Find("ImportCurrenciesRates");
	If MetadataObject = Undefined Then
		Return;
	EndIf;

	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Common.DataSeparationEnabled() // Automatic update in SaaS mode.
		Or Common.IsStandaloneWorkplace()
		Or Not AccessRight("Update", Metadata.InformationRegisters.ExchangeRates)
		Or ModuleToDoListServer.UserTaskDisabled("CurrencyClassifier") Then
		Return;
	EndIf;
	
	RatesUpToDate = RatesUpToDate();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(MetadataObject.FullName());
	
	For Each Section In Sections Do
		
		CurrencyID = "CurrencyClassifier" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = CurrencyID;
		ToDoItem.HasToDoItems       = Not RatesUpToDate;
		ToDoItem.Presentation  = NStr("ru = 'Курсы валют устарели'; en = 'Outdated exchange rates'; pl = 'Kursy wymiany walut są nieaktualne';de = 'Wechselkurse sind veraltet';ro = 'Ratele valutare sunt vechi';tr = 'Döviz kurları güncel değil'; es_ES = 'Tipos de cambio están desactualizados'");
		ToDoItem.Important         = True;
		ToDoItem.Form          = "DataProcessor.ImportCurrenciesRates.Form";
		ToDoItem.FormParameters = New Structure("OpeningFromList", True);
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Import to the currency classifier is denied.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.Currencies.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.Currencies.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].OnDefineScheduledJobSettings(Dependencies);
	EndIf;
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadCurrencyRates.Name);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Common.DataSeparationEnabled() Or Common.IsStandaloneWorkplace() Then
		RatesUpdatedByEmployeesResponsible = False; // Automatic update in SaaS mode.
	ElsIf NOT AccessRight("Update", Metadata.InformationRegisters.ExchangeRates) Then
		RatesUpdatedByEmployeesResponsible = False; // The user cannot update currency rates.
	Else
		RatesUpdatedByEmployeesResponsible = RatesImportedFromInternet(); // There are currencies whose rates can be imported.
	EndIf;
	
	EnableNotifications = Not Common.SubsystemExists("StandardSubsystems.ToDoList");
	CurrenciesExchangeRatesOverridable.OnDetermineWhetherCurrencyRateUpdateWarningRequired(EnableNotifications);
	
	Parameters.Insert("Currencies", New FixedStructure("RatesUpdatedByEmployeesResponsible", (RatesUpdatedByEmployeesResponsible AND EnableNotifications)));
	
EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(Array) Export
	
	Array.Add(Metadata.InformationRegisters.ExchangeRates.FullName());
	
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

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.4.4";
	Handler.Procedure = "CurrencyRateOperations.UpdateCurrencyInformation937";
	Handler.ExecutionMode = "Exclusive";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.3.10";
	Handler.Procedure = "CurrencyRateOperations.FillCurrencyRateSettingMethod";
	Handler.ExecutionMode = "Exclusive";
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].OnAddUpdateHandlers(Handlers);
	EndIf;
	
EndProcedure

Procedure ConvertCurrencyLinks() Export
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].ConvertCurrencyLinks();
	EndIf;
EndProcedure

// See OnlineSupportOverridable.OnSaveOnlineSupportUserAuthenticationData. 
Procedure OnSaveOnlineSupportUserAuthenticationData(UserData) Export
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].OnSaveOnlineSupportUserAuthenticationData(UserData);
	EndIf;
	
EndProcedure

// See OnlineSupportOverridable.OnDeleteOnlineSupportUserAuthenticationData. 
Procedure OnDeleteOnlineSupportUserAuthenticationData() Export
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].OnDeleteOnlineSupportUserAuthenticationData();
	EndIf;
	
EndProcedure

// Checks whether the exchange rate and multiplier as of January 1, 1980, are available.
// If they are not available, sets them both to one.
//
// Parameters:
//  Currency - a reference to a Currencies catalog item.
//
Procedure CheckCurrencyRateAvailabilityFor01_01_1980(Currency) Export
	
	RateDate = Date("19800101");
	RateStructure = InformationRegisters.ExchangeRates.GetLast(RateDate, New Structure("Currency", Currency));
	
	If (RateStructure.Rate = 0) Or (RateStructure.Repetition = 0) Then
		RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
		RecordSet.Filter.Currency.Set(Currency);
		RecordSet.Filter.Period.Set(RateDate);
		Record = RecordSet.Add();
		Record.Currency = Currency;
		Record.Period = RateDate;
		Record.Rate = 1;
		Record.Repetition = 1;
		RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ImportActualRate(ImportParameters = Undefined, ResultAddress = Undefined) Export
	
	If Metadata.DataProcessors.Find("ImportCurrenciesRates") <> Undefined Then
		DataProcessors["ImportCurrenciesRates"].ImportActualRate(ImportParameters, ResultAddress);
	EndIf;
	
EndProcedure

// Returns a list of permissions to import currency rates from the 1C website.
//
// Returns:
//  Array.
//
Function Permissions()
	
	Permissions = New Array;
	DataProcessorName = "ImportCurrenciesRates";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		DataProcessors[DataProcessorName].AddPermissions(Permissions);
	EndIf;
	
	Return Permissions;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Internal export procedures and functions.

// Returns an array of currencies whose rates are imported from the 1C website.
//
Function CurrenciesToImport() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND NOT Currencies.DeletionMark
	|
	|ORDER BY
	|	Currencies.DescriptionFull";

	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns a currency rate by a currency reference.
// Returns data as a structure.
//
// Parameters:
//   SelectedCurrency - Catalog.Currencies / Reference - reference to the currency to find out the 
//                  rate for.
//
// Returns:
//   RateData   - structure describing the most recent rate record.
//                 
//
Function FillCurrencyRateData(SelectedCurrency) Export
	
	RateData = New Structure("RateDate, Rate, Repetition");
	
	Query = New Query;
	
	Query.Text = "SELECT RegRates.Period, RegRates.Rate, RegRates.Repetition
	              | FROM InformationRegister.ExchangeRates.SliceLast(&ImportPeriodEnd, Currency = &SelectedCurrency) AS RegRates";
	Query.SetParameter("SelectedCurrency", SelectedCurrency);
	Query.SetParameter("ImportPeriodEnd", CurrentSessionDate());
	
	SelectionRate = Query.Execute().Select();
	SelectionRate.Next();
	
	RateData.RateDate = SelectionRate.Period;
	RateData.Rate      = SelectionRate.Rate;
	RateData.Repetition = SelectionRate.Repetition;
	
	Return RateData;
	
EndFunction

// Returns a value table containing currencies depending on the one set as the parameter.
// 
// Returns
//   ValueTable column "Reference" - CatalogRef.Currencies column "Markup" - number.
//   
//   
//
Function DependentCurrenciesList(BaseCurrency, AdditionalProperties = Undefined) Export
	
	Cached = (TypeOf(AdditionalProperties) = Type("Structure"));
	
	If Cached Then
		
		DependentCurrencies = AdditionalProperties.DependentCurrencies.Get(BaseCurrency);
		
		If TypeOf(DependentCurrencies) = Type("ValueTable") Then
			Return DependentCurrencies;
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CurrencyCatalog.Ref,
	|	CurrencyCatalog.Markup,
	|	CurrencyCatalog.RateSource,
	|	CurrencyCatalog.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CurrencyCatalog
	|WHERE
	|	CurrencyCatalog.MainCurrency = &BaseCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	CurrencyCatalog.Ref,
	|	CurrencyCatalog.Markup,
	|	CurrencyCatalog.RateSource,
	|	CurrencyCatalog.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CurrencyCatalog
	|WHERE
	|	CurrencyCatalog.RateCalculationFormula LIKE &AlphabeticCode";
	
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("AlphabeticCode", "%" + Common.ObjectAttributeValue(BaseCurrency, "Description") + "%");
	
	DependentCurrencies = Query.Execute().Unload();
	
	If Cached Then
		
		AdditionalProperties.DependentCurrencies.Insert(BaseCurrency, DependentCurrencies);
		
	EndIf;
	
	Return DependentCurrencies;
	
EndFunction

Procedure UpdateCurrencyRate(Parameters, ResultAddress) Export
	
	DependentCurrency = Parameters.Currency;
	RateSource = DependentCurrency.RateSource;
	
	CurrenciesList = New Array;
	
	If RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		CurrenciesList.Add(DependentCurrency.MainCurrency);
	ElsIf RateSource = Enums.RateSources.CalculationByFormula Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Currencies.Ref AS Ref
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	&RateCalculationFormula LIKE ""%"" + Currencies.Description + ""%""";
		
		Query.SetParameter("RateCalculationFormula", DependentCurrency.RateCalculationFormula);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			ErrorText = NStr("ru = 'В формуле должна быть использована хотя бы одна основная валюта.'; en = 'The formula must include at least one base currency.'; pl = 'We wzorze należy zastosować co najmniej jedną walutę główną.';de = 'In der Formel muss mindestens eine Hauptwährung verwendet werden.';ro = 'Cel puțin o monedă principală urmează să fie utilizată în formulă.';tr = 'Formülde en az bir ana para birimi kullanılacaktır.'; es_ES = 'Como mínimo una moneda principal tiene que utilizarse en la fórmula.'");
			Common.MessageToUser(ErrorText, , "Object.RateCalculationFormula");
			Raise ErrorText;
		EndIf;
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			CurrenciesList.Add(Selection.Ref);
		EndDo
	EndIf;
	
	QueryText =
	"SELECT
	|	ExchangeRates.Period AS Period,
	|	ExchangeRates.Currency AS Currency
	|FROM
	|	InformationRegister.ExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Currency IN(&Currency)
	|
	|GROUP BY
	|	ExchangeRates.Period,
	|	ExchangeRates.Currency
	|
	|ORDER BY
	|	Period";
	
	Query = New Query(QueryText);
	Query.SetParameter("Currency", CurrenciesList);
	
	Selection = Query.Execute().Select();
	
	UpdatedPeriods = New Map;
	While Selection.Next() Do
		If UpdatedPeriods[Selection.Period] <> Undefined Then 
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			For Each Currency In CurrenciesList Do
				Lock = New DataLock;
				LockItem = Lock.Add("InformationRegister.ExchangeRates");
				LockItem.SetValue("Currency", Currency);
				LockItem.SetValue("Period", Selection.Period);
			EndDo;
			Lock.Lock();
			
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(Selection.Currency);
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Read();
			RecordSet.AdditionalProperties.Insert("UpdateSubordinateCurrencyRate", DependentCurrency);
			RecordSet.AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UpdatedPeriods.Insert(Selection.Period, True);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Updates currency info after the "Amendment 33/2012 ARCC All-Russian Classifier of Currencies.
// OK (MK (ISO 4217) 003-97) 014-2000" document passed and implemented by the decree of Russian Federal Agency for Technical Regulating and Metrology No.1883-st from 12/12/2012).
//
Procedure UpdateCurrencyInformation937() Export
	Currency = Catalogs.Currencies.FindByCode("937");
	If Not Currency.IsEmpty() Then
		Currency = Currency.GetObject();
		Currency.Description = "VEF";
		Currency.DescriptionFull = NStr("ru = 'Боливар'; en = 'Bolivar'; pl = 'Bolivar';de = 'Bolívar';ro = 'Bolivar';tr = 'Bolivar'; es_ES = 'Bolívar'");
		InfobaseUpdate.WriteData(Currency);
	EndIf;
EndProcedure

// Fills in the RateSource attribute for all items of the Currencies catalog.
Procedure FillCurrencyRateSettingMethod() Export
	Selection = Catalogs.Currencies.Select();
	While Selection.Next() Do
		Currency = Selection.Ref.GetObject();
		If Currency.ImportingFromInternet Then
			Currency.RateSource = Enums.RateSources.DownloadFromInternet;
		ElsIf Not Currency.MainCurrency.IsEmpty() Then
			Currency.RateSource = Enums.RateSources.MarkupForOtherCurrencyRate;
		Else
			Currency.RateSource = Enums.RateSources.ManualInput;
		EndIf;
		InfobaseUpdate.WriteData(Currency);
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Currency rates update.

// Checks whether all currency rates are up-to-date.
//
Function RatesUpToDate() Export
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|INTO ttCurrencies
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND Currencies.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	ttCurrencies AS Currencies
	|		LEFT JOIN InformationRegister.ExchangeRates AS ExchangeRates
	|		ON Currencies.Ref = ExchangeRates.Currency
	|			AND (ExchangeRates.Period = &CurrentDate)
	|WHERE
	|	ExchangeRates.Currency IS NULL ";
	
	Query = New Query;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.Text = QueryText;
	
	Return Query.Execute().IsEmpty();
EndFunction

// Determines whether there is at least one currency whose rate can be imported from the internet.
//
Function RatesImportedFromInternet()
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND Currencies.DeletionMark = FALSE";
	Return NOT Query.Execute().IsEmpty();
EndFunction

#EndRegion
