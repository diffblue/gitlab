import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WeightCount from 'ee/issues/components/weight_count.vue';

describe('WeightCount component', () => {
  const iconName = 'weight';
  const tooltipText = 'Weight';
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);

  const mountComponent = ({ weight = 1, hasIssueWeightsFeature = true } = {}) =>
    shallowMount(WeightCount, {
      propsData: { weight },
      provide: { hasIssueWeightsFeature },
    });

  describe('with issue_weights license', () => {
    describe.each([1, 0])('when weight is %d', (i) => {
      beforeEach(() => {
        wrapper = mountComponent({ weight: i });
      });

      it('renders weight', () => {
        expect(wrapper.text()).toBe(i.toString());
        expect(wrapper.attributes('title')).toBe(tooltipText);
        expect(findIcon().props('name')).toBe(iconName);
      });
    });

    describe('when weight is null', () => {
      beforeEach(() => {
        wrapper = mountComponent({ weight: null });
      });

      it('does not render weight', () => {
        expect(wrapper.text()).toBe('');
      });
    });
  });

  describe('without issue_weights license', () => {
    beforeEach(() => {
      wrapper = mountComponent({ hasIssueWeightsFeature: false });
    });

    it('does not render weight', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
