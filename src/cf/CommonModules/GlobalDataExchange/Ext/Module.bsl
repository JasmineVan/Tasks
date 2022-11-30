///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks whether infobase configuration update in the subordinate node is required.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequired() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientRunParameters().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

// Checks whether infobase configuration update in the subordinate node is required. The check is performed on application startup.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequiredOnStart() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientParametersOnStart().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

Procedure CheckUpdateRequired(DIBNodeConfigurationUpdateRequired)
	
	If DIBNodeConfigurationUpdateRequired Then
		Note = NStr("ru = 'Получено обновление программы из ""%1"".
			|Необходимо установить обновление программы, после чего синхронизация данных будет продолжена.'; 
			|en = 'An application update is received from ""%1."" 
			|Please install the update, then the data synchronization will continue.'; 
			|pl = 'Aktualizacja aplikacji otrzymana od ""%1"".
			|Konieczne jest zainstalowanie aktualizacji aplikacji, po której synchronizacja danych będzie kontynuowana.';
			|de = 'Die Anwendung wurde von ""%1"" aktualisiert.
			|Sie sollten das Update installieren, damit die Datensynchronisierung fortgesetzt wird.';
			|ro = 'Actualizarea aplicației este primită de la ""%1"".
			|Instalați actualizarea pentru a continua sincronizarea datelor.';
			|tr = 'Bu uygulamanın güncellemesi ""%1""dan alınmaktadir. 
			|Veri senkronizasyonuna devam etmek için güncellemeyi kurmanız gerekmektedir.'; 
			|es_ES = 'La actualización de la aplicación se ha recibido desde ""%1"".
			|Instalar la actualización para que la sincronización de datos se continúe.'");
		Note = StringFunctionsClientServer.SubstituteParametersToString(Note, StandardSubsystemsClient.ClientRunParameters().MasterNode);
		ShowUserNotification(NStr("ru = 'Установить обновление'; en = 'Install update'; pl = 'Instalacja aktualizacji';de = 'Update installieren';ro = 'Instalați actualizarea';tr = 'Güncellemeyi yükle'; es_ES = 'Instalar la actualización'"), "e1cib/app/DataProcessor.DataExchangeExecution",
			Note, PictureLib.Warning32);
		Notify("DataExchangeCompleted");
	EndIf;
	
	AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequired", 60 * 60, True); // once an hour
	
EndProcedure

#EndRegion
