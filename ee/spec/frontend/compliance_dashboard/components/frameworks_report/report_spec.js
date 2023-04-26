import * as Sentry from '@sentry/browser';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createComplianceFrameworksResponse } from 'ee_jest/compliance_dashboard/mock_data';

import ComplianceFrameworksReport from 'ee/compliance_dashboard/components/frameworks_report/report.vue';
import complianceFrameworksGroupProjects from 'ee/compliance_dashboard/graphql/compliance_frameworks_group_projects.query.graphql';
import complianceFrameworksProjectFragment from 'ee/compliance_dashboard/graphql/compliance_frameworks_project.fragment.graphql';

import { ROUTE_FRAMEWORKS } from 'ee/compliance_dashboard/constants';
import ProjectsTable from 'ee/compliance_dashboard/components/frameworks_report/projects_table.vue';
import Pagination from 'ee/compliance_dashboard/components/frameworks_report/pagination.vue';
import Filters from 'ee/compliance_dashboard/components/frameworks_report/filters.vue';

Vue.use(VueApollo);

describe('ComplianceFrameworksReport component', () => {
  let wrapper;
  let apolloProvider;
  const groupPath = 'group-path';
  const rootAncestorPath = 'root-ancestor-path';
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
  const findFilters = () => wrapper.findComponent(Filters);

  function createMockApolloProvider(resolverMock) {
    return createMockApollo([[complianceFrameworksGroupProjects, resolverMock]]);
  }

  function createComponent(
    mountFn = shallowMount,
    props = {},
    resolverMock = mockGraphQlLoading,
    queryParams = {},
  ) {
    const currentQueryParams = { ...queryParams };
    $router = {
      push: jest.fn().mockImplementation(({ query }) => {
        Object.assign(currentQueryParams, query);
      }),
    };

    apolloProvider = createMockApolloProvider(resolverMock);

    wrapper = extendedWrapper(
      mountFn(ComplianceFrameworksReport, {
        apolloProvider,
        propsData: {
          groupPath,
          rootAncestorPath,
          newGroupComplianceFrameworkPath,
          ...props,
        },
        mocks: {
          $router,
          $route: {
            name: ROUTE_FRAMEWORKS,
            query: currentQueryParams,
          },
        },
      }),
    );
  }

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });
  });

  describe('when initializing', () => {
    beforeEach(() => {
      createComponent(mount, {}, mockGraphQlLoading);
    });

    it('renders the filters', () => {
      expect(findFilters().exists()).toBe(true);
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
      createComponent(mount, {}, mockGraphQlLoading, {
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
      createComponent(shallowMount, {}, mockGraphQlError);
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
      createComponent(mount, {}, mockGraphQlSuccess);
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

        createComponent(mount, {}, mockResolver);
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

        createComponent(mount, {}, mockResolver);
        return waitForPromises();
      });

      it('does not show the pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });
  });

  describe('when there are no projects', () => {
    beforeEach(() => {
      const emptyProjectsResponse = createComplianceFrameworksResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(emptyProjectsResponse);
      createComponent(mount, {}, mockResolver);
    });

    it('does not show the pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when the filter is updated', () => {
    beforeEach(async () => {
      createComponent(mount, {}, mockGraphQlSuccess);
      await waitForPromises();
    });

    it('should update route query', async () => {
      findFilters().vm.$emit('submit', [
        {
          type: 'framework',
          value: {
            data: 'gid://gitlab/ComplianceManagement::Framework/1',
            operator: '=',
          },
        },
      ]);
      await waitForPromises();

      expect($router.push).toHaveBeenCalledTimes(1);
      expect($router.push).toHaveBeenCalledWith({
        query: {
          project: undefined,
          framework: 'gid://gitlab/ComplianceManagement::Framework/1',
          frameworkExclude: undefined,
          before: undefined,
          after: undefined,
        },
      });
    });

    it('should still reload list when updated to the same value', async () => {
      const FILTERS = [
        {
          type: 'framework',
          value: {
            data: 'gid://gitlab/ComplianceManagement::Framework/1',
            operator: '=',
          },
        },
      ];

      findFilters().vm.$emit('submit', FILTERS);
      findFilters().vm.$emit('submit', FILTERS);
      await waitForPromises();

      expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
    });
  });

  it('should not open update popover on filters on update from projects table when filters are not provided', async () => {
    createComponent(shallowMount, {}, mockGraphQlSuccess, {});

    findProjectsTable().vm.$emit('updated');

    await nextTick();
    expect(findFilters().props('showUpdatePopover')).toBe(false);
  });

  it('should open update popover on filters on update from projects table when filters are provided', async () => {
    createComponent(shallowMount, {}, mockGraphQlSuccess, {
      framework: 'some-framework',
    });

    findProjectsTable().vm.$emit('updated');

    await nextTick();
    expect(findFilters().props('showUpdatePopover')).toBe(true);
  });

  it('does not refresh the list when underlying project is updated', async () => {
    createComponent(shallowMount, {}, mockGraphQlSuccess);
    await waitForPromises();

    expect(mockGraphQlSuccess).toHaveBeenCalledTimes(1);

    // We've intentionally directly modifying cache because our component
    // should not care for the source of the change
    const { defaultClient: apolloClient } = apolloProvider;
    const projectToModify = projectsResponse.data.group.projects.nodes[0];
    const projectToModifyId = apolloClient.cache.identify(projectToModify);
    apolloClient.writeFragment({
      id: projectToModifyId,
      fragment: complianceFrameworksProjectFragment,
      data: {
        ...projectToModify,
        name: `NEW_NAME`,
      },
    });

    expect(mockGraphQlSuccess).toHaveBeenCalledTimes(1);
  });
});
