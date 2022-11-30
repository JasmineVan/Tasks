///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates and displays print forms.
// 
// Parameters:
//  PrintManagerName - String - a print manager for the objects to print.
//  TemplateNames - String - print form IDs.
//  ObjectsArray - Ref, Array - print objects.
//  FormOwner - ManagedForm - a form, from which printing is executed.
//  PrintParameters - Structure - arbitrary parameters to pass to the print manager.
//
// Example:
//   PrintManagerClient.ExecutePrintCommand("DataProcessor.PrintForm", "GoodsWriteOff", DocumentsForPrinting, ThisObject);
//
Procedure ExecutePrintCommand(PrintManagerName, TemplatesNames, ObjectsArray, FormOwner, PrintParameters = Undefined) Export
	
	If NOT CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure("PrintManagerName,TemplatesNames,CommandParameter,PrintParameters");
	OpeningParameters.PrintManagerName = PrintManagerName;
	OpeningParameters.TemplatesNames		 = TemplatesNames;
	OpeningParameters.CommandParameter	 = ObjectsArray;
	OpeningParameters.PrintParameters	 = PrintParameters;
	OpenForm("CommonForm.PrintDocuments", OpeningParameters, FormOwner, String(New UUID));
	
EndProcedure

// Generates and outputs print forms to the printer.
//
// Parameters:
//  PrintManagerName - String - a print manager for the objects to print.
//  TemplateNames - String - print form IDs.
//  ObjectsArray - Ref, Array - print objects.
//  PrintParameters - Structure - arbitrary parameters to pass to the print manager.
//
// Example:
//   PrintManagerClient.ExecutePrintToPrinterCommand("DataProcessor.PrintForm", "GoodsWriteOff", DocumentsForPrinting);
//
Procedure ExecutePrintToPrinterCommand(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters = Undefined) Export

	// Checking a number of objects.
	If NOT CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	// Generating spreadsheet documents.
#If ThickClientOrdinaryApplication Then
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrintOrdinaryApplication(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
	If NOT PrintForms.Cancel Then
		PrintObjects = New ValueList;
		For Each PrintObject In PrintForms.PrintObjects Do
			PrintObjects.Add(PrintObject.Value, PrintObject.Key);
		EndDo;
		PrintForms.PrintObjects = PrintObjects;
	EndIf;
#Else
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrint(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
#EndIf
	
	If PrintForms.Cancel Then
		CommonClient.MessageToUser(NStr("ru = 'Нет прав для вывода печатной формы на принтер, обратитесь к администратору.'; en = 'Insufficient rights to print out the form. Contact your administrator.'; pl = 'Nie masz uprawnień do wysyłania wydruku na drukarkę. Skontaktuj się z administratorem.';de = 'Sie haben keine Rechte, ein Druckformular auf dem Drucker zu senden. Kontaktieren Sie Ihren Administrator.';ro = 'Lipsesc drepturile de imprimare a formei de tipar, adresați-vă administratorului.';tr = 'Yazıcıya baskı formu gönderme hakkınız yoktur. Yöneticinize başvurun.'; es_ES = 'Usted no tiene derechos para enviar la versión impresa en la impresora. Contactar su administrador.'"));
		Return;
	EndIf;
	
	// Printing
	PrintSpreadsheetDocuments(PrintForms.SpreadsheetDocuments, PrintForms.PrintObjects);
	
EndProcedure

// Outputting spreadsheet documents to the printer.
//
// Parameters:
//  SpreadsheetDocuments - ValueList - print forms.
//  PrintObjects - ValueList - a correspondence between objects and names of spreadsheet document areas.
//  PrintInSets          - Boolean, Undefined - not used (calculated automatically).
//  SetsCopies - Number - a number of each document set copies.
Procedure PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects, Val PrintInSets = Undefined, 
	Val SetCopies = 1) Export
	
	PrintInSets = SpreadsheetDocuments.Count() > 1;
	DocumentsPackageToDisplay = PrintManagementServerCall.DocumentsPackage(SpreadsheetDocuments,
		PrintObjects, PrintInSets, SetCopies);
	DocumentsPackageToDisplay.Print(PrintDialogUseMode.DontUse);
	
EndProcedure

// Executes interactive document posting before printing.
// If there are unposted documents, prompts the user to post them. Asks the user whether they want 
// to continue if any of the documents are not posted and at the same time some of the documents are posted.
//
// Parameters:
//  CompletionProcedureDetails - NotifyDescription - a procedure to which control after execution is 
//                                                     transferred.
//                                Parameters of the procedure being called:
//                                  DocumentsList - Array - posted documents.
//                                  AdditionalParameters - a value specified when creating a 
//                                                            notification object.
//  DocumentsList - Array - references to the documents that require posting.
//  Form - ManagedForm - a form the command is called from. The parameter is required to reread the 
//                                                    form when the procedure is called from the 
//                                                    object form.
Procedure CheckDocumentsPosting(CompletionProcedureDetails, DocumentsList, Form = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionProcedureDetails", CompletionProcedureDetails);
	AdditionalParameters.Insert("DocumentsList", DocumentsList);
	AdditionalParameters.Insert("Form", Form);
	
	UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(DocumentsList);
	HasUnpostedDocuments = UnpostedDocuments.Count() > 0;
	If HasUnpostedDocuments Then
		AdditionalParameters.Insert("UnpostedDocuments", UnpostedDocuments);
		PrintManagementInternalClient.CheckDocumentsPostedPostingDialog(AdditionalParameters);
	Else
		ExecuteNotifyProcessing(CompletionProcedureDetails, DocumentsList);
	EndIf;
	
EndProcedure

// Opens the PrintDocuments form for a spreadsheet document collection.
//
// Parameters:
//  PrintFormsCollection - Array - see NewPrintFormsCollection(). 
//  PrintObjects - ValueList - see PrintManagerOverridable.OnPrint. 
//  FormOwner - ManagedForm - a form, from which the printing is executed.
//
Procedure PrintDocuments(PrintFormsCollection, Val PrintObjects = Undefined, FormOwner = Undefined) Export
	If PrintObjects = Undefined Then
		PrintObjects = New ValueList;
	EndIf;
	
	UniqueKey = String(New UUID);
	
	OpeningParameters = New Structure("PrintManagerName,TemplatesNames,CommandParameter,PrintParameters");
	OpeningParameters.CommandParameter = New Array;
	OpeningParameters.PrintParameters = New Structure;
	OpeningParameters.Insert("PrintFormsCollection", PrintFormsCollection);
	OpeningParameters.Insert("PrintObjects", PrintObjects);
	
	OpenForm("CommonForm.PrintDocuments", OpeningParameters, FormOwner, UniqueKey);
EndProcedure

// Constructor of the PrintFormsCollection parameter for procedures and functions of this module.
// See PrintDocuments() 
// See PrintFormDetails(). 
//
// Parameters:
//  IDs - String - print form IDs.
//
// Returns:
//  Array - a collection of print form descriptions. The collection is designed for use as the 
//           PrintFormsCollection parameter in other procedures of the client software interface of the subsystem.
//           To access collection items, use the PrintFormDetails function.
//
Function NewPrintFormsCollection(Val IDs) Export
	
	If TypeOf(IDs) = Type("String") Then
		IDs = StrSplit(IDs, ",");
	EndIf;
	
	Fields = PrintManagementClientServer.PrintFormsCollectionFieldsNames();
	AddedPrintForms = New Map;
	Result = New Array;
	
	For Each ID In IDs Do
		PrintForm = AddedPrintForms[ID];
		If PrintForm = Undefined Then
			PrintForm = New Structure(StrConcat(Fields, ","));
			PrintForm.TemplateName = ID;
			PrintForm.UpperCaseName = Upper(ID);
			PrintForm.Copies = 1;
			AddedPrintForms.Insert(ID, PrintForm);
			Result.Add(PrintForm);
		Else
			PrintForm.Copies = PrintForm.Copies + 1;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns description of the print form found in the collection.
// If the description is not found, returns Undefined.
//
// Parameters:
//  PrintFormsCollection - Array - see NewPrintFormsCollection(). 
//  ID - String - a print form ID.
//
// Returns:
//  Structure - print form details found in a print form collection:
//   * TemplateSynonym - String - a print form presentation.
//   * SpreadsheetDocument - SpreadsheetDocument - a print form.
//   * Copies - Number - a number of copies to be printed.
//   * FullTemplatePath - String - used for quick access to print form template editing.
//   * PrintFormFileName - String - a file name.
//                           - Map - file names for each object:
//                              ** Key - AnyRef - a reference to the print object.
//                              ** Value - String - a file name.
//   * OfficeDocuments - Map - a collection of print forms in the format of office documents:
//                         ** Key - String - an address in the temporary storage of binary data of the print form.
//                         ** Value - String - a print form file name.
//
Function PrintFormDetails(PrintFormsCollection, ID) Export
	For Each PrintFormDetails In PrintFormsCollection Do
		If PrintFormDetails.UpperCaseName = Upper(ID) Then
			Return PrintFormDetails;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Opens a selection form of template opening mode.
//
Procedure SetActionOnChoosePrintFormTemplate() Export
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode");
	
EndProcedure

// Opens a form showing how to create a facsimile signature and a seal.
Procedure ShowInstructionOnHowToCreateFacsimileSignatureAndSeal() Export
	
	ExecutePrintCommand("InformationRegister.SuppliedPrintTemplates", "GuideToCreateFacsimileAndStamp", 
		PredefinedValue("Catalog.MetadataObjectIDs.EmptyRef"), Undefined, New Structure);
	
EndProcedure

// For use in procedures of the PrintManagerClientOverridable.PrintDocuments<...> module.
// Returns a parameter collection of the current print form in the Print documents form (CommonForm.PrintDocuments).
// 
// Parameters:
//  Form - ManagedForm - PrintDocuments form passed in the Form parameter of the common module procedure.
//                             PrintManagerClientOverridable.
//
// Returns:
//  FormDataCollectionItem - current print form settings.
//
Function CurrentPrintFormSetup(Form) Export
	Result = Form.Items.PrintFormsSettings.CurrentData;
	If Result = Undefined AND Form.PrintFormsSettings.Count() > 0 Then
		Result = Form.PrintFormsSettings[0];
	EndIf;
	Return Result;
EndFunction

#Region ObsoleteProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Operations with office document templates.

//	The section contains interface functions (API) used for creating print forms based on Microsoft 
//	Office (Microsoft Word templates) and Open Office (OO Writer templates) office documents.
//
////////////////////////////////////////////////////////////////////////////////
//	Used data types (determined by specific implementations).
//	RefPrintForm	- a reference to a print form.
//	RefTemplate			- a reference to a template.
//	Area				- a reference to a print form area or a template area (structure), it is overridden with 
//						internal area data in the interface module.
//						
//	AreaDetails			- a template area description (see below).
//	FillingData		- either a structure or an array of structures (for lists and tables).
//							
////////////////////////////////////////////////////////////////////////////////
//	AreaDetails - a structure that describes template areas prepared by the user key AreaName - an 
//	area name key AreaTypeType - 	Header.
//	
//							Footer
//							Total
//							TableRow
//							List
//

////////////////////////////////////////////////////////////////////////////////
// Functions for initializing and closing references.

// Obsolete. Use PrintManager.InitializePrintForm.
//
// Creates a connection to the output print form.
// Call this function before performing any actions on the form.
// The function does not work in any other browsers except for Internet Explorer.
// This function requires the file system extension installed to operate in the web client.
//
// Parameters:
//  DocumentType - String - a print form type: DOC or ODT.
//  TemplatePageSettings - Map - parameters from the structure returned by the InitializeTemplate 
//                                           function (the parameter is obsolete, skip it and use the Template parameter).
//  Template - Structure - a result of the InitializeTemplate function.
//
// Returns:
//  Structure - a new print form.
// 
Function InitializePrintForm(Val DocumentType, Val TemplatePagesSettings = Undefined, Template = Undefined) Export
	
	If Upper(DocumentType) = "DOC" Then
		Parameter = ?(Template = Undefined, TemplatePagesSettings, Template); // For backward compatibility
		PrintForm = PrintManagementMSWordClient.InitializeMSWordPrintForm(Parameter);
		PrintForm.Insert("Type", "DOC");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	ElsIf Upper(DocumentType) = "ODT" Then
		PrintForm = PrintManagementOOWriterClient.InitializeOOWriterPrintForm(Template);
		PrintForm.Insert("Type", "ODT");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	EndIf;
	
EndFunction

// Obsolete. Use PrintManager.InitializeOfficeDocumentTemplate.
//
// Creates a COM connection with a template. This connection is used later for getting template 
// areas (tags and tables).
// The function does not work in any other browsers except for Internet Explorer.
// This function requires the file system extension installed to operate in the web client.
//
// Parameters:
//  BinaryTemplateData - BinaryData - a binary template data.
//  TemplateType - String - a print form template type: DOC or ODT.
//  TemplateName - String - a name to be used for creating a temporary template file.
//
// Returns:
//  Structure - a template.
//
Function InitializeOfficeDocumentTemplate(Val BinaryTemplateData, Val TemplateType, Val TemplateName = "") Export
	
	Template = Undefined;
	TempFileName = "";
	
	#If WebClient Then
		If IsBlankString(TemplateName) Then
			TempFileName = String(New UUID) + "." + Lower(TemplateType);
		Else
			TempFileName = TemplateName + "." + Lower(TemplateType);
		EndIf;
	#EndIf
	
	If Upper(TemplateType) = "DOC" Then
		Template = PrintManagementMSWordClient.GetMSWordTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "DOC");
		EndIf;
	ElsIf Upper(TemplateType) = "ODT" Then
		Template = PrintManagementOOWriterClient.GetOOWriterTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "ODT");
			Template.Insert("TemplatePagesSettings", Undefined);
		EndIf;
	EndIf;
	
	Return Template;
	
EndFunction

// Obsolete. Use the PrintManager.ClearRefs procedure.
//
// Releases links in the created interface of connection with office application.
// Always call this procedure after the template is generated and the print form is displayed to a user.
//
// Parameters:
//  PrintForm - Structure - a result of the InitializePrintForm and InitializeOfficeDocumentTemplate functions.
//  CloseApplication - Boolean - True, if it is necessary to close the application.
//                                  Connection to the template must be closed when closing the application.
//                                  PrintForm does not need to be closed.
//
Procedure ClearRefs(PrintForm, Val CloseApplication = True) Export
	
	If PrintForm <> Undefined Then
		If PrintForm.Type = "DOC" Then
			PrintManagementMSWordClient.CloseConnection(PrintForm, CloseApplication);
		Else
			PrintManagementOOWriterClient.CloseConnection(PrintForm, CloseApplication);
		EndIf;
		PrintForm = Undefined;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Function that displays a print form to a user.

// Obsolete. It is not required anymore.
//
// Shows the generated document to a user.
//
// Parameters:
//  PrintForm - Structure - a result of the InitializePrintForm function.
//
Procedure ShowDocument(Val PrintForm) Export
	
	If PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.ShowMSWordDocument(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.ShowOOWriterDocument(PrintForm);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions for getting template areas, outputting template areas to print forms, and filling 
// parameters in template areas.

// Obsolete. Use PrintManager.TemplateArea.
//
// Gets a print form template area.
//
// Parameters:
//   RefToTemplate - Structure - a print form template.
//   AreaDetails - Structure - an area description.
//
// Returns:
//  Structure - a template area.
//
Function TemplateArea(Val RefToTemplate, Val AreaDetails) Export
	
	Area = Undefined;
	If RefToTemplate.Type = "DOC" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementMSWordClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementMSWordClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Total" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		ElsIf	AreaDetails.AreaType = "TableRow" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName);
		ElsIf	AreaDetails.AreaType = "List" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Тип области не указан или указан некорректно: %1.'; en = 'Area type is not specified or invalid: %1.'; pl = 'Nie określono typu obszaru, lub określono go niepopranie: %1.';de = 'Bereichstyp ist nicht angegeben oder falsch angegeben: %1.';ro = 'Tipul de zonă nu este specificat sau specificat incorect: %1.';tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş: %1.'; es_ES = 'Tipo de área no está especificado o especificado de forma incorrecta: %1.'"), AreaDetails.AreaType);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	ElsIf RefToTemplate.Type = "ODT" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementOOWriterClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementOOWriterClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Total"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			Area = PrintManagementOOWriterClient.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Тип области не указан или указан некорректно: %1.'; en = 'Area type is not specified or invalid: %1.'; pl = 'Nie określono typu obszaru, lub określono go niepopranie: %1.';de = 'Bereichstyp ist nicht angegeben oder falsch angegeben: %1.';ro = 'Tipul de zonă nu este specificat sau specificat incorect: %1.';tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş: %1.'; es_ES = 'Tipo de área no está especificado o especificado de forma incorrecta: %1.'"), AreaDetails.AreaName);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	EndIf;
	
	Return Area;
	
EndFunction

// Obsolete. Use PrintManager.AttachArea.
//
// Attaches an area to a template print form.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see InitializePrintForm. 
//  TemplateArea - Structure - see TemplateArea. 
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachArea(Val PrintForm, Val TemplateArea, Val GoToNextRow = True) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	Try
		AreaDetails = TemplateArea.AreaDetails;
		
		If PrintForm.Type = "DOC" Then
			
			OutputArea = Undefined;
			
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementMSWordClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementMSWordClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Total" Then
				OutputArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow);
			ElsIf	AreaDetails.AreaType = "List" Then
				OutputArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				If PrintForm.LastOutputArea <> Undefined
				   AND PrintForm.LastOutputArea.AreaType = "TableRow"
				   AND NOT PrintForm.LastOutputArea.GoToNextRow Then
					OutputArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow, True);
				Else
					OutputArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow);
				EndIf;
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			
			AreaDetails.Insert("Area", OutputArea);
			AreaDetails.Insert("GoToNextRow", GoToNextRow);
			
			// Contains an area type and area borders (if required).
			PrintForm.LastOutputArea = AreaDetails;
			
		ElsIf PrintForm.Type = "ODT" Then
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementOOWriterClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementOOWriterClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Total"
					OR AreaDetails.AreaType = "List" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow, True);
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			// Contains an area type and area borders (if required).
			PrintForm.LastOutputArea = AreaDetails;
		EndIf;
	Except
		ErrorMessage = TrimAll(BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при попытке вывести область ""%1"" из макета.'; en = 'Error occurred during output of %1 layout area.'; pl = 'Podczas próby uzyskania obszaru ""%1"" z szablonu wystąpił błąd.';de = 'Beim Versuch, den Bereich ""%1"" aus der Vorlage zu erhalten, ist ein Fehler aufgetreten.';ro = 'Eroare la tentativa de afișare a domeniului ""%1"" din machetă.';tr = 'Şablondan alan ""%1"" elde etmeye çalışırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al intentar obtener el área ""%1"" desde el modelo.'"),
			TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Obsolete. Use PrintManager.FillParameters.
//
// Fills parameters of the print form area.
//
// Parameters:
//  PrintForm - Structure - either a print form area or a print form itself.
//  Data - Structure - filling data.
//
Procedure FillParameters(Val PrintForm, Val Data) Export
	
	AreaDetails = PrintForm.LastOutputArea;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "Header" Then
			PrintManagementMSWordClient.FillHeaderParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			PrintManagementMSWordClient.FillFooterParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Total"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.FillParameters(PrintForm.LastOutputArea.Area, Data);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		PrintForm.LastOutputArea.AreaType = "Header" Then
			PrintManagementOOWriterClient.SetMainCursorToHeader(PrintForm);
		ElsIf	PrintForm.LastOutputArea.AreaType = "Footer" Then
			PrintManagementOOWriterClient.SetMainCursorToFooter(PrintForm);
		ElsIf	AreaDetails.AreaType = "Total"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
		EndIf;
		PrintManagementOOWriterClient.FillParameters(PrintForm, Data);
	EndIf;
	
EndProcedure

// Obsolete. Use PrintManager.AttachAreaAndFillParameters.
//
// Adds an area from a template to a print form, replacing the area parameters with the object data values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see InitializePrintForm. 
//  TemplateArea - Structure - see TemplateArea. 
//  Data - Structure - filling data.
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachAreaAndFillParameters(Val PrintForm, Val TemplateArea,
	Val Data, Val GoToNextRow = True) Export
	
	If TemplateArea <> Undefined Then
		AttachArea(PrintForm, TemplateArea, GoToNextRow);
		FillParameters(PrintForm, Data)
	EndIf;
	
EndProcedure

// Obsolete. Use PrintManager.AttachAndFillCollection.
//
// Adds an area from a template to a print form, replacing the area parameters with the object data 
// values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - Structure - a print form, see InitializePrintForm. 
//  TemplateArea - Structure - see TemplateArea(). 
//  Data - Array - an item collection of the Structure type - object data.
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure JoinAndFillCollection(Val PrintForm,
										Val TemplateArea,
										Val Data,
										Val GoToNextRow = True) Export
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementMSWordClient.JoinAndFillTableArea(PrintForm, TemplateArea, Data, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, True, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, False, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	EndIf;
	
EndProcedure

// Obsolete. Use PrintManager.InsertNewLineBreak.
//
// Inserts a line break as a newline character.
//
// Parameters:
//  PrintForm - Structure - a print form, see InitializePrintForm. 
//
Procedure InsertBreakAtNewLine(Val PrintForm) Export
	
	If	  PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.InsertBreakAtNewLine(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

// Other obsolete procedures and functions

// Obsolete. Use AttachableCommandsClient.ExecuteCommand.
//
// Handler of the dynamically connected print command.
//
// Parameters:
//  Command - FormCommand - dynamically connected form command that executes the Attachable_ExecutePrintCommand handler.
//           - Structure - the PrintCommands table row converted into a structure.
//  Form - ManagedForm - a form the command is called from.
//  Source - FormTable, FormDataStructure - a print object source (Form.Object, Form.Item.List).
//           - Array - a list of print objects.
Procedure RunConnectedPrintCommand(Val Command, Val Form, Val Source) Export
	AttachableCommandsClient.ExecuteCommand(Form, Command, Source);
EndProcedure

// Obsolete. Use AttachableCommandsClient.StartUpdateCommands.
//
// Starts a deferred process of updating print commands on the form.
//
// Parameters:
//  Form - ManagedForm - a form that requires update of print commands.
//
Procedure StartCommandUpdate(Form) Export
	AttachableCommandsClient.StartCommandUpdate(Form);
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Opens a template file import dialog box for editing it in an external application.
Procedure EditTemplateInExternalApplication(NotifyDescription, TemplateParameters, Form) Export
	OpenForm("InformationRegister.UserPrintTemplates.Form.EditTemplate", TemplateParameters, Form, , , , NotifyDescription);
EndProcedure

#EndRegion

#Region Private

// Before executing a print command, check whether at least one object is passed as an empty array 
// can be passed for commands that accept multiple objects.
Function CheckPassedObjectsCount(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") AND CommandParameter.Count() = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function AreaTypeSpecifiedIncorrectlyText()
	Return NStr("ru = 'Тип области не указан или указан некорректно.'; en = 'Area type is not specified or invalid.'; pl = 'Nie określono typu obszaru, lub określono go niepopranie.';de = 'Der Bereichstyp wurde nicht angegeben oder falsch angegeben.';ro = 'Tipul de zonă nu este specificat sau specificat incorect.';tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş.'; es_ES = 'Tipo de área no está especificado o especificado de forma incorrecta.'");
EndFunction

#EndRegion
