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
	
	FieldsCompositionDetails = FieldsCompositionDetails(Object.FieldsComposition);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
	ShowMessageBox(,
		NStr("ru = 'Ключ доступа не следует изменять, так как он сопоставлен с разными объектами.
		           |Чтобы исправить нестандартную проблему следует удалить ключ доступа или
		           |связь с ним в регистрах и выполнить процедуру обновления доступа.'; 
		           |en = 'It is not recommend that you change the access key as it is mapped to various objects.
		           |To resolve a non-standard issue, delete the access key or
		           |a link with it in registers and update access.'; 
		           |pl = 'Klucz dostępu nie należy zmieniać, ponieważ on jest zestawiony z różnymi obiektami.
		           |Aby poprawić nietypowy problem należy usunąć klucz dostępu lub 
		           |związek z nim w rejestrach i wykonać procedurę aktualizacji dostępu.';
		           |de = 'Der Zugriffsschlüssel sollte nicht geändert werden, da er verschiedenen Objekten zugeordnet ist.
		           |Um ein nicht standardmäßiges Problem zu beheben, entfernen Sie den Zugriffsschlüssel oder
		           |die Registerkommunikation und führen Sie das Verfahren zur Aktualisierung des Zugriffs durch.';
		           |ro = 'Cheia de acces nu trebuie modificată, deoarece ea este confruntată cu diferite obiecte.
		           |Pentru a corecta problema nestandard trebuie să ștergeți cheia de acces sau
		           |legătura cu ea în registre și să executați procedura de actualizare a accesului.';
		           |tr = 'Farklı nesnelerle eşleştirildiğinden erişim anahtarı değiştirilmemelidir.
		           |Standart olmayan bir sorunu gidermek için, erişim anahtarını  veya 
		           |kayıtlarda onunla bağlantıyı kaldırmanız ve erişim güncelleme işlemini gerçekleştirmeniz gerekir.'; 
		           |es_ES = 'No hay que cambiar la clave de acceso porque está vinculada con varios objetos.
		           |Para corregir un problema no estándar hay que eliminar la clave de acceso o
		           |el vínculo con ella en los registros y realizar el procedimiento de actualización de acceso.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FieldsCompositionDetails(FieldsContent)
	
	CurrentCount = FieldsContent;
	Details = "";
	
	TabularSectionNumber = 0;
	While CurrentCount > 0 Do
		Balance = CurrentCount - Int(CurrentCount / 16) * 16;
		If TabularSectionNumber = 0 Then
			Details = NStr("ru = 'Шапка'; en = 'Header'; pl = 'Grupa kont';de = 'Kopfzeile';ro = 'Antet';tr = 'Üst Bilgi'; es_ES = 'Encabezado'") + ": " + Balance;
		Else
			Details = Details + ", " + NStr("ru = 'Табличная часть'; en = 'Tabular section'; pl = 'Część tabelaryczna';de = 'Tabellarischer Teil';ro = 'Secțiunea tabelară';tr = 'Tablo kısmı'; es_ES = 'Parte de tabla'") + " " + TabularSectionNumber + ": " + Balance;
		EndIf;
		CurrentCount = Int(CurrentCount / 16);
		TabularSectionNumber = TabularSectionNumber + 1;
	EndDo;
	
	Return Details;
	
EndFunction

#EndRegion
