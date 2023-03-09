import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DastScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';

describe('EE - DastScanTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(DastScanTypeBadge, options);
  };
  const createComponent = wrapperFactory();

  it.each`
    scanType             | variant
    ${SCAN_TYPE.ACTIVE}  | ${'warning'}
    ${SCAN_TYPE.PASSIVE} | ${'neutral'}
  `('renders a $variant badge for $scanType scans', ({ scanType, variant }) => {
    createComponent({
      propsData: {
        scanType,
      },
    });

    expect(findBadge().props('variant')).toBe(variant);
  });
});
