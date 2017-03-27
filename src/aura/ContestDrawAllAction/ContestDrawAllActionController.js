({
	doInit : function(component) {
		//	global static void drawAll(string contestId){

		let action = component.get("c.drawAll");
		action.setParams({
			"contestId" : component.get("v.recordId")
		});
		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				console.log(a);
				let toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title" : "Drawing Started",
					"message" : 'Reload the page to see the results.  It may take a few tries.',
					"type" : "success",
				});
				toastEvent.fire();
				$A.get("e.force:refreshView").fire();
				$A.get("e.force:closeQuickAction").fire();

			}  else if (state === "ERROR") {
				let appEvent = $A.get("e.c:handleCallbackError");
				appEvent.setParams({
					"errors" : a.getError()
				});
				appEvent.fire();
			}
		});
		$A.enqueueAction(action);
	}
})