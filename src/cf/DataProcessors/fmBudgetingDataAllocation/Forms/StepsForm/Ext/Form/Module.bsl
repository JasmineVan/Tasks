
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ДЕЙСТВИЯ КОМАНДНЫХ ПАНЕЛЕЙ ФОРМЫ

&AtClient
//Обработчик события нажатия на кнопку "ОК"
//устанавливает на основной форме обработки флажки в выбранном диапазоне
//
Procedure CommandOK(Command)
	
	Close(New Structure("BeginStep, EndStep", BeginStep, EndStep));
	
EndProcedure //КомандаОК()

&AtClient
//Обработчик события нажатия на кнопку "Закрыть"
//закрывает форму шагов и не устанавливает на основной форме обработки флажки в выбранном диапазоне
//
Procedure CommandClose(Command)
	
	Close();
	
EndProcedure //КомандаЗакрыть()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("CurrentRowStep") Then
		EndStep = Parameters.CurrentRowStep;
	EndIf;
EndProcedure //ПриСозданииНаСервере()







