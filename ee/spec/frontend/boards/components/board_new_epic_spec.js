import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import GroupSelect from 'ee/boards/components/group_select.vue';
import epicBoardQuery from 'ee/boards/graphql/epic_board.query.graphql';
import { mockList } from 'jest/boards/mock_data';

import BoardNewItem from '~/boards/components/board_new_item.vue';
import eventHub from '~/boards/eventhub';

import { mockEpicBoardResponse } from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

const addListNewEpicSpy = jest.fn().mockResolvedValue();
const mockActions = { addListNewEpic: addListNewEpicSpy };

const epicBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardResponse);
const mockApollo = createMockApollo([[epicBoardQuery, epicBoardQueryHandlerSuccess]]);

const createComponent = ({ actions = mockActions, isApolloBoard = false } = {}) =>
  shallowMount(BoardNewEpic, {
    apolloProvider: mockApollo,
    store: new Vuex.Store({
      actions,
    }),
    propsData: {
      list: mockList,
      boardId: 'gid://gitlab/Board::EpicBoard/1',
    },
    provide: {
      boardType: 'group',
      fullPath: 'gitlab-org',
      isApolloBoard,
    },
    stubs: {
      BoardNewItem,
    },
  });

describe('Epic boards new epic form', () => {
  let wrapper;

  const findBoardNewItem = () => wrapper.findComponent(BoardNewItem);
  const submitForm = async (w) => {
    const boardNewItem = w.findComponent(BoardNewItem);

    boardNewItem.vm.$emit('form-submit', { title: 'Foo' });

    await nextTick();
  };

  beforeEach(async () => {
    wrapper = createComponent();

    await nextTick();
  });

  it('renders board-new-item component', () => {
    const boardNewItem = findBoardNewItem();
    expect(boardNewItem.exists()).toBe(true);
    expect(boardNewItem.props()).toEqual({
      list: mockList,
      formEventPrefix: 'toggle-epic-form-',
      submitButtonTitle: 'Create epic',
      disableSubmit: false,
    });
  });

  it('renders group-select dropdown within board-new-item', () => {
    const boardNewItem = findBoardNewItem();
    const groupSelect = boardNewItem.findComponent(GroupSelect);

    expect(groupSelect.exists()).toBe(true);
  });

  it('calls action `addListNewEpic` when "Create epic" button is clicked', async () => {
    await submitForm(wrapper);

    expect(addListNewEpicSpy).toHaveBeenCalledWith(expect.any(Object), {
      list: expect.any(Object),
      epicInput: {
        title: 'Foo',
        labelIds: [],
        groupPath: 'gitlab-org',
      },
    });
  });

  it('emits event `toggle-epic-form` with current list Id suffix on eventHub when `board-new-item` emits form-cancel event', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
    findBoardNewItem().vm.$emit('form-cancel');

    await nextTick();
    expect(eventHub.$emit).toHaveBeenCalledWith(`toggle-epic-form-${mockList.id}`);
  });

  describe('Apollo boards', () => {
    beforeEach(async () => {
      wrapper = createComponent({ isApolloBoard: true });

      await nextTick();
    });

    it('fetches board when creating epic and emits addNewEpic event', async () => {
      await submitForm(wrapper);
      await waitForPromises();

      expect(epicBoardQueryHandlerSuccess).toHaveBeenCalled();
      expect(wrapper.emitted('addNewEpic')[0][0]).toMatchObject({ title: 'Foo' });
    });
  });
});
