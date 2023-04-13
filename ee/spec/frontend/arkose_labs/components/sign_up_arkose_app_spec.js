import { nextTick } from 'vue';
import { createAlert } from '~/alert';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SignUpArkoseApp from 'ee/arkose_labs/components/sign_up_arkose_app.vue';
import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';
import {
  VERIFICATION_LOADING_MESSAGE,
  VERIFICATION_REQUIRED_MESSAGE,
  VERIFICATION_TOKEN_INPUT_NAME,
} from 'ee/arkose_labs/constants';

jest.mock('~/alert');
jest.mock('ee/arkose_labs/init_arkose_labs_script');
let onShown;
let onCompleted;
initArkoseLabsScript.mockImplementation(() => ({
  setConfig: ({ onShown: shownHandler, onCompleted: completedHandler }) => {
    onShown = shownHandler;
    onCompleted = completedHandler;
  },
}));

const MOCK_ARKOSE_RESPONSE = { token: 'verification-token' };
const MOCK_PUBLIC_KEY = 'arkose-labs-public-api-key';
const MOCK_DOMAIN = 'client-api.arkoselabs.com';

describe('SignUpArkoseApp', () => {
  let wrapper;

  const findChallengeContainer = () => wrapper.findByTestId('arkose-labs-challenge');
  const findArkoseLabsVerificationTokenInput = () =>
    wrapper.find(`input[name="${VERIFICATION_TOKEN_INPUT_NAME}"]`);

  const submitForm = async (event) => {
    wrapper.findComponent(DomElementListener).vm.$emit('submit', event);
    await nextTick();
  };

  const createComponent = () => {
    wrapper = mountExtended(SignUpArkoseApp, {
      propsData: {
        publicKey: MOCK_PUBLIC_KEY,
        domain: MOCK_DOMAIN,
        formSelector: 'dummy',
      },
    });
  };

  afterEach(() => {
    wrapper?.destroy();
  });

  beforeEach(() => {
    createComponent();
  });

  it("includes Arkose Labs' script", () => {
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

  it('shows the challenge container when Arkose Labs calls `onShown`', async () => {
    expect(findChallengeContainer().isVisible()).toBe(false);

    onShown();
    await nextTick();

    expect(findChallengeContainer().isVisible()).toBe(true);
  });

  describe('when Arkose Labs calls `onCompleted`', () => {
    beforeEach(() => {
      onCompleted(MOCK_ARKOSE_RESPONSE);
    });

    it("sets the verification token input's value", () => {
      expect(findArkoseLabsVerificationTokenInput().element.value).toBe(MOCK_ARKOSE_RESPONSE.token);
    });
  });

  describe('when form is submitted', () => {
    let mockSubmitEvent;

    beforeEach(() => {
      mockSubmitEvent = { preventDefault: jest.fn(), stopPropagation: jest.fn() };
    });

    describe('when challenge was not completed', () => {
      beforeEach(async () => {
        onShown();

        await submitForm(mockSubmitEvent);
      });

      it('shows verification required error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: VERIFICATION_REQUIRED_MESSAGE,
        });
      });

      it('stops the submit event', () => {
        expect(mockSubmitEvent.preventDefault).toHaveBeenCalledTimes(1);
        expect(mockSubmitEvent.stopPropagation).toHaveBeenCalledTimes(1);
      });
    });

    describe('when challenge was completed', () => {
      beforeEach(async () => {
        onShown();
        onCompleted(MOCK_ARKOSE_RESPONSE);

        await nextTick();

        submitForm(mockSubmitEvent);
      });

      it('does not show verification required error message', () => {
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not stop the submit event', () => {
        expect(mockSubmitEvent.preventDefault).not.toHaveBeenCalled();
        expect(mockSubmitEvent.stopPropagation).not.toHaveBeenCalled();
      });
    });

    describe('when challenge has not been shown yet (loading)', () => {
      beforeEach(async () => {
        await submitForm(mockSubmitEvent);
      });

      it('shows verification loading message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: VERIFICATION_LOADING_MESSAGE,
        });
      });
    });
  });
});
