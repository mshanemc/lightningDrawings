({
	doInit : function(component) {
		//	public static list<string> drawThisPrize(string prizeId){
		let action = component.get("c.drawSinglePrize");
		action.setParams({
			"prizeId" : component.get("v.recordId")
		});
		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				console.log(a);
				let toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title" : "Winner",
					"message" : a.getReturnValue(),
					"type" : "success",
				});
				toastEvent.fire();
				$A.get("e.force:refreshView").fire();
				$A.get("e.force:closeQuickAction").fire();
			}  else if (state === "ERROR") {
				component.find('leh').passErrors(a.getError());
				$A.get("e.force:closeQuickAction").fire();
			}
		});
		$A.enqueueAction(action);
	}
})