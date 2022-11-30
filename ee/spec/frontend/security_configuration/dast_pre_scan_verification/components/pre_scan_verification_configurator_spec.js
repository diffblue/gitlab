import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationConfigurator from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_configurator.vue';
import PreScanVerificationStatus from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_status.vue';
import PreScanVerificationSidebar from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_sidebar.vue';

describe('PreScanVerificationConfigurator', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(PreScanVerificationConfigurator, {
      propsData: {
        ...propsData,
      },
    });
  };

  const findPreScanVerificationStatus = () => wrapper.findComponent(PreScanVerificationStatus);
  const findPreScanVerificationSidebar = () => wrapper.findComponent(PreScanVerificationSidebar);

  it('should open and close sidebar', async () => {
    createComponent();
    expect(findPreScanVerificationSidebar().props('open')).toBe(false);

    findPreScanVerificationStatus().vm.$emit('select-results');
    await nextTick();

    expect(findPreScanVerificationSidebar().props('open')).toBe(true);

    findPreScanVerificationSidebar().vm.$emit('close');
    await nextTick();

    expect(wrapper.emitted('open-drawer')).toHaveLength(1);
    expect(findPreScanVerificationSidebar().props('open')).toBe(false);
  });

  it.each`
    showTrigger | expectedResult
    ${true}     | ${true}
    ${false}    | ${false}
  `('should render side drawer trigger', ({ showTrigger, expectedResult }) => {
    createComponent({ showTrigger });

    expect(findPreScanVerificationStatus().exists()).toBe(expectedResult);
  });
});
