({
	doInit : function(component) {
    let evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
        componentDef : "c:DramaticDrawings",
        componentAttributes: {
            prizeId : component.get("v.recordId"),
            isredirect : true
        }
    });
    evt.fire();
	},
})