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
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UpdateRegisterData(Command)
	
	HasChanges = False;
	
	UpdateRegisterDataAtServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("ru = 'Обновление выполнено успешно.'; en = 'The update is completed.'; pl = 'Aktualizacja zakończona pomyślnie.';de = 'Das Update war erfolgreich.';ro = 'Actualizarea este executată cu succes.';tr = 'Güncelleme başarılı.'; es_ES = 'Actualización se ha realizado con éxito.'");
	Else
		Text = NStr("ru = 'Обновление не требуется.'; en = 'The update is not required.'; pl = 'Aktualizacja nie jest wymagana.';de = 'Update ist nicht erforderlich.';ro = 'Actualizarea nu este necesară.';tr = 'Güncelleme gerekmiyor.'; es_ES = 'No se requiere una actualización.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateRegisterDataAtServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessRightsDependencies.UpdateRegisterData(HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
