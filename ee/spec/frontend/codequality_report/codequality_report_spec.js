import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { parsedIssues } from './mock_data';

jest.mock('~/flash');

Vue.use(Vuex);
const ENDPOINT = '/testendpoint';
const BLOBPATH = '/blobPath';
const PROJECTPATH = '/projectPath';
const PIPELINEIID = '0';

describe('Codequality report app', () => {
  let wrapper;
  let store;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  const createComponent = () => {
    store = new Vuex.Store();

    wrapper = mount(CodequalityReportApp, {
      store,
      propsData: {
        endpoint: ENDPOINT,
        blobPath: BLOBPATH,
        projectPath: PROJECTPATH,
        pipelineIid: PIPELINEIID,
      },
    });
  };

  const findStatus = () => wrapper.find('.js-code-text');
  const findSuccessIcon = () => wrapper.find('svg[aria-label~="Success"]');
  const findWarningIcon = () => wrapper.find('svg[aria-label~="Warning"]');
  const findPagination = () => wrapper.findComponent(PaginationLinks);

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading state', () => {
      expect(findStatus().text()).toBe('Loading Code Quality report');
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    });

    it('shows a warning icon and error message', async () => {
      await waitForPromises();
      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('Failed to load Code Quality report');
    });
  });

  describe('when there are codequality issues', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(ENDPOINT).reply(200, parsedIssues);
    });

    it('renders the codequality issues', async () => {
      await waitForPromises();
      const expectedIssueTotal = parsedIssues.length;

      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toContain(`Found ${expectedIssueTotal} code quality issues`);
      expect(findStatus().text()).toContain(
        `This report contains all Code Quality issues in the source branch.`,
      );
      expect(wrapper.emitted().updateBadgeCount).toBeDefined();
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(expectedIssueTotal);
    });

    it('renders a link to the line where the issue was found', async () => {
      await waitForPromises();
      const issueLink = wrapper.find('.report-block-list-issue a');

      expect(issueLink.text()).toBe('ee/spec/features/admin/geo/admin_geo_projects_spec.rb:152');
      expect(issueLink.attributes('href')).toBe(
        `${BLOBPATH}/ee/spec/features/admin/geo/admin_geo_projects_spec.rb#L152`,
      );
    });

    it('renders the pagination component', () => {
      expect(findPagination().exists()).toBe(true);
    });
  });

  describe('when there are no codequality issues', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(ENDPOINT).reply(200, []);
    });

    it('shows a message that no codequality issues were found', async () => {
      await waitForPromises();
      expect(findSuccessIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('No code quality issues found');
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(0);
    });
  });
});
