import { GlAvatarLabeled, GlDropdown, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardAddNewColumn, { listTypeInfo } from 'ee/boards/components/board_add_new_column.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { ListType } from '~/boards/constants';
import defaultState from '~/boards/stores/state';
import { getIterationPeriod } from 'ee/iterations/utils';
import { mockAssignees, mockLists, mockIterations } from '../mock_data';

const mockLabelList = mockLists[1];

Vue.use(Vuex);

describe('BoardAddNewColumn', () => {
  let wrapper;

  const selectItem = (id) => {
    wrapper.findByTestId('selectItem').vm.$emit('change', id);
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
    glFeatures = {},
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardAddNewColumn, {
        stubs: {
          BoardAddNewColumnForm,
          GlFormRadio,
          GlFormRadioGroup,
          IterationTitle,
        },
        data() {
          return {
            selectedId,
          };
        },
        store: createStore({
          actions: {
            fetchLabels: jest.fn(),
            setAddColumnFormVisibility: jest.fn(),
            ...actions,
          },
          getters: {
            getListByTypeId: () => getListByTypeId,
            isEpicBoard: () => false,
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
          glFeatures,
        },
      }),
    );

    // trigger change event
    if (selectedId) {
      selectItem(selectedId);
    }
  };

  afterEach(() => {
    wrapper.destroy();
  });

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

  it('clicking cancel hides the form', () => {
    const setAddColumnFormVisibility = jest.fn();
    mountComponent({
      actions: {
        setAddColumnFormVisibility,
      },
    });

    cancelButton().vm.$emit('click');

    expect(setAddColumnFormVisibility).toHaveBeenCalledWith(expect.anything(), false);
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

    it('sets assignee placeholder text in form', async () => {
      expect(findForm().props()).toMatchObject({
        noneSelected: listTypeInfo.assignee.noneSelected,
        searchLabel: BoardAddNewColumn.i18n.value,
        searchPlaceholder: listTypeInfo.assignee.searchPlaceholder,
      });
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
      expect(findForm().props()).toMatchObject({
        searchLabel: BoardAddNewColumn.i18n.value,
        searchPlaceholder: listTypeInfo.iteration.searchPlaceholder,
      });
    });

    it('shows list of iterations', () => {
      const itemList = wrapper.findComponent(GlDropdown).findAllComponents(GlFormRadio);

      expect(itemList).toHaveLength(mockIterations.length);
      expectIterationWithoutTitle();
      expectIterationWithTitle();
    });
  });

  describe('iteration_cadences feature flag is on', () => {
    const iterationMountOptions = {
      iterations: mockIterations,
      actions: {
        fetchIterations: jest.fn(),
      },
    };

    beforeEach(async () => {
      mountComponent({
        ...iterationMountOptions,
        glFeatures: {
          iterationCadences: true,
        },
      });

      await selectIteration();
    });

    it('finds a cadence in the dropdown', () => {
      const { iterations } = iterationMountOptions;
      const getCadenceTitleFromMocks = (idx) => iterations[idx].iterationCadence.title;
      const cadenceTitles = wrapper
        .findAll('[data-testid="cadence"]')
        .wrappers.map((x) => x.text());

      expect(cadenceTitles).toEqual(cadenceTitles.map((_, idx) => getCadenceTitleFromMocks(idx)));
    });

    it('displays iteration period optionally with title', async () => {
      expectIterationWithoutTitle();
      expectIterationWithTitle();
    });
  });
});
