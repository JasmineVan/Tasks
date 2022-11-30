///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Variables

Var VerificationRequired;
Var DataToWrite;
Var PreparedData;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// There is no DataExchange.Load property value verification, because the limitations imposed by the 
	// script should not be bypassed by passing True to the Load property (on the side of the script 
	// that records to this register).
	//
	// This register cannot be included in any exchanges or data import or export operations if the data 
	// area separation is enabled.
	
	If PreparedData Then
		Load(DataToWrite);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// There is no DataExchange.Load property value verification, because the limitations imposed by the 
	// script should not be bypassed by passing True to the Load property (on the side of the script 
	// that records to this register).
	//
	// This register cannot be included in any exchanges or data import or export operations if the data 
	// area separation is enabled.
	
	If VerificationRequired Then
		
		For Each Record In ThisObject Do
			
			VerificationRows = DataToWrite.FindRows(
				New Structure("ID, DataType", Record.ID, Record.DataType));
			
			If VerificationRows.Count() <> 1 Then
				VerificationError();
			Else
				
				VerificationRow = VerificationRows.Get(0);
				
				CurrentData = Common.ValueToXMLString(Record.Data.Get());
				VerificationData = Common.ValueToXMLString(VerificationRow.Data.Get());
				
				If CurrentData <> VerificationData Then
					VerificationError();
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataToRecord() Export
	
	ReceivingParameters = Undefined;
	If Not AdditionalProperties.Property("ReceivingParameters", ReceivingParameters) Then
		Raise NStr("ru = 'Не определены параметры получения данных'; en = 'The data getting parameters are not defined.'; pl = 'Nie określono parametrów uzyskania danych';de = 'Datenempfangsparameter sind nicht angegeben';ro = 'Parametrii de primire a datelor nu sunt specificați';tr = 'Veri girişi parametreleri belirtilmemiş'; es_ES = 'Parámetros del recibo de datos no se han especificado'");
	EndIf;
	
	DataToWrite = Unload();
	
	For Each Row In DataToWrite Do
		
		Data = InformationRegisters.ProgramInterfaceCache.PrepareVersionCacheData(Row.DataType, ReceivingParameters);
		Row.Data = New ValueStorage(Data);
		
	EndDo;
	
	PreparedData = True;
	
EndProcedure

Procedure VerificationError()
	
	Raise NStr("ru = 'Недопустимое изменение ресурса Данные записи регистра сведений КэшПрограммныхИнтерфейсов
                            |внутри транзакции записи из сеанса с включенным разделением.'; 
                            |en = 'The Data resource of the ProgramInterfaceCache information register record cannot be changed
                            |inside the record transaction from the session with separation enabled.'; 
                            |pl = 'Nieprawidłowa zmiana zasobu Zapisz dane rejestru informacji CacheProgramInterface
                            |W zapisie transakcji z sesji z włączonym splitem.';
                            |de = 'Unzulässige Änderung der Ressourcendaten des Datenregistersatzes CacheSoftwareSchnittstellen
                            |innerhalb der Transaktion des Datensatzes aus der Sitzung bei aktivierter Aufteilung.';
                            |ro = 'Modificare inadmisibilă a resursei Datele înregistrării registrului de date КэшПрограммныхИнтерфейсов
                            |în interiorul tranzacției de înregistrare din sesiunea cu separare activată.';
                            |tr = 'Kabul  edilemez kaynak güncellemesi Bilgi kayıt cihazı verileri
                            | ProgramArayüzüÖnbellek etkinleştirilmiş bölümlü oturumdan kayıt işlemi  içinde!'; 
                            |es_ES = 'No se admite cambiar el recurso Datos de guardar el registro de información ProgramInterfaceCache
                            |dentro de transacción del registro de la sesión con la separación activada.'");
	
EndProcedure

#EndRegion

#Region Initializing

DataToWrite = New ValueTable();
VerificationRequired = Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable();
PreparedData = False;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf