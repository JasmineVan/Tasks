&AtClient
Procedure ReadFileLists(Command) 
	//Open folder dialog
	Description = New NotifyDescription("FinishSelectFile", ThisObject);
	BeginPutFile(Description, , , True, ThisObject.UUID);
EndProcedure

&AtClient
Procedure FinishSelectFile(Result, Address, FileDicrectory, AdditionalParameters) Export
	If Result Then
		path = FileDicrectory;
		ImportDataAtServer(path);
	EndIf;  
	
EndProcedure

//Just use it, nothing to change
Function SetupConnection(FileName = "")
	Try
		Excel = New COMObject("Excel.Application");
	Except
		Message("Unable to create Com object: " + ErrorDescription(), MessageStatus.Important);
		Return Null;
	EndTry;
	
	Try
		Book = Excel.Workbooks.Add(FileName);
	Except
		Message("Unable to open Excel file: " + ErrorDescription());
		
		Excel.Quit();
		
		Excel = Null;
		
		Return Null;
	EndTry;
	
	Try
		Sheet = Book.Sheets(1);
	Except
		Message("Unable to get Sheet1 in the Excel file: " + ErrorDescription());
		
		Book.Close();
		Excel.Quit();
		
		Book = Null;
		Excel = Null;		
		
		Return Null;
	EndTry;
	
	StructureToReturn = New Structure;
	StructureToReturn.Insert("Excel", Excel);
	StructureToReturn.Insert("Sheet", Sheet);
	
	Return StructureToReturn;
EndFunction

&AtServer
Procedure ImportDataAtServer(path)
	Object.DataPath = path;
	ConnectionResult = SetupConnection(Object.DataPath);
	If ConnectionResult = Null Then
		Return;
	EndIf;
	Excel = ConnectionResult.Excel;
	Sheet = ConnectionResult.Sheet;
	RowsCount = Sheet.UsedRange.Rows.Count;
	
	Array = Excel.Range(Excel.Cells(2, 1), Excel.Cells(RowsCount, 11)).Value;
	
	Excel.Quit();
	
	Sheet = Null;
	Excel = Null;
	
	//Folder = Catalogs.DogOwners.FindByDescription(Object.ImportToFolder);
	
	//Import data from above array to catalog
	For Index = 1 to RowsCount - 1 Do
		If Not IsBlankString(Array.GetValue(1, Index)) Then
		EndIf;
	EndDo;
EndProcedure

