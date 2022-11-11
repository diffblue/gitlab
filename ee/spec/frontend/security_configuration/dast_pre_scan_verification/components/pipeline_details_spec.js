import { getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineDetails from 'ee/security_configuration/dast_pre_scan_verification/components/pipeline_details.vue';
import { PRE_SCAN_VERIFICATION_STATUS } from 'ee/security_configuration/dast_pre_scan_verification/constants';

describe('PipelineDetails', () => {
  let wrapper;
  const defaultProps = {
    pipelineCreatedAt: '2022-09-23 11:19:49 UTC',
    pipelineId: '2343434',
    pipelinePath: 'test-path',
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(PipelineDetails, {
      propsData: {
        ...defaultProps,
        ...options,
      },
    });
  };

  const timeAgoString = (date) => getTimeago().format(date, timeagoLanguageCode);

  const findStatusMessage = () => wrapper.findByTestId('status-message');

  describe('status text', () => {
    it.each`
      status                                               | expectedResult
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

  describe('status case', () => {
    it.each`
      isLowerCase | expectedResult
      ${true}     | ${'last run'}
      ${false}    | ${'Last run'}
    `('should render status in lower case or capitalized', ({ isLowerCase, expectedResult }) => {
      createComponent({ isLowerCase, status: PRE_SCAN_VERIFICATION_STATUS.COMPLETE });
      expect(findStatusMessage().text()).toContain(expectedResult);
    });
  });
});
