///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Obsolete. It will be removed in the next library version.
// Returns an array of methods that can be executed in safe mode.
// 
//
// Returns:
//   Array - an array of strings that store the allowed methods.
//
Function GetAllowedMethods() Export
	
	Result = New Array();
	
	Return New FixedArray(Result);
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns a dictionary of synonyms and parameters of additional report and data processor 
// permission kinds (to display in the user interface).
//
// Returns:
//  FixedMap - keys:
//    * Key - XDTOType - a key appropriate to the permission kind.
//    * Value - Structure - keys:
//        * Presentation - String - a short presentation of the permission kind.
//        * Details - String - permission kind details.
//        * Parameters - ValueTable - columns:
//            * Name - String - a name of the property defined for XDTOType.
//            * Details - String - details of permission parameter consequences for the specified parameter value.
//        * AnyValueDetails - String - details of permission parameter consequences for an undefined parameter value.
//
Function Dictionary() Export
	
	Result = New Map();
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	Presentation = NStr("ru = 'Получение данных из сети Интернет'; en = 'Receiving data over the internet'; pl = 'Pobieranie danych z Internetu';de = 'Empfangen von Daten aus dem Internet';ro = 'Primirea datelor de pe Internet';tr = 'İnternetten veri alma'; es_ES = 'Recibiendo datos de Internet'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено получать данные из сети Интернет'; en = 'Allow the additional report or data processor to receive web data'; pl = 'Dodatkowe sprawozdanie lub procedura przetwarzania danych będą mogły odbierać dane z Internetu';de = 'Ein zusätzlicher Bericht oder Datenprozessor darf Daten aus dem Internet empfangen';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea de a primi date de pe Internet';tr = 'Ek rapor veya veri işlemcinin internetten veri almasına izin verilecek'; es_ES = 'Se permitirá al informe adicional o el procesador recibir los datos de Internet'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "Host", NStr("ru = 'с сервера %1'; en = 'from %1 server'; pl = 'z serwera %1';de = 'vom Server %1';ro = 'de la server-ul %1';tr = 'sunucudan %1'; es_ES = 'del servidor %1'"), NStr("ru = 'с любого сервера'; en = 'from all servers'; pl = 'z dowolnego serwera';de = 'von jedem Server';ro = 'de pe orice server';tr = 'herhangi bir sunucudan'; es_ES = 'de cualquier servidor'"));
	AddParameter(Parameters, "Protocol", NStr("ru = 'по протоколу %1'; en = 'over %1 protocol'; pl = 'protokołem %1';de = 'nach Protokoll %1';ro = 'prin protocolul %1';tr = 'protokole göre%1'; es_ES = 'según el protocolo %1'"), NStr("ru = 'по любому протоколу'; en = 'over all protocols'; pl = 'dowolnym protokołem';de = 'durch irgendein Protokoll';ro = 'prin orice protocol';tr = 'herhangi bir protokole göre'; es_ES = 'según cualquier protocolo'"));
	AddParameter(Parameters, "Port", NStr("ru = 'через порт %1'; en = 'using port %1'; pl = 'przez port %1';de = 'über Port %1';ro = 'prin portul %1';tr = 'port ile%1'; es_ES = 'a través del puerto %1'"), NStr("ru = 'через любой порт'; en = 'using all ports'; pl = 'przez dowolny port';de = 'über einen beliebigen Port';ro = 'prin orice port';tr = 'herhangi port ile'; es_ES = 'a través cualquier puerto'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Parameters", Parameters);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DataReceivingFromInternetType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("ru = 'Передача данных в сеть Интернет'; en = 'Sending data over the internet'; pl = 'Transfer danych do Internetu';de = 'Datenübertragung ins Internet';ro = 'Transferul de date către Internet';tr = 'İnternete veri aktarımı'; es_ES = 'Traslado de datos a Internet'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено отправлять данные в сеть Интернет'; en = 'Allow the additional report or data processor to send web data'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będą mogły wysyłać dane do Internetu';de = 'Ein zusätzlicher Bericht oder Datenprozessor darf Daten an das Internet senden';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea de a trimite date în Internet';tr = 'Ek rapor veya veri işlemcinin internete veri göndermesine izin verilecektir'; es_ES = 'Se permitirá al informe adicional o el procesador de datos enviar los datos a Internet'");
	Consequences = NStr("ru = 'Внимание! Отправка данных потенциально может использоваться дополнительным
                        |отчетом или обработкой для совершения действий, не предполагаемых администратором
                        |информационной базы.
                        |
                        |Используйте данный дополнительный отчет или обработку только в том случае, если доверяете
                        |ее разработчику и контролируйте ограничения (сервер, протокол и порт), накладываемые на
                        |выданные разрешения.'; 
                        |en = 'Warning! This option might lead to unwanted behavior from the additional report or data processor.
                        |
                        |Use this additional report or data processor only if you trust the developer.
                        |Also, ensure that the usage of servers, protocols, and ports is properly configured
                        |and complies to the safety requirements.'; 
                        |pl = 'Uwaga! Wysłanie danych potencjalnie może być używane przez sprawozdanie
                        |lub przetwarzanie dodatkowe do dokonania czynności, nie zakładanych przez administratora
                        |bazy informacyjnej.
                        |
                        |Korzystaj z danego sprawozdania lub przetwarzania dodatkowego tylko wtedy, gdy ufasz
                        |jej programisty i kontroluj ograniczenia (serwer, protokół i port), nałożone na
                        |wydane zezwolenia.';
                        |de = 'Achtung: Das Senden von Daten kann möglicherweise von einem zusätzlichen
                        |Bericht oder einer zusätzlichen Verarbeitung verwendet werden, um Aktionen durchzuführen, die vom Administrator
                        |der Datenbank nicht erwartet werden.
                        |
                        |Verwenden Sie diesen zusätzlichen Bericht oder diese Verarbeitung nur, wenn Sie
                        |dem Entwickler vertrauen und die Einschränkungen (Server, Protokoll und Port) kontrollieren, die sich
                        |aus den erteilten Berechtigungen ergeben.';
                        |ro = 'Atenție! Trimiterea datelor potențial poate fi utilizată de raportul
                        |sau procesarea suplimentară pentru comiterea acțiunilor ne preconizate de administratorul
                        |bazei de informații.
                        |
                        |Utilizați acest raport sau procesare suplimentară numai în cazul în care aveți încredere
                        |în dezvoltatorul ei și monitorizați restricțiile (server, protocol și port) impuse pentru
                        |permisiunile eliberate.';
                        |tr = 'Uyarı! Potansiyel  olarak veri gönderimi, 
                        |veritabanları yöneticisi tarafından öngörülmeyen eylemler için ek bir rapor veya veri işlemcisi tarafından  kullanılabilir. 
                        |
                        |Bu ek raporu veya veri işlemciyi, yalnızca  yayımlanmış izinlere eklenmiş geliştiriciye ve denetim kısıtlamasına  (sunucu, protokol ve bağlantı noktası) 
                        |
                        |güveniyorsanız kullanın.
                        |'; 
                        |es_ES = '¡Aviso! El envío de los datos potencialmente puede utilizarse por un informe
                        |adicional o un procesador de datos para actos, que no están alegados por el administrador
                        |de las infobases.
                        |
                        |Utilizar este informe adicional o el procesador de datos solo si usted confía
                        |en el desarrollador, y controlar la restricción (servidor, protocolo y puerto),
                        |adjuntada a los permisos emitidos.'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "Host", NStr("ru = 'на сервер %1'; en = 'to server %1'; pl = 'na serwer %1';de = 'zum Server %1';ro = 'la server-ul %1';tr = 'sunucuya %1'; es_ES = 'al servidor %1'"), NStr("ru = 'на любой сервера'; en = 'to all servers'; pl = 'na dowolny serwer';de = 'auf jedem Server';ro = 'pe orice server';tr = 'herhangi bir sunucuda'; es_ES = 'en cualquier servidor'"));
	AddParameter(Parameters, "Protocol", NStr("ru = 'по протоколу %1'; en = 'over %1 protocol'; pl = 'protokołem %1';de = 'nach Protokoll %1';ro = 'prin protocolul %1';tr = 'protokole göre%1'; es_ES = 'según el protocolo %1'"), NStr("ru = 'по любому протоколу'; en = 'over all protocols'; pl = 'dowolnym protokołem';de = 'durch irgendein Protokoll';ro = 'prin orice protocol';tr = 'herhangi bir protokole göre'; es_ES = 'según cualquier protocolo'"));
	AddParameter(Parameters, "Port", NStr("ru = 'через порт %1'; en = 'using port %1'; pl = 'przez port %1';de = 'über Port %1';ro = 'prin portul %1';tr = 'port ile%1'; es_ES = 'a través del puerto %1'"), NStr("ru = 'через любой порт'; en = 'using all ports'; pl = 'przez dowolny port';de = 'über einen beliebigen Port';ro = 'prin orice port';tr = 'herhangi port ile'; es_ES = 'a través cualquier puerto'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Consequences", Consequences);
	Value.Insert("Parameters", Parameters);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DataSendingToInternetType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	Presentation = NStr("ru = 'Обращение к веб-сервисам в сети Интернет'; en = 'Access to web services'; pl = 'Kontakt z serwisami sieci Web w Internecie';de = 'Kontaktaufnahme mit Internetdiensten im Internet';ro = 'Contactarea serviciilor web în Internet';tr = 'İnternette web servislerine başvurma'; es_ES = 'Contactando los servicios web en Internet'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено обращаться к веб-сервисам, расположенным в сети Интернет (при этом возможно как получение дополнительным отчетом или обработкой информации из сети Интернет, так и передача.'; en = 'Allow the additional report or data processor to access web services, which includes sending and receiving web data.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło odwoływać się do usług sieciowych w Internecie (dodatkowe sprawozdanie lub przetwarzanie danych może odbierać i wysyłać pewne informacje w Internecie.';de = 'Ein zusätzlicher Bericht oder Datenverarbeiter darf auf Webdienste im Internet verweisen (ein zusätzlicher Bericht oder Datenprozessor kann einige Informationen im Internet empfangen und senden).';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea de apelare a serviciilor web din Internet (totodată raportul sau procesarea suplimentare vor putea primi și trimite informații pe Internet.';tr = 'Ek  rapor veya veri işlemcisinin internetteki web servislerine başvurmasına  izin verilecektir (ek rapor veya veri işlemcisi İnternet hakkında bazı  bilgiler alabilir ve gönderebilir.'; es_ES = 'Se permitirá al informe adicional o el procesador de datos referirse a los servicios web en Internet (informe adicional o procesador de datos puede recibir y enviar alguna información en Internet.'");
	Consequences = NStr("ru = 'Внимание! Обращение к веб-сервисам потенциально может использоваться дополнительным
                        |отчетом или обработкой для совершения действий, не предполагаемых администратором
                        |информационной базы.
                        |
                        |Используйте данный дополнительный отчет или обработку только в том случае, если доверяете
                        |ее разработчику и контролируйте ограничения (адрес подключения), накладываемые на
                        |выданные разрешения.'; 
                        |en = 'Warning! This option might lead to unwanted behavior from the additional report or data processor.
                        |
                        |Use this additional report or data processor only if you trust the developer.
                        |Also, ensure that the web server address is properly configured
                        |and complies to the safety requirements.'; 
                        |pl = 'Uwaga! Zwrócenie się do usług internetowych potencjalnie może być używane przez sprawozdanie lub przetwarzanie dodatkowe
                        | do dokonania czynności, nie zakładanych przez administratora
                        |bazy informacyjnej.
                        |
                        |Korzystaj z danego sprawozdania lub przetwarzania dodatkowego tylko wtedy, gdy ufasz
                        |jej programisty i kontroluj ograniczenia (adres podłączenia), nałożone na
                        |wydane zezwolenia.';
                        |de = 'Achtung! Der Zugriff auf Webdienste kann möglicherweise von einem zusätzlichen
                        |Bericht oder einer zusätzlichen Verarbeitung verwendet werden, um Aktionen auszuführen, die vom Administrator
                        |der Informationsbasis nicht beabsichtigt sind.
                        |
                        |Verwenden Sie diesen zusätzlichen Bericht oder diese Verarbeitung nur, wenn Sie
                        |dem Entwickler darauf vertrauen und die Einschränkungen (Verbindungsadresse) für die
                        |erteilten Berechtigungen kontrollieren.';
                        |ro = 'Atenție! Adresarea la serviciile web potențial poate fi utilizată de raportul
                        |sau procesarea suplimentară pentru executarea acțiunilor care nu sunt preconizate de administratorul
                        |bazei de informații.
                        |
                        |Utilizați acest raport sau procesare suplimentară numai în cazul în care aveți încredere în
                        |dezvoltatorul ei și monitorizați restricțiile (adresa de conexiune), impuse pentru
                        |permisiunile eliberate.';
                        |tr = 'Uyarı! Potansiyel  olarak web hizmetlerine başvuru, 
                        |veritabanları yöneticisi tarafından öngörülmeyen 
                        |eylemler için ek bir rapor veya veri işlemcisi tarafından  kullanılabilir. 
                        |
                        |Bu ek raporu veya veri işlemciyi, yalnızca  yayımlanmış 
                        |izinlere eklenmiş geliştiriciye ve denetim kısıtlamasına  (sunucu, protokol ve bağlantı noktası) 
                        |güveniyorsanız kullanın.'; 
                        |es_ES = '¡Aviso! Llamada a los servicios web potencialmente puede utilizarse por un informe
                        |adicional o un procesador de datos para acciones que no están alegadas por el administrador
                        |de las infobases.
                        |
                        |Utilizar este informe adicional o el procesador de datos solo si usted
                        |confía en el desarrollador, y controlar la restricción (dirección de la conexión), adjuntada
                        |a los permisos emitidos.'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "WsdlDestination", NStr("ru = 'по адресу %1'; en = 'at web address %1'; pl = 'pod adresem %1';de = 'an die Adresse %1';ro = 'la adresa %1';tr = 'adreste %1'; es_ES = 'en la dirección %1'"), NStr("ru = 'по любому адресу'; en = 'at all web addresses'; pl = 'pod dowolnym adresem';de = 'durch irgendeine Adresse';ro = 'la orice adresă';tr = 'herhangi bir adrese göre'; es_ES = 'por cualquier dirección'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Consequences", Consequences);
	Value.Insert("Parameters", Parameters);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.WSConnectionType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	Presentation = NStr("ru = 'Создание COM-объекта'; en = 'Create COM objects'; pl = 'Utwórz obiekt COM';de = 'Erstellen Sie ein COM-Objekt';ro = 'Crearea obiectului COM';tr = 'COM nesnesini oluştur'; es_ES = 'Crear el objeto COM'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено использовать механизмы внешнего программного обеспечения с помощью COM-соединения'; en = 'Allow the additional report or data processor to interact with other applications over COM connections.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło korzystać z mechanizmów oprogramowania zewnętrznego korzystającego z połączenia COM';de = 'Zusätzlicher Bericht oder Datenprozessor darf Mechanismen externer Software über COM-Verbindung verwenden';ro = 'Raportul sau procesarea suplimentară va avea permisiunea să utilizeze mecanismele software-ului extern folosind conexiunea COM';tr = 'Ek rapor veya veri işlemcisinin COM bağlantısı kullanarak harici yazılım mekanizmalarını kullanmasına izin verilecektir.'; es_ES = 'Se permitirá al informe adicional o el procesador de datos utilizar los mecanismos del software externo utilizando la conexión COM'");
	Consequences = NStr("ru = 'Внимание! Использование средств стороннего программного обеспечения может использоваться
                        |дополнительным отчетом или обработкой для совершения действий, не предполагаемых администратором
                        |информационной базы, а также для несанкционированного обхода ограничений, накладываемых на дополнительную обработку
                        |в безопасном режиме.
                        |
                        |Используйте данный дополнительный отчет или обработку только в том случае, если доверяете
                        |ее разработчику и контролируйте ограничения (программный идентификатор), накладываемые на
                        |выданные разрешения.'; 
                        |en = 'Warning! This option might lead to unwanted behavior from the additional report or data processor,
                        |including unauthorized bypass of safe mode restrictions.
                        |
                        |Use this additional report or data processor only if you trust the developer.
                        |Also, ensure that the web server address is properly configured
                        |and complies to the safety requirements.'; 
                        |pl = 'Uwaga! Użycie środków oprogramowania postronnego może być stosowane
                        |przez sprawozdanie lub przetwarzanie dodatkowe do dokonania czynności, nie zakładanych przez administratora
                        |bazy informacyjnej oraz do niedozwolonego obejścia ograniczeń, nałożonych na przetwarzanie dodatkowe
                        |w trybie bezpiecznym.
                        |
                        |Korzystaj z danego sprawozdania lub przetwarzania dodatkowego tylko wtedy, gdy ufasz
                        |jej programisty i kontroluj ograniczenia (identyfikator programowy), nałożone na
                        |wydane zezwolenia.';
                        |de = 'Achtung: Die Verwendung von Softwaretools von Drittanbietern kann durch
                        |zusätzliche Berichterstattung oder Verarbeitung genutzt werden, um Aktionen durchzuführen, die nicht vom Administrator
                        |der Informationsdatenbank angenommen werden, sowie zur unbefugten Umgehung von Einschränkungen der zusätzlichen Verarbeitung
                        |im abgesicherten Modus.
                        |
                        |Verwenden Sie diesen zusätzlichen Bericht oder diese Verarbeitung nur, wenn Sie
                        |dem Entwickler vertrauen und die Einschränkungen (Softwarekennung) für die
                        |erteilten Berechtigungen kontrollieren.';
                        |ro = 'Atenție! Folosirea mijloacelor software-ului extern poate fi utilizată de raportul
                        |sau procesarea suplimentară pentru executarea acțiunilor care nu sunt preconizate de administratorul
                        |bazei de informații, precum și pentru evitarea nesancționată a restricțiilor impuse procesării suplimentare
                        |în regim securizat.
                        |
                        |Utilizați acest raport sau procesare suplimentară numai în cazul în care aveți încredere în
                        |dezvoltatorul ei și monitorizați restricțiile (identificatorul de program), impuse pentru
                        |permisiunile eliberate.';
                        |tr = 'Uyarı! Üçüncü  taraf yazılım fonlarının kullanımı, 
                        | veritabanı yöneticisi tarafından öngörülmeyen eylemler için ek bir rapor veya veri işlemcisi  tarafından kullanılabilir ve ayrıca ek işlemin güvenli 
                        |modda getirdiği  kısıtlamaların izinsiz olarak atlatılması için kullanılabilir. 
                        |
                        |Bu  ek raporu veya veri işlemcisini, 
                        |yalnızca verilen izinlere  eklenmiş geliştiriciye 
                        |ve kontrol kısıtlamasına (uygulama kimliği)  
                        |güveniyorsanız kullanın.'; 
                        |es_ES = '¡Aviso! Uso de los fondos del software de la tercera parte puede utilizarse
                        |por un informe adicional o un procesador de datos para acciones que no están alegadas por el administrador
                        |de la infobase, y también para una circunvención no autorizada de las restricciones impuestas por el procesamiento adicional
                        |en el modo seguro.
                        |
                        |Utilizar este informe adicional o el procesador de datos solo si
                        |usted confía en el desarrollador, y controlar la restricción (identificador de la aplicación),
                        |adjuntada a los permisos emitidos.'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "ProgId", NStr("ru = 'с программным идентификатором %1'; en = 'with software ID %1'; pl = 'z dowolnym identyfikatorem programowym %1';de = 'mit Programmkennung %1';ro = 'cu identificatorul de program %1';tr = 'program tanımlayıcısıyla %1'; es_ES = 'con el identificador programático %1'"), NStr("ru = 'с любым программным идентификатором'; en = 'with any software ID'; pl = 'z dowolnym identyfikatorem programowym';de = 'mit irgendeiner Programmkennung';ro = 'cu orice identificator de program';tr = 'herhangi bir program tanımlayıcı ile'; es_ES = 'con cualquier identificados programático'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Consequences", Consequences);
	Value.Insert("Parameters", Parameters);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.COMObjectCreationType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	Presentation = NStr("ru = 'Создание объекта внешней компоненту'; en = 'Create add-in objects'; pl = 'Utwórz obiekt komponentu zewnętrznego';de = 'Objekt der externen Komponente erstellen';ro = 'Crearea obiectului componentei externe';tr = 'Harici bileşenin nesnesini oluştur'; es_ES = 'Crear el objeto del componente externo'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено использовать механизмы внешнего программного обеспечения с помощью создания объекта внешней компоненты, поставляемой в макете конфигурации'; en = 'Allow the additional report or data processor to interact with other applications using embedded add-in.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło korzystać z mechanizmów oprogramowania zewnętrznego poprzez tworzenie obiektu komponentu zewnętrznego, który jest dostarczany w szablonie konfiguracji';de = 'Ein zusätzlicher Bericht oder Datenprozessor kann Mechanismen externer Software  verwenden, indem er ein Objekte einer externen Komponente erstellt, die in der  Konfigurationsvorlage enthalten ist.';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea să utilizeze mecanismele software-ului extern prin crearea unui obiect al componentei externe, care este furnizată în macheta configurației';tr = 'Ek  rapor veya veri işlemcisinin, yapılandırma şablonunda sağlanan harici  bileşen nesnesini oluşturarak harici yazılım mekanizmalarını  kullanmasına izin verilir.'; es_ES = 'Se permitirá al informe adicional o el procesador de datos utilizar los mecanismos del software externo creando un objeto del componente externo, que se proporciona en el modelo de la configuración.'");
	Consequences = NStr("ru = 'Внимание! Использование средств стороннего программного обеспечения может использоваться
                        |дополнительным отчетом или обработкой для совершения действий, не предполагаемых администратором
                        |информационной базы, а также для несанкционированного обхода ограничений, накладываемых на дополнительную обработку
                        |в безопасном режиме.
                        |
                        |Используйте данный дополнительный отчет или обработку только в том случае, если доверяете
                        |ее разработчику и контролируйте ограничения (имя макета, из которого выполняется подключение внешней
                        |компоненты), накладываемые на выданные разрешения.'; 
                        |en = 'Warning! The additional report or data processor might use third-party software features to perform actions
                        |that are not intended by the infobase administrator,
                        |and also to bypass restrictions applied to the additional data processor
                        |in safe mode.
                        |
                        |Use this additional report or data processor only if you trust
                        |the developer, and verify the restrictions applied to
                        |the issued permissions (the name of the source template).'; 
                        |pl = 'Uwaga! Użycie środków oprogramowania postronnego może być stosowane
                        |przez sprawozdanie lub przetwarzanie dodatkowe do dokonania czynności, nie zakładanych przez administratora
                        |bazy informacyjnej oraz do niedozwolonego obejścia ograniczeń nałożonych na przetwarzanie dodatkowe
                        |w trybie bezpiecznym.
                        |
                        |Korzystaj z danego sprawozdania lub przetwarzania dodatkowego tylko wtedy, gdy ufasz
                        |jej programisty i kontroluj ograniczenia (nazwa makiety, z której jest wykonywane podłączenie komponentu
                        |zewnętrznego), nałożone na wydane zezwolenia.';
                        |de = 'Achtung: Die Verwendung von Softwaretools von Drittanbietern kann durch
                        |zusätzliche Berichterstattung oder Verarbeitung genutzt werden, um Aktionen durchzuführen, die nicht vom Administrator
                        |der Informationsdatenbank angenommen werden, sowie zur unbefugten Umgehung von Einschränkungen der zusätzlichen Verarbeitung
                        |im abgesicherten Modus.
                        |
                        |Verwenden Sie den gegebenen zusätzlichen Bericht oder die Verarbeitung nur in diesem Fall, wenn Sie
                        |dem Entwickler vertrauen und Einschränkungen (der Name des Layouts, von dem aus die externen
                        |Komponenten verbunden wird) für die gegebenen Berechtigungen kontrollieren.';
                        |ro = 'Atenție! Folosirea mijloacelor software-ului extern poate fi utilizată de raportul
                        |sau procesarea suplimentară pentru executarea acțiunilor care nu sunt preconizate de administratorul
                        |bazei de informații, precum și pentru evitarea nesancționată a restricțiilor impuse procesării suplimentare
                        |în regim securizat.
                        |
                        |Utilizați acest raport sau procesare suplimentară numai în cazul în care aveți încredere în
                        |dezvoltatorul ei și monitorizați restricțiile (numele machetei din care se face conectarea componentei
                        |externe), impuse pentru permisiunile eliberate.';
                        |tr = 'Uyarı! Üçüncü  taraf yazılım fonlarının kullanımı, 
                        | veritabanı yöneticisi tarafından öngörülmeyen eylemler için ek bir rapor veya veri işlemcisi  tarafından kullanılabilir ve ayrıca ek işlemin güvenli 
                        |modda getirdiği  kısıtlamaların izinsiz olarak atlatılması için kullanılabilir. 
                        |
                        |Bu  ek raporu veya veri işlemcisini, 
                        |yalnızca verilen izinlere  eklenmiş geliştiriciye 
                        |ve kontrol kısıtlamasına (bağlantının harici bileşen olan
                        |şablonun adı) güveniyorsanız kullanın.'; 
                        |es_ES = '¡Aviso! Uso de los fondos del software de la tercera perta puede utilizarse
                        |por un informe adicional o un procesador de datos para acciones que no están alegadas por el administrador
                        |de la infobase, y también para una circunvención no autorizada por el procesamiento adicional
                        |en el modo seguro.
                        |
                        |Utilizar este informe adicional o el procesador de datos solo si usted
                        |confía en el desarrollador, y controlar la restricción (nombre del modelo, desde el cual la conexión
                        |es un componente externo), adjuntada a los permisos emitidos.'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "TemplateName", NStr("ru = 'из макета %1'; en = 'from template %1'; pl = 'z szablonu %1';de = 'von Vorlage %1';ro = 'din șablonul %1';tr = 'şablondan %1'; es_ES = 'desde el modelo %1'"), NStr("ru = 'из любого макета'; en = 'from all templates'; pl = 'z dowolnego szablonu';de = 'von jeder Vorlage';ro = 'din orice șablon';tr = 'herhangi bir şablondan'; es_ES = 'desde cualquier modelo'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Consequences", Consequences);
	Value.Insert("Parameters", Parameters);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.AddInAttachmentType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	Presentation = NStr("ru = 'Получение файлов из внешнего объекта'; en = 'Receive files from external objects'; pl = 'Pobieranie plików od obiektu zewnętrznego';de = 'Empfangen von Dateien von einem externen Objekt';ro = 'Primirea fișierului din obiectul extern';tr = 'Dosyaları harici nesneden al'; es_ES = 'Recibir archivos del objeto externo'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено получать файлы из внешнего программного обеспечения (например, с помощью COM-соединения или внешней компоненты)'; en = 'Allow the additional report or data processor to receive files from other applications using COM connections or an add-ins.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło odbierać pliki z zewnętrznego oprogramowania (na przykład przy użyciu połączenia COM lub komponentu zewnętrznego)';de = 'Zusätzlicher  Bericht oder Datenprozessor darf Dateien von externer Software  empfangen (z. B. über COM-Verbindung oder externe Komponente)';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea să primească fișiere din software-ul extern (de pildă, cu ajutorul conexiunii COM sau componentei externe)';tr = 'Ek  rapor veya veri işlemcisinin harici yazılımdan dosya almasına izin  verilir (örneğin, COM bağlantısı veya harici bileşen kullanılarak)'; es_ES = 'Se permitirá al informe adicional o el procesador de datos recibir archivos del software externo (por ejemplo, utilizando la conexión COM o un componente externo)'");
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.FileReceivingFromExternalObjectType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	Presentation = NStr("ru = 'Передача файлов во внешний объект'; en = 'Send files to external objects'; pl = 'Przesyłanie plików do obiektu zewnętrznego';de = 'Dateiübertragung an das externe Objekt';ro = 'Transferul fișierelor în obiectul extern';tr = 'Harici nesneye dosya aktarımı'; es_ES = 'Traslado de archivos al objeto externo'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено передавать файлы во внешнее программное обеспечение (например, с помощью COM-соединения или внешней компоненты)'; en = 'Allow the additional report or data processor to send files to other applications using COM connections or add-ins.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło przesyłać pliki do zewnętrznego oprogramowania (na przykład za pomocą połączenia COM lub komponentu zewnętrznego)';de = 'Zusätzlicher Bericht oder Datenprozessor darf Dateien an externe Software übertragen (z. B. über COM-Verbindung oder externe Komponente)';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea să trimită fișiere în software-ul extern (de pildă, cu ajutorul conexiunii COM sau componentei externe)';tr = 'Ek  rapor veya veri işlemcisinin dosyaları harici yazılıma aktarmasına izin  verilir (örneğin, COM bağlantısı veya harici bileşen kullanılarak).'; es_ES = 'Se permitirá al informe adicional o el procesador de datos trasladar archivos al software externo (por ejemplo, utilizando la conexión COM o un componente externo)'");
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.TypeTransferFileToExternalObject(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("ru = 'Проведение документов'; en = 'Post documents'; pl = 'Zaksięgowania dokumentów';de = 'Dokumente ausführen';ro = 'Validarea documentelor';tr = 'Belgelerin gönderimi'; es_ES = 'Envío de documentos'");
	Details = NStr("ru = 'Дополнительному отчету или обработке будет разрешено изменять состояние проведенности документов'; en = 'Allow the additional report or data processor to post and unpost documents.'; pl = 'Dodatkowe sprawozdanie lub przetwarzanie danych będzie mogło zmienić stan księgowania dokumentu';de = 'Ein zusätzlicher Bericht oder Datenverarbeiter darf Belege buchen oder die Buchung ausgleichen.';ro = 'Raportul sau procesarea suplimentară vor avea permisiunea să modifica statutul de validare a documentelor';tr = 'Ek rapor veya veri işlemcinin belgelerin gönderim durumunu değiştirmesine izin verilecektir'; es_ES = 'Se permitirá al informe adicional o el procesador de datos cambiar el estado de envío de documentos'");
	
	Parameters = ParametersTable();
	AddParameter(Parameters, "DocumentType", NStr("ru = 'документы с типом %1'; en = 'documents of %1 type'; pl = 'dokumenty z typem %1';de = 'Dokumente mit Typ %1';ro = 'documente cu tipul %1';tr = '%1 tür belgeler'; es_ES = 'documentos con el tipo %1'"), NStr("ru = 'любые документы'; en = 'all documents'; pl = 'wszelkie dokumenty';de = 'irgendwelche Dokumente';ro = 'orice documente';tr = 'herhangi belgeler'; es_ES = 'cualquier documento'"));
	AddParameter(Parameters, "Action", NStr("ru = 'разрешенное действие: %1'; en = '%1 only'; pl = 'dozwolone czynności: %1';de = 'zulässige Aktion: %1';ro = 'acțiune permisă: %1';tr = 'izin verilen eylem: %1'; es_ES = 'acción permitida: %1'"), NStr("ru = 'любое изменение состояния проведения'; en = 'post and unpost'; pl = 'dowolne zmiany statusu dekretowania';de = 'sowohl Buchung als auch Buchung ausgleichen';ro = 'orice modificare a statutului validării';tr = 'herhangi bir gönderi durumu değişikliği'; es_ES = 'cualquier cambio del estado de envío'"));
	
	Value = New Structure;
	Value.Insert("Presentation", Presentation);
	Value.Insert("Details", Details);
	Value.Insert("Parameters", Parameters);
	Value.Insert("DisplayToUser", Undefined);
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DocumentPostingType(),
		Value);
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddParameter(Val ParametersTable, Val Name, Val Details, Val AnyValueDetails)
	
	Parameter = ParametersTable.Add();
	Parameter.Name = Name;
	Parameter.Details = Details;
	Parameter.AnyValueDetails = AnyValueDetails;
	
EndProcedure

Function ParametersTable()
	
	Result = New ValueTable();
	Result.Columns.Add("Name", New TypeDescription("String"));
	Result.Columns.Add("Details", New TypeDescription("String"));
	Result.Columns.Add("AnyValueDetails", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

#EndRegion
