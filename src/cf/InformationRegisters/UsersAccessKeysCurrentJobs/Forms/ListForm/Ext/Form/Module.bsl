
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
Procedure CancelBackgroundJob(Command)
	
	If Items.List.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Запись не выделена.'; en = 'Record is not highlighted.'; pl = 'Zapis nie jest wyróżniony.';de = 'Aufzeichnung ist nicht markiert.';ro = 'Înregistrarea nu este selectată.';tr = 'Kayıt vurgulanmamıştır.'; es_ES = 'Registro no marcado.'"));
		Return;
	EndIf;
	
	ResultingText = "";
	CancelBackgroundJobAtServer(Items.List.CurrentData.ThreadID, ResultingText);
	
	ShowMessageBox(, ResultingText);
	
EndProcedure


#EndRegion

#Region Private

&AtServerNoContext
Procedure CancelBackgroundJobAtServer(JobID, ResultingText)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	
	If BackgroundJob = Undefined Then
		ResultingText = NStr("ru = 'Не удалость найти фоновое задание по идентификатору.'; en = 'Cannot find background job by ID.'; pl = 'Nie udało się znaleźć zadanie wykonywane w tle wg identyfikatora.';de = 'Der Hintergrundjob konnte nicht anhand der ID gefunden werden.';ro = 'Eșec la găsirea sarcinii de fundal conform identificatorului.';tr = 'Kimlik tarafından arka plan işi bulunamadı.'; es_ES = 'No se ha podido encontrar una tarea de fondo por el identificador.'");
		Return;
	EndIf;
	
	Try
		BackgroundJob.Cancel();
		ResultingText = NStr("ru = 'Фоновое задание отменено.'; en = 'Background job is canceled.'; pl = 'Zadanie w tle zostało anulowane.';de = 'Hintergrundjob abgebrochen.';ro = 'Sarcina de fundal este revocată.';tr = 'Arkaplan işi iptal edildi.'; es_ES = 'Tarea de fondo cancelada.'");
	Except
		ErrorInformation = ErrorInfo();
		ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось отменить фоновое задание по причине:
			           |%1'; 
			           |en = 'Cannot cancel background job due to:
			           |%1'; 
			           |pl = 'Nie można cofnąć zadania w tle z powodu:
			           |%1';
			           |de = 'Der Hintergrundjob konnte aus einem bestimmten Grund nicht abgebrochen werden:
			           |%1';
			           |ro = 'Eșec la revocarea sarcinii de fundal din motivul:
			           |%1';
			           |tr = 'Arka plan işi şu sebeplerden dolayı iptal edilemedi:
			           |%1'; 
			           |es_ES = 'No se ha podido cancelar una tarea de fondo a causa de: 
			           |%1'"), BriefErrorDescription(ErrorInformation));
	EndTry;
	
EndProcedure

#EndRegion


