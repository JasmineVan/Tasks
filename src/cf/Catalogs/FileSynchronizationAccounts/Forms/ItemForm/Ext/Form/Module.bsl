///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Object.FilesAuthor) Then
		AsFilesAuthor = "User";
		Items.FilesAuthor.Enabled = True;
	Else
		AsFilesAuthor = "ExchangePlan";
		Items.FilesAuthor.Enabled = False;
	EndIf;
	
	If Not IsBlankString(Object.Service) Then
		If Object.Service = "https://webdav.yandex.com"
			Or Object.Service = "https://webdav.yandex.ru" Then
			Service = NStr("ru = 'Яндекс.Диск'; en = 'Yandex.Disk'; pl = 'Yandeks.Dysk';de = 'Yandex.Disk';ro = 'Yandex.Disc';tr = 'Yandex.Disk'; es_ES = 'Yandex.Disk'");
		ElsIf Object.Service = "https://webdav.4shared.com" Then
			Service = "4shared.com"
		ElsIf Object.Service = "https://dav.box.com/dav" Then
			Service = "Box"
		ElsIf Object.Service = "https://dav.dropdav.com" Then
			Service = "Dropbox"
		EndIf;
	EndIf;
	
	AutoDescription = IsBlankString(Object.Description);
	If Not IsBlankString(Object.Description) Then
		Items.AsFilesAuthor.ChoiceList[0].Presentation =
			StringFunctionsClientServer.SubstituteParametersToString(Items.AsFilesAuthor.Title, "(" + Object.Description + ")");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
		ModuleObjectAttributesLock = Common.CommonModule("ObjectAttributesLock");
		ModuleObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		
		SetPrivilegedMode(True);
		AccountParameters = Common.ReadDataFromSecureStorage(Object.Ref, "Username, Password");
		SetPrivilegedMode(False);
		
		Username = AccountParameters.Username;
		Password = ?(ValueIsFilled(AccountParameters.Password), ThisObject.UUID, "");
		
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel Then
		
		SetPrivilegedMode(True);
		
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Username, "Username");
		If PasswordChanged Then
			Common.WriteDataToSecureStorage(CurrentObject.Ref, Password);
		EndIf;
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	AutoDescription = IsBlankString(Object.Description);
EndProcedure

&AtClient
Procedure ServicePresentationOnChange(Item)
	
	If Service = "Yandex.Disk" Then
		Object.Service = "https://webdav.yandex.com"
	ElsIf Service = "4shared.com" Then
		Object.Service = "https://webdav.4shared.com"
	ElsIf Service = "Box" Then
		Object.Service = "https://dav.box.com/dav"
	ElsIf Service = "Dropbox" Then
		Object.Service = "https://dav.dropdav.com"
	Else
		Object.Service = "";
	EndIf;
	
	If AutoDescription Then
		If ValueIsFilled(Object.Service) Then
			Object.Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Синхронизация с %1'; en = 'Synchronization with %1'; pl = 'Synchronizuj z %1';de = 'Synchronisation mit %1';ro = 'Sincronizare cu %1';tr = 'İle senkronize et%1'; es_ES = 'Sincronización con %1'"), 
				Items.Service.ChoiceList.FindByValue(Service).Presentation);
		Else
			Object.Description = "";
		EndIf;	
	EndIf;	

EndProcedure

&AtClient
Procedure AsFilesAuthorOnChange(Item)
	
	Object.FilesAuthor = Undefined;
	Items.FilesAuthor.Enabled = False;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordChanged = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CheckSettings(Command)
	
	ClearMessages();
	
	If Object.Ref.IsEmpty() Or Modified Then
		NotifyDescription = New NotifyDescription("CheckSettingsCompletion", ThisObject);
		QuestionText = NStr("ru = 'Для проверки настроек необходимо записать данные учетной записи. Продолжить?'; en = 'To proceed with the settings validation, please save the account data. Do you want to continue?'; pl = 'Aby zweryfikować ustawienia, należy zapisać dane konta. Kontynuować?';de = 'Um die Einstellungen zu überprüfen, müssen Sie die Kontodaten aufschreiben. Fortfahren?';ro = 'Pentru verificarea setărilor trebuie să înregistrați datele contului. Continuați?';tr = 'Ayarları doğrulamak için hesap bilgilerini kaydetmeniz gerekir. Devam etmek istiyor musunuz?'; es_ES = 'Para comprobar lo ajustes es necesario guardar los datos de la cuenta. ¿Continuar?'");
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("ru = 'Продолжить'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare';tr = 'Devam'; es_ES = 'Continuar'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(NotifyDescription, QuestionText, Buttons);
		Return;
	EndIf;
	
	CheckCanSyncWithCloudService();
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributesEditing(Command)
	
	ModuleObjectAttributesLockClient = CommonClient.CommonModule("ObjectAttributesLockClient");
	ModuleObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckSettingsCompletion(DialogResult, AdditionalParameters) Export
	
	If DialogResult <> "Continue" Then
		Return;
	EndIf;
	
	If Not Write() Then
		Return;
	EndIf;
	
	CheckCanSyncWithCloudService();
	
EndProcedure

&AtClient
Procedure CheckCanSyncWithCloudService()
	
	ResultStructure = Undefined;
	
	ExecuteConnectionCheck(Object.Ref, ResultStructure);
	
	ResultProtocol = ResultStructure.ResultProtocol;
	ResultText = ResultStructure.ResultText;
	
	If ResultStructure.Cancel Then
		
		ProtocolText = StringFunctionsClientServer.ExtractTextFromHTML(ResultProtocol);
		If Not ValueIsFilled(ResultStructure.ErrorCode) Then
			
			DiagnosticsResult = CheckConnection(Object.Service, ProtocolText);
			ErrorText          = DiagnosticsResult.ErrorDescription;
			ProtocolText       = DiagnosticsResult.DiagnosticsLog;
			
		ElsIf ResultStructure.ErrorCode = 404 Then
			ErrorText = NStr("ru = 'Проверьте правильность указанной корневой папки.'; en = 'Please check whether the specified root folder is valid.'; pl = 'Sprawdź poprawność określonego folderu głównego.';de = 'Überprüfen Sie die Korrektheit des angegebenen Stammordners.';ro = 'Verificați corectitudinea folderului de rădăcină indicat.';tr = 'Belirtilen kök klasörün doğru olduğunu doğrulayın.'; es_ES = 'Compruebe si la carpeta raíz indicada es correcta.'");
		ElsIf ResultStructure.ErrorCode = 401 Then
			ErrorText = NStr("ru = 'Проверьте правильность введенных логина/пароля.'; en = 'Please check whether the username and password are valid.'; pl = 'Sprawdź poprawność wprowadzonej nazwy użytkownika/hasła.';de = 'Überprüfen Sie, ob Ihr Login/Passwort korrekt ist.';ro = 'Verificați corectitudinea loginului/parolei introduse.';tr = 'Girilen kullanıcı adı / şifrenin doğruluğunu kontrol edin.'; es_ES = 'Compruebe si nombre de usuario/contraseña introducidos son correctos.'");
		Else
			ErrorText = NStr("ru = 'Проверьте правильность введенных данных.'; en = 'Please check the validity of the data you entered.'; pl = 'Sprawdź poprawność wprowadzonych danych.';de = 'Überprüfen Sie die Richtigkeit der eingegebenen Daten.';ro = 'Verificați corectitudinea datelor introduse.';tr = 'Girilen verilerin doğruluğunu kontrol edin.'; es_ES = 'Compruebe si los datos introducidos son correctos.'");
		EndIf;
		
		ShowMessageBox(Undefined, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка параметров учетной записи завершилась с ошибками.
					   |%1
					   |
					   |Технические подробности:
					   |%2'; 
					   |en = 'The account validation completed with errors.
					   |%1
					   |
					   |Details: 
					   |%2'; 
					   |pl = 'Sprawdzenie parametrów konta użytkownika zostało zakończone błędami.
					   |%1
					   |
					   |Szczegóły techniczne:
					   |%2';
					   |de = 'Die Überprüfung der Benutzerkontoparameter ist fehlerhaft verlaufen.
					   |%1
					   |
					   |Technische Details:
					   |%2';
					   |ro = 'Verificarea parametrilor contului s-a soldat cu erori.
					   |%1
					   |
					   |Detalii tehnice:
					   |%2';
					   |tr = 'Hesap ayarlarını kontrol edin, 
					   |%1
					   |
					   |hatalarla sona erdi.
					   |%2'; 
					   |es_ES = 'La prueba de parámetros de la cuenta se ha terminado con errores.
					   |%1
					   |
					   |Información técnica:
					   |%2'"),
					   ErrorText,
					   ProtocolText));
	Else
		ShowMessageBox(Undefined, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка параметров учетной записи завершилась успешно. 
					   |%1'; 
					   |en = 'The account validation is completed.
					   |%1'; 
					   |pl = 'Sprawdzenie parametrów konta zakończyło się pomyślnie. 
					   |%1';
					   |de = 'Die Überprüfung der Kontenparameter wurde erfolgreich abgeschlossen. 
					   |%1';
					   |ro = 'Verificarea parametrilor de cont a fost încheiată cu succes. 
					   |%1';
					   |tr = 'Hesap parametresi kontrolü başarıyla tamamlandı.
					   |%1'; 
					   |es_ES = 'La prueba de los parámetros de la cuenta se ha terminado con éxito. 
					   |%1'"),
			ResultText));
	EndIf;
		
EndProcedure

&AtServer
Procedure ExecuteConnectionCheck(Account, ResultStructure)
	FilesOperationsInternal.ExecuteConnectionCheck(Account, ResultStructure);
EndProcedure

&AtServerNoContext
Function CheckConnection(Service, ProtocolText)
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Return ModuleNetworkDownload.ConnectionDiagnostics(Service);
	Else
		
		Return New Structure("ErrorDescription, DiagnosticsLog",
			NStr("ru = 'Проверьте соединение с сетью Интернет.'; en = 'Please check the internet connection.'; pl = 'Sprawdź połączenie internetowe.';de = 'Überprüfen Sie Ihre Internetverbindung.';ro = 'Verificați conexiunea cu rețeaua Internet.';tr = 'İnternet bağlantınızı kontrol edin.'; es_ES = 'Compruebe la conexión con Internet.'"), ProtocolText);
			
	EndIf;
	
EndFunction

&AtClient
Procedure AsFilesAuthorUserOnChange(Item)
	
	Items.FilesAuthor.Enabled = True;
	
EndProcedure

#EndRegion