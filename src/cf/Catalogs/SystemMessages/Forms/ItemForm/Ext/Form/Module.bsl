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
	
	MessageBody = Common.ObjectAttributeValue(Object.Ref, "MessageBody").Get();
	
	If TypeOf(MessageBody) = Type("String") Then
		
		MessageBodyPresentation = MessageBody;
		
	Else
		
		Try
			MessageBodyPresentation = Common.ValueToXMLString(MessageBody);
		Except
			MessageBodyPresentation = NStr("ru = 'Тело сообщения не может быть представлено строкой.'; en = 'Body cannot be presented as a string.'; pl = 'Treść wiadomości e-mail nie może być wyświetlana jako wiersz.';de = 'Der E-Mail-Text kann nicht als Zeichenfolge angezeigt werden.';ro = 'Corpul mesajului nu poate fi afișat ca un șir de caractere.';tr = 'E-posta gövdesi bir dize olarak görüntülenemiyor.'; es_ES = 'Cuerpo del correo electrónico no puede visualizarse como una línea.'");
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion
