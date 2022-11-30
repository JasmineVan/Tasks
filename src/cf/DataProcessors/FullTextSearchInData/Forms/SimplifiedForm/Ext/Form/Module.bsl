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
	
	RefreshSearchHistory(Items.SearchString);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunSearch(Command)
	
	If IsBlankString(SearchString) Then
		ShowMessageBox(, NStr("ru = 'Введите, что нужно найти.'; en = 'Enter search text.'; pl = 'Wprowadź obiekt wyszukiwania.';de = 'Geben Sie ein Suchobjekt ein.';ro = 'Introduceți ce trebuie de găsit.';tr = 'Bulunması gerekeni girin'; es_ES = 'Introducir un objeto de búsqueda.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("PassedSearchString", SearchString);
	
	OpenForm("CommonForm.SearchForm", FormParameters,, True);
	
	RefreshSearchHistory(Items.SearchString);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure RefreshSearchHistory(Item)
	
	SearchHistory = SavedSearchHistory();
	If TypeOf(SearchHistory) = Type("Array") Then
		Item.ChoiceList.LoadValues(SearchHistory);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SavedSearchHistory()
	
	Return Common.CommonSettingsStorageLoad("FullTextSearchFullTextSearchStrings", "");
	
EndFunction

#EndRegion
