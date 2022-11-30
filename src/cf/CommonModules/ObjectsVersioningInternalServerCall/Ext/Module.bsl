///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Use the function to set change history storage mode.
// Executes:
//   - sets value to the UseObjectsVersioning constant
//   - changes value of the UseObjectsVersioning functional option
//   
Function SetChangeHistoryStorageMode(StoreChangeHistory) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise NStr("ru = 'Недостаточно прав для совершения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Niewystarczające uprawnienia do wykonania operacji.';de = 'Nicht genügend Rechte zum Ausführen des Vorgangs.';ro = 'Drepturi insuficiente pentru executarea operației.';tr = 'İşlemi gerçekleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para realizar la operación.'");
	EndIf;
	
	Try
		Constants.UseObjectsVersioning.Set(StoreChangeHistory);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// (See ObjectsVersioning.StoreHistoryCheckBoxValue)
//
Function StoreHistoryCheckBoxValue() Export
	
	Return ObjectsVersioning.StoreHistoryCheckBoxValue();
	
EndFunction

#EndRegion

