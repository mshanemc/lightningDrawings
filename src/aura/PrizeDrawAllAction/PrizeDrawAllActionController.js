({
	doInit : function(component) {
		let action = component.get("c.drawThisPrize");
		action.setParams({
			"prizeId" : component.get("v.recordId")
		});
		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				//console.log(a.getReturnValue());
				let toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title" : "Winners",
					"message" : a.getReturnValue().join(),
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