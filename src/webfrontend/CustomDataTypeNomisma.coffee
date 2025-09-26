class CustomDataTypeNomisma extends CustomDataTypeWithCommonsAsPlugin

  #######################################################################
  # return the prefix for localization for this data type.
  # Note: This function is supposed to be deprecated, but is still used 
  # internally and has to be used here as a workaround because the 
  # default generates an incorrect prefix for camelCase 
  getL10NPrefix: ->
    'custom.data.type.nomisma'

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-nomisma.nomisma"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.nomisma.name")

  #######################################################################
  # support geostandard in frontend?
  supportsGeoStandard: ->
    return false
    

  #######################################################################
  # configure used facet
  getFacet: (opts) ->
    opts.field = @
    new CustomDataTypeNomismaFacet(opts)

  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5?.loca?.getLanguage()
    if desiredLanguage
      desiredLanguage = desiredLanguage.split('-')
      desiredLanguage = desiredLanguage[0]
    else
      desiredLanguage = false

    desiredLanguage
    
   
  #######################################################################
  # get more info about record
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->

    that = @
    uri = decodeURIComponent uri
    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    # extract nomisma-id from URI
    nomismaID = NomismaUtil.getNomismaIDFromURI uri
    nomismaType = NomismaUtil.getNomismaTypeFromURI uri

    # get record by uri
    path = location.protocol + '//uri.gbv.de/terminology/' + nomismaType + '/' + nomismaID + '?format=json'

    extendedInfo_xhr.xhr = new (CUI.XHR)(url: path)
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="font-weight: bold; padding: 3px 6px;">' + $$('custom.data.type.goobi.config.parameter.mask.infopopup.popup.info') + '</span>'
      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'
      if data?.uri
        for key, value of data
          if key != '@context' && key != 'inScheme' && key != 'depiction' && key != 'notation' && key != 'Moodifizierungsdatum' && key != 'uri'
            keyUpperCased = key.charAt(0).toUpperCase() + key.slice(1);
            htmlContent += '<tr><td style="min-width:150px;"><b>' + keyUpperCased + ':</b></td><td>'
            for entry, key2 in value
              htmlContent += entry
            htmlContent += '</td></tr>'
          if key == 'depiction'
            htmlContent += '<tr><td style="min-width:150px;"><br /><b>Examples of this type:</b></td><td></td></tr><tr><td colspan="2">'
            for entry, key2 in value
              htmlContent += '<img src="' + entry + '" class="nomisma_imageExample" />'
            htmlContent += '</td></tr>'
        htmlContent += '</table>'
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return


  #######################################################################
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, nomisma_searchterm, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        if cdata_form
          nomisma_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
          nomisma_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()
          nomisma_set = cdata_form.getFieldsByName("searchSetSelect")[0].getValue()
        else
          # if no form, search in first type and with default count
          nomisma_countSuggestions = 20
          if that.getCustomMaskSettings().crro?.value
            nomisma_set = 'crro'
          else if that.getCustomMaskSettings().ocre?.value
            nomisma_set = 'ocre'
          else if that.getCustomMaskSettings().aod?.value
            nomisma_set = 'aod'
          else if that.getCustomMaskSettings().sco?.value
            nomisma_set = 'sco'
          else if that.getCustomMaskSettings().pella?.value
            nomisma_set = 'pella'
          else if that.getCustomMaskSettings().pco?.value
            nomisma_set = 'pco'
          else if that.getCustomMaskSettings().oscar?.value
            nomisma_set = 'oscar'
          else if that.getCustomMaskSettings().bigr?.value
            nomisma_set = 'bigr'
          else if that.getCustomMaskSettings().coi?.value
            nomisma_set = 'coi'
          else if that.getCustomMaskSettings().iacb?.value
            nomisma_set = 'iacb'

        if nomisma_searchterm.length == 0
            return

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        extendedInfo_xhr = { "xhr" : undefined }

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()
        # start new request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/numismatics.org/?searchstring=' + nomisma_searchterm + '&type=' + nomisma_set + '&count=' + nomisma_countSuggestions)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            # create new menu with suggestions
            menu_items = []
            for suggestion, key in data[1]
              do(key) ->
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "w"
                    content: (tooltip) ->
                      that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.nomisma.modal.form.popup.loadingstring'))
                menu_items.push item

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->
                  # lock in save data
                  cdata.conceptURI = btn.getOpt("value")
                  cdata.conceptName = btn.getText()
                  cdata.conceptFulltext = cdata.conceptName
                  # extract nomisma-id from URI
                  nomismaID = NomismaUtil.getNomismaIDFromURI cdata.conceptURI
                  nomismaType = NomismaUtil.getNomismaTypeFromURI cdata.conceptURI

                  # get record by uri
                  path = '//uri.gbv.de/terminology/' + nomismaType + '/' + nomismaID + '?format=json'
                  dataEntry_xhr = new (CUI.XHR)(url: location.protocol + path)
                  dataEntry_xhr.start().done((data, status, statusText) ->

                    # _standard & _fulltext
                    cdata._fulltext = TNADiscoveryUtil.getFullTextFromTNADiscoveryJSON data, false
                    cdata._standard = TNADiscoveryUtil.getStandardFromTNADiscoveryJSON that, data, false

                    # update the layout in form
                    that.__updateResult(cdata, layout, opts)
                    # hide suggest-menu
                    suggest_Menu.hide()
                    # close popover
                    if that.popover
                      that.popover.hide()
                  )
              items: menu_items

            # if no hits set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: $$('custom.data.type.nomisma.no_hit')
                  value: undefined
                ]

            suggest_Menu.setItemList(itemList)

            suggest_Menu.show()

        )
    ), delayMillisseconds



  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    that = @
    possibleTypes = ['crro', 'ocre', 'aod', 'sco', 'pella', 'pco', 'oscar', 'bigr', 'coi', 'iacb']
    searchOptions = []

    for type in possibleTypes
      do (type) ->
        if that.getCustomMaskSettings()[type]?.value
          option = (
              value: type
              text: $$('custom.data.type.nomisma.config.parameter.mask.' + type + '.value.label_long')
            )
          searchOptions.push option

        # form fields
    fields = [
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.nomisma.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 ' + $$('custom.data.type.nomisma.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.nomisma.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.nomisma.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.nomisma.modal.form.text.count_short')
          )
          (
              value: 500
              text: '500 ' + $$('custom.data.type.nomisma.modal.form.text.count_short')
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.nomisma.modal.form.text.searchfield')
        options: searchOptions
        name: 'searchSetSelect'
      }
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.nomisma.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.nomisma.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }]

    fields



  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->

    that = @

    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.nomisma.edit.no_nomisma")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.nomisma.edit.no_valid_nomisma")).DOM

    extendedInfo_xhr = { "xhr" : undefined }

    # if status is ok
    cdata.conceptURI = CUI.parseLocation(cdata.conceptURI).url

    # output Button with Name of picked Entry and URI
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: cdata.conceptName
      center:
        content:
          new CUI.ButtonHref(
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'w'
              content: (tooltip) ->
                uri = cdata.conceptURI
                # get jskos-details-data
                that.__getAdditionalTooltipInfo(uri, tooltip, extendedInfo_xhr)
                # loader, until details are xhred
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.nomisma.modal.form.popup.loadingstring'))
            text: ' '
          )
      right: null
    .DOM

  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    tags


CustomDataType.register(CustomDataTypeNomisma)
