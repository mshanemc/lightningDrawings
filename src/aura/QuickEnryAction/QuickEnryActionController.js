({
	save : function(component) {
		//	global static contact easyEntryContact (string first, string last, id contestId){

		let action = component.get("c.easyEntryContact");
		action.setParams({
			"first" : component.get("v.first"),
			"last" : component.get("v.last"),
			"contestId" : component.get("v.recordId")
		});
		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				console.log(a);
				$A.get("e.force:showToast").setParams({"message" : "Success!  Next, Attach a photo to contact", "type" : "Success"}).fire();
				$A.get("e.force:navigateToSObject").setParams({"recordId": a.getReturnValue().Id, "slideDevName" : "chatter"}).fire();

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