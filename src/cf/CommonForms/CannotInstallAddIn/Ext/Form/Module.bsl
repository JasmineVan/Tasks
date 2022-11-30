///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(Parameters.NoteText) Then
		Items.NoteDecoration.Title = StringFunctionsClientServer.FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1
				           |
				           |Не предусмотрена работа внешней компоненты 
				           |в клиентском приложении <b>%2</b>.
				           |Используйте <a href = about:blank>поддерживаемое клиентское приложение</a> или обратитесь к разработчику внешней компоненты.'; 
				           |en = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.'; 
				           |pl = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';
				           |de = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';
				           |ro = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';
				           |tr = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.'; 
				           |es_ES = '%1
				           |
				           |The add-in is not supported 
				           |in the client application <b>%2</b>.
				           |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.'"),
				Parameters.NoteText,
				PresentationOfCurrentClient()));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportedClients", Parameters.SupportedClients);
	
	OpenForm("CommonForm.SupportedClientApplications", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function PresentationOfCurrentClient()
	
	SystemInfo = New SystemInfo;
	
#If WebClient Then
	Row = SystemInfo.UserAgentInformation;
	
	If StrFind(Row, "Chrome/") > 0 Then
		Browser = NStr("ru = 'Chrome'; en = 'Chrome'; pl = 'Chrome';de = 'Chrome';ro = 'Chrome';tr = 'Chrome'; es_ES = 'Chrome'");
	ElsIf StrFind(Row, "MSIE") > 0 Then
		Browser = NStr("ru = 'Internet Explorer'; en = 'Internet Explorer'; pl = 'Internet Explorer';de = 'Internet Explorer';ro = 'Internet Explorer';tr = 'Internet Explorer'; es_ES = 'Internet Explorer'");
	ElsIf StrFind(Row, "Safari/") > 0 Then
		Browser = NStr("ru = 'Safari'; en = 'Safari'; pl = 'Safari';de = 'Safari';ro = 'Safari';tr = 'Safari'; es_ES = 'Safari'");
	ElsIf StrFind(Row, "Firefox/") > 0 Then
		Browser = NStr("ru = 'Firefox'; en = 'Firefox'; pl = 'Firefox';de = 'Firefox';ro = 'Firefox';tr = 'Firefox'; es_ES = 'Firefox'");
	EndIf;
	
	Application = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'веб-клиент %1'; en = 'web client %1'; pl = 'web client %1';de = 'web client %1';ro = 'web client %1';tr = 'web client %1'; es_ES = 'web client %1'"), Browser);
#ElsIf MobileAppClient Then
	Application = NStr("ru = 'мобильное приложение'; en = 'mobile application'; pl = 'mobile application';de = 'mobile application';ro = 'mobile application';tr = 'mobile application'; es_ES = 'mobile application'");
#ElsIf MobileClient Then
	Application = NStr("ru = 'мобильный клиент'; en = 'mobile client'; pl = 'mobile client';de = 'mobile client';ro = 'mobile client';tr = 'mobile client'; es_ES = 'mobile client'");
#ElsIf ThinClient Then
	Application = NStr("ru = 'тонкий клиент'; en = 'thin client'; pl = 'thin client';de = 'thin client';ro = 'thin client';tr = 'thin client'; es_ES = 'thin client'");
#ElsIf ThickClientOrdinaryApplication Then
	Application = NStr("ru = 'толстый клиент (обычное приложение)'; en = 'thick client (standard application)'; pl = 'thick client (standard application)';de = 'thick client (standard application)';ro = 'thick client (standard application)';tr = 'thick client (standard application)'; es_ES = 'thick client (standard application)'");
#ElsIf ThickClientManagedApplication Then
	Application = NStr("ru = 'толстый клиент'; en = 'thick client'; pl = 'thick client';de = 'thick client';ro = 'thick client';tr = 'thick client'; es_ES = 'thick client'");
#EndIf
	
	If SystemInfo.PlatformType = PlatformType.Windows_x86 Then 
		Platform = NStr("ru = 'Windows x86'; en = 'Windows x86'; pl = 'Windows x86';de = 'Windows x86';ro = 'Windows x86';tr = 'Windows x86'; es_ES = 'Windows x86'");
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then 
		Platform = NStr("ru = 'Windows x86-64'; en = 'Windows x86-64'; pl = 'Windows x86-64';de = 'Windows x86-64';ro = 'Windows x86-64';tr = 'Windows x86-64'; es_ES = 'Windows x86-64'");
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86 Then 
		Platform = NStr("ru = 'Linux x86'; en = 'Linux x86'; pl = 'Linux x86';de = 'Linux x86';ro = 'Linux x86';tr = 'Linux x86'; es_ES = 'Linux x86'");
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then 
		Platform = NStr("ru = 'Linux x86-64'; en = 'Linux x86-64'; pl = 'Linux x86-64';de = 'Linux x86-64';ro = 'Linux x86-64';tr = 'Linux x86-64'; es_ES = 'Linux x86-64'");
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86 Then 
		Platform = NStr("ru = 'macOS x86'; en = 'macOS x86'; pl = 'macOS x86';de = 'macOS x86';ro = 'macOS x86';tr = 'macOS x86'; es_ES = 'macOS x86'");
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86_64 Then 
		Platform = NStr("ru = 'macOS x86-64'; en = 'macOS x86-64'; pl = 'macOS x86-64';de = 'macOS x86-64';ro = 'macOS x86-64';tr = 'macOS x86-64'; es_ES = 'macOS x86-64'");
	EndIf;
	
	// Example:
	// Firefox Windows x86 web client Windows x86-64 thin client
	// 
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 %2'; en = '%1 %2'; pl = '%1 %2';de = '%1 %2';ro = '%1 %2';tr = '%1 %2'; es_ES = '%1 %2'"), Application, Platform);
	
EndFunction

#EndRegion