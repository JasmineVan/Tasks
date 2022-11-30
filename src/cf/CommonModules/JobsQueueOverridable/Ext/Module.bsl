///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates a list of templates for queued jobs.
//
// Parameters:
//  JobTemplates - Array - the parameter should include names of predefined shared scheduled jobs to 
//   be used as queue job templates.
//   
//
Procedure OnGetTemplateList(JobTemplates) Export
	
EndProcedure

// Fills mapping of method names and their aliases for calling from a job queue.
//
// Parameters:
//  NameAndAliasMap - Map -
//    * Key - a method alias, for example, ClearDataArea.
//    * Value - a method name to be called, for example, SaaS.ClearDataArea.
//        You can specify Undefined as a value, in this case, the name is assumed to be the same as 
//        an alias.
//
Procedure OnDefineHandlerAliases(NameAndAliasMap) Export
	
EndProcedure

// Sets a mapping between error handler methods and aliases of methods where errors occur.
// 
//
// Parameters:
//  ErrorHandlers - Map -
//    * Key - a method alias, for example, ClearDataArea.
//    * Value - Method name - error handler, called upon error.
//        The error handler is called whenever a job execution fails.
//         The error handler is always called in the data area of the failed job.
//        The error handler method can be called by the queue mechanisms.
//        Error handler parameters:
//          JobParameters - Structure - queue job parameters.
//          Parameters
//          AttemptNumber
//          RestartCountOnFailure
//          LastRunStartDate.
//
Procedure OnDefineErrorsHandlers(ErrorsHandlers) Export
	
EndProcedure

// Generates a scheduled job table with flags that show whether a job is used in SaaS mode.
//
// Parameters:
//  UsageTable - ValueTable - value table with the following columns:
//    * ScheduledJob - String - name of the predefined scheduled job,
//    * Usage - Boolean - True if the scheduled job must be executed in the SaaS mode, False if it 
//       must not.
//
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
EndProcedure

#EndRegion
