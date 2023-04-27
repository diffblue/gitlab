import MaxExpirationDateMessage from 'ee/access_tokens/components/max_expiration_date_message.vue';

import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('MaxExpirationDateMessage', () => {
  let wrapper;

  const date = '2022-03-02';
  const defaultPropsData = {
    maxDate: new Date(date),
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = mountExtended(MaxExpirationDateMessage, {
      propsData,
    });
  };

  describe('when `maxDate` is set', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders max date expiration message', () => {
      expect(wrapper.text()).toContain(
        `An Administrator has set the maximum expiration date to ${date}`,
      );
    });
  });

  describe('when `maxDate` is not set', () => {
    beforeEach(() => {
      createComponent({});
    });

    it('does not render anything', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
