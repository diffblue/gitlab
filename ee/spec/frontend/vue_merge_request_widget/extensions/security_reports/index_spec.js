import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import securityReportsExtension from 'ee/vue_merge_request_widget/extensions/security_reports';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { addedResponse, emptyResponse, fixedResponse } from './mock_data';

describe('License Compliance extension', () => {
  let wrapper;
  let mock;

  registerExtension(securityReportsExtension);

  const sastEndpoint = '/group-name/project-name/-/merge_requests/78/sast_reports';
  const dastEndpoint = '/group-name/project-name/-/merge_requests/78/dasy_reports';
  const secretDetectionEndpoint =
    '/group-name/project-name/-/merge_requests/78/secret_detection_reports';
  const apiFuzzingEndpoint = '/group-name/project-name/-/merge_requests/78/api_fuzzing_reports';
  const coverageFuzzingEndpoint =
    '/group-name/project-name/-/merge_requests/78/coverage_fuzzing_reports';
  const dependencyScanningEndpoint =
    '/group-name/project-name/-/merge_requests/78/dependency_scanning';

  const mockAllApiCalls = (statusCode, data) => {
    mock.onGet(sastEndpoint).reply(statusCode, data);
    mock.onGet(dastEndpoint).reply(statusCode, data);
    mock.onGet(secretDetectionEndpoint).reply(statusCode, data);
    mock.onGet(apiFuzzingEndpoint).reply(statusCode, data);
    mock.onGet(coverageFuzzingEndpoint).reply(statusCode, data);
    mock.onGet(dependencyScanningEndpoint).reply(statusCode, data);
  };

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          securityReportPaths: {
            sastReportPath: sastEndpoint,
            dastReportPath: dastEndpoint,
            secretDetectionReportPath: secretDetectionEndpoint,
            apiFuzzingReportPath: apiFuzzingEndpoint,
            coverageFuzzingReportPath: coverageFuzzingEndpoint,
            dependencyScanningReportPath: dependencyScanningEndpoint,
          },
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockAllApiCalls(HTTP_STATUS_OK, emptyResponse());
      createComponent();
      expect(wrapper.text()).toBe('Security scanning is loading');
    });

    it('displays failed loading text', async () => {
      mockAllApiCalls(HTTP_STATUS_INTERNAL_SERVER_ERROR, emptyResponse());
      createComponent();
      await waitForPromises();
      expect(wrapper.text()).toBe('Security reports failed loading results');
    });

    it('displays the summary correctly', async () => {
      mock.onGet(sastEndpoint).reply(HTTP_STATUS_OK, addedResponse());
      mock.onGet(dastEndpoint).reply(HTTP_STATUS_OK, fixedResponse());
      mock.onGet(secretDetectionEndpoint).reply(HTTP_STATUS_OK, emptyResponse());
      mock.onGet(apiFuzzingEndpoint).reply(HTTP_STATUS_OK, addedResponse());
      mock.onGet(coverageFuzzingEndpoint).reply(HTTP_STATUS_OK, emptyResponse());
      mock.onGet(dependencyScanningEndpoint).reply(HTTP_STATUS_OK, emptyResponse());
      createComponent();
      await waitForPromises();
      expect(wrapper.text()).toContain(
        'Security scanning detected 6 new potential vulnerabilities',
      );
    });
  });
});
