///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If Not StandardSubsystemsClient.ApplicationStartupLogicDisabled() Then
		Return;
	EndIf;
	
	Items.TestMode.Visible = True;
	
	TestModeTitle = "{" + NStr("ru = 'Тестирование'; en = 'Testing'; pl = 'Testowanie';de = 'Testen';ro = 'Testare';tr = 'Test'; es_ES = 'Prueba'") + "} ";
	CurrentTitle = ClientApplication.GetCaption();
	
	If StrStartsWith(CurrentTitle, TestModeTitle) Then
		Return;
	EndIf;
	
	ClientApplication.SetCaption(TestModeTitle + CurrentTitle);
	
	RegisterApplicationStartupLogicDisabling();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RegisterApplicationStartupLogicDisabling()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataOwner = Catalogs.MetadataObjectIDs.GetRef(
		New UUID("627a6fb8-872a-11e3-bb87-005056c00008")); // Constants
	
	DisablingDates = Common.ReadDataFromSecureStorage(DataOwner);
	If TypeOf(DisablingDates) <> Type("Array") Then
		DisablingDates = New Array;
	EndIf;
	
	DisablingDates.Add(CurrentSessionDate());
	Common.WriteDataToSecureStorage(DataOwner, DisablingDates);
	
EndProcedure

#EndRegion
