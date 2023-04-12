import {
  ActiveModelError,
  errorDictionary,
  EMAIL_TAKEN_ERROR,
  EMAIL_TAKEN_ERROR_TYPE,
  CONTACT_SUPPORT_DEFAULT_MESSAGE,
  generateHelpTextWithLinks,
  mapSystemToFriendlyError,
} from 'ee/vue_shared/purchase_flow/utils/purchase_errors';

describe('Purchase Dynamic Errors', () => {
  describe('errorDictionary', () => {
    it('contains all the declared errors', () => {
      expect(Object.keys(errorDictionary)).toHaveLength(10);
    });
  });

  describe('mapSystemToFriendlyError', () => {
    describe.each(Object.keys(errorDictionary))('when system error is %s', (systemError) => {
      const friendlyError = errorDictionary[systemError];

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(systemError))).toEqual(friendlyError);
      });

      it('maps the system error to the friendly one from uppercase', () => {
        expect(mapSystemToFriendlyError(new Error(systemError.toUpperCase()))).toEqual(
          friendlyError,
        );
      });
    });

    describe.each(['', {}, [], undefined, null, new Error()])(
      'when system error is %s',
      (systemError) => {
        it('defaults to the general error message', () => {
          expect(mapSystemToFriendlyError(systemError)).toEqual(CONTACT_SUPPORT_DEFAULT_MESSAGE);
        });
      },
    );

    describe('when system error is a non-existent key', () => {
      const message = 'a non-existent key';
      const nonExistentKeyError = { message, links: {} };

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message))).toEqual(nonExistentKeyError);
      });
    });

    describe('when system error consists of multiple non-existent keys', () => {
      const message = 'a non-existent key, another non-existent key';
      const nonExistentKeyError = { message, links: {} };

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message))).toEqual(nonExistentKeyError);
      });
    });

    describe('when system error consists of multiple messages with one matching key', () => {
      const message = `a non-existent key, ${EMAIL_TAKEN_ERROR}`;

      it('maps the system error to the friendly one', () => {
        expect(mapSystemToFriendlyError(new Error(message))).toEqual(
          errorDictionary[EMAIL_TAKEN_ERROR.toLowerCase()],
        );
      });
    });

    describe('when error is email already taken message', () => {
      it('maps the email friendly error', () => {
        expect(mapSystemToFriendlyError(new Error(EMAIL_TAKEN_ERROR))).toEqual(
          errorDictionary[EMAIL_TAKEN_ERROR.toLowerCase()],
        );
      });
    });

    describe('when error is email:taken error_attribute_map', () => {
      const errorAttributeMap = { email: ['taken'] };

      it('maps the email friendly error', () => {
        expect(
          mapSystemToFriendlyError(new ActiveModelError(errorAttributeMap, EMAIL_TAKEN_ERROR)),
        ).toEqual(errorDictionary[EMAIL_TAKEN_ERROR_TYPE.toLowerCase()]);
      });
    });

    describe('when there are multiple errors in the error_attribute_map', () => {
      const errorAttributeMap = { email: ['taken', 'invalid'] };

      it('maps the email friendly error', () => {
        expect(
          mapSystemToFriendlyError(
            new ActiveModelError(errorAttributeMap, `${EMAIL_TAKEN_ERROR}, Email is invalid`),
          ),
        ).toEqual(errorDictionary[EMAIL_TAKEN_ERROR_TYPE.toLowerCase()]);
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
