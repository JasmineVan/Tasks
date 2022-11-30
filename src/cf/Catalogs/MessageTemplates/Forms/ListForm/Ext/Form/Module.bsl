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
	
	SetConditionalAppearance();
	
	InitializeFilters();
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		SendSMSMessageEnabled = True;
		EmailOperationsEnabled = True;
	Else
		EmailOperationsEnabled = Common.SubsystemExists("StandardSubsystems.EmailOperations");
		SendSMSMessageEnabled = Common.SubsystemExists("StandardSubsystems.SendSMSMessage");
	EndIf;
	
	// buttons are in the group; if there is one button, the group is not required
	Items.FormCreateSMSMessageTemplate.Visible = SendSMSMessageEnabled;
	Items.FormCreateEmailTemplate.Visible = EmailOperationsEnabled;
	
	Items.FormShowContextTemplates.Visible = Users.IsFullUser();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_MessagesTemplates" Then
		InitializeFilters();
		SetAssignmentFilter(Purpose);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssignmentFilterOnChange(Item)
	SelectedItem = Items.AssignmentFilter.ChoiceList.FindByValue(Purpose);
	SetAssignmentFilter(SelectedItem.Presentation);
EndProcedure

&AtClient
Procedure TemplateForFilterChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ValueSelected = "SMS" Then
		CommonClientServer.SetFilterItem(List.Filter, "TemplateFor", NStr("ru = 'Сообщения SMS'; en = 'Text messages'; pl = 'Text messages';de = 'Text messages';ro = 'Text messages';tr = 'Text messages'; es_ES = 'Text messages'"), DataCompositionComparisonType.Equal);
	ElsIf ValueSelected = "Email" Then
		CommonClientServer.SetFilterItem(List.Filter, "TemplateFor", NStr("ru = 'Электронного письма'; en = 'Email'; pl = 'Email';de = 'Email';ro = 'Email';tr = 'Email'; es_ES = 'Email'"), DataCompositionComparisonType.Equal);
	Else
		CommonClientServer.DeleteFilterItems(List.Filter, "TemplateFor");
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnReceiveDataAtServer(ItemName, Settings, Rows)
	
	Query = New Query("SELECT 
	| MessagesTemplatesPrintFormsAndAttachments.Ref AS Ref
	|FROM
	|	Catalog.MessageTemplates.PrintFormsAndAttachments AS MessagesTemplatesPrintFormsAndAttachments
	|WHERE
	| MessagesTemplatesPrintFormsAndAttachments.Ref IN (&MessageTemplates)
	|GROUP BY
	| MessagesTemplatesPrintFormsAndAttachments.Ref");
	Query.SetParameter("MessageTemplates", Rows.GetKeys());
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	For each MessagesTemplate In Result Do
		ListLine = Rows[MessagesTemplate];
		ListLine.Data["HasFiles"] = 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateEmailTemplate(Command)
	CreateTemplate("EmailMessage");
EndProcedure

&AtClient
Procedure CreateSMSMessageTemplate(Command)
	CreateTemplate("SMSMessage");
EndProcedure

&AtClient
Procedure ShowContextTemplates(Command)
	Items.FormShowContextTemplates.Check = Not Items.FormShowContextTemplates.Check;
	List.Parameters.SetParameterValue("ShowContextTemplates", Items.FormShowContextTemplates.Check);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Ref.TemplateOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateTemplate(MessageType)
	FormParameters = New Structure();
	FormParameters.Insert("MessageKind",           MessageType);
	FormParameters.Insert("FullBasisTypeName", Purpose);
	FormParameters.Insert("CanChangeAssignment",  True);
	OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure SetAssignmentFilter(Val SelectedValue)
	
	If IsBlankString(SelectedValue) Then
		CommonClientServer.DeleteFilterItems(List.Filter, "Purpose");
	Else
		CommonClientServer.SetFilterItem(List.Filter, "Purpose", SelectedValue, DataCompositionComparisonType.Equal);
	EndIf;

EndProcedure

&AtServer
Procedure InitializeFilters()
	
	Items.AssignmentFilter.ChoiceList.Clear();
	Items.TemplateForFilter.ChoiceList.Clear();
	
	List.Parameters.SetParameterValue("Purpose", "");
	
	TemplatesKinds = MessageTemplatesInternal.TemplatesKinds();
	TemplatesKinds.Insert(0, NStr("ru = 'Электронных писем и SMS'; en = 'Emails and SMS'; pl = 'Emails and SMS';de = 'Emails and SMS';ro = 'Emails and SMS';tr = 'Emails and SMS'; es_ES = 'Emails and SMS'"), NStr("ru = 'Электронных писем и SMS'; en = 'Emails and SMS'; pl = 'Emails and SMS';de = 'Emails and SMS';ro = 'Emails and SMS';tr = 'Emails and SMS'; es_ES = 'Emails and SMS'"));
	
	List.Parameters.SetParameterValue("SMSMessage", TemplatesKinds.FindByValue("SMS").Presentation);
	List.Parameters.SetParameterValue("Email", TemplatesKinds.FindByValue("Email").Presentation);
	List.Parameters.SetParameterValue("ShowContextTemplates", False);
	
	For each TemplateKind In TemplatesKinds Do
		Items.TemplateForFilter.ChoiceList.Add(TemplateKind.Value, TemplateKind.Presentation);
	EndDo;
	
	Items.AssignmentFilter.ChoiceList.Add("", NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'"));
	
	CommonTemplatePresentation = NStr("ru = 'Общий'; en = 'Common'; pl = 'Common';de = 'Common';ro = 'Common';tr = 'Common'; es_ES = 'Common'");
	List.Parameters.SetParameterValue("Common",    CommonTemplatePresentation);
	Items.AssignmentFilter.ChoiceList.Add("Common", CommonTemplatePresentation);
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	MessageTemplates.Purpose AS Purpose,
		|	MessageTemplates.InputOnBasisParameterTypeFullName AS InputOnBasisParameterTypeFullName
		|FROM
		|	Catalog.MessageTemplates AS MessageTemplates
		|WHERE
		|	MessageTemplates.Purpose <> """" AND MessageTemplates.Purpose <> ""Internal""
		|	AND MessageTemplates.Purpose <> &Common
		|
		|GROUP BY
		|	MessageTemplates.Purpose, MessageTemplates.InputOnBasisParameterTypeFullName
		|
		|ORDER BY
		|	Purpose";
	
	Query.SetParameter("Common", CommonTemplatePresentation);
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		Items.AssignmentFilter.ChoiceList.Add(QueryResult.InputOnBasisParameterTypeFullName, QueryResult.Purpose);
	EndDo;
	
	Purpose = "";
	TemplateFor = NStr("ru = 'Электронных писем и SMS'; en = 'Emails and SMS'; pl = 'Emails and SMS';de = 'Emails and SMS';ro = 'Emails and SMS';tr = 'Emails and SMS'; es_ES = 'Emails and SMS'");
	
EndProcedure

#EndRegion
