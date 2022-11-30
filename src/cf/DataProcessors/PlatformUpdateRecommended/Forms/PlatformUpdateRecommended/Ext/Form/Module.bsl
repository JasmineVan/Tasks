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
	
	If NOT Parameters.Property("OpenByScenario") Then
		Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor is not intended for direct usage.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	SkipExit = Parameters.SkipExit;
	
	Items.MessageText.Title = Parameters.MessageText;
	Items.RecommendedPlatformVersion.Title = Parameters.RecommendedPlatformVersion;
	SystemInfo = New SystemInfo;
	ActualVersion       = SystemInfo.AppVersion;
	Min   = Parameters.MinPlatformVersion;
	Recommended = Parameters.RecommendedPlatformVersion;
	
	CannotContinue = False;
	If CommonClientServer.CompareVersions(ActualVersion, Min) < 0 Then
		TextCondition                                    = NStr("ru = 'необходимо'; en = 'required'; pl = 'jest konieczne';de = 'erforderlich';ro = 'necesar';tr = 'gerekli'; es_ES = 'requerido'");
		CannotContinue                     = True;
		Items.RecommendedPlatformVersion.Title = Min;
	Else
		TextCondition                                    = NStr("ru = 'рекомендуется'; en = 'recommended'; pl = 'zalecane';de = 'empfohlen';ro = 'recomandat';tr = 'tavsiye edilir'; es_ES = 'recomendado'");
		Items.RecommendedPlatformVersion.Title = Recommended;
	EndIf;
	Items.Version.Title = StringFunctionsClientServer.SubstituteParametersToString(Items.Version.Title, TextCondition, SystemInfo.AppVersion);
	
	If CannotContinue Then
		Items.QuestionText.Visible = False;
		Items.FormNo.Visible     = False;
		Title = NStr("ru = 'Необходимо обновить версию платформы'; en = '1C:Enterprise update required'; pl = 'Zaktualizuj wersję platformy';de = '1C:Enterprise Aktualisierung erforderlich';ro = 'Se recomandă actualizarea versiunii platformei';tr = 'Platform sürümünü güncelle'; es_ES = 'Actualizar la versión de la plataforma'");
	EndIf;
	
	If (ClientApplication.CurrentInterfaceVariant() <> ClientApplicationInterfaceVariant.Taxi) Then
		Items.RecommendedPlatformVersion.Font = New Font(,, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not ActionDefined Then
		ActionDefined = True;
		
		If NOT SkipExit Then
			Terminate();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkTextClick(Item)
	
	OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateOrder",,ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ContinueWork(Command)
	
	ActionDefined = True;
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	ActionDefined = True;
	If NOT SkipExit Then
		Terminate();
	EndIf;
	Close();
	
EndProcedure

#EndRegion
