import BasePolicy from 'ee/threat_monitoring/components/policy_drawer/base_policy.vue';
import ScanResultPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_result_policy.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockScanResultPolicy } from '../../mocks/mock_data';

describe('ScanResultPolicy component', () => {
  let wrapper;

  const findDescription = () => wrapper.findByTestId('policy-description');
  const findRules = () => wrapper.findByTestId('policy-rules');

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScanResultPolicy, {
      propsData,
      stubs: {
        BasePolicy,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default policy', () => {
    beforeEach(() => {
      factory({ propsData: { policy: mockScanResultPolicy } });
    });

    it.each`
      component        | finder             | text
      ${'rules'}       | ${findRules}       | ${''}
      ${'description'} | ${findDescription} | ${'This policy enforces critical vulnerability CS approvals'}
    `('does render the policy $component', ({ finder, text }) => {
      const component = finder();
      expect(component.exists()).toBe(true);
      if (text) {
        expect(component.text()).toBe(text);
      }
    });
  });
});
