////////////////////////////////////////////////////////////////////////////////// 
//// EVENT HANDLERS
////

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DetermineEnabled(ThisObject);
	
	// StandardSubsystems.Properties
	//PropertyManagement.OnCreateAtServer(ThisObject, , "AdditionalAttributesGroup");
	// End StandardSubsystems.Properties
	
EndProcedure

//&AtServer
//Procedure OnReadAtServer(CurrentObject)
//	
//	// StandardSubsystems.Properties
//	PropertyManagement.OnReadAtServer(ThisObject, CurrentObject);
//	// End StandardSubsystems.Properties
//	
//EndProcedure
//	
//&AtServer
//Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
//	
//	// StandardSubsystems.Properties
//	PropertyManagement.BeforeWriteAtServer(ThisObject, CurrentObject);
//	// End StandardSubsystems.Properties
//	
//EndProcedure

&AtClient
Procedure KindOnChange(Element)
	DetermineEnabled(ThisForm);
EndProcedure

//&AtClient
//Procedure NotificationProcessing(EventName, Parameter, Source)
//	
//	// StandardSubsystems.Properties 
//	Если PropertyManagementClient.ProcessNofifications(ThisObject, EventName, Parameter) Тогда
//     	UpdateAdditionalAttributeItems();
// 	КонецЕсли;
// 	// End StandardSubsystems.Properties
//	
//EndProcedure

//&AtServer
//Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
//	
//	// StandardSubsystems.Properties
//	PropertyManagement.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
//	// End StandardSubsystems.Properties
//	
//EndProcedure

//////////////////////////////////////////////////////////////////////////////// 
// Form procedures and functions

// Sets the Enabled flag of items depending on what is being edited:
// product or service.
//
&AtClientAtServerNoContext
Procedure DetermineEnabled(Form)

	ProductAttributesEnabled = Form.Object.Kind = PredefinedValue("Enum.ProductKinds.Product");
	Form.Items.Barcode.Enabled = ProductAttributesEnabled;
	Form.Items.Vendor.Enabled = ProductAttributesEnabled;
	Form.Items.Sku.Enabled = ProductAttributesEnabled;

EndProcedure

//// StandardSubsystems.Properties

//&AtClient
//Процедура Attachable_EditPropertyContent()
//	
//	PropertyManagementClient.EditPropertyContent(ThisObject, Object.Ref);
//	
//КонецПроцедуры

//&AtServer
//Процедура UpdateAdditionalAttributeItems()
//	
//     PropertyManagement.UpdateAdditionalAttributeItems(ThisObject);
//	 
//КонецПроцедуры

//// End StandardSubsystems.Properties
