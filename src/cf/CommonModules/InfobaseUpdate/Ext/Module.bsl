///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for use in update handlers.
//

// Records changes into the passed object.
// To be used in update handlers.
//
// Parameters:
//   Data - Arbitrary - an object, record set, or manager of the constant to be written.
//                                                      
//   RegisterOnExchangePlanNodes - Boolean - enables registration in exchange plan nodes when writing the object.
//   EnableBusinessLogic - Boolean - enables business logic when writing the object.
//
Procedure WriteData(Val Data, Val RegisterOnExchangePlanNodes = Undefined, 
	Val EnableBusinessLogic = False) Export
	
	Data.DataExchange.Load = Not EnableBusinessLogic;
	Data.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", RegisterOnExchangePlanNodes);
	
	If RegisterOnExchangePlanNodes = Undefined
		Or Not RegisterOnExchangePlanNodes Then
		Data.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Data.Write();
	
	MarkProcessingCompletion(Data);
	
EndProcedure

// Records changes in a passed reference object.
// To be used in update handlers.
//
// Parameters:
//   Object - Arbitrary - the reference object to be written. For example, CatalogObject.
//   RegisterOnExchangePlanNodes - Boolean - enables registration in exchange plan nodes when writing the object.
//   EnableBusinessLogic - Boolean - enables business logic when writing the object.
//   DocumentWriteMode - DocumentWriteMode - valid only for DocumentObject data type - the document 
//                                                            write mode.
//											If the parameter is not passed, the document is written in the Write mode.
//
Procedure WriteObject(Val Object, Val RegisterOnExchangePlanNodes = Undefined, 
	Val EnableBusinessLogic = False, DocumentWriteMode = Undefined) Export
	
	Object.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", RegisterOnExchangePlanNodes);
	Object.DataExchange.Load = Not EnableBusinessLogic;
	
	If RegisterOnExchangePlanNodes = Undefined
		Or Not RegisterOnExchangePlanNodes
		AND Not Object.IsNew() Then
		Object.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	If DocumentWriteMode <> Undefined Then
		If TypeOf(DocumentWriteMode) <> Type("DocumentWriteMode") Then
			ExceptionText = NStr("ru = 'Неправильный тип параметра ДокументРежимЗаписи'; en = 'Invalid type of DocumentWriteMode parameter.'; pl = 'Niepoprawny typ parametru DocumentWriteMode';de = 'Falscher Typ des Parameters DocumentWriteMode';ro = 'Tip incorect al parametrului DocumentWriteMode';tr = 'DocumentWriteMode parametresinin türü yanlıştır'; es_ES = 'Tipo incorrecto del parámetro DocumentWriteMode.'");
			Raise ExceptionText;
		EndIf;
		Object.DataExchange.Load = Object.DataExchange.Load
			AND Not DocumentWriteMode = DocumentWriteMode.Posting
			AND Not DocumentWriteMode = DocumentWriteMode.UndoPosting;
		Object.Write(DocumentWriteMode);
	Else
		Object.Write();
	EndIf;
	
	MarkProcessingCompletion(Object);
	
EndProcedure

// Records changes in the passed data set.
// To be used in update handlers.
//
// Parameters:
//   RecordSet                      - InformationRegisterRecordSet,
//                                       AccumulationRegisterRecordSet,
//                                       AccountingRegisterRecordSet,
//                                       CalculationRegisterRecordSet - the record set to be written.
//   Replace                          - Boolean       - defines the record replacement mode in 
//       accordance with the current filter criteria. True - the existing records are deleted before writing. 
//       False - the new records are appended to the existing records.
//   RegisterOnExchangePlanNodes - Boolean - enables registration in exchange plan nodes when writing the object.
//   EnableBusinessLogic - Boolean - enables business logic when writing the object.
//
Procedure WriteRecordSet(Val RecordSet, Replace = True, Val RegisterOnExchangePlanNodes = Undefined,
	Val EnableBusinessLogic = False) Export
	
	RecordSet.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", RegisterOnExchangePlanNodes);
	RecordSet.DataExchange.Load = Not EnableBusinessLogic;
	
	If RegisterOnExchangePlanNodes = Undefined 
		Or Not RegisterOnExchangePlanNodes Then
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	RecordSet.Write(Replace);
	
	MarkProcessingCompletion(RecordSet);
	
EndProcedure

// Deletes the passed object.
// To be used in update handlers.
//
// Parameters:
//  Data - Arbitrary - the object to be deleted.
//  RegisterOnExchangePlanNodes - Boolean - enables registration in exchange plan nodes when writing the object.
//  EnableBusinessLogic - Boolean - enables business logic when writing the object.
//
Procedure DeleteData(Val Data, Val RegisterOnExchangePlanNodes = Undefined, 
	Val EnableBusinessLogic = False) Export
	
	Data.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", RegisterOnExchangePlanNodes);
	
	Data.DataExchange.Load = Not EnableBusinessLogic;
	If RegisterOnExchangePlanNodes = Undefined 
		Or Not RegisterOnExchangePlanNodes Then
		Data.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Data.Delete();
	
EndProcedure

// Returns a string constant for generating event log messages.
//
// Returns:
//   String - the text of an event in the event log.
//
Function EventLogEvent() Export
	
	Return InfobaseUpdateInternal.EventLogEvent();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to check object availability when running deferred update.
//

// If there are unfinished deferred update handlers that process the passed Data object, the 
// procedure throws an exception or locks form to disable editing.
// 
//
// For calls made from the deferred update handler (handler interface check scenario), the check 
// does not start unless the DeferredHandlerName parameter is specified. The blank parameter means 
// the update order is formed during the update queue generation.
//
// Parameters:
//  Data - AnyRef, RecordSet, Object, FormDataStructure, String - the object reference, the object 
//           itself, record set or full name of the metadata object whose handler is to be checked.
//  Form - ManagedForm - if an object is not processed, the ReadOnly property is set for the passed 
//           form. If the form is not passed, an exception is thrown.
//           
//
//  DeferredHandlerName - String - unless blank, checks that another deferred handler that makes a 
//           call has a smaller queue number than the current deferred number.
//           If the queue number is greater, it throws an exception as it is forbidden to use 
//           application interface specified in the InterfaceProcedureName parameter.
//
//  InterfaceProcedureName - String - the application interface name displayed in the exception 
//           message shown when checking queue number of the deferred handler specified in the 
//           DeferredHandlerName parameter.
//
//  Example:
//   Locking object form in the OnCreateAtServer module handler.
//   InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
//
//   Locking object (a record set) form in the BeforeWrite module handler:
//   InfobaseUpdate.CheckObjectProcessed(ThisObject);
//
//   Check that the object is updated and throw the DigitalSignature.UpdateSignature procedure 
//   exception unless the object is not processed by
//   Catalog.DigitalSignatures.ProcessDataForMigrationToNewVersion
//
//   InfobaseUpdate.CheckObjectProcessed(SignedObject,,
//      "Catalog.DigitalSignatures.ProcessDataForMigrationToNewVersion",
//      "DigitalSignature.UpdateSignature");
//
//   Check that all objects of the type are updated:
//   AllOrdersProcessed = InfobaseUpdate.CheckObjectProcessed("Document.CustomerOrder");
//
Procedure CheckObjectProcessed(Data, Form = Undefined, DeferredHandlerName = "", InterfaceProcedureName = "") Export
	
	If Not IsCallFromUpdateHandler() Then
		Result = ObjectProcessed(Data);
		If Result.Processed Then
			Return;
		EndIf;
			
		If Form = Undefined Then
			Raise Result.ExceptionText;
		EndIf;
		
		Form.ReadOnly = True;
		Common.MessageToUser(Result.ExceptionText);
		Return;
	EndIf;
	
	If Not ValueIsFilled(DeferredHandlerName) Then
		Return;
	EndIf;
	
	If DeferredHandlerName = SessionParameters.UpdateHandlerParameters.HandlerName Then
		Return;
	EndIf;
	
	RequiredHandlerQueue = DeferredUpdateHandlerQueue(DeferredHandlerName);
	CurrentHandlerQueue = SessionParameters.UpdateHandlerParameters.DeferredProcessingQueue;
	If CurrentHandlerQueue > RequiredHandlerQueue Then
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Недопустимо вызывать %1
		           |из обработчика обновления
		           |%2
		           |так как его номер очереди меньше или равен номеру очереди обработчика обновления
		           |%3'; 
		           |en = 'Cannot call %1
		           |from update handler
		           |%2
		           | as its queue number is less than or equal to the queue number of update handler
		           |%3.'; 
		           |pl = 'Nie dopuszczalne jest wezwanie %1
		           |z programu przetwarzania aktualizacji
		           |%2
		           |ponieważ jego numer kolejki jest mniejszy lub równy numeru kolejki programu przetwarzania aktualizacji
		           |%3';
		           |de = 'Rufen Sie %1
		           | nicht vom 
		           |%2
		           |Update-Handler auf, da seine Warteschlangennummer kleiner oder gleich der Warteschlangennummer des Update-Handlers ist
		           |%3';
		           |ro = 'Nu se permite apelarea %1
		           |din handlerul de actualizare
		           |%2
		           |deoarece numărul lui de rând de așteptare este mai mic sau egal cu numărul rândului de așteptare al handlerului de actualizare
		           |%3';
		           |tr = 'Güncelleştirme işleyicisinden çağırmak%1
		           | için geçerli değil, çünkü sıra numarası
		           |%2
		           | güncelleştirme işleyicisinin sıra numarasına eşit veya daha küçük
		           |%3'; 
		           |es_ES = 'No se admite llamar %1
		           |del procesador de actualización 
		           |%2
		           |porque su número de orden es menos o igual al número de orden del procesador de actualización
		           |%3'"),
		InterfaceProcedureName,
		SessionParameters.UpdateHandlerParameters.HandlerName,
		DeferredHandlerName);
	
EndProcedure

// Check whether there are deferred update handlers that are processing the passed Data object.
// 
//
// Parameters:
//  Data - AnyRef, RecordSet, Object, FormDataStructure, String - the object reference, the object 
//           itself, record set, or full name of the metadata object whose lock is to be checked.
//
// Returns:
//   Structure - with the following fields:
//     * Processed - Boolean - the flag showing whether the object is processed.
//     * ExceptionText - String - the exception text in case the object is not processed. Contains 
//                         the list of unfinished handlers.
//
// Example:
//   Check that all objects of the type are updated:
//   AllOrdersProcessed = InfobaseUpdate.ObjectProcessed("Document.CustomerOrder");
//
Function ObjectProcessed(Data) Export
	
	Result = New Structure;
	Result.Insert("Processed", True);
	Result.Insert("ExceptionText", "");
	Result.Insert("IncompleteHandlersString", "");
	
	If Data = Undefined Then
		Return Result;
	EndIf;
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		
		IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
		If Not IsSubordinateDIBNode Then
			Return Result;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return Result;
		EndIf;
		
	EndIf;
	
	LockedObjectsInfo = InfobaseUpdateInternal.LockedObjectsInfo();
	
	If TypeOf(Data) = Type("String") Then
		FullName = Data;
	Else
		MetadataAndFilter = MetadataAndFilterByData(Data);
		FullName = MetadataAndFilter.Metadata.FullName();
	EndIf;
	
	ObjectToCheck = StrReplace(FullName, ".", "");
	
	ObjectHandlers = LockedObjectsInfo.ObjectsToLock[ObjectToCheck];
	If ObjectHandlers = Undefined Then
		Return Result;
	EndIf;
	
	Processed = True;
	IncompleteHandlers = New Array;
	For Each Handler In ObjectHandlers Do
		HandlerProperties = LockedObjectsInfo.Handlers[Handler];
		If HandlerProperties.Completed Then
			Processed = True;
		ElsIf TypeOf(Data) = Type("String") Then
			Processed = False;
		Else
			Processed = Common.CalculateInSafeMode(
				HandlerProperties.CheckProcedure + "(Parameters)", MetadataAndFilter);
		EndIf;
		
		Result.Processed = Processed AND Result.Processed;
		
		If Not Processed Then
			IncompleteHandlers.Add(Handler);
		EndIf;
	EndDo;
	
	If IncompleteHandlers.Count() > 0 Then
		ExceptionText = NStr("ru = 'Действия с объектом временно запрещены, так как не завершен переход на новую версию программы.
			|Это плановый процесс, который скоро завершится.
			|Остались следующие процедуры обработки данных:'; 
			|en = 'Operations with this object are temporarily blocked
			|until the scheduled upgrade to a new version is completed.
			|The following data processing procedures are not yet completed:'; 
			|pl = 'Czynności z obiektem tymczasowo są zabronione, ponieważ nie jest zakończone przejście do nowej wersji programu.
			|To jest proces planowy, który niedługo będzie zakończony.
			|Zostały następujące procedury przetwarzania danych:';
			|de = 'Aktionen mit dem Objekt sind vorübergehend verboten, da die Migration auf die neue Version des Programms nicht abgeschlossen ist.
			|Dies ist ein geplanter Prozess, der in Kürze abgeschlossen sein wird.
			|Die folgenden Verfahren der Datenverarbeitung bleiben bestehen:';
			|ro = 'Acțiunile cu obiectul sunt interzise temporar, deoarece nu este finalizată trecerea la versiunea nouă a programului.
			|Acesta este un proces planificat care va finaliza în curând.
			|Au rămas următoarele proceduri de procesare a datelor:';
			|tr = 'Programın yeni bir sürümüne geçiş tamamlanmadığı için nesne eylemleri geçici olarak yasaktır. 
			|Yakında sona erecek planlı bir süreçtir. 
			|Aşağıdaki veri işleme işlemleri kalmıştır:'; 
			|es_ES = 'Las acciones con el objeto están temporalmente prohibidas porque no se ha terminado el traspaso a la nueva versión del programa.
			|Es un proceso planificado que terminará dentro de poco.
			|Quedan los siguientes procedimientos de procesamiento de datos:'");
		
		IncompleteHandlersString = "";
		For Each IncompleteHandler In IncompleteHandlers Do
			IncompleteHandlersString = IncompleteHandlersString + Chars.LF + IncompleteHandler;
		EndDo;
		Result.ExceptionText = ExceptionText + IncompleteHandlersString;
		Result.IncompleteHandlersString = IncompleteHandlersString;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for deferred update handlers with Parallel execution mode.
// 
//

// Checking that the passed data is updated.
//
// Parameters:
//  Data - Reference, Array, DataSet - the data the changes to be recorded for.
//							 - ValueTable - independent information register dimension values. Requirements:
//													- All register dimensions are included in the main filter.
//													- The table contains only the columns that match the register dimension names
//														the handler has been assigned to.
//													- During the update, the sets are recorded with the same filter
//														the handler has been assigned with.
//													- AdditionalParameters obtains the flag value and the full register name.
//  AdditionalParameters - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
//  PositionInQueue - Number, Undefined - the position in a processing queue where the current handler is running. 
//													By default, you do not have to pass the position as its value is obtained from the parameters of the session that runs the update handler.
//
Procedure MarkProcessingCompletion(Data, AdditionalParameters = Undefined, PositionInQueue = Undefined) Export
	If PositionInQueue = Undefined Then
		If SessionParameters.UpdateHandlerParameters.ExecutionMode <> "Deferred"
			Or SessionParameters.UpdateHandlerParameters.DeferredHandlerExecutionMode <> "Parallel" Then
			Return;
		EndIf;
		PositionInQueue = SessionParameters.UpdateHandlerParameters.DeferredProcessingQueue;
	EndIf;
	
	If Not SessionParameters.UpdateHandlerParameters.HasProcessedObjects Then
		NewSessionParameters = InfobaseUpdateInternal.NewUpdateHandlerParameters();
		
		FillPropertyValues(NewSessionParameters, SessionParameters.UpdateHandlerParameters);
		NewSessionParameters.HasProcessedObjects = True;
		
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewSessionParameters);
	EndIf;
	
	DataCopy = Data;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingMarkParameters();
	EndIf;
	
	If (TypeOf(Data) = Type("Array")
		Or TypeOf(Data) = Type("ValueTable"))
		AND Data.Count() = 0 Then
		
		ExceptionText = NStr("ru = 'В процедуру ОбновлениеИнформационнойБазы.ОтметитьВыполнениеОбработки передан пустой массив. Не возможно отметить выполнение обработки.'; en = 'An empty array is passed to InfobaseUpdate.MarkProcessingCompletion procedure. Cannot mark the data processing procedure as completed.'; pl = 'Do procedury InfobaseUpdate.MarkProcessingCompletion został przekazany pusty masyw. Niemożliwie jest zaznaczyć wykonanie przetwarzania.';de = 'Zur Prozedur der InfobaseUpdate.MarkProcessingCompletion wird ein leeres Array übertragen. Es ist nicht möglich, die Verarbeitungsausführung zu markieren.';ro = 'În procedura InfobaseUpdate.MarkProcessingCompletion a fost transmisă mulțimea goală. Nu puteți marca executarea procesării.';tr = 'InfobaseUpdate.MarkProcessingCompletion prosedürüne boş küme aktarıldı.  İşlem yürütülemedi.'; es_ES = 'En el procedimiento InfobaseUpdate.MarkProcessingCompletion se ha pasado una matriz vacía. No se puede marcar la ejecución del procesamiento.'");
		Raise ExceptionText;
		
	EndIf;
	
	Node = QueueRef(PositionInQueue);
	
	If AdditionalParameters.IsRegisterRecords Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		
		If TypeOf(Data) = Type("Array") Then
			For Each ArrayRow In Data Do
				Set.Filter.Recorder.Set(ArrayRow);
				ExchangePlans.DeleteChangeRecords(Node, Set);
			EndDo;
		Else
			Set.Filter.Recorder.Set(Data);
			ExchangePlans.DeleteChangeRecords(Node, Set);
		EndIf;
		
	ElsIf AdditionalParameters.IsIndependentInformationRegister Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		ObjectMetadata = Metadata.FindByFullName(AdditionalParameters.FullRegisterName);
		
		SetMissingFiltersInSet(Set, ObjectMetadata, Data);	
		
		For each TableRow In Data Do
			For Each Column In Data.Columns Do
				Set.Filter[Column.Name].Value = TableRow[Column.Name];
				Set.Filter[Column.Name].Use = True;
			EndDo;
			
			ExchangePlans.DeleteChangeRecords(Node, Set);
		EndDo;
		
	Else
		If TypeOf(Data) = Type("MetadataObject") Then
			ExceptionText = NStr("ru = 'Не поддерживается отметка выполнения обработки обновления целиком объекта метаданных. Нужно отмечать обработку конкретных данных.'; en = 'Setting ""update processing completed"" flag to an entire metadata object is not supported. This flag can be set to specific data.'; pl = 'Nie jest obsługiwane zaznaczenie wykonania przetwarzania aktualizacji w całości obiektu metadanych. Trzeba zaznaczać przetwarzanie konkretnych danych.';de = 'Es wird nicht unterstützt, das gesamte Metadatenobjekt als aktualisiert zu markieren. Es ist notwendig, die Verarbeitung bestimmter Daten zu kennzeichnen.';ro = 'Marcarea executării procesării de actualizare a obiectului de metadate în întregime nu este susținută. Trebuie să marcați procesarea datelor concrete.';tr = 'Meta veri nesnesinin tamamını güncelleştirme işleme yürütme işareti desteklenmiyor. Belirli verilerin işlenmesi işaretlenmelidir.'; es_ES = 'No se admite la marca de ejecución del procesamiento de actualización del objeto de metadatos entero. Hay que marcar el procesamiento de datos en concreto.'");
			Raise ExceptionText;
		EndIf;
		
		If TypeOf(Data) <> Type("Array") Then
			
			ObjectValueType = TypeOf(Data);
			ObjectMetadata  = Metadata.FindByType(ObjectValueType);
			
			If Common.IsInformationRegister(ObjectMetadata)
				AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				Set = Common.ObjectManagerByFullName(ObjectMetadata.FullName()).CreateRecordSet();
				For Each FilterItem In Data.Filter Do
					Set.Filter[FilterItem.Name].Value = FilterItem.Value;
					Set.Filter[FilterItem.Name].Use = FilterItem.Use;
				EndDo;
				SetMissingFiltersInSet(Set, ObjectMetadata, Data.Filter);
			ElsIf Common.IsRefTypeObject(ObjectMetadata)
				AND Not Common.IsReference(ObjectValueType)
				AND Data.IsNew() Then
				
				Return;
			Else
				Set = Data;
			EndIf;
			
			ExchangePlans.DeleteChangeRecords(Node, Set);
			DataCopy = Set;
		Else
			For Each ArrayElement In Data Do
				ExchangePlans.DeleteChangeRecords(Node, ArrayElement);
			EndDo;
		EndIf;
		
	EndIf;
	
	If Not Common.IsSubordinateDIBNode() Then
		InformationRegisters.DataProcessedInMasterDIBNode.MarkProcessingCompletion(PositionInQueue, DataCopy, AdditionalParameters); 
	EndIf;
	
EndProcedure

// Additional parameters of functions MarkForProcessing and MarkProcessingCompletion.
// 
// Returns:
//  Structure - structure with the following properties:
//     * IsRegisterRecords - Boolean - the Data function parameter passed references to recorders that require update.
//                              Default value is False.
//      * RegisterFullName - String - the full name of the register that requires update. For example, AccumulationRegister.Stock
//      * SelectAllRecorders - Boolean - all posted documents passed in the type second parameter 
//                                           are selected for processing.
//                                           In this scenario, the Data parameter can pass the following
//                                           MetadataObject: Document or DocumentRef.
//      * IsIndependentInformationRegister - Boolean - the function Data parameter passes table with 
//                                                 dimension values to update. The default value is False.
//
Function AdditionalProcessingMarkParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IsRegisterRecords", False);
	AdditionalParameters.Insert("SelectAllRecorders", False);
	AdditionalParameters.Insert("IsIndependentInformationRegister", False);
	AdditionalParameters.Insert("FullRegisterName", "");
	
	Return AdditionalParameters;
	
EndFunction

// The InfobaseUpdate.MarkForProcessing procedure main parameters that are initialized by the change 
// registration mechanism and must not be overridden in the code of procedures that mark update 
// handlers for processing.
//
// Returns:
//  Structure - with the following properties:
//     * PositionInQueue - Number - the position in the queue for the current handler.
//     * WriteChangesForSubordinateDIBNodeWithFilters - FastInfosetWriter - the parameter is 
//          available only when the DataExchange subsystem is embedded.
//     * SelectionParameters - Structure - see  AdditionalMultithreadProcessingDataSelectionParameters().
//
Function MainProcessingMarkParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Queue", 0);
	Parameters.Insert("ReRegistration", False);
	Parameters.Insert("SelectionParameters");
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Parameters.Insert("NameOfChangedFile", Undefined);
		Parameters.Insert("WriteChangesForSubordinateDIBNodeWithFilters", Undefined);
		
	EndIf;
	
	Return Parameters; 
	
EndFunction

// Returns normalized information on the passed data.
// Which then is used in data lock check procedures for deferred update handlers.
//
// Parameters:
//  Data - AnyRef, RecordSet, Object, FormDataStructure - the data to be analyzed.
//  AdditionalParameters - Structure, Undefined - see InfobaseUpdate. AdditionalProcessingMarkParameters.
// 
// Returns:
//  Structure - with the following properties:
//      * Data - AnyRef, RecordSet, Object, FormDataStructure - the value of the input Data parameter.
//  	* ObjectMetadata - MetadataObject - the metadata object that matches the Data parameter.
//  	* FullName - String - the metadata object full name (see method MetadataObject.FullName).
//		* Filter               - AnyRef - if Data is a reference object, it is the reference value. If 
//                                            Data is a recorder subordinate register, it is the recorder filter value.
//			   	              - Structure - if Data is an independent information register, it is the 
//                                            structure that matches the filters set for the dimensions.
//		* IsNew - Boolean - if Data is a reference object, it is a new object flag.
//                                            For other data types, it is always False.
//	
Function MetadataAndFilterByData(Data, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingMarkParameters();
	EndIf;
	
	If AdditionalParameters.IsRegisterRecords Then
		ObjectMetadata = Metadata.FindByFullName(AdditionalParameters.FullRegisterName);		
	Else
		ObjectMetadata = Undefined;
	EndIf;
	
	Filter = Undefined;
	DataType = TypeOf(Data);
	IsNew = False;
	
	If TypeOf(Data) = Type("String") Then
		ObjectMetadata = Metadata.FindByFullName(Data);
	ElsIf DataType = Type("FormDataStructure") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Data, "Ref") Then
			
			If ObjectMetadata = Undefined Then
				ObjectMetadata = Data.Ref.Metadata();
			EndIf;
			
			Filter = Data.Ref;
			
			If Not ValueIsFilled(Filter) Then
				IsNew = True;
			EndIf;
			
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Data, "SourceRecordKey") Then	

			If ObjectMetadata = Undefined Then
				ObjectMetadata = Metadata.FindByType(TypeOf(Data.SourceRecordKey));	
			EndIf;
			Filter = New Structure;
			For Each Dimension In ObjectMetadata.Dimensions Do
				Filter.Insert(Dimension.Name, Data[Dimension.Name]);
			EndDo;
			
		Else
			ExceptionText = NStr("ru = 'Процедура ОбновлениеИнформационнойБазы.МетаданныеИОтборПоДанным не может быть использована для этой формы.'; en = 'Cannot use InfobaseUpdate.MetadataAndFilterByData function in this form.'; pl = 'Procedura InfobaseUpdate.MetadataAndFilterByData nie może być zastosowana dla tej formy.';de = 'Die Prozedur InfobaseUpdate.MetadataAndFilterByData kann für dieses Formular nicht verwendet werden.';ro = 'Procedura InfobaseUpdate.MetadataAndFilterByData nu poate fi utilizată pentru această formă.';tr = 'InfobaseUpdate.MetadataAndFilterByData işlemi bu form için kullanılamaz.'; es_ES = 'El procedimiento InfobaseUpdate.MetadataAndFilterByData no puede ser usado para este formulario.'");
		EndIf;
		
	Else
		
		If ObjectMetadata = Undefined Then
			ObjectMetadata = Data.Metadata();
		EndIf;
		
		If Common.IsRefTypeObject(ObjectMetadata) Then
			
			If Common.IsReference(DataType) Then
				Filter = Data;
			Else
				Filter = Data.Ref;
				
				If Data.IsNew() Then
					IsNew = True;
				EndIf;
			
			EndIf;
			
		ElsIf Common.IsInformationRegister(ObjectMetadata)
			AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			
			Filter = New Structure;
			For Each FilterItem In Data.Filter Do
				If FilterItem.Use Then 
					Filter.Insert(FilterItem.Name, FilterItem.Value);
				EndIf;
			EndDo;
			
		ElsIf Common.IsRegister(ObjectMetadata) Then
			If AdditionalParameters.IsRegisterRecords Then
				Filter = Data;
			Else
				Filter = Data.Filter.Recorder.Value;
			EndIf;
		Else
			ExceptionText = NStr("ru = 'Для этого типа метаданных не поддерживается анализ в функции ОбновлениеИнформационнойБазы.МетаданныеИОтборПоДанным.'; en = 'The InfobaseUpdate.MetadataAndFilterByData function does not support analysis of this metadata type.'; pl = 'Dla tego typu metadanych nie jest obsługiwana analiza w funkcji InfobaseUpdate.MetadataAndFilterByData.';de = 'Für diese Art von Metadaten wird die Analyse in der Funktion InfobaseUpdate.MetadataAndFilterByData nicht unterstützt.';ro = 'Pentru acest tip de metadate nu este susținută analiza în funcția InfobaseUpdate.MetadataAndFilterByData.';tr = 'Bu tür meta veri için InfobaseUpdate.MetadataAndFilterByData işlevinde analiz desteklenmiyor.'; es_ES = 'Para este tipo de metadatos no se admite el análisis en la función InfobaseUpdate.MetadataAndFilterByData.'");
			Raise ExceptionText;
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("Data", Data);
	Result.Insert("Metadata", ObjectMetadata);
	Result.Insert("FullName", ObjectMetadata.FullName());
	Result.Insert("Filter", Filter);
	Result.Insert("IsNew", IsNew);
	
	Return Result;
EndFunction

// Mark passed objects for update.
// Note. It is not recommended that you pass to the Data parameter all the data to update at once as 
// big collections of Arrays or ValueTables type might take a significant amount of space on the 
// server and affect its performance.
//  It is recommended that you transfer data by batches about 1,000 objects at a time.
// 
//
// Parameters:
//  MainParameters - Structure - see InfobaseUpdate.MainProcessingMarkParameters. 
//  Data - Reference, Array, RecordSet - the data the changes to be recorded for.
//                    - ValueTable - independent information register dimension values. Requirements:
//                        - no changes with name "Node".
//                        - All register dimensions are included in the main filter.
//                        - The table contains only the columns that match the register dimension 
//                          names that are subject to process request.
//                        - During the update, the filter applied to the process request is applied 
//                          to sets to be recorded.
//                        - AdditionalParameters obtains the flag value and the full register name.
//  AdditionalParameters - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
// 
Procedure MarkForProcessing(MainParameters, Data, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingMarkParameters();
	EndIf;
	
	If (TypeOf(Data) = Type("Array")
		Or TypeOf(Data) = Type("ValueTable"))
		AND Data.Count() = 0 Then
		Return;
	EndIf;
	
	Node = QueueRef(MainParameters.Queue);
	
	If AdditionalParameters.IsRegisterRecords Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		
		If AdditionalParameters.SelectAllRecorders Then
			
			If TypeOf(Data) = Type("MetadataObject") Then
				DocumentMetadata = Data;
			ElsIf Common.IsReference(TypeOf(Data)) Then
				DocumentMetadata = Data.Metadata();
			Else
				ExceptionText = NStr("ru = 'Для регистрации всех регистраторов регистра необходимо в параметре ""Данные"" передать ОбъектМетаданных:Документ или ДокументСсылка.'; en = 'To register all register recorders, in the Data parameter, pass MetadataObject:Document or DocumentRef.'; pl = 'Dla rejestracji wszystkich rejestratorów rejestru należy w parametrze ""Данные"" przekazać ОбъектМетаданных:Документ lub ДокументСсылка.';de = 'Um alle Registrierstellen des Registers zu registrieren, ist es erforderlich, im Parameter ""Daten"" die ObjektMetadaten:Dokument oder DokumentVerknüpfung zu übertragen.';ro = 'Pentru înregistrarea tuturor registratorilor registrului trebuie să transmiteți ОбъектМетаданных:Документ sau ДокументСсылка în parametrul ""Datele"" .';tr = 'Tüm sicil kaydediciler için ""Veriler"" parametresinde MetaveriNesnesi: Belge veya BelgeReferans aktar.'; es_ES = 'Para registrar todos los registradores es necesario en el parámetro ""Datos"" transmitir MetadataObject:Document o DocumentRef.'");
				Raise ExceptionText;
			EndIf;
			FullDocumentName = DocumentMetadata.FullName();
			
			QueryText =
			"SELECT
			|	DocumentTable.Ref AS Ref
			|FROM
			|	#DocumentTable AS DocumentTable
			|WHERE
			|	DocumentTable.Posted";
			
			QueryText = StrReplace(QueryText, "#DocumentTable", FullDocumentName);
			Query = New Query;
			Query.Text = QueryText;
			
			RefsArray = Query.Execute().Unload().UnloadColumn("Ref");
			
			For Each ArrayElement In RefsArray Do
				Set.Filter.Recorder.Set(ArrayElement);
				RecordChanges(MainParameters, Node, Set, "SubordinateRegister", AdditionalParameters.FullRegisterName);
			EndDo;
			
		Else
			
			If TypeOf(Data) = Type("Array") Then
				Iterator = 0;
				Try
					For Each ArrayElement In Data Do
						If Iterator = 0 Then
							BeginTransaction();
						EndIf;
						Set.Filter.Recorder.Set(ArrayElement);
						RecordChanges(MainParameters, Node, Set, "SubordinateRegister", AdditionalParameters.FullRegisterName);
						Iterator = Iterator + 1;
						If Iterator = 1000 Then
							Iterator = 0;
							CommitTransaction();
						EndIf;
					EndDo;
					
					If Iterator <> 0 Then
						CommitTransaction();
					EndIf;
				Except
					RollbackTransaction();
					Raise;
				EndTry
			Else
				
				Set.Filter.Recorder.Set(Data);
				RecordChanges(MainParameters, Node, Set, "SubordinateRegister", AdditionalParameters.FullRegisterName);
				
			EndIf;
			
		EndIf;
	ElsIf AdditionalParameters.IsIndependentInformationRegister Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		ObjectMetadata = Metadata.FindByFullName(AdditionalParameters.FullRegisterName);
		SetMissingFiltersInSet(Set, ObjectMetadata, Data);
		
		For Each TableRow In Data Do
			
			For Each Column In Data.Columns Do
				Set.Filter[Column.Name].Value = TableRow[Column.Name];
				Set.Filter[Column.Name].Use = True;
			EndDo;
			
			RecordChanges(MainParameters, Node, Set, "IndependentRegister", AdditionalParameters.FullRegisterName);
			
		EndDo;
	Else
		If TypeOf(Data) = Type("Array") Then
			Iterator = 0;
			Try
				For Each ArrayElement In Data Do
					If Iterator = 0 Then
						BeginTransaction();
					EndIf;
					RecordChanges(MainParameters, Node, ArrayElement, "Ref");
					Iterator = Iterator + 1;
					If Iterator = 1000 Then
						Iterator = 0;
						CommitTransaction();
					EndIf;
				EndDo;
				
				If Iterator <> 0 Then
					CommitTransaction();
				EndIf;
			Except
				RollbackTransaction();
				Raise;
			EndTry
		ElsIf Common.IsReference(TypeOf(Data)) Then
			RecordChanges(MainParameters, Node, Data, "Ref");
		Else
			If TypeOf(Data) = Type("MetadataObject") Then
				ExceptionText = NStr("ru = 'Не поддерживается регистрация к обновлению целиком объекта метаданных. Нужно обновлять конкретные данные.'; en = 'Registration of an entire metadata object for update is not supported. Please update specific data.'; pl = 'Nie jest obsługiwana rejestracja do aktualizacji w całości obiektu metadanych. Trzeba aktualizować konkretne dane.';de = 'Die Registrierung für die Aktualisierung des gesamten Metadatenobjekts wird nicht unterstützt. Bestimmte Daten müssen aktualisiert werden.';ro = 'Înregistrarea spre actualizare a obiectului de metadate în întregime nu este susținută. Trebuie să actualizați datele concrete.';tr = 'Meta veri nesnesinin tamamını güncelleştirmeye kayıt desteklenmiyor. Belirli verileri güncellemek gerekir.'; es_ES = 'No se admite el registro a la actualización del objeto entero de metadatos. Hay que actualizar los datos en concreto.'");
				Raise ExceptionText;
			EndIf;
			
			ObjectMetadata = Metadata.FindByType(TypeOf(Data));
			
			If Common.IsInformationRegister(ObjectMetadata)
				AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				
				SetMissingFiltersInSet(Data, ObjectMetadata, Data.Filter);
				
			EndIf;
			RecordChanges(MainParameters, Node, Data, "IndependentRegister", ObjectMetadata.FullName());
		EndIf;
	EndIf;
	
EndProcedure

// Register passed recorders as the ones that require record update.
// 
// Parameters:
//  Parameters - Structure - see InfobaseUpdate.MainProcessingMarkParameters. 
//  Recorders - Array - a recorder ref array.
//  RegisterFullName - String - the full name of a register that requires update.
//
Procedure MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName) Export
	
	AdditionalParameters = AdditionalProcessingMarkParameters();
	AdditionalParameters.IsRegisterRecords = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;
	MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
EndProcedure

// Additional parameters for the data selected for processing.
// 
// Returns:
//  Structure - structure fields:
//   * SelectInParts - Boolean - select data to process in chunks.
//                        If documents are selected, the data chunks are formed considering the 
//                        document sorting (from newest to latest). If register recorders are 
//                        selected and the full document name has been passed, the data chunks are formed considering the recorder sorting (from newest to latest).
//                        If the full document name has not been passed, the data chunks are formed considering the register sorting:
//                        - Get maximum date for each recorder.
//                        - If a register has no records, it goes on top.
//   * TemporaryTableName - String - the parameter is valid for methods that create temporary tables. 
//                           If the name is not specified (the default scenario), the temporary 
//                           table is created with the name specified in the method description.
//   * AdditionalDataSources - Map - the parameter is valid for methods that select recorders and 
//                                     references to be processed. There can be only one of the 
//                                     following data kinds in matching keys:
//                                     1. Paths to document header attributes or tabular sections 
//                                        attributes that are connected with other tables (including 
//                                        implicit connections when addressing "separated by dot").
//                                     2. Names of reference metadata objects (String) that contain 
//                                        a map in their values where the key is a register name 
//                                        (String), and in the map value in the keys of which is the same as in the cl. 1, that means,
//                                        map hierarchy "Object" -> "Register" -> "Sources".
//                                     Procedures check data lock for these tables by the handlers 
//                                     with lowest positions in the queue. Source name format: <AttributeName> or
//                                     <TabularSectionName>.<TabularSectionAttributeName>. To ease 
//                                     the filling see SetDataSource(), and see GetDataSource().  
//   * OrderingFields - Array - the name of independent information register fields used to organize 
//                                    a query result.
//   * MaxSelection - Number - the maximum number of selecting records.
//
Function AdditionalProcessingDataSelectionParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectInBatches", True);
	AdditionalParameters.Insert("TempTableName", "");
	AdditionalParameters.Insert("AdditionalDataSources", New Map);
	AdditionalParameters.Insert("OrderFields", New Array);
	AdditionalParameters.Insert("MaxSelection", MaxRecordsCountInSelection());
	
	Return AdditionalParameters;
	
EndFunction

// Additional parameters for the data selected for multithread processing.
//
// Returns:
//  Structure - fields from AdditionalProcessingDataSelectionParameters() with the following fields:
//   * FullNamesOfObjects - String - full names of updated objects (for example, documents) separated by commas.
//   * FullRegistersNames - Start - full registers names separated by commas.
//   * OrderingFieldsOnUserOperations - Array - ordering fields that are used when updating with 
//                                                user operations priority.
//   * OrderingFieldsOnProcessData - Array - ordering fields that are used when updating with data 
//                                            processing priority.
//   * SelectionMethod - String - one of the selection method:
//                              InfobaseUpdate.IndependentInfoRegistryMeasurementsSelectionMethod(),
//                              InfobaseUpdate.RegistryRecordersSelectionMethod(),
//                              InfobaseUpdate.RefsSelectionMethod().
//   * LastSelectedRecord - ValueList - end of the previous selection (internal field).
//   * FirstRecord - ValueList - selection start (internal field).
//   * LastRecord - ValueList - end of the previous selection (internal field).
//   * OptimizeSelectionByPages - Boolean - if True, the selection is executed without OR, the False 
//                                        value can be useful if the original request is not optimal, then it will be faster with OR.
//
Function AdditionalMultithreadProcessingDataSelectionParameters() Export
	
	AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.Insert("FullNamesOfObjects");
	AdditionalParameters.Insert("FullRegistersNames");
	AdditionalParameters.Insert("OrderingFieldsOnUserOperations", New Array);
	AdditionalParameters.Insert("OrderingFieldsOnProcessData", New Array);
	AdditionalParameters.Insert("SelectionMethod");
	AdditionalParameters.Insert("LastSelectedRecord");
	AdditionalParameters.Insert("FirstRecord");
	AdditionalParameters.Insert("LatestRecord");
	AdditionalParameters.Insert("OptimizeSelectionByPages", True);
	
	Return AdditionalParameters;
	
EndFunction

// Set the AdditionalDataSources parameter in the structure returned by the function
// AdditionalProcessingDataSelectionParameters().
//
// It is used when the data sources must be set by documents and registers.
// Applied by multithread updating.
//
// Parameters:
//  AdditionalDataSources - Map - the same as AdditionalDataSources (see
//                                   AdditionalProcessingDataSelectionParameters()).
//  Source - String - data sources (see AdditionalProcessingDataSelectionParameters()).
//  Object - String - document name (full or short).
//  Register - String - register name (full or short).
//
Procedure SetDataSource(AdditionalDataSources, Source, Object = "", Register = "") Export
	
	ObjectName = MetadataObjectName(Object);
	RegisterName = MetadataObjectName(Register);
	
	If IsBlankString(ObjectName) AND IsBlankString(RegisterName) Then
		AdditionalDataSources.Insert(Source);
	Else
		ObjectRegister = AdditionalDataSources[ObjectName];
		
		If ObjectRegister = Undefined Then
			ObjectRegister = New Map;
			AdditionalDataSources[ObjectName] = ObjectRegister;
		EndIf;
		
		DataSources = ObjectRegister[RegisterName];
		
		If DataSources = Undefined Then
			DataSources = New Map;
			ObjectRegister[RegisterName] = DataSources;
		EndIf;
		
		DataSources.Insert(Source);
	EndIf;
	
EndProcedure

// Get the AdditionalDataSources parameter value from the structure returned by the 
// AdditionalProcessingDataSelectionParameters() function.
//
// It can be used when the data sources must be get by documents and registers.
// Applied by multithread updating.
//
// Parameters:
//  AdditionalDataSources - Map - the same as AdditionalDataSources (see
//                                   AdditionalProcessingDataSelectionParameters()).
//  Object - String - document name (full or short).
//  Register - String - register name (full or short).
//
// Returns:
//  Map - data sources for the specified document and register.
//
Function DataSources(AdditionalDataSources, Object = "", Register = "") Export
	
	If IsSimpleDataSource(AdditionalDataSources) Then
		Return AdditionalDataSources;
	Else
		ObjectName = MetadataObjectName(Object);
		RegisterName = MetadataObjectName(Register);
		ObjectRegister = AdditionalDataSources[ObjectName];
		MapType = Type("Map");
		
		If TypeOf(ObjectRegister) = MapType Then
			DataSources = ObjectRegister[RegisterName];
			
			If TypeOf(DataSources) = MapType Then
				Return DataSources;
			EndIf;
		EndIf;
		
		Return New Map;
	EndIf;
	
EndFunction

// Creates temporary reference table that are not processed in the current queue and not locked by 
//  the lesser priority queues.
//  Table name: TTForProcessing<RegisterName>. For example, TTForProcessingStock.
//  Table columns:
//  * Recorder - DocumentRef.
//
// Parameters:
//  PositionInQueue - Number - the position in the processing queue where the handler is running.
//  FullDocumentName - String - the name of the document that requires record update. If the records 
//									are not based on the document data, the passed value is Undefined. In this case, the document table is not checked for lock.
//									For example, Document.GoodsReceipt.
//  RegisterFullName - String - the name of the register that requires record update.
//  	For example, AccumulationRegister.Stock
//  TemporaryTablesManager - TemporaryTablesManager - the manager where a temporary table to be created.
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  Structure - temporary table formation result:
//  * HasRecordsInTemporaryTable - Boolean - the created table has at least one record. There are 
//                                            two reasons records might be missing:
//												All references have been processed or the references to be processed are locked by the lower-priority handlers.
//  * HasDataForProcessing - Boolean - the queue contains references to process.
//  * TemporaryTableName - String - a name of a created temporary table.
//
Function CreateTemporaryTableOfRegisterRecordersToProcess(PositionInQueue, FullDocumentName, FullRegisterName, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	RegisterName = StrSplit(FullRegisterName,".",False)[1];
	
	CurrentQueue = QueueRef(PositionInQueue);
	
	If FullDocumentName = Undefined Then 
		If AdditionalParameters.SelectInBatches Then
			QueryText =
			"SELECT
			|	RegisterTableChanges.Recorder AS Recorder,
			|	MAX(ISNULL(RegisterTable.Period, DATETIME(3000, 1, 1))) AS Period
			|INTO TTToProcessRecorderFull
			|FROM
			|	#RegisterTableChanges AS RegisterTableChanges
			|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
			|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
			|		LEFT JOIN #RegisterRecordsTable AS RegisterTable
			|		ON RegisterTableChanges.Recorder = RegisterTable.Recorder
			|		#ConnectionToAdditionalSourcesRegistersQueryText
			|WHERE
			|	RegisterTableChanges.Node = &CurrentQueue
			|	AND TTLockedRecorder.Recorder IS NULL
			|	AND &ConditionByAdditionalSourcesRegisters
			|
			|GROUP BY
			|	RegisterTableChanges.Recorder
			|
			|INDEX BY
			|	Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TTToProcessRecorderFull.Recorder AS Recorder
			|INTO #TTToProcessRecorder
			|FROM
			|	TTToProcessRecorderFull AS TTToProcessRecorderFull
			|WHERE
			|	TTToProcessRecorderFull.Recorder IN
			|			(SELECT TOP 10000
			|				TTToProcessRecorderFull.Recorder AS Recorder
			|			FROM
			|				TTToProcessRecorderFull AS TTToProcessRecorderFull
			|			ORDER BY
			|				TTToProcessRecorderFull.Period DESC)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTLockedRecorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTToProcessRecorderFull";
			QueryText = StrReplace(QueryText,"#RegisterRecordsTable", FullRegisterName);	
		Else
			QueryText =
			"SELECT
			|	RegisterTableChanges.Recorder AS Recorder
			|INTO #TTToProcessRecorder
			|FROM
			|	#RegisterTableChanges AS RegisterTableChanges
			|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
			|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
			|		#ConnectionToAdditionalSourcesRegistersQueryText
			|WHERE
			|	RegisterTableChanges.Node = &CurrentQueue
			|	AND TTLockedRecorder.Recorder IS NULL
			|	AND &ConditionByAdditionalSourcesRegisters
			|
			|INDEX BY
			|	Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTLockedRecorder";
		EndIf;
	Else
		If AdditionalParameters.SelectInBatches Then
			QueryText =
			"SELECT
			|	RegisterTableChanges.Recorder AS Recorder
			|INTO TTToProcessRecorderFull
			|FROM
			|	#RegisterTableChanges AS RegisterTableChanges
			|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
			|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
			|		LEFT JOIN TTLockedReference AS TTLockedReference
			|		ON RegisterTableChanges.Recorder = TTLockedReference.Ref
			|		#ConnectionToAdditionalSourcesByHeaderQueryText
			|		#ConnectionToAdditionalSourcesByTabularSectionQueryText
			|		#ConnectionToAdditionalSourcesRegistersQueryText
			|WHERE
			|	RegisterTableChanges.Node = &CurrentQueue
			|	AND RegisterTableChanges.Recorder REFS #FullDocumentName 
			|	AND TTLockedRecorder.Recorder IS NULL 
			|	AND TTLockedReference.Ref IS NULL 
			|	AND &ConditionByAdditionalSourcesReferences
			|	AND &ConditionByAdditionalSourcesRegisters
			|
			|INDEX BY
			|	Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TTToProcessRecorderFull.Recorder AS Recorder
			|INTO #TTToProcessRecorder
			|FROM
			|	TTToProcessRecorderFull AS TTToProcessRecorderFull
			|WHERE
			|	TTToProcessRecorderFull.Recorder IN
			|			(SELECT TOP 10000
			|				TTToProcessRecorderFull.Recorder AS Recorder
			|			FROM
			|				TTToProcessRecorderFull AS TTToProcessRecorderFull
			|					INNER JOIN #FullDocumentName AS DocumentTable
			|					ON
			|						TTToProcessRecorderFull.Recorder = DocumentTable.Ref
			|			ORDER BY
			|				DocumentTable.Date DESC)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTLockedRecorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTLockedReference
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTToProcessRecorderFull";

		Else	
			QueryText =
			"SELECT
			|	RegisterTableChanges.Recorder AS Recorder
			|INTO #TTToProcessRecorder
			|FROM
			|	#RegisterTableChanges AS RegisterTableChanges
			|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
			|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
			|		LEFT JOIN TTLockedReference AS TTLockedReference
			|		ON RegisterTableChanges.Recorder = TTLockedReference.Ref
			|		#ConnectionToAdditionalSourcesByHeaderQueryText
			|		#ConnectionToAdditionalSourcesByTabularSectionQueryText
			|		#ConnectionToAdditionalSourcesRegistersQueryText
			|WHERE
			|	RegisterTableChanges.Node = &CurrentQueue
			|	AND RegisterTableChanges.Recorder REFS #FullDocumentName 
			|	AND TTLockedRecorder.Recorder IS NULL 
			|	AND TTLockedReference.Ref IS NULL 
			|	AND &ConditionByAdditionalSourcesReferences
			|	AND &ConditionByAdditionalSourcesRegisters
			|
			|INDEX BY
			|	Recorder 
			|;
			|DROP
			|	TTLockedRecorder 
			|;
			|DROP
			|	TTLockedReference";
		EndIf;
		
		AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
		AdditionalParametersForTTCreation.TempTableName = "TTLockedReference";
		CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullDocumentName, TempTablesManager, AdditionalParametersForTTCreation);
	EndIf;
	
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName = "TTToProcess" + RegisterName;
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	
	QueryText = StrReplace(QueryText, "#RegisterTableChanges", FullRegisterName + ".Changes");	
	QueryText = StrReplace(QueryText, "#TTToProcessRecorder", TempTableName);
	
	AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
	AdditionalParametersForTTCreation.TempTableName = "TTLockedRecorder";
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullRegisterName, TempTablesManager, AdditionalParametersForTTCreation);
	
	AddAdditionalSourceLockCheck(PositionInQueue, QueryText, FullDocumentName, FullRegisterName, TempTablesManager, True, AdditionalParameters);
	
	QueryText = StrReplace(QueryText, "#FullDocumentName", FullDocumentName);
		
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", CurrentQueue);
	QueryResult = Query.ExecuteBatch();
	
	Result = New Structure("HasRecordsInTemporaryTable,HasDataToProcess,TempTableName", False, False, "");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult[0].Unload()[0].Count <> 0;
	
	If Result.HasRecordsInTemporaryTable Then
		Result.HasDataToProcess = True;
	Else
		Result.HasDataToProcess = HasDataToProcess(PositionInQueue, FullRegisterName);
	EndIf;	
	
	Return Result; 
	
EndFunction

// Returns a chunk of recorders that require record update. 
//  The input is the data registered in the queue. Data in the higher-priority queues is processed first.
//  Lock by other queues includes documents and registers.
//  If the full document name has been passed, the selected recorders are sorted by date (from newest to latest).
//  If the full document name has not been passed, the data chunks are formed considering the register sorting:
//				- Get maximum date for each recorder.
//				- If a register has no records, it goes on top.
// Parameters:
//  PositionInQueue - Number - the position in the queue the handler and the data it will process are assigned to.
//  FullDocumentName - String - the name of the document that requires record update. If the records 
//									are not based on the document data, the passed value is Undefined. In this case, the document table is not checked for lock.
//									For example, Document.GoodsReceipt.
//  RegisterFullName - String - the name of the register that requires record update.
//  	For example, AccumulationRegister.Stock
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  * QueryResultSelection - the selection of recorders that require processing and selection fields:
//    ** Recorder - DocumentRef.
//    ** Period - Data - if the full document name is passed, the date of the document. Otherwise, 
//                       the maximum period of the recorder.
//    ** Posted - Boolean, Undefined - if the full document name is passed, contains the document Posted attribute value.
//                                         Otherwise, contains Undefined.
//  * ValueTable - data that must be processed, column names map the register dimension names.
//
Function SelectRegisterRecordersToProcess(PositionInQueue, FullDocumentName, FullRegisterName, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	CheckSelectionParameters(AdditionalParameters);
	BuildParameters = SelectionBuildParameters(AdditionalParameters);
	
	If FullDocumentName = Undefined Then
		QueryText =
		"SELECT TOP 10000
		|	&SelectedFields
		|FROM
		|	#RegisterTableChanges AS RegisterTableChanges
		|		LEFT JOIN #RegisterRecordsTable AS RegisterTable
		|		ON RegisterTableChanges.Recorder = RegisterTable.Recorder
		|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
		|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
		|		#ConnectionToAdditionalSourcesRegistersQueryText
		|WHERE
		|	RegisterTableChanges.Node = &CurrentQueue
		|	AND TTLockedRecorder.Recorder IS NULL 
		|	AND &ConditionByAdditionalSourcesRegisters
		|
		|GROUP BY
		|	RegisterTableChanges.Recorder";
		
		If BuildParameters.SelectionByPage Then
			QueryText = QueryText + "
				|
				|HAVING
				|	&PagesCondition"
		EndIf;
		
		QueryText = QueryText + "
			|
			|ORDER BY
			|	&SelectionOrder";
		QueryText = StrReplace(QueryText, "#RegisterRecordsTable", FullRegisterName);
		SetRegisterOrderingFields(BuildParameters);
	Else
		QueryText =
		"SELECT TOP 10000
		|	&SelectedFields
		|FROM
		|	#RegisterTableChanges AS RegisterTableChanges
		|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
		|		ON RegisterTableChanges.Recorder = TTLockedRecorder.Recorder
		|		LEFT JOIN TTLockedReference AS TTLockedReference
		|		ON RegisterTableChanges.Recorder = TTLockedReference.Ref
		|		INNER JOIN #FullDocumentName AS DocumentTable
		|			#ConnectionToAdditionalSourcesByHeaderQueryText
		|		ON RegisterTableChanges.Recorder = DocumentTable.Ref
		|		#ConnectionToAdditionalSourcesByTabularSectionQueryText
		|		#ConnectionToAdditionalSourcesRegistersQueryText
		|
		|WHERE
		|	RegisterTableChanges.Node = &CurrentQueue
		|	AND RegisterTableChanges.Recorder REFS #FullDocumentName 
		|	AND TTLockedRecorder.Recorder IS NULL 
		|	AND TTLockedReference.Ref IS NULL 
		|	AND &ConditionByAdditionalSourcesReferences
		|	AND &ConditionByAdditionalSourcesRegisters
		|	AND &PagesCondition
		|
		|ORDER BY
		|	&SelectionOrder";
		AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
		AdditionalParametersForTTCreation.TempTableName = "TTLockedReference";
		CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullDocumentName, TempTablesManager, AdditionalParametersForTTCreation);
		SetRegisterOrderingFieldsByDocument(BuildParameters);
	EndIf;
	
	QueryText = StrReplace(QueryText, "#RegisterTableChanges", FullRegisterName + ".Changes");	
	
	AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
	AdditionalParametersForTTCreation.TempTableName = "TTLockedRecorder";
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullRegisterName, TempTablesManager, AdditionalParametersForTTCreation);
	SetSelectionSize(QueryText, AdditionalParameters);
	AddAdditionalSourceLockCheck(PositionInQueue, QueryText, FullDocumentName, FullRegisterName, TempTablesManager, False, AdditionalParameters);
	
	QueryText = StrReplace(QueryText, "#FullDocumentName", FullDocumentName);
		
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", QueueRef(PositionInQueue));
	
	SetFieldsByPages(Query, BuildParameters);
	SetOrderByPages(Query, BuildParameters);
	
	Return SelectDataToProcess(Query, BuildParameters);
	
EndFunction

// Returns a chunk of references that require processing.
//  The input is the data registered in the queue. Data in the higher-priority queues is processed first.
//	The returned document references are sorted by date (from newest to latest).
//
// Parameters:
//  PositionInQueue - Number - the position in the queue the handler and the data it will process 
//									are assigned to.
//  FullObjectName - String - the name of the object that require processing. For example, Document.GoodsReceipt.
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  * QueryResultSelection - the selection of references that require processing and selection fields:
//    ** Ref - AnyRef.
//  * ValueTable - data that must be processed, column names map the register dimension names.
//
Function SelectRefsToProcess(PositionInQueue, FullObjectName, AdditionalParameters = Undefined) Export
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	ObjectName = StrSplit(FullObjectName,".",False)[1];
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
	IsDocument = Common.IsDocument(ObjectMetadata)
				Or Common.IsTask(ObjectMetadata);
	
	CheckSelectionParameters(AdditionalParameters);
	BuildParameters = SelectionBuildParameters(AdditionalParameters);
	
	QueryText =
	"SELECT TOP 10000
	|	&SelectedFields
	|FROM
	|	#ObjectTableChanges AS ChangesTable
	|		LEFT JOIN #TTLockedReference AS TTLockedReference
	|		ON ChangesTable.Ref = TTLockedReference.Ref
	|		INNER JOIN #ObjectTable AS ObjectTable
	|			#ConnectionToAdditionalSourcesByHeaderQueryText
	|		ON ChangesTable.Ref = ObjectTable.Ref
	|		#ConnectionToAdditionalSourcesByTabularSectionQueryText
	|		#ConnectionToAdditionalSourcesRegistersQueryText
	|WHERE
	|	ChangesTable.Node = &CurrentQueue
	|	AND TTLockedReference.Ref IS NULL 
	|	AND &ConditionByAdditionalSourcesReferences
	|	AND &ConditionByAdditionalSourcesRegisters
	|	AND &PagesCondition";
	If IsDocument Or BuildParameters.SelectionByPage Then
		QueryText = QueryText + "
		|
		|ORDER BY
		|	&SelectionOrder";
	EndIf;
	QueryText = QueryText + "
	|;
	|DROP
	|	#TTLockedReference"; 
	SetRefsOrderingFields(BuildParameters, IsDocument);
	QueryText = StrReplace(QueryText, "#TTLockedReference","TTLocked" + ObjectName);
	QueryText = StrReplace(QueryText,"#ObjectTableChanges", FullObjectName + ".Changes");	
	QueryText = StrReplace(QueryText,"#ObjectTable", FullObjectName);	
	SetSelectionSize(QueryText, AdditionalParameters);
	TempTablesManager = New TempTablesManager();
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullObjectName, TempTablesManager);
	
	AddAdditionalSourceLockCheck(PositionInQueue, QueryText, FullObjectName, Undefined, TempTablesManager, False, AdditionalParameters);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", QueueRef(PositionInQueue));
	
	SetFieldsByPages(Query, BuildParameters);
	If IsDocument Or BuildParameters.SelectionByPage Then
		SetOrderByPages(Query, BuildParameters);
	EndIf;
	
	Return SelectDataToProcess(Query, BuildParameters);
	
EndFunction

// Creates temporary reference table that are not processed in the current queue and not locked by 
//  the lesser priority queues.
//  Table name: TTForProcessing<ObjectName>, for instance, TTForProcessingProducts.
//  Table columns:
//  * Ref - AnyRef.
//
// Parameters:
//  Queue           - Number - the position in the queue for the current handler.
//  FullObjectName  - String - full name of an object, for which the check is run (for instance, Catalog.Products).
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  Structure - temporary table formation result:
//  * HasRecordsInTemporaryTable - Boolean - the created table has at least one record. There are 
//                                            two reasons records can be missing:
//                                             All references have been processed or the references 
//                                             to be processed are locked by the lower-priority handlers.
//  * HasDataForProcessing - Boolean - the queue contains references to process.
//  * TemporaryTableName - String - a name of a created temporary table.
//
Function CreateTemporaryTableOfRefsToProcess(PositionInQueue, FullObjectName, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	ObjectName = StrSplit(FullObjectName,".",False)[1];
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
	
	If AdditionalParameters.SelectInBatches Then
		
		IsDocument = Common.IsDocument(ObjectMetadata)
					Or Common.IsTask(ObjectMetadata);
		
		QueryText =
		"SELECT
		|	ChangesTable.Ref AS Ref";
		If IsDocument Then
			QueryText = QueryText + ",
			|	ObjectTable.Date AS Date";
		EndIf;
		QueryText = QueryText + "
		|INTO TTToProcessRefFull
		|FROM
		|	#ObjectTableChanges AS ChangesTable
		|		LEFT JOIN #TTLockedReference AS TTLockedReference
		|		ON ChangesTable.Ref = TTLockedReference.Ref
		|		INNER JOIN #ObjectTable AS ObjectTable
		|			#ConnectionToAdditionalSourcesByHeaderQueryText
		|		ON ChangesTable.Ref = ObjectTable.Ref
		|			#ConnectionToAdditionalSourcesByTabularSectionQueryText
		|			#ConnectionToAdditionalSourcesRegistersQueryText
		|WHERE
		|	ChangesTable.Node = &CurrentQueue
		|	AND TTLockedReference.Ref IS NULL 
		|	AND &ConditionByAdditionalSourcesReferences
		|	AND &ConditionByAdditionalSourcesRegisters
		|
		|INDEX BY
		|	Ref 
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTToProcessRefFull.Ref AS Ref
		|INTO #TTToProcessRef
		|FROM
		|	TTToProcessRefFull AS TTToProcessRefFull
		|WHERE
		|	TTToProcessRefFull.Ref IN
		|			(SELECT TOP 10000
		|				TTToProcessRefFull.Ref AS Ref
		|			FROM
		|				TTToProcessRefFull AS TTToProcessRefFull";
		If IsDocument Then
			QueryText = QueryText + "
			|			ORDER BY
			|				TTToProcessRefFull.Date DESC";
		EndIf;
		
		QueryText = QueryText + "
		|)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP #TTLockedReference
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTToProcessRefFull"; 
		
	Else
		QueryText =
		"SELECT
		|	ChangesTable.Ref AS Ref
		|INTO #TTToProcessRef
		|FROM
		|	#ObjectTableChanges AS ChangesTable
		|		LEFT JOIN #TTLockedReference AS TTLockedReference
		|		ON ChangesTable.Ref = TTLockedReference.Ref
		|		INNER JOIN #ObjectTable AS ObjectTable
		|			#ConnectionToAdditionalSourcesByHeaderQueryText
		|		ON ChangesTable.Ref = ObjectTable.Ref
		|		#ConnectionToAdditionalSourcesByTabularSectionQueryText
		|		#ConnectionToAdditionalSourcesRegistersQueryText
		|WHERE
		|	ChangesTable.Node = &CurrentQueue
		|	AND TTLockedReference.Ref IS NULL
		|	AND &ConditionByAdditionalSourcesReferences
		|	AND &ConditionByAdditionalSourcesRegisters
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP #TTLockedReference"; 
	EndIf;
	
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName = "TTToProcess" + ObjectName;
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	
	QueryText = StrReplace(QueryText, "#TTLockedReference","TTLocked" + ObjectName);
	QueryText = StrReplace(QueryText, "#TTToProcessRef",TempTableName);
	QueryText = StrReplace(QueryText,"#ObjectTableChanges", FullObjectName + ".Changes");	
	
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullObjectName, TempTablesManager);
	
	AddAdditionalSourceLockCheck(PositionInQueue, QueryText, FullObjectName, Undefined, TempTablesManager, True, AdditionalParameters);
	
	QueryText = StrReplace(QueryText,"#ObjectTable", FullObjectName);	
	
	CurrentQueue = QueueRef(PositionInQueue);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", CurrentQueue);
	QueryResult = Query.ExecuteBatch();
	
	Result = New Structure("HasRecordsInTemporaryTable,HasDataToProcess,TempTableName", False, False,"");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult[0].Unload()[0].Count <> 0;
	
	If Result.HasRecordsInTemporaryTable Then
		Result.HasDataToProcess = True;
	Else
		Result.HasDataToProcess = HasDataToProcess(PositionInQueue, FullObjectName);
	EndIf;	
		
	Return Result;
	
EndFunction

// Returns the values of independent information register dimensions for processing.
// The input is the data registered in the queue. Data in the higher-priority queues is processed first.
//
// Parameters:
//  PositionInQueue - Number - the position in the queue the handler and the data it will process 
//                              are assigned to.
//  FullObjectName - String - the name of the object that require processing. For example, InformationRegister.ProductBarcodes.
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  * QueryResultSelection - the selection from dimension values that require processing. The field 
//                                 names match the register dimenstion names. If a dimension is not 
//                                 in the processing queue, this dimenstion selection value is blank.
//  * ValueTable - data that must be processed, column names map the register dimension names.
//
Function SelectStandaloneInformationRegisterDimensionsToProcess(PositionInQueue, FullObjectName, AdditionalParameters = Undefined) Export
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	ObjectName = StrSplit(FullObjectName,".",False)[1];
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
	BuildParameters = SelectionBuildParameters(AdditionalParameters, "ChangesTable");
	OrderingFieldsAreSet = OrderingFieldsAreSet(AdditionalParameters);
	OrderingRequired = OrderingFieldsAreSet Or BuildParameters.SelectionByPage;
	
	Query = New Query;
	QueryText =
	"SELECT TOP 10000
	|	&SelectedFields
	|FROM
	|	#ObjectTableChanges AS ChangesTable
	|	LEFT JOIN #TTLockedDimensions AS TTLockedDimensions
	|	ON &DimensionJoinConditionText
	|   #ConnectionToAdditionalSourcesQueryText
	|WHERE
	|	ChangesTable.Node = &CurrentQueue
	|	AND &UnlockedFilterConditionText
	|	AND &ConditionByAdditionalSourcesReferences
	|	AND &PagesCondition";
	
	If OrderingRequired Then
		SetStandaloneInformationRegisterOrderingFields(BuildParameters);
		QueryText = QueryText + "
			|ORDER BY
			|	&SelectionOrder
			|";
	EndIf;
	
	DimensionJoinConditionText = "TRUE";
	UnlockedFilterConditionText = "TRUE";
	FirstDimension = True;
	For Each Dimension In ObjectMetadata.Dimensions Do
		
		If Not Dimension.MainFilter Then
			Continue;
		EndIf;
		
		SetDimension(BuildParameters, Dimension.Name);
		DimensionJoinConditionText = DimensionJoinConditionText + "
		|	AND (ChangesTable." + Dimension.Name + " = TTLockedDimensions." + Dimension.Name + "
		|		OR ChangesTable." + Dimension.Name + " = &EmptyDimensionValue"+ Dimension.Name + "
		|		OR TTLockedDimensions." + Dimension.Name + " = &EmptyDimensionValue"+ Dimension.Name + ")";
		
		Query.SetParameter("EmptyDimensionValue"+ Dimension.Name, Dimension.Type.AdjustValue()); 
		If FirstDimension Then
			UnlockedFilterConditionText =  "TTLockedDimensions." + Dimension.Name + " IS NULL ";
			FirstDimension = False;
		EndIf;
	EndDo;
	
	NonPeriodicFlag = Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
	If ObjectMetadata.InformationRegisterPeriodicity <> NonPeriodicFlag
		AND ObjectMetadata.MainFilterOnPeriod Then
		SetPeriod(BuildParameters);
	EndIf;
	
	SetResources(BuildParameters, ObjectMetadata.Resources);
	SetAttributes(BuildParameters, ObjectMetadata.Attributes);
	
	QueryText = StrReplace(QueryText, "&DimensionJoinConditionText", DimensionJoinConditionText);
	QueryText = StrReplace(QueryText, "&UnlockedFilterConditionText", UnlockedFilterConditionText);
	QueryText = StrReplace(QueryText, "#ObjectTableChanges", FullObjectName + ".Changes");
	QueryText = StrReplace(QueryText, "#TTLockedDimensions","TTLocked" + ObjectName);
	SetSelectionSize(QueryText, AdditionalParameters);
	
	TempTablesManager = New TempTablesManager();
	
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullObjectName, TempTablesManager);
	
	AddAdditionalSourceLockCheckForStandaloneRegister(PositionInQueue,
																				QueryText,
																				FullObjectName,
																				TempTablesManager,
																				AdditionalParameters);	
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", QueueRef(PositionInQueue));
	
	SetFieldsByPages(Query, BuildParameters);
	If OrderingRequired Then
		SetOrderByPages(Query, BuildParameters);
	EndIf;
	
	Return SelectDataToProcess(Query, BuildParameters);
	
EndFunction

// Creates a temporary table with values of an independent information register for processing.
//  Table name: TTForProcessing<ObjectName>. Example: TTForProcessingProductsBarcodes.
//  The table columns match the register dimensions. If processing a dimension is not required,
//	leaves the selection by the dimension blank.
//
// Parameters:
//  PositionInQueue - Number - the position in the processing queue where the handler is running.
//  FullObjectName		 - String					 - full name of an object, for which the check is run (for instance, Catalog.Products).
//  TemporaryTablesManager - TemporaryTablesManager - the manager where a temporary table to be created.
//  AdditionalParameters - Structure - see InfobaseUpdate. AdditionalProcessingDataSelectionParameters.
// 
// Returns:
//  Structure - temporary table formation result:
//  * HasRecordsInTemporaryTable - Boolean - the created table has at least one record. There are 
//                                            two reasons records can be missing:
//                                              All references have been processed or the references 
//                                              to be processed are locked by the lower-priority handlers.
//  * HasDataForProcessing - Boolean - there is data for processing in the queue (subsequently, not everything is processed).
//  * TemporaryTableName - String - a name of a created temporary table.
//
Function CreateTemporaryTableOfStandaloneInformationRegisterDimensionsToProcess(Queue, FullObjectName, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	ObjectName = StrSplit(FullObjectName,".",False)[1];
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
		                      
	Query = New Query;
	If AdditionalParameters.SelectInBatches Then
		QueryText =
		"SELECT
		|	&DimensionSelectionText
		|INTO TTToProcessDimensionsFull
		|FROM
		|	#ObjectTableChanges AS ChangesTable
		|		LEFT JOIN #TTLockedDimensions AS TTLockedDimensions
		|		ON (&DimensionJoinConditionText)
		|   #ConnectionToAdditionalSourcesQueryText
		|WHERE
		|	ChangesTable.Node = &CurrentQueue
		|	AND &UnlockedFilterConditionText
		|	AND &ConditionByAdditionalSourcesReferences
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 10000
		|	&DimensionSelectionText
		|INTO #TTToProcessDimensions
		|FROM
		|	TTToProcessDimensionsFull AS ChangesTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP #TTLockedDimensions
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTToProcessDimensionsFull";
	Else
		QueryText =
		"SELECT
		|	&DimensionSelectionText
		|INTO #TTToProcessDimensions
		|FROM
		|	#ObjectTableChanges AS ChangesTable
		|	LEFT JOIN #TTLockedDimensions AS TTLockedDimensions
		|	ON &DimensionJoinConditionText
		|   #ConnectionToAdditionalSourcesQueryText
		|WHERE
		|	ChangesTable.Node = &CurrentQueue
		|	AND &UnlockedFilterConditionText
		|	AND &ConditionByAdditionalSourcesReferences
		|;
		|DROP
		|	#TTLockedDimensions";
	EndIf;
	DimensionSelectionText = "";
	DimensionJoinConditionText = "TRUE";
	
	FirstDimension = True;
	PeriodicRegister = 
		(ObjectMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical)
		AND ObjectMetadata.MainFilterOnPeriod;
	For Each Dimension In ObjectMetadata.Dimensions Do
		If Not Dimension.MainFilter Then
			Continue;
		EndIf;
		
		DimensionSelectionText = DimensionSelectionText + "
		|	ChangesTable." + Dimension.Name + " AS " + Dimension.Name + ",";
		
		DimensionJoinConditionText = DimensionJoinConditionText + "
		|	AND ChangesTable." + Dimension.Name + " = TTLockedDimensions." + Dimension.Name + "
		|		OR ChangesTable." + Dimension.Name + " = &EmptyDimensionValue"+ Dimension.Name + "
		|		OR TTLockedDimensions." + Dimension.Name + " = &EmptyDimensionValue"+ Dimension.Name;
		Query.SetParameter("EmptyDimensionValue"+ Dimension.Name, Dimension.Type.AdjustValue()); 
		
		If FirstDimension Then
			UnlockedFilterConditionText =  "TTLockedDimensions." + Dimension.Name + " IS NULL ";
			
			If PeriodicRegister Then
				DimensionSelectionText = DimensionSelectionText + "
					|	ChangesTable.Period AS Period,";
			EndIf;
			
			FirstDimension = False;
		EndIf;
	EndDo;
	
	DimensionSelectionText = Left(DimensionSelectionText, StrLen(DimensionSelectionText) - 1);
	
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName = "TTToProcess" + ObjectName;
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DimensionSelectionText", DimensionSelectionText);
	QueryText = StrReplace(QueryText, "&DimensionJoinConditionText", DimensionJoinConditionText);
	QueryText = StrReplace(QueryText, "&UnlockedFilterConditionText", UnlockedFilterConditionText);
	QueryText = StrReplace(QueryText,"#ObjectTableChanges", FullObjectName + ".Changes");	
	QueryText = StrReplace(QueryText, "#TTLockedDimensions","TTLocked" + ObjectName);
	QueryText = StrReplace(QueryText, "#TTToProcessDimensions",TempTableName);
	
	CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(Queue, FullObjectName, TempTablesManager);
	AddAdditionalSourceLockCheckForStandaloneRegister(Queue,
																				QueryText,
																				FullObjectName,
																				TempTablesManager,
																				AdditionalParameters);	
	
	CurrentQueue = QueueRef(Queue);
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentQueue", CurrentQueue);
	QueryResult = Query.ExecuteBatch();
	
	Result = New Structure("HasRecordsInTemporaryTable,HasDataToProcess,TempTableName", False, False,"");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult[0].Unload()[0].Count <> 0;
	
	If Result.HasRecordsInTemporaryTable Then
		Result.HasDataToProcess = True;
	Else
		Result.HasDataToProcess = HasDataToProcess(Queue, FullObjectName);
	EndIf;	
		
	Return Result;
	
EndFunction

// Checks if there is unprocessed data.
//
// Parameters:
//  Queue    - Number        - a queue, to which a handler relates and in which data to process is 
//                              registered.
//             - Undefined - checked if general processing is complete;
//             - Array       - checked if there is data to be processed in the queues list.
//  FullObjectNameMetadata- String, MetadataObject - a full name of an object being processed or its 
//                              metadata. For example, "Document.GoodsReceipt"
//                            - Array - an array of full names of metadata objects; an array cannot 
//                              have independent information registers.
//  Filter - AnyReference, Structure, Undefined, Array - filters data to be checked.
//                              If passed Undefined - checked for the whole object type.
//                              If an object is a register subordinate to a recorder, then a 
//                                 reference to a recorder or an array of references is filtered.
//                              If an object is of a reference type, then either a reference or an array of references is filtered.
//                              If an object is an independent information register, then a structure containing values of dimensions is filtered.
//                              Structure key - dimension name, value - filter value (an array of values can be passed).
//
// Returns:
//  Boolean - True if not all data is processed.
//
Function HasDataToProcess(PositionInQueue, FullObjectNameMetadata, Filter = Undefined) Export
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
		If Not IsSubordinateDIBNode Then
			Return False;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return False;
		EndIf;
	EndIf;
	
	If TypeOf(FullObjectNameMetadata) = Type("String") Then
		FullNamesOfObjectsToProcess = StrSplit(FullObjectNameMetadata, ",");
	ElsIf TypeOf(FullObjectNameMetadata) = Type("Array") Then
		FullNamesOfObjectsToProcess = FullObjectNameMetadata;
	ElsIf TypeOf(FullObjectNameMetadata) = Type("MetadataObject") Then
		FullNamesOfObjectsToProcess = New Array;
		FullNamesOfObjectsToProcess.Add(FullObjectNameMetadata.FullName());
	Else
		ExceptionText = NStr("ru = 'Передан неправильный тип параметра ""ПолноеИмяМетаданныеОбъекта"" в функцию ОбновлениеИнформационнойБазы.ЕстьДанныеДляОбработки'; en = 'The FullObjectNameMetadata parameter passed to InfobaseUpdate.HasDataToProcess function has invalid type.'; pl = 'Został przekazany nieprawidłowy typ parametru ""FullObjectNameMetadata"" do funkcji InfobaseUpdate.HasDataToProcess';de = 'Fehlerhafter Parametertyp ""FullObjectNameMetadata"" wurde an die Funktion InfobaseUpdate.HasDataToProcess übertragen';ro = 'În funcția InfobaseUpdate.HasDataToProcess este transmis tipul incorect al parametrului ""FullObjectNameMetadata""';tr = 'InfobaseUpdate.HasDataToProcess işlevinde ""FullObjectNameMetadata"" parametresinin türü yanlış aktarılmıştır.'; es_ES = 'El parámetro FullObjectNameMetadata pasado a la función InfobaseUpdate.HasDataToProcess tiene un tipo no válido.'");
		Raise ExceptionText;
	EndIf;	
	
	Query = New Query;
	
	QueryTexts = New Array;
	FilterSet = False;
	
	For each TypeToProcess In FullNamesOfObjectsToProcess Do 
		
		If TypeOf(TypeToProcess) = Type("MetadataObject") Then
			ObjectMetadata = TypeToProcess;
			FullObjectName  = TypeToProcess.FullName();
		Else
			ObjectMetadata = Metadata.FindByFullName(TypeToProcess);
			FullObjectName  = TypeToProcess;
		EndIf;
		
		ObjectName = StrSplit(FullObjectName,".",False)[1];
		
		DataFilterCondition = "TRUE";
		
		If Common.IsRefTypeObject(ObjectMetadata) Then
			QueryText =
			"SELECT TOP 1
			|	ChangesTable.Ref AS Ref
			|FROM
			|	#ChangesTable AS ChangesTable
			|	LEFT JOIN #ObjectTable AS #ObjectName
			|		ON #ObjectName.Ref = ChangesTable.Ref
			|WHERE
			|	&NodeFilterCriterion
			|	AND &DataFilterCriterion
			|	AND NOT #ObjectName.Ref IS NULL";
			
			Query.SetParameter("Ref", Filter);
			
			If Filter <> Undefined Then
				DataFilterCondition = "ChangesTable.Ref IN (&Filter)";
			EndIf;
			
		ElsIf Common.IsInformationRegister(ObjectMetadata)
			AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			
			If FullNamesOfObjectsToProcess.Count() > 1 Then
				ExceptionText = NStr("ru = 'В массиве имен в параметре ""ПолноеИмяМетаданныеОбъекта"" в функцию ОбновлениеИнформационнойБазы.ЕстьДанныеДляОбработки передан независимый регистр сведений.'; en = 'An independent information register is passed to the InfobaseUpdate.HasDataToProcess function in the FullObjectNameMetadata parameter (which has Array type).'; pl = 'W masywie nazw w parametrze ""FullObjectNameMetadata"" do funkcji InfobaseUpdate.HasDataToProcess został przekazany niezależny rejestr informacji.';de = 'Im Namensarray im Parameter ""FullObjectNameMetadata"" in der Funktion InfobaseUpdate.HasDataToProcess wurde ein unabhängiges Informationsregister übertragen.';ro = 'În mulțimea numelor în parametrul ""FullObjectNameMetadata"" în funcția InfobaseUpdate.HasDataToProcess este transmis registrul de date independent.';tr = 'InfobaseUpdate.HasDataToProcess işlevinde ""FullObjectNameMetadata"" parametresinde isim masifinde bağımsız bilgi kaydı aktarıldı.'; es_ES = 'Se pasa un registro de información independiente a la función InfobaseUpdate.HasDataToProcess en el parámetro FullObjectNameMetadata (que tiene el tipo Matriz).'");
				Raise ExceptionText;
			EndIf;	
			
			FilterSet = True;
			
			QueryText =
			"SELECT TOP 1
			|	&DimensionSelectionText
			|FROM
			|	#ChangesTable AS ChangesTable
			|WHERE
			|	&NodeFilterCriterion
			|	AND &DataFilterCriterion";
			
			DimensionSelectionText = "";
			For Each Dimension In ObjectMetadata.Dimensions Do
				If Not Dimension.MainFilter Then
					Continue;
				EndIf;
				
				DimensionSelectionText = DimensionSelectionText + "
				|	ChangesTable." + Dimension.Name + " AS " + Dimension.Name + ",";
				
				If Filter <> Undefined Then
					DataFilterCondition = DataFilterCondition + "
					|	AND (ChangesTable." + Dimension.Name + " IN (&FilterValue" + Dimension.Name + ")
					|		OR ChangesTable." + Dimension.Name + " = &EmptyValue" + Dimension.Name + ")";
					
					If Filter.Property(Dimension.Name) Then
						Query.SetParameter("FilterValue" + Dimension.Name, Filter[Dimension.Name]);
					Else
						Query.SetParameter("FilterValue" + Dimension.Name, Dimension.Type.AdjustValue());
					EndIf;
					
					Query.SetParameter("EmptyValue" + Dimension.Name, Dimension.Type.AdjustValue());
				EndIf;
			EndDo;
			
			If IsBlankString(DimensionSelectionText) Then
				DimensionSelectionText = "*";
			Else
				DimensionSelectionText = Left(DimensionSelectionText, StrLen(DimensionSelectionText) - 1);
			EndIf;
			
			QueryText = StrReplace(QueryText, "&DimensionSelectionText", DimensionSelectionText);
			
		ElsIf Common.IsRegister(ObjectMetadata) Then
			
			QueryText =
			"SELECT TOP 1
			|	ChangesTable.Recorder AS Ref
			|FROM
			|	#ChangesTable AS ChangesTable
			|WHERE
			|	&NodeFilterCriterion
			|	AND &DataFilterCriterion";
			
			If Filter <> Undefined Then
				DataFilterCondition = "ChangesTable.Recorder IN (&Filter)";
			EndIf;
			
		Else
			ExceptionText = NStr("ru = 'Для типа метаданных ""%ObjectMetadata%"" не поддерживается проверка в функции ОбновлениеИнформационнойБазы.ЕстьДанныеДляОбработки'; en = 'The InfobaseUpdate.HasDataToProcess function does not support chechs for the %ObjectMetadata% metadata type.'; pl = 'Dla typu metadanych ""%ObjectMetadata%"" nie jest obsługiwana weryfikacja w funkcji InfobaseUpdate.HasDataToProcess';de = 'Für den Metadatentyp ""%ObjectMetadata%"" wird die Überprüfung in der Funktion InfobaseUpdate.HasDataToProcess nicht unterstützt.';ro = 'Pentru tipul de metadate ""%ObjectMetadata%"" nu este susținută analiza în funcția InfobaseUpdate.HasDataToProcess';tr = '""%ObjectMetadata%"" tür metaveri için InfobaseUpdate.HasDataToProcess işlevinde doğrulama desteklenmiyor'; es_ES = 'Para el tipo de datos ""%ObjectMetadata%"" no se admite la prueba en la función InfobaseUpdate.HasDataToProcess.'");
			ExceptionText = StrReplace(ExceptionText, "%ObjectMetadata%", String(ObjectMetadata)); 
			Raise ExceptionText;
		EndIf;
		
		QueryText = StrReplace(QueryText, "#ChangesTable", FullObjectName + ".Changes");
		QueryText = StrReplace(QueryText, "#ObjectTable", FullObjectName);
		QueryText = StrReplace(QueryText, "#ObjectName", ObjectName);
		QueryText = StrReplace(QueryText, "&DataFilterCriterion", DataFilterCondition);
		
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	Connector = "
	|
	|UNION ALL
	|";

	QueryText = StrConcat(QueryTexts, Connector);
	
	If PositionInQueue = Undefined Then
		NodeFilterCondition = "	ChangesTable.Node REFS ExchangePlan.InfobaseUpdate ";
	Else
		NodeFilterCondition = "	ChangesTable.Node IN (&Nodes) ";
		If TypeOf(PositionInQueue) = Type("Array") Then
			Query.SetParameter("Nodes", PositionInQueue);
		Else
			Query.SetParameter("Nodes", QueueRef(PositionInQueue));
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&NodeFilterCriterion", NodeFilterCondition);
	
	If Not FilterSet Then
		Query.SetParameter("Filter", Filter);
	EndIf;
		
	Query.Text = QueryText;
	
	Return Not Query.Execute().IsEmpty(); 
	
EndFunction

// Checks if all data is processed.
//
// Parameters:
//  Queue    - Number        - a queue, to which a handler relates and in which data to process is 
//                              registered.
//             - Undefined - checked if general processing is complete;
//             - Array       - checked if there is data to be processed in the queues list.
//  FullObjectNameMetadata- String, MetadataObject - a full name of an object being processed or its 
//                              metadata. For example, "Document.GoodsReceipt"
//                            - Array - an array of full names of metadata objects; an array cannot 
//                              have independent information registers.
//  Filter - AnyReference, Structure, Undefined, Array - filters data to be checked.
//                              If passed Undefined - checked for the whole object type.
//                              If an object is a register subordinate to a recorder, then a 
//                                 reference to a recorder or an array of references is filtered.
//                              If an object is of a reference type, then either a reference or an array of references is filtered.
//                              If an object is an independent information register, then a structure containing values of dimensions is filtered.
//                              Structure key - dimension name, value - filter value (an array of values can be passed).
// 
// Returns:
//  Boolean - True if all data is processed.
//
Function DataProcessingCompleted(PositionInQueue, FullObjectNameMetadata, Filter = Undefined) Export
	
	Return Not HasDataToProcess(PositionInQueue, FullObjectNameMetadata, Filter);
	
EndFunction

// Checks if there is data locked by smaller queues.
//
// Parameters:
//  Queue - Number, Undefined - a queue, to which a handler relates and in which data to process is 
//                                  registered.
//  FullObjectNameMetadata - String, MetadataObject - a full name of an object being processed or 
//                                        its metadata. For example, "Document.GoodsReceipt"
//                             - Array - an array of full names of metadata objects; an array cannot 
//                                        have independent information registers.
// 
// Returns:
//  Boolean - True if processing of the object is locked by smaller queues.
//
Function HasDataLockedByPreviousQueues(PositionInQueue, FullObjectNameMetadata) Export
	
	Return HasDataToProcess(EarlierQueueNodes(PositionInQueue), FullObjectNameMetadata);
	
EndFunction

// Checks if data processing carried our by handlers of an earlier queue was finished.
//
// Parameters:
//  Queue    - Number        - a queue, to which a handler relates and in which data to process is 
//                              registered.
//             - Undefined - checked if general processing is complete;
//             - Array       - checked if there is data to be processed in the queues list.
//  Data     - AnyReference, RecordSet, Object, FormDataStructure - a reference to an object, an 
//                              object proper, or a set of records to be checked.
//                              If ExtendedParameters.IsRegisterRecords = True, then Data is a 
//                              recorder of a register specified in AdditionalParameters.
//  AdditionalParameters   - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
//  MetadataAndFilter          - Structure - see InfobaseUpdate.MetadataAndFilterByData. 
// 
// Returns:
//  Boolean - True if the passed object is updated to a new version and can be changed.
//
Function CanReadAndEdit(PositionInQueue, Data, AdditionalParameters = Undefined, MetadataAndFilter = Undefined) Export
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		If Not Common.IsSubordinateDIBNode() Then
			Return True;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return True;
		EndIf;
	EndIf;
	
	If MetadataAndFilter = Undefined Then
		MetadataAndFilter = MetadataAndFilterByData(Data, AdditionalParameters);
	EndIf;
	
	If MetadataAndFilter.IsNew Then
		Return True;
	EndIf;
	
	If PositionInQueue = Undefined Then
		Return Not HasDataToProcess(Undefined, MetadataAndFilter.Metadata, MetadataAndFilter.Filter);
	Else
		Return Not HasDataToProcess(EarlierQueueNodes(PositionInQueue), MetadataAndFilter.Metadata, MetadataAndFilter.Filter);
	EndIf;
	
EndFunction

// Creates a temporary table containing locked data.
// Table name: TTLocked<ObjectName>, for example TTLockedProducts.
//  Table columns:
//      for the reference type objects
//          * Ref;
//      for registers subordinate to a recorder
//          * Recorder;
//      for registers containing a direct record
//          * columns that correspond to dimensions of a register.
//
// Parameters:
//  Queue                 - Number, Undefined - the processing queue the current handler is being executed in.
//                             If passed Undefined, then checked in all queues.
//  FullObjectName        - String - full name of an object, for which the check is run (for 
//                             instance, Catalog.Products).
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  AdditionalParameters - Structure - see InfobaseUpdate. 
//                             AdditionalProcessingDataSelectionParameters, the SelectInBatches 
//                             parameter is ignored, blocked data is always placed into a table in full.
//
// Returns:
//  Structure - structure with the following properties:
//     * HasRecordsInTemporaryTable - Boolean - the created table has at least one record.
//     * TemporaryTableName          - String - the name of the created table.
//
Function CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullObjectName, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
	
	If Common.IsRefTypeObject(ObjectMetadata) Then
		If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
			QueryText =
			"SELECT DISTINCT
			|	&EmptyValue AS Ref
			|INTO #TempTableName
			|WHERE
			|	FALSE";
			                                           
			Query.SetParameter("EmptyValue", ObjectMetadata.StandardAttributes.Ref.Type.AdjustValue()); 
		Else	
			QueryText =
			"SELECT DISTINCT
			|	ChangesTable.Ref AS Ref
			|INTO #TempTableName
			|FROM
			|	#ChangesTable AS ChangesTable
			|WHERE
			|	&NodeFilterCriterion
			|
			|INDEX BY
			|	Ref";
		EndIf;
	ElsIf Common.IsInformationRegister(ObjectMetadata)
		AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
		
		If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
			QueryText =
			"SELECT DISTINCT
			|	&DimensionSelectionText
			|INTO #TempTableName
			|WHERE
			|	FALSE";
			DimensionSelectionText = "";
			For Each Dimension In ObjectMetadata.Dimensions Do
				If Not Dimension.MainFilter Then
					Continue;
				EndIf;
				
				DimensionSelectionText = DimensionSelectionText + "
				|	&EmptyDimensionValue"+ Dimension.Name + " AS " + Dimension.Name + ",";
				Query.SetParameter("EmptyDimensionValue"+ Dimension.Name, Dimension.Type.AdjustValue()); 
			EndDo;
			
		Else
			QueryText =
			"SELECT DISTINCT
			|	&DimensionSelectionText
			|INTO #TempTableName
			|FROM
			|	#ChangesTable AS ChangesTable
			|WHERE
			|	&NodeFilterCriterion ";
			DimensionSelectionText = "";
			For Each Dimension In ObjectMetadata.Dimensions Do
				If Not Dimension.MainFilter Then
					Continue;
				EndIf;
				
				DimensionSelectionText = DimensionSelectionText + "
				|	ChangesTable." + Dimension.Name + " AS " + Dimension.Name + ",";
			EndDo;
		EndIf;
		
		NonPeriodicFlag = Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
		If ObjectMetadata.InformationRegisterPeriodicity <> NonPeriodicFlag
			AND ObjectMetadata.MainFilterOnPeriod Then
			DimensionSelectionText = DimensionSelectionText + "
				|	ChangesTable.Period AS Period,";
		EndIf;
		
		If IsBlankString(DimensionSelectionText) Then
			DimensionSelectionText = "*";
		Else
			DimensionSelectionText = Left(DimensionSelectionText, StrLen(DimensionSelectionText) - 1);
		EndIf;
		
		QueryText = StrReplace(QueryText, "&DimensionSelectionText", DimensionSelectionText);
		
	ElsIf Common.IsRegister(ObjectMetadata) Then
		
		If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
			QueryText =
			"SELECT DISTINCT
			|	&EmptyValue AS Recorder
			|INTO #TempTableName
			|WHERE
			|	FALSE";
			
			Query.SetParameter("EmptyValue", ObjectMetadata.StandardAttributes.Recorder.Type.AdjustValue()); 
			
		Else
			QueryText =
			"SELECT DISTINCT
			|	ChangesTable.Recorder AS Recorder
			|INTO #TempTableName
			|FROM
			|	#ChangesTable AS ChangesTable
			|WHERE
			|	&NodeFilterCriterion
			|
			|INDEX BY
			|	Recorder";
		EndIf;
		
	Else
		ExceptionText = NStr("ru = 'Для этого типа метаданных не поддерживается проверка в функции ОбновлениеИнформационнойБазы.СоздатьВременнуюТаблицуЗаблокированныхДляЧтенияИИзмененияДанных.'; en = 'The InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing function does not support checks for this metadata type.'; pl = 'Dla tego typu metadanych nie jest obsługiwana weryfikacja w funkcji InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing.';de = 'Diese Art von Metadaten unterstützt keine Prüfung in der Funktion InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing.';ro = 'Pentru acest tip de metadate nu este susținută analiza în funcția InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing.';tr = 'Bu tür meta veri için InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing işlevinde doğrulama desteklenmiyor.'; es_ES = 'Para este tipo de metadatos, no se admiten las comprobaciones en la función InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing.'");
		Raise ExceptionText;
	EndIf;
	
	If Not GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		
		If PositionInQueue = Undefined Then
			NodeFilterCondition = "	ChangesTable.Node REFS ExchangePlan.InfobaseUpdate ";
		Else
			NodeFilterCondition = "	ChangesTable.Node IN (&Nodes) ";
			Query.SetParameter("Nodes", EarlierQueueNodes(PositionInQueue));
		EndIf;	
		QueryText = StrReplace(QueryText, "&NodeFilterCriterion", NodeFilterCondition);
	
		QueryText = StrReplace(QueryText, "#ChangesTable", FullObjectName + ".Changes");
		
	EndIf;
	
	ObjectName = StrSplit(FullObjectName, ".")[1];
	
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName =  "TTLocked"+ObjectName;
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	Result = New Structure("HasRecordsInTemporaryTable,TempTableName", False, "");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult.Unload()[0].Count <> 0;
			
	Return Result;
	
EndFunction

// Creates a temporary table of blocked references.
//  Table name: TTLocked.
//  Table columns:
//    * Ref.
//
// Parameters:
//  Queue                 - Number, Undefined - the processing queue the current handler is being 
//                             executed in. If passed Undefined, then checked in all queues.
//  FullObjectName        - String, Array - full name of an object, for which the check is run (for 
//                             instance, Catalog.Products).
//                             It is allowed to pass objects of a reference type or registers subordinate to a recorder.
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  AdditionalParameters - Structure - see InfobaseUpdate. 
//                             AdditionalProcessingDataSelectionParameters, the SelectInBatches 
//                             parameter is ignored, blocked data is always placed into a table in full.
//
// Returns:
//  Structure - structure with the following properties:
//    * HasRecordsInTemporaryTable - Boolean - the created table has at least one record.
//    * TemporaryTableName          - String - the name of the created table.
//
Function CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing(PositionInQueue, FullNamesOfObjects, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		QueryText =
		"SELECT DISTINCT
		|	UNDEFINED AS Ref
		|INTO #TempTableName
		|WHERE
		|	FALSE";
	Else	
		If TypeOf(FullNamesOfObjects) = Type("String") Then
			FullObjectNamesArray = StrSplit(FullNamesOfObjects,",",False);
		ElsIf TypeOf(FullNamesOfObjects) = Type("Array") Then 
			FullObjectNamesArray = FullNamesOfObjects;
		Else
			FullObjectNamesArray = New Array;
			FullObjectNamesArray.Add(FullNamesOfObjects);
		EndIf;
		
		QueryTextArray = New Array;
		
		HasRegisters = False;
		
		For Each TypeToProcess In FullObjectNamesArray Do
			
			If TypeOf(TypeToProcess) = Type("MetadataObject") Then
				ObjectMetadata = TypeToProcess;
				FullObjectName  = TypeToProcess.FullName();
			Else
				ObjectMetadata = Metadata.FindByFullName(TypeToProcess);
				FullObjectName  = TypeToProcess;
			EndIf;
			
			ObjectMetadata = Metadata.FindByFullName(FullObjectName);
			
			If Common.IsRefTypeObject(ObjectMetadata) Then
				If QueryTextArray.Count() = 0 Then
					QueryText =
					"SELECT DISTINCT
					|	ChangesTable.Ref AS Ref
					|//FirstQuery
					|FROM
					|	#ChangesTable AS ChangesTable
					|WHERE
					|	&NodeFilterCriterion";
				Else
					QueryText =
					"SELECT DISTINCT
					|	ChangesTable.Ref AS Ref
					|FROM
					|	#ChangesTable AS ChangesTable
					|WHERE
					|	&NodeFilterCriterion";	
				EndIf;
			ElsIf Common.IsRegister(ObjectMetadata) Then
				If QueryTextArray.Count() = 0 Then
					QueryText =
					"SELECT DISTINCT
					|	ChangesTable.Recorder AS Ref
					|//FirstQuery
					|FROM
					|	#ChangesTable AS ChangesTable
					|WHERE
					|	&NodeFilterCriterion";
				Else
					QueryText =
					"SELECT DISTINCT
					|	ChangesTable.Recorder AS Ref
					|FROM
					|	#ChangesTable AS ChangesTable
					|WHERE
					|	&NodeFilterCriterion";	
				EndIf;
				
				HasRegisters = True;
				
			Else
				ExceptionText = NStr("ru = 'Для типа метаданных ""%ObjectMetadata%"" не поддерживается проверка в функции ОбновлениеИнформационнойБазы.СоздатьВременнуюТаблицуЗаблокированныхДляЧтенияИИзмененияСсылок'; en = 'The InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing function does no support checks for the %ObjectMetadata% metadata type.'; pl = 'W przypadku typu metadanych %ObjectMetadata% sprawdzanie funkcji InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing nie jest obsługiwane.';de = 'Für den Metadatentyp ""%ObjectMetadata%"" wird die Überprüfung in der Funktion InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing nicht unterstützt.';ro = 'Pentru tipul de metadate ""%ObjectMetadata%"" nu este susținută verificarea în funcția InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing';tr = '""%ObjectMetadata%"" tür metaveri için InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing işlevinde doğrulama desteklenmiyor'; es_ES = 'Para el tipo de metadatos ""%ObjectMetadata%"" no se admite la prueba en la función InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing'");
				ExceptionText = StrReplace(ExceptionText, "%ObjectMetadata%", String(ObjectMetadata)); 
				Raise ExceptionText;
			EndIf;
		
			QueryText = StrReplace(QueryText, "#ChangesTable", FullObjectName + ".Changes");
			
			QueryTextArray.Add(QueryText);
		EndDo;
		
		Connector = "
		|
		|UNION ALL
		|";
		
		QueryText = StrConcat(QueryTextArray, Connector); 
		
		If HasRegisters
			AND QueryTextArray.Count() > 1 Then
			QueryText =
			"SELECT DISTINCT
			|	NestedQuery.Ref AS Ref
			|INTO #TempTableName
			|FROM
			|	(" + QueryText + ") AS NestedQuery
			|
			|INDEX BY
			|	Ref";
			QueryText = StrReplace(QueryText, "//FirstQuery", "");
		Else
			QueryText = QueryText + "
			|
			|INDEX BY
			|	Ref";
			QueryText = StrReplace(QueryText, "//FirstQuery", "INTO #TempTableName");
		EndIf;
		
		If PositionInQueue = Undefined Then
			NodeFilterCondition = "	ChangesTable.Node REFS ExchangePlan.InfobaseUpdate ";
		Else
			NodeFilterCondition = "	ChangesTable.Node IN (&Nodes) ";
			Query.SetParameter("Nodes", EarlierQueueNodes(PositionInQueue));
		EndIf;	
		QueryText = StrReplace(QueryText, "&NodeFilterCriterion", NodeFilterCondition);
	EndIf;	
	
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName =  "TTLocked";
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	Result = New Structure("HasRecordsInTemporaryTable,TempTableName", False, "");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult.Unload()[0].Count <> 0;
			
	Return Result;
	
EndFunction

// Creates a temporary table of changes in register dimensions subordinate to recorders for dimensions that have unprocessed recorders.
//  Creates a temporary table of changes in register dimensions subordinate to recorders for dimensions that have unprocessed recorders:
//  - determine locked recorders;
//  - join with the main recorder table by these recorders;
//  - get the values of changes from the main table;
//  - perform the grouping.
//  Table name: TTLocked<ObjectName>, for example, TTLockedStock.
//  The table columns match the passed dimensions.
//
// Parameters:
//  Queue                 - Number, Undefined - the processing queue the current handler is being 
//                             executed in. If passed Undefined, then checked in all queues.
//                             
//  RegisterFullName       - String - the name of the register that requires record update.
//                             For example, AccumulationRegister.Stock.
//  Dimensions               - String, Array - the name of dimensions by which the lock must be 
//                             checked, separated by commas, or an array of names.
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  AdditionalParameters - Structure - see InfobaseUpdate. 
//                             AdditionalProcessingDataSelectionParameters, the SelectInBatches 
//                             parameter is ignored, blocked data is always placed into a table in full.
//
// Returns:
//  Structure - structure with the following properties:
//   * HasRecordsInTemporaryTable - Boolean - the created table has at least one record.
//   * TemporaryTableName          - String - the name of the created table.
//
Function CreateTemporaryTableOfLockedDimensionValues(PositionInQueue, FullRegisterName, Dimensions, TempTablesManager, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalProcessingDataSelectionParameters();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If TypeOf(Dimensions) = Type("String") Then
		DimensionsArray = StrSplit(Dimensions, ",", False);
	Else
		DimensionsArray = Dimensions;
	EndIf;
	
	ObjectMetadata = Metadata.FindByFullName(FullRegisterName);
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		QueryText =
		"SELECT DISTINCT
		|	&DimensionValues
		|INTO #TempTableName
		|WHERE
		|	FALSE";
		DimensionValues = "";
		For Each DimensionStr In DimensionsArray Do
			
			Dimension = ObjectMetadata.Dimensions.Find(DimensionStr);
			
			DimensionValues = DimensionValues + "
			|	&EmptyDimensionValue"+ Dimension.Name + " AS " + Dimension.Name + ",";
			Query.SetParameter("EmptyDimensionValue"+ Dimension.Name, Dimension.Type.AdjustValue()); 
			
		EndDo;
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	&DimensionValues
		|INTO #TempTableName
		|FROM
		|	#ChangesTable AS ChangesTable
		|		INNER JOIN #RegisterTable AS RegisterTable
		|		ON ChangesTable.Recorder = RegisterTable.Recorder
		|WHERE
		|	&NodeFilterCriterion";
		
		DimensionValues = "";
		For Each Dimension In DimensionsArray Do
			
			DimensionValues = DimensionValues + "
			|	RegisterTable." + Dimension + " AS " + Dimension + ","; 	
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "#ChangesTable", FullRegisterName + ".Changes");
		QueryText = StrReplace(QueryText, "#RegisterTable", FullRegisterName);
		
		If PositionInQueue = Undefined Then
			NodeFilterCondition = "	ChangesTable.Node REFS ExchangePlan.InfobaseUpdate ";
		Else
			NodeFilterCondition = "	ChangesTable.Node IN (&Nodes) ";
			Query.SetParameter("Nodes", EarlierQueueNodes(PositionInQueue));
		EndIf;	
		
		QueryText = StrReplace(QueryText, "&NodeFilterCriterion", NodeFilterCondition);
		
		
	EndIf;
	
	ObjectName = StrSplit(FullRegisterName, ".")[1];
	If IsBlankString(AdditionalParameters.TempTableName) Then
		TempTableName =  "TTLocked" + ObjectName;
	Else
		TempTableName = AdditionalParameters.TempTableName;
	EndIf;
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	DimensionValues = Left(DimensionValues, StrLen(DimensionValues) - 1);
	QueryText = StrReplace(QueryText, "&DimensionValues", DimensionValues);
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	Result = New Structure("HasRecordsInTemporaryTable,TempTableName", False, "");
	Result.TempTableName = TempTableName;
	Result.HasRecordsInTemporaryTable = QueryResult.Unload()[0].Count <> 0;
			
	Return Result;
	
EndFunction

// The function is used for checking objects in opening forms and before recording.
// It can be used as a function for checking by default in case there is enough logics - blocked 
// objects are registered on the InfobaseUpdate exchange plan nodes.
//
// Parameters:
//  MetadataAndFilter - Structure - see InfobaseUpdate.MetadataAndFilterByData. 
//
// Returns:
//  Boolean - True if the object is updated and available for changing.
//
Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	Return CanReadAndEdit(Undefined, MetadataAndFilter.Data,,MetadataAndFilter); 
	
EndFunction

// Data selection through SelectStandaloneInformationRegisterDimensionsToProcess().
//
// Returns:
//  String - the "IndependentInfoRegistryMeasurements" constant.
//
Function SelectionMethodOfIndependentInfoRegistryMeasurements() Export
	
	Return "IndependentInfoRegistryMeasurements";
	
EndFunction

// Data selection through SelectRegisterRecordersToProcess().
//
// Returns:
//  String - the "RegisterRecorders" constant.
//
Function RegisterRecordersSelectionMethod() Export
	
	Return "RegistryRecorders";
	
EndFunction

// Data selection through SelectRefsToProcess().
//
// Returns:
//  String - the "Refs" constant.
//
Function RefsSelectionMethod() Export
	
	Return "References";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// Checks if the infobase update is required when the configuration version is changed.
//
// Returns:
//   Boolean - True if an update is required.
//
Function InfobaseUpdateRequired() Export
	
	Return InfobaseUpdateInternalCached.InfobaseUpdateRequired();
	
EndFunction

// Returns True if the infobase is being updated.
//
// Returns:
//   Boolean - True if an update is in progress.
//
Function InfobaseUpdateInProgress() Export
	
	If Common.DataSeparationEnabled()
		AND Not Common.SeparatedDataUsageAvailable() Then
		Return InfobaseUpdateRequired();
	EndIf;
	
	Return SessionParameters.IBUpdateInProgress;
	
EndFunction

// Returns True if the function is called from the update handler.
// For any type of an update handler - exclusive, seamless, or deferred.
//
// Parameters:
//  HandlerExecutionMode - String - Deferred, Seamless, Exclusive or a combination of these variants 
//                               separated by commas. If given, only a call from update handlers 
//                               from the stated execution mode is checked.
//
// Returns:
//  Boolean - True if the function is called from the update handler.
//
Function IsCallFromUpdateHandler(HandlerExecutionMode = "") Export
	
	ExecutionMode = SessionParameters.UpdateHandlerParameters.ExecutionMode;
	If Not ValueIsFilled(ExecutionMode) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(HandlerExecutionMode) Then
		Return True;
	EndIf;
	
	Return (StrFind(HandlerExecutionMode, ExecutionMode) > 0);
	
EndFunction

// Returns an empty table of update handlers and initial infobase filling handlers.
//
// Returns:
//   ValueTable - a table with the following columns:
//    1) For all types of update handlers:
//
//     * InitialFilling - Boolean - if True, then a handler is started on a launch with an empty base.
//     * Version - String - for example, "2.1.3.39". Configuration version number. The handler is 
//                                      executed when the configuration migrates to this version number.
//                                      If an empty string is specified, this handler is intended 
//                                      for initial filling only (when the InitialFilling parameter is specified).
//     * Procedure - String - the full name of an update handler or initial filling handler.
//                                      For example, "MEMInfobaseUpdate.FillNewAttribute"
//                                      Must be an export procedure.
//     * ExecutionMode - String - update handler run mode. The following values are available:
//                                      Exclusive, Deferred, Nonexclusive. If this value is not 
//                                      specified, the handler is considered exclusive.
//
//    2. For SaaS update handlers:
//
//     * SharedData - Boolean - if True, the handler is executed prior to other handlers that use 
//                                      shared data.
//                                      Is is allowed to specify it only for handlers with Exclusive or Seamless execution mode.
//                                      If the True value is specified for a handler with a Deferred 
//                                      execution mode, an exception will be brought out.
//     * HandlerManagement - Boolean - if True, then the handler has a parameter of a Structure type 
//                                          which has the SeparatedHandlers property that is the 
//                                          table of values characterized by the structure retuned by this function.
//                                      In this case the version column is ignored. If separated 
//                                      handler execution is required, you have to add a row with 
//                                      the description of the handler procedure.
//                                      Makes sense only for required (Version = *) update handlers 
//                                      having a SharedData flag set.
//
//    3) For deferred update handlers:
//
//     * Comment         - String - details for actions executed by an update handler.
//     * ID       - UUID - it must be filled in only for deferred update handlers and not required 
//                                                 for others. Helps to identify a handler in case 
//                                                 it was renamed.
//     
//     * LockedItems - String - it must be filled in only for deferred update handlers and not 
//                                      required for others. Full names of objects separated by 
//                                      commas. These names must be locked from changing until data processing procedure is finalized.
//                                      If it is not empty, then the CheckProcedure property must also be filled in.
//     * CheckProcedure   - String - it must be filled in only for deferred update handlers and not 
//                                      required for others. Name of a function that defines if data 
//                                      processing procedure is finalized for the passed object.
//                                      If the passed object is fully processed, it must aquire the True value.
//                                      Called from the InfobaseUpdate.CheckObjectProcessed procedure.
//                                      Parameters that are passed to the function:
//                                         Parameters - Structure - see InfobaseUpdate. MetadataAndFilterByData.
//
//    4) For update handlers in libraries (configurations) with a parallel mode of deferred handlers execution:
//
//     * UpdateDataFillingProcedure - String - the procedure for registering data to be updated by 
//                                      this handler must be specified.
//     * RunOnlyInMasterNode - Boolean - only for deferred update handlers with a Parallel execution mode.
//                                      Specify as True if an update handler must be executed only 
//                                      in the master DIB node.
//     * RunAlsoInSubordinateDIBNodeWithFilters - Boolean - only for deferred update handlers with 
//                                      the Parallel execution mode.
//                                      Specify as True if an update handler must also be executed 
//                                      in the subordinate DIB node using filters.
//     * ObjectsToRead              - String - objects to be read by the update handler while processing data.
//     * ObjectsToChange            - String - objects to be changed by the update handler while processing data.
//     * ExecutionPriorities         - ValueTable - table of execution priorities for deferred 
//                                      handlers changing or reading the same data. For more 
//                                      information, see the commentary to the InfobaseUpdate.HandlerExecutionPriorities function.
//
//    5) For inner use:
//
//     * ExecuteInMandatoryGroup - Boolean - specify this parameter if the handler must be executed 
//                                      in the group that contains handlers for the "*" version.
//                                      You can change the order of handlers in the group by 
//                                      changing their priorities.
//     * Priority           - Number - for inner use.
//
//    6) Obsolete, used for backwards compatibility (not to be specified for new handlers):
//
//     * ExclusiveMode    - Undefined, Boolean - if Undefined, the handler is executed 
//                                      unconditionally in the exclusive mode.
//                                      For handlers that execute migration to a specific version (Version <> "*"):
//                                        False   - handler execution does not require an exclusive mode.
//                                        True - handler execution requires an exclusive mode.
//                                      For required update handlers (Version = "*"):
//                                        False   - handler execution does not require an exclusive mode.
//                                        True - handler execution may require an exclusive mode.
//                                                 A parameter of structure type with ExclusiveMode 
//                                                 property (of Boolean type) is passed to such handlers.
//                                                 To execute the handler in exclusive mode, set 
//                                                 this parameter to True. In this case the handler 
//                                                 must perform the required update operations. 
//                                                 Changing the parameter in the handler body is ignored.
//                                                 To execute the handler in nonexclusive mode, set 
//                                                 this parameter to False. In this case the handler 
//                                                 must not make any changes to the infobase.
//                                                 If the analysis reveals that a handler needs to 
//                                                 change infobase data, set the parameter value to 
//                                                 the True, and stop handler execution.
//                                                 In this case nonexclusive infobase update is 
//                                                 canceled and an error message with a 
//                                                 recommendation to perform the update in exclusive mode is displayed.
//
Function NewUpdateHandlerTable() Export
	
	Handlers = New ValueTable;
	// Common properties.
	Handlers.Columns.Add("InitialFilling", New TypeDescription("Boolean"));
	Handlers.Columns.Add("Version",    New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure", New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("ExecutionMode", New TypeDescription("String"));
	// For libraries.
	Handlers.Columns.Add("ExecuteInMandatoryGroup", New TypeDescription("Boolean"));
	Handlers.Columns.Add("Priority", New TypeDescription("Number", New NumberQualifiers(2)));
	// For the service model.
	Handlers.Columns.Add("SharedData",             New TypeDescription("Boolean"));
	Handlers.Columns.Add("HandlerManagement", New TypeDescription("Boolean"));
	// For deferred update handlers.
	Handlers.Columns.Add("Comment", New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("ID", New TypeDescription("UUID"));
	Handlers.Columns.Add("CheckProcedure", New TypeDescription("String"));
	Handlers.Columns.Add("ObjectsToLock", New TypeDescription("String"));
	// For the Parallel execution mode of the deferred update.
	Handlers.Columns.Add("UpdateDataFillingProcedure", New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("DeferredProcessingQueue",  New TypeDescription("Number", New NumberQualifiers(4)));
	Handlers.Columns.Add("ExecuteInMasterNodeOnly",  New TypeDescription("Boolean"));
	Handlers.Columns.Add("RunAlsoInSubordinateDIBNodeWithFilters",  New TypeDescription("Boolean"));
	Handlers.Columns.Add("ObjectsToBeRead", New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("ObjectsToChange", New TypeDescription("String", , New StringQualifiers(0)));
	Handlers.Columns.Add("ExecutionPriorities");
	Handlers.Columns.Add("Multithreaded", New TypeDescription("Boolean"));
	
	// Obsolete. Reverse compatibility with edition 2.2.
	Handlers.Columns.Add("Optional");
	Handlers.Columns.Add("ExclusiveMode");
	
	Return Handlers;
	
EndFunction

// Returns the empty table of execution priorities for deferred handlers changing or reading the 
// same data. For using update handlers in descriptions.
//
// Returns:
//  ValueTable - a table with the following columns:
//    * Order       - String - execution order for a current handler in relation to other handlers.
//                               Possible variants: "Before", "After", and "Any".
//    * ID - UUID - an ID of a procedure to establish relation with.
//    * Procedure     - String - full name of a procedure to establish relation with.
//
// Example:
//  Priority = HandlerExecutionPriorities().Add();
//  Priority.Order = "Before";
//  Priority.Procedure = "Document.CustomerOrder.UpdateDataForMigrationToNewVersion";
//
Function HandlerExecutionPriorities() Export
	
	Priorities = New ValueTable;
	Priorities.Columns.Add("Order", New TypeDescription("String", , New StringQualifiers(0)));
	Priorities.Columns.Add("ID");
	Priorities.Columns.Add("Procedure", New TypeDescription("String", , New StringQualifiers(0)));
	
	Return Priorities;
	
EndFunction

// Executes handlers from the UpdateHandlers list for LibraryID library update to IBMetadataVersion 
// version.
//
// Parameters:
//   LibraryID   - String       - configuration name or library ID.
//   InfobaseMetadataVersion        - String       - metadata version to be updated to.
//   UpdateHandlers     - Map - list of update handlers.
//   SeamlessUpdate     - Boolean       - True if an update is seamless.
//   HandlerExecutionProgress - Structure    - has the following properties:
//       * TotalHandlers     - String - a total number of handlers being executed.
//       * HandlersCompleted - Boolean - a number of completed handlers.
//
// Returns:
//   ValueTree   - executed update handlers.
//
Function ExecuteUpdateIteration(Val LibraryID, Val IBMetadataVersion, 
	Val UpdateHandlers, Val HandlerExecutionProgress, Val SeamlessUpdate = False) Export
	
	UpdateIteration = InfobaseUpdateInternal.UpdateIteration(LibraryID, 
		IBMetadataVersion, UpdateHandlers);
		
	Parameters = New Structure;
	Parameters.Insert("HandlerExecutionProgress", HandlerExecutionProgress);
	Parameters.Insert("NonexclusiveUpdate", SeamlessUpdate);
	Parameters.Insert("InBackground", False);
	
	Return InfobaseUpdateInternal.ExecuteUpdateIteration(UpdateIteration, Parameters);
	
EndFunction

// Runs noninteractive infobase update.
// This function is intended for calling through an external connection.
// When calling the method containing extensions which modify the configuration role, the exception will follow.
// 
// To be used in other libraries and configurations.
//
// Parameters:
//  ExecuteDeferredHandlers - Boolean - if True, then a deferred update will be executed in the 
//    default update mode. Only for a client-server mode.
//
// Returns:
//  String -  update hadlers execution flag:
//           "Done", "NotRequired", "ExclusiveModeSettingError".
//
Function UpdateInfobase(ExecuteDeferredHandlers = False) Export
	
	StartDate = CurrentSessionDate();
	Result = InfobaseUpdateInternalServerCall.UpdateInfobase(,,
		ExecuteDeferredHandlers);
	EndDate = CurrentSessionDate();
	InfobaseUpdateInternal.WriteUpdateExecutionTime(StartDate, EndDate);
	
	Return Result;
	
EndFunction

// Returns a table of subsystem versions used in the configuration.
// The procedure is used for batch import and export of information about subsystem versions.
//
// Returns:
//   ValueTable - a table with columns:
//     * SubsystemName - String - name of a subsystem.
//     * Version        - String - version of a subsystem.
//
Function SubsystemsVersions() Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	SubsystemsVersions.SubsystemName AS SubsystemName,
	|	SubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.SubsystemsVersions AS SubsystemsVersions";
	
	Return Query.Execute().Unload();

EndFunction 

// Sets all subsystem versions.
// The procedure is used for batch import and export of information about subsystem versions.
//
// Parameters:
//   SubsystemVersions - ValueTable - a table containing the following columns:
//     * SubsystemName - String - name of a subsystem.
//     * Version        - String - version of a subsystem.
//
Procedure SetSubsystemVersions(SubsystemsVersions) Export

	RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
	
	For each Version In SubsystemsVersions Do
		NewRecord = RecordSet.Add();
		NewRecord.SubsystemName = Version.SubsystemName;
		NewRecord.Version = Version.Version;
		NewRecord.IsMainConfiguration = (Version.SubsystemName = Metadata.Name);
	EndDo;
	
	RecordSet.Write();

EndProcedure

// Get configuration or parent configuration (library) version that is stored in the infobase.
// 
//
// Parameters:
//  LibraryID - String - a configuration name or a library ID.
//
// Returns:
//   String   - version.
//
// Example:
//   IBСonfigurationVersion = IBVersion(Metadata.Name);
//
Function IBVersion(Val LibraryID) Export
	
	Return InfobaseUpdateInternal.IBVersion(LibraryID);
	
EndFunction

// Writes a configuration or parent configuration (library) version to the infobase.
//
// Parameters:
//  LibraryID - String - configuration name or parent configuration (library) name.
//  VersionNumber             - String - version number.
//  IsMainConfiguration - Boolean - a flag indicating that the LibraryID corresponds to the configuration name.
//
Procedure SetIBVersion(Val LibraryID, Val VersionNumber, Val IsMainConfiguration) Export
	
	InfobaseUpdateInternal.SetIBVersion(LibraryID, VersionNumber, IsMainConfiguration);
	
EndProcedure

// Registers a new subsystem in the SubsystemVersions information register.
// For instance, it can be used to create a subsystem on the basis of already existing metadata 
// without using initial filling handlers.
// If the subsystem is registered, succeeding registration will not be performed.
// This method can be called from the BeforeInfobaseUpdate procedure of the common module 
// InfobaseUpdateOverridable.
//
// Parameters:
//  SubsystemName - String - name of a subsystem in the form set in the common module.
//                           InfobaseUpdateXXX.
//                           For example - "StandardSubsystems".
//  VersionNumber   - String - full number of a version the subsystem must be registered for.
//                           If the number is not stated, it will be registered for a version "0.0.0.1". 
//                           It is necessary to indicate if only last handlers should be executed or all of them.
//
Procedure RegisterNewSubsystem(SubsystemName, VersionNumber = "") Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	| SubsystemsVersions.SubsystemName AS SubsystemName
	|FROM
	| InformationRegister.SubsystemsVersions AS SubsystemsVersions";
	
	ConfigurationSubsystems = Query.Execute().Unload().UnloadColumn("SubsystemName");
	
	If ConfigurationSubsystems.Count() > 0 Then
		// This is not the first launch of a program
		If ConfigurationSubsystems.Find(SubsystemName) = Undefined Then
			Record = InformationRegisters.SubsystemsVersions.CreateRecordManager();
			Record.SubsystemName = SubsystemName;
			Record.Version = ?(VersionNumber = "", "0.0.0.1", VersionNumber);
			Record.Write();
		EndIf;
	EndIf;
	
	Info = InfobaseUpdateInternal.InfobaseUpdateInfo();
	ItemIndex = Info.NewSubsystems.Find(SubsystemName);
	If ItemIndex <> Undefined Then
		Info.NewSubsystems.Delete(ItemIndex);
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(Info);
	EndIf;
	
EndProcedure

// Returns a queue number of a deferred update handler by its full name or a UUID.
// 
//
// Parameters:
//  NameOrID - String, UUID - full name of deferred handler or its ID.
//                         For more information, see NewUpdateHandlerTable, description of  
//                        properties for Procedure and ID.
//
// Returns:
//  Number, Undefined - queue number of a passed handler. If a handler is not found, the Undefined 
//                        value will be returned.
//
Function DeferredUpdateHandlerQueue(NameOrID) Export
	
	Result = InfobaseUpdateInternalCached.DeferredUpdateHandlerQueue();
	
	If TypeOf(NameOrID) = Type("UUID") Then
		QueueByID = Result["ByID"];
		Return QueueByID[NameOrID];
	Else
		QueueByName = Result["ByName"];
		Return QueueByName[NameOrID];
	EndIf;
	
EndFunction

// Max records quantity in data selection for update.
//
// Returns:
//  Number - constant 10000.
//
Function MaxRecordsCountInSelection() Export
	
	Return 10000;
	
EndFunction

// Returns table with data to update.
// Used in multithread update handlers.
//
// Parameters:
//  Parameters - Structure - the parameter that is passed in update handler.
//
// Returns:
//  ValueTable - a table with data being updated, whose column content depends on the selection 
//                    method that is specified in the data register procedure for updating.
//                    If there is no data to update, the blank table returns without columns.
//
Function DataToUpdateInMultithreadHandler(Parameters) Export
	
	DataSet = Parameters.DataToUpdate.DataSet;
	
	If DataSet.Count() > 0 Then
		Return DataSet[0].Data;
	Else
		Return New ValueTable;
	EndIf;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete: no longer required as the actions are executed automatically by an update feature.
// 
// Removes a deferred handler from the handler execution queue for the new version.
// It is recommended for use in cases, such as switching from a deferred handler execution mode to 
// an exclusive (seamless) one.
// To perform this action, add a new separate update handler of a
// "Seamless" execution mode and a "SharedData = False" flag, and place a call for this method in it.
//
// Parameters:
//  HandlerName - String - full procedure name of a deferred handler.
//
Procedure DeleteDeferredHandlerFromQueue(HandlerName) Export
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
	SelectedHandler = UpdateInfo.HandlersTree.Rows.FindRows(New Structure("HandlerName", HandlerName), True);
	If SelectedHandler <> Undefined AND SelectedHandler.Count() > 0 Then
		
		For Each RowHandler In SelectedHandler Do
			RowHandler.Parent.Rows.Delete(RowHandler);
		EndDo;
		
	EndIf;
	
	For Each UpdateStep In UpdateInfo.DeferredUpdatePlan Do
		StepHandlers = UpdateStep.Handlers;
		Index = 0;
		HandlerFound = False;
		For Each HandlerDetails In StepHandlers Do
			If HandlerDetails.HandlerName = HandlerName Then
				HandlerFound = True;
				Break;
			EndIf;
			Index = Index + 1;
		EndDo;
		
		If HandlerFound Then
			StepHandlers.Delete(Index);
			Break;
		EndIf;
	EndDo;
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure AddAdditionalSourceLockCheck(PositionInQueue, QueryText, FullObjectName, FullRegisterName, TempTablesManager, IsTemporaryTableCreation, AdditionalParameters)
	
	If AdditionalParameters.AdditionalDataSources.Count() = 0 Then
				
		QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByHeaderQueryText", "");
		QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByTabularSectionQueryText", "");
		QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesReferences", "TRUE");
		QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesRegisters", "TRUE");
		QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesRegistersQueryText", "");
	
	Else	
		
		AdditionalSourcesRefs = New Array;
		AdditionalSourcesRegisters = New Array;
		
		For Each KeyValue In AdditionalParameters.AdditionalDataSources Do
			
			DataSource = KeyValue.Key;
			
			If StandardSubsystemsServer.IsRegisterTable(DataSource)
				AND StrFind(DataSource,".") <> 0 Then
				AdditionalSourcesRegisters.Add(DataSource);
			Else
				AdditionalSourcesRefs.Add(DataSource);
			EndIf;
			
		EndDo;
		
		#Region AdditionalSourcesRefs
		
		If AdditionalSourcesRefs.Count() > 0 Then
			
			If FullObjectName = Undefined Then
				ExceptionText = NStr("ru = 'Ошибка вызова функции %FunctionName%: не передано имя документа, но переданы дополнительные источники данных.'; en = '%FunctionName% function call error: additional data sources were passed without a document name.'; pl = 'Błąd wezwania funkcji %FunctionName%: nie przekazano nazwa dokumentu, ale są przekazane dodatkowe źródła danych.';de = 'Fehler beim Aufruf der Funktion %FunctionName%: Der Dokumentname wurde nicht übertragen, es wurden jedoch zusätzliche Datenquellen übertragen.';ro = 'Eroare de apelare a funcției %FunctionName%: nu este transmis numele documentului, dar sunt transmise sursele suplimentare a datelor.';tr = '%FunctionName% işlevin çağrı hatası: belge adı aktarılamadı, ancak ek veri kaynakları aktarıldı.'; es_ES = 'Error al llamar la función %FunctionName%: no se ha transmitido el nombre de documento, no han sido transmitidos las fuentes adicionales de datos.'");
				ExceptionText = StrReplace(ExceptionText, "%FunctionName%", "InfobaseUpdate.AddAdditionalSourceLockCheck");
				Raise ExceptionText;
			EndIf;
			
			DocumentMetadata = Metadata.FindByFullName(FullObjectName);
			ConnectionToAdditionalSourcesByHeaderQueryText = "";
			ConnectionToAdditionalSourcesByTabularSectionQueryText = "";
			ConnectionToAdditionalSourcesByTabularSectionQueryTexts = New Map;
			ConditionByAdditionalSourcesRefs = "TRUE";
			
			ConditionByAdditionalSourcesRefsTabularSection = "FALSE";
			
			TemporaryTablesOfLockedAdditionalSources = New Map;
			
			For Each DataSource In AdditionalSourcesRefs Do
				
				If StrFind(DataSource, ".") > 0 Then
					NameParts = StrSplit(DataSource, ".");
					TSName = NameParts[0];
					AttributeName = NameParts[1];
				Else
					TSName = "";
					AttributeName = DataSource;
				EndIf;
				
				If ValueIsFilled(TSName) Then
					SourceTypes = DocumentMetadata.TabularSections[TSName].Attributes[AttributeName].Type.Types();
				Else
					SourceTypes = DocumentMetadata.Attributes[AttributeName].Type.Types();
				EndIf;	
				
				For Each SourceType In SourceTypes Do
					
					If IsPrimitiveType(SourceType) Then
						Continue;
					EndIf;
					
					If ValueIsFilled(TSName)
						AND StrFind(ConnectionToAdditionalSourcesByTabularSectionQueryText, "AS DocumentTabularSection" + TSName) = 0 Then
						
						If FullRegisterName <> Undefined Then
							
							ConnectionToAdditionalSourcesByTabularSectionQueryText = ConnectionToAdditionalSourcesByTabularSectionQueryText + "
							|		INNER JOIN #FullDocumentName." + TSName + " AS DocumentTabularSection" + TSName + "
							|#ConnectionToAdditionalSourcesByTabularSectionQueryText" + TSName + "
							|		ON RegisterTableChanges.Recorder = DocumentTabularSection" + TSName + ".Ref
							|";
							
						Else
							
							ConnectionToAdditionalSourcesByTabularSectionQueryText = ConnectionToAdditionalSourcesByTabularSectionQueryText + "
							|		INNER JOIN #FullDocumentName." + TSName + " AS DocumentTabularSection" + TSName + "
							|#ConnectionToAdditionalSourcesByTabularSectionQueryText" + TSName + "
							|		ON ChangesTable.Ref = DocumentTabularSection" + TSName + ".Ref
							|";
							
						EndIf;
					EndIf;
					
					SourceMetadata = Metadata.FindByType(SourceType);
					
					LockedAdditionalSourceTTName = TemporaryTablesOfLockedAdditionalSources.Get(SourceMetadata);
					
					If LockedAdditionalSourceTTName = Undefined Then
						FullSourceName = SourceMetadata.FullName();
						LockedAdditionalSourceTTName = "TTLocked" + StrReplace(FullSourceName,".","_");
						
						AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
						AdditionalParametersForTTCreation.TempTableName = LockedAdditionalSourceTTName;
						CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, FullSourceName, TempTablesManager, AdditionalParametersForTTCreation);
						
						TemporaryTablesOfLockedAdditionalSources.Insert(SourceMetadata, LockedAdditionalSourceTTName);
						
					EndIf;
					
					If ValueIsFilled(TSName) Then
						
						ConnectionToAdditionalSourcesByTSTSNameQueryText = ConnectionToAdditionalSourcesByTabularSectionQueryTexts.Get(TSName);
						
						If ConnectionToAdditionalSourcesByTSTSNameQueryText = Undefined Then
							ConnectionToAdditionalSourcesByTSTSNameQueryText = "";
						EndIf;
						
						ConnectionToAdditionalSourcesByTSTSNameQueryText = ConnectionToAdditionalSourcesByTSTSNameQueryText + "
						|			LEFT JOIN #TTName AS #TempTableSynonym
						|			ON DocumentTabularSection" + TSName + "." + AttributeName + " = #TempTableSynonym.Ref";
						
						ConnectionToAdditionalSourcesByTSTSNameQueryText = StrReplace(ConnectionToAdditionalSourcesByTSTSNameQueryText,
																					"#TTName",
																					LockedAdditionalSourceTTName);
						LockedAdditionalSourceTTSynonym = LockedAdditionalSourceTTName + TSName + AttributeName;															 
						ConnectionToAdditionalSourcesByTSTSNameQueryText = StrReplace(ConnectionToAdditionalSourcesByTSTSNameQueryText,
																					"#TempTableSynonym",
																					LockedAdditionalSourceTTSynonym);
						ConnectionToAdditionalSourcesByTabularSectionQueryTexts.Insert(TSName, ConnectionToAdditionalSourcesByTSTSNameQueryText);
						
						ConditionByAdditionalSourcesRefsTabularSection = ConditionByAdditionalSourcesRefsTabularSection + "
						|	OR NOT " + LockedAdditionalSourceTTSynonym + ".Ref IS NULL ";
					Else
						If FullRegisterName <> Undefined Then
							ConnectionToAdditionalSourcesByHeaderQueryText = ConnectionToAdditionalSourcesByHeaderQueryText + "
							|			LEFT JOIN #TTName AS #TempTableSynonym
							|			ON DocumentTable." + AttributeName + " = #TempTableSynonym.Ref";
						Else
							ConnectionToAdditionalSourcesByHeaderQueryText = ConnectionToAdditionalSourcesByHeaderQueryText + "
							|			LEFT JOIN #TTName AS #TempTableSynonym
							|			ON ObjectTable." + AttributeName + " = #TempTableSynonym.Ref";
						EndIf;
						ConnectionToAdditionalSourcesByHeaderQueryText = StrReplace(ConnectionToAdditionalSourcesByHeaderQueryText,
																					"#TTName",
																					LockedAdditionalSourceTTName);
						LockedAdditionalSourceTTSynonym = LockedAdditionalSourceTTName + "Header";															 
						ConnectionToAdditionalSourcesByHeaderQueryText = StrReplace(ConnectionToAdditionalSourcesByHeaderQueryText,
																					"#TempTableSynonym",
																					LockedAdditionalSourceTTSynonym);
					
						ConditionByAdditionalSourcesRefs = ConditionByAdditionalSourcesRefs + "
						|	AND " + LockedAdditionalSourceTTSynonym + ".Ref IS NULL ";
					EndIf;
				EndDo;
				
			EndDo;
			
			If Not IsBlankString(ConnectionToAdditionalSourcesByTabularSectionQueryText) Then
				For Each JoinText In ConnectionToAdditionalSourcesByTabularSectionQueryTexts Do
					
					ConnectionToAdditionalSourcesByTabularSectionQueryText = StrReplace(ConnectionToAdditionalSourcesByTabularSectionQueryText,
					"#ConnectionToAdditionalSourcesByTabularSectionQueryText" + JoinText.Key,
					JoinText.Value);
					
				EndDo;
				
				If FullRegisterName <> Undefined Then
					LockedSourcesTemporaryTableByTabularSectionQueryText =
					"SELECT DISTINCT
					|	RegisterTableChanges.Recorder AS Ref
					|INTO LockedByTabularSection
					|FROM
					|	#ChangesTable AS RegisterTableChanges
					|       #ConnectionToAdditionalSourcesByTabularSectionQueryText
					|WHERE
					|	&ConditionByAdditionalSourcesReferencesTabularSection";
				Else
					LockedSourcesTemporaryTableByTabularSectionQueryText =
					"SELECT DISTINCT
					|	ChangesTable.Ref AS Ref
					|INTO LockedByTabularSection
					|FROM
					|	#ChangesTable AS ChangesTable
					|       #ConnectionToAdditionalSourcesByTabularSectionQueryText
					|WHERE
					|	&ConditionByAdditionalSourcesReferencesTabularSection";
				EndIf;
				
				LockedSourcesTemporaryTableByTabularSectionQueryText = StrReplace(LockedSourcesTemporaryTableByTabularSectionQueryText,
																				"#ConnectionToAdditionalSourcesByTabularSectionQueryText",
																				ConnectionToAdditionalSourcesByTabularSectionQueryText);
				
				LockedSourcesTemporaryTableByTabularSectionQueryText = StrReplace(LockedSourcesTemporaryTableByTabularSectionQueryText,
																				"&ConditionByAdditionalSourcesReferencesTabularSection",
																				ConditionByAdditionalSourcesRefsTabularSection);
				If FullRegisterName <> Undefined Then
					LockedSourcesTemporaryTableByTabularSectionQueryText = StrReplace(LockedSourcesTemporaryTableByTabularSectionQueryText,
																					"#ChangesTable",
																					FullRegisterName + ".Changes");	
				Else
					LockedSourcesTemporaryTableByTabularSectionQueryText = StrReplace(LockedSourcesTemporaryTableByTabularSectionQueryText,
																					"#ChangesTable",
																					FullObjectName + ".Changes");	
				EndIf;																
				
				LockedSourcesTemporaryTableByTabularSectionQueryText = StrReplace(LockedSourcesTemporaryTableByTabularSectionQueryText,
																				"#FullDocumentName",
																				FullObjectName);
				Query = New Query;
				Query.Text = LockedSourcesTemporaryTableByTabularSectionQueryText;
				Query.TempTablesManager = TempTablesManager;
				Query.Execute();
				
				If FullRegisterName <> Undefined Then
					ConnectionToAdditionalSourcesByTabularSectionQueryText = "
					|		LEFT JOIN LockedByTabularSection AS LockedByTabularSection 
					|		ON RegisterTableChanges.Recorder = LockedByTabularSection.Ref
					|";
				Else
					ConnectionToAdditionalSourcesByTabularSectionQueryText = "
					|		LEFT JOIN LockedByTabularSection AS LockedByTabularSection 
					|		ON ChangesTable.Ref = LockedByTabularSection.Ref
					|";
				EndIf;																
				
				ConditionByAdditionalSourcesRefs = ConditionByAdditionalSourcesRefs + "
				|	AND LockedByTabularSection.Ref IS NULL ";
				
				TemporaryTablesOfLockedAdditionalSources.Insert("LockedByTabularSection", "LockedByTabularSection");
			EndIf;
			
			If ValueIsFilled(ConnectionToAdditionalSourcesByHeaderQueryText) Then 
				If IsTemporaryTableCreation
					AND FullRegisterName <> Undefined Then
					ConnectionToAdditionalSourcesByHeaderQueryText = StrReplace("
					|		INNER JOIN #FullDocumentName AS DocumentTable
					|       	#ConnectionToAdditionalSourcesByHeaderQueryText
					|		ON RegisterTableChanges.Recorder = DocumentTable.Ref",
					"#ConnectionToAdditionalSourcesByHeaderQueryText",
					ConnectionToAdditionalSourcesByHeaderQueryText);
				EndIf;
			EndIf;	
				
			DropTemporaryTableQueryTextTemplate = "
			|DROP
			|	#TTName
			|";
			
			QueryTexts = New Array;
			QueryTexts.Add(QueryText);
			
			For Each KeyValue In TemporaryTablesOfLockedAdditionalSources Do
				
				DropTemporaryTableQueryText = StrReplace(DropTemporaryTableQueryTextTemplate, "#TTName", KeyValue.Value);
				
				QueryTexts.Add(DropTemporaryTableQueryText);
				
			EndDo;
			
			QueryText = StrConcat(QueryTexts, ";");
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByHeaderQueryText", ConnectionToAdditionalSourcesByHeaderQueryText);
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByTabularSectionQueryText", ConnectionToAdditionalSourcesByTabularSectionQueryText);
			QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesReferences", ConditionByAdditionalSourcesRefs);
			QueryText = StrReplace(QueryText, "#FullDocumentName", FullObjectName);
		Else
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByHeaderQueryText", "");
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesByTabularSectionQueryText", "");
			QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesReferences", "TRUE");
		EndIf;
		#EndRegion
		
		#Region AdditionalSourcesRegisters

		If AdditionalSourcesRegisters.Count() > 0 Then
			
			ConnectionToAdditionalSourcesRegistersQueryText = "";
			ConditionByAdditionalSourcesRegisters = "TRUE";
			
			TemporaryTablesOfLockedAdditionalSources = New Map;
			
			For Each DataSource In AdditionalSourcesRegisters Do
				
				SourceMetadata = Metadata.FindByFullName(DataSource);
				
				If Common.IsInformationRegister(SourceMetadata)
					AND SourceMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					
					ExceptionText = NStr("ru = 'Регистр %DataSource% независимый. Поддерживается проверка только по регистрам, подчиненным регистраторам.'; en = 'The %DataSource% register is independent. The check supports only registers that subordinate to recorders.'; pl = 'Rejestr %DataSource% niezależny. Jest obsługiwana weryfikacja tylko wg rejestrów, podporządkowanych do rejestratorów.';de = 'Registrieren Sie %DataSource% unabhängig. Es wird nur für Register unterstützt, die Registrierstellen untergeordnet sind.';ro = 'Registrul %DataSource% este independent. Este susținută verificarea numai pe registrele subordonate registratorilor.';tr = '%DataSource% kaydedicisi bağımsız. Sadece kaydedicilere bağlı kayıtlara göre doğrulama destekleniyor.'; es_ES = 'El registro %DataSource% es independiente. Se admite la prueba solo por registros subordinados a los registradores.'");
					ExceptionText = StrReplace(ExceptionText, "%DataSource%",DataSource);
					Raise ExceptionText;
				EndIf;
				
				LockedAdditionalSourceTTName = TemporaryTablesOfLockedAdditionalSources.Get(SourceMetadata);
				
				If LockedAdditionalSourceTTName = Undefined Then
					LockedAdditionalSourceTTName = "TTLocked" + StrReplace(DataSource,".","_");
					
					AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
					AdditionalParametersForTTCreation.TempTableName = LockedAdditionalSourceTTName;
					CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(PositionInQueue, DataSource, TempTablesManager, AdditionalParametersForTTCreation);
					
					TemporaryTablesOfLockedAdditionalSources.Insert(SourceMetadata, LockedAdditionalSourceTTName);
					
				EndIf;
				
				If FullRegisterName <> Undefined Then
					ConnectionToAdditionalSourcesRegistersQueryText = ConnectionToAdditionalSourcesRegistersQueryText + "
					|			LEFT JOIN #TTName AS #TTName
					|			ON RegisterTableChanges.Recorder = #TTName.Recorder";
				Else
					ConnectionToAdditionalSourcesRegistersQueryText = ConnectionToAdditionalSourcesRegistersQueryText + "
					|			LEFT JOIN #TTName AS #TTName
					|			ON ObjectTable.Ref = #TTName.Recorder";
				EndIf;
				ConnectionToAdditionalSourcesRegistersQueryText = StrReplace(ConnectionToAdditionalSourcesRegistersQueryText,
					"#TTName", LockedAdditionalSourceTTName);
					
				ConditionByAdditionalSourcesRegisters = ConditionByAdditionalSourcesRegisters + "
				|	AND " + LockedAdditionalSourceTTName + ".Recorder IS NULL ";
				
			EndDo;	
			
			DropTemporaryTableQueryTextTemplate = "
			|DROP
			|	#TTName
			|";
			
			QueryTexts = New Array;
			QueryTexts.Add(QueryText);
			
			For Each KeyValue In TemporaryTablesOfLockedAdditionalSources Do
				
				DropTemporaryTableQueryText = StrReplace(DropTemporaryTableQueryTextTemplate, "#TTName", KeyValue.Value);
				
				QueryTexts.Add(DropTemporaryTableQueryText);
				
			EndDo;
			
			QueryText = StrConcat(QueryTexts, ";");
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesRegistersQueryText", ConnectionToAdditionalSourcesRegistersQueryText);
			QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesRegisters", ConditionByAdditionalSourcesRegisters);
		Else
			QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesRegisters", "TRUE");
			QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesRegistersQueryText", "");
		EndIf;
		#EndRegion
	EndIf;	
EndProcedure

Function IsPrimitiveType(TypeToCheck)
	
	If TypeToCheck = Type("Undefined")
		Or TypeToCheck = Type("Boolean")
		Or TypeToCheck = Type("String")
		Or TypeToCheck = Type("Number")
		Or TypeToCheck = Type("Date")
		Or TypeToCheck = Type("UUID") Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Procedure AddAdditionalSourceLockCheckForStandaloneRegister(PositionInQueue, QueryText, FullRegisterName, TempTablesManager, AdditionalParameters)
	
	If AdditionalParameters.AdditionalDataSources.Count() = 0 Then
		
		QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesQueryText", "");
		QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesReferences", "TRUE");
	
	Else
		
		RegisterMetadata = Metadata.FindByFullName(FullRegisterName);
		ConnectionToAdditionalSourcesQueryText = "";
		ConditionByAdditionalSourcesRefs = "TRUE";
		
		For Each KeyValue In AdditionalParameters.AdditionalDataSources Do
			
			DataSource = KeyValue.Key;
			
			SourceTypes = RegisterMetadata.Dimensions[DataSource].Type.Types();
			MetadataObjectArray = New Array;
			
			For Each SourceType In SourceTypes Do
				
				If IsPrimitiveType(SourceType) Then
					Continue;
				EndIf;
				
				MetadataObjectArray.Add(Metadata.FindByType(SourceType));
				
			EndDo;
			
			AdditionalParametersForTTCreation = AdditionalProcessingDataSelectionParameters();
			TempTableName = "TTLocked" + DataSource;
			AdditionalParametersForTTCreation.TempTableName = TempTableName;
			
			CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing(PositionInQueue, MetadataObjectArray, TempTablesManager, AdditionalParametersForTTCreation);
			
			ConnectionToAdditionalSourcesQueryText = ConnectionToAdditionalSourcesQueryText + "
			|		LEFT JOIN " + TempTableName + " AS " + TempTableName + "
			|		ON ChangesTable." + DataSource + " = " + TempTableName + ".Ref";
			
			ConditionByAdditionalSourcesRefs = ConditionByAdditionalSourcesRefs + "
			|		AND "  + TempTableName + ".Ref IS NULL ";
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "#ConnectionToAdditionalSourcesQueryText", ConnectionToAdditionalSourcesQueryText);
		QueryText = StrReplace(QueryText, "&ConditionByAdditionalSourcesReferences", ConditionByAdditionalSourcesRefs);

	EndIf;
EndProcedure

Procedure SetMissingFiltersInSet(Set, SetMetadata, FiltersToSet)
	For Each Dimension In SetMetadata.Dimensions Do
		
		HasFilterByDimension = False;
		
		If TypeOf(FiltersToSet) = Type("ValueTable") Then
			HasFilterByDimension = FiltersToSet.Columns.Find(Dimension.Name) <> Undefined;
		Else //Filter
			HasFilterByDimension = FiltersToSet[Dimension.Name].Use;	
		EndIf;
		
		If Not HasFilterByDimension Then
			EmptyValue = Dimension.Type.AdjustValue();
			Set.Filter[Dimension.Name].Set(EmptyValue);
		EndIf;
	EndDo;
	
	If SetMetadata.MainFilterOnPeriod Then
		
		If TypeOf(FiltersToSet) = Type("ValueTable") Then
			HasFilterByDimension = FiltersToSet.Columns.Find("Period") <> Undefined;
		Else //Filter
			HasFilterByDimension = FiltersToSet.Period.Use;
		EndIf;
		
		If Not HasFilterByDimension Then
			EmptyValue = '00010101';
			Set.Filter.Period.Set(EmptyValue);
		EndIf;
		
	EndIf;
EndProcedure

Procedure RecordChanges(Parameters, Node, Data, DataKind, FullObjectName = "")
	
	ExchangePlans.RecordChanges(Node, Data);
	
	If Parameters.Property("HandlerData") Then
		If Not ValueIsFilled(FullObjectName) Then
			FullName = Data.Metadata().FullName();
		Else
			FullName = FullObjectName;
		EndIf;
		
		ObjectData = Parameters.HandlerData[FullName];
		If ObjectData = Undefined Then
			ObjectData = New Structure;
			ObjectData.Insert("Count", 1);
			ObjectData.Insert("Queue", Parameters.Queue);
			Parameters.HandlerData.Insert(FullName, ObjectData);
		Else
			Parameters.HandlerData[FullName].Count = ObjectData.Count + 1;
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange")
		AND StandardSubsystemsCached.DIBUsed("WithFilter")
		AND Not Parameters.ReRegistration
		AND Not Common.IsSubordinateDIBNode() Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.WriteUpdateDataToFile(Parameters, Data, DataKind, FullObjectName);
	EndIf;
	
EndProcedure

Function EarlierQueueNodes(PositionInQueue)
	Return ExchangePlans.InfobaseUpdate.EarlierQueueNodes(PositionInQueue);
EndFunction

Function QueueRef(PositionInQueue)
	Return ExchangePlans.InfobaseUpdate.NodeInQueue(PositionInQueue);
EndFunction

// Selection creation context using the following functions:
// - SelectRegisterRecordersToProcess();
// - SelectRefsToProcess();
// - SelectStandaloneInformationRegisterDimensionsToProcess();
//
// Parameters:
//  AdditionalParameters - Structure - see
//                            InfobaseUpdate.AdditionalProcessingDataSelectionParameters().
//  TableName - String - the name of the table from which the data is selected.
//
// Returns:
//  Structure - with the following fields:
//   * AdditionalParameters - Structure - the input parameter reference copy for mechanism procedures.
//   * SelectionByPage - Boolean - True if the selection is executed by page.
//   * TableName - String - the name of the table from which the data is selected.
//   * SelectionFields - Array - fields that are placed in the request selection list.
//   * OrderingFields - Array - fields that are placed in request of ordering section.
//   * UsedOrderingFields - Map - cache of the fields that were used for ordering.
//   * Aliases - Array - name aliases of fields being selected that are inserted in selection request.
//   * Directions - Array - ordering directions (ASC, and DESC).
//
Function SelectionBuildParameters(AdditionalParameters, TableName = Undefined)
	
	CheckSelectionParameters(AdditionalParameters);
	
	BuildParameters = New Structure;
	BuildParameters.Insert("AdditionalParameters", AdditionalParameters);
	BuildParameters.Insert("SelectionByPage", IsSelectionByPages(AdditionalParameters));
	BuildParameters.Insert("TableName", TableName);
	BuildParameters.Insert("SelectionFields", New Array);
	BuildParameters.Insert("OrderFields", New Array);
	BuildParameters.Insert("UsedOrderingFields", New Map);
	BuildParameters.Insert("Aliases", New Array);
	BuildParameters.Insert("Directions", New Array);
	
	Return BuildParameters;
	
EndFunction

// Set ordering fields in SelectRefsToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//  IsDocument - Boolean - True if document referencies are processed.
//
Procedure SetRefsOrderingFields(BuildParameters, IsDocument)
	
	SelectionFields = BuildParameters.SelectionFields;
	OrderFields = BuildParameters.OrderFields;
	SelectionByPage = BuildParameters.SelectionByPage;
	
	If IsDocument Then
		If SelectionByPage Then
			SelectionFields.Add("ObjectTable.Date");
		EndIf;
		
		OrderFields.Add("ObjectTable.Date");
	EndIf;
	
	SelectionFields.Add("ChangesTable.Ref");
	
	If SelectionByPage Then
		OrderFields.Add("ChangesTable.Ref");
	EndIf;
	
EndProcedure

// Set ordering fields for register in SelectRegisterRecordersToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetRegisterOrderingFields(BuildParameters)
	
	SelectionFields = BuildParameters.SelectionFields;
	Aliases = BuildParameters.Aliases;
	OrderFields = BuildParameters.OrderFields;
	
	SelectionFields.Add("RegisterTableChanges.Recorder");
	Aliases.Add("Recorder");
	
	If BuildParameters.SelectionByPage Then
		OrderFields.Add("RegisterTableChanges.Recorder");
	Else
		SelectionFields.Add("MAX(ISNULL(RegisterTable.Period, DATETIME(3000, 1, 1)))");
		Aliases.Add("Period");
		OrderFields.Add("MAX(ISNULL(RegisterTable.Period, DATETIME(3000, 1, 1)))");
	EndIf;
	
EndProcedure

// Set ordering fields for document in SelectRegisterRecordersToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetRegisterOrderingFieldsByDocument(BuildParameters)
	
	SelectionFields = BuildParameters.SelectionFields;
	Aliases = BuildParameters.Aliases;
	OrderFields = BuildParameters.OrderFields;
	OrderFields.Add("DocumentTable.Date");
	
	If BuildParameters.SelectionByPage Then
		SelectionFields.Add("DocumentTable.Date");
		Aliases.Add("Date");
		OrderFields.Add("RegisterTableChanges.Recorder");
	EndIf;
	
	SelectionFields.Add("RegisterTableChanges.Recorder");
	Aliases.Add("Recorder");
	
EndProcedure

// Set ordering fields for document in SelectStandaloneInformationRegisterDimensionsToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetStandaloneInformationRegisterOrderingFields(BuildParameters)
	
	Separators = " " + Chars.Tab + Chars.LF;
	OrderFields = BuildParameters.AdditionalParameters.OrderFields;
	
	For FieldIndex = 0 To OrderFields.UBound() Do
		Field = OrderFields[FieldIndex];
		Content = StrSplit(Field, Separators, False);
		FieldName = Content[0];
		BuildParameters.SelectionFields.Add(FieldName);
		BuildParameters.UsedOrderingFields[FieldName] = True;
		
		If Content.Count() > 1 Then
			BuildParameters.Directions.Add(Content[1]);
		Else
			BuildParameters.Directions.Add(?(FieldIndex = 0, "DESC", ""));
		EndIf;
	EndDo;
	
EndProcedure

// Consider the dimension in generating request parameters in SelectStandaloneInformationRegisterDimensionsToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//  DimensionName - String - the name of the dimension being processed.
//
Procedure SetDimension(BuildParameters, DimensionName)
	
	If BuildParameters.UsedOrderingFields[DimensionName] = Undefined Then
		BuildParameters.SelectionFields.Add(DimensionName);
		OrderingFieldsAreSet = OrderingFieldsAreSet(BuildParameters.AdditionalParameters);
		
		If OrderingFieldsAreSet Or BuildParameters.SelectionByPage Then
			BuildParameters.Directions.Add("");
		EndIf;
	EndIf;
	
EndProcedure

// Consider the period in generating request parameters in SelectStandaloneInformationRegisterDimensionsToProcess ().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetPeriod(BuildParameters)
	
	BuildParameters.SelectionFields.Insert(0, "Period");
	BuildParameters.Directions.Insert(0, "");
	
EndProcedure

// Consider the resources in generating request parameters in SelectStandaloneInformationRegisterDimensionsToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetResources(BuildParameters, Resources)
	
	If BuildParameters.SelectionFields.Count() = 0 Then
		For Each Resource In Resources Do
			If BuildParameters.UsedOrderingFields[Resource.Name] = Undefined Then
				BuildParameters.SelectionFields.Add(Resource.Name);
				BuildParameters.Directions.Add("");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Consider the attributes in generating request parameters in SelectStandaloneInformationRegisterDimensionsToProcess().
//
// Parameters:
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
Procedure SetAttributes(BuildParameters, Attributes)
	
	If BuildParameters.SelectionFields.Count() = 0 Then
		For Each Attribute In Attributes Do
			If BuildParameters.UsedOrderingFields[Attribute.Name] = Undefined Then
				BuildParameters.SelectionFields.Add(Attribute.Name);
				BuildParameters.Directions.Add("");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Set the data in the following functions considering selection by page:
// - SelectRegisterRecordersToProcess();
// - SelectRefsToProcess();
// - SelectStandaloneInformationRegisterDimensionsToProcess();
//
// Parameters:
//  Request - Request - data selection request.
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
// Returns:
//  * QueryResultSelection - in case of usual selection.
//  * ValueTable - in case of selection by page.
//
Function SelectDataToProcess(Query, BuildParameters)
	
	If BuildParameters.SelectionByPage Then
		Return SelectDataByPage(Query, BuildParameters);
	Else
		Query.Text = StrReplace(Query.Text, "&PagesCondition", "TRUE");
		Return Query.Execute().Select();
	EndIf;
	
EndFunction

// Get the value table with the data to process considering selection by page.
//
// Parameters:
//  Request - Request - data selection request.
//  BuildParameters - Structure - see SelectionBuildParameters(). 
//
// Returns:
//  ValueTable - data for update handler (multithread).
//
Function SelectDataByPage(Query, BuildParameters)
	
	SelectionFields = BuildParameters.SelectionFields;
	Parameters = BuildParameters.AdditionalParameters;
	ChangesTable = BuildParameters.TableName;
	Directions = BuildParameters.Directions;
	LastSelectedRecord = Parameters.LastSelectedRecord;
	FirstRecord = Parameters.FirstRecord;
	LatestRecord = Parameters.LatestRecord;
	SelectFirstRecords = LastSelectedRecord = Undefined
	              AND FirstRecord = Undefined
	              AND LatestRecord = Undefined;
	
	If SelectFirstRecords Then
		ChangeSelectionMax(Query.Text, MaxRecordsCountInSelection(), Parameters.MaxSelection);
		Query.Text = StrReplace(Query.Text, "&PagesCondition", "TRUE");
		Result = Query.Execute().Unload();
	Else
		SelectRange = FirstRecord <> Undefined AND LatestRecord <> Undefined;
		BaseQueryText = Query.Text;
		
		If SelectRange Then
			Conditions = PageRangeConditions(SelectionFields, Parameters, Directions);
		Else
			Conditions = ConditionsForTheFollowingPage(SelectionFields, Parameters, Directions);
		EndIf;
		
		If Parameters.OptimizeSelectionByPages Then
			Result = Undefined;
			LastConditionIndex = Conditions.Count() - 1;
			DeferTemporaryTablesDrop = Conditions.Count() > 1;
			
			If DeferTemporaryTablesDrop Then
				TemporaryTablesDropQueryText = CutTemporaryTablesDrop(BaseQueryText);
			EndIf;
			
			For Index = 0 To LastConditionIndex Do
				If Result = Undefined Then
					Count = Parameters.MaxSelection;
				Else
					Count = Parameters.MaxSelection - Result.Count();
				EndIf;
				
				Query.Text = String(BaseQueryText);
				ChangeSelectionMax(Query.Text, MaxRecordsCountInSelection(), Count);
				SetSelectionByPageConditions(Query, Conditions, ChangesTable, Parameters, True, Index);
				
				If DeferTemporaryTablesDrop AND Index = LastConditionIndex Then
					Query.Text = Query.Text + TemporaryTablesDropQueryText;
				EndIf;
				
				DataExported = Query.Execute().Unload();
				
				If Result = Undefined Then
					Result = DataExported;
				Else
					For each ExportString In DataExported Do
						ResultString = Result.Add();
						FillPropertyValues(ResultString, ExportString);
					EndDo;
				EndIf;
				
				If Result.Count() = Parameters.MaxSelection Then
					Break;
				EndIf;
			EndDo;
		Else
			ChangeSelectionMax(Query.Text, MaxRecordsCountInSelection(), Parameters.MaxSelection);
			SetSelectionByPageConditions(Query, Conditions, ChangesTable, Parameters, True);
			Result = Query.Execute().Unload();
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Delete from the requests package temporary tables deletion and return them as a result of this function.
//
// Parameters:
//  QueryText - String - the modified query text.
//
// Returns:
//  String - text fragment with temporary tables deletion.
//
Function CutTemporaryTablesDrop(QueryText)
	
	DropQueries = New Array;
	PositionToDrop = StrFind(QueryText, "DROP");
	
	While PositionToDrop > 0 Do
		SeparatorPosition = StrFind(QueryText, ";",, PositionToDrop);
		
		If SeparatorPosition > 0 Then
			DropQuery = Mid(QueryText, PositionToDrop, SeparatorPosition - PositionToDrop + 1);
		Else
			DropQuery = Mid(QueryText, PositionToDrop);
		EndIf;
		
		If DropQueries.Count() = 0 Then
			DropQueries.Add(Chars.LF);
		EndIf;
		
		DropQueries.Add(DropQuery);
		QueryText = StrReplace(QueryText, DropQuery, "");
		PositionToDrop = StrFind(QueryText, "DROP");
	EndDo;
	
	Return StrConcat(DropQueries, Chars.LF);
	
EndFunction

// Add conditions restricting selection by page to the query.
//
// Selection by page operates in two modes:
// - selection from above - the records larger than the specified one (similar to the dynamic list),
// - range selection - records between two specified records including them.
//
// Parameters:
//  Request - Request - data selection request.
//  Conditions - see PageRangeConditions(). 
//  Table - String - name of the table from which the selection is executed.
//  Parameters - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
//  First - Boolean - True if they are first conditions in the query.
//  ConditionNumber - Number - processing condition number.
//
Procedure SetSelectionByPageConditions(Query, Conditions, Table, Parameters, First, ConditionNumber = Undefined)
	
	FirstRecord = Parameters.FirstRecord;
	LatestRecord = Parameters.LatestRecord;
	SelectRange = FirstRecord <> Undefined
	                AND LatestRecord <> Undefined;
	
	If Not SelectRange Then
		FirstRecord = Parameters.LastSelectedRecord;
	EndIf;
	
	Columns = Conditions.Columns;
	ColumnsCount = Columns.Count();
	ConditionsAnd = New Array;
	ConditionsOr = New Array;
	HasConditionsOr = (ConditionNumber = Undefined);
	HasTable = Not IsBlankString(Table);
	ConditionAndPattern = ?(HasTable, Table + ".%1 %2 &%3", "%1 %2 &%3");
	ConditionOrPattern = "(%1)";
	ConditionsAndSeparator =
		"
		|	AND ";
	ConditionsOrSeparator =
		"
		|	) OR (
		|	";
	
	If HasConditionsOr Then
		StartIndex = 0;
		EndIndex = Conditions.Count() - 1;
	Else
		StartIndex = ConditionNumber;
		EndIndex = ConditionNumber;
	EndIf;
	
	For RowIndex = StartIndex To EndIndex Do
		ConditionsAnd.Clear();
		
		For ColumnIndex = 0 To ColumnsCount - 1 Do
			Operator = Conditions[RowIndex][ColumnIndex];
			FieldIndex = ?(SelectRange, Int(ColumnIndex / 2), ColumnIndex) + 2;
			
			If Not IsBlankString(Operator) Then
				Column = Columns[ColumnIndex];
				FullFieldName = Column.Title;
				ParameterName = Column.Name + "Value";
				FieldName = ColumnNameForQuery(FullFieldName);
				Condition = StringFunctionsClientServer.SubstituteParametersToString(ConditionAndPattern, FieldName, Operator, ParameterName);
				ConditionsAnd.Add(Condition);
				
				If IsRangeEndColumnName(FullFieldName) Then
					ParameterValue = LatestRecord[FieldIndex].Value;
				Else
					ParameterValue = FirstRecord[FieldIndex].Value;
				EndIf;
				
				Query.SetParameter(ParameterName, ParameterValue);
			EndIf;
		EndDo;
		
		ConditionsText = StrConcat(ConditionsAnd, ConditionsAndSeparator);
		
		If HasConditionsOr Then
			ConditionsOr.Add(ConditionsText);
		EndIf;
	EndDo;
	
	If HasConditionsOr Then
		ConditionsOrText = StrConcat(ConditionsOr, ConditionsOrSeparator);
		ConditionsText = StringFunctionsClientServer.SubstituteParametersToString(ConditionOrPattern, ConditionsOrText);
	EndIf;
	
	If Not First Then
		ConditionsText = "	AND " + ConditionsText;
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&PagesCondition", ConditionsText);
	
EndProcedure

// Get conditions to filter records larger than the specified one (similar to the dynamic list).
//
// Parameters:
//  SelectionFields - Array - fields selected by query.
//  Parameters - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
//  Directions - Array - ordering directions (ASC, and DESC) in the quantity equal to the SelectionFields quantity.
//              - Undefined - order is not specified (always ASC).
//
// Returns:
//  ValueTable - see NewConditionsOfSelectionByPage(). 
//
Function ConditionsForTheFollowingPage(SelectionFields, Parameters, Directions)
	
	AllConditions = NewConditionsOfSelectionByPage(SelectionFields);
	FieldsCount = SelectionFields.Count();
	
	While FieldsCount > 0 Do
		NewConditions = AllConditions.Add();
		
		For ConditionNumber = 1 To FieldsCount Do
			FieldColumnName = SelectionFields[ConditionNumber - 1];
			
			If ConditionNumber < FieldsCount Then
				Operator = "=";
			Else
				Operator = OperatorGreater(Directions[ConditionNumber - 1]);
			EndIf;
			
			NewConditions[ColumnNameFromSelectionField(FieldColumnName)] = Operator;
		EndDo;
		
		FieldsCount = FieldsCount - 1;
	EndDo;
	
	Return AllConditions;
	
EndFunction

// Get the conditions to select the records between two specified records, inclusively.
//
// Parameters:
//  SelectionFields - Array - fields selected by query.
//  Parameters - Structure - see InfobaseUpdate.AdditionalProcessingMarkParameters. 
//  Directions - Array - ordering directions (ASC, and DESC) in the quantity equal to the SelectionFields quantity.
//              - Undefined - order is not specified (always ASC).
//
// Returns:
//  ValueTable - see NewConditionsOfSelectionByPage(). 
//
Function PageRangeConditions(SelectionFields, Parameters, Directions)
	
	AllConditions = NewConditionsOfSelectionByPage(SelectionFields, True);
	FirstRecord = Parameters.FirstRecord;
	LatestRecord = Parameters.LatestRecord;
	FieldsCount = SelectionFields.Count();
	FieldsTotal = SelectionFields.Count();
	InsertPosition = 0;
	
	While FieldsCount > 0 Do
		CurrentFieldsAreEqual = RecordsAreEqual(FirstRecord, LatestRecord, FieldsCount);
		
		If CurrentFieldsAreEqual AND FieldsCount <> FieldsTotal Then
			Break;
		EndIf;
		
		FirstConditions = AllConditions.Insert(InsertPosition);
		InsertPosition = InsertPosition + 1;
		PreviousFieldsAreEqual = RecordsAreEqual(FirstRecord, LatestRecord, FieldsCount - 1);
		
		If Not PreviousFieldsAreEqual Then
			LastConditions = AllConditions.Insert(InsertPosition);
		EndIf;
		
		For ConditionNumber = 1 To FieldsCount Do
			FieldColumnName = ColumnNameFromSelectionField(SelectionFields[ConditionNumber - 1]);
			FieldColumnNameByRange = RangeColumnName(FieldColumnName);
			
			If ConditionNumber < FieldsCount Or CurrentFieldsAreEqual AND FieldsCount = FieldsTotal Then
				OperatorFirst = "=";
				OperatorLast = "=";
			Else
				Direction = Directions[ConditionNumber - 1];
				
				If FieldsCount = FieldsTotal Then
					OperatorFirst = OperatorGreaterOrEqual(Direction);
					OperatorLast = OperatorLessOrEqual(Direction);
				Else
					OperatorFirst = OperatorGreater(Direction);
					OperatorLast = OperatorLess(Direction);
				EndIf;
				
				// Restriction by the range
				If PreviousFieldsAreEqual Then
					FirstConditions[FieldColumnNameByRange] = OperatorLast;
				EndIf;
			EndIf;
			
			// Selection by the first record
			FirstConditions[FieldColumnName] = OperatorFirst;
			
			// Selection by the last record
			If Not PreviousFieldsAreEqual Then
				LastConditions[FieldColumnNameByRange] = OperatorLast;
			EndIf;
		EndDo;
		
		FieldsCount = FieldsCount - 1;
	EndDo;
	
	Return AllConditions;
	
EndFunction

// Returns the two records comparison result.
//
// Parameters:
//  FirstRecord - see InfobaseUpdateInternal.NewRecordKey(). 
//  LastRecord - see InfobaseUpdateInternal.NewRecordKey(). 
//  FieldsCount - Number - applied fields quantity in the record key.
//
// Returns:
//  Boolean - True if the records are equal.
//
Function RecordsAreEqual(FirstRecord, LatestRecord, FieldsCount)
	
	For Index = 2 To FieldsCount + 2 - 1 Do
		If FirstRecord[Index].Value <> LatestRecord[Index].Value Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Returns the value table with the conditions of selection by page.
//
// Parameters:
//  SelectionFields - Array - fields selected by query.
//  ForRange - Boolean - True if the table will be used to restrict the range.
//                 In this case, additional columns are added for the lower range condition.
//
// Returns:
//  ValueTable - table columns describe query fields, where a full field name is stored in the title.
//                    Column names are generated dynamically from query selection fields.
//                    Each row describes conditions for one query that selects data batches for a 
//                    page or condition group upon the selection via OR. The following conditions 
//                    are stored in the table cells: ("=", ">", "<", ">=", "<=")..
// 
Function NewConditionsOfSelectionByPage(SelectionFields, ForRange = False)
	
	Conditions = New ValueTable;
	Columns = Conditions.Columns;
	
	For each SelectionField In SelectionFields Do
		Name = ColumnNameFromSelectionField(SelectionField);
		Columns.Add(Name,, SelectionField);
		
		If ForRange Then
			Columns.Add(RangeColumnName(Name),, SelectionField);
		EndIf;
	EndDo;
	
	Return Conditions;
	
EndFunction

// Return a column name for the condition by the range bottom of the selection by page.
//
// Parameters:
//  FieldName - String - a field name.
//
// Returns:
//  String - a field name for the condition by the range bottom.
//
Function RangeColumnName(FieldName)
	
	Return FieldName + "_";
	
EndFunction

// Returns a name, for example, for a value table column, received from the full query field name.
//
// Parameters:
//  Name - String - a full query field name (it can be point-separated).
//
// Returns:
//  String - a field name.
//
Function ColumnNameFromSelectionField(Name)
	
	CharsToReplace = ".,() ";
	ColumnName = String(Name);
	
	For Index = 1 To StrLen(CharsToReplace) Do
		Char = Mid(CharsToReplace, Index, 1);
		ColumnName = StrReplace(ColumnName, Char, "_");
	EndDo;
	
	Return ColumnName;
	
EndFunction

// A field name received from table columns of the selection by pages. NewConditionsOfSelectionByPage()).
//
// Parameters:
//  FieldName - String - a field name.
//
// Returns:
//  String - a field name without service characters.
//
Function ColumnNameForQuery(FieldName)
	
	If IsRangeEndColumnName(FieldName) Then
		Return Left(FieldName, StrLen(FieldName) - 1);
	Else
		Return FieldName;
	EndIf;
	
EndFunction

// Defines if the column describes the end of selection by page range.
//
// Parameters:
//  FieldName - String - a field name.
//
// Returns:
//  Boolean - True if this field describes the selection by page range end.
//
Function IsRangeEndColumnName(FieldName)
	
	Return Right(FieldName, 1) = "_";
	
EndFunction

// Checking if data selection parameters are filed in correctly.
//
// Parameters - Structure - see
//             InfobaseUpdate.AdditionalProcessingDataSelectionParameters.
//
// Returns:
//  Boolean - True if the selection is multithread.
//
Procedure CheckSelectionParameters(Parameters)
	
	If Not Parameters.SelectInBatches AND IsSelectionByPages(Parameters) Then
		Raise NStr("ru = 'Многопоточный обработчик обновления обязан выбирать данные порциями.'; en = 'Multithreaded update handler must select data in portions.'; pl = 'Wielopotokowy program obsługi aktualizacji musi wybrać dane porcjami.';de = 'Ein Multi-Threaded-Update-Handler ist erforderlich, um Daten in Blöcken auszuwählen.';ro = 'Handlerul multi-flux de actualizare este obligat să selecteze aceste poziții.';tr = 'Çok akışlı güncelleme işleyicisi verileri partiler halinde seçmelidir.'; es_ES = 'Procesador de muchos flujos de actualización debe seleccionar datos por partes.'");
	EndIf;
	
EndProcedure

// Checking if name starts from the letter or underscore and can contain only numbers after them.
//
// Parameters:
//  Name - String - a name to check.
//
// Returns:
//  Boolean - True if the ID is correct.
//
Function NameMeetPropertyNamingRequirements(Name)
	
	Numbers = "1234567890";
	If Name = "" Or StrFind(Numbers, Left(Name, 1)) > 0 Then
		Return False;
	EndIf;
	
	InvalidChars = """/\[]:;|=-?*<>,.()+№@!%^&~" + " ";
	NewName = StrConcat(StrSplit(Name, InvalidChars, True));
	Return (NewName = Name);
	
EndFunction

// Generates a query text fragment with fields to select.
//
// Parameters:
//  FieldsNames - Array - field names as an array.
//  Aliases - Array - aliases as an array with the same number of elements, as FieldsNames has.
//             - Undefined - in this case aliases are equal to field names.
//  TableName - String - a name of a table that contains fields,
//                        if a blank row is specified, a table name is not inserted.
//  Additional - Boolean - True, if these are not the first fields in the selection and they require "," before them.
//
// Returns:
//  String - a query text fragment with fields to select.
//
Function FieldsForQuery(FieldsNames, Aliases = Undefined, TableName = "", Additional = False)
	
	FieldsCount = FieldsNames.Count();
	
	If FieldsCount = 0 Then
		Return "";
	EndIf;
	
	HasAliases = Aliases <> Undefined AND Aliases.Count() = FieldsCount;
	FullTableName = ?(IsBlankString(TableName), "", TableName + ".");
	AliasesToUse = New Map;
	Fields = New Array;
	
	For Index = 0 To FieldsCount - 1 Do
		FieldName = FieldsNames[Index];
		
		If HasAliases Then
			Alias = Aliases[Index];
		Else
			Content = StrSplit(FieldName, ".");
			Alias = Content[Content.Count() - 1];
			AliasToUse = AliasesToUse[Alias];
			
			If AliasToUse = Undefined Then
				AliasesToUse[Alias] = 1;
			Else
				AliasesToUse[Alias] = AliasesToUse[Alias] + 1;
				Alias = Alias + Format(AliasesToUse[Alias], "NG=0");
			EndIf;
		EndIf;
		
		If NameMeetPropertyNamingRequirements(Alias) Then
			Alias = " AS " + Alias;
		Else
			Alias = "";
		EndIf;
		
		Name = FullTableName + FieldName + Alias;
		Fields.Add(Name);
	EndDo;
	
	Separator = ",
		|	";
	
	Return ?(Additional, Separator, "") + StrConcat(Fields, Separator);
	
EndFunction

// Generates a query text fragment with the specified order.
//
// Parameters:
//  FieldsNames - Array - field names as an array.
//  Directions - Array - ordering directions (ASC, and DESC) in the quantity equal to the FieldsNames quantity.
//              - Undefined - order is not specified (always ASC).
//  TableName - String - a name of a table that contains fields,
//                        if a blank row is specified, a table name is not inserted.
//  Additional - Boolean - True, if these are not the first fields in the selection and they require "," before them.
//
// Returns:
//  String - a query text fragment for ordering.
//
Function OrderingsForQuery(FieldsNames, Directions = Undefined, TableName = "", Additional = False)
	
	FieldsCount = FieldsNames.Count();
	
	If FieldsCount = 0 Then
		Return "";
	EndIf;
	
	FullTableName = ?(IsBlankString(TableName), "", TableName + ".");
	HasDirections = Directions <> Undefined AND Directions.Count() = FieldsCount;
	Ordering = New Array;
	
	For Index = 0 To FieldsCount - 1 Do
		FieldName = FieldsNames[Index];
		
		If HasDirections Then
			CurrentDirection = Directions[Index];
			Direction = ?(IsBlankString(CurrentDirection), "", " " + CurrentDirection);
		Else
			Direction = "";
		EndIf;
		
		Order = FullTableName + FieldName + Direction;
		Ordering.Add(Order);
	EndDo;
	
	Separator = ",
		|	";
	
	Return ?(Additional, Separator, "") + StrConcat(Ordering, Separator);
	
EndFunction

// Set size of the query filter that gets data for an update.
//
// Parameters:
//  QueryText - String - a modified query text.
//  Parameters - Structure - see
//              InfobaseUpdate.AdditionalProcessingDataSelectionParameters.
//
Procedure SetSelectionSize(QueryText, Parameters)
	
	SelectionSize = ?(Parameters.SelectInBatches, Parameters.MaxSelection, Undefined);
	ChangeSelectionMax(QueryText, 10000, SelectionSize);
	
EndProcedure

// Set query selection size (FIRST N).
//
// Parameters:
//  QueryText - String - text of a query to be modified.
//  CurrentCount - Number - the amount specified in the current query text.
//  NewCount - Number a new value for "FIRST N".
//                  - Undefined - Select all (without FIRST N).
//
Procedure ChangeSelectionMax(QueryText, CurrentCount, NewCount)
	
	SearchText = "TOP " + Format(CurrentCount, "NZ=0; NG=0");
	
	If NewCount = Undefined Then
		ReplacementText = "";
	Else
		ReplacementText = "TOP " + Format(NewCount, "NZ=0; NG=0");
	EndIf;
	
	QueryText = StrReplace(QueryText, SearchText, ReplacementText);
	
EndProcedure

// Set selection fields considering multithread update handlers.
//
// Parameters:
//  Query - Query - a query to be modified.
//  FieldsNames - Array - names of fields to select.
//  Aliases - Array - aliases of fields to select.
//  TableName - String - a name of a table that contains fields,
//                        if a blank row is specified, a table name is not inserted.
//
Procedure SetFieldsByPages(Query, BuildParameters)
	
	FieldsToSelect = FieldsForQuery(BuildParameters.SelectionFields,
		BuildParameters.Aliases,
		BuildParameters.TableName);
	
	Query.Text = StrReplace(Query.Text, "&SelectedFields", FieldsToSelect);
	
EndProcedure

// Set selection order considering multithread update handlers.
//
// Parameters:
//  Query - Query - a query to be modified.
//  FieldsNames - Array - names of fields to select.
//  Parameters - Structure - see InfobaseUpdate.AdditionalProcessingDataSelectionParameters. 
//  TableName - String - a name of a table that contains fields,
//                        if a blank row is specified, a table name is not inserted.
//  Directions - Array - ordering directions (ASC, and DESC) in the quantity equal to the FieldsNames quantity.
//              - Undefined - order is not specified (always ASC).
//
Procedure SetOrderByPages(Query, BuildParameters)
	
	SelectionFields = BuildParameters.SelectionFields;
	TableName = BuildParameters.TableName;
	Directions = BuildParameters.Directions;
	
	If Directions.Count() = 0 Then
		Directions.Add("DESC");
		
		If BuildParameters.SelectionByPage Then
			For Index = 1 To SelectionFields.Count() - 1 Do
				Directions.Add("");
			EndDo;
		EndIf;
	EndIf;
	
	SelectionOrder = OrderingsForQuery(SelectionFields, Directions, TableName);
	Query.Text = StrReplace(Query.Text, "&SelectionOrder", SelectionOrder);
	
EndProcedure

// Allows to delermine if the selection is by pages.
//
// Parameters:
//   Parameters - Structure - see
//             InfobaseUpdate.AdditionalProcessingDataSelectionParameters.
//
// Returns:
//  Boolean - True if the selection is multithread.
//
Function IsSelectionByPages(Parameters)
	
	Return Parameters.Property("SelectionMethod") AND Parameters.SelectInBatches;
	
EndFunction

// Returns if ordering is ascending.
//
// Parameters:
//  Direction - String - an ordering direction to check.
//
// Returns:
//  Boolean - True if ordering is ascending, otherwise False.
//
Function OrderingAscending(Direction)
	
	If Direction = Undefined Then
		Return True;
	Else
		OrderInReg = Upper(Direction);
	
		// DontTranslate: DESC.
		Return NOT (OrderInReg = "DESC" Or OrderInReg = "DESC");
	EndIf;
	
EndFunction

// Returns the ">" operator for selection by pages considering the ordering direction.
//
// Parameters:
//  Direction - String - an ordering direction to check.
//
// Returns:
//  String - the ">" operator if Order = ASC, otherwise "<".
//
Function OperatorGreater(Direction)
	
	Return ?(OrderingAscending(Direction), ">", "<");
	
EndFunction

// Returns the "<" operator for selection by pages considering the ordering direction.
//
// Parameters:
//  Direction - String - an ordering direction to check.
//
// Returns:
//  String - the "<" operator if Order = ASC, otherwise ">".
//
Function OperatorLess(Direction)
	
	Return ?(OrderingAscending(Direction), "<", ">");
	
EndFunction

// Returns the ">=" operator for selection by pages considering the ordering direction.
//
// Parameters:
//  Direction - String - an ordering direction to check.
//
// Returns:
//  String - the ">=" operator if Order = ASC, otherwise "<=".
//
Function OperatorGreaterOrEqual(Direction)
	
	Return ?(OrderingAscending(Direction), ">=", "<=");
	
EndFunction

// Returns the "<=" operator for selection by pages considering the ordering direction.
//
// Parameters:
//  Direction - String - an ordering direction to check.
//
// Returns:
//  String - the "<=" operator if Order = ASC, otherwise ">=".
//
Function OperatorLessOrEqual(Direction)
	
	Return ?(OrderingAscending(Direction), "<=", ">=");
	
EndFunction

// Returns a metadata object name from its full name.
//
// Parameters:
//  FullName - String - full name of a metadata object.
//
// Returns:
//  String - a metadata object name (after fullstop).
//
Function MetadataObjectName(FullName)
	
	Position = StrFind(FullName, ".", SearchDirection.FromEnd);
	
	If Position > 0  Then
		Return Mid(FullName, Position + 1);
	Else
		Return FullName;
	EndIf;
	
EndFunction

// Returns if there are ordering fields.
//
// Parameters:
//  
Function OrderingFieldsAreSet(AdditionalParameters)
	
	Return AdditionalParameters.OrderFields.Count() > 0;
	
EndFunction

// Returns a data source kind (see AdditionalProcessingDataSelectionParameters(), cl. 1, and cl. 2.
//
// Parameters:
//  AdditionalDataSources - Structure - see AdditionalProcessingDataSelectionParameters(). 
//
// Returns:
//  Boolean - True if it is a simple set of sources as in clause 1, False if it is a map hierarchy 
//           as in clause 2.
//
Function IsSimpleDataSource(AdditionalDataSources)
	
	SimpleSource = False;
	ComplexSource = False;
	MapType = Type("Map");
	
	For each KeyAndValue In AdditionalDataSources Do
		If TypeOf(KeyAndValue.Value) = MapType Then
			ComplexSource = True;
		Else
			SimpleSource = True;
		EndIf;
	EndDo;
	
	If SimpleSource AND ComplexSource Then
		Error = NStr("ru = 'Источник данных задан неверно (см. ДополнительныеПараметрыВыборкиДанныхДляОбработки()).'; en = 'Invalid data source (see AdditionalProcessingDataSelectionParameters()).'; pl = 'Źródło danych jest ustawione niepoprawnie (zob. AdditionalProcessingDataSelectionParameters()).';de = 'Die Datenquelle ist nicht korrekt eingestellt (siehe AdditionalProcessingDataSelectionParameters()).';ro = 'Sursa de date este specificată incorect (vezi AdditionalProcessingDataSelectionParameters()).';tr = 'Veri kaynağı yanlış olarak belirtilmiştir (bkz. AdditionalProcessingDataSelectionParameters()).'; es_ES = 'La fuente de datos está especificada incorrectamente (véase AdditionalProcessingDataSelectionParameters()).'");
		Raise Error;
	Else
		Return SimpleSource;
	EndIf;
	
EndFunction

#EndRegion