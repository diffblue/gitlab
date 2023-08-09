import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import { generateHelpTextWithLinks, mapSystemToFriendlyError } from '~/lib/utils/error_utils';

const error = new Error('An error');
const friendlyError = 'A friendly error';
const friendlyErrorHTML = '<a href="https://a.link">A friendly error message with links</a>';
const errorDictionary = {
  'unfriendly error': {
    message: 'friendly error message',
    links: {},
  },
};
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
      createComponent({ error, errorDictionary, defaultError });
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
      expect(mapSystemToFriendlyError).toHaveBeenCalledWith(error, errorDictionary, defaultError);
    });

    it('passes the correct html', () => {
      expect(findAlert().html()).toContain(friendlyErrorHTML);
    });
  });
});
