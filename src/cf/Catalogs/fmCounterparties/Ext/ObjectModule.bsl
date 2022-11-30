////////////////////////////////////////////////////////////////////////////////
// OBJECT EVENT HANDLERS

////////////////////////////////////////////////////////////////////////////////
// The "Fill Checking" event handler
Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	// If this is a folder,
	If IsFolder Then
		// further checks do not make sence
		Return;
	EndIf;

	// If the field "Street" is filled
	If Not IsBlankString(Street) Then

		// Then the Country, City, and House fields must be filled.
		CheckedAttributes.Add("Country");
		CheckedAttributes.Add("City");
		CheckedAttributes.Add("House");

	EndIf;

EndProcedure
