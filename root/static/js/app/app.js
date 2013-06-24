var judoonApp = angular.module('judoon', ['ngSanitize']);

    judoonApp.directive('judoonTable', function() {
        return function(scope, element, attrs) {
            scope.$watch('page', function() {
                if (!scope.page.columns) {
                    return;
                }

                // apply DataTable options, use defaults if none specified by user
                var options = {
                    "bAutoWidth": false,
                    "bServerSide": true,
                    "bProcessing" : true,
                    "sPaginationType": "bootstrap"
                };

                options["aoColumns"] = [];
                for (idx in scope.page.columns) {
                    options["aoColumns"][idx] = scope.page.columns[idx].title;
                }

                options["sAjaxSource"] = "/api/datasetdata/" + scope.page.dataset_id;
                options["fnServerData"] = scope.getServerData;

                // apply the plugin
                var dataTable = element.dataTable(options);
            });
        };
    });


CKEDITOR.plugins.registered['save'] = {
  init: function(editor) {
    var command = editor.addCommand('save', {
      modes: {wysiwyg: 1, source: 1},
      readOnly: 1,
      exec: function(editor) {
        editor.fire('save');
      }
    });

    editor.ui.addButton('Save', {
      label : editor.lang.save,
      command : 'save'
    });
  }
};

    judoonApp.directive('judoonCk', function() {
        return {
            require: '?ngModel',
            link: function(scope, elm, attr, ngModel) {
                var ckConfig;
                if (attr.ckEditType === "inline") {
                    ckConfig = {
                        toolbar: [
                            { name: 'formatting', items: ["Bold", "Italic", "Underline", "Strike", "Subscript", "Superscript", "RemoveFormat",'-','Undo','Redo'] }
                        ],
                        height: '3em',
                        removePlugins: 'elementspath',
                        resize_enabled: false,
                        contentsCss: ''
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
                        extraAllowedContent: 'ul ol li dl dd dt',
                        contentsCss: ''

                    };
                }

                var ck = CKEDITOR.replace(elm[0], ckConfig);

                if (!ngModel) return;

                ck.on('save', function() {
                    scope.$apply(function() {
                        ngModel.$setViewValue(ck.getData());
                    });
                });
            }
        };
    });
