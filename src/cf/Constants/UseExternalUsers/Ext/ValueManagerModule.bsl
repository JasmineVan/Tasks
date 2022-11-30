///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ValueChanged;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ValueChanged = Value <> Constants.UseExternalUsers.Get();
	
	If ValueChanged
	   AND Value
	   AND Not UsersInternal.ExternalUsersEmbedded() Then
		Raise NStr("ru = 'Использование внешних пользователей не предусмотрено в программе.'; en = 'The application does not support external users.'; pl = 'Korzystanie z zewnętrznych użytkowników nie jest przewidziane w programie.';de = 'Die Verwendung von externen Benutzern ist im Programm nicht vorgesehen.';ro = 'În aplicație nu este prevăzută folosirea utilizatorilor externi.';tr = 'Uygulamada harici kullanıcıların kullanımı öngörülmemiştir.'; es_ES = 'El uso de los usuarios externos no está previsto en el programa.'");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueChanged Then
		UsersInternal.UpdateExternalUsersRoles();
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = Common.CommonModule("AccessManagement");
			ModuleAccessManagement.UpdateUserRoles(Type("CatalogRef.ExternalUsers"));
			
			ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
			If ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
				PlanningParameters = ModuleAccessManagementInternal.AccessUpdatePlanningParameters();
				PlanningParameters.ForUsers = False;
				PlanningParameters.ForExternalUsers = True;
				PlanningParameters.IsUpdateContinuation = True;
				PlanningParameters.Details = "UseExternalUsersOnWrite";
				ModuleAccessManagementInternal.ScheduleAccessUpdate(, PlanningParameters);
			EndIf;
		EndIf;
		If Value Then
			ClearShowInListAttributeForAllIBUsers();
		Else
			ClearCanSignInAttributeForAllExternalUsers();
		EndIf;
		
		SetPropertySetUsageFlag();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Clears the FlagShowInList attribute for all infobase users.
Procedure ClearShowInListAttributeForAllIBUsers() Export
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each InfobaseUser In IBUsers Do
		If InfobaseUser.ShowInList Then
			InfobaseUser.ShowInList = False;
			InfobaseUser.Write();
		EndIf;
	EndDo;
	
EndProcedure

// Clears the FlagShowInList attribute for all infobase users.
Procedure ClearCanSignInAttributeForAllExternalUsers()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExternalUsers.IBUserID AS ID
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers";
	IDs = Query.Execute().Unload();
	IDs.Indexes.Add("ID");
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each InfobaseUser In IBUsers Do
		
		If IDs.Find(InfobaseUser.UUID, "ID") <> Undefined
		   AND Users.CanSignIn(InfobaseUser) Then
			
			InfobaseUser.StandardAuthentication = False;
			InfobaseUser.OSAuthentication          = False;
			InfobaseUser.OpenIDAuthentication      = False;
			InfobaseUser.Write();
		EndIf;
	EndDo;
	
EndProcedure

Procedure SetPropertySetUsageFlag()
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Return;
	EndIf;
	ModulePropertyManager = Common.CommonModule("PropertyManager");
	
	SetParameters = ModulePropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Value;
	ModulePropertyManager.SetPropertySetParameters("Catalog_ExternalUsers", SetParameters);
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf