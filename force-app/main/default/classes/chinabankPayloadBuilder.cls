public with sharing class chinabankPayloadBuilder {
    
    private static final Map<String, String> NATIONALITY_MAP = new Map<String, String>{
        'FILIPINO' => 'N0001-FILIPINO',
        'AFGHAN' => 'N0002-AFGHAN',
        'ALBANIAN' => 'N0003-ALBANIAN',
        'ALGERIAN' => 'N0004-ALGERIAN',
        'AMERICAN' => 'N0005-AMERICAN',
        'ANDORRAN' => 'N0006-ANDORRAN',
        'ANGOLAN' => 'N0007-ANGOLAN',
        'ANGUILLAN' => 'N0008-ANGUILLAN',
        'ANTIGUAN' => 'N0009-ANTIGUAN',
        'ARGENTINE' => 'N0010-ARGENTINE',
        'ARMENIAN' => 'N0011-ARMENIAN',
        'AUSTRALIAN' => 'N0012-AUSTRALIAN',
        'AUSTRIAN' => 'N0013-AUSTRIAN',
        'AZERBAIJANI' => 'N0014-AZERBAIJANI',
        'BAHAMIAN' => 'N0015-BAHAMIAN',
        'BAHRAINI' => 'N0016-BAHRAINI',
        'BANGLADESHI' => 'N0017-BANGLADESHI',
        'BARBADIAN' => 'N0018-BARBADIAN',
        'BELARUSIAN' => 'N0019-BELARUSIAN',
        'BELGIAN' => 'N0020-BELGIAN',
        'BELIZEAN' => 'N0021-BELIZEAN',
        'BENINESE' => 'N0022-BENINESE',
        'BERMUDIAN' => 'N0023-BERMUDIAN',
        'BHUTANESE' => 'N0024-BHUTANESE',
        'BOLIVIAN' => 'N0025-BOLIVIAN',
        'BOSNIAN' => 'N0026-BOSNIAN',
        'BOTSWANAN' => 'N0027-BOTSWANAN',
        'BRAZILIAN' => 'N0028-BRAZILIAN',
        'BRITISH' => 'N0029-BRITISH',
        'BRUNEIAN' => 'N0030-BRUNEIAN',
        'BULGARIAN' => 'N0031-BULGARIAN',
        'BURKINABE' => 'N0032-BURKINABE',
        'BURMESE' => 'N0033-BURMESE',
        'BURUNDIAN' => 'N0034-BURUNDIAN',
        'CAMBODIAN' => 'N0035-CAMBODIAN',
        'CAMEROONIAN' => 'N0036-CAMEROONIAN',
        'CANADIAN' => 'N0037-CANADIAN',
        'CAPE VERDEAN' => 'N0038-CAPE VERDEAN',
        'CAYMANIAN' => 'N0039-CAYMANIAN',
        'CENTRAL AFRICAN' => 'N0040-CENTRAL AFRICAN',
        'CHADIAN' => 'N0041-CHADIAN',
        'CHILEAN' => 'N0042-CHILEAN',
        'CHINESE' => 'N0043-CHINESE',
        'COLOMBIAN' => 'N0044-COLOMBIAN',
        'COMORAN' => 'N0045-COMORAN',
        'CONGOLESE' => 'N0046-CONGOLESE',
        'COSTA RICAN' => 'N0047-COSTA RICAN',
        'CROATIAN' => 'N0048-CROATIAN',
        'CUBAN' => 'N0049-CUBAN',
        'CYPRIOT' => 'N0050-CYPRIOT',
        'CZECH' => 'N0051-CZECH',
        'DANISH' => 'N0052-DANISH',
        'DJIBOUTIAN' => 'N0053-DJIBOUTIAN',
        'DOMINICAN' => 'N0054-DOMINICAN',
        'DUTCH' => 'N0055-DUTCH',
        'ECUADOREAN' => 'N0056-ECUADOREAN',
        'EGYPTIAN' => 'N0057-EGYPTIAN',
        'EMIRATI' => 'N0058-EMIRATI',
        'ENGLISH' => 'N0059-ENGLISH',
        'ERITREAN' => 'N0060-ERITREAN',
        'ESTONIAN' => 'N0061-ESTONIAN',
        'ETHIOPIAN' => 'N0062-ETHIOPIAN',
        'FAROESE' => 'N0063-FAROESE',
        'FIJIAN' => 'N0064-FIJIAN',
        'FINNISH' => 'N0065-FINNISH',
        'FRENCH' => 'N0066-FRENCH',
        'GABONESE' => 'N0067-GABONESE',
        'GAMBIAN' => 'N0068-GAMBIAN',
        'GEORGIAN' => 'N0069-GEORGIAN',
        'GERMAN' => 'N0070-GERMAN',
        'GHANAIAN' => 'N0071-GHANAIAN',
        'GIBRALTAR' => 'N0072-GIBRALTAR',
        'GREEK' => 'N0073-GREEK',
        'GREENLANDIC' => 'N0074-GREENLANDIC',
        'GRENADIAN' => 'N0075-GRENADIAN',
        'GUAMANIAN' => 'N0076-GUAMANIAN',
        'GUATEMALAN' => 'N0077-GUATEMALAN',
        'GUINEAN' => 'N0078-GUINEAN',
        'GUYANESE' => 'N0079-GUYANESE',
        'HAITIAN' => 'N0080-HAITIAN',
        'HONDURAN' => 'N0081-HONDURAN',
        'HONG KONG' => 'N0082-HONG KONG',
        'HUNGARIAN' => 'N0083-HUNGARIAN',
        'ICELANDIC' => 'N0084-ICELANDIC',
        'INDIAN' => 'N0085-INDIAN',
        'INDONESIAN' => 'N0086-INDONESIAN',
        'IRANIAN' => 'N0087-IRANIAN',
        'IRAQI' => 'N0088-IRAQI',
        'IRISH' => 'N0089-IRISH',
        'ISRAELI' => 'N0090-ISRAELI',
        'ITALIAN' => 'N0091-ITALIAN',
        'IVORIAN' => 'N0092-IVORIAN',
        'JAMAICAN' => 'N0093-JAMAICAN',
        'JAPANESE' => 'N0094-JAPANESE',
        'JORDANIAN' => 'N0095-JORDANIAN',
        'KAZAKH' => 'N0096-KAZAKH',
        'KENYAN' => 'N0097-KENYAN',
        'KIRIBATI' => 'N0098-KIRIBATI',
        'KOREAN' => 'N0099-KOREAN',
        'KUWAITI' => 'N0100-KUWAITI',
        'KYRGYZ' => 'N0101-KYRGYZ',
        'LAOTIAN' => 'N0102-LAOTIAN',
        'LATVIAN' => 'N0103-LATVIAN',
        'LEBANESE' => 'N0104-LEBANESE',
        'LIBERIAN' => 'N0105-LIBERIAN',
        'LIBYAN' => 'N0106-LIBYAN',
        'LIECHTENSTEINER' => 'N0107-LIECHTENSTEINER',
        'LITHUANIAN' => 'N0108-LITHUANIAN',
        'LUXEMBOURGER' => 'N0109-LUXEMBOURGER',
        'MACANESE' => 'N0110-MACANESE',
        'MACEDONIAN' => 'N0111-MACEDONIAN',
        'MALAGASY' => 'N0112-MALAGASY',
        'MALAWIAN' => 'N0113-MALAWIAN',
        'MALAYSIAN' => 'N0114-MALAYSIAN',
        'MALDIVIAN' => 'N0115-MALDIVIAN',
        'MALIAN' => 'N0116-MALIAN',
        'MALTESE' => 'N0117-MALTESE',
        'MARSHALLESE' => 'N0118-MARSHALLESE',
        'MARTINICAN' => 'N0119-MARTINICAN',
        'MAURITANIAN' => 'N0120-MAURITANIAN',
        'MAURITIAN' => 'N0121-MAURITIAN',
        'MEXICAN' => 'N0122-MEXICAN',
        'MICRONESIAN' => 'N0123-MICRONESIAN',
        'MOLDOVAN' => 'N0124-MOLDOVAN',
        'MONACAN' => 'N0125-MONACAN',
        'MONGOLIAN' => 'N0126-MONGOLIAN',
        'MONTENEGRIN' => 'N0127-MONTENEGRIN',
        'MOROCCAN' => 'N0128-MOROCCAN',
        'MOZAMBICAN' => 'N0129-MOZAMBICAN',
        'NAMIBIAN' => 'N0130-NAMIBIAN',
        'NAURUAN' => 'N0131-NAURUAN',
        'NEPALESE' => 'N0132-NEPALESE',
        'NEW ZEALANDER' => 'N0133-NEW ZEALANDER',
        'NICARAGUAN' => 'N0134-NICARAGUAN',
        'NIGERIEN' => 'N0135-NIGERIEN',
        'NIGERIAN' => 'N0136-NIGERIAN',
        'NORWEGIAN' => 'N0137-NORWEGIAN',
        'OMANI' => 'N0138-OMANI',
        'PAKISTANI' => 'N0139-PAKISTANI',
        'PALAUAN' => 'N0140-PALAUAN',
        'PANAMANIAN' => 'N0141-PANAMANIAN',
        'PAPUA NEW GUINEAN' => 'N0142-PAPUA NEW GUINEAN',
        'PARAGUAYAN' => 'N0143-PARAGUAYAN',
        'PERUVIAN' => 'N0144-PERUVIAN',
        'POLISH' => 'N0145-POLISH',
        'PORTUGUESE' => 'N0146-PORTUGUESE',
        'PUERTO RICAN' => 'N0147-PUERTO RICAN',
        'QATARI' => 'N0148-QATARI',
        'ROMANIAN' => 'N0149-ROMANIAN',
        'RUSSIAN' => 'N0150-RUSSIAN',
        'RWANDAN' => 'N0151-RWANDAN',
        'SALVADORAN' => 'N0152-SALVADORAN',
        'SAMOAN' => 'N0153-SAMOAN',
        'SAN MARINESE' => 'N0154-SAN MARINESE',
        'SAO TOMEAN' => 'N0155-SAO TOMEAN',
        'SAUDI' => 'N0156-SAUDI',
        'SCOTTISH' => 'N0157-SCOTTISH',
        'SENEGALESE' => 'N0158-SENEGALESE',
        'SERBIAN' => 'N0159-SERBIAN',
        'SEYCHELLOIS' => 'N0160-SEYCHELLOIS',
        'SIERRA LEONEAN' => 'N0161-SIERRA LEONEAN',
        'SINGAPOREAN' => 'N0162-SINGAPOREAN',
        'SLOVAK' => 'N0163-SLOVAK',
        'SLOVENIAN' => 'N0164-SLOVENIAN',
        'SOLOMON ISLANDER' => 'N0165-SOLOMON ISLANDER',
        'SOMALI' => 'N0166-SOMALI',
        'SOUTH AFRICAN' => 'N0167-SOUTH AFRICAN',
        'SPANISH' => 'N0168-SPANISH',
        'SRI LANKAN' => 'N0169-SRI LANKAN',
        'SUDANESE' => 'N0170-SUDANESE',
        'SURINAMESE' => 'N0171-SURINAMESE',
        'SWAZI' => 'N0172-SWAZI',
        'SWEDISH' => 'N0173-SWEDISH',
        'SWISS' => 'N0174-SWISS',
        'SYRIAN' => 'N0175-SYRIAN',
        'TAIWANESE' => 'N0176-TAIWANESE',
        'TAJIK' => 'N0177-TAJIK',
        'TANZANIAN' => 'N0178-TANZANIAN',
        'THAI' => 'N0179-THAI',
        'TOGOLESE' => 'N0180-TOGOLESE',
        'TONGAN' => 'N0181-TONGAN',
        'TRINIDADIAN' => 'N0182-TRINIDADIAN',
        'TUNISIAN' => 'N0183-TUNISIAN',
        'TURKISH' => 'N0184-TURKISH',
        'TURKMEN' => 'N0185-TURKMEN',
        'TUVALUAN' => 'N0186-TUVALUAN',
        'UGANDAN' => 'N0187-UGANDAN',
        'UKRAINIAN' => 'N0188-UKRAINIAN',
        'URUGUAYAN' => 'N0189-URUGUAYAN',
        'UZBEK' => 'N0190-UZBEK',
        'VANUATUAN' => 'N0191-VANUATUAN',
        'VATICAN' => 'N0192-VATICAN',
        'VENEZUELAN' => 'N0193-VENEZUELAN',
        'VIETNAMESE' => 'N0194-VIETNAMESE',
        'WELSH' => 'N0195-WELSH',
        'YEMENI' => 'N0196-YEMENI',
        'ZAMBIAN' => 'N0197-ZAMBIAN',
        'ZIMBABWEAN' => 'N0198-ZIMBABWEAN'
    };
        
    private static String transformNationality(String rawNationality) {
        if (String.isBlank(rawNationality)) return null;
    
        String key = rawNationality.trim().toUpperCase();
        if (NATIONALITY_MAP.containsKey(key)) {
            return NATIONALITY_MAP.get(key);
        }
        return rawNationality;
    }
    
    private static String formattedIndustryClass(String rawIndustryClass) {
        if (String.isBlank(rawIndustryClass)) {
            return null;
        }
    
        rawIndustryClass = rawIndustryClass.trim();
    
        if (rawIndustryClass.length() > 60) {
            return rawIndustryClass.substring(0, 60);
        }
    
        return rawIndustryClass;
    }
   
    private static String formattedMobile(String mobile) {
        if (String.isBlank(mobile)) return null;
    
        String m = mobile.trim();
    
        if (m.startsWith('0') && m.length() == 11) {
          m = '63' + m.substring(1);
      }
    
        return m;
    }
    
    private static String formatBusinessProvince(String province) {
        if (String.isBlank(province)) return null;
    
        String p = province.trim();
    
        if (p.toUpperCase().startsWith('METRO MANILA')) {
            return 'Metro Manila';
        }
    
        return p;
	}


    private static final List<String> NO_EMPLOYMENT_STATUS = new List<String>{
        'ES0010-UNEMPLOYED', 'ES0011-HOUSEWIFE', 'ES0012-STUDENT', 'ES0013-RETIRED'
    };
        
    private static String formattedCompanyName(String companyName) {
        if (String.isBlank(companyName)) {
            return null;
        }
    
        String name = companyName.trim();
    
        return (name.length() > 35)
            ? name.substring(0, 35)
            : name;
    }
        
    private static String generateReferenceNumber() {
            
        Long timestamp = Datetime.now().getTime();
        Long rand1 = Crypto.getRandomLong();
        Long rand2 = Crypto.getRandomLong();
    
        String seed = timestamp + '-' + rand1 + '-' + rand2;
    
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(seed));
        String fullHash = EncodingUtil.convertToHex(digest).toUpperCase();
    
        String hash29 = fullHash.substring(0, 29);
    
        return 'LEX' + hash29;
    }


    public static String buildPayload(Contact con) {

        String referenceNumber = generateReferenceNumber();
        
        String formattedDate = Datetime.now().format(
            'yyyy-MM-dd HH:mm:ss',
            'Asia/Manila'
        );
    

        Map<String, Object> requesterContext = new Map<String, Object>{
            'ClientId'                  => 'LEX',          
            'RequesterReferenceNumber'  => referenceNumber,
            'RequestDateTime'           => formattedDate
        };

        Map<String, Object> requestHeader = new Map<String, Object>{
            'RequesterContext' => requesterContext
        };
            
		Date bdate = con.Birthdate__c;
		Datetime bdate_t = DateTime.newInstance(bdate, Time.newInstance(0,0,0,0));  
        string formattedbdate = bdate_t.format('yyyy-MM-dd');
        string formattedSubClass = con.industry_subclass__c;
        formattedSubClass = String.isBlank(formattedSubClass) ? null : formattedSubClass.replace('--', '-');
        
        String rawTenure = con.employment_tenure__c;

        String formattedTenureYearMonth =
            String.isBlank(rawTenure)
                ? null
                : rawTenure.replaceAll('\\s+', '');
        
        if (formattedTenureYearMonth == '00|00') {
            formattedTenureYearMonth = '00|01';
        }

            
        Map<String, Object> personalInfo = new Map<String, Object>{
            'FirstName'            => con.FirstName,
            'MiddleName'           => con.MiddleName,
            'LastName'             => con.LastName,
            'Suffix'               => con.Suffix,
            'DateOfBirth'          => formattedbdate,
            'PlaceOfBirth'         => con.place_of_birth_city__c,
            'Gender'               => con.gender__c,
            'CivilStatus'          => con.marital_status__c,
            'Nationality'          => transformNationality(con.nationality__c),
            'MotherMaidenName'     => con.mother_maiden_name__c,
            'EducationalAttainment'=> con.educational_attainment__c,
            'CarOwnership'         => con.car_ownership__c,
            'IdType'               => con.cbcc_id_type__c,
            'IdNumber'             => con.cbcc_id_number__c
        };

        Map<String, Object> contactInfo = new Map<String, Object>{
            'MobileNumber'                     => formattedMobile(con.MobilePhone),
            'EmailAddress'                     => con.Email,
            'TelephoneNumber'                  => con.Phone,
            'PresentAddress_Street'            => con.street__c,
            'PresentAddress_Barangay'          => con.barangay__c,
            'PresentAddress_CityMunicipality'  => con.city__c,
            'PresentAddress_Province'          => con.province__c,
            'PresentAddress_Country'           => 'Philippines',
            'PresentAddress_PostalCode'        => con.zip_code__c,
            'PermanentAddress'                 => con.Permanent_Address__c
        };

        Boolean isNoEmployment =
            !String.isBlank(con.employment_status__c) &&
            NO_EMPLOYMENT_STATUS.contains(con.employment_status__c.toUpperCase());

        Map<String, Object> employmentInfo = new Map<String, Object>{
            'EmploymentStatus' => con.employment_status__c
        };

        if (isNoEmployment) {
        
            Map<String, String> employmentToOccupation = new Map<String, String>{
                'ES0011-HOUSEWIFE'  => 'OC0026-HOUSEWIFE',
                'ES0012-STUDENT'    => 'OC0056-STUDENT',
                'ES0010-UNEMPLOYED' => 'OC0059-UNEMPLOYED',
                'ES0013-RETIRED'    => 'OC0059-UNEMPLOYED'
            };
        
            String employmentStatus = con.employment_status__c;
        
            String occupationValue = employmentToOccupation.containsKey(employmentStatus)
                ? employmentToOccupation.get(employmentStatus)
                : 'OC0059-UNEMPLOYED';
        
            employmentInfo.put('Occupation', occupationValue);
            employmentInfo.put('MajorIndustry', 'MI0015-OTHER SERVICE ACTIVITIES');
            employmentInfo.put('Industryclass', 'NOT APPLICABLE');
            employmentInfo.put('IndustrySubclass', 'NOT APPLICABLE');
            employmentInfo.put('SourceOfFunds', con.cbcc_source_of_income__c);
            employmentInfo.put('NameofCompany', 'NOT APPLICABLE');
            employmentInfo.put('TenureYearMonth', '00|01');
        
            employmentInfo.put('BusinessAddress_Street', con.street__c);
            employmentInfo.put('BusinessAddress_Barangay', con.barangay__c);
            employmentInfo.put('BusinessAddress_CityMunicipality', con.city__c);
            employmentInfo.put('BusinessAddress_Province', formatBusinessProvince(con.province__c));
            employmentInfo.put('BusinessAddress_Country', 'Philippines');
            employmentInfo.put('BusinessAddress_PostalCode', con.zip_code__c);
            employmentInfo.put('GrossAnnualIncome', con.cbcc_annual_income__c);
            employmentInfo.put('PreferredBillingAddress', 'PRESENT');
        } 	else {

            Boolean usePresentAddress = 
                String.isBlank(con.Business_Street__c) ||
                String.isBlank(con.business_barangay__c) ||
                String.isBlank(con.business_city__c) ||
                String.isBlank(con.business_province__c);
            
            String finalStreet;
            String finalBarangay;
            String finalCity;
            String rawFinalProvince;
            String finalZipCode;
            String finalCountry;
            
            if (usePresentAddress) {
                finalStreet = con.street__c;
                finalBarangay = con.barangay__c;
                finalCity = con.city__c;
                rawFinalProvince = con.province__c;
                finalZipCode = con.zip_code__c;
                finalCountry = 'Philippines';
            } else {
                finalStreet = con.Business_Street__c;
                finalBarangay = con.business_barangay__c;
                finalCity = con.business_city__c;
                rawFinalProvince = con.business_province__c;
                finalZipCode = con.business_address_zip_code__c;
                finalCountry = 'Philippines';
            }

            String finalProvince = formatBusinessProvince(rawFinalProvince);
            String businessEmail = String.isBlank(con.business_email__c) ? con.Email : con.business_email__c;
            String businessPhone = String.isBlank(con.business_phone__c) ? con.Phone : con.business_phone__c;


            employmentInfo.put('Occupation', con.cbcc_occupation__c);
            employmentInfo.put('MajorIndustry', con.cbcc_major_industry__c);
            employmentInfo.put('Industryclass', formattedIndustryClass(con.Industry_Class__c));
            employmentInfo.put('IndustrySubclass', formattedSubClass);
            employmentInfo.put('SourceOfFunds', con.cbcc_source_of_income__c);
            employmentInfo.put('NameofCompany', formattedCompanyName(con.company_name__c));
            employmentInfo.put('TenureYearMonth', formattedTenureYearMonth);
            
            employmentInfo.put('BusinessMobileNumber', con.business_mobile_number__c);
            
            employmentInfo.put('BusinessPhoneNumber', businessPhone);
            employmentInfo.put('BusinessEmailAddress', businessEmail);
            
            employmentInfo.put('BusinessAddress_Street', finalStreet);
            employmentInfo.put('BusinessAddress_Barangay', finalBarangay);
            employmentInfo.put('BusinessAddress_CityMunicipality', finalCity);
            employmentInfo.put('BusinessAddress_Province', finalProvince);
            employmentInfo.put('BusinessAddress_Country', 'Philippines');
            employmentInfo.put('BusinessAddress_PostalCode', finalZipCode);
            
            employmentInfo.put('GrossAnnualIncome', con.cbcc_annual_income__c);
            employmentInfo.put('PreferredBillingAddress', con.preferred_billing_address__c);
        }

        Map<String, Object> requestBody = new Map<String, Object>{
            'MembershipId'           => con.membership_id__c,
            'PersonalInformation'    => personalInfo,
            'ContactInformation'     => contactInfo,
            'EmploymentInformation'  => employmentInfo
        };

        Map<String, Object> fullPayload = new Map<String, Object>{
            'RequestHeader' => requestHeader,
            'RequestBody'   => requestBody
        };

        return JSON.serialize(fullPayload);
    }
    
    public static String buildGetResultPayload(String applicationRefNo) {
    
        String referenceNumber = generateReferenceNumber();
       
        String formattedDate = Datetime.now().format(
            'yyyy-MM-dd HH:mm:ss',
            'Asia/Manila'
        );
    
        Map<String, Object> requesterContext = new Map<String, Object>{
            'ClientId'                => 'LEX',           
            'RequesterReferenceNumber'=> referenceNumber,
            'RequestDateTime'         => formattedDate
        };
    
        Map<String, Object> requestHeader = new Map<String, Object>{
            'RequesterContext' => requesterContext
        };
    
        Map<String, Object> requestBody = new Map<String, Object>{
            'ApplicationReferenceNo' => applicationRefNo
        };
    
        Map<String, Object> fullPayload = new Map<String, Object>{
            'RequestHeader' => requestHeader,
            'RequestBody'   => requestBody
        };
    
        return JSON.serialize(fullPayload);
    }
}