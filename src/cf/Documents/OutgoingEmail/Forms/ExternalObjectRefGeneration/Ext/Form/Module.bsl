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
	
	InfobasePublicationURL = Common.InfobasePublicationURL();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobasePublicationURLOnChange(Item)
	
	GenerateRefAddress();

EndProcedure

&AtClient
Procedure RefToObjectOnChange(Item)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Insert(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If IsBlankString(InfobasePublicationURL) Then
		
		MessageText = NStr("ru = 'Не указан адрес публикации информационной базы в интернете.'; en = 'Infobase publication address on the Internet is not specified.'; pl = 'Infobase publication address on the Internet is not specified.';de = 'Infobase publication address on the Internet is not specified.';ro = 'Infobase publication address on the Internet is not specified.';tr = 'Infobase publication address on the Internet is not specified.'; es_ES = 'Infobase publication address on the Internet is not specified.'");
		CommonClient.MessageToUser(MessageText,, "InfobasePublicationURL",, Cancel);
		
	EndIf;
	
	If IsBlankString(ObjectRef) Then
		
		MessageText = NStr("ru = 'Не указана внутренняя ссылка на объект.'; en = 'Internal reference to the object is not specified.'; pl = 'Internal reference to the object is not specified.';de = 'Internal reference to the object is not specified.';ro = 'Internal reference to the object is not specified.';tr = 'Internal reference to the object is not specified.'; es_ES = 'Internal reference to the object is not specified.'");
		CommonClient.MessageToUser(MessageText,, "ObjectRef",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		NotifyChoice(GeneratedRef);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateRefAddress()

	GeneratedRef = InfobasePublicationURL + "#"+ ObjectRef;

EndProcedure

#EndRegion
