///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See AddInsServer.UpdateSharedAddIn. 
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Not Common.DataSeparationEnabled() Or Common.SeparatedDataUsageAvailable() Then 
		Raise
			NStr("ru = 'Загрузка общий внешних компонент возможна только в неразделенном режиме модели сервиса.'; en = 'External component shares can be imported only in SaaS undivided mode.'; pl = 'Pobieranie ogólnych komponentów zewnętrznych jest możliwe tylko w trybie niepodzielonym modelu serwisu.';de = 'Das Herunterladen der gemeinsamen externen Komponenten ist nur im ungeteilten Modus des Servicemodells möglich.';ro = 'Importul componentelor externe este posibilă numai în regimul neseparat al modelului serviciului.';tr = 'Paylaşılan bir dış bileşen yalnızca hizmet modelinin ayrılmaz modunda yüklenebilir.'; es_ES = 'La carga común de los componentes externos es posible solo en el modo no distribuido del modelo de servicio.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты'; en = 'Supplied external components.Import supplied component'; pl = 'Dostarczane komponenty zewnętrzne. Pobierane dostarczanego komponentu';de = 'Mitgelieferte externe Komponenten. Laden Sie die mitgelieferten Komponenten herunter';ro = 'Componentele externe furnizate.Importul componentei furnizate';tr = 'Sağlanan dış bileşenler. Sağlanan bileşenleri yükleme'; es_ES = 'Componentes externos suministrados. Carga del componente suministrado'", 
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Инициирована загрузка поставляемой обработки
			           |%1'; 
			           |en = 'Supplied data processor import is initiated
			           |%1'; 
			           |pl = 'Inicjowane pobieranie dostarczanego przetwarzania 
			           |%1';
			           |de = 'Initiiertes Herunterladen der gelieferten Bearbeitung
			           |%1';
			           |ro = 'Importul procesării furnizate 
			           |%1 este inițiat';
			           |tr = 'Sağlanan veri işlemcisinin içe aktarma başlatıldı
			           |%1'; 
			           |es_ES = 'Se ha iniciado la carga del procesamiento suministrado
			           |%1'"),
		AddInsInternal.AddInPresentation(
			ComponentDetails.ID, 
			ComponentDetails.Version)));
		
	Ref = Catalogs.CommonAddIns.FindByID(
		ComponentDetails.ID, 
		ComponentDetails.Version);
	
	If Ref.IsEmpty() Then
		SharedAddIn = Catalogs.CommonAddIns.CreateItem();
	Else 
		SharedAddIn = Ref.GetObject();
	EndIf;
	
	SharedAddIn.Fill(Undefined); // Default constructor
	
	ComponentBinaryData = New BinaryData(ComponentDetails.PathToFile);
	FileStorageAddress = PutToTempStorage(ComponentBinaryData);
	Information = AddInsInternal.InformationOnAddInFromFile(FileStorageAddress, False);
	
	If Not Information.Disassembled Then 
		WriteLogEvent(NStr("ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты'; en = 'Supplied external components.Import supplied component'; pl = 'Dostarczane komponenty zewnętrzne. Pobierane dostarczanego komponentu';de = 'Mitgelieferte externe Komponenten. Laden Sie die mitgelieferten Komponenten herunter';ro = 'Componentele externe furnizate.Importul componentei furnizate';tr = 'Sağlanan dış bileşenler. Sağlanan bileşenleri yükleme'; es_ES = 'Componentes externos suministrados. Carga del componente suministrado'",
			Common.DefaultLanguageCode()),
		EventLogLevel.Error, , , Information.ErrorDescription);
		Return;
	EndIf;
	
	FillPropertyValues(SharedAddIn, Information.Attributes); // By manifest data.
	FillPropertyValues(SharedAddIn, ComponentDetails);   // By data from the website.
	
	SharedAddIn.AddInStorage = New ValueStorage(ComponentBinaryData);
	
	Try
		SharedAddIn.Write();
	Except
		WriteLogEvent(NStr("ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты'; en = 'Supplied external components.Import supplied component'; pl = 'Dostarczane komponenty zewnętrzne. Pobierane dostarczanego komponentu';de = 'Mitgelieferte externe Komponenten. Laden Sie die mitgelieferten Komponenten herunter';ro = 'Componentele externe furnizate.Importul componentei furnizate';tr = 'Sağlanan dış bileşenler. Sağlanan bileşenleri yükleme'; es_ES = 'Componentes externos suministrados. Carga del componente suministrado'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.CommonAddIns.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Catalogs.CommonAddIns);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToMaster. 
Procedure OnSendDataToMaster(DataItem, ItemSending, Recipient) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.CommonAddIns") Then
		ItemSending = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave. 
Procedure OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.CommonAddIns") Then
		ItemSending = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster. 
Procedure OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.CommonAddIns") Then
		GetItem = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave. 
Procedure OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.CommonAddIns") Then
		GetItem = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
