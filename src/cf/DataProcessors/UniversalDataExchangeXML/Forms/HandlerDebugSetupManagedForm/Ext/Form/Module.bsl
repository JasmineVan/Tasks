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
	
	// First of all, checking the access rights.
	If Not AccessRight("Administration", Metadata) Then
		Raise NStr("ru = 'Использование обработки в интерактивном режиме доступно только администратору.'; en = 'Running the data processor manually requires administrator rights.'; pl = 'Używanie przetwarzania danych w trybie interaktywnym jest dostępne tylko dla administratora.';de = 'Die Verwendung des Datenprozessors im interaktiven Modus ist nur für Administratoren verfügbar.';ro = 'Utilizarea procesării în modul interactiv este disponibilă numai pentru administrator.';tr = 'Etkileşimli modda veri işlemcisi kullanımı sadece yönetici için kullanılabilir.'; es_ES = 'Uso del procesador de datos en el modo interactivo está disponible solo para el administrador'");
	EndIf;
	
	Object.ExchangeFileName = Parameters.ExchangeFileName;
	Object.ExchangeRuleFileName = Parameters.ExchangeRuleFileName;
	Object.EventHandlerExternalDataProcessorFileName = Parameters.EventHandlerExternalDataProcessorFileName;
	Object.AlgorithmDebugMode = Parameters.AlgorithmDebugMode;
	Object.ReadEventHandlersFromExchangeRulesFile = Parameters.ReadEventHandlersFromExchangeRulesFile;
	
	FormHeader = NStr("ru = 'Настройка отладки обработчиков при %Event% данных'; en = 'Configure debugguing upon data %Event%'; pl = 'Skonfiguruj debugowanie zdarzeń %Event% ';de = 'Konfigurieren Sie das Debugging von %Event%-Handlern.';ro = 'Configurați corectare handlers pentru %Event%';tr = '%Event% işleyicilerinin hata ayıklamasını yapılandırın'; es_ES = 'Configurar depuración de gestores de %Event%'");	
	Event = ?(Parameters.ReadEventHandlersFromExchangeRulesFile, NStr("ru = 'выгрузке'; en = 'export'; pl = 'eksportuj';de = 'export';ro = 'export';tr = 'dışa aktarma'; es_ES = 'exportar'"), NStr("ru = 'загрузке'; en = 'import'; pl = 'importuj';de = 'import';ro = 'import';tr = 'içe aktar'; es_ES = 'importar'"));
	FormHeader = StrReplace(FormHeader, "%Event%", Event);
	Title = FormHeader;
	
	ButtonTitle = NStr("ru = 'Сформировать модуль отладки %Event%'; en = 'Generate %Event% debug engine'; pl = 'Wygeneruj moduł debugowania %Event%';de = 'Generieren Sie %Event% Debug-Modul';ro = 'Generați modul corectare %Event% ';tr = '%Event% hata ayıklama modülü oluştur'; es_ES = 'Generar módulo de depuración de %Event%'");
	Event = ?(Parameters.ReadEventHandlersFromExchangeRulesFile, NStr("ru = 'выгрузки'; en = 'export'; pl = 'przesyłanie';de = 'exporte';ro = 'export';tr = 'dışa aktarma'; es_ES = 'subidas'"), NStr("ru = 'загрузки'; en = 'imports'; pl = 'pobierania';de = 'importe';ro = 'import';tr = 'içe aktarma'; es_ES = 'descargas'"));
	ButtonTitle = StrReplace(ButtonTitle, "%Event%", Event);
	Items.ExportHandlersCode.Title = ButtonTitle;
	
	SpecialTextColor = StyleColors.SpecialTextColor;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibility();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AlgorithmDebugOnChange(Item)
	
	OnChangeOfChangeDebugMode();
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileSelectionDialog = New FileDialog(FileDialogMode.Open);
	
	FileSelectionDialog.Filter     = NStr("ru = 'Файл внешней обработки обработчиков событий (*.epf)|*.epf'; en = 'Event handler external data processor file (*.epf)|*.epf'; pl = 'Zewnętrzny plik opracowania programów obsługi zdarzeń (*.epf)|*.epf';de = 'Externe Datenverarbeitungsdatei von Ereignis-Anerndern (*.epf)|*.epf';ro = 'Fișierul procesării externe a handlerelor evenimentelor (*.epf)|*.epf';tr = 'Olay işleyicilerinin dış veri işlemci dosyası (*.epf) |*.epf'; es_ES = 'Archivo del procesador de datos externo de los manipuladores de eventos (*.epf)|*.epf'");
	FileSelectionDialog.DefaultExt = "epf";
	FileSelectionDialog.Title = NStr("ru = 'Выберите файл'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectați fișierul';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
	FileSelectionDialog.Preview = False;
	FileSelectionDialog.FilterIndex = 0;
	FileSelectionDialog.FullFileName = Item.EditText;
	FileSelectionDialog.CheckFileExist = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	Notification = New NotifyDescription("NameOfExternalDataProcessorFileOfEventHandlersChoiceProcessing", ThisObject, AdditionalParameters);
	FileSelectionDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure NameOfExternalDataProcessorFileOfEventHandlersChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.EventHandlerExternalDataProcessorFileName = SelectedFiles[0];
	
	EventHandlerExternalDataProcessorFileNameOnChange(AdditionalParameters.Item);
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileNameOnChange(Item)
	
	SetVisibility();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Finish(Command)
	
	ClearMessages();
	
	If IsBlankString(Object.EventHandlerExternalDataProcessorFileName) Then
		
		MessageToUser(NStr("ru = 'Укажите имя файла внешней обработки.'; en = 'Enter the external data processor file name.'; pl = 'Podaj nazwę zewnętrznego pliku przetwarzania danych.';de = 'Geben Sie einen Namen für die externe Datenprozessordatei an.';ro = 'Specificați numele fișierului procesării externe.';tr = 'Harici veri işlemcisi dosyasının adını belirtin.'; es_ES = 'Especificar un nombre del archivo del procesador de datos externo.'"), "EventHandlerExternalDataProcessorFileName");
		Return;
		
	EndIf;
	
	EventHandlerExternalDataProcessorFile = New File(Object.EventHandlerExternalDataProcessorFileName);
	
	Notification = New NotifyDescription("EventHandlerExternalDataProcessorFileExistanceCheckCompletion", ThisObject);
	EventHandlerExternalDataProcessorFile.BeginCheckingExistence(Notification);
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileExistanceCheckCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("ru = 'Указанный файл внешней обработки не существует.'; en = 'The specified external data processor file does not exist.'; pl = 'Określony plik zewnętrznego przetwarzania danych nie istnieje.';de = 'Die angegebene Datei des externen Datenprozessors existiert nicht.';ro = 'Fișierul specificat al procesării externe nu există.';tr = 'Belirtilen harici veri işlemcisi dosyası mevcut değil.'; es_ES = 'El archivo especificado del procesador de datos externo no existe.'"),
			"EventHandlerExternalDataProcessorFileName");
		Return;
	EndIf;
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("EventHandlerExternalDataProcessorFileName", Object.EventHandlerExternalDataProcessorFileName);
	ClosingParameters.Insert("AlgorithmsDebugMode", Object.AlgorithmDebugMode);
	ClosingParameters.Insert("ExchangeRuleFileName", Object.ExchangeRuleFileName);
	ClosingParameters.Insert("ExchangeFileName", Object.ExchangeFileName);
	
	Close(ClosingParameters);
	
EndProcedure

&AtClient
Procedure OpenFile(Command)
	
	ShowEventHandlersInWindow();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibility()
	
	OnChangeOfChangeDebugMode();
	
	// Highlighting wizard steps that require corrections with red color.
	SelectExternalDataProcessorName(IsBlankString(Object.EventHandlerExternalDataProcessorFileName));
	
	Items.OpenFile.Enabled = Not IsBlankString(Object.EventHandlersTempFileName);
	
EndProcedure

&AtClient
Procedure SelectExternalDataProcessorName(NeedToSelect = False) 
	
	Items.Step4Pages.CurrentPage = ?(NeedToSelect, Items.RedPage, Items.GreenPage);
	
EndProcedure

&AtClient
Procedure ExportHandlersCode(Command)
	
	// Data was exported earlier...
	If Not IsBlankString(Object.EventHandlersTempFileName) Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("ru = 'Выгрузить повторно'; en = 'Repeat export'; pl = 'Eksportuj ponownie';de = 'Exportieren Sie erneut';ro = 'Exportați din nou';tr = 'Tekrar dışa aktarma'; es_ES = 'Exportar de nuevo'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("ru = 'Открыть модуль'; en = 'Open module'; pl = 'Otwórz moduł';de = 'Modul öffnen';ro = 'Deschis modul';tr = 'Modülü aç'; es_ES = 'Abrir el módulo'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		
		NotifyDescription = New NotifyDescription("ExportHandlersCodeCompletion", ThisObject);
		ShowQueryBox(NotifyDescription, NStr("ru = 'Модуль отладки с кодом обработчиков уже выгружен.'; en = 'The debug module with the handler script is already exported.'; pl = 'Moduł debugowania z kodem obsługi jest już eksportowany.';de = 'Die Debug-Engine mit dem Anwender-Code wurde bereits exportiert.';ro = 'Modulul de depanare cu codul handlerelor este deja exportat.';tr = 'İşleyici koduyla hata ayıklama motoru zaten dışa aktarılıyor.'; es_ES = 'Motor de depuración con el código del manipulador ya se ha exportado.'"), ButtonsList,,DialogReturnCode.No);
		
	Else
		
		ExportHandlersCodeCompletion(DialogReturnCode.Yes, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportHandlersCodeCompletion(Result, AdditionalParameters) Export
	
	HasExportErrors = False;
	
	If Result = DialogReturnCode.Yes Then
		
		ExportedWithErrors = False;
		ExportEventHandlersAtServer(ExportedWithErrors);
		
	ElsIf Result = DialogReturnCode.Cancel Then
		
		Return;
		
	EndIf;
	
	If Not HasExportErrors Then
		
		SetVisibility();
		
		ShowEventHandlersInWindow();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowEventHandlersInWindow()
	
	EventHandlers = EventHandlers();
	If EventHandlers <> Undefined Then
		EventHandlers.Show(NStr("ru = 'Модуль отладки обработчиков'; en = 'Handler debug module'; pl = 'Moduł nastawienia przetwarzania';de = 'Anwender-Debug-Engine';ro = 'Modulul de depanare a handlerelor';tr = 'İşleyici hata ayıklama motoru'; es_ES = 'Motor de depuración del manipulador'"));
	EndIf;
	
	
	ExchangeProtocol = ExchangeProtocol();
	If ExchangeProtocol <> Undefined Then
		ExchangeProtocol.Show(NStr("ru = 'Ошибки выгрузки модуля обработчиков'; en = 'Handler debug module export errors'; pl = 'Wystąpił błąd podczas eksportowania modułu obsługi';de = 'Beim Exportieren des Anwender-Moduls ist ein Fehler aufgetreten';ro = 'Eroare la exportul modulului handlerelor';tr = 'İşleyici modülünü dışa aktarırken bir hata oluştu'; es_ES = 'Ha ocurrido un error al exportar el módulo del manipulador'"));
	EndIf;
	
EndProcedure

&AtServer
Function EventHandlers()
	
	EventHandlers = Undefined;
	
	HandlerFile = New File(Object.EventHandlersTempFileName);
	If HandlerFile.Exist() AND HandlerFile.Size() <> 0 Then
		EventHandlers = New TextDocument;
		EventHandlers.Read(Object.EventHandlersTempFileName);
	EndIf;
	
	Return EventHandlers;
	
EndFunction

&AtServer
Function ExchangeProtocol()
	
	ExchangeProtocol = Undefined;
	
	ErrorLogFile = New File(Object.ExchangeProtocolTempFileName);
	If ErrorLogFile.Exist() AND ErrorLogFile.Size() <> 0 Then
		ExchangeProtocol = New TextDocument;
		ExchangeProtocol.Read(Object.EventHandlersTempFileName);
	EndIf;
	
	Return ExchangeProtocol;
	
EndFunction

&AtServer
Procedure ExportEventHandlersAtServer(Cancel)
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ObjectForServer.ExportEventHandlers(Cancel);
	ValueToFormAttribute(ObjectForServer, "Object");
	
EndProcedure

&AtClient
Procedure OnChangeOfChangeDebugMode()
	
	Tooltip = Items.AlgorithmsDebugTooltip;
	
	Tooltip.CurrentPage = Tooltip.ChildItems["Group_"+Object.AlgorithmDebugMode];
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

#EndRegion
