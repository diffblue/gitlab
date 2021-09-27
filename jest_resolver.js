/* eslint-disable import/no-commonjs */
/* eslint-disable import/no-extraneous-dependencies */
const Resolver = require('jest-resolve');

// Wrap jest default resolver to detect missing frontend fixtures.
module.exports = (request, options) => {
  try {
    return options.defaultResolver(request, options);
  } catch (e) {
    if (Resolver.tryCastModuleNotFoundError(e) && request.match(/tmp\/tests\/frontend\/fixtures/)) {
      /* eslint-disable no-console */
      /* eslint-disable @gitlab/require-i18n-strings */
      console.error(
        '\x1b[1m\x1b[41m\x1b[30m %s \x1b[0m %s',
        '!',
        `Fixture file ${request} does not exist. Did you run bin/rake frontend:fixtures?`,
      );
    }
    throw e;
  }
};
