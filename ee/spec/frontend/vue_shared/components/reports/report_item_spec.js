import { mount } from '@vue/test-utils';
import Vue from 'vue';
import { componentNames, iconComponentNames } from 'ee/reports/components/issue_body';
import { codequalityParsedIssues } from 'ee_jest/vue_merge_request_widget/mock_data';
import LicenseIssueBody from 'ee/vue_shared/license_compliance/components/license_issue_body.vue';
import LicenseStatusIcon from 'ee/vue_shared/license_compliance/components/license_status_icon.vue';
import SecurityIssueBody from 'ee/vue_shared/security_reports/components/security_issue_body.vue';
import store from 'ee/vue_shared/security_reports/store';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
  secretDetectionParsedIssues,
  licenseComplianceParsedIssues,
} from 'ee_jest/vue_shared/security_reports/mock_data';
import mountComponent, { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import reportIssue from '~/reports/components/report_item.vue';
import { STATUS_FAILED, STATUS_SUCCESS, STATUS_NEUTRAL } from '~/reports/constants';

describe('Report issue', () => {
  let vm;
  let wrapper;
  let ReportIssue;

  beforeEach(() => {
    ReportIssue = Vue.extend(reportIssue);
  });

  afterEach(() => {
    if (vm?.$destroy) vm.$destroy();

    if (wrapper) wrapper.destroy();
  });

  describe('for codequality issue', () => {
    describe('resolved issue', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssue, {
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

    describe('unresolved issue', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssue, {
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
      vm = mount(ReportIssue, {
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
      expect(vm.find('li a').attributes('href')).toEqual(sastParsedIssues[0].urlPath);
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      vm = mount(ReportIssue, {
        propsData: {
          issue: {
            title: 'foo',
          },
          component: componentNames.SecurityIssueBody,
          status: STATUS_SUCCESS,
        },
        stubs: {
          SecurityIssueBody,
        },
      });

      expect(vm.text()).not.toContain('in');
      expect(vm.find('a').exists()).toBe(false);
    });
  });

  describe('for container scanning issue', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssue, {
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
      expect(vm.$el.querySelector('button').textContent.trim()).toEqual(
        dockerReportParsed.unapproved[0].title,
      );
    });
  });

  describe('for dast issue', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(ReportIssue, {
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

  describe('for secret Description issue', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssue, {
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
      expect(vm.$el.querySelector('button').textContent.trim()).toEqual(
        secretDetectionParsedIssues[0].title,
      );
    });
  });

  describe('for license compliance issue', () => {
    it('renders LicenseIssueBody & LicenseStatusIcon', () => {
      wrapper = mount(ReportIssue, {
        propsData: {
          issue: licenseComplianceParsedIssues[0],
          component: componentNames.LicenseIssueBody,
          iconComponent: iconComponentNames.LicenseStatusIcon,
          status: STATUS_NEUTRAL,
        },
        stubs: {
          LicenseIssueBody,
          LicenseStatusIcon,
        },
      });

      expect(wrapper.findComponent(LicenseIssueBody).exists()).toBe(true);
      expect(wrapper.findComponent(LicenseStatusIcon).exists()).toBe(true);
    });
  });

  describe('showReportSectionStatusIcon', () => {
    it('does not render CI Status Icon when showReportSectionStatusIcon is false', () => {
      vm = mountComponentWithStore(ReportIssue, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_SUCCESS,
          showReportSectionStatusIcon: false,
        },
      });

      expect(vm.$el.querySelectorAll('.report-block-list-icon')).toHaveLength(0);
    });

    it('shows status icon when unspecified', () => {
      vm = mountComponentWithStore(ReportIssue, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.SecurityIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(vm.$el.querySelectorAll('.report-block-list-icon')).toHaveLength(1);
    });
  });
});
