import { mount, shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';

import { __ } from '~/locale';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceReportsApp from 'ee/compliance_dashboard/components/reports_app.vue';
import ReportHeader from 'ee/compliance_dashboard/components/shared/report_header.vue';
import MergeCommitsExportButton from 'ee/compliance_dashboard/components/violations_report/shared/merge_commits_export_button.vue';
import { stubComponent } from 'helpers/stub_component';
import { ROUTE_FRAMEWORKS, ROUTE_VIOLATIONS, TABS } from 'ee/compliance_dashboard/constants';

describe('ComplianceReportsApp component', () => {
  let wrapper;
  const defaultProps = {
    groupPath: 'group-path',
    mergeCommitsCsvExportPath: '/csv',
  };

  const findHeader = () => wrapper.findComponent(ReportHeader);
  const findMergeCommitsExportButton = () => wrapper.findComponent(MergeCommitsExportButton);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findFrameworksTab = () => wrapper.findByTestId('frameworks-tab');
  const findViolationsTab = () => wrapper.findByTestId('violations-tab');

  const createComponent = (props = {}, mountFn = shallowMount) => {
    return extendedWrapper(
      mountFn(ComplianceReportsApp, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        mocks: {
          $route: {
            name: ROUTE_VIOLATIONS,
          },
        },
        stubs: {
          'router-view': stubComponent({}),
        },
      }),
    );
  };

  describe('violations report', () => {
    beforeEach(() => {
      wrapper = createComponent(defaultProps, mount);
      findTabs().vm.$emit('input', TABS.indexOf(ROUTE_VIOLATIONS));
    });

    it('renders the violations report tab', () => {
      expect(findViolationsTab().exists()).toBe(true);
    });

    it('passes the expected values to the header', () => {
      expect(findHeader().props()).toMatchObject({
        heading: __('Compliance report'),
        subheading: __('Compliance violations and compliance frameworks for the group.'),
        documentationPath: '/help/user/compliance/compliance_report/index.md',
      });
    });

    it('renders the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(true);
    });

    it('does not render the merge commit export button when there is no CSV path', () => {
      wrapper = createComponent({ mergeCommitsCsvExportPath: null }, mount);
      findTabs().vm.$emit('input', TABS.indexOf(ROUTE_VIOLATIONS));

      expect(findMergeCommitsExportButton().exists()).toBe(false);
    });
  });

  describe('frameworks report', () => {
    beforeEach(() => {
      wrapper = createComponent();
      findTabs().vm.$emit('input', TABS.indexOf(ROUTE_FRAMEWORKS));
    });

    it('renders the frameworks report tab', () => {
      expect(findFrameworksTab().exists()).toBe(true);
    });

    it('passes the expected values to the header', () => {
      expect(findHeader().props()).toMatchObject({
        heading: __('Compliance report'),
        subheading: __('Compliance violations and compliance frameworks for the group.'),
        documentationPath: '/help/user/compliance/compliance_report/index.md',
      });
    });

    it('does not render the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(false);
    });
  });
});
