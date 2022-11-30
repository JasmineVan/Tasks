///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoteDeletionMark") AND AdditionalProperties.NoteDeletionMark Then
		Return;
	EndIf;
		
	If ValueIsFilled(Parent) AND Parent.Author <> Author Then
		Common.MessageToUser(NStr("ru = 'Нельзя указывать группу другого пользователя.'; en = 'You cannot specify a group that belongs to another user.'; pl = 'You cannot specify a group that belongs to another user.';de = 'You cannot specify a group that belongs to another user.';ro = 'You cannot specify a group that belongs to another user.';tr = 'You cannot specify a group that belongs to another user.'; es_ES = 'You cannot specify a group that belongs to another user.'"));
		Cancel = True;
		Return;
	EndIf;
	
	If Not IsFolder Then 
		ChangeDate = CurrentSessionDate();
		SubjectPresentation = Common.SubjectString(Topic);
		
		Position = StrFind(ContentText, Chars.LF);
		If Position > 0 Then
			UserNoteSubject = Mid(ContentText, 1, Position - 1);
		Else
			UserNoteSubject = ContentText;
		EndIf;
		
		If IsBlankString(UserNoteSubject) Then 
			UserNoteSubject = "<" + NStr("ru = 'Пустая заметка'; en = 'Blank note'; pl = 'Blank note';de = 'Blank note';ro = 'Blank note';tr = 'Blank note'; es_ES = 'Blank note'") + ">";
		EndIf;
		
		MaxDescriptionLength = Metadata().DescriptionLength;
		If StrLen(UserNoteSubject) > MaxDescriptionLength Then
			UserNoteSubject = Left(Description, MaxDescriptionLength - 3) + "...";
		EndIf;
		
		Description = UserNoteSubject;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf