import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PreScanVerificationStatus from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_status.vue';
import { PRE_SCAN_VERIFICATION_STATUS } from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PreScanVerificationStatus', () => {
  let wrapper;
  const defaultProps = {
    pipelineCreatedAt: '2022-09-23 11:19:49 UTC',
    pipelineId: '2343434',
    pipelinePath: 'test-path',
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(PreScanVerificationStatus, {
      propsData: {
        ...defaultProps,
        ...options,
      },
    });
  };

  const timeAgoString = (date) => getTimeago().format(date, timeagoLanguageCode);

  const findStatusButton = () => wrapper.findByTestId('pre-scan-results-btn');
  const findStatusMessage = () => wrapper.findByTestId('status-message');

  describe('status text', () => {
    it.each`
      status                                               | expectedResult
      ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${'Test your configuration and identify potential errors before running a full scan.'}
      ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${`Started ${timeAgoString(defaultProps.pipelineCreatedAt)} in pipeline`}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${`Last run ${timeAgoString(defaultProps.pipelineCreatedAt)} in pipeline`}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${`Last run ${timeAgoString(defaultProps.pipelineCreatedAt)} in pipeline`}
      ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${`Last run ${timeAgoString(defaultProps.pipelineCreatedAt)} in pipeline`}
      ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${`Last run ${timeAgoString(defaultProps.pipelineCreatedAt)} in pipeline`}
    `('should render correct status message', ({ status, expectedResult }) => {
      createComponent({ status });
      expect(findStatusMessage().text()).toContain(expectedResult);
    });
  });

  describe('actions', () => {
    it.each`
      status                                               | expectedResult
      ${PRE_SCAN_VERIFICATION_STATUS.DEFAULT}              | ${'Verify configuration'}
      ${PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS}          | ${'View results'}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE}             | ${'View results'}
      ${PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS} | ${'View results'}
      ${PRE_SCAN_VERIFICATION_STATUS.FAILED}               | ${'View results'}
      ${PRE_SCAN_VERIFICATION_STATUS.INVALIDATED}          | ${'View results'}
    `('should render correct button label', ({ status, expectedResult }) => {
      createComponent({ status });
      expect(findStatusButton().text()).toContain(expectedResult);
    });

    it('should emit correct event', () => {
      createComponent();
      findStatusButton().vm.$emit('click');

      expect(wrapper.emitted()['select-results']).toHaveLength(1);
    });
  });
});
