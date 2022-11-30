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
	
	If Not Parameters.Property("ExchangeNodeRef", ExchangeNodeRef) Then
		Cancel = True;
		Return;
	EndIf;
	
	Title = ExchangeNodeRef;
	
	ReadMessageNumbers();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// The procedure writes modified data and closes the form.
//
&AtClient
Procedure WriteNodeChanges(Command)
	
	WriteMessageNumbers();
	Notify("ExchangeNodeDataEdit", ExchangeNodeRef, ThisObject);
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ThisObject() 
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Procedure ReadMessageNumbers()
	
	Data = ThisObject().GetExchangeNodeParameters(ExchangeNodeRef, "SentNo, ReceivedNo");
	FillPropertyValues(ThisObject, Data);
	
EndProcedure

&AtServer
Procedure WriteMessageNumbers()
	
	Data = New Structure("SentNo, ReceivedNo", SentNo, ReceivedNo);
	ThisObject().SetExchangeNodeParameters(ExchangeNodeRef, Data);
	
EndProcedure

#EndRegion
