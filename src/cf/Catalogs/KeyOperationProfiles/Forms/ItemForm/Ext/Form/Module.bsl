///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandHandlers

&AtClient
Procedure LoadKeyOperationsProfile(Command)
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл профиля ключевых операций'; en = 'Select file of key operation profile'; pl = 'Select file of key operation profile';de = 'Select file of key operation profile';ro = 'Select file of key operation profile';tr = 'Select file of key operation profile'; es_ES = 'Select file of key operation profile'");
	ImportParameters.Dialog.Filter = "Files profile key operations (*.xml)|*.xml";
	
	NotifyDescription = New NotifyDescription("SelectFileDialogCompletion", ThisObject, Undefined);
	FileSystemClient.ImportFile(NotifyDescription, ImportParameters);
	
EndProcedure

&AtClient
Procedure SaveKeyOperationsProfile(Command)
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Сохранить профиль ключевых операций в файл'; en = 'Save key operation profile to file'; pl = 'Save key operation profile to file';de = 'Save key operation profile to file';ro = 'Save key operation profile to file';tr = 'Save key operation profile to file'; es_ES = 'Save key operation profile to file'");
	SavingParameters.Dialog.Filter = "Files profile key operations (*.xml)|*.xml";
	
	FileSystemClient.SaveFile(Undefined, SaveKeyOperationsProfileToServer(), "", SavingParameters);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	FillAtServer();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectFileDialogCompletion(SelectedFile, AdditionalParameters) Export
	
	If SelectedFile = Undefined Then
		Return;
	EndIf;
	
	LoadKeyOperationsProfileAtServer(SelectedFile.Location);
	Modified = True;
	
EndProcedure

&AtServer
Function SaveKeyOperationsProfileToServer()
    
    TempFileName = GetTempFileName("xml");
    
    XMLWriter = New XMLWriter;
    XMLWriter.OpenFile(TempFileName);
    
    XMLWriter.WriteStartElement("Items");
    XMLWriter.WriteAttribute("Description", Object.Description);
    XMLWriter.WriteAttribute("Columns", "Name,ResponseTimeThreshold,Importance");
    
    For Each curRow In Object.ProfileKeyOperations Do
        XMLWriter.WriteStartElement("Item");
        XMLWriter.WriteAttribute("Name", curRow.KeyOperation.Name);
        XMLWriter.WriteAttribute("ResponseTimeThreshold", Format(curRow.ResponseTimeThreshold, "NG=0"));
        XMLWriter.WriteAttribute("Importance", Format(curRow.Priority, "NG=0"));
        XMLWriter.WriteEndElement();
    EndDo;
        
    XMLWriter.WriteEndElement();
    
    XMLWriter.Close();
    
    BinaryData = New BinaryData(TempFileName);
    StorageAddress = PutToTempStorage(BinaryData, ThisObject.UUID);
    
    DeleteFiles(TempFileName);
    
    Return StorageAddress;
    
EndFunction

&AtServer
Procedure LoadKeyOperationsProfileAtServer(StorageAddress)
    
    BinaryData = GetFromTempStorage(StorageAddress);
        
    TempFileName = GetTempFileName("xml");
    BinaryData.Write(TempFileName);
    
    XMLReader = New XMLReader;
    XMLReader.OpenFile(TempFileName);
    KeyOperations = XDTOFactory.ReadXML(XMLReader);
    
    Columns = StrSplit(KeyOperations["Columns"], ",",False);
    If KeyOperations.Properties().Get("Item") <> Undefined Then
	    If TypeOf(KeyOperations["Item"]) = Type("XDTODataObject") Then
	        LoadXDTODataObject(KeyOperations["Item"], Columns);
	    Else
	        For Each CurItem In KeyOperations["Item"] Do
	            LoadXDTODataObject(CurItem, Columns);
	        EndDo;
		EndIf;
	EndIf;
            
    XMLReader.Close();
    DeleteFiles(TempFileName);
    
EndProcedure

&AtServer
Procedure LoadXDTODataObject(XDTODataObject, Columns)
    
    CurItem = XDTODataObject;
	
	KeyOperation = Catalogs.KeyOperations.FindByAttribute("Name", CurItem.Name);
	If KeyOperation.IsEmpty() Then
		KeyOperation = PerformanceMonitor.CreateKeyOperation(CurItem.Name);
	EndIf;
    FilterParameters = New Structure("KeyOperation", KeyOperation);
    FoundRows = Object.ProfileKeyOperations.FindRows(FilterParameters);
    
    If FoundRows.Count() = 0 Then
        
        NewString = Object.ProfileKeyOperations.Add();
		NewString.KeyOperation = KeyOperation;
        
		For Each CurColumn In Columns Do
			ColumnName = ?(CurColumn = "Importance", "Priority", CurColumn);
            If NewString.Property(ColumnName) AND CurItem.Properties().Get(CurColumn) <> Undefined Then
                NewString[ColumnName] = CurItem[CurColumn];
            EndIf;
        EndDo;
        
        If NOT ValueIsFilled(NewString.Priority) Then
            NewString.Priority = 5;
        EndIf;
    Else
        For Each NewString In FoundRows Do
			For Each CurColumn In Columns Do
				ColumnName = ?(CurColumn = "Importance", "Priority", CurColumn);
                If NewString.Property(ColumnName) AND CurItem.Properties().Get(CurColumn) <> Undefined Then
                    NewString[ColumnName] = CurItem[CurColumn];
                EndIf;
            EndDo;
        EndDo;
    EndIf;
    
EndProcedure

&AtServer
Procedure FillAtServer()
	Query = New Query("SELECT
	                      |	KeyOperations.Ref AS KeyOperation,
	                      |	KeyOperations.ResponseTimeThreshold AS ResponseTimeThreshold,
	                      |	CASE
	                      |		WHEN KeyOperations.Priority = 0
	                      |			THEN 5
	                      |		ELSE KeyOperations.Priority
	                      |	END AS Priority
	                      |FROM
	                      |	Catalog.KeyOperations AS KeyOperations
	                      |WHERE
	                      |	NOT KeyOperations.DeletionMark
	                      |
	                      |ORDER BY
	                      |	KeyOperations.Description");
	Object.ProfileKeyOperations.Load(Query.Execute().Unload());
EndProcedure

#EndRegion
