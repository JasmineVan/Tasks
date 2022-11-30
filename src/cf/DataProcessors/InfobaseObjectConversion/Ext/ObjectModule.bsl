///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

////////////////////////////////////////////////////////////////////////////////
// ACRONYMS IN VARIABLE NAMES
//
//  OCR is an object conversion rule.
//  PCR is an object property conversion rule.
//  PGCR is an object property group conversion rule.
//  VCR is an object value conversion rule.
//  DER is a data export rule.
//  DCR is a data clearing rule.

////////////////////////////////////////////////////////////////////////////////
// EXPORT VARIABLES
Var EventLogMessageKey Export; // a message string to record errors in the event log.
Var ExternalConnection Export; // Contains external connection global context or Undefined.
Var Queries Export; // Structure containing used queries.

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY MODULE VARIABLES FOR CREATING ALGORITHMS (FOR BOTH IMPORT AND EXPORT)

Var Conversion; // Conversion property structure (name, ID, and exchange event handlers).

Var Algorithms; // Structure containing used algorithms.
Var AdditionalDataProcessors; // Structure containing used external data processors.

Var Rules; // Structure containing references to OCR.

Var Managers; // Map containing the following fields: Name, TypeName, RefTypeAsString, Manager, MetadataObject, and OCR.
Var ManagersForExchangePlans;

Var AdditionalDataProcessorParameters; // Structure containing parameters of used external data processors.

Var ParametersInitialized; // If True, necessary conversion parameters are initialized.

Var DataProtocolFile; // Data exchange log file.
Var CommentObjectProcessingFlag;

////////////////////////////////////////////////////////////////////////////////
// HANDLER DEBUGGING VARIABLES

Var ExportProcessing;
Var ImportProcessing;

////////////////////////////////////////////////////////////////////////////////
// FLAGS THAT SHOW WHETHER GLOBAL EVENT HANDLERS EXIST

Var HasBeforeExportObjectGlobalHandler;
Var HasAfterExportObjectGlobalHandler;

Var HasBeforeConvertObjectGlobalHandler;

Var HasBeforeImportObjectGlobalHandler;
Var HasAfterObjectImportGlobalHandler;

////////////////////////////////////////////////////////////////////////////////
// VARIABLES THAT ARE USED IN EXCHANGE HANDLERS (BOTH FOR IMPORT AND EXPORT)

Var StringType;                  // Type("String")
Var BooleanType;                  // Type("Boolean")
Var NumberType;                   // Type("Number")
Var DateType;                    // Type("Date")
Var UUIDType; // Type("UUID")
Var ValueStorageType;       // Type("ValueStorage")
Var BinaryDataType;          // Type("BinaryData")
Var AccumulationRecordTypeType;   // Type("AccumulationRecordType")
Var ObjectDeletionType;         // Type("ObjectDeletion")
Var AccountTypeKind;                // Type("AccountType")
Var TypeType;                     // Type("Type")
Var MapType;            // Type("Map".
Var String36Type;
Var String255Type;

Var MapRegisterType;

Var XMLNodeTypeEndElement;
Var XMLNodeTypeStartElement;
Var XMLNodeTypeText;

Var BlankDateValue;

Var ErrorMessages; // Map. Key - an error code, Value - error details.

////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCESSING MODULE VARIABLES
 
Var SnCounter;   // Number - an NBSp counter.
Var WrittenToFileSn;
Var PropertyConversionRuleTable;      // ValueTable - a template for restoring the table structure by copying.
                                            //                   
Var XMLRules;                           // XML string that contains exchange rule description.
Var TypesForDestinationString;
Var DocumentsForDeferredPostingField; // Value table to post documents after the data import.
Var DocumentsForDeferredPostingMap; // Map for storage additional document properties after data import.
                                                      // 
Var ObjectsForDeferredPostingField; // Map for storing reference type object after data import.
Var ExchangeFile; // Sequentially written or read exchange file.
Var ObjectsToExportCount; //Total number of objects to be exported.

////////////////////////////////////////////////////////////////////////////////
// IMPORT PROCESSING MODULE VARIABLES
 
Var DeferredDocumentRegisterRecordCount;
Var LastSearchByRefNumber;
Var StoredExportedObjectCountByTypes;
Var AdditionalSearchParameterMap;
Var TypeAndObjectNameMap;
Var EmptyTypeValueMap;
Var TypeDescriptionMap;
Var ConversionRulesMap; // Map to define an object conversion rule by this object type.
Var MessageNumberField;
Var ReceivedMessageNumberField;
Var AllowDocumentPosting;
Var DataExportCallStack;
Var GlobalNotWrittenObjectStack;
Var DataMapForExportedItemUpdate;
Var EventsAfterParametersImport;
Var ObjectMapsRegisterManager;
Var CurrentNestingLevelExportByRule;
Var VisualExchangeSetupMode;
Var ExchangeRuleInfoImportMode;
Var SearchFieldInfoImportResultTable;
Var CustomSearchFieldInfoOnDataExport;
Var CustomSearchFieldInfoOnDataImport;
Var InfobaseObjectsMapQuery;
Var HasObjectRegistrationDataAdjustment;
Var HasObjectChangeRecordData;
Var ExchangeNodeDataImportObject;

Var DataImportDataProcessorField;
Var ObjectsToImportCount;
Var ExchangeMessageFileSize;

////////////////////////////////////////////////////////////////////////////////
// VARIABLES FOR PROPERTY VALUES

Var ErrorFlagField;
Var ExchangeResultField;
Var DataExchangeStateField;

Var ExchangeMessageDataTableField;  // Map with data values tables from the exchange messages;
										 // Key - TypeName (String); Value - a table with object data (ValueTable).
//
Var PackageHeaderDataTableField; // A value table with data from the batch title file of exchange messages.
Var ErrorMessageStringField; // String - a variable contains a string with error message.
//
Var DataForImportTypeMapField;

Var ImportedObjectCounterField; // Imported object counter.
Var ExportedObjectCounterField; // Exported object counter.

Var ExchangeResultPrioritiesField; // Array - priorities of data exchange results descending.

Var ObjectPropertyDescriptionTableField; // Map: Key - MetadataObject; Value - ValueTable - a table of description of metadata object 
                                          // properties.

Var ExportedByRefObjectsField; // Array of objects exported by reference. Array elements are unique.
Var CreatedOnExportObjectsField; // Array of objects created during import. Array elements are unique.

Var ExportedByRefMetadataObjectsField; // Cache) Map: Key - MetadataObject. Value - a flag showing whether an object is exported by 
                                                // reference. True - an object must be exported by reference. Otherwise, False.
                                                // 

Var ObjectsRegistrationRulesField; // Cache) ValueTable - contains object registration rules (only rules with the "Allowed object 
                                      // filter" kind and for the current exchange plan).

Var ExchangePlanNameField;

Var ExchangePlanNodePropertyField;

Var IncomingExchangeMessageFormatVersionField;

#EndRegion

#Region Public

#Region ExportProperties

// Function for retrieving properties: a number of the received data exchange message.
//
// Returns:
//  Number - a number of the received data exchange message.
//
Function ReceivedMessageNumber() Export
	
	If TypeOf(ReceivedMessageNumberField) <> Type("Number") Then
		
		ReceivedMessageNumberField = 0;
		
	EndIf;
	
	Return ReceivedMessageNumberField;
	
EndFunction

#EndRegion

#Region DataOperations

// Returns a string - a name of the passed enumeration value.
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  Value     - EnumRef - an enumeration value.
//
// Returns:
//  String       - String - a name of the passed enumeration value.
//
Function deEnumValueName(Value) Export

	MetadataObject       = Value.Metadata();
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);

	Return MetadataObject.EnumValues[ValueIndex].Name;

EndFunction

#EndRegion

#Region ExchangeRulesOperationProcedures

// Sets parameter values in the Parameters structure by the ParametersSetupTable table.
// 
//
Procedure SetParametersFromDialog() Export

	For Each TableRow In ParameterSetupTable Do
		Parameters.Insert(TableRow.Name, TableRow.Value);
	EndDo;

EndProcedure

#EndRegion

#Region DataSending

// Exports an object according to the specified conversion rule.
//
// Parameters:
//  Source				 - Arbitrary - an arbitrary data source.
//  Destination				 - a destination object XML node.
//  IncomingData			 - Arbitrary - auxiliary data passed to the conversion rule.
//                             
//  OutgoingData			 - Arbitrary - arbitrary auxiliary data passed to property conversion rules.
//                             
//  OCRName					 - String - a name of the conversion rule used to execute export.
//  RefNode				 - a destination object reference XML node.
//  GetRefNodeOnly - Boolean - if True, the object is not exported but the reference XML node is 
//                             generated.
//  OCR						 - ValueTableRow - conversion rule reference.
//  ExportSubordinateObjectRefs - Boolean - if True, subordinate object references are exported.
//  ExportRegisterRecordSetRow - Boolean - if True, a record set line is exported.
//  ParentNode				 - a destination object parent XML node.
//  ConstantNameForExport  - String - value to write to the ConstantName attribute.
//  IsObjectExport - boolean - a flag showing that the object is exporting.
//  IsRuleWithGlobalObjectExport - Boolean - a flag indicating global object export.
//  DontUseRuleWithGlobalExportAndDontRememberExported - Boolean - not used.
//  ObjectExportStack      - Array - contains information on parent export objects.
//
// Returns:
//  a reference XML node or a destination value.
//
//
Function ExportByRule(Source					= Undefined,
						   Destination					= Undefined,
						   IncomingData			= Undefined,
						   OutgoingData			= Undefined,
						   OCRName					= "",
						   RefNode				= Undefined,
						   GetRefNodeOnly	= False,
						   OCR						= Undefined,
						   ExportSubordinateObjectRefs = True,
						   ExportRegisterRecordSetRow = False,
						   ParentNode				= Undefined,
						   ConstantNameForExport  = "",
						   IsObjectExport = Undefined,
						   IsRuleWithGlobalObjectExport = False,
						   DontUseRuleWithGlobalExportAndDontRememberExported = False,
						   ObjectExportStack = Undefined) Export
	//
	
	DetermineOCRByParameters(OCR, Source, OCRName);
			
	If OCR = Undefined Then
		
		WP = ExchangeProtocolRecord(45);
		
		WP.Object = Source;
		WP.ObjectType = TypeOf(Source);
		
		WriteToExecutionProtocol(45, WP, True); // OCR is not found
		Return Undefined;
		
	EndIf;
	
	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule + 1;
	
	If CommentObjectProcessingFlag Then
		
		Try
			SourceToString = String(Source);
		Except
			SourceToString = " ";
		EndTry;
		
		ActionName = ?(GetRefNodeOnly, NStr("ru = 'Конвертация ссылки на объект'; en = 'Converting object reference'; pl = 'Konwersja linku do obiektu';de = 'Umwandlung der Referenz in ein Objekt';ro = 'Conversia referinței la obiect';tr = 'Nesne referansının dönüştürülmesi'; es_ES = 'Conversión de la referencia al objeto'"), NStr("ru = 'Конвертация объекта'; en = 'Converting object'; pl = 'Konwersja obiektu';de = 'Objektkonvertierung';ro = 'Conversia obiectelor';tr = 'Nesne dönüştürülmesi'; es_ES = 'Conversión del objeto'"));
		
		MessageText = NStr("ru = '[ActionName]: [Object]([ObjectType]), ПКО: [OCR](НаименованиеПКО)'; en = '[ActionName]: [Object]([ObjectType]), OCR: [OCR](OCRDescription)'; pl = '[ActionName]: [Object]([ObjectType]), OCR: [OCR](OCRDescription)';de = '[ActionName]: [Object] ([ObjectType]), PKO: [OCR](NamePKO)';ro = '[ActionName]: [Object]([ObjectType]), ПКО: [OCR](НаименованиеПКО)';tr = '[ActionName]: [Object]([ObjectType]), PKО: [OCR](PКОAdı)'; es_ES = '[ActionName]: [Object]([ObjectType]),OCR: [OCR](OCRDescription)'");
		MessageText = StrReplace(MessageText, "[ActionName]", ActionName);
		MessageText = StrReplace(MessageText, "[Object]", SourceToString);
		MessageText = StrReplace(MessageText, "[ObjectType]", TypeOf(Source));
		MessageText = StrReplace(MessageText, "[OCR]", TrimAll(OCRName));
		MessageText = StrReplace(MessageText, "[OCRDescription]", TrimAll(OCR.Description));
		
		WriteToExecutionProtocol(MessageText, , False, CurrentNestingLevelExportByRule + 1, 7);
		
	EndIf;
	
	IsRuleWithGlobalObjectExport = False;
	
	If ObjectExportStack = Undefined Then
		ObjectExportStack = New Array;
	EndIf;
	
	PropertiesToTransfer = New Structure("Ref");
	If Source <> Undefined AND TypeOf(Source) <> Type("String") Then
		FillPropertyValues(PropertiesToTransfer, Source);
	EndIf;
	SourceRef = PropertiesToTransfer.Ref;
	
	ObjectExportedByRefFromItself = False;
	If ValueIsFilled(SourceRef) Then
		SequenceNumberInStack = ObjectExportStack.Find(SourceRef);
		ObjectExportedByRefFromItself = SequenceNumberInStack <> Undefined;
	EndIf;
	
	ObjectExportStack.Add(SourceRef);
	
	// Loop reference to the object.
	RememberExported = ObjectExportedByRefFromItself;
	
	ExportedObjects          = OCR.Exported;
	AllObjectsExported         = OCR.AllObjectsExported;
	DontReplaceObjectOnImport = OCR.DoNotReplace;
	DontCreateIfNotFound     = OCR.DoNotCreateIfNotFound;
	OnExchangeObjectByRefSetGIUDOnly     = OCR.OnMoveObjectByRefSetGIUDOnly;
	DontReplaceObjectCreatedInDestinationInfobase = OCR.DoNotReplaceObjectCreatedInDestinationInfobase;
	ExchangeObjectsPriority = OCR.ExchangeObjectsPriority;
	
	RecordObjectChangeAtSenderNode = False;
	
	AutonumberingPrefix		= "";
	WriteMode     			= "";
	PostingMode 			= "";
	TempFileList = Undefined;

   	TypeName          = "";
	ExportObjectProperties = True;
	
	PropertyStructure = FindPropertyStructureByParameters(OCR, Source);
			
	If PropertyStructure <> Undefined Then
		TypeName = PropertyStructure.TypeName;
	EndIf;

	ExportedDataKey = OCRName;
	
	If ValueIsFilled(TypeName) Then
		
		IsNotReferenceType = TypeName = "Constants"
			Or TypeName = "InformationRegister"
			Or TypeName = "AccumulationRegister"
			Or TypeName = "AccountingRegister"
			Or TypeName = "CalculationRegister";
		
	Else
		
		If TypeOf(Source) = Type("Structure") Then
			IsNotReferenceType = Not Source.Property("Ref");
		Else
			IsNotReferenceType = True;
		EndIf;
		
	EndIf;
	
	If IsNotReferenceType 
		OR IsBlankString(TypeName) Then
		
		RememberExported = False;
		
	EndIf;
	
	RefToSource = Undefined;
	ExportingObject = IsObjectExport;
	
	If (Source <> Undefined) 
		AND NOT IsNotReferenceType Then
		
		If ExportingObject = Undefined Then
			// If nothing is specified than specify that object is exporting.
			ExportingObject = True;	
		EndIf;
		
		RefToSource = GetRefByObjectOrRef(Source, ExportingObject);
		If RememberExported Then
			ExportedDataKey = DetermineInternalPresentationForSearch(RefToSource, PropertyStructure);
		EndIf;
		
	Else
		
		ExportingObject = False;
			
	EndIf;
	
	// Variable for storing the predefined item name.
	PredefinedItemName = Undefined;
	
	// BeforeObjectConversion global handler.
	Cancel = False;
	If HasBeforeConvertObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				HandlerParameters = New Array();
				HandlerParameters.Add(ExchangeFile);
				HandlerParameters.Add(Source);
				HandlerParameters.Add(IncomingData);
				HandlerParameters.Add(OutgoingData);
				HandlerParameters.Add(OCRName);
				HandlerParameters.Add(OCR);
				HandlerParameters.Add(ExportedObjects);
				HandlerParameters.Add(Cancel);
				HandlerParameters.Add(ExportedDataKey);
				HandlerParameters.Add(RememberExported);
				HandlerParameters.Add(DontReplaceObjectOnImport);
				HandlerParameters.Add(AllObjectsExported);
				HandlerParameters.Add(GetRefNodeOnly);
				HandlerParameters.Add(Destination);
				HandlerParameters.Add(WriteMode);
				HandlerParameters.Add(PostingMode);
				HandlerParameters.Add(DontCreateIfNotFound);
				
				ExecuteHandler_Conversion_BeforeObjectConversion(HandlerParameters);
				
				ExchangeFile = HandlerParameters[0];
				Source = HandlerParameters[1];
				IncomingData = HandlerParameters[2];
				OutgoingData = HandlerParameters[3];
				OCRName = HandlerParameters[4];
				OCR = HandlerParameters[5];
				ExportedObjects = HandlerParameters[6];
				Cancel = HandlerParameters[7];
				ExportedDataKey = HandlerParameters[8];
				RememberExported = HandlerParameters[9];
				DontReplaceObjectOnImport = HandlerParameters[10];
				AllObjectsExported = HandlerParameters[11];
				GetRefNodeOnly = HandlerParameters[12];
				Destination = HandlerParameters[13];
				WriteMode = HandlerParameters[14];
				PostingMode = HandlerParameters[15];
				DontCreateIfNotFound = HandlerParameters[16];
				
			Else
				
				Execute(Conversion.BeforeConvertObject);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(64, ErrorDescription(), OCR, Source, NStr("ru = 'ПередКонвертациейОбъекта (глобальный)'; en = 'BeforeConvertObject (global)'; pl = 'BeforeObjectConversion (globalny)';de = 'VorDerObjektkonvertierung (global)';ro = 'BeforeObjectConversion (la nivel mondial)';tr = 'NesneDönüştürmedenÖnce (global)'; es_ES = 'BeforeObjectConversion (global)'"));
		EndTry;
		
		If Cancel Then	//	Canceling further rule processing.
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Destination;
		EndIf;
		
	EndIf;
	
	// BeforeExport handler
	If OCR.HasBeforeExportHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				Execute_OCR_HandlerBeforeObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
															  ExportedObjects, Cancel, ExportedDataKey, RememberExported,
															  DontReplaceObjectOnImport, AllObjectsExported, GetRefNodeOnly,
															  Destination, WriteMode, PostingMode, DontCreateIfNotFound);
				
			Else
				
				Execute(OCR.BeforeExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(41, ErrorDescription(), OCR, Source, "BeforeExportObject");
		EndTry;
		
		If Cancel Then	//	Canceling further rule processing.
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Destination;
		EndIf;
		
	EndIf;
	
	ExportStackRow = Undefined;
	
	MustUpdateLocalExportedObjectCache = False;
	RefValueInAnotherIB = "";

	// Perhaps this data has already been exported.
	If Not AllObjectsExported Then
		
		SN = 0;
		
		If RememberExported Then
			
			ExportedObjectRow = ExportedObjects.Find(ExportedDataKey, "Key");
			
			If ExportedObjectRow <> Undefined Then
				
				ExportedObjectRow.CallCount = ExportedObjectRow.CallCount + 1;
				ExportedObjectRow.LastCallNumber = SnCounter;
				
				If GetRefNodeOnly Then
					
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					If StrFind(ExportedObjectRow.RefNode, "<Ref") > 0
						AND WrittenToFileSn >= ExportedObjectRow.RefSN Then
						Return ExportedObjectRow.RefSN;
					Else
						Return ExportedObjectRow.RefNode;
					EndIf;
					
				EndIf;
				
				ExportedRefNumber = ExportedObjectRow.RefSN;
				
				If NOT ExportedObjectRow.OnlyRefExported Then
					
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					Return ExportedObjectRow.RefNode;
					
				Else
					
					ExportStackRow = DataExportCallStack.Find(ExportedDataKey, "Ref");
				
					If ExportStackRow <> Undefined Then
						CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
						Return Undefined;
					EndIf;
					
					ExportStackRow = DataExportCallStack.Add();
					ExportStackRow.Ref = ExportedDataKey;
					
					SN = ExportedRefNumber;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If SN = 0 Then
			
			SnCounter = SnCounter + 1;
			SN         = SnCounter;
			
			
			// Preventing cyclic reference existence.
			If RememberExported Then
				
				If ExportedObjectRow = Undefined Then
					
					If NOT IsRuleWithGlobalObjectExport
						AND NOT MustUpdateLocalExportedObjectCache
						AND ExportedObjects.Count() > StoredExportedObjectCountByTypes Then
						
						MustUpdateLocalExportedObjectCache = True;
						DataMapForExportedItemUpdate.Insert(OCR.Destination, OCR);
												
					EndIf;
					
					ExportedObjectRow = ExportedObjects.Add();
					
				EndIf;
				
				ExportedObjectRow.Key = ExportedDataKey;
				ExportedObjectRow.RefNode = SN;
				ExportedObjectRow.RefSN = SN;
				ExportedObjectRow.LastCallNumber = SN;
												
				If GetRefNodeOnly Then
					
					ExportedObjectRow.OnlyRefExported = True;					
					
				Else
					
					ExportStackRow = DataExportCallStack.Add();
					ExportStackRow.Ref = ExportedDataKey;
					
				EndIf;
				
			EndIf;
				
		EndIf;
		
	EndIf;
	
	ValueMap = OCR.PredefinedDataValues;
	ValueMapItemCount = ValueMap.Count();
	
	// Predefined item map processing.
	If PredefinedItemName = Undefined Then
		
		If PropertyStructure <> Undefined
			AND ValueMapItemCount > 0
			AND PropertyStructure.SearchByPredefinedItemsPossible Then
			
			Try
				PredefinedNameSource = Common.ObjectAttributeValue(RefToSource, "PredefinedDataName");
			Except
				PredefinedNameSource = "";
			EndTry;
			
		Else
			
			PredefinedNameSource = "";
			
		EndIf;
		
		If NOT IsBlankString(PredefinedNameSource)
			AND ValueMapItemCount > 0 Then
			
			PredefinedItemName = ValueMap[RefToSource];
			
		Else
			PredefinedItemName = Undefined;				
		EndIf;
		
	EndIf;
	
	If PredefinedItemName <> Undefined Then
		ValueMapItemCount = 0;
	EndIf;			
	
	DontExportByValueMap = (ValueMapItemCount = 0);
	
	If Not DontExportByValueMap Then
		
		// If value mapping does not contain values, exporting mapping in the ordinary way.
		RefNode = ValueMap[RefToSource];
		If RefNode = Undefined Then
			
			// Perhaps, this is a conversion from enumeration into enumeration and
			// required VCR is not found. Exporting an empty reference.
			If PropertyStructure.TypeName = "Enum"
				AND StrFind(OCR.Destination, "EnumRef.") > 0 Then
				
				// Error writing to execution log.
				WP = ExchangeProtocolRecord();
				WP.OCRName              = OCRName;
				WP.Value            = Source;
				WP.ValueType         = PropertyStructure.RefTypeString;
				WP.ErrorMessageCode = 71;
				WP.Text               = NStr("ru = 'В правиле конвертации значений (ПКЗ) необходимо сопоставить значение Источника значению Приемника.
													|Если подходящего значения приемника нет, то указать пустое значение.'; 
													|en = 'The Source value must be mapped to the Destination value in the value conversion rule.
													|If there is no appropriate destination value, specify an empty value.'; 
													|pl = 'W regule konwersji wartości (VCR) należy dopasować wartość Źródła do wartości Odbiornika.
													|Jeśli nie ma odpowiedniej wartości odbiornika, podaj pustą wartość.';
													|de = 'Der Quellwert sollte in der Wertumrechnungsregel auf den Zielwert abgebildet werden.
													|Geben Sie einen leeren Wert an, wenn es keinen passenden Zielwert gibt.';
													|ro = 'Valoarea sursă ar trebui să fie mapată cu valoarea Destinație din regula de conversie a valorii.
													|Specificați o valoare goală, dacă nu există o valoare de destinație corespunzătoare.';
													|tr = 'Kaynak değer, değer dönüştürme kuralındaki Hedef değerle eşlenmelidir. 
													|Uygun bir hedef değer yoksa, boş bir değer belirtin.'; 
													|es_ES = 'El valor Fuente debe ser mapeado con el valor de Destino en la regla de conversión de valor.
													|Especifique un valor vacío, si no hay un valor de destino apropiado.'");
				//
				WriteToExecutionProtocol(71, WP);
				
				If ExportStackRow <> Undefined Then
					DataExportCallStack.Delete(ExportStackRow);				
				EndIf;
				
				CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
				
				Return Undefined;
				
			Else
				
				DontExportByValueMap = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DontExportSubordinateObjects = GetRefNodeOnly OR NOT ExportSubordinateObjectRefs;
	
	MustRememberObject = RememberExported AND (Not AllObjectsExported);
	
	If DontExportByValueMap Then
		
		If OCR.SearchProperties.Count() > 0 
			OR PredefinedItemName <> Undefined Then
			
			//	Creating reference node
			RefNode = CreateNode("Ref");
						
			If MustRememberObject Then
				
				If IsRuleWithGlobalObjectExport Then
					SetAttribute(RefNode, "Gsn", SN);
				Else
					SetAttribute(RefNode, "Sn", SN);
				EndIf;
				
			EndIf;
			
			If DontCreateIfNotFound Then
				SetAttribute(RefNode, "DoNotCreateIfNotFound", DontCreateIfNotFound);
			EndIf;
			
			If OCR.SearchBySearchFieldsIfNotFoundByID Then
				SetAttribute(RefNode, "ContinueSearch", True);
			EndIf;
			
			If RecordObjectChangeAtSenderNode Then
				SetAttribute(RefNode, "RecordObjectChangeAtSenderNode", RecordObjectChangeAtSenderNode);
			EndIf;
			
			WriteExchangeObjectPriority(ExchangeObjectsPriority, RefNode);
			
			If DontReplaceObjectCreatedInDestinationInfobase Then
				SetAttribute(RefNode, "DoNotReplaceObjectCreatedInDestinationInfobase", DontReplaceObjectCreatedInDestinationInfobase);				
			EndIf;
			
			If ExportObjectProperties = True Then
			
				ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, OCR.SearchProperties, 
					RefNode, , PredefinedItemName, True, 
					True, ExportingObject, ExportedDataKey, , RefValueInAnotherIB,,, ObjectExportStack);
					
			EndIf;
			
			RefNode.WriteEndElement();
			RefNode = RefNode.Close();
			
			If MustRememberObject Then
				
				ExportedObjectRow.RefNode = RefNode;															
								
			EndIf;			
			
		Else
			RefNode = SN;
		EndIf;
		
	Else
		
		// Searching in the value map by VCR.
		If RefNode = Undefined Then
			
			// Error writing to execution log.
			WP = ExchangeProtocolRecord();
			WP.OCRName              = OCRName;
			WP.Value            = Source;
			WP.ValueType         = TypeOf(Source);
			WP.ErrorMessageCode = 71;
			
			WriteToExecutionProtocol(71, WP);
			
			If ExportStackRow <> Undefined Then
				DataExportCallStack.Delete(ExportStackRow);				
			EndIf;
			
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Undefined;
		EndIf;
		
		If RememberExported Then
			ExportedObjectRow.RefNode = RefNode;			
		EndIf;
		
		If ExportStackRow <> Undefined Then
			DataExportCallStack.Delete(ExportStackRow);				
		EndIf;
		
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf;

		
	If GetRefNodeOnly
		Or AllObjectsExported Then
		
		If ExportStackRow <> Undefined Then
			DataExportCallStack.Delete(ExportStackRow);				
		EndIf;
		
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf; 

	If Destination = Undefined Then
		
		Destination = CreateNode("Object");
		
		If NOT ExportRegisterRecordSetRow Then
			
			If IsRuleWithGlobalObjectExport Then
				SetAttribute(Destination, "Gsn", SN);
			Else
				SetAttribute(Destination, "Sn", SN);
			EndIf;
			
			SetAttribute(Destination, "Type", 			OCR.Destination);
			SetAttribute(Destination, "RuleName",	OCR.Name);
			
			If NOT IsBlankString(ConstantNameForExport) Then
				
				SetAttribute(Destination, "ConstantName", ConstantNameForExport);
				
			EndIf;
			
			WriteExchangeObjectPriority(ExchangeObjectsPriority, Destination);
			
			If DontReplaceObjectOnImport Then
				SetAttribute(Destination, "DoNotReplace",	"true");
			EndIf;
			
			If Not IsBlankString(AutonumberingPrefix) Then
				SetAttribute(Destination, "AutonumberingPrefix",	AutonumberingPrefix);
			EndIf;
			
			If Not IsBlankString(WriteMode) Then
				
				SetAttribute(Destination, "WriteMode",	WriteMode);
				If Not IsBlankString(PostingMode) Then
					SetAttribute(Destination, "PostingMode",	PostingMode);
				EndIf;
				
			EndIf;
			
			If TypeOf(RefNode) <> NumberType Then
				AddSubordinateNode(Destination, RefNode);
			EndIf;
		
		EndIf;
		
	EndIf;

	// OnExport handler
	StandardProcessing = True;
	Cancel = False;
	
	If OCR.HasOnExportHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				Execute_OCR_HandlerOnObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName,
														   OCR, ExportedObjects, ExportedDataKey, Cancel,
														   StandardProcessing, Destination, RefNode);
				
			Else
				
				Execute(OCR.OnExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(42, ErrorDescription(), OCR, Source, "OnExportObject");
		EndTry;
				
		If Cancel Then	//	Canceling writing the object to a file.
			
			If ExportStackRow <> Undefined Then
				DataExportCallStack.Delete(ExportStackRow);				
			EndIf;
			
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return RefNode;
		EndIf;
		
	EndIf;

	// Exporting properties
	If StandardProcessing Then
		
		If NOT IsBlankString(ConstantNameForExport) Then
			
			PropertyForExportArray = New Array();
			
			TableRow = OCR.Properties.Find(ConstantNameForExport, "Source");
			
			If TableRow <> Undefined Then
				PropertyForExportArray.Add(TableRow);
			EndIf;
			
		Else
			
			PropertyForExportArray = OCR.Properties;
			
		EndIf;
		
		If ExportObjectProperties Then
		
			ExportProperties(
				Source,                 // Source
				Destination,                 // Destination
				IncomingData,           // IncomingData
				OutgoingData,          // OutgoingData
				OCR,                      // OCR
				PropertyForExportArray, // PCRCollection
				,                         // PropertiesCollectionNode = Undefined
				,                         // CollectionObject = Undefined
				,                         // PredefinedItemName = Undefined
				True,                   // Val ExportOnlyRef = True
				False,                     // Val IsRefExport = False
				ExportingObject,        // Val ExportingObject = False
				ExportedDataKey,    // RefSearchKey = ""
				,                         // DontUseRulesWithGlobalExportAndDontRememberExported = False
				RefValueInAnotherIB,  // RefValueInAnotherIB
				TempFileList,    // TempFilesList = Undefined
				ExportRegisterRecordSetRow, // ExportRegisterRecordSetRow = False
				ObjectExportStack);
				
			EndIf;
			
		EndIf;    
		
		// AfterExport handler
		
		If OCR.HasAfterExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_OCR_HandlerAfterObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
																 ExportedObjects, ExportedDataKey, Cancel, Destination, RefNode);
					
				Else
					
					Execute(OCR.AfterExport);
					
				EndIf;
				
			Except
				WriteInfoOnOCRHandlerExportError(43, ErrorDescription(), OCR, Source, "AfterExportObject");
			EndTry;
			
			If Cancel Then	//	Canceling writing the object to a file.
				
				If ExportStackRow <> Undefined Then
					DataExportCallStack.Delete(ExportStackRow);				
				EndIf;
				
				CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
				Return RefNode;
			EndIf;
		EndIf;
		
		
	//	Writing the object to a file
	
	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
	
	If ParentNode <> Undefined Then
		
		Destination.WriteEndElement();
		
		ParentNode.WriteRaw(Destination.Close());
		
	Else
	
		If TempFileList = Undefined Then
			
			Destination.WriteEndElement();
			WriteToFile(Destination);
			
		Else
			
			WriteToFile(Destination);
		
			TempFile = New TextReader;
			For each TempFileName In TempFileList Do
				
				Try
					TempFile.Open(TempFileName, TextEncoding.UTF8);
				Except
					Continue;
				EndTry;
				
				TempFileLine = TempFile.ReadLine();
				While TempFileLine <> Undefined Do
					WriteToFile(TempFileLine);	
				    TempFileLine = TempFile.ReadLine();
				EndDo;
				
				TempFile.Close();
				
				// Deleting files
				DeleteFiles(TempFileName); 
			EndDo;
			
			WriteToFile("</Object>");
			
		EndIf;
		
		If MustRememberObject
			AND IsRuleWithGlobalObjectExport Then
				
			ExportedObjectRow.RefNode = SN;
			
		EndIf;
		
		If CurrentNestingLevelExportByRule = 0 Then
			
			SetExportedToFileObjectFlags();
			
		EndIf;
		
		UpdateDataInDataToExport();		
		
	EndIf;
	
	If ExportStackRow <> Undefined Then
		DataExportCallStack.Delete(ExportStackRow);				
	EndIf;
	
	// AfterExportToFile handler
	If OCR.HasAfterExportToFileHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				Execute_OCR_HandlerAfterObjectExportToExchangeFile(ExchangeFile, Source, IncomingData, OutgoingData,
																		OCRName, OCR, ExportedObjects, Destination, RefNode);
				
			Else
				
				Execute(OCR.AfterExportToFile);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(79, ErrorDescription(), OCR, Source, "HasAfterExportToFileHandler");
		EndTry;
		
	EndIf;
	
	Return RefNode;
	
EndFunction

// Calls the BeforeExport and AfterExport rules to export the register.
//
// Parameters:
//         RecordSetForExport - RegisterRecordSet - it might also be Structure containing filter.
//         Rule - ValueTableRow - object conversion rules tables.
//         IncomingData - Arbitrary - incoming data for the conversion rule.
//         DontExportPropertyObjectsByRefs - Boolean - a flag for property export by references.
//         OCRName - String - a conversion rule name.
//
// Returns:
//         Boolean - a flag of successful export.
//
Function ExportRegister(RecordSetForExport,
							Rule = Undefined,
							IncomingData = Undefined,
							DontExportPropertyObjectsByRefs = False,
							OCRName = "") Export
							
	OCRName			= "";
	Cancel			= False;
	OutgoingData	= Undefined;
		
	FireEventsBeforeExportObject(RecordSetForExport, Rule, Undefined, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);
		
	If Cancel Then
		Return False;
	EndIf;	
	
	
	UnloadRegister(RecordSetForExport, 
					 Undefined, 
					 OutgoingData, 
					 DontExportPropertyObjectsByRefs, 
					 OCRName,
					 Rule);
		
	FireEventsAfterExportObject(RecordSetForExport, Rule, Undefined, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);	
		
	Return Not Cancel;							
							
EndFunction

// Generates the query result for data clearing export.
//
//  Parameters:
//       Properties                      - Structure - contains object properties.
//       TypeName                       - String - an object type name.
//       SelectionForDataClearing       - Boolean - a flag showing whether selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean - a flag showing whether direct deletion is required.
//       SelectAllFields               - Boolean - a flag showing whether it is necessary to select all fields.
//
//  Returns:
//       QueryResult or Undefined - a result of the query to export data cleaning.
//
Function QueryResultForExpotingDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export 
	
	PermissionRow = ?(ExportAllowedObjectsOnly, " ALLOWED ", "");
	
	FieldSelectionString = ?(SelectAllFields, " * ", "	ObjectForExport.Ref AS Ref ");
	
	If TypeName = "Catalog" 
		OR TypeName = "ChartOfCharacteristicTypes" 
		OR TypeName = "ChartOfAccounts" 
		OR TypeName = "ChartOfCalculationTypes" 
		OR TypeName = "AccountingRegister"
		OR TypeName = "ExchangePlan"
		OR TypeName = "Task"
		OR TypeName = "BusinessProcess" Then
		
		Query = New Query();
		
		If TypeName = "AccountingRegister" Then
			
			FieldSelectionString = "*";	
			
		EndIf;
		
		Query.Text = "SELECT " + PermissionRow + "
		         |	" + FieldSelectionString + "
		         |FROM
		         |	" + TypeName + "." + Properties.Name + " AS ObjectForExport
				 |
				 |";
		
		If SelectionForDataClearing
			AND DeleteObjectsDirectly Then
			
			If (TypeName = "Catalog"
				OR TypeName = "ChartOfCharacteristicTypes") Then
				
				If TypeName = "Catalog" Then
					HierarchyRequired = Metadata.Catalogs[Properties.Name].Hierarchical;
				Else
					HierarchyRequired = Metadata.ChartsOfCharacteristicTypes[Properties.Name].Hierarchical;
				EndIf;
				
				If HierarchyRequired Then
					
					Query.Text = Query.Text + "
					|	WHERE ObjectForExport.Parent = &Parent
					|";
					
					Query.SetParameter("Parent", Properties.Manager.EmptyRef());
				
				EndIf;
				
			EndIf;
			
		EndIf;		 
					
	ElsIf TypeName = "Document" Then
		
		Query = New Query();
		
		ResultingRestrictionByDate = "";
				
		Query.Text = "SELECT " + PermissionRow + "
		         |	" + FieldSelectionString + "
		         |FROM
		         |	" + TypeName + "." + Properties.Name + " AS ObjectForExport
				 |
				 |" + ResultingRestrictionByDate;
					 
											
	ElsIf TypeName = "InformationRegister" Then
		
		Nonperiodical = NOT Properties.Periodic;
		SubordinatedToRecorder = Properties.SubordinateToRecorder;
		
		Query = New Query();
		
		ResultingRestrictionByDate = "";
				
		SelectionFieldSupplementionStringSubordinateToRegistrar = ?(NOT SubordinatedToRecorder, ", NULL AS Active,
		|	NULL AS Recorder,
		|	NULL AS LineNumber", "");
		
		SelectionFieldSupplementionStringPeriodicity = ?(Nonperiodical, ", NULL AS Period", "");
		
		Query.Text = "SELECT " + PermissionRow 
			+ "
			| *
			| " + SelectionFieldSupplementionStringSubordinateToRegistrar + "
			| " + SelectionFieldSupplementionStringPeriodicity + "
			|FROM
			| " + TypeName + "." + Properties.Name + " AS ObjectForExport
			|" + ResultingRestrictionByDate;
		
	Else
		
		Return Undefined;
					
	EndIf;
	
	
	Return Query.Execute();
	
EndFunction

// Generates selection for data clearing export.
//
//  Parameters:
//       Properties                      - Structure - contains object properties.
//       TypeName                       - String - an object type name.
//       SelectionForDataClearing       - Boolean - a flag showing whether selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean - a flag showing whether direct deletion is required.
//       SelectAllFields               - Boolean - a flag showing whether it is necessary to select all fields.
//
//  Returns:
//       QueryResultSelection or Undefined - generated selection for data clearing.
//
Function SelectionForExpotingDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export
	
	QueryResult = QueryResultForExpotingDataClearing(Properties, TypeName, 
			SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
			
	If QueryResult = Undefined Then
		Return Undefined;
	EndIf;
			
	Selection = QueryResult.Select();
	
	
	Return Selection;		
	
EndFunction

// Exports data according to the specified rule.
//
// Parameters:
//  Rule - ValueTableRow - object data export rule reference.
// 
Procedure ExportDataByRule(Rule) Export
	
	OCRName = Rule.ConversionRule;
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;


	If CommentObjectProcessingFlag Then
		
		MessageString = NStr("ru = 'ПРАВИЛО ВЫГРУЗКИ ДАННЫХ: %1 (%2)'; en = 'DATA EXPORT RULE: %1 (%2)'; pl = 'REGUŁA WYŁADUNKU DANYCH: %1(%2)';de = 'DATENEXPORT-REGEL: %1 (%2)';ro = 'REGULA DE EXPORT A DATELOR: %1 (%2)';tr = 'VERİ DIŞA AKTARMA KURALI : %1 (%2)'; es_ES = 'REGLA DE EXPORTACIÓN DE DATOS: %1 (%2)'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, TrimAll(Rule.Name), TrimAll(Rule.Description));
		WriteToExecutionProtocol(MessageString, , False, , 4);
		
	EndIf;
		
	
	// BeforeProcess handle
	Cancel			= False;
	OutgoingData	= Undefined;
	DataSelection	= Undefined;
	
	If Not IsBlankString(Rule.BeforeProcess) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_DER_BeforeProcessRule(Cancel, OCRName, Rule, OutgoingData, DataSelection);
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(31, ErrorDescription(), Rule.Name, "BeforeProcessDataExport");
			
		EndTry;
		
		If Cancel Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// Standard selection with filter.
	If Rule.DataFilterMethod = "StandardSelection" AND Rule.UseFilter Then

		Selection = SelectionForExportWithRestrictions(Rule);
		
		While Selection.Next() Do
			ExportSelectionObject(Selection.Ref, Rule, , OutgoingData);
		EndDo;

	// Standard selection without filter.
	ElsIf (Rule.DataFilterMethod = "StandardSelection") Then
		
		Properties	= Managers[Rule.SelectionObject];
		TypeName		= Properties.TypeName;
		
		If TypeName = "Constants" Then
			
			ExportConstantsSet(Rule, Properties, OutgoingData);		
			
		Else
			
			IsNotReferenceType = TypeName =  "InformationRegister" 
				OR TypeName = "AccountingRegister";
			
			
			If IsNotReferenceType Then
					
				SelectAllFields = MustSelectAllFields(Rule);
				
			Else
				
				// Getting only the reference
				SelectAllFields = False;	
				
			EndIf;	
				
			
			Selection = SelectionForExpotingDataClearing(Properties, TypeName, , , SelectAllFields);
			
			If Selection = Undefined Then
				Return;
			EndIf;
			
			While Selection.Next() Do
				
				If IsNotReferenceType Then
					
					ExportSelectionObject(Selection, Rule, Properties, OutgoingData);
					
				Else
					
					ExportSelectionObject(Selection.Ref, Rule, Properties, OutgoingData);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then

		If DataSelection <> Undefined Then
			
			Selection = SelectionToExportByArbitraryAlgorithm(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
					
					ExportSelectionObject(Selection, Rule, , OutgoingData);
					
				EndDo;
				
			Else
				
				For each Object In DataSelection Do
					
					ExportSelectionObject(Object, Rule, , OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf;
			
	EndIf;

	
	// AfterProcess handler
	
	If Not IsBlankString(Rule.AfterProcess) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_DER_AfterProcessRule(OCRName, Rule, OutgoingData);
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(32, ErrorDescription(), Rule.Name, "AfterProcessDataExport");
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Export register by filter.
// 
// Parameters:
//         RecordSetForExport - Structure - contains filter or the register RecordSet.
//         Rule - ValueTableRow - from object conversion rules.
//         IncomingData - Arbitrary - incoming data for the conversion rule.
//         DontExportObjectsByRefs - Boolean - a flag for property export by references.
//         OCRName - String - a conversion rule name.
//         DataExportRule - ValueTableRow - from the data export rules table.
//
Procedure UnloadRegister(RecordSetForExport, 
							Rule = Undefined, 
							IncomingData = Undefined, 
							DontExportObjectsByRefs = False, 
							OCRName = "",
							DataExportRule = Undefined) Export
							
	OutgoingData = Undefined;						
							
	
	DetermineOCRByParameters(Rule, RecordSetForExport, OCRName);
	
	ExchangeObjectsPriority = Rule.ExchangeObjectsPriority;
	
	If TypeOf(RecordSetForExport) = Type("Structure") Then
		
		RecordSetFilter  = RecordSetForExport.Filter;
		RecordSetRows = RecordSetForExport.Rows;
		
	Else // RecordSet
		
		RecordSetFilter  = RecordSetForExport.Filter;
		RecordSetRows = RecordSetForExport;
		
	EndIf;
	
	// Writing filter first then record set Filter.
	// 
	
	Destination = CreateNode("RegisterRecordSet");
	
	RegisterRecordCount = RecordSetRows.Count();
		
	SnCounter = SnCounter + 1;
	SN        = SnCounter;
	
	SetAttribute(Destination, "Sn",			SN);
	SetAttribute(Destination, "Type", 			StrReplace(Rule.Destination, "InformationRegisterRecord.", "InformationRegisterRecordSet."));
	SetAttribute(Destination, "RuleName",	Rule.Name);
	
	WriteExchangeObjectPriority(ExchangeObjectsPriority, Destination);
	
	ExportingEmptySet = RegisterRecordCount = 0;
	If ExportingEmptySet Then
		SetAttribute(Destination, "BlankSet",	True);
	EndIf;
	
	Destination.WriteStartElement("Filter");
	
	SourceStructure = New Structure;
	PCRArrayForExport = New Array();
	
	For Each FIlterRow In RecordSetFilter Do
		
		If FIlterRow.Use = False Then
			Continue;
		EndIf;
		
		PCRRow = Rule.Properties.Find(FIlterRow.Name, "Source");
		
		If PCRRow = Undefined Then
			
			PCRRow = Rule.Properties.Find(FIlterRow.Name, "Destination");
			
		EndIf;
		
		If PCRRow <> Undefined
			AND  (PCRRow.DestinationKind = "Property"
			OR PCRRow.DestinationKind = "Dimension") Then
			
			PCRArrayForExport.Add(PCRRow);
			
			varKey = ?(IsBlankString(PCRRow.Source), PCRRow.Destination, PCRRow.Source);
			
			SourceStructure.Insert(varKey, FIlterRow.Value);
			
		EndIf;
		
	EndDo;
	
	// Adding filter parameters.
	For Each SearchPropertyRow In Rule.SearchProperties Do
		
		If IsBlankString(SearchPropertyRow.Destination)
			AND NOT IsBlankString(SearchPropertyRow.ParameterForTransferName) Then
			
			PCRArrayForExport.Add(SearchPropertyRow);	
			
		EndIf;
		
	EndDo;
	
	ExportProperties(SourceStructure, Undefined, IncomingData, OutgoingData, Rule, PCRArrayForExport, Destination, 
		, , True, , , , ExportingEmptySet);
	
	Destination.WriteEndElement();
	
	Destination.WriteStartElement("RecordSetRows");
	
	// Data set IncomingData = Undefined;
	For Each RegisterLine In RecordSetRows Do
		
		ExportSelectionObject(RegisterLine, DataExportRule, , IncomingData, DontExportObjectsByRefs, True, 
			Destination, , OCRName, FALSE);
				
	EndDo;
	
	Destination.WriteEndElement();
	
	Destination.WriteEndElement();
	
	WriteToFile(Destination);
	
	UpdateDataInDataToExport();
	
	SetExportedToFileObjectFlags();
	
EndProcedure

// Adds information on exchange types to xml file.
//
// Parameters:
//	Destination - a destination object XML node.
//	Type - String, Array - a single exported type or a list of string exported types.
//	AttributesList - Structure - key contains the attribute name.
//
Procedure ExportInformationAboutTypes(Destination, Type, AttributesList = Undefined) Export
	
	TypesNode = CreateNode("Types");
	
	If AttributesList <> Undefined Then
		For Each CollectionItem In AttributesList Do
			SetAttribute(TypesNode, CollectionItem.Key, CollectionItem.Value);
		EndDo;
	EndIf;
	
	If TypeOf(Type) = Type("String") Then
		deWriteElement(TypesNode, "Type", Type);
	Else
		For Each TypeString In Type Do
			deWriteElement(TypesNode, "Type", TypeString);
		EndDo;
	EndIf;
	
	AddSubordinateNode(Destination, TypesNode);
	
EndProcedure

// Creates a record about object deleting in exchange file.
//
// Parameters:
//	Reference - CatalogRef, DocumentRef - an object to be deleted.
//	DestinationType - String - contains a destination type string presentation.
//	SourceType - String - contains string presentation of the source type.
// 
Procedure WriteToFileObjectDeletion(Ref, Val DestinationType, Val SourceType) Export
	
	Destination = CreateNode("ObjectDeletion");
	
	SetAttribute(Destination, "DestinationType", DestinationType);
	SetAttribute(Destination, "SourceType", SourceType);
	
	SetAttribute(Destination, "UUID", Ref.UUID());
	
	Destination.WriteEndElement(); // ObjectDeletion
	
	WriteToFile(Destination);
	
EndProcedure

// Registers an object that is created during data export.
//
// Parameters:
//	Reference - CatalogRef, DocumentRef - an object to be registered.
// 
Procedure RegisterObjectCreatedDuringExport(Ref) Export
	
	If CreatedOnExportObjects().Find(Ref) = Undefined Then
		
		CreatedOnExportObjects().Add(Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GetData

// Returns a values table containing references to documents for deferred posting and dates of these 
// documents for the preliminary sorting.
//
// Returns:
//  ValueTable - contains references to documents for deferred posting. Columns:
//    * DocumentRef - DocumentRef - a reference to the imported document thet requires deferred posting.
//    * DocumentDate  - Date - an imported document date for the preliminary table sorting.
//
Function DocumentsForDeferredPosting() Export
	
	If TypeOf(DocumentsForDeferredPostingField) <> Type("ValueTable") Then
		
		// Initializing a table for the deferred document posting.
		DocumentsForDeferredPostingField = New ValueTable;
		DocumentsForDeferredPostingField.Columns.Add("DocumentRef");
		DocumentsForDeferredPostingField.Columns.Add("DocumentDate", deTypeDetails("Date"));
		
	EndIf;
	
	Return DocumentsForDeferredPostingField;
	
EndFunction

// Returns the flag that shows whether it is import to the infobase.
// 
// Returns:
//	Boolean - a flag indicating data import mode.
// 
Function DataImportToInfobaseMode() Export
	
	Return IsBlankString(DataImportMode) OR Upper(DataImportMode) = Upper("ImportToInfobase");
	
EndFunction

// Adds the row containing the reference to the document to post and its date for the preliminary 
// sorting to the deferred posting table.
//
// Parameters:
//  ObjectRef         - DocumentRef - an object that requires deferred posting.
//  ObjectDate - Date - a document date.
//  AdditionalProperties - Structure - additional properties of the object being written.
//
Procedure AddObjectForDeferredPosting(ObjectRef, ObjectDate, AdditionalProperties) Export
	
	DeferredPostingTable = DocumentsForDeferredPosting();
	NewRow = DeferredPostingTable.Add();
	NewRow.DocumentRef = ObjectRef;
	NewRow.DocumentDate  = ObjectDate;
	
	AdditionalPropertiesForDeferredPosting().Insert(ObjectRef, AdditionalProperties);
	
EndProcedure

// Writes an object to the infobase.
//
// Parameters:
//	Object - CatalogObject, DocumentObject - an object to be written.
//	Type - String - an object type as a string.
//	WriteObject - Boolean - a flag showing whether the object was written.
//	SendBack - Boolean - a flag showing whether the data item status of this infobase must be passed 
//                           to the correspondent infobase.
// 
Procedure WriteObjectToIB(Object, Type, WriteObject = False, Val SendBack = False) Export
	
	// Do not write to VT in import mode.
	If DataImportToValueTableMode() Then
		Return;
	EndIf;
		
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject(Object.Metadata().FullName());
		Else
			IsSeparatedMetadataObject = False;
		EndIf;
		
		If Not IsSeparatedMetadataObject Then 
		
			ErrorMessageString = NStr("ru = 'Попытка изменения неразделенных данных (%1) в разделенном сеансе.'; en = 'An attempt to change shared data (%1) in a separated session.'; pl = 'Próba zmiany udostępnionych danych (%1) w sesji podzielonej.';de = 'Versuch, geteilte Daten (%1) in einer Split-Sitzung zu ändern.';ro = 'Încercarea de a schimba datele partajate (%1) în sesiunea separată.';tr = 'Bölünmemiş verileri (%1) bölünmüş modda değiştirme girişimi'; es_ES = 'Intentando cambiar los datos compartidos (%1) en la sesión de división.'");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, Object.Metadata().FullName());
			
			WriteToExecutionProtocol(ErrorMessageString,, False,,,, Enums.ExchangeExecutionResults.CompletedWithWarnings);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// Setting a data import mode for the object.
	SetDataExchangeLoad(Object,, SendBack);
	
	// Checking for a deletion mark of the predefined item.
	RemoveDeletionMarkFromPredefinedItem(Object, Type);
	
	BeginTransaction();
	Try
		
		// Writing an object to the transaction.
		Object.Write();
		
		InfobaseObjectsMaps = Undefined;
		If Object.AdditionalProperties.Property("InfobaseObjectsMaps", InfobaseObjectsMaps)
			AND InfobaseObjectsMaps <> Undefined Then
			
			InfobaseObjectsMaps.SourceUUID = Object.Ref;
			
			InformationRegisters.InfobaseObjectsMaps.AddRecord(InfobaseObjectsMaps);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteObject = False;
		
		ErrorMessageString = WriteErrorInfoToProtocol(26, DetailErrorDescription(ErrorInfo()), Object, Type);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

// Cancels an infobase object posting.
//
// Parameters:
//	Objects - DocumentObject - a document to cancel posting.
//	Type - String - an object type as a string.
//	WriteObject - Boolean - a flag showing whether the object was written.
//
Procedure UndoObjectPostingInIB(Object, Type, WriteObject = False) Export
	
	If DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
		Enums.DataExchangeIssuesTypes.UnpostedDocument);
	
	// Setting a data import mode for the object.
	SetDataExchangeLoad(Object);
	
	BeginTransaction();
	Try
		
		// Canceling a document posting.
		Object.Posted = False;
		Object.Write();
		
		InfobaseObjectsMaps = Undefined;
		If Object.AdditionalProperties.Property("InfobaseObjectsMaps", InfobaseObjectsMaps)
			AND InfobaseObjectsMaps <> Undefined Then
			
			InfobaseObjectsMaps.SourceUUID = Object.Ref;
			
			InformationRegisters.InfobaseObjectsMaps.AddRecord(InfobaseObjectsMaps);
		EndIf;
		
		DataExchangeServer.DeleteDocumentRegisterRecords(Object);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteObject = False;
		
		ErrorMessageString = WriteErrorInfoToProtocol(26, DetailErrorDescription(ErrorInfo()), Object, Type);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

// Sets deletion mark.
//
// Parameters:
//	Object - CatalogObject, DocumentObject - an object to be marked.
//	DeletionMark - Boolean - deletion mark flag.
//	ObjectTypeName - String - an object type as a string.
//
Procedure SetObjectDeletionMark(Object, DeletionMark, ObjectTypeName) Export
	
	If (DeletionMark = Undefined AND Object.DeletionMark <> True)
		Or DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	If ObjectTypeName = "Document" Then
		SetDataExchangeLoad(Object, False);
		InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
			Enums.DataExchangeIssuesTypes.UnpostedDocument);
	EndIf;
	
	MarkToSet = ?(DeletionMark <> Undefined, DeletionMark, False);
	
	SetDataExchangeLoad(Object);
		
	// For hierarchical object the deletion mark is set only for the current object.
	If ObjectTypeName = "Catalog"
		OR ObjectTypeName = "ChartOfCharacteristicTypes"
		OR ObjectTypeName = "ChartOfAccounts" Then
		
		If Not Object.Predefined Then
			
			Object.SetDeletionMark(MarkToSet, False);
			
		EndIf;
		
	Else
		
		Object.SetDeletionMark(MarkToSet);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions

// Registers a warning in the event log.
// If during data exchange this procedure is executed, the data exchange is not stopped.
// After exchange end the exchange status in the monitor have the value "Warning" if errors does not 
// occur.
//
// Parameters:
//  Warning - String - a warning text that must be registered.
//            Information, warnings, and errors that occur during data exchange are recorded in the event log.
// 
Procedure RecordWarning(Warning) Export
	
	WriteToExecutionProtocol(Warning,,False,,,, Enums.ExchangeExecutionResults.CompletedWithWarnings);
	
EndProcedure

// Sets the mark status for subordinate rows of the value tree row.
// Depending on the mark of the current row.
//
// Parameters:
//  CurRow - ValueTreeRow - whose items must be marked.
//  Attribute - String - a name of a tree item that enables marking.
// 
Procedure SetSubordinateMarks(curRow, Attribute) Export

	SubordinateElements = curRow.Rows;

	If SubordinateElements.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Row In SubordinateElements Do
		
		If Row.BuilderSettings = Undefined 
			AND Attribute = "UseFilter" Then
			
			Row[Attribute] = 0;
			
		Else
			
			Row[Attribute] = curRow[Attribute];
			
		EndIf;
		
		SetSubordinateMarks(Row, Attribute);
		
	EndDo;
		
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete: Use the GetQueryResultForExportDataClearing function.
// Generates the query result for data clearing export.
//
//  Parameters:
//       Properties                      - Structure - contains object properties.
//       TypeName                       - String - an object type name.
//       SelectionForDataClearing       - Boolean - a flag showing whether selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean - a flag showing whether direct deletion is required.
//       SelectAllFields               - Boolean - a flag showing whether it is necessary to select all fields.
//
//  Returns:
//       QueryResult or Undefined - a result of the query to export data cleaning.
//
Function GetQueryResultForExportDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export 
	
	Return QueryResultForExpotingDataClearing(Properties, TypeName,
		SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
	
EndFunction

// Obsolete: Use the SelectionForExpotingDataClearing function
// Generates selection for data clearing export.
//
//  Parameters:
//       Properties                      - Structure - contains object properties.
//       TypeName                       - String - an object type name.
//       SelectionForDataClearing       - Boolean - a flag showing whether selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean - a flag showing whether direct deletion is required.
//       SelectAllFields               - Boolean - a flag showing whether it is necessary to select all fields.
//
//  Returns:
//       QueryResultSelection or Undefined - generated selection for data clearing.
//
Function GetSelectionForDataClearingExport(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export
	
	Return SelectionForExpotingDataClearing(Properties, TypeName,
		SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ExportProperties

// Function for retrieving property: a flag that shows a data exchange execution error.
//
// Returns:
//  Boolean - a flag that shows a data exchange execution error.
//
Function ErrorFlag() Export
	
	If TypeOf(ErrorFlagField) <> Type("Boolean") Then
		
		ErrorFlagField = False;
		
	EndIf;
	
	Return ErrorFlagField;
	
EndFunction

// Function for retrieving property: the result of data exchange.
//
// Returns:
//  EnumRef.ExchangeExecutionResults - the result of data exchange execution.
//
Function ExchangeExecutionResult() Export
	
	If TypeOf(ExchangeResultField) <> Type("EnumRef.ExchangeExecutionResults") Then
		
		ExchangeResultField = Enums.ExchangeExecutionResults.Completed;
		
	EndIf;
	
	Return ExchangeResultField;
	
EndFunction

// Function for retrieving property: the result of data exchange.
//
// Returns:
//  String - string presentation of the EnumRef.ExchangeExecutionResults enumeration value.
//
Function ExchangeExecutionResultString() Export
	
	Return Common.EnumValueName(ExchangeExecutionResult());
	
EndFunction

// Function for retrieving properties: map with data tables of the received data exchange message.
//
// Returns:
//  Map - map data tables with incoming exchange message.
//
Function DataTablesExchangeMessages() Export
	
	If TypeOf(ExchangeMessageDataTableField) <> Type("Map") Then
		
		ExchangeMessageDataTableField = New Map;
		
	EndIf;
	
	Return ExchangeMessageDataTableField;
	
EndFunction

// Function for retrieving properties: a value table with incoming exchange message statistics and extra information.
//
// Returns:
//  ValueTable - a value table with statistical and extra information on the incoming exchange message.
//
Function PackageHeaderDataTable() Export
	
	If TypeOf(PackageHeaderDataTableField) <> Type("ValueTable") Then
		
		PackageHeaderDataTableField = New ValueTable;
		
		Columns = PackageHeaderDataTableField.Columns;
		
		Columns.Add("ObjectTypeString",            deTypeDetails("String"));
		Columns.Add("ObjectCountInSource", deTypeDetails("Number"));
		Columns.Add("SearchFields",                   deTypeDetails("String"));
		Columns.Add("TableFields",                  deTypeDetails("String"));
		
		Columns.Add("SourceTypeString", deTypeDetails("String"));
		Columns.Add("DestinationTypeString", deTypeDetails("String"));
		
		Columns.Add("SynchronizeByID", deTypeDetails("Boolean"));
		Columns.Add("IsObjectDeletion", deTypeDetails("Boolean"));
		Columns.Add("IsClassifier", deTypeDetails("Boolean"));
		Columns.Add("UsePreview", deTypeDetails("Boolean"));
		
	EndIf;
	
	Return PackageHeaderDataTableField;
	
EndFunction

// Function for retrieving properties: a data exchange error message string.
//
// Returns:
//  String - a string containing an error message on exchange data.
//
Function ErrorMessageString() Export
	
	If TypeOf(ErrorMessageStringField) <> Type("String") Then
		
		ErrorMessageStringField = "";
		
	EndIf;
	
	Return ErrorMessageStringField;
	
EndFunction

// Function for retrieving property: the number of imported objects.
//
// Returns:
//  Number - number of imported objects.
//
Function ImportedObjectCounter() Export
	
	If TypeOf(ImportedObjectCounterField) <> Type("Number") Then
		
		ImportedObjectCounterField = 0;
		
	EndIf;
	
	Return ImportedObjectCounterField;
	
EndFunction

// Function for retrieving property: the amount of exported objects.
//
// Returns:
//  Number - number of exported objects.
//
Function ExportedObjectCounter() Export
	
	If TypeOf(ExportedObjectCounterField) <> Type("Number") Then
		
		ExportedObjectCounterField = 0;
		
	EndIf;
	
	Return ExportedObjectCounterField;
	
EndFunction

#EndRegion

#Region DataExport

// Exports data.
// -- All objects are exported to one file.
// -- The following is exported to a file header:
//	 - exchange rules.
//	 - information on data types.
//	 - exchange data (exchange plan name, node codes, message numbers (confirmation)).
//
// Parameters:
//      DataProcessorForDataImport - DataProcessorObject.InfobaseObjectsConversion in COM connection.
Procedure RunDataExport(DataProcessorForDataImport = Undefined) Export
	
	SetErrorFlag(False);
	
	ErrorMessageStringField = "";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	ExportedByRefObjectsField = Undefined;
	CreatedOnExportObjectsField = Undefined;
	ExportedByRefMetadataObjectsField = Undefined;
	ObjectsRegistrationRulesField = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	DataImportDataProcessorField = DataProcessorForDataImport;
	
	InitializeKeepExchangeProtocol();
	
	// Opening the exchange file
	If IsExchangeOverExternalConnection() Then
		ExchangeFile = New TextWriter;
	Else
		
		If IsMessageImportToMap() Then
			ExchangeFileName = GetTempFileName("xml");
		EndIf;
		
		OpenExportFile();
	EndIf;
	
	If ErrorFlag() Then
		ExchangeFile = Undefined;
		FinishKeepExchangeProtocol();
		Return;
	EndIf;
	
	SecurityProfileName = InitializeDataProcessors();
	
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	If IsExchangeOverExternalConnection() Then
		
		DataProcessorForDataImport().ExternalConnectionBeforeDataImport();
		
		DataProcessorForDataImport().ImportExchangeRules(XMLRules, "String");
		
		If DataProcessorForDataImport().ErrorFlag() Then
			
			MessageString = NStr("ru = 'Ошибка в базе-корреспонденте: %1'; en = 'Peer infobase error: %1'; pl = 'Błąd w bazie-korespondencie: %1';de = 'Es liegt ein Fehler in der entsprechenden Datenbank vor: %1';ro = 'Eroare în baza-corespondentă: %1';tr = 'Muhabir tabanındaki hata: %1'; es_ES = 'Error en la base-correspondiente: %1'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DataProcessorForDataImport().ErrorMessageString());
			WriteToExecutionProtocol(MessageString);
			FinishKeepExchangeProtocol();
			Return;
			
		EndIf;
		
		Cancel = False;
		
		DataProcessorForDataImport().ExternalConnectionConversionHandlerBeforeDataImport(Cancel);
		
		If Cancel Then
			FinishKeepExchangeProtocol();
			DisableDataProcessorForDebug();
			Return;
		EndIf;
		
	Else
		
		// Writing the exchange rules to the file.
		ExchangeFile.WriteLine(XMLRules);
		
	EndIf;
	
	// EXPORTING DATA.
	Try
		ExecuteExport();
	Except
		WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
		FinishKeepExchangeProtocol();
		ExchangeFile = Undefined;
		ExportedByRefObjectsField = Undefined;
		CreatedOnExportObjectsField = Undefined;
		ExportedByRefMetadataObjectsField = Undefined;
		Return;
	EndTry;
	
	If IsExchangeOverExternalConnection() Then
		
		If Not ErrorFlag() Then
			
			DataProcessorForDataImport().ExternalConnectionAfterDataImport();
			
		EndIf;
		
	Else
		
		// Closing the exchange file
		CloseFile();
		
	EndIf;
	
	FinishKeepExchangeProtocol();
	
	If IsMessageImportToMap() Then
		
		TextDocument = New TextDocument;
		TextDocument.Read(ExchangeFileName);
		
		DataProcessorForDataImport().PutMessageForDataMapping(TextDocument.GetText());
		
		TextDocument = Undefined;
		
		DeleteFiles(ExchangeFileName);
		
	EndIf;
	
	// Resetting modal variables before storing the data processor to the platform cache.
	ExportedByRefObjectsField = Undefined;
	CreatedOnExportObjectsField = Undefined;
	ExportedByRefMetadataObjectsField = Undefined;
	DisableDataProcessorForDebug();
	ExchangeFile = Undefined;
	
EndProcedure

#EndRegion

#Region DataImport

// Imports data from the exchange message file.
// Data is imported to the infobase.
//
// Parameters:
// 
Procedure RunDataImport() Export
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	MessageReader = Undefined;
	Try
		DataImportMode = "ImportToInfobase";
		
		ErrorMessageStringField = "";
		DataExchangeStateField = Undefined;
		ExchangeResultField = Undefined;
		DataForImportTypeMapField = Undefined;
		ImportedObjectCounterField = Undefined;
		DocumentsForDeferredPostingField = Undefined;
		ObjectsForDeferredPostingField = Undefined;
		DocumentsForDeferredPostingMap = Undefined;
		ExchangePlanNodePropertyField = Undefined;
		IncomingExchangeMessageFormatVersionField = Undefined;
		HasObjectRegistrationDataAdjustment = False;
		HasObjectChangeRecordData = False;
		
		GlobalNotWrittenObjectStack = New Map;
		LastSearchByRefNumber = 0;
		
		InitManagersAndMessages();
		
		SetErrorFlag(False);
		
		InitializeCommentsOnDataExportAndImport();
		
		InitializeKeepExchangeProtocol();
		
		CustomSearchFieldInfoOnDataImport = New Map;
		
		AdditionalSearchParameterMap = New Map;
		ConversionRulesMap = New Map;
		
		DeferredDocumentRegisterRecordCount = 0;
		
		If ContinueOnError Then
			UseTransactions = False;
		EndIf;
		
		If ProcessedObjectsCountToUpdateStatus = 0 Then
			ProcessedObjectsCountToUpdateStatus = 100;
		EndIf;
		
		DataAnalysisResultToExport = DataExchangeServer.DataAnalysisResultToExport(ExchangeFileName, False);
		ExchangeMessageFileSize = DataAnalysisResultToExport.ExchangeMessageFileSize;
		ObjectsToImportCount = DataAnalysisResultToExport.ObjectsToImportCount;
		
		SecurityProfileName = InitializeDataProcessors();
		
		If SecurityProfileName <> Undefined Then
			SetSafeMode(SecurityProfileName);
		EndIf;
		
		StartReadMessage(MessageReader);
		
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		If UseTransactions Then
			BeginTransaction();
		EndIf;
		Try
			
			ReadData(MessageReader);
			
			If ErrorFlag() Then
				Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
			EndIf;
			
			// Delayed writinging of what was not written.
			ExecuteWriteNotWrittenObjects();
			
			ExecuteHandlerAfterDataImport();
			
			If ErrorFlag() Then
				Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
			EndIf;
			
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			If UseTransactions Then
				CommitTransaction();
			EndIf;
		Except
			If UseTransactions Then
				RollbackTransaction();
				DataExchangeInternal.DisableAccessKeysUpdate(False, False);
			Else
				DataExchangeInternal.DisableAccessKeysUpdate(False);
			EndIf;
			
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
		// Posting documents in queue.
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		Try
			ExecuteDeferredDocumentsPosting();
			ExecuteDeferredObjectsWrite();
			
			DataExchangeInternal.DisableAccessKeysUpdate(False);
		Except
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			Raise;
		EndTry;
		
		FinishMessageReader(MessageReader);
	Except
		If MessageReader <> Undefined
			AND MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
		EndIf;
	EndTry;
	
	FinishKeepExchangeProtocol();
	
	// Resetting modal variables before storing the data processor to the platform cache.
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	DisableDataProcessorForDebug();
	ExchangeFile = Undefined;
	
EndProcedure

#EndRegion

#Region PackagedDataImport

// Imports data from an exchange message file to an infobase of the specified object types only.
//
// Parameters:
//  TablesToImport - Array - an array of types to be imported from the exchange message; array item -
//                                String.
//  For example, to import from the exchange message the Counterparties catalog items only:
//   TablesToImport = New Array;
//   TablesToImport.Add("CatalogRef.Counterparties");
// 
//  You can receive the list of all types that are contained in the current exchange message by 
//  calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportForInfobase(TablesToImport) Export
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	DataImportMode = "ImportToInfobase";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	HasObjectRegistrationDataAdjustment = False;
	HasObjectChangeRecordData = False;
	GlobalNotWrittenObjectStack = New Map;
	ConversionRulesMap = New Map;
	
	// Import start date
	DataExchangeState().StartDate = CurrentSessionDate();
	
	// Record in the event log.
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла: %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła: %1';de = 'Datenaustauschprozess für den Knoten starten: %1';ro = 'Începutul procesului de schimb de date pentru nod: %1';tr = 'Ünite için veri değişimi süreci başlatılıyor: %1'; es_ES = 'Inicio del proceso del intercambio de datos para el nodo: %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(ExchangeNodeDataImport));
	WriteEventLogDataExchange(MessageString, EventLogLevel.Information);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		ExecuteSelectiveMessageReader(TablesToImport);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Raise;
	EndTry;
	
	// import end date
	DataExchangeState().EndDate = CurrentSessionDate();
	
	// Recording data import completion in the information register.
	WriteDataImportEnd();
	
	// Record in the event log.
	MessageString = NStr("ru = '%1, %2; Обработано %3 объектов'; en = '%1, %2, %3 objects processed.'; pl = '%1, %2; %3 obiekty są przetwarzane';de = '%1, %2; %3 Eigenschaften werden verarbeitet';ro = '%1, %2; %3 obiectele sunt procesate';tr = '%1, %2; %3 nesneler işleniyor'; es_ES = '%1, %2; %3 objetos se han procesado'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
					ExchangeExecutionResult(),
					Enums.ActionsOnExchange.DataImport,
					Format(ImportedObjectCounter(), "NG=0"));
	//
	WriteEventLogDataExchange(MessageString, EventLogLevel.Information);
	
	// Resetting modal variables before storing the data processor to the platform cache.
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// imports data from the exchange message file to values table of specified objects types.
//
// Parameters:
//  TablesToImport - Array - an array of types to be imported from the exchange message; array item -
//                                String.
//  For example, to import from the exchange message the Counterparties catalog items only:
//   TablesToImport = New Array;
//   TablesToImport.Add("CatalogRef.Counterparties");
// 
//  You can receive the list of all types that are contained in the current exchange message by 
//  calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportIntoValueTable(TablesToImport) Export
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	DataImportMode = "ImportToValueTable";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	HasObjectRegistrationDataAdjustment = False;
	HasObjectChangeRecordData = False;
	GlobalNotWrittenObjectStack = New Map;
	ConversionRulesMap = New Map;
	
	UseTransactions = False;
	
	// Initialize data tables of the data exchange message.
	For Each DataTableKey In TablesToImport Do
		
		SubstringsArray = StrSplit(DataTableKey, "#");
		
		ObjectType = SubstringsArray[1];
		
		DataTablesExchangeMessages().Insert(DataTableKey, InitExchangeMessageDataTable(Type(ObjectType)));
		
	EndDo;
	
	ExecuteSelectiveMessageReader(TablesToImport);
	
	// Resetting modal variables before storing the data processor to the platform cache.
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// Performs sequential reading of the exchange message file while:
//     - registration of changes by the number of the incoming receipt is deleted
//     - exchange rules are imported
//     - information on data types is imported
//     - data mapping information is read and recorded to the infobase
//     - information on objects types and their amount is collected.
//
// Parameters:
//     AnalysisParameters - Structure. Optional additional parameters of analysis. Valid fields:
//         * CollectClassifierStatistics - Boolean - a flag showing whether classifier data is 
//                                                        included in statistics.
//                                                        Classifiers are catalogs, charts of 
//                                                        characteristic types, charts of accounts, CCTs, which have in OCR
//                                                        SynchronizeByID. and
//                                                        SearchBySearchFieldsIfNotFoundByID.
// 
Procedure ExecuteExchangeMessageAnalysis(AnalysisParameters = Undefined) Export
	
	MessageReader = Undefined;
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	Try
		
		SetErrorFlag(False);
		
		UseTransactions = False;
		
		ErrorMessageStringField = "";
		DataExchangeStateField = Undefined;
		ExchangeResultField = Undefined;
		IncomingExchangeMessageFormatVersionField = Undefined;
		HasObjectRegistrationDataAdjustment = False;
		HasObjectChangeRecordData = False;
		GlobalNotWrittenObjectStack = New Map;
		ConversionRulesMap = New Map;
		
		InitializeKeepExchangeProtocol();
		
		InitManagersAndMessages();
		
		// Analysis start date
		DataExchangeState().StartDate = CurrentSessionDate();
		
		// Resetting the modal variable.
		PackageHeaderDataTableField = Undefined;
		
		StartReadMessage(MessageReader, True);
		Try
			
			// Reading data from the exchange message.
			ReadDataInAnalysisMode(MessageReader, AnalysisParameters);
			
			If ErrorFlag() Then
				Raise NStr("ru = 'Возникли ошибки при анализе данных.'; en = 'Data analysis errors.'; pl = 'Wystąpiły błędy podczas analizy danych.';de = 'Bei der Datenanalyse sind Fehler aufgetreten.';ro = 'Au apărut erori la analiza datelor.';tr = 'Veri analiz edilirken hatalar oluştu.'; es_ES = 'Errores ocurridos al analizar los datos.'");
			EndIf;
			
			// Generate a temporary data table.
			TemporaryPackageHeaderDataTable = PackageHeaderDataTable().Copy(, "SourceTypeString, DestinationTypeString, SearchFields, TableFields");
			TemporaryPackageHeaderDataTable.GroupBy("SourceTypeString, DestinationTypeString, SearchFields, TableFields");
			
			// Grouping the data table of a data batch title.
			PackageHeaderDataTable().GroupBy(
				"ObjectTypeString, SourceTypeString, DestinationTypeString, SynchronizeByID, IsClassifier, IsObjectDeletion, UsePreview",
				"ObjectCountInSource");
			//
			PackageHeaderDataTable().Columns.Add("SearchFields",  deTypeDetails("String"));
			PackageHeaderDataTable().Columns.Add("TableFields", deTypeDetails("String"));
			
			For Each TableRow In PackageHeaderDataTable() Do
				
				Filter = New Structure;
				Filter.Insert("SourceTypeString", TableRow.SourceTypeString);
				Filter.Insert("DestinationTypeString", TableRow.DestinationTypeString);
				
				TemporaryTableRows = TemporaryPackageHeaderDataTable.FindRows(Filter);
				
				TableRow.SearchFields  = TemporaryTableRows[0].SearchFields;
				TableRow.TableFields = TemporaryTableRows[0].TableFields;
				
			EndDo;
			
			ExecuteHandlerAfterDataImport();
			
			FinishMessageReader(MessageReader);
			
		Except
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
	Except
		If MessageReader <> Undefined
			AND MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
		EndIf;
		
	EndTry;
	
	FinishKeepExchangeProtocol();
	
	// analysis end date
	DataExchangeState().EndDate = CurrentSessionDate();
	
	// Recording data analysis completion in the information register.
	WriteDataImportEnd();
	
	// Resetting modal variables before storing the data processor to the platform cache.
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

#EndRegion

#Region ProcessingProceduresOfExternalConnection

// Import data from an XML string.
//
Procedure ExternalConnectionImportDataFromXMLString(XMLString) Export
	
	If ExchangeNodeDataImportObject = Undefined
		AND ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	ExchangeFile.SetString(XMLString);
	
	MessageReader = Undefined;
	Try
		
		ReadDataInExternalConnectionMode(MessageReader);
		
	Except
		
		If MessageReader <> Undefined
			AND MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
		EndIf;
		
	EndTry;
	
EndProcedure

// Execute Before data import handler for external connection.
//
Procedure ExternalConnectionConversionHandlerBeforeDataImport(Cancel) Export
	
	// {Handler: BeforeDataImport} Start
	If Not IsBlankString(Conversion.BeforeImportData) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeDataImport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeImportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(22, ErrorDescription(), NStr("ru = 'ПередЗагрузкойДанных (конвертация)'; en = 'BeforeImportData (conversion)'; pl = 'BeforeDataImport (Konwertowanie)';de = 'VorDemDatenimport (Konvertierung)';ro = 'BeforeDataImport (conversie)';tr = 'VeriİçeAktarılmadanÖnce (Dönüştürme)'; es_ES = 'BeforeDataImport (Conversión)'"));
			Cancel = True;
		EndTry;
		
	EndIf;
	
	If Cancel Then // Canceling data import
		Return;
	EndIf;
	// {Handler: BeforeDataImport} End
	
EndProcedure

// Initializes settings before data import through the external connection.
//
Procedure ExternalConnectionBeforeDataImport() Export
	
	DataImportMode = "ImportToInfobase";
	
	ErrorMessageStringField = "";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DataForImportTypeMapField = Undefined;
	ImportedObjectCounterField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	
	GlobalNotWrittenObjectStack = New Map;
	LastSearchByRefNumber = 0;
	
	InitManagersAndMessages();
	
	SetErrorFlag(False);
	
	InitializeCommentsOnDataExportAndImport();
	
	InitializeKeepExchangeProtocol();
	
	CustomSearchFieldInfoOnDataImport = New Map;
	
	AdditionalSearchParameterMap = New Map;
	ConversionRulesMap = New Map;
	
	DeferredDocumentRegisterRecordCount = 0;
	
	If ProcessedObjectsCountToUpdateStatus = 0 Then
		ProcessedObjectsCountToUpdateStatus = 100;
	EndIf;
	
	// Clearing exchange rules.
	Rules.Clear();
	ConversionRulesTable.Clear();
	
	ExchangeFile = New XMLReader;
	
	HasObjectChangeRecordData = False;
	HasObjectRegistrationDataAdjustment = False;
	
EndProcedure

// Executes After data import handler.
// Clears variables and executes a deferred document posting and object writing.
//
Procedure ExternalConnectionAfterDataImport() Export
	
	// Delayed writinging of what was not written.
	ExecuteWriteNotWrittenObjects();
	
	// Handler AfterDataImport
	If Not ErrorFlag() Then
		
		If Not IsBlankString(Conversion.AfterImportData) Then
			
			Try
				
				If ImportHandlersDebug Then
					
					ExecuteHandler_Conversion_AfterDataImport();
					
				Else
					
					Execute(Conversion.AfterImportData);
					
				EndIf;
				
			Except
				WriteErrorInfoConversionHandlers(23, ErrorDescription(), NStr("ru = 'ПослеЗагрузкиДанных (конвертация)'; en = 'AfterImportData (conversion)'; pl = 'AfterDataImport (konwertowanie)';de = 'NachDemDatenimport (Konvertierung)';ro = 'AfterDataImport (conversie)';tr = 'VeriİçeAktarıldıktanSonra (dönüştürme)'; es_ES = 'AfterDataImport (conversión)'"));
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If Not ErrorFlag() Then
		
		// Posting documents in queue.
		ExecuteDeferredDocumentsPosting();
		ExecuteDeferredObjectsWrite();
		
		// Writing information on the incoming message number.
		NodeObject = ExchangeNodeDataImport.GetObject();
		NodeObject.ReceivedNo = MessageNumber();
		NodeObject.DataExchange.Load = True;
		
		Try
			NodeObject.Lock();
		Except
			WriteErrorInfoToProtocol(173, BriefErrorDescription(ErrorInfo()), NodeObject);
		EndTry;
		
	EndIf;
	
	If Not ErrorFlag() Then
		
		NodeObject.Write();
		
		If HasObjectRegistrationDataAdjustment = True Then
			
			InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustmentUnconditionally(ExchangeNodeDataImport);
			
		EndIf;
		
		If HasObjectChangeRecordData = True Then
			
			InformationRegisters.InfobaseObjectsMaps.DeleteObsoleteExportByRefModeRecords(ExchangeNodeDataImport);
			
		EndIf;
		
	EndIf;
	
	FinishKeepExchangeProtocol();
	
	// Resetting modal variables before storing the data processor to the platform cache.
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// Opens a new transaction.
//
Procedure ExternalConnectionCheckTransactionStartAndCommitOnDataImport() Export
	
	If UseTransactions
		AND ObjectsPerTransaction > 0
		AND ImportedObjectCounter() % ObjectsPerTransaction = 0 Then
		
		CommitTransaction();
		BeginTransaction();
		
	EndIf;
	
EndProcedure

// Opens transaction for exchange via external connection, if required.
//
Procedure ExternalConnectionBeginTransactionOnDataImport() Export
	
	If UseTransactions Then
		BeginTransaction();
	EndIf;
	
EndProcedure

// Commits the transaction of exchange through the external connection (if import is executed in transaction.
//
Procedure ExternalConnectionCommitTransactionOnDataImport() Export
	
	If UseTransactions Then
		
		If ErrorFlag() Then
			RollbackTransaction();
		Else
			CommitTransaction();
		EndIf;
		
	EndIf;
	
EndProcedure

// Cancels transaction on exchange via external connection.
//
Procedure ExternalConnectionRollbackTransactionOnDataImport() Export
	
	While TransactionActive() Do
		RollbackTransaction();
	EndDo;
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions

// Stores an exchange file to a file storage service for subsequent mapping.
// Data is not imported.
//
Procedure PutMessageForDataMapping(XMLExportData) Export
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	TempFileName = DataExchangeServer.UniqueExchangeMessageFileName();
	
	TempFileFullName = CommonClientServer.GetFullFileName(
		DumpDirectory, TempFileName);
		
	TextDocument = New TextDocument;
	TextDocument.AddLine(XMLExportData);
	TextDocument.Write(TempFileFullName, , Chars.LF);
	
	FileID = DataExchangeServer.PutFileInStorage(TempFileFullName);
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNodeDataImport, FileID);
	
EndProcedure

// Sets the Load parameter value for the DataExchange object property.
//
// Parameters:
//  Object - object whose property will be set.
//  Value - a value of the Import property being set.
//
//
Procedure SetDataExchangeLoad(Object, Value = True, Val SendBack = False) Export
	
	DataExchangeServer.SetDataExchangeLoad(Object, Value, SendBack, ExchangeNodeDataImport);
	
EndProcedure

// Prepares a row with information about the rules based on the read data from the XML file.
//
// Parameters:
//  No.
// 
// Returns:
//  InfoString - String - a sring with information on rules.
//
Function RulesInformation(IsCorrespondentRules = False) Export
	
	// Function return value.
	InfoString = "";
	
	If ErrorFlag() Then
		Return InfoString;
	EndIf;
	
	If IsCorrespondentRules Then
		InfoString = NStr("ru = 'Правила конвертации корреспондента (%1) от %2'; en = 'Peer (%1) conversion rules created on %2'; pl = 'Zasady konwersji korespondenta (%1) z %2';de = 'Konvertierungsregeln von Korrespondenten (%1) aus %2';ro = 'Regulile de conversie a corespondentului (%1) din %2';tr = '%1''dan muhabirin (%2) dönüşüm kuralları'; es_ES = 'Reglas de conversión del corresponsal (%1) de %2'");
	Else
		InfoString = NStr("ru = 'Правила конвертации этой информационной базы (%1) от %2'; en = 'This infobase (%1) conversion rules created on %2'; pl = 'Reguły konwersji tej bazy informacyjnej (%1) z %2';de = 'Konvertierungsregeln von dieser Infobase (%1) aus %2';ro = 'Regulile de conversie ale acestei baze de informații (%1) din %2';tr = '%1''dan veritabanın (%2) dönüşüm kuralları'; es_ES = 'Reglas de conversión de esta infobase (%1) de %2'");
	EndIf;
	
	SourceConfigurationPresentation = ConfigurationPresentationFromExchangeRules("Source");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(InfoString,
							SourceConfigurationPresentation,
							Format(Conversion.CreationDateTime, "DLF =DD"));
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InternalProperties

Function DataProcessorForDataImport()
	
	Return DataImportDataProcessorField;
	
EndFunction

Function IsExchangeOverExternalConnection()
	
	Return DataProcessorForDataImport() <> Undefined
		AND Not (DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping");
	
EndFunction
	
Function IsMessageImportToMap()	
	
	Return DataProcessorForDataImport() <> Undefined
		AND DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping";
		
EndFunction

Function DataExchangeState()
	
	If TypeOf(DataExchangeStateField) <> Type("Structure") Then
		
		DataExchangeStateField = New Structure;
		DataExchangeStateField.Insert("InfobaseNode");
		DataExchangeStateField.Insert("ActionOnExchange");
		DataExchangeStateField.Insert("ExchangeExecutionResult");
		DataExchangeStateField.Insert("StartDate");
		DataExchangeStateField.Insert("EndDate");
		
	EndIf;
	
	Return DataExchangeStateField;
	
EndFunction

Function DataForImportTypeMap()
	
	If TypeOf(DataForImportTypeMapField) <> Type("Map") Then
		
		DataForImportTypeMapField = New Map;
		
	EndIf;
	
	Return DataForImportTypeMapField;
	
EndFunction

Function DataImportToValueTableMode()
	
	Return Not DataImportToInfobaseMode();
	
EndFunction

Function UUIDColumnName()
	
	Return "UUID";
	
EndFunction

Function ColumnNameTypeAsString()
	
	Return "TypeString";
	
EndFunction

Function EventLogMessageKey()
	
	If TypeOf(EventLogMessageKey) <> Type("String")
		OR IsBlankString(EventLogMessageKey) Then
		
		EventLogMessageKey = DataExchangeServer.EventLogMessageTextDataExchange();
		
	EndIf;
	
	Return EventLogMessageKey;
EndFunction

Function ExchangeResultPriorities()
	
	If TypeOf(ExchangeResultPrioritiesField) <> Type("Array") Then
		
		ExchangeResultPrioritiesField = New Array;
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.Error);
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.Error_MessageTransport);
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.Canceled);
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.CompletedWithWarnings);
		ExchangeResultPrioritiesField.Add(Enums.ExchangeExecutionResults.Completed);
		ExchangeResultPrioritiesField.Add(Undefined);
		
	EndIf;
	
	Return ExchangeResultPrioritiesField;
EndFunction

Function ObjectPropertyDescriptionTables()
	
	If TypeOf(ObjectPropertyDescriptionTableField) <> Type("Map") Then
		
		ObjectPropertyDescriptionTableField = New Map;
		
	EndIf;
	
	Return ObjectPropertyDescriptionTableField;
EndFunction

Function AdditionalPropertiesForDeferredPosting()
	
	If TypeOf(DocumentsForDeferredPostingMap) <> Type("Map") Then
		
		// Initialize document deferred posting map.
		DocumentsForDeferredPostingMap = New Map;
		
	EndIf;
	
	Return DocumentsForDeferredPostingMap;
	
EndFunction

Function ObjectsForDeferredPosting()
	
	If TypeOf(ObjectsForDeferredPostingField) <> Type("Map") Then
		
		// Initialize object deferred posting map.
		ObjectsForDeferredPostingField = New Map;
		
	EndIf;
	
	Return ObjectsForDeferredPostingField;
	
EndFunction

Function ExportedByRefObjects()
	
	If TypeOf(ExportedByRefObjectsField) <> Type("Array") Then
		
		ExportedByRefObjectsField = New Array;
		
	EndIf;
	
	Return ExportedByRefObjectsField;
EndFunction

Function CreatedOnExportObjects()
	
	If TypeOf(CreatedOnExportObjectsField) <> Type("Array") Then
		
		CreatedOnExportObjectsField = New Array;
		
	EndIf;
	
	Return CreatedOnExportObjectsField;
EndFunction

Function ExportedByRefMetadataObjects()
	
	If TypeOf(ExportedByRefMetadataObjectsField) <> Type("Map") Then
		
		ExportedByRefMetadataObjectsField = New Map;
		
	EndIf;
	
	Return ExportedByRefMetadataObjectsField;
EndFunction

Function ExportObjectByRef(Object, ExchangePlanNode)
	
	MetadataObject = Metadata.FindByType(TypeOf(Object));
	
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	
	// receiving a value from cache
	Result = ExportedByRefMetadataObjects().Get(MetadataObject);
	
	If Result = Undefined Then
		
		Result = False;
		
		// Receiving a flag of export by reference.
		Filter = New Structure("MetadataObjectName", MetadataObject.FullName());
		
		RulesArray = ObjectsRegistrationRules(ExchangePlanNode).FindRows(Filter);
		
		For Each Rule In RulesArray Do
			
			If Not IsBlankString(Rule.FlagAttributeName) Then
				
				FlagAttributeValue = Undefined;
				ExchangePlanNodeProperties(ExchangePlanNode).Property(Rule.FlagAttributeName, FlagAttributeValue);
				
				Result = Result OR ( FlagAttributeValue = Enums.ExchangeObjectExportModes.ExportIfNecessary
										OR FlagAttributeValue = Enums.ExchangeObjectExportModes.EmptyRef());
				//
				If Result Then
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		// Saving the received value to cache.
		ExportedByRefMetadataObjects().Insert(MetadataObject, Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function ExchangePlanName()
	
	If TypeOf(ExchangePlanNameField) <> Type("String")
		OR IsBlankString(ExchangePlanNameField) Then
		
		If ValueIsFilled(NodeForExchange) Then
			
			ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(NodeForExchange);
			
		ElsIf ValueIsFilled(ExchangeNodeDataImport) Then
			
			ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(ExchangeNodeDataImport);
			
		ElsIf ValueIsFilled(ExchangePlanNameSOR) Then
			
			ExchangePlanNameField = ExchangePlanNameSOR;
			
		Else
			
			ExchangePlanNameField = "";
			
		EndIf;
		
	EndIf;
	
	Return ExchangePlanNameField;
EndFunction

Function ExchangePlanNodeProperties(Node)
	
	If TypeOf(ExchangePlanNodePropertyField) <> Type("Structure") Then
		
		ExchangePlanNodePropertyField = New Structure;
		
		// getting attribute names
		AttributesNames = Common.AttributeNamesByType(Node, Type("EnumRef.ExchangeObjectExportModes"));
		
		// Getting attribute values.
		If Not IsBlankString(AttributesNames) Then
			
			ExchangePlanNodePropertyField = Common.ObjectAttributesValues(Node, AttributesNames);
			
		EndIf;
		
	EndIf;
	
	Return ExchangePlanNodePropertyField;
EndFunction

Function IncomingExchangeMessageFormatVersion()
	
	If TypeOf(IncomingExchangeMessageFormatVersionField) <> Type("String") Then
		
		IncomingExchangeMessageFormatVersionField = "0.0.0.0";
		
	EndIf;
	
	// Adding the version of the incoming message format to 4 digits.
	VersionDigits = StrSplit(IncomingExchangeMessageFormatVersionField, ".");
	
	If VersionDigits.Count() < 4 Then
		
		DigitsCountAdd = 4 - VersionDigits.Count();
		
		For A = 1 To DigitsCountAdd Do
			
			VersionDigits.Add("0");
			
		EndDo;
		
		IncomingExchangeMessageFormatVersionField = StrConcat(VersionDigits, ".");
		
	EndIf;
	
	Return IncomingExchangeMessageFormatVersionField;
EndFunction

Function MessageNumber()
	
	If TypeOf(MessageNumberField) <> Type("Number") Then
		
		MessageNumberField = 0;
		
	EndIf;
	
	Return MessageNumberField;
	
EndFunction

#EndRegion

#Region CachingFunctions

Function ObjectPropertiesDescriptionTable(MetadataObject)
	
	Result = ObjectPropertyDescriptionTables().Get(MetadataObject);
	
	If Result = Undefined Then
		
		Result = Common.ObjectPropertiesDetails(MetadataObject, "Name");
		
		ObjectPropertyDescriptionTables().Insert(Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function ObjectsRegistrationRules(ExchangePlanNode)
	
	If TypeOf(ObjectsRegistrationRulesField) <> Type("ValueTable") Then
		
		ObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(
			DataExchangeCached.GetExchangePlanName(ExchangePlanNode));
		ObjectsRegistrationRulesField = ObjectsRegistrationRules.Copy(, "MetadataObjectName, FlagAttributeName");
		ObjectsRegistrationRulesField.Indexes.Add("MetadataObjectName");
		
	EndIf;
	
	Return ObjectsRegistrationRulesField;
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresToWriteAlgorithms

#Region StringOperations

// Splits a string into two parts: before the separator substring and after it.
//
// Parameters:
//  Str          - a string to split.
//  Separator  - separator substring:
//  Mode        - 0 - separator is not included in the returned substrings.
//                 1 - separator is included in the left substring.
//                 2 - separator is included in the right substring.
//
// Returns:
//  The right part of the string - before the separator character.
// 
Function SplitWithSeparator(Page, Val Separator, Mode=0)

	RightPart         = "";
	SeparatorPos      = StrFind(Page, Separator);
	SeparatorLength    = StrLen(Separator);
	If SeparatorPos > 0 Then
		RightPart	 = Mid(Page, SeparatorPos + ?(Mode=2, 0, SeparatorLength));
		Page          = TrimAll(Left(Page, SeparatorPos - ?(Mode=1, -SeparatorLength + 1, 1)));
	EndIf;

	Return(RightPart);

EndFunction

// Converts values from a string to an array using the specified separator.
//
// Parameters:
//  Str            - a string to be split.
//  Separator    - separator substring.
//
// Returns:
//  Array of values
// 
Function ArrayFromString(Val Page, Separator=",")

	Array      = New Array;
	RightPart = SplitWithSeparator(Page, Separator);
	
	While Not IsBlankString(Page) Do
		Array.Add(TrimAll(Page));
		Page         = RightPart;
		RightPart = SplitWithSeparator(Page, Separator);
	EndDo; 

	Return(Array);
	
EndFunction

Function StringNumberWithoutPrefixes(Number)
	
	NumberWithoutPrefixes = "";
	Cnt = StrLen(Number);
	
	While Cnt > 0 Do
		
		Char = Mid(Number, Cnt, 1);
		
		If (Char >= "0" AND Char <= "9") Then
			
			NumberWithoutPrefixes = Char + NumberWithoutPrefixes;
			
		Else
			
			Return NumberWithoutPrefixes;
			
		EndIf;
		
		Cnt = Cnt - 1;
		
	EndDo;
	
	Return NumberWithoutPrefixes;
	
EndFunction

// Splits a string into a prefix and numerical part.
//
// Parameters:
//  Str            - string. String to be split;
//  NumericalPart  - Number. Variable that contains numeric part of the passed string.
//  Mode          - string. Pass Number if you want numeric part to be returned, otherwise pass Prefix.
//
// Returns:
//  String prefix
//
Function PrefixNumberCount(Val Page, NumericalPart = "", Mode = "")

	NumericalPart = 0;
	Prefix = "";
	Page = TrimAll(Page);
	Length   = StrLen(Page);
	
	StringNumberWithoutPrefix = StringNumberWithoutPrefixes(Page);
	StringPartLength = StrLen(StringNumberWithoutPrefix);
	If StringPartLength > 0 Then
		NumericalPart = Number(StringNumberWithoutPrefix);
		Prefix = Mid(Page, 1, Length - StringPartLength);
	Else
		Prefix = Page;	
	EndIf;

	If Mode = "Number" Then
		Return(NumericalPart);
	Else
		Return(Prefix);
	EndIf;

EndFunction

// Casts the number (code) to the required length, splitting the number into a prefix and numeric part. 
// The space between the prefix and number is filled with zeros.
// 
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  Str          - a string to convert;
//  Length        - required length of a row.
//
// Returns:
//  String       - a code or number cast to the required length.
// 
Function CastNumberToLength(Val Page, Length, AddZerosIfLengthNotLessCurrentNumberLength = True, Prefix = "")

	Page             = TrimAll(Page);
	IncomingNumberLength = StrLen(Page);

	NumericalPart   = "";
	Result       = PrefixNumberCount(Page, NumericalPart);
	
	Result = ?(IsBlankString(Prefix), Result, Prefix);
	
	NumericPartString = Format(NumericalPart, "NG=0");
	NumericPartLength = StrLen(NumericPartString);

	If (Length >= IncomingNumberLength AND AddZerosIfLengthNotLessCurrentNumberLength)
		OR (Length < IncomingNumberLength) Then
		
		For TemporaryVariable = 1 To Length - StrLen(Result) - NumericPartLength Do
			
			Result = Result + "0";
			
		EndDo;
	
	EndIf;
		
	Result = Result + NumericPartString;

	Return(Result);

EndFunction

// Supplements string with the specified symbol to the specified length.
//
// Parameters:
//  Str          - string to be supplemented;
//  Length - required length of a resulting row.
//  What          - character used for supplementing the string.
//
// Returns:
//  String that is supplemented with the specified symbol to the specified length.
//
Function odSupplementString(Page, Length, Than = " ")

	Result = TrimAll(Page);
	While Length - StrLen(Result) > 0 Do
		Result = Result + Than;
	EndDo;

	Return(Result);

EndFunction

#EndRegion

#Region DataOperations

// Defines whether the passed value is filled.
//
// Parameters:
//  Value - a value to be checked.
//
// Returns:
//  True         - the value is not filled in, otherwise False.
//
Function deEmpty(Value, IsNULL=False)

	// Primitive types first
	If Value = Undefined Then
		Return True;
	ElsIf Value = NULL Then
		IsNULL   = True;
		Return True;
	EndIf;
	
	ValueType = TypeOf(Value);
	
	If ValueType = ValueStorageType Then
		
		Result = deEmpty(Value.Get());
		Return Result;		
		
	ElsIf ValueType = BinaryDataType Then
		
		Return False;
		
	Else
		
		// The value is considered empty if it is equal to the default value of its type.
		// 
		Try
			Result = Not ValueIsFilled(Value);
			Return Result;
		Except
			Return False;
		EndTry;
			
	EndIf;
	
EndFunction

// Returns the TypeDescription object that contains the specified type.
//
// Parameters:
//  TypeValue - a string with a type name or Type.
//  
// Returns:
//  TypesDetails
//
Function deTypeDetails(TypeValue)

	TypesDetails = TypeDescriptionMap[TypeValue];
	
	If TypesDetails = Undefined Then
		
		TypesArray = New Array;
		If TypeOf(TypeValue) = StringType Then
			TypesArray.Add(Type(TypeValue));
		Else
			TypesArray.Add(TypeValue);
		EndIf; 
		TypesDetails	= New TypeDescription(TypesArray);
		
		TypeDescriptionMap.Insert(TypeValue, TypesDetails);
		
	EndIf;	
	
	Return TypesDetails;

EndFunction

// Returns the blank (default) value of the specified type.
//
// Parameters:
//  Type          - a string with a type name or Type.
//
// Returns:
//  A blank value of the specified type.
// 
Function deGetEmptyValue(Type)

	EmptyTypeValue = EmptyTypeValueMap[Type];
	
	If EmptyTypeValue = Undefined Then
		
		EmptyTypeValue = deTypeDetails(Type).AdjustValue(Undefined);	
		
		EmptyTypeValueMap.Insert(Type, EmptyTypeValue);
			
	EndIf;
	
	Return EmptyTypeValue;

EndFunction

Function CheckRefExists(Ref, Manager, FoundByUUIDObject, 
	MainObjectSearchMode, SearchByUUIDQueryString)
	
	Try
			
		If MainObjectSearchMode
			OR IsBlankString(SearchByUUIDQueryString) Then
			
			FoundByUUIDObject = Ref.GetObject();
			
			If FoundByUUIDObject = Undefined Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		Else
			// It is the Search by reference mode - It is enough to execute a query by the following pattern: 
			// PropertiesStructure.SearchString.
			
			Query = New Query();
			Query.Text = SearchByUUIDQueryString + "  Ref = &Ref ";
			Query.SetParameter("Ref", Ref);
			
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		EndIf;
		
		Return Ref;	
		
	Except
			
		Return Manager.EmptyRef();
		
	EndTry;
	
EndFunction

// Performs a simple search for infobase object by the specified property.
//
// Parameters:
//  Manager - manager of the object to be searched.
//  Property - a property to implement the search: Name, Code,
//                   Description, or a Name of an indexed attribute.
//  Value - value of a property to be used for searching the object.
//
// Returns:
//  Found infobase object.
//
Function deFindObjectByProperty(Manager, Property, Value, 
	FoundByUUIDObject = Undefined, 
	CommonPropertyStructure = Undefined, CommonSearchProperties = Undefined,
	MainObjectSearchMode = True, SearchByUUIDQueryString = "")
	
	If Property = "Name" Then
		
		Return Manager[Value];
		
	ElsIf Property = "{UUID}" Then
		
		RefByUUID = Manager.GetRef(New UUID(Value));
		
		Ref =  CheckRefExists(RefByUUID, Manager, FoundByUUIDObject, 
			MainObjectSearchMode, SearchByUUIDQueryString);
			
		Return Ref;
		
	ElsIf Property = "{PredefinedItemName}" Then
		
		Ref = PredefinedManagerItem(Manager, Value);
		If Ref = Undefined Then
			Ref = Manager.FindByCode(Value);
			If Ref = Undefined Then
				Ref = Manager.EmptyRef();
			EndIf;
		EndIf;
		
		Return Ref;
		
	Else
		
		ObjectRef = FindItemUsingRequest(CommonPropertyStructure, CommonSearchProperties, , Manager);
		
		Return ObjectRef;
		
	EndIf;
	
EndFunction

// Returns predefined item value by its name.
// 
Function PredefinedManagerItem(Val Manager, Val PredefinedItemName)
	
	Query = New Query( StrReplace("
		|SELECT 
		|	PredefinedDataName AS PredefinedDataName,
		|	Ref                    AS Ref
		|FROM
		|	{TableName}
		|WHERE
		|	Predefined
		|",
		"{TableName}", Metadata.FindByType(TypeOf(Manager)).FullName()));
	
	Selection = Query.Execute().Select();
	If Selection.FindNext( New Structure("PredefinedDataName", PredefinedItemName) ) Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
EndFunction

// Performs a simple search for infobase object by the specified property.
//
// Parameters:
//  Str            - String - a property value, by which an object is searched.
//                   
//  Type - a type of the object to be found.
//  Property       - String - a property name, by which an object is found.
//
// Returns:
//  Found infobase object.
//
Function deGetValueByString(Page, Type, Property = "")

	If IsBlankString(Page) Then
		Return New(Type);
	EndIf; 

	Properties = Managers[Type];

	If Properties = Undefined Then
		
		TypesDetails = deTypeDetails(Type);
		Return TypesDetails.AdjustValue(Page);
		
	EndIf;

	If IsBlankString(Property) Then
		
		If Properties.TypeName = "Enum"
			Or Properties.TypeName = "BusinessProcessRoutePoint" Then
			Property = "Name";
		Else
			Property = "{PredefinedItemName}";
		EndIf;
		
	EndIf; 

	Return deFindObjectByProperty(Properties.Manager, Property, Page);

EndFunction

// Returns a string presentation of a value type.
//
// Parameters:
//  ValueOrType - arbitrary value or Type.
//
// Returns:
//  String - a string presentation of the value type.
//
Function deValueTypeAsString(ValueOrType)

	ValueType	= TypeOf(ValueOrType);
	
	If ValueType = TypeType Then
		ValueType	= ValueOrType;
	EndIf; 
	
	If (ValueType = Undefined) Or (ValueOrType = Undefined) Then
		Result = "";
	ElsIf ValueType = StringType Then
		Result = "String";
	ElsIf ValueType = NumberType Then
		Result = "Number";
	ElsIf ValueType = DateType Then
		Result = "Date";
	ElsIf ValueType = BooleanType Then
		Result = "Boolean";
	ElsIf ValueType = ValueStorageType Then
		Result = "ValueStorage";
	ElsIf ValueType = UUIDType Then
		Result = "UUID";
	ElsIf ValueType = AccumulationRecordTypeType Then
		Result = "AccumulationRecordType";
	Else
		Manager = Managers[ValueType];
		If Manager = Undefined Then
		Else
			Result = Manager.RefTypeString;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region ProceduresAndFunctionsOfObjectOperationsXMLWriter

// Creates a new XML node
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
//
// Parameters:
//  Name - Node name
//
// Returns:
//  Object of the new XML node
//
Function CreateNode(Name)

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement(Name);

	Return XMLWriter;

EndFunction

// Writes item and its value to the specified object.
//
// Parameters:
//  Object - an object of the XMLWrite type.
//  Name            - string. Item name.
//  Value - Item value.
// 
Procedure deWriteElement(Object, Name, Value="")

	Object.WriteStartElement(Name);
	Page = XMLString(Value);
	
	Object.WriteText(Page);
	Object.WriteEndElement();
	
EndProcedure

// Subordinates an xml node to the specified parent node.
//
// Parameters:
//  ParentNode - parent XML node.
//  Node - node to be subordinated.
//
Procedure AddSubordinateNode(ParentNode, Node)

	If TypeOf(Node) <> StringType Then
		Node.WriteEndElement();
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	ParentNode.WriteRaw(InformationToWriteToFile);
		
EndProcedure

// Sets an attribute of the specified xml node.
//
// Parameters:
//  Node - XML node
//  Name - attribute name.
//  Value - value to be set.
//
Procedure SetAttribute(Node, Name, Value)

	RecordRow = XMLString(Value);
	
	Node.WriteAttribute(Name, RecordRow);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfObjectOperationsXMLReader

// Reads the attribute value by the name from the specified object, converts the value to the 
// specified primitive type.
//
// Parameters:
//  Object - XMLReader object positioned to the beginning of the element whose attribute is required.
//                
//  Type - a value of Type type. Attribute type.
//  Name         - String. Attribute name.
//
// Returns:
//  The attribute value received by the name and cast to the specified type.
// 
Function deAttribute(Object, Type, Name)

	ValueStr = TrimR(Object.GetAttribute(Name));
	If Not IsBlankString(ValueStr) Then
		Return XMLValue(Type, ValueStr);		
	ElsIf      Type = StringType Then
		Return ""; 
	ElsIf Type = BooleanType Then
		Return False;
	ElsIf Type = NumberType Then
		Return 0;
	ElsIf Type = DateType Then
		Return BlankDateValue;
	EndIf; 
	
EndFunction

// Skips xml nodes to the end of the specified item (whichg is currently the default one).
//
// Parameters:
//  Object - an object of the XMLReader type.
//  Name - a name of node, to the end of which items are skipped.
// 
Procedure deSkip(Object, Name="")

	AttachmentsCount = 0; // Number of attachments with the same name.

	If Name = "" Then
		
		Name = Object.LocalName;
		
	EndIf; 
	
	While Object.Read() Do
		
		If Object.LocalName <> Name Then
			Continue;
		EndIf;
		
		NodeType = Object.NodeType;
			
		If NodeType = XMLNodeTypeEndElement Then
				
			If AttachmentsCount = 0 Then
					
				Break;
					
			Else
					
				AttachmentsCount = AttachmentsCount - 1;
					
			EndIf;
				
		ElsIf NodeType = XMLNodeTypeStartElement Then
				
			AttachmentsCount = AttachmentsCount + 1;
				
		EndIf;
					
	EndDo;
	
EndProcedure

// Reads the element text and converts the value to the specified type.
//
// Parameters:
//  Object - XMLReader object whose data will be read.
//  Type - type of the return value.
//  SearchByProperty - for reference types, you can specify a property to be used for searching the 
//                     object: Code, Description, <AttributeName>, Name (predefined value).
//
// Returns:
//  Value of an XML element converted to the relevant type.
//
Function deElementValue(Object, Type, SearchByProperty = "", CutStringRight = True)

	Value = "";
	Name      = Object.LocalName;

	While Object.Read() Do
		
		NodeType = Object.NodeType;
		
		If NodeType = XMLNodeTypeText Then
			
			Value = Object.Value;
			
			If CutStringRight Then
				
				Value = TrimR(Value);
				
			EndIf;
						
		ElsIf (Object.LocalName = Name) AND (NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	EndDo;

	
	If (Type = StringType)
		OR (Type = BooleanType)
		OR (Type = NumberType)
		OR (Type = DateType)
		OR (Type = ValueStorageType)
		OR (Type = UUIDType)
		OR (Type = AccumulationRecordTypeType)
		OR (Type = AccountTypeKind) Then
		
		Return XMLValue(Type, Value);
		
	Else
		
		Return deGetValueByString(Value, Type, SearchByProperty);
		
	EndIf;
	
EndFunction

#EndRegion

#Region ExchangeFileOperationsProceduresAndFunctions

// Saves the specified xml node to file.
//
// Parameters:
//  Node - XML node to be saved to the file.
//
Procedure WriteToFile(Node)

	If TypeOf(Node) <> StringType Then
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	If IsExchangeOverExternalConnection() Then
		
		// ============================ {Start: Data exchange through external connection}.
		DataProcessorForDataImport().ExternalConnectionImportDataFromXMLString(InformationToWriteToFile);
		
		If DataProcessorForDataImport().ErrorFlag() Then
			
			MessageString = NStr("ru = 'Ошибка в базе-корреспонденте: %1'; en = 'Peer infobase error: %1'; pl = 'Błąd w bazie-korespondencie: %1';de = 'Es liegt ein Fehler in der entsprechenden Datenbank vor: %1';ro = 'Eroare în baza-corespondentă: %1';tr = 'Muhabir tabanındaki hata: %1'; es_ES = 'Error en la base-correspondiente: %1'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DataProcessorForDataImport().ErrorMessageString());
			ExchangeExecutionResultExternalConnection = Enums.ExchangeExecutionResults[DataProcessorForDataImport().ExchangeExecutionResultString()];
			WriteToExecutionProtocol(MessageString,,,,,, ExchangeExecutionResultExternalConnection);
			Raise MessageString;
			
		EndIf;
		// ============================ {End: Data exchange through external connection}.
		
	Else
		
		ExchangeFile.WriteLine(InformationToWriteToFile);
		
	EndIf;
	
EndProcedure

// Opens an exchange file, writes a file header according to the exchange format.
//
// Parameters:
//  No.
//
Function OpenExportFile()

	ExchangeFile = New TextWriter;
		
	Try
		ExchangeFile.Open(ExchangeFileName, TextEncoding.UTF8);
	Except
		ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при открытии файла для записи сообщения обмена.
				|Имя файла ""%1"".
				|Описание ошибки:
				|%2'; 
				|en = 'Cannot open the file for writing the exchange message.
				|File name: %1.
				|Error description:
				|%2'; 
				|pl = 'Błąd podczas otwierania pliku w celu zapisania wymiany komunikatów.
				|Nazwa pliku ""%1"".
				|Opis błędu:
				|%2';
				|de = 'Fehler beim Öffnen einer Datei zum Aufzeichnen einer Austauschnachricht.
				|Dateiname ""%1"".
				| Beschreibung des Fehlers:
				|%2';
				|ro = 'Eroare la deschiderea fișierului pentru scrierea mesajului de schimb.
				|Numele fișierului ""%1"".
				| Descrierea erorii:
				|%2';
				|tr = 'Veri alışverişi iletisini yazmak için dosyayı açarken hata oluştu. 
				|Dosya adı ""%1"".
				| Hata açıklaması:
				|%2'; 
				|es_ES = 'Error al abrir el archivo para guardar el mensaje de cambio.
				|Nombre de archivo ""%1"".
				|Descripción de error:
				|%2'"),
			String(ExchangeFileName),
			DetailErrorDescription(ErrorInfo()));
		WriteToExecutionProtocol(ErrorPresentation);
		Return "";
	EndTry;
	
	XMLInfoString = "<?xml version=""1.0"" encoding=""UTF-8""?>";
	
	ExchangeFile.WriteLine(XMLInfoString);

	TempXMLWriter = New XMLWriter();
	
	TempXMLWriter.SetString();
	
	TempXMLWriter.WriteStartElement("ExchangeFile");
	
	SetAttribute(TempXMLWriter, "FormatVersion", 				 ExchangeMessageFormatVersion());
	SetAttribute(TempXMLWriter, "ExportDate",				 CurrentSessionDate());
	SetAttribute(TempXMLWriter, "SourceConfigurationName",	 Conversion.Source);
	SetAttribute(TempXMLWriter, "SourceConfigurationVersion", Conversion.SourceConfigurationVersion);
	SetAttribute(TempXMLWriter, "DestinationConfigurationName",	 Conversion.Destination);
	SetAttribute(TempXMLWriter, "ConversionRuleIDs",		 Conversion.ID);
	
	TempXMLWriter.WriteEndElement();
	
	Page = TempXMLWriter.Close();
	
	Page = StrReplace(Page, "/>", ">");
	
	ExchangeFile.WriteLine(Page);
	
	Return XMLInfoString + Chars.LF + Page;
	
EndFunction

// Closes the exchange file.
//
// Parameters:
//  No.
//
Procedure CloseFile()
	
	ExchangeFile.WriteLine("</ExchangeFile>");
	ExchangeFile.Close();
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfExchangeProtocolOperations

// Returns a Structure type object containing all possible fields of the execution protocol record 
// (such as error messages and others).
//
// Parameters:
//  No.
//
// Returns:
//  Object of the Structure type.
// 
Function ExchangeProtocolRecord(ErrorMessageCode = "", Val ErrorRow = "")

	ErrorStructure = New Structure("OCRName,DPRName,Sn,Gsn,Source,ObjectType,Property,Value,ValueType,OCR,PCR,PGCR,DER,DPR,Object,DestinationProperty,ConvertedValue,Handler,ErrorDescription,ModulePosition,Text,ErrorMessageCode,ExchangePlanNode");
	
	ModuleLine              = SplitWithSeparator(ErrorRow, "{");
	ErrorDescription            = SplitWithSeparator(ModuleLine, "}: ");
	
	If ErrorDescription <> "" Then
		
		ErrorStructure.ErrorDescription         = ErrorDescription;
		ErrorStructure.ModulePosition          = ModuleLine;
				
	EndIf;
	
	If ErrorStructure.ErrorMessageCode <> "" Then
		
		ErrorStructure.ErrorMessageCode           = ErrorMessageCode;
		
	EndIf;
	
	Return ErrorStructure;
	
EndFunction 

Procedure InitializeKeepExchangeProtocol()
	
	If IsBlankString(ExchangeProtocolFileName) Then
		
		DataProtocolFile = Undefined;
		CommentObjectProcessingFlag = OutputInfoMessagesToMessageWindow;		
		Return;
		
	Else	
		
		CommentObjectProcessingFlag = OutputInfoMessagesToProtocol OR OutputInfoMessagesToMessageWindow;		
		
	EndIf;
	
	// Attempting to write to an exchange protocol file.
	Try
		DataProtocolFile = New TextWriter(ExchangeProtocolFileName, TextEncoding.ANSI, , AppendDataToExchangeLog);
	Except
		DataProtocolFile = Undefined;
		MessageString = NStr("ru = 'Ошибка при попытке записи в файл протокола данных: %1. Описание ошибки: %2'; en = 'Cannot write to the log file: %1. Error description: %2'; pl = 'Wystąpił błąd podczas próby zapisu do pliku protokołu danych: %1. Opis błędu: %2';de = 'Beim Schreiben in die Datenprotokolldatei ist ein Fehler aufgetreten: %1. Fehlerbeschreibung: %2';ro = 'A apărut o eroare la încercarea de scriere în fișierul protocolului de date: %1. Descrierea erorii: %2';tr = 'Veri iletişim kuralı %1dosyasına yazılmaya çalışırken bir hata oluştu. Hata açıklaması:%2'; es_ES = 'Ha ocurrido un error al intentar grabar para el archivo del protocolo de datos: %1. Descripción del error: %2'",
			Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeProtocolFileName, ErrorDescription());
		WriteEventLogDataExchange(MessageString, EventLogLevel.Warning);
	EndTry;
	
EndProcedure

Procedure FinishKeepExchangeProtocol()
	
	If DataProtocolFile <> Undefined Then
		
		DataProtocolFile.Close();
				
	EndIf;	
	
	DataProtocolFile = Undefined;
	
EndProcedure

Procedure SetExchangeResult(ExchangeExecutionResult)
	
	CurrentResultIndex = ExchangeResultPriorities().Find(ExchangeExecutionResult());
	NewResultIndex   = ExchangeResultPriorities().Find(ExchangeExecutionResult);
	
	If CurrentResultIndex = Undefined Then
		CurrentResultIndex = 100
	EndIf;
	
	If NewResultIndex = Undefined Then
		NewResultIndex = 100
	EndIf;
	
	If NewResultIndex < CurrentResultIndex Then
		
		ExchangeResultField = ExchangeExecutionResult;
		
	EndIf;
	
EndProcedure

Function ExchangeExecutionResultError(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error
		OR ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
	
EndFunction

Function ExchangeExecutionResultWarning(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings
		OR ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
	
EndFunction

// Writes to a protocol or displays messages of the specified structure.
//
// Parameters:
//  Code - Number. Message code.
//  RecordStructure - Structure. Protocol record structure.
//  SetErrorsFlag - if true, then it is an error message. Setting ErrorFlag.
// 
Function WriteToExecutionProtocol(Code = "",
									RecordStructure=Undefined,
									SetErrorFlag=True,
									Level=0,
									Align=22,
									UnconditionalWriteToExchangeProtocol = False,
									Val ExchangeExecutionResult = Undefined) Export
	//
	Indent = "";
	For Cnt = 0 To Level-1 Do
		Indent = Indent + Chars.Tab;
	EndDo; 
	
	If TypeOf(Code) = NumberType Then
		
		If ErrorMessages = Undefined Then
			InitMessages();
		EndIf;
		
		Page = ErrorMessages[Code];
		
	Else
		
		Page = String(Code);
		
	EndIf;

	Page = Indent + Page;
	
	If RecordStructure <> Undefined Then
		
		For each Field In RecordStructure Do
			
			Value = Field.Value;
			If Value = Undefined Then
				Continue;
			EndIf; 
			varKey = Field.Key;
			Page  = Page + Chars.LF + Indent + Chars.Tab + odSupplementString(varKey, Align) + " =  " + String(Value);
			
		EndDo;
		
	EndIf;
	
	ErrorMessageStringField = Page;
	
	If SetErrorFlag Then
		
		SetErrorFlag();
		
		ExchangeExecutionResult = ?(ExchangeExecutionResult = Undefined,
										Enums.ExchangeExecutionResults.Error,
										ExchangeExecutionResult);
		//
	EndIf;
	
	SetExchangeResult(ExchangeExecutionResult);
	
	If DataProtocolFile <> Undefined Then
		
		If SetErrorFlag Then
			
			DataProtocolFile.WriteLine(Chars.LF + "Error.");
			
		EndIf;
		
		If SetErrorFlag OR UnconditionalWriteToExchangeProtocol OR OutputInfoMessagesToProtocol Then
			
			DataProtocolFile.WriteLine(Chars.LF + ErrorMessageString());
		
		EndIf;
		
	EndIf;
	
	If ExchangeExecutionResultError(ExchangeExecutionResult) Then
		
		ELLevel = EventLogLevel.Error;
		
	ElsIf ExchangeExecutionResultWarning(ExchangeExecutionResult) Then
		
		ELLevel = EventLogLevel.Warning;
		
	Else
		
		ELLevel = EventLogLevel.Information;
		
	EndIf;
	
	// Registering an event in the event log.
	WriteEventLogDataExchange(ErrorMessageString(), ELLevel);
	
	Return ErrorMessageString();
	
EndFunction

Function WriteErrorInfoToProtocol(ErrorMessageCode, ErrorRow, Object, ObjectType = Undefined)
	
	WP         = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.Object  = Object;
	
	If ObjectType <> Undefined Then
		WP.ObjectType     = ObjectType;
	EndIf;	
		
	ErrorRow = WriteToExecutionProtocol(ErrorMessageCode, WP);	
	
	Return ErrorRow;
	
EndFunction

Procedure WriteDataClearingHandlerErrorInfo(ErrorMessageCode, ErrorRow, DataClearingRuleName, Object = "", HandlerName = "")
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.DPR                    = DataClearingRuleName;
	
	If Object <> "" Then
		WP.Object                 = String(Object) + "  (" + TypeOf(Object) + ")";
	EndIf;
	
	If HandlerName <> "" Then
		WP.Handler             = HandlerName;
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

Procedure WriteInfoOnOCRHandlerImportError(ErrorMessageCode, ErrorRow, RuleName, Source = "", 
	ObjectType, Object = Undefined, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.OCRName                 = RuleName;
	WP.ObjectType             = ObjectType;
	WP.Handler             = HandlerName;
						
	If Not IsBlankString(Source) Then
							
		WP.Source           = Source;
							
	EndIf;
						
	If Object <> Undefined Then
	
		WP.Object                 = String(Object);
		
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

Procedure WriteInfoOnOCRHandlerExportError(ErrorMessageCode, ErrorRow, OCR, Source, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
	
	Try
		WP.Object                 = String(Source) + "  (" + TypeOf(Source) + ")";
	Except
		WP.Object                 = "(" + TypeOf(Source) + ")";
	EndTry;
	
	WP.Handler             = HandlerName;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

Procedure WriteErrorInfoPCRHandlers(ErrorMessageCode, ErrorRow, OCR, PCR, Source = "", 
	HandlerName = "", Value = Undefined)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
	WP.PCR                    = PCR.Name + "  (" + PCR.Description + ")";
	
	Try
		WP.Object                 = String(Source) + "  (" + TypeOf(Source) + ")";
	Except
		WP.Object                 = "(" + TypeOf(Source) + ")";
	EndTry;
	
	WP.DestinationProperty      = PCR.Destination + "  (" + PCR.DestinationType + ")";
	
	If HandlerName <> "" Then
		WP.Handler         = HandlerName;
	EndIf;
	
	If Value <> Undefined Then
		WP.ConvertedValue = String(Value) + "  (" + TypeOf(Value) + ")";
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure	

Procedure WriteErrorInfoDERHandlers(ErrorMessageCode, ErrorRow, RuleName, HandlerName, Object = Undefined)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.DER                    = RuleName;
	
	If Object <> Undefined Then
		WP.Object                 = String(Object) + "  (" + TypeOf(Object) + ")";
	EndIf;
	
	WP.Handler             = HandlerName;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

Function WriteErrorInfoConversionHandlers(ErrorMessageCode, ErrorRow, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorRow);
	WP.Handler             = HandlerName;
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	Return ErrorMessageString;
	
EndFunction

#EndRegion

#Region ExchangeRulesImportProcedures

// Imports the property group conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - a value table containing PCR.
// 
Procedure ImportPGCR(ExchangeRules, PropertiesTable, DisabledProperties, SynchronizeByID, OCRName = "")
	
	IsDisabledField = deAttribute(ExchangeRules, BooleanType, "Disable");
	
	If IsDisabledField Then
		
		NewRow = DisabledProperties.Add();
		
	Else
		
		NewRow = PropertiesTable.Add();
		
	EndIf;
	
	NewRow.IsFolder     = True;
	
	NewRow.GroupRules            = PropertyConversionRuleTable.Copy();
	NewRow.DisabledGroupRules = PropertyConversionRuleTable.Copy();
	
	// Default values
	NewRow.DoNotReplace               = False;
	NewRow.GetFromIncomingData = False;
	NewRow.SimplifiedPropertyExport = False;
	
	SearchFieldsString = "";
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Destination" Then
			NewRow.Destination		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Property" Then
			
			PCRParent = ?(ValueIsFilled(NewRow.Source), "_" + NewRow.Source, "_" + NewRow.Destination);
			
			OCRProperties = New Structure;
			OCRProperties.Insert("OCRName", OCRName);
			OCRProperties.Insert("ParentName", PCRParent);
			OCRProperties.Insert("SynchronizeByID", SynchronizeByID);
			
			ImportPCR(ExchangeRules, NewRow.GroupRules, NewRow.DisabledGroupRules, OCRProperties, SearchFieldsString);

		ElsIf NodeName = "BeforeProcessExport" Then
			NewRow.BeforeProcessExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeProcessExportHandler = Not IsBlankString(NewRow.BeforeProcessExport);
			
		ElsIf NodeName = "AfterProcessExport" Then
			NewRow.AfterProcessExport	= deElementValue(ExchangeRules, StringType);
			NewRow.HasAfterProcessExportHandler = Not IsBlankString(NewRow.AfterProcessExport);
			
		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DoNotReplace" Then
			NewRow.DoNotReplace = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
	        NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "ExportGroupToFile" Then
			NewRow.ExportGroupToFile = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf (NodeName = "Group") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If NewRow.HasBeforeProcessExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_BeforeProcessExport_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.BeforeExportProcessHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasAfterProcessExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_AfterProcessExport_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.AfterExportProcessHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasBeforeExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_BeforeExportProperty_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.BeforeExportHandlerName = HandlerName;

	EndIf;
	
	If NewRow.HasOnExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_OnExportProperty[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.OnExportHandlerName = HandlerName;

	EndIf;
	
	If NewRow.HasAfterExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_AfterExportProperty[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.AfterExportHandlerName = HandlerName;
		
	EndIf;
	
	NewRow.SearchFieldsString = SearchFieldsString;
	
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler OR NewRow.HasAfterExportHandler;
	
	NewRow.XMLNodeRequiredOnExportGroup = NewRow.HasAfterProcessExportHandler; 

EndProcedure

Procedure AddFieldToSearchString(SearchFieldsString, FieldName)
	
	If IsBlankString(FieldName) Then
		Return;
	EndIf;
	
	If NOT IsBlankString(SearchFieldsString) Then
		SearchFieldsString = SearchFieldsString + ",";
	EndIf;
	
	SearchFieldsString = SearchFieldsString + FieldName;
	
EndProcedure

// Imports the property group conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - a value table containing PCR.
// 
// Parameters:
//  ExchangeRules  - XMLReader - an object that contains the text of exchange rules.
//  PropertiesTable - Value table - PCR table.
//  DisabledProperties - Value table - disabled PCR table.
//  OCRProperties - Structure - additional information on data to change:
//    * OCRName - String - an OCR name.
//    * SynchronizeByID - Boolean - a flag showing whether an algorithm for search by UUID is used.
//    * ParentName - String - a name of parent OCR or PGCR.
//  SearchFieldsString - String - OCR search properties.
//  SearchTable - Value table - PCR table (synchronizing PCR.)
//
Procedure ImportPCR(ExchangeRules,
	PropertiesTable,
	DisabledProperties,
	OCRProperties,
	SearchFieldsString = "",
	SearchTable = Undefined)
	
	OCRName = ?(ValueIsFilled(OCRProperties.OCRName), OCRProperties.OCRName, "");
	ParentName = ?(ValueIsFilled(OCRProperties.ParentName), OCRProperties.ParentName, "");
	SynchronizeByID = ?(ValueIsFilled(OCRProperties.SynchronizeByID),
		OCRProperties.SynchronizeByID, False);
	
	IsDisabledField        = deAttribute(ExchangeRules, BooleanType, "Disable");
	IsSearchField           = deAttribute(ExchangeRules, BooleanType, "Search");
	IsRequiredProperty = deAttribute(ExchangeRules, BooleanType, "Required");
	
	If IsDisabledField Then
		
		NewRow = DisabledProperties.Add();
		
	ElsIf IsRequiredProperty AND SearchTable <> Undefined Then
		
		NewRow = SearchTable.Add();
		
	ElsIf IsSearchField AND SearchTable <> Undefined Then
		
		NewRow = SearchTable.Add();
		
	Else
		
		NewRow = PropertiesTable.Add();
		
	EndIf;
	
	// Default values
	NewRow.DoNotReplace               = False;
	NewRow.GetFromIncomingData = False;
	NewRow.IsRequiredProperty  = IsRequiredProperty;
	NewRow.IsSearchField            = IsSearchField;
		
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Destination" Then
			NewRow.Destination		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, StringType, "Type");
			
			If Not IsDisabledField Then
				
				// Filling in the SearchFieldsString variable to search by all tabular section attributes with PCR.
				AddFieldToSearchString(SearchFieldsString, NewRow.Destination);
				
			EndIf;
			
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DoNotReplace" Then
			NewRow.DoNotReplace = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
	        NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "CastToLength" Then
			NewRow.CastToLength = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "ParameterForTransferName" Then
			NewRow.ParameterForTransferName = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SearchByEqualDate" Then
			NewRow.SearchByEqualDate = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf (NodeName = "Property") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If NewRow.HasBeforeExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_BeforeExportProperty_[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		
		NewRow.BeforeExportHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasOnExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_OnExportProperty[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		
		NewRow.OnExportHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasAfterExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_AfterExportProperty[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));

		NewRow.AfterExportHandlerName = HandlerName;
		
	EndIf;
	
	NewRow.SimplifiedPropertyExport = NOT NewRow.GetFromIncomingData
		AND NOT NewRow.HasBeforeExportHandler
		AND NOT NewRow.HasOnExportHandler
		AND NOT NewRow.HasAfterExportHandler
		AND IsBlankString(NewRow.ConversionRule)
		AND NewRow.SourceType = NewRow.DestinationType
		AND (NewRow.SourceType = "String" OR NewRow.SourceType = "Number" OR NewRow.SourceType = "Boolean" OR NewRow.SourceType = "Date");
		
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler OR NewRow.HasAfterExportHandler;
	
EndProcedure

// Imports property conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - a value table containing PCR.
//  SearchTable - a value table containing PCR (synchronizing).
// 
Procedure ImportProperties(ExchangeRules,
							PropertiesTable,
							SearchTable,
							DisabledProperties,
							Val SynchronizeByID = False,
							OCRName = "")
	//
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Property" Then
			
			OCRProperties = New Structure;
			OCRProperties.Insert("OCRName", OCRName);
			OCRProperties.Insert("ParentName", "");
			OCRProperties.Insert("SynchronizeByID", SynchronizeByID);
			ImportPCR(ExchangeRules, PropertiesTable, DisabledProperties, OCRProperties,, SearchTable);
			
		ElsIf NodeName = "Group" Then
			
			ImportPGCR(ExchangeRules, PropertiesTable, DisabledProperties, SynchronizeByID, OCRName);
			
		ElsIf (NodeName = "Properties") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	PropertiesTable.Sort("Order");
	SearchTable.Sort("Order");
	DisabledProperties.Sort("Order");
	
EndProcedure

// Imports the value conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  Values       - a map of source object values to destination object presentation strings.
//                   
//  SourceType   - value of the Type type - source object type.
// 
Procedure ImportVCR(ExchangeRules, Values, SourceType)
	
	Source = "";
	Destination = "";
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Source" Then
			Source = deElementValue(ExchangeRules, StringType);
		ElsIf NodeName = "Destination" Then
			Destination = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Value") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If Not IsBlankString(Source) Then
		Values.Insert(Source, Destination);
	EndIf;
	
EndProcedure

// Imports value conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  Values       - a map of source object values to destination object presentation strings.
//                   
//  SourceType   - value of the Type type - source object type.
// 
Procedure LoadValues(ExchangeRules, Values, SourceType);

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Value" Then
			ImportVCR(ExchangeRules, Values, SourceType);
		ElsIf (NodeName = "Values") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Imports the object conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportConversionRule(ExchangeRules, XMLWriter)

	XMLWriter.WriteStartElement("Rule");

	NewRow = ConversionRulesTable.Add();
	
	// Default values
	
	NewRow.RememberExported = True;
	NewRow.DoNotReplace            = False;
	NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	
	SearchInTabularSections = New ValueTable;
	SearchInTabularSections.Columns.Add("ItemName");
	SearchInTabularSections.Columns.Add("KeySearchFieldArray");
	SearchInTabularSections.Columns.Add("KeySearchFields");
	SearchInTabularSections.Columns.Add("Valid", deTypeDetails("Boolean"));
	
	NewRow.SearchInTabularSections = SearchInTabularSections;		
	
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
				
		If      NodeName = "Code" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.Name = Value;
			
		ElsIf NodeName = "Description" Then
			
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SynchronizeByID" Then
			
			NewRow.SynchronizeByID = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.SynchronizeByID);
			
		ElsIf NodeName = "DoNotCreateIfNotFound" Then
			
			NewRow.DoNotCreateIfNotFound = deElementValue(ExchangeRules, BooleanType);			
			
		ElsIf NodeName = "RecordObjectChangeAtSenderNode" Then // is not supported
			
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "DoNotExportPropertyObjectsByRefs" Then
			
			NewRow.DoNotExportPropertyObjectsByRefs = deElementValue(ExchangeRules, BooleanType);
						
		ElsIf NodeName = "SearchBySearchFieldsIfNotFoundByID" Then
			
			NewRow.SearchBySearchFieldsIfNotFoundByID = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.SearchBySearchFieldsIfNotFoundByID);
			
		ElsIf NodeName = "OnMoveObjectByRefSetGIUDOnly" Then
			
			NewRow.OnMoveObjectByRefSetGIUDOnly = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.OnMoveObjectByRefSetGIUDOnly);
			
		ElsIf NodeName = "DoNotReplaceObjectCreatedInDestinationInfobase" Then
			
			NewRow.DoNotReplaceObjectCreatedInDestinationInfobase = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.DoNotReplaceObjectCreatedInDestinationInfobase);		
			
		ElsIf NodeName = "UseQuickSearchOnImport" Then
			
			NewRow.UseQuickSearchOnImport = deElementValue(ExchangeRules, BooleanType);	
			
		ElsIf NodeName = "GenerateNewNumberOrCodeIfNotSet" Then
			
			NewRow.GenerateNewNumberOrCodeIfNotSet = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.GenerateNewNumberOrCodeIfNotSet);
						
		ElsIf NodeName = "DoNotRememberExported" Then
			
			NewRow.RememberExported = Not deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "DoNotReplace" Then
			
			Value = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.DoNotReplace = Value;
			
		ElsIf NodeName = "Destination" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			
			NewRow.Destination     = Value;
			NewRow.DestinationType = Value;
			
		ElsIf NodeName = "Source" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			
			NewRow.SourceType = Value;
			
			If ExchangeMode = "Load" Then
				
				NewRow.Source = Value;
				
			Else
				
				If Not IsBlankString(Value) Then
					
					If Not ExchangeRuleInfoImportMode Then
						
						Try
							
							NewRow.Source = Type(Value);
							
							Managers[NewRow.Source].OCR = NewRow;
							
						Except
							
							WriteErrorInfoToProtocol(11, ErrorDescription(), String(NewRow.Source));
							
						EndTry;
					
					EndIf;
					
				EndIf;
				
			EndIf;
			
		// Properties
		
		ElsIf NodeName = "Properties" Then
		
			NewRow.Properties            = PropertyConversionRuleTable.Copy();
			NewRow.SearchProperties      = PropertyConversionRuleTable.Copy();
			NewRow.DisabledProperties = PropertyConversionRuleTable.Copy();
			
			If NewRow.SynchronizeByID = True Then
				
				SearchPropertyUUID = NewRow.SearchProperties.Add();
				SearchPropertyUUID.Name      = "{UUID}";
				SearchPropertyUUID.Source = "{UUID}";
				SearchPropertyUUID.Destination = "{UUID}";
				SearchPropertyUUID.IsRequiredProperty = True;
				
			EndIf;
			
			ImportProperties(ExchangeRules, NewRow.Properties, NewRow.SearchProperties, NewRow.DisabledProperties, NewRow.SynchronizeByID, NewRow.Name);
			
		// Values
		ElsIf NodeName = "Values" Then
			
			LoadValues(ExchangeRules, NewRow.PredefinedDataReadValues, NewRow.Source);
			
		// EVENT HANDLERS
		ElsIf NodeName = "BeforeExport" Then
		
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_BeforeExportObject";
			NewRow.BeforeExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_OnExportObject";
			NewRow.OnExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_AfterExportObject";
			NewRow.AfterExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "AfterExportToFile" Then
			
			NewRow.AfterExportToFile = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_AfterExportObjectToExchangeFile";
			NewRow.AfterExportToFileHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasAfterExportToFileHandler  = Not IsBlankString(NewRow.AfterExportToFile);
			
		// For import
		
		ElsIf NodeName = "BeforeImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.BeforeImport               = Value;
				HandlerName = "OCR_[OCRName]_BeforeImportObject";
				NewRow.BeforeImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasBeforeImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "OnImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.OnImport               = Value;
				HandlerName = "OCR_[OCRName]_OnImportObject";
				NewRow.OnImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasOnImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf; 
			
		ElsIf NodeName = "AfterImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.AfterImport               = Value;
				HandlerName = "OCR_[OCRName]_AfterImportObject";
				NewRow.AfterImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasAfterImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "SearchFieldSequence" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			NewRow.HasSearchFieldSequenceHandler = Not IsBlankString(Value);
			
			If ExchangeMode = "Load" Then
				
				NewRow.SearchFieldSequence = Value;
				HandlerName = "OCR_[OCRName]_SearchFieldsSequence";
				NewRow.SearchFieldSequenceHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "ExchangeObjectsPriority" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If Value = "Below" Then
				NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority;
			ElsIf Value = "Matches" Then
				NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch;
			EndIf;
			
		// Search option settings.
		ElsIf NodeName = "ObjectSearchOptionsSettings" Then
		
			ImportSearchVariantSettings(ExchangeRules, NewRow);
			
		ElsIf NodeName = "SearchInTabularSections" Then
			
			// Importing information by search key fields in tabular sections.
			Value = deElementValue(ExchangeRules, StringType);
			
			For Number = 1 To StrLineCount(Value) Do
				
				CurrentRow = StrGetLine(Value, Number);
				
				SearchString = SplitWithSeparator(CurrentRow, ":");
				
				TableRow = NewRow.SearchInTabularSections.Add();
				
				TableRow.ItemName               = CurrentRow;
				TableRow.KeySearchFields        = SearchString;
				TableRow.KeySearchFieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SearchString);
				TableRow.Valid                  = TableRow.KeySearchFieldArray.Count() <> 0;
				
			EndDo;
			
		ElsIf NodeName = "SearchFields" Then
			
			NewRow.SearchFields = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "TableFields" Then
			
			NewRow.TableFields = deElementValue(ExchangeRules, StringType);
			
		ElsIf (NodeName = "Rule") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
		
			Break;
			
		EndIf;
		
	EndDo;
	
	If ExchangeMode <> "Load" Then
		
		// RECEIVING PROPERTIES OF TABULAR SECTION FIELDS SEARCH FOR DATA IMPORT RULES (XMLWriter)
		
		ResultingTSSearchString = "";
		
		// Sending details of tabular section search fields to the destination.
		For Each PropertyString In NewRow.Properties Do
			
			If Not PropertyString.IsFolder
				OR IsBlankString(PropertyString.DestinationKind)
				OR IsBlankString(PropertyString.Destination) Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(PropertyString.SearchFieldsString) Then
				Continue;
			EndIf;
			
			ResultingTSSearchString = ResultingTSSearchString + Chars.LF + PropertyString.DestinationKind + "." + PropertyString.Destination + ":" + PropertyString.SearchFieldsString;
			
		EndDo;
		
		ResultingTSSearchString = TrimAll(ResultingTSSearchString);
		
		If Not IsBlankString(ResultingTSSearchString) Then
			
			deWriteElement(XMLWriter, "SearchInTabularSections", ResultingTSSearchString);
			
		EndIf;
		
	EndIf;
	
	TableFields = "";
	SearchFields = "";
	If NewRow.Properties.Count() > 0
		Or NewRow.SearchProperties.Count() > 0 Then
		
		ArrayProperties = NewRow.Properties.Copy(New Structure("IsFolder, ParameterForTransferName", False, ""), "Destination").UnloadColumn("Destination");
		
		ArraySearchProperties               = NewRow.SearchProperties.Copy(New Structure("IsFolder, ParameterForTransferName", False, ""), "Destination").UnloadColumn("Destination");
		SearchPropertyAdditionalArray = NewRow.Properties.Copy(New Structure("IsSearchField, ParameterForTransferName", True, ""), "Destination").UnloadColumn("Destination");
		
		For each Value In SearchPropertyAdditionalArray Do
			
			ArraySearchProperties.Add(Value);
			
		EndDo;
		
		// Deleting a {UUID} value from the array of search fields.
		CommonClientServer.DeleteValueFromArray(ArraySearchProperties, "{UUID}");
		
		// Getting the ArrayProperties variable value.
		TableFieldsTable = New ValueTable;
		TableFieldsTable.Columns.Add("Destination");
		
		CommonClientServer.SupplementTableFromArray(TableFieldsTable, ArrayProperties, "Destination");
		CommonClientServer.SupplementTableFromArray(TableFieldsTable, ArraySearchProperties, "Destination");
		
		TableFieldsTable.GroupBy("Destination");
		ArrayProperties = TableFieldsTable.UnloadColumn("Destination");
		
		TableFields = StrConcat(ArrayProperties, ",");
		SearchFields  = StrConcat(ArraySearchProperties, ",");
		
	EndIf;
	
	If ExchangeMode = "Load" Then
		
		// Correspondent rules import - record search fields and table fields.
		If Not ValueIsFilled(NewRow.TableFields) Then
			NewRow.TableFields = TableFields;
		EndIf;
		
		If Not ValueIsFilled(NewRow.SearchFields) Then
			NewRow.SearchFields = SearchFields;
		EndIf;
		
	Else
		
		If Not IsBlankString(TableFields) Then
			deWriteElement(XMLWriter, "TableFields", TableFields);
		EndIf;
		
		If Not IsBlankString(SearchFields) Then
			deWriteElement(XMLWriter, "SearchFields", SearchFields);
		EndIf;
		
	EndIf;
	
	// close node
	XMLWriter.WriteEndElement(); // Rule
	
	// Quick access to OCR by name.
	Rules.Insert(NewRow.Name, NewRow);
	
EndProcedure

Procedure ImportSearchVariantSetting(ExchangeRules, NewRow)
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If NodeName = "AlgorithmSettingName" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.AlgorithmSettingName = Value;
			EndIf;
			
		ElsIf NodeName = "UserSettingsName" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.UserSettingsName = Value;
			EndIf;
			
		ElsIf NodeName = "SettingDetailsForUser" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.SettingDetailsForUser = Value;
			EndIf;
			
		ElsIf (NodeName = "SearchMode") AND (NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ImportSearchVariantSettings(ExchangeRules, BaseOCRRow)

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If NodeName = "SearchMode" Then
			
			If ExchangeRuleInfoImportMode Then
				SettingString = SearchFieldInfoImportResultTable.Add();
				SettingString.ExchangeRuleCode = BaseOCRRow.Name;
				SettingString.ExchangeRuleDescription = BaseOCRRow.Description;
			Else
				SettingString = Undefined;
			EndIf;
			
			ImportSearchVariantSetting(ExchangeRules, SettingString);
			
		ElsIf (NodeName = "ObjectSearchOptionsSettings") AND (NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Imports object conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportConversionRules(ExchangeRules, XMLWriter)
	
	ConversionRulesTable.Clear();
	
	XMLWriter.WriteStartElement("ObjectConversionRules");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Rule" Then
			
			ImportConversionRule(ExchangeRules, XMLWriter);
			
		ElsIf (NodeName = "ObjectConversionRules") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	ImportConversionRule_ExchangeObjectsExportModes(XMLWriter);
	
	XMLWriter.WriteEndElement();
	
	ConversionRulesTable.Indexes.Add("Destination");
	
EndProcedure

// Imports the data clearing rule group according to the exchange rule format.
//
// Parameters:
//  NewRow    - a value tree row that describes a data clearing rules group.
// 
Procedure ImportDPRGroup(ExchangeRules, NewRow)

	NewRow.IsFolder = True;
	NewRow.Enable  = Number(Not deAttribute(ExchangeRules, BooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If      NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "Rule" Then
			VTRow = NewRow.Rows.Add();
			ImportDPR(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") AND (NodeType = XMLNodeTypeStartElement) Then
			VTRow = NewRow.Rows.Add();
			ImportDPRGroup(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") AND (NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Imports the data clearing rule according to the format of exchange rules.
//
// Parameters:
//  NewString    - a value tree row describing the data clearing rule.
// 
Procedure ImportDPR(ExchangeRules, NewRow)
	
	NewRow.Enable = Number(Not deAttribute(ExchangeRules, BooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Code" Then
			Value = deElementValue(ExchangeRules, StringType);
			NewRow.Name = Value;

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "SelectionObject" Then
			
			If Not ExchangeRuleInfoImportMode Then
			
				SelectionObject = deElementValue(ExchangeRules, StringType);
				If Not IsBlankString(SelectionObject) Then
					NewRow.SelectionObject = Type(SelectionObject);
				EndIf;
				
			EndIf;

		ElsIf NodeName = "DeleteForPeriod" Then
			NewRow.DeleteForPeriod = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Directly" Then
			NewRow.Directly = deElementValue(ExchangeRules, BooleanType);

		
		// EVENT HANDLERS

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_BeforeProcessRule";
			NewRow.BeforeProcessHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_AfterProcessRule_";
			NewRow.AfterProcessHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		ElsIf NodeName = "BeforeDeleteObject" Then
			NewRow.BeforeDelete = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_BeforeDeleteObject";
			NewRow.BeforeDeleteHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		// Exit
		ElsIf (NodeName = "Rule") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
			
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Imports data clearing rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportClearingRules(ExchangeRules, XMLWriter)

	CleanupRulesTable.Rows.Clear();
	VTRows = CleanupRulesTable.Rows;
	
	XMLWriter.WriteStartElement("DataClearingRules");

	While ExchangeRules.Read() Do
		
		NodeType = ExchangeRules.NodeType;
		
		If NodeType = XMLNodeTypeStartElement Then
			NodeName = ExchangeRules.LocalName;
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteStartElement(ExchangeRules.Name);
				While ExchangeRules.ReadAttribute() Do
					XMLWriter.WriteAttribute(ExchangeRules.Name, ExchangeRules.Value);
				EndDo;
			Else
				If NodeName = "Rule" Then
					VTRow = VTRows.Add();
					ImportDPR(ExchangeRules, VTRow);
				ElsIf NodeName = "Group" Then
					VTRow = VTRows.Add();
					ImportDPRGroup(ExchangeRules, VTRow);
				EndIf;
			EndIf;
		ElsIf NodeType = XMLNodeTypeEndElement Then
			NodeName = ExchangeRules.LocalName;
			If NodeName = "DataClearingRules" Then
				Break;
			Else
				If ExchangeMode <> "Load" Then
					XMLWriter.WriteEndElement();
				EndIf;
			EndIf;
		ElsIf NodeType = XMLNodeTypeText Then
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteText(ExchangeRules.Value);
			EndIf;
		EndIf; 
	EndDo;

	VTRows.Sort("Order", True);
	
	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the algorithm according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportAlgorithm(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Text" Then
			Text = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Algorithm") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;

	
	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Algorithms.Insert(Name, Text);
		Else
			XMLWriter.WriteStartElement("Algorithm");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Algorithms.Insert(Name, Text);
		EndIf;
	EndIf;
	
	
EndProcedure

// Imports algorithms according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportAlgorithms(ExchangeRules, XMLWriter)

	Algorithms.Clear();

	XMLWriter.WriteStartElement("Algorithms");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		If      NodeName = "Algorithm" Then
			ImportAlgorithm(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Algorithms") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the query according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportQuery(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Text" Then
			Text = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Query") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;

	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		Else
			XMLWriter.WriteStartElement("Query");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		EndIf;
	EndIf;
	
EndProcedure

// Imports queries according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportQueries(ExchangeRules, XMLWriter)

	Queries.Clear();

	XMLWriter.WriteStartElement("Queries");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Query" Then
			ImportQuery(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Queries") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports parameters according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
// 
Procedure ImportParameters(ExchangeRules, XMLWriter)

	Parameters.Clear();
	EventsAfterParametersImport.Clear();
	ParameterSetupTable.Clear();
	
	XMLWriter.WriteStartElement("Parameters");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;

		If NodeName = "Parameter" AND NodeType = XMLNodeTypeStartElement Then
			
			// Importing by the 2.01 rule version.
			Name                     = deAttribute(ExchangeRules, StringType, "Name");
			Description            = deAttribute(ExchangeRules, StringType, "Description");
			SetInDialog   = deAttribute(ExchangeRules, BooleanType, "SetInDialog");
			ValueTypeString      = deAttribute(ExchangeRules, StringType, "ValueType");
			UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
			PassParameterOnExport = deAttribute(ExchangeRules, BooleanType, "PassParameterOnExport");
			ConversionRule = deAttribute(ExchangeRules, StringType, "ConversionRule");
			AfterParameterImportAlgorithm = deAttribute(ExchangeRules, StringType, "AfterImportParameter");
			
			If Not IsBlankString(AfterParameterImportAlgorithm) Then
				
				EventsAfterParametersImport.Insert(Name, AfterParameterImportAlgorithm);
				
			EndIf;
			
			// Determining value types and setting initial values.
			If Not IsBlankString(ValueTypeString) Then
				
				Try
					DataValueType = Type(ValueTypeString);
					TypeDefined = TRUE;
				Except
					TypeDefined = FALSE;
				EndTry;
				
			Else
				
				TypeDefined = FALSE;
				
			EndIf;
			
			If TypeDefined Then
				ParameterValue = deGetEmptyValue(DataValueType);
				Parameters.Insert(Name, ParameterValue);
			Else
				ParameterValue = "";
				Parameters.Insert(Name);
			EndIf;
						
			If SetInDialog = TRUE Then
				
				TableRow              = ParameterSetupTable.Add();
				TableRow.Description = Description;
				TableRow.Name          = Name;
				TableRow.Value = ParameterValue;				
				TableRow.PassParameterOnExport = PassParameterOnExport;
				TableRow.ConversionRule = ConversionRule;
				
			EndIf;
			
			If UsedOnImport
				AND ExchangeMode = "DataExported" Then
				
				XMLWriter.WriteStartElement("Parameter");
				SetAttribute(XMLWriter, "Name",   Name);
				SetAttribute(XMLWriter, "Description", Description);
					
				If NOT IsBlankString(AfterParameterImportAlgorithm) Then
					SetAttribute(XMLWriter, "AfterImportParameter", XMLString(AfterParameterImportAlgorithm));
				EndIf;
				
				XMLWriter.WriteEndElement();
				
			EndIf;

		ElsIf (NodeType = XMLNodeTypeText) Then
			
			// Importing from the string to provide 2.0 compatibility.
			ParametersString = ExchangeRules.Value;
			For each Par In ArrayFromString(ParametersString) Do
				Parameters.Insert(Par);
			EndDo;
			
		ElsIf (NodeName = "Parameters") AND (NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();

EndProcedure

// Imports the data processor according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportDataProcessor(ExchangeRules, XMLWriter)

	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	Description            = deAttribute(ExchangeRules, StringType, "Description");
	IsSetupDataProcessor   = deAttribute(ExchangeRules, BooleanType, "IsSetupDataProcessor");
	
	UsedOnExport = deAttribute(ExchangeRules, BooleanType, "UsedOnExport");
	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");

	ParametersString        = deAttribute(ExchangeRules, StringType, "Parameters");
	
	DataProcessorStorage      = deElementValue(ExchangeRules, ValueStorageType);

	AdditionalDataProcessorParameters.Insert(Name, ArrayFromString(ParametersString));
	
	
	If UsedOnImport Then
		If ExchangeMode <> "Load" Then
			XMLWriter.WriteStartElement("DataProcessor");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",                     Name);
			SetAttribute(XMLWriter, "Description",            Description);
			SetAttribute(XMLWriter, "IsSetupDataProcessor",   IsSetupDataProcessor);
			XMLWriter.WriteText(XMLString(DataProcessorStorage));
			XMLWriter.WriteEndElement();
		EndIf;
	EndIf;

	If IsSetupDataProcessor Then
		If (ExchangeMode = "Load") AND UsedOnImport Then
			ImportSettingsDataProcessors.Add(Name, Description, , );
			
		ElsIf (ExchangeMode = "DataExported") AND UsedOnExport Then
			ExportSettingsDataProcessors.Add(Name, Description, , );
			
		EndIf; 
	EndIf; 
	
EndProcedure

// Imports external data processors according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  WriteXML - Object of the XMLWrite type  - rules to be saved into the exchange file and used on 
//                   data import.
// 
Procedure ImportDataProcessors(ExchangeRules, XMLWriter)

	AdditionalDataProcessors.Clear();
	AdditionalDataProcessorParameters.Clear();
	
	ExportSettingsDataProcessors.Clear();
	ImportSettingsDataProcessors.Clear();

	XMLWriter.WriteStartElement("DataProcessors");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "DataProcessor" Then
			ImportDataProcessor(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "DataProcessors") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the data export rule according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  NewString    - a value tree row describing the data export rule.
// 
Procedure ImportDER(ExchangeRules)
	
	NewRow = ExportRuleTable.Add();
	
	NewRow.Enable = Not deAttribute(ExchangeRules, BooleanType, "Disable");
		
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		If NodeName = "Code" Then
			
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SelectExportDataInSingleQuery" Then
			
			// This parameter is ignored during online data exchange.
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "DoNotExportObjectsCreatedInDestinationInfobase" Then
			
			NewRow.DoNotExportObjectsCreatedInDestinationInfobase = deElementValue(ExchangeRules, BooleanType);

		ElsIf NodeName = "DestinationTypeName" Then
			
			NewRow.DestinationTypeName = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "SelectionObject" Then
			
			SelectionObject = deElementValue(ExchangeRules, StringType);
			
			If Not ExchangeRuleInfoImportMode Then
				
				NewRow.SynchronizeByID = SynchronizeByDERID(NewRow.ConversionRule);
				
				If Not IsBlankString(SelectionObject) Then
					
					NewRow.SelectionObject        = Type(SelectionObject);
					
				EndIf;
				
				// For filtering using the query builder.
				If StrFind(SelectionObject, "Ref.") Then
					NewRow.ObjectForQueryName = StrReplace(SelectionObject, "Ref.", ".");
				Else
					NewRow.ObjectNameForRegisterQuery = StrReplace(SelectionObject, "Record.", ".");
				EndIf;
				
			EndIf;

		ElsIf NodeName = "ConversionRuleCode" Then
			
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);

		// EVENT HANDLERS

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_BeforeProcessRule";
			NewRow.BeforeProcessHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_AfterProcessRule_";
			NewRow.AfterProcessHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
		
		ElsIf NodeName = "BeforeExportObject" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_BeforeExportObject";
			NewRow.BeforeExportHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf NodeName = "AfterExportObject" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_AfterExportObject";
			NewRow.AfterExportHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf (NodeName = "Rule") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf;
	
EndProcedure

// Imports data export rules according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
// 
Procedure ImportExportRules(ExchangeRules)
	
	ExportRuleTable.Clear();
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Rule" Then
			
			ImportDER(ExchangeRules);
			
		ElsIf (NodeName = "DataExportRules") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;

EndProcedure

Function SynchronizeByDERID(Val OCRName)
	
	OCR = FindRule(Undefined, OCRName);
	
	If OCR <> Undefined Then
		
		Return (OCR.SynchronizeByID = True);
		
	EndIf;
	
	Return False;
EndFunction

Procedure ImportConversionRule_ExchangeObjectsExportModes(XMLWriter)
	
	SourceType = "EnumRef.ExchangeObjectExportModes";
	DestinationType = "EnumRef.ExchangeObjectExportModes";
	
	Filter = New Structure;
	Filter.Insert("SourceType", SourceType);
	Filter.Insert("DestinationType", DestinationType);
	
	If ConversionRulesTable.FindRows(Filter).Count() <> 0 Then
		Return;
	EndIf;
	
	NewRow = ConversionRulesTable.Add();
	
	NewRow.RememberExported = True;
	NewRow.DoNotReplace            = False;
	NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	
	NewRow.Properties            = PropertyConversionRuleTable.Copy();
	NewRow.SearchProperties      = PropertyConversionRuleTable.Copy();
	NewRow.DisabledProperties = PropertyConversionRuleTable.Copy();
	
	NewRow.Name = "ExchangeObjectExportModes";
	NewRow.Source = Type(SourceType);
	NewRow.Destination = DestinationType;
	NewRow.SourceType = SourceType;
	NewRow.DestinationType = DestinationType;
	
	Values = New Structure;
	Values.Insert("ExportAlways",           "ExportAlways");
	Values.Insert("ExportByCondition",        "ExportByCondition");
	Values.Insert("ExportIfNecessary", "ExportIfNecessary");
	Values.Insert("ManualExport",          "ManualExport");
	Values.Insert("DoNotExport",               "DoNotExport");
	NewRow.PredefinedDataReadValues = Values;
	
	SearchInTabularSections = New ValueTable;
	SearchInTabularSections.Columns.Add("ItemName");
	SearchInTabularSections.Columns.Add("KeySearchFieldArray");
	SearchInTabularSections.Columns.Add("KeySearchFields");
	SearchInTabularSections.Columns.Add("Valid", deTypeDetails("Boolean"));
	NewRow.SearchInTabularSections = SearchInTabularSections;
	
	Managers[NewRow.Source].OCR = NewRow;
	
	Rules.Insert(NewRow.Name, NewRow);
	
	XMLWriter.WriteStartElement("Rule");
	deWriteElement(XMLWriter, "Code", NewRow.Name);
	deWriteElement(XMLWriter, "Source", NewRow.SourceType);
	deWriteElement(XMLWriter, "Destination", NewRow.DestinationType);
	XMLWriter.WriteEndElement(); // Rule
	
EndProcedure

#EndRegion

#Region ExchangeRulesOperationProcedures

// Searches for the conversion rule by name or according to the passed object type.
// 
//
// Parameters:
//  Object         -  a source object whose conversion rule will be searched.
//  RuleName     - a conversion rule name.
//
// Returns:
//  Conversion rule reference (a row in the rules table).
// 
Function FindRule(Object = Undefined, RuleName = "")

	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		
	Else
		
		Rule = Managers[TypeOf(Object)];
		If Rule <> Undefined Then
			Rule    = Rule.OCR;
			
			If Rule <> Undefined Then 
				RuleName = Rule.Name;
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	Return Rule; 
	
EndFunction

// Restores rules from the internal format.
//
// Parameters:
// 
Procedure RestoreRulesFromInternalFormat() Export

	If SavedSettings = Undefined Then
		Return;
	EndIf;
	
	RulesStructure = SavedSettings.Get();
	
	// Checking storage format version of exchange rules.
	RulesStorageFormatVersion = Undefined;
	RulesStructure.Property("RulesStorageFormatVersion", RulesStorageFormatVersion);
	If RulesStorageFormatVersion <> ExchangeRuleStorageFormatVersion() Then
		Raise NStr("ru = 'Версия формата хранения правил обмена не соответствует ожидаемой.
			|Требуется выполнить загрузку правил обмена повторно.'; 
			|en = 'Unexpected exchange rule storage format version.
			|Please reload the exchange rules.'; 
			|pl = 'Wersja formatu przechowywania reguł wymiany nie odpowiada wersji oczekiwanej.
			|Reguły wymiany muszą być ponownie zaimportowane.';
			|de = 'Die Version des Austausch-Regel Speicherformats entspricht nicht dem erwarteten.
			|Austausch-Regeln müssen erneut importiert werden.';
			|ro = 'Versiunea formatului de stocare a regulilor de schimb nu corespunde celei așteptate.
			|Regulile de schimb trebuie să fie importate din nou.';
			|tr = 'Değişim kuralları depolama biçimi sürümü beklenen sürümle eşleşmiyor. 
			|Yeniden paylaşım kuralları indirilmelidir.'; 
			|es_ES = 'Versión del formato de almacenamiento de las reglas de intercambio no corresponde a la esperada.
			|Se requiere importar las reglas de intercambio de nuevo.'");
	EndIf;
	
	Conversion                = RulesStructure.Conversion;
	ExportRuleTable      = RulesStructure.ExportRuleTable;
	ConversionRulesTable   = RulesStructure.ConversionRulesTable;
	ParameterSetupTable = RulesStructure.ParameterSetupTable;
	
	Algorithms                  = RulesStructure.Algorithms;
	QueriesToRestore   = RulesStructure.Queries;
	Parameters                  = RulesStructure.Parameters;
	
	XMLRules                = RulesStructure.XMLRules;
	TypesForDestinationString   = RulesStructure.TypesForDestinationString;
	
	HasBeforeExportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeExportObject);
	HasAfterExportObjectGlobalHandler     = Not IsBlankString(Conversion.AfterExportObject);
	HasBeforeImportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeImportObject);
	HasAfterObjectImportGlobalHandler     = Not IsBlankString(Conversion.AfterImportObject);
	HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);

	// Restoring queries
	Queries.Clear();
	For Each StructureItem In QueriesToRestore Do
		Query = New Query(StructureItem.Value);
		Queries.Insert(StructureItem.Key, Query);
	EndDo;
	
	InitManagersAndMessages();
	
	Rules.Clear();
	
	For Each TableRow In ConversionRulesTable Do
		
		If ExchangeMode = "DataExported" Then
			
			GetPredefinedDataValues(TableRow);
			
		EndIf;
		
		Rules.Insert(TableRow.Name, TableRow);
		
		If ExchangeMode = "DataExported" AND TableRow.Source <> Undefined Then
			
			Try
				If TypeOf(TableRow.Source) = StringType Then
					Managers[Type(TableRow.Source)].OCR = TableRow;
				Else
					Managers[TableRow.Source].OCR = TableRow;
				EndIf;
			Except
				WriteErrorInfoToProtocol(11, ErrorDescription(), String(TableRow.Source));
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetParameterValueInTable(ParameterName, ParameterValue)
	
	TableRow = ParameterSetupTable.Find(ParameterName, "Name");
	
	If TableRow <> Undefined Then
		
		TableRow.Value = ParameterValue;	
		
	EndIf;
	
EndProcedure

Procedure InitializeInitialParameterValues()
	
	For Each CurParameter In Parameters Do
		
		SetParameterValueInTable(CurParameter.Key, CurParameter.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ClearingRuleProcessing

Procedure DeleteObject(Object, DeleteDirectly, TypeName = "")
	
	ObjectMetadata = Object.Metadata();
	
	If Common.IsCatalog(ObjectMetadata)
		Or Common.IsChartOfCharacteristicTypes(ObjectMetadata)
		Or Common.IsChartOfAccounts(ObjectMetadata)
		Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
		
		Predefined = Object.Predefined;
	Else
		Predefined = False;
	EndIf;
	
	If Predefined Then
		
		Return;
		
	EndIf;
	
	If DeleteDirectly Then
		
		Object.Delete();
		
	Else
		
		SetObjectDeletionMark(Object, True, TypeName);
		
	EndIf;
	
EndProcedure

Procedure ExecuteObjectDeletion(Object, Properties, DeleteDirectly)
	
	If Properties.TypeName = "InformationRegister" Then
		
		Object.Delete();
		
	Else
		
		DeleteObject(Object, DeleteDirectly, Properties.TypeName);
		
	EndIf;
	
EndProcedure

// Deletes (or marks for deletion) a selection object according to the specified rule.
//
// Parameters:
//  Object - selection object to be deleted (or whose deletion mark will be set).
//  Rule - data clearing rule reference.
//  Properties - metadata object properties of the object to be deleted.
//  IncomingData - arbitrary auxiliary data.
// 
Procedure SelectionObjectDeletion(Object, Rule, Properties, IncomingData)
	
	Cancel = False;
	DeleteDirectly = Rule.Directly;
	
	// BeforeSelectionObjectDeletion handler
	
	If Not IsBlankString(Rule.BeforeDelete) Then
	
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_DPR_BeforeDeleteObject(Rule, Object, Cancel, DeleteDirectly, IncomingData);
				
			Else
				
				Execute(Rule.BeforeDelete);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(29, ErrorDescription(), Rule.Name, Object, "BeforeDeleteSelectionObject");
			
		EndTry;
		
		If Cancel Then
		
			Return;
			
		EndIf;
		
	EndIf;

	Try
		
		ExecuteObjectDeletion(Object, Properties, DeleteDirectly);
		
	Except
		
		WriteDataClearingHandlerErrorInfo(24, ErrorDescription(), Rule.Name, Object, "");
		
	EndTry;
	
EndProcedure

// Clears data according to the specified rule.
//
// Parameters:
//  Rule - data clearing rule reference.
// 
Procedure ClearDataByRule(Rule)
	
	// BeforeProcess handle
	
	Cancel			= False;
	DataSelection	= Undefined;
	OutgoingData = Undefined;
	
	// BeforeProcessClearingRule handler
	If Not IsBlankString(Rule.BeforeProcess) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_DPR_BeforeProcessRule(Rule, Cancel, OutgoingData, DataSelection);
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(27, ErrorDescription(), Rule.Name, "", "BeforeProcessClearingRule");
						
		EndTry;
			
		If Cancel Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// Standard selection
	
	Properties = Managers[Rule.SelectionObject];
	
	If Rule.DataFilterMethod = "StandardSelection" Then
		
		TypeName		= Properties.TypeName;
		
		If TypeName = "AccountingRegister" 
			OR TypeName = "Constants" Then
			
			Return;
			
		EndIf;
		
		AllFieldsRequired  = Not IsBlankString(Rule.BeforeDelete);
		
		Selection = SelectionForExpotingDataClearing(Properties, TypeName, True, Rule.Directly, AllFieldsRequired);
		
		While Selection.Next() Do
			
			If TypeName =  "InformationRegister" Then
				
				RecordManager = Properties.Manager.CreateRecordManager(); 
				FillPropertyValues(RecordManager, Selection);
									
				SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);
									
			Else
					
				SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
					
			EndIf;
				
		EndDo;		

	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then

		If DataSelection <> Undefined Then
			
			Selection = SelectionToExportByArbitraryAlgorithm(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
					
					If TypeName =  "InformationRegister" Then
				
						RecordManager = Properties.Manager.CreateRecordManager(); 
						FillPropertyValues(RecordManager, Selection);
											
						SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);
											
					Else
							
						SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
							
					EndIf;					
					
				EndDo;	
				
			Else
				
				For each Object In DataSelection Do
					
					SelectionObjectDeletion(Object.GetObject(), Rule, Properties, OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// AfterProcessClearingRule handler
	
	If Not IsBlankString(Rule.AfterProcess) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_DPR_AfterProcessRule(Rule);
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(28, ErrorDescription(), Rule.Name, "", "AfterProcessClearingRule");
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Iterates the tree of data clearing rules and executes clearing.
//
// Parameters:
//  Rows - value tree rows collection.
// 
Procedure ProcessClearingRules(Rows)
	
	For each ClearingRule In Rows Do
		
		If ClearingRule.Enable = 0 Then
			
			Continue;
			
		EndIf; 

		If ClearingRule.IsFolder Then
			
			ProcessClearingRules(ClearingRule.Rows);
			Continue;
			
		EndIf;
		
		ClearDataByRule(ClearingRule);
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region DataImportProcedures

Procedure StartReadMessage(MessageReader, DataAnalysis = False)
	
	If IsBlankString(ExchangeFileName) Then
		Raise WriteToExecutionProtocol(15);
	EndIf;
	
	ExchangeFile = New XMLReader;
	
	ExchangeFile.OpenFile(ExchangeFileName);
	
	ExchangeFile.Read(); // ExchangeFile
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeFile" Then
		// Perhaps, this is an exchange message in a new format.
		If DataExchangeXDTOServer.CheckExchangeMessageFormat(ExchangeFile) Then
			SwitchToNewExchange();
		Else
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
		EndIf;
	EndIf;
	
	IncomingExchangeMessageFormatVersionField = deAttribute(ExchangeFile, StringType, "FormatVersion");
	
	SourceConfigurationVersion = "";
	Conversion.Property("SourceConfigurationVersion", SourceConfigurationVersion);
	SourceVersionFromRules = deAttribute(ExchangeFile, StringType, "SourceConfigurationVersion");
	MessageText = "";
	
	If DataExchangeServer.DifferentCorrespondentVersions(ExchangePlanName(), EventLogMessageKey(),
		SourceConfigurationVersion, SourceVersionFromRules, MessageText) Then
		
		Raise MessageText;
		
	EndIf;
	
	ExchangeFile.Read(); // ExchangeRules
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeRules" Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	If ConversionRulesTable.Count() = 0 Then
		ImportExchangeRules(ExchangeFile, "XMLReader");
		If ErrorFlag() Then
			Raise NStr("ru = 'При загрузке правил обмена данными возникли ошибки.'; en = 'Cannot load data exchange rules.'; pl = 'Wystąpiły błędy podczas importowania reguł wymiany danych.';de = 'Beim Importieren von Datenaustauschregeln sind Fehler aufgetreten.';ro = 'Erori la importul regulilor schimbului de date.';tr = 'Veri alışverişi kurallarını yüklerken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar las reglas del intercambio de datos.'");
		EndIf;
	Else
		deSkip(ExchangeFile);
	EndIf;
	
	// {Handler: BeforeDataImport} Start
	If Not IsBlankString(Conversion.BeforeImportData) Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeDataImport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeImportData);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(22, ErrorDescription(), NStr("ru = 'ПередЗагрузкойДанных (конвертация)'; en = 'BeforeImportData (conversion)'; pl = 'BeforeDataImport (Konwertowanie)';de = 'VorDemDatenimport (Konvertierung)';ro = 'BeforeDataImport (conversie)';tr = 'VeriİçeAktarılmadanÖnce (Dönüştürme)'; es_ES = 'BeforeDataImport (Conversión)'"));
		EndTry;
		
		If Cancel Then
			Raise NStr("ru = 'Отказ от загрузки сообщения обмена в обработчике ПередЗагрузкойДанных (конвертация).'; en = 'Exchange message import canceled in the BeforeImportData handler (conversion).'; pl = 'Anuluj importowanie wiadomości wymiany BeforeDataImport w programie obsługi (konwertowanie)';de = 'Abbrechen der Importnachricht im Anwender ""VorDemDatenimport"" (Konvertierung).';ro = 'Anulați importul mesajului de schimb în handler BeforeDataImport (conversie).';tr = 'VeriYüklenmedenÖnce işleyicide alışveriş mesajın indirmeyi reddetme (dönüştürme). '; es_ES = 'Cancelar la importación del mensaje de cambio en el manipulador BeforeDataImport (conversión).'");
		EndIf;
		
	EndIf;
	// {Handler: BeforeDataImport} End
	
	ExchangeFile.Read();
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	// CustomSearchSetup (optional)
	If ExchangeFile.LocalName = "CustomSearchSettings" Then
		ImportCustomSearchFieldInfo();
		ExchangeFile.Read();
	EndIf;
	
	// DataTypeInfo (optional)
	If ExchangeFile.LocalName = "DataTypeInformation" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
		EndIf;
		
		If DataForImportTypeMap().Count() > 0 Then
			deSkip(ExchangeFile);
		Else
			ImportDataTypeInfo();
			If ErrorFlag() Then
				Raise NStr("ru = 'При загрузке информации о типах данных возникли ошибки.'; en = 'Errors occurred while importing information about the data types.'; pl = 'Wystąpiły błędy podczas importowania informacji o typach danych.';de = 'Beim Importieren von Informationen zu Datentypen sind Fehler aufgetreten.';ro = 'Au apărut erori la importul de informații privind tipurile de date.';tr = 'Veri türleri hakkında bilgiler yüklenirken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar la información de los tipos de datos.'");
			EndIf;
		EndIf;
		ExchangeFile.Read();
	EndIf;
	
	// ParameterValue (optional) (several.
	If ExchangeFile.LocalName = "ParameterValue" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
		EndIf;
		
		ImportDataExchangeParameterValues();
		
		While ExchangeFile.Read() Do
			
			If ExchangeFile.LocalName = "ParameterValue" Then
				
				If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
					Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
				EndIf;
				
				ImportDataExchangeParameterValues();
			Else
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// AfterParametersImportAlgorithm (optional)
	If ExchangeFile.LocalName = "AfterParameterExportAlgorithm" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
		EndIf;
		
		ExecuteAfterParametersImportAlgorithm(deElementValue(ExchangeFile, StringType));
		ExchangeFile.Read();
	EndIf;
	
	// ExchangeData (mandatory)
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeData" Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	ReadDataViaExchange(MessageReader, DataAnalysis);
	ExchangeFile.Read();
	
	If TransactionActive() Then
		Raise NStr("ru = 'Блокировка получения данных не может быть установлена в активной транзакции.'; en = 'Cannot set a data receipt lock in an active transaction.'; pl = 'Blokada odbioru danych nie może zostać ustawiona w aktywnej transakcji.';de = 'Sperren des Datenempfangs kann nicht in einer aktiven Transaktion festgelegt werden.';ro = 'Blocarea primirii datelor nu poate fi setată într-o tranzacție activă.';tr = 'Veri alma kilidi aktif bir işlemde belirlenemez.'; es_ES = 'Bloqueo del recibo de datos no puede establecerse en una transacción activa.'");
	EndIf;
	
	// Setting the sender node lock.
	Try
		LockDataForEdit(MessageReader.Sender);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка установки блокировки на обмен данными.
			|Возможно, обмен данными выполняется другим сеансом.
			|
			|Подробности:
			|%1'; 
			|en = 'Cannot set a data exchange lock.
			|Perhaps data exchange is running in another session.
			|
			|Details:
			|%1'; 
			|pl = 'Błąd ustawiania blokady wymiany danych.
			|Wymiana danych może być wykonana przez inną sesję.
			|
			|Szczegóły:
			|%1';
			|de = 'Sperren des Datenaustauschfehlers einstellen. 
			|Der Datenaustausch kann von einer anderen Sitzung durchgeführt werden. 
			|
			| Einzelheiten: 
			|%1';
			|ro = 'Eroare de instalare a blocării schimbului de date.
			|Posibil, schimbul de date a fost efectuat de altă sesiune.
			|
			|Detalii:
			|%1';
			|tr = 'Veri değişimi hatası ayarlanıyor. 
			|Veri değişimi başka bir oturum tarafından gerçekleştirilebilir. 
			|
			|Detaylar:
			|%1'; 
			|es_ES = 'Bloque de la configuración del error del intercambio de datos.
			|Intercambio de datos puede realizarse en otra sesión.
			|
			|Detalles:
			|%1'"),
			BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ExecuteHandlerAfterDataImport()
	
	// {Handler: AfterDataImport} Start
	If Not IsBlankString(Conversion.AfterImportData) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_AfterDataImport();
				
			Else
				
				Execute(Conversion.AfterImportData);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(23, ErrorDescription(), NStr("ru = 'ПослеЗагрузкиДанных (конвертация)'; en = 'AfterImportData (conversion)'; pl = 'AfterDataImport (konwertowanie)';de = 'NachDemDatenimport (Konvertierung)';ro = 'AfterDataImport (conversie)';tr = 'VeriİçeAktarıldıktanSonra (dönüştürme)'; es_ES = 'AfterDataImport (conversión)'"));
		EndTry;
		
	EndIf;
	// {Handler: AfterDataImport} End
	
EndProcedure

Procedure FinishMessageReader(Val MessageReader)
	
	If ExchangeFile.NodeType <> XMLNodeType.EndElement Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeFile" Then
		Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
	EndIf;
	
	ExchangeFile.Read(); // ExchangeFile
	ExchangeFile.Close();
	
	BeginTransaction();
	Try
		If Not MessageReader.DataAnalysis Then
			MessageReader.SenderObject.ReceivedNo = MessageReader.MessageNo;
			MessageReader.SenderObject.DataExchange.Load = True;
			MessageReader.SenderObject.Write();
		EndIf;
		
		If HasObjectRegistrationDataAdjustment = True Then
			InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustmentUnconditionally(ExchangeNodeDataImport);
		EndIf;
		
		If HasObjectChangeRecordData = True Then
			InformationRegisters.InfobaseObjectsMaps.DeleteObsoleteExportByRefModeRecords(ExchangeNodeDataImport);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
	UnlockDataForEdit(MessageReader.Sender);
	
EndProcedure

Procedure BreakMessageReader(Val MessageReader)
	
	ExchangeFile.Close();
	
	UnlockDataForEdit(MessageReader.Sender);
	
EndProcedure

Procedure ExecuteAfterParametersImportAlgorithm(Val AlgorithmText)
	
	If IsBlankString(AlgorithmText) Then
		Return;
	EndIf;
	
	Cancel = False;
	CancelReason = "";
	
	Try
		
		If ImportHandlersDebug Then
			
			ExecuteHandler_Conversion_AfterParametersImport(ExchangeFile, Cancel, CancelReason);
			
		Else
			
			Execute(AlgorithmText);
			
		EndIf;
		
		If Cancel = True Then
			
			If Not IsBlankString(CancelReason) Then
				
				MessageString = NStr("ru = 'Отказ от загрузки сообщения обмена в обработчике ПослеЗагрузкиПараметров (конвертация) по причине: %1'; en = 'The exchange message import is canceled in the AfterImportParameters (conversion) handler. Reason: %1'; pl = 'Odrzuć import wiadomości wymiany w programie obsługi AfterParametersImport (konwersja) z powodu: %1';de = 'Importnachrichtenaustausch ablehnen im Anwender NachParameterImport (Konvertierung) aufgrund von: %1';ro = 'Refuză importul mesajului de schimb în handlerul AfterParametersImport (conversie) din cauza: %1';tr = 'ParametrelerYüklendiktenSonra işleyicide alışveriş mesajını içe aktarmayı reddetmenin nedeni (dönüştürme): %1'; es_ES = 'Denegar la importación del mensaje de intercambio en el manipulador AfterParametersImport (conversión) debido a: %1'");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CancelReason);
				Raise MessageString;
			Else
				Raise NStr("ru = 'Отказ от загрузки сообщения обмена в обработчике ПослеЗагрузкиПараметров (конвертация).'; en = 'The exchange message import is canceled in the AfterImportParameters (conversion) handler.'; pl = 'Anuluj importowanie wiadomości wymiany AfterImportOfParameters w programie obsługi (konwertowanie)';de = 'Importnachrichtenaustausch löschen im Anwender NachParameterImport (Konvertierung).';ro = 'Refuzul importulului mesajului de schimb în handlerul AfterImportOfParameters (conversie).';tr = 'VeriYüklendiktenSonra işleyicide alışveriş mesajını içe aktarmayı reddetme (dönüştürme). '; es_ES = 'Cancelar la importación del mensaje de intercambio en el manipulador AfterImportOfParameters (conversión).'");
			EndIf;
			
		EndIf;
		
	Except
		
		WP = ExchangeProtocolRecord(78, ErrorDescription());
		WP.Handler     = "AfterImportParameters";
		ErrorMessageString = WriteToExecutionProtocol(78, WP);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

Function SetNewObjectRef(Object, Manager, SearchProperties)
	
	UUID = SearchProperties["{UUID}"];
	
	If UUID <> Undefined Then
		
		NewRef = Manager.GetRef(New UUID(UUID));
		
		Object.SetNewObjectRef(NewRef);
		
		SearchProperties.Delete("{UUID}");
		
	Else
		
		Object.SetNewObjectRef(Manager.GetRef(New UUID));
		NewRef = Undefined;
		
	EndIf;
	
	Return NewRef;
	
EndFunction

// Searches for the object by its number in the list of already imported objects.
//
// Parameters:
//  NBSp          - a number of the object to be searched in the exchange file.
//
// Returns:
//  Reference to the found object. If object is not found, Undefined is returned.
// 
Function FindObjectByNumber(SN, ObjectType, MainObjectSearchMode = False)
	
	Return Undefined;
	
EndFunction

Function FindObjectByGlobalNumber(SN, MainObjectSearchMode = False)
	
	Return Undefined;
	
EndFunction

Procedure RemoveDeletionMarkFromPredefinedItem(Object, Val ObjectType)
	
	If TypeOf(ObjectType) = StringType Then
		ObjectType = Type(ObjectType);
	EndIf;
	
	If (Catalogs.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfAccounts.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType))
		AND Object.DeletionMark
		AND Object.Predefined Then
		
		Object.DeletionMark = False;
		
		// Adding the event log entry.
		WP            = ExchangeProtocolRecord(80);
		WP.ObjectType = ObjectType;
		WP.Object     = String(Object);
		
		WriteToExecutionProtocol(80, WP, False,,,,Enums.ExchangeExecutionResults.CompletedWithWarnings);
		
	EndIf;
	
EndProcedure

Procedure SetCurrentDateToAttribute(ObjectAttribute)
	
	ObjectAttribute = CurrentSessionDate();
	
EndProcedure

// Creates a new object of the specified type, sets attributes that are specified in the 
// SearchProperties structure.
//
// Parameters:
//  Type - type of the object to be created.
//  SearchProperties - Structure - contains attributes of a new object to be set.
//  Object - an infobase object created after completion.
//  WriteObjectImmediatelyAfterCreation - boolean.
//  NewRef - a reference to the created object.
//  SetAllObjectSearchProperties - Boolean.
//  RegisterRecordSet - InformationRegisterRecordSet which is created.
//
// Returns:
//  Created object or Undefined (if WriteObjectImmediatelyAfterCreation is not set).
// 
Function CreateNewObject(Type, SearchProperties, Object, 
	WriteObjectImmediatelyAfterCreation, NewRef = Undefined, 
	SetAllObjectSearchProperties = True,
	RegisterRecordSet = Undefined)
	
	MDProperties      = Managers[Type];
	TypeName         = MDProperties.TypeName;
	Manager        = MDProperties.Manager;

	If TypeName = "Catalog"
		OR TypeName = "ChartOfCharacteristicTypes" Then
		
		IsFolder = SearchProperties["IsFolder"];
		
		If IsFolder = True Then
			
			Object = Manager.CreateFolder();
						
		Else
			
			Object = Manager.CreateItem();
			
		EndIf;		
				
	ElsIf TypeName = "Document" Then
		
		Object = Manager.CreateDocument();
				
	ElsIf TypeName = "ChartOfAccounts" Then
		
		Object = Manager.CreateAccount();
				
	ElsIf TypeName = "ChartOfCalculationTypes" Then
		
		Object = Manager.CreateCalculationType();
				
	ElsIf TypeName = "InformationRegister" Then
		
		RegisterRecordSet = Manager.CreateRecordSet();
		Object = RegisterRecordSet.Add();
		Return Object;
		
	ElsIf TypeName = "ExchangePlan" Then
		
		Object = Manager.CreateNode();
				
	ElsIf TypeName = "Task" Then
		
		Object = Manager.CreateTask();
		
	ElsIf TypeName = "BusinessProcess" Then
		
		Object = Manager.CreateBusinessProcess();	
		
	ElsIf TypeName = "Enum" Then
		
		Object = MDProperties.EmptyRef;	
		Return Object;
		
	ElsIf TypeName = "BusinessProcessRoutePoint" Then
		
		Return Undefined;
				
	EndIf;
	
	NewRef = SetNewObjectRef(Object, Manager, SearchProperties);
	
	If SetAllObjectSearchProperties Then
		SetObjectSearchAttributes(Object, SearchProperties, , False, False);
	EndIf;
	
	// Checks
	If TypeName = "Document"
		OR TypeName = "Task"
		OR TypeName = "BusinessProcess" Then
		
		If NOT ValueIsFilled(Object.Date) Then
			
			SetCurrentDateToAttribute(Object.Date);			
						
		EndIf;
		
	EndIf;
		
	If WriteObjectImmediatelyAfterCreation Then
		
		WriteObjectToIB(Object, Type);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	Return Object.Ref;
	
EndFunction

// Reads the object property node from the file and sets the property value.
//
// Parameters:
//  Type - property value type.
//  ObjectFound - False returned after function execution means that the property object is not 
//                   found in the infobase and the new object was created.
//
// Returns:
//  Property value
// 
Function ReadProperty(Type, DontCreateObjectIfNotFound = False, PropertyNotFoundByRef = False, OCRName = "")

	Value = Undefined;
	PropertyExistence = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Value" Then
			
			SearchByProperty = deAttribute(ExchangeFile, StringType, "Property");
			Value         = deElementValue(ExchangeFile, Type, SearchByProperty, False);
			PropertyExistence = True;
			
		ElsIf NodeName = "Ref" Then
			
			InfobaseObjectsMaps = Undefined;
			CreatedObject = Undefined;
			ObjectFound = True;
			SearchBySearchFieldsIfNotFoundByID = False;
			
			Value = FindObjectByRef(Type,
											,
											, 
											ObjectFound, 
											CreatedObject, 
											DontCreateObjectIfNotFound, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											OCRName, 
											InfobaseObjectsMaps, 
											SearchBySearchFieldsIfNotFoundByID);
			
			If DontCreateObjectIfNotFound
				AND NOT ObjectFound Then
				
				PropertyNotFoundByRef = False;
				
			EndIf;
			
			PropertyExistence = True;
			
		ElsIf NodeName = "Sn" Then
			
			ExchangeFile.Read();
			SN = Number(ExchangeFile.Value);
			If SN <> 0 Then
				Value  = FindObjectByNumber(SN, Type);
				PropertyExistence = True;
			EndIf;			
			ExchangeFile.Read();
			
		ElsIf NodeName = "Gsn" Then
			
			ExchangeFile.Read();
			GSN = Number(ExchangeFile.Value);
			If GSN <> 0 Then
				Value  = FindObjectByGlobalNumber(GSN);
				PropertyExistence = True;
			EndIf;
			
			ExchangeFile.Read();
			
		ElsIf (NodeName = "Property" OR NodeName = "ParameterValue") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			If Not PropertyExistence
				AND ValueIsFilled(Type) Then
				
				// If there is no data, empty value.
				Value = deGetEmptyValue(Type);
				
			EndIf;
			
			Break;
			
		ElsIf NodeName = "Expression" Then
			
			Expression = deElementValue(ExchangeFile, StringType, , False);
			Value  = Common.CalculateInSafeMode(Expression);
			
			PropertyExistence = True;
			
		ElsIf NodeName = "Empty" Then
			
			Value = deGetEmptyValue(Type);
			PropertyExistence = True;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Value;
	
EndFunction

Procedure SetObjectSearchAttributes(FoundObject, SearchProperties,
		SearchPropertiesDontReplace = Undefined, ShouldCompareWithCurrentAttributes = True, DontReplacePropertiesNotToChange = True)
	
	For each Property In SearchProperties Do
					
		Name      = Property.Key;
		Value = Property.Value;
		
		If DontReplacePropertiesNotToChange
			AND SearchPropertiesDontReplace[Name] <> Undefined Then
			
			Continue;
			
		EndIf;
					
		If Name = "IsFolder" 
			OR Name = "{UUID}" 
			OR Name = "{PredefinedItemName}"
			OR Name = "{SourceIBSearchKey}"
			OR Name = "{DestinationIBSearchKey}"
			OR Name = "{TypeNameInSourceIB}"
			OR Name = "{TypeNameInDestinationIB}" Then
						
			Continue;
						
		ElsIf Name = "DeletionMark" Then
						
			If NOT ShouldCompareWithCurrentAttributes
				OR FoundObject.DeletionMark <> Value Then
							
				FoundObject.DeletionMark = Value;
							
			EndIf;
						
		Else
				
			// Setting attributes that are different.
			
			If FoundObject[Name] <> NULL Then
			
				If NOT ShouldCompareWithCurrentAttributes
					OR FoundObject[Name] <> Value Then
						
					FoundObject[Name] = Value;
					
						
				EndIf;
				
			EndIf;
				
		EndIf;
					
	EndDo;
	
EndProcedure

Function FindOrCreateObjectByProperty(PropertyStructure,
									ObjectType,
									SearchProperties,
									SearchPropertiesDontReplace,
									ObjectTypeName,
									SearchProperty,
									SearchPropertyValue,
									ObjectFound,
									CreateNewItemIfNotFound = True,
									FoundOrCreatedObject = Undefined,
									MainObjectSearchMode = False,
									NewUUIDRef = Undefined,
									SN = 0,
									GSN = 0,
									ObjectParameters = Undefined,
									DontReplaceObjectCreatedInDestinationInfobase = False,
									ObjectCreatedInCurrentInfobase = Undefined)
	
	Object = deFindObjectByProperty(PropertyStructure.Manager, SearchProperty, SearchPropertyValue, 
		FoundOrCreatedObject, , , MainObjectSearchMode, PropertyStructure.SearchString);
	
	ObjectFound = NOT (Object = Undefined
				OR Object.IsEmpty());
				
	If Not ObjectFound
		AND CreateNewItemIfNotFound Then
		
		Object = CreateNewObject(ObjectType, SearchProperties, FoundOrCreatedObject, 
			NOT MainObjectSearchMode, NewUUIDRef);
			
		Return Object;
		
	EndIf;
			
	
	If MainObjectSearchMode Then
		
		//
		Try
			
			If Not ValueIsFilled(Object) Then
				Return Object;
			EndIf;
			
			If FoundOrCreatedObject = Undefined Then
				FoundOrCreatedObject = Object.GetObject();
			EndIf;
			
		Except
			Return Object;
		EndTry;
			
		SetObjectSearchAttributes(FoundOrCreatedObject, SearchProperties, SearchPropertiesDontReplace);
		
	EndIf;
		
	Return Object;
	
EndFunction

Function PropertyType()
	
	PropertyTypeString = deAttribute(ExchangeFile, StringType, "Type");
	If IsBlankString(PropertyTypeString) Then
		
		// Define property by its map.
		Return Undefined;
		
	EndIf;
	
	Return Type(PropertyTypeString);
	
EndFunction

Function PropertyTypeByAdditionalData(TypesInformation, PropertyName)
	
	PropertyType = PropertyType();
				
	If PropertyType = Undefined
		AND TypesInformation <> Undefined Then
		
		PropertyType = TypesInformation[PropertyName];
		
	EndIf;
	
	Return PropertyType;
	
EndFunction

Procedure ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation,
	SearchByEqualDate, ObjectParameters, Val MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps)
	
	SearchByEqualDate = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If    NodeName = "Property"
			OR NodeName = "ParameterValue" Then
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name = deAttribute(ExchangeFile, StringType, "Name");
			
			SourceTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			DestinationTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			UUIDProperty = (Name = "{UUID}");
			
			If UUIDProperty Then
				
				PropertyType = StringType;
				
			ElsIf Name = "{PredefinedItemName}"
				  OR Name = "{SourceIBSearchKey}"
				  OR Name = "{DestinationIBSearchKey}"
				  OR Name = "{TypeNameInSourceIB}"
				  OR Name = "{TypeNameInDestinationIB}" Then
				
				PropertyType = StringType;
				
			Else
				
				PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
				
			EndIf;
			
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "DoNotReplace");
			
			SearchByEqualDate = SearchByEqualDate 
						OR deAttribute(ExchangeFile, BooleanType, "SearchByEqualDate");
			//
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			PropertyValue = ReadProperty(PropertyType,,, OCRName);
			
			If UUIDProperty Then
				
				ReplaceUUIDIfNecessary(PropertyValue, SourceTypeString, DestinationTypeString, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
				
			EndIf;
			
			If (Name = "IsFolder") AND (PropertyValue <> True) Then
				
				PropertyValue = False;
												
			EndIf; 
			
			If IsParameter Then
				
				
				AddParameterIfNecessary(ObjectParameters, Name, PropertyValue);
				
			Else
			
				SearchProperties[Name] = PropertyValue;
				
				If DontReplaceProperty Then
					
					SearchPropertiesDontReplace[Name] = True;
					
				EndIf;
				
			EndIf;
			
		ElsIf (NodeName = "Ref") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ReplaceUUIDIfNecessary(
										UUID,
										Val SourceTypeString,
										Val DestinationTypeString,
										Val MainObjectSearchMode,
										ObjectMapFound = False,
										InfobaseObjectsMaps = Undefined)
	
	// Do not replace main objects in the mapping mode.
	If MainObjectSearchMode AND DataImportToValueTableMode() Then
		Return;
	EndIf;
	
	InfobaseObjectsMapQuery.SetParameter("InfobaseNode", ExchangeNodeDataImport);
	InfobaseObjectsMapQuery.SetParameter("DestinationUUID", UUID);
	InfobaseObjectsMapQuery.SetParameter("DestinationType", DestinationTypeString);
	InfobaseObjectsMapQuery.SetParameter("SourceType", SourceTypeString);
	
	QueryResult = InfobaseObjectsMapQuery.Execute();
	
	If QueryResult.IsEmpty() Then
		
		InfobaseObjectsMaps = New Structure;
		InfobaseObjectsMaps.Insert("InfobaseNode", ExchangeNodeDataImport);
		InfobaseObjectsMaps.Insert("DestinationType", DestinationTypeString);
		InfobaseObjectsMaps.Insert("SourceType", SourceTypeString);
		InfobaseObjectsMaps.Insert("DestinationUUID", UUID);
		
		// Value will be determined after the object is written.
		// Perhaps mapping will be assigned to an object when identifying an object by search fields.
		InfobaseObjectsMaps.Insert("SourceUUID", Undefined);
		
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		UUID = Selection.SourceUUIDString;
		
		ObjectMapFound = True;
		
	EndIf;
	
EndProcedure

Function UnlimitedLengthField(TypeManager, ParameterName)
	
	LongStrings = Undefined;
	If NOT TypeManager.Property("LongStrings", LongStrings) Then
		
		LongStrings = New Map;
		For Each Attribute In TypeManager.MetadateObject.Attributes Do
			
			If Attribute.Type.ContainsType(StringType) 
				AND (Attribute.Type.StringQualifiers.Length = 0) Then
				
				LongStrings.Insert(Attribute.Name, Attribute.Name);	
				
			EndIf;
			
		EndDo;
		
		TypeManager.Insert("LongStrings", LongStrings);
		
	EndIf;
	
	Return (LongStrings[ParameterName] <> Undefined);
		
EndFunction

Function IsUnlimitedLengthParameter(TypeManager, ParameterValue, ParameterName)
	
	If TypeOf(ParameterValue) = StringType Then
		UnlimitedLengthString = UnlimitedLengthField(TypeManager, ParameterName);
	Else
		UnlimitedLengthString = False;
	EndIf;
	
	Return UnlimitedLengthString;
	
EndFunction

Function FindItemUsingRequest(PropertyStructure, SearchProperties, ObjectType = Undefined, 
	TypeManager = Undefined, RealPropertyForSearchCount = Undefined)
	
	PropertyCountForSearch = ?(RealPropertyForSearchCount = Undefined, SearchProperties.Count(), RealPropertyForSearchCount);
	
	If PropertyCountForSearch = 0
		AND PropertyStructure.TypeName = "Enum" Then
		
		Return PropertyStructure.EmptyRef;
		
	EndIf;
	
	QueryText       = PropertyStructure.SearchString;
	
	If IsBlankString(QueryText) Then
		Return PropertyStructure.EmptyRef;
	EndIf;
	
	SearchQuery       = New Query();
	
	PropertyUsedInSearchCount = 0;
	
	For Each Property In SearchProperties Do
		
		ParameterName = Property.Key;
		
		// The following parameters cannot be search fields.
		If ParameterName = "{UUID}" Or ParameterName = "{PredefinedItemName}" Then
			Continue;
		EndIf;
		
		ParameterValue = Property.Value;
		SearchQuery.SetParameter(ParameterName, ParameterValue);
		
		UnlimitedLengthString = IsUnlimitedLengthParameter(PropertyStructure, ParameterValue, ParameterName);
		
		PropertyUsedInSearchCount = PropertyUsedInSearchCount + 1;
		
		If UnlimitedLengthString Then
			
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " AND ", "") + ParameterName + " LIKE &" + ParameterName;
			
		Else
			
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " AND ", "") + ParameterName + " = &" + ParameterName;
			
		EndIf;
		
	EndDo;
	
	If PropertyUsedInSearchCount = 0 Then
		Return Undefined;
	EndIf;
	
	SearchQuery.Text = QueryText;
	Result = SearchQuery.Execute();
			
	If Result.IsEmpty() Then
		
		Return Undefined;
								
	Else
		
		// Returning the first found object.
		Selection = Result.Select();
		Selection.Next();
		ObjectRef = Selection.Ref;
				
	EndIf;
	
	Return ObjectRef;
	
EndFunction

// Determines the object conversion rule (OCR) by destination object type.
//
// Parameters:
//  RefTypeAsString - String - an object type as a string, for example, CatalogRef.Products.
// 
// Returns:
//  MapValue = object conversion rule.
// 
Function GetConversionRuleWithSearchAlgorithmByDestinationObjectType(RefTypeString)
	
	MapValue = ConversionRulesMap.Get(RefTypeString);
	
	If MapValue <> Undefined Then
		Return MapValue;
	EndIf;
	
	Try
	
		For Each Item In Rules Do
			
			If Item.Value.Destination = RefTypeString Then
				
				If Item.Value.HasSearchFieldSequenceHandler = True Then
					
					Rule = Item.Value;
					
					ConversionRulesMap.Insert(RefTypeString, Rule);
					
					Return Rule;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ConversionRulesMap.Insert(RefTypeString, Undefined);
		Return Undefined;
	
	Except
		
		ConversionRulesMap.Insert(RefTypeString, Undefined);
		Return Undefined;
	
	EndTry;
	
EndFunction

Function FindDocumentRef(SearchProperties, PropertyStructure, RealPropertyForSearchCount, SearchWithQuery, SearchByEqualDate)
	
	// Attempting to search for the document by the date and number.
	SearchWithQuery = SearchByEqualDate OR (RealPropertyForSearchCount <> 2);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
	
	DocumentNumber = SearchProperties["Number"];
	DocumentDate  = SearchProperties["Date"];
					
	If (DocumentNumber <> Undefined) AND (DocumentDate <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByNumber(DocumentNumber, DocumentDate);
																		
	Else
						
		// Cannot find by date and number. Search using a query.
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
	
	Return ObjectRef;
	
EndFunction

Function FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, 
	PropertyStructure, SearchPropertyNameString, SearchByEqualDate)
	
	// Searching by predefined item name or by unique reference link is not required. Searching by 
	// properties that are in the property name string. If this parameter is empty, searching by all available search properties. 
	// If it is empty, then search by all existing search properties.
	
	If IsBlankString(SearchPropertyNameString) Then
		
		TemporarySearchProperties = SearchProperties;
		
	Else
		
		ResultingStringForParsing = StrReplace(SearchPropertyNameString, " ", "");
		StringLength = StrLen(ResultingStringForParsing);
		If Mid(ResultingStringForParsing, StringLength, 1) <> "," Then
			
			ResultingStringForParsing = ResultingStringForParsing + ",";
			
		EndIf;
		
		TemporarySearchProperties = New Map;
		For Each PropertyItem In SearchProperties Do
			
			ParameterName = PropertyItem.Key;
			If StrFind(ResultingStringForParsing, ParameterName + ",") > 0 Then
				
				TemporarySearchProperties.Insert(ParameterName, PropertyItem.Value);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	UUIDProperty = TemporarySearchProperties["{UUID}"];
	PredefinedNameProperty    = TemporarySearchProperties["{PredefinedItemName}"];
	
	RealPropertyForSearchCount = TemporarySearchProperties.Count();
	RealPropertyForSearchCount = RealPropertyForSearchCount - ?(UUIDProperty <> Undefined, 1, 0);
	RealPropertyForSearchCount = RealPropertyForSearchCount - ?(PredefinedNameProperty    <> Undefined, 1, 0);
	
	SearchWithQuery = False;
	
	If ObjectTypeName = "Document" Then
		
		ObjectRef = FindDocumentRef(TemporarySearchProperties, PropertyStructure, RealPropertyForSearchCount, SearchWithQuery, SearchByEqualDate);
		
	Else
		
		SearchWithQuery = True;
		
	EndIf;
	
	If SearchWithQuery Then
		
		ObjectRef = FindItemUsingRequest(PropertyStructure, TemporarySearchProperties, ObjectType, , RealPropertyForSearchCount);
		
	EndIf;
	
	Return ObjectRef;
EndFunction

Procedure ProcessObjectSearchPropertySetting(SetAllObjectSearchProperties, 
												ObjectType, 
												SearchProperties, 
												SearchPropertiesDontReplace, 
												ObjectRef, 
												CreatedObject, 
												WriteNewObjectToInfobase = True, 
												DontReplaceObjectCreatedInDestinationInfobase = False, 
												ObjectCreatedInCurrentInfobase = Undefined)
	
	If SetAllObjectSearchProperties <> True Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ObjectRef) Then
		Return;
	EndIf;
	
	If CreatedObject = Undefined Then
		CreatedObject = ObjectRef.GetObject();
	EndIf;
	
	SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
	
EndProcedure

Procedure ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace,
	SearchByEqualDate = False, ObjectParameters = Undefined, Val MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps)
	
	If SearchProperties = "" Then
		SearchProperties = New Map;
	EndIf;
	
	If SearchPropertiesDontReplace = "" Then
		SearchPropertiesDontReplace = New Map;
	EndIf;
	
	TypesInformation = DataForImportTypeMap()[ObjectType];
	ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation, SearchByEqualDate, ObjectParameters, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
	
EndProcedure

Procedure GetAdditionalObjectSearchParameters(SearchProperties, ObjectType, PropertyStructure, ObjectTypeName, IsDocumentObject)
	
	If ObjectType = Undefined Then
		
		// Try to define type by search properties.
		DestinationTypeName = SearchProperties["{TypeNameInDestinationIB}"];
		If DestinationTypeName = Undefined Then
			DestinationTypeName = SearchProperties["{TypeNameInSourceIB}"];
		EndIf;
		
		If DestinationTypeName <> Undefined Then
			
			ObjectType = Type(DestinationTypeName);	
			
		EndIf;		
		
	EndIf;
	
	PropertyStructure   = Managers[ObjectType];
	ObjectTypeName     = PropertyStructure.TypeName;	
	
EndProcedure

// Searches an object in the infobase and creates a new object, if it is not found.
//
// Parameters:
//  ObjectType - type of the object to be found.
//  SearchProperties - structure with properties to be used for object searching.
//  ObjectFound - False means that the object is not found and a new object is created.
//
// Returns:
//  New or found infobase object.
//  
Function FindObjectByRef(ObjectType, 
							SearchProperties = "", 
							SearchPropertiesDontReplace = "", 
							ObjectFound = True, 
							CreatedObject = Undefined, 
							DontCreateObjectIfNotFound = False,
							MainObjectSearchMode = False,
							GlobalRefSn = 0,
							RefSN = 0,
							ObjectFoundBySearchFields = False,
							KnownUUIDRef = Undefined,
							SearchingImportObject = False,
							ObjectParameters = Undefined,
							DontReplaceObjectCreatedInDestinationInfobase = False,
							ObjectCreatedInCurrentInfobase = Undefined,
							RecordObjectChangeAtSenderNode = False,
							UUIDAsString = "",
							OCRName = "",
							InfobaseObjectsMaps = Undefined,
							SearchBySearchFieldsIfNotFoundByID = Undefined)
	
	// Object identification is performed sequentially in five stages.
	// The transition to each subsequent stage is performed if the search did not give a positive result.
	// 
	//
	// Object identification (search) steps:
	// 1. Searching for an object by an infobase object mapping register.
	// 2. Searching for an object by a predefined item name.
	// 3. Searching for an object by a reference UUID.
	// 4. Searching for an object by an arbitrary search algorithm.
	// 5. Searching for an object by search fields.
	
	SearchByEqualDate = False;
	ObjectRef = Undefined;
	PropertyStructure = Undefined;
	ObjectTypeName = Undefined;
	IsDocumentObject = False;
	RefPropertyReadingCompleted = False;
	ObjectMapFound = False;
	
	GlobalRefSn = deAttribute(ExchangeFile, NumberType, "Gsn");
	RefSN           = deAttribute(ExchangeFile, NumberType, "Sn");
	
	// Shows whether the object must be registered prior to export for the sender node (sending the object back).
	RecordObjectChangeAtSenderNode = deAttribute(ExchangeFile, BooleanType, "RecordObjectChangeAtSenderNode");
	
	FlagDontCreateObjectIfNotFound = deAttribute(ExchangeFile, BooleanType, "DoNotCreateIfNotFound");
	If NOT ValueIsFilled(FlagDontCreateObjectIfNotFound) Then
		FlagDontCreateObjectIfNotFound = False;
	EndIf;
	
	If DontCreateObjectIfNotFound = Undefined Then
		DontCreateObjectIfNotFound = False;
	EndIf;
	
	OnExchangeObjectByRefSetGIUDOnly = NOT MainObjectSearchMode;
		
	DontCreateObjectIfNotFound = DontCreateObjectIfNotFound OR FlagDontCreateObjectIfNotFound;
	
	DontReplaceObjectCreatedInDestinationInfobaseFlag = deAttribute(ExchangeFile, BooleanType, "DoNotReplaceObjectCreatedInDestinationInfobase");
	If NOT ValueIsFilled(DontReplaceObjectCreatedInDestinationInfobaseFlag) Then
		DontReplaceObjectCreatedInDestinationInfobase = False;
	Else
		DontReplaceObjectCreatedInDestinationInfobase = DontReplaceObjectCreatedInDestinationInfobaseFlag;	
	EndIf;
	
	SearchBySearchFieldsIfNotFoundByID = deAttribute(ExchangeFile, BooleanType, "ContinueSearch");
	
	// 1. Searching for an object by an infobase object mapping register.
	ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, SearchByEqualDate, ObjectParameters, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
	GetAdditionalObjectSearchParameters(SearchProperties, ObjectType, PropertyStructure, ObjectTypeName, IsDocumentObject);
	
	UUIDProperty = SearchProperties["{UUID}"];
	PredefinedNameProperty    = SearchProperties["{PredefinedItemName}"];
	
	UUIDAsString = UUIDProperty;
	
	OnExchangeObjectByRefSetGIUDOnly = OnExchangeObjectByRefSetGIUDOnly
									AND UUIDProperty <> Undefined;
	
	If ObjectMapFound Then
		
		// 1. Object search by an infobase object mapping register gave a positive result.
		
		ObjectRef = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
		
		If MainObjectSearchMode Then
			
			CreatedObject = ObjectRef.GetObject();
			
			If CreatedObject <> Undefined Then
				
				SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
				
				ObjectFound = True;
				
				Return ObjectRef;
				
			EndIf;
			
		Else
			
			// For non-main objects (exported by reference), just get the link with the specified GUID.
			Return ObjectRef;
			
		EndIf;
		
	EndIf;
	
	// 2. Searching for an object of a predefined item name.
	If PredefinedNameProperty <> Undefined Then
		
		CreateNewObjectAutomatically = False;
		
		ObjectRef = FindOrCreateObjectByProperty(PropertyStructure,
													ObjectType,
													SearchProperties,
													SearchPropertiesDontReplace,
													ObjectTypeName,
													"{PredefinedItemName}",
													PredefinedNameProperty,
													ObjectFound,
													CreateNewObjectAutomatically,
													CreatedObject,
													MainObjectSearchMode,
													,
													RefSN, GlobalRefSn,
													ObjectParameters,
													DontReplaceObjectCreatedInDestinationInfobase,
													ObjectCreatedInCurrentInfobase);
		
		If ObjectRef <> Undefined
			AND ObjectRef.IsEmpty() Then
			
			ObjectFound = False;
			ObjectRef = Undefined;
					
		EndIf;
			
		If    ObjectRef <> Undefined
			OR CreatedObject <> Undefined Then
			
			ObjectFound = True;
			
			// 2. A search for the object name of a predefined item returned a positive result.
			Return ObjectRef;
			
		EndIf;
		
	EndIf;
	
	// 3. Searching for an object by a reference UUID.
	If UUIDProperty <> Undefined Then
		
		If MainObjectSearchMode Then
			
			CreateNewObjectAutomatically = NOT DontCreateObjectIfNotFound AND Not SearchBySearchFieldsIfNotFoundByID;
			
			ObjectRef = FindOrCreateObjectByProperty(PropertyStructure,
														ObjectType,
														SearchProperties,
														SearchPropertiesDontReplace,
														ObjectTypeName,
														"{UUID}",
														UUIDProperty,
														ObjectFound,
														CreateNewObjectAutomatically,
														CreatedObject,
														MainObjectSearchMode,
														KnownUUIDRef,
														RefSN,
														GlobalRefSn,
														ObjectParameters,
														DontReplaceObjectCreatedInDestinationInfobase,
														ObjectCreatedInCurrentInfobase);
			If Not SearchBySearchFieldsIfNotFoundByID Then
				
				Return ObjectRef;
				
			EndIf;
			
		ElsIf SearchBySearchFieldsIfNotFoundByID Then
			
			CreateNewObjectAutomatically = False;
			
			ObjectRef = FindOrCreateObjectByProperty(PropertyStructure,
														ObjectType,
														SearchProperties,
														SearchPropertiesDontReplace,
														ObjectTypeName,
														"{UUID}",
														UUIDProperty,
														ObjectFound,
														CreateNewObjectAutomatically,
														CreatedObject,
														MainObjectSearchMode,
														KnownUUIDRef,
														RefSN,
														GlobalRefSn,
														ObjectParameters,
														DontReplaceObjectCreatedInDestinationInfobase,
														ObjectCreatedInCurrentInfobase);
			
		Else
			
			// For non-main objects (exported by reference), just get the link with the specified GUID.
			Return PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
			
		EndIf;
		
		If ObjectRef <> Undefined 
			AND ObjectRef.IsEmpty() Then
			
			ObjectFound = False;
			ObjectRef = Undefined;
					
		EndIf;
			
		If    ObjectRef <> Undefined
			OR CreatedObject <> Undefined Then
			
			ObjectFound = True;
			
			// 3. Object search by a reference UUID returned a positive result.
			Return ObjectRef;
			
		EndIf;
		
	EndIf;
	
	// 4. Searching for an object by an arbitrary search algorithm.
	SearchVariantNumber = 1;
	SearchPropertyNameString = "";
	PreviousSearchString = Undefined;
	StopSearch = False;
	SetAllObjectSearchProperties = True;
	OCR = Undefined;
	SearchAlgorithm = "";
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;
	
	If OCR = Undefined Then
		
		OCR = GetConversionRuleWithSearchAlgorithmByDestinationObjectType(PropertyStructure.RefTypeString);
		
	EndIf;
	
	If OCR <> Undefined Then
		
		SearchAlgorithm = OCR.SearchFieldSequence;
		
	EndIf;
	
	HasSearchAlgorithm = Not IsBlankString(SearchAlgorithm);
	
	While SearchVariantNumber <= 10
		AND HasSearchAlgorithm Do
		
		Try
			
			If ImportHandlersDebug Then
				
				Execute_OCR_HandlerSearchFieldsSequence(SearchVariantNumber, SearchProperties, ObjectParameters, StopSearch,
																	  ObjectRef, SetAllObjectSearchProperties, SearchPropertyNameString,
																	  OCR.SearchFieldSequenceHandlerName);
				
			Else
				
				Execute(SearchAlgorithm);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(73, ErrorDescription(), "", "", 
				ObjectType, Undefined, NStr("ru = 'Последовательность полей поиска'; en = 'Search field sequence'; pl = 'Sekwencja pól wyszukiwania';de = 'Reihenfolge der Suchfelder';ro = 'Secvența câmpurilor de căutare';tr = 'Arama alanlarının dizisi'; es_ES = 'Secuencia de los campos de búsqueda'"));
			
		EndTry;
		
		DontSearch = StopSearch = True 
			OR SearchPropertyNameString = PreviousSearchString
			OR ValueIsFilled(ObjectRef);				
			
		If NOT DontSearch Then
	
			// The search
			ObjectRef = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
				SearchPropertyNameString, SearchByEqualDate);
				
			DontSearch = ValueIsFilled(ObjectRef);
			
			If ObjectRef <> Undefined
				AND ObjectRef.IsEmpty() Then
				ObjectRef = Undefined;
			EndIf;
			
		EndIf;
		
		If DontSearch Then
		
			If MainObjectSearchMode Then
			
				ProcessObjectSearchPropertySetting(SetAllObjectSearchProperties, 
													ObjectType, 
													SearchProperties, 
													SearchPropertiesDontReplace, 
													ObjectRef, 
													CreatedObject, 
													NOT MainObjectSearchMode, 
													DontReplaceObjectCreatedInDestinationInfobase, 
													ObjectCreatedInCurrentInfobase);
					
			EndIf;
						
			Break;
			
		EndIf;	
	
		SearchVariantNumber = SearchVariantNumber + 1;
		PreviousSearchString = SearchPropertyNameString;
		
	EndDo;
		
	If Not HasSearchAlgorithm Then
		
		// 5. Searching for an object by search fields.
		ObjectRef = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
					SearchPropertyNameString, SearchByEqualDate);
		
	EndIf;
	
	If MainObjectSearchMode
		AND ValueIsFilled(ObjectRef)
		AND (ObjectTypeName = "Document" 
		OR ObjectTypeName = "Task"
		OR ObjectTypeName = "BusinessProcess") Then
		
		// Setting the date if it is in the document search fields.
		EmptyDate = Not ValueIsFilled(SearchProperties["Date"]);
		CanReplace = (Not EmptyDate) 
			AND (SearchPropertiesDontReplace["Date"] = Undefined);
			
		If CanReplace Then
			
			If CreatedObject = Undefined Then
				CreatedObject = ObjectRef.GetObject();
			EndIf;
			
			CreatedObject.Date = SearchProperties["Date"];
				
		EndIf;
		
	EndIf;		
	
	// Creating a new object is not always necessary.
	If (ObjectRef = Undefined
			OR ObjectRef.IsEmpty())
		AND CreatedObject = Undefined Then // Object is not found by search fields.
		
		If OnExchangeObjectByRefSetGIUDOnly Then
			
			ObjectRef = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
			
		ElsIf NOT DontCreateObjectIfNotFound Then
		
			ObjectRef = CreateNewObject(ObjectType, SearchProperties, CreatedObject, 
				NOT MainObjectSearchMode, KnownUUIDRef, SetAllObjectSearchProperties);
				
		EndIf;
			
		ObjectFound = False;
		
	Else
		
		// The object is found by search fields.
		ObjectFound = True;
			
	EndIf;
	
	If ObjectRef <> Undefined
		AND ObjectRef.IsEmpty() Then
		
		ObjectRef = Undefined;
		
	EndIf;
	
	ObjectFoundBySearchFields = ObjectFound;
	
	Return ObjectRef;
	
EndFunction 

Procedure SetExchangeFileCollectionProperties(Object, ExchangeFileCollection, TypesInformation,
	ObjectParameters, RecordNumber, Val TabularSectionName, Val OrderFieldName)
	
	BranchName = TabularSectionName + "TabularSection";
	
	CollectionRow = ExchangeFileCollection.Add();
	CollectionRow[OrderFieldName] = RecordNumber;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Property" 
			OR NodeName = "ParameterValue" Then
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name    = deAttribute(ExchangeFile, StringType, "Name");
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
			
			PropertyValue = ReadProperty(PropertyType,,, OCRName);
			
			If IsParameter Then
				
				AddComplexParameterIfNecessary(ObjectParameters, BranchName, RecordNumber, Name, PropertyValue);
				
			Else
				
				Try
					
					CollectionRow[Name] = PropertyValue;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorDescription());
					WP.OCRName           = OCRName;
					WP.Object           = Object;
					WP.ObjectType       = TypeOf(Object);
					WP.Property         = "Object." + TabularSectionName + "." + Name;
					WP.Value         = PropertyValue;
					WP.ValueType      = TypeOf(PropertyValue);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "ExtDimensionsDr" OR NodeName = "ExtDimensionsCr" Then
			
			deSkip(ExchangeFile);
				
		ElsIf (NodeName = "Record") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Imports an object tabular section.
//
Procedure ImportTabularSection(Object, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, OCR)
	
	Var KeySearchFields;
	Var KeySearchFieldArray;
	
	Result = KeySearchFieldsByTabularSection(OCR, TabularSectionName, KeySearchFieldArray, KeySearchFields);
	
	If Not Result Then
		
		KeySearchFieldArray = New Array;
		
		MetadataObjectTabularSection = Object.Metadata().TabularSections[TabularSectionName];
		
		For Each Attribute In MetadataObjectTabularSection.Attributes Do
			
			KeySearchFieldArray.Add(Attribute.Name);
			
		EndDo;
		
		KeySearchFields = StrConcat(KeySearchFieldArray, ",");
		
	EndIf;
	
	UUID = StrReplace(String(New UUID), "-", "_");
	
	OrderFieldName = "OrderField_[UUID]";
	OrderFieldName = StrReplace(OrderFieldName, "[UUID]", UUID);
	
	IteratorColumnName = "IteratorField_[UUID]";
	IteratorColumnName = StrReplace(IteratorColumnName, "[UUID]", UUID);
	
	ObjectTabularSection = Object[TabularSectionName];
	
	ObjectCollection = ObjectTabularSection.Unload();
	
	ExchangeFileCollection = ObjectCollection.CopyColumns();
	ExchangeFileCollection.Columns.Add(OrderFieldName);
	
	FillExchangeFileCollection(Object, ExchangeFileCollection, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, KeySearchFieldArray, OrderFieldName);
	
	AddColumnWithValueToTable(ExchangeFileCollection, +1, IteratorColumnName);
	AddColumnWithValueToTable(ObjectCollection,     -1, IteratorColumnName);
	
	GroupCollection = InitTableByKeyFields(KeySearchFieldArray);
	GroupCollection.Columns.Add(IteratorColumnName);
	
	FillTablePropertiesValues(ExchangeFileCollection, GroupCollection);
	FillTablePropertiesValues(ObjectCollection,     GroupCollection);
	
	GroupCollection.GroupBy(KeySearchFields, IteratorColumnName);
	
	OrderCollection = ObjectTabularSection.UnloadColumns();
	OrderCollection.Columns.Add(OrderFieldName);
	
	For Each CollectionRow In GroupCollection Do
		
		// getting a filter structure
		Filter = New Structure();
		
		For Each FieldName In KeySearchFieldArray Do
			
			Filter.Insert(FieldName, CollectionRow[FieldName]);
			
		EndDo;
		
		OrderFieldsValues = Undefined;
		
		If CollectionRow[IteratorColumnName] = 0 Then
			
			// Filling in tabular section rows from the old object version.
			ObjectCollectionRows = ObjectCollection.FindRows(Filter);
			
			OrderFieldsValues = ExchangeFileCollection.FindRows(Filter);
			
		Else
			
			// Filling in tabular section rows from the exchange file collection.
			ObjectCollectionRows = ExchangeFileCollection.FindRows(Filter);
			
		EndIf;
		
		// Adding object tabular section rows.
		For Each CollectionRow In ObjectCollectionRows Do
			
			OrderCollectionRow = OrderCollection.Add();
			
			FillPropertyValues(OrderCollectionRow, CollectionRow);
			
			If OrderFieldsValues <> Undefined Then
				
				OrderCollectionRow[OrderFieldName] = OrderFieldsValues[ObjectCollectionRows.Find(CollectionRow)][OrderFieldName];
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	OrderCollection.Sort(OrderFieldName);
	
	// Importing result to the object tabular section.
	Try
		ObjectTabularSection.Load(OrderCollection);
	Except
		
		Text = NStr("ru = 'Имя табличной части: %1'; en = 'Tabular section name: %1'; pl = 'Nazwa sekcji tabelarycznej: %1';de = 'Tabellarischer Name: %1';ro = 'Nume secțiune de tabel:  %1';tr = 'Sekme bölümü adı: %1'; es_ES = 'Nombre de la sección tabular: %1'");
		
		WP = ExchangeProtocolRecord(83, ErrorDescription());
		WP.Object     = Object;
		WP.ObjectType = TypeOf(Object);
		WP.Text = StringFunctionsClientServer.SubstituteParametersToString(Text, TabularSectionName);
		WriteToExecutionProtocol(83, WP);
		
		deSkip(ExchangeFile);
		Return;
	EndTry;
	
EndProcedure

Procedure FillTablePropertiesValues(SourceCollection, DestinationCollection)
	
	For Each CollectionItem In SourceCollection Do
		
		FillPropertyValues(DestinationCollection.Add(), CollectionItem);
		
	EndDo;
	
EndProcedure

Function InitTableByKeyFields(KeySearchFieldArray)
	
	Collection = New ValueTable;
	
	For Each FieldName In KeySearchFieldArray Do
		
		Collection.Columns.Add(FieldName);
		
	EndDo;
	
	Return Collection;
	
EndFunction

Procedure AddColumnWithValueToTable(Collection, Value, IteratorColumnName)
	
	Collection.Columns.Add(IteratorColumnName);
	Collection.FillValues(Value, IteratorColumnName);
	
EndProcedure

Procedure FillExchangeFileCollection(Object, ExchangeFileCollection, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, KeySearchFieldArray, OrderFieldName)
	
	BranchName = TabularSectionName + "TabularSection";
	
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[BranchName];
	Else
		TypesInformation = Undefined;
	EndIf;
	
	RecordNumber = 0;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Record" Then
			
			SetExchangeFileCollectionProperties(Object, ExchangeFileCollection, TypesInformation, ObjectParameters, RecordNumber, TabularSectionName, OrderFieldName);
			
			RecordNumber = RecordNumber + 1;
			
		ElsIf (NodeName = "TabularSection") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function KeySearchFieldsByTabularSection(OCR, TabularSectionName, KeySearchFieldArray, KeySearchFields)
	
	If OCR = Undefined Then
		Return False;
	EndIf;
	
	SearchDataInTS = OCR.SearchInTabularSections.Find("TabularSection." + TabularSectionName, "ItemName");
	
	If SearchDataInTS = Undefined Then
		Return False;
	EndIf;
	
	If Not SearchDataInTS.Valid Then
		Return False;
	EndIf;
	
	KeySearchFieldArray = SearchDataInTS.KeySearchFieldArray;
	KeySearchFields        = SearchDataInTS.KeySearchFields;
	
	Return True;

EndFunction

// Imports object records.
//
// Parameters:
//  Object         - an object whose records are imported.
//  Name - a register name.
//  Clear - if True, register records are cleared beforehand.
// 
Procedure ImportRegisterRecords(Object, Name, Clear, GeneralDocumentTypeInformation, 
	ObjectParameters, Rule)
	
	RegisterRecordName = Name + "RecordSet";
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[RegisterRecordName];
	Else
	    TypesInformation = Undefined;
	EndIf;
	
	SearchDataInTS = Undefined;
	
	TSCopyForSearch = Undefined;
	
	RegisterRecords = Object.RegisterRecords[Name];
	
	RegisterRecords.Read();
	RegisterRecords.Write = True;

	If Clear
		AND RegisterRecords.Count() <> 0 Then
		
		If SearchDataInTS <> Undefined Then 
			TSCopyForSearch = RegisterRecords.Unload();
		EndIf;
		
        RegisterRecords.Clear();
		
	ElsIf SearchDataInTS <> Undefined Then
		
		TSCopyForSearch = RegisterRecords.Unload();	
		
	EndIf;
	
	RecordNumber = 0;
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
			
		If      NodeName = "Record" Then
			
			Record = RegisterRecords.Add();
			SetRecordProperties(Record, TypesInformation, ObjectParameters, RegisterRecordName, RecordNumber, SearchDataInTS, TSCopyForSearch);
			
			RecordNumber = RecordNumber + 1;
			
		ElsIf (NodeName = "RecordSet") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets object (record) properties.
//
// Parameters:
//  Record         - an object whose properties are set.
//                   For example, a tabular section row or a register record.
//
Procedure SetRecordProperties(Record, TypesInformation, 
	ObjectParameters, BranchName, RecordNumber,
	SearchDataInTS = Undefined, TSCopyForSearch = Undefined)
	
	MustSearchInTS = (SearchDataInTS <> Undefined)
								AND (TSCopyForSearch <> Undefined)
								AND TSCopyForSearch.Count() <> 0;
								
	If MustSearchInTS Then
									
		PropertyReadingStructure = New Structure();
		ExtDimensionReadingStructure = New Structure();
		
	EndIf;
		
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property"
			OR NodeName = "ParameterValue" Then
			
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name    = deAttribute(ExchangeFile, StringType, "Name");
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			If Name = "RecordType" AND StrFind(Metadata.FindByType(TypeOf(Record)).FullName(), "AccumulationRegister") Then
				
				PropertyType = AccumulationRecordTypeType;
				
			Else
				
				PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
				
			EndIf;
			
			PropertyValue = ReadProperty(PropertyType,,, OCRName);
			
			If IsParameter Then
				AddComplexParameterIfNecessary(ObjectParameters, BranchName, RecordNumber, Name, PropertyValue);			
			ElsIf MustSearchInTS Then 
				PropertyReadingStructure.Insert(Name, PropertyValue);	
			Else
				
				Try
					
					Record[Name] = PropertyValue;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorDescription());
					WP.OCRName           = OCRName;
					WP.Object           = Record;
					WP.ObjectType       = TypeOf(Record);
					WP.Property         = Name;
					WP.Value         = PropertyValue;
					WP.ValueType      = TypeOf(PropertyValue);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "ExtDimensionsDr" OR NodeName = "ExtDimensionsCr" Then
			
			// The search by extra dimensions is not implemented.
			
			varKey = Undefined;
			Value = Undefined;
			
			While ExchangeFile.Read() Do
				
				NodeName = ExchangeFile.LocalName;
								
				If NodeName = "Property" Then
					
					Name    = deAttribute(ExchangeFile, StringType, "Name");
					OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
					
					PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
										
					If Name = "Key" Then
						
						varKey = ReadProperty(PropertyType);
						
					ElsIf Name = "Value" Then
						
						Value = ReadProperty(PropertyType,,, OCRName);
						
					EndIf;
					
				ElsIf (NodeName = "ExtDimensionsDr" OR NodeName = "ExtDimensionsCr") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
					
					Break;
					
				Else
					
					WriteToExecutionProtocol(9);
					Break;
					
				EndIf;
				
			EndDo;
			
			If varKey <> Undefined 
				AND Value <> Undefined Then
				
				If NOT MustSearchInTS Then
				
					Record[NodeName][varKey] = Value;
					
				Else
					
					RecordMap = Undefined;
					If NOT ExtDimensionReadingStructure.Property(NodeName, RecordMap) Then
						RecordMap = New Map;
						ExtDimensionReadingStructure.Insert(NodeName, RecordMap);
					EndIf;
					
					RecordMap.Insert(varKey, Value);
					
				EndIf;
				
			EndIf;
				
		ElsIf (NodeName = "Record") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	If MustSearchInTS Then
		
		SearchStructure = New Structure();
		
		For Each SearchItem In  SearchDataInTS.TSSearchFields Do
			
			ItemValue = Undefined;
			PropertyReadingStructure.Property(SearchItem, ItemValue);
			
			SearchStructure.Insert(SearchItem, ItemValue);		
			
		EndDo;		
		
		SearchResultArray = TSCopyForSearch.FindRows(SearchStructure);
		
		RecordFound = SearchResultArray.Count() > 0;
		If RecordFound Then
			FillPropertyValues(Record, SearchResultArray[0]);
		EndIf;
		
		// Filling with properties and extra dimension value.
		For Each KeyAndValue In PropertyReadingStructure Do
			
			Record[KeyAndValue.Key] = KeyAndValue.Value;
			
		EndDo;
		
		For Each ItemName In ExtDimensionReadingStructure Do
			
			For Each ItemKey In ItemName.Value Do
			
				Record[ItemName.Key][ItemKey.Key] = ItemKey.Value;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Imports an object of the TypeDescription type from the specified XML source.
//
// Parameters:
//  Source - an XML source.
// 
Function ImportObjectTypes(Source)
	
	// DateQualifiers
	
	DateComposition =  deAttribute(Source, StringType,  "DateComposition");
	
	// StringQualifiers
	
	Length           =  deAttribute(Source, NumberType,  "Length");
	AllowedLength =  deAttribute(Source, StringType, "AllowedLength");
	
	// NumberQualifiers
	
	NumberOfDigits             = deAttribute(Source, NumberType,  "Digits");
	DigitsInFractionalPart = deAttribute(Source, NumberType,  "FractionDigits");
	AllowedFlag          = deAttribute(Source, StringType, "AllowedSign");
	
	// Reading the array of types
	
	TypesArray = New Array;
	
	While Source.Read() Do
		NodeName = Source.LocalName;
		
		If      NodeName = "Type" Then
			TypesArray.Add(Type(deElementValue(Source, StringType)));
		ElsIf (NodeName = "Types") AND ( Source.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			WriteToExecutionProtocol(9);
			Break;
		EndIf;
		
	EndDo;
	
	If TypesArray.Count() > 0 Then
		
		// DateQualifiers
		
		If DateComposition = "Date" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Date);
		ElsIf DateComposition = "DateTime" Then
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		ElsIf DateComposition = "Time" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Time);
		Else
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		EndIf;
		
		// NumberQualifiers
		
		If NumberOfDigits > 0 Then
			If AllowedFlag = "Nonnegative" Then
				Sign = AllowedSign.Nonnegative;
			Else
				Sign = AllowedSign.Any;
			EndIf; 
			NumberQualifiers  = New NumberQualifiers(NumberOfDigits, DigitsInFractionalPart, Sign);
		Else
			NumberQualifiers  = New NumberQualifiers();
		EndIf;
		
		// StringQualifiers
		
		If Length > 0 Then
			If AllowedLength = "Fixed" Then
				AllowedLength = AllowedLength.Fixed;
			Else
				AllowedLength = AllowedLength.Variable;
			EndIf;
			StringQualifiers = New StringQualifiers(Length, AllowedLength);
		Else
			StringQualifiers = New StringQualifiers();
		EndIf; 
		
		Return New TypeDescription(TypesArray, NumberQualifiers, StringQualifiers, DateQualifiers);
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure WriteDocumentInSafeMode(Document, ObjectType)
	
	If Document.Posted Then
						
		Document.Posted = False;
			
	EndIf;		
								
	WriteObjectToIB(Document, ObjectType);	
	
EndProcedure

Function ObjectByRefAndAddInformation(CreatedObject, Ref)
	
	// If you have created an object, work with it, if you have found an object, receive it.
	If CreatedObject <> Undefined Then
		
		Object = CreatedObject;
		
	ElsIf Ref = Undefined Then
		
		Object = Undefined;
		
	ElsIf Ref.IsEmpty() Then
		
		Object = Undefined;
		
	Else
		
		Object = Ref.GetObject();
		
	EndIf;
	
	Return Object;
EndFunction

Procedure ObjectImportComments(SN, RuleName, Source, ObjectType, GSN = 0)
	
	If CommentObjectProcessingFlag Then
		
		MessageString = NStr("ru = 'Загрузка объекта № %1'; en = 'Importing object #%1'; pl = 'Pobieranie obiektu nr %1';de = 'Download Objektnummer %1';ro = 'Importul obiectului Nr. %1';tr = '%1 sayılı nesneyi içe aktar'; es_ES = 'Carga del objeto № %1'");
		Number = ?(SN <> 0, SN, GSN);
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Number);
		
		WP = ExchangeProtocolRecord();
		
		If Not IsBlankString(RuleName) Then
			
			WP.OCRName = RuleName;
			
		EndIf;
		
		If Not IsBlankString(Source) Then
			
			WP.Source = Source;
			
		EndIf;
		
		WP.ObjectType = ObjectType;
		WriteToExecutionProtocol(MessageString, WP, False);
		
	EndIf;	
	
EndProcedure

Procedure AddParameterIfNecessary(DataParameters, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	DataParameters.Insert(ParameterName, ParameterValue);
	
EndProcedure

Procedure AddComplexParameterIfNecessary(DataParameters, ParameterBranchName, RowNumber, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	CurrentParameterData = DataParameters[ParameterBranchName];
	
	If CurrentParameterData = Undefined Then
		
		CurrentParameterData = New ValueTable;
		CurrentParameterData.Columns.Add("LineNumber");
		CurrentParameterData.Columns.Add("ParameterName");
		CurrentParameterData.Indexes.Add("LineNumber");
		
		DataParameters.Insert(ParameterBranchName, CurrentParameterData);	
		
	EndIf;
	
	If CurrentParameterData.Columns.Find(ParameterName) = Undefined Then
		CurrentParameterData.Columns.Add(ParameterName);
	EndIf;		
	
	RowData = CurrentParameterData.Find(RowNumber, "LineNumber");
	If RowData = Undefined Then
		RowData = CurrentParameterData.Add();
		RowData.LineNumber = RowNumber;
	EndIf;		
	
	RowData[ParameterName] = ParameterValue;
	
EndProcedure

Function ReadObjectChangeRecordInfo()
	
	// Assigning CROSS values to variables. Information register is symmetric.
	DestinationUUID = deAttribute(ExchangeFile, StringType, "SourceUUID");
	SourceUUID = deAttribute(ExchangeFile, StringType, "DestinationUUID");
	DestinationType                     = deAttribute(ExchangeFile, StringType, "SourceType");
	SourceType                     = deAttribute(ExchangeFile, StringType, "DestinationType");
	BlankSet                      = deAttribute(ExchangeFile, BooleanType, "BlankSet");
	
	Try
		SourceUUID = New UUID(SourceUUID);
	Except
		
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
		
	EndTry;
	
	// Getting the source property structure by the source type.
	Try
		PropertyStructure = Managers[Type(SourceType)];
	Except
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
	EndTry;
	
	// Getting the source reference by GUID.
	SourceUUID = PropertyStructure.Manager.GetRef(SourceUUID);
	
	// If reference is not received, do not write this set.
	If Not ValueIsFilled(SourceUUID) Then
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
	EndIf;
	
	RecordSet = ObjectMapsRegisterManager.CreateRecordSet();
	
	// filter for a record set
	RecordSet.Filter.InfobaseNode.Set(ExchangeNodeDataImport);
	RecordSet.Filter.SourceUUID.Set(SourceUUID);
	RecordSet.Filter.DestinationUUID.Set(DestinationUUID);
	RecordSet.Filter.SourceType.Set(SourceType);
	RecordSet.Filter.DestinationType.Set(DestinationType);
	
	If Not BlankSet Then
		
		// Adding a single record to the set.
		SetRow = RecordSet.Add();
		
		SetRow.InfobaseNode           = ExchangeNodeDataImport;
		SetRow.SourceUUID = SourceUUID;
		SetRow.DestinationUUID = DestinationUUID;
		SetRow.SourceType                     = SourceType;
		SetRow.DestinationType                     = DestinationType;
		
	EndIf;
	
	// Writing the record set
	WriteObjectToIB(RecordSet, "InformationRegisterRecordSet.InfobaseObjectsMaps");
	
	deSkip(ExchangeFile, "ObjectRegistrationInformation");
	
	Return RecordSet;
	
EndFunction

Procedure ExportMappingInfoAdjustment()
	
	ConversionRules = ConversionRulesTable.Copy(New Structure("SynchronizeByID", True), "SourceType, DestinationType");
	ConversionRules.GroupBy("SourceType, DestinationType");
	
	For Each Rule In ConversionRules Do
		
		Manager = Managers.Get(Type(Rule.SourceType)).Manager;
		
		If TypeOf(Manager) = Type("BusinessProcessRoutePoints") Then
			Continue;
		EndIf;
		
		If Manager <> Undefined Then
			
			Selection = Manager.Select();
			
			While Selection.Next() Do
				
				UUID = String(Selection.Ref.UUID());
				
				Destination = CreateNode("ObjectRegistrationDataAdjustment");
				
				SetAttribute(Destination, "UUID", UUID);
				SetAttribute(Destination, "SourceType",            Rule.SourceType);
				SetAttribute(Destination, "DestinationType",            Rule.DestinationType);
				
				Destination.WriteEndElement(); // ObjectChangeRecordDataAdjustment
				
				WriteToFile(Destination);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadMappingInfoAdjustment()
	
	// Assigning CROSS values to variables. Information register is symmetric.
	UUID = deAttribute(ExchangeFile, StringType, "UUID");
	DestinationType            = deAttribute(ExchangeFile, StringType, "SourceType");
	SourceType            = deAttribute(ExchangeFile, StringType, "DestinationType");
	
	DestinationUUID = UUID;
	SourceUUID = UUID;
	
	InfobaseObjectsMapQuery.SetParameter("InfobaseNode", ExchangeNodeDataImport);
	InfobaseObjectsMapQuery.SetParameter("DestinationUUID", DestinationUUID);
	InfobaseObjectsMapQuery.SetParameter("DestinationType", DestinationType);
	InfobaseObjectsMapQuery.SetParameter("SourceType", SourceType);
	
	QueryResult = InfobaseObjectsMapQuery.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return; // Skipping data as information already exists in the register.
	EndIf;
	
	Try
		UUID = SourceUUID;
		SourceUUID = New UUID(SourceUUID);
	Except
		Return;
	EndTry;
	
	// Getting the source property structure by the source type.
	PropertyStructure = Managers[Type(SourceType)];
	
	// Getting the source reference by GUID.
	SourceUUID = PropertyStructure.Manager.GetRef(SourceUUID);
	
	Object = SourceUUID.GetObject();
	
	If Object = Undefined Then
		Return; // Skipping data if there in no such object in the infobase.
	EndIf;
	
	// Adding the record to the mapping register.
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", ExchangeNodeDataImport);
	RecordStructure.Insert("SourceUUID", SourceUUID);
	RecordStructure.Insert("DestinationUUID", DestinationUUID);
	RecordStructure.Insert("DestinationType",                     DestinationType);
	RecordStructure.Insert("SourceType",                     SourceType);
	
	InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure);
	
	IncreaseImportedObjectCounter();
	
EndProcedure

Function ReadRegisterRecordSet()
	
	// Stubs to support debugging mechanism of event handler code.
	Var Ref,ObjectFound, DontReplaceObject, WriteMode, PostingMode, GenerateNewNumberOrCodeIfNotSet, ObjectIsModified;
	
	SN						= deAttribute(ExchangeFile, NumberType,  "Sn");
	RuleName				= deAttribute(ExchangeFile, StringType, "RuleName");
	ObjectTypeString       = deAttribute(ExchangeFile, StringType, "Type");
	ExchangeObjectPriority  = ExchangeObjectPriority(ExchangeFile);
	
	IsEmptySet			= deAttribute(ExchangeFile, BooleanType, "BlankSet");
	If Not ValueIsFilled(IsEmptySet) Then
		IsEmptySet = False;
	EndIf;
	
	ObjectType 				= Type(ObjectTypeString);
	Source 				= Undefined;
	SearchProperties 			= Undefined;
	
	ObjectImportComments(SN, RuleName, Undefined, ObjectType);
	
	RegisterRowTypeName = StrReplace(ObjectTypeString, "InformationRegisterRecordSet.", "InformationRegisterRecord.");
	RegisterName = StrReplace(ObjectTypeString, "InformationRegisterRecordSet.", "");
	
	RegisterSetRowType = Type(RegisterRowTypeName);
	
	PropertyStructure = Managers[RegisterSetRowType];
	ObjectTypeName   = PropertyStructure.TypeName;
	
	TypesInformation = DataForImportTypeMap()[RegisterSetRowType];
	
	Object          = Undefined;
		
	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		HasBeforeImportHandler = Rule.HasBeforeImportHandler;
		HasOnImportHandler    = Rule.HasOnImportHandler;
		HasAfterImportHandler  = Rule.HasAfterImportHandler;
		
	Else
		
		HasBeforeImportHandler = False;
		HasOnImportHandler    = False;
		HasAfterImportHandler  = False;
		
	EndIf;

    // BeforeImportObject global event handler.
	
	If HasBeforeImportObjectGlobalHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeImportObject(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
																	  GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																	  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Conversion.BeforeImportObject);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(53, ErrorDescription(), RuleName, Source, 
			ObjectType, Undefined, NStr("ru = 'ПередЗагрузкойОбъекта (глобальный)'; en = 'BeforeImportObject (global)'; pl = 'BeforeObjectImport (globalny)';de = 'VorDemObjektimport (global)';ro = 'BeforeObjectImport (global)';tr = 'NesneİçeAktarılmadanÖnce (global)'; es_ES = 'BeforeObjectImport (global)'"));
			
		EndTry;
		
		If Cancel Then	//	Canceling the object import
			
			deSkip(ExchangeFile, "RegisterRecordSet");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	
	// BeforeImportObject event handler.
	If HasBeforeImportHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				Execute_OCR_HandlerBeforeObjectImport(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
															  GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
															  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Rule.BeforeImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(19, ErrorDescription(), RuleName, Source, 
				ObjectType, Undefined, "BeforeImportObject");
			
		EndTry;
		
		If Cancel Then // Canceling the object import
			
			deSkip(ExchangeFile, "RegisterRecordSet");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	FilterReadMode = False;
	RecordReadingMode = False;
	
	RegisterFilter = Undefined;
	CurrentRecordSetRow = Undefined;
	ObjectParameters = Undefined;
	RecordSetParameters = Undefined;
	RecordNumber = -1;
	
	// Reading what is written in the register.
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Filter" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
					
				Object = InformationRegisters[RegisterName].CreateRecordSet();
				RegisterFilter = Object.Filter;
			
				FilterReadMode = True;
					
			EndIf;			
		
		ElsIf NodeName = "Property"
			OR NodeName = "ParameterValue" Then
			
			IsParameterForObject = (NodeName = "ParameterValue");
			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "DoNotReplace");
			OCRName             = deAttribute(ExchangeFile, StringType, "OCRName");
			
			// Reading and setting the property value.
			PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
			PropertyNotFoundByRef = False;
			
			// Always create
			Value = ReadProperty(PropertyType, IsEmptySet, PropertyNotFoundByRef, OCRName);
			
			If IsParameterForObject Then
				
				If FilterReadMode Then
					AddParameterIfNecessary(RecordSetParameters, Name, Value);
				Else
					// Supplementing the object parameter collection.
					AddParameterIfNecessary(ObjectParameters, Name, Value);
					AddComplexParameterIfNecessary(RecordSetParameters, "Rows", RecordNumber, Name, Value);
				EndIf;
				
			Else
 				
				Try
					
					If FilterReadMode Then
						RegisterFilter[Name].Set(Value);						
					ElsIf RecordReadingMode Then
						CurrentRecordSetRow[Name] = Value;
					EndIf;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorDescription());
					WP.OCRName           = RuleName;
					WP.Source         = Source;
					WP.Object           = Object;
					WP.ObjectType       = ObjectType;
					WP.Property         = Name;
					WP.Value         = Value;
					WP.ValueType      = TypeOf(Value);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "RecordSetRows" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
				
				// OnImportObject event handler is triggered before reading the first set record.
				// 
				If FilterReadMode = True
					AND HasOnImportHandler Then
					
					Try
						
						If ImportHandlersDebug Then
							
							Execute_OCR_HandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source, 
						ObjectType, Object, "OnImportObject");
						
					EndTry;
					
				EndIf;
				
				FilterReadMode = False;
				RecordReadingMode = True;
				
			EndIf;
			
		ElsIf NodeName = "Object" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
			
				CurrentRecordSetRow = Object.Add();	
			    RecordNumber = RecordNumber + 1;
				
			EndIf;
			
		ElsIf NodeName = "RegisterRecordSet" AND ExchangeFile.NodeType = XMLNodeTypeEndElement Then
			
			Break;
						
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	// after import
	Cancel = False;
	If HasAfterImportHandler Then
		
		Try
			
			If ImportHandlersDebug Then
				
				Execute_OCR_HandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
															 ObjectIsModified, ObjectTypeName, ObjectFound, Rule);
				
			Else
				
				Execute(Rule.AfterImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(21, ErrorDescription(), RuleName, Source, 
				ObjectType, Object, "AfterImportObject");
			
		EndTry;
		
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If Object <> Undefined Then
		
		GetItem = DataItemReceive.Auto;
		SendBack = False;
		
		Object.AdditionalProperties.Insert("DataExchange", New Structure("DataAnalysis", Not DataImportToInfobaseMode()));
		
		If ExchangeObjectPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
			StandardSubsystemsServer.OnReceiveDataFromSlave(Object, GetItem, SendBack, ExchangeNodeDataImportObject);
		Else
			StandardSubsystemsServer.OnReceiveDataFromMaster(Object, GetItem, SendBack, ExchangeNodeDataImportObject);
		EndIf;
		
		If GetItem = DataItemReceive.Ignore Then
			Return Undefined;
		EndIf;
		
		WriteObjectToIB(Object, ObjectType);
		
	EndIf;
	
	Return Object;
	
EndFunction

Procedure SupplementNotWrittenObjectStack(NumberForStack, Object, KnownRef, ObjectType, TypeName, GenerateCodeAutomatically = False, ObjectParameters = Undefined)
	
	StackString = GlobalNotWrittenObjectStack[NumberForStack];
	If StackString <> Undefined Then
		Return;
	EndIf;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Object",Object);
	ParametersStructure.Insert("KnownRef",KnownRef);
	ParametersStructure.Insert("ObjectType", ObjectType);
	ParametersStructure.Insert("TypeName", TypeName);
	ParametersStructure.Insert("GenerateCodeAutomatically", GenerateCodeAutomatically);
	ParametersStructure.Insert("ObjectParameters", ObjectParameters);

	GlobalNotWrittenObjectStack.Insert(NumberForStack, ParametersStructure);
	
EndProcedure

Procedure DeleteFromNotWrittenObjectStack(SN, GSN)
	
	NumberForStack = ?(SN = 0, GSN, SN);
	GlobalNotWrittenObjectStack.Delete(NumberForStack);
	
EndProcedure

Procedure ExecuteWriteNotWrittenObjects()
	
	For Each DataString In GlobalNotWrittenObjectStack Do
		
		// Deferred objects writing
		Object = DataString.Value.Object;
		
		If DataString.Value.GenerateCodeAutomatically = True Then
			
			ExecuteNumberCodeGenerationIfNecessary(True, Object,
				DataString.Value.TypeName, True);
			
		EndIf;
		
		WriteObjectToIB(Object, DataString.Value.ObjectType);
		
	EndDo;
	
	GlobalNotWrittenObjectStack.Clear();
	
EndProcedure

Procedure ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, ObjectTypeName, 
	DataExchangeMode)
	
	If Not GenerateNewNumberOrCodeIfNotSet
		OR NOT DataExchangeMode Then
		
		// If the number does not need to be generated, or generated not in the data exchange mode, then 
		// nothing needs to be done. The platform will generate everything itself.
		Return;
	EndIf;
	
	// Checking whether the code or number are filled (depends on the object type).
	If ObjectTypeName = "Document"
		OR ObjectTypeName =  "BusinessProcess"
		OR ObjectTypeName = "Task" Then
		
		If NOT ValueIsFilled(Object.Number) Then
			
			Object.SetNewNumber();
			
		EndIf;
		
	ElsIf ObjectTypeName = "Catalog"
		OR ObjectTypeName = "ChartOfCharacteristicTypes"
		OR ObjectTypeName = "ExchangePlan" Then
		
		If NOT ValueIsFilled(Object.Code) Then
			
			Object.SetNewCode();
			
		EndIf;	
		
	EndIf;
	
EndProcedure

Function ExchangeObjectPriority(ExchangeFile)
		
	PriorityString = deAttribute(ExchangeFile, StringType, "ExchangeObjectPriority");
	If IsBlankString(PriorityString) Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	ElsIf PriorityString = "Above" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	ElsIf PriorityString = "Below" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority;
	ElsIf PriorityString = "Matches" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch;
	EndIf;
	
	Return PriorityValue;
	
EndFunction

// Reads the next object from the exchange file and imports it.
//
// Parameters:
//  No.
// 
Function ReadObject(UUIDAsString = "")

	SN						= deAttribute(ExchangeFile, NumberType,  "Sn");
	GSN					= deAttribute(ExchangeFile, NumberType,  "Gsn");
	Source				= deAttribute(ExchangeFile, StringType, "Source");
	RuleName				= deAttribute(ExchangeFile, StringType, "RuleName");
	DontReplaceObject 		= deAttribute(ExchangeFile, BooleanType, "DoNotReplace");
	AutonumberingPrefix	= deAttribute(ExchangeFile, StringType, "AutonumberingPrefix");
	ExchangeObjectPriority  = ExchangeObjectPriority(ExchangeFile);
	
	ObjectTypeString       = deAttribute(ExchangeFile, StringType, "Type");
	ObjectType 				= Type(ObjectTypeString);
	TypesInformation = DataForImportTypeMap()[ObjectType];
	
    
	ObjectImportComments(SN, RuleName, Source, ObjectType, GSN);
    	
	PropertyStructure = Managers[ObjectType];
	ObjectTypeName   = PropertyStructure.TypeName;


	If ObjectTypeName = "Document" Then
		
		WriteMode     = deAttribute(ExchangeFile, StringType, "WriteMode");
		PostingMode = deAttribute(ExchangeFile, StringType, "PostingMode");
		
	EndIf;
	
	Object          = Undefined;
	ObjectFound    = True;
	ObjectCreatedInCurrentInfobase = Undefined;
	
	SearchProperties  = New Map;
	SearchPropertiesDontReplace  = New Map;
	
	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		HasBeforeImportHandler = Rule.HasBeforeImportHandler;
		HasOnImportHandler    = Rule.HasOnImportHandler;
		HasAfterImportHandler  = Rule.HasAfterImportHandler;
		GenerateNewNumberOrCodeIfNotSet = Rule.GenerateNewNumberOrCodeIfNotSet;
		DontReplaceObjectCreatedInDestinationInfobase =  Rule.DoNotReplaceObjectCreatedInDestinationInfobase;
		
	Else
		
		HasBeforeImportHandler = False;
		HasOnImportHandler    = False;
		HasAfterImportHandler  = False;
		GenerateNewNumberOrCodeIfNotSet = False;
		DontReplaceObjectCreatedInDestinationInfobase = False;
		
	EndIf;


    // BeforeImportObject global event handler.
	
	If HasBeforeImportObjectGlobalHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeImportObject(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
																	  GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																	  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Conversion.BeforeImportObject);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(53, ErrorDescription(), RuleName, Source, 
				ObjectType, Undefined, NStr("ru = 'ПередЗагрузкойОбъекта (глобальный)'; en = 'BeforeImportObject (global)'; pl = 'BeforeObjectImport (globalny)';de = 'VorDemObjektimport (global)';ro = 'BeforeObjectImport (global)';tr = 'NesneİçeAktarılmadanÖnce (global)'; es_ES = 'BeforeObjectImport (global)'"));				
							
		EndTry;
				
		If Cancel Then	//	Canceling the object import
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	
	// BeforeImportObject event handler.
	If HasBeforeImportHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				Execute_OCR_HandlerBeforeObjectImport(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
															  GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
															  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Rule.BeforeImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(19, ErrorDescription(), RuleName, Source, 
			ObjectType, Undefined, "BeforeImportObject");				
			
		EndTry;
		
		If Cancel Then // Canceling the object import
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;

	ConstantOperatingMode = False;
	ConstantName = "";
	
	GlobalRefSn = 0;
	RefSN = 0;
	ObjectParameters = Undefined;
	RecordSet = Undefined;
	WriteObject = True;
	
	// The flag determines whether the object was found by the search fields in the mapping mode of objects or not.
	// If the flag is set, then the information on mapping GUID of source and destination reference is 
	// added to the mapping register.
	ObjectFoundBySearchFields = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property"
			OR NodeName = "ParameterValue" Then
			
			IsParameterForObject = (NodeName = "ParameterValue");
			
			If Object = Undefined Then
				
				// The object was not found and was not created, attempting to do it now.
				ObjectFound = False;
				
				// OnImportObject event handler.
				If HasOnImportHandler Then
					ObjectIsModified = True;
					// Rewriting the object if OnImporthandler exists, because of possible changes.
					Try
						
						If ImportHandlersDebug Then
							
							Execute_OCR_HandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source,
																		 ObjectType, Object, "OnImportObject");
						
					EndTry;							
					
				EndIf;
				
				// Failed to create the object in the event, creating it separately.
				If Object = Undefined Then
					
					If ObjectTypeName = "Constants" Then
						
						Object = Undefined;
						ConstantOperatingMode = True;
												
					Else
						
						CreateNewObject(ObjectType, SearchProperties, Object, False, , ,RecordSet);
																	
					EndIf;
					
				EndIf;
				
			EndIf; 

			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "DoNotReplace");
			OCRName             = deAttribute(ExchangeFile, StringType, "OCRName");
			
			If ConstantOperatingMode Then
				
				Object = Constants[Name].CreateValueManager();	
				ConstantName = Name;
				Name = "Value";
				
			ElsIf NOT IsParameterForObject
				AND ((ObjectFound AND DontReplaceProperty) 
				OR (Name = "IsFolder") 
				OR (Object[Name] = NULL)) Then
				
				// Unknown property
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf; 

			
			// Reading and setting the property value.
			PropertyType = PropertyTypeByAdditionalData(TypesInformation, Name);
			Value    = ReadProperty(PropertyType,,, OCRName);
			
			If IsParameterForObject Then
				
				// Supplementing the object parameter collection.
				AddParameterIfNecessary(ObjectParameters, Name, Value);
				
			Else
				
				Try
					
					Object[Name] = Value;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorDescription());
					WP.OCRName           = RuleName;
					WP.Sn              = SN;
					WP.Gsn             = GSN;
					WP.Source         = Source;
					WP.Object           = Object;
					WP.ObjectType       = ObjectType;
					WP.Property         = Name;
					WP.Value         = Value;
					WP.ValueType      = TypeOf(Value);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "Ref" Then
			
			// Reference to item. First receiving an object by reference, and then setting properties.
			InfobaseObjectsMaps = Undefined;
			CreatedObject = Undefined;
			DontCreateObjectIfNotFound = Undefined;
			KnownUUIDRef = Undefined;
			DontReplaceObjectCreatedInDestinationInfobase = False;
			RecordObjectChangeAtSenderNode = False;
												
			Ref = FindObjectByRef(ObjectType,
										SearchProperties,
										SearchPropertiesDontReplace,
										ObjectFound,
										CreatedObject,
										DontCreateObjectIfNotFound,
										True,
										GlobalRefSn,
										RefSN,
										ObjectFoundBySearchFields,
										KnownUUIDRef,
										True,
										ObjectParameters,
										DontReplaceObjectCreatedInDestinationInfobase,
										ObjectCreatedInCurrentInfobase,
										RecordObjectChangeAtSenderNode,
										UUIDAsString,
										RuleName,
										InfobaseObjectsMaps);
				
			If ObjectTypeName = "Enum" Then
				
				Object = Ref;
				
			Else
				
				Object = ObjectByRefAndAddInformation(CreatedObject, Ref);
				
				If Object = Undefined Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
				If ObjectFound AND DontReplaceObject AND (Not HasOnImportHandler) Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
				If Ref = Undefined Then
					
					NumberForStack = ?(SN = 0, GSN, SN);
					SupplementNotWrittenObjectStack(NumberForStack, CreatedObject, KnownUUIDRef, ObjectType, 
						ObjectTypeName, Rule.GenerateNewNumberOrCodeIfNotSet, ObjectParameters);
					
				EndIf;
				
			EndIf;
			
			// OnImportObject event handler.
			If HasOnImportHandler Then
				
				Try
					
					If ImportHandlersDebug Then
						
						Execute_OCR_HandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
						
					Else
						
						Execute(Rule.OnImport);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source,
							ObjectType, Object, "OnImportObject");
					//
				EndTry;
				
				If ObjectFound AND DontReplaceObject Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
			EndIf;
			
			If RecordObjectChangeAtSenderNode = True Then
				Object.AdditionalProperties.Insert("RecordObjectChangeAtSenderNode");
			EndIf;
			
			Object.AdditionalProperties.Insert("InfobaseObjectsMaps", InfobaseObjectsMaps);
			
		ElsIf NodeName = "TabularSection"
			  OR NodeName = "RecordSet" Then
			//
			
			If DataImportToValueTableMode()
				AND ObjectTypeName <> "ExchangePlan" Then
				deSkip(ExchangeFile, NodeName);
				Continue;
			EndIf;
			
			If Object = Undefined Then
				
				ObjectFound = False;
				
				// OnImportObject event handler.
				
				If HasOnImportHandler Then
					
					Try
						
						If ImportHandlersDebug Then
							
							Execute_OCR_HandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source, 
							ObjectType, Object, "OnImportObject");							
						
					EndTry;
						
				EndIf;
				 
			EndIf;
			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "DoNotReplace");
			DontClear          = deAttribute(ExchangeFile, BooleanType, "DoNotClear");

			If ObjectFound AND DontReplaceProperty Then
				
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf;
			
			If Object = Undefined Then
					
				CreateNewObject(ObjectType, SearchProperties, Object, False);
									
			EndIf;
						
			If NodeName = "TabularSection" Then
				
				// Importing items from the tabular section
				ImportTabularSection(Object, Name, TypesInformation, ObjectParameters, Rule);
				
			ElsIf NodeName = "RecordSet" Then
				
				// Importing register
				ImportRegisterRecords(Object, Name, Not DontClear, TypesInformation, ObjectParameters, Rule);
				
			EndIf;
			
		ElsIf (NodeName = "Object") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Cancel = False;
			
			// AfterObjectImport global event handler.
			If HasAfterObjectImportGlobalHandler Then
				
				ObjectIsModified = True;
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteHandler_Conversion_AfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
																			 ObjectIsModified, ObjectTypeName, ObjectFound);
						
					Else
						
						Execute(Conversion.AfterImportObject);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(54, ErrorDescription(), RuleName, Source,
						ObjectType, Object, NStr("ru = 'ПослеЗагрузкиОбъекта (глобальный)'; en = 'AfterImportObject (global)'; pl = 'AftertObjectImport (globalny)';de = 'NachDemObjektimport (global)';ro = 'AftertObjectImport (global)';tr = 'NesneİçeAktarıldıktanSonra (global)'; es_ES = 'AftertObjectImport (global)'"));
					
				EndTry;
				
			EndIf;
			
			// AfterObjectImport event handler.
			If HasAfterImportHandler Then
				
				Try
					
					If ImportHandlersDebug Then
						
						Execute_OCR_HandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
																	 ObjectIsModified, ObjectTypeName, ObjectFound, Rule);
						
					Else
						
						Execute(Rule.AfterImport);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(21, ErrorDescription(), RuleName, Source, 
						ObjectType, Object, "AfterImportObject");				
					
				EndTry;
				
			EndIf;
			
			GetItem = DataItemReceive.Auto;
			SendBack = False;
			
			CurObject = Object;
			If ObjectTypeName = "InformationRegister" Then
				CurObject = RecordSet;
			EndIf;
			If CurObject <> Undefined Then
				If ObjectTypeName <> "Enum"
					AND ObjectTypeName <> "Constants" Then
					CurObject.AdditionalProperties.Insert("DataExchange", New Structure("DataAnalysis", Not DataImportToInfobaseMode()));
				EndIf;
				
				If ExchangeObjectPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
					StandardSubsystemsServer.OnReceiveDataFromSlave(CurObject, GetItem, SendBack, ExchangeNodeDataImportObject);
				Else
					StandardSubsystemsServer.OnReceiveDataFromMaster(CurObject, GetItem, SendBack, ExchangeNodeDataImportObject);
				EndIf;
			EndIf;
			
			If GetItem = DataItemReceive.Ignore Then
				Cancel = True;
			EndIf;
			
			If Cancel Then
				DeleteFromNotWrittenObjectStack(SN, GSN);
				Return Undefined;
			EndIf;
			
			If ObjectTypeName = "Document" Then
				
				If WriteMode = "Posting" Then
					
					WriteMode = DocumentWriteMode.Posting;
					
				ElsIf WriteMode = "UndoPosting" Then
					
					WriteMode = DocumentWriteMode.UndoPosting; 
					
				Else
					
					// Determining how to write a document.
					If Object.Posted Then
						
						WriteMode = DocumentWriteMode.Posting;
						
					Else
						
						// The document can either be posted or not.
						DocumentCanBePosted = (Object.Metadata().Posting = AllowDocumentPosting);
						
						If DocumentCanBePosted Then
							WriteMode = DocumentWriteMode.UndoPosting;
						Else
							WriteMode = DocumentWriteMode.Write;
						EndIf;
						
					EndIf;
					
				EndIf;
				
				PostingMode = ?(PostingMode = "RealTime", DocumentPostingMode.RealTime, DocumentPostingMode.Regular);
				
				// Clearing the deletion mark to post the marked for deletion object.
				If Object.DeletionMark
					AND (WriteMode = DocumentWriteMode.Posting) Then
					
					Object.DeletionMark = False;
					
				EndIf;
				
				ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, 
				ObjectTypeName, True);
				
				If DataImportToInfobaseMode() Then
					
					Try
						
						// Write the document. Information whether to post it or cancel posting is recorded separately.
						
						// If documents just need to be posted, post them as they are.
						If WriteMode = DocumentWriteMode.Write Then
							
							// Disabling the object registration mechanism when the document posting is cleared.
							// The registration mechanism will be executed on a deferred document posting (for optimizing data 
							// import performance).
							Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							
							// Setting DataExchange.Load for document register records.
							For Each CurRecord In Object.RegisterRecords Do
								SetDataExchangeLoad(CurRecord,, SendBack);
							EndDo;
							
							WriteObjectToIB(Object, ObjectType, WriteObject, SendBack);
							
							If WriteObject
								AND Object <> Undefined
								AND Object.Ref <> Undefined Then
								
								ObjectsForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
								
							EndIf;
							
						ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
							
							UndoObjectPostingInIB(Object, ObjectType, WriteObject);
							
						ElsIf WriteMode = DocumentWriteMode.Posting Then
							
							// Disabling the object registration mechanism when the document posting is cleared.
							// The registration mechanism will be executed on a deferred document posting (for optimizing data 
							// import performance).
							Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							
							UndoObjectPostingInIB(Object, ObjectType, WriteObject);
							
							// If the object is written successfully and the reference is created, putting the object in the 
							// queue to post.
							If WriteObject
								AND Object <> Undefined
								AND Object.Ref <> Undefined Then
								
								TableRow = DocumentsForDeferredPosting().Add();
								TableRow.DocumentRef = Object.Ref;
								TableRow.DocumentDate  = Object.Date;
								
								AdditionalPropertiesForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
								
							EndIf;
							
						EndIf;
						
					Except
						
						ErrorDescriptionString = ErrorDescription();
						
						If WriteObject Then
							// Failed to execute actions required for the document.
							WriteDocumentInSafeMode(Object, ObjectType);
						EndIf;
						
						WP                        = ExchangeProtocolRecord(25, ErrorDescriptionString);
						WP.OCRName                 = RuleName;
						
						If Not IsBlankString(Source) Then
							
							WP.Source           = Source;
							
						EndIf;
						
						WP.ObjectType             = ObjectType;
						WP.Object                 = String(Object);
						WriteToExecutionProtocol(25, WP);
						
						MessageString = NStr("ru = 'Ошибка при записи документа: %1. Описание ошибки: %2'; en = 'Cannot write document: %1. Error description: %2'; pl = 'Wystąpił błąd podczas zapisu dokumentu: %1 Opis błędu: %2';de = 'Beim Schreiben des Dokuments ist ein Fehler aufgetreten: %1 Fehlerbeschreibung: %2';ro = 'Eroare la înregistrarea documentului: %1. Descrierea erorii: %2';tr = 'Belge yazılırken bir hata oluştu: %1Hata açıklaması: %2'; es_ES = 'Ha ocurrido un error al grabar el documento: %1 Descripción del error: %2'");
						MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(Object), ErrorDescriptionString);
						
						// Cannot write the object properly. Report it.
						Raise MessageString;
						
					EndTry;
					
					DeleteFromNotWrittenObjectStack(SN, GSN);
					
				EndIf;
				
			ElsIf ObjectTypeName <> "Enum" Then
				
				If ObjectTypeName = "InformationRegister" Then
					
					Periodic = PropertyStructure.Periodic;
					
					If Periodic Then
						
						If Not ValueIsFilled(Object.Period) Then
							SetCurrentDateToAttribute(Object.Period);
						EndIf;
						
					EndIf;
					If RecordSet <> Undefined Then
						// The register requires the filter to be set.
						For Each FilterItem In RecordSet.Filter Do
							FilterItem.Set(Object[FilterItem.Name]);
						EndDo;
						Object = RecordSet;
					EndIf;
				EndIf;
				
				ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object,
				ObjectTypeName, True);
				
				If DataImportToInfobaseMode() Then
					
					// Disabling the object registration mechanism when the document posting is cleared.
					// The registration mechanism will be executed on a deferred document posting (for optimizing data 
					// import performance).
					If ObjectTypeName <> "Constants" Then
						Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
					EndIf;
					
					WriteObjectToIB(Object, ObjectType, WriteObject, SendBack);
					
					If NOT (ObjectTypeName = "InformationRegister"
						 OR ObjectTypeName = "Constants") Then
						// If the object is written successfully and the reference is created, puttting the object in the 
						// queue to write.
						If WriteObject
							AND Object <> Undefined
							AND Object.Ref <> Undefined Then
							
							ObjectsForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
							
						EndIf;
						
						DeleteFromNotWrittenObjectStack(SN, GSN);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			IsReferenceObjectType = NOT(ObjectTypeName = "InformationRegister"
										OR ObjectTypeName = "Constants");
			
			Break;
			
		ElsIf NodeName = "SequenceRecordSet" Then
			
			deSkip(ExchangeFile);
			
		ElsIf NodeName = "Types" Then

			If Object = Undefined Then
				
				ObjectFound = False;
				Ref  = CreateNewObject(ObjectType, SearchProperties, Object, True);
								
			EndIf; 

			ObjectTypesDetails = ImportObjectTypes(ExchangeFile);

			If ObjectTypesDetails <> Undefined Then
				
				Object.ValueType = ObjectTypesDetails;
				
			EndIf; 
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Object;

EndFunction

Procedure SwitchToNewExchange()
	
	ExchangePlanName = ExchangePlanName();
	NameOfExchangePlanToGo = ExchangePlans[ExchangePlanName].ExchangePlanNameToMigrateToNewExchange();
	
	DataSynchronizationSetup = Undefined;
	If ValueIsFilled(NodeForExchange) Then
		DataSynchronizationSetup = NodeForExchange;
	ElsIf ValueIsFilled(ExchangeNodeDataImport) Then
		DataSynchronizationSetup = ExchangeNodeDataImport;
	EndIf;

	ExchangePlans[NameOfExchangePlanToGo].SwitchToNewExchange(DataSynchronizationSetup);
	MessageString = NStr("ru = 'Выполнен автоматический переход на синхронизацию данных через формат EnterpriseData.'; en = 'Automatic switching to EnterpriseData data synchronization format.'; pl = 'Automatyczne przejście do synchronizacji danych za pośrednictwem formatu EnterpriseData.';de = 'Ein automatischer Übergang zur Synchronisation von Daten über das EnterpriseData-Format.';ro = 'Trecerea automată la sincronizarea datelor prin formatul EnterpriseData este executată.';tr = 'Otomatik olarak EnterpriseData biçimi üzerinden veri senkronizasyonu için geçiş yapıldı.'; es_ES = 'Se ha pasado automáticamente a la sincronización de datos a través del formato EnterpriseData.'");
	WriteEventLogDataExchange(MessageString, EventLogLevel.Information);
	ExchangeResultField = Enums.ExchangeExecutionResults.Canceled;
	Raise NStr("ru = 'Синхронизация данных по старой настройке отменена.'; en = 'Data synchronization with outdated settings is canceled.'; pl = 'Synchronizacja danych na starym ustawieniu została anulowana.';de = 'Die Synchronisation der Daten mit der alten Einstellung wird abgebrochen.';ro = 'Sincronizarea datelor conform setării vechi este revocată.';tr = 'Eski ayardaki veri senkronizasyonu iptal edildi.'; es_ES = 'Sincronización de datos por el ajuste antigua se ha cancelado.'");
EndProcedure

#EndRegion

#Region DataExportProcedures

Function DocumentRegisterRecordSet(DocumentRef, SourceKind, RegisterName)
	
	If SourceKind = "AccumulationRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccumulationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "InformationRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = InformationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "AccountingRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccountingRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "CalculationRegisterRecordSet" Then	
		
		DocumentRegisterRecordSet = CalculationRegisters[RegisterName].CreateRecordSet();
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	DocumentRegisterRecordSet.Filter.Recorder.Set(DocumentRef.Ref);
	DocumentRegisterRecordSet.Read();
	
	Return DocumentRegisterRecordSet;
	
EndFunction

// Generates destination object property nodes according to the specified property conversion rule collection.
//
// Parameters:
//  Source		 - an arbitrary data source.
//  Destination		 - a destination object XML node.
//  IncomingData	 - arbitrary auxiliary data that is passed to the conversion rule.
//                         
//  OutgoingData - arbitrary auxiliary data that is passed to the property object conversion rules.
//                         
//  OCR				     - a reference to the object conversion rule (property conversion rule collection parent).
//  PGCR                 - a reference to the property group conversion rule.
//  PropertyCollectionNode - property collection XML node.
// 
Procedure ExportPropertyGroup(Source, Destination, IncomingData, OutgoingData, OCR, PGCR, PropertyCollectionNode, 
	ExportRefOnly, TempFileList = Undefined, ExportRegisterRecordSetRow = False)

	
	ObjectCollection = Undefined;
	DontReplace        = PGCR.DoNotReplace;
	DontClear         = False;
	ExportGroupToFile = PGCR.ExportGroupToFile;
	
	// BeforeProcessExport handler

	If PGCR.HasBeforeProcessExportHandler Then
		
		Cancel = False;
		Try
			
			If ExportHandlersDebug Then
				
				Execute_PGCR_HandlerBeforeExportProcessing(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
																 PGCR, Cancel, ObjectCollection, DontReplace, PropertyCollectionNode, DontClear);
				
			Else
				
				Execute(PGCR.BeforeProcessExport);
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(48, ErrorDescription());
			WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
			
			TypesDetails = New TypeDescription("String");
			StringSource= TypesDetails.AdjustValue(Source);
			If Not IsBlankString(StringSource) Then
				WP.Object = TypesDetails.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
			Else
				WP.Object = "(" + TypeOf(Source) + ")";
			EndIf;
			
			WP.Handler             = "BeforeProcessPropertyGroupExport";
			ErrorMessageString = WriteToExecutionProtocol(48, WP);
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
							
		If Cancel Then // Canceling property group processing.
			
			Return;
			
		EndIf;
		
	EndIf;

	
    DestinationKind = PGCR.DestinationKind;
	SourceKind = PGCR.SourceKind;
	
	
    // Creating a node of subordinate object collection.
	PropertyNodeStructure = Undefined;
	ObjectCollectionNode = Undefined;
	MasterNodeName = "";
	
	If DestinationKind = "TabularSection" Then
		
		MasterNodeName = "TabularSection";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, TRUE, PGCR.Destination, MasterNodeName);
		
		If DontReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotReplace", "true");
						
		EndIf;
		
		If DontClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotClear", "true");
						
		EndIf;
		
	ElsIf DestinationKind = "SubordinateCatalog" Then
				
		
	ElsIf DestinationKind = "SequenceRecordSet" Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, TRUE, PGCR.Destination, MasterNodeName);
		
	ElsIf StrFind(DestinationKind, "RecordSet") > 0 Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, TRUE, PGCR.Destination, MasterNodeName);
		
		If DontReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotReplace", "true");
						
		EndIf;
		
		If DontClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotClear", "true");
						
		EndIf;
		
	Else  // Simple group
		
		ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
			PropertyCollectionNode, , , True, False);
		
		If PGCR.HasAfterProcessExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PGCR_HandlerAfterExportProcessing(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																	OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode);
					
				Else
					
					Execute(PGCR.AfterProcessExport);
					
				EndIf;
				
			Except
				
				WP = ExchangeProtocolRecord(49, ErrorDescription());
				WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
				WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
				
				TypesDetails = New TypeDescription("String");
				StringSource= TypesDetails.AdjustValue(Source);
				If Not IsBlankString(StringSource) Then
					WP.Object = TypesDetails.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
				Else
					WP.Object = "(" + TypeOf(Source) + ")";
				EndIf;
				
				WP.Handler             = "AfterProcessPropertyGroupExport";
				ErrorMessageString = WriteToExecutionProtocol(49, WP);
			
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
			EndTry;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	// Getting the collection of subordinate objects.
	
	If ObjectCollection <> Undefined Then
		
		// The collection was initialized in the BeforeProcess handler.
		
	ElsIf PGCR.GetFromIncomingData Then
		
		Try
			
			ObjectCollection = IncomingData[PGCR.Destination];
			
			If TypeOf(ObjectCollection) = Type("QueryResult") Then
				
				ObjectCollection = ObjectCollection.Unload();
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(66, ErrorDescription());
			WP.OCR  = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR = PGCR.Name + "  (" + PGCR.Description + ")";
			
			Try
				WP.Object = String(Source) + "  (" + TypeOf(Source) + ")";
			Except
				WP.Object = "(" + TypeOf(Source) + ")";
			EndTry;
			
			ErrorMessageString = WriteToExecutionProtocol(66, WP);
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
			Return;
		EndTry;
		
	ElsIf SourceKind = "TabularSection" Then
		
		ObjectCollection = Source[PGCR.Source];
		
		If TypeOf(ObjectCollection) = Type("QueryResult") Then
			
			ObjectCollection = ObjectCollection.Unload();
			
		EndIf;
		
	ElsIf SourceKind = "SubordinateCatalog" Then
		
	ElsIf StrFind(SourceKind, "RecordSet") > 0 Then
		
		ObjectCollection = DocumentRegisterRecordSet(Source, SourceKind, PGCR.Source);
				
	ElsIf IsBlankString(PGCR.Source) Then
		
		ObjectCollection = Source[PGCR.Destination];
		
		If TypeOf(ObjectCollection) = Type("QueryResult") Then
			
			ObjectCollection = ObjectCollection.Unload();
			
		EndIf;
		
	EndIf;

	ExportGroupToFile = ExportGroupToFile OR (ObjectCollection.Count() > 1000);
	ExportGroupToFile = ExportGroupToFile AND NOT ExportRegisterRecordSetRow;
	ExportGroupToFile = ExportGroupToFile AND NOT IsExchangeOverExternalConnection();
	
	If ExportGroupToFile Then
		
		PGCR.XMLNodeRequiredOnExport = False;
		
		If TempFileList = Undefined Then
			TempFileList = New ValueList();
		EndIf;
		
		RecordFileName = GetTempFileName();
		// Temporary files deletion is performed not by location via DeleteFiles(RecordFileName), but centrally.
		TempFileList.Add(RecordFileName);
		
		TempRecordFile = New TextWriter;
		Try
			
			TempRecordFile.Open(RecordFileName, TextEncoding.UTF8);
			
		Except
			
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при создании временного файла для выгрузки данных.
					|Имя файла ""%1"".
					|Описание ошибки:
					|%2'; 
					|en = 'Cannot create a temporary file for data export.
					|File name: %1.
					|Error description:
					|%2'; 
					|pl = 'Błąd podczas tworzenia pliku tymczasowego do przesłania danych.
					|Nazwa pliku ""%1"".
					|Opis błędu:
					|%2';
					|de = 'Fehler beim Erstellen einer temporären Datei für das Hochladen von Daten.
					|Dateiname ""%1"".
					| Beschreibung des Fehlers:
					|%2';
					|ro = 'Eroare la crearea fișierului temporar pentru exportul de date.
					|Numele fișierului ""%1"".
					|Descrierea erorii:
					|%2';
					|tr = 'Veri içe aktarma için geçici dosya oluşturulurken bir hata oluştu. 
					|Dosya adı ""%1"". 
					|Hata 
					|tanımlaması:%2'; 
					|es_ES = 'Error al crear el archivo temporal para subir los datos.
					|Nombre de archivo ""%1"".
					|Descripción de error:
					|%2'"),
				String(RecordFileName),
				DetailErrorDescription(ErrorInfo()));
				
			WriteToExecutionProtocol(ErrorMessageString);
			
		EndTry;
		
		InformationToWriteToFile = ObjectCollectionNode.Close();
		TempRecordFile.WriteLine(InformationToWriteToFile);
		
	EndIf;
	
	For each CollectionObject In ObjectCollection Do
		
		// BeforeExport handler
		If PGCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PGCR_HandlerBeforePropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
																	PGCR, Cancel, CollectionObject, PropertyCollectionNode, ObjectCollectionNode);
					
				Else
					
					Execute(PGCR.BeforeExport);
					
				EndIf;
				
			Except
				
				ErrorMessageString = WriteToExecutionProtocol(50);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
			If Cancel Then // Canceling subordinate object export.
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		// OnExport handler
		
		If PGCR.XMLNodeRequiredOnExport OR ExportGroupToFile Then
			CollectionObjectNode = CreateNode("Record");
		Else
			ObjectCollectionNode.WriteStartElement("Record");
			CollectionObjectNode = ObjectCollectionNode;
		EndIf;
		
		StandardProcessing	= True;
		
		If PGCR.HasOnExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PGCR_HandlerOnPropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
																 PGCR, CollectionObject, ObjectCollectionNode, CollectionObjectNode,
																 PropertyCollectionNode, StandardProcessing);
					
				Else
					
					Execute(PGCR.OnExport);
					
				EndIf;
			
		Except
				
				ErrorMessageString = WriteToExecutionProtocol(51);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
		EndIf;
		
		// Exporting the collection object properties.
		If StandardProcessing Then
			
			If PGCR.GroupRules.Count() > 0 Then
				
				ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
					CollectionObjectNode, CollectionObject, , True, False);
				
			EndIf;
			
		EndIf;
		
		// AfterExport handler
		If PGCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PGCR_HandlerAfterPropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																   OCR, PGCR, Cancel, CollectionObject, ObjectCollectionNode,
																   PropertyCollectionNode, CollectionObjectNode);
					
				Else
					
					Execute(PGCR.AfterExport);
					
				EndIf;
				
			Except
				
				ErrorMessageString = WriteToExecutionProtocol(52);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
		If Cancel Then // Canceling subordinate object export.
			
			Continue;
			
		EndIf;
			
		EndIf;
		
		If PGCR.XMLNodeRequiredOnExport Then
			AddSubordinateNode(ObjectCollectionNode, CollectionObjectNode);
		EndIf;
		
		// Filling the file with node objects.
		If ExportGroupToFile Then
			
			CollectionObjectNode.WriteEndElement();
			InformationToWriteToFile = CollectionObjectNode.Close();
			TempRecordFile.WriteLine(InformationToWriteToFile);
			
		Else
			
			If Not PGCR.XMLNodeRequiredOnExport Then
				
				ObjectCollectionNode.WriteEndElement();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// AfterProcessExport handler
	If PGCR.HasAfterProcessExportHandler Then
		
		Cancel = False;
		
		Try
			
			If ExportHandlersDebug Then
				
				Execute_PGCR_HandlerAfterExportProcessing(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode);
				
			Else
				
				Execute(PGCR.AfterProcessExport);
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(49, ErrorDescription());
			WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
			
			TypesDetails = New TypeDescription("String");
			StringSource= TypesDetails.AdjustValue(Source);
			If Not IsBlankString(StringSource) Then
				WP.Object = TypesDetails.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
			Else
				WP.Object = "(" + TypeOf(Source) + ")";
			EndIf;
			
			WP.Handler             = "AfterProcessPropertyGroupExport";
			ErrorMessageString = WriteToExecutionProtocol(49, WP);
		
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
		If Cancel Then // Canceling subordinate object collection writing.
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If ExportGroupToFile Then
		TempRecordFile.WriteLine("</" + MasterNodeName + ">"); // Closing the node
		TempRecordFile.Close(); // Closing the file
	Else
		WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, ObjectCollectionNode);
	EndIf;
	
EndProcedure

Procedure GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, DataSelection = Undefined)
	
	If Value <> Undefined Then
		Return;
	EndIf;
	
	If PCR.GetFromIncomingData Then
			
		ObjectForReceivingData = IncomingData;
		
		If Not IsBlankString(PCR.Destination) Then
		
			PropertyName = PCR.Destination;
			
		Else
			
			PropertyName = PCR.ParameterForTransferName;
			
		EndIf;
		
		ErrorCode = ?(CollectionObject <> Undefined, 67, 68);
	
	ElsIf CollectionObject <> Undefined Then
		
		ObjectForReceivingData = CollectionObject;
		
		If Not IsBlankString(PCR.Source) Then
			
			PropertyName = PCR.Source;
			ErrorCode = 16;
						
		Else
			
			PropertyName = PCR.Destination;
			ErrorCode = 17;
            							
		EndIf;
		
	ElsIf DataSelection <> Undefined Then
		
		ObjectForReceivingData = DataSelection;	
		
		If Not IsBlankString(PCR.Source) Then
		
			PropertyName = PCR.Source;
			ErrorCode = 13;
			
		Else
			
			Return;
			
		EndIf;
						
	Else
		
		ObjectForReceivingData = Source;
		
		If Not IsBlankString(PCR.Source) Then
		
			PropertyName = PCR.Source;
			ErrorCode = 13;
		
		Else
			
			PropertyName = PCR.Destination;
			ErrorCode = 14;
		
		EndIf;
			
	EndIf;
	
	
	Try
					
		Value = ObjectForReceivingData[PropertyName];
					
	Except
		
		If ErrorCode <> 14 Then
			WriteErrorInfoPCRHandlers(ErrorCode, ErrorDescription(), OCR, PCR, Source, "");
		EndIf;
																	
	EndTry;					
			
EndProcedure

Procedure ExportItemPropertyType(PropertyNode, PropertyType)
	
	SetAttribute(PropertyNode, "Type", PropertyType);	
	
EndProcedure

Procedure _ExportExtDimension(Source, Destination, IncomingData, OutgoingData, OCR, PCR, 
	PropertyCollectionNode = Undefined, CollectionObject = Undefined, Val ExportRefOnly = False)
	
	// Stubs to support debugging mechanism of event handler code.
    Var DestinationType, Empty, Expression, DontReplace, PropertiesOCR, PropertyNode;
	
	// Initializing the value
	Value = Undefined;
	OCRName = "";
	OCRNameExtDimensionType = "";
	
	// BeforeExport handler
	If PCR.HasBeforeExportHandler Then
		
		Cancel = False;
		
		Try
			
			ExportObject = Not ExportRefOnly;
			
			If ExportHandlersDebug Then
				
				Execute_PCR_HandlerBeforeExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
															   PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
															   OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, DontReplace,
															   ExportObject);
				
			Else
				
				Execute(PCR.BeforeExport);
				
			EndIf;
			
			ExportRefOnly = Not ExportObject;
			
		Except
			
			WriteErrorInfoPCRHandlers(55, ErrorDescription(), OCR, PCR, Source, 
				"BeforeExportProperty", Value);
			
		EndTry;
		
		If Cancel Then // Canceling the export
			
			Return;
			
		EndIf;
		
	EndIf;
	
	GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source);
	
	If PCR.CastToLength <> 0 Then
				
		CastValueToLength(Value, PCR);
						
	EndIf;
		
	For Each KeyAndValue In Value Do
		
		ExtDimensionType = KeyAndValue.Key;
		ExtDimensionDimension = KeyAndValue.Value;
		OCRName = "";
		
		// OnExport handler
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					Execute_PCR_HandlerOnExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																ExtDimensionDimension, Empty, OCRName, PropertiesOCR,PropertyNode, PropertyCollectionNode,
																OCRNameExtDimensionType, ExportObject);
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorDescription(), OCR, PCR, Source, 
					"OnExportProperty", Value);
				
			EndTry;
			
			If Cancel Then // Canceling extra dimension exporting
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		If ExtDimensionDimension = Undefined
			OR FindRule(ExtDimensionDimension, OCRName) = Undefined Then
			
			Continue;
			
		EndIf;
			
		ExtDimensionNode = CreateNode(PCR.Destination);
			
		// Key
		PropertyNode = CreateNode("Property");
			
		If OCRNameExtDimensionType = "" Then
				
			OCRKey = FindRule(ExtDimensionType);
				
		Else
				
			OCRKey = FindRule(, OCRNameExtDimensionType);
				
		EndIf;
			
		SetAttribute(PropertyNode, "Name", "Key");
		ExportItemPropertyType(PropertyNode, OCRKey.Destination);
		
		RefNode = ExportByRule(ExtDimensionType,, OutgoingData,, OCRNameExtDimensionType,, TRUE, OCRKey, , , , , False);
			
		If RefNode <> Undefined Then
				
			AddSubordinateNode(PropertyNode, RefNode);
				
		EndIf;
			
		AddSubordinateNode(ExtDimensionNode, PropertyNode);
		
		// Value
		PropertyNode = CreateNode("Property");
			
		OCRValue = FindRule(ExtDimensionDimension, OCRName);
		
		DestinationType = OCRValue.Destination;
		
		IsNULL = False;
		Empty = deEmpty(ExtDimensionDimension, IsNULL);
		
		If Empty Then
			
			If IsNULL 
				Or Value = Undefined Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(ExtDimensionDimension);
								
			EndIf;			
			
			SetAttribute(PropertyNode, "Name", "Value");
			
			If Not IsBlankString(DestinationType) Then
				SetAttribute(PropertyNode, "Type", DestinationType);
			EndIf;
							
			// If it is a variable of multiple type, it must be exported with the specified type, perhaps this is an empty reference.
			deWriteElement(PropertyNode, "Empty");
			AddSubordinateNode(ExtDimensionNode, PropertyNode);
			
		Else
			
			IsRuleWithGlobalExport = False;
			
			ExportRefOnly = True;
			If ExportObjectByRef(ExtDimensionDimension, NodeForExchange) Then
						
				If Not ObjectPassesAllowedObjectFilter(ExtDimensionDimension) Then
					
					// Setting the flag indicating that the object needs to be fully exported.
					ExportRefOnly = False;
					
					// Adding the record to the mapping register.
					RecordStructure = New Structure;
					RecordStructure.Insert("InfobaseNode", NodeForExchange);
					RecordStructure.Insert("SourceUUID", ExtDimensionDimension);
					RecordStructure.Insert("ObjectExportedByRef", True);
					
					InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure, True);
					
					// Adding the object to an array of objects unloaded by reference for registration of objects on the 
					// current node and to assign the number of the current sent exchange message.
					// 
					ExportedByRefObjectsAddValue(ExtDimensionDimension);
					
				EndIf;
				
			EndIf;
			
			RefNode = ExportByRule(ExtDimensionDimension,, OutgoingData, , OCRName, , ExportRefOnly, OCRValue, , , , , False, IsRuleWithGlobalExport);
			
			SetAttribute(PropertyNode, "Name", "Value");
			ExportItemPropertyType(PropertyNode, DestinationType);
						
				
			RefNodeType = TypeOf(RefNode);
				
			If RefNode = Undefined Then
					
				Continue;
					
			EndIf;
							
			AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport);
			
			AddSubordinateNode(ExtDimensionNode, PropertyNode);
			
		EndIf;
		
		// AfterExport handler
		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PCR_HandlerAfterExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																  ExtDimensionDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode,
																  RefNode, PropertyCollectionNode, ExtDimensionNode);
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(57, ErrorDescription(), OCR, PCR, Source, 
				"AfterExportProperty", Value);
				
			EndTry;
			
			If Cancel Then // Canceling the export
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		AddSubordinateNode(PropertyCollectionNode, ExtDimensionNode);
		
	EndDo;
	
EndProcedure

Procedure AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport)
	
	If RefNodeType = StringType Then
				
		If StrFind(RefNode, "<Ref") > 0 Then
					
			PropertyNode.WriteRaw(RefNode);
					
		Else
			
			deWriteElement(PropertyNode, "Value", RefNode);
					
		EndIf;
				
	ElsIf RefNodeType = NumberType Then
		
		If IsRuleWithGlobalExport Then
		
			deWriteElement(PropertyNode, "Gsn", RefNode);
			
		Else     		
			
			deWriteElement(PropertyNode, "Sn", RefNode);
			
		EndIf;
				
	Else
				
		AddSubordinateNode(PropertyNode, RefNode);
				
	EndIf;
	
EndProcedure

Procedure GetValueSettingPossibility(Value, ValueType, DestinationType, PropertySet, TypeRequired)
	
	PropertySet = True;
		
	If ValueType = StringType Then
				
		If DestinationType = "String"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf DestinationType = "Date"  Then
					
			Value = Date(Value);
					
		ElsIf DestinationType = "ValueStorage"  Then
					
			Value = New ValueStorage(Value);
					
		ElsIf DestinationType = "UUID" Then
					
			Value = New UUID(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "String";
			TypeRequired = True;
			
		EndIf;
								
	ElsIf ValueType = NumberType Then
				
		If DestinationType = "Number"
			OR DestinationType = "String" Then
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Number";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;
								
	ElsIf ValueType = DateType Then
				
		If DestinationType = "Date"  Then
		ElsIf DestinationType = "String"  Then
					
			Value = Left(String(Value), 10);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Date";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = BooleanType Then
				
		If DestinationType = "Boolean"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Boolean";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = ValueStorageType Then
				
		If IsBlankString(DestinationType) Then
					
			DestinationType = "ValueStorage";
			TypeRequired = True;
					
		ElsIf DestinationType <> "ValueStorage"  Then
					
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = UUIDType Then
				
		If DestinationType = "UUID" Then
		ElsIf DestinationType = "String" Then
			
			Value = String(Value);
			
		ElsIf IsBlankString(DestinationType) Then
			
			DestinationType = "UUID";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = AccumulationRecordTypeType Then
				
		Value = String(Value);		
		
	Else	
		
		PropertySet = False;
		
	EndIf;	
	
EndProcedure

Function GetDataTypeForDestination(Value)
	
	DestinationType = deValueTypeAsString(Value);
	
	// Checking for any OCR with the DestinationType destination type. If no rule is found, then "". If 
	// a rule is found, it is left.
	TableRow = ConversionRulesTable.Find(DestinationType, "Destination");
	
	If TableRow = Undefined Then
		
		If Not (DestinationType = "String"
			OR DestinationType = "Number"
			OR DestinationType = "Date"
			OR DestinationType = "Boolean"
			OR DestinationType = "ValueStorage") Then
			
			DestinationType = "";
		EndIf;
		
	EndIf;
	
	Return DestinationType;
	
EndFunction

Procedure CastValueToLength(Value, PCR)
	
	Value = CastNumberToLength(String(Value), PCR.CastToLength);
		
EndProcedure

Procedure WriteStructureToXML(DataStructure, PropertyCollectionNode, IsOrdinaryProperty = True)
	
	PropertyCollectionNode.WriteStartElement(?(IsOrdinaryProperty, "Property", "ParameterValue"));
	
	For Each CollectionItem In DataStructure Do
		
		If CollectionItem.Key = "Expression"
			OR CollectionItem.Key = "Value"
			OR CollectionItem.Key = "Sn"
			OR CollectionItem.Key = "Gsn" Then
			
			deWriteElement(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		ElsIf CollectionItem.Key = "Ref" Then
			
			PropertyCollectionNode.WriteRaw(CollectionItem.Value);
			
		Else
			
			SetAttribute(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		EndIf;
		
	EndDo;
	
	PropertyCollectionNode.WriteEndElement();		
	
EndProcedure

Procedure CreateComplexInformationForXMLWriter(DataStructure, PropertyNode, XMLNodeRequired, DestinationName, ParameterName)
	
	If IsBlankString(ParameterName) Then
		
		CreateObjectsForXMLWriter(DataStructure, PropertyNode, XMLNodeRequired, DestinationName, "Property");
		
	Else
		
		CreateObjectsForXMLWriter(DataStructure, PropertyNode, XMLNodeRequired, ParameterName, "ParameterValue");
		
	EndIf;
	
EndProcedure

Procedure CreateObjectsForXMLWriter(DataStructure, PropertyNode, XMLNodeRequired, NodeName, XMLNodeDescription = "Property")
	
	If XMLNodeRequired Then
		
		PropertyNode = CreateNode(XMLNodeDescription);
		SetAttribute(PropertyNode, "Name", NodeName);
		
	Else
		
		DataStructure = New Structure("Name", NodeName);
		
	EndIf;		
	
EndProcedure

Procedure AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		SetAttribute(PropertyNode, AttributeName, AttributeValue);
	EndIf;
	
EndProcedure

Procedure AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		deWriteElement(PropertyNode, AttributeName, AttributeValue);
	EndIf;
	
EndProcedure

Procedure AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		PropertyNode.WriteRaw(AttributeValue);
	EndIf;
	
EndProcedure

Procedure WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode, IsOrdinaryProperty = True)
	
	If PropertyNodeStructure <> Undefined Then
		WriteStructureToXML(PropertyNodeStructure, PropertyCollectionNode, IsOrdinaryProperty);
	Else
		AddSubordinateNode(PropertyCollectionNode, PropertyNode);
	EndIf;
	
EndProcedure

// Generates destination object property nodes according to the specified property conversion rule collection.
//
// Parameters:
//  Source		 - an arbitrary data source.
//  Destination		 - a destination object XML node.
//  IncomingData	 - arbitrary auxiliary data that is passed to the conversion rule.
//                         
//  OutgoingData - arbitrary auxiliary data that is passed to the property object conversion rules.
//                         
//  OCR				     - a reference to the object conversion rule (property conversion rule collection parent).
//  PCRCollection         - property conversion rule collection.
//  PropertyCollectionNode - property collection XML node.
//  CollectionObject - if this parameter is specified, collection object properties are exported, otherwise source object properties are exported.
//  PredefinedItemName - if this parameter is specified, the predefined item name is written to the properties.
// 
Procedure ExportProperties(Source, 
							Destination, 
							IncomingData, 
							OutgoingData, 
							OCR, 
							PCRCollection, 
							PropertyCollectionNode = Undefined, 
							CollectionObject = Undefined, 
							PredefinedItemName = Undefined, 
							Val OCRExportRefOnly = True, 
							Val IsRefExport = False, 
							Val ExportingObject = False, 
							RefSearchKey = "", 
							DontUseRulesWithGlobalExportAndDontRememberExported = False,
							RefValueInAnotherIB = "",
							TempFileList = Undefined, 
							ExportRegisterRecordSetRow = False,
							ObjectExportStack = Undefined)
							
	// Stubs to support debugging mechanism of event handler code.
	Var KeyAndValue, ExtDimensionType, ExtDimensionDimension, OCRNameExtDimensionType, ExtDimensionNode;

							
	If PropertyCollectionNode = Undefined Then
		
		PropertyCollectionNode = Destination;
		
	EndIf;
	
	PropertiesSelection = Undefined;
	
	If IsRefExport Then
				
		// Exporting the predefined item name if it is specified.
		If PredefinedItemName <> Undefined Then
			
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", "{PredefinedItemName}");
			deWriteElement(PropertyCollectionNode, "Value", PredefinedItemName);
			PropertyCollectionNode.WriteEndElement();
			
		EndIf;
		
	EndIf;
	
	For each PCR In PCRCollection Do
		
		ExportRefOnly = OCRExportRefOnly;
		
		If PCR.SimplifiedPropertyExport Then
			
			
			 //	Creating the property node
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", PCR.Destination);
			
			If Not IsBlankString(PCR.DestinationType) Then
				
				SetAttribute(PropertyCollectionNode, "Type", PCR.DestinationType);
				
			EndIf;
			
			If PCR.DoNotReplace Then
				
				SetAttribute(PropertyCollectionNode, "DoNotReplace",	"true");
				
			EndIf;
			
			If PCR.SearchByEqualDate  Then
				
				SetAttribute(PropertyCollectionNode, "SearchByEqualDate", "true");
				
			EndIf;
			
			Value = Undefined;
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, PropertiesSelection);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
			
			IsNULL = False;
			Empty = deEmpty(Value, IsNULL);
						
			If Empty Then
				
				PropertyCollectionNode.WriteEndElement();
				Continue;
				
			EndIf;
			
			deWriteElement(PropertyCollectionNode, 	"Value", Value);
			
			PropertyCollectionNode.WriteEndElement();
			Continue;					
					
		ElsIf PCR.DestinationKind = "AccountExtDimensionTypes" Then
			
			_ExportExtDimension(Source, Destination, IncomingData, OutgoingData, OCR, 
				PCR, PropertyCollectionNode, CollectionObject, ExportRefOnly);
			
			Continue;
			
		ElsIf PCR.Name = "{UUID}" Then
			
			RefToSource = GetRefByObjectOrRef(Source, ExportingObject);
			
			UUID = RefToSource.UUID();
			
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", "{UUID}");
			SetAttribute(PropertyCollectionNode, "Type", "String");
			SetAttribute(PropertyCollectionNode, "SourceType", OCR.SourceType);
			SetAttribute(PropertyCollectionNode, "DestinationType", OCR.DestinationType);
			deWriteElement(PropertyCollectionNode, "Value", UUID);
			PropertyCollectionNode.WriteEndElement();
			
			Continue;
			
		ElsIf PCR.IsFolder Then
			
			ExportPropertyGroup(
				Source, Destination, IncomingData, OutgoingData, OCR, PCR, PropertyCollectionNode, 
				ExportRefOnly, TempFileList, ExportRegisterRecordSetRow);
			
			Continue;
			
		EndIf;
		
		//	Initializing the value to be converted.
		Value 	 = Undefined;
		OCRName		 = PCR.ConversionRule;
		DontReplace   = PCR.DoNotReplace;
		
		Empty		 = False;
		Expression	 = Undefined;
		DestinationType = PCR.DestinationType;

		IsNULL      = False;
		
		// BeforeExport handler
		If PCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					Execute_PCR_HandlerBeforeExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																   PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
																   OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, DontReplace,
																   ExportObject);
					
				Else
					
					Execute(PCR.BeforeExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject;
				
			Except
				
				WriteErrorInfoPCRHandlers(55, ErrorDescription(), OCR, PCR, Source, 
						"BeforeExportProperty", Value);
														
			EndTry;
			
			If Cancel Then	//	Canceling property export
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		// Creating the property node
		PropertyNodeStructure = Undefined;
		PropertyNode = Undefined;
		
		CreateComplexInformationForXMLWriter(PropertyNodeStructure, PropertyNode, PCR.XMLNodeRequiredOnExport, PCR.Destination, PCR.ParameterForTransferName);
							
		If DontReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "DoNotReplace", "true");			
						
		EndIf;
		
		If PCR.SearchByEqualDate  Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "SearchByEqualDate", "true");
			
		EndIf;
		
		//	Perhaps, the conversion rule is already defined.
		If Not IsBlankString(OCRName) Then
			
			PropertiesOCR = Rules[OCRName];
			
		Else
			
			PropertiesOCR = Undefined;
			
		EndIf;
		
		If Not IsBlankString(DestinationType) Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "Type", DestinationType);
			
		ElsIf PropertiesOCR <> Undefined Then
			
			// Attempting to define a destination property type.
			DestinationType = PropertiesOCR.Destination;
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "Type", DestinationType);
			
		EndIf;
		
		If Not IsBlankString(OCRName)
			AND PropertiesOCR <> Undefined
			AND PropertiesOCR.HasSearchFieldSequenceHandler = True Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "OCRName", OCRName);
			
		EndIf;
		
		IsOrdinaryProperty = IsBlankString(PCR.ParameterForTransferName);
		
		//	Determining the value to be converted.
		If Expression <> Undefined Then
			
			AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, "Expression", Expression);
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode, IsOrdinaryProperty);
			Continue;
			
		ElsIf Empty Then
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode, IsOrdinaryProperty);
			Continue;
			
		Else
			
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, PropertiesSelection);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
						
		EndIf;

		OldValueBeforeOnExportHandler = Value;
		Empty = deEmpty(Value, IsNULL);
		
		// OnExport handler
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					Execute_PCR_HandlerOnExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																ExtDimensionDimension, Empty, OCRName, PropertiesOCR,PropertyNode, PropertyCollectionNode,
																OCRNameExtDimensionType, ExportObject);
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorDescription(), OCR, PCR, Source, 
						"OnExportProperty", Value);
														
			EndTry;
			
			If Cancel Then	//	Canceling property export
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		// Initializing the Empty variable one more time, perhaps its value has been changed in the OnExport 
		// handler.
		If OldValueBeforeOnExportHandler <> Value Then
			
			Empty = deEmpty(Value, IsNULL);
			
		EndIf;

		If Empty Then
			
			If IsNULL Then
				
				Value = Undefined;
				
			EndIf;
			
			If Value <> Undefined 
				AND IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(Value);
				
				If Not IsBlankString(DestinationType) Then
					
					AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "Type", DestinationType);
					
				EndIf;
								
			EndIf;			
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode, IsOrdinaryProperty);
			Continue;
			
		EndIf;
      		
		RefNode = Undefined;
		
		If PropertiesOCR = Undefined
			AND IsBlankString(OCRName) Then
			
			PropertySet = False;
			ValueType = TypeOf(Value);
			TypeRequired = False;
			GetValueSettingPossibility(Value, ValueType, DestinationType, PropertySet, TypeRequired);
						
			If PropertySet Then
				
				// specifying a type if necessary
				If TypeRequired Then
					
					AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "Type", DestinationType);
					
				EndIf;
				
				AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, "Value", Value);
								              				
			Else
				
				ValueManager = Managers[ValueType];
				
				If ValueManager = Undefined Then
					Continue;
				EndIf;
				
				PropertiesOCR = ValueManager.OCR;
				
				If PropertiesOCR = Undefined Then
					Continue;
				EndIf;
					
				OCRName = PropertiesOCR.Name;
				
			EndIf;
			
		EndIf;
		
		If (PropertiesOCR <> Undefined) 
			Or (Not IsBlankString(OCRName)) Then
			
			If ExportRefOnly Then
				
				If ExportObjectByRef(Value, NodeForExchange) Then
					
					If Not ObjectPassesAllowedObjectFilter(Value) Then
						
						// Setting the flag indicating that the object needs to be fully exported.
						ExportRefOnly = False;
						
						// Adding the record to the mapping register.
						RecordStructure = New Structure;
						RecordStructure.Insert("InfobaseNode", NodeForExchange);
						RecordStructure.Insert("SourceUUID", Value);
						RecordStructure.Insert("ObjectExportedByRef", True);
						
						InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure, True);
						
						// Adding the object to an array of objects unloaded by reference for registration of objects on the 
						// current node and to assign the number of the current sent exchange message.
						// 
						ExportedByRefObjectsAddValue(Value);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(ObjectExportStack) Then
				ExportStackBranch = Common.CopyRecursive(ObjectExportStack);
			Else
				ExportStackBranch = New Array;
			EndIf;
			
			RuleWithGlobalExport = False;
			RefNode = ExportByRule(Value, , OutgoingData, , OCRName, , ExportRefOnly, PropertiesOCR, , , , , False, 
				RuleWithGlobalExport, DontUseRulesWithGlobalExportAndDontRememberExported, ExportStackBranch);
	
			If RefNode = Undefined Then
						
				Continue;
						
			EndIf;
			
			If IsBlankString(DestinationType) Then
						
				DestinationType  = PropertiesOCR.Destination;
				AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, "Type", DestinationType);
														
			EndIf;			
				
			RefNodeType = TypeOf(RefNode);
						
			If RefNodeType = StringType Then
				
				If StrFind(RefNode, "<Ref") > 0 Then
								
					AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode, "Ref", RefNode);
											
				Else
					
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, "Value", RefNode);
																	
				EndIf;
						
			ElsIf RefNodeType = NumberType Then
				
				If RuleWithGlobalExport Then
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, "Gsn", RefNode);
				Else
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode, "Sn", RefNode);
				EndIf;
														
			Else
				
				RefNode.WriteEndElement();
				InformationToWriteToFile = RefNode.Close();
				
				AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode, "Ref", InformationToWriteToFile);
										
			EndIf;
													
		EndIf;
		
		
		
		// AfterExport handler
		
		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					Execute_PCR_HandlerAfterExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
																  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																  ExtDimensionDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode,
																  RefNode, PropertyCollectionNode, ExtDimensionNode);
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(57, ErrorDescription(), OCR, PCR, Source, 
						"AfterExportProperty", Value);
				
			EndTry;
			
			If Cancel Then	//	Canceling property export
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode, IsOrdinaryProperty);
		
	EndDo; // by PCR
	
EndProcedure

Procedure DetermineOCRByParameters(OCR, Source, OCRName)
	
	// Searching for OCR
	If OCR = Undefined Then
		
        OCR = FindRule(Source, OCRName);
		
	ElsIf (Not IsBlankString(OCRName))
		AND OCR.Name <> OCRName Then
		
		OCR = FindRule(Source, OCRName);
				
	EndIf;	
	
EndProcedure

Function FindPropertyStructureByParameters(OCR, Source)
	
	PropertyStructure = Managers[OCR.Source];
	If PropertyStructure = Undefined Then
		PropertyStructure = Managers[TypeOf(Source)];
	EndIf;	
	
	Return PropertyStructure;
	
EndFunction

Function GetRefByObjectOrRef(Source, ExportingObject)
	
	If ExportingObject Then
		Return Source.Ref;
	Else
		Return Source;
	EndIf;
	
EndFunction

Function DetermineInternalPresentationForSearch(Source, PropertyStructure)
	
	If PropertyStructure.TypeName = "Enum" Then
		Return Source;
	Else
		Return ValueToStringInternal(Source);
	EndIf
	
EndFunction

Procedure UpdateDataInDataToExport()
	
	If DataMapForExportedItemUpdate.Count() > 0 Then
		
		DataMapForExportedItemUpdate.Clear();
		
	EndIf;
	
EndProcedure

Procedure SetExportedToFileObjectFlags()
	
	WrittenToFileSn = SnCounter;
	
EndProcedure

Procedure WriteExchangeObjectPriority(ExchangeObjectsPriority, Node)
	
	If ValueIsFilled(ExchangeObjectsPriority)
		AND ExchangeObjectsPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
		
		If ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority Then
			SetAttribute(Node, "ExchangeObjectPriority", "Below");
		ElsIf ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch Then
			SetAttribute(Node, "ExchangeObjectPriority", "Matches");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExportChangeRecordedObjectData(RecordSetForExport)
	
	If RecordSetForExport.Count() = 0 Then // exporting an empty information register set
		
		Filter = New Structure;
		Filter.Insert("SourceUUID", RecordSetForExport.Filter.SourceUUID.Value);
		Filter.Insert("DestinationUUID", RecordSetForExport.Filter.DestinationUUID.Value);
		Filter.Insert("SourceType",                     RecordSetForExport.Filter.SourceType.Value);
		Filter.Insert("DestinationType",                     RecordSetForExport.Filter.DestinationType.Value);
		
		ExportInfobaseObjectsMapRecord(Filter, True);
		
	Else
		
		For Each SetRow In RecordSetForExport Do
			
			ExportInfobaseObjectsMapRecord(SetRow, False);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ExportInfobaseObjectsMapRecord(SetRow, BlankSet)
	
	Destination = CreateNode("ObjectRegistrationInformation");
	
	SetAttribute(Destination, "SourceUUID", String(SetRow.SourceUUID.UUID()));
	SetAttribute(Destination, "DestinationUUID",        SetRow.DestinationUUID);
	SetAttribute(Destination, "SourceType",                            SetRow.SourceType);
	SetAttribute(Destination, "DestinationType",                            SetRow.DestinationType);
	
	SetAttribute(Destination, "BlankSet", BlankSet);
	
	Destination.WriteEndElement(); // ObjectChangeRecordData
	
	WriteToFile(Destination);
	
EndProcedure

Procedure FireEventsBeforeExportObject(Object, Rule, Properties=Undefined, IncomingData=Undefined, 
	DontExportPropertyObjectsByRefs = False, OCRName, Cancel, OutgoingData)
	
	If CommentObjectProcessingFlag Then
		
		TypesDetails = New TypeDescription("String");
		RowObject  = TypesDetails.AdjustValue(Object);
		If RowObject = "" Then
			ObjectRul = RowObject + "  (" + TypeOf(Object) + ")";
		Else
			ObjectRul = TypeOf(Object);
		EndIf;
		
		EventName = NStr("ru = 'ВыгрузкаОбъекта: %1'; en = 'ExportObject: %1'; pl = 'ObjectExport: %1';de = 'ObjektExport: %1';ro = 'ExportObiect: %1';tr = 'NesneDışaAktarımı: %1'; es_ES = 'ObjectExport: %1'");
		EventName = StringFunctionsClientServer.SubstituteParametersToString(EventName, ObjectRul);
		
		WriteToExecutionProtocol(EventName, , False, 1, 7);
		
	EndIf;
	
	
	OCRName			= Rule.ConversionRule;
	Cancel			= False;
	OutgoingData	= Undefined;
	
	
	// BeforeExportObject global handler.
	If HasBeforeExportObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object);
				
			Else
				
				Execute(Conversion.BeforeExportObject);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(65, ErrorDescription(), Rule.Name, NStr("ru = 'ПередВыгрузкойОбъектаВыборки (глобальный)'; en = 'BeforeExportSelectionObject (global)'; pl = 'BeforeExportSelectionObject (globalny)';de = 'VorDemExportDesAuswahlobjekts (global)';ro = 'BeforeExportSelectionObject (global)';tr = 'SeçmeNesnesininDışaAktarılmadanÖnce (global)'; es_ES = 'BeforeExportSelectionObject (global)'"), Object);
		EndTry;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// BeforeExport handler
	If Not IsBlankString(Rule.BeforeExport) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_DER_BeforeExportObject(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object);
				
			Else
				
				Execute(Rule.BeforeExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(33, ErrorDescription(), Rule.Name, "BeforeExportSelectionObject", Object);
		EndTry;
		
	EndIf;		
	
EndProcedure

Procedure FireEventsAfterExportObject(Object, Rule, Properties=Undefined, IncomingData=Undefined, 
	DontExportPropertyObjectsByRefs = False, OCRName, Cancel, OutgoingData)
	
	Var RefNode; // Stub
	
	// AfterExportObject global handler.
	If HasAfterExportObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_AfterObjectExport(ExchangeFile, Object, OCRName, IncomingData, OutgoingData, RefNode);
				
			Else
				
				Execute(Conversion.AfterExportObject);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(69, ErrorDescription(), Rule.Name, NStr("ru = 'ПослеВыгрузкиОбъектаВыборки (глобальный)'; en = 'AfterExportSelectionObject (global)'; pl = 'AfterSelectionObjectExport (Globalny)';de = 'NachDemExportDesAuswahlobjekts (global)';ro = 'AfterSelectionObjectExport (Global)';tr = 'SeçmeNesnesininDışaAktarıldıktanSonra (Global)'; es_ES = 'AfterSelectionObjectExport (Global)'"), Object);
		EndTry;
	EndIf;
	
	// AfterExport handler
	If Not IsBlankString(Rule.AfterExport) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_DER_AfterExportObject(ExchangeFile, Object, OCRName, IncomingData, OutgoingData, RefNode, Rule);
				
			Else
				
				Execute(Rule.AfterExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(34, ErrorDescription(), Rule.Name, "AfterExportSelectionObject", Object);
		EndTry;
		
	EndIf;
	
EndProcedure

// Exports the selection object according to the specified rule.
//
// Parameters:
//  Object - selection object to be exported.
//  Rule - data export rule reference.
//  Properties - metadata object properties of the object to be exported.
//  IncomingData - arbitrary auxiliary data.
// 
Function ExportSelectionObject(Object, 
								ExportRule, 
								Properties=Undefined, 
								IncomingData = Undefined,
								DontExportPropertyObjectsByRefs = False, 
								ExportRecordSetRow = False, 
								ParentNode = Undefined, 
								ConstantNameForExport = "",
								OCRName = "",
								FireEvents = True)
								
	Cancel			= False;
	OutgoingData	= Undefined;
		
	If FireEvents
		AND ExportRule <> Undefined Then							

		OCRName			= "";		
		
		FireEventsBeforeExportObject(Object, ExportRule, Properties, IncomingData, 
			DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);
		
		If Cancel Then
			Return False;
		EndIf;
		
	EndIf;
	
	RefNode = Undefined;
	ExportByRule(Object, , IncomingData, OutgoingData, OCRName, RefNode, , , NOT DontExportPropertyObjectsByRefs, 
		ExportRecordSetRow, ParentNode, ConstantNameForExport, True);
		
		
	If FireEvents
		AND ExportRule <> Undefined Then
		
		FireEventsAfterExportObject(Object, ExportRule, Properties, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);	
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

Function SelectionForExportWithRestrictions(Rule)
	
	MetadataName           = Rule.ObjectForQueryName;
	
	PermissionRow = ?(ExportAllowedObjectsOnly, " ALLOWED ", "");
	
	ReportBuilder.Text = "SELECT " + PermissionRow + " Object.Ref AS Ref FROM " + MetadataName + " AS Object "+ "{WHERE Object.Ref.* AS " + StrReplace(MetadataName, ".", "_") + "}";
	ReportBuilder.Filter.Reset();
	If NOT Rule.BuilderSettings = Undefined Then
		ReportBuilder.SetSettings(Rule.BuilderSettings);
	EndIf;

	ReportBuilder.Execute();
	Selection = ReportBuilder.Result.Select();
		
	Return Selection;
		
EndFunction

Function SelectionToExportByArbitraryAlgorithm(DataSelection)
	
	Selection = Undefined;
	
	SelectionType = TypeOf(DataSelection);
			
	If SelectionType = Type("QueryResultSelection") Then
				
		Selection = DataSelection;
		
	ElsIf SelectionType = Type("QueryResult") Then
				
		Selection = DataSelection.Select();
					
	ElsIf SelectionType = Type("Query") Then
				
		QueryResult = DataSelection.Execute();
		Selection          = QueryResult.Select();
									
	EndIf;
		
	Return Selection;	
	
EndFunction

Function ConstantsSetStringForExport(ConstantDataTableForExport)
	
	ConstantSetString = "";
	
	For Each TableRow In ConstantDataTableForExport Do
		
		If Not IsBlankString(TableRow.Source) Then
		
			ConstantSetString = ConstantSetString + ", " + TableRow.Source;
			
		EndIf;	
		
	EndDo;	
	
	If Not IsBlankString(ConstantSetString) Then
		
		ConstantSetString = Mid(ConstantSetString, 3);
		
	EndIf;
	
	Return ConstantSetString;
	
EndFunction

Function ExportConstantsSet(Rule, Properties, OutgoingData, ConstantSetNameString = "")
	
	If ConstantSetNameString = "" Then
		ConstantSetNameString = ConstantsSetStringForExport(Properties.OCR.Properties);
	EndIf;
			
	ConstantsSet = Constants.CreateSet(ConstantSetNameString);
	ConstantsSet.Read();
	ExportResult = ExportSelectionObject(ConstantsSet, Rule, Properties, OutgoingData, , , , ConstantSetNameString);	
	Return ExportResult;
	
EndFunction

Function MustSelectAllFields(Rule)
	
	AllFieldsRequiredForSelection = NOT IsBlankString(Conversion.BeforeExportObject)
		OR NOT IsBlankString(Rule.BeforeExport)
		OR NOT IsBlankString(Conversion.AfterExportObject)
		OR NOT IsBlankString(Rule.AfterExport);		
		
	Return AllFieldsRequiredForSelection;	
	
EndFunction

Procedure ProcessObjectDeletion(ObjectDeletionData, ErrorMessageString = "")
	
	Ref = ObjectDeletionData.Ref;
	
	EventText = "";
	If Conversion.Property("BeforeSendDeletionInfo", EventText) Then
		
		If Not IsBlankString(EventText) Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecuteHandler_Conversion_BeforeSendDeletionInfo(Ref, Cancel);
					
				Else
					
					Execute(EventText);
					
				EndIf;
				
			Except
				ErrorMessageString = WriteErrorInfoConversionHandlers(76, ErrorDescription(), NStr("ru = 'ПередОтправкойИнформацииОбУдалении (конвертация)'; en = 'BeforeSendDeletionInfo (conversion)'; pl = 'BeforeSendingInformationAboutDeletion (konwertowanie)';de = 'VorDemSendenVonInformationenÜberDasLöschen (Konvertierung)';ro = 'ПередОтправкойИнформацииОбУдалении (conversie)';tr = 'SilmeBilgisininGönderilmedenÖnce (dönüştürme)'; es_ES = 'BeforeSendingInformationAboutDeletion (conversión)'"));
				
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Cancel = True;
			EndTry;
			
			If Cancel Then
				Return;
			EndIf;
			
		EndIf;
	EndIf;
	
	Manager = Managers[TypeOf(Ref)];
	
	// Checking whether the manager and OCR exist.
	If    Manager = Undefined
		OR Manager.OCR = Undefined Then
		
		WP = ExchangeProtocolRecord(45);
		
		WP.Object = Ref;
		WP.ObjectType = TypeOf(Ref);
		
		WriteToExecutionProtocol(45, WP, True);
		Return;
		
	EndIf;
	
	WriteToFileObjectDeletion(Ref, Manager.OCR.DestinationType, Manager.OCR.SourceType);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCompilingExchangeRulesInStructure

// returns the exchange rule structure.
Function ExchangeRules(Source) Export
	
	ImportExchangeRules(Source, "XMLFile");
	
	If ErrorFlag() Then
		Return Undefined;
	EndIf;
	
	If ExchangeMode = "Load" Then
		ObjectsRegistrationAttributesTable = Undefined;
	Else
		// Getting the table of registration attributes for the selective object registration mechanism.
		ObjectsRegistrationAttributesTable = ObjectsRegistrationAttributes();
	EndIf;
	
	// saving queries
	QueriesToSave = New Structure;
	
	For Each StructureItem In Queries Do
		
		QueriesToSave.Insert(StructureItem.Key, StructureItem.Value.Text);
		
	EndDo;
	
	// saving parameters
	ParametersToSave = New Structure;
	
	For Each StructureItem In Parameters Do
		
		ParametersToSave.Insert(StructureItem.Key, Undefined);
		
	EndDo;
	
	ExchangeRuleStructure = New Structure;
	
	ExchangeRuleStructure.Insert("RulesStorageFormatVersion", ExchangeRuleStorageFormatVersion());
	
	ExchangeRuleStructure.Insert("Conversion", Conversion);
	
	ExchangeRuleStructure.Insert("ParameterSetupTable", ParameterSetupTable);
	ExchangeRuleStructure.Insert("ExportRuleTable",      ExportRuleTable);
	ExchangeRuleStructure.Insert("ConversionRulesTable",   ConversionRulesTable);
	
	ExchangeRuleStructure.Insert("Algorithms", Algorithms);
	ExchangeRuleStructure.Insert("Parameters", ParametersToSave);
	ExchangeRuleStructure.Insert("Queries",   QueriesToSave);
	
	ExchangeRuleStructure.Insert("XMLRules",              XMLRules);
	ExchangeRuleStructure.Insert("TypesForDestinationString", TypesForDestinationString);
	
	ExchangeRuleStructure.Insert("SelectiveObjectsRegistrationRules", ObjectsRegistrationAttributesTable);
	
	Return ExchangeRuleStructure;
	
EndFunction

Function ObjectsRegistrationAttributes()
	
	RegistrationAttributesTable = InitChangeRecordAttributeTable();
	ResultTable             = InitChangeRecordAttributeTable();
	
	// Getting the preliminary table from conversion rules.
	For Each OCR In ConversionRulesTable Do
		
		FillObjectChangeRecordAttributeTableDetailsByRule(OCR, ResultTable);
		
	EndDo;
	
	ResultTableGroup = ResultTable.Copy();
	
	ResultTableGroup.GroupBy("ObjectName, TabularSectionName");
	
	// Getting the resulting table taking into account grouped rows of the preliminary table.
	For Each TableRow In ResultTableGroup Do
		
		Filter = New Structure("ObjectName, TabularSectionName", TableRow.ObjectName, TableRow.TabularSectionName);
		
		ResultTableRowArray = ResultTable.FindRows(Filter);
		
		SupplementChangeRecordAttributeTable(ResultTableRowArray, RegistrationAttributesTable);
		
	EndDo;
	
	// deleting rows with errors
	DeleteChangeRecordAttributeTableRowsWithErrors(RegistrationAttributesTable);
	
	// Checking whether the required title attributes and metadata objects tabular sections are exist.
	CheckObjectChangeRecordAttributes(RegistrationAttributesTable);
	
	// Filling in the table with value of the Exchange plan name.
	RegistrationAttributesTable.FillValues(ExchangePlanNameSOR, "ExchangePlanName");
	
	Return RegistrationAttributesTable;
	
EndFunction

Function InitChangeRecordAttributeTable()
	
	ResultTable = New ValueTable;
	
	ResultTable.Columns.Add("Order",                        deTypeDetails("Number"));
	ResultTable.Columns.Add("ObjectName",                     deTypeDetails("String"));
	ResultTable.Columns.Add("ObjectTypeString",              deTypeDetails("String"));
	ResultTable.Columns.Add("ExchangePlanName",                 deTypeDetails("String"));
	ResultTable.Columns.Add("TabularSectionName",              deTypeDetails("String"));
	ResultTable.Columns.Add("RegistrationAttributes",           deTypeDetails("String"));
	ResultTable.Columns.Add("RegistrationAttributesStructure", deTypeDetails("Structure"));
	
	Return ResultTable;
	
EndFunction

Function PropertiesRegistrationAttributes(PCRTable)
	
	RegistrationAttributesStructure = New Structure;
	
	PCRRowsArray = PCRTable.FindRows(New Structure("IsFolder", False));
	
	For Each PCR In PCRRowsArray Do
		
		// Checking for invalid characters in the row.
		If IsBlankString(PCR.Source)
			OR Left(PCR.Source, 1) = "{" Then
			
			Continue;
		EndIf;
		
		Try
			RegistrationAttributesStructure.Insert(PCR.Source);
		Except
			WriteLogEvent(NStr("ru = 'Обмен данными.Загрузка правил конвертации'; en = 'Data exchange.Import conversion rules'; pl = 'Wymiana danych.Import reguł konwersji';de = 'Datenaustausch.Konvertierungsregelimport';ro = 'Schimb de date.Import de reguli de conversie';tr = 'Veri değişimi. Dönüştürme kuralı içe aktarma'; es_ES = 'Intercambio de datos.Importación de la regla de conversión'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	Return RegistrationAttributesStructure;
	
EndFunction

Function REgistrationAttributesByRowsArray(RowsArray)
	
	ResultingStructure = New Structure;
	
	For Each TableRowResult In RowsArray Do
		
		RegistrationAttributesStructure = TableRowResult.RegistrationAttributesStructure;
		
		For Each RegistrationAttribute In RegistrationAttributesStructure Do
			
			ResultingStructure.Insert(RegistrationAttribute.Key);
			
		EndDo;
		
	EndDo;
	
	Return ResultingStructure;
	
EndFunction

Function RegistrationAttributes(RegistrationAttributesStructure)
	
	RegistrationAttributes = "";
	
	For Each RegistrationAttribute In RegistrationAttributesStructure Do
		
		RegistrationAttributes = RegistrationAttributes + RegistrationAttribute.Key + ", ";
		
	EndDo;
	
	StringFunctionsClientServer.DeleteLastCharInString(RegistrationAttributes, 2);
	
	Return RegistrationAttributes;
	
EndFunction

Procedure CheckObjectChangeRecordAttributes(RegistrationAttributesTable)
	
	For Each TableRow In RegistrationAttributesTable Do
		
		Try
			ObjectType = Type(TableRow.ObjectTypeString);
		Except
			
			MessageString = NStr("ru = 'Тип объекта не определен: %1'; en = 'Undefined object type: %1'; pl = 'Nie określono typu obiektu: %1';de = 'Objekttyp ist nicht definiert: %1';ro = 'Tipul de obiect este nedefinit: %1';tr = 'Nesne türü belirlenmemiş: %1'; es_ES = 'Tipo de objeto es indefinido: %1'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, TableRow.ObjectTypeString);
			WriteToExecutionProtocol(MessageString);
			Continue;
			
		EndTry;
		
		MetadataObject = Metadata.FindByType(ObjectType);
		
		// Checking reference types only.
		If NOT Common.IsRefTypeObject(MetadataObject) Then
			Continue;
		EndIf;
		
		CommonAttributeTable = CommonAttributeTable();
		FillCommonAttributeTable(CommonAttributeTable);
		
		If IsBlankString(TableRow.TabularSectionName) Then // header attributes
			
			For Each Attribute In TableRow.RegistrationAttributesStructure Do
				
				If Common.IsTask(MetadataObject) Then
					
					If NOT (MetadataObject.Attributes.Find(Attribute.Key) <> Undefined
						OR  MetadataObject.AddressingAttributes.Find(Attribute.Key) <> Undefined
						OR  DataExchangeServer.IsStandardAttribute(MetadataObject.StandardAttributes, Attribute.Key)
						OR  IsCommonAttribute(Attribute.Key, MetadataObject.FullName(), CommonAttributeTable)) Then
						
						MessageString = NStr("ru = 'Неправильно указаны реквизиты шапки объекта ""%1"". Реквизит ""%2"" не существует.'; en = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.'; pl = 'Atrybuty nagłówka obiektu ""%1"" są niepoprawnie określone. Atrybut ""%2"" nie istnieje.';de = 'Attribute der ""%1"" -Objektkopfzeile sind falsch angegeben. Attribut ""%2"" existiert nicht.';ro = 'Atributele antetului obiect ""%1"" sunt specificate incorect. Atributul ""%2"" nu există.';tr = '""%1"" nesne başlığının öznitelikleri yanlış belirtildi. Öznitelik ""%2"" mevcut değil.'; es_ES = 'Atributos del manipulador de objetos ""%1"" están especificados de forma incorrecta. El atributo ""%2"" no existe.'");
						MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(MetadataObject), Attribute.Key);
						WriteToExecutionProtocol(MessageString);
						
					EndIf;
					
				Else
					
					If NOT (MetadataObject.Attributes.Find(Attribute.Key) <> Undefined
						OR  DataExchangeServer.IsStandardAttribute(MetadataObject.StandardAttributes, Attribute.Key)
						OR  IsCommonAttribute(Attribute.Key, MetadataObject.FullName(), CommonAttributeTable)) Then
						
						MessageString = NStr("ru = 'Неправильно указаны реквизиты шапки объекта ""%1"". Реквизит ""%2"" не существует.'; en = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.'; pl = 'Atrybuty nagłówka obiektu ""%1"" są niepoprawnie określone. Atrybut ""%2"" nie istnieje.';de = 'Attribute der ""%1"" -Objektkopfzeile sind falsch angegeben. Attribut ""%2"" existiert nicht.';ro = 'Atributele antetului obiect ""%1"" sunt specificate incorect. Atributul ""%2"" nu există.';tr = '""%1"" nesne başlığının öznitelikleri yanlış belirtildi. Öznitelik ""%2"" mevcut değil.'; es_ES = 'Atributos del manipulador de objetos ""%1"" están especificados de forma incorrecta. El atributo ""%2"" no existe.'");
						MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(MetadataObject), Attribute.Key);
						WriteToExecutionProtocol(MessageString);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		Else
			// Tabular section, standard tabular section, records.
			MetaTable  = MetaTabularSectionOfObjectRegistrationAttributes(MetadataObject, TableRow.TabularSectionName);
			If MetaTable = Undefined Then
				WriteToExecutionProtocol(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Табличная часть (стандартная табличная часть, движения) ""%1"" объекта ""%2"" не существует.'; en = 'The ""%1"" tabular section (or a standard tabular section, or a list of register records) of the ""%2"" object does not exist.'; pl = 'Sekcja tabelaryczna (standardowa sekcja tabelaryczna, ruch) %1 obiektu %2 nie istnieje.';de = 'Tabellarischer Abschnitt (Standardtabellenabschnitt, Bewegungen) %1 des Objekts %2 existiert nicht.';ro = 'Secțiunea tabelară (secțiunea tabelară standard, mișcări) %1 a obiectului %2 nu există.';tr = '%1 nesnenin %2 sekme bölümü (standart sekme bölümü, hareketler) mevcut değil.'; es_ES = 'Sección tabular (sección tabular estándar, movimientos) %1 del objeto %2 no existe.'"),
					TableRow.TabularSectionName, MetadataObject));
				Continue;
			EndIf;
			
			// Trying to find every attribute somewhere.
			For Each Attribute In TableRow.RegistrationAttributesStructure Do
				
				If Not AttributeIsFoundInTabularSectionOfObjectRegistrationAttributes(MetaTable, Attribute.Key) Then
					WriteToExecutionProtocol(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Реквизит ""%3"" не существует в табличной части (стандартной табличной части, движениях) ""%1"" объекта ""%2"".'; en = 'The ""%3"" attribute is not found in the tabular section (or a standard tabular section, or a list of register records) ""%1"" of the ""%2"" object.'; pl = 'Atrybut ""%3"" nie istnieje w sekcji tabelarycznej (standardowej sekcji tabelarycznej, ruchu) ""%1"" obiektu ""%2"".';de = 'Das Attribut ""%3"" existiert im Tabellenabschnitt (Standardtabellenabschnitt, Bewegung) ""%1"" des Objekts ""%2"" nicht.';ro = 'Atributul ""%3"" nu există în secțiunea tabelă (secțiunea tabelară standard, mișcare) ""%1"" a obiectului ""%2"".';tr = '""%3"" nesnenin ""%1"" tablo bölümünde (standart tablo bölümü, hareket) atribüt ""%2"" mevcut değil.'; es_ES = 'El atributo ""%3"" no existe en la sección tabular (sección de la tabla estándar, moción) ""%1"" del objeto ""%2"".'"),
						TableRow.TabularSectionName, MetadataObject, Attribute.Key));
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
EndProcedure

Function MetaTabularSectionOfObjectRegistrationAttributes(CurrentObjetMetadata, RequiredTabularSectionName)
	
	MetaTest = New Structure("TabularSections, StandardTabularSections, RegisterRecords");
	FillPropertyValues(MetaTest, CurrentObjetMetadata);
	
	CandidateName = Upper(RequiredTabularSectionName);
	
	For Each KeyValue In MetaTest Do
		TableMetaCollection = KeyValue.Value;
		If TableMetaCollection <> Undefined Then
			
			For Each MetaTable In TableMetaCollection Do
				If Upper(MetaTable.Name) = CandidateName Then
					Return MetaTable;
				EndIf;
			EndDo;
			
		EndIf;
	EndDo;

	Return Undefined;
EndFunction

Function AttributeIsFoundInTabularSectionOfObjectRegistrationAttributes(TabularSectionMetadata, NameOfSoughtAttribute)
	
	MetaTest = New Structure("Attributes, StandardAttributes, Dimensions, Resources");
	FillPropertyValues(MetaTest, TabularSectionMetadata);
			
	CandidateName = Upper(NameOfSoughtAttribute);
	
	For Each KeyValue In MetaTest Do
		MetaCollectionOfAttribuutes = KeyValue.Value;
		If MetaCollectionOfAttribuutes <> Undefined Then
			
			For Each MetaAttribute In MetaCollectionOfAttribuutes Do
				If Upper(MetaAttribute.Name) = CandidateName Then
					Return True;
				EndIf;
			EndDo;
			
		EndIf;
	EndDo;
	
	Return False;
EndFunction

Procedure FillObjectChangeRecordAttributeTableDetailsByRule(OCR, ResultTable)
	
	ObjectName        = StrReplace(OCR.SourceType, "Ref", "");
	ObjectTypeString = OCR.SourceType;
	
	// Filling in the table with the header attributes (properties).
	FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, "", -50, OCR.Properties, ResultTable);
	
	// Filling in the table with the header attributes (search properties).
	FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, "", -50, OCR.SearchProperties, ResultTable);
	
	// Filling in the table with the header attributes (disabled properties).
	FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, "", -50, OCR.DisabledProperties, ResultTable);
	
	// rule tabular sections
	PGCRArray = OCR.Properties.FindRows(New Structure("IsFolder", True));
	
	For Each PGCR In PGCRArray Do
		
		// Filling in the table with the tabular section attributes.
		FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.GroupRules, ResultTable);
		
		// Filling in the table with the tabular section attributes (disabled).
		FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.DisabledGroupRules, ResultTable);
		
	EndDo;
	
	// Rule tabular sections (disabled).
	PGCRArray = OCR.DisabledProperties.FindRows(New Structure("IsFolder", True));
	
	For Each PGCR In PGCRArray Do
		
		// Filling in the table with the tabular section attributes.
		FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.GroupRules, ResultTable);
		
		// Filling in the table with the tabular section attributes (disabled).
		FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.DisabledGroupRules, ResultTable);
		
	EndDo;
	
EndProcedure

Procedure FillObjectChangeRecordAttributeTableByTable(ObjectTypeString, ObjectName, TabularSectionName, Order, PropertiesTable, ResultTable)
	
	TableRowResult = ResultTable.Add();
	
	TableRowResult.Order                        = Order;
	TableRowResult.ObjectName                     = ObjectName;
	TableRowResult.ObjectTypeString              = ObjectTypeString;
	TableRowResult.TabularSectionName              = TabularSectionName;
	TableRowResult.RegistrationAttributesStructure = PropertiesRegistrationAttributes(PropertiesTable);
	
EndProcedure

Procedure SupplementChangeRecordAttributeTable(RowsArray, RegistrationAttributesTable)
	
	TableRow = RegistrationAttributesTable.Add();
	
	TableRow.Order                        = RowsArray[0].Order;
	TableRow.ObjectName                     = RowsArray[0].ObjectName;
	TableRow.ObjectTypeString              = RowsArray[0].ObjectTypeString;
	TableRow.TabularSectionName              = RowsArray[0].TabularSectionName;
	TableRow.RegistrationAttributesStructure = REgistrationAttributesByRowsArray(RowsArray);
	TableRow.RegistrationAttributes           = RegistrationAttributes(TableRow.RegistrationAttributesStructure);
	
EndProcedure

Procedure DeleteChangeRecordAttributeTableRowsWithErrors(RegistrationAttributesTable)
	
	CollectionItemCount = RegistrationAttributesTable.Count();
	
	For ReverseIndex = 1 To CollectionItemCount Do
		
		TableRow = RegistrationAttributesTable[CollectionItemCount - ReverseIndex];
		
		// If there are no registration attributes, deleting the row.
		If IsBlankString(TableRow.RegistrationAttributes) Then
			
			RegistrationAttributesTable.Delete(TableRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns flag that shows attribute is common one.
//
Function IsCommonAttribute(CommonAttribute, MDOName, CommonAttributeTable)
	
	SearchParameters = New Structure("CommonAttribute, MetadataObject", CommonAttribute, MDOName);
	FoundValues = CommonAttributeTable.FindRows(SearchParameters);
	
	If FoundValues.Count() > 0 Then
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Function CommonAttributeTable()
	
	CommonAttributeTable = New ValueTable;
	CommonAttributeTable.Columns.Add("CommonAttribute");
	CommonAttributeTable.Columns.Add("MetadataObject");
	
	CommonAttributeTable.Indexes.Add("CommonAttribute, MetadataObject");
	
	Return CommonAttributeTable;
	
EndFunction

Procedure FillCommonAttributeTable(CommonAttributeTable)
	
	If Metadata.CommonAttributes.Count() <> 0 Then
		
		CommonAttributeAutoUsage = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		CommonAttributeUsage = Metadata.ObjectProperties.CommonAttributeUse.Use;
		
		For Each CommonAttribute In Metadata.CommonAttributes Do
			
			If CommonAttribute.DataSeparationUse = Undefined Then
				
				AutoUse = (CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
				
				For Each Item In CommonAttribute.Content Do
					
					If Item.Use = CommonAttributeUsage
						Or (Item.Use = CommonAttributeAutoUsage AND AutoUse) Then
						
						NewRow = CommonAttributeTable.Add();
						NewRow.CommonAttribute = CommonAttribute.Name;
						NewRow.MetadataObject = Item.Metadata.FullName();
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InitializingExchangeRulesTables

// Initializes table columns of object property conversion rules.
//
// Parameters:
//  Tab            - ValueTable. a table of object property conversion rules to be initialized.
// 
Procedure InitPropertyConversionRuleTable(Tab)

	Columns = Tab.Columns;

	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("IsFolder",     deTypeDetails("Boolean"));
	Columns.Add("IsSearchField", deTypeDetails("Boolean"));
	Columns.Add("GroupRules");
	Columns.Add("DisabledGroupRules");

	Columns.Add("SourceKind");
	Columns.Add("DestinationKind");
	
	Columns.Add("SimplifiedPropertyExport", deTypeDetails("Boolean"));
	Columns.Add("XMLNodeRequiredOnExport", deTypeDetails("Boolean"));
	Columns.Add("XMLNodeRequiredOnExportGroup", deTypeDetails("Boolean"));

	Columns.Add("SourceType", deTypeDetails("String"));
	Columns.Add("DestinationType", deTypeDetails("String"));
		
	Columns.Add("Source");
	Columns.Add("Destination");

	Columns.Add("ConversionRule");

	Columns.Add("GetFromIncomingData", deTypeDetails("Boolean"));
	
	Columns.Add("DoNotReplace",              deTypeDetails("Boolean"));
	Columns.Add("IsRequiredProperty", deTypeDetails("Boolean"));
	
	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	Columns.Add("OnExport");
	Columns.Add("OnExportHandlerName");
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");

	Columns.Add("BeforeProcessExport");
	Columns.Add("BeforeExportProcessHandlerName");
	Columns.Add("AfterProcessExport");
	Columns.Add("AfterExportProcessHandlerName");

	Columns.Add("HasBeforeExportHandler",			deTypeDetails("Boolean"));
	Columns.Add("HasOnExportHandler",				deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportHandler",				deTypeDetails("Boolean"));
	
	Columns.Add("HasBeforeProcessExportHandler",	deTypeDetails("Boolean"));
	Columns.Add("HasAfterProcessExportHandler",	deTypeDetails("Boolean"));
	
	Columns.Add("CastToLength",							deTypeDetails("Number"));
	Columns.Add("ParameterForTransferName", 				deTypeDetails("String"));
	Columns.Add("SearchByEqualDate",					deTypeDetails("Boolean"));
	Columns.Add("ExportGroupToFile",				deTypeDetails("Boolean"));
	
	Columns.Add("SearchFieldsString");
	
EndProcedure

Function CreateExportedObjectTable()
	
	Table = New ValueTable();
	Table.Columns.Add("Key");
	Table.Columns.Add("RefNode");
	Table.Columns.Add("OnlyRefExported",    New TypeDescription("Boolean"));
	Table.Columns.Add("RefSN",                New TypeDescription("Number"));
	Table.Columns.Add("CallCount",      New TypeDescription("Number"));
	Table.Columns.Add("LastCallNumber", New TypeDescription("Number"));
	
	Table.Indexes.Add("Key");
	
	Return Table;
	
EndFunction

// Initializes table columns of object conversion rules.
//
// Parameters:
//  No.
// 
Procedure InitConversionRuleTable()

	Columns = ConversionRulesTable.Columns;
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("SynchronizeByID",                        deTypeDetails("Boolean"));
	Columns.Add("DoNotCreateIfNotFound",                                 deTypeDetails("Boolean"));
	Columns.Add("DoNotExportPropertyObjectsByRefs",                      deTypeDetails("Boolean"));
	Columns.Add("SearchBySearchFieldsIfNotFoundByID", deTypeDetails("Boolean"));
	Columns.Add("OnMoveObjectByRefSetGIUDOnly",       deTypeDetails("Boolean"));
	Columns.Add("DoNotReplaceObjectCreatedInDestinationInfobase",   deTypeDetails("Boolean"));
	Columns.Add("UseQuickSearchOnImport",                     deTypeDetails("Boolean"));
	Columns.Add("GenerateNewNumberOrCodeIfNotSet",                deTypeDetails("Boolean"));
	Columns.Add("TinyObjectCount",                             deTypeDetails("Boolean"));
	Columns.Add("RefExportReferenceCount",                    deTypeDetails("Number"));
	Columns.Add("IBItemsCount",                                  deTypeDetails("Number"));
		
	Columns.Add("ExportMethod");

	Columns.Add("Source");
	Columns.Add("Destination");
	
	Columns.Add("SourceType",  deTypeDetails("String"));
	Columns.Add("DestinationType",  deTypeDetails("String"));
	
	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	
	Columns.Add("OnExport");
	Columns.Add("OnExportHandlerName");
	
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");
	
	Columns.Add("AfterExportToFile");
	Columns.Add("AfterExportToFileHandlerName");

	Columns.Add("HasBeforeExportHandler",	deTypeDetails("Boolean"));
	Columns.Add("HasOnExportHandler",		deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportHandler",		deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportToFileHandler",deTypeDetails("Boolean"));

	Columns.Add("BeforeImport");
	Columns.Add("BeforeImportHandlerName");
	
	Columns.Add("OnImport");
	Columns.Add("OnImportHandlerName");
	
	Columns.Add("AfterImport");
	Columns.Add("AfterImportHandlerName");
	
	Columns.Add("SearchFieldSequence");
	Columns.Add("SearchFieldSequenceHandlerName");

	Columns.Add("SearchInTabularSections");
	
	Columns.Add("ExchangeObjectsPriority");
	
	Columns.Add("HasBeforeImportHandler", deTypeDetails("Boolean"));
	Columns.Add("HasOnImportHandler",    deTypeDetails("Boolean"));
	Columns.Add("HasAfterImportHandler",  deTypeDetails("Boolean"));
	
	Columns.Add("HasSearchFieldSequenceHandler",  deTypeDetails("Boolean"));

	Columns.Add("Properties",            deTypeDetails("ValueTable"));
	Columns.Add("SearchProperties",      deTypeDetails("ValueTable"));
	Columns.Add("DisabledProperties", deTypeDetails("ValueTable"));
	
	// Property Value not used for the Columns.
	// Columns.Add("Values", deTypeDetails("Map"));
	
	// Map.
	// Key - a predefined item value in this base.
	// Value - a string presentation of a predefined value in the destination.
	Columns.Add("PredefinedDataValues", deTypeDetails("Map"));
	
	// Structure.
	// Key - string presentation of a predefined value in this infobase.
	// Value - a string presentation of a predefined value in the destination.
	Columns.Add("PredefinedDataReadValues", deTypeDetails("Structure"));
	
	Columns.Add("Exported",							deTypeDetails("ValueTable"));
	Columns.Add("ExportSourcePresentation",		deTypeDetails("Boolean"));
	
	Columns.Add("DoNotReplace",					deTypeDetails("Boolean"));
	
	Columns.Add("RememberExported",       deTypeDetails("Boolean"));
	Columns.Add("AllObjectsExported",         deTypeDetails("Boolean"));
	
	Columns.Add("SearchFields",  deTypeDetails("String"));
	Columns.Add("TableFields", deTypeDetails("String"));
	
EndProcedure

// Initializes table columns of data export rules.
//
// Parameters:
//  No
// 
Procedure InitExportRuleTable()

	Columns = ExportRuleTable.Columns;

	Columns.Add("Enable", deTypeDetails("Boolean"));
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("DataFilterMethod");
	Columns.Add("SelectionObject");
	Columns.Add("SelectionObjectMetadata");
	
	Columns.Add("ConversionRule");

	Columns.Add("BeforeProcess");
	Columns.Add("BeforeProcessHandlerName");
	Columns.Add("AfterProcess");
	Columns.Add("AfterProcessHandlerName");

	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");
	
	// Columns for filtering using the query builder.
	Columns.Add("UseFilter", deTypeDetails("Boolean"));
	Columns.Add("BuilderSettings");
	Columns.Add("ObjectForQueryName");
	Columns.Add("ObjectNameForRegisterQuery");
	Columns.Add("DestinationTypeName");
	
	Columns.Add("DoNotExportObjectsCreatedInDestinationInfobase", deTypeDetails("Boolean"));
	
	Columns.Add("ExchangeNodeRef");
	
	Columns.Add("SynchronizeByID", deTypeDetails("Boolean"));
	
EndProcedure

// Initializes table columns of data clearing rules.
//
// Parameters:
//  No.
// 
Procedure CleaningRuleTableInitialization()

	Columns = CleanupRulesTable.Columns;

	Columns.Add("Enable",		deTypeDetails("Boolean"));
	Columns.Add("IsFolder",		deTypeDetails("Boolean"));
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order",	deTypeDetails("Number"));

	Columns.Add("DataFilterMethod");
	Columns.Add("SelectionObject");
	
	Columns.Add("DeleteForPeriod");
	Columns.Add("Directly",	deTypeDetails("Boolean"));

	Columns.Add("BeforeProcess");
	Columns.Add("BeforeProcessHandlerName");
	Columns.Add("AfterProcess");
	Columns.Add("AfterProcessHandlerName");
	Columns.Add("BeforeDelete");
	Columns.Add("BeforeDeleteHandlerName");

EndProcedure

// Initializes table columns of parameter setup table.
//
// Parameters:
//  No.
// 
Procedure ParametersSetupTableInitialization()

	Columns = ParameterSetupTable.Columns;

	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Value");
	Columns.Add("PassParameterOnExport");
	Columns.Add("ConversionRule");

EndProcedure

#EndRegion

#Region InitAttributesAndModuleVariables

Function InitExchangeMessageDataTable(ObjectType)
	
	ExchangeMessageDataTable = New ValueTable;
	
	Columns = ExchangeMessageDataTable.Columns;
	
	// required fields
	Columns.Add(UUIDColumnName(), String36Type);
	Columns.Add(ColumnNameTypeAsString(),              String255Type);
	
	MetadataObject = Metadata.FindByType(ObjectType);
	
	// Getting a description of all metadata object fields from the configuration.
	ObjectPropertiesDescriptionTable = Common.ObjectPropertiesDetails(MetadataObject, "Name, Type");
	
	For Each PropertyDetails In ObjectPropertiesDescriptionTable Do
		ColumnTypes = New TypeDescription(PropertyDetails.Type, "NULL");
		Columns.Add(PropertyDetails.Name, ColumnTypes);
	EndDo;
	
	ExchangeMessageDataTable.Indexes.Add(UUIDColumnName());
	
	Return ExchangeMessageDataTable;
	
EndFunction

Function InitializeDataProcessors()
	
	If ExportHandlersDebug Or ImportHandlersDebug Then 
		Raise
			NStr("ru = 'Внешняя обработка отладки, загружаемая из файла на диске, не поддерживается.'; en = 'The external data processor for debugging loaded from a file is not supported.'; pl = 'Внешняя обработка отладки, загружаемая из файла на диске, не поддерживается.';de = 'Externe Debug-Verarbeitung, die aus der Datei auf der Festplatte geladen wird, wird nicht unterstützt.';ro = 'Procesarea externă de depanare încărcată din fișier pe disc nu este susținută.';tr = 'Diskteki bir dosyadan yüklenen harici hata ayıklama işlemi desteklenmez.'; es_ES = 'Procesamiento externo de depuración, descargado del archivo en el disco, no se admite.'");
	EndIf;
	
	ExchangePlanName = ExchangePlanName();
	SecurityProfileName = DataExchangeCached.SecurityProfileName(ExchangePlanName);
	Return SecurityProfileName;
	
EndFunction

// Disables the attached debug processing with handler code.
//
Procedure DisableDataProcessorForDebug()
	
	If ExportProcessing <> Undefined Then
		
		Try
			ExportProcessing.DisableDataProcessorForDebug();
		Except
			WriteLogEvent(NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		ExportProcessing = Undefined;
		
	ElsIf ImportProcessing <> Undefined Then
		
		Try
			ImportProcessing.DisableDataProcessorForDebug();
		Except
			WriteLogEvent(NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		ImportProcessing = Undefined;
		
	EndIf;
	
EndProcedure

// Initializes the ErrorMessages variable that contains mapping of message codes and their description.
//
// Parameters:
//  No.
// 
Procedure InitMessages()

	ErrorMessages			= New Map;
		
	ErrorMessages.Insert(2,  NStr("ru = 'Ошибка распаковки файла обмена. Файл заблокирован.'; en = 'Cannot unpack the exchange file. The file is locked.'; pl = 'Wystąpił błąd podczas rozpakowywania pliku wymiany. Plik jest zablokowany.';de = 'Beim Entpacken einer Austausch-Datei ist ein Fehler aufgetreten. Die Datei ist gesperrt.';ro = 'A apărut o eroare la dezarhivarea unui fișier de schimb. Fișierul este blocat.';tr = 'Bir değişim dosyasını paketinden çıkarılırken bir hata oluştu. Dosya kilitli.'; es_ES = 'Ha ocurrido un error al desembalar un archivo de intercambio. El archivo está bloqueado.'"));
	ErrorMessages.Insert(3,  NStr("ru = 'Указанный файл правил обмена не существует.'; en = 'The exchange rules file does not exist.'; pl = 'Określony plik reguły wymiany nie istnieje.';de = 'Die angegebene Austausch-Regeldatei existiert nicht.';ro = 'Fișierul de reguli de schimb specificat nu există.';tr = 'Belirtilen değişim kuralları dosyası mevcut değil.'; es_ES = 'El archivo de la regla del intercambio especificado no existe.'"));
	ErrorMessages.Insert(4,  NStr("ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument'; en = 'Cannot create COM object: Msxml2.DOMDocument.'; pl = 'Podczas tworzenia COM obiektu Msxml2.DOMDocument wystąpił błąd';de = 'Beim Erstellen des COM-Objekts Msxml2.DOMDocument ist ein Fehler aufgetreten';ro = 'Eroare la crearea obiectului COM Msxml2.DOMDocument';tr = 'Msxml2.DOMDocument COM nesnesi oluştururken bir hata oluştu '; es_ES = 'Ha ocurrido un error al crear el objeto COM Msxml2.DOMDocumento'"));
	ErrorMessages.Insert(5,  NStr("ru = 'Ошибка открытия файла обмена'; en = 'Cannot open the exchange file.'; pl = 'Podczas otwarcia pliku wymiany wystąpił błąd';de = 'Beim Öffnen der Austausch-Datei ist ein Fehler aufgetreten';ro = 'Eroare la deschiderea fișierului de schimb';tr = 'Değişim dosyası açılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al abrir el archivo de intercambio'"));
	ErrorMessages.Insert(6,  NStr("ru = 'Ошибка при загрузке правил обмена'; en = 'Cannot load the exchange rules.'; pl = 'Podczas importu reguł wymiany wystąpił błąd';de = 'Beim Importieren von Austausch-Regeln ist ein Fehler aufgetreten';ro = 'Eroare la importul regulilor de schimb';tr = 'Değişim kuralları içe aktarılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al importar las reglas de intercambio'"));
	ErrorMessages.Insert(7,  NStr("ru = 'Ошибка формата правил обмена'; en = 'Exchange rule format error.'; pl = 'Błąd formatu reguł wymiany';de = 'Fehler beim Format der Austauschregeln';ro = 'Eroare în formatul regulilor de schimb';tr = 'Değişim kuralı biçiminde hata'; es_ES = 'Error en el formato de la regla de intercambio'"));
	ErrorMessages.Insert(8,  NStr("ru = 'Некорректно указано имя файла для выгрузки данных'; en = 'Invalid data export file name.'; pl = 'Niepoprawnie jest wskazana nazwa pliku do pobierania danych';de = 'Falscher Dateiname für das Hochladen von Daten';ro = 'Numele fișierului pentru exportul de date este indicat incorect';tr = 'Veri dışa aktarma için belirtilen dosya adı yanlıştır'; es_ES = 'Nombre del archivo está indicado incorrectamente para subir los datos'")); // not used
	ErrorMessages.Insert(9,  NStr("ru = 'Ошибка формата файла обмена'; en = 'Exchange file format error.'; pl = 'Błąd formatu pliku wymiany';de = 'Fehler beim Austausch des Dateiformats';ro = 'Eroare în formatul fișierului de schimb';tr = 'Değişim dosyası biçiminde hata'; es_ES = 'Error en el formato del archivo de intercambio'"));
	ErrorMessages.Insert(10, NStr("ru = 'Не указано имя файла для выгрузки данных (Имя файла данных)'; en = 'The name of the data export file (the file with data) is not specified.'; pl = 'Nie określono nazwy pliku do eksportu danych (Nazwa pliku danych)';de = 'Dateiname für Datenexport ist nicht angegeben (Dateiname)';ro = 'Numele fișierului pentru exportul de date nu este specificat (Numele fișierului de date)';tr = 'Veri dışa aktarma için dosya adı belirtilmemiş (Veri dosyasının adı)'; es_ES = 'Nombre del archivo para la exportación de datos no está especificado (Nombre del archivo de datos)'"));
	ErrorMessages.Insert(11, NStr("ru = 'Ссылка на несуществующий объект метаданных в правилах обмена'; en = 'The exchange rules contain a reference to a metadata object that does not exist.'; pl = 'Odwołanie do nieistniejącego obiektu metadanych w regułach wymiany';de = 'Verknüpfen Sie ein nicht vorhandenes Metadatenobjekt in den Austauschregeln';ro = 'Link la un obiect de metadate inexistent în regulile de schimb';tr = 'Değişim kurallarında varolan bir meta veri nesnesine bağlanma'; es_ES = 'Enlace al objeto de metadatos inexistente en las reglas de intercambio'"));
	ErrorMessages.Insert(12, NStr("ru = 'Не указано имя файла с правилами обмена (Имя файла правил)'; en = 'The exchange rules file name is not specified.'; pl = 'Nie określono nazwy pliku z regułami wymiany (Nazwa pliku reguł)';de = 'Dateiname mit Austauschregeln ist nicht angegeben (Regeldateiname)';ro = 'Numele fișierului cu regulile de schimb nu este specificat (Numele fișierului de reguli)';tr = 'Değişim kuralları ile dosya adı belirtilmemiş (Kural dosyasının adı)'; es_ES = 'Nombre del archivo con las reglas de intercambio no está especificado (Nombre del archivo de la regla)'"));
			
	ErrorMessages.Insert(13, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства источника)'; en = 'Cannot get an object property value by source property name.'; pl = 'Podczas odzyskiwania wartości właściwości obiektu (wg nazwy właściwości źródła) wystąpił błąd';de = 'Beim Empfangen eines Werts der Objekteigenschaft (anhand des Namens der Quelleigenschaft) ist ein Fehler aufgetreten';ro = 'Eroare la obținerea valorii proprietății obiectului (după numele proprietății sursei)';tr = 'Nesne özelliğinin bir değeri alınırken bir hata oluştu (kaynak özelliği adıyla)'; es_ES = 'Ha ocurrido un error al recibir un valor de la propiedad del objeto (por el nombre de la propiedad de la fuente)'"));
	ErrorMessages.Insert(14, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства приемника)'; en = 'Cannot get an object property value by destination property name.'; pl = 'Podczas odzyskiwania wartości właściwości obiektu (wg nazwy właściwości celu) wystąpił błąd';de = 'Fehler beim Abrufen des Objekt-Eigenschaftswerts (nach Ziel-Eigenschaftsname).';ro = 'Eroare la preluarea valorii proprietății obiectului (după numele proprietății destinație).';tr = 'Nesne özelliği değerini alınırken bir hata oluştu (hedef özellik adına göre)'; es_ES = 'Ha ocurrido un error al recibir el valor de la propiedad del objeto (por el nombre de la propiedad de objetivo)'"));
	
	ErrorMessages.Insert(15, NStr("ru = 'Не указано имя файла для загрузки данных (Имя файла для загрузки)'; en = 'The name of the data import file (the file with data) is not specified.'; pl = 'Nie określono nazwy pliku do importu danych (Nazwa pliku do importu)';de = 'Dateiname für den Datenimport ist nicht angegeben (Dateiname für den Import)';ro = 'Numele fișierului pentru importul de date nu este specificat (Numele fișierului pentru import)';tr = 'Veri dışa aktarma için dosya adı belirtilmemiş (İçe aktarılacak dosyasının adı)'; es_ES = 'Nombre del archivo para importación de datos no está especificado (Nombre del archivo para importar)'"));
			
	ErrorMessages.Insert(16, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)'; en = 'Cannot get a value of a subordinate object property by source property name.'; pl = 'Podczas otrzymywania wartości właściwości obiektu  podporządkowanego (wg nazwy właściwości źródła) wystąpił błąd';de = 'Beim Empfangen des Werts der Unterobjekteigenschaft (nach Name der Quelleigenschaft) ist ein Fehler aufgetreten';ro = 'Eroare la obținerea valorii proprietății obiectului subordonat (după numele proprietății sursei)';tr = 'Alt nesne özelliğinin değeri alınırken bir hata oluştu (kaynak özellik adına göre)'; es_ES = 'Ha ocurrido un error al recibir el valor de la propiedad del subobjeto (por el nombre de la propiedad de la fuente)'"));
	ErrorMessages.Insert(17, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)'; en = 'Cannot get a value of a subordinate object property by destination property name.'; pl = 'Podczas otrzymywania wartości właściwości obiektu  podporządkowanego (wg nazwy właściwości celu) wystąpił błąd';de = 'Fehler beim Abrufen des Wertes der untergeordneten Objekteigenschaften (nach Name der Zieleigenschaft).';ro = 'Eroare la preluarea valorii proprietății obiectului subordonat (după numele proprietății destinație).';tr = 'Alt nesne özelliğinin değeri alınırken bir hata oluştu (kaynak özellik adına göre)'; es_ES = 'Ha ocurrido un error al recibir el valor de la propiedad del subobjeto (por el nombre de la propiedad de objetivo)'"));
	ErrorMessages.Insert(18, NStr("ru = 'Ошибка при создании обработки с кодом обработчиков'; en = 'Cannot create a data processor with handlers code.'; pl = 'Wystąpił błąd podczas tworzenia przetwarzania danych z kodem procedury przetwarzania';de = 'Beim Erstellen eines Datenprozessors mit dem Anwender-Code ist ein Fehler aufgetreten';ro = 'Eroare la crearea procesării cu codul handlerelor';tr = 'İşleyici koduyla bir veri işlemci oluştururken bir hata oluştu'; es_ES = 'Ha ocurrido un error al crear un procesador de datos con el código del manipulador'"));
	ErrorMessages.Insert(19, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойОбъекта'; en = 'BeforeImportObject event handler error.'; pl = 'Błąd przetwarzania zdarzenia BeforeObjectImport';de = 'Ein Fehler ist aufgetreten in Ereignis-Anwender VorObjektImport';ro = 'Eroare în handlerul evenimentului BeforeObjectImport';tr = 'NesneİçeAktarılmadanÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeObjectImport'"));
	ErrorMessages.Insert(20, NStr("ru = 'Ошибка в обработчике события ПриЗагрузкеОбъекта'; en = 'OnImportObject event handler error.'; pl = 'Błąd przetwarzania zdarzenia OnObjectImport';de = 'Ein Fehler ist aufgetreten in Ereignis-Anwender AufObjektImport';ro = 'Eroare în handlerul evenimentului OnObjectImport';tr = 'NesneİçeAktarılırken veri işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos OnObjectImport'"));
	ErrorMessages.Insert(21, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиОбъекта'; en = 'AfterImportObject event handler error.'; pl = 'Błąd przetwarzania zdarzenia AfterObjectImport';de = 'Ein Fehler ist aufgetreten in Ereignis-Anwender NachObjektImport';ro = 'Eroare în handlerul evenimentului AfterObjectImport';tr = 'NesneİçeAktarıldıktanSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterObjectImport'"));
	ErrorMessages.Insert(22, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)'; en = 'BeforeImportData event handler error (conversion).'; pl = 'Błąd przetwarzania zdarzenia BeforeDataImport (konwersja)';de = 'Ein Fehler ist aufgetreten in Ereignis-Anwender VorDatenImport (Umwandlung)';ro = 'Eroare în handlerul evenimentului BeforeDataImport (conversie)';tr = 'NesneİçeAktarılmadanÖnce olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeDataImport (conversión)'"));
	ErrorMessages.Insert(23, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)'; en = 'AfterImportData event handler error (conversion).'; pl = 'Błąd przetwarzania zdarzenia AfterDataImport (konwersja)';de = 'Ein Fehler ist aufgetreten in Ereignis-Anwender NachDatenImport (Umwandlung)';ro = 'Eroare în handlerul evenimentului AfterDataImport (conversie)';tr = 'NesneİçeAktarıldıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterDataImport (conversión)'"));
	ErrorMessages.Insert(24, NStr("ru = 'Ошибка при удалении объекта'; en = 'Cannot delete the object.'; pl = 'Podczas usuwania obiektu wystąpił błąd';de = 'Beim Entfernen eines Objekts ist ein Fehler aufgetreten';ro = 'Eroare la ștergerea obiectului';tr = 'Nesne silinirken bir hata oluştu'; es_ES = 'Ha ocurrido un error al eliminar un objeto'"));
	ErrorMessages.Insert(25, NStr("ru = 'Ошибка при записи документа'; en = 'Cannot write the document.'; pl = 'Podczas zapisu dokumentu wystąpił błąd';de = 'Beim Schreiben des Dokuments ist ein Fehler aufgetreten';ro = 'Eroare la înregistrarea documentului';tr = 'Belge yazılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al grabar el documento'"));
	ErrorMessages.Insert(26, NStr("ru = 'Ошибка записи объекта'; en = 'Cannot write the object.'; pl = 'Podczas zapisu obiektu wystąpił błąd';de = 'Beim Schreiben des Objekts ist ein Fehler aufgetreten';ro = 'Eroare la înregistrarea obiectului';tr = 'Nesne yazılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al grabar el objeto'"));
	ErrorMessages.Insert(27, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаОчистки'; en = 'BeforeProcessClearingRule event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeProcessClearingRule';de = 'Im Ereignis-Anwender VorDerProzessbereinigungsregel ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului BeforeProcessClearingRule';tr = 'TemizlemeKuralıİşlenmedenÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeProcessClearingRule'"));
	ErrorMessages.Insert(28, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаОчистки'; en = 'AfterProcessClearingRule event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterClearingRuleProcessing';de = 'Ein Fehler ist im Ereignis-Anwender NachDemLöschenDerRegelverarbeitung"" aufgetreten.';ro = 'Eroare în handlerul evenimentului AfterClearingRuleProcessing ';tr = 'TemizlemeKuralıİşlendiktenSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterClearingRuleProcessing'"));
	ErrorMessages.Insert(29, NStr("ru = 'Ошибка в обработчике события ПередУдалениемОбъекта'; en = 'BeforeDeleteObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeDeleteObject';de = 'Im Ereignis-Anwender VorDemObjektLöschen ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului BeforeDeleteObject';tr = 'NesneSilinmedenÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeDeleteObject'"));
	
	ErrorMessages.Insert(31, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаВыгрузки'; en = 'BeforeProcessExportRule event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeProcessExportRule';de = 'Im Ereignis-Anwender VorDemProzessExport-Regel ist ein Fehler aufgetreten';ro = 'Eroare handlerul evenimentului BeforeProcessExportRule';tr = 'DışaAktarmaKuralıİşlenmedenÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeProcessExportRule'"));
	ErrorMessages.Insert(32, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки'; en = 'AfterProcessExportRule event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterDumpRuleProcessing';de = 'Im Ereignis-Anwender NachDerDump-Regelverarbeitung ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului AfterDumpRuleProcessing';tr = 'DışaAktarmaKuralıİşlendiktenSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterDumpRuleProcessing'"));
	ErrorMessages.Insert(33, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'; en = 'BeforeExportObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeObjectExport';de = 'Im Ereignis-Anwender VorDemObjektExport ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului BeforeObjectExport';tr = 'NesneDışaAktarmadanÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeObjectExport'"));
	ErrorMessages.Insert(34, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'; en = 'AfterExportObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterObjectExport';de = 'Im Ereignis-Anwender NachDemObjektExport ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului AfterObjectExport';tr = 'NesneDışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterObjectExport'"));
			
	ErrorMessages.Insert(41, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'; en = 'BeforeExportObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeObjectExport';de = 'Im Ereignis-Anwender VorDemObjektExport ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului BeforeObjectExport';tr = 'NesneDışaAktarmadanÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeObjectExport'"));
	ErrorMessages.Insert(42, NStr("ru = 'Ошибка в обработчике события ПриВыгрузкеОбъекта'; en = 'OnExportObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia OnObjectExport';de = 'Im Ereignis-Anwender BeimObjektExport ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului OnObjectExport';tr = 'NesneDışaAktarılırken olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos OnObjectExport'"));
	ErrorMessages.Insert(43, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'; en = 'AfterExportObject event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterObjectExport';de = 'Im Ereignis-Anwender NachDemObjektExport ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului AfterObjectExport';tr = 'NesneDışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterObjectExport'"));
			
	ErrorMessages.Insert(45, NStr("ru = 'Не найдено правило конвертации объектов'; en = 'The conversion rule is not found.'; pl = 'Nie znaleziono reguły konwertowania obiektów';de = 'Die Objektkonvertierungsregel wurde nicht gefunden';ro = 'Regula conversiei obiectului nu a fost găsită';tr = 'Nesne dönüştürme kuralı bulunamadı'; es_ES = 'Regla de conversión de objetos no encontrada'"));
		
	ErrorMessages.Insert(48, NStr("ru = 'Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств'; en = 'BeforeProcessExport (of a property group) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeExportProcessor grupy właściwości';de = 'Im Ereignis-Anwender VorExportProzessor der Eigenschaftsgruppe ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului BeforeExportProcessor din grupul de proprietăți';tr = 'Özellik grubunun İşlemciDışaAktarılmadanÖnce olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeExportProcessor del grupo de propiedades'"));
	ErrorMessages.Insert(49, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств'; en = 'AfterProcessExport (of a property group) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterExportProcessor grupy właściwości';de = 'Im Ereignis-Anwender NachExportProzessor der Eigenschaftsgruppe ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului AfterExportProcessor din grupul de proprietăți';tr = 'Özellik grubunun İşlemciDışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterExportProcessor del grupo de propiedades'"));
	ErrorMessages.Insert(50, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)'; en = 'BeforeExport (of a collection object) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeExport (obiektu kolekcji)';de = 'Fehler im Ereignis-Anwender VorDemExport (Der Sammlungsobjekt)';ro = 'Eroare la handlerul evenimentului BeforeExport (a obiectului colecției)';tr = 'DışaAktarımdanÖnce olay işleyicisindeki hata  (koleksiyon nesnesinin)'; es_ES = 'Error en el manipulador de eventos BeforeExport (del objeto de colección)'"));
	ErrorMessages.Insert(51, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (объекта коллекции)'; en = 'OnExport (of a collection object) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia OnExport (obiektu kolekcji)';de = 'Fehler im Ereignis-Anwender BeimExport (Der Sammlungsobjekt)';ro = 'Eroare la handlerul evenimentului OnExport (a obiectului colecției)';tr = 'DışaAktarılırken olay işleyicisindeki hata  (koleksiyon nesnesinin)'; es_ES = 'Error en el manipulador de eventos OnExport (del objeto de colección)'"));
	ErrorMessages.Insert(52, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)'; en = 'AfterExport (of a collection object) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterExport (obiektu kolekcji)';de = 'Fehler im Ereignis-Anwender NachDemExport (Der Sammlungsobjekt)';ro = 'Eroare la handlerul evenimentului AfterExport (a obiectului colecției)';tr = 'DışaAktarımdanSonra olay işleyicisindeki hata  (koleksiyon nesnesinin)'; es_ES = 'Error en el manipulador de eventos AfterExport (del objeto de colección)'"));
	ErrorMessages.Insert(53, NStr("ru = 'Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)'; en = 'BeforeImportObject global event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeObjectImporting (konwersja)';de = 'Im globalen Ereignis-Anwender ist ein Fehler aufgetreten VorDemImportierenVonObjekten (Konvertierung)';ro = 'Eroare în handlerul global al evenimentului BeforeObjectImporting (conversie)';tr = 'NesneİçeAktarılmadanÖnce global olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos global BeforeObjectImporting (conversión)'"));
	ErrorMessages.Insert(54, NStr("ru = 'Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)'; en = 'AfterImportObject global event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterObjectImport (konwersja)';de = 'Im globalen Ereignis-Anwender ist ein Fehler aufgetreten NachDemImportierenVonObjekten (Konvertierung)';ro = 'Eroare în handlerul global al evenimentului AfterObjectImport (conversie)';tr = 'NesneİçeAktarıldıktanSonra global olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos global AfterObjectImport (conversión)'"));
	ErrorMessages.Insert(55, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (свойства)'; en = 'BeforeExport (of a property) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterExport (właściwości)';de = 'Im Ereignis-Anwender ist ein Fehler aufgetreten VorExport (Eigenschaften)';ro = 'Eroare în handlerul evenimentului BeforeExport (proprietăți)';tr = 'DışaAktarılmadanÖnce olay işleyicisinde bir hata oluştu (özellikler)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeExport (propiedades)'"));
	ErrorMessages.Insert(56, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (свойства)'; en = 'OnExport (of a property) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia OnExport (właściwości)';de = 'Im Ereignis-Anwender ist ein Fehler aufgetreten BeimExport (Eigenschaften)';ro = 'Eroare în handlerul evenimentului OnExport (proprietăți)';tr = 'DışaAktarılırken olay işleyicisinde bir hata oluştu (özellikler)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos OnExport (propiedades)'"));
	ErrorMessages.Insert(57, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (свойства)'; en = 'AfterExport (of a property) event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterExport (właściwości)';de = 'Im Ereignis-Anwender ist ein Fehler aufgetreten NachExport (Eigenschaften)';ro = 'Eroare în handlerul evenimentului AfterExport (proprietăți)';tr = 'DışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu (özellikler)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterExport (propiedades)'"));
	
	ErrorMessages.Insert(62, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)'; en = 'BeforeExportData event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeDataExport (konwersja)';de = 'Im Ereignis-Anwender ist ein Fehler aufgetreten VorDatenExport (Konvertierung)';ro = 'Eroare în handlerul evenimentului BeforeDataExport (conversie)';tr = 'VeriDışaAktarılmadanÖnce olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeDataExport (conversión)'"));
	ErrorMessages.Insert(63, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)'; en = 'AfterExportData event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterDataExport (konwersja)';de = 'Im Ereignis-Anwender ist ein Fehler aufgetreten NachDatenExport (Konvertierung)';ro = 'Eroare în handlerul evenimentului AfterDataExport (conversie)';tr = 'VeriDışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterDataExport (conversión)'"));
	ErrorMessages.Insert(64, NStr("ru = 'Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)'; en = 'BeforeConvertObject global event handler error (conversion).'; pl = 'Wystąpił błąd podczas globalnego przetwarzania zdarzenia BeforeObjectConversion (konwersja)';de = 'Im globalen Ereignis-Anwender ist ein Fehler aufgetreten VorDerObjektkonvertierung (Konvertierung)';ro = 'Eroare în handlerul global al evenimentului BeforeObjectConversion (conversie)';tr = 'NesneDönüştürmedenÖnce global olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos global BeforeObjectConversion (conversión)'"));
	ErrorMessages.Insert(65, NStr("ru = 'Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)'; en = 'BeforeExportObject global event handler error (conversion).'; pl = 'Wystąpił błąd podczas globalnego przetwarzania zdarzenia BeforeObjectExport (konwertowanie)';de = 'Im globalen Ereignis-Anwender ist ein Fehler aufgetreten VorObjektExport (Konvertierung)';ro = 'Eroare în handlerul global al evenimentului BeforeObjectExport (conversie)';tr = 'NesneDışaAktarılmadanÖnce global olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos global BeforeObjectExport (conversión)'"));
	ErrorMessages.Insert(66, NStr("ru = 'Ошибка получения коллекции подчиненных объектов из входящих данных'; en = 'Cannot get a collection of subordinate objects from incoming data.'; pl = 'Podczas otrzymywania kolekcji obiektów podporządkowanych z danych wchodzących wystąpił błąd';de = 'Beim Empfang einer untergeordneten Objektsammlung aus den eingehenden Daten ist ein Fehler aufgetreten';ro = 'Eroare la obținerea colecției de obiecte subordonate din datele de intrare';tr = 'Gelen verilerden bir alt nesne koleksiyonu alınırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al recibir una colección de objetos subordinados desde los datos entrantes'"));
	ErrorMessages.Insert(67, NStr("ru = 'Ошибка получения свойства подчиненного объекта из входящих данных'; en = 'Cannot get a property of a subordinate object from incoming data.'; pl = 'Podczas odzyskiwania właściwości obiektu podporządkowanego z danych wchodzących wystąpił błąd';de = 'Beim Empfang der untergeordneten Objekteigenschaften aus den eingehenden Daten ist ein Fehler aufgetreten';ro = 'Eroare la obținerea proprietății obiectului subordonat din datele de intrare';tr = 'Alt nesne özelliklerini gelen verilerden alırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al recibir las propiedades del objeto subordinado desde los datos entrantes'"));
	ErrorMessages.Insert(68, NStr("ru = 'Ошибка получения свойства объекта из входящих данных'; en = 'Cannot get an object property from incoming data.'; pl = 'Podczas odzyskiwania właściwości obiektu z danych wchodzących wystąpił błąd';de = 'Beim Empfang der Objekteigenschaften aus den eingehenden Daten ist ein Fehler aufgetreten';ro = 'Eroare la obținerea proprietății obiectului din datele de intrare';tr = 'Nesne özelliklerini gelen verilerden alırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al recibir las propiedades del objeto desde los datos entrantes'"));
	
	ErrorMessages.Insert(69, NStr("ru = 'Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)'; en = 'AfterExportObject global event handler error (conversion).'; pl = 'Wystąpił błąd podczas globalnego przetwarzania zdarzenia AfterObjectExport (konwertowanie)';de = 'Im globalen Ereignis-Anwender ist ein Fehler aufgetreten NachObjektExport (Konvertierung)';ro = 'Eroare în handlerul global al evenimentului AfterObjectExport (conversie)';tr = 'NesneDışaAktarıldıktanSonra global olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos global AfterObjectExpor (conversión)'"));
	
	ErrorMessages.Insert(71, NStr("ru = 'Не найдено соответствие для значения Источника'; en = 'Cannot find a mapping for the source value.'; pl = 'Nie znaleziono odpowiednika dla znaczenia Źródła';de = 'Übereinstimmung für den Quellwert wurde nicht gefunden';ro = 'Nu a fost găsită corespondența pentru valoarea Sursei';tr = 'Kaynak değerinin eşleşmesi bulunamadı'; es_ES = 'Correspondencia con el valor de la Fuente no encontrada'"));
	
	ErrorMessages.Insert(72, NStr("ru = 'Ошибка при выгрузке данных для узла плана обмена'; en = 'Cannot export data for the exchange plan node.'; pl = 'Błąd podczas eksportu danych dla węzła planu wymiany';de = 'Beim Exportieren von Daten für den Austauschplanknoten ist ein Fehler aufgetreten';ro = 'Eroare la exportul datelor pentru nodul planului de schimb';tr = 'Değişim planı ünitesi için veri dışa aktarılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al exportar los datos para el nodo del plan de intercambio'"));
	
	ErrorMessages.Insert(73, NStr("ru = 'Ошибка в обработчике события ПоследовательностьПолейПоиска'; en = 'SearchFieldSequence event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia SearchFieldsSequence';de = 'Im Ereignis-Anwender SuchfelderSequenz ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului SearchFieldsSequence';tr = 'AlanSırasınıArama olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos SearchFieldsSequence'"));
	ErrorMessages.Insert(74, NStr("ru = 'Необходимо перезагрузить правила обмена для выгрузки данных.'; en = 'Reloading exchange rules for data export is required.'; pl = 'Należy ponownie wykonać reguły wymiany dla eksportu danych.';de = 'Importieren Sie die Austauschregeln für den Datenexport erneut.';ro = 'Importați din nou regulile de schimb pentru exportul de date.';tr = 'Veri aktarımı için tekrar değişim kuralları.'; es_ES = 'Reglas de intercambio de importación para exportar los datos de nuevo.'"));
	
	ErrorMessages.Insert(75, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиПравилОбмена (конвертация)'; en = 'AfterImportExchangeRules event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterImportOfExchangeRules (konwersja)';de = 'Es ist ein Fehler im Ereignis-Anwender AfterImportExchangeRules aufgetreten (Konvertierung)';ro = 'A apărut o eroare în handler evenimente AfterImportExchangeRules (conversie)';tr = 'AfterImportExchangeRules olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterImportOfExchangeRules (conversión)'"));
	ErrorMessages.Insert(76, NStr("ru = 'Ошибка в обработчике события ПередОтправкойИнформацииОбУдалении (конвертация)'; en = 'BeforeSendDeletionInfo event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeSendingUninstallInformation (konwersja)';de = 'Es ist ein Fehler im BeforeSendDeletionInformation Ereignis-Anwender aufgetreten (Konvertierung)';ro = 'A apărut o eroare în handler evenimente BeforeSendDeletionInformation (conversie)';tr = 'BeforeSendDeletionInformation olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeSendDeletionInformation (conversión)'"));
	ErrorMessages.Insert(77, NStr("ru = 'Ошибка в обработчике события ПриПолученииИнформацииОбУдалении (конвертация)'; en = 'OnGetDeletionInfo event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzeniaOnObtainingInformationAboutDeletion (konwersja)';de = 'Es ist ein Fehler im OnGetDeletionInformation Event-Anwender aufgetreten (Konvertierung)';ro = 'A apărut o eroare în handler evenimente OnGetDeletionInformation (conversie)';tr = 'OnGetDeletionInformation olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos OnGetDeletionInformation (conversión)'"));
	
	ErrorMessages.Insert(78, NStr("ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров'; en = 'Error executing algorithm after parameter value import'; pl = 'Podczas wykonania algorytmu po imporcie wartości parametrów wystąpił błąd';de = 'Beim Ausführen des Algorithmus nach dem Import der Parameterwerte ist ein Fehler aufgetreten';ro = 'Eroare la executarea algoritmului după importul valorilor parametrilor';tr = 'Parametre değerlerini içe aktardıktan sonra algoritmayı çalıştırırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al ejecutar el algoritmo después de la importación de los valores del parámetro'"));
	
	ErrorMessages.Insert(79, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл'; en = 'AfterExportObjectToFile event handler error.'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia AfterObjectExportToFile';de = 'Im Ereignis-Anwender NachDemObjektExportInDatei ist ein Fehler aufgetreten';ro = 'Eroare în handlerul evenimentului AfterObjectExportToFile';tr = 'NesneDosyayaAktarıldıktanSonra olay işleyicisinde bir hata oluştu'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterObjectExportToFile'"));
	
	ErrorMessages.Insert(80, NStr("ru = 'Ошибка установки свойства предопределенного элемента.
		|Нельзя помечать на удаление предопределенный элемент. Пометка на удаление для объекта не установлена.'; 
		|en = 'Cannot set a predefined item property value.
		|Cannot set a deletion mark for a predefined item. The deletion mark is not set.'; 
		|pl = 'Błąd predefiniowanego ustawienia właściwości elementu.
		|Nie można oznaczyć predefiniowanego elementu do usunięcia. Zaznaczenie do usunięcia dla obiektów nie zostało ustawione.';
		|de = 'Fehler der vordefinierten Einstellung der Elementeigenschaften. 
		|Sie können das vordefinierte Element, das gelöscht werden soll, nicht markieren. Die zu löschende Markierung für die Objekte ist nicht installiert.';
		|ro = 'Eroare la setarea proprietății elementului predefinit.
		|Nu puteți marca elementul predefinit pentru ștergere. Obiectul nu este marcat la ștergere.';
		|tr = 'Önceden tanımlanmış öğe özelliği ayarının hatası. 
		|Önceden silinecek olarak tanımlanmış öğeyi işaretleyemezsiniz. Nesnelerin silinmesi için işaret yüklenmemiş.'; 
		|es_ES = 'Error de la configuración de la propiedad del artículo predefinido.
		|Usted no puede marcar el artículo predefinido para borrar. Marca de borrado para los objetos no está instalada.'"));
	//
	ErrorMessages.Insert(83, NStr("ru = 'Ошибка обращения к табличной части объекта. Табличная часть объекта не может быть изменена.'; en = 'Object tabular section access error. Cannot change the tabular section.'; pl = 'Wystąpił błąd podczas uzyskiwania dostępu do sekcji tabelarycznej obiektu. Nie można zmienić sekcji tabelarycznej obiektu.';de = 'Beim Zugriff auf den Objekttabellenabschnitt ist ein Fehler aufgetreten. Der tabellarische Objektbereich kann nicht geändert werden.';ro = 'A apărut o eroare la accesarea secțiunii tabulare a obiectului. Secțiunea tabulară a obiectului nu poate fi modificată.';tr = 'Nesne sekme bölümüne erişilirken bir hata oluştu. Nesne sekme bölümü değiştirilemez.'; es_ES = 'Ha ocurrido un error al acceder a la sección tabular del objeto. La sección tabular del objeto no puede cambiarse.'"));
	ErrorMessages.Insert(84, NStr("ru = 'Коллизия дат запрета изменения.'; en = 'Period-end closing dates conflict.'; pl = 'Konflikt dat zakazu przemiany.';de = 'Kollision der Abschlussdaten der Änderung.';ro = 'Coliziunea datei de închidere a modificării.';tr = 'Değişim kapanış tarihlerinin çarpışması.'; es_ES = 'Colisión de las fechas de cierre de cambios.'"));
	
	ErrorMessages.Insert(173, NStr("ru = 'Ошибка блокировки узла обмена. Возможно синхронизация данных уже выполняется'; en = 'Cannot lock the exchange node. Probably the synchronization is already running.'; pl = 'Wystąpił błąd blokady węzła wymiany. Być może synchronizacja danych już jest w toku';de = 'Ein Fehler der Austausch-Knoten-Sperre ist aufgetreten. Vielleicht läuft die Datensynchronisation bereits';ro = 'A apărut o eroare a blocării nodului de schimb. Poate că sincronizarea datelor este deja în curs';tr = 'Değişim ünitesi kilidi hatası oluştu. Belki, veri senkronizasyonu zaten devam ediyor'; es_ES = 'Ha ocurrido un error del bloqueo del nodo de intercambio. Puede ser que la sincronización de datos ya esté en progreso'"));
	ErrorMessages.Insert(174, NStr("ru = 'Сообщение обмена было принято ранее'; en = 'The exchange message was received earlier.'; pl = 'Wiadomość wymiany została przyjęta poprzednio';de = 'Austausch-Nachricht wurde zuvor empfangen';ro = 'Mesajul de schimb a fost primit anterior';tr = 'Değişim iletisi daha önce alındı'; es_ES = 'Mensaje de intercambio se había recibido previamente'"));
	ErrorMessages.Insert(175, NStr("ru = 'Ошибка в обработчике события ПередПолучениемИзмененныхОбъектов (конвертация)'; en = 'BeforeGetChangedObjects event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeModifiedObjectsReceiving (konwersja)';de = 'Im Ereignis-Anwender BeforeGetChangedObjects ist ein Fehler aufgetreten (Konvertierung)';ro = 'A apărut o eroare în procedura de procesare a evenimentelor BeforeGetChangedObjects (conversie)';tr = 'BeforeGetChangedObjects olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeGetChangedObjects (conversión)'"));
	ErrorMessages.Insert(176, NStr("ru = 'Ошибка в обработчике события ПослеПолученияИнформацииОбУзлахОбмена (конвертация)'; en = 'AfterGetExchangeNodesInformation event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia  AfterGettingInformationAboutExchangeNodes (konwertowanie)';de = 'Fehler im AfterReceiveExchangeNodeDetails Ereignis-Anwender (Konvertierung)';ro = 'Eroare în handler de evenimente AfterReceiveExchangeNodeDetails (conversie)';tr = 'DeğişimÜniteleriHakkındakiBilgilerAlındıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterGettingInformationAboutExchangeNodes (conversión)'"));
		
	ErrorMessages.Insert(1000, NStr("ru = 'Ошибка при создании временного файла выгрузки данных'; en = 'Cannot create a temporary data export file.'; pl = 'Wystąpił błąd podczas tworzenia tymczasowego pliku eksportu danych';de = 'Beim Erstellen einer temporären Datei mit Datenexport ist ein Fehler aufgetreten';ro = 'A apărut o eroare la crearea unui fișier temporar de export de date';tr = 'Geçici bir veri aktarımı dosyası oluşturulurken bir hata oluştu'; es_ES = 'Ha ocurrido un error al crear un archivo temporal de la exportación de datos'"));
		
EndProcedure

Procedure SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, TypeName, Manager, TypeNamePrefix, SearchByPredefinedItemsPossible = False)
	
	Name              = MetadataObject.Name;
	RefTypeString = TypeNamePrefix + "." + Name;
	SearchString     = "SELECT Ref FROM " + TypeName + "." + Name + " WHERE ";
	RefExportSearchString     = "SELECT #SearchFields# FROM " + TypeName + "." + Name;
	RefType        = Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);
	Structure.Insert("SearchString",SearchString);
	Structure.Insert("RefExportSearchString",RefExportSearchString);
	Structure.Insert("SearchByPredefinedItemsPossible",SearchByPredefinedItemsPossible);

	Managers.Insert(RefType, Structure);
	
	
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, True, False);

	ManagersForExchangePlans.Insert(MetadataObject, StructureForExchangePlan);
	
EndProcedure

Procedure SupplementManagerArrayWithRegisterType(Managers, MetadataObject, TypeName, Manager, TypeNamePrefixRecord, SelectionTypeNamePrefix)
	
	Periodic = Undefined;
	
	Name					= MetadataObject.Name;
	RefTypeString	= TypeNamePrefixRecord + "." + Name;
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);

	If TypeName = "InformationRegister" Then
		
		Periodic = (MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical);
		SubordinatedToRecorder = (MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		
		Structure.Insert("Periodic", Periodic);
		Structure.Insert("SubordinateToRecorder", SubordinatedToRecorder);
		
	EndIf;	
	
	Managers.Insert(RefType, Structure);
		
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, False, True);

	ManagersForExchangePlans.Insert(MetadataObject, StructureForExchangePlan);
	
	
	RefTypeString	= SelectionTypeNamePrefix + "." + Name;
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);

	If Periodic <> Undefined Then
		
		Structure.Insert("Periodic", Periodic);
		Structure.Insert("SubordinateToRecorder", SubordinatedToRecorder);
		
	EndIf;
	
	Managers.Insert(RefType, Structure);
		
EndProcedure

// Initializes the Managers variable that contains mapping of object types and their properties.
//
// Parameters:
//  No.
// 
Procedure ManagersInitialization()

	Managers = New Map;
	
	ManagersForExchangePlans = New Map;
    	
	// REFERENCES
	
	For each MetadataObject In Metadata.Catalogs Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "Catalog", Catalogs[MetadataObject.Name], "CatalogRef", True);
					
	EndDo;

	For each MetadataObject In Metadata.Documents Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "Document", Documents[MetadataObject.Name], "DocumentRef");
				
	EndDo;

	For each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "ChartOfCharacteristicTypes", ChartsOfCharacteristicTypes[MetadataObject.Name], "ChartOfCharacteristicTypesRef", True);
				
	EndDo;
	
	For each MetadataObject In Metadata.ChartsOfAccounts Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "ChartOfAccounts", ChartsOfAccounts[MetadataObject.Name], "ChartOfAccountsRef", True);
						
	EndDo;
	
	For each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "ChartOfCalculationTypes", ChartsOfCalculationTypes[MetadataObject.Name], "ChartOfCalculationTypesRef", True);
				
	EndDo;
	
	For each MetadataObject In Metadata.ExchangePlans Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "ExchangePlan", ExchangePlans[MetadataObject.Name], "ExchangePlanRef");
				
	EndDo;
	
	For each MetadataObject In Metadata.Tasks Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "Task", Tasks[MetadataObject.Name], "TaskRef");
				
	EndDo;
	
	For each MetadataObject In Metadata.BusinessProcesses Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObject, "BusinessProcess", BusinessProcesses[MetadataObject.Name], "BusinessProcessRef");
		
		TypeName = "BusinessProcessRoutePoint";
		// Route point references
		Name              = MetadataObject.Name;
		Manager         = BusinessProcesses[Name].RoutePoints;
		SearchString     = "";
		RefTypeString = "BusinessProcessRoutePointRef." + Name;
		RefType        = Type(RefTypeString);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);
		Structure.Insert("EmptyRef", Undefined);
		Structure.Insert("SearchString", SearchString);

		Managers.Insert(RefType, Structure);
				
	EndDo;
	
	// REGISTERS

	For each MetadataObject In Metadata.InformationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObject, "InformationRegister", InformationRegisters[MetadataObject.Name], "InformationRegisterRecord", "InformationRegisterSelection");
						
	EndDo;

	For each MetadataObject In Metadata.AccountingRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObject, "AccountingRegister", AccountingRegisters[MetadataObject.Name], "AccountingRegisterRecord", "AccountingRegisterSelection");
				
	EndDo;
	
	For each MetadataObject In Metadata.AccumulationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObject, "AccumulationRegister", AccumulationRegisters[MetadataObject.Name], "AccumulationRegisterRecord", "AccumulationRegisterSelection");
						
	EndDo;
	
	For each MetadataObject In Metadata.CalculationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObject, "CalculationRegister", CalculationRegisters[MetadataObject.Name], "CalculationRegisterRecord", "CalculationRegisterSelection");
						
	EndDo;
	
	TypeName = "Enum";
	
	For each MetadataObject In Metadata.Enums Do
		
		Name              = MetadataObject.Name;
		Manager         = Enums[Name];
		RefTypeString = "EnumRef." + Name;
		RefType        = Type(RefTypeString);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);
		Structure.Insert("EmptyRef", Enums[Name].EmptyRef());

		Managers.Insert(RefType, Structure);
		
	EndDo;
	
	// Constants
	TypeName             = "Constants";
	MetadataObject            = Metadata.Constants;
	Name					= "Constants";
	Manager			= Constants;
	RefTypeString	= "ConstantsSet";
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject);

	Managers.Insert(RefType, Structure);
	
EndProcedure

Procedure InitManagersAndMessages()
	
	If Managers = Undefined Then
		ManagersInitialization();
	EndIf; 

	If ErrorMessages = Undefined Then
		InitMessages();
	EndIf;
	
EndProcedure

Procedure CreateConversionStructure()
	
	Conversion = New Structure("BeforeExportData, AfterExportData, BeforeGetChangedObjects, AfterGetExchangeNodesInformation, BeforeExportObject, AfterExportObject, BeforeConvertObject, BeforeImportObject, AfterImportObject, BeforeImportData, AfterImportData, OnGetDeletionInfo, BeforeSendDeletionInfo");
	Conversion.Insert("DeleteMappedObjectsFromDestinationOnDeleteFromSource", False);
	Conversion.Insert("FormatVersion");
	Conversion.Insert("CreationDateTime");
	
EndProcedure

// Initializes data processor attributes and module variables.
//
// Parameters:
//  No.
// 
Procedure InitAttributesAndModuleVariables()

	VisualExchangeSetupMode = False;
	ProcessedObjectsCountToUpdateStatus = 100;
	
	StoredExportedObjectCountByTypes = 2000;
		
	ParametersInitialized        = False;
	
	Managers    = Undefined;
	ErrorMessages  = Undefined;
	
	SetErrorFlag(False);
	
	CreateConversionStructure();
	
	Rules      = New Structure;
	Algorithms    = New Structure;
	AdditionalDataProcessors = New Structure;
	Queries      = New Structure;

	Parameters    = New Structure;
	EventsAfterParametersImport = New Structure;
	
	AdditionalDataProcessorParameters = New Structure;
    	
	XMLRules  = Undefined;
	
	// Types

	StringType                  = Type("String");
	BooleanType                  = Type("Boolean");
	NumberType                   = Type("Number");
	DateType                    = Type("Date");
	ValueStorageType       = Type("ValueStorage");
	UUIDType = Type("UUID");
	BinaryDataType          = Type("BinaryData");
	AccumulationRecordTypeType   = Type("AccumulationRecordType");
	ObjectDeletionType         = Type("ObjectDeletion");
	AccountTypeKind			       = Type("AccountType");
	TypeType                     = Type("Type");
	MapType            = Type("Map");
	
	String36Type  = New TypeDescription("String",, New StringQualifiers(36));
	String255Type = New TypeDescription("String",, New StringQualifiers(255));
	
	MapRegisterType    = Type("InformationRegisterRecordSet.InfobaseObjectsMaps");

	BlankDateValue		   = Date('00010101');
	
	ObjectsToImportCount     = 0;
	ObjectsToExportCount     = 0;
	ExchangeMessageFileSize      = 0;

	// XML node types
	
	XMLNodeTypeEndElement  = XMLNodeType.EndElement;
	XMLNodeTypeStartElement = XMLNodeType.StartElement;
	XMLNodeTypeText          = XMLNodeType.Text;
	
	DataProtocolFile = Undefined;
	
	TypeAndObjectNameMap = New Map();
	
	EmptyTypeValueMap = New Map;
	TypeDescriptionMap = New Map;
	
	AllowDocumentPosting = Metadata.ObjectProperties.Posting.Allow;
	
	ExchangeRuleInfoImportMode = False;
	
	ExchangeResultField = Undefined;
	
	CustomSearchFieldInfoOnDataExport = New Map();
	CustomSearchFieldInfoOnDataImport = New Map();
		
	ObjectMapsRegisterManager = InformationRegisters.InfobaseObjectsMaps;
	
	// Query to define information on mapping objects to replace source reference with target reference.
	InfobaseObjectsMapQuery = New Query;
	InfobaseObjectsMapQuery.Text = "
	|SELECT TOP 1
	|	InfobaseObjectsMaps.SourceUUIDString AS SourceUUIDString
	|FROM
	|	InformationRegister.InfobaseObjectsMaps AS InfobaseObjectsMaps
	|WHERE
	|	  InfobaseObjectsMaps.InfobaseNode           = &InfobaseNode
	|	AND InfobaseObjectsMaps.DestinationUUID = &DestinationUUID
	|	AND InfobaseObjectsMaps.DestinationType                     = &DestinationType
	|	AND InfobaseObjectsMaps.SourceType                     = &SourceType
	|";
	//
	
EndProcedure

Procedure SetErrorFlag(Value = True)
	
	ErrorFlagField = Value;
	
EndProcedure

Procedure Increment(Value, Val Iterator = 1)
	
	If TypeOf(Value) <> Type("Number") Then
		
		Value = 0;
		
	EndIf;
	
	Value = Value + Iterator;
	
EndProcedure

Procedure WriteDataImportEnd()
	
	DataExchangeState().ExchangeExecutionResult = ExchangeExecutionResult();
	DataExchangeState().ActionOnExchange         = Enums.ActionsOnExchange.DataImport;
	DataExchangeState().InfobaseNode    = ExchangeNodeDataImport;
	
	InformationRegisters.DataExchangesStates.AddRecord(DataExchangeState());
	
	// Writing the successful exchange to the information register.
	If ExchangeExecutionResult() = Enums.ExchangeExecutionResults.Completed Then
		
		// Generating and filling in a structure for the new information register record.
		RecordStructure = New Structure("InfobaseNode, ActionOnExchange, EndDate");
		FillPropertyValues(RecordStructure, DataExchangeState());
		
		InformationRegisters.SuccessfulDataExchangesStates.AddRecord(RecordStructure);
		
	EndIf;
	
EndProcedure

Procedure IncreaseImportedObjectCounter()
	
	Increment(ImportedObjectCounterField);
	
EndProcedure

Function ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MetadataObject)
	Structure = New Structure();
	Structure.Insert("Name", Name);
	Structure.Insert("TypeName", TypeName);
	Structure.Insert("RefTypeString", RefTypeString);
	Structure.Insert("Manager", Manager);
	Structure.Insert("MetadateObject", MetadataObject);
	Structure.Insert("SearchByPredefinedItemsPossible", False);
	Structure.Insert("OCR");
	Return Structure;
EndFunction

Function ExchangePlanParametersStructure(Name, RefType, IsReferenceType, IsRegister)
	Structure = New Structure();
	Structure.Insert("Name",Name);
	Structure.Insert("RefType",RefType);
	Structure.Insert("IsReferenceType",IsReferenceType);
	Structure.Insert("IsRegister",IsRegister);
	Return Structure;
EndFunction

#EndRegion

#Region HandlerProcedures

Function PCRPropertyName(TabularSectionRow)
	
	If ValueIsFilled(TabularSectionRow.Source) Then
		Property = "_" + TrimAll(TabularSectionRow.Source);
	ElsIf ValueIsFilled(TabularSectionRow.Destination) Then 
		Property = "_" + TrimAll(TabularSectionRow.Destination);
	ElsIf ValueIsFilled(TabularSectionRow.ParameterForTransferName) Then
		Property = "_" + TrimAll(TabularSectionRow.ParameterForTransferName);
	Else
		Property = "";
	EndIf;
	
	Return Property;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Global handlers

Procedure ExecuteHandler_Conversion_AfterExchangeRulesImport()
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterExchangeRulesImportHandlerName);
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeDataExport(ExchangeFile, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeDataExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeGetChangedObjects(Recipient, BackgroundExchangeNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Recipient);
	HandlerParameters.Add(BackgroundExchangeNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeGetChangedObjectsHandlerName, HandlerParameters);
	
	Recipient = HandlerParameters[0];
	BackgroundExchangeNode = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterDataExport(ExchangeFile)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterDataExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule,
																IncomingData, OutgoingData, Object)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(Object);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeObjectExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	Rule = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	OutgoingData = HandlerParameters[5];
	Object = HandlerParameters[6];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterObjectExport(ExchangeFile, Object, OCRName, IncomingData,
															   OutgoingData, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterObjectExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Object = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	RefNode = HandlerParameters[5];
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeObjectConversion(HandlerParameters)
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeObjectConversionHandlerName, HandlerParameters);
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeSendDeletionInfo(Ref, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeSendDeletionInfoHandlerName, HandlerParameters);
	
	Ref = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeDataImport(ExchangeFile, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.BeforeDataImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterDataImport()
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.AfterDataImportHandlerName);
	
EndProcedure

Procedure ExecuteHandler_Conversion_BeforeImportObject(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
																GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																ObjectType, DontReplaceObject, WriteMode, PostingMode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(SN);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(RuleName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(GenerateNewNumberOrCodeIfNotSet);
	HandlerParameters.Add(ObjectTypeString);
	HandlerParameters.Add(ObjectType);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.BeforeObjectImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	SN = HandlerParameters[2];
	Source = HandlerParameters[3];
	RuleName = HandlerParameters[4];
	Rule = HandlerParameters[5];
	GenerateNewNumberOrCodeIfNotSet = HandlerParameters[6];
	ObjectTypeString = HandlerParameters[7];
	ObjectType = HandlerParameters[8];
	DontReplaceObject = HandlerParameters[9];
	WriteMode = HandlerParameters[10];
	PostingMode = HandlerParameters[11];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
															   ObjectIsModified, ObjectTypeName, ObjectFound)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(ObjectIsModified);
	HandlerParameters.Add(ObjectTypeName);
	HandlerParameters.Add(ObjectFound);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.AfterObjectImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	Ref = HandlerParameters[2];
	Object = HandlerParameters[3];
	ObjectParameters = HandlerParameters[4];
	ObjectIsModified = HandlerParameters[5];
	ObjectTypeName = HandlerParameters[6];
	ObjectFound = HandlerParameters[7];
	
EndProcedure

Procedure ExecuteHandler_Conversion_OnGetDeletionInfo(Object, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Object);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.OnGetDeletionInfoHandlerName, HandlerParameters);
	
	Object = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterParametersImport(ExchangeFile, Cancel, CancelReason)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CancelReason);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, "Conversion_AfterParameterImport", HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	CancelReason = HandlerParameters[2];
	
EndProcedure

Procedure ExecuteHandler_Conversion_AfterGetExchangeNodesInformation(Val ExchangeNodeDataImport)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeNodeDataImport);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Conversion.AfterReceiveExchangeNodeDetailsHandlerName, HandlerParameters);
	
	ExchangeNodeDataImport = HandlerParameters[0];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OCR handlers

Procedure Execute_OCR_HandlerBeforeObjectExport(ExchangeFile, Source, IncomingData, OutgoingData,
														OCRName, OCR, ExportedObjects, Cancel, ExportedDataKey,
														RememberExported, DontReplaceObjectOnImport,
														AllObjectsExported, GetRefNodeOnly, Destination,
														WriteMode, PostingMode, DontCreateIfNotFound)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(ExportedDataKey);
	HandlerParameters.Add(RememberExported);
	HandlerParameters.Add(DontReplaceObjectOnImport);
	HandlerParameters.Add(AllObjectsExported);
	HandlerParameters.Add(GetRefNodeOnly);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	HandlerParameters.Add(DontCreateIfNotFound);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	ExportedDataKey = HandlerParameters[8];
	RememberExported = HandlerParameters[9];
	DontReplaceObjectOnImport = HandlerParameters[10];
	AllObjectsExported = HandlerParameters[11];
	GetRefNodeOnly = HandlerParameters[12];
	Destination = HandlerParameters[13];
	WriteMode = HandlerParameters[14];
	PostingMode = HandlerParameters[15];
	DontCreateIfNotFound = HandlerParameters[16];
	
EndProcedure

Procedure Execute_OCR_HandlerOnObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
													 ExportedObjects, ExportedDataKey, Cancel, StandardProcessing,
													 Destination, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(ExportedDataKey);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(StandardProcessing);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	ExportedDataKey = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	StandardProcessing = HandlerParameters[9];
	Destination = HandlerParameters[10];
	RefNode = HandlerParameters[11];
	
EndProcedure

Procedure Execute_OCR_HandlerAfterObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
													   ExportedObjects, ExportedDataKey, Cancel, Destination, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(ExportedDataKey);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.AfterExportHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	ExportedDataKey = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Destination = HandlerParameters[9];
	RefNode = HandlerParameters[10];
	
EndProcedure

Procedure Execute_OCR_HandlerAfterObjectExportToExchangeFile(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
																  ExportedObjects, Destination, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.AfterExportToFileHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	Destination = HandlerParameters[7];
	RefNode = HandlerParameters[8];
	
EndProcedure

Procedure Execute_OCR_HandlerBeforeObjectImport(ExchangeFile, Cancel, SN, Source, RuleName, Rule,
														GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
														ObjectType,DontReplaceObject, WriteMode, PostingMode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(SN);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(RuleName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(GenerateNewNumberOrCodeIfNotSet);
	HandlerParameters.Add(ObjectTypeString);
	HandlerParameters.Add(ObjectType);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.BeforeImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	SN = HandlerParameters[2];
	Source = HandlerParameters[3];
	RuleName = HandlerParameters[4];
	Rule = HandlerParameters[5];
	GenerateNewNumberOrCodeIfNotSet = HandlerParameters[6];
	ObjectTypeString = HandlerParameters[7];
	ObjectType = HandlerParameters[8];
	DontReplaceObject = HandlerParameters[9];
	WriteMode = HandlerParameters[10];
	PostingMode = HandlerParameters[11];
	
EndProcedure

Procedure Execute_OCR_HandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(ObjectFound);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(ObjectIsModified);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.OnImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	ObjectFound = HandlerParameters[1];
	Object = HandlerParameters[2];
	DontReplaceObject = HandlerParameters[3];
	ObjectIsModified = HandlerParameters[4];
	
EndProcedure

Procedure Execute_OCR_HandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
													   ObjectIsModified, ObjectTypeName, ObjectFound, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(ObjectIsModified);
	HandlerParameters.Add(ObjectTypeName);
	HandlerParameters.Add(ObjectFound);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.AfterImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	Ref = HandlerParameters[2];
	Object = HandlerParameters[3];
	ObjectParameters = HandlerParameters[4];
	ObjectIsModified = HandlerParameters[5];
	ObjectTypeName = HandlerParameters[6];
	ObjectFound = HandlerParameters[7];
	
EndProcedure

Procedure Execute_OCR_HandlerSearchFieldsSequence(SearchVariantNumber, SearchProperties, ObjectParameters, StopSearch,
																ObjectRef, SetAllObjectSearchProperties,
																SearchPropertyNameString, HandlerName)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(SearchVariantNumber);
	HandlerParameters.Add(SearchProperties);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(StopSearch);
	HandlerParameters.Add(ObjectRef);
	HandlerParameters.Add(SetAllObjectSearchProperties);
	HandlerParameters.Add(SearchPropertyNameString);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, HandlerName, HandlerParameters);
		
	SearchVariantNumber = HandlerParameters[0];
	SearchProperties = HandlerParameters[1];
	ObjectParameters = HandlerParameters[2];
	StopSearch = HandlerParameters[3];
	ObjectRef = HandlerParameters[4];
	SetAllObjectSearchProperties = HandlerParameters[5];
	SearchPropertyNameString = HandlerParameters[6];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PCR handlers

Procedure Execute_PCR_HandlerBeforeExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
														 PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
														 OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, DontReplace,
														 ExportObject)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(DestinationType);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(Empty);
	HandlerParameters.Add(Expression);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(DontReplace);
	HandlerParameters.Add(ExportObject);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	DestinationType = HandlerParameters[10];
	OCRName = HandlerParameters[11];
	OCRNameExtDimensionType = HandlerParameters[12];
	Empty = HandlerParameters[13];
	Expression = HandlerParameters[14];
	PropertyCollectionNode = HandlerParameters[15];
	DontReplace = HandlerParameters[16];
	ExportObject = HandlerParameters[17];
	
EndProcedure

Procedure Execute_PCR_HandlerOnExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
													  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
													  ExtDimensionDimension, Empty, OCRName, PropertiesOCR,PropertyNode, PropertyCollectionNode,
													  OCRNameExtDimensionType, ExportObject)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(KeyAndValue);
	HandlerParameters.Add(ExtDimensionType);
	HandlerParameters.Add(ExtDimensionDimension);
	HandlerParameters.Add(Empty);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(PropertiesOCR);
	HandlerParameters.Add(PropertyNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(ExportObject);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	KeyAndValue = HandlerParameters[10];
	ExtDimensionType = HandlerParameters[11];
	ExtDimensionDimension = HandlerParameters[12];
	Empty = HandlerParameters[13];
	OCRName = HandlerParameters[14];
	PropertiesOCR = HandlerParameters[15];
	PropertyNode = HandlerParameters[16];
	PropertyCollectionNode = HandlerParameters[17];
	OCRNameExtDimensionType = HandlerParameters[18];
	ExportObject = HandlerParameters[19];
	
EndProcedure

Procedure Execute_PCR_HandlerAfterExportProperty(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
														PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
														ExtDimensionDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode,
														RefNode, PropertyCollectionNode, ExtDimensionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(KeyAndValue);
	HandlerParameters.Add(ExtDimensionType);
	HandlerParameters.Add(ExtDimensionDimension);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(PropertiesOCR);
	HandlerParameters.Add(PropertyNode);
	HandlerParameters.Add(RefNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ExtDimensionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.AfterExportHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	KeyAndValue = HandlerParameters[10];
	ExtDimensionType = HandlerParameters[11];
	ExtDimensionDimension = HandlerParameters[12];
	OCRName = HandlerParameters[13];
	OCRNameExtDimensionType = HandlerParameters[14];
	PropertiesOCR = HandlerParameters[15];
	PropertyNode = HandlerParameters[16];
	RefNode = HandlerParameters[17];
	PropertyCollectionNode = HandlerParameters[18];
	ExtDimensionNode = HandlerParameters[19];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PGCR handlers

Procedure Execute_PGCR_HandlerBeforeExportProcessing(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
														   PGCR, Cancel, ObjectCollection, DontReplace, PropertyCollectionNode, DontClear)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(ObjectCollection);
	HandlerParameters.Add(DontReplace);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(DontClear);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.BeforeExportProcessHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	ObjectCollection = HandlerParameters[8];
	DontReplace = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	DontClear = HandlerParameters[11];
	
EndProcedure

Procedure Execute_PGCR_HandlerBeforePropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
														  PGCR, Cancel, CollectionObject, PropertyCollectionNode, ObjectCollectionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ObjectCollectionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	CollectionObject = HandlerParameters[8];
	PropertyCollectionNode = HandlerParameters[9];
	ObjectCollectionNode = HandlerParameters[10];
	
EndProcedure

Procedure Execute_PGCR_HandlerOnPropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData, OCR,
													   PGCR, CollectionObject, ObjectCollectionNode, CollectionObjectNode,
													   PropertyCollectionNode, StandardProcessing)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(ObjectCollectionNode);
	HandlerParameters.Add(CollectionObjectNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(StandardProcessing);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	ObjectCollectionNode = HandlerParameters[8];
	CollectionObjectNode = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	StandardProcessing = HandlerParameters[11];
	
EndProcedure

Procedure Execute_PGCR_HandlerAfterPropertyExport(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
														 OCR, PGCR, Cancel, CollectionObject, ObjectCollectionNode,
														 PropertyCollectionNode, CollectionObjectNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(ObjectCollectionNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(CollectionObjectNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.AfterExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	CollectionObject = HandlerParameters[8];
	ObjectCollectionNode = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	CollectionObjectNode = HandlerParameters[11];
	
EndProcedure

Procedure Execute_PGCR_HandlerAfterExportProcessing(ExchangeFile, Source, Destination, IncomingData, OutgoingData,
														  OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Destination);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ObjectCollectionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.AfterExportProcessHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Destination = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	PropertyCollectionNode = HandlerParameters[8];
	ObjectCollectionNode = HandlerParameters[9];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// DER handlers

Procedure ExecuteHandler_DER_BeforeProcessRule(Cancel, OCRName, Rule, OutgoingData, DataSelection)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(DataSelection);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.BeforeProcessHandlerName, HandlerParameters);
	
	Cancel = HandlerParameters[0];
	OCRName = HandlerParameters[1];
	Rule = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	DataSelection = HandlerParameters[4];
	
EndProcedure

Procedure ExecuteHandler_DER_AfterProcessRule(OCRName, Rule, OutgoingData)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(OutgoingData);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.AfterProcessHandlerName, HandlerParameters);
	
	OCRName = HandlerParameters[0];
	Rule = HandlerParameters[1];
	OutgoingData = HandlerParameters[2];
	
EndProcedure

Procedure ExecuteHandler_DER_BeforeExportObject(ExchangeFile, Cancel, OCRName, Rule,
														IncomingData, OutgoingData, Object)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(Object);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	Rule = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	OutgoingData = HandlerParameters[5];
	Object = HandlerParameters[6];
	
EndProcedure

Procedure ExecuteHandler_DER_AfterExportObject(ExchangeFile, Object, OCRName, IncomingData,
													   OutgoingData, RefNode, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.AfterExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Object = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	RefNode = HandlerParameters[5];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// DPR handlers

Procedure ExecuteHandler_DPR_BeforeProcessRule(Rule, Cancel, OutgoingData, DataSelection)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(DataSelection);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.BeforeProcessHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OutgoingData = HandlerParameters[2];
	DataSelection = HandlerParameters[3];
	
EndProcedure

Procedure ExecuteHandler_DPR_BeforeDeleteObject(Rule, Object, Cancel, DeleteDirectly, IncomingData)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(DeleteDirectly);
	HandlerParameters.Add(IncomingData);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.BeforeDeleteHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	Object = HandlerParameters[1];
	Cancel = HandlerParameters[2];
	DeleteDirectly = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	
EndProcedure

Procedure ExecuteHandler_DPR_AfterProcessRule(Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, Rule.AfterProcessHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Parameter handlers

Procedure ExecuteHandler_Parameters_AfterParameterImport(Name, Value)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Name);
	HandlerParameters.Add(Value);
	
	HandlerName = "Parameters_[ParameterName]_AfterImportParameter";
	HandlerName = StrReplace(HandlerName, "[ParameterName]", Name);
	
	Common.ExecuteObjectMethod(
		ImportProcessing, HandlerName, HandlerParameters);
	
	Name = HandlerParameters[0];
	Value = HandlerParameters[1];
	
EndProcedure

#EndRegion

#Region Constants

Function ExchangeMessageFormatVersion()
	
	Return "3.1";
	
EndFunction

// Storage format version of exchange rules that is supported in the processing.
// 
//
// Exchange rules are retrieved from the file and saved in the infobase in storage format.
// Rule storage format can be obsolete. Rules need to be reread.
//
Function ExchangeRuleStorageFormatVersion()
	
	Return 2;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

Procedure GetPredefinedDataValues(Val OCR)
	
	OCR.PredefinedDataValues = New Map;
	
	For Each Item In OCR.PredefinedDataReadValues Do
		
		OCR.PredefinedDataValues.Insert(deGetValueByString(Item.Key, OCR.Source), Item.Value);
		
	EndDo;
	
EndProcedure

Function ConfigurationPresentationFromExchangeRules(DefinitionName)
	
	ConfigurationName = "";
	Conversion.Property("ConfigurationSynonym" + DefinitionName, ConfigurationName);
	
	If Not ValueIsFilled(ConfigurationName) Then
		Return "";
	EndIf;
	
	AccurateVersion = "";
	Conversion.Property("ConfigurationVersion" + DefinitionName, AccurateVersion);
	
	If ValueIsFilled(AccurateVersion) Then
		
		AccurateVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(AccurateVersion);
		
		ConfigurationName = ConfigurationName + " version " + AccurateVersion;
		
	EndIf;
	
	Return ConfigurationName;
	
EndFunction

Procedure FillPropertiesForSearch(DataStructure, PCR)
	
	For Each FieldsString In PCR Do
		
		If FieldsString.IsFolder Then
						
			If FieldsString.DestinationKind = "TabularSection" 
				OR StrFind(FieldsString.DestinationKind, "RecordSet") > 0 Then
				
				DestinationStructureName = FieldsString.Destination + ?(FieldsString.DestinationKind = "TabularSection", "TabularSection", "RecordSet");
				
				InternalStructure = DataStructure[DestinationStructureName];
				
				If InternalStructure = Undefined Then
					InternalStructure = New Map();
				EndIf;
				
				DataStructure[DestinationStructureName] = InternalStructure;
				
			Else
				
				InternalStructure = DataStructure;	
				
			EndIf;
			
			FillPropertiesForSearch(InternalStructure, FieldsString.GroupRules);
									
		Else
			
			If IsBlankString(FieldsString.DestinationType)	Then
				
				Continue;
				
			EndIf;
			
			DataStructure[FieldsString.Destination] = FieldsString.DestinationType;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteExcessiveItemsFromMap(DataStructure)
	
	For Each Item In DataStructure Do
		
		If TypeOf(Item.Value) = MapType Then
			
			DeleteExcessiveItemsFromMap(Item.Value);
			
			If Item.Value.Count() = 0 Then
				DataStructure.Delete(Item.Key);
			EndIf;
			
		EndIf;		
		
	EndDo;		
	
EndProcedure

Procedure FillInformationByDestinationDataTypes(DataStructure, Rules)
	
	For Each Row In Rules Do
		
		If IsBlankString(Row.Destination) Then
			Continue;
		EndIf;
		
		StructureData = DataStructure[Row.Destination];
		If StructureData = Undefined Then
			
			StructureData = New Map();
			DataStructure[Row.Destination] = StructureData;
			
		EndIf;
		
		// Going through search fields and other property conversion rules, and saving data types.
		FillPropertiesForSearch(StructureData, Row.SearchProperties);
				
		// Properties
		FillPropertiesForSearch(StructureData, Row.Properties);
		
	EndDo;
	
	DeleteExcessiveItemsFromMap(DataStructure);	
	
EndProcedure

Procedure CreateStringWithPropertyTypes(XMLWriter, PropertyTypes)
	
	If TypeOf(PropertyTypes.Value) = MapType Then
		
		If PropertyTypes.Value.Count() = 0 Then
			Return;
		EndIf;
		
		XMLWriter.WriteStartElement(PropertyTypes.Key);
		
		For Each Item In PropertyTypes.Value Do
			CreateStringWithPropertyTypes(XMLWriter, Item);
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	Else		
		
		deWriteElement(XMLWriter, PropertyTypes.Key, PropertyTypes.Value);
		
	EndIf;
	
EndProcedure

Function CreateTypesStringForDestination(DataStructure)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement("DataTypeInformation");	
	
	For Each Row In DataStructure Do
		
		XMLWriter.WriteStartElement("DataType");
		SetAttribute(XMLWriter, "Name", Row.Key);
		
		For Each SubordinationRow In Row.Value Do
			
			CreateStringWithPropertyTypes(XMLWriter, SubordinationRow);	
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndDo;	
	
	XMLWriter.WriteEndElement();
	
	ResultString = XMLWriter.Close();
	Return ResultString;
	
EndFunction

Procedure ImportSingleTypeData(ExchangeRules, TypeMap, LocalItemName)
	
	NodeName = LocalItemName;
	
	ExchangeRules.Read();
	
	If (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
		
		ExchangeRules.Read();
		Return;
		
	ElsIf ExchangeRules.NodeType = XMLNodeTypeStartElement Then
			
		// this is a new item
		NewMap = New Map;
		TypeMap.Insert(NodeName, NewMap);
		
		ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);
		ExchangeRules.Read();
		
	Else
		TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
		ExchangeRules.Read();
	EndIf;	
	
	ImportTypeMapForSingleType(ExchangeRules, TypeMap);
	
EndProcedure

Procedure ImportTypeMapForSingleType(ExchangeRules, TypeMap)
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
		    Break;
			
		EndIf;
		
		// Reading the element start
		ExchangeRules.Read();
		
		If ExchangeRules.NodeType = XMLNodeTypeStartElement Then
			
			// this is a new item
			NewMap = New Map;
			TypeMap.Insert(NodeName, NewMap);
			
			ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);			
			
		Else
			TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
			ExchangeRules.Read();
		EndIf;	
		
	EndDo;	
	
EndProcedure

Procedure ImportDataTypeInfo()
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "DataType" Then
			
			TypeName = deAttribute(ExchangeFile, StringType, "Name");
			
			TypeMap = New Map;
			DataForImportTypeMap().Insert(Type(TypeName), TypeMap);

			ImportTypeMapForSingleType(ExchangeFile, TypeMap);	
			
		ElsIf (NodeName = "DataTypeInformation") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ImportDataExchangeParameterValues()
	
	Name = deAttribute(ExchangeFile, StringType, "Name");
	
	PropertyType = PropertyTypeByAdditionalData(Undefined, Name);
	
	Value = ReadProperty(PropertyType);
	
	Parameters.Insert(Name, Value);	
	
	AfterParameterImportAlgorithm = "";
	If EventsAfterParametersImport.Property(Name, AfterParameterImportAlgorithm)
		AND Not IsBlankString(AfterParameterImportAlgorithm) Then
		
		If ImportHandlersDebug Then
			
			ExecuteHandler_Parameters_AfterParameterImport(Name, Value);
			
		Else
			
			Execute(AfterParameterImportAlgorithm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ImportCustomSearchFieldInfo()
	
	RuleName = "";
	SearchSetup = "";
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "RuleName" Then
			
			RuleName = deElementValue(ExchangeFile, StringType);
			
		ElsIf NodeName = "SearchSettings" Then
			
			SearchSetup = deElementValue(ExchangeFile, StringType);
			CustomSearchFieldInfoOnDataImport.Insert(RuleName, SearchSetup);	
			
		ElsIf (NodeName = "CustomSearchSettings") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

// Imports exchange rules according to the format.
//
// Parameters:
//  Source       - an object where the exchange rules are imported from.
//  SourceType   - a string specifying a source type: "XMLFile", "ReadingXML", "String".
// 
Procedure ImportExchangeRules(Source="",
									SourceType="XMLFile",
									ErrorMessageString = "",
									ImportRuleHeaderOnly = False) Export
	
	InitManagersAndMessages();
	
	HasBeforeExportObjectGlobalHandler    = False;
	HasAfterExportObjectGlobalHandler     = False;
	
	HasBeforeConvertObjectGlobalHandler = False;
	
	HasBeforeImportObjectGlobalHandler    = False;
	HasAfterObjectImportGlobalHandler     = False;
	
	CreateConversionStructure();
	
	PropertyConversionRuleTable = New ValueTable;
	InitPropertyConversionRuleTable(PropertyConversionRuleTable);
	
	// Perhaps, embedded exchange rules are selected (one of templates.
	
	ExchangeRulesTempFileName = "";
	If IsBlankString(Source) Then
		
		Source = ExchangeRuleFileName;
		
	EndIf;
	
	If SourceType="XMLFile" Then
		
		If IsBlankString(Source) Then
			ErrorMessageString = WriteToExecutionProtocol(12);
			Return; 
		EndIf;
		
		File = New File(Source);
		If Not File.Exist() Then
			ErrorMessageString = WriteToExecutionProtocol(3);
			Return; 
		EndIf;
		
		ExchangeRules = New XMLReader();
		ExchangeRules.OpenFile(Source);
		ExchangeRules.Read();
		
	ElsIf SourceType="String" Then
		
		ExchangeRules = New XMLReader();
		ExchangeRules.SetString(Source);
		ExchangeRules.Read();
		
	ElsIf SourceType="XMLReader" Then
		
		ExchangeRules = Source;
		
	EndIf;
	
	If Not ((ExchangeRules.LocalName = "ExchangeRules") AND (ExchangeRules.NodeType = XMLNodeTypeStartElement)) Then
		ErrorMessageString = WriteToExecutionProtocol(7);
		Return;
	EndIf;
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement("ExchangeRules");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		// Conversion attributes
		If NodeName = "FormatVersion" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("FormatVersion", Value);
			
			XMLWriter.WriteStartElement("FormatVersion");
			Page = XMLString(Value);
			
			XMLWriter.WriteText(Page);
			XMLWriter.WriteEndElement();
			
		ElsIf NodeName = "ID" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("ID",                   Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Description" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Description",         Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "CreationDateTime" Then
			Value = deElementValue(ExchangeRules, DateType);
			Conversion.Insert("CreationDateTime",    Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Source" Then
			
			SourcePlatformVersion = ExchangeRules.GetAttribute ("PlatformVersion");
			SourceConfigurationSynonym = ExchangeRules.GetAttribute ("ConfigurationSynonym");
			SourceConfigurationVersion = ExchangeRules.GetAttribute ("ConfigurationVersion");
			
			Conversion.Insert("SourcePlatformVersion", SourcePlatformVersion);
			Conversion.Insert("SourceConfigurationSynonym", SourceConfigurationSynonym);
			Conversion.Insert("SourceConfigurationVersion", SourceConfigurationVersion);
			
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Source",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
			
		ElsIf NodeName = "Destination" Then
			
			DestinationPlatformVersion = ExchangeRules.GetAttribute ("PlatformVersion");
			DestinationConfigurationSynonym = ExchangeRules.GetAttribute ("ConfigurationSynonym");
			DestinationConfigurationVersion = ExchangeRules.GetAttribute ("ConfigurationVersion");
			
			Conversion.Insert("DestinationPlatformVersion", DestinationPlatformVersion);
			Conversion.Insert("DestinationConfigurationSynonym", DestinationConfigurationSynonym);
			Conversion.Insert("DestinationConfigurationVersion", DestinationConfigurationVersion);
			
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Destination",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
			
			If ImportRuleHeaderOnly Then
				Return;
			EndIf;
			
		ElsIf NodeName = "CompatibilityMode" Then
			// For backward compatibility.
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Comment" Then
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "MainExchangePlan" Then
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Parameters" Then
			ImportParameters(ExchangeRules, XMLWriter)

		// Conversion events
		
		ElsIf NodeName = "" Then
		
		ElsIf NodeName = "AfterImportExchangeRules" Then
			Conversion.Insert("AfterImportExchangeRules", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterExchangeRulesImportHandlerName","Conversion_AfterExchangeRuleImport");
				
		ElsIf NodeName = "BeforeExportData" Then
			Conversion.Insert("BeforeExportData", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeDataExportHandlerName","Conversion_BeforeDataExport");
			
		ElsIf NodeName = "BeforeGetChangedObjects" Then
			Conversion.Insert("BeforeGetChangedObjects", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeGetChangedObjectsHandlerName","Conversion_BeforeGetChangedObjects");
			
		ElsIf NodeName = "AfterGetExchangeNodesInformation" Then
			
			Conversion.Insert("AfterGetExchangeNodesInformation", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterReceiveExchangeNodeDetailsHandlerName","Conversion_AfterGetExchangeNodeDetails");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterGetExchangeNodesInformation);
						
		ElsIf NodeName = "AfterExportData" Then
			Conversion.Insert("AfterExportData",  deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterDataExportHandlerName","Conversion_AfterDataExport");
			
		ElsIf NodeName = "BeforeSendDeletionInfo" Then
			Conversion.Insert("BeforeSendDeletionInfo",  deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeSendDeletionInfoHandlerName","Conversion_BeforeSendDeletionInfo");

		ElsIf NodeName = "BeforeExportObject" Then
			Conversion.Insert("BeforeExportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectExportHandlerName","Conversion_BeforeExportObject");
			HasBeforeExportObjectGlobalHandler = Not IsBlankString(Conversion.BeforeExportObject);

		ElsIf NodeName = "AfterExportObject" Then
			Conversion.Insert("AfterExportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterObjectExportHandlerName","Conversion_AfterExportObject");
			HasAfterExportObjectGlobalHandler = Not IsBlankString(Conversion.AfterExportObject);

		ElsIf NodeName = "BeforeImportObject" Then
			Conversion.Insert("BeforeImportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectImportHandlerName","Conversion_BeforeImportObject");
			HasBeforeImportObjectGlobalHandler = Not IsBlankString(Conversion.BeforeImportObject);
			deWriteElement(XMLWriter, NodeName, Conversion.BeforeImportObject);

		ElsIf NodeName = "AfterImportObject" Then
			Conversion.Insert("AfterImportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterObjectImportHandlerName","Conversion_AfterImportObject");
			HasAfterObjectImportGlobalHandler = Not IsBlankString(Conversion.AfterImportObject);
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportObject);

		ElsIf NodeName = "BeforeConvertObject" Then
			Conversion.Insert("BeforeConvertObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectConversionHandlerName","Conversion_BeforeObjectConversion");
			HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);
			
		ElsIf NodeName = "BeforeImportData" Then
			Conversion.BeforeImportData = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("BeforeDataImportHandlerName","Conversion_BeforeDataImport");
			deWriteElement(XMLWriter, NodeName, Conversion.BeforeImportData);
			
		ElsIf NodeName = "AfterImportData" Then
            Conversion.AfterImportData = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("AfterDataImportHandlerName","Conversion_AfterDataImport");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportData);
			
		ElsIf NodeName = "AfterImportParameters" Then
            Conversion.Insert("AfterImportParameters", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterParametesrImportHandlerName","Conversion_AfterParameterImport");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportParameters);
			
		ElsIf NodeName = "OnGetDeletionInfo" Then
            Conversion.Insert("OnGetDeletionInfo", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("OnGetDeletionInfoHandlerName","Conversion_OnGetDeletionInfo");
			deWriteElement(XMLWriter, NodeName, Conversion.OnGetDeletionInfo);
			
		ElsIf NodeName = "DeleteMappedObjectsFromDestinationOnDeleteFromSource" Then
            Conversion.DeleteMappedObjectsFromDestinationOnDeleteFromSource = deElementValue(ExchangeRules, BooleanType);
						
		// Rules
		
		ElsIf NodeName = "DataExportRules" Then
			If ExchangeMode = "Load" Then
				deSkip(ExchangeRules);
			Else
				ImportExportRules(ExchangeRules);
			EndIf; 
			
		ElsIf NodeName = "ObjectConversionRules" Then
			ImportConversionRules(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "DataClearingRules" Then
			ImportClearingRules(ExchangeRules, XMLWriter)
		
		ElsIf NodeName = "ObjectsRegistrationRules" Then
			deSkip(ExchangeRules);
			
		// Algorithms, Queries, DataProcessors.
		
		ElsIf NodeName = "Algorithms" Then
			ImportAlgorithms(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "Queries" Then
			ImportQueries(ExchangeRules, XMLWriter);

		ElsIf NodeName = "DataProcessors" Then
			ImportDataProcessors(ExchangeRules, XMLWriter);
			
		// Exit
		ElsIf (NodeName = "ExchangeRules") AND (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			If ExchangeMode <> "Load" Then
				ExchangeRules.Close();
			EndIf;
			Break;

			
		// Format error
		Else
			ErrorMessageString = WriteToExecutionProtocol(7);
			Return;
		EndIf;
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLRules = XMLWriter.Close();
	
	// Deleting the temporary rule file.
	If Not IsBlankString(ExchangeRulesTempFileName) Then
		Try
			DeleteFiles(ExchangeRulesTempFileName);
		Except
			WriteLogEvent(NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	If ImportRuleHeaderOnly Then
		Return;
	EndIf;
	
	// Information on destination data types is required for quick data import.
	DataStructure = New Map();
	FillInformationByDestinationDataTypes(DataStructure, ConversionRulesTable);
	
	TypesForDestinationString = CreateTypesStringForDestination(DataStructure);
	
	SecurityProfileName = InitializeDataProcessors();
	
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	// Event call is required after importing the exchange rules.
	AfterExchangeRulesImportEventText = "";
	If ExchangeMode <> "Load" AND Conversion.Property("AfterImportExchangeRules", AfterExchangeRulesImportEventText)
		AND Not IsBlankString(AfterExchangeRulesImportEventText) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_AfterExchangeRulesImport();
				
			Else
				
				Execute(AfterExchangeRulesImportEventText);
				
			EndIf;
			
		Except
			ErrorMessageString = WriteErrorInfoConversionHandlers(75, ErrorDescription(), NStr("ru = 'ПослеЗагрузкиПравилОбмена (конвертация)'; en = 'AfterImportExchangeRules (conversion)'; pl = 'AfterImportOfExchangeRules (konwertowanie)';de = 'AfterImportExchangeRules (Konvertierung)';ro = 'AfterImportExchangeRules (conversie)';tr = 'İçeriAktarmaSonrasıDeğişimKuralları (dönüştürme)'; es_ES = 'AfterImportExchangeRules (conversión)'"));
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
	EndIf;
	
	InitializeInitialParameterValues();
	
EndProcedure

Procedure ProcessNewItemReadEnd(LastImportObject = Undefined)
	
	IncreaseImportedObjectCounter();
	
	If ImportedObjectCounter() % 100 = 0
		AND GlobalNotWrittenObjectStack.Count() > 100 Then
		
		ExecuteWriteNotWrittenObjects();
		
	EndIf;
	
	// When importing in external connection mode, transaction management is performed from the management application.
	If Not DataImportedOverExternalConnection Then
		
		If UseTransactions
			AND ObjectsPerTransaction > 0 
			AND ImportedObjectCounter() % ObjectsPerTransaction = 0 Then
			
			CommitTransaction();
			BeginTransaction();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteObjectByLink(Ref, ErrorMessageString)
	
	Object = Ref.GetObject();
	
	If Object = Undefined Then
		Return;
	EndIf;
	
	If DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	SetDataExchangeLoad(Object);
	
	If Not IsBlankString(Conversion.OnGetDeletionInfo) Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_OnGetDeletionInfo(Object, Cancel);
				
			Else
				
				Execute(Conversion.OnGetDeletionInfo);
				
			EndIf;
			
		Except
			ErrorMessageString = WriteErrorInfoConversionHandlers(77, ErrorDescription(), NStr("ru = 'ПриПолученииИнформацииОбУдалении (конвертация)'; en = 'OnGetDeletionInfo (conversion)'; pl = 'WhenGettingInformationAboutDeleting (konwertowanie)';de = 'BeimAbrufenVonInformationenZumLöschen (Konvertierung)';ro = 'ПриПолученииИнформацииОбУдалении (conversie)';tr = 'SilmeBilgileriniAlırken (Dönüştürme)'; es_ES = 'WhenGettingInformationAboutDeleting (Conversión)'"));
			Cancel = True;
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	DeleteObject(Object, True);
	
EndProcedure

Procedure ReadObjectDeletion(ErrorMessageString)
	
	SourceTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
	DestinationTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
	
	UUIDAsString = deAttribute(ExchangeFile, StringType, "UUID");
	
	ReplaceUUIDIfNecessary(UUIDAsString, SourceTypeString, DestinationTypeString, True);
	
	PropertyStructure = Managers[Type(SourceTypeString)];
	
	Ref = PropertyStructure.Manager.GetRef(New UUID(UUIDAsString));
	
	DeleteObjectByLink(Ref, ErrorMessageString);
	
EndProcedure

Procedure ExecuteSelectiveMessageReader(TablesToImport)
	
	If TablesToImport.Count() = 0 Then
		Return;
	EndIf;
	
	MessageReader = Undefined;
	Try
		
		SetErrorFlag(False);
		
		InitializeCommentsOnDataExportAndImport();
		
		CustomSearchFieldInfoOnDataImport = New Map;
		AdditionalSearchParameterMap = New Map;
		ConversionRulesMap = New Map;
		
		// Initializing exchange logging.
		InitializeKeepExchangeProtocol();
		
		If ProcessedObjectsCountToUpdateStatus = 0 Then
			ProcessedObjectsCountToUpdateStatus = 100;
		EndIf;
		
		GlobalNotWrittenObjectStack = New Map;
		
		ImportedObjectCounterField = Undefined;
		LastSearchByRefNumber  = 0;
		
		InitManagersAndMessages();
		
		StartReadMessage(MessageReader, True);
		
		If UseTransactions Then
			BeginTransaction();
		EndIf;
		Try
			
			ReadDataForTables(TablesToImport);
			
			If ErrorFlag() Then
				Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
			EndIf;
			
			// Delayed writinging of what was not written.
			ExecuteWriteNotWrittenObjects();
			
			ExecuteHandlerAfterDataImport();
			
			If ErrorFlag() Then
				Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
			EndIf;
			
			If UseTransactions Then
				CommitTransaction();
			EndIf;
		Except
			If UseTransactions Then
				RollbackTransaction();
			EndIf;
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
		// Posting documents in queue.
		ExecuteDeferredDocumentsPosting();
		ExecuteDeferredObjectsWrite();
		
		FinishMessageReader(MessageReader);
		
	Except
		If MessageReader <> Undefined
			AND MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
		EndIf;
	EndTry;
	
	FinishKeepExchangeProtocol();
	
EndProcedure

Procedure ReadData(MessageReader)
	
	ErrorMessageString = "";
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
			LastImportObject = ReadObject();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			// register record set
			LastImportObject = ReadRegisterRecordSet();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			// Processing of object deletion from infobase.
			ReadObjectDeletion(ErrorMessageString);
			
			deSkip(ExchangeFile, "ObjectDeletion");
			
			ProcessNewItemReadEnd();
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			HasObjectRegistrationDataAdjustment = True;
			
			ReadMappingInfoAdjustment();
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(MessageReader);
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // exiting
			
		Else
			
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
			
		EndIf;
		
		// Abort the file read cycle if an importing error occurs.
		If ErrorFlag() Then
			Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadDataForTables(TablesToImport)
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			ObjectTypeString = deAttribute(ExchangeFile, StringType, "Type");
			
			If ObjectTypeString = "ConstantsSet" Then
				
				ConstantName = deAttribute(ExchangeFile, StringType, "ConstantName");
				
				SourceTypeString = ConstantName;
				DestinationTypeString = ConstantName;
				
			Else
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				
				OCR = Rules[RuleName];
				
				SourceTypeString = OCR.SourceType;
				DestinationTypeString = OCR.DestinationType;
				
			EndIf;
			
			DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, False);
			
			If TablesToImport.Find(DataTableKey) <> Undefined Then
				
				If DataImportToInfobaseMode() Then // Import to the infobase.
					
					ProcessNewItemReadEnd(ReadObject());
					
				Else // Import into the values table.
					
					UUIDAsString = "";
					
					LastImportObject = ReadObject(UUIDAsString);
					
					If LastImportObject <> Undefined Then
						
						ExchangeMessageDataTable = DataTablesExchangeMessages().Get(DataTableKey);
						
						TableRow = ExchangeMessageDataTable.Find(UUIDAsString, UUIDColumnName());
						
						If TableRow = Undefined Then
							
							IncreaseImportedObjectCounter();
							
							TableRow = ExchangeMessageDataTable.Add();
							
							TableRow[ColumnNameTypeAsString()]              = DestinationTypeString;
							TableRow["Ref"]                            = LastImportObject.Ref;
							TableRow[UUIDColumnName()] = UUIDAsString;
							
						EndIf;
						
						// Filling in object property values.
						FillPropertyValues(TableRow, LastImportObject);
						
					EndIf;
					
				EndIf;
				
			Else
				
				deSkip(ExchangeFile, NodeName);
				
			EndIf;
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			If DataImportToInfobaseMode() Then
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				
				OCR = Rules[RuleName];
				
				SourceTypeString = OCR.SourceType;
				DestinationTypeString = OCR.DestinationType;
				
				DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, False);
				
				If TablesToImport.Find(DataTableKey) <> Undefined Then
					
					ProcessNewItemReadEnd(ReadRegisterRecordSet());
					
				Else
					
					deSkip(ExchangeFile, NodeName);
					
				EndIf;
				
			Else
				
				deSkip(ExchangeFile, NodeName);
				
			EndIf;
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			DestinationTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			SourceTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, True);
			
			If TablesToImport.Find(DataTableKey) <> Undefined Then
				
				If DataImportToInfobaseMode() Then // Import to the infobase.
					
					// Processing of object deletion from infobase.
					ReadObjectDeletion("");
					
					ProcessNewItemReadEnd();
					
				Else // Import into the values table.
					
					UUIDAsString = deAttribute(ExchangeFile, StringType, "UUID");
					
					// Adding object deletion into the message data table.
					ExchangeMessageDataTable = DataTablesExchangeMessages().Get(DataTableKey);
					
					TableRow = ExchangeMessageDataTable.Find(UUIDAsString, UUIDColumnName());
					
					If TableRow = Undefined Then
						
						IncreaseImportedObjectCounter();
						
						TableRow = ExchangeMessageDataTable.Add();
						
						// Filling in the values of all table fields with default values.
						For Each Column In ExchangeMessageDataTable.Columns Do
							
							// filter
							If    Column.Name = ColumnNameTypeAsString()
								OR Column.Name = UUIDColumnName()
								OR Column.Name = "Ref" Then
								Continue;
							EndIf;
							
							If Column.ValueType.ContainsType(StringType) Then
								
								TableRow[Column.Name] = NStr("ru = 'Удаление объекта'; en = 'Object deletion'; pl = 'Usuwanie obiektu';de = 'Objekt löschen';ro = 'Ștergerea obiectului';tr = 'Nesneyi silme'; es_ES = 'Eliminación del objeto'");
								
							EndIf;
							
						EndDo;
						
						PropertyStructure = Managers[Type(DestinationTypeString)];
						
						ObjectToDeleteRef = PropertyStructure.Manager.GetRef(New UUID(UUIDAsString));
						
						TableRow[ColumnNameTypeAsString()]              = DestinationTypeString;
						TableRow["Ref"]                            = ObjectToDeleteRef;
						TableRow[UUIDColumnName()] = UUIDAsString;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			deSkip(ExchangeFile, NodeName); // Skipping item in selective message read mode.
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			deSkip(ExchangeFile, NodeName); // Skipping item in selective message read mode.
			
		ElsIf NodeName = "CommonNodeData" Then
			
			deSkip(ExchangeFile, NodeName); // Skipping item in selective message read mode.
			
		ElsIf (NodeName = "ExchangeFile") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // exiting
			
		Else
			
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
			
		EndIf;
		
		// Abort the file read cycle if an error occurs.
		If ErrorFlag() Then
			Raise NStr("ru = 'Возникли ошибки при загрузке данных.'; en = 'Data import errors.'; pl = 'Wystąpiły błędy podczas importu danych.';de = 'Beim Importieren von Daten sind Fehler aufgetreten.';ro = 'Au apărut erori la importul datelor.';tr = 'Veriler içe aktarılırken hatalar oluştu.'; es_ES = 'Errores ocurridos al importar los datos.'");
		EndIf;
		
	EndDo;
	
EndProcedure

// A classifier is a catalog, a chart of characteristic types, a chart of accounts, a CCT, which 
// have the following flags selected in OCR: SynchronizeByID AND SearchBySearchFieldsIfNotFoundByID.
//
Function IsClassifierObject(ObjectTypeString, OCR)
	
	ObjectKind = ObjectTypeString;
	Position = StrFind(ObjectKind, ".");
	If Position > 0 Then
		ObjectKind = Left(ObjectKind, Position - 1);
	EndIf;
	
	If    ObjectKind = "CatalogRef"
		Or ObjectKind = "ChartOfCharacteristicTypesRef"
		Or ObjectKind = "ChartOfAccountsRef"
		Or ObjectKind = "ChartOfCalculationTypesRef" Then
		Return OCR.SynchronizeByID AND OCR.SearchBySearchFieldsIfNotFoundByID
	EndIf; 
	
	Return False;
EndFunction

Procedure ReadDataInAnalysisMode(MessageReader, AnalysisParameters = Undefined)
	
	// Default parameters
	StatisticsCollectionParameters = New Structure("CollectClassifiersStatistics", False);
	If AnalysisParameters <> Undefined Then
		FillPropertyValues(StatisticsCollectionParameters, AnalysisParameters);
	EndIf;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			ObjectTypeString = deAttribute(ExchangeFile, StringType, "Type");
			
			If ObjectTypeString <> "ConstantsSet" Then
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				OCR        = Rules[RuleName];
				
				If StatisticsCollectionParameters.CollectClassifiersStatistics AND IsClassifierObject(ObjectTypeString, OCR) Then
					// New behavior
					CollectStatistics = True;
					IsClassifier   = True;
					
				ElsIf Not (OCR.SynchronizeByID AND OCR.SearchBySearchFieldsIfNotFoundByID) AND OCR.SynchronizeByID Then
					// Compatibility branch.
					// Objects with automatic mapping during the exchange (classifiers) do not display in the statistic 
					// information table. Statistic information gathering for the objects is not required.
					// 

					// Objects that are identified by the search fields rather than by a reference UUID are not 
					// displayed.
					CollectStatistics = True;
					IsClassifier   = False;
					
				Else 
					CollectStatistics = False;
					
				EndIf;
				
				If CollectStatistics Then
					TableRow = PackageHeaderDataTable().Add();
					
					TableRow.ObjectTypeString = ObjectTypeString;
					TableRow.ObjectCountInSource = 1;
					
					TableRow.DestinationTypeString = OCR.DestinationType;
					TableRow.SourceTypeString = OCR.SourceType;
					
					TableRow.SearchFields  = ObjectMappingMechanismSearchFields(OCR.SearchFields);
					TableRow.TableFields = OCR.TableFields;
					
					TableRow.SynchronizeByID    = OCR.SynchronizeByID;
					TableRow.UsePreview = OCR.SynchronizeByID;
					TableRow.IsClassifier   = IsClassifier;
					TableRow.IsObjectDeletion = False;

				EndIf;
				
			EndIf;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			TableRow = PackageHeaderDataTable().Add();
			
			TableRow.DestinationTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			TableRow.SourceTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			TableRow.ObjectTypeString = TableRow.DestinationTypeString;
			
			TableRow.ObjectCountInSource = 1;
			
			TableRow.SynchronizeByID = False;
			TableRow.UsePreview = True;
			TableRow.IsClassifier = False;
			TableRow.IsObjectDeletion = True;
			
			TableRow.SearchFields = ""; // Search fields assignes in object mapping processing.
			
			// specifying values for TableFields column  Getting description of all configuration metadata 
			// object fields.
			ObjectType = Type(TableRow.ObjectTypeString);
			MetadataObject = Metadata.FindByType(ObjectType);
			
			SubstringsArray = ObjectPropertiesDescriptionTable(MetadataObject).UnloadColumn("Name");
			
			// Deleting field Reference from visible table fields
			CommonClientServer.DeleteValueFromArray(SubstringsArray, "Ref");
			
			TableRow.TableFields = StrConcat(SubstringsArray, ",");
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			HasObjectRegistrationDataAdjustment = True;
			
			ReadMappingInfoAdjustment();
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(MessageReader);
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") AND (ExchangeFile.NodeType = XMLNodeType.EndElement) Then
			
			Break; // exit
			
		Else
			
			Raise NStr("ru = 'Ошибка формата сообщения обмена.'; en = 'Exchange message format error.'; pl = 'Błąd formatu wiadomości wymiany';de = 'Fehler im Austausch Nachrichtenformat.';ro = 'Eroare în formatul mesajului de schimb.';tr = 'Değişim mesajı biçiminde hata.'; es_ES = 'Error en el formato del mensaje de intercambio.'");
			
		EndIf;
		
		// Abort the file read cycle if an error occurs.
		If ErrorFlag() Then
			Raise NStr("ru = 'Возникли ошибки при анализе данных.'; en = 'Data analysis errors.'; pl = 'Wystąpiły błędy podczas analizy danych.';de = 'Bei der Datenanalyse sind Fehler aufgetreten.';ro = 'Au apărut erori la analiza datelor.';tr = 'Veri analiz edilirken hatalar oluştu.'; es_ES = 'Errores ocurridos al analizar los datos.'");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadDataInExternalConnectionMode(MessageReader)
	
	ErrorMessageString = "";
	ObjectsToImportCount = ObjectsToImportCountExternalConnection;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			LastImportObject = ReadObject();
			
			ProcessNewItemReadEnd(LastImportObject);
			
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			// register record set
			LastImportObject = ReadRegisterRecordSet();
			
			ProcessNewItemReadEnd(LastImportObject);
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
		ElsIf NodeName = "ObjectDeletion" Then
			
			// Processing of object deletion from infobase.
			ReadObjectDeletion(ErrorMessageString);
			
			deSkip(ExchangeFile, "ObjectDeletion");
			
			ProcessNewItemReadEnd();
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "CustomSearchSettings" Then
			
			ImportCustomSearchFieldInfo();
			
		ElsIf NodeName = "DataTypeInformation" Then
			
			If DataForImportTypeMap().Count() > 0 Then
				
				deSkip(ExchangeFile, NodeName);
				
			Else
				ImportDataTypeInfo();
			EndIf;
			
		ElsIf NodeName = "ParameterValue" Then	
			
			ImportDataExchangeParameterValues();
			
		ElsIf NodeName = "AfterParameterExportAlgorithm" Then
			
			Cancel = False;
			CancelReason = "";
			
			AlgorithmText = deElementValue(ExchangeFile, StringType);
			
			If Not IsBlankString(AlgorithmText) Then
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteHandler_Conversion_AfterParametersImport(ExchangeFile, Cancel, CancelReason);
						
					Else
						
						Execute(AlgorithmText);
						
					EndIf;
					
					If Cancel = True Then
						
						If Not IsBlankString(CancelReason) Then
							
							MessageString = NStr("ru = 'Загрузка данных отменена по причине: %1'; en = 'The data import is canceled. Reason: %1'; pl = 'Wczytywanie danych jest skasowane z powodu: %1';de = 'Der Datenimport wurde abgebrochen als: %1';ro = 'Importul de date a fost anulat din motivul: %1';tr = 'Veri içe aktarımı aşağıdaki nedenle iptal edildi: %1'; es_ES = 'Importación de datos se ha cancelado como: %1'");
							MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CancelReason);
							Raise MessageString;
						Else
							Raise NStr("ru = 'Загрузка данных отменена'; en = 'The data import is canceled.'; pl = 'Import danych został anulowany';de = 'Der Datenimport wurde abgebrochen';ro = 'Importul de date este anulat';tr = 'Verinin içe aktarımı iptal edildi'; es_ES = 'Importación de datos se ha cancelado'");
						EndIf;
						
					EndIf;
					
				Except
					
					WP = ExchangeProtocolRecord(78, ErrorDescription());
					WP.Handler     = "AfterImportParameters";
					ErrorMessageString = WriteToExecutionProtocol(78, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "ExchangeData" Then
			
			ReadDataViaExchange(MessageReader, False);
			
			deSkip(ExchangeFile, NodeName);
			
			If ErrorFlag() Then
				Break;
			EndIf;
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(Undefined);
			
			deSkip(ExchangeFile, NodeName);
			
			If ErrorFlag() Then
				Break;
			EndIf;
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			ReadMappingInfoAdjustment();
			
			HasObjectRegistrationDataAdjustment = True;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") AND (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // exiting
			
		Else
			
			deSkip(ExchangeFile, NodeName);
			
		EndIf;
		
		// Abort the file read cycle if an importing error occurs.
		If ErrorFlag() Then
			Break;
		EndIf;
		
	EndDo;
		
EndProcedure

Procedure ReadDataViaExchange(MessageReader, DataAnalysis)
	
	ExchangePlanNameField           = deAttribute(ExchangeFile, StringType, "ExchangePlan");
	FromWhomCode                    = deAttribute(ExchangeFile, StringType, "FromWhom");
	MessageNumberField           = deAttribute(ExchangeFile, NumberType,  "OutgoingMessageNumber");
	ReceivedMessageNumberField  = deAttribute(ExchangeFile, NumberType,  "IncomingMessageNumber");
	DeleteChangesRegistration  = deAttribute(ExchangeFile, BooleanType, "DeleteChangeRecords");
	SenderVersion            = deAttribute(ExchangeFile, StringType, "SenderVersion");
	
	ExchangeNodeRecipient = ExchangePlans[ExchangePlanName()].FindByCode(FromWhomCode);
	
	// Check for the presence of the recipient node, check for correctness of the specifying the 
	// recipient node in the exchange message.
	If Not ValueIsFilled(ExchangeNodeRecipient)
		OR ExchangeNodeRecipient <> ExchangeNodeDataImport Then
		
		MessageString = NStr("ru = 'Не найден узел обмена для загрузки данных. План обмена: %1, Код: %2'; en = 'The exchange node for data import is not found. Exchange plan: %1. Code: %2'; pl = 'Węzeł wymiany dla importu danych nie został znaleziony. Plan wymiany: %1, kod: %2';de = 'Austausch-Knoten für den Datenimport wurde nicht gefunden. Austauschplan: %1, Code: %2';ro = 'Nodul de schimb pentru importul de date nu a fost găsit. Planul de schimb: %1, Cod: %2';tr = 'Veri içe aktarma için değişim ünitesi bulunamadı. Değişim planı:%1, Kod:%2'; es_ES = 'Nodo de intercambio para importar los datos no encontrado. Plan de intercambio: %1, Código: %2'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangePlanName(), FromWhomCode);
		Raise MessageString;
	EndIf;
	
	MessageReader = New Structure("MessageNo, ReceivedNo, Sender, SenderObject, MessageReceivedEarlier, DataAnalysis");
	MessageReader.Sender       = ExchangeNodeRecipient;
	MessageReader.SenderObject = ExchangeNodeRecipient.GetObject();
	MessageReader.MessageNo    = MessageNumberField;
	MessageReader.ReceivedNo    = ReceivedMessageNumberField;
	MessageReader.MessageReceivedEarlier = False;
	MessageReader.DataAnalysis = DataAnalysis;
	MessageReader = New FixedStructure(MessageReader);
	
	BackupRestored = (MessageReader.ReceivedNo > Common.ObjectAttributeValue(MessageReader.Sender, "SentNo"));
	
	If DataImportToInfobaseMode() Then
		
		BeginTransaction();
		Try
			ReceivedMessageNumber = Common.ObjectAttributeValue(MessageReader.Sender, "ReceivedNo");
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
		If ReceivedMessageNumber >= MessageReader.MessageNo Then // The message number is less than or equal to the previously received one.
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False);
			MessageReaderTemporary.MessageReceivedEarlier = True;
			MessageReader = New FixedStructure(MessageReaderTemporary);
			
			Raise NStr("ru = 'Сообщение обмена было принято ранее'; en = 'The exchange message was received earlier.'; pl = 'Wiadomość wymiany została przyjęta poprzednio';de = 'Austausch-Nachricht wurde zuvor empfangen';ro = 'Mesajul de schimb a fost primit anterior';tr = 'Değişim iletisi daha önce alındı'; es_ES = 'Mensaje de intercambio se había recibido previamente'");
		EndIf;
		
		DeleteChangesRegistration = DeleteChangesRegistration AND Not BackupRestored;
		
		If DeleteChangesRegistration Then // Deleting change records.
			
			If TransactionActive() Then
				Raise NStr("ru = 'Удаление регистрации изменений данных не может быть выполнено в активной транзакции.'; en = 'Cannot delete the registration of data changes in an active transaction.'; pl = 'Usunięcie rejestracji zmiany danych nie może zostać zakończone w aktywnej transakcji.';de = 'Das Löschen der Datenänderungsregistrierung kann in einer aktiven Transaktion nicht abgeschlossen werden.';ro = 'Ștergerea înregistrării modificărilor de date nu poate fi executată în tranzacția activă.';tr = 'Veri değişim kaydının silinmesi aktif bir işlemde tamamlanamıyor.'; es_ES = 'Eliminación del registro de cambios de datos no puede finalizarse en una transacción activa.'");
			EndIf;
			
			ExchangePlans.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
			
			InformationRegisters.CommonNodeDataChanges.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
			
			If CommonClientServer.CompareVersions(IncomingExchangeMessageFormatVersion(), "3.1.0.0") >= 0 Then
				
				InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustment(MessageReader.Sender, MessageReader.ReceivedNo);
				
			EndIf;
			
			InformationRegisters.CommonInfobasesNodesSettings.ClearInitialDataExportFlag(MessageReader.Sender, MessageReader.ReceivedNo);
			
		EndIf;
		
		If BackupRestored Then
			
			MessageReader.SenderObject.SentNo = MessageReader.ReceivedNo;
			MessageReader.SenderObject.DataExchange.Load = True;
			MessageReader.SenderObject.Write();
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False);
			MessageReaderTemporary.SenderObject = MessageReader.Sender.GetObject();
			MessageReader = New FixedStructure(MessageReaderTemporary);
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetCorrespondentVersion(MessageReader.Sender, SenderVersion);
		
	EndIf;
	
	// {Handler: AfterReceiveExchangeNodeDetails} Start
	If Not IsBlankString(Conversion.AfterGetExchangeNodesInformation) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandler_Conversion_AfterGetExchangeNodesInformation(MessageReader.Sender);
				
			Else
				
				Execute(Conversion.AfterGetExchangeNodesInformation);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(176, ErrorDescription(), NStr("ru = 'ПослеПолученияИнформацииОбУзлахОбмена (конвертация)'; en = 'AfterGetExchangeNodesInformation (conversion)'; pl = 'AfterReceivingInformationAboutExchangeNodes (konwertowanie)';de = 'NachErhaltVonInformationenÜberAustauschKnoten (Konvertierung)';ro = 'ПослеПолученияИнформацииОбУзлахОбмена (conversie)';tr = 'DeğişimÜniteleriHakkındaBilgiAldıktanSonra (dönüştürme) '; es_ES = 'AfterReceivingInformationAboutExchangeNodes (conversión)'"));
		EndTry;
		
	EndIf;
	// {Handler: AfterReceiveExchangeNodeDetails} End
	
EndProcedure

Procedure ReadCommonNodeData(MessageReader)
	
	ExchangeFile.Read();
	
	DataImportModePrevious = DataImportMode;
	
	DataImportMode = "ImportToValueTable";
	
	CommonNode = ReadObject();
	
	IncreaseImportedObjectCounter();
	
	DataImportMode = DataImportModePrevious;
	
	// {Handler: OnGetSenderData} Start
	Ignore = False;
	ExchangePlanName = CommonNode.Metadata().Name;
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnGetSenderData",ExchangePlanName) Then
		ExchangePlans[ExchangePlanName].OnGetSenderData(CommonNode, Ignore);
	
		If Ignore = True Then
			Return;
		EndIf;
	EndIf;
	// {Handler: OnGetSenderData} End
	
	If DataExchangeEvents.DataDifferent(CommonNode, CommonNode.Ref.GetObject()) Then
		
		BeginTransaction();
		Try
			
			CommonNode.DataExchange.Load = True;
			CommonNode.Write();
			
			// Updating cached values of the mechanism.
			DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		// If there is an open transaction (open when receiving data in the Import mode), close it.
		// 
		// If the transaction will not be closed, the lock of the CommonNodesDataChanges register
		// 
		// when calling the DeleteChangeRecords method will be active until the open transaction is 
		// completed (the end of data receipt), which will make it impossible to either interactively change 
		// the exchange plan node or change it programmatically from other sessions of the infobase.
		// 
		OpenTransaction = False;
		If TransactionActive() Then
			CommitTransaction();
			OpenTransaction = True;
		EndIf;
		
		// Deleting change registration in case if the changes have been registered earlier (in case of a conflict).
		InformationRegisters.CommonNodeDataChanges.DeleteChangeRecords(CommonNode.Ref);
		
		// If before calling the DeleteChangeRecords method of the CommonNodesDataChanges information register
		// the transaction, that was open on data receipt in the Import mode, was closed, you need to open it again.
		If OpenTransaction Then
			BeginTransaction();
		EndIf;
		
		If MessageReader <> Undefined
			AND CommonNode.Ref = MessageReader.Sender Then
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False);
			MessageReaderTemporary.SenderObject = MessageReader.Sender.GetObject();
			MessageReader = New FixedStructure(MessageReaderTemporary);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteDeferredDocumentsPosting()
	
	If DocumentsForDeferredPosting().Count() = 0 Then
		Return // Queue is empty
	EndIf;
	
	// Collapsing the table by unique fields.
	DocumentsForDeferredPosting().GroupBy("DocumentRef, DocumentDate");
	
	// Sorting the documents by dates ascending.
	DocumentsForDeferredPosting().Sort("DocumentDate");
	
	For Each TableRow In DocumentsForDeferredPosting() Do
		
		DocumentRef = TableRow.DocumentRef;
		
		If DocumentRef.IsEmpty() Then
			Continue;
		EndIf;
		
		Object = DocumentRef.GetObject();
		
		If Object = Undefined Then
			Continue;
		EndIf;
		
		// Determining a sender node to prevent object registration on the destination node. Posting is 
		// executed not in import mode.
		SetDataExchangeLoad(Object, False);
		
		ErrorDescription = "";
		DocumentPostedSuccessfully = False;
		
		Try
			
			AdditionalProperties = AdditionalPropertiesForDeferredPosting().Get(DocumentRef);
			
			For Each Property In AdditionalProperties Do
				
				Object.AdditionalProperties.Insert(Property.Key, Property.Value);
				
			EndDo;
			
			Object.AdditionalProperties.Insert("DeferredPosting");
			
			If Object.CheckFilling() Then
				
				// Enabling the object registration rules on document posting as
				//  ORR were ignored during normal document writing in order to optimize data import speed.
				If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
					Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
				EndIf;
				
				DataExchangeServer.SkipPeriodClosingCheck();
				Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
				
				// Trying to post a document.
				Object.Write(DocumentWriteMode.Posting);
				
				DocumentPostedSuccessfully = Object.Posted;
				
			Else
				
				DocumentPostedSuccessfully = False;
				
			EndIf;
			
		Except
			
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			
			DocumentPostedSuccessfully = False;
			
		EndTry;
		
		DataExchangeServer.SkipPeriodClosingCheck(False);
		
		If Not DocumentPostedSuccessfully Then
			
			DataExchangeServer.RecordDocumentPostingError(Object, ExchangeNodeDataImport, ErrorDescription, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExecuteDeferredObjectsWrite()
	
	If ObjectsForDeferredPosting().Count() = 0 Then
		Return // No objects in the queue.
	EndIf;
	
	For Each MapObject In ObjectsForDeferredPosting() Do
		
		If MapObject.Key.IsEmpty() Then
			Continue;
		EndIf;
		
		Object = MapObject.Key.GetObject();
		
		If Object = Undefined Then
			Continue;
		EndIf;
		
		// Determining a sender node to prevent object registration on the destination node. Posting is 
		// executed not in import mode.
		SetDataExchangeLoad(Object, False);
		
		ErrorDescription = "";
		ObjectWrittenSuccessfully = False;
		
		Try
			
			AdditionalProperties = MapObject.Value;
			
			For Each Property In AdditionalProperties Do
				
				Object.AdditionalProperties.Insert(Property.Key, Property.Value);
				
			EndDo;
			
			Object.AdditionalProperties.Insert("DeferredWriting");
			
			If Object.CheckFilling() Then
				
				// Enabling the object registration rules on document posting as
				//  ORR were ignored during normal document writing in order to optimize data import speed.
				If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
					Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
				EndIf;
				
				DataExchangeServer.SkipPeriodClosingCheck();
				Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
				
				// Attempting to write the object.
				ObjectVersionInfo = Undefined;
				If Object.AdditionalProperties.Property("ObjectVersionInfo", ObjectVersionInfo) Then
					DataExchangeEvents.OnCreateObjectVersion(Object, ObjectVersionInfo, True, ExchangeNodeDataImport);
				EndIf;
				Object.Write();
				
				ObjectWrittenSuccessfully = True;
				
			Else
				
				ObjectWrittenSuccessfully = False;
				
				ErrorDescription = NStr("ru = 'Ошибка проверки заполнения реквизитов'; en = 'Attribute filling check error.'; pl = 'Wystąpił błąd podczas sprawdzania wypełnienia atrybutów';de = 'Bei der Überprüfung der Attributpopulation ist ein Fehler aufgetreten';ro = 'Eroare la verificarea completării atributelor';tr = 'Doldurulmuş özellikleri doğrulanamadı'; es_ES = 'Ha ocurrido un error al revisar la población del atributo'");
				
			EndIf;
			
		Except
			
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			
			ObjectWrittenSuccessfully = False;
			
		EndTry;
		
		DataExchangeServer.SkipPeriodClosingCheck(False);
		
		If Not ObjectWrittenSuccessfully Then
			
			DataExchangeServer.RecordObjectWriteError(Object, ExchangeNodeDataImport, ErrorDescription);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteInformationOnDataExchangeOverExchangePlans(Val SentMessageNumber)
	
	Destination = CreateNode("ExchangeData");
	
	SetAttribute(Destination, "ExchangePlan", ExchangePlanName());
	SetAttribute(Destination, "SendTo", DataExchangeServer.CorrespondentNodeIDForExchange(NodeForExchange));
	SetAttribute(Destination, "FromWhom", DataExchangeServer.NodeIDForExchange(NodeForExchange));
	
	// Attributes of exchange message handshake functionality.
	SetAttribute(Destination, "OutgoingMessageNumber", SentMessageNumber);
	SetAttribute(Destination, "IncomingMessageNumber",  NodeForExchange.ReceivedNo);
	SetAttribute(Destination, "DeleteChangeRecords", True);
	
	SetAttribute(Destination, "SenderVersion", TrimAll(Metadata.Version));
	
	// Writing the object to a file
	Destination.WriteEndElement();
	
	WriteToFile(Destination);
	
EndProcedure

Procedure ExportCommonNodeData(Val SentMessageNumber)
	
	NodesChangesSelection = InformationRegisters.CommonNodeDataChanges.SelectChanges(NodeForExchange, SentMessageNumber);
	
	If NodesChangesSelection.Count() = 0 Then
		Return;
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(NodeForExchange);
	
	CommonNodeData = DataExchangeCached.CommonNodeData(NodeForExchange);
	
	If IsBlankString(CommonNodeData) Then
		Return;
	EndIf;
	
	PropertiesConversionRules = New ValueTable;
	InitPropertyConversionRuleTable(PropertiesConversionRules);
	
	Properties       = PropertiesConversionRules.Copy();
	SearchProperties = PropertiesConversionRules.Copy();
	
	CommonNodeMetadata = Metadata.ExchangePlans[ExchangePlanName];
	
	CommonNodeTabularSections = DataExchangeEvents.ObjectTabularSections(CommonNodeMetadata);
	
	CommonNodeProperties = StrSplit(CommonNodeData, ",");
	
	For Each Property In CommonNodeProperties Do
		
		If CommonNodeTabularSections.Find(Property) <> Undefined Then
			
			PCR = Properties.Add();
			PCR.IsFolder = True;
			PCR.SourceKind = "TabularSection";
			PCR.DestinationKind = "TabularSection";
			PCR.Source = Property;
			PCR.Destination = Property;
			PCR.GroupRules = PropertiesConversionRules.Copy();
			
			For Each Attribute In CommonNodeMetadata.TabularSections[Property].Attributes Do
				
				PGCR = PCR.GroupRules.Add();
				PGCR.IsFolder = False;
				PGCR.SourceKind = "Attribute";
				PGCR.DestinationKind = "Attribute";
				PGCR.Source = Attribute.Name;
				PGCR.Destination = Attribute.Name;
				
			EndDo;
			
		Else
			
			PCR = Properties.Add();
			PCR.IsFolder = False;
			PCR.SourceKind = "Attribute";
			PCR.DestinationKind = "Attribute";
			PCR.Source = Property;
			PCR.Destination = Property;
			
		EndIf;
		
	EndDo;
	
	PCR = SearchProperties.Add();
	PCR.SourceKind = "Property";
	PCR.DestinationKind = "Property";
	PCR.Source = "Code";
	PCR.Destination = "Code";
	PCR.SourceType = "String";
	PCR.DestinationType = "String";
	
	OCR = ConversionRulesTable.Add();
	OCR.SynchronizeByID = False;
	OCR.SearchBySearchFieldsIfNotFoundByID = False;
	OCR.DoNotExportPropertyObjectsByRefs = True;
	OCR.SourceType = "ExchangePlanRef." + ExchangePlanName;
	OCR.Source = Type(OCR.SourceType);
	OCR.DestinationType = OCR.SourceType;
	OCR.Destination     = OCR.SourceType;
	
	OCR.Properties = Properties;
	OCR.SearchProperties = SearchProperties;
	
	CommonNode = ExchangePlans[ExchangePlanName].CreateNode();
	DataExchangeEvents.FillObjectPropertiesValues(CommonNode, NodeForExchange.GetObject(), CommonNodeData);
	
	// {Handler: OnSendSenderData} Start
	Ignore = False;
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnSendSenderData",ExchangePlanName) Then
		ExchangePlans[CommonNode.Metadata().Name].OnSendSenderData(CommonNode, Ignore);
		If Ignore = True Then
			Return;
		EndIf;
	EndIf;
	// {Handler: OnSendSenderData} End
	
	CommonNode.Code = DataExchangeServer.NodeIDForExchange(NodeForExchange);
	
	XMLNode = CreateNode("CommonNodeData");
	
	ExportByRule(CommonNode,,,,,,, OCR,,, XMLNode);
	
	XMLNode.WriteEndElement();
	
	WriteToFile(XMLNode);
	
EndProcedure

Function ExportRefObjectData(Value, OutgoingData, OCRName, PropertiesOCR, DestinationType, PropertyNode, Val ExportRefOnly)
	
	IsRuleWithGlobalExport = False;
	RefNode    = ExportByRule(Value, , OutgoingData, , OCRName, , ExportRefOnly, PropertiesOCR, IsRuleWithGlobalExport, , , , False);
	RefNodeType = TypeOf(RefNode);

	If IsBlankString(DestinationType) Then
				
		DestinationType  = PropertiesOCR.Destination;
		SetAttribute(PropertyNode, "Type", DestinationType);
				
	EndIf;
			
	If RefNode = Undefined Then
				
		Return Undefined;
				
	EndIf;
				
	AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport);	
	
	Return RefNode;
	
EndFunction

Procedure SendOneParameterToDestination(Name, InitialParameterValue, ConversionRule = "")
	
	If IsBlankString(ConversionRule) Then
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		SetAttribute(ParameterNode, "Type", deValueTypeAsString(InitialParameterValue));
		
		IsNULL = False;
		Empty = deEmpty(InitialParameterValue, IsNULL);
		
		If Empty Then
			
			// Writing the empty value.
			deWriteElement(ParameterNode, "Empty");
			
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
			
		EndIf;
		
		deWriteElement(ParameterNode, "Value", InitialParameterValue);
		
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);
		
	Else
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		
		IsNULL = False;
		Empty = deEmpty(InitialParameterValue, IsNULL);
		
		If Empty Then
			
			PropertiesOCR = FindRule(InitialParameterValue, ConversionRule);
			DestinationType  = PropertiesOCR.Destination;
			SetAttribute(ParameterNode, "Type", DestinationType);
			
			// Writing the empty value.
			deWriteElement(ParameterNode, "Empty");
			
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
			
		EndIf;
		
		ExportRefObjectData(InitialParameterValue, Undefined, ConversionRule, Undefined, Undefined, ParameterNode, True);
		
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);
		
	EndIf;
	
EndProcedure

Procedure SendAdditionalParametersToDestination()
	
	For Each Parameter In ParameterSetupTable Do
		
		If Parameter.PassParameterOnExport = True Then
			
			SendOneParameterToDestination(Parameter.Name, Parameter.Value, Parameter.ConversionRule);
					
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SendTypesInformationToDestination()
	
	If Not IsBlankString(TypesForDestinationString) Then
		WriteToFile(TypesForDestinationString);
	EndIf;
		
EndProcedure

Procedure SendCustomSearchFieldsInformationToDestination()
	
	For Each MapKeyAndValue In CustomSearchFieldInfoOnDataExport Do
		
		ParameterNode = CreateNode("CustomSearchSettings");
		
		deWriteElement(ParameterNode, "RuleName", MapKeyAndValue.Key);
		deWriteElement(ParameterNode, "SearchSettings", MapKeyAndValue.Value);
		
		ParameterNode.WriteEndElement();
		WriteToFile(ParameterNode);
		
	EndDo;
	
EndProcedure

Procedure InitializeCommentsOnDataExportAndImport()
	
	CommentOnDataExport = "";
	CommentOnDataImport = "";
	
EndProcedure

Procedure ExportedByRefObjectsAddValue(Value)
	
	If ExportedByRefObjects().Find(Value) = Undefined Then
		
		ExportedByRefObjects().Add(Value);
		
	EndIf;
	
EndProcedure

Function ObjectPassesAllowedObjectFilter(Value)
	
	Return InformationRegisters.InfobaseObjectsMaps.ObjectIsInRegister(Value, NodeForExchange);
	
EndFunction

Function ObjectMappingMechanismSearchFields(Val SearchFields)
	
	SearchFieldsCollection = StrSplit(SearchFields, ",");
	
	CommonClientServer.DeleteValueFromArray(SearchFieldsCollection, "IsFolder");
	
	Return StrConcat(SearchFieldsCollection, ",");
EndFunction

Procedure ExecuteExport(ErrorMessageString = "")
	
	ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(NodeForExchange);
	
	ExportMappingInformation = ExportObjectMappingInfo(NodeForExchange);
	
	InitializeCommentsOnDataExportAndImport();
	
	CurrentNestingLevelExportByRule = 0;
	
	DataExportCallStack = New ValueTable;
	DataExportCallStack.Columns.Add("Ref");
	DataExportCallStack.Indexes.Add("Ref");
	
	InitManagersAndMessages();
	
	ExportedObjectCounterField = Undefined;
	SnCounter 				= 0;
	WrittenToFileSn		= 0;
	
	For Each Rule In ConversionRulesTable Do
		
		Rule.Exported = CreateExportedObjectTable();
		
	EndDo;
	
	// Getting types of metadata objects that will take part in the export.
	UsedExportRulesTable = ExportRuleTable.Copy(New Structure("Enable", True));
	UsedExportRulesTable.Indexes.Add("SelectionObjectMetadata");
	
	For Each TableRow In UsedExportRulesTable Do
		
		If Not TableRow.SelectionObject = Type("ConstantsSet") Then
			
			TableRow.SelectionObjectMetadata = Metadata.FindByType(TableRow.SelectionObject);
			
		EndIf;
		
	EndDo;
	
	DataMapForExportedItemUpdate = New Map;
	
	// {BeforeDataExport HANDLER}
	Cancel = False;
	
	If Not IsBlankString(Conversion.BeforeExportData) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeDataExport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeExportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(62, ErrorDescription(), NStr("ru = 'ПередВыгрузкойДанных (конвертация)'; en = 'BeforeExportData (conversion)'; pl = 'BeforeDataExport (konwertowanie)';de = 'VorDemDatenExport (Konvertierung)';ro = 'BeforeDataExport (conversie)';tr = 'VeriDışaAktarılmadanÖnce (dönüştürme)'; es_ES = 'BeforeDataExport (conversión)'"));
			Cancel = True;
		EndTry; 
		
		If Cancel Then // Canceling data export
			FinishKeepExchangeProtocol();
			Return;
		EndIf;
		
	EndIf;
	// {BeforeDataExport HANDLER}
	
	SendCustomSearchFieldsInformationToDestination();
	
	SendTypesInformationToDestination();
	
	// Passing add. parameters to destination.
	SendAdditionalParametersToDestination();
	
	EventTextAfterParametersImport = "";
	If Conversion.Property("AfterImportParameters", EventTextAfterParametersImport)
		AND Not IsBlankString(EventTextAfterParametersImport) Then
		
		WritingEvent = New XMLWriter;
		WritingEvent.SetString();
		deWriteElement(WritingEvent, "AfterParameterExportAlgorithm", EventTextAfterParametersImport);
		
		WriteToFile(WritingEvent);
		
	EndIf;
	
	SentMessageNumber = Common.ObjectAttributeValue(NodeForExchange, "SentNo") + ?(ExportMappingInformation, 2, 1);
	
	WriteInformationOnDataExchangeOverExchangePlans(SentMessageNumber);
	
	ExportCommonNodeData(SentMessageNumber);
	
	Cancel = False;
	
	// EXPORTING MAPPING REGISTER
	If ExportMappingInformation Then
		
		XMLWriter = New XMLWriter;
		XMLWriter.SetString();
		WriteMessage = ExchangePlans.CreateMessageWriter();
		WriteMessage.BeginWrite(XMLWriter, NodeForExchange);
		
		Try
			ExportObjectMappingRegister(WriteMessage, ErrorMessageString);
		Except
			Cancel = True;
		EndTry;
		
		If Cancel Then
			WriteMessage.CancelWrite();
		Else
			WriteMessage.EndWrite();
		EndIf;
		
		XMLWriter.Close();
		XMLWriter = Undefined;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// EXPORTING MAPPING REGISTER CORRECTION
	If MustAdjustMappingInfo() Then
		
		ExportMappingInfoAdjustment();
		
	EndIf;
	
	// EXPORTING REGISTERED DATA
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	WriteMessage = ExchangePlans.CreateMessageWriter();
	WriteMessage.BeginWrite(XMLWriter, NodeForExchange);
	
	Try
		ExecuteRegisteredDataExport(WriteMessage, ErrorMessageString, UsedExportRulesTable);
	Except
		Cancel = True;
		WriteToExecutionProtocol(DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	// Registering the selected exported by reference objects on the current node.
	For Each Item In ExportedByRefObjects() Do
		
		ExchangePlans.RecordChanges(WriteMessage.Recipient, Item);
		
	EndDo;
	
	// Setting the number of sent message for objects exported by reference.
	If ExportedByRefObjects().Count() > 0 Then
		
		DataExchangeServer.SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo, ExportedByRefObjects());
		
	EndIf;
	
	// Setting the number of sent message for objects created in current session.
	If CreatedOnExportObjects().Count() > 0 Then
		
		DataExchangeServer.SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo, CreatedOnExportObjects());
		
	EndIf;
	
	If Cancel Then
		WriteMessage.CancelWrite();
	Else
		WriteMessage.EndWrite();
	EndIf;
	
	XMLWriter.Close();
	XMLWriter = Undefined;
	
	// {AfterDataExport HANDLER}
	If Not Cancel AND Not IsBlankString(Conversion.AfterExportData) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_AfterDataExport(ExchangeFile);
				
			Else
				
				Execute(Conversion.AfterExportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(63, ErrorDescription(), NStr("ru = 'ПослеВыгрузкиДанных (конвертация)'; en = 'AfterExportData (conversion)'; pl = 'AfterDataExport (konwertowanie)';de = 'NachDemDatenExport (Konvertierung)';ro = 'După depozit de date (conversie)';tr = 'VeriİçeAktarıldıktanSonra (dönüştürme)'; es_ES = 'AfterDataExport (conversión)'"));
		EndTry;
	
	EndIf;
	// {AfterDataExport HANDLER}
	
EndProcedure

Procedure ExportObjectMappingRegister(WriteMessage, ErrorMessageString)
	
	// Selecting changes only for the mapping register.
	ChangesSelection = DataExchangeServer.SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo, Metadata.InformationRegisters.InfobaseObjectsMaps);
	
	While ChangesSelection.Next() Do
		
		Data = ChangesSelection.Get();
		
		// Apply filter to the data export.
		If Data.Filter.InfobaseNode.Value <> NodeForExchange Then
			Continue;
		ElsIf IsBlankString(Data.Filter.DestinationUUID.Value) Then
			Continue;
		EndIf;
		
		ExportObject = True;
		
		For Each Record In Data Do
			
			If ExportObject AND Record.ObjectExportedByRef = True Then
				
				ExportObject = False;
				
			EndIf;
			
		EndDo;
		
		// Exporting the registered information of the InfobaseObjectsMap register record.
		// Conversion rules of the register record are written in the code of this data processor.
		If ExportObject Then
			
			ExportChangeRecordedObjectData(Data);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExecuteRegisteredDataExport(WriteMessage, ErrorMessageString, UsedExportRulesTable)
	
	// Stubs to support debugging mechanism of event handler code.
	Var Cancel, OCRName, DataSelection, OutgoingData;
	// {BeforeGetChangedObjects HANDLER}
	If Not IsBlankString(Conversion.BeforeGetChangedObjects) Then
		
		Try
			
			Recipient = NodeForExchange;
			
			If ExportHandlersDebug Then
				
				ExecuteHandler_Conversion_BeforeGetChangedObjects(Recipient, BackgroundExchangeNode);
				
			Else
				
				Execute(Conversion.BeforeGetChangedObjects);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(175, ErrorDescription(), NStr("ru = 'ПередПолучениемИзмененныхОбъектов (конвертация)'; en = 'BeforeGetChangedObjects (conversion)'; pl = 'BeforeReceivingChangedObjects (konwertowanie)';de = 'VorDemEmpfangenGeänderterObjekte (Konvertierung)';ro = 'ПередПолучениемИзмененныхОбъектов (conversie)';tr = 'DeğişmişNesneleriAlmadanÖnce (dönüştürme)'; es_ES = 'BeforeReceivingChangedObjects (conversión)'"));
			Return;
		EndTry;
		
	EndIf;
	// {BeforeGetChangedObjects HANDLER}
	
	MetadataToExportArray = UsedExportRulesTable.UnloadColumn("SelectionObjectMetadata");
	
	// The Undefined value means that constants need to be exported.
	If MetadataToExportArray.Find(Undefined) <> Undefined Then
		
		SupplementMetadataToExportArrayWithConstants(MetadataToExportArray);
		
	EndIf;
	
	// Deleting elements with the Undefined value from the array.
	DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray);
	
	// The InfobaseObjectsMaps register record is exported separately. That is why it is not included to 
	// this selection.
	If MetadataToExportArray.Find(Metadata.InformationRegisters.InfobaseObjectsMaps) <> Undefined Then
		
		CommonClientServer.DeleteValueFromArray(MetadataToExportArray, Metadata.InformationRegisters.InfobaseObjectsMaps);
		
	EndIf;
	
	// Updating cached values of the object registration mechanism.
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	InitialDataExport = DataExchangeServer.InitialDataExportFlagIsSet(WriteMessage.Recipient);
	
	// CHANGE SELECTION
	ChangesSelection = DataExchangeServer.SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo, MetadataToExportArray);
	
	MetadataObjectPrevious      = Undefined;
	PreviousDataExportRule = Undefined;
	DataExportRule           = Undefined;
	ExportingRegister              = False;
	ExportingConstants            = False;
	
	IsExchangeOverExternalConnection = IsExchangeOverExternalConnection();
	
	If IsExchangeOverExternalConnection Then
		If DataImportExecutedInExternalConnection Then
			If DataProcessorForDataImport().UseTransactions Then
				ExternalConnection.BeginTransaction();
			EndIf;
		Else
			DataProcessorForDataImport().ExternalConnectionBeginTransactionOnDataImport();
		EndIf;
	EndIf;
	
	Try
		NodeForExchangeObject = NodeForExchange.GetObject();
		
		While ChangesSelection.Next() Do
			Increment(ObjectsToExportCount);
		EndDo;
		
		ChangesSelection.Reset();
		
		If IsExchangeOverExternalConnection() Then
			// This data processor attribute might be missing in the correspondent infobase.
			If DataProcessorForDataImport().Metadata().Attributes.Find("ObjectsToImportCountExternalConnection") <> Undefined Then
				DataProcessorForDataImport().ObjectsToImportCountExternalConnection = ObjectsToExportCount;
			EndIf;
		EndIf;
		
		While ChangesSelection.Next() Do
			
			Increment(ExportedObjectCounterField);
			DataExchangeServer.CalculateExportPercent(ExportedObjectCounter(), ObjectsToExportCount);
			
			Data = ChangesSelection.Get();
			
			ExportDataType = TypeOf(Data);
			
			// Processing object deletion.
			If ExportDataType = ObjectDeletionType Then
				
				ProcessObjectDeletion(Data);
				Continue;
				
			ElsIf ExportDataType = MapRegisterType Then
				Continue;
			EndIf;
			
			CurrentMetadataObject = Data.Metadata();
			
			// A new type of a metadata object is exported.
			If MetadataObjectPrevious <> CurrentMetadataObject Then
				
				If MetadataObjectPrevious <> Undefined Then
					
					// {AfterProcess DER HANDLER}
					If PreviousDataExportRule <> Undefined
						AND Not IsBlankString(PreviousDataExportRule.AfterProcess) Then
						
						Try
							
							If ExportHandlersDebug Then
								
								ExecuteHandler_DER_AfterProcessRule(OCRName, PreviousDataExportRule, OutgoingData);
								
							Else
								
								Execute(PreviousDataExportRule.AfterProcess);
								
							EndIf;
							
						Except
							WriteErrorInfoDERHandlers(32, ErrorDescription(), PreviousDataExportRule.Name, "AfterProcessDataExport");
						EndTry;
						
					EndIf;
					// {AfterProcess DER HANDLER}
					
				EndIf;
				
				MetadataObjectPrevious = CurrentMetadataObject;
				
				ExportingRegister = False;
				ExportingConstants = False;
				
				DataStructure = ManagersForExchangePlans[CurrentMetadataObject];
				
				If DataStructure = Undefined Then
					
					ExportingConstants = Metadata.Constants.Contains(CurrentMetadataObject);
					
				ElsIf DataStructure.IsRegister = True Then
					
					ExportingRegister = True;
					
				EndIf;
				
				If ExportingConstants Then
					
					DataExportRule = UsedExportRulesTable.Find(Type("ConstantsSet"), "SelectionObjectMetadata");
					
				Else
					
					DataExportRule = UsedExportRulesTable.Find(CurrentMetadataObject, "SelectionObjectMetadata");
					
				EndIf;
				
				PreviousDataExportRule = DataExportRule;
				
				// {BeforeProcess DER HANDLER}
				OutgoingData = Undefined;
				
				If DataExportRule <> Undefined
					AND Not IsBlankString(DataExportRule.BeforeProcess) Then
					
					Try
						
						If ExportHandlersDebug Then
							
							ExecuteHandler_DER_BeforeProcessRule(Cancel, OCRName, DataExportRule, OutgoingData, DataSelection);
							
						Else
							
							Execute(DataExportRule.BeforeProcess);
							
						EndIf;
						
					Except
						WriteErrorInfoDERHandlers(31, ErrorDescription(), DataExportRule.Name, "BeforeProcessDataExport");
					EndTry;
					
					
				EndIf;
				// {BeforeProcess DER HANDLER}
				
			EndIf;
			
			If ExportDataType <> MapRegisterType Then
				
				// Determining the kind of object sending.
				ItemSending = DataItemSend.Auto;
				
				StandardSubsystemsServer.OnSendDataToSlave(Data, ItemSending, InitialDataExport, NodeForExchangeObject);
				
				If ItemSending = DataItemSend.Delete Then
					
					If ExportingRegister Then
						
						// Sending an empty record set upon the register deletion.
						
					Else
						
						// Sending data about deleting.
						ProcessObjectDeletion(Data);
						Continue;
						
					EndIf;
					
				ElsIf ItemSending = DataItemSend.Ignore Then
					
					Continue;
					
				EndIf;
				
			EndIf;
			
			// OBJECT EXPORT
			If ExportingRegister Then
				
				// register export
				ExportRegister(Data, DataExportRule, OutgoingData, DoNotExportObjectsByRefs);
				
			ElsIf ExportingConstants Then
				
				// exporting the set of constants
				Properties = Managers[Type("ConstantsSet")];
				
				ExportConstantsSet(DataExportRule, Properties, OutgoingData, CurrentMetadataObject.Name);
				
			Else
				
				// exporting reference types
				ExportSelectionObject(Data, DataExportRule, , OutgoingData, DoNotExportObjectsByRefs);
				
			EndIf;
			
			If IsExchangeOverExternalConnection Then
				
				If DataImportExecutedInExternalConnection Then
					
					If DataProcessorForDataImport().UseTransactions
						AND DataProcessorForDataImport().ObjectsPerTransaction > 0
						AND DataProcessorForDataImport().ImportedObjectCounter() % DataProcessorForDataImport().ObjectsPerTransaction = 0 Then
						
						// If transactions are used and the number of items of a single transaction is set, then when 
						// reading an exchange message you need to control how many objects are imported.
						//  If the amount of imported objects equals the amount of objects in one transaction, commit the 
						// existing transaction and open a new one.
						// 
						ExternalConnection.CommitTransaction();
						ExternalConnection.BeginTransaction();
						
					EndIf;
					
					
				Else
					
					DataProcessorForDataImport().ExternalConnectionCheckTransactionStartAndCommitOnDataImport();
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If MetadataObjectPrevious <> Undefined Then
			
			// {AfterProcess DER HANDLER}
			If DataExportRule <> Undefined
				AND Not IsBlankString(DataExportRule.AfterProcess) Then
				
				Try
					
					If ExportHandlersDebug Then
						
						ExecuteHandler_DER_AfterProcessRule(OCRName, DataExportRule, OutgoingData);
						
					Else
						
						Execute(DataExportRule.AfterProcess);
						
					EndIf;
					
				Except
						WriteErrorInfoDERHandlers(32, ErrorDescription(), DataExportRule.Name, "AfterProcessDataExport");
				EndTry;
				
			EndIf;
			// {AfterProcess DER HANDLER}
			
		EndIf;
	
		If IsExchangeOverExternalConnection Then
			If DataImportExecutedInExternalConnection Then
				If DataProcessorForDataImport().UseTransactions Then
					
					If DataProcessorForDataImport().ErrorFlag() Then
						Raise(NStr("ru = 'Ошибка при отправке данных.'; en = 'Cannot send the data.'; pl = 'Błąd wysyłania danych.';de = 'Fehler beim Senden von Daten.';ro = 'Eroare la trimiterea datelor.';tr = 'Veri gönderilirken hata oluştu.'; es_ES = 'Error al enviar los datos.'"));
					Else
						ExternalConnection.CommitTransaction();
					EndIf;
					
				EndIf;
			Else
				DataProcessorForDataImport().ExternalConnectionCommitTransactionOnDataImport();
			EndIf;
			
		EndIf;
		
	Except
		
		If IsExchangeOverExternalConnection Then
			If DataImportExecutedInExternalConnection Then
				While ExternalConnection.TransactionActive() Do
					ExternalConnection.RollbackTransaction();
				EndDo;
			Else
				DataProcessorForDataImport().ExternalConnectionRollbackTransactionOnDataImport();
			EndIf;
		EndIf;
		
		Raise(NStr("ru = 'Ошибка при отправке данных'; en = 'Cannot send the data'; pl = 'Błąd wysyłania danych';de = 'Fehler beim Senden von Daten';ro = 'Eroare la trimiterea datelor';tr = 'Veri gönderilirken hata oluştu'; es_ES = 'Error al enviar los datos'") + ": " + ErrorDescription());
		
	EndTry
	
EndProcedure

Procedure WriteEventLogDataExchange(Comment, Level = Undefined)
	
	If Level = Undefined Then
		Level = EventLogLevel.Error;
	EndIf;
	
	MetadataObject = Undefined;
	
	If     ExchangeNodeDataImport <> Undefined
		AND Not ExchangeNodeDataImport.IsEmpty() Then
		
		MetadataObject = ExchangeNodeDataImport.Metadata();
		
	EndIf;
	
	WriteLogEvent(EventLogMessageKey(), Level, MetadataObject,, Comment);
	
EndProcedure

Function ExportObjectMappingInfo(InfobaseNode)
	
	QueryText = "
	|SELECT TOP 1 1
	|FROM
	|	InformationRegister.InfobaseObjectsMaps.Changes AS InfobaseObjectsMapsChanges
	|WHERE
	|	InfobaseObjectsMapsChanges.Node = &InfobaseNode
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function MustAdjustMappingInfo()
	
	Return InformationRegisters.CommonInfobasesNodesSettings.MustAdjustMappingInfo(NodeForExchange, NodeForExchange.SentNo + 1);
	
EndFunction

Procedure DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray)
	
	If MetadataToExportArray.Find(Undefined) <> Undefined Then
		
		CommonClientServer.DeleteValueFromArray(MetadataToExportArray, Undefined);
		
		DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray);
		
	EndIf;
	
EndProcedure

Procedure SupplementMetadataToExportArrayWithConstants(MetadataToExportArray)
	
	Composition = Metadata.ExchangePlans[ExchangePlanName()].Content;
	
	For Each MetadataObjectConstant In Metadata.Constants Do
		
		If Composition.Contains(MetadataObjectConstant) Then
			
			MetadataToExportArray.Add(MetadataObjectConstant);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initializing

InitAttributesAndModuleVariables();

InitConversionRuleTable();
InitExportRuleTable();
CleaningRuleTableInitialization();
ParametersSetupTableInitialization();

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf