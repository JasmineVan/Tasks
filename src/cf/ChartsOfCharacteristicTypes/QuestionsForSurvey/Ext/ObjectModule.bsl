///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array();
	
	If Not CommentRequired Then
		NotCheckedAttributeArray.Add("CommentNote");
	EndIf;
	
	If (ReplyType <> Enums.QuestionAnswerTypes.String)
		AND (ReplyType <> Enums.QuestionAnswerTypes.Number) Then
		NotCheckedAttributeArray.Add("Length");
	EndIf;
	If ReplyType <> Enums.QuestionAnswerTypes.InfobaseValue Then
		NotCheckedAttributeArray.Add("ValueType");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		ClearUnnecessaryAttributes();
		SetCCTType();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The procedure clears values of unnecessary attributes.
// This situation occurs when the user changes the answer type upon editing.
Procedure ClearUnnecessaryAttributes()
	
	If ((ReplyType <> Enums.QuestionAnswerTypes.Number) AND (ReplyType <> Enums.QuestionAnswerTypes.String)  AND (ReplyType <> Enums.QuestionAnswerTypes.Text))
	   AND (Length <> 0)Then
		
		Length = 0;
		
	EndIf;
	
	If (ReplyType <> Enums.QuestionAnswerTypes.Number) Then	
		
		MinValue       = 0;
		MaxValue      = 0;
		ShowAggregatedValuesInReports = False;
		
	EndIf;
	
	If ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		CommentRequired = False;
		CommentNote = "";
	EndIf;

EndProcedure

// Sets a CCT value type depending on the answer type.
Procedure SetCCTType()
	
	TypesOfAnswersToQuestion = Enums.QuestionAnswerTypes;
	
	// Qualifiers
	NQ = New NumberQualifiers(?(Length = 0,15,Length),Accuracy);
	SQ = New StringQualifiers(Length);
	DQ = New DateQualifiers(DateFractions.Date);
	
	// Types details
	TypesDetailsNumber  = New TypeDescription("Number",,NQ);
	TypesDetailsString = New TypeDescription("String", , SQ);
	TypesDetailsDate   = New TypeDescription("Date",DQ , , );
	TypesDetailsBoolean = New TypeDescription("Boolean");
	AnswersOptionsTypesDetails     = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions");
	
	If ReplyType = TypesOfAnswersToQuestion.String Then
		
		ValueType = TypesDetailsString;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Text Then
		
		ValueType = TypesDetailsString;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Number Then
		
		ValueType = TypesDetailsNumber;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Date Then
		
		ValueType = TypesDetailsDate;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Boolean Then
		
		ValueType = TypesDetailsBoolean;
		
	ElsIf ReplyType =TypesOfAnswersToQuestion.OneVariantOf
		  OR ReplyType = TypesOfAnswersToQuestion.MultipleOptionsFor Then
		
		ValueType = AnswersOptionsTypesDetails;
		
	EndIf;

EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf