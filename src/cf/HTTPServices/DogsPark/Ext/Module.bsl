//Start Huong
Function GetDogs(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter =CreateJsonWriter();
		//Y
	Code = Request.QueryOptions.Get("Code");
	
	//WriteJSON(JSONWriter, StructureResult);
	JSONWriter.WriteStartObject();
	GetDogData(JSONWriter,Code);
	//result = JSONWriter.Close();
	JSONWriter.WriteEndObject();
	
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	
	Return Response;
EndFunction

Procedure GetDogData(Val JSONWriter,Code = Undefined)
	
	
	JSONWriter.WritePropertyName("Dog");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Dogs.Code AS Code,
		|	Dogs.Description AS Description,
		|	Dogs.DogBreed AS DogBreed,
		|	Dogs.Gender AS Gender,
		|	Dogs.DateOfBirth AS DateOfBirth,
		|	Dogs.Picture AS Picture,
		|	Dogs.Weight AS Weight,
		|	Dogs.Sterilized AS Sterilized,
		|	Dogs.Age AS Age,
		|	Dogs.Microchip AS Microchip,
		|	Dogs.Owner.Password AS Password,
		|	Dogs.FurColor AS FurColor,
		|	Dogs.Species AS Species,
		|	Dogs.Owner.Code AS OwnerCode,
		|	Dogs.Owner.Description AS OwnerDescription,
		|	Dogs.Ref AS Ref
		|FROM
		|	Catalog.Dogs AS Dogs
		|WHERE
		|	Dogs.Code = &Code";
	
	Query.SetParameter("Code", Code);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If selection.Count() = 0 Then
		JSONWriter.WriteStartObject();
		//Existed of customer
		JSONWriter.WritePropertyName("Existed");
		JSONWriter.WriteValue(False);	
		JSONWriter.WriteEndObject();
	EndIf;
	
	While Selection.Next() Do
		
		JSONWriter.WriteStartObject();
		//DogName
		JSONWriter.WritePropertyName("DogName");
		JSONWriter.WriteValue(String(Selection.Description));
		//DogCode
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Code));
		//DogBreed
		JSONWriter.WritePropertyName("DogBreed");
		JSONWriter.WriteValue(String(Selection.DogBreed));
		//DogGender
		JSONWriter.WritePropertyName("Gender");
		JSONWriter.WriteValue(String(Selection.Gender));
		//DateOfBirth
		JSONWriter.WritePropertyName("DateOfBirth");
		DateOfBirth = Format(Selection.DateOfBirth,"DF=dd.MM.yyyy");
		JSONWriter.WriteValue(String(DateOfBirth));
		//Picture
		JSONWriter.WritePropertyName("Picture");
		Picture = Base64String(Selection.Picture.Get());
		JSONWriter.WriteValue(Picture);
		//Weight
		JSONWriter.WritePropertyName("Weight");
		JSONWriter.WriteValue(String(Selection.Weight));
		//Sterilized
		JSONWriter.WritePropertyName("Sterilized");
		JSONWriter.WriteValue(String(Selection.Sterilized));
		//Age
		JSONWriter.WritePropertyName("Age");
		JSONWriter.WriteValue(String(Selection.Age));
		//Microchip
		JSONWriter.WritePropertyName("Microchip");
		JSONWriter.WriteValue(String(Selection.Microchip));
		//Furcolor
		JSONWriter.WritePropertyName("Furcolor");
		JSONWriter.WriteValue(String(Selection.FurColor));
		//Species
		JSONWriter.WritePropertyName("Species");
		JSONWriter.WriteValue(String(Selection.Species));
		//Dog Owner
		JSONWriter.WritePropertyName("Owner");
		JSONWriter.WriteStartArray();
		JSONWriter.WriteStartObject();
		JSONWriter.WritePropertyName("OwnerCode");
		JSONWriter.WriteValue(String(Selection.OwnerCode));
		
		JSONWriter.WritePropertyName("OwnerDescription");
		JSONWriter.WriteValue(String(Selection.OwnerDescription));
		JSONWriter.WriteEndObject();
		JSONWriter.WriteEndArray();
		//Last Checkin: TrackingData
		TrackingData = TrackingData(Selection.Ref);
		JSONWriter.WritePropertyName("Tracking");
		JSONWriter.WriteStartArray();
		
		JSONWriter.WriteStartObject();
		//YenNN
		//If Not IsBlankString(TrackingData) Then
			JSONWriter.WritePropertyName("CheckIn");
			JSONWriter.WriteValue(String(TrackingData.TimeCheckIn));
			
			JSONWriter.WritePropertyName("CheckInStatus");
			JSONWriter.WriteValue(String(TrackingData.CheckIn));
			
			JSONWriter.WritePropertyName("CheckOutStatus");
			JSONWriter.WriteValue(String(TrackingData.CheckOut));
			
			JSONWriter.WritePropertyName("Zone");
			JSONWriter.WriteValue(String(TrackingData.Zone));

		//EndIf;			
		JSONWriter.WriteEndObject();
		
		JSONWriter.WriteEndArray();
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();

EndProcedure

&AtServer
Function TrackingData(Dog) 
	  	
	Query = New Query;
		
	Query.Text = 
		"SELECT TOP 1
		|	TrackingHistorySliceLast.CheckIn AS CheckIn,
		|	TrackingHistorySliceLast.Dog AS Dog,
		|	TrackingHistorySliceLast.CheckOut AS CheckOut,
		|	TrackingHistorySliceLast.Zone AS Zone
		|FROM
		|	InformationRegister.TrackingHistory.SliceLast AS TrackingHistorySliceLast
		|WHERE
		|	TrackingHistorySliceLast.Dog = &Dog
		|
		|ORDER BY
		|	CheckIn DESC";
	
	Query.SetParameter("Dog", Dog);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Data = New Structure;
	CheckIn = True;
	CheckOut=False;
	TimeCheckIn=Undefined;
	Zone ="";
	//Date = Date("01.01.0001 0:00:00");

	
	While Selection.Next() Do
		If (ValueIsFilled(Selection.CheckOut))=False Then
			Zone = Selection.Zone;
		    CheckIn = False;
			CheckOut = True
		EndIf; 
			Time = String(Selection.CheckIn);
	EndDo;

	Data.Insert("CheckIn",CheckIn);
	Data.Insert("CheckOut",CheckOut);
	Data.Insert("TimeCheckIn",Time);
	Data.Insert("Zone",Zone);
	Return Data;
EndFunction

Procedure DogBreedsData(JSONWriter)
	JSONWriter.WritePropertyName("ListDogBreed");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Dogs.DogBreed AS DogBreed
	|FROM
	|	Catalog.Dogs AS Dogs";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//DogBreed
		JSONWriter.WritePropertyName("DogBreed");
		JSONWriter.WriteValue(trimall(selection.DogBreed));
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();
	
EndProcedure

Function GETDogBreed(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	
	JSONWriter.WriteStartObject();
	DogBreedsData(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

Function GETDoglist(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();	
	CodeOwner = Request.QueryOptions.Get("CodeOwner");
	
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("Dog");
	DogsData(JSONWriter,CodeOwner);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

Procedure DogsData(JSONWriter,CodeOwner)
	CodeDog =0;
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Dogs.Ref AS Ref
	|FROM
	|	Catalog.Dogs AS Dogs
	|WHERE
	|	Dogs.Owner.Code = &CodeOwner";
	
	Query.SetParameter("CodeOwner",CodeOwner);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	//Yen
	While Selection.Next() Do
		CodeDog = Selection.Ref.Code;
		JSONWriter.WriteStartObject();
		//DogCode
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(CodeDog));
		//DogName
		JSONWriter.WritePropertyName("DogName");
		JSONWriter.WriteValue(Selection.Ref.Description);
		//Owner
		JSONWriter.WritePropertyName("Owner");
		JSONWriter.WriteValue(String(Selection.Ref.Owner));
		//DogBreed
		JSONWriter.WritePropertyName("DogBreed");
		JSONWriter.WriteValue(String(Selection.Ref.DogBreed));
		//DogGender
		JSONWriter.WritePropertyName("Gender");
		JSONWriter.WriteValue(String(Selection.Ref.Gender));
		//DateOfBirth
		JSONWriter.WritePropertyName("DateOfBirth");
		DateOfBirth = Format(Selection.Ref.DateOfBirth,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(DateOfBirth));
		//Picture
		JSONWriter.WritePropertyName("Picture");
		If IsBlankString(Selection.Ref.Picture.Get()) Then
			Picture = "";
		Else
			Picture = Base64String(Selection.Ref.Picture.Get());
		EndIf;
		JSONWriter.WriteValue(Picture);
		//Weight
		JSONWriter.WritePropertyName("Weight");
		JSONWriter.WriteValue(String(Selection.Ref.Weight));
		//Sterilized
		JSONWriter.WritePropertyName("Sterilized");
		JSONWriter.WriteValue(String(Selection.Ref.Sterilized));
		//Age
		JSONWriter.WritePropertyName("Age");
		JSONWriter.WriteValue(String(Selection.Ref.Age));
		//Microchip
		JSONWriter.WritePropertyName("Microchip");
		JSONWriter.WriteValue(String(Selection.Ref.Microchip));
		//Furcolor
		JSONWriter.WritePropertyName("Furcolor");
		JSONWriter.WriteValue(String(Selection.Ref.Furcolor));
		//Species
		JSONWriter.WritePropertyName("Species");
		JSONWriter.WriteValue(String(Selection.Ref.Species));
				
		//Tabular
		//JSONWriter.WritePropertyName("OwnerSecondary");
		//JSONWriter.WriteStartArray();
		//For Each Line In Selection.Ref.OwnerSecondary Do
		//	JSONWriter.WriteStartObject();
		//	//Owner
		//	JSONWriter.WritePropertyName("Owner");
		//	JSONWriter.WriteValue(String(Line.Owner));
		//	//Phone
		//	JSONWriter.WritePropertyName("PhoneNumber");
		//	JSONWriter.WriteValue(String(Line.Phone));
		//	//Main
		//	JSONWriter.WritePropertyName("Main");
		//	JSONWriter.WriteValue(String(Line.Main));
		//	
		//	JSONWriter.WriteEndObject();
		//EndDo;
		//JSONWriter.WriteEndArray();
		
		//HealtStatus[]
		JSONWriter.WritePropertyName("HealthStatus");
		HealthStatusData(JSONWriter,CodeDog);
		//InjectionHistory[]
		JSONWriter.WritePropertyName("InjectionHistory");
		InjectionHistory(JSONWriter,CodeDog);
		//LouseDogStreatment
		JSONWriter.WritePropertyName("LouseDogStreatment");
		LouseDogTreatment(JSONWriter,CodeDog);
		
		
		JSONWriter.WriteEndObject();
	EndDo;
	//Y	
	JSONWriter.WriteEndArray();
EndProcedure
//End Huong

//Start Yen
Function GetOwner(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	
	PhoneNumber = Request.QueryOptions.Get("phonenumber");
	Password = Request.QueryOptions.Get("password");
	
	CheckPhoneNumber = Catalogs.DogOwners.FindByCode(PhoneNumber);
	
	
	If CheckPhoneNumber=Catalogs.DogOwners.EmptyRef() Then	
		Response.SetBodyFromString("NotExisted",TextEncoding.UTF8);
	Else
		If Not CheckPhoneNumber.Password = Password Then
			Response.SetBodyFromString("WrongPassword",TextEncoding.UTF8);	
		Else
			JSONWriter.WriteStartObject();
			GetDataOwner(JSONWriter,PhoneNumber,Password);
			JSONWriter.WriteEndObject();
			
			Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
			Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);	
		EndIf; 
	EndIf; 

	Return Response;

EndFunction

Procedure GetDataOwner(JSONWriter,PhoneNumber,Password)
	//Dont edit
	JSONWriter.WritePropertyName("Owner");
	JSONWriter.WriteStartArray();
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DogOwners.Ref AS Ref
		|FROM
		|	Catalog.DogOwners AS DogOwners
		|WHERE
		|	DogOwners.Code = &PhoneNumber
		|	AND DogOwners.Password = &Password";
	
	Query.SetParameter("PhoneNumber", PhoneNumber);
	Query.SetParameter("Password",Password);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		JSONWriter.WritePropertyName("Password");
		JSONWriter.WriteValue(String(Selection.Ref.Password));

		
		JSONWriter.WritePropertyName("FullName");
		JSONWriter.WriteValue(String(Selection.Ref.Description));
		
		JSONWriter.WritePropertyName("PhoneNumber");
		JSONWriter.WriteValue(String(Selection.Ref.Code));
		
		JSONWriter.WritePropertyName("Address");
		JSONWriter.WriteValue(String(Selection.Ref.Address));

		JSONWriter.WritePropertyName("Gender");
		JSONWriter.WriteValue(String(Selection.Ref.Gender));

		JSONWriter.WritePropertyName("DateOfBirth");
		DateOfBirth = Format(Selection.Ref.DateOfBirth,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(DateOfBirth));
		
		//JSONWriter.WritePropertyName("Tabular");
		//JSONWriter.WriteStartArray();
		//For Each Line In Selection.Ref.RelevantContacts Do
		//JSONWriter.WriteStartObject();
		//
		//JSONWriter.WritePropertyName("FullName");
		//JSONWriter.WriteValue(String(Line.FullName));
		//
		//JSONWriter.WritePropertyName("PhoneNumber");
		//JSONWriter.WriteValue(String(Line.PhoneNumber));
		//
		//JSONWriter.WritePropertyName("RelationshipWithDogOwner");
		//JSONWriter.WriteValue(String(Line.RelationshipWithDogOwner));

		//JSONWriter.WriteEndObject();
		//EndDo; 
		//

		//JSONWriter.WriteEndArray();


		
		JSONWriter.WriteEndObject();

	EndDo;
	   JSONWriter.WriteEndArray();

   EndProcedure
   
//End Yen
//Start Huong
Function OwnerPUTOwner(Request)
	Response = New HTTPServiceResponse(200);
	Result = "OK";
		
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	OwnerPhoneNumer = Request.QueryOptions.Get("phonenumber");
	OwnerObject = Catalogs.DogOwners.FindByCode(OwnerPhoneNumer).GetObject();
	If TypeOf(StructureResult) = Type("Structure") Then 
		For Each curElement In structureResult Do
			If curElement.Key = "newname" Then
				OwnerObject.Description = curElement.Value;
			ElsIf curElement.Key = "newaddress" Then
				OwnerObject.Address = curElement.Value;
			ElsIf curElement.Key = "newpassword" Then
				OwnerObject.Password = curElement.Value;
			ElsIf curElement.Key = "newphonenumber" Then
				OwnerObject.PhoneNumber = curElement.Value;
			ElsIf curElement.Key = "newgender" Then
				If curElement.Value = "Male" then
					OwnerObject.Gender = enums.Gender.Male;
				Elsif curElement.Value = "Memale" then
					OwnerObject.Gender = enums.Gender.Female;
				Elsif curElement.Value = "Other" then
					OwnerObject.Gender = enums.Gender.Other;
				EndIf;
			ElsIf curElement.Key = "newdateofbirth" Then
				OwnerObject.DateOfBirth = date(curElement.Value);
			Endif;
		EndDo; 
	EndIf;
	 			
	OwnerObject.Write(); 
	
	Response.SetBodyFromString(result,TextEncoding.UTF8);
	Return Response;
EndFunction

//ThuongTV Modified 29092022
Function PostOwner(Request)
	Response = New HTTPServiceResponse(200);
	
	StringResult = Request.GetBodyAsString();	
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If TypeOf(StructureResult) = Type("Structure") Then
		Password = Undefined;
		For Each curElement In structureResult Do
			If curElement.Key = "phonenumber" Then				
				PhoneNumber = curElement.value; 	
			ElsIf curElement.Key = "fullname" Then
				FullName = curElement.value;	
			ElsIf curElement.Key = "gender" Then
				If curElement.Value = "Male" then
					Gender = enums.Gender.Male;
				Elsif curElement.Value = "Female" then
					Gender = enums.Gender.Female;
				Else
					Gender = enums.Gender.Other;
				EndIf;
			ElsIf curElement.Key = "address" Then
				Address = curElement.value;
			ElsIf curElement.Key = "dateofbirth" Then
			DateOfBirth=curElement.value;
			ElsIf curElement.Key = "CreatedBy" Then
				User = InfoBaseUsers.FindByName(curElement.Value);
				CreatedBy = Catalogs.DogOwners.findbyAttribute("Code",User.UUID);
			ElsIf curElement.Key = "password" Then
				Password = curElement.value;
			Endif;
		EndDo; 
		
		If Catalogs.DogOwners.FindByCode(PhoneNumber).IsEmpty() Then
			NewOwner = Catalogs.DogOwners.CreateItem();
			NewOwner.Code = PhoneNumber;
			NewOwner.Description = FullName;             
			NewOwner.Address = Address;
			NewOwner.DateOfBirth = DateOfBirth;
			NewOwner.Gender = Gender; 
			If Password <> Undefined Then
				NewOwner.Password = Password; 		
			EndIf;
			NewOwner.Write();        
			Response.SetBodyFromString("Success", TextEncoding.UTF8);
		Else
			Response.SetBodyFromString("AlreadyExistedInDatabase", TextEncoding.UTF8);
		EndIf; 
	EndIf;
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Return Response;
EndFunction
//End Huong

//Y
Function CreateJsonWriter()
	JSONWriter = New JSONWriter;
	JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.Auto, Chars.Tab);
	JSONWriter.SetString(JSONWriterSettings);
	Return JSONWriter
EndFunction

Function GetDiseases(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	JSONWriter.WriteStartObject();
	DiseasesData(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);

	Return Response;
EndFunction

Procedure DiseasesData(JSONWriter)
	JSONWriter.WritePropertyName("ListDiseases");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CoreDiseases.Code AS Code,
	|	CoreDiseases.Description AS Description,
	|	CoreDiseases.Predefined AS Predefined,
	|	CoreDiseases.Presentation AS Presentation
	|FROM
	|	Catalog.CoreDiseases AS CoreDiseases";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(selection.Code));
		//Des
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(selection.Description));
		//Predefined
		JSONWriter.WritePropertyName("Predefined");
		JSONWriter.WriteValue(String(selection.Predefined));
		//Presentation
		JSONWriter.WritePropertyName("Presentation");
		JSONWriter.WriteValue(String(selection.Presentation));
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();	
EndProcedure

Function GetProduct(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	JSONWriter.WriteStartObject();
	ProductData(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	
	Return Response;
EndFunction

Procedure ProductData(JSONWriter)
	JSONWriter.WritePropertyName("List Product");
	JSONWriter.WriteStartArray();
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Products.Code AS Code,
		|	Products.Description AS Description,
		|	Products.Presentation AS Presentation
		|FROM
		|	Catalog.Products AS Products";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Code));
		//Des
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(Selection.Description));
		//Presentation
		JSONWriter.WritePropertyName("Presentation");
		JSONWriter.WriteValue(String(Selection.Presentation));
		
		JSONWriter.WriteEndObject();
		
	EndDo;
	JSONWriter.WriteEndArray();



EndProcedure

Function GetVaccines(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	JSONWriter.WriteStartObject();
	VaccinesData(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	
	Return Response;
EndFunction

Procedure VaccinesData(JSONWriter)
	 JSONWriter.WritePropertyName("ListVaccines");
	JSONWriter.WriteStartArray();

	 	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Vaccines.Ref AS Ref
		|FROM
		|	Catalog.Vaccines AS Vaccines";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
	    JSONWriter.WriteStartObject();
		//Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Ref.Code));
		//Des
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(Selection.Ref.Description));
		//Presentation
		JSONWriter.WritePropertyName("Disease");
		JSONWriter.WriteStartArray();
		For Each Line In Selection.Ref.DiseaseName Do
			JSONWriter.WriteStartObject();
			JSONWriter.WritePropertyName("DiseaseName");
			JSONWriter.WriteValue(String(Line.DiseaseName));
			JSONWriter.WriteEndObject();
		EndDo;
		JSONWriter.WriteEndArray();
		
				
		JSONWriter.WriteEndObject();

	EndDo;
	   JSONWriter.WriteEndArray();
	
	
EndProcedure

Function GetVeterinarians(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	JSONWriter.WriteStartObject();
	VeterinariansData(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);

	Return Response;
EndFunction

Procedure VeterinariansData(JSONWriter)
	JSONWriter.WritePropertyName("ListVeterinarians");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Veterinarians.Code AS Code,
	|	Veterinarians.Description AS Description,
	|	Veterinarians.PhoneNumber AS PhoneNumber,
	|	Veterinarians.DateOfBirth AS DateOfBirth,
	|	Veterinarians.Gender AS Gender,
	|	Veterinarians.Address AS Address
	|FROM
	|	Catalog.Veterinarians AS Veterinarians";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Code));
		//Des
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(Selection.Description));
		//PhoneNumber
		JSONWriter.WritePropertyName("PhoneNumber");
		JSONWriter.WriteValue(String(Selection.PhoneNumber));
		//DateOfBirth
		JSONWriter.WritePropertyName("DateOfBirth");
		JSONWriter.WriteValue(String(Selection.DateOfBirth));
		//Gender
		JSONWriter.WritePropertyName("Gender");
		JSONWriter.WriteValue(String(Selection.Gender));
		//Address
		JSONWriter.WritePropertyName("Address");
		JSONWriter.WriteValue(String(Selection.Address));
		
		JSONWriter.WriteEndObject();
		
	EndDo;
	JSONWriter.WriteEndArray();
EndProcedure

Function GetHealthStatus(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter =CreateJsonWriter();
	CodeDog = Request.QueryOptions.Get("CodeDog");
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("HealthStatus");
	HealthStatusData(JSONWriter,CodeDog);
	JSONWriter.WriteEndObject();
	
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	
	
	Return Response;
EndFunction

Procedure HealthStatusData(JSONWriter,CodeDog)
	
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text =  "SELECT
	              |	HealthStatuses.Dog AS Dog,
	              |	HealthStatuses.Owner AS Owner,
	              |	HealthStatuses.Disease AS Disease,
	              |	HealthStatuses.Weight AS Weight,
	              |	HealthStatuses.Veterinarian AS Veterinarian,
	              |	HealthStatuses.StartTime AS StartTime,
	              |	HealthStatuses.EndTime AS EndTime,
	              |	HealthStatuses.IsCured AS IsCured,
	              |	HealthStatuses.Purpose AS Purpose
	              |FROM
	              |	InformationRegister.HealthStatuses AS HealthStatuses
	              |WHERE
	              |	HealthStatuses.Dog.Code = &Code";
	
	
	Query.SetParameter("Code", CodeDog);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//StartTime
		JSONWriter.WritePropertyName("StartTime");
		StartTime =  Format(Selection.StartTime,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(StartTime));
		//Code
		JSONWriter.WritePropertyName("Dog");
		JSONWriter.WriteValue(String(Selection.Dog));
		//Owner
		JSONWriter.WritePropertyName("Owner");
		JSONWriter.WriteValue(String(Selection.Owner));
		//HealthStatus
		JSONWriter.WritePropertyName("Disease");
		JSONWriter.WriteValue(String(Selection.Disease));
		//EndTime
		JSONWriter.WritePropertyName("EndTime");
		EndTime = Format(Selection.EndTime,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(EndTime));
		//Veterinarian
		JSONWriter.WritePropertyName("Veterinarian");
		JSONWriter.WriteValue(String(Selection.Veterinarian));
		//Weight
		JSONWriter.WritePropertyName("Weight");
		JSONWriter.WriteValue(String(Selection.Weight));
		//Weight
		JSONWriter.WritePropertyName("Purpose");
		JSONWriter.WriteValue(String(Selection.Purpose));
		//Weight
		JSONWriter.WritePropertyName("IsCured");
		JSONWriter.WriteValue(String(Selection.IsCured));

		
		JSONWriter.WriteEndObject();
		
	EndDo;
	    JSONWriter.WriteEndArray();
EndProcedure

Function GetInjectionHistory(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter =CreateJsonWriter();
	CodeDog = Request.QueryOptions.Get("CodeDog");
	
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("InjectionHistory");
	InjectionHistory(JSONWriter,CodeDog);
	JSONWriter.WriteEndObject();
	
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Return Response;
EndFunction

Procedure InjectionHistory(JSONWriter,CodeDog)
		JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InjectionHistory.Date AS Date,
	|	InjectionHistory.Dog AS Dog,
	|	InjectionHistory.Owner AS Owner,
	|	InjectionHistory.NextVaccination AS NextVaccination,
	|	InjectionHistory.Veterinarian AS Veterinarian,
	|	InjectionHistory.VaccineLabel AS VaccineLabel,
	|	InjectionHistory.Weight AS Weight,
	|	InjectionHistory.Disease AS Disease
	|FROM
	|	InformationRegister.InjectionHistory AS InjectionHistory
	|WHERE
	|	InjectionHistory.Dog.Code = &Code";
	
	Query.SetParameter("Code", CodeDog);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Date
		JSONWriter.WritePropertyName("Date");
		Date = Format(Selection.Date,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(Date));
		//Dog
		JSONWriter.WritePropertyName("Dog");
		JSONWriter.WriteValue(String(Selection.Dog));
		//Owner
		JSONWriter.WritePropertyName("Owner");
		JSONWriter.WriteValue(String(Selection.Owner));
		//NextVaccination
		JSONWriter.WritePropertyName("NextVaccination");
		NextVaccination = Format(Selection.NextVaccination,"DF=yyyyMMdd" );

		JSONWriter.WriteValue(String(NextVaccination));
		
		JSONWriter.WriteEndObject();

	EndDo;
	JSONWriter.WriteEndArray();
	
EndProcedure

Function GetLouseDogTreatment(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter =CreateJsonWriter();
	CodeDog = Request.QueryOptions.Get("CodeDog");
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("HealthStatus");
	LouseDogTreatment(JSONWriter,CodeDog);
	JSONWriter.WriteEndObject();
	
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	
	Return Response;
EndFunction 

Procedure LouseDogTreatment(JSONWriter,CodeDog)
		JSONWriter.WriteStartArray();
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LouseDogTreatment.Dog AS Dog,
	|	LouseDogTreatment.Date AS Date,
	|	LouseDogTreatment.Product AS Product,
	|	LouseDogTreatment.Quantity AS Quantity,
	|	LouseDogTreatment.Veterinarian AS Veterinarian
	|FROM
	|	InformationRegister.LouseDogTreatment AS LouseDogTreatment
	|WHERE
	|	LouseDogTreatment.Dog.Code = &Code";
	
	Query.SetParameter("Code", CodeDog);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Date
		JSONWriter.WritePropertyName("Date");
		 Date = Format(Selection.Date,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(Date));
		//Dog
		JSONWriter.WritePropertyName("Dog");
		JSONWriter.WriteValue(String(Selection.Dog));
		//Product
		JSONWriter.WritePropertyName("Product");
		JSONWriter.WriteValue(String(Selection.Product));
		//Quantity
		JSONWriter.WritePropertyName("Quantity");
		JSONWriter.WriteValue(String(Selection.Quantity));
		//Veterinarian
		JSONWriter.WritePropertyName("Veterinarian");
		JSONWriter.WriteValue(String(Selection.Veterinarian));
		
		JSONWriter.WriteEndObject();
		
	EndDo;
	JSONWriter.WriteEndArray()
	
EndProcedure

Function PUTDog(Request)
	Response = New HTTPServiceResponse(200);
	Result = "OK";
		
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	DogCode = Request.QueryOptions.Get("dogcode");
	OwnerObject = Catalogs.Dogs.FindByCode(DogCode).GetObject();
	If TypeOf(StructureResult) = Type("Structure") Then
		For Each curElement In structureResult Do
			If curElement.Key = "newdogname" Then
				OwnerObject.Description = curElement.Value;
			ElsIf curElement.Key = "newdogbreed" Then
				OwnerObject.DogBreed = Catalogs.DogBreeds.FindByDescription(curElement.Value);
			ElsIf curElement.Key = "newweight" Then
				OwnerObject.Weight = curElement.Value;
			ElsIf curElement.Key = "newmicrochip" Then
				OwnerObject.Microchip = curElement.Value;
			ElsIf curElement.Key = "newdoggender" Then
				If curElement.Value = "male" then
					OwnerObject.Gender = enums.DogGender.Male;
				Elsif curElement.Value = "female" then
					OwnerObject.Gender = enums.GenDogGenderder.Female;
				Elsif curElement.Value = "other" then
					OwnerObject.Gender = enums.DogGender.Other;
				EndIf;
			ElsIf curElement.Key = "newdateofbirth" Then
				OwnerObject.DateOfBirth = date(curElement.Value);
			ElsIf curElement.Key = "newstirilized" Then
				If curElement.Value = "true" then 
					OwnerObject.Sterilized = True;
				Elsif curElement.Value = "false" then 
					OwnerObject.Sterilized = False;
				Endif;
			ElsIf curElement.Key = "newadditionalinfo" Then
				OwnerObject.AdditionalInformation = curElement.Value;
			ElsIf curElement.Key = "newfurcolor" Then
				OwnerObject.FurColor = Catalogs.FurColors.FindByDescription(curElement.Value);
			ElsIf curElement.Key = "newspecies" Then
				OwnerObject.Species = Catalogs.Species.FindByDescription(curElement.Value);
			Endif;
		EndDo; 
	EndIf;
	 			
	OwnerObject.Write(); 
	
	Response.SetBodyFromString(result,TextEncoding.UTF8);
	Return Response;

EndFunction

Function POSTDog(Request)
	Response = New HTTPServiceResponse(200);
	Result = "OK";
	JSONWriter = New JSONWriter;
	JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.Auto, Chars.Tab);
	JSONWriter.SetString(JSONWriterSettings);
	JSONWriter.WriteStartObject();
	
	JSONWriter.WritePropertyName("newdog"); 
	
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	OwnerRef = Catalogs.DogOwners.FindByCode(Request.QueryOptions.Get("ownercode"));
	//If NOT OwnerRef.IsEmpty() then
		JSONWriter.WriteStartObject();
		If TypeOf(StructureResult) = Type("Structure") Then
			//Newdog = Catalogs.Dogs.CreateItem();
			//Newdog.Owner = OwnerRef.Ref;
			For Each curElement In structureResult Do
				If curElement.Key = "dogname" Then				
					Description = curElement.value; 	
				ElsIf curElement.Key = "dogbreed" Then
					DogBreed = Catalogs.DogBreeds.FindByDescription(curElement.Value);
				ElsIf curElement.Key = "weight" Then
					Weight = curElement.Value;
				ElsIf curElement.Key = "microchip" Then
					Microchip = curElement.Value;
				ElsIf curElement.Key = "doggender" Then
					If curElement.Value = "dog" then
						Gender = enums.DogGender.Dog;
					Elsif curElement.Value = "bitch" then
						Gender = enums.DogGender.Bitch;
					EndIf;
				ElsIf curElement.Key = "dateofbirth" Then
					DateOfBirth = date(curElement.Value);
				ElsIf curElement.Key = "stirilized" Then
					If curElement.Value = "true" then 
						Sterilized = True;
					Elsif curElement.Value = "false" then 
						Sterilized = False;
					Endif;
				ElsIf curElement.Key = "additionalinfo" Then
					AdditionalInformation = curElement.Value;
				ElsIf curElement.Key = "furcolor" Then
					furcolor = Catalogs.FurColors.FindByDescription(curElement.Value);
				ElsIf curElement.Key = "species" Then
					species = Catalogs.Species.FindByDescription(curElement.Value);
				Endif;
			EndDo; 
			//Newdog.Write();
			If NOT OwnerRef.IsEmpty() then
				NewDog = Catalogs.Dogs.CreateItem();
				NewDog.Description = Description;
				NewDog.DogBreed = DogBreed;             
				NewDog.Weight = Weight;
				NewDog.Microchip = Microchip;
				NewDog.DateOfBirth = DateofBirth;
				NewDog.Gender = Gender; 
				NewDog.Sterilized = Sterilized;
				NewDog.FurColor = furcolor;
				NewDog.Species = species;
				NewDog.AdditionalInformation = AdditionalInformation;
				NewDog.Owner = OwnerRef;
				NewDog.Write();        
				JSONWriter.WritePropertyName("Status");
				JSONWriter.WriteValue(True);
			Else
				JSONWriter.WritePropertyName("Status");
				JSONWriter.WriteValue(False);	
			EndIf;
		EndIf;
		//JSONWriter.WriteEndObject();
	//Endif;
	JSONWriter.WriteEndObject();
	JSONWriter.WriteEndObject();
	
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Return Response;
EndFunction

Function GetListData(Request)
	Response = New HTTPServiceResponse(200);
	
	JSONWriter = CreateJsonWriter();
	
	PhoneNumber = Request.QueryOptions.Get("phonenumber");
		
	
	CheckPhoneNumber = Catalogs.DogOwners.FindByCode(PhoneNumber);
	
	
	If CheckPhoneNumber=Catalogs.DogOwners.EmptyRef() Then
		If CheckPhoneNumber=Catalogs.DogOwners.EmptyRef()Then
			Response.SetBodyFromString("NotExisted",TextEncoding.UTF8);
		EndIf;
	Else
		JSONWriter.WriteStartObject();
		AllData(JSONWriter,PhoneNumber);
		JSONWriter.WriteEndObject();
		
		Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
		Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
		
	EndIf; 
	
	
	Return Response;
EndFunction

Procedure AllData(JSONWriter,Phonenumber)
	CodeOwner =0;
	
	JSONWriter.WritePropertyName("Metadata");
	JSONWriter.WriteStartArray();
	JSONWriter.WriteStartObject();

	
	JSONWriter.WritePropertyName("Customer");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DogOwners.Ref AS Ref
	|FROM
	|	Catalog.DogOwners AS DogOwners
	|WHERE
	|	DogOwners.Code = &PhoneNumber";
	
	Query.SetParameter("PhoneNumber", PhoneNumber);	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		CodeOwner = Selection.Ref.Code;
		JSONWriter.WriteStartObject();
		
		JSONWriter.WritePropertyName("FullName");
		JSONWriter.WriteValue(String(Selection.Ref.Description));
		
		JSONWriter.WritePropertyName("PhoneNumber");
		JSONWriter.WriteValue(String(Selection.Ref.Code));
		
		JSONWriter.WritePropertyName("Address");
		JSONWriter.WriteValue(String(Selection.Ref.Address));
		
		JSONWriter.WritePropertyName("Gender");
		JSONWriter.WriteValue(String(Selection.Ref.Gender));
		
		JSONWriter.WritePropertyName("Password");
		JSONWriter.WriteValue(String(Selection.Ref.Password));
		
		JSONWriter.WritePropertyName("DateOfBirth");
		DateOfBirth = Format(Selection.Ref.DateOfBirth,"DF=yyyyMMdd" );
		JSONWriter.WriteValue(String(DateOfBirth));
		
		
		//JSONWriter.WritePropertyName("Tabular");
		//JSONWriter.WriteStartArray();
		////For Each Line In Selection.Ref.RelevantContacts Do
		////	JSONWriter.WriteStartObject();
		////	
		////	JSONWriter.WritePropertyName("FullName");
		////	JSONWriter.WriteValue(String(Line.FullName));
		////	
		////	JSONWriter.WritePropertyName("PhoneNumber");
		////	JSONWriter.WriteValue(String(Line.PhoneNumber));
		////	
		////	JSONWriter.WritePropertyName("RelationshipWithDogOwner");
		////	JSONWriter.WriteValue(String(Line.RelationshipWithDogOwner));
		////	
		////	JSONWriter.WriteEndObject();
		////EndDo;
		//JSONWriter.WriteEndArray();
		// ListDog
		
		//[DogData]
		
		
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();
	JSONWriter.WritePropertyName("OwnedDog");
	DogsData(JSONWriter,CodeOwner);
	JSONWriter.WriteEndObject();
	JSONWriter.WriteEndArray();
	

 EndProcedure

 #Region API_V2_ThuongTV
 //<< Thuong TV
//Check in
Function NewDogTrackingPostCheckindata(Request)
	 Response = New HTTPServiceResponse(200);
	
	JSONWriter = New JSONWriter;
	JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.Auto, Chars.Tab);
	JSONWriter.SetString(JSONWriterSettings);
	JSONWriter.WriteStartObject();
	
	JSONWriter.WritePropertyName("NewDocument"); 
	
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	JSONWriter.WriteStartObject();
	If TypeOf(StructureResult) = Type("Structure") Then
		Password = Undefined;
		For Each curElement In structureResult Do	
			If curElement.Key = "PhoneNumber" Then
				Customer = curElement.value;	
			ElsIf curElement.Key = "Zone" Then
				Zone = curElement.value;	
			ElsIf curElement.Key = "DogCode" Then
				DogCode = curElement.value;
			ElsIf curElement.Key = "Status" Then
				Status = curElement.value;	
			Endif;
		EndDo; 
		
		NewDoc = Documents.DogTracking.CreateDocument();
		NewDoc.Date = CurrentDate();
		NewDoc.Zone = Catalogs.Zones.FindByDescription(Zone);
		NewDoc.Status = Status;
		NewDoc.Purpose = Catalogs.Purposes.None;
		NewDoc.StartTime = CurrentDate();
		NewDoc.DogOwner = Catalogs.DogOwners.FindByCode(Customer);
		NewDoc.Dog = Catalogs.Dogs.FindByCode(DogCode);
		NewDoc.Weight = NewDoc.Dog.Weight;
		
		
		NewDoc.Write(DocumentWriteMode.Posting);
	EndIf;
	JSONWriter.WriteEndObject();
	JSONWriter.WriteEndObject();
	Response.SetBodyFromString("SUCCESS");
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Return Response;
 EndFunction

//Check out
Function NewDogTrackingPutCheckindata(Request)
	 Response = New HTTPServiceResponse(200);	 
	 Query = New Query;
	DogCode = Request.QueryOptions.Get("Code");
	Query.SetParameter("Code", DogCode);
	
	Query.Text = "SELECT
	             |	DogTracking.Ref AS Ref,
	             |	DogTracking.Date AS Date,
	             |	DogTracking.DogOwner AS DogOwner,
	             |	DogTracking.Dog AS Dog,
	             |	DogTracking.EndTime AS EndTime,
	             |	DogTracking.StartTime AS StartTime,
	             |	DogTracking.Purpose AS Purpose,
	             |	DogTracking.Number AS Number
	             |FROM
	             |	Document.DogTracking AS DogTracking
	             |WHERE
	             |	DogTracking.Dog.Code = &Code";
	
	Result = Query.Execute();
	CheckinData = Result.Unload();
	
	NothingChanged = True;
	For Each Row in CheckinData Do
		If ValueIsFilled(Row.StartTime) And
			Not ValueIsFilled(Row.EndTime) Then
			NothingChanged = False;
			DocumentObject = Row.Ref.GetObject();
			DocumentObject.EndTime = CurrentDate();
			DocumentObject.Write(DocumentWriteMode.Posting);
		EndIf;
	EndDo;
	
	If NothingChanged Then
		Response.SetBodyFromString("NOTHING-CHANGED");
	Else
		Response.SetBodyFromString("SUCCESS");
	EndIf;
	Return Response;
EndFunction

//Get Zones
Function ListzoneGetListzone(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();
	JSONWriter.WriteStartObject();
	Listzone(JSONWriter);
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);

	Return Response;
EndFunction

Procedure Listzone(JSONWriter)
	JSONWriter.WritePropertyName("Listzone");
	JSONWriter.WriteStartArray();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Zones.Description AS Description,
	|	Zones.Code AS Code
	|FROM
	|	Catalog.Zones AS Zones";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(selection.Code));
		//Des
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(selection.Description));
		
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();	
EndProcedure

//Employee Task
Function DayCareGetEmployeeTask(Request)
	Response = New HTTPServiceResponse(200);
	
	EmployeeCode = Request.QueryOptions.Get("EmployeeCode");
	Day = Request.QueryOptions.Get("Day");
	If Not IsBlankString(Day) Then
		Day = Date(Day);
	Else
		Day = Date("00010101");
	EndIf;
	
	If Catalogs.Employees.FindByCode(EmployeeCode) = 
		//Exception Flow
		Catalogs.Employees.EmptyRef() Then
		Response.SetBodyFromString("EmployeeDidNotExist", TextEncoding.UTF8);
	Else
		//Normal Flow
		Query = New Query;
		Query.Text = "SELECT
		|	DayCare.LineNumber AS LineNumber,
		|	DayCare.Period AS Period,
		|	DayCare.Dog AS Dog,
		|	DayCare.Customer AS Customer,
		|	DayCare.CheckIn AS CheckIn,
		|	DayCare.CheckOut AS CheckOut,
		|	DayCare.Staff AS Staff,
		|	DayCare.Package AS Package,
		|	DayCare.PackageTime AS PackageTime,
		|	DayCare.Pickup AS Pickup,
		|	DayCare.Driver AS Driver,
		|	DayCare.City AS City,
		|	DayCare.District AS District,
		|	DayCare.Ward AS Ward,
		|	DayCare.Street AS Street,
		|	DayCare.AddressNumber AS AddressNumber,
		|	DayCare.PickupTime AS TimePickup
		|FROM
		|	InformationRegister.DayCare AS DayCare
		|WHERE
		|	DayCare.Staff.Code = &Code
		|	AND CASE
		|			WHEN &Date = &NoDate
		|				THEN TRUE
		|			ELSE DayCare.CheckIn BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
		|		END";
		
		Query.SetParameter("Code", EmployeeCode);
		Query.SetParameter("Date", Day);
		Query.SetParameter("NoDate", Date("00010101"));
		
		Result = Query.Execute();
		SelectionResult = Result.Unload();
		SelectionResult.Sort("CheckIn Asc");
		
		If SelectionResult.Count() = 0 Then
			//No data
			Response.SetBodyFromString("NoData", TextEncoding.UTF8);
		Else
			//Handle
			JSONWriter = CreateJsonWriter();
			//////////////////////////Start YeNN ---add employee information
			JSONWriter.WriteStartObject();
			JSONWriter.WritePropertyName("Metadata");
			JSONWriter.WriteStartArray();	
			////////
			JSONWriter.WriteStartObject();
			JSONWriter.WritePropertyName("TaskList");
			JSONWriter.WriteStartArray();
			///////
			
			
			
			For Each Selection In SelectionResult Do
				JSONWriter.WriteStartObject();
						//Dog
				JSONWriter.WritePropertyName("Dog");
				JSONWriter.WriteValue(String(Selection.Dog));
				//ImageDog
				JSONWriter.WritePropertyName("Picture");
				//Picture = Base64String(Selection.Dog.Picture.Get());
				Picture = "https://firebasestorage.googleapis.com/v0/b/dogsparkadmin.appspot.com/o/images%2Fcute-dogs-pembroke-welsh.jpg?alt=media&token=ccabe7e0-e03c-474a-b765-0d7ab181f699";
				JSONWriter.WriteValue(Picture);
				
				//Owner
				JSONWriter.WritePropertyName("Customer");
				JSONWriter.WriteValue(String(Selection.Customer));
				//Package
				JSONWriter.WritePropertyName("Package");
				JSONWriter.WriteValue(String(Selection.Package));
				//Staff
				JSONWriter.WritePropertyName("Staff");
				JSONWriter.WriteValue(String(Selection.Staff));
				//CheckIn
				JSONWriter.WritePropertyName("CheckIn");
				JSONWriter.WriteValue(String(Selection.CheckIn));
				//CheckOut
				JSONWriter.WritePropertyName("CheckOut");
				JSONWriter.WriteValue(String(Selection.CheckOut));
				//PackageTime
				JSONWriter.WritePropertyName("PackageTime");
				JSONWriter.WriteValue(String(Selection.PackageTime));
				//PickUp
				JSONWriter.WritePropertyName("PickUp");
				JSONWriter.WriteValue(String(Selection.PickUp));
				//Pickup Information
				If Selection.PickUp Then					
					City = Selection.City;
					Ward = Selection.Ward;
					District = Selection.District;
					Street = Selection.Street;
					AddressNumber = Selection.AddressNumber;
					Address =  String(AddressNumber) + " " + 
					String(Street) + " street ward " + 
					String(Ward) + " district " + 
					String(District) + " " +  
					String(City);
					
					JSONWriter.WritePropertyName("PickupInformation");
					JSONWriter.WriteStartArray();
					JSONWriter.WriteStartObject();
					//PickupAddress
					JSONWriter.WritePropertyName("PickupAddress");
					JSONWriter.WriteValue(Address);
					//PickupTime
					JSONWriter.WritePropertyName("PickupTime");
					JSONWriter.WriteValue(String(Selection.TimePickup));
					//Driver
					JSONWriter.WritePropertyName("Driver");
					JSONWriter.WriteValue(String(Selection.Driver));
					
					JSONWriter.WriteEndObject();
					JSONWriter.WriteEndArray();
				EndIf;
				
				JSONWriter.WriteEndObject();
			EndDo;
			JSONWriter.WriteEndArray();
			
			//////
			JSONWriter.WritePropertyName("EmployeeInformation");
			JSONWriter.WriteStartArray();
			
			Query = New Query;
			Query.Text = 
			"SELECT
			|	Employees.Ref AS Ref
			|FROM
			|	Catalog.Employees AS Employees
			|WHERE
			|	Employees.Code = &Code";
			Query.SetParameter("Code",EmployeeCode);
			
			QueryResult = Query.Execute();
			
			Selection = QueryResult.Select();
			
			
			While Selection.Next() Do
				JSONWriter.WriteStartObject();
				
				Ref = Selection.Ref;
				
				//PhoneNumber
				JSONWriter.WritePropertyName("PhoneNumber");
				JSONWriter.WriteValue(String(Ref.Code));
				//FullName
				JSONWriter.WritePropertyName("FullName");
				JSONWriter.WriteValue(String(Ref.Description));
				//Position
				JSONWriter.WritePropertyName("Position");
				JSONWriter.WriteValue(String(Ref.Position));
				//DateOfBirth
				JSONWriter.WritePropertyName("DateOfBirth");
				JSONWriter.WriteValue(String(Ref.DateOfBirth));
				//IsModerator
				JSONWriter.WritePropertyName("IsModerator");
				JSONWriter.WriteValue(String(Ref.IsModerator));
						
				JSONWriter.WriteEndObject();
				
			EndDo;
			
			JSONWriter.WriteEndArray();
			JSONWriter.WriteEndObject();
			JSONWriter.WriteEndArray();			
			JSONWriter.WriteEndObject();
			//Yennn
			
			Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
			Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
		EndIf;	
	EndIf; 
	
	Return Response;
EndFunction

//DayCare new document
Function DayCareNewDayCare(Request)
	Response = New HTTPServiceResponse(200);
	
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If TypeOf(StructureResult) = Type("Structure") Then
		Password = Undefined;
		For Each CurrentElement In structureResult Do	
			If CurrentElement.Key = "CustomerPhoneNumber" Then
				CustomerPhoneNumber = CurrentElement.value;		
			ElsIf CurrentElement.Key = "DogCode" Then
				DogCode = CurrentElement.value;
			ElsIf CurrentElement.Key = "DogSize" Then
				DogSize = CurrentElement.value;
			ElsIf CurrentElement.Key = "StaffPhoneNumber" Then
				StaffPhoneNumber = CurrentElement.value;
			ElsIf CurrentElement.Key = "Package" Then
				Package = CurrentElement.value;
			ElsIf CurrentElement.Key = "PackageTime" Then
				PackageTime = CurrentElement.value;
			ElsIf CurrentElement.Key = "Pickup" Then
				Pickup = CurrentElement.value;
			Endif;
		EndDo; 
		
		If Catalogs.DogOwners.FindByCode(CustomerPhoneNumber) = Catalogs.DogOwners.EmptyRef() Then
			Response.SetBodyFromString("CustomerPhoneNumberIsNotCorrect");
		Elsif Catalogs.Dogs.FindByCode(DogCode) = Catalogs.Dogs.EmptyRef() Then
			Response.SetBodyFromString("DogCodeIsNotCorrect");
		Elsif Catalogs.Employees.FindByCode(StaffPhoneNumber) = Catalogs.Employees.EmptyRef() Then
			Response.SetBodyFromString("StaffPhoneNumberIsNotCorrect");
		Else
			NewDoc = Documents.DayCare.CreateDocument();
			NewDoc.Date = CurrentDate();
			NewDoc.StartTime = CurrentDate();
			NewDoc.Owner = Catalogs.DogOwners.FindByCode(CustomerPhoneNumber);
			NewDoc.Dog = Catalogs.Dogs.FindByCode(DogCode);
			NewDoc.DogSize = Catalogs.DogSizes.FindByDescription(DogSize);
			NewDoc.Employees = Catalogs.Employees.FindByCode(StaffPhoneNumber);
			//Package
			If TrimAll(Package) = "Pro" Then
				NewDoc.Package = Catalogs.Packages.Pro;
			ElsIf TrimAll(Package) = "Advance" Then
				NewDoc.Package = Catalogs.Packages.Advance;
			Else
				NewDoc.Package = Catalogs.Packages.Basic;
			EndIf;
			//PackageTime
			If TrimAll(PackageTime) = "1" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.Fullday;
			ElsIf TrimAll(PackageTime) = "2" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.HalfDay1;
			ElsIf TrimAll(PackageTime) = "3" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.HalfDay2;
			Else
				NewDoc.PackageTime = Catalogs.PackageTimes.Overnight;
			EndIf;
			
			NewDoc.Write(DocumentWriteMode.Posting);
			Response.SetBodyFromString("SUCCESS");
		EndIf;
	EndIf;
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Return Response;
EndFunction

//Get Activity in Package
Function PackagesGetPackageActivity(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();	
	PackageCode = Request.QueryOptions.Get("Code");
	Package = Catalogs.Packages.FindByCode(PackageCode);
	
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("Package");
	JSONWriter.WriteValue(String(Package));
	JSONWriter.WritePropertyName("Price");
	JSONWriter.WriteValue(String(Package.Price));
	
	JSONWriter.WritePropertyName("Activities");
	JSONWriter.WriteStartArray();
	//Activity List
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Activities.Package.Code AS PackageCode,
	|	Activities.Package.Price AS PackagePrice,
	|	Activities.Code AS Code,
	|	Activities.Description AS Description,
	|	Activities.Picture AS Picture
	|FROM
	|	Catalog.Activities AS Activities
	|WHERE
	|	Activities.Package.Code = &Code";
	
	
	Query.SetParameter("Code", PackageCode);
	QueryResult = Query.Execute();	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//ActivityCode
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Code));
		//ActivityDescription
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(Selection.Description));
		//Picture
		JSONWriter.WritePropertyName("Picture");
		Picture = Base64String(Selection.Picture.Get());
		JSONWriter.WriteValue(Picture);
		//WasSelected
		JSONWriter.WritePropertyName("WasSelected");
		JSONWriter.WriteValue("True");
		JSONWriter.WriteEndObject();	
	EndDo;
	//End Activity List
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

//Get Activities
Function AcitivitiesGetActivities(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();	
	
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("Activities");
	JSONWriter.WriteStartArray();
	//Activity List
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Activities.Code AS Code,
	|	Activities.Description AS Description,
	|	Activities.Basic AS Basic,
	|	Activities.Advance AS Advance,
	|	Activities.Pro AS Pro,
	|	Activities.Price AS Price,
	|	Activities.Picture AS Picture
	|FROM
	|	Catalog.Activities AS Activities";
	
	
	QueryResult = Query.Execute();	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		JSONWriter.WriteStartObject();
		//ActivityCode
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Selection.Code));
		//ActivityDescription
		JSONWriter.WritePropertyName("Description");
		JSONWriter.WriteValue(String(Selection.Description));
		//Picture
		JSONWriter.WritePropertyName("Picture");
		Picture = Base64String(Selection.Picture.Get());
		JSONWriter.WriteValue(Picture);
		//isInBasic
		JSONWriter.WritePropertyName("Basic");
		JSONWriter.WriteValue(String(Selection.Basic));
		//isInAdvance
		JSONWriter.WritePropertyName("Advance");
		JSONWriter.WriteValue(String(Selection.Advance));
		//isInPro
		JSONWriter.WritePropertyName("Pro");
		JSONWriter.WriteValue(String(Selection.Pro));
		
		JSONWriter.WriteEndObject();	
	EndDo;
	//End Activity List
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

//Get Package included Activity
Function Packages2GetPackages(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();	
	
	JSONWriter.WriteStartObject();
	//Activity List
	
	Query = New Query;
	Query2 = New Query;
	Query.Text = 
	"SELECT
	|	Packages.Code AS Code,
	|	Packages.Ref AS Ref,
	|	Packages.Description AS Description,
	|	Packages.Price AS Price
	|FROM
	|	Catalog.Packages AS Packages";
	
	QueryResult = Query.Execute();	
	Packages = QueryResult.Unload();
	For Each Pack In Packages Do
		//Package Name
		JSONWriter.WritePropertyName("PackageName");
		JSONWriter.WriteValue(String(Pack.Description));
		//Package Code
		JSONWriter.WritePropertyName("Code");
		JSONWriter.WriteValue(String(Pack.Code));
		//Package Price
		JSONWriter.WritePropertyName("Price");
		JSONWriter.WriteValue(String(Pack.Price));
		
		JSONWriter.WritePropertyName("Activities");
		JSONWriter.WriteStartArray();
	
		Query2.Text = 
		"SELECT
		|	Activities.Code AS Code,
		|	Activities.Description AS Description,
		|	Activities.Price AS Price,
		|	Activities.Basic AS Basic,
		|	Activities.Advance AS Advance,
		|	Activities.Pro AS Pro,
		|	Activities.Picture AS Picture
		|FROM
		|	Catalog.Activities AS Activities
		|WHERE
		|	(CASE
		|				WHEN &Package = &Basic
		|					THEN Activities.Basic = &true
		|			END
		|			OR CASE
		|				WHEN &Package = &Advance
		|					THEN Activities.Advance = &true
		|			END
		|			OR CASE
		|				WHEN &Package = &Pro
		|					THEN Activities.Pro = &true
		|			END)";
		
		Query2.SetParameter("Package", Pack.Ref);
		Query2.SetParameter("Basic", Catalogs.Packages.Basic);
		Query2.SetParameter("Advance", Catalogs.Packages.Advance);
		Query2.SetParameter("Pro", Catalogs.Packages.Pro);
		Query2.SetParameter("true", True);
		QueryResult2 = Query2.Execute();
		Selection = QueryResult2.Select();
		
		While Selection.Next() Do
			JSONWriter.WriteStartObject();
			//ActivityCode
			JSONWriter.WritePropertyName("Code");
			JSONWriter.WriteValue(String(Selection.Code));
			//ActivityDescription
			JSONWriter.WritePropertyName("Description");
			JSONWriter.WriteValue(String(Selection.Description));
			//Price
			JSONWriter.WritePropertyName("Price");
			JSONWriter.WriteValue(String(Selection.Price));
			//Picture
			JSONWriter.WritePropertyName("Picture");
			Picture = Base64String(Selection.Picture.Get());
			JSONWriter.WriteValue(Picture);
			//IsSelected
			JSONWriter.WritePropertyName("WasSelected");
			JSONWriter.WriteValue("True");
			JSONWriter.WriteEndObject();	
		EndDo;
		//End Activity List
		JSONWriter.WriteEndArray();	
	EndDo;
	
	JSONWriter.WriteEndObject();
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;	
EndFunction

//Get top breed
Function GetBreedFrequencyGetBreedFrequency(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();		
	JSONWriter.WriteStartObject();
	
	Query = New Query;
	Query.Text = "SELECT
	|	Dogs.Code AS Code,
	|	Dogs.DogBreed AS DogBreed,
	|	1 AS Frequency
	|FROM
	|	Catalog.Dogs AS Dogs";
	
	Result = Query.Execute();
	Selection = Result.Unload();
	
	FrequencyList = New ValueTable();
	FrequencyList.Columns.Add("DogBreed",,,);
	FrequencyList.Columns.Add("Frequency",,,);
	
	For Each Row In Selection Do
		If FrequencyList.Find(Row.DogBreed, "DogBreed") <> Undefined Then
			FrequencyList.Find(Row.DogBreed, "DogBreed").Frequency = 
			FrequencyList.Find(Row.DogBreed, "DogBreed").Frequency + 1;
		Else
			NewRow = FrequencyList.Add();
			NewRow.DogBreed = Row.DogBreed;
			NewRow.Frequency = 1;
		EndIf;
	EndDo;
	FrequencyList.Sort("Frequency DESC");
	Top1 = FrequencyList.Get(0);
	Top2 = FrequencyList.Get(1);
	Top3 = FrequencyList.Get(2);
	
	//Top 1 2 3 Breed
	JSONWriter.WritePropertyName("TopBreeds");
	JSONWriter.WriteStartArray();
	JSONWriter.WriteStartObject();
	
 	JSONWriter.WritePropertyName("Top1");
	JSONWriter.WriteValue(String(Top1.DogBreed));
	JSONWriter.WritePropertyName("Top2");
	JSONWriter.WriteValue(String(Top2.DogBreed));
	JSONWriter.WritePropertyName("Top3");
	JSONWriter.WriteValue(String(Top3.DogBreed));
	
	JSONWriter.WriteEndObject();
	JSONWriter.WriteEndArray();

	//All Breeds
	JSONWriter.WritePropertyName("DogBreedsFrequencyTable");
	JSONWriter.WriteStartArray();
	For Each Row In FrequencyList Do
		JSONWriter.WriteStartObject();
		//ActivityDescription
		JSONWriter.WritePropertyName("DogBreed");
		JSONWriter.WriteValue(String(Row.DogBreed));
		//Price
		JSONWriter.WritePropertyName("Frequency");
		JSONWriter.WriteValue(String(Row.Frequency));
		JSONWriter.WriteEndObject();
	EndDo;
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject();
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	
	Return Response;
EndFunction

//DayCare new document v2
Function DayCare2NewDayCare2(Request)
	Response = New HTTPServiceResponse(200);
	
	StringResult = Request.GetBodyAsString();
	
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If TypeOf(StructureResult) = Type("Structure") Then
		Password = Undefined;
		For Each CurrentElement In structureResult Do	
			If CurrentElement.Key = "CustomerPhoneNumber" Then
				CustomerPhoneNumber = CurrentElement.value;		
			ElsIf CurrentElement.Key = "DogCode" Then
				DogCode = CurrentElement.value;
			ElsIf CurrentElement.Key = "DogSize" Then
				DogSize = CurrentElement.value;
			ElsIf CurrentElement.Key = "StaffPhoneNumber" Then
				StaffPhoneNumber = CurrentElement.value;
			ElsIf CurrentElement.Key = "Package" Then
				Package = CurrentElement.value;
			ElsIf CurrentElement.Key = "PackageTime" Then
				PackageTime = CurrentElement.value;
			ElsIf CurrentElement.Key = "Pickup" Then
				Pickup = CurrentElement.value;
			Endif;
		EndDo; 
		
		If Catalogs.DogOwners.FindByCode(CustomerPhoneNumber) = Catalogs.DogOwners.EmptyRef() Then
			Response.SetBodyFromString("CustomerPhoneNumberIsNotCorrect");
		Elsif Catalogs.Dogs.FindByCode(DogCode) = Catalogs.Dogs.EmptyRef() Then
			Response.SetBodyFromString("DogCodeIsNotCorrect");
		Elsif Catalogs.Employees.FindByCode(StaffPhoneNumber) = Catalogs.Employees.EmptyRef() Then
			Response.SetBodyFromString("StaffPhoneNumberIsNotCorrect");
		Else
			NewDoc = Documents.DayCare.CreateDocument();
			NewDoc.Date = CurrentDate();
			NewDoc.StartTime = CurrentDate();
			NewDoc.Owner = Catalogs.DogOwners.FindByCode(CustomerPhoneNumber);
			NewDoc.Dog = Catalogs.Dogs.FindByCode(DogCode);
			NewDoc.DogSize = Catalogs.DogSizes.FindByDescription(DogSize);
			NewDoc.Employees = Catalogs.Employees.FindByCode(StaffPhoneNumber);
			//Package and Price
			If TrimAll(Package) = "Pro" Then
				NewDoc.Package = Catalogs.Packages.Pro;
			ElsIf TrimAll(Package) = "Advance" Then
				NewDoc.Package = Catalogs.Packages.Advance;
			Else
				NewDoc.Package = Catalogs.Packages.Basic;
			EndIf;
			NewDoc.Price = NewDoc.Package.Price;
			//PackageTime
			If TrimAll(PackageTime) = "1" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.Fullday;
			ElsIf TrimAll(PackageTime) = "2" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.HalfDay1;
			ElsIf TrimAll(PackageTime) = "3" Then
				NewDoc.PackageTime = Catalogs.PackageTimes.HalfDay2;
			Else
				NewDoc.PackageTime = Catalogs.PackageTimes.Overnight;
			EndIf;
			
			//NewDoc.Write(DocumentWriteMode.Posting);
			NewDoc.Write();
		EndIf;
	EndIf;
	//Response
	JSONWriter = CreateJsonWriter();		
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("DocumentNumber");
	JSONWriter.WriteValue(String(NewDoc.Number));
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

//Get DayCare activity by DocumentNumber
Function DayCare2GetDayCareActivity2(Request)
	Response = New HTTPServiceResponse(200);
	
	DocumentNumber = Request.QueryOptions.Get("DocumentNumber");
	
	If Documents.DayCare.FindByNumber(DocumentNumber) = 
		//Exception Flow
		Documents.DayCare.EmptyRef() Then
		Response.SetBodyFromString("DocumentDidNotExist", TextEncoding.UTF8);
	Else
		//Normal Flow
		Query = New Query;
		Query.Text = "SELECT
		             |	DayCare.Ref AS Ref,
		             |	DayCare.DataVersion AS DataVersion,
		             |	DayCare.DeletionMark AS DeletionMark,
		             |	DayCare.Number AS Number,
		             |	DayCare.Date AS Date,
		             |	DayCare.Posted AS Posted,
		             |	DayCare.Dog AS Dog,
		             |	DayCare.Owner AS Owner,
		             |	DayCare.Package AS Package,
		             |	DayCare.PackageTime AS PackageTime,
		             |	DayCare.DogSize AS DogSize,
		             |	DayCare.PickUp AS PickUp,
		             |	DayCare.City AS City,
		             |	DayCare.District AS District,
		             |	DayCare.AddressNumber AS AddressNumber,
		             |	DayCare.Street AS Street,
		             |	DayCare.Ward AS Ward,
		             |	DayCare.Driver AS Driver,
		             |	DayCare.TimePickup AS TimePickup,
		             |	DayCare.IsFillActivity AS IsFillActivity,
		             |	DayCare.Weight AS Weight,
		             |	DayCare.Employees AS Employees,
		             |	DayCare.Picture AS Picture,
		             |	DayCare.PictureAddress AS PictureAddress,
		             |	DayCare.StartTime AS StartTime,
		             |	DayCare.EndTime AS EndTime,
		             |	DayCare.Price AS Price,
		             |	DayCare.ListActivity.(
		             |		Ref AS Ref,
		             |		LineNumber AS LineNumber,
		             |		Check AS Check,
		             |		Activities AS Activities,
		             |		Price AS Price
		             |	) AS ListActivity
		             |FROM
		             |	Document.DayCare AS DayCare
		             |WHERE
		             |	DayCare.Number = &Number";
		
		Query.SetParameter("Number", DocumentNumber);
		
		Result = Query.Execute();
		SelectionResult = Result.Unload();
		
		If SelectionResult.Count() = 0 Then
			//No data
			Response.SetBodyFromString("NoData", TextEncoding.UTF8);
		Else
			//Handle
			JSONWriter = CreateJsonWriter();
			JSONWriter.WriteStartObject();
			JSONWriter.WritePropertyName("DayCareDocumentInformation");
			JSONWriter.WriteStartArray();	
			For Each Selection In SelectionResult Do
				JSONWriter.WriteStartObject();
				//Number
				JSONWriter.WritePropertyName("Number");
				JSONWriter.WriteValue(String(Selection.Number));
				//Date
				JSONWriter.WritePropertyName("Date");
				JSONWriter.WriteValue(String(Selection.Date));
				//Dog
				JSONWriter.WritePropertyName("Dog");
				JSONWriter.WriteValue(String(Selection.Dog));
				//DogSize
				JSONWriter.WritePropertyName("DogSize");
				JSONWriter.WriteValue(String(Selection.DogSize));
				//Customer
				JSONWriter.WritePropertyName("Customer");
				JSONWriter.WriteValue(String(Selection.Owner));
				//Package
				JSONWriter.WritePropertyName("Package");
				JSONWriter.WriteValue(String(Selection.Package));
				//Employee
				JSONWriter.WritePropertyName("Employee");
				JSONWriter.WriteValue(String(Selection.Employees));
				//CheckIn
				JSONWriter.WritePropertyName("StartTime");
				JSONWriter.WriteValue(String(Selection.StartTime));
				//CheckOut
				JSONWriter.WritePropertyName("EndTime");
				JSONWriter.WriteValue(String(Selection.EndTime));
				//PackageTime
				JSONWriter.WritePropertyName("PackageTime");
				JSONWriter.WriteValue(String(Selection.PackageTime));
				//PickUp
				JSONWriter.WritePropertyName("PickUp");
				JSONWriter.WriteValue(String(Selection.PickUp));
				//Pickup Information
				If Selection.PickUp Then					
					City = Selection.City;
					Ward = Selection.Ward;
					District = Selection.District;
					Street = Selection.Street;
					AddressNumber = Selection.AddressNumber;
					Address =  String(AddressNumber) + ", " + 
					String(Street) + " street, ward " + 
					String(Ward) + ", district " + 
					String(District) + ", " +  
					String(City) + " city.";
					
					JSONWriter.WritePropertyName("PickupInformation");
					JSONWriter.WriteStartArray();
					JSONWriter.WriteStartObject();
					//PickupAddress
					JSONWriter.WritePropertyName("PickupAddress");
					JSONWriter.WriteValue(Address);
					//PickupTime
					JSONWriter.WritePropertyName("PickupTime");
					JSONWriter.WriteValue(String(Selection.TimePickup));
					//Driver
					JSONWriter.WritePropertyName("Driver");
					JSONWriter.WriteValue(String(Selection.Driver));
					
					JSONWriter.WriteEndObject();
					JSONWriter.WriteEndArray();
				EndIf;
				//Activity Information
				If Selection.ListActivity.Count() = 0 Then
					Response.SetBodyFromString("NoActivityInThisDocument", TextEncoding.UTF8);
				Else
					JSONWriter.WritePropertyName("ListActivity");
					JSONWriter.WriteStartArray();
					JSONWriter.WriteStartObject();
					For Each Activity In Selection.ListActivity Do
						JSONWriter.WritePropertyName("Activity" + String(Activity.LineNumber));
						JSONWriter.WriteStartArray();
						JSONWriter.WriteStartObject();
						//Check
						JSONWriter.WritePropertyName("Check");
						JSONWriter.WriteValue(String(Activity.Check));
						//Activities
						JSONWriter.WritePropertyName("ActivityName");
						JSONWriter.WriteValue(String(Activity.Activities));
						//Price
						JSONWriter.WritePropertyName("Price");
						JSONWriter.WriteValue(String(Activity.Price));
						JSONWriter.WriteEndObject();
						JSONWriter.WriteEndArray();
					EndDo;
				EndIf;
				JSONWriter.WriteEndObject();
				JSONWriter.WriteEndArray();
				
				JSONWriter.WriteEndObject();
			EndDo;
			JSONWriter.WriteEndArray();
			JSONWriter.WriteEndObject();
			
			Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
			Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
		EndIf;	
	EndIf; 
	
	Return Response;
EndFunction

//Metadata v2
Function Metadata2Metadata(Request)
	
EndFunction

//Get Employee's task for Manager
Function DayCareGetEmployeeTask_Manager(Request)
	Response = New HTTPServiceResponse(200);
	
	Day = Request.QueryOptions.Get("Day");
	If Not IsBlankString(Day) Then
		Day = Date(Day);
	Else
		Day = Date("00010101");
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	             |	DayCare.LineNumber AS LineNumber,
	             |	DayCare.Period AS Period,
	             |	DayCare.Dog AS Dog,
	             |	DayCare.Customer AS Customer,
	             |	DayCare.CheckIn AS CheckIn,
	             |	DayCare.CheckOut AS CheckOut,
	             |	DayCare.Staff AS Staff,
	             |	DayCare.Package AS Package,
	             |	DayCare.PackageTime AS PackageTime,
	             |	DayCare.Pickup AS Pickup,
	             |	DayCare.Driver AS Driver,
	             |	DayCare.City AS City,
	             |	DayCare.District AS District,
	             |	DayCare.Ward AS Ward,
	             |	DayCare.Street AS Street,
	             |	DayCare.AddressNumber AS AddressNumber,
	             |	DayCare.PickupTime AS TimePickup,
	             |	DayCare.Recorder.Number AS RecorderNumber
	             |FROM
	             |	InformationRegister.DayCare AS DayCare
	             |WHERE
	             |	CASE
	             |			WHEN &Date = &NoDate
	             |				THEN TRUE
	             |			ELSE DayCare.CheckIn BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	             |		END";
	
	Query.SetParameter("Date", Day);
	Query.SetParameter("NoDate", Date("00010101"));
	
	Result = Query.Execute();
	SelectionResult = Result.Unload();
	SelectionResult.Sort("CheckIn Asc");
	
	If SelectionResult.Count() = 0 Then
		//No data
		Response.SetBodyFromString("NoData", TextEncoding.UTF8);
	Else
		//Handle
		JSONWriter = CreateJsonWriter();
		JSONWriter.WriteStartObject();
		JSONWriter.WritePropertyName("DayCareEmployeeTaskList");
		JSONWriter.WriteStartArray();	
		JSONWriter.WriteStartObject();
		Counter = 0;
		For Each Selection In SelectionResult Do
			Counter = Counter + 1;
			//EmployeeNumber
			JSONWriter.WritePropertyName("Document"+Counter);
			JSONWriter.WriteStartArray();	
			JSONWriter.WriteStartObject();
			//Name
			JSONWriter.WritePropertyName("Name");
			JSONWriter.WriteValue(String(Selection.Staff));
			//LineNumber
			JSONWriter.WritePropertyName("LineNumber");
			JSONWriter.WriteValue(String(Selection.LineNumber));
			//RecorderNumber
			JSONWriter.WritePropertyName("DocumentNumber");
			JSONWriter.WriteValue(String(Selection.RecorderNumber));
			//Period
			JSONWriter.WritePropertyName("Period");
			JSONWriter.WriteValue(String(Selection.Period));
			//Dog
			JSONWriter.WritePropertyName("Dog");
			JSONWriter.WriteValue(String(Selection.Dog));
			//ImageDog
			JSONWriter.WritePropertyName("Picture");
			Picture = Base64String(Selection.Dog.Picture.Get());
			JSONWriter.WriteValue(Picture);
			//Owner
			JSONWriter.WritePropertyName("Customer");
			JSONWriter.WriteValue(String(Selection.Customer));
			//Package
			JSONWriter.WritePropertyName("Package");
			JSONWriter.WriteValue(String(Selection.Package));
			//CheckIn
			JSONWriter.WritePropertyName("CheckIn");
			JSONWriter.WriteValue(String(Selection.CheckIn));
			//CheckOut
			JSONWriter.WritePropertyName("CheckOut");
			JSONWriter.WriteValue(String(Selection.CheckOut));
			//PackageTime
			JSONWriter.WritePropertyName("PackageTime");
			JSONWriter.WriteValue(String(Selection.PackageTime));
			//PickUp
			JSONWriter.WritePropertyName("PickUp");
			JSONWriter.WriteValue(String(Selection.PickUp));
			//Pickup Information
			If Selection.PickUp Then					
				City = Selection.City;
				Ward = Selection.Ward;
				District = Selection.District;
				Street = Selection.Street;
				AddressNumber = Selection.AddressNumber;
				Address =  String(AddressNumber) + " " + 
				String(Street) + " street ward " + 
				String(Ward) + " district " + 
				String(District) + " " +  
				String(City);
				
				JSONWriter.WritePropertyName("PickupInformation");
				JSONWriter.WriteStartArray();
				JSONWriter.WriteStartObject();
				//PickupAddress
				JSONWriter.WritePropertyName("PickupAddress");
				JSONWriter.WriteValue(Address);
				//PickupTime
				JSONWriter.WritePropertyName("PickupTime");
				JSONWriter.WriteValue(String(Selection.TimePickup));
				//Driver
				JSONWriter.WritePropertyName("Driver");
				JSONWriter.WriteValue(String(Selection.Driver));
				
				JSONWriter.WriteEndObject();
				JSONWriter.WriteEndArray();
			EndIf;
			JSONWriter.WriteEndObject();
			JSONWriter.WriteEndArray();
		EndDo;
		JSONWriter.WriteEndObject();
		JSONWriter.WriteEndArray();
		JSONWriter.WriteEndObject();
		
		Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
		Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	EndIf;	
	
	Return Response;
EndFunction

//Create DayCare and DogTracking immediately
Function DayCare3NewDayCare3(Request)
	Response = New HTTPServiceResponse(200);
	StringResult = Request.GetBodyAsString();
	
	//Read data from Body param if exists
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	If TypeOf(StructureResult) = Type("Structure") Then
		DataSource = New Structure;
		DataSource.Clear();
		For Each CurrentElement In structureResult Do
			DataSource.Insert(String(CurrentElement.Key), String(CurrentElement.Value));	
		EndDo; 
		
		If Catalogs.DogOwners.FindByCode(DataSource.Owner) = Catalogs.DogOwners.EmptyRef() Then
			Response.SetBodyFromString("OwnerIsNotCorrect");
		Elsif Catalogs.Dogs.FindByCode(DataSource.Dog) = Catalogs.Dogs.EmptyRef() Then
			Response.SetBodyFromString("DogIsNotCorrect");
		Elsif Catalogs.Employees.FindByCode(DataSource.Employees) = Catalogs.Employees.EmptyRef() Then
			Response.SetBodyFromString("EmployeeIsNotCorrect");
		Elsif Catalogs.Packages.FindByCode(DataSource.Package) = Catalogs.Packages.EmptyRef() Then
			Response.SetBodyFromString("PackageIsNotCorrect");
		Elsif Catalogs.PackageTimes.FindByCode(DataSource.PackageTime) = Catalogs.PackageTimes.EmptyRef() Then
			Response.SetBodyFromString("PackageTimeIsNotCorrect");
		Else
			DataSource.Owner = Catalogs.DogOwners.FindByCode(DataSource.Owner);
			DataSource.Dog = Catalogs.Dogs.FindByCode(DataSource.Dog);
			DataSource.Employees = Catalogs.Employees.FindByCode(DataSource.Employees);
			DataSource.Package = Catalogs.Packages.FindByCode(DataSource.Package);
			DataSource.PackageTime = Catalogs.PackageTimes.FindByCode(DataSource.PackageTime);
			DataSource.StartTime = Date(DataSource.StartTime);
			DataSource.EndTime = Date(DataSource.EndTime);
			//Document DayCare
			NewDayCareDocument = Documents.DayCare.CreateDocument();
			NewDayCareDocument.Date = CurrentDate();
			FillPropertyValues(NewDayCareDocument, DataSource);
			NewDayCareDocument.Price = NewDayCareDocument.Package.Price;
			//DayCare ActivityList and Total price, CCTV
			ActivityArray = StrSplit(DataSource.ActivityList, ",", );
			Query = New Query;
			Query.Text = "SELECT
			|	Activities.Ref AS Ref,
			|	Activities.Code AS Code,
			|	Activities.Price AS Price
			|FROM
			|	Catalog.Activities AS Activities";
			
			Result = Query.Execute();
			Selection = Result.Choose();
			
			NewDayCareDocument.ListActivityBackup.Clear();
			While Selection.Next() Do
				NewLine = NewDayCareDocument.ListActivityBackup.Add();
				NewLine.Activities = Selection.Ref;
				If ActivityArray.Find(Selection.Code) <> Undefined Then
					NewLine.Check = True;				
				EndIf;
				NewLine.Price = Selection.Price;
			EndDo;
			Included2WLF = False;
			If ActivityArray.Find(Constants.ActivityRequiredCCTV.Get().Code) <> Undefined Then
				Included2WLF = True;				
			EndIf;
			NewDayCareDocument.IsFillActivity = True;
			NewDayCareDocument.Write();
			//Document DogTracking
			NewDogTrackingDocument = Documents.DogTracking.CreateDocument();
			NewDogTrackingDocument.Date = CurrentDate();
			FillPropertyValues(NewDogTrackingDocument, DataSource);
			NewDogTrackingDocument.DogOwner = DataSource.Owner;
			NewDogTrackingDocument.Purpose = Catalogs.Purposes.None;
			NewDogTrackingDocument.Write();
		EndIf;
	EndIf;
	
	//Response
	JSONWriter = CreateJsonWriter();		
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("CCTVAccessCode");
	If Included2WLF Then
		JSONWriter.WriteValue(String(Constants.DayCareDefaultCCTVForFeeding.Get().AccessCode));
	Else
		JSONWriter.WriteValue("NaN");
	EndIf;
	JSONWriter.WritePropertyName("DayCareDocumentNumber");
	JSONWriter.WriteValue(String(NewDayCareDocument.Number));
	JSONWriter.WritePropertyName("DogTrackingDocumentNumber");
	JSONWriter.WriteValue(String(NewDogTrackingDocument.Number));
	JSONWriter.WriteEndObject();
	
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

//Dog create new Object
Function Dogs2CreateNewDog2(Request)
	Response = New HTTPServiceResponse(200);
	StringResult = Request.GetBodyAsString();
	
	//Read data from Body param if exists
	JSONReader = New JSONReader;                                        
	JSONReader.SetString(StringResult);
	
	StructureResult = ReadJSON(JSONReader);
	JSONReader.Close();
	
	//Query param
	CustomerPhoneNumber = Request.QueryOptions.Get("CustomerPhoneNumber");
	Owner = Catalogs.DogOwners.FindByCode(CustomerPhoneNumber);
	If Owner = Catalogs.DogOwners.EmptyRef() Then
		Response.SetBodyFromString("OwnerIsNotCorrect");
	EndIf;
	If TypeOf(StructureResult) = Type("Structure") Then
		DataSource = New Structure;
		DataSource.Clear();
		For Each CurrentElement In structureResult Do
			DataSource.Insert(String(CurrentElement.Key), String(CurrentElement.Value));	
		EndDo; 
		
		If Catalogs.DogBreeds.FindByCode(DataSource.DogBreed) = Catalogs.DogBreeds.EmptyRef() Then
			Response.SetBodyFromString("DogBreedIsNotCorrect");
		Else
			DataSource.DogBreed = Catalogs.DogBreeds.FindByCode(DataSource.DogBreed);
		EndIf;
	EndIf;
	
	//Handle
	NewDog = Catalogs.Dogs.CreateItem();
	FillPropertyValues(NewDog, DataSource);
	NewDog.Description = DataSource.DogName;
	NewDog.DogBreed = DataSource.DogBreed;
	If StrCompare(DataSource.Gender, "Dog") = 0 Then
		NewDog.Gender = Enums.DogGender.Dog;	
	Else
		NewDog.Gender = Enums.DogGender.Bitch;
	EndIf;
	NewDog.DateOfBirth = Date(DataSource.DateOfBirth);
	NewDog.Owner = Owner;
	NewDog.Picture = Undefined;
	NewDog.FurColor = Catalogs.FurColors.FindByDescription(DataSource.FurColor);
	//OwnerSecondary
	MainOwner = NewDog.OwnerSecondary.Add();
	MainOwner.Phone = CustomerPhoneNumber;
	//<<Very Important Field
	MainOwner.Owner = Owner;
	//>>
	MainOwner.Main = True;
	NewDog.Write();
	
	//Response
	Response.SetBodyFromString("SUCCESS");
	Return Response;	
EndFunction

//Auth Moderator
Function ModeratorVerifyModerator(Request)
	Response = New HTTPServiceResponse(200);
	
	//Query param
	ModeratorPhoneNumber = TrimAll(Request.QueryOptions.Get("ModeratorPhoneNumber"));
	Password = TrimAll(Request.QueryOptions.Get("Password"));
	
	//<<YenNN
	CheckPhoneNumber = Catalogs.Employees.FindByCode(ModeratorPhoneNumber);

	//Handle		
	If CheckPhoneNumber=Catalogs.Employees.EmptyRef() Then	
		Response.SetBodyFromString("NotExisted",TextEncoding.UTF8);
	Else
		If Not CheckPhoneNumber.Password = Password Then
			Response.SetBodyFromString("WrongPassword",TextEncoding.UTF8);	
		Else
			Response.SetBodyFromString("Success",TextEncoding.UTF8)	
		EndIf; 
	EndIf; 
	
	//Response
	Return Response;
	//>>EndYenn
EndFunction

//Get Breeds
Function DogBreeds2GetAllDogBreeds(Request)
	Response = New HTTPServiceResponse(200);
	
	//Query param
	
	//Handle
	Query = New Query;
	Query.Text = "SELECT
	             |	DogBreeds.Code AS Code,
	             |	DogBreeds.Description AS Description
	             |FROM
	             |	Catalog.DogBreeds AS DogBreeds";
	// Param
	
	Result = Query.Execute();
	Selection = Result.Unload();

	If Selection.Count() = 0 Then
		Response.SetBodyFromString("NoData");
	Else
		JSONWriter = CreateJsonWriter();		
		JSONWriter.WriteStartObject();
		JSONWriter.WritePropertyName("AllDogBreeds");
		JSONWriter.WriteStartArray();
		For Each Breed In Selection Do
			JSONWriter.WriteStartObject();
			JSONWriter.WritePropertyName("Description");
			JSONWriter.WriteValue(String(Breed.Description));
			JSONWriter.WritePropertyName("Code");
			JSONWriter.WriteValue(String(Breed.Code));
			JSONWriter.WriteEndObject();
		EndDo;
		JSONWriter.WriteStartArray();
		JSONWriter.WriteStartObject();
	EndIf;

	//Response
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	Return Response;
EndFunction

//Get CCTVs 
Function CCTVsGetCCTV(Request)
	Response = New HTTPServiceResponse(200);
	JSONWriter = CreateJsonWriter();		
	JSONWriter.WriteStartObject();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	CCTVs.Code AS Code,
	             |	CCTVs.Description AS Description,
	             |	CCTVs.SerialNumber AS SerialNumber,
	             |	CCTVs.IPAddress AS IPAddress,
	             |	CCTVs.AccessCode AS AccessCode,
	             |	CCTVs.Model AS Model
	             |FROM
	             |	Catalog.CCTVs AS CCTVs";
	
	Result = Query.Execute();
	Selection = Result.Unload();
	
	//All CCTV Information
	JSONWriter.WritePropertyName("CCTVList");
	JSONWriter.WriteStartArray();
	If Selection.Count() <> 0 Then
		For Each Row In Selection Do
			JSONWriter.WriteStartObject();
			//Code
			JSONWriter.WritePropertyName("Code");
			JSONWriter.WriteValue(String(Row.Code));
			//Description
			JSONWriter.WritePropertyName("Description");
			JSONWriter.WriteValue(String(Row.Description));
			//SerialNumber
			JSONWriter.WritePropertyName("SerialNumber");
			JSONWriter.WriteValue(String(Row.SerialNumber));
			//IPAddress
			JSONWriter.WritePropertyName("IPAddress");
			JSONWriter.WriteValue(String(Row.IPAddress));
			//AccessCode
			JSONWriter.WritePropertyName("AccessCode");
			JSONWriter.WriteValue(String(Row.AccessCode));
			//Model
			JSONWriter.WritePropertyName("Model");
			JSONWriter.WriteValue(String(Row.Model));
			JSONWriter.WriteEndObject();
		EndDo;
	EndIf;
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject();
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	
	Return Response;
EndFunction

//Get CCTV AccessCode by DocumentNumber - On Progress
Function DayCareCCTVAccessCodeGetCCTVAccessCode(Request)
	Response = New HTTPServiceResponse(200);
	//Query param
	DocumentNumber = TrimAll(Request.QueryOptions.Get("DocumentNumber"));
	
	JSONWriter = CreateJsonWriter();		
	JSONWriter.WriteStartObject();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	DayCare.ListActivity.(
	             |		Activities.AdditionalInformation.Code AS ActivitiesAdditionalInformationCode,
	             |		Activities.AdditionalInformation.IPAddress AS ActivitiesAdditionalInformationIPAddress,
	             |		Activities.AdditionalInformation.Model AS ActivitiesAdditionalInformationModel,
	             |		Activities.AdditionalInformation.SerialNumber AS ActivitiesAdditionalInformationSerialNumber,
	             |		Activities.AdditionalInformation.Description AS ActivitiesAdditionalInformationDescription,
	             |		Activities.AdditionalInformation.AccessCode AS ActivitiesAdditionalInformationAccessCode
	             |	) AS ListActivity
	             |FROM
	             |	Document.DayCare AS DayCare
	             |WHERE
	             |	&Activities IN (DayCare.ListActivity.Activities)
	             |	AND DayCare.Number = &Number";
	
	//Query Param
	Query.SetParameter("Activities", Catalogs.Activities.TwoWayLiveFeed);
	Query.SetParameter("Number", DocumentNumber);


	Result = Query.Execute();
	Selection = Result.Unload();
	
	//All CCTV Information
	JSONWriter.WritePropertyName("CCTVList");
	JSONWriter.WriteStartArray();
	If Selection.Count() <> 0 Then
		For Each Row In Selection Do
			JSONWriter.WriteStartObject();
			//Code
			JSONWriter.WritePropertyName("Code");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationCode));
			//Description
			JSONWriter.WritePropertyName("Description");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationDescription));
			//SerialNumber
			JSONWriter.WritePropertyName("SerialNumber");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationSerialNumber));
			//IPAddress
			JSONWriter.WritePropertyName("IPAddress");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationIPAddress));
			//AccessCode
			JSONWriter.WritePropertyName("AccessCode");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationAccessCode));
			//Model
			JSONWriter.WritePropertyName("Model");
			JSONWriter.WriteValue(String(Row.ActivitiesAdditionalInformationModel));
			JSONWriter.WriteEndObject();
		EndDo;
	EndIf;
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject();
	Response.Headers.Insert("Content-Type","text/html; charset=utf-8");
	Response.SetBodyFromString(JSONWriter.Close(),TextEncoding.UTF8);
	
	Return Response;
EndFunction

//Moderator2 - On Progress
Function Moderator2VerifyModerator(Request)
	Response = New HTTPServiceResponse(200);
	
	//Query param
	ModeratorPhoneNumber = TrimAll(Request.QueryOptions.Get("ModeratorPhoneNumber"));
	Password = TrimAll(Request.QueryOptions.Get("Password"));
		
	Query = New Query;
	Query.Text = "SELECT
	             |	&Response AS Response,
	             |	Employees.Ref AS Ref,
	             |	Employees.Code AS Code,
	             |	Employees.Description AS Description,
	             |	Employees.Position AS Position,
	             |	Employees.DateOfBirth AS DateOfBirth,
	             |	Employees.PhoneNumber AS PhoneNumber,
	             |	Employees.IsModerator AS IsModerator,
	             |	Employees.Password AS Password
	             |FROM
	             |	Catalog.Employees AS Employees
	             |WHERE
	             |	CASE
	             |			WHEN Employees.Code = &Code
	             |					AND Employees.Password = &Password
	             |				THEN CASE
	             |						WHEN Employees.IsModerator = &IsModerator
	             |							THEN &Response = ""ModeratorVerified""
	             |						ELSE &Response = ""EmployeeVerified""
	             |					END
	             |			ELSE &Response = ""PasswordIsNotCorrectOrEmployeeIsNotExists""
	             |		END";
	
	// Param	
	Query.SetParameter("Response", "");
	Query.SetParameter("Code", ModeratorPhoneNumber);
	Query.SetParameter("Password", Password);
	Query.SetParameter("IsModerator", True);
	
	Result = Query.Execute();
	Selection = Result.Unload();

	If Selection.Count() <> 0 Then
		Response.SetBodyFromString(Selection.Response);
	EndIf;

	//Response
	Return Response;
EndFunction
//>> Thuong TV
#EndRegion

 

