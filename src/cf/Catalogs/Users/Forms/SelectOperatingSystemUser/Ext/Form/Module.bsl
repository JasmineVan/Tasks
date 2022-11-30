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
	
#If ThickClientOrdinaryApplication OR ThickClientManagedApplication Then
	DomainsAndUsersTable = OSUsers();
#ElsIf ThinClient Then
	DomainsAndUsersTable = New FixedArray (OSUsers());
#EndIf
	
	FillDomainList();
	
EndProcedure

#EndRegion

#Region DomainTableFormTableItemsEventHandlers

&AtClient
Procedure DomainTableOnActivateRow(Item)
	
	CurrentDomainUsersList.Clear();
	
	If Item.CurrentData <> Undefined Then
		DomainName = Item.CurrentData.DomainName;
		
		For Each Record In DomainsAndUsersTable Do
			If Record.DomainName = DomainName Then
				
				For Each User In Record.Users Do
					DomainUser = CurrentDomainUsersList.Add();
					DomainUser.UserName = User;
				EndDo;
				Break;
				
			EndIf;
		EndDo;
		
		CurrentDomainUsersList.Sort("UserName");
	EndIf;
	
EndProcedure

#EndRegion

#Region UserTableFormTableItemsEventHandlers

&AtClient
Procedure DomainUserTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	ComposeResultAndCloseForm();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	If Items.DomainsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите домен.'; en = 'Select a domain.'; pl = 'Wybierz domenę.';de = 'Wählen Sie die Domäne aus.';ro = 'Selectați domenul.';tr = 'Alanı seçin.'; es_ES = 'Seleccionar el dominio.'"));
		Return;
	EndIf;
	
	If Items.DomainUsersTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выберите пользователя домена.'; en = 'Select a domain user.'; pl = 'Wybierz użytkownika domeny.';de = 'Wählen Sie den Domänenbenutzer aus.';ro = 'Selectați utilizatorul domenului.';tr = 'Alan kullanıcısını seçin.'; es_ES = 'Seleccionar el usuario del dominio.'"));
		Return;
	EndIf;
	
	ComposeResultAndCloseForm();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillDomainList()
	
	DomainsList.Clear();
	
	For Each Record In DomainsAndUsersTable Do
		Domain = DomainsList.Add();
		Domain.DomainName = Record.DomainName;
	EndDo;
	
	DomainsList.Sort("DomainName");
	
EndProcedure

&AtClient
Procedure ComposeResultAndCloseForm()
	
	DomainName = Items.DomainsTable.CurrentData.DomainName;
	Username = Items.DomainUsersTable.CurrentData.UserName;
	
	SelectionResult = "\\" + DomainName + "\" + Username;
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
