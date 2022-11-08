import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationStep from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_step.vue';
import { PRE_SCAN_VERIFICATION_STATUS } from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationStep', () => {
  let wrapper;
  const defaultProps = {
    step: {
      header: 'Test header',
      text: 'Test content',
    },
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(PreScanVerificationStep, {
      propsData: {
        ...defaultProps,
        ...options,
      },
    });
  };

  const findDownloadButton = () => wrapper.findComponent(GlButton);
  const findPreScanVerificationStepContent = () => wrapper.findByTestId('pre-scan-step-content');
  const findPreScanVerificationStepDivider = () => wrapper.findByTestId('pre-scan-step-divider');
  const findPreScanVerificationStepText = () => wrapper.findByTestId('pre-scan-step-text');

  it('should render correct step content', () => {
    createComponent();

    expect(findPreScanVerificationStepContent().text()).toContain(defaultProps.step.header);
    expect(findPreScanVerificationStepContent().text()).toContain(defaultProps.step.text);
  });

  it.each`
    showDivider | expectedResult
    ${true}     | ${true}
    ${false}    | ${false}
  `('should render step divider based', ({ showDivider, expectedResult }) => {
    createComponent({ showDivider });

    expect(findPreScanVerificationStepDivider().exists()).toEqual(expectedResult);
  });

  it.each`
    status                                               | expectedResult
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${true}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${true}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${true}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${true}
  `('should render download button for certain statuses', ({ status, expectedResult }) => {
    createComponent({ status });

    expect(findDownloadButton().exists()).toEqual(expectedResult);
  });

  it.each`
    status                                               | expectedResult
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${false}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${true}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${true}
  `('should mark content as failed when status is failed', ({ status, expectedResult }) => {
    createComponent({ status });

    expect(findPreScanVerificationStepText().classes('gl-text-red-500')).toEqual(expectedResult);
    expect(findPreScanVerificationStepText().classes('gl-text-gray-500')).toEqual(!expectedResult);
  });
});
