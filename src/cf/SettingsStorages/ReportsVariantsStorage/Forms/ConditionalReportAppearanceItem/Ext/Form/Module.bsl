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
	
	If Not Parameters.Property("SettingsComposer", SettingsComposer) Then
		Raise NStr("ru = 'Не передан служебный параметр ""КомпоновщикНастроек"".'; en = 'SettingsComposer service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego SettingsLinker.';de = 'Der SettingsLinker-Serviceparameter ist nicht bestanden.';ro = 'Parametrul serviciului ”SettingsLinker” nu este transmis.';tr = 'SettingsLinker hizmet parametresi iletilmedi.'; es_ES = 'El parámetro de servicio SettingsLinker no está pasado.'");
	EndIf;
	If Not Parameters.Property("ReportSettings", ReportSettings) Then
		Raise NStr("ru = 'Не передан служебный параметр ""НастройкиОтчета"".'; en = 'ReportSettings service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ReportSettings.';de = 'Serviceparameter ""ReportSettings"" ist nicht bestanden.';ro = 'Parametrul serviciului ""ReportSettings"" nu este transmis.';tr = 'Servis parametresi ReportSettings geçmedi.'; es_ES = 'Parámetro de servicio ReportSettings no está pasado.'");
	EndIf;
	If Not Parameters.Property("SettingsStructureItemID", SettingsStructureItemID) Then
		Raise NStr("ru = 'Не передан служебный параметр ""ИдентификаторЭлементаСтруктурыНастроек"".'; en = 'SettingsStructureItemID service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ""SettingsStructureItemID"".';de = 'Der Serviceparameter ""SettingsStructureItemID"" wird nicht übergeben.';ro = 'Parametrul serviciului ""SettingsStructureItemID"" nu este transmis.';tr = 'Hizmet parametresi ""SettingsStructureItemID"" geçmedi.'; es_ES = 'El parámetro de servicio ""SettingsStructureItemID"" no está pasado.'");
	EndIf;
	If Not Parameters.Property("DCID", DCID) Then
		Raise NStr("ru = 'Не передан служебный параметр ""ИдентификаторКД"".'; en = 'DCID service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego DCIdentifier.';de = 'Der Serviceparameter DCID wird nicht übergeben.';ro = 'Parametrul de service DCID nu este acceptat.';tr = 'Servis parametresi DCID geçmedi.'; es_ES = 'Parámetro de servicio DCID no está pasado.'");
	EndIf;
	If Not Parameters.Property("Description", Description) Then
		Raise NStr("ru = 'Не передан служебный параметр ""Наименование"".'; en = 'Description service parameter has not been passed.'; pl = 'Nie przekazano parametru serwisowego ""Nazwa"".';de = 'Der Serviceparameter ""Name"" wird nicht weitergegeben.';ro = 'Parametrul serviciului ”Name” nu este transmis.';tr = 'Servis parametresi ""İsim"" aktarılmıyor.'; es_ES = 'No se ha pasado el parámetro de servicio ""Nombre"".'");
	EndIf;
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf;
	
	Source = New DataCompositionAvailableSettingsSource(ReportSettings.SchemaURL);
	SettingsComposer.Initialize(Source);
	
	DCNode = SettingsComposer.Settings.ConditionalAppearance;
	If DCID = Undefined Then // New item
		IsNew = True;
		DCItem = DCNode.Items.Insert(0);
		DCItem.Use = True;
		DCItem.ViewMode = DataCompositionSettingsItemViewMode.Normal;
		Items.Description.ClearButton = False;
	Else
		DCNodeSource = DCNode(ThisObject);
		If DCNodeSource = Undefined Then
			Raise NStr("ru = 'Не найден узел отчета.'; en = 'Cannot find report node.'; pl = 'Nie znaleziono węzła raportu.';de = 'Berichtsknoten nicht gefunden';ro = 'Nodul de raport nu a fost găsit.';tr = 'Rapor ünitesi bulunamadı.'; es_ES = 'Nodo de informes no encontrado.'");
		EndIf;
		DCItemSource = DCNodeSource.GetObjectByID(DCID);
		If DCItemSource = Undefined Then
			Raise NStr("ru = 'Не найден элемент условного оформления.'; en = 'Cannot find conditional appearance item.'; pl = 'Nie znaleziono elementu widoku warunkowego.';de = 'Artikel mit bedingter Darstellung wird nicht gefunden.';ro = 'Elementul de aspect condițional nu a fost găsit.';tr = 'Koşullu görünümün öğesi bulunamadı.'; es_ES = 'Artículo del formato condicional no se ha encontrado.'");
		EndIf;
		DCItem = ReportsClientServer.CopyRecursive(DCNode, DCItemSource, DCNode.Items, 0, New Map);
		
		DefaultDescription = ReportsClientServer.ConditionalAppearanceItemPresentation(DCItem, Undefined, "");
		DescriptionOverridden = (Description <> "" AND Description <> DefaultDescription);
		Items.Description.InputHint = DefaultDescription;
		If Not DescriptionOverridden Then
			Description = "";
			Items.Description.ClearButton = False;
		EndIf;
	EndIf;
	
	For Each CheckBoxField In Items.GroupDisplayArea.ChildItems Do
		CheckBoxName = CheckBoxField.Name;
		DisplayAreaCheckBoxes.Add(CheckBoxName);
		If DCItem[CheckBoxName] = DataCompositionConditionalAppearanceUse.Use Then
			ThisObject[CheckBoxName] = True;
		EndIf;
	EndDo;
	
	CloseOnChoice = False;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	If Description = "" Or Description = Items.Description.InputHint Then
		DefaultDescriptionUpdateRequired = True;
		UpdateDefaultDescriptionIfRequired();
		Items.Description.ClearButton = False;
	Else
		Items.Description.ClearButton = True;
	EndIf;
EndProcedure

&AtClient
Procedure UseInGroupOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInHierarchicalGroupOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInOverallOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInFieldsTitleOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInTitleOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInParametersOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure UseInFilterOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAppearance

&AtClient
Procedure AppearanceOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilter

&AtClient
Procedure FilterOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFormattedFields

&AtClient
Procedure FormattedFieldsOnChange(Item)
	UpdateDefaultDescription();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	SelectAndClose();
EndProcedure

&AtClient
Procedure Show_SelectCheckBoxes(Command)
	For Each ListItem In DisplayAreaCheckBoxes Do
		ThisObject[ListItem.Value] = True;
	EndDo;
	UpdateDefaultDescription();
EndProcedure

&AtClient
Procedure Show_ClearCheckBoxes(Command)
	For Each ListItem In DisplayAreaCheckBoxes Do
		ThisObject[ListItem.Value] = False;
	EndDo;
EndProcedure

&AtClient
Procedure InsertDefaultDescription(Command)
	Description = DefaultDescription;
	Items.Description.ClearButton = False;
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function DCNode(Form)
	If Form.SettingsStructureItemID = Undefined Then
		Return Form.SettingsComposer.Settings.ConditionalAppearance;
	Else
		DCCurrentNode = Form.SettingsComposer.Settings.GetObjectByID(Form.SettingsStructureItemID);
		Return DCCurrentNode.ConditionalAppearance;
	EndIf;
EndFunction

&AtClient
Procedure UpdateDefaultDescription()
	DefaultDescriptionUpdateRequired = True;
	If Description = "" Or Description = Items.Description.InputHint Then
		AttachIdleHandler("UpdateDefaultDescriptionIfRequired", 1, True);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateDefaultDescriptionIfRequired()
	If Not DefaultDescriptionUpdateRequired Then
		Return;
	EndIf;
	DefaultDescriptionUpdateRequired = False;
	DCNode = SettingsComposer.Settings.ConditionalAppearance;
	DCItem = DCNode.Items[0];
	DefaultDescription = ReportsClientServer.ConditionalAppearanceItemPresentation(DCItem, Undefined, "");
	If Description = Items.Description.InputHint Then
		Description = DefaultDescription;
		Items.Description.InputHint = DefaultDescription;
	ElsIf Description = "" Then
		Items.Description.InputHint = DefaultDescription;
	EndIf;
EndProcedure

&AtClient
Procedure SelectAndClose()
	DetachIdleHandler("UpdateDefaultDescriptionIfRequired");
	UpdateDefaultDescriptionIfRequired();
	
	If Description = "" Then
		Description = DefaultDescription;
	EndIf;
	
	DCItem = SettingsComposer.Settings.ConditionalAppearance.Items[0];
	
	If Description = DefaultDescription Then
		DCItem.UserSettingPresentation = "";
	Else
		DCItem.UserSettingPresentation = Description;
	EndIf;
	
	For Each ListItem In DisplayAreaCheckBoxes Do
		CheckBoxName = ListItem.Value;
		If ThisObject[CheckBoxName] Then
			DCItem[CheckBoxName] = DataCompositionConditionalAppearanceUse.Use;
		Else
			DCItem[CheckBoxName] = DataCompositionConditionalAppearanceUse.DontUse;
		EndIf;
	EndDo;
	
	Result = New Structure("DCItem, Description", DCItem, Description);
	NotifyChoice(Result);
	Close(Result);
EndProcedure

#EndRegion