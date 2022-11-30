///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If Value Then
		
		DataSeparationEnabled = Common.DataSeparationEnabled();
		Constants.UseDataSynchronizationInLocalMode.Set(Not DataSeparationEnabled);
		Constants.UseDataSynchronizationSaaS.Set(DataSeparationEnabled);
		
	Else
		
		Constants.UseDataSynchronizationInLocalMode.Set(False);
		Constants.UseDataSynchronizationSaaS.Set(False);
		
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Value
	   AND Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnDisableDataSynchronization(Cancel);
	EndIf;
	Job = ScheduledJobsServer.GetScheduledJob(
			Metadata.ScheduledJobs.ObsoleteSynchronizationDataDeletion);
	If Job.Use <> Value Then
		Job.Use = Value;
		Job.Write();
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf