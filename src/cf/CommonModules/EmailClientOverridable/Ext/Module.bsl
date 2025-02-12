﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called before opening a new email form.
// Changing parameter StandardProcessing can cancel opening the form.
//
// Parameters:
//  SendingParameters    - Structure - see EmailOperationsClient.CreateNewEmailMessage.
//  CompletionHandler - NotifyDescription - description of the procedure that is called after 
//                                              sending email.
//  StandardProcessing - Boolean - shows whether a new email form continues opening after the 
//                                  procedure ends. If False, the email form is not opened.
Procedure BeforeOpenEmailSendingForm(SendOptions, CompletionHandler, StandardProcessing) Export
	
EndProcedure

#EndRegion