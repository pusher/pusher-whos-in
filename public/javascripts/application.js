angular.module('WhosIn', ['pusher-angular']).controller('AppCtrl', function($scope, $pusher){

	var client = new Pusher('5b38b811cbe170b81ea1');
	var pusher = $pusher(client);
	var peopleChannel = pusher.subscribe('people_channel');

	peopleChannel.bind('people_event', function(data){
		$scope.people = data;
	});

});