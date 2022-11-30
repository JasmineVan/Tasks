﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("ru='Обработка не предназначена для непосредственного использования.'; en = 'The data processor cannot be opened manually.'; pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesorul de date nu este destinat utilizării directe.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	
EndProcedure

#EndRegion