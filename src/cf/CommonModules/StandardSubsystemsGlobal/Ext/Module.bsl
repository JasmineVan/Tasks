///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Called every 20 minutes, for example, for dynamic control of updates and user account expiration.
// 
//
Procedure StandardPeriodicCheckIdleHandler() Export
	
	StandardSubsystemsClient.OnExecuteStandardDynamicChecks();
	
EndProcedure

// Continues exiting in the mode of interactive interaction with the user after setting Cancel = 
// True.
//
Procedure BeforeExitInteractiveHandlerIdleHandler() Export
	
	StandardSubsystemsClient.StartInteractiveHandlerBeforeExit();
	
EndProcedure

// Continues starting the application in interaction with a user.
Procedure OnStartIdleHandler() Export
	
	StandardSubsystemsClient.OnStart(, False);
	
EndProcedure

// Called when the application is started, opens the information window.
Procedure ShowInformationAfterStart() Export
	ModuleNotificationAtStartupClient = CommonClient.CommonModule("InformationOnStartClient");
	ModuleNotificationAtStartupClient.Show();
EndProcedure

// Called when the application is started, opens the security warning window.
Procedure ShowSecurityWarningAfterStart() Export
	UsersInternalClient.ShowSecurityWarning();
EndProcedure

// Shows users a message about insufficient RAM.
Procedure ShowRAMRecommendation() Export
	StandardSubsystemsClient.NotifyLowMemory();
EndProcedure

// Displays a popup warning message about additional actions that have to be performed before exit 
// the application.
//
Procedure ShowExitWarning() Export
	Warnings = StandardSubsystemsClient.ClientParameter("ExitWarnings");
	Note = NStr("ru = 'и выполнить дополнительные действия'; en = 'and perform additional actions.'; pl = 'i wykonać dodatkowe działania';de = 'und mache zusätzliche Aktionen';ro = 'și a executa acțiunile suplimentare';tr = 've ek eylemleri yerine getir'; es_ES = 'y hacer acciones adicionales'");
	If Warnings.Count() = 1 AND Not IsBlankString(Warnings[0].HyperlinkText) Then
		Note = Warnings[0].HyperlinkText;
	EndIf;
	ShowUserNotification(NStr("ru = 'Нажмите, чтобы завершить работу'; en = 'Click here to exit'; pl = 'Kliknij, aby wyjść';de = 'Klicken Sie, um zu beenden';ro = 'Tastați pentru a finaliza lucrul';tr = 'Çıkmak için tıklayın'; es_ES = 'Hacer clic para salir'"), 
		"e1cib/command/CommonCommand.ExitWarnings",
		Note, PictureLib.ExitApplication, UserNotificationStatus.Important);
EndProcedure

#EndRegion
