import { GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationIcon from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_icon.vue';
import {
  DEFAULT_STYLING,
  PRE_SCAN_VERIFICATION_STATUS,
  STATUS_STYLE_MAP,
} from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationIcon', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = mountExtended(PreScanVerificationIcon, {
      propsData: {
        ...options,
      },
    });
  };

  const findBasicIconWrapper = () => wrapper.findByTestId('pre-scan-verification-icon-wrapper');
  const findBasicIcon = () => wrapper.findByTestId('pre-scan-verification-icon');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  it.each`
    status                                               | output
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.DEFAULT]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.FAILED]}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]}
  `('should render correct icon and style based on status', ({ status, output }) => {
    createComponent({ status });

    expect(findBasicIcon().attributes('class')).toContain(output.iconColor);
    expect(findBasicIcon().props('name')).toEqual(output.icon);
    expect(findBasicIcon().attributes('aria-label')).toEqual(output.icon);
    expect(findBasicIconWrapper().attributes('class')).toContain(output.bgColor);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('should render loading icon when in progress', () => {
    createComponent({ status: PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS });

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findBasicIcon().exists()).toBe(false);
  });

  it('should fall back to a default styling if status is invalid', () => {
    createComponent({ status: 'Invalid status ' });

    expect(findBasicIcon().attributes('class')).toContain(DEFAULT_STYLING.iconColor);
    expect(findBasicIcon().attributes('aria-label')).toEqual(DEFAULT_STYLING.icon);
    expect(findBasicIconWrapper().attributes('class')).toContain(DEFAULT_STYLING.bgColor);
  });
});
