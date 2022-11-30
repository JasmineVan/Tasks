///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CurrentObject.DataType = Enums.APICacheDataTypes.InterfaceVersions Then
		
		Data = CurrentObject.Data.Get();
		Body = Common.ValueToXMLString(Data);
		
	ElsIf CurrentObject.DataType = Enums.APICacheDataTypes.WebServiceDetails Then
		
		TempFile = GetTempFileName("xml");
		
		BinaryData = CurrentObject.Data.Get();
		BinaryData.Write(TempFile);
		
		TextDocument = New TextDocument();
		TextDocument.Read(TempFile);
		
		Body = TextDocument.GetText();
		
		DeleteFiles(TempFile);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.DataType = Enums.APICacheDataTypes.InterfaceVersions Then
		
		Data = Common.ValueFromXMLString(Body);
		CurrentObject.Data = New ValueStorage(Data);
		
	ElsIf CurrentObject.DataType = Enums.APICacheDataTypes.WebServiceDetails Then
		
		TempFile = GetTempFileName("xml");
		
		TextDocument = New TextDocument();
		TextDocument.SetText(Body);
		TextDocument.Write(TempFile);
		
		BinaryData = New BinaryData(TempFile);
		CurrentObject.Data = New ValueStorage(BinaryData);
		
		DeleteFiles(TempFile);
		
	EndIf;
	
EndProcedure

#EndRegion