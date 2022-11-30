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
	
	MappingFieldsList = Parameters.MappingFieldsList;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MappingFieldListOnChange(Item)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunMapping(Command)
	
	NotifyChoice(MappingFieldsList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateCommentLabelText()
	
	MarkedListItemArray = CommonClientServer.MarkedItems(MappingFieldsList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NoteLabel = NStr("ru = 'Сопоставление будет выполнено только по внутренним идентификаторам объектов.'; en = 'Mapping will be performed by UUIDs only.'; pl = 'Obiekty będą mapowane wyłącznie za pomocą wewnętrznych identyfikatorów.';de = 'Objekte werden nur durch interne Bezeichner abgebildet.';ro = 'Confruntarea va fi executată numai conform identificatorilor interni ai obiectelor.';tr = 'Nesneler yalnızca iç tanımlayıcılarla eşleştirilecektir.'; es_ES = 'Objetos se mapearán solo por los identificadores internos.'");
		
	Else
		
		NoteLabel = NStr("ru = 'Сопоставление будет выполнено по внутренним идентификаторам объектов и по выбранным полям.'; en = 'Mapping will be performed by UUIDs and selected fields.'; pl = 'Obiekty będą mapowane przez wewnętrzne identyfikatory i wybrane pola.';de = 'Objekte werden durch interne Bezeichner und ausgewählte Felder zugeordnet.';ro = 'Confruntarea va fi executată conform identificatorilor interni ai obiectelor și conform câmpurilor selectate.';tr = 'Nesneler dahili tanımlayıcılar ve seçilen alanlar ile eşleştirilecektir.'; es_ES = 'Objetos se mapearán por los identificadores internos y los campos seleccionados.'");
		
	EndIf;
	
EndProcedure

#EndRegion
