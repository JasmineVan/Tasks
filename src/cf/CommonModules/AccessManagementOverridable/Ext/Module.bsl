///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Fills access kinds used in access restrictions.
// Note: the Users and ExternalUsers access kinds are predefined, but you can remove them from the 
// AccessKinds list if you do not need them for access restriction.
//
// Parameters:
//  AccessKinds - ValueTable - a table with the following columns:
//   * Name                    - String - a name used in description of the supplied access group 
//                                       profiles and RLS texts.
//   * Presentation - String - presents an access kind in profiles and access groups.
//   * ValueType            - Type    - an access value reference type, for example, 
//                                       Type("CatalogRef.Products").
//   * ValuesGroupsType       - Type    - an access value group reference type, for example, 
//                                       Type("CatalogRef.ProductsAccessGroups").
//   * MultipleValuesGroups - Boolean - True indicates that you can select multiple value groups 
//                                       (Products access group) for an access value (Products).
//
// Example:
//  1. To set access rights by companies:
//  AccessKind = AccessKinds.Add(),
//  AccessKind.Name = "Companies",
//  AccessKind.Presentation = NStr("en = 'Companies'");
//  AccessKind.ValueType = Type("CatalogRef.Companies");
//
//  2. To set access rights by partner groups:
//  AccessKind = AccessKinds.Add(),
//  AccessKind.Name = "PartnersGroups",
//  AccessKind.Presentation = NStr("en = 'Partner groups'");
//  AccessKind.ValueType = Type("CatalogRef.Partners");
//  AccessKind.ValuesGroupsType = Type("CatalogRef.PartnersAccessGroups");
//
Procedure OnFillAccessKinds(AccessKinds) Export
	
	
	
EndProcedure

// Allows you to specify lists whose metadata objects contain description of the logic for access 
// restriction in the manager modules or the overridable module.
//
// In manager modules of the specified lists, there must be a handler procedure, to which the 
// following parameters are passed.
// 
//  Restriction - Structure - with the following properties:
//    * Text - String - access restriction for users.
//                                            If the string is blank, access is granted.
//    * TextForExternalUsers - String - access restriction for external users.
//                                            If the string is blank, access denied.
//    * ByOwnerWithoutAccessKeysRecord - Undefined - define automatically.
//                                        - Boolean - if False, always write access keys. If True, 
//                                            do not write access keys, but use owner access keys 
//                                            (the restriction must be by the owner object only).
//                                            
///   * ByOwnerWithoutAccessKeysRecordForExternalUsers - Undefined, Boolean - see
//                                            description of the previous parameter.
//
// The following is an example procedure for a manager module.
//
//// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
//Procedure OnFillAccessRestriction(Restriction) Export
//	
//	Restriction.Text =
//	"AllowReadEdit
//	|WHERE
//	|	ValueAllowed(Company)
//	|	And ValueAllowed(Counterparty)";
//	
//EndProcedure
//
// Parameters:
//  Lists - Map - lists with access restriction:
//             * Key - MetadataObject - a list with access restriction.
//             * Value - Boolean - True - a restriction text in the manager module.
//                                 - False - a restriction text in the overridable
//                module in the OnFillAccessRestriction procedure.
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
	
EndProcedure

// Fills descriptions of supplied access group profiles and overrides update parameters of profiles 
// and access groups.
//
// To generate the procedure code automatically, it is recommended that you use the developer tools 
// from the Access management subsystem.
//
// Parameters:
//  ProfilesDetails - Array - add access group profile descriptions (Structure).
//                        See the structure properties in AccessManagement. NewAccessGroupsProfileDetails.
//
//  UpdateParameters - Structure - contains the following properties:
//   * UpdateChangedProfiles - Boolean - the initial value is True.
//   * DenyProfilesChange - Boolean - the initial value is True.
//       If False, the supplied profiles can not only be viewed but also edited.
//   * UpdatingAccessGroups - Boolean - the default value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the default value is False.
//       If True, the value settings made by the administrator for the access kind, which was 
//       deleted from the profile, are also deleted from the access groups.
//
// Example:
//  ProfileDetails = AccessManagement.NewAccessGroupProfileDetails(),
//  ProfileDetails.Name = "Manager";
//  ProfileDetails.ID = "75fa0ecb-98aa-11df-b54f-e0cb4ed5f655";
//  ProfileDetails.Description = NStr("en = 'Sales representative'", Metadata.DefaultLanguage.LanguageCode);
//  ProfileDetails.Roles.Add("StartWebClient");
//  ProfileDetails.Roles.Add("StartThinClient");
//  ProfileDetails.Roles.Add("BasicSSLRights");
//  ProfileDetails.Roles.Add("Subsystem_Sales");
//  ProfileDetails.Roles.Add("AddEditCustomersDocuments");
//  ProfileDetails.Roles.Add("ViewReportPurchaseLedger");
//  ProfilesDetails.Add(ProfileDetails);
//
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, UpdateParameters) Export
	
	
	
EndProcedure

// Fills in non-standard access right dependencies of the subordinate object on the main object. For 
// example, access right dependencies of the PerformerTask task on the Job business process.
//
// Access right dependencies are used in the standard access restriction template for Object access kind.
// 1. By default, when reading a subordinate object, the right to read a leading object is checked 
//    and if there are no restrictions to read the leading object.
//    
// 2. When adding, changing, or deleting a subordinate object, a right to edit a leading object is 
//    checked and whether there are no restrictions to edit the leading object.
//    
//
// Only one variation is allowed, compared to the standard one, that is in clause 2 checking the 
// right to edit the leading object can be replaced with checking the right to read the leading 
// object.
//
// Parameters:
//  RightsDependencies - ValueTable - with the following columns:
//   * LeadingTable     - String - for example, Metadata.BusinessProcesses.Job.FullName().
//   * SubordinateTable - String - for example, Metadata.Tasks.PerformerTask.FullName().
//
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	
	
EndProcedure

// Fills in description of available rights assigned to the objects of the specified types.
// 
// Parameters:
//  AvailableRights - ValueTable - a table with the following columns:
//   RightsOwner - String - a full name of the access value table.
//
//   Name          - String - a right ID, for example, FoldersChange. The RightsManagement right 
//                  must be defined for the "Access rights" common form for setting rights.
//                  RightsManagement is a right to change rights by the owner, checked upon opening 
//                  CommonForm.ObjectsRightsSettings.
//
//   Title - String - a right title, for example, in the ObjectsRightsSettings form:
//                  "Update.
//                  |folders".
//
//   Tooltip    - String - a tooltip of the right title. For example, "Add, change, and mark folders 
//                  for deletion".
//
//   InitialValue - Boolean - an initial value of right check box when adding a new row in the 
//                  "Access rights" form.
//
//   RequiredRights - String array - names of rights required by this right. For example, the 
//                  ChangeFiles right is required by the AddFiles right.
//
//   ReadInTables - String array - full names of tables, for which this right means the Read right.
//                  You can use the * character, which means "for all other tables". The Read right 
//                  can depend on the Read right only, that is why only * character makes sense
//                  (it is required for access restriction templates).
//
//   ChangeInTables - String array - full names of tables, for which this right means the Update right.
//                  You can use an asterisk ("*"), which means "for all other tables"
//                  (it is required for access restriction templates).
//
Procedure OnFillAvailableRightsForObjectsRightsSettings(AvailableRights) Export
	
EndProcedure

// Defines the user interface type used for access setup.
//
// Parameters:
//  SimplifiedInterface - Boolean - the initial value is False.
//
Procedure OnDefineAccessSettingInterface(SimplifiedInterface) Export
	
EndProcedure

// Fills in the usage of access kinds depending on functional options of the configuration, for 
// example, UseProductsAccessGroups.
//
// Parameters:
//  AccessKind    - String - an access kind name specified in the OnFillAccessKinds procedure.
//  Use - Boolean - the initial value is True.
// 
Procedure OnFillAccessKindUsage(AccessKind, Usage) Export
	
	
	
EndProcedure

// Allows to override the restriction specified in the metadata object manager module.
//
// Parameters:
//  List - MetadataObject - a list, for which restriction text return is required.
//                              Specify False for the list in the OnFillListsWithAccessRestriction 
//                              procedure, otherwise, a call will not be made.
//
//  Restriction - Structure - with the properties as for the procedures in manager modules. See the 
//                            properties in comments to the OnFillListsWithAccessRestriction procedure.
//
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	
	
EndProcedure

// Fills in the list of access kinds used to set metadata object right restrictions.
// If the list of access kinds is not filled, the Access rights report displays incorrect data.
//
// Only access kinds explicitly used in access restriction templates must be filled. Access kinds 
// used in access value sets can be obtained from the current state of the AccessValuesSets 
// information register.
//
//  To prepare the procedure content automatically, use the
// developer tools for the Access management subsystem.
//
// Parameters:
//  Details - String - a multiline string of the <Table>.<Right>.<AccessKind>[.Object table] format. 
//                 For example "Document.PurchaseInvoice.Read.Companies",
//                           "Document.PurchaseInvoice.Read.Counterparties",
//                           "Document.PurchaseInvoice.Change.Companies",
//                           "Document.PurchaseInvoice.Change.Counterparties",
//                           "Document.Emails.Read.Object.Document.Emails",
//                           "Document.Emails.Change.Object.Document.Emails",
//                           "Document.Files.Read.Object.Catalog.FilesFolders",
//                           "Document.Files.Read.Object.Document.Email",
//                           "Document.Files.Change.Object.Catalog.FilesFolders",
//                           "Document.Files.Change.Object.Document.Email".
//                 The Object access kind is predefined as a literal. This access kind is used in 
//                 access restriction templates as a reference to another object used for applying 
//                 restrictions to the current table item.
//                 When the Object access kind is set, set table types used for this access kind.
//                  That means to enumerate types corresponding to the field used in the access 
//                 restriction template together with the "Object" access kind.
//                  When listing types by the Object access kind,
//                 list only those field types that the InformationRegisters.AccessValuesSets.Object 
//                 field has, other types are excess.
// 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(Details) Export
	
	
	
EndProcedure

// Allows to overwrite dependent access value sets of other objects.
//
// Called from procedures
//  AccessManagementInternal.WriteAccessValuesSets,
//  AccessManagementInternal.WriteDependentAccessValuesSets.
//
// Parameters:
//  Ref - CatalogRef, DocumentRef, ... - a reference to the object, for which access value sets are 
//                 written.
//
//  RefsToDependentObjects - Array - an array of elements like CatalogRef, DocumentRef and so on.
//                 Contains references to objects with dependent access value sets.
//                 Initial value is a blank array.
//
Procedure OnChangeAccessValuesSets(Ref, RefsToDependentObjects) Export
	
	
	
EndProcedure

#EndRegion
