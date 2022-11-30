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
	
	ChoiceList = Items.SetItemsType.ChoiceList;
	AddListItem(ChoiceList, "AccessGroups");
	AddListItem(ChoiceList, "UserGroups");
	AddListItem(ChoiceList, "Users");
	AddListItem(ChoiceList, "ExternalUsersGroups");
	AddListItem(ChoiceList, "ExternalUsers");
	
	SetAttributesPageByType(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetItemsTypeOnChange(Item)
	
	SetAttributesPageByType(ThisObject);
	Object.Folders.Clear();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
	ShowMessageBox(,
		NStr("ru = 'Набор групп доступа не следует изменять, так как он сопоставлен с разными ключами доступа.
		           |Чтобы исправить нестандартную проблему следует удалить набор групп доступа или
		           |связь с ним в регистрах и выполнить процедуру обновления доступа.'; 
		           |en = 'It is not recommend that you change the access group set as it is mapped with various access keys.
		           |To resolve a non-standard issue, delete the access group set or
		           |a link with it in registers and update access.'; 
		           |pl = 'Zestaw grup dostępu nie należy zmieniać, ponieważ on jest zestawiony z różnymi kluczami dostępu. 
		           |Aby poprawić nietypowy problem należy usunąć zestaw grup dostępu lub
		           |związek z nim w rejestrach i wykonać procedurę aktualizacji dostępu.';
		           |de = 'Der Set von Zugriffsgruppen sollte nicht geändert werden, da er mit verschiedenen Zugriffsschlüsseln verknüpft ist.
		           |Um ein nicht standardmäßiges Problem zu beheben, entfernen Sie den Zugriffsgruppen-Set oder
		           |registrieren Sie die Kommunikation und führen Sie das Verfahren zur Aktualisierung des Zugriffs durch.';
		           |ro = 'Setul grupurilor de acces nu trebui modificat, deoarece el este confruntat cu diferite chei de acces.
		           |Pentru a corecta problema nestandard trebuie să ștergeți setul grupurilor de acces sau
		           |legătura cu el în registre și să executați procedura de actualizare a accesului.';
		           |tr = 'Farklı nesnelerle eşleştirildiğinden erişim anahtarı değiştirilmemelidir.
		           |Standart olmayan bir sorunu gidermek için, erişim anahtarını  veya 
		           |kayıtlarda onunla bağlantıyı kaldırmanız ve erişim güncelleme işlemini gerçekleştirmeniz gerekir.'; 
		           |es_ES = 'No hay que cambiar el conjunto de grupos de acceso porque está vinculado con varias claves de acceso.
		           |Para corregir un problema no estándar hay que eliminar el conjunto de grupos de acceso o
		           |el vínculo con él en los registros y realizar el procedimiento de actualización de acceso.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddListItem(ChoiceList, CatalogName)
	
	BlankID = CommonClientServer.BlankUUID();
	
	ChoiceList.Add(Catalogs[CatalogName].GetRef(BlankID),
		Metadata.Catalogs[CatalogName].Presentation());
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAttributesPageByType(Form)
	
	If TypeOf(Form.Object.SetItemsType) = Type("CatalogRef.Users")
	 Or TypeOf(Form.Object.SetItemsType) = Type("CatalogRef.ExternalUsers") Then
		
		Form.Items.SetsAttributes.CurrentPage = Form.Items.SingleUserSetAttributes;
	Else
		Form.Items.SetsAttributes.CurrentPage = Form.Items.GroupsSetAttributes;
	EndIf;
	
EndProcedure

#EndRegion
