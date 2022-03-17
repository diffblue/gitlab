import { mount } from '@vue/test-utils';
import { GlDatepicker } from '@gitlab/ui';

import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import MaxExpirationDateMessage from 'ee/access_tokens/components/max_expiration_date_message.vue';

describe('~/access_tokens/components/expires_at_field', () => {
  let wrapper;

  const defaultPropsData = {
    inputAttrs: {
      id: 'personal_access_token_expires_at',
      name: 'personal_access_token[expires_at]',
      placeholder: 'YYYY-MM-DD',
    },
    maxDate: new Date('2022-3-2'),
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = mount(ExpiresAtField, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders `MaxExpirationDateMessage` message component', () => {
    expect(wrapper.findComponent(MaxExpirationDateMessage).exists()).toBe(true);
  });

  it('sets `GlDatepicker` `maxDate` prop', () => {
    expect(wrapper.findComponent(GlDatepicker).props('maxDate')).toEqual(defaultPropsData.maxDate);
  });
});
