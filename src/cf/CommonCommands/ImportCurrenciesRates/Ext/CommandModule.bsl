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
	
	NotifyDescription = New NotifyDescription("ImportRatesClient", ThisObject);
	ShowQueryBox(NotifyDescription, 
		NStr("ru = 'Будет произведена загрузка файла с полной информацией по курсами всех валют за все время из менеджера сервиса.
              |Курсы валют, помеченных в областях данных для загрузки из сети Интернет, будут заменены в фоновом задании. Продолжить?'; 
              |en = 'File with all the information on exchange rates for all the periods will be imported from the service manager.
              |Exchange rates marked in data areas for importing from the Internet will be replaced in the background job. Continue?'; 
              |pl = 'Pliki zostaną zaimportowane z menedżera usług z pełnymi danymi dotyczącymi kursów walut wszystkich walut za cały okres.
              |Kursy walut zaznaczone w obszarach danych do importu z Internetu zostaną zastąpione w zleceniu działającym w tle. Kontynuować?';
              |de = 'Die Dateien werden vom Service Manager mit vollständigen Daten zu den Wechselkursen aller Währungen für den gesamten Zeitraum importiert. 
              |Die in den Datenbereichen für den Import aus dem Internet markierten Wechselkurse werden im Hintergrundjob ersetzt. Fortsetzen?';
              |ro = 'Fișierele vor fi importate de la managerul de servicii cu date complete despre cursurile de schimb valutar pentru întreaga perioadă.
              |Cursurile de schimb marcate în domeniile de date pentru importul de pe Internet vor fi înlocuite în sarcina de fundal. Continuați?';
              |tr = 'Dosyalar, tüm dönem için tüm döviz kurlarına ilişkin tam verilerle servis yöneticisinden alınır. 
              |İnternet''ten içe aktarılacak veri alanlarında işaretlenen döviz kurları arka plan görevinde değiştirilecektir. Devam etmek istiyor musunuz?'; 
              |es_ES = 'Los archivos se importarán desde el gestor de servicio con los datos completos de los tipos de cambio de todas monedas para el período entero.
              |Los tipos de cambio marcados en las áreas de datos para la importación desde Internet, se sustituirán en la tarea de fondo. ¿Continuar?'"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportRatesClient(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ImportCurrencyRates();
	
	ShowUserNotification(
		NStr("ru = 'Загрузка запланирована.'; en = 'Import is scheduled.'; pl = 'Import jest zaplanowany.';de = 'Der Import ist geplant.';ro = 'Importul este programat.';tr = 'Içe aktarma planlandı.'; es_ES = 'Importación está programada.'"), ,
		NStr("ru = 'Курсы будут загружены в фоновом режиме через непродолжительное время.'; en = 'The rates will soon be imported in the background mode.'; pl = 'Stawki zostaną zaimportowane w tle po pewnym czasie.';de = 'Die Preise werden nach einiger Zeit im Hintergrund importiert.';ro = 'Cursurile vor fi importate în regim de fundal după o scurtă perioadă de timp.';tr = 'Kurlar bir süre sonra arka planda içe aktarılacaktır.'; es_ES = 'Tasas de importarán en el fondo al pasar algún tiempo.'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure ImportCurrencyRates()
	
	CurrencyRatesInternalSaaS.ImportCurrencyRates();
	
EndProcedure

#EndRegion
