import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createComplianceFrameworksResponse } from 'ee_jest/compliance_dashboard/mock_data';

import ComplianceFrameworksReport from 'ee/compliance_dashboard/components/frameworks_report/report.vue';
import complianceFrameworksGroupProjects from 'ee/compliance_dashboard/graphql/compliance_frameworks_group_projects.query.graphql';
import { ROUTE_FRAMEWORKS } from 'ee/compliance_dashboard/constants';
import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import Pagination from 'ee/compliance_dashboard/components/frameworks_report/pagination.vue';

Vue.use(VueApollo);

describe('ComplianceFrameworksReport component', () => {
  let wrapper;
  const groupPath = 'group-path';
  const newGroupComplianceFrameworkPath = 'new-framework-path';
  let $router;

  const sentryError = new Error('GraphQL networkError');
  const projectsResponse = createComplianceFrameworksResponse();
  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(projectsResponse);
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findProjectsTable = () => wrapper.findComponent(ProjectsTable);
  const findPagination = () => wrapper.findComponent(Pagination);

  function createMockApolloProvider(resolverMock) {
    return createMockApollo([[complianceFrameworksGroupProjects, resolverMock]]);
  }

  function createComponent(
    mountFn = shallowMount,
    props = {},
    resolverMock = mockGraphQlLoading,
    queryParams = {},
  ) {
    $router = {
      push: jest.fn(),
    };
    return extendedWrapper(
      mountFn(ComplianceFrameworksReport, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          groupPath,
          newGroupComplianceFrameworkPath,
          ...props,
        },
        mocks: {
          $router,
          $route: {
            name: ROUTE_FRAMEWORKS,
            query: queryParams,
          },
        },
      }),
    );
  }

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });
  });

  describe('when initializing', () => {
    beforeEach(() => {
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
        after: undefined,
        first: 20,
      });
    });

    it('passes the url query params when fetching projects', () => {
      wrapper = createComponent(mount, {}, mockGraphQlLoading, {
        perPage: 99,
        after: 'fgfgfg-after',
      });

      expect(mockGraphQlLoading).toHaveBeenCalledWith({
        groupPath,
        after: 'fgfgfg-after',
        first: 99,
      });
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
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

        expect($router.push).toHaveBeenCalledWith(
          expect.objectContaining({
            query: {
              perPage: 99,
            },
          }),
        );
      });

      it('resets to first page when page size is changed', async () => {
        findPagination().vm.$emit('page-size-change', 99);
        await waitForPromises();

        expect($router.push).toHaveBeenCalledWith(
          expect.objectContaining({
            query: expect.objectContaining({
              before: undefined,
              after: undefined,
            }),
          }),
        );
      });
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
      const emptyProjectsResponse = createComplianceFrameworksResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(emptyProjectsResponse);
      wrapper = createComponent(mount, {}, mockResolver);
    });

    it('does not show the pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });
});
