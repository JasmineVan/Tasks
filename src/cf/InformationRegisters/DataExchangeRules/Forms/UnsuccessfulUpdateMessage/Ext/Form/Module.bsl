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
	
	ExchangePlanName = Parameters.ExchangePlanName;
	ExchangePlanSynonym = Metadata.ExchangePlans[ExchangePlanName].Synonym;
	
	ObjectConversionRules = Enums.DataExchangeRulesTypes.ObjectConversionRules;
	ObjectsRegistrationRules = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,,
		Parameters.DetailedErrorPresentation);
		
	ErrorMessage = Items.ErrorMessageText.Title;
	ErrorMessage = StrReplace(ErrorMessage, "%2", Parameters.BriefErrorPresentation);
	ErrorMessage = StrReplaceWithFormalization(ErrorMessage, "%1", ExchangePlanSynonym);
	Items.ErrorMessageText.Title = ErrorMessage;
	
	RulesFromFile = InformationRegisters.DataExchangeRules.RulesFromFileUsed(ExchangePlanName, True);
	
	If RulesFromFile.ConversionRules AND RulesFromFile.RecordRules Then
		RulesType = NStr("ru = 'конвертации и регистрации'; en = 'conversions and registrations'; pl = 'konwersje i rejestracje';de = 'Umrechnungen und Registrierungen';ro = 'conversii și înregistrări';tr = 'dönüşümler ve kayıtlar'; es_ES = 'conversiones y registros'");
	ElsIf RulesFromFile.ConversionRules Then
		RulesType = NStr("ru = 'конвертации'; en = 'conversions'; pl = 'konwersje';de = 'Konvertierungen';ro = 'conversie';tr = 'dönüştürme'; es_ES = 'de conversión'");
	ElsIf RulesFromFile.RecordRules Then
		RulesType = NStr("ru = 'регистрации'; en = 'registrations'; pl = 'rejestracje';de = 'Registrierungen';ro = 'înregistrare';tr = 'kayıt'; es_ES = 'de registro'");
	EndIf;
	
	Items.RulesTextFromFile.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.RulesTextFromFile.Title, ExchangePlanSynonym, RulesType);
	
	UpdateStartTime = Parameters.UpdateStartTime;
	If Parameters.UpdateEndTime = Undefined Then
		UpdateEndTime = CurrentSessionDate();
	Else
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	FormParameters.Insert("RunNotInBackground", True);
	EventLogClient.OpenEventLog(FormParameters);
	
EndProcedure

&AtClient
Procedure Restart(Command)
	Close(False);
EndProcedure

&AtClient
Procedure ImportRulesSet(Command)
	
	DataExchangeClient.ImportDataSyncRules(ExchangePlanName);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StrReplaceWithFormalization(Row, SearchSubstring, ReplaceSubstring)
	
	StartPosition = StrFind(Row, SearchSubstring);
	
	RowArray = New Array;
	
	RowArray.Add(Left(Row, StartPosition - 1));
	RowArray.Add(New FormattedString(ReplaceSubstring, New Font(,,True)));
	RowArray.Add(Mid(Row, StartPosition + StrLen(SearchSubstring)));
	
	Return New FormattedString(RowArray);
	
EndFunction

#EndRegion