import AxiosMockAdapter from 'axios-mock-adapter';
import { ArkoseLabs } from 'ee/arkose_labs/arkose_labs';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

describe('ArkoseLabs', () => {
  let arkoseLabs;
  let axiosMock;

  // Finders
  const findByTestId = (testId) => document.querySelector(`[data-testid="${testId}"]`);
  const findScriptTags = () => document.querySelectorAll('script');
  const findSignInForm = () => findByTestId('sign-in-form');
  const findUsernameInput = () => findByTestId('username-field');
  const findSignInButton = () => findByTestId('sign-in-button');
  const findArkoseLabsChallengeContainer = () => findByTestId('arkose-labs-challenge');
  const findArkoseLabsErrorMessage = () => findByTestId('arkose-labs-error-message');
  const findArkoseLabsFailureAlert = () => findByTestId('arkose-labs-failure-alert');
  const findArkoseLabsVerificationTokenInput = () =>
    document.querySelector('input[name="arkose_labs_token"]');

  // Helpers
  const createForm = (username = '') => {
    loadFixtures('sessions/new.html');
    findUsernameInput().value = username;
  };
  const initArkoseLabs = (username) => {
    createForm(username);
    arkoseLabs = new ArkoseLabs();
  };
  const setUsername = (username) => {
    const input = findUsernameInput();
    input.focus();
    input.value = username;
    input.blur();
  };
  const submitForm = () => {
    findSignInForm().dispatchEvent(new Event('submit'));
  };

  // Assertions
  const itInitializesArkoseLabs = () => {
    it("includes ArkoseLabs' script", () => {
      expect(findScriptTags().length).toBe(1);
    });

    it('creates a hidden input for the verification token', () => {
      const input = findArkoseLabsVerificationTokenInput();

      expect(input).not.toBeNull();
      expect(input.value).toBe('');
    });
  };
  const expectHiddenArkoseLabsError = () => {
    expect(findArkoseLabsErrorMessage().classList.contains('gl-display-none')).toBe(true);
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  it('skips the initialization if the login form is not present', () => {
    expect(() => {
      arkoseLabs = new ArkoseLabs();
    }).not.toThrow();
    expect(arkoseLabs.signInForm).toBeNull();
  });

  describe('when the username field is pre-filled', () => {
    const username = 'invite-email-username';

    it("does not include ArkoseLabs' script initially", () => {
      expect(findScriptTags().length).toBe(0);
    });

    it('puts the sign-in button in the loading state', () => {
      initArkoseLabs(username);
      const signInButton = findSignInButton();

      expect(signInButton.innerText).toMatchInterpolatedText('Loading');
      expect(signInButton.disabled).toBe(true);
    });

    it('triggers a request to the captcha_check API', async () => {
      initArkoseLabs(username);

      expect(axiosMock.history.get).toHaveLength(0);

      await waitForPromises();

      expect(axiosMock.history.get).toHaveLength(1);
      expect(axiosMock.history.get[0].url).toMatch(`/users/${username}/captcha_check`);
    });

    describe('if the challenge is not needed', () => {
      beforeEach(async () => {
        axiosMock.onGet().reply(200, { result: false });
        initArkoseLabs(username);
        await waitForPromises();
      });

      it('resets the loading button', () => {
        const signInButton = findSignInButton();

        expect(signInButton.innerText).toMatchInterpolatedText('Sign in');
      });

      it('does not show ArkoseLabs error when submitting the form', () => {
        submitForm();

        expect(findArkoseLabsErrorMessage()).toBe(null);
      });

      describe('if the challenge becomes needed', () => {
        beforeEach(async () => {
          axiosMock.onGet().reply(200, { result: true });
          setUsername('bob');
          await waitForPromises();
        });

        itInitializesArkoseLabs();
      });
    });

    describe('if the challenge is needed', () => {
      beforeEach(async () => {
        axiosMock.onGet().reply(200, { result: true });
        initArkoseLabs(username);
        await waitForPromises();
      });

      itInitializesArkoseLabs();

      it('shows ArkoseLabs error when submitting the form', () => {
        submitForm();

        expect(findArkoseLabsErrorMessage()).not.toBe(null);
      });

      it('un-hides the challenge container once the iframe has been shown', () => {
        let onShown;
        arkoseLabs.setConfig({
          setConfig: ({ onShown: handler }) => {
            onShown = handler;
          },
        });

        expect(findArkoseLabsChallengeContainer().classList.contains('gl-display-none!')).toBe(
          true,
        );

        onShown();

        expect(findArkoseLabsChallengeContainer().classList.contains('gl-display-none!')).toBe(
          false,
        );
      });

      it('shows an error alert if the challenge fails to load', () => {
        let onError;
        arkoseLabs.setConfig({
          setConfig: ({ onError: handler }) => {
            onError = handler;
          },
        });

        expect(findArkoseLabsFailureAlert()).toBe(null);

        onError();

        expect(findArkoseLabsFailureAlert()).not.toBe(null);
      });

      describe.each`
        handlerName
        ${'onCompleted'}
        ${'onSuppress'}
      `(
        'when ArkoseLabs calls `$handlerName` handler that has been configured',
        ({ handlerName }) => {
          let handlerMock;

          const enforcement = {
            setConfig: ({ [handlerName]: handler }) => {
              handlerMock = handler;
            },
          };

          const response = { token: 'verification-token' };

          beforeEach(() => {
            submitForm();
            arkoseLabs.setConfig(enforcement);

            handlerMock(response);
          });

          it('removes ArkoseLabs error', () => {
            expectHiddenArkoseLabsError();
          });

          it('does not show again the error when re-submitting the form', () => {
            submitForm();

            expectHiddenArkoseLabsError();
          });

          it("sets the verification token input's value", () => {
            expect(findArkoseLabsVerificationTokenInput().value).toBe(response.token);
          });
        },
      );
    });
  });
});
