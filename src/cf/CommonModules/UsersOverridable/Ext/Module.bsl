///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Redefines the standard behavior of the Users subsystem.
//
// Parameters:
//  Settings - Structure - with the following properties:
//   * CommonAuthorizationSettings - Boolean - indicates whether the administration panel will have the
//          "Users and rights settings". Login settings and the availability of action period limit 
//          settings are available in user and external user forms.
//          It is True by default and False for basic versions of the configuration.
//
//   * EditRoles - Boolean - shows whether the role editing interface is available in profiles of 
//          users, external users, and groups of external users. This affects both regular users and 
//          administrators. The default value is True.
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

// Allows you to specify roles, the purpose of which will be controlled in a special way.
// The majority of configuration roles here are not required as they are intended for any users 
// except for external ones.
//
// Parameters:
//  RolesAssignment - Structure - with the following properties:
//   * ForSystemAdministratorsOnly - Array - role names that, when separation is disabled, are 
//     intended for any users other than external users, and in separated mode, are intended only 
//     for service administrators, for example:
//       Administration, DatabaseConfigurationUpdate, SystemAdministrator,
//     and also all roles with the rights:
//       Administration,
//       Administration of configuration extensions,
//       Update database configuration.
//     Such roles are usually available in SSL and not available in applications.
//
//   * ForSystemUsersOnly - Array - role names that, when separation is disabled, are intended for 
//     any users other than external users, and in separated mode, are intended only for 
//     non-separated users (technical support stuff and service administrators), for example:
//     
//       AddEditAddressInfo, AddEditBanks,
//     and all roles with rights to change non-separated data and those that have the following rules:
//       Thick client,
//       External connection,
//       Automation,
//       Mode "All functions",
//       Interactive open external data processors,
//       Interactive open external reports.
//     Such roles are mainly available in SSL. However, they might be available in applications.
//
//   * ForExternalUsersOnly - Array - role names that are intended only for external users (roles 
//     with a specially developed set of rights), for example:
//       AddEditQuestionnaireQuestionsAnswers, BasicSSLRightsForExternalUsers.
//     Such roles are available both both in SSL and applications (if external users are used).
//
//   * BothForUsersAndExternalUsers - Array - role names that are intended for any users (internal, 
//     external, and non-separated), for example:
//       ReadQuestionnaireQuestionsAnswers, AddEditPersonalReportsOptions.
//     Such roles are available both both in SSL and applications (if external users are used).
//
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	
	
	
	
EndProcedure

// Overrides the behavior of the user form, the external user form, and a group of external users, 
// when it should be different from the default behavior.
//
// For example, you need to hide, show, or allow to change or lock some properties in cases that are 
// defined by the applied logic.
//
// Parameters:
//  UserOrGroup - CatalogRef.Users,
//                          CatalogRef.ExternalUsers,
//                          CatalogRef.ExternalUsersGroups - reference to the user, external user, 
//                          or external user group at the time of form creation.
//
//  FormActions - Structure - with the following properties:
//         * Roles - String - "", "View", "Editing".
//                                             For example, when roles are edited in another form, 
//                                             you can hide them in this form or just lock editing.
//         * ContactInformation - String - "", "View", "Editing".
//                                             This property is not available for external user groups.
//                                             For example, you may need to hide contact information 
//                                             from the user with no application rights to view CI.
//         * IBUserProperties - String - "", "View", or "Editing".
//                                             This property is not available for external user groups.
//                                             For example, you may need to show infobase user 
//                                             properties for a user who has application rights to this information.
//         * ItemProperties - String - "", "View", "Editing".
//                                             For example, Description is the full name of the 
//                                             infobase user. It might require editing the 
//                                             description for a user who has application rights for employee operations.
//
Procedure ChangeFormActions(Val UserOrGroup, Val FormActions) Export
	
EndProcedure

// Redefines actions that are required on infobase user writing.
// For example, if you need to synchronously update record in the matching register and so on.
// The procedure is called from the Users.WriteIBUser procedure if the user was changed.
// If the Name field in the PreviousProperties structure is not filled, a new infobase user is created.
//
// Parameters:
//  PreviousProperties - Structure - see Users.NewIBUserDetails. 
//  NewProperties - Structure - see Users.NewIBUserDetails. 
//
Procedure OnWriteInfobaseUser(Val PreviousProperties, Val NewProperties) Export
	
EndProcedure

// Redefines actions that are required after deleting an infobase user.
// For example, if you need to synchronously update record in the matching register and so on.
// The procedure is called from the DeleteIBUser() procedure if the user has been deleted.
//
// Parameters:
//  PreviousProperties - Structure - see Users.NewIBUserDetails. 
//
Procedure AfterDeleteInfobaseUser(Val PreviousProperties) Export
	
EndProcedure

// Overrides interface settings for new users.
// For example, you can set initial settings of command interface sections location.
//
// Parameters:
//  InitialSettings - Structure - the default settings:
//   * ClientSettings - ClientSettings - client application settings.
//   * InterfaceSettings - CommandInterfaceSettings - Command interface settings (for sections panel, 
//                                                                      navigation panel, and actions panel)
//   * TaxiSettings - ClientApplicationInterfaceSettings - client application interface settings 
//                                                                      (panel content and positions).
//
//   * IsExternalUser - Boolean - if True, then this is an external user.
//
Procedure OnSetInitialSettings(InitialSettings) Export
	
	
	
EndProcedure

// Allows you to add an arbitrary setting on the Other tab in the UsersSettings handler interface so 
// that other users can delete or copy it.
// To be able to manage the setting, write its code of copying (see OnSaveOtherSetings) and deletion 
// (see OnDeleteOtherSettings). It will be called when interactive actions are performed on the setting.
//
// For example, the flag that shows whether the warning should be shown when closing the application.
//
// Parameters:
//  UserInfo - Structure - string and referential user presentation.
//       * UserRef - CatalogRef.Users - a user, from which you need to receive settings.
//                               
//       * InfobaseUserName - String - an infobase user, from which you need to receive settings.
//                                             
//  Settings - Structure - other user settings.
//       * Key - String - string ID of a setting that is used for copying and clearing the setting.
//                             
//       * Value - Structure - information about settings.
//              ** SettingName - String - name to be displayed in the setting tree.
//              ** SettingPicture - Picture - picture to be displayed in the tree of settings.
//              ** SettingsList - ValueList - a list of received settings.
//
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	
	
EndProcedure

// Saves arbitrary settings of the specified user.
// Also see OnGetOtherSettings.
//
// Parameters:
//  Settings - Structure - a structure with the fields:
//       * SettingID - String - a string of a setting to be copied.
//       * SettingValue - ValueList - a list of values of settings being copied.
//  UserInfo - Structure - string and referential user presentation.
//       * UserRef - CatalogRef.Users - a user who needs to copy a setting.
//                              
//       * InfobaseUserName - String - an infobase user.
//                                             
//
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	
	
EndProcedure

// Clears an arbitrary setting of a passed user.
// Also see OnGetOtherSettings.
//
// Parameters:
//  Settings - Structure - a structure with the fields:
//       * SettingID - String - a string of a setting to be cleared.
//       * SettingValue - ValueList - a list of values of settings being cleared.
//  UserInfo - Structure - string and referential user presentation.
//       * UserRef - CatalogRef.Users - a user who needs to clear a setting.
//                              
//       * InfobaseUserName - String - an infobase user.
//                                             
//
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	
	
EndProcedure

#EndRegion
