import PolicyDrawerVariables from 'ee/security_orchestration/components/policy_drawer/scan_execution/humanized_actions/variables.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PolicyDrawerVariables', () => {
  let wrapper;

  const createComponent = (variables) => {
    wrapper = shallowMountExtended(PolicyDrawerVariables, {
      propsData: {
        criteria: { variables },
      },
    });
  };

  it('renders nothing when action has no variables', () => {
    createComponent([]);

    expect(wrapper.text()).toEqual('');
  });

  it('renders each variable', () => {
    createComponent([
      { variable: 'variable1', value: 'value1' },
      { variable: 'variable2', value: 'value2' },
    ]);

    expect(wrapper.text()).toContain('variable1: value1');
    expect(wrapper.text()).toContain('variable2: value2');
  });
});
