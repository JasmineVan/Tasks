////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SolutionsList = LicensingSupport.GetProductList();
	SolutionCount = SolutionsList.Count();
	
	If SolutionCount > 1 Then // Несколько решений
		SelectedSolutionList = Items.SelectedSolution.ChoiceList;
		SolutionIndex = 0;
		For Each ListItem In SolutionsList Do
			SelectedSolutionList.Add(SolutionIndex, ListItem.Value);
			SolutionIndex = SolutionIndex + 1;
		EndDo;
	EndIf;
	
	SelectedSolution = 0;
	
	Settings = CommonSettingsStorage.Load("RegistrationInfo",,,"");
	If NOT Settings = Undefined Then
		For Each Setting In Settings Do
			Object[Setting.Key] = Setting.Value;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Function GetDataProcessorNameByIndex(IndexOf)
	SolutionsList = LicensingSupport.GetProductList();
	CurrIndex = 0;
	For Each ListItem In SolutionsList Do
		If CurrIndex = IndexOf Then
			Return ListItem.Key;
		Else
			CurrIndex = CurrIndex + 1;
		EndIf;
	EndDo;
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	Items.GroupPages.PagesRepresentation = FormPagesRepresentation.No;
	// отключение видимости всех страниц
	For Each CurPage In Items.GroupPages.ChildItems Do
		CurPage.Visible = False;
	EndDo;
	If SolutionCount = 1 Then
		Object.DataProcessorName = GetDataProcessorNameByIndex(0);
		PageNavigation(Items.PageActivationMethodSelection);
	Else
		PageNavigation(Items.PageSolutionSelection);
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	SaveSettings();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckingAttributes)
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	If ActivationMode = 0 Then // для НЕ совместных продуктов
		If StrLen(TrimAll(Object.LicensePackageRegistrationNumber)) < 13 Then
			Message = New UserMessage();
			Message.Text = NStr("ru = 'Некорректно указан регистрационный номер.
                                    |Номер должен содержать не менее 13 цифр'; en = 'Incorrectly specified registration number.
                                    |Number must be at least 13 digits'");
			Message.Field = "Object.LicenseNumber";
			Message.Message();
			LicensingServer.WriteErrorInEventLog(Message.Text);
			Cancel = True;
		EndIf;
	EndIf;
	
	If IsBlankString(StrReplace(Object.PackageLicensePassword,"-","")) Then
		Message = New UserMessage();
		Message.Text = NStr("ru = 'Не указан пароль пакета лицензий'; en = 'Password of license package is not specified'");
		Message.Field = "Object.PackageLicensePassword";
		Message.Message();
		LicensingServer.WriteErrorInEventLog(Message.Text);
		Cancel = True;
	Else
		If (ActivationMode = 0 AND StrLen(TrimAll(Object.PackageLicensePassword)) < 15) OR (ActivationMode = 1 AND StrLen(TrimAll(Object.PackageLicensePassword)) < 39) Then
			Message = New UserMessage();
			Message.Text = NStr("ru = 'Неверно указан пароль пакета лицензий'; en = 'Incorrect password of license package'");
			Message.Field = "Object.Pin";
			Message.Message();
			LicensingServer.WriteErrorInEventLog(Message.Text);
			Cancel = True;
		EndIf;
	EndIf;
EndProcedure

//////////////////////////////////////////////////////////
// КОМАНДЫ ФОРМЫ

&AtClient
Procedure CommandNext(Command)
	ActionProcessing("Next");
EndProcedure

&AtClient
Procedure CommandBack(Command)
	ActionProcessing("Back");
EndProcedure

// Активация пакета лицензий через интернет
&AtClient
Procedure CommandActivateWebService(Command)
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	CodedString = FormActivationRequest();
	If CodedString = Undefined Then
		Return;
	EndIf;
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	If LicensingParametersTemplateName = Undefined Then
		ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + Object.DataProcessorName;
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return;
	EndIf;	
	
	If ActivationMode = 0 Then
		ActivationResponse = LicensingServer.ActivateViaWebService(CodedString, 1, LicensingParametersTemplateName, ErrorDescription);
	Else
		ActivationResponse = LicensingServer.ActivateViaWebService(CodedString, 3, LicensingParametersTemplateName, ErrorDescription);
	EndIf;
		
	If ActivationResponse = "" Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	Else
		Result = LicensingServer.SetKeyUpdate(ActivationResponse, ErrorDescription);
		If NOT Result Then
			Message = New UserMessage();
			Message.Text = ErrorDescription;
			Message.Message();
			LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Else
			Close(NStr("ru = 'Пакет лицензий № '; en = 'License Pack №'") + Object.LicensePackageRegistrationNumber + Chars.NBSp + NStr("ru = 'активирован.'; en = 'activated.'"));
		EndIf;
	EndIf;
	
EndProcedure

// Активация пакета лицензий через файловый запрос
&AtClient
Procedure CommandActivateManually(Command)
		
	File = New File(Object.InternetActivationResponse);
	File.StartExistanceCheck(New NotifyDescription("CommandActivateManuallyEnd", ThisObject, New Structure("File", File)));
    	
EndProcedure

&AtClient
Procedure CommandActivateManuallyEnd(Exist, AdditionalParameters) Export
	
	File = AdditionalParameters.File;
	
	
	If NOT Exist Then
		MessageString = NStr("ru = 'Указанный файл не существует'; en = 'The specified file does not exist'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
		Return;
	EndIf;
	ReadStream = New TextDocument();
	ReadStream.BeginReading(New NotifyDescription("CommandActivateManuallyEndEnd", ThisObject, New Structure("ReadStream", ReadStream)), Object.InternetActivationResponse,TextEncoding.ANSI);

EndProcedure

&AtClient
Procedure CommandActivateManuallyEndEnd(AdditionalParameters1) Export
	
	ReadStream = AdditionalParameters1.ReadStream;
	
	
	ResponseAnswer = ReadStream.GetText();
	
	Result = LicensingServer.SetKeyUpdate(ResponseAnswer, ErrorDescription);
	If NOT Result Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	Else
		Close(NStr("ru = 'Пакет лицензий № '; en = 'License Pack №'") + Object.LicensePackageRegistrationNumber + Chars.NBSp + NStr("ru = 'активирован.'; en = 'activated.'"));
	EndIf;

EndProcedure

&AtClient
Procedure CommandSaveRequestFile(Command)
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	CodedString = FormActivationRequest();
	If CodedString = Undefined Then
		Return;
	EndIf;

	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Title = NStr("ru = 'Сохранить файл запроса активации как'; en = 'Save an activation request file as'");
	Dialog.Filter = NStr("ru = 'Files *.txt|*.txt'");
	
	If ActivationMode = 0 Then
		Dialog.FullFileName = "LAR" + Object.LicensePackageRegistrationNumber + ".txt";
	Else
		CodePart = StrReplace(Left(Object.PackageLicensePassword, 7),"-","");
		Dialog.FullFileName = "LAR" + CodePart + ".txt";
	EndIf;
	
	Dialog.Show(New NotifyDescription("CommandSaveRequestFileEnd", ThisObject, New Structure("Dialog, LicensingParametersTemplateName, CodedString", Dialog, LicensingParametersTemplateName, CodedString)));
EndProcedure

&AtClient
Procedure CommandSaveRequestFileEnd(SelectedFiles, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog;
	LicensingParametersTemplateName = AdditionalParameters.LicensingParametersTemplateName;
	CodedString = AdditionalParameters.CodedString;
	
	
	If (SelectedFiles <> Undefined) Then
		FileName = Dialog.FullFileName;
	Else
		Return;
	EndIf;
	
	File = New TextDocument();
	
	Try
		File.Write(FileName, TextEncoding.ANSI);
	Except
		MessageString = NStr("ru = 'Не удалось сохранить файл запроса'; en = 'Failed to save the file'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
	EndTry;
	
	File.SetText(CodedString);
	Try
		File.Write(FileName, TextEncoding.ANSI);
		FileWritten = True;
	Except
		MessageString = NStr("ru = 'Не удалось сохранить файл запроса'; en = 'Failed to save the file'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
	EndTry;
	If FileWritten Then
		Items.LabelFileName.Title = FileName;
		Items.LabelEmail.Title = LicensingServer.EmailForActivation(LicensingParametersTemplateName);
		
		PageNavigation(Items.PageActivationFileInstruction);
	EndIf;

EndProcedure

&AtClient
Function FormActivationRequest()
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	Result = GetKeyParameters(Object.DataProcessorName);
	
	If NOT Result Then
		Return False;
	EndIf;
	
	TextXML = New XMLWriter;
	TextXML.SetString();
	
	TextXML.WriteXMLDeclaration();
	TextXML.WriteStartElement("sd");
	
	TextXML.WriteStartElement("Activation");
	
	If ActivationMode = 0 Then
		TextXML.WriteAttribute("Type", "1");
		TextXML.WriteAttribute("PinCode", Object.Pin);
		TextXML.WriteAttribute("KeyNumber", Format(Object.KeyNumber,"NG="));
		TextXML.WriteAttribute("Regnumber", Object.LicensePackageRegistrationNumber);
		TextXML.WriteAttribute("Password", Object.PackageLicensePassword);
	Else
		TextXML.WriteAttribute("Type", "3");
		TextXML.WriteAttribute("PinCode", Object.Pin);
		TextXML.WriteAttribute("KeyNumber", Format(Object.KeyNumber,"NG="));
		TextXML.WriteAttribute("Regnumber", "");
		TextXML.WriteAttribute("Password", Object.PackageLicensePassword);
	EndIf;

	TextXML.WriteEndElement();
	
	TextXML.WriteStartElement("RegInfo");
	
	TextXML.WriteAttribute("Responsible", Object.Responsible);
	TextXML.WriteAttribute("Organization", Object.Company);
	TextXML.WriteAttribute("Phone", Object.Phone);
	TextXML.WriteAttribute("email", Object.Email);
	TextXML.WriteAttribute("web", Object.Site);
	TextXML.WriteAttribute("installer", Object.Installer);
	TextXML.WriteAttribute("tin", Object.TIN);
	
	TextXML.WriteEndElement();
	TextXML.WriteEndElement();
	
	ActivationString = TextXML.Close();
		
    CodedString = "";
	ErrorDescription="";
	
	If NOT LicensingServer.ComponentCodeString(ActivationString, CodedString, Object.DataProcessorName, ErrorDescription) Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;

	Return CodedString;
EndFunction

// Получение параметров ключа защиты
&AtClient
Function GetKeyParameters(DataProcessorName)
	Var TotalUsersForPlace, FreeUsersForPlace, TotalUsersForSession, FreeUsersForSession, Mask, Counter1, Counter2, Counter3, EndDate, KeyType, SerialNumber, HardwareNumber, Pin, KeyName;
	
	Result = LicensingServer.GetProtectionKeyParameters(DataProcessorName, TotalUsersForPlace, FreeUsersForPlace, TotalUsersForSession, FreeUsersForSession,
	                                                              Mask, Counter1, Counter2, Counter3, EndDate, KeyType, SerialNumber, HardwareNumber, Pin, KeyName, ErrorDescription, ErrorCode);
	If NOT Result Then
		Return False;
	Else
		Object.KeyNumber = SerialNumber;
		Object.FactoryKeyNumber = HardwareNumber;
		Object.Pin = Pin; // пин-код, которым был активирован ключ защиты
		Return True;
	EndIf;
EndFunction

&AtClient
Procedure ActionProcessing(Action)
	Pages = Items.GroupPages.ChildItems;
	CurrentPage = Items.GroupPages.CurrentPage;
	
	If CurrentPage = Pages.PageActivationMethodSelection Then
		If Object.ActivationMethod = 0 Then //веб сервис
			PageNavigation(Pages.PagePersonalData);
		Else
			// Вручную
			PageNavigation(Pages.PageRequestResponse);
		EndIf;
		
	ElsIf CurrentPage = Pages.PageSolutionSelection Then
		Object.DataProcessorName = GetDataProcessorNameByIndex(SelectedSolution);
		PageNavigation(Pages.PageActivationMethodSelection);
		
	ElsIf CurrentPage = Pages.PagePersonalData Then
		If Action = "Next" Then
			
			If NOT CheckFilling() Then
				Return;
			EndIf;
			
			If Object.ActivationMethod = 0 Then
				PageNavigation(Pages.PageActivationWebService);
				Items.CommandSaveRequestFile.Visible = False;
				Items.CommandActivateWebService.Visible = True;
			Else
				PageNavigation(Pages.PageActivationWebService);
				Items.CommandSaveRequestFile.Visible = True;
				Items.CommandActivateWebService.Visible = False;
			EndIf;
		Else // Назад
			PageNavigation(Pages.PageActivationMethodSelection);
		EndIf;
		
	ElsIf CurrentPage = Pages.PageRequestResponse Then
		If Action = "Next" Then
			If Object.RequestResponse = 0 Then
				PageNavigation(Pages.PagePersonalData);
			Else
				// Ответ активации
				PageNavigation(Pages.PageActivationResponse);
			EndIf;
		Else
			// Назад
			PageNavigation(Pages.PageActivationMethodSelection);
		EndIf;
	ElsIf CurrentPage = Pages.PageActivationWebService Then	
		If Action = "Back" Then
			PageNavigation(Pages.PagePersonalData);
		EndIf;
	ElsIf CurrentPage = Pages.PageActivationResponse Then
		If Action = "Back" Then
			If Object.ActivationMethod = 0 Then
				PageNavigation(Pages.PagePersonalData);
			Else
				If Object.RequestResponse = 0 Then
					PageNavigation(Pages.PagePersonalData); 
				Else
					PageNavigation(Pages.PageRequestResponse);
				EndIf;
			EndIf;
		EndIf;
	ElsIf CurrentPage = Pages.PageActivationFileInstruction Then
		If Action = "Next" Then
			PageNavigation(Pages.PageActivationResponse);
		Else
			PageNavigation(Pages.PageActivationWebService);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure PageNavigation(Page)
	Items.GroupPages.CurrentPage.Visible = False;
	Page.Visible = True;
	Items.GroupPages.CurrentPage = Page;
	
	CurrentPage = Items.GroupPages.CurrentPage;
	
	If (Page = Items.PageActivationMethodSelection AND SolutionCount = 1) OR Page = Items.PageSolutionSelection Then
		Items.FormCommandBar.ChildItems.FormCommandBack.Enabled = False;
	Else
		Items.FormCommandBar.ChildItems.FormCommandBack.Enabled = True;
	EndIf;
	
	If Page = Items.PageActivationMethodSelection Then
		ActivationMethodOnChange(Items.ActivationMethod);
	EndIf;
	
	If CurrentPage = Items.PageActivationWebService OR CurrentPage = Items.PageActivationResponse Then
		Items.FormCommandNext.Enabled = False;
	Else
		Items.FormCommandNext.Enabled = True;
	EndIf;
	
	If Page = Items.PagePersonalData Then
		LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
		ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
		
		If ActivationMode = 0 Then
			Items.PackageLicensePassword.Mask = "999-999-999-999";
			Items.LicenseNumber.Visible = True;
			Items.RegistrationNumberWebService.Visible = True;
		Else
			// совместные продукты
			Items.PackageLicensePassword.Mask = "999-999-999-999-999-999-999-999-999-999";
			Items.LicenseNumber.Visible = False;
			Items.RegistrationNumberWebService.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InternetActivationResponseStartChoice(Item, ChoiceData, StandardProcessing)
	AttachingConnected = Undefined;

	BeginAttachingFileSystemExtension(New NotifyDescription("AfterAttachingFileSystemExtension", ThisObject));
	
EndProcedure

&AtClient
Procedure AfterAttachingFileSystemExtension(Connected, AdditionalParameters) Export
	
	AttachingConnected = Connected;
	If AttachingConnected Then
		FileChoice = New FileDialog(FileDialogMode.Open);
		FileChoice.Multiselect = False;
		FileChoice.Title = NStr("ru = 'Выбор файла'; en = 'Select File'");
		FileChoice.Filter = NStr("ru = 'Текстовый документ(*.txt)|*.txt|Все файлы (*.*)|*.*'; en = 'Text document(*.txt)|*.txt|All files (*.*)|*.*'");
		FileChoice.FilterIndex = 0;
		FileChoice.Show(New NotifyDescription("ActivationResponseFileNameAfterChoice", ThisObject, New Structure("FileChoice", FileChoice)));
	Else
		ErrorDescription = NStr("ru = 'Ошибка открытия файла. Попробуйте открыть через тонкий или толстый клиент.'; en = 'Error opening file. Try opening through a thin or thick client.'");
	EndIf;

EndProcedure

&AtClient
Procedure ActivationResponseFileNameAfterChoice(SelectedFiles, AdditionalParameters) Export
	
	FileChoice = AdditionalParameters.FileChoice;
	
	
	Result = (SelectedFiles <> Undefined);
	FullFileName = FileChoice.FullFileName;
	
	If NOT Result Then
		Return;
	EndIf;
	
	Object.InternetActivationResponse = FullFileName;

EndProcedure

&AtServer
Procedure SaveSettings()
	SettingDescription = New SettingsDescription;
	SettingDescription.Presentation = NStr("ru = 'Регистрационная информация'; en = 'Registration Information'");
	SettingData = New Structure;
	SettingData.Insert("Company", Object.Company);
	SettingData.Insert("Responsible",Object.Responsible);
	SettingData.Insert("Phone",Object.Phone);
	SettingData.Insert("Email",Object.Email);
	SettingData.Insert("Site",Object.Site);
	SettingData.Insert("Installer", Object.Installer);
	SettingData.Insert("TIN", Object.TIN);
	CommonSettingsStorage.Save("RegistrationInfo",,SettingData,,"");
EndProcedure

&AtClient
Procedure ActivationMethodOnChange(Item)
	If Object.ActivationMethod = 0 Then
		Items.LabelActivationVariant.Title = "	" + NStr("ru = 'Онлайн-активация выполняется через интернет. 
		|Наиболее быстрый способ активации.'");
	Else
		Items.LabelActivationVariant.Title = "	" + NStr("ru = 'В этом способе работы программой создается файл запроса активации.
		|Этот файл каким-либо способом - например, по электронной почте или с курьером - передается в центр лицензирования.
		|На основании данного файла запроса в центре лицензирования создается файл активации лицензии, который передается обратно.
		|Этот файл активации следует загрузить в систему систему защиты. В результате этой загрузки новая лицензия будет активирована.'");
	EndIf;
EndProcedure



