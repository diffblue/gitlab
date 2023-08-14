import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import { generateHelpTextWithLinks, mapSystemToFriendlyError } from '~/lib/utils/error_utils';

const unfriendlyErrorMessage = 'unfriendly error';
const error = new Error(unfriendlyErrorMessage);
const friendlyError = {
  title: 'friendly title',
  message: 'friendly error message',
  links: {},
};
const errorDictionary = {
  [unfriendlyErrorMessage]: friendlyError,
};
const friendlyErrorHTML = '<a href="https://a.link">A friendly error message with links</a>';
const defaultError = {
  message: 'default error message',
  links: {},
};

jest.mock('~/lib/utils/error_utils', () => ({
  generateHelpTextWithLinks: jest.fn().mockReturnValue(friendlyErrorHTML),
  mapSystemToFriendlyError: jest.fn().mockReturnValue(friendlyError),
}));

describe('Error Alert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ErrorAlert, {
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
      createComponent({ error, errorDictionary, defaultError, dismissible: true });
    });

    it('passes the correct props', () => {
      expect(findAlert().props()).toMatchObject({
        dismissible: true,
        variant: 'danger',
        title: friendlyError.title,
      });
    });

    it('invokes generateHelpTextWithLinks', () => {
      expect(generateHelpTextWithLinks).toHaveBeenCalledWith(friendlyError);
    });

    it('invokes mapSystemToFriendlyError', () => {
      expect(mapSystemToFriendlyError).toHaveBeenCalledWith(error, errorDictionary, defaultError);
    });

    it('passes the correct html', () => {
      expect(findAlert().html()).toContain(friendlyErrorHTML);
    });

    it('emits a dismiss event when dismissing the error', () => {
      findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted('dismiss')).toHaveLength(1);
    });
  });
});
