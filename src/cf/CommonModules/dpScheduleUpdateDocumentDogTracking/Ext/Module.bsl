
Procedure UpdateDocumentDogTrackingonschedule() Export
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdateDocumentDogTracking);
	Cancel = False;
	//UpdateDocumentDogTracking();
	If Cancel = TRUE Then
		Return;
	EndIf;
	
	If Not Constants.UseFilePreview.Get() Then
		Return;
	EndIf;
	
	Filter = New Structure("Key, State", Metadata.ScheduledJobs.UpdateDocumentDogTracking.Key, BackgroundJobState.Active); 
	ArrayJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If ArrayJobs.Count() > 1 Then
		Return;	
	EndIf;
	
	WriteLogEvent(NStr("en='Files.Update files contents';ru='Files.Обновление содержимого файлов';vi='Tệp.Cập nhật thành phần tệp'"), 
			EventLogLevel.Information, , ,
			Nstr("ru = 'Начато регламентное задание по обновлению содержимого файлов'; en = 'Started routine update file contents'; vi = 'Bắt đầu tập tin cập nhật thường xuyên nội dung'"));
	
	//InformationRegisters.FilesContents.UpdateFilesContents();
			
	WriteLogEvent(NStr("en='Files.Update files contents';ru='Files.Обновление содержимого файлов';vi='Tệp.Cập nhật thành phần tệp'"), 
			EventLogLevel.Information, , ,
			Nstr("ru = 'Закончено регламентное задание по обновлению содержимого файлов'; en = 'Finished routine update file contents'; vi = 'Hoàn thành thói quen cập tập tin nội dung'"));

EndProcedure

Procedure UpdateDocumentDogTracking() Export
	DocumentObject = Documents.DogTracking;
	ListForm = DocumentObject.GetListForm("ListForm");
	ListForm.RefreshDisplay();
EndProcedure

Function UseFilePreview() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.UseFilePreview.Get();
	
EndFunction