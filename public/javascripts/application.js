angular.module('WhosIn', ['pusher-angular']).controller('AppCtrl', function($scope, $pusher, $http){

	var client = new Pusher('5b38b811cbe170b81ea1');
	var pusher = $pusher(client);
	var peopleChannel = pusher.subscribe('people_channel');

	peopleChannel.bind('people_event', function(data){
		$scope.groups = data;
		$scope.people = data;
		console.log(data);
	});

	$scope.user = {
		"name": "Jamie",
		"mac address": "84:7A:88:5C:A2:F7",
		"email address": "jamie@pusher.com"
	};

	$scope.createNewUser = function(){
		$http.post('/users/new', $scope.user).then(function(){ $scope.user = {} })
	};

	$scope.fields = [
		"Name",
		"MAC Address",
		"Email Address"
	];


	var eachSlice = function(array, size, callback){
		for(var i = 0, l = array.length; i < l; i += size){
			callback(array, array.slice(i, i+size));
		}
	}


});

