///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var CommandToExecute;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.SectionName)
		AND Parameters.SectionName <> AdditionalReportsAndDataProcessorsClientServer.StartPageName() Then
		SectionRef = Common.MetadataObjectID(Metadata.Subsystems.Find(Parameters.SectionName));
	EndIf;
	
	DataProcessorsKind = AdditionalReportsAndDataProcessors.GetDataProcessorKindByKindStringPresentation(Parameters.Kind);
	If DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling Then
		AreAssignableDataProcessors = True;
		Title = NStr("ru = 'Команды заполнения объектов'; en = 'Object filling commands'; pl = 'Polecenia wypełnienia obiektów';de = 'Befehle zur Objektauffüllung';ro = 'Comenzile de completare a obiectelor';tr = 'Nesne doldurma komutları'; es_ES = 'Comando de la población del objeto'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		AreAssignableDataProcessors = True;
		AreReports = True;
		Title = NStr("ru = 'Отчеты'; en = 'Reports'; pl = 'Sprawozdania';de = 'Berichte';ro = 'Rapoarte';tr = 'Raporlar'; es_ES = 'Informes'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		AreAssignableDataProcessors = True;
		Title = NStr("ru = 'Дополнительные печатные формы'; en = 'Additional print forms'; pl = 'Dodatkowe drukarskie formy';de = 'Zusätzliche Druckformen';ro = 'Forme de listare suplimentare';tr = 'Ek baskı formları'; es_ES = 'Versiones impresas adicionales'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation Then
		AreAssignableDataProcessors = True;
		Title = NStr("ru = 'Команды создания связанных объектов'; en = 'Create related objects commands'; pl = 'Polecenia utworzenia obiektów powiązanych';de = 'Befehle für die Erstellung von verknüpften Objekten';ro = 'Comenzile de creare a obiectelor conexe';tr = 'Bağlantılı nesne oluşturma için komutlar'; es_ES = 'Comandos para crear objetos vinculados'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		AreGlobalDataProcessors = True;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дополнительные обработки (%1)'; en = 'Additional data processors (%1)'; pl = 'Dodatkowe opracowanie (%1)';de = 'Zusätzliche Datenprozessoren (%1)';ro = 'Procesări suplimentare (%1)';tr = 'Ek veri işlemcileri (%1)'; es_ES = 'Procesadores de datos adicionales (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		AreGlobalDataProcessors = True;
		AreReports = True;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дополнительные отчеты (%1)'; en = 'Additional reports (%1)'; pl = 'Dodatkowe sprawozdania (%1)';de = 'Zusätzliche Berichte (%1)';ro = 'Rapoarte suplimentare (%1)';tr = 'Ek raporlar (%1)'; es_ES = 'Informes adicionales (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	EndIf;
	
	If Parameters.Property("WindowOpeningMode") Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf;
	
	If AreAssignableDataProcessors Then
		Items.CustomizeList.Visible = False;
		
		RelatedObjects.LoadValues(Parameters.RelatedObjects.UnloadValues());
		If RelatedObjects.Count() = 0 Then
			Cancel = True;
			Return;
		EndIf;
		
		OwnerInfo = AdditionalReportsAndDataProcessorsCached.AssignedObjectFormParameters(Parameters.FormName);
		ParentMetadata = Metadata.FindByType(TypeOf(RelatedObjects[0].Value));
		If ParentMetadata = Undefined Then
			ParentRef = OwnerInfo.ParentRef;
		Else
			ParentRef = Common.MetadataObjectID(ParentMetadata);
		EndIf;
		If TypeOf(OwnerInfo) = Type("FixedStructure") Then
			IsObjectForm = OwnerInfo.IsObjectForm;
		Else
			IsObjectForm = False;
		EndIf;
	EndIf;
	
	FillDataProcessorsTable();
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If SelectedValue = "MyReportsAndDataProcessorsSetupDone" Then
		FillDataProcessorsTable();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCommandsTable

&AtClient
Procedure CommandsTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RunDataProcessorByParameters();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RunDataProcessor(Command)
	
	RunDataProcessorByParameters()
	
EndProcedure

&AtClient
Procedure CustomizeList(Command)
	FormParameters = New Structure("DataProcessorsKind, SectionRef");
	FillPropertyValues(FormParameters, ThisObject);
	OpenForm("CommonForm.MyReportsAndDataProcessorsSettings", FormParameters, ThisObject, False);
EndProcedure

&AtClient
Procedure CancelDataProcessorExecution(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillDataProcessorsTable()
	CommandsTypes = New Array;
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ClientMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.OpeningForm);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode);
	
	Query = AdditionalReportsAndDataProcessors.NewQueryByAvailableCommands(DataProcessorsKind, ?(AreGlobalDataProcessors, SectionRef, ParentRef), IsObjectForm, CommandsTypes);
	ResultTable = Query.Execute().Unload();
	CommandsTable.Load(ResultTable);
EndProcedure

&AtClient
Procedure RunDataProcessorByParameters()
	DataProcessorData = Items.CommandsTable.CurrentData;
	If DataProcessorData = Undefined Then
		Return;
	EndIf;
	
	CommandToExecute = New Structure(
		"Ref, Presentation, 
		|ID, StartupOption, ShowNotification, 
		|Modifier, RelatedObjects, IsReport, Kind");
	FillPropertyValues(CommandToExecute, DataProcessorData);
	If NOT AreGlobalDataProcessors Then
		CommandToExecute.RelatedObjects = RelatedObjects.UnloadValues();
	EndIf;
	CommandToExecute.IsReport = AreReports;
	CommandToExecute.Kind = DataProcessorsKind;
	
	If DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		AdditionalReportsAndDataProcessorsClient.OpenDataProcessorForm(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		Close();
		
	ElsIf DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		AdditionalReportsAndDataProcessorsClient.ExecuteDataProcessorClientMethod(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		Close();
		
	ElsIf DataProcessorsKind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm")
		AND DataProcessorData.Modifier = "PrintMXL" Then
		
		AdditionalReportsAndDataProcessorsClient.ExecutePrintFormOpening(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		Close();
		
	ElsIf DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode") Then
		
		// Changing form items
		Items.ExplainingDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполняется команда ""%1""...'; en = 'Executing command %1...'; pl = 'Wykonywanie polecenia ""%1""...';de = 'Ausführen des Befehls ""%1""...';ro = 'Are loc executarea comenzii ""%1""...';tr = '""%1"" komutu yürütülüyor...'; es_ES = 'Ejecutando el comando ""%1""...'"),
			DataProcessorData.Presentation);
		Items.Pages.CurrentPage = Items.DataProcessorExecutionPage;
		Items.CustomizeList.Visible = False;
		Items.RunDataProcessor.Visible = False;
		
		// Delaying the server call until the form state becomes consistent.
		AttachIdleHandler("ExecuteDataProcessorServerMethod", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataProcessorServerMethod()
	
	Job = RunBackgroundJob(CommandToExecute, UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("RunDataProcessorServerMethodCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServerNoContext
Function RunBackgroundJob(Val CommandToExecute, Val UUID)
	MethodName = "AdditionalReportsAndDataProcessors.ExecuteCommand";
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Доп. отчеты и обработки: Выполнение команды ""%1""'; en = 'Additional reports and data processors: executing command %1.'; pl = 'Dodatkowe sprawozdania i procedury przetwarzania: Wykonywanie polecenia ""%1""';de = 'Zusätzliche Berichte und Verarbeitung: Ausführung des Befehls ""%1""';ro = 'Rapoarte și procesări supl.: Executarea comenzii ""%1""';tr = 'Ek raporlar ve veri işlemcileri: ""%1"" komutu yürütülüyor'; es_ES = 'Informes adicionales y procesamientos: Realización de comandos ""%1""'"),
		CommandToExecute.Presentation);
	
	MethodParameters = New Structure("AdditionalDataProcessorRef, CommandID, RelatedObjects");
	MethodParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	MethodParameters.CommandID          = CommandToExecute.ID;
	MethodParameters.RelatedObjects             = CommandToExecute.RelatedObjects;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, MethodParameters, StartSettings);
EndFunction

&AtClient
Procedure RunDataProcessorServerMethodCompletion(Job, AdditionalParameters) Export
	If Job.Status = "Completed" Then
		// Showing a pop-up notification and closing this form.
		If CommandToExecute.ShowNotification Then
			ShowUserNotification(
				NStr("ru = 'Команда выполнена'; en = 'The operation is completed.'; pl = 'Polecenie wykonane';de = 'Befehl ausgeführt';ro = 'Comandă executată';tr = 'Komut yapıldı'; es_ES = 'Comando ejecutado'"),
				,
				CommandToExecute.Presentation);
		EndIf;
		If IsOpen() Then
			Close();
		EndIf;
		// Refreshing owner form.
		If IsObjectForm Then
			Try
				FormOwner.Read();
			Except
				// No action required.
			EndTry;
		EndIf;
		// Notifying other forms.
		ExecutionResult = GetFromTempStorage(Job.ResultAddress);
		NotifyForms = CommonClientServer.StructureProperty(ExecutionResult, "NotifyForms");
		If NotifyForms <> Undefined Then
			StandardSubsystemsClient.NotifyFormsAboutChange(NotifyForms);
		EndIf;
	Else
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Команда ""%1"" не выполнена:'; en = 'The ""%1"" operation is not performed:'; pl = 'Polecenie ""%1"" nie zostało wykonane:';de = 'Der Befehl ""%1"" wird nicht ausgeführt:';ro = 'Comanda ""%1"" nu este executată:';tr = 'Komut ""%1"" yürürülmedi:'; es_ES = 'Comando ""%1"" no ejecutado:'"),
			CommandToExecute.Presentation);
		If IsOpen() Then
			Close();
		EndIf;
		Raise Text + Chars.LF + Job.BriefErrorPresentation;
	EndIf;
EndProcedure

#EndRegion