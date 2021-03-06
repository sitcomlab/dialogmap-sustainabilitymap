angular.module("DialogMapApp").directive "loading", [
  "$http"
  ($http) ->
    restrict: "A"
    link: (scope, elm, attrs) ->
      scope.isLoading = ->
        $http.pendingRequests.length > 0

      scope.$watch scope.isLoading, (v) ->
        if v
          elm.css('background-position', '0px 0px')
        else
          elm.css('background-position', '0px -5px')
        return

      return
]
