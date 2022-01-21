import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { parsedIssues } from './mock_data';

jest.mock('~/flash');

Vue.use(Vuex);

describe('Codequality report app', () => {
  let wrapper;
  let store;

  const createComponent = (state = {}, issues = [], glFeatures = {}, mountFn = mount) => {
    store = new Vuex.Store({
      state: {
        pageInfo: {},
        isLoadingCodequality: false,
        ...state,
      },
      getters: {
        codequalityIssues: () => issues,
        codequalityIssueTotal: () => issues.length,
      },
    });

    wrapper = mountFn(CodequalityReportApp, {
      store,
      provide: {
        glFeatures,
      },
    });
  };

  const findStatus = () => wrapper.find('.js-code-text');
  const findSuccessIcon = () => wrapper.find('.js-ci-status-icon-success');
  const findWarningIcon = () => wrapper.find('.js-ci-status-icon-warning');
  const findPagination = () => wrapper.findComponent(PaginationLinks);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ isLoadingCodequality: true });
    });

    it('shows a loading state', () => {
      expect(findStatus().text()).toBe('Loading Code Quality report');
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      createComponent({ loadingCodequalityFailed: true });
    });

    it('shows a warning icon and error message', () => {
      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('Failed to load Code Quality report');
    });
  });

  describe('when there are codequality issues', () => {
    beforeEach(() => {
      createComponent({}, parsedIssues);
    });

    it('renders the codequality issues', () => {
      const expectedIssueTotal = parsedIssues.length;

      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toContain(`Found ${expectedIssueTotal} code quality issues`);
      expect(findStatus().text()).toContain(
        `This report contains all Code Quality issues in the source branch.`,
      );
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(expectedIssueTotal);
    });

    it('renders a link to the line where the issue was found', () => {
      const issueLink = wrapper.find('.report-block-list-issue a');

      expect(issueLink.text()).toBe('ee/spec/features/admin/geo/admin_geo_projects_spec.rb:152');
      expect(issueLink.attributes('href')).toBe(
        '/root/test-codequality/blob/feature-branch/ee/spec/features/admin/geo/admin_geo_projects_spec.rb#L152',
      );
    });

    it('renders the pagination component', () => {
      expect(findPagination().exists()).toBe(true);
    });
  });

  describe('when there are no codequality issues', () => {
    beforeEach(() => {
      createComponent({}, []);
    });

    it('shows a message that no codequality issues were found', () => {
      expect(findSuccessIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('No code quality issues found');
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(0);
    });
  });
});
