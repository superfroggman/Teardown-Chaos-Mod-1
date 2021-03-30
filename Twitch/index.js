const tmi = require("tmi.js");
const config = require("./config.json");
const xmlParser = require("xml2json");
const formatXml = require("xml-formatter");
const fs = require("fs");

let votes = [0, 0, 0, 0];

const client = new tmi.Client({
  options: { debug: true },
  connection: {
    secure: true,
    reconnect: true,
  },
  identity: {
    username: config.username,
    password: config.authToken,
  },
  channels: [config.channel],
});

client.connect();

client.on("message", (channel, tags, message, self) => {
  console.log(message);
  // Ignore echoed messages.
  if (self) return;

  switch (message) {
    case "1":
      votes[0] += 1;
      break;
    case "2":
      votes[1]++;
      break;
    case "3":
      votes[2]++;
      break;
    case "4":
      votes[3]++;
      break;
  }

  console.log(votes);
  updateXML();
});

function updateXML() {
  fs.readFile(config.teardownSavegameLocation, function (err, data) {
    const xmlObj = xmlParser.toJson(data, { reversible: true, object: true });

    console.log(xmlObj);

    xmlObj["registry"]["savegame"]["mod"][config.teardownSavegameModname] = "hej";

    const stringifiedXmlObj = JSON.stringify(xmlObj);
    const finalXml = xmlParser.toXml(stringifiedXmlObj);

    fs.writeFile(
      config.teardownSavegameLocation,
      formatXml(finalXml, { collapseContent: true }),
      function (err, result) {
        if (err) {
          console.log("err");
        } else {
          console.log("Xml file successfully updated.");
        }
      }
    );
  });
}
