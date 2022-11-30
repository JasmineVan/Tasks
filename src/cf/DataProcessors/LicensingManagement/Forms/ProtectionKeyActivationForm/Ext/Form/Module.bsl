/////////////////////////////////////////////////////////////
// ОБРАБТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ServerAddress = LicensingServer.LicensingServerAddress();
    ServerCurrentAddress = ServerAddress;
	
	If NOT ValueIsFilled(ServerAddress) Then
		Object.StartMode = 0;
		Object.ServerAddress = "*LOCAL";
		Items.ServerAddress.Enabled = False;
	ElsIf Upper(ServerAddress) = "*LOCAL" OR Upper(ServerAddress) = "LOCALHOST" Then
		Object.StartMode = 0;
		Object.ServerAddress = ServerAddress;
		Items.ServerAddress.Enabled = False;
	ElsIf  Upper(ServerAddress) = "*AUTO" Then
		Object.StartMode = 1;
		Object.ServerAddress = "";
	Else
		Object.StartMode = 1;
		Object.ServerAddress = ServerAddress;
	EndIf;
	
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
	Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	PageNavigation(Items.PageServerSelection);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckingAttributes)
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);

	If IsBlankString(StrReplace(Object.Pin,"-","")) Then
		Message = New UserMessage();
		Message.Text = NStr("ru = 'Не указан пин-код'; en = 'PIN is not specified'");
		Message.Field = "Object.Pin";
		Message.Message();
		LicensingServer.WriteErrorInEventLog(Message.Text);
		Cancel = True;
	Else
		
		If (ActivationMode = 0 AND StrLen(TrimAll(Object.Pin)) < 7) OR (ActivationMode = 1 AND StrLen(TrimAll(Object.Pin)) < 23) Then
			Message = New UserMessage();
			Message.Text = NStr("ru = 'Неверно указан пин-код'; en = 'Incorrect PIN'");
			Message.Field = "Object.Pin";
			Message.Message();
			LicensingServer.WriteErrorInEventLog(Message.Text);
			Cancel = True;
		EndIf;

	EndIf;
	
	If ActivationMode = 0 Then //  Рег. номер нужен для НЕ совместных продуктов
		If IsBlankString(Object.LicenseNumber) Then
			Message = New UserMessage();
			Message.Text = NStr("ru = 'Не указан регистрационный номер'; en = 'Registration number is not specified registration number'");
			Message.Field = "Object.LicenseNumber";
			Message.Message();
			LicensingServer.WriteErrorInEventLog(Message.Text);
			Cancel = True;
		Else
			If StrLen(TrimAll(Object.LicenseNumber)) < 13 Then
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
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////
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
Procedure CommandActivateManually(Command)
	
	File = New File(ActivationResponseFileName);
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
	ReadStream.BeginReading(New NotifyDescription("CommandActivateManuallyEndEnd", ThisObject, New Structure("ReadStream", ReadStream)), ActivationResponseFileName,TextEncoding.ANSI);

EndProcedure

&AtClient
Procedure CommandActivateManuallyEndEnd(AdditionalParameters1) Export
	
	ReadStream = AdditionalParameters1.ReadStream;
	
	
	ResponseAnswer = ReadStream.GetText();
	Result = LicensingServer.ActivateProgramKeyOnSpecifiedServer(Object.ServerAddress, ResponseAnswer, ErrorDescription);
	
	If NOT Result Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();				
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	Else
		If ServaersDiffer() Then
			PageNavigation(Items.ActionPageAfterActivation);
		Else
			ThisForm.Close(ErrorDescription);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CommandActivateWebService(Command)
	
	CodedString = FormActivationRequest();
	If CodedString = Undefined Then
		Return;
	EndIf;
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	If LicensingParametersTemplateName = Undefined Then
		ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + Object.DataProcessorName;
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return;
	EndIf;
	
	If ActivationMode = 0 Then
		ActivationResponse = LicensingServer.ActivateViaWebService(CodedString, 0, LicensingParametersTemplateName, ErrorDescription);
	Else
		ActivationResponse = LicensingServer.ActivateViaWebService(CodedString, 2, LicensingParametersTemplateName, ErrorDescription);
	EndIf;
	
	If ActivationResponse = "" Then
		ThisForm.Close(ErrorDescription);
		Return;
	EndIf;
	
	Result = LicensingServer.ActivateProgramKeyOnSpecifiedServer(Object.ServerAddress, ActivationResponse, ErrorDescription);
	If NOT Result Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	Else
		If ServaersDiffer() Then
			PageNavigation(Items.ActionPageAfterActivation);
		Else
			ThisForm.Close(ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandActivateByPhone(Command)
	Var KeyKernel;
	If IsBlankString(StrReplace(Object.PhoneActivationResponseBlock1,"-","")) Then
		MessageString = NStr("ru = 'Заполните ответную строку активации'; en = 'Fill in the activation response string'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
		Return;
	EndIf;
	
	If IsBlankString(StrReplace(Object.PhoneActivationResponseBlock2,"-","")) Then
		MessageString = NStr("ru = 'Заполните ответную строку активации'; en = 'Fill in the activation response string'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
		Return;
	EndIf;
	
	If IsBlankString(StrReplace(Object.PhoneActivationResponseBlock3,"-","")) Then
		MessageString = NStr("ru = 'Заполните ответную строку активации'; en = 'Fill in the activation response string'");
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
		Return;
	EndIf;
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	KeyKernel = "";
	
	ErrorDescription = "";
	ActivationData = New Structure;
	ActivationData.Insert("PinRepresentation",Object.Pin);
	ActivationData.Insert("EquipmentDescription",Object.EquipmentDescription);
	ActivationData.Insert("LicenseNumber",Object.LicenseNumber);
	ActivationData.Insert("Name", Object.Responsible);
	ActivationData.Insert("Company", Object.Company);
	ActivationData.Insert("Phone",Object.Phone);
	ActivationData.Insert("Mail",Object.Email);
	ActivationData.Insert("Site",Object.Site);
	ActivationData.Insert("Installer", "");
	ActivationData.Insert("TIN", Object.TIN);
	
	ActivationResponse = Object.PhoneActivationResponseBlock1 + Chars.LF;
	ActivationResponse = ActivationResponse + Object.PhoneActivationResponseBlock2 + Chars.LF;
	ActivationResponse = ActivationResponse + Object.PhoneActivationResponseBlock3 + Chars.LF;
	
	If NOT LicensingServer.ActivateKeyByPhone(LicensingParametersTemplateName, Object.ServerAddress, ActivationResponse, ActivationData, ErrorDescription) Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	Else
		If ServaersDiffer() Then
			PageNavigation(Items.ActionPageAfterActivation);
		Else
			ThisForm.Close(ErrorDescription);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CommandSaveFile(Command)
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
    ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Title = NStr("ru = 'Сохранить файл запроса активации как'; en = 'Save the activation reques file as'");
	Dialog.Filter = NStr("ru = 'Files *.txt|*.txt'; en = 'Files *.txt|*.txt'");
	
	If ActivationMode = 0 Then
		Dialog.FullFileName = "KAR" + Object.LicenseNumber + ".txt";
	Else
		CodePart = StrReplace(Left(Object.Pin, 7),"-","");
		Dialog.FullFileName = "KAR" + CodePart + ".txt";
	EndIf;
			
	Dialog.Show(New NotifyDescription("CommandSaveFileEnd", ThisObject, New Structure("Dialog, LicensingParametersTemplateName", Dialog, LicensingParametersTemplateName)));
EndProcedure

&AtClient
Procedure CommandSaveFileEnd(SelectedFiles, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog;
	LicensingParametersTemplateName = AdditionalParameters.LicensingParametersTemplateName;
	
	
	If (SelectedFiles <> Undefined) Then
		FileName = Dialog.FullFileName;
	Else
		Return;
	EndIf;
	
	File = New TextDocument();
	File.Write(FileName, TextEncoding.ANSI);
	
	CodedString = FormActivationRequest();
	
	If CodedString = Undefined Then
		Return;
	EndIf;
	
	File.SetText(CodedString);
	File.Write(FileName, TextEncoding.ANSI);
	
	Items.LabelFileName.Title = FileName;
	Items.LabelEmail.Title = LicensingServer.EmailForActivation(LicensingParametersTemplateName);
	
	PageNavigation(Items.PageActivationFileInstruction);

EndProcedure

////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ РЕКВИЗИТОВ ФОРМЫ

// Выбор файла ответа активации
&AtClient
Procedure ActivationResponseFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	AttachingConnected = Undefined;

	BeginAttachingFileSystemExtension(New NotifyDescription("AfterAttachingFileSystemExtension", ThisObject));
EndProcedure

&AtClient
Procedure AfterAttachingFileSystemExtension(Connected, AdditionalParameters) Export
	
	AttachingConnected = Connected;
	If AttachingConnected Then
		FileChoice = New FileDialog(FileDialogMode.Open);
		FileChoice.Multiselect = False;
		FileChoice.Title = NStr("ru = 'CASE File'; en = 'File selection'");
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
	
	ActivationResponseFileName = FullFileName;

EndProcedure


// Обработка действий пользователя
&AtClient
Procedure ActionProcessing(Action)
	
	If Items.GroupPages.CurrentPage = Items.PageServerSelection Then
		If Object.StartMode = 1 Then
			If IsBlankString(Object.ServerAddress) OR Upper(Object.ServerAddress) = "*AUTO" Then
				MessageString = NStr("ru = 'Укажите адрес сервера лицензирования'; en = 'Specify the address of the license server'");
				Message = New UserMessage();
				Message.Text = MessageString;
				Message.Message();
				LicensingServer.WriteErrorInEventLog(MessageString);
				Return;
			EndIf;
		EndIf;
		
		If SolutionCount = 1 Then
			Object.DataProcessorName = GetDataProcessorNameByIndex(0);
			PageNavigation(Items.PageActivationMethod);
		Else
			PageNavigation(Items.PageSolutionSelection);
		EndIf;
		
	ElsIf Items.GroupPages.CurrentPage = Items.PageSolutionSelection Then
		
		If Action =  "Next" Then
			Object.DataProcessorName = GetDataProcessorNameByIndex(SelectedSolution);
			PageNavigation(Items.PageActivationMethod);
		Else
			PageNavigation(Items.PageServerSelection);
		EndIf;
		
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationMethod Then
		If Action = "Next" Then
			
			LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
			If LicensingParametersTemplateName = Undefined Then
				ErrorDescription = NStr("ru = 'Неверный формат имени обработки:'; en = 'Invalid name format of data processor:'") + Chars.LF + Object.DataProcessorName;
				Message = New UserMessage();
				Message.Text = ErrorDescription;
				Message.Message();
				LicensingServer.WriteErrorInEventLog(ErrorDescription);
				Return;
			EndIf;	
			
			If Object.ActivationMethod = 0 Then //веб-сервис
				
				If LicensingServer.ActivationViaWebServiceIsAllowed(LicensingParametersTemplateName) Then
					PageNavigation(Items.PageActivationParameters);
				Else
					ErrorDescription = NStr("ru = 'Для этой конфигурации отсутствует возможность активации через интернет'; en = 'For this product there is no possibility of activation via the Internet'");
					Message = New UserMessage();
					Message.Text = ErrorDescription;
					Message.Message();
					LicensingServer.WriteErrorInEventLog(ErrorDescription);
					Return;
				EndIf;
			ElsIf Object.ActivationMethod = 1 Then //вручную через интернет
				If LicensingServer.ActivationViaEmailIsAllowed(LicensingParametersTemplateName) Then
					PageNavigation(Items.PageRequestResponse);
				Else
					ErrorDescription = NStr("ru = 'Для этой конфигурации отсутствует возможность активации через файловый запрос'; en = 'For this product there is no possibility of activation by file request'");
					Message = New UserMessage();
					Message.Text = ErrorDescription;
					Message.Message();
					LicensingServer.WriteErrorInEventLog(ErrorDescription);
					Return;
				EndIf;
			Else // по телефону
				If LicensingServer.ActivationViaPhoneIsAllowed(LicensingParametersTemplateName) Then
					PageNavigation(Items.PageActivationParameters);
				Else
					ErrorDescription = NStr("ru = 'Для этой конфигурации отсутствует возможность активации по телефону'; en = 'For this configuration, there is no possibility of activation by phone'");
					Message = New UserMessage();
					Message.Text = ErrorDescription;
					Message.Message();
					LicensingServer.WriteErrorInEventLog(ErrorDescription);
					Return;
				EndIf;
			EndIf;
		Else //Назад
			If SolutionCount = 1 Then
				PageNavigation(Items.PageServerSelection);
			Else
				PageNavigation(Items.PageSolutionSelection);
			EndIf;
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageRequestResponse Then
		If Action = "Next" Then
			// Вперед
			If Object.RequestResponse = 0 Then
				PageNavigation(Items.PageActivationParameters);
			Else
				PageNavigation(Items.PageActivationResponse);
			EndIf;
		Else
			// Назад
			PageNavigation(Items.PageActivationMethod);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationParameters Then
		If Action = "Next" Then
			
			If NOT CheckFilling() Then
				Return;
			EndIf;

			If NOT LicensingServer.GetSpecifiedServerEquipmentSignature(Object.ServerAddress, Object.EquipmentSignature, Object.EquipmentDescription, ErrorDescription) Then	
				ErrorDescription = NStr("ru = 'Не удалось получить идентификатор аппаратной привязки. '; en = 'Failed to get the hardware ID binding.'") + ErrorDescription;
				Message = New UserMessage();
   				Message.Text = ErrorDescription;
   				Message.SetData(ThisObject);
    			Message.Message();
				LicensingServer.WriteErrorInEventLog(ErrorDescription);
				Return;
			EndIf;
			
			LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
			ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);

			If ActivationMode = 0 Then
				PinCheckResult = LicensingServer.IsPin(Object.Pin, ErrorDescription);
			Else
				LicenseNumber = "";
				ShortPin = "";	
				PinCheckResult = LicensingServer.IsLongPin(Object.Pin, LicenseNumber, ShortPin, ErrorDescription);
			EndIf;
			
			If PinCheckResult = Undefined Then
				Message = New UserMessage();
				Message.Text = ErrorDescription;
				Message.Message();
				LicensingServer.WriteErrorInEventLog(ErrorDescription);
				Return;
			ElsIf (NOT PinCheckResult) Then
				Message = New UserMessage();
				Message.Text = NStr("ru = 'Некорректно указан пин-код'; en = 'Incorrect PIN'");
				Message.Field = "Object.Pin";
				Message.Message();
				LicensingServer.WriteErrorInEventLog(Message.Text);
				Return;
			EndIf;
							
			If Object.ActivationMethod = 0 Then
				PageNavigation(Items.PageActivationWebService);
			ElsIf Object.ActivationMethod = 1 Then //файл
				PageNavigation(Items.PageActivationFile);
			Else //телефон
				Object.PhoneActivationRequestBlock = FormPhoneActivationRequest();
				InstructionTextOnActivation = NStr("ru = 'Позвоните в центр лицензирования по телефону ""'; en = 'Call in Licensing center by phone ""'") + LicensingServer.LicensingCenterPhone(LicensingParametersTemplateName) + NStr("ru = '"".
				|Продиктуйте регистрационные данные и запрос активации ключа.
				|Затем, перейдите на следующую страницу и введите ответ активации ключа.'; en = '"".
				|Dictate the registration data and an activation key.
				|Then, go to the next page and enter the activation key response.'");
				Items.LabelActivationInstruction.Title = InstructionTextOnActivation;
				PageNavigation(Items.PageActivationRequestPhone);
			EndIf;
		Else
			PageNavigation(Items.PageActivationMethod);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationFile Then
		If Action = "Back" Then
			PageNavigation(Items.PageActivationParameters);
		Else
			If IsBlankString(FileName) Then
				PageNavigation(Items.PageActivationResponse);
			Else
				PageNavigation(Items.PageActivationFileInstruction);
			EndIf;
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationResponse Then
		If Action = "Back" Then
			If Object.RequestResponse = 0 Then
				If IsBlankString(FileName) Then
					PageNavigation(Items.PageActivationFile);
				Else
					PageNavigation(Items.PageActivationFileInstruction);
				EndIf;
			Else
				PageNavigation(Items.PageRequestResponse);
			EndIf;
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationWebService Then
		If Action = "Back" Then
			PageNavigation(Items.PageActivationParameters);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationRequestPhone Then
		If Action = "Next" Then
			PageNavigation(Items.PageActivationPhone);
		Else //назад
			PageNavigation(Items.PageActivationParameters);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationPhone Then
		If Action = "Back" Then
			PageNavigation(Items.PageActivationRequestPhone);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PageActivationFileInstruction Then
		If Action = "Next" Then
			PageNavigation(Items.PageActivationResponse);
		Else
			PageNavigation(Items.PageActivationFile);
		EndIf;
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
	
	If  CurrentPage = Items.PageServerSelection Then
		Items.FormCommandBar.ChildItems.FormCommandBack.Enabled = False;
	Else
		Items.FormCommandBar.ChildItems.FormCommandBack.Enabled = True;
	EndIf;
	
	If CurrentPage = Items.PageActivationWebService OR CurrentPage = Items.PageActivationResponse 
		OR CurrentPage = Items.PageActivationPhone OR CurrentPage = Items.ActionPageAfterActivation Then
		
		Items.FormCommandBar.ChildItems.FormCommandNext.Enabled = False;
	Else
		Items.FormCommandBar.ChildItems.FormCommandNext.Enabled = True;
	EndIf;
	
	If Page = Items.PageActivationParameters Then
		LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
		If LicensingServer.ActivationMode(LicensingParametersTemplateName) = 0 Then
			Items.Pin.Mask = "999-999";
			Items.Pin.Width = 9;
			Items.LicenseNumber.Visible = True;
			Items.LabelRegistrationNumber.Visible = True;
			Items.LabelLicenseNumberByPhone.Visible = True;
			Items.LabelRegistrationNumberFile.Visible = True;
			Items.LabelLicNumberPin.Title = NStr("ru = 'Укажите регистрационный номер программного продукта и прилагающийся к продукту пин-код'");
		Else
			Items.Pin.Mask = "999-999-999-999-999-999";
			Items.Pin.Width = 23;
			Items.LicenseNumber.Visible = False;
			Items.LabelRegistrationNumber.Visible = False;
			Items.LabelLicenseNumberByPhone.Visible = False;
			Items.LabelRegistrationNumberFile.Visible = False;
			Items.LabelLicNumberPin.Visible = False;
		EndIf;
	EndIf;
	
	If CurrentPage = Items.PageActivationMethod Then
		ActivationMethodOnChange(Items.ActivationMethod);
	EndIf;
	
	If CurrentPage = Items.PageActivationFile Then
		Items.FormCommandNext.Enabled = False;
	EndIf;
EndProcedure

// Формирует запрос активации программного ключа
&AtClient
Function FormActivationRequest()
	
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	
	TextXML = New XMLWriter;
	TextXML.SetString();
	
	TextXML.WriteXMLDeclaration();
	TextXML.WriteStartElement("sd");
	
	TextXML.WriteStartElement("Activation");
	
	If ActivationMode = 0 Then
		TextXML.WriteAttribute("Type", "0");
		
		TextXML.WriteAttribute("PinCode", Object.Pin);
		TextXML.WriteAttribute("Regnumber", Object.LicenseNumber);
		
	Else
		TextXML.WriteAttribute("Type", "2");
		TextXML.WriteAttribute("PinCode", Object.Pin);
		TextXML.WriteAttribute("Regnumber", "");
	EndIf;
	
	TextXML.WriteAttribute("Signature", Object.EquipmentSignature);
	TextXML.WriteAttribute("HIDText", Object.EquipmentDescription);
	
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
	If NOT LicensingServer.CodeString(ActivationString, CodedString, ErrorDescription) Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;

	Return CodedString;
EndFunction

// Формирует запрос телефонной активации программного ключа
&AtClient
Function FormPhoneActivationRequest()
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
	ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);

	If ActivationMode = 0 Then
		SerialNumber = LicensingServer.ProductNumberFromSerialNumber(Object.LicenseNumber);
	Else
		SerialNumber = 0;
	EndIf;
	
	ProductLineNumber = LicensingServer.ProductID(LicensingParametersTemplateName);
	Pin = Object.Pin;
	HardwareID = Object.EquipmentSignature;
	Result = "";
	
	If LicensingServer.GetPhoneQuery(SerialNumber, ProductLineNumber, Pin, HardwareID, Result, ErrorDescription) Then
		Return Result;
	Else
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
		Return Undefined;
	EndIf;
EndFunction

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
	Return LicensingServer.GetServerList("",ErrorDescription);
EndFunction

&AtClient
Procedure StartModeOnChange(Item)
	If Object.StartMode = 0 Then
		Object.ServerAddress = "*LOCAL";
		Items.ServerAddress.Enabled = False;
		Items.ConnetToSelectedServerAfterActivation.Enabled = False;
		Object.ConnetToSelectedServerAfterActivation = False;
	Else
		Items.ServerAddress.Enabled = True;
		Items.ConnetToSelectedServerAfterActivation.Enabled = True;
		Object.ConnetToSelectedServerAfterActivation = True;
	EndIf;
EndProcedure

&AtClient
Procedure PageGroupOnCurrentPageChange(Item, CurrentPage)
	If Items.GroupPages.CurrentPage = Items.PageActivationWebService Then
		CurrentAddress = LicensingServer.LicensingServerAddress();
		ActivationAddress = Object.ServerAddress;
		
		If (NOT ValueIsFilled(CurrentAddress) OR Upper(CurrentAddress) = "*LOCAL" OR Upper(CurrentAddress) = "LOCALHOST")
			AND (NOT ValueIsFilled(ActivationAddress) OR Upper(ActivationAddress) = "*LOCAL" OR Upper(ActivationAddress) = "LOCALHOST") Then
			
		Else
			Text = NStr("ru = 'Адрес текущего сервера лицензирования:'; en = 'Address of the current license server:'")+ Chars.NBSp + CurrentAddress
				+ NStr("ru = '|Адрес выбранного сервера для активации ключа:'; en = '|Address of the selected server for the key activation:'") + Chars.NBSp + ActivationAddress;
			
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function ServaersDiffer()
	CurrentAddress = LicensingServer.LicensingServerAddress();
	ActivationAddress = Object.ServerAddress;
	
	If NOT Upper(CurrentAddress) = Upper(ActivationAddress) Then
		Return True;
	ElsIf (Upper(CurrentAddress) = "*LOCAL" OR Upper(CurrentAddress) = "LOCALHOST") AND (Upper(ActivationAddress) = "*LOCAL" OR Upper(ActivationAddress) = "LOCALHOST") Then
		Return False;
	Else
		Return False;
	EndIf;
EndFunction

&AtServer
Procedure OnLoadingDataFromSettingsAtServer(Settings)
	If Upper(Settings["Object.ServerAddress"]) = "*AUTO" Then
		Settings["Object.ServerAddress"] = "";
	EndIf;
EndProcedure

&AtClient
Procedure CommandEndWizardExecution(Command)
	If Object.ConnetToSelectedServerAfterActivation Then
		LicensingServer.SetLicensingServerAddressParameter(Object.ServerAddress);
		Notify("LicensingServer",Object.ServerAddress);
	EndIf;
	ThisForm.Close(ErrorDescription);
EndProcedure

&AtClient
Procedure PhoneActivationResponseBlock1OnChange(Item)
	
	CheckPhoneActivationDataString(Item);
	
EndProcedure

&AtClient
Procedure PhoneActivationResponseBlock1EditTextChange(Item, Text, StandardProcessing)
	CheckPhoneActivationDataString(Item);
EndProcedure

&AtClient
Procedure CheckPhoneActivationDataString(Item)
	ActivationString = Item.EditText;
	Result = LicensingServer.CheckPhoneActivationDataString(ActivationString, ErrorDescription);
	If Result = Undefined Then
		Message = New UserMessage();
		Message.Text = ErrorDescription;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(ErrorDescription);
	EndIf;
	
	If NOT Result Then
		Items[Item.Name].TextColor = WebColors.Red;
	Else
		Items[Item.Name].TextColor = WebColors.Green;
	EndIf;
EndProcedure

&AtClient
Procedure OnClose()
	SaveSettings();
EndProcedure

&AtServer
Procedure SaveSettings()
	SettingDescription = New SettingsDescription;
	SettingDescription.Presentation = NStr("ru = 'Регистрационная информация'; en = 'Registration information'");
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
		Items.LabelActivationMethod.Title = "	" + NStr("ru = 'Онлайн-активация выполняется через интернет. Наиболее быстрый способ активации.'");
	ElsIf Object.ActivationMethod = 1 Then
		Items.LabelActivationMethod.Title = "	" + NStr("ru = 'При выборе этого способа активации - программой создается файл запроса активации. 
		|Этот файл каким-либо способом, например, по электронной почте, передается в центр лицензирования.
		|На основании данного файла запроса в центре лицензирования создается файл активации, который передается обратно.
		|Этот файл активации следует загрузить в систему защиты. 
		|В результате этой загрузки будет активирован программный ключ.'");
	Else
		Items.LabelActivationMethod.Title = "	" + NStr("ru = 'При выборе этого способа активации - пользователь звонит по телефону в центр лицензирования и зачитывает цифровой код, 
		|отображенный программой. 
		|В ответ из центра сообщают цифровой код для активации.
		|Пользователь вводит этот код в соответствующее поле и активирует программный Key.
		|Данный способ удобен, если есть только телефонная связь, а связь через интернет - отсутствует.'");
	EndIf;
EndProcedure

&AtClient
Procedure LabelEmailClick(Item)
	LicensingParametersTemplateName = LicensingServer.GetLicensingParametersTemplateName(Object.DataProcessorName);
    ActivationMode = LicensingServer.ActivationMode(LicensingParametersTemplateName);
	Email = LicensingServer.EmailForActivation(LicensingParametersTemplateName);
	StringMailTo = "mailto:" + Items.LabelEmail.Title;
	
	BeginRunningApplication(Undefined, StringMailTo);
EndProcedure
