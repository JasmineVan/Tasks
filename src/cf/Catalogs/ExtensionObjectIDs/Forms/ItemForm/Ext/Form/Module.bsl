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
	
	Catalogs.MetadataObjectIDs.ItemFormOnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

&AtClient
Procedure FullNameOnChange(Item)
	
	FullName = Object.FullName;
	UpdateIDProperties();
	
	If FullName <> Object.FullName Then
		Object.FullName = FullName;
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Объект метаданных не найден по полному имени:
			           |%1.'; 
			           |en = 'Metadata object is not found by full name:
			           |%1.'; 
			           |pl = 'Obiekt metadanych nie został znaleziony według pełnej nazwy:
			           |%1.';
			           |de = 'Das Metadatenobjekt wurde nicht mit seinem vollständigen Namen gefunden:
			           |%1.';
			           |ro = 'Obiect de metadate nu a fost găsit după numele complet:
			           |%1.';
			           |tr = 'Meta veri nesnesi tam adı ile bulunamadı: 
			           |%1'; 
			           |es_ES = 'El objeto de metadatos no se ha encontrado por el nombre completo:
			           |%1.'"),
			FullName));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateIDProperties()
	
	Catalogs.MetadataObjectIDs.UpdateIDProperties(Object);
	
EndProcedure

#EndRegion
