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
	
	ReportSettings.DefineFormSettings = True;

	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanes(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Details = NStr("ru = 'Универсальный отчет по справочникам, документам, регистрам.'; en = 'Universal report on catalogs, documents, and registers.'; pl = 'Uniwersalne sprawozdanie dot. raportów, katalogów, dokumentów, rejestrów.';de = 'Universeller Bericht über Verzeichnisse, Dokumente, Register.';ro = 'Raport universal privind clasificatoarele, documentele, registrele.';tr = 'Kılavuzlar, belgeler, kayıtlar ile ilgili üniversal rapor'; es_ES = 'Informe universal por catálogos, documentos, registros.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

Function ImportSettingsOnChangeParameters() Export 
	Parameters = New Array;
	Parameters.Add(New DataCompositionParameter("MetadataObjectType"));
	Parameters.Add(New DataCompositionParameter("MetadataObjectName"));
	Parameters.Add(New DataCompositionParameter("TableName"));
	
	Return Parameters;
EndFunction

Function FixedParameters(Settings, UserSettings, AvailableValues) Export 
	FixedParameters = New Structure("Period, DataSource, MetadataObjectType, MetadataObjectName, TableName");
	AvailableValues = New Structure("MetadataObjectType, MetadataObjectName, TableName");
	
	SetFixedParameter("Period", FixedParameters, Settings, UserSettings);
	SetFixedParameter("DataSource", FixedParameters, Settings, UserSettings);
	
	AvailableValues.MetadataObjectType = AvailableMetadataObjectsTypes();
	SetFixedParameter(
		"MetadataObjectType",
		FixedParameters,
		Settings, UserSettings,
		AvailableValues.MetadataObjectType);
	
	AvailableValues.MetadataObjectName = AvailableMetadataObjects(
		FixedParameters.MetadataObjectType);
	SetFixedParameter(
		"MetadataObjectName",
		FixedParameters,
		Settings,
		UserSettings,
		AvailableValues.MetadataObjectName);
	
	AvailableValues.TableName = AvailableTables(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	SetFixedParameter(
		"TableName", FixedParameters, Settings, UserSettings, AvailableValues.TableName);
	
	FixedParameters.DataSource = DataSource(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	
	IDs = StrSplit("MetadataObjectType, MetadataObjectName, TableName", ", ", False);
	DataParameters = Settings.DataParameters.Items;
	For Each ID In IDs Do 
		SettingItem = DataParameters.Find(ID);
		If SettingItem = Undefined
			Or SettingItem.Value = FixedParameters[ID] Then 
			Continue;
		EndIf;
		
		Settings.AdditionalProperties.Insert("ReportInitialized", False);
		Break;
	EndDo;
	
	Return FixedParameters;
EndFunction

Procedure SetFixedParameter(ID, Parameters, Settings, UserSettings, AvailableValues = Undefined)
	FixedParameter = Parameters[ID];
	
	If AvailableValues = Undefined Then 
		AvailableValues = New ValueList;
	EndIf;
	
	SettingItem = Settings.DataParameters.Items.Find(ID);
	If SettingItem = Undefined Then 
		If AvailableValues.Count() > 0 Then 
			Parameters[ID] = AvailableValues[0].Value;
		EndIf;
		Return;
	EndIf;
	
	UserSettingItem = Undefined;
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		AND (Settings.AdditionalProperties.Property("ReportInitialized")
		Or UserSettings.AdditionalProperties.Property("ReportInitialized")) Then 
		
		UserSettingItem = UserSettings.Items.Find(
			SettingItem.UserSettingID);
	EndIf;
	
	If UserSettingItem <> Undefined
		AND AvailableValues.FindByValue(UserSettingItem.Value) <> Undefined Then 
		FixedParameter = UserSettingItem.Value;
	ElsIf AvailableValues.FindByValue(SettingItem.Value) <> Undefined Then 
		FixedParameter = SettingItem.Value;
	ElsIf ID = "MetadataObjectName"
		AND ValueIsFilled(Parameters.DataSource) Then 
		FixedParameter = Common.MetadataObjectByID(Parameters.DataSource).Name;
	ElsIf AvailableValues.Count() > 0 Then 
		FixedParameter = AvailableValues[0].Value;
	ElsIf UserSettingItem <> Undefined
		AND ValueIsFilled(UserSettingItem.Value) Then 
		FixedParameter = UserSettingItem.Value;
	ElsIf ValueIsFilled(SettingItem.Value) Then 
		FixedParameter = SettingItem.Value;
	EndIf;
	
	If ID = "MetadataObjectType"
		AND ValueIsFilled(Parameters.DataSource) Then 
		MetadataObject = Common.MetadataObjectByID(Parameters.DataSource);
		MetadataObjectType = Common.BaseTypeNameByMetadataObject(MetadataObject);
		If MetadataObjectType <> FixedParameter Then 
			Parameters.DataSource = Undefined;
		EndIf;
	EndIf;
	
	Parameters[ID] = FixedParameter;
EndProcedure

Procedure SetFixedParameters(Report, FixedParameters, Settings, UserSettings) Export 
	DataParameters = Settings.DataParameters;
	
	AvailableParameters = DataParameters.AvailableParameters;
	If AvailableParameters = Undefined Then 
		Return;
	EndIf;
	
	For Each Parameter In FixedParameters Do 
		If AvailableParameters.Items.Find(Parameter.Key) = Undefined Then 
			Continue;
		EndIf;
		
		SettingItem = DataParameters.Items.Find(Parameter.Key);
		If SettingItem = Undefined Then 
			SettingItem = DataParameters.Items.Add();
			SettingItem.Parameter = New DataCompositionParameter(Parameter.Key);
			SettingItem.Value = Parameter.Value;
			SettingItem.Use = True;
		Else
			DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
		
		UserSettingItem = Undefined;
		If UserSettings <> Undefined Then 
			UserSettingItem = UserSettings.Items.Find(
				SettingItem.UserSettingID);
		EndIf;
		
		If UserSettingItem <> Undefined Then 
			FillPropertyValues(UserSettingItem, SettingItem, "Use, Value");
		EndIf;
	EndDo;
	
	If UserSettings <> Undefined Then 
		UserSettings.AdditionalProperties.Insert("ReportInitialized", True);
	EndIf;
EndProcedure

Function TextOfQueryByMetadata(ReportParameters)
	SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	
	SourceName = SourceMetadata.FullName();
	If ValueIsFilled(ReportParameters.TableName) Then 
		SourceName = SourceName + "." + ReportParameters.TableName;
	EndIf;
	
	SourceFilter = "";
	If ReportParameters.TableName = "BalanceAndTurnovers"
		Or ReportParameters.TableName = "Turnovers" Then
		SourceFilter = "({&BeginOfPeriod}, {&EndOfPeriod}, Auto)";
	ElsIf ReportParameters.TableName = "Balance"
		Or ReportParameters.TableName = "SliceLast" Then
		SourceFilter = "({&EndOfPeriod},)";
	ElsIf ReportParameters.TableName = "SliceFirst" Then
		SourceFilter = "({&BeginOfPeriod},)";
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Tasks"
		Or ReportParameters.MetadataObjectType = "BusinessProcesses" Then
		
		If ValueIsFilled(ReportParameters.TableName)
			AND CommonClientServer.HasAttributeOrObjectProperty(SourceMetadata, "TabularSections")
			AND CommonClientServer.HasAttributeOrObjectProperty(SourceMetadata.TabularSections, ReportParameters.TableName) Then 
			SourceFilter = "
				|{WHERE
				|	(Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		Else
			SourceFilter = "
				|{WHERE
				|	(Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		EndIf;
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters"
		AND SourceMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		SourceFilter = "
			|{WHERE
			|	(Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "AccumulationRegisters"
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		SourceFilter = "
			|{WHERE
			|	(Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		SourceFilter = "
			|{WHERE
			|	RegistrationPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod}";
	EndIf;
	
	QueryText = "
	|SELECT ALLOWED
	|	*
	|FROM
	|	[SourceName] [SourceFilter]
	|";
	QueryTextExpressions = New Structure;
	QueryTextExpressions.Insert("SourceName", SourceName);
	QueryTextExpressions.Insert("SourceFilter", SourceFilter);
	
	Return StringFunctionsClientServer.InsertParametersIntoString(QueryText, QueryTextExpressions);
EndFunction

Function AvailableMetadataObjectsTypes()
	AvailableValues = New ValueList;
	
	If HasMetadataTypeObjects(Metadata.Catalogs) Then
		AvailableValues.Add("Catalogs", NStr("ru = 'Справочник'; en = 'Catalog'; pl = 'Katalog';de = 'Katalog';ro = 'Catalog';tr = 'Katalog'; es_ES = 'Catálogo'"), , PictureLib.Catalog);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Documents) Then
		AvailableValues.Add("Documents", NStr("ru = 'Документ'; en = 'Document'; pl = 'Dokument';de = 'Dokument';ro = 'Document';tr = 'Belge'; es_ES = 'Documento'"), , PictureLib.Document);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.InformationRegisters) Then
		AvailableValues.Add("InformationRegisters", NStr("ru = 'Регистр сведений'; en = 'Information register'; pl = 'Rejestru informacji';de = 'Informationsregister';ro = 'Registrul de informații';tr = 'Bilgi kaydı'; es_ES = 'Registro de información'"), , PictureLib.InformationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccumulationRegisters) Then
		AvailableValues.Add("AccumulationRegisters", NStr("ru = 'Регистр накопления'; en = 'Accumulation register'; pl = 'Rejestru akumulacji';de = 'Akkumulationsregister';ro = 'Registrul de acumulare';tr = 'Birikeç '; es_ES = 'Registro de acumulación'"), , PictureLib.AccumulationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccountingRegisters) Then
		AvailableValues.Add("AccountingRegisters", NStr("ru = 'Регистр бухгалтерии'; en = 'Accounting register'; pl = 'Rejestru księgowego';de = 'Buchhaltungsregister';ro = 'Registrul contabil';tr = 'Muhasebe kaydı'; es_ES = 'Registro de contabilidad'"), , PictureLib.AccountingRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.CalculationRegisters) Then
		AvailableValues.Add("CalculationRegisters", NStr("ru = 'Регистр расчета'; en = 'Calculation register'; pl = 'Rejestr kalkulacji';de = 'Berechnungsregister';ro = 'Registrul de calcul';tr = 'Hesaplama kaydı'; es_ES = 'Registro de cálculos'"), , PictureLib.CalculationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.ChartsOfCalculationTypes) Then
		AvailableValues.Add("ChartsOfCalculationTypes", NStr("ru = 'Планы видов расчета'; en = 'Charts of calculation types'; pl = 'Plany typów obliczeń';de = 'Diagramme der Berechnungstypen';ro = 'Diagrame de tipuri de calcul';tr = 'Hesaplama türleri çizelgeleri'; es_ES = 'Diagramas de los tipos de cálculos'"), , PictureLib.ChartOfCalculationTypes);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Tasks) Then
		AvailableValues.Add("Tasks", NStr("ru = 'Задачи'; en = 'Tasks'; pl = 'Zadania';de = 'Aufgaben';ro = 'Sarcini';tr = 'Görevler'; es_ES = 'Tareas'"), , PictureLib.Task);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.BusinessProcesses) Then
		AvailableValues.Add("BusinessProcesses", NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Business-procese';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'"), , PictureLib.BusinessProcess);
	EndIf;
	
	Return AvailableValues;
EndFunction

Function AvailableMetadataObjects(MetadataObjectType)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType) Then
		Return AvailableValues;
	EndIf;
	
	ValuesToDelete = New ValueList;
	For Each Object In Metadata[MetadataObjectType] Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Object)
			Or Not AccessRight("Read", Object) Then
			Continue;
		EndIf;
		
		If StrStartsWith(Upper(Object.Name), "DELETE") Then 
			ValuesToDelete.Add(Object.Name, Object.Synonym);
		Else
			AvailableValues.Add(Object.Name, Object.Synonym);
		EndIf;
	EndDo;
	AvailableValues.SortByPresentation(SortDirection.Asc);
	ValuesToDelete.SortByPresentation(SortDirection.Asc);
	
	For Each ObjectToDelete In ValuesToDelete Do
		AvailableValues.Add(ObjectToDelete.Value, ObjectToDelete.Presentation);
	EndDo;
	
	Return AvailableValues;
EndFunction

Function AvailableTables(MetadataObjectType, MetadataObjectName)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType)
		Or Not ValueIsFilled(MetadataObjectName) Then 
		Return AvailableValues;
	EndIf;
	
	MetadataObject = Metadata[MetadataObjectType][MetadataObjectName];
	
	AvailableValues.Add("", NStr("ru = 'Основные данные'; en = 'Main data'; pl = 'Dane podstawowe';de = 'Hauptdaten';ro = 'Date principale';tr = 'Ana veri'; es_ES = 'Datos principales'"));
	
	If MetadataObjectType = "Catalogs" 
		Or MetadataObjectType = "Documents" 
		Or MetadataObjectType = "BusinessProcesses"
		Or MetadataObjectType = "Tasks" Then
		
		For Each TabularSection In MetadataObject.TabularSections Do
			AvailableValues.Add(TabularSection.Name, TabularSection.Synonym);
		EndDo;
	ElsIf MetadataObjectType = "InformationRegisters" Then 
		If MetadataObject.InformationRegisterPeriodicity
			<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			
			AvailableValues.Add("SliceLast", NStr("ru = 'Срез последних'; en = 'Last values slice'; pl = 'Przekrój ostatnich';de = 'Schnitt vom Letzten';ro = 'Secțiunea ultimelor';tr = 'Son olanların kesiti'; es_ES = 'Corte de últimos'"));
			AvailableValues.Add("SliceFirst", NStr("ru = 'Срез первых'; en = 'Firlst values slice'; pl = 'Przekrój pierwszych';de = 'Schnitt vom Ersten';ro = 'Secțiunea primelor';tr = 'Birincilerin kesiti'; es_ES = 'Corte de primeros'"));
		EndIf;
	ElsIf MetadataObjectType = "AccumulationRegisters" Then
		If MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then
			AvailableValues.Add("BalanceAndTurnovers", NStr("ru = 'Остатки и обороты'; en = 'Balances and turnovers'; pl = 'Saldo i obroty';de = 'Balance und Umsätze';ro = 'Solduri și rulaje';tr = 'Bakiye ve cirolar'; es_ES = 'Saldo y facturación'"));
			AvailableValues.Add("Balance", NStr("ru = 'Остатки'; en = 'Balances'; pl = 'Salda';de = 'Verbleibende';ro = 'Solduri';tr = 'Bakiye'; es_ES = 'Saldos'"));
			AvailableValues.Add("Turnovers", NStr("ru = 'Обороты'; en = 'Turnovers'; pl = 'Obroty';de = 'Umsätze';ro = 'Rulaje';tr = 'Cirolar'; es_ES = 'Movimientos'"));
		Else
			AvailableValues.Add("Turnovers", NStr("ru = 'Обороты'; en = 'Turnovers'; pl = 'Obroty';de = 'Umsätze';ro = 'Rulaje';tr = 'Cirolar'; es_ES = 'Movimientos'"));
		EndIf;
	ElsIf MetadataObjectType = "AccountingRegisters" Then
		AvailableValues.Add("BalanceAndTurnovers", NStr("ru = 'Остатки и обороты'; en = 'Balances and turnovers'; pl = 'Saldo i obroty';de = 'Balance und Umsätze';ro = 'Solduri și rulaje';tr = 'Bakiye ve cirolar'; es_ES = 'Saldo y facturación'"));
		AvailableValues.Add("Balance", NStr("ru = 'Остатки'; en = 'Balances'; pl = 'Salda';de = 'Verbleibende';ro = 'Solduri';tr = 'Bakiye'; es_ES = 'Saldos'"));
		AvailableValues.Add("Turnovers", NStr("ru = 'Обороты'; en = 'Turnovers'; pl = 'Obroty';de = 'Umsätze';ro = 'Rulaje';tr = 'Cirolar'; es_ES = 'Movimientos'"));
		AvailableValues.Add("DrCrTurnovers", NStr("ru = 'Обороты Дт/Кт'; en = 'Dr/Cr turnovers'; pl = 'Obroty Dł/Kd';de = 'Umsätze Dt/Kt';ro = 'Rulaje Dt/Ct';tr = 'Cirolar Dt/Kt'; es_ES = 'Movimientos D/H'"));
		AvailableValues.Add("RecordsWithExtDimensions", NStr("ru = 'Движения с субконто'; en = 'Movements with extra dimension'; pl = 'Ruch z subkonto';de = 'Subkonto-Bewegungen';ro = 'Mișcări cu subconto';tr = 'Alt hesap hareketleri'; es_ES = 'Registros con cuentas analíticas'"));
	ElsIf MetadataObjectType = "CalculationRegisters" Then 
		If MetadataObject.ActionPeriod Then
			AvailableValues.Add("ScheduleData", NStr("ru = 'Данные графика'; en = 'Chart data'; pl = 'Dane harmonogramu';de = 'Grafikdaten';ro = 'Datele graficului';tr = 'Grafik verileri'; es_ES = 'Datos del gráfico'"));
			AvailableValues.Add("ActualActionPeriod", NStr("ru = 'Фактический период действия'; en = 'Actual validity period'; pl = 'Rzeczywisty okres obowiązywania';de = 'Tatsächlicher Gültigkeitszeitraum';ro = 'Perioada de valabilitate efectivă';tr = 'Fiili geçerlilik dönemi'; es_ES = 'Período de acción actual'"));
		EndIf;
	ElsIf MetadataObjectType = "ChartsOfCalculationTypes" Then
		If MetadataObject.DependenceOnCalculationTypes
			<> Metadata.ObjectProperties.ChartOfCalculationTypesBaseUse.DontUse Then 
			
			AvailableValues.Add("BaseCalculationTypes", NStr("ru = 'Базовые виды расчета'; en = 'Basic compensation types'; pl = 'Podstawowe rodzaje obliczeń';de = 'Grundlegende Berechnungsarten';ro = 'Tipurile de calcul de bază';tr = 'Temel hesaplama türleri'; es_ES = 'Tipos de liquidaciones básicos'"));
		EndIf;
		
		AvailableValues.Add("LeadingCalculationTypes", NStr("ru = 'Ведущие виды расчета'; en = 'Primary compensation types'; pl = 'Czołowe rodzaje obliczeń';de = 'Führende Berechnungsarten';ro = 'Tipurile de calcul principale';tr = 'En önemli hesaplama türleri'; es_ES = 'Tipos de liquidaciones principales'"));
		
		If MetadataObject.ActionPeriodUse Then 
			AvailableValues.Add("DisplacingCalculationTypes", NStr("ru = 'Вытесняющие виды расчета'; en = 'Overriding compensation types'; pl = 'Wypierające rodzaje obliczeń';de = 'Vorhersage von Berechnungsarten';ro = 'Tipurile de calcul de substituire';tr = 'Yerinden çıkaran hesaplama türleri'; es_ES = 'Tipos de liquidaciones desplazados'"));
		EndIf;
	EndIf;
	
	Return AvailableValues;
EndFunction

Function HasMetadataTypeObjects(MetadataType)
	
	For each Object In MetadataType Do
		If Common.MetadataObjectAvailableByFunctionalOptions(Object)
			AND AccessRight("Read", Object) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure AddTotals(ReportParameters, DataCompositionSchema)
	
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" 
		OR ReportParameters.MetadataObjectType = "InformationRegisters" 
		OR ReportParameters.MetadataObjectType = "AccountingRegisters" 
		OR ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		
		AddRegisterTotals(ReportParameters, DataCompositionSchema);
		
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		OR ReportParameters.MetadataObjectType = "Catalogs" 
		OR ReportParameters.MetadataObjectType = "BusinessProcesses"
		OR ReportParameters.MetadataObjectType = "Tasks" Then
		
		AddObjectTotals(ReportParameters, DataCompositionSchema);
	EndIf;
	
EndProcedure

Procedure AddObjectTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	ObjectPresentation = MetadataObject.Presentation();
	
	ReferenceDetails = MetadataObject.StandardAttributes["Ref"];
	If ValueIsFilled(ReferenceDetails.Synonym) Then 
		ObjectPresentation = ReferenceDetails.Synonym;
	ElsIf ValueIsFilled(MetadataObject.ObjectPresentation) Then 
		ObjectPresentation = MetadataObject.ObjectPresentation;
	EndIf;
	
	AddDataSetField(DataCompositionSchema.DataSets[0], ReferenceDetails.Name, ObjectPresentation);
	
	If ReportParameters.TableName <> "" Then
		TabularSection = MetadataObject.TabularSections.Find(ReportParameters.TableName);
		If TabularSection <> Undefined Then 
			MetadataObject = TabularSection;
		EndIf;
	EndIf;
	
	// Add totals by numeric attributes
	For each Attribute In MetadataObject.Attributes Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
			Continue;
		EndIf;
		
		AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
		If Attribute.Type.ContainsType(Type("Number")) Then
			AddTotalField(DataCompositionSchema, Attribute.Name);
		EndIf;
	EndDo;

EndProcedure

Procedure AddRegisterTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName]; 
	
	// Add dimensions
	For each Dimension In MetadataObject.Dimensions Do
		If Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
			AddDataSetField(DataCompositionSchema.DataSets[0], Dimension.Name, Dimension.Synonym);
		EndIf;
	EndDo;
	
	// Add attributes
	If IsBlankString(ReportParameters.TableName) Then
		For each Attribute In MetadataObject.Attributes Do
			If Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
			EndIf;
		EndDo;
	EndIf;
	
	// Add period fields
	If ReportParameters.TableName = "BalanceAndTurnovers" 
		OR ReportParameters.TableName = "Turnovers" 
		OR ReportParameters.MetadataObjectType = "AccountingRegisters" AND ReportParameters.TableName = "" Then
		AddPeriodFieldsInDataSet(DataCompositionSchema.DataSets[0]);
	EndIf;
	
	// For accounting registers, setting up roles is important.
	If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		
		AccountField = AddDataSetField(DataCompositionSchema.DataSets[0], "Account", NStr("ru = 'Счет'; en = 'Account'; pl = 'Rachunek';de = 'Konto';ro = 'Cont';tr = 'Hesap'; es_ES = 'Cuenta'"));
		AccountField.Role.AccountTypeExpression = "Account.Type";
		AccountField.Role.Account = True;
		
		ExtDimensionCount = 0;
		If MetadataObject.ChartOfAccounts <> Undefined Then 
			ExtDimensionCount = MetadataObject.ChartOfAccounts.MaxExtDimensionCount;
		EndIf;
		
		For ExtDimensionNumber = 1 To ExtDimensionCount Do
			ExtDimensionField = AddDataSetField(DataCompositionSchema.DataSets[0], "ExtDimensions" + ExtDimensionNumber, NStr("ru = 'Субконто'; en = 'Extra dimension'; pl = 'Subkonto';de = 'Subkonto';ro = 'Subconto';tr = 'Alt hesap'; es_ES = 'Сuenta analítica'") + " " + ExtDimensionNumber);
			ExtDimensionField.Role.Dimension = True;
			ExtDimensionField.Role.IgnoreNULLValues = True;
		EndDo;
		
	EndIf;
	
	// Add resources
	For each Resource In MetadataObject.Resources Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
			Continue;
		EndIf;
		
		If ReportParameters.TableName = "Turnovers" Then
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
				
				If NOT Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnover", Resource.Synonym + " " + NStr("ru = 'кор. оборот'; en = 'corr. turnover'; pl = 'kor. obrót';de = 'Kor. Umsatz';ro = 'rulaj coresp.';tr = 'muh.ciro'; es_ES = 'movimiento corresponsal'"), Resource.Name + "BalancedTurnover");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnover");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverDr", Resource.Synonym + " " + NStr("ru = 'кор. оборот Дт'; en = 'Dr corr. turnover'; pl = 'kor. obrót Dł';de = 'Kor. Umsatz Dt';ro = 'rulaj coresp. Dt';tr = 'muh. ciro Borç'; es_ES = 'movimiento corresponsal D'"), Resource.Name + "BalancedTurnoverDr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverDr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverCr", Resource.Synonym + " " + NStr("ru = 'кор. оборот Кт'; en = 'Cr corr. turnover'; pl = 'kor. obrót Kd';de = 'Kor. Umsatz Kt';ro = 'rulaj coresp. Ct';tr = 'muh. ciro Alacak'; es_ES = 'movimiento corresponsal H'"), Resource.Name + "BalancedTurnoverCr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverCr");
				EndIf;
			EndIf;
			
		ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("ru = 'Дт'; en = 'Dr'; pl = 'Wn';de = 'Dr';ro = 'Dt';tr = 'Dr'; es_ES = 'Débito'"), Resource.Name + "Dr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("ru = 'Кт'; en = 'Cr'; pl = 'Ma';de = 'Cr';ro = 'Ct';tr = 'Cr'; es_ES = 'Correspondencia'"), Resource.Name + "Cr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalance", Resource.Synonym + " " + NStr("ru = 'нач. остаток'; en = 'open balance'; pl = 'pocz. zapasy';de = 'Anf. Rest';ro = 'sold inițial';tr = 'ilk bakiye'; es_ES = 'saldo inicial'"), Resource.Name + "OpeningBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				SetField.Role.AccountField = "Account";
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("ru = 'нач. остаток Дт'; en = 'Dr open balance'; pl = 'pocz. zapasy Dł';de = 'Anf. Rest Dt';ro = 'sold iniț. Dt';tr = 'ilk bakiye Borç'; es_ES = 'saldo inicial D'"), Resource.Name + "OpeningBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("ru = 'нач. остаток Кт'; en = 'Cr open balance'; pl = 'pocz. zapasy Kd';de = 'Anf. Rest Kt';ro = 'sold iniț. Ct';tr = 'ilk bakiye Alacak'; es_ES = 'saldo inicial H'"), Resource.Name + "OpeningBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceDr", Resource.Synonym + " " + NStr("ru = 'нач. развернутый остаток Дт'; en = 'Dr open balance detailed'; pl = 'pocz. szczegół. zapasy Dł';de = 'Anf. entfaltete Balance Dt';ro = 'sold inițial desfăș. Dt';tr = 'ilk geniş bakiye Alacak'; es_ES = 'saldo inicial expandido D'"), Resource.Name + "OpeningSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceDr");
				
				SetField =AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceCr", Resource.Synonym + " " + NStr("ru = 'нач. развернутый остаток Кт'; en = 'Cr open balance detailed'; pl = 'pocz. szczegół. zapasy Kd';de = 'Anf. entfaltete Balance Kt';ro = 'sold inițial desfăș. Ct';tr = 'ilk geniş bakiye Borç'; es_ES = 'saldo inicial expandido H'"), Resource.Name + "OpeningSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceCr");
			EndIf;
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym + " " + NStr("ru = 'оборот'; en = 'turnover'; pl = 'obrót';de = 'Umsatz';ro = 'rulaj';tr = 'ciro'; es_ES = 'movimiento'"), Resource.Name + "Turnover");
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Receipt", Resource.Synonym + " " + NStr("ru = 'приход'; en = 'income'; pl = 'wpłynięcie';de = 'Einnahme';ro = 'intrări';tr = 'gelen para'; es_ES = 'cobro'"), Resource.Name + "Receipt");
				AddTotalField(DataCompositionSchema, Resource.Name + "Receipt");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Expense", Resource.Synonym + " " + NStr("ru = 'расход'; en = 'expense'; pl = 'rozchód';de = 'Ausgabe';ro = 'ieșiri';tr = 'gider'; es_ES = 'gasto'"), Resource.Name + "Expense");
				AddTotalField(DataCompositionSchema, Resource.Name + "Expense");
			ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalance", Resource.Synonym + " " + NStr("ru = 'кон. остаток'; en = 'close balance'; pl = 'koń. zapasy';de = 'End. Balance';ro = 'sold final';tr = 'son bakiye'; es_ES = 'saldo final'"), Resource.Name + "ClosingBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceDr", Resource.Synonym + " " + NStr("ru = 'кон. остаток Дт'; en = 'Dr close balance'; pl = 'koń. zapasy Dł';de = 'End. Balance Dt';ro = 'sold final Dt';tr = 'son bakiye Borç'; es_ES = 'saldo final D'"), Resource.Name + "ClosingBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceCr", Resource.Synonym + " " + NStr("ru = 'кон. остаток Кт'; en = 'Cr close balance'; pl = 'koń. zapasy Kd';de = 'End. Balance Kt';ro = 'sold final Ct';tr = 'son bakiye Alacak'; es_ES = 'saldo final H'"), Resource.Name + "ClosingBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceDr", Resource.Synonym + " " + NStr("ru = 'кон. развернутый остаток Дт'; en = 'Dr close balance detailed'; pl = 'kon. szczegół. zapasy Dł';de = 'End. entfaltete Balance Dt';ro = 'sold final desfăș. Dt';tr = 'son geniş bakiye Borç'; es_ES = 'saldo final expandido D'"), Resource.Name + "ClosingSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceCr", Resource.Synonym + " " + NStr("ru = 'кон. развернутый остаток Кт'; en = 'Cr close balance detailed'; pl = 'kon. szczegół. zapasy Kd';de = 'End. entfaltete Balance Kt';ro = 'sold final desfăș. Ct';tr = 'son geniş bakiye Alacak'; es_ES = 'saldo final expandido H'"), Resource.Name + "ClosingSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "DetailedBalance" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceCr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "Balance" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Balance", Resource.Synonym + " " + NStr("ru = 'остаток'; en = 'balance'; pl = 'saldo';de = 'Balance';ro = 'sold';tr = 'bakiye'; es_ES = 'saldo'"), Resource.Name + "Balance");
			AddTotalField(DataCompositionSchema, Resource.Name + "Balance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("ru = 'остаток Дт'; en = 'Dr balance'; pl = 'zapasy Dł';de = 'Balance Dt';ro = 'sold Dt';tr = 'bakiye Alacak'; es_ES = 'saldo D'"), Resource.Name + "BalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("ru = 'остаток Кт'; en = 'Cr balance'; pl = 'zapasy Kd';de = 'Balance Kt';ro = 'sold Ct';tr = 'bakiye Borç'; es_ES = 'saldo H'"), Resource.Name + "BalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceCr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "DetailedBalanceDr", Resource.Synonym + " " + NStr("ru = 'развернутый остаток Дт'; en = 'Dr balance detailed'; pl = 'szczegół. zapasy Kd';de = 'entfaltete Balance Dt';ro = 'sold desfăș. Dt';tr = 'geniş bakiye Alacak'; es_ES = 'saldo expandido D'"), Resource.Name + "DetailedBalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "DetailedBalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "DetailedBalanceCr", Resource.Synonym + " " + NStr("ru = 'развернутый остаток Кт'; en = 'Cr balance detailed'; pl = 'szczegół. zapasy Kd';de = 'entfaltete Balance Kt';ro = 'sold desfăș. Ct';tr = 'geniş bakiye Borç'; es_ES = 'saldo expandido H'"), Resource.Name + "DetailedBalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "DetailedBalanceCr");
			EndIf;
		ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
			If Resource.Type.ContainsType(Type("Number")) Then
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		ElsIf ReportParameters.TableName = "" Then
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				If Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
					AddTotalField(DataCompositionSchema, Resource.Name);
				Else
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("ru = 'Дт'; en = 'Dr'; pl = 'Wn';de = 'Dr';ro = 'Dt';tr = 'Dr'; es_ES = 'Débito'"), Resource.Name + "Dr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("ru = 'Кт'; en = 'Cr'; pl = 'Ma';de = 'Cr';ro = 'Ct';tr = 'Cr'; es_ES = 'Correspondencia'"), Resource.Name + "Cr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
				EndIf;
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		EndIf;
	EndDo;

EndProcedure

Function AddPeriodFieldsInDataSet(DataSet)
	
	PeriodsList = New ValueList;
	PeriodsList.Add("SecondPeriod",   NStr("ru = 'Период секунда'; en = 'Period second'; pl = 'Okres sekunda';de = 'Periode Sekunde';ro = 'Secunde perioadă';tr = 'Dönem saniye'; es_ES = 'Período segundo'"));
	PeriodsList.Add("MinutePeriod",    NStr("ru = 'Период минута'; en = 'Period minute'; pl = 'Okres minuta';de = 'Periode Minute';ro = 'Minute perioadă';tr = 'Dönem dakika'; es_ES = 'Período minuto'"));
	PeriodsList.Add("HourPeriod",       NStr("ru = 'Период час'; en = 'Period hour'; pl = 'Okres godzina';de = 'Periode Stunde';ro = 'Oră perioadă';tr = 'Dönem saat'; es_ES = 'Período hora'"));
	PeriodsList.Add("DayPeriod",      NStr("ru = 'Период день'; en = 'Period day'; pl = 'Okres dzień';de = 'Periode Tag';ro = 'Zi perioadă';tr = 'Dönem Gün'; es_ES = 'Período día'"));
	PeriodsList.Add("WeekPeriod",    NStr("ru = 'Период неделя'; en = 'Period week'; pl = 'Okres tydzień';de = 'Periode Woche';ro = 'Perioada săptămână';tr = 'Dönem Hafta'; es_ES = 'Período Semana'"));
	PeriodsList.Add("TenDaysPeriod",    NStr("ru = 'Период декада'; en = 'Period ten-day'; pl = 'Okres dekada';de = 'Periode Zehn-Tage-Zeitraum';ro = 'Perioadă de zece zile';tr = 'Dönem On gün'; es_ES = 'Período período de diez días'"));
	PeriodsList.Add("MonthPeriod",     NStr("ru = 'Период месяц'; en = 'Period month'; pl = 'Okres miesiąc';de = 'Zeitraum Monat';ro = 'Perioadă lună';tr = 'Dönem Ay'; es_ES = 'Período mes'"));
	PeriodsList.Add("QuarterPeriod",   NStr("ru = 'Период квартал'; en = 'Period quarter'; pl = 'Okres kwartał';de = 'Periode Quartal';ro = 'Perioada trimestru';tr = 'Dönem Çeyrek yıl'; es_ES = 'Período Trimestre'"));
	PeriodsList.Add("HalfYearPeriod", NStr("ru = 'Период полугодие'; en = 'Period half-year'; pl = 'Okres półrocze';de = 'Halbjahreszeitraum';ro = 'Perioada semestru';tr = 'Dönem yarıyıl'; es_ES = 'Período medio año'"));
	PeriodsList.Add("YearPeriod",       NStr("ru = 'Период год'; en = 'Period year'; pl = 'Okres rok';de = 'Periode Jahr';ro = 'Perioada an';tr = 'Dönem Yıl'; es_ES = 'Período Año'"));
	
	FolderName = "Periods";
	DataSetFieldsList = New ValueList;
	DataSetFieldsFolder = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
	DataSetFieldsFolder.Title   = FolderName;
	DataSetFieldsFolder.DataPath = FolderName;
	
	PeriodType = DataCompositionPeriodType.Main;
	
	For each Period In PeriodsList Do
		DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		DataSetField.Field        = Period.Value;
		DataSetField.Title   = Period.Presentation;
		DataSetField.DataPath = FolderName + "." + Period.Value;
		DataSetField.Role.PeriodType = PeriodType;
		DataSetField.Role.PeriodNumber = PeriodsList.IndexOf(Period);
		DataSetFieldsList.Add(DataSetField);
		PeriodType = DataCompositionPeriodType.Additional;
	EndDo;
	
	Return DataSetFieldsList;
	
EndFunction

// Add field to data set.
Function AddDataSetField(DataSet, Field, Title, DataPath = Undefined)
	
	If DataPath = Undefined Then
		DataPath = Field;
	EndIf;
	
	DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = Field;
	DataSetField.Title   = Title;
	DataSetField.DataPath = DataPath;
	Return DataSetField;
	
EndFunction

// Add total field to data composition schema. If the Expression parameter is not specified, Sum(PathToData) is used.
Function AddTotalField(DataCompositionSchema, DataPath, Expression = Undefined)
	
	If Expression = Undefined Then
		Expression = "Sum(" + DataPath + ")";
	EndIf;
	
	TotalField = DataCompositionSchema.TotalFields.Add();
	TotalField.DataPath = DataPath;
	TotalField.Expression = Expression;
	Return TotalField;
	
EndFunction

Procedure AddIndicators(ReportParameters, DCSettings)
	
	If ReportParameters.TableName = "BalanceAndTurnovers" Then
		SelectedFieldsOpeningBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsOpeningBalance.Title = NStr("ru = 'Нач. остаток'; en = 'Open balance'; pl = 'Pocz. zapasy';de = 'Anf. rest';ro = 'Sold inițial';tr = 'İlk bakiye'; es_ES = 'Saldo inicial'");
		SelectedFieldsOpeningBalance.Placement = DataCompositionFieldPlacement.Horizontally;
		If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
			SelectedFieldsReceipt = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsReceipt.Title = NStr("ru = 'Приход'; en = 'Income'; pl = 'Wpływy';de = 'Zufluss';ro = 'Sumă încasări';tr = 'Giriş'; es_ES = 'Entrada'");
			SelectedFieldsReceipt.Placement = DataCompositionFieldPlacement.Horizontally;
			SelectedFieldsExpense = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsExpense.Title = NStr("ru = 'Расход'; en = 'Expense'; pl = 'Wydatki';de = 'Abfluss';ro = 'Sumă plăți';tr = 'Çıkış'; es_ES = 'Salida'");
			SelectedFieldsExpense.Placement = DataCompositionFieldPlacement.Horizontally;
		ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
			SelectedFieldsTurnovers = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsTurnovers.Title = NStr("ru = 'Обороты'; en = 'Turnovers'; pl = 'Obroty';de = 'Umsätze';ro = 'Rulaje';tr = 'Cirolar'; es_ES = 'Movimientos'");
			SelectedFieldsTurnovers.Placement = DataCompositionFieldPlacement.Horizontally;
		EndIf;
		SelectedFieldsClosingBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsClosingBalance.Title = NStr("ru = 'Кон. остаток'; en = 'Close balance'; pl = 'Koń. zapasy';de = 'End. balance';ro = 'Sold final';tr = 'Son bakiye'; es_ES = 'Saldo final'");
		SelectedFieldsClosingBalance.Placement = DataCompositionFieldPlacement.Horizontally;
	EndIf;
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym);
			ElsIf ReportParameters.TableName = "Balance" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Balance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalance", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsReceipt, Resource.Name + "Receipt", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsExpense, Resource.Name + "Expense", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"));
			ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym + " " + NStr("ru = 'оборот'; en = 'turnover'; pl = 'obrót';de = 'Umsatz';ro = 'rulaj';tr = 'ciro'; es_ES = 'movimiento'"));
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"));
				EndIf;
			ElsIf ReportParameters.TableName = "Balance" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("ru = 'ост. Дт'; en = 'Dr balance'; pl = 'zap. Dł';de = 'Bal. Dt';ro = 'sold Dt';tr = 'bakiye Borç'; es_ES = 'saldo D'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("ru = 'ост. Кт'; en = 'Cr balance'; pl = 'zap. Kd';de = 'Bal. Kt';ro = 'sold Ct';tr = 'bakiye Alacak'; es_ES = 'saldo H'"));
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("ru = 'нач. ост. Дт'; en = 'Dr open balance'; pl = 'pocz. zap. Dł';de = 'Anf. Bal. Dt';ro = 'sold iniț. Dt';tr = 'ilk bakiye Borç'; es_ES = 'saldo inicial D'"));
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("ru = 'нач. ост. Кт'; en = 'Cr open balance'; pl = 'pocz. zap. Kd';de = 'Anf. Bal. Kt';ro = 'sold iniț. Ct';tr = 'ilk bakiye Alacak'; es_ES = 'saldo inicial H'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("ru = 'оборот Дт'; en = 'Dr turnover'; pl = 'Obrót Dt';de = 'Umsatz Dt';ro = 'rulaj Dt';tr = 'ciro Borç'; es_ES = 'movimiento D'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("ru = 'оборот Кт'; en = 'Cr turnover'; pl = 'obrót Ct';de = 'Umsatz Kt';ro = 'rulaj Ct';tr = 'ciro Alacak'; es_ES = 'movimiento H'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceDr", " " + Resource.Synonym + NStr("ru = 'кон. ост. Дт'; en = 'Dr close balance'; pl = 'kon. zap. Dł';de = 'End. Bal. Dt';ro = 'sold final Dt';tr = 'son bakiye Borç'; es_ES = 'saldo final D'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceCr", " " + Resource.Synonym + NStr("ru = 'кон. ост. Кт'; en = 'Cr close balance'; pl = 'kon. zap. Kd';de = 'End. Bal. Kt';ro = 'sold final Ct';tr = 'son bakiye Alacak'; es_ES = 'saldo final H'"));
			ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name, Resource.Synonym);
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Dr", Resource.Synonym + " " + NStr("ru = 'Дт'; en = 'Dr'; pl = 'Wn';de = 'Dr';ro = 'Dt';tr = 'Dr'; es_ES = 'Débito'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Cr", Resource.Synonym + " " + NStr("ru = 'Кт'; en = 'Cr'; pl = 'Kt';de = 'Cr';ro = 'Ct';tr = 'Cr'; es_ES = 'Crédito'"));
				EndIf;
			ElsIf ReportParameters.TableName = "" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name, Resource.Synonym);
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Dr", Resource.Synonym + " " + NStr("ru = 'Дт'; en = 'Dr'; pl = 'Wn';de = 'Dr';ro = 'Dt';tr = 'Dr'; es_ES = 'Débito'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Cr", Resource.Synonym + " " + NStr("ru = 'Кт'; en = 'Cr'; pl = 'Kt';de = 'Cr';ro = 'Ct';tr = 'Cr'; es_ES = 'Crédito'"));
				EndIf;
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		OR ReportParameters.MetadataObjectType = "Tasks"
		OR ReportParameters.MetadataObjectType = "BusinessProcesses"
		OR ReportParameters.MetadataObjectType = "Catalogs" Then
		If ReportParameters.TableName <> "" Then
			MetadataObject = MetadataObject.TabularSections[ReportParameters.TableName];
		EndIf;
		SelectedFields = DCSettings.Selection;
		ReportsServer.AddSelectedField(SelectedFields, "Ref");
		For each Attribute In MetadataObject.Attributes Do
			If Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "ChartsOfCalculationTypes" Then
		If ReportParameters.TableName = "" Then
			For each Attribute In MetadataObject.Attributes Do
				If Not Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
					Continue;
				EndIf;
				
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		Else
			For each Attribute In MetadataObject.StandardAttributes Do
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Generates the structure of data composition settings
//
// Parameters:
//  ReportParameters - Structure - a description of a metadata object that is a data source
//  Schema - DataCompositionSchema - main schema of report data composition
//  Settings - DataCompositionSettings - settings whose structure is being generated.
//
Procedure GenerateStructure(ReportParameters, Schema, Settings)
	Settings.Structure.Clear();
	
	Structure = Settings.Structure.Add(Type("DataCompositionGroup"));
	
	FieldsTypes = StrSplit("Dimensions@Resources", "@", False);
	
	SourcesFieldsTypes = New Map();
	SourcesFieldsTypes.Insert("InformationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccumulationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccountingRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("CalculationRegisters", FieldsTypes);
	
	SourceFieldsTypes = SourcesFieldsTypes[ReportParameters.MetadataObjectType];
	If SourceFieldsTypes <> Undefined Then 
		SpecifyFieldsSuffixes = ReportParameters.MetadataObjectType = "AccountingRegisters"
			AND (ReportParameters.TableName = ""
				Or ReportParameters.TableName = "DrCrTurnovers"
				Or ReportParameters.TableName = "RecordsWithExtDimensions");
		
		For Each SourceFieldsType In SourceFieldsTypes Do 
			GroupFields = Structure.GroupFields.Items;
			
			SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
			For Each FieldMetadata In SourceMetadata[SourceFieldsType] Do
				If Not Common.MetadataObjectAvailableByFunctionalOptions(FieldMetadata) Then 
					Continue;
				EndIf;
				
				If ReportParameters.MetadataObjectType = "AccountingRegisters"
					AND FieldMetadata.AccountingFlag <> Undefined Then 
					Continue;
				EndIf;
				
				If SourceFieldsType = "Resources"
					AND FieldMetadata.Type.ContainsType(Type("Number")) Then 
					Continue;
				EndIf;
				
				If SpecifyFieldsSuffixes
					AND Not FieldMetadata.Balance Then 
					FieldsSuffixes = StrSplit("Dr@Cr", "@", False);
				Else
					FieldsSuffixes = StrSplit("", "@");
				EndIf;
				
				For Each Suffix In FieldsSuffixes Do 
					GroupField = GroupFields.Add(Type("DataCompositionGroupField"));
					GroupField.Field = New DataCompositionField(FieldMetadata.Name + Suffix);
					GroupField.Use = True;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
	Structure.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	Structure.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Work with a standard schema set in user settings.

Function DataCompositionSchema(FixedParameters) Export 
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	DataCompositionSchema.TotalFields.Clear();
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	DataSet.Query = TextOfQueryByMetadata(FixedParameters);
	DataSet.AutoFillAvailableFields = True;
	
	AddTotals(FixedParameters, DataCompositionSchema);
	
	If FixedParameters.MetadataObjectType = "Catalogs"
		Or FixedParameters.MetadataObjectType = "ChartsOfCalculationTypes" 
		Or (FixedParameters.MetadataObjectType = "InformationRegisters"
			AND Metadata[FixedParameters.MetadataObjectType][FixedParameters.MetadataObjectName].InformationRegisterPeriodicity 
			= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical) Then
		DataCompositionSchema.Parameters.Period.UseRestriction = True;
	EndIf;
	
	AvailableTables = AvailableTables(FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	If AvailableTables.Count() < 2 Then
		DataCompositionSchema.Parameters.TableName.UseRestriction = True;
	EndIf;
	
	Return DataCompositionSchema;
EndFunction

Procedure CustomizeStandardSettings(Report, FixedParameters, Settings, UserSettings) Export 
	ReportInitialized = CommonClientServer.StructureProperty(
		Settings.AdditionalProperties, "ReportInitialized", False);
	
	If ReportInitialized Then 
		Return;
	EndIf;
	
	Report.SettingsComposer.LoadSettings(Report.DataCompositionSchema.DefaultSettings);
	
	Settings = Report.SettingsComposer.Settings;
	Settings.Selection.Items.Clear();
	Settings.Structure.Clear();
	
	AddIndicators(FixedParameters, Settings);
	GenerateStructure(FixedParameters, Report.DataCompositionSchema, Settings);
	
	SetFixedParameters(Report, FixedParameters, Settings, UserSettings);
	
	Settings.AdditionalProperties.Insert("ReportInitialized", True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Work with arbitrary schema from a file.

Function ExtractSchemaFromBinaryData(ImportedSchema) Export
	
	FullFileName = GetTempFileName();
	ImportedSchema.Write(FullFileName);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FullFileName);
	DCSchema = XDTOSerializer.ReadXML(XMLReader, Type("DataCompositionSchema"));
	XMLReader.Close();
	XMLReader = Undefined;
	DeleteFiles(FullFileName);
	
	If DCSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
		DCSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
	EndIf;
	
	Return DCSchema;
	
EndFunction

Procedure SetStandardImportedSchemaSettings(Report, SchemaBinaryData, Settings, UserSettings) Export 
	If CommonClientServer.StructureProperty(Settings.AdditionalProperties, "ReportInitialized", False) Then 
		Return;
	EndIf;
	
	Settings = Report.DataCompositionSchema.DefaultSettings;
	Settings.AdditionalProperties.Insert("DataCompositionSchema", SchemaBinaryData);
	Settings.AdditionalProperties.Insert("ReportInitialized",  True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Work with the data source of a report option.

// Sets the DataSource parameter of report option settings
//
// Parameters:
//  Option - CatalogRef.ReportsOptions - a report option settings storage.
//
Procedure DetermineOptionDataSource(Option) Export
	UniversalReport = Common.MetadataObjectID(Metadata.Reports.UniversalReport);
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add(Option.Metadata().FullName());
		LockItem.SetValue("Ref", Option);
		Lock.Lock();
		
		OptionObject = Option.GetObject();
		
		OptionSettings = Undefined;
		If OptionObject <> Undefined
			AND OptionObject.Report = UniversalReport Then 
			OptionSettings = OptionSettings(OptionObject);
		EndIf;
		
		If OptionSettings = Undefined Then 
			RollbackTransaction();
			InfobaseUpdate.MarkProcessingCompletion(Option);
			Return;
		EndIf;
		
		OptionObject.Settings = New ValueStorage(OptionSettings);
		InfobaseUpdate.WriteData(OptionObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

// Returns the report option settings with the set DataSource parameter.
//
// Parameters:
//  Option - CatalogObject.ReportOptions - a report option settings storage.
//
// Returns:
//   DataCompositionSettings, Undefined - updated setting or Undefined if update failed.
//                                            
//
Function OptionSettings(Option)
	Try
		OptionSettings = Option.Settings.Get();
	Except
		// Cannot deserialize a value storage:
		//  perhaps a reference to a nonexistent type is found.
		Return Undefined;
	EndTry;
	
	If OptionSettings = Undefined Then 
		Return Undefined;
	EndIf;
	
	DataParameters = OptionSettings.DataParameters.Items;
	
	ParametersRequired = New Structure(
		"MetadataObjectType, FullMetadataObjectName, MetadataObjectName, DataSource");
	For Each Parameter In ParametersRequired Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter <> Undefined Then 
			ParametersRequired[Parameter.Key] = FoundParameter.Value;
		EndIf;
	EndDo;
	
	// If option settings contain a parameter with a non-relevant name, the name will be updated.
	If ValueIsFilled(ParametersRequired.FullMetadataObjectName) Then 
		ParametersRequired.MetadataObjectName = ParametersRequired.FullMetadataObjectName;
	EndIf;
	ParametersRequired.Delete("FullMetadataObjectName");
	
	If Not ValueIsFilled(ParametersRequired.DataSource) Then 
		ParametersRequired.DataSource = DataSource(
			ParametersRequired.MetadataObjectType, ParametersRequired.MetadataObjectName);
		If ParametersRequired.DataSource = Undefined Then 
			Return Undefined;
		EndIf;
	EndIf;
	
	ParametersToSet = New Structure("DataSource, MetadataObjectName");
	FillPropertyValues(ParametersToSet, ParametersRequired);
	
	ObjectName = Common.ObjectAttributeValue(ParametersRequired.DataSource, "Name");
	If ObjectName <> ParametersToSet.MetadataObjectName Then 
		ParametersToSet.MetadataObjectName = ObjectName;
	EndIf;
	
	For Each Parameter In ParametersToSet Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter = Undefined Then 
			DataParameter = DataParameters.Add();
			DataParameter.Parameter = New DataCompositionParameter(Parameter.Key);
			DataParameter.Value = Parameter.Value;
			DataParameter.Use = True;
		Else
			OptionSettings.DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Return OptionSettings;
EndFunction

// Returns report data source
//
// Parameters:
//  ManagerType - String - a metadata object manager presentation, for example, "Catalogs" or 
//                 "InformationRegisters" and other presentations.
//  ObjectName  - String - a short name of a metadata object, for example, "Currencies" or 
//                "ExchangeRates", and so on.
//
// Returns:
//   CatalogRef.MetadataObjectsIDs, Undefined - a reference to the found item of the catalog, 
//   otherwise - Undefined.
//
Function DataSource(ManagerType, ObjectName)
	ObjectType = ObjectTypeByManagerType(ManagerType);
	FullObjectName = ObjectType + "." + ObjectName;
	If Metadata.FindByFullName(FullObjectName) = Undefined Then 
		WriteLogEvent(NStr("ru = 'Варианты отчетов.Установка источника данных универсального отчета'; en = 'Report options. Configure universal report data source'; pl = 'Opcje raportu.Ustawianie źródła danych raportu uniwersalnego';de = 'Berichtsoptionen. Einstellen der universellen Berichtsdatenquelle';ro = 'Variantele rapoartelor.Instalarea sursei de date a raportului universal';tr = 'Konaklama seçenekleri rapor.Genel rapor veri kaynağını ayarlama'; es_ES = 'Opciones de informes.Determinación de fuente de datos del informe universal'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.ReportsOptions,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Источник данных %1 отсутствует'; en = 'Cannot find data source for %1'; pl = 'Brak źródła danych %1 ';de = 'Keine Datenquelle %1';ro = 'Lipsește sursa de date %1';tr = 'Veri kaynağı %1eksik'; es_ES = 'No hay fuente de datos %1'"), 
				FullObjectName));
		Return Undefined;
	EndIf;
	
	Return Common.MetadataObjectID(FullObjectName);
EndFunction

// Returns the type of metadata object by the matching manager type
//
// Parameters:
//  ManagerType - String - a metadata object manager presentation, for example, "Catalogs" or 
//                 "InformationRegisters" and other presentations.
//
// Returns:
//   String - a metadata object type, for example, "Catalog" or "InformationRegister", and so on.
//
Function ObjectTypeByManagerType(ManagerType)
	Types = New Map;
	Types.Insert("Catalogs", "Catalog");
	Types.Insert("Documents", "Document");
	Types.Insert("DataProcessors", "DataProcessor");
	Types.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Types.Insert("AccountingRegisters", "AccountingRegister");
	Types.Insert("AccumulationRegisters", "AccumulationRegister");
	Types.Insert("CalculationRegisters", "CalculationRegister");
	Types.Insert("InformationRegisters", "InformationRegister");
	Types.Insert("BusinessProcesses", "BusinessProcess");
	Types.Insert("DocumentJournals", "DocumentJournal");
	Types.Insert("Tasks", "Task");
	Types.Insert("Reports", "Report");
	Types.Insert("Constants", "Constant");
	Types.Insert("Enums", "Enum");
	Types.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	Types.Insert("ExchangePlans", "ExchangePlan");
	Types.Insert("ChartsOfAccounts", "ChartOfAccounts");
	
	Return ?(Types[ManagerType] = Undefined, "", Types[ManagerType]);
EndFunction

#EndRegion

#EndIf