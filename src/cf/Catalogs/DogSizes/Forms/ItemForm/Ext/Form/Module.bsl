&AtClient

Procedure ExecutePrintQRCode(Command)

   

   SpreadsheetDocument = PrintQRCode("More samples on 1C:Developer Network forum: http://1c-dn.com/forum/");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(NStr("en = 'QR code sample'"));
	EndIf;

   

EndProcedure



&AtServer

Function PrintQRCode(QRString)

   

   SpreadsheetDocument = New SpreadsheetDocument;

   

   Template = GetCommonTemplate("QRCodeSample");

   Area = Template.GetArea("Output");

   

   QRCodeData = QRCodeData(QRString, 0, 190);

   

   If Not TypeOf(QRCodeData) = Type("BinaryData") Then

      

      UserMessage = New UserMessage;

      UserMessage.Text = NStr("en = 'Unable to generate QR code'");

      UserMessage.Message();

      

      Return Undefined;

   EndIf;

   

   QRCodePicture = New Picture(QRCodeData);

   

   Area.Drawings.QRCode.Picture = QRCodePicture;

   

   SpreadsheetDocument.Put(Area);

   

   Return SpreadsheetDocument;

   

EndFunction



&AtServer

Function QRCodeData(QRString, CorrectionLevel, Size) 

   

   ErrorMessage = НСтр("en = 'Unable to attach the QR code generation add-in.'");

   

   Try

      If AttachAddIn("CommonTemplate.QRCodeAddIn", "QR") Then

         QRCodeGenerator = New("AddIn.QR.QRCodeExtension");

      Else

         UserMessage = New UserMessage;

         UserMessage.Text = ErrorMessage;

         UserMessage.Message();

      EndIf

   Except

      DetailErrorDescription = DetailErrorDescription(ErrorInfo());

      UserMessage = New UserMessage;

      UserMessage.Text = ErrorMessage + Chars.LF + DetailErrorDescription;

      UserMessage.Message();

   EndTry;

   

   Try

      PictureBinaryData = QRCodeGenerator.GenerateQRCode(QRString, CorrectionLevel, Size);

   Except

      UserMessage = New UserMessage;

      UserMessage.Text = DetailErrorDescription(ErrorInfo());

      UserMessage.Message();

   EndTry;

   

   Return PictureBinaryData;

   

EndFunction

