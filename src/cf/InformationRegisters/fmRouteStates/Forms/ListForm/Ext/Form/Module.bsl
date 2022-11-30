
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Разрешено прямое обращение к списку для роли Администратор.
	If NOT IsInRole("SystemAdministrator") Then
		CommonClientServer.MessageToUser("Интерактивное редактирование запрещено!", , , ,Cancel);
	EndIf;
EndProcedure

