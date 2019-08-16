const TIMEOUT = 5000;
// Node's Utils.promisify expects (err, data) style callbacks
const promisify = (objOrFn, name) => (...args) => {
  const fn = name ? objOrFn[name].bind(objOrFn) : objOrFn;
  return new Promise((resolve, reject) => {
    let rejected = false;
    const timeout = setTimeout(() => {
      rejected = true;
      reject(new Error("Timeout"));
    }, TIMEOUT);

    fn(...args, (...result) => {
      if(rejected) {
        return;
      }
      clearTimeout(timeout);
      resolve(...result);
    })
  });
}

module.exports = promisify;
