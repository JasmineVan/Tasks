///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sets the automatic marked objects deletion mode
//   
Function SetDeleteOnScheduleMode(DeleteMarkedObjects) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise NStr("ru = 'Недостаточно прав для совершения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Niewystarczające uprawnienia do wykonania operacji.';de = 'Nicht genügend Rechte zum Ausführen des Vorgangs.';ro = 'Drepturi insuficiente pentru executarea operației.';tr = 'İşlemi gerçekleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para realizar la operación.'");
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.MarkedObjectsDeletion);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each Job In Jobs Do 
		
		Parameters = New Structure;
		Parameters.Insert("Use", DeleteMarkedObjects);
		ScheduledJobsServer.ChangeJob(Job, Parameters);
		
		Return True;
	EndDo;
	
	Return False;
	
EndFunction

// (See MarkedObjectsDeletion.DeleteOnScheduleCheckBoxValue)
//
Function DeleteOnScheduleCheckBoxValue() Export
	
	Return MarkedObjectsDeletion.DeleteOnScheduleCheckBoxValue();
	
EndFunction

#EndRegion