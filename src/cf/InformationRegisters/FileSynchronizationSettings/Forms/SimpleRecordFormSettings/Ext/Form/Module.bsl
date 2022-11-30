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
	
	If Parameters.Property("FileOwner") Then
		Record.FileOwner = Parameters.FileOwner;
	EndIf;
	
	If Parameters.Property("FileOwnerType") Then
		Record.FileOwnerType = Parameters.FileOwnerType;
	EndIf;
	
	If Parameters.Property("IsFile") Then
		Record.IsFile = Parameters.IsFile;
	EndIf;
	
	OwnerPresentation = Common.SubjectString(Record.FileOwner);
	
	Title = NStr("ru='Настройка синхронизации файлов:'; en = 'File synchronization settings:'; pl = 'Dostosowanie synchronizacji plików:';de = 'Einrichten der Dateisynchronisation:';ro = 'Setarea sincronizării fișierelor:';tr = 'Dosya eşleşmesinin ayarı:'; es_ES = 'Ajuste de sincronización de archivos:'")
		+ " " + OwnerPresentation;
	
EndProcedure

#EndRegion