///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// The BeforeWrite event handler prevents access kinds from being changed. These access kinds can be 
// changed only in Designer mode.
//
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Raise
		NStr("ru = 'Изменение видов доступа
		           |выполняется только через конфигуратор.
		           |
		           |Удаление допустимо.'; 
		           |en = 'Access kinds can be
		           |changed only using Designer.
		           |
		           |You can remove them.'; 
		           |pl = 'Zmiana rodzajów dostępu
		           |jest wykonywana tylko za pośrednictwem kreatora.
		           |
		           |Usuwanie jest dozwolone.';
		           |de = 'Das Ändern von Zugriffsarten
		           |ist nur über den Konfigurator möglich.
		           |
		           |Das Löschen ist erlaubt.';
		           |ro = 'Modificarea tipurilor de acces
		           |se face numai prin designer.
		           |
		           |Ștergerea se admite.';
		           |tr = 'Erişim türü değişikliği
		           |, yalnızca yapılandırıcı aracılığı ile yapılabilir. 
		           |
		           | Silinemez.'; 
		           |es_ES = 'Se puede cambiar los tipos de acceso
		           |solo a través del configurador.
		           |
		           |No se puede eliminar.'");
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf