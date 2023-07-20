import { GlProgressBar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';

describe('UsageStatistics', () => {
  let wrapper;

  const createWrapper = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(UsageStatistics, {
      propsData: props,
      slots,
    });
  };

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the component properly', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('does not render the progress bar', () => {
      expect(wrapper.findComponent(GlProgressBar).exists()).toBe(false);
    });
  });

  describe('with usage value and unit', () => {
    const usageUnit = 'GB';
    const usageValue = '10';

    beforeEach(() => {
      createWrapper({ props: { usageUnit, usageValue } });
    });

    it('renders the usage value', () => {
      expect(wrapper.findByTestId('usage').text()).toBe(`${usageValue}${usageUnit}`);
    });

    it('renders the usage unit', () => {
      expect(wrapper.findByTestId('usage-unit').text()).toBe(usageUnit);
    });
  });

  describe('with total value and unit', () => {
    const totalUnit = 'GB';
    const totalValue = '100';

    beforeEach(() => {
      createWrapper({ props: { totalUnit, totalValue, usageValue: '10' } });
    });

    it('renders the total value', () => {
      expect(wrapper.findByTestId('total').text()).toBe(`/ ${totalValue}${totalUnit}`);
    });

    it('renders the total unit', () => {
      expect(wrapper.findByTestId('total-unit').text()).toBe(totalUnit);
    });
  });

  describe('with percentage', () => {
    const percentage = 50;

    it('renders the progress', () => {
      createWrapper({ props: { percentage } });

      expect(wrapper.findComponent(GlProgressBar).attributes('value')).toBe(`${percentage}`);
    });
  });

  describe('slots', () => {
    const slotContent = 'test slot content';

    it('renders the description slot', () => {
      createWrapper({ slots: { description: slotContent } });

      expect(wrapper.text()).toContain(slotContent);
    });

    it('renders the actions slot', () => {
      createWrapper({ slots: { actions: slotContent } });

      expect(wrapper.text()).toContain(slotContent);
    });

    it('renders the additional-info slot', () => {
      createWrapper({ slots: { 'additional-info': slotContent } });

      expect(wrapper.text()).toContain(slotContent);
    });
  });
});
