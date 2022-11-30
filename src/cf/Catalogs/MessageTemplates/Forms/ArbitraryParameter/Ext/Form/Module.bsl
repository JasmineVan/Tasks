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
	
	If Parameters.TypeDetails.Types().Count() > 0 Then
		FoundParameterType = Parameters.TypeDetails.Types()[0];
	EndIf;
	
	FillChoiceListInputOnBasis(FoundParameterType);
	
	For each ParameterFromForm In Parameters.ParametersList Do
		If StrStartsWith(Parameters.ParameterName, MessageTemplatesClientServer.ArbitraryParametersTitle()) Then
			ParameterNameToCheck = Mid(Parameters.ParameterName, StrLen(MessageTemplatesClientServer.ArbitraryParametersTitle()) + 2);
		Else
			ParameterNameToCheck = Parameters.ParameterName;
		EndIf;
		If ParameterFromForm.ParameterName = ParameterNameToCheck Then
			Continue;
		EndIf;
		ParametersList.Add(ParameterFromForm.ParameterName, ParameterFromForm.ParameterPresentation);
	EndDo;
	
	If StrStartsWith(Parameters.ParameterName, MessageTemplatesClientServer.ArbitraryParametersTitle()) Then
		ParameterName = Mid(Parameters.ParameterName, StrLen(MessageTemplatesClientServer.ArbitraryParametersTitle()) + 2);
	Else
		ParameterName = Parameters.ParameterName;
	EndIf;
	ParameterPresentation = Parameters.ParameterPresentation;
	ParameterType = Parameters.TypeDetails;
	
EndProcedure

&AtServerNoContext
Function ParameterTypeAsString(FullTypeName)
	
	If StrCompare(FullTypeName, NStr("ru = 'Дата'; en = 'Date'; pl = 'Date';de = 'Date';ro = 'Date';tr = 'Date'; es_ES = 'Date'")) = 0 Then
		Result = Type("Date");
	ElsIf StrCompare(FullTypeName, NStr("ru = 'Строка'; en = 'Row'; pl = 'Row';de = 'Row';ro = 'Row';tr = 'Row'; es_ES = 'Row'")) = 0 Then
		Result = Type("String");
	Else
		ObjectManager = Common.ObjectManagerByFullName(FullTypeName);
		If ObjectManager <> Undefined Then
			Result = TypeOf(ObjectManager.EmptyRef());
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParameterTypeOnChange(Item)
	If IsBlankString(ParameterPresentation) AND IsBlankString(ParameterName) Then
		ParameterPresentation = Items.TypeString.EditText;
		Position = StrFind(TypeString, ".", SearchDirection.FromEnd);
		If Position > 0 AND Position < StrLen(TypeString) Then
			ParameterName = Mid(TypeString, Position + 1);
		Else
			ParameterName = TypeString;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	For Each ParameterFromForm In ParametersList Do
		If StrCompare(ParameterFromForm.Value, ParameterName) = 0 Then
			ShowMessageBox(, NStr("ru='Некорректное имя параметра. Параметр с таким именем уже был добавлен ранее.'; en = 'Incorrect parameter name. A parameter with the same name has been added already.'; pl = 'Incorrect parameter name. A parameter with the same name has been added already.';de = 'Incorrect parameter name. A parameter with the same name has been added already.';ro = 'Incorrect parameter name. A parameter with the same name has been added already.';tr = 'Incorrect parameter name. A parameter with the same name has been added already.'; es_ES = 'Incorrect parameter name. A parameter with the same name has been added already.'"));
			Return;
		EndIf;
		If StrCompare(ParameterFromForm.Presentation, ParameterPresentation) = 0 Then
			ShowMessageBox(, NStr("ru='Некорректное представление параметра. Параметр с таким представлением уже был добавлен ранее.'; en = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.'; pl = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.';de = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.';ro = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.';tr = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.'; es_ES = 'Incorrect parameter presentation. A parameter with the same presentation has already been added.'"));
			Return;
		EndIf;
	EndDo;
	
	If InvalidParameterName(ParameterName) OR IsBlankString(ParameterName) Then
		ShowMessageBox(, NStr("ru='Некорректное имя параметра. Нельзя использовать пробелы, знаки пунктуации и другие спец. символы.'; en = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.'; pl = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.';de = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.';ro = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.';tr = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.'; es_ES = 'Incorrect parameter name. You cannot use spaces, punctuation marks, and other special characters.'"));
		Return;
	EndIf;
	
	If IsBlankString(ParameterPresentation) Then
		ShowMessageBox(, NStr("ru='Некорректное представление параметра.'; en = 'Incorrect parameter presentation.'; pl = 'Incorrect parameter presentation.';de = 'Incorrect parameter presentation.';ro = 'Incorrect parameter presentation.';tr = 'Incorrect parameter presentation.'; es_ES = 'Incorrect parameter presentation.'"));
		Return;
	EndIf;
	
	If IsBlankString(TypeString) Then
		ShowMessageBox(, NStr("ru='Некорректный тип параметра.'; en = 'Incorrect parameter type.'; pl = 'Incorrect parameter type.';de = 'Incorrect parameter type.';ro = 'Incorrect parameter type.';tr = 'Incorrect parameter type.'; es_ES = 'Incorrect parameter type.'"));
		Return;
	EndIf;
	
	Result = New Structure("ParameterName, ParameterPresentation, ParameterType");
	FillPropertyValues(Result, ThisObject);
	Result.ParameterType = ParameterTypeAsString(TypeString);
	Close(Result);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function InvalidParameterName(ParameterName)
	
	Try
		Test = New Structure(ParameterName, ParameterName);
	Except
		Return True;
	EndTry;
	
	Return Type(Test) <> Type("Structure");
	
EndFunction

&AtServer
Procedure FillChoiceListInputOnBasis(ParameterType)
	
	TypePresentation = "";
	MessagesTemplatesSettings = MessagesTemplatesInternalCachedModules.OnDefineSettings();
	For each TemplateSubject In MessagesTemplatesSettings.TemplateSubjects Do
		If StrCompare(TemplateSubject.Name, Parameters.InputOnBasisParameterTypeFullName) = 0 Then
			Continue;
		EndIf;
		ObjectMetadata = Metadata.FindByFullName(TemplateSubject.Name);
		If ObjectMetadata = Undefined Then
			Continue;
		EndIf;
		Items.TypeString.ChoiceList.Add(TemplateSubject.Name, TemplateSubject.Presentation);
		
		ObjectManager = Common.ObjectManagerByFullName(TemplateSubject.Name);
		If ObjectManager <> Undefined Then
			If ParameterType = TypeOf(ObjectManager.EmptyRef()) Then
				TypePresentation = TemplateSubject.Name;
			EndIf;
		EndIf;
	EndDo;
	
	If ParameterType = Type("String") Then
		TypePresentation = "String";
	ElsIf ParameterType = Type("Date") Then
		TypePresentation = "Date";
	EndIf;
	
	Items.TypeString.ChoiceList.Insert(0, "Date", NStr("ru = 'Дата'; en = 'Date'; pl = 'Date';de = 'Date';ro = 'Date';tr = 'Date'; es_ES = 'Date'"));
	Items.TypeString.ChoiceList.Insert(0, "String", NStr("ru = 'Строка'; en = 'Row'; pl = 'Row';de = 'Row';ro = 'Row';tr = 'Row'; es_ES = 'Row'"));
	
	TypeString = TypePresentation;
	
EndProcedure

#EndRegion

