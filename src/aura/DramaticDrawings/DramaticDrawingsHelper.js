/* globals d3 */
({
	getPhoto : function(node) {
		if (node.drawings__User__r){
			if (node.drawings__User__r.MediumPhotoUrl){
				return node.drawings__User__r.MediumPhotoUrl;
			} else {
				return node.drawings__User__r.SmallPhotoUrl;
			}
		} else {
			return null;
		}
	},

	nodeBuilder : function(results, globalRadius, height, width) {
		//console.log(results);
		let helper = this;
		let nodes = [];
		let idGenerator = 0;

		for (let node of results){
			nodes.push({
				name: node.drawings__Entrant_Name__c,
				value: 1,
				radius: globalRadius,
				x: Math.random() * width,
				y: Math.random() * height,
				id: idGenerator,
				image : helper.getPhoto(node),
				sfId : node.Id
			});
			idGenerator++;
		}
		//console.log(nodes);
		return nodes;
	},

	loadPrizeDetails : function(component) {
		let prizeDetails = component.get("c.getLocalPrize");

		prizeDetails.setParams({
			"prizeId" : component.get("v.prizeId")
		});

		prizeDetails.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				let prizeResult = a.getReturnValue();
				console.log(prizeResult);
				component.set("v.prize", prizeResult);
				if (prizeResult.drawings__Prize_Image__c){
					d3.select(".dramatic").attr('style', 'background-image : url("'+prizeResult.drawings__Prize_Image__c+'")');
				}
			} else if (state === "ERROR") {
				let appEvent = $A.get("e.c:handleCallbackError");
				appEvent.setParams({
					"errors" : a.getError()
				});
				appEvent.fire();
			}
		});

		$A.enqueueAction(prizeDetails);

	},

})