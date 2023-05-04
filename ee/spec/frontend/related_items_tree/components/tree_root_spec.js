import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';

import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import { treeItemChevronBtnClassName } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import {
  mockQueryResponse,
  mockInitialConfig,
  mockParentItem,
  mockEpic1,
  mockIssue2,
} from '../mock_data';

const { epic } = mockQueryResponse.data.group;

Vue.use(Vuex);
let store;

const createComponent = ({
  parentItem = mockParentItem,
  epicPageInfo = epic.children.pageInfo,
  issuesPageInfo = epic.issues.pageInfo,
} = {}) => {
  store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });

  store.dispatch('setEpicPageInfo', {
    parentItem,
    pageInfo: epicPageInfo,
  });

  store.dispatch('setIssuePageInfo', {
    parentItem,
    pageInfo: issuesPageInfo,
  });

  return shallowMount(TreeRoot, {
    store,
    stubs: {
      'tree-item': true,
    },
    propsData: {
      parentItem,
      children,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeRoot', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('mixins', () => {
      describe('TreeDragAndDropMixin', () => {
        const containedDragClassOriginally = document.body.classList.contains('is-dragging');
        const containedNoDropClassOriginally = document.body.classList.contains('no-drop');

        beforeEach(() => {
          document.body.classList.remove('is-dragging');
          document.body.classList.remove('no-drop');
        });

        afterAll(() => {
          // Prevent side-effects of this test.
          document.body.classList.toggle('is-dragging', containedDragClassOriginally);
          document.body.classList.toggle('no-drop', containedNoDropClassOriginally);
        });

        describe('computed', () => {
          describe('treeRootWrapper', () => {
            it('should return Draggable reference when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootWrapper).toBe(Draggable);
            });

            it('should return string "ul" when userSignedIn prop is false', () => {
              store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootWrapper).toBe('ul');
            });
          });

          describe('treeRootOptions', () => {
            it('should return object containing Vue.Draggable config extended from `defaultSortableOptions` when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootOptions).toEqual(
                expect.objectContaining({
                  animation: 200,
                  forceFallback: true,
                  fallbackClass: 'is-dragging',
                  fallbackOnBody: false,
                  ghostClass: 'is-ghost',
                  group: 'sortable-container',
                  tag: 'ul',
                  'ghost-class': 'tree-item-drag-active',
                  'data-parent-reference': mockParentItem.reference,
                  'data-parent-id': mockParentItem.id,
                  value: wrapper.vm.children,
                  filter: `.${treeItemChevronBtnClassName}`,
                }),
              );
            });

            it('should return an empty object when userSignedIn prop is false', () => {
              store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootOptions).toEqual(expect.objectContaining({}));
            });
          });
        });

        describe('methods', () => {
          describe('getItemId', () => {
            it('returns value of `id` prop when item is an Epic', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[0])).toBe(mockEpic1.id);
            });

            it('returns value of `epicIssueId` prop when item is an Issue', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[2])).toBe(mockIssue2.epicIssueId);
            });
          });

          describe('getTreeReorderMutation', () => {
            it('returns an object containing ID of targetItem', () => {
              const targetItemEpic = wrapper.vm.children[0];
              const targetItemIssue = wrapper.vm.children[2];
              const newIndex = 0;

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemEpic,
                  newIndex,
                }),
              ).toEqual(
                expect.objectContaining({
                  id: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemIssue,
                  newIndex,
                }),
              ).toEqual(
                expect.objectContaining({
                  id: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns an object containing `adjacentReferenceId` of children item at provided `newIndex`', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                expect.objectContaining({
                  adjacentReferenceId: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                expect.objectContaining({
                  adjacentReferenceId: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param is 0', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `before` when `newIndex` param is last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: wrapper.vm.children.length - 1,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'before',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param neither `0` nor last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });
          });

          describe('handleDragOnStart', () => {
            it('adds a class `is-dragging` to document body', () => {
              expect(document.body.classList.contains('is-dragging')).toBe(false);

              wrapper.vm.handleDragOnStart();

              expect(document.body.classList.contains('is-dragging')).toBe(true);
            });

            it('attaches `keyup` event listener on document', async () => {
              jest.spyOn(document, 'addEventListener');
              wrapper.findComponent(Draggable).vm.$emit('start');
              await nextTick();

              expect(document.addEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
            });
          });

          describe('handleDragOnEnd', () => {
            it('removes class `is-dragging` from document body', async () => {
              document.body.classList.add('is-dragging');

              wrapper.findComponent(Draggable).vm.$emit('end', {});
              await nextTick();

              expect(document.body.classList.contains('is-dragging')).toBe(false);
            });

            it('detaches `keyup` event listener on document', async () => {
              jest.spyOn(document, 'removeEventListener');

              wrapper.findComponent(Draggable).vm.$emit('end', { oldIndex: 0, newIndex: 0 });
              await nextTick();

              expect(document.removeEventListener).toHaveBeenCalledWith(
                'keyup',
                expect.any(Function),
              );
            });

            describe('origin parent is destination parent', () => {
              it('does not call `reorderItem` action when newIndex is same as oldIndex', async () => {
                jest.spyOn(store, 'dispatch').mockImplementation(() => {});

                wrapper.findComponent(Draggable).vm.$emit('end', {
                  oldIndex: 0,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.element,
                });
                await nextTick();

                expect(store.dispatch).not.toHaveBeenCalled();
              });

              it('calls `reorderItem` action when newIndex is different from oldIndex', async () => {
                jest.spyOn(store, 'dispatch').mockImplementation(() => {});

                wrapper.findComponent(Draggable).vm.$emit('end', {
                  oldIndex: 1,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.element,
                });
                await nextTick();

                expect(store.dispatch).toHaveBeenCalledWith(
                  'reorderItem',
                  expect.objectContaining({
                    treeReorderMutation: expect.any(Object),
                    parentItem: mockParentItem,
                    targetItem: epicUtils.processQueryResponse(mockQueryResponse.data.group)[1],
                    oldIndex: 1,
                    newIndex: 0,
                  }),
                );
              });
            });

            describe('origin parent is different than destination parent', () => {
              it('calls `moveItem`', async () => {
                jest.spyOn(store, 'dispatch').mockImplementation(() => {});

                wrapper.findComponent(Draggable).vm.$emit('end', {
                  oldIndex: 1,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.find('li:first-child .sub-tree-root'),
                });
                await nextTick();

                expect(store.dispatch).toHaveBeenCalledWith(
                  'moveItem',
                  expect.objectContaining({
                    oldParentItem: wrapper.vm.parentItem,
                    newParentItem: wrapper.find('li:first-child .sub-tree-root').dataset,
                    targetItem: wrapper.vm.children[1],
                    oldIndex: 1,
                    newIndex: 0,
                  }),
                );
              });
            });
          });

          describe('handleKeyUp', () => {
            it('dispatches `mouseup` event when Escape key is pressed', () => {
              jest.spyOn(store, 'dispatch').mockImplementation(() => {});
              jest.spyOn(document, 'dispatchEvent');

              document.dispatchEvent(
                new Event('keyup', {
                  keyCode: ESC_KEY_CODE,
                }),
              );

              expect(document.dispatchEvent).toHaveBeenCalledWith(new Event('mouseup'));
              expect(store.dispatch).not.toHaveBeenCalled();
            });
          });
        });
      });
    });

    describe('computed', () => {
      describe('hasMoreChildren', () => {
        it('returns `true` when either `hasMoreEpics` or `hasMoreIssues` is true', () => {
          expect(wrapper.vm.hasMoreChildren).toBe(true);
        });

        it('returns `false` when both `hasMoreEpics` and `hasMoreIssues` is false', () => {
          const wrapperNoMoreChild = createComponent({
            epicPageInfo: {
              hasNextPage: false,
              endCursor: 'abc',
            },
            issuesPageInfo: {
              hasNextPage: false,
              endCursor: 'def',
            },
          });

          expect(wrapperNoMoreChild.vm.hasMoreChildren).toBe(false);

          wrapperNoMoreChild.destroy();
        });
      });
    });

    describe('methods', () => {
      describe('handleShowMoreClick', () => {
        it('sets `fetchInProgress` to true and calls `fetchNextPageItems` action with parentItem as param', () => {
          jest
            .spyOn(wrapper.vm, 'fetchNextPageItems')
            .mockImplementation(() => new Promise(() => {}));

          wrapper.vm.handleShowMoreClick();

          expect(wrapper.vm.fetchInProgress).toBe(true);
          expect(wrapper.vm.fetchNextPageItems).toHaveBeenCalledWith(
            expect.objectContaining({
              parentItem: mockParentItem,
            }),
          );
        });
      });

      describe('onMove', () => {
        let mockEvt;
        let mockOriginalEvt;

        beforeEach(() => {
          mockEvt = {
            relatedContext: {
              element: mockParentItem,
            },
          };
          mockOriginalEvt = {
            clientX: 10,
            clientY: 10,
            target: {
              getBoundingClientRect() {
                return {
                  top: 5,
                  left: 5,
                };
              },
            },
          };
        });

        it('calls toggleItem action after a delay if move event finds epic with children and mouse cursor is over it', () => {
          jest.spyOn(wrapper.vm, 'toggleItem').mockImplementation(() => {});
          wrapper.vm.onMove(mockEvt, mockOriginalEvt);

          jest.runAllTimers();

          expect(wrapper.vm.toggleItem).toHaveBeenCalled();
        });

        it('does not call toggleItem action if move event does not find epic with children', () => {
          jest.spyOn(wrapper.vm, 'toggleItem').mockImplementation(() => {});
          mockEvt = {
            relatedContext: {
              element: mockIssue2,
            },
          };
          mockOriginalEvt = {
            clientX: 10,
            clientY: 10,
          };

          wrapper.vm.onMove(mockEvt, mockOriginalEvt);

          expect(wrapper.vm.toggleItem).not.toHaveBeenCalled();
        });

        it('does not call toggleItem action if move event no longer have cursor over an epic with children', () => {
          jest.spyOn(wrapper.vm, 'toggleItem').mockImplementation(() => {});

          wrapper.vm.onMove(mockEvt, mockOriginalEvt);

          // Simulate cursor movement.
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            currentClientX: 10,
            currentClientY: 20,
          });

          jest.runAllTimers();

          expect(wrapper.vm.toggleItem).not.toHaveBeenCalled();
        });
      });
    });

    describe('template', () => {
      it('renders tree item component', () => {
        expect(wrapper.html()).toContain('tree-item-stub');
      });

      it('renders `Show more` link', () => {
        expect(wrapper.findComponent(GlButton).text()).toBe('Show more');
      });

      it('calls `handleShowMoreClick` when `Show more` link is clicked', () => {
        jest.spyOn(wrapper.vm, 'handleShowMoreClick').mockImplementation(() => {});

        wrapper.findComponent(GlButton).vm.$emit('click');

        expect(wrapper.vm.handleShowMoreClick).toHaveBeenCalled();
      });
    });
  });
});
