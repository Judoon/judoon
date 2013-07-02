var judoonApp = angular.module('judoon', ['ngSanitize','judoonServices']);
judoonApp.config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider
        .when('/user/:userName/fancy/page/:pageId', {templateUrl: '/static/html/partials/page.html', controller: PageCtrl})
        .otherwise({redirectTo: '/'});
}]);


judoonApp.directive('judoonTable', function($timeout) {
    return {
        link: function($scope, element, attrs) {

            var dataTable;
            var defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "fnServerData"    : $scope.getServerData
            };

            var dataset_id;

            function rebuildTable() {
                if (dataTable) {
                    dataTable.fnDestroy();
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions["aoColumns"] = [];
                angular.forEach($scope.pageColumns, function (value, key) {
                    tableOptions["aoColumns"][key] = value.title;
                } );

                dataTable = element.dataTable(tableOptions);
            }


            $scope.$watch('pageLoaded', function() {
                if (!$scope.pageLoaded) {
                    return;
                }

                // this won't change over life of the directive
                defaultOptions["sAjaxSource"] = "/api/datasetdata/" + $scope.page.dataset_id;
            });

            $scope.$watch('pageColumns', function() {
                if (!$scope.pageLoaded) {
                    return; // too soon.
                }

                // run rebuild table after digest
                $timeout(function() { rebuildTable(); }, 0, false);
            }, true);
        }
    };
});

judoonApp.directive('judoonCk', function() {
    return {
        require: '?ngModel',
        link: function(scope, elm, attr, ngModel) {
            var ckConfig;
            if (attr.ckEditType === "inline") {
                ckConfig = {
                    toolbar: [
                        { name: 'formatting', items: ["Bold", "Italic", "Underline", "Strike", "Subscript", "Superscript", "RemoveFormat",'-','Undo','Redo'] }
                    ]
                };
            }
            else {
                ckConfig = {
                    toolbar: [
                        { name: 'clipboard', items: ['Cut','Copy','Paste','PasteText','PasteWord','-','Undo','Redo'] },
                        { name: 'editing',   items: ['Find','Replace','-','SelectAll','-','Scayt'] },
                        { name: 'links',     items: ['Link','Unlink','Anchor'] },
                        { name: 'insert',    items: ['Image', 'Table', 'HorizontalRule', 'SpecialChar'] },
                        { name: 'groups',    items: ["NumberedList", "BulletedList", "DefinitionList", "Outdent", "Indent", "Blockquote", ] },
                        '/',
                        { name: 'formatting', items: ["Bold", "Italic", "Underline", "Strike", "Subscript", "Superscript", "RemoveFormat"] },
                        { name: 'paragraph',  items: ["JustifyLeft", "JustifyCenter", "JustifyRight", "JustifyBlock" ] },
                        { name: 'styles',     items: ["Format", "Font", "FontSize", "TextColor", "BGColor" ] },
                        { name: 'about',      items: ["About"] }
                    ],
                    removePlugins: 'smiley,flash,iframe,pagebreak',
                    extraAllowedContent: 'h5 h6 ul ol li dl dd dt'
                };
            }

            scope.$watch('editmode', function() {
                if (scope.editmode == 1) {
                    elm.attr('contenteditable', 'true');

                    var ck = CKEDITOR.inline(elm[0], ckConfig);
                    elm.data('editor', ck);

                    if (!ngModel) return;

                    // ck.on('pasteState', function() {
                    //     scope.$apply(function() {
                    //         ngModel.$setViewValue(ck.getData());
                    //     });
                    // });

                    ngModel.$render = function() {
                        ck.setData(ngModel.$viewValue);
                    };

                    // load init value from DOM
                    ngModel.$render();
                }
                else {
                    var ck = elm.data('editor');
                    if (ck) {
                        ngModel.$setViewValue(ck.getData());
                        ck.destroy();
                    }

                    elm.attr('contenteditable', 'false');
                }
            });

        }
    };
});
