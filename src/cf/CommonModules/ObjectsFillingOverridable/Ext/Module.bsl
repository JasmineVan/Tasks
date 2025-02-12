﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Determines the list of configuration objects in whose manager modules this procedure is available
// AddFillingCommands that generates object filling commands.
// See the help for the AddFillingCommands procedure syntax.
//
// Parameters:
//   Objects - Array - metadata objects (MetadataObject type) with filling commands.
//
// Example:
//  Objects.Add(Metadata.Catalogs.Organizations);
//
Procedure OnDefineObjectsWithFIllingCommands(Objects) Export
	
EndProcedure

// Defines general filling commands.
//
// Parameters:
//   FillingCommands - ValueTable - generated commands to be shown in the submenu.
//     
//     Common settings:
//       * ID - String - a command ID.
//     
//     Appearance settings:
//       * Presentation - String   - command presentation in a form.
//       * Importance      - String   - a submenu group to display the command in.
//                                    The following values are acceptable: "Important", "Ordinary", and "SeeAlso".
//       * Order       - Number    - an order of placing the command in the submenu. It is used to 
//                                    set up a particular workplace.
//       * Picture      - Picture - a command picture.
//     
//     Visibility and availability settings:
//       * ParameterType - TypesDetails - types of objects that the command is intended for.
//       * VisibilityOnForms    - String - comma-separated names of forms on which the command is to be displayed.
//                                        Used when commands differ for various forms.
//       * FunctionalOptions - String - comma-separated  names of functional options that define the command visibility.
//       * VisibilityConditions    - Array - defines the command visibility depending on the context.
//                                        To register conditions, use procedure
//                                        AttachableCommands.AddCommandVisibilityCondition().
//                                        The conditions are combined by "And".
//       * ChangesSelectedObjects - Boolean - defines whether the command is available if a user is 
//                                        not authorized to change the object. If True, the button will be unavailable.
//                                        Optional. Default value is True.
//     
//     Execution process settings:
//       * MultipleChoice - Boolean, Undefined - if True, then the command supports multiple choice.
//             In this case, the parameter is passed via a list.
//             Optional. Default value is True.
//       * WriteMode - String - actions associated with object writing that are executed before the command handler.
//             ** "DoNotWrite"          - do not write the object and pass the full form in the 
//                                       handler parameters instead of references. In this mode, we 
//                                       recommend that you operate directly with a form that is passed in the structure of parameter 2 of the command handler.
//             ** "WriteNewOnly" - write only new objects.
//             ** "Write"            - write only new and modified objects.
//             ** "Post"             - post documents.
//             Before writing or posting the object, users are asked for confirmation.
//             Optional. Default value is "Write".
//       * FilesOperationsRequired - Boolean - if True, in the web client, users are prompted to 
//             install the file system extension.
//             Optional. Default value is False.
//     
//     Handler settings:
//       * Manager - String - an object responsible for executing the command.
//       * FormName - String - name of the form to be retrieved for the command execution.
//             If Handler is not specified, the "Open" form method is called.
//       * FormParameters - Undefined, FixedStructure - optional. Form parameters specified in FormName.
//       * Handler - String - details of the procedure that handles the main action of the command.
//             Format "<CommonModuleName>.<ProcedureName>" is used when the procedure is in a common module.
//             Format "<ProcedureName>" is used in the following cases:
//               - if FormName is filled, a client procedure is expected in the  specified form module.
//               - if FormName is not filled, a server procedure is expected in the manager module.
//       * AdditionalParameters - FixedStructure - optional. Parameters of the handler specified in Handler.
//   
//   Parameters - Structure - info about execution context.
//       * FormName - String - full name of the form.
//   
//   StandardProcessing - Boolean - if False, the "AddFillingCommands" event of the object manager 
//                                   is not called.
//
Procedure BeforeAddFillCommands(FillingCommands, Parameters, StandardProcessing) Export
	
EndProcedure

#EndRegion
