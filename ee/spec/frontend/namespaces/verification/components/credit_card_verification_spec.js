import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CreditCardVerification from 'ee/namespaces/verification/components/credit_card_verification.vue';
import { I18N_FORM_TITLE, I18N_FORM_EXPLANATION } from 'ee/namespaces/verification/constants';

describe('Verification page', () => {
  let wrapper;

  const DEFAULT_PROVIDES = {
    verificationFormUrl: 'https://gitlab.com',
    subscriptionsUrl: 'https://gitlab.com',
  };

  const createComponent = (opts) => {
    wrapper = mountExtended(CreditCardVerification, {
      provide: DEFAULT_PROVIDES,
      ...opts,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title', () => {
      expect(wrapper.findByText(I18N_FORM_TITLE).exists()).toBe(true);
    });

    it('renders the explanation', () => {
      expect(wrapper.findByText(I18N_FORM_EXPLANATION).exists()).toBe(true);
    });
  });

  describe('successful verification', () => {
    let mockPostMessage;

    const setup = async () => {
      const dispatchWindowMessageEvent = () => {
        window.dispatchEvent(
          new MessageEvent('message', {
            origin: DEFAULT_PROVIDES.subscriptionsUrl,
            data: { success: true },
          }),
        );
      };

      createComponent({
        attachTo: document.body,
      });

      // mock load event so success event listeners are registered
      await wrapper.find('iframe').trigger('load');

      // mock success event arrival when postMessage is called on the Zuora iframe
      mockPostMessage = jest
        .spyOn(wrapper.find('iframe').element.contentWindow, 'postMessage')
        .mockImplementation(dispatchWindowMessageEvent);

      wrapper.findComponent(GlButton).vm.$emit('click');
    };

    it('triggers postMessage on the Zuora iframe', async () => {
      await setup();

      expect(mockPostMessage).toHaveBeenCalledWith('submit', DEFAULT_PROVIDES.subscriptionsUrl);
    });

    it('emits verified event', async () => {
      await setup();

      expect(wrapper.emitted('verified')).toHaveLength(1);
    });
  });
});
