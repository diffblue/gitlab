import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PreScanVerificationIcon from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_icon.vue';
import {
  DEFAULT_STYLING,
  PRE_SCAN_VERIFICATION_STATUS,
  STATUS_STYLE_MAP,
} from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationIcon', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = shallowMount(PreScanVerificationIcon, {
      propsData: {
        ...options,
      },
    });
  };

  const findBasicIcon = () => wrapper.findComponent(GlBadge);
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

    expect(findBasicIcon().props('icon')).toContain(output.icon);
    expect(findBasicIcon().props('variant')).toEqual(output.variant);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('should render loading icon when in progress', () => {
    createComponent({ status: PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS });

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findBasicIcon().exists()).toBe(false);
  });

  it('should fall back to a default styling if status is invalid', () => {
    createComponent({ status: 'Invalid status ' });

    expect(findBasicIcon().props('icon')).toContain(DEFAULT_STYLING.icon);
    expect(findBasicIcon().props('variant')).toContain(DEFAULT_STYLING.variant);
  });
});
