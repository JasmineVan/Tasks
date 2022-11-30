///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Web service operation handlers

// Matches the DeliverMessages web service operation.
Function DeliverMessages(SenderCode, StreamStorage)
	
	SetPrivilegedMode(True);
	
	// Getting the sender link.
	Sender = ExchangePlans.MessageExchange.FindByCode(SenderCode);
	
	If Sender.IsEmpty() Then
		
		Raise NStr("ru = 'Заданы неправильные настройки подключения к конечной точке.'; en = 'Invalid endpoint connection settings.'; pl = 'Nieprawidłowe ustawienia połączenia punktu końcowego.';de = 'Ungültige Einstellungen für die Endpunktverbindung.';ro = 'Setări de conexiune nevalide pentru punctul final.';tr = 'Geçersiz uç nokta bağlantı ayarları.'; es_ES = 'Configuraciones de conexión del punto extremo inválidas.'");
		
	EndIf;
	
	ImportedMessages = Undefined;
	DataReadPartially = False;
	
	// Importing messages to the infobase.
	MessageExchangeInternal.SerializeDataFromStream(
		Sender,
		StreamStorage.Get(),
		ImportedMessages,
		DataReadPartially);
	
	// Processing message queue.
	If Common.FileInfobase() Then
		
		MessageExchangeInternal.ProcessSystemMessageQueue(ImportedMessages);
		
	Else
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ImportedMessages", ImportedMessages);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
		ExecutionParameters.RunInBackground = True;
		
		TimeConsumingOperations.ExecuteInBackground(
			"MessageExchangeInternal.ProcessSystemMessageQueueInBackground",
			ProcedureParameters,
			ExecutionParameters);
		
	EndIf;
	
	If DataReadPartially Then
		
		Raise NStr("ru = 'Произошла ошибка при доставке быстрых сообщений - некоторые сообщения
                                |не были доставлены из-за установленных блокировок областей данных.
                                |
                                |Эти сообщения будут обработаны в рамках очереди обработки сообщений системы.'; 
                                |en = 'An error occurred when delivering instant messages. Some messages
                                |were not delivered due to the set locks of data areas.
                                |
                                |These messages will be processed within the queue for processing system messages.'; 
                                |pl = 'Wystąpił błąd podczas wysyłki wiadomości błyskawicznych – niektóre wiadomości
                                |nie zostały dostarczone z powodu blokad zainstalowanych obszarów danych.
                                |
                                |Wiadomości te będą przetwarzane w ramach kolejki przetwarzania komunikatów systemu.';
                                |de = 'Bei der Zustellung von schnellen Nachrichten ist ein Fehler aufgetreten - einige der Nachrichten 
                                |wurden aufgrund der gesetzten Sperren des Datenbereichs nicht zugestellt.
                                |
                                |Diese Nachrichten werden in der Systemnachrichtenwarteschlange verarbeitet.';
                                |ro = 'Eroare la livrarea mesajelor rapide - unele mesaje
                                |nu au fost livrate din cauza blocărilor instalate ale domeniilor de date.
                                |
                                |Aceste mesaje vor fi procesate în cadrul rândului de procesare a mesajelor de sistem.';
                                |tr = 'Hızlı mesajlar gönderilirken hata oluştu 
                                |- belirli veri alanı kilitleri nedeniyle bazı mesajlar iletilmedi
                                |
                                |Bu mesajlar, sistemin mesaj işleme kuyruğunda işlenecektir.'; 
                                |es_ES = 'Ha ocurrido un error al enviar los mensajes rápidos 
                                | - algunos mensajes no se han enviado debido al bloqueo del área de datos especificada.
                                |
                                |Estos mensajes se procesarán dentro de la cola de procesamiento de mensajes del sistema.'");
		
	EndIf;
	
	Return "";
	
EndFunction

// Matches the GetInfobaseParameters web service operation.
Function GetInfobaseParameters(ThisEndpointDescription)
	
	SetPrivilegedMode(True);
	
	If IsBlankString(MessageExchangeInternal.ThisNodeCode()) Then
		
		ThisNodeObject = MessageExchangeInternal.ThisNode().GetObject();
		ThisNodeObject.Code = String(New UUID());
		ThisNodeObject.Description = ?(IsBlankString(ThisEndpointDescription),
									MessageExchangeInternal.ThisNodeDefaultDescription(),
									ThisEndpointDescription);
		ThisNodeObject.Write();
		
	ElsIf IsBlankString(MessageExchangeInternal.ThisNodeDescription()) Then
		
		ThisNodeObject = MessageExchangeInternal.ThisNode().GetObject();
		ThisNodeObject.Description = ?(IsBlankString(ThisEndpointDescription),
									MessageExchangeInternal.ThisNodeDefaultDescription(),
									ThisEndpointDescription);
		ThisNodeObject.Write();
		
	EndIf;
	
	ThisPointParameters = Common.ObjectAttributesValues(MessageExchangeInternal.ThisNode(), "Code, Description");
	
	Result = New Structure;
	Result.Insert("Code",          ThisPointParameters.Code);
	Result.Insert("Description", ThisPointParameters.Description);
	
	Return XDTOSerializer.WriteXDTO(Result);
EndFunction

// Matches the ConnectEndpoint web service operation.
Function ConnectEndpoint(Code, Description, RecipientConnectionSettingsXDTO)
	
	Cancel = False;
	
	MessageExchangeInternal.ConnectEndpointAtRecipient(
				Cancel,
				Code,
				Description,
				XDTOSerializer.ReadXDTO(RecipientConnectionSettingsXDTO));
	
	Return Not Cancel;
EndFunction

// Matches the UpdateConnectionSettings web service operation.
Function UpdateConnectionSettings(Code, ConnectionSettingsXDTO)
	
	ConnectionSettings = XDTOSerializer.ReadXDTO(ConnectionSettingsXDTO);
	
	SetPrivilegedMode(True);
	
	Endpoint = ExchangePlans.MessageExchange.FindByCode(Code);
	If Endpoint.IsEmpty() Then
		Raise NStr("ru = 'Заданы неправильные настройки подключения к конечной точке.'; en = 'Invalid endpoint connection settings.'; pl = 'Nieprawidłowe ustawienia połączenia punktu końcowego.';de = 'Ungültige Einstellungen für die Endpunktverbindung.';ro = 'Setări de conexiune nevalide pentru punctul final.';tr = 'Geçersiz uç nokta bağlantı ayarları.'; es_ES = 'Configuraciones de conexión del punto extremo inválidas.'");
	EndIf;
	
	BeginTransaction();
	Try
		
		// Updating connection settings.
		RecordStructure = New Structure;
		RecordStructure.Insert("Endpoint", Endpoint);
		
		RecordStructure.Insert("WebServiceAddress", ConnectionSettings.WSWebServiceURL);
		RecordStructure.Insert("UserName", ConnectionSettings.WSUsername);
		RecordStructure.Insert("Password",          ConnectionSettings.WSPassword);
		RecordStructure.Insert("RememberPassword", True);
		
		// Adding information register record
		InformationRegisters.MessageExchangeTransportSettings.UpdateRecord(RecordStructure);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return "";
	
EndFunction

// Matches the SetLeadingEndPoint web service operation.
Function SetLeadingEndpoint(ThisEndpointCode, LeadingEndpointCode)
	
	MessageExchangeInternal.SetLeadingEndpointAtRecipient(ThisEndpointCode, LeadingEndpointCode);
	
	Return "";
	
EndFunction

// Matches the TestConnectionAtRecipient web service operation.
Function TestConnectionAtRecipient(ConnectionSettingsXDTO, SenderCode)
	
	SetPrivilegedMode(True);
	
	ErrorMessageString = "";
	
	WSProxy = MessageExchangeInternal.GetWSProxy(XDTOSerializer.ReadXDTO(ConnectionSettingsXDTO), ErrorMessageString);
	
	If WSProxy = Undefined Then
		Raise ErrorMessageString;
	EndIf;
	
	WSProxy.TestConnectionSender(SenderCode);
	
	Return "";
	
EndFunction

// Matches the TestConnectionAtSender web service operation .
Function TestConnectionAtSender(SenderCode)
	
	SetPrivilegedMode(True);
	
	If MessageExchangeInternal.ThisNodeCode() <> SenderCode Then
		
		Raise NStr("ru = 'Настройки подключения базы получателя указывают на другого отправителя.'; en = 'Sender infobase connection settings indicate another recipient.'; pl = 'Ustawienia połączenia z bazą odbiorcy wskazują na innego nadawcę.';de = 'Die Einstellungen der Empfängerbasisverbindung zeigen einen anderen Absender an.';ro = 'Setările conexiunii bazei destinatarului indică un alt expeditor.';tr = 'Alıcı baz bağlantı ayarları başka bir göndereni gösterir.'; es_ES = 'Configuraciones de conexión de la base del destinatario indican otro remitente.'");
		
	EndIf;
	
	Return "";
	
EndFunction

// Matches the Ping web service operation.
Function Ping()
	
	// Stub. Used to prevent error during the configuration checking.
	Return "";
	
EndFunction

#EndRegion
