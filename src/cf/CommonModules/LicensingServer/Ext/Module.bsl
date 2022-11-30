

// Проверяет, удовлетворяет ли полное имя обработки требуемому формату, и если все в порядке,
// то имя разделяется на три части.
Function SplitDataProcessorName(VAL DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Export
	Point1 = 0;
	Point2 = 0;
	For IndexOf=1 To StrLen(DataProcessorName) Do
		Symbol = Mid(DataProcessorName, IndexOf, 1);
		If Symbol="." Then
			If Point2>0 Then
				// Обнаружена третья точка. Формат неверен
				Return False;
			EndIf;	
			If Point1=0 Then 
				Point1 = IndexOf;
			Else	
				Point2 = IndexOf;
			EndIf;
		EndIf;	
	EndDo;	
	If (Point1=0) OR (Point2=0) Then
		// Формат имени неверен
		Return False;
	EndIf;
	StorageTemplateName = Mid(DataProcessorName, 1, Point1-1);
	LicensingParametersTemplateName = Mid(DataProcessorName, Point1+1, Point2-Point1-1);
	DataProcessorShortName = Mid(DataProcessorName, Point2+1, StrLen(DataProcessorName)-Point2);
	Return True;
EndFunction

// Возвращает имя макета параметров лицензирования
Function GetLicensingParametersTemplateName(VAL DataProcessorName) Export
	// Проверка и разбор длинного имени
	StorageTemplateName = "";
	LicensingParametersTemplateName = "";
	DataProcessorShortName = "";
	If NOT SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
		Return Undefined;
	Else
		Return LicensingParametersTemplateName;
	EndIf;	
EndFunction

// Процедура выполняет проверку заполненности параметров лицензирования
Procedure CheckLicensingParameters(LicensingParametersTemplateName)
	SetPrivilegedMode(True);
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	Check = "";
	ActivationIsGiven = False;
	
	// проверка адреса сервера активации
	Value = TrimAll(ParametersTemplate.GetArea("URLActivationServer|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("URLActivationServer|Comment").CurrentArea.Text);
	Else
		ActivationIsGiven = ActivationIsGiven OR (Value<>NStr("ru = 'Не используется.'"));
	EndIf;
	
	// проверка кода вендора
	Value = TrimAll(ParametersTemplate.GetArea("VendorCode|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("VendorCode|Comment").CurrentArea.Text);
	EndIf;	
	
	// проверка серии аппаратных ключей
	Value = TrimAll(ParametersTemplate.GetArea("HardKeySeries|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("HardKeySeries|Comment").CurrentArea.Text);
	EndIf;	
	
	// проверка идентификатора продукта
	Value = TrimAll(ParametersTemplate.GetArea("ProductID|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("ProductID|Comment").CurrentArea.Text);
	EndIf;	
	
	// проверка требуемого вида лицензирования
	Value = TrimAll(ParametersTemplate.GetArea("LicenseKind|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("LicenseKind|Comment").CurrentArea.Text);
	EndIf;	
	
	// проверка адреса электронной почты центра лицензирования
	Value = TrimAll(ParametersTemplate.GetArea("Email|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("Email|Comment").CurrentArea.Text);
	Else
		ActivationIsGiven = ActivationIsGiven OR (Value<>NStr("ru = 'Не используется.'"));
	EndIf;
	
	// проверка телефона центра лицензирования
	Value = TrimAll(ParametersTemplate.GetArea("LicensingCenterPhone|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("LicensingCenterPhone|Comment").CurrentArea.Text);
	Else
		ActivationIsGiven = ActivationIsGiven OR (Value<>NStr("ru = 'Не используется.'"));
	EndIf;
	
	// проверка режима активации
	Value = TrimAll(ParametersTemplate.GetArea("ActivationMode|Value").CurrentArea.Text);
	If Value="" Then
		Check = Check +Chars.CR + Chars.LF + TrimAll(ParametersTemplate.GetArea("ActivationMode|Comment").CurrentArea.Text);
	ElsIf NOT (Value="0" OR Value="1") Then
		Check = Check + Chars.CR + Chars.LF + NStr("ru = 'Некорректно заполнен реквизит:'") + Chars.NBSp + TrimAll(ParametersTemplate.GetArea("ActivationMode|Comment").CurrentArea.Text);
	EndIf;
	
	If Check<>"" Then
		Check = NStr("ru = 'Не заполнены обязательные параметры лицензирования:'") + Chars.CR + Chars.LF + Check;
		Raise Check;
	EndIf;
	
	If NOT ActivationIsGiven Then
		Raise NStr("ru = 'Не указано ни одного способа активации ключей и лицензий.'");
	EndIf;	
EndProcedure

// Функция пытается создать защищенную обработку по имени
// Если операция завершилась неудачно, то будет вызвано
// исключение с описанием возникшей проблемы.
// ИмяОбработки - строка с именем защищенной обработки
// Маска - число. Сервер защиты будет искать ключ, чья битовая маска дополнительного
// параметра лицензирования будет совпадать или превышать переданную в этом параметре.
Function GetProtectedDataProcessor(VAL DataProcessorName, ErrorDescription="", ErrorCode=0) Export
	If IsBlankString(DataProcessorName) Then
		ErrorDescription = NStr("ru = 'Имя обработки не может быть пустым'");
		ErrorCode = 1;
		Return Undefined;
	EndIf; 
	
	// Проверка и разбор длинного имени
	StorageTemplateName = "";
	LicensingParametersTemplateName = "";
	DataProcessorShortName = "";
	If NOT SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
		ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'") + Chars.LF + DataProcessorName;
		ErrorCode = 1;
		Return Undefined;
	EndIf;	
	
	CheckLicensingParameters(LicensingParametersTemplateName);
	
	// Попытка создания защищенной обработки
	ProtectedDataProcessor =  LicensingCached.GetProtectedDataProcessor(DataProcessorName, ErrorDescription, ErrorCode);
	
	// Возможно значение "неопределено" уже закэшировано, поэтому попробуем переподключиться со сбросом кеша.
	If ProtectedDataProcessor = Undefined AND ErrorCode=0 Then
		RefreshReusableValues();
		ProtectedDataProcessor =  LicensingCached.GetProtectedDataProcessor(DataProcessorName, ErrorDescription, ErrorCode);
	EndIf;	
	
	// Первоначально обработка создается методом Старт
	// но в процессе работы, сеанс на сервере может завершиться
	// В этом случае попытка получения защищенной обработки
	// пройдет полный цикл, и может не создаться.
	
	If ProtectedDataProcessor = Undefined AND ErrorCode=0 Then
		If ErrorDescription <> "" Then
			// Ошибку выдадим только если есть описание
			// Возможна ситуация, когда мы уже "не получили" обработку
			// и значение "Неопределено" уже закэшировано повторным использованием.
			Raise(ErrorDescription);
		Else
			Raise NStr("ru = 'Система лицензирования не активирована.'; en = 'The licensing system is inactive.'");
		EndIf;
	EndIf;	
	
	Return ProtectedDataProcessor; 
	 
EndFunction	

// Функция пытается создать защищенную обработку по имени
// Если операция завершилась неудачно, то будет вызвано
// исключение с описанием возникшей проблемы.
// ИмяОбработки - строка с именем защищенной обработки
// Маска - число. Сервер защиты будет искать ключ, чья битовая маска дополнительного
// параметра лицензирования будет совпадать или превышать переданную в этом параметре.
Function GetProtectedDataProcessorExternalErrorControl(VAL DataProcessorName, ErrorDescription="", ErrorCode=0) Export
	If IsBlankString(DataProcessorName) Then
		ErrorDescription = NStr("ru = 'Имя обработки не может быть пустым'");
		ErrorCode = 1;
		Return Undefined;
	EndIf; 
	
	// Проверка и разбор длинного имени
	StorageTemplateName = "";
	LicensingParametersTemplateName = "";
	DataProcessorShortName = "";
	If NOT SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
		ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'") + Chars.LF + DataProcessorName;
		ErrorCode = 1;
		Return Undefined;
	EndIf;	
	
	CheckLicensingParameters(LicensingParametersTemplateName);
	
	// Попытка создания защищенной обработки
	ProtectedDataProcessor =  LicensingCached.GetProtectedDataProcessor(DataProcessorName, ErrorDescription, ErrorCode);
	
	// Возможно значение "неопределено" уже закэшировано, поэтому попробуем переподключиться со сбросом кеша.
	If ProtectedDataProcessor = Undefined AND ErrorCode=0 Then
		RefreshReusableValues();
		ProtectedDataProcessor =  LicensingCached.GetProtectedDataProcessor(DataProcessorName, ErrorDescription, ErrorCode);
		Return ProtectedDataProcessor;
	EndIf;	
	
	// Первоначально обработка создается методом Старт
	// но в процессе работы, сеанс на сервере может завершиться
	// В этом случае попытка получения защищенной обработки
	// пройдет полный цикл, и может не создаться.
	
	If ProtectedDataProcessor = Undefined AND ErrorCode=0 Then
 		// Не удалось создать защищенную обработку
		// вызовем исключение с описанием проблемы.
		ErrorCode = 1;
		If ErrorDescription = "" Then
			ErrorDescription = NStr("ru = 'Система лицензирования не активирована.'");
		EndIf;	
	EndIf;	
	
	Return ProtectedDataProcessor; 
	 
EndFunction

// Запуск системы защиты и создание экземпляра 
// защищенной обработки
// ИмяОбработки - строка с именем защищенной обработки
// Маска - число. Сервер защиты будет искать ключ, чья битовая маска дополнительного
// параметра лицензирования будет совпадать или превышать переданную в этом параметре
// ОписаниеОшибки - возвращаемый параметр, содержит описание результата операции.
Function LicensingSystemStart(DataProcessorName, ErrorDescription, ErrorCode) Export
	
	If IsBlankString(LicensingServerAddress()) Then
		// Первый запуск
	EndIf;
	
	Try	
		ProtectedDataProcessor = GetProtectedDataProcessorExternalErrorControl(DataProcessorName, ErrorDescription, ErrorCode);
	Except
		ErrorCode = 1;
		ErrorDescription = ErrorDescription();
		Return False;
	EndTry;
	
	Return NOT  ProtectedDataProcessor = Undefined;
	
EndFunction

// Завершает работу конфигурации с сервером лицензирования 
Function LicensingSystemFinish(ErrorDescription) Export
	
	// Если подключение к серверу лицензирования не было выполнено, то и не надо его завершать.
	For Each Item In GetIssuedCertificateList() Do	
		Try
			// Если подключение к серверу лицензирования не было выполнено, то и не надо его завершать.
			LicensingServer.GetProtectedDataProcessor(Item.Key).LicensingSystemFinish(ErrorDescription);
		Except
			// Если не удалось получить защищенную обработку, то и отключаться от сервера лицензирования не нужно.
			WriteLogEvent(NStr("ru = 'Не удалось получить защищенную обработку при завершении работы системы лицензирования'",BasicLanguageCode()), EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
   		EndTry;
	EndDo;
	SetIssuedCertificateList(New Map);
EndFunction

// Возвращает адрес сервера защиты из параметра сеанса, т.е. адрес сервера, к которому выполнено подключение
// Возвращаемое значение:
//   Строка   - адрес сервера защиты.
Function LicensingServerAddress() Export
	SetPrivilegedMode(True);
	Return SessionParameters.CurrentLicensingServerAddress;
EndFunction

// Возвращает адрес сервера защиты из константы
// Возвращаемое значение:
//   Строка   - адрес сервера защиты или список серверов.
Function LicensingServerAddressConstant() Export
	SetPrivilegedMode(True);
	Return Constants.LicensingServer.Get();
EndFunction

// Возвращает список адресов серверов лицензирования из строки
Function LicensingServerAddressList() Export
	SetPrivilegedMode(True);
	ListString = Constants.LicensingServer.Get();
	AddressList = ExpandStringIntoSubstringArray(ListString, ";");
	
	If AddressList.Count() = 0 Then
		AddressList.Add("");
	EndIf;
	Return AddressList;
EndFunction

// Функция "расщепляет" строку на подстроки, используя заданный
//      разделитель. Разделитель может иметь любую длину.
//      Если в качестве разделителя задан пробел, рядом стоящие пробелы
//      считаются одним разделителем, а ведущие и хвостовые пробелы параметра Стр
//      игнорируются.
//      Например,
//      РазложитьСтрокуВМассивПодстрок(",один,,,два", ",") возвратит массив значений из пяти элементов,
//      три из которых - пустые строки, а
//      РазложитьСтрокуВМассивПодстрок(" один   два", " ") возвратит массив значений из двух элементов.
//
//  Параметры:
//      Стр -           строка, которую необходимо разложить на подстроки.
//                      Параметр передается по значению.
//      Разделитель -   строка-разделитель, по умолчанию - запятая.
//
//  Возвращаемое значение:
//      массив значений, элементы которого - подстроки.
//
Function ExpandStringIntoSubstringList(VAL Str, Splitter = ",") Export
	
	StringList = New ValueList();
	If Splitter = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				StringList.Add(Str);
				Return StringList;
			EndIf;
			StringList.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SplitterLength = StrLen(Splitter);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				If (TrimAll(Str) <> "") Then
					StringList.Add(Str);
				EndIf;
				Return StringList;
			EndIf;
			StringList.Add(Left(Str,Pos - 1));
			Str = Mid(Str, Pos + SplitterLength);
		EndDo;
	EndIf;
	
EndFunction 

// Функция "расщепляет" строку на подстроки, используя заданный
//      разделитель. Разделитель может иметь любую длину.
//      Если в качестве разделителя задан пробел, рядом стоящие пробелы
//      считаются одним разделителем, а ведущие и хвостовые пробелы параметра Стр
//      игнорируются.
//      Например,
//      РазложитьСтрокуВМассивПодстрок(",один,,,два", ",") возвратит массив значений из пяти элементов,
//      три из которых - пустые строки, а
//      РазложитьСтрокуВМассивПодстрок(" один   два", " ") возвратит массив значений из двух элементов.
//
//  Параметры:
//      Стр -           строка, которую необходимо разложить на подстроки.
//                      Параметр передается по значению.
//      Разделитель -   строка-разделитель, по умолчанию - запятая.
//
//  Возвращаемое значение:
//      массив значений, элементы которого - подстроки.
//
Function ExpandStringIntoSubstringArray(VAL Str, Splitter = ",") Export
	
	StringArray = New Array();
	If Splitter = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				StringArray.Add(Str);
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SplitterLength = StrLen(Splitter);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				If (TrimAll(Str) <> "") Then
					StringArray.Add(Str);
				EndIf;
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str,Pos - 1));
			Str = Mid(Str, Pos + SplitterLength);
		EndDo;
	EndIf;
	
EndFunction 

// Возвращает адрес сервера защиты из параметра сеанса
// Возвращаемое значение:
//   Строка   - адрес сервера защиты.
Function LicensingServerAddressSessionParameter() Export
	SetPrivilegedMode(True);
	Return SessionParameters.LicensingServerAddress;
EndFunction

// Устанавливает значение адреса сервера защиты
Procedure SetLicensingServerAddressParameter(Address) Export
	SetPrivilegedMode(True);
	Constants.LicensingServer.Set(Address);
EndProcedure

// Возвращает код доступа ключа защиты из константы
Function ProtectionKeyAccessCode() Export
	SetPrivilegedMode(True);
	Return Constants.ProtectionKeyAccessCode.Get();
EndFunction

// Устанавливает код доступа ключа защиты
Procedure SetProtectionKeyAccessCode(AccessCode) Export
	SetPrivilegedMode(True);
	Constants.ProtectionKeyAccessCode.Set(TrimAll(AccessCode));
EndProcedure

// Возвращает идентификатор аппаратной привязки и описание оборудования для сервера, на котором установлен
//	сервер защиты.
//
// Параметры
//  Идентификатор  - Строка - Идентификатор аппаратной привязки
//  Описание       - Строка - описание оборудование
//  ОписаниеОшибки - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function GetEquipmentSignature(ID, Desription, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	
	ServerAddress = LicensingServerAddress();
	If NOT Component.ПолучитьИдентификаторАппаратнойПривязки(ServerAddress, ID, Desription) Then
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

// Возвращает идентификатор аппаратной привязки и описание оборудования для сервера, на котором установлен
//	сервер защиты.
//
// Параметры
//  АдресСервера   - Строка - адрес сервера лицензирования, сигнатуру которого требуется получить
//  Идентификатор  - Строка - Идентификатор аппаратной привязки
//  Описание       - Строка - описание оборудование
//  ОписаниеОшибки - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function GetSpecifiedServerEquipmentSignature(ServerAddress, ID, Desription, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	
	If NOT Component.ПолучитьИдентификаторАппаратнойПривязки(ServerAddress, ID, Desription) Then
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

// Проверяет корректность введенного пин-кода. 
// Возвращает Истину, если переданная строка является представлением пин кода, иначе Ложь.
Function IsPin(Pin, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);

	If Component = Undefined Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;
	
	Try
		Result = Component.ЭтоПинКод(Pin)
	Except
		ErrorDescription = NStr("ru = 'Произошла ошибка при выполнении метода компоненты ""IsPin()""'; en = 'An error occurred while performing the method of component ""IsPin()""'");
		Return Undefined;
	EndTry;
	
	Return Result;
EndFunction

// Проверяет корректность введенного длинного пин-кода
// Возвращает Истину, если переданная строка является представлением пин кода, иначе Ложь.
Function IsLongPin(LongPin, LicenseNumber, ShortPin, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);

	If Component = Undefined Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;
	
	Try
		Result = Component.ЭтоДлинныйПинКод(LongPin, LicenseNumber, ShortPin);
	Except
		ErrorDescription = NStr("ru = 'Произошла ошибка при выполнении метода компоненты ""IsLongPin()""'; en = 'An error occurred while performing the method of component ""IsLongPin()""'");
		Return Undefined;
	EndTry;
	
	Return Result;
EndFunction

// Проверяет корректность введенного длинного ключа пакета лицензий
// Возвращает Истину, если переданная строка является ключом пакета лицензий, иначе Ложь.
Function IsLicensePackageLongKey(LicensePackageLongKey, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);

	If Component = Undefined Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;
	
	Try
		Result = Component.ЭтоДлинныйКлючПакетаЛицензий(LicensePackageLongKey)
	Except
		ErrorDescription = NStr("ru = 'Произошла ошибка при выполнении метода компоненты ""IsLicensePackageLongKey()""'; en = 'An error occurred while performing the method of component ""IsLicensePackageLongKey()""'");
		Return Undefined;
	EndTry;
	
	Return Result;
EndFunction

// Функция принудительного отключения безопасного режима
// Возвращаемое значение - счетчик безопасного режима.
Function DisableSafeMode()
	SafeModeCounter=0;
	
	While SafeMode() Do
		SafeModeCounter=SafeModeCounter+1;
		Try
			SetSafeMode(False);
		Except
			WriteLogEvent(NStr("ru = 'При установке безопасного режима, вызовов метода с параметром Ложь сделано больше, чем вызовов с параметром Истина.'",BasicLanguageCode()), EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
   		EndTry; 
	EndDo; 
	
	Return SafeModeCounter;
EndFunction // ОтключитьБезопасныйРежим()

// Процедура восстановления безопасного режима
// СчБезопасногоРежима - счетчик безопасного режима.
Procedure EnableSafeMode(SafeModeCounter)
	Counter=0;
	While Counter<SafeModeCounter Do
		Counter=Counter+1;
		SetSafeMode(True);
	EndDo; 
EndProcedure // ВключитьБезопасныйРежим() 

Function GetComponentStoragePlace() Export
	SetPrivilegedMode(True);
	Return SessionParameters.ComponentStoragePlace;
EndFunction

// Подключает серверную компоненту защиты
//
// Параметры
//  ОписаниеОшибки  - Строка - описание ошибки.
//  
// Возвращаемое значение:
// Неопределено - если не удалось подключить компоненту.
Function AttachComponent(ErrorDescription) Export
	SafeModeCounter=DisableSafeMode();
	
	// Проверка ОС
	SysInfo = New SystemInfo; 
	If NOT (SysInfo.PlatformType = PlatformType.Windows_x86 OR SysInfo.PlatformType = PlatformType.Windows_x86_64 
		OR SysInfo.PlatformType = PlatformType.Linux_x86 OR SysInfo.PlatformType = PlatformType.Linux_x86_64) Then
		ErrorDescription = NStr("ru = 'Платформа, отличная от Windows и Linux, не поддерживается'; en = 'Platforms other than Windows and Linux is not supported'");
		Return Undefined;
	EndIf;

	
	// Подключаем компоненту защиты из макета компоненты защиты
	If AttachAddIn(GetComponentStoragePlace(), "Licence", AddInType.Native) Then
		// Создаем экземпляр объекта компоненты защиты.
		Component = New ("AddIn.Licence.CServer");
		EnableSafeMode(SafeModeCounter);
		Return Component;
	Else
		Definitions = "Licence" + Format(InfoBaseSessionNumber(), "NG=0");
		// Попробуем подключить компоненту под другим "средним" именем, так как есть подозрение, что платформа 1С
		// периодически начинает чудить. 
		If AttachAddIn(GetComponentStoragePlace(), Definitions, AddInType.Native) Then
			// Создаем экземпляр объекта компоненты защиты.
			Component = New ("AddIn."+Definitions+".CServer");
			EnableSafeMode(SafeModeCounter);
			Return Component;
		Else	
			// Не удалось подключить компоненту защиты. (Жаль причина нам не доступна)
			ErrorDescription = NStr("ru = 'Ошибка при подключении компоненты.'; en = 'Error while connecting component.'");
			Message = New UserMessage();
			Message.Text = ErrorDescription;
			Message.Message();
			LicensingServer.WriteErrorInEventLog(ErrorDescription);
			EnableSafeMode(SafeModeCounter);
			Return Undefined;
		EndIf;
	EndIf;
EndFunction

// Возвращает экземпляр компоненты лицензирования,
// который используется в защите.
Function ActiveComponent(ProductKey, ErrorDescription) Export
	Return LicensingCached.ActiveComponent(ProductKey, ErrorDescription);
EndFunction

// Кодирует строку в Base64
//
// Параметры
//  Текст  - Строка - исходный текст
//  КодированныйТекст  - Строка - текст Base64
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function CodeString(Text, CodedText, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	If Component.ЗакодироватьСтроку(Text, CodedText) Then
		Return True
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False
	EndIf;
	
EndFunction

// Кодирует строку в Base64. Используется в случае, если защита уже активирована 
// и можно получить компоненту из защищенной обработки.
//
// Параметры
//  Текст  - Строка - исходный текст
//  КодированныйТекст  - Строка - текст Base64
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function ComponentCodeString(Text, CodedText, DataProcessorName, ErrorDescription) Export
	Component = LicensingServer.GetProtectedDataProcessor(DataProcessorName, ErrorDescription).Компонента;
	
	If Component.ЗакодироватьСтроку(Text, CodedText) Then
		Return True
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False
	EndIf;
EndFunction

// Раскодирует строку из Base64
//
// Параметры
//  Текст  - Строка - текст Base64
//  РаскодированныйТекст  - Строка - раскодированный текст
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function ComponentDecodeString(Text, DecodedText, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	If Component.ДекодироватьСтроку(Text, DecodedText) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Получает ядро ключа защиты из ответа телефонной активации
//
// Параметры
//  ТекстОтвета  - Строка - многострочная строка ответа активации
//  ЯдроКлюча  - Строка - ядро ключа защиты
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function GetKeyKernelFromPhoneResponse(ResponseAnswer, KeyKernel, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	If Component.ПолучитьЯдроКлючаИзТелефонногоОтвета(ResponseAnswer, KeyKernel) Then
		Return True;
	Else             
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
EndFunction

// Получает код продукта из серийного номера
//
// Параметры
//  СерийныйНомер  - Строка - серийный номер продукта.
//
// Возвращаемое значение:
//   НомерПродукта   - Число - код продукта.
//
Function ProductNumberFromSerialNumber(SerialNumber) Export
	If StrLen(SerialNumber) = 13 Then
		ProductNumber = Number(Mid(SerialNumber,5,8));
	Else
		ProductNumber = Number(SerialNumber);
	EndIf;
	Return ProductNumber;
EndFunction

// Формирует XML для передачи в компоненту. Для активации ключа по телефону
// <Описание функции>.
//
// Параметры
//  ДанныеАктивации  - Структура - данные активации продукта.
//
// Возвращаемое значение:
//   Строка   - XML с данными активации программного продукта.
//
Function GenerateXML(LicensingParametersTemplateName, ActivationData) Export
	
	// XML
	ResponseXML = New XMLWriter;
	ResponseXML.SetString();
	ResponseXML.WriteXMLDeclaration();
	
	ResponseXML.WriteStartElement("sd");
	
	ResponseXML.WriteStartElement("activation");
	ResponseXML.WriteAttribute("pincode", ActivationData.PinRepresentation);
	ResponseXML.WriteAttribute("part1", ActivationData.KeyKernel);
	ResponseXML.WriteAttribute("part2", OpenKey(LicensingParametersTemplateName));
	ResponseXML.WriteAttribute("hidtext",ActivationData.EquipmentDescription);
	ResponseXML.WriteEndElement();
	
	ResponseXML.WriteStartElement("product");
	ResponseXML.WriteAttribute("id", ProductID(LicensingParametersTemplateName));
	ResponseXML.WriteAttribute("name", Metadata.BriefInformation);
	ResponseXML.WriteAttribute("sn", Format(ActivationData.KeyNumber,"NG="));
	ResponseXML.WriteAttribute("vendorid", VendorCode(LicensingParametersTemplateName));
	ResponseXML.WriteEndElement();
	
	ResponseXML.WriteStartElement("reginfo");
	ResponseXML.WriteAttribute("fio", ActivationData.Name);
	ResponseXML.WriteAttribute("company", ActivationData.Company);
	ResponseXML.WriteAttribute("phone", ActivationData.Phone);
	ResponseXML.WriteAttribute("email", ActivationData.Mail);
	ResponseXML.WriteAttribute("web", ActivationData.Site);
	ResponseXML.WriteAttribute("installer", ActivationData.Installer);
	ResponseXML.WriteEndElement();
	
	ResponseXML.WriteEndElement();
	
	ResponseString = ResponseXML.Close();
	Return ResponseString;
EndFunction

// Активирует программный ключ на текущем сервере лицензирования
//
// Параметры
//  Ответ  - Строка - ответ активации программного ключа
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function ActivateProgramKey(Response, ErrorDescription) Export
	Var DecodedText;
	
	Component = AttachComponent(ErrorDescription);
	
	If NOT Component.ДекодироватьСтроку(Response, DecodedText) Then
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
	
	ServerAddress = LicensingServerAddress();
	If Component.АктивироватьПрограммныйКлюч(ServerAddress, DecodedText) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
EndFunction

// Активирует программный ключ на указанном сервере лицензирования
//
// Параметры
//  Ответ  - Строка - ответ активации программного ключа
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function ActivateProgramKeyOnSpecifiedServer(ServerAddress, Response, ErrorDescription) Export
	Var DecodedText;
	
	Component = AttachComponent(ErrorDescription);
	
	If NOT Component.ДекодироватьСтроку(Response, DecodedText) Then
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
	
	If Component.АктивироватьПрограммныйКлюч(ServerAddress, DecodedText) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
EndFunction

// Получает все лицензионные ограничения ключа защиты, от которого получен сертификат.
//
// Параметры
// ПользователейЗаМесто	    Число	Допустимое количество уникальных подключений с типом лицензии за место
// ПользователейЗаСессию	Число	Допустимое количество уникальных подключений с типом лицензии за сессию
// Маска	                Число	Функциональная маска
// Счетчик1	                Число	Дополнительный счетчик 1
// Счетчик2	                Число	Дополнительный счетчик 2
// Счетчик3	                Число	Дополнительный счетчик 3
// ДатаОкончания	        Дата	Дата окончания работоспособности ключа защиты или 
//										0 - если ключ без ограничения по времени.
// ТипКлюча	Целое	        Число   Тип ключа защиты 1 - рабочий ключ,2 - демонстрационный ключ
// СерийныйНомер	        Число	Серийный номер ключа защиты
// АппаратныйНомер	        Число	Аппаратный номер ключа защиты
// ПинКод	                Строка	Пин-код активации ключа защиты
// НазваниеКлюча 			Строка	Название продукта, которое прописано в ключе.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function GetProtectionKeyParameters(DataProcessorName, TotalUsersForPlace, FreeUsersForPlace, TotalUsersForSession, FreeUsersForSession, Mask, Counter1, Counter2, Counter3, EndDate, KeyType, SerialNumber, HardwareNumber, Pin, KeyName, ErrorDescription ,ErrorCode) Export
	
	ProtectedDataProcessor = LicensingServer.GetProtectedDataProcessor(DataProcessorName, ErrorDescription, ErrorCode);
	Component = ProtectedDataProcessor.Компонента;
	
	If NOT Component.ПолучитьПараметрыКлючаЗащиты(TotalUsersForPlace, FreeUsersForPlace, TotalUsersForSession, FreeUsersForSession, Mask, Counter1, Counter2, Counter3, EndDate, KeyType, SerialNumber, HardwareNumber, Pin, KeyName) Then
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
	
	Return True;
EndFunction

// Устанавливает обновление ключа защиты
//
// Параметры
//  ТекстОбновления  - Строка - Содержимое обновления. Создается на стороне центра лицензирования
//  ОписаниеОшибки  - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function SetKeyUpdate(UpdateText, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	
	ServerAddress = LicensingServerAddress();
	
	If Component.УстановитьОбновлениеКлюча(ServerAddress, UpdateText) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
EndFunction

// Активирует программный ключ при активации по телефону
//
// Параметры
//  Ответ            - Строка - многострочная строка - ответ активации по телефону
//  ДанныеАктивации  - Структура - данные для активации программного ключа
//  ОписаниеОшибки   - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function ActivateKeyByPhone(LicensingParametersTemplateName, ServerAddress, Response, ActivationData, ErrorDescription) Export
	
	KeyKernel = "";
	If NOT LicensingServer.GetKeyKernelFromPhoneResponse(Response, KeyKernel, ErrorDescription) Then
		Return False;
	EndIf;
	
	ActivationData.Insert("KeyKernel", KeyKernel);
	
	If ActivationMode(LicensingParametersTemplateName) = 0 Then
		ActivationData.Insert("KeyNumber", ProductNumberFromSerialNumber(ActivationData.LicenseNumber));
	Else
		LicenseNumber = "";
		ShortPin = "";
		PinCheckResult = LicensingServer.IsLongPin(ActivationData.PinRepresentation, LicenseNumber, ShortPin, ErrorDescription);
		ActivationData.PinRepresentation = ShortPin;
		ActivationData.Insert("KeyNumber", ProductNumberFromSerialNumber(LicenseNumber));
	EndIf;
	
	StringXML = GenerateXML(LicensingParametersTemplateName, ActivationData);
	
	Component = AttachComponent(ErrorDescription);
	
	If Component = Undefined Then
		Return False;
	EndIf;
	
	If Component.АктивироватьПрограммныйКлюч(ServerAddress, StringXML) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;

EndFunction

// Активация ключа или лицензии через веб-сервис
// Тип активации. 0 - базовая поставка, 1 - лицензия
// <Описание функции>.
//
// Параметры
//  ТекстЗапроса  - Строка - запрос активации программного ключа в формате Base64
//  ТипАктивации  - Число - 0 - базовая поставка, 1 - лицензия
//  ОписаниеОшибки   - Строка - описание ошибки
// Возвращаемое значение:
//   Строка - ответ от центра лицензирования или Неопределено, если активация не успешна.
//
Function ActivateViaWebService(QueryText, ActivationType, LicensingParametersTemplateName, ErrorDescription) Export

	Proxy = LicensingServer.GetProxy(LicensingParametersTemplateName, ErrorDescription);
	
	If NOT Proxy = Undefined Then
		Result = Proxy.Activate(QueryText, ActivationType, ErrorDescription);
	Else
		Result = "";
	EndIf;
	
	Return Result;
EndFunction

// Создает текст запроса для активации по телефону
//
// Параметры
//   СерийныйНомер	        - Число  - Серийный номер базовой поставки
//   ИдентификаторПродукта	- Строка - Идентификатор продукта
//   ПинКод	                - Строка - Строковое представление пин-кода
//   ИдАппаратнойПривязки	- Строка - Идентификатор аппаратной привязки
//   Результат	            - Строка - Телефонный запрос активации
// Возвращаемое значение:
//   Булево                 - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function GetPhoneQuery(SerialNumber, ProductLineNumber, Pin, HardwareID, Result, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	If Component.ПолучитьТелефонныйЗапрос(SerialNumber, ProductLineNumber, Pin, HardwareID, Result) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;
EndFunction

// Проверяет корректность строки данных телефонной активации
Function CheckPhoneActivationDataString(DataString, ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	
	If Component = Undefined Then
		Return Undefined;
	EndIf;
	
	If Component.ПроверитьСтрокуДанных(DataString) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Выполняет поиск серверов лицензирования в сети
// Параметры
//  Идентификаторы    - Строка - идентификаторы ключей защиты. Если пустая строка, то возвращаются все доступные сервера
//  АсинхронныйРежим  - Булево - Истина - управление возвращается сразу. Параметр Результат не используется
//                               Ложь - метод дожидается окончания поиска и помещает результат в Результат
//  РезультатПоиска  - Строка - XML с найденными серверами и ключами защиты. (только при синхронном исполнении)
//  ОписаниеОшибки   - Строка - описание ошибки.
//
// Возвращаемое значение:
//   Булево   - результат выполнения функции: Истина - успешное выполнение, Ложь - ошибка выполнения.
//
Function FindLicensingServers(IDs, AsynchronousMode, SearchResult, ErrorDescription) Export
	SearchResult = "";
	
	Component = AttachComponent(ErrorDescription);
	
	If Component.ИскатьСервераЛицензирования(IDs, AsynchronousMode, SearchResult) Then
		Return True;
	Else
		ErrorDescription = Component.ОписаниеОшибки;
		Return False;
	EndIf;

EndFunction

// Получает список доступных серверов лицензирования
//
// Параметры
//  Идентификаторы   - Строка - идентификаторы ключей защиты
//  ОписаниеОшибки   - Строка - описание ошибки.
//
// Возвращаемое значение:
//   СписокЗначений   - список серверов лицензирования.
//
Function GetServerList(IDs, ErrorDescription) Export
	Var SearchResult;
	
	ServerList = New ValueList;
	If FindLicensingServers(IDs, False, SearchResult, ErrorDescription) Then
		ReaderXML = New XMLReader;
		ReaderXML.SetString(SearchResult);
		
		While ReaderXML.Read() Do
			If ReaderXML.NodeType=XMLNodeType.StartElement AND ReaderXML.Name="keys" Then
				ServerAddress = ReaderXML.GetAttribute("srv");
				ServerPort = ReaderXML.GetAttribute("port");
				ServerVersion = ReaderXML.GetAttribute("ver");
				If ServerVersion = Undefined Then
					Continue;
				EndIf;
				ConnectionString = ServerAddress + ":" + ServerPort;
				Presentation = ConnectionString + " Version: " + ServerVersion;
				ServerList.Add(ConnectionString,Presentation);
			EndIf;
		EndDo;
	EndIf;
	Return ServerList;
EndFunction

// Освобождает ранее взятый сертификат лицензирования
Function FreeLicense(DataProcessorName, ErrorDescription) Export
	Try
		Certificate = LicensingServer.GetCertificatesFromDataProcessorName(DataProcessorName);
		If NOT IsBlankString(Certificate) Then
			
			StorageTemplateName = "";
			LicensingParametersTemplateName = "";
			DataProcessorShortName = "";
			If NOT LicensingServer.SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
				ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + DataProcessorName;
				ErrorCode = 1;
				Return Undefined;
			EndIf;	
			ProductKey = StorageTemplateName+"."+LicensingParametersTemplateName;
			
			Component = LicensingServer.ActiveComponent(ProductKey, ErrorDescription);
			If ErrorDescription<>"" Then
				Return Undefined;
			EndIf;
			
			Component.ОсвободитьСертификат();
			LicensingServer.DeleteCertificate(Certificate);	
			
		EndIf;
	Except
		// Если не удалось получить защищенную обработку, то и отключаться от сервера лицензирования не нужно.
		WriteLogEvent(NStr("ru = 'Не удалось получить защищенную обработку при освобождении лицензии'",BasicLanguageCode()), EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
   	EndTry;
EndFunction

// Возвращает Истину, если локальная система защиты установлена, и Ложь, если локальной системы защиты нет.
//
Function LocalLicensingSystemEnabled(ErrorDescription) Export
	Component = AttachComponent(ErrorDescription);
	If Component = Undefined Then
		Return Undefined;
	EndIf;
	
	Try
		Result = Component.ЛокальнаяСистемаЛицензированияДоступна();
	Except
		Result = Undefined;
	EndTry;
	Return Result;
EndFunction

// Получает серию аппаратного ключа из макета параметров
Function HardKeySeries(LicensingParametersTemplateName)
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	HardKeySeries = ParametersTemplate.GetArea("HardKeySeries|Value").CurrentArea.Text;
	
	Return HardKeySeries;
EndFunction

// Получает список строк с идентификаторами доступа к ключам защиты.
// Идентификаторы определяют, от каких ключей может работать продукт.
//
// Возвращаемое значение:
//   Строка   - идентификаторы доступа к ключам защиты.
//
Function KeyIdentifiers(LicensingParametersTemplateName) Export
	Var OpenKey;
	Var HardKeySeries;
	
	TextIDs = "";
	Splitter = ":";
	
	OpenKey = OpenKey(LicensingParametersTemplateName);
	HardKeySeries = HardKeySeries(LicensingParametersTemplateName);
	
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	// основной идентификатор
	TextIDs = TextIDs + ProductID(LicensingParametersTemplateName) + Splitter + HardKeySeries + Splitter + OpenKey + Chars.CR + Chars.LF;
	// дополнительные идентификаторы
	AddIDe = AdditionalIDs(LicensingParametersTemplateName);
	For Each AdditionalID In AddIDe Do
		TextIDs = TextIDs + AdditionalID + Splitter + HardKeySeries + Splitter + OpenKey + Chars.CR + Chars.LF;
	EndDo;
	
	Return TextIDs;
EndFunction

// Получает идентификатор продукта
//
// Возвращаемое значение:
//   Строка   - идентификатор продукта.
//
Function ProductID(LicensingParametersTemplateName) Export

	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	ProductID = ParametersTemplate.GetArea("ProductID|Value").CurrentArea.Text;
	
	Return ProductID;
EndFunction

// Возвращает массив дополнительных идентификаторов (идентификаторы ключей, от которых может работать данное решение).
//
// Возвращаемое значение:
//   Массив   -  массив идентификаторов.
//
Function AdditionalIDs(LicensingParametersTemplateName) Export
	IDArray = New Array;
	
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	AdditionalIDs = ParametersTemplate.GetArea("AdditionalIDs|Value").CurrentArea.Text;
	
	For IndexOf = 1 To StrLineCount(AdditionalIDs) Do
		Str = StrGetLine(AdditionalIDs,IndexOf);
		If Str<>"" Then 
			IDArray.Add(Str);
		EndIf;
	EndDo;
	
	Return IDArray;
EndFunction

// Получает открытый RSA ключ из макета идентификаторов
//
// Возвращаемое значение:
//   Строка   - открытый ключ
//
Function OpenKey(LicensingParametersTemplateName)Export
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	OpenKey = ParametersTemplate.GetArea("OpenKey|Value").CurrentArea.Text;
	Return OpenKey;
EndFunction

// Получает код вендора из макета идентификаторов
//
// Возвращаемое значение:
//   Строка - код вендора
//
Function VendorCode(LicensingParametersTemplateName)Export
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	VendorCode = ParametersTemplate.GetArea("VendorCode|Value").CurrentArea.Text;
	Return VendorCode;
EndFunction

// Возвращает URL сервиса активации
Function URLActivationServer(LicensingParametersTemplateName)
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	URL = ParametersTemplate.GetArea("URLActivationServer|Value").CurrentArea.Text;
	If NOT Right(URL,1) = "/" Then
		URL = URL + "/";
	EndIf;
	Return URL;
EndFunction

// Возвращает адрес электронной почты, на который следует отправить запрос активации ключа или лицензии при активации
// через файл.
Function EmailForActivation(LicensingParametersTemplateName) Export
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	Address = ParametersTemplate.GetArea("Email|Value").CurrentArea.Text;
	Return Address;
EndFunction

// Возвращает номер телефона, по которому производится активация ключа защиты в случае активации по телефону.
Function LicensingCenterPhone(LicensingParametersTemplateName) Export
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	Phone = ParametersTemplate.GetArea("LicensingCenterPhone|Value").CurrentArea.Text;
	Return Phone;
EndFunction

// Возвращает значение режима активации программного продукта
Function ActivationMode(LicensingParametersTemplateName) Export
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	ActivationMode = Number(ParametersTemplate.GetArea("ActivationMode|Value").CurrentArea.Text);
	Return ActivationMode;
EndFunction

// Возвращает Истина, если разрешена активация через интернет
//
Function ActivationViaWebServiceIsAllowed(LicensingParametersTemplateName) Export
	If Upper(URLActivationServer(LicensingParametersTemplateName)) = "NOT IsUsed" Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

// Возвращает Истина, если разрешена активация по почте
//
Function ActivationViaEmailIsAllowed(LicensingParametersTemplateName) Export
	If Upper(EmailForActivation(LicensingParametersTemplateName)) = "NOT IsUsed" Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

// Возвращает Истина, если разрешена активация по телефону
//
Function ActivationViaPhoneIsAllowed(LicensingParametersTemplateName) Export
	If Upper(LicensingCenterPhone(LicensingParametersTemplateName)) = "NOT IsUsed" Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

// Возвращает прокси веб-сервиса
// Возвращаемое значение
// Прокси веб-сервиса
// 		WSПрокси
//
Function GetProxy(LicensingParametersTemplateName, ErrorDescription) Export
	
	LocationWSDL = URLActivationServer(LicensingParametersTemplateName) + "ws/Activation?wsdl";
	UserName = "Activator";
	Password = "";
	
	Try
		Definitions = New WSОпределения(
		LocationWSDL, 
		UserName,
		Password,,7);
	Except
		ErrorDescription = NStr("ru = 'Ошибка подключения к веб-сервису активации. Описание ошибки:'; en = 'Error connecting to the activation service. Error description:'") + Chars.NBSp + ErrorDescription();
		Return Undefined;
	EndTry;
	
	Proxy = New WSProxy(
		Definitions,
		"http://www.rarus.ru/activation",
		"Activation",
		"ActivationSoap",,20);
		
	Proxy.User = UserName;
	Proxy.Password = Password;
	
	Return Proxy;
	
EndFunction	

// Возвращает ключ клиентской ссылки, для детальной идентификации клиентского компьютера
// ОписаниеОшибки - содержит причину проблемы, если функция вернула Неопределено.
Function GetClientRefKey(ProductKey, ErrorDescription) Export;
	Return LicensingCached.GetClientRefKey(ProductKey, ErrorDescription);
EndFunction	

// Устанавливает ссылку на клиентский компьютер
// ОписаниеОшибки - содержит причину проблемы, если функция вернула Неопределено.
Function SetClientRef(ProductKey, Ref, ErrorDescription) Export;
	Return LicensingCached.SetClientRef(ProductKey, Ref, ErrorDescription);
EndFunction

Function LisensingControl(ProductKey, ErrorDescription) Export;
	Return LicensingCached.LisensingControl(ProductKey, ErrorDescription);
EndFunction	

// Методы работы со списком выданных сертификатов

// Получить список выданных сертификатов
Function GetIssuedCertificateList() 
	SetPrivilegedMode(True);
	ListStorage = SessionParameters.CertificateList;
	StrList = ListStorage.Get();
	If StrList<>Undefined Then
		Return StrList;
	Else
		Return New Map;
	EndIf	
EndFunction	

// Запомнить список выданных сертификатов
Procedure SetIssuedCertificateList(VAL List) Export
	SetPrivilegedMode(True);
	ListStorage = New ValueStorage(List);
	SessionParameters.CertificateList = ListStorage;
EndProcedure

// Возвращает идентификатор выданного для обработки сертификата, или неопределено,
// если для указанной обработки не выдавался сертификат.
Function GetCertificatesFromDataProcessorName(VAL DataProcessorName) Export
	List = GetIssuedCertificateList();
	Certificate = List.Get(DataProcessorName);
	If NOT ValueIsFilled(Certificate) Then
		Certificate = "";
	EndIf;
	Return Certificate;
EndFunction	

// Сохраняет выданный сертификат для указанной обработки
Procedure AddCertificate(DataProcessorName, CertificateID) Export
	List = GetIssuedCertificateList();
	If GetCertificatesFromDataProcessorName(DataProcessorName)="" Then
		List.Insert(DataProcessorName, CertificateID);
		SetIssuedCertificateList(List);
	EndIf;
EndProcedure

// Удаляет соответствие выданного сертификата созданной обработке
Procedure DeleteCertificate(CertificateID) Export
	List = GetIssuedCertificateList();
	For Each Item In List Do
		If Item.Value = CertificateID Then
			List.Delete(Item.Key);
		EndIf
	EndDo;
	SetIssuedCertificateList(List);
EndProcedure

// Методы работы со списком серверов

// Возвращает адрес сервера защиты из параметра сеанса
// Возвращаемое значение:
//   Строка   - адрес сервера защиты.
Function SetSessionParameterLicensingServerCurrentAddress(ServerCurrentAddress) Export
	SetPrivilegedMode(True);
	SessionParameters.CurrentLicensingServerAddress = ServerCurrentAddress;
EndFunction

// Возвращает адрес сервера защиты из параметра сеанса
// Возвращаемое значение:
//   Строка   - адрес сервера защиты.
Function SessionParameterLicensingServerCurrentAddress() Export
	SetPrivilegedMode(True);
	Return SessionParameters.CurrentLicensingServerAddress;
EndFunction

Function IsErrorConnectionWithServer(ErrorsArray) Export
	For Each Item In ErrorsArray Do
		If Item.ErrorCode = 10000 OR Item.ErrorCode = 10034 Then // 10000 - не найден сервер, 10034 - не найден ключ
			Return True;
		EndIf;	
	EndDo;
	
	Return False;
EndFunction

Procedure WriteErrorInEventLog(ErrorContent) Export
	WriteLogEvent(NStr("ru = 'Ошибка лицензирования'; en = 'licensing error'",BasicLanguageCode()), EventLogLevel.Error,,, ErrorContent);
EndProcedure

// Возвращает код основного языка конфигурации, например "ru".
Function BasicLanguageCode()
	#If NOT ThinClient AND NOT WebClient And Not MobileClient Then
		Return Metadata.DefaultLanguage.LanguageCode;
	#Else
		Return StandardSubsystemsClient.ClientParameter("DefaultLanguageCode");
	#EndIf
EndFunction //КодОсновногоЯзыка()

// Методы работы с параметрами сеанса

Procedure SetSessionParameters(SessionParametersNames=Undefined) Export
	
	SetPrivilegedMode(True);
	
	If SessionParametersNames = Undefined Then  // установка при запуске
		
		SessionParameters.CurrentLicensingServerAddress = "";
		SessionParameters.LicensingServerAddress        = "";
		SessionParameters.CertificateList                = New ValueStorage(New Map);
		SessionParameters.ComponentStoragePlace           = "CommonTemplate.ProtectionComponents";
		DetermineConponentSavingPlace();
		DetermineUnsafeOperationProtectionMode();
		
	Else // установка по обращению
		
		If SessionParametersNames.Find("CurrentLicensingServerAddress") <> Undefined Then
			SessionParameters.CurrentLicensingServerAddress = "";
		EndIf;
		
		If SessionParametersNames.Find("LicensingServerAddress") <> Undefined Then
			SessionParameters.LicensingServerAddress = "";
		EndIf;
		
		If SessionParametersNames.Find("CertificateList") <> Undefined Then
			SessionParameters.CertificateList = New ValueStorage(New Map);
		EndIf;
		
		If SessionParametersNames.Find("ComponentStoragePlace") <> Undefined Then
			SessionParameters.ComponentStoragePlace = "CommonTemplate.ProtectionComponents";
			DetermineConponentSavingPlace();
		EndIf;
		
		If SessionParametersNames.Find("UnsafeOperationProtectionIsOn") <> Undefined Then
			DetermineUnsafeOperationProtectionMode();
		EndIf;
		
	EndIf;
	
EndProcedure // УстановитьПараметрыСеанса()

// Процедура проверяет использование режима защиты от опасных действий
Procedure DetermineUnsafeOperationProtectionMode()
	
	// Получим параметры работы текущего пользователя
	UserParameters = New Structure("UnsafeOperationProtection", Undefined);
	FillPropertyValues(UserParameters, InfoBaseUsers.CurrentUser());
	
	// Обработаем в зависимости от полученных параметров пользователя
	SessionParameters.UnsafeOperationProtectionIsOn = ?(UserParameters.UnsafeOperationProtection=Undefined OR NOT UserParameters.UnsafeOperationProtection.UnsafeOperationWarnings, 0, 1);
	
	// Нет возможности определить, что защита отключена при помощи параметра DisableUnsafeActionProtection в файле conf.cfg
	// (по большей части, актуально для файловых баз).
	
EndProcedure // ОпределитьРежимЗащитыОтОпасныхДействий()

// Архив с компонентами защиты может располагаться в двух местах
// 1. В общем макете КомпонентыЗащиты
// 2. В файле rarusaddin.zip в каталоге rarus_protect, который должен находиться в папке 1cV8 или
//	1cV82 установленной платформы.
//
// Пример каталог программы C:\Program Files (x86)\1cv82\8.2.19.68\bin\
// значит rarusaddin.zip должен располагаться в C:\Program Files (x86)\1cv82\rarus_protect.
//
// Пример для Linux (Ubuntu 64). Каталог программы /opt/1C/v8.3/x86_64/
// значит rarusaddin.zip должен располагаться в /opt/1C/rarus_protect/.
//
Procedure DetermineConponentSavingPlace()
	
	FullPath = BinDir();
	TotalLength = StrLen(FullPath);
	If Find(FullPath, "\") > 0 Then
		// Похоже на Windows
		Splitter = "\";
	ElsIf Find(FullPath, "/") > 0 Then
		// Похоже на  Linux
		Splitter = "/";
	Else
		// Неведома ОС
		Return;
	EndIf;
	
	FoundPosition =  0;
	SplittersFound = 0;
	// Найдем третий разделитель  с конца
	For Ind = 0 To (TotalLength - 1) Do
		Position = TotalLength - Ind;
		Symbol  = Mid(FullPath, Position, 1);
		If (Symbol = Splitter) 
			OR (Ind = 0) Then // Путь у 1С не всегда заканчивается на слеш
			SplittersFound = SplittersFound + 1;
		EndIf;
		
		If SplittersFound = 3 Then
			FoundPosition = Position;
			Break;
		EndIf;
		
	EndDo;
	
	If FoundPosition > 0 Then
		Result = Left(FullPath, FoundPosition);
	Else
		Result = FullPath;
	EndIf;
	
	Result = Result+ "rarus_protect" + Splitter + "rarusaddin.zip";
	
	ComponentFile = New File(Result);
	If ComponentFile.Exist() Then  // Синхронный вызов выполняется на сервере
  		DATE = PutToTempStorage(New BinaryData(Result), New UUID);
		SessionParameters.ComponentStoragePlace = DATE;
	EndIf;	
	
EndProcedure

Procedure DetermineConponentSavingPlaceEnd(Exist, AdditionalParameters) Export
	
	Result = AdditionalParameters.Result;
	
	
	If Exist Then
		DATE = PutToTempStorage(New BinaryData(Result), New UUID);
		SessionParameters.ComponentStoragePlace = DATE;
	EndIf;

EndProcedure


// Завершение работы защиты происходит в момент завершения сеанса 1С, вне зависимости
// от чего произошло завершение сеанса (Закрыли клиента, Таймаут  и т.д.).







