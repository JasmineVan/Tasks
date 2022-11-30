&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not Parameters.Key.IsEmpty() Then	
		CurrentObject = Parameters.Key.GetObject();
		PictureAddress = PutToTempStorage(CurrentObject.Picture.Get());
	EndIf;
	//Huong Fill attribute Age
	If not object.Ref.isempty() AND valueisfilled(Object.DateOfBirth) then
		DoB = new ValueTable;
		DoB.Columns.Add("DateOfBirth",new TypeDescription("date"));
		NewDoB = DoB.Add();
		NewDoB.DateOfBirth = Object.DateOfBirth;
		
		FillWeight(DoB);
	Else 
		Object.Age=0;
	Endif;
	//End Huong
	
	///Yenn Truyen owner into Tabular
	
	If Object.Owner.IsEmpty() Then
	Else
		Check=0;
		Owner=Object.Owner;
		If  Object.OwnerSecondary.Count()=0 Then
			NewLine= Object.OwnerSecondary.Add();
			NewLine.Owner=Owner;
			NewLine.Phone=Owner.Code;
			NewLine.Main=True;
		Else
			For Each Line In Object.OwnerSecondary Do
				If Line.Owner=Owner Then
					Line.Phone =Owner.Code;
					Line.Main=True;
					Check=1;
				EndIf;    
			EndDo;
			If Check=0 Then
				NewLine= Object.OwnerSecondary.Add();
				NewLine.Owner=Owner;
				NewLine.Phone=Owner.Code;
				NewLine.Main=True;
			EndIf; 	
		EndIf;		
		//CurrentObject.Write();
	EndIf;
	QRPicture = PrintQRCode(DogData2());

	
		
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	If Not IsBlankString(PictureAddress) Then
		Picture = GetFromTempStorage(PictureAddress);
		PictureAddress = PictureAddress;
		IF Picture <> Undefined Then       
			CurrentObject.Picture = New ValueStorage(Picture);
			CurrentObject.Write();    
		EndIf;
	EndIf;
EndProcedure

 ///Yen Check Main & Owner before save
&AtServer
 Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	 Check=False;
	 If CurrentObject.OwnerSecondary.Count()=0 Then
		  Message("Please add Main owner.",MessageStatus.VeryImportant);
	 Else
		 For Each Line In CurrentObject.OwnerSecondary Do
			 If Line.Main Then
				 Check= True;
				 Break;
			 EndIf; 
		 EndDo;
	 EndIf; 
	 If Check = False Then
		 Message("Please choose Main owner of this dog.",MessageStatus.VeryImportant);
		 Cancel=True;  
	 EndIf; 
EndProcedure

&AtServer
Procedure FillWeight(Val DoB)
	
	Var Query, QueryResult, SelectionDetailRecords;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DoB.DateOfBirth AS DateOfBirth
	|INTO DoBvalue
	|FROM
	|	&DoB AS DoB
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEDIFF(DoBvalue.DateOfBirth, &currentdate, MONTH) / 12 AS Age
	|FROM
	|	DoBvalue AS DoBvalue";
	
	Query.SetParameter("currentdate", currentdate());
	Query.SetParameter("DoB", DoB);
	
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Object.Age = SelectionDetailRecords.age;
	EndDo;
	DoB.Clear();

EndProcedure

&AtClient
Procedure ChangePicture(Command)
	BeginPutFile(New NotifyDescription("ChangePictureAfterPutFile", ThisForm), , , True, UUID);
EndProcedure
 
 &AtClient
 Procedure ChangePictureAfterPutFile(Result, Address, SelectedFileName, AdditionalParameters) Export
	 If Result Then
		 PictureAddress = Address;
	 EndIf;
 EndProcedure

 //Yen Owner in tabular onChange
&AtClient
Procedure OwnerListOnChange(Item)
	If typeof(items.OwnerList.CurrentData.FullName) = type("Undefined") then 
		items.OwnerList.CurrentData.FullName = "";
		items.OwnerList.CurrentData.NewRow = True;
			Endif;
 EndProcedure

 //Yen Main in tabular onChange
&AtClient
Procedure OwnerSecondaryMainOnChange(Item)
	ChangeMainOwner();
EndProcedure

&AtClient
Procedure ChangeMainOwner()
	Check = Items.OwnerSecondary.CurrentData.Main;
	ListOwner=Object.OwnerSecondary;
	For Each Line In ListOwner  Do
		Line.Main = False
	EndDo;
	 Items.OwnerSecondary.CurrentData.Main= Check;
	If  Check = True Then
		Owner= Items.OwnerSecondary.CurrentData.Owner;
		Object.Owner = Owner;
	Else
		Object.Owner ="";
	EndIf;

EndProcedure


///Yen Add new owner into Tabular
 &AtClient
 Procedure OwnerSecondaryBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	 Mode = QuestionDialogMode.YesNo;
	 Notification = New NotifyDescription("AfterQueryClose", ThisObject, Parameters);
	 items.ownerSecondary.ChildItems.OwnerSecondaryOwner.ReadOnly= True;
	 ShowQueryBox(Notification, "Do you want create new owner ?", Mode, 0);
 EndProcedure
 
 &AtClient
 Procedure AfterQueryClose(Result, Parameters) Export
	 If Result = DialogReturnCode.No Then
		 items.ownerSecondary.ChildItems.OwnerSecondaryOwner.ReadOnly = False;
		 Return;
	 Else
		 items.ownerSecondary.ChildItems.OwnerSecondaryOwner.ReadOnly = False;
		 NotifyOnCloseOwner = New NotifyDescription("AfterCloseFormOwner",ThisObject);
		 FromDog = New Structure;
		 FromDog.Insert("FromDogOwnerList", True);
		 OpenForm("Catalog.DogOwners.Form.ItemForm", FromDog,,,,,NotifyOnCloseOwner);
	 EndIf;
 EndProcedure
 
 &AtClient
 Procedure AfterCloseFormOwner(Result,Parameters)Export
	 If Result=Undefined Then
		 Index= object.OwnerSecondary.Count()-1;
		 Object.OwnerSecondary.Delete(Index);	
	 Else	 
		 Owner = Result.Key;
		 Phone = GetPhoneNumber(Owner);
		 items.OwnerSecondary.CurrentData.Owner =Owner;
		 items.OwnerSecondary.CurrentData.Phone =Phone;
		 If Object.OwnerSecondary.Count()=1 Then
			 items.OwnerSecondary.CurrentData.Main =True;
			 Object.Owner =Owner; 
		 EndIf;	 
	 EndIf; 
	 
 EndProcedure
 
 //Yen Get Phone Number tabular
&AtClient
Procedure OwnerSecondaryOwnerOnChange(Item)
	ObjOwner= Item.Parent.CurrentData.Owner;
	Phone=GetPhoneNumber(ObjOwner);
	Item.Parent.CurrentData.Phone =Phone;
	If Object.OwnerSecondary.Count()=1 Then
	Item.Parent.CurrentData.Main = True;
	Object.Owner =Item.Parent.CurrentData.Owner; 
	EndIf;
EndProcedure

&AtServer
Function GetPhoneNumber(ObjOwner)
	//Thuong TV modified
	//Return ObjOwner.Phone;	
	Return ObjOwner.Code;	
EndFunction	

/// Yen Check Value OwnerTabular
&AtClient
Procedure OwnerSecondaryOwnerChoiceProcessing(Item, SelectedValue, StandardProcessing)
	For Each Line In Object.OwnerSecondary Do
		If SelectedValue=Line.Owner Then
			StandardProcessing=False;
			Message("Owner had been existed ",MessageStatus.Information); 
		EndIf; 
	EndDo;
EndProcedure

&AtServer
Procedure DateOfBirthOnChangeAtServer()
	Dob = new ValueTable;
	DoB.Columns.Add("DateOfBirth",new TypeDescription("date"));
	NewDoB = DoB.Add();
	NewDoB.DateOfBirth = Object.DateOfBirth;
	FillWeight(DoB);
EndProcedure

&AtClient
Procedure DateOfBirthOnChange(Item)
	DateOfBirthOnChangeAtServer();
EndProcedure

&AtClient
Procedure ExecutePrintQRCode(Command)
	
	SpreadsheetDocument = PrintQRCode(DogData());
	If SpreadsheetDocument <> Undefined Then
		//SpreadsheetDocument.Show(NStr("en = 'QR code sample'"));
		QRPicture = PrintQRCode(DogData());
		//Thisform.ChildItems.Group2.ChildItems.Picture.ChildItems.QRPicture.Visible =True;

	EndIf;
	
	
EndProcedure

Function DogData()
	DayCare = DayCareChecking(Object);
	Tracking = DogTrackingLastDay(Object);
	
	DogInformation = "Code: " + String(object.Code)+ chars.LF
	+ "Description: " + string(Object.Description) + chars.LF
	+ "Breed: " + string(Object.DogBreed) + chars.LF
	+ "Age: " + string(Object.Age) + chars.LF
	+ "Weight: " + string(Object.Weight) + chars.LF
	+ "Gender: "+ string(Object.Gender)+ chars.LF
	+ "Owner: " + string(Object.Owner) + chars.LF
	+ "Phone number: " +String(Object.Owner.Code) + chars.LF
	+ "Additional information: " + string(Object.AdditionalInformation) + chars.LF
	+ "Day Care (Last day): " +DayCare + Chars.LF
	+ "Tracking(Last day): " +Tracking;
		Return DogInformation 
EndFunction
	
Function DogData2()
	DogInformation = String(object.Code);
	Return DogInformation 
EndFunction	

&AtServer
Function PrintQRCode(QRString)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Template = GetCommonTemplate("QRCodeSample");
	Area = Template.GetArea("Output");
	
	QRCodeData = QRCodeData(QRString,0, 190);
	
	If Not TypeOf(QRCodeData) = Type("BinaryData") Then
		
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en = 'Unable to generate QR code'");
		UserMessage.Message();
		
		Return Undefined;
	EndIf;
	
	QRCodePicture = New Picture(QRCodeData);
	
	Area.Drawings.QRCode.Picture = QRCodePicture;
	//SpreadsheetDocument.Put(Area);
	
	//Thuong TV - Test Picture in QR Code
	If Not Parameters.Key.IsEmpty() Then	
		CurrentObject = Parameters.Key.GetObject();
		PictureBinaryData = CurrentObject.Picture.Get();
	EndIf;
	If Not IsBlankString(PictureBinaryData) Then
		DogPicture = New Picture(PictureBinaryData);
	EndIf;
	//Area.Drawings.DogPicture.Picture = DogPicture;
	SpreadsheetDocument.Put(Area);
	//End ThuongTV
	
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

//Yen
&AtServer
Function DayCareChecking(Dog)
	  	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	DayCareSliceLast.CheckIn AS CheckIn,
		|	DayCareSliceLast.CheckOut AS CheckOut,
		|	DayCareSliceLast.Dog AS Dog
		|FROM
		|	InformationRegister.DayCare.SliceLast AS DayCareSliceLast
		|WHERE
		|	DayCareSliceLast.Dog = &Dog";
	
	Query.SetParameter("Dog", Dog.Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
	Checking="Check in: "+ String(Selection.CheckIn) +
	" Check out: " +String(Selection.CheckOut);
	EndDo;
	
	Return Checking;
EndFunction

&AtServer
Function DogTrackingLastDay(Dog)
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	TrackingHistorySliceLast.Dog AS Dog,
		|	TrackingHistorySliceLast.CheckIn AS CheckIn,
		|	TrackingHistorySliceLast.CheckOut AS CheckOut
		|FROM
		|	InformationRegister.TrackingHistory.SliceLast AS TrackingHistorySliceLast
		|WHERE
		|	TrackingHistorySliceLast.Dog = &Dog
		|
		|ORDER BY
		|	CheckIn";
	
	Query.SetParameter("Dog", Dog.Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		Tracking="Check In: "+ String(Selection.CheckIn) +" Check Out: "
		+String(Selection.CheckOut);
	EndDo;
	 Return Tracking;

EndFunction



 