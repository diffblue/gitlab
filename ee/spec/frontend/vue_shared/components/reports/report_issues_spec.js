import { mount } from '@vue/test-utils';
import { componentNames } from 'ee/ci/reports/components/issue_body';
import { codequalityParsedIssues } from 'ee_jest/vue_merge_request_widget/mock_data';
import SecurityIssueBody from 'ee/vue_shared/security_reports/components/security_issue_body.vue';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
  secretDetectionParsedIssues,
} from 'ee_jest/vue_shared/security_reports/mock_data';
import ReportIssues from '~/ci/reports/components/report_item.vue';
import { STATUS_FAILED, STATUS_SUCCESS } from '~/ci/reports/constants';

describe('Report issues', () => {
  let wrapper;

  describe('for codequality issues', () => {
    describe('resolved issues', () => {
      beforeEach(() => {
        wrapper = mount(ReportIssues, {
          propsData: {
            issue: codequalityParsedIssues[0],
            component: componentNames.CodequalityIssueBody,
            status: STATUS_SUCCESS,
          },
        });
      });

      it('should render "Fixed" keyword', () => {
        expect(wrapper.text()).toContain('Fixed');
        expect(wrapper.text()).toMatchInterpolatedText(
          'Fixed: Minor - Insecure Dependency in Gemfile.lock:12',
        );
      });
    });

    describe('unresolved issues', () => {
      beforeEach(() => {
        wrapper = mount(ReportIssues, {
          propsData: {
            issue: codequalityParsedIssues[0],
            component: componentNames.CodequalityIssueBody,
            status: STATUS_FAILED,
          },
        });
      });

      it('should not render "Fixed" keyword', () => {
        expect(wrapper.text()).not.toContain('Fixed');
      });
    });
  });

  describe('with location', () => {
    it('should render location', () => {
      wrapper = mount(ReportIssues, {
        propsData: {
          issue: sastParsedIssues[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
        stubs: {
          SecurityIssueBody,
        },
      });

      expect(wrapper.text()).toContain('in');
      expect(wrapper.find('.report-block-list-issue a').attributes('href')).toEqual(
        sastParsedIssues[0].urlPath,
      );
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      wrapper = mount(ReportIssues, {
        propsData: {
          issue: {
            title: 'foo',
          },
          component: componentNames.SecurityIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(wrapper.text()).not.toContain('in');
      expect(wrapper.find('.report-block-list-issue a').exists()).toBe(false);
    });
  });

  describe('for container scanning issues', () => {
    beforeEach(() => {
      wrapper = mount(ReportIssues, {
        propsData: {
          issue: dockerReportParsed.unapproved[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
      });
    });

    it('renders severity', () => {
      expect(wrapper.text().toLowerCase()).toContain(dockerReportParsed.unapproved[0].severity);
    });

    it('renders CVE name', () => {
      expect(wrapper.find('.report-block-list-issue button').text()).toEqual(
        dockerReportParsed.unapproved[0].title,
      );
    });
  });

  describe('for dast issues', () => {
    beforeEach(() => {
      wrapper = mount(ReportIssues, {
        propsData: {
          issue: parsedDast[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
      });
    });

    it('renders severity and title', () => {
      expect(wrapper.text()).toContain(parsedDast[0].title);
      expect(wrapper.text().toLowerCase()).toContain(`${parsedDast[0].severity}`);
    });
  });

  describe('for secret Detection issues', () => {
    beforeEach(() => {
      wrapper = mount(ReportIssues, {
        propsData: {
          issue: secretDetectionParsedIssues[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
      });
    });

    it('renders severity', () => {
      expect(wrapper.text().toLowerCase()).toContain(secretDetectionParsedIssues[0].severity);
    });

    it('renders CVE name', () => {
      expect(wrapper.find('.report-block-list-issue button').text()).toEqual(
        secretDetectionParsedIssues[0].title,
      );
    });
  });
});
