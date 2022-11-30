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
	If NOT PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ThisObject.Items.ExportDirectory.ChoiceButton = False;
		SSLAvailable = False;
	Else
		SSLAvailable = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectExportDirectorySuggested(FileSystemExtensionAttached, AdditionalParameters) Export
	
	If FileSystemExtensionAttached Then
		
		SelectFile = New FileDialog(FileDialogMode.ChooseDirectory);
		SelectFile.Multiselect = False;
		SelectFile.Title = NStr("ru = 'Выбор каталога экспорта'; en = 'Select export directory'; pl = 'Select export directory';de = 'Select export directory';ro = 'Select export directory';tr = 'Select export directory'; es_ES = 'Select export directory'");
		
		NotifyDescription = New NotifyDescription("SelectDirectoryDialogCompletion", ThisObject, Undefined);
		FileSystemClient.ShowSelectionDialog(NotifyDescription, SelectFile);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	If SSLAvailable Then
		NotifyDescription = New NotifyDescription("SelectExportDirectorySuggested", ThisObject);
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ModuleFileSystemClient.AttachFileOperationsExtension(NotifyDescription);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteExport(Command)
    
    HasErrors = False;
    
    If NOT ValueIsFilled(ExportPeriodStartDate) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodStartDate";
        UserMessage.Text = NStr("ru = 'Значение параметра ""Дата начала"" не заполнено.
			|Экспорт невозможен.'; 
			|en = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.'; 
			|pl = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.';
			|de = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.';
			|ro = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.';
			|tr = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.'; 
			|es_ES = 'The value of the ""Start date"" parameter is not filled in.
			|Cannot export.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If NOT ValueIsFilled(ExportPeriodEndDate) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodEndDate";
        UserMessage.Text = NStr("ru = 'Значение параметра ""Дата окончания"" не заполнено.
			|Экспорт невозможен.'; 
			|en = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.'; 
			|pl = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.';
			|de = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.';
			|ro = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.';
			|tr = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.'; 
			|es_ES = 'The value of the ""End date"" parameter is not filled in.
			|Cannot export.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If NOT ValueIsFilled(ExportDirectory) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportDirectory";
        UserMessage.Text = NStr("ru = 'Значение параметра ""Каталог экспорта"" не заполнено.
			|Экспорт невозможен.'; 
			|en = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.'; 
			|pl = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.';
			|de = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.';
			|ro = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.';
			|tr = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.'; 
			|es_ES = 'Value of the ""Export directory"" parameter is not filled in.
			|Cannot export.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
     If NOT ValueIsFilled(ArchiveName) Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ArchiveName";
        UserMessage.Text = NStr("ru = 'Значение параметра ""Имя архива"" не заполнено.
			|Экспорт невозможен.'; 
			|en = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.'; 
			|pl = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.';
			|de = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.';
			|ro = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.';
			|tr = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.'; 
			|es_ES = 'The value of the ""Archive name"" parameter is not filled in.
			|Cannot export.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
        
    If ValueIsFilled(ExportPeriodStartDate) AND ValueIsFilled(ExportPeriodEndDate) AND ExportPeriodStartDate >= ExportPeriodEndDate Then
        
        UserMessage = New UserMessage;
        UserMessage.Field = "ExportPeriodStartDate";
        UserMessage.Text = NStr("ru = 'Значение параметра ""Дата начала"" больше или равно значения параметры ""Дата окончания"".
			|Экспорт невозможен.'; 
			|en = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.'; 
			|pl = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.';
			|de = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.';
			|ro = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.';
			|tr = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.'; 
			|es_ES = 'Value of the ""Start date"" parameter is equal to or greater than the value of the ""End date"" parameter.
			|Cannot export.'");
        UserMessage.Message();
        
        HasErrors = True;
        
    EndIf;
    
    If HasErrors Then
        Return;
    EndIf;
            
	StorageAddress = PutToTempStorage(Undefined, ThisObject.UUID);
	ExportParameters = New Structure;
	ExportParameters.Insert("StartDate", ThisObject.ExportPeriodStartDate);
	ExportParameters.Insert("EndDate", ThisObject.ExportPeriodEndDate);
	ExportParameters.Insert("StorageAddress", StorageAddress);
	ExportParameters.Insert("Profile", Profile);
	RunExportAtServer(ExportParameters);
	
	BinaryData = GetFromTempStorage(StorageAddress);
	DeleteFromTempStorage(StorageAddress);
    
    If BinaryData <> Undefined Then
        BinaryData.Write(ThisObject.ExportDirectory + GetClientPathSeparator() + ThisObject.ArchiveName + ".zip");
    Else
        UserMessage = New UserMessage;
        UserMessage.Text = NStr("ru = 'За указанный период нет замеров. Файл архива не сформирован.'; en = 'There are no measurements over the specified period. Archive file is not generated.'; pl = 'There are no measurements over the specified period. Archive file is not generated.';de = 'There are no measurements over the specified period. Archive file is not generated.';ro = 'There are no measurements over the specified period. Archive file is not generated.';tr = 'There are no measurements over the specified period. Archive file is not generated.'; es_ES = 'There are no measurements over the specified period. Archive file is not generated.'") + Chars.LF;
        UserMessage.Message();
    EndIf;
    	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RunExportAtServer(Parameters)
	PerformanceMonitor.PerformanceMonitorDataExport(Undefined, Parameters);	
EndProcedure

&AtClient
Procedure SelectDirectoryDialogCompletion(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined Then
		ThisObject.ExportDirectory = SelectedFiles[0];
	EndIf;
		
EndProcedure


#EndRegion