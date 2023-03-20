import { GlButton, GlCard, GlIcon, GlCollapse, GlCollapsibleListbox } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockTimezones from 'test_fixtures/timezones/full.json';
import OnCallSchedule, { i18n } from 'ee/oncall_schedules/components/oncall_schedule.vue';
import RotationsListSection from 'ee/oncall_schedules/components/schedule/components/rotations_list_section.vue';
import ScheduleTimelineSection from 'ee/oncall_schedules/components/schedule/components/schedule_timeline_section.vue';
import * as utils from 'ee/oncall_schedules/components/schedule/utils';
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';
import getShiftsForRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules_with_rotations_shifts.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as dateTimeUtility from '~/lib/utils/datetime/date_calculation_utility';
import { getOncallSchedulesQueryResponseWithRotations } from './mocks/apollo_mock';

Vue.use(VueApollo);

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

  const createComponent = ({
    schedule = mockSchedule,
    scheduleIndex = 0,
    getShiftsForRotationsQueryHandler = jest
      .fn()
      .mockResolvedValue(getOncallSchedulesQueryResponseWithRotations),
    props = {},
    provide = {},
    userCanCreateSchedule = true,
    presetType = PRESET_TYPES.WEEKS,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getShiftsForRotationsQuery, getShiftsForRotationsQueryHandler],
    ]);

    wrapper = shallowMountExtended(OnCallSchedule, {
      apolloProvider: fakeApollo,
      propsData: {
        schedule,
        scheduleIndex,
        ...props,
      },
      data() {
        return {
          rotations: schedule.rotations.nodes,
          presetType,
        };
      },
      provide: {
        timezones: mockTimezones,
        projectPath,
        userCanCreateSchedule,
        ...provide,
      },
      stubs: {
        GlCard,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(utils, 'getTimeframeForWeeksView').mockReturnValue(mockWeeksTimeFrame);
    createComponent();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  const findScheduleHeader = () => wrapper.findByTestId('schedule-header');
  const findRotationsHeader = () => wrapper.findByTestId('rotations-header');
  const findRotations = () => wrapper.findByTestId('rotations-body');
  const findRotationsShiftPreset = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAddRotationsBtn = () => findRotationsHeader().findComponent(GlButton);
  const findScheduleTimeline = () => findRotations().findComponent(ScheduleTimelineSection);
  const findRotationsList = () => findRotations().findComponent(RotationsListSection);
  const findLoadPreviousTimeframeBtn = () => wrapper.findByTestId('previous-timeframe-btn');
  const findLoadNextTimeframeBtn = () => wrapper.findByTestId('next-timeframe-btn');
  const findCollapsible = () => wrapper.findComponent(GlCollapse);
  const findCollapsibleIcon = () => wrapper.findComponent(GlIcon);
  const findEditAndDeleteButtons = () => wrapper.findByTestId('schedule-edit-button-group');

  describe('Timeframe schedule card header information', () => {
    const timezone = lastTz.identifier;
    const offset = `(UTC ${lastTz.formatted_offset})`;

    it('shows schedule title and timezone', () => {
      expect(findScheduleHeader().text()).toContain(mockSchedule.name);
    });

    it('shows timezone info', () => {
      expect(findScheduleHeader().text()).toContain(timezone);
      expect(findScheduleHeader().text()).toContain(offset);
    });

    it('shows schedule description if present', () => {
      expect(findScheduleHeader().text()).toContain(mockSchedule.description);
    });

    it('does not show schedule description if none present', () => {
      createComponent({
        schedule: { ...mockSchedule, description: null },
        loading: false,
        scheduleIndex: 0,
      });
      expect(findScheduleHeader()).not.toContain(mockSchedule.description);
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

  it('renders rotations list', async () => {
    await waitForPromises();
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

  it('renders edit and delete buttons', () => {
    expect(findEditAndDeleteButtons().exists()).toBe(true);
  });

  it('renders a open card for the first in the list by default', () => {
    expect(findCollapsible().attributes('visible')).toBe('true');
    expect(findCollapsibleIcon().props('name')).toBe('chevron-lg-down');
  });

  it('renders a collapsed card if not the first in the list by default', () => {
    createComponent({ scheduleIndex: 1 });
    expect(findCollapsible().attributes('visible')).toBeUndefined();
    expect(findCollapsibleIcon().props('name')).toBe('chevron-lg-up');
  });

  describe('Timeframe shift preset type', () => {
    it('renders rotation shift preset type buttons', () => {
      expect(findRotationsShiftPreset().exists()).toBe(true);
    });

    it('sets shift preset type with a default type', () => {
      expect(findRotationsShiftPreset().props('selected')).toBe(PRESET_TYPES.WEEKS);
    });

    it('updates the rotation preset type on click', async () => {
      await findRotationsShiftPreset().vm.$emit('select', PRESET_TYPES.DAYS);
      expect(findRotationsShiftPreset().props('selected')).toBe(PRESET_TYPES.DAYS);
    });
  });

  describe('Timeframe update', () => {
    describe('WEEKS view', () => {
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
        createComponent({ presetType: PRESET_TYPES.DAYS });
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

  describe('with Apollo mock', () => {
    it('renders rotations list from API response when resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(findRotationsList().props('rotations')).toHaveLength(4);

      expect(findRotationsList().props('rotations')).toEqual(
        getOncallSchedulesQueryResponseWithRotations.data.project.incidentManagementOncallSchedules
          .nodes[0].rotations.nodes,
      );
    });

    it('does not renders rotations list from API response when skipped', async () => {
      createComponent({ scheduleIndex: 1 });
      await waitForPromises();

      expect(findRotationsList().props('rotations')).toHaveLength(0);
      expect(findRotationsList().props('rotations')).toEqual([]);
    });
  });

  describe('when user cannot create schedule', () => {
    beforeEach(() => {
      createComponent({ userCanCreateSchedule: false });
    });

    it('does not render edit and delete buttons', () => {
      expect(findEditAndDeleteButtons().exists()).toBe(false);
    });
  });
});
