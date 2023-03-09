import { shallowMount } from '@vue/test-utils';
import MrWidgetPolicyViolation from 'ee/vue_merge_request_widget/components/states/mr_widget_policy_violation.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

describe('EE MrWidgetPolicyViolation', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MrWidgetPolicyViolation, {
      propsData: {
        mr: {},
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows the disabled reason', () => {
    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain('Merge blocked:');
    expect(message).toContain('denied licenses must be removed.');
  });
});
