import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import GroupSelect from 'ee/boards/components/group_select.vue';
import { mockList } from 'jest/boards/mock_data';

import BoardNewItem from '~/boards/components/board_new_item.vue';
import eventHub from '~/boards/eventhub';

Vue.use(Vuex);

const addListNewEpicSpy = jest.fn().mockResolvedValue();
const mockActions = { addListNewEpic: addListNewEpicSpy };

const createComponent = ({ actions = mockActions } = {}) =>
  shallowMount(BoardNewEpic, {
    store: new Vuex.Store({
      actions,
    }),
    propsData: {
      list: mockList,
    },
    provide: {
      boardId: 1,
      fullPath: 'group/project',
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
        groupPath: 'group/project',
      },
    });
  });

  it('emits event `toggle-epic-form` with current list Id suffix on eventHub when `board-new-item` emits form-cancel event', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation();
    findBoardNewItem().vm.$emit('form-cancel');

    await nextTick();
    expect(eventHub.$emit).toHaveBeenCalledWith(`toggle-epic-form-${mockList.id}`);
  });
});
