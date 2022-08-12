import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import { buildDefaultAction } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import { ACTION_AND_LABEL } from 'ee/security_orchestration/components/policy_editor/constants';

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = (props = {}) => {
    wrapper = mountExtended(PolicyActionBuilder, {
      propsData: {
        initAction: buildDefaultAction(),
        actionIndex: 0,
        ...props,
      },
    });
  };

  const findActionLabel = () => wrapper.findByTestId('action-component-label');

  it('renders correctly with DAST as the default scanner', async () => {
    factory();
    await nextTick();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders an additional action correctly', async () => {
    factory({ actionIndex: 1 });
    await nextTick();

    expect(findActionLabel().text()).toBe(ACTION_AND_LABEL);
  });
});
