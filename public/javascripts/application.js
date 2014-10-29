angular.module('WhosIn', ['pusher-angular', 'ui.bootstrap']).controller('AppCtrl', function($scope, $pusher, $http){

	var client = new Pusher('5b38b811cbe170b81ea1');
	var pusher = $pusher(client);
	var peopleChannel = pusher.subscribe('people_channel');

	peopleChannel.bind('people_event', function(data){
		$scope.people = data;
		$scope.people.push("");
		console.log(data);
	});

	$scope.user = {
		"name": "Jamie",
		"mac address": "84:7A:88:5C:A2:F7",
		"email address": "jamie@pusher.com"
	};

	$scope.createNewUser = function(){
		console.log("creating user...")
		$http.post('/users/new', $scope.user).then(function(){ $scope.user = {} })
	};

	$scope.fields = [
		"Name",
		"MAC Address",
		"Email Address"
	];

	$scope.shouldCreateGap = function(index){
		var range = _.range(1, 100)
		var turningPoints = _.map(range, function(number){
			// return (2*number) + Math.ceil(number / 2)
			// return (5*number) - 2
			return (7*number) - 3
		});
		return _.contains(turningPoints, index)
	};


});

