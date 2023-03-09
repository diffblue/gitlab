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

  it.each`
    status               | variant      | label
    ${STATUS.NONE}       | ${'neutral'} | ${'Not validated'}
    ${STATUS.INPROGRESS} | ${'info'}    | ${'Validating...'}
    ${STATUS.PENDING}    | ${'info'}    | ${'Validating...'}
    ${STATUS.FAILED}     | ${'warning'} | ${'Validation failed'}
    ${STATUS.PASSED}     | ${'success'} | ${'Validated'}
  `('renders a $variant badge for $status status', ({ status, variant, label }) => {
    createComponent({
      propsData: {
        status,
      },
    });

    expect(findBadge().props('variant')).toBe(variant);
    expect(findBadge().text()).toBe(label);
  });
});
