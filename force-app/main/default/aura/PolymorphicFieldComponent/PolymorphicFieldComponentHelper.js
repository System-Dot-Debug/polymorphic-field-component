({
	runSearch: function(component)
    {
        var spinner = component.find('spinner');
        var $clear = $('.clear-search');
        var spinnerInEvt = spinner.get("e.toggle");
        $clear.css('display','none');
        spinnerInEvt.setParams({ isVisible : true });        
        spinnerInEvt.fire();
        
        var action = component.get("c.search");
        action.setParams({
            'searchTerm' : $('#searchTerm').val()          
        });
        
        action.setCallback(this, function(data) {
            var recordOptions = JSON.parse(data.getReturnValue());
            var $select = $('#sObjectRecords');            
            var data = {};//we will store this information on our select element so we can get access to it later.
            var optionsString = '';
            //Loop over each of the records that was returned and build out an element to display the data.
            $.each(recordOptions,function(k,rec){
                var iconURL = rec.iconURL != undefined ? rec.iconURL : '';
                optionsString += '<li id="' + rec.id + '" value="' + rec.id + '"><span><img src="' + iconURL   + '" height="16"/></span>' + rec.label + '</li>';
                data[rec.id] = rec;
            });
            
            
            $select.data('records',data);
            $select.empty();
            $select.append(optionsString);
              
            
            var spinnerOutEvt = spinner.get("e.toggle");
        	spinnerOutEvt.setParams({ isVisible : false });           
            spinnerOutEvt.fire();
            $clear.css('display','block');
            $select.css('display','block');
            $('#clear').css('display','block');     
            
        });
        $A.enqueueAction(action);
        
    },
    checkCurrentValue: function(component){
        var action = component.get("c.checkCurrentValue");
        action.setParams({
            'recObject' : component.get('v.sObjectName'),
            'recId' : component.get('v.recordId'),
            'fieldAPIName' : component.get('v.lookupFieldAPIName')            
        });        
        
        action.setCallback(this, function(data) {            
            var objectInfo = JSON.parse(data.getReturnValue());
            if(objectInfo)
            {
                component.set("v.outputField", objectInfo.label);
                component.set("v.polyId",objectInfo.polyId);
                component.set("v.lookupFieldLabel",objectInfo.fieldLabel)
            } else 
            {
                component.set("v.outputField",'No Record Chosen');
            }
        });        

    	$A.enqueueAction(action);
    },
    updateField: function(component,data)
    {
        
        var action = component.get("c.updatePolyValue");
        action.setParams({
            'data' : JSON.stringify(data)                     
        });
        
        action.setCallback(this, function(data) {
            if(data.getState() == 'SUCCESS')
            {
                var recordOptions = JSON.parse(data.getReturnValue());
                console.log({success:true,recordOptions: recordOptions});
            } else {
                console.log({success:false});
            }        
        });
        $A.enqueueAction(action);
        component.set('v.outputField',data.label);
        component.set('v.displayMode',true);
        component.set('v.searchTerm','');
        $('#sObjectRecords').empty();        
        $('#sObjectRecords').css('display','none');
    }
})