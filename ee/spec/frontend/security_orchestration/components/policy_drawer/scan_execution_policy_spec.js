import ScanExecutionPolicy from 'ee/security_orchestration/components/policy_drawer/scan_execution_policy.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  mockProjectScanExecutionPolicy,
  mockScanExecutionManifestNoActions,
  mockScanExecutionManifestMultipleActions,
  mockUnsupportedAttributeScanExecutionPolicy,
} from '../../mocks/mock_data';

describe('ScanExecutionPolicy component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');

  const factory = ({ propsData } = {}) => {
    wrapper = mountExtended(ScanExecutionPolicy, {
      propsData,
      provide: { namespaceType: NAMESPACE_TYPES.PROJECT },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    title                                   | propsData
    ${'default policy'}                     | ${{ policy: mockProjectScanExecutionPolicy }}
    ${'no action policy'}                   | ${{ policy: { ...mockProjectScanExecutionPolicy, yaml: mockScanExecutionManifestNoActions } }}
    ${'multiple action policy'}             | ${{ policy: { ...mockProjectScanExecutionPolicy, yaml: mockScanExecutionManifestMultipleActions } }}
    ${'policy with unsupported attributes'} | ${{ policy: mockUnsupportedAttributeScanExecutionPolicy }}
  `('$title', ({ propsData }) => {
    beforeEach(() => {
      factory({ propsData });
    });

    it('renders the correct policy action message', () => {
      expect(findSummary().element).toMatchSnapshot();
    });
  });
});
