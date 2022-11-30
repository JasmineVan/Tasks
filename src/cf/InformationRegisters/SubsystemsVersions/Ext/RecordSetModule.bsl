///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();
	For each VersionRecord In ThisObject Do
		If Not IsBlankString(VersionRecord.Version) AND Not IsFullVersionNumber(VersionRecord.Version) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Некорректный номер версии: %1 (ожидалось значение в виде ""1.2.3.4"")'; en = 'Invalid version number: %1. The expected format is ""1.2.3.4"".'; pl = 'Nieprawidłowy numer wersji: %1 (oczekiwana była wartość w postaci ""1.2.3.4"")';de = 'Falsche Versionsnummer: %1 (erwarteter Wert ist ""1.2.3.4"")';ro = 'Număr de versiune incorect: %1 (se aștepta valoarea în formă de ""1.2.3.4"")';tr = 'Yanlış sürüm numarası: %1(""1.2.3.4"" olarak beklenen değer"")'; es_ES = 'Número de versión incorrecto: %1 (se esperaba un valor del tipo ""1.2.3.4"")'"), VersionRecord.Version));
			Cancel = True; 
	    	AttributesNotToCheck.Add("Version"); 
		EndIf;
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region Private

Function IsFullVersionNumber(Val VersionNumber)
	
	VersionParts = StrSplit(VersionNumber, ".");
	If VersionParts.Count() <> 4 Then
		Return False;	
	EndIf;
	
	NumberType = New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
 	For Digit = 0 To 3 Do
		VersionPart = VersionParts[Digit];
		If NumberType.AdjustValue(VersionPart) = 0 AND VersionPart <> "0" Then
			Return False;
		EndIf;
	EndDo;
	Return True;
		
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf