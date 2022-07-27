import { mount } from '@vue/test-utils';
import Vue from 'vue';
import { componentNames } from 'ee/reports/components/issue_body';
import { codequalityParsedIssues } from 'ee_jest/vue_merge_request_widget/mock_data';
import SecurityIssueBody from 'ee/vue_shared/security_reports/components/security_issue_body.vue';
import store from 'ee/vue_shared/security_reports/store';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
  secretDetectionParsedIssues,
} from 'ee_jest/vue_shared/security_reports/mock_data';
import mountComponent, { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import reportIssues from '~/reports/components/report_item.vue';
import { STATUS_FAILED, STATUS_SUCCESS } from '~/reports/constants';

describe('Report issues', () => {
  let vm;
  let wrapper;
  let ReportIssues;

  beforeEach(() => {
    ReportIssues = Vue.extend(reportIssues);
  });

  afterEach(() => {
    if (vm?.$destroy) vm.$destroy();

    if (wrapper) wrapper.destroy();
  });

  describe('for codequality issues', () => {
    describe('resolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssues, {
          issue: codequalityParsedIssues[0],
          component: componentNames.CodequalityIssueBody,
          status: STATUS_SUCCESS,
        });
      });

      it('should render "Fixed" keyword', () => {
        expect(vm.$el.textContent).toContain('Fixed');
        expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toEqual(
          'Fixed: Minor - Insecure Dependency in Gemfile.lock:12',
        );
      });
    });

    describe('unresolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssues, {
          issue: codequalityParsedIssues[0],
          component: componentNames.CodequalityIssueBody,
          status: STATUS_FAILED,
        });
      });

      it('should not render "Fixed" keyword', () => {
        expect(vm.$el.textContent).not.toContain('Fixed');
      });
    });
  });

  describe('with location', () => {
    it('should render location', () => {
      vm = mount(ReportIssues, {
        propsData: {
          issue: sastParsedIssues[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
        stubs: {
          SecurityIssueBody,
        },
      });

      expect(vm.text()).toContain('in');
      expect(vm.find('.report-block-list-issue a').attributes('href')).toEqual(
        sastParsedIssues[0].urlPath,
      );
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      vm = mountComponent(ReportIssues, {
        issue: {
          title: 'foo',
        },
        component: componentNames.SecurityIssueBody,
        status: STATUS_SUCCESS,
      });

      expect(vm.$el.textContent).not.toContain('in');
      expect(vm.$el.querySelector('.report-block-list-issue a')).toEqual(null);
    });
  });

  describe('for container scanning issues', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssues, {
        issue: dockerReportParsed.unapproved[0],
        component: componentNames.SecurityIssueBody,
        status: STATUS_FAILED,
      });
    });

    it('renders severity', () => {
      expect(vm.$el.textContent.trim().toLowerCase()).toContain(
        dockerReportParsed.unapproved[0].severity,
      );
    });

    it('renders CVE name', () => {
      expect(vm.$el.querySelector('.report-block-list-issue button').textContent.trim()).toEqual(
        dockerReportParsed.unapproved[0].title,
      );
    });
  });

  describe('for dast issues', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(ReportIssues, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_FAILED,
        },
      });
    });

    it('renders severity and title', () => {
      expect(vm.$el.textContent).toContain(parsedDast[0].title);
      expect(vm.$el.textContent.toLowerCase()).toContain(`${parsedDast[0].severity}`);
    });
  });

  describe('for secret Detection issues', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssues, {
        issue: secretDetectionParsedIssues[0],
        component: componentNames.SecurityIssueBody,
        status: STATUS_FAILED,
      });
    });

    it('renders severity', () => {
      expect(vm.$el.textContent.trim().toLowerCase()).toContain(
        secretDetectionParsedIssues[0].severity,
      );
    });

    it('renders CVE name', () => {
      expect(vm.$el.querySelector('.report-block-list-issue button').textContent.trim()).toEqual(
        secretDetectionParsedIssues[0].title,
      );
    });
  });
});
