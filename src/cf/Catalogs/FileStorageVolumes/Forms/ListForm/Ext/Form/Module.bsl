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
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.FormMarkForDeletion.OnlyInAllActions = False;
	EndIf;
	Items.MoveAllFilesToVolumes.Visible = Common.SubsystemExists("StandardSubsystems.FilesOperations");
	
	If Common.IsMobileClient() Then
		Items.ListComment.Visible = False;
		Items.ListMaxSize.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SetClearDeletionMark(Command)
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	StartDeletionMarkChange(Items.List.CurrentData);
	
EndProcedure

&AtClient
Procedure MoveAllFilesToVolumes(Command)
	
	FilesOperationsInternalClient.MoveAllFilesToVolumes();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartDeletionMarkChange(CurrentData)
	
	If CurrentData.DeletionMark Then
		QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to clear the deletion mark from ""%1""?'; pl = 'Oczyścić znacznik usunięcia dla ""%1""?';de = 'Löschzeichen für ""%1"" löschen?';ro = 'Scoateți marcajul la ștergere de pe ""%1""?';tr = '""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Eliminar la marca para borrar para ""%1""?'");
	Else
		QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark ""%1"" for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
	EndIf;
	
	QuestionContent = New Array;
	QuestionContent.Add(PictureLib.Question32);
	QuestionContent.Add(StringFunctionsClientServer.SubstituteParametersToString(
		QuestionText, CurrentData.Description));
	
	ShowQueryBox(
		New NotifyDescription("ContinueDeletionMarkChange", ThisObject, CurrentData),
		New FormattedString(QuestionContent),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ContinueDeletionMarkChange(Response, CurrentData) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Volume = Items.List.CurrentData.Ref;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Volume", Items.List.CurrentData.Ref);
	AdditionalParameters.Insert("DeletionMark", Undefined);
	AdditionalParameters.Insert("Queries", New Array());
	AdditionalParameters.Insert("FormID", UUID);
	
	PrepareSetClearDeletionMark(Volume, AdditionalParameters);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			AdditionalParameters.Queries, ThisObject, New NotifyDescription(
				"ContinueSetClearDeletionMark", ThisObject, AdditionalParameters));
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure PrepareSetClearDeletionMark(Volume, AdditionalParameters)
	
	LockDataForEdit(Volume, , AdditionalParameters.FormID);
	
	VolumeProperties = Common.ObjectAttributesValues(
		Volume, "DeletionMark,FullPathWindows,FullPathLinux");
	
	AdditionalParameters.DeletionMark = VolumeProperties.DeletionMark;
	
	If AdditionalParameters.DeletionMark Then
		// Deletion mark is set, and it is to be cleared.
		
		Query = Catalogs.FileStorageVolumes.RequestToUseExternalResourcesForVolume(
			Volume, VolumeProperties.FullPathWindows, VolumeProperties.FullPathLinux);
	Else
		// Deletion mark is not set, and it is to be set.
		If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
			Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(Volume)
		EndIf;
	EndIf;
	
	AdditionalParameters.Queries.Add(Query);
	
EndProcedure

&AtClient
Procedure ContinueSetClearDeletionMark(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		EndSetClearDeletionMark(AdditionalParameters);
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure EndSetClearDeletionMark(AdditionalParameters)
	
	BeginTransaction();
	Try
	
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.Catalogs.FileStorageVolumes.FullName());
		DataLockItem.SetValue("Ref", AdditionalParameters.Volume);
		DataLock.Lock();
		
		Object = AdditionalParameters.Volume.GetObject();
		Object.SetDeletionMark(Not AdditionalParameters.DeletionMark);
		Object.Write();
		
		UnlockDataForEdit(
		AdditionalParameters.Volume, AdditionalParameters.FormID);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion