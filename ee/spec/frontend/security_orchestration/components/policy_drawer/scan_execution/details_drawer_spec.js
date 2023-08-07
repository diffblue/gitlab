import DetailsDrawer from 'ee/security_orchestration/components/policy_drawer/scan_execution/details_drawer.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  mockUnsupportedAttributeScanExecutionPolicy,
  mockProjectScanExecutionPolicy,
  mockNoActionsScanExecutionManifest,
  mockMultipleActionsScanExecutionManifest,
  mockCiVariablesWithTagsScanExecutionManifest,
} from '../../../mocks/mock_scan_execution_policy_data';

describe('DetailsDrawer component', () => {
  let wrapper;

  const findSummary = () => wrapper.findByTestId('policy-summary');

  const factory = ({ propsData } = {}) => {
    wrapper = mountExtended(DetailsDrawer, {
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
    ${'policy with tags and CI variables'}  | ${{ policy: { ...mockProjectScanExecutionPolicy, yaml: mockCiVariablesWithTagsScanExecutionManifest } }}
  `('$title', ({ propsData }) => {
    beforeEach(() => {
      factory({ propsData });
    });

    it('renders the correct policy action message', () => {
      expect(findSummary().element).toMatchSnapshot();
    });
  });
});
