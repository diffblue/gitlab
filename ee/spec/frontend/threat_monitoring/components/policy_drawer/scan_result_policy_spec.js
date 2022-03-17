import PolicyDrawerLayout from 'ee/threat_monitoring/components/policy_drawer/policy_drawer_layout.vue';
import ScanResultPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_result_policy.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockScanResultPolicy } from '../../mocks/mock_data';

describe('ScanResultPolicy component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScanResultPolicy, {
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
      factory({ propsData: { policy: mockScanResultPolicy } });
    });

    it('does render the policy summary', () => {
      expect(findSummary().exists()).toBe(true);
    });
  });
});
