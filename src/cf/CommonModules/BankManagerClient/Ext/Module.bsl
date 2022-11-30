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

// See CommonClientOverridable.AfterStart. 
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Banks") AND ClientParameters.Banks.OutputMessageOnInvalidity Then
		AttachIdleHandler("BankManagerOutputObsoleteDataNotification", 45, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Bank classifier update.

// Displays the update notification.
//
Procedure NotifyClassifierObsolete() Export
	
	ShowUserNotification(
		NStr("ru = 'Классификатор банков устарел'; en = 'The bank classifier is outdated'; pl = 'Klasyfikator bankowy jest nieaktualny';de = 'Bank-Klassifikator ist veraltet';ro = 'Bank classifier is outdated';tr = 'Banka sınıflandırıcı zaman aşımına uğramış'; es_ES = 'Clasificador de bancos está desactualizado'"),
		NotificationURLImportForm(),
		NStr("ru = 'Обновить классификатор банков'; en = 'Update the bank classifier'; pl = 'Zaktualizować klasyfikator banków';de = 'Aktualisieren des Bankklassifiziers';ro = 'Actualizare clasificatorul băncilor';tr = 'Banka sınıflandırıcısını yenile'; es_ES = 'Actualizar el clasificador de los bancos'"),
		PictureLib.Warning32);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyClassifierSuccessfullyUpdated() Export
	
	ShowUserNotification(
		NStr("ru = 'Классификатор банков успешно обновлен'; en = 'The bank classifier is updated'; pl = 'Klasyfikator bankowy został pomyślnie zaktualizowany';de = 'Bank-Klassifikator wurde erfolgreich aktualisiert';ro = 'Clasificatorul băncilor este actualizat cu succes';tr = 'Banka sınıflandırıcısı başarıyla güncellendi'; es_ES = 'Clasificador de bancos de la actualizado con éxito'"),
		NotificationURLImportForm(),
		NStr("ru = 'Классификатор банков обновлен'; en = 'The bank classifier is updated'; pl = 'Klasyfikator bankowy jest aktualizowany';de = 'Bank-Klassifikator ist aktualisiert';ro = 'Clasificatorul bancar este actualizat';tr = 'Banka sınıflandırıcısı güncellendi'; es_ES = 'Clasificador de bancos está actualizado'"),
		PictureLib.Information32);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyClassifierUpToDate() Export
	
	ShowMessageBox(,NStr("ru = 'Классификатор банков актуален.'; en = 'The bank classifier is up-to-date.'; pl = 'Klasyfikator banków aktualny.';de = 'Bankklassifizierer ist aktuell.';ro = 'Clasificatorul băncilor este actual.';tr = 'Banka sınıflandırıcısı günceldir.'; es_ES = 'Clasificador de los bancos está actualizado.'"));
	
EndProcedure

// Returns a notification URL.
//
Function NotificationURLImportForm()
	Return "e1cib/data/DataProcessor.ImportBankClassifier.Form.ImportClassifier";
EndFunction

Procedure OpenClassifierImportForm(Owner, OpenFromList = False) Export
	If OpenFromList Then
		FormParameters = New Structure("OpeningFromList");
	EndIf;
	FormName = "DataProcessor.ImportBankClassifier.Form.ImportClassifier";
	OpenForm(FormName, FormParameters, Owner);
EndProcedure

#EndRegion
