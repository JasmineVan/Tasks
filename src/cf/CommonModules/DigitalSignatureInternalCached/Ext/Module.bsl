///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// For internal use only.
Function CommonSettings() Export
	
	CommonSettings = New Structure;
	
	SetPrivilegedMode(True);
	
	CommonSettings.Insert("UseDigitalSignature",
		Constants.UseDigitalSignature.Get());
	
	CommonSettings.Insert("UseEncryption",
		Constants.UseEncryption.Get());
	
	If Common.DataSeparationEnabled()
	 Or Common.FileInfobase()
	   AND Not Common.ClientConnectedOverWebServer() Then
		
		CommonSettings.Insert("VerifyDigitalSignaturesOnTheServer", False);
		CommonSettings.Insert("GenerateDigitalSignaturesAtServer", False);
	Else
		CommonSettings.Insert("VerifyDigitalSignaturesOnTheServer",
			Constants.VerifyDigitalSignaturesOnTheServer.Get());
		
		CommonSettings.Insert("GenerateDigitalSignaturesAtServer",
			Constants.GenerateDigitalSignaturesAtServer.Get());
	EndIf;
	
	CommonSettings.Insert("CertificateIssueRequestAvailable", 
		Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined);
	If CommonSettings.CertificateIssueRequestAvailable Then
		Application = Common.CommonModule("DataProcessors.ApplicationForNewQualifiedCertificateIssue");
		CommonSettings.CertificateIssueRequestAvailable = Application.CertificateIssueRequestAvailable();
	EndIf;		
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Applications.Ref AS Ref,
	|	Applications.Description AS Description,
	|	Applications.ApplicationName AS ApplicationName,
	|	Applications.ApplicationType AS ApplicationType,
	|	Applications.SignAlgorithm AS SignAlgorithm,
	|	Applications.HashAlgorithm AS HashAlgorithm,
	|	Applications.EncryptAlgorithm AS EncryptAlgorithm
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Applications
	|WHERE
	|	NOT Applications.DeletionMark
	|	AND NOT Applications.IsCloudServiceApplication
	|
	|ORDER BY
	|	Description";
	
	Selection = Query.Execute().Select();
	ApplicationsDetailsCollection = New Array;
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	While Selection.Next() Do
		Filter = New Structure("ApplicationName, ApplicationType", Selection.ApplicationName, Selection.ApplicationType);
		Rows = SettingsToSupply.FindRows(Filter);
		ID = ?(Rows.Count() = 0, "", Rows[0].ID);
		
		Details = New Structure;
		Details.Insert("Ref",              Selection.Ref);
		Details.Insert("Description",        Selection.Description);
		Details.Insert("ApplicationName",        Selection.ApplicationName);
		Details.Insert("ApplicationType",        Selection.ApplicationType);
		Details.Insert("SignAlgorithm",     Selection.SignAlgorithm);
		Details.Insert("HashAlgorithm", Selection.HashAlgorithm);
		Details.Insert("EncryptAlgorithm",  Selection.EncryptAlgorithm);
		Details.Insert("ID",       ID);
		ApplicationsDetailsCollection.Add(New FixedStructure(Details));
	EndDo;
	
	CommonSettings.Insert("ApplicationsDetailsCollection", New FixedArray(ApplicationsDetailsCollection));
	
	Return New FixedStructure(CommonSettings);
	
EndFunction

Function OwnersTypes(RefsOnly = False) Export
	
	Result = New Map;
	Types = Metadata.DefinedTypes.SignedObject.Type.Types();
	
	TypesToExclude = New Map;
	TypesToExclude.Insert(Type("Undefined"), True);
	TypesToExclude.Insert(Type("String"), True);
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		TypesToExclude.Insert(Type("CatalogRef." + "FilesVersions"), True);
	EndIf;
	
	For Each Type In Types Do
		If TypesToExclude.Get(Type) <> Undefined Then
			Continue;
		EndIf;
		Result.Insert(Type, True);
		If Not RefsOnly Then
			ObjectTypeName = StrReplace(Metadata.FindByType(Type).FullName(), ".", "Object.");
			Result.Insert(Type(ObjectTypeName), True);
		EndIf;
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion
