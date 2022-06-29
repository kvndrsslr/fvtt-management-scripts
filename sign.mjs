import fetch from 'node-fetch';
import fs from 'fs';
import os from 'os';

const LICENSE = '81XNM3JARTAOM1UZ1L3FGMNY';
const API_KEY = 'foundryvtt_hkmg5t4zxc092e31mkfbg3';
const VERSION = '0.8.0';

const body = {
  host: os.hostname(),
  license: LICENSE,
  version: VERSION
}

const response = await fetch('https://foundryvtt.com/_api/license/sign/', {
	method: 'post',
	body: JSON.stringify(body),
	headers: {'Content-Type': 'application/json', 'Authorization': `APIKey:${API_KEY}`}
});

const data = await response.json();
body.time = new Date().toISOString();
body.signature = data.signature;
fs.writeFile("license.json", JSON.stringify(body, 0, 4), 'utf8', function (err) {
  if (err) {
      console.log("License could not be saved!");
      return console.log(err);
  }
  console.log("License has been signed!");
});
