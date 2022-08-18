import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
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

  const createComponent = (props = {}) => {
    wrapper = mount(ExpiresAtField, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  const findMaxExpirationDateMessage = () => wrapper.findComponent(MaxExpirationDateMessage);

  afterEach(() => {
    wrapper?.destroy();
  });

  it('renders a description', () => {
    const description = 'My description';
    createComponent({ description });

    expect(wrapper.text()).toContain(description);
    expect(findMaxExpirationDateMessage().exists()).toBe(false);
  });

  it('renders `MaxExpirationDateMessage` message component', async () => {
    createComponent();
    await nextTick();

    expect(findMaxExpirationDateMessage().exists()).toBe(true);
  });

  it('sets `GlDatepicker` `maxDate` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlDatepicker).props('maxDate')).toEqual(defaultPropsData.maxDate);
  });
});
