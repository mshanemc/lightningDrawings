({

	processErrors : function(errors) {
		let helper = this;

		if (errors) {
			let showTopLevelError = true;
			errors.forEach( function (error){
				//TODO: handle potential duplicate rules

				//page-level errors (validation rules, etc)
				if (error.pageErrors){
					error.pageErrors.forEach( function(pageError) {
						helper.toastThis(pageError.message);
						showTopLevelError = false;
					});

				}

				if (error.fieldErrors){
					//field specific errors--we'll say what the field is
					for (let fieldName in error.fieldErrors) {
						//each field could have multiple errors
						error.fieldErrors[fieldName].forEach( function (errorList){
							helper.toastThis(errorList.message, "Field Error on " + errorList.fieldLabel + " : ");
							showTopLevelError = false;
						});
					}  //end of field errors forLoop
				} //end of fieldErrors if

				//top-level error.  there can be only one
				if (error.message && showTopLevelError){
					helper.toastThis(error.message);
				}
			}); //end Errors forEach
		}
	},

	toastThis : function(message, title) {
		let toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": title || "Error:",
			"message": message,
			"type": "error",
			"mode": "sticky"
		});
		toastEvent.fire();
	}
})