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

	If Not IsBlankString(Parameters.NoteText) Then
		Items.NoteDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |Установить?'; 
			           |en = '%1
			           |Do you want to install the extension?'; 
			           |pl = '%1
			           |Ustawić?';
			           |de = '%1
			           |Installieren?';
			           |ro = '%1
			           |Instalați?';
			           |tr = '%1
			           |Ayarla?'; 
			           |es_ES = '%1
			           |¿Instalar?'"),
			Parameters.NoteText);
	EndIf;
	
EndProcedure

#EndRegion