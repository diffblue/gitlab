import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import EpicsListEmpty from 'ee/roadmap/components/epics_list_empty.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockSvgPath } from 'ee_jest/roadmap/mock_data';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_EPICS_PATH = '/epics';
const TEST_NEW_EPIC_PATH = '/epics/new';

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

describe('ee/roadmap/components/epics_list_empty.vue', () => {
  let wrapper;

  const createWrapper = ({
    isChildEpics = false,
    hasFiltersApplied = false,
    canCreateEpic = true,
    presetType = PRESET_TYPES.MONTHS,
    timeframeStart = mockTimeframeMonths[0],
    timeframeEnd = mockTimeframeMonths[mockTimeframeMonths.length - 1],
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(EpicsListEmpty, {
        propsData: {
          presetType,
          timeframeStart,
          timeframeEnd,
          emptyStateIllustrationPath: mockSvgPath,
          hasFiltersApplied,
          isChildEpics,
        },
        provide: {
          newEpicPath: TEST_NEW_EPIC_PATH,
          listEpicsPath: TEST_EPICS_PATH,
          epicsDocsPath: TEST_HOST,
          canCreateEpic,
        },
      }),
    );
  };

  const findComponent = () => wrapper.findComponent(GlEmptyState);
  const findTitle = () => findComponent().props('title');
  const findSubTitle = () => wrapper.findByTestId('sub-title');

  it('renders default message', () => {
    createWrapper({});

    expect(findTitle()).toBe('The roadmap shows the progress of your epics along a timeline');
  });

  it('renders empty state message when `hasFiltersApplied` prop is true', () => {
    createWrapper({ hasFiltersApplied: true });

    expect(findTitle()).toBe('Sorry, no epics matched your search');
  });

  describe('with presetType `QUARTERS`', () => {
    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.QUARTERS,
        timeframeStart: mockTimeframeQuarters[0],
        timeframeEnd: mockTimeframeQuarters[mockTimeframeQuarters.length - 1],
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Jul 1, 2016 to Sep 30, 2019.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.QUARTERS,
        timeframeStart: mockTimeframeQuarters[0],
        timeframeEnd: mockTimeframeQuarters[mockTimeframeQuarters.length - 1],
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Jul 1, 2016 to Sep 30, 2019.',
      );
    });
  });

  describe('with presetType `MONTHS`', () => {
    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.MONTHS,
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Jan 1 to Dec 31, 2018.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.MONTHS,
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Jan 1 to Dec 31, 2018.',
      );
    });
  });

  describe('with presetType `WEEKS`', () => {
    let timeframeEnd;

    beforeEach(() => {
      timeframeEnd = mockTimeframeWeeks[mockTimeframeWeeks.length - 1];
      timeframeEnd.setDate(timeframeEnd.getDate() + 6);
    });

    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.WEEKS,
        timeframeStart: mockTimeframeWeeks[0],
        timeframeEnd,
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Dec 31, 2017 to Apr 6, 2018.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.WEEKS,
        timeframeStart: mockTimeframeWeeks[0],
        timeframeEnd,
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Dec 31, 2017 to Apr 12, 2018.',
      );
    });
  });

  it('renders empty state sub-title when `isChildEpics` is set to `true`', () => {
    createWrapper({ isChildEpics: true });

    expect(findSubTitle().text()).toBe(
      'To view the roadmap, add a start or due date to one of the child epics.',
    );
  });

  it('renders empty state illustration in image element with provided `emptyStateIllustrationPath`', () => {
    createWrapper({});

    expect(findComponent().props('svgPath')).toBe(mockSvgPath);
  });

  it('renders buttons for create and list epics', () => {
    createWrapper({});

    expect(findComponent().props()).toMatchObject({
      primaryButtonLink: TEST_NEW_EPIC_PATH,
      secondaryButtonLink: TEST_EPICS_PATH,
    });
  });

  it('does not render new epic button element when `hasFiltersApplied` prop is true', () => {
    createWrapper({ hasFiltersApplied: true });

    expect(findComponent().props('primaryButtonLink')).toBe(null);
  });

  it('does not render new epic button element when `canCreateEpic` is false', () => {
    createWrapper({ canCreateEpic: false });

    expect(findComponent().props('primaryButtonLink')).toBe(null);
  });
});
