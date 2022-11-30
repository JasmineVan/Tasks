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
	
	If TypeOf(Parameters.SupportedClients) = Type("Structure") Then 
		FillPropertyValues(ThisObject, Parameters.SupportedClients);
	EndIf;
	
	Available = PictureLib.AddInIsAvailable;
	Unavailable = PictureLib.AddInNotAvailable;
	
	Items.Windows_x86_1CEnterprise.Picture = ?(Windows_x86, Available, Unavailable);
	Items.Windows_x86_Chrome.Picture = ?(Windows_x86_Chrome, Available, Unavailable);
	Items.Windows_x86_Firefox.Picture = ?(Windows_x86_Firefox, Available, Unavailable);
	Items.Windows_x86_MSIE.Picture = ?(Windows_x86_MSIE, Available, Unavailable);
	Items.Windows_x86_64_1CEnterprise.Picture = ?(Windows_x86_64, Available, Unavailable);
	Items.Windows_x86_64_Chrome.Picture = ?(Windows_x86_Chrome, Available, Unavailable);
	Items.Windows_x86_64_Firefox.Picture = ?(Windows_x86_Firefox, Available, Unavailable);
	Items.Windows_x86_64_MSIE.Picture = ?(Windows_x86_64_MSIE, Available, Unavailable);
	Items.Linux_x86_1CEnterprise.Picture = ?(Linux_x86, Available, Unavailable);
	Items.Linux_x86_Chrome.Picture = ?(Linux_x86_Chrome, Available, Unavailable);
	Items.Linux_x86_Firefox.Picture = ?(Linux_x86_Firefox, Available, Unavailable);
	Items.Linux_x86_64_1CEnterprise.Picture = ?(Linux_x86_64, Available, Unavailable);
	Items.Linux_x86_64_Chrome.Picture = ?(Linux_x86_64_Chrome, Available, Unavailable);
	Items.Linux_x86_64_Firefox.Picture = ?(Linux_x86_64_Firefox, Available, Unavailable);
	Items.MacOS_x86_64_Safari.Picture = ?(MacOS_x86_64_Safari, Available, Unavailable);
	
EndProcedure

#EndRegion