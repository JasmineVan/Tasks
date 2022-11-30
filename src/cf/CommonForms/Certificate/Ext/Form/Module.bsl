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
	
	If ValueIsFilled(Parameters.CertificateAddress) Then
		CertificateData = GetFromTempStorage(Parameters.CertificateAddress);
		Certificate = New CryptoCertificate(CertificateData);
		CertificateAddress = PutToTempStorage(CertificateData, UUID);
		
	ElsIf ValueIsFilled(Parameters.Ref) Then
		CertificateAddress = CertificateAddress(Parameters.Ref, UUID);
		
		If CertificateAddress = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось открыть сертификат ""%1"",
				           |т.к. он не найден в справочнике.'; 
				           |en = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.'; 
				           |pl = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.';
				           |de = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.';
				           |ro = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.';
				           |tr = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.'; 
				           |es_ES = 'Cannot open certificate ""%1""
				           |as it is not found in the catalog.'"), Parameters.Ref);
		EndIf;
	Else // Thumbprint
		CertificateAddress = CertificateAddress(Parameters.Thumbprint, UUID);
		
		If CertificateAddress = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось открыть сертификат, т.к. он не найден
				           |по отпечатку ""%1"".'; 
				           |en = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".'; 
				           |pl = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".';
				           |de = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".';
				           |ro = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".';
				           |tr = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".'; 
				           |es_ES = 'Cannot open the certificate as it is not found 
				           |by thumbprint ""%1"".'"), Parameters.Thumbprint);
		EndIf;
	EndIf;
	
	If CertificateData = Undefined Then
		CertificateData = GetFromTempStorage(CertificateAddress);
		Certificate = New CryptoCertificate(CertificateData);
	EndIf;
	
	CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
	
	AssignmentSign = Certificate.UseToSign;
	AssignmentEncryption = Certificate.UseToEncrypt;
	
	Thumbprint      = CertificateProperties.Thumbprint;
	IssuedTo      = CertificateProperties.IssuedTo;
	IssuedBy       = CertificateProperties.IssuedBy;
	ValidBefore = CertificateProperties.ValidTo;
	
	FillCertificatePurposeCodes(CertificateProperties.Purpose, AssignmentCodes);
	
	FillSubjectProperties(Certificate);
	FillIssuerProperties(Certificate);
	
	InternalFieldsGroup = "Common";
	FillInternalCertificateFields();
	
	If Parameters.Property("OpeningFromCertificateItemForm") Then
		Items.FormSaveToFile.Visible = False;
		Items.FormCheck.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InternalFieldsGroupOnChange(Item)
	
	FillInternalCertificateFields();
	
EndProcedure

&AtClient
Procedure InternalFieldsGroupClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureInternalClient.SaveCertificate(Undefined, CertificateAddress);
	
EndProcedure

&AtClient
Procedure CheckSSL(Command)
	
	DigitalSignatureClient.CheckCertificate(New NotifyDescription(
		"CheckCompletion", ThisObject), CertificateAddress);
	
EndProcedure

#EndRegion

#Region Private

// Continues the Check procedure.
&AtClient
Procedure CheckCompletion(Result, Context) Export
	
	If Result = True Then
		ShowMessageBox(, NStr("ru = 'Сертификат действителен.'; en = 'Certificate is valid.'; pl = 'Certificate is valid.';de = 'Certificate is valid.';ro = 'Certificate is valid.';tr = 'Certificate is valid.'; es_ES = 'Certificate is valid.'"));
		
	ElsIf Result <> Undefined Then
		WarningParameters = New Structure;
		
		WarningParameters.Insert("WarningText", Result);
		WarningParameters.Insert("WarningTitle", NStr("ru = 'Сертификат недействителен по причине:'; en = 'Certificate is invalid due to:'; pl = 'Certificate is invalid due to:';de = 'Certificate is invalid due to:';ro = 'Certificate is invalid due to:';tr = 'Certificate is invalid due to:'; es_ES = 'Certificate is invalid due to:'"));
		
		OpenForm("CommonForm.CheckResult", WarningParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSubjectProperties(Certificate)
	
	Collection = DigitalSignature.CertificateSubjectProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("ru = 'Общее имя'; en = 'Common name'; pl = 'Common name';de = 'Common name';ro = 'Common name';tr = 'Common name'; es_ES = 'Common name'");
	PropertiesPresentations["Country"] = NStr("ru = 'Страна'; en = 'Country'; pl = 'Country';de = 'Country';ro = 'Country';tr = 'Country'; es_ES = 'Country'");
	PropertiesPresentations["State"] = NStr("ru = 'Регион'; en = 'State'; pl = 'State';de = 'State';ro = 'State';tr = 'State'; es_ES = 'State'");
	PropertiesPresentations["Locality"] = NStr("ru = 'Населенный пункт'; en = 'Locality'; pl = 'Locality';de = 'Locality';ro = 'Locality';tr = 'Locality'; es_ES = 'Locality'");
	PropertiesPresentations["Street"] = NStr("ru = 'Улица'; en = 'Street'; pl = 'Street';de = 'Street';ro = 'Street';tr = 'Street'; es_ES = 'Street'");
	PropertiesPresentations["Company"] = NStr("ru = 'Организация'; en = 'Company'; pl = 'Company';de = 'Company';ro = 'Company';tr = 'Company'; es_ES = 'Company'");
	PropertiesPresentations["Department"] = NStr("ru = 'Подразделение'; en = 'Department'; pl = 'Department';de = 'Department';ro = 'Department';tr = 'Department'; es_ES = 'Department'");
	PropertiesPresentations["Email"] = NStr("ru = 'Электронная почта'; en = 'Email'; pl = 'Email';de = 'Email';ro = 'Email';tr = 'Email'; es_ES = 'Email'");
	
	If Metadata.CommonModules.Find("DigitalSignatureLocalizationClientServer") <> Undefined Then
		ModuleDigitalSignatureLocalizationClientServer = Common.CommonModule("DigitalSignatureLocalizationClientServer");
		CommonClientServer.SupplementMap(PropertiesPresentations,
			ModuleDigitalSignatureLocalizationClientServer.CertificateSubjectPropertiesPresentations(), True);
	EndIf;	
	
	For each ListItem In PropertiesPresentations Do
		PropertyValue = Collection[ListItem.Key];
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		Row = Subject.Add();
		Row.Property = ListItem.Value;
		Row.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIssuerProperties(Certificate)
	
	Collection = DigitalSignature.CertificateIssuerProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("ru = 'Общее имя'; en = 'Common name'; pl = 'Common name';de = 'Common name';ro = 'Common name';tr = 'Common name'; es_ES = 'Common name'");
	PropertiesPresentations["Country"] = NStr("ru = 'Страна'; en = 'Country'; pl = 'Country';de = 'Country';ro = 'Country';tr = 'Country'; es_ES = 'Country'");
	PropertiesPresentations["State"] = NStr("ru = 'Регион'; en = 'State'; pl = 'State';de = 'State';ro = 'State';tr = 'State'; es_ES = 'State'");
	PropertiesPresentations["Locality"] = NStr("ru = 'Населенный пункт'; en = 'Locality'; pl = 'Locality';de = 'Locality';ro = 'Locality';tr = 'Locality'; es_ES = 'Locality'");
	PropertiesPresentations["Street"] = NStr("ru = 'Улица'; en = 'Street'; pl = 'Street';de = 'Street';ro = 'Street';tr = 'Street'; es_ES = 'Street'");
	PropertiesPresentations["Company"] = NStr("ru = 'Организация'; en = 'Company'; pl = 'Company';de = 'Company';ro = 'Company';tr = 'Company'; es_ES = 'Company'");
	PropertiesPresentations["Department"] = NStr("ru = 'Подразделение'; en = 'Department'; pl = 'Department';de = 'Department';ro = 'Department';tr = 'Department'; es_ES = 'Department'");
	PropertiesPresentations["Email"] = NStr("ru = 'Электронная почта'; en = 'Email'; pl = 'Email';de = 'Email';ro = 'Email';tr = 'Email'; es_ES = 'Email'");
	
	If Metadata.CommonModules.Find("DigitalSignatureLocalizationClientServer") <> Undefined Then
		ModuleDigitalSignatureLocalizationClientServer = Common.CommonModule("DigitalSignatureLocalizationClientServer");
		CommonClientServer.SupplementMap(PropertiesPresentations,
			ModuleDigitalSignatureLocalizationClientServer.CertificateIssuerPropertiesPresentations(), True);
	EndIf;
		
	For each ListItem In PropertiesPresentations Do
		PropertyValue = Collection[ListItem.Key];
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		Row = Issuer.Add();
		Row.Property = ListItem.Value;
		Row.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInternalCertificateFields()
	
	InternalContent.Clear();
	CertificateBinaryData = GetFromTempStorage(CertificateAddress);
	Certificate = New CryptoCertificate(CertificateBinaryData);
	
	If InternalFieldsGroup = "Common" Then
		Items.InternalContentID.Visible = False;
		
		AddProperty(Certificate, "Version",                    NStr("ru = 'Версия'; en = 'Version'; pl = 'Version';de = 'Version';ro = 'Version';tr = 'Version'; es_ES = 'Version'"));
		AddProperty(Certificate, "StartDate",                NStr("ru = 'Дата начала'; en = 'Start date'; pl = 'Start date';de = 'Start date';ro = 'Start date';tr = 'Start date'; es_ES = 'Start date'"));
		AddProperty(Certificate, "EndDate",             NStr("ru = 'Дата окончания'; en = 'End date'; pl = 'End date';de = 'End date';ro = 'End date';tr = 'End date'; es_ES = 'End date'"));
		AddProperty(Certificate, "UseToSign",    NStr("ru = 'Использовать для подписи'; en = 'Use for signature'; pl = 'Use for signature';de = 'Use for signature';ro = 'Use for signature';tr = 'Use for signature'; es_ES = 'Use for signature'"));
		AddProperty(Certificate, "UseToEncrypt", NStr("ru = 'Использовать для шифрования'; en = 'Use for encryption'; pl = 'Use for encryption';de = 'Use for encryption';ro = 'Use for encryption';tr = 'Use for encryption'; es_ES = 'Use for encryption'"));
		AddProperty(Certificate, "PublicKey",              NStr("ru = 'Открытый ключ'; en = 'Public key'; pl = 'Public key';de = 'Public key';ro = 'Public key';tr = 'Public key'; es_ES = 'Public key'"), True);
		AddProperty(Certificate, "Thumbprint",                 NStr("ru = 'Отпечаток'; en = 'Thumbprint'; pl = 'Thumbprint';de = 'Thumbprint';ro = 'Thumbprint';tr = 'Thumbprint'; es_ES = 'Thumbprint'"), True);
		AddProperty(Certificate, "SerialNumber",             NStr("ru = 'Серийный номер'; en = 'Serial number'; pl = 'Serial number';de = 'Serial number';ro = 'Serial number';tr = 'Serial number'; es_ES = 'Serial number'"), True);
		
	ElsIf InternalFieldsGroup = "Extensions" Then
		Items.InternalContentID.Visible = False;
		
		Collection = Certificate.Extensions;
		For Each KeyAndValue In Collection Do
			AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
		EndDo;
	Else
		Items.InternalContentID.Visible = True;
		
		IDsNames = New ValueList;
		IDsNames.Add("OID2_5_4_3",              "CN");
		IDsNames.Add("OID2_5_4_6",              "C");
		IDsNames.Add("OID2_5_4_8",              "ST");
		IDsNames.Add("OID2_5_4_7",              "L");
		IDsNames.Add("OID2_5_4_9",              "Street");
		IDsNames.Add("OID2_5_4_10",             "O");
		IDsNames.Add("OID2_5_4_11",             "OU");
		IDsNames.Add("OID2_5_4_12",             "T");
		IDsNames.Add("OID1_2_840_113549_1_9_1", "E");
		
		IDsNames.Add("OID1_2_643_100_1",     "OGRN");
		IDsNames.Add("OID1_2_643_100_5",     "OGRNIP");
		IDsNames.Add("OID1_2_643_100_3",     "SNILS");
		IDsNames.Add("OID1_2_643_3_131_1_1", "INN");
		IDsNames.Add("OID2_5_4_4",           "SN");
		IDsNames.Add("OID2_5_4_42",          "GN");
		
		NamesAndIDs = New Map;
		Collection = Certificate[InternalFieldsGroup];
		
		For Each ListItem In IDsNames Do
			If Collection.Property(ListItem.Value) Then
				AddProperty(Collection, ListItem.Value, ListItem.Presentation);
			EndIf;
			NamesAndIDs.Insert(ListItem.Value, True);
			NamesAndIDs.Insert(ListItem.Presentation, True);
		EndDo;
		
		For Each KeyAndValue In Collection Do
			If NamesAndIDs.Get(KeyAndValue.Key) = Undefined Then
				AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProperty(PropertiesValues, Property, Presentation, Lowercase = Undefined)
	
	Value = PropertiesValues[Property];
	If TypeOf(Value) = Type("Date") Then
		Value = ToLocalTime(Value, SessionTimeZone());
	ElsIf TypeOf(Value) = Type("FixedArray") Then
		FixedArray = Value;
		Value = "";
		For each ArrayElement In FixedArray Do
			Value = Value + ?(Value = "", "", Chars.LF) + TrimAll(ArrayElement);
		EndDo;
	EndIf;
	
	Row = InternalContent.Add();
	If StrStartsWith(Property, "OID") Then
		Row.ID = StrReplace(Mid(Property, 4), "_", ".");
		If Property <> Presentation Then
			Row.Property = Presentation;
		EndIf;
	Else
		Row.Property = Presentation;
	EndIf;
	
	If Lowercase = True Then
		Row.Value = Lower(Value);
	Else
		Row.Value = Value;
	EndIf;
	
EndProcedure

// Transforms certificate purposes into purpose codes.
//
// Parameters:
//  Purpose    - String - a multiline certificate purpose, for example:
//                           "Microsoft Encrypted File System (1.3.6.1.4.1.311.10.3.4)
//                           |E-mail Protection (1.3.6.1.5.5.7.3.4)
//                           |TLS Web Client Authentication (1.3.6.1.5.5.7.3.2)".
//  
//  PurposeCodes - String - purpose codes "1.3.6.1.4.1.311.10.3.4, 1.3.6.1.5.5.7.3.4, 1.3.6.1.5.5.7.3.2".
//
&AtServer
Procedure FillCertificatePurposeCodes(Assignment, PurposeCodes)
	
	SetPrivilegedMode(True);
	
	Codes = "";
	
	For Index = 1 To StrLineCount(Assignment) Do
		
		Row = StrGetLine(Assignment, Index);
		CurrentCode = "";
		
		Position = StrFind(Row, "(", SearchDirection.FromEnd);
		If Position <> 0 Then
			CurrentCode = Mid(Row, Position + 1, StrLen(Row) - Position - 1);
		EndIf;
		
		If ValueIsFilled(CurrentCode) Then
			Codes = Codes + ?(Codes = "", "", ", ") + TrimAll(CurrentCode);
		EndIf;
		
	EndDo;
	
	PurposeCodes = Codes;
	
EndProcedure

&AtServer
Function CertificateAddress(RefThumbprint, FormID = Undefined)
	
	CertificateData = Undefined;
	
	If TypeOf(RefThumbprint) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Storage = Common.ObjectAttributeValue(RefThumbprint, "CertificateData");
		If TypeOf(Storage) = Type("ValueStorage") Then
			CertificateData = Storage.Get();
		EndIf;
	Else
		Query = New Query;
		Query.SetParameter("Thumbprint", RefThumbprint);
		Query.Text =
		"SELECT
		|	Certificates.CertificateData
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint = &Thumbprint";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			CertificateData = Selection.CertificateData.Get();
		Else
			Certificate = DigitalSignatureInternal.GetCertificateByThumbprint(RefThumbprint, False, False);
			If Certificate <> Undefined Then
				CertificateData = Certificate.Unload();
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(CertificateData) = Type("BinaryData") Then
		Return PutToTempStorage(CertificateData, FormID);
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion
