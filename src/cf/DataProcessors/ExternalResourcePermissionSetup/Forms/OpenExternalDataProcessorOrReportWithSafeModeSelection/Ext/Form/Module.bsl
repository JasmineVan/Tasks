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
	
	SafeMode = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Notification = New NotifyDescription("DataProcessorFileNameStartChoiceAfterPutFile", ThisObject);
	BeginPutFile(Notification, , , True, ThisObject.UUID);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(DataProcessorFileName) Or Not ValueIsFilled(DataProcessorFileAddress) Then
		Common.MessageToUser(NStr("ru = 'Укажите файл внешнего отчета или обработки.'; en = 'Specify an external report file or a data processor file.'; pl = 'Specify an external report file or a data processor file.';de = 'Specify an external report file or a data processor file.';ro = 'Specify an external report file or a data processor file.';tr = 'Specify an external report file or a data processor file.'; es_ES = 'Specify an external report file or a data processor file.'"),, 
			"DataProcessorFileName");
		Cancel = True;
	Else
		FileProperties = CommonClientServer.ParseFullFileName(DataProcessorFileName);
		If Lower(FileProperties.Extension) <> Lower(".epf") AND Lower(FileProperties.Extension) <> Lower(".erf") Then
			Common.MessageToUser(NStr("ru = 'Выбранный файл не является внешним отчетом или обработкой.'; en = 'Selected file is not external report or data processor.'; pl = 'Selected file is not external report or data processor.';de = 'Selected file is not external report or data processor.';ro = 'Selected file is not external report or data processor.';tr = 'Selected file is not external report or data processor.'; es_ES = 'Selected file is not external report or data processor.'"),,
				"DataProcessorFileName");
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(SafeMode) Then
		Common.MessageToUser(NStr("ru = 'Укажите безопасный режим для подключения внешнего модуля.'; en = 'Specify the safe mode for the external module attachment.'; pl = 'Specify the safe mode for the external module attachment.';de = 'Specify the safe mode for the external module attachment.';ro = 'Specify the safe mode for the external module attachment.';tr = 'Specify the safe mode for the external module attachment.'; es_ES = 'Specify the safe mode for the external module attachment.'"),, 
			"SafeMode");
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataProcessorFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New NotifyDescription("DataProcessorFileNameStartChoiceAfterPutFile", ThisObject);
	BeginPutFile(Notification, , , True, ThisObject.UUID);
	
EndProcedure

&AtClient
Procedure DataProcessorFileNameStartChoiceAfterPutFile(Result, Address, SelectedFileName, Context) Export
	
	If Not ValueIsFilled(Address) Then
		Return;
	EndIf;
	
	DataProcessorFileName = SelectedFileName;
	DataProcessorFileAddress = Address;
	
	FileProperties = CommonClientServer.ParseFullFileName(DataProcessorFileName);
	If Lower(FileProperties.Extension) <> Lower(".epf") AND Lower(FileProperties.Extension) <> Lower(".erf") Then
		ShowMessageBox(, NStr("ru = 'Выбранный файл не является внешним отчетом или обработкой.'; en = 'Selected file is not external report or data processor.'; pl = 'Selected file is not external report or data processor.';de = 'Selected file is not external report or data processor.';ro = 'Selected file is not external report or data processor.';tr = 'Selected file is not external report or data processor.'; es_ES = 'Selected file is not external report or data processor.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AttachAndOpen(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;	
	
	FileProperties = CommonClientServer.ParseFullFileName(DataProcessorFileName);
	IsExternalDataProcessor = (Lower(FileProperties.Extension) = Lower(".epf"));
	
	ExternalObjectName = AttachOnServer(IsExternalDataProcessor);
	If IsExternalDataProcessor Then
		ExternalFormName = "ExternalDataProcessor." + ExternalObjectName + ".Form";
	Else
		ExternalFormName = "ExternalReport." + ExternalObjectName + ".Form";
	EndIf;
	
	OpenForm(ExternalFormName, , FormOwner);
	Close();
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AttachOnServer(IsExternalDataProcessor)
	
	VerifyAccessRights("Administration", Metadata);
	
	If IsExternalDataProcessor Then
		Manager = ExternalDataProcessors;
	Else
		Manager = ExternalReports;
	EndIf;
	
	Return Manager.Connect(DataProcessorFileAddress,, SafeMode); // CAC:552; CAC:553 Secure connection.
	
EndFunction

#EndRegion
