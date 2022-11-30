
&AtClient
//Обработчик нажатия кнопки "ОК"
//
Procedure OK(Command)
	If NOT ValueIsFilled(Comment) Then
		CommonClientServer.MessageToUser(NStr("en='You should fill in the comment.';ru='Необходимо заполнить комментарий!'"));
		Return;
	EndIf;
	ClosingParameter = Comment;
	Close(ClosingParameter);
EndProcedure //ОК()

&AtClient
//Обработчик нажатия кнопки "Отмена"
//
Procedure Cancel(Command)
	Close();
EndProcedure //Отмена()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Comment") Then
		Comment = Parameters.Comment;
	EndIf;
EndProcedure

