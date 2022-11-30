///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets details of predefined property sets.
//
// Parameters:
//  Sets - ValuesTree - with the following columns:
//     * Name           - String - a property set name. Generated from the full metadata object name 
//                       by replacing a period (".") by an underscore ("_").
//                       For example, Document_SalesOrder.
//     * ID - UUID - a predefined item reference ID.
//     * Used - Undefined, Boolean - indicates whether a property set is used.
//                       For example, you can use it to hide a set by functional options.
//                       Default value - Undefined, matches the True value.
//     * IsFolder     - Boolean - True if the property set is a folder.
//
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	
	
	
EndProcedure

// Gets descriptions of second-level property sets in different languages.
//
// Parameters:
//  Descriptions - Map - a set presentation in the passed language:
//     * Key     - String - a property set name. For example, Catalog_Partners_Common.
//     * Value - String - a set description for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["Catalog_Partners_Common"] = Nstr("ru='Common'; en='General';", LanguageCode);
//
Procedure OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode) Export
	
	
	
EndProcedure

// Fills object property sets. Usually required if there is more than one set.
//
// Parameters:
//  Object       - AnyRef      - a reference to an object with properties.
//               - ManagedForm - a form of the object, to which properties are attached.
//               - FormDataStructure - details of the object, to which properties are attached.
//
//  RefType - Type - a type of the property owner reference.
//
//  PropertySets - ValueTable - with columns:
//                    Set - CatalogRef.AdditionalAttributesAndInfoSets.
//                    CommonSet - Boolean - True if the property set contains properties common for 
//                     all objects.
//                    // Then, form item properties of the FormGroup type and the usual group kind
//                    // or page that is created if there are more than one set excluding
//                    // a blank set that describes properties of deleted attributes group.
//                    
//                    // If the value is Undefined, use the default value.
//                    
//                    // For any managed form group.
//                    Height - a number.
//                    Header - a string.
//                    Hint - a string.
//                    VerticalStretch - Boolean.
//                    HorizontalStretch - Boolean.
//                    ReadOnly - Boolean.
//                    TitleTextColor - a color.
//                    Width - a number.
//                    TitleFont - a font.
//                    
//                    // For usual group and page.
//                    Grouping - ChildFormItemsGroup.
//                    
//                    // For usual group.
//                    Representation - UsualGroupRepresentation.
//                    
//                    // For page.
//                    Picture - a picture.
//                    DisplayTitle - Boolean.
//
//  StandardProcessing - Boolean - initial value is True. Indicates whether to get the default set 
//                         when PropertiesSets.Count() is equal to zero.
//
//  AssignmentKey - Undefined - (initial value) - specifies to calculate the assignment key 
//                      automatically and add PurposeUseKey and WindowOptionsKey to form property 
//                      values to save form changes (settings, position, and size) separately for 
//                      different sets.
//                      
//                      For example, for each product kind - its own sets.
//
//                    - String - (not more than 32 characters) - use the specified assignment key to 
//                      add it to form property values.
//                      Blank string - do not change form key properties as they are set in the form 
//                      and already consider differences of sets.
//
//                    Addition has format "PropertySetKey<AssignmentKey>" to be able to update 
//                    <AssignmentKey> without re-adding.
//                    Upon automatic calculation, <AssignmentKey> contains reference ID hash of 
//                    ordered property sets.
//
Procedure FillObjectPropertiesSets(Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey) Export
	
	
	
EndProcedure

#EndRegion

