///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Converts the amount from the source currency to the new currency according to their rate parameters.
// To get currency rate parameters, use the CurrencyExchangeRates.GetCurrencyExchangeRate function.
//
// Parameters:
//   Amount                  - Number     - the amount to be converted.
//
//   CurrentRateParameters - Structure - the rate parameters for the source currency.
//    * Currency    - CatalogRef.Currencies - reference to the currency to be converted.
//    * Rate      - Number - rate of the currency being converted.
//    * Multiplier - Number - multiplier for the currency being converted.
//
//   ewRateParameters   - Structure - rate parameters for a new currency.
//    * Currency    - CatalogRef.Currencies - link for a currency, into which calculation is being made.
//    * Exchange rate      - Number - exchange rate for a currency, into which calculation is being made.
//    * Multiplier - Number - multiplier of a currency, into which calculation is being made.
//
// Returns:
//   Number - the amount converted at the new rate.
//
Function ConvertAtRate(Sum, SourceRateParameters, NewRateParameters) Export
	If SourceRateParameters.Currency = NewRateParameters.Currency
		Or (SourceRateParameters.Rate = NewRateParameters.Rate 
			AND SourceRateParameters.Repetition = NewRateParameters.Repetition) Then
		
		Return Sum;
	EndIf;
	
	If SourceRateParameters.Rate = 0
		Or SourceRateParameters.Repetition = 0
		Or NewRateParameters.Rate = 0
		Or NewRateParameters.Repetition = 0 Then
		
		Return 0;
	EndIf;
	
	Return Round((Sum * SourceRateParameters.Rate * NewRateParameters.Repetition) 
		/ (NewRateParameters.Rate * SourceRateParameters.Repetition), 2);
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ConvertAtRate instead.
//
// Converts the amount from the currency CurrencyTrg at the rate of AtRateSrc into the currency 
// CurrencyTrg at the rate of AtRateTrg.
//
// Parameters:
//   Amount - Number - the amount to be converted.
//   CurrencySrc      - CatalogRef.Currencies - the source currency.
//   CurrencyDst      - CatalogRef.Currencies - the destination currency.
//   AtRateSrc     - Number - the source currency rate.
//   AtRateDst     - Number - the destination currency rate.
//   ByMultiplierSrc - Number - the source currency rate multiplier (the default value is 1).
//   ByMultiplierDst - Number - the destination currency rate multiplier (the default value is 1).
//
// Returns:
//   Number - The converted amount.
//
Function ConvertCurrencies(Sum, CurrencySrc, CurrencyDst, AtRateSrc, AtRateDst, 
	ByMultiplierSrc = 1, ByMultiplierDst = 1) Export
	
	Return ConvertAtRate(
		Sum, 
		New Structure("Currency, Rate, Repetition", CurrencySrc, AtRateSrc, ByMultiplierSrc),
		New Structure("Currency, Rate, Repetition", CurrencyDst, AtRateDst, ByMultiplierDst));
	
EndFunction

#EndRegion

#EndRegion
