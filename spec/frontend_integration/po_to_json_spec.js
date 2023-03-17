/**
 * This whole file is just a temporary measure.
 * Some things in here are weird hacks. Do not copy them.
 * Please refer to:
 * - scripts/frontend/po_to_json_spec.sh
 * - scripts/frontend/po_to_json.js
 */
if (process.env.TEST_PO_FILE_EQUIVALENCE) {
  // eslint-disable-next-line global-require
  const fs = require('fs');
  // eslint-disable-next-line global-require
  const path = require('path');

  const files = fs
    .readdirSync(path.join(__dirname, '../../tmp', 'po_json_before'), { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);

  describe('Check equality of gettext:compile and po_to_json', () => {
    describe.each(files)('Testing language: %p', (lang) => {
      let oldTranslations = null;
      let newTranslations = null;

      beforeEach(async () => {
        window.translations = {};

        await import(`../../tmp/po_json_before/${lang}/app.js`);

        oldTranslations = JSON.parse(JSON.stringify(window.translations));
        window.translations = {};

        await import(`../../tmp/po_json_after/${lang}/app.js`);
        newTranslations = JSON.parse(JSON.stringify(window.translations));
      });

      it('Compare', () => {
        expect(newTranslations).not.toBeNull();
        expect(newTranslations).toStrictEqual(oldTranslations);
      });
    });
  });
} else {
  it('hopefully I never fail', () => {
    expect(true).toBe(true);
  });
}
