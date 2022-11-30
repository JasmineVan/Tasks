///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
#If WebClient Then
	ShowMessageBox(, NStr("ru = 'В веб-клиенте параметры прокси-сервера необходимо задавать в настройках браузера.'; en = 'Please specify the proxy server parameters in the browser settings.'; pl = 'Ustaw parametry serwera proxy klienta sieci Web w ustawieniach przeglądarki.';de = 'Legen Sie die Proxy-Server-Parameter des Web-Clients in den Browsereinstellungen fest.';ro = 'Setați parametrii serverului proxy a web-clientului în setările browserului.';tr = 'Tarayıcı ayarlarında web istemcisinin proxy sunucu parametrelerini ayarlayın.'; es_ES = 'Establecer los parámetros del servidor proxy del cliente web en las configuraciones del navegador.'"));
	Return;
#EndIf
	
	OpenForm("CommonForm.ProxyServerParameters", New Structure("ProxySettingAtClient", True));
	
EndProcedure

#EndRegion
