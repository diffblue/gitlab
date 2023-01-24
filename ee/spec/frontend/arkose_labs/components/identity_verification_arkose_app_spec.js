import { nextTick } from 'vue';
import { GlForm, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import IdentityVerificationArkoseApp from 'ee/arkose_labs/components/identity_verification_arkose_app.vue';
import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';
import { VERIFICATION_TOKEN_INPUT_NAME, CHALLENGE_CONTAINER_CLASS } from 'ee/arkose_labs/constants';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
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
const MOCK_SESSION_VERIFICATION_PATH = '/session/verification/path';

describe('IdentityVerificationArkoseApp', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findForm = () => wrapper.findComponent(GlForm);
  const findArkoseLabsVerificationTokenInput = () =>
    findForm().find(`input[name="${VERIFICATION_TOKEN_INPUT_NAME}"]`);

  const createComponent = () => {
    wrapper = mount(IdentityVerificationArkoseApp, {
      propsData: {
        publicKey: MOCK_PUBLIC_KEY,
        domain: MOCK_DOMAIN,
        sessionVerificationPath: MOCK_SESSION_VERIFICATION_PATH,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it("includes Arkose Labs' script", () => {
    expect(initArkoseLabsScript).toHaveBeenCalledWith({
      publicKey: MOCK_PUBLIC_KEY,
      domain: MOCK_DOMAIN,
    });
  });

  it('renders the challenge container', () => {
    expect(wrapper.find(`.${CHALLENGE_CONTAINER_CLASS}`).exists()).toBe(true);
  });

  describe('rendered form', () => {
    it('has the correct attributes', () => {
      const form = findForm();
      expect(form.attributes('action')).toBe(MOCK_SESSION_VERIFICATION_PATH);
      expect(form.attributes('method')).toBe('post');
    });

    it('contains a hidden input for the verification token', () => {
      const input = findArkoseLabsVerificationTokenInput();

      expect(input.attributes('type')).toBe('hidden');
      expect(input.element.value).toBe('');
    });

    it('contains a hidden input for the authenticity_token', () => {
      const input = findForm().find('input[name="authenticity_token"]');
      expect(input.attributes('type')).toBe('hidden');
      expect(input.attributes('value')).toBe('mock-csrf-token');
    });
  });

  it('shows a loading icon and removes it when Arkose Labs calls `onShown`', async () => {
    expect(findLoadingIcon().exists()).toBe(true);

    onShown();
    await nextTick();

    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('when Arkose Labs calls `onCompleted`', () => {
    let formSubmitSpy;

    beforeEach(() => {
      formSubmitSpy = jest.spyOn(findForm().element, 'submit');

      onCompleted(MOCK_ARKOSE_RESPONSE);
    });

    it("sets the verification token input's value", () => {
      expect(findArkoseLabsVerificationTokenInput().element.value).toBe(MOCK_ARKOSE_RESPONSE.token);
    });

    it('submits the form', () => {
      expect(formSubmitSpy).toHaveBeenCalledTimes(1);
    });
  });
});
