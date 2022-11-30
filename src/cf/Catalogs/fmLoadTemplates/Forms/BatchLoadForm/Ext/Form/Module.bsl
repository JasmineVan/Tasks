
&AtClient
Procedure DirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FileChoice = New FileDialog(FileDialogMode.ChooseDirectory);
	FileChoice.Multiselect = False;
	FileChoice.Directory = Directory;
	FileChoice.Title = NStr("en='Select an excel file folder...';ru='Выберите каталог файлов excel...'");
	FileChoice.Show(New NotifyDescription("DirectoryStartChoiceEnd", ThisObject, New Structure("FileChoice", FileChoice)));
EndProcedure

&AtClient
Procedure DirectoryStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileChoice = AdditionalParameters.FileChoice;
	If (SelectedFiles <> Undefined) Then
		Directory = FileChoice.Directory;
		ReadDirectory(Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure DirectoryOpening(Item, StandardProcessing)
	StandardProcessing = False;
	#If NOT WebClient Then
	If ValueIsFilled(Directory) Then
		Try
			System("explorer "+Directory);
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the folder.';ru='Не удалось открыть каталог!'"));
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The folder path is not specified.';ru='Не указан путь к каталогу!'"));
	EndIf;
	#EndIf
EndProcedure

&AtClient
Procedure Load(Command)
	
	If NOT CheckFilling() Then
		Return;
	EndIf;
	
	LoadedDocuments.Clear();
	
	// Пойдем по файлам циклом.
	For Each CurFile In Files Do
		If NOT CurFile.Check Then Continue; EndIf;
		// Переберем листы.
		For Each CurSheet In Sheets Do
			If NOT CurSheet.Check Then Continue; EndIf;
			// Шаблон 1.
			CurTemplate = ?(ValueIsFilled(CurSheet.Template1), CurSheet.Template1, Template1);
			If ValueIsFilled(CurTemplate) Then
				AttributesStructure = GenerateAttributes(CurTemplate, Scenario, BeginOfPeriod);
				Attributes.Clear();
				For Each CurRow In AttributesStructure Do
					NewLine = Attributes.Add();
					FillPropertyValues(NewLine, CurRow);
				EndDo;
				ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(CurFile.File, CurSheet.Sheet, CurTemplate, Attributes, UpdateExistingDocuments);
				If TypeOf(ParametersStructure)=Type("Structure") Then
					// Выведем загруженные документы.
					If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
						For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
							NewLine=LoadedDocuments.Add();
							NewLine.Document=CurDocument;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			// Шаблон 2.
			CurTemplate = ?(ValueIsFilled(CurSheet.Template2), CurSheet.Template2, Template2);
			If ValueIsFilled(CurTemplate) Then
				AttributesStructure = GenerateAttributes(CurTemplate, Scenario, BeginOfPeriod);
				Attributes.Clear();
				For Each CurRow In AttributesStructure Do
					NewLine = Attributes.Add();
					FillPropertyValues(NewLine, CurRow);
				EndDo;
				ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(CurFile.File, CurSheet.Sheet, CurTemplate, Attributes, UpdateExistingDocuments);
				If TypeOf(ParametersStructure)=Type("Structure") Then
					// Выведем загруженные документы.
					If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
						For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
							NewLine=LoadedDocuments.Add();
							NewLine.Document=CurDocument;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			// Шаблон 3.
			CurTemplate = ?(ValueIsFilled(CurSheet.Template3), CurSheet.Template3, Template3);
			If ValueIsFilled(CurTemplate) Then
				AttributesStructure = GenerateAttributes(CurTemplate, Scenario, BeginOfPeriod);
				Attributes.Clear();
				For Each CurRow In AttributesStructure Do
					NewLine = Attributes.Add();
					FillPropertyValues(NewLine, CurRow);
				EndDo;
				ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(CurFile.File, CurSheet.Sheet, CurTemplate, Attributes, UpdateExistingDocuments);
				If TypeOf(ParametersStructure)=Type("Structure") Then
					// Выведем загруженные документы.
					If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
						For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
							NewLine=LoadedDocuments.Add();
							NewLine.Document=CurDocument;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			// Шаблон 4.
			CurTemplate = ?(ValueIsFilled(CurSheet.Template4), CurSheet.Template4, Template4);
			If ValueIsFilled(CurTemplate) Then
				AttributesStructure = GenerateAttributes(CurTemplate, Scenario, BeginOfPeriod);
				Attributes.Clear();
				For Each CurRow In AttributesStructure Do
					NewLine = Attributes.Add();
					FillPropertyValues(NewLine, CurRow);
				EndDo;
				ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(CurFile.File, CurSheet.Sheet, CurTemplate, Attributes, UpdateExistingDocuments);
				If TypeOf(ParametersStructure)=Type("Structure") Then
					// Выведем загруженные документы.
					If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
						For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
							NewLine=LoadedDocuments.Add();
							NewLine.Document=CurDocument;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			// Шаблон 5.
			CurTemplate = ?(ValueIsFilled(CurSheet.Template5), CurSheet.Template5, Template5);
			If ValueIsFilled(CurTemplate) Then
				AttributesStructure = GenerateAttributes(CurTemplate, Scenario, BeginOfPeriod);
				Attributes.Clear();
				For Each CurRow In AttributesStructure Do
					NewLine = Attributes.Add();
					FillPropertyValues(NewLine, CurRow);
				EndDo;
				ParametersStructure = fmExcelFormatProcessingClient.LoadExcelFile(CurFile.File, CurSheet.Sheet, CurTemplate, Attributes, UpdateExistingDocuments);
				If TypeOf(ParametersStructure)=Type("Structure") Then
					// Выведем загруженные документы.
					If ParametersStructure.Property("SuccessfullyLoadedDocuments") AND TypeOf(ParametersStructure.SuccessfullyLoadedDocuments)=Type("Array") Then
						For Each CurDocument In ParametersStructure.SuccessfullyLoadedDocuments Do
							NewLine=LoadedDocuments.Add();
							NewLine.Document=CurDocument;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If LoadedDocuments.Count()>0 Then
		Items.GroupPages.CurrentPage=Items.GroupPageLoadedDocuments;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GenerateAttributes(LoadTemplate, Scenario, BeginOfPeriod)
	
	// Заполним реквизитами со способом считывания "Фикс. значения" для возможности перевыбора.
	Attributes = New Array();
	For Each CurRow In LoadTemplate.LoadSettings Do
		If CurRow.ReadMethod = Enums.fmReadMethods.FixedValue Then
			NewLine = New Structure("Attribute, Value, TSName");
			FillPropertyValues(NewLine, CurRow);
			If CurRow.Attribute="Scenario" Then
				NewLine.Value = Scenario;
			ElsIf CurRow.Attribute="BeginOfPeriod" Then
				NewLine.Value = BeginOfPeriod;
			Else
				NewLine.Value = CurRow.FixedValue;
			EndIf;
			Attributes.Add(NewLine);
		EndIf;
	EndDo;
	Return Attributes;
	
EndFunction // СформироватьРеквизиты()

&AtClient
Procedure ReadDirectory(Command)
	If ValueIsFilled(Directory) Then
		Files.Clear();
		#If WebClient Then
		NotDescr = New NotifyDescription("Next_End", ThisObject, New Structure);
		BeginAttachingFileSystemExtension(NotDescr);
		#Else
		NotDesc = New NotifyDescription("ReadDirectory_End", ThisObject);
		BeginFindingFiles(NotDesc,Directory, "*.xls", True);
		#EndIf
	Else
		CommonClientServer.MessageToUser(NStr("en='The folder path is not specified.';ru='Не указан путь к каталогу!'"));
	EndIf;
EndProcedure

&AtClient
Procedure Next_End(Result, AddPar) Export
	
	If NOT Result Then
		//устанавливаем
		Notify2 = New NotifyDescription("Next_End2", ThisObject, New Structure);
		BeginInstallFileSystemExtension(Notify2);
	Else
		NotDesc = New NotifyDescription("ReadDirectory_End", ThisObject);
		BeginFindingFiles(NotDesc,Directory, "*.xls", True);
	EndIf;
	
EndProcedure
 
&AtClient
Procedure Next_End2(Result, AddPar) Export
	
	Notify3 = New NotifyDescription("Next_End3", ThisObject, New Structure);
	BeginAttachingFileSystemExtension(Notify3);
	
EndProcedure

&AtClient
Procedure Next_End3(Result, AddPar) Export
	
	//если не удалось установить - то повторный вызов подключения будет неудачный
	If NOT Result Then
		//сообщаем об ошибке и прерываем работу программы
		Raise NStr("ru = 'Ошибка. Ваш браузер не поддерживает работу с файлами.'; en = 'Error - working with files isn't supported by your browser'");
	Else
		NotDesc = New NotifyDescription("ReadDirectory_End", ThisObject);
		BeginFindingFiles(NotDesc,Directory, "*.xls", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadDirectory_End(FilesArray, Parameter) Export
	
	For Each File In FilesArray Do
		NewLine = Files.Add();
		NewLine.File = File.FullName;
		NewLine.Check = True;
	EndDo;
	If Files.Count()>0 Then
		If ValueIsFilled(ReferenceFile) Then
			If Files.FindRows(New Structure("File", ReferenceFile)).Count()=0 Then
				ReferenceFile = Files[0].File;
				ReadSheets(Undefined);
			EndIf;
		Else
			ReferenceFile = Files[0].File;
			ReadSheets(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DirectoryOnChange(Item)
	ReadDirectory(Undefined);
EndProcedure

&AtClient
Procedure ReadSheets(Command)
	
	// Доступ из 1С к Excel производится посредством OLE.
	Try
		AppExcel = New COMObject("Excel.Application"); 
	Except
		CommonClientServer.MessageToUser(NStr("en='File error! ';ru='Ошибка при работе с файлом! '") + ErrorDescription()); 
		Return;
	EndTry;
	
	// Откроем файл.
	If ValueIsFilled(ReferenceFile) Then
		Try
			ExcelFile = AppExcel.WorkBooks.Open(ReferenceFile);
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the file.';ru='Не удалось открыть файл '") + ErrorDescription());
			fmExcelFormatProcessingClient.CloseExcel(AppExcel);
			Return;
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The file path is not specified.';ru='Не указан путь к файлу!'"));
		fmExcelFormatProcessingClient.CloseExcel(AppExcel);
		Return;
	EndIf;
	
	// Создадим список листов.
	Sheets.Clear();
	SheetCount = ExcelFile.Sheets.Count;
	For Num=1 To SheetCount Do
		CurRow = Sheets.Add();
		CurRow.Sheet=ExcelFile.Sheets(Num).Name;
	EndDo;
		
	fmExcelFormatProcessingClient.CloseExcel(AppExcel);
	
EndProcedure // ПрочитатьЛисты()

&AtClient
Procedure ReferenceFileStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FileChoice = New FileDialog(FileDialogMode.Open);
	FileChoice.Multiselect = False;
	FileChoice.Filter = "Excel (*.xls;*.xlsx)|*.xls;*.xlsx";
	FileChoice.Title = NStr("en='Select an excel file...';ru='Выберите файл excel...'");
	FileChoice.Show(New NotifyDescription("ReferenceFileStartChoiceEnd", ThisObject, New Structure("FileChoice", FileChoice)));
EndProcedure

&AtClient
Procedure ReferenceFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileChoice = AdditionalParameters.FileChoice;
	If (SelectedFiles <> Undefined) Then
		ReferenceFile = FileChoice.SelectedFiles[0];
		ReadSheets(Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure ReferenceFileOpening(Item, StandardProcessing)
	StandardProcessing = False;
	If ValueIsFilled(ReferenceFile) Then
		Try
			NotDesc = New NotifyDescription("ReferenceFileOpenEnd", ThisObject);
			BeginRunningApplication(NotDesc, ReferenceFile);
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to open the file.';ru='Не удалось открыть файл!'"));
		EndTry;
	Else
		CommonClientServer.MessageToUser(NStr("en='The file path is not specified.';ru='Не указан путь к файлу!'"));
	EndIf;
EndProcedure

&AtClient
Procedure ReferenceFileOpenEnd(Res, Parameter) Export
	
EndProcedure

&AtClient
Procedure LoadDocumentsChoice(Item, SelectedRow, Field, StandardProcessing)
	CurRow = Items.LoadedDocuments.CurrentData;
	If NOT CurRow=Undefined Then
		ShowValue( , CurRow.Document);
	EndIf;
EndProcedure

&AtClient
Procedure SelectFiles(Command)
	For Each CurRow In Files Do
		CurRow.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ResetFiles(Command)
	For Each CurRow In Files Do
		CurRow.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure SelectSheets(Command)
	For Each CurRow In Sheets Do
		CurRow.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ResetSheets(Command)
	For Each CurRow In Sheets Do
		CurRow.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure FillByDefault(Command)
	For Each CurRow In Sheets Do
		CurRow.Template1 = Template1;
		CurRow.Template2 = Template2;
		CurRow.Template3 = Template3;
		CurRow.Template4 = Template4;
		CurRow.Template5 = Template5;
	EndDo;
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	SaveSettingsServer();
EndProcedure

&AtServer
Procedure SaveSettingsServer()
	LoadSetting = InformationRegisters.fmBatchLoadSettingsExcel.CreateRecordSet();
	LoadSetting.Filter.Scenario.Set(Scenario);
	LoadSetting.Filter.Directory.Set(Directory);
	LoadSetting.Read();
	LoadSetting.Clear();
	NewRecord = LoadSetting.Add();
	NewRecord.Scenario = Scenario;
	NewRecord.Directory = Directory;
	NewRecord.Template1 = Template1;
	NewRecord.Template2 = Template2;
	NewRecord.Template3 = Template3;
	NewRecord.Template4 = Template4;
	NewRecord.Template5 = Template5;
	For Each CurRow In Sheets Do
		NewRecord = LoadSetting.Add();
		NewRecord.Scenario = Scenario;
		NewRecord.Directory = Directory;
		FillPropertyValues(NewRecord, CurRow);
	EndDo;
	LoadSetting.Write();
EndProcedure

&AtClient
Procedure LoadSettings(Command)
	LoadSettingsServer();
EndProcedure

&AtServer
Procedure LoadSettingsServer()
	LoadSetting = InformationRegisters.fmBatchLoadSettingsExcel.CreateRecordSet();
	LoadSetting.Filter.Scenario.Set(Scenario);
	LoadSetting.Filter.Directory.Set(Directory);
	LoadSetting.Read();
	For Each CurRow In LoadSetting Do
		If ValueIsFilled(CurRow.Sheet) Then
			Rows = Sheets.FindRows(New Structure("Sheet", CurRow.Sheet));
			If NOT Rows.Count()=0 Then
				FillPropertyValues(Rows[0], CurRow);
			EndIf;
		Else
			Template1 = CurRow.Template1;
			Template2 = CurRow.Template2;
			Template3 = CurRow.Template3;
			Template4 = CurRow.Template4;
			Template5 = CurRow.Template5;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(Directory) Then
		ReadDirectory(Undefined);
	EndIf;
	If ValueIsFilled(ReferenceFile) Then
		ReadSheets(Undefined);
	EndIf;
	LoadSettingsServer();
EndProcedure

&AtServer
Procedure OnLoadingDataFromSettingsAtServer(Settings)
	FillMonthByDate(ThisForm, "BeginOfPeriod", "BegOfPeriodAsString");
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Редактирование месяца строкой.

&AtClient
Procedure BegOfPeriodAsStringOnChange(Item)
	fmCommonUseClient.MonthInputOnChange(ThisForm, "BeginOfPeriod", "BegOfPeriodAsString", Modified);
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringStartChoice(Item, ChoiceData, StandardProcessing)
	fmCommonUseClient.MonthInputStartChoice(ThisForm, ThisForm, "BeginOfPeriod", "BegOfPeriodAsString");
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringTuning(Item, Direction, StandardProcessing)
	fmCommonUseClient.MonthInputTuning(ThisForm, "BeginOfPeriod", "BegOfPeriodAsString", Direction, Modified);
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	fmCommonUseClient.MonthInputTextAutoComplete(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure BegOfPeriodAsStringTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	fmCommonUseClient.MonthInputTextEditEnd(Text, ChoiceData, StandardProcessing);
EndProcedure

// Заполняет реквизит представлением месяца, хранящегося в другом реквизите.
//
// Параметры:
//		РедактируемыйОбъект
//		ПутьРеквизита - Строка, путь к реквизиту, содержащего дату.
//		ПутьРеквизитаПредставления - Строка, путь к реквизиту в который помещается представление месяца.
//
&AtServer
Procedure FillMonthByDate(EditedObject, AttributePath, AttributePathPresentation)
	Value = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePath);
	CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePathPresentation, Format(Value, "DF='MMMM yyyy'"));
EndProcedure









