import { GlPagination } from '@gitlab/ui';
import { defaultDataIdFromObject } from '@apollo/client/core';
import VueApollo from 'vue-apollo';

import Vue, { nextTick } from 'vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';
import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementForm from 'ee/requirements/components/requirement_form.vue';
import RequirementsTabs from 'ee/requirements/components/requirements_tabs.vue';

import { filterState, STATE_FAILED } from 'ee/requirements/constants';
import createRequirement from 'ee/requirements/queries/create_requirement.mutation.graphql';
import exportRequirement from 'ee/requirements/queries/export_requirements.mutation.graphql';

import projectRequirements from 'ee/requirements/queries/project_requirements.query.graphql';
import projectRequirementsCount from 'ee/requirements/queries/project_requirements_count.query.graphql';
import updateRequirement from 'ee/requirements/queries/update_requirement.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

import ExportRequirementsModal from 'ee/requirements/components/export_requirements_modal.vue';

import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { queryToObject } from '~/lib/utils/url_utility';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import {
  mockRequirementsOpen,
  mockRequirementsCount,
  mockPageInfo,
  mockFilters,
  mockAuthorToken,
  mockStatusToken,
  mockInitialRequirementCounts,
  mockProjectRequirementCounts,
  mockProjectRequirements,
  mockUpdateRequirementTitle,
  mockProjectRequirementPassed,
  mockExportRequirement,
  mockCreateRequirement,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const showToast = jest.fn();

const defaultProps = {
  projectPath: 'gitlab-org/gitlab-shell',
  initialFilterBy: filterState.opened,
  initialRequirementsCount: mockRequirementsCount,
  showCreateRequirement: false,
  emptyStatePath: '/assets/illustrations/empty-state/requirements.svg',
  canCreateRequirement: true,
  requirementsWebUrl: '/gitlab-org/gitlab-shell/-/requirements',
  importCsvPath: '/gitlab-org/gitlab-shell/-/requirements/import_csv',
  currentUserEmail: 'admin@example.com',
};

let wrapper;
let requestHandlers;

const buildHandlers = ({ nodes, opened = 1, archived = 0, pageInfo } = {}) => {
  let mockProjectRequirementsData = { ...mockProjectRequirements };
  if (nodes) {
    mockProjectRequirementsData = {
      ...mockProjectRequirements,
      ...{
        data: {
          project: {
            requirements: {
              nodes,
            },
          },
        },
      },
    };
  }

  if (pageInfo) {
    mockProjectRequirements.data.project.requirements.pageInfo = pageInfo;
  }

  mockProjectRequirementCounts.data.project.requirementStatesCount.opened = opened;
  mockProjectRequirementCounts.data.project.requirementStatesCount.archived = archived;

  return {
    projectRequirements: jest.fn().mockResolvedValue(mockProjectRequirementsData),
    projectRequirementsCount: jest.fn().mockResolvedValue(mockProjectRequirementCounts),
    createRequirement: jest.fn().mockResolvedValue(mockCreateRequirement),
    updateRequirement: jest.fn().mockResolvedValue(mockUpdateRequirementTitle),
    exportRequirement: jest.fn().mockResolvedValue(mockExportRequirement),
  };
};

const createMockApolloProvider = (handlers) => {
  Vue.use(VueApollo);

  requestHandlers = handlers;

  return createMockApollo(
    [
      [projectRequirements, handlers.projectRequirements],
      [projectRequirementsCount, handlers.projectRequirementsCount],
      [createRequirement, handlers.createRequirement],
      [updateRequirement, handlers.updateRequirement],
      [exportRequirement, handlers.exportRequirement],
    ],
    {},
    {
      dataIdFromObject: (object) =>
        // eslint-disable-next-line no-underscore-dangle
        object.__typename === 'Requirement' ? object.iid : defaultDataIdFromObject(object),
    },
  );
};

const createComponentWithApollo = ({ props = {}, handlers = buildHandlers() } = {}) => {
  wrapper = shallowMountExtended(RequirementsRoot, {
    apolloProvider: createMockApolloProvider(handlers),
    propsData: {
      ...defaultProps,
      initialRequirementsCount: mockInitialRequirementCounts,
      ...props,
    },
    mocks: {
      $toast: {
        show: showToast,
      },
    },
    stubs: {
      RequirementItem,
      RequirementStatusBadge,
    },
  });
};

describe('RequirementsRoot', () => {
  let trackingSpy;

  const findRequirementEditForm = () => wrapper.findByTestId('edit-form');
  const findRequirementsList = () => wrapper.findByTestId('requirements-list');
  const findExportRequirementsModal = () => wrapper.findComponent(ExportRequirementsModal);
  const findRequirementsTabs = () => wrapper.findComponent(RequirementsTabs);
  const findRequirementsEmptyState = () => wrapper.findComponent(RequirementsEmptyState);
  const findGlPagination = () => wrapper.findComponent(GlPagination);
  const findFilteredSearchBarRoot = () => wrapper.findComponent(FilteredSearchBarRoot);
  const findRequirementForm = () => wrapper.findComponent(RequirementForm);

  beforeEach(() => {
    createComponentWithApollo();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('computed', () => {
    describe('requirementsListEmpty', () => {
      it('does not show requirement list while loading', () => {
        createComponentWithApollo();
        expect(findRequirementsList().exists()).toBe(false);
      });

      it('does not show empty requirement list', async () => {
        createComponentWithApollo({ handlers: buildHandlers({ nodes: [] }) });
        await waitForPromises();

        expect(findRequirementsList().exists()).toBe(false);
      });

      it('does not show when filterBy value is 0', async () => {
        createComponentWithApollo({
          props: {
            initialFilterBy: filterState.opened,
          },
          handlers: buildHandlers({ nodes: [], opened: 0 }),
        });

        await waitForPromises();

        expect(findRequirementsList().exists()).toBe(false);
      });
    });

    describe('totalRequirementsForCurrentTab', () => {
      it('displays total requirements for current tab', async () => {
        createComponentWithApollo({
          props: {
            initialFilterBy: filterState.opened,
          },
          handlers: buildHandlers({ opened: mockRequirementsCount.OPENED }),
        });

        await waitForPromises();

        expect(findExportRequirementsModal().props('requirementCount')).toBe(
          mockRequirementsCount.OPENED,
        );
      });
    });

    describe('showEmptyState', () => {
      it('does not show empty state when create form is visible', () => {
        findRequirementsTabs().vm.$emit('click-new-requirement');
        expect(findRequirementsEmptyState().exists()).toBe(false);
      });
    });

    describe('Pagination', () => {
      it('renders pagination for multiple pages', async () => {
        createComponentWithApollo({
          handlers: buildHandlers({ pageInfo: mockPageInfo }),
        });

        await waitForPromises();
        expect(findGlPagination().exists()).toBe(true);
      });

      it('does not display pagination for one page', () => {
        createComponentWithApollo({
          handlers: buildHandlers({
            nodes: mockProjectRequirements.data.project.requirements.nodes[0],
            pageInfo: mockPageInfo,
            opened: 1,
            archived: mockRequirementsCount.ARCHIVED,
          }),
        });

        expect(findGlPagination().exists()).toBe(false);
      });

      it.each`
        hasPreviousPage | hasNextPage | isVisible
        ${true}         | ${false}    | ${true}
        ${false}        | ${true}     | ${true}
        ${false}        | ${false}    | ${false}
        ${false}        | ${false}    | ${false}
        ${false}        | ${false}    | ${false}
        ${true}         | ${true}     | ${true}
      `(
        'renders next previous pagination buttons on condition',
        async ({ hasPreviousPage, hasNextPage, isVisible }) => {
          createComponentWithApollo({
            handlers: buildHandlers({
              pageInfo: {
                ...mockPageInfo,
                hasPreviousPage,
                hasNextPage,
              },
            }),
          });

          await waitForPromises();

          expect(findGlPagination().exists()).toBe(isVisible);
        },
      );
    });

    describe('prevPage', () => {
      it('renders correct previous button', async () => {
        createComponentWithApollo({
          props: { page: 3 },
          handlers: buildHandlers({ pageInfo: mockPageInfo }),
        });

        await waitForPromises();
        expect(findGlPagination().props('prevPage')).toBe(2);
      });
    });

    describe('nextPage', () => {
      it('renders correct next button', async () => {
        createComponentWithApollo({
          props: { page: 1 },
          handlers: buildHandlers({
            opened: 20,
            pageInfo: {
              ...mockPageInfo,
              hasNextPage: true,
            },
          }),
        });

        await waitForPromises();

        expect(findGlPagination().props('nextPage')).toBe(2);
      });

      it('does not render next page if current page is last one', async () => {
        createComponentWithApollo({
          props: { page: 2 },
          handlers: buildHandlers({ pageInfo: mockPageInfo }),
        });

        await waitForPromises();

        expect(findGlPagination().props('nextPage')).toEqual(null);
      });
    });
  });

  describe('methods', () => {
    describe('FilteredSearchBar', () => {
      it('renders search bar based on parameters', () => {
        createComponentWithApollo({
          props: {
            initialAuthorUsernames: ['root', 'john.doe'],
            initialStatus: 'satisfied',
            initialTextSearch: 'foo',
          },
        });

        expect(findFilteredSearchBarRoot().props('initialFilterValue')).toEqual(mockFilters);
      });
    });

    describe('updateUrl', () => {
      it('updates window URL based on search criteria', () => {
        createComponentWithApollo({
          props: {
            initialFilterBy: filterState.all,
            page: 2,
            initialAuthorUsernames: ['root', 'john.doe'],
            initialTextSearch: 'foo',
            initialSortBy: 'updated_asc',
            next: mockPageInfo.endCursor,
          },
          handlers: buildHandlers({
            pageInfo: mockPageInfo,
          }),
        });

        findFilteredSearchBarRoot().vm.$emit('onSort', 'created_desc');

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=all&search=foo&sort=created_desc&author_username%5B%5D=root&author_username%5B%5D=john.doe`,
        );
      });
    });

    describe('exportCsv', () => {
      it('exports csv with graphql', () => {
        findExportRequirementsModal().vm.$emit('export');

        expect(requestHandlers.exportRequirement).toHaveBeenCalledWith({
          projectPath: 'gitlab-org/gitlab-shell',
          state: 'OPENED',
          authorUsername: [],
          search: '',
          sortBy: 'created_desc',
        });
      });

      it('shows alert on failed requests', () => {
        createComponentWithApollo({
          handlers: {
            ...buildHandlers(),
            exportRequirement: jest.fn().mockRejectedValue(new Error({})),
          },
        });

        return wrapper.vm.exportCsv().catch(() => {
          expect(createAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: 'Something went wrong while exporting requirements',
              captureError: true,
            }),
          );
        });
      });
    });

    describe('updateRequirement', () => {
      it('updateRequirement with graphql mutation and variables', () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
        });

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
          updateRequirementInput: {
            projectPath: 'gitlab-org/gitlab-shell',
            iid: '1',
          },
        });
      });

      it('updateRequirement with graphql mutation and variables when it is included in object param', () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          title: 'foo',
        });

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
          updateRequirementInput: {
            projectPath: 'gitlab-org/gitlab-shell',
            iid: '1',
            title: 'foo',
          },
        });
      });

      it('updateRequirement with graphql mutation and variables containing `description` when it is included in object param', () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          description: '_foo_',
        });

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
          updateRequirementInput: {
            projectPath: 'gitlab-org/gitlab-shell',
            iid: '1',
            description: '_foo_',
          },
        });
      });

      it('updateRequirement with graphql mutation and variables containing `state` when it is included in object param', () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          state: filterState.opened,
        });

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
          updateRequirementInput: {
            projectPath: 'gitlab-org/gitlab-shell',
            iid: '1',
            state: filterState.opened,
          },
        });
      });

      it('shows alert when request fails', () => {
        createComponentWithApollo({
          handlers: {
            ...buildHandlers(),
            updateRequirement: jest.fn().mockRejectedValue(new Error({})),
          },
        });

        return wrapper.vm
          .updateRequirement(
            {
              iid: '1',
            },
            {
              errorFlashMessage: 'Something went wrong',
            },
          )
          .catch(() => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'Something went wrong',
              captureError: true,
            });
          });
      });
    });

    describe('handleNewRequirementClick', () => {
      it('renders create drawer', async () => {
        await findRequirementsTabs().vm.$emit('click-new-requirement');

        expect(findRequirementsTabs().props('showCreateForm')).toBe(true);
      });
    });

    describe('handleShowRequirementClick', () => {
      it('renders create requirement drawer', async () => {
        await waitForPromises();

        await findRequirementsList()
          .findAllComponents(RequirementItem)
          .at(0)
          .vm.$emit('show-click', mockRequirementsOpen[0]);

        expect(findRequirementEditForm().props('drawerOpen')).toBe(true);
        expect(findRequirementEditForm().props('requirement')).toEqual(mockRequirementsOpen[0]);
      });
    });

    describe('handleNewRequirementSave', () => {
      it('sets `createRequirementRequestActive` prop to `true`', async () => {
        findRequirementForm().vm.$emit('save', { title: 'foo', description: '_bar_' });
        await nextTick();

        expect(findRequirementForm().props('requirementRequestActive')).toBe(true);
      });

      it('calls `$apollo.mutate` with createRequirement mutation and `projectPath` & `title` as variables', () => {
        findRequirementForm().vm.$emit('save', { title: 'foo', description: '_bar_' });

        expect(requestHandlers.createRequirement).toHaveBeenCalledWith({
          createRequirementInput: {
            projectPath: 'gitlab-org/gitlab-shell',
            title: 'foo',
            description: '_bar_',
          },
        });
      });

      it('sets `showRequirementCreateDrawer` and `createRequirementRequestActive` props to `false` and refetches requirements count and list when request is successful', async () => {
        findRequirementForm().vm.$emit('save', { title: 'foo', description: '_bar_' });
        await waitForPromises();

        expect(requestHandlers.projectRequirementsCount).toHaveBeenCalled();
        expect(requestHandlers.projectRequirements).toHaveBeenCalled();
        expect(findRequirementsTabs().props('showCreateForm')).toBe(false);
        expect(findRequirementForm().props('requirementRequestActive')).toBe(false);
      });

      it('calls `$toast.show` with string "Requirement added successfully" when request is successful', async () => {
        findRequirementForm().vm.$emit('save', { title: 'foo', description: '_bar_' });
        await waitForPromises();

        expect(showToast).toHaveBeenCalledWith('Requirement REQ-1 has been added');
      });

      it('sets `createRequirementRequestActive` prop to `false` and calls `createAlert` when `$apollo.mutate` request fails', () => {
        createComponentWithApollo({
          handlers: {
            ...buildHandlers(),
            createRequirement: jest.fn().mockRejectedValue(new Error()),
          },
        });

        return wrapper.vm
          .handleNewRequirementSave({
            title: 'foo',
            description: '_bar_',
          })
          .catch(() => {
            expect(createAlert).toHaveBeenCalledWith({
              message: 'Something went wrong while creating a requirement.',
              captureError: true,
              parent: expect.any(Object),
            });
            expect(findRequirementForm().props('requirementRequestActive')).toBe(false);
          });
      });
    });

    describe('RequirementEditForm', () => {
      it('renders RequirementEditForm', async () => {
        findRequirementEditForm().vm.$emit('save', { title: 'foo' });
        await nextTick();

        expect(findRequirementEditForm().props('requirementRequestActive')).toBe(true);
      });

      it('updates requirement` with object containing `iid`, `title`', async () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          title: 'foo',
        });
        await waitForPromises();

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            updateRequirementInput: {
              iid: '1',
              title: 'foo',
              projectPath: 'gitlab-org/gitlab-shell',
            },
          }),
        );
      });

      it('disables edit mode and active mode after update', async () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          title: 'foo',
        });
        await waitForPromises();

        expect(findRequirementEditForm().props('enableRequirementEdit')).toBe(false);
        expect(findRequirementEditForm().props('requirementRequestActive')).toBe(false);
      });

      it('calls `$toast.show` with string "Requirement updated successfully" when request is successful', async () => {
        findRequirementEditForm().vm.$emit('save', {
          iid: '1',
          title: 'foo',
        });
        await waitForPromises();

        expect(showToast).toHaveBeenCalledWith('Requirement REQ-1 has been updated');
      });

      it('disables active mode when request fails', () => {
        createComponentWithApollo({
          handlers: {
            ...buildHandlers(),
            updateRequirement: jest.fn().mockRejectedValue(new Error()),
          },
        });

        return wrapper.vm
          .handleUpdateRequirementSave({
            title: 'foo',
          })
          .catch(() => {
            expect(findRequirementEditForm().props('requirementRequestActive')).toBe(false);
          });
      });
    });

    describe('Cancel new requirement', () => {
      it('closes requirement drawer', async () => {
        findRequirementsTabs().vm.$emit('click-new-requirement');
        await nextTick();

        findRequirementForm().vm.$emit('drawer-close');
        await nextTick();

        expect(findRequirementForm().props('drawerOpen')).toBe(false);
      });
    });

    describe('RequirementStateChange', () => {
      it('changes active state value to `iid` provided within object param', async () => {
        await waitForPromises();

        findRequirementsList()
          .findAllComponents(RequirementItem)
          .at(0)
          .vm.$emit('archiveClick', { iid: '1' });
        await nextTick();

        expect(
          findRequirementsList()
            .findAllComponents(RequirementItem)
            .at(0)
            .props('stateChangeRequestActive'),
        ).toBe(true);
      });

      it('updates requirement with object containing params and errorFlashMessage when `params.state` is "OPENED"', async () => {
        await waitForPromises();

        findRequirementsList()
          .findAllComponents(RequirementItem)
          .at(0)
          .vm.$emit('archiveClick', { iid: '1', state: filterState.opened });
        await waitForPromises();

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            updateRequirementInput: {
              iid: '1',
              state: filterState.opened,
              projectPath: 'gitlab-org/gitlab-shell',
            },
          }),
        );
      });

      it('updates requirement with object containing params and errorFlashMessage when `params.state` is "ARCHIVED"', async () => {
        await waitForPromises();

        findRequirementsList().findAllComponents(RequirementItem).at(0).vm.$emit('archiveClick', {
          iid: '1',
          state: filterState.archived,
        });
        await waitForPromises();

        expect(requestHandlers.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            updateRequirementInput: {
              iid: '1',
              state: filterState.archived,
              projectPath: 'gitlab-org/gitlab-shell',
            },
          }),
        );
      });

      it('disables active state', async () => {
        await waitForPromises();

        findRequirementsList().findAllComponents(RequirementItem).at(0).vm.$emit('archiveClick', {
          iid: '1',
          state: filterState.opened,
        });
        await waitForPromises();

        expect(
          findRequirementsList()
            .findAllComponents(RequirementItem)
            .at(0)
            .props('stateChangeRequestActive'),
        ).toBe(false);
      });

      it('refetches requirementsCount query when request is successful', async () => {
        await waitForPromises();

        findRequirementsList().findAllComponents(RequirementItem).at(0).vm.$emit('archiveClick', {
          iid: '1',
          state: filterState.opened,
        });

        expect(requestHandlers.projectRequirementsCount).toHaveBeenCalled();
      });

      it('calls `$toast.show` with string "Requirement has been reopened" when `params.state` is "OPENED" and request is successful', async () => {
        await waitForPromises();

        findRequirementsList().findAllComponents(RequirementItem).at(0).vm.$emit('archiveClick', {
          iid: '1',
          state: filterState.opened,
        });
        await waitForPromises();

        expect(showToast).toHaveBeenCalledWith('Requirement REQ-1 has been reopened');
      });

      it('calls `$toast.show` with string "Requirement has been archived" when `params.state` is "ARCHIVED" and request is successful', async () => {
        await waitForPromises();

        findRequirementsList().findAllComponents(RequirementItem).at(0).vm.$emit('archiveClick', {
          iid: '1',
          state: filterState.archived,
        });
        await waitForPromises();

        expect(showToast).toHaveBeenCalledWith('Requirement REQ-1 has been archived');
      });
    });

    describe('UpdateRequirementDrawerClose', () => {
      it('closes drawer and disables active state', () => {
        findRequirementEditForm().vm.$emit('drawer-close');

        expect(findRequirementEditForm().props('enableRequirementEdit')).toBe(false);
        expect(findRequirementEditForm().props('drawerOpen')).toBe(false);
        expect(findRequirementEditForm().props('requirement')).toBe(null);
      });
    });

    describe('handleFilterRequirements', () => {
      it('updates props tied to requirements Graph query', async () => {
        createComponentWithApollo({
          handlers: buildHandlers({ pageInfo: mockPageInfo }),
        });
        await waitForPromises();

        findFilteredSearchBarRoot().vm.$emit('onFilter', mockFilters);
        await nextTick();

        const [author1, author2, status, search] = findFilteredSearchBarRoot().props(
          'initialFilterValue',
        );

        expect(author1).toEqual({ type: 'author', value: { data: 'root' } });
        expect(author2).toEqual({ type: 'author', value: { data: 'john.doe' } });
        expect(status).toEqual({ type: 'status', value: { data: 'satisfied' } });
        expect(search).toEqual({ type: 'filtered-search-term', value: { data: 'foo' } });

        expect(findGlPagination().props('value')).toBe(1);
        expect(findGlPagination().props('nextPage')).toEqual(null);
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&search=foo&sort=created_desc&author_username%5B%5D=root&author_username%5B%5D=john.doe&status=satisfied`,
        );
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter', {
          property: JSON.stringify([
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'root' } },
            { type: TOKEN_TYPE_AUTHOR, value: { data: 'john.doe' } },
            { type: TOKEN_TYPE_STATUS, value: { data: 'satisfied' } },
            { type: FILTERED_SEARCH_TERM, value: { data: 'foo' } },
          ]),
        });
      });

      it('updates props `textSearch` and `authorUsernames` with empty values when passed filters param is empty', () => {
        createComponentWithApollo({
          props: {
            initialAuthorUsernames: ['root', 'john.doe'],
            initialStatus: 'satisfied',
            initialTextSearch: 'foo',
          },
        });

        findFilteredSearchBarRoot().vm.$emit('onFilter', []);

        const [author1, author2, status, search] = findFilteredSearchBarRoot().props(
          'initialFilterValue',
        );

        expect(author1).toEqual({ type: 'author', value: { data: 'root' } });
        expect(author2).toEqual({ type: 'author', value: { data: 'john.doe' } });
        expect(status).toEqual({ type: 'status', value: { data: 'satisfied' } });
        expect(search).toEqual({ type: 'filtered-search-term', value: { data: 'foo' } });

        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });

    describe('handleSortRequirements', () => {
      it('updates props tied to requirements Graph query', async () => {
        createComponentWithApollo({
          handlers: buildHandlers({ pageInfo: mockPageInfo }),
        });
        await waitForPromises();

        findFilteredSearchBarRoot().vm.$emit('onSort', 'updated_desc');
        await nextTick();

        expect(findFilteredSearchBarRoot().props('initialSortBy')).toBe('updated_desc');
        expect(findGlPagination().props('value')).toBe(1);
        expect(findGlPagination().props('nextPage')).toEqual(null);
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&sort=updated_desc`,
        );
      });
    });

    describe('handlePageChange', () => {
      it('updates pagination based on selected next page', async () => {
        createComponentWithApollo({
          props: {
            page: 1,
          },
          handlers: buildHandlers({
            pageInfo: mockPageInfo,
          }),
        });

        await waitForPromises();

        findGlPagination().vm.$emit('input', 2);
        await nextTick();

        expect(queryToObject(window.location.search)).toEqual({
          page: '2',
          state: 'opened',
          sort: 'created_desc',
          next: mockPageInfo.endCursor,
        });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_navigation', {
          label: 'next',
        });
      });

      it('updates pagination based on selected page', async () => {
        createComponentWithApollo({
          props: {
            page: 1,
          },
          handlers: buildHandlers({
            pageInfo: mockPageInfo,
          }),
        });

        await waitForPromises();

        findGlPagination().vm.$emit('input', 1);
        await nextTick();

        expect(queryToObject(window.location.search)).toEqual({
          page: '1',
          state: 'opened',
          sort: 'created_desc',
          prev: mockPageInfo.startCursor,
        });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_navigation', {
          label: 'prev',
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `requirements-list-container`', () => {
      expect(wrapper.classes()).toContain('requirements-list-container');
    });

    it('renders requirements-tabs component', () => {
      expect(findRequirementsTabs().exists()).toBe(true);
    });

    it('renders filtered-search-bar component', () => {
      expect(findFilteredSearchBarRoot().exists()).toBe(true);
      expect(findFilteredSearchBarRoot().props('searchInputPlaceholder')).toBe(
        'Search requirements',
      );
      expect(findFilteredSearchBarRoot().props('tokens')).toEqual([
        mockAuthorToken,
        mockStatusToken,
      ]);
      expect(findFilteredSearchBarRoot().props('recentSearchesStorageKey')).toBe('requirements');
    });

    it('renders empty state when query results are empty', async () => {
      createComponentWithApollo({
        handlers: buildHandlers({ nodes: [], opened: 0 }),
      });
      await waitForPromises();

      expect(findRequirementsEmptyState().exists()).toBe(true);
    });

    it('renders requirements-loading component when query results are still being loaded', () => {
      expect(wrapper.findComponent(RequirementsLoading).isVisible()).toBe(true);
    });

    it('renders requirement-create-form component', () => {
      expect(wrapper.find('requirement-create-form-stub').exists()).toBe(true);
    });

    it('renders requirement-edit-form component', () => {
      expect(wrapper.find('requirement-edit-form-stub').exists()).toBe(true);
    });

    it('does not render requirement-empty-state component when `showRequirementCreateDrawer` prop is `true`', async () => {
      createComponentWithApollo({
        handlers: buildHandlers({ nodes: [] }),
      });
      await waitForPromises();

      findRequirementsTabs().vm.$emit('click-new-requirement');

      await nextTick();
      expect(findRequirementsEmptyState().exists()).toBe(false);
    });

    it('renders requirement items for all the requirements', async () => {
      createComponentWithApollo({
        handlers: buildHandlers({ pageInfo: mockPageInfo }),
      });
      await waitForPromises();
      expect(findRequirementsList().exists()).toBe(true);
      expect(findRequirementsList().findAllComponents(RequirementItem)).toHaveLength(1);
    });

    it('renders pagination controls', async () => {
      createComponentWithApollo({
        handlers: buildHandlers({ pageInfo: mockPageInfo }),
      });
      await waitForPromises();

      const pagination = findGlPagination();

      expect(pagination.exists()).toBe(true);
      expect(pagination.props('value')).toBe(1);
      expect(pagination.props('perPage')).toBe(2);
      expect(pagination.props('align')).toBe('center');
    });
  });

  describe('with apollo mock', () => {
    describe('when requirement is edited', () => {
      describe('when user changes the requirement\'s status to "FAILED" from "SUCCESS"', () => {
        const editRequirementToFailed = () => {
          findRequirementEditForm().vm.$emit('save', {
            description: mockProjectRequirementPassed.description,
            iid: mockProjectRequirementPassed.iid,
            title: mockProjectRequirementPassed.title,
            lastTestReportState: STATE_FAILED,
          });
        };

        it('calls `updateRequirement` mutation with correct parameters', () => {
          editRequirementToFailed();

          expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
            updateRequirementInput: {
              projectPath: 'gitlab-org/gitlab-shell',
              iid: mockProjectRequirementPassed.iid,
              lastTestReportState: STATE_FAILED,
              title: mockProjectRequirementPassed.title,
            },
          });
        });
      });

      describe('when user changes the title of a requirement', () => {
        const editRequirementTitle = () => {
          findRequirementEditForm().vm.$emit('save', {
            description: mockProjectRequirementPassed.description,
            iid: mockProjectRequirementPassed.iid,
            title: 'edited title',
            lastTestReportState: null,
          });
        };

        beforeEach(() => {
          createComponentWithApollo();
        });

        it('calls `updateRequirement` mutation with correct parameters without `lastTestReport`', () => {
          editRequirementTitle();

          expect(requestHandlers.updateRequirement).toHaveBeenCalledWith({
            updateRequirementInput: {
              projectPath: 'gitlab-org/gitlab-shell',
              iid: mockProjectRequirementPassed.iid,
              title: 'edited title',
            },
          });
        });

        it('renders the edited title', async () => {
          editRequirementTitle();
          await waitForPromises();

          expect(wrapper.find('.issue-title-text').text()).toContain('edited title');
        });
      });
    });
  });
});
