/* globals d3 */
/* globals _ */

({
	doInit : function(component, undefined, helper) {
		//basic geometry setup for responsive layout
		//const thisComp = document.getElementsByClassName('dramatic')[0];
		const thisComp = component.find('dramaticDrawingHolder').getElement();
		const width = thisComp.offsetWidth;
		const height = thisComp.offsetHeight;
		const center = {x: width / 2, y: height / 2};
		const hw = height/width; //save calc later

		const ticksPerSecond = 15; //reasonably performant on my machine.  Adjust if not.
		const speed = 1000/ticksPerSecond;
		//const expectedLoops = component.get("v.duration")*ticksPerSecond;

		//d3 constants
		const gravityToChargeRatio = 1.5;
		const forceStrength = 0.1;

		let svg = d3.select(".dramatic")
			.append('svg')
			.attr('width', width)
			.attr('height', height);

		//variables for use later
		let safetyValve = 0;
		let intervalCounter = 0;
		let winnerSaved = 'No';
		let nodes = [];
  	let bubble, img, label, simulation, reducer, decay, originalNodes, globalRadius = null;

  	//load the image and name for this prize.  Doesn't have to interact with anything else in this bloated controller
		helper.loadPrizeDetails(component);

  	//getting data from Salesforce
		let action = component.get("c.drawLocallySingle");
		action.setParams({
			"prizeId" : component.get("v.prizeId")
		});

		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				let results = JSON.parse(a.getReturnValue());
				//console.log(results);
				decay = (Math.log(1/results.length))/(component.get("v.duration")*ticksPerSecond);
				originalNodes = results.length;

				globalRadius = (height/2)/Math.sqrt(results.length);
				nodes = helper.nodeBuilder(results, globalRadius, height, width);



				bubble = svg.append("g")
					.attr("class", "bubbles")
					.selectAll("circle")
					.data(nodes)
					.enter()
						.append("circle")
							.attr("class", "bubble")
							.attr('r', globalRadius)
				      .attr('fill', "grey")
			  ;

			  img = svg.select("g")
			  	  .selectAll("image")
			  	  .data(nodes, function(d){return d.id;})
			  		.enter()
		  			.append("image")
			  			.attr("class", "image")
					  	.attr("xlink:href", function(d){return d.image;})
				;

			  label = svg.append("g")
			  	.attr("class", "label")
			  	.selectAll("text")
			  	.data(nodes, function(d){return d.id;})
			  	.enter().append("text")
			  		.attr("class", "username")
			  		.text(function(d){return d.name;})
      			.attr("fill", "black")
      	;

				simulation = d3.forceSimulation()
  				.nodes(nodes)
  				.alphaDecay(0)
  				.force('x', d3.forceX().strength(forceStrength*gravityToChargeRatio*(hw)).x(center.x))
		  		.force('y', d3.forceY().strength(forceStrength*gravityToChargeRatio).y(center.y))
					.force('charge', d3.forceManyBody().strength(charge))
				  .on('tick', ticked)
			  ;


			  //now, start the removal loop
			  reducer = setInterval($A.getCallback(function(){
			  	//console.log(winnerSaved);
			  	//console.log(nodes.length);
			  	//console.log(safetyValve);
			  	if (nodes.length>1 && safetyValve<1200){
						//console.log("do a tick");
						if (Math.round(originalNodes * Math.pow((1+decay), intervalCounter))===nodes.length){
							intervalCounter++;
						} else { //go through the removal/redraw process
							nodes = removeNode(nodes);
							safetyValve++;
					  	//redraw labels
					  	label = label.data(nodes, function(d){return d.id;});
					  	label.exit().remove();
					  	label = label.enter()
								.append("text").attr("class", "username").text(function(d){return d.name;}).attr("fill", "black").merge(label);
					  	//redraw bubble
					  	bubble = bubble.data(nodes, function(d){return d.id;});
					  	bubble.exit().remove();
					  	bubble = bubble.enter()
					  		.append("circle").attr("class", "bubble").attr('r', globalRadius).attr('fill', "grey")
					  		//.attr('stroke', "black").attr('stroke-width', 2)
					  		.merge(bubble);
					  	//redraw image
					  	img = img.data(nodes, function(d){return d.id;});
					  	img.exit().remove();
					  	img = img.enter()
					  		.append("image").attr("class", "image").attr("xlink:href", function(d){return d.image;}).attr("width", globalRadius*2).attr("height", globalRadius*2)
					  		.merge(img);
							simulation.nodes(nodes);

						}
					} else if (winnerSaved==='Pending'){
						//console.log("in pending");
						//do nothing...just waiting for apex to call back
					} else if (winnerSaved==='Saved'){
						//console.log("Saved!");
						//do nothing...just waiting for apex to call back
					} else if (nodes.length===1){
						//console.log("down to one");
						simulation
							.stop();
						//set the winner 	global static void setWinner (string prizeId, string entryId){
						let saveTheWinner = component.get("c.setWinner");
						saveTheWinner.setParams({
							"prizeId" : component.get("v.prizeId"),
							"entryId" : nodes[0].sfId
						});

						saveTheWinner.setCallback(this, function(b){
							//console.log("action back");
							let state = b.getState();
							if (state === "SUCCESS") {
								//console.log(b);
								let toastEvent = $A.get("e.force:showToast");
								toastEvent.setParams({
									"message": "Winner saved!"
								});
								toastEvent.fire();
								winnerSaved = 'Saved';
								component.set("v.awarded", true);
								clearInterval(reducer);
							} else if (state === "ERROR") {
								component.find('leh').passErrors(a.getError());
							}
						});
						$A.enqueueAction(saveTheWinner);
						//console.log("action sent");
						winnerSaved = 'Pending';

					} else {
			  		simulation.stop();
			  		//console.log("no winner due to error");
			  		clearInterval(reducer);
					}
		  	}) , speed);


			} else if (state === "ERROR") {
				component.find('leh').passErrors(a.getError());
			}
		});
		$A.enqueueAction(action);

		function charge() {
		  return -forceStrength * Math.pow(globalRadius, 2.0);
		}

		function ticked() {
		  bubble
		  	.attr("cx", function(d) { return d.x; })
		  	.attr("cy", function(d) { return d.y; })
		  	.attr("r", globalRadius)
		  ;
		  label
		  	.attr("x", function(d) { return d.x; })
		  	.attr("y", function(d) { return d.y + globalRadius/2; })
		  	.attr("font-size", globalRadius/4 + "px")
		  ;
		  img
		  	.attr("x", function(d) { return d.x - globalRadius;})
		  	.attr("y", function(d) { return d.y - globalRadius;})
		  	.attr("width", globalRadius*2)
		  	.attr("height", globalRadius*2)
		  	.style("clip-path", "circle(" + globalRadius + "px at " + globalRadius + "px " + globalRadius + "px)")
		  ;
		}

		function removeNode(input){
			intervalCounter++;
			//calculate how many nodes there *should* be right now?
			let targetNodes = Math.round(originalNodes * Math.pow((1+decay), intervalCounter));
			//console.log("Nodes... on iteration " + intervalCounter +" I have " + input.length + " but want " + targetNodes);
			//sample that many nodes from the population
			let output =  _.sampleSize(input, targetNodes);

			//update the radius!
			globalRadius = Math.min(height/5, height/1.4/Math.sqrt(output.length));
			for (let thisNode of output){
				thisNode.radius = globalRadius;
			}
			return output;
		}

	},

	navToRecord : function(component) {
		let navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({"recordId" : component.get("v.prizeId")});
		navEvt.fire();
	},

	destoryCmp : function (component) {
    component.destroy();
  },

})