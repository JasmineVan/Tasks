&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ServerAddress = SessionParameters.LicensingServerAddress;
	
	If NOT ValueIsFilled(ServerAddress) Then
		MessageString = (NStr("ru = 'Отсутствует подключение к серверу лицензирования'; en = 'No connection to the license server'"));
		Message = New UserMessage();
		Message.Text = MessageString;
		Message.Message();
		LicensingServer.WriteErrorInEventLog(MessageString);
		Cancel = True;
	EndIf;
	
	SolutionsList = LicensingSupport.GetProductList();
	
	If SolutionsList.Count() > 1 Then // Несколько решений
		Items.SelectedSolution.Visible = True;
		SolutionCount = SolutionsList.Count();
		SelectedSolutionList = Items.SelectedSolution.ChoiceList;
		SolutionIndex = 0;
		For Each ListItem In SolutionsList Do
			SelectedSolutionList.Add(SolutionIndex, ListItem.Value);
			SolutionIndex = SolutionIndex + 1;
		EndDo;
	Else
		Items.SelectedSolution.Visible = False;
	EndIf;
	
	SelectedSolution = 0;
	
	DataProcessorName = GetDataProcessorNameByIndex(SelectedSolution);
	
	If NOT Cancel Then
		Result = GetKeyParameters(DataProcessorName);
		
		DistrWithSoftwareKey = (SerialNumber = HardwareNumber);
		
		If Result Then
			FillParametersTable();
		Else
			Items.ErrorDescription.Visible = True;
			ErrorDescription = NStr("ru = 'Не удалось получить параметры ключа защиты'");
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function GetKeyParameters(DataProcessorName)
	ParameterEndDate = 0;
	
	Result = LicensingServer.GetProtectionKeyParameters(DataProcessorName, TotalUsersForPlace, FreeUsersForPlace, TotalUsersForSession
	                                                             , FreeUsersForSession, Mask, Counter1, Counter2, Counter3
																 , ParameterEndDate, KeyType, SerialNumber, HardwareNumber, Pin, KeyName, ErrorDescription, ErrorCode);
	If NOT Result Then
		Return False;
	Else
		EndDate = ParameterEndDate;
		Return True;
	EndIf;
EndFunction

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

// Возвращает строковое представление типа ключа
&AtServer
Function StringKeyType(KeyType)
	If DistrWithSoftwareKey Then
		KeyTypeAsString = NStr("ru = 'Программный'; en = 'Software'");
	Else
		KeyTypeAsString = NStr("ru = 'Аппаратный'; en = 'Hardware'");
	EndIf;
	
	If KeyType = 2 Then
		KeyTypeAsString = KeyTypeAsString + NStr("ru = ', Демонстрационный'; en = ', demo'");
	EndIf;
	
	Return KeyTypeAsString;
EndFunction

// Возвращает описание количества подключений
&AtServer
Function StringConnectionNumber(Всего, Свободно)
	If Всего>=255 Then
		String = NStr("ru = 'Без ограничений '; en = 'Without restriction '") + Chars.NBSp + NStr("ru = 'занято -'; en = 'used -'") + Chars.NBSp + String(Всего - Свободно);
	Else
		String = NStr("ru = 'всего - '; en = 'total -'") + String(Всего) + ", " + NStr("ru = 'занято - '; en = 'used -'") + String(Всего - Свободно) + ", " + NStr("ru = 'свободно - '; en = 'available -'") + String(Свободно);
	EndIf;
	Return String;
EndFunction

// Возвращает строковое представление даты окончания действия ключа
&AtServer
Function StringExpirationDate(EndDate)
	If EndDate = '18991230000000' Then
		ExpirationDateAsString = NStr("ru = 'Не определено'; en = 'not determined'");
	Else
		ExpirationDateAsString = Format(EndDate,"DLF=D");
	EndIf;
	Return ExpirationDateAsString;
EndFunction

// Заполняет таблицу параметров ключа лицензирования
&AtServer
Procedure FillParametersTable()
	ParametersTableAddRow(NStr("ru = 'Сервер лицензирования'; en = 'License server'"), SessionParameters.LicensingServerAddress);
	ParametersTableAddRow(NStr("ru = 'Наименование ключа'; en = 'The key name'"), KeyName);
	ParametersTableAddRow(NStr("ru = 'Серийный номер'; en = 'Serial number'"), SerialNumber);
	If NOT DistrWithSoftwareKey Then
		ParametersTableAddRow(NStr("ru = 'Аппаратный номер'; en = 'Hardware key number'"), HardwareNumber);
	EndIf;
	ParametersTableAddRow(NStr("ru = 'Дата окончания'; en = 'Expiration date'"), StringExpirationDate(EndDate));
	ParametersTableAddRow(NStr("ru = 'Тип ключа'; en = 'Key type'"), StringKeyType(KeyType));
	If DistrWithSoftwareKey Then
		ParametersTableAddRow(NStr("ru = 'Пин-код'; en = 'PIN'"), Pin);
	EndIf;
	ParametersTableAddRow(NStr("ru = 'Подключений за место'; en = 'Connections for a place'"), StringConnectionNumber(TotalUsersForPlace, FreeUsersForPlace));
	ParametersTableAddRow(NStr("ru = 'Подключений за сессию'; en = 'Connections per session'"), StringConnectionNumber(TotalUsersForSession, FreeUsersForSession));
	ParametersTableAddRow(NStr("ru = 'Маска'; en = 'Mask'"), Mask);
	ParametersTableAddRow(NStr("ru = 'Маска 2'; en = 'Mask 2'"), Counter2);
	ParametersTableAddRow(NStr("ru = 'Версия компоненты'; en = 'Version of the protection component'"), LicensingServer.GetProtectedDataProcessor(DataProcessorName).Компонента.Версия);
	
	ComponentStoragePlace = LicensingServer.GetComponentStoragePlace();
	If Find(ComponentStoragePlace, "CommonTemplate") Then
		ComponentSource = NStr("ru = 'Внутреннее хранилище'; en = 'Internal storage'");
	Else
		ComponentSource = NStr("ru = 'Внешнее хранилище'; en = 'External storage'");
	EndIf;
	ParametersTableAddRow(NStr("ru = 'Источник компоненты'; en = 'Location of component'"), ComponentSource);
EndProcedure

&AtServer
Procedure ParametersTableAddRow(Parameter, Value)
	NewLine = KeyParametersTable.Add();
	NewLine.Parameter = Parameter;
	NewLine.Value = Value;
EndProcedure

&AtClient
Procedure CommandSaveToFile(Command)
	Text = "";
	
	Text = Text + NStr("ru = 'DATE:'") + Chars.NBSp + CurrentDate() + Chars.CR + Chars.LF;
	If NOT ErrorDescription = "" Then
		Text = Text + NStr("ru = 'Описание ошибки: '; en = 'Error description'") + ErrorDescription + Chars.CR + Chars.LF; 
	EndIf;
	
	For Each CurRow In KeyParametersTable Do
		Text = Text + CurRow.Parameter + ": " + CurRow.Value + Chars.CR + Chars.LF;
	EndDo;
	
	FileName = "LicParam_"+SerialNumber+".txt";
	
	Dialog = New FileDialog(FileDialogMode.Save);
	
	Dialog.Title = NStr("ru = 'Сохранить файл параметров лицензирования как'; en = 'Save the licensing options file as'");
	Dialog.Filter = NStr("ru = 'Files *.txt|*.txt'; en = 'Files *.txt|*.txt'");
	Dialog.FullFileName = FileName;
	
	Dialog.Show(New NotifyDescription("CommandSaveToFileEnd", ThisObject, New Structure("Dialog, Text", Dialog, Text)));
EndProcedure

&AtClient
Procedure CommandSaveToFileEnd(SelectedFiles, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog;
	Text = AdditionalParameters.Text;
	
	
	If (SelectedFiles <> Undefined) Then
		FileName = Dialog.FullFileName;
	Else
		Return;
	EndIf;
	
	File = New TextDocument();
	File.Write(FileName, TextEncoding.ANSI);
	
	File.SetText(Text);
	File.Write(FileName, TextEncoding.ANSI);
	
	WarningText = NStr("ru = 'Описание текущих параметров лицензирования сохранено в файл: '; en = 'Description of the current licensing options stored in the file'") + FileName;
	ShowMessageBox(Undefined, WarningText,,NStr("ru = 'Сохранен файл текущих параметров лицензирования'; en = 'The file is saved'"));

EndProcedure

&AtClient
Procedure SelectedSolutionOnChange(Item)
	
	KeyParametersTable.Clear();
	
	Result = GetKeyParameters(GetDataProcessorNameByIndex(SelectedSolution));
	
	DistrWithSoftwareKey = (SerialNumber = HardwareNumber);
	
	If Result Then
		FillParametersTable();
	Else
		Items.ErrorDescription.Visible = True;
		ErrorDescription = NStr("ru = 'Не удалось получить параметры ключа защиты'; en = 'Could not get the key parameters of protection'");
	EndIf;
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure
