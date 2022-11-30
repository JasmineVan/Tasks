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
	
	Manager = ExchangePlans[Parameters.Node.Metadata().Name];
	
	If Parameters.Node = Manager.ThisNode() Then
		Raise
			NStr("ru = 'Создание начального образа для данного узла невозможно.'; en = 'Cannot create an initial image for this node.'; pl = 'Nie można utworzyć obrazu początkowego dla tego węzła..';de = 'Es kann kein Anfangsbild für diesen Knoten erstellt werden.';ro = 'Nu se poate crea o imagine inițială pentru acest nod.';tr = 'Bu ünite için ilk resim oluşturulamıyor.'; es_ES = 'No se puede crear la imagen inicial para este nodo.'");
	Else
		InfobaseType = 0; // file base
		DBMSType = "";
		Node = Parameters.Node;
		CanCreateFileInfobase = True;
		If Common.IsLinuxServer() Then
			CanCreateFileInfobase = False;
		EndIf;
		
		LocaleCodes = GetAvailableLocaleCodes();
		FileModeInfobaseLanguage = Items.Find("FileModeInfobaseLanguage");
		ClientServerModeInfobaseLanguage = Items.Find("ClientServerModeInfobaseLanguage");
		
		For Each Code In LocaleCodes Do
			Presentation = LocaleCodePresentation(Code);
			FileModeInfobaseLanguage.ChoiceList.Add(Code, Presentation);
			ClientServerModeInfobaseLanguage.ChoiceList.Add(Code, Presentation);
		EndDo;
		
		Language = InfoBaseLocaleCode();
		
	EndIf;
	
	HasFilesInVolumes = False;
	
	If FilesOperations.HasFileStorageVolumes() Then
		HasFilesInVolumes = FilesOperationsInternal.HasFilesInVolumes();
	EndIf;
	
	WindowsOSServers = Common.IsWindowsServer();
	If Common.FileInfobase() Then
		Items.FileInfobaseFullNameLinux.Visible = NOT WindowsOSServers;
		Items.FullFileInfobaseName.Visible = WindowsOSServers;
	EndIf;
	
	If HasFilesInVolumes Then
		If WindowsOSServers Then
			Items.FullFileInfobaseName.AutoMarkIncomplete = True;
			Items.VolumesFilesArchivePath.AutoMarkIncomplete = True;
		Else
			Items.FileInfobaseFullNameLinux.AutoMarkIncomplete = True;
			Items.PathToVolumeFilesArchiveLinux.AutoMarkIncomplete = True;
		EndIf;
	Else
		Items.PathToVolumeFilesArchiveGroup.Visible = False;
	EndIf;
	
	If Not Common.FileInfobase() Then
		Items.VolumesFilesArchivePath.InputHint = NStr("ru = '\\имя сервера\resource\files.zip'; en = '\\server name\resource\files.zip'; pl = '\\server name\resource\files.zip';de = '\\ Servername \ Ressource \ Dateien.zip';ro = '\\server name\resource\files.zip';tr = '\\server name\resource\files.zip'; es_ES = '\\ nombre del servidor\recurso\archivos.zip'");
		Items.VolumesFilesArchivePath.ChoiceButton = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FormPages.CurrentPage = Items.RawData;
	Items.CreateInitialImage.Visible = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobaseVariantOnChange(Item)
	
	// Switch the parameters page.
	Pages = Items.Find("Pages");
	Pages.CurrentPage = Pages.ChildItems[InfobaseType];
	
	If ThisObject.InfobaseType = 0 Then
		Items.VolumesFilesArchivePath.InputHint = "";
		Items.VolumesFilesArchivePath.ChoiceButton = True;
	Else
		Items.VolumesFilesArchivePath.InputHint = NStr("ru = '\\имя сервера\resource\files.zip'; en = '\\server name\resource\files.zip'; pl = '\\server name\resource\files.zip';de = '\\ Servername \ Ressource \ Dateien.zip';ro = '\\server name\resource\files.zip';tr = '\\server name\resource\files.zip'; es_ES = '\\ nombre del servidor\recurso\archivos.zip'");
		Items.VolumesFilesArchivePath.ChoiceButton = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PathToVolumeFilesArchiveStartChoice(Item, ChoiceData, StandardProcessing)
	
	SaveFileHandler(
		Item,
		"WindowsVolumesFilesArchivePath",
		StandardProcessing,
		"files.zip",
		"Archives zip(*.zip)|*.zip");
	
EndProcedure

&AtClient
Procedure FileInfobaseFullNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SaveFileHandler(
		Item,
		"FullWindowsFileInfobaseName",
		StandardProcessing,
		"1Cv8.1CD",
		"Any file(*.*)|*.*");
	
EndProcedure

&AtClient
Procedure FileBaseFullNameOnChange(Item)
	
	FullWindowsFileInfobaseName = TrimAll(FullWindowsFileInfobaseName);
	PathStructure = CommonClientServer.ParseFullFileName(FullWindowsFileInfobaseName);
	If NOT IsBlankString(PathStructure.Path) Then
		PathToFile = PathStructure.Path;
		If IsBlankString(PathStructure.Extension) Then
			PathToFile = PathStructure.FullName;
			FullWindowsFileInfobaseName = CommonClientServer.AddLastPathSeparator(PathStructure.FullName);
			FullWindowsFileInfobaseName = FullWindowsFileInfobaseName + "1Cv8.1CD";
		EndIf;
		
		DirectoriesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(PathToFile, "\", True);
		
		If DirectoriesArray.Count() > 0 Then
			File = New File(DirectoriesArray[0]);
			
			CurrentArray = New Array;
			CurrentArray.Add(DirectoriesArray[0]);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("FullPath", File.FullName);
			AdditionalParameters.Insert("DirectoriesArray",
				CommonClientServer.ArraysDifference(DirectoriesArray, CurrentArray));
			
			Notification = New NotifyDescription("ExistenceCheckFileBaseFullNameCompletion", ThisObject, AdditionalParameters);
			File.BeginCheckingExistence(Notification);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateInitialImage(Command)
	
	ClearMessages();
	If InfobaseType = 0 AND NOT CanCreateFileInfobase Then
		
		Raise
			NStr("ru = 'Создание начального образа файловой информационной базы
			           |на данной платформе не поддерживается.'; 
			           |en = 'Creation of initial images for file infobases
			           |is not supported on this platform.'; 
			           |pl = 'Tworzenie obrazu początkowego
			           |bazy informacyjnej nie jest obsługiwane na tej platformie.';
			           |de = 'Die Erstellung des Startbildes der 
			           |Dateiinfobase wird auf dieser Plattform nicht unterstützt.';
			           |ro = 'Crearea imaginii inițiale a bazei de informații de tip fișier
			           |nu este susținută pe această platformă.';
			           |tr = 'Bu platformda veritabanı dosyasının 
			           |ilk resminin oluşturulması desteklenmemektedir.'; 
			           |es_ES = 'Creación de la imagen inicial de la
			           |infobase de archivos no se admite en esta plataforma.'");
	Else
		ProgressPercent = 0;
		ProgressAdditionalInformation = "";
		JobParameters = New Structure;
		JobParameters.Insert("Node", Node);
		JobParameters.Insert("WindowsVolumesFilesArchivePath", WindowsVolumesFilesArchivePath);
		JobParameters.Insert("PathToVolumeFilesArchiveLinux", PathToVolumeFilesArchiveLinux);
		
		If InfobaseType = 0 Then
			// File initial image.
			JobParameters.Insert("UUIDOfForm", UUID);
			JobParameters.Insert("Language", Language);
			JobParameters.Insert("FullWindowsFileInfobaseName", FullWindowsFileInfobaseName);
			JobParameters.Insert("FileInfobaseFullNameLinux", FileInfobaseFullNameLinux);
			JobParameters.Insert("JobDescription", NStr("ru = 'Создание файлового начального образа'; en = 'Create initial file image'; pl = 'Tworzenie plikowego obrazu początkowego';de = 'Erstellen eines Datei-Startimages';ro = 'Crearea imaginii inițiale a fișierelor';tr = 'Dosya başlangıç görüntüsü oluşturma'; es_ES = 'Crear una imagen inicial de archivo'"));
			JobParameters.Insert("ProcedureDescription", "FilesOperationsInternal.CreateFileInitialImageAtServer");
		Else
			// Server initial image.
			ConnectionString =
				"Srvr="""       + Server + """;"
				+ "Ref="""      + InfobaseName + """;"
				+ "DBMS="""     + DBMSType + """;"
				+ "DBSrvr="""   + DatabaseServer + """;"
				+ "DB="""       + DatabaseName + """;"
				+ "DBUID="""    + DatabaseUser + """;"
				+ "DBPwd="""    + UserPassword + """;"
				+ "SQLYOffs=""" + Format(DateOffset, "NG=") + """;"
				+ "Locale="""   + Language + """;"
				+ "SchJobDn=""" + ?(SetScheduledJobLock, "Y", "N") + """;";
			
			JobParameters.Insert("ConnectionString", ConnectionString);
			JobParameters.Insert("JobDescription", NStr("ru = 'Создание серверного начального образа'; en = 'Create initial server image'; pl = 'Tworzenie serwerowego obrazu początkowego';de = 'Erstellen eines Server-Startimages';ro = 'Crearea imaginii inițiale a serverului';tr = 'Sunucu tabanlı ilk görüntü oluşturma'; es_ES = 'Crear una imagen inicial de servidor'"));
			JobParameters.Insert("ProcedureDescription", "FilesOperationsInternal.CreateServerInitialImageAtServer");
		EndIf;
		Result = PrepareDataToCreateInitialImage(JobParameters, InfobaseType);
		If TypeOf(Result) = Type("Structure") Then
			If Result.DataReady Then
				JobParametersAddress = PutToTempStorage(JobParameters, UUID);
				NotifyDescription = New NotifyDescription("RunCreateInitialImage", ThisObject);
				If Result.ConfirmationRequired Then
					ShowQueryBox(NotifyDescription, Result.QuestionText, QuestionDialogMode.YesNo);
				Else
					ExecuteNotifyProcessing(NotifyDescription, DialogReturnCode.Yes);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExistenceCheckFileBaseFullNameCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		Notification = New NotifyDescription("CreateDirectoryCompletion", ThisObject, AdditionalParameters);
		BeginCreatingDirectory(Notification, AdditionalParameters.FullPath);
		Return;
	EndIf;
	
	ContinueExistenceCheckFileBaseFullName(AdditionalParameters.FullPath,
		AdditionalParameters.DirectoriesArray);
	
EndProcedure

&AtClient
Procedure ContinueExistenceCheckFileBaseFullName(FullPath, DirectoriesArray)
	If DirectoriesArray.Count() = 0 Then
		Return;
	EndIf;
	
	File = New File(FullPath + "\" + DirectoriesArray[0]);
			
	CurrentArray = New Array;
	CurrentArray.Add(DirectoriesArray[0]);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FullPath", File.FullName);
	NotificationParameters.Insert("DirectoriesArray",
		CommonClientServer.ArraysDifference(DirectoriesArray, CurrentArray));
	
	Notification = New NotifyDescription("ExistenceCheckFileBaseFullNameCompletion", ThisObject, NotificationParameters);
	File.BeginCheckingExistence(Notification);
EndProcedure

&AtClient
Procedure CreateDirectoryCompletion(DirectoryName, AdditionalParameters) Export
	
	ContinueExistenceCheckFileBaseFullName(DirectoryName, AdditionalParameters.DirectoriesArray);
	
EndProcedure

&AtClient
Procedure SaveFileHandler(
		Item,
		PropertyName,
		StandardProcessing,
		FileName,
		Filter = "")
	
	StandardProcessing = False;
	
	Context = New Structure;
	Context.Insert("Item",     Item);
	Context.Insert("PropertyName", PropertyName);
	Context.Insert("FileName",    FileName);
	Context.Insert("Filter",      Filter);
	
	Dialog = New FileDialog(FileDialogMode.Save);
	
	Dialog.Title = NStr("ru = 'Выберите файл для сохранения'; en = 'Select file to save'; pl = 'Wybierz plik, który chcesz zapisać';de = 'Wählen Sie eine Datei zum Speichern aus';ro = 'Selectați fișierul pentru salvare';tr = 'Kaydedilecek dosyayı seçin'; es_ES = ' Seleccione un archivo para guardar'");
	Dialog.Multiselect = False;
	Dialog.Preview = False;
	Dialog.Filter = Context.Filter;
	Dialog.FullFileName =
		?(ThisObject[Context.PropertyName] = "",
			Context.FileName,
			ThisObject[Context.PropertyName]);
	
	ChoiceDialogNotificationDetails = New NotifyDescription(
		"FileSaveHandlerAfterChoiceInDialog", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, Dialog);
	
EndProcedure

&AtClient
Procedure FileSaveHandlerAfterChoiceInDialog(SelectedFiles, Context) Export
	
	If SelectedFiles <> Undefined
		AND SelectedFiles.Count() = 1 Then
		
		ThisObject[Context.PropertyName] = SelectedFiles[0];
		If Context.Item = Items.FullFileInfobaseName Then
			FileBaseFullNameOnChange(Context.Item);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PrepareDataToCreateInitialImage(JobParameters, InfobaseType)
	
	// Writing the parameters of attaching node to constant.
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Cancel = False;
		
		DataExchangeCreationWizard = DataProcessors["DataExchangeCreationWizard"].Create();
		DataExchangeCreationWizard.Initializing(JobParameters.Node);
		
		Try
			DataProcessors["DataExchangeCreationWizard"].ExportConnectionSettingsForSubordinateDIBNode(
				DataExchangeCreationWizard);
		Except
			Cancel = True;
			WriteLogEvent(NStr("ru = 'Обмен данными'; en = 'Data exchange'; pl = 'Wymiana danych';de = 'Datenaustausch';ro = 'Schimb de date';tr = 'Veri alışverişi'; es_ES = 'Intercambio de datos'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		If Cancel Then
			Return Undefined;
		EndIf;
		
	EndIf;
	
	If InfobaseType = 0 Then
		// File initial image.
		// Function of processing, checking and preparing parameters.
		Result = FilesOperationsInternal.PrepareDataToCreateFileInitialImage(JobParameters);
	Else
		// Server initial image.
		// Function of processing, checking and preparing parameters.
		Result = FilesOperationsInternal.PrepareDataToCreateServerInitialImage(JobParameters);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure RunCreateInitialImage(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		ProgressPercent = 0;
		ProgressAdditionalInformation = "";
		GoToWaitPage();
		AttachIdleHandler("StartInitialImageCreation", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartInitialImageCreation()
	
	Result = CreateInitialImageAtServer(InfobaseType);
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Running" Then
		CompletionNotification = New NotifyDescription("CreateInitialImageAtServerCompletion", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.OutputProgressBar = True;
		IdleParameters.ExecutionProgressNotification = New NotifyDescription("CreateInitialImageAtServerProgress", ThisObject);;
		TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
	ElsIf Result.Status = "Completed" Then
		GoToWaitPage();
		ProgressPercent = 100;
		ProgressAdditionalInformation = "";
		// Go to the page with the result with a 1 sec delay.
		AttachIdleHandler("ExecuteGoResult", 1, True);
	Else
		Raise NStr("ru = 'Не удалось создать начальный образ по причине:'; en = 'Cannot create an initial image. Reason:'; pl = 'Tworzenie obrazu początkowego nie powiodło się z powodu:';de = 'Fehler beim Erstellen des ersten Images aufgrund von:';ro = 'Eșec la crearea imaginii inițiale din motivul:';tr = 'İlk görüntü aşağıdaki nedenle oluşturulamadı:'; es_ES = 'No se ha podido crear una imagen inicial a causa de:'") + " " + Result.BriefErrorPresentation; 
	EndIf;

EndProcedure

&AtClient
Procedure GoToWaitPage()
	Items.FormPages.CurrentPage = Items.InitialImageCreationWaiting;
	Items.CreateInitialImage.Visible = False;
EndProcedure

&AtServer
Function CreateInitialImageAtServer(Val Action)
	
	If IsTempStorageURL(JobParametersAddress) Then
		JobParameters = GetFromTempStorage(JobParametersAddress);
		If TypeOf(JobParameters) = Type("Structure") Then
			// Starting background job.
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
			ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;
			
			Return TimeConsumingOperations.ExecuteInBackground(JobParameters.ProcedureDescription, JobParameters, ExecutionParameters);
		EndIf;
	EndIf;
	
EndFunction

&AtClient
Procedure CreateInitialImageAtServerCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		ProgressPercent = 0;
		ProgressAdditionalInformation = NStr("ru = 'Действие отменено администратором.'; en = 'The operation is canceled by administrator.'; pl = 'Działanie zostało anulowane przez administratora.';de = 'Die Aktion wurde vom Administrator abgebrochen.';ro = 'Acțiunea este revocată de administrator.';tr = 'Eylem yönetici tarafından iptal edildi.'; es_ES = 'Acción cancelada por administrador.'");
		ExecuteGoResult();
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ProgressPercent = 0;
		Items.StatusDone.Title = NStr("ru = 'Не удалось создать начальный образ по причине:'; en = 'Cannot create an initial image. Reason:'; pl = 'Tworzenie obrazu początkowego nie powiodło się z powodu:';de = 'Fehler beim Erstellen des ersten Images aufgrund von:';ro = 'Eșec la crearea imaginii inițiale din motivul:';tr = 'İlk görüntü aşağıdaki nedenle oluşturulamadı:'; es_ES = 'No se ha podido crear una imagen inicial a causa de:'") + " " + Result.BriefErrorPresentation;
		ExecuteGoResult();
		Return;
	EndIf;
	
	ProgressPercent = 100;
	ProgressAdditionalInformation = "";
	ExecuteGoResult();
	
EndProcedure

&AtClient
Procedure CreateInitialImageAtServerProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ProgressStructure = Progress.Progress;
		ProgressPercent = ProgressStructure.Percent;
		ProgressAdditionalInformation = ProgressStructure.Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteGoResult()
	Items.FormPages.CurrentPage = Items.Result;
	Items.CreateInitialImage.Visible = False;
	
	If ProgressPercent = 100 Then
		CompleteInitialImageCreation(Node);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CompleteInitialImageCreation(ExchangeNode)
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CompleteInitialImageCreation(ExchangeNode);
	EndIf;
	
EndProcedure

#EndRegion
