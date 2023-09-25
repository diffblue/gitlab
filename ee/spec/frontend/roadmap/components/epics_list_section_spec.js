import { GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';

import { nextTick } from 'vue';
import EpicItem from 'ee/roadmap/components/epic_item.vue';
import EpicsListSection from 'ee/roadmap/components/epics_list_section.vue';
import {
  DATE_RANGES,
  PRESET_TYPES,
  EPIC_DETAILS_CELL_WIDTH,
  TIMELINE_CELL_MIN_WIDTH,
} from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { scrollToCurrentDay } from 'ee/roadmap/utils/epic_utils';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import {
  mockFormattedChildEpic1,
  mockFormattedChildEpic2,
  mockTimeframeInitialDate,
  mockGroupId,
  rawEpics,
  mockEpicsWithParents,
  mockEpicsWithSkippedParents,
  mockSortedBy,
  mockPageInfo,
  basePath,
} from 'ee_jest/roadmap/mock_data';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import eventHub from 'ee/roadmap/event_hub';

jest.mock('ee/roadmap/utils/epic_utils');

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const store = createStore();
store.dispatch('setInitialData', {
  currentGroupId: mockGroupId,
  sortedBy: mockSortedBy,
  presetType: PRESET_TYPES.MONTHS,
  timeframe: mockTimeframeMonths,
  filterQueryString: '',
  basePath,
});

store.dispatch('receiveEpicsSuccess', {
  rawEpics,
  pageInfo: mockPageInfo,
  appendToList: true,
});

const mockEpics = store.state.epics;

store.state.childrenEpics[mockEpics[0].id] = [mockFormattedChildEpic1, mockFormattedChildEpic2];

describe('EpicsListSectionComponent', () => {
  let wrapper;

  const findBottomShadow = () => wrapper.findByTestId('epic-scroll-bottom-shadow');
  const findEmptyRowEl = () => wrapper.find('.epics-list-item-empty');
  const findAllEpicItems = () => wrapper.findAllComponents(EpicItem);

  const createComponent = ({
    epics = mockEpics,
    timeframe = mockTimeframeMonths,
    currentGroupId = mockGroupId,
    presetType = PRESET_TYPES.MONTHS,
    hasFiltersApplied = false,
  } = {}) => {
    wrapper = shallowMountExtended(EpicsListSection, {
      store,
      propsData: {
        presetType,
        epics,
        timeframe,
        currentGroupId,
        hasFiltersApplied,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('computed', () => {
    describe('emptyRowContainerVisible', () => {
      it('returns true when total epics are less than buffer size', () => {
        store.dispatch('setBufferSize', mockEpics.length + 1);

        expect(findEmptyRowEl().exists()).toBe(true);
      });
    });

    describe('sectionContainerStyles', () => {
      it('returns style string for container element based on sectionShellWidth', () => {
        expect(wrapper.attributes('style')).toBe(
          `width: ${
            EPIC_DETAILS_CELL_WIDTH + TIMELINE_CELL_MIN_WIDTH * mockTimeframeMonths.length
          }px;`,
        );
      });
    });

    describe('epicsWithAssociatedParents', () => {
      it('should return epics which contain parent associations', async () => {
        expect(findAllEpicItems()).toHaveLength(
          // Only top-level epics are visible by default, any child
          // epics are shown only when the parent is expanded.
          mockEpics.filter((epic) => !epic.hasParent).length,
        );

        wrapper.setProps({
          epics: mockEpicsWithParents,
        });

        await nextTick();

        expect(findAllEpicItems()).toHaveLength(mockEpicsWithParents.length);
      });

      it('should return epics which match the applied filter when one of the epic in hierarchy is not matching the filter', async () => {
        createComponent({ epics: mockEpicsWithSkippedParents });
        store.state.epicIds = mockEpicsWithSkippedParents.map((epic) => epic.id);

        await nextTick();

        expect(findAllEpicItems()).toHaveLength(mockEpicsWithSkippedParents.length);
      });
    });

    describe('displayedEpics', () => {
      beforeAll(() => {
        store.state.epicIds = ['1', '2', '3'];
      });

      it('returns all epics if epicIid is specified', () => {
        store.state.epicIid = '23';
        mockEpics.forEach((epic, index) => {
          expect(findAllEpicItems().at(index).props('epic')).toMatchObject(epic);
        });
      });
    });
  });

  describe('methods', () => {
    describe('initMounted', () => {
      beforeEach(() => {
        // Destroy the existing wrapper, and create a new one. This works
        // around a race condition between how Jest runs tests and the
        // $nextTick call in EpicsListSectionComponent's mounted hook.
        // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27992#note_319213990
        wrapper.destroy();
        store.state.epicIid = undefined;
        createComponent();
      });

      it('calls action `setBufferSize` with value based on window.innerHeight and component element position', () => {
        expect(store.state.bufferSize).toBe(16);
      });

      it('calls `scrollToCurrentDay` following the component render', () => {
        expect(scrollToCurrentDay).toHaveBeenCalledWith(wrapper.element);
      });

      it('sets style attribute containing `height` on empty row', () => {
        expect(findEmptyRowEl().attributes('style')).toBe('height: calc(100vh - 0px);');
      });
    });

    describe('getEmptyRowContainerStyles', () => {
      it('does not set style attribute on empty row when no epics are available to render', () => {
        createComponent({ epics: [] });

        expect(findEmptyRowEl().attributes('style')).not.toBeDefined();
      });

      it('sets style attribute with `height` on empty row when there epics available to render', () => {
        expect(findEmptyRowEl().attributes('style')).toBe('height: calc(100vh - 0px);');
      });
    });

    describe('handleEpicsListScroll', () => {
      it('toggles value of `showBottomShadow` based on provided `scrollTop`, `clientHeight` & `scrollHeight`', async () => {
        const bottomShadow = findBottomShadow();

        eventHub.$emit('epicsListScrolled', {
          scrollTop: 5,
          clientHeight: 5,
          scrollHeight: 15,
        });
        await nextTick();

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(bottomShadow.isVisible()).toBe(true);

        eventHub.$emit('epicsListScrolled', {
          scrollTop: 15,
          clientHeight: 5,
          scrollHeight: 15,
        });
        await nextTick();

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(bottomShadow.isVisible()).toBe(false);
      });
    });
  });

  describe('template', () => {
    const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);

    it('renders component container element with class `epics-list-section`', () => {
      expect(wrapper.classes('epics-list-section')).toBe(true);
    });

    it('renders epic-item', () => {
      expect(wrapper.findComponent(EpicItem).exists()).toBe(true);
    });

    it('renders empty row element when `epics.length` is less than `bufferSize`', () => {
      store.dispatch('setBufferSize', 50);

      expect(findEmptyRowEl().exists()).toBe(true);
    });

    it('renders gl-intersection-observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('calls action `fetchEpics` when gl-intersection-observer appears in viewport', () => {
      jest.spyOn(store, 'dispatch').mockImplementation();

      findIntersectionObserver().vm.$emit('appear');

      expect(store.dispatch).toHaveBeenCalledWith('fetchEpics', {
        endCursor: mockPageInfo.endCursor,
      });
    });

    it('renders gl-loading icon when epicsFetchForNextPageInProgress is true', async () => {
      store.state.epicsFetchForNextPageInProgress = true;
      await nextTick();

      expect(wrapper.findByTestId('next-page-loading').text()).toContain('Loading epics');
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders bottom shadow element when `showBottomShadow` prop is true', () => {
      eventHub.$emit('epicsListScrolled', {
        scrollTop: 5,
        clientHeight: 5,
        scrollHeight: 15,
      });

      expect(findBottomShadow().exists()).toBe(true);
    });
  });

  it('expands to show child epics when epic is toggled', () => {
    const epic = mockEpics[0];

    expect(store.state.childrenFlags[epic.id].itemExpanded).toBe(false);

    eventHub.$emit('toggleIsEpicExpanded', epic);

    expect(store.state.childrenFlags[epic.id].itemExpanded).toBe(true);
  });
});
