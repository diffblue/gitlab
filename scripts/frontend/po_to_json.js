#!/usr/bin/env node

const fs = require('fs/promises');
const path = require('path');

const ROOT_DIR = path.join(__dirname, '../../');

/**
 * This is the main function which starts multiple workers
 * in order to speed up the po file => app.js
 * locale conversions
 */
async function main() {
  // eslint-disable-next-line global-require
  const { Worker } = require('jest-worker');

  const getChildDirectories = async (source) =>
    (await fs.readdir(source, { withFileTypes: true }))
      .filter((dirent) => dirent.isDirectory())
      .map((dirent) => dirent.name);

  const worker = new Worker(__filename, {
    exposedMethods: ['convertPoFileForLocale'],
    silent: false,
    enableWorkerThreads: true,
  });
  worker.getStdout().pipe(process.stdout);
  worker.getStderr().pipe(process.stderr);

  const locales = await getChildDirectories(path.join(ROOT_DIR, 'locale/'));

  await Promise.all(locales.map((locale) => worker.convertPoFileForLocale(locale)));

  await worker.end();

  console.log('Done converting all the po files');
}

/**
 * This is the conversion logic for: po => JS object for jed
 */
function convertPoToJed(data, locale) {
  // eslint-disable-next-line global-require
  const { parse } = require('gettext-parser/lib/poparser');
  const DEFAULT_CONTEXT = '';

  /**
   * TODO: This replacer might be unnecessary _or_ even cause bugs.
   *   due to potential unnecessary double escaping.
   *   But for now it is here to ensure that the old and new output
   *   are equivalent.
   * @param str
   * @returns {string}
   */
  function escapeMsgid(str) {
    return `${str}`.replace(/([\\"])/g, '\\$1');
  }

  /**
   * TODO: This replacer might be unnecessary _or_ even cause bugs.
   *   due to potential unnecessary double escaping.
   *   But for now it is here to ensure that the old and new output
   *   are equivalent.
   *
   *   NOTE: The replacements of `\n` and `\t` need to be iterated on,
   *   because: In the cases where we see those chars, they:
   *     - likely need or could be trimmed because they do nothing
   *     - they seem to escaped in a way that is broken anyhow
   * @param str
   * @returns {string}
   */
  function escapeMsgstr(str) {
    return `${str}`.replace(/[\t\n"\\]/g, (match) => {
      if (match === '\n') {
        return '\\n';
      }
      if (match === '\t') {
        return '\\t';
      }
      return `\\${match}`;
    });
  }

  const { headers = {}, translations: parsed } = parse(data);

  const translations = Object.values(parsed[DEFAULT_CONTEXT] ?? {}).reduce((acc, entry) => {
    const { msgid, msgstr } = entry;

    /* TODO: If a msgid has no translation, we can just drop the whole key,
         as jed will just fallback to the keys
         We are not doing that yet, because we do want to ensure that
         the results of the new and old way of generating the files matches.
    if (msgstr.every((x) => x === '')) {
      return acc;
     }
    */

    acc[escapeMsgid(msgid)] = msgstr.map(escapeMsgstr);

    return acc;
  }, {});

  // Do not bother if the file has no actual translations
  if (!Object.keys(translations).length) {
    return { jed: null };
  }

  if (headers['Plural-Forms']) {
    headers.plural_forms = headers['Plural-Forms'];
  }

  // Format required for jed: http://messageformat.github.io/Jed/
  const jed = {
    domain: 'app',
    locale_data: {
      app: {
        ...translations,
        // Ensure that the header data which is attached to a message with id ""
        // is not accidentally overwritten by an empty externalized string
        '': {
          ...headers,
          domain: 'app',
          lang: locale,
        },
      },
    },
  };

  return { jed };
}

/**
 * This is the function which the workers actually execute
 * 1. It reads the po
 * 2. converts it with convertPoToJed
 * 3. writes the file to
 */
async function convertPoFileForLocale(locale) {
  const poContent = await fs.readFile(path.join(ROOT_DIR, `locale/${locale}/gitlab.po`));

  const { jed } = await convertPoToJed(poContent, locale);

  if (jed === null) {
    console.log(`${locale}: No translations. Skipping creation of app.js`);
    return;
  }

  const resultDir = path.join(ROOT_DIR, `app/assets/javascripts/locale/${locale}`);

  await fs.mkdir(resultDir, { recursive: true });

  await fs.writeFile(
    path.join(resultDir, 'app.js'),
    `window.translations = ${JSON.stringify(jed)}`,
    'utf8',
  );
  console.log(`Created app.js in ${resultDir}`);
}

/*
 Start the main thread only if we are not part of a worker
 */
if (!process.env.JEST_WORKER_ID) {
  main();
}

/*
 Expose the function for workers
 */
module.exports = {
  convertPoToJed,
  convertPoFileForLocale,
};
