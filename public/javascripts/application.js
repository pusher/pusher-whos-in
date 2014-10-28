angular.module('WhosIn', ['pusher-angular']).controller('AppCtrl', function($scope, $pusher, $http){

	var client = new Pusher('5b38b811cbe170b81ea1');
	var pusher = $pusher(client);
	var peopleChannel = pusher.subscribe('people_channel');

	peopleChannel.bind('people_event', function(data){
		$scope.people = data;
	});

	$scope.user = {
		"name": "Jamie",
		"mac address": "84:7A:88:5C:A2:F7",
		"email address": "jamie@pusher.com"
	};

	$scope.createNewUser = function(){
		$http.post('/users/new', $scope.user)
	};

	// $scope.$watch('user', function(){
	// 	console.log($scope.user)
	// }, true);


	$scope.fields = [
		"Name",
		"MAC Address",
		"Email Address"
	];


});

