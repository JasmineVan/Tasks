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
	
	If Parameters.Property("Owner")
		AND TypeOf(Parameters.Owner) = Type("ChartOfCharacteristicTypesRef.QuestionsForSurvey")
		AND NOT Parameters.Owner.IsEmpty() Then
			
			Object.Owner = Parameters.Owner;
		
	Else
		
		MessageText = NStr("ru = 'Данная форма предназначена для открытия только из формы элемента плана вида характеристик ""Вопросы для анкетирования""'; en = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".'; pl = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".';de = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".';ro = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".';tr = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".'; es_ES = 'This form is opened from the form of the item of the chart of characteristic types ""Survey questions"".'");
		Common.MessageToUser(MessageText);
		Cancel = True;
		Return;
		
	EndIf;
	
	If Parameters.Property("ReplyType") Then
		Items.OpenEndedQuestion.Visible = (Parameters.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor);
	Else
		Items.OpenEndedQuestion.Visible = (Object.Owner.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor);
	EndIf;
	
	If Parameters.Property("Description") Then
		Object.Description = Parameters.Description;
	EndIf;
	
EndProcedure

#EndRegion
