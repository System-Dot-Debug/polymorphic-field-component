@isTest
private class PolySearchTest {
    static testMethod void validatePolySearch() {
        
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        PolymorphicJoin__c pj = new PolymorphicJoin__c();
        pj.Name = 'Account';
        pj.LookupObjectAPIName__c = 'Account';
        pj.NameField__c = 'Name';
        pj.Type__c = 'Account';
        pj.LookupRecordId__c = a.Id;
        
        insert pj;
        
        PolymorphicJoin__c pj2 = new PolymorphicJoin__c();
        pj2.Name = 'Test Poly';
		pj2.PolymorphicJoin__c = pj.id;

        insert pj2;       
        
        List<List<SObject>> objectDataList = new List<List<SObject>>();
        objectDataList.add(new List<Account>{a});
        objectDataList.add(new List<PolymorphicJoin__c>{pj,pj2});
        
        Map<String,String> data = new Map<String,String>{
            'polyId' => pj2.PolymorphicJoin__c,
            'nameField' => 'Name',
            'objectAPIName' => 'Account',
            'lookupRecordId' => a.Id,
            'fieldAPIName' => 'PolymorphicJoin__c',
            'recId' => pj2.Id,
            'recObject' => 'PolymorphicJoin__c'
        };  
        
        PolySearch ps = new PolySearch();            
        PolySearch.checkCurrentValue('','','');
        PolySearch.checkCurrentValue('PolymorphicJoin__c',pj2.Id,'PolymorphicJoin__c');
        PolySearch.search('Test');
        PolySearch.getSearchResults(objectDataList);    
        PolySearch.updatePolyValue('{}');
        PolySearch.updatePolyValue(JSON.serialize(data));
    }
}