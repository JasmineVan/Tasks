///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	ResultTable = RegisteredObjects();
	
	StandardProcessing = False;
	DCSettings = SettingsComposer.GetSettings();
	ExternalDataSets = New Structure("ResultTable", ResultTable);
	
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(DataCompositionSchema, DCSettings, DetailsData);
	
	DCProcessor = New DataCompositionProcessor;
	DCProcessor.Initialize(DCTemplate, ExternalDataSets, DetailsData);
	
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DCResultOutputProcessor.SetDocument(ResultDocument);
	DCResultOutputProcessor.Output(DCProcessor);
	
	ResultDocument.ShowRowGroupLevel(2);
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ResultTable.Count() = 0);
	
EndProcedure

#EndRegion

#Region Private

Function RegisteredObjects()
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate";
	Result = Query.Execute().Unload();
	NodesArray = Result.UnloadColumn("Ref");
	NodesList = New ValueList;
	NodesList.LoadValues(NodesArray);
	
	ResultTable = New ValueTable;
	ResultTable.Columns.Add("ConfigurationSynonym");
	ResultTable.Columns.Add("FullName");
	ResultTable.Columns.Add("ObjectType");
	ResultTable.Columns.Add("Presentation");
	ResultTable.Columns.Add("MetadataType");
	ResultTable.Columns.Add("ObjectCount");
	ResultTable.Columns.Add("Queue");
	ResultTable.Columns.Add("UpdateHandler");
	ResultTable.Columns.Add("TotalObjectCount", New TypeDescription("Number"));
	
	ExchangePlanComposition = Metadata.ExchangePlans.InfobaseUpdate.Content;
	PresentationMap = New Map;
	
	ConfigurationSynonym = Metadata.Synonym;
	QueryText = "";
	Query       = New Query;
	Query.SetParameter("NodesList", NodesList);
	Restriction  = 0;
	For Each ExchangePlanItem In ExchangePlanComposition Do
		MetadataObject = ExchangePlanItem.Metadata;
		If Not AccessRight("Read", MetadataObject) Then
			Continue;
		EndIf;
		Presentation    = MetadataObject.Presentation();
		FullName        = MetadataObject.FullName();
		FullNameParts = StrSplit(FullName, ".");
		
		// Transforming from "CalculationRegister._DemoBasicAccruals.Recalculation.BasicAccrualsRecalculation.Changes"
		// to "CalculationRegister._DemoBasicAccruals.BasicAccrualsRecalculation.Changes"
		If FullNameParts[0] = "CalculationRegister" AND FullNameParts.Count() = 4 AND FullNameParts[2] = "Recalculation" Then
			FullNameParts.Delete(2); // delete the extra Recalculation
			FullName = StrConcat(FullNameParts, ".");
		EndIf;	
		QueryText = QueryText + ?(QueryText = "", "", "UNION ALL") + "
			|SELECT
			|	""" + MetadataTypePresentation(FullNameParts[0]) + """ AS MetadataType,
			|	""" + FullNameParts[1] + """ AS ObjectType,
			|	""" + FullName + """ AS FullName,
			|	Node.Queue AS Queue,
			|	COUNT(*) AS ObjectCount
			|FROM
			|	" + FullName + ".Changes
			|WHERE
			|	Node IN (&NodesList)
			|GROUP BY
			|	Node
			|";
			
		Restriction = Restriction + 1;
		PresentationMap.Insert(FullNameParts[1], Presentation);
		If Restriction = 200 Then
			Query.Text = QueryText;
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				Row = ResultTable.Add();
				FillPropertyValues(Row, Selection);
				Row.ConfigurationSynonym = ConfigurationSynonym;
				Row.Presentation = PresentationMap[Row.ObjectType];
			EndDo;
			Restriction  = 0;
			QueryText = "";
			PresentationMap = New Map;
		EndIf;
		
	EndDo;
	
	If QueryText <> "" Then
		Query.Text = QueryText;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Row = ResultTable.Add();
			FillPropertyValues(Row, Selection);
			Row.ConfigurationSynonym = ConfigurationSynonym;
			Row.Presentation = PresentationMap[Row.ObjectType];
		EndDo;
	EndIf;
	
	HandlersData = UpdateHandlers();
	For Each HandlerData In HandlersData Do
		HandlerName = HandlerData.Key;
		For Each ObjectData In HandlerData.Value.HandlerData Do
			FullObjectName = ObjectData.Key;
			Queue    = ObjectData.Value.Queue;
			Count = ObjectData.Value.Count;
			
			FilterParameters = New Structure;
			FilterParameters.Insert("FullName", FullObjectName);
			FilterParameters.Insert("Queue", Queue);
			Rows = ResultTable.FindRows(FilterParameters);
			For Each Row In Rows Do
				If Not ValueIsFilled(Row.UpdateHandler) Then
					Row.UpdateHandler = HandlerName;
				Else
					Row.UpdateHandler = Row.UpdateHandler + "," + Chars.LF + HandlerName;
				EndIf;
				Row.TotalObjectCount = Row.TotalObjectCount + Count;
			EndDo;
			
			// Object is fully processed.
			If Rows.Count() = 0 Then
				Row = ResultTable.Add();
				FullNameParts = StrSplit(FullObjectName, ".");
				
				Row.ConfigurationSynonym = ConfigurationSynonym;
				Row.FullName     = FullObjectName;
				Row.ObjectType    = FullNameParts[1];
				Row.Presentation = Metadata.FindByFullName(FullObjectName).Presentation();
				Row.MetadataType = MetadataTypePresentation(FullNameParts[0]);
				Row.Queue       = Queue;
				Row.UpdateHandler = HandlerName;
				Row.TotalObjectCount = Row.TotalObjectCount + Count;
				Row.ObjectCount = 0;
			EndIf;
			
		EndDo;
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("UpdateHandler", Undefined);
	SearchResult = ResultTable.FindRows(Filter);
	
	For Each Row In SearchResult Do
		ResultTable.Delete(Row);
	EndDo;
	
	Return ResultTable;
	
EndFunction

Function MetadataTypePresentation(MetadataType)
	
	Map = New Map;
	Map.Insert("Constant", NStr("ru = 'Константы'; en = 'Constants'; pl = 'Stałe';de = 'Konstanten';ro = 'Constante';tr = 'Sabitler'; es_ES = 'Constantes'"));
	Map.Insert("Catalog", NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'"));
	Map.Insert("Document", NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'"));
	Map.Insert("ChartOfCharacteristicTypes", NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'"));
	Map.Insert("ChartOfAccounts", NStr("ru = 'Планы счетов'; en = 'Charts of accounts'; pl = 'Plany kont';de = 'Kontenpläne';ro = 'Planurile conturilor';tr = 'Hesap çizelgeleri'; es_ES = 'Diagramas de las cuentas'"));
	Map.Insert("ChartOfCalculationTypes", NStr("ru = 'Планы видов расчета'; en = 'Charts of calculation types'; pl = 'Plany typów obliczeń';de = 'Diagramme der Berechnungstypen';ro = 'Diagrame de tipuri de calcul';tr = 'Hesaplama türleri çizelgeleri'; es_ES = 'Diagramas de los tipos de cálculos'"));
	Map.Insert("InformationRegister", NStr("ru = 'Регистры сведений'; en = 'Information registers'; pl = 'Rejestry informacji';de = 'Informationen registriert';ro = 'Registre de date';tr = 'Bilgi kayıtları'; es_ES = 'Registros de información'"));
	Map.Insert("AccumulationRegister", NStr("ru = 'Регистры накопления'; en = 'Accumulation registers'; pl = 'Rejestry akumulacji';de = 'Akkumulationsregister';ro = 'Registre de acumulare';tr = 'Birikeçler'; es_ES = 'Registros de acumulación'"));
	Map.Insert("AccountingRegister", NStr("ru = 'Регистры бухгалтерии'; en = 'Accounting registers'; pl = 'Rejestry księgowe';de = 'Buchhaltungsregister';ro = 'Registre contabile';tr = 'Muhasebe kayıtları'; es_ES = 'Registros de contabilidad'"));
	Map.Insert("CalculationRegister", NStr("ru = 'Регистры расчета'; en = 'Calculation registers'; pl = 'Rejestry obliczeń';de = 'Berechnungsregister';ro = 'Registre de calcul';tr = 'Hesaplama kayıtları'; es_ES = 'Registros de cálculos'"));
	Map.Insert("BusinessProcess", NStr("ru = 'Бизнес процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Business-procese';tr = 'Iş süreçleri'; es_ES = 'Procesos de negocio'"));
	Map.Insert("Task", NStr("ru = 'Задачи'; en = 'Tasks'; pl = 'Zadania';de = 'Aufgaben';ro = 'Sarcini';tr = 'Görevler'; es_ES = 'Tareas'"));
	
	Return Map[MetadataType];
	
EndFunction

Function UpdateHandlers()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	DataToProcess = UpdateInfo.DataToProcess;
	
	Return DataToProcess;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf