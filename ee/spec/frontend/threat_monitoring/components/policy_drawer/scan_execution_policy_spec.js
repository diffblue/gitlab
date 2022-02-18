import PolicyDrawerLayout from 'ee/threat_monitoring/components/policy_drawer/policy_drawer_layout.vue';
import ScanExecutionPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_execution_policy.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockScanExecutionPolicy } from '../../mocks/mock_data';

describe('ScanExecutionPolicy component', () => {
  let wrapper;

  const findActions = () => wrapper.findByTestId('policy-actions');
  const findRules = () => wrapper.findByTestId('policy-rules');

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScanExecutionPolicy, {
      propsData,
      stubs: {
        PolicyDrawerLayout,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default policy', () => {
    beforeEach(() => {
      factory({ propsData: { policy: mockScanExecutionPolicy } });
    });

    it.each`
      component    | finder         | text
      ${'actions'} | ${findActions} | ${''}
      ${'rules'}   | ${findRules}   | ${''}
    `('does render the policy $component', ({ finder, text }) => {
      const component = finder();
      expect(component.exists()).toBe(true);
      if (text) {
        expect(component.text()).toBe(text);
      }
    });
  });
});
