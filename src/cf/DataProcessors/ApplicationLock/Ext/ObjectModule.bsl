///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Locks or unlocks the infobase, depending on the data processor attribute values.
// 
//
Procedure SetLock() Export
	
	ExecuteSetLock(DisableUserAuthorisation);
	
EndProcedure

// Disables the previously enabled session lock.
//
Procedure CancelLock() Export
	
	ExecuteSetLock(False);
	
EndProcedure

// Reads the infobase lock parameters and passes them to the data processor attributes.
// 
//
Procedure GetLockParameters() Export
	
	If Users.IsFullUser(, True) Then
		CurrentMode = GetSessionsLock();
		UnlockCode = CurrentMode.KeyCode;
	Else
		CurrentMode = IBConnections.GetDataAreaSessionLock();
	EndIf;
	
	DisableUserAuthorisation = CurrentMode.Use 
		AND (Not ValueIsFilled(CurrentMode.End) Or CurrentSessionDate() < CurrentMode.End);
	MessageForUsers = IBConnectionsClientServer.ExtractLockMessage(CurrentMode.Message);
	
	If DisableUserAuthorisation Then
		LockEffectiveFrom    = CurrentMode.Begin;
		LockEffectiveTo = CurrentMode.End;
	Else
		// If data lock is not set, most probably the form is opened by user in order to set the lock.
		// 
		// Therefore making lock date equal to the current date.
		LockEffectiveFrom     = BegOfMinute(CurrentSessionDate() + 5 * 60);
	EndIf;
	
EndProcedure

Procedure ExecuteSetLock(Value)
	
	If Users.IsFullUser(, True) Then
		Lock = New SessionsLock;
		Lock.KeyCode    = UnlockCode;
	Else
		Lock = IBConnections.NewConnectionLockParameters();
	EndIf;
	
	Lock.Begin           = LockEffectiveFrom;
	Lock.End            = LockEffectiveTo;
	Lock.Message        = IBConnections.GenerateLockMessage(MessageForUsers, 
		UnlockCode); 
	Lock.Use      = Value;
	
	If Users.IsFullUser(, True) Then
		SetSessionsLock(Lock);
	Else
		IBConnections.SetDataAreaSessionLock(Lock);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf