import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationSummary from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_summary.vue';
import {
  PRE_SCAN_VERIFICATION_STATUS,
  SUMMARY_STATUS_STYLE_MAP,
  DEFAULT_STYLING_SUMMARY_STYLING,
  STATUS_LABEL_MAP,
} from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationSummary', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(PreScanVerificationSummary, {
      propsData: {
        ...options,
      },
    });
  };

  const findPreScanIcon = () => wrapper.findComponent(GlIcon);
  const findPreScanStatus = () => wrapper.findByTestId('pre-scan-status');

  it.each`
    status                                               | output
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${DEFAULT_STYLING_SUMMARY_STYLING}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.FAILED]}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]}
  `('should render correct icon for statuses', ({ status, output }) => {
    createComponent({ status });

    expect(findPreScanIcon().props('name')).toEqual(output.icon);
    expect(findPreScanIcon().attributes('class')).toContain(output.iconColor);
  });

  it.each`
    status                                               | output
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.DEFAULT]}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.FAILED]}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]}
  `('should render correct label for statuses', ({ status, output }) => {
    createComponent({ status });

    expect(findPreScanStatus().text()).toEqual(output);
  });
});
