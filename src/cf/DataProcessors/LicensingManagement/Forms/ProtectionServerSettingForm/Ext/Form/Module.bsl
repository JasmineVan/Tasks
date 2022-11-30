//////////////////////////////////////////////////////////////
// СОБЫТИЯ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.ServerAddress = LicensingServer.LicensingServerAddressConstant();
	Object.ProtectionKeyAccessCode = LicensingServer.ProtectionKeyAccessCode();
	
	// проверка доступности локальной системы лицензирования
	Result = LicensingServer.LocalLicensingSystemEnabled(ErrorDescription);
	If Result = Undefined Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		// И считаем, что недоступна
		LocalLicensingSystemEnabled = False;
	Else
		LocalLicensingSystemEnabled = Result;
	EndIf;
	
	If NOT ValueIsFilled(Object.ServerAddress) OR Upper(Object.ServerAddress) = "*LOCAL" Then
		Object.StartMode = 0;
	ElsIf Upper(Object.ServerAddress) = "*AUTO" Then
		Object.StartMode = 1;
		Items.ProtectionKeyAccessCode.Enabled = False;
		Object.ProtectionKeyAccessCode = "";
	Else
		Object.StartMode = 2;
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SysInfo = New SystemInfo;
	IsWindows = SysInfo.PlatformType = PlatformType.Windows_x86 OR SysInfo.PlatformType = PlatformType.Windows_x86_64;

	Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	
	If IsWindows Then
		PageNavigation(Items.PageModeSelection);
		StartModeOnChange(Items.StartMode);
	Else
		PageNavigation(Items.PageSpecifyAddress);
	EndIf;
EndProcedure


/////////////////////////////////////////////////////////////
// КОМАНДЫ ФОРМЫ

&AtClient
Procedure CommandNext(Command)
	ActionProcessing("Next");
EndProcedure

&AtClient
Procedure CommandBack(Command)
	ActionProcessing("Back");
EndProcedure

&AtClient
Procedure CommandFindServers(Command)
	ServerList = LicensingServer.GetServerList("",ErrorDescription);
	SelectedItem = Undefined;

	ServerList.ShowChooseItem(New NotifyDescription("CommandFindServersEnd", ThisObject));
EndProcedure

&AtClient
Procedure CommandFindServersEnd(SekectedItem1, AdditionalParameters) Export
	
	SelectedItem = SekectedItem1;
	Object.ServerAddress = ?(SelectedItem = Undefined, Object.ServerAddress, SelectedItem.Value);

EndProcedure

// Обработка действия пользователя
&AtClient
Procedure ActionProcessing(Action)
	Pages = Items.GroupPages.ChildItems;
	CurrentPage = Items.GroupPages.CurrentPage;
	
	If CurrentPage = Pages.PageModeSelection Then
		If Object.StartMode = 0 Then //LOCAL
			
			If NOT LocalLicensingSystemEnabled Then
				ShowMessageBox(Undefined, NStr("ru = 'Недоступен сервер лицензирования на локальном компьютере.
                                     |Необходимо запустить или выполнить установку сервера лицензирования.'; en = 'The license server is not available on your computer.
                                     | You need to run or install the license server.'"));
				Return;
			EndIf;	
			Items.LabelServerChange.Title = NStr("ru = 'Будет выполнено подключение к локальному серверу лицензирования.'; en = 'It will connect to the local server licensing.'"); 
			Object.ServerAddress = "*LOCAL";	
			PageNavigation(Items.PageSpecifyAddress); // нужно указать код ключа										   
		
		ElsIf Object.StartMode = 1 Then //AUTO
		
			Items.LabelServerChange.Title = NStr("ru = 'Будет выполнен поиск сервера лицензирования в сети и подключение к найденному серверу'; en = 'It will search the license server on the network and connect to servers found'");
			Object.ServerAddress = "*AUTO";                                               
			PageNavigation(Items.PageWarning);												
		
		ElsIf Object.StartMode = 2 Then //Адрес
			
			Object.ServerAddress = LicensingServer.LicensingServerAddressConstant();
			PageNavigation(Pages.PageSpecifyAddress);
			
		EndIf;
			
	ElsIf CurrentPage = Pages.PageSpecifyAddress Then
		If Action = "Next" Then
			If IsBlankString(Object.ServerAddress) Then
				Message = New UserMessage();
				Message.Text = NStr("ru = 'Укажите адрес сервера лицензирования'; en = 'Specify the address of the license server'");
				Message.Message();				
				LicensingServer.WriteErrorInEventLog(ErrorDescription);
				Return;
			EndIf;
			
			Items.LabelServerChange.Title = NStr("ru = 'Будет выполнено подключение к серверу лицензирования ""'; en = 'It will connect to the license server ""'") + Object.ServerAddress + """ ";
															
			PageNavigation(Items.PageWarning);												
															
		Else //Назад
			PageNavigation(Pages.PageModeSelection);
		EndIf;
	ElsIf CurrentPage = Pages.PageWarning Then
		
		If Action = "Next" Then
			LicensingServer.SetLicensingServerAddressParameter(Object.ServerAddress);
			LicensingServer.SetProtectionKeyAccessCode(Object.ProtectionKeyAccessCode);
			Notify("LicensingServer",Object.ServerAddress);
			Close("");
		Else
			If Object.StartMode = 1 Then
				PageNavigation(Pages.PageModeSelection);
			Else
				PageNavigation(Pages.PageSpecifyAddress);
			EndIf;
		EndIf;
	Else
	EndIf;
		
EndProcedure

// Переход к странице формы
// Параметры
//   Страница - ГруппаФормы - страница, на которую будет осуществлен переход.
&AtClient
Procedure PageNavigation(Page)
	For Each CurPage In Items.GroupPages.ChildItems Do
		CurPage.Visible = False;
	EndDo;
	Page.Visible = True;
	Items.GroupPages.CurrentPage = Page;
	
	CurrentPage = Items.GroupPages.CurrentPage;
	If  CurrentPage = Items.PageModeSelection Then
		Items.FormCommandBack.Enabled = False;
	Else
		Items.FormCommandBack.Enabled = True;
	EndIf;
	
	If CurrentPage = Items.PageSpecifyAddress AND NOT IsWindows Then
		Items.FormCommandBack.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure ServerAddressStartChoice(Item, ChoiceData, StandardProcessing)
    ServerList = ServerList(ErrorDescription);
	SelectedItem = Undefined;
	
	ServerList.ShowChooseItem(New NotifyDescription("ServerAddressStartChoiceEnd", ThisObject), NStr("ru = 'Выберите сервер лицензирования'; en = 'Select the license server'"));
EndProcedure

&AtClient
Procedure ServerAddressStartChoiceEnd(SekectedItem1, AdditionalParameters) Export
	
	SelectedItem = SekectedItem1;
	Object.ServerAddress = ?(SelectedItem = Undefined, Object.ServerAddress, SelectedItem.Value);

EndProcedure

// Возвращает список серверов лицензирования, найденных в локальной сети  
&AtServerNoContext
Function ServerList(ErrorDescription)
	Return LicensingServer.GetServerList("", ErrorDescription);
EndFunction

&AtClient
Procedure StartModeOnChange(Item)
	If Object.StartMode = 0 Then
		Items.LabelStartMode.Title = NStr("ru = 'Этот вариант следует выбирать в случае работы в локальном режиме: то есть на одном рабочем месте, без использования сети. 
		|Если используетися аппаратный ключ защиты, то его следует подключать к этому компьютеру. 
		|Если же используется программный ключ защиты, то его следует активировать на данном компьютере.
		|(При использовании серверной базы данных сервер лицензирования должен быть установлен на одном компьютере с сервером 1С,
		|А при использовании нескольких серверов в кластере - на каждом сервере кластера.)'");
	ElsIf Object.StartMode = 2 Then
		Items.LabelStartMode.Title = NStr("ru = 'Этот вариант используется в сетевом режиме. 
		|Если он выбран, то следует указать сетевой адрес компьютера, на котором установлен сервер лицензирования.
		|По умолчанию сервер лицензирования устанавливается на сетевой порт 15200.'");
	Else
		Items.LabelStartMode.Title = NStr("ru = 'Этот вариант используется только при наличии в сети настроенных серверов лицензирования. 
		|При использовании данного варианта происходит автоматический поиск серверов лицензирования в сети.
		|В этом режиме невозможна активация программного ключа.'");
	EndIf;
	
	If Object.StartMode = 1 Then
		Object.ProtectionKeyAccessCode = "";
		Items.ProtectionKeyAccessCode.Visible = False;
	Else
		Items.ProtectionKeyAccessCode.Visible = True;
	EndIf;
	
	If Object.StartMode = 0 Then
		Items.ServerAddress.Visible = False;
		Items.LabelServerAddress.Visible = False;
	Else
		Items.ServerAddress.Visible = True;
		Items.LabelServerAddress.Visible = True;
	EndIf;
EndProcedure



