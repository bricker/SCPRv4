/*
* Dialogue to add Embed placeholders.
*
* Plugin name:      embed-placeholder
* Menu button name: EmbedPlaceholder
*
* @author Bryan Ricker / SCPR
* @version 0.1
*/


(function() {
    var pluginName = 'embed-placeholder',
        dialogName = 'embed-placeholder-dialog',
        command    = 'openEmbedPlaceholderDialog',
        button     = 'EmbedPlaceholder', // icon must match this, lowercased.
        icon       = 'embedplaceholder';


    CKEDITOR.plugins.add(pluginName, {
      hidpi: true,
      icons: icon,

      init: function(editor) {
        var plugin = this;

        CKEDITOR.dialog.add(dialogName, function (instance) {
          return {
            title       : 'Embed Placeholder',
            minWidth    : 550,
            minHeight   : 200,

            contents : [
              {
                id        : 'embed',
                label     : 'Embed Info',
                elements  : [
                  {
                    id : "alphaWarning",
                    type : 'html',
                    html : '<span style="color:#ff0000"><strong>' +
                           'This feature is in beta. Please report any ' +
                           'problems.</strong></span>'
                  }, // alphaWarning
                  {
                    id          : 'embedUrl',
                    type        : 'text',
                    label       : '<strong>oEmbed URL</strong> (<a href="' +
                                  'https://github.com/SCPR/oembed-manual' +
                                  '/tree/master/services#readme' +
                                  '" target="_blank">Help</a>)',
                    autofocus   : 'autofocus',

                    validate : function() {
                      if(!this.getValue()) {
                        alert("URL can't be empty.")
                        return false
                      }
                    } // validate
                  }, // embedUrl
                  {
                    id      : 'embedService',
                    type    : 'select',
                    label   : '<strong>Service</strong><br />' +
                            '<span style="color:#ff0000">' +
                            'If a service is not listed here, then it is ' +
                            'not officially supported. You may select ' +
                            '"Other" to try it out.</span>',
                    items   : [
                      ['Select a Service:', ''],
                      ['Brightcove', 'brightcove'],
                      ['Cover It Live', 'coveritlive'],
                      ['DocumentCloud', 'documentcloud'],
                      ['Facebook', 'facebook'],
                      ['Fire Tracker', 'firetracker'],
                      ['Google Maps', 'googlemaps'],
                      ['Instagram', 'instagram'],
                      ['Polldaddy', 'polldaddy'],
                      ['RebelMouse', 'rebelmouse'],
                      ['Scribd', 'scribd'],
                      ['SoundCloud', 'soundcloud'],
                      ['Spotify', 'spotify'],
                      ['Storify', 'storify'],
                      ['Twitter', 'twitter'],
                      ['Ustream', 'ustream'],
                      ['Vimeo', 'vimeo'],
                      ['Vine', 'vine'],
                      ['YouTube', 'youtube'],
                      ['Other (Embedly)', 'other']
                    ], // items

                    validate : function() {
                      if(!this.getValue()) {
                        alert("Service can't be empty.")
                        return false
                      }
                    } // validate
                  }, // embedService
                  {
                    id      : 'linkTitle',
                    type    : 'text',
                    label   : 'Link Title (optional) ' +
                              '<span style="color:#ff0000">' +
                              'The URL will be used if no title is ' +
                              'specified.</span>'
                  } // linkTitle
                ] // elements
              }, // embed
              {
                id        : 'embed-advanced',
                label     : 'Advanced',
                elements  : [
                  {
                    id      : 'embedMaxHeight',
                    type    : 'text',
                    label   : 'Embed Maximum Height (Optional)<br />' +
                                  '<span style="color:#ff0000">' +
                                  'This parameter is not honored by all ' +
                                  'embeds. It is recommended that you ' +
                                  'leave it blank unless necessary.</span>',
                    width   : '45px',
                    onLoad: function() {
                      $('input', '#'+this.domId).after(' <strong>px</strong>')
                    }
                  } // embedMaxHeight
                ] // elements
              }, // embed-advanced
            ], // contents

            onOk: function() {
              var url         = this.getContentElement(
                                  'embed', 'embedUrl'
                                ).getValue().trim(),

                  title       = this.getContentElement(
                                  'embed', 'linkTitle'
                                ).getValue(),

                  maxheight   = this.getContentElement(
                                  'embed-advanced', 'embedMaxHeight'
                                ).getValue(),

                  service     = this.getContentElement(
                                  'embed', 'embedService'
                                ).getValue();

              if(title === "") title = url;

              var p           = editor.document.createElement('p'),
                  markBegin   = "<!-- EMBED PLACEHOLDER: " + url + " -->",
                  markEnd     = "<!-- END PLACEHOLDER -->";

              var tagProps = {
                'href'    : url,
                'class'   : "embed-placeholder",
                'title'   : title,
                'text'    : title
              }

              if(maxheight !== "") tagProps['data-maxheight'] = maxheight;
              if(service !== "") tagProps['data-service'] = service;

              var tag  = $("<a />", tagProps),
                  html = [markBegin,tag[0].outerHTML,markEnd].join("")

              p.setHtml(html)
              instance.insertElement(p)
            } // onOk
          }; // return
        }); // dialog.add


        editor.addCommand(command,
          new CKEDITOR.dialogCommand(dialogName, {
            allowedContent: 'a[*](*)'
          })
        )

        editor.ui.addButton(button, {
          label     : 'Embed Placeholder',
          command   : command
        })
      } // init
    }) // plugins.add
})() // closure
