///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Count() = 1 Then
		Folder = Get(0).Folder;
		Path = Get(0).Path;
		
		If IsBlankString(Path) Then
			Return;
		EndIf;						
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	FilesFolders.Ref,
			|	FilesFolders.Description
			|FROM
			|	Catalog.FilesFolders AS FilesFolders
			|WHERE
			|	FilesFolders.Parent = &Ref";
		
		Query.SetParameter("Ref", Folder);
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			
			WorkingDirectory = Path;
			// Adding a slash to the end if it does not exist, the same type as it was before. It is required on 
			//  the client, and BeforeWrite is executed on the server.
			WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
			
			WorkingDirectory = WorkingDirectory + Selection.Description;
			WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
			
			FilesOperationsInternalServerCall.SaveFolderWorkingDirectory(
				Selection.Ref, WorkingDirectory);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf