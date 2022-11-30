
&AtClient
Procedure PathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter                  = NStr("en='(*.xml)|*.xml data file ';ru='Файл данных (*.xml)|*.xml'");
	FileDialog.Title               = NStr("en='Select a file';ru='Выберите файл'");
	FileDialog.Preview = False;
	FileDialog.DefaultExt              = "xml";
	FileDialog.FilterIndex           = 0;
	FileDialog.FullFileName          = PathToFile;
	FileDialog.Show(New NotifyDescription("PathToFileStartChoiceEnd", ThisObject, New Structure("FileDialog", FileDialog)));
EndProcedure

&AtClient
Procedure PathToFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileDialog = AdditionalParameters.FileDialog;
	If (SelectedFiles <> Undefined) Then
		PathToFile = FileDialog.FullFileName;
	EndIf;

EndProcedure

&AtClient
Procedure TemplatesImport(Command)
	If IsBlankString(PathToFile) Then
		CommonClientServer.MessageToUser(NStr("en='The document to be imported is not selected.';ru='Не выбран файл для загрузки.'"));
		Return
	EndIf;
	ExchangeFormat = GetForm("DataProcessor.UniversalDataEchangeXML.Form.ManagedForm",, ThisForm);
	ExchangeFormat.AtClient(Command);
	
	ExchangeFormat.ExchangeFileName = PathToFile;
	ExchangeFormat.Object.ExchangeMode = "Load";
	ExchangeFormat.ExecuteImportFromForm();
	ThisForm.FormOwner.Items.List.Refresh();
EndProcedure

&AtServerNoContext
Function GetRules(ExportObjectName)
	
	DataExchangeRules = Undefined;
	If ExportObjectName = "Catalogs.fmLoadTemplates" Then
		DataExchangeRules = Catalogs.ImportTemplates.GetTemplate("Rules");
	EndIf;
	
	Return DataExchangeRules;
		
EndFunction

#If NOT WebClient Then

&AtClient
Procedure TemplatesExport(Command)
	
	If IsBlankString(PathToFile) Then
		CommonClientServer.MessageToUser(NStr("en='The document to be imported is not selected.';ru='Не выбран файл для загрузки.'"));
		Return
	EndIf;
	
	RulesTemplate = GetRules(ExportObjectName);
	
	RulesFileName = TempFilesDir() + "ExcRules.xml";
	RulesTemplate.Write(RulesFileName);
	
	ExchangeFormat = GetForm("DataProcessor.UniversalDataEchangeXML.Form.ManagedForm",, ThisForm);
	
	ExchangeFormat.AtClient(Command);
	ExchangeFormat.DataFileName       = PathToFile;
	ExchangeFormat.Object.ExchangeRulesFileName = RulesFileName;
	ExchangeFormat.RulesFileName = RulesFileName;
	ExchangeFormat.ReadExchangeRules(ExchangeFormat);
	ExchangeFormat.Object.ReferencesList = ReferencesList;
	ExchangeFormat.ExecuteExportFromForm();

	DeleteFiles(RulesFileName); // удалим за собой мусор.
EndProcedure

#EndIf

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Возврат при получении формы для анализа.
		Return;
	EndIf;
	
	Parameters.Property("ExportObjectName", ExportObjectName);
	
	ReferencesList = Parameters.SelectedRows;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ReferencesList.Count() = 0 Then
		Items.FormExport.Enabled = False;
	EndIf;
EndProcedure



