import { GlButton, GlCard, GlIcon, GlCollapse } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import OnCallSchedule, { i18n } from 'ee/oncall_schedules/components/oncall_schedule.vue';
import RotationsListSection from 'ee/oncall_schedules/components/schedule/components/rotations_list_section.vue';
import ScheduleTimelineSection from 'ee/oncall_schedules/components/schedule/components/schedule_timeline_section.vue';
import * as utils from 'ee/oncall_schedules/components/schedule/utils';
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';
import getShiftsForRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules_with_rotations_shifts.query.graphql';
import * as commonUtils from 'ee/oncall_schedules/utils/common_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as dateTimeUtility from '~/lib/utils/datetime/date_calculation_utility';
import { getOncallSchedulesQueryResponse } from './mocks/apollo_mock';
import mockTimezones from './mocks/mock_timezones.json';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('On-call schedule', () => {
  let wrapper;
  let fakeApollo;

  const lastTz = mockTimezones[mockTimezones.length - 1];
  const mockSchedule = {
    description: 'monitor description',
    iid: '3',
    name: 'monitor schedule',
    timezone: lastTz.identifier,
    rotations: {
      nodes: [],
    },
  };

  const projectPath = 'group/project';
  const mockWeeksTimeFrame = [
    new Date('31 Dec 2020'),
    new Date('7 Jan 2021'),
    new Date('14 Jan 2021'),
  ];
  const formattedTimezone = '(UTC-09:00) AKST Alaska';

  const createComponent = ({
    schedule = mockSchedule,
    scheduleIndex = 0,
    getShiftsForRotationsQueryHandler = jest
      .fn()
      .mockResolvedValue(getOncallSchedulesQueryResponse),
    props = {},
    provide = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [getShiftsForRotationsQuery, getShiftsForRotationsQueryHandler],
    ]);

    wrapper = shallowMountExtended(OnCallSchedule, {
      localVue,
      apolloProvider: fakeApollo,
      propsData: {
        schedule,
        scheduleIndex,
        ...props,
      },
      data() {
        return {
          rotations: schedule.rotations.nodes,
        };
      },
      provide: {
        timezones: mockTimezones,
        projectPath,
        ...provide,
      },
      stubs: {
        GlCard,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(utils, 'getTimeframeForWeeksView').mockReturnValue(mockWeeksTimeFrame);
    jest.spyOn(commonUtils, 'getFormattedTimezone').mockReturnValue(formattedTimezone);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  const findScheduleHeader = () => wrapper.findByTestId('scheduleHeader');
  const findRotationsHeader = () => wrapper.findByTestId('rotationsHeader');
  const findSchedule = () => wrapper.findByTestId('scheduleBody');
  const findScheduleDescription = () => findSchedule().text();
  const findRotations = () => wrapper.findByTestId('rotationsBody');
  const findRotationsShiftPreset = () => wrapper.findByTestId('shift-preset-change');
  const findAddRotationsBtn = () => findRotationsHeader().find(GlButton);
  const findScheduleTimeline = () => findRotations().find(ScheduleTimelineSection);
  const findRotationsList = () => findRotations().find(RotationsListSection);
  const findLoadPreviousTimeframeBtn = () => wrapper.findByTestId('previous-timeframe-btn');
  const findLoadNextTimeframeBtn = () => wrapper.findByTestId('next-timeframe-btn');
  const findCollapsible = () => wrapper.findComponent(GlCollapse);
  const findGlCard = () => wrapper.findComponent(GlCard);
  const findCollapsibleIcon = () => wrapper.findComponent(GlIcon);

  it('shows schedule title', () => {
    expect(findScheduleHeader().text()).toBe(mockSchedule.name);
  });

  describe('Timeframe schedule card header information', () => {
    const timezone = lastTz.identifier;
    const offset = `(UTC ${lastTz.formatted_offset})`;

    it('shows timezone info', () => {
      expect(findScheduleDescription()).toContain(timezone);
      expect(findScheduleDescription()).toContain(offset);
    });

    it('shows schedule description if present', () => {
      expect(findScheduleDescription()).toContain(mockSchedule.description);
    });

    it('does not show schedule description if none present', () => {
      createComponent({
        schedule: { ...mockSchedule, description: null },
        loading: false,
        scheduleIndex: 0,
      });
      expect(findScheduleDescription()).not.toContain(mockSchedule.description);
    });
  });

  it('renders rotations header', () => {
    expect(findRotationsHeader().text()).toContain(i18n.rotationTitle);
    expect(findAddRotationsBtn().text()).toContain(i18n.addARotation);
  });

  it('renders schedule timeline', () => {
    const timeline = findScheduleTimeline();
    expect(timeline.exists()).toBe(true);
    expect(timeline.props()).toEqual({
      presetType: PRESET_TYPES.WEEKS,
      timeframe: mockWeeksTimeFrame,
    });
  });

  it('renders rotations list', () => {
    const rotationsList = findRotationsList();
    expect(rotationsList.exists()).toBe(true);
    expect(rotationsList.props()).toEqual({
      presetType: PRESET_TYPES.WEEKS,
      timeframe: mockWeeksTimeFrame,
      rotations: expect.any(Array),
      scheduleIid: mockSchedule.iid,
      loading: wrapper.vm.$apollo.queries.rotations.loading,
    });
  });

  it('renders a open card for the first in the list by default', () => {
    expect(findCollapsible().attributes('visible')).toBe('true');
    expect(findCollapsibleIcon().props('name')).toBe('angle-down');
  });

  it('renders a collapsed card if not the first in the list by default', () => {
    createComponent({ scheduleIndex: 1 });
    expect(findCollapsible().attributes('visible')).toBeUndefined();
    expect(findCollapsibleIcon().props('name')).toBe('angle-right');
  });

  describe('Timeframe shift preset type', () => {
    it('renders rotation shift preset type buttons', () => {
      expect(findRotationsShiftPreset().exists()).toBe(true);
    });

    it('sets shift preset type with a default type', () => {
      const presetBtns = findRotationsShiftPreset().findAllComponents(GlButton);
      expect(presetBtns.at(0).attributes('selected')).toBe(undefined);
      expect(presetBtns.at(1).attributes('selected')).toBe('true');
    });

    it('updates the rotation preset type on click', async () => {
      const presetBtns = findRotationsShiftPreset().findAllComponents(GlButton);
      await presetBtns.at(0).vm.$emit('click');
      expect(presetBtns.at(0).attributes('selected')).toBe('true');
      expect(presetBtns.at(1).attributes('selected')).toBe(undefined);
    });
  });

  describe('Timeframe update', () => {
    describe('WEEKS view', () => {
      beforeEach(() => {
        wrapper.setData({ presetType: PRESET_TYPES.WEEKS });
      });

      it('should load next timeframe', () => {
        const mockDate = new Date('2021/01/28');
        jest.spyOn(dateTimeUtility, 'nWeeksAfter').mockReturnValue(mockDate);
        findLoadNextTimeframeBtn().vm.$emit('click');
        expect(dateTimeUtility.nWeeksAfter).toHaveBeenCalledWith(expect.any(Date), 2);
        expect(wrapper.vm.timeframeStartDate).toEqual(mockDate);
      });

      it('should load previous timeframe', () => {
        const mockDate = new Date('2021/01/28');
        jest.spyOn(dateTimeUtility, 'nWeeksBefore').mockReturnValue(mockDate);
        findLoadPreviousTimeframeBtn().vm.$emit('click');
        expect(dateTimeUtility.nWeeksBefore).toHaveBeenCalledWith(expect.any(Date), 2);
        expect(wrapper.vm.timeframeStartDate).toEqual(mockDate);
      });

      it('should query with a two week timeframe', () => {
        const expectedVariables = {
          iids: [mockSchedule.iid],
          projectPath: 'group/project',
          startsAt: new Date('2020-07-06'),
          endsAt: new Date('2020-07-20'),
        };
        expect(wrapper.vm.$options.apollo.rotations.variables.bind(wrapper.vm)()).toEqual(
          expectedVariables,
        );
      });
    });

    describe('DAYS view', () => {
      beforeEach(() => {
        wrapper.setData({ presetType: PRESET_TYPES.DAYS });
      });
      it('should load next timeframe', () => {
        const mockDate = new Date('2021/01/28');
        jest.spyOn(dateTimeUtility, 'nDaysAfter').mockReturnValue(mockDate);
        findLoadNextTimeframeBtn().vm.$emit('click');
        expect(dateTimeUtility.nDaysAfter).toHaveBeenCalledWith(expect.any(Date), 1);
        expect(wrapper.vm.timeframeStartDate).toEqual(mockDate);
      });

      it('should load previous timeframe', () => {
        const mockDate = new Date('2021/01/28');
        jest.spyOn(dateTimeUtility, 'nDaysBefore').mockReturnValue(mockDate);
        findLoadPreviousTimeframeBtn().vm.$emit('click');
        expect(dateTimeUtility.nDaysBefore).toHaveBeenCalledWith(expect.any(Date), 1);
        expect(wrapper.vm.timeframeStartDate).toEqual(mockDate);
      });

      it('should query with a two week timeframe', () => {
        const expectedVariables = {
          iids: [mockSchedule.iid],
          projectPath: 'group/project',
          startsAt: new Date('2020-07-06'),
          endsAt: new Date('2020-07-07'),
        };
        expect(wrapper.vm.$options.apollo.rotations.variables.bind(wrapper.vm)()).toEqual(
          expectedVariables,
        );
      });
    });
  });

  describe('Card collapsing behavior', () => {
    it('adds content body padding when it is expanded', async () => {
      findCollapsible().vm.$emit('show');
      await nextTick();
      expect(findGlCard().props('bodyClass')).toBe('gl-p-5');
    });

    it('removes content body padding when it is collapsed', async () => {
      findCollapsible().vm.$emit('hidden');
      await nextTick();
      expect(findGlCard().props('bodyClass')).toBe('gl-p-0');
    });
  });

  describe('with Apollo mock', () => {
    it('renders rotations list from API response when resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(findRotationsList().props('rotations')).toHaveLength(4);

      expect(findRotationsList().props('rotations')).toEqual(
        getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0]
          .rotations.nodes,
      );
    });

    it('does not renders rotations list from API response when skipped', async () => {
      createComponent({ scheduleIndex: 1 });
      await nextTick();
      await waitForPromises();

      expect(findRotationsList().props('rotations')).toHaveLength(0);
      expect(findRotationsList().props('rotations')).toEqual([]);
    });
  });
});
