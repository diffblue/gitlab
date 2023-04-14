import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import getStateQueryResponse from 'test_fixtures/graphql/merge_requests/get_state.query.graphql.json';
import readyToMergeResponse from 'test_fixtures/graphql/merge_requests/states/ready_to_merge.query.graphql.json';

import {
  registerExtension,
  registeredExtensions,
} from '~/vue_merge_request_widget/components/extensions';

// Force Jest to transpile and cache
// eslint-disable-next-line no-unused-vars
import _GroupedLoadPerformanceReportsApp from 'ee/ci/reports/load_performance_report/grouped_load_performance_reports_app.vue';

import MrWidgetOptions from 'ee/vue_merge_request_widget/mr_widget_options.vue';
import WidgetContainer from 'ee/vue_merge_request_widget/components/widget/app.vue';
// Force Jest to transpile and cache
// eslint-disable-next-line no-unused-vars
import _GroupedSecurityReportsApp from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';

// EE Widget Extensions
import licenseComplianceExtension from 'ee/vue_merge_request_widget/extensions/license_compliance';

import {
  sastDiffSuccessMock,
  dastDiffSuccessMock,
  containerScanningDiffSuccessMock,
  dependencyScanningDiffSuccessMock,
  secretDetectionDiffSuccessMock,
  coverageFuzzingDiffSuccessMock,
  apiFuzzingDiffSuccessMock,
} from 'ee_jest/vue_shared/security_reports/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { securityReportMergeRequestDownloadPathsQueryResponse } from 'jest/vue_shared/security_reports/mock_data';

import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';

// Force Jest to transpile and cache
// eslint-disable-next-line no-unused-vars
import _Deployment from '~/vue_merge_request_widget/components/deployment/deployment.vue';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_shared/security_reports/graphql/queries/security_report_merge_request_download_paths.query.graphql';

import getStateQuery from '~/vue_merge_request_widget/queries/get_state.query.graphql';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import mergeQuery from '~/vue_merge_request_widget/queries/states/new_ready_to_merge.query.graphql';
import approvalsQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import securityReportSummaryQuery from 'ee/vue_shared/security_reports/graphql/mr_security_report_summary.graphql';

import mockData from './mock_data';

jest.mock('~/vue_shared/components/help_popover.vue');

Vue.use(VueApollo);

const SAST_SELECTOR = '.js-sast-widget';
const DAST_SELECTOR = '.js-dast-widget';
const DEPENDENCY_SCANNING_SELECTOR = '.js-dependency-scanning-widget';
const CONTAINER_SCANNING_SELECTOR = '.js-container-scanning';
const SECRET_DETECTION_SELECTOR = '.js-secret-detection';
const COVERAGE_FUZZING_SELECTOR = '.js-coverage-fuzzing-widget';
const API_FUZZING_SELECTOR = '.js-api-fuzzing-widget';

describe('ee merge request widget options', () => {
  let wrapper;
  let mock;

  const createComponent = (options) => {
    wrapper = mount(MrWidgetOptions, {
      ...options,
      apolloProvider: createMockApollo([
        [approvalsQuery, jest.fn().mockResolvedValue(approvedByCurrentUser)],
        [getStateQuery, jest.fn().mockResolvedValue(getStateQueryResponse)],
        [readyToMergeQuery, jest.fn().mockResolvedValue(readyToMergeResponse)],
        [
          securityReportMergeRequestDownloadPathsQuery,
          jest
            .fn()
            .mockResolvedValue({ data: securityReportMergeRequestDownloadPathsQueryResponse }),
        ],
        [securityReportSummaryQuery, jest.fn().mockResolvedValue({ data: { project: null } })],
        [
          mergeQuery,
          jest.fn().mockResolvedValue({
            data: {
              project: { id: 1, mergeRequest: { id: 1, userPermissions: { canMerge: true } } },
            },
          }),
        ],
      ]),
      data() {
        return {
          loading: false,
        };
      },
    });
  };

  beforeEach(() => {
    gon.features = { asyncMrWidget: true };
    gl.mrWidgetData = { ...mockData };

    mock = new MockAdapter(axios);

    mock.onGet(mockData.merge_request_widget_path).reply(() => [HTTP_STATUS_OK, gl.mrWidgetData]);
    mock
      .onGet(mockData.merge_request_cached_widget_path)
      .reply(() => [HTTP_STATUS_OK, gl.mrWidgetData]);
  });

  afterEach(() => {
    registeredExtensions.extensions = [];

    // This is needed because the `fetchInitialData` is triggered while
    // the `mock.restore` is trying to clean up, causing a bunch of
    // unmocked requests...
    // This is not ideal and will be cleaned up in
    // https://gitlab.com/gitlab-org/gitlab/-/issues/214032
    return waitForPromises().then(() => {
      wrapper.destroy();
      wrapper = null;
      mock.restore();
    });
  });

  const findExtendedSecurityWidget = () => wrapper.find('.js-security-widget');
  const findBaseSecurityWidget = () => wrapper.find('[data-testid="security-mr-widget"]');
  const findWidgetContainer = () => wrapper.findComponent(WidgetContainer);

  const VULNERABILITY_FEEDBACK_ENDPOINT = 'vulnerability_feedback_path';

  describe('SAST', () => {
    const SAST_DIFF_ENDPOINT = 'sast_diff_endpoint';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        enabled_reports: {
          sast: true,
        },
        sast_comparison_path: SAST_DIFF_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios, { delayResponse: 1 });
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, sastDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        wrapper.vm.loading = false;
      });

      it('should render loading indicator', () => {
        expect(findExtendedSecurityWidget().find(SAST_SELECTOR).text()).toContain(
          'SAST is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, sastDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);
        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${SAST_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual('SAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others');
      });
    });

    describe('with empty successful request', () => {
      beforeEach(() => {
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, { added: [], existing: [] });
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${SAST_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual('SAST detected no new vulnerabilities.');
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(trimText(findExtendedSecurityWidget().find(SAST_SELECTOR).text())).toContain(
          'SAST: Loading resulted in an error',
        );
      });
    });
  });

  describe('Dependency Scanning', () => {
    const DEPENDENCY_SCANNING_ENDPOINT = 'dependency_scanning_diff_endpoint';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        enabled_reports: {
          dependency_scanning: true,
        },
        dependency_scanning_comparison_path: DEPENDENCY_SCANNING_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios, { delayResponse: 1 });
        mock
          .onGet(DEPENDENCY_SCANNING_ENDPOINT)
          .reply(HTTP_STATUS_OK, dependencyScanningDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
      });

      it('should render loading indicator', () => {
        expect(
          trimText(findExtendedSecurityWidget().find(DEPENDENCY_SCANNING_SELECTOR).text()),
        ).toContain('Dependency scanning is loading');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock
          .onGet(DEPENDENCY_SCANNING_ENDPOINT)
          .reply(HTTP_STATUS_OK, dependencyScanningDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${DEPENDENCY_SCANNING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual(
          'Dependency scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('with full report and no added or fixed issues', () => {
      beforeEach(() => {
        mock.onGet(DEPENDENCY_SCANNING_ENDPOINT).reply(HTTP_STATUS_OK, {
          added: [],
          fixed: [],
          existing: [{ title: 'Mock finding' }],
        });
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('renders no vulnerabilities message', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${DEPENDENCY_SCANNING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual('Dependency scanning detected no new vulnerabilities.');
      });
    });

    describe('with empty successful request', () => {
      beforeEach(() => {
        mock
          .onGet(DEPENDENCY_SCANNING_ENDPOINT)
          .reply(HTTP_STATUS_OK, { added: [], fixed: [], existing: [] });
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${DEPENDENCY_SCANNING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual('Dependency scanning detected no new vulnerabilities.');
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onAny().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(
          trimText(findExtendedSecurityWidget().find(DEPENDENCY_SCANNING_SELECTOR).text()),
        ).toContain('Dependency scanning: Loading resulted in an error');
      });
    });
  });

  describe('Container Scanning', () => {
    const CONTAINER_SCANNING_ENDPOINT = 'container_scanning';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        enabled_reports: {
          container_scanning: true,
        },
        container_scanning_comparison_path: CONTAINER_SCANNING_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios, { delayResponse: 1 });
        mock
          .onGet(CONTAINER_SCANNING_ENDPOINT)
          .reply(HTTP_STATUS_OK, containerScanningDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
      });

      it('should render loading indicator', () => {
        expect(
          trimText(findExtendedSecurityWidget().find(CONTAINER_SCANNING_SELECTOR).text()),
        ).toContain('Container scanning is loading');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock
          .onGet(CONTAINER_SCANNING_ENDPOINT)
          .reply(HTTP_STATUS_OK, containerScanningDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${CONTAINER_SCANNING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual(
          'Container scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(CONTAINER_SCANNING_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(findExtendedSecurityWidget().find(CONTAINER_SCANNING_SELECTOR).text()).toContain(
          'Container scanning: Loading resulted in an error',
        );
      });
    });
  });

  describe('DAST', () => {
    const DAST_ENDPOINT = 'dast_report';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        enabled_reports: {
          dast: true,
        },
        dast_comparison_path: DAST_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios, { delayResponse: 1 });
        mock.onGet(DAST_ENDPOINT).reply(HTTP_STATUS_OK, dastDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
      });

      it('should render loading indicator', () => {
        expect(findExtendedSecurityWidget().find(DAST_SELECTOR).text()).toContain(
          'DAST is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet(DAST_ENDPOINT).reply(HTTP_STATUS_OK, dastDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${DAST_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual('DAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others');
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(DAST_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(findExtendedSecurityWidget().find(DAST_SELECTOR).text()).toContain(
          'DAST: Loading resulted in an error',
        );
      });
    });
  });

  describe('Coverage Fuzzing', () => {
    const COVERAGE_FUZZING_ENDPOINT = 'coverage_fuzzing_report';

    const createComponentWithFeatureFlag = () => {
      createComponent({
        propsData: { mrData: gl.mrWidgetData },
        provide: {
          glFeatures: { coverageFuzzingMrWidget: true },
        },
      });
    };

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        target_project_full_path: '',
        enabled_reports: {
          coverage_fuzzing: true,
        },
        coverage_fuzzing_comparison_path: COVERAGE_FUZZING_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet(COVERAGE_FUZZING_ENDPOINT).reply(HTTP_STATUS_OK, coverageFuzzingDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);
        createComponentWithFeatureFlag();

        expect(findExtendedSecurityWidget().find(COVERAGE_FUZZING_SELECTOR).text()).toContain(
          'Coverage fuzzing is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet(COVERAGE_FUZZING_ENDPOINT).reply(HTTP_STATUS_OK, coverageFuzzingDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);
        createComponentWithFeatureFlag();
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${COVERAGE_FUZZING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual(
          'Coverage fuzzing detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(COVERAGE_FUZZING_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        createComponentWithFeatureFlag();
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(findExtendedSecurityWidget().find(COVERAGE_FUZZING_SELECTOR).text()).toContain(
          'Coverage fuzzing: Loading resulted in an error',
        );
      });
    });
  });

  describe('Secret Detection', () => {
    const SECRET_DETECTION_ENDPOINT = 'secret_detection_report';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        enabled_reports: {
          secret_detection: true,
          // The below property needs to exist until
          // secret Detection is implemented in backend
          // Or for some other reason I'm yet to find
          dast: true,
        },
        secret_detection_comparison_path: SECRET_DETECTION_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet(SECRET_DETECTION_ENDPOINT).reply(HTTP_STATUS_OK, secretDetectionDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });

        expect(
          trimText(findExtendedSecurityWidget().find(SECRET_DETECTION_SELECTOR).text()),
        ).toContain('Secret detection is loading');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet(SECRET_DETECTION_ENDPOINT).reply(HTTP_STATUS_OK, secretDetectionDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${SECRET_DETECTION_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual(
          'Secret detection detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(SECRET_DETECTION_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(findExtendedSecurityWidget().find(SECRET_DETECTION_SELECTOR).text()).toContain(
          'Secret detection: Loading resulted in an error',
        );
      });
    });
  });

  describe('API Fuzzing', () => {
    const API_FUZZING_ENDPOINT = 'api_fuzzing_report';

    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        target_project_full_path: '',
        enabled_reports: {
          api_fuzzing: true,
        },
        api_fuzzing_comparison_path: API_FUZZING_ENDPOINT,
        vulnerability_feedback_path: VULNERABILITY_FEEDBACK_ENDPOINT,
      };
    });

    describe('when it is loading', () => {
      it('should render loading indicator', async () => {
        mock.onGet(API_FUZZING_ENDPOINT).reply(HTTP_STATUS_OK, apiFuzzingDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });

        await nextTick();

        expect(trimText(findExtendedSecurityWidget().find(API_FUZZING_SELECTOR).text())).toContain(
          'API fuzzing is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet(API_FUZZING_ENDPOINT).reply(HTTP_STATUS_OK, apiFuzzingDiffSuccessMock);
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_OK, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render provided data', () => {
        expect(
          trimText(
            findExtendedSecurityWidget()
              .find(`${API_FUZZING_SELECTOR} .report-block-list-issue-description`)
              .text(),
          ),
        ).toEqual(
          'API fuzzing detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet(API_FUZZING_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        mock.onGet(VULNERABILITY_FEEDBACK_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

        createComponent({ propsData: { mrData: gl.mrWidgetData } });
        return axios.waitForAll();
      });

      it('should render error indicator', () => {
        expect(findExtendedSecurityWidget().find(API_FUZZING_SELECTOR).text()).toContain(
          'API fuzzing: Loading resulted in an error',
        );
      });
    });
  });

  describe('CE security report', () => {
    describe.each`
      context                               | canReadVulnerabilities | hasPipeline | shouldRender
      ${'user cannot read vulnerabilities'} | ${false}               | ${true}     | ${true}
      ${'user can read vulnerabilities'}    | ${true}                | ${true}     | ${false}
      ${'no pipeline'}                      | ${false}               | ${false}    | ${false}
    `('given $context', ({ canReadVulnerabilities, hasPipeline, shouldRender }) => {
      beforeEach(() => {
        gl.mrWidgetData = {
          ...mockData,
          can_read_vulnerabilities: canReadVulnerabilities,
          pipeline: hasPipeline ? mockData.pipeline : undefined,
        };

        createComponent({
          propsData: { mrData: gl.mrWidgetData },
        });

        return waitForPromises();
      });

      it(`${shouldRender ? 'renders' : 'does not render'} the CE security report`, () => {
        expect(findBaseSecurityWidget().exists()).toBe(shouldRender);
      });
    });
  });

  describe('computed', () => {
    describe('shouldRenderApprovals', () => {
      it('should return false when in empty state', () => {
        createComponent({
          propsData: {
            mrData: {
              ...mockData,
              has_approvals_available: true,
            },
          },
        });
        wrapper.vm.mr.state = 'nothingToMerge';

        expect(wrapper.vm.shouldRenderApprovals).toBe(false);
      });

      it('should return true when requiring approvals and in non-empty state', () => {
        createComponent({
          propsData: {
            mrData: {
              ...mockData,
              has_approvals_available: true,
            },
          },
        });
        wrapper.vm.mr.state = 'readyToMerge';

        expect(wrapper.vm.shouldRenderApprovals).toBe(true);
      });
    });
  });

  describe('rendering deployments', () => {
    const deploymentMockData = {
      id: 15,
      name: 'review/diplo',
      url: '/root/acets-review-apps/environments/15',
      stop_url: '/root/acets-review-apps/environments/15/stop',
      metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
      metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
      external_url: 'http://diplo.',
      external_url_formatted: 'diplo.',
      deployed_at: '2017-03-22T22:44:42.258Z',
      deployed_at_formatted: 'Mar 22, 2017 10:44pm',
      status: SUCCESS,
    };

    beforeEach(async () => {
      createComponent({
        propsData: {
          mrData: {
            ...mockData,
          },
        },
      });

      wrapper.vm.mr.deployments.push(
        {
          ...deploymentMockData,
        },
        {
          ...deploymentMockData,
          id: deploymentMockData.id + 1,
        },
      );

      await nextTick();
    });

    it('renders multiple deployments', () => {
      expect(wrapper.findAll('.deploy-heading')).toHaveLength(2);
    });
  });

  describe('CI widget', () => {
    it('renders the branch in the pipeline widget', () => {
      const sourceBranchLink = '<a href="/to/the/past">Link</a>';
      createComponent({
        propsData: {
          mrData: {
            ...mockData,
            source_branch_with_namespace_link: sourceBranchLink,
          },
        },
      });

      const ciWidget = wrapper.find('.mr-state-widget .label-branch');

      expect(ciWidget.html()).toContain(sourceBranchLink);
    });
  });

  describe('data', () => {
    it('passes approval api paths to service', () => {
      const paths = {
        api_approvals_path: `${TEST_HOST}/api/approvals/path`,
        api_approval_settings_path: `${TEST_HOST}/api/approval/settings/path`,
        api_approve_path: `${TEST_HOST}/api/approve/path`,
        api_unapprove_path: `${TEST_HOST}/api/unapprove/path`,
      };

      createComponent({
        propsData: {
          mrData: {
            ...mockData,
            ...paths,
          },
        },
      });

      expect(wrapper.vm.service).toMatchObject(convertObjectPropsToCamelCase(paths));
    });
  });

  describe('when no security reports are enabled', () => {
    const noSecurityReportsEnabledCases = [
      undefined,
      {},
      { foo: true },
      { license_scanning: true },
      {
        dast: false,
        sast: false,
        container_scanning: false,
        dependency_scanning: false,
        secret_detection: false,
      },
    ];

    noSecurityReportsEnabledCases.forEach((noSecurityReportsEnabled) => {
      it('does not render the security reports widget', () => {
        gl.mrWidgetData = {
          ...mockData,
          enabled_reports: noSecurityReportsEnabled,
        };

        if (noSecurityReportsEnabled?.license_scanning) {
          // Provide license report config if it's going to be rendered
          gl.mrWidgetData.license_scanning = {
            managed_licenses_path: `${TEST_HOST}/manage_license_api`,
            can_manage_licenses: false,
          };
        }

        createComponent({ propsData: { mrData: gl.mrWidgetData } });

        expect(findExtendedSecurityWidget().exists()).toBe(false);
      });
    });
  });

  describe('given the user cannot read vulnerabilites', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        can_read_vulnerabilities: false,
        enabled_reports: {
          sast: true,
        },
      };

      createComponent({ propsData: { mrData: gl.mrWidgetData } });
    });

    it('does not render the EE security report', () => {
      expect(findExtendedSecurityWidget().exists()).toBe(false);
    });
  });

  describe('license scanning report', () => {
    it.each`
      shouldRegisterExtension | description
      ${true}                 | ${'extension is registered'}
      ${false}                | ${'extension is not registered'}
    `(
      'should render license widget is "$shouldRegisterExtension" when $description',
      ({ shouldRegisterExtension }) => {
        const licenseComparisonPath =
          '/group-name/project-name/-/merge_requests/78/license_scanning_reports';
        const licenseComparisonPathCollapsed =
          '/group-name/project-name/-/merge_requests/78/license_scanning_reports_collapsed';
        const fullReportPath = '/group-name/project-name/-/merge_requests/78/full_report';
        const settingsPath = '/group-name/project-name/-/licenses#licenses';
        const apiApprovalsPath = '/group-name/project-name/-/licenses#policies';

        gl.mrWidgetData = {
          ...mockData,
          license_scanning_comparison_path: licenseComparisonPath,
          license_scanning_comparison_collapsed_path: licenseComparisonPathCollapsed,
          api_approvals_path: apiApprovalsPath,
          license_scanning: {
            settings_path: settingsPath,
            full_report_path: fullReportPath,
          },
        };

        if (shouldRegisterExtension) {
          registerExtension(licenseComplianceExtension);
        }

        createComponent({ propsData: { mrData: gl.mrWidgetData } });

        expect(wrapper.findComponent({ name: 'WidgetLicenseCompliance' }).exists()).toBe(
          shouldRegisterExtension,
        );
      },
    );
  });

  describe('widget container', () => {
    afterEach(() => {
      delete window.gon.features.refactorSecurityExtension;
    });

    it('should not be displayed when the refactor_security_extension feature flag is turned off', () => {
      createComponent({ propsData: { mrData: gl.mrWidgetData } });
      expect(findWidgetContainer().exists()).toBe(false);
    });

    it('should be displayed when the refactor_security_extension feature flag is turned on', () => {
      window.gon = { features: { refactorSecurityExtension: true } };
      createComponent({ propsData: { mrData: gl.mrWidgetData } });
      expect(findWidgetContainer().exists()).toBe(true);
    });
  });
});
