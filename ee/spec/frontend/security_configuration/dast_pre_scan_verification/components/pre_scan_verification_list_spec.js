import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationList from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_list.vue';
import PreScanVerificationStep from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_step.vue';
import {
  PRE_SCAN_VERIFICATION_STATUS,
  PRE_SCAN_VERIFICATION_STEPS,
} from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationList', () => {
  let wrapper;
  const EXPECTED_NUMBER_OF_STEPS = PRE_SCAN_VERIFICATION_STEPS.length;

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(PreScanVerificationList, {
      propsData: {
        ...options,
      },
    });
  };

  const findSubmitButton = () => wrapper.findByTestId('pre-scan-verification-submit');
  const findPreScanVerificationSteps = () => wrapper.findAllComponents(PreScanVerificationStep);

  it('should render correct number of steps', () => {
    createComponent();

    expect(findPreScanVerificationSteps()).toHaveLength(EXPECTED_NUMBER_OF_STEPS);
  });

  it.each`
    status                                               | variant      | category       | text
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${'confirm'} | ${'primary'}   | ${'Save and run verification'}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${'danger'}  | ${'secondary'} | ${'Cancel pre-scan verification'}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${'confirm'} | ${'primary'}   | ${'Save and run verification'}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${'confirm'} | ${'primary'}   | ${'Save and run verification'}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${'confirm'} | ${'primary'}   | ${'Save and run verification'}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${'confirm'} | ${'primary'}   | ${'Save and run verification'}
  `(
    'should render correct variant and category of a submit button',
    ({ status, variant, category, text }) => {
      createComponent({ status });

      /**
       * Add coverage for a tooltip
       * when disabled functionality is ready
       */
      expect(findSubmitButton().props('variant')).toEqual(variant);
      expect(findSubmitButton().props('category')).toEqual(category);
      expect(findSubmitButton().text()).toContain(text);
    },
  );
});
