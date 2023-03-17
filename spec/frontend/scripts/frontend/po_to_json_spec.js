import { convertPoToJed } from '../../../../scripts/frontend/po_to_json';

describe('PoToJson', () => {
  const LOCALE = 'de';

  describe('#convertPoToJed', () => {
    it('converts simple PO to JED compatible JSON', () => {
      const poContent = `
# Simple translated string
msgid " %{start} to %{end}"
msgstr " %{start} bis %{end}"

# Simple translated, pluralized string
msgid "%d Alert:"
msgid_plural "%d Alerts:"
msgstr[0] "%d Warnung:"
msgstr[1] "%d Warnungen:"

# Simple string without translation
msgid "Example"
msgstr ""
`;

      expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
        domain: 'app',
        locale_data: {
          app: {
            '': {
              domain: 'app',
              lang: LOCALE,
            },
            ' %{start} to %{end}': [' %{start} bis %{end}'],
            '%d Alert:': ['%d Warnung:', '%d Warnungen:'],
            Example: [''],
          },
        },
      });
    });

    it('returns null for empty string', () => {
      const poContent = '';

      expect(convertPoToJed(poContent, LOCALE).jed).toEqual(null);
    });

    describe('PO File headers', () => {
      it('parses headers properly', () => {
        const poContent = `
msgid ""
msgstr ""
"Project-Id-Version: gitlab-ee\\n"
"Report-Msgid-Bugs-To: \\n"
"X-Crowdin-Project: gitlab-ee\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Project-Id-Version': 'gitlab-ee',
                'Report-Msgid-Bugs-To': '',
                'X-Crowdin-Project': 'gitlab-ee',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });

      // JED needs that property, hopefully we could get
      // rid of this in a future iteration
      it("exposes 'Plural-Forms' as 'plural_forms' for `jed`", () => {
        const poContent = `
msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Plural-Forms': 'nplurals=2; plural=(n != 1);',
                plural_forms: 'nplurals=2; plural=(n != 1);',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });

      it('removes POT-Creation-Date', () => {
        const poContent = `
msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                'Plural-Forms': 'nplurals=2; plural=(n != 1);',
                plural_forms: 'nplurals=2; plural=(n != 1);',
                domain: 'app',
                lang: LOCALE,
              },
            },
          },
        });
      });
    });

    describe('escaping', () => {
      it('escapes quotes in msgid and translation', () => {
        const poContent = `
# Escaped quotes in msgid and msgstr
msgid "Changes the title to \\"%{title_param}\\"."
msgstr "Ändert den Titel in \\"%{title_param}\\"."
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              'Changes the title to \\"%{title_param}\\".': [
                'Ändert den Titel in \\"%{title_param}\\".',
              ],
            },
          },
        });
      });

      it('escapes backslashes in msgid and translation', () => {
        const poContent = `
# Escaped backslashes in msgid and msgstr
msgid "Example: ssh\\\\:\\\\/\\\\/"
msgstr "Beispiel: ssh\\\\:\\\\/\\\\/"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              'Example: ssh\\\\:\\\\/\\\\/': ['Beispiel: ssh\\\\:\\\\/\\\\/'],
            },
          },
        });
      });

      // This is potentially faulty behavior but demands further investigation
      // See also the escapeMsgstr method
      it('escapes \\n and \\t in translation', () => {
        const poContent = `
# Escaped \\n
msgid "Outdent line"
msgstr "Désindenter la ligne\\n"

# Escaped \\t
msgid "Headers"
msgstr "Cabeçalhos\\t"
`;

        expect(convertPoToJed(poContent, LOCALE).jed).toEqual({
          domain: 'app',
          locale_data: {
            app: {
              '': {
                domain: 'app',
                lang: LOCALE,
              },
              Headers: ['Cabeçalhos\\t'],
              'Outdent line': ['Désindenter la ligne\\n'],
            },
          },
        });
      });
    });
  });
});
