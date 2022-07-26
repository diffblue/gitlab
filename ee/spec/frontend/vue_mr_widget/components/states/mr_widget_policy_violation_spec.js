import { shallowMount } from '@vue/test-utils';
import MrWidgetPolicyViolation from 'ee/vue_merge_request_widget/components/states/mr_widget_policy_violation.vue';

describe('EE MrWidgetPolicyViolation', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MrWidgetPolicyViolation, {});
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('shows the disabled merge button', () => {
    expect(wrapper.text()).toContain('Merge');
  });

  it('shows the disabled reason', () => {
    expect(wrapper.text()).toContain('Merge blocked: denied licenses must be removed.');
  });
});
