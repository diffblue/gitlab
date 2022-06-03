import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignInArkoseApp from 'ee/arkose_labs/components/sign_in_arkose_app.vue';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import waitForPromises from 'helpers/wait_for_promises';
import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';

jest.mock('~/lib/logger');
// ArkoseLabs enforcement mocks
jest.mock('ee/arkose_labs/init_arkose_labs_script');
let onShown;
let onCompleted;
let onError;
initArkoseLabsScript.mockImplementation(() => ({
  setConfig: ({ onShown: shownHandler, onCompleted: completedHandler, onError: errorHandler }) => {
    onShown = shownHandler;
    onCompleted = completedHandler;
    onError = errorHandler;
  },
}));

const MOCK_USERNAME = 'cassiopeia';
const MOCK_PUBLIC_KEY = 'arkose-labs-public-api-key';
const MOCK_ARKOSE_RESPONSE = { completed: true, token: 'verification-token', suppressed: false };
const MOCK_ARKOSE_RESPONSE_SUPPRESSED = { ...MOCK_ARKOSE_RESPONSE, suppressed: true };
const MOCK_DOMAIN = 'client-api.arkoselabs.com';

describe('SignInArkoseApp', () => {
  let wrapper;
  let axiosMock;

  // Finders
  const makeTestIdSelector = (testId) => `[data-testid="${testId}"]`;
  const findByTestId = (testId) => document.querySelector(makeTestIdSelector(testId));
  const findSignInForm = () => findByTestId('sign-in-form');
  const findUsernameInput = () => findByTestId('username-field');
  const findSignInButton = () => findByTestId('sign-in-button');
  const findChallengeContainer = () => wrapper.findByTestId('arkose-labs-challenge');
  const findArkoseLabsErrorMessage = () => wrapper.findByTestId('arkose-labs-error-message');
  const findArkoseLabsVerificationTokenInput = () =>
    wrapper.find('input[name="arkose_labs_token"]');

  // Helpers
  const createForm = (username = '') => {
    loadHTMLFixture('sessions/new.html');
    findUsernameInput().value = username;
  };
  const initArkoseLabs = (username) => {
    createForm(username);
    wrapper = mountExtended(SignInArkoseApp, {
      propsData: {
        publicKey: MOCK_PUBLIC_KEY,
        domain: MOCK_DOMAIN,
        formSelector: makeTestIdSelector('sign-in-form'),
        usernameSelector: makeTestIdSelector('username-field'),
        submitSelector: makeTestIdSelector('sign-in-button'),
      },
    });
  };
  const setUsername = (username) => {
    const input = findUsernameInput();
    input.focus();
    input.value = username;
    input.blur();
  };
  const onSuppress = () => {
    onCompleted(MOCK_ARKOSE_RESPONSE_SUPPRESSED);
    return nextTick();
  };
  const submitForm = () => {
    findSignInForm().dispatchEvent(new Event('submit'));
  };

  // Assertions
  const itInitializesArkoseLabs = () => {
    it("includes ArkoseLabs' script", () => {
      expect(initArkoseLabsScript).toHaveBeenCalledWith({
        publicKey: MOCK_PUBLIC_KEY,
        domain: MOCK_DOMAIN,
      });
    });

    it('creates a hidden input for the verification token', () => {
      const input = findArkoseLabsVerificationTokenInput();

      expect(input.exists()).toBe(true);
      expect(input.element.value).toBe('');
    });
  };
  const expectHiddenArkoseLabsError = () => {
    expect(findArkoseLabsErrorMessage().exists()).toBe(false);
  };
  const expectArkoseLabsInitError = () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.MSG_ARKOSE_FAILURE_BODY);
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper?.destroy();
    resetHTMLFixture();
  });

  describe('when the username field is pre-filled', () => {
    it("does not include ArkoseLabs' script initially", () => {
      expect(initArkoseLabsScript).not.toHaveBeenCalled();
    });

    it('puts the sign-in button in the loading state', async () => {
      initArkoseLabs(MOCK_USERNAME);
      await nextTick();
      const signInButton = findSignInButton();

      expect(signInButton.innerText).toMatchInterpolatedText('Loading');
      expect(signInButton.disabled).toBe(true);
    });

    it('triggers a request to the captcha_check API', async () => {
      initArkoseLabs(MOCK_USERNAME);

      expect(axiosMock.history.post).toHaveLength(0);

      await waitForPromises();

      expect(axiosMock.history.post).toHaveLength(1);
      expect(axiosMock.history.post[0]).toMatchObject({
        url: expect.stringContaining('/users/captcha_check'),
        data: JSON.stringify({
          username: MOCK_USERNAME,
        }),
      });
    });

    describe('if the challenge is not needed', () => {
      beforeEach(async () => {
        axiosMock.onPost().reply(200, { result: false });
        initArkoseLabs(MOCK_USERNAME);
        await waitForPromises();
      });

      it('resets the loading button', () => {
        const signInButton = findSignInButton();

        expect(signInButton.innerText).toMatchInterpolatedText('Sign in');
        expect(signInButton.disabled).toBe(false);
      });

      it('does not show ArkoseLabs error when submitting the form', async () => {
        submitForm();
        await waitForPromises();

        expect(findArkoseLabsErrorMessage().exists()).toBe(false);
      });

      describe('if the challenge becomes needed', () => {
        beforeEach(async () => {
          axiosMock.onPost().reply(200, { result: true });
          setUsername(`malicious-${MOCK_USERNAME}`);
          await waitForPromises();
        });

        itInitializesArkoseLabs();
      });
    });

    describe('when the form is submitted without the username field losing the focus', () => {
      beforeEach(() => {
        initArkoseLabs();
        jest.spyOn(findSignInForm(), 'submit');
        axiosMock.onPost().reply(200, { result: false });
        findUsernameInput().value = `noblur-${MOCK_USERNAME}`;
      });

      it('triggers a username check', async () => {
        expect(axiosMock.history.post).toHaveLength(0);

        submitForm();
        await waitForPromises();

        expect(axiosMock.history.post).toHaveLength(1);
      });

      it("proceeds with the form's submission if the challenge still isn't needed", async () => {
        submitForm();
        await waitForPromises();

        expect(findSignInForm().submit).toHaveBeenCalled();
      });

      describe('when the challenge becomes needed', () => {
        beforeEach(() => {
          axiosMock.onPost().reply(200, { result: true });
          submitForm();
          return waitForPromises();
        });

        it("blocks the form's submission if the challenge becomes needed", () => {
          expect(findSignInForm().submit).not.toHaveBeenCalled();
        });

        it("proceeds with the form's submission if the challenge is being suppressed", async () => {
          await onSuppress();

          expect(findSignInForm().submit).toHaveBeenCalled();
        });
      });
    });

    describe('if the challenge is needed', () => {
      beforeEach(async () => {
        axiosMock.onPost().reply(200, { result: true });
        initArkoseLabs(MOCK_USERNAME);
        await waitForPromises();
      });

      itInitializesArkoseLabs();

      it('shows ArkoseLabs error when submitting the form', async () => {
        onShown();
        submitForm();
        await nextTick();

        expect(findArkoseLabsErrorMessage().exists()).toBe(true);
        expect(wrapper.text()).toContain(wrapper.vm.$options.MSG_ARKOSE_NEEDED);
      });

      it('un-hides the challenge container once the iframe has been shown', async () => {
        expect(findChallengeContainer().isVisible()).toBe(false);

        onShown();
        await nextTick();

        expect(findChallengeContainer().isVisible()).toBe(true);
      });

      it('shows an error alert if the challenge fails to load', async () => {
        expect(wrapper.text()).not.toContain(wrapper.vm.$options.MSG_ARKOSE_FAILURE_BODY);

        const error = new Error();
        onError(error);

        expect(logError).toHaveBeenCalledWith('ArkoseLabs initialization error', error);

        await nextTick();

        expectArkoseLabsInitError();
      });

      it('does not submit the form even if the challenge is being suppressed', async () => {
        jest.spyOn(findSignInForm(), 'submit');
        await onSuppress();

        expect(findSignInForm().submit).not.toHaveBeenCalled();
      });

      describe('when ArkoseLabs calls `onCompleted` handler that has been configured', () => {
        beforeEach(() => {
          submitForm();

          onCompleted(MOCK_ARKOSE_RESPONSE);
        });

        it('removes ArkoseLabs error', () => {
          expectHiddenArkoseLabsError();
        });

        it('does not show again the error when re-submitting the form', () => {
          submitForm();

          expectHiddenArkoseLabsError();
        });

        it("sets the verification token input's value", () => {
          expect(findArkoseLabsVerificationTokenInput().element.value).toBe(
            MOCK_ARKOSE_RESPONSE.token,
          );
        });
      });
    });
  });

  describe('when the username check fails', () => {
    it('with a 404, nothing happens', async () => {
      axiosMock.onPost().reply(404);
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expect(initArkoseLabsScript).not.toHaveBeenCalled();
      expectHiddenArkoseLabsError();
    });

    it('with some other HTTP error, the challenge is initialized', async () => {
      axiosMock.onPost().reply(500);
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expect(initArkoseLabsScript).toHaveBeenCalled();
      expectHiddenArkoseLabsError();
    });

    it('due to the script inclusion, an error is shown', async () => {
      const error = new Error();
      initArkoseLabsScript.mockImplementation(() => {
        throw new Error();
      });
      axiosMock.onPost().reply(200, { result: true });
      initArkoseLabs(MOCK_USERNAME);
      await waitForPromises();

      expectArkoseLabsInitError();
      expect(logError).toHaveBeenCalledWith('ArkoseLabs initialization error', error);
    });
  });
});
