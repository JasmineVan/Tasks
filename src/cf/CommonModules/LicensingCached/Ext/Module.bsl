

// Этот модуль должен обязательно иметь Повторное использование возвращаемых
// значений в положении "На время сеанса". За счет этого осуществляется кэширование
// значения защищенных обработок и загруженных экземпляров компоненты защиты 
// для каждого сеанса работы.

// Возвращает экземпляр компоненты лицензирования,
// который используется в защите.
Function ActiveComponent(ProductKey, ErrorDescription) Export
	SetPrivilegedMode(True);
	Return LicensingServer.AttachComponent(ErrorDescription);
EndFunction

Function AttachExternalDataProcessor(FileName, ErrorDescription = "", ErrorCode = 0) Export
	
	SetPrivilegedMode(True);
	
	// Обнуляем переменные описания ошибки
	ErrorDescription  = "";
	ErrorCode       = 0;
	MessageTemplate = NStr("ru = 'Работа системы лицензирования IN режиме Обычного приложения C файловой базой возможна только после отключения функции ""Protection от опасных действий"" IN параметрах пользователя 1C (Designer --> Administration --> Users). Подробнее, см. на сайте 1C Desription ошибки платформы #10170221.'; en = 'The work of the licensing system in the mode of a Ordinary application with a file database is possible only after disabling the function ""Unsafe action protection"" in the user settings 1C (Configurator -> Administration -> Users). For more details, see the 1C website for a description of the platform error #10170221.'");
	
	// Попытаемся подключить обработку в режиме отключения защиты от опасных действий
	If SessionParameters.UnsafeOperationProtectionIsOn=1 Then
		
		Try
			
			ProtectionParameters = New("UnsafeOperationProtectionDescription"+"");
			ProtectionParameters.UnsafeOperationWarnings = False;                                            
			
			Data = New BinaryData(FileName);
			StorageAddress = PutToTempStorage(Data, New UUID());
			
			DataProcessor = ExternalDataProcessors.Create(ExternalDataProcessors.Connect(StorageAddress,,False, ProtectionParameters), False);
			
		Except
			
			ErrorCause  = ErrorInfo();
			DataProcessor      = Undefined;
			
			If CurrentRunMode()=ClientRunMode.OrdinaryApplication AND Find(Upper(InfoBaseConnectionString()), "FILE=")>0 Then
				
				ErrorDescription = MessageTemplate;
				ErrorCode      = 10170221;
				
				// Получим параметры работы текущего пользователя
				UserParameters = New Structure("UnsafeOperationProtection", Undefined);
				FillPropertyValues(UserParameters, InfoBaseUsers.CurrentUser());
				
				// В версии платформы 8.3.10 исправлена ошибка Создания внешней обработки
				SessionParameters.UnsafeOperationProtectionIsOn = ?(UserParameters.UnsafeOperationProtection=Undefined, 2, 0);
				
			EndIf;
			
		EndTry;
		
	ElsIf SessionParameters.UnsafeOperationProtectionIsOn=2 Then
		ErrorDescription = MessageTemplate;
		ErrorCode      = 10170221;
		DataProcessor      = Undefined;
		
		// Нет возможности определить, что защита отключена при помощи параметра DisableUnsafeActionProtection в файле conf.cfg.
		
	Else
		
		// Производим подключение обработки по старинке
		DataProcessor = ExternalDataProcessors.Create(FileName, False);
		
	EndIf;
	
	// Возвращаем полученную обработку
	Return DataProcessor;
	
EndFunction // ПодключитьВнешнююОбработку()

// Функция создает и инициализирует обработку менеджера
// управления лицензированием. В течении сеанса обработка будет 
// закэширована.
// ОписаниеОшибки - возвращаемый параметр, содержит описание результата операции.
Function LisensingControl(ProductKey, ErrorDescription = "", ErrorCode = 0) Export;
	
	// Обнуляем переменные описания ошибки
	SetPrivilegedMode(True);
	ErrorDescription  = "";
	ErrorCode       = 0;
	
	Try
		Component = LicensingServer.ActiveComponent(ProductKey, ErrorDescription);
		If Component = Undefined Then
			Return Undefined;
		EndIf;
		Control = AttachExternalDataProcessor(Component.КонтрольЛицензирования(), ErrorDescription, ErrorCode);
		If ErrorCode=0 Then
			Control.ПодключитьКомпоненту(Component);
		EndIf;
	Except
		Control = Undefined;
		Error = ErrorDescription();
		If (Component<>Undefined) AND (Error="") Then
			Error = Component.ОписаниеПоследнейОшибки;
		EndIf;	
		ErrorDescription = NStr("ru = 'Error при инициализации компоненты лицензирования '; en = 'Error initializing licensing component'") + Error;

	EndTry;
	Return Control;
EndFunction	

// Функция получает ключ клиентской ссылки
//
Function GetClientRefKey(ProductKey, ErrorDescription = "") Export;
	SetPrivilegedMode(True);
	Control = LicensingServer.LisensingControl(ProductKey, ErrorDescription);
	If Control = Undefined Then
		Return Undefined;
	EndIf;
	Return Control.GetClientRef(ErrorDescription);
EndFunction	

// Функция устанавливает клиентскую ссылку
//
Function SetClientRef(ProductKey, Ref, ErrorDescription) Export;
	SetPrivilegedMode(True);
	ErrorDescription = "";
	Control = LicensingServer.LisensingControl(ProductKey, ErrorDescription);
	If Control = Undefined Then
		Return False;
	EndIf;
	Control.Ref = Ref;
	Return True;
EndFunction

// Функция создает и инициализирует защищенную обработку. В дальнейшем, в течении 
// сеанса, значение будет закэшировано, и вызов будет возвращать тот же
// экземпляр обработки
// ИмяОбработки - строка с именем защищенной обработки
// параметра лицензирования будет совпадать или превышать переданную в этом параметре
// ОписаниеОшибки - возвращаемый параметр, содержит описание результата операции.
Function GetProtectedDataProcessor(DataProcessorName, ErrorDescription = "", ErrorCode = 0)  Export
	Var SetSessionParameters, LicensingServerAddress, Certificate;
	
	// Проверка и разбор длинного имени
	StorageTemplateName = "";
	LicensingParametersTemplateName = "";
	DataProcessorShortName = "";
	If NOT LicensingServer.SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
		ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + DataProcessorName;
		ErrorCode = 1;
		Return Undefined;
	EndIf;	
	ProductKey = StorageTemplateName+"."+LicensingParametersTemplateName;
	
	SetSessionParameters = False;
	Control = LicensingServer.LisensingControl(ProductKey, ErrorDescription);
	If Control = Undefined Then
		Return Undefined;
	EndIf;
	Control.ПодключитьКомпоненту(LicensingServer.ActiveComponent(ProductKey, ErrorDescription));
	
	ParametersTemplate = GetCommonTemplate(LicensingParametersTemplateName);
	
	LicenseKind = Number(ParametersTemplate.GetArea("LicenseKind|Value").CurrentArea.Text);

	SetPrivilegedMode(True);
	
	Result = Control.ПолучитьЗащищеннуюОбработку(DataProcessorShortName, ErrorDescription, ErrorCode, LicenseKind, LicensingServer.ProtectionKeyAccessCode()
	, LicensingServer.KeyIdentifiers(LicensingParametersTemplateName), StorageTemplateName, LicensingServer.GetCertificatesFromDataProcessorName(DataProcessorName)
	, SessionParameters.LicensingServerAddress, LicensingServer.LicensingServerAddress()
	, SetSessionParameters, LicensingServerAddress, Certificate);
	
	If SetSessionParameters Then
		SessionParameters.LicensingServerAddress = LicensingServerAddress;
		LicensingServer.AddCertificate(DataProcessorName, Certificate);
	EndIf;
	
	Return Result;

EndFunction
