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
	
	ThisObject.ReadOnly = Parameters.ReadOnly;
	
	Items.Ref.TypeRestriction  = Parameters.ValueType;
	RefTypeString             = Parameters.RefTypeString;
	Items.Presentation.Visible = RefTypeString;
	Items.Ref.Title        = Parameters.AttributeDescription;
	
	UsageKey = ?(RefTypeString, "EditRow", "EditReferenceObject");
	StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, UsageKey);
	
	If Not Parameters.RefTypeString
		AND PropertyManagerInternal.ValueTypeContainsPropertyValues(Parameters.ValueType) Then
		ChoiceParameter = ?(ValueIsFilled(Parameters.AdditionalValuesOwner),
			Parameters.AdditionalValuesOwner, Parameters.Property);
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("AttributeName", Parameters.AttributeName);
	ReturnValue.Insert("RefTypeString", RefTypeString);
	If Parameters.RefTypeString Then
		ReturnValue.Insert("RefAttributeName", Parameters.RefAttributeName);
		
		LinkAndPresentation = PropertyManagerInternal.AddressAndPresentation(Parameters.AttributeValue);
		Ref        = LinkAndPresentation.Ref;
		Presentation = LinkAndPresentation.Presentation;
	Else
		Ref = Parameters.AttributeValue;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormOKButton.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ChoiceParameter = Undefined Then
		Return;
	EndIf;
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", ChoiceParameter));
	
	Items.Ref.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKButton(Command)
	If RefTypeString Then
		Template = "<a href = ""%1"">%2</a>";
		If Not ValueIsFilled(Presentation) Then
			Presentation = Ref;
		EndIf;
		If Not ValueIsFilled(Ref) Then
			Value = "";
			ReturnValue.Insert("FormattedString", BlankFormattedString());
		Else
			Value = StringFunctionsClientServer.SubstituteParametersToString(Template, Ref, Presentation);
			ReturnValue.Insert("FormattedString", StringFunctionsClientServer.FormattedString(Value));
		EndIf;
	Else
		Value = Ref;
	EndIf;
	
	ReturnValue.Insert("Value", Value);
	Close(ReturnValue);
EndProcedure

&AtClient
Procedure CancelButton(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function BlankFormattedString()
	ValuePresentation= NStr("ru = 'не задано'; en = 'not set'; pl = 'nie określono';de = 'nicht gesetzt';ro = 'nu este specificat';tr = 'belirlenmedi'; es_ES = 'no especificado'");
	EditLink = "NotDefined";
	Result            = New FormattedString(ValuePresentation,, StyleColors.EmptyHyperlinkColor,, EditLink);
	
	Return Result;
EndFunction

#EndRegion