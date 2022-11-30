///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets the exchange plan setting value by the setting name.
// For non-existent settings, Undefined is returned.
// 
// Parameters:
//   ExchangePlanName         - String - a name of the exchange plan from the metadata.
//   ParameterName            - String - an exchange plan parameter name or list of parameters separated by commas.
//                                     For the list of allowed values, see functions DefaultExchangePlanSettings,
//                                     ExchangeSettingOptionDetailsByDefault.
//   SetupID - String - a name of a predefined setting of exchange plan.
//   CorrespondentVersion   - String - correspondent configuration version.
// 
// Returns:
//   Arbitrary, Structure - type of a value to return depends on the type of value of the setting being received.
//                             Arbitrary if a single parameter was passed as ParameterName
//                             Structure if ParameterName contains a list of comma-separated parameters.
//
Function ExchangePlanSettingValue(ExchangePlanName, ParameterName, SettingID = "", CorrespondentVersion = "") Export
	
	ParameterValue = New Structure;
	ExchangePlanSettings = Undefined;
	SettingOptionDetails = Undefined;
	ParameterName = StrReplace(ParameterName, Chars.LF, "");
	ParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ParameterName,,True);
	DefaultExchangePlanSettings = DefaultExchangePlanSettings(ExchangePlanName);
	DefaultOptionDetails = ExchangeSettingOptionDetailsByDefault(ExchangePlanName);
	If ParametersNames.Count() = 0 Then
		Return Undefined;
	EndIf;
	For Each SingleParameter In ParametersNames Do
		SingleParameterValue = Undefined;
		If DefaultExchangePlanSettings.Property(SingleParameter) Then
			If ExchangePlanSettings = Undefined Then
				ExchangePlanSettings = DataExchangeCached.ExchangePlanSettings(ExchangePlanName);
			EndIf;
			ExchangePlanSettings.Property(SingleParameter, SingleParameterValue);
		ElsIf DefaultOptionDetails.Property(SingleParameter) Then
			If SettingOptionDetails = Undefined Then
				SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, SettingID, CorrespondentVersion);
			EndIf;
			SettingOptionDetails.Property(SingleParameter, SingleParameterValue);
		EndIf;
		If ParametersNames.Count() = 1 Then
			Return SingleParameterValue;
		Else
			ParameterValue.Insert(SingleParameter, SingleParameterValue);
		EndIf;
	EndDo;
	Return ParameterValue;
	
EndFunction

// OnCreateAtServer event handler for the exchange plan node form.
//
// Parameters:
//  Form - ManagedForm - a form the procedure is called from.
//  Cancel - Boolean           - a flag showing whether form creation is denied. If this parameter is set to True, the form is not created.
// 
Procedure NodeFormOnCreateAtServer(Form, Cancel) Export
	
	If Form.Parameters.Property("AutoTest") Then // Return when a form is received for analysis.
		Return;
	EndIf;
	
	ExchangePlanPresentation = ExchangePlanSettingValue(
		Form.Object.Ref.Metadata().Name,
		"ExchangePlanNodeTitle",
		DataExchangeOption(Form.Object.Ref));
	
	Form.AutoTitle = False;
	Form.Title = StringFunctionsClientServer.SubstituteParametersToString(Form.Object.Description + " (%1)",
		ExchangePlanPresentation);
	
EndProcedure

// OnWriteAtServer event handler for the exchange plan node form.
//
// Parameters:
//  CurrentObject - ExchangePlanObject - an exchange plan node to be written.
//  Cancel         - Boolean           - the incoming parameter showing whether writing the exchange node is canceled.
//                                     If it is set to True, synchronization setup completion is not 
//                                     committed for the node.
//
Procedure NodeFormOnWriteAtServer(CurrentObject, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not SynchronizationSetupCompleted(CurrentObject.Ref) Then
		CompleteDataSynchronizationSetup(CurrentObject.Ref);
	EndIf;
	
EndProcedure

// OnCreateAtServer event handler for the node setup form.
//
// Parameters:
//  Form          - ManagedForm - a form the procedure is called from.
//  ExchangePlanName - String           - a name of the exchange plan the form is created for.
// 
Procedure NodeSettingsFormOnCreateAtServer(Form, ExchangePlanName) Export
	
	If Form.Parameters.Property("AutoTest") Then // Return when a form is received for analysis.
		Return;
	EndIf;
	
	SettingID = "";
	
	If Form.Parameters.Property("SettingID") Then
		SettingID = Form.Parameters.SettingID;
	EndIf;
	
	CheckMandatoryFormAttributes(Form, "NodeFilterStructure, CorrespondentVersion");
	
	Form.CorrespondentVersion   = Form.Parameters.CorrespondentVersion;
	Form.NodeFilterStructure = NodeFilterStructure(ExchangePlanName, Form.CorrespondentVersion, SettingID);
	
	NodeSettingsFormOnCreateAtServerHandler(Form, "NodeFilterStructure");
	
EndProcedure

// Determines whether the AfterDataExport event handler must be executed on exchange in the DIB.
//
// Parameters:
//  Object - ExchangePlanObject - an exchange plan for which the handler is executed.
//  Ref - ExchangePlanObject - a reference to an exchange plan for which the handler is executed.
//
// Returns:
//   Boolean - True if the AfterDataExport handler must be executed. Otherwise, False.
//
Function MustExecuteHandlerAfterDataExport(Object, Ref) Export
	
	Return MustExecuteHandler(Object, Ref, "SentNo");
	
EndFunction

// Determines whether the AfterDataImport event handler is to be executed upon exchange in DIB.
//
// Parameters:
//  Object - ExchangePlanObject - an exchange plan for which the handler is executed.
//  Ref - ExchangePlanObject - a reference to an exchange plan for which the handler is executed.
//
// Returns:
//   Boolean - True if the AfterDataImport handler must be executed. Otherwise, False.
//
Function MustExecuteHandlerAfterDataImport(Object, Ref) Export
	
	Return MustExecuteHandler(Object, Ref, "ReceivedNo");
	
EndFunction

// Returns a prefix of the current infobase.
//
// Returns:
//   String - this infobase prefix.
//
Function InfobasePrefix() Export
	
	Return GetFunctionalOption("InfobasePrefix");
	
EndFunction

// Returns the correspondent configuration version.
// If the correspondent configuration version is not defined, returns an empty version - 0.0.0.0.
//
// Parameters:
//  Correspondent - ExchangePlanObject - a reference to an exchange plan for which you need to get the configuration version.
// 
// Returns:
//  String - correspondent configuration version.
//
// Example:
//  If CommonClientServer.CompareVersions(DataExchangeServer.CorrespondentVersion(Correspondent), "2.1.5.1")
//  >= 0 Then ...
//
Function CorrespondentVersion(Val Correspondent) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.CommonInfobasesNodesSettings.CorrespondentVersion(Correspondent);
EndFunction

// Sets prefix for the current infobase.
//
// Parameters:
//   Prefix - String - a new value of the infobase prefix.
//
Procedure SetInfobasePrefix(Val Prefix) Export
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes")
		AND Not OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
		
		ModuleObjectsPrefixesInternal = Common.CommonModule("ObjectsPrefixesInternal");
		
		PrefixChangeParameters = New Structure("NewIBPrefix, ContinueNumbering",
			TrimAll(Prefix), True);
		ModuleObjectsPrefixesInternal.ChangeIBPrefix(PrefixChangeParameters);
		
	Else
		// Data changes to renumber directories and documents must not be performed
		// - If the prefix system is not embedded.
		// - On the first start of the subordinate DIB node.
		Constants.DistributedInfobaseNodePrefix.Set(TrimAll(Prefix));
	EndIf;
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	
EndProcedure

// Checks whether the current infobase is restored from backup.
// If the infobase is restored from backup, numbers of sent and received messages must be 
// synchronized for the infobases. Number of a sent message in the current infobase is set equal to 
// the received message number in the correspondent infobase.
// If the infobase is restored from backup, we recommend that you do not delete change registration 
// on the current infobase node because this data might not have been sent to the correspondent infobase yet.
//
// Parameters:
//   Sender    - ExchangePlanRef - a node on behalf of which the exchange message was created and sent.
//   ReceivedMessageNumber - Number            - a number of received message in the correspondent infobase.
//
// Returns:
//   FixedStructure - structure properties:
//     * Sender                 - ExchangePlanRef - see the Sender parameter above.
//     * ReceivedMessageNumber              - Number            - see the ReceivedMessageNumber parameter above.
//     * BackupRestored - Boolean - True if the infobase is restored from backup.
//
Function BackupParameters(Val Sender, Val ReceivedMessageNumber) Export
	
	// For the base restored from backup, the number of sent message is less than the number of received 
	// message in the correspondent.
	// It means that the base receives the number of the received message that it has not sent yet, "a 
	// message from the future".
	Result = New Structure("Sender, ReceivedNo, BackupRestored");
	Result.Sender = Sender;
	Result.ReceivedNo = ReceivedMessageNumber;
	Result.BackupRestored = (ReceivedMessageNumber > Common.ObjectAttributeValue(Sender, "SentNo"));
	
	Return New FixedStructure(Result);
EndFunction

// Synchronizes numbers of sent and received messages for both infobases. In the current infobase, 
// sent message number is set to the value of the received message number in the correspondent 
// infobase.
//
// Parameters:
//   BackupParameters - FixedStructure - structure properties:
//     * Sender                 - ExchangePlanRef - a node on behalf of which the exchange message 
//                                                        is created and sent.
//     * ReceivedMessageNumber              - Number            - a number of received message in the correspondent infobase.
//     * BackupRestored - Boolean           - shows whether the current infobase is restored from the backup.
//
Procedure OnRestoreFromBackup(Val BackupParameters) Export
	
	If BackupParameters.BackupRestored Then
		
		// Setting sent message number in the current infobase equal to the received message number in the correspondent infobase.
		NodeObject = BackupParameters.Sender.GetObject();
		NodeObject.SentNo = BackupParameters.ReceivedNo;
		NodeObject.DataExchange.Load = True;
		NodeObject.Write();
		
	EndIf;
	
EndProcedure

// Returns an ID of the saved exchange plan setting option.
// Parameters:
//   ExchangePlanNode - ExchangePlanRef - an exchange plan node to get predefined name for.
//                                                
//
// Returns:
//  String - saved setting ID as it is set in Designer.
//
Function SavedExchangePlanNodeSettingOption(ExchangePlanNode) Export
	
	SetupOption = "";
	
	If Common.HasObjectAttribute("SettingsMode", ExchangePlanNode.Metadata()) Then
		
		SetPrivilegedMode(True);
		SetupOption = Common.ObjectAttributeValue(ExchangePlanNode, "SettingsMode");
		
	EndIf;
	
	Return SetupOption;
	
EndFunction

// Returns an array of all exchange message transport kinds defined in the configuration.
//
// Returns:
//   Array - array items have the EnumRef.ExchangeMessageTransportKinds type.
//
Function AllConfigurationExchangeMessagesTransports() Export
	
	Result = New Array;
	Result.Add(Enums.ExchangeMessagesTransportTypes.COM);
	Result.Add(Enums.ExchangeMessagesTransportTypes.WS);
	Result.Add(Enums.ExchangeMessagesTransportTypes.FILE);
	Result.Add(Enums.ExchangeMessagesTransportTypes.FTP);
	Result.Add(Enums.ExchangeMessagesTransportTypes.EMAIL);
	Result.Add(Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
	
	Return Result;
EndFunction

// Sends or receives data for an infobase node using any of the communication channels available for 
// the exchange plan, except for COM connection and web service.
//
// Parameters:
//  Cancel                        - Boolean - a cancellation flag. True if errors occurred when 
//                                 running the procedure.
//  InfobaseNode - EchangeNodeRef - ExchangePlanRef - an exchange plan node, for which data is being 
//                                 exchanged.
//  ActionOnExchange            - EnumRef.ActionsOnExchange - a running data exchange action.
//  ExchangeMessagesTransportKind - EnumRef.Enumerations.ExchangeMessagesTransportKinds - a 
//                                 transport kind that will be used in the data exchange. If it is 
//                                 not specified, it is determined from transport parameters 
//                                 specified for the exchange plan node on exchange setup. Optional, the default value is Undefined.
//  ParametersOnly              - Boolean - indicates that data are imported selectively on DIB exchange.
//  AdditionalParameters      - Structure - reserved for internal use.
// 
Procedure ExecuteExchangeActionForInfobaseNode(
		Cancel,
		InfobaseNode,
		ActionOnExchange,
		ExchangeMessagesTransportKind = Undefined,
		Val ParametersOnly = False,
		AdditionalParameters = Undefined) Export
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
		
	SetPrivilegedMode(True);
	
	// INITIALIZING DATA EXCHANGE
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
		InfobaseNode, ActionOnExchange, ExchangeMessagesTransportKind);
	
	If ExchangeSettingsStructure.Cancel Then
		
		// If settings contain errors, canceling the exchange.
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		
		Cancel = True;
		
		Return;
	EndIf;
	
	For Each Parameter In AdditionalParameters Do
		ExchangeSettingsStructure.AdditionalParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła %1';de = 'Datenaustausch beginnt für Knoten %1';ro = 'Începutul procesului schimbului de date pentru nodul %1';tr = '%1Ünite için veri değişimi süreci başlatılıyor'; es_ES = 'Inicio de proceso de intercambio de datos para el nodo %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	// DATA EXCHANGE
	ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure, ParametersOnly);
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
	For Each Parameter In ExchangeSettingsStructure.AdditionalParameters Do
		AdditionalParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

// Returns the count of unresolved data exchange issues. It is used to display the number of 
// exchange issues in the user interface. For example, it can be used in a hyperlink title to 
// navigate to the exchange issue monitor.
//
// Parameters:
//   Nodes - Array - an array of ExchangePlanRef values.
//
// Returns:
//   Number - the number of unresolved data exchange issues.
// 
Function UnresolvedIssuesCount(Nodes = Undefined) Export
	
	Return DataExchangeIssueCount(Nodes) + VersioningIssuesCount(Nodes);
	
EndFunction

// Returns a structure of title of the hyperlink to navigate to the data exchange issue monitor.
// 
// Parameters:
//   Nodes - Array - an array of ExchangePlanRef values.
//
// Returns:
//	Structure - with the following properties:
//	  * Title - String   - a hyperlink title.
//	  * Picture  - Picture - a picture for the hyperlink.
//
Function IssueMonitorHyperlinkTitleStructure(Nodes = Undefined) Export
	
	Count = UnresolvedIssuesCount(Nodes);
	
	If Count > 0 Then
		
		Title = NStr("ru = 'Предупреждения (%1)'; en = 'Warnings (%1)'; pl = 'Ostrzeżenia (%1)';de = 'Warnungen (%1)';ro = 'Avertismente (%1)';tr = 'Uyarılar (%1)'; es_ES = 'Avisos (%1)'");
		Title = StringFunctionsClientServer.SubstituteParametersToString(Title, Count);
		Picture = PictureLib.Warning;
		
	Else
		
		Title = NStr("ru = 'Предупреждений нет'; en = 'No warnings'; pl = 'Brak ostrzeżeń';de = 'Keine Warnungen';ro = 'Nu există avertismente';tr = 'Uyarı yok'; es_ES = 'No hay avisos'");
		Picture = New Picture;
		
	EndIf;
	
	TitleStructure = New Structure;
	TitleStructure.Insert("Title", Title);
	TitleStructure.Insert("Picture", Picture);
	
	Return TitleStructure;
	
EndFunction

// It determines whether the FTP server has the directory.
//
// Parameters:
//  Path - String - path to the file directory.
//  DirectoryName - String - a file directory name.
//  FTPConnection - FTPConnection - FTPConnection used to connect to the FTP server.
// 
// Returns:
//  Boolean - if True, the directory exists. Oherwise, False.
//
Function FTPDirectoryExists(Val Path, Val DirectoryName, Val FTPConnection) Export
	
	For Each FTPFile In FTPConnection.FindFiles(Path) Do
		
		If FTPFile.IsDirectory() AND FTPFile.Name = DirectoryName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
EndFunction

// Returns table data for exchange node attributes.
// 
// Parameters:
//  Tables        - Array - an array of strings containing names of exchange plan node attributes.
//  ExchangePlanName - String - an exchange plan name.
// 
// Returns:
//  Map - a map of tables and their data.
//
Function CorrespondentTablesData(Tables, Val ExchangePlanName) Export
	
	Result = New Map;
	ExchangePlanAttributes = Metadata.ExchangePlans[ExchangePlanName].Attributes;
	
	For Each Item In Tables Do
		
		Attribute = ExchangePlanAttributes.Find(Item);
		
		If Attribute <> Undefined Then
			
			AttributeTypes = Attribute.Type.Types();
			
			If AttributeTypes.Count() <> 1 Then
				
				MessageString = NStr("ru = 'Составной тип данных для значений по умолчанию не поддерживается.
					|Реквизит ""%1"".'; 
					|en = 'Composite data type is not supported for default values.
					|Attribute: %1.'; 
					|pl = 'Typ danych złożonych nie jest obsługiwany przez wartości domyślne.
					|Atrybut %1.';
					|de = 'Zusammengesetzter Datentyp wird von Standardwerten nicht unterstützt. 
					|Attribut %1.';
					|ro = 'Tipul de date compus nu este susținut pentru valorile implicite.
					|Atribut %1.';
					|tr = 'Bileşik veri türü, varsayılan değerler tarafından desteklenmez.
					|Özellik%1.'; 
					|es_ES = 'Tipo de datos compuestos no está admitido por los valores por defecto.
					|Atributo %1.'");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Attribute.FullName());
				Raise MessageString;
			EndIf;
			
			MetadataObject = Metadata.FindByType(AttributeTypes.Get(0));
			
			If Not Common.IsCatalog(MetadataObject) Then
				
				MessageString = NStr("ru = 'Выбор значений по умолчанию поддерживается только для справочников.
					|Реквизит ""%1"".'; 
					|en = 'Selection of default values is supported only for catalogs.
					|Attribute: %1.'; 
					|pl = 'Wybór wartości domyślnych jest obsługiwany tylko dla katalogów.
					|Atrybut %1.';
					|de = 'Zusammengesetzter Datentyp wird von Standardwerten unterstützt. 
					|Attribut %1.';
					|ro = 'Selectarea valorilor implicite este susținută numai pentru clasificatoare.
					|Atribut ""%1"".';
					|tr = 'Varsayılan değerler seçimi sadece kataloglar için desteklenir. 
					| Özellik%1.'; 
					|es_ES = 'Selección de valores por defecto está admitida solo para los catálogos.
					|Atributo %1.'");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Attribute.FullName());
				Raise MessageString;
			EndIf;
			
			FullMetadataObjectName = MetadataObject.FullName();
			
			TableData = New Structure("MetadataObjectProperties, CorrespondentInfobaseTable");
			TableData.MetadataObjectProperties = MetadataObjectProperties(FullMetadataObjectName);
			TableData.CorrespondentInfobaseTable = GetTableObjects(FullMetadataObjectName);
			
			Result.Insert(FullMetadataObjectName, TableData);
			
		EndIf;
		
	EndDo;
	
	Result.Insert("{AdditionalData}", New Structure); // For backward compatibility with 2.4.x.
	
	Return Result;
	
EndFunction

// Sets the number of items in a data import transaction as the constant value.
//
// Parameters:
//  Count - Number - the number of items in transaction.
// 
Procedure SetDataImportTransactionItemsCount(Count) Export
	
	SetPrivilegedMode(True);
	Constants.DataImportTransactionItemCount.Set(Count);
	
EndProcedure

// Returns the synchronization date presentation.
//
// Parameters:
//  SynchronizationDate - Date - absolute date of data synchronization.
//
// Returns:
//  String - string presentation of date.
//
Function SynchronizationDatePresentation(Val SynchronizationDate) Export
	
	If Not ValueIsFilled(SynchronizationDate) Then
		Return NStr("ru = 'Синхронизация не выполнялась.'; en = 'Synchronization was not performed.'; pl = 'Synchronizacja nie została przeprowadzona.';de = 'Die Synchronisation wurde noch nie durchgeführt.';ro = 'Sincronizarea nu a fost efectuată.';tr = 'Senkronizasyon hiç yapılmadı.'; es_ES = 'Sincronización nunca se ha realizado.'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Последняя синхронизация: %1'; en = 'Last synchronized on: %1'; pl = 'Ostatnia synchronizacja: %1';de = 'Letzte Synchronisation: %1';ro = 'Ultima sincronizare: %1';tr = 'Son senkronizasyon: %1'; es_ES = 'Última sincronización: %1'"), RelativeSynchronizationDate(SynchronizationDate));
EndFunction

// Returns presentation for the relative synchronization date.
//
// Parameters:
//  SynchronizationDate - Date - absolute date of data synchronization.
//
// Returns:
//  String - presentation for the relative synchronization date.
//    *Never             (T = blank date).
//    *Now              (T < 5 min).
//    *5 minutes ago       (5 min < T < 15 min).
//    *15 minutes ago      (15 min < T < 30 min).
//    *30 minutes ago      (30 min < T < 1 hour).
//    *1 hour ago         (1 hour < T < 2 hours).
//    *2 hours ago        (2 hours < T < 3 hours).
//    *Today, 12:44:12   (3 hours  < Т < yesterday).
//    *Yesterday, 22:30:45     (yesterday  < Т < one day ago).
//    *One day ago, 21:22:54 (one day ago  < Т < two days ago).
//    *<March 12, 2012>   (two days ago < T).
//
Function RelativeSynchronizationDate(Val SynchronizationDate) Export
	
	If Not ValueIsFilled(SynchronizationDate) Then
		
		Return NStr("ru = 'Никогда'; en = 'Never'; pl = 'Nigdy';de = 'Niemals';ro = 'Niciodată';tr = 'Hiç bir zaman'; es_ES = 'Nunca'");
		
	EndIf;
	
	DateCurrent = CurrentSessionDate();
	
	Interval = DateCurrent - SynchronizationDate;
	
	If Interval < 0 Then // 0 min
		
		Result = Format(SynchronizationDate, "DLF=DD");
		
	ElsIf Interval < 60 * 5 Then // 5 min
		
		Result = NStr("ru = 'Сейчас'; en = 'Now'; pl = 'Teraz';de = 'Jetzt';ro = 'Acum';tr = 'Şimdi'; es_ES = 'Ahora'");
		
	ElsIf Interval < 60 * 15 Then // 15 min
		
		Result = NStr("ru = '5 минут назад'; en = '5 minutes ago'; pl = '5 minut temu';de = 'Vor 5 Minuten';ro = 'Acum 5 minute';tr = '5 dakika önce'; es_ES = 'Hace 5 minutos'");
		
	ElsIf Interval < 60 * 30 Then // 30 min
		
		Result = NStr("ru = '15 минут назад'; en = '15 minutes ago'; pl = '15 minut temu';de = 'Vor 15 Minuten';ro = 'Acum 15 minute';tr = '15 dakika önce'; es_ES = 'Hace 15 minutos'");
		
	ElsIf Interval < 60 * 60 * 1 Then // 1 hour
		
		Result = NStr("ru = '30 минут назад'; en = '30 minutes ago'; pl = '30 minut temu';de = 'Vor 30 Minuten';ro = 'Acum 30 minute';tr = '30 dakika önce'; es_ES = 'Hace 30 minutos'");
		
	ElsIf Interval < 60 * 60 * 2 Then // 2 hours
		
		Result = NStr("ru = '1 час назад'; en = '1 hour ago'; pl = 'godzinę temu';de = 'Vor 1 Stunde';ro = '1 oră în urmă';tr = '1 saat önce'; es_ES = 'Hace 1 hora'");
		
	ElsIf Interval < 60 * 60 * 3 Then // 3 hours
		
		Result = NStr("ru = '2 часа назад'; en = '2 hours ago'; pl = '2 godziny temu';de = 'Vor 2 Stunde';ro = '2 ore în urmă';tr = '2 saat önce'; es_ES = 'Hace 2 horas'");
		
	Else
		
		DifferenceDaysCount = DifferenceDaysCount(SynchronizationDate, DateCurrent);
		
		If DifferenceDaysCount = 0 Then // today
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сегодня, %1'; en = 'Today, %1'; pl = 'Dzisiaj, %1';de = 'Heute, %1';ro = 'Astăzi, %1';tr = 'Bugün, %1'; es_ES = 'Hoy, %1'"), Format(SynchronizationDate, "DLF=T"));
			
		ElsIf DifferenceDaysCount = 1 Then // yesterday
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вчера, %1'; en = 'Yesterday, %1'; pl = 'Wczoraj, %1';de = 'Gestern, %1';ro = 'Ieri, %1';tr = 'Dün, %1'; es_ES = 'Ayer, %1'"), Format(SynchronizationDate, "DLF=T"));
			
		ElsIf DifferenceDaysCount = 2 Then // day before yesterday
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Позавчера, %1'; en = 'Day before yesterday, %1'; pl = 'Przedwczoraj, %1';de = 'Vorgestern, %1';ro = 'Cu o zi înainte de ieri, %1';tr = 'Önceki gün, %1'; es_ES = 'Anteayer, %1'"), Format(SynchronizationDate, "DLF=T"));
			
		Else // long ago
			
			Result = Format(SynchronizationDate, "DLF=DD");
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

// Returns an ID of the supplied profile of the "Data synchronization with other applications" access groups.
//
// Returns:
//  String - ID of the supplied access group profile.
//
Function DataSynchronizationWithOtherApplicationsAccessProfile() Export
	
	Return "04937803-5dba-11df-a1d4-005056c00008";
	
EndFunction

// Checks whether the current user can administer exchanges.
//
// Returns:
//  Boolean - True if the user has rights. Otherwise, False.
//
Function HasRightsToAdministerExchanges() Export
	
	Return Users.IsFullUser();
	
EndFunction

// The function returns the WSProxy object of the Exchange web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure - Structure - parameters for WSProxy.
//    * WebServiceWSURL - String - WSDL file location.
//    * WSServiceName - String - a service name.
//    * WSURLServiceNamespace - String - web service namespace URI.
//    * WSUserName - String - a user name to sign in to server.
//    * WSPassword - String - a user password.
//    * WSTimeout - Number - the timeout for operations executed over the proxy.
//  ErrorMessageString - String - contains detailed error description in case of unsuccessful connection.
//  UserMessage - String - contains brief error description in case of unsuccessful connection.
//
// Returns:
//  WSProxy - a WSProxy object of the Exchange web service.
//
Function GetWSProxy(SettingsStructure, ErrorMessageString = "", UserMessage = "") Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure);
	
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange");
	SettingsStructure.Insert("WSServiceName",                 "Exchange");
	SettingsStructure.Insert("WSTimeout", 600);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString, UserMessage);
EndFunction

// The function returns the WSProxy object of the Exchange_2_0_1_6 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure - Structure - parameters for WSProxy.
//    * WebServiceWSURL - String - WSDL file location.
//    * WSServiceName - String - a service name.
//    * WSURLServiceNamespace - String - web service namespace URI.
//    * WSUserName - String - a user name to sign in to server.
//    * WSPassword - String - a user password.
//    * WSTimeout - Number - the timeout for operations executed over the proxy.
//  ErrorMessageString - String - contains detailed error description in case of unsuccessful connection.
//  UserMessage - String - contains brief error description in case of unsuccessful connection.
//
// Returns:
//  WSProxy - a WSProxy object of the Exchange_2_0_1_6 web service.
//
Function GetWSProxy_2_0_1_6(SettingsStructure, ErrorMessageString = "", UserMessage = "") Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure);
	
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_2_0_1_6");
	SettingsStructure.Insert("WSServiceName",                 "Exchange_2_0_1_6");
	SettingsStructure.Insert("WSTimeout", 600);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString, UserMessage);
EndFunction

// The function returns the WSProxy object of the Exchange_2_0_1_7 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure - Structure - parameters for WSProxy.
//    * WebServiceWSURL - String - WSDL file location.
//    * WSServiceName - String - a service name.
//    * WSURLServiceNamespace - String - web service namespace URI.
//    * WSUserName - String - a user name to sign in to server.
//    * WSPassword - String - a user password.
//    * WSTimeout - Number - the timeout for operations executed over the proxy.
//  ErrorMessageString - String - contains detailed error description in case of unsuccessful connection.
//  UserMessage - String - contains brief error description in case of unsuccessful connection.
//  Timeout - Number - timeout.
//
// Returns:
//  WSProxy - a WSProxy object of the Exchange_2_0_1_7 web service.
//
Function GetWSProxy_2_1_1_7(SettingsStructure, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure);
	
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_2_0_1_6");
	SettingsStructure.Insert("WSServiceName",                 "Exchange_2_0_1_6");
	SettingsStructure.Insert("WSTimeout", Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString, UserMessage, True);
EndFunction

// The function returns the WSProxy object of the Exchange_3_0_1_1 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure - Structure - parameters for WSProxy.
//    * WebServiceWSURL - String - WSDL file location.
//    * WSServiceName - String - a service name.
//    * WSURLServiceNamespace - String - web service namespace URI.
//    * WSUserName - String - a user name to sign in to server.
//    * WSPassword - String - a user password.
//    * WSTimeout - Number - the timeout for operations executed over the proxy.
//  ErrorMessageString - String - contains detailed error description in case of unsuccessful connection.
//  UserMessage - String - contains brief error description in case of unsuccessful connection.
//  Timeout - Number - timeout.
//
// Returns:
//  WSProxy - a WSProxy object of the Exchange_3_0_1_1 web service.
//
Function GetWSProxy_3_0_1_1(SettingsStructure, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure);
	
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_3_0_1_1");
	SettingsStructure.Insert("WSServiceName",                 "Exchange_3_0_1_1");
	SettingsStructure.Insert("WSTimeout",                    Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString, UserMessage, True);
	
EndFunction

// Returns allowed number of items processed in a single data import transaction.
//
// Returns:
//   Number - allowed number of items processed in a single data import transaction.
// 
Function DataImportTransactionItemCount() Export
	
	SetPrivilegedMode(True);
	Return Constants.DataImportTransactionItemCount.Get();
	
EndFunction

// Returns allowed number of items processed in a single data export transaction.
//
// Returns:
//   Number - allowed number of items processed in a single data export transaction.
// 
Function DataExportTransactionItemsCount() Export
	
	Return 1;
	
EndFunction

// Returns a table with data of nodes of all configured SSL exchanges.
//
// Returns:
//   ValueTable - a value table with the following columns:
//     * InfobaseNode - ExchangePlanRef - a reference to the exchange plan node.
//     * Description - String - description of the exchange plan node.
//     * ExchangePlanName - String - an exchange plan name.
//
Function SSLExchangeNodes() Export
	
	Query = New Query(ExchangePlansForMonitorQueryText());
	SetPrivilegedMode(True);
	SSLExchangeNodes = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return SSLExchangeNodes;
	
EndFunction

// Determines whether standard conversion rules are used for the exchange plan.
//
// Parameters:
//	ExchangePlanName - String - a name of the exchange plan for which the rules are being imported.
//
// Returns:
//   Boolean - if True, the rules are used. Otherwise, False.
//
Function StandardRulesUsed(ExchangePlanName) Export
	
	Return InformationRegisters.DataExchangeRules.StandardRulesUsed(ExchangePlanName);
	
EndFunction

// Sets an external connection with the infobase and returns the connection description.
//
// Parameters:
//  Parameters - Structure - external connection parameters.
//                          For the properties, see function
//                          CommonClientServer.ParametersStructureForExternalConnection:
//
//	  * InfobaseOperationMode - Number - the infobase operation mode. File mode - 0. Client/server 
//	                                                           mode - 1.
//	  * InfobaseDirectory - String - the infobase directory.
//	  * NameOf1CEnterpriseServer - String - the name of the 1C:Enterprise server.
//	  * NameOfInfobaseOn1CEnterpriseServer - String - a name of the infobase on 1C Enterprise server.
//	  * OperatingSystemAuthentication - Boolean - indicates whether the operating system is 
//	                                                           authenticated on establishing a connection to the infobase.
//	  * UserName - String - the name of an infobase user.
//	  * UserPassword - String - the user password.
//
// Returns:
//  Structure - connection details.
//    * Connection - COMObject, Undefined - if the connection is established, returns a COM object 
//                                    reference. Otherwise, returns Undefined.
//    * BriefErrorDescription       - String - a brief error description.
//    * DetailedErrorDescription     - String - a detailed error description.
//    * ErrorAttachingAddIn - Boolean - a COM connection error flag.
//
Function ExternalConnectionToInfobase(Parameters) Export
	
	// Converting external connection parameters to transport parameters.
	TransportSettings = TransportSettingsByExternalConnectionParameters(Parameters);
	Return EstablishExternalConnectionWithInfobase(TransportSettings);
	
EndFunction

#Region ConnectionToExternalSystemSettings

// Saves connection settings to exchange with external system via EnterpriseData.
//
// Parameters:
//  Context - Structure - operation execution context.
//    * Mode - String - a mode in which a handler is called.
//                       Possible values: NewConnection | EditConnectionParameters.
//    * Correspondent - ExchangePlanRef, Undefined - an exchange node matching the correspondent.
//                                                       For the NewConnection mode it equals Undefined.
//    * ExchangePlanName - String, Undefined - a name of the exchange plan where node is created.
//    * SettingID - String, Undefined - a setting option ID as it is specified in the exchange plan 
//                                                      manager module.
//  ConnectionParameters - Structure - a structure of connection parameters.
//    * CorrespondentID - String(36), Undefined - a correspondent UUID.
//    * CorrespondentDescription - String, Undefined - a correspondent name as it will be displayed 
//                                                          in the list of configured synchronizations.
//    * TransportSettings - Arbitrary, Undefined - an arbitrary value describing connection parameters.
//    * SynchronizationSchedule - ScheduledJobSchedule, Undefined - a schedule of synchronization startup.
//    * XDTOSettings - Structure, Undefined - a structure of XDTO correspondent settings.
//      ** SupportedVersions - Array - a list of format versions supported by the correspondent.
//      ** SupportedObjects - ValueTable - a list of format objects supported by the correspondent.
//                                                   See XDTODataExchangeServer. SupportedFormatObjects
//  Result - Structure - outgoing.
//    * ExchangeNode - ExchangePlanRef - an exchange plan node matching the correspondent.
//    * CorrespondentID - String - a correspondent UUID.
//
Procedure OnSaveExternalSystemConnectionSettings(Context, AttachmentParameters, Result) Export
	
	Correspondent = Undefined;
	Context.Property("Correspondent", Correspondent);
	
	XDTOSettings = Undefined;
	AttachmentParameters.Property("XDTOSettings", XDTOSettings);
	
	ExchangeFormatVersion = "";
	If Not XDTOSettings = Undefined Then
		If XDTOSettings.SupportedVersions <> Undefined
			AND XDTOSettings.SupportedVersions.Count() > 0 Then
			ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(
				Context.ExchangePlanName, XDTOSettings.SupportedVersions);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If Context.Mode = "NewConnection" Then
			
			CorrespondentID = Undefined;
			AttachmentParameters.Property("CorrespondentID", CorrespondentID);
			If Not ValueIsFilled(CorrespondentID) Then
				CorrespondentID = XMLString(New UUID);
			EndIf;
			
			Correspondent = NewXDTODataExchangeNode(
				Context.ExchangePlanName,
				Context.SettingID,
				CorrespondentID,
				AttachmentParameters.CorrespondentDescription,
				ExchangeFormatVersion);
			
			If Not Common.DataSeparationEnabled() Then
				UpdateDataExchangeRules();
			EndIf;
			
			DatabaseObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(
				Context.ExchangePlanName, "SendGet", Correspondent);
			
			XDTOSettingManager = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
			XDTOSettingManager.UpdateSettings(
				Correspondent, "SupportedObjects", DatabaseObjectsTable);
				
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode",       Correspondent);
			RecordStructure.Insert("CorrespondentExchangePlanName", Context.ExchangePlanName);
			
			UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
		ElsIf Context.Mode = "EditConnectionParameters" Then
			CorrespondentData = Common.ObjectAttributesValues(Correspondent, "Code, Description, ExchangeFormatVersion");
			
			ValuesToUpdate = New Structure;
			
			If AttachmentParameters.Property("CorrespondentID")
				AND ValueIsFilled(AttachmentParameters.CorrespondentID)
				AND TrimAll(AttachmentParameters.CorrespondentID) <> TrimAll(CorrespondentData.Code) Then
				ValuesToUpdate.Insert("Code", TrimAll(AttachmentParameters.CorrespondentID));
			EndIf;
			
			If AttachmentParameters.Property("CorrespondentDescription")
				AND ValueIsFilled(AttachmentParameters.CorrespondentDescription)
				AND TrimAll(AttachmentParameters.CorrespondentDescription) <> TrimAll(CorrespondentData.Description) Then
				ValuesToUpdate.Insert("Description", TrimAll(AttachmentParameters.CorrespondentDescription));
			EndIf;
			
			If ValueIsFilled(ExchangeFormatVersion)
				AND Not ExchangeFormatVersion = CorrespondentData.ExchangeFormatVersion Then
				ValuesToUpdate.Insert("ExchangeFormatVersion", ExchangeFormatVersion);
			EndIf;
			
			If ValuesToUpdate.Count() > 0 Then
				CorrespondentObject = Correspondent.GetObject();
				
				For Each ValueToUpdate In ValuesToUpdate Do
					CorrespondentObject[ValueToUpdate.Key] = ValueToUpdate.Value;
				EndDo;
				
				CorrespondentObject.DataExchange.Load = True;
				CorrespondentObject.Write();
			EndIf;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не подходящий режим вызова функции: %1'; en = 'Invalid function call mode: %1.'; pl = 'Nieprawidłowy tryb wywołania funkcji: %1';de = 'Ungeeigneter Funktionsaufrufmodus: %1';ro = 'Regimul nepotrivit de apelare a funcției: %1';tr = 'Uygun olmayan işlev çağrısı modu: %1'; es_ES = 'Modo no conveniente de llamada de la función: %1'"), Context.Mode);
		EndIf;
		
		If Not XDTOSettings = Undefined Then
			If Not XDTOSettings.SupportedObjects = Undefined Then
				XDTOSettingManager = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
				XDTOSettingManager.UpdateCorrespondentSettings(
					Correspondent, "SupportedObjects", XDTOSettings.SupportedObjects);
			EndIf;
		EndIf;
		
		TransportSettingsManager = Common.CommonModule("InformationRegisters.DataExchangeTransportSettings");
		TransportSettingsManager.SaveExternalSystemTransportSettings(
			Correspondent, AttachmentParameters.TransportSettings);
			
		If AttachmentParameters.Property("SynchronizationSchedule")
			AND AttachmentParameters.SynchronizationSchedule <> Undefined Then
			
			UseScheduledJob = ?(AttachmentParameters.Property("UseScheduledJob"),
				AttachmentParameters.UseScheduledJob, True);
				
			If Common.DataSeparationEnabled() Then
				If Common.SubsystemExists("StandardSubsystems.SaaS.JobQueue") Then
					ModuleJobQueue = Common.CommonModule("JobQueue");
					
					JobKey = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'ОбменДаннымиСВнешнейСистемой (%1)'; en = 'DataExchangeWithExternalSystem (%1)'; pl = 'ОбменДаннымиСВнешнейСистемой (%1)';de = 'DatenaustauschAusDemFremdsystem (%1)';ro = 'ОбменДаннымиСВнешнейСистемой (%1)';tr = 'DışSistemİleVeriAlışverişi (%1)'; es_ES = 'ОбменДаннымиСВнешнейСистемой (%1)'"),
						Common.ObjectAttributeValue(Correspondent, "Code"));
						
					ModuleSaaS = Common.CommonModule("SaaS");
						
					JobParameters = New Structure;
					JobParameters.Insert("DataArea", ModuleSaaS.SessionSeparatorValue());
					JobParameters.Insert("Use", UseScheduledJob);
					JobParameters.Insert("MethodName",     "DataExchangeServer.ExecuteDataExchangeWithExternalSystem");
					
					JobParameters.Insert("Parameters", New Array);
					JobParameters.Parameters.Add(Correspondent);
					JobParameters.Parameters.Add(New Structure("ExecuteImport, ExecuteSettingsSending", True, True));
					JobParameters.Parameters.Add(False);
					
					JobParameters.Insert("Key",       JobKey);
					JobParameters.Insert("Schedule", AttachmentParameters.SynchronizationSchedule);
					
					If Context.Mode = "NewConnection" Then
						ModuleJobQueue.AddJob(JobParameters);
					ElsIf Context.Mode = "EditConnectionParameters" Then
						Filter = New Structure("DataArea, MethodName, Key");
						FillPropertyValues(Filter, JobParameters);
						
						JobTable = ModuleJobQueue.GetJobs(Filter);
						If JobTable.Count() > 0 Then
							ModuleJobQueue.ChangeJob(JobTable[0].ID, JobParameters);
						Else
							ModuleJobQueue.AddJob(JobParameters);
						EndIf;
					EndIf;
					
				EndIf;
			Else
				If Context.Mode = "NewConnection" Then
					Catalogs.DataExchangeScenarios.CreateScenario(
						Correspondent, AttachmentParameters.SynchronizationSchedule, UseScheduledJob);
				ElsIf Context.Mode = "EditConnectionParameters" Then
					Query = New Query(
					"SELECT DISTINCT
					|	DataExchangeScenarios.Ref AS Scenario,
					|	DataExchangeScenarios.Ref.UseScheduledJob AS UseScheduledJob
					|FROM
					|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
					|		INNER JOIN Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenarioExchangeSettings
					|		ON (DataExchangeScenarioExchangeSettings.Ref = DataExchangeScenarios.Ref)
					|WHERE
					|	DataExchangeScenarioExchangeSettings.InfobaseNode = &InfobaseNode
					|	AND NOT DataExchangeScenarios.DeletionMark");
					Query.SetParameter("InfobaseNode", Correspondent);
					
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						ScenarioObject = Selection.Scenario.GetObject();
						
						Cancel = False;
						Catalogs.DataExchangeScenarios.UpdateScheduledJobData(
							Cancel, AttachmentParameters.SynchronizationSchedule, ScenarioObject);
							
						If Not Cancel Then	
							ScenarioObject.UseScheduledJob = UseScheduledJob;
							ScenarioObject.Write();
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Context.Mode = "NewConnection" Then
		// Sending formalized XDTO settings.
		ExchangeParameters = New Structure;
		ExchangeParameters.Insert("ExecuteImport",         False);
		ExchangeParameters.Insert("ExecuteSettingsSending", True);
		
		Cancel             = False;
		ErrorMessage = "";
		Try
			ExecuteDataExchangeWithExternalSystem(Correspondent, ExchangeParameters, Cancel);
		Except
			Cancel = True;
			ErrorMessage = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , ErrorMessage);
		EndTry;
		
		If Cancel Then
			DeletionSettings = New Structure;
			DeletionSettings.Insert("ExchangeNode", Correspondent);
			DeletionSettings.Insert("DeleteSettingItemInCorrespondent", True);
			
			ProcedureParameters = New Structure;
			ProcedureParameters.Insert("DeletionSettings", DeletionSettings);
			
			ResultAddress = "";
			Try
				ModuleDataExchangeCreationWizard().DeleteSynchronizationSetting(ProcedureParameters, ResultAddress);
			Except
				Raise;
			EndTry;
			
			Raise ErrorMessage;
		EndIf;
	EndIf;
		
	Result = New Structure;
	Result.Insert("ExchangeNode", Correspondent);
	Result.Insert("CorrespondentID",
		Common.ObjectAttributeValue(Correspondent, "Code"));
	
EndProcedure

// Fills saved parameter structure of connection to external system.
//
// Parameters:
//  Context - Structure - operation execution context.
//    * Correspondent - ExchangePlanRef - an exchange node matching the correspondent.
//  ConnectionParameters - Structure - a structure of connection parameters.
//    * CorrespondentID - String(36) - a correspondent UUID.
//    * CorrespondentDescription - String - a correspondent name as it is displayed in the list of 
//                                            configured synchronizations.
//    * TransportSettings - Arbitrary - saved transport settings of external system exchange messages.
//    * SynchronizationSchedule - ScheduledJobSchedule, Undefined - a schedule of automatic exchange startup.
//    * XDTOSettings - Structure, Undefined - a structure of XDTO correspondent settings.
//      ** SupportedVersions - Array - a list of format versions supported by the correspondent.
//      ** SupportedObjects - ValueTable - a list of format objects supported by the correspondent.
//                                                   See XDTODataExchangeServer. SupportedFormatObjects.
//
Procedure OnGetExternalSystemConnectionSettings(Context, AttachmentParameters) Export
	
	SetPrivilegedMode(True);
	
	ExchangeNodeData = Common.ObjectAttributesValues(Context.Correspondent, "Code, Description");
	
	AttachmentParameters = New Structure;
	AttachmentParameters.Insert("CorrespondentID", ExchangeNodeData.Code);
	AttachmentParameters.Insert("CorrespondentDescription",  ExchangeNodeData.Description);
	AttachmentParameters.Insert("TransportSettings",
		InformationRegisters.DataExchangeTransportSettings.ExternalSystemTransportSettings(Context.Correspondent));
	AttachmentParameters.Insert("SynchronizationSchedule");
	AttachmentParameters.Insert("XDTOSettings", New Structure);
	
	AttachmentParameters.XDTOSettings.Insert("SupportedVersions",
		InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Context.Correspondent, "SupportedVersions"));
	AttachmentParameters.XDTOSettings.Insert("SupportedObjects",
		InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Context.Correspondent, "SupportedObjects"));
	
EndProcedure
	
// A table of exchange transport settings for all set data exchanges with external systems.
//
// Returns:
//  ValueTable - transport settings
//    * Correspondent - ExchangePlanRef - an exchange node matching the correspondent.
//    * TransportSettings - Arbitrary - saved transport settings of external system exchange messages.
//
Function AllTransportSettingsOfExchangeWithExternalSystems() Export
	
	Result = New ValueTable;
	Result.Columns.Add("Correspondent");
	Result.Columns.Add("TransportSettings");
	
	CommonQueryText = "";
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	
	For Each ExchangePlan In SSLExchangePlans Do
		
		If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlan) Then
			Continue;
		EndIf;
		
		QueryText = 
		"SELECT
		|	T.Ref AS Correspondent,
		|	DataExchangeTransportSettings.ExternalSystemConnectionParameters AS ExternalSystemConnectionParameters
		|FROM
		|	#ExchangePlanTable AS T
		|		INNER JOIN InformationRegister.DataExchangeTransportSettings AS DataExchangeTransportSettings
		|		ON (DataExchangeTransportSettings.Correspondent = T.Ref)
		|WHERE
		|	NOT T.ThisNode
		|	AND DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.ExternalSystem)";
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlan);
		
		If Not IsBlankString(CommonQueryText) Then
			CommonQueryText = CommonQueryText + "
			|
			|UNION ALL
			|
			|";
		EndIf;
		
		CommonQueryText = CommonQueryText + QueryText;
		
	EndDo;
	
	If IsBlankString(CommonQueryText) Then
		Return Result;
	EndIf;
	
	Query = New Query(CommonQueryText);
	
	SetPrivilegedMode(True);
	SettingsTable = Query.Execute().Unload();
	
	For Each SettingString In SettingsTable Do
		ResultRow = Result.Add();
		ResultRow.Correspondent = SettingString.Correspondent;
		ResultRow.TransportSettings = SettingString.ExternalSystemConnectionParameters.Get();
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SaveDataSynchronizationSettings

// Starts saving data synchronization settings in time-consuming operation.
// On saving the settings, the data is transferred to the node of passed filling data exchange, and 
// synchronization setup completion flag is set.
// We recommend you to use it in data synchronization setup wizard.
// 
// Parameters:
//  SynchronizationSettings - Structure - parameter structure to save the settings.
//   * ExchangeNode - ExchangePlanRef - an exchange plan node for which synchronization settings are being saved.
//   * FillingData - Structure - arbitrary structure to fill settings on the node.
//                                    It is passed to the OnSaveDataSynchronizationSettings algorithm, if any.
//  HandlerParameters - Structure - outgoing internal parameter. Reserved for internal use.
//                                       It is intended to track the state of time-consuming operation.
//                                       Initial value must be a form attribute of the Arbitrary 
//                                       type which is not used in any other operation.
//  ContinueWait     - Boolean    - outgoing parameter. True, if setting saving is running in a time-consuming operation.
//                                       In this case, to track the state, use procedure
//                                       DataExchangeServer.OnWaitSaveSynchronizationSettings.
//
Procedure OnStartSaveSynchronizationSettings(SynchronizationSettings, HandlerParameters, ContinueWait = True) Export
	
	ModuleDataExchangeCreationWizard().OnStartSaveSynchronizationSettings(SynchronizationSettings,
		HandlerParameters,
		ContinueWait);
	
EndProcedure

// It is used when waiting for data synchronization setup to complete.
// Checks the status of a time-consuming operation of saving the settings. Returns a flag indicating 
// that it is necessary to continue waiting or reports that the saving operation is completed.
// 
// Parameters:
//  HandlerParameters - Structure - incoming/outgoing service parameter. Reserved for internal use.
//                                       It is intended to track the state of time-consuming operation.
//                                       Initial value must be a form attribute of the Arbitrary 
//                                       type used on starting synchronization setup by calling the 
//                                       DataExchangeServer.OnStartSaveSynchronizationSettings method.
//  ContinueWait     - Boolean    - outgoing parameter. True if it is necessary to continue waiting 
//                                       for completion of synchronization settings saving, False - 
//                                       if synchronization setup is completed.
//
Procedure OnWaitForSaveSynchronizationSettings(HandlerParameters, ContinueWait) Export

	ModuleDataExchangeCreationWizard().OnWaitForSaveSynchronizationSettings(HandlerParameters,
		ContinueWait);
	
EndProcedure

// Gets the status of synchronization setup completion. It is called, when procedure
// DataExchangeServer.OnStartSaveSynchronizationSettings or DataExchangeServer.
// OnWaitSaveSynchronizationSettings sets the ContinueWaiting flag to False.
// 
// Parameters:
//  HandlerParameters - Structure - incoming service parameter. Reserved for internal use.
//                                       It is intended to get the state of a time-consuming operation.
//                                       Initial value must be a form attribute of the Arbitrary 
//                                       type used on starting synchronization setup by calling the 
//                                       DataExchangeServer.OnStartSaveSynchronizationSettings method.
//  CompletionStatus       - Structure - an outgoing parameter that returns the state of completion of a time-consuming operation.
//   * Cancel             - Boolean - True if an error occurred on startup or on execution of a time-consuming operation.
//   * ErrorMessage - String - text of the error that occurred on executing a time-consuming operation if Cancel = True.
//   * Result         - Structure - a state of synchronization settings saving.
//    ** SettingsSaved - Boolean - True, if synchronization setup is successfully completed.
//    ** ErrorMessage  - String - text of the error that occurred right in the synchronization settings saving transaction.
//
Procedure OnCompleteSaveSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	ModuleDataExchangeCreationWizard().OnCompleteSaveSynchronizationSettings(HandlerParameters,
		CompletionStatus);
	
EndProcedure

#EndRegion

#Region CommonInfobasesNodesSettings

// Sets a flag of completing data synchronization setup.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef - an exchange node to set the flag for.
//
Procedure CompleteDataSynchronizationSetup(ExchangeNode) Export
	
	SetPrivilegedMode(True);
	
	If ExchangeNode = ExchangePlans[DataExchangeCached.GetExchangePlanName(ExchangeNode)].ThisNode() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		If Not SynchronizationSetupCompleted(ExchangeNode) Then
			// Changes that are registered before synchronisation setting has completed are incorrect because 
			// filters have not been set yet.
			ExchangePlans.DeleteChangeRecords(ExchangeNode);
			
			// You need to reset the flag of changes registration to send a message to the service manager again.
			If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
				Constants["DataChangesRecorded"].Set(False);
			EndIf;
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetFlagSettingCompleted(ExchangeNode);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns a flag of completing data synchronization setup for the exchange node.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef - an exchange node to get a flag for.
//
// Returns:
//   Boolean - True if synchronization setup for the passed node is completed.
//
Function SynchronizationSetupCompleted(ExchangeNode) Export
	
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeNode) Then
		Return True;
	Else
		SetPrivilegedMode(True);
		
		Return InformationRegisters.CommonInfobasesNodesSettings.SetupCompleted(ExchangeNode);
	EndIf;
	
EndFunction

// Indicates that DIB node initial image is created successfully.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef - an exchange node to set the flag for.
//
Procedure CompleteInitialImageCreation(ExchangeNode) Export
	
	InformationRegisters.CommonInfobasesNodesSettings.SetFlagInitialImageCreated(ExchangeNode);
	
EndProcedure

#EndRegion

#Region ForCallsFromOtherSubsystems

// SaaSTechnology.SaaS.DataExchangeSaaS

// Returns a reference to the exchange plan node found by its code.
// If the node is not found, Undefined is returned.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is set in Designer.
//  NodeCode - String - an exchange plan node code.
//
// Returns:
//  ExchangePlanRef - a reference to the found exchange plan node.
//  Undefined - if the exchange plan node is not found.
//
Function ExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	NodeRef = ExchangePlans[ExchangePlanName].FindByCode(NodeCode);
	
	If Not ValueIsFilled(NodeRef) Then
		Return Undefined;
	EndIf;
	
	Return NodeRef;
	
EndFunction

// Returns True if the session is started on a standalone workplace.
// Returns:
//  Boolean - indicates whether the session is started on a standalone workplace.
//
Function IsStandaloneWorkplace() Export
	
	SetPrivilegedMode(True);
	
	If Constants.SubordinateDIBNodeSetupCompleted.Get() Then
		Return Constants.IsStandaloneWorkplace.Get();
	EndIf;
		
	MasterNodeOfThisInfobase = MasterNode();
	Return MasterNodeOfThisInfobase <> Undefined
		AND DataExchangeCached.IsStandaloneWorkstationNode(MasterNodeOfThisInfobase);
	
EndFunction

// Determines whether the passed exchange plan node is a standalone workstation.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - a node to be checked.
//
// Returns:
//  Boolean -indicates whether the passed node is a standalone workplace.
//
Function IsStandaloneWorkstationNode(Val InfobaseNode) Export
	
	Return DataExchangeCached.IsStandaloneWorkstationNode(InfobaseNode);
	
EndFunction

// Deletes a record set for the passed structure values from the register.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values are used to delete a record set.
// 
Procedure DeleteDataExchangesStateRecords(RecordStructure) Export
	
	DeleteRecordSetFromInformationRegister(RecordStructure, "DataExchangesStates");
	
EndProcedure

// Deletes a record set for the passed structure values from the register.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values are used to delete a record set.
// 
Procedure DeleteSuccessfulDataExchangesStateRecords(RecordStructure) Export
	
	DeleteRecordSetFromInformationRegister(RecordStructure, "SuccessfulDataExchangesStates");
	
EndProcedure

// Deletes supplied rules for the exchange plan (clears data in the register).
//
// Parameters:
//	ExchangePlanName - String - a name of the exchange plan for which the rules are being deleted.
//
Procedure DeleteSuppliedRules(ExchangePlanName) Export
	
	InformationRegisters.DataExchangeRules.DeleteSuppliedRules(ExchangePlanName);	
	
EndProcedure

// Imports supplied rules for the exchange plan.
//
// Parameters:
//	ExchangePlanName - String - a name of the exchange plan for which the rules are being imported.
//	RulesFileName - String - a full name of exchange rules file (ZIP).
//
Procedure ImportSuppliedRules(ExchangePlanName, RulesFileName) Export
	
	InformationRegisters.DataExchangeRules.ImportSuppliedRules(ExchangePlanName, RulesFileName);	
	
EndProcedure

// Returns exchange setting ID matching the specific correspondent.
// 
// Parameters:
//  ExchangePlanName       - String - a name of an exchange plan used for exchange setup.
//  CorrespondentVersion - String - a number of version of the  correspondent to setup data exchange with.
//  CorrespondentName    - String - a correspondent name (see the SourceConfigurationName function 
//                               in the correspondent configuration).
//
// Returns:
//  Array - an array of strings with setting IDs for the correspondent.
// 
Function CorrespondentExchangeSettingsOptions(ExchangePlanName, CorrespondentVersion, CorrespondentName) Export
	
	ExchangePlanSettings = ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, True);
	If ExchangePlanSettings.ExchangeSettingsOptions.Count() = 0 Then
		Return New Array;
	Else
		Return ExchangePlanSettings.ExchangeSettingsOptions.UnloadColumn("SettingID");
	EndIf;
	
EndFunction

// Returns exchange setting ID matching the specific correspondent.
// 
// Parameters:
//  ExchangePlanName    - String - a name of exchange plan to use for exchange setup.
//  CorrespondentName - String - a correspondent name (see the SourceConfigurationName function in 
//                               the correspondent configuration).
//
// Returns:
//  String - ID of data exchange setup.
// 
Function ExchangeSettingOptionForCorrespondent(ExchangePlanName, CorrespondentName) Export
	
	ExchangePlanSettings = ExchangePlanSettings(ExchangePlanName, "", CorrespondentName, True);
	If ExchangePlanSettings.ExchangeSettingsOptions.Count() = 0 Then
		Return "";
	Else
		Return ExchangePlanSettings.ExchangeSettingsOptions[0].SettingID;
	EndIf;
	
EndFunction

// End SaaSTechnology.SaaS.DataExchangeSaaS

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Adds information on number of items per transaction set in the constant to the structure that 
// contains parameters of exchange message transport.
//
// Parameters:
//  Result - Structure - contains parameters of exchange message transport.
// 
Procedure AddTransactionItemCountToTransportSettings(Result) Export
	
	Result.Insert("DataExportTransactionItemsCount", DataExportTransactionItemsCount());
	Result.Insert("DataImportTransactionItemCount", DataImportTransactionItemCount());
	
EndProcedure

// Returns the area number by the exchange plan node code (message exchange).
// 
// Parameters:
//  NodeCode - String - an exchange plan node code.
// 
// Returns:
//  Number - area number.
//
Function DataAreaNumberByExchangePlanNodeCode(Val NodeCode) Export
	
	If TypeOf(NodeCode) <> Type("String") Then
		Raise NStr("ru = 'Неправильный тип параметра номер [1].'; en = 'Invalid type of parameter #1.'; pl = 'Typ parametru nr [1] jest niepoprawny.';de = 'Ungültiger Typ der Parameternummer [1].';ro = 'Tip incorect al parametrului număr [1].';tr = 'Geçersiz parametre numarası [1].'; es_ES = 'Tipo inválido del número del parámetro [1].'");
	EndIf;
	
	Result = StrReplace(NodeCode, "S0", "");
	
	Return Number(Result);
EndFunction

// Returns data of the first record of query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult - a query result containing the data to be processed.
// 
// Returns:
//  Structure - a structure with the result.
//
Function QueryResultToStructure(Val QueryResult) Export
	
	Result = New Structure;
	For Each Column In QueryResult.Columns Do
		Result.Insert(Column.Name);
	EndDo;
	
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	FillPropertyValues(Result, Selection);
	
	Return Result;
EndFunction

// Obsolete. Use the ExchangePlanSettingValue function by setting ParameterName to one of the 
// following values:
//  - NewDataExchangeCreationCommandTitle;
//  - ExchangeCreateWizardTitle;
//  - ExchangePlanNodeTitle;
//  - CorrespondentConfigurationDescription
//
// Returns an overridable exchange plan name if set, depending on the predefined exchange setting.
// 
// Parameters:
//   ExchangePlanNode - ExchangePlanRef - an exchange plan node to get predefined name for.
//                                                
//   ParameterNameWithNodeName - String - a name of default parameter to get the node name from.
//   SetupOption        - String - exchange setup option.
//
// Returns:
//  String - a predefined exchange plan name as it is set in Designer.
//
Function OverridableExchangePlanNodeName(Val ExchangePlanNode, ParameterNameWithNodeName, SetupOption = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangePlanPresentation = ExchangePlanSettingValue(
		ExchangePlanNode.Metadata().Name,
		ParameterNameWithNodeName,
		SetupOption);
	
	SetPrivilegedMode(False);
	
	Return ExchangePlanPresentation;
	
EndFunction

#EndRegion

// An entry point to iterate data exchange (import and export) with the external system by the exchange plan node.
//
// Parameters:
//  Correspondent - ExchangePlanRef - an exchange plan node matching the external system.
//  ExchangeParameters - Structure - it must contain the following parameters:
//    * PerformImport - Boolean - indicates whether data export is required.
//    * ExecuteSettingsSending - Boolean - indicates that it is necessary to send XDTO settings.
//  FlagError - Boolean - True if an error occurs during the exchange.
//                        See technical information on the error in the event log.
// 
Procedure ExecuteDataExchangeWithExternalSystem(Correspondent, ExchangeParameters, FlagError) Export
	
	AdditionalParameters = New Structure;
		
	ActionImport = Enums.ActionsOnExchange.DataImport;
	ActionExport = Enums.ActionsOnExchange.DataExport;
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	ParametersOnly = False;
	ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem;
	
	FlagError = False;
	
	If ExchangeParameters.ExecuteImport Then
		ExecuteExchangeActionForInfobaseNode(FlagError, Correspondent,
			ActionImport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
	EndIf;
	
	If ExchangeParameters.ExecuteSettingsSending Then
		ExecuteExchangeActionForInfobaseNode(FlagError, Correspondent,
			ActionExport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

#Region DifferentPurpose

// Imports the priority data received from the master DIB node.
Procedure ImportPriorityDataToSubordinateDIBNode(Cancel = False) Export
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
	SetPrivilegedMode(False);
	
	Try
		
		If NOT GetFunctionalOption("UseDataSynchronization") Then
			
			If Common.DataSeparationEnabled() Then
				
				UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
				UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				UseDataSynchronization.DataExchange.Load = True;
				UseDataSynchronization.Value = True;
				UseDataSynchronization.Write();
				
			Else
				
				If GetExchangePlansInUse().Count() > 0 Then
					
					UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
					UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
					UseDataSynchronization.DataExchange.Load = True;
					UseDataSynchronization.Value = True;
					UseDataSynchronization.Write();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				InformationRegisters.DeleteExchangeTransportSettings.TransferSettingsOfCorrespondentDataExchangeTransport(InfobaseNode);
				TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
				
				// Importing application parameters only.
				ExchangeParameters = ExchangeParameters();
				ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
				ExchangeParameters.ExecuteImport = True;
				ExchangeParameters.ExecuteExport = False;
				ExchangeParameters.ParametersOnly   = True;
				ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
				
			EndIf;
			
		EndIf;
		
	Except
		SetPrivilegedMode(True);
		SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		SetPrivilegedMode(False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WriteLogEvent(
			NStr("ru = 'Обмен данными.Загрузка приоритетных данных'; en = 'Data exchange.Import priority data'; pl = 'Wymiana danych.Pobieranie danych priorytetowych';de = 'Datenaustausch.Herunterladen von Prioritätsdaten ';ro = 'Schimb de date.Încărcarea datelor prioritare';tr = 'Veri alışverişi.  Öncelikli verilerin içe aktarılması'; es_ES = 'Intercambio de datos.Descarga de los datos de prioridad'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		Raise
			NStr("ru = 'Ошибка загрузки приоритетных данных из сообщения обмена.
			           |См. подробности в журнале регистрации.'; 
			           |en = 'Cannot import priority data from the exchange message.
			           |For more information, see the event log.'; 
			           |pl = 'Błąd pobierania danych priorytetowych z komunikatu wymiany.
			           |Zob. szczegóły w dzienniku rejestracji.';
			           |de = 'Fehler beim Herunterladen von Prioritätsdaten aus der Austauschnachricht.
			           |Siehe das Ereignisprotokoll für Details.';
			           |ro = 'Eroare de încărcare a datelor prioritare din mesajul de schimb.
			           |Detalii vezi în registrul logare.';
			           |tr = 'Öncelikli verilerin alışveriş mesajından içe aktarılma hatası. 
			           | Detaylar için bkz. kayıt günlüğü.'; 
			           |es_ES = 'Error de descargar los datos de prioridad del mensaje de intercambio.
			           |Véase los detalles en el registro.'");
	EndTry;
	SetPrivilegedMode(True);
	SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
	SetPrivilegedMode(False);
	
	If Cancel Then
		
		If ConfigurationChanged() Then
			Raise
				NStr("ru = 'Загружены изменения программы, полученные из главного узла.
				           |Завершите работу программы. Откройте программу в конфигураторе
				           |и выполните команду ""Обновить конфигурацию базы данных (F7)"".
				           |
				           |После этого запустите программу.'; 
				           |en = 'The application changes received from the main node are imported.
				           |Please exit the application, open the application in Designer
				           |and run the ""Update database configuration (F7)"" command.
				           |
				           |Then run the application.'; 
				           |pl = 'Zostały pobrane zmiany programu, otrzymane z głównego węzła.
				           |Zakończ pracę programu. Otwórz program w konfiguratorze
				           |i wykonaj polecenie ""Обновить конфигурацию базы данных (F7)"".
				           |
				           |Po tym uruchom program.';
				           |de = 'Vom Hauptknoten empfangene Programmänderungen werden geladen.
				           |Schließen Sie das Programm. Öffnen Sie das Programm im Konfigurator
				           |und führen Sie den Befehl ""Datenbankkonfiguration aktualisieren (F7)"" aus.
				           |
				           |Starten Sie dann das Programm.';
				           |ro = 'Modificările aplicației primite de la nodul principal sunt importate.
				           |Închideți programul. Deschideți aplicația din designer
				           |și executați ""Actualizare configurația bazei de date (F7)"".
				           |
				           |După aceasta lansați aplicația.';
				           |tr = 'Ana üniteden alınan uygulama değişiklikleri içe aktarıldı. 
				           |Uygulama çalışmalarını bitirin. Uygulamayı 
				           |yapılandırıcıda açın ve Güncelleme veri tabanı yapılandırmasını (F7) komutunu çalıştırın. 
				           |
				           |Ondan sonra uygulamayı başlatın.'; 
				           |es_ES = 'Modificaciones del programa descargadas desde el nodo principal.
				           |Termine el trabajo del programa. Abra el programa en el configurador
				           |y lance el comando ""Actualizar la configuración de la base de datos (F7)"".
				           |
				           |Después reinicie el programa.'");
		EndIf;
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		Raise
			NStr("ru = 'Ошибка загрузки приоритетных данных из сообщения обмена.
			           |См. подробности в журнале регистрации.'; 
			           |en = 'Cannot import priority data from the exchange message.
			           |For more information, see the event log.'; 
			           |pl = 'Błąd pobierania danych priorytetowych z komunikatu wymiany.
			           |Zob. szczegóły w dzienniku rejestracji.';
			           |de = 'Fehler beim Herunterladen von Prioritätsdaten aus der Austauschnachricht.
			           |Siehe das Ereignisprotokoll für Details.';
			           |ro = 'Eroare de încărcare a datelor prioritare din mesajul de schimb.
			           |Detalii vezi în registrul logare.';
			           |tr = 'Öncelikli verilerin alışveriş mesajından içe aktarılma hatası. 
			           | Detaylar için bkz. kayıt günlüğü.'; 
			           |es_ES = 'Error de descargar los datos de prioridad del mensaje de intercambio.
			           |Véase los detalles en el registro.'");
	EndIf;
	
EndProcedure

// Sets the RetryDataExchangeMessageImportBeforeStart constant value to True.
// Clears exchange messages received from the master node.
//
Procedure EnableDataExchangeMessageImportRecurrenceBeforeStart() Export
	
	ClearDataExchangeMessageFromMasterNode();
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(True);
	
EndProcedure

// Initializes the XML file to write information on objects marked for update processing, to pass 
// them to a subordinate DIB node.
//
Procedure InitializeUpdateDataFile(Parameters) Export
	
	FileToWriteXML = Undefined;
	NameOfChangedFile = Undefined;
	
	If StandardSubsystemsCached.DIBUsed("WithFilter") Then
		
		NameOfChangedFile = FileOfDeferredUpdateDataFullName();
		
		FileToWriteXML = New FastInfosetWriter;
		FileToWriteXML.OpenFile(NameOfChangedFile);
		FileToWriteXML.WriteXMLDeclaration();
		FileToWriteXML.WriteStartElement("Objects");
		
	EndIf;
	
	Parameters.NameOfChangedFile = NameOfChangedFile;
	Parameters.WriteChangesForSubordinateDIBNodeWithFilters = FileToWriteXML;
	
EndProcedure

// Initializes the XML file to write information on objects.
//
Procedure WriteUpdateDataToFile(Parameters, Data, DataKind, FullObjectName = "") Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter") Then
		Return;
	EndIf;
	
	If Parameters.WriteChangesForSubordinateDIBNodeWithFilters = Undefined Then
		ExceptionText = NStr("ru = 'В обработчике неправильно организована работа с параметрами регистрации данных к обработке.'; en = 'Operations with data registration parameters for processing are invalid in the handler.'; pl = 'W programie przetwarzania jest nieprawidłowo zorganizowana praca z parametrami rejestracji danych do przetwarzania.';de = 'Im Handler ist die Arbeit mit den Datenprotokollierungsparametern für die Verarbeitung falsch organisiert.';ro = 'În handler este organizat incorect lucrul cu parametrii de înregistrare a datelor pentru procesare.';tr = 'İşleyicide, işleme için veri kaydı parametreleri ile çalışma doğru ayarlanmadı.'; es_ES = 'En el procesador se ha organizado incorrectamente el uso de los parámetros de registro de datos para procesar.'");
		Raise ExceptionText;
	EndIf;
	
	XMLWriter = Parameters.WriteChangesForSubordinateDIBNodeWithFilters;
	XMLWriter.WriteStartElement("Object");
	XMLWriter.WriteAttribute("Queue", String(Parameters.Queue));
	
	If Not ValueIsFilled(FullObjectName) Then
		FullObjectName = Data.Metadata().FullName();
	EndIf;
	
	XMLWriter.WriteAttribute("Type", FullObjectName);
	
	If Upper(DataKind) = "REFS" Then
		XMLWriter.WriteAttribute("Ref", XMLString(Data.Ref));
	Else
		
		If Upper(DataKind) = "INDEPENDENTREGISTER" Then
			
			XMLWriter.WriteStartElement("Filter");
			For Each FilterItem In Data.Filter Do
				
				If ValueIsFilled(FilterItem.Value) Then
					XMLWriter.WriteStartElement(FilterItem.Name);
					
					DataType = TypeOf(FilterItem.Value);
					MetadataObject =  Metadata.FindByType(DataType);
					
					If MetadataObject <> Undefined Then
						XMLWriter.WriteAttribute("Type", MetadataObject.FullName());
					ElsIf DataType = Type("UUID") Then
						XMLWriter.WriteAttribute("Type", "UUID");
					Else
						XMLWriter.WriteAttribute("Type", String(DataType));
					EndIf;
					
					XMLWriter.WriteAttribute("Val", XMLString(FilterItem.Value));
					XMLWriter.WriteEndElement();
				EndIf;
				
			EndDo;
			XMLWriter.WriteEndElement();
			
		Else
			Recorder = Data.Filter.Recorder.Value;
			XMLWriter.WriteAttribute("FilterType", String(Recorder.Metadata().FullName()));
			XMLWriter.WriteAttribute("Ref",        XMLString(Recorder.Ref));
		EndIf;
		
	EndIf;
	
	XMLWriter.WriteEndElement();

EndProcedure

// Executes registration in the subordinate DIB node with filtered objects registered for deferred 
// update in the master DIB node.
//
Procedure ProcessDataToUpdateInSubordinateNode(Val ConstantValue) Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter")
		Or Not IsSubordinateDIBNode()
		Or ExchangePlanPurpose(MasterNode().Metadata().Name) <> "DIBWithFilter" Then
		Return;
	EndIf;
	
	ArrayOfValues    = ConstantValue.Value.Get();
	If TypeOf(ArrayOfValues) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each ValueStorage In ArrayOfValues Do
		FileName = FileOfDeferredUpdateDataFullName();
		
		If ValueStorage = Undefined Then
			Return;
		EndIf;
		
		BinaryData = ValueStorage.Get();
		If BinaryData = Undefined Then
			Return;
		EndIf;
		
		If Common.IsSubordinateDIBNode() Then
			Query = New Query;
			Query.Text = 
			"SELECT
			|	InfobaseUpdate.Ref AS Node
			|FROM
			|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
			|WHERE
			|	NOT InfobaseUpdate.ThisNode";
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ExchangePlans.DeleteChangeRecords(Selection.Node);
			EndDo;
		EndIf;
		
		BinaryData.Write(FileName);
		
		XMLReader = New FastInfosetReader;
		XMLReader.OpenFile(FileName);
		
		HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
		
		While XMLReader.Read() Do
			
			If XMLReader.Name = "Object"
				AND XMLReader.NodeType = XMLNodeType.StartElement Then
				
				HandlerParametersStructure.Queue = Number(XMLReader.AttributeValue("Queue"));
				FullMetadataObjectName            = TrimAll(XMLReader.AttributeValue("Type"));
				MetadataObjectType                  = Metadata.FindByFullName(FullMetadataObjectName);
				ObjectManager                       = Common.ObjectManagerByFullName(FullMetadataObjectName);
				IsReferenceObjectType                = Common.IsRefTypeObject(MetadataObjectType);
				
				If IsReferenceObjectType Then
					ObjectToProcess = ObjectManager.GetRef(New UUID(XMLReader.AttributeValue("Ref")));
				Else
					
					ObjectToProcess = ObjectManager.CreateRecordSet();
					
					If Common.IsInformationRegister(MetadataObjectType)
						AND MetadataObjectType.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
						
						XMLReader.Read();
						
						If XMLReader.Name = "Filter"
							AND XMLReader.NodeType = XMLNodeType.StartElement Then
							
							WritingFilter = True;
							
							While WritingFilter Do
								
								XMLReader.Read();
								
								If XMLReader.Name = "Filter" AND XMLReader.NodeType = XMLNodeType.EndElement Then
									WritingFilter = False;
									Continue;
								ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
									Continue;
								Else
									
									FilterValue = XMLReader.AttributeValue("Val");
									If ValueIsFilled(FilterValue) Then
										
										FilterName         = XMLReader.Name;
										FilterValueType = XMLReader.AttributeValue("Type");
										FilterValueMetadata = Metadata.FindByFullName(FilterValueType);
										
										If FilterValueMetadata <> Undefined Then
											
											FilterObjectManager = Common.ObjectManagerByFullName(FilterValueType);
											
											If Common.IsEnum(FilterValueMetadata) Then
												ValueRef = FilterObjectManager[FilterValue];
											Else
												ValueRef = FilterObjectManager.GetRef(New UUID(FilterValue));
											EndIf;
											
											ObjectToProcess.Filter[FilterName].Set(ValueRef);
											
										Else
											If Upper(StrReplace(FilterValueType, " ", "")) = "UUID" Then
												ObjectToProcess.Filter[FilterName].Set(XMLValue(Type("UUID"), FilterValue));
											Else
												ObjectToProcess.Filter[FilterName].Set(XMLValue(Type(FilterValueType), FilterValue));
											EndIf;
										EndIf;
										
									EndIf;
									
								EndIf;
								
							EndDo;
							
						EndIf;
						
					Else
						
						RecorderValue  = New UUID(XMLReader.AttributeValue("Ref"));
						FullRecorderName = XMLReader.AttributeValue("FilterType");
						RecorderManager  = Common.ObjectManagerByFullName(FullRecorderName);
						RecorderRef   = RecorderManager.GetRef(RecorderValue);
						ObjectToProcess.Filter.Recorder.Set(RecorderRef);
						
					EndIf;
					
					ObjectToProcess.Read();
					
				EndIf;
				
				InfobaseUpdate.MarkForProcessing(HandlerParametersStructure, ObjectToProcess);
				
			Else
				Continue;
			EndIf;
			
		EndDo;
		
		XMLReader.Close();
		
		File = New File(FileName);
		If File.Exist() Then
			DeleteFiles(FileName);
		EndIf;
	EndDo;
	
EndProcedure

// Closes the XML file with written information on objects registered for deferred update.
// 
//
Procedure CompleteWriteUpdateDataFile(Parameters) Export
	
	UpdateData = CompleteWriteFileAndGetUpdateData(Parameters);
	
	If UpdateData <> Undefined Then
		SaveUpdateData(UpdateData, Parameters.NameOfChangedFile);
	EndIf;
	
EndProcedure

// Closes the XML file with written information on objects registered for deferred update and 
// returns file content.
//
// Parameters:
//  Parameters - Structure - see InfobaseUpdate.MainProcessingMarkParameters(). 
//
// Returns:
//  ValueStorage - file content.
//
Function CompleteWriteFileAndGetUpdateData(Parameters) Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter")
		Or Common.IsSubordinateDIBNode() Then
		Return Undefined;
	EndIf;
	
	If Parameters.WriteChangesForSubordinateDIBNodeWithFilters = Undefined Then
		ExceptionText = NStr("ru = 'В обработчике неправильно организована работа с параметрами регистрации данных к обработке.'; en = 'Operations with data registration parameters for processing are invalid in the handler.'; pl = 'W programie przetwarzania jest nieprawidłowo zorganizowana praca z parametrami rejestracji danych do przetwarzania.';de = 'Im Handler ist die Arbeit mit den Datenprotokollierungsparametern für die Verarbeitung falsch organisiert.';ro = 'În handler este organizat incorect lucrul cu parametrii de înregistrare a datelor pentru procesare.';tr = 'İşleyicide, işleme için veri kaydı parametreleri ile çalışma doğru ayarlanmadı.'; es_ES = 'En el procesador se ha organizado incorrectamente el uso de los parámetros de registro de datos para procesar.'");
		Raise ExceptionText;
	EndIf;
	
	XMLWriter = Parameters.WriteChangesForSubordinateDIBNodeWithFilters;
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
	NameOfChangedFile = Parameters.NameOfChangedFile;
	FileBinaryData = New BinaryData(NameOfChangedFile);
	
	Return New ValueStorage(FileBinaryData, New Deflation(9));
	
EndFunction

// Saves file content from CompleteWriteFileAndGetUpdateData() to the DeferredUpdateData constant.
// 
//
// Parameters:
//  UpdateData - ValueStorage - file content.
//  NameOfChangedFile - String - a name of data file.
//
Procedure SaveUpdateData(UpdateData, NameOfChangedFile) Export
	
	If NameOfChangedFile = Undefined Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		Lock.Add("Constant.DataForDeferredUpdate");
		Lock.Lock();
		
		ConstantValue = Constants.DataForDeferredUpdate.Get().Get();
		If TypeOf(ConstantValue) <> Type("Array") Then
			ConstantValue = New Array;
		EndIf;
		
		ConstantValue.Add(UpdateData);

		Constants.DataForDeferredUpdate.Set(New ValueStorage(ConstantValue));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	FileWithData = New File(NameOfChangedFile);
	If FileWithData.Exist() Then
		DeleteFiles(NameOfChangedFile);
	EndIf;
	
EndProcedure

// Clears the WriteChangesForSubordinateDIBNodeWithFilters constant value on update.
//
Procedure ClearConstantValueWithChangesForSUbordinateDIBNodeWithFilters() Export
	
	Constants.DataForDeferredUpdate.Set(Undefined);
	
EndProcedure

// Returns True if the DIB node setup is not completed and it is required to update the application 
// parameters that are not used in DIB.
//
Function SubordinateDIBNodeSetup() Export
	
	SetPrivilegedMode(True);
	
	Return IsSubordinateDIBNode()
	      AND NOT Constants.SubordinateDIBNodeSetupCompleted.Get();
	
EndFunction

// Updates object conversion or registration rules.
// Update is performed for all exchange plans that use SSL functionality.
// Updates only standard rules.
// Rules loaded from a file are not updated.
//
Procedure UpdateDataExchangeRules() Export
	
	// If an exchange plan was renamed or deleted from the configuration.
	DeleteObsoleteRecordsFromDataExchangeRulesRegister();
	
	If Not GetFunctionalOption("UseDataSynchronization")
		AND Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	LoadedFromFileExchangeRules = New Array;
	RegistrationRulesImportedFromFile = New Array;
	
	CheckLoadedFromFileExchangeRulesAvailability(LoadedFromFileExchangeRules, RegistrationRulesImportedFromFile);
	UpdateStandardDataExchangeRuleVersion(LoadedFromFileExchangeRules, RegistrationRulesImportedFromFile);
	
EndProcedure

// See DataExchangeCached.TempFilesStorageDirectory() 
//
Function TempFilesStorageDirectory() Export
	
	SafeMode = SafeMode();
	Return DataExchangeCached.TempFilesStorageDirectory(SafeMode);
	
EndFunction

#EndRegion

#Region ProgressBar

// Calculates export progress and writes as a message to user.
//
// Parameters:
//  ExportedCount - Number - a number of objects exported at the moment.
//  ObjectsToExportCount - Number - number of objects to export.
//
Procedure CalculateExportPercent(ExportedCount, ObjectsToExportCount) Export
	
	// Showing export progress message every 100 objects.
	If ExportedCount = 0 OR ExportedCount / 100 <> Int(ExportedCount / 100) Then
		Return;
	EndIf;
	
	If ObjectsToExportCount = 0 Or ExportedCount > ObjectsToExportCount Then
		ProgressPercent = 95;
		Template = NStr("ru = 'Обработано: %1 объектов.'; en = '%1 objects processed.'; pl = 'Przetworzono: %1 obiektów.';de = 'Bearbeitet: %1 Objekte.';ro = 'Obiecte procesate: %1.';tr = 'İşlenen: %1 nesne.'; es_ES = 'Procesado: %1 objetos.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Format(ExportedCount, "NZ=0; NG="));
	Else
		// Reserving 5% of the bar for export by references, calculating the number percent basing on 95.
		ProgressPercent = Round(Min(ExportedCount * 95 / ObjectsToExportCount, 95));
		Template = NStr("ru = 'Обработано: %1 из %2 объектов.'; en = '%1 out of %2 objects processed.'; pl = 'Przetworzono: %1 z %2 obiektów.';de = 'Bearbeitet: %1 von %2 Objekten.';ro = 'Obiecte procesate: %1 din %2.';tr = 'İşlendi: %1 nesneden %2.'; es_ES = 'Procesado: %1 de %2 objetos.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Format(ExportedCount, "NZ=0; NG="),
			Format(ObjectsToExportCount, "NZ=0; NG="));
	EndIf;
	
	// Register a message to read it from the client session.
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataExchange", True);
	
	TimeConsumingOperations.ReportProgress(ProgressPercent, Text, AdditionalParameters);
EndProcedure

// Calculates import progress and writes as a message to user.
//
// Parameters:
//  ImportedCount - Number - a number of objects imported at the moment.
//  ObjectsToImportCount - Number - a number of objects to import.
//  ExchangeMessageFileSize - Number - the size of exchange message file in megabytes.
//
Procedure CalculateImportPercent(ExportedCount, ObjectsToImportCount, ExchangeMessageFileSize) Export
	// Showing import progress message every 10 objects.
	If ExportedCount = 0 OR ExportedCount / 10 <> Int(ExportedCount / 10) Then
		Return;
	EndIf;

	If ObjectsToImportCount = 0 Then
		// It is possible when importing through COM connection if progress bar is not used on the other side.
		ProgressPercent = 95;
		Template = NStr("ru = 'Обработано %1 объектов.'; en = '%1 objects processed.'; pl = 'Przetworzono %1 obiektów.';de = 'Bearbeitet: %1 Objekte.';ro = 'Obiecte procesate: %1.';tr = '%1 nesne işlendi.'; es_ES = 'Procesado %1 objetos.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Format(ExportedCount, "NZ=0; NG="));
	Else
		// Reserving 5% of the bar for deferred filling, calculating number percent based on 95.
		ProgressPercent = Round(Min(ExportedCount * 95 / ObjectsToImportCount, 95));
		
		Template = NStr("ru = 'Обработано: %1 из %2 объектов.'; en = '%1 out of %2 objects processed.'; pl = 'Przetworzono: %1 z %2 obiektów.';de = 'Bearbeitet: %1 von %2 Objekten.';ro = 'Obiecte procesate: %1 din %2.';tr = 'İşlendi: %1 nesneden %2.'; es_ES = 'Procesado: %1 de %2 objetos.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Format(ExportedCount, "NZ=0; NG="),
			Format(ObjectsToImportCount, "NZ=0; NG="));
	EndIf;
	
	// Adding file size.
	If ExchangeMessageFileSize <> 0 Then
		Template = NStr("ru = 'Размер сообщения %1 МБ'; en = 'Message size: %1 MB'; pl = 'Rozmiar komunikatu %1 MB';de = 'Nachrichtengröße %1 MB';ro = 'Dimensiunea mesajului %1 MB';tr = 'Mesaj boyutu %1 MB'; es_ES = 'Tamaño del mensaje %1 MB'");
		TextAddition = StringFunctionsClientServer.SubstituteParametersToString(Template, ExchangeMessageFileSize);
		Text = Text + " " + TextAddition;
	EndIf;
	
	// Register a message to read it from the client session.
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataExchange", True);
	
	TimeConsumingOperations.ReportProgress(ProgressPercent, Text, AdditionalParameters);

EndProcedure

// Increasing counter of exported objects and calculating export percent. Only for DIB.
//
// Parameters:
//   Recipient - an exchange plan object.
//   InitialImageCreation - Boolean.
//
Procedure CalculateDIBDataExportPercentage(Recipient, InitialImageCreation) Export
	
	If Recipient = Undefined
		Or Not DataExchangeCached.IsDistributedInfobaseNode(Recipient.Ref) Then
		Return;
	EndIf;
	
	// Counting the number of objects to be exported.
	If NOT Recipient.AdditionalProperties.Property("ObjectsToExportCount") Then
		ObjectsToExportCount = 0;
		If InitialImageCreation Then
			ObjectsToExportCount = CalculateObjectsCountInInfobase(Recipient);
		Else
			// Extracting the total number of objects to be exported.
			CurrentSessionParameter = Undefined;
			SetPrivilegedMode(True);
			Try
				CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
			Except
				Return;
			EndTry;
			SetPrivilegedMode(False);
			If TypeOf(CurrentSessionParameter) = Type("Map") Then
				SynchronizationData = CurrentSessionParameter.Get(Recipient.Ref);
				If NOT (SynchronizationData = Undefined 
					OR TypeOf(SynchronizationData) <> Type("Structure")) Then
					ObjectsToExportCount = SynchronizationData.ObjectsToExportCount;
				EndIf;
			EndIf;
		EndIf;
		Recipient.AdditionalProperties.Insert("ObjectsToExportCount", ObjectsToExportCount);
		Recipient.AdditionalProperties.Insert("ExportedObjectCounter", 1);
		Return; // In this case, there is no need to calculate export percent. This is the very beginning of export.
	Else
		If Recipient.AdditionalProperties.Property("ExportedObjectCounter") Then
			Recipient.AdditionalProperties.ExportedObjectCounter = Recipient.AdditionalProperties.ExportedObjectCounter + 1;
		Else
			Return;
		EndIf;
	EndIf;
	
	CalculateExportPercent(Recipient.AdditionalProperties.ExportedObjectCounter,
		Recipient.AdditionalProperties.ObjectsToExportCount);
EndProcedure

// Increasing counter of imported objects and calculating import percent. Only for DIB.
//
// Parameters:
//   Sender - an exchange plan object.
//
Procedure CalculateDIBDataImportPercentage(Sender) Export
	
	If Sender = Undefined
		Or Not DataExchangeCached.IsDistributedInfobaseNode(Sender.Ref) Then
		Return;
	EndIf;
	If NOT Sender.AdditionalProperties.Property("ObjectsToImportCount")
		OR NOT Sender.AdditionalProperties.Property("ExchangeMessageFileSize") Then
		// Extracting the total number of objects to be imported and the size of exchange message file.
		CurrentSessionParameter = Undefined;
		SetPrivilegedMode(True);
		Try
			CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
		Except
			Return;
		EndTry;
		SetPrivilegedMode(False);
		If TypeOf(CurrentSessionParameter) = Type("Map") Then
			SynchronizationData = CurrentSessionParameter.Get(Sender.Ref);
			If SynchronizationData = Undefined 
				OR TypeOf(SynchronizationData) <> Type("Structure") Then
				Return;
			EndIf;
			Sender.AdditionalProperties.Insert("ObjectsToImportCount", 
														SynchronizationData.ObjectsToImportCount);
			Sender.AdditionalProperties.Insert("ExchangeMessageFileSize", 
														SynchronizationData.ExchangeMessageFileSize);
		EndIf;
	EndIf;
	If Not Sender.AdditionalProperties.Property("ImportedObjectCounter") Then
		Sender.AdditionalProperties.Insert("ImportedObjectCounter", 1);
	Else
		Sender.AdditionalProperties.ImportedObjectCounter = Sender.AdditionalProperties.ImportedObjectCounter + 1;
	EndIf;
	
	CalculateImportPercent(Sender.AdditionalProperties.ImportedObjectCounter,
		Sender.AdditionalProperties.ObjectsToImportCount,
		Sender.AdditionalProperties.ExchangeMessageFileSize);
	
EndProcedure

// Analyzes data to import:
// Calculates the number of objects to be imported, the size of exchange message file, and other service data.
// Parameters:
//  ExchangeFileName - String - an exchange message file name.
//  IsXDTOExchange - Boolean - indicates that exchange via universal format is being executed.
// 
// Returns:
//  Structure - structure properties:
//    * ExchangeMessageFileSize - Number - the size of the exchange message file in megabytes, 0 by default.
//    * ObjectsToImportCount - Number - number of objects to import, 0 by default.
//    * From - String - code of message sender node.
//    * To - String - code of message recipient node.
//    * NewFrom - String - a sender node code in new format (to convert current exchanges to a new encoding).
Function DataAnalysisResultToExport(Val ExchangeFileName, IsXDTOExchange, IsDIBExchange = False) Export
	
	Result = New Structure;
	Result.Insert("ExchangeMessageFileSize", 0);
	Result.Insert("ObjectsToImportCount", 0);
	Result.Insert("From", "");
	Result.Insert("NewFrom", "");
	Result.Insert("To", "");
	
	If NOT ValueIsFilled(ExchangeFileName) Then
		Return Result;
	EndIf;
	
	FileWithData = New File(ExchangeFileName);
	If Not FileWithData.Exist() Then
		Return Result;
	EndIf;
	
	ExchangeFile = New XMLReader;
	Try
		// Converting the size to megabytes.
		Result.ExchangeMessageFileSize = Round(FileWithData.Size() / 1048576, 1);
		ExchangeFile.OpenFile(ExchangeFileName);
	Except
		Return Result;
	EndTry;
	
	// The algorithm of exchange file analysis depends on exchange kind.
	If IsXDTOExchange Then
		ExchangeFile.Read(); // Message.
		ExchangeFile.Read();  // Header start.
		StartObjectsAccount = False;
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Header" Then
				// Header is read.
				StartObjectsAccount = True;
				ExchangeFile.Skip(); 
			ElsIf ExchangeFile.LocalName = "Confirmation" Then
				ExchangeFile.Read();
			ElsIf ExchangeFile.LocalName = "From" Then
				ExchangeFile.Read();
				Result.From = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf ExchangeFile.LocalName = "To" Then
				ExchangeFile.Read();
				Result.To = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf ExchangeFile.LocalName = "NewFrom" Then
				ExchangeFile.Read();
				Result.NewFrom = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf StartObjectsAccount 
				AND ExchangeFile.NodeType = XMLNodeType.StartElement 
				AND ExchangeFile.LocalName <> "ObjectDeletion" 
				AND ExchangeFile.LocalName <> "Body" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
				ExchangeFile.Skip();
			EndIf;
		EndDo;

	ElsIf IsDIBExchange Then
		ExchangeFile.Read(); // Message.
		ExchangeFile.Read();  // Header start.
		ExchangeFile.Skip(); // Header end.
		ExchangeFile.Read(); //Body start.
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Changes"
				OR ExchangeFile.LocalName = "Data" Then
				Continue;
			ElsIf StrFind(ExchangeFile.LocalName, "Config") = 0 
				AND StrFind(ExchangeFile.LocalName, "Signature") = 0
				AND StrFind(ExchangeFile.LocalName, "Nodes") = 0
				AND ExchangeFile.LocalName <> "Parameters"
				AND ExchangeFile.LocalName <> "Body" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
			EndIf;
			ExchangeFile.Skip();
		EndDo;	
	Else
		
		ExchangeFile.Read(); // Exchange file.
		ExchangeFile.Read();  // ExchangeRules start.
		ExchangeFile.Skip(); // ExchangeRules end.

		ExchangeFile.Read();  // DataTypes start.
		ExchangeFile.Skip(); // DataTypes end.

		ExchangeFile.Read();  // Exchange data start.
		ExchangeFile.Skip(); // Exchange data end.
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Object"
				OR ExchangeFile.LocalName = "RegisterRecordSet"
				OR ExchangeFile.LocalName = "ObjectDeletion"
				OR ExchangeFile.LocalName = "ObjectRegistrationInformation" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
			EndIf;
			ExchangeFile.Skip();
		EndDo;
	EndIf;
	ExchangeFile.Close();
	
	Return Result;
EndFunction

#EndRegion

#Region OperationsWithFTPConnectionObject

Function FTPConnection(Val Settings) Export
	
	Return New FTPConnection(
		Settings.Server,
		Settings.Port,
		Settings.UserName,
		Settings.UserPassword,
		ProxyServerSettings(Settings.SecureConnection),
		Settings.PassiveConnection,
		Settings.Timeout,
		Settings.SecureConnection);
	
EndFunction

Function FTPConnectionSettings(Val Timeout = 180) Export
	
	Result = New Structure;
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("UserName", "");
	Result.Insert("UserPassword", "");
	Result.Insert("PassiveConnection", False);
	Result.Insert("Timeout", Timeout);
	Result.Insert("SecureConnection", Undefined);
	
	Return Result;
EndFunction

// Returns server name and FTP server path. This data is gotten from FTP server connection string.
//
// Parameters:
//  StringForConnection - String - an FTP resource connection string.
// 
// Returns:
//  Structure - FTP server connection settings. The structure includes the following fields:
//              Server - String - a server name.
//              Path   - String - a server path.
//
//  Example (1):
// Result = FTPServerNameAndPath("ftp://server");
// Result.Server = "server";
// Result.Path = "/";
//
//  Example (2):
// Result = FTPServerNameAndPath("ftp://server/saas/exchange");
// Result.Server = "server";
// Result.Path = "/saas/exchange/";
//
Function FTPServerNameAndPath(Val StringForConnection) Export
	
	Result = New Structure("Server, Path");
	StringForConnection = TrimAll(StringForConnection);
	
	If (Upper(Left(StringForConnection, 6)) <> "FTP://"
		AND Upper(Left(StringForConnection, 7)) <> "FTPS://")
		OR StrFind(StringForConnection, "@") <> 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Строка подключения к FTP-ресурсу не соответствует формату: ""%1""'; en = 'The FTP connection string has invalid format: ""%1"".'; pl = 'Wiersz połączenia FTP nie jest zgodny z formatem: ""%1""';de = 'FTP-Verbindungszeichenfolge stimmt nicht mit dem Format überein: ""%1""';ro = 'Conexiunea FTP de tip șir nu se potrivește cu formatul: ""%1""';tr = 'FTP bağlantı dizesi şu biçimle eşleşmiyor: ""%1""'; es_ES = 'Línea de conexión FTP no coincide con el formato: ""%1""'"), StringForConnection);
	EndIf;
	
	ConnectionParameters = StrSplit(StringForConnection, "/");
	
	If ConnectionParameters.Count() < 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В строке подключения к FTP-ресурсу не указано имя сервера: ""%1""'; en = 'The server name is missing from the FTP connection string: ""%1"".'; pl = 'Nie określono nazwy ciągu połączenia zasobów FTP: ""%1""';de = 'Der Servername wird in der Zeichenkette FTP-Ressourcenverbindung nicht angegeben: ""%1""';ro = 'Numele serverului nu este specificat în șirul de conectare a resurselor FTP: ""%1""';tr = 'FTP kaynak bağlantı dizesinde sunucu adı belirtilmemiş: ""%1""'; es_ES = 'Nombre del servidor no está especificado en la línea de conexión del recurso FTP: ""%1""'"), StringForConnection);
	EndIf;
	
	Result.Server = ConnectionParameters[2];
	
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	
	ConnectionParameters.Insert(0, "@");
	
	If Not IsBlankString(ConnectionParameters.Get(ConnectionParameters.UBound())) Then
		
		ConnectionParameters.Add("@");
		
	EndIf;
	
	Result.Path = StrConcat(ConnectionParameters, "/");
	Result.Path = StrReplace(Result.Path, "@", "");
	
	Return Result;
EndFunction

Function OpenDataExchangeCreationWizardForSubordinateNodeSetup() Export
	
	Return Not Common.DataSeparationEnabled()
		AND Not IsStandaloneWorkplace()
		AND IsSubordinateDIBNode()
		AND Not Constants.SubordinateDIBNodeSetupCompleted.Get();
	
EndFunction

#EndRegion

#Region SecurityProfiles

Function RequestToUseExternalResourcesOnEnableExchange() Export
	
	Queries = New Array();
	CreateRequestsToUseExternalResources(Queries);
	Return Queries;
	
EndFunction

Function RequestToClearPermissionsToUseExternalResources() Export
	
	Queries = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Node
		|FROM
		|	ExchangePlan.[ExchangePlanName] AS ExchangePlan";
		
		QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(Selection.Node));
			
		EndDo;
		
	EndDo;
	
	Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(
		Common.MetadataObjectID(Metadata.Constants.DataExchangeMessageDirectoryForLinux)));
	Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(
		Common.MetadataObjectID(Metadata.Constants.DataExchangeMessageDirectoryForWindows)));
	
	Return Queries;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

// Returns a string of invalid characters in the username used for authentication when creating 
// WSProxy.
//
// Returns:
//	String - a string of invalid characters in the username.
//
Function ProhibitedCharsInWSProxyUserName() Export
	
	Return ":";
	
EndFunction

Function NodeIDForExchange(ExchangeNode) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	NodeCode = TrimAll(Common.ObjectAttributeValue(ExchangePlans[ExchangePlanName].ThisNode(), "Code"));
	
	If DataExchangeCached.IsSeparatedSSLDataExchangeNode(ExchangeNode) Then
		
		NodePrefixes = InformationRegisters.CommonInfobasesNodesSettings.NodePrefixes(ExchangeNode);
		ThisNodePrefix = TrimAll(NodePrefixes.Prefix);
		
		If Not IsBlankString(ThisNodePrefix)
			AND StrLen(NodeCode) <= 2 Then
			// Prefix specified on connection setup is used as identification code on exchange.
			// 
			NodeCode = ThisNodePrefix;
		EndIf;
		
	EndIf;
	
	Return NodeCode;
	
EndFunction

Function CorrespondentNodeIDForExchange(ExchangeNode) Export
	
	NodeCode = TrimAll(Common.ObjectAttributeValue(ExchangeNode, "Code"));
	
	If DataExchangeCached.IsSeparatedSSLDataExchangeNode(ExchangeNode) Then
		NodePrefixes = InformationRegisters.CommonInfobasesNodesSettings.NodePrefixes(ExchangeNode);
		
		If StrLen(NodeCode) <= 2
			AND Not IsBlankString(NodePrefixes.CorrespondentPrefix) Then
			// Prefix specified on connection setup is used as identification code on exchange.
			// 
			NodeCode = TrimAll(NodePrefixes.CorrespondentPrefix);
		EndIf;
	EndIf;
	
	Return NodeCode;
	
EndFunction

// Determines whether the SSL exchange plan is a separated one.
//
// Parameters:
//	ExchangePlanName - String - a name of the exchange plan to check.
//
// Returns:
//	Type - Boolean.
//
Function IsSeparatedSSLExchangePlan(Val ExchangePlanName) Export
	
	Return DataExchangeCached.SeparatedSSLExchangePlans().Find(ExchangePlanName) <> Undefined;
	
EndFunction

// Creates the selection of changed data to pass it to an exchange plan node.
// If the method is called in the active transaction, an exception is raised.
// See the ExchangePlansManager.SelectChanges() method details in Syntax Assistant.
//
Function SelectChanges(Val Node, Val MessageNumber, Val SelectionFilter = Undefined) Export
	
	If TransactionActive() Then
		Raise NStr("ru = 'Выборка изменений данных запрещена в активной транзакции.'; en = 'Cannot select data changes in an active transaction.'; pl = 'Wybór zmiany danych jest zabroniony dla aktywnej transakcji.';de = 'Die Auswahl der Datenänderung ist in einer aktiven Transaktion verboten.';ro = 'Selectarea modificărilor datelor este interzisă în tranzacție activă.';tr = 'Etkin bir işlemde veri değişikliği seçimi yasaktır.'; es_ES = 'Selección de cambio de datos está prohibida en una transacción activa.'");
	EndIf;
	
	Return ExchangePlans.SelectChanges(Node, MessageNumber, SelectionFilter);
EndFunction

Function WSParameterStructure() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("WSWebServiceURL");
	ParametersStructure.Insert("WSUsername");
	ParametersStructure.Insert("WSPassword");
	
	Return ParametersStructure;
	
EndFunction

Function DataExchangeMonitorTable(Val ExchangePlans, Val ExchangePlanAdditionalProperties = "") Export
	
	Query = New Query(
	"SELECT
	|	DataExchangeScenarioExchangeSettings.InfobaseNode AS InfobaseNode
	|INTO DataSynchronizationScenarios
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenarioExchangeSettings
	|WHERE
	|	DataExchangeScenarioExchangeSettings.Ref.UseScheduledJob = TRUE
	|
	|GROUP BY
	|	DataExchangeScenarioExchangeSettings.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangePlans.InfobaseNode AS InfobaseNode,
	|
	|	[ExchangePlanAdditionalProperties]
	|
	|	ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) AS LastDataExportResult,
	|	ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) AS LastDataImportResult,
	|	ISNULL(DataExchangeStatesImport.StartDate, DATETIME(1, 1, 1)) AS LastImportStartDate,
	|	ISNULL(DataExchangeStatesImport.EndDate, DATETIME(1, 1, 1)) AS LastImportEndDate,
	|	ISNULL(DataExchangeStatesExport.StartDate, DATETIME(1, 1, 1)) AS LastExportStartDate,
	|	ISNULL(DataExchangeStatesExport.EndDate, DATETIME(1, 1, 1)) AS LastExportEndDate,
	|	ISNULL(SuccessfulDataExchangeStatesImport.EndDate, DATETIME(1, 1, 1)) AS LastSuccessfulExportEndDate,
	|	ISNULL(SuccessfulDataExchangeStatesExport.EndDate, DATETIME(1, 1, 1)) AS LastSuccessfulImportEndDate,
	|	CASE
	|		WHEN DataSynchronizationScenarios.InfobaseNode IS NULL
	|			THEN 0
	|		ELSE 1
	|	END AS ScheduleConfigured,
	|	CommonInfobasesNodesSettings.CorrespondentVersion AS CorrespondentVersion,
	|	CommonInfobasesNodesSettings.CorrespondentPrefix AS CorrespondentPrefix,
	|	CommonInfobasesNodesSettings.SetupCompleted AS SetupCompleted,
	|	CASE
	|		WHEN ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) = 0
	|				AND ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS HasErrors,
	|	ISNULL(MessagesForDataMapping.EmailReceivedForDataMapping, FALSE) AS EmailReceivedForDataMapping,
	|	ISNULL(MessagesForDataMapping.LastMessageStoragePlacementDate, DATETIME(1, 1, 1)) AS DataMapMessageDate
	|FROM
	|	ConfigurationExchangePlans AS ExchangePlans
	|		LEFT JOIN CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|		ON (CommonInfobasesNodesSettings.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN DataExchangeStatesImport AS DataExchangeStatesImport
	|		ON (DataExchangeStatesImport.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN DataExchangeStatesExport AS DataExchangeStatesExport
	|		ON (DataExchangeStatesExport.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN SuccessfulDataExchangeStatesImport AS SuccessfulDataExchangeStatesImport
	|		ON (SuccessfulDataExchangeStatesImport.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN SuccessfulDataExchangeStatesExport AS SuccessfulDataExchangeStatesExport
	|		ON (SuccessfulDataExchangeStatesExport.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN DataSynchronizationScenarios AS DataSynchronizationScenarios
	|		ON (DataSynchronizationScenarios.InfobaseNode = ExchangePlans.InfobaseNode)
	|		LEFT JOIN MessagesForDataMapping AS MessagesForDataMapping
	|		ON MessagesForDataMapping.InfobaseNode = ExchangePlans.InfobaseNode
	|
	|ORDER BY
	|	ExchangePlans.Description");
	
	Query.Text = StrReplace(Query.Text, "[ExchangePlanAdditionalProperties]",
		AdditionalExchangePlanPropertiesAsString(ExchangePlanAdditionalProperties));
		
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	GetExchangePlansForMonitor(TempTablesManager, ExchangePlans, ExchangePlanAdditionalProperties);
	GetExchangeResultsForMonitor(TempTablesManager);
	GetDataExchangesStates(TempTablesManager);
	GetMessagesToMapData(TempTablesManager);
	GetCommonInfobasesNodesSettings(TempTablesManager);
	
	SynchronizationSettings = Query.Execute().Unload();
	
	SynchronizationSettings.Columns.Add("DataExchangeOption", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("ExchangePlanName",       New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastRunDate", New TypeDescription("Date"));
	SynchronizationSettings.Columns.Add("LastStartDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastImportDatePresentation", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("LastExportDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastSuccessfulImportDatePresentation", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("LastSuccessfulExportDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("MessageDatePresentationForDataMapping", New TypeDescription("String"));
	
	For Each SyncSetup In SynchronizationSettings Do
		
		SyncSetup.LastRunDate = Max(SyncSetup.LastImportStartDate,
			SyncSetup.LastExportStartDate);
		SyncSetup.LastStartDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastRunDate);
		
		SyncSetup.LastImportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastImportEndDate);
		SyncSetup.LastExportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastExportEndDate);
		SyncSetup.LastSuccessfulImportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastSuccessfulExportEndDate);
		SyncSetup.LastSuccessfulExportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastSuccessfulImportEndDate);
		
		SyncSetup.MessageDatePresentationForDataMapping = RelativeSynchronizationDate(
			ToLocalTime(SyncSetup.DataMapMessageDate));
		
		SyncSetup.DataExchangeOption = DataExchangeOption(SyncSetup.InfobaseNode);
		SyncSetup.ExchangePlanName = DataExchangeCached.GetExchangePlanName(SyncSetup.InfobaseNode);
		
	EndDo;
	
	Return SynchronizationSettings;
	
EndFunction

Procedure CheckCanSynchronizeData(OnlineApplication = False) Export
	
	If Not AccessRight("View", Metadata.CommonCommands.Synchronize) Then
		
		If OnlineApplication Then
			Raise NStr("ru = 'Недостаточно прав для синхронизации данных с приложением в Интернете.'; en = 'Insufficient rights to synchronize data with the web application.'; pl = 'Nie wystarczające uprawnienia dla synchronizacji danych z aplikacją w Internecie.';de = 'Unzureichende Rechte zur Synchronisation von Daten mit der Anwendung im Internet.';ro = 'Drepturi insuficiente pentru sincronizarea datelor cu aplicația în Internet.';tr = 'Verilerin İnternet''teki uygulama ile eşleşmesi için olan haklar yetersizdir.'; es_ES = 'Insuficientes derechos para sincronizar los datos de aplicación en Internet.'");
		Else
			Raise NStr("ru = 'Недостаточно прав для синхронизации данных.'; en = 'Insufficient rights to synchronize data.'; pl = 'Niewystarczające uprawnienia do synchronizacji danych.';de = 'Unzureichende Rechte für die Datensynchronisierung.';ro = 'Drepturi insuficiente pentru sincronizarea datelor.';tr = 'Veri senkronizasyonu için yetersiz haklar.'; es_ES = 'Insuficientes derechos para sincronizar los datos.'");
		EndIf;
		
	ElsIf InfobaseUpdate.InfobaseUpdateRequired()
	        AND Not DataExchangeInternal.DataExchangeMessageImportModeBeforeStart("ImportPermitted") Then
		
		If OnlineApplication Then	
			Raise NStr("ru = 'Приложение в Интернете находится в состоянии обновления.'; en = 'Web application update is pending.'; pl = 'Aplikacja w Internecie znajduje się w statusie aktualizacji.';de = 'Die Internetanwendung wird derzeit aktualisiert.';ro = 'Aplicația din Internet este în curs de actualizare.';tr = 'İnternetteki uygulama güncelleniyor.'; es_ES = 'La aplicación en Internet se encuentra en el estado de actualización.'");
		Else
			Raise NStr("ru = 'Информационная база находится в состоянии обновления.'; en = 'Infobase update is pending.'; pl = 'Baza informacyjna została zaktualizowana.';de = 'Infobase wird aktualisiert.';ro = 'Baza de informații este în curs de actualizare.';tr = 'Veritabanı güncelleniyor.'; es_ES = 'Infobase se está actualizando.'");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckDataExchangeUsage(SetUsing = False) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		If Not Common.DataSeparationEnabled()
			AND SetUsing
			AND AccessRight("Edit", Metadata.Constants.UseDataSynchronization) Then
			
			Try
				Constants.UseDataSynchronization.Set(True);
			Except
				MessageText = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(EventLogMessageTextDataExchange(), EventLogLevel.Error,,,MessageText);
				Raise MessageText;
			EndTry;
			
		Else
			MessageText = NStr("ru = 'Синхронизация данных запрещена администратором.'; en = 'The synchronization is prohibited by administrator.'; pl = 'Synchronizacja danych została zabroniona przez administratora.';de = 'Die Datensynchronisierung ist vom Administrator untersagt.';ro = 'Sincronizarea datelor este interzisă de administrator.';tr = 'Veri senkronizasyonu yönetici tarafından yasaklanmıştır.'; es_ES = 'Sincronicazación de datos está prohibida por el administrador.'");
			WriteLogEvent(EventLogMessageTextDataExchange(), EventLogLevel.Error,,,MessageText);
			Raise MessageText;
		EndIf;
		
	EndIf;
	
EndProcedure

Function ExchangeParameters() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("ExchangeMessagesTransportKind", Undefined);
	ParametersStructure.Insert("ExecuteImport", True);
	ParametersStructure.Insert("ExecuteExport", True);
	
	ParametersStructure.Insert("ParametersOnly",     False);
	
	ParametersStructure.Insert("TimeConsumingOperationAllowed", False);
	ParametersStructure.Insert("TimeConsumingOperation", False);
	ParametersStructure.Insert("OperationID", "");
	ParametersStructure.Insert("FileID", "");
	ParametersStructure.Insert("AuthenticationParameters", Undefined);
	
	ParametersStructure.Insert("MessageForDataMapping", False);
	
	Return ParametersStructure;
	
EndFunction

// An entry point to iterate data exchange, that is export and import data for the exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which data exchange iteration is being executed.
//  ExchangeParametersForNode - Structure - contains the following parameters:
//    * PerformImport - Boolean - indicates whether data export is required.
//        Optional, the default value is True.
//    * PerformExport - Boolean - indicates whether data export is required.
//        Optional, the default value is True.
//    * ExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportKinds - a transport kind to 
//        use in the data exchange.
//        If the value is not set in the information register, then the default value is Enums.ExchangeMessageTransportKinds.FILE.
//        Optional, the default value is Undefined.
//    * TimeConsumingOperation - Boolean - indicates whether it is a time-consuming operation.
//        Optional, the default value is False.
//    * ActionID - String - contains a time-consuming operation ID as a string.
//        Optional, default value is an empty string.
//    * FileID - String - message file ID in the service.
//        Optional, default value is an empty string.
//    * TimeConsumingOperationAllowed - Boolean - indicates whether time-consuming operation is allowed.
//        Optional, the default value is False.
//    * AuthenticationParameters - Structure - contains authentication parameters for exchange via Web service.
//        Optional, the default value is Undefined.
//    * ParametersOnly - Boolean - indicates whether data is imported selectively on DIB exchange.
//        Optional, the default value is False.
//  Cancel - Boolean - a cancel flag, appears if errors occur on data exchange.
//  AdditionalParameters - Structure - reserved for internal use.
// 
Procedure ExecuteDataExchangeForInfobaseNode(InfobaseNode,
		ExchangeParameters, Cancel, AdditionalParameters = Undefined) Export
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
		
	ActionImport = Enums.ActionsOnExchange.DataImport;
	ActionExport = Enums.ActionsOnExchange.DataExport;
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	// Exchanging data through external connection.
	If ExchangeParameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		CheckExternalConnectionAvailable();
		
		If ExchangeParameters.ExecuteImport Then
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel,
				InfobaseNode, ActionImport, Undefined);
		EndIf;
		
		If ExchangeParameters.ExecuteExport Then
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel,
				InfobaseNode, ActionExport, Undefined, ExchangeParameters.MessageForDataMapping);
		EndIf;
		
	ElsIf ExchangeParameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then // Exchanging data through web service.
		
		If ExchangeParameters.ExecuteImport Then
			ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
				InfobaseNode, ActionImport, ExchangeParameters);
		EndIf;
		
		If ExchangeParameters.ExecuteExport Then
			ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
				InfobaseNode, ActionExport, ExchangeParameters);
		EndIf;
			
	Else // Exchanging data through ordinary channels.
		
		ParametersOnly = ExchangeParameters.ParametersOnly;
		ExchangeMessagesTransportKind = ExchangeParameters.ExchangeMessagesTransportKind;
		
		If ExchangeParameters.ExecuteImport Then
			ExecuteExchangeActionForInfobaseNode(Cancel, InfobaseNode,
				ActionImport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
		EndIf;
		
		If ExchangeParameters.ExecuteExport Then
			ExecuteExchangeActionForInfobaseNode(Cancel, InfobaseNode,
				ActionExport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

Function GetWSProxyByConnectionParameters(
					SettingsStructure,
					ErrorMessageString = "",
					UserMessage = "",
					ProbingCallRequired = False) Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(SettingsStructure.WSWebServiceURL);
	Except
		UserMessage = BriefErrorDescription(ErrorInfo());
		ErrorMessageString = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventLogEventEstablishWebServiceConnection(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUserName(SettingsStructure.WSUsername);
	Except
		UserMessage = BriefErrorDescription(ErrorInfo());
		ErrorMessageString = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventLogEventEstablishWebServiceConnection(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", SettingsStructure.WSWebServiceURL);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    SettingsStructure.WSServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = WSDLLocation;
	ConnectionParameters.NamespaceURI = SettingsStructure.WSServiceNamespaceURL;
	ConnectionParameters.ServiceName = SettingsStructure.WSServiceName;
	ConnectionParameters.UserName = SettingsStructure.WSUsername; 
	ConnectionParameters.Password = SettingsStructure.WSPassword;
	ConnectionParameters.Timeout = SettingsStructure.WSTimeout;
	ConnectionParameters.ProbingCallRequired = ProbingCallRequired;
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = BriefErrorDescription(ErrorInfo());
		ErrorMessageString = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventLogEventEstablishWebServiceConnection(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
EndFunction

// Deletes data synchronization setting.
// 
// Parameters:
//   InfobaseNode - ExchangePlanRef - a reference to the exchange plan node to be deleted.
// 
Procedure DeleteSynchronizationSetting(InfobaseNode) Export
	
	CheckExchangeManagementRights();
	
	NodeObject = InfobaseNode.GetObject();
	If NodeObject = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(InfobaseNode);
	NodeObject.Delete();
	
EndProcedure

// Deletes setting of data synchronization with master DIB node.
// 
// Parameters:
//   InfobaseNode - ExchangePlanRef - a reference to the master node.
// 
Procedure DeleteSynchronizationSettingsForMasterDIBNode(InfobaseNode) Export
	
	DeleteSynchronizationSetting(InfobaseNode);
	
	SubordinateDIBNodeSetupCompleted = Constants.SubordinateDIBNodeSetupCompleted.CreateValueManager();
	SubordinateDIBNodeSetupCompleted.Read();
	If SubordinateDIBNodeSetupCompleted.Value Then
		SubordinateDIBNodeSetupCompleted.Value = False;
		InfobaseUpdate.WriteData(SubordinateDIBNodeSetupCompleted);
	EndIf;
	
EndProcedure

// Sets the Load parameter value for the DataExchange object property.
//
// Parameters:
//  Object - Any object - an object whose property is being set.
//  Value - Boolean - a value of the Import property being set.
//  SendBack - Boolean - shows that data must be registered to send it back.
//  ExchangeNode - ExchangePlanRef - shows that data must be registered to send it back.
//
Procedure SetDataExchangeLoad(Object, Value = True, SendBack = False, ExchangeNode = Undefined) Export
	
	Object.DataExchange.Load = Value;
	
	If Not SendBack
		AND ExchangeNode <> Undefined
		AND NOT ExchangeNode.IsEmpty() Then
	
		ObjectValueType = TypeOf(Object);
		MetadataObject = Metadata.FindByType(ObjectValueType);
		
		If Metadata.ExchangePlans[ExchangeNode.Metadata().Name].Content.Contains(MetadataObject) Then
			Object.DataExchange.Sender = ExchangeNode;
		EndIf;
	
	EndIf;
	
EndProcedure

Function ExchangePlanPurpose(ExchangePlanName) Export
	
	Return DataExchangeCached.ExchangePlanPurpose(ExchangePlanName);
	
EndFunction

// Procedure of deleting existing document register records upon reposting (posting cancellation).
//
// Parameters:
//   DocumentObject - DocumentObject - a document whose register records must be deleted.
//
Procedure DeleteDocumentRegisterRecords(DocumentObject) Export
	
	RecordTableRowToProcessArray = New Array();
	
	// Getting a list of registers with existing records.
	RegisterRecordTable = GetDocumentHasRegisterRecords(DocumentObject.Ref);
	RegisterRecordTable.Columns.Add("RecordSet");
	RegisterRecordTable.Columns.Add("ForceDelete", New TypeDescription("Boolean"));
		
	For Each RegisterRecordRow In RegisterRecordTable Do
		// The register name is passed as a value received using the FullName() function of register 
		// metadata.
		PointPosition = StrFind(RegisterRecordRow.Name, ".");
		TypeRegister = Left(RegisterRecordRow.Name, PointPosition - 1);
		RegisterName = TrimR(Mid(RegisterRecordRow.Name, PointPosition + 1));

		RecordTableRowToProcessArray.Add(RegisterRecordRow);
		
		If TypeRegister = "AccumulationRegister" Then
			Set = AccumulationRegisters[RegisterName].CreateRecordSet();
		ElsIf TypeRegister = "AccountingRegister" Then
			Set = AccountingRegisters[RegisterName].CreateRecordSet();
		ElsIf TypeRegister = "InformationRegister" Then
			Set = InformationRegisters[RegisterName].CreateRecordSet();
		ElsIf TypeRegister = "CalculationRegister" Then
			Set = CalculationRegisters[RegisterName].CreateRecordSet();
		EndIf;
		
		If Not AccessRight("Update", Set.Metadata()) Then
			// Insufficient access rights for the entire register table.
			ExceptionText = NStr("ru = 'Нарушение прав доступа: %1'; en = 'Access rights violation: %1.'; pl = 'Naruszenia praw dostępu: %1';de = 'Zugriffsrechtsverletzung: %1';ro = 'Încălcarea drepturilor de acces: %1';tr = 'Erişim haklarının ihlali: %1'; es_ES = 'Violación del derecho de acceso: %1'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, RegisterRecordRow.Name);
			Raise ExceptionText;
		EndIf;

		Set.Filter.Recorder.Set(DocumentObject.Ref);

		// The set is not recorded immediately so that not to roll back the transaction if it turns out 
		// later that user does not have sufficient rights to one of the registers.
		RegisterRecordRow.RecordSet = Set;
		
	EndDo;
	
	SkipPeriodClosingCheck();
	
	For Each RegisterRecordRow In RecordTableRowToProcessArray Do		
		Try
			RegisterRecordRow.RecordSet.Write();
		Except
			// It is possible that the restriction at the record level or the period-end closing date subsystem has activated.
			ExceptionText = NStr("ru = 'Операция не выполнена: %1
				|%2'; 
				|en = 'Operation failed: %1
				|%2'; 
				|pl = 'Operacja nie jest wykonana: %1
				|%2';
				|de = 'Der Vorgang wurde nicht durchgeführt: %1
				|%2';
				|ro = 'Operația nu este executată: %1
				|%2';
				|tr = 'İşlem yapılamadı: %1
				|%2'; 
				|es_ES = 'Operación no realizada: %1
				|%2'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, RegisterRecordRow.Name, BriefErrorDescription(ErrorInfo()));
			Raise ExceptionText;
		EndTry;
	EndDo;
	
	SkipPeriodClosingCheck(False);
	
	For Each RegisterRecord In DocumentObject.RegisterRecords Do
		If RegisterRecord.Count() > 0 Then
			RegisterRecord.Clear();
		EndIf;
	EndDo;
	
	// Deleting registration records from all sequences.
	If DocumentObject.Metadata().SequenceFilling = Metadata.ObjectProperties.SequenceFilling.AutoFill Then
		QueryText = "";
		
		For Each Sequence In DocumentObject.BelongingToSequences Do
			// In the query, getting names of the sequences where the document is registered.
			QueryText = QueryText + "
			|" + ?(QueryText = "", "", "UNION ALL ") + "
			|SELECT """ + Sequence.Metadata().Name
			+  """ AS Name FROM " + Sequence.Metadata().FullName()
			+ " WHERE Recorder = &Recorder";
			
		EndDo;
		
		If QueryText = "" Then
			RecordChangeTable = New ValueTable();
		Else
			Query = New Query(QueryText);
			Query.SetParameter("Recorder", DocumentObject.Ref);
			RecordChangeTable = Query.Execute().Unload();
		EndIf;
		
		// Getting the list of the sequences where the document is registered.
		SequenceCollection = DocumentObject.BelongingToSequences;
		For Each SequenceRecordRecordSet In SequenceCollection Do
			If (SequenceRecordRecordSet.Count() > 0)
				OR (NOT RecordChangeTable.Find(SequenceRecordRecordSet.Metadata().Name,"Name") = Undefined) Then
				SequenceRecordRecordSet.Clear();
			EndIf;
		EndDo;
	EndIf;

EndProcedure

// Indicates whether it is necessary to import data exchange message.
//
// Returns:
//   Boolean - if True, the message is to be imported. Otherwise, False.
//
Function LoadDataExchangeMessage() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.LoadDataExchangeMessage.Get();
	
EndFunction

// Intended for moving passwords to a secure storage.
// This procedure is used in the infobase update handler.
Procedure MovePasswordsToSecureStorage() Export
	
	Query = New Query(
	"SELECT
	|	TransportSettings.InfobaseNode,
	|	TransportSettings.DeleteCOMUserPassword,
	|	TransportSettings.DeleteFTPConnectionPassword,
	|	TransportSettings.DeleteWSPassword,
	|	TransportSettings.DeleteExchangeMessageArchivePassword
	|FROM
	|	InformationRegister.DeleteExchangeTransportSettings AS TransportSettings");
	
	QueryResult = Query.Execute().Select();
	While QueryResult.Next() Do
		If Not IsBlankString(QueryResult.DeleteCOMUserPassword)
			Or Not IsBlankString(QueryResult.DeleteFTPConnectionPassword)
			Or Not IsBlankString(QueryResult.DeleteWSPassword) 
			Or Not IsBlankString(QueryResult.DeleteExchangeMessageArchivePassword) Then
			BeginTransaction();
			Try
				SetPrivilegedMode(True);
				Common.WriteDataToSecureStorage(QueryResult.InfobaseNode, QueryResult.DeleteCOMUserPassword, "COMUserPassword");
				Common.WriteDataToSecureStorage(QueryResult.InfobaseNode, QueryResult.DeleteFTPConnectionPassword, "FTPConnectionPassword");
				Common.WriteDataToSecureStorage(QueryResult.InfobaseNode, QueryResult.DeleteWSPassword, "WSPassword");
				Common.WriteDataToSecureStorage(QueryResult.InfobaseNode, QueryResult.DeleteExchangeMessageArchivePassword, "ExchangeMessageArchivePassword");
				SetPrivilegedMode(False);
				
				RecordStructure = New Structure("InfobaseNode", QueryResult.InfobaseNode);
				RecordStructure.Insert("DeleteCOMUserPassword", "");
				RecordStructure.Insert("DeleteFTPConnectionPassword", "");
				RecordStructure.Insert("DeleteWSPassword", "");
				RecordStructure.Insert("DeleteExchangeMessageArchivePassword", "");
				
				UpdateInformationRegisterRecord(RecordStructure, "DeleteExchangeTransportSettings");
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ErrorMessageString = DetailErrorDescription(ErrorInfo());
				WriteLogEvent(EventLogMessageTextDataExchange(), EventLogLevel.Error,,, ErrorMessageString);
			EndTry;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "DataExchangeServer.SetPredefinedNodeCodes";
	Handler.ExecutionMode = "Seamless";

	Handler = Handlers.Add();
	Handler.Version = "1.1.1.2";
	Handler.Procedure = "DataExchangeServer.SetMappingDataAdjustmentRequiredForAllInfobaseNodes";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.1.2";
	Handler.Procedure = "DataExchangeServer.SetExportModeForAllInfobaseNodes";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.1.2";
	Handler.SharedData = True;
	Handler.Procedure = "DataExchangeServer.UpdateDataExchangeScenarioScheduledJobs";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.0";
	Handler.Procedure = "DataExchangeServer.UpdateSubordinateDIBNodeSetupCompletedConstant";
	
	Handler = Handlers.Add();
	Handler.Version = "2.0.1.10";
	Handler.SharedData = True;
	Handler.Procedure = "DataExchangeServer.CheckFunctionalOptionsAreSetOnUpdateIB";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.1.5";
	Handler.SharedData = True;
	Handler.Procedure = "DataExchangeServer.SetExchangePasswordSaveOverInternetFlag";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.2.12";
	Handler.Procedure = "DataExchangeServer.ClearExchangeMonitorSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.2.21";
	Handler.SharedData = True;
	Handler.Procedure = "DataExchangeServer.CheckFunctionalOptionsAreSetOnUpdateIB_2_1_2_21";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.2.4";
	Handler.SharedData = True;
	Handler.Procedure = "DataExchangeServer.SetItemCountForDataImportTransaction_2_2_2_4";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "DataExchangeServer.DeleteDataSynchronizationSetupRole";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.91";
	Handler.Comment =
		NStr("ru = 'Перенос настроек подключения обменов данными в новый регистр ""Настройки транспорта обмена данными"".'; en = 'Moves data exchange connection settings to the new register ""Data exchange transport settings.""'; pl = 'Przeniesienie ustawień podłączenia wymian danych do nowego rejestru ""Настройки транспорта обмена данными"".';de = 'Übertragung der Datenaustausch-Verbindungseinstellungen in das neue Register ""Datenaustausch-Transporteinstellungen"".';ro = 'Transferul setărilor de conectare a schimburilor de date în registrul nou ""Setările transportului schimbului de date"".';tr = 'Veri alışverişi bağlantı ayarlarını yeni ""Veri alışverişi aktarım ayarları"" kaydına aktarma.'; es_ES = 'El traslado de los ajustes de conexión de intercambios de datos al registro nuevo ""Ajustes del transporte de intercambio de datos"".'");
	Handler.ID = New UUID("8d5f1092-f569-4c03-aca9-65625809b853");
	Handler.Procedure = "InformationRegisters.DeleteExchangeTransportSettings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead = "InformationRegister.DeleteExchangeTransportSettings";
	Handler.ObjectsToChange = "InformationRegister.DeleteExchangeTransportSettings,InformationRegister.DataExchangeTransportSettings";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DeleteExchangeTransportSettings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.DeleteExchangeTransportSettings,InformationRegister.DataExchangeTransportSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.281";
	Handler.Comment =
		NStr("ru = 'Заполнение вспомогательных настроек обмена данными в регистре ""Общие настройки узлов информационных баз"".'; en = 'Fills in auxiliary data exchange settings in the ""Common infobase node settings"" register.'; pl = 'Wypełnienie ustawień pomocniczych  wymiany danych w rejestrze ""Общие настройки узлов информационных баз"".';de = 'Ausfüllen der zusätzlichen Datenaustausch-Einstellungen im Register ""Allgemeine Einstellungen der Informationsbasisknoten"".';ro = 'Completarea setărilor auxiliare ale schimbului de date în registrul ""Setările generale ale nodurilor bazelor de informații"".';tr = '""Genel veri tabanı ünite ayarları"" kayıtlarında veri alışverişi destek ayarlarını doldur.'; es_ES = 'Relleno de los ajustes auxiliares del intercambio de datos en el registro ""Ajustes comunes de los nodos de la base de información"".'");
	Handler.ID = New UUID("e1cd64f1-3df9-4ea6-8076-1ba0627ba104");
	Handler.Procedure = "InformationRegisters.CommonInfobasesNodesSettings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead = "InformationRegister.CommonInfobasesNodesSettings";
	Handler.ObjectsToChange = "InformationRegister.CommonInfobasesNodesSettings";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.CommonInfobasesNodesSettings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.CommonInfobasesNodesSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.91";
	Handler.Comment =
		NStr("ru = 'Первоначальное заполнение настроек обмена данными XDTO.'; en = 'Performs initial filling of XDTO data exchange settings.'; pl = 'Początkowe wypełnienie ustawień  wymiany danych XDTO.';de = 'Erstmaliges Ausfüllen der XDTO-Kommunikationseinstellungen.';ro = 'Completarea inițială a setărilor schimbului de date XDTO.';tr = 'XDTO veri alışverişi ayarlarını ilk doldurma.'; es_ES = 'Relleno inicial de los ajustes de intercambio de datos XDTO.'");
	Handler.ID = New UUID("2ea5ec7e-547b-4e8b-9c3f-d2d8652c8cdf");
	Handler.Procedure = "InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead = "InformationRegister.XDTODataExchangeSettings";
	Handler.ObjectsToChange = "InformationRegister.XDTODataExchangeSettings";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.XDTODataExchangeSettings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.XDTODataExchangeSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.207";
	Handler.Comment =
		NStr("ru = 'Перенос результатов выполнения обменов данными в новый регистр.'; en = 'Moves data exchange results to a new register.'; pl = 'Przeniesienie wyników wymiany danych do nowego rejestru.';de = 'Übertragung der Datenaustauschergebnisse in ein neues Register.';ro = 'Transferul rezultatelor de executare a schimburilor de date în registrul nou.';tr = 'Veri alışverişi yerine getirme sonuçlarını yeni kayıt defterine taşıma.'; es_ES = 'El traslado de los resultados de realizar los intercambios de datos al registro nuevo.'");
	Handler.ID = New UUID("012c28d7-bbe8-494f-87f7-620ffe5c99e2");
	Handler.Procedure = "InformationRegisters.DeleteDataExchangeResults.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToBeRead = "InformationRegister.DeleteDataExchangeResults";
	Handler.ObjectsToChange = "InformationRegister.DeleteDataExchangeResults,InformationRegister.DataExchangeResults";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DeleteDataExchangeResults.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.DeleteDataExchangeResults,InformationRegister.DataExchangeResults";
	
EndProcedure

// See InfobaseUpdateSSL.InfobaseBeforeUpdate. 
Procedure BeforeUpdateInfobase(OnClientStart, Restart) Export
	
	If Common.DataSeparationEnabled() Then
		Return;	
	EndIf;
	
	If NOT InfobaseUpdate.InfobaseUpdateRequired() Then
		ExecuteSynchronizationWhenInfobaseUpdateAbsent(OnClientStart, Restart);
	Else	
		ImportMessageBeforeInfobaseUpdate();
	EndIf;

EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase. 
Procedure AfterUpdateInfobase() Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	InformationRegisters.DataSyncEventHandlers.RegisterInfobaseDataUpdate();
	
	ExportMessageAfterInfobaseUpdate();
	
EndProcedure	

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.DataExchangeScenarios.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See SaaSOverridable.OnEnableDataSeparation. 
Procedure OnEnableSeparationByDataAreas() Export
	
	If NOT GetFunctionalOption("UseDataSynchronization") Then
		Constants.UseDataSynchronization.Set(True);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("DataExchangeMessageImportModeBeforeStart", "DataExchangeInternal.SessionParametersSetting");
	
	Handlers.Insert("ORMCachedValuesRefreshDate",    "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("SelectiveObjectsRegistrationRules",             "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("ObjectsRegistrationRules",                       "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("DataSynchronizationPasswords",                        "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("PriorityExchangeData",                         "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("VersionMismatchErrorOnGetData",        "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("DataSynchronizationSessionParameters",               "DataExchangeInternal.SessionParametersSetting");
EndProcedure

// See CommonOverridable.OnDefineSupportedAPIVersions. 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("2.0.1.6");
	VersionsArray.Add("2.1.1.7");
	VersionsArray.Add("3.0.1.1");
	SupportedVersionsStructure.Insert("DataExchange", VersionsArray);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("DIBExchangePlanName", ?(IsSubordinateDIBNode(), MasterNode().Metadata().Name, ""));
	Parameters.Insert("MasterNode", MasterNode());
	
	If OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
		
		If Common.SubsystemExists("StandardSubsystems.Interactions") Then
			ModuleInteractions = Common.CommonModule("Interactions");
			ModuleInteractions.PerformCompleteStatesRecalculation();
		EndIf;
		
		Parameters.Insert("OpenDataExchangeCreationWizardForSubordinateNodeSetup");
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	If Parameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup") Then
		
		ThisNode = ExchangePlans[Parameters.DIBExchangePlanName].ThisNode();
		Parameters.Insert("DIBNodeSettingID", SavedExchangePlanNodeSettingOption(ThisNode));
		
	EndIf;
	
	If Not Parameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup")
		AND AccessRight("View", Metadata.CommonCommands.Synchronize) Then
		
		Parameters.Insert("CheckSubordinateNodeConfigurationUpdateRequired");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("MasterNode", MasterNode());
	
EndProcedure

// See AccessManagementOverridable.OnFillSuppliedAccessGroupsProfiles. 
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, UpdateParameters) Export
	
	// "Data synchronization with other applications" profile.
	ProfileDetails = Common.CommonModule("AccessManagement").NewAccessGroupProfileDescription();
	ProfileDetails.ID = DataSynchronizationWithOtherApplicationsAccessProfile();
	ProfileDetails.Description =
		NStr("ru = 'Синхронизация данных с другими программами'; en = 'Synchronize data with other applications'; pl = 'Synchronizacja danych z innymi aplikacjami';de = 'Datensynchronisierung mit anderen Anwendungen';ro = 'Sincronizarea datelor cu alte programe';tr = 'Diğer uygulamalarla veri senkronizasyonu'; es_ES = 'Sincronización de datos con otras aplicaciones'", Metadata.DefaultLanguage.LanguageCode);
	ProfileDetails.Details =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должны быть доступны средства
		           |для мониторинга и синхронизации данных с другими программами.'; 
		           |en = 'The profile is assigned to users that are allowed
		           |to synchronize data with other applications and monitor the synchronization.'; 
		           |pl = 'Jest dodatkowo wyznaczana dla tych użytkowników, dla których powinny być dostępne środki
		           |do monitoringu i synchronizacji danych z innymi programami.';
		           |de = 'Darüber hinaus ist es denjenigen Benutzern zugeordnet, die Zugriff auf die Tools
		           |zur Überwachung und Synchronisation von Daten mit anderen Programmen haben sollen.';
		           |ro = 'Se atribuie suplimentar acelor utilizatori care au acces la instrumentele
		           |de monitorizare și sincronizare a datelor cu alte aplicații.';
		           |tr = 'Diğer uygulamalarla izleme ve veri senkronizasyonu için 
		           |araçlara erişimi olan kullanıcılara ek olarak atandı.'; 
		           |es_ES = 'Se establece adicionalmente para los usuarios a los que deben estar disponibles las propiedades
		           | de controlar y sincronizar los datos con otros programas.'",
			Metadata.DefaultLanguage.LanguageCode);
	
	// Basic profile features.
	ProfileRoles = StrSplit(DataSynchronizationAccessProfileWithOtherApplicationsRoles(), ",");
	For Each Role In ProfileRoles Do
		ProfileDetails.Roles.Add(TrimAll(Role));
	EndDo;
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	OnFillToDoListSynchronizationWarnings(ToDoList);
	OnFillToDoListUpdateRequired(ToDoList);
	OnFillToDoListValidateCompatibilityWithCurrentVersion(ToDoList);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.ObsoleteSynchronizationDataDeletion;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseDataSynchronization;
	Dependence.UseExternalResources = True;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.DataSynchronization;
	Dependence.UseExternalResources = True;
	Dependence.IsParameterized = True;
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(
		Total, "2.1.2.5", "Role.ExecuteDataExchange", "Role.DataSynchronizationInProgress", Library);
	
EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(Array) Export
	
	Array.Add(Metadata.InformationRegisters.DataExchangeResults.FullName());
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If NOT GetFunctionalOption("UseDataSynchronization") Then
		Return;
	EndIf;
	
	CreateRequestsToUseExternalResources(PermissionsRequests);
	
EndProcedure

// See SubsystemIntegrationSSL.ExternalModuleManagersOnRegistration. 
Procedure OnRegisterExternalModulesManagers(Managers) Export
	
	Managers.Add(DataExchangeServer);
	
EndProcedure


Procedure SetPredefinedNodeCodes() Export
	BeginTransaction();
	
	Try
		
		CodeFromSaaSMode = "";
		VirtualCodes = InformationRegisters.PredefinedNodesAliases.CreateRecordSet();
		
		If Common.DataSeparationEnabled()
			AND Common.SeparatedDataUsageAvailable()
			AND Common.SubsystemExists("StandardSubsystems.SaaS") Then
			
			ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
			ModuleSaaS = Common.CommonModule("SaaS");
			
			CodeFromSaaSMode = TrimAll(ModuleDataExchangeSaaS.ExchangePlanNodeCodeInService(ModuleSaaS.SessionSeparatorValue()));
			
		EndIf;
		
		For Each NodeRef In PredefinedNodesOfSSLExchangePlans() Do
			
			If Not IsXDTOExchangePlan(NodeRef) Then
				Continue;
			ElsIf Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(NodeRef) Then
				Continue;
			EndIf;
			
			PredefinedNodeCode = TrimAll(Common.ObjectAttributeValue(NodeRef, "Code"));
			If Not ValueIsFilled(PredefinedNodeCode)
				// Migration to a new node encoding was not carried out.
				Or StrLen(PredefinedNodeCode) < 36
				// Re-encoding is required because the code is generated using STL logic.
				Or PredefinedNodeCode = CodeFromSaaSMode Then
				
				DataExchangeUUID = String(New UUID);
				
				ObjectNode = NodeRef.GetObject();
				ObjectNode.Code = DataExchangeUUID;
				ObjectNode.DataExchange.Load = True;
				ObjectNode.Write();
				
				If ValueIsFilled(PredefinedNodeCode) Then
					// Saving the previous node code to the register of virtual codes.
					QueryText = 
					"SELECT
					|	T.Ref AS Ref
					|FROM
					|	#ExchangePlanTable AS T
					|WHERE
					|	NOT T.ThisNode
					|	AND NOT T.DeletionMark";
					
					QueryText = StrReplace(QueryText,
						"#ExchangePlanTable", "ExchangePlan." + DataExchangeCached.GetExchangePlanName(NodeRef));
					
					Query = New Query(QueryText);
					
					ExchangePlanCorrespondents = Query.Execute().Select();
					While ExchangePlanCorrespondents.Next() Do
						VirtualCode = VirtualCodes.Add();
						VirtualCode.Correspondent = ExchangePlanCorrespondents.Ref;
						VirtualCode.NodeCode       = PredefinedNodeCode;
					EndDo;
				EndIf;
				
			EndIf;
		EndDo;
		
		If VirtualCodes.Count() > 0 Then
			VirtualCodes.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlersAliases. 
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
	NameAndAliasMap.Insert("DataExchangeServer.ExecuteDataExchangeWithExternalSystem");
	
EndProcedure


#EndRegion

#EndRegion

#Region Private

Function ModuleDataSynchronizationBetweenWebApplicationsSetupWizard() Export
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		Return Common.CommonModule("DataProcessors.DataSynchronizationBetweenWebApplicationsSetupWizard");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ModuleInteractiveDataExchangeWizardInSaaS() Export
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		Return Common.CommonModule("DataProcessors.InteractiveDataExchangeWizardSaaS");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ModuleDataExchangeCreationWizard() Export
	
	Return Common.CommonModule("DataProcessors.DataExchangeCreationWizard");
	
EndFunction

Function ModuleInteractiveDataExchangeWizard() Export
	
	Return Common.CommonModule("DataProcessors.InteractiveDataExchangeWizard");
	
EndFunction

Function MessageWithDataForMappingReceived(ExchangeNode) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	MessagesForDataMapping.EmailReceivedForDataMapping AS EmailReceivedForDataMapping
	|FROM
	|	#ExchangePlanTable AS ExchangePlanTable
	|		INNER JOIN MessagesForDataMapping AS MessagesForDataMapping
	|		ON (MessagesForDataMapping.InfobaseNode = ExchangePlanTable.Ref)
	|WHERE
	|	ExchangePlanTable.Ref = &ExchangeNode");
	Query.SetParameter("ExchangeNode", ExchangeNode);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTable", "ExchangePlan." + DataExchangeCached.GetExchangePlanName(ExchangeNode));
	
	GetMessagesToMapData(Query.TempTablesManager);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.EmailReceivedForDataMapping;
	EndIf;
	
	Return False;
	
EndFunction

Function PredefinedNodesOfSSLExchangePlans()
	
	Result = New Array;
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		Result.Add(ExchangePlans[ExchangePlanName].ThisNode());
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SkipPeriodClosingCheck(Ignore = True) Export
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternal = Common.CommonModule("PeriodClosingDatesInternal");
		ModulePeriodClosingDatesInternal.SkipPeriodClosingCheck(Ignore);
	EndIf;
	
EndProcedure

Procedure OnContinueSubordinateDIBNodeSetup() Export
	
	SSLSubsystemsIntegration.OnSetUpSubordinateDIBNode();
	DataExchangeOverridable.OnSetUpSubordinateDIBNode();
	
EndProcedure

Procedure CheckProhibitedCharsInWSProxyUserName(Val Username)
	
	InvalidChars = ProhibitedCharsInWSProxyUserName();
	
	If StringContainsCharacter(Username, InvalidChars) Then
		
		MessageString = NStr("ru = 'В имени пользователя %1 содержатся недопустимые символы.
			|Имя пользователя не должно содержать символы %2.'; 
			|en = 'Username %1 contains prohibited characters:
			|%2'; 
			|pl = '%1Nazwa użytkownika zawiera nieprawidłowe znaki.
			|Nazwa użytkownika nie może zawierać %2 symboli.';
			|de = 'Der %1 Benutzername enthält ungültige Zeichen. Der 
			| Benutzername darf keine %2Symbole enthalten.';
			|ro = 'Numele utilizatorului %1 conține simboluri inadmisibile.
			|Numele utilizatorului nu trebuie să conțină simboluri %2.';
			|tr = 'Kullanıcı adı %1 geçersiz karakterler içeriyor. 
			|Kullanıcı adı %2.sembol içermemelidir.'; 
			|es_ES = 'El %1 nombre de usuario contiene símbolos inválidos.
			|Nombre de usuario no tiene que contener los símbolos %2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Username, InvalidChars);
		
		Raise MessageString;
		
	EndIf;
	
EndProcedure

Procedure CheckWSProxyAddressFormatCorrectness(Val WSProxyAddress)
	
	IsInternetAddress           = False;
	WSProxyAllowedPrefixes = WSProxyAllowedPrefixes();
	
	For Each Prefix In WSProxyAllowedPrefixes Do
		If Left(Lower(WSProxyAddress), StrLen(Prefix)) = Lower(Prefix) Then
			IsInternetAddress = True;
			Break;
		EndIf;
	EndDo;
	
	If Not IsInternetAddress Then
		PrefixesString = "";
		For Each Prefix In WSProxyAllowedPrefixes Do
			PrefixesString = PrefixesString + ?(IsBlankString(PrefixesString), """", " or """) + Prefix + """";
		EndDo;
		
		MessageString = NStr("ru = 'Неверный формат адреса ""%1"".
			|Адрес должен начинаться с префикса Интернет протокола %2 (например: ""http://myserver.com/service"").'; 
			|en = 'Invalid address format: ""%1"".
			|The address must start with one of the internet protocol prefixes: %2 (for example, ""http://myserver.com/service"").'; 
			|pl = 'Błędny format adresu ""%1"".
			|Adres musi zaczynać się od prefiksu protokołu Internetu %2 (na przykład: ""http://myserver.com/service"").';
			|de = 'Falsches Adressformat ""%1"".
			|Die Adresse muss mit dem Präfix des Internetprotokolls beginnen %2 (z.B.: ""http://myserver.com/service"").';
			|ro = 'Format incorect de adresă ""%1"".
			|Adresa trebuie să înceapă cu prefixul protocolului de Internet %2 (de exemplu: ""http://myserver.com/service"").';
			|tr = 'Yanlış Adres biçimi ""%1""
			|. Adres Internet Protokolü öneki ile başlamalıdır%2 (örneğin, ""http://myserver.com/service"").'; 
			|es_ES = 'Formato incorrecto de dirección ""%1"".
			|La dirección debe empezarse con el prefijo del protocolo de Internet %2 (por ejemplo: ""http://myserver.com/service"").'");
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, WSProxyAddress, PrefixesString);
		
		Raise MessageString;
	EndIf;
	
EndProcedure

Function StringContainsCharacter(Val Row, Val CharactersString)
	
	For Index = 1 To StrLen(CharactersString) Do
		Char = Mid(CharactersString, Index, 1);
		
		If StrFind(Row, Char) <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function WSProxyAllowedPrefixes()
	
	Result = New Array();
	
	Result.Add("http");
	Result.Add("https");
	
	Return Result;
	
EndFunction

Procedure ExecuteExchangeSettingsUpdate(InfobaseNode)
	
	If DataExchangeCached.IsMessagesExchangeNode(InfobaseNode) Then
		Return;
	EndIf;
	
	DeleteExchangeTransportSettingsSet = InformationRegisters.DeleteExchangeTransportSettings.CreateRecordSet();
	DeleteExchangeTransportSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
	DeleteExchangeTransportSettingsSet.Read();
	
	ProcessingState = InfobaseUpdate.ObjectProcessed(DeleteExchangeTransportSettingsSet);
	If Not ProcessingState.Processed Then
		InformationRegisters.DeleteExchangeTransportSettings.TransferSettingsOfCorrespondentDataExchangeTransport(InfobaseNode);
	EndIf;
	
	CommonInfobasesNodesSettingsSet = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordSet();
	CommonInfobasesNodesSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
	CommonInfobasesNodesSettingsSet.Read();
	
	If CommonInfobasesNodesSettingsSet.Count() = 0 Then
		InformationRegisters.CommonInfobasesNodesSettings.UpdateCorrespondentCommonSettings(InfobaseNode);
	Else
		ProcessingState = InfobaseUpdate.ObjectProcessed(CommonInfobasesNodesSettingsSet);
		If Not ProcessingState.Processed Then
			InformationRegisters.CommonInfobasesNodesSettings.UpdateCorrespondentCommonSettings(InfobaseNode);
		EndIf;
	EndIf;
	
	If IsXDTOExchangePlan(InfobaseNode) Then
		XDTODataExchangeSettingsSet = InformationRegisters.XDTODataExchangeSettings.CreateRecordSet();
		XDTODataExchangeSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
		XDTODataExchangeSettingsSet.Read();
		
		If XDTODataExchangeSettingsSet.Count() = 0 Then
			InformationRegisters.XDTODataExchangeSettings.RefreshDataExchangeSettingsOfCorrespondentXDTO(InfobaseNode);
		EndIf;
	EndIf;
	
EndProcedure

#Region InfobaseUpdate

// Sets the flag that indicates whether mapping data adjustment for all exchange plan nodes must be 
// executed on the next data exchange.
//
Procedure SetMappingDataAdjustmentRequiredForAllInfobaseNodes() Export
	
	InformationRegisters.CommonInfobasesNodesSettings.SetMappingDataAdjustmentRequiredForAllInfobaseNodes();
	
EndProcedure

// Sets the following value for export mode flags of all universal data exchange nodes:
// Export by condition.
//
Procedure SetExportModeForAllInfobaseNodes() Export
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
			Continue;
		EndIf;
		
		For Each Node In ExchangePlanNodes(ExchangePlanName) Do
			
			AttributesNames = Common.AttributeNamesByType(Node, Type("EnumRef.ExchangeObjectExportModes"));
			
			If IsBlankString(AttributesNames) Then
				Continue;
			EndIf;
			
			AttributesNames = StrReplace(AttributesNames, " ", "");
			
			Attributes = StrSplit(AttributesNames, ",");
			
			ObjectIsModified = False;
			
			ObjectNode = Node.GetObject();
			
			For Each AttributeName In Attributes Do
				
				If Not ValueIsFilled(ObjectNode[AttributeName]) Then
					
					ObjectNode[AttributeName] = Enums.ExchangeObjectExportModes.ExportByCondition;
					
					ObjectIsModified = True;
					
				EndIf;
				
			EndDo;
			
			If ObjectIsModified Then
				
				ObjectNode.AdditionalProperties.Insert("GettingExchangeMessage");
				ObjectNode.Write();
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Refreshes scheduled job data for all data exchange scenarios except for those marked for deletion.
//
Procedure UpdateDataExchangeScenarioScheduledJobs() Export
	
	QueryText = "
	|SELECT
	|	DataExchangeScenarios.Ref
	|FROM
	|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
	|WHERE
	|	NOT DataExchangeScenarios.DeletionMark
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Cancel = False;
		
		Object = Selection.Ref.GetObject();
		
		Catalogs.DataExchangeScenarios.UpdateScheduledJobData(Cancel, Undefined, Object);
		
		If Cancel Then
			Raise NStr("ru = 'Ошибка при обновлении регламентного задания для сценария обмена данными.'; en = 'Cannot update the scheduled job for the data exchange scenario.'; pl = 'Błąd podczas aktualizacji zadania reglamentowanego dla scenariusza  wymiany danych.';de = 'Fehler bei der Aktualisierung der Routineaufgabe für ein Datenaustauschszenario.';ro = 'Eroare de actualizare a sarcinii reglementare pentru scenariul schimbului de date.';tr = 'Veri alışverişi komut dosyası için rutin görev güncelleştirilirken hata oluştu.'; es_ES = 'Error al actualizar la tarea programada para el script de intercambio de datos.'");
		EndIf;
		
		InfobaseUpdate.WriteData(Object);
		
	EndDo;
	
EndProcedure

// Sets the SubordinateDIBNodeSetupCompleted constant to True for the subordinate DIB node, because 
// exchange in DIB is already set.
//
Procedure UpdateSubordinateDIBNodeSetupCompletedConstant() Export
	
	If  IsSubordinateDIBNode()
		AND InformationRegisters.DataExchangeTransportSettings.NodeTransportSettingsAreSet(MasterNode()) Then
		
		Constants.SubordinateDIBNodeSetupCompleted.Set(True);
		
		RefreshReusableValues();
		
	EndIf;
	
EndProcedure

// Redefines the UseDataSynchronization constant value if necessary.
//
Procedure CheckFunctionalOptionsAreSetOnUpdateIB() Export
	
	If Constants.UseDataSynchronization.Get() Then
		
		Constants.UseDataSynchronization.Set(True);
		
	EndIf;
	
EndProcedure

// Redefines the UseDataSynchronization constant value if necessary.
// Because the constant has become shared and its value reset.
//
Procedure CheckFunctionalOptionsAreSetOnUpdateIB_2_1_2_21() Export
	
	If NOT GetFunctionalOption("UseDataSynchronization") Then
		
		If Common.DataSeparationEnabled() Then
			
			Constants.UseDataSynchronization.Set(True);
			
		Else
			
			If GetExchangePlansInUse().Count() > 0 Then
				
				Constants.UseDataSynchronization.Set(True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets the number of items per an export transaction equal to one.
//
Procedure SetItemCountForDataImportTransaction_2_2_2_4() Export
	
	SetDataImportTransactionItemsCount(1);
	
EndProcedure

// Sets the WSRememberPassword attribute value to True in InformationRegister.DeleteExchangeTransportSettings.
//
Procedure SetExchangePasswordSaveOverInternetFlag() Export
	
	QueryText =
	"SELECT
	|	TransportSettings.InfobaseNode AS InfobaseNode
	|FROM
	|	InformationRegister.DeleteExchangeTransportSettings AS TransportSettings
	|WHERE
	|	TransportSettings.DefaultExchangeMessagesTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.WS)";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode", Selection.InfobaseNode);
		RecordStructure.Insert("WSRememberPassword", True);
		
		UpdateInformationRegisterRecord(RecordStructure, "DeleteExchangeTransportSettings");
		
	EndDo;
	
EndProcedure

// Clears saved settings of the DataSynchronization common form.
//
Procedure ClearExchangeMonitorSettings() Export
	
	FormSettingsArray = New Array;
	FormSettingsArray.Add("/FormSettings");
	FormSettingsArray.Add("/WindowSettings");
	FormSettingsArray.Add("/WebClientWindowSettings");
	FormSettingsArray.Add("/CurrentData");
	
	For Each FormItem In FormSettingsArray Do
		SystemSettingsStorage.Delete("CommonForm.DataSynchronization" + FormItem, Undefined, Undefined);
	EndDo;
	
EndProcedure

// Deletes the DataSynchronizationSetup role from all profiles that include it.
Procedure DeleteDataSynchronizationSetupRole() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	RolesToReplace = New Map;
	RolesToReplace.Insert("? DataSynchronizationSetup", NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

#EndRegion

#Region DataExchangeExecution

// Executes data exchange process separately for each exchange setting line.
// Data exchange process consists of two stages:
// - Exchange initialization - preparation of data exchange subsystem to perform data exchange.
// - Data exchange - a process of reading a message file and then importing this data to infobase or 
//                          exporting changes to the message file.
// The initialization stage is performed once per session and is saved to the session cache at 
// server until the session is restarted or cached values of data exchange subsystem are reset.
// Cached values are reset when data that affects data exchange process is changed (transport 
// settings, exchange settings, filter settings on exchange plan nodes).
//
// The exchange can be executed completely for all scenario lines or can be executed for a single 
// row of the exchange scenario TS.
//
// Parameters:
//  Cancel                     - Boolean - a cancelation flag. It appears when scenario execution errors occur.
//  ExchangeExecutionSettings - CatalogRef.DataExchangeScenarios - a catalog item whose attribute 
//                              values are used to perform data exchange.
//  LineNumber - Number - a number of the line to use for performing data exchange.
//                              If it is not specified, all lines are involved in data exchange.
// 
Procedure ExecuteDataExchangeUsingDataExchangeScenario(Cancel, ExchangeExecutionSettings, RowNumber = Undefined) Export
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	QueryText = "
	|SELECT
	|	ExchangeExecutionSettingsExchangeSettings.Ref                         AS ExchangeExecutionSettings,
	|	ExchangeExecutionSettingsExchangeSettings.LineNumber                    AS LineNumber,
	|	ExchangeExecutionSettingsExchangeSettings.CurrentAction            AS CurrentAction,
	|	ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind            AS ExchangeTransportKind,
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode         AS InfobaseNode,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.COM)
	|	THEN TRUE
	|	ELSE FALSE
	|	END AS ExchangeOverExternalConnection,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.WS)
	|	THEN TRUE
	|	ELSE FALSE
	|	END AS ExchangeOverWebService,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.ExternalSystem)
	|	THEN TRUE
	|	ELSE FALSE
	|	END AS ExchangeWithExternalSystem
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeExecutionSettingsExchangeSettings
	|WHERE
	|	ExchangeExecutionSettingsExchangeSettings.Ref = &ExchangeExecutionSettings
	|	[LineNumberCondition]
	|ORDER BY
	|	ExchangeExecutionSettingsExchangeSettings.LineNumber
	|";
	
	LineNumberCondition = ?(RowNumber = Undefined, "", "AND ExchangeExecutionSettingsExchangeSettings.LineNumber = &LineNumber");
	
	QueryText = StrReplace(QueryText, "[LineNumberCondition]", LineNumberCondition);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangeExecutionSettings", ExchangeExecutionSettings);
	Query.SetParameter("LineNumber", RowNumber);
	
	Selection = Query.Execute().Select();
	
	IsSubordinateDIBNodeRequiringUpdates = 
		IsSubordinateDIBNode() AND UpdateInstallationRequired();
		
	While Selection.Next() Do
		CancelByScenarioString = False;
		If IsSubordinateDIBNodeRequiringUpdates
			AND DataExchangeCached.IsDistributedInfobaseNode(Selection.InfobaseNode) Then
			// Scheduled exchange is not performed.
			Continue;
		ElsIf Not SynchronizationSetupCompleted(Selection.InfobaseNode)
			AND Not Selection.ExchangeWithExternalSystem Then
			Continue;
		EndIf;
		
		If Selection.ExchangeOverExternalConnection Then
			
			CheckExternalConnectionAvailable();
			
			TransactionItemsCount = ItemsCountInTransactionOfActionBeingExecuted(Selection.CurrentAction);
			
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(CancelByScenarioString,
				Selection.InfobaseNode, Selection.CurrentAction, TransactionItemsCount);
			
		ElsIf Selection.ExchangeOverWebService Then
			
			ExchangeParameters = ExchangeParameters();
			ExecuteExchangeActionForInfobaseNodeUsingWebService(CancelByScenarioString,
				Selection.InfobaseNode, Selection.CurrentAction, ExchangeParameters);
			
		Else
			
			// INITIALIZING DATA EXCHANGE
			ExchangeSettingsStructure = DataExchangeSettings(Selection.ExchangeExecutionSettings, Selection.LineNumber);
			
			// If settings contain errors, canceling the exchange.
			If ExchangeSettingsStructure.Cancel Then
				
				CancelByScenarioString = True;
				
				// Registering data exchange log in the event log.
				AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
				Continue;
			EndIf;
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
			
			// Adding data exchange message to the event log.
			MessageString = NStr("ru = 'Начало процесса обмена данными по настройке %1'; en = 'Data exchange with ""%1"" settings started.'; pl = 'Początek procesu wymiany danych po ustawieniu %1';de = 'Der Datenaustausch beginnt mit der Einstellung %1';ro = 'Începutul procesului schimbului de date conform setării %1';tr = 'Ayar için veri değişim süreci başlatılıyor%1'; es_ES = 'Inicio del proceso del intercambio de datos para la configuración %1'", Common.DefaultLanguageCode());
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.ExchangeExecutionSettingDescription);
			WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
			
			// DATA EXCHANGE
			ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure);
			
			// Registering data exchange log in the event log.
			AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
			
			If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
				
				CancelByScenarioString = True;
				
			EndIf;
			
		EndIf;
		If CancelByScenarioString Then
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure

// An entry point for data exchange using scheduled job exchange scenario.
//
// Parameters:
//  ExchangeScenarioCode - String - a code of the Data exchange scenarios catalog item for which 
//                               data exchange is to be executed.
// 
Procedure ExecuteDataExchangeWithScheduledJob(ExchangeScenarioCode) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataSynchronization);
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	If Not ValueIsFilled(ExchangeScenarioCode) Then
		Raise NStr("ru = 'Не задан сценарий обмена данными.'; en = 'The data exchange scenario is not specified.'; pl = 'Nie określono scenariusza wymiany danych.';de = 'Datenaustauschszenario ist nicht angegeben.';ro = 'Scenariul de schimb de date nu este specificat.';tr = 'Veri değişimi senaryosu belirtilmemiş.'; es_ES = 'Escenarios del intercambio de datos no está especificado.'");
	EndIf;
	
	QueryText = "
	|SELECT
	|	DataExchangeScenarios.Ref AS Ref
	|FROM
	|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
	|WHERE
	|		 DataExchangeScenarios.Code = &Code
	|	AND NOT DataExchangeScenarios.DeletionMark
	|";
	
	Query = New Query;
	Query.SetParameter("Code", ExchangeScenarioCode);
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		// Performing exchange using scenario.
		ExecuteDataExchangeUsingDataExchangeScenario(False, Selection.Ref);
	Else
		MessageString = NStr("ru = 'Сценарий обмена данными с кодом %1 не найден.'; en = 'The data exchange scenario with code %1 is not found.'; pl = 'Nie znaleziono skryptu wymiany danych z kodem %1.';de = 'Datenaustauschskript mit Code %1 wurde nicht gefunden.';ro = 'Scenariul schimbului de date cu codul %1 nu a fost găsit.';tr = '%1Kodu ile veri değişim betiği bulunamadı.'; es_ES = 'Script del intercambio de datos con el código %1 no encontrado.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeScenarioCode);
		Raise MessageString;
	EndIf;
	
EndProcedure

// Gets an exchange message to OS user's temporary directory.
//
// Parameters:
//  Cancel - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which the exchange message is being 
//                                                    received.
//  ExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportKinds - a transport kind for 
//                                                                                    receiving exchange messages.
//  OutputMessages - Boolean - if True, user messages are displayed.
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessageCatalogName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName - a full name of the exchange message file.
//     * DataPackageFileID - date of changing the exchange message file.
//
Function GetExchangeMessageToTemporaryDirectory(Cancel, InfobaseNode, ExchangeMessagesTransportKind, OutputMessages = True) Export
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessageCatalogName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	ExchangeSettingsStructure = ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind);
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	// If the setting contains errors, canceling exchange message receiving and setting the exchange status to Canceled.
	If ExchangeSettingsStructure.Cancel Then
		
		If OutputMessages Then
			NString = NStr("ru = 'При инициализации обработки транспорта сообщений обмена возникли ошибки.'; en = 'Exchange message transport processing initialization error.'; pl = 'W trakcie inicjalizacji przetwarzania transportu komunikatów wymiany zaistniały błędy.';de = 'Beim Initialisieren der Verarbeitung des Nachrichtenaustauschs sind Fehler aufgetreten.';ro = 'Au apărut erori în timpul inițializării procesării transportului mesajelor de schimb.';tr = 'Değişim mesajı aktarımının işlenmesi başlatılırken hatalar oluştu.'; es_ES = 'Errores ocurridos durante la iniciación del proceso del transporte de mensajes de intercambio.'");
			Common.MessageToUser(NString,,,, Cancel);
		EndIf;
		
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	// Creating a temporary directory.
	ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		
		// Receiving the message and putting it in the temporary directory.
		ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure);
		
	EndIf;

	If ExchangeSettingsStructure.ExchangeExecutionResult <> Undefined Then
		
		If OutputMessages Then
			NString = NStr("ru = 'При получении сообщений обмена возникли ошибки.'; en = 'Errors occurred when receiving exchange messages.'; pl = 'Podczas otrzymywaniu komunikatów wymiany zaistniały błędy.';de = 'Beim Empfangen von Austauschnachrichten sind Fehler aufgetreten.';ro = 'Au apărut erori la primirea mesajelor de schimb.';tr = 'Değişim mesajları alınırken hatalar oluştu.'; es_ES = 'Errores ocurridos al recibir los mensajes de intercambio.'");
			Common.MessageToUser(NString,,,, Cancel);
		EndIf;
		
		// Deleting temporary directory with all its content.
		ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
		
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	Result.TempExchangeMessageCatalogName = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageCatalogName();
	Result.ExchangeMessageFileName              = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName();
	Result.DataPackageFileID       = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileDate();
	
	Return Result;
EndFunction

// Gets an exchange message from the correspondent infobase to OS user's temporary directory.
//
// Parameters:
//  Cancel - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which the exchange message is being 
//                                                    received.
//  OutputMessages - Boolean - if True, user messages are displayed.
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessageCatalogName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName - a full name of the exchange message file.
//     * DataPackageFileID - date of changing the exchange message file.
//
Function GetExchangeMessageFromCorrespondentInfobaseToTempDirectory(Cancel, InfobaseNode, OutputMessages = True) Export
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessageCatalogName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	CurrentExchangePlanNodeCode = NodeIDForExchange(InfobaseNode);

	MessageFileNamePattern = MessageFileNamePattern(CurrentExchangePlanNode, InfobaseNode, False);
	
	// Parameters to be defined in the function.
	ExchangeMessageFileDate = Date('00010101');
	ExchangeMessageCatalogName = "";
	ErrorMessageString = "";
	
	Try
		ExchangeMessageCatalogName = CreateTempExchangeMessagesDirectory();
	Except
		If OutputMessages Then
			Message = NStr("ru = 'Не удалось произвести обмен: %1'; en = 'Cannot run the exchange: %1'; pl = 'Nie można wymienić: %1';de = 'Kann nicht austauschen: %1';ro = 'Eșec la executarea schimbului: %1';tr = 'Değişim yapılamadı: %1'; es_ES = 'No se puede intercambiar: %1'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
			Common.MessageToUser(Message,,,, Cancel);
		EndIf;
		Return Result;
	EndTry;
	
	// Getting external connection for the infobase node.
	ConnectionData = DataExchangeCached.ExternalConnectionForInfobaseNode(InfobaseNode);
	ExternalConnection = ConnectionData.Connection;
	
	If ExternalConnection = Undefined Then
		
		Message = NStr("ru = 'Не удалось произвести обмен: %1'; en = 'Cannot run the exchange: %1'; pl = 'Nie można wymienić: %1';de = 'Kann nicht austauschen: %1';ro = 'Eșec la executarea schimbului: %1';tr = 'Değişim yapılamadı: %1'; es_ES = 'No se puede intercambiar: %1'");
		If OutputMessages Then
			UserMessage = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.BriefErrorDescription);
			Common.MessageToUser(UserMessage,,,, Cancel);
		EndIf;
		
		// Adding two records to the event log: one for data import and one for data export.
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.DetailedErrorDescription);
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndIf;
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName, MessageFileNamePattern + ".xml");
	
	NodeAlias = PredefinedNodeAlias(InfobaseNode);
	If ValueIsFilled(NodeAlias) Then
		// You need to check the node code in the correspondent because it can be already re-encoded.
		// In this case, alias is not required.
		ExchangePlanManager = ExternalConnection.ExchangePlans[ExchangePlanName];
		If ExchangePlanManager.FindByCode(NodeAlias) <> ExchangePlanManager.EmptyRef() Then
			CurrentExchangePlanNodeCode = NodeAlias;
		EndIf;
	EndIf;
	
	ExternalConnection.DataExchangeExternalConnection.ExportForInfobaseNode(Cancel, ExchangePlanName, CurrentExchangePlanNodeCode, ExchangeMessageFileName, ErrorMessageString);
	
	If Cancel Then
		
		If OutputMessages Then
			// Displaying error message.
			Message = NStr("ru = 'Не удалось выгрузить данные: %1'; en = 'Cannot export data: %1'; pl = 'Nie można eksportować danych: %1';de = 'Daten können nicht exportiert werden: %1';ro = 'Eșec la exportul datelor: %1';tr = 'Veri dışa aktarılamadı: %1'; es_ES = 'No se puede exportar los datos: %1'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.BriefErrorDescription);
			Common.MessageToUser(Message,,,, Cancel);
		EndIf;
		
		Return Result;
	EndIf;
	
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If FileExchangeMessages.Exist() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessageCatalogName = ExchangeMessageCatalogName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

// Gets an exchange message from the correspondent infobase via web service to the temporary directory of the
// OS user.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which exchange message is being received.
//  FileID      - UUID - a file ID.
//  TimeConsumingOperation      - Boolean - indicates that time-consuming operation is used.
//  OperationID   - UUID - an UUID of the time-consuming operation.
//  AuthenticationParameters - Structure. Contains web service authentication parameters (User, Password).
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessageCatalogName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName - a full name of the exchange message file.
//     * DataPackageFileID - date of changing the exchange message file.
//
Function GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseOverWebService(
											Cancel,
											InfobaseNode,
											FileID,
											TimeConsumingOperation,
											OperationID,
											AuthenticationParameters = Undefined) Export
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessageCatalogName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	// Parameters to be defined in the function.
	ExchangeMessageCatalogName = "";
	ExchangeMessageFileName = "";
	ExchangeMessageFileDate = Date('00010101');
	
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("ExchangePlanName", DataExchangeCached.GetExchangePlanName(InfobaseNode));
	ExchangeSettingsStructure.Insert("InfobaseNode", InfobaseNode);
	ExchangeSettingsStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport));
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNode",
		DataExchangeCached.GetThisExchangePlanNode(ExchangeSettingsStructure.ExchangePlanName));
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNodeCode",
		NodeIDForExchange(InfobaseNode));
	ExchangeSettingsStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
		
	ProxyParameters = New Structure;
	ProxyParameters.Insert("AuthenticationParameters", AuthenticationParameters);
	
	Proxy = Undefined;
	SetupStatus = Undefined;
	ErrorMessage = "";
	InitializeWSProxyToManageDataExchange(Proxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);
	
	If Cancel Then
		WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
		Return Result;
	EndIf;
	
	Try
		
		Proxy.UploadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode,
			FileID,
			TimeConsumingOperation,
			OperationID,
			True);
		
	Except
		
		Cancel = True;
		Message = NStr("ru = 'При выгрузке данных возникли ошибки во второй информационной базе: %1'; en = 'Errors occurred in the peer infobase during data export: %1'; pl = 'Podczas eksportowania danych wystąpiły błędy w drugiej bazie informacyjnej: %1';de = 'Beim Exportieren von Daten sind Fehler in der zweiten Infobase aufgetreten: %1';ro = 'La exportul datelor au apărut erori în cea de-a doua bază de date: %1';tr = 'Verileri dışa aktarırken, ikinci veritabanında hatalar oluştu:%1'; es_ES = 'Al exportar los datos, han ocurrido errores en la segunda infobase: %1'", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
		
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	If TimeConsumingOperation Then
		WriteEventLogDataExchange(NStr("ru = 'Ожидание получения данных от базы-корреспондента...'; en = 'Waiting for data from the peer infobase...'; pl = 'Oczekiwanie odbioru danych z bazy korespondenta...';de = 'Ausstehende Daten von der Korrespondenzbasis...';ro = 'Datele în așteptare de la baza corespondentă...';tr = 'Muhabir tabandan veri bekleniyor ...'; es_ES = 'Datos pendientes de la base corresponsal...'",
			Common.DefaultLanguageCode()), ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	Try
		FileTransferServiceFileName = GetFileFromStorageInService(New UUID(FileID),
			ExchangeSettingsStructure.InfobaseNode,, AuthenticationParameters);
	Except
		
		Cancel = True;
		Message = NStr("ru = 'Возникли ошибки при получении сообщения обмена из сервиса передачи файлов: %1'; en = 'Errors occurred while receiving an exchange message from the file transfer service: %1'; pl = 'Wystąpiły błędy podczas odbierania wiadomości wymiany z usługi przesyłania plików: %1';de = 'Beim Empfang einer Austauschnachricht vom Dateiübertragungsdienst sind Fehler aufgetreten: %1';ro = 'Erori la primirea mesajului de schimb de la serviciul de transfer de fișiere: %1';tr = 'Dosya aktarım hizmetinden bir değişim mesajı alınırken hatalar oluştu:%1'; es_ES = 'Han ocurrido errores al recibir un mensaje de intercambio del servicio de transferencia de archivos: %1'", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
		
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	Try
		ExchangeMessageCatalogName = CreateTempExchangeMessagesDirectory();
	Except
		Cancel = True;
		Message = NStr("ru = 'При получении сообщения обмена возникли ошибки: %1'; en = 'Errors occurred while receiving an exchange message: %1'; pl = 'Podczas odbioru wiadomości wymiany wystąpiły błędy: %1';de = 'Beim Empfangen von Austauschnachrichten sind Fehler aufgetreten: %1';ro = 'Au apărut erori la primirea mesajelor de schimb: %1';tr = 'Değişim mesajları alınırken hatalar oluştu: %1'; es_ES = 'Han ocurrido errores al recibir los mensajes de intercambio: %1'", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
		
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	MessageFileNamePattern = MessageFileNamePattern(ExchangeSettingsStructure.CurrentExchangePlanNode,
		ExchangeSettingsStructure.InfobaseNode, False);
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName, MessageFileNamePattern + ".xml");
	
	MoveFile(FileTransferServiceFileName, ExchangeMessageFileName);
	
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If FileExchangeMessages.Exist() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessageCatalogName = ExchangeMessageCatalogName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

// The function receives an exchange message from the correspondent infobase using web service
// and saves it to the temporary directory.
// It is used if the exchange message receipt is a part of a background job in the correspondent 
// infobase.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which exchange message is being received.
//  FileID      - UUID - a file ID.
//  AuthenticationParameters - Structure. Contains web service authentication parameters (User, Password).
//
//  Returns:
//   Structure with the following keys:
//     * TempExchangeMessageCatalogName - a full name of the exchange directory that stores the exchange message.
//     * ExchangeMessageFileName - a full name of the exchange message file.
//     * DataPackageFileID - date of changing the exchange message file.
//
Function GetExchangeMessageToTempDirectoryFromCorrespondentInfobaseOverWebServiceTimeConsumingOperationCompletion(
							Cancel,
							InfobaseNode,
							FileID,
							Val AuthenticationParameters = Undefined) Export
	
	// Function return value.
	Result = New Structure;
	Result.Insert("TempExchangeMessageCatalogName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	// Parameters to be defined in the function.
	ExchangeMessageCatalogName = "";
	ExchangeMessageFileName = "";
	ExchangeMessageFileDate = Date('00010101');
	
	Try
		
		FileTransferServiceFileName = GetFileFromStorageInService(New UUID(FileID), InfobaseNode,, AuthenticationParameters);
	Except
		
		Cancel = True;
		Message = NStr("ru = 'Возникли ошибки при получении сообщения обмена из сервиса передачи файлов: %1'; en = 'Errors occurred when receiving an exchange message from file transfer service: %1'; pl = 'Wystąpiły błędy podczas odbierania wiadomości wymiany z usługi przesyłania plików: %1';de = 'Beim Empfang einer Austauschnachricht vom Dateiübertragungsdienst sind Fehler aufgetreten: %1';ro = 'Erori la primirea mesajului de schimb de la serviciul de transfer de fișiere: %1';tr = 'Dosya aktarım hizmetinden bir değişim mesajı alınırken hatalar oluştu:%1'; es_ES = 'Han ocurrido errores al recibir un mensaje de intercambio del servicio de transferencia de archivos: %1'", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	Try
		ExchangeMessageCatalogName = CreateTempExchangeMessagesDirectory();
	Except
		Cancel = True;
		Message = NStr("ru = 'При получении сообщения обмена возникли ошибки: %1'; en = 'Errors occurred while receiving an exchange message: %1'; pl = 'Podczas odbioru wiadomości wymiany wystąpiły błędy: %1';de = 'Beim Empfangen von Austauschnachrichten sind Fehler aufgetreten: %1';ro = 'Au apărut erori la primirea mesajelor de schimb: %1';tr = 'Değişim mesajları alınırken hatalar oluştu: %1'; es_ES = 'Han ocurrido errores al recibir los mensajes de intercambio: %1'", Common.DefaultLanguageCode());
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DetailErrorDescription(ErrorInfo()));
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndTry;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	
	MessageFileNamePattern = MessageFileNamePattern(CurrentExchangePlanNode, InfobaseNode, False);
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName, MessageFileNamePattern + ".xml");
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If NOT FileExchangeMessages.Exist() Then
		// Probably the file can be received if you apply the virtual code of the node.
		TemplateOfMessageFileNamePrevious = MessageFileNamePattern;
		MessageFileNamePattern = MessageFileNamePattern(CurrentExchangePlanNode, InfobaseNode, False,, True);
		If MessageFileNamePattern <> TemplateOfMessageFileNamePrevious Then
			ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageCatalogName, MessageFileNamePattern + ".xml");
			FileExchangeMessages = New File(ExchangeMessageFileName);
		EndIf;
	EndIf;
	
	MoveFile(FileTransferServiceFileName, ExchangeMessageFileName);
	
	If FileExchangeMessages.Exist() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessageCatalogName = ExchangeMessageCatalogName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

// Gets exchange message file from a correspondent infobase using web service.
// Imports exchange message file to the current infobase.
//
// Parameters:
//  Cancel                   - Boolean - indicates whether an error occurred on data exchange.
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which exchange message is being received.
//  FileID      - UUID - a file ID.
//  OperationStartDate      - Date - the date of import start.
//  AuthenticationParameters - Structure. Contains web service authentication parameters (User, Password).
//
Procedure ExecuteDataExchangeForInfobaseNodeTimeConsumingOperationCompletion(
															Cancel,
															Val InfobaseNode,
															Val FileID,
															Val OperationStartDate,
															Val AuthenticationParameters = Undefined,
															ShowError = False) Export
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	Try
		FileExchangeMessages = GetFileFromStorageInService(New UUID(FileID), InfobaseNode,, AuthenticationParameters);
	Except
		RecordExchangeCompletionWithError(InfobaseNode,
			Enums.ActionsOnExchange.DataImport,
			OperationStartDate,
			DetailErrorDescription(ErrorInfo()));
		If ShowError Then
			Raise;
		Else
			Cancel = True;
		EndIf;
		Return;
	EndTry;
	
	// Importing the exchange message file into the current infobase.
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.InfobaseNode        = InfobaseNode;
	DataExchangeParameters.FullNameOfExchangeMessageFile = FileExchangeMessages;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.OperationStartDate            = OperationStartDate;
	
	Try
		ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		RecordExchangeCompletionWithError(InfobaseNode,
			Enums.ActionsOnExchange.DataImport,
			OperationStartDate,
			DetailErrorDescription(ErrorInfo()));
		If ShowError Then
			Raise;
		Else
			Cancel = True;
		EndIf;
	EndTry;
	
	Try
		DeleteFiles(FileExchangeMessages);
	Except
		WriteLogEvent(EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Deletes exchange message files that are not deleted due to system failures.
// Exchange files placed earlier than 24 hours ago from the current universal date and mapping files 
// placed earlier than 7 days ago from the current universal date are to be deleted.
// Analyzing IR.DataExchangeMessages and IR.DataAreaDataExchangeMessages.
//
// Parameters:
//   No.
//
Procedure DeleteObsoleteExchangeMessages() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ObsoleteSynchronizationDataDeletion);
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		Return;
	EndIf;
	
	CheckExchangeManagementRights();
	
	SetPrivilegedMode(True);
	
	If Common.SeparatedDataUsageAvailable() Then
		// Deleting obsolete exchange messages marked in IR.DataExchangeMessages.
		QueryText =
		"SELECT
		|	DataExchangeMessages.MessageID AS MessageID,
		|	DataExchangeMessages.MessageFileName AS FileName,
		|	DataExchangeMessages.MessageStoredDate AS MessageStoredDate,
		|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
		|	CASE
		|		WHEN CommonInfobasesNodesSettings.InfobaseNode IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS MessageForMapping
		|INTO TTExchangeMessages
		|FROM
		|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
		|		LEFT JOIN InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
		|		ON (CommonInfobasesNodesSettings.MessageForDataMapping = DataExchangeMessages.MessageID)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTExchangeMessages.MessageID AS MessageID,
		|	TTExchangeMessages.FileName AS FileName,
		|	TTExchangeMessages.MessageForMapping AS MessageForMapping,
		|	TTExchangeMessages.InfobaseNode AS InfobaseNode
		|FROM
		|	TTExchangeMessages AS TTExchangeMessages
		|WHERE
		|	CASE
		|			WHEN TTExchangeMessages.MessageForMapping
		|				THEN TTExchangeMessages.MessageStoredDate < &RelevanceDateForMapping
		|			ELSE TTExchangeMessages.MessageStoredDate < &UpdateDate
		|		END";
		
		Query = New Query;
		Query.SetParameter("UpdateDate",                 CurrentUniversalDate() - 60 * 60 * 24);
		Query.SetParameter("RelevanceDateForMapping", CurrentUniversalDate() - 60 * 60 * 24 * 7);
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			MessageFileFullName = CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), Selection.FileName);
			
			MessageFile = New File(MessageFileFullName);
			
			If MessageFile.Exist() Then
				
				Try
					DeleteFiles(MessageFile.FullName);
				Except
					WriteLogEvent(EventLogMessageTextDataExchange(),
						EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
					Continue;
				EndTry;
			EndIf;
			
			// Deleting information about message file from the storage.
			RecordStructure = New Structure;
			RecordStructure.Insert("MessageID", String(Selection.MessageID));
			InformationRegisters.DataExchangeMessages.DeleteRecord(RecordStructure);
			
			If Selection.MessageForMapping Then
				RecordStructure = New Structure;
				RecordStructure.Insert("InfobaseNode",          Selection.InfobaseNode);
				RecordStructure.Insert("MessageForDataMapping", "");
				
				UpdateInformationRegisterRecord(RecordStructure, "CommonInfobasesNodesSettings");
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// Deleting obsolete exchange messages marked in IR.DataAreaDataExchangeMessages.
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnDeleteObsoleteExchangeMessages();
	EndIf;
	
EndProcedure

Function ItemsCountInTransactionOfActionBeingExecuted(Action)
	
	If Action = Enums.ActionsOnExchange.DataExport Then
		ItemsCount = DataExportTransactionItemsCount();
	Else
		ItemsCount = DataImportTransactionItemCount();
	EndIf;
	
	Return ItemsCount;
	
EndFunction

// Exports the exchange message that contained configuration changes before infobase update.
// 
//
Procedure ExportMessageAfterInfobaseUpdate()
	
	// The repeat mode can be disabled if messages are imported and the infobase is updated successfully.
	DisableDataExchangeMessageImportRepeatBeforeStart();
	
	Try
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				ExecuteExport = True;
				
				TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(InfobaseNode);
				
				TransportKind = TransportSettings.DefaultExchangeMessagesTransportKind;
				
				If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
					AND Not TransportSettings.WSRememberPassword Then
					
					ExecuteExport = False;
					
					InformationRegisters.CommonInfobasesNodesSettings.SetDataSendingFlag(InfobaseNode);
					
				EndIf;
				
				If ExecuteExport Then
					
					// Export only.
					Cancel = False;
					
					ExchangeParameters = ExchangeParameters();
					ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
					ExchangeParameters.ExecuteImport = False;
					ExchangeParameters.ExecuteExport = True;
					
					ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		WriteLogEvent(EventLogMessageTextDataExchange(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

#Region ToWorkThroughExternalConnections

Procedure ExportToTempStorageForInfobaseNode(Val ExchangePlanName, Val InfobaseNodeCode, Address) Export
	
	FullNameOfExchangeMessageFile = GetTempFileName("xml");
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = FullNameOfExchangeMessageFile;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	Address = PutToTempStorage(New BinaryData(FullNameOfExchangeMessageFile));
	
	DeleteFiles(FullNameOfExchangeMessageFile);
	
EndProcedure

Procedure ExportToFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	UseCompression = ProcedureParameters.Property("UseCompression") AND ProcedureParameters["UseCompression"];
	
	SetPrivilegedMode(True);
	
	MessageFileName = CommonClientServer.GetFullFileName(
		TempFilesStorageDirectory(),
		UniqueExchangeMessageFileName());
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	NameOfFileToPutInStorage = MessageFileName;
	If UseCompression Then
		NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
			TempFilesStorageDirectory(),
			UniqueExchangeMessageFileName("zip"));
		
		Archiver = New ZipFileWriter(NameOfFileToPutInStorage, , , , ZIPCompressionLevel.Maximum);
		Archiver.Add(MessageFileName);
		Archiver.Write();
		
		DeleteFiles(MessageFileName);
	EndIf;
	
	PutFileInStorage(NameOfFileToPutInStorage, FileID);
	
EndProcedure

Procedure ExportForInfobaseNodeViaFile(Val ExchangePlanName,
	Val InfobaseNodeCode,
	Val FullNameOfExchangeMessageFile) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = FullNameOfExchangeMessageFile;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
EndProcedure

Procedure ExportForInfobaseNodeViaString(Val ExchangePlanName, Val InfobaseNodeCode, ExchangeMessage) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	DataExchangeParameters.ExchangeMessage               = ExchangeMessage;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	ExchangeMessage = DataExchangeParameters.ExchangeMessage;
	
EndProcedure

Procedure ImportForInfobaseNodeViaString(Val ExchangePlanName, Val InfobaseNodeCode, ExchangeMessage) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	DataExchangeParameters.ExchangeMessage               = ExchangeMessage;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	ExchangeMessage = DataExchangeParameters.ExchangeMessage;
	
EndProcedure

Procedure ImportFromFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	SetPrivilegedMode(True);
	
	TempFileName = GetFileFromStorage(FileID);
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = TempFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	Try
		ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		DeleteFiles(TempFileName);
		Raise ErrorPresentation;
	EndTry;
	
	DeleteFiles(TempFileName);
EndProcedure

Function DataExchangeParametersThroughFileOrString() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("InfobaseNode");
	ParametersStructure.Insert("FullNameOfExchangeMessageFile", "");
	ParametersStructure.Insert("ActionOnExchange");
	ParametersStructure.Insert("ExchangePlanName", "");
	ParametersStructure.Insert("InfobaseNodeCode", "");
	ParametersStructure.Insert("ExchangeMessage", "");
	ParametersStructure.Insert("OperationStartDate", "");
	
	Return ParametersStructure;
	
EndFunction

Procedure ExecuteDataExchangeForInfobaseNodeOverFileOrString(ExchangeParameters) Export
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	If ExchangeParameters.InfobaseNode = Undefined Then
		
		ExchangePlanName = ExchangeParameters.ExchangePlanName;
		InfobaseNodeCode = ExchangeParameters.InfobaseNodeCode;
		
		ExchangeParameters.InfobaseNode = ExchangePlans[ExchangePlanName].FindByCode(InfobaseNodeCode);
			
		If ExchangeParameters.InfobaseNode.IsEmpty()
			AND IsXDTOExchangePlan(ExchangePlanName) Then
			MigrationError = False;
			SynchronizationSetupViaCF = ExchangePlans[ExchangePlanName].MigrateToDataSyncViaUniversalFormatInternet(
				InfobaseNodeCode, MigrationError);
			If ValueIsFilled(SynchronizationSetupViaCF) Then
				ExchangeParameters.InfobaseNode = SynchronizationSetupViaCF;
			ElsIf MigrationError Then
				ErrorMessageString = NStr("ru = 'Не удалось выполнить переход на синхронизацию данных через универсальный формат.'; en = 'Cannot switch to universal data synchronization format.'; pl = 'Nie udało się wykonać przejście do synchronizacji danych za pomocą formatu uniwersalnego.';de = 'Fehler beim Migrieren zum Synchronisieren der Daten über das universelle Format.';ro = 'Eșec la executarea trecerii la sincronizarea datelor prin format universal.';tr = 'Genel biçim üzerinden veri eşleştirmeye geçiş başarısız oldu.'; es_ES = 'No se ha podido pasar a la sincronización de datos a través del frmato universal.'");
				Raise ErrorMessageString;
			EndIf;
		EndIf;
		
		If ExchangeParameters.InfobaseNode.IsEmpty() Then
			ErrorMessageString = NStr("ru = 'Узел плана обмена %1 с кодом %2 не найден.'; en = 'The node of exchange plan %1 with code %2 is not found.'; pl = 'Nie znaleziono węzła planu wymiany %1 z kodem %2.';de = 'Austauschplan-Knoten %1 mit Code %2 wurde nicht gefunden.';ro = 'Nodul planului de schimb %1 cu codul %2 nu a fost găsit.';tr = '%1Kod ile değişim planı ünitesi%2 bulunamadı. '; es_ES = 'Nodo del plan de intercambio %1 con el código %2 no encontrado.'");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ExchangePlanName, InfobaseNodeCode);
			Raise ErrorMessageString;
		EndIf;
		
	EndIf;
	
	ExecuteExchangeSettingsUpdate(ExchangeParameters.InfobaseNode);
	
	If Not SynchronizationSetupCompleted(ExchangeParameters.InfobaseNode) Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		CorrespondentData = Common.ObjectAttributesValues(ExchangeParameters.InfobaseNode,
			"Code, Description");
		
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В ""%1"" настройка синхронизации данных с ""%2"" (идентификатор ""%3"") еще не завершена.'; en = 'The setup of data synchronization with %2 (ID: %3) in %1 is not completed.'; pl = 'W ""%1"" ustawienie synchronizacji danych z ""%2"" (identyfikator ""%3"") jeszcze nie jest zakończone.';de = 'In ""%1"" ist die Einstellung der Datensynchronisation mit ""%2"" (Bezeichner ""%3"") noch nicht abgeschlossen.';ro = 'În ""%1"" setarea sincronizării datelor cu ""%2"" (identificatorul ""%3"") încă nu este finalizată.';tr = '""%1"" ""%2""(kimlik""%3"") ile veri senkronizasyonu ayarı henüz tamamlanmadı.'; es_ES = 'En ""%1"" el ajuste de sincronización de datos con ""%2"" (identificador ""%3"") todavía no se ha terminado.'"),
			ApplicationPresentation, CorrespondentData.Description, CorrespondentData.Code);
			
		Raise ErrorMessageString;
	EndIf;
	
	// INITIALIZING DATA EXCHANGE
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
		ExchangeParameters.InfobaseNode, ExchangeParameters.ActionOnExchange, Undefined, False);
	
	If ExchangeSettingsStructure.Cancel Then
		ErrorMessageString = NStr("ru = 'Ошибка при инициализации процесса обмена данными.'; en = 'Cannot initialize data exchange.'; pl = 'Podczas inicjowania procesu wymiany danych wystąpił błąd.';de = 'Bei der Initialisierung des Datenaustauschprozesses ist ein Fehler aufgetreten.';ro = 'Eroare la inițializarea procesului schimbului de date.';tr = 'Veri alışverişi sürecini başlatırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al iniciar el proceso de intercambio de datos.'");
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Raise ErrorMessageString;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	If ExchangeParameters.OperationStartDate <> Undefined Then
		ExchangeSettingsStructure.StartDate = ExchangeParameters.OperationStartDate;
	EndIf;
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła %1';de = 'Datenaustausch beginnt für Knoten %1';ro = 'Începutul procesului schimbului de date pentru nodul %1';tr = '%1Ünite için veri değişimi süreci başlatılıyor'; es_ES = 'Inicio de proceso de intercambio de datos para el nodo %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.DoDataImport Then
		
		TemporaryFileCreated = False;
		If ExchangeParameters.FullNameOfExchangeMessageFile = ""
			AND ExchangeParameters.ExchangeMessage <> "" Then
			
			ExchangeParameters.FullNameOfExchangeMessageFile = GetTempFileName(".xml");
			TextFile = New TextDocument;
			TextFile.SetText(ExchangeParameters.ExchangeMessage);
			TextFile.Write(ExchangeParameters.FullNameOfExchangeMessageFile);
			TemporaryFileCreated = True;
		EndIf;
		
		ReadMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeParameters.FullNameOfExchangeMessageFile, ExchangeParameters.ExchangeMessage);
		
		// {Handler: AfterExchangeMessageRead} Start
		StandardProcessing = True;
		
		AfterExchangeMessageRead(
					ExchangeSettingsStructure.InfobaseNode,
					ExchangeParameters.FullNameOfExchangeMessageFile,
					ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
					StandardProcessing);
		// {Handler: AfterExchangeMessageRead} End
		
		If TemporaryFileCreated Then
			
			Try
				DeleteFiles(ExchangeParameters.FullNameOfExchangeMessageFile);
			Except
				WriteLogEvent(EventLogMessageTextDataExchange(),
					EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		WriteMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeParameters.FullNameOfExchangeMessageFile, ExchangeParameters.ExchangeMessage);
		
	EndIf;
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		Raise ExchangeSettingsStructure.ErrorMessageString;
	EndIf;
	
EndProcedure

Procedure AddExchangeOverExternalConnectionFinishEventLogMessage(ExchangeSettingsStructure) Export
	
	SetPrivilegedMode(True);
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
EndProcedure

Function ExchangeOverExternalConnectionSettingsStructure(Structure) Export
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	InfobaseNode = ExchangePlans[Structure.ExchangePlanName].FindByCode(Structure.CurrentExchangePlanNodeCode);
	
	ActionOnExchange = Enums.ActionsOnExchange[Structure.ActionOnStringExchange];
	
	ExchangeSettingsStructureExternalConnection = New Structure;
	ExchangeSettingsStructureExternalConnection.Insert("ExchangePlanName",                   Structure.ExchangePlanName);
	ExchangeSettingsStructureExternalConnection.Insert("DebugMode",                     Structure.DebugMode);
	
	ExchangeSettingsStructureExternalConnection.Insert("InfobaseNode",             InfobaseNode);
	ExchangeSettingsStructureExternalConnection.Insert("InfobaseNodeDescription", Common.ObjectAttributeValue(InfobaseNode, "Description"));
	
	ExchangeSettingsStructureExternalConnection.Insert("EventLogMessageKey",  EventLogMessageKey(InfobaseNode, ActionOnExchange));
	
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeExecutionResult",        Undefined);
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeExecutionResultString", "");
	
	ExchangeSettingsStructureExternalConnection.Insert("ActionOnExchange", ActionOnExchange);
	
	ExchangeSettingsStructureExternalConnection.Insert("ExportHandlersDebug", False);
	ExchangeSettingsStructureExternalConnection.Insert("ImportHandlersDebug", False);
	ExchangeSettingsStructureExternalConnection.Insert("ExportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("ImportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("DataExchangeLoggingMode", False);
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeProtocolFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("ContinueOnError", False);
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructureExternalConnection, True);
	
	ExchangeSettingsStructureExternalConnection.Insert("ProcessedObjectsCount", 0);
	
	ExchangeSettingsStructureExternalConnection.Insert("StartDate",    Undefined);
	ExchangeSettingsStructureExternalConnection.Insert("EndDate", Undefined);
	
	ExchangeSettingsStructureExternalConnection.Insert("MessageOnExchange",      "");
	ExchangeSettingsStructureExternalConnection.Insert("ErrorMessageString", "");
	
	ExchangeSettingsStructureExternalConnection.Insert("TransactionItemsCount", Structure.TransactionItemsCount);
	
	ExchangeSettingsStructureExternalConnection.Insert("IsDIBExchange", False);
	
	ExchangeSettingsStructureExternalConnection.Insert("DataSynchronizationSetupCompleted",     False);
	ExchangeSettingsStructureExternalConnection.Insert("EmailReceivedForDataMapping",   False);
	ExchangeSettingsStructureExternalConnection.Insert("DataMappingSupported",         True);
	
	If ValueIsFilled(InfobaseNode) Then
		ExchangeSettingsStructureExternalConnection.DataSynchronizationSetupCompleted   = SynchronizationSetupCompleted(InfobaseNode);
		ExchangeSettingsStructureExternalConnection.EmailReceivedForDataMapping = MessageWithDataForMappingReceived(InfobaseNode);
		ExchangeSettingsStructureExternalConnection.DataMappingSupported = ExchangePlanSettingValue(Structure.ExchangePlanName,
			"DataMappingSupported", SavedExchangePlanNodeSettingOption(InfobaseNode));
	EndIf;
	
	Return ExchangeSettingsStructureExternalConnection;
EndFunction

Function GetObjectConversionRulesViaExternalConnection(ExchangePlanName, GetCorrespondentRules = False) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangePlanName, GetCorrespondentRules);
	
EndFunction

Procedure ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
		InfobaseNode, ActionOnExchange, ExchangeParameters)
	
	ParametersOnly = ExchangeParameters.ParametersOnly;
	
	SetPrivilegedMode(True);
	
	// INITIALIZING DATA EXCHANGE
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
		InfobaseNode, ActionOnExchange, Enums.ExchangeMessagesTransportTypes.WS, False);
	
	If ExchangeSettingsStructure.Cancel Then
		// If settings contain errors, canceling the exchange.
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła %1';de = 'Datenaustausch beginnt für Knoten %1';ro = 'Începutul procesului schimbului de date pentru nodul %1';tr = '%1Ünite için veri değişimi süreci başlatılıyor'; es_ES = 'Inicio de proceso de intercambio de datos para el nodo %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.DoDataImport Then
		
		If ExchangeSettingsStructure.UseLargeDataTransfer Then
			
			// {Handler: BeforeExchangeMessageRead} Start
			FileExchangeMessages = "";
			StandardProcessing = True;
			
			BeforeExchangeMessageRead(ExchangeSettingsStructure.InfobaseNode, FileExchangeMessages, StandardProcessing);
			// {Handler: BeforeExchangeMessageRead} End
			
			If StandardProcessing Then
				
				Proxy = Undefined;
				
				ProxyParameters = New Structure;
				ProxyParameters.Insert("AuthenticationParameters", ExchangeParameters.AuthenticationParameters);
				
				SetupStatus = Undefined;
				ErrorMessage  = "";
				InitializeWSProxyToManageDataExchange(Proxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);

				If Cancel Then
					WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
					ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
					AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
					Return;
				EndIf;
				
				FileExchangeMessages = "";
				
				Try
					
					Proxy.UploadData(ExchangeSettingsStructure.ExchangePlanName,
						ExchangeSettingsStructure.CurrentExchangePlanNodeCode,
						ExchangeParameters.FileID,
						ExchangeParameters.TimeConsumingOperation,
						ExchangeParameters.OperationID,
						ExchangeParameters.TimeConsumingOperationAllowed);
					
					If ExchangeParameters.TimeConsumingOperation Then
						WriteEventLogDataExchange(NStr("ru = 'Ожидание получения данных от базы-корреспондента...'; en = 'Waiting for data from the peer infobase...'; pl = 'Oczekiwanie odbioru danych z bazy korespondenta...';de = 'Ausstehende Daten von der Korrespondenzbasis...';ro = 'Datele în așteptare de la baza corespondentă...';tr = 'Muhabir tabandan veri bekleniyor ...'; es_ES = 'Datos pendientes de la base corresponsal...'",
							Common.DefaultLanguageCode()), ExchangeSettingsStructure);
						Return;
					EndIf;
					
					FileExchangeMessages = GetFileFromStorageInService(
						New UUID(ExchangeParameters.FileID),
						InfobaseNode,,
						ExchangeParameters.AuthenticationParameters);
				Except
					WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
					ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
					Cancel = True;
				EndTry;
				
			EndIf;
			
			If Not Cancel Then
				
				ReadMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages,, ParametersOnly);
				
			EndIf;
			
			// {Handler: AfterExchangeMessageRead} Start
			StandardProcessing = True;
			
			AfterExchangeMessageRead(
						ExchangeSettingsStructure.InfobaseNode,
						FileExchangeMessages,
						ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
						StandardProcessing,
						Not ParametersOnly);
			// {Handler: AfterExchangeMessageRead} End
			
			If StandardProcessing Then
				
				Try
					If Not IsBlankString(FileExchangeMessages) AND TypeOf(DataExchangeMessageFromMasterNode()) <> Type("Structure") Then
						DeleteFiles(FileExchangeMessages);
					EndIf;
				Except
					WriteLogEvent(EventLogMessageTextDataExchange(),
						EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
				EndTry;
				
			EndIf;
			
		Else
			
			Proxy = Undefined;
			
			ProxyParameters = New Structure;
			ProxyParameters.Insert("AuthenticationParameters", ExchangeParameters.AuthenticationParameters);
			
			SetupStatus = Undefined;
			ErrorMessage  = "";
			InitializeWSProxyToManageDataExchange(Proxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);

			If Cancel Then
				WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
				AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
				Return;
			EndIf;
			
			ExchangeMessageStorage = Undefined;
			Try
				Proxy.Upload(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode, ExchangeMessageStorage);
				ReadMessageWithNodeChanges(ExchangeSettingsStructure,, ExchangeMessageStorage.Get());
			Except
				WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			EndTry;
			
		EndIf;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		Proxy = Undefined;
		
		ProxyParameters = New Structure;
		ProxyParameters.Insert("AuthenticationParameters", ExchangeParameters.AuthenticationParameters);
		If ExchangeParameters.MessageForDataMapping Then
			ProxyParameters.Insert("EarliestVersion", "3.0.1.1");
		EndIf;
		
		SetupStatus = Undefined;
		ErrorMessage  = "";
		InitializeWSProxyToManageDataExchange(Proxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessage);
		
		If Cancel Then
			WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		If ExchangeSettingsStructure.UseLargeDataTransfer Then
			
			TempDirectory = GetTempFileName();
			CreateDirectory(TempDirectory);
			
			FileExchangeMessages = CommonClientServer.GetFullFileName(
				TempDirectory, UniqueExchangeMessageFileName());
			
			Try
				WriteMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages);
			Except
				WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				Cancel = True;
			EndTry;
			
			// Sending exchange message only if data is exported successfully.
			If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) AND Not Cancel Then
				
				Try
					
					FileIDAsString = String(PutFileInStorageInService(
						FileExchangeMessages, InfobaseNode,, ExchangeParameters.AuthenticationParameters));
					
					Try
						DeleteFiles(TempDirectory);
					Except
						WriteLogEvent(EventLogMessageTextDataExchange(),
							EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
					EndTry;
						
					If ExchangeParameters.MessageForDataMapping
						AND (SetupStatus.DataMappingSupported
							Or Not SetupStatus.DataSynchronizationSetupCompleted) Then
						Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.ExchangePlanName,
							ExchangeSettingsStructure.CurrentExchangePlanNodeCode,
							FileIDAsString);
					Else
						Proxy.DownloadData(ExchangeSettingsStructure.ExchangePlanName,
							ExchangeSettingsStructure.CurrentExchangePlanNodeCode,
							FileIDAsString,
							ExchangeParameters.TimeConsumingOperation,
							ExchangeParameters.OperationID,
							ExchangeParameters.TimeConsumingOperationAllowed);
					
						If ExchangeParameters.TimeConsumingOperation Then
							WriteEventLogDataExchange(NStr("ru = 'Ожидание загрузки данных в базе-корреспонденте...'; en = 'Waiting for data import in the peer infobase...'; pl = 'Oczekiwanie importu danych z bazy korespondenta...';de = 'Ausstehende Datenimport in der Korrespondenzbasis...';ro = 'Importul datelor în așteptare în baza corespondentă...';tr = 'Muhabir bazında veri içe aktarma bekleniyor ...'; es_ES = 'Importación de datos pendiente en la base corresponsal...'",
								Common.DefaultLanguageCode()), ExchangeSettingsStructure);
							Return;
						EndIf;
					EndIf;
					
				Except
					WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
					ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
					Cancel = True;
				EndTry;
				
			EndIf;
			
			Try
				DeleteFiles(TempDirectory);
			Except
				WriteLogEvent(EventLogMessageTextDataExchange(),
					EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			EndTry;
			
		Else
			
			ExchangeMessage = "";
			
			Try
				
				WriteMessageWithNodeChanges(ExchangeSettingsStructure,, ExchangeMessage);
				
				// Sending exchange message only if data is exported successfully.
				If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
					
					Proxy.Download(ExchangeSettingsStructure.ExchangePlanName,
						ExchangeSettingsStructure.CurrentExchangePlanNodeCode,
						New ValueStorage(ExchangeMessage, New Deflation(9)));
						
				EndIf;
				
			Except
				WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			EndTry;
			
		EndIf;
		
	EndIf;
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel, InfobaseNode,
	ActionOnExchange,
	TransactionItemsCount,
	MessageForDataMapping = False)
	
	SetPrivilegedMode(True);
	
	// INITIALIZING DATA EXCHANGE
	ExchangeSettingsStructure = ExchangeSettingsForExternalConnection(
		InfobaseNode,
		ActionOnExchange,
		TransactionItemsCount);
	
	WriteLogEventDataExchangeStart(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		// If settings contain errors, canceling the exchange.
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	ErrorMessageString = "";
	
	// Getting external connection for the infobase node.
	ExternalConnection = DataExchangeCached.GetExternalConnectionForInfobaseNode(
		InfobaseNode,
		ErrorMessageString);
	
	If ExternalConnection = Undefined Then
		
		// Adding the event log entry.
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		// If settings contain errors, canceling the exchange.
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	// Getting remote infobase version.
	SSLVersionByExternalConnection = ExternalConnection.StandardSubsystemsServer.LibraryVersion();
	ExchangeWithSSL20 = CommonClientServer.CompareVersions("2.1.1.10", SSLVersionByExternalConnection) > 0;
	
	// INITIALIZING DATA EXCHANGE (USING EXTERNAL CONNECTION)
	Structure = New Structure("ExchangePlanName, CurrentExchangePlanNodeCode, TransactionItemsCount");
	FillPropertyValues(Structure, ExchangeSettingsStructure);
	
	// Reversing enumeration values.
	ActionOnStringExchange = ?(ActionOnExchange = Enums.ActionsOnExchange.DataExport,
								Common.EnumValueName(Enums.ActionsOnExchange.DataImport),
								Common.EnumValueName(Enums.ActionsOnExchange.DataExport));
	//
	
	Structure.Insert("ActionOnStringExchange", ActionOnStringExchange);
	Structure.Insert("DebugMode", False);
	Structure.Insert("ExchangeProtocolFileName", "");
	
	IsXDTOExchangePlan = IsXDTOExchangePlan(InfobaseNode);
	If IsXDTOExchangePlan Then
		// Checking predefined node alias.
		PredefinedNodeAlias = PredefinedNodeAlias(InfobaseNode);
		ExchangePlanManager = ExternalConnection.ExchangePlans[Structure.ExchangePlanName];
		CheckNodeExistenceInCorrespondent = True;
		If ValueIsFilled(PredefinedNodeAlias) Then
			// You need to check the node code in the correspondent because it can be already re-encoded.
			// In this case, alias is not required.
			If ExchangePlanManager.FindByCode(PredefinedNodeAlias) <> ExchangePlanManager.EmptyRef() Then
				Structure.CurrentExchangePlanNodeCode = PredefinedNodeAlias;
				CheckNodeExistenceInCorrespondent = False;
			EndIf;
		EndIf;
		If CheckNodeExistenceInCorrespondent Then
			ExchangePlanRef = ExchangePlanManager.FindByCode(Structure.CurrentExchangePlanNodeCode);
			If NOT ValueIsFilled(ExchangePlanRef.Code) Then
				// If necessary, start migration to data synchronization via universal format.
				MessageText = NStr("ru = 'Необходим переход на синхронизацию данных через универсальный формат в базе-корреспонденте.'; en = 'Switching to the universal data synchronization format in the peer infobase is required.'; pl = 'Jest potrzebne przejście do synchronizacji danych za pomocą formatu uniwersalnego w bazie-korespondencie.';de = 'Es ist erforderlich, auf die Synchronisation von Daten über das Universalformat in der entsprechenden Datenbank umzuschalten.';ro = 'Este necesară trecerea la sincronizarea datelor prin format universal în baza-corespondentă.';tr = 'Muhabir veritabanında genel bir format üzerinden veri senkronizasyonu için bir geçiş gereklidir.'; es_ES = 'Es necesario pasar a la sincronización de datos a través del formato universal en la base-correspondiente.'");
				WriteEventLogDataExchange(MessageText, ExchangeSettingsStructure, False);

				ParametersStructure = New Structure();
				ParametersStructure.Insert("Code", Structure.CurrentExchangePlanNodeCode);
				ParametersStructure.Insert("SettingsMode", 
					Common.ObjectAttributeValue(InfobaseNode, "SettingsMode"));
				ParametersStructure.Insert("Error", False);
				ParametersStructure.Insert("ErrorMessage", "");
				
				HasErrors = False;
				ErrorMessageString = "";
				TransferResult = 
					ExchangePlanManager.MigrateToDataSyncViaUniversalFormatExternalConnection(ParametersStructure);
				If ParametersStructure.Error Then
					HasErrors = True;
					NString = NStr("ru = 'Ошибка при переходе на синхронизацию данных через универсальный формат: %1. Обмен отменен.'; en = 'An error occurred while switching to the universal data synchronization format: %1. The exchange is canceled.'; pl = 'Błąd podczas przejścia do synchronizacji danych za pomocą formatu uniwersalnego: %1. Wymiana została anulowana.';de = 'Fehler bei der Umstellung auf Datensynchronisation über das Universalformat: %1. Der Austausch wird abgebrochen.';ro = 'Eroare de trecere la sincronizarea datelor prin format universal: %1. Schimb revocat.';tr = 'Genel biçim üzerinden veri senkronizasyonu geçiş yaparken bir hata oluştu:%1 . Veri alışverişi iptal edildi.'; es_ES = 'Error al pasar a la sincronización de datos a través del formato universal: %1. Intercambio cancelado.'",
						Common.DefaultLanguageCode());
					ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, 
						ParametersStructure.ErrorMessage);
				ElsIf TransferResult = Undefined Then
					HasErrors = True;
					ErrorMessageString = NStr("ru = 'Переход на синхронизацию данных через универсальный формат не выполнен'; en = 'Switching to the universal data synchronization format was not performed.'; pl = 'Przejście do synchronizacji danych za pomocą formatu uniwersalnego nie jest wykonane';de = 'Der Übergang zur Synchronisation von Daten durch das Universalformat wird nicht durchgeführt';ro = 'Saltul la sincronizarea datelor prin format universal nu a fost executat';tr = 'Genel biçim üzerinden veri eşitlemeye geçiş başarısız oldu'; es_ES = 'No se ha pasado a la sincronización de datos a través del formato universal'");
				EndIf;
				If HasErrors Then
					WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
					ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
					AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
					Cancel = True;
					Return;
				Else
					Message = NStr("ru = 'Переход на синхронизацию данных через универсальный формат завершен успешно.'; en = 'Switching to the universal data synchronization format is completed.'; pl = 'Przejście do synchronizacji danych za pomocą formatu uniwersalnego jest zakończone pomyślnie.';de = 'Der Übergang zur Synchronisation von Daten über das Universalformat wurde erfolgreich abgeschlossen.';ro = 'Saltul la sincronizarea datelor prin format universal este executat cu succes.';tr = 'Genel biçim üzerinden veri eşitlemeye geçiş başarılı oldu.'; es_ES = 'Se ha pasado con éxito a la sincronización de datos a través del formato universal.'");
					WriteEventLogDataExchange(Message, ExchangeSettingsStructure, False);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Try
		ExchangeSettingsStructureExternalConnection = ExternalConnection.DataExchangeExternalConnection.ExchangeSettingsStructure(Structure);
	Except
		WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndTry;
	
	If ExchangeSettingsStructureExternalConnection.Property("DataSynchronizationSetupCompleted") Then
		If Not MessageForDataMapping
			AND ExchangeSettingsStructureExternalConnection.DataSynchronizationSetupCompleted = False Then
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для продолжения необходимо перейти в программу ""%1"" и завершить в ней настройку синхронизации.
				|Выполнение обмена данными отменено.'; 
				|en = 'To continue, open %1 and complete the synchronization setup there.
				|The data exchange is canceled.'; 
				|pl = 'Aby kontynuować, musisz przejść do programu ""%1"" i zakończyć w nim konfigurację synchronizacji.
				|Wymiana danych została anulowana.';
				|de = 'Um fortzufahren, gehen Sie zum Programm ""%1"" und beenden Sie die Synchronisationseinstellung darin.
				|Der Datenaustausch wird abgebrochen.';
				|ro = 'Pentru continuare trebuie să treceți în aplicația ""%1"" și să finalizați setarea sincronizării în ea.
				|Executarea schimbului de date este revocată.';
				|tr = 'Devam etmek için ""%1"" programına geçmeniz ve eşleşme ayarlarını tamamlamanız gerekir. 
				| Veri alışverişi iptal edildi.'; 
				|es_ES = 'Para continuar es necesario pasar al programa ""%1"" y terminar de ajustar la sincronización en él.
				|Ejecución de intercambio de datos cancelada.'"),
				ExchangeSettingsStructureExternalConnection.InfobaseNodeDescription);
			WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
			Cancel = True;
			Return;
			
		EndIf;
	EndIf;
	
	If ExchangeSettingsStructureExternalConnection.Property("EmailReceivedForDataMapping") Then
		If Not MessageForDataMapping
			AND ExchangeSettingsStructureExternalConnection.EmailReceivedForDataMapping = True Then
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для продолжения необходимо перейти в программу ""%1"" и выполнить загрузку сообщения для сопоставления данных.
				|Выполнение обмена данными отменено.'; 
				|en = 'To continue, open %1 and import the data mapping message.
				|The data exchange is canceled.'; 
				|pl = 'Aby kontynuować, musisz przejść do programu ""%1"" i pobrać wiadomość, aby dopasować dane.
				|Wymiana danych została anulowana.';
				|de = 'Um fortzufahren, müssen Sie zum Programm ""%1"" gehen und die Meldung herunterladen, um die Daten zu vergleichen.
				|Der Datenaustausch wurde abgebrochen.';
				|ro = 'Pentru continuare trebuie să treceți în aplicația ""%1"" și să executați importul mesajului pentru confruntarea datelor.
				|Executarea schimbului de date este revocată.';
				|tr = 'Devam etmek için ""%1"" programına geçmeniz ve veri karşılaştırmak için mesajı içe aktarmanız gerekir. 
				|Veri alışverişi iptal edildi.'; 
				|es_ES = 'Para continuar es necesario pasar al programa ""%1"" y cargar el mensaje para comparar los datos.
				|Ejecución de intercambio de datos cancelada.'"),
				ExchangeSettingsStructureExternalConnection.InfobaseNodeDescription);
			WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
			Cancel = True;
			Return;
			
		EndIf;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	ExchangeSettingsStructureExternalConnection.StartDate = ExternalConnection.CurrentSessionDate();
	
	ExternalConnection.DataExchangeExternalConnection.WriteLogEventDataExchangeStart(ExchangeSettingsStructureExternalConnection);
	// DATA EXCHANGE
	If ExchangeSettingsStructure.DoDataImport Then
		If NOT IsXDTOExchangePlan Then
			// Getting exchange rules from the correspondent infobase.
			ObjectsConversionRules = ExternalConnection.DataExchangeExternalConnection.GetObjectConversionRules(ExchangeSettingsStructureExternalConnection.ExchangePlanName);
			
			If ObjectsConversionRules = Undefined Then
				
				// Exchange rules must be specified.
				NString = NStr("ru = 'Не заданы правила конвертации во второй информационной базе для плана обмена %1. Обмен отменен.'; en = 'Conversion rules for exchange plan %1 are not specified in the second infobase. The exchange is canceled.'; pl = 'Reguły konwersji dla planu wymiany %1 nie są określone w drugiej bazie informacyjnej. Wymiana zostanie anulowana.';de = 'Konvertierungsregeln für den Austauschplan %1 sind in der zweiten Infobase nicht angegeben. Austausch wird abgebrochen.';ro = 'Normele de conversie pentru planul de schimb %1 nu sunt specificate în cea de-a doua informație. Schimbul este anulat.';tr = '%1Değişim planı için dönüşüm kuralları, ikinci veritabanında belirtilmemiştir. Değişim iptal edildi'; es_ES = 'Reglas de conversión para el plan de intercambio %1 no están especificadas en la segunda infobase. Intercambio se ha cancelado.'",
					Common.DefaultLanguageCode());
				ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, ExchangeSettingsStructureExternalConnection.ExchangePlanName);
				WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
				SetExchangeInitEnd(ExchangeSettingsStructure);
				Return;
			EndIf;
		EndIf;
		
		// Data processor for importing data.
		DataProcessorForDataImport = ExchangeSettingsStructure.DataExchangeDataProcessor;
		DataProcessorForDataImport.ExchangeFileName = "";
		DataProcessorForDataImport.ObjectsPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
		DataProcessorForDataImport.UseTransactions = (DataProcessorForDataImport.ObjectsPerTransaction <> 1);
		If NOT IsXDTOExchangePlan Then
			DataProcessorForDataImport.DataImportedOverExternalConnection = True;
		EndIf;
		
		// Getting the initialized data processor for exporting data.
		If IsXDTOExchangePlan Then
			DataExchangeDataProcessorExternalConnection = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
			DataExchangeDataProcessorExternalConnection.ExchangeMode = "DataExported";
		Else
			DataExchangeDataProcessorExternalConnection = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
			DataExchangeDataProcessorExternalConnection.SavedSettings = ObjectsConversionRules;
			DataExchangeDataProcessorExternalConnection.DataImportExecutedInExternalConnection = False;
			DataExchangeDataProcessorExternalConnection.ExchangeMode = "DataExported";
			Try
				DataExchangeDataProcessorExternalConnection.RestoreRulesFromInternalFormat();
			Except
				WriteEventLogDataExchange(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Возникла ошибка во второй информационной базе: %1'; en = 'An error occurred in the second infobase: %1'; pl = 'Wystąpił błąd w drugiej bazie informacyjnej: %1';de = 'In der zweiten Infobase ist ein Fehler aufgetreten: %1';ro = 'Eroare în a doua bază de informații: %1';tr = 'İkinci veritabanında bir hata oluştu:%1'; es_ES = 'Ha ocurrido un error en la segunda infobase: %1'"),
					DetailErrorDescription(ErrorInfo())), ExchangeSettingsStructure, True);
				
				// If settings contain errors, canceling the exchange.
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
				AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
				Cancel = True;
				Return;
			EndTry;
			// Specifying exchange nodes.
			DataExchangeDataProcessorExternalConnection.BackgroundExchangeNode = Undefined;
			DataExchangeDataProcessorExternalConnection.DoNotExportObjectsByRefs = True;
			DataExchangeDataProcessorExternalConnection.ExchangeRuleFileName = "1";
			DataExchangeDataProcessorExternalConnection.ExternalConnection = Undefined;
		EndIf;

		// Specifying exchange nodes (common for all exchange kinds).
		DataExchangeDataProcessorExternalConnection.NodeForExchange = ExchangeSettingsStructureExternalConnection.InfobaseNode;
		
		SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessorExternalConnection, ExchangeSettingsStructureExternalConnection, ExchangeWithSSL20);
		
		If NOT IsXDTOExchangePlan Then
			DestinationConfigurationVersion = "";
			SourceVersionFromRules = "";
			MessageText = "";
			ExternalConnectionParameters = New Structure;
			ExternalConnectionParameters.Insert("ExternalConnection", ExternalConnection);
			ExternalConnectionParameters.Insert("SSLVersionByExternalConnection", SSLVersionByExternalConnection);
			ExternalConnectionParameters.Insert("EventLogMessageKey", ExchangeSettingsStructureExternalConnection.EventLogMessageKey);
			ExternalConnectionParameters.Insert("InfobaseNode", ExchangeSettingsStructureExternalConnection.InfobaseNode);
			
			ObjectsConversionRules.Get().Conversion.Property("SourceConfigurationVersion", DestinationConfigurationVersion);
			DataProcessorForDataImport.SavedSettings.Get().Conversion.Property("SourceConfigurationVersion", SourceVersionFromRules);
			
			If DifferentCorrespondentVersions(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.EventLogMessageKey,
				SourceVersionFromRules, DestinationConfigurationVersion, MessageText, ExternalConnectionParameters) Then
				
				DataExchangeDataProcessorExternalConnection = Undefined;
				Return;
				
			EndIf;
		EndIf;
		// EXPORT (CORRESPONDENT) - IMPORT (CURRENT INFOBASE)
		DataExchangeDataProcessorExternalConnection.RunDataExport(DataProcessorForDataImport);
		
		// Commiting data exchange state.
		ExchangeSettingsStructure.ExchangeExecutionResult    = DataProcessorForDataImport.ExchangeExecutionResult();
		ExchangeSettingsStructure.ProcessedObjectsCount = DataProcessorForDataImport.ImportedObjectCounter();
		ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString = DataExchangeDataProcessorExternalConnection.ExchangeExecutionResultString();
		ExchangeSettingsStructureExternalConnection.ProcessedObjectsCount     = DataExchangeDataProcessorExternalConnection.ExportedObjectCounter();
		ExchangeSettingsStructure.MessageOnExchange           = DataProcessorForDataImport.CommentOnDataImport;
		ExchangeSettingsStructure.ErrorMessageString      = DataProcessorForDataImport.ErrorMessageString();
		ExchangeSettingsStructureExternalConnection.MessageOnExchange               = DataExchangeDataProcessorExternalConnection.CommentOnDataExport;
		ExchangeSettingsStructureExternalConnection.ErrorMessageString          = DataExchangeDataProcessorExternalConnection.ErrorMessageString();
		
		DataExchangeDataProcessorExternalConnection = Undefined;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		// Data processor for importing data.
		If IsXDTOExchangePlan Then
			DataProcessorForDataImport = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
		Else
			DataProcessorForDataImport = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
			DataProcessorForDataImport.DataImportedOverExternalConnection = True;
		EndIf;
		DataProcessorForDataImport.ExchangeMode = "Load";
		DataProcessorForDataImport.ExchangeNodeDataImport = ExchangeSettingsStructureExternalConnection.InfobaseNode;
		
		SetCommonParametersForDataExchangeProcessing(DataProcessorForDataImport, ExchangeSettingsStructureExternalConnection, ExchangeWithSSL20);
		
		HasMappingSupport            = True;
		DataSynchronizationSetupCompleted = True;
		InterfaceVersions = InterfaceVersionsThroughExternalConnection(ExternalConnection);
		If InterfaceVersions.Find("3.0.1.1") <> Undefined Then
			ErrorMessage = "";
			InfobaseParameters = ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_2_0_1_6(
				ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode, ErrorMessage);
			CorrespondentParameters = Common.ValueFromXMLString(InfobaseParameters);
			If CorrespondentParameters.Property("DataMappingSupported") Then
				HasMappingSupport = CorrespondentParameters.DataMappingSupported;
			EndIf;
			If CorrespondentParameters.Property("DataSynchronizationSetupCompleted") Then
				DataSynchronizationSetupCompleted = CorrespondentParameters.DataSynchronizationSetupCompleted;
			EndIf;
		EndIf;
		
		If MessageForDataMapping
			AND (HasMappingSupport Or Not DataSynchronizationSetupCompleted) Then
			DataProcessorForDataImport.DataImportMode = "ImportMessageForDataMapping";
		EndIf;
		
		DataProcessorForDataImport.ObjectsPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
		DataProcessorForDataImport.UseTransactions = (DataProcessorForDataImport.ObjectsPerTransaction <> 1);
		
		// Getting the initialized data processor for exporting data.
		DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
		DataExchangeXMLDataProcessor.ExchangeFileName = "";
		
		If Not IsXDTOExchangePlan Then
			
			DataExchangeXMLDataProcessor.ExternalConnection = ExternalConnection;
			DataExchangeXMLDataProcessor.DataImportExecutedInExternalConnection = True;
			
		EndIf;
		
		// EXPORT (THIS INFOBASE) - IMPORT (CORRESPONDENT)
		DataExchangeXMLDataProcessor.RunDataExport(DataProcessorForDataImport);
		
		// Commiting data exchange state.
		ExchangeSettingsStructure.ExchangeExecutionResult    = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
		ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ExportedObjectCounter();
		ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString = DataProcessorForDataImport.ExchangeExecutionResultString();
		ExchangeSettingsStructureExternalConnection.ProcessedObjectsCount     = DataProcessorForDataImport.ImportedObjectCounter();
		ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataExport;
		ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
		ExchangeSettingsStructureExternalConnection.MessageOnExchange               = DataProcessorForDataImport.CommentOnDataImport;
		ExchangeSettingsStructureExternalConnection.ErrorMessageString          = DataProcessorForDataImport.ErrorMessageString();
		DataProcessorForDataImport = Undefined;
		
	EndIf;
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
	ExternalConnection.DataExchangeExternalConnection.AddExchangeCompletionEventLogMessage(ExchangeSettingsStructureExternalConnection);
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

Procedure ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure, Val ParametersOnly = False)
	
	If ExchangeSettingsStructure.DoDataImport Then
		
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
			ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		// {Handler: BeforeExchangeMessageRead} Start
		ExchangeMessage = "";
		StandardProcessing = True;
		
		BeforeExchangeMessageRead(ExchangeSettingsStructure.InfobaseNode, ExchangeMessage, StandardProcessing);
		// {Handler: BeforeExchangeMessageRead} End
		
		If StandardProcessing Then
			
			ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
			
			If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
				
				ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure);
				
				If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
					
					ExchangeMessage = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// Data is imported only if the exchange message is received successfully.
		If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
			
			HasMappingSupport = ExchangePlanSettingValue(
				DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode),
				"DataMappingSupported",
				SavedExchangePlanNodeSettingOption(ExchangeSettingsStructure.InfobaseNode));
			
			If ExchangeSettingsStructure.AdditionalParameters.Property("MessageForDataMapping")
				AND (HasMappingSupport 
					Or Not SynchronizationSetupCompleted(ExchangeSettingsStructure.InfobaseNode)) Then
				
				NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
					TempFilesStorageDirectory(),
					UniqueExchangeMessageFileName());
					
				// Saving a new message for data mapping.
				FileID = PutFileInStorage(NameOfFileToPutInStorage);
				MoveFile(ExchangeMessage, NameOfFileToPutInStorage);
				
				DataExchangeInternal.PutMessageForDataMapping(
					ExchangeSettingsStructure.InfobaseNode, FileID);
				
				StandardProcessing = True;
			Else
				
				ReadMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeMessage, , ParametersOnly);
				
				// {Handler: AfterExchangeMessageRead} Start
				StandardProcessing = True;
				
				AfterExchangeMessageRead(
							ExchangeSettingsStructure.InfobaseNode,
							ExchangeMessage,
							ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
							StandardProcessing,
							Not ParametersOnly);
				// {Handler: AfterExchangeMessageRead} End
				
			EndIf;
			
		EndIf;
		
		// {Handler: AfterExchangeMessageRead} Start
		StandardProcessing = True;
		
		AfterExchangeMessageRead(
					ExchangeSettingsStructure.InfobaseNode,
					ExchangeMessage,
					ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
					StandardProcessing,
					Not ParametersOnly);
		// {Handler: AfterExchangeMessageRead} End
		
		If StandardProcessing Then
			
			ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
			
		EndIf;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
			ExecuteDataExchangeWithExternalSystemExportXDTOSettings(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
		
		// Exporting data.
		If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
			
			WriteMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName());
			
		EndIf;
		
		// Sending exchange message only if data is exported successfully.
		If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
			
			ExecuteExchangeMessageTransportSending(ExchangeSettingsStructure);
			
		EndIf;
		
		ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

Procedure BeforeExchangeMessageRead(Val Recipient, ExchangeMessage, StandardProcessing)
	
	If IsSubordinateDIBNode()
		AND TypeOf(MasterNode()) = TypeOf(Recipient) Then
		
		SavedExchangeMessage = DataExchangeMessageFromMasterNode();
		
		If TypeOf(SavedExchangeMessage) = Type("BinaryData") Then
			// Converting to a new storage format and re-reading the DataExchangeMessageFromMasterNode constant 
			// value.
			SetDataExchangeMessageFromMasterNode(SavedExchangeMessage, Recipient);
			SavedExchangeMessage = DataExchangeMessageFromMasterNode();
		EndIf;
		
		If TypeOf(SavedExchangeMessage) = Type("Structure") Then
			
			StandardProcessing = False;
			
			ExchangeMessage = SavedExchangeMessage.PathToFile;
			
			WriteDataReceiveEvent(Recipient, NStr("ru = 'Сообщение обмена получено из кэша.'; en = 'An exchange message is received from the cache.'; pl = 'Wiadomość wymiany została odebrana z pamięci podręcznej.';de = 'Die Austauschnachricht wurde vom Cache empfangen.';ro = 'Mesajul de schimb a fost primit din memoria cache.';tr = 'Değişim mesajı önbellekten alındı.'; es_ES = 'El mensaje de intercambio se ha recibido del caché.'"));
			
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache", True);
			SetPrivilegedMode(False);
			
		Else
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache", False);
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AfterExchangeMessageRead(Val Recipient, Val ExchangeMessage, Val MessageRead, StandardProcessing, Val DeleteMessage = True)
	
	If IsSubordinateDIBNode()
		AND TypeOf(MasterNode()) = TypeOf(Recipient) Then
		
		If Not MessageRead
		   AND DataExchangeInternal.DataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache") Then
			// Cannot read the message received from cache. Cache requires cleaning.
			ClearDataExchangeMessageFromMasterNode();
			Return;
		EndIf;
		
		UpdateCachedMessage = False;
		
		If ConfigurationChanged() Then
			
			// If obsolete exchange message is stored in the cache, cached values must be updated, because 
			// configuration can be changed again.
			// 
			UpdateCachedMessage = True;
			
			If Not MessageRead Then
				
				If NOT Constants.LoadDataExchangeMessage.Get() Then
					Constants.LoadDataExchangeMessage.Set(True);
				EndIf;
				
			EndIf;
			
		Else
			
			If DeleteMessage Then
				
				ClearDataExchangeMessageFromMasterNode();
				If Constants.LoadDataExchangeMessage.Get() Then
					Constants.LoadDataExchangeMessage.Set(False);
				EndIf;
				
			Else
				// Exchange message can be read without importing metadata. After reading the application parameters, 
				// the exchange message is to be saved so that not to import it again for basic reading.
				// 
				UpdateCachedMessage = True;
			EndIf;
			
		EndIf;
		
		If UpdateCachedMessage Then
			
			PreviousMessage = DataExchangeMessageFromMasterNode();
			
			UpdateCachedValues = False;
			NewMessage = New BinaryData(ExchangeMessage);
			
			StructureType = TypeOf(PreviousMessage) = Type("Structure");
			
			If StructureType Or TypeOf(PreviousMessage) = Type("BinaryData") Then
				
				If StructureType Then
					PreviousMessage = New BinaryData(PreviousMessage.PathToFile);
				EndIf;
				
				If PreviousMessage.Size() <> NewMessage.Size() Then
					UpdateCachedValues = True;
				ElsIf NewMessage <> PreviousMessage Then
					UpdateCachedValues = True;
				EndIf;
				
			Else
				
				UpdateCachedValues = True;
				
			EndIf;
			
			If UpdateCachedValues Then
				SetDataExchangeMessageFromMasterNode(NewMessage, Recipient);
			EndIf;
		EndIf;
		
	EndIf;
	
	If MessageRead AND Common.SeparatedDataUsageAvailable() Then
		InformationRegisters.DataSyncEventHandlers.ExecuteHandlers(Recipient, "AfterGetData");
	EndIf;
	
EndProcedure

// Writes infobase node changes to file in the temporary directory.
//
// Parameters:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
// 
Procedure WriteMessageWithNodeChanges(ExchangeSettingsStructure, Val ExchangeMessageFileName = "", ExchangeMessage = "")
	
	If ExchangeSettingsStructure.IsDIBExchange Then // Performing exchange in DIB.
		
		Cancel = False;
		ErrorMessage = "";
		
		// Getting the exchange data processor.
		DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
		
		// Specifying the name of the exchange message file to be read.
		DataExchangeDataProcessor.SetExchangeMessageFileName(ExchangeMessageFileName);
		
		DataExchangeDataProcessor.RunDataExport(Cancel, ErrorMessage);
		
		If Cancel Then
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessage;
			
		EndIf;
		
	Else
		
		// {Handler: OnDataExport} Start. Overriding the standard export data processor.
		StandardProcessing = True;
		ProcessedObjectsCount = 0;
		
		Try
			OnSSLDataExportHandler(StandardProcessing,
											ExchangeSettingsStructure.InfobaseNode,
											ExchangeMessageFileName,
											ExchangeMessage,
											ExchangeSettingsStructure.TransactionItemsCount,
											ExchangeSettingsStructure.EventLogMessageKey,
											ProcessedObjectsCount);
			
			If StandardProcessing = True Then
				
				ProcessedObjectsCount = 0;
				
				OnDataExportHandler(StandardProcessing,
												ExchangeSettingsStructure.InfobaseNode,
												ExchangeMessageFileName,
												ExchangeMessage,
												ExchangeSettingsStructure.TransactionItemsCount,
												ExchangeSettingsStructure.EventLogMessageKey,
												ProcessedObjectsCount);
				
			EndIf;
			
		Except
			
			ErrorMessageString = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
					ExchangeSettingsStructure.InfobaseNode.Metadata(), 
					ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
			Return;
		EndTry;
		
		If StandardProcessing = False Then
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			Return;
		EndIf;
		// {Handler: OnDataExport} End
		
		// Universal exchange (exchange using conversion rules).
		If ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
			
			GenerateExchangeMessage = IsBlankString(ExchangeMessageFileName);
			If GenerateExchangeMessage Then
				ExchangeMessageFileName = GetTempFileName(".xml");
			EndIf;
			
			// Getting the initialized exchange data processor.
			DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
			DataExchangeXMLDataProcessor.ExchangeFileName = ExchangeMessageFileName;
			
			// Exporting data.
			Try
				DataExchangeXMLDataProcessor.RunDataExport();
			Except
				ErrorMessageString = DetailErrorDescription(ErrorInfo());
			
				WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
						ExchangeSettingsStructure.InfobaseNode.Metadata(), 
						ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
				Return;
			EndTry;
			
			If GenerateExchangeMessage Then
				TextFile = New TextDocument;
				TextFile.Read(ExchangeMessageFileName, TextEncoding.UTF8);
				ExchangeMessage = TextFile.GetText();
				DeleteFiles(ExchangeMessageFileName);
			EndIf;
			
			ExchangeSettingsStructure.ExchangeExecutionResult = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
			
			// Commiting data exchange state.
			ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ExportedObjectCounter();
			ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataExport;
			ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
			
		Else // Standard exchange (platform serialization).
			
			Cancel = False;
			ProcessedObjectsCount = 0;
			
			Try
				ExecuteStandardNodeChangeExport(Cancel,
									ExchangeSettingsStructure.InfobaseNode,
									ExchangeMessageFileName,
									ExchangeMessage,
									ExchangeSettingsStructure.TransactionItemsCount,
									ExchangeSettingsStructure.EventLogMessageKey,
									ProcessedObjectsCount);
			Except
				ErrorMessageString = DetailErrorDescription(ErrorInfo());
			
				WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
						ExchangeSettingsStructure.InfobaseNode.Metadata(), 
						ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
				ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
				Cancel = True;
			EndTry;
			
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			
			If Cancel Then
				
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Gets an exchange message with new data and imports the data to the infobase.
//
// Parameters:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
// 
Procedure ReadMessageWithNodeChanges(ExchangeSettingsStructure,
		Val ExchangeMessageFileName = "", ExchangeMessage = "", Val ParametersOnly = False)
	
	If ExchangeSettingsStructure.IsDIBExchange Then // Performing exchange in DIB.
		
		Cancel = False;
		
		// Getting the exchange data processor.
		DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
		
		// Specifying the name of the exchange message file to be read.
		DataExchangeDataProcessor.SetExchangeMessageFileName(ExchangeMessageFileName);
		
		DataExchangeDataProcessor.RunDataImport(Cancel, ParametersOnly);
		
		If Cancel Then
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			
		EndIf;
		
	Else
		
		// {Handler: OnDataImport} Start. Overriding the standard import data processor.
		StandardProcessing = True;
		ProcessedObjectsCount = 0;
		
		Try
			OnSSLDataImportHandler(StandardProcessing,
											ExchangeSettingsStructure.InfobaseNode,
											ExchangeMessageFileName,
											ExchangeMessage,
											ExchangeSettingsStructure.TransactionItemsCount,
											ExchangeSettingsStructure.EventLogMessageKey,
											ProcessedObjectsCount);
			
			If StandardProcessing = True Then
				
				ProcessedObjectsCount = 0;
				
				OnDataImportHandler(StandardProcessing,
												ExchangeSettingsStructure.InfobaseNode,
												ExchangeMessageFileName,
												ExchangeMessage,
												ExchangeSettingsStructure.TransactionItemsCount,
												ExchangeSettingsStructure.EventLogMessageKey,
												ProcessedObjectsCount);
				
			EndIf;
			
		Except
			ErrorMessageString = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
					ExchangeSettingsStructure.InfobaseNode.Metadata(), 
					ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
			Return;
		EndTry;
		
		If StandardProcessing = False Then
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			Return;
		EndIf;
		// {Handler: OnDataImport} End
		
		// Universal exchange (exchange using conversion rules).
		If ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
			
			// Getting the initialized exchange data processor.
			DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
			DataExchangeXMLDataProcessor.ExchangeFileName = ExchangeMessageFileName;
			
			// Importing data.
			If DataExchangeCached.IsXDTOExchangePlan(ExchangeSettingsStructure.ExchangePlanName) Then
				ImportParameters = New Structure;
				ImportParameters.Insert("DataExchangeWithExternalSystem",
					ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem);
				
				DataExchangeXMLDataProcessor.RunDataImport(ImportParameters);
				
				DataReceivedForMapping = False;
				If Not DataExchangeXMLDataProcessor.ExchangeComponents.ErrorFlag Then
					DataReceivedForMapping = (DataExchangeXMLDataProcessor.ExchangeComponents.IncomingMessageNumber > 0
						AND DataExchangeXMLDataProcessor.ExchangeComponents.MessageNumberReceivedByCorrespondent = 0);
				EndIf;
				ExchangeSettingsStructure.AdditionalParameters.Insert("DataReceivedForMapping", DataReceivedForMapping);
			Else
				DataExchangeXMLDataProcessor.RunDataImport();
			EndIf;
			
			ExchangeSettingsStructure.ExchangeExecutionResult = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
			
			// Commiting data exchange state.
			ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ImportedObjectCounter();
			ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataImport;
			ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
			
		Else // Standard exchange (platform serialization).
			
			ProcessedObjectsCount = 0;
			ExchangeExecutionResult = Undefined;
			
			ExecuteStandardNodeChangeImport(
				ExchangeSettingsStructure.InfobaseNode,
				ExchangeMessageFileName,
				ExchangeMessage,
				ExchangeSettingsStructure.TransactionItemsCount,
				ExchangeSettingsStructure.EventLogMessageKey,
				ProcessedObjectsCount,
				ExchangeExecutionResult);
			
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			ExchangeSettingsStructure.ExchangeExecutionResult = ExchangeExecutionResult;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure)
	
	TempDirectoryName = CreateTempExchangeMessagesDirectory();
	
	MessageFileName = CommonClientServer.GetFullFileName(
		TempDirectoryName, UniqueExchangeMessageFileName());
		
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	MessageReceived = False;
	Try
		MessageReceived = ExchangeMessageTransportDataProcessor.GetMessage(MessageFileName);
	Except
		Information = ErrorInfo();
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
		WriteEventLogDataExchange(DetailErrorDescription(Information), ExchangeSettingsStructure, True);
	EndTry;
	
	MessageProcessed = False;
	ExecuteHandlerAfterImport = False;
	
	If MessageReceived
		AND ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		
		ExecuteHandlerAfterImport = True;
		
		ReadMessageWithNodeChanges(ExchangeSettingsStructure, MessageFileName);
		
		MessageProcessed = ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult);
		
	EndIf;
	
	Try
		DeleteFiles(TempDirectoryName);
	Except
		WriteEventLogDataExchange(DetailErrorDescription(Information), ExchangeSettingsStructure);
	EndTry;
	
	SetupCompleted = SynchronizationSetupCompleted(ExchangeSettingsStructure.InfobaseNode);
	
	If ExecuteHandlerAfterImport Then
		HasNextMessage = False;
		Try
			ExchangeMessageTransportDataProcessor.AfterProcessReceivedMessage(MessageProcessed, HasNextMessage);
		Except
			Information = ErrorInfo();
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
			WriteEventLogDataExchange(DetailErrorDescription(Information), ExchangeSettingsStructure, True);
			HasNextMessage = False;
		EndTry;
		
		If MessageProcessed
			AND Not SetupCompleted Then
			
			ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
			
			If HasExchangePlanManagerAlgorithm("BeforeDataSynchronizationSetup", ExchangePlanName) Then
		
				Context = New Structure;
				Context.Insert("Correspondent",          ExchangeSettingsStructure.InfobaseNode);
				Context.Insert("SettingID", SavedExchangePlanNodeSettingOption(ExchangeSettingsStructure.InfobaseNode));
				Context.Insert("InitialSetting",     Not SetupCompleted);
				
				WizardFormName  = "";
				
				ExchangePlans[ExchangePlanName].BeforeDataSynchronizationSetup(Context, SetupCompleted, WizardFormName);
				
				If SetupCompleted Then
					CompleteDataSynchronizationSetup(ExchangeSettingsStructure.InfobaseNode);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If HasNextMessage AND SetupCompleted Then
			ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
			ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ExecuteDataExchangeWithExternalSystemExportXDTOSettings(ExchangeSettingsStructure)
	
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
		
	XDTOSettings = New Structure;
	XDTOSettings.Insert("ExchangeFormat",
		ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat"));
	XDTOSettings.Insert("SupportedVersions",
		DataExchangeXDTOServer.ExhangeFormatVersionsArray(ExchangeSettingsStructure.InfobaseNode));
	XDTOSettings.Insert("SupportedObjects",
		DataExchangeXDTOServer.SupportedObjectsInFormat(ExchangePlanName, , ExchangeSettingsStructure.InfobaseNode));
	
	Try
		ExchangeMessageTransportDataProcessor.SendXDTOSettings(XDTOSettings);
	Except
		Information = ErrorInfo();
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
		WriteEventLogDataExchange(DetailErrorDescription(Information), ExchangeSettingsStructure, True);
	EndTry;
	
EndProcedure

#EndRegion

#Region SerializationMethodsExchangeExecution

// Records changes for the exchange message.
// Can be applied if the infobases have the same metadata structure for all objects involved in the exchange.
//
Procedure ExecuteStandardNodeChangeExport(Cancel,
							InfobaseNode,
							FileName,
							ExchangeMessage,
							TransactionItemsCount = 0,
							EventLogMessageKey = "",
							ProcessedObjectsCount = 0)
	
	XMLWriter = New XMLWriter;	
	If Not IsBlankString(FileName) Then
		XMLWriter.OpenFile(FileName);
	Else
		XMLWriter.SetString();
	EndIf;
	XMLWriter.WriteXMLDeclaration();
	
	// Creating a new message.
	WriteMessage = ExchangePlans.CreateMessageWriter();
	
	WriteMessage.BeginWrite(XMLWriter, InfobaseNode);
	
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	PredefinedItemsTable = DataExchangeInternal.PredefinedDataTable();
	PredefinedItemsTable.Columns.Add("ExportData", New TypeDescription("Boolean"));
	PredefinedItemsTable.Indexes.Add("Ref");
	
	// Getting changed data selection.
	ChangesSelection = SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo);
	
	If IsBlankString(EventLogMessageKey) Then
		EventLogMessageKey = EventLogMessageTextDataExchange();
	EndIf;
	
	RecipientObject = InfobaseNode.GetObject();
	
	ExportParameters = New Structure;
	ExportParameters.Insert("XMLWriter",                      XMLWriter);
	ExportParameters.Insert("Recipient",                     RecipientObject);
	ExportParameters.Insert("InitialDataExport",        InitialDataExportFlagIsSet(InfobaseNode));
	ExportParameters.Insert("TransactionItemsCount", TransactionItemsCount);
	ExportParameters.Insert("ProcessedObjectsCount",   ProcessedObjectsCount);
	ExportParameters.Insert("PredefinedItemsTable",        PredefinedItemsTable);
	
	UseTransactions = TransactionItemsCount <> 1;
	
	ContinueExport = True;
	If UseTransactions Then
		While ContinueExport Do
			BeginTransaction();
			Try
				ExecuteStandardDataBatchExport(ChangesSelection, ExportParameters, ContinueExport);
				CommitTransaction();
			Except
				RollbackTransaction();
				
				WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
					InfobaseNode.Metadata(), InfobaseNode, DetailErrorDescription(ErrorInfo()));
				Cancel = True;
				Break;
			EndTry;
		EndDo;
	Else
		Try
			While ContinueExport Do
				ExecuteStandardDataBatchExport(ChangesSelection, ExportParameters, ContinueExport);
			EndDo;
		Except
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode, DetailErrorDescription(ErrorInfo()));
			Cancel = True;
		EndTry;
	EndIf;
	
	If Cancel Then
		WriteMessage.CancelWrite();
		XMLWriter.Close();
		Return;
	EndIf;
	
	ExportPredefinedItemsTable(ExportParameters);
	
	WriteMessage.EndWrite();
	ExchangeMessage = XMLWriter.Close();
	
	ProcessedObjectsCount = ExportParameters.ProcessedObjectsCount;
	
EndProcedure

Procedure ExecuteStandardDataBatchExport(ChangesSelection, ExportParameters, ContinueExport)
	
	WrittenItemsCount = 0;
	
	While (ExportParameters.TransactionItemsCount = 0
			Or WrittenItemsCount <= ExportParameters.TransactionItemsCount)
		AND ChangesSelection.Next() Do
		
		Data = ChangesSelection.Get();
		
		// Checking whether the object passes the ORR filter. If the object does not pass the ORR filter, 
		// sending object deletion to the target infobase. If the object is a record set, verifying each 
		// record. All record sets are exported, even empty ones. An empty set is the object deletion analog.
		// 
		ItemSending = DataItemSend.Auto;
		
		StandardSubsystemsServer.OnSendDataToSlave(Data, ItemSending, ExportParameters.InitialDataExport, ExportParameters.Recipient);
		
		If ItemSending = DataItemSend.Delete Then
			
			If Common.IsRegister(Data.Metadata()) Then
				
				// Sending an empty record set upon the register deletion.
				
			Else
				
				Data = New ObjectDeletion(Data.Ref);
				
			EndIf;
			
		ElsIf ItemSending = DataItemSend.Ignore Then
			
			Continue;
			
		EndIf;
		
		// Writing data to the message.
		WriteXML(ExportParameters.XMLWriter, Data);
		WrittenItemsCount = WrittenItemsCount + 1;
		
		DataExchangeInternal.MarkRefsToPredefinedData(Data, ExportParameters.PredefinedItemsTable);
		
	EndDo;
	
	ContinueExport = (WrittenItemsCount > 0);
	
	ExportParameters.ProcessedObjectsCount = ExportParameters.ProcessedObjectsCount + WrittenItemsCount;
	
EndProcedure

Procedure ExportPredefinedItemsTable(ExportParameters)
	
	ExportParameters.PredefinedItemsTable.Sort("TableName");
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-8");
	
	XMLWriter.WriteStartElement("PredefinedData");
	
	CountExported = 0;
	
	For Each PredefinedItemsRow In ExportParameters.PredefinedItemsTable Do
		If Not PredefinedItemsRow.ExportData Then
			Continue;
		EndIf;
		
		XMLWriter.WriteStartElement(PredefinedItemsRow.XMLTypeName);
		XMLWriter.WriteAttribute("PredefinedDataName", PredefinedItemsRow.PredefinedDataName);
		XMLWriter.WriteText(XMLString(PredefinedItemsRow.Ref));
		XMLWriter.WriteEndElement();
		
		CountExported = CountExported + 1;
	EndDo;
	
	XMLWriter.WriteEndElement(); // PredefinedData
	
	PredefinedItemsComment = XMLWriter.Close();
	
	If CountExported > 0 Then
		ExportParameters.XMLWriter.WriteComment(PredefinedItemsComment);
	EndIf;
	
EndProcedure

// The procedure for reading changes from the exchange message.
// Can be applied if the infobases have the same metadata structure for all objects involved in the exchange.
//
Procedure ExecuteStandardNodeChangeImport(
		InfobaseNode,
		FileName,
		ExchangeMessage,
		TransactionItemsCount,
		EventLogMessageKey,
		ProcessedObjectsCount,
		ExchangeExecutionResult)
		
	If IsBlankString(EventLogMessageKey) Then
		EventLogMessageKey = EventLogMessageTextDataExchange();
	EndIf;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("InfobaseNode",       InfobaseNode);
	ImportParameters.Insert("ExchangeMessage",              ExchangeMessage);
	ImportParameters.Insert("FileName",                     FileName);
	ImportParameters.Insert("XMLReader",                    Undefined);
	ImportParameters.Insert("MessageReader",              Undefined);
	
	ImportParameters.Insert("TransactionItemsCount", TransactionItemsCount);
	ImportParameters.Insert("ProcessedObjectsCount",   0);
	
	PredefinedItemsTable = DataExchangeInternal.PredefinedDataTable();
	PredefinedItemsTable.Columns.Add("SourceRef");
	PredefinedItemsTable.Columns.Add("OriginalReferenceFilled", New TypeDescription("Boolean"));
	
	ImportParameters.Insert("PredefinedItemsTable", PredefinedItemsTable);
	
	ErrorMessage = "";
	FillInitialRefsInPredefinedDataTable(ImportParameters, ErrorMessage);
	
	ImportParameters.PredefinedItemsTable = PredefinedItemsTable.Copy(New Structure("OriginalReferenceFilled", True));
	ImportParameters.PredefinedItemsTable.Indexes.Add("SourceRef");
	PredefinedItemsTable = Undefined;
	
	If Not IsBlankString(ErrorMessage) Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
	EndIf;
	
	InitializeMessageReaderForStandardImport(ImportParameters, ExchangeExecutionResult, ErrorMessage);
	
	If ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
		Return;
	ElsIf ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
		Return;
	EndIf;
	
	XMLReader       = ImportParameters.XMLReader;
	MessageReader = ImportParameters.MessageReader;
	
	BackupParameters = BackupParameters(MessageReader.Sender, MessageReader.ReceivedNo);
	
	// Deleting changes registration for the sender node.
	If Not BackupParameters.BackupRestored Then
		ExchangePlans.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
		InformationRegisters.CommonInfobasesNodesSettings.ClearInitialDataExportFlag(
			MessageReader.Sender, MessageReader.ReceivedNo);
	EndIf;
		
	UseTransactions = TransactionItemsCount <> 1;
	
	ContinueImport = True;
	If UseTransactions Then
		While ContinueImport Do
			DataExchangeInternal.DisableAccessKeysUpdate(True);
			BeginTransaction();
			Try
				ExecuteStandardDataBatchImport(ImportParameters, ContinueImport);
				DataExchangeInternal.DisableAccessKeysUpdate(False);
				CommitTransaction();
			Except
				RollbackTransaction();
				DataExchangeInternal.DisableAccessKeysUpdate(False, False);
				
				ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
					InfobaseNode.Metadata(), InfobaseNode, DetailErrorDescription(ErrorInfo()));
				Break;
			EndTry;
		EndDo;
	Else
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		Try
			While ContinueImport Do
				ExecuteStandardDataBatchImport(ImportParameters, ContinueImport);
			EndDo;
			DataExchangeInternal.DisableAccessKeysUpdate(False);
		Except
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	If ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error Then
		MessageReader.CancelRead();
	Else
		// Skipping all non-standard items in message body.
		CurrentNodeName = "";
		While MessageReader.XMLReader.NodeType = XMLNodeType.StartElement
			Or (MessageReader.XMLReader.NodeType = XMLNodeType.EndElement
				AND MessageReader.XMLReader.Name = CurrentNodeName) Do
			CurrentNodeName = MessageReader.XMLReader.Name;
			MessageReader.XMLReader.Skip();
		EndDo;
		
		Try
			MessageReader.EndRead();
			OnRestoreFromBackup(BackupParameters);
		Except
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode, DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	XMLReader.Close();
	
	ProcessedObjectsCount = ImportParameters.ProcessedObjectsCount;
	
EndProcedure

Procedure FillInitialRefsInPredefinedDataTable(ImportParameters, ErrorMessage)
	
	XMLReader = New XMLReader;
	ReaderSettings = New XMLReaderSettings(, , , , , , , False); // reading considering comments
	Try
		If Not IsBlankString(ImportParameters.ExchangeMessage) Then
			XMLReader.SetString(ImportParameters.ExchangeMessage, ReaderSettings);
		Else
			XMLReader.OpenFile(ImportParameters.FileName, ReaderSettings);
		EndIf;
		
		IsBody = False;
		While XMLReader.Read() Do
			If XMLReader.NodeType = XMLNodeType.StartElement Then
				If XMLReader.LocalName = "Message" Then
					Continue;
				ElsIf XMLReader.LocalName = "Header" Then
					XMLReader.Skip();
				ElsIf XMLReader.LocalName = "Body" Then
					IsBody = True;
					Continue;
				ElsIf IsBody AND CanReadXML(XMLReader) Then
					XMLReader.Skip();
				ElsIf IsBody AND XMLReader.LocalName = "PredefinedData" Then
					ProcessPredefinedItemsSectionInExchangeMessages(
						XMLReader, ImportParameters.PredefinedItemsTable);
				EndIf;
			ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
				If XMLReader.LocalName = "Message" Then
					Break;
				ElsIf XMLReader.LocalName = "Header" Then
					Continue;
				ElsIf XMLReader.LocalName = "Body" Then
					Break;
				EndIf;
			ElsIf IsBody AND XMLReader.NodeType = XMLNodeType.Comment Then
				XMLCommentReader = New XMLReader;
				XMLCommentReader.SetString(XMLReader.Value);
				XMLCommentReader.Read(); // PredefinedData - ItemStart
				
				ProcessPredefinedItemsSectionInExchangeMessages(
					XMLCommentReader, ImportParameters.PredefinedItemsTable);
					
				XMLCommentReader.Close();
			EndIf;
		EndDo;
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
	EndTry;
	
	XMLReader.Close();
	
EndProcedure

Procedure InitializeMessageReaderForStandardImport(ImportParameters, ExchangeExecutionResult, ErrorMessage)
	
	XMLReader = New XMLReader;
	Try
		If Not IsBlankString(ImportParameters.ExchangeMessage) Then
			XMLReader.SetString(ImportParameters.ExchangeMessage);
		Else
			XMLReader.OpenFile(ImportParameters.FileName);
		EndIf;
		
		MessageReader = ExchangePlans.CreateMessageReader();
		MessageReader.BeginRead(XMLReader, AllowedMessageNo.Greater);
	Except
		ErrorInformation  = ErrorInfo();
		
		BriefInformation   = BriefErrorDescription(ErrorInformation);
		DetailedInformation = DetailErrorDescription(ErrorInformation);
		
		If IsErrorMessageNumberLessOrEqualToPreviouslyAcceptedMessageNumber(BriefInformation) Then
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
			ErrorMessage = BriefInformation;
		Else
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ErrorMessage = DetailedInformation;
		EndIf;
		
		Return;
	EndTry;
	
	If MessageReader.Sender <> ImportParameters.InfobaseNode Then
		// The message is not intended for this node.
		ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		
		ErrorMessage = NStr("ru = 'Сообщение обмена содержит данные для другого узла информационной базы.'; en = 'The exchange message contains data for another infobase node.'; pl = 'Komunikat wymiany zawiera dane dla innego węzła bazy informacyjnej.';de = 'Die Austauschnachricht enthält Daten für einen anderen Infobaseknoten.';ro = 'Mesajul de schimb conține date pentru un alt nod al bazei de date.';tr = 'Değişim mesajı başka bir veritabanı ünitesi için veri içerir.'; es_ES = 'El mensaje de intercambio contiene datos para el nodo de otra infobase.'",
			Common.DefaultLanguageCode());
		Return;
	EndIf;
	
	ImportParameters.XMLReader       = XMLReader;
	ImportParameters.MessageReader = MessageReader;
	
EndProcedure

Procedure ExecuteStandardDataBatchImport(ImportParameters, ContinueImport)
	
	XMLReader       = ImportParameters.XMLReader;
	MessageReader = ImportParameters.MessageReader;
	
	WrittenItemsCount = 0;
	
	While (ImportParameters.TransactionItemsCount = 0
			Or WrittenItemsCount <= ImportParameters.TransactionItemsCount)
		AND CanReadXML(XMLReader) Do
		
		Data = ReadXML(XMLReader);
		
		GetItem = DataItemReceive.Auto;
		SendBack = False;
		
		StandardSubsystemsServer.OnReceiveDataFromMaster(
			Data, GetItem, SendBack, MessageReader.Sender.GetObject());
			
		ImportParameters.ProcessedObjectsCount = ImportParameters.ProcessedObjectsCount + 1;
		
		If GetItem = DataItemReceive.Ignore Then
			Continue;
		EndIf;
			
		// Overriding standard system behavior on getting object deletion.
		// Setting deletion mark instead of deleting objects without checking reference integrity.
		// 
		If TypeOf(Data) = Type("ObjectDeletion") Then
			Data = Data.Ref.GetObject();
			
			If Data = Undefined Then
				Continue;
			EndIf;
			
			Data.DeletionMark = True;
			
			If Common.IsDocument(Data.Metadata()) Then
				Data.Posted = False;
			EndIf;
		Else
			DataExchangeInternal.ReplaceRefsToPredefinedItems(Data, ImportParameters.PredefinedItemsTable);
		EndIf;
		
		If Not SendBack Then
			Data.DataExchange.Sender = MessageReader.Sender;
		EndIf;
		Data.DataExchange.Load = True;
		
		Data.Write();
		
		WrittenItemsCount = WrittenItemsCount + 1;
		
	EndDo;
	
	ContinueImport = (WrittenItemsCount > 0);
	
EndProcedure

Procedure ProcessPredefinedItemsSectionInExchangeMessages(XMLReader, PredefinedItemsTable)
	
	If XMLReader.NodeType = XMLNodeType.StartElement
		AND XMLReader.LocalName = "PredefinedData" Then
		
		XMLReader.Read();
		While CanReadXML(XMLReader) Do
			XMLTypeName          = XMLReader.LocalName;
			PredefinedItemsName = XMLReader.GetAttribute("PredefinedDataName");
			SourceRef      = ReadXML(XMLReader);
			
			RowsPredefined = PredefinedItemsTable.FindRows(
				New Structure("XMLTypeName, PredefinedDataName", XMLTypeName, PredefinedItemsName));
			For Each RowPredefined In RowsPredefined Do
				RowPredefined.SourceRef = SourceRef;
				RowPredefined.OriginalReferenceFilled = True;
			EndDo;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PropertyFunctions

Function FileOfDeferredUpdateDataFullName()
	
	Return GetTempFileName(".xml");
	
EndFunction

// Returns the name of exchange message file by sender node and recipient node data.
//
Function ExchangeMessageFileName(SenderNodeCode, RecipientNodeCode, IsOutgoingMessage)
	
	NameTemplate = "[Prefix]_[SenderNode]_[RecipientNode]";
	If StrLen(SenderNodeCode) = 36 AND IsOutgoingMessage Then
		SourceIBPrefix = Constants.DistributedInfobaseNodePrefix.Get();
		If ValueIsFilled(SourceIBPrefix) Then
			NameTemplate = "[Prefix]_[SourceIBPrefix]_[SenderNode]_[RecipientNode]";
		EndIf;
	EndIf;
	NameTemplate = StrReplace(NameTemplate, "[Prefix]",         "Message");
	NameTemplate = StrReplace(NameTemplate, "[SourceIBPrefix]",SourceIBPrefix);
	NameTemplate = StrReplace(NameTemplate, "[SenderNode]", SenderNodeCode);
	NameTemplate = StrReplace(NameTemplate, "[RecipientNode]",  RecipientNodeCode);
	
	Return NameTemplate;
EndFunction

// Returns the name of temporary directory for data exchange messages.
// The directory name is written in the following way:
// Exchange82 {GUID}, where GUID is a UUID string.
// 
//
// Parameters:
//  No.
// 
// Returns:
//  String -  a name of temporary directory for data exchange messages.
//
Function TempExchangeMessagesDirectoryName()
	
	Return StrReplace("Exchange82 {GUID}", "GUID", Upper(String(New UUID)));
	
EndFunction

// Returns the name of exchange message transport data processor.
//
// Parameters:
//  TransportKind - EnumRef.ExchangeMessageTransportKinds - a transport kind to get a data processor 
//                                                                     name for.
// 
//  Returns:
//    String - a name of exchange message transport data processor.
//
Function DataExchangeMessageTransportDataProcessorName(TransportKind)
	
	Return StrReplace("ExchangeMessageTransport[TransportKind]", "[TransportKind]", Common.EnumValueName(TransportKind));
	
EndFunction

// The DataExchangeClient.MaxObjectMappingFieldsCount() procedure duplicate at server.
//
Function MaxCountOfObjectsMappingFields() Export
	
	Return 5;
	
EndFunction

// Determines whether the exchange plan is in the list of exchange plans that use XDTO data exchange.
//
// Parameters:
//  ExchangePlan - a reference to the exchange plan node or the exchange plan name.
//
// Returns:
//  Boolean - True if an exchange plan is used to exchange data by XDTO format.
//
Function IsXDTOExchangePlan(ExchangePlan) Export
	Return DataExchangeCached.IsXDTOExchangePlan(ExchangePlan);
EndFunction

// Returns the unlimited length string literal.
//
// Returns:
//  String - an unlimited length string literal.
//
Function UnlimitedLengthString() Export
	
	Return "(string of unlimited length)";
	
EndFunction

// Function for retrieving property: returns literal of the XML node that contains the ORR constant value.
//
// Returns:
//  String literal of the XML node that contains the ORR constant value.
//
Function FilterItemPropertyConstantValue() Export
	
	Return "ConstantValue";
	
EndFunction

// Function for retrieving property: returns literal of the XML node that contains the value getting algorithm.
//
// Returns:
//  String - returns an XML node literal that contains the value getting algorithm.
//
Function FilterItemPropertyValueAlgorithm() Export
	
	Return "ValueAlgorithm";
	
EndFunction

// Function for retrieving property: returns a name of the file that is used for checking whether transport data processor is attached.
//
// Returns:
//  String - returns a name of the file that is used for checking whether transport data processor is attached.
//
Function TempConnectionTestFileName() Export
	FilePostfix = String(New UUID());
	Return "ConnectionCheckFile_" + FilePostfix + ".tmp";
	
EndFunction

Function IsErrorMessageNumberLessOrEqualToPreviouslyAcceptedMessageNumber(ErrorDescription)
	
	Return StrFind(Lower(ErrorDescription), Lower("ru = 'Number messages less than or equal'")) > 0;
	
EndFunction

Function EventLogEventEstablishWebServiceConnection() Export
	
	Return NStr("ru = 'Обмен данными.Установка подключения к web-сервису'; en = 'Data exchange.Establish web service connection'; pl = 'Wymiana danych. Połączenie z usługą sieciową';de = 'Datenaustausch. Verbindung mit dem Webservice';ro = 'Schimb de date.Conectarea la serviciul web';tr = 'Veri alışverişi. Web servisine bağlanma'; es_ES = 'Intercambio de datos.Conectando al servicio web'", Common.DefaultLanguageCode());
	
EndFunction

Function DataExchangeRuleImportEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Загрузка правил'; en = 'Data exchange.Load rules'; pl = 'Wymiana danych. Import reguł';de = 'Datenaustausch. Regelimport';ro = 'Schimb de date.Importul regulilor';tr = 'Veri değişimi. Kuralı içe aktarma'; es_ES = 'Intercambio de datos.Importación de la regla'", Common.DefaultLanguageCode());
	
EndFunction

Function DataExchangeCreationEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Создание обмена данными'; en = 'Data exchange.Create data exchange'; pl = 'Wymiana danych. Utworzenie wymiany danych';de = 'Datenaustausch. Datenaustausch erstellen';ro = 'Schimb de date.Crearea schimbului de date';tr = 'Veri değişimi. Veri değişimin oluşturulması'; es_ES = 'Intercambio de datos.Creando el intercambio de datos'", Common.DefaultLanguageCode());
	
EndFunction

Function DataExchangeDeletionEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Удаление обмена данными'; en = 'Data exchange.Delete data exchange'; pl = 'Wymiana danych.Usunięcie  wymiany danych';de = 'Datenaustausch.Datenaustausch löschen';ro = 'Schimb de date.Ștergerea schimbului de date';tr = 'Veri alışverişi. Veri alışverişin kaldırılması'; es_ES = 'Intercambio de datos.Eliminar intercambio de datos'", Common.DefaultLanguageCode());
	
EndFunction

Function RegisterDataForInitialExportEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Регистрация данных для начальной выгрузки'; en = 'Data exchange.Register data for initial export'; pl = 'Wymiana danych.Rejestracja danych do wysłania początkowego';de = 'Datenaustausch.Daten für den erstmaligen Upload registrieren';ro = 'Schimb de date.Înregistrarea datelor pentru exportul inițial';tr = 'Veri alışverişi. İlk dışa aktarma için veri kaydı'; es_ES = 'Intercambio de datos.Registro de datos para subida inicial'", Common.DefaultLanguageCode());
	
EndFunction

Function DataImportToMapEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Выгрузка данных для сопоставления'; en = 'Data exchange.Export data for mapping'; pl = 'Wymiana danych.Pobieranie danych do porównania';de = 'Datenaustausch.Daten zum Vergleich exportiert';ro = 'Schimb de date.Exportul de date pentru confruntare';tr = 'Veri alışverişi.  Karşılaştırılacak verilerin dışa aktarımı'; es_ES = 'Intercambio de datos.Subida de datos para comparar'", Common.DefaultLanguageCode());
	
EndFunction

Function TempFileDeletionEventLogMessageText() Export
	
	Return NStr("ru = 'Обмен данными.Удаление временного файла'; en = 'Data exchange.Delete temporary file'; pl = 'Wymiana danych. Usunięcie pliku tymczasowego';de = 'Datenaustausch.Entfernen der temporären Datei';ro = 'Schimb de date.Ștergerea fișierului temporar';tr = 'Veri değişimi. Geçici dosyayı kaldırma'; es_ES = 'Intercambio de datos.Eliminando el archivo temporal'", Common.DefaultLanguageCode());
	
EndFunction

Function EventLogMessageTextDataExchange() Export
	
	Return NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'", Common.DefaultLanguageCode());
	
EndFunction

Function EventLogEventExportDataToFilesTransferService() Export
	
	Return NStr("ru = 'Обмен данными.Сервис передачи файлов.Выгрузка данных'; en = 'Data exchange.File transfer service.Export data'; pl = 'Wymiana danych.Serwis przekazania plików.Wysłanie danych';de = 'Datenaustausch.Dateiübertragungsdienst.Daten exportieren';ro = 'Schimb de date.Serviciul de transfer de fișiere.Exportul de date';tr = 'Veri alışverişi.  Dosya transfer hizmetleri. Veri dışa aktarma'; es_ES = 'Intercambio de datos.Servicio de pasar los archivos.Subida de datos'", Common.DefaultLanguageCode());
	
EndFunction

Function ExportDataFromFileTransferServiceEventLogEvent() Export
	
	Return NStr("ru = 'Обмен данными.Сервис передачи файлов.Загрузка данных'; en = 'Data exchange.File transfer service.Import data'; pl = 'Wymiana danych.Serwis przekazania plików.Pobieranie danych';de = 'Datenaustausch.Dateiübertragungsdienst.Daten importieren ';ro = 'Schimb de date.Serviciul de transfer de fișiere.Importul de date';tr = 'Veri alışverişi.  Dosya transfer hizmetleri. Veri içe aktarma'; es_ES = 'Intercambio de datos.Servicio de pasar los archivos.Descarga de datos'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region ExchangeMessagesTransport

Procedure ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure)
	
	// Getting the initialized message transport data processor.
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	// Getting a new temporary file name.
	If Not ExchangeMessageTransportDataProcessor.ExecuteActionsBeforeProcessMessage() Then
		
		WriteEventLogDataExchange(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL, ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportSending(ExchangeSettingsStructure)
	
	// Getting the initialized message transport data processor.
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	// Sending the exchange message from the temporary directory.
	If Not ExchangeMessageTransportDataProcessor.ConnectionIsSet()
		Or Not ExchangeMessageTransportDataProcessor.SendMessage() Then
		
		WriteEventLogDataExchange(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL, ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure, UseAlias = True, ErrorsStack = Undefined)
	
	If ErrorsStack = Undefined Then
		ErrorsStack = New Array;
	EndIf;
	
	// Getting the initialized message transport data processor.
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	// Getting exchange message to a temporary directory.
	If Not ExchangeMessageTransportDataProcessor.ConnectionIsSet()
		Or Not ExchangeMessageTransportDataProcessor.GetMessage() Then
		
		ErrorsStack.Add(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL);
		
		If Not UseAlias Then
			// There will be no more attempts to search the file. Registering all accumulated errors.
			For Each CurrentError In ErrorsStack Do
				WriteEventLogDataExchange(CurrentError, ExchangeSettingsStructure, True);
			EndDo;
		EndIf;
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
		
	EndIf;
	
	If UseAlias
		AND ExchangeSettingsStructure.ExchangeExecutionResult <> Undefined Then
		// Probably the file can be received if you apply the virtual code (alias) of the node.
		
		Transliteration = Undefined;
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
			ExchangeSettingsStructure.TransportSettings.Property("FILETransliterateExchangeMessageFileNames", Transliteration);
		ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
			ExchangeSettingsStructure.TransportSettings.Property("EMAILTransliterateExchangeMessageFileNames", Transliteration);
		ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
			ExchangeSettingsStructure.TransportSettings.Property("FTPTransliterateExchangeMessageFileNames", Transliteration);
		EndIf;
		Transliteration = ?(Transliteration = Undefined, False, Transliteration);
		
		FileNameTemplatePrevious = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern;
		ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern = MessageFileNamePattern(
				ExchangeSettingsStructure.CurrentExchangePlanNode,
				ExchangeSettingsStructure.InfobaseNode,
				False,
				Transliteration, 
				True);
		If FileNameTemplatePrevious <> ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNamePattern Then
			// Retrying the transport with a new template.
			ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
			ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure, False, ErrorsStack);
		Else
			// There will be no more attempts to search the file. Registering all accumulated errors.
			For Each CurrentError In ErrorsStack Do
				WriteEventLogDataExchange(CurrentError, ExchangeSettingsStructure, True);
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure)
	
	// Getting the initialized message transport data processor.
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor;
	
	// Performing actions after sending the message.
	ExchangeMessageTransportDataProcessor.ExecuteActionsAfterProcessMessage();
	
EndProcedure

// Gets proxy server settings.
//
Function ProxyServerSettings(SecureConnection)
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Protocol = ?(SecureConnection = Undefined, "ftp", "ftps");
		Proxy = ModuleNetworkDownload.GetProxy(Protocol);
	EndIf;
	
	Return Proxy;
	
EndFunction
#EndRegion

#Region FileTransferService

// The function downloads the file from the file transfer service by the passed ID.
//
// Parameters:
//  FileID       - UUID - ID ща the file being received.
//  SaaSAccessParameters - Structure: ServiceAddress, Username, UserPassword.
//  PartSize              - Number - part size in kilobytes. If the passed value is 0, the file is 
//                             not split into parts.
// Returns:
//  String - received file path.
//
Function GetFileFromStorageInService(Val FileID, Val InfobaseNode, Val PartSize = 1024, Val AuthenticationParameters = Undefined) Export
	
	// Function return value.
	ResultFileName = "";
	
	AdditionalParameters = New Structure("AuthenticationParameters", AuthenticationParameters);
	
	Proxy = WSProxyForInfobaseNode(InfobaseNode, , AdditionalParameters);
	
	SessionID = Undefined;
	PartCount    = Undefined;
	
	Proxy.PrepareGetFile(FileID, PartSize, SessionID, PartCount);
	
	FileNames = New Array;
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	// Logging exchange events.
	ExchangeSettingsStructure = New Structure("EventLogMessageKey");
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Начало получения сообщения обмена из Интернета (количество частей файла %1).'; en = 'Receiving exchange message from the internet started (file parts: %1).'; pl = 'Początek odbierania wiadomości wymiany internetowej (ilość części pliku: %1).';de = 'Start des Internet Austausch Nachrichtenempfangs (Anzahl der Dateiteile ist %1).';ro = 'Începutul primirii mesajului de schimb din Internet (numărul de părți ale fișierului %1).';tr = 'İnternet değişim mesajının alınmaya başlaması (dosya parçalarının sayısı%1).'; es_ES = 'Inicio de la recepción del mensaje de intercambio de Internet (número de las partes del archivo es %1).'"),
		Format(PartCount, "NZ=0; NG=0"));
	WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	For PartNumber = 1 To PartCount Do
		PartData = Undefined;
		Try
			Proxy.GetFilePart(SessionID, PartNumber, PartData);
		Except
			Proxy.ReleaseFile(SessionID);
			Raise;
		EndTry;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FileNames.Add(PartFileName);
	EndDo;
	PartData = Undefined;
	
	Proxy.ReleaseFile(SessionID);
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FileNames, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			WriteLogEvent(TempFileDeletionEventLogMessageText(),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("ru = 'Файл архива не содержит данных.'; en = 'The archive file does not contain data.'; pl = 'Plik archiwum nie zawiera danych.';de = 'Die Archivdatei enthält keine Daten.';ro = 'Fișierul arhivei nu conține date.';tr = 'Arşiv dosyası veri içermemektedir.'; es_ES = 'Documento del archivo no contiene datos.'"));
	EndIf;
	
	// Logging exchange events.
	ArchiveFile = New File(ArchiveName);
	
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Окончание получения сообщения обмена из Интернета (размер сжатого сообщения обмена %1 Мб).'; en = 'Receiving exchange message from the internet completed (compressed exchange message size: %1 MB).'; pl = 'Zakończenie odbioru wiadomości wymiany z Internetu (rozmiar skompresowanej wiadomości wymiany:%1 MB).';de = 'Ende der Austauschnachricht, die aus dem Internet empfangen wird (die Größe einer komprimierten Austauschnachricht ist %1 MB).';ro = 'Sfârșitul primirii mesajului de schimb de pe Internet (mărimea mesajului de schimb comprimat este %1 MB).';tr = 'İnternetten alınan değişim mesajının sonu (sıkıştırılmış bir değişim mesajının boyutu %1MB''dir).'; es_ES = 'Fin de la recepción del mensaje de intercambio de Internet (tamaño de un mensaje de intercambio comprimido es %1 MB).'"),
		Format(Round(ArchiveFile.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
	WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	FileName = CommonClientServer.GetFullFileName(BuildDirectory, Dearchiver.Items[0].Name);
	
	Dearchiver.Extract(Dearchiver.Items[0], BuildDirectory);
	Dearchiver.Close();
	
	File = New File(FileName);
	
	TempDirectory = GetTempFileName();
	CreateDirectory(TempDirectory);
	
	ResultFileName = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	
	MoveFile(FileName, ResultFileName);
	
	Try
		DeleteFiles(BuildDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Return ResultFileName;
EndFunction

// Passes the specified file to the file transfer service.
//
// Parameters:
//  FileName                 - String - path to the file being passed.
//  SaaSAccessParameters - Structure: ServiceAddress, Username, UserPassword.
//  PartSize              - Number - part size in kilobytes. If the passed value is 0, the file is 
//                             not split into parts.
// Returns:
//  UUID  - a file ID in the file transfer service.
//
Function PutFileInStorageInService(Val FileName, Val InfobaseNode, Val PartSize = 1024, Val AuthenticationParameters = Undefined)
	
	// Function return value.
	FileID = Undefined;
	
	AdditionalParameters = New Structure("AuthenticationParameters", AuthenticationParameters);
	
	Proxy = WSProxyForInfobaseNode(InfobaseNode, , AdditionalParameters);
	
	FilesDirectory = GetTempFileName();
	CreateDirectory(FilesDirectory);
	
	// Archiving the file.
	SharedFileName = CommonClientServer.GetFullFileName(FilesDirectory, "data.zip");
	Archiver = New ZipFileWriter(SharedFileName,,,, ZIPCompressionLevel.Maximum);
	Archiver.Add(FileName);
	Archiver.Write();
	
	// Splitting a file into parts.
	SessionID = New UUID;
	
	PartCount = 1;
	If ValueIsFilled(PartSize) Then
		FileNames = SplitFile(SharedFileName, PartSize * 1024);
		PartCount = FileNames.Count();
		For PartNumber = 1 To PartCount Do
			PartFileName = FileNames[PartNumber - 1];
			FileData = New BinaryData(PartFileName);
			Proxy.PutFilePart(SessionID, PartNumber, FileData);
		EndDo;
	Else
		FileData = New BinaryData(SharedFileName);
		Proxy.PutFilePart(SessionID, 1, FileData);
	EndIf;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Proxy.SaveFileFromParts(SessionID, PartCount, FileID);
	
	Return FileID;
	
EndFunction

// Getting file by its ID.
//
// Parameters:
//	FileID - UUID - an ID of the file being received.
//
// Returns:
//  FileName – String – a file name.
//
Function GetFileFromStorage(Val FileID) Export
	
	FileName = "";
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnReceiveFileFromStorage(FileID, FileName);
		
	Else
		
		OnReceiveFileFromStorage(FileID, FileName);
		
	EndIf;
	
	Return CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), FileName);
	
EndFunction

// Saving file.
//
// Parameters:
//  FileName               - String - a file name.
//  FileID     - UUID - a file ID. If the ID is specified, it is used on saving the file. Otherwise, 
//                           a new value is generated.
//
// Returns:
//  UUID - a file ID.
//
Function PutFileInStorage(Val FileName, Val FileID = Undefined) Export
	
	FileID = ?(FileID = Undefined, New UUID, FileID);
	
	File = New File(FileName);
	
	RecordStructure = New Structure;
	RecordStructure.Insert("MessageID", String(FileID));
	RecordStructure.Insert("MessageFileName", File.Name);
	RecordStructure.Insert("MessageStoredDate", CurrentUniversalDate());
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnPutFileToStorage(RecordStructure);
	Else
		
		OnPutFileToStorage(RecordStructure);
		
	EndIf;
	
	Return FileID;
	
EndFunction

// Gets a file from the storage by the file ID.
// If a file with the specified ID is not found, an exception is thrown.
// If the file is found, its name is returned, and the information about the file is deleted from the storage.
//
// Parameters:
//	FileID  - UUID - ID of the file being received.
//	FileName            - String - a name of a file from the storage.
//
Procedure OnReceiveFileFromStorage(Val FileID, FileName)
	
	QueryText =
	"SELECT
	|	DataExchangeMessages.MessageFileName AS FileName
	|FROM
	|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
	|WHERE
	|	DataExchangeMessages.MessageID = &MessageID";
	
	Query = New Query;
	Query.SetParameter("MessageID", String(FileID));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Details = NStr("ru = 'Файл с идентификатором %1 не обнаружен.'; en = 'The file with ID %1 is not found.'; pl = 'Nie znaleziono pliku z identyfikatorem %1.';de = 'Eine Datei mit ID %1 wurde nicht gefunden.';ro = 'Nu a fost găsit fișierul cu ID %1.';tr = '%1Kimliğine sahip bir dosya bulunamadı.'; es_ES = 'Un archivo con el identificador %1 no encontrado.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Details, String(FileID));
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FileName = Selection.FileName;
	
	// Deleting information about message file from the storage.
	RecordStructure = New Structure;
	RecordStructure.Insert("MessageID", String(FileID));
	InformationRegisters.DataExchangeMessages.DeleteRecord(RecordStructure);
	
EndProcedure

// Stores a file to a storage.
//
Procedure OnPutFileToStorage(Val RecordStructure)
	
	InformationRegisters.DataExchangeMessages.AddRecord(RecordStructure);
	
EndProcedure

#EndRegion

#Region InitialDataExportChangesRegistration

// Registers changes for initial data export considering export start date and the list of companies.
// The procedure is universal and can be used for registering data changes by export start date and 
// the list of companies for object data types and register record sets.
// If the list of companies is not specified (Companies = Undefined), changes are registered only by 
// export start date.
// The procedure registers data of all metadata objects included in the exchange plan.
// The procedure registers data unconditionally in the following cases:  - the UseAutoRecord flag of 
// the metadata object is set.  - the UseAutoRecord flag is not set and registration rules are not 
// specified.
// If registration rules are specified for the metadata object, changes are registered based on 
// export start date and the list of companies.
// Document changes can be registered based on export start date and the list of companies.
// Business process changes and task changes can be registered based on export start date.
// Register record set changes can be registered based on export start date and the list of companies.
// The procedure can be used as a prototype for developing procedures of changes registration for 
// initial data export.
//
// Parameters:
//
//  Recipient - ExchangePlanRef - an exchange plan node whose changes are to be registered.
//               
//  ExportStartDate - Date - changes made since this date and time are to be registered.
//                Changes are registered for the data located after this date on the time scale.
//               
//  Companies - Array, Undefined - a list of companies data changes are to be registered for.
//                If this parameter is not specified, companies are not taken into account on 
//               changes registration.
//
Procedure RegisterDataByExportStartDateAndCompanies(Val Recipient, ExportStartDate,
	Companies = Undefined,
	Data = Undefined) Export
	
	FilterByCompanies = (Companies <> Undefined);
	FilterByExportStartDate = ValueIsFilled(ExportStartDate);
	
	If Not FilterByCompanies AND Not FilterByExportStartDate Then
		
		If TypeOf(Data) = Type("Array") Then
			
			For Each MetadataObject In Data Do
				
				ExchangePlans.RecordChanges(Recipient, MetadataObject);
				
			EndDo;
			
		Else
			
			ExchangePlans.RecordChanges(Recipient, Data);
			
		EndIf;
		
		Return;
	EndIf;
	
	FilterByExportStartDateAndCompanies = FilterByExportStartDate AND FilterByCompanies;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	
	ExchangePlanComposition = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	UseFilterByMetadata = (TypeOf(Data) = Type("Array"));
	
	For Each ExchangePlanCompositionItem In ExchangePlanComposition Do
		
		If UseFilterByMetadata
			AND Data.Find(ExchangePlanCompositionItem.Metadata) = Undefined Then
			
			Continue;
			
		EndIf;
		
		FullObjectName = ExchangePlanCompositionItem.Metadata.FullName();
		
		If ExchangePlanCompositionItem.AutoRecord = AutoChangeRecord.Deny
			AND DataExchangeCached.ObjectRegistrationRulesExist(ExchangePlanName, FullObjectName) Then
			
			If Common.IsDocument(ExchangePlanCompositionItem.Metadata) Then // Documents
				
				If FilterByExportStartDateAndCompanies
					// Registering by date and companies.
					AND ExchangePlanCompositionItem.Metadata.Attributes.Find("Company") <> Undefined Then
					
					Selection = DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				Else // Registering by date.
					
					Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				EndIf;
				
			ElsIf Common.IsBusinessProcess(ExchangePlanCompositionItem.Metadata)
				OR Common.IsTask(ExchangePlanCompositionItem.Metadata) Then // Business processes and Tasks.
				
				// Registering by date.
				Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
				
				While Selection.Next() Do
					
					ExchangePlans.RecordChanges(Recipient, Selection.Ref);
					
				EndDo;
				
				Continue;
				
			ElsIf Common.IsRegister(ExchangePlanCompositionItem.Metadata) Then // Registers
				
				// Information registers (independent).
				If Common.IsInformationRegister(ExchangePlanCompositionItem.Metadata)
					AND ExchangePlanCompositionItem.Metadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					
					MainFilter = MainInformationRegisterFilter(ExchangePlanCompositionItem.Metadata);
					
					FilterByPeriod     = (MainFilter.Find("Period") <> Undefined);
					FilterByCompany = (MainFilter.Find("Company") <> Undefined);
					
					// Registering by date and companies.
					If FilterByExportStartDateAndCompanies AND FilterByPeriod AND FilterByCompany Then
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter, FullObjectName, ExportStartDate, Companies);
						
					ElsIf FilterByExportStartDate AND FilterByPeriod Then // Registering by date.
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate);
						
					ElsIf FilterByCompanies AND FilterByCompany Then // Registering by companies.
						
						Selection = MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies);
						
					Else
						
						Selection = Undefined;
						
					EndIf;
					
					If Selection <> Undefined Then
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							For Each DimensionName In MainFilter Do
								
								RecordSet.Filter[DimensionName].Value = Selection[DimensionName];
								RecordSet.Filter[DimensionName].Use = True;
								
							EndDo;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				Else // Registers (other)
					HasPeriodInRegister = Common.IsAccountingRegister(ExchangePlanCompositionItem.Metadata)
							OR Common.IsAccumulationRegister(ExchangePlanCompositionItem.Metadata)
							OR (Common.IsInformationRegister(ExchangePlanCompositionItem.Metadata)
								AND ExchangePlanCompositionItem.Metadata.InformationRegisterPeriodicity 
									<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical);
					If FilterByExportStartDateAndCompanies
						AND HasPeriodInRegister
						// Registering by date and companies.
						AND ExchangePlanCompositionItem.Metadata.Dimensions.Find("Company") <> Undefined Then
						
						Selection = RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					// Registering by date.
					ElsIf HasPeriodInRegister Then
						
						Selection = RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ExchangePlans.RecordChanges(Recipient, ExchangePlanCompositionItem.Metadata);
		
	EndDo;
	
EndProcedure

Function DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	[FullObjectName] AS Table
	|WHERE
	|	Table.Company IN(&Companies)
	|	AND Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	[FullObjectName] AS Table
	|WHERE
	|	Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	[FullObjectName] AS RegisterTable
	|WHERE
	|	RegisterTable.Company IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	[FullObjectName] AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter,
	FullObjectName,
	ExportStartDate,
	Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	[Dimensions]
	|FROM
	|	[FullObjectName] AS RegisterTable
	|WHERE
	|	RegisterTable.Company IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	QueryText = StrReplace(QueryText, "[Dimensions]", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	[Dimensions]
	|FROM
	|	[FullObjectName] AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	QueryText = StrReplace(QueryText, "[Dimensions]", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	[Dimensions]
	|FROM
	|	[FullObjectName] AS RegisterTable
	|WHERE
	|	RegisterTable.Company IN(&Companies)";
	
	QueryText = StrReplace(QueryText, "[FullObjectName]", FullObjectName);
	QueryText = StrReplace(QueryText, "[Dimensions]", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilter(MetadataObject)
	
	Result = New Array;
	
	If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
		AND MetadataObject.MainFilterOnPeriod Then
		
		Result.Add("Period");
		
	EndIf;
	
	For Each Dimension In MetadataObject.Dimensions Do
		
		If Dimension.MainFilter Then
			
			Result.Add(Dimension.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region WrappersToOperateWithExchangePlanManagerApplicationInterface

Function NodeFilterStructure(Val ExchangePlanName, Val CorrespondentVersion, SettingID = "") Export
	If IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, 
								SettingID, CorrespondentVersion);
	
	Result = Undefined;
	If ValueIsFilled(SettingOptionDetails.Filters) Then
		Result = SettingOptionDetails.Filters;
	EndIf;
	
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	Return Result;
EndFunction

Function DataTransferRestrictionsDetails(Val ExchangePlanName, Val Setting, Val CorrespondentVersion, 
										SettingID = "") Export
	If NOT HasExchangePlanManagerAlgorithm("DataTransferRestrictionsDetails", ExchangePlanName) Then
		Return "";
	ElsIf IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	Return ExchangePlans[ExchangePlanName].DataTransferRestrictionsDetails(Setting, CorrespondentVersion, SettingID);
	
EndFunction

Function CommonNodeData(Val ExchangePlanName, Val CorrespondentVersion, Val SettingID) Export
	
	If IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, 
								SettingID, CorrespondentVersion);
	Result = SettingOptionDetails.CommonNodeData;
	
	Return StrReplace(Result, " ", "");
	
EndFunction

Procedure OnConnectToCorrespondent(Val ExchangePlanName, Val CorrespondentVersion) Export
	If NOT HasExchangePlanManagerAlgorithm("OnConnectToCorrespondent", ExchangePlanName) Then
		Return;
	ElsIf IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	ExchangePlans[ExchangePlanName].OnConnectToCorrespondent(CorrespondentVersion);
	
EndProcedure

// Fills settings for the exchange plan which are then used by the data exchange subsystem.
// Parameters:
//   ExchangePlanName              - String - an exchange plan name.
//   CorrespondentVersion        - String - a correspondent configuration version.
//   CorrespondentName           - String - a correspondent configuration name.
//   CorrespondentInSaaS - Boolean or Undefined - shows that correspondent is in SaaS.
// Returns:
//   Structure - see comment to the DefaultExchangePlanSettings function.
Function ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, CorrespondentInSaaS) Export
	ExchangePlanSettings = DefaultExchangePlanSettings(ExchangePlanName);
	SetPrivilegedMode(True);
	ExchangePlans[ExchangePlanName].OnGetSettings(ExchangePlanSettings);
	HasOptionsReceivingHandler = ExchangePlanSettings.Algorithms.OnGetExchangeSettingsOptions;
	// Option initialization is required.
	If HasOptionsReceivingHandler Then
		FilterParameters = ContextParametersOfSettingsOptionsReceipt(CorrespondentName, CorrespondentVersion, CorrespondentInSaaS);
		ExchangePlans[ExchangePlanName].OnGetExchangeSettingsOptions(ExchangePlanSettings.ExchangeSettingsOptions, FilterParameters);
	Else
		// Options are not used – an internal option is to be added.
		SetupOption = ExchangePlanSettings.ExchangeSettingsOptions.Add();
		SetupOption.SettingID = "";
		SetupOption.CorrespondentInSaaS = Common.DataSeparationEnabled() 
			AND ExchangePlanSettings.ExchangePlanUsedInSaaS;
		SetupOption.CorrespondentInLocalMode = True;
	EndIf;
	SetPrivilegedMode(False);

	Return ExchangePlanSettings;
EndFunction

// Intended for preparing the structure and passing it to setting options get handler.
// Parameters:
//  CorrespondentName - String - a correspondent configuration name.
//  CorrespondentVersion - String - a correspondent configuration version.
//  CorrespondentInSaaS - Boolean or Undefined - shows that correspondent is in SaaS.
// Returns: Structure.
Function ContextParametersOfSettingsOptionsReceipt(CorrespondentName, CorrespondentVersion, CorrespondentInSaaS)
	Return New Structure("CorrespondentName, CorrespondentVersion, CorrespondentInSaaS",
				CorrespondentName, CorrespondentVersion, CorrespondentInSaaS);
EndFunction

// Fills in the settings related to the exchange setup option. Later these settings are used by the data exchange subsystem.
// Parameters:
//   ExchangePlanName        - String -  an exchange plan name.
//   SetupID - String - ID of data exchange setup option.
//   CorrespondentVersion   - String - a correspondent configuration version.
//   CorrespondentName      - String - a correspondent configuration name.
// Returns:
//   Structure - for more information, see comment to the ExchangeSettingOptionDetailsByDefault function.
Function SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion, CorrespondentName) Export
	SettingOptionDetails = ExchangeSettingOptionDetailsByDefault(ExchangePlanName);
	HasOptionDetailsHandler = HasExchangePlanManagerAlgorithm("OnGetSettingOptionDetails", ExchangePlanName);
	If HasOptionDetailsHandler Then
		OptionParameters = ContextParametersOfSettingOptionDetailsReceipt(CorrespondentName, CorrespondentVersion);
		ExchangePlans[ExchangePlanName].OnGetSettingOptionDetails(
							SettingOptionDetails, SettingID, OptionParameters);
	EndIf;
	Return SettingOptionDetails;
EndFunction

// Is intended for preparing the structure and passing to the handler of option details receipt.
// Parameters:
//  CorrespondentName - String - a correspondent configuration name.
//  CorrespondentVersion - String - a correspondent configuration version.
// Returns: Structure.
Function ContextParametersOfSettingOptionDetailsReceipt(CorrespondentName, CorrespondentVersion)
	Return New Structure("CorrespondentVersion, CorrespondentName",
							CorrespondentVersion,CorrespondentName);
EndFunction

// Returns the flag showing whether the specified procedure or function is available in the exchange plan manager module.
// Calculated by exchange plan settings, the Algorithms property (see the DefaultExchangePlanSettings comment).
// Parameters:
//  AlgorithmName - String - a name of procedure / function.
//  ExchangePlanName - String - an exchange plan name.
// Returns:
//   Boolean.
//
Function HasExchangePlanManagerAlgorithm(AlgorithmName, ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeCached.ExchangePlanSettings(ExchangePlanName);
	
	AlgorithmFound = Undefined;
	ExchangePlanSettings.Algorithms.Property(AlgorithmName, AlgorithmFound);
	
	Return (AlgorithmFound = True);
	
EndFunction
#EndRegion

#Region DataSynchronizationPasswordsOperations

// Returns the data synchronization password for the specified node.
// If the password is not set, the function returns Undefined.
//
// Returns:
//  String, Undefined - data synchronization password value.
//
Function DataSynchronizationPassword(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.DataSynchronizationPasswords.Get(InfobaseNode);
EndFunction

// Returns the flag that shows whether the data synchronization password is set by a user.
//
Function DataSynchronizationPasswordSpecified(Val InfobaseNode) Export
	
	Return DataSynchronizationPassword(InfobaseNode) <> Undefined;
	
EndFunction

// Sets the data synchronization password for the specified node.
// Saves the password to a session parameter.
//
Procedure SetDataSynchronizationPassword(Val InfobaseNode, Val Password)
	
	SetPrivilegedMode(True);
	
	DataSynchronizationPasswords = New Map;
	
	For Each Item In SessionParameters.DataSynchronizationPasswords Do
		
		DataSynchronizationPasswords.Insert(Item.Key, Item.Value);
		
	EndDo;
	
	DataSynchronizationPasswords.Insert(InfobaseNode, Password);
	
	SessionParameters.DataSynchronizationPasswords = New FixedMap(DataSynchronizationPasswords);
	
EndProcedure

// Resets the data synchronization password for the specified node.
//
Procedure ResetDataSynchronizationPassword(Val InfobaseNode)
	
	SetDataSynchronizationPassword(InfobaseNode, Undefined);
	
EndProcedure

#EndRegion

#Region SharedDataControl

// Checks whether it is possible to write separated data item. Raises exception if the data item cannot be written.
//
Procedure ExecuteSharedDataOnWriteCheck(Val Data) Export
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable()
		AND Not IsSeparatedObject(Data) Then
		
		ExceptionText = NStr("ru = 'Недостаточно прав для выполнения действия.'; en = 'Insufficient rights to perform the operation.'; pl = 'Nie wystarczające uprawnienia do wykonania czynności.';de = 'Unzureichende Rechte zur Durchführung der Aktion.';ro = 'Drepturi insuficiente pentru executarea acțiunii.';tr = 'Eylemi gerçekleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para realizar la acción.'", Common.DefaultLanguageCode());
		
		WriteLogEvent(
			ExceptionText,
			EventLogLevel.Error,
			Data.Metadata());
		
		Raise ExceptionText;
	EndIf;
	
EndProcedure

Function IsSeparatedObject(Val Object)
	
	FullName = Object.Metadata().FullName();
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject(FullName);
	Else
		IsSeparatedMetadataObject = False;
	EndIf;
	
	Return IsSeparatedMetadataObject;
	
EndFunction

#EndRegion

#Region DataExchangeDashboardOperations

// Returns the structure with the last exchange data for the specified infobase node.
//
// Parameters:
//  No.
// 
// Returns:
//  DataExchangesStates - Structure - a structure with the last exchange data for the specified infobase node.
//
Function DataExchangesStatesForInfobaseNode(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	// Function return value.
	DataExchangesStates = New Structure;
	DataExchangesStates.Insert("InfobaseNode");
	DataExchangesStates.Insert("DataImportResult", "Undefined");
	DataExchangesStates.Insert("DataExportResult", "Undefined");
	
	QueryText = "
	|// {QUERY #0}
	|////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
	|	THEN ""Success""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|	THEN ""CompletedWithWarnings""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
	|	THEN ""Warning_ExchangeMessageAlreadyAccepted""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Error_MessageTransport)
	|	THEN ""Error_MessageTransport""
	|	
	|	ELSE ""Error""
	|	
	|	END AS ExchangeExecutionResult
	|FROM
	|	InformationRegister.[DataExchangesStates] AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|// {QUERY #1}
	|////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
	|	THEN ""Success""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|	THEN ""CompletedWithWarnings""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
	|	THEN ""Warning_ExchangeMessageAlreadyAccepted""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Error_MessageTransport)
	|	THEN ""Error_MessageTransport""
	|	
	|	ELSE ""Error""
	|	END AS ExchangeExecutionResult
	|	
	|FROM
	|	InformationRegister.[DataExchangesStates] AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
	|;
	|";
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		QueryText = StrReplace(QueryText, "[DataExchangesStates]", "DataAreaDataExchangeStates");
	Else
		QueryText = StrReplace(QueryText, "[DataExchangesStates]", "DataExchangesStates");
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	QueryResultsArray = Query.ExecuteBatch();
	
	DataImportResultSelection = QueryResultsArray[0].Select();
	DataExportResultSelection = QueryResultsArray[1].Select();
	
	If DataImportResultSelection.Next() Then
		
		DataExchangesStates.DataImportResult = DataImportResultSelection.ExchangeExecutionResult;
		
	EndIf;
	
	If DataExportResultSelection.Next() Then
		
		DataExchangesStates.DataExportResult = DataExportResultSelection.ExchangeExecutionResult;
		
	EndIf;
	
	DataExchangesStates.InfobaseNode = InfobaseNode;
	
	Return DataExchangesStates;
EndFunction

// Returns the structure with the last exchange data for the specified infobase node and actions on exchange.
//
// Parameters:
//  No.
// 
// Returns:
//  DataExchangesStates - Structure - a structure with the last exchange data for the specified infobase node.
//
Function DataExchangesStates(Val InfobaseNode, ActionOnExchange) Export
	
	// Function return value.
	DataExchangesStates = New Structure;
	DataExchangesStates.Insert("StartDate",    Date('00010101'));
	DataExchangesStates.Insert("EndDate", Date('00010101'));
	
	QueryText = "
	|SELECT
	|	StartDate,
	|	EndDate
	|FROM
	|	InformationRegister.[DataExchangesStates] AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange      = &ActionOnExchange
	|";
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		QueryText = StrReplace(QueryText, "[DataExchangesStates]", "DataAreaDataExchangeStates");
	Else
		QueryText = StrReplace(QueryText, "[DataExchangesStates]", "DataExchangesStates");
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	Query.SetParameter("ActionOnExchange",      ActionOnExchange);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		FillPropertyValues(DataExchangesStates, Selection);
		
	EndIf;
	
	Return DataExchangesStates;
	
EndFunction

#EndRegion

#Region InitializeSession

// Retrieves an array of all exchange plans that take part in the data exchange.
// The return array contains all exchange plans that have exchange nodes except the predefined one.
//
// Parameters:
//  No.
// 
// Returns:
//  ExchangePlanArray - Array - an array of strings (names) of all exchange plans that take part in the data exchange.
//
Function GetExchangePlansInUse() Export
	
	// returns
	ExchangePlanArray = New Array;
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		If Not ExchangePlanContainsNoNodes(ExchangePlanName) Then
			
			ExchangePlanArray.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return ExchangePlanArray;
	
EndFunction

// Receives the object registration rules table from the infobase.
//
// Parameters:
//  No.
// 
// Returns:
//  ObjectsRegistrationRules - ValueTable - a table of common object registration rules for ORM.
// 
Function GetObjectsRegistrationRules() Export
	
	// Function return value.
	ObjectsRegistrationRules = ObjectsRegistrationRulesTableInitialization();
	
	QueryText = "
	|SELECT
	|	DataExchangeRules.RulesAreRead AS RulesAreRead
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	  DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsRegistrationRules)
	|	AND DataExchangeRules.RulesAreImported
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RulesAreRead = Selection.RulesAreRead.Get();
		If RulesAreRead = Undefined Then
			Continue;
		EndIf;
		
		FillPropertiesValuesForORRValuesTable(ObjectsRegistrationRules, RulesAreRead);
		
	EndDo;
	
	Return ObjectsRegistrationRules;
	
EndFunction

// Receives the object selective registration rule table from the infobase.
//
// Parameters:
//  No.
// 
// Returns:
//  SelectiveObjectsRegistrationRules - ValueTable - a table of general rules of selective object registration for
//                                                           ORM.
// 
Function GetSelectiveObjectsRegistrationRules() Export
	
	// Function return value.
	SelectiveObjectsRegistrationRules = SelectiveObjectsRegistrationRulesTableInitialization();
	
	QueryText = "
	|SELECT
	|	DataExchangeRules.RulesAreRead AS RulesAreRead
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	  DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectConversionRules)
	|	AND DataExchangeRules.UseSelectiveObjectRegistrationFilter
	|	AND DataExchangeRules.RulesAreImported
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExchangeRuleStructure = Selection.RulesAreRead.Get();
		
		FillPropertiesValuesForValueTable(SelectiveObjectsRegistrationRules, ExchangeRuleStructure["SelectiveObjectsRegistrationRules"]);
		
	EndDo;
	
	Return SelectiveObjectsRegistrationRules;
	
EndFunction

Function ObjectsRegistrationRulesTableInitialization() Export
	
	// Function return value.
	Rules = New ValueTable;
	
	Columns = Rules.Columns;
	
	Columns.Add("MetadataObjectName", New TypeDescription("String"));
	Columns.Add("ExchangePlanName",      New TypeDescription("String"));
	
	Columns.Add("FlagAttributeName", New TypeDescription("String"));
	
	Columns.Add("QueryText",    New TypeDescription("String"));
	Columns.Add("ObjectProperties", New TypeDescription("Structure"));
	
	Columns.Add("ObjectPropertiesString", New TypeDescription("String"));
	
	// Flag that shows whether rules are empty.
	Columns.Add("RuleByObjectPropertiesEmpty", New TypeDescription("Boolean"));
	
	// event handlers
	Columns.Add("BeforeProcess",            New TypeDescription("String"));
	Columns.Add("OnProcess",               New TypeDescription("String"));
	Columns.Add("OnProcessAdditional", New TypeDescription("String"));
	Columns.Add("AfterProcess",             New TypeDescription("String"));
	
	Columns.Add("HasBeforeProcessHandler",            New TypeDescription("Boolean"));
	Columns.Add("HasOnProcessHandler",               New TypeDescription("Boolean"));
	Columns.Add("HasOnProcessHandlerAdditional", New TypeDescription("Boolean"));
	Columns.Add("HasAfterProcessHandler",             New TypeDescription("Boolean"));
	
	Columns.Add("FilterByObjectProperties", New TypeDescription("ValueTree"));
	
	// This field is used for temporary storing data from the object or reference.
	Columns.Add("FilterByProperties", New TypeDescription("ValueTree"));
	
	// Adding the index
	Rules.Indexes.Add("ExchangePlanName, MetadataObjectName");
	
	Return Rules;
	
EndFunction

Function SelectiveObjectsRegistrationRulesTableInitialization() Export
	
	// Function return value.
	Rules = New ValueTable;
	
	Columns = Rules.Columns;
	
	Columns.Add("Order",                        New TypeDescription("Number"));
	Columns.Add("ObjectName",                     New TypeDescription("String"));
	Columns.Add("ExchangePlanName",                 New TypeDescription("String"));
	Columns.Add("TabularSectionName",              New TypeDescription("String"));
	Columns.Add("RegistrationAttributes",           New TypeDescription("String"));
	Columns.Add("RegistrationAttributesStructure", New TypeDescription("Structure"));
	
	// Adding the index
	Rules.Indexes.Add("ExchangePlanName, ObjectName");
	
	Return Rules;
	
EndFunction

Function ExchangePlanContainsNoNodes(Val ExchangePlanName)
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	#ExchangePlanTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.ThisNode");
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTableName", "ExchangePlan." + ExchangePlanName);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

Procedure FillPropertiesValuesForORRValuesTable(DestinationTable, SourceTable)
	
	For Each SourceRow In SourceTable Do
		
		FillPropertyValues(DestinationTable.Add(), SourceRow);
		
	EndDo;
	
EndProcedure

Procedure FillPropertiesValuesForValueTable(DestinationTable, SourceTable)
	
	For Each SourceRow In SourceTable Do
		
		FillPropertyValues(DestinationTable.Add(), SourceRow);
		
	EndDo;
	
EndProcedure

Function DataSynchronizationRulesDetails(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	CorrespondentVersion = CorrespondentVersion(InfobaseNode);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	Setting = NodeFiltersSettingsValues(InfobaseNode, CorrespondentVersion);
	
	DataSynchronizationRulesDetails = DataTransferRestrictionsDetails(
		ExchangePlanName, Setting, CorrespondentVersion,SavedExchangePlanNodeSettingOption(InfobaseNode));
	
	SetPrivilegedMode(False);
	
	Return DataSynchronizationRulesDetails;
	
EndFunction

Function NodeFiltersSettingsValues(Val InfobaseNode, Val CorrespondentVersion)
	
	Result = New Structure;
	
	InfobaseNodeObject = InfobaseNode.GetObject();
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	NodeFiltersSetting = NodeFilterStructure(ExchangePlanName,
		CorrespondentVersion, SavedExchangePlanNodeSettingOption(InfobaseNode));
	
	For Each Setting In NodeFiltersSetting Do
		
		If TypeOf(Setting.Value) = Type("Structure") Then
			
			TabularSection = New Structure;
			
			For Each Column In Setting.Value Do
				
				TabularSection.Insert(Column.Key, InfobaseNodeObject[Setting.Key].UnloadColumn(Column.Key));
				
			EndDo;
			
			Result.Insert(Setting.Key, TabularSection);
			
		Else
			
			Result.Insert(Setting.Key, InfobaseNodeObject[Setting.Key]);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SetDataExchangeMessageImportModeBeforeStart(Val Property, Val EnableMode) Export
	
	// You have to set the privileged mode before the procedure call.
	
	If IsSubordinateDIBNode() Then
		
		NewStructure = New Structure(SessionParameters.DataExchangeMessageImportModeBeforeStart);
		If EnableMode Then
			If NOT NewStructure.Property(Property) Then
				NewStructure.Insert(Property);
			EndIf;
		Else
			If NewStructure.Property(Property) Then
				NewStructure.Delete(Property);
			EndIf;
		EndIf;
		
		SessionParameters.DataExchangeMessageImportModeBeforeStart =
			New FixedStructure(NewStructure);
	Else
		
		SessionParameters.DataExchangeMessageImportModeBeforeStart = New FixedStructure;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangeSettingsStructureInitialization

// Initializes the data exchange subsystem to execute the exchange process.
//
// Parameters:
// 
// Returns:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
//
Function ExchangeSettingsForInfobaseNode(
	InfobaseNode,
	ActionOnExchange,
	ExchangeMessagesTransportKind,
	UseTransportSettings = True) Export
	
	// Function return value.
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = ActionOnExchange;
	ExchangeSettingsStructure.ExchangeTransportKind    = ExchangeMessagesTransportKind;
	ExchangeSettingsStructure.IsDIBExchange           = DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
	InitExchangeSettingsStructureForInfobaseNode(ExchangeSettingsStructure, UseTransportSettings);
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// Validating settings structure values for the exchange. Adding error messages to the event log.
	CheckExchangeStructure(ExchangeSettingsStructure, UseTransportSettings);
	
	// Canceling if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	If UseTransportSettings Then
		
		// Initializing the exchange message transport data processor.
		InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
		
	EndIf;
	
	// Initializing the exchange data processor.
	If ExchangeSettingsStructure.IsDIBExchange Then
		
		InitDataExchangeDataProcessor(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
		
		InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
		
	EndIf;
	
	Return ExchangeSettingsStructure;
EndFunction

Function ExchangeSettingsForExternalConnection(InfobaseNode, ActionOnExchange, TransactionItemsCount)
	
	// Function return value.
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = ActionOnExchange;
	ExchangeSettingsStructure.IsDIBExchange           = DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
	PropertyStructure = Common.ObjectAttributesValues(ExchangeSettingsStructure.InfobaseNode, "Code, Description");
	
	ExchangeSettingsStructure.InfobaseNodeCode = CorrespondentNodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.InfobaseNodeDescription = PropertyStructure.Description;
	
	ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode);
	
	If TransactionItemsCount = Undefined Then
		TransactionItemsCount = ItemsCountInTransactionOfActionBeingExecuted(ActionOnExchange);
	EndIf;
	
	ExchangeSettingsStructure.TransactionItemsCount = TransactionItemsCount;
	
	// CALCULATED VALUES
	ExchangeSettingsStructure.DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangeSettingsStructure.ExchangePlanName);
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode = NodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	
	// Getting the message key for the event log.
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
	ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.COM;
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// Validating settings structure values for the exchange. Adding error messages to the event log.
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// Canceling if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// Initializing the exchange data processor.
	InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
	
	Return ExchangeSettingsStructure;
EndFunction

// Initializes the data exchange subsystem to execute the exchange process.
//
// Parameters:
// 
// Returns:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
//
Function DataExchangeSettings(ExchangeExecutionSettings, RowNumber)
	
	// Function return value.
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	InitExchangeSettingsStructure(ExchangeSettingsStructure, ExchangeExecutionSettings, RowNumber);
	
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// Validating settings structure values for the exchange. Adding error messages to the event log.
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// Canceling if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// Initializing the exchange message transport data processor.
	InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
	
	// Initializing the exchange data processor.
	If ExchangeSettingsStructure.IsDIBExchange Then
		
		InitDataExchangeDataProcessor(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
		
		InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
		
	EndIf;
	
	Return ExchangeSettingsStructure;
EndFunction

// Gets the transport settings structure for data exchange.
//
Function ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind) Export
	
	// Function return value.
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = Enums.ActionsOnExchange.DataImport;
	ExchangeSettingsStructure.ExchangeTransportKind    = ExchangeMessagesTransportKind;
	
	InitExchangeSettingsStructureForInfobaseNode(ExchangeSettingsStructure, True);
	
	// Validating settings structure values for the exchange. Adding error messages to the event log.
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// Canceling if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// Initializing the exchange message transport data processor.
	InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
	
	Return ExchangeSettingsStructure;
EndFunction

Function ExchangeSettingsStructureForInteractiveImportSession(Val InfobaseNode, Val ExchangeMessageFileName) Export
	
	Return DataExchangeCached.ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName);
	
EndFunction

Procedure InitExchangeSettingsStructure(ExchangeSettingsStructure, ExchangeExecutionSettings, RowNumber)
	
	QueryText = "
	|SELECT
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode         AS InfobaseNode,
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode.Code     AS InfobaseNodeCode,
	|	ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind            AS ExchangeTransportKind,
	|	ExchangeExecutionSettingsExchangeSettings.CurrentAction            AS ActionOnExchange,
	|	ExchangeExecutionSettingsExchangeSettings.Ref                         AS ExchangeExecutionSettings,
	|	ExchangeExecutionSettingsExchangeSettings.Ref.Description            AS ExchangeExecutionSettingDescription,
	|	CASE
	|		WHEN ExchangeExecutionSettingsExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataImport) THEN TRUE
	|		ELSE FALSE
	|	END                                                                   AS DoDataImport,
	|	CASE
	|		WHEN ExchangeExecutionSettingsExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataExport) THEN TRUE
	|		ELSE FALSE
	|	END                                                                   AS DoDataExport
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeExecutionSettingsExchangeSettings
	|WHERE
	|	  ExchangeExecutionSettingsExchangeSettings.Ref      = &ExchangeExecutionSettings
	|	AND ExchangeExecutionSettingsExchangeSettings.LineNumber = &LineNumber
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangeExecutionSettings", ExchangeExecutionSettings);
	Query.SetParameter("LineNumber",               RowNumber);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	// Filling structure property value.
	FillPropertyValues(ExchangeSettingsStructure, Selection);
	
	ExchangeSettingsStructure.IsDIBExchange = DataExchangeCached.IsDistributedInfobaseNode(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.EventLogMessageKey = NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'");
	
	// Checking whether basic exchange settings structure fields are filled.
	CheckMainExchangeSettingsStructureFields(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	//
	ExchangeSettingsStructure.ExchangePlanName = ExchangeSettingsStructure.InfobaseNode.Metadata().Name;
	ExchangeSettingsStructure.ExchangeByObjectConversionRules = DataExchangeCached.IsUniversalDataExchangeNode(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode    = ExchangePlans[ExchangeSettingsStructure.ExchangePlanName].ThisNode();
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode = ExchangeSettingsStructure.CurrentExchangePlanNode.Code;
	
	ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName = DataExchangeMessageTransportDataProcessorName(ExchangeSettingsStructure.ExchangeTransportKind);
	
	// Getting the message key for the event log.
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeSettingsStructure.InfobaseNode) Then
		ModuleMessagesExchangeTransportSettings = InformationRegisters["MessageExchangeTransportSettings"];
		ExchangeSettingsStructure.TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(ExchangeSettingsStructure.InfobaseNode);
	Else
		ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ExchangeTransportKind);
	EndIf;
	
	ExchangeSettingsStructure.TransactionItemsCount = ItemsCountInTransactionOfActionBeingExecuted(ExchangeSettingsStructure.ActionOnExchange);
	
EndProcedure

Procedure InitExchangeSettingsStructureForInfobaseNode(
		ExchangeSettingsStructure,
		UseTransportSettings)
	
	PropertyStructure = Common.ObjectAttributesValues(ExchangeSettingsStructure.InfobaseNode, "Code, Description");
	
	ExchangeSettingsStructure.InfobaseNodeCode = CorrespondentNodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.InfobaseNodeDescription = PropertyStructure.Description;
	
	// Getting exchange transport settings.
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeSettingsStructure.InfobaseNode) Then
		ModuleMessagesExchangeTransportSettings = InformationRegisters["MessageExchangeTransportSettings"];
		ExchangeSettingsStructure.TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
			ExchangeSettingsStructure.InfobaseNode);
	Else
		ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode);
	EndIf;
	
	If ExchangeSettingsStructure.TransportSettings <> Undefined Then
		
		If UseTransportSettings Then
			
			// Using the default value if the transport kind is not specified.
			If ExchangeSettingsStructure.ExchangeTransportKind = Undefined Then
				ExchangeSettingsStructure.ExchangeTransportKind = ExchangeSettingsStructure.TransportSettings.DefaultExchangeMessagesTransportKind;
			EndIf;
			
			// Using the FILE transport if the transport kind is not specified.
			If Not ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
				
				ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FILE;
				
			EndIf;
			
			ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName = DataExchangeMessageTransportDataProcessorName(ExchangeSettingsStructure.ExchangeTransportKind);
			
		EndIf;
		
		ExchangeSettingsStructure.TransactionItemsCount = ItemsCountInTransactionOfActionBeingExecuted(ExchangeSettingsStructure.ActionOnExchange);
		
		If ExchangeSettingsStructure.TransportSettings.Property("WSUseHighVolumeDataTransfer") Then
			ExchangeSettingsStructure.UseLargeDataTransfer = ExchangeSettingsStructure.TransportSettings.WSUseHighVolumeDataTransfer;
		EndIf;
		
	EndIf;
	
	// DEFAULT VALUES
	ExchangeSettingsStructure.ExchangeExecutionSettings             = Undefined;
	ExchangeSettingsStructure.ExchangeExecutionSettingDescription = "";
	
	// CALCULATED VALUES
	ExchangeSettingsStructure.DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.ExchangeByObjectConversionRules = DataExchangeCached.IsUniversalDataExchangeNode(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode    = ExchangePlans[ExchangeSettingsStructure.ExchangePlanName].ThisNode();
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode = NodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	
	// Getting the message key for the event log.
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
EndProcedure

Function BaseExchangeSettingsStructure()
	
	ExchangeSettingsStructure = New Structure;
	
	// Structure of settings by query fields.
	
	ExchangeSettingsStructure.Insert("StartDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("EndDate");
	
	ExchangeSettingsStructure.Insert("LineNumber");
	ExchangeSettingsStructure.Insert("ExchangeExecutionSettings");
	ExchangeSettingsStructure.Insert("ExchangeExecutionSettingDescription");
	ExchangeSettingsStructure.Insert("InfobaseNode");
	ExchangeSettingsStructure.Insert("InfobaseNodeCode", "");
	ExchangeSettingsStructure.Insert("InfobaseNodeDescription", "");
	ExchangeSettingsStructure.Insert("ExchangeTransportKind");
	ExchangeSettingsStructure.Insert("ActionOnExchange");
	ExchangeSettingsStructure.Insert("TransactionItemsCount", 1); // each item requires a single transaction.
	ExchangeSettingsStructure.Insert("DoDataImport", False);
	ExchangeSettingsStructure.Insert("DoDataExport", False);
	ExchangeSettingsStructure.Insert("UseLargeDataTransfer", False);
	
	// Additional settings structure.
	ExchangeSettingsStructure.Insert("Cancel", False);
	ExchangeSettingsStructure.Insert("IsDIBExchange", False);
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor");
	ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor");
	
	ExchangeSettingsStructure.Insert("ExchangePlanName");
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNode");
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNodeCode");
	
	ExchangeSettingsStructure.Insert("ExchangeByObjectConversionRules", False);
	
	ExchangeSettingsStructure.Insert("DataExchangeMessageTransportDataProcessorName");
	
	ExchangeSettingsStructure.Insert("EventLogMessageKey");
	
	ExchangeSettingsStructure.Insert("TransportSettings");
	
	ExchangeSettingsStructure.Insert("ObjectConversionRules");
	ExchangeSettingsStructure.Insert("RulesAreImported", False);
	
	ExchangeSettingsStructure.Insert("ExportHandlersDebug", False);
	ExchangeSettingsStructure.Insert("ImportHandlersDebug", False);
	ExchangeSettingsStructure.Insert("ExportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructure.Insert("ImportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructure.Insert("DataExchangeLoggingMode", False);
	ExchangeSettingsStructure.Insert("ExchangeProtocolFileName", "");
	ExchangeSettingsStructure.Insert("ContinueOnError", False);
	
	// Structure for passing arbitrary additional parameters.
	ExchangeSettingsStructure.Insert("AdditionalParameters", New Structure);
	
	// Structure for adding event log entries.
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult");
	ExchangeSettingsStructure.Insert("ActionOnExchange");
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("MessageOnExchange",           "");
	ExchangeSettingsStructure.Insert("ErrorMessageString",      "");
	
	Return ExchangeSettingsStructure;
EndFunction

Procedure CheckMainExchangeSettingsStructureFields(ExchangeSettingsStructure)
	
	If NOT ValueIsFilled(ExchangeSettingsStructure.InfobaseNode) Then
		
		// The infobase node must be specified.
		ErrorMessageString = NStr(
		"ru = 'Не задан узел информационной базы с которым нужно производить обмен информацией. Обмен отменен.'; en = 'The peer infobase node is not specified. The exchange is canceled.'; pl = 'Nie określono węzła bazy informacyjnej do wymiany informacji. Wymiana została anulowana.';de = 'Infobase-Knoten, mit denen Informationen ausgetauscht werden sollen, sind nicht spezifiziert. Austausch wird abgebrochen.';ro = 'Nodul bazei de date cu care se schimbă informațiile nu este specificat. Schimbul este anulat.';tr = 'Bilgilerin değiştirileceği veritabanı ünitesi belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Nodo de la infobase con el cual la información tiene que intercambiarse, no está especificado. Intercambio se ha cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf NOT ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
		
		ErrorMessageString = NStr("ru = 'Не задан вид транспорта обмена. Обмен отменен.'; en = 'The exchange transport type is not specified. The exchange is canceled.'; pl = 'Nie określono rodzaju transportu wymiany. Wymiana została anulowana.';de = 'Austausch-Transportart ist nicht angegeben. Austausch wird abgebrochen.';ro = 'Nu este specificat un tip de transport de schimb. Schimbul este anulat.';tr = 'Değişim taşıma türü belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Tipo de transporte de intercambio no está especificado. Intercambio está cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf NOT ValueIsFilled(ExchangeSettingsStructure.ActionOnExchange) Then
		
		ErrorMessageString = NStr("ru = 'Не указано выполняемое действие (выгрузка / загрузка). Обмен отменен.'; en = 'The action (export or import) is not specified. The exchange is canceled.'; pl = 'Nie określono wykonywanego działania (eksport/import). Wymiana została anulowana.';de = 'Ausgeführte Aktion (Export / Import) ist nicht angegeben. Austausch wird abgebrochen.';ro = 'Acțiunea executată (export/ import) nu este specificată. Schimbul este anulat.';tr = 'Yürütülen eylem (dışa aktarma / içe aktarma) belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Acción ejecutada (exportación/importación) no está especificada. Intercambio se ha cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

Procedure CheckExchangeStructure(ExchangeSettingsStructure, UseTransportSettings = True)
	
	If NOT ValueIsFilled(ExchangeSettingsStructure.InfobaseNode) Then
		
		// The infobase node must be specified.
		ErrorMessageString = NStr(
		"ru = 'Не задан узел информационной базы с которым нужно производить обмен информацией. Обмен отменен.'; en = 'The peer infobase node is not specified. The exchange is canceled.'; pl = 'Nie określono węzła bazy informacyjnej do wymiany informacji. Wymiana została anulowana.';de = 'Infobase-Knoten, mit denen Informationen ausgetauscht werden sollen, sind nicht spezifiziert. Austausch wird abgebrochen.';ro = 'Nodul bazei de date cu care se schimbă informațiile nu este specificat. Schimbul este anulat.';tr = 'Bilgilerin değiştirileceği veritabanı ünitesi belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Nodo de la infobase con el cual la información tiene que intercambiarse, no está especificado. Intercambio se ha cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf UseTransportSettings AND NOT ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
		
		ErrorMessageString = NStr("ru = 'Не задан вид транспорта обмена. Обмен отменен.'; en = 'The exchange transport type is not specified. The exchange is canceled.'; pl = 'Nie określono rodzaju transportu wymiany. Wymiana została anulowana.';de = 'Austausch-Transportart ist nicht angegeben. Austausch wird abgebrochen.';ro = 'Nu este specificat un tip de transport de schimb. Schimbul este anulat.';tr = 'Değişim taşıma türü belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Tipo de transporte de intercambio no está especificado. Intercambio está cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf NOT ValueIsFilled(ExchangeSettingsStructure.ActionOnExchange) Then
		
		ErrorMessageString = NStr("ru = 'Не указано выполняемое действие (выгрузка / загрузка). Обмен отменен.'; en = 'The action (export or import) is not specified. The exchange is canceled.'; pl = 'Nie określono wykonywanego działania (eksport/import). Wymiana została anulowana.';de = 'Ausgeführte Aktion (Export / Import) ist nicht angegeben. Austausch wird abgebrochen.';ro = 'Acțiunea executată (export/ import) nu este specificată. Schimbul este anulat.';tr = 'Yürütülen eylem (dışa aktarma / içe aktarma) belirtilmemiş. Değişim iptal edildi.'; es_ES = 'Acción ejecutada (exportación/importación) no está especificada. Intercambio se ha cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.InfobaseNode.DeletionMark Then
		
		// The infobase node cannot be marked for deletion.
		ErrorMessageString = NStr("ru = 'Узел информационной базы помечен на удаление. Обмен отменен.'; en = 'The infobase node is marked for deletion. The exchange is canceled.'; pl = 'Węzeł bazy informacyjnej jest oznaczony do usunięcia. Wymiana została anulowana.';de = 'Der Infobase-Knoten ist zum Löschen markiert. Austausch wird abgebrochen.';ro = 'Nod baza de date este marcat pentru ștergere. Schimbul este anulat.';tr = 'Veritabanı ünitesi silinmek üzere işaretlendi. Değişim iptal edildi.'; es_ES = 'Nodo de la infobase está marcado para borrar. Intercambio está cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
	
	ElsIf ExchangeSettingsStructure.InfobaseNode = ExchangeSettingsStructure.CurrentExchangePlanNode Then
		
		// The exchange with the current infobase node cannot be provided.
		ErrorMessageString = NStr(
		"ru = 'Нельзя организовать обмен данными с текущим узлом информационной базы. Обмен отменен.'; en = 'Cannot exchange data with this infobase node. The exchange is canceled.'; pl = 'Nie można poprawnie połączyć się z bieżącym węzłem bazy informacyjnej. Wymiana została anulowana.';de = 'Kommunikation mit dem aktuellen Infobase-Knoten nicht möglich. Der Austausch wurde storniert.';ro = 'Nu se permite organizarea schimbului de date cu nodul curent al bazei de informații. Schimb revocat.';tr = 'Mevcut veritabanı ünitesi ile düzgün bir şekilde iletişim kurulamıyor. Değişim iptal edildi.'; es_ES = 'No se puede comunicarse de forma apropiada con el nodo de la infobase actual. El intercambio se ha cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
	
	ElsIf IsBlankString(ExchangeSettingsStructure.InfobaseNodeCode)
		  OR IsBlankString(ExchangeSettingsStructure.CurrentExchangePlanNodeCode) Then
		
		// The infobase codes must be specified.
		ErrorMessageString = NStr("ru = 'Один из узлов обмена имеет пустой код. Обмен отменен.'; en = 'One of the exchange nodes has a blank code. The exchange is canceled.'; pl = 'Jeden z węzłów wymiany ma pusty kod. Wymiana została anulowana.';de = 'Einer der Austausch-Knoten hat einen leeren Code. Austausch wird abgebrochen.';ro = 'Unul dintre nodurile de schimb are un cod gol. Schimbul este anulat.';tr = 'Değişim ünitelerinden birinin boş bir kodu mevcut. Değişim iptal edildi.'; es_ES = 'Uno de los nodos de intercambio tiene un código vacío. Intercambio está cancelado.'",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExportHandlersDebug Then
		
		ExportDataProcessorFile = New File(ExchangeSettingsStructure.ExportDebugExternalDataProcessorFileName);
		
		If Not ExportDataProcessorFile.Exist() Then
			
			ErrorMessageString = NStr("ru = 'Файл внешней обработки для отладки выгрузки не существует. Обмен отменен.'; en = 'The file of the external data processor for export debugging does not exist. The exchange is canceled.'; pl = 'Zewnętrzny plik opracowania do debugowania eksportu nie istnieje. Wymiana została anulowana.';de = 'Externe Datenprozessordatei für Export-Debugging ist nicht vorhanden. Austausch wird abgebrochen.';ro = 'Fișierul procesor de date extern pentru depanarea exportului nu există. Schimbul este anulat.';tr = 'Dışa aktarma hata ayıklaması için harici veri işlemci dosyası mevcut değil. Değişim iptal edildi.'; es_ES = 'Archivo del procesador de datos externo para la depuración de la exportación no existe. Intercambio está cancelado.'",
				Common.DefaultLanguageCode());
			WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
			
			SetExchangeInitEnd(ExchangeSettingsStructure);
			
		EndIf;
		
	ElsIf ExchangeSettingsStructure.ImportHandlersDebug Then
		
		ImportDataProcessorFile = New File(ExchangeSettingsStructure.ImportDebugExternalDataProcessorFileName);
		
		If Not ImportDataProcessorFile.Exist() Then
			
			ErrorMessageString = NStr("ru = 'Файл внешней обработки для отладки загрузки не существует. Обмен отменен.'; en = 'The file of the external data processor for import debugging does not exist. The exchange is canceled.'; pl = 'Zewnętrzny plik opracowania do debugowania importu nie istnieje. Wymiana została anulowana.';de = 'Externe Datenprozessordatei für Import-Debugging ist nicht vorhanden. Austausch wird abgebrochen.';ro = 'Fișierul procesor de date extern pentru depanarea importului nu există. Schimbul este anulat.';tr = 'İçe aktarmadaki hata ayıklaması için harici veri işlemci dosyası mevcut değil. Değişim iptal edildi.'; es_ES = 'Archivo del procesador de datos externo para la depuración de la importación no existe. Intercambio está cancelado.'",
				Common.DefaultLanguageCode());
			WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
			
			SetExchangeInitEnd(ExchangeSettingsStructure);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitDataExchangeDataProcessor(ExchangeSettingsStructure)
	
	// Canceling initialization if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	// create
	DataExchangeDataProcessor = DataProcessors.DistributedInfobasesObjectsConversion.Create();
	
	// Initializing properties
	DataExchangeDataProcessor.InfobaseNode          = ExchangeSettingsStructure.InfobaseNode;
	DataExchangeDataProcessor.TransactionItemsCount  = ExchangeSettingsStructure.TransactionItemsCount;
	DataExchangeDataProcessor.EventLogMessageKey = ExchangeSettingsStructure.EventLogMessageKey;
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor", DataExchangeDataProcessor);
	
EndProcedure

Procedure InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure)
	
	Var DataExchangeDataProcessor;
	
	// Canceling initialization if settings contain errors.
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	If ExchangeSettingsStructure.DoDataExport Then
		
		DataExchangeDataProcessor = DataExchangeDataProcessorForExport(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.DoDataImport Then
		
		DataExchangeDataProcessor = DataExchangeDataProcessorForImport(ExchangeSettingsStructure);
		
	EndIf;
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor", DataExchangeDataProcessor);
	
EndProcedure

Procedure InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure)
	
	If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
		InitMessagesOfExchangeWithExternalSystemTransportProcessing(ExchangeSettingsStructure);
		Return;
	EndIf;
	
	// Creating a transport data processor.
	ExchangeMessageTransportDataProcessor = DataProcessors[ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName].Create();
	
	IsOutgoingMessage = ExchangeSettingsStructure.DoDataExport;
	
	Transliteration = Undefined;
	SettingsDictionary = New Map;
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.FILE,  "FILETransliterateExchangeMessageFileNames");
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.EMAIL, "EMAILTransliterateExchangeMessageFileNames");
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.FTP,   "FTPTransliterateExchangeMessageFileNames");
	
	PropertyNameTransliteration = SettingsDictionary.Get(ExchangeSettingsStructure.ExchangeTransportKind);
	If ValueIsFilled(PropertyNameTransliteration) Then
		ExchangeSettingsStructure.TransportSettings.Property(PropertyNameTransliteration, Transliteration);
	EndIf;
	
	Transliteration = ?(Transliteration = Undefined, False, Transliteration);
	
	// Filling in common attributes (the same for all transport data processors).
	ExchangeMessageTransportDataProcessor.MessageFileNamePattern = MessageFileNamePattern(
		ExchangeSettingsStructure.CurrentExchangePlanNode,
		ExchangeSettingsStructure.InfobaseNode,
		IsOutgoingMessage,
		Transliteration);
	
	// Filling in transport settings (various for each transport data processor).
	FillPropertyValues(ExchangeMessageTransportDataProcessor, ExchangeSettingsStructure.TransportSettings);
	
	// Initializing the transport
	ExchangeMessageTransportDataProcessor.Initializing();
	
	ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor", ExchangeMessageTransportDataProcessor);
	
EndProcedure

Function DataExchangeDataProcessorForExport(ExchangeSettingsStructure)
	
	DataProcessorManager = ?(IsXDTOExchangePlan(ExchangeSettingsStructure.InfobaseNode),
		DataProcessors.ConvertXTDOObjects,
		DataProcessors.InfobaseObjectConversion);
	
	DataExchangeDataProcessor = DataProcessorManager.Create();
	
	DataExchangeDataProcessor.ExchangeMode = "DataExported";
	
	// If the data processor supports the conversion rule mechanism, the following actions can be executed.
	If DataExchangeDataProcessor.Metadata().Attributes.Find("ExchangeRuleFileName") <> Undefined Then
		SetDataExportExchangeRules(DataExchangeDataProcessor, ExchangeSettingsStructure);
		DataExchangeDataProcessor.DoNotExportObjectsByRefs = True;
		DataExchangeDataProcessor.ExchangeRuleFileName        = "1";
	EndIf;
	
	// If the data processor supports the background exchange, the following actions can be executed.
	If DataExchangeDataProcessor.Metadata().Attributes.Find("BackgroundExchangeNode") <> Undefined Then
		DataExchangeDataProcessor.BackgroundExchangeNode = Undefined;
	EndIf;
		
	DataExchangeDataProcessor.NodeForExchange = ExchangeSettingsStructure.InfobaseNode;
	
	SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure);
	
	Return DataExchangeDataProcessor;
	
EndFunction

Function DataExchangeDataProcessorForImport(ExchangeSettingsStructure)
	
	DataProcessorManager = ?(IsXDTOExchangePlan(ExchangeSettingsStructure.InfobaseNode),
		DataProcessors.ConvertXTDOObjects,
		DataProcessors.InfobaseObjectConversion);
	
	DataExchangeDataProcessor = DataProcessorManager.Create();
	
	DataExchangeDataProcessor.ExchangeMode = "Load";
	DataExchangeDataProcessor.ExchangeNodeDataImport = ExchangeSettingsStructure.InfobaseNode;
	
	If DataExchangeDataProcessor.Metadata().Attributes.Find("ExchangeRuleFileName") <> Undefined Then
		SetDataImportExchangeRules(DataExchangeDataProcessor, ExchangeSettingsStructure);
	EndIf;
	
	SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure);
	
	Return DataExchangeDataProcessor
	
EndFunction

Procedure SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure, ExchangeWithSSL20 = False)
	
	DataExchangeDataProcessor.AppendDataToExchangeLog = False;
	DataExchangeDataProcessor.ExportAllowedObjectsOnly      = False;
	
	DataExchangeDataProcessor.UseTransactions         = ExchangeSettingsStructure.TransactionItemsCount <> 1;
	DataExchangeDataProcessor.ObjectsPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
	
	DataExchangeDataProcessor.EventLogMessageKey = ExchangeSettingsStructure.EventLogMessageKey;
	
	If Not ExchangeWithSSL20 Then
		
		SetDebugModeSettingsForDataProcessor(DataExchangeDataProcessor, ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

Procedure SetDataExportExchangeRules(DataExchangeXMLDataProcessor, ExchangeSettingsStructure)
	
	ObjectsConversionRules = InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangeSettingsStructure.ExchangePlanName);
	
	If ObjectsConversionRules = Undefined Then
		
		// Exchange rules must be specified.
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не заданы правила конвертации для плана обмена %1. Выгрузка данных отменена.'; en = 'Conversion rules are not specified for exchange plan %1. The data export is canceled.'; pl = 'Nie określono reguł konwersji dla planu wymiany %1. Eksport danych został anulowany.';de = 'Konvertierungsregeln sind für den Austauschplan nicht angegeben %1. Der Datenexport ist abgebrochen.';ro = 'Normele de conversie nu sunt specificate pentru planul de schimb %1. Exportul de date este anulat.';tr = 'Değişim planı için dönüştürme kuralları belirtilmemiş. %1Veri dışa aktarma iptal edildi.'; es_ES = 'Reglas de conversión no están especificadas para el plan de intercambio %1. Exportación de datos está cancelada.'", Common.DefaultLanguageCode()),
			ExchangeSettingsStructure.ExchangePlanName);
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
		Return;
	EndIf;
	
	DataExchangeXMLDataProcessor.SavedSettings = ObjectsConversionRules;
	
	Try
		DataExchangeXMLDataProcessor.RestoreRulesFromInternalFormat();
	Except
		WriteEventLogDataExchange(DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		Return;
	EndTry;
	
EndProcedure

Procedure SetDataImportExchangeRules(DataExchangeXMLDataProcessor, ExchangeSettingsStructure)
	
	ObjectsConversionRules = InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangeSettingsStructure.ExchangePlanName, True);
	
	If ObjectsConversionRules = Undefined Then
		
		// Exchange rules must be specified.
		NString = NStr("ru = 'Не заданы правила конвертации для плана обмена %1. Загрузка данных отменена.'; en = 'Conversion rules are not specified for exchange plan %1. The data import is canceled.'; pl = 'Nie określono reguł konwersji dla planu wymiany %1. Import danych został anulowany.';de = 'Konvertierungsregeln sind für den Austauschplan nicht angegeben %1. Der Datenimport ist abgebrochen.';ro = 'Normele de conversie nu sunt specificate pentru planul de schimb %1. Importul de date este anulat.';tr = 'Değişim planı için dönüştürme kuralları belirtilmemiş. %1Veri içe aktarma iptal edildi.'; es_ES = 'Reglas de conversión no están especificadas para el plan de intercambio %1. Importación de datos está cancelada.'",
			Common.DefaultLanguageCode());
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, ExchangeSettingsStructure.ExchangePlanName);
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		
		Return;
	EndIf;
	
	DataExchangeXMLDataProcessor.SavedSettings = ObjectsConversionRules;
	
	Try
		DataExchangeXMLDataProcessor.RestoreRulesFromInternalFormat();
	Except
		WriteEventLogDataExchange(BriefErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
		SetExchangeInitEnd(ExchangeSettingsStructure);
		Return;
	EndTry;
	
EndProcedure

// Reads debugging settings from the infobase and sets them for the exchange structure.
//
Procedure SetDebugModeSettingsForStructure(ExchangeSettingsStructure, IsExternalConnection = False)
	
	QueryText = "SELECT
	|	CASE
	|		WHEN &PerformDataExport
	|			THEN DataExchangeRules.ExportDebugMode
	|		ELSE FALSE
	|	END AS ExportHandlersDebug,
	|	CASE
	|		WHEN &PerformDataExport
	|			THEN DataExchangeRules.ExportDebuggingDataProcessorFileName
	|		ELSE """"
	|	END AS ExportDebugExternalDataProcessorFileName,
	|	CASE
	|		WHEN &PerformDataImport
	|			THEN DataExchangeRules.ImportDebugMode
	|		ELSE FALSE
	|	END AS ImportHandlersDebug,
	|	CASE
	|		WHEN &PerformDataImport
	|			THEN DataExchangeRules.ImportDebuggingDataProcessorFileName
	|		ELSE """"
	|	END AS ImportDebugExternalDataProcessorFileName,
	|	DataExchangeRules.DataExchangeLoggingMode AS DataExchangeLoggingMode,
	|	DataExchangeRules.ExchangeProtocolFileName AS ExchangeProtocolFileName,
	|	DataExchangeRules.DoNotStopOnError AS ContinueOnError
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectConversionRules)
	|	AND DataExchangeRules.DebugMode";
	
	Query = New Query;
	Query.Text = QueryText;
	
	DoDataExport = False;
	If Not ExchangeSettingsStructure.Property("DoDataExport", DoDataExport) Then
		DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	EndIf;
	
	DoDataImport = False;
	If Not ExchangeSettingsStructure.Property("DoDataImport", DoDataImport) Then
		DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	EndIf;
	
	Query.SetParameter("ExchangePlanName", ExchangeSettingsStructure.ExchangePlanName);
	Query.SetParameter("PerformDataExport", DoDataExport);
	Query.SetParameter("PerformDataImport", DoDataImport);
	
	Result = Query.Execute();
	
	ProtocolFileName = "";
	If IsExternalConnection AND ExchangeSettingsStructure.Property("ExchangeProtocolFileName", ProtocolFileName)
		AND Not IsBlankString(ProtocolFileName) Then
		
		ExchangeSettingsStructure.ExchangeProtocolFileName = AddLiteralToFileName(ProtocolFileName, "ExternalConnection")
	
	EndIf;
	
	If Not Result.IsEmpty() AND Not Common.DataSeparationEnabled() Then
		
		SettingsTable = Result.Unload();
		TableRow = SettingsTable[0];
		
		FillPropertyValues(ExchangeSettingsStructure, TableRow);
		
	EndIf;
	
EndProcedure

// Reads debugging settings from the infobase and sets them for the structure of exchange settings.
//
Procedure SetDebugModeSettingsForDataProcessor(DataExchangeDataProcessor, ExchangeSettingsStructure)
	
	If ExchangeSettingsStructure.Property("ExportDebugExternalDataProcessorFileName")
		AND DataExchangeDataProcessor.Metadata().Attributes.Find("ExportDebugExternalDataProcessorFileName") <> Undefined Then
		
		DataExchangeDataProcessor.ExportHandlersDebug = ExchangeSettingsStructure.ExportHandlersDebug;
		DataExchangeDataProcessor.ImportHandlersDebug = ExchangeSettingsStructure.ImportHandlersDebug;
		DataExchangeDataProcessor.ExportDebugExternalDataProcessorFileName = ExchangeSettingsStructure.ExportDebugExternalDataProcessorFileName;
		DataExchangeDataProcessor.ImportDebugExternalDataProcessorFileName = ExchangeSettingsStructure.ImportDebugExternalDataProcessorFileName;
		DataExchangeDataProcessor.DataExchangeLoggingMode = ExchangeSettingsStructure.DataExchangeLoggingMode;
		DataExchangeDataProcessor.ExchangeProtocolFileName = ExchangeSettingsStructure.ExchangeProtocolFileName;
		DataExchangeDataProcessor.ContinueOnError = ExchangeSettingsStructure.ContinueOnError;
		
		If ExchangeSettingsStructure.DataExchangeLoggingMode Then
			
			If ExchangeSettingsStructure.ExchangeProtocolFileName = "" Then
				DataExchangeDataProcessor.OutputInfoMessagesToMessageWindow = True;
				DataExchangeDataProcessor.OutputInfoMessagesToProtocol = False;
			Else
				DataExchangeDataProcessor.OutputInfoMessagesToMessageWindow = False;
				DataExchangeDataProcessor.OutputInfoMessagesToProtocol = True;
				DataExchangeDataProcessor.ExchangeProtocolFileName = ExchangeSettingsStructure.ExchangeProtocolFileName;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets up export settings for the data processor.
//
Procedure SetExportDebugSettingsForExchangeRules(DataExchangeDataProcessor, ExchangePlanName, DebugMode) Export
	
	QueryText = "SELECT
	|	DataExchangeRules.ExportDebugMode AS ExportHandlersDebug,
	|	DataExchangeRules.ExportDebuggingDataProcessorFileName AS ExportDebugExternalDataProcessorFileName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectConversionRules)
	|	AND &DebugMode = TRUE";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	Query.SetParameter("DebugMode", DebugMode);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Or Common.DataSeparationEnabled() Then
		
		DataExchangeDataProcessor.ExportHandlersDebug = False;
		DataExchangeDataProcessor.ExportDebugExternalDataProcessorFileName = "";
		
	Else
		
		SettingsTable = Result.Unload();
		DebuggingSettings = SettingsTable[0];
		
		FillPropertyValues(DataExchangeDataProcessor, DebuggingSettings);
		
	EndIf;
	
EndProcedure

Procedure SetExchangeInitEnd(ExchangeSettingsStructure)
	
	ExchangeSettingsStructure.Cancel = True;
	ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
	
EndProcedure

Function MessageFileNamePattern(CurrentExchangePlanNode, InfobaseNode, IsOutgoingMessage, Transliteration = False, UseVirtualNodeCodeOnGet = False) Export
	
	If IsOutgoingMessage Then
		SenderCode = NodeIDForExchange(InfobaseNode);
		RecipientCode  = CorrespondentNodeIDForExchange(InfobaseNode);
	Else
		SenderCode = CorrespondentNodeIDForExchange(InfobaseNode);
		RecipientCode  = NodeIDForExchange(InfobaseNode);
	EndIf;
	
	If IsOutgoingMessage Or UseVirtualNodeCodeOnGet Then
		// Exchange with a correspondent which is unfamiliar with a new predefined node code - upon 
		// generating an exchange message file name, the register code is used instead of a predefined node code.
		PredefinedNodeAlias = PredefinedNodeAlias(InfobaseNode);
		If ValueIsFilled(PredefinedNodeAlias) Then
			If IsOutgoingMessage Then
				SenderCode = PredefinedNodeAlias;
			Else
				RecipientCode = PredefinedNodeAlias;
			EndIf;
		EndIf;
	EndIf;
	
	MessageFileName = ExchangeMessageFileName(SenderCode, RecipientCode, IsOutgoingMessage);
	
	// Considering the transliteration setting for the exchange plan node.
	If Transliteration Then
		MessageFileName = StringFunctionsClientServer.LatinString(MessageFileName);
	EndIf;
	
	Return MessageFileName;
	
EndFunction

Function PredefinedNodeAlias(CorrespondentNode) Export
	
	If Not IsXDTOExchangePlan(CorrespondentNode) Then
		Return "";
	EndIf;
	
	Query = New Query(
	"SELECT
	|	PredefinedNodesAliases.NodeCode AS NodeCode
	|FROM
	|	InformationRegister.PredefinedNodesAliases AS PredefinedNodesAliases
	|WHERE
	|	PredefinedNodesAliases.Correspondent = &InfobaseNode");
	Query.SetParameter("InfobaseNode", CorrespondentNode);
	
	PredefinedNodeAlias = "";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		PredefinedNodeAlias = TrimAll(Selection.NodeCode);
	EndIf;
	
	Return PredefinedNodeAlias;
	
EndFunction

Procedure CheckNodesCodes(DataAnalysisResultToExport, InfobaseNode) Export
	If NOT IsXDTOExchangePlan(InfobaseNode) Then
		Return;
	EndIf;

	IBNodeCode = Common.ObjectAttributeValue(InfobaseNode,"Code");
	If ValueIsFilled(DataAnalysisResultToExport.NewFrom) Then
		CorrespondentNodeRecoded = (IBNodeCode = DataAnalysisResultToExport.NewFrom);
		If NOT CorrespondentNodeRecoded
			AND DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(InfobaseNode) Then
			ExchangeNodeObject = InfobaseNode.GetObject();
			ExchangeNodeObject.Code = DataAnalysisResultToExport.NewFrom;
			ExchangeNodeObject.DataExchange.Load = True;
			ExchangeNodeObject.Write();
			CorrespondentNodeRecoded = True;
		EndIf;
	Else
		CorrespondentNodeRecoded = True;
	EndIf;
	If CorrespondentNodeRecoded Then
		PredefinedNodeAlias = PredefinedNodeAlias(InfobaseNode);
		If ValueIsFilled(PredefinedNodeAlias)
			AND DataAnalysisResultToExport.CorrespondentSupportsDataExchangeID Then
			// This might be a good time to delete the record. Checking the To section.
			ExchangePlanName = InfobaseNode.Metadata().Name;
			PredefinedNodeCode = CodeOfPredefinedExchangePlanNode(ExchangePlanName);
			If TrimAll(PredefinedNodeCode) = DataAnalysisResultToExport.To Then
				DeleteRecordSetFromInformationRegister(New Structure("Correspondent", InfobaseNode),
					"PredefinedNodesAliases");
			EndIf;
		EndIf;
	EndIf;
EndProcedure

Procedure InitMessagesOfExchangeWithExternalSystemTransportProcessing(ExchangeSettingsStructure)
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		
		ExchangeMessageTransportDataProcessor = DataProcessors[ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName].Create();
		
		AttachmentParameters = InformationRegisters.DataExchangeTransportSettings.ExternalSystemTransportSettings(
			ExchangeSettingsStructure.InfobaseNode);
		
		// Initialing transport.
		ExchangeMessageTransportDataProcessor.Initializing(AttachmentParameters);
		
		ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor", ExchangeMessageTransportDataProcessor);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataExchangeIssuesDashboardOperations

Function DataExchangeIssueCount(ExchangeNodes = Undefined)
	
	IssueSearchParameters = InformationRegisters.DataExchangeResults.IssueSearchParameters();
	IssueSearchParameters.ExchangePlanNodes = ExchangeNodes;
	
	IssueSearchParameters.IssueType = New Array;
	IssueSearchParameters.IssueType.Add(Enums.DataExchangeIssuesTypes.BlankAttributes);
	IssueSearchParameters.IssueType.Add(Enums.DataExchangeIssuesTypes.UnpostedDocument);
	IssueSearchParameters.IssueType.Add(Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError);
	
	Return InformationRegisters.DataExchangeResults.IssuesCount(IssueSearchParameters);
	
EndFunction

Function VersioningIssuesCount(ExchangeNodes = Undefined, Val QueryParameters = Undefined) Export
	
	If QueryParameters = Undefined Then
		QueryParameters = QueryParametersVersioningIssuesCount();
	EndIf;
	
	VersioningUsed = DataExchangeCached.VersioningUsed(, True);
	
	If VersioningUsed Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		Return ModuleObjectsVersioning.ConflictOrRejectedItemCount(
			ExchangeNodes,
			QueryParameters.IsConflictCount,
			QueryParameters.IncludingIgnored,
			QueryParameters.Period,
			QueryParameters.SearchString);
	EndIf;
		
	Return 0;
	
EndFunction

Function QueryParametersVersioningIssuesCount() Export
	
	Result = New Structure;
	
	Result.Insert("IsConflictCount",      Undefined);
	Result.Insert("IncludingIgnored", False);
	Result.Insert("Period",                     Undefined);
	Result.Insert("SearchString",               "");
	
	Return Result;
	
EndFunction

// Registers errors upon deferred document posting in the exchange issue monitor.
//
// Parameters:
//	Object - DocumentObject - errors occurred during deferred posting of this document.
//	ExchangeNode - ExchangePlanRef - an infobase node the document is received from. 
//	ErrorMessage - String - a message text for the event log.
//    It is recommended to pass the result of BriefErrorDescription(ErrorInfo()) in this parameter.
//    Message text to display in the monitor is compiled from system user messages that are 
//    generated but are not displayed to a user yet. Therefore, we recommend you to delete cached 
//    messages before calling this method.
//	RecordIssuesInExchangeResults - Boolean - issues must be registered.
//
// Example:
// Procedure PostDocumentOnImport(Document, ExchangeNode)
// Document.DataExchange.Import = True;
// Document.Write();
// Document.DataExchange.Import = False;
// Cancel = False;
//
// Try
// 	Document.Write(DocumentWriteMode.Posting);
// Except
// 	ErrorMessage = BriefErrorPresentation(ErrorInformation());
// 	Cancel = True;
// EndTry;
//
// If Cancel Then
// 	DataExchangeServer.RecordDocumentPostingError(Document, ExchangeNode, ErrorMessage);
// EndIf;
//
// EndProcedure;
//
Procedure RecordDocumentPostingError(
		Object,
		ExchangeNode,
		ExceptionText,
		RecordIssuesInExchangeResults = True) Export
	
	UserMessages = GetUserMessages(True);
	MessageText = ExceptionText;
	For Each Message In UserMessages Do
		If StrFind(Message.Text, TimeConsumingOperations.ProgressMessage()) > 0 Then
			Continue;
		EndIf;
		MessageText = MessageText + ?(IsBlankString(MessageText), "", Chars.LF) + Message.Text;
	EndDo;
	
	ErrorReason = MessageText;
	If Not IsBlankString(TrimAll(MessageText)) Then
		
		ErrorReason = " " + NStr("ru = 'По причине %1.'; en = 'Reason: %1.'; pl = 'Z powodu %1.';de = 'Aus dem Grund %1.';ro = 'Din motivul %1.';tr = '%1 nedeniyle.'; es_ES = 'A causa de %1.'");
		ErrorReason = StringFunctionsClientServer.SubstituteParametersToString(ErrorReason, MessageText);
		
	EndIf;
	
	MessageString = NStr("ru = 'Не удалось провести документ %1, полученный из другой информационной базы.%2
		|Возможно не заполнены все реквизиты, обязательные к заполнению.'; 
		|en = 'Cannot post document %1 received from another infobase. %2
		|Probably some of the required attributes are blank.'; 
		|pl = 'Nie udało się zaksięgować dokument %1, otrzymany z innej bazy informacyjnej.%2
		|Możliwie, że nie są wypełnione wszystkie atrybuty, obowiązkowe do wypełnienia.';
		|de = 'Das Dokument %1, das von einer anderen Infobase empfangen wurde, konnte nicht gepostet werden.%2
		|Wahrscheinlich sind nicht alle Details ausgefüllt, die ausgefüllt werden müssen.';
		|ro = 'Eșec la validarea documentului %1 primit din altă bază de informații.%2
		|Posibil, nu sunt completate toate atributele obligatorii pentru completare.';
		|tr = 'Başka bir veritabanından %1 alınan belge gönderilemedi. %2
		|Tüm gerekli özellikler doldurulmamış olabilir.'; 
		|es_ES = 'No se ha podido validar el documento %1 recibido de otra base de información.%2
		|Es posible que no todos los requisitos estén rellenados que son obligatorios para rellenar.'",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(Object), ErrorReason);
	
	WriteLogEvent(EventLogMessageTextDataExchange(), EventLogLevel.Warning,,, MessageString);
	
	If RecordIssuesInExchangeResults Then
		InformationRegisters.DataExchangeResults.RecordDocumentCheckError(Object.Ref, ExchangeNode,
			MessageText, Enums.DataExchangeIssuesTypes.UnpostedDocument);
	EndIf;
	
EndProcedure

// Registers errors upon deferred object writing in the exchange issue monitor.
//
// Parameters:
//	Object - Object of reference type - errors occurred during deferred writing of this object.
//	ExchangeNode - ExchangePlanRef - an infobase node the object was received from. 
//	ErrorMessage - String - a message text for the event log.
//    It is recommended to pass the result of BriefErrorDescription(ErrorInfo()) in this parameter.
//    Message text to display in the monitor is compiled from system user messages that are 
//    generated but are not displayed to a user yet. Therefore, we recommend you to delete cached 
//    messages before calling this method.
//
// Example:
// Procedure WriteObjectOnImport(Object, ExchangeNode)
// Object.DataExchange.Import = True;
// Object.Write();
// Object.DataExchange.Import = False;
// Cancel = False;
//
// Try
// 	Object.Write();
// Except
// 	ErrorMessage = BriefErrorPresentation(ErrorInformation());
// 	Cancel = True;
// EndTry;
//
// If Cancel Then
// 	DataExchangeServer.RecordObjectWriteError(Object, ExchangeNode, ErrorMessage);
// EndIf;
//
// EndProcedure;
//
Procedure RecordObjectWriteError(Object, ExchangeNode, ExceptionText) Export
	
	UserMessages = GetUserMessages(True);
	MessageText = ExceptionText;
	For Each Message In UserMessages Do
		If StrFind(Message.Text, TimeConsumingOperations.ProgressMessage()) > 0 Then
			Continue;
		EndIf;
		MessageText = MessageText + ?(IsBlankString(MessageText), "", Chars.LF) + Message.Text;
	EndDo;
	
	ErrorReason = MessageText;
	If Not IsBlankString(TrimAll(MessageText)) Then
		
		ErrorReason = " " + NStr("ru = 'По причине %1.'; en = 'Reason: %1.'; pl = 'Z powodu %1.';de = 'Aus dem Grund %1.';ro = 'Din motivul %1.';tr = '%1 nedeniyle.'; es_ES = 'A causa de %1.'");
		ErrorReason = StringFunctionsClientServer.SubstituteParametersToString(ErrorReason, MessageText);
		
	EndIf;
	
	MessageString = NStr("ru = 'Не удалось записать объект %1, полученный из другой информационной базы.%2
		|Возможно не заполнены все реквизиты, обязательные к заполнению.'; 
		|en = 'Cannot write object %1 received from another infobase. %2
		|Probably some of the required attributes are blank.'; 
		|pl = 'Nie udało się zapisać obiekt %1, otrzymany z innej bazy informacyjnej.%2
		|Możliwie, że nie są wypełnione wszystkie atrybuty, obowiązkowe do wypełnienia.';
		|de = 'Objekt %1aus einer anderen Infobase konnte nicht geschrieben werden.%2
		|Wahrscheinlich sind nicht alle Details ausgefüllt, die ausgefüllt werden müssen.';
		|ro = 'Eșec la înregistrarea obiectului %1 primit din altă bază de informații.%2
		|Posibil, nu sunt completate toate atributele obligatorii pentru completare.';
		|tr = 'Başka bir veritabanından %1 alınan nesne yazılamadı. %2
		|Tüm gerekli özellikler doldurulmamış olabilir.'; 
		|es_ES = 'No se ha podido guardar el objeto %1 recibido de otra base de información.%2
		|Es posible que no todos los requisitos estén rellenados que son obligatorios para rellenar.'",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(Object), ErrorReason);
	
	WriteLogEvent(EventLogMessageTextDataExchange(), EventLogLevel.Warning,,, MessageString);
	
	InformationRegisters.DataExchangeResults.RecordDocumentCheckError(Object.Ref, ExchangeNode,
		MessageText, Enums.DataExchangeIssuesTypes.BlankAttributes);
	
EndProcedure

#EndRegion

#Region ProgressBar

// Calculating the number of infobase objects to be exported upon initial image creation.
//
// Parameters:
//   Recipient - an exchange plan object.
//
// Returns a number.
Function CalculateObjectsCountInInfobase(Recipient)
	
	ExchangePlanName = Recipient.Metadata().Name;
	ObjectCounter = 0;
	ExchangePlanComposition = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	// 1. Reference objects.
	RefObjectsStructure = New Structure;
	RefObjectsStructure.Insert("Catalog", Metadata.Catalogs);
	RefObjectsStructure.Insert("Document", Metadata.Documents);
	RefObjectsStructure.Insert("ChartOfCharacteristicTypes", Metadata.ChartsOfCharacteristicTypes);
	RefObjectsStructure.Insert("ChartOfCalculationTypes", Metadata.ChartsOfCalculationTypes);
	RefObjectsStructure.Insert("ChartOfAccounts", Metadata.ChartsOfAccounts);
	RefObjectsStructure.Insert("BusinessProcess", Metadata.BusinessProcesses);
	RefObjectsStructure.Insert("Task", Metadata.Tasks);
	RefObjectsStructure.Insert("ChartOfAccounts", Metadata.ChartsOfAccounts);

	QueryText = "SELECT 
	|Count(Ref) AS ObjectCount
	|FROM ";
	For Each RefObject In RefObjectsStructure Do
		For Each MetadataObject In RefObject.Value Do
			If ExchangePlanComposition.Find(MetadataObject) = Undefined Then
				Continue;
			EndIf;
			FullObjectName = RefObject.Key +"."+MetadataObject.Name;
			Query = New Query;
			Query.Text = QueryText + FullObjectName;
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ObjectCounter = ObjectCounter + Selection.ObjectCount;
			EndIf;
		EndDo;
	EndDo;
	
	// 2. Constants
	For Each MetadataObject In Metadata.Constants Do
		If ExchangePlanComposition.Find(MetadataObject) = Undefined Then
			Continue;
		EndIf;
		ObjectCounter = ObjectCounter + 1;
	EndDo;

	// 3. Information registers.
	QueryText = "SELECT 
	|Count(*) AS ObjectCount
	|FROM ";
	QueryTextWithRecorder = "SELECT 
	|Count(DISTINCT Recorder) AS ObjectCount
	|FROM ";
	For Each MetadataObject In Metadata.InformationRegisters Do
		If ExchangePlanComposition.Find(MetadataObject) = Undefined Then
			Continue;
		EndIf;
		FullObjectName = "InformationRegister."+MetadataObject.Name;
		Query = New Query;
		If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			Query.Text = QueryTextWithRecorder + FullObjectName;
		Else
			Query.Text = QueryText + FullObjectName;
		EndIf;
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			ObjectCounter = ObjectCounter + Selection.ObjectCount;
		EndIf;
	EndDo;
	
	// 4. Registers (subordinate to a recorder) and sequences.
	RegistersStructure = New Structure;
	RegistersStructure.Insert("AccumulationRegister", Metadata.AccumulationRegisters);
	RegistersStructure.Insert("CalculationRegister", Metadata.CalculationRegisters);
	RegistersStructure.Insert("AccountingRegister", Metadata.AccountingRegisters);
	RegistersStructure.Insert("Sequence", Metadata.Sequences);

	QueryText = QueryTextWithRecorder;
	For Each Register In RegistersStructure Do
		For Each MetadataObject In Register.Value Do
			If ExchangePlanComposition.Find(MetadataObject) = Undefined Then
				Continue;
			EndIf;
			FullObjectName = Register.Key +"."+MetadataObject.Name;
			Query = New Query;
			Query.Text = QueryText + FullObjectName;
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ObjectCounter = ObjectCounter + Selection.ObjectCount;
			EndIf;
		EndDo;
	EndDo;

	Return ObjectCounter;
	
EndFunction

// Calculating a number of objects registered in the exchange plan.
//
// Parameters:
//   Recipient - an exchange plan object.
//
// Returns a number.
Function CalculateRegisteredObjectsCount(Recipient) Export
	
	ChangesSelection = ExchangePlans.SelectChanges(Recipient.Ref, Recipient.SentNo + 1);
	ObjectsToExportCount = 0;
	While ChangesSelection.Next() Do
		ObjectsToExportCount = ObjectsToExportCount + 1;
	EndDo;
	Return ObjectsToExportCount;
	
EndFunction

#EndRegion

#Region Common

Function AdditionalExchangePlanPropertiesAsString(Val PropertiesAsString)
	
	Result = "";
	
	Template = "ExchangePlans.[PropertyAsString] AS [PropertyAsString]";
	
	ArrayProperties = StrSplit(PropertiesAsString, ",", False);
	
	For Each PropertyAsString In ArrayProperties Do
		
		PropertyAsStringInQuery = StrReplace(Template, "[PropertyAsString]", PropertyAsString);
		
		Result = Result + PropertyAsStringInQuery + ", ";
		
	EndDo;
	
	Return Result;
EndFunction

Function ExchangePlansFilterByDataSeparationFlag(ExchangePlansArray)
	
	Result = New Array;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SeparatedDataUsageAvailable() Then
			
			For Each ExchangePlanName In ExchangePlansArray Do
				
				If Common.SubsystemExists("StandardSubsystems.SaaS") Then
					ModuleSaaS = Common.CommonModule("SaaS");
					IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName);
				Else
					IsSeparatedMetadataObject = False;
				EndIf;
				
				If IsSeparatedMetadataObject Then
					
					Result.Add(ExchangePlanName);
					
				EndIf;
				
			EndDo;
			
		Else
			
			For Each ExchangePlanName In ExchangePlansArray Do
				
				If Common.SubsystemExists("StandardSubsystems.SaaS") Then
					ModuleSaaS = Common.CommonModule("SaaS");
					IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName);
				Else
					IsSeparatedMetadataObject = False;
				EndIf;
				
				If Not IsSeparatedMetadataObject Then
					
					Result.Add(ExchangePlanName);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		
		For Each ExchangePlanName In ExchangePlansArray Do
			
			Result.Add(ExchangePlanName);
			
		EndDo;
		
	EndIf;
	
	Return Result;
EndFunction

Function ExchangePlansFilterByStandaloneModeFlag(ExchangePlansArray)
	
	Result = New Array;
	
	For Each ExchangePlanName In ExchangePlansArray Do
		
		If ExchangePlanName <> DataExchangeCached.StandaloneModeExchangePlan() Then
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// Deletes obsolete records from the information register.
// The record is obsolete if the exchange plan that includes the record was renamed or deleted.
// 
//
// Parameters:
//  No.
// 
Procedure DeleteObsoleteRecordsFromDataExchangeRulesRegister()
	
	Query = New Query(
	"SELECT DISTINCT
	|	DataExchangeRules.ExchangePlanName AS ExchangePlanName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	NOT DataExchangeRules.ExchangePlanName IN (&SSLExchangePlans)");
	Query.SetParameter("SSLExchangePlans", DataExchangeCached.SSLExchangePlans());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
			
		RecordSet = CreateInformationRegisterRecordSet(New Structure("ExchangePlanName", Selection.ExchangePlanName),
			"DataExchangeRules");
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure GetExchangePlansForMonitor(TempTablesManager, ExchangePlansArray, Val ExchangePlanAdditionalProperties)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	// The logic for the query generation is in a separate function.
	QueryParameters = ExchangePlansForMonitorQueryParameters();
	QueryParameters.ExchangePlansArray                 = ExchangePlansArray;
	QueryParameters.ExchangePlanAdditionalProperties = ExchangePlanAdditionalProperties;
	QueryParameters.ResultToTemporaryTable       = True;
	Query.Text = ExchangePlansForMonitorQueryText(QueryParameters);
	Query.Execute();
	
EndProcedure

// Function for declaring the parameter structure of the ExchangePlansForMonitorQueryText function.
//
// Parameters:
//   No.
//
// Returns:
//   Structure.
//
Function ExchangePlansForMonitorQueryParameters()
	
	QueryParameters = New Structure;
	QueryParameters.Insert("ExchangePlansArray",                 New Array);
	QueryParameters.Insert("ExchangePlanAdditionalProperties", "");
	QueryParameters.Insert("ResultToTemporaryTable",       False);
	
	Return QueryParameters;
	
EndFunction

// Returns a query text to get data of exchange plan nodes.
//
// Parameters:
//   QueryOptions - Structure - a parameter structure (see the ExchangePlansForMonitorQueryParameters function):
//     * ExchangePlansArray - Array - names of SSL exchange plans. All SSL exchange plans by default.
//     * ExchangePlanAdditionalProperties - String - properties of nodes with values being received.
//                                                    default value: empty string.
//     * ResultToTemporaryTable       - Boolean - if True, the query describes storing the result to 
//                                                    the ConfigurationExchangePlans temporary table.
//                                                    Default value is False.
//   ExcludeStandaloneModeExchangePlans - Boolean - if True, standalone mode exchange plans are 
//                                                    excluded from a query text.
//
// Returns:
//   String - a query resulting text.
//
Function ExchangePlansForMonitorQueryText(QueryParameters = Undefined, ExcludeStandaloneModeExchangePlans = True) Export
	
	If QueryParameters = Undefined Then
		QueryParameters = ExchangePlansForMonitorQueryParameters();
	EndIf;
	
	ExchangePlansArray                 = QueryParameters.ExchangePlansArray;
	ExchangePlanAdditionalProperties = QueryParameters.ExchangePlanAdditionalProperties;
	ResultToTemporaryTable       = QueryParameters.ResultToTemporaryTable;
	
	If Not ValueIsFilled(ExchangePlansArray) Then
		ExchangePlansArray = DataExchangeCached.SSLExchangePlans();
	EndIf;
	
	MethodExchangePlans = ExchangePlansFilterByDataSeparationFlag(ExchangePlansArray);
	
	If DataExchangeCached.StandaloneModeSupported()
		AND ExcludeStandaloneModeExchangePlans Then
		
		// Using separate monitor for the exchange plan of the standalone mode.
		MethodExchangePlans = ExchangePlansFilterByStandaloneModeFlag(MethodExchangePlans);
		
	EndIf;
	
	AdditionalExchangePlanPropertiesAsString = ?(IsBlankString(ExchangePlanAdditionalProperties), "", ExchangePlanAdditionalProperties + ", ");
	
	QueryTemplate = "
	|
	|UNION ALL
	|
	|//////////////////////////////////////////////////////// {[ExchangePlanName]}
	|SELECT
	|
	|	[ExchangePlanAdditionalProperties]
	|
	|	Ref                      AS InfobaseNode,
	|	Description                AS Description,
	|	""[ExchangePlanNameSynonym]"" AS ExchangePlanName
	|FROM
	|	ExchangePlan.[ExchangePlanName]
	|WHERE
	|	     NOT ThisNode
	|	AND NOT DeletionMark
	|";
	
	QueryText = "";
	
	If MethodExchangePlans.Count() > 0 Then
		
		For Each ExchangePlanName In MethodExchangePlans Do
			
			ExchangePlanQueryText = StrReplace(QueryTemplate,              "[ExchangePlanName]",        ExchangePlanName);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "[ExchangePlanNameSynonym]", Metadata.ExchangePlans[ExchangePlanName].Synonym);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "[ExchangePlanAdditionalProperties]", AdditionalExchangePlanPropertiesAsString);
			
			// Deleting the literal that is used to perform table union for the first table.
			If IsBlankString(QueryText) Then
				
				ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "UNION ALL", "");
				
			EndIf;
			
			QueryText = QueryText + ExchangePlanQueryText;
			
		EndDo;
		
	Else
		
		AdditionalPropertiesWithoutDataSourceAsString = "";
		
		If Not IsBlankString(ExchangePlanAdditionalProperties) Then
			
			AdditionalProperties = StrSplit(ExchangePlanAdditionalProperties, ",");
			
			AdditionalPropertiesWithoutDataSource = New Array;
			
			For Each Property In AdditionalProperties Do
				
				AdditionalPropertiesWithoutDataSource.Add(StrReplace("Undefined AS [Property]", "[Property]", Property));
				
			EndDo;
			
			AdditionalPropertiesWithoutDataSourceAsString = StrConcat(AdditionalPropertiesWithoutDataSource, ",") + ", ";
			
		EndIf;
		
		QueryText = "
		|SELECT
		|
		|	[AdditionalPropertiesWithoutDataSourceAsString]
		|
		|	Undefined AS InfobaseNode,
		|	Undefined AS Description,
		|	Undefined AS ExchangePlanName
		|";
		
		QueryText = StrReplace(QueryText, "[AdditionalPropertiesWithoutDataSourceAsString]", AdditionalPropertiesWithoutDataSourceAsString);
		
	EndIf;
	
	QueryTextResult = "
	|//////////////////////////////////////////////////////// {ConfigurationExchangePlans}
	|SELECT
	|
	|	[ExchangePlanAdditionalProperties]
	|
	|	InfobaseNode,
	|	Description,
	|	ExchangePlanName
	| [PutInTemporaryTable]
	|FROM
	|	(
	|	[QueryText]
	|	) AS NestedQuery
	|;
	|";
	
	
	QueryTextResult = StrReplace(QueryTextResult, "[PutInTemporaryTable]",
		?(ResultToTemporaryTable, "INTO ConfigurationExchangePlans", ""));
	QueryTextResult = StrReplace(QueryTextResult, "[QueryText]", QueryText);
	QueryTextResult = StrReplace(QueryTextResult, "[ExchangePlanAdditionalProperties]", AdditionalExchangePlanPropertiesAsString);
	
	Return QueryTextResult;
	
EndFunction

Procedure GetDataExchangesStates(TempTablesManager)
	
	Query = New Query;
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		QueryTextResult =
		"SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.EndDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
		|				OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesImport
		|FROM
		|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.EndDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesExport
		|FROM
		|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesImport
		|FROM
		|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesExport
		|FROM
		|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)";
	Else
		QueryTextResult =
		"SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.EndDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
		|				OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesImport
		|FROM
		|	InformationRegister.DataExchangesStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.EndDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesExport
		|FROM
		|	InformationRegister.DataExchangesStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesImport
		|FROM
		|	InformationRegister.SuccessfulDataExchangesStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesExport
		|FROM
		|	InformationRegister.SuccessfulDataExchangesStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)";
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetExchangeResultsForMonitor(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		QueryTextResult = 
		"SELECT
		|	DataExchangeResults.InfobaseNode AS InfobaseNode,
		|	CASE
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.UnpostedDocument), VALUE(Enum.DataExchangeIssuesTypes.BlankAttributes), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData))
		|			THEN VALUE(Enum.ActionsOnExchange.DataImport)
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData), VALUE(Enum.DataExchangeIssuesTypes.ConvertedObjectValidationError))
		|			THEN VALUE(Enum.ActionsOnExchange.DataExport)
		|		ELSE UNDEFINED
		|	END AS ActionOnExchange,
		|	COUNT(DISTINCT DataExchangeResults.ObjectWithIssue) AS Count
		|INTO IssuesCount
		|FROM
		|	InformationRegister.DataExchangeResults AS DataExchangeResults
		|WHERE
		|	DataExchangeResults.Skipped = FALSE
		|
		|GROUP BY
		|	DataExchangeResults.InfobaseNode,
		|	CASE
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.UnpostedDocument), VALUE(Enum.DataExchangeIssuesTypes.BlankAttributes), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData))
		|			THEN VALUE(Enum.ActionsOnExchange.DataImport)
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData), VALUE(Enum.DataExchangeIssuesTypes.ConvertedObjectValidationError))
		|			THEN VALUE(Enum.ActionsOnExchange.DataExport)
		|		ELSE UNDEFINED
		|	END";
		
	Else
		
		QueryTextResult = 
		"SELECT
		|	UNDEFINED AS InfobaseNode,
		|	UNDEFINED AS ActionOnExchange,
		|	UNDEFINED AS Count
		|INTO IssuesCount";
		
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetMessagesToMapData(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If Common.DataSeparationEnabled() Then
			QueryTextResult =
			"SELECT
			|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
			|	CASE
			|		WHEN COUNT(CommonInfobasesNodesSettings.MessageForDataMapping) > 0
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS EmailReceivedForDataMapping,
			|	MAX(DataExchangeMessages.MessageStoredDate) AS LastMessageStoragePlacementDate
			|INTO MessagesForDataMapping
			|FROM
			|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
			|		INNER JOIN InformationRegister.DataAreaDataExchangeMessages AS DataExchangeMessages
			|		ON (DataExchangeMessages.MessageID = CommonInfobasesNodesSettings.MessageForDataMapping)
			|
			|GROUP BY
			|	CommonInfobasesNodesSettings.InfobaseNode";
		Else
			QueryTextResult =
			"SELECT
			|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
			|	CASE
			|		WHEN COUNT(CommonInfobasesNodesSettings.MessageForDataMapping) > 0
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS EmailReceivedForDataMapping,
			|	MAX(DataExchangeMessages.MessageStoredDate) AS LastMessageStoragePlacementDate
			|INTO MessagesForDataMapping
			|FROM
			|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
			|		INNER JOIN InformationRegister.DataExchangeMessages AS DataExchangeMessages
			|		ON (DataExchangeMessages.MessageID = CommonInfobasesNodesSettings.MessageForDataMapping)
			|
			|GROUP BY
			|	CommonInfobasesNodesSettings.InfobaseNode";
		EndIf;
		
	Else
		
		QueryTextResult =
		"SELECT
		|	NULL AS InfobaseNode,
		|	NULL AS EmailReceivedForDataMapping,
		|	NULL AS LastMessageStoragePlacementDate
		|INTO MessagesForDataMapping";
		
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetCommonInfobasesNodesSettings(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		QueryTextResult =
		"SELECT
		|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentVersion, """") AS CorrespondentVersion,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentPrefix, """") AS CorrespondentPrefix,
		|	ISNULL(CommonInfobasesNodesSettings.SetupCompleted, FALSE) AS SetupCompleted
		|INTO CommonInfobasesNodesSettings
		|FROM
		|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings";
		
	Else
		
		QueryTextResult =
		"SELECT
		|	NULL AS InfobaseNode,
		|	"""" AS CorrespondentVersion,
		|	"""" AS CorrespondentPrefix,
		|	FALSE AS SetupCompleted
		|INTO CommonInfobasesNodesSettings";
		
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Function ExchangePlansWithRulesFromFile()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataExchangeRules.ExchangePlanName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.RulesSource = &RulesSource";
	
	Query.SetParameter("RulesSource", Enums.DataExchangeRulesSources.File);
	Result = Query.Execute().Unload();
	
	Return Result.Count();
	
EndFunction

Procedure CheckExchangeManagementRights() Export
	
	If Not HasRightsToAdministerExchanges() Then
		
		Raise NStr("ru = 'Недостаточно прав для администрирования синхронизации данных.'; en = 'Insufficient rights to administer data synchronization.'; pl = 'Niewystarczające uprawnienia do administrowania synchronizacją danych.';de = 'Unzureichende Rechte zum Verwalten der Datensynchronisierung.';ro = 'Drepturi insuficiente pentru administrarea sincronizării datelor.';tr = 'Veri senkronizasyonunu yönetmek için yetersiz haklar.'; es_ES = 'Insuficientes derecho para administrar la sincronización de datos.'");
		
	EndIf;
	
EndProcedure

Procedure CheckExternalConnectionAvailable()
	
	If Common.IsLinuxServer() Then
		
		Raise NStr("ru = 'Синхронизация данных через прямое подключение на сервере под управлением ОС Linux недоступно.
			|Для синхронизации данных через прямое подключение требуется использовать ОС Windows.'; 
			|en = 'Data synchronization over a direct server connection is not available on Linux.
			|Use Microsoft Windows to synchronize data over a direct connection.'; 
			|pl = 'Synchronizacja danych przez bezpośrednie połączenie na serwerze zarządzanym przez system operacyjny Linux nie jest dostępna.
			|Musisz użyć systemu operacyjnego Windows do synchronizacji danych przez połączenie bezpośrednie.';
			|de = 'Die Datensynchronisierung über die direkte Verbindung auf einem Server, der von einem Linux-Betriebssystem verwaltet wird, ist nicht verfügbar. 
			|Sie müssen ein Windows-Betriebssystem für die Datensynchronisierung über die direkte Verbindung verwenden.';
			|ro = 'Sincronizarea datelor prin conexiunea directă pe serverul gestionat de sistemul de operare Linux nu este disponibilă.
			|Trebuie să utilizați sistemul de operare Windows pentru sincronizarea datelor prin conexiune directă.';
			|tr = 'Linux OS tarafından yönetilen sunucudaki doğrudan bağlantı üzerinden veri senkronizasyonu mevcut değildir. 
			|Doğrudan bağlantı yoluyla veri senkronizasyonu için Windows işletim sistemini kullanmanız gerekir.'; 
			|es_ES = 'Sincronización de datos a través de la conexión directa en el servidor gestionado por OS Linux no está disponible.
			|Usted tiene que utilizar OS Windows para sincronizar los datos a través de la conexión directa.'");
			
	EndIf;
	
EndProcedure

// Returns the flag that shows whether a user has rights to perform the data synchronization.
// A user can perform data synchronization if it has either full access or rights of the "Data 
// synchronization with other applications" supplied profile.
//
//  Parameters:
// User (optional) - InfoBaseUser, Undefined.
// This user is used to define whether the data synchronization is available.
// If this parameter is not set, the current infobase user is used to calculate the function result.
//
Function DataSynchronizationPermitted(Val User = Undefined) Export
	
	If User = Undefined Then
		User = InfoBaseUsers.CurrentUser();
	EndIf;
	
	If User.Roles.Contains(Metadata.Roles.FullRights) Then
		Return True;
	EndIf;
	
	ProfileRoles = StrSplit(DataSynchronizationAccessProfileWithOtherApplicationsRoles(), ",");
	For Each Role In ProfileRoles Do
		
		If Not User.Roles.Contains(Metadata.Roles.Find(TrimAll(Role))) Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
EndFunction

// Fills in a value list with available transport types for the exchange plan node.
//
Procedure FillChoiceListWithAvailableTransportTypes(InfobaseNode, FormItem, Filter = Undefined) Export
	
	FilterSet = (Filter <> Undefined);
	
	UsedTransports = DataExchangeCached.UsedExchangeMessagesTransports(InfobaseNode);
	
	FormItem.ChoiceList.Clear();
	
	For Each Item In UsedTransports Do
		
		If FilterSet Then
			
			If Filter.Find(Item) <> Undefined Then
				
				FormItem.ChoiceList.Add(Item, String(Item));
				
			EndIf;
			
		Else
			
			FormItem.ChoiceList.Add(Item, String(Item));
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Registeres that the exchange was carried out and records information in the protocol.
//
// Parameters:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
// 
Procedure AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure) Export
	
	// The Undefined state in the end of the exchange indicates that the exchange has been performed successfully.
	If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed;
	EndIf;
	
	// Generating the final message to be written.
	If ExchangeSettingsStructure.IsDIBExchange Then
		MessageString = NStr("ru = '%1, %2'; en = '%1, %2'; pl = '%1, %2';de = '%1, %2';ro = '%1, %2';tr = '%1, %2'; es_ES = '%1, %2'", Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
							ExchangeSettingsStructure.ExchangeExecutionResult,
							ExchangeSettingsStructure.ActionOnExchange);
	Else
		MessageString = NStr("ru = '%1, %2; Объектов обработано: %3'; en = '%1, %2, objects processed: %3'; pl = '%1, %2; Przetworzone obiekty: %3';de = '%1, %2; Verarbeitete Objekte: %3';ro = '%1, %2; Obiecte procesate: %3';tr = '%1, %2;İşlenmiş nesneler:%3'; es_ES = '%1, %2; Objetos procesados: %3'", Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
							ExchangeSettingsStructure.ExchangeExecutionResult,
							ExchangeSettingsStructure.ActionOnExchange,
							ExchangeSettingsStructure.ProcessedObjectsCount);
	EndIf;
	
	ExchangeSettingsStructure.EndDate = CurrentSessionDate();
	
	SetPrivilegedMode(True);
	
	// Writing the exchange state to the information register.
	AddExchangeFinishMessageToInformationRegister(ExchangeSettingsStructure);
	
	// The data exchange has been completed successfully.
	If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		AddSuccessfulDataExchangeMessageToInformationRegister(ExchangeSettingsStructure);
		
		InformationRegisters.CommonInfobasesNodesSettings.ClearDataSendingFlag(ExchangeSettingsStructure.InfobaseNode);
		
	EndIf;
	
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
EndProcedure

// Records the data exchange state in the DataExchangesStates information register.
//
// Parameters:
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute exchange.
// 
Procedure AddExchangeFinishMessageToInformationRegister(ExchangeSettingsStructure)
	
	// Generating a structure for the new information register record.
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode",    ExchangeSettingsStructure.InfobaseNode);
	RecordStructure.Insert("ActionOnExchange",         ExchangeSettingsStructure.ActionOnExchange);
	
	RecordStructure.Insert("ExchangeExecutionResult", ExchangeSettingsStructure.ExchangeExecutionResult);
	RecordStructure.Insert("StartDate",                ExchangeSettingsStructure.StartDate);
	RecordStructure.Insert("EndDate",             ExchangeSettingsStructure.EndDate);
	
	InformationRegisters.DataExchangesStates.AddRecord(RecordStructure);
	
EndProcedure

Procedure AddSuccessfulDataExchangeMessageToInformationRegister(ExchangeSettingsStructure)
	
	// Generating a structure for the new information register record.
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", ExchangeSettingsStructure.InfobaseNode);
	RecordStructure.Insert("ActionOnExchange",      ExchangeSettingsStructure.ActionOnExchange);
	RecordStructure.Insert("EndDate",          ExchangeSettingsStructure.EndDate);
	
	InformationRegisters.SuccessfulDataExchangesStates.AddRecord(RecordStructure);
	
EndProcedure

Procedure WriteLogEventDataExchangeStart(ExchangeSettingsStructure) Export
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła %1';de = 'Datenaustausch beginnt für Knoten %1';ro = 'Începutul procesului schimbului de date pentru nodul %1';tr = '%1Ünite için veri değişimi süreci başlatılıyor'; es_ES = 'Inicio de proceso de intercambio de datos para el nodo %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
EndProcedure

// Creates a record in the event log about a data exchange event or an exchange message transport.
//
Procedure WriteEventLogDataExchange(Comment, ExchangeSettingsStructure, IsError = False)
	
	Level = ?(IsError, EventLogLevel.Error, EventLogLevel.Information);
	
	If ExchangeSettingsStructure.Property("InfobaseNode") Then
		
		WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, 
			Level,
			ExchangeSettingsStructure.InfobaseNode.Metadata(),
			ExchangeSettingsStructure.InfobaseNode,
			Comment);
			
	Else
		WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, Level,,, Comment);
	EndIf;
	
EndProcedure

Procedure WriteDataReceiveEvent(Val InfobaseNode, Val Comment, Val IsError = False)
	
	Level = ?(IsError, EventLogLevel.Error, EventLogLevel.Information);
	
	EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	
	WriteLogEvent(EventLogMessageKey, Level,,, Comment);
	
EndProcedure

Procedure NodeSettingsFormOnCreateAtServerHandler(Form, FormAttributeName)
	
	FormAttributes = FormAttributeNames(Form);
	
	For Each FilterSetting In Form[FormAttributeName] Do
		
		varKey = FilterSetting.Key;
		
		If FormAttributes.Find(varKey) = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(Form[varKey]) = Type("FormDataCollection") Then
			
			Table = New ValueTable;
			
			TabularSectionStructure = Form.Parameters[FormAttributeName][varKey];
			
			For Each Item In TabularSectionStructure Do
				
				While Table.Count() < Item.Value.Count() Do
					Table.Add();
				EndDo;
				
				Table.Columns.Add(Item.Key);
				
				Table.LoadColumn(Item.Value, Item.Key);
				
			EndDo;
			
			Form[varKey].Load(Table);
			
		Else
			
			Form[varKey] = Form.Parameters[FormAttributeName][varKey];
			
		EndIf;
		
		Form[FormAttributeName][varKey] = Form.Parameters[FormAttributeName][varKey];
		
	EndDo;
	
EndProcedure

Function FormAttributeNames(Form)
	
	// Function return value.
	Result = New Array;
	
	For Each FormAttribute In Form.GetAttributes() Do
		
		Result.Add(FormAttribute.Name);
		
	EndDo;
	
	Return Result;
EndFunction

// Unpacks the ZIP archive file to the specified directory and extracts all archive files.
//
// Parameters:
//  FullArchiveFileName  - String - an archive file name being extracted.
//  FileUnpackPath  - String - a path by which the files are extracted.
//  ArchivePassword          - String - a password for unpacking the archive. Default value: empty string.
// 
// Returns:
//  Result - Boolean - True if it is successful. Otherwise, False.
//
Function UnpackZipFile(Val ArchiveFileFullName, Val FileUnpackPath, Val ArchivePassword = "") Export
	
	// Function return value.
	Result = True;
	
	Try
		
		Archiver = New ZipFileReader(ArchiveFileFullName, ArchivePassword);
		
	Except
		Archiver = Undefined;
		ReportError(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Try
		
		Archiver.ExtractAll(FileUnpackPath, ZIPRestoreFilePathsMode.DontRestore);
		
	Except
		
		MessageString = NStr("ru = 'Ошибка при распаковке файлов архива: %1 в каталог: %2'; en = 'Cannot unpack archive %1 to directory %2.'; pl = 'Podczas rozpakowywania plików archiwum %1 do katalogu: %2 wystąpił błąd';de = 'Beim Entpacken der Archivdateien %1 in das Verzeichnis ist ein Fehler aufgetreten: %2';ro = 'Eroare la decomprimarea fișierelor arhivei %1 în directorul: %2';tr = 'Arşiv dosyalarını %1 açarken bir hata oluştu:%2'; es_ES = 'Ha ocurrido un error al desembalar los documentos del archivo %1 para el directorio: %2'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ArchiveFileFullName, FileUnpackPath);
		Common.MessageToUser(MessageString);
		
		Result = False;
	EndTry;
	
	Archiver.Close();
	Archiver = Undefined;
	
	Return Result;
	
EndFunction

// Packs the specified directory into a ZIP file.
//
// Parameters:
//  FullArchiveFileName  - String - a name of an archive file being packed.
//  FilePackingMask    - String - a name of a file to archive or mask.
//			It is prohibited that you name files and directories using characters that can be converted to 
//			UNICODE characters and back incorrectly.
//			It is recommended that you use only roman characters to name files and folders.
//  ArchivePassword          - String - a password for the archive. Default value: empty string.
// 
// Returns:
//  Result - Boolean - True if it is successful. Otherwise, False.
//
Function PackIntoZipFile(Val ArchiveFileFullName, Val FilesPackingMask, Val ArchivePassword = "") Export
	
	// Function return value.
	Result = True;
	
	Try
		
		Archiver = New ZipFileWriter(ArchiveFileFullName, ArchivePassword);
		
	Except
		Archiver = Undefined;
		ReportError(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Try
		
		Archiver.Add(FilesPackingMask, ZIPStorePathMode.DontStorePath);
		Archiver.Write();
		
	Except
		
		MessageString = NStr("ru = 'Ошибка при запаковке файлов архива: %1 из каталог: %2'; en = 'Cannot archive files from directory %2 to file %1.'; pl = 'Podczas pakowania plików archiwum: %1 z katalogu: %2 wystąpił błąd';de = 'Beim Packen von Archivdateien ist ein Fehler aufgetreten: %1 aus dem Verzeichnis: %2';ro = 'Eroare la comprimarea fișierelor arhivei: %1 din directorul: %2';tr = 'Arşiv dosyalarını %1 dizinden paketlerken bir hata oluştu: %2'; es_ES = 'Ha ocurrido un error al desembalar los documentos del archivo %1 desde el directorio: %2'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ArchiveFileFullName, FilesPackingMask);
		Common.MessageToUser(MessageString);
		
		Result = False;
	EndTry;
	
	Archiver = Undefined;
	
	Return Result;
	
EndFunction

// Returns the number of records in the infobase table.
//
// Parameters:
//  TableName - String - a full name of the infobase table. For example: Catalog.Counterparties.Orders.
// 
// Returns:
//  Number - a number of records in the infobase table.
//
Function RecordCountInInfobaseTable(Val TableName) Export
	
	QueryText = "
	|SELECT
	|	Count(*) AS Count
	|FROM
	|	#TableName
	|";
	
	QueryText = StrReplace(QueryText, "#TableName", TableName);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection["Count"];
	
EndFunction

// Returns the number of records in the temporary infobase table.
//
// Parameters:
//  TableName - String - a name of the table. For example: "TemporaryTable1".
//  TempTablesManager - a temporary table manager containing a reference to the TableName temporary table.
// 
// Returns:
//  Number - a number of records in the infobase table.
//
Function TempInfobaseTableRecordCount(Val TableName, TempTablesManager) Export
	
	QueryText = "
	|SELECT
	|	Count(*) AS Count
	|FROM
	|	#TableName
	|";
	
	QueryText = StrReplace(QueryText, "#TableName", TableName);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection["Count"];
	
EndFunction

// Returns the event log message key.
//
Function EventLogMessageKey(InfobaseNode, ActionOnExchange) Export
	
	ExchangePlanName     = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	MessageKey = NStr("ru = 'Обмен данными.[ExchangePlanName].[ActionOnExchange]'; en = 'Data exchange.[ExchangePlanName].[ActionOnExchange]'; pl = 'Wymiana danych.[ExchangePlanName].[ActionOnExchange]';de = 'Datenaustausch.[ExchangePlanName].[ActionOnExchange]';ro = 'Schimb de date.[ExchangePlanName].[ActionOnExchange]';tr = 'Veri alışverişi. [ExchangePlanName].[ActionOnExchange]'; es_ES = 'Intercambio de datos.[ExchangePlanName].[ActionOnExchange]'",
		Common.DefaultLanguageCode());
	
	MessageKey = StrReplace(MessageKey, "[ExchangePlanName]",    ExchangePlanName);
	MessageKey = StrReplace(MessageKey, "[ActionOnExchange]", ActionOnExchange);
	
	Return MessageKey;
	
EndFunction

// Returns a flag indicating whether the attribute is a standard attribute.
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		
		If Attribute.Name = AttributeName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Returns the flag of successful data exchange completion.
//
Function ExchangeExecutionResultCompleted(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Undefined
		OR ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed
		OR ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings;
	
EndFunction

// Generating the data table key.
// The table key is used for importing data selectively from the exchange message.
//
Function DataTableKey(Val SourceType, Val DestinationType, Val IsObjectDeletion) Export
	
	Return SourceType + "#" + DestinationType + "#" + String(IsObjectDeletion);
	
EndFunction

Function MustExecuteHandler(Object, Ref, PropertyName)
	
	NumberAfterProcessing = Object[PropertyName];
	
	NumberBeforeProcessing = Common.ObjectAttributeValue(Ref, PropertyName);
	
	NumberBeforeProcessing = ?(NumberBeforeProcessing = Undefined, 0, NumberBeforeProcessing);
	
	Return NumberBeforeProcessing <> NumberAfterProcessing;
	
EndFunction

Function FillExternalConnectionParameters(TransportSettings)
	
	ConnectionParameters = CommonClientServer.ParametersStructureForExternalConnection();
	
	ConnectionParameters.InfobaseOperatingMode             = TransportSettings.COMInfobaseOperatingMode;
	ConnectionParameters.InfobaseDirectory                   = TransportSettings.COMInfobaseDirectory;
	ConnectionParameters.NameOf1CEnterpriseServer                     = TransportSettings.COM1CEnterpriseServerName;
	ConnectionParameters.NameOfInfobaseOn1CEnterpriseServer = TransportSettings.COM1CEnterpriseServerSideInfobaseName;
	ConnectionParameters.OperatingSystemAuthentication           = TransportSettings.COMOperatingSystemAuthentication;
	ConnectionParameters.UserName                             = TransportSettings.COMUsername;
	ConnectionParameters.UserPassword = TransportSettings.COMUserPassword;
	
	Return ConnectionParameters;
EndFunction

Function AddLiteralToFileName(Val FullFileName, Val Literal)
	
	If IsBlankString(FullFileName) Then
		Return "";
	EndIf;
	
	FileNameWithoutExtension = Mid(FullFileName, 1, StrLen(FullFileName) - 4);
	
	Extension = Right(FullFileName, 3);
	
	Result = "[FileNameWithoutExtension]_[Literal].[Extension]";
	
	Result = StrReplace(Result, "[FileNameWithoutExtension]", FileNameWithoutExtension);
	Result = StrReplace(Result, "[Literal]",               Literal);
	Result = StrReplace(Result, "[Extension]",            Extension);
	
	Return Result;
EndFunction

Function ExchangePlanNodeCodeString(Value) Export
	
	If TypeOf(Value) = Type("String") Then
		
		Return TrimAll(Value);
		
	ElsIf TypeOf(Value) = Type("Number") Then
		
		Return Format(Value, "ND=7; NLZ=; NG=0");
		
	EndIf;
	
	Return Value;
EndFunction

Function PredefinedExchangePlanNodeDescription(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return Common.ObjectAttributeValue(DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName), "Description");
EndFunction

Procedure OnSSLDataExportHandler(StandardProcessing,
											Val Recipient,
											Val MessageFileName,
											MessageData,
											Val TransactionItemsCount,
											Val EventLogEventName,
											SentObjectsCount)
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.MessageExchange") Then
		ModuleMessageExchangeInternal = Common.CommonModule("MessageExchangeInternal");
		ModuleMessageExchangeInternal.OnDataExport(
			StandardProcessing,
			Recipient,
			MessageFileName,
			MessageData,
			TransactionItemsCount,
			EventLogEventName,
			SentObjectsCount);
	EndIf;
	
EndProcedure

Procedure OnDataExportHandler(StandardProcessing,
											Val Recipient,
											Val MessageFileName,
											MessageData,
											Val TransactionItemsCount,
											Val EventLogEventName,
											SentObjectsCount)
	
	DataExchangeOverridable.OnDataExport(StandardProcessing,
											Recipient,
											MessageFileName,
											MessageData,
											TransactionItemsCount,
											EventLogEventName,
											SentObjectsCount);
	
EndProcedure

Procedure OnSSLDataImportHandler(StandardProcessing,
											Val Sender,
											Val MessageFileName,
											MessageData,
											Val TransactionItemsCount,
											Val EventLogEventName,
											ReceivedObjectsCount)
	
	
	If Common.SubsystemExists("StandardSubsystems.SaaS.MessageExchange") Then
		ModuleMessageExchangeInternal = Common.CommonModule("MessageExchangeInternal");
		ModuleMessageExchangeInternal.OnDataImport(
			StandardProcessing,
			Sender,
			MessageFileName,
			MessageData,
			TransactionItemsCount,
			EventLogEventName,
			ReceivedObjectsCount);
	EndIf;
	
EndProcedure

Procedure OnDataImportHandler(StandardProcessing,
											Val Sender,
											Val MessageFileName,
											MessageData,
											Val TransactionItemsCount,
											Val EventLogEventName,
											ReceivedObjectsCount)
	
	DataExchangeOverridable.OnDataImport(StandardProcessing,
											Sender,
											MessageFileName,
											MessageData,
											TransactionItemsCount,
											EventLogEventName,
											ReceivedObjectsCount);
	
EndProcedure

Procedure RecordExchangeCompletionWithError(Val InfobaseNode, 
												Val ActionOnExchange, 
												Val StartDate, 
												Val ErrorMessageString) Export
	
	If TypeOf(ActionOnExchange) = Type("String") Then
		
		ActionOnExchange = Enums.ActionsOnExchange[ActionOnExchange];
		
	EndIf;
	
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("InfobaseNode", InfobaseNode);
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult", Enums.ExchangeExecutionResults.Error);
	ExchangeSettingsStructure.Insert("ActionOnExchange", ActionOnExchange);
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("EventLogMessageKey", EventLogMessageKey(InfobaseNode, ActionOnExchange));
	ExchangeSettingsStructure.Insert("StartDate", StartDate);
	ExchangeSettingsStructure.Insert("EndDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("IsDIBExchange", DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode));
	
	WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
	
	AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
EndProcedure

// Checks whether the specified attributes are on the form.
// If at least one attribute is absent, the exception is raised.
//
Procedure CheckMandatoryFormAttributes(Form, Val Attributes)
	
	AbsentAttributes = New Array;
	
	FormAttributes = FormAttributeNames(Form);
	
	For Each Attribute In StrSplit(Attributes, ",") Do
		
		Attribute = TrimAll(Attribute);
		
		If FormAttributes.Find(Attribute) = Undefined Then
			
			AbsentAttributes.Add(Attribute);
			
		EndIf;
		
	EndDo;
	
	If AbsentAttributes.Count() > 0 Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Отсутствуют обязательные реквизиты формы настройки узла: %1'; en = 'Mandatory attributes of the node setup form are missing: %1.'; pl = 'Brak wymaganych atrybutów formularza konfiguracji węzła: %1';de = 'Keine erforderlichen Attribute des Knotenkonfigurationsformulars: %1';ro = 'Nu există atributele necesare ale formei de configurare a nodului: %1';tr = 'Ünite yapılandırma formunun gerekli özellikleri yok:%1'; es_ES = 'Atributos no requeridos del formulario de la configuración del nodo: %1'"),
			StrConcat(AbsentAttributes, ","));
	EndIf;
	
EndProcedure

Procedure ExternalConnectionUpdateDataExchangeSettings(Val ExchangePlanName, Val NodeCode, Val DefaultNodeValues) Export
	
	SetPrivilegedMode(True);
	
	InfobaseNode = ExchangePlans[ExchangePlanName].FindByCode(NodeCode);
	
	If Not ValueIsFilled(InfobaseNode) Then
		Message = NStr("ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2'; en = 'The exchange plan node is not found. Node name: %1. Node code: %2.'; pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2';de = 'Der Austauschplan-Knoten wurde nicht gefunden. Name des Austauschplans %1; Knotencode %2';ro = 'Nodul planului de schimb nu a fost găsit; numele planului de schimb %1; codul nodului %2';tr = 'Değişim plan ünitesi bulunamadı; değişim planı adı%1; ünite kodu %2'; es_ES = 'Nodo del plan de intercambio no encontrado; nombre del plan de intercambio %1; código del nodo %2'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, NodeCode);
		Raise Message;
	EndIf;
	
	DataExchangeCreationWizard = ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.InfobaseNode = InfobaseNode;
	DataExchangeCreationWizard.ExternalConnectionUpdateDataExchangeSettings(GetFilterSettingsValues(DefaultNodeValues));
	
EndProcedure

Function GetFilterSettingsValues(ExternalConnectionSettingsStructure) Export
	
	Result = New Structure;
	
	// object types
	For Each FilterSetting In ExternalConnectionSettingsStructure Do
		
		If TypeOf(FilterSetting.Value) = Type("Structure") Then
			
			ResultNested = New Structure;
			
			For Each Item In FilterSetting.Value Do
				
				If StrFind(Item.Key, "_Key") > 0 Then
					
					varKey = StrReplace(Item.Key, "_Key", "");
					
					Array = New Array;
					
					For Each ArrayElement In Item.Value Do
						
						If Not IsBlankString(ArrayElement) Then
							
							Value = ValueFromStringInternal(ArrayElement);
							
							Array.Add(Value);
							
						EndIf;
						
					EndDo;
					
					ResultNested.Insert(varKey, Array);
					
				EndIf;
				
			EndDo;
			
			Result.Insert(FilterSetting.Key, ResultNested);
			
		Else
			
			If StrFind(FilterSetting.Key, "_Key") > 0 Then
				
				varKey = StrReplace(FilterSetting.Key, "_Key", "");
				
				Try
					If IsBlankString(FilterSetting.Value) Then
						Value = Undefined;
					Else
						Value = ValueFromStringInternal(FilterSetting.Value);
					EndIf;
				Except
					Value = Undefined;
				EndTry;
				
				Result.Insert(varKey, Value);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Primitive types
	For Each FilterSetting In ExternalConnectionSettingsStructure Do
		
		If TypeOf(FilterSetting.Value) = Type("Structure") Then
			
			ResultNested = Result[FilterSetting.Key];
			
			If ResultNested = Undefined Then
				
				ResultNested = New Structure;
				
			EndIf;
			
			For Each Item In FilterSetting.Value Do
				
				If StrFind(Item.Key, "_Key") <> 0 Then
					
					Continue;
					
				ElsIf FilterSetting.Value.Property(Item.Key + "_Key") Then
					
					Continue;
					
				EndIf;
				
				Array = New Array;
				
				For Each ArrayElement In Item.Value Do
					
					Array.Add(ArrayElement);
					
				EndDo;
				
				ResultNested.Insert(Item.Key, Array);
				
			EndDo;
			
		Else
			
			If StrFind(FilterSetting.Key, "_Key") <> 0 Then
				
				Continue;
				
			ElsIf ExternalConnectionSettingsStructure.Property(FilterSetting.Key + "_Key") Then
				
				Continue;
				
			EndIf;
			
			// Shielding the enumeration
			If TypeOf(FilterSetting.Value) = Type("String")
				AND (     StrFind(FilterSetting.Value, "Enum.") <> 0
					OR StrFind(FilterSetting.Value, "Enumeration.") <> 0) Then
				
				Result.Insert(FilterSetting.Key, PredefinedValue(FilterSetting.Value));
				
			Else
				
				Result.Insert(FilterSetting.Key, FilterSetting.Value);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function DataForThisInfobaseNodeTabularSections(Val ExchangePlanName, CorrespondentVersion = "", SettingID = "") Export
	
	Result = New Structure;
	
	NodeCommonTables = DataExchangeCached.ExchangePlanTabularSections(ExchangePlanName, CorrespondentVersion, SettingID)["AllTablesOfThisInfobase"];
	
	For Each TabularSectionName In NodeCommonTables Do
		
		TableName = TableNameFromExchangePlanTabularSectionFirstAttribute(ExchangePlanName, TabularSectionName);
		
		If Not ValueIsFilled(TableName) Then
			Continue;
		EndIf;
		
		TabularSectionData = New ValueTable;
		TabularSectionData.Columns.Add("Presentation",                 New TypeDescription("String"));
		TabularSectionData.Columns.Add("RefUUID", New TypeDescription("String"));
		
		QueryText =
		"SELECT TOP 1000
		|	Table.Ref AS Ref,
		|	Table.Presentation AS Presentation
		|FROM
		|	[TableName] AS Table
		|
		|WHERE
		|	NOT Table.DeletionMark
		|
		|ORDER BY
		|	Table.Presentation";
		
		QueryText = StrReplace(QueryText, "[TableName]", TableName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			TableRow = TabularSectionData.Add();
			TableRow.Presentation = Selection.Presentation;
			TableRow.RefUUID = String(Selection.Ref.UUID());
			
		EndDo;
		
		Result.Insert(TabularSectionName, TabularSectionData);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function TableNameFromExchangePlanTabularSectionFirstAttribute(Val ExchangePlanName, Val TabularSectionName)
	
	TabularSection = Metadata.ExchangePlans[ExchangePlanName].TabularSections[TabularSectionName];
	
	For Each Attribute In TabularSection.Attributes Do
		
		Type = Attribute.Type.Types()[0];
		
		If Common.IsReference(Type) Then
			
			Return Metadata.FindByType(Type).FullName();
			
		EndIf;
		
	EndDo;
	
	Return "";
EndFunction

Function ExchangePlanCatalogs(Val ExchangePlanName)
	
	If TypeOf(ExchangePlanName) <> Type("String") Then
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanName);
		
	EndIf;
	
	Result = New Array;
	
	ExchangePlanComposition = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	For Each Item In ExchangePlanComposition Do
		
		If Common.IsCatalog(Item.Metadata)
			OR Common.IsChartOfCharacteristicTypes(Item.Metadata) Then
			
			Result.Add(Item.Metadata);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function AllExchangePlanDataExceptCatalogs(Val ExchangePlanName)
	
	If TypeOf(ExchangePlanName) <> Type("String") Then
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanName);
		
	EndIf;
	
	Result = New Array;
	
	ExchangePlanComposition = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	For Each Item In ExchangePlanComposition Do
		
		If Not (Common.IsCatalog(Item.Metadata)
			OR Common.IsChartOfCharacteristicTypes(Item.Metadata)) Then
			
			Result.Add(Item.Metadata);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function AccountingParametersSettingsAreSet(Val ExchangePlanName, Val Correspondent, ErrorMessage)
	
	If TypeOf(Correspondent) = Type("String") Then
		
		If IsBlankString(Correspondent) Then
			Return False;
		EndIf;
		
		CorrespondentCode = Correspondent;
		
		Correspondent = ExchangePlans[ExchangePlanName].FindByCode(Correspondent);
		
		If Not ValueIsFilled(Correspondent) Then
			Message = NStr("ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2'; en = 'The exchange plan node is not found. Node name: %1. Node code: %2.'; pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2';de = 'Der Austauschplan-Knoten wurde nicht gefunden. Name des Austauschplans %1; Knotencode %2';ro = 'Nodul planului de schimb nu a fost găsit; numele planului de schimb %1; codul nodului %2';tr = 'Değişim plan ünitesi bulunamadı; değişim planı adı%1; ünite kodu %2'; es_ES = 'Nodo del plan de intercambio no encontrado; nombre del plan de intercambio %1; código del nodo %2'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, CorrespondentCode);
			Raise Message;
		EndIf;
		
	EndIf;
	
	Cancel = False;
	If HasExchangePlanManagerAlgorithm("AccountingSettingsCheckHandler", ExchangePlanName) Then
		SetPrivilegedMode(True);
		ExchangePlans[ExchangePlanName].AccountingSettingsCheckHandler(Cancel, Correspondent, ErrorMessage);
	EndIf;
	
	Return Not Cancel;
EndFunction

Function GetInfobaseParameters(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return ValueToStringInternal(InfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage));
	
EndFunction

Function GetInfobaseParameters_2_0_1_6(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return Common.ValueToXMLString(InfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage));
	
EndFunction

Function MetadataObjectProperties(Val FullTableName) Export
	
	Result = New Structure("Synonym, Hierarchical");
	
	MetadataObject = Metadata.FindByFullName(FullTableName);
	
	FillPropertyValues(Result, MetadataObject);
	
	Return Result;
EndFunction

Function GetTableObjects(Val FullTableName) Export
	SetPrivilegedMode(True);
	
	MetadataObject = Metadata.FindByFullName(FullTableName);
	
	If Common.IsCatalog(MetadataObject) Then
		
		If MetadataObject.Hierarchical Then
			If MetadataObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
				Return HierarchicalCatalogItemsHierarchyFoldersAndItems(FullTableName);
			EndIf;
			
			Return HierarchicalCatalogItemsHierarchyItems(FullTableName);
		EndIf;
		
		Return NonhierarchicalCatalogItems(FullTableName);
		
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		
		If MetadataObject.Hierarchical Then
			Return HierarchicalCatalogItemsHierarchyFoldersAndItems(FullTableName);
		EndIf;
		
		Return NonhierarchicalCatalogItems(FullTableName);
		
	EndIf;
	
	Return Undefined;
EndFunction

Function HierarchicalCatalogItemsHierarchyFoldersAndItems(Val FullTableName)
	
	Query = New Query("
		|SELECT TOP 2000
		|	Ref,
		|	Presentation,
		|	CASE
		|		WHEN    IsFolder AND NOT DeletionMark THEN 0
		|		WHEN    IsFolder AND    DeletionMark THEN 1
		|		WHEN NOT IsFolder AND NOT DeletionMark THEN 2
		|		WHEN NOT IsFolder AND    DeletionMark THEN 3
		|	END AS PictureIndex
		|FROM
		|	" + FullTableName + "
		|ORDER BY
		|	IsFolder HIERARCHY,
		|	Description
		|");
		
	Return QueryResultToXMLTree(Query);
EndFunction

Function HierarchicalCatalogItemsHierarchyItems(Val FullTableName)
	
	Query = New Query("
		|SELECT TOP 2000
		|	Ref,
		|	Presentation,
		|	CASE
		|		WHEN DeletionMark THEN 3
		|		ELSE 2
		|	END AS PictureIndex
		|FROM
		|	" + FullTableName + "
		|ORDER BY
		|	Description HIERARCHY
		|");
		
	Return QueryResultToXMLTree(Query);
EndFunction

Function NonhierarchicalCatalogItems(Val FullTableName)
	
	Query = New Query("
		|SELECT TOP 2000
		|	Ref,
		|	Presentation,
		|	CASE
		|		WHEN DeletionMark THEN 3
		|		ELSE 2
		|	END AS PictureIndex
		|FROM
		|	" + FullTableName + " 
		|ORDER BY
		|	Description
		|");
		
	Return QueryResultToXMLTree(Query);
EndFunction

Function QueryResultToXMLTree(Val Query)
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	Result.Columns.Add("ID", New TypeDescription("String"));
	FillRefIDInTree(Result.Rows);
	
	ColumnRef = Result.Columns.Find("Ref");
	If Not ColumnRef = Undefined Then
		Result.Columns.Delete(ColumnRef);
	EndIf;
	
	Return Common.ValueToXMLString(Result);
EndFunction

Procedure FillRefIDInTree(TreeRows)
	
	For Each Row In TreeRows Do
		Row.ID = XMLString(Row.Ref);
		FillRefIDInTree(Row.Rows);
	EndDo;
	
EndProcedure

Function CorrespondentData(Val FullTableName) Export
	
	Result = New Structure("MetadataObjectProperties, CorrespondentInfobaseTable");
	
	Result.MetadataObjectProperties = MetadataObjectProperties(FullTableName);
	Result.CorrespondentInfobaseTable = GetTableObjects(FullTableName);
	
	Return Result;
EndFunction

Function InfobaseParameters(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Result = New Structure;
	
	Result.Insert("ExchangePlanExists",                      False);
	Result.Insert("InfobasePrefix",                 "");
	Result.Insert("DefaultInfobasePrefix",      "");
	Result.Insert("InfobaseDescription",            "");
	Result.Insert("DefaultInfobaseDescription", "");
	Result.Insert("AccountingParametersSettingsAreSpecified",            False);
	Result.Insert("ThisNodeCode",                              "");
	// SSL version 2.1.5.1 or later.
	Result.Insert("ConfigurationVersion",                        Metadata.Version);
	// SSL version 2.4.2(?) or later.
	Result.Insert("NodeExists",                            False);
	// SSL version 3.0.1.1 or later.
	Result.Insert("DataExchangeSettingsFormatVersion",        ModuleDataExchangeCreationWizard().DataExchangeSettingsFormatVersion());
	Result.Insert("UsePrefixesForExchangeSettings",    True);
	Result.Insert("ExchangeFormat",                              "");
	Result.Insert("ExchangePlanName",                            ExchangePlanName);
	Result.Insert("ExchangeFormatVersions",                       New Array);
	Result.Insert("SupportedObjectsInFormat",              Undefined);
	
	Result.Insert("DataSynchronizationSetupCompleted",     False);
	Result.Insert("EmailReceivedForDataMapping",   False);
	Result.Insert("DataMappingSupported",         True);
	
	SetPrivilegedMode(True);
	
	Result.ExchangePlanExists = (Metadata.ExchangePlans.Find(ExchangePlanName) <> Undefined);
	
	If Not Result.ExchangePlanExists Then
		// Exchange format can be passed as an exchange plan name.
		For Each ExchangePlan In DataExchangeCached.SSLExchangePlans() Do
			If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlan) Then
				Continue;
			EndIf;
			
			ExchangeFormat = ExchangePlanSettingValue(ExchangePlan, "ExchangeFormat");
			If ExchangePlanName = ExchangeFormat Then
				Result.ExchangePlanExists = True;
				Result.ExchangePlanName = ExchangePlan;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not Result.ExchangePlanExists Then
		Return Result;
	EndIf;
	
	ThisNode = ExchangePlans[Result.ExchangePlanName].ThisNode();
	
	ThisNodeProperties = Common.ObjectAttributesValues(ThisNode, "Code, Description");
	
	InfobasePrefix = Undefined;
	DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(InfobasePrefix);
	
	CorrespondentNode = Undefined;
	If ValueIsFilled(NodeCode) Then
		CorrespondentNode = ExchangePlanNodeByCode(Result.ExchangePlanName, NodeCode);
	EndIf;
	
	Result.InfobasePrefix            = GetFunctionalOption("InfobasePrefix");
	Result.DefaultInfobasePrefix = InfobasePrefix;
	Result.InfobaseDescription       = ThisNodeProperties.Description;
	Result.NodeExists                       = ValueIsFilled(CorrespondentNode);
	Result.AccountingParametersSettingsAreSpecified       = Result.NodeExists
		AND AccountingParametersSettingsAreSet(Result.ExchangePlanName, NodeCode, ErrorMessage);
	Result.ThisNodeCode                         = ThisNodeProperties.Code;
	Result.ConfigurationVersion                   = Metadata.Version;
	
	Result.DefaultInfobaseDescription = ?(Common.DataSeparationEnabled(),
		Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
		
	If DataExchangeCached.IsXDTOExchangePlan(Result.ExchangePlanName) Then
		Result.UsePrefixesForExchangeSettings = 
			Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ThisNode);
			
		ExchangePlanProperties = ExchangePlanSettingValue(Result.ExchangePlanName, "ExchangeFormatVersions, ExchangeFormat");
		
		Result.ExchangeFormat        = ExchangePlanProperties.ExchangeFormat;
		Result.ExchangeFormatVersions = Common.UnloadColumn(ExchangePlanProperties.ExchangeFormatVersions, "Key", True);
		
		Result.Insert("SupportedObjectsInFormat",
			DataExchangeXDTOServer.SupportedObjectsInFormat(Result.ExchangePlanName, "SendGet", CorrespondentNode));
	EndIf;
		
	If Result.NodeExists Then
		Result.DataSynchronizationSetupCompleted   = SynchronizationSetupCompleted(CorrespondentNode);
		Result.EmailReceivedForDataMapping = MessageWithDataForMappingReceived(CorrespondentNode);
		Result.DataMappingSupported = ExchangePlanSettingValue(Result.ExchangePlanName,
			"DataMappingSupported", SavedExchangePlanNodeSettingOption(CorrespondentNode));
	EndIf;
			
	Return Result;
	
EndFunction

Function StatisticsInformation(StatisticsInformation, Val EnableObjectDeletion = False) Export
	
	ArrayFilter = StatisticsInformation.UnloadColumn("DestinationTableName");
	
	FilterString = StrConcat(ArrayFilter, ",");
	
	Filter = New Structure("FullName", FilterString);
	
	// Getting configuration metadata object tree.
	StatisticsInformationTree = DataExchangeCached.ConfigurationMetadata(Filter).Copy();
	
	// Adding columns
	StatisticsInformationTree.Columns.Add("Key");
	StatisticsInformationTree.Columns.Add("ObjectCountInSource");
	StatisticsInformationTree.Columns.Add("ObjectCountInDestination");
	StatisticsInformationTree.Columns.Add("UnmappedObjectCount");
	StatisticsInformationTree.Columns.Add("MappedObjectPercentage");
	StatisticsInformationTree.Columns.Add("PictureIndex");
	StatisticsInformationTree.Columns.Add("UsePreview");
	StatisticsInformationTree.Columns.Add("DestinationTableName");
	StatisticsInformationTree.Columns.Add("ObjectTypeString");
	StatisticsInformationTree.Columns.Add("TableFields");
	StatisticsInformationTree.Columns.Add("SearchFields");
	StatisticsInformationTree.Columns.Add("SourceTypeString");
	StatisticsInformationTree.Columns.Add("DestinationTypeString");
	StatisticsInformationTree.Columns.Add("IsObjectDeletion");
	StatisticsInformationTree.Columns.Add("DataImportedSuccessfully");
	
	
	// Indexes for searching in the statistics.
	Indexes = StatisticsInformation.Indexes;
	If Indexes.Count() = 0 Then
		If EnableObjectDeletion Then
			Indexes.Add("IsObjectDeletion");
			Indexes.Add("OneToMany, IsObjectDeletion");
			Indexes.Add("IsClassifier, IsObjectDeletion");
		Else
			Indexes.Add("OneToMany");
			Indexes.Add("IsClassifier");
		EndIf;
	EndIf;
	
	ProcessedRows = New Map;
	
	// Normal strings
	Filter = New Structure("OneToMany", False);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
		
	For Each TableRow In StatisticsInformation.FindRows(Filter) Do
		TreeRow = StatisticsInformationTree.Rows.Find(TableRow.DestinationTableName, "FullName", True);
		FillPropertyValues(TreeRow, TableRow);
		
		TreeRow.Synonym = DataSynonymOfStatisticsTreeRow(TreeRow, TableRow.SourceTypeString);
		
		ProcessedRows[TableRow] = True;
	EndDo;
	
	// Adding rows of OneToMany type.
	Filter = New Structure("OneToMany", True);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
	FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	
	// Adding classifier rows.
	Filter = New Structure("IsClassifier", True);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
	FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	
	// Adding rows for object deletion.
	If EnableObjectDeletion Then
		Filter = New Structure("IsObjectDeletion", True);
		FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	EndIf;
	
	// Clearing empty rows
	StatisticsRows = StatisticsInformationTree.Rows;
	GroupPosition = StatisticsRows.Count() - 1;
	While GroupPosition >=0 Do
		Folder = StatisticsRows[GroupPosition];
		
		Items = Folder.Rows;
		Position = Items.Count() - 1;
		While Position >=0 Do
			Item = Items[Position];
			
			If Item.ObjectCountInDestination = Undefined 
				AND Item.ObjectCountInSource = Undefined
				AND Item.Rows.Count() = 0 Then
				Items.Delete(Item);
			EndIf;
			
			Position = Position - 1;
		EndDo;
		
		If Items.Count() = 0 Then
			StatisticsRows.Delete(Folder);
		EndIf;
		GroupPosition = GroupPosition - 1;
	EndDo;
	
	Return StatisticsInformationTree;
EndFunction

Procedure FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, AlreadyProcessedRows)
	
	RowsToProcess = StatisticsInformation.FindRows(Filter);
	
	// Ignoring processed source rows.
	Position = RowsToProcess.UBound();
	While Position >= 0 Do
		Candidate = RowsToProcess[Position];
		
		If AlreadyProcessedRows[Candidate] <> Undefined Then
			RowsToProcess.Delete(Position);
		Else
			AlreadyProcessedRows[Candidate] = True;
		EndIf;
		
		Position = Position - 1;
	EndDo;
		
	If RowsToProcess.Count() = 0 Then
		Return;
	EndIf;
	
	StatisticsOneToMany = StatisticsInformation.Copy(RowsToProcess);
	StatisticsOneToMany.Indexes.Add("DestinationTableName");
	
	StatisticsOneToManyTemporary = StatisticsOneToMany.Copy(RowsToProcess, "DestinationTableName");
	
	StatisticsOneToManyTemporary.GroupBy("DestinationTableName");
	
	For Each TableRow In StatisticsOneToManyTemporary Do
		Rows       = StatisticsOneToMany.FindRows(New Structure("DestinationTableName", TableRow.DestinationTableName));
		TreeRow = StatisticsInformationTree.Rows.Find(TableRow.DestinationTableName, "FullName", True);
		
		For Each Row In Rows Do
			NewTreeRow = TreeRow.Rows.Add();
			FillPropertyValues(NewTreeRow, TreeRow);
			FillPropertyValues(NewTreeRow, Row);
			
			If Row.IsObjectDeletion Then
				NewTreeRow.Picture = PictureLib.MarkToDelete;
			Else
				NewTreeRow.Synonym = DataSynonymOfStatisticsTreeRow(NewTreeRow, Row.SourceTypeString) ;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function DeleteClassNameFromObjectName(Val Result)
	
	Result = StrReplace(Result, "DocumentRef.", "");
	Result = StrReplace(Result, "CatalogRef.", "");
	Result = StrReplace(Result, "ChartOfCharacteristicTypesRef.", "");
	Result = StrReplace(Result, "ChartOfAccountsRef.", "");
	Result = StrReplace(Result, "ChartOfCalculationTypesRef.", "");
	Result = StrReplace(Result, "BusinessProcessRef.", "");
	Result = StrReplace(Result, "TaskRef.", "");
	
	Return Result;
EndFunction

Procedure CheckLoadedFromFileExchangeRulesAvailability(LoadedFromFileExchangeRules, RegistrationRulesImportedFromFile)
	
	QueryText = "SELECT DISTINCT
	|	DataExchangeRules.ExchangePlanName AS ExchangePlanName,
	|	DataExchangeRules.RulesKind AS RulesKind
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.RulesSource = VALUE(Enum.DataExchangeRulesSources.File)
	|	AND DataExchangeRules.RulesAreImported";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		ExchangePlansArray = New Array;
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			If Selection.RulesKind = Enums.DataExchangeRulesTypes.ObjectConversionRules Then
				
				LoadedFromFileExchangeRules.Add(Selection.ExchangePlanName);
				
			ElsIf Selection.RulesKind = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules Then
				
				RegistrationRulesImportedFromFile.Add(Selection.ExchangePlanName);
				
			EndIf;
			
			If ExchangePlansArray.Find(Selection.ExchangePlanName) = Undefined Then
				
				ExchangePlansArray.Add(Selection.ExchangePlanName);
				
			EndIf;
			
		EndDo;
		
		MessageString = NStr("ru = 'Для планов обмена %1 используются правила обмена, загруженные из файла.
				|Эти правила могут быть несовместимы с новой версией программы.
				|Для предупреждения возможного возникновения ошибок при работе с программой рекомендуется актуализировать правила обмена из файла.'; 
				|en = 'The exchange rules imported from a file apply to exchange plans %1.
				|These rules might be incompatible with the new application version.
				|It is recommended that you verify these exchange rules.'; 
				|pl = 'Do %1 planów wymiany, stosowane są reguły wymiany importowane z pliku.
				|Reguły te mogą być niezgodne z nową wersją aplikacji.
				|Aby zapobiec możliwym błędom podczas pracy z aplikacją, zaleca się aktualizację reguł wymiany z pliku.';
				|de = 'Für %1Austauschpläne werden die aus einer Datei importierten Austauschregeln verwendet. 
				|Diese Regeln können mit der neuen Anwendungsversion nicht kompatibel sein. 
				|Um mögliche Fehler beim Arbeiten mit der Anwendung zu vermeiden, empfiehlt es sich, die Austauschregeln aus der Datei zu aktualisieren.';
				|ro = 'Pentru planurile de schimb %1 se utilizează regulile de schimb importate din fișier. 
				|Aceste reguli pot fi incompatibile cu noua versiune a aplicației.
				|Pentru a preveni posibilele erori la lucrul cu aplicația, se recomandă actualizarea regulilor de schimb din fișier.';
				|tr = 'Değişim planları %1 için dosyadan aktarılan değişim kuralları kullanılır. 
				|Bu kurallar yeni uygulama sürümü ile uyumsuz olabilir. 
				|Uygulama ile çalışırken olası hata oluşumunu önlemek için, değişim kurallarını dosyadan gerçekleştirmeniz önerilir.'; 
				|es_ES = 'Para %1 los planes de intercambio, las reglas de intercambio importadas desde el archivo se utilizan.
				|Estas reglas pueden ser incompatibles con la versión nueva de la aplicación.
				|Para prevenir el acontecimiento de un posible error durante el trabajo con la aplicación, se recomienda actualizar las reglas de intercambio desde el archivo.'",
				Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, StrConcat(ExchangePlansArray, ","));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,, MessageString);
		
	EndIf;
	
EndProcedure

// Verifies the transport processor connection by the specified settings.
//
Procedure CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
		SettingsStructure, TransportKind, ErrorMessage = "", NewPasswords = Undefined) Export
	
	SetPrivilegedMode(True);
	
	// Creating data processor instance.
	DataProcessorObject = DataProcessors[DataExchangeMessageTransportDataProcessorName(TransportKind)].Create();
	
	// Initializing data processor properties with the passed settings parameters.
	FillPropertyValues(DataProcessorObject, SettingsStructure);
	
	// Privileged mode has already been set.
	If SettingsStructure.Property("Correspondent") Then
		If NewPasswords = Undefined Then
			Passwords = Common.ReadDataFromSecureStorage(SettingsStructure.Correspondent,
				"COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages", True);
		Else
			Passwords = New Structure(
				"COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages");
			FillPropertyValues(Passwords, NewPasswords);
		EndIf;
		FillPropertyValues(DataProcessorObject, Passwords);
	EndIf;
	
	// Initializing the exchange transport.
	DataProcessorObject.Initializing();
	
	// Checking the connection.
	If Not DataProcessorObject.ConnectionIsSet() Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessageString
			+ Chars.LF + NStr("ru = 'Техническую информацию об ошибке см. в журнале регистрации.'; en = 'See the event log for details.'; pl = 'Informacje techniczne o błędzie znajdziesz w dzienniku zdarzeń.';de = 'Siehe technische Informationen zum Fehler im Ereignisprotokoll.';ro = 'Informațiile tehnice despre eroare vezi în registrul logare.';tr = 'Olay günlüğündeki hata hakkındaki teknik bilgilere bakın.'; es_ES = 'Ver la información técnica sobre el error en el registro de eventos.'");
		
		WriteLogEvent(NStr("ru = 'Транспорт сообщений обмена'; en = 'Exchange message transport'; pl = 'Transport wiadomości wymiany';de = 'Austausch-Nachrichtentransport';ro = 'Transportul mesajelor de schimb';tr = 'Değişim ileti aktarımı'; es_ES = 'Transporte de mensajes de intercambio'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DataProcessorObject.ErrorMessageStringEL);
		
	EndIf;
	
EndProcedure

// Main function that is used to perform the data exchange over the external connection.
//
// Parameters:
//  SettingsStructure - a structure of COM exchange transport settings.
//
// Returns:
//  Structure - 
//    * Connection - COMObject, Undefined - if the connection is established, returns a COM object 
//                                    reference. Otherwise, returns Undefined.
//    * BriefErrorDescription       - String - a brief error description.
//    * DetailedErrorDescription     - String - a detailed error description.
//    * ErrorAttachingAddIn - Boolean - a COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(SettingsStructure) Export
	
	Result = Common.EstablishExternalConnectionWithInfobase(
		FillExternalConnectionParameters(SettingsStructure));
	
	ExternalConnection = Result.Connection;
	If ExternalConnection = Undefined Then
		// Connection establish error.
		Return Result;
	EndIf;
	
	// Checking whether it is possible to operate with the external infobase.
	
	Try
		NoFullAccess = Not ExternalConnection.DataExchangeExternalConnection.RoleAvailableFullAccess();
	Except
		NoFullAccess = True;
	EndTry;
	
	If NoFullAccess Then
		Result.DetailedErrorDescription = NStr("ru = 'Пользователю, указанному для подключения к другой программе, должны быть назначены роли ""Администратор системы"" и ""Полные права""'; en = 'The user on whose behalf connection to the other application is established must have ""System administrator"" and ""Full access"" roles.'; pl = 'Użytkownikowi, wskazanemu do połączenia z inną aplikacją powinny zostać przypisane role ""Administrator systemu"" i ""Pełne uprawnienia""';de = 'Benutzer, der für die Verbindung mit einer anderen Anwendung angegeben wurde, sollte die Rollen ""Systemadministrator"" und ""Volle Rechte"" zugewiesen bekommen haben';ro = 'Pentru utilizatorul specificat pentru conectare la altă aplicație trebuie atribuite rolurile ""Administrator de sistem"" și ""Drepturi depline""';tr = 'Başka bir uygulamaya bağlantı için belirtilen kullanıcı ""Sistem yöneticisi"" ve ""Tam haklar"" rollerine atanmış olmalıdır.'; es_ES = 'Usuario especificado para la conexión a otra aplicación tiene que tener los roles asignados de ""Administrador del sistema"" y ""Plenos derechos""'");
		Result.BriefErrorDescription   = Result.DetailedErrorDescription;
		Result.Connection = Undefined;
	Else
		Try 
			InvalidState = ExternalConnection.InfobaseUpdate.InfobaseUpdateRequired();
		Except
			InvalidState = False
		EndTry;
		
		If InvalidState Then
			Result.DetailedErrorDescription = NStr("ru = 'Другая программа находится в состоянии обновления.'; en = 'An update of the other application is pending.'; pl = 'Trwa aktualizacja innej aplikacji.';de = 'Eine andere Anwendung wird aktualisiert.';ro = 'O altă aplicație se află în statut de actualizare.';tr = 'Başka bir uygulama güncelleniyor.'; es_ES = 'Otra aplicación se está actualizando.'");
			Result.BriefErrorDescription   = Result.DetailedErrorDescription;
			Result.Connection = Undefined;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

Function TransportSettingsByExternalConnectionParameters(Parameters)
	
	// Converting external connection parameters to transport parameters.
	TransportSettings = New Structure;
	
	TransportSettings.Insert("COMUserPassword",
		CommonClientServer.StructureProperty(Parameters, "UserPassword"));
	TransportSettings.Insert("COMUsername",
		CommonClientServer.StructureProperty(Parameters, "UserName"));
	TransportSettings.Insert("COMOperatingSystemAuthentication",
		CommonClientServer.StructureProperty(Parameters, "OperatingSystemAuthentication"));
	TransportSettings.Insert("COM1CEnterpriseServerSideInfobaseName",
		CommonClientServer.StructureProperty(Parameters, "NameOfInfobaseOn1CEnterpriseServer"));
	TransportSettings.Insert("COM1CEnterpriseServerName",
		CommonClientServer.StructureProperty(Parameters, "NameOf1CEnterpriseServer"));
	TransportSettings.Insert("COMInfobaseDirectory",
		CommonClientServer.StructureProperty(Parameters, "InfobaseDirectory"));
	TransportSettings.Insert("COMInfobaseOperatingMode",
		CommonClientServer.StructureProperty(Parameters, "InfobaseOperatingMode"));
	
	Return TransportSettings;
	
EndFunction

// Initializes WS proxy to execute managing data exchange commands, but before that is checks if 
// there is an exchange node.
//
// Parameters:
//   Proxy - WSProxy - a WS proxy to pass managing commands.
//   SettingsStructure - Structure - a parameter structure to connect to the correspondent and identify exchange settings.
//     * ExchangePlanName - String - name of the exchange plan used during synchronization.
//     * InfobaseNode - ExchangePlanRef - an exchange plan node matching the correspondent.
//     * EventLogMessageKey - String - name of an event to write errors to the event log.
//     * CurrentExchangePlanNode - ExchangePlanRef - a reference to ThisNode of the exchange plan.
//     * CurrentExchangePlanNodeCode - String - an ID of the current exchange plan node.
//     * ActionOnExchange - EnumRef.ActionOnExchange - indicates the exchange direction.
//   ProxyParameters - Structure
//     * AuthenticationParameters - String, Structure - contains a password for authentication on the web-server.
//     * AuthenticationSettingsStructure - Structure - contains a setting structure for authentication on the web-server.
//     * EarliestVersion - String - number of the earliest version of the Data Exchange interface required to perform actions.
//     * CurrentVersion - String - an outgoing one, the actual interface version of the initialized WS proxy.
//   Cancel - Boolean - indicates a failed WS proxy initialization.
//   SetupStatus - Structure - outgoing, returns status of the synchronization setup described in SettingsStructure.
//     * SettingExists - Boolean - True if a setting with the specified exchange plan and node ID exists.
//     * DataSynchronizationSetupCompleted - Boolean - True, if synchronization setup is successfully completed.
//     * DataMappingSupported - Boolean - True if a correspondent supports data mapping.
//     * EmailReceivedForDataMapping - Boolean - True, an email for mapping is imported to correspondent.
//   ErrorMessageString - String - a WS-proxy initialization error.
//
Procedure InitializeWSProxyToManageDataExchange(Proxy,
		SettingsStructure, ProxyParameters, Cancel, SetupStatus, ErrorMessageString = "") Export
	
	MinVersion = "0.0.0.0";
	If ProxyParameters.Property("EarliestVersion") Then
		MinVersion = ProxyParameters.EarliestVersion;
	EndIf;
	
	AuthenticationParameters = Undefined;
	ProxyParameters.Property("AuthenticationParameters", AuthenticationParameters);
	
	AuthenticationSettingsStructure = Undefined;
	ProxyParameters.Property("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	ProxyParameters.Insert("CurrentVersion", Undefined);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AuthenticationParameters",         AuthenticationParameters);
	AdditionalParameters.Insert("EarliestVersion",               MinVersion);
	AdditionalParameters.Insert("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	Proxy = WSProxyForInfobaseNode(
		SettingsStructure.InfobaseNode,
		ErrorMessageString,
		AdditionalParameters);
		
	If Proxy = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	ProxyParameters.CurrentVersion = AdditionalParameters.CurrentVersion;
	
	NodeExists = False;
	
	If IsXDTOExchangePlan(SettingsStructure.ExchangePlanName) Then
		
		NodeAlias = PredefinedNodeAlias(SettingsStructure.InfobaseNode);
		If ValueIsFilled(NodeAlias) Then
			// Checking setting with an old ID (prefix).
			SetupStatus = SynchronizationSettingStatusInCorrespondent(
				Proxy,
				ProxyParameters,
				SettingsStructure.ExchangePlanName,
				NodeAlias);
				
			If SetupStatus.SettingExists Then
				SettingsStructure.CurrentExchangePlanNodeCode = NodeAlias;
				Return;
			Else
				// Checking if migration is possible.
				For Each SetupOption In ObsoleteExchangeSettingsOptions(SettingsStructure.InfobaseNode) Do
					SetupStatus = SynchronizationSettingStatusInCorrespondent(
						Proxy,
						ProxyParameters,
						SetupOption.ExchangePlanName,
						NodeAlias);
					If SetupStatus.SettingExists Then
						If SettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
							SettingsStructure.ExchangePlanName = SetupOption.ExchangePlanName;
							SettingsStructure.CurrentExchangePlanNodeCode = NodeAlias;
						Else
							// This infobase has migrated to a new exchange plan but the correspondent has not.
							// You need to cancel getting data.
							ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'В программе ""%1"" выполняется обновление настроек синхронизации.
								|Загрузка данных отменена. Необходимо запустить синхронизацию данных повторно.'; 
								|en = 'A synchronization settings update is pending in %1.
								|The data import is canceled. Please restart the data synchronization later.'; 
								|pl = 'W programie ""%1"" trwa aktualizacja ustawień synchronizacji.
								|Pobieranie danych zostało anulowane. Należy uruchomić synchronizację danych ponownie.';
								|de = 'Das Programm ""%1"" aktualisiert die Synchronisierungseinstellungen.
								|Der Download der Daten wird abgebrochen. Die Datensynchronisation muss neu gestartet werden.';
								|ro = 'În aplicația ""%1"" are loc actualizarea setărilor de sincronizare.
								|Importul de date este revocat. Trebuie să lansați repetat sincronizarea datelor.';
								|tr = '""%1"" programında eşleşme ayarları güncellenmektedir. 
								| Verilerin içe aktarımı iptal edildi. Veriler tekrar eşleştirilmelidir.'; 
								|es_ES = 'En el programa ""%1"" se están actualizando los ajustes de sincronización.
								|Descarga de datos cancelada. Es necesario volver a lanzar la sincronización de datos.'"),
								Common.ObjectAttributeValue(SettingsStructure.InfobaseNode, "Description"));
							Cancel = True;
						EndIf;
						Return;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		SetupStatus = SynchronizationSettingStatusInCorrespondent(
			Proxy,
			ProxyParameters,
			SettingsStructure.ExchangePlanName,
			SettingsStructure.CurrentExchangePlanNodeCode);
			
		If Not SetupStatus.SettingExists
			AND SettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
			// Checking if migration is possible.
			For Each SetupOption In ObsoleteExchangeSettingsOptions(SettingsStructure.InfobaseNode) Do
				SetupStatus = SynchronizationSettingStatusInCorrespondent(
					Proxy,
					ProxyParameters,
					SetupOption.ExchangePlanName,
					SettingsStructure.CurrentExchangePlanNodeCode);
				If SetupStatus.SettingExists Then
					SettingsStructure.ExchangePlanName = SetupOption.ExchangePlanName;
					Return;
				EndIf;
			EndDo;
		EndIf;
	Else
		SetupStatus = SynchronizationSettingStatusInCorrespondent(
			Proxy,
			ProxyParameters,
			SettingsStructure.ExchangePlanName,
			SettingsStructure.CurrentExchangePlanNodeCode);
	EndIf;
	
	If Not SetupStatus.SettingExists Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдена настройка синхронизации данных ""%1"" с идентификатором ""%2"".'; en = 'Cannot find data synchronization setting for exchange plan ""%1 with ID ""%2"".'; pl = 'Nie znaleziono konfigurowanie synchronizacji danych ""%1"" z identyfikatorem ""%2"".';de = 'Die Datensynchronisationseinstellung ""%1"" mit dem Identifikator ""%2"" wird nicht gefunden.';ro = 'Setarea de sincronizare a datelor ""%1"" cu identificatorul ""%2"" nu a fost găsită.';tr = '""%1"" tanımlayıcısına sahip ""%2"" veri eşleşme ayarı bulunamadı.'; es_ES = 'No se ha encontrado el ajuste de sincronización de datos ""%1"" con el identificador ""%2"".'"),
			SettingsStructure.ExchangePlanName,
			SettingsStructure.CurrentExchangePlanNodeCode);
		Cancel = True;
	EndIf;
	
EndProcedure

Function ObsoleteExchangeSettingsOptions(ExchangeNode)
	
	Result = New Array;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	SetupOption = "";
	If Common.HasObjectAttribute("SettingsMode", ExchangeNode.Metadata()) Then
		SetupOption = Common.ObjectAttributeValue(ExchangeNode, "SettingsMode");
	EndIf;
	
	If ValueIsFilled(SetupOption) Then
		For Each PreviousExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
			If PreviousExchangePlanName = ExchangePlanName Then
				Continue;
			EndIf;
			If DataExchangeCached.IsDistributedInfobaseExchangePlan(PreviousExchangePlanName) Then
				Continue;
			EndIf;
			
			PreviousExchangePlanSettings = ExchangePlanSettingValue(PreviousExchangePlanName,
				"ExchangePlanNameToMigrateToNewExchange,ExchangeSettingsOptions");
			
			If PreviousExchangePlanSettings.ExchangePlanNameToMigrateToNewExchange = ExchangePlanName Then
				SettingsOption = PreviousExchangePlanSettings.ExchangeSettingsOptions.Find(SetupOption, "SettingID");
				If Not SettingsOption = Undefined Then
					Result.Add(New Structure("ExchangePlanName, SettingID", 
						PreviousExchangePlanName, SettingsOption.SettingID));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function SynchronizationSettingStatusInCorrespondent(Proxy, ProxyParameters, ExchangePlanName, NodeID)
	
	Result = New Structure;
	Result.Insert("SettingExists",                     False);
	
	Result.Insert("DataSynchronizationSetupCompleted",   True);
	Result.Insert("EmailReceivedForDataMapping", False);
	Result.Insert("DataMappingSupported",       True);
	
	ErrorMessageString = "";
	If CommonClientServer.CompareVersions(ProxyParameters.CurrentVersion, "2.0.1.6") >= 0 Then
		SettingExists = Proxy.TestConnection(ExchangePlanName, NodeID, ErrorMessageString);
		
		If SettingExists
			AND CommonClientServer.CompareVersions(ProxyParameters.CurrentVersion, "3.0.1.1") >= 0 Then
			ProxyDestinationParameters = Proxy.GetIBParameters(ExchangePlanName, NodeID, ErrorMessageString);
			DestinationParameters = XDTOSerializer.ReadXDTO(ProxyDestinationParameters);
			
			FillPropertyValues(Result, DestinationParameters);
		EndIf;
		
		Result.SettingExists = SettingExists;
	Else
		ProxyDestinationParameters = Proxy.GetIBParameters(ExchangePlanName, NodeID, ErrorMessageString);
		DestinationParameters = ValueFromStringInternal(ProxyDestinationParameters);
		
		If DestinationParameters.Property("NodeExists") Then
			Result.SettingExists = DestinationParameters.NodeExists;
		Else
			Result.SettingExists = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function WSProxyForInfobaseNode(InfobaseNode,
		ErrorMessageString = "",
		AdditionalParameters = Undefined)
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	AuthenticationParameters = Undefined;
	AdditionalParameters.Property("AuthenticationParameters", AuthenticationParameters);
	
	AuthenticationSettingsStructure = Undefined;
	AdditionalParameters.Property("AuthenticationSettingsStructure", AuthenticationSettingsStructure);
	
	MinVersion = Undefined;
	If Not AdditionalParameters.Property("EarliestVersion", MinVersion) Then
		MinVersion = "0.0.0.0";
	EndIf;
	
	AdditionalParameters.Insert("CurrentVersion");
		
	If AuthenticationSettingsStructure = Undefined Then
		If DataExchangeCached.IsMessagesExchangeNode(InfobaseNode) Then
			ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
			AuthenticationSettingsStructure = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(InfobaseNode, AuthenticationParameters);
		Else
			AuthenticationSettingsStructure = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(InfobaseNode, AuthenticationParameters);
		EndIf;
	EndIf;
	
	Try
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(AuthenticationSettingsStructure);
	Except
		ErrorMessageString = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventLogEventEstablishWebServiceConnection(),
			EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	AvailableVersions = New Map;
	For Each Version In StrSplit("3.0.1.1;2.1.1.7;2.0.1.6", ";", False) Do
		AvailableVersions.Insert(Version, CorrespondentVersions.Find(Version) <> Undefined
			AND (CommonClientServer.CompareVersions(Version, MinVersion) >= 0));
	EndDo;
	AvailableVersions.Insert("0.0.0.0", CommonClientServer.CompareVersions("0.0.0.0", MinVersion) >= 0);
	
	WSProxy = Undefined;
	If AvailableVersions.Get("3.0.1.1") = True Then
		WSProxy = GetWSProxy_3_0_1_1(AuthenticationSettingsStructure, ErrorMessageString);
		AdditionalParameters.CurrentVersion = "3.0.1.1";
	ElsIf AvailableVersions.Get("2.1.1.7") = True Then
		WSProxy = GetWSProxy_2_1_1_7(AuthenticationSettingsStructure, ErrorMessageString);
		AdditionalParameters.CurrentVersion = "2.1.1.7";
	ElsIf AvailableVersions.Get("2.0.1.6") = True Then
		WSProxy = GetWSProxy_2_0_1_6(AuthenticationSettingsStructure, ErrorMessageString);
		AdditionalParameters.CurrentVersion = "2.0.1.6";
	ElsIf AvailableVersions.Get("0.0.0.0") = True Then
		WSProxy = GetWSProxy(AuthenticationSettingsStructure, ErrorMessageString);
		AdditionalParameters.CurrentVersion = "0.0.0.0";
	Else
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Корреспондент не поддерживает требуемую версию ""%1"" интерфейса ""ОбменДанными"".'; en = 'The peer does not support the required version %1 of the DataExchange interface.'; pl = 'Korespondent nie obsługuje wymaganej wersji ""%1"" interfejsu ""ОбменДанными"".';de = 'Der Korrespondent unterstützt nicht die erforderliche Version der ""%1"" Schnittstelle ""Datenaustausch"".';ro = 'Corespondentul nu susține versiunea dorită ""%1"" a interfeței ""ОбменДанными"".';tr = 'Muhabir, ""VeriAlışverişi"" arabirimin %1gerekli sürümünü desteklemiyor.'; es_ES = 'El correspondiente no admite la versión requerida ""%1"" de la interfaz ""ОбменДанными"".'"),
			MinVersion);
	EndIf;
	
	Return WSProxy;
EndFunction

Procedure DeleteInsignificantCharactersInConnectionSettings(Settings)
	
	For Each Setting In Settings Do
		
		If TypeOf(Setting.Value) = Type("String") Then
			
			Settings.Insert(Setting.Key, TrimAll(Setting.Value));
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function CorrespondentConnectionEstablished(Val Correspondent,
		Val SettingsStructure,
		UserMessage = "",
		DataSynchronizationSetupCompleted = True,
		EmailReceivedForDataMapping = False) Export
		
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("ExchangePlanName", DataExchangeCached.GetExchangePlanName(Correspondent));
	ExchangeSettingsStructure.Insert("InfobaseNode", Correspondent);
	ExchangeSettingsStructure.Insert("EventLogMessageKey",
		NStr("ru = 'Обмен данными.Проверка подключения'; en = 'Data exchange.Test connection'; pl = 'Wymiana danych. Sprawdzanie połączenia';de = 'Data exchange.Connection check';ro = 'Schimb de date. Verificarea conexiunii';tr = 'Veri değişimi. Bağlantı kontrolü'; es_ES = 'Intercambio de datos.Revisión de conexión'", Common.DefaultLanguageCode()));
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNode",
		DataExchangeCached.GetThisExchangePlanNode(ExchangeSettingsStructure.ExchangePlanName));
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNodeCode",
		NodeIDForExchange(Correspondent));
	ExchangeSettingsStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport); // To check if migration is possible.
		
	ProxyParameters = New Structure;
	ProxyParameters.Insert("AuthenticationParameters",         Undefined);
	ProxyParameters.Insert("AuthenticationSettingsStructure", SettingsStructure);
	
	Proxy = Undefined;
	SetupStatus = Undefined;
	Cancel = False;
	InitializeWSProxyToManageDataExchange(Proxy, ExchangeSettingsStructure, ProxyParameters, Cancel, SetupStatus, UserMessage);
	
	If Cancel Then
		ResetDataSynchronizationPassword(Correspondent);
		DataSynchronizationSetupCompleted = False;
		Return False;
	EndIf;
	
	SetDataSynchronizationPassword(Correspondent, SettingsStructure.WSPassword);
	
	DataSynchronizationSetupCompleted   = SetupStatus.DataSynchronizationSetupCompleted;
	EmailReceivedForDataMapping = SetupStatus.EmailReceivedForDataMapping;
	
	Return SetupStatus.SettingExists;
	
EndFunction

// Displays the error message and sets the Cancellation flag to True.
//
// Parameters:
//  MessageText - string, message text.
//  Cancel          - Boolean - a cancellation flag (optional).
//
Procedure ReportError(MessageText, Cancel = False) Export
	
	Cancel = True;
	
	Common.MessageToUser(MessageText);
	
EndProcedure

// Gets the table of selective object registration from session parameters.
//
// Parameters:
//   No.
// 
// Returns:
//   Value table - a table of registration attributes for all metadata objects.
//
Function GetSelectiveObjectsRegistrationRulesSP() Export
	
	Return DataExchangeCached.GetSelectiveObjectsRegistrationRulesSP();
	
EndFunction

// Adds one record to the information register by the passed structure values.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used for creating and filling in 
//                                the record set.
//  RegisterName     - String - a name of information register to be supplied with a record.
// 
Procedure AddRecordToInformationRegister(RecordStructure, Val RegisterName, Import = False) Export
	
	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);
	
	// Adding the single record to the new record set.
	NewRecord = RecordSet.Add();
	
	// Filling record property values from the passed structure.
	FillPropertyValues(NewRecord, RecordStructure);
	
	RecordSet.DataExchange.Load = Import;
	
	// Writing the record set
	RecordSet.Write();
	
EndProcedure

// Updates a record in the information register by the passed structure values.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used to create a record manager and update the record.
//  RegisterName     - String - a name of information register supplied with a record to be updated.
// 
Procedure UpdateInformationRegisterRecord(RecordStructure, Val RegisterName) Export
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	// Creating a register record manager.
	RecordManager = InformationRegisters[RegisterName].CreateRecordManager();
	
	// Setting register dimension filters.
	For Each Dimension In RegisterMetadata.Dimensions Do
		
		// If dimension filter value is specified in a structure, the filter is set.
		If RecordStructure.Property(Dimension.Name) Then
			
			RecordManager[Dimension.Name] = RecordStructure[Dimension.Name];
			
		EndIf;
		
	EndDo;
	
	// Reading the record from the infobase.
	RecordManager.Read();
	
	// Filling record property values from the passed structure.
	FillPropertyValues(RecordManager, RecordStructure);
	
	// Writing the record manager
	RecordManager.Write();
	
EndProcedure

// Deletes a record set for the passed structure values from the register.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values are used to delete a record set.
//  RegisterName     - String - a name of information register supplied with the record set to be deleted.
// 
Procedure DeleteRecordSetFromInformationRegister(RecordStructure, RegisterName, Import = False) Export
	
	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);
	
	RecordSet.DataExchange.Load = Import;
	
	// Writing the record set
	RecordSet.Write();
	
EndProcedure

// Imports data exchange rules (ORR or OCR) into the infobase.
// 
Procedure ImportDataExchangeRules(Cancel,
										Val ExchangePlanName,
										Val RulesKind,
										Val RulesTemplateName,
										Val CorrespondentRulesTemplateName = "")
	
	RecordStructure = New Structure;
	RecordStructure.Insert("ExchangePlanName",  ExchangePlanName);
	RecordStructure.Insert("RulesKind",       RulesKind);
	If Not IsBlankString(CorrespondentRulesTemplateName) Then
		RecordStructure.Insert("CorrespondentRuleTemplateName", CorrespondentRulesTemplateName);
	EndIf;
	RecordStructure.Insert("RulesTemplateName", RulesTemplateName);
	RecordStructure.Insert("RulesSource",  Enums.DataExchangeRulesSources.ConfigurationTemplate);
	RecordStructure.Insert("UseSelectiveObjectRegistrationFilter", True);
	
	// Creating a register record set.
	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, "DataExchangeRules");
	
	// Adding the single record to the new record set.
	NewRecord = RecordSet.Add();
	
	// Filling record properties with values from the structure.
	FillPropertyValues(NewRecord, RecordStructure);
	
	// Importing data exchange rules into the infobase.
	InformationRegisters.DataExchangeRules.ImportRules(Cancel, RecordSet[0]);
	
	If Not Cancel Then
		RecordSet.Write();
	EndIf;
	
EndProcedure

Procedure UpdateStandardDataExchangeRuleVersion(LoadedFromFileExchangeRules, RegistrationRulesImportedFromFile)
	
	Cancel = False;
	QueryText = "";
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		If Not IsBlankString(QueryText) Then
			QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
		EndIf;
		
		QueryText = QueryText + StringFunctionsClientServer.SubstituteParametersToString("SELECT
			|	COUNT (%1.Ref) AS Count,
			|	""%1"" AS ExchangePlanName
			|FROM
			|	ExchangePlan.%1 AS %1", ExchangePlanName);
			
	EndDo;
	If IsBlankString(QueryText) Then
		Return;
	EndIf;
	Query = New Query(QueryText);
	Result = Query.Execute().Unload();
	
	RulesUpdateExecuted = False;
	For Each ExchangePlanRecord In Result Do
		
		If ExchangePlanRecord.Count <= 1 
			AND Not Common.DataSeparationEnabled() Then // ThisNode only
			Continue;
		EndIf;
		
		ExchangePlanName = ExchangePlanRecord.ExchangePlanName;
		
		If LoadedFromFileExchangeRules.Find(ExchangePlanName) = Undefined
			AND DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules")
			AND DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "CorrespondentExchangeRules") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполняется обновление правил конвертации данных для плана обмена %1'; en = 'Updating data conversion rules for exchange plan %1.'; pl = 'Aktualizacja reguł konwersji danych dla planu wymiany %1';de = 'Aktualisieren der Datenkonvertierungsregeln für den Austauschplan %1';ro = 'Actualizarea regulilor de conversie a datelor pentru planul de schimb %1';tr = 'Değişim planı için veri dönüştürme kurallarının güncellenmesi%1'; es_ES = 'Actualizando las reglas de conversión de datos para el plan de intercambio %1'"), ExchangePlanName);
			WriteLogEvent(EventLogMessageTextDataExchange(),
				EventLogLevel.Information,,, MessageText);
			
			ImportDataExchangeRules(Cancel, ExchangePlanName, Enums.DataExchangeRulesTypes.ObjectConversionRules,
				"ExchangeRules", "CorrespondentExchangeRules");
				
			RulesUpdateExecuted = True;
			
		EndIf;
		
		If RegistrationRulesImportedFromFile.Find(ExchangePlanName) = Undefined
			AND DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "RecordRules") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполняется обновление правил регистрации данных для плана обмена %1'; en = 'Updating data registration rules for exchange plan %1.'; pl = 'Aktualizacja reguł rejestracji danych dla planu wymiany %1';de = 'Aktualisierung der Datenregistrierungsregeln für den Austauschplan %1';ro = 'Actualizarea regulilor de înregistrare a datelor pentru planul de schimb %1';tr = 'Değişim planı için veri kayıt kurallarının güncellenmesi%1'; es_ES = 'Actualizando las reglas de registro de datos para el plan de intercambio %1'"), ExchangePlanName);
			WriteLogEvent(EventLogMessageTextDataExchange(),
				EventLogLevel.Information,,, MessageText);
				
			ImportDataExchangeRules(Cancel, ExchangePlanName, Enums.DataExchangeRulesTypes.ObjectsRegistrationRules, "RecordRules");
			
			RulesUpdateExecuted = True;
			
		EndIf;
		
	EndDo;
	
	If Cancel Then
		Raise NStr("ru = 'При обновлении правил обмена данными возникли ошибки (см. Журнал регистрации).'; en = 'Errors occurred while updating data exchange rules (see the event log).'; pl = 'Wystąpiły błędy podczas aktualizacji reguł wymiany danych (zob. dziennik zdarzeń).';de = 'Bei der Aktualisierung der Datenaustauschregeln sind Fehler aufgetreten (siehe Ereignisprotokoll).';ro = 'Au apărut erori în timpul actualizării regulilor de schimb de date (vezi Registrul logare).';tr = 'Veri değişimi kurallarının güncellenmesi sırasında hatalar oluştu (olay günlüğüne bakın).'; es_ES = 'Errores ocurridos durante la actualización de las reglas del intercambio de datos (ver el registro de eventos).'");
	EndIf;
	
	If RulesUpdateExecuted Then
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	EndIf;
	
EndProcedure

// Creates an information register record set by the passed structure values. Adds a single record to the set.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used for creating and filling in 
//                                the record set.
//  RegisterName     - String - an information register name.
// 
Function CreateInformationRegisterRecordSet(RecordStructure, RegisterName)
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	// Creating register record set.
	RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
	
	// Setting register dimension filters.
	For Each Dimension In RegisterMetadata.Dimensions Do
		
		// If dimension filter value is specified in a structure, the filter is set.
		If RecordStructure.Property(Dimension.Name) Then
			
			RecordSet.Filter[Dimension.Name].Set(RecordStructure[Dimension.Name]);
			
		EndIf;
		
	EndDo;
	
	Return RecordSet;
EndFunction

// Receives a picture index to display it in the object mapping statistics table.
//
Function StatisticsTablePictureIndex(Val UnmappedObjectCount, Val DataImportedSuccessfully) Export
	
	Return ?(UnmappedObjectCount = 0, ?(DataImportedSuccessfully = True, 2, 0), 1);
	
EndFunction

// Checks whether the exchange message size exceed the maximum allowed size.
//
//  Returns:
//   True if the file size exceeds the maximum allowed size. Otherwise, False.
//
Function ExchangeMessageSizeExceedsAllowed(Val FileName, Val MaxMessageSize) Export
	
	// Function return value.
	Result = False;
	
	File = New File(FileName);
	
	If File.Exist() AND File.IsFile() Then
		
		If MaxMessageSize <> 0 Then
			
			PackageSize = Round(File.Size() / 1024, 0, RoundMode.Round15as20);
			
			If PackageSize > MaxMessageSize Then
				
				MessageString = NStr("ru = 'Размер исходящего пакета составил %1 Кбайт, что превышает допустимое ограничение %2 Кбайт.'; en = 'The outgoing package size (%1 KB) exceeds the limit (%2 KB).'; pl = 'Rozmiar wychodzącego zestawu wyniósł %1 KB, co przekracza dopuszczalne ograniczenie %2 KB.';de = 'Die Größe des ausgehenden Pakets ist %1 KB und überschreitet das zulässige %2 KB-Limit.';ro = 'Dimensiunea pachetului de ieșire este %1 KB și depășește limita admisă de %2 KB.';tr = 'Giden paket boyutu %1KB''dir ve izin verilen %2KB sınırını aşıyor.'; es_ES = 'Tamaño del paquete saliente es %1 KB, y excede el límite permitido de %2 KB.'");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(PackageSize), String(MaxMessageSize));
				ReportError(MessageString, Result);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InitialDataExportFlagIsSet(InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.CommonInfobasesNodesSettings.InitialDataExportFlagIsSet(InfobaseNode);
	
EndFunction

Procedure RegisterOnlyCatalogsForInitialExport(Val InfobaseNode) Export
	
	RegisterDataForInitialExport(InfobaseNode, ExchangePlanCatalogs(InfobaseNode));
	
EndProcedure

Procedure RegisterCatalogsOnlyForInitialBackgroundExport(ProcedureParameters, StorageAddress) Export
	
	RegisterOnlyCatalogsForInitialExport(ProcedureParameters["InfobaseNode"]);
	
EndProcedure

Procedure RegisterAllDataExceptCatalogsForInitialExport(Val InfobaseNode) Export
	
	RegisterDataForInitialExport(InfobaseNode, AllExchangePlanDataExceptCatalogs(InfobaseNode));
	
EndProcedure

Procedure RegisterAllDataExceptCatalogsForInitialBackgroundExport(ProcedureParameters, StorageAddress) Export
	
	RegisterAllDataExceptCatalogsForInitialExport(ProcedureParameters["InfobaseNode"]);
	
EndProcedure

Procedure RegisterDataForInitialExport(InfobaseNode, Data = Undefined, DeleteMapsRegistration = True) Export
	
	SetPrivilegedMode(True);
	
	// Updating cached object registration values.
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	StandardProcessing = True;
	
	DataExchangeOverridable.InitialDataExportChangesRegistration(InfobaseNode, StandardProcessing, Data);
	
	If StandardProcessing Then
		
		If TypeOf(Data) = Type("Array") Then
			
			For Each MetadataObject In Data Do
				
				ExchangePlans.RecordChanges(InfobaseNode, MetadataObject);
				
			EndDo;
			
		Else
			
			ExchangePlans.RecordChanges(InfobaseNode, Data);
			
		EndIf;
		
	EndIf;
	
	If DataExchangeCached.ExchangePlanContainsObject(DataExchangeCached.GetExchangePlanName(InfobaseNode),
		Metadata.InformationRegisters.InfobaseObjectsMaps.FullName())
		AND DeleteMapsRegistration Then
		
		ExchangePlans.DeleteChangeRecords(InfobaseNode, Metadata.InformationRegisters.InfobaseObjectsMaps);
		
	EndIf;
	
	// Setting the initial data export flag for the node.
	InformationRegisters.CommonInfobasesNodesSettings.SetInitialDataExportFlag(InfobaseNode);
	
EndProcedure

// Imports the exchange message that contains configuration changes before infobase update.
// 
//
Procedure ImportMessageBeforeInfobaseUpdate()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		InfobaseNode = MasterNode();
		
		If InfobaseNode <> Undefined Then
			
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
			SetPrivilegedMode(False);
			
			Try
				// Updating object registration rules before importing data.
				UpdateDataExchangeRules();
				
				TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
				
				Cancel = False;
				
				ExchangeParameters = ExchangeParameters();
				ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
				ExchangeParameters.ExecuteImport = True;
				ExchangeParameters.ExecuteExport = False;
				ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
				
				// Repeat mode must be enabled in the following cases.
				// Case 1. A new configuration version is received and therefore infobase update is required.
				// If Cancel = True, the procedure execution must be stopped, otherwise data duplicates can be created,
				// - If Cancel = False, an error might occur during the infobase update and you might need to reimport the message.
				// Case 2. Received configuration version is equal to the current infobase configuration version and no updating required.
				// If Cancel = True, an error might occur during the infobase startup, possible cause is that 
				//   predefined items are not imported.
				// - If Cancel = False, it is possible to continue import because export can be performed later. If 
				//   export cannot be succeeded, it is possible to receive a new message to import.
				
				If Cancel OR InfobaseUpdate.InfobaseUpdateRequired() Then
					EnableDataExchangeMessageImportRecurrenceBeforeStart();
				EndIf;
				
				If Cancel Then
					Raise NStr("ru = 'Получение данных из главного узла завершилось с ошибками.'; en = 'Receiving data from the master node completed with errors.'; pl = 'Odbiór danych z głównego węzła został zakończony z błędami.';de = 'Der Empfang von Daten vom Hauptknoten wird mit Fehlern abgeschlossen.';ro = 'Primirea datelor din nodul principal este finalizată cu erori.';tr = 'Ana üniteden veri alımı hatalarla tamamlandı.'; es_ES = 'Recepción de los datos del nodo principal se ha finalizado con errores.'");
				EndIf;
			Except
				SetPrivilegedMode(True);
				SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
				SetPrivilegedMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets to False the import repeat flag. It is called if errors occurred during message import or infobase updating.
Procedure DisableDataExchangeMessageImportRepeatBeforeStart() Export
	
	SetPrivilegedMode(True);
	
	If Constants.RetryDataExchangeMessageImportBeforeStart.Get() Then
		Constants.RetryDataExchangeMessageImportBeforeStart.Set(False);
	EndIf;
	
EndProcedure

// Performs import and export of an exchange message that contains configuration changes but 
// configuration update is not required.
// 
//
Procedure ExecuteSynchronizationWhenInfobaseUpdateAbsent(
		OnClientStart, Restart)
	
	If Not LoadDataExchangeMessage() Then
		// If the message import is canceled and the metadata configuration version is not increased, you 
		// have to disable the import repetition.
		DisableDataExchangeMessageImportRepeatBeforeStart();
		Return;
	EndIf;
		
	If ConfigurationChanged() Then
		// Configuration changes are imported but are not applied
		// Exchange message cannot be imported
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		ImportMessageBeforeInfobaseUpdate();
		CommitTransaction();
	Except
		If ConfigurationChanged() Then
			If Not DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
				"MessageReceivedFromCache") Then
				// Updating configuration from version where cached exchange messages are not used.
				//  Perhaps, imported message contains configuration changes.
				//  Cannot determine whether the return to the database configuration was made.
				//  You have to commit the transaction and continue the start without exchange message export.
				// 
				CommitTransaction();
				Return;
			Else
				// Configuration changes are received. It means that return to database configuration was performed.
				// 
				// The data import must be cancelled.
				RollbackTransaction();
				SetPrivilegedMode(True);
				Constants.LoadDataExchangeMessage.Set(False);
				ClearDataExchangeMessageFromMasterNode();
				SetPrivilegedMode(False);
				WriteDataReceiveEvent(MasterNode(),
					NStr("ru = 'Обнаружен возврат к конфигурации базы данных.
					           |Синхронизация отменена.'; 
					           |en = 'Rollback to the database configuration is detected.
					           |The synchronization is canceled.'; 
					           |pl = 'Wykryto powrót do konfiguracji bazy danych.
					           | Synchronizacja została anulowana.';
					           |de = 'Zurück zur Datenbankkonfiguration gefunden. 
					           |Die Synchronisierung wird abgebrochen.';
					           |ro = 'Este depistată revenirea la configurația bazei de date.
					           |Sincronizare revocată.';
					           |tr = 'Veri tabanı konfigürasyonuna geri dönüş bulundu. 
					           |Senkronizasyon iptal edildi.'; 
					           |es_ES = 'Vuelta a la configuración de la base de datos encontrada.
					           |Sincronización se ha cancelado.'"));
				Return;
			EndIf;
		EndIf;
		// If the return to the database configuration is executed, but Designer is not closed.
		//  It means that the message is not imported.
		// After you switch to the repeat mode, you can click 
		// "Do not synchronize and continue", and after that return to the database configuration will be 
		// completed.
		CommitTransaction();
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		If OnClientStart Then
			Restart = True;
			Return;
		EndIf;
		Raise;
	EndTry;
	
	ExportMessageAfterInfobaseUpdate();
	
EndProcedure

Function UniqueExchangeMessageFileName(Extension = "xml") Export
	
	Result = "Message{GUID}." + Extension;
	
	Result = StrReplace(Result, "GUID", String(New UUID));
	
	Return Result;
EndFunction

Function IsSubordinateDIBNode() Export
	
	Return MasterNode() <> Undefined;
	
EndFunction

// Returns the current infobase master node if the distributed infobase is created based on the 
// exchange plan that is supported in the SSL data exchange subsystem.
//
// Returns:
//  ExchangePlanRef.<Exchange plan name>, Undefined - this method returns Undefined in the following 
//   cases: - the current infobase is not a DIB node, - the master node is not defined (this 
//   infobase is the master node), - distributed infobase is created based on an exchange plan that 
//   is not supported in the SSL data exchange subsystem.
//   
//
Function MasterNode() Export
	
	Result = ExchangePlans.MasterNode();
	
	If Result <> Undefined Then
		
		If Not DataExchangeCached.IsSSLDataExchangeNode(Result) Then
			
			Result = Undefined;
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

// Returns an array of version numbers supported by correspondent API for the DataExchange subsystem.
// 
// Parameters:
//   ExternalConnection - a COM connection object that is used for working with the correspondent.
//
// Returns:
//   Array of version numbers that are supported by correspondent API.
//
Function InterfaceVersionsThroughExternalConnection(ExternalConnection) Export
	
	Return Common.GetInterfaceVersionsViaExternalConnection(ExternalConnection, "DataExchange");
	
EndFunction

Function FirstErrorBriefPresentation(ErrorInformation)
	
	If ErrorInformation.Reason <> Undefined Then
		
		Return FirstErrorBriefPresentation(ErrorInformation.Reason);
		
	EndIf;
	
	Return BriefErrorDescription(ErrorInformation);
EndFunction

// Creates a temporary directory for exchange messages.
// Writes the directory name to the register for further deletion.
//
Function CreateTempExchangeMessagesDirectory(DirectoryID = Undefined) Export
	
	Result = CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), TempExchangeMessagesDirectoryName());
	
	CreateDirectory(Result);
	
	If Not Common.FileInfobase() Then
		
		SetPrivilegedMode(True);
		
		DirectoryID = PutFileInStorage(Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function DataExchangeOption(Val Correspondent) Export
	
	Result = "Synchronization";
	
	If DataExchangeCached.IsDistributedInfobaseNode(Correspondent) Then
		Return Result;
	EndIf;
	
	AttributesNames = Common.AttributeNamesByType(Correspondent, Type("EnumRef.ExchangeObjectExportModes"));
	
	AttributesValues = Common.ObjectAttributesValues(Correspondent, AttributesNames);
	
	For Each Attribute In AttributesValues Do
			
		If Attribute.Value = Enums.ExchangeObjectExportModes.ManualExport
			Or Attribute.Value = Enums.ExchangeObjectExportModes.DoNotExport Then
			
			Result = "ReceiveAndSend";
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ImportObjectContext(Val Context, Val Object) Export
	
	For Each Attribute In Object.Metadata().Attributes Do
		
		If Context.Property(Attribute.Name) Then
			
			Object[Attribute.Name] = Context[Attribute.Name];
			
		EndIf;
		
	EndDo;
	
	For Each TabularSection In Object.Metadata().TabularSections Do
		
		If Context.Property(TabularSection.Name) Then
			
			Object[TabularSection.Name].Load(Context[TabularSection.Name]);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetObjectContext(Val Object) Export
	
	Result = New Structure;
	
	For Each Attribute In Object.Metadata().Attributes Do
		
		Result.Insert(Attribute.Name, Object[Attribute.Name]);
		
	EndDo;
	
	For Each TabularSection In Object.Metadata().TabularSections Do
		
		Result.Insert(TabularSection.Name, Object[TabularSection.Name].Unload());
		
	EndDo;
	
	Return Result;
EndFunction

Procedure ExpandValueTree(Table, Tree)
	
	For Each TreeRow In Tree Do
		
		FillPropertyValues(Table.Add(), TreeRow);
		
		If TreeRow.Rows.Count() > 0 Then
			
			ExpandValueTree(Table, TreeRow.Rows);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function DifferenceDaysCount(Val Date1, Val Date2)
	
	Return Int((BegOfDay(Date2) - BegOfDay(Date1)) / 86400);
	
EndFunction

Procedure FillValueTable(Destination, Val Source) Export
	Destination.Clear();
	
	If TypeOf(Source)=Type("ValueTable") Then
		SourceColumns = Source.Columns;
	Else
		TempTable = Source.Unload(New Array);
		SourceColumns = TempTable.Columns;
	EndIf;
	
	If TypeOf(Destination)=Type("ValueTable") Then
		DestinationColumns = Destination.Columns;
		DestinationColumns.Clear();
		For Each Column In SourceColumns Do
			FillPropertyValues(DestinationColumns.Add(), Column);
		EndDo;
	EndIf;
	
	For Each Row In Source Do
		FillPropertyValues(Destination.Add(), Row);
	EndDo;
EndProcedure

Function TableIntoStrucrureArray(Val ValueTable)
	Result = New Array;
	
	ColumnsNames = "";
	For Each Column In ValueTable.Columns Do
		ColumnsNames = ColumnsNames + "," + Column.Name;
	EndDo;
	ColumnsNames = Mid(ColumnsNames, 2);
	
	For Each Row In ValueTable Do
		StringStructure = New Structure(ColumnsNames);
		FillPropertyValues(StringStructure, Row);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
EndFunction

// Checking the corespondent versions for differences in the rules of the current and another program.
//
Function DifferentCorrespondentVersions(ExchangePlanName, EventLogMessageKey, VersionInCurrentApplication,
	VersionInOtherApplication, MessageText, ExternalConnectionParameters = Undefined) Export
	
	VersionInCurrentApplication = ?(ValueIsFilled(VersionInCurrentApplication), VersionInCurrentApplication, CorrespondentVersionInRules(ExchangePlanName));
	
	If ValueIsFilled(VersionInCurrentApplication) AND ValueIsFilled(VersionInOtherApplication)
		AND ExchangePlanSettingValue(ExchangePlanName, "WarnAboutExchangeRuleVersionMismatch") Then
		
		VersionInCurrentApplicationWithoutAssemblyNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(VersionInCurrentApplication);
		VersionInOtherApplicationWithoutAssemblyNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(VersionInOtherApplication);
		
		If VersionInCurrentApplicationWithoutAssemblyNumber <> VersionInOtherApplicationWithoutAssemblyNumber Then
			
			ExchangePlanSynonym = Metadata.ExchangePlans[ExchangePlanName].Synonym;
			
			MessageTemplate = NStr("ru = 'Синхронизация данных может быть выполнена некорректно, т.к. версия программы ""%1"" (%2) в правилах конвертации этой программы отличается от версии %3 в правилах конвертации в другой программе. Убедитесь, что загружены актуальные правила, подходящие для используемых версий обеих программ.'; en = 'The data synchronization might be performed incorrectly because %1 version %2 is different from version %3 specified in the conversion rules in the other application. Ensure that rules relevant for both application versions are loaded.'; pl = 'Dane mogą być nieprawidłowo synchronizowane, ponieważ wersja aplikacji ""%1"" (%2) różni się od %3 wersji określonej w regułach konwersji innej aplikacji. Upewnij się, że zaimportowałeś reguły odpowiednie dla obu aplikacji.';de = 'Daten können falsch synchronisiert werden, da sich die Version der Anwendung ""%1"" (%2) von der Version%3, die in den Konvertierungsregeln einer anderen Anwendung angegebenen ist, unterscheidet. Stellen Sie sicher, dass Sie die für beide Anwendungen relevanten Regeln importiert haben.';ro = 'Datele pot fi sincronizate incorect deoarece versiunea aplicației ""%1"" (%2) este diferită de versiunea %3 specificată în regulile de conversie ale unei alte aplicații. Asigurați-vă că ați importat regulile relevante pentru ambele aplicații.';tr = 'Veriler, ""%1""  (%2) uygulamasının sürümü, başka bir uygulamanın dönüştürme kurallarında %3 belirtilen sürümden farklı olduğu için yanlış senkronize edilebilir. Her iki uygulama ile ilgili kuralları içe aktardığınızdan emin olun.'; es_ES = 'Datos pueden estar sincronizados de forma incorrecta, porque la versión de la aplicación ""%1"" (%2) es diferente de la versión %3 especificada en las reglas de conversión de otra aplicación. Asegurarse de que usted haya importado las reglas relevantes para ambas aplicaciones.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ExchangePlanSynonym, VersionInCurrentApplicationWithoutAssemblyNumber, VersionInOtherApplicationWithoutAssemblyNumber);
			
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,,, MessageText);
			
			If ExternalConnectionParameters <> Undefined
				AND CommonClientServer.CompareVersions("2.2.3.18", ExternalConnectionParameters.SSLVersionByExternalConnection) <= 0
				AND ExternalConnectionParameters.ExternalConnection.DataExchangeExternalConnection.WarnAboutExchangeRuleVersionMismatch(ExchangePlanName) Then
				
				ExchangePlanSynonymInOtherApplication = ExternalConnectionParameters.InfobaseNode.Metadata().Synonym;
				ExternalConnectionMessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
					ExchangePlanSynonymInOtherApplication, VersionInOtherApplicationWithoutAssemblyNumber, VersionInCurrentApplicationWithoutAssemblyNumber);
				
				ExternalConnectionParameters.ExternalConnection.EventLogRecord(ExternalConnectionParameters.EventLogMessageKey,
					ExternalConnectionParameters.ExternalConnection.EventLogLevel.Warning,,, ExternalConnectionMessageText);
				
			EndIf;
			
			If SessionParameters.VersionMismatchErrorOnGetData.CheckVersionDifference Then
				
				CheckStructure = New Structure(SessionParameters.VersionMismatchErrorOnGetData);
				CheckStructure.HasError = True;
				CheckStructure.ErrorText = MessageText;
				CheckStructure.CheckVersionDifference = False;
				SessionParameters.VersionMismatchErrorOnGetData = New FixedStructure(CheckStructure);
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function InitializeVersionDifferenceCheckParameters(CheckVersionDifference) Export
	
	SetPrivilegedMode(True);
	
	CheckStructure = New Structure(SessionParameters.VersionMismatchErrorOnGetData);
	CheckStructure.CheckVersionDifference = CheckVersionDifference;
	CheckStructure.HasError = False;
	SessionParameters.VersionMismatchErrorOnGetData = New FixedStructure(CheckStructure);
	
	Return SessionParameters.VersionMismatchErrorOnGetData;
	
EndFunction

Function VersionMismatchErrorOnGetData() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.VersionMismatchErrorOnGetData;
	
EndFunction

Function CorrespondentVersionInRules(ExchangePlanName)
	
	Query = New Query;
	Query.Text = "SELECT
	|	DataExchangeRules.CorrespondentRulesAreRead,
	|	DataExchangeRules.RulesKind
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesAreImported = TRUE
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectConversionRules)";
	
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		RulesStructure = Selection.CorrespondentRulesAreRead.Get().Conversion;
		CorrespondentVersion = Undefined;
		RulesStructure.Property("SourceConfigurationVersion", CorrespondentVersion);
		
		Return CorrespondentVersion;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns True if update is required for the subordinate DIB node infobase configuration.
//  Always False for the master node.
// 
// Copy of the Common.SubordinateDIBNodeConfigurationUpdateRequired function.
// 
Function UpdateInstallationRequired() Export
	
	Return IsSubordinateDIBNode() AND ConfigurationChanged();
	
EndFunction

// Returns an extended object presentation.
//
Function ObjectPresentation(ParameterObject) Export
	
	If ParameterObject = Undefined Then
		Return "";
	EndIf;
	ObjectMetadata = ?(TypeOf(ParameterObject) = Type("String"), Metadata.FindByFullName(ParameterObject), ParameterObject);
	
	// There can be no presentation attributes, iterating through structure.
	Presentation = New Structure("ExtendedObjectPresentation, ObjectPresentation");
	FillPropertyValues(Presentation, ObjectMetadata);
	If Not IsBlankString(Presentation.ExtendedObjectPresentation) Then
		Return Presentation.ExtendedObjectPresentation;
	ElsIf Not IsBlankString(Presentation.ObjectPresentation) Then
		Return Presentation.ObjectPresentation;
	EndIf;
	
	Return ObjectMetadata.Presentation();
EndFunction

// Returns an extended object list presentation.
//
Function ObjectListPresentation(ParameterObject) Export
	
	If ParameterObject = Undefined Then
		Return "";
	EndIf;
	ObjectMetadata = ?(TypeOf(ParameterObject) = Type("String"), Metadata.FindByFullName(ParameterObject), ParameterObject);
	
	// There can be no presentation attributes, iterating through structure.
	Presentation = New Structure("ExtendedListPresentation, ListPresentation");
	FillPropertyValues(Presentation, ObjectMetadata);
	If Not IsBlankString(Presentation.ExtendedListPresentation) Then
		Return Presentation.ExtendedListPresentation;
	ElsIf Not IsBlankString(Presentation.ListPresentation) Then
		Return Presentation.ListPresentation;
	EndIf;
	
	Return ObjectMetadata.Presentation();
EndFunction

// Returns the flag showing whether export is available for the specified reference on the node.
//
//  Parameters:
//      ExchangeNode - ExchangePlanRef - an exchange plan node to check whether the data export is available.
//      Ref                  - Arbitrary     - an object to be checked.
//      AdditionalProperties - Structure         - additional properties passed in the object.
//
// Returns:
//  Boolean - an enabled flag
//
Function RefExportAllowed(ExchangeNode, Ref, AdditionalProperties = Undefined) Export
	
	If Ref.IsEmpty() Then
		Return False;
	EndIf;
	
	RegistrationObject = Ref.GetObject();
	If RegistrationObject = Undefined Then
		// Object is deleted. It is always possible.
		Return True;
	EndIf;
	
	If AdditionalProperties <> Undefined Then
		AttributesStructure = New Structure("AdditionalProperties");
		FillPropertyValues(AttributesStructure, RegistrationObject);
		AdditionalObjectProperties = AttributesStructure.AdditionalProperties;
		
		If TypeOf(AdditionalObjectProperties) = Type("Structure") Then
			For Each KeyValue In AdditionalProperties Do
				AdditionalObjectProperties.Insert(KeyValue.Key, KeyValue.Value);
			EndDo;
		EndIf;
	EndIf;
	
	// Checking whether the data export is available.
	Sending = DataItemSend.Auto;
	DataExchangeEvents.OnSendDataToRecipient(RegistrationObject, Sending, , ExchangeNode);
	Return Sending = DataItemSend.Auto;
EndFunction

// Returns the flag showing whether manual export is available for the specified reference on the node.
//
//  Parameters:
//      ExchangeNode - ExchangePlanRef - an exchange plan node to check whether the data export is available.
//      Ref                  - Arbitrary     - an object to be checked.
//
// Returns:
//  Boolean - an enabled flag
//
Function RefExportFromInteractiveAdditionAllowed(ExchangeNode, Ref) Export
	
	// In the case of a call from the data composition schema, when the add-on to importing mechanism is 
	// running, the safe mode is enabled, which must be disabled when executing this function.
	SetSafeModeDisabled(True);
	
	AdditionalProperties = New Structure("InteractiveExportAddition", True);
	Return RefExportAllowed(ExchangeNode, Ref, AdditionalProperties);
	
EndFunction

// Wrappers for background procedures of changing export interactively.
//
Procedure InteractiveExportModification_GenerateUserTableDocument(Parameters, ResultAddress) Export
	
	ReportObject        = InteractiveExportModification_ObjectBySettings(Parameters.DataProcessorStructure);
	ExecutionResult = ReportObject.GenerateUserSpreadsheetDocument(Parameters.FullMetadataName, Parameters.Presentation, Parameters.SimplifiedMode);
	PutToTempStorage(ExecutionResult, ResultAddress);
	
EndProcedure

Procedure InteractiveExportModification_GenerateValueTree(Parameters, ResultAddress) Export
	
	ReportObject = InteractiveExportModification_ObjectBySettings(Parameters.DataProcessorStructure);
	Result = ReportObject.GenerateValueTree();
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function InteractiveExportModification_ObjectBySettings(Val Settings)
	
	ReportObject = DataProcessors.InteractiveExportModification.Create();
	
	FillPropertyValues(ReportObject, Settings, , "AllDocumentsFilterComposer");
	
	// Setting up the composer fractionally.
	Data = ReportObject.CommonFilterSettingsComposer();
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
	Composer.LoadSettings(Data.Settings);
	
	ReportObject.AllDocumentsFilterComposer = Composer;
	
	FilterItems = ReportObject.AllDocumentsFilterComposer.Settings.Filter.Items;
	FilterItems.Clear();
	ReportObject.AddDataCompositionFilterValues(
		FilterItems, Settings.AllDocumentsFilterComposerSettings.Filter.Items);
	
	Return ReportObject;
EndFunction

// Returns the role list of the profile of the "Data synchronization with other applications" access groups.
// 
Function DataSynchronizationAccessProfileWithOtherApplicationsRoles()
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		Return "DataSynchronizationInProgress, RemoteAccessCore, ReadObjectVersionInfo";
	Else
		Return "DataSynchronizationInProgress, RemoteAccessCore";
	EndIf;
	
EndFunction

// Gets the secure connection parameter.
//
Function SecureConnection(Path) Export
	
	Return ?(Lower(Left(Path, 4)) = "ftps", CommonClientServer.NewSecureConnection(), Undefined);
	
EndFunction

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoListSynchronizationWarnings(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("View", Metadata.InformationRegisters.DataExchangeResults)
		Or ModuleToDoListServer.UserTaskDisabled("WarningsOnSynchronization") Then
		Return;
	EndIf;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	If SSLExchangePlans.Count() > 0 Then
		DashboardTable = DataExchangeMonitorTable(SSLExchangePlans);
		
		UnresolvedIssuesCount = UnresolvedIssuesCount(
			DashboardTable.UnloadColumn("InfobaseNode"));
	Else
		UnresolvedIssuesCount = 0;
	EndIf;
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DataSynchronization.FullName());
	
	For Each Section In Sections Do
		
		NotificationAtSynchronizationID = "WarningsOnSynchronization" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = NotificationAtSynchronizationID;
		ToDoItem.HasToDoItems       = UnresolvedIssuesCount > 0;
		ToDoItem.Presentation  = NStr("ru = 'Предупреждения при синхронизации'; en = 'Synchronization warnings'; pl = 'Ostrzeżenia synchronizacji';de = 'Synchronisierungswarnungen';ro = 'Avertizări de sincronizare';tr = 'Senkronizasyon uyarıları'; es_ES = 'Avisos de sincronización'");
		ToDoItem.Count     = UnresolvedIssuesCount;
		ToDoItem.Form          = "InformationRegister.DataExchangeResults.Form.Form";
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoListUpdateRequired(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Administration", Metadata)
		Or ModuleToDoListServer.UserTaskDisabled("UpdateRequiredDataExchange") Then
		Return;
	EndIf;
	
	UpdateInstallationRequired = UpdateInstallationRequired();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DataSynchronization.FullName());
	
	For Each Section In Sections Do
		
		IDUpdateRequired = "UpdateRequiredDataExchange" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID  = IDUpdateRequired;
		ToDoItem.HasToDoItems       = UpdateInstallationRequired;
		ToDoItem.Important         = True;
		ToDoItem.Presentation  = NStr("ru = 'Обновить версию программы'; en = 'Update application version'; pl = 'Aktualizacja wersji programu';de = 'Aktualisieren Sie die Anwendungsversion';ro = 'Actualizați versiunea aplicației';tr = 'Uygulama sürümünü güncelle'; es_ES = 'Actualizar la versión de la aplicación'");
		If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
			ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
			FormParameters = New Structure("Exit, ConfigurationUpdateReceived", False, False);
			ToDoItem.Form      = ModuleSoftwareUpdate.InstallUpdatesFormName();
			ToDoItem.FormParameters = FormParameters;
		Else
			ToDoItem.Form      = "CommonForm.AdditionalDetails";
			ToDoItem.FormParameters = New Structure("Title,TemplateName",
				NStr("ru = 'Установка обновления'; en = 'Install update'; pl = 'Zainstaluj aktualizację';de = 'Installiere Update';ro = 'Instalarea actualizării';tr = 'Güncellemeyi yükle'; es_ES = 'Instalar la actualización'"), "ManualUpdateInstruction");
		EndIf;
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoListValidateCompatibilityWithCurrentVersion(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.InformationRegisters.DataExchangeRules)
		Or ModuleToDoListServer.UserTaskDisabled("ExchangeRules") Then
		Return;
	EndIf;
	
	// If in the command interface there is no section, which the information register belongs to, the user task is not added.
	Sections = ModuleToDoListServer.SectionsForObject("InformationRegister.DataExchangeRules");
	If Sections.Count() = 0 Then 
		Return;
	EndIf;
	
	OutputUserTask = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "ExchangePlans");
	If VersionChecked <> Undefined Then
		ArrayVersion  = StrSplit(Metadata.Version, ".");
		CurrentVersion = ArrayVersion[0] + ArrayVersion[1] + ArrayVersion[2];
		If VersionChecked = CurrentVersion Then
			OutputUserTask = False; // Additional reports and data processors were checked on the current version.
		EndIf;
	EndIf;
	
	ExchangePlansWithRulesFromFile = ExchangePlansWithRulesFromFile();
	
	For Each Section In Sections Do
		SectionID = "CheckCompatibilityWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		
		// Adding a to-do.
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = "ExchangeRules";
		ToDoItem.HasToDoItems      = OutputUserTask AND ExchangePlansWithRulesFromFile > 0;
		ToDoItem.Presentation = NStr("ru = 'Правила обмена'; en = 'Exchange rules'; pl = 'Reguły wymiany';de = 'Austausch-Regeln';ro = 'Reguli de schimb';tr = 'Değişim kuralları'; es_ES = 'Reglas de intercambio'");
		ToDoItem.Count    = ExchangePlansWithRulesFromFile;
		ToDoItem.Form         = "InformationRegister.DataExchangeRules.Form.DataSynchronizationCheck";
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

Function DataSynonymOfStatisticsTreeRow(TreeRow, SourceTypeString) 
	
	Synonym = TreeRow.Synonym;
	
	Filter = New Structure("FullName, Synonym", TreeRow.FullName, Synonym);
	Existing = TreeRow.Owner().Rows.FindRows(Filter, True);
	Count   = Existing.Count();
	If Count = 0 Or (Count = 1 AND Existing[0] = TreeRow) Then
		// There has been no such descirption in this tree.
		Return Synonym;
	EndIf;
	
	Synonym = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1 (%2)'; en = '%1 (%2)'; pl = '%1 (%2)';de = '%1 (%2)';ro = '%1 (%2)';tr = '%1 (%2)'; es_ES = '%1 (%2)'"),
		TreeRow.Synonym,
		DeleteClassNameFromObjectName(SourceTypeString));
	
	Return Synonym;
EndFunction

Function GetDocumentHasRegisterRecords(DocumentRef)
	QueryText = "";	
	// To exclude failure of documents to post by more than 256 tables.
	table_counter = 0;
	
	DocumentMetadata = DocumentRef.Metadata();
	
	If DocumentMetadata.RegisterRecords.Count() = 0 Then
		Return New ValueTable;
	EndIf;
	
	For Each RegisterRecord In DocumentMetadata.RegisterRecords Do
		// Receiving the names of the registers, for which there is at least one record, in the request.
		// Example:
		// SELECT First 1 AccumulationRegister.ProductsStock
		// FROM AccumulationRegisterProductsStock
		// WHERE Recorder = &Recorder.
		
		// Adjust register name to String(200), see below.
		QueryText = QueryText + "
		|" + ?(QueryText = "", "", "UNION ALL ") + "
		|SELECT TOP 1 CAST(""" + RegisterRecord.FullName() 
		+  """ AS String(200)) AS Name FROM " + RegisterRecord.FullName() 
		+ " WHERE Recorder = &Recorder";
		
		// If the request includes more than 256 tables, split it into two parts (exclude posting by 512 
		// registers).
		table_counter = table_counter + 1;
		If table_counter = 256 Then
			Break;
		EndIf;
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", DocumentRef);
	// On export, for the Name column set type by the longest string from the query. On the second pass 
	// of the table the new name might not fit so adjust it to string(200).
	// 
	QueryTable = Query.Execute().Unload();
	
	// If the tables number is not more than 256, return the table.
	If table_counter = DocumentMetadata.RegisterRecords.Count() Then
		Return QueryTable;			
	EndIf;
	
	// If the tables number is more than 256, make an additional request and supplement the table with rows.
	
	QueryText = "";
	For Each RegisterRecord In DocumentMetadata.RegisterRecords Do
		
		If table_counter > 0 Then
			table_counter = table_counter - 1;
			Continue;
		EndIf;
		
		QueryText = QueryText + "
		|" + ?(QueryText = "", "", "UNION ALL ") + "
		|SELECT TOP 1 """ + RegisterRecord.FullName() +  """ AS Name FROM " 
		+ RegisterRecord.FullName() + " WHERE Recorder = &Recorder";	
		
		
	EndDo;
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TableRow = QueryTable.Add();
		FillPropertyValues(TableRow, Selection);
	EndDo;
	
	Return QueryTable;
	
EndFunction

// Determines default settings for the exchange plan. Later, they can be changed in the exchange 
// plan manager module in the OnReceiveSettings() procedure.
// 
// Returns:
//   Structure - contains the following fields:
//      * ExchangeSettingsOptions                         - ValueTable - possible exchange plan settings.
//                                                                  Is used for creating preset 
//                                                                  templates with filled exchange plan settings
//      * GroupTypeForSettingsOptions - FormGroupType - a group type option for displaying in the 
//                                                                  tree of creation commands for settings option exchange.
//      * SourceConfigurationName                       - String - a source configuration name 
//                                                                  displayed to user.
//      * TargetConfigurationName - Structure - a list of IDs of correspondent configurations 
//                                                                  exchange with which is possible via this exchange plan.
//      * ExchangeFormatOptions - Map - a map of supported format versions and references to common 
//                                                                  modules with exchange implemented using format.
//                                                                  It is used for exchange via the universal format only.
//      * ExchangeFormat                                   - String - an XDTO package namespace, 
//                                                                  which contains the universal format without the format version specified.
//                                                                  It is used for exchange via the universal format only.
//      * ExchangePlanUsedInSaaS           - Boolean - indicates whether the exchange plan is used 
//                                                                  to organize exchange in SaaS.
//      * IsXDTOExchangePlan                              - Boolean - indicates whether this is a 
//                                                                  plan of exchange via the universal format.
//      * WarnAboutExchangeRulesVersionsMismatch - Boolean - indicates whether it is required to 
//                                                                  check versions for discrepancy in the conversion rules.
//                                                                  The checking is performed on 
//                                                                  rule set importing , on data sending, and on data receiving.
//      * ExchangePlanNameToMigrateToNewExchange          - String - if the property is set for an 
//                                                                  exchange plan, this exchange 
//                                                                  kind is not available for setup in the settings management workplaces.
//                                                                  Existing exchanges of this type 
//                                                                  will be still visible in the configured exchange list.
//                                                                  Getting an exchange message in a 
//                                                                  new format will initiate migration to a new exchange kind.
//      * ExchangePlanPurpose                          - String - an exchange plan purpose option.
//      * Algorithms                                      - Structure - a list of export procedures 
//                                                                  and functions declared in the 
//                                                                  exchange plan manager module and used by the data exchange subsystem.
//
Function DefaultExchangePlanSettings(ExchangePlanName)
	
	ExchangePlanPurpose = "SynchronizationWithAnotherApplication";
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
		ExchangePlanPurpose = "DIB";
	EndIf;
	
	ExchangeSettingsOptions = New ValueTable;
	ExchangeSettingsOptions.Columns.Add("SettingID",        New TypeDescription("String"));
	ExchangeSettingsOptions.Columns.Add("CorrespondentInSaaS",   New TypeDescription("Boolean"));
	ExchangeSettingsOptions.Columns.Add("CorrespondentInLocalMode", New TypeDescription("Boolean"));
	
	Algorithms = New Structure;
	Algorithms.Insert("OnGetExchangeSettingsOptions",          False);
	Algorithms.Insert("OnGetSettingOptionDetails",        False);
	
	Algorithms.Insert("DataTransferRestrictionsDetails",            False);
	Algorithms.Insert("DefaultValuesDetails",                  False);
	
	Algorithms.Insert("InteractiveExportFilterPresentation",     False);
	Algorithms.Insert("SetUpInteractiveExport",               False);
	Algorithms.Insert("SetUpInteractiveExportSaaS", False);
	
	Algorithms.Insert("DataTransferLimitsCheckHandler",  False);
	Algorithms.Insert("DefaultValuesCheckHandler",        False);
	Algorithms.Insert("AccountingSettingsCheckHandler",            False);
	
	Algorithms.Insert("OnConnectToCorrespondent",                False);
	Algorithms.Insert("OnGetSenderData",                False);
	Algorithms.Insert("OnSendSenderData",                 False);
	
	Algorithms.Insert("OnSaveDataSynchronizationSettings",     False);
	
	Algorithms.Insert("OnDefineSupportedFormatObjects",  False);
	Algorithms.Insert("OnDefineFormatObjectsSupportedByCorrespondent", False);
	
	Algorithms.Insert("BeforeDataSynchronizationSetup",           False);
	
	Parameters = New Structure;
	Parameters.Insert("ExchangeSettingsOptions",                         ExchangeSettingsOptions);
	Parameters.Insert("SourceConfigurationName",                       "");
	Parameters.Insert("DestinationConfigurationName",                       New Structure);
	Parameters.Insert("ExchangeFormatVersions",                            New Map);
	Parameters.Insert("ExchangeFormat",                                   "");
	Parameters.Insert("ExchangePlanUsedInSaaS",           False);
	Parameters.Insert("IsXDTOExchangePlan",                              False);
	Parameters.Insert("ExchangePlanNameToMigrateToNewExchange",          "");
	Parameters.Insert("WarnAboutExchangeRuleVersionMismatch", True);
	Parameters.Insert("ExchangePlanPurpose",                          ExchangePlanPurpose);
	Parameters.Insert("Algorithms",                                      Algorithms);
	
	Return Parameters;
	
EndFunction

// Gets a configuration metadata tree with the specified filter by metadata objects.
//
// Parameters:
//   Filter - Structure - contains filter item values.
//						If this parameter is specified, the metadata tree will be retrieved according to the filter value:
//						Key - String - a metadata item property name.
//						Value - Array - an array of filter values.
//
// Example of initializing the Filter variable:
//
// Array = New Array;
// Array.Add("Constant.UseDataSynchronization");
// Array.Add("Catalog.Currencies");
// Array.Add("Catalog.Companies");
// Filter = New Structure;
// Filter.Insert("FullName", Array);
// 
// Returns:
//   ValuesTree - a configuration metadata tree.
//
Function ConfigurationMetadataTree(Filter = Undefined) Export
	
	UseFilter = (Filter <> Undefined);
	
	MetadataObjectsCollections = New ValueTable;
	MetadataObjectsCollections.Columns.Add("Name");
	MetadataObjectsCollections.Columns.Add("Synonym");
	MetadataObjectsCollections.Columns.Add("Picture");
	MetadataObjectsCollections.Columns.Add("ObjectPicture");
	
	NewMetadataObjectCollectionRow("Constants",               NStr("ru = 'Константы'; en = 'Constants'; pl = 'Stałe';de = 'Konstanten';ro = 'Constante';tr = 'Sabitler'; es_ES = 'Constantes'"),                 PictureLib.Constant,              PictureLib.Constant,                    MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("Catalogs",             NStr("ru = 'Справочники'; en = 'Catalogs'; pl = 'Katalogi';de = 'Stammdaten';ro = 'Cataloage';tr = 'Ana kayıtlar'; es_ES = 'Catálogos'"),               PictureLib.Catalog,             PictureLib.Catalog,                   MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("Documents",               NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'"),                 PictureLib.Document,               PictureLib.DocumentObject,               MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("ChartsOfCharacteristicTypes", NStr("ru = 'Планы видов характеристик'; en = 'Charts of characteristic types'; pl = 'Plany rodzajów charakterystyk';de = 'Diagramme von charakteristischen Typen';ro = 'Diagrame de tipuri caracteristice';tr = 'Karakteristik tiplerin çizelgeleri'; es_ES = 'Diagramas de los tipos de características'"), PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("ChartsOfAccounts",             NStr("ru = 'Планы счетов'; en = 'Charts of accounts'; pl = 'Plany kont';de = 'Kontenpläne';ro = 'Planurile conturilor';tr = 'Hesap çizelgeleri'; es_ES = 'Diagramas de las cuentas'"),              PictureLib.ChartOfAccounts,             PictureLib.ChartOfAccountsObject,             MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("ChartsOfCalculationTypes",       NStr("ru = 'Планы видов расчета'; en = 'Charts of calculation types'; pl = 'Plany typów obliczeń';de = 'Diagramme der Berechnungstypen';ro = 'Diagrame de tipuri de calcul';tr = 'Hesaplama türleri çizelgeleri'; es_ES = 'Diagramas de los tipos de cálculos'"),       PictureLib.ChartOfCalculationTypes,       PictureLib.ChartOfCalculationTypesObject,       MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("InformationRegisters",        NStr("ru = 'Регистры сведений'; en = 'Information registers'; pl = 'Rejestry informacji';de = 'Informationen registriert';ro = 'Registre de date';tr = 'Bilgi kayıtları'; es_ES = 'Registros de información'"),         PictureLib.InformationRegister,        PictureLib.InformationRegister,              MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("AccumulationRegisters",      NStr("ru = 'Регистры накопления'; en = 'Accumulation registers'; pl = 'Rejestry akumulacji';de = 'Akkumulationsregister';ro = 'Registre de acumulare';tr = 'Birikeçler'; es_ES = 'Registros de acumulación'"),       PictureLib.AccumulationRegister,      PictureLib.AccumulationRegister,            MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("AccountingRegisters",     NStr("ru = 'Регистры бухгалтерии'; en = 'Accounting registers'; pl = 'Rejestry księgowe';de = 'Buchhaltungsregister';ro = 'Registre contabile';tr = 'Muhasebe kayıtları'; es_ES = 'Registros de contabilidad'"),      PictureLib.AccountingRegister,     PictureLib.AccountingRegister,           MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("CalculationRegisters",         NStr("ru = 'Регистры расчета'; en = 'Calculation registers'; pl = 'Rejestry obliczeń';de = 'Berechnungsregister';ro = 'Registre de calcul';tr = 'Hesaplama kayıtları'; es_ES = 'Registros de cálculos'"),          PictureLib.CalculationRegister,         PictureLib.CalculationRegister,               MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("BusinessProcesses",          NStr("ru = 'Бизнес-процессы'; en = 'Business processes'; pl = 'Procesy biznesowe';de = 'Geschäftsprozesse';ro = 'Procesele de afaceri';tr = 'İş süreçleri'; es_ES = 'Procesos de negocio'"),           PictureLib.BusinessProcess,          PictureLib.BusinessProcessObject,          MetadataObjectsCollections);
	NewMetadataObjectCollectionRow("Tasks",                  NStr("ru = 'Задачи'; en = 'Tasks'; pl = 'Zadania';de = 'Aufgaben';ro = 'Sarcinile';tr = 'Görevler'; es_ES = 'Tareas'"),                    PictureLib.Task,                 PictureLib.TaskObject,                 MetadataObjectsCollections);
	
	// Function return value.
	MetadataTree = New ValueTree;
	MetadataTree.Columns.Add("Name");
	MetadataTree.Columns.Add("FullName");
	MetadataTree.Columns.Add("Synonym");
	MetadataTree.Columns.Add("Picture");
	
	For Each CollectionRow In MetadataObjectsCollections Do
		
		TreeRow = MetadataTree.Rows.Add();
		FillPropertyValues(TreeRow, CollectionRow);
		For Each MetadataObject In Metadata[CollectionRow.Name] Do
			
			If UseFilter Then
				
				ObjectPassedFilter = True;
				For Each FilterItem In Filter Do
					
					Value = ?(Upper(FilterItem.Key) = Upper("FullName"), MetadataObject.FullName(), MetadataObject[FilterItem.Key]);
					If FilterItem.Value.Find(Value) = Undefined Then
						ObjectPassedFilter = False;
						Break;
					EndIf;
					
				EndDo;
				
				If Not ObjectPassedFilter Then
					Continue;
				EndIf;
				
			EndIf;
			
			MOTreeRow = TreeRow.Rows.Add();
			MOTreeRow.Name       = MetadataObject.Name;
			MOTreeRow.FullName = MetadataObject.FullName();
			MOTreeRow.Synonym   = MetadataObject.Synonym;
			MOTreeRow.Picture  = CollectionRow.ObjectPicture;
			
		EndDo;
		
	EndDo;
	
	// Deleting rows that have no subordinate items.
	If UseFilter Then
		
		// Using reverse value tree iteration order.
		CollectionItemCount = MetadataTree.Rows.Count();
		
		For ReverseIndex = 1 To CollectionItemCount Do
			
			CurrentIndex = CollectionItemCount - ReverseIndex;
			TreeRow = MetadataTree.Rows[CurrentIndex];
			If TreeRow.Rows.Count() = 0 Then
				MetadataTree.Rows.Delete(CurrentIndex);
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return MetadataTree;
	
EndFunction

Procedure NewMetadataObjectCollectionRow(Name, Synonym, Picture, ObjectPicture, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name               = Name;
	NewRow.Synonym           = Synonym;
	NewRow.Picture          = Picture;
	NewRow.ObjectPicture   = ObjectPicture;
	
EndProcedure

// Determines default settings for the exchange setting option that can later be overridden in the 
// exchange plan manager module in the OnReceiveSettingOptionsDetails() procedure.
// Parameters:
//   ExchangePlanName - String - contains an exchange plan name.
// 
// Returns:
//   Structure - contains the following fields:
//      * Filters                                                - Structure - filters on the 
//                                                                         exchange plan node to be filled with default values.
//      * DefaultValues                                   - Structure - default values on the exchange plan node.
//      * CorrespondentFilters                                  - Structure - filters on the 
//                                                                          exchange plan node to be filled with default values for the correspondent base.
//      * DefaultValues                                   - Structure - default values on the exchange plan node.
//      * CorrespondentDefaultValues                     - Structure - default values on the node for the correspondent base.
//      * CommonNodesData                                      - String - Returns comma-separated 
//                                                                         names of attributes and 
//                                                                         exchange plan tabular sections that are common for both data exchange participants.
//      * FilterFormName                                       - String - A name of node filter setup form to use.
//      * DefaultValueFormName                           - String - A default name of filter setup 
//                                                                         form to use.
//      * CorrespondentFilterFormName                         - String - A name of filter setup form 
//                                                                         of correspondent Infobase node  to use.
//      * DefaultValueFormNameCorrespondent             - String - a name of default values form to 
//                                                                         use on infobase correspondent node.
//      * FormNameCommonNodeData                              - String - a name of node configuration form to use.
//      * SettingsFileNameForDestination                          - String - a default file name for 
//                                                                         saving synchronization settings.
//      * UseDataExchangeCreationWizard             - Boolean - a flag showing whether the wizard 
//                                                                         will be used to create new exchange plan nodes.
//      * InitialImageCreatingFormName                      - String - a name of initial image 
//                                                                         creation form to use in distributed infobase.
//      * AdditionalDataForCorrespondentInfobase                 - Structure - additional data to be 
//                                                                         used for data exchange 
//                                                                         setup at the correspondent infobase. Can be used in handler
//                                                                        OnCreateAtServer in the 
//                                                                        setup form of the CorrespondentInfobaseDefaultValueSetupForm exchange plan node
//      * HintsForSettingUpAccountingParameters                  - String - Hints on sequence of 
//                                                                         user actions to setup 
//                                                                         accounting parameters in the current infobase.
//      * HintsToSetupAccountingCorrespondentParameters    - String - Hints on sequence of user 
//                                                                         actions to setup accounting parameters in the correspondent infobase.
//      * RuleSetFilePathOnUserSite      - String - the path to the archive of the rule set file on 
//                                                                         the user site, in the configuration section.
//      * RuleSetFilePathInTemplateDirectory            - String -  a relative path to the rule set 
//                                                                         file in the 1C:Enterprise template directory.
//      * NewDataExchangeCreationCommandTitle        - String - command presentation displayed to 
//                                                                         user on creating a new 
//                                                                         data exchange setting.
//      * ExchangeCreateWizardTitle                      - String - presentation of data exchange 
//                                                                         creation wizard title 
//                                                                         displayed to user.
//      * CorrespondentConfigurationDescription                - String - presentation of the 
//                                                                         correspondent configuration name displayed to user.
//      * ExchangePlanNodeTitle                              - String - the exchange plan node 
//                                                                         presentation displayed to user.
//      * DisplayFiltersSettingOnNode                      - Boolean - a flag showing whether node 
//                                                                         filter settings are shown in the exchange creation wizard.
//      * DisplayDefaultValuesOnNode                   - Boolean - a flag showing whether default 
//                                                                         values are shown in the exchange creation wizard.
//      * DisplayFiltersSettingOnCorrespondentInfobaseNode    - Boolean - a flag showing whether 
//                                                                         filter settings of the correspondent infobase node are shown in the exchange creation wizard.
//      * DisplayDefaultValuesOnCorrespondentBaseNode - Boolean - shows whether default values of 
//                                                                         the correspondent base are shown in the exchange creation wizard
//      * UsedExchangeMessagesTransports                 - Array - a list of used message transports.
//                                                                         If it is not filled in, 
//                                                                         all possible transport kinds will be available.
//      * ExchangeBriefInfo                             - String - Data exchange brief info 
//                                                                         displayed on the first 
//                                                                         page of the exchange creation wizard.
//      * DetailedExchangeInformation                           - String - a web page URL or a full 
//                                                                         path to the form within 
//                                                                         the configuration as a string to display in the exchange creation wizard.
//
Function ExchangeSettingOptionDetailsByDefault(ExchangePlanName)
	
	OptionDetails = New Structure;
	
	ExchangePlanMetadata = Metadata.ExchangePlans[ExchangePlanName];
	WizardFormTitle = NStr("ru = 'Синхронизация данных с %Application% (настройка)'; en = 'Data synchronization with %Application% (setup)'; pl = 'Synchronizacja danych z %Application% (ustawienie)';de = 'Datensynchronisation mit %Application% (Setup)';ro = 'Sincronizarea datelor cu %Application% (configurare)';tr = '%Application% ile veri senkronizasyonu (setup)'; es_ES = 'Sincronización de datos con %Application% (setup)'");
	WizardFormTitle = StrReplace(WizardFormTitle, "%Application%", ExchangePlanMetadata.Synonym);
	
	OptionDetails.Insert("SettingsFileNameForDestination",                          "");
	OptionDetails.Insert("UseDataExchangeCreationWizard",             True);
	OptionDetails.Insert("DataMappingSupported",                     True);
	
	OptionDetails.Insert("DataSyncSettingsWizardFormName",         "");
	OptionDetails.Insert("InitialImageCreationFormName",                      "");
	
	OptionDetails.Insert("PathToRulesSetFileOnUserSite",      "");
	OptionDetails.Insert("PathToRulesSetFileInTemplateDirectory",            "");
	OptionDetails.Insert("NewDataExchangeCreationCommandTitle",        ExchangePlanMetadata.Synonym);
	OptionDetails.Insert("CorrespondentConfigurationName",                         "");
	OptionDetails.Insert("CorrespondentConfigurationDescription",                "");
	OptionDetails.Insert("UsedExchangeMessagesTransports",                 New Array);
	OptionDetails.Insert("ExchangeBriefInfo",                             "");
	OptionDetails.Insert("ExchangeDetailedInformation",                           "");
	OptionDetails.Insert("CommonNodeData",                                      "");
	
	OptionDetails.Insert("ExchangeCreateWizardTitle",                      WizardFormTitle);
	OptionDetails.Insert("ExchangePlanNodeTitle",                              ExchangePlanMetadata.Synonym);
	
	OptionDetails.Insert("AccountingSettingsSetupNote",                  "");
	
	OptionDetails.Insert("Filters",                                                New Structure);
	OptionDetails.Insert("DefaultValues",                                   New Structure);

	Return OptionDetails;
	
EndFunction

Function CodeOfPredefinedExchangePlanNode(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	ThisNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	
	Return TrimAll(Common.ObjectAttributeValue(ThisNode, "Code"));
	
EndFunction

// Returns an array of all nodes of the specified exchange plan but the predefined node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  NodesArray - Array - an array of all nodes of the specified exchange plan but the predefined node.
//
Function ExchangePlanNodes(ExchangePlanName) Export
	
	Query = New Query(
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	#ExchangePlanTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.ThisNode");
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTableName", "ExchangePlan." + ExchangePlanName);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

#EndRegion

#Region ExchangeMessageFromMainNodeConstantOperations

// Reads infobase information on a data exchange message.
//
// Return value - Structure - information about the location of the exchange message file (current format).
//                       - BinaryData - an exchange message in the infobase (obsolete format).
//
Function DataExchangeMessageFromMasterNode()
	
	Return Constants.DataExchangeMessageFromMasterNode.Get().Get();
	
EndFunction

// Writes an exchange message file from the master node to the hard drive.
// Saves the path to the written message to the DataExchangeMessageFromMasterNode constant.
//
// Parameters:
//	ExchangeMessage - BinaryData - a read exchange message.
//	MasterNode - ExchangePlanRef - a node used to receive the message.
//
Procedure SetDataExchangeMessageFromMasterNode(ExchangeMessage, MasterNode) Export
	
	PathToFile = "[Directory][Path].xml";
	PathToFile = StrReplace(PathToFile, "[Directory]", TempFilesStorageDirectory());
	PathToFile = StrReplace(PathToFile, "[Path]", New UUID);
	
	ExchangeMessage.Write(PathToFile);
	
	MessageStructure = New Structure;
	MessageStructure.Insert("PathToFile", PathToFile);
	
	Constants.DataExchangeMessageFromMasterNode.Set(New ValueStorage(MessageStructure));
	
	WriteDataReceiveEvent(MasterNode, NStr("ru = 'Сообщение обмена записано в кэш.'; en = 'The exchange message is cached.'; pl = 'Wiadomość wymiany została zapisana w pamięci podręcznej.';de = 'Die Austauschnachricht wurde in den Cache geschrieben.';ro = 'Mesajul de schimb a fost scris în memoria cache.';tr = 'Değişim mesajı önbelleğe yazıldı.'; es_ES = 'El mensaje de intercambio se ha grabado en el caché.'"));
	
EndProcedure

// Deletes the exchange message file from the hard drive and clears the DataExchangeMessageFromMasterNode constant.
//
Procedure ClearDataExchangeMessageFromMasterNode() Export
	
	ExchangeMessage = DataExchangeMessageFromMasterNode();
	
	If TypeOf(ExchangeMessage) = Type("Structure") Then
		
		DeleteFiles(ExchangeMessage.PathToFile);
		
	EndIf;
	
	Constants.DataExchangeMessageFromMasterNode.Set(New ValueStorage(Undefined));
	
	WriteDataReceiveEvent(MasterNode(), NStr("ru = 'Сообщение обмена удалено из кэша.'; en = 'The exchange message is deleted from the cache.'; pl = 'Wiadomość wymiany została usunięta z pamięci podręcznej.';de = 'Die Austauschnachricht wurde aus dem Cache gelöscht.';ro = 'Mesajul de schimb a fost șters din memoria cache.';tr = 'Değişim mesajı önbellekten silindi.'; es_ES = 'El mensaje de intercambio se ha borrado del caché.'"));
	
EndProcedure

#EndRegion

#Region SecurityProfiles

Procedure CreateRequestsToUseExternalResources(PermissionsRequests)
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Constants.DataExchangeMessageDirectoryForLinux.CreateValueManager().OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	Constants.DataExchangeMessageDirectoryForWindows.CreateValueManager().OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
	InformationRegisters.DataExchangeTransportSettings.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	InformationRegisters.DataExchangeRules.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
EndProcedure

Procedure ExternalResourcesDataExchangeMessageDirectoryQuery(PermissionsRequests, Object) Export
	
	ConstantValue = Object.Value;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not IsBlankString(ConstantValue) Then
		
		Permissions = New Array();
		Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
			ConstantValue, True, True));
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
				Common.MetadataObjectID(Object.Metadata())));
		
	EndIf;
	
EndProcedure

// Returns the template of a security profile name for external module.
// The function must return the same value every time it is called.
//
// Parameters:
//  ExternalModule - AnyRef, a reference to an external module.
//
// Returns - String - a template of a security profile name containing characters
//  "%1". These characters will be replaced with a UUID later.
//
Function SecurityProfileNamePattern(Val ExternalModule) Export
	
	Template = "Exchange_[ExchangePlanName]_%1"; // Do not localize.
	Return StrReplace(Template, "[ExchangePlanName]", ExternalModule.Name);
	
EndFunction

// Returns an external module icon.
//
//  ExternalModule - AnyRef, a reference to an external module.
//
// Returns - a picture.
//
Function ExternalModuleIcon(Val ExternalModule) Export
	
	Return PictureLib.DataSynchronization;
	
EndFunction

Function ExternalModuleContainerDictionary() Export
	
	Result = New Structure();
	
	Result.Insert("NominativeCase", NStr("ru = 'Настройка синхронизация данных'; en = 'Data synchronization setting'; pl = 'Ustawienia synchronizacji danych';de = 'Konfigurieren Sie die Datensynchronisierung';ro = 'Setarea de sincronizare a datelor';tr = 'Veri senkronizasyonunu yapılandır'; es_ES = 'Configurar la sincronización de datos'"));
	Result.Insert("GenitiveCase", NStr("ru = 'Настройки синхронизации данных'; en = 'Data synchronization setting'; pl = 'Ustawienia synchronizacji danych';de = 'Datensynchronisierungseinstellungen';ro = 'Setările de sincronizare date';tr = 'Veri senkronizasyonu ayarları'; es_ES = 'Configuraciones de la sincronización de datos'"));
	
	Return Result;
	
EndFunction

Function ExternalModuleContainers() Export
	
	Result = New Array();
	DataExchangeOverridable.GetExchangePlans(Result);
	Return Result;
	
EndFunction

#EndRegion

#Region InteractiveExportModification

// Initializes export addition for the step-by-step exchange wizard.
//
// Parameters:
//     InfobaseNode - ExchangePlanRef                - a reference to the node to be configured.
//     FromStorageAddress    - String, UUID - an address for saving data between server calls.
//     HasNodeScenario       - Boolean - a flag showing whether additional setup is required.
//
// Returns:
//     Structure - data for further export addition operations.
//
Function InteractiveExportModification(Val InfobaseNode, Val FromStorageAddress, Val HasNodeScenario=Undefined) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("InfobaseNode", InfobaseNode);
	Result.Insert("ExportOption", 0);
	
	Result.Insert("AllDocumentsFilterPeriod", New StandardPeriod);
	Result.AllDocumentsFilterPeriod.Variant = StandardPeriodVariant.LastMonth;
	
	AdditionDataProcessor = DataProcessors.InteractiveExportModification.Create();
	AdditionDataProcessor.InfobaseNode = InfobaseNode;
	AdditionDataProcessor.ExportOption        = 0;
	
	// Specifying composer options.
	Data = AdditionDataProcessor.CommonFilterSettingsComposer(FromStorageAddress);
	Result.Insert("AllDocumentsComposerAddress", PutToTempStorage(Data, FromStorageAddress));
	
	Result.Insert("AdditionalRegistration", New ValueTable);
	Columns = Result.AdditionalRegistration.Columns;
	
	StringType = New TypeDescription("String");
	Columns.Add("FullMetadataName", StringType);
	Columns.Add("Filter",         New TypeDescription("DataCompositionFilter"));
	Columns.Add("Period",        New TypeDescription("StandardPeriod"));
	Columns.Add("SelectPeriod",  New TypeDescription("Boolean"));
	Columns.Add("Presentation", StringType);
	Columns.Add("FilterString",  StringType);
	Columns.Add("Count",    StringType);

	Result.Insert("AdditionScenarioParameters", New Structure);
	AdditionScenarioParameters = Result.AdditionScenarioParameters;
	
	AdditionScenarioParameters.Insert("OptionDoNotAdd", New Structure("Use, Order, Title", True, 1));
	AdditionScenarioParameters.OptionDoNotAdd.Insert("Explanation", 
		NStr("ru='Будут отправлены только данные согласно общим настройкам.'; en = 'Send only data selected using the common settings.'; pl = 'Będą wysyłane tylko dane zgodnie z ogólnymi ustawieniami.';de = 'Es werden nur Daten gemäß den allgemeinen Einstellungen gesendet.';ro = 'Numai datele conform setărilor generale vor fi trimise.';tr = 'Sadece genel ayarlara göre veri gönderilecektir.'; es_ES = 'Solo los datos según las configuraciones generales se enviarán.'")); 
	
	AdditionScenarioParameters.Insert("AllDocumentsOption", New Structure("Use, Order, Title", True, 2));
	AdditionScenarioParameters.AllDocumentsOption.Insert("Explanation",
		NStr("ru='Дополнительно будут отправлены все документы за период, удовлетворяющие условиям отбора.'; en = 'Also send all documents in the specified period that match the filter.'; pl = 'Wszystkie dokumenty za okres, spełniające warunki filtrowania będą wysyłane dodatkowo.';de = 'Alle Periodendokumente, die die Filterbedingungen erfüllen, werden zusätzlich gesendet.';ro = 'Toate documentele din perioada care satisfac condițiile de filtrare vor fi trimise suplimentar.';tr = 'Filtre koşullarını karşılayan tüm dönem belgeleri ek olarak gönderilecektir.'; es_ES = 'Todos los documentos del período, que cumplen las condiciones del filtro, se enviarán adicionalmente.'")); 
	
	AdditionScenarioParameters.Insert("ArbitraryFilterOption", New Structure("Use, Order, Title", True, 3));
	AdditionScenarioParameters.ArbitraryFilterOption.Insert("Explanation",
		NStr("ru='Дополнительно будут отправлены данные согласно отбору.'; en = 'Also send all data that matches the filter.'; pl = 'Dane będą wysyłane dodatkowo zgodnie z filtrem.';de = 'Daten werden zusätzlich gemäß dem Filter gesendet.';ro = 'Datele vor fi trimise suplimentar în funcție de filtru.';tr = 'Ek olarak filtreye göre veri gönderilecektir.'; es_ES = 'Datos se enviarán adicionalmente según el filtro.'")); 
	
	AdditionScenarioParameters.Insert("AdditionalOption", New Structure("Use, Order, Title", False,   4));
	AdditionScenarioParameters.AdditionalOption.Insert("Explanation",
		NStr("ru='Будут отправлены дополнительные данные по настройкам.'; en = 'Also send additional settings data.'; pl = 'Dodatkowe dane o ustawieniach zostaną wysłane.';de = 'Zusätzliche Daten zu den Einstellungen werden gesendet.';ro = 'Vor fi trimise date suplimentare conform setărilor.';tr = 'Ayarlar ile ilgili ek veriler gönderilecektir.'; es_ES = 'Datos adiciones sobre las configuraciones se enviarán.'")); 
	
	AdditionalOption = AdditionScenarioParameters.AdditionalOption;
	AdditionalOption.Insert("Title", "");
	AdditionalOption.Insert("UseFilterPeriod", False);
	AdditionalOption.Insert("FilterPeriod");
	AdditionalOption.Insert("Filter", Result.AdditionalRegistration.Copy());
	AdditionalOption.Insert("FilterFormName");
	AdditionalOption.Insert("FormCommandTitle");
	
	MetaNode = InfobaseNode.Metadata();
	
	If HasNodeScenario=Undefined Then
		// Additional setup is not required.
		HasNodeScenario = False;
	EndIf;
	
	If HasNodeScenario Then
		If HasExchangePlanManagerAlgorithm("SetUpInteractiveExport",MetaNode.Name) Then
			ModuleNodeManager = ExchangePlans[MetaNode.Name];
			ModuleNodeManager.SetUpInteractiveExport(InfobaseNode, Result.AdditionScenarioParameters);
		EndIf;
	EndIf;
	
	Result.Insert("FromStorageAddress", FromStorageAddress);
	
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Clearing filter for all documents.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//
Procedure InteractiveExportModificationGeneralFilterClearing(ExportAddition) Export
	
	If IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		ExportAddition.AllDocumentsFilterComposer.Settings.Filter.Items.Clear();
	Else
		Data = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
		Data.Settings.Filter.Items.Clear();
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(Data, ExportAddition.FromStorageAddress);
		
		Composer = New DataCompositionSettingsComposer;
		Composer.Initialize(New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
		Composer.LoadSettings(Data.Settings);
		ExportAddition.AllDocumentsFilterComposer = Composer;
	EndIf;
	
EndProcedure

// Clears the detailed filter.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//
Procedure InteractiveExportModificationDetailsClearing(ExportAddition) Export
	ExportAddition.AdditionalRegistration.Clear();
EndProcedure

// Defines general filter details. If the filter is not filled, returning the empty string.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//
// Returns:
//     String - filter details.
//
Function InteractiveExportModificationGeneralFilterAdditionDescription(Val ExportAddition) Export
	
	ComposerData = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
	
	Source = New DataCompositionAvailableSettingsSource(ComposerData.CompositionSchema);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(Source);
	Composer.LoadSettings(ComposerData.Settings);
	
	Return ExportAdditionFilterPresentation(Undefined, Composer, "");
EndFunction

// Define the description of the detailed filter. If the filter is not filled, returning the empty string.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//
// Returns:
//     String - filter details.
//
Function InteractiveExportModificationDetailedFilterDetails(Val ExportAddition) Export
	Return DetailedExportAdditionPresentation(ExportAddition.AdditionalRegistration, "");
EndFunction

// Analyzes the filter settings history saved by the user for the node.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//
// Returns:
//     List of values where presentation is a setting name and value is setting data.
//
Function InteractiveExportModificationSettingsHistory(Val ExportAddition) Export
	AdditionDataProcessor = DataProcessors.InteractiveExportModification.Create();
	
	OptionFilter = InteractiveExportModificationVariantFilter(ExportAddition);
	
	Return AdditionDataProcessor.ReadSettingsListPresentations(ExportAddition.InfobaseNode, OptionFilter);
EndFunction

// Restores settings in the ExportAddition attributes by the name of the saved setting.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//     SettingPresentation - String                            - a name of a setting to restore.
//
// Returns:
//     Boolean - True - restored, False - the setting is not found.
//
Function InteractiveExportModificationRestoreSettings(ExportAddition, Val SettingPresentation) Export
	
	AdditionDataProcessor = DataProcessors.InteractiveExportModification.Create();
	FillPropertyValues(AdditionDataProcessor, ExportAddition);
	
	OptionFilter = InteractiveExportModificationVariantFilter(ExportAddition);
	
	// Restoring object state.
	Result = AdditionDataProcessor.RestoreCurrentAttributesFromSettings(SettingPresentation, OptionFilter, ExportAddition.FromStorageAddress);
	
	If Result Then
		FillPropertyValues(ExportAddition, AdditionDataProcessor, "ExportOption, AllDocumentsFilterPeriod, AllDocumentsFilterComposer");
		
		// Updating composer address anyway.
		Data = AdditionDataProcessor.CommonFilterSettingsComposer();
		Data.Settings = ExportAddition.AllDocumentsFilterComposer.Settings;
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(Data, ExportAddition.FromStorageAddress);
		
		FillValueTable(ExportAddition.AdditionalRegistration, AdditionDataProcessor.AdditionalRegistration);
		
		// Updating node scenario settings only if they are defined in the read message Otherwise leave the current one.
		If AdditionDataProcessor.AdditionalNodeScenarioRegistration.Count() > 0 Then
			FillPropertyValues(ExportAddition, AdditionDataProcessor, "NodeScenarioFilterPeriod, NodeScenarioFilterPresentation");
			FillValueTable(ExportAddition.AdditionalNodeScenarioRegistration, AdditionDataProcessor.AdditionalNodeScenarioRegistration);
			// Normalizing period settings.
			InteractiveExportModificationSetNodeScenarioPeriod(ExportAddition);
		EndIf;
		
		// The current presentation of saved settings.
		ExportAddition.CurrentSettingsItemPresentation = SettingPresentation;
	EndIf;

	Return Result;
EndFunction

// Saves settings with the specified name, according to the ExportAddition values.
//
// Parameters:
//     ExportAddition -Structure, FormAttributesCollection - export parameters details.
//     SettingPresentation - String                            - a name of the setting to save.
//
Procedure InteractiveExportModificationSaveSettings(ExportAddition, Val SettingPresentation) Export
	
	AdditionDataProcessor = DataProcessors.InteractiveExportModification.Create();
	FillPropertyValues(AdditionDataProcessor, ExportAddition, ,
		"AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	FillValueTable(AdditionDataProcessor.AdditionalRegistration,             ExportAddition.AdditionalRegistration);
	FillValueTable(AdditionDataProcessor.AdditionalNodeScenarioRegistration, ExportAddition.AdditionalNodeScenarioRegistration);
	
	// Specifying settings composer options again.
	Data = AdditionDataProcessor.CommonFilterSettingsComposer();
	
	If IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		SettingsSource = ExportAddition.AllDocumentsFilterComposer.Settings;
	Else
		ComposerStructure = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
		SettingsSource = ComposerStructure.Settings;
	EndIf;
		
	AdditionDataProcessor.AllDocumentsFilterComposer = New DataCompositionSettingsComposer;
	AdditionDataProcessor.AllDocumentsFilterComposer.Initialize( New DataCompositionAvailableSettingsSource(Data.CompositionSchema) );
	AdditionDataProcessor.AllDocumentsFilterComposer.LoadSettings(SettingsSource);
	
	// Saving
	AdditionDataProcessor.SaveCurrentValuesInSettings(SettingPresentation);
	
	// Current presentation of saved settings.
	ExportAddition.CurrentSettingsItemPresentation = SettingPresentation;
	
EndProcedure

// Fills in the form attribute according to settings structure data.
//
// Parameters:
//     Form - ManagedForm - an attribute setup form.
//     ExportAdditionSettings - Structure - initial settings.
//     AdditionAttributeName      - String           - a name of the form attribute for creation and filling in.
//
Procedure InteractiveExportModificationAttributeBySettings(Form, Val ExportAdditionSettings, Val AdditionAttributeName="ExportAddition") Export
	
	SetPrivilegedMode(True);
	
	AdditionScenarioParameters = ExportAdditionSettings.AdditionScenarioParameters;
	
	// Processing the attributes
	AdditionAttribute = Undefined;
	For Each Attribute In Form.GetAttributes() Do
		If Attribute.Name=AdditionAttributeName Then
			AdditionAttribute = Attribute;
			Break;
		EndIf;
	EndDo;
	
	// Checking and adding the attribute.
	PermissionsToAdd = New Array;
	If AdditionAttribute=Undefined Then
		AdditionAttribute = New FormAttribute(AdditionAttributeName, 
			New TypeDescription("DataProcessorObject.InteractiveExportModification"));
			
		PermissionsToAdd.Add(AdditionAttribute);
		Form.ChangeAttributes(PermissionsToAdd);
	EndIf;
	
	// Checking and adding columns of the general additional registration.
	TableAttributePath = AdditionAttribute.Name + ".AdditionalRegistration";
	If Form.GetAttributes(TableAttributePath).Count()=0 Then
		PermissionsToAdd.Clear();
		Columns = ExportAdditionSettings.AdditionalRegistration.Columns;
		For Each Column In Columns Do
			PermissionsToAdd.Add(New FormAttribute(Column.Name, Column.ValueType, TableAttributePath));
		EndDo;
		Form.ChangeAttributes(PermissionsToAdd);
	EndIf;
	
	// Checking and adding additional registration columns of the node scenario.
	TableAttributePath = AdditionAttribute.Name + ".AdditionalNodeScenarioRegistration";
	If Form.GetAttributes(TableAttributePath).Count()=0 Then
		PermissionsToAdd.Clear();
		Columns = AdditionScenarioParameters.AdditionalOption.Filter.Columns;
		For Each Column In Columns Do
			PermissionsToAdd.Add(New FormAttribute(Column.Name, Column.ValueType, TableAttributePath));
		EndDo;
		Form.ChangeAttributes(PermissionsToAdd);
	EndIf;
	
	// Adding data
	AttributeValue = Form[AdditionAttributeName];
	
	// Processing value tables.
	ValueToFormData(AdditionScenarioParameters.AdditionalOption.Filter,
		AttributeValue.AdditionalNodeScenarioRegistration);
	
	AdditionScenarioParameters.AdditionalOption.Filter =TableIntoStrucrureArray(
		AdditionScenarioParameters.AdditionalOption.Filter);
	
	AttributeValue.AdditionScenarioParameters = AdditionScenarioParameters;
	
	AttributeValue.InfobaseNode = ExportAdditionSettings.InfobaseNode;

	AttributeValue.ExportOption                 = ExportAdditionSettings.ExportOption;
	AttributeValue.AllDocumentsFilterPeriod      = ExportAdditionSettings.AllDocumentsFilterPeriod;
	
	Data = GetFromTempStorage(ExportAdditionSettings.AllDocumentsComposerAddress);
	DeleteFromTempStorage(ExportAdditionSettings.AllDocumentsComposerAddress);
	AttributeValue.AllDocumentsComposerAddress = PutToTempStorage(Data, Form.UUID);
	
	AttributeValue.NodeScenarioFilterPeriod = AdditionScenarioParameters.AdditionalOption.FilterPeriod;
	
	If AdditionScenarioParameters.AdditionalOption.Use Then
		AttributeValue.NodeScenarioFilterPresentation = ExportAdditionPresentationByNodeScenario(AttributeValue);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns export by settings details.
//
// Parameters:
//     ExportAddition -Structure, FormDataCollection - export parameters details.
//
// Returns:
//     String - presentation.
// 
Function ExportAdditionPresentationByNodeScenario(Val ExportAddition)
	MetaNode = ExportAddition.InfobaseNode.Metadata();
	If NOT HasExchangePlanManagerAlgorithm("InteractiveExportFilterPresentation",MetaNode.Name) Then
		Return "";
	EndIf;
	ModuleManager = ExchangePlans[MetaNode.Name];
	
	Parameters = New Structure;
	Parameters.Insert("UseFilterPeriod", ExportAddition.AdditionScenarioParameters.AdditionalOption.UseFilterPeriod);
	Parameters.Insert("FilterPeriod",             ExportAddition.NodeScenarioFilterPeriod);
	Parameters.Insert("Filter",                    ExportAddition.AdditionalNodeScenarioRegistration);
	
	Return ModuleManager.InteractiveExportFilterPresentation(ExportAddition.InfobaseNode, Parameters);
EndFunction

// Returns period and filter details as string.
//
//  Parameters:
//      Period:                a period to describe filter.
//      Filter:                 a data composition filter to describe.
//      EmptyFilterDetails: the function returns this value if an empty filter is passed.
//
//  Returns:
//      String - description of period and filter.
//
Function ExportAdditionFilterPresentation(Val Period, Val Filter, Val EmptyFilterDetails=Undefined) Export
	
	OurFilter = ?(TypeOf(Filter)=Type("DataCompositionSettingsComposer"), Filter.Settings.Filter, Filter);
	
	PeriodAsString = ?(ValueIsFilled(Period), String(Period), "");
	FilterString  = String(OurFilter);
	
	If IsBlankString(FilterString) Then
		If EmptyFilterDetails=Undefined Then
			FilterString = NStr("ru='Все объекты'; en = 'All objects'; pl = 'Wszystkie obiekty';de = 'Alle Objekte';ro = 'Toate obiectele';tr = 'Tüm nesneler'; es_ES = 'Todos objetos'");
		Else
			FilterString = EmptyFilterDetails;
		EndIf;
	EndIf;
	
	If Not IsBlankString(PeriodAsString) Then
		FilterString =  PeriodAsString + ", " + FilterString;
	EndIf;
	
	Return FilterString;
EndFunction

// Returns details of the detailed filter by the AdditionalRegistration attribute.
//
//  Parameters:
//      AdditionalRegistration - ValueTable, Array - strings or structures that describe the filter.
//      EmptyFilterDetails     - String                  - the function returns this value if an empty filter is passed.
//
Function DetailedExportAdditionPresentation(Val AdditionalRegistration, Val EmptyFilterDetails=Undefined) Export
	
	Text = "";
	For Each Row In AdditionalRegistration Do
		Text = Text + Chars.LF + Row.Presentation + ": " + ExportAdditionFilterPresentation(Row.Period, Row.Filter);
	EndDo;
	
	If Not IsBlankString(Text) Then
		Return TrimAll(Text);
		
	ElsIf EmptyFilterDetails=Undefined Then
		Return NStr("ru='Дополнительные данные не выбраны'; en = 'No additional data is selected'; pl = 'Dodatkowe dane nie zostały wybrane';de = 'Zusätzliche Daten sind nicht ausgewählt';ro = 'Nu sunt selectate date suplimentare';tr = 'Ek veri seçilmedi'; es_ES = 'Datos adicionales no seleccionados'");
		
	EndIf;
	
	Return EmptyFilterDetails;
EndFunction

// The "All documents" metadata object internal group ID.
//
Function ExportAdditionAllDocumentsID() Export
	// The ID must not be identical to the full metadata name.
	Return "AllDocuments";
EndFunction

// The "All catalogs" metadata object internal group ID.
//
Function ExportAdditionAllCatalogsID() Export
	// The ID must not be identical to the full metadata name.
	Return "AllCatalogs";
EndFunction

// Name to save and restore settings upon interactive export addition.
//
Function ExportAdditionSettingsAutoSavingName() Export
	Return NStr("ru = 'Последняя отправка (сохраняется автоматически)'; en = 'Last data sent (autosaved)'; pl = 'Ostatnio wysłane (zapisane automatycznie)';de = 'Zuletzt gesendet (automatisch gespeichert)';ro = 'Ultimul trimis (salvat automat)';tr = 'Son gönderilen (otomatik kaydedilmiştir)'; es_ES = 'Último enviado (guardado automáticamente)'");
EndFunction

// Carries out additional registration of objects by settings.
//
// Parameters:
//     ExportAddition -Structure, FormDataCollection - export parameters details.
//
Procedure InteractiveExportModificationRegisterAdditionalData(Val ExportAddition) Export
	
	If ExportAddition.ExportOption <= 0 Then
		Return;
	EndIf;
	
	ReportObject = DataProcessors.InteractiveExportModification.Create();
	FillPropertyValues(ReportObject, ExportAddition,,"AdditionalRegistration, AdditionalNodeScenarioRegistration");
		
	If ReportObject.ExportOption=1 Then
		// Period with filter, additional option is empty.
		
	ElsIf ExportAddition.ExportOption=2 Then
		// Detailed settings
		ReportObject.AllDocumentsFilterComposer = Undefined;
		ReportObject.AllDocumentsFilterPeriod      = Undefined;
		
		FillValueTable(ReportObject.AdditionalRegistration, ExportAddition.AdditionalRegistration);
		
	ElsIf ExportAddition.ExportOption=3 Then
		// According to the node scenario imitating detailed option.
		ReportObject.ExportOption = 2;
		
		ReportObject.AllDocumentsFilterComposer = Undefined;
		ReportObject.AllDocumentsFilterPeriod      = Undefined;
		
		FillValueTable(ReportObject.AdditionalRegistration, ExportAddition.AdditionalNodeScenarioRegistration);
	EndIf;
	
	ReportObject.RecordAdditionalChanges();
EndProcedure

// Sets the general period for all filter sections.
//
// Parameters:
//     ExportAddition -Structure, FormDataCollection - export parameters details.
//
Procedure InteractiveExportModificationSetNodeScenarioPeriod(ExportAddition) Export
	For Each Row In ExportAddition.AdditionalNodeScenarioRegistration Do
		Row.Period = ExportAddition.NodeScenarioFilterPeriod;
	EndDo;
	
	// Updating the presentation
	ExportAddition.NodeScenarioFilterPresentation = ExportAdditionPresentationByNodeScenario(ExportAddition);
EndProcedure

// Returns used filter options by settings data.
//
// Parameters:
//     ExportAddition -Structure, FormDataCollection - export parameters details.
//
// Returns:
//     Array contains the following numbers of used options:
//               0 - without filter, 1 - all document filter, 2 - detailed, 3 - node scenario.
//
Function InteractiveExportModificationVariantFilter(Val ExportAddition) Export
	
	Result = New Array;
	
	DataTest = New Structure("AdditionScenarioParameters");
	FillPropertyValues(DataTest, ExportAddition);
	AdditionScenarioParameters = DataTest.AdditionScenarioParameters;
	If TypeOf(AdditionScenarioParameters)<>Type("Structure") Then
		// If there is no settings specified, using all options as the default settings
		Return Undefined;
	EndIf;
	
	If AdditionScenarioParameters.Property("OptionDoNotAdd") 
		AND AdditionScenarioParameters.OptionDoNotAdd.Use Then
		Result.Add(0);
	EndIf;
	
	If AdditionScenarioParameters.Property("AllDocumentsOption")
		AND AdditionScenarioParameters.AllDocumentsOption.Use Then
		Result.Add(1);
	EndIf;
	
	If AdditionScenarioParameters.Property("ArbitraryFilterOption")
		AND AdditionScenarioParameters.ArbitraryFilterOption.Use Then
		Result.Add(2);
	EndIf;
	
	If AdditionScenarioParameters.Property("AdditionalOption")
		AND AdditionScenarioParameters.AdditionalOption.Use Then
		Result.Add(3);
	EndIf;
	
	If Result.Count()=4 Then
		// All options are selected, deleting filter.
		Return Undefined;
	EndIf;

	Return Result;
EndFunction

#EndRegion

Function NewXDTODataExchangeNode(
		ExchangePlanName,
		SettingID,
		CorrespondentID,
		CorrespondentDescription,
		ExchangeFormatVersion)
	
	ExchangePlanManager = ExchangePlans[ExchangePlanName];
	
	NewNode = ExchangePlanManager.CreateNode();
	NewNode.Code          = CorrespondentID;
	NewNode.Description = CorrespondentDescription;
	
	If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ExchangePlanName]) Then
		NewNode.SettingsMode = SettingID;
	EndIf;
	
	NewNode.ExchangeFormatVersion = ExchangeFormatVersion;
	
	NewNode.Fill(Undefined);
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable()
		AND IsSeparatedSSLExchangePlan(ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	Return NewNode.Ref;
	
EndFunction

#EndRegion