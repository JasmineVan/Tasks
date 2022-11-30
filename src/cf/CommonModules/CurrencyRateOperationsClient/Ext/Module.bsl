///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.AfterStart. 
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Currencies") AND ClientParameters.Currencies.RatesUpdatedByEmployeesResponsible Then
		AttachIdleHandler("CurrencyRateOperationsOutputObsoleteDataNotification", 15, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Currency rates update.

// Displays the update notification.
//
Procedure NotifyRatesObsolete() Export
	
	ShowUserNotification(
		NStr("ru = 'Курсы валют устарели'; en = 'Exchange rates are outdated'; pl = 'Kursy wymiany walut są nieaktualne';de = 'Wechselkurse sind veraltet';ro = 'Cursurile de schimb sunt învechite';tr = 'Döviz kurları güncel değil'; es_ES = 'Tipos de cambio están desactualizados'"),
		DataProcessorURL(),
		NStr("ru = 'Обновить курсы валют'; en = 'Update exchange rates'; pl = 'Zaktualizuj kursy wymiany walut';de = 'Wechselkurs aktualisieren';ro = 'Actualizați cursurile de schimb';tr = 'Döviz kurları güncelleyin'; es_ES = 'Actualizar los tipos de cambio'"),
		PictureLib.Warning32);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesAreUpdated() Export
	
	ShowUserNotification(
		NStr("ru = 'Курсы валют успешно обновлены'; en = 'Exchange rates are updated'; pl = 'Kursy wymiany są aktualizowane';de = 'Wechselkurse werden aktualisiert';ro = 'Cursurile de schimb sunt actualizate';tr = 'Döviz kurları güncelendi'; es_ES = 'Tipos de cambio se han actualizado'"),
		,
		NStr("ru = 'Курсы валют обновлены'; en = 'The exchange rates are updated.'; pl = 'Kursy wymiany są aktualizowane';de = 'Wechselkurse werden aktualisiert';ro = 'Ratele valutare au fost actualizate';tr = 'Döviz kurları güncelendi'; es_ES = 'Tipos de cambio se han actualizado'"),
		PictureLib.Information32);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesUpToDate() Export
	
	ShowMessageBox(,NStr("ru = 'Курсы валют актуальны.'; en = 'The exchange rates are up-to-date.'; pl = 'Kursy wymiany są istotne.';de = 'Wechselkurse sind relevant.';ro = 'Ratele valutare sunt actuale';tr = 'Döviz kurları güncel '; es_ES = 'Tipos de cambio son relevantes.'"));
	
EndProcedure

// Returns a notification URL.
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.ImportCurrenciesRates";
EndFunction

#EndRegion
