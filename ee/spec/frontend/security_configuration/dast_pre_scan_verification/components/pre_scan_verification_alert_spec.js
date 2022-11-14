import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationAlert from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_alert.vue';
import PipelineDetails from 'ee/security_configuration/dast_pre_scan_verification/components/pipeline_details.vue';
import {
  PRE_SCAN_VERIFICATION_STATUS,
  ALERT_VARIANT_STATUS_MAP,
} from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationAlert', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(PreScanVerificationAlert, {
      propsData: {
        ...propsData,
      },
      stubs: {
        PipelineDetails: true,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPipelineDetails = () => wrapper.findComponent(PipelineDetails);

  it.each`
    status                                               | variant
    ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${ALERT_VARIANT_STATUS_MAP[PRE_SCAN_VERIFICATION_STATUS.DEFAULT]}
    ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${'info'}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${ALERT_VARIANT_STATUS_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE]}
    ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${ALERT_VARIANT_STATUS_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]}
    ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${ALERT_VARIANT_STATUS_MAP[PRE_SCAN_VERIFICATION_STATUS.FAILED]}
    ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${ALERT_VARIANT_STATUS_MAP[PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]}
  `('should render correct alert variant for status', ({ status, variant }) => {
    createComponent({ status });

    expect(findAlert().props('variant')).toEqual(variant);
  });

  it.each`
    pipelineCreatedAt            | expectedResult
    ${'2022-09-23 11:19:49 UTC'} | ${true}
    ${''}                        | ${false}
  `(
    'should render pipeline details when date is provided',
    ({ pipelineCreatedAt, expectedResult }) => {
      createComponent({ pipelineCreatedAt });
      expect(findPipelineDetails().exists()).toBe(expectedResult);
    },
  );

  it('should dismiss alert', async () => {
    createComponent();
    await findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismiss')).toHaveLength(1);
  });
});
