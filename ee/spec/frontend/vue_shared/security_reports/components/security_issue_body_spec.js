import { shallowMount } from '@vue/test-utils';
import {
  CRITICAL,
  HIGH,
  MEDIUM,
  LOW,
} from 'ee/security_dashboard/store/modules/vulnerabilities/constants';
import SecurityIssueBody from 'ee/vue_shared/security_reports/components/security_issue_body.vue';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ReportLink from '~/ci/reports/components/report_link.vue';
import { STATUS_FAILED } from '~/ci/reports/constants';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
  dependencyScanningIssues,
  secretDetectionParsedIssues,
} from '../mock_data';

describe('Security Issue Body', () => {
  let wrapper;

  const findReportLink = () => wrapper.findComponent(ReportLink);

  const createComponent = (issue) => {
    wrapper = extendedWrapper(
      shallowMount(SecurityIssueBody, {
        propsData: {
          issue,
          status: STATUS_FAILED,
        },
      }),
    );
  };

  describe.each([
    ['SAST', sastParsedIssues[0], true, HIGH],
    ['DAST', parsedDast[0], false, LOW],
    ['Container Scanning', dockerReportParsed.vulnerabilities[0], false, MEDIUM],
    ['Dependency Scanning', dependencyScanningIssues[0], true],
    ['Secret Detection', secretDetectionParsedIssues[0], false, CRITICAL],
  ])('for a %s vulnerability', (name, vuln, hasReportLink, severity) => {
    beforeEach(() => {
      createComponent(vuln);
    });

    if (severity) {
      it(`shows SeverityBadge if severity is present`, () => {
        expect(wrapper.findComponent(SeverityBadge).props('severity')).toBe(severity);
      });
    } else {
      it(`does not show SeverityBadge if severity is not present`, () => {
        expect(wrapper.findComponent(SeverityBadge).exists()).toBe(false);
      });
    }

    it(`does ${hasReportLink ? '' : 'not '}render report link`, () => {
      expect(findReportLink().exists()).toBe(hasReportLink);
    });

    it.each([true, false])(
      `shows a "dismissed" info correctly when the vulnerability's "isDismissed" property is set to "%s`,
      (isDismissed) => {
        createComponent({ ...vuln, isDismissed });

        expect(wrapper.findByTestId('dismissed-badge').exists()).toBe(isDismissed);
      },
    );
  });
});
