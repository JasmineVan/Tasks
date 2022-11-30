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
		ShowMessageBox(, NStr("ru = 'Выберите варианты отчетов программы, для которых необходимо сбросить настройки размещения.'; en = 'Select application report options to reset location settings.'; pl = 'Wybierz warianty raportu aplikacji, których ustawienia lokalizacji mają zostać zresetowane.';de = 'Wählen Sie die Anwendungsbericht-Optionen, deren Standorteinstellungen zurückgesetzt werden sollen.';ro = 'Selectați opțiunile pentru rapoartele aplicației în cadrul cărora setările de locație urmează să fie resetate.';tr = 'Hangi konum ayarlarının sıfırlanacağını, uygulama raporu seçeneklerini seçin.'; es_ES = 'Seleccionar las opciones del informe de la aplicación las configuraciones de la ubicación de las cuales tienen que restablecerse.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.ResetAssignmentToSections",
		New Structure("Variants", Options), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
