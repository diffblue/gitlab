import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'spec/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createComplianceFrameworksResponse } from 'ee_jest/compliance_dashboard/mock_data';
import UrlSync, { URL_SET_PARAMS_STRATEGY } from '~/vue_shared/components/url_sync.vue';

import ComplianceFrameworksReport from 'ee/compliance_dashboard/components/frameworks_report/report.vue';
import complianceFrameworksGroupProjects from 'ee/compliance_dashboard/graphql/compliance_frameworks_group_projects.query.graphql';
import { DEFAULT_PAGINATION_CURSORS, GRAPHQL_PAGE_SIZE } from 'ee/compliance_dashboard/constants';
import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import Pagination from 'ee/compliance_dashboard/components/frameworks_report/pagination.vue';

Vue.use(VueApollo);

describe('ComplianceFrameworksReport component', () => {
  let wrapper;
  const groupPath = 'group-path';
  const defaultQueryParams = `?tab=frameworks`;

  const sentryError = new Error('GraphQL networkError');
  const projectsResponse = createComplianceFrameworksResponse();
  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(projectsResponse);
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findProjectsTable = () => wrapper.findComponent(ProjectsTable);
  const findPagination = () => wrapper.findComponent(Pagination);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  function createMockApolloProvider(resolverMock) {
    return createMockApollo([[complianceFrameworksGroupProjects, resolverMock]]);
  }

  function createComponent(mountFn = shallowMount, props = {}, resolverMock = mockGraphQlLoading) {
    return extendedWrapper(
      mountFn(ComplianceFrameworksReport, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          groupPath,
          ...props,
        },
      }),
    );
  }

  describe('default behavior', () => {
    beforeEach(() => {
      setWindowLocation(TEST_HOST + defaultQueryParams);
      wrapper = createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('syncs the URL query with "set" strategy', () => {
      expect(findUrlSync().props('urlParamsUpdateStrategy')).toBe(URL_SET_PARAMS_STRATEGY);
    });
  });

  describe('when initializing', () => {
    beforeEach(() => {
      setWindowLocation(TEST_HOST + defaultQueryParams);
      wrapper = createComponent(mount, {}, mockGraphQlLoading);
    });

    it('renders the table loading icon', () => {
      expect(findProjectsTable().exists()).toBe(true);
      expect(findProjectsTable().props('isLoading')).toBe(true);
    });

    it('fetches the list of projects', () => {
      expect(mockGraphQlLoading).toHaveBeenCalledTimes(1);
      expect(mockGraphQlLoading).toHaveBeenCalledWith({
        groupPath,
        ...DEFAULT_PAGINATION_CURSORS,
      });
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
      setWindowLocation(TEST_HOST + defaultQueryParams);
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponent(shallowMount, {}, mockGraphQlError);
    });

    it('renders the error message', async () => {
      await waitForPromises();

      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe(
        'Unable to load the compliance framework report. Refresh the page and try again.',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('when there are projects', () => {
    beforeEach(async () => {
      setWindowLocation(TEST_HOST + defaultQueryParams);
      wrapper = createComponent(mount, {}, mockGraphQlSuccess);
      await waitForPromises();
    });

    it('does not show loading indicator', () => {
      expect(findProjectsTable().props('isLoading')).toBe(false);
    });

    it('passes results to the table', () => {
      const projectsTable = findProjectsTable();
      expect(projectsTable.props('projects')).toHaveLength(1);
      expect(projectsTable.props('projects')[0]).toMatchObject(
        expect.objectContaining({
          fullPath: 'gitlab-org/gitlab-shell',
          id: 'gid://gitlab/Project/0',
          name: 'Gitlab Shell',
          complianceFrameworks: [
            expect.objectContaining({
              color: '#3cb371',
              default: false,
              description: 'this is a framework',
              id: 'gid://gitlab/ComplianceManagement::Framework/1',
              name: 'some framework',
            }),
          ],
        }),
      );
    });

    describe('when there is more than one page of projects', () => {
      const pageInfo = {
        endCursor: 'abc',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'abc',
        __typename: 'PageInfo',
      };
      const multiplePagesResponse = createComplianceFrameworksResponse({
        pageInfo,
      });
      let mockResolver;

      beforeEach(() => {
        mockResolver = jest.fn().mockResolvedValue(multiplePagesResponse);

        wrapper = createComponent(mount, {}, mockResolver);
        return waitForPromises();
      });

      it('shows the pagination', () => {
        expect(findPagination().exists()).toBe(true);
        expect(findPagination().props()).toMatchObject(expect.objectContaining({ pageInfo }));
      });

      it('updates the page size when it is changed', async () => {
        findPagination().vm.$emit('page-size-change', 99);
        await waitForPromises();

        expect(findPagination().props('perPage')).toBe(99);
      });

      it('fetches more projects', async () => {
        findPagination().vm.$emit('page-size-change', 99);
        await waitForPromises();

        expect(mockResolver).toHaveBeenCalledTimes(2);
        expect(mockResolver).toHaveBeenNthCalledWith(2, {
          groupPath,
          ...DEFAULT_PAGINATION_CURSORS,
          first: 99,
        });
      });

      it.each`
        event     | after    | before   | first                | last
        ${'next'} | ${'foo'} | ${null}  | ${GRAPHQL_PAGE_SIZE} | ${undefined}
        ${'prev'} | ${null}  | ${'foo'} | ${undefined}         | ${GRAPHQL_PAGE_SIZE}
      `(
        'fetches the $event page when the pagination emits "$event"',
        async ({ event, after, before, first, last }) => {
          await findPagination().vm.$emit(event, after ?? before);
          await waitForPromises();

          expect(mockResolver).toHaveBeenCalledTimes(2);
          expect(mockResolver).toHaveBeenNthCalledWith(2, {
            groupPath,
            after,
            before,
            first,
            last,
          });
        },
      );
    });

    describe('when there is only one page of projects', () => {
      beforeEach(() => {
        const noPagesResponse = createComplianceFrameworksResponse({
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
          },
        });
        const mockResolver = jest.fn().mockResolvedValue(noPagesResponse);

        wrapper = createComponent(mount, {}, mockResolver);
        return waitForPromises();
      });

      it('does not show the pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });
  });

  describe('when there are no projects', () => {
    beforeEach(async () => {
      setWindowLocation(TEST_HOST + defaultQueryParams);
      const emptyProjectsResponse = createComplianceFrameworksResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(emptyProjectsResponse);
      wrapper = createComponent(mount, {}, mockResolver);
    });

    it('does not show the pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });
});
