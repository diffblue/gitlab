import ScanExecutionPolicy from 'ee/security_orchestration/components/policy_drawer/scan_execution_policy.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  mockUnsupportedAttributeScanExecutionPolicy,
  mockProjectScanExecutionPolicy,
  mockNoActionsScanExecutionManifest,
  mockMultipleActionsScanExecutionManifest,
} from '../../mocks/mock_scan_execution_policy_data';

describe('ScanExecutionPolicy component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');

  const factory = ({ propsData } = {}) => {
    wrapper = mountExtended(ScanExecutionPolicy, {
      propsData,
      provide: { namespaceType: NAMESPACE_TYPES.PROJECT },
    });
  };

  describe.each`
    title                                   | propsData
    ${'default policy'}                     | ${{ policy: mockProjectScanExecutionPolicy }}
    ${'no action policy'}                   | ${{ policy: { ...mockProjectScanExecutionPolicy, yaml: mockNoActionsScanExecutionManifest } }}
    ${'multiple action policy'}             | ${{ policy: { ...mockProjectScanExecutionPolicy, yaml: mockMultipleActionsScanExecutionManifest } }}
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
