///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//                          HOW TO USE THE FORM                               //
//
// The form is intended for selecting configuration metadata objects and passing them to a calling 
// environment.
//
// Call parameters:
// MetadataObjectsToSelectCollection - ValueList -  the available metadata object type filters.
//				
//				Example:
//					FilterByReferenceMetadata = New ValueList;
//					FilterByReferenceMetadata.Add("Catalogs");
//					FilterByReferenceMetadata.Add("Documents");
//				In this example the form allows to select only Catalogs and Documents metadata objects.
// SelectedMetadataObjects - ValueList - metadata objects that are already selected.
//				In metadata tree this objects will be marked by flags.
//				It can be useful for setting up default selected metadata objects or for changing the list of 
//				selected ones.
// ParentSubsystems - ValueList - only child subsystems of this subsystems will be displayed on the 
// 				form (for SSL Integration Wizard).
// SubsystemsWithCIOnly - Boolean - the flag that shows whether there will be only included in the 
//				command interface subsystems in the list (for SSL Integration Wizard).
// SelectSingle - Boolean - indicates whether a single metadata object is selected.
//              In this case multiselect is not allowed, furthermore, double-clicking a row with 
//              object makes selection.
// ChoiceInitialValue - String - full name of metadata where the list will be positioned during the 
//              form opening.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedMetadataObjects.LoadValues(Parameters.SelectedMetadataObjects.UnloadValues());
	
	If Parameters.FilterByMetadataObjects.Count() > 0 Then
		Parameters.MetadataObjectsToSelectCollection.Clear();
		For Each MetadataObjectFullName In Parameters.FilterByMetadataObjects Do
			BaseTypeName = Common.BaseTypeNameByMetadataObject(Metadata.FindByFullName(MetadataObjectFullName.Value));
			If Parameters.MetadataObjectsToSelectCollection.FindByValue(BaseTypeName) = Undefined Then
				Parameters.MetadataObjectsToSelectCollection.Add(BaseTypeName);
			EndIf;
		EndDo;
	EndIf;
	
	If Parameters.Property("SubsystemsWithCIOnly") AND Parameters.SubsystemsWithCIOnly Then
		SubsystemsList = Metadata.Subsystems;
		FillSubsystemList(SubsystemsList);
		SubsystemsWithCIOnly = True;
	EndIf;
	
	If Parameters.Property("SelectSingle", SelectSingle) AND SelectSingle Then
		Items.Check.Visible = False;
	EndIf;
	
	If Parameters.Property("Title") Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	
	Parameters.Property("ChoiceInitialValue", ChoiceInitialValue);
	If Not ValueIsFilled(ChoiceInitialValue)
		AND SelectSingle
		AND Parameters.SelectedMetadataObjects.Count() = 1 Then
		ChoiceInitialValue = Parameters.SelectedMetadataObjects[0].Value;
	EndIf;
	
	MetadataObjectTreeFill();
	
	If Parameters.ParentSubsystems.Count()> 0 Then
		Items.MetadataObjectsTree.InitialTreeView = InitialTreeView.ExpandAllLevels;
	EndIf;
	
	SetInitialCollectionMark(MetadataObjectsTree);
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Settings the initial selection value.
	If CurrentLineIDOnOpen > 0 Then
		
		Items.MetadataObjectsTree.CurrentRow = CurrentLineIDOnOpen;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Form tree "Mark" field click event handler procedure.
&AtClient
Procedure CheckOnChange(Item)

	CurrentData = CurrentItem.CurrentData;
	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;
	SetNestedItemMarks(CurrentData);
	MarkParentItems(CurrentData);

EndProcedure

#EndRegion

#Region MetadataObjectTreeFormTableItemsEventHandlers

&AtClient
Procedure MetadataObjectsTreeChoice(Item, RowSelected, Field, StandardProcessing)

	If SelectSingle Then
		
		SelectExecute();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SelectExecute()
	
	If SelectSingle Then
		
		curData = Items.MetadataObjectsTree.CurrentData;
		If curData <> Undefined
			AND curData.IsMetadataObject Then
			
			SelectedMetadataObjects.Clear();
			SelectedMetadataObjects.Add(curData.FullName, curData.Presentation);
			
		Else
			
			Return;
			
		EndIf;
	Else
		
		SelectedMetadataObjects.Clear();
		
		GetData();
		
	EndIf;
	If ThisObject.OnCloseNotifyDescription = Undefined Then
		Notify("SelectMetadataObjects", SelectedMetadataObjects, Parameters.UUIDSource);
	EndIf;
	Close(SelectedMetadataObjects);
	
EndProcedure

&AtClient
Procedure CloseExecute()
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSubsystemList(SubsystemsList) 
	For Each Subsystem In SubsystemsList Do
		If Subsystem.IncludeInCommandInterface Then
			ItemsOfSubsystemsWithCommandInterface.Add(Subsystem.FullName());
		EndIf;	
		
		If Subsystem.Subsystems.Count() > 0 Then
			FillSubsystemList(Subsystem.Subsystems);
		EndIf;
	EndDo;
EndProcedure

// Fill the tree of configuration object values.
// If the Parameters.MetadataObjectToSelectCollection value list is not empty, the tree is limited 
// by the passed metadata object collection list.
//  If metadata objects from the tree are found in the
// "Parameters.SelectedMetadataObjects" value list, they are marked as selected.
//
&AtServer
Procedure MetadataObjectTreeFill()
	
	MetadataObjectsCollections = New ValueTable;
	MetadataObjectsCollections.Columns.Add("Name");
	MetadataObjectsCollections.Columns.Add("Synonym");
	MetadataObjectsCollections.Columns.Add("Picture");
	MetadataObjectsCollections.Columns.Add("ObjectPicture");
	MetadataObjectsCollections.Columns.Add("IsCommonCollection");
	MetadataObjectsCollections.Columns.Add("FullName");
	MetadataObjectsCollections.Columns.Add("Parent");
	
	MetadataObjectCollections_NewRow("Subsystems",                   NStr("ru = 'Подсистемы'; en = 'Subsystems'; pl = 'Podsystemy';de = 'Untersysteme';ro = 'Subsisteme';tr = 'Alt sistemler'; es_ES = 'Subsistemas'"),                     35, 36, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommonModules",                  NStr("ru = 'Общие модули'; en = 'Common modules'; pl = 'Wspólne moduły';de = 'Allgemeine Module';ro = 'Module comune';tr = 'Ortak modüller'; es_ES = 'Módulos comunes'"),                   37, 38, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("SessionParameters",              NStr("ru = 'Параметры сеанса'; en = 'Session parameters'; pl = 'Parametry sesji';de = 'Sitzungsparameter';ro = 'Sesiunea parametrilor';tr = 'Oturum parametreleri'; es_ES = 'Parámetros de la sesión'"),               39, 40, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Roles",                         NStr("ru = 'Роли'; en = 'Roles'; pl = 'Role';de = 'Rollen';ro = 'Roluri';tr = 'Roller'; es_ES = 'Papeles'"),                           41, 42, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("ExchangePlans",                  NStr("ru = 'Планы обмена'; en = 'Exchange plans'; pl = 'Plany wymiany';de = 'Austauschpläne';ro = 'Planurile de schimb';tr = 'Değiştirme planları'; es_ES = 'Planos de intercambio'"),                   43, 44, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("FilterCriteria",               NStr("ru = 'Критерии отбора'; en = 'Filter criteria'; pl = 'Filtruj kryteria';de = 'Filterkriterien';ro = 'Filtrați criteriile';tr = 'Filtre kriteri'; es_ES = 'Criterio de filtro'"),                45, 46, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("EventSubscriptions",            NStr("ru = 'Подписки на события'; en = 'Event subscriptions'; pl = 'Subskrypcja zdarzeń';de = 'Abonnement für Ereignisse';ro = 'Abonarea la evenimente';tr = 'Etkinlikler aboneliği'; es_ES = 'Suscripción a eventos'"),            47, 48, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("ScheduledJobs",          NStr("ru = 'Регламентные задания'; en = 'Scheduled jobs'; pl = 'Zadania zaplanowane';de = 'Geplante Aufträge';ro = 'Sarcini reglementare';tr = 'Planlanan işler'; es_ES = 'Tareas programadas'"),           49, 50, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("FunctionalOptions",          NStr("ru = 'Функциональные опции'; en = 'Functional options'; pl = 'Opcje funkcjonalne';de = 'Funktionale Optionen';ro = 'Opțiuni funcționale';tr = 'İşlevsel opsiyonlar'; es_ES = 'Opciones funcionales'"),           51, 52, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("FunctionalOptionsParameters", NStr("ru = 'Параметры функциональных опций'; en = 'Functional option parameters'; pl = 'Parametry opcji funkcjonalnych';de = 'Funktionale Optionsparameter';ro = 'Parametrii opțiunii funcționale';tr = 'İşlevsel opsiyon parametreleri'; es_ES = 'Parámetros de la opción funcional'"), 53, 54, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("SettingsStorages",            NStr("ru = 'Хранилища настроек'; en = 'Settings storages'; pl = 'Ustawianie pamięci';de = 'Speicherplatz einstellen';ro = 'Locurile de stocare a setărilor';tr = 'Depolama alanı ayarı'; es_ES = 'Almacenamiento de configuraciones'"),             55, 56, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommonForms",                   NStr("ru = 'Общие формы'; en = 'Common forms'; pl = 'Wspólne formularze';de = 'Allgemeine Formulare';ro = 'Forme comune';tr = 'Ortak formlar'; es_ES = 'Formularios comunes'"),                    57, 58, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommonCommands",                 NStr("ru = 'Общие команды'; en = 'Common commands'; pl = 'Typowe polecenia';de = 'Allgemeine Befehle';ro = 'Comenzi comune';tr = 'Ortak komutlar'; es_ES = 'Comandos comunes'"),                  59, 60, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommandGroups",                 NStr("ru = 'Группы команд'; en = 'Command groups'; pl = 'Grupy poleceń';de = 'Befehlsgruppen';ro = 'Grupuri de comandă';tr = 'Ortak gruplar'; es_ES = 'Grupos comunes'"),                  61, 62, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Interfaces",                   NStr("ru = 'Интерфейсы'; en = 'Interfaces'; pl = 'Interfejsy';de = 'Schnittstellen';ro = 'interfeţe';tr = 'Arayüzler'; es_ES = 'Interfaces'"),                     63, 64, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommonTemplates",                  NStr("ru = 'Общие макеты'; en = 'Common templates'; pl = 'Wspólne szablony';de = 'Allgemeine Vorlagen';ro = 'Șabloane comune';tr = 'Ortak şablonlar'; es_ES = 'Modelos comunes'"),                   65, 66, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CommonPictures",                NStr("ru = 'Общие картинки'; en = 'Common pictures'; pl = 'Wspólne obrazy';de = 'Allgemeine Bilder';ro = 'Imagini obișnuite';tr = 'Ortak resimler'; es_ES = 'Imágenes comunes'"),                 67, 68, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("XDTOPackages",                   NStr("ru = 'XDTO-пакеты'; en = 'XDTO packages'; pl = 'Pakiety XDTO';de = 'XDTO-Pakete';ro = 'Pachete XDTO';tr = 'XDTO-paketleri'; es_ES = 'Paquetes XDTO'"),                    69, 70, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("WebServices",                   NStr("ru = 'Web-сервисы'; en = 'Web services'; pl = 'Serwisy Web';de = 'Web-Services';ro = 'Servicii web';tr = 'Web-servisleri'; es_ES = 'Servicios Web'"),                    71, 72, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("WSReferences",                     NStr("ru = 'WS-ссылки'; en = 'WS references'; pl = 'WS-references';de = 'WS Referenzen';ro = 'Referințe WS';tr = 'WS referanslar'; es_ES = 'Referencias WS'"),                      73, 74, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Styles",                        NStr("ru = 'Стили'; en = 'Styles'; pl = 'Style';de = 'Arten';ro = 'Stiluri';tr = 'Stiller'; es_ES = 'Diseños'"),                          75, 76, True, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Languages",                        NStr("ru = 'Языки'; en = 'Languages'; pl = 'Języki';de = 'Sprachen';ro = 'Limbi';tr = 'Diller'; es_ES = 'Idiomas'"),                          77, 78, True, MetadataObjectsCollections);
	
	MetadataObjectCollections_NewRow("Constants",                    NStr("ru = 'Константы'; en = 'Constants'; pl = 'Stałe';de = 'Konstanten';ro = 'Constante';tr = 'Sabitler'; es_ES = 'Constantes'"),                      PictureLib.Constant,              PictureLib.Constant,                    False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Catalogs",                  NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'"),                    PictureLib.Catalog,             PictureLib.Catalog,                   False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Documents",                    NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'"),                      PictureLib.Document,               PictureLib.DocumentObject,               False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("DocumentJournals",            NStr("ru = 'Журналы документов'; en = 'Document journals'; pl = 'Dzienniki zdarzeń dokumentu';de = 'Dokumentprotokolle';ro = 'Registrele documentelor';tr = 'Belge günlükleri'; es_ES = 'Registros del documento'"),             PictureLib.DocumentJournal,       PictureLib.DocumentJournal,             False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Enums",                 NStr("ru = 'Перечисления'; en = 'Enumerations'; pl = 'Przelewy';de = 'Transfers';ro = 'Secvențe';tr = 'Transferler'; es_ES = 'Transferencias'"),                   PictureLib.Enum,           PictureLib.Enum,                 False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Reports",                       NStr("ru = 'Отчеты'; en = 'Reports'; pl = 'Sprawozdania';de = 'Berichte';ro = 'Rapoarte';tr = 'Raporlar'; es_ES = 'Informes'"),                         PictureLib.Report,                  PictureLib.Report,                        False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("DataProcessors",                    NStr("ru = 'Обработки'; en = 'Data processors'; pl = 'Opracowania';de = 'Datenverarbeiter';ro = 'Procesoare de date';tr = 'Veri işlemcileri'; es_ES = 'Procesadores de datos'"),                      PictureLib.DataProcessor,              PictureLib.DataProcessor,                    False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("ChartsOfCharacteristicTypes",      NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'"),      PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("ChartsOfAccounts",                  NStr("ru = 'Планы счетов'; en = 'Charts of accounts'; pl = 'Plany kont';de = 'Kontenpläne';ro = 'Planurile conturilor';tr = 'Hesap çizelgeleri'; es_ES = 'Diagramas de las cuentas'"),                   PictureLib.ChartOfAccounts,             PictureLib.ChartOfAccountsObject,             False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("ChartsOfCalculationTypes",            NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'"),      PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("InformationRegisters",             NStr("ru = 'Регистры сведений'; en = 'Information registers'; pl = 'Rejestry informacji';de = 'Informationsregister';ro = 'Registre de date';tr = 'Bilgi kayıtları'; es_ES = 'Registros de información'"),              PictureLib.InformationRegister,        PictureLib.InformationRegister,              False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("AccumulationRegisters",           NStr("ru = 'Регистры накопления'; en = 'Accumulation registers'; pl = 'Rejestry akumulacji';de = 'Akkumulationsregister';ro = 'Registre de acumulare';tr = 'Birikeçler'; es_ES = 'Registros de acumulación'"),            PictureLib.AccumulationRegister,      PictureLib.AccumulationRegister,            False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("AccountingRegisters",          NStr("ru = 'Регистры бухгалтерии'; en = 'Accounting registers'; pl = 'Rejestry księgowe';de = 'Buchhaltungsregister';ro = 'Registre contabile';tr = 'Muhasebe kayıtları'; es_ES = 'Registros de contabilidad'"),           PictureLib.AccountingRegister,     PictureLib.AccountingRegister,           False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("CalculationRegisters",              NStr("ru = 'Регистры расчета'; en = 'Calculation registers'; pl = 'Rejestry obliczeń';de = 'Berechnungsregister';ro = 'Registre de calcul';tr = 'Hesaplama kayıtları'; es_ES = 'Registros de cálculos'"),               PictureLib.CalculationRegister,         PictureLib.CalculationRegister,               False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("BusinessProcesses",               NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Procesele de afaceri';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'"),                PictureLib.BusinessProcess,          PictureLib.BusinessProcessObject,          False, MetadataObjectsCollections);
	MetadataObjectCollections_NewRow("Tasks",                       NStr("ru = 'Задачи'; en = 'Tasks'; pl = 'Zadania';de = 'Aufgaben';ro = 'Sarcini';tr = 'Görevler'; es_ES = 'Tareas'"),                         PictureLib.Task,                 PictureLib.TaskObject,                 False, MetadataObjectsCollections);
	
	// Creating the predefined items.
	ItemParameters = MetadataObjectTreeItemParameters();
	ItemParameters.Name = Metadata.Name;
	ItemParameters.Synonym = Metadata.Synonym;
	ItemParameters.Picture = 79;
	ItemParameters.Parent = MetadataObjectsTree;
	ConfigurationItem = NewTreeRow(ItemParameters);
	
	ItemParameters = MetadataObjectTreeItemParameters();
	ItemParameters.Name = "Common";
	ItemParameters.Synonym = NStr("ru = 'Общие'; en = 'Common'; pl = 'Ogólne';de = 'Allgemein';ro = 'Comune';tr = 'Ortak'; es_ES = 'Comunes'");
	ItemParameters.Picture = 0;
	ItemParameters.Parent = ConfigurationItem;
	ItemCommon = NewTreeRow(ItemParameters);
	
	// FIlling the metadata object tree.
	For Each Row In MetadataObjectsCollections Do
		If Parameters.MetadataObjectsToSelectCollection.Count() = 0
			Or Parameters.MetadataObjectsToSelectCollection.FindByValue(Row.Name) <> Undefined Then
			Row.Parent = ?(Row.IsCommonCollection, ItemCommon, ConfigurationItem);
			AddMetadataObjectTreeItem(Row, ?(Row.Name = "Subsystems", Metadata.Subsystems, Undefined));
		EndIf;
	EndDo;
	
	If ItemCommon.GetItems().Count() = 0 Then
		ConfigurationItem.GetItems().Delete(ItemCommon);
	EndIf;
	
EndProcedure

// Returns a new metadata object tree item parameter structure.
//
// Returns:
//   Structure containing fields:
//     Name           - String - name of the parent item.
//     Synonym       - String - synonym of the parent item.
//     Mark       - Boolean - the initial mark of a collection or metadata object.
//     Picture      - Number - code of the parent item picture.
//     ObjectPicture - Number  - code of the subitem picture.
//     Parent        - reference to the value tree item that is a root of the item to be added.
//                       
//
&AtServer
Function MetadataObjectTreeItemParameters()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Name", "");
	ParametersStructure.Insert("FullName", "");
	ParametersStructure.Insert("Synonym", "");
	ParametersStructure.Insert("Check", 0);
	ParametersStructure.Insert("Picture", 0);
	ParametersStructure.Insert("ObjectPicture", Undefined);
	ParametersStructure.Insert("Parent", Undefined);
	
	Return ParametersStructure;
	
EndFunction

// Adds a new row to the form value tree and fills the full row set from metadata by the passed 
// parameter.
//
// If the Subsystems parameter is filled, the function is called recursively for all child subsystems.
//
// Parameters:
//   ItemParameters - Structure containing fields:
//     Name           - String - name of the parent item.
//     Synonym       - String - synonym of the parent item.
//     Mark       - Boolean - the initial mark of a collection or metadata object.
//     Picture      - Number - code of the parent item picture.
//     ObjectPicture - Number  - code of the subitem picture.
//     Parent        - reference to the value tree item that is a root of the item to be added.
//                       
//   Subsystems      - If filled, it contains Metadata.Subsystems value (an item collection).
//   Check       - Boolean - indicates whether a check for subordination to parent subsystems is required.
// 
// Returns:
// 
//   Metadata object tree row.
//
&AtServer
Function AddMetadataObjectTreeItem(ItemParameters, Subsystems = Undefined, CheckSSL = True)
	
	// Checking whether command interface is available in tree leaves only.
	If Subsystems <> Undefined  AND Parameters.Property("SubsystemsWithCIOnly") 
		AND Not IsBlankString(ItemParameters.FullName) 
		AND ItemsOfSubsystemsWithCommandInterface.FindByValue(ItemParameters.FullName) = Undefined Then
		Return Undefined;
	EndIf;
	
	If Subsystems = Undefined Then
		
		If Metadata[ItemParameters.Name].Count() = 0 Then
			
			// There are no metadata objects in the current tree branch.
			// For example, if there are no accounting registers, the Accounting registers root should not be 
			// added.
			Return Undefined;
			
		EndIf;
		
		NewRow = NewTreeRow(ItemParameters, Subsystems <> Undefined AND Subsystems <> Metadata.Subsystems);
		
		For Each MetadataCollectionItem In Metadata[ItemParameters.Name] Do
			
			If Parameters.FilterByMetadataObjects.Count() > 0
				AND Parameters.FilterByMetadataObjects.FindByValue(MetadataCollectionItem.FullName()) = Undefined Then
				Continue;
			EndIf;
			
			ItemParameters = MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.ObjectPicture = ItemParameters.ObjectPicture;
			ItemParameters.Parent = NewRow;
			NewTreeRow(ItemParameters, True);
		EndDo;
		
		Return NewRow;
		
	EndIf;
		
	If Subsystems.Count() = 0 AND ItemParameters.Name = "Subsystems" Then
		// If no subsystems are found, the Subsystems root should not be added.
		Return Undefined;
	EndIf;
	
	NewRow = NewTreeRow(ItemParameters, Subsystems <> Undefined AND Subsystems <> Metadata.Subsystems);
	
	For Each MetadataCollectionItem In Subsystems Do
		
		If Not CheckSSL
			Or Parameters.ParentSubsystems.Count() = 0
			Or Parameters.ParentSubsystems.FindByValue(MetadataCollectionItem.Name) <> Undefined Then
			
			ItemParameters = MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.Picture = ItemParameters.Picture;
			ItemParameters.ObjectPicture = ItemParameters.ObjectPicture;
			ItemParameters.Parent = NewRow;
			AddMetadataObjectTreeItem(ItemParameters, MetadataCollectionItem.Subsystems, False);
		EndIf;
	EndDo;
	
	Return NewRow;
	
EndFunction

&AtServer
Function NewTreeRow(RowParameters, IsMetadataObject = False)
	
	Collection = RowParameters.Parent.GetItems();
	NewRow = Collection.Add();
	NewRow.Name                 = RowParameters.Name;
	NewRow.Presentation       = ?(ValueIsFilled(RowParameters.Synonym), RowParameters.Synonym, RowParameters.Name);
	NewRow.Check             = ?(Parameters.SelectedMetadataObjects.FindByValue(RowParameters.FullName) = Undefined, 0, 1);
	NewRow.Picture            = RowParameters.Picture;
	NewRow.FullName           = RowParameters.FullName;
	NewRow.IsMetadataObject = IsMetadataObject;
	
	If NewRow.IsMetadataObject 
		AND NewRow.FullName = ChoiceInitialValue Then
		CurrentLineIDOnOpen = NewRow.GetID();
	EndIf;
	
	Return NewRow;
	
EndFunction

// Adds a new row to configuration metadata object type value table.
// 
//
// Parameters:
//   Name           - a metadata object name, or a metadata object kind name.
//   Synonym       - a metadata object synonym.
//   Picture       - picture referring to the metadata object or to the metadata object type.
//                 
//   IsCommonCollection - indicates whether the current item contains subitems.
//
&AtServer
Procedure MetadataObjectCollections_NewRow(Name, Synonym, Picture, ObjectPicture, IsCommonCollection, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name               = Name;
	NewRow.Synonym           = Synonym;
	NewRow.Picture          = Picture;
	NewRow.ObjectPicture   = ObjectPicture;
	NewRow.IsCommonCollection = IsCommonCollection;
	
EndProcedure

// Recursively sets or clears mark for parent items of the passed item.
//
// Parameters:
//   Element      - FormDataTreeItemCollection.
//
&AtClient
Procedure MarkParentItems(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ParentItems = Parent.GetItems();
	If ParentItems.Count() = 0 Then
		Parent.Check = 0;
	ElsIf Item.Check = 2 Then
		Parent.Check = 2;
	Else
		Parent.Check = ItemMarkValues(ParentItems);
	EndIf;
	
	MarkParentItems(Parent);
	
EndProcedure

&AtClient
Function ItemMarkValues(ParentItems)
	
	HasMarkedItems    = False;
	HasUnmarkedItems = False;
	
	For each ParentItem In ParentItems Do
		
		If ParentItem.Check = 2 OR (HasMarkedItems AND HasUnmarkedItems) Then
			HasMarkedItems    = True;
			HasUnmarkedItems = True;
			Break;
		ElsIf ParentItem.IsMetadataObject Then
			HasMarkedItems    = HasMarkedItems    OR    ParentItem.Check;
			HasUnmarkedItems = HasUnmarkedItems OR NOT ParentItem.Check;
		Else
			NestedItems = ParentItem.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValues(NestedItems);
			HasMarkedItems    = HasMarkedItems    OR    ParentItem.Check OR    NestedItemMarkValue;
			HasUnmarkedItems = HasUnmarkedItems OR NOT ParentItem.Check OR NOT NestedItemMarkValue;
		EndIf;
	EndDo;
	
	If HasMarkedItems Then
		If HasUnmarkedItems Then
			Return 2;
		Else
			If SubsystemsWithCIOnly Then
				Return 2;
			Else
				Return 1;
			EndIf;
		EndIf;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Procedure MarkParentItemsAtServer(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ParentItems = Parent.GetItems();
	If ParentItems.Count() = 0 Then
		Parent.Check = 0;
	ElsIf Item.Check = 2 Then
		Parent.Check = 2;
	Else
		Parent.Check = ItemMarkValuesAtServer(ParentItems);
	EndIf;
	
	MarkParentItemsAtServer(Parent);

EndProcedure

&AtServer
Function ItemMarkValuesAtServer(ParentItems)
	
	HasMarkedItems    = False;
	HasUnmarkedItems = False;
	
	For each ParentItem In ParentItems Do
		
		If ParentItem.Check = 2 OR (HasMarkedItems AND HasUnmarkedItems) Then
			HasMarkedItems    = True;
			HasUnmarkedItems = True;
			Break;
		ElsIf ParentItem.IsMetadataObject Then
			HasMarkedItems    = HasMarkedItems    OR    ParentItem.Check;
			HasUnmarkedItems = HasUnmarkedItems OR NOT ParentItem.Check;
		Else
			NestedItems = ParentItem.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValuesAtServer(NestedItems);
			HasMarkedItems    = HasMarkedItems    OR    ParentItem.Check OR    NestedItemMarkValue;
			HasUnmarkedItems = HasUnmarkedItems OR NOT ParentItem.Check OR NOT NestedItemMarkValue;
		EndIf;
	EndDo;
	
	Return ?(HasMarkedItems AND HasUnmarkedItems, 2, ?(HasMarkedItems, 1, 0));
	
EndFunction

// Selects a mark of the metadata object collections that does not have metadata objects or whose 
// metadata object marks are selected.
// 
//
// Parameters:
//   Element      - FormDataTreeItemCollection.
//
&AtServer
Procedure SetInitialCollectionMark(Parent)
	
	NestedItems = Parent.GetItems();
	
	For Each NestedItem In NestedItems Do
		If NestedItem.Check Then
			MarkParentItemsAtServer(NestedItem);
		EndIf;
		SetInitialCollectionMark(NestedItem);
	EndDo;
	
EndProcedure

// The procedure recursively sets or clears mark for nested items of starting with the passed item.
// 
//
// Parameters:
//   Element      - FormDataTreeItemCollection.
//
&AtClient
Procedure SetNestedItemMarks(Item)

	NestedItems = Item.GetItems();
	
	If NestedItems.Count() = 0 Then
		If Not Item.IsMetadataObject Then
			Item.Check = 0;
		EndIf;
	Else
		For Each NestedItem In NestedItems Do
			If Not SubsystemsWithCIOnly Then
				NestedItem.Check = Item.Check;
			EndIf;
			SetNestedItemMarks(NestedItem);
		EndDo;
	EndIf;
	
EndProcedure

// Fills a list with the selected tree items.
// The function recursively scans the item tree and if an item is selected adds its FullName to the 
// selected list.
//
// Parent      - FormDataTreeItem
//
&AtServer
Procedure GetData(Parent = Undefined)
	
	Parent = ?(Parent = Undefined, MetadataObjectsTree, Parent);
	
	ItemCollection = Parent.GetItems();
	
	For Each Item In ItemCollection Do
		If Item.Check = 1 AND Not IsBlankString(Item.FullName) Then
			SelectedMetadataObjects.Add(Item.FullName, Item.Presentation);
		EndIf;
		GetData(Item);
	EndDo;
	
EndProcedure

#EndRegion
