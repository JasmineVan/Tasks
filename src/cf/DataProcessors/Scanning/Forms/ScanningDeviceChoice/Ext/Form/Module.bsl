///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	ItemsCount = 0;
	If FilesOperationsInternalClient.InitAddIn() Then
		DeviceArray = FilesOperationsInternalClient.EnumDevices();
		For Each Row In DeviceArray Do
			ItemsCount = ItemsCount + 1;
			Items.DeviceName.ChoiceList.Add(Row);
		EndDo;
	EndIf;
	If ItemsCount = 0 Then
		Cancel = True;
		ShowMessageBox(, NStr("ru = 'Не установлен сканер. Обратитесь к администратору программы.'; en = 'There are no scanners installed. Please contact the application administrator.'; pl = 'Skaner nie jest zainstalowany. Skontaktuj się z administratorem aplikacji.';de = 'Scanner ist nicht installiert. Wenden Sie sich an den Anwendungsadministrator.';ro = 'Scanerul nu este instalat. Contactați administratorul aplicației.';tr = 'Tarayıcı yüklü değil. Uygulama yöneticisine başvurun.'; es_ES = 'Escáner no se ha instalado. Contactar el administrador de la aplicación.'"));
	Else
		Items.DeviceName.ListChoiceMode = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChooseScanner(Command)
	
	If IsBlankString(DeviceName) Then
		MessageText = NStr("ru = 'Не выбран сканер.'; en = 'Please select a scanner.'; pl = 'Nie wybrano skanera.';de = 'Kein Scanner ausgewählt.';ro = 'Scanerul nu este selectat.';tr = 'Tarayıcı seçilmedi.'; es_ES = 'Escáner no seleccionado.'");
		CommonClient.MessageToUser(MessageText, , "DeviceName");
		Return;
	EndIf;
	
	SystemInfo = New SystemInfo();
	CommonServerCall.CommonSettingsStorageSave(
		"ScanningSettings/DeviceName",
		SystemInfo.ClientID,
		DeviceName,
		,
		,
		True);
	Close(DeviceName);
EndProcedure

#EndRegion