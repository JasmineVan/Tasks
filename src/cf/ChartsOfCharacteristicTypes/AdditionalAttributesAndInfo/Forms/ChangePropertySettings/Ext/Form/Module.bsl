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
	
	If Parameters.IsAdditionalInfo Then
		Items.PropertyTypes.CurrentPage = Items.AdditionalInfoItem;
		Title = NStr("ru = 'Изменить настройку дополнительного сведения'; en = 'Change additional information setting'; pl = 'Zmień ustawienia informacji dodatkowej';de = 'Ändern Sie zusätzliche Informationseinstellungen';ro = 'Modificare setarea datelor suplimentare';tr = 'Ek bilgi ayarlarını değiştir'; es_ES = 'Cambiar las configuraciones de la información adicional'");
	Else
		Items.PropertyTypes.CurrentPage = Items.AdditionalAttribute;
	EndIf;
	
	If ValueIsFilled(Parameters.PropertiesSet) Then
		Items.AttributeKinds.CurrentPage = Items.SharedAttributesValuesKind;
		Items.InfoKinds.CurrentPage  = Items.SharedInfoValuesKind;
		
		If ValueIsFilled(Parameters.AdditionalValuesOwner) Then
			IndependentPropertyWithSharedValuesList = 1;
		Else
			IndependentPropertyWithIndependentValuesList = 1;
		EndIf;
	Else
		Items.AttributeKinds.CurrentPage = Items.SharedAttributeKind;
		Items.InfoKinds.CurrentPage  = Items.SharedInfoKind;
		
		CommonProperty = 1;
	EndIf;
	
	Property = Parameters.Property;
	CurrentPropertiesSet = Parameters.CurrentPropertiesSet;
	IsAdditionalInfo = Parameters.IsAdditionalInfo;
	
	Items.IndependentAttributeValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.IndependentAttributeValuesComment.Title, CurrentPropertiesSet);
	
	Items.SharedAttributesValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.SharedAttributesValuesComment.Title, CurrentPropertiesSet);
	
	Items.IndependentInfoItemValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.IndependentInfoItemValuesComment.Title, CurrentPropertiesSet);
	
	Items.SharedInfoValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.SharedInfoValuesComment.Title, CurrentPropertiesSet);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KindOnChange(Item)
	
	KindOnChangeAtServer(Item.Name);
	
EndProcedure

&AtServer
Procedure KindOnChangeAtServer(ItemName)
	
	IndependentPropertyWithSharedValuesList = 0;
	IndependentPropertyWithIndependentValuesList = 0;
	CommonProperty = 0;
	
	ThisObject[Items[ItemName].DataPath] = 1;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAndCloseCompletion();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseCompletion(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If IndependentPropertyWithIndependentValuesList = 1 Then
		WriteBeginning();
	Else
		WriteCompletion(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteBeginning()
	
	ExecutionResult = WriteAtServer();
	
	If ExecutionResult.Status = "Completed" Then
		OpenProperty = GetFromTempStorage(ExecutionResult.ResultAddress);
		WriteCompletion(OpenProperty);
	Else
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CompletionNotification = New NotifyDescription("WriteFollowUp", ThisObject);
		
		TimeConsumingOperationsClient.WaitForCompletion(ExecutionResult, CompletionNotification, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteFollowUp(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	OpenProperty = GetFromTempStorage(Result.ResultAddress);
	
	WriteCompletion(OpenProperty);
EndProcedure

&AtClient
Procedure WriteCompletion(OpenProperty)
	
	Modified = False;
	
	Notify("Write_AdditionalAttributesAndInfo",
		New Structure("Ref", Property), Property);
	
	Notify("Write_AdditionalDataAndAttributeSets",
		New Structure("Ref", CurrentPropertiesSet), CurrentPropertiesSet);
	
	NotifyChoice(OpenProperty);
	
EndProcedure

&AtServer
Function WriteAtServer()
	
	JobDescription = NStr("ru = 'Изменение настройки дополнительного свойства'; en = 'Change additional property settings'; pl = 'Zmień dodatkowe ustawienie właściwości';de = 'Ändern Sie zusätzliche Eigenschafteneinstellung';ro = 'Modificarea setării proprietății suplimentare';tr = 'Ek özellik ayarlarını değiştir'; es_ES = 'Cambiar las configuraciones de la propiedad adicional'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Property", Property);
	ProcedureParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitForCompletion = 2;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground("ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.ChangePropertySetting",
		ProcedureParameters, ExecutionParameters);
	
	Return Result;
	
EndFunction

#EndRegion
