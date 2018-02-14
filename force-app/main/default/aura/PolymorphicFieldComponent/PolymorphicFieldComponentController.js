({ 
    editMode: function(component)
    {
        component.set('v.displayMode',false);
    },
    displayMode : function(component) 
    {
        component.set('v.displayMode',true);
        component.set('v.searchTerm','');
        $('#sObjectRecords').empty();
        $('#sObjectRecords').css('display','none');
    },
	doInit: function(component, event, helper)
    {
        //Upon load of the component we want to check and see if there is already a relational record
        helper.checkCurrentValue(component);
        
        /**
        * Initialize Event Listeners
        */
        
        //Any time a new li element is generated and appended to our records select list
        //we want to make sure that we are listening in case it is clicked
        //then we will take information from that element in order to create / update our 
        //poly fields.
        $('body').on('click','#sObjectRecords li',function(){
            
            var $select = $('#sObjectRecords');
            var records = $select.data('records');
            var value = $(this).attr('value');
            var recordOptions = records[value] != null ? records[value] : {};
            var data = {
                nameField:     recordOptions.nameField,
                objectAPIName: recordOptions.APIName,
                polyId:        component.get('v.polyId'),
                lookupRecordId:value,
                fieldAPIName:  component.get('v.lookupFieldAPIName'),
                objectAPIName: recordOptions.APIName,
                recId:         component.get('v.recordId'),
                recObject:     component.get('v.sObjectName'),
                label:         $(this).text()
            }
            helper.updateField(component,data);
        });
        
        //We are going to start/restart a half-second timer everytime the user presses a key
        //this way we don't try running our search function for every key pressed.
        var timeout;
        $('body').on('keypress','#searchTerm',function() {         
            
            if(timeout) {
                clearTimeout(timeout);
                timeout = null;
            }        
            timeout = setTimeout(function(){
                helper.runSearch(component);
            }, 500)
        })
        
    },
    runSearch : function(component,event,helper)
    {
        helper.runSearch(component);
    }
})