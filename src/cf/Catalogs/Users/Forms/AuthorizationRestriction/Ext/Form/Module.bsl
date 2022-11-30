///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.DueDate.ToolTip
		= Metadata.InformationRegisters.UsersInfo.Resources.ValidityPeriod.ToolTip;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If TypeOf(FormOwner) <> Type("ManagedForm") Then
		Return;
	EndIf;
	
	InactivityPeriod = FormOwner.InactivityPeriodBeforeDenyingAuthorization;
	DueDate      = FormOwner.ValidityPeriod;
	
	If FormOwner.UnlimitedValidityPeriod Then
		PeriodType = "NoExpiration";
		CurrentItem = Items.PeriodTypeNoExpiration;
		
	ElsIf ValueIsFilled(DueDate) Then
		PeriodType = "TillDate";
		CurrentItem = Items.PeriodTypeTillDate;
		
	ElsIf ValueIsFilled(InactivityPeriod) Then
		PeriodType = "InactivityPeriod";
		CurrentItem = Items.PeriodTypeTimeout;
	Else
		PeriodType = "NotSpecified";
		CurrentItem = Items.PeriodTypeNotSpecified;
	EndIf;
	
	UpdateAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodTypeOnChange(Item)
	
	UpdateAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If PeriodType = "TillDate" Then
		If Not ValueIsFilled(DueDate) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Дата не указана.'; en = 'The date is not specified.'; pl = 'Nie wskazano daty.';de = 'Datum nicht angegeben.';ro = 'Data nu este indicată.';tr = 'Tarih belirtilmedi.'; es_ES = 'Fecha no indicada.'"),, "DueDate");
			Return;
			
		ElsIf DueDate <= BegOfDay(CommonClient.SessionDate()) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Ограничение должно быть до завтра или более.'; en = 'The password expiration date must be tomorrow or later.'; pl = 'Data ważności hasła musi być jutro lub później.';de = 'Die Begrenzung sollte bis morgen oder später gelten.';ro = 'Restricția trebuie să fie până mâine sau mai mult.';tr = 'Kısıtlama yarına kadar veya daha fazla olmalıdır.'; es_ES = 'La restricción debe ser hasta mañana o más.'"),, "DueDate");
			Return;
		EndIf;
	EndIf;
	
	FormOwner.Modified = True;
	FormOwner.InactivityPeriodBeforeDenyingAuthorization = InactivityPeriod;
	FormOwner.ValidityPeriod = DueDate;
	FormOwner.UnlimitedValidityPeriod = (PeriodType = "NoExpiration");
	
	Items.FormOK.Enabled = False;
	AttachIdleHandler("CloseForm", 0.1, True);
	
EndProcedure

#EndRegion

#Region Private
	
&AtClient
Procedure UpdateAvailability()
	
	If PeriodType = "TillDate" Then
		Items.DueDate.AutoMarkIncomplete = True;
		Items.DueDate.Enabled = True;
	Else
		Items.DueDate.AutoMarkIncomplete = False;
		DueDate = Undefined;
		Items.DueDate.Enabled = False;
	EndIf;
	
	If PeriodType <> "InactivityPeriod" Then
		InactivityPeriod = 0;
	ElsIf InactivityPeriod = 0 Then
		InactivityPeriod = 60;
	EndIf;
	Items.InactivityPeriod.Enabled = PeriodType = "InactivityPeriod";
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close();
	
EndProcedure

#EndRegion
