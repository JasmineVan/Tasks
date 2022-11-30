///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns description of the print form found in the collection.
// If the description is not found, returns Undefined.
// The function is used only inside the Print procedure.
//
// Parameters:
//  PrintFormsCollection - ValueTable - an internal parameter passed to the Print procedure.
//  ID - String - a print form ID.
//
// Returns:
//  ValueTableRow - found description of the print form.
Function PrintFormInfo(PrintFormsCollection, ID) Export
	Return PrintFormsCollection.Find(Upper(ID), "UpperCaseName");
EndFunction

// Checks whether printing of a template is required.
// The function is used only inside the Print procedure.
//
// Parameters:
//  PrintFormsCollection - ValueTable - an internal parameter passed to the Print procedure.
//  TemplateName - String - a name of the template being checked.
//
// Returns:
//  Boolean - True, if the template requires printing.
Function TemplatePrintRequired(PrintFormsCollection, TemplateName) Export
	
	Return PrintFormsCollection.Find(Upper(TemplateName), "UpperCaseName") <> Undefined;
	
EndFunction

// Adds a spreadsheet document to a print form collection.
// The procedure is used only inside the Print procedure.
//
// Parameters:
//  PrintFormsCollection - ValueTable - an internal parameter passed to the Print procedure.
//  TemplateName - String - a template name.
//  TemplateSynonym - String - a template presentation.
//  SpreadsheetDocument - SpreadsheetDocument - a document print form.
//  Picture - Picture - a print form icon.
//  FullTemplatePath - String - a path to the template in the metadata tree, for example
//                                   "Document.ProformaInvoice.PF_MXL_InvoiceOrder".
//                                   If you do not specify this parameter, editing the template in 
//                                   the PrintDocuments form is not available to users.
//  PrintFormFileName - String - a name used when saving a print form to a file.
//                        - Map:
//                           * Key - AnyRef - a reference to the print object.
//                           * Value - String - a file name.
Procedure OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym, SpreadsheetDocument,
	Picture = Undefined, FullTemplatePath = "", PrintFormFileName = Undefined) Export
	
	PrintFormDetails = PrintFormsCollection.Find(Upper(TemplateName), "UpperCaseName");
	If PrintFormDetails <> Undefined Then
		PrintFormDetails.SpreadsheetDocument = SpreadsheetDocument;
		PrintFormDetails.TemplateSynonym = TemplateSynonym;
		PrintFormDetails.Picture = Picture;
		PrintFormDetails.FullTemplatePath = FullTemplatePath;
		PrintFormDetails.PrintFormFileName = PrintFormFileName;
	EndIf;
	
EndProcedure

// Sets an object printing area in a spreadsheet document.
// Used to connect an area in a spreadsheet document to a print object (reference).
// The procedure is called when generating the next print form area in a spreadsheet document.
// 
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a print form.
//  RowNumberStart - Number - a position of the beginning of the next area in the document.
//  PrintObjects - ValueList - a print object list.
//  Ref - AnyRef - a print object.
Procedure SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Ref) Export
	
	Item = PrintObjects.FindByValue(Ref);
	If Item = Undefined Then
		AreaName = "Document_" + Format(PrintObjects.Count() + 1, "NZ=; NG=");
		PrintObjects.Add(Ref, AreaName);
	Else
		AreaName = Item.Presentation;
	EndIf;
	
	RowNumberEnd = SpreadsheetDocument.TableHeight;
	SpreadsheetDocument.Area(RowNumberStart, , RowNumberEnd, ).Name = AreaName;
	
	If Not PrintSettings().UseSignaturesAndSeals Then
		Return;
	EndIf;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		IsSignatureAndSeal = False;
		For Each NameOfAreaWithSignatureAndSeal In AreaNamesPrefixesWithSignatureAndSeal() Do
			If StrFind(Drawing.Name, NameOfAreaWithSignatureAndSeal) > 0 Then
				IsSignatureAndSeal = True;
				Break;
			EndIf;
		EndDo;
		If Not IsSignatureAndSeal Then
			Continue;
		EndIf;
		If Drawing.DrawingType = SpreadsheetDocumentDrawingType.Picture AND StrFind(Drawing.Name, "_Document_") = 0 Then
			Drawing.Name = Drawing.Name + "_" + AreaName;
		EndIf;
	EndDo;
	
EndProcedure

// Returns an external print form list.
//
// Parameters:
//  FullMetadataObjectName - String - a full name of the metadata object to obtain the list of print 
//                                        forms for.
//
// Returns:
//  ValueList - a collection of print forms:
//   * Value - String - a print form ID.
//   * Presentation - String - a print form presentation.
Function PrintFormsListFromExternalSources(FullMetadataObjectName) Export
	
	ExternalPrintForms = New ValueList;
	If Not IsBlankString(FullMetadataObjectName) AND FullMetadataObjectName <> "Catalog.MetadataObjectIDs" Then
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnReceiveExternalPrintFormList(ExternalPrintForms, FullMetadataObjectName);
		EndIf;
	EndIf;
	
	Return ExternalPrintForms;
	
EndFunction

// Returns a list of print commands for the specified print form.
//
// Parameters:
//  Form - ManagedForm, String - a form or a full form name for getting a list of print commands.
//  ObjectsList - Array - a collection of metadata objects whose print commands are to be used when 
//                            drawing up a list of print commands for the specified form.
// Returns:
//  ValueTable - see description in CreatePrintCommandsCollection().
//
Function FormPrintCommands(Form, ObjectsList = Undefined) Export
	
	If TypeOf(Form) = Type("ManagedForm") Then
		FormName = Form.FormName;
	Else
		FormName = Form;
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(FormName);
	If MetadataObject <> Undefined AND Not Metadata.CommonForms.Contains(MetadataObject) Then
		MetadataObject = MetadataObject.Parent();
	Else
		MetadataObject = Undefined;
	EndIf;

	If MetadataObject <> Undefined Then
		MORef = Common.MetadataObjectID(MetadataObject);
	EndIf;
	
	PrintCommands = CreatePrintCommandsCollection();
	
	StandardProcessing = True;
	PrintManagementOverridable.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
	
	If StandardProcessing Then
		If ObjectsList <> Undefined Then
			FillPrintCommandsForObjectsList(ObjectsList, PrintCommands);
		ElsIf MetadataObject = Undefined Then
			Return PrintCommands;
		Else
			IsDocumentJournal = Common.IsDocumentJournal(MetadataObject);
			ListSettings = New Structure;
			ListSettings.Insert("PrintCommandsManager", Common.ObjectManagerByFullName(MetadataObject.FullName()));
			ListSettings.Insert("AutoFilling", IsDocumentJournal);
			If IsDocumentJournal Then
				PrintManagementOverridable.OnGetPrintCommandListSettings(ListSettings);
			EndIf;
			
			If ListSettings.AutoFilling Then
				If IsDocumentJournal Then
					FillPrintCommandsForObjectsList(MetadataObject.RegisteredDocuments, PrintCommands);
				EndIf;
			Else
				PrintManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
				PrintCommandsToAdd = CreatePrintCommandsCollection();
				PrintManager.AddPrintCommands(PrintCommandsToAdd);
				
				For Each PrintCommand In PrintCommandsToAdd Do
					If PrintCommand.PrintManager = Undefined Then
						PrintCommand.PrintManager = MetadataObject.FullName();
					EndIf;
					FillPropertyValues(PrintCommands.Add(), PrintCommand);
				EndDo;
				
				If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
					ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
					ModuleAdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, MetadataObject.FullName());
				EndIf;
				
				AttachedReportsAndDataProcessors = AttachableCommands.AttachedObjects(MORef);
				FoundItems = AttachedReportsAndDataProcessors.FindRows(New Structure("AddPrintCommands", True));
				For Each AttachedObject In FoundItems Do
					AttachedObject.Manager.AddPrintCommands(PrintCommands);
					AddedCommands = PrintCommands.FindRows(New Structure("PrintManager", Undefined));
					For Each Command In AddedCommands Do
						Command.PrintManager = AttachedObject.FullName;
					EndDo;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	For Each PrintCommand In PrintCommands Do
		If PrintCommand.Order = 0 Then
			PrintCommand.Order = 50;
		EndIf;
		PrintCommand.AdditionalParameters.Insert("AddExternalPrintFormsToSet", PrintCommand.AddExternalPrintFormsToSet);
	EndDo;
	
	If MetadataObject <> Undefined Then
		SetPrintCommandsSettings(PrintCommands, MORef);
	EndIf;
	
	PrintCommands.Sort("Order Asc, Presentation Asc");
	
	NameParts = StrSplit(FormName, ".");
	ShortFormName = NameParts[NameParts.Count()-1];
	
	// Filter by form names
	For RowNumber = -PrintCommands.Count() + 1 To 0 Do
		PrintCommand = PrintCommands[-RowNumber];
		FormsList = StrSplit(PrintCommand.FormsList, ",", False);
		If FormsList.Count() > 0 AND FormsList.Find(ShortFormName) = Undefined Then
			PrintCommands.Delete(PrintCommand);
		EndIf;
	EndDo;
	
	DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands, Form);
	
	Return PrintCommands;
	
EndFunction

// Creates a blank table with description of print commands.
// The table of print commands is passed to the AddPrintCommands procedures placed in the 
// configuration object manager modules listed in the procedure
// PrintManagerOverridable.OnDefineObjectsWithPrintCommands.
// 
// Returns:
//  ValueTable - description of print commands:
//
//  * ID - String - a print command ID. The print manager uses this ID to determine a print form to 
//                             be generated.
//                             Example: "InvoiceOrder".
//
//                                        To print multiple print forms, you can specify all their 
//                                        IDs at once (as a comma-separated string or an array of strings), for example:
//                                         "InvoiceOrder,LetterOfGuarantee".
//
//                                        To set a number of copies for a print form, duplicate its 
//                                        ID as many times as the number of copies you want 
//                                        generated. Note. The order of print forms in the set 
//                                        matches the order of print form IDs specified in this 
//                                        parameter. Example (2 proforma invoices + 1 letter of guarantee):
//                                        "InvoiceOrder,InvoiceOrder,LetterOfGuarantee".
//
//                                        A print form ID can contain an alternative print manager 
//                                        if it is different from the print manager specified in the 
//                                         PrintManager parameter, for example: "InvoiceOrder,Processing.PrintForm.LetterOfGuarantee".
//
//                                        In this example, LetterOfGuarantee is generated in print manager
//                                        Processing.PrintForm, and InvoiceOrder is generated in the 
//                                        print manager specified in the PrintManager parameter.
//
//                  - Array - a list of print command IDs.
//
//  * Presentation - String            - a command presentation in the Print menu.
//                                         Example: "Proforma invoice".
//
//  * PrintManager - String           - (optional) name of the object whose manager module contains 
//                                        the Print procedure that generates spreadsheet documents for this command.
//                                        Default value is a name of the object manager module.
//                                         Example: "Document.ProformaInvoice".
//  * PrintObjectsTypes - Array - (optional) list of object types, for which the print command is 
//                                        used. The parameter is used for print commands in document 
//                                        journals, which require checking the passed object type before calling the print manager.
//                                        If a list is blank, whenever the list of print commands is 
//                                        generated in a document journal, it is filled with an 
//                                        object type, from which the print command was imported.
//
//  * Handler    - String            - (optional) command client handler executed instead of the 
//                                        standard Print command handler. It is used, for example, 
//                                        when the print form is generated on the client.
//                                        Format "<CommonModuleName>.<ProcedureName>" is used when 
//                                        the procedure is in a common module.
//                                        The <ProcedureName> format is used when the procedure is 
//                                        placed in the main form module of a report or a data processor specified in PrintManager.
//                                        Example:
//                                          PrintCommand.Handler = "_DemoStandardSubsystemsClient.PrintProformaInvoices";
//                                        An example of handler in the form module:
//                                          // Generates a print form <print form presentation>.
//                                          //
//                                          // Parameters:
//                                          //   PrintParameters - Structure - a print form info.
//                                          //       * PrintObjects - Array - an array of selected object references.
//                                          //       * Form - ManagedForm - a form, from which the print command is called.
//                                          //       * AdditionalParameters - Structure - additional print parameters.
//                                          // Other structure keys match the columns of the PrintCommands table,
//                                          // for more information, see the PrintManager.CreatePrintCommandsCollection function.
//                                          //
//                                          &AtClient
//                                          Function <FunctionName> (PrintParameters) Export
//                                          	// Print handler.
//                                          EndFunction
//                                        Remember that the handler is called using the Calculate 
//                                        method, so only a function can act as a handler.
//                                        The return value of the function is not used by the subsystem.
//
//  * Order - Number - (optional) a value from 1 to 100 that indicates the position of the command 
//                                        among other commands. The Print menu commands are sorted 
//                                        by the Order field, then by a presentation.
//                                        The default value is 50.
//
//  * Picture - Picture - (optional) a picture displayed next to the command in the Print menu.
//                                         Example: PictureLib.PDFFormat.
//
//  * FormsList - String - (optional) comma-separated names of forms, in which the command is to be 
//                                        displayed. If the parameter is not specified, the print 
//                                        command is available in all object forms that include the Print subsystem.
//                                         Example: "DocumentForm".
//
//  * Location - String - (optional) name of the form command bar, to which the print command is to 
//                                        be placed. Use this parameter only when the form has more 
//                                        than one Print submenu. In other cases, specify the print 
//                                        command location in the form module upon the method call.
//                                        PrintManager.OnCreateAtServer.
//                                        
//  * FormHeader - String - (optional) an arbitrary string overriding the standard header of the 
//                                        Print documents form.
//                                         Example: "Customize set".
//
//  * FunctionalOptions - String - (optional) comma-separated names of functional options that 
//                                        influence the print command availability.
//
//  * VisibilityConditions - Array - (optional) collection of command visibility conditions 
//                                        depending on the context. The command visibility conditions are specified using the
//                                        AddCommandVisibilityCondition procedure.
//                                        If the parameter is not specified, the command is visible regardless of the context.
//                                        
//  * CheckPostingBeforePrint - Boolean - (optional) shows whether the document posting check is 
//                                        performed before printing. If at least one unposted 
//                                        document is selected, a posting dialog box appears before executing the print command.
//                                        The print command is not executed for unposted documents.
//                                        If the parameter is not specified, the posting check is not performed.
//
//  * SkipPreview - Boolean - (optional) shows whether documents are sent directly to a printer 
//                                        without the print preview. If the parameter is not 
//                                        specified, the print command opens the "Print documents" preview form.
//
//  * SaveFormat - SpreadsheetDocumentFileType - (optional) used for quick saving of a print form 
//                                        (without additional actions) to non-MXL formats.
//                                        If the parameter is not specified, the print form is saved to an MXL format.
//                                         Example: SpreadsheetDocumentFileType.PDF.
//
//                                        In this example, selecting a print command opens a PDF 
//                                        document.
//
//  * OverrideCopiesUserSettings - Boolean - (optional) shows whether the option to save or restore 
//                                        the number of copies selected by user for printing in the 
//                                        PrintDocuments form is to be disabled. If the parameter is 
//                                        not specified, the option of saving or restoring settings will be applied upon opening the form.
//                                        PrintDocuments.
//
//  * SupplementSetWithExternalPrintForms - Boolean - (optional) shows whether the document set is 
//                                        to be supplemented with all external print forms connected 
//                                        to the object (the AdditionalReportsAndDataProcessors subsystem). 
//                                        If the parameter is not specified, external print forms are not added to the set.
//
//  * FixedSet - Boolean - (optional) shows whether users can change the document set.
//                                         If the parameter is not specified, the user can exclude 
//                                        some print forms from the set in the PrintDocuments form 
//                                        and change the number of copies.
//
//  * AdditionalParameters - Structure - (optional) arbitrary parameters to pass to the print manager.
//
//  * DontWriteToForm - Boolean - (optional) shows whether object writing before the print command 
//                                        execution is disabled. This parameter is used in special circumstances. 
//                                        If the parameter is not specified, the object is written 
//                                        when the object form has a modification flag.
//
//  * FilesExtensionRequired - Boolean - (optional) shows whether attaching of the file extension is 
//                                        required before executing the command. If the parameter is 
//                                        not specified, the file system extension is not attached.
//
Function CreatePrintCommandsCollection() Export
	
	Result = New ValueTable;
	
	// details
	Result.Columns.Add("ID", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	
	//////////
	// Options (optional parameters).
	
	// Print manager
	Result.Columns.Add("PrintManager", Undefined);
	Result.Columns.Add("PrintObjectsTypes", New TypeDescription("Array"));
	
	// Alternative command handler.
	Result.Columns.Add("Handler", New TypeDescription("String"));
	
	// presentation
	Result.Columns.Add("Order", New TypeDescription("Number"));
	Result.Columns.Add("Picture", New TypeDescription("Picture"));
	// Comma-separated names of forms for placing commands.
	Result.Columns.Add("FormsList", New TypeDescription("String"));
	Result.Columns.Add("PlacingLocation", New TypeDescription("String"));
	Result.Columns.Add("FormCaption", New TypeDescription("String"));
	// Comma-separated names of functional options that affect the command visibility.
	Result.Columns.Add("FunctionalOptions", New TypeDescription("String"));
	
	// Dynamic visibility conditions.
	Result.Columns.Add("VisibilityConditions", New TypeDescription("Array"));
	
	// Posting check
	Result.Columns.Add("CheckPostingBeforePrint", New TypeDescription("Boolean"));
	
	// Output
	Result.Columns.Add("SkipPreview", New TypeDescription("Boolean"));
	Result.Columns.Add("SaveFormat"); // SpreadsheetDocumentFileType of set settings
	
	// 
	Result.Columns.Add("OverrideCopiesUserSetting", New TypeDescription("Boolean"));
	Result.Columns.Add("AddExternalPrintFormsToSet", New TypeDescription("Boolean"));
	Result.Columns.Add("FixedSet", New TypeDescription("Boolean")); // restricting set changes additional parameters
	
	// 
	Result.Columns.Add("AdditionalParameters", New TypeDescription("Structure"));
	
	// Special command execution mode. By default, the modified object is written before executing the 
	// command.
	Result.Columns.Add("DontWriteToForm", New TypeDescription("Boolean"));
	
	// For using office document templates in the web client.
	Result.Columns.Add("FileSystemExtensionRequired", New TypeDescription("Boolean"));
	
	// For internal use.
	Result.Columns.Add("HiddenByFunctionalOptions", New TypeDescription("Boolean"));
	Result.Columns.Add("UUID", New TypeDescription("String"));
	Result.Columns.Add("Disabled", New TypeDescription("Boolean"));
	Result.Columns.Add("CommandNameAtForm", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

// Sets visibility conditions of the print command on the form, depending on the context.
//
// Parameters:
//  PrintCommand - ValueTableRow - the PrintCommands collection item in the AddPrintCommands 
//                                           procedure. See description in the CreatePrintCommandsCollection function.
//  Attribute - String - an object attribute name.
//  Value - Arbitrary - an object attribute value.
//  ComparisonMethod - ComparisonType - a value comparison kind. Possible kinds:
//                                           Equal, NotEqual, Greater, GreaterOrEqual, Less, LessOrEqual, InList, and NotInList.
//                                           The default value is Equal.
//
Procedure AddCommandVisibilityCondition(PrintCommand, Attribute, Value, Val ComparisonMethod = Undefined) Export
	If ComparisonMethod = Undefined Then
		ComparisonMethod = ComparisonType.Equal;
	EndIf;
	VisibilityCondition = New Structure;
	VisibilityCondition.Insert("Attribute", Attribute);
	VisibilityCondition.Insert("ComparisonType", ComparisonMethod);
	VisibilityCondition.Insert("Value", Value);
	PrintCommand.VisibilityConditions.Add(VisibilityCondition);
EndProcedure

// It is used when transferring a template (metadata object) of a print form to another object.
// It is intended to be called in the procedure for filling in the update data (for the deferred handler).
// Registers a new address of a template to process.
//
// Parameters:
//  TemplateName   - String - a new template name in the format
//                         "Document.<DocumentName>.<TemplateName>"
//                         "DataProcessor.<DataProcessorName>.<TemplateName>"
//                         "CommonTemplate.<TemplateName>".
//  Parameters - Structure - see InfobaseUpdate.MainProcessingMarkParameters. 
//
Procedure RegisterNewTemplateName(TemplateName, Parameters) Export
	TemplateNameParts = TemplateNameParts(TemplateName);
	
	RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
	RecordSet.Filter.TemplateName.Set(TemplateNameParts.TemplateName);
	RecordSet.Filter.Object.Set(TemplateNameParts.ObjectName);
	
	InfobaseUpdate.MarkForProcessing(Parameters, RecordSet);
EndProcedure

// It is used when transferring a template (metadata object) of a print form to another object.
// It is intended to be called in the deferred update handler.
// Transfers user data related to the template to a new address.
//
// Parameters:
//  Templates     - Map - info about previous and new template names in the format
//                              "Document.<DocumentName>.<TemplateName>"
//                              "DataProcessor.<DataProcessorName>.<TemplateName>"
//                              "CommonTemplate.<TemplateName>":
//   * Key     - String - a new template name.
//   * Value - String - a previous template name.
//
//  Parameters - Structure - parameters passed to the deferred update handler.
//
Procedure TransferUserTemplates(Templates, Parameters) Export
	
	DataForProcessing = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	While DataForProcessing.Next() Do
		NewTemplateName = DataForProcessing.Object + "." + DataForProcessing.TemplateName;
		PreviousTemplateName = Templates[NewTemplateName];
		TemplateNameParts = TemplateNameParts(PreviousTemplateName);
		
		RecordManager = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		RecordManager.TemplateName = TemplateNameParts.TemplateName;
		RecordManager.Object = TemplateNameParts.ObjectName;
		RecordManager.Read();
		
		If RecordManager.Selected() Then
			RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
			RecordSet.Filter.TemplateName.Set(DataForProcessing.TemplateName);
			RecordSet.Filter.Object.Set(DataForProcessing.Object);
			Record = RecordSet.Add();
			Record.TemplateName = DataForProcessing.TemplateName;
			Record.Object = DataForProcessing.Object;
			FillPropertyValues(Record, RecordManager, , "TemplateName,Object");
			InfobaseUpdate.WriteData(RecordSet);
			RecordManager.Delete();
		EndIf;
	EndDo;
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	
EndProcedure

// Provides an additional access profile "Edit, send by email, save print forms to file (additional)".
// For use in the OnFillSuppliedAccessGroupsProfiles procedure of the AccessManagementOverridable module.
//
// Parameters:
//  ProfilesDetails - Array - see AccessManagementOverridable.OnFillSuppliedAccessGroupsProfiles. 
//
Procedure FillProfileEditPrintForms(ProfilesDetails) Export
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	ProfileDetails = ModuleAccessManagement.NewAccessGroupProfileDescription();;
	ProfileDetails.ID = "70179f20-2315-11e6-9bff-d850e648b60c";
	ProfileDetails.Description = NStr("ru = 'Редактирование, отправка по почте, сохранение в файл печатных форм (дополнительно)'; en = 'Edit, send by email,  and save print forms to file (additionally)'; pl = 'Edycja, wysyłanie na e-mail, zapisywanie do pliku formularzy wydruku (opcjonalnie)';de = 'Bearbeitung, Versand per Post, Speichern von gedruckten Formularen in einer Datei (optional)';ro = 'Editarea, trimiterea prin poștă, salvarea în fișier a formelor de tipar (suplimentar)';tr = 'Düzenleme, posta ile gönderme, basılı form dosyasına kaydetme (ek olarak)'; es_ES = 'Edición, envío por correo, guarda en el archivo de los formularios de impresión (adicional)'",
		Metadata.DefaultLanguage.LanguageCode);
	ProfileDetails.Details = NStr("ru = 'Дополнительно назначается пользователям, которым должна быть доступна возможность редактирования,
		|перед печатью, отправка по почте и сохранение в файл сформированных печатных форм.'; 
		|en = 'Assign to users whose duties include editing,
		|sending by email, and saving print forms to file.'; 
		|pl = 'Dodatkowo przypisuje się użytkownikom, którym powinna być dostępna możliwość edycji,
		|przed wydrukowaniem, wysyłanie pocztą i zapisywanie do pliku uformowanych formularzy wydruku.';
		|de = 'Zusätzlich wird es den Benutzern zugewiesen, in der Lage zu sein, die Formulare
		|vor dem Drucken zu bearbeiten, sie per Mail zu versenden und in einer Datei zu speichern.';
		|ro = 'Suplimentar este atribuită utilizatorilor care trebuie să aibă acces la opțiunea de editare,
		|înainte de imprimare, trimiterea prin poștă și salvarea în fișier a formelor de tipar generate.';
		|tr = 'Ayrıca, 
		|yazdırmadan önce düzenleme, posta ile gönderme ve oluşturulan yazdırılan formların bir dosyasına kaydetme seçeneği olan kullanıcılara atanır.'; 
		|es_ES = 'Se establece adicionalmente para los usuarios a los que debe estar disponible la posibilidad de editar 
		|antes de imprimir, el envío por correo y guardar en el archivo los formularios de impresión generados.'", Metadata.DefaultLanguage.LanguageCode);
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// Adds a new area record to the TemplateAreas parameter.
//
// Adds a new area record to the TemplateAreas parameter.
//
// Parameters:
//   OfficeDocumentTemplateAreas - Array - a set of areas (array of structures) of an office document template.
//   AreaName - String - name of the area being added.
//   AreaType - String - an area type:
//    Header;
//    Footer;
//    Shared;
//    TableRow;
//    List.
//
// Example:
//	Function OfficeDocumentTemplateAreas()
//	
//		Areas = New Structure;
//	
//		PrintManager.AddAreaDetails(Areas, "Header",	"Header");
//		PrintManager.AddAreaDetails(Areas, "Footer",	"Footer");
//		PrintManager.AddAreaDetails(Areas, "Title",			"Total");
//	
//		Area Return;
//	
//	EndFunction
//
Procedure AddAreaDetails(OfficeDocumentTemplateAreas, Val AreaName, Val AreaType) Export
	
	NewArea = New Structure;
	
	NewArea.Insert("AreaName", AreaName);
	NewArea.Insert("AreaType", AreaType);
	
	OfficeDocumentTemplateAreas.Insert(AreaName, NewArea);
	
EndProcedure

// Gets all data required for printing within a single call: object template data, binary template 
// data, and template area description.
// Used for calling print forms based on office document templates from client modules.
//
// Parameters:
//   PrintManagerName - String - a name for accessing the object manager, for example, Document.<Document name>.
//   TemplatesNames - String - names of templates used for print form generation.
//   DocumentsContent - Array - references to infobase objects (all references must be of the same type).
//
// Returns:
//  Map - a collection of references to objects and their data:
//   * Key - AnyRef - reference to an infobase object.
//   * Value - Structure - a template and data:
//       ** Key - String - a template name.
//       ** Value - Structure - object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	TemplatesNamesArray = StrSplit(TemplatesNames, ", ", False);
	
	ObjectManager = Common.ObjectManagerByFullName(PrintManagerName);
	TemplatesAndData = ObjectManager.GetPrintInfo(DocumentsComposition, TemplatesNamesArray);
	TemplatesAndData.Insert("LocalPrintFileFolder", Undefined); // For backward compatibility.
	
	If NOT TemplatesAndData.Templates.Property("TemplateTypes") Then
		TemplatesAndData.Templates.Insert("TemplateTypes", New Map); // For backward compatibility.
	EndIf;
	
	Return TemplatesAndData;
	
EndFunction

// Returns a print form template by the full path to the template.
//
// Parameters:
//  TemplatePath - String - a full path to the template in the following format:
//                         "Document.<DocumentName>.<TemplateName>"
//                         "DataProcessor.<DataProcessorName>.<TemplateName>"
//                         "CommonTemplate.<TemplateName>".
// Returns:
//  SpreadsheetDocument - for a template of the MXL type.
//  BinaryData - for office document templates.
//
Function PrintFormTemplate(PathToTemplate) Export
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Макет ""%1"" не существует. Операция прервана.'; en = 'Layout %1 does not exist. Operation terminated.'; pl = 'Makieta ""%1"" nie istnieje. Operacja została przerwana.';de = 'Layout ""%1"" existiert nicht. Vorgang abgebrochen.';ro = 'Macheta ""%1"" nu există. Operație întreruptă.';tr = '""%1"" Şablonu bulunamadı. İşlem iptal edildi.'; es_ES = 'Modelo ""%1"" no existe. Operación cancelada.'"), PathToTemplate);
	PathParts = StrSplit(PathToTemplate, ".", True);
	If PathParts.Count() <> 2 AND PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	QueryText = 
	"SELECT
	|	UserPrintTemplates.Template AS Template,
	|	UserPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Object = &Object
	|	AND UserPrintTemplates.TemplateName LIKE &TemplateName
	|	AND UserPrintTemplates.Use";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", ObjectName);
	Query.Parameters.Insert("TemplateName", TemplateName + "%");
	
	Selection = Query.Execute().Select();
	
	TemplatesList = New Map;
	While Selection.Next() Do
		TemplatesList.Insert(Selection.TemplateName, Selection.Template.Get());
	EndDo;
	
	SearchNames = TemplateNames(TemplateName);
	
	For Each SearchName In SearchNames Do
		FoundTemplate = TemplatesList[SearchName];
		If FoundTemplate <> Undefined Then
			Return FoundTemplate;
		EndIf;
	EndDo;
	
	IsCommonTemplate = StrSplit(ObjectName, ".").Count() = 1;
	
	TemplatesCollection = Metadata.CommonTemplates;
	If Not IsCommonTemplate Then
		MetadataObject = Metadata.FindByFullName(ObjectName);
		If MetadataObject = Undefined Then
			Raise ErrorText;
		EndIf;
		TemplatesCollection = MetadataObject.Templates;
	EndIf;
	
	For Each SearchName In SearchNames Do
		If TemplatesCollection.Find(SearchName) <> Undefined Then
			If IsCommonTemplate Then
				Return GetCommonTemplate(SearchName);
			Else
				SetSafeModeDisabled(True);
				SetPrivilegedMode(True);
				Return Common.ObjectManagerByFullName(ObjectName).GetTemplate(SearchName);
			EndIf;
		EndIf;
	EndDo;
	
	Raise ErrorText;
	
EndFunction

// Checks whether a user template is used instead of the supplied one.
//
// Parameters:
//  TemplatePath - String - a full path to the template in the following format:
//                         "Document.<DocumentName>.<TemplateName>"
//                         "DataProcessor.<DataProcessorName>.<TemplateName>"
//                         "CommonTemplate.<TemplateName>".
// Returns:
//  Boolean - True if a user template is used.
//
Function UserTemplateUsed(TemplatePath) Export
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Макет ""%1"" не существует. Операция прервана.'; en = 'Layout %1 does not exist. Operation terminated.'; pl = 'Makieta ""%1"" nie istnieje. Operacja została przerwana.';de = 'Layout ""%1"" existiert nicht. Vorgang abgebrochen.';ro = 'Macheta ""%1"" nu există. Operație întreruptă.';tr = '""%1"" Şablonu bulunamadı. İşlem iptal edildi.'; es_ES = 'Modelo ""%1"" no existe. Operación cancelada.'"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 AND PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	QueryText = 
	"SELECT
	|	UserPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Object = &Object
	|	AND UserPrintTemplates.TemplateName LIKE &TemplateName";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", ObjectName);
	Query.Parameters.Insert("TemplateName", TemplateName + "%");
	
	Selection = Query.Execute().Select();
	
	TemplatesList = New Map;
	While Selection.Next() Do
		TemplatesList.Insert(Selection.TemplateName, True);
	EndDo;
	
	SearchNames = TemplateNames(TemplateName);
	
	For Each SearchName In SearchNames Do
		FoundTemplate = TemplatesList[SearchName];
		If FoundTemplate <> Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Checks if the supplied template was changed compared to the previous configuration version.
//
// Parameters:
//  TemplatePath - String - a full path to the template in the following format:
//                         "Document.<DocumentName>.<TemplateName>"
//                         "DataProcessor.<DataProcessorName>.<TemplateName>"
//                         "CommonTemplate.<TemplateName>".
// Returns:
//  Boolean - True, if the template was changed.
//
Function SuppliedTemplateChanged(TemplatePath) Export
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Макет ""%1"" не существует. Операция прервана.'; en = 'Layout %1 does not exist. Operation terminated.'; pl = 'Makieta ""%1"" nie istnieje. Operacja została przerwana.';de = 'Layout ""%1"" existiert nicht. Vorgang abgebrochen.';ro = 'Macheta ""%1"" nu există. Operație întreruptă.';tr = '""%1"" Şablonu bulunamadı. İşlem iptal edildi.'; es_ES = 'Modelo ""%1"" no existe. Operación cancelada.'"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 AND PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	MetadataObject = Common.MetadataObjectID(ObjectName);
	
	QueryText = 
	"SELECT
	|	SuppliedPrintTemplates.PreviousCheckSum <> """"
	|		AND SuppliedPrintTemplates.Checksum <> SuppliedPrintTemplates.PreviousCheckSum AS Changed,
	|	SuppliedPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.SuppliedPrintTemplates AS SuppliedPrintTemplates
	|WHERE
	|	SuppliedPrintTemplates.Object = &Object
	|	AND SuppliedPrintTemplates.TemplateName LIKE &TemplateName
	|	AND SuppliedPrintTemplates.TemplateVersion = &TemplateVersion";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", MetadataObject);
	Query.Parameters.Insert("TemplateName", TemplateName + "%");
	Query.Parameters.Insert("TemplateVersion", Metadata.Version);
	
	Selection = Query.Execute().Select();
	
	TemplatesList = New Map;
	While Selection.Next() Do
		TemplatesList.Insert(Selection.TemplateName, Selection.Changed);
	EndDo;
	
	SearchNames = TemplateNames(TemplateName);
	
	For Each SearchName In SearchNames Do
		Changed = TemplatesList[SearchName];
		If Changed <> Undefined Then
			Return Changed;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Switches the use of a user template to a configuration template.
// It is applied when a print form template of the configuration or an output algorithm are changed 
// without backward compatibility support with a template of previous configuration version.
// To be used in update handlers.
//
// In general, when changing templates and print form generation procedures, you need to consider 
// that templates can be changed by users (they can take a standard template from the configuration 
// and add there a static text, change its font, color, and cell design that does not require 
// processing by configuration algorithms).
//
// In some cases, exact order of filling forms is more important than compatibility with possible 
// user changes in previous version templates (for example, it applies to strictly regulated print 
// forms. If their use is violated, regulatory authorities can impose fines, refuse to conduct 
// operations, tax deductions, and so on. Users are not allowed to reduce the number of fields in the form and rearrange them).
// Examples of such forms are a proforma invoice, UTD, and UCD created on its base, cash vouchers 
// (CV-1 and CV-2), and a payment order.
// When a user has a changed template, it must be disabled upon update to generate these print forms 
// correctly.
// 
//
// Parameters:
//  TemplatePath - String - a full path to the template in the following format:
//                         "Document.<DocumentName>.<TemplateName>"
//                         "DataProcessor.<DataProcessorName>.<TemplateName>"
//                         "CommonTemplate.<TemplateName>".
//
Procedure DisableUserTemplate(PathToTemplate) Export
	
	StringParts = StrSplit(PathToTemplate, ".", True);
	If StringParts.Count() <> 2 AND StringParts.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Макет ""%1"" не найден.'; en = 'Layout %1 is not found.'; pl = 'Makieta ""%1"" nie została znaleziona.';de = 'Layout ""%1"" wurde nicht gefunden.';ro = 'Macheta ""%1"" nu a fost găsită.';tr = '""%1"" şablonu bulunamadı.'; es_ES = 'Modelo ""%1"" no se ha encontrado.'"), PathToTemplate);
	EndIf;
	
	TemplateName = StringParts[StringParts.UBound()];
	StringParts.Delete(StringParts.UBound());
	OwnerName = StrConcat(StringParts, ".");
	
	
	RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
	RecordSet.Filter.Object.Set(OwnerName);
	RecordSet.Filter.TemplateName.Set(TemplateName);
	RecordSet.Read();
	For Each Record In RecordSet Do
		Record.Use = False;
	EndDo;
	
	If RecordSet.Count() > 0 Then
		If InfobaseUpdate.IsCallFromUpdateHandler() Then
			InfobaseUpdate.WriteRecordSet(RecordSet);
		Else
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			
			RecordSet.Write();
			
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
		EndIf;
	EndIf;
	
EndProcedure

// Returns a spreadsheet document by binary data of a spreadsheet document.
//
// Parameters:
//  BinaryDocumentData - BinaryData - binary data of a spreadsheet document.
//
// Returns:
//  SpreadsheetDocument - a spreadsheet document.
//
Function SpreadsheetDocumentByBinaryData(BinaryDocumentData) Export
	
	TempFileName = GetTempFileName();
	BinaryDocumentData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	
	SafeModeSet = SafeMode();
	If TypeOf(SafeModeSet) = Type("String") Then
		SafeModeSet = True;
	EndIf;
	
	If Not SafeModeSet Then
		DeleteFiles(TempFileName);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns binary data for generating a QR code.
//
// Parameters:
//  QRString - String - data to be placed in the QR code.
//
//  CorrectionLevel - Number - an image aberration level, at which it is still possible to completely recognize this QR
//                             code.
//                     The parameter must have an integer type and have one of the following possible values:
//                     0 (7% defect allowed), 1 (15% defect allowed), 2 (25% defect allowed), 3 (35% defect allowed).
//
//  Size - Number - determines the size of the output image side, in pixels.
//                     If the smallest possible image size is greater than this parameter, the code is not generated.
//
// Returns:
//  BinaryData - a buffer that contains the bytes of the QR code image in PNG format.
// 
// Example:
//  
//  // Printing a QR code containing information encrypted according to UFEBM.
//
//  QRString = PrintManager.UFEBMFormatString(PaymentDetails);
//  ErrorText = "";
//  QRCodeData = AccessManagement.QRCodeData(QRString, 0, 190, ErrorText);
//  If Not BlankString (ErrorText)
//      CommonClientServer.MessageToUser(ErrorText);
//  EndIf;
//
//  QRCodePicture = New Picture(QRCodeData);
//  TemplateArea.Pictures.QRCode.Picture = QRCodePicture;
//
Function QRCodeData(QRString, CorrectionLevel, Size) Export
	
	SetSafeModeDisabled(True);
	QRCodeGenerator = QRCodeGenerationComponent();
	If QRCodeGenerator = Undefined Then
		Return Undefined;
	EndIf;
	
	Try
		BinaryPictureData = QRCodeGenerator.GenerateQRCode(QRString, CorrectionLevel, Size);
	Except
		WriteLogEvent(NStr("ru = 'Формирование QR-кода'; en = 'QR code generation'; pl = 'Generacja kodu QR';de = 'QR-Code-Generierung';ro = 'Generarea codului QR';tr = 'QR kodu oluşturulması'; es_ES = 'Generación del código QR'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return BinaryPictureData;
	
EndFunction

// Generates print forms in the required format and writes them to files.
// Restriction: print forms generated on the client are not supported.
//
// Parameters:
//  PrintCommand - Structure - a form print command, see PrintManager.FormPrintCommands. 
//  ObjectsList - Array    - references to the objects to print.
//  SettingsForSaving - Structure - see PrintManager.SettingsForSaving. 
//
// Returns:
//  ValueTable - print form files:
//   * FileName - String - a file name.
//   * BinaryData - BinaryData - a print form file.
//
Function PrintToFile(PrintCommand, ObjectsList, SettingsForSaving) Export
	
	Result = New ValueTable;
	Result.Columns.Add("FileName");
	Result.Columns.Add("BinaryData");
	
	PrintData = Undefined;
	If PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
		Source = PrintCommand.AdditionalParameters.Ref;
		PrintData = GenerateExternalPrintForm(Source, PrintCommand.ID, ObjectsList);
	Else
		PrintData = GeneratePrintForms(PrintCommand.PrintManager, PrintCommand.ID,
			ObjectsList, PrintCommand.AdditionalParameters);
	EndIf;
		
	PrintFormsCollection = PrintData.PrintFormsCollection;
	PrintObjects = PrintData.PrintObjects;
	
	AreasSignaturesAndSeals = Undefined;
	If SettingsForSaving.SignatureAndSeal Then
		AreasSignaturesAndSeals = AreasSignaturesAndSeals(PrintObjects);
	EndIf;
	
	FormatsTable = SpreadsheetDocumentSaveFormatsSettings();
	
	For Each PrintForm In PrintFormsCollection Do
		If ValueIsFilled(PrintForm.OfficeDocuments) Then
			For Each OfficeDocument In PrintForm.OfficeDocuments Do
				File = Result.Add();
				File.FileName = OfficeDocumentFileName(OfficeDocument.Value, SettingsForSaving.TransliterateFilesNames);
				File.BinaryData = GetFromTempStorage(OfficeDocument.Key);
			EndDo;
			Continue;
		EndIf;
		
		If SettingsForSaving.SignatureAndSeal Then
			AddSignatureAndSeal(PrintForm.SpreadsheetDocument, AreasSignaturesAndSeals);
		Else
			RemoveSignatureAndSeal(PrintForm.SpreadsheetDocument);
		EndIf;
		
		PrintFormsByObjects = PrintFormsByObjects(PrintForm.SpreadsheetDocument, PrintObjects);
		For Each MapBetweenObjectAndPrintForm In PrintFormsByObjects Do
			
			PrintObject = MapBetweenObjectAndPrintForm.Key;
			SpreadsheetDocument = MapBetweenObjectAndPrintForm.Value;
		
			For Each Format In SettingsForSaving.SaveFormats Do
				FileType = Format;
				If TypeOf(FileType) = Type("String") Then
					FileType = SpreadsheetDocumentFileType[FileType];
				EndIf;
				FormatSettings = FormatsTable.FindRows(New Structure("SpreadsheetDocumentFileType", FileType))[0];
				
				FileExtention = FormatSettings.Extension;
				SpecifiedPrintFormsNames = PrintForm.PrintFormFileName;
				PrintFormName = PrintForm.TemplateSynonym;
				
				FileName = ObjectPrintFormFileName(PrintObject, SpecifiedPrintFormsNames, PrintFormName) + "." + FileExtention;
				If SettingsForSaving.TransliterateFilesNames Then
					FileName = StringFunctionsClientServer.LatinString(FileName)
				EndIf;
				FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
				
				File = Result.Add();
				File.FileName = FileName;
				File.BinaryData = SpreadsheetDocumentToBinaryData(SpreadsheetDocument, FileType);
			EndDo;
		EndDo;
	EndDo;
	
	If SettingsForSaving.PackToArchive Then
		BinaryData = PackToArchive(Result);
		Result.Clear();
		File = Result.Add();
		File.FileName = FileName(GetTempFileName("zip"));
		File.BinaryData = BinaryData;
	EndIf;
	
	Return Result;
	
EndFunction

// The SettingsForSaving parameter constructor of the PrintManager.PrintToFile function.
// Defines a format and other settings of writing a spreadsheet document to file.
// 
// Returns:
//  Structure - settings of writing a spreadsheet document to file.
//   * SaveFormats - Array - a collection of the SpreadsheetDocumentFileType values.
//   * PackToArchive   - Boolean - if set to True, one archive file with files of the specified formats will be created.
//   * TransliterateFilesNames - Boolean - if set to True, names of the received files will be in Latin characters.
//   * SignatureAndSeal    - Boolean - if it is set to True and a spreadsheet document being saved 
//                                  supports placement of signatures and seals, they will be placed to saved files.
//
Function SettingsForSaving() Export
	
	SettingsForSaving = New Structure;
	SettingsForSaving.Insert("SaveFormats", New Array);
	SettingsForSaving.Insert("PackToArchive", False);
	SettingsForSaving.Insert("TransliterateFilesNames", False);
	SettingsForSaving.Insert("SignatureAndSeal", False);
	
	Return SettingsForSaving;
	
EndFunction

#Region OperationsWithOfficeDocumentsTemplates

////////////////////////////////////////////////////////////////////////////////
// Operations with office document templates.

//	The section contains interface functions (API) used for creating print forms based on office 
//	documents. Currently, office suites that work with the Office Open XML format (Microsoft Office, 
//	Open Office, Google Docs) are supported.
//
////////////////////////////////////////////////////////////////////////////////
//	Used data types (determined by specific implementations).
//	RefPrintForm	- a reference to a print form.
//	RefTemplate			- a reference to a template.
//	Area				- a reference to a print form area or a template area (structure), it is overridden with 
//						internal area data in the interface module.
//						
//	AreaDetails		- a template area description (see below).
//	FillingData	- either a structure or an array of structures (for lists and tables.
//						
////////////////////////////////////////////////////////////////////////////////
//	AreaDetails - a structure that describes template areas prepared by the user key AreaName - an 
//	area name key AreaTypeType - 	Header.
//	
//							Footer
//							FirstHeader
//							FirstFooter
//							EvenHeader
//							EvenFooter
//							Total
//							TableRow
//							List
//

////////////////////////////////////////////////////////////////////////////////
// Functions for initializing and closing references.

// Creates a structure of the output print form.
// Call this function before performing any actions on the form.
//
// Parameters:
//  DeleteDocumentType - String - an obsolete parameter, not used.
//  DeleteTemplatePageSettings - Map - an obsolete parameter, not used.
//  Template - Structure - see PrintManager.InitializeTemplate. 
//
// Returns:
//  Structure - a new print form.
//
Function InitializePrintForm(Val DeleteDocumentType, Val DeleteTemplatePageSettings = Undefined, Template = Undefined) Export
	
	If Template = Undefined Then
		Raise NStr("ru = 'Необходимо указать значение параметра ""Макет""'; en = 'Specify value for Layout parameter'; pl = 'Neobkhodimo ukazatjh znachenie parametra ""Maket""';de = 'Neobkhodimo ukazatjh znachenie parametra ""Maket""';ro = 'Neobkhodimo ukazatjh znachenie parametra ""Maket""';tr = 'Neobkhodimo ukazatjh znachenie parametra ""Maket""'; es_ES = 'Neobkhodimo ukazatjh znachenie parametra ""Maket""'");
	EndIf;
	
	PrintForm = PrintManagementInternal.InitializePrintForm(Template);
	PrintForm.Insert("Type", "DOCX");
	PrintForm.Insert("LastOutputArea", Undefined);
	
	Return PrintForm;
	
EndFunction

// Creates a template structure. This structure is used later for receiving template areas (tags and 
// tables), headers, and footers.
//
// Parameters:
//  BinaryTemplateData - BinaryData - a binary template data.
//  DeleteTemplateType - String - an obsolete parameter, not used.
//  DeleteTemplateName - String - an obsolete parameter, not used.
//
// Returns:
//  Structure - a template.
//
Function InitializeOfficeDocumentTemplate(BinaryTemplateData, Val DeleteTemplateType, Val DeleteTemplateName = "") Export
	
	Template = PrintManagementInternal.TemplateFromBinaryData(BinaryTemplateData);
	If Template <> Undefined Then
		Template.Insert("Type", "DOCX");
		Template.Insert("TemplatePagesSettings", New Map);
	EndIf;
	
	Return Template;
	
EndFunction

// Deletes temporary files formed after expanding an xml template structure.
// Call it every time after generation of a template and a print form, as well as in the event of 
// generation termination.
//
// Parameters:
//  PrintForm - Structure - see PrintManager.InitializePrintForm. 
//  DeleteCloseApplication - Boolean - an obsolete parameter, not used.
//
Procedure ClearRefs(PrintForm, Val DeleteCloseApplication = True) Export
	
	If PrintForm <> Undefined Then
		PrintManagementInternal.CloseConnection(PrintForm);
		PrintForm = Undefined;
	EndIf;
	
EndProcedure

// Generates a file of an output print form and places it in the storage.
// Call this method after adding all areas to a print form structure.
//
// Parameters:
//  PrintForm - Structure - see PrintManager.InitializePrintForm. 
//
// Returns:
//  String - a storage address, to which the generated file is placed.
//
Function GenerateDocument(Val PrintForm) Export
	
	PrintFormStorageAddress = PrintManagementInternal.GenerateDocument(PrintForm);
	
	Return PrintFormStorageAddress;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for getting template areas, outputting template areas to print forms, and filling 
// parameters in template areas.

// Gets a print form template area.
//
// Parameters:
//   RefToTemplate - Structure - a print form template.
//   AreaDetails - Structure - an area description.
//
// Returns:
//  Structure - a template area.
//
Function TemplateArea(RefToTemplate, AreaDetails) Export
	
	Area = Undefined;
	
	If AreaDetails.AreaType = "Header" OR AreaDetails.AreaType = "EvenHeader" OR AreaDetails.AreaType = "FirstHeader" Then
		Area = PrintManagementInternal.GetHeaderArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "Footer"  OR AreaDetails.AreaType = "EvenFooter"  OR AreaDetails.AreaType = "FirstFooter" Then
		Area = PrintManagementInternal.GetFooterArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "Total" Then
		Area = PrintManagementInternal.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "TableRow" Then
		Area = PrintManagementInternal.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "List" Then
		Area = PrintManagementInternal.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Тип области не указан или указан некорректно: %1.'; en = 'Area type is not specified or invalid: %1.'; pl = 'Nie określono typu obszaru, lub określono go niepopranie: %1.';de = 'Bereichstyp ist nicht angegeben oder falsch angegeben: %1.';ro = 'Tipul de zonă nu este specificat sau specificat incorect: %1.';tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş: %1.'; es_ES = 'Tipo de área no está especificado o especificado de forma incorrecta: %1.'"), AreaDetails.AreaType);
	EndIf;
	
	If Area <> Undefined Then
		Area.Insert("AreaDetails", AreaDetails);
	EndIf;
	
	Return Area;
	
EndFunction

// Attaches an area to a template print form.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see PrintManager.InitializePrintForm. 
//  TemplateArea - Structure - see PrintManager.TemplateArea. 
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachArea(PrintForm, TemplateArea, Val GoToNextRow = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	Try
		
		AreaDetails = TemplateArea.AreaDetails;
	
		OutputArea = Undefined;
		
		If AreaDetails.AreaType = "Header" OR AreaDetails.AreaType = "EvenHeader" OR AreaDetails.AreaType = "FirstHeader" Then
				OutputArea = PrintManagementInternal.AddHeader(PrintForm, TemplateArea);
		ElsIf AreaDetails.AreaType = "Footer"  OR AreaDetails.AreaType = "EvenFooter"  OR AreaDetails.AreaType = "FirstFooter" Then
			OutputArea = PrintManagementInternal.AddFooter(PrintForm, TemplateArea);
		ElsIf AreaDetails.AreaType = "Total" Then
			OutputArea = PrintManagementInternal.AttachArea(PrintForm, TemplateArea, GoToNextRow);
		ElsIf AreaDetails.AreaType = "List" OR AreaDetails.AreaType = "TableRow" Then
			OutputArea = PrintManagementInternal.AttachArea(PrintForm, TemplateArea, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
		
		AreaDetails.Insert("Area", OutputArea);
		AreaDetails.Insert("GoToNextRow", GoToNextRow);
		
		// Contains an area type and area borders (if required).
		PrintForm.LastOutputArea = AreaDetails;
		
	Except
		ErrorMessage = TrimAll(BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при попытке вывести область ""%1"" из макета.'; en = 'Error occurred during output of %1 layout area.'; pl = 'Podczas próby uzyskania obszaru ""%1"" z szablonu wystąpił błąd.';de = 'Beim Versuch, den Bereich ""%1"" aus der Vorlage zu erhalten, ist ein Fehler aufgetreten.';ro = 'Eroare la tentativa de afișare a domeniului ""%1"" din machetă.';tr = 'Şablondan alan ""%1"" elde etmeye çalışırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al intentar obtener el área ""%1"" desde el modelo.'"),
			TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Fills parameters of the print form area.
//
// Parameters:
//  PrintForm - Structure - either a print form area or a print form itself.
//  Data - Structure - filling data.
//
Procedure FillParameters(PrintForm, Data) Export
	
	AreaDetails = PrintForm.LastOutputArea;
	
	If AreaDetails.AreaType = "Header" OR AreaDetails.AreaType = "EvenHeader" OR AreaDetails.AreaType = "FirstHeader" Then
		PrintManagementInternal.FillHeaderParameters(PrintForm, PrintForm.LastOutputArea.Area, Data);
	ElsIf AreaDetails.AreaType = "Footer"  OR AreaDetails.AreaType = "EvenFooter"  OR AreaDetails.AreaType = "FirstFooter" Then
		PrintManagementInternal.FillFooterParameters(PrintForm, PrintForm.LastOutputArea.Area, Data);
	ElsIf AreaDetails.AreaType = "Total"
			OR AreaDetails.AreaType = "TableRow"
			OR AreaDetails.AreaType = "List" Then
		PrintManagementInternal.FillParameters(PrintForm, PrintForm.LastOutputArea.Area, Data);
	Else
		Raise AreaTypeSpecifiedIncorrectlyText();
	EndIf;

EndProcedure

// Adds an area from a template to a print form, replacing the area parameters with the object data values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see PrintManager.InitializePrintForm. 
//  TemplateArea - Structure - see PrintManager.TemplateArea. 
//  Data - Structure - filling data.
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachAreaAndFillParameters(PrintForm, TemplateArea, Data, Val GoToNextRow = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AttachArea(PrintForm, TemplateArea, GoToNextRow);
	FillParameters(PrintForm, Data);
	
EndProcedure

// Adds an area from a template to a print form, replacing the area parameters with the object data 
// values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see PrintManager.InitializePrintForm. 
//  TemplateArea - Structure - see PrintManager.TemplateArea. 
//  Data - Array - an item collection of the Structure type, object data.
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure JoinAndFillCollection(PrintForm, TemplateArea, Data, Val GoToNextRow = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If AreaDetails.AreaType = "TableRow" OR AreaDetails.AreaType = "List" Then
		PrintManagementInternal.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNextRow);
	Else
		Raise AreaTypeSpecifiedIncorrectlyText();
	EndIf;
	
EndProcedure

// Inserts a line break as a newline character.
//
// Parameters:
//  PrintForm - Structure - a print form, see PrintManager.InitializePrintForm. 
//
Procedure InsertBreakAtNewLine(PrintForm) Export
	
	PrintManagementInternal.InsertBreakAtNewLine(PrintForm);
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use AttachableCommands.OnCreateAtServer.
// Places print commands in a form.
//
// Parameters:
//   Form - ManagedForm - a form, where the Print submenu is to be placed.
//   DefaultCommandsLocation - FormItem - a group for placing the Print submenu, the default 
//                                                     location is the form command bar.
//   PrintObjects - Array - a list of metadata objects, for which it is required to generate a joint 
//                                               Print submenu.
Procedure OnCreateAtServer(Form, DefaultCommandsLocation = Undefined, PrintObjects = Undefined) Export
	PlacementParameters = AttachableCommands.PlacementParameters();
	If TypeOf(DefaultCommandsLocation) = Type("FormGroup") Then
		If DefaultCommandsLocation.Type = FormGroupType.Popup
			Or DefaultCommandsLocation.Title = NStr("ru = 'Печать'; en = 'Print'; pl = 'Wydruki';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'")
			Or DefaultCommandsLocation.Name = "PrintSubmenu" Then
			Parent = DefaultCommandsLocation.Parent;
			If TypeOf(Parent) = Type("FormGroup") Then
				PlacementParameters.CommandBar = Parent;
			EndIf;
		Else
			PlacementParameters.CommandBar = DefaultCommandsLocation;
		EndIf;
	EndIf;
	If TypeOf(PrintObjects) = Type("Array") Then
		PlacementParameters.Sources = PrintObjects;
	EndIf;
	AttachableCommands.OnCreateAtServer(Form, PlacementParameters);
EndProcedure

// Obsolete. The LocalPrintFilesDirectory setting is out of use.
// Returns a path to the directory used for printing.
//
// Returns:
//  String - a full path to the temporary directory of print files.
//
Function GetLocalDirectoryOfPrintFiles() Export
	Return "";
EndFunction

// Obsolete. Use PrintManagerRF.UFEBMFormatString.
//
// Generates a format string according to "Unified format for electronic banking messages" for its 
// display as a QR code.
//
// Parameters:
//  DocumentData - Structure - contains document field values.
//    The document data will be encoded according to standard
//    Standards for financial transactions. Two-dimensional barcode characters for making payments of individuals".
//    DocumentData must contain information in the fields described below.
//    Required structure fields:
//     * PayeeText - a payee name - up to 160 characters.
//     * PayeeAccount - a payee account number - up to 20 characters.
//     * PayeeBankName - a payee bank name - up to 45 characters.
//     * PayeeBankBIC          - BIC                                     - up to 9 characters.
//     * PayeeBankAccount         - a payee bank account number - up to 20 characters.
//    Additional fields of the following structure:
//     * AmountAsNumber         - a payment amount in dollars                 - up to 16 characters.
//     * PaymentPurpose   - a payment name (purpose)       - up to 210 characters.
//     * PayeeTIN       - a payee TIN                  - up to 12 characters.
//     * PayerTIN      - a payer TIN                         - up to 12 characters.
//     * AuthorStatus   - a status of a payment document author - up to 2 characters.
//     * PayeeCRTR       - a payee CRTR                  - up to 9 characters.
//     * BCCode               - BCC                                     - up to 20 characters.
//     * RNCMTCode            - RNCMT                                   - up to 11 characters.
//     * BaseIndicator - a tax payment reason            - up to 2 characters.
//     * PeriodIndicator   - a fiscal period                        - up to 10 characters.
//     * NumberIndicator    - a document number                         - up to 15 characters.
//     * DateIndicator      - a document date                          - up to 10 characters.
//     * TypeIndicator      - a payment type                             - up to 2 characters.
//    Other additional fields:
//     * LastPayerName               - a payer's last name.
//     * PayerName                   - a payer name.
//     * PayerMiddleName              - a payer's middle name.
//     * PayerAddress                 - a payer address.
//     * BudgetPayeeAccount  - a budget payee account.
//     * PaymentDocumentIndex        - a payment document index.
//     * IIAN - a PF individual account number (IIAN).
//     * ContractNumber                    - a contract number.
//     * PayerAccount    - a payer account number in the company (in the personal accounting system).
//     * ApartmentNumber                    - an apartment number.
//     * PhoneNumber                    - a phone number.
//     * PayerKind                   - a payer identity document kind.
//     * PayerNumber                  - a payer identity document number.
//     * FullChildName                       - a full name of a student or a child.
//     * BirthDate                     - a date of birth.
//     * PaymentTerm                      - a payment term or a proforma invoice date.
//     * PayPeriod                     - a payment period.
//     * PaymentKind                       - a payment kind.
//     * ServiceCode                        - a service code or a metering device name.
//     * MeterNumber - a metering device number.
//     * MeterValue            - a metering device value.
//     * NotificationNumber                   - a notification, accrual, or a proforma invoice number.
//     * NotificationDate                    - a date of notification, accrual, proforma invoice, or order (for State Traffic Safety Inspectorate).
//     * InstitutionNumber                  - an institution (educational, healthcare) number.
//     * GroupNumber                      - a number of kindergarten group or school grade.
//     * FullTeacherName - a full name of the teacher or the specialist who provides the service.
//     * InsuranceAmount                   - an amount of insurance, additional service, or late payment charge (in cents).
//     * OrderNumber - an order ID (for State Traffic Safety Inspectorate).
//     * EnforcementOrderNumber - an enforcement order number.
//     * PaymentKindCode                   - a payment kind code (for example, for payments to Federal Agency for State Registration).
//     * AccrualID          - an accrual UUID.
//     * TechnicalCode                   - a technical code recommended to be filled by a service provider.
//                                          It can be used by a host company to call the appropriate 
//                                          processing IT system.
//                                          The code value list is presented below.
//
//       Purpose code - a payment purpose.
//       
//       
//          01 Mobile communications, fixed line telephone.
//          02 Utility services, housing and public utilities.
//          03 State Traffic Safety Inspectorate, taxes, duties, budgetary payments.
//          04 Security services
//          05 Services provided by FMS.
//          06 PF
//          07 Loan repayments
//          08 Educational institutions.
//          09 Internet and TV
//          10 Electronic money
//          11 Recreation and travel.
//          12 Investment and insurance.
//          13 Sports and health
//          14 Charitable and public organizations.
//          15 Other services.
//
// Returns:
//   String - data string in the UFEBM format.
//
Function UFEBMFormatString(DocumentData) Export
	
	ModulePrintManagerRF = Common.CommonModule("PrintManagementRussia");
	If ModulePrintManagerRF <> Undefined Then
		Return ModulePrintManagerRF.UFEBMFormatString(DocumentData);
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Hides print commands from the Print submenu.
Procedure DisablePrintCommands(ObjectsList, CommandsList) Export
	RecordSet = InformationRegisters.PrintCommandsSettings.CreateRecordSet();
	For Each Object In ObjectsList Do
		ObjectPrintCommands = StandardObjectPrintCommands(Object);
		For Each IDOfCommandToReplace In CommandsList Do
			Filter = New Structure;
			Filter.Insert("ID", IDOfCommandToReplace);
			Filter.Insert("SaveFormat");
			Filter.Insert("SkipPreview", False);
			Filter.Insert("Disabled", False);
			
			ListOfCommandsToReplace = ObjectPrintCommands.FindRows(Filter);
			For Each CommandToReplace In ListOfCommandsToReplace Do
				RecordSet.Filter.Owner.Set(Object);
				RecordSet.Filter.UUID.Set(CommandToReplace.UUID);
				RecordSet.Read();
				RecordSet.Clear();
				If RecordSet.Count() = 0 Then
					Record = RecordSet.Add();
				Else
					Record = RecordSet[0];
				EndIf;
				Record.Owner = Object;
				Record.UUID = CommandToReplace.UUID;
				Record.Visible = False;
				RecordSet.Write();
			EndDo;
		EndDo;
	EndDo;
EndProcedure

// Returns a list of supplied object printing commands.
//
// Parameters:
//  Object - CatalogRef.MetadataObjectsIDs;
Function StandardObjectPrintCommands(Object) Export
	
	ObjectPrintCommands = ObjectPrintCommands(
		Common.MetadataObjectByID(Object, False));
		
	ExternalPrintCommands = ObjectPrintCommands.FindRows(New Structure("PrintManager", "StandardSubsystems.AdditionalReportsAndDataProcessors"));
	For Each PrintCommand In ExternalPrintCommands Do
		ObjectPrintCommands.Delete(PrintCommand);
	EndDo;
	
	Return ObjectPrintCommands;
EndFunction

// Returns a list of metadata objects, in which the Print subsystem is embedded.
//
// Returns:
//  Array - a list of items of the MetadataObject type.
Function PrintCommandsSources() Export
	ObjectsWithPrintCommands = New Array;
	
	ObjectsList = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsWithPrintCommands(ObjectsWithPrintCommands);
	CommonClientServer.SupplementArray(ObjectsWithPrintCommands, ObjectsList, True);
	
	ObjectsList = New Array;
	PrintManagementOverridable.OnDefineObjectsWithPrintCommands(ObjectsList);
	CommonClientServer.SupplementArray(ObjectsWithPrintCommands, ObjectsList, True);
	
	Result = New Array;
	For Each ObjectManager In ObjectsWithPrintCommands Do
		Result.Add(Metadata.FindByType(TypeOf(ObjectManager)));
	EndDo;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Message templates.

// Returns print form formats allowed for saving for message templates.
//
Function SpreadsheetDocumentSaveFormats() Export
	Return SpreadsheetDocumentSaveFormatsSettings();
EndFunction

Function ObjectPrintCommandsAvailableForAttachments(MetadataObject) Export
	Return ObjectPrintCommands(MetadataObject);
EndFunction

// Generates a print form based on an external source.
//
// Parameters:
//   AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - an external data processor.
//   SourceParameters            - Structure - a structure with the following properties:
//       * CommandID - String - a list of comma-separated templates.
//       * RelatedObjects    - Array
//   PrintFormsCollection - ValueTable - see the Print() procedure description available in the documentation.
//   PrintObjects - ValueList - see the Print() procedure description available in the documentation.
//   OutputParameters - Structure - see the Print() procedure description available in the documentation.
//   
Procedure PrintByExternalSource(AdditionalDataProcessorRef, SourceParameters, PrintFormsCollection,
	PrintObjects, OutputParameters) Export
	
	ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
	ExternalDataProcessorObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(AdditionalDataProcessorRef);
	If ExternalDataProcessorObject = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Внешняя обработка ""%1"" (тип ""%2"") не обслуживается.'; en = 'External data processor %1, type %2, is not supported.'; pl = 'Zewnętrzna obróbka ""%1"" (rodzaj ""%2"") nie jest obsługiwana.';de = 'Externe Verarbeitung ""%1"" (Typ ""%2"") wird nicht bearbeitet.';ro = 'Procesarea externă ""%1"" (tipul ""%2"") nu se deservește.';tr = '""%1"" dış işleme (""%2"" tür) hizmet verilmez.'; es_ES = 'Procesamiento externo ""%1"" (tipo ""%2"") no se soporta.'"),
			String(AdditionalDataProcessorRef),
			String(TypeOf(AdditionalDataProcessorRef)));
	EndIf;
	
	PrintFormsCollection = PreparePrintFormsCollection(SourceParameters.CommandID);
	OutputParameters = PrepareOutputParametersStructure();
	OutputParameters.Insert("AdditionalDataProcessorRef", AdditionalDataProcessorRef);
	
	ExternalDataProcessorObject.Print(
		SourceParameters.RelatedObjects,
		PrintFormsCollection,
		PrintObjects,
		OutputParameters);
	
	// Checking if all templates are generated.
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.SpreadsheetDocument = Undefined Then
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В обработчике печати не был сформирован табличный документ для: %1'; en = 'Print handler did not generate the spreadsheet document for: %1'; pl = 'Dokument tabelaryczny nie został wygenerowany w procesorze wydruku: %1';de = 'Das Tabellenkalkulationsdokument für %1 wurde nicht im Druckprozessor generiert';ro = 'În handlerul de imprimare nu a fost generat documentul tabelar pentru: %1';tr = '%1 için elektronik tablo belgesi yazdırma işlemcisinde oluşturulmadı'; es_ES = 'Documento de la hoja de cálculo para %1 no se ha generado en el procesador de impresión'"),
				PrintForm.TemplateName);
			Raise(ErrorMessageText);
		EndIf;
		
		PrintForm.SpreadsheetDocument.Copies = PrintForm.Copies;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition. 
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings) Export
	Setting = InterfaceSettings.Add();
	Setting.Key          = "AddPrintCommands";
	Setting.TypeDescription = New TypeDescription("Boolean");
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds. 
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "Print";
	Kind.SubmenuName  = "PrintSubmenu";
	Kind.Title   = NStr("ru = 'Печать'; en = 'Print'; pl = 'Wydruki';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'");
	Kind.Order     = 40;
	Kind.Picture    = PictureLib.Print;
	Kind.Representation = ButtonRepresentation.PictureAndText;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject. 
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	ObjectsList = New Array;
	For Each Source In Sources.Rows Do
		ObjectsList.Add(Source.Metadata);
	EndDo;
	If Sources.Rows.Count() = 1 AND Common.IsDocumentJournal(Sources.Rows[0].Metadata) Then
		ObjectsList = Undefined;
	EndIf;
	
	PrintCommands = FormPrintCommands(FormSettings.FormName, ObjectsList);
	
	HandlerParametersKeys = "Handler, PrintManager, FormCaption, SkipPreview, SaveFormat,
	|OverrideCopiesUserSetting, AddExternalPrintFormsToSet,
	|FixedSet, AdditionalParameters";
	For Each PrintCommand In PrintCommands Do
		If PrintCommand.Disabled Then
			Continue;
		EndIf;
		Command = Commands.Add();
		FillPropertyValues(Command, PrintCommand, , "Handler");
		Command.Kind = "Print";
		Command.Popup = PrintCommand.PlacingLocation;
		Command.MultipleChoice = True;
		If PrintCommand.PrintObjectsTypes.Count() > 0 Then
			Command.ParameterType = New TypeDescription(PrintCommand.PrintObjectsTypes);
		EndIf;
		Command.VisibilityInForms = PrintCommand.FormsList;
		If PrintCommand.DontWriteToForm Then
			Command.WriteMode = "DoNotWrite";
		ElsIf PrintCommand.CheckPostingBeforePrint Then
			Command.WriteMode = "Post";
		Else
			Command.WriteMode = "Write";
		EndIf;
		Command.FilesOperationsRequired = PrintCommand.FileSystemExtensionRequired;
		
		Command.Handler = "PrintManagementInternalClient.CommandHandler";
		Command.AdditionalParameters = New Structure(HandlerParametersKeys);
		FillPropertyValues(Command.AdditionalParameters, PrintCommand);
	EndDo;
	
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForSystemUsersOnly.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.PrintFormsEdit.Name);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.2.5";
	Handler.Procedure = "PrintManagement.ResetUserSettingsPrintDocumentsForm";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.22";
	Handler.Procedure = "PrintManagement.ConvertUserMXLTemplateBinaryDataToSpreadsheetDocuments";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "PrintManagement.AddEditPrintFormsRoleToBasicRightsProfiles";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.60";
	Handler.Procedure = "InformationRegisters.UserPrintTemplates.ProcessUserTemplates";
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 1;
	Handler.Comment = NStr("ru = 'Очищает пользовательские макеты, в которых нет изменений по сравнению с соответствующими поставляемыми макетами.
		|Отключает пользовательские макеты, которые не совместимы с текущей версией конфигурации.'; 
		|en = 'Removes custom layouts that are indistinguishable from build-in layouts.
		|Disables custom layouts that incompatible with the configuration version.'; 
		|pl = 'Oczyszcza niestandardowe makiety, w których nie ma zmian w porównaniu z odpowiednimi dostarczanymi makietami.
		|Wyłącza makiety użytkowników, które nie są kompatybilne z aktualną wersją konfiguracji.';
		|de = 'Löscht benutzerdefinierte Layouts, die im Vergleich zu den entsprechenden ausgelieferten Layouts keine Änderungen aufweisen.
		|Deaktiviert benutzerdefinierte Layouts, die nicht mit der aktuellen Version der Konfiguration kompatibel sind.';
		|ro = 'Golește machetele utilizatorului în care nu există modificări în comparație cu machetele respective furnizate.
		|Dezactivează machetele de utilizator incompatibile cu versiunea curentă a configurației.';
		|tr = 'Verilen düzenlere göre değişiklik yapılmayan kullanıcı şablonları temizler. 
		|Geçerli yapılandırma sürümü ile uyumlu olmayan kullanıcı şablonları devre dışı bırakır.'; 
		|es_ES = 'Limpia los modelos de usuario en los que no hay cambios comparando con los modelos suministrados correspondientes.
		|Desactiva los modelos de usuario que no son compatibles con la versión actual de la configuración.'");
	Handler.ID = New UUID("e5b0d876-c766-40a0-a0cf-ffccc83a193f");
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.UserPrintTemplates";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.UserPrintTemplates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToBeRead = "InformationRegister.UserPrintTemplates";
	Handler.ObjectsToChange = "InformationRegister.UserPrintTemplates";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "InformationRegisters.SuppliedPrintTemplates.UpdateTemplatesCheckSum";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("ru = 'Определяет, какие поставляемые макеты печатных форм изменились по отношению к предыдущей версии конфигурации.'; en = 'Identifies which build-in print form layouts have changed since the previous configuration version.'; pl = 'Określa, jakie wydrukowane makiety formularzy zmieniły się w stosunku do poprzedniej wersji konfiguracji.';de = 'Legt fest, welche gedruckten Formularlayouts sich gegenüber der vorherigen Konfigurationsversion geändert haben.';ro = 'Determină care machete furnizate ale formelor de tipar s-au modificat în raport cu versiunea precedentă a configurației.';tr = 'Hangi basılı form düzenlerinin önceki yapılandırma sürümüne göre değiştiğini belirler.'; es_ES = 'Determina cuáles modelos de formularios de impresión han sido cambiados respecto a la versión anterior de la configuración.'");
	Handler.ID = New UUID("51f71246-67e3-40e0-80e5-ebb3192fa6c0");
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(ModuleSafeModeManager.PermissionToUseAddIn(
		"CommonTemplate.QRCodePrintingComponent", NStr("ru = 'Печать QR кодов.'; en = 'Print QR codes.'; pl = 'Drukowanie kodów QR.';de = 'QR-Codes drucken';ro = 'Imprimați codurile QR.';tr = 'QR kodlarını yazdır.'; es_ES = 'Imprimir los códigos QR.'")));
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.InformationRegisters.UserPrintTemplates)
		Or ModuleToDoListServer.UserTaskDisabled("PrintFormTemplates") Then
		Return;
	EndIf;
	
	// If there is no Administration section, a to-do is not added.
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject("InformationRegister.UserPrintTemplates");
	Else
		Sections = New Array;
		Sections.Add(Subsystem);
	EndIf;
	
	OutputUserTask = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "PrintForms");
	If VersionChecked <> Undefined Then
		ArrayVersion  = StrSplit(Metadata.Version, ".");
		CurrentVersion = ArrayVersion[0] + ArrayVersion[1] + ArrayVersion[2];
		If VersionChecked = CurrentVersion Then
			OutputUserTask = False; // Current version print forms are checked.
		EndIf;
	EndIf;
	
	UserTemplatesCount = CountOfUsedUserTemplates();
	
	For Each Section In Sections Do
		SectionID = "CheckCompatibilityWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		
		// Adding a to-do.
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = "PrintFormTemplates";
		ToDoItem.HasToDoItems      = OutputUserTask AND UserTemplatesCount > 0;
		ToDoItem.Presentation = NStr("ru = 'Макеты печатных форм'; en = 'Print form layouts'; pl = 'Szablony formularza wydruku';de = 'Formularvorlagen drucken';ro = 'Șabloanele formelor de listare';tr = 'Baskı formu şablonları'; es_ES = 'Versión impresa modelos'");
		ToDoItem.Count    = UserTemplatesCount;
		ToDoItem.Form         = "InformationRegister.UserPrintTemplates.Form.CheckPrintForms";
		ToDoItem.Owner      = SectionID;
		
		// Checking whether the to-do group exists. If a group is missing, add it.
		UserTaskGroup = ToDoList.Find(SectionID, "ID");
		If UserTaskGroup = Undefined Then
			UserTaskGroup = ToDoList.Add();
			UserTaskGroup.ID = SectionID;
			UserTaskGroup.HasToDoItems      = ToDoItem.HasToDoItems;
			UserTaskGroup.Presentation = NStr("ru = 'Проверить совместимость'; en = 'Check compatibility'; pl = 'Kontrola zgodności';de = 'Überprüfen Sie die Kompatibilität';ro = 'Verificați compatibilitatea';tr = 'Uygunluğu kontrol et'; es_ES = 'Revisar la compatibilidad'");
			If ToDoItem.HasToDoItems Then
				UserTaskGroup.Count = ToDoItem.Count;
			EndIf;
			UserTaskGroup.Owner = Section;
		Else
			If Not UserTaskGroup.HasToDoItems Then
				UserTaskGroup.HasToDoItems = ToDoItem.HasToDoItems;
			EndIf;
			
			If ToDoItem.HasToDoItems Then
				UserTaskGroup.Count = UserTaskGroup.Count + ToDoItem.Count;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// Resets user print form settings: number of copies and order.
Procedure ResetUserSettingsPrintDocumentsForm() Export
	Common.CommonSettingsStorageDelete("PrintFormsSettings", Undefined, Undefined);
EndProcedure

// Converts user MXL templates stored as binary data to spreadsheet documents.
Procedure ConvertUserMXLTemplateBinaryDataToSpreadsheetDocuments() Export
	
	QueryText = 
	"SELECT
	|	UserPrintTemplates.TemplateName,
	|	UserPrintTemplates.Object,
	|	UserPrintTemplates.Template,
	|	UserPrintTemplates.Use
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates";
	
	Query = New Query(QueryText);
	TemplatesSelection = Query.Execute().Select();
	
	While TemplatesSelection.Next() Do
		If StrStartsWith(TemplatesSelection.TemplateName, "PF_MXL") Then
			TempFileName = GetTempFileName();
			
			BinaryTemplateData = TemplatesSelection.Template.Get();
			If TypeOf(BinaryTemplateData) <> Type("BinaryData") Then
				Continue;
			EndIf;
			
			BinaryTemplateData.Write(TempFileName);
			
			SpreadsheetDocumentRead = True;
			SpreadsheetDocument = New SpreadsheetDocument;
			Try
				SpreadsheetDocument.Read(TempFileName);
			Except
				SpreadsheetDocumentRead = False; // This file is not a spreadsheet document. Deleting the file.
			EndTry;
			
			Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
			FillPropertyValues(Record, TemplatesSelection, , "Template");
			
			If SpreadsheetDocumentRead Then
				Record.Template = New ValueStorage(SpreadsheetDocument, New Deflation(9));
				Record.Write();
			Else
				Record.Delete();
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds the PrintFormsEditing role to all profiles that have the BasicSSLRights role.
Procedure AddEditPrintFormsRoleToBasicRightsProfiles() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	NewRoles.Add(Metadata.Roles.BasicSSLRights.Name);
	NewRoles.Add(Metadata.Roles.PrintFormsEdit.Name);
	
	RolesToReplace = New Map;
	RolesToReplace.Insert(Metadata.Roles.BasicSSLRights.Name, NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

// Returns a reference to the source object of the external print form.
//
// Parameters:
//  ID - String - a form ID.
//  FullMetadataObjectName - String - a full name of the metadata object for getting a reference to 
//                                        the external print form source.
//
// Returns:
//  Ref.
Function AdditionalPrintFormRef(ID, FullMetadataObjectName)
	ExternalPrintFormRef = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnReceiveExternalPrintForm(ID, FullMetadataObjectName, ExternalPrintFormRef);
	EndIf;
	
	Return ExternalPrintFormRef;
EndFunction

// Generating print forms.
Function GeneratePrintForms(Val PrintManagerName, Val TemplatesNames, Val ObjectsArray, Val PrintParameters, 
	AllowedPrintObjectsTypes = Undefined) Export
	
	PrintFormsCollection = PreparePrintFormsCollection(New Array);
	PrintObjects = New ValueList;
	OutputParameters = PrepareOutputParametersStructure();
	
	If TypeOf(TemplatesNames) = Type("String") Then
		TemplatesNames = StrSplit(TemplatesNames, ",");
	Else // Type("Array")
		TemplatesNames = Common.CopyRecursive(TemplatesNames);
	EndIf;
	
	ExternalPrintFormsPrefix = "ExternalPrintForm.";
	
	ExternalPrintFormsSource = PrintManagerName;
	If Common.IsReference(TypeOf(ObjectsArray)) Then
		ExternalPrintFormsSource = ObjectsArray.Metadata().FullName();
	Else
		If ObjectsArray.Count() > 0 Then
			ExternalPrintFormsSource = ObjectsArray[0].Metadata().FullName();
		EndIf;
	EndIf;
	ExternalPrintForms = PrintFormsListFromExternalSources(ExternalPrintFormsSource);
	
	// Adding external print forms to a set.
	AddedExternalPrintForms = New Array;
	If TypeOf(PrintParameters) = Type("Structure") 
		AND PrintParameters.Property("AddExternalPrintFormsToSet") 
		AND PrintParameters.AddExternalPrintFormsToSet Then 
		
		ExternalPrintFormsIDs = ExternalPrintForms.UnloadValues();
		For Each ID In ExternalPrintFormsIDs Do
			TemplatesNames.Add(ExternalPrintFormsPrefix + ID);
			AddedExternalPrintForms.Add(ExternalPrintFormsPrefix + ID);
		EndDo;
	EndIf;
	
	For Each TemplateName In TemplatesNames Do
		// Checking for a printed form.
		FoundPrintForm = PrintFormsCollection.Find(TemplateName, "TemplateName");
		If FoundPrintForm <> Undefined Then
			LastAddedPrintForm = PrintFormsCollection[PrintFormsCollection.Count() - 1];
			If LastAddedPrintForm.TemplateName = FoundPrintForm.TemplateName Then
				LastAddedPrintForm.Copies = LastAddedPrintForm.Copies + 1;
			Else
				PrintFormCopy = PrintFormsCollection.Add();
				FillPropertyValues(PrintFormCopy, FoundPrintForm);
				PrintFormCopy.Copies = 1;
			EndIf;
			Continue;
		EndIf;
		
		// Checking whether an additional print manager is specified in the print form name.
		AdditionalPrintManagerName = "";
		ID = TemplateName;
		ExternalPrintForm = Undefined;
		If StrFind(ID, ExternalPrintFormsPrefix) > 0 Then // This is an external print form
			ID = Mid(ID, StrLen(ExternalPrintFormsPrefix) + 1);
			ExternalPrintForm = ExternalPrintForms.FindByValue(ID);
		ElsIf StrFind(ID, ".") > 0 Then // Additional print manager is specified.
			Position = StrFind(ID, ".", SearchDirection.FromEnd);
			AdditionalPrintManagerName = Left(ID, Position - 1);
			ID = Mid(ID, Position + 1);
		EndIf;
		
		// Determining an internal print manager.
		UsedPrintManager = AdditionalPrintManagerName;
		If IsBlankString(UsedPrintManager) Then
			UsedPrintManager = PrintManagerName;
		EndIf;
		
		// Checking whether the objects being printed match the selected print form.
		ObjectsCorrespondingToPrintForm = ObjectsArray;
		If AllowedPrintObjectsTypes <> Undefined AND AllowedPrintObjectsTypes.Count() > 0 Then
			If TypeOf(ObjectsArray) = Type("Array") Then
				ObjectsCorrespondingToPrintForm = New Array;
				For Each Object In ObjectsArray Do
					If AllowedPrintObjectsTypes.Find(TypeOf(Object)) = Undefined Then
						MessagePrintFormUnavailable(Object);
					Else
						ObjectsCorrespondingToPrintForm.Add(Object);
					EndIf;
				EndDo;
				If ObjectsCorrespondingToPrintForm.Count() = 0 Then
					ObjectsCorrespondingToPrintForm = Undefined;
				EndIf;
			ElsIf Common.RefTypeValue(ObjectsArray) Then // The passed variable is not an array
				If AllowedPrintObjectsTypes.Find(TypeOf(ObjectsArray)) = Undefined Then
					MessagePrintFormUnavailable(ObjectsArray);
					ObjectsCorrespondingToPrintForm = Undefined;
				EndIf;
			EndIf;
		EndIf;
		
		TempCollectionForSinglePrintForm = PreparePrintFormsCollection(ID);
		
		// Calling the Print procedure from the print manager.
		If ExternalPrintForm <> Undefined Then
			// Print manager in an external print form.
			PrintByExternalSource(
				AdditionalPrintFormRef(ExternalPrintForm.Value, ExternalPrintFormsSource),
				New Structure("CommandID, RelatedObjects", ExternalPrintForm.Value, ObjectsCorrespondingToPrintForm),
				TempCollectionForSinglePrintForm,
				PrintObjects,
				OutputParameters);
		Else
			If Not IsBlankString(UsedPrintManager) Then
				PrintManager = Common.ObjectManagerByFullName(UsedPrintManager);
				// Printing an internal print form.
				If ObjectsCorrespondingToPrintForm <> Undefined Then
					PrintManager.Print(ObjectsCorrespondingToPrintForm, PrintParameters, TempCollectionForSinglePrintForm, 
						PrintObjects, OutputParameters);
				Else
					TempCollectionForSinglePrintForm[0].SpreadsheetDocument = New SpreadsheetDocument;
				EndIf;
			EndIf;
		EndIf;
		
		// Checking filling of the print form collection received from a print manager.
		For Each PrintFormDetails In TempCollectionForSinglePrintForm Do
			CommonClientServer.Validate(
				TypeOf(PrintFormDetails.Copies) = Type("Number") AND PrintFormDetails.Copies > 0,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не задано количество экземпляров для печатной формы ""%1"".'; en = 'The number of copies is not specified for %1 print form.'; pl = 'Nie określono ilości kopii dla formularza wydruku ""%1"".';de = 'Die Anzahl der Kopien ist nicht für das Druckformular ""%1"" angegeben.';ro = 'Nu este setat numărul de copii pentru forma de tipar ""%1"".';tr = 'Baskı formu ""%1"" için kopya sayısı belirtilmemiş.'; es_ES = 'Número de copias no está especificado para la versión impresa ""%1"".'"),
				?(IsBlankString(PrintFormDetails.TemplateSynonym), PrintFormDetails.TemplateName, PrintFormDetails.TemplateSynonym)));
		EndDo;
				
		// Updating the collection
		Cancel = TempCollectionForSinglePrintForm.Count() = 0;
		// A single print form is required but the entire collection is processed for backward compatibility.
		For Each TempPrintForm In TempCollectionForSinglePrintForm Do 
			
			If NOT TempPrintForm.OfficeDocuments = Undefined Then
				TempPrintForm.SpreadsheetDocument = New SpreadsheetDocument;
			EndIf;
			
			If TempPrintForm.SpreadsheetDocument <> Undefined Then
				PrintForm = PrintFormsCollection.Add();
				FillPropertyValues(PrintForm, TempPrintForm);
				If TempCollectionForSinglePrintForm.Count() = 1 Then
					PrintForm.TemplateName = TemplateName;
					PrintForm.UpperCaseName = Upper(TemplateName);
				EndIf;
			Else
				// An error occurred when generating a print form.
				Cancel = True;
			EndIf;
			
		EndDo;
		
		// Raising an exception based on the error.
		If Cancel Then
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"ru = 'При формировании печатной формы ""%1"" возникла ошибка. Обратитесь к администратору.'; en = 'Error occurred generating %1 print form. Contact your administrator.'; pl = 'Podczas generowania formularza wydruku ""%1"" wystąpił błąd. Skontaktuj się z administratorem.';de = 'Beim Generieren des Druckformulars ""%1"" ist ein Fehler aufgetreten. Kontaktieren Sie Ihren Administrator.';ro = 'A apărut o eroare la generarea formularului de imprimare ""%1"". Adresați-vă administratorului.';tr = '""%1"" Formunu oluştururken bir hata oluştu. Yöneticinize başvurun.'; es_ES = 'Ha ocurrido un error al generar la versión impresa ""%1"". Contactar su administrador.'"), TemplateName);
			Raise ErrorMessageText;
		EndIf;
		
	EndDo;
	
	PrintManagementOverridable.OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
	// Setting a number of spreadsheet document copies, checking areas.
	For Each PrintForm In PrintFormsCollection Do
		CheckSpreadsheetDocumentLayoutByPrintObjects(PrintForm.SpreadsheetDocument, 
			PrintObjects, PrintManagerName, PrintForm.TemplateName);
		If AddedExternalPrintForms.Find(PrintForm.TemplateName) <> Undefined Then
			PrintForm.Copies = 0; // For automatically added forms.
		EndIf;
		If PrintForm.SpreadsheetDocument <> Undefined Then
			PrintForm.SpreadsheetDocument.Copies = PrintForm.Copies;
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("PrintFormsCollection", PrintFormsCollection);
	Result.Insert("PrintObjects", PrintObjects);
	Result.Insert("OutputParameters", OutputParameters);
	Return Result;
	
EndFunction

// Generates print forms for direct output to a printer.
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocuments");
	Result.Insert("PrintObjects");
	Result.Insert("OutputParameters");
	Result.Insert("Cancel", False);
		
	If NOT AccessRight("Output", Metadata) Then
		Result.Cancel = True;
		Return Result;
	EndIf;
	
	PrintForms = GeneratePrintForms(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
		
	SpreadsheetDocuments = New ValueList;
	For Each PrintForm In PrintForms.PrintFormsCollection Do
		If (TypeOf(PrintForm.SpreadsheetDocument) = Type("SpreadsheetDocument")) AND (PrintForm.SpreadsheetDocument.TableHeight <> 0) Then
			SpreadsheetDocuments.Add(PrintForm.SpreadsheetDocument, PrintForm.TemplateSynonym);
		EndIf;
	EndDo;
	
	Result.SpreadsheetDocuments = SpreadsheetDocuments;
	Result.PrintObjects      = PrintForms.PrintObjects;
	Result.OutputParameters    = PrintForms.OutputParameters;
	Return Result;
	
EndFunction

// Generating print forms for direct output to a printer in the server mode in an ordinary 
// application.
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Result = New Structure;
	Result.Insert("Address");
	Result.Insert("PrintObjects");
	Result.Insert("OutputParameters");
	Result.Insert("Cancel", False);
	
	PrintForms = GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
	
	If PrintForms.Cancel Then
		Result.Cancel = PrintForms.Cancel;
		Return Result;
	EndIf;
	
	Result.PrintObjects = New Map;
	
	For Each PrintObject In PrintForms.PrintObjects Do
		Result.PrintObjects.Insert(PrintObject.Presentation, PrintObject.Value);
	EndDo;
	
	Result.Address = PutToTempStorage(PrintForms.SpreadsheetDocuments);
	Return Result;
	
EndFunction

// Returns a table of available formats for saving a spreadsheet document.
//
// Returns
//  ValueTable:
//                   SpreadsheetDocumentFileType - SpreadsheetDocumentFileType - a value in the 
//                                                                                               
//                                                                                               platform that matches the format.
//                   Ref - EnumRef.ReportsSaveFormats - a reference to metadata that stores 
//                                                                                               
//                                                                                               presentation.
//                   Presentation - String - a file type presentation (filled in from enumeration).
//                                                          
//                   Extension - String - a file type for an operating system.
//                                                          
//                   Picture - Picture - a format icon.
//
// Note: the format table can be overridden in the
// PrintManagerOverridable.OnFillSaveFormatsSettings() procedure.
//
Function SpreadsheetDocumentSaveFormatsSettings() Export
	
	FormatsTable = StandardSubsystemsServer.SpreadsheetDocumentSaveFormatsSettings();
	
	For Each SaveFormat In FormatsTable Do
		// To be used in mobile client.
		SaveFormat.Presentation = String(SaveFormat.Ref);
	EndDo;
		
	Return FormatsTable;
	
EndFunction

// Filters a list of print commands according to set functional options.
Procedure DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands, Form = Undefined)
	For each PrintCommandDetails In PrintCommands Do
		FunctionalOptionsOfPrintCommand = StrSplit(PrintCommandDetails.FunctionalOptions, ", ", False);
		CommandVisibility = FunctionalOptionsOfPrintCommand.Count() = 0;
		For Each FunctionalOption In FunctionalOptionsOfPrintCommand Do
			If TypeOf(Form) = Type("ManagedForm") Then
				CommandVisibility = CommandVisibility Or Form.GetFormFunctionalOption(FunctionalOption);
			Else
				CommandVisibility = CommandVisibility Or GetFunctionalOption(FunctionalOption);
			EndIf;
			
			If CommandVisibility Then
				Break;
			EndIf;
		EndDo;
		PrintCommandDetails.HiddenByFunctionalOptions = Not CommandVisibility;
	EndDo;
EndProcedure

// Saves a user print template to the infobase.
Procedure WriteTemplate(TemplateMetadataObjectName, TemplateAddressInTempStorage) Export
	
	ModifiedTemplate = GetFromTempStorage(TemplateAddressInTempStorage);
	
	NameParts = StrSplit(TemplateMetadataObjectName, ".");
	TemplateName = NameParts[NameParts.UBound()];
	
	OwnerName = "";
	For PartNumber = 0 To NameParts.UBound()-1 Do
		If Not IsBlankString(OwnerName) Then
			OwnerName = OwnerName + ".";
		EndIf;
		OwnerName = OwnerName + NameParts[PartNumber];
	EndDo;
	
	If NameParts.Count() = 3 Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		TemplateFromMetadata = Common.ObjectManagerByFullName(OwnerName).GetTemplate(TemplateName);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	Else
		TemplateFromMetadata = GetCommonTemplate(TemplateName);
	EndIf;
	
	Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
	Record.Object = OwnerName;
	Record.TemplateName = TemplateName;
	If TemplatesDiffer(TemplateFromMetadata, ModifiedTemplate) Then
		Record.Use = True;
		Record.Template = New ValueStorage(ModifiedTemplate, New Deflation(9));
		Record.Write();
	Else
		Record.Read();
		If Record.Selected() Then
			Record.Delete();
		EndIf;
	EndIf;
	
EndProcedure

Function QRCodeGenerationComponent()
	
	ErrorText = NStr("ru = 'Не удалось подключить внешнюю компоненту для генерации QR-кода. Подробности в журнале регистрации.'; en = 'Failed to attach QR code add-in. See the event log for details.'; pl = 'Nie udało się podłączyć zewnętrzny składnik do generowania kodu QR. Szczegóły w dzienniku rejestracji.';de = 'Es war nicht möglich, eine externe Komponente anzuschließen, um einen QR-Code zu generieren. Details im Ereignisprotokoll.';ro = 'Eșec la conectarea componentei externe pentru generarea codului QR. Detalii vezi în registrul logare.';tr = 'QR kodu oluşturmak için harici bir bileşen bağlanamadı. Kayıt defterindeki ayrıntılar.'; es_ES = 'No se puede conectar un componente externo para generar el código QR. Véase más en el registro de eventos.'");
	
	QRCodeGenerator = Common.AttachAddInFromTemplate("QRCodeExtension", "CommonTemplate.QRCodePrintingComponent");
	If QRCodeGenerator = Undefined Then 
		Common.MessageToUser(ErrorText);
	EndIf;
	
	Return QRCodeGenerator;
	
EndFunction

Procedure MessagePrintFormUnavailable(Object)
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Печать %1 не выполнена: выбранная печатная форма недоступна.'; en = 'Cannot print %1: the print form is unavailable.'; pl = '%1 nie został wydrukowany. Wybrany formularz wydruku jest niedostępny.';de = '%1 wurde nicht gedruckt. Das ausgewählte Druckformular ist nicht verfügbar.';ro = '%1 nu a fost imprimat: forma de tipar selectată nu este accesibilă.';tr = '%1 basılmadı. Seçilen baskı formu mevcut değildir.'; es_ES = '%1 no se ha imprimido. La versión impresa seleccionada no está disponible.'"), Object);
	Common.MessageToUser(MessageText, Object);
EndProcedure

// Generates a document package for sending to the printer.
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, CopiesCount = 1) Export
	
	DocumentsPackageToDisplay = New RepresentableDocumentBatch;
	DocumentsPackageToDisplay.Collate = True;
	PrintFormsCollection = SpreadsheetDocuments.UnloadValues();
	
	For Each PrintForm In PrintFormsCollection Do
		PrintInSets = PrintInSets Or PrintForm.DuplexPrinting <> DuplexPrintingType.None;
	EndDo;
	
	If PrintInSets AND PrintObjects.Count() > 1 Then 
		For Each PrintObject In PrintObjects Do
			AreaName = PrintObject.Presentation;
			For Each PrintForm In PrintFormsCollection Do
				Area = PrintForm.Areas.Find(AreaName);
				If Area = Undefined Then
					Continue;
				EndIf;
				
				SpreadsheetDocument = PrintForm.GetArea(Area.Top, , Area.Bottom);
				FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
				
				DocumentsPackageToDisplay.Content.Add().Data = PackageWithOneSpreadsheetDocument(SpreadsheetDocument);
			EndDo;
		EndDo;
	Else
		For Each PrintForm In PrintFormsCollection Do
			SpreadsheetDocument = New SpreadsheetDocument;
			SpreadsheetDocument.Put(PrintForm);
			FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
			DocumentsPackageToDisplay.Content.Add().Data = PackageWithOneSpreadsheetDocument(SpreadsheetDocument);
		EndDo;
	EndIf;
	
	SetsPackage = New RepresentableDocumentBatch;
	SetsPackage.Collate = True;
	For Number = 1 To CopiesCount Do
		SetsPackage.Content.Add().Data = DocumentsPackageToDisplay;
	EndDo;
	
	Return SetsPackage;
	
EndFunction

// Wraps a spreadsheet document in a package of displayed documents.
Function PackageWithOneSpreadsheetDocument(SpreadsheetDocument)
	SpreadsheetDocumentAddressInTempStorage = PutToTempStorage(SpreadsheetDocument);
	PackageWithOneDocument = New RepresentableDocumentBatch;
	PackageWithOneDocument.Collate = True;
	PackageWithOneDocument.Content.Add(SpreadsheetDocumentAddressInTempStorage);
	FillPropertyValues(PackageWithOneDocument, SpreadsheetDocument, "Output, DuplexPrinting, PrinterName, Copies, PrintAccuracy");
	If SpreadsheetDocument.Collate <> Undefined Then
		PackageWithOneDocument.Collate = SpreadsheetDocument.Collate;
	EndIf;
	Return PackageWithOneDocument;
EndFunction

// Generates a list of print commands from several objects.
Procedure FillPrintCommandsForObjectsList(ObjectsList, PrintCommands)
	PrintCommandsSources = New Map;
	For Each PrintCommandsSource In PrintCommandsSources() Do
		PrintCommandsSources.Insert(PrintCommandsSource, True);
	EndDo;
	
	For Each MetadataObject In ObjectsList Do
		If PrintCommandsSources[MetadataObject] = Undefined Then
			Continue;
		EndIf;
		
		FormPrintCommands = ObjectPrintCommands(MetadataObject);
		
		For Each PrintCommandToAdd In FormPrintCommands Do
			// Searching for a similar command that was added earlier.
			FoundCommands = PrintCommands.FindRows(New Structure("UUID", PrintCommandToAdd.UUID));
			
			For Each ExistingPrintCommand In FoundCommands Do
				// If the command is in the list, supplement the object types, for which it is intended.
				ObjectType = Type(StrReplace(MetadataObject.FullName(), ".", "Ref."));
				If ExistingPrintCommand.PrintObjectsTypes.Find(ObjectType) = Undefined Then
					ExistingPrintCommand.PrintObjectsTypes.Add(ObjectType);
				EndIf;
				// Clearing PrintManager if it is different for the existing command.
				If ExistingPrintCommand.PrintManager <> PrintCommandToAdd.PrintManager Then
					ExistingPrintCommand.PrintManager = "";
				EndIf;
			EndDo;
			If FoundCommands.Count() > 0 Then
				Continue;
			EndIf;
			
			If PrintCommandToAdd.PrintObjectsTypes.Count() = 0 Then
				PrintCommandToAdd.PrintObjectsTypes.Add(Type(StrReplace(MetadataObject.FullName(), ".", "Ref.")));
			EndIf;
			FillPropertyValues(PrintCommands.Add(), PrintCommandToAdd);
		EndDo;
	EndDo;
EndProcedure

// For internal use only.
//
Function CountOfUsedUserTemplates()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UserPrintTemplates.TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Use = TRUE";
	
	Result = Query.Execute().Unload();
	
	Return Result.Count();
	
EndFunction

Procedure SetPrintCommandsSettings(PrintCommands, Owner)
	
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	PrintCommandsSettings.UUID AS UUID
	|FROM
	|	InformationRegister.PrintCommandsSettings AS PrintCommandsSettings
	|WHERE
	|	PrintCommandsSettings.Owner = &Owner
	|	AND NOT PrintCommandsSettings.Visible";
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Selection = Query.Execute().Select();
	
	ListOfDisabledItems = New Map;
	While Selection.Next() Do
		ListOfDisabledItems.Insert(Selection.UUID, True);
	EndDo;
	
	For Each PrintCommand In PrintCommands Do
		PrintCommand.UUID = PrintCommandUUID(PrintCommand);
		If ListOfDisabledItems[PrintCommand.UUID] <> Undefined Then
			PrintCommand.Disabled = True;
		EndIf;
		PrintCommand.SaveFormat = String(PrintCommand.SaveFormat);
	EndDo;
	
EndProcedure

Function PrintCommandUUID(PrintCommand)
	
	Parameters = New Array;
	Parameters.Add("ID");
	Parameters.Add("PrintManager");
	Parameters.Add("Handler");
	Parameters.Add("SkipPreview");
	Parameters.Add("SaveFormat");
	Parameters.Add("FixedSet");
	Parameters.Add("AdditionalParameters");
	
	ParametersStructure = New Structure(StrConcat(Parameters, ","));
	FillPropertyValues(ParametersStructure, PrintCommand);
	
	Return Common.CheckSumString(ParametersStructure);
	
EndFunction

Function ObjectPrintCommands(MetadataObject) Export
	PrintCommands = CreatePrintCommandsCollection();
	If TypeOf(MetadataObject) <> Type("MetadataObject") Then 
		Return PrintCommands;
	EndIf;	
	
	Sources = AttachableCommands.CommandsSourcesTree();
	APISettings = AttachableCommands.AttachableObjectsInterfaceSettings();
	AttachedReportsAndDataProcessors = AttachableCommands.AttachableObjectsTable(APISettings);
	Source = AttachableCommands.RegisterSource(MetadataObject, Sources, AttachedReportsAndDataProcessors, APISettings);
	If Source.Manager = Undefined Then
		Return PrintCommands;
	EndIf;
	
	PrintCommandsToAdd = CreatePrintCommandsCollection();
	Source.Manager.AddPrintCommands(PrintCommandsToAdd);
	For Each PrintCommand In PrintCommandsToAdd Do
		If PrintCommand.PrintManager = Undefined Then
			PrintCommand.PrintManager = Source.FullName;
		EndIf;
		If PrintCommand.Order = 0 Then
			PrintCommand.Order = 50;
		EndIf;
		FillPropertyValues(PrintCommands.Add(), PrintCommand);
	EndDo;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, Source.FullName);
	EndIf;
	
	PrintCommands.Indexes.Add("PrintManager");
	FoundItems = AttachedReportsAndDataProcessors.FindRows(New Structure("AddPrintCommands", True));
	For Each AttachedObject In FoundItems Do
		AttachedObject.Manager.AddPrintCommands(PrintCommands);
		AddedCommands = PrintCommands.FindRows(New Structure("PrintManager", Undefined));
		For Each Command In AddedCommands Do
			Command.PrintManager = AttachedObject.FullName;
		EndDo;
	EndDo;
	
	For Each PrintCommand In PrintCommands Do
		PrintCommand.AdditionalParameters.Insert("AddExternalPrintFormsToSet", PrintCommand.AddExternalPrintFormsToSet);
	EndDo;
	
	PrintCommands.Sort("Order Asc, Presentation Asc");
	SetPrintCommandsSettings(PrintCommands, Source.MetadataRef);
	DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands);
	
	PrintCommands.Indexes.Add("UUID");
	Return PrintCommands;
EndFunction

Procedure CheckSpreadsheetDocumentLayoutByPrintObjects(SpreadsheetDocument, PrintObjects, Val PrintManager, Val ID)
	
	If SpreadsheetDocument.TableHeight = 0 Or PrintObjects.Count() = 0 Then
		Return;
	EndIf;
	
	HasLayoutByPrintObjects = False;
	For Each PrintObject In PrintObjects Do
		For Each Area In SpreadsheetDocument.Areas Do
			If Area.Name = PrintObject.Presentation Then
				HasLayoutByPrintObjects = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If StrFind(ID, ".") > 0 Then
		Position = StrFind(ID, ".", SearchDirection.FromEnd);
		PrintManager = Left(ID, Position - 1);
		ID = Mid(ID, Position + 1);
	EndIf;
	
	LayoutErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"ru = 'Отсутствует разметка табличного документа ""%1"" по объектам печати.
		|Необходимо использовать процедуру УправлениеПечатью.ЗадатьОбластьПечатиДокумента()
		|при формировании табличного документа'; 
		|en = 'Spreadsheet document %1 has no print areas.
		|When you generate a spreadsheet document, ensure that you run
		|PrintManagement.SetDocumentPrintArea() procedure.'; 
		|pl = 'Brak oznaczenia tabelarycznego dokumentu ""%1"" po obiektach wydruku. 
		|Należy stosować procedurę PrintManagement.SetDocumentPrintArea()
		|przy tworzeniu dokumentu tabelarycznego';
		|de = 'Es gibt keine Markierung des Tabellen-Dokuments ""%1"" auf den Druckobjekten,
		|Es ist notwendig, die Prozedur PrintManagement.SetDocumentPrintArea()
		|beim Erstellen eines tabellarischen Dokuments zu verwenden';
		|ro = 'Lipsește demarcarea documentului tabelar ""%1"" pe obiectele de imprimare.
		|Trebuie să utilizați procedura PrintManagement.SetDocumentPrintArea()
		|la generarea documentului tabelar';
		|tr = '""%1"" tablo belgesinde biçimlendirme yok. 
		| Tablo belgesi oluşturulduğunda PrintManagement.SetDocumentPrintArea()
		| prosedürü kullanılmalıdır'; 
		|es_ES = 'No hay marcas del documento de tabla ""%1"" por objetos de impresión.
		|Es necesario usar el procedimientos PrintManagement.SetDocumentPrintArea()
		|al generar el documento de tabla'"), ID);
	CommonClientServer.Validate(HasLayoutByPrintObjects, LayoutErrorText, PrintManager + "." + "Print()");
	
EndProcedure

Function TemplateNameParts(FullTemplateName)
	StringParts = StrSplit(FullTemplateName, ".");
	LastItemIndex = StringParts.UBound();
	TemplateName = StringParts[LastItemIndex];
	StringParts.Delete(LastItemIndex);
	ObjectName = StrConcat(StringParts, ".");
	
	Result = New Structure;
	Result.Insert("TemplateName", TemplateName);
	Result.Insert("ObjectName", ObjectName);
	
	Return Result;
EndFunction

Function SpreadsheetDocumentPropertiesToCopy() Export
	Return "FitToPage,Output,PageHeight,DuplexPrinting,Protection,PrinterName,LanguageCode,Copies,PrintScale,FirstPageNumber,PageOrientation,TopMargin,LeftMargin,BottomMargin,RightMargin,Collate,HeaderSize,FooterSize,PageSize,PrintAccuracy,BackgroundPicture,BlackAndWhite,PageWidth,PerPage";
EndFunction

Function TemplatesDiffer(Val InitialTemplate, ModifiedTemplate) Export
	Return Common.CheckSumString(NormalizeTemplate(InitialTemplate)) <> Common.CheckSumString(NormalizeTemplate(ModifiedTemplate));
EndFunction

Function NormalizeTemplate(Val Template)
	TemplateStorage = New ValueStorage(Template);
	Return TemplateStorage.Get();
EndFunction

Function AreaTypeSpecifiedIncorrectlyText()
	Return NStr("ru = 'Тип области не указан или указан некорректно.'; en = 'Area type is not specified or invalid.'; pl = 'Nie określono typu obszaru, lub określono go niepopranie.';de = 'Der Bereichstyp wurde nicht angegeben oder falsch angegeben.';ro = 'Tipul de zonă nu este specificat sau specificat incorect.';tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş.'; es_ES = 'Tipo de área no está especificado o especificado de forma incorrecta.'");
EndFunction

Function AreasSignaturesAndSeals(PrintObjects) Export
	
	SignaturesAndSeals = ObjectsSignaturesAndSeals(PrintObjects);
	
	AreasSignaturesAndSeals = New Map;
	For Each PrintObject In PrintObjects Do
		ObjectRef = PrintObject.Value;
		SignaturesAndSealsSet = SignaturesAndSeals[ObjectRef];
		AreasSignaturesAndSeals.Insert(PrintObject.Presentation, SignaturesAndSealsSet);
	EndDo;
	
	Return AreasSignaturesAndSeals;
	
EndFunction

Function ObjectsSignaturesAndSeals(Val PrintObjects) Export
	
	ObjectsList = PrintObjects.UnloadValues();
	SignaturesAndSeals = New Map;
	PrintManagementOverridable.OnGetSignaturesAndSeals(ObjectsList, SignaturesAndSeals);
	
	Return SignaturesAndSeals;
	
EndFunction

Procedure AddSignatureAndSeal(SpreadsheetDocument, AreasSignaturesAndSeals) Export
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		Position = StrFind(Drawing.Name, "_Document_");
		If Position > 0 Then
			ObjectAreaName = Mid(Drawing.Name, Position + 1);
			
			SignaturesAndSealsSet = AreasSignaturesAndSeals[ObjectAreaName];
			If SignaturesAndSealsSet = Undefined Then
				Continue;
			EndIf;
			
			Picture = SignaturesAndSealsSet[Left(Drawing.Name, Position - 1)];
			If Picture <> Undefined Then
				Drawing.Picture = Picture;
			EndIf;
			Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		EndIf;
	EndDo;

EndProcedure

Procedure RemoveSignatureAndSeal(SpreadsheetDocument, HideSignaturesAndSeals = False) Export
	
	DrawingsToDelete = New Array;
	For Each Drawing In SpreadsheetDocument.Drawings Do
		If IsSignatureOrSeal(Drawing) Then
			Drawing.Picture = New Picture;
			Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
			If HideSignaturesAndSeals Then
				DrawingsToDelete.Add(Drawing);
			EndIf;
		EndIf;
	EndDo;
	
	For Each Drawing In DrawingsToDelete Do
		SpreadsheetDocument.Drawings.Delete(Drawing);
	EndDo;
	
EndProcedure

Function IsSignatureOrSeal(Drawing) Export
	
	Return Drawing.DrawingType = SpreadsheetDocumentDrawingType.Picture AND StrFind(Drawing.Name, "_Document_") > 0;
	
EndFunction

Function AreaNamesPrefixesWithSignatureAndSeal() Export
	
	Result = New Array;
	Result.Add("Print");
	Result.Add("Signature");
	Result.Add("Facsimile");
	
	Return Result;
	
EndFunction

Function GenerateExternalPrintForm(AdditionalDataProcessorRef, ID, ObjectsList)
	
	SourceParameters = New Structure;
	SourceParameters.Insert("CommandID", ID);
	SourceParameters.Insert("RelatedObjects", ObjectsList);
	
	PrintFormsCollection = Undefined;
	PrintObjects = New ValueList;
	OutputParameters = PrepareOutputParametersStructure();
	
	PrintByExternalSource(AdditionalDataProcessorRef, SourceParameters, PrintFormsCollection,
	PrintObjects, OutputParameters);
	
	Result = New Structure;
	Result.Insert("PrintFormsCollection", PrintFormsCollection);
	Result.Insert("PrintObjects", PrintObjects);
	Result.Insert("OutputParameters", OutputParameters);
	
	Return Result;
	
EndFunction

Procedure InsertPicturesToHTML(HTMLFileName) Export
	
	TextDocument = New TextDocument();
	TextDocument.Read(HTMLFileName, TextEncoding.UTF8);
	HTMLText = TextDocument.GetText();
	
	HTMLFile = New File(HTMLFileName);
	
	PicturesFolderName = HTMLFile.BaseName + "_files";
	PicturesFolderPath = StrReplace(HTMLFile.FullName, HTMLFile.Name, PicturesFolderName);
	
	// The folder is only for pictures.
	PicturesFiles = FindFiles(PicturesFolderPath, "*");
	
	For Each PicturesFile In PicturesFiles Do
		PictureInText = Base64String(New BinaryData(PicturesFile.FullName));
		PictureInText = "data:image/" + Mid(PicturesFile.Extension,2) + ";base64," + Chars.LF + PictureInText;
		
		HTMLText = StrReplace(HTMLText, PicturesFolderName + "\" + PicturesFile.Name, PictureInText);
	EndDo;
		
	TextDocument.SetText(HTMLText);
	TextDocument.Write(HTMLFileName, TextEncoding.UTF8);
	
EndProcedure

Function FileName(FilePath)
	File = New File(FilePath);
	Return File.Name;
EndFunction

Function PackToArchive(FilesList)
	
	If FilesList.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	MemoryStream = New MemoryStream;
	ZipFileWriter = New ZipFileWriter(MemoryStream);
	
	TempFolder = FileSystem.CreateTemporaryDirectory();
	
	CreateDirectory(TempFolder);
	
	For Each File In FilesList Do
		FileName = TempFolder + File.FileName;
		FileName = UniqueFileName(FileName);
		File.BinaryData.Write(FileName);
		ZipFileWriter.Add(FileName);
	EndDo;
	
	ZipFileWriter.Write();
	MemoryStream.Seek(0, PositionInStream.Begin);
	
	DataReading = New DataReader(MemoryStream);
	DataReadingResult = DataReading.Read();
	BinaryData = DataReadingResult.GetBinaryData();
	
	DataReading.Close();
	MemoryStream.Close();
	
	FileSystem.DeleteTemporaryDirectory(TempFolder);
	
	Return BinaryData;
	
EndFunction

Function UniqueFileName(FileName)
	
	File = New File(FileName);
	NameWithoutExtension = File.BaseName;
	Extension = File.Extension;
	Folder = File.Path;
	
	Counter = 1;
	While File.Exist() Do
		Counter = Counter + 1;
		File = New File(Folder + NameWithoutExtension + " (" + Counter + ")" + Extension);
	EndDo;
	
	Return File.FullName;

EndFunction

Function SpreadsheetDocumentToBinaryData(SpreadsheetDocument, Format)
	
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, Format);
	
	If Format = SpreadsheetDocumentFileType.HTML Then
		InsertPicturesToHTML(TempFileName);
	EndIf;
	
	BinaryData = New BinaryData(TempFileName);
	
	Return BinaryData;
	
EndFunction

Function PrintFormsByObjects(PrintForm, PrintObjects) Export
	
	If PrintObjects.Count() = 0 Then
		Return New Structure("PrintObjectsNotSpecified", PrintForm);
	EndIf;
	
	Result = New Map;
	
	For Each PrintObject In PrintObjects Do
		AreaName = PrintObject.Presentation;
		Area = PrintForm.Areas.Find(AreaName);
		If Area = Undefined Then
			Continue;
		EndIf;
		
		If PrintObjects.Count() = 1 Then
			SpreadsheetDocument = PrintForm;
		Else
			SpreadsheetDocument = PrintForm.GetArea(Area.Top, , Area.Bottom);
			FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
		EndIf;
		
		Result.Insert(PrintObject.Value, SpreadsheetDocument);
	EndDo;
	
	Return Result;
	
EndFunction

Function ObjectPrintFormFileName(PrintObject, PrintFormFileName, PrintFormName) Export
	
	If PrintObject = Undefined Or PrintObject = "PrintObjectsNotSpecified" Then
		If ValueIsFilled(PrintFormName) Then
			Return PrintFormName;
		EndIf;
		Return GetTempFileName();
	EndIf;
	
	If TypeOf(PrintFormFileName) = Type("Map") Then
		Return String(PrintFormFileName[PrintObject]);
	ElsIf TypeOf(PrintFormFileName) = Type("String") AND Not IsBlankString(PrintFormFileName) Then
		Return PrintFormFileName;
	EndIf;
	
	Return DefaultPrintFormFileName(PrintObject, PrintFormName);
	
EndFunction

Function DefaultPrintFormFileName(PrintObject, PrintFormName)
	
	If Common.IsDocument(Metadata.FindByType(TypeOf(PrintObject))) Then
		
		DocumentContainsNumber = PrintObject.Metadata().NumberLength > 0;
		
		If DocumentContainsNumber Then
			AttributesList = "Date,Number";
			Template = NStr("ru = '[PrintFormName] № [Number] от [Date]'; en = '[PrintFormName] No. [Number], [Date]'; pl = '[PrintFormName] nr [Number] z dn. [Date]';de = '[PrintFormName] Nr.[Number] von[Date]';ro = '[PrintFormName] Nr. [Number] din [Date]';tr = '[PrintFormName] № [Number],  [Date]'; es_ES = '[PrintFormName] № [Number] de [Date]'");
		Else
			AttributesList = "Date";
			Template = NStr("ru = '[PrintFormName] от [Date]'; en = '[PrintFormName],  [Date]'; pl = '[PrintFormName] od [Date]';de = '[PrintFormName] von[Date]';ro = '[PrintFormName] din  [Date]';tr = '[PrintFormName],  [Date]'; es_ES = '[PrintFormName] de [Date]'");
		EndIf;
		
		ParametersToInsert = Common.ObjectAttributesValues(PrintObject, AttributesList);
		If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes") AND DocumentContainsNumber Then
			ModuleObjectsPrefixesClientServer = Common.CommonModule("ObjectPrefixationClientServer");
			ParametersToInsert.Number = ModuleObjectsPrefixesClientServer.NumberForPrinting(ParametersToInsert.Number);
		EndIf;
		ParametersToInsert.Date = Format(ParametersToInsert.Date, "DLF=D");
		ParametersToInsert.Insert("PrintFormName", PrintFormName);
		
	Else
		
		ParametersToInsert = New Structure;
		ParametersToInsert.Insert("PrintFormName",PrintFormName);
		ParametersToInsert.Insert("ObjectPresentation", Common.SubjectString(PrintObject));
		ParametersToInsert.Insert("CurrentDate",Format(CurrentSessionDate(), "DLF=D"));
		Template = NStr("ru = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]'; en = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]'; pl = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]';de = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]';ro = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]';tr = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]'; es_ES = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]'");
		
	EndIf;
	
	Return StringFunctionsClientServer.InsertParametersIntoString(Template, ParametersToInsert);
	
EndFunction

Function OfficeDocumentFileName(Val FileName, Val Transliterate = False) Export
	
	FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
	
	ExtensionsToExpect = New Map;
	ExtensionsToExpect.Insert(".docx", True);
	ExtensionsToExpect.Insert(".doc", True);
	ExtensionsToExpect.Insert(".odt", True);
	ExtensionsToExpect.Insert(".html", True);
	
	File = New File(FileName);
	If ExtensionsToExpect[File.Extension] = Undefined Then
		FileName = FileName + ".docx";
	EndIf;
	
	If Transliterate Then
		FileName = StringFunctionsClientServer.LatinString(FileName)
	EndIf;
	
	Return FileName;
	
EndFunction

// A list of possible template names:
//  1) in session language
//  2) in configuration language
//  3) without specifying a language.
Function TemplateNames(Val TemplateName)
	
	Result = New Array;
	If StrFind(TemplateName, "PF_DOC_") > 0 
		Or StrFind(TemplateName, "PF_ODT_") > 0 Then
		
		CurrentLanguage = CurrentLanguage();
		If TypeOf(CurrentLanguage) <> Type("MetadataObject") Then
			CurrentLanguage = Metadata.DefaultLanguage;
		EndIf;
		LanguageCode = CurrentLanguage.LanguageCode;
		Result.Add(TemplateName + "_" + LanguageCode);
		If LanguageCode <> Metadata.DefaultLanguage.LanguageCode Then
			Result.Add(TemplateName + "_" + Metadata.DefaultLanguage.LanguageCode);
		EndIf;
		
	EndIf;
	Result.Add(TemplateName);
	Return Result;

EndFunction

// Constructor for the PrintFormsCollection of the Print procedure.
//
// Returns:
//  ValueTable - a blank collection of print forms:
//   * TemplateName - String - a print form ID.
//   * NameUpper - String - an ID in uppercase for quick search.
//   * TemplateSynonym - String - a print form presentation.
//   * SpreadsheetDocument - SpreadsheetDocument - a print form.
//   * Copies - Number - a number of copies to be printed.
//   * Picture - Picture - (not used).
//   * FullTemplatePath - String - used for quick access to print form template editing.
//   * PrintFormFileName - String - a file name.
//                           - Map - file names for each object:
//                              ** Key - AnyRef - a reference to the print object.
//                              ** Value - String - a file name.
//   * OfficeDocuments - Map - a collection of print forms in the format of office documents:
//                         ** Key - String - an address in the temporary storage of binary data of the print form.
//                         ** Value - String - a print form file name.
Function PreparePrintFormsCollection(Val IDs)
	
	Result = New ValueTable;
	For Each ColumnName In PrintManagementClientServer.PrintFormsCollectionFieldsNames() Do
		Result.Columns.Add(ColumnName);
	EndDo;
	
	If TypeOf(IDs) = Type("String") Then
		IDs = StrSplit(IDs, ",");
	EndIf;
	
	For Each ID In IDs Do
		PrintForm = Result.Find(ID, "TemplateName");
		If PrintForm = Undefined Then
			PrintForm = Result.Add();
			PrintForm.TemplateName = ID;
			PrintForm.UpperCaseName = Upper(ID);
			PrintForm.Copies = 1;
		Else
			PrintForm.Copies = PrintForm.Copies + 1;
		EndIf;
	EndDo;
	
	Result.Indexes.Add("UpperCaseName");
	Return Result;
	
EndFunction

// Preparing a structure of output parameters for the object manager that generates print forms.
//
Function PrepareOutputParametersStructure() Export
	
	OutputParameters = New Structure;
	OutputParameters.Insert("PrintBySetsAvailable", False); // not used
	
	EmailParametersStructure = New Structure("Recipient,Subject,Text", Undefined, "", "");
	OutputParameters.Insert("SendOptions", EmailParametersStructure);
	
	Return OutputParameters;
	
EndFunction

Function PrintSettings() Export
	
	Settings = New Structure;
	Settings.Insert("UseSignaturesAndSeals", True);
	Settings.Insert("HideSignaturesAndSealsForEditing", False);
	
	Return Settings;
	
EndFunction

#EndRegion
