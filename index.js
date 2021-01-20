const fs = require('fs')
const path = require('path')
const request = require('request')

const error = `
#!/bin/sh

echo "Something went wrong. Please file an issue at https://github.com/zeplo/zeplo-install."

exit 1
`

let out = null
let timer = null

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/plain')
  return getInstallScript().catch(() => error)
}

async function getInstallScript () {
  // Prevent script from caching for more than 3 mins
  if (!timer) {
    timer = setTimeout(() => {
      out = null
      timer = null
    }, 60 * 1000 * 5)
  }
  if (out) {
    return out
  }
  out = await createInstallScript()
  return out
}

async function createInstallScript () {
  return new Promise((resolve, reject) => {
    request({
      url: 'https://ralley-cli-releases.zeplo.io',
      json: true,
    }, (err, resp, body) => {
      if (err || !resp) return reject(err)
      const out = fs.readFileSync(path.resolve(__dirname, './install.sh'), 'utf8').replace('$REPLACE_WITH_VERSION$', body && body.stable && body.stable.tag)
      resolve(out)
    })
  })
}
