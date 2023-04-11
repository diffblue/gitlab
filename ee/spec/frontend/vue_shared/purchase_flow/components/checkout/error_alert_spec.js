import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PurchaseErrorAlert from 'ee/vue_shared/purchase_flow/components/checkout/error_alert.vue';
import {
  generateHelpTextWithLinks,
  mapSystemToFriendlyError,
} from 'ee/vue_shared/purchase_flow/utils/purchase_errors';

const error = new Error('An error');
const friendlyError = 'A friendly error';
const friendlyErrorHTML = '<a href="https://a.link">A friendly error message with links</a>';

jest.mock('ee/vue_shared/purchase_flow/utils/purchase_errors', () => ({
  generateHelpTextWithLinks: jest.fn().mockReturnValue(friendlyErrorHTML),
  mapSystemToFriendlyError: jest.fn().mockReturnValue(friendlyError),
}));

describe('Purchase Error Alert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (props = { error: undefined }) => {
    wrapper = shallowMount(PurchaseErrorAlert, {
      propsData: props,
    });
  };

  describe('with no error', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('with an error', () => {
    beforeEach(() => {
      createComponent({ error });
    });

    it('passes the correct props', () => {
      expect(findAlert().props()).toMatchObject({
        dismissible: false,
        variant: 'danger',
      });
    });

    it('invokes generateHelpTextWithLinks', () => {
      expect(generateHelpTextWithLinks).toHaveBeenCalledWith(friendlyError);
    });

    it('invokes mapSystemToFriendlyError', () => {
      expect(mapSystemToFriendlyError).toHaveBeenCalledWith(error);
    });

    it('passes the correct html', () => {
      expect(findAlert().html()).toContain(friendlyErrorHTML);
    });
  });
});
