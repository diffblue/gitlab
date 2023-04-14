import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Draggable from 'vuedraggable';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuesLaneList from 'ee/boards/components/issues_lane_list.vue';
import { mockList } from 'jest/boards/mock_data';
import BoardCard from '~/boards/components/board_card.vue';
import { ListType } from '~/boards/constants';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { createStore } from '~/boards/stores';
import { mockIssues, mockGroupIssuesResponse } from '../mock_data';

Vue.use(VueApollo);

describe('IssuesLaneList', () => {
  let wrapper;
  let store;
  let mockApollo;

  const listIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupIssuesResponse);

  const createComponent = ({
    listType = ListType.backlog,
    listProps = {},
    collapsed = false,
    isUnassignedIssuesLane = false,
    isApolloBoard = false,
  } = {}) => {
    const listMock = {
      ...mockList,
      ...listProps,
      listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.user = {};
    }

    mockApollo = createMockApollo([[listsIssuesQuery, listIssuesQueryHandlerSuccess]]);

    wrapper = shallowMount(IssuesLaneList, {
      apolloProvider: mockApollo,
      store,
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        list: listMock,
        issues: mockIssues,
        canAdminList: true,
        isUnassignedIssuesLane,
        filterParams: {},
      },
      provide: {
        fullPath: 'gitlab-org',
        boardType: 'group',
        isApolloBoard,
      },
    });
  };

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

  describe('max issue count warning', () => {
    beforeEach(() => {
      const defaultStore = createStore();
      store = {
        ...defaultStore,
        state: {
          ...defaultStore.state,
        },
      };
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to red-100', () => {
        store.state.fullBoardIssuesCount = { [mockList.id]: 4 };
        createComponent({ listProps: { maxIssueCount: 3 } });
        const block = wrapper.find('.gl-bg-red-100');
        expect(block.exists()).toBe(true);
        expect(block.attributes('class')).toContain('gl-rounded-base');
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not set background to red-100', () => {
        store.state.fullBoardIssuesCount = { [mockList.id]: 2 };
        createComponent({ listProps: { maxIssueCount: 3 } });

        expect(wrapper.find('.gl-bg-red-100').exists()).toBe(false);
      });
    });
  });

  describe('Apollo boards', () => {
    it.each`
      isUnassignedIssuesLane | performsQuery
      ${true}                | ${true}
      ${false}               | ${false}
    `(
      'fetches issues $performsQuery when isUnassignedIssuesLane is $isUnassignedIssuesLane',
      async ({ isUnassignedIssuesLane, performsQuery }) => {
        createComponent({ isUnassignedIssuesLane, isApolloBoard: true });

        await waitForPromises();

        if (performsQuery) {
          expect(listIssuesQueryHandlerSuccess).toHaveBeenCalled();
        } else {
          expect(listIssuesQueryHandlerSuccess).not.toHaveBeenCalled();
        }
      },
    );
  });
});
