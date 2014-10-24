angular.module('WhosIn', []).controller('AppCtrl', function($scope, $http){

	$scope.testing = 'hello'

	$http.get('/people').success(function(data){
		console.log(data);
		$scope.people = data;
	});

});