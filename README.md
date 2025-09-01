> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# custom-data-type-nomisma

Custom Data Type "Nomisma" for fylr

This is a plugin for [fylr](https://docs.fylr.io/) with Custom Data Type `CustomDataTypeNomisma` for references to the records from different online ressources of the [Nomisma-Project](<http://www.nomisma.org/datasets>).

The Plugins uses <http://ws.gbv.de/suggest/numismatics.org/> and <http://uri.gbv.de/terminology/> for the autocomplete-suggestions and additional informations about the Nomisma-records.

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-nomisma/releases/latest/download/customDataTypeNomisma.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-nomisma/releases/).

## requirements
This plugin requires https://github.com/programmfabrik/fylr-plugin-commons-library. In order to use this Plugin, you need to add the [commons-library-plugin](https://github.com/programmfabrik/fylr-plugin-commons-library) to your pluginmanager.


## configuration

As defined in `manifest.master.yml` this datatype can be configured:

### Schema options
  * search crro?
  * search ocre?
  * search pella?
  * search aod?
  * search sco?
  * search pco?
  * search oscar?
  * search bigr?
  * search coi?
  * search iacb?

### Mask options
  * none

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/fylr-plugin-custom-data-type-nomisma>.

## updater
Note: The automatic updater is implemented and can be configured in the baseconfig. You need to enable the "custom-data-type"-update-service globally too.


