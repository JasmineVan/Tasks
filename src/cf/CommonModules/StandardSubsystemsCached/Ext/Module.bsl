///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns descriptions of all configuration libraries, including the configuration itself.
// 
//
Function SubsystemsDetails() Export
	
	SubsystemsModules = New Array;
	SubsystemsModules.Add("InfobaseUpdateSSL");
	
	ConfigurationSubsystemsOverridable.SubsystemsOnAdd(SubsystemsModules);
	
	ConfigurationDetailsFound = False;
	SubsystemsDetails = New Structure;
	SubsystemsDetails.Insert("Order",  New Array);
	SubsystemsDetails.Insert("ByNames", New Map);
	
	AllRequiredSubsystems = New Map;
	
	For Each ModuleName In SubsystemsModules Do
		
		Details = NewSubsystemDescription();
		Module = Common.CommonModule(ModuleName);
		Module.OnAddSubsystem(Details);
		
		If SubsystemsDetails.ByNames.Get(Details.Name) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при подготовке описаний подсистем:
				           |в описании подсистемы (см. процедуру %1.ПриДобавленииПодсистемы)
				           |указано имя подсистемы ""%2"", которое уже зарегистрировано ранее.'; 
				           |en = 'Cannot prepare subsystem descriptions.
				           |The subsystem description (see %1.OnAddSubsystem procedure)
				           |contains subsystem name ""%2,"" which is already registered.'; 
				           |pl = 'Wystąpił błąd podczas
				           |przygotowywania opisów podsystemów: w opisie podsystemu (zob. procedurę %1.OdAdd Subsystem)
				           |podano nazwę podsystemu ""%2"", która została już zarejestrowana.';
				           |de = 'Beim
				           |Vorbereiten der Subsystembeschreibungen ist ein Fehler aufgetreten: In der Beschreibung des Subsystems (siehe die Prozedur %1.AufSubsystemHinzufügen) wird der
				           |Subsystemname ""%2"" angegeben, der bereits registriert wurde.';
				           |ro = 'Erori la pregătirea descrierilor subsistemelor:
				           |în descrierea subsistemului (vezi procedura %1.ПриДобавленииПодсистемы)
				           |este indicat numele subsistemului ""%2"" deja înregistrat anterior.';
				           |tr = 'Alt  sistemlerin açıklamalarını hazırlama sırasında bir hata 
				           |oluştu: alt  sistem tanımında (bkz.%1AltSitemEklenirken prosedürü) daha önce kaydedilen %2 alt sistem adı 
				           |"" belirtilmiştir.'; 
				           |es_ES = 'Ha ocurrido un error al
				           |preparar las descripciones de subsistemas: en la descripción del subsistema (ver el procedimiento %1. OnAddSubsystem)
				           |nombre del subsistema ""%2"" está especificado que ya se había registrado.'"),
				ModuleName, Details.Name);
			Raise ErrorText;
		EndIf;
		
		If Details.Name = Metadata.Name Then
			ConfigurationDetailsFound = True;
			Details.Insert("IsConfiguration", True);
		Else
			Details.Insert("IsConfiguration", False);
		EndIf;
		
		Details.Insert("MainServerModule", ModuleName);
		
		SubsystemsDetails.ByNames.Insert(Details.Name, Details);
		// Setting up the subsystem order according to the adding order of main modules.
		SubsystemsDetails.Order.Add(Details.Name);
		// Collecting all required subsystems.
		For each RequiredSubsystem In Details.RequiredSubsystems Do
			If AllRequiredSubsystems.Get(RequiredSubsystem) = Undefined Then
				AllRequiredSubsystems.Insert(RequiredSubsystem, New Array);
			EndIf;
			AllRequiredSubsystems[RequiredSubsystem].Add(Details.Name);
		EndDo;
	EndDo;
	
	// Verifying the main configuration description.
	If ConfigurationDetailsFound Then
		Details = SubsystemsDetails.ByNames[Metadata.Name];
		
		If Details.Version <> Metadata.Version Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при подготовке описаний подсистем:
				           |версия ""%2"" конфигурации ""%1"" (см. процедуру %3.ПриДобавленииПодсистемы)
				           |не совпадает с версией конфигурации в метаданных ""%4"".'; 
				           |en = 'Cannot prepare subsystem descriptions.
				           |Version %2 of ""%1"" configuration (see %3.OnAddSubsystem procedure)
				           |does not match the configuration version in the metadata: %4.'; 
				           |pl = 'Wystąpił błąd podczas przygotowywania opisów podsystemów:
				           |wersja ""%2"" konfiguracji ""%1"" (zob. procedurę %3.OnAddSubsystem)
				           |nie pasuje do wersji konfiguracyjnej w metadanych ""%4"".';
				           |de = 'Beim Vorbereiten der Subsystembeschreibungen ist ein Fehler aufgetreten: Die
				           |Version ""%2"" der Konfiguration ""%1"" (siehe die Prozedur %3.AufSubsystemHinzufügen)
				           |stimmt nicht mit der Konfigurationsversion in den Metadaten ""%4"" überein.';
				           |ro = 'Eroare la pregătirea descrierilor subsistemelor:
				           |versiunea ""%2"" a configurației ""%1"" (vezi procedura %3.ПриДобавленииПодсистемы)
				           |nu coincide cu versiunea configurației în metadate ""%4"".';
				           |tr = 'Alt  sistem açıklamaları hazırlanırken bir hata oluştu: "
" yapılandırmasının  ""%2"" sürümü (bkz. %1AltSistemEklenirken prosedürü), meta veriler ""%3"" içindeki %4 yapılandırma 
				           |sürümü ile eşleşmiyor.'; 
				           |es_ES = 'Ha ocurrido un error al preparar las descripciones de subsistemas:
				           |versión ""%2"" de la configuración ""%1"" (ver el procedimiento %3.OnAddSubsystem)
				           |no coincide con la versión de la configuración en los metadatos ""%4"".'"),
				Details.Name,
				Details.Version,
				Details.MainServerModule,
				Metadata.Version);
			Raise ErrorText;
		EndIf;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при подготовке описаний подсистем:
			           |в общих модулях, указанных в процедуре ПодсистемыКонфигурацииПереопределяемый.ПриДобавленииПодсистемы
			           |не найдено описание подсистемы, совпадающей с именем конфигурации ""%1"".'; 
			           |en = 'Cannot prepare subsystem descriptions.
			           |The description of a subsystem matching the configuration name ""%1""
			           |is not found in the common modules specified in ConfigurationSubsystemsOverridable.OnAddSubsystem procedure.'; 
			           |pl = 'Błąd podczas przygotowania opisów podsystemów:
			           |w ogólnych modułach opisanych w procedurze ConfigurationSubsystemsOverridable.OnAddSubsystem
			           |nie znaleziono opis podsystemu, który pokrywa się z nazwą konfiguracji ""%1"".';
			           |de = 'Fehler beim Vorbereiten der Subsystembeschreibungen:
			           |in den allgemeinen Modulen, die in der Prozedur ConfigurationSubsystemsOverridable.OnAddSubsystem
			           |angegeben sind, wurde keine mit dem Konfigurationsnamen ""%1"" übereinstimmende Beschreibung des Subsystems gefunden.';
			           |ro = 'Eroare la pregătirea descrierilor subsistemelor:
			           |în modulele comune indicate în procedura ConfigurationSubsystemsOverridable.OnAddSubsystem
			           |nu a fost găsită descrierea subsistemului care coincide cu numele configurației ""%1"".';
			           |tr = 'Alt sistem açıklamaları hazırlanırken hata oluştu: 
			           |ConfigurationSubsystemsOverridable.OnAddSubsystem prosedüründe belirtilen genel modüllerde 
			           | ""%1"" yapılandırıcının adı ile uyumlu alt sistemin açıklaması bulunamadı. '; 
			           |es_ES = 'Error al preparar las descripciones de subsistemas:
			           | en los módulos comunes indicados en el procedimiento ConfigurationSubsystemsOverridable.OnAddSubsystem
			           |no se ha encontrado la descripción del subsistema que coincida con el nombre de la configuración ""%1"".'"),
			Metadata.Name);
		Raise ErrorText;
	EndIf;
	
	// Checking whether all required subsystems are presented.
	For each KeyAndValue In AllRequiredSubsystems Do
		If SubsystemsDetails.ByNames.Get(KeyAndValue.Key) = Undefined Then
			DependentSubsystems = "";
			For Each DependentSubsystem In KeyAndValue.Value Do
				DependentSubsystems = Chars.LF + DependentSubsystem;
			EndDo;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при подготовке описаний подсистем:
				           |не найдена подсистема ""%1"" требуемая для подсистем: %2.'; 
				           |en = 'Cannot prepare subsystem descriptions.
				           |Subsystem ""%1"" is not found. It is required for the following subsystems:%2'; 
				           |pl = 'Wystąpił błąd podczas przygotowywania opisów podsystemów:
				           |podsystem ""%1"" nie jest wymagany dla podsystemów: %2.';
				           |de = 'Beim Vorbereiten der Subsystembeschreibungen ist ein Fehler aufgetreten:
				           |Subsystem ""%1"" wurde für Subsysteme nicht benötigt: %2.';
				           |ro = 'Eroare la pregătirea descrierilor subsistemelor:
				           |nu a fost găsit subsistemul ""%1"" necesar pentru subsistemele: %2.';
				           |tr = 'Alt sistem açıklamaları hazırlanırken bir hata oluştu: 
				           |alt sistemler için ""%1"" alt sistem gerekli değil:%2.'; 
				           |es_ES = 'Ha ocurrido un error al preparar las descripciones de subsistemas:
				           |el subsistema ""%1"" no se ha encontrado, requerido para los subsistemas: %2.'"),
				KeyAndValue.Key,
				DependentSubsystems);
			Raise ErrorText;
		EndIf;
	EndDo;
	
	// Setting up the subsystem order according to dependencies.
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		Name = KeyAndValue.Key;
		Order = SubsystemsDetails.Order.Find(Name);
		For each RequiredSubsystem In KeyAndValue.Value.RequiredSubsystems Do
			RequiredSubsystemOrder = SubsystemsDetails.Order.Find(RequiredSubsystem);
			If Order < RequiredSubsystemOrder Then
				Interdependency = SubsystemsDetails.ByNames[RequiredSubsystem
					].RequiredSubsystems.Find(Name) <> Undefined;
				If Interdependency Then
					NewOrder = RequiredSubsystemOrder;
				Else
					NewOrder = RequiredSubsystemOrder + 1;
				EndIf;
				If Order <> NewOrder Then
					SubsystemsDetails.Order.Insert(NewOrder, Name);
					SubsystemsDetails.Order.Delete(Order);
					Order = NewOrder - 1;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// Moving the configuration description to the end of the array.
	Index = SubsystemsDetails.Order.Find(Metadata.Name);
	If SubsystemsDetails.Order.Count() > Index + 1 Then
		SubsystemsDetails.Order.Delete(Index);
		SubsystemsDetails.Order.Add(Metadata.Name);
	EndIf;
	
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		KeyAndValue.Value.RequiredSubsystems =
			New FixedArray(KeyAndValue.Value.RequiredSubsystems);
		
		SubsystemsDetails.ByNames[KeyAndValue.Key] =
			New FixedStructure(KeyAndValue.Value);
	EndDo;
	
	Return Common.FixedData(SubsystemsDetails);
	
EndFunction

// Returns True if the privileged mode has been set using the UsePrivilegedMode start parameter.
// 
//
// Supported client applications only (external connections are not supported).
// 
//
Function PrivilegedModeSetOnStart() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.ClientParametersAtServer.Get(
		"PrivilegedModeSetOnStart") = True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Application and extension metadata object ID usage.

// For internal use only.
Function DisableMetadataObjectsIDs() Export
	
	CommonParameters = Common.CommonCoreParameters();
	
	If NOT CommonParameters.DisableMetadataObjectsIDs Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 OR Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors")
	 OR Common.SubsystemExists("StandardSubsystems.ReportMailing")
	 OR Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		Raise
			NStr("ru = 'Невозможно отключить справочник Идентификаторы объектов метаданных,
			           |если используется любая из следующих подсистем:
			           |- ВариантыОтчетов,
			           |- ДополнительныеОтчетыИОбработки,
			           |- РассылкаОтчетов,
			           |- УправлениеДоступом.'; 
			           |en = 'Cannot disable ""Metadata object IDs"" catalog
			           |if any of the following subsystems is available:
			           |- ReportsOptions
			           |- AdditionalReportsAndDataProcessors
			           |- ReportsMailing
			           |- AccessManagement'; 
			           |pl = 'Niemożliwe jest wyłączenie katalogu Identyfikator obiektów metadanych,
			           |jeśli używany jest jakikolwiek z następujących podsystemów:
			           |- ReportVariants, 
			           |- AdditionalReportsAndDataProcessors, 
			           |- ReportsMail, 
			           |- AccessManagement.';
			           |de = 'Der Katalog Metadatenobjekte-IDs kann nicht deaktiviert werden, 
			           |wenn eines der folgenden Subsysteme verwendet wird:
			           |- Berichtsvarianten, 
			           |- zusätzliche Berichte und Datenprozessoren, 
			           |- Berichte Mail, 
			           |- Zugriffsverwaltung.';
			           |ro = 'Nu puteți dezactiva clasificatorul Identificatorii obiectelor de metadate,
			           |dacă este utilizată oricare din următoarele subsisteme:
			           |- ВариантыОтчетов,
			           |- ДополнительныеОтчетыИОбработки,
			           |- РассылкаОтчетов,
			           |- УправлениеДоступом.';
			           |tr = 'Aşağıdaki  alt sistemlerden herhangi biri kullanılıyorsa, 
			           |Meta Veri Nesneleri  Tanımlayıcılar kataloğu devre dışı bırakılamaz:
			           | -  RaporSeçenekleri, 
			           |- EkRaporlarVeVeriİşlemcileri,
			           |- RaporGönderimi, 
			           |-  ErişimYönetimi.'; 
			           |es_ES = 'Imposible desactivar el catálogo de Identificadores de Objetos de Metadatos
			           |, si uno de los siguientes subsistemas está en uso:
			           |- ReportVariants, 
			           |- AdditionalReportsAndDataProcessors,
			           |- ReportsMail, 
			           |- AccessManagement.'");
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
Function MetadataObjectIDsUsageCheck(CheckForUpdates = False, ExtensionsObjects = False) Export
	
	Catalogs.MetadataObjectIDs.CheckForUsage(ExtensionsObjects);
	
	If CheckForUpdates Then
		Catalogs.MetadataObjectIDs.IsDataUpdated(True, ExtensionsObjects);
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Data exchange operation procedures and functions.

// Returns a flag that shows whether the full DIB is used in the infobase (without filters).
// Checking with more accurately algorithm if the "Data exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - clarifies which DIB is checked.
//                        The following values are available:
//                        - Empty string - any DIB
//                        - WithFilter - DIB with the
//                        - Full filter - DIB without filters.
// 
// Returns: Boolean.
//
Function DIBUsed(FilterByPurpose = "") Export
	
	If DIBNodes(FilterByPurpose).Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a list of the DIB nodes used in the infobase (without filters).
// Checking with more accurately algorithm if the "Data exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - specifies the purposes of DIB exchange plan nodes to be returned.
//                        The following values are available:
//                        - Empty string - all DIB nodes
//                        - WithFilter will be returned - DIB nodes with the
//                        - Full filter will be returned - DIB nodes without filters will be returned.
// 
// Returns: ValueList.
//
Function DIBNodes(FilterByPurpose = "") Export
	
	FilterByPurpose = Upper(FilterByPurpose);
	
	NodesList = New ValueList;
	
	DIBExchangePlans = DIBExchangePlans();
	Query = New Query();
	For Each ExchangePlanName In DIBExchangePlans Do
		
		If ValueIsFilled(FilterByPurpose)
			AND Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			
			CommonModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			DIBPurpose = Upper(CommonModuleDataExchangeServer.ExchangePlanPurpose(ExchangePlanName));
			
			If FilterByPurpose = "WITHFILTER" AND DIBPurpose <> "DIBWITHFILTER"
				Or FilterByPurpose = "FULL" AND DIBPurpose <> "DIB" Then
				Continue;
			EndIf;
		EndIf;
		
		Query.Text =
		"SELECT
		|	ExchangePlan.Ref AS Ref
		|FROM
		|	ExchangePlan.[ExchangePlanName] AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		Query.Text = StrReplace(Query.Text, "[ExchangePlanName]", ExchangePlanName);
		NodeSelection = Query.Execute().Select();
		While NodeSelection.Next() Do
			NodesList.Add(NodeSelection.Ref);
		EndDo;
	EndDo;
	
	Return NodesList;
	
EndFunction

// Returns a list of DIB exchange plans.
// For SaaS mode, returns the list of a separated DIB exchange plans.
// 
//
Function DIBExchangePlans() Export
	
	Result = New Array;
	
	If Common.DataSeparationEnabled() Then
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If Left(ExchangePlan.Name, 7) = "Delete" Then
				Continue;
			EndIf;
			
			If Common.SubsystemExists("StandardSubsystems.SaaS") Then
				ModuleSaaS = Common.CommonModule("SaaS");
				IsSeparatedData = ModuleSaaS.IsSeparatedMetadataObject(
					ExchangePlan.FullName(), ModuleSaaS.MainDataSeparator());
			Else
				IsSeparatedData = False;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase
				AND IsSeparatedData Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If Left(ExchangePlan.Name, 7) = "Delete" Then
				Continue;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Depermines the data registration mode on exchange plan nodes.
// 
// Parameters:
//  FullObjectName - String - the full name of a metadata object to check.
//  ExchangePlanName - String - exchange plan to check.
//
// Returns:
//  Undefined - exchange plan does not include the object,
//  "AutoRecord" - object is included in the exchange plan content, autorecord is enabled,
//  "AutoRecordDisabled" - the object is included in an exchange plan content, autorecord is 
//                               disabled, objects are processed when creating of the initial DIB image.
//  "ProgramRegistration" - object is included in the exchange plan content, autorecord is disabled, 
//                               registering in the script using event subscriptions, objects are 
//                               processed when the initial DIB image is created.
//
Function ExchangePlanDataRegistrationMode(FullObjectName, ExchangePlanName) Export
	
	MetadataObject = Metadata.FindByFullName(FullObjectName);
	
	ExchangePlanCompositionItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(MetadataObject);
	If ExchangePlanCompositionItem = Undefined Then
		Return Undefined;
	ElsIf ExchangePlanCompositionItem.AutoRegistration = AutoChangeRecord.Allow Then
		Return "AutoRecordEnabled";
	EndIf;
	
	// Analyzing event subscriptions for complex cases, when platform autorecord engine is disabled for 
	// the metadata object.
	For each Subscription In Metadata.EventSubscriptions Do
		SubscriptionTitleBeginning = ExchangePlanName + "Registration";
		If Upper(Left(Subscription.Name, StrLen(SubscriptionTitleBeginning))) = Upper(SubscriptionTitleBeginning) Then
			For each Type In Subscription.Source.Types() Do
				If MetadataObject = Metadata.FindByType(Type) Then
					Return "ProgramRegistration";
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return "AutoRecordDisabled";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other.

// Metadata object availability by functional options.
Function ObjectsEnabledByOption() Export
	
	Parameters = New Structure(StandardSubsystemsCached.InterfaceOptions());
	
	ObjectsEnabled = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		Value = -1;
		For Each Item In FunctionalOption.Content Do
			If Item.Object = Undefined Then
				Continue;
			EndIf;
			If Value = -1 Then
				Value = GetFunctionalOption(FunctionalOption.Name, Parameters);
			EndIf;
			FullName = Item.Object.FullName();
			If Value = True Then
				ObjectsEnabled.Insert(FullName, True);
			Else
				If ObjectsEnabled[FullName] = Undefined Then
					ObjectsEnabled.Insert(FullName, False);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	Return New FixedMap(ObjectsEnabled);
	
EndFunction

#EndRegion

#Region Private

// Parameters applied to command interface items associated with parametric functional options.
Function InterfaceOptions() Export 
	
	InterfaceOptions = New Structure;
	CommonOverridable.OnDetermineInterfaceFunctionalOptionsParameters(InterfaceOptions);
	Return New FixedStructure(InterfaceOptions);
	
EndFunction

// Returns a map of the "functional" subsystem names and the True value.
// A subsystem is considered functional if its "Include in command interface" check box is cleared.
//
Function SubsystemsNames() Export
	
	DisabledSubsystems = New Map;
	CommonOverridable.OnDetermineDisabledSubsystems(DisabledSubsystems);
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata, DisabledSubsystems);
	
	Return New FixedMap(Names);
	
EndFunction

Function AllRefsTypeDetails() Export
	
	Return New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
		New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
			Catalogs.AllRefsType(),
			Documents.AllRefsType().Types()),
			ExchangePlans.AllRefsType().Types()),
			Enums.AllRefsType().Types()),
			ChartsOfCharacteristicTypes.AllRefsType().Types()),
			ChartsOfAccounts.AllRefsType().Types()),
			ChartsOfCalculationTypes.AllRefsType().Types()),
			BusinessProcesses.AllRefsType().Types()),
			BusinessProcesses.RoutePointsAllRefsType().Types()),
			Tasks.AllRefsType().Types());
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For the MetadataObjectIDs catalog.

// For internal use only.
Function MetadataObjectIDCache(CachedDataKey) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectIDCache(
		CachedDataKey);
	
EndFunction

// For internal use only.
Function RenamingTableForCurrentVersion() Export
	
	Return Catalogs.MetadataObjectIDs.RenamingTableForCurrentVersion();
	
EndFunction

// For internal use only.
Function MetadataObjectCollectionProperties(ExtensionsObjects = False) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties(ExtensionsObjects);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Predefined data processing.

// Returns the map of predefined value names and their references.
//
// Parameters:
//  FullMetadataObjectName - String, for example, "Catalog.ProductAndServiceTypes",
//                               Only tables with the following predefined items are supported:
//                               
//                               - Catalogs
//                               - Charts of characteristic types
//                               - Charts of accounts,
//                               - Charts of calculation types.
// 
// Returns:
//  FixedMap, Undefined, where
//      * Key - String - a name of the predefined item,
//      * Value - Reference, Null - a reference of the redefined item or Null if the object is not in infobase.
//
//  If there is an error in the metadata name or an inappropriate metadata type, Undefined is returned.
//  If metadata has no predefined items, empty fixed map is returned.
//  If the predefined item is defined in metadata, but it is not created in infobase, Null is returned for it in the map.
//
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	PredefinedValues = New Map;
	
	ObjectMetadata = Metadata.FindByFullName(FullMetadataObjectName);
	
	// If metadata does not exist.
	If ObjectMetadata = Undefined Then 
		Return Undefined;
	EndIf;
	
	// If inappropriate type of metadata .
	If Not Metadata.Catalogs.Contains(ObjectMetadata)
		AND Not Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata)
		AND Not Metadata.ChartsOfAccounts.Contains(ObjectMetadata)
		AND Not Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then 
		
		Return Undefined;
	EndIf;
	
	PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
	
	// If metadata has no predefined items.
	If PredefinedItemsNames.Count() = 0 Then 
		Return New FixedMap(PredefinedValues);
	EndIf;
	
	// Default filling by the absence flag in the infobase (the present ones will be redefined).
	For each PredefinedItemName In PredefinedItemsNames Do 
		PredefinedValues.Insert(PredefinedItemName, Null);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref,
		|	CurrentTable.PredefinedDataName AS PredefinedDataName
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", FullMetadataObjectName);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	// Filling the present items in the infobase.
	While Selection.Next() Do
		PredefinedValues.Insert(Selection.PredefinedDataName, Selection.Ref);
	EndDo;
	
	Return New FixedMap(PredefinedValues);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

Function NewSubsystemDescription()
	
	Details = New Structure;
	Details.Insert("Name",    "");
	Details.Insert("Version", "");
	Details.Insert("RequiredSubsystems", New Array);
	Details.Insert("OnlineSupportID", "");
	
	// The property is set automatically.
	Details.Insert("IsConfiguration", False);
	
	// Name of the main library module.
	// Can has an empty value in case of configuration.
	Details.Insert("MainServerModule", "");
	
	// Execution mode of deffered update handlers.
	// Consistently by default.
	Details.Insert("DeferredHandlerExecutionMode", "Sequentially");
	Details.Insert("ParralelDeferredUpdateFromVersion", "");
	
	Return Details;
	
EndFunction

Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, DisabledSubsystems, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		If DisabledSubsystems.Get(CurrentSubsystemName) = True Then
			Continue;
		Else
			Names.Insert(CurrentSubsystemName, True);
		EndIf;
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, DisabledSubsystems, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

#EndRegion
