import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Draggable from 'vuedraggable';
import IssuesLaneList from 'ee/boards/components/issues_lane_list.vue';
import { mockList } from 'jest/boards/mock_data';
import BoardCard from '~/boards/components/board_card.vue';
import { ListType } from '~/boards/constants';
import { createStore } from '~/boards/stores';
import { mockIssues } from '../mock_data';

describe('IssuesLaneList', () => {
  let wrapper;
  let store;

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    isUnassignedIssuesLane = false,
  } = {}) => {
    const listMock = {
      ...mockList,
      listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.user = {};
    }

    wrapper = shallowMount(IssuesLaneList, {
      store,
      propsData: {
        list: listMock,
        issues: mockIssues,
        canAdminList: true,
        isUnassignedIssuesLane,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('if list is expanded', () => {
    beforeEach(() => {
      store = createStore();

      createComponent();
    });

    it('does not have is-collapsed class', () => {
      expect(wrapper.classes('is-collapsed')).toBe(false);
    });

    it('renders one BoardCard component per issue passed in props', () => {
      expect(wrapper.findAllComponents(BoardCard)).toHaveLength(wrapper.props('issues').length);
    });
  });

  describe('if list is collapsed', () => {
    beforeEach(() => {
      store = createStore();

      createComponent({ collapsed: true });
    });

    it('has is-collapsed class', () => {
      expect(wrapper.classes('is-collapsed')).toBe(true);
    });

    it('does not renders BoardCard components', () => {
      expect(wrapper.findAllComponents(BoardCard)).toHaveLength(0);
    });
  });

  describe('drag & drop permissions', () => {
    beforeEach(() => {
      store = createStore();

      createComponent();
    });

    it('user cannot drag on epic lane if canAdminEpic is false', () => {
      expect(wrapper.vm.treeRootWrapper).toBe('ul');
    });

    it('user can drag on unassigned lane if canAdminEpic is false', () => {
      createComponent({ isUnassignedIssuesLane: true });

      expect(wrapper.vm.treeRootWrapper).toBe(Draggable);
    });
  });

  describe('drag & drop issue', () => {
    beforeEach(() => {
      const defaultStore = createStore();
      store = {
        ...defaultStore,
        state: {
          ...defaultStore.state,
          canAdminEpic: true,
        },
      };

      createComponent();
    });

    describe('handleDragOnStart', () => {
      it('adds a class `is-dragging` to document body', () => {
        expect(document.body.classList.contains('is-dragging')).toBe(false);

        wrapper.find(`[data-testid="tree-root-wrapper"]`).vm.$emit('start');

        expect(document.body.classList.contains('is-dragging')).toBe(true);
      });
    });

    describe('handleDragOnEnd', () => {
      it('removes class `is-dragging` from document body', () => {
        jest.spyOn(wrapper.vm, 'moveIssue').mockImplementation(() => {});
        document.body.classList.add('is-dragging');

        wrapper.find(`[data-testid="tree-root-wrapper"]`).vm.$emit('end', {
          oldIndex: 1,
          newIndex: 0,
          item: {
            dataset: {
              issueId: mockIssues[0].id,
              issueIid: mockIssues[0].iid,
              issuePath: mockIssues[0].referencePath,
            },
          },
          to: { children: [], dataset: { listId: 'gid://gitlab/List/1' } },
          from: { dataset: { listId: 'gid://gitlab/List/2' } },
        });

        expect(document.body.classList.contains('is-dragging')).toBe(false);
      });
    });

    describe('highlighting', () => {
      it('scrolls to column when highlighted', async () => {
        const defaultStore = createStore();
        store = {
          ...defaultStore,
          state: {
            ...defaultStore.state,
            highlightedLists: [mockList.id],
          },
        };

        createComponent();

        await nextTick();

        expect(wrapper.element.scrollIntoView).toHaveBeenCalled();
      });
    });
  });
});
