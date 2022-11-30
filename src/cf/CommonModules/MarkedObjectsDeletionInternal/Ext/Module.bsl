///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.InitialFilling = True;
	Handler.Procedure = "MarkedObjectsDeletionInternal.EnableDeleteMarkedObjects";
	Handler.ExecutionMode = "Seamless";
	
EndProcedure

// 2.4.1.1 update handler.
//
Procedure EnableDeleteMarkedObjects() Export
	
	Constants.UseMarkedObjectsDeletion.Set(True);
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("MarkedObjectsDeletion");
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.MarkedObjectsDeletion;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseMarkedObjectsDeletion;
	
EndProcedure

#EndRegion

#Region Private

// Scheduled job entry point.
//
Procedure MarkedObjectsDeletionScheduled() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.MarkedObjectsDeletion);
	
	DataProcessors.MarkedObjectsDeletion.DeleteMarkedObjectsFromScheduledJob();
	
EndProcedure

#EndRegion