import BasePolicy from 'ee/threat_monitoring/components/policy_drawer/base_policy.vue';
import ScanExecutionPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_execution_policy.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockSecretDetectionScanExecutionManifest,
  mockScanExecutionPolicy,
} from '../../mocks/mock_data';

describe('ScanExecutionPolicy component', () => {
  let wrapper;

  const findActions = () => wrapper.findByTestId('policy-actions');
  const findDescription = () => wrapper.findByTestId('policy-description');
  const findLatestScan = () => wrapper.findByTestId('policy-latest-scan');
  const findRules = () => wrapper.findByTestId('policy-rules');
  const findEnabledText = () => wrapper.findByTestId('enabled-status-text');
  const findNotEnabledText = () => wrapper.findByTestId('not-enabled-status-text');

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ScanExecutionPolicy, {
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
      factory({ propsData: { policy: mockScanExecutionPolicy } });
    });

    it.each`
      component         | finder             | text
      ${'actions'}      | ${findActions}     | ${''}
      ${'rules'}        | ${findRules}       | ${''}
      ${'description'}  | ${findDescription} | ${'This policy enforces pipeline configuration to have a job with DAST scan'}
      ${'latest scan'}  | ${findLatestScan}  | ${''}
      ${'enabled text'} | ${findEnabledText} | ${''}
    `('does render the policy $component', ({ finder, text }) => {
      const component = finder();
      expect(component.exists()).toBe(true);
      if (text) {
        expect(component.text()).toBe(text);
      }
    });
  });

  describe('not enabled policy', () => {
    beforeEach(() => {
      factory({ propsData: { policy: { ...mockScanExecutionPolicy, enabled: false } } });
    });

    it('does render the policy not enabled text', () => {
      expect(findNotEnabledText().exists()).toBe(true);
    });
  });

  describe('empty policy', () => {
    beforeEach(() => {
      factory({
        propsData: {
          policy: {
            ...mockScanExecutionPolicy,
            latestScan: undefined,
            yaml: mockSecretDetectionScanExecutionManifest,
          },
        },
      });
    });

    it.each`
      component        | finder
      ${'description'} | ${findDescription}
      ${'latest scan'} | ${findLatestScan}
    `('does render the policy $component', ({ finder }) => {
      expect(finder().exists()).toBe(false);
    });
  });
});
