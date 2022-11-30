///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Printing using templates in the OpenDocument Text (odt) format on the client. For backward compatibility.
//
// Description of the reference to a print form and a template.
// Structure containing fields:
// ServiceManager - service manager, Open Office service.
// Desktop - Open Office application (UNO service).
// Document - a document (print form).
// Type - a print form type ("ODT").
//
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Print form initialization: a COM object is created and properties are set for it.
// 
Function InitializeOOWriterPrintForm(Val Template = Undefined) Export
	
	Handler = New Structure("ServiceManager,Desktop,Document,Type");
	
#If Not MobileClient Then
	
	Try
		ServiceManager = New COMObject("com.sun.star.ServiceManager");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			NStr("ru = 'Ошибка при связи с сервис менеджером (com.sun.star.ServiceManager).'; en = 'Error occurred connecting to Service Manager (com.sun.star.ServiceManager).'; pl = 'Podczas połączenia z menedżerem serwisu wystąpił błąd (com.sun.star.ServiceManager).';de = 'Beim Kontaktieren des Service Managers (com.sun.star.ServiceManager) ist ein Fehler aufgetreten.';ro = 'Eroare la conectarea cu managerul de servicii (com.sun.star.ServiceManager).';tr = 'Servis yöneticisiyle iletişim kurarken bir hata oluştu (com.sun.star.ServiceManager).'; es_ES = 'Ha ocurrido un error al contactar el gestor de servicio (com.sun.star.ServiceManager).'")
			+ Chars.LF + DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
	Try
		Desktop = ServiceManager.CreateInstance("com.sun.star.frame.Desktop");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			NStr("ru = 'Ошибка при запуске сервиса Desktop (com.sun.star.frame.Desktop).'; en = 'Error occurred starting Desktop service (com.sun.star.frame.Desktop).'; pl = 'Podczas uruchamiania serwisu Desktop wystąpił błąd (com.sun.star.frame.Desktop).';de = 'Beim Starten des Desktop-Services (com.sun.star.frame.Desktop) ist ein Fehler aufgetreten.';ro = 'Eroare la lansarea serviciului Desktop (com.sun.star.frame.Desktop).';tr = 'Masaüstü hizmetini başlatırken bir hata oluştu (com.sun.star.frame.Desktop).'; es_ES = 'Ha ocurrido un error al lanzar el servicio de Escritorio (com.sun.star.frame.Desktop).'")
			+ Chars.LF + DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
	Parameters = GetComSafeArray();
	
#If Not WebClient Then
	Parameters.SetValue(0, PropertyValue(ServiceManager, "Hidden", True));
#EndIf
	
	Document = Desktop.LoadComponentFromURL("private:factory/swriter", "_blank", 0, Parameters);
	
#If WebClient Then
	Document.getCurrentController().getFrame().getContainerWindow().setVisible(False);
#EndIf
	
	If Template <> Undefined Then
		TemplateStyleName = Template.Document.CurrentController.getViewCursor().PageStyleName;
		TemplateStyle = Template.Document.StyleFamilies.getByName("PageStyles").getByName(TemplateStyleName);
			
		StyleName = Document.CurrentController.getViewCursor().PageStyleName;
		Style = Document.StyleFamilies.getByName("PageStyles").getByName(StyleName);
		
		Style.TopMargin = TemplateStyle.TopMargin;
		Style.LeftMargin = TemplateStyle.LeftMargin;
		Style.RightMargin = TemplateStyle.RightMargin;
		Style.BottomMargin = TemplateStyle.BottomMargin;
	EndIf;
	
	Handler.ServiceManager = ServiceManager;
	Handler.Desktop = Desktop;
	Handler.Document = Document;
	
#EndIf

	Return Handler;
	
EndFunction

// Returns a structure with a print form template.
//
// Parameters:
//   BinaryTemplateData - BinaryData - binary data of a template.
// Returns:
//   structure - a template reference.
//
Function GetOOWriterTemplate(Val BinaryTemplateData, TempFileName) Export
	
	Handler = New Structure("ServiceManager,Desktop,Document,FileName");
	
#If Not MobileClient Then
	Try
		ServiceManager = New COMObject("com.sun.star.ServiceManager");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			NStr("ru = 'Ошибка при связи с сервис менеджером (com.sun.star.ServiceManager).'; en = 'Error occurred connecting to Service Manager (com.sun.star.ServiceManager).'; pl = 'Podczas połączenia z menedżerem serwisu wystąpił błąd (com.sun.star.ServiceManager).';de = 'Beim Kontaktieren des Service Managers (com.sun.star.ServiceManager) ist ein Fehler aufgetreten.';ro = 'Eroare la conectarea cu managerul de servicii (com.sun.star.ServiceManager).';tr = 'Servis yöneticisiyle iletişim kurarken bir hata oluştu (com.sun.star.ServiceManager).'; es_ES = 'Ha ocurrido un error al contactar el gestor de servicio (com.sun.star.ServiceManager).'")
			+ Chars.LF + DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
	Try
		Desktop = ServiceManager.CreateInstance("com.sun.star.frame.Desktop");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			NStr("ru = 'Ошибка при запуске сервиса Desktop (com.sun.star.frame.Desktop).'; en = 'Error occurred starting Desktop service (com.sun.star.frame.Desktop).'; pl = 'Podczas uruchamiania serwisu Desktop wystąpił błąd (com.sun.star.frame.Desktop).';de = 'Beim Starten des Desktop-Services (com.sun.star.frame.Desktop) ist ein Fehler aufgetreten.';ro = 'Eroare la lansarea serviciului Desktop (com.sun.star.frame.Desktop).';tr = 'Masaüstü hizmetini başlatırken bir hata oluştu (com.sun.star.frame.Desktop).'; es_ES = 'Ha ocurrido un error al lanzar el servicio de Escritorio (com.sun.star.frame.Desktop).'")
			+ Chars.LF + DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
#If WebClient Then
	FilesDetails = New Array;
	FilesDetails.Add(New TransferableFileDescription(TempFileName, PutToTempStorage(BinaryTemplateData)));
	TempDirectory = PrintManagementInternalClient.CreateTemporaryDirectory("OOWriter");
	If NOT GetFiles(FilesDetails, , TempDirectory, False) Then
		Return Undefined;
	EndIf;
	TempFileName = CommonClientServer.AddLastPathSeparator(TempDirectory) + TempFileName;
#Else
	TempFileName = GetTempFileName("ODT");
	BinaryTemplateData.Write(TempFileName);
#EndIf
	
	DocumentParameters = GetComSafeArray();
#If Not WebClient Then
	DocumentParameters.SetValue(0, PropertyValue(ServiceManager, "Hidden", True));
#EndIf
	
	// Opening parameters: disabling macros.
	StartMode = PropertyValue(ServiceManager,
		"MacroExecutionMode",
		0); // const short NEVER_EXECUTE = 0
	DocumentParameters.SetValue(0, StartMode);
	
	Document = Desktop.LoadComponentFromURL("file:///" + StrReplace(TempFileName, "\", "/"), "_blank", 0, DocumentParameters);
	
#If WebClient Then
	Document.getCurrentController().getFrame().getContainerWindow().setVisible(False);
#EndIf
	
	Handler.ServiceManager = ServiceManager;
	Handler.Desktop = Desktop;
	Handler.Document = Document;
	Handler.FileName = TempFileName;
	
#EndIf

	Return Handler;
	
EndFunction

// Closes a print form template and deletes references to the COM object.
//
Procedure CloseConnection(Handler, Val CloseApplication) Export
	
	If CloseApplication Then
		Handler.Document.Close(0);
	EndIf;
	
	Handler.Document = Undefined;
	Handler.Desktop = Undefined;
	Handler.ServiceManager = Undefined;
	
	If Handler.Property("FileName") Then
		DeleteFiles(Handler.FileName);
	EndIf;
	
	Handler = Undefined;
	
EndProcedure

// Sets a visibility property for OO Writer application.
// Handler - a reference to a print form.
//
Procedure ShowOOWriterDocument(Val Handler) Export
	
	ContainerWindow = Handler.Document.getCurrentController().getFrame().getContainerWindow();
	ContainerWindow.setVisible(True);
	ContainerWindow.setFocus();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Template operations

// Gets an area from the template.
// Parameters:
//   Handler - a reference to a template
//   AreaName - an area name in the template.
//   OffsetStart - offset from the area start, default offset: 1 - the area is taken without a 
//					newline character, after the operator parenthesis of the area opening.
//					
//   OffsetEnd - offset from the area end, default offset:- 11 - the area is taken without a newline 
//					character, before the operator parenthesis of the area closing.
//					
//
Function GetTemplateArea(Val Handler, Val AreaName) Export
	
	Result = New Structure("Document,Start,End");
	
	Result.Start = GetAreaStartPosition(Handler.Document, AreaName);
	Result.End   = GetAreaEndPosition(Handler.Document, AreaName);
	Result.Document = Handler.Document;
	
	Return Result;
	
EndFunction

// Gets a header area.
//
Function GetHeaderArea(Val TemplateRef) Export
	
	Return New Structure("Document, ServiceManager", TemplateRef.Document, TemplateRef.ServiceManager);
	
EndFunction

// Gets a footer area.
//
Function GetFooterArea(TemplateRef) Export
	
	Return New Structure("Document, ServiceManager", TemplateRef.Document, TemplateRef.ServiceManager);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Print form operations

// Inserts a line break to the next row.
// Parameters:
//   Handler - a reference to a Microsoft Word document. A line break is to be added to this document.
//
Procedure InsertBreakAtNewLine(Val Handler) Export
	
	oText = Handler.Document.getText();
	oCursor = oText.createTextCursor();
	oCursor.gotoEnd(False);
	oText.insertControlCharacter(oCursor, 0, False);
	
EndProcedure

// Adds a header to a print form.
//
Procedure AddHeader(Val PrintForm,
									Val Area) Export
	
	Template_oTxtCrsr = SetMainCursorToHeader(Area);
	While Template_oTxtCrsr.goRight(1, True) Do
	EndDo;
	TransferableObject = Area.Document.getCurrentController().Frame.controller.getTransferable();
	
	SetMainCursorToHeader(PrintForm);
	PrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
	
EndProcedure

// Adds a footer to a print form.
//
Procedure AddFooter(Val PrintForm,
									Val Area) Export
	
	Template_oTxtCrsr = SetMainCursorToFooter(Area);
	While Template_oTxtCrsr.goRight(1, True) Do
	EndDo;
	TransferableObject = Area.Document.getCurrentController().Frame.controller.getTransferable();
	
	SetMainCursorToFooter(PrintForm);
	PrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
	
EndProcedure

// Adds an area from a template to a print form, replacing the area parameters with the object data 
// values.
// The procedure is used upon output of a single area.
//
// Parameters:
//   PrintForm - a reference to a print form.
//   AreaHandler - a reference to an area in the template.
//   GoToNextRow - boolean, shows if it is required to add a line break after the area output.
//
// Returns:
//   AreaCoordinates
//
Procedure AttachArea(Val HandlerPrintForm,
							Val HandlerArea,
							Val GoToNextRow = True,
							Val JoinTableRow = False) Export
	
	Template_oTxtCrsr = HandlerArea.Document.getCurrentController().getViewCursor();
	Template_oTxtCrsr.gotoRange(HandlerArea.Start, False);
	
	If NOT JoinTableRow Then
		Template_oTxtCrsr.goRight(1, False);
	EndIf;
	
	Template_oTxtCrsr.gotoRange(HandlerArea.End, True);
	
	TransferableObject = HandlerArea.Document.getCurrentController().Frame.controller.getTransferable();
	HandlerPrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
	
	If JoinTableRow Then
		DeleteRow(HandlerPrintForm);
	EndIf;
	
	If GoToNextRow Then
		InsertBreakAtNewLine(HandlerPrintForm);
	EndIf;
	
EndProcedure

// Fills parameters in a print form tabular section.
//
Procedure FillParameters(PrintForm, Data) Export
	
	For Each KeyValue In Data Do
		If TypeOf(KeyValue) <> Type("Array") Then
			ReplacementString = KeyValue.Value;
			If IsTempStorageURL(ReplacementString) Then
#If WebClient Then
				TempFileName = TempFilesDir() + String(New UUID) + ".tmp";
#Else
				TempFileName = GetTempFileName("tmp");
#EndIf
				BinaryData = GetFromTempStorage(ReplacementString);
				BinaryData.Write(TempFileName);
				
				TextGraphicObject = PrintForm.Document.createInstance("com.sun.star.text.TextGraphicObject");
				FileURL = FileNameInURL(TempFileName);
				TextGraphicObject.GraphicURL = FileURL;
				
				Document = PrintForm.Document;
				SearchDescriptor = Document.CreateSearchDescriptor();
				SearchDescriptor.SearchString = "{v8 " + KeyValue.Key + "}";
				SearchDescriptor.SearchCaseSensitive = False;
				SearchDescriptor.SearchWords = False;
				Found = Document.FindFirst(SearchDescriptor);
				While Found <> Undefined Do
					Found.GetText().InsertTextContent(Found.getText(), TextGraphicObject, True);
					Found = Document.FindNext(Found.End, SearchDescriptor);
				EndDo;
			Else
				PF_oDoc = PrintForm.Document;
				PF_ReplaceDescriptor = PF_oDoc.createReplaceDescriptor();
				PF_ReplaceDescriptor.SearchString = "{v8 " + KeyValue.Key + "}";
				PF_ReplaceDescriptor.ReplaceString = String(KeyValue.Value);
				PF_oDoc.replaceAll(PF_ReplaceDescriptor);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a collection area to a print form.
//
Procedure JoinAndFillCollection(Val HandlerPrintForm,
										  Val HandlerArea,
										  Val Data,
										  Val IsTableRow = False,
										  Val GoToNextRow = True) Export
	
	Template_oTxtCrsr = HandlerArea.Document.getCurrentController().getViewCursor();
	Template_oTxtCrsr.gotoRange(HandlerArea.Start, False);
	
	If NOT IsTableRow Then
		Template_oTxtCrsr.goRight(1, False);
	EndIf;
	Template_oTxtCrsr.gotoRange(HandlerArea.End, True);
	
	TransferableObject = HandlerArea.Document.getCurrentController().Frame.controller.getTransferable();
	
	For Each RowWithData In Data Do
		HandlerPrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
		If IsTableRow Then
			DeleteRow(HandlerPrintForm);
		EndIf;
		FillParameters(HandlerPrintForm, RowWithData);
	EndDo;
	
	If GoToNextRow Then
		InsertBreakAtNewLine(HandlerPrintForm);
	EndIf;
	
EndProcedure

// Sets a mouse pointer to the end of the DocumentRef document.
//
Procedure SetMainCursorToDocumentBody(Val DocumentRef) Export
	
	oDoc = DocumentRef.Document;
	oViewCursor = oDoc.getCurrentController().getViewCursor();
	oTextCursor = oDoc.Text.createTextCursor();
	oViewCursor.gotoRange(oTextCursor, False);
	oViewCursor.gotoEnd(False);
	
EndProcedure

// Sets a mouse pointer to the header.
//
Function SetMainCursorToHeader(Val DocumentRef) Export
	
	xCursor = DocumentRef.Document.getCurrentController().getViewCursor();
	PageStyleName = xCursor.getPropertyValue("PageStyleName");
	oPStyle = DocumentRef.Document.getStyleFamilies().getByName("PageStyles").getByName(PageStyleName);
	oPStyle.HeaderIsOn = True;
	HeaderTextCursor = oPStyle.getPropertyValue("HeaderText").createTextCursor();
	xCursor.gotoRange(HeaderTextCursor, False);
	Return xCursor;
	
EndFunction

// Sets a mouse pointer to the footer.
//
Function SetMainCursorToFooter(Val DocumentRef) Export
	
	xCursor = DocumentRef.Document.getCurrentController().getViewCursor();
	PageStyleName = xCursor.getPropertyValue("PageStyleName");
	oPStyle = DocumentRef.Document.getStyleFamilies().getByName("PageStyles").getByName(PageStyleName);
	oPStyle.FooterIsOn = True;
	FooterTextCursor = oPStyle.getPropertyValue("FooterText").createTextCursor();
	xCursor.gotoRange(FooterTextCursor, False);
	Return xCursor;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions

// Gets a structure used to set UNO object parameters.
// 
//
Function PropertyValue(Val ServiceManager, Val Property, Val Value)
	
	PropertyValue = ServiceManager.Bridge_GetStruct("com.sun.star.beans.PropertyValue");
	PropertyValue.Name = Property;
	PropertyValue.Value = Value;
	
	Return PropertyValue;
	
EndFunction

Function GetAreaStartPosition(Val xDocument, Val AreaName)
	
	TextToSearch = "{v8 Area." + AreaName + "}";
	
	xSearchDescr = xDocument.createSearchDescriptor();
	xSearchDescr.SearchString = TextToSearch;
	xSearchDescr.SearchCaseSensitive = False;
	xSearchDescr.SearchWords = True;
	xFound = xDocument.findFirst(xSearchDescr);
	If xFound = Undefined Then
		Raise NStr("ru = 'Не найдено начало области макета:'; en = 'Cannot find where layout begins:'; pl = 'Nie znaleziono początku obszaru szablonu:';de = 'Start des Vorlagenbereichs wurde nicht gefunden:';ro = 'Începutul domeniului machetei nu a fost găsit:';tr = 'Şablon alanı başlangıcı bulunamadı:'; es_ES = 'Inicio del área del modelo no encontrado:'") + " " + AreaName;	
	EndIf;
	Return xFound.End;
	
EndFunction

Function GetAreaEndPosition(Val xDocument, Val AreaName)
	
	TextToSearch = "{/v8 Area." + AreaName + "}";
	
	xSearchDescr = xDocument.createSearchDescriptor();
	xSearchDescr.SearchString = TextToSearch;
	xSearchDescr.SearchCaseSensitive = False;
	xSearchDescr.SearchWords = True;
	xFound = xDocument.findFirst(xSearchDescr);
	If xFound = Undefined Then
		Raise NStr("ru = 'Не найден конец области макета:'; en = 'Cannot find where layout ends:'; pl = 'Nie znaleziono końca obszaru szablonu:';de = 'Ende des Vorlagenbereichs wurde nicht gefunden:';ro = 'Sfârșitul domeniului machetei nu a fost găsit:';tr = 'Şablon alanının sonu bulunamadı:'; es_ES = 'Fin del área del modelo no encontrado:'") + " " + AreaName;	
	EndIf;
	Return xFound.Start;
	
EndFunction

Procedure DeleteRow(HandlerPrintForm)
	
	oFrame = HandlerPrintForm.Document.getCurrentController().Frame;
	
	dispatcher = HandlerPrintForm.ServiceManager.CreateInstance ("com.sun.star.frame.DispatchHelper");
	
	oViewCursor = HandlerPrintForm.Document.getCurrentController().getViewCursor();
	
	dispatcher.executeDispatch(oFrame, ".uno:GoUp", "", 0, GetComSafeArray());
	
	While oViewCursor.TextTable <> Undefined Do
		dispatcher.executeDispatch(oFrame, ".uno:GoUp", "", 0, GetComSafeArray());
	EndDo;
	
	dispatcher.executeDispatch(oFrame, ".uno:Delete", "", 0, GetComSafeArray());
	
	While oViewCursor.TextTable <> Undefined Do
		dispatcher.executeDispatch(oFrame, ".uno:GoDown", "", 0, GetComSafeArray());
	EndDo;
	
EndProcedure

Function GetComSafeArray()
	
#If WebClient Then
	scr = New COMObject("MSScriptControl.ScriptControl");
	scr.language = "javascript";
	scr.eval("Array=new Array()");
	Return scr.eval("Array");
#ElsIf Not MobileClient Then
	Return New COMSafeArray("VT_DISPATCH", 1);
#EndIf
	
EndFunction

Function EventLogEvent()
	Return NStr("ru = 'Печать'; en = 'Print'; pl = 'Wydruki';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'");
EndFunction

Procedure FailedToGeneratePrintForm(ErrorInformation)
#If WebClient Or MobileClient Then
	ClarificationText = NStr("ru = 'Для формирования этой печатной формы необходимо воспользоваться тонким клиентом.'; en = 'This print from can be generated in thin client only.'; pl = 'Do tworzenia formularzy wydruku, należy skorzystać z cienkiego klienta.';de = 'Um diese Druckform zu erstellen, benötigen Sie einen Thin Client.';ro = 'Pentru generarea acestei forme de tipar trebuie să utilizați thin-clientul.';tr = 'Bu baskı formunu oluşturmak için ince istemci kullanmanız gerekir.'; es_ES = 'Para generar este formulario de impresión es necesario usar el cliente ligero.'");
#Else
	ClarificationText = NStr("ru = 'Для вывода печатных форм в формате OpenOffice.org Writer требуется, чтобы на компьютере был установлен пакет OpenOffice.org.'; en = 'To output print forms in OpenOffice Writer format, OpenOffice.org must be installed.'; pl = 'Dla wyprowadzenia formularzy wydruku w formacie OpenOffice.org Writer jest wymagane, aby na komputerze był zainstalowany pakiet OpenOffice.org.';de = 'Um Druckformulare im OpenOffice.org-Format auszugeben, muss das OpenOffice.org-Paket auf Ihrem Computer installiert sein.';ro = 'Pentru imprimarea formelor de tipar în formatul OpenOffice.org Writer trebuie să aveți instalat pe computer pachetul OpenOffice.org.';tr = 'OpenOffice.org biçimindeki baskı formlarını yazdırmak için, Writer OpenOffice.org paketinin bilgisayarınızda kurulu olmasını gerektirir.'; es_ES = 'Para mostrar los formularios de impresión en el formato OpenOffice.org Writer se requiere que en el ordenador esté instalado el paquete de OpenOffice.org.'");
#EndIf
	ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось сформировать печатную форму: %1. 
			|%2'; 
			|en = 'Cannot generate print form: %1.
			|%2'; 
			|pl = 'Nie udało się wygenerować formularza do wydruku: %1. 
			|%2';
			|de = 'Es war nicht möglich, ein Druckformular zu erstellen: %1. 
			|%2';
			|ro = 'Eșec la generarea formei de tipar: %1. 
			|%2';
			|tr = 'Yazdırma formu oluşturulamadı:%1.
			|%2'; 
			|es_ES = 'No se ha podido generar el formulario de impresión: %1.
			|%2'"),
		BriefErrorDescription(ErrorInformation), ClarificationText);
	Raise ExceptionText;
EndProcedure

Function FileNameInURL(Val FileName)
	FileName = StrReplace(FileName, " ", "%20");
	FileName = StrReplace(FileName, "\", "/"); 
	Return "file:/" + "/localhost/" + FileName; 
EndFunction

#EndRegion