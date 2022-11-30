///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sets the full text search mode
// Executes:
//   - Changes mode of the platform full text search mechanism
//   - Sets value to the UseFullTextSearch constant
//   - Changes value of the UseFullTextSearch functional option
//   - Changes mode of the FullTextSearchUpdateIndex scheduled job
//   - Changes mode of the FullTextSearchMergeIndex scheduled job
//   - Changes mode of the TextExtraction scheduled job of the FilesOperations subsystem.
//
Function SetFullTextSearchMode(UseFullTextSearch) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise NStr("ru = 'Недостаточно прав для совершения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Niewystarczające uprawnienia do wykonania operacji.';de = 'Nicht genügend Rechte zum Ausführen des Vorgangs.';ro = 'Drepturi insuficiente pentru executarea operației.';tr = 'İşlemi gerçekleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para realizar la operación.'");
	EndIf;
	
	Try
		Constants.UseFullTextSearch.Set(UseFullTextSearch);	
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// (See FullTextSearchServer.UseSearchFlagValue)
//
Function UseSearchFlagValue() Export

	Return FullTextSearchServer.UseSearchFlagValue();

EndFunction

#EndRegion

