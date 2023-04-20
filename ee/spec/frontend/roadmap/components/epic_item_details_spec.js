import { nextTick } from 'vue';
import { GlButton, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { updateHistory } from '~/lib/utils/url_utility';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EpicItemDetails from 'ee/roadmap/components/epic_item_details.vue';
import eventHub from 'ee/roadmap/event_hub';
import createStore from 'ee/roadmap/store';
import {
  mockGroupId,
  mockFormattedEpic,
  mockFormattedChildEpic2,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

jest.mock('~/lib/utils/url_utility');

describe('EpicItemDetails', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
  });

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(EpicItemDetails, {
        store,
        propsData: {
          epic: mockFormattedEpic,
          currentGroupId: mockGroupId,
          timeframeString: 'Jul 10, 2017 – Jun 2, 2018',
          childLevel: 0,
          childrenFlags: { [mockFormattedEpic.id]: { itemExpanded: false } },
          hasFiltersApplied: false,
          isChildrenEmpty: false,
          ...props,
        },
      }),
    );
  };

  const getTitle = () => wrapper.findByTestId('epic-title');
  const getGroupName = () => wrapper.findByTestId('epic-group');
  const getEpicContainer = () => wrapper.findByTestId('epic-container');
  const getExpandIconButton = () => wrapper.findComponent(GlButton);
  const getExpandIconTooltip = () => wrapper.findByTestId('expand-icon-tooltip');
  const getChildEpicsCount = () => wrapper.findByTestId('child-epics-count');
  const getChildEpicsCountTooltip = () => wrapper.findByTestId('child-epics-count-tooltip');
  const getBlockedIcon = () => wrapper.findByTestId('blocked-icon');
  const getLabels = () => wrapper.findByTestId('epic-labels');

  const getExpandButtonData = () => ({
    icon: wrapper.findComponent(GlButton).attributes('icon'),
    iconLabel: getExpandIconButton().attributes('aria-label'),
    tooltip: getExpandIconTooltip().text(),
  });

  const getEpicTitleData = () => ({
    title: getTitle().text(),
    link: getTitle().attributes('href'),
  });

  const getEpicGroupNameData = () => ({
    groupName: getGroupName().text(),
    title: getGroupName().attributes('title'),
  });

  const createMockEpic = (epic) => ({
    ...mockFormattedEpic,
    ...epic,
  });

  describe('epic title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('is displayed with a link to the epic', () => {
      expect(getEpicTitleData()).toEqual({
        title: mockFormattedEpic.title,
        link: mockFormattedEpic.webUrl,
      });
    });
  });

  describe('epic group name', () => {
    describe('when the epic group ID is different from the current group ID', () => {
      it('is displayed and set to the title attribute', () => {
        createWrapper({ currentGroupId: 123 });
        expect(getEpicGroupNameData()).toEqual({
          groupName: mockFormattedEpic.group.name,
          title: mockFormattedEpic.group.fullName,
        });
      });
    });

    describe('when the epic group ID is the same as the current group ID', () => {
      it('is hidden', () => {
        createWrapper({ currentGroupId: mockGroupId });
        expect(getGroupName().exists()).toBe(false);
      });
    });
  });

  describe('timeframe', () => {
    it('is displayed', () => {
      createWrapper();
      const timeframe = wrapper.find('.epic-timeframe');

      expect(timeframe.text()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });

  describe('nested children styles', () => {
    const epic = createMockEpic({
      ...mockFormattedEpic,
      isChildEpic: true,
    });
    it('applies class for level 1 child', () => {
      createWrapper({ epic, childLevel: 1 });
      expect(getEpicContainer().classes('ml-3')).toBe(true);
    });

    it('applies class for level 2 child', () => {
      createWrapper({ epic, childLevel: 2 });
      expect(getEpicContainer().classes('ml-4')).toBe(true);
    });
  });

  describe('epic', () => {
    beforeEach(() => {
      store.state.allowSubEpics = true;
    });

    describe('expand icon', () => {
      it('is hidden when it is child epic', () => {
        const epic = createMockEpic({
          isChildEpic: true,
        });
        createWrapper({ epic });
        expect(getExpandIconButton().classes()).toContain('invisible');
      });

      describe('when epic has no child epics', () => {
        beforeEach(() => {
          const epic = createMockEpic({
            hasChildren: false,
            descendantCounts: {
              openedEpics: 0,
              closedEpics: 0,
            },
          });
          createWrapper({ epic });
        });
        it('is hidden', () => {
          expect(getExpandIconButton().classes()).toContain('invisible');
        });
        describe('child epics count', () => {
          it('shows the count as 0', () => {
            expect(getChildEpicsCount().text()).toBe('0');
          });
        });
      });

      describe('when epic has child epics', () => {
        let epic;
        beforeEach(() => {
          epic = createMockEpic({
            hasChildren: true,
            children: {
              edges: [mockFormattedChildEpic1],
            },
            descendantCounts: {
              openedEpics: 0,
              closedEpics: 1,
            },
          });
          createWrapper({ epic });
        });

        it('is shown', () => {
          expect(getExpandIconButton().classes()).not.toContain('invisible');
        });

        it('emits toggleIsEpicExpanded event when clicked', () => {
          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
          getExpandIconButton().vm.$emit('click');
          expect(eventHub.$emit).toHaveBeenCalledWith('toggleIsEpicExpanded', epic);
        });

        describe('when child epics are expanded', () => {
          const childrenFlags = {
            [mockFormattedEpic.id]: { itemExpanded: true },
          };

          beforeEach(() => {
            createWrapper({ epic, childrenFlags });
          });

          it('shows collapse button', () => {
            expect(getExpandButtonData()).toEqual({
              icon: 'chevron-down',
              iconLabel: 'Collapse',
              tooltip: 'Collapse',
            });
          });

          describe('when filters are applied', () => {
            beforeEach(() => {
              createWrapper({
                epic,
                childrenFlags,
                hasFiltersApplied: true,
                isChildrenEmpty: true,
              });
            });

            it('shows child epics match filters button', () => {
              expect(getExpandButtonData()).toEqual({
                icon: 'information-o',
                iconLabel: 'No child epics match applied filters',
                tooltip: 'No child epics match applied filters',
              });
            });
          });
        });

        describe('when child epics are not expanded', () => {
          beforeEach(() => {
            const childrenFlags = {
              [mockFormattedEpic.id]: { itemExpanded: false },
            };
            createWrapper({
              epic,
              childrenFlags,
            });
          });

          it('shows expand button', () => {
            expect(getExpandButtonData()).toEqual({
              icon: 'chevron-right',
              iconLabel: 'Expand',
              tooltip: 'Expand',
            });
          });
        });

        describe('child epics count', () => {
          it('has a tooltip with the count', () => {
            createWrapper({ epic });
            expect(getChildEpicsCountTooltip().text()).toBe('1 child epic');
          });

          it('has a tooltip with the count and explanation if search is being performed', () => {
            createWrapper({ epic, hasFiltersApplied: true });
            expect(getChildEpicsCountTooltip().text()).toBe(
              '1 child epic Some child epics may be hidden due to applied filters',
            );
          });

          it('does not render if the user license does not support child epics', () => {
            store.state.allowSubEpics = false;
            createWrapper({ epic });
            expect(getChildEpicsCount().exists()).toBe(false);
          });

          it('shows the correct count of child epics', () => {
            epic = createMockEpic({
              children: {
                edges: [mockFormattedChildEpic1, mockFormattedChildEpic2],
              },
              descendantCounts: {
                openedEpics: 0,
                closedEpics: 2,
              },
            });
            createWrapper({ epic });
            expect(getChildEpicsCount().text()).toBe('2');
          });
        });

        describe('blocked icon', () => {
          it.each`
            blocked  | showsBlocked
            ${true}  | ${true}
            ${false} | ${false}
          `(
            'if epic.blocked is $blocked then blocked is shown $showsBlocked',
            ({ blocked, showsBlocked }) => {
              epic = createMockEpic({
                blocked,
              });
              createWrapper({ epic });

              expect(getBlockedIcon().exists()).toBe(showsBlocked);
            },
          );
        });
      });
    });
  });

  describe('epic labels', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('do not display by default', () => {
      expect(getLabels().exists()).toBe(false);
    });

    it('display when isShowingLabels setting is set to true', async () => {
      expect(getLabels().exists()).toBe(false);

      store.dispatch('toggleLabels');

      await nextTick();

      expect(getLabels().exists()).toBe(true);
    });

    describe('click on label', () => {
      beforeEach(() => {
        store.dispatch('toggleLabels');
        jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());
      });

      describe('when selected label is not in the filter', () => {
        beforeEach(() => {
          // setWindowLocation('?');
          wrapper.findComponent(GlLabel).vm.$emit('click', {
            preventDefault: jest.fn(),
          });
        });

        it('calls updateHistory', () => {
          expect(updateHistory).toHaveBeenCalledTimes(1);
        });

        it('dispatches setFilterParams and fetchEpics vuex actions', () => {
          expect(store.dispatch.mock.calls[0]).toEqual(['setFilterParams', {}]);
          expect(store.dispatch.mock.calls[1]).toEqual(['fetchEpics']);
        });
      });

      describe('when selected label is already in the filter', () => {
        beforeEach(() => {
          // setWindowLocation('?label_name[]=Aquanix');
          store.state.filterParams = {
            labelName: ['Aquanix'],
          };
          createWrapper();

          wrapper.findComponent(GlLabel).vm.$emit('click', {
            preventDefault: jest.fn(),
          });
        });

        it('does not call updateHistory', () => {
          expect(updateHistory).not.toHaveBeenCalled();
        });

        it('does not dispatch setFilterParams or fetchEpics vuex action', () => {
          expect(store.dispatch).not.toHaveBeenCalled();
        });
      });
    });
  });
});
