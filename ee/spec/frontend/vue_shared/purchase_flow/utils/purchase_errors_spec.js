import {
  errorDictionary,
  CONTACT_SUPPORT_DEFAULT_MESSAGE,
  generateHelpTextWithLinks,
  mapSystemToFriendlyError,
} from 'ee/vue_shared/purchase_flow/utils/purchase_errors';

describe('Purchase Dynamic Errors', () => {
  describe('errorDictionary', () => {
    it('contains all the declared errors', () => {
      expect(Object.keys(errorDictionary)).toHaveLength(7);
    });
  });

  describe('mapSystemToFriendlyError', () => {
    describe.each(Object.keys(errorDictionary))('when system error is %s', (systemError) => {
      const friendlyError = errorDictionary[systemError];

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(systemError)).toEqual(friendlyError);
      });

      it('maps the system error to the friendly one from uppercase', () => {
        expect(mapSystemToFriendlyError(systemError.toUpperCase())).toEqual(friendlyError);
      });
    });

    describe.each(['', {}, [], undefined, null])('when system error is %s', (systemError) => {
      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(systemError)).toEqual(CONTACT_SUPPORT_DEFAULT_MESSAGE);
      });
    });

    describe('when system error is a non existent key', () => {
      const message = 'a non existent key';
      const nonExistentKeyError = { message, links: {} };

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(message)).toEqual(nonExistentKeyError);
      });
    });

    describe('when error is email already taken', () => {
      const EMAIL_TAKEN_ERROR = JSON.stringify({ email: ['has already been taken'] });

      it('maps the email friendly error', () => {
        expect(mapSystemToFriendlyError(EMAIL_TAKEN_ERROR)).toEqual(
          errorDictionary[EMAIL_TAKEN_ERROR],
        );
      });

      it('directs the user to the legacy Customers Portal login', () => {
        expect(mapSystemToFriendlyError(EMAIL_TAKEN_ERROR).links.customersPortalLink).toEqual(
          gon.subscriptions_legacy_sign_in_url,
        );
      });
    });
  });

  describe('generateHelpTextWithLinks', () => {
    describe('when the error is present in the dictionary', () => {
      describe.each(Object.values(errorDictionary))('when system error is %s', (friendlyError) => {
        it('generates the proper link', () => {
          const errorHtmlString = generateHelpTextWithLinks(friendlyError);
          const expected = Array.from(friendlyError.message.matchAll(/%{/g)).length / 2;
          const newNode = document.createElement('div');
          newNode.innerHTML = errorHtmlString;
          const links = Array.from(newNode.querySelectorAll('a'));

          expect(links).toHaveLength(expected);
        });
      });
    });

    describe('when the error contains no links', () => {
      it('generates the proper link/s', () => {
        const anError = { message: 'An error', links: {} };
        const errorHtmlString = generateHelpTextWithLinks(anError);
        const expected = Object.keys(anError.links).length;
        const newNode = document.createElement('div');
        newNode.innerHTML = errorHtmlString;
        const links = Array.from(newNode.querySelectorAll('a'));

        expect(links).toHaveLength(expected);
      });
    });

    describe('when the error is invalid', () => {
      it('returns the error', () => {
        expect(() => generateHelpTextWithLinks([])).toThrow(
          new Error('The error cannot be empty.'),
        );
      });
    });

    describe('when the error is not an object', () => {
      it('returns the error', () => {
        const errorHtmlString = generateHelpTextWithLinks('An error');

        expect(errorHtmlString).toBe('An error');
      });
    });

    describe('when the error is falsy', () => {
      it('throws an error', () => {
        expect(() => generateHelpTextWithLinks(null)).toThrow(
          new Error('The error cannot be empty.'),
        );
      });
    });
  });
});
