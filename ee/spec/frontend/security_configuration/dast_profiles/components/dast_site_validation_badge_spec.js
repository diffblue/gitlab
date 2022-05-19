import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DastSiteValidationBadge from 'ee/security_configuration/dast_profiles/components/dast_site_validation_badge.vue';
import { DAST_SITE_VALIDATION_STATUS as STATUS } from 'ee/security_configuration/dast_site_validation/constants';

describe('EE - DastSiteValidationBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(DastSiteValidationBadge, options);
  };
  const createComponent = wrapperFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    status               | variant
    ${STATUS.NONE}       | ${'neutral'}
    ${STATUS.INPROGRESS} | ${'info'}
    ${STATUS.PENDING}    | ${'info'}
    ${STATUS.FAILED}     | ${'warning'}
    ${STATUS.PASSED}     | ${'success'}
  `('renders a $variant badge for $status status', ({ status, variant }) => {
    createComponent({
      propsData: {
        status,
      },
    });

    expect(findBadge().props('variant')).toBe(variant);
  });
});
