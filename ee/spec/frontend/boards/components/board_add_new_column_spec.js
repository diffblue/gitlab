import { GlAvatarLabeled, GlFormRadio, GlFormRadioGroup, GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardAddNewColumn, { listTypeInfo } from 'ee/boards/components/board_add_new_column.vue';
import projectBoardMilestonesQuery from '~/boards/graphql/project_board_milestones.query.graphql';
import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import createBoardListMutation from 'ee_else_ce/boards/graphql/board_list_create.mutation.graphql';
import boardLabelsQuery from '~/boards/graphql/board_labels.query.graphql';
import projectBoardMembersQuery from '~/boards/graphql/project_board_members.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { ListType } from '~/boards/constants';
import defaultState from '~/boards/stores/state';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { getIterationPeriod } from 'ee/iterations/utils';
import { mockLabelList, createBoardListResponse, labelsQueryResponse } from 'jest/boards/mock_data';
import {
  mockAssignees,
  mockIterations,
  assigneesQueryResponse,
  milestonesQueryResponse,
  iterationsQueryResponse,
} from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

describe('BoardAddNewColumn', () => {
  let wrapper;
  let mockApollo;

  const createBoardListQueryHandler = jest.fn().mockResolvedValue(createBoardListResponse);
  const labelsQueryHandler = jest.fn().mockResolvedValue(labelsQueryResponse);
  const milestonesQueryHandler = jest.fn().mockResolvedValue(milestonesQueryResponse);
  const assigneesQueryHandler = jest.fn().mockResolvedValue(assigneesQueryResponse);
  const iterationQueryHandler = jest.fn().mockResolvedValue(iterationsQueryResponse);
  const errorMessageMilestones = 'Failed to fetch milestones';
  const milestonesQueryHandlerFailure = jest
    .fn()
    .mockRejectedValue(new Error(errorMessageMilestones));
  const errorMessageAssignees = 'Failed to fetch assignees';
  const assigneesQueryHandlerFailure = jest
    .fn()
    .mockRejectedValue(new Error(errorMessageAssignees));
  const errorMessageIterations = 'Failed to fetch iterations';
  const iterationsQueryHandlerFailure = jest
    .fn()
    .mockRejectedValue(new Error(errorMessageIterations));

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const selectItem = (id) => {
    findDropdown().vm.$emit('select', id);
  };

  const createStore = ({ actions = {}, getters = {}, state = {} } = {}) => {
    return new Vuex.Store({
      state: {
        ...defaultState,
        ...state,
      },
      actions,
      getters,
    });
  };

  const mountComponent = ({
    selectedId,
    labels = [],
    assignees = [],
    iterations = [],
    getListByTypeId = jest.fn(),
    actions = {},
    provide = {},
    labelsHandler = labelsQueryHandler,
    milestonesHandler = milestonesQueryHandler,
    assigneesHandler = assigneesQueryHandler,
    iterationHandler = iterationQueryHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [boardLabelsQuery, labelsHandler],
      [projectBoardMembersQuery, assigneesHandler],
      [projectBoardMilestonesQuery, milestonesHandler],
      [searchIterationQuery, iterationHandler],
      [createBoardListMutation, createBoardListQueryHandler],
    ]);

    wrapper = shallowMountExtended(BoardAddNewColumn, {
      apolloProvider: mockApollo,
      propsData: {
        listQueryVariables: {},
        boardId: 'gid://gitlab/Board/1',
        lists: {},
      },
      stubs: {
        BoardAddNewColumnForm,
        GlFormRadio,
        GlFormRadioGroup,
        IterationTitle,
        GlCollapsibleListbox,
      },
      data() {
        return {
          selectedId,
        };
      },
      store: createStore({
        actions: {
          fetchLabels: jest.fn(),
          ...actions,
        },
        getters: {
          getListByTypeId: () => getListByTypeId,
        },
        state: {
          labels,
          labelsLoading: false,
          assignees,
          assigneesLoading: false,
          iterations,
          iterationsLoading: false,
        },
      }),
      provide: {
        scopedLabelsAvailable: true,
        milestoneListsAvailable: true,
        assigneeListsAvailable: true,
        iterationListsAvailable: true,
        isEpicBoard: false,
        issuableType: 'issue',
        fullPath: 'gitlab-org/gitlab',
        boardType: 'project',
        isApolloBoard: false,
        ...provide,
      },
    });

    // trigger change event
    if (selectedId) {
      selectItem(selectedId);
    }

    // Necessary for cache update
    mockApollo.clients.defaultClient.cache.writeQuery = jest.fn();
  };

  const findForm = () => wrapper.findComponent(BoardAddNewColumnForm);
  const cancelButton = () => wrapper.findByTestId('cancelAddNewColumn');
  const submitButton = () => wrapper.findByTestId('addNewColumnButton');
  const findIterationItemAt = (i) => wrapper.findAllByTestId('new-column-iteration-item').at(i);
  const listTypeSelect = (type) => {
    const radio = wrapper
      .findAllComponents(GlFormRadio)
      .filter((r) => r.attributes('value') === type)
      .at(0);
    radio.element.value = type;
    radio.vm.$emit('change', type);
  };
  const selectIteration = async () => {
    listTypeSelect(ListType.iteration);

    await nextTick();
  };

  const expectIterationWithTitle = () => {
    expect(findIterationItemAt(1).text()).toContain(getIterationPeriod(mockIterations[1]));
    expect(findIterationItemAt(1).text()).toContain(mockIterations[1].title);
  };

  const expectIterationWithoutTitle = () => {
    expect(findIterationItemAt(0).text()).toContain(getIterationPeriod(mockIterations[0]));
    expect(findIterationItemAt(0).findComponent(IterationTitle).exists()).toBe(false);
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  it('clicking cancel hides the form', () => {
    mountComponent();

    cancelButton().vm.$emit('click');

    expect(wrapper.emitted('setAddColumnFormVisibility')).toEqual([[false]]);
  });

  it('renders GlCollapsibleListbox with search field', () => {
    mountComponent();

    expect(findDropdown().exists()).toBe(true);
    expect(findDropdown().props('searchable')).toBe(true);
  });

  describe('Add list button', () => {
    it('is enabled if no item is selected', () => {
      mountComponent();

      expect(submitButton().props('disabled')).toBe(false);
    });

    it('adds a new list on click', async () => {
      const labelId = mockLabelList.label.id;
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedId: labelId,
        actions: {
          createList,
          highlightList,
        },
      });

      await nextTick();

      submitButton().vm.$emit('click');

      expect(highlightList).not.toHaveBeenCalled();
      expect(createList).toHaveBeenCalledWith(expect.anything(), { labelId });
    });

    it('highlights existing list if trying to re-add', async () => {
      const getListByTypeId = jest.fn().mockReturnValue(mockLabelList);
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        labels: [mockLabelList.label],
        selectedId: mockLabelList.label.id,
        getListByTypeId,
        actions: {
          createList,
          highlightList,
        },
      });

      await nextTick();

      submitButton().vm.$emit('click');

      expect(highlightList).toHaveBeenCalledWith(expect.anything(), mockLabelList.id);
      expect(createList).not.toHaveBeenCalled();
    });

    it('does not create on click and shows the dropdown as invalid when no ID is selected', async () => {
      const getListByTypeId = jest.fn().mockReturnValue(mockLabelList);
      const highlightList = jest.fn();
      const createList = jest.fn();

      mountComponent({
        selectedId: null,
        getListByTypeId,
        actions: {
          createList,
          highlightList,
        },
      });

      await nextTick();

      submitButton().vm.$emit('click');

      expect(createList).not.toHaveBeenCalled();
    });
  });

  describe('assignee list', () => {
    beforeEach(async () => {
      mountComponent({
        assignees: mockAssignees,
        actions: {
          fetchAssignees: jest.fn(),
        },
      });

      listTypeSelect(ListType.assignee);

      await nextTick();
    });

    it('sets assignee placeholder text in form', () => {
      expect(findForm().props('searchLabel')).toBe(BoardAddNewColumn.i18n.value);
      expect(findDropdown().props('searchPlaceholder')).toBe(
        listTypeInfo.assignee.searchPlaceholder,
      );
    });

    it('shows list of assignees', () => {
      const userList = wrapper.findAllComponents(GlAvatarLabeled);

      const [firstUser] = mockAssignees;

      expect(userList).toHaveLength(mockAssignees.length);
      expect(userList.at(0).props()).toMatchObject({
        label: firstUser.name,
        subLabel: `@${firstUser.username}`,
      });
    });
  });

  describe('iteration list', () => {
    const iterationMountOptions = {
      iterations: mockIterations,
      actions: {
        fetchIterations: jest.fn(),
      },
    };

    beforeEach(async () => {
      mountComponent({
        ...iterationMountOptions,
      });

      await selectIteration();
    });

    it('sets iteration placeholder text in form', () => {
      expect(findForm().props('searchLabel')).toBe(BoardAddNewColumn.i18n.value);
      expect(findDropdown().props('searchPlaceholder')).toBe(
        listTypeInfo.iteration.searchPlaceholder,
      );
    });

    it('shows list of iterations', () => {
      const itemList = findDropdown().props('items');

      expect(itemList).toHaveLength(mockIterations.length);
      expectIterationWithoutTitle();
      expectIterationWithTitle();
    });

    it('finds a cadence in the dropdown', () => {
      const { iterations } = iterationMountOptions;
      const getCadenceTitleFromMocks = (idx) => iterations[idx].iterationCadence.title;
      const cadenceTitles = wrapper
        .findAll('[data-testid="cadence"]')
        .wrappers.map((x) => x.text());

      expect(cadenceTitles).toEqual(cadenceTitles.map((_, idx) => getCadenceTitleFromMocks(idx)));
    });
  });

  describe('Apollo boards', () => {
    describe('assignee list', () => {
      beforeEach(async () => {
        mountComponent({ provide: { isApolloBoard: true } });
        listTypeSelect(ListType.assignee);

        await nextTick();
      });

      it('sets assignee placeholder text in form', () => {
        expect(findForm().props('searchLabel')).toBe(BoardAddNewColumn.i18n.value);
        expect(findDropdown().props('searchPlaceholder')).toBe(
          listTypeInfo.assignee.searchPlaceholder,
        );
      });

      it('shows list of assignees', () => {
        const userList = wrapper.findAllComponents(GlAvatarLabeled);

        const [firstUser] = mockAssignees;

        expect(userList).toHaveLength(mockAssignees.length);
        expect(userList.at(0).props()).toMatchObject({
          label: firstUser.name,
          subLabel: `@${firstUser.username}`,
        });
      });
    });

    describe('iteration list', () => {
      beforeEach(async () => {
        mountComponent({ provide: { isApolloBoard: true } });
        await selectIteration();
      });

      it('sets iteration placeholder text in form', () => {
        expect(findForm().props('searchLabel')).toBe(BoardAddNewColumn.i18n.value);
        expect(findDropdown().props('searchPlaceholder')).toBe(
          listTypeInfo.iteration.searchPlaceholder,
        );
      });

      it('shows list of iterations', () => {
        const itemList = findDropdown().props('items');

        expect(itemList).toHaveLength(mockIterations.length);
        expectIterationWithoutTitle();
        expectIterationWithTitle();
      });
    });

    describe('when fetch milestones query fails', () => {
      beforeEach(async () => {
        mountComponent({
          provide: { isApolloBoard: true },
          milestonesHandler: milestonesQueryHandlerFailure,
        });
        listTypeSelect(ListType.milestone);

        await nextTick();
      });

      it('sets error', async () => {
        findDropdown().vm.$emit('show');

        await waitForPromises();
        expect(cacheUpdates.setError).toHaveBeenCalled();
      });
    });

    describe('when fetch assignees query fails', () => {
      beforeEach(async () => {
        mountComponent({
          provide: { isApolloBoard: true },
          assigneesHandler: assigneesQueryHandlerFailure,
        });
        listTypeSelect(ListType.assignee);

        await nextTick();
      });

      it('sets error', async () => {
        findDropdown().vm.$emit('show');

        await waitForPromises();
        expect(cacheUpdates.setError).toHaveBeenCalled();
      });
    });

    describe('when fetch iterations query fails', () => {
      beforeEach(async () => {
        mountComponent({
          provide: { isApolloBoard: true },
          iterationHandler: iterationsQueryHandlerFailure,
        });
        await selectIteration();
      });

      it('sets error', async () => {
        findDropdown().vm.$emit('show');

        await waitForPromises();
        expect(cacheUpdates.setError).toHaveBeenCalled();
      });
    });
  });
});
