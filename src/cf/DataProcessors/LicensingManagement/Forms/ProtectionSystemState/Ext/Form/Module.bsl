
//////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	IsClientServerBase = NOT Find(InfoBaseConnectionString(), "File=");
	
	NamePart = StrReplace(ThisObject.FormName, ".", Chars.LF);
	
	DataProcessorObjectName = StrGetLine(NamePart, 1)+"."+StrGetLine(NamePart, 2);
	Result = "";
	ErrorDescription = "";
	
	If TypeOf(Parameters.LaunchResults)=Type("Array") Then
		LaunchResults = Parameters.LaunchResults;
	Else	
		LaunchResults = New Array;
		For Each Product In LicensingSupport.GetProductList() Do
			FormParameters = New Structure;
			FormParameters.Insert("ErrorDescription","");
			FormParameters.Insert("ErrorCode",0);
			FormParameters.Insert("ProgramFormOpening",True);
			FormParameters.Insert("DataProcessorName", Product.Key);
			FormParameters.Insert("ProductName", Product.Value);
			LaunchResults.Add(FormParameters);
		EndDo;
		
	EndIf;
	
	
	For Each LaunchResult In LaunchResults Do
		Result = LaunchResult.ErrorDescription;
		ErrorCode = LaunchResult.ErrorCode;
		
		If IsBlankString(Result) Then
			Try
				DataProcessor = LicensingServer.GetProtectedDataProcessor(LaunchResult.DataProcessorName, Result);
			Except
				Result = ErrorDescription();
			EndTry
		EndIf;
		
		If IsBlankString(Result) Then
			If DataProcessor.Компонента.ЗащитаАктивна() Then
				Result = "";
				Result = GenerateProtectionSystemStateDescription(Result);
			Else
				Items.CommandActivateLicensePackage.Enabled = False;
			EndIf;
		Else
			Items.CommandActivateLicensePackage.Enabled = False;
			Result = GenerateProtectionSystemStateDescription(Result);
		EndIf;
		If ErrorDescription<>"" Then
			ErrorDescription = ErrorDescription + Chars.LF+Chars.LF;	
		EndIf;	
			
		ErrorDescription = ErrorDescription + LaunchResult.ProductName + Chars.LF + Result;
	EndDo;
	
	If IsClientServerBase Then
		Items.CommandSetLicensingServer.Enabled = False;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////
// КОМАНДЫ ФОРМЫ

// Вызов мастера активации ключа защиты
&AtClient
Procedure CommandActivateKey(Command)
	
	Notification = New NotifyDescription("ProcessClosingOfKeyActivationForm", ThisObject);
	OpenForm(DataProcessorObjectName+".Form.ProtectionKeyActivationForm", , , , , , Notification);

EndProcedure

&AtClient
Procedure ProcessClosingOfKeyActivationForm(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ErrorDescription = Result;
	
	If ErrorDescription = "" Then
		// перезапуск защиты
		RefreshReusableValues();
		
		AttachIdleHandler("Timeout", 2, True);
		Error = False;
		ConnectToLicensingServer(Error);
		
	EndIf;
	
EndProcedure

// Перезапуск защиты
&AtClient
Procedure Reconnect(Command)
	
	ErrorDescription = "";
	
	// перезапуск защиты
	DisconnectFromLicensingServer();
	RefreshReusableValues();
	Error = False;
	ConnectToLicensingServer(Error);
	
	If NOT Error Then
		RefreshInterface();
		Close(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectToLicensingServer(Error=False)
	SolutionsList = LicensingSupport.GetProductList();
	LaunchResults = New Array;
	
	For Each Product In SolutionsList Do
		
		ErrorDescription = "";
		ErrorCode = 0;
		
		#If ThickClientOrdinaryApplication Then
			
			// Повторный запуск системы лицензирования в режиме обычного приложения не дает ошибки.
			SetPrivilegedMode(True);
			If SessionParameters.UnsafeOperationProtectionIsOn = 2 Then
				SessionParameters.UnsafeOperationProtectionIsOn = 0
			EndIf;
			
			// Проверка и разбор длинного имени
			DataProcessorName = Product.Key;
			StorageTemplateName = "";
			LicensingParametersTemplateName = "";
			DataProcessorShortName = "";
			If NOT LicensingServer.SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
				ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF+DataProcessorName;
				ErrorCode = 1;
				Return;
			EndIf;	
			ProductKey = StorageTemplateName + "." + LicensingParametersTemplateName;
			
			If NOT LicensingClient.DoClientBinding(ProductKey, ErrorDescription) Then
				ErrorDescription = GenerateProtectionSystemStateDescription(ErrorDescription);
				Return;
			EndIf;
			
		#EndIf
		
		ResultErrorDescription = "";
		LicensingServer.LicensingSystemStart(Product.Key, ResultErrorDescription, ErrorCode);
		If ResultErrorDescription<>"" Then
			Error = True;
		EndIf;
		FormParameters = New Structure;
		FormParameters.Insert("ErrorDescription",ResultErrorDescription);
		FormParameters.Insert("ErrorCode",ErrorCode);
		FormParameters.Insert("ProgramFormOpening",True);
		FormParameters.Insert("DataProcessorName", Product.Key);
		FormParameters.Insert("ProductName", Product.Value);
		LaunchResults.Add(FormParameters); 
		
	EndDo;
	
	For Each LaunchResult In LaunchResults Do
		Result = LaunchResult.ErrorDescription;
		ErrorCode = LaunchResult.ErrorCode;
		
		If IsBlankString(Result) Then
			Result = GenerateProtectionSystemStateDescription(Result);
		EndIf;
		
		If ErrorDescription<>"" Then
			ErrorDescription = ErrorDescription + Chars.LF+Chars.LF;	
		EndIf;	
		
		ErrorDescription = ErrorDescription + LaunchResult.ProductName + Chars.LF + Result;
	EndDo;
	
	ErrorDescription = GenerateProtectionSystemStateDescription(ErrorDescription);
	
EndProcedure

// Завершение работы
&AtClient
Procedure Shutdown(Command)
	
	Response = Undefined;

	
	ShowQueryBox(New NotifyDescription("ShutDownEnd", ThisForm), NStr("ru = 'Завершить работу системы?'; en = 'Shut down the system?'"), QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure ShutDownEnd(QueryResult, AdditionalParameters) Export
	
	Response = QueryResult;
	If Response = DialogReturnCode.OK Then
		
		If Parameters.ProgramFormOpening OR ThisForm.ModalMode Then
			Close(True);
		Else
			DisconnectFromLicensingServer();
			
			// Если необходимо завершить работу платформы, то следует 
			// Закомментировать:
			Close(True);
			// Раскомментировать:
			//ЗавершитьРаботуСистемы(Ложь);
		EndIf;
	EndIf;

EndProcedure

// Вызов мастера настройки сервера лицензирования
&AtClient
Procedure CommandConfigureServer(Command)
	
	Notification = New NotifyDescription("ProcessFormClosingOfProtectionServerSetting", ThisObject, New Structure("ProgramFormOpening", Parameters.ProgramFormOpening));
	OpenForm(DataProcessorObjectName+".Form.ProtectionServerSettingForm", , , , , , Notification);
	
EndProcedure

&AtClient
Procedure ProcessFormClosingOfProtectionServerSetting(Result, AdditionalParameters) Export
	If NOT Result = Undefined Then
		// были выполнены действия по настройке подключения к серверу
		ErrorDescription = Result;
		If ErrorDescription = "" Then
			// перезапуск защиты
			DisconnectFromLicensingServer();
			RefreshReusableValues();
			
			SolutionsList = LicensingSupport.GetProductList();
			LaunchResults = New Array;
			LaunchResultsByAllServers = New Array;
			Error = False;
			
			LicensingServersAddresses = LicensingServer.LicensingServerAddressList();
			
			ServerCount = LicensingServersAddresses.Count();
			Counter = 1;
			For Each ServerAddress In LicensingServersAddresses Do
				
				LicensingServer.SetSessionParameterLicensingServerCurrentAddress(ServerAddress);
				
				
				For Each Product In SolutionsList Do
					
					#If ThickClientOrdinaryApplication Then
						
						ErrorDescription = "";
						ErrorCode = 0;
						
						// Проверка и разбор длинного имени
						DataProcessorName = Product.Key;
						StorageTemplateName = "";
						LicensingParametersTemplateName = "";
						DataProcessorShortName = "";
						If NOT LicensingServer.SplitDataProcessorName(DataProcessorName, StorageTemplateName, LicensingParametersTemplateName, DataProcessorShortName) Then
							ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + DataProcessorName;
							ErrorCode = 1;
							Return;
						EndIf;	
						ProductKey = StorageTemplateName + "." + LicensingParametersTemplateName;
						
						If NOT LicensingClient.DoClientBinding(ProductKey, ErrorDescription) Then
							ErrorDescription = GenerateProtectionSystemStateDescription(ErrorDescription);
							Return;
						EndIf;
						
					#EndIf
					
					
					ResultErrorDescription = "";
					ErrorCode = 0;
					LicensingServer.LicensingSystemStart(Product.Key, ResultErrorDescription, ErrorCode);
					If ResultErrorDescription<>"" Then
						Error = True;
					EndIf;
					FormParameters = New Structure;
					FormParameters.Insert("ErrorDescription",ResultErrorDescription);
					FormParameters.Insert("ErrorCode",ErrorCode);
					FormParameters.Insert("ProgramFormOpening",True);
					FormParameters.Insert("DataProcessorName", Product.Key);
					FormParameters.Insert("ProductName", Product.Value);
					LaunchResults.Add(FormParameters); 
					
				EndDo;
				
				For Each LaunchResult In LaunchResults Do
					Result = LaunchResult.ErrorDescription;
					ErrorCode = LaunchResult.ErrorCode;
					
					If IsBlankString(Result) Then
						Result = GenerateProtectionSystemStateDescription(Result);
					EndIf;
					
					If ErrorDescription<>"" Then
						ErrorDescription = ErrorDescription + Chars.LF+Chars.LF;	
					EndIf;	
					
					ErrorDescription = ErrorDescription + LaunchResult.ProductName + Chars.LF + Result;
				EndDo;
				
				
				If LicensingServer.IsErrorConnectionWithServer(LaunchResults) AND Counter < ServerCount Then
					// Если ошибка соединения с сервером, на сервере не найден ключ и список серверов не исчерпан, то пробуем
					// подключиться к другому серверу.
					LaunchResults.Clear();
					Counter = Counter + 1;
					Continue;
				Else
					Break;
				EndIf;
				
			EndDo;
			
			If NOT Error AND Parameters.ProgramFormOpening Then
				RefreshInterface();
				Close(False);
			Else
				ErrorDescription = GenerateProtectionSystemStateDescription(ErrorDescription);
			EndIf;
		EndIf;
	EndIf;
EndProcedure


&AtClient
Procedure CommandActivateLicensePackage(Command)
	If Upper(LicensingServer.LicensingServerAddress()) = "*AUTO" Then
		
		ShowMessageBox(Undefined, NStr("ru = 'В режиме автоматического поиска сервера лицензирования невозможна активация лицензий.
		|Требуется явно указать сервер лицензирования.'; en = 'In license server automatic search mode can not activate the license.
		|Required to specify the license server.'"));
		
		Return;
	EndIf;
	
	Notification = New NotifyDescription("ProcessFormClosingOfLicensesActivation", ThisObject);
	OpenForm(DataProcessorObjectName+".Form.LicensesActivationForm", , , , , , Notification);
	
EndProcedure

&AtClient
Procedure ProcessFormClosingOfLicensesActivation(Result, AdditionalParameters) Export
	ErrorDescription = GenerateProtectionSystemStateDescription(Result);
EndProcedure

&AtClient
Procedure CommandSetLicensingServer(Command)
	
	#If NOT WebClient And Not MobileClient Then
		ShowQueryBox(New NotifyDescription("CommandSetLicensingServerEnd", ThisObject), NStr("ru = 'Сервер лицензирования конфигураций будет установлен на этом компьютере.
                          |Пользователь должен иметь права администратора компьютера.
                          |Установить?'; en = 'The license server is installed on this computer.
                          |The user must have administrator privileges computer.
                          |Start Installation?'"), QuestionDialogMode.YesNo);
	#Else
		  ShowMessageBox(Undefined, NStr("ru = 'В веб-клиенте недоступна установка сервера защиты'; en = 'In  web-client mode,  the License server installation is unavailable'"));
		  Return;
	#EndIf
	
EndProcedure

&AtClient
Procedure CommandSetLicensingServerEnd(QueryResult, AdditionalParameters) Export
	
	If QueryResult =  DialogReturnCode.Yes Then
		FileData = GetFileData();
		BeginGettingTempFilesDir(New NotifyDescription("CommandSetLicensingServerEndGettingTempFilesDir", ThisObject, New Structure("FileData", FileData)));
	EndIf;

EndProcedure

&AtClient
Procedure CommandSetLicensingServerEndGettingTempFilesDir(TempFilesDirName, AdditionalParameters) Export
	
	FileData = AdditionalParameters.FileData;
	
	DirName = TempFilesDirName;
	TempFileName = DirName + "setup.exe";
	
	FileData.BeginWrite(New NotifyDescription("CommandSetLicensingServerEndGettingTempFilesDirEnd", ThisObject, New Structure("TempFileName", TempFileName)), TempFileName);

EndProcedure

&AtClient
Procedure CommandSetLicensingServerEndGettingTempFilesDirEnd(AdditionalParameters1) Export
	
	TempFileName = AdditionalParameters1.TempFileName;
	
	FileWritten = True;
	
	ApplicationName = TempFileName;
	BeginRunningApplication(New NotifyDescription("ComandSetLicensingServerEndEnd", ThisObject), ApplicationName);

EndProcedure

// Процедура - Команда установить сервер лицензирования завершение завершение
// Необходима для возможности создать оповещение.
//
// Параметры:
//  КодВозврата				
//  ДополнительныеПараметры 
//
&AtClient
Procedure ComandSetLicensingServerEndEnd(ReturnCode, AdditionalParameters) Export
	
	Reserved = True;

EndProcedure

&AtClient
Procedure CommandInformation(Command)
	
	OpenForm(DataProcessorObjectName+".Form.LicensingParametersInfo", , ThisForm);
	
EndProcedure

/////////////////////////////////////////////////
// ОБЩИЕ ПРОЦЕДУРЫ И ФУНКЦИИ

&AtClientAtServerNoContext
Function GenerateProtectionSystemStateDescription(ErrorDescription)
	If IsBlankString(ErrorDescription) Then
		ErrorDescription = NStr("ru = 'Лицензия получена от сервера: ""'; en = 'License received from the server: ""'") + LicensingServer.LicensingServerAddressSessionParameter() + """";
	EndIf;
		
	Return "[" + CurrentDate() + "]: " + ErrorDescription;
EndFunction

&AtServer
Procedure DisconnectFromLicensingServer()
	ErrorDescription = "";
	
	SolutionsList = LicensingSupport.GetProductList();
	For Each Product In SolutionsList Do
		LicensingServer.FreeLicense(Product.Key, ErrorDescription);
	EndDo;

EndProcedure

&AtServerNoContext
Function GetFileData()
	BinaryData = GetCommonTemplate("LicensingServerSetup");
	Return BinaryData;
EndFunction

// Служебная функция. Зарезервировано.
&AtClient
Procedure Timeout()
	
	Reserved = True;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SysInfo = New SystemInfo;
	IsWindows = SysInfo.PlatformType = PlatformType.Windows_x86 OR SysInfo.PlatformType = PlatformType.Windows_x86_64;
	
	If NOT IsWindows Then
		Items.CommandSetLicensingServer.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure CommandSaveLicensingServerSetup(Command)
	#If NOT WebClient And Not MobileClient Then
		SetupDir = "";
		SaveDialog = New FileDialog(FileDialogMode.Save);
		SaveDialog.Filter = ".exe";
		SaveDialog.FullFileName = "setup.exe";
		SaveDialog.Title = NStr("ru = 'Выберите расположение дистрибутива сервера лицензирования'; en = 'Select the location of the license server distribution'");
		
		SaveDialog.Show(New NotifyDescription("CommandSaveLicensingServerSetupEnd", ThisObject, New Structure("SaveDialog", SaveDialog)));
	#Else
		ShowMessageBox(Undefined, NStr("ru = 'В веб-клиенте недоступно сохранение сервера лицензирования'; en = 'Saving a license server is not available in the Web client'"));
		Return;
	#EndIf
EndProcedure

&AtClient
Procedure CommandSaveLicensingServerSetupEnd(SelectedFiles, AdditionalParameters) Export
	
	SaveDialog = AdditionalParameters.SaveDialog;
	
	
	If (SelectedFiles <> Undefined) Then
		
		SetupDir = SaveDialog.FullFileName;
		
		FileData = GetFileData();
		FileData.BeginWrite(New NotifyDescription("CommandSaveLicensingServerSetupEndEnd", ThisObject, New Structure("SetupDir", SetupDir)), SetupDir);                            
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandSaveLicensingServerSetupEndEnd(Result) Export

	Reserved = True;

EndProcedure





