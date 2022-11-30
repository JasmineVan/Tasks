///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function ActionsCompleted(Val JobsToCheck, JobsToCancel) Export
	
	Result = TimeConsumingOperations.ActionsCompleted(JobsToCheck);
	For each JobID In JobsToCancel Do
		TimeConsumingOperations.CancelJobExecution(JobID);
		Result.Insert(JobID, New Structure("Status", "Canceled"));
	EndDo;
	Return Result;
	
EndFunction

#EndRegion
