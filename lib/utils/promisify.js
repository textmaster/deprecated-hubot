// Node's Utils.promisify expects (err, data) style callbacks
const promisify = (objOrFn, name) => (...args) => {
  const fn = name ? objOrFn[name].bind(objOrFn) : objOrFn;
  return new Promise((resolve, reject) => fn(...args, resolve));
}

module.exports = promisify;
