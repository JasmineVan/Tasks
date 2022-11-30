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
	
	ExchangePlanInfo = ExchangePlanInfo(CommandParameter);
	
	If ExchangePlanInfo.SeparatedMode Then
		CommonClient.MessageToUser(
			NStr("ru = 'Загрузка правил обмена данными в разделенном режиме недоступна.'; en = 'Cannot load data exchange rules in shared mode.'; pl = 'Pobieranie reguł wymiany danych w rozdzielonym trybie jest niedostępne.';de = 'Das Herunterladen von Datenaustauschregeln im Split-Modus ist nicht möglich.';ro = 'Încărcarea regulilor schimbului de date în regim separat nu este disponibilă.';tr = 'Bölünmüş modda veri alışverişi kuralları içe aktarılamaz.'; es_ES = 'Carga de reglas de intercambio de datos en el modo separado no disponible.'"));
		Return;
	EndIf;
	
	If ExchangePlanInfo.ConversionRulesAreUsed Then
		DataExchangeClient.ImportDataSyncRules(ExchangePlanInfo.ExchangePlanName);
	Else
		Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, ExchangePlanInfo.ORRRulesKind);
		FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, ExchangePlanInfo.ORRRulesKind);
		
		DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", 
			CommandParameter, "ObjectsRegistrationRules");
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ExchangePlanInfo(Val InfobaseNode)
	
	Result = New Structure("SeparatedMode",
		Common.DataSeparationEnabled() AND Common.SeparatedDataUsageAvailable());
		
	If Not Result.SeparatedMode Then
		Result.Insert("ExchangePlanName",
			DataExchangeCached.GetExchangePlanName(InfobaseNode));
			
		Result.Insert("ConversionRulesAreUsed",
			DataExchangeCached.HasExchangePlanTemplate(Result.ExchangePlanName, "ExchangeRules"));
			
		Result.Insert("ORRRulesKind", Enums.DataExchangeRulesTypes.ObjectsRegistrationRules);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion