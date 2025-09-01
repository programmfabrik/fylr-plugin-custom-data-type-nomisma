const fs = require('fs')
const https = require('https')
const fetch = (...args) => import('node-fetch').then(({
  default: fetch
}) => fetch(...args));

let databaseLanguages = [];

let info = {}

let access_token = '';

if (process.argv.length >= 3) {
  info = JSON.parse(process.argv[2])
}

function hasChanges(objectOne, objectTwo) {
  const ref = [
    "conceptName",
    "conceptURI",
    "_standard",
    "_fulltext",
    "facetTerm"
  ];
  for (let i = 0; i < ref.length; i++) {
    let key = ref[i];
    if (!NomismaUtil.isEqual(objectOne[key], objectTwo[key])) {
      return true;
    }
  }
  return false;
}

function getConfigFromAPI() {
  return new Promise((resolve, reject) => {
    var url = 'http://fylr.localhost:8081/api/v1/config?access_token=' + access_token
    fetch(url, {
      headers: {
        'Accept': 'application/json'
      },
    })
      .then(response => {
        if (response.ok) {
          resolve(response.json());
        } else {
          console.error("Nomisma-Updater: Fehler bei der Anfrage an /config ");
        }
      })
      .catch(error => {
        console.error(error);
        console.error("Nomisma-Updater: Fehler bei der Anfrage an /config");
      });
  });
}

function isInTimeRange(currentHour, fromHour, toHour) {
  if (fromHour === toHour) {
    return true;
  }

  if (fromHour < toHour) { // same day
    return currentHour >= fromHour && currentHour < toHour;
  } else { // through the night
    return currentHour >= fromHour || currentHour < toHour;
  }
} 

main = (payload) => {
  console.error("main " + payload.action)
  switch (payload.action) {
    case "start_update":
      outputData({
        "state": {
          "personal": 2
        },
        "log": ["started logging"]
      })
      break
    case "update":
      ////////////////////////////////////////////////////////////////////////////
      // run Nomisma-api-call for every given uri
      ////////////////////////////////////////////////////////////////////////////

      // collect IDs
      let IDList = [];
      for (var i = 0; i < payload.objects.length; i++) {
        IDList.push(payload.objects[i].data.discoveryID);
      }
      // unique urilist
      IDList = [...new Set(IDList)]

      let requestUrls = [];
      let requests = [];

      IDList.forEach((id) => {

        let dataRequestUrl = 'https://discovery.nationalarchives.gov.uk/api/records/details/' + id;
        const options = {
          headers: {
            Accept: 'application/json',
            'User-Agent': 'Node'
          }
        }
        let dataRequest = fetch(dataRequestUrl, options);
        requests.push({
          url: dataRequestUrl,
          uri: 'http://discovery.nationalarchives.gov.uk/details/r/' + id,
          request: dataRequest
        });
        requestUrls.push(dataRequest);
      });

      Promise.all(requestUrls).then(function (responses) {
        let results = [];
        // console.error(responses)
        // Get a JSON object from each of the responses
        responses.forEach((response, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let result = {
            url: url,
            uri: uri,
            data: null,
            error: null
          };
          if (response.ok) {
            result.data = response.json();
          } else {
            result.error = "Error fetching data from " + url + ": " + response.status + " " + response.statusText;
          }
          results.push(result);
        });
        console.error(results);

        return Promise.all(results.map(result => result.data));
      }).then(function (data) {
        // console.error("2nd then");
        // console.error(data);

        let results = [];
        data.forEach((data, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let result = {
            url: url,
            uri: uri,
            data: data,
            error: null
          };
          if (data instanceof Error) {
            result.error = "Error parsing data from " + url + ": " + data.message;
          }
          results.push(result);
        });

        var test = ""
        payload.objects.forEach((result, index) => {
          let originalCdata = payload.objects[index].data;

          let newCdata = {};
          let originalURI = originalCdata.conceptURI;

          const matchingRecordData = results.find(record => record.uri === originalURI);

          if (matchingRecordData) {
            test += "Matching Record\n"
            ///////////////////////////////////////////////////////
            // conceptName, conceptURI, conceptSource, _standard, _fulltext, facet
            resultObject = matchingRecordData.data;
            if (resultObject) {
              test += "resultObject OK\n"
              // save discoveryID
              newCdata.discoveryID = resultObject.id
              // save discoveryURL
              newCdata.discoveryURL = 'http://discovery.nationalarchives.gov.uk/details/r/' + resultObject.id
              // save referenceNumber
              newCdata.referenceNumber = resultObject.citableReference ?? ''
              // save locationHeld
              newCdata.locationHeld = resultObject.heldBy[0] ? resultObject.heldBy[0].xReferenceName : null
              // save resultObject
              newCdata.title = resultObject.title ?? ''
              // save description + remove html tags
              newCdata.description = resultObject.scopeContent?.description?.replace(/<\/?[^>]+(>|$)/g, "") ?? ''
              // save conceptName
              newCdata.conceptName = resultObject.citableReference;
              // save conceptURI
              newCdata.conceptURI = 'http://discovery.nationalarchives.gov.uk/details/r/' + resultObject.id;
              // save _fulltext
              newCdata._fulltext = NomismaUtil.getFullTextFromNomismaJSON(newCdata, databaseLanguages);
              // save _standard
              newCdata._standard = NomismaUtil.getStandardFromNomismaJSON(null, newCdata, newCdata, databaseLanguages);
              if (hasChanges(payload.objects[index].data, newCdata)) {
                payload.objects[index].data = newCdata;
              }
            }
          } else {
            console.error('No matching record found');
          }
        });
        outputData({
          "payload": payload.objects,
          "log": [payload.objects.length + " objects in payload \n" + test]
        });
      });
      // send data back for update
      break;
    case "end_update":
      outputData({
        "state": {
          "theend": 2,
          "log": ["done logging"]
        }
      });
      break;
    default:
      outputErr("Unsupported action " + payload.action);
  }
}

outputData = (data) => {
  out = {
    "status_code": 200,
    "body": data
  }
  process.stdout.write(JSON.stringify(out))
  process.exit(0);
}

outputErr = (err2) => {
  let err = {
    "status_code": 400,
    "body": {
      "error": err2.toString()
    }
  }
  console.error(JSON.stringify(err))
  process.stdout.write(JSON.stringify(err))
  process.exit(0);
}

(() => {
  let data = ""

  process.stdin.setEncoding('utf8');

  ////////////////////////////////////////////////////////////////////////////
  // check if hour-restriction is set
  ////////////////////////////////////////////////////////////////////////////
  if (info?.config?.plugin?.['custom-data-type-nomisma']?.config?.update_nomisma?.restrict_time === true) {
    nomisma_config = info.config.plugin['custom-data-type-nomisma'].config.update_nomisma;

    // check if hours are configured
    if (nomisma_config?.from_time !== false && nomisma_config?.to_time !== false) {
      const now = new Date();
      const hour = now.getHours();

      // check if hours do not match
      if (!isInTimeRange(hour, nomisma_config.from_time, nomisma_config.to_time)) {
        // exit if hours do not match
        outputData({
          "state": {
            "theend": 2,
            "log": ["hours do not match, cancel update"]
          }
        });
      }
    }
  }

  access_token = info && info.plugin_user_access_token;

  if (access_token) {

    ////////////////////////////////////////////////////////////////////////////
    // get config and read the languages
    ////////////////////////////////////////////////////////////////////////////

    getConfigFromAPI().then(config => {
      databaseLanguages = config.system.config.languages.database;
      databaseLanguages = databaseLanguages.map((value, key, array) => {
        return value.value;
      });

      ////////////////////////////////////////////////////////////////////////////
      // availabilityCheck for Nomisma-api
      ////////////////////////////////////////////////////////////////////////////

      const testURL = "https://discovery.nationalarchives.gov.uk/API/search/v1/records?sps.sortByOption=RELEVANCE&sps.resultsPageSize=1"
      const options = {
        headers: {
          Accept: 'application/json',
          'User-Agent': 'Node'
        }
      }
      https.get(testURL, options, res => {
        let testData = [];
        res.on('data', chunk => {
          testData.push(chunk);
        });
        res.on('end', () => {
          testData = Buffer.concat(testData).toString();
          const testJSON = JSON.parse(testData);

          if (!Array.isArray(testJSON?.records)) {
            return console.error("Error: Json parse complete, result does not contain hits or hits is not an array.")
          }

          if (testJSON.records.length < 0) {
            return console.error('Error: Hits array is empty.')
          }

          ////////////////////////////////////////////////////////////////////////////
          // test successfull --> continue with custom-data-type-update
          ////////////////////////////////////////////////////////////////////////////
          process.stdin.on('readable', () => {
            let chunk;
            while ((chunk = process.stdin.read()) !== null) {
              data = data + chunk
            }
          });
          process.stdin.on('end', () => {
            ///////////////////////////////////////
            // continue with update-routine
            ///////////////////////////////////////
            try {
              let payload = JSON.parse(data)
              main(payload)
            } catch (error) {
              console.error("caught error", error)
              outputErr(error)
            }
          });

        });
      }).on('error', err => {
        console.error('Error while receiving data from Nomisma-API: ', err.message);
      });
    }).catch(error => {
      console.error('Es gab einen Fehler beim Laden der Konfiguration:', error);
    });
  }
  else {
    console.error("kein Accesstoken gefunden");
  }

})();
