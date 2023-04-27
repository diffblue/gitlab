import { GlPagination, GlBadge } from '@gitlab/ui';
import { defaultDataIdFromObject } from '@apollo/client/core';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';

import { nextTick } from 'vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';
import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementsTabs from 'ee/requirements/components/requirements_tabs.vue';

import { filterState, STATE_FAILED } from 'ee/requirements/constants';
import createRequirement from 'ee/requirements/queries/create_requirement.mutation.graphql';
import exportRequirement from 'ee/requirements/queries/export_requirements.mutation.graphql';

import projectRequirements from 'ee/requirements/queries/project_requirements.query.graphql';
import projectRequirementsCount from 'ee/requirements/queries/project_requirements_count.query.graphql';
import updateRequirement from 'ee/requirements/queries/update_requirement.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
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
  mockUpdateRequirementToFailed,
  mockProjectRequirementPassed,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const $toast = {
  show: jest.fn(),
};

const localVue = createLocalVue();

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

const createComponent = ({ props = {}, loading = false } = {}) =>
  extendedWrapper(
    shallowMount(RequirementsRoot, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $apollo: {
          queries: {
            requirements: {
              loading,
              list: [],
              pageInfo: {},
              refetch: jest.fn(),
            },
            requirementsCount: {
              ...defaultProps.initialRequirementsCount,
              refetch: jest.fn(),
            },
          },
          mutate: jest.fn(),
        },
        $toast,
      },
    }),
  );

const createComponentWithApollo = ({ props = {}, requestHandlers = [] } = {}) => {
  localVue.use(VueApollo);

  const mockApollo = createMockApollo(
    [
      [projectRequirements, jest.fn().mockResolvedValue(mockProjectRequirements)],
      [projectRequirementsCount, jest.fn().mockResolvedValue(mockProjectRequirementCounts)],
      ...requestHandlers,
    ],
    {},
    {
      dataIdFromObject: (object) =>
        // eslint-disable-next-line no-underscore-dangle
        object.__typename === 'Requirement' ? object.iid : defaultDataIdFromObject(object),
    },
  );

  return extendedWrapper(
    shallowMount(RequirementsRoot, {
      localVue,
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        initialRequirementsCount: mockInitialRequirementCounts,
        ...props,
      },
      mocks: {
        $toast,
      },
      stubs: {
        RequirementItem,
        RequirementStatusBadge,
        GlBadge,
      },
    }),
  );
};

describe('RequirementsRoot', () => {
  let wrapper;
  let trackingSpy;

  const findRequirementEditForm = () => wrapper.findByTestId('edit-form');
  const findBadge = () => wrapper.findComponent(GlBadge);

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('computed', () => {
    describe('requirementsListEmpty', () => {
      it('returns `false` when `$apollo.queries.requirements.loading` is true', () => {
        const wrapperLoading = createComponent({ loading: true });

        expect(wrapperLoading.vm.requirementsListEmpty).toBe(false);

        wrapperLoading.destroy();
      });

      it('returns `true` when `requirements.list` is empty', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          requirements: {
            list: [],
          },
        });

        await nextTick();
        expect(wrapper.vm.requirementsListEmpty).toBe(true);
      });

      it('returns `true` when `requirementsCount` for current filterBy value is 0', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          filterBy: filterState.opened,
          requirementsCount: {
            OPENED: 0,
          },
        });

        await nextTick();
        expect(wrapper.vm.requirementsListEmpty).toBe(true);
      });
    });

    describe('totalRequirementsForCurrentTab', () => {
      it('returns number representing total requirements for current tab', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          filterBy: filterState.opened,
          requirementsCount: {
            OPENED: mockRequirementsCount.OPENED,
          },
        });

        await nextTick();
        expect(wrapper.vm.totalRequirementsForCurrentTab).toBe(mockRequirementsCount.OPENED);
      });
    });

    describe('showEmptyState', () => {
      it('returns `false` when `showRequirementCreateDrawer` is true', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          showRequirementCreateDrawer: true,
        });

        await nextTick();
        expect(wrapper.vm.showEmptyState).toBe(false);
      });
    });

    describe('showPaginationControls', () => {
      it('returns `true` when totalRequirements is more than default page size', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          requirementsCount: mockRequirementsCount,
        });

        await nextTick();
        expect(wrapper.vm.showPaginationControls).toBe(true);
      });

      it('returns `false` when totalRequirements is less than default page size', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          requirements: {
            list: [mockRequirementsOpen[0]],
            pageInfo: mockPageInfo,
          },
          requirementsCount: {
            ...mockRequirementsCount,
            OPENED: 1,
          },
        });

        await nextTick();
        expect(wrapper.vm.showPaginationControls).toBe(false);
      });

      it.each`
        hasPreviousPage | hasNextPage  | isVisible
        ${true}         | ${undefined} | ${true}
        ${undefined}    | ${true}      | ${true}
        ${false}        | ${undefined} | ${false}
        ${undefined}    | ${false}     | ${false}
        ${false}        | ${false}     | ${false}
        ${true}         | ${true}      | ${true}
      `(
        'returns $isVisible when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `requirements.pageInfo`',
        async ({ hasPreviousPage, hasNextPage, isVisible }) => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            requirements: {
              pageInfo: {
                hasPreviousPage,
                hasNextPage,
              },
            },
          });

          await nextTick();
          expect(wrapper.vm.showPaginationControls).toBe(isVisible);
        },
      );
    });

    describe('prevPage', () => {
      it('returns number representing previous page based on currentPage value', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentPage: 3,
        });

        await nextTick();
        expect(wrapper.vm.prevPage).toBe(2);
      });
    });

    describe('nextPage', () => {
      it('returns number representing next page based on currentPage value', () => {
        expect(wrapper.vm.nextPage).toBe(2);
      });

      it('returns `null` when currentPage is already last page', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentPage: 2,
        });

        await nextTick();
        expect(wrapper.vm.nextPage).toBeNull();
      });
    });
  });

  describe('methods', () => {
    const mockUpdateMutationResult = {
      data: {
        updateRequirement: {
          errors: [],
          requirement: {
            iid: '1',
            title: 'foo',
          },
        },
      },
    };

    const mockExportRequirementsMutationResult = {
      data: {
        exportRequirements: {
          errors: [],
        },
      },
    };

    describe('getFilteredSearchValue', () => {
      it('returns array containing applied filter search values', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          authorUsernames: ['root', 'john.doe'],
          status: 'satisfied',
          textSearch: 'foo',
        });

        await nextTick();
        expect(wrapper.vm.getFilteredSearchValue()).toEqual(mockFilters);
      });
    });

    describe('updateUrl', () => {
      it('updates window URL based on presence of props for filtered search and sort criteria', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          filterBy: filterState.all,
          currentPage: 2,
          nextPageCursor: mockPageInfo.endCursor,
          authorUsernames: ['root', 'john.doe'],
          textSearch: 'foo',
          sortBy: 'updated_asc',
        });

        await nextTick();
        wrapper.vm.updateUrl();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=2&next=${mockPageInfo.endCursor}&state=all&search=foo&sort=updated_asc&author_username%5B%5D=root&author_username%5B%5D=john.doe`,
        );
      });
    });

    describe('exportCsv', () => {
      it('calls `$apollo.mutate` with `exportRequirement` mutation and variables', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue(mockExportRequirementsMutationResult);

        wrapper.vm.exportCsv();

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: exportRequirement,
            variables: {
              projectPath: wrapper.vm.projectPath,
              state: wrapper.vm.filterBy,
              authorUsername: wrapper.vm.authorUsernames,
              search: wrapper.vm.textSearch,
              sortBy: wrapper.vm.sortBy,
            },
          }),
        );
      });

      it('calls `createAlert` when request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(new Error({}));

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
      it('calls `$apollo.mutate` with `updateRequirement` mutation and variables containing `projectPath` & `iid`', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `title` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                title: 'foo',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `description` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          description: '_foo_',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                description: '_foo_',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `state` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          state: filterState.opened,
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                state: filterState.opened,
              },
            },
          }),
        );
      });

      it('calls `createAlert` with provided `errorFlashMessage` param when request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(new Error({}));

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
      it('sets `showRequirementCreateDrawer` prop to `true`', () => {
        wrapper.vm.handleNewRequirementClick();

        expect(wrapper.vm.showRequirementCreateDrawer).toBe(true);
      });
    });

    describe('handleShowRequirementClick', () => {
      it('sets `showRequirementViewDrawer` prop to `true`', () => {
        wrapper.vm.handleShowRequirementClick(mockRequirementsOpen[0]);

        expect(wrapper.vm.showRequirementViewDrawer).toBe(true);
        expect(wrapper.vm.editedRequirement).toBe(mockRequirementsOpen[0]);
      });
    });

    describe('handleEditRequirementClick', () => {
      it('sets `showRequirementViewDrawer` prop to `true` and `editedRequirement` to value of passed param', () => {
        wrapper.vm.handleEditRequirementClick(mockRequirementsOpen[0]);

        expect(wrapper.vm.showRequirementViewDrawer).toBe(true);
        expect(wrapper.vm.editedRequirement).toBe(mockRequirementsOpen[0]);
      });
    });

    describe('handleNewRequirementSave', () => {
      const mockMutationResult = {
        data: {
          createRequirement: {
            errors: [],
            requirement: {
              iid: '1',
            },
          },
        },
      };

      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave({
          title: 'foo',
          description: '_bar_',
        });

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `$apollo.mutate` with createRequirement mutation and `projectPath` & `title` as variables', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave({
          title: 'foo',
          description: '_bar_',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: createRequirement,
            variables: {
              createRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                title: 'foo',
                description: '_bar_',
              },
            },
          }),
        );
      });

      it('sets `showRequirementCreateDrawer` and `createRequirementRequestActive` props to `false` and refetches requirements count and list when request is successful', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirementsCount, 'refetch')
          .mockImplementation(jest.fn());
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirements, 'refetch')
          .mockImplementation(jest.fn());

        return wrapper.vm
          .handleNewRequirementSave({
            title: 'foo',
            description: '_bar_',
          })
          .then(() => {
            expect(wrapper.vm.$apollo.queries.requirementsCount.refetch).toHaveBeenCalled();
            expect(wrapper.vm.$apollo.queries.requirements.refetch).toHaveBeenCalled();
            expect(wrapper.vm.showRequirementCreateDrawer).toBe(false);
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });

      it('calls `$toast.show` with string "Requirement added successfully" when request is successful', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockMutationResult);

        return wrapper.vm
          .handleNewRequirementSave({
            title: 'foo',
            description: '_bar_',
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Requirement REQ-1 has been added');
          });
      });

      it('sets `createRequirementRequestActive` prop to `false` and calls `createAlert` when `$apollo.mutate` request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));

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
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });
    });

    describe('handleUpdateRequirementSave', () => {
      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          title: 'foo',
        });

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `updateRequirement` with object containing `iid`, `title` & `errorFlashMessage` props', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            iid: '1',
            title: 'foo',
          }),
          expect.objectContaining({
            errorFlashMessage: 'Something went wrong while updating a requirement.',
          }),
        );
      });

      it('sets `showRequirementViewDrawer` to `true`, `editedRequirement` to `null` and `createRequirementRequestActive` prop to `false` when request is successful', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        return wrapper.vm
          .handleUpdateRequirementSave({
            iid: '1',
            title: 'foo',
          })
          .then(() => {
            expect(wrapper.vm.enableRequirementEdit).toBe(false);
            expect(wrapper.vm.editedRequirement).toEqual(
              mockUpdateMutationResult.data.updateRequirement.requirement,
            );
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });

      it('calls `$toast.show` with string "Requirement updated successfully" when request is successful', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        return wrapper.vm
          .handleUpdateRequirementSave({
            iid: '1',
            title: 'foo',
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been updated',
            );
          });
      });

      it('sets `createRequirementRequestActive` prop to `false` when request fails', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockRejectedValue(new Error());

        return wrapper.vm
          .handleUpdateRequirementSave({
            title: 'foo',
          })
          .catch(() => {
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });
    });

    describe('handleNewRequirementCancel', () => {
      it('sets `showRequirementCreateDrawer` prop to `false`', () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          showRequirementCreateDrawer: true,
        });

        wrapper.vm.handleNewRequirementCancel();

        expect(wrapper.vm.showRequirementCreateDrawer).toBe(false);
      });
    });

    describe('handleRequirementStateChange', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);
      });

      it('sets `stateChangeRequestActiveFor` value to `iid` provided within object param', () => {
        wrapper.vm.handleRequirementStateChange({
          iid: '1',
        });

        expect(wrapper.vm.stateChangeRequestActiveFor).toBe('1');
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "OPENED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: filterState.opened,
              }),
              expect.objectContaining({
                errorFlashMessage: 'Something went wrong while reopening a requirement.',
              }),
            );
          });
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "ARCHIVED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: filterState.archived,
              }),
              expect.objectContaining({
                errorFlashMessage: 'Something went wrong while archiving a requirement.',
              }),
            );
          });
      });

      it('sets `stateChangeRequestActiveFor` to 0', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.stateChangeRequestActiveFor).toBe(0);
          });
      });

      it('refetches requirementsCount query when request is successful', () => {
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirementsCount, 'refetch')
          .mockImplementation(jest.fn());

        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.$apollo.queries.requirementsCount.refetch).toHaveBeenCalled();
          });
      });

      it('calls `$toast.show` with string "Requirement has been reopened" when `params.state` is "OPENED" and request is successful', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been reopened',
            );
          });
      });

      it('calls `$toast.show` with string "Requirement has been archived" when `params.state` is "ARCHIVED" and request is successful', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: filterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been archived',
            );
          });
      });
    });

    describe('handleUpdateRequirementDrawerClose', () => {
      it('sets `enableRequirementEdit` & `showRequirementViewDrawer` to false and `editedRequirement` to `null`', () => {
        wrapper.vm.handleUpdateRequirementDrawerClose();

        expect(wrapper.vm.enableRequirementEdit).toBe(false);
        expect(wrapper.vm.showRequirementViewDrawer).toBe(false);
        expect(wrapper.vm.editedRequirement).toBe(null);
      });
    });

    describe('handleFilterRequirements', () => {
      it('updates props tied to requirements Graph query', () => {
        wrapper.vm.handleFilterRequirements(mockFilters);

        expect(wrapper.vm.authorUsernames).toEqual(['root', 'john.doe']);
        expect(wrapper.vm.status).toBe('satisfied');
        expect(wrapper.vm.textSearch).toBe('foo');
        expect(wrapper.vm.currentPage).toBe(1);
        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe('');
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
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          authorUsernames: ['root'],
          status: 'satisfied',
          textSearch: 'foo',
        });

        wrapper.vm.handleFilterRequirements([]);

        expect(wrapper.vm.authorUsernames).toEqual([]);
        expect(wrapper.vm.status).toBe('');
        expect(wrapper.vm.textSearch).toBe('');
        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });

    describe('handleSortRequirements', () => {
      it('updates props tied to requirements Graph query', () => {
        wrapper.vm.handleSortRequirements('updated_desc');

        expect(wrapper.vm.sortBy).toBe('updated_desc');
        expect(wrapper.vm.currentPage).toBe(1);
        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe('');
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&sort=updated_desc`,
        );
      });
    });

    describe('handlePageChange', () => {
      it('sets data prop `prevPageCursor` to empty string and `nextPageCursor` to `requirements.pageInfo.endCursor` when provided page param is greater than currentPage', () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          currentPage: 1,
          requirementsCount: mockRequirementsCount,
        });

        wrapper.vm.handlePageChange(2);

        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe(mockPageInfo.endCursor);
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

      it('sets data prop `nextPageCursor` to empty string and `prevPageCursor` to `requirements.pageInfo.startCursor` when provided page param is less than currentPage', () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          currentPage: 2,
          requirementsCount: mockRequirementsCount,
        });

        wrapper.vm.handlePageChange(1);

        expect(wrapper.vm.prevPageCursor).toBe(mockPageInfo.startCursor);
        expect(wrapper.vm.nextPageCursor).toBe('');
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
      expect(wrapper.findComponent(RequirementsTabs).exists()).toBe(true);
    });

    it('renders filtered-search-bar component', () => {
      expect(wrapper.findComponent(FilteredSearchBarRoot).exists()).toBe(true);
      expect(wrapper.findComponent(FilteredSearchBarRoot).props('searchInputPlaceholder')).toBe(
        'Search requirements',
      );
      expect(wrapper.findComponent(FilteredSearchBarRoot).props('tokens')).toEqual([
        mockAuthorToken,
        mockStatusToken,
      ]);
      expect(wrapper.findComponent(FilteredSearchBarRoot).props('recentSearchesStorageKey')).toBe(
        'requirements',
      );
    });

    it('renders empty state when query results are empty', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        requirements: {
          list: [],
        },
        requirementsCount: {
          OPENED: 0,
        },
      });

      await nextTick();
      expect(wrapper.findComponent(RequirementsEmptyState).exists()).toBe(true);
    });

    it('renders requirements-loading component when query results are still being loaded', () => {
      const wrapperLoading = createComponent({ loading: true });

      expect(wrapperLoading.findComponent(RequirementsLoading).isVisible()).toBe(true);

      wrapperLoading.destroy();
    });

    it('renders requirement-create-form component', () => {
      expect(wrapper.find('requirement-create-form-stub').exists()).toBe(true);
    });

    it('renders requirement-edit-form component', () => {
      expect(wrapper.find('requirement-edit-form-stub').exists()).toBe(true);
    });

    it('does not render requirement-empty-state component when `showRequirementCreateDrawer` prop is `true`', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        showRequirementCreateDrawer: true,
      });

      await nextTick();
      expect(wrapper.findComponent(RequirementsEmptyState).exists()).toBe(false);
    });

    it('renders requirement items for all the requirements', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          pageInfo: mockPageInfo,
        },
        requirementsCount: mockRequirementsCount,
      });

      await nextTick();
      const itemsContainer = wrapper.find('ul.requirements-list');

      expect(itemsContainer.exists()).toBe(true);
      expect(itemsContainer.findAllComponents(RequirementItem)).toHaveLength(
        mockRequirementsOpen.length,
      );
    });

    it('renders pagination controls', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          pageInfo: mockPageInfo,
        },
        requirementsCount: mockRequirementsCount,
      });

      await nextTick();
      const pagination = wrapper.findComponent(GlPagination);

      expect(pagination.exists()).toBe(true);
      expect(pagination.props('value')).toBe(1);
      expect(pagination.props('perPage')).toBe(2); // We're mocking this page size
      expect(pagination.props('align')).toBe('center');
    });
  });

  describe('with apollo mock', () => {
    describe('when requirement is edited', () => {
      let updateRequirementSpy;

      describe('when user changes the requirement\'s status to "FAILED" from "SUCCESS"', () => {
        const editRequirementToFailed = () => {
          findRequirementEditForm().vm.$emit('save', {
            description: mockProjectRequirementPassed.description,
            iid: mockProjectRequirementPassed.iid,
            title: mockProjectRequirementPassed.title,
            lastTestReportState: STATE_FAILED,
          });
        };

        beforeEach(() => {
          updateRequirementSpy = jest.fn().mockResolvedValue(mockUpdateRequirementToFailed);

          wrapper = createComponentWithApollo({
            requestHandlers: [[updateRequirement, updateRequirementSpy]],
          });
        });

        it('calls `updateRequirement` mutation with correct parameters', () => {
          editRequirementToFailed();

          expect(updateRequirementSpy).toHaveBeenCalledWith({
            updateRequirementInput: {
              projectPath: 'gitlab-org/gitlab-shell',
              iid: mockProjectRequirementPassed.iid,
              lastTestReportState: STATE_FAILED,
              title: mockProjectRequirementPassed.title,
            },
          });
        });

        it('renders a failed badge after the update', async () => {
          await nextTick();
          expect(findBadge().props('icon')).toBe('status-success');

          editRequirementToFailed();
          await waitForPromises();

          expect(findBadge().props('icon')).toBe('status-failed');
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
          updateRequirementSpy = jest.fn().mockResolvedValue(mockUpdateRequirementTitle);

          wrapper = createComponentWithApollo({
            requestHandlers: [[updateRequirement, updateRequirementSpy]],
          });
        });

        it('calls `updateRequirement` mutation with correct parameters without `lastTestReport`', () => {
          editRequirementTitle();

          expect(updateRequirementSpy).toHaveBeenCalledWith({
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
