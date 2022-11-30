///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ByAuthor = Users.CurrentUser();
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "SourceTask", Tasks.PerformerTask.EmptyRef());
	
	SetFilter();
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.DueDate.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");
	Items.VerificationDueDate.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");
	BusinessProcessesAndTasksServer.SetBusinessProcessesAppearance(List.ConditionalAppearance);
	Items.FormStop.Visible = AccessRight("Update", Metadata.BusinessProcesses.Job);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	SetListFilter(Settings);	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByAuthorOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ByPerformerOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure BySupervisorOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ShowCompletedJobsOnChange(Item)
	
	SetFilter();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ShowStoppedItemsOnChange(Item)
	
	SetFilter();
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Stop(Command)
	
	BusinessProcessesAndTasksClient.Stop(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure ContinueBusinessProcess(Command)
	
	BusinessProcessesAndTasksClient.Activate(Items.List.SelectedRows);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFilter()
	FilterParameters = New Map();
	FilterParameters.Insert("ShowCompletedJobs", ShowCompletedJobs);
	FilterParameters.Insert("ShowStopped", ShowStopped);
	FilterParameters.Insert("ByAuthor", ByAuthor);
	FilterParameters.Insert("ByPerformer", ByPerformer);
	FilterParameters.Insert("BySupervisor", BySupervisor);
	SetListFilter(FilterParameters);
EndProcedure

&AtServer
Procedure SetListFilter(FilterParameters)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Completed", False,,,
		Not FilterParameters["ShowCompletedJobs"]);
	CommonClientServer.SetDynamicListFilterItem(List, "Stopped", False,,,
		Not FilterParameters["ShowStopped"]);
	CommonClientServer.SetDynamicListFilterItem(List, "Author", FilterParameters["ByAuthor"],,,
		Not FilterParameters["ByAuthor"].IsEmpty());
	CommonClientServer.SetDynamicListFilterItem(List, "Performer", FilterParameters["ByPerformer"],,,
		Not FilterParameters["ByPerformer"].IsEmpty());
	CommonClientServer.SetDynamicListFilterItem(List, "Supervisor", FilterParameters["BySupervisor"],,,
		Not FilterParameters["BySupervisor"].IsEmpty());
	
EndProcedure

#EndRegion
