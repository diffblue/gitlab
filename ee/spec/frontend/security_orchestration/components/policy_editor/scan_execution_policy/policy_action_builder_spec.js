import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import { buildDefaultAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mountExtended(PolicyActionBuilder, {
      propsData: {
        initAction: buildDefaultAction(),
        ...options,
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  it('renders correctly with DAST as the default scanner', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
