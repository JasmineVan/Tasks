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
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		ModuleSafeModeManager   = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
		
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If Not AdditionalProperties.Property("SkipBasicFillingCheck") Then
	
		If Not SequenceNumberUnique(FillOrder, Ref) Then
			ErrorText = NStr("ru = 'Порядок заполнения не уникален - в системе уже есть том с таким порядком'; en = 'The filling order is not unique. A volume with this order already exists.'; pl = 'Tryb wypełnienia nie jest unikalny - w systemie już jest tom z takim trybem';de = 'Die Füllreihenfolge ist nicht eindeutig. Das Volumen mit dieser Reihenfolge ist bereits im System vorhanden';ro = 'Completarea comenzii nu este unică - volumul cu astfel de ordine există deja în sistem';tr = 'Doldurma sırası benzersiz değil. Sistemde böyle bir düzene sahip disk bölümü zaten var'; es_ES = 'Orden de relleno no es único. Volumen con este orden ya existe en el sistema'");
			Common.MessageToUser(ErrorText, , "FillOrder", "Object", Cancel);
		EndIf;
		
		If MaxSize <> 0 Then
			CurrentSizeInBytes = 0;
			If Not Ref.IsEmpty() Then
				CurrentSizeInBytes = FilesOperationsInternal.CalculateFileSizeInVolume(Ref);
			EndIf;
			ActualSize = CurrentSizeInBytes / (1024 * 1024);
			
			If MaxSize < ActualSize Then
				ErrorText = NStr("ru = 'Максимальный размер тома меньше, чем текущий размер'; en = 'The volume size limit is less than the current size.'; pl = 'Maksymalny rozmiar tomu jest mniejszy niż bieżący rozmiar';de = 'Die maximale Größe des Volumens ist kleiner als die aktuelle Größe';ro = 'Dimensiunea maximă a volumului este mai mică decât dimensiunea curentă';tr = 'Disk bölümün maksimum boyutu geçerli boyuttan daha küçüktür'; es_ES = 'Tamaño máximo del volumen es menor al tamaño actual'");
				Common.MessageToUser(ErrorText, , "MaxSize", "Object", Cancel);
			EndIf;
		EndIf;
		
		If IsBlankString(FullPathWindows) AND IsBlankString(FullPathLinux) Then
			ErrorText = NStr("ru = 'Не заполнен полный путь'; en = 'The full path is required.'; pl = 'Pełna ścieżka nie jest wypełniona';de = 'Der vollständige Pfad wurde nicht eingegeben';ro = 'Traseul complet nu este introdus';tr = 'Tam yol girilmedi'; es_ES = 'Ruta completa no se ha introducido'");
			Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
			Common.MessageToUser(ErrorText, , "FullPathLinux",   "Object", Cancel);
			Return;
		EndIf;
		
		If Not UseSecurityProfiles
		   AND Not IsBlankString(FullPathWindows)
		   AND (    Left(FullPathWindows, 2) <> "\\"
		      OR StrFind(FullPathWindows, ":") <> 0 ) Then
			
			ErrorText = NStr("ru = 'Путь к тому должен быть в формате UNC (\\servername\resource).'; en = 'The volume path must have UNC format (\\server_name\resource).'; pl = 'Ścieżka do woluminu musi mieć format UNC (\\servername\resource).';de = 'Der Pfad zum Volumen muss das UNC-Format haben (\\ Servername \ Ressource).';ro = 'Calea pentru volum trebuie să aibă formatul UNC (\\ servername\resource).';tr = 'Disk bölümü yolu UNC biçiminde olmalıdır ((\\servername\resource).'; es_ES = 'Ruta para el volumen tiene que tener el formato UNC (\\ nombredelservidor\recurso).'");
			Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
			Return;
		EndIf;
	EndIf;
	
	If Not AdditionalProperties.Property("SkipDirectoryAccessCheck") Then
		FullPathFieldName = "";
		FullVolumePath = "";
		
		If Common.IsWindowsServer() Then
			FullVolumePath = FullPathWindows;
			FullPathFieldName = "FullPathWindows";
		Else
			FullVolumePath = FullPathLinux;
			FullPathFieldName = "FullPathLinux";
		EndIf;
		
		TestDirectoryName = FullVolumePath + "CheckAccess" + GetPathSeparator();
		
		Try
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			ErrorInformation = ErrorInfo();
			
			If UseSecurityProfiles Then
				ErrorTemplate =
					NStr("ru = 'Путь к тому некорректен.
					           |Возможно не настроены разрешения в профилях безопасности,
					           |или учетная запись, от лица которой работает
					           |сервер 1С:Предприятия, не имеет прав доступа к каталогу тома.
					           |
					           |%1'; 
					           |en = 'Invalid volume path.
					           |Possibly security profile permissions are not configured,
					           |or an account on whose behalf 1C:Enterprise server is running
					           |does not have access rights to the volume directory.
					           |
					           |%1'; 
					           |pl = 'Ścieżka do woluminu jest nieprawidłowa.
					           |Być może nie ustawiono uprawnień w profilach bezpieczeństwa,
					           |lub konto, w imieniu którego pracuje
					           |serwer 1C:Enterprise, nie posiada praw dostępu do katalogu woluminu.
					           |
					           |%1';
					           |de = 'Der Pfad zum Volumen ist falsch.
					           |Möglicherweise sind die Berechtigungen in den Sicherheitsprofilen nicht konfiguriert,
					           |oder das Konto, für das der
					           |1C:Enterprise-Server ausgeführt wird, verfügt nicht über Zugriffsrechte für das Volumen-Verzeichnis.
					           |
					           |%1';
					           |ro = 'Calea spre volum este incorectă.
					           |Posibil, nu sunt configurate permisiunile în profilele de securitate,
					           |sau accountul, din numele căruia lucrează
					           |serverul 1С:Enterprise, nu are drepturi de acces la catalogul volumului.
					           |
					           |%1';
					           |tr = 'Birim yolu doğru değil. 
					           |Güvenlik profillerinde izin verilmeyebilir veya 
					           |1C:Enterprise adına çalıştığı 
					           |hesap, birim dizinine erişim iznine sahip olmayabilir. 
					           |
					           |%1'; 
					           |es_ES = 'La ruta al tomo no es correcta.
					           |Es posible que no se hayan ajustado las extensiones en los perfiles de seguridad
					           |o la cuenta que usa
					           |el servidor de 1C:Enterprise no tenga derechos de acceso al catálogo del tomo.
					           |
					           |%1'");
			Else
				ErrorTemplate =
					NStr("ru = 'Путь к тому некорректен.
					           |Возможно учетная запись, от лица которой работает
					           |сервер 1С:Предприятия, не имеет прав доступа к каталогу тома.
					           |
					           |%1'; 
					           |en = 'Invalid volume path.
					           |Possibly an account on whose behalf 1C:Enterprise server is running
					           |does not have access rights to the volume directory.
					           |
					           |%1'; 
					           |pl = 'Ścieżka do woluminu jest nieprawidłowa.
					           |Być może konto, w imieniu którego pracuje
					           |serwer 1C:Enterprise, nie posiada praw dostępu do katalogu woluminu.
					           |
					           |%1';
					           |de = 'Der Pfad zum Volumen ist falsch.
					           |Es ist möglich, dass das Konto, für das der
					           |1C:Enterprise-Server ausgeführt wird, keine Zugriffsrechte für das Volumen-Verzeichnis hat.
					           |
					           |%1';
					           |ro = 'Calea către volum nu este corectă.
					           |Posibil contul, din numele căruia funcționează
					           |serverul 1C: Enterprise nu are drepturi de acces la directorul de volum.
					           |
					           |%1';
					           |tr = 'Birim yolu doğru değil. 
					           |1C:Enterprise sunucusunun 
					           |çalıştığı hesap, disk bölümü dizinine erişim haklarına sahip değildir. 
					           |
					           |%1'; 
					           |es_ES = 'La ruta al tomo no es correcta.
					           |Es posible que la cuenta que usa
					           |el servidor de 1C:Enterprise no tenga derechos de acceso al catálogo del tomo.
					           |
					           |%1'");
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate, BriefErrorDescription(ErrorInformation));
			
			Common.MessageToUser(
				ErrorText, , FullPathFieldName, "Object", Cancel);
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns False if there is a volume of the same order.
Function SequenceNumberUnique(FillOrder, VolumeRef)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(Volumes.FillOrder) AS Count
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.FillOrder = &FillOrder
	|	AND Volumes.Ref <> &VolumeRef";
	
	Query.Parameters.Insert("FillOrder", FillOrder);
	Query.Parameters.Insert("VolumeRef", VolumeRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Count = 0;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf