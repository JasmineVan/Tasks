﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Determines a handler list to generate (or update) the list of all current to-dos available in the 
// configuration.
//
// In the specified modules, a handler procedure with the following passed parameters must be placed:
//  ToDoList - ValueTable - defines to-do parameters:
//    * ID - String - internal to-do ID used by the subsystem.
//    * HasUserTasks - Boolean - if True, the to-do is displayed in the user's to-do list.
//    * Important - Boolean - if True, to-do is highlighted in red.
//    * HideInSettings - Boolean - if True, to-do is hidden in the to-do settings form.
//                            It can be applied to to-dos that are not used several times. Once 
//                            completed, these to-dos are no longer displayed in the infobase.
//                            
//    * Presentation - String - to-do presentation displayed to the user.
//    * Count - Number - a quantitative indicator of a to-do displayed in a to-do title.
//    * Form - String - a full path to the form that is displayed by clicking on the to-do hyperlink 
//                                in the To-do list panel.
//    * FormParameters - Structure - parameters for opening the indicator form.
//    * Owner - String and metadata object - string ID of the to-do that is the owner of the current 
//                       to-do, or a subsystem metadata object.
//    * Tooltip - String - a tooltip text.
// 
// The following is an example of a handler procedure for copying to the specified modules.
//
//// See ToDoListOverridable.OnDetermineToDoListHandlers. 
//Procedure OnFillToDoList(ToDoList) Export
//
//EndProcedure
//
// Parameters:
//  Handlers - Array - an array of references to manager modules or common modules, for example, 
//                         Documents.SalesOrder or ToDoListBySales.
// Example:
//  Handlers.Add(Documents.SalesOrder);
//
Procedure OnDetermineToDoListHandlers(Handlers) Export
	
	
	
	
	
EndProcedure

// It sets an initial order of sections in the To-do list panel.
//
// Parameters:
//  Sections - Array - an array of command interface sections.
//                     Sections in the To-do list panel are shown in the order in which they were 
//                     added to the array.
//
Procedure OnDetermineCommandInterfaceSectionsOrder(Sections) Export
	
	
	
	
	
EndProcedure

// It determines current to-dos that will not be shown to the user.
//
// Parameters:
//  UserTasksToDisable - Array - an array of strings of IDs of to-dos to disable.
//
Procedure OnDisableToDos(UserTasksToDisable) Export
	
EndProcedure

// It allows you to change some subsystem settings.
//
// Parameters:
//  Parameters - Structure - with the following properties:
//     * OtherUserTasksTitle - String - a title of a section where to-dos not included in command 
//                            interface sections are shown.
//                            It is applicable for to-dos whose placement in the panel is determined 
//                            by function ToDoListServer.SectionsForObject.
//                            If it is not specified, to-dos are displayed in a group with title
//                            Other to dos.
//
Procedure OnDefineSettings(Parameters) Export
	
	
	
EndProcedure

// Allows you to set query parameters common for several current to-dos.
//
// For example, if the CurrentDate parameter is set in several to-do receiving handlers, you can 
// specify parameter setting in this procedure and call procedure
// 
// ToDoList.SetCommonQueryParameters(), that will set this parameter.
//
// Parameters:
//  Query - Query - a running query.
//  CommonQueryParameters - Structure - common values for calculating current to-dos.
//
Procedure SetCommonQueryParameters(Query, CommonQueryParameters) Export
	
EndProcedure

// It is a handler procedure that you can call in to-do details forms to override parameters for 
// opening the form and setting required form list filters.
//
// Parameters:
//  Form - ManagedForm - a form the method was called from.
//  List - DynamicList - a list whose parameters can be overridden.
//
Procedure OnCreateAtServer(Form, List) Export
	
EndProcedure

// It is a handler procedure that you can call in the relevant handler of to-do details forms to 
// replace saved form attribute values.
//
// Parameters:
//  Form - ManagedForm - a form the method was called from.
//  Settings - Map - form settings with attribute values.
//
Procedure BeforeLoadDataFromSettingsAtServer(Form, Settings) Export
	
EndProcedure

#EndRegion