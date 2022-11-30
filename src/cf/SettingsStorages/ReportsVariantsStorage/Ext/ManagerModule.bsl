///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Reading handler of report option settings.
//
// Parameters:
//   ReportKey        - String - a full name of a report with a point.
//   OptionKey      - String - Report option key.
//   Settings         - Arbitrary     - report option settings.
//   SettingsDetails  - SettingsDetails - Additional details of settings.
//   User      - String           - a name of an infobase user.
//       It is not used, because the "Report options" subsystem does not separate options by their authors.
//       The uniqueness of storage and selection is guaranteed by the uniqueness of pairs of report and options keys .
//
// See also:
//   "SettingsStorageManager.<Storage name>.LoadProcessing" in Syntax Assistant.
//
Procedure LoadProcessing(ReportKey, OptionKey, Settings, SettingsDescription, User)
	If Not ReportsOptionsCached.ReadRight() Then
		Return;
	EndIf;
	
	If TypeOf(ReportKey) = Type("String") Then
		ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			Raise ReportInformation.ErrorText;
		EndIf;
		ReportRef = ReportInformation.Report;
	Else
		ReportRef = ReportKey;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	ReportsOptions.Presentation,
	|	ReportsOptions.Settings
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.VariantKey = &VariantKey");
	
	Query.SetParameter("Report",        ReportRef);
	Query.SetParameter("VariantKey", OptionKey);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If SettingsDescription = Undefined Then
			SettingsDescription = New SettingsDescription;
			SettingsDescription.ObjectKey  = ReportKey;
			SettingsDescription.SettingsKey = OptionKey;
			SettingsDescription.User = User;
		EndIf;
		SettingsDescription.Presentation = Selection.Presentation;
		Settings = Selection.Settings.Get();
	EndIf;
EndProcedure

// Handler of writing report option settings.
//
// Parameters:
//   ReportKey        - String - a full name of a report with a point.
//   OptionKey      - String - Report option key.
//   Settings         - Arbitrary         - report option settings.
//   SettingsDetails  - SettingsDetails     - Additional details of settings.
//   User      - String, Undefined - a name of an infobase user.
//       It is not used, because the "Report options" subsystem does not separate options by their authors.
//       The uniqueness of storage and selection is guaranteed by the uniqueness of pairs of report and options keys .
//
// See also:
//   "SettingsStorageManager.<Storage name>.SaveProcessing" in Syntax Assistant.
//
Procedure SaveProcessing(ReportKey, OptionKey, Settings, SettingsDescription, User)
	If Not ReportsOptionsCached.InsertRight() Then
		Raise NStr("ru = 'Недостаточно прав для сохранения вариантов отчетов'; en = 'Insufficient rights to save report options.'; pl = 'Niewystarczające uprawnienia, aby zapisać ustawienia raportu.';de = 'Unzureichende Rechte zum Speichern von Berichtsoptionen.';ro = 'Drepturile insuficiente pentru salvarea opțiunilor pentru rapoarte.';tr = 'Rapor seçeneklerini kaydetmek için yetersiz hak.'; es_ES = 'Insuficientes derechos para guardar las opciones del informe.'");
	EndIf;
	
	ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
	
	If TypeOf(ReportInformation.ErrorText) = Type("String") Then
		Raise ReportInformation.ErrorText;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	ReportsOptions.Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.VariantKey = &VariantKey");
	
	Query.SetParameter("Report",        ReportInformation.Report);
	Query.SetParameter("VariantKey", OptionKey);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	OptionRef = Selection.Ref;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
		LockItem.SetValue("Ref", OptionRef);
		Lock.Lock();
		
		OptionObject = OptionRef.GetObject();
		If TypeOf(Settings) = Type("DataCompositionSettings") Then // For platform.
			Address = CommonClientServer.StructureProperty(Settings.AdditionalProperties, "Address");
			If TypeOf(Address) = Type("String") AND IsTempStorageURL(Address) Then
				Settings = GetFromTempStorage(Address);
			EndIf;
		EndIf;
		OptionObject.Settings = New ValueStorage(Settings);
		If SettingsDescription <> Undefined Then
			OptionObject.Description = SettingsDescription.Presentation;
		EndIf;
		OptionObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Receiving handler of report option settings details.
//
// Parameters:
//   ReportKey       - String - a full name of a report with a point.
//   OptionKey     - String - Report option key.
//   SettingsDetails - SettingsDetails     - Additional details of settings.
//   User     - String, Undefined - a name of an infobase user..
//       It is not used, because the "Report options" subsystem does not separate options by their authors.
//       The uniqueness of storage and selection is guaranteed by the uniqueness of pairs of report and options keys .
//
// See also:
//   "SettingsStorageManager.<Storage name>.GetDescriptionProcessing" in Syntax Assistant.
//
Procedure GetDescriptionProcessing(ReportKey, OptionKey, SettingsDescription, User)
	If Not ReportsOptionsCached.ReadRight() Then
		Return;
	EndIf;
	
	If TypeOf(ReportKey) = Type("String") Then
		ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			Raise ReportInformation.ErrorText;
		EndIf;
		ReportRef = ReportInformation.Report;
	Else
		ReportRef = ReportKey;
	EndIf;
	
	If SettingsDescription = Undefined Then
		SettingsDescription = New SettingsDescription;
	EndIf;
	
	SettingsDescription.ObjectKey  = ReportKey;
	SettingsDescription.SettingsKey = OptionKey;
	
	If TypeOf(User) = Type("String") Then
		SettingsDescription.User = User;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	Variants.Presentation,
	|	Variants.DeletionMark,
	|	Variants.Custom
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|WHERE
	|	Variants.Report = &Report
	|	AND Variants.VariantKey = &VariantKey");
	
	Query.SetParameter("Report",        ReportRef);
	Query.SetParameter("VariantKey", OptionKey);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		SettingsDescription.Presentation = Selection.Presentation;
		SettingsDescription.AdditionalProperties.Insert("DeletionMark", Selection.DeletionMark);
		SettingsDescription.AdditionalProperties.Insert("Custom", Selection.Custom);
	EndIf;
EndProcedure

// Installation handler of report option settings details.
//
// Parameters:
//   ReportKey       - String - a full name of a report with a point.
//   OptionKey     - String - Report option key.
//   SettingsDetails - SettingsDetails - Additional details of settings.
//   User     - String           - a name of an infobase user.
//       It is not used, because the "Report options" subsystem does not separate options by their authors.
//       The uniqueness of storage and selection is guaranteed by the uniqueness of pairs of report and options keys .
//
// See also:
//   "SettingsStorageManager.<Storage name>.SetDescriptionProcessing" in Syntax Assistant.
//
Procedure SetDescriptionProcessing(ReportKey, OptionKey, SettingsDescription, User)
	If Not ReportsOptionsCached.InsertRight() Then
		Raise NStr("ru = 'Недостаточно прав для сохранения вариантов отчетов'; en = 'Insufficient rights to save report options.'; pl = 'Niewystarczające uprawnienia, aby zapisać ustawienia raportu.';de = 'Unzureichende Rechte zum Speichern von Berichtsoptionen.';ro = 'Drepturile insuficiente pentru salvarea opțiunilor pentru rapoarte.';tr = 'Rapor seçeneklerini kaydetmek için yetersiz hak.'; es_ES = 'Insuficientes derechos para guardar las opciones del informe.'");
	EndIf;
	
	If TypeOf(ReportKey) = Type("String") Then
		ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			Raise ReportInformation.ErrorText;
		EndIf;
		ReportRef = ReportInformation.Report;
	Else
		ReportRef = ReportKey;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	Variants.Ref
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|WHERE
	|	Variants.Report = &Report
	|	AND Variants.VariantKey = &VariantKey");
	
	Query.SetParameter("Report",        ReportRef);
	Query.SetParameter("VariantKey", OptionKey);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	OptionRef = Selection.Ref;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
		LockItem.SetValue("Ref", OptionRef);
		Lock.Lock();
		
		OptionObject = OptionRef.GetObject();
		OptionObject.Description = SettingsDescription.Presentation;
		OptionObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

#EndIf

#EndRegion

#Region Private

// CAC:361-off Not all function is wrapped into preprocessor instruction, but only its 
// implementation so it would always return value of the ValueList type.

// Returns a list of user report options.
//
Function GetList(ReportKey, Val User = Undefined) Export // CAC:307 Is an analogue of standard setting storage method
	List = New ValueList;

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
	If TypeOf(ReportKey) = Type("String") Then
		ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			Raise ReportInformation.ErrorText;
		EndIf;
		Report = ReportInformation.Report;
	Else
		Report = ReportKey;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED DISTINCT
	|	Variants.VariantKey,
	|	Variants.Description
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|WHERE
	|	Variants.Report = &Report
	|	AND Variants.Author = &Author
	|	AND Variants.Author.IBUserID = &GUID
	|	AND NOT Variants.DeletionMark
	|	AND Variants.Custom");
	
	Query.SetParameter("Report", Report);
	
	If User = "" Then
		User = Users.UnspecifiedUserRef();
	ElsIf User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	If TypeOf(User) = Type("CatalogRef.Users") Then
		Query.SetParameter("Author", User);
		Query.Text = StrReplace(Query.Text, "AND Variants.Author.IBUserID = &GUID", "");
	Else
		If TypeOf(User) = Type("UUID") Then
			UserID = User;
		Else
			If TypeOf(User) = Type("String") Then
				SetPrivilegedMode(True);
				InfobaseUser = InfoBaseUsers.FindByName(User);
				SetPrivilegedMode(False);
				If InfobaseUser = Undefined Then
					Return List;
				EndIf;
			ElsIf TypeOf(User) = Type("InfoBaseUser") Then
				InfobaseUser = User;
			Else
				Return List;
			EndIf;
			UserID = InfobaseUser.UUID;
		EndIf;
		Query.SetParameter("GUID", UserID);
		Query.Text = StrReplace(Query.Text, "AND Variants.Author = &Author", "");
	EndIf;
	
	ReportOptionsTable = Query.Execute().Unload();
	For Each TableRow In ReportOptionsTable Do
		List.Add(TableRow.VariantKey, TableRow.Description);
	EndDo;
#EndIf

	Return List;
EndFunction

// CAC:361-on

Procedure Delete(ReportKey, OptionKey, Val User) Export
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	Variants.Ref
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|WHERE
	|	Variants.Report = &Report
	|	AND Variants.Author = &Author
	|	AND Variants.Author.IBUserID = &GUID
	|	AND Variants.VariantKey = &VariantKey
	|	AND NOT Variants.DeletionMark
	|	AND Variants.Custom";
	
	Query = New Query;
	
	If ReportKey = Undefined Then
		QueryText = StrReplace(QueryText, "Variants.Report = &Report", "TRUE");
	Else
		ReportInformation = ReportsOptions.GenerateReportInformationByFullName(ReportKey);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			Raise ReportInformation.ErrorText;
		EndIf;
		Query.SetParameter("Report", ReportInformation.Report);
	EndIf;
	
	If OptionKey = Undefined Then
		QueryText = StrReplace(QueryText, "AND Variants.VariantKey = &VariantKey", "");
	Else
		Query.SetParameter("VariantKey", OptionKey);
	EndIf;
	
	If User = "" Then
		User = Users.UnspecifiedUserRef();
	EndIf;
	
	If User = Undefined Then
		QueryText = StrReplace(QueryText, "AND Variants.Author = &Author", "");
		QueryText = StrReplace(QueryText, "AND Variants.Author.IBUserID = &GUID", "");
		
	ElsIf TypeOf(User) = Type("CatalogRef.Users") Then
		Query.SetParameter("Author", User);
		QueryText = StrReplace(QueryText, "AND Variants.Author.IBUserID = &GUID", "");
		
	Else
		If TypeOf(User) = Type("UUID") Then
			UserID = User;
		Else
			If TypeOf(User) = Type("String") Then
				SetPrivilegedMode(True);
				InfobaseUser = InfoBaseUsers.FindByName(User);
				SetPrivilegedMode(False);
				If InfobaseUser = Undefined Then
					Return;
				EndIf;
			ElsIf TypeOf(User) = Type("InfoBaseUser") Then
				InfobaseUser = User;
			Else
				Return;
			EndIf;
			UserID = InfobaseUser.UUID;
		EndIf;
		Query.SetParameter("GUID", UserID);
		QueryText = StrReplace(QueryText, "AND Variants.Author = &Author", "");
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		OptionObject = Selection.Ref.GetObject();
		OptionObject.SetDeletionMark(True);
	EndDo;
	
#EndIf
EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function AddExternalReportOptions(ReportOptions, FullReportName, NameOfReport) Export 
	Try
		ReportObject = ReportsServer.ReportObject(FullReportName);
	Except
		MessageTemplate = NStr("ru = 'Не удалось получить список предопределенных вариантов внешнего отчета ""%1"":%2%3'; en = 'Failed to get the list of predefined options of external report %1: %2%3'; pl = 'Uzyskanie listy predefiniowanych ustawień raportu zewnętrznego ""%1"":%2%3 nie powiodło się:';de = 'Eine Liste der vordefinierten externen Berichtsoptionen konnte nicht abgerufen werden ""%1"":%2%3';ro = 'Eșec la obținerea listei variantelor predefinite ale raportului extern ""%1"":%2%3';tr = 'Harici raporun önceden tanımlanmış seçeneklerinin listesi alınamadı ""%1"":%2%3'; es_ES = 'No se ha podido recibir la lista de opciones predeterminados del informe externo ""%1"":%2%3'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, NameOfReport, Chars.LF, DetailErrorDescription(ErrorInfo()));
		ReportsOptions.WriteToLog(EventLogLevel.Error, Message, FullReportName);
		
		Return False;
	EndTry;
	
	If ReportObject.DataCompositionSchema = Undefined Then
		Return False;
	EndIf;
	
	For Each DCSettingsOption In ReportObject.DataCompositionSchema.SettingVariants Do
		Option = ReportOptions.Add();
		Option.Custom = False;
		Option.Description = DCSettingsOption.Presentation;
		Option.VariantKey = DCSettingsOption.Name;
		Option.AvailableToAuthorOnly = False;
		Option.CurrentUserAuthor = False;
		Option.Order = 1;
		Option.PictureIndex = 5;
	EndDo;
	
	Return True;
EndFunction

#EndIf

#EndRegion