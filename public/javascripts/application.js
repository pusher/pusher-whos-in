angular.module('WhosIn', ['pusher-angular']).controller('AppCtrl', function($scope, $http, $pusher){

	$scope.testing = 'hello'

	$http.get('/people').success(function(data){
		console.log(data);
		$scope.people = data;
	});

	var client = new Pusher('5b38b811cbe170b81ea1');
	var pusher = $pusher(client);
	var peopleChannel = pusher.subscribe('people_channel');

	peopleChannel.bind('people_event', function(data){
		// console.log(data);
		$scope.people = data;
	})

});