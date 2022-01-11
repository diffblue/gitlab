import { shallowMount } from '@vue/test-utils';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import MrWidgetPolicyViolation from 'ee/vue_merge_request_widget/components/states/mr_widget_policy_violation.vue';

describe('EE MrWidgetPolicyViolation', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponent(StatusIcon);

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
    expect(findStatusIcon().props('showDisabledButton')).toBe(true);
  });

  it('shows the disabled reason', () => {
    expect(wrapper.text()).toContain('Merge blocked: denied licenses must be removed.');
  });
});
