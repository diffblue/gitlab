import { shallowMount } from '@vue/test-utils';
import TrendIndicator from 'ee/analytics/dashboards/components/trend_indicator.vue';

describe('Analytics trend indicator', () => {
  let wrapper;

  function createComponent(propsData = {}) {
    wrapper = shallowMount(TrendIndicator, { propsData });
  }

  it('renders a positive change with green text', () => {
    createComponent({ change: 100 });
    expect(wrapper.classes('gl-text-green-500')).toBe(true);
  });

  it('renders a negative change with red text', () => {
    createComponent({ change: -100 });
    expect(wrapper.classes('gl-text-red-500')).toBe(true);
  });

  it('renders a positive change with red text when invertColor = true', () => {
    createComponent({ change: 100, invertColor: true });
    expect(wrapper.classes('gl-text-red-500')).toBe(true);
  });

  it('renders a negative change with green text when invertColor = true', () => {
    createComponent({ change: -100, invertColor: true });
    expect(wrapper.classes('gl-text-green-500')).toBe(true);
  });
});
