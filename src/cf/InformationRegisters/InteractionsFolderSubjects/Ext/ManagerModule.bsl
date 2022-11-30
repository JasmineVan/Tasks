///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(Interaction)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update handlers

// Infobase update procedure for SSL 2.2.
// Moves Reviewed and ReviewAfter from interaction document attributes to information register
// InteractionsFolderSubjects.
//
Procedure UpdateStoragereviewedReviewAfter_2_2_0_0(Parameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1000
	|	Meeting.Ref,
	|	Meeting.Delete_Reviewed AS Reviewed,
	|	Meeting.Delete_ReviewAfter AS ReviewAfter
	|FROM
	|	Document.Meeting AS Meeting
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
	|WHERE
	|	NOT (NOT Meeting.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT Meeting.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)
	|
	|UNION ALL
	|
	|SELECT
	|	PlannedInteraction.Ref,
	|	PlannedInteraction.Delete_Reviewed,
	|	PlannedInteraction.Delete_ReviewAfter
	|FROM
	|	Document.PlannedInteraction AS PlannedInteraction
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = PlannedInteraction.Ref)
	|WHERE
	|	NOT (NOT PlannedInteraction.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT PlannedInteraction.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)
	|
	|UNION ALL
	|
	|SELECT
	|	PhoneCall.Ref,
	|	PhoneCall.Delete_Reviewed,
	|	PhoneCall.Delete_ReviewAfter
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
	|WHERE
	|	NOT (NOT PhoneCall.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT PhoneCall.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)
	|
	|UNION ALL
	|
	|SELECT
	|	IncomingEmail.Ref,
	|	IncomingEmail.Delete_Reviewed,
	|	IncomingEmail.Delete_ReviewAfter
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
	|WHERE
	|	NOT (NOT IncomingEmail.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT IncomingEmail.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	OutgoingEmail.Delete_Reviewed,
	|	OutgoingEmail.Delete_ReviewAfter
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
	|WHERE
	|	NOT (NOT OutgoingEmail.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT OutgoingEmail.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)
	|
	|UNION ALL
	|
	|SELECT
	|	SMSMessage.Ref,
	|	SMSMessage.Delete_Reviewed,
	|	SMSMessage.Delete_ReviewAfter
	|FROM
	|	Document.SMSMessage AS SMSMessage
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = SMSMessage.Ref)
	|WHERE
	|	NOT (NOT SMSMessage.Delete_Reviewed <> InteractionsFolderSubjects.Reviewed
	|			AND NOT SMSMessage.Delete_ReviewAfter <> InteractionsFolderSubjects.ReviewAfter)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Attributes = InteractionAttributes();
		Attributes.Reviewed = Selection.Reviewed;
		Attributes.ReviewAfter = Selection.ReviewAfter;
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Interaction.Set(Selection.Ref);
		WriteInteractionFolderSubjects(Selection.Ref, Attributes, RecordSet);
		InfobaseUpdate.WriteData(RecordSet);
	
	EndDo;
	
	Parameters.ProcessingCompleted = (Selection.Count() = 0);

EndProcedure

// Generates a blank structure to write to the InteractionsFolderSubjects information register.
//
Function InteractionAttributes() Export

	Result = New Structure;
	Result.Insert("Topic"                ,Undefined);
	Result.Insert("Folder"                  ,Undefined);
	Result.Insert("Reviewed"            ,Undefined);
	Result.Insert("ReviewAfter"       ,Undefined);
	Result.Insert("CalculateReviewedItems",True);
	
	Return Result;
	
EndFunction

// Sets a folder, subject, and review attributes for interactions.
//
// Parameters:
//  Ref - DocumentRef.IncomingEmail,
//                DocumentRef.OutgoingEmail,
//                DocumentRef.Meeting,
//                DocumentRef.PlannedInteraction,
//                DocumentRef.PhoneCall - an interaction, for which a folder and a subject will be set.
//  Attributes    - Structure - see InformationRegisters.InteractionsFolderSubjects. InteractionAttributes.
//  RecordSet - InformationRegister.InteractionsFolderSubjects.RecordSet - a register record set if 
//                 is created at the time of the procedure call.
//
Procedure WriteInteractionFolderSubjects(Interaction, Attributes, RecordSet = Undefined) Export
	
	Folder                   = Attributes.Folder;
	Topic                 = Attributes.Topic;
	Reviewed             = Attributes.Reviewed;
	ReviewAfter        = Attributes.ReviewAfter;
	CalculateReviewedItems = Attributes.CalculateReviewedItems;
	
	CreateAndWrite = (RecordSet = Undefined);
	
	If Folder = Undefined AND Topic = Undefined AND Reviewed = Undefined 
		AND ReviewAfter = Undefined  Then
		
		Return;
		
	ElsIf Folder = Undefined OR Topic = Undefined OR Reviewed = Undefined 
		OR ReviewAfter = Undefined Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsFolderSubjects.Topic,
		|	InteractionsFolderSubjects.EmailMessageFolder,
		|	InteractionsFolderSubjects.Reviewed,
		|	InteractionsFolderSubjects.ReviewAfter
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|WHERE
		|	InteractionsFolderSubjects.Interaction = &Interaction";
		
		Query.SetParameter("Interaction",Interaction);
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			
			Selection = Result.Select();
			Selection.Next();
			
			If Folder = Undefined Then
				Folder = Selection.EmailMessageFolder;
			EndIf;
			
			If Topic = Undefined Then
				Topic = Selection.Topic;
			EndIf;
			
			If Reviewed = Undefined Then
				Reviewed = Selection.Reviewed;
			EndIf;
			
			If ReviewAfter = Undefined Then
				ReviewAfter = Selection.ReviewAfter;
			EndIf;
			
		EndIf;
	EndIf;
	
	If CreateAndWrite Then
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Interaction.Set(Interaction);
	EndIf;
	Record = RecordSet.Add();
	Record.Interaction          = Interaction;
	Record.Topic                 = Topic;
	Record.EmailMessageFolder = Folder;
	Record.Reviewed             = Reviewed;
	Record.ReviewAfter        = ReviewAfter;
	RecordSet.AdditionalProperties.Insert("CalculateReviewedItems", CalculateReviewedItems);
	
	If CreateAndWrite Then
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
