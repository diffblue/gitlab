import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyRule from 'ee/approvals/components/empty_rule.vue';

describe('Empty Rule', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(EmptyRule, {
      propsData: {
        rule: {},
        ...props,
      },
    });
  };

  describe('multiple rules', () => {
    it('does not display "Add approval rule" button', () => {
      createComponent({
        allowMultiRule: true,
        canEdit: true,
      });
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('single rule', () => {
    it('displays "Add approval rule" button if allowed to edit', () => {
      createComponent({
        allowMultiRule: false,
        canEdit: true,
      });

      expect(wrapper.findComponent(GlButton).exists()).toBe(true);
    });

    it('does not display "Add approval rule" button if not allowed to edit', () => {
      createComponent({
        allowMultiRule: true,
        canEdit: false,
      });
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });
});
