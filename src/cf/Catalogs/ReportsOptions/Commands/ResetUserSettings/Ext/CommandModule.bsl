///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(Options, CommandExecuteParameters)
	If TypeOf(Options) <> Type("Array") Or Options.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Выберите варианты отчетов, для которых необходимо сбросить пользовательские настройки.'; en = 'Select report options to reset custom settings.'; pl = 'Wybierz warianty sprawozdania, dla których wymagane jest zresetowanie ustawień niestandardowych.';de = 'Wählen Sie Berichtsoptionen aus, für die die benutzerdefinierten Einstellungen zurückgesetzt werden müssen.';ro = 'Selectați variantele rapoartelor pentru care trebuie resetate setările de utilizator.';tr = 'Özel ayarları sıfırlamanız gereken rapor seçeneklerini seçin.'; es_ES = 'Seleccionar las opciones del informe para las cuales se requiere restablecer las configuraciones personales.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.ResetUserSettings",
		New Structure("Variants", Options), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
