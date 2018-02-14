Global with sharing class PolySearch {
    //The nameFields map is just a collection of customObjects and their known standard name fields.
    //PolySearch only includes standard objects that are in this map
    private static Map<String,String> nameFields = new Map<String,String>{
        	'case' => 'CaseNumber',
            'workorder' => 'WorkOrderNumber',
            'solution' =>'SolutionName',
            'contentversion' => 'VersionNumber',
            'contentdocument' => 'Title',
            'contentnote' => 'Title',
            'note' => 'Title',
            'task' => 'Subject',
            'event' => 'Subject',
            'idea' => 'Title',
            'account' => 'Name',
            'opportunity' => 'Name',
            'lead' => 'Name',
            'campaignmember' => 'Name',
            'campaign' => 'Name',
            'contact' => 'Name',
            'User' => 'Name'
		};
    
    public PolySearch()
    {}
    
    /**
     *  We use this method to check and see if the current record has a lookup record
     *  associted to it or not. It is called in the doInit function of our controller.js script.
     *  @param String recObject: The api name of the current records object
     *  @param String recId: The id of the current record
     *  @param String fieldAPIName: The api name of the recObjects lookup field to PolymorphicJoin__c
     *  @return JSONString lookupData: {
     *        	label: Concatination of lookup object label and the value of the lookup records name field
     *			recId: Lookup records Id
     *			polyId: Associated PolymorphicJoin__c record Id
     *			fieldLabel: Label of the PolymorphicJoin__c lookup Field on the current records Object.
     *     }
     */ 
    @auraEnabled   
    public static String checkCurrentValue(String recObject,String recId, String fieldAPIName){
		Map<String,String> lookupData = new Map<String,String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<String> polyFields = new List<String>{'Name','LookupObjectAPIName__c','LookupRecordId__c','NameField__c','Id'};
        String polyLookup = fieldAPIName.endsWith('__c') ? fieldAPIName.replace('__c','__r') : fieldAPIName;
        String recQueryString = 'Select ' + polyLookup + '.' + String.join(polyFields,',' + polyLookup + '.') + ' From ' + recObject + ' Where Id =:recId AND ' + fieldAPIName + ' != \'\'';
         
        //if this is null its because of a custom field that may contain a namespace.
        //need to find a way to check for this but for now include namespace in design param on setup.
            
        String fieldLabel = '';
        try{
            Schema.DescribeSObjectResult thisRecObject = gd.get(recObject).getDescribe();
            fieldLabel = String.valueOf(thisRecObject.fields.getMap().get(fieldAPIName).getDescribe().getLabel());
            for(sObject rec : database.query(recQueryString))
            {            
                String nameField = String.valueOf(rec.getSObject(polyLookup).get('NameField__c'));
                String lookupObject = String.valueOf(rec.getSObject(polyLookup).get('LookupObjectAPIName__c'));
                String lookupRecDataQueryString = 'Select ' + nameField + ' From ' + lookupObject + ' Where Id =\'' + String.valueOf(rec.getSObject(polyLookup).get('LookupRecordId__c')) + '\'';
                sobject lookupRecData = database.query(lookupRecDataQueryString);
                String lookupLabel = String.valueOf(gd.get(lookupObject).getDescribe().getLabel());
                lookupData.put('label',lookupLabel + ': ' + lookupRecData.get(nameField));
                lookupData.put('recId',String.valueOf(rec.getSObject(polyLookup).get('LookupRecordId__c')));
                lookupData.put('polyId',String.valueOf(rec.get(fieldAPIName)));
                lookupData.put('fieldLabel',fieldLabel);
            }
        } catch(Exception e){
            system.debug(e.getMessage());
        }
        if (lookupData == null || lookupData.isEmpty()) {
        	lookupData.put('label','No Data');
            lookupData.put('recId','');
            lookupData.put('polyId','');
            lookupData.put('fieldLabel',fieldLabel);
        }
        return JSON.serialize(lookupData);
    }
    
    /**
     *  We use this method to begin a SOSL search using objects in the users org based on the users search input.
     *  @param String searchTerm: User specified text.
     *  @return JSONString searchResults: [{
     *        	label: Concatination of search object label and the value of the search records name field
     *			id: Search records Id
     *			APIName: Search objects API Name
     *			nameField: API Name of the the search objects name field.
	 *			iconURL: URL of the search objects tab icon if present.
     *     }]
     */ 
    @auraEnabled
    public static String search(String searchTerm){
        
        List<String> soslWhere = getSOSLWhere(searchTerm);
        List<List<SObject>> searchList = search.query('FIND \''+searchTerm+'*\' IN Name Fields Returning ' + String.join(soslWhere,','));  
        List<map<string,object>> searchResults = getSearchResults(searchList);
        return JSON.serialize(searchResults);
    }
    
    /**
     * We use this method to update the current record as well as update / create a PolymorphicJoin__c record
     * with the users selected record information.
     * @param JSONString data: JSON data that was stringified in our Helper.js scripts updateField function.
     */ 
    @auraEnabled
    public static void updatePolyValue(String data){
    	Map<string,string> dataMap = (Map<String,String>)JSON.deserializeStrict(data, Map<String,String>.class);
        try {
            String polyId = dataMap.containsKey('polyId') ? dataMap.get('polyId') : '';//Check to see if a polyId was passed. If not then keep it blank and we will create a new record.
            String nameField = dataMap.get('nameField');
            String objectAPIName = dataMap.get('objectAPIName');
            String lookupRecordId = dataMap.get('lookupRecordId');
            String thisRecFieldAPIName = dataMap.get('fieldAPIName');
            String thisRecId = dataMap.get('recId');
            String recObject = dataMap.get('recObject');
            
            PolymorphicJoin__c polyRec = new PolymorphicJoin__c();
            if (polyId != null && polyId != '')
            {
                polyRec.Id = polyId;//This record already has an associate PolymorphicJoin__c record so lets just update that one and not create a new one.
            }
            
            polyRec.Name = objectAPIName;
            polyRec.LookupObjectAPIName__c = objectAPIName;
            polyRec.LookupRecordId__c = lookupRecordId;
            polyRec.NameField__c = nameField;
            polyRec.Type__c = objectAPIName;
            polyRec.DisplayName__c = 'stuffNuggets';
            upsert polyRec;  
            
            sObject thisRec = database.query('Select Id From ' + recObject + ' Where Id =:thisRecId');
            thisRec.put(thisRecFieldAPIName,String.valueOf(polyRec.Id));
            update thisRec;
        }catch(Exception e)
        {
            system.debug(e.getMessage());
        }
       
    }
    
    /**
     *  We use this method to build out our SOSL where clause information and fields to return from each object.
     *  @param String searchTerm: User specified text.
	 *  @return List<String> objectNames: ['sObject(Id,Name Where Name Like '%searchTerm%' Limit 3)']
     */
    public static List<String> getSOSLWhere(String searchTerm){
        List<String> objectNames = new List<String>();
        //we need to build a map of all our sObjects
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        //Now we will loop over the keys in our gd Map and do a describe on each object.
        for(String key : gd.keySet())
        {
            //we need to see if the current user has access to this object. 
        	if(gd.get(key).getDescribe().isAccessible() && gd.get(key).getDescribe().isSearchable())
            {
                //The current user has access so lets add the key / object api name to our list
                
                //We are using a map to handle exception objects that have special name fields                 
                
                if(nameFields.containsKey(key.toLowerCase())){
                    string nameField = nameFields.get(key.toLowerCase());
                    objectNames.add(key + '(Id,'+ nameField +  ' Where ('+nameField+' Like \'%' + searchTerm + '%\') Limit 3)');
                    
                } else if (gd.get(key).getDescribe().isCustom() && key.endsWith('__c')){
                    objectNames.add(key + '(Id,Name Where Name Like \'%'+searchTerm+'%\' Limit 3)');
                }
            }
        }
       	
        //we are done building our list of accessible sObject Names and need to send the data back.
        return objectNames;
    }
    
    /**
     * We use this method to get any tab data in our org like tab labels and icons.
	 * @return Map<String,Map<String,String>> tabData: {
	 * 		sObject apiName => {
	 * 			label => the label of the sObject,
	 * 			iconURL => url of the tabs icon.
	 * 		}
	 * }
     */ 
    public static Map<String,Map<String,String>> buildTabData()
    {
        Map<String,Map<String,String>> tabData = new Map<String,Map<String,String>>();//we need to be able to build a map of tab url data in order to make our app fancier looking
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        for(DescribeTabSetResult tsr : tabSetDesc) {
            List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();
                    for(Schema.DescribeTabResult tr : tabDesc) {
                        if(!tabData.containsKey(tr.getSobjectName()))
                        {
                            tabData.put(tr.getSobjectName(),new Map<String,String>{'label' => tr.getLabel(),'iconURL' => tr.getMiniIconUrl()});
                        }
                    }
            
        }
        return tabData;
    }
    
    /**
     *  We use this method to build out our search results that we will pass to the user.
     *  @param List<List<SObject>> searchList: List of a list of sObjects information received from a SOSL search.
	 *  @return List<map<string,object>> searchResults: [{
     *        	label => Concatination of search object label and the value of the search records name field
     *			id => Search records Id
     *			APIName => Search objects API Name
     *			nameField => API Name of the the search objects name field.
	 *			iconURL => URL of the search objects tab icon if present.
     *     }]
     */
    public static List<map<string,object>> getSearchResults(List<List<SObject>> searchList){
        system.debug(searchList);
        List<map<string,object>> searchResults = new List<map<string,object>>();
        Map<String,Map<String,String>> tabData = buildTabData();
        if(searchList != null) {
            //Loop through the list of the list of sObjects from our sosl query
            for(list<sObject> objectList : searchList) {
				
                if(objectList.isEmpty() != true) {                    
                    string objType = ID.valueOf(objectList.get(0).id).getSObjectType().getDescribe().getName();
                    
                	if(nameFields.containsKey(objType.toLowerCase())){
                   
                    		for(sObject obj : objectList) {
                                map<string,object> searchResult = new map<string,object>{                                
                                    'label' => tabData.get(objType).get('label') + ': ' + obj.get(nameFields.get(objType.toLowerCase())),
                                    'id' => obj.get('Id'),
                                    'APIName' => objType,
                                    'nameField' => nameFields.get(objType.toLowerCase()),
                                    'iconURL' => tabData.get(objType).containsKey('iconURL')!= null ? tabData.get(objType).get('iconURL'): ''
                                };
                                searchResults.add(searchResult);
                            
                            }
                    }
                    else {
                        
                        for(sObject obj : objectList) {
                            map<string,object> searchResult = new map<string,object>{
    							'label' => tabData.containsKey(objType)? tabData.get(objType).get('label') + ':' + obj.get('Name') : 'No Tab Data',
                                'id' => obj.get('Id'),
                                'APIName' => objType,
                                'nameField' => 'name'
                            };
    						searchResults.add(searchResult);
                            
                        }
                    }
		    	}
            }
        }
        
        return searchResults;
    }
}