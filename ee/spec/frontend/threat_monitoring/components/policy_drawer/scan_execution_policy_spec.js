import ScanExecutionPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_execution_policy.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockScanExecutionPolicy,
  mockScanExecutionManifestNoActions,
  mockScanExecutionManifestMultipleActions,
} from '../../mocks/mock_data';

describe('ScanExecutionPolicy component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');

  const factory = ({ propsData } = {}) => {
    wrapper = mountExtended(ScanExecutionPolicy, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    title                       | propsData
    ${'default policy'}         | ${{ policy: mockScanExecutionPolicy }}
    ${'no action policy'}       | ${{ policy: { ...mockScanExecutionPolicy, yaml: mockScanExecutionManifestNoActions } }}
    ${'multiple action policy'} | ${{ policy: { ...mockScanExecutionPolicy, yaml: mockScanExecutionManifestMultipleActions } }}
  `('$title', ({ propsData }) => {
    beforeEach(() => {
      factory({ propsData });
    });

    it('renders the correct policy action message', () => {
      expect(findSummary().element).toMatchSnapshot();
    });
  });
});
