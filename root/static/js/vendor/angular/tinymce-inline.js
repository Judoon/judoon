/**
 * Binds a TinyMCE widget to inline elements.
 * This is a rewrite based on the iframe version. This version is better able to handle reordering
 * and deletion of items.
 */
angular.module('ui.tinymce.inline', [])
    .value('uiTinymceConfig', {})
    .directive('uiTinymceInline', ['uiTinymceConfig', function (uiTinymceConfig) {
        uiTinymceConfig = uiTinymceConfig || {};
        var generatedIds = 0;
        return {
            require: 'ngModel',
            link: function (scope, elm, attrs, ngModel) {
                var expression, options, tinyInstance,
                    updateModel = function(editor) {
                        ngModel.$setViewValue(editor.getContent());
                        if (!scope.$$phase) {
                          scope.$apply();
                        }
                    }
                ;

                // generate an ID if not present
                if (!attrs.id) {
                    attrs.$set('id', 'uiTinymce' + generatedIds++);
                }

                if (attrs.uiTinymceInline) {
                    expression = scope.$eval(attrs.uiTinymceInline);
                } else {
                    expression = {};
                }
                options = {
                    // Update model when calling setContent (such as from the source editor popup)
                    setup: function (ed) {
                        var args;
                        ed.on('init', function (args) {
                            ngModel.$render();
                            if (options.onInit) {
                                options.onInit(elm);
                            }
                        });
                        // Update model on button click
                        ed.on('ExecCommand', function (e) {
                            updateModel(ed);
                        });
                        // Update model on keypress
                        ed.on('KeyUp', function (e) {
                            updateModel(ed);
                        });
                        // Update model on change, i.e. copy/pasted text, plugins altering content
                        ed.on('SetContent', function (e) {
                            // @TODO (gunnar): I don't quite know when this is called, or what we should do, may not be needed.
                        });
                        if (expression.setup) {
                            scope.$eval(expression.setup);
                            delete expression.setup;
                        }
                    },

                    mode: 'exact',
                    inline: true,
                    elements: attrs.id
                };
                // extend options with initial uiTinymceConfig and options from directive attribute value
                angular.extend(options, uiTinymceConfig, expression);
                setTimeout(function () {
                    tinymce.init(options);
                });

                ngModel.$render = function () {
                    if (!tinyInstance) {
                        tinyInstance = tinymce.get(attrs.id);
                    }
                    if (tinyInstance) {
                        tinyInstance.setContent(ngModel.$viewValue || '');
                    }
                };
            }
        };
    }]);
