import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import { mockList } from 'jest/boards/mock_data';

import BoardNewItem from '~/boards/components/board_new_item.vue';
import eventHub from '~/boards/eventhub';

const localVue = createLocalVue();

localVue.use(Vuex);

const addListNewEpicSpy = jest.fn().mockResolvedValue();
const mockActions = { addListNewEpic: addListNewEpicSpy };

const createComponent = ({ actions = mockActions, getters = { isGroupBoard: () => true } } = {}) =>
  shallowMount(BoardNewEpic, {
    localVue,
    store: new Vuex.Store({
      actions,
      getters,
    }),
    propsData: {
      list: mockList,
    },
    provide: {
      boardId: 1,
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

    await wrapper.vm.$nextTick();
  };

  beforeEach(async () => {
    wrapper = createComponent();

    await wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
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

  it('calls action `addListNewEpic` when "Create epic" button is clicked', async () => {
    await submitForm(wrapper);

    expect(addListNewEpicSpy).toHaveBeenCalledWith(expect.any(Object), {
      list: expect.any(Object),
      epicInput: {
        title: 'Foo',
        boardId: 'gid://gitlab/Boards::EpicBoard/1',
        listId: 'gid://gitlab/List/1',
      },
    });
  });

  it('emits event `toggle-epic-form` with current list Id suffix on eventHub when `board-new-item` emits form-cancel event', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
    findBoardNewItem().vm.$emit('form-cancel');

    await wrapper.vm.$nextTick();
    expect(eventHub.$emit).toHaveBeenCalledWith(`toggle-epic-form-${mockList.id}`);
  });
});
