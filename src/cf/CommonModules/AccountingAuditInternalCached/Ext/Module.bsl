///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Generates the structure of check tables and check groups for further use.
//
// Returns:
//    Structure with the following values:
//       * ChecksGroups - ValueTable - a table of group checks.
//       * Checks       - ValueTable - a table of checks.
//
Function AccountingChecks() Export
	
	ChecksGroups = ChecksGroupsNewTable();
	Checks       = NewChecksTable();
	
	AddAccountingSystemChecks(ChecksGroups, Checks);
	
	SSLSubsystemsIntegration.OnDefineChecks(ChecksGroups, Checks);
	AccountingAuditOverridable.OnDefineChecks(ChecksGroups, Checks);
	
	// For backward compatibility.
	AccountingAuditOverridable.OnDefineAppliedChecks(ChecksGroups, Checks);
	ProvideReverseCompatibility(Checks);
	
	Return New FixedStructure("ChecksGroups, Validation", ChecksGroups, Checks);
	
EndFunction

// Returns an array of types that includes all possible configuration object types.
//
// Returns:
//    Array - an array of object types.
//
Function TypeDetailsAllObjects() Export
	
	TypesArray = New Array;
	
	MetadataKindsArray = New Array;
	MetadataKindsArray.Add(Metadata.Documents);
	MetadataKindsArray.Add(Metadata.Catalogs);
	MetadataKindsArray.Add(Metadata.ExchangePlans);
	MetadataKindsArray.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKindsArray.Add(Metadata.ChartsOfAccounts);
	MetadataKindsArray.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKindsArray.Add(Metadata.Tasks);
	
	For Each MetadataKind In MetadataKindsArray Do
		For Each MetadataObject In MetadataKind Do
			
			SeparatedName = StrSplit(MetadataObject.FullName(), ".");
			If SeparatedName.Count() < 2 Then
				Continue;
			EndIf;
			
			TypesArray.Add(Type(SeparatedName.Get(0) + "Object." + SeparatedName.Get(1)));
			
		EndDo;
	EndDo;
	
	Return New FixedArray(TypesArray);
	
EndFunction

#EndRegion

#Region Private

// See AccountingAuditOverridable.OnDefineChecks 
Procedure AddAccountingSystemChecks(ChecksGroups, Checks)
	
	ChecksGroup = ChecksGroups.Add();
	ChecksGroup.Description                 = NStr("ru='Системные проверки'; en = 'System checks'; pl = 'System checks';de = 'System checks';ro = 'System checks';tr = 'System checks'; es_ES = 'System checks'");
	ChecksGroup.ID                = "SystemChecks";
	ChecksGroup.AccountingChecksContext = "SystemChecks";
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID          = ChecksGroup.ID;
	CheckSSL.Description                 = NStr("ru='Проверка незаполненных обязательных реквизитов'; en = 'Check for unfilled mandatory attributes'; pl = 'Check for unfilled mandatory attributes';de = 'Check for unfilled mandatory attributes';ro = 'Check for unfilled mandatory attributes';tr = 'Check for unfilled mandatory attributes'; es_ES = 'Check for unfilled mandatory attributes'");
	CheckSSL.Reasons                      = NStr("ru='Некорректная синхронизация данных с другими программами или импорт данных.'; en = 'Invalid data synchronization with external applications or data import.'; pl = 'Invalid data synchronization with external applications or data import.';de = 'Invalid data synchronization with external applications or data import.';ro = 'Invalid data synchronization with external applications or data import.';tr = 'Invalid data synchronization with external applications or data import.'; es_ES = 'Invalid data synchronization with external applications or data import.'");
	CheckSSL.Recommendation                 = NStr("ru='Перенастроить синхронизацию данных или заполнить обязательные реквизиты вручную.
		|Для этого можно также воспользоваться групповым изменением реквизитов (в разделе Администрирование).
		|В случае обнаружения незаполненных обязательных полей у регистров, то в большинстве
		|случаев, для устранения проблемы, достаточно заполнить соответствующие поля в документе-регистраторе.'; 
		|en = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.'; 
		|pl = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.';
		|de = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.';
		|ro = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.';
		|tr = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.'; 
		|es_ES = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.'");
	CheckSSL.ID                = "StandardSubsystems.CheckBlankMandatoryAttributes";
	CheckSSL.CheckHandler           = "AccountingAuditInternal.CheckUnfilledRequiredAttributes";
	CheckSSL.AccountingChecksContext = "SystemChecks";
	CheckSSL.Disabled                     = True;
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID          = ChecksGroup.ID;
	CheckSSL.Description                 = NStr("ru='Проверка ссылочной целостности'; en = 'Reference integrity check'; pl = 'Reference integrity check';de = 'Reference integrity check';ro = 'Reference integrity check';tr = 'Reference integrity check'; es_ES = 'Reference integrity check'");
	CheckSSL.Reasons                      = NStr("ru='Случайное или преднамеренное удаление данных без контроля ссылочной целостности, сбои в работе оборудования, некорректная синхронизация данных с другими программами или импорт данных, ошибки в сторонних инструментах (например, внешних обработках или расширениях).'; en = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; pl = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';de = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';ro = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';tr = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; es_ES = 'Accidental or intentional data deletion without reference integrity control, equipment failures, Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'");
	CheckSSL.Recommendation                 = NStr("ru='В зависимости от ситуации следует выбрать один из вариантов:
		|• восстановить удаленные данные из резервной копии,
		|• или очистить ссылки на удаленные данные (если они больше не требуются).'; 
		|en = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).'; 
		|pl = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).';
		|de = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).';
		|ro = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).';
		|tr = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).'; 
		|es_ES = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).'");
	If Not Common.DataSeparationEnabled() Then
		CheckSSL.Recommendation = CheckSSL.Recommendation + Chars.LF + Chars.LF 
			+ NStr("ru='Для очистки ссылок на удаленные данные следует:
			|• Завершить работу всех пользователей, установить блокировку входа в программу и сделать резервную копию информационной базы;
			|• Запустить конфигуратор, меню Администрирование - Тестирования и исправление, включить два флажка для проверки логической и ссылочной целостности
			|  См. подробнее на ИТС: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Дождаться завершения тестирования и исправления, снять блокировку входа в программу.
			|
			|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.'; 
			|en = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|pl = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|de = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|ro = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|es_ES = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check.
			| For more information, see ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142.
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'");
	
	EndIf;
	CheckSSL.Recommendation = CheckSSL.Recommendation + Chars.LF
		+ NStr("ru='В случае обнаружения битых ссылок в регистрах, то в большинстве случаев, для устранения проблемы
		|достаточно устранить соответствующие битые ссылки в документах-регистраторах.'; 
		|en = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.'; 
		|pl = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.';
		|de = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.';
		|ro = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.';
		|tr = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.'; 
		|es_ES = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.'");
	
	CheckSSL.ID                = "StandardSubsystems.CheckReferenceIntegrity";
	CheckSSL.CheckHandler           = "AccountingAuditInternal.CheckReferenceIntegrity";
	CheckSSL.AccountingChecksContext = "SystemChecks";
	CheckSSL.Disabled                     = True;
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID            = ChecksGroup.ID;
	CheckSSL.Description                   = NStr("ru='Проверка циклических ссылок'; en = 'Check for circular references'; pl = 'Check for circular references';de = 'Check for circular references';ro = 'Check for circular references';tr = 'Check for circular references'; es_ES = 'Check for circular references'");
	CheckSSL.Reasons                        = NStr("ru='Некорректная синхронизация данных с другими программами или импорт данных.'; en = 'Invalid data synchronization with external applications or data import.'; pl = 'Invalid data synchronization with external applications or data import.';de = 'Invalid data synchronization with external applications or data import.';ro = 'Invalid data synchronization with external applications or data import.';tr = 'Invalid data synchronization with external applications or data import.'; es_ES = 'Invalid data synchronization with external applications or data import.'");
	CheckSSL.Recommendation                   = NStr("ru='У одного из элементов очистить ссылку на родительский элемент (для автоматического исправления нажать ссылку ниже).
		|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
		|Затем выполнить синхронизацию с подчиненными узлами.'; 
		|en = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.'; 
		|pl = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.';
		|de = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.';
		|ro = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.';
		|tr = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.'; 
		|es_ES = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.'");
	CheckSSL.ID                  = "StandardSubsystems.CheckCircularRefs";
	CheckSSL.CheckHandler             = "AccountingAuditInternal.CheckCircularRefs";
	CheckSSL.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	CheckSSL.AccountingChecksContext   = "SystemChecks";
	CheckSSL.Disabled                      = True;
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID            = ChecksGroup.ID;
	CheckSSL.Description                   = NStr("ru='Проверка отсутствующих предопределенных элементов'; en = 'Check for missing predefined items'; pl = 'Check for missing predefined items';de = 'Check for missing predefined items';ro = 'Check for missing predefined items';tr = 'Check for missing predefined items'; es_ES = 'Check for missing predefined items'");
	CheckSSL.Reasons                        = NStr("ru='Некорректная синхронизация данных с другими программами или импорт данных, ошибки в сторонних инструментах (например, внешних обработках или расширениях).'; en = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; pl = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';de = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';ro = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';tr = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; es_ES = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'");
	CheckSSL.Recommendation                   = NStr("ru='В зависимости от ситуации следует выбрать один из вариантов:
		|• подобрать и указать в качестве предопределенного один из существующих элементов в списке; 
		|• восстановить предопределенные элементы из резервной копии;
		|• создать отсутствующие предопределенные элементы заново (для этого нажмите ссылку ниже).'; 
		|en = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).'; 
		|pl = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).';
		|de = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).';
		|ro = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).';
		|tr = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).'; 
		|es_ES = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).'"); 
	If Not Common.DataSeparationEnabled() Then
		CheckSSL.Recommendation = CheckSSL.Recommendation + Chars.LF
			+ NStr("ru='Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.'; 
			|en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|pl = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|de = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|ro = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|es_ES = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'");
	EndIf;
	CheckSSL.ID                  = "StandardSubsystems.CheckNoPredefinedItems";
	CheckSSL.CheckHandler             = "AccountingAuditInternal.CheckMissingPredefinedItems";
	CheckSSL.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	CheckSSL.AccountingChecksContext   = "SystemChecks";
	CheckSSL.Disabled                      = True;
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID          = ChecksGroup.ID;
	CheckSSL.Description                 = NStr("ru='Проверка дублирования предопределенных элементов'; en = 'Check for duplicate predefined items'; pl = 'Check for duplicate predefined items';de = 'Check for duplicate predefined items';ro = 'Check for duplicate predefined items';tr = 'Check for duplicate predefined items'; es_ES = 'Check for duplicate predefined items'");
	CheckSSL.Reasons                      = NStr("ru='Некорректная синхронизация данных с другими программами или импорт данных.'; en = 'Invalid data synchronization with external applications or data import.'; pl = 'Invalid data synchronization with external applications or data import.';de = 'Invalid data synchronization with external applications or data import.';ro = 'Invalid data synchronization with external applications or data import.';tr = 'Invalid data synchronization with external applications or data import.'; es_ES = 'Invalid data synchronization with external applications or data import.'");
	CheckSSL.Recommendation                 = NStr("ru='Запустить поиск и удаление дублей (в разделе Администрирование).'; en = 'Start duplicate objects detection in the Administration section.'; pl = 'Start duplicate objects detection in the Administration section.';de = 'Start duplicate objects detection in the Administration section.';ro = 'Start duplicate objects detection in the Administration section.';tr = 'Start duplicate objects detection in the Administration section.'; es_ES = 'Start duplicate objects detection in the Administration section.'");
	If Not Common.DataSeparationEnabled() Then
		CheckSSL.Recommendation = CheckSSL.Recommendation + Chars.LF
			+ NStr("ru='Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.'; 
			|en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|pl = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|de = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|ro = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|es_ES = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'");
	EndIf;
	CheckSSL.ID                = "StandardSubsystems.CheckDuplicatePredefinedItems";
	CheckSSL.CheckHandler           = "AccountingAuditInternal.CheckDuplicatePredefinedItems";
	CheckSSL.AccountingChecksContext = "SystemChecks";
	CheckSSL.Disabled                    = True;
	
	CheckSSL = Checks.Add();
	CheckSSL.GroupID          = ChecksGroup.ID;
	CheckSSL.Description                 = NStr("ru='Проверка отсутствия предопределенных узлов плана обмена'; en = 'Check for missing predefined nodes in exchange plan'; pl = 'Check for missing predefined nodes in exchange plan';de = 'Check for missing predefined nodes in exchange plan';ro = 'Check for missing predefined nodes in exchange plan';tr = 'Check for missing predefined nodes in exchange plan'; es_ES = 'Check for missing predefined nodes in exchange plan'");
	CheckSSL.Reasons                      = NStr("ru='Некорректное поведение программы при работе на устаревших версиях платформы 1С:Предприятие.'; en = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version'; pl = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version';de = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version';ro = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version';tr = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version'; es_ES = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version'");
	If Common.DataSeparationEnabled() Then
		CheckSSL.Recommendation             = NStr("ru='Обратиться в техническую поддержку сервиса.'; en = 'Contact technical service support.'; pl = 'Contact technical service support.';de = 'Contact technical service support.';ro = 'Contact technical service support.';tr = 'Contact technical service support.'; es_ES = 'Contact technical service support.'");
	Else	
		CheckSSL.Recommendation             = NStr("ru='• Перейти на версию платформы 1С:Предприятие 8.3.9.2033 или выше;
			|• Завершить работу всех пользователей, установить блокировку входа в программу и сделать резервную копию информационной базы;
			|• Запустить конфигуратор, меню Администрирование - Тестирования и исправление, включить два флажка для проверки логической и ссылочной целостности
			|  См. подробнее на ИТС: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Дождаться завершения тестирования и исправления, снять блокировку входа в программу.
			|
			|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.'; 
			|en = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|pl = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|de = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|ro = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; 
			|es_ES = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup
			|• Open Designer, open Administration – Verify and Repair menu, select the check boxes for logical integrity check and referential integrity check
			|  For more details, refer to ITS: https://its.1c.ru/db/v83doc#bookmark:adm:TI000000142
			|• Wait for verification and repair to complete, and unlock the application
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'");
	EndIf;
	CheckSSL.ID                = "StandardSubsystems.CheckNoPredefinedExchangePlansNodes";
	CheckSSL.CheckHandler           = "AccountingAuditInternal.CheckPredefinedExchangePlanNodeAvailability";
	CheckSSL.AccountingChecksContext = "SystemChecks";
	CheckSSL.Disabled                    = True;
	
EndProcedure

// Creates a table of check groups
//
// Returns:
//   ValueTable with the following columns:
//      * Description                 - String - a check group description.
//      * GroupID          - String - a string ID of the check group, for example:
//                                       "SystemChecks", "MonthEndClosing", "VATChecks", and so on.
//                                       Required.
//      * ID                - String - a string ID of the check group. Required.
//                                       The ID format has to be as follows:
//                                       <Software name>.<CheckID>. Example:
//                                       StandardSubsystems.SystemChecks.
//      * AccountingChecksContext - DefinedType.AccountingChecksContext - a value that additionally 
//                                       specifies the belonging of an accounting check group to a certain category.
//      * Comment                  - String - a comment to a check group.
//
Function ChecksGroupsNewTable()
	
	ChecksGroups        = New ValueTable;
	ChecksGroupColumns = ChecksGroups.Columns;
	ChecksGroupColumns.Add("Description",                 New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("ID",                New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("GroupID",          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("AccountingChecksContext", Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksGroupColumns.Add("Comment",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	
	Return ChecksGroups;
	
EndFunction

// Creates a check table.
//
// Returns:
//   ValueTable - a table with the following columns:
//      * GroupID                    - String - a string ID of the group of checks, for example:
//                                                 "SystemChecks", "MonthEndClosing", "VATChecks", and so on.
//                                                 Required.
//      * Description                          - String - a check description displayed to a user.
//      * Reasons                                - String - details of possible reasons that result 
//                                                 in issue appearing.
//      * Recommendation                           - String - a recommendation on solving an appeared issue.
//      * ID                          - String - an item string ID. Required.
//                                                 The ID format has to be as follows:
//                                                 <Software name>.<CheckID>. Example:
//                                                 StandardSubsystems.SystemChecks.
//      * CheckStartDate                     - Date - a threshold date that indicates the boundary 
//                                                 of the checked objects (only for objects with a date). 
//                                                 Do not check objects whose date is less than the specified one. It is not filled in by default (that means,
//                                                 check all).
//      * IssuesLimit                           - Number - a number of checked objects. The default value is 1000.
//                                                 If 0 is specified, check all objects.
//      * CheckHandler                     - String - a name of the export handler procedure of the 
//                                                 server common module as ModuleName.ProcedureName.
//      * GoToCorrectionHandler         - String - a name of the client handler procedure of the 
//                                                 server common module to start correcting an issue in the form of ModuleName.ProcedureName.
//      * WithoutCheckHandler                 - Boolean - a flag of the service check that does not have a handler procedure.
//      * ImportanceChangeProhibited             - Boolean - if True, the administrator cannot 
//                                                 change the severity of this check.
//      * AccountingChecksContext - DefinedType.AccountingChecksContext - a value that additionally 
//                                                 specifies the belonging of an accounting check to 
//                                                 a certain group or category.
//      * AccountingChecksContextClarification - DefinedType.AccountingChecksContextClarification - 
//                                                 the second value that additionally specifies the 
//                                                 belonging of an accounting check to a certain group or category.
//      * AdditionalParameters                - ValueStorage - an additional check information for 
//                                                 program use.
//      * Comment                            - String - a comment to the check.
//      * Disabled                              - Boolean - if True, the check will not be performed in the background on schedule.
//
Function NewChecksTable()
	
	Checks        = New ValueTable;
	ChecksColumns = Checks.Columns;
	ChecksColumns.Add("GroupID",                    New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Description",                           New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Reasons",                                New TypeDescription("String"));
	ChecksColumns.Add("Recommendation",                           New TypeDescription("String"));
	ChecksColumns.Add("ID",                          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("CheckStartDate",                     New TypeDescription("Date", , , , , New DateQualifiers(DateFractions.DateTime)));
	ChecksColumns.Add("IssuesLimit",                           New TypeDescription("Number", , , New NumberQualifiers(8, 0, AllowedSign.Nonnegative)));
	ChecksColumns.Add("CheckHandler",                     New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("GoToCorrectionHandler",         New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("NoCheckHandler",                 New TypeDescription("Boolean"));
	ChecksColumns.Add("ImportanceChangeDenied",             New TypeDescription("Boolean"));
	ChecksColumns.Add("AccountingChecksContext",           Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksColumns.Add("AccountingCheckContextClarification", Metadata.DefinedTypes.AccountingCheckContextClarification.Type);
	ChecksColumns.Add("AdditionalParameters",                New TypeDescription("ValueStorage"));
	ChecksColumns.Add("ParentID",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Comment",                            New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Disabled",                              New TypeDescription("Boolean"));
	Checks.Indexes.Add("ID");
	
	Return Checks;
	
EndFunction

Procedure ProvideReverseCompatibility(Checks)
	
	For Each CheckSSL In Checks Do
		
		If ValueIsFilled(CheckSSL.GroupID) Then
			Continue;
		EndIf;
		
		CheckSSL.GroupID = CheckSSL.ParentID;
		
	EndDo;
	
EndProcedure

#EndRegion