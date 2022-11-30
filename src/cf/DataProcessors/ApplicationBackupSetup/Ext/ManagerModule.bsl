///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	StandardProcessing = False;
	
	SetPrivilegedMode(True);
	
	Versions = GetWebServiceVersions();
	
	If Versions.Find("1.0.2.1") <> Undefined Then
	
		SelectedForm = "SetWithIntervals";
			
		DataArea = SaaS.SessionSeparatorValue();
		
		AdditionalParameters = DataAreaBackupFormDataInterface.
			GetSettingsFormParameters(DataArea);
		For each KeyAndValue In AdditionalParameters Do
			Parameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
	ElsIf DataAreasBackupCached.ServiceManagerSupportsBackup() Then
		
		SelectedForm = "SetWithoutIntervals";
		
	Else
		
		Raise(NStr("ru = 'Менеджер сервиса не поддерживает резервное копирование приложений'; en = 'The service manager does not support application backup'; pl = 'Menedżer usług nie obsługuje tworzenia kopii zapasowych aplikacji';de = 'Service Manager unterstützt keine Anwendungssicherung';ro = 'Managerul serviciului nu susține copierea de rezervă a aplicațiilor';tr = 'Servis yöneticisi uygulama yedeğini desteklemiyor'; es_ES = 'Gestor de servicio no admite la copia de respaldo de la aplicación'"));
		
	EndIf;
	
EndProcedure

Function GetWebServiceVersions()
	
	Return Common.GetInterfaceVersions(
		SaaS.InternalServiceManagerURL(),
		SaaS.AuxiliaryServiceManagerUsername(),
		SaaS.AuxiliaryServiceManagerUserPassword(),
		"ZoneBackupControl");

EndFunction

#EndRegion
	
#EndIf