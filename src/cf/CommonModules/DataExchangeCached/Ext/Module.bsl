///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use the new one (see DataExchangeServer.IsOfflineMode).
//
Function IsStandaloneWorkplace() Export
	
	SetPrivilegedMode(True);
	
	If Constants.SubordinateDIBNodeSetupCompleted.Get() Then
		
		Return Constants.IsStandaloneWorkplace.Get();
		
	Else
		
		MasterNodeOfThisInfobase = DataExchangeServer.MasterNode();
		Return MasterNodeOfThisInfobase <> Undefined
			AND IsStandaloneWorkstationNode(MasterNodeOfThisInfobase);
		
	EndIf;
	
EndFunction

// Obsolete. Use the new one (see DataExchangeCached.ExchangePlanNodeByCode).
//
Function FindExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	QueryText =
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	ExchangePlan.[ExchangePlanName] AS ExchangePlan
	|WHERE
	|	ExchangePlan.Code = &Code";
	
	QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
	
	Query = New Query;
	Query.SetParameter("Code", NodeCode);
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return Undefined;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Returns a flag that shows whether an exchange plan is used in data exchange.
// If an exchange plan contains at least one node apart from the predefined one, it is considered 
// being used in data exchange.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is set in Designer.
//  Sender - ExchangePlanRef - the parameter value is set if it is necessary to determine whether 
//   there are other exchange nodes besides the one from which the object was received.
//   
//
// Returns:
//  Boolean. True - exchange plan is used, False - not used.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender = Undefined) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		Return False;
	EndIf;
	
	QueryText = "SELECT TOP 1 1
	|FROM
	|	ExchangePlan." + ExchangePlanName + " AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.DeletionMark
	|	AND NOT ExchangePlan.ThisNode
	|	AND ExchangePlan.Ref <> &Sender";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Sender", Sender);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// See DataExchangeServer.IsStandaloneWorkstationNode. 
//
Function IsStandaloneWorkstationNode(Val InfobaseNode) Export
	
	Return DataExchangeCached.StandaloneModeSupported()
		AND InfobaseNode.Metadata().Name = DataExchangeCached.StandaloneModeExchangePlan();
	
EndFunction

// See DataExchangeServer.ExchangePlansSettings 
Function ExchangePlanSettings(ExchangePlanName, CorrespondentVersion = "", CorrespondentName = "", CorrespondentInSaaS = Undefined) Export
	Return DataExchangeServer.ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, CorrespondentInSaaS);
EndFunction

// See DataExchangeServer.SettingOptionsDetails 
Function SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion = "", CorrespondentName = "") Export
	Return DataExchangeServer.SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion, CorrespondentName);
EndFunction
////////////////////////////////////////////////////////////////////////////////
// The mechanism of object registration on exchange plan nodes (ORM).

// Gets the name of this infobase from a constant or a configuration synonym.
// (For internal use only).
//
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	
	Result = Constants.SystemTitle.Get();
	
	If IsBlankString(Result) Then
		
		Result = Metadata.Synonym;
		
	EndIf;
	
	Return Result;
EndFunction

// Gets a code of a predefined exchange plan node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  String - a code of a predefined exchange plan node.
//
Function GetThisNodeCodeForExchangePlan(ExchangePlanName) Export
	
	Return Common.ObjectAttributeValue(GetThisExchangePlanNode(ExchangePlanName), "Code");
	
EndFunction

// Gets a name of a predefined exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  String - name of the predefined exchange plan node.
//
Function ThisNodeDescription(Val InfobaseNode) Export
	
	Return Common.ObjectAttributeValue(GetThisExchangePlanNode(GetExchangePlanName(InfobaseNode)), "Description");
	
EndFunction

// Gets an array of names of configuration exchange plans that use the SSL functionality.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of exchange plan name items.
//
Function SSLExchangePlans() Export
	
	Return SSLExchangePlansList().UnloadValues();
	
EndFunction

// Determines whether an exchange plan specified by name is used in SaaS mode.
// For this purpose, all exchange plans on their manager module level define the 
// ExchangePlanUsedInSaaS() function which explicitly returns True or False.
// 
//
// Parameters:
//   ExchangePlanName - String.
//
// Returns:
//   Boolean.
//
Function ExchangePlanUsedInSaaS(Val ExchangePlanName) Export
	
	Result = False;
	
	If SSLExchangePlans().Find(ExchangePlanName) <> Undefined Then
		Result = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"ExchangePlanUsedInSaaS", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in the list of possible error codes.
//
// Returns:
//  Map. Key - error code (number), value - error description (string).
//
Function ErrorMessages() Export
	
	ErrorMessages = New Map;
		
	ErrorMessages.Insert(2,  NStr("ru = 'Ошибка распаковки файла обмена. Файл заблокирован.'; en = 'Cannot unpack the exchange file. The file is locked.'; pl = 'Wystąpił błąd podczas rozpakowywania pliku wymiany. Plik jest zablokowany.';de = 'Beim Entpacken einer Austausch-Datei ist ein Fehler aufgetreten. Die Datei ist gesperrt.';ro = 'A apărut o eroare la dezarhivarea unui fișier de schimb. Fișierul este blocat.';tr = 'Bir değişim dosyasını paketinden çıkarılırken bir hata oluştu. Dosya kilitli.'; es_ES = 'Ha ocurrido un error al desembalar un archivo de intercambio. El archivo está bloqueado.'"));
	ErrorMessages.Insert(3,  NStr("ru = 'Указанный файл правил обмена не существует.'; en = 'The exchange rules file does not exist.'; pl = 'Określony plik reguły wymiany nie istnieje.';de = 'Die angegebene Austausch-Regeldatei existiert nicht.';ro = 'Fișierul de reguli de schimb specificat nu există.';tr = 'Belirtilen değişim kuralları dosyası mevcut değil.'; es_ES = 'El archivo de la regla del intercambio especificado no existe.'"));
	ErrorMessages.Insert(4,  NStr("ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument'; en = 'Cannot create COM object: Msxml2.DOMDocument.'; pl = 'Podczas tworzenia COM obiektu Msxml2.DOMDocument wystąpił błąd';de = 'Beim Erstellen des COM-Objekts Msxml2.DOMDocument ist ein Fehler aufgetreten';ro = 'Eroare la crearea obiectului COM Msxml2.DOMDocument';tr = 'Msxml2.DOMDocument COM nesnesi oluştururken bir hata oluştu '; es_ES = 'Ha ocurrido un error al crear el objeto COM Msxml2.DOMDocumento'"));
	ErrorMessages.Insert(5,  NStr("ru = 'Ошибка открытия файла обмена'; en = 'Cannot open the exchange file.'; pl = 'Podczas otwarcia pliku wymiany wystąpił błąd';de = 'Beim Öffnen der Austausch-Datei ist ein Fehler aufgetreten';ro = 'Eroare la deschiderea fișierului de schimb';tr = 'Değişim dosyası açılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al abrir el archivo de intercambio'"));
	ErrorMessages.Insert(6,  NStr("ru = 'Ошибка при загрузке правил обмена'; en = 'Cannot load the exchange rules.'; pl = 'Podczas importu reguł wymiany wystąpił błąd';de = 'Beim Importieren von Austausch-Regeln ist ein Fehler aufgetreten';ro = 'Eroare la importul regulilor de schimb';tr = 'Değişim kuralları içe aktarılırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al importar las reglas de intercambio'"));
	ErrorMessages.Insert(7,  NStr("ru = 'Ошибка формата правил обмена'; en = 'Exchange rule format error.'; pl = 'Błąd formatu reguł wymiany';de = 'Fehler beim Format der Austauschregeln';ro = 'Eroare în formatul regulilor de schimb';tr = 'Değişim kuralı biçiminde hata'; es_ES = 'Error en el formato de la regla de intercambio'"));
	ErrorMessages.Insert(8,  NStr("ru = 'Некорректно указано имя файла для выгрузки данных'; en = 'Invalid data export file name.'; pl = 'Niepoprawnie jest wskazana nazwa pliku do pobierania danych';de = 'Falscher Dateiname für das Hochladen von Daten';ro = 'Numele fișierului pentru exportul de date este indicat incorect';tr = 'Veri dışa aktarma için belirtilen dosya adı yanlıştır'; es_ES = 'Nombre del archivo está indicado incorrectamente para subir los datos'"));
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
	
	ErrorMessages.Insert(78, NStr("ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров'; en = 'Algorithm execution error after importing parameter values.'; pl = 'Podczas wykonania algorytmu po imporcie wartości parametrów wystąpił błąd';de = 'Beim Ausführen des Algorithmus nach dem Import der Parameterwerte ist ein Fehler aufgetreten';ro = 'Eroare la executarea algoritmului după importul valorilor parametrilor';tr = 'Parametre değerlerini içe aktardıktan sonra algoritmayı çalıştırırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al ejecutar el algoritmo después de la importación de los valores del parámetro'"));
	
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
	ErrorMessages.Insert(81, NStr("ru = 'Возникла коллизия изменений объектов.
		|Объект этой информационной базы был заменен версией объекта из второй информационной базы.'; 
		|en = 'Object version conflict.
		|The object in this infobase is replaced with the object version from the other infobase.'; 
		|pl = 'Wystąpił konflikt zmiany obiektu.
		|Ten obiekt bazy informacyjnej został zastąpiony przez drugą wersję obiektu bazy informacyjnej.';
		|de = 'Die Objektwechselkollision ist aufgetreten. 
		|Dieses Infobase-Objekt wurde durch die zweite Infobase-Objektversion ersetzt.';
		|ro = 'A apărut coliziunea de modificare a obiectelor.
		|Obiectul acestei baze de informații a fost înlocuit cu versiunea obiectului din a doua bază de informații.';
		|tr = 'Nesne değişikliği çarpışması meydana geldi. 
		|Bu veritabanı nesnesi, ikinci veritabanı nesne sürümü ile değiştirildi.'; 
		|es_ES = 'Ha ocurrido la colisión del cambio de objeto.
		|Este objeto de la infobase se ha reemplazado por la versión del objeto de la segunda infobase.'"));
	//
	ErrorMessages.Insert(82, NStr("ru = 'Возникла коллизия изменений объектов.
		|Объект из второй информационной базы не принят. Объект этой информационной базы не изменен.'; 
		|en = 'Object version conflict.
		|The object from the other infobase is rejected. The object in this infobase is not changed.'; 
		|pl = 'Wystąpiła kolizja zmiany obiektu.
		|Obiekt z drugiej bazy informacyjnej nie jest akceptowany. Ten obiekt bazy informacyjnej nie został zmodyfikowany.';
		|de = 'Die Objektwechselkollision ist aufgetreten. 
		|Objekt aus der zweiten Infobase wird nicht akzeptiert. Dieses Infobase-Objekt wurde nicht geändert.';
		|ro = 'Coliziune de modificare a obiectelor.
		|Obiectul din baza de informații a doua nu este acceptat. Obiectul acestei baze de informații nu a fost modificat.';
		|tr = 'Nesne değişiklikleri çakışması ortaya çıktı. 
		|İkinci veritabanındaki nesne kabul edilmedi. Bu veritabanı nesnesi değiştirilmedi.'; 
		|es_ES = 'Ha ocurrido la colisión del cambio de objeto.
		|El objeto de la segunda infobase no se ha aceptado. Este objeto de la infobase no se ha modificado.'"));
	//
	ErrorMessages.Insert(83, NStr("ru = 'Ошибка обращения к табличной части объекта. Табличная часть объекта не может быть изменена.'; en = 'Object tabular section access error. Cannot change the tabular section.'; pl = 'Wystąpił błąd podczas uzyskiwania dostępu do sekcji tabelarycznej obiektu. Nie można zmienić sekcji tabelarycznej obiektu.';de = 'Beim Zugriff auf den Objekttabellenabschnitt ist ein Fehler aufgetreten. Der tabellarische Objektbereich kann nicht geändert werden.';ro = 'A apărut o eroare la accesarea secțiunii tabulare a obiectului. Secțiunea tabulară a obiectului nu poate fi modificată.';tr = 'Nesne sekme bölümüne erişilirken bir hata oluştu. Nesne sekme bölümü değiştirilemez.'; es_ES = 'Ha ocurrido un error al acceder a la sección tabular del objeto. La sección tabular del objeto no puede cambiarse.'"));
	ErrorMessages.Insert(84, NStr("ru = 'Коллизия дат запрета изменения.'; en = 'Period-end closing dates conflict.'; pl = 'Konflikt dat zakazu przemiany.';de = 'Kollision der Abschlussdaten der Änderung.';ro = 'Coliziunea datei de închidere a modificării.';tr = 'Değişim kapanış tarihlerinin çarpışması.'; es_ES = 'Colisión de las fechas de cierre de cambios.'"));
	
	ErrorMessages.Insert(174, NStr("ru = 'Сообщение обмена было принято ранее'; en = 'The exchange message was received earlier.'; pl = 'Wiadomość wymiany została przyjęta poprzednio';de = 'Austausch-Nachricht wurde zuvor empfangen';ro = 'Mesajul de schimb a fost primit anterior';tr = 'Değişim iletisi daha önce alındı'; es_ES = 'Mensaje de intercambio se había recibido previamente'"));
	ErrorMessages.Insert(175, NStr("ru = 'Ошибка в обработчике события ПередПолучениемИзмененныхОбъектов (конвертация)'; en = 'BeforeGetChangedObjects event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia BeforeModifiedObjectsReceiving (konwersja)';de = 'Im Ereignis-Anwender BeforeGetChangedObjects ist ein Fehler aufgetreten (Konvertierung)';ro = 'A apărut o eroare în procedura de procesare a evenimentelor BeforeGetChangedObjects (conversie)';tr = 'BeforeGetChangedObjects olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos BeforeGetChangedObjects (conversión)'"));
	ErrorMessages.Insert(176, NStr("ru = 'Ошибка в обработчике события ПослеПолученияИнформацииОбУзлахОбмена (конвертация)'; en = 'AfterGetExchangeNodesInformation event handler error (conversion).'; pl = 'Wystąpił błąd podczas przetwarzania zdarzenia  AfterGettingInformationAboutExchangeNodes (konwertowanie)';de = 'Fehler im AfterReceiveExchangeNodeDetails Ereignis-Anwender (Konvertierung)';ro = 'Eroare în handler de evenimente AfterReceiveExchangeNodeDetails (conversie)';tr = 'DeğişimÜniteleriHakkındakiBilgilerAlındıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'; es_ES = 'Ha ocurrido un error en el manipulador de eventos AfterGettingInformationAboutExchangeNodes (conversión)'"));
		
	ErrorMessages.Insert(177, NStr("ru = 'Имя плана обмена из сообщения обмена не соответствует ожидаемому.'; en = 'Unexpected exchange plan name in the exchange message.'; pl = 'Nazwa planu wymiany w komunikacie wymiany nie jest zgodna z oczekiwaniami.';de = 'Der Name des Austausch-Plans aus der Austausch-Nachricht ist nicht wie erwartet.';ro = 'Numele planului de schimb din mesajul de schimb nu este cel așteptat.';tr = 'Değişim mesajındaki değişim planının ismi beklendiği gibi değil.'; es_ES = 'Nombre del plan de intercambio del mensaje de intercambio no está tan esperado.'"));
	ErrorMessages.Insert(178, NStr("ru = 'Получатель из сообщения обмена не соответствует ожидаемому.'; en = 'Unexpected destination in the exchange message.'; pl = 'Odbiorca wiadomości wymiany nie jest zgodny z oczekiwaniami.';de = 'Empfänger von der Austausch-Nachricht ist nicht wie erwartet.';ro = 'Destinatarul din mesajul de schimb nu este același.';tr = 'Değişim mesajındaki alıcı beklendiği gibi değil.'; es_ES = 'Destinatario del mensaje de intercambio no está tan esperado.'"));
	
	ErrorMessages.Insert(1000, NStr("ru = 'Ошибка при создании временного файла выгрузки данных'; en = 'Cannot create a temporary data export file.'; pl = 'Wystąpił błąd podczas tworzenia tymczasowego pliku eksportu danych';de = 'Beim Erstellen einer temporären Datei mit Datenexport ist ein Fehler aufgetreten';ro = 'A apărut o eroare la crearea unui fișier temporar de export de date';tr = 'Geçici bir veri aktarımı dosyası oluşturulurken bir hata oluştu'; es_ES = 'Ha ocurrido un error al crear un archivo temporal de la exportación de datos'"));
	
	Return ErrorMessages;
	
EndFunction

Function StandaloneModeSupported() Export
	
	Return StandaloneModeExchangePlans().Count() = 1;
	
EndFunction

Function ExchangePlanPurpose(ExchangePlanName) Export
	
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangePlanPurpose");
	
EndFunction

// Determines whether an exchange plan has a template.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is set in Designer.
//  TemplateName - String - a name of the template to check for existence.
// 
//  Returns:
//   True - the exchange plan contains the specified template. Otherwise, False.
//
Function HasExchangePlanTemplate(Val ExchangePlanName, Val TemplateName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].Templates.Find(TemplateName) <> Undefined;
	
EndFunction

// Returns the flag showing that the exchange plan belongs to the DIB exchange plan.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is set in Designer.
// 
//  Returns:
//   True if the exchange plan belongs to the DIB exchange plan. Otherwise, False.
//
Function IsDistributedInfobaseExchangePlan(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].DistributedInfoBase;
	
EndFunction

Function StandaloneModeExchangePlan() Export
	
	Result = StandaloneModeExchangePlans();
	
	If Result.Count() = 0 Then
		
		Raise NStr("ru = 'Автономная работа в системе не предусмотрена.'; en = 'The application does not support offline work.'; pl = 'Praca offline w aplikacji nie jest obsługiwana.';de = 'Offline-Arbeit in der Anwendung wird nicht unterstützt.';ro = 'Activitatea offline din aplicație nu este acceptată.';tr = 'Uygulamada çevrimdışı çalışma desteklenmiyor.'; es_ES = 'Trabajo offline en la aplicación no se admite.'");
		
	ElsIf Result.Count() > 1 Then
		
		Raise NStr("ru = 'Создано более одного плана обмена для автономной работы.'; en = 'Multiple exchange plans are found for offline mode.'; pl = 'Utworzono więcej niż jeden plan wymiany dla pracy w trybie offline.';de = 'Mehr als ein Austauschplan für Offline-Arbeiten wurde erstellt.';ro = 'Au fost create mai multe planuri de schimb pentru lucrul autonom.';tr = 'Çevrimdışı çalışma için birden fazla değişim planı oluşturuldu.'; es_ES = 'Más de un plan de intercambio para el trabajo offline se ha creado.'");
		
	EndIf;
	
	Return Result[0];
EndFunction

// See DataExchangeServer.IsXDTOExchangePlan. 
//
Function IsXDTOExchangePlan(ExchangePlan) Export
	If TypeOf(ExchangePlan) = Type("String") Then
		ExchangePlanName = ExchangePlan;
	Else
		ExchangePlanName = ExchangePlan.Metadata().Name;
	EndIf;
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "IsXDTOExchangePlan");
EndFunction

Function IsStringAttributeOfUnlimitedLength(FullName, AttributeName) Export
	
	MetadataObject = Metadata.FindByFullName(FullName);
	Attribute = MetadataObject.Attributes.Find(AttributeName);
	
	If Attribute <> Undefined
		AND Attribute.Type.ContainsType(Type("String"))
		AND (Attribute.Type.StringQualifiers.Length = 0) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// See DataExchangeServer.ExchangePlanNodeByCode. 
//
Function ExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	Return DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
	
EndFunction

// Returns a node content table (reference types only).
//
// Parameters:
//    ExchangePlanName - String - an exchange plan to analyze.
//    Periodic - a flag that shows whether objects with date (such as documents) are included in the result.
//    Regulatory - a flag that shows whether regulatory data objects are included in the result.
//
// Returns:
//    ValueTable - a table with the following columns:
//      * FullMetadataName - String - a full metadata name (a table name for the query).
//      * ListPresentation - String - list presentation for a table.
//      * Presentation       - String - object presentation for a table.
//      * PictureIndex      - Number - a picture index according to PictureLib.MetadataObjectsCollection.
//      * Type                 - Type - the corresponding type.
//      * SelectPeriod        - Boolean - a flag showing that filter by period can be applied to the object.
//
Function ExchangePlanContent(ExchangePlanName, Periodic = True, Regulatory = True) Export
	
	ResultTable = New ValueTable;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, PictureIndex, Type, SelectPeriod")) Do
		ResultTable.Columns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, Type")) Do
		ResultTable.Indexes.Add(KeyValue.Key);
	EndDo;
	
	ExchangePlanComposition = Metadata.ExchangePlans.Find(ExchangePlanName).Content;
	For Each CompositionItem In ExchangePlanComposition Do
		
		ObjectMetadata = CompositionItem.Metadata;
		Details = MetadataObjectDetails(ObjectMetadata);
		If Details.PictureIndex >= 0 Then
			If Not Periodic AND Details.Periodic Then 
				Continue;
			ElsIf Not Regulatory AND Details.Reference Then 
				Continue;
			EndIf;
			
			Row = ResultTable.Add();
			FillPropertyValues(Row, Details);
			Row.SelectPeriod        = Details.Periodic;
			Row.FullMetadataName = ObjectMetadata.FullName();
			Row.ListPresentation = DataExchangeServer.ObjectListPresentation(ObjectMetadata);
			Row.Presentation       = DataExchangeServer.ObjectPresentation(ObjectMetadata);
		EndIf;
	EndDo;
	
	ResultTable.Sort("ListPresentation");
	Return ResultTable;
	
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// The mechanism of object registration on exchange plan nodes (ORM).

// Retrieves the table of object registration rules for the exchange plan.
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan as it is set in Designer for which the 
//                    registration rules are to be received.
// 
// Returns:
//   Value table - a table of registration rules for the current exchange plan.
//
Function ExchangePlanObjectsRegistrationRules(Val ExchangePlanName) Export
	
	ObjectsRegistrationRules = DataExchangeInternal.SessionParametersObjectsRegistrationRules().Get();
	
	Return ObjectsRegistrationRules.Copy(New Structure("ExchangePlanName", ExchangePlanName));
EndFunction

// Gets the table of object registration rules for the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - the exchange plan name as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object for which registration rules are to 
//                   be received.
// 
// Returns:
//   Value table - a table of object registration rules for the specified exchange plan.
//
Function ObjectRegistrationRules(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	
	Return ExchangePlanObjectsRegistrationRules.Copy(New Structure("MetadataObjectName", FullObjectName));
	
EndFunction

// Returns a flag that shows whether registration rules exist for the object by the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - the exchange plan name as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object whose registration rules must be 
//                   checked for existence.
// 
//  Returns:
//    True if the object registration rules exist, otherwise False.
//
Function ObjectRegistrationRulesExist(Val ExchangePlanName, Val FullObjectName) Export
	
	Return DataExchangeEvents.ObjectRegistrationRules(ExchangePlanName, FullObjectName).Count() <> 0;
	
EndFunction

// Determines whether automatic registration of a metadata object in exchange plan is allowed.
//
// Parameters:
//  ExchangePlanName   - String - a name of the exchange plan as it is set in Designer which 
//                              contains the metadata object.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag must be checked.
//
//  Returns:
//   True if metadata object automatic registration is allowed in the exchange plan.
//   False if metadata object auto registration is denied in the exchange plan or the exchange plan 
//          does not include the metadata object.
//
Function AutoRegistrationAllowed(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanCompositionItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	If ExchangePlanCompositionItem = Undefined Then
		Return False; // The exchange plan does not include the metadata object.
	EndIf;
	
	Return ExchangePlanCompositionItem.AutoRecord = AutoChangeRecord.Allow;
EndFunction

// Determines whether the exchange plan includes the metadata object.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag is to be checked.
// 
//  Returns:
//   True if the exchange plan includes the object. Otherwise, False.
//
Function ExchangePlanContainsObject(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanCompositionItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	Return ExchangePlanCompositionItem <> Undefined;
EndFunction

// Returns a list of exchange plans that contain at least one exchange node (ignoring ThisNode).
//
Function ExchangePlansInUse() Export
	
	Return DataExchangeServer.GetExchangePlansInUse();
	
EndFunction

// List of metadata objects included in SSL exchange plans, except for DIB, by which the problems 
// like Unfilled attributes
// and Unposted documents can be registered.
//
// Returns:
//   Map - map key - object metadata, the value is True.
//
Function ObjectsToRegisterDataProblemsOnImport() Export
	
	Result = New Map;
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
			Continue;
		EndIf;
		For Each CompositionItem In Metadata.ExchangePlans[ExchangePlanName].Content Do
			Result.Insert(CompositionItem.Metadata, True);
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the exchange plan content specified by the user.
// Custom exchange plan content is determined by the object registration rules and node settings 
// specified by the user.
//
// Parameters:
//  Recipient - ExchangePlanRef - an exchange plan node reference. User content is retrieved for 
//               this node.
//
//  Returns:
//   Map:
//     * Key     - String - a full name of a metadata object that is included in the exchange plan content.
//     * Value - EnumRef.ExchangeObjectExportModes - object export mode.
//
Function UserExchangePlanComposition(Val Recipient) Export
	
	SetPrivilegedMode(True);
	
	Result = New Map;
	
	DestinationProperties = Common.ObjectAttributesValues(Recipient,
		Common.AttributeNamesByType(Recipient, Type("EnumRef.ExchangeObjectExportModes")));
	
	Priorities = ObjectsExportModesPriorities();
	ExchangePlanName = Recipient.Metadata().Name;
	Rules = DataExchangeCached.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	Rules.Indexes.Add("MetadataObjectName");
	
	For Each Item In Metadata.ExchangePlans[ExchangePlanName].Content Do
		
		ObjectName = Item.Metadata.FullName();
		ObjectRules = Rules.FindRows(New Structure("MetadataObjectName", ObjectName));
		ExportMode = Undefined;
		
		If ObjectRules.Count() = 0 Then // Registration rules are not set.
			
			ExportMode = Enums.ExchangeObjectExportModes.ExportAlways;
			
		Else // Registration rules are set.
			
			For Each ORR In ObjectRules Do
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					ExportMode = ObjectExportMaxMode(DestinationProperties[ORR.FlagAttributeName], ExportMode, Priorities);
				EndIf;
				
			EndDo;
			
			If ExportMode = Undefined
				OR ExportMode = Enums.ExchangeObjectExportModes.EmptyRef() Then
				ExportMode = Enums.ExchangeObjectExportModes.ExportByCondition;
			EndIf;
			
		EndIf;
		
		Result.Insert(ObjectName, ExportMode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Returns the object export mode based on the custom exchange plan content (user settings).
//
// Parameters:
//  ObjectName - a metadata object full name. Export mode is retrieved for this metadata object.
//  Recipient - ExchangePlanRef - an exchange plan node reference. The function gets custom content from this node.
//
// Returns:
//   EnumRef.ExchangeObjectExportModes -  object export mode.
//
Function ObjectExportMode(Val ObjectName, Val Recipient) Export
	
	Result = DataExchangeCached.UserExchangePlanComposition(Recipient).Get(ObjectName);
	
	Return ?(Result = Undefined, Enums.ExchangeObjectExportModes.ExportAlways, Result);
EndFunction

Function ObjectExportMaxMode(Val ExportMode1, Val ExportMode2, Val Priorities)
	
	If Priorities.Find(ExportMode1) < Priorities.Find(ExportMode2) Then
		
		Return ExportMode1;
		
	Else
		
		Return ExportMode2;
		
	EndIf;
	
EndFunction

Function ObjectsExportModesPriorities()
	
	Result = New Array;
	Result.Add(Enums.ExchangeObjectExportModes.ExportAlways);
	Result.Add(Enums.ExchangeObjectExportModes.ManualExport);
	Result.Add(Enums.ExchangeObjectExportModes.ExportByCondition);
	Result.Add(Enums.ExchangeObjectExportModes.EmptyRef());
	Result.Add(Enums.ExchangeObjectExportModes.ExportIfNecessary);
	Result.Add(Enums.ExchangeObjectExportModes.DoNotExport);
	Result.Add(Undefined);
	
	Return Result;
EndFunction

// Retrieves the table of object registration attributes for the mechanism of selective object registration.
//
// Parameters:
//  ObjectName     - String - a full metadata object name, for example, "Catalog.Products".
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
//
// Returns:
//  RegistrationAttributesTable - value table - a table of registration attributes ordered by the 
//  Order field for the specified metadata object.
//
Function ObjectAttributesToRegister(ObjectName, ExchangePlanName) Export
	
	ObjectsRegistrationAttributesTable = DataExchangeServer.GetSelectiveObjectsRegistrationRulesSP();
	
	Filter = New Structure;
	Filter.Insert("ExchangePlanName", ExchangePlanName);
	Filter.Insert("ObjectName",     ObjectName);
	
	RegistrationAttributesTable = ObjectsRegistrationAttributesTable.Copy(Filter);
	
	RegistrationAttributesTable.Sort("Order Asc");
	
	Return RegistrationAttributesTable;
	
EndFunction

// Gets the table of selective object registration from session parameters.
//
// Parameters:
//   No.
// 
// Returns:
//   Value table - a table of registration attributes for all metadata objects.
//
Function GetSelectiveObjectsRegistrationRulesSP() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.SelectiveObjectsRegistrationRules.Get();
	
EndFunction

// Gets a predefined exchange plan node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  ThisNode - ExchangePlanRef - a predefined exchange plan node.
//
Function GetThisExchangePlanNode(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName].ThisNode();
	
EndFunction

// Returns the flag showing whether the node belongs to DIB exchange plan.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
// 
//  Returns:
//   True - the node belongs to DIB exchange plan. Otherwise, False.
//
Function IsDistributedInfobaseNode(Val InfobaseNode) Export

	Return InfobaseNode.Metadata().DistributedInfoBase;
	
EndFunction

// Returns the flag showing that the node belongs to a standard exchange plan (without conversion rules).
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan which requires the function value.
// 
//  Returns:
//   True if the node belongs to the standard exchange plan. Otherwise, False.
//
Function IsStandardDataExchangeNode(ExchangePlanName) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
		Return False;
	EndIf;
	
	Return Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		AND Not DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Returns the flag showing whether the node belongs to a universal exchange plan (using conversion rules).
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
// 
//  Returns:
//   True if the node belongs to the universal exchange plan. Otherwise, False.
//
Function IsUniversalDataExchangeNode(InfobaseNode) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(InfobaseNode) Then
		Return True;
	Else
		Return Not IsDistributedInfobaseNode(InfobaseNode)
			AND HasExchangePlanTemplate(GetExchangePlanName(InfobaseNode), "ExchangeRules");
	EndIf;
	
EndFunction

// Returns the flag showing whether the node belongs to an exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef, ExchangePlanObject - an exchange plan node for which the 
//                           function value is to be received.
// 
//  Returns:
//   True if the node belongs to the exchange plan that uses SSL exchange functionality. Otherwise, False.
//
Function IsSSLDataExchangeNode(Val InfobaseNode) Export
	
	Return SSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to a separated exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
// 
//  Returns:
//   True if the node belongs to the separated exchange plan that uses SSL exchange functionality. Otherwise, False.
//
Function IsSeparatedSSLDataExchangeNode(InfobaseNode) Export
	
	Return SeparatedSSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to the exchange plan used for message exchange.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
// 
//  Returns:
//   True if the node belongs to the message exchange plan. Otherwise, False.
//
Function IsMessagesExchangeNode(InfobaseNode) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SaaS.MessageExchange") Then
		Return False;
	EndIf;
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode) = "MessageExchange";
	
EndFunction

// Gets a name of the exchange plan as a metadata object for the specified node.
//
// Parameters:
//  ExchangePlanNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  Name - String - a name of the exchange plan as a metadata object.
//
Function GetExchangePlanName(ExchangePlanNode) Export
	
	Return ExchangePlanNode.Metadata().Name;
	
EndFunction

// Gets a list of templates of standard exchange rules from configuration for the specified exchange plan.
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  RulesList - a value list - a list of templates of standard exchange rules.
//
Function ConversionRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Gets a list of templates of standard registration rules from configuration for the specified exchange plan.
// The list contains names and synonyms of the rule templates.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  RulesList - a value list - a list of templates of standard registration rules.
//
Function RegistrationRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "RecordRules");
	
EndFunction

// Gets a list of configuration exchange plans that use the SSL functionality.
// The list is filled with names and synonyms of exchange plans.
//
// Parameters:
//  No.
// 
// Returns:
//  ExchangePlansList - value list - a list of configuration exchange plans.
//
Function SSLExchangePlansList() Export
	
	// Function return value.
	ExchangePlanList = New ValueList;
	
	SubsystemExchangePlans = New Array;
	
	DataExchangeOverridable.GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan In SubsystemExchangePlans Do
		
		ExchangePlanList.Add(ExchangePlan.Name, ExchangePlan.Synonym);
		
	EndDo;
	
	Return ExchangePlanList;
	
EndFunction

// Gets an array of names of separated configuration exchange plans that use the SSL functionality.
// If the configuration does not contain separators, all exchange plans are treated as separated.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of elements of separated exchange plan names.
//
Function SeparatedSSLExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlanName In SSLExchangePlans() Do
		
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			IsSeparatedConfiguration = ModuleSaaS.IsSeparatedConfiguration();
		Else
			IsSeparatedConfiguration = False;
		EndIf;
		
		If IsSeparatedConfiguration Then
			
			If ModuleSaaS.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName,
					ModuleSaaS.MainDataSeparator()) Then
				
				Result.Add(ExchangePlanName);
				
			EndIf;
			
		Else
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// For internal use.
//
Function CommonNodeData(Val InfobaseNode) Export
	
	Return DataExchangeServer.CommonNodeData(GetExchangePlanName(InfobaseNode),
		InformationRegisters.CommonInfobasesNodesSettings.CorrespondentVersion(InfobaseNode),
		"");
EndFunction

// For internal use.
//
Function ExchangePlanTabularSections(Val ExchangePlanName, Val CorrespondentVersion = "", Val SettingID = "") Export
	
	CommonTables             = New Array;
	ThisInfobaseTables          = New Array;
	AllTablesOfThisInfobase       = New Array;
	
	CommonNodeData = DataExchangeServer.CommonNodeData(ExchangePlanName, CorrespondentVersion, SettingID);
	
	TabularSections = DataExchangeEvents.ObjectTabularSections(Metadata.ExchangePlans[ExchangePlanName]);
	
	If Not IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			If StrFind(CommonNodeData, TabularSection) <> 0 Then
				
				CommonTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ThisInfobaseSettings = DataExchangeServer.NodeFilterStructure(ExchangePlanName, CorrespondentVersion, SettingID);
	
	ThisInfobaseSettings = DataExchangeEvents.StructureKeysToString(ThisInfobaseSettings);
	
	If IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				ThisInfobaseTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				If StrFind(CommonNodeData, TabularSection) = 0 Then
					
					ThisInfobaseTables.Add(TabularSection);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("CommonTables",             CommonTables);
	Result.Insert("ThisInfobaseTables",          ThisInfobaseTables);
	Result.Insert("AllTablesOfThisInfobase",       AllTablesOfThisInfobase);
	
	Return Result;
	
EndFunction

// Gets the exchange plan manager by exchange plan name.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
//
// Returns:
//  ExchangePlanManager - an exchange plan manager.
//
Function GetExchangePlanManagerByName(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName];
	
EndFunction

// Wrapper of the function with the same name.
//
Function ConfigurationMetadata(Filter) Export
	
	For Each FilterItem In Filter Do
		
		Filter[FilterItem.Key] = StrSplit(FilterItem.Value, ",");
		
	EndDo;
	
	Return DataExchangeServer.ConfigurationMetadataTree(Filter);
	
EndFunction

// For internal use.
//
Function ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName) Export
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		InfobaseNode,
		Enums.ActionsOnExchange.DataImport,
		Undefined,
		False);
		
	ExchangeSettingsStructure.DataExchangeDataProcessor.ExchangeFileName = ExchangeMessageFileName;
	
	Return ExchangeSettingsStructure;
	
EndFunction

// Wrapper of the function with the same name from the DataExchangeEvents module.
//
Function NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, FlagAttributeName, Val DataExported = False) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeEvents.NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, FlagAttributeName, DataExported);
	
EndFunction

// Returns a collection of exchange message transports that can be used for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//  SetupOption       - String           - ID of data synchronization setup option.
// 
//  Returns:
//   Array - message transports that are used for the specified exchange plan node.
//
Function UsedExchangeMessagesTransports(InfobaseNode, Val SetupOption = "") Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	If Not InfobaseNode.IsEmpty() Then
		SetupOption = DataExchangeServer.SavedExchangePlanNodeSettingOption(InfobaseNode);
	EndIf;
	
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName,  
		SetupOption, "", "");
	
	Result = SettingOptionDetails.UsedExchangeMessagesTransports;
	
	If Result.Count() = 0 Then
		Result = DataExchangeServer.AllConfigurationExchangeMessagesTransports();
	EndIf;
	
	// Exchange via COM connection is not supported:
	//  - For basic configuration versions.
	//  - For DIB.
	//  - For standard exchange (without conversion rules).
	//  - For 1C servers under Linux.
	//
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
		Or DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		Or DataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName)
		Or Common.IsLinuxServer() Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.COM);
			
	EndIf;
	
	// Exchange via WS connection is not supported:
	//  - For DIB that are not SWP.
	//
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		AND Not DataExchangeCached.IsStandaloneWorkstationNode(InfobaseNode) Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.WS);
		
	EndIf;
	
	// Exchange via WS connection in passive mode is not supported:
	//  - For objects that are not an exchange through XDTO.
	//  - For file infobases.
	//
	If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName)
		Or Common.FileInfobase() Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Establishes an external connection to the infobase and returns a reference to this connection.
// 
// Parameters:
//  InfobaseNode (required) - ExchangePlanRef. Exchange plan node for which the external connection 
//  is required.
//  ErrorMessageString (optional) - String - if establishing connection fails, this parameter will 
//   store the error details.
//
// Returns:
//  COMObject - if external connection is established. Undefined - if external connection is not established.
//
Function GetExternalConnectionForInfobaseNode(InfobaseNode, ErrorMessageString = "") Export

	Result = ExternalConnectionForInfobaseNode(InfobaseNode);

	ErrorMessageString = Result.DetailedErrorDescription;
	Return Result.Connection;
	
EndFunction

// Establishes an external connection to the infobase and returns a reference to this connection.
// 
// Parameters:
//  InfobaseNode (required) - ExchangePlanRef. Exchange plan node for which the external connection 
//  is required.
//  ErrorMessageString (optional) - String - if establishing connection fails, this parameter will 
//   store the error details.
//
// Returns:
//  COMObject - if external connection is established. Undefined - if external connection is not established.
//
Function ExternalConnectionForInfobaseNode(InfobaseNode) Export
	
	Return DataExchangeServer.EstablishExternalConnectionWithInfobase(
        InformationRegisters.DataExchangeTransportSettings.TransportSettings(
            InfobaseNode, Enums.ExchangeMessagesTransportTypes.COM));
	
EndFunction

// Determines whether the exchange plan can be used.
// The flag is calculated by the configuration functional options composition.
// If no functional option includes the exchange plan, the function returns True.
// If functional options include the exchange plan and one or more functional option is enabled, the 
// function returns True.
// Otherwise, the function returns False.
//
// Parameters:
//  ExchangePlanName - String. Name of the exchange plan to get the flag for.
//
// Returns:
//  True - the exchange plan can be used.
//  False - it cannot be used.
//
Function ExchangePlanUsageAvailable(Val ExchangePlanName) Export
	
	ObjectIsIncludedInFunctionalOptions = False;
	
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		
		If FunctionalOption.Content.Contains(Metadata.ExchangePlans[ExchangePlanName]) Then
			
			ObjectIsIncludedInFunctionalOptions = True;
			
			If GetFunctionalOption(FunctionalOption.Name) = True Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not ObjectIsIncludedInFunctionalOptions Then
		
		Return True;
		
	EndIf;
	
	Return False;
EndFunction

// Returns an array of version numbers supported by correspondent API for the DataExchange subsystem.
// 
// Parameters:
//   Correspondent - Structure, ExchangePlanRef. Exchange plan node that corresponds the 
//                 correspondent infobase.
//
// Returns:
//   Array of version numbers that are supported by correspondent API.
//
Function CorrespondentVersions(Val Correspondent) Export
	
	If TypeOf(Correspondent) = Type("Structure") Then
		SettingsStructure = Correspondent;
	Else
		If DataExchangeCached.IsMessagesExchangeNode(Correspondent) Then
			ModuleMessagesExchangeTransportSettings = InformationRegisters["MessageExchangeTransportSettings"];
			SettingsStructure = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(Correspondent);
		Else
			SettingsStructure = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(Correspondent);
		EndIf;
	EndIf;
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("URL",      SettingsStructure.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", SettingsStructure.WSUsername);
	ConnectionParameters.Insert("Password", SettingsStructure.WSPassword);
	
	Return Common.GetInterfaceVersions(ConnectionParameters, "DataExchange");
	
EndFunction

// Returns the array of all reference types available in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Result = New Array;
	
	CommonClientServer.SupplementArray(Result, Catalogs.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Documents.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, BusinessProcesses.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCharacteristicTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfAccounts.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCalculationTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Tasks.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ExchangePlans.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Enums.AllRefsType().Types());
	
	Return Result;
EndFunction

Function StandaloneModeExchangePlans()
	
	// An exchange plan that is used to implement the standalone mode in SaaS mode must meet the following conditions:
	// - must be separated.
	// - must be a DIB exchange plan.
	// - It must be used for exchange in SaaS (ExchangePlanUsedInSaaS = True).
	
	Result = New Array;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name)
			AND ExchangePlan.DistributedInfoBase
			AND DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function SecurityProfileName(Val ExchangePlanName) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Return Undefined;
	EndIf;
	
	If Catalogs.MetadataObjectIDs.IsDataUpdated() Then
		ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[ExchangePlanName]);
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
	Else
		SecurityProfileName = Undefined;
	EndIf;
	
	If SecurityProfileName = Undefined Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		SecurityProfileName = ModuleSafeModeManager.InfobaseSecurityProfile();
		If IsBlankString(SecurityProfileName) Then
			SecurityProfileName = Undefined;
		EndIf;
	EndIf;
	
	Return SecurityProfileName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of the data exchange settings structure.

// Gets the transport settings structure for data exchange.
//
Function TransportSettingsOfExchangePlanNode(InfobaseNode, ExchangeMessagesTransportKind) Export
	
	Return DataExchangeServer.ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind);
	
EndFunction

// Gets a list of templates of standard rules for data exchange from configuration for the specified exchange plan.
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name as it is specified in Designer.
// 
// Returns:
//  RulesList - a value list - a list of templates of standard rules for data exchange.
//
Function RulesForExchangePlanFromConfiguration(ExchangePlanName, TemplateNameLiteral)
	
	RulesList = New ValueList;
	
	If IsBlankString(ExchangePlanName) Then
		Return RulesList;
	EndIf;
	
	For Each Template In Metadata.ExchangePlans[ExchangePlanName].Templates Do
		
		If StrFind(Template.Name, TemplateNameLiteral) <> 0 AND StrFind(Template.Name, "Correspondent") = 0 Then
			
			RulesList.Add(Template.Name, Template.Synonym);
			
		EndIf;
		
	EndDo;
	
	Return RulesList;
EndFunction

Function MetadataObjectDetails(Meta)
	
	Result = New Structure("PictureIndex, Periodic, Reference, Type", -1, False, False);
	
	If Metadata.Catalogs.Contains(Meta) Then
		Result.PictureIndex = 3;
		Result.Reference = True;
		Result.Type = Type("CatalogRef." + Meta.Name);
		
	ElsIf Metadata.Documents.Contains(Meta) Then
		Result.PictureIndex = 7;
		Result.Periodic = True;
		Result.Type = Type("DocumentRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(Meta) Then
		Result.PictureIndex = 9;
		Result.Reference = True;
		Result.Type = Type("ChartOfCharacteristicTypesRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfAccounts.Contains(Meta) Then
		Result.PictureIndex = 11;
		Result.Reference = True;
		Result.Type = Type("ChartOfAccountsRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(Meta) Then
		Result.PictureIndex = 13;
		Result.Reference = True;
		Result.Type = Type("ChartOfCalculationTypesRef." + Meta.Name);
		
	ElsIf Metadata.BusinessProcesses.Contains(Meta) Then
		Result.PictureIndex = 23;
		Result.Periodic = True;
		Result.Type = Type("BusinessProcessRef." + Meta.Name);
		
	ElsIf Metadata.Tasks.Contains(Meta) Then
		Result.PictureIndex = 25;
		Result.Periodic  = True;
		Result.Type = Type("TaskRef." + Meta.Name);
		
	EndIf;
	
	Return Result;
EndFunction

// It determines whether versioning is used.
//
// Parameters:
//	Sender - ExchangePlanRef - determines whether object version creating is needed for the passed 
//		node if the parameter is passed.
//
Function VersioningUsed(Sender = Undefined, CheckAccessRights = False) Export
	
	Used = False;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Used = ?(Sender <> Undefined, IsSSLDataExchangeNode(Sender), True);
		
		If Used AND CheckAccessRights Then
			
			ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
			Used = ModuleObjectsVersioning.HasRightToReadObjectVersionInfo();
			
		EndIf;
			
	EndIf;
	
	Return Used;
	
EndFunction

// Returns the name of the temporary file directory.
//
// Returns:
//	String - a path to the temporary file directory.
//
Function TempFilesStorageDirectory(SafeMode = Undefined) Export
	
	// If the current infobase is running in file mode, the function returns TempFilesDir.
	If Common.FileInfobase() Then 
		Return TrimAll(TempFilesDir());
	EndIf;
	
	CommonPlatformType = "Windows";
	
	SetPrivilegedMode(True);
	
	If Common.IsWindowsServer() Then
		
		Result         = Constants.DataExchangeMessageDirectoryForWindows.Get();
		
	ElsIf Common.IsLinuxServer() Then
		
		Result         = Constants.DataExchangeMessageDirectoryForLinux.Get();
		CommonPlatformType = "Linux";
		
	Else
		
		Result         = Constants.DataExchangeMessageDirectoryForWindows.Get();
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	ConstantPresentation = ?(CommonPlatformType = "Linux", 
		Metadata.Constants.DataExchangeMessageDirectoryForLinux.Presentation(),
		Metadata.Constants.DataExchangeMessageDirectoryForWindows.Presentation());
	
	If IsBlankString(Result) Then
		
		Result = TrimAll(TempFilesDir());
		
	Else
		
		Result = TrimAll(Result);
		
		// Checking whether the directory exists.
		Directory = New File(Result);
		If Not Directory.Exist() Then
			
			MessageTemplate = NStr("ru = 'Каталог временных файлов не существует.
					|Необходимо убедиться, что в настройках программы задано правильное значение параметра
					|""%1"".'; 
					|en = 'The temporary file directory does not exist.
					|Please check the value of the ""%1"" parameter
					| in the application settings.'; 
					|pl = 'Katalog tymczasowych plików nie istnieje.
					|Należy upewnić się, że w ustawieniach programu jest podana prawidłowa wartość parametrów
					|""%1"".';
					|de = 'Es gibt kein Verzeichnis für temporäre Dateien.
					|Es ist darauf zu achten, dass in den Programmeinstellungen der richtige Wert des Parameters
					|""%1"" eingestellt ist.';
					|ro = 'Directorul temporar al fișierelor nu există.
					|Trebuie să vă asigurați că în setările aplicației este specificată valoarea corectă a parametrului
					|""%1"".';
					|tr = 'Geçici dosya dizini mevcut değil. 
					|Uygulama ayarlarında 
					| ""%1"" parametre değerinin doğru belirtildiğinden  emin olunmalıdır.'; 
					|es_ES = 'El catálogo de archivos temporales no existe.
					|Es necesario asegurarse de que en los ajustes del programa está establecido un valor correcto del parámetro
					|""%1"".'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ConstantPresentation);
			Raise(MessageText);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion