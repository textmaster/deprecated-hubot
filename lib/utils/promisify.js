
// Node's Utils.promisify expects (err, data) style callbacks
const promisify = fn => (...args) => new Promise((resolve, reject) => fn(...args, resolve))

module.exports = promisify

