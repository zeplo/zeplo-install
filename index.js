const fs = require('fs')
const path = require('path')
const Sentry = require("@sentry/node")
const axios = require('axios')

Sentry.init({
  dsn: "https://3d73e314f55a405a86dfca52ce7febdb@o412857.ingest.sentry.io/5898461",

  // Set tracesSampleRate to 1.0 to capture 100%
  // of transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,
})


const error = `
#!/bin/sh

echo "Something went wrong. Please file an issue at https://github.com/zeplo/zeplo-install."

exit 1
`

let out = null
let timer = null

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/plain')
  return getInstallScript()
}

async function getInstallScript () {
  // Prevent script from caching for more than 3 mins
  if (!timer) {
    timer = setTimeout(() => {
      out = null
      timer = null
    }, 60 * 1000 * 5)
  }
  if (out) return out
  out = await createInstallScript().catch((e) => {
    Sentry.captureException(e)
    return null
  })
  if (!out) return error
  return out
}

async function createInstallScript () {
  const resp = await axios.get('https://zeplo-cli-releases.zeplo.io')
  const tag = resp && resp.data.stable && resp.data.stable.tag
  if (!tag) return null
  return fs.readFileSync(path.resolve(__dirname, './install.sh'), 'utf8').replace('$REPLACE_WITH_VERSION$', tag)
}
