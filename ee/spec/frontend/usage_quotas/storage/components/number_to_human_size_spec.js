import { shallowMount } from '@vue/test-utils';
import NumberToHumanSize from 'ee/usage_quotas/storage/components/number_to_human_size.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

let wrapper;

const createComponent = (props = {}) => {
  wrapper = shallowMount(NumberToHumanSize, {
    propsData: {
      ...props,
    },
  });
};

describe('NumberToHumanSize', () => {
  it('formats the value', () => {
    const value = 1024;
    createComponent({ value });

    const expectedValue = numberToHumanSize(value, 1);
    expect(wrapper.text()).toBe(expectedValue);
  });

  it('handles number of fraction digits', () => {
    const value = 1024 + 254;
    const fractionDigits = 2;
    createComponent({ value, fractionDigits });

    const expectedValue = numberToHumanSize(value, fractionDigits);
    expect(wrapper.text()).toBe(expectedValue);
  });
});
