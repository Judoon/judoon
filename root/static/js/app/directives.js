/*jshint globalstrict: true */
/*global angular, CKEDITOR */

'use strict';

var judoonDir = angular.module('judoon.directives', []);


/**  Judoon Data Table

 This directive binds our data api to a jQuery DataTables datatable.

**/

judoonDir.directive('judoonDataTable', ['$timeout', function($timeout) {
    return {
        restrict    : 'E',
        replace     : true,
        templateUrl : '/static/html/partials/judoon-data-table.html',
        transclude  : false,
        scope       : {
            columns         : '=jdtColumns',
            colDefs         : '=jdtColDefs',
            dataUrl         : '=jdtDataUrl',
            highlightActive : '&highlightActive',
            highlightDelete : '&highlightDelete'
        },
        link: function(scope, element, attrs) {

            var dataTable;
            var defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "sAjaxSource"     : scope.dataUrl,
                "sAjaxDataProp"   : "tmplData"
            };

            function rebuildTable() {
                if (dataTable) {
                    dataTable.fnDestroy();
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions.aoColumns = scope.colDefs;
                dataTable = element.dataTable(tableOptions);
            }

            // columns may not be available at link time
            scope.$watch('columns', function() {
                if (!scope.columns || !scope.columns.length) {
                    return; // too soon.
                }

                // run rebuild table after digest
                $timeout(function() { rebuildTable(); }, 0, false);
            }, true);
        }
    };
}]);


judoonDir.directive('judoonCkeditor', [function() {
    return {
        link: function(scope, elm, attr) {
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
                        { name: 'groups',    items: ["NumberedList", "BulletedList", "DefinitionList", "Outdent", "Indent", "Blockquote"] },
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
                var ck;
                if (scope.editmode == 1) {
                    ck = CKEDITOR.inline(elm[0], ckConfig);
                    elm.data('editor', ck);
                }
                else {
                    ck = elm.data('editor');
                    if (ck) {
                        ck.destroy();
                    }
                }
            });

        }
    };
}]);


judoonDir.directive(
    'judoonFileInput',
    ['$timeout', function($timeout) {
        return {
            restrict    : 'E',
            replace     : true,
            templateUrl : '/static/html/partials/judoon-file-input.html',
            scope       : { inputName : '@' },
            link        : function(scope, elem, attrs) {
                elem.find('input[type="file"]').attr('name', attrs.inputName);
                elem.find('.fake-uploader').click(function() {
                    elem.find('input[type="file"]').click();
                });
            },
            controller: ['$scope', function ($scope) {
                $scope.setFile = function (elem) {
                    $scope.filePath = elem.files[0].name;
                    $scope.$apply();
                };
            }]
        };
    }]
);

judoonDir.directive(
    'judoonWidgetFactory',
    ['$compile', function($compile) {
        return {
            restrict: 'E',
            replace: true,
            template: '<div class="widget-object input-append dropdown"></div>',
            link: function(scope, element, attrs) {
                element.append('<judoon-'+scope.widget.type+'-widget widget="widget">');
                if (scope.widget.type !== 'newline' && scope.widget.type !== 'image') {
                    element.append('<judoon-formatting-widget>');
                }
                $compile(element.contents())(scope);
            }
        };
    }]
);

judoonDir.directive(
    'judoonTextWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-text.html'
        };
    }]
);

judoonDir.directive(
    'judoonVariableWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-variable.html'
        };
    }]
);

judoonDir.directive(
    'judoonNewlineWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-newline.html'
        };
    }]
);

judoonDir.directive(
    'judoonLinkWidget',
    ['$modal', function($modal) {
        function link(scope, elem, attrs) {

            function openLinkBuilder(widget) {
                var modalInstance = $modal.open({
                    resolve: {
                        currentLink: function() {
                            return {
                                url:   angular.copy(widget.url),
                                label: angular.copy(widget.label)
                            };
                        },
                        columns: function() {
                            return {
                                all:        scope.dataset.columns,
                                accessions: scope.ds_columns.accessions,
                                dict:       scope.ds_columns.dict
                            };
                        },
                        siteLinker: function() { return scope.siteLinker; }
                    },
                    templateUrl:  '/static/html/partials/widget-link-builder.html',
                    controller: 'LinkBuilderCtrl'
                });

                modalInstance.result.then(
                    function (linkProps) {
                        widget.url   = linkProps.url;
                        widget.label = linkProps.label;
                    }
                );
            }

            angular.element(elem.find('input')).on(
                'click', function () {
                    openLinkBuilder(scope.widget);
                    scope.$apply();
                }
            );
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-link.html',
            link: link
        };
    }]
);

judoonDir.directive(
    'judoonImageWidget',
    ['$modal', function($modal) {
        function link(scope, elem, attrs) {

            function openImageBuilder(widget) {
                var modalInstance = $modal.open({
                    resolve: {
                        currentImage: function() {
                            return {
                                url:   angular.copy(widget.url),
                            };
                        },
                        columns: function() {
                            return {
                                all:  scope.dataset.columns,
                                dict: scope.ds_columns.dict
                            };
                        }
                    },
                    templateUrl:  '/static/html/partials/widget-image-builder.html',
                    controller: 'ImageBuilderCtrl'
                });

                modalInstance.result.then(
                    function (imageProps) {
                        widget.url   = imageProps.url;
                    }
                );
            }

            angular.element(elem.find('input')).on(
                'click', function () {
                    openImageBuilder(scope.widget);
                    scope.$apply();
                }
            );
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-image.html',
            link: link
        };
    }]
);



judoonDir.directive(
    'judoonFormattingWidget',
    [function() {

        function link(scope, elem, attrs) {

            function toggleFormatting(format) {
                var idx = scope.widget.formatting.indexOf(format);
                if (idx === -1) {
                    scope.widget.formatting.push(format);
                }
                else {
                    scope.widget.formatting.splice(idx, 1);
                }
                return;
            }
            function toggleFormattingBold()   { toggleFormatting('bold');   }
            function toggleFormattingItalic() { toggleFormatting('italic'); }

            function deleteWidget() {
                scope.$parent.removeNode(scope.widget);
            }

            var actions = elem.find('ul').find('a');
            angular.element(actions[0]).on('click', function() { toggleFormattingBold();   scope.$apply(); });
            angular.element(actions[1]).on('click', function() { toggleFormattingItalic(); scope.$apply(); });
            angular.element(actions[2]).on('click', function() { deleteWidget();           scope.$apply(); });
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-formatting.html',
            link: link
        };
    }]
);


judoonDir.directive(
    'judoonLinkBuilderWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-link-builder.html'
        };
    }]
);
