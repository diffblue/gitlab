import { GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import StatusChecksReportApp from 'ee/reports/status_checks_report/status_checks_reports_app.vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import ReportSection from '~/reports/components/report_section.vue';
import { status as reportStatus } from '~/reports/constants';
import { approvedChecks, pendingChecks, approvedAndPendingChecks } from './mock_data';

jest.mock('~/flash');

describe('Grouped test reports app', () => {
  let wrapper;
  let mock;

  const endpoint = 'http://test';

  const findReport = () => wrapper.findComponent(ReportSection);

  const mountComponent = () => {
    wrapper = shallowMount(StatusChecksReportApp, {
      propsData: {
        endpoint,
      },
      stubs: {
        ReportSection,
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('when mounted', () => {
    beforeEach(() => {
      mock.onGet(endpoint).reply(() => new Promise(() => {}));
      mountComponent();
    });

    it('configures the report section', () => {
      expect(findReport().props()).toEqual(
        expect.objectContaining({
          status: reportStatus.LOADING,
          component: 'StatusCheckIssueBody',
          showReportSectionStatusIcon: false,
          resolvedIssues: [],
          neutralIssues: [],
          hasIssues: false,
        }),
      );
    });

    it('matches the default state component snapshot', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('when the status checks have been fetched', () => {
    const mountWithResponse = (statusCode, data) => {
      mock.onGet(endpoint).reply(statusCode, data);
      mountComponent();
      return waitForPromises();
    };

    describe.each`
      state         | response                    | text            | resolvedIssues    | neutralIssues
      ${'approved'} | ${approvedChecks}           | ${'All passed'} | ${approvedChecks} | ${[]}
      ${'pending'}  | ${pendingChecks}            | ${'1 pending'}  | ${[]}             | ${pendingChecks}
      ${'mixed'}    | ${approvedAndPendingChecks} | ${'1 pending'}  | ${approvedChecks} | ${pendingChecks}
    `('and the status checks are $state', ({ response, text, resolvedIssues, neutralIssues }) => {
      beforeEach(() => {
        return mountWithResponse(httpStatus.OK, response);
      });

      it('sets the report status to success', () => {
        expect(findReport().props('status')).toBe(reportStatus.SUCCESS);
      });

      it('sets the issues on the report', () => {
        expect(findReport().props('hasIssues')).toBe(true);
        expect(findReport().props('resolvedIssues')).toStrictEqual(resolvedIssues);
        expect(findReport().props('neutralIssues')).toStrictEqual(neutralIssues);
      });

      it(`renders '${text}' in the report section`, () => {
        expect(findReport().text()).toContain(text);
      });
    });

    describe('and an error occurred', () => {
      beforeEach(() => {
        jest.spyOn(Sentry, 'captureException');

        return mountWithResponse(httpStatus.NOT_FOUND);
      });

      it('sets the report status to error', () => {
        expect(findReport().props('status')).toBe(reportStatus.ERROR);
      });

      it('shows the error text', () => {
        expect(findReport().text()).toContain('Failed to load status checks.');
      });

      it('captures the error', () => {
        expect(Sentry.captureException.mock.calls[0]).toEqual([expect.any(Error)]);
      });
    });
  });
});
