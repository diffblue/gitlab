import { GlCard } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RotationsAssignee from 'ee/oncall_schedules/components/rotations/components/rotation_assignee.vue';
import CurrentDayIndicator from 'ee/oncall_schedules/components/schedule/components/current_day_indicator.vue';
import RotationsListSection from 'ee/oncall_schedules/components/schedule/components/rotations_list_section.vue';
import { getTimeframeForWeeksView } from 'ee/oncall_schedules/components/schedule/utils';
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { scheduleIid } from '../../mocks/apollo_mock';
import mockRotations from '../../mocks/mock_rotation.json';

jest.mock('~/lib/utils/color_utils');

describe('RotationsListSectionComponent', () => {
  let wrapper;
  const mockTimeframeInitialDate = new Date(mockRotations[0].shifts.nodes[0].startsAt);
  const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);
  const projectPath = 'group/project';

  function createComponent({
    presetType = PRESET_TYPES.WEEKS,
    timeframe = mockTimeframeWeeks,
  } = {}) {
    wrapper = extendedWrapper(
      mount(RotationsListSection, {
        propsData: {
          presetType,
          timeframe,
          scheduleIid,
          rotations: [mockRotations[0]],
        },
        provide: {
          projectPath,
        },
        stubs: {
          GlCard,
        },
        directives: {
          GlTooltip: createMockDirective(),
        },
      }),
    );
  }

  const findTimelineCells = () => wrapper.findAllByTestId('timeline-cell');
  const findRotationAssignees = () => wrapper.findAllComponents(RotationsAssignee);
  const findCurrentDayIndicatorContent = () => wrapper.findByTestId('current-day-indicator');
  const findRotationName = (id) => wrapper.findByTestId(`rotation-name-${id}`);
  const findRotationNameTooltip = (id) => getBinding(findRotationName(id).element, 'gl-tooltip');

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('when the timeframe includes today', () => {
    useFakeDate(2021, 0, 14);

    beforeEach(() => {
      createComponent();
    });

    it('renders component layout', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the current day indicator if the timeframe includes the current day', () => {
      expect(findCurrentDayIndicatorContent().exists()).toBe(true);
    });

    it('renders timeline cell items based on timeframe data', () => {
      const mockTimelineCellWidth = 1;
      expect(findTimelineCells().length).toBe(mockTimelineCellWidth);
    });

    it('renders current day indicator in the first timeline cell', () => {
      expect(findTimelineCells().at(0).findComponent(CurrentDayIndicator).exists()).toBe(true);
    });

    it('render the correct amount of rotation assignees with their related information', () => {
      expect(findRotationAssignees()).toHaveLength(mockRotations[0].shifts.nodes.length);
      expect(findRotationAssignees().at(0).props().assignee.user).toEqual(
        mockRotations[0].shifts.nodes[0].participant.user,
      );
    });

    it('renders a tooltip with the rotation name', () => {
      const rotationNameTT = findRotationNameTooltip(mockRotations[0].id);
      expect(rotationNameTT.value).toBeDefined();
      expect(rotationNameTT.value.title).toBe(mockRotations[0].name);
    });
  });

  describe('when the timeframe does not include today', () => {
    useFakeDate(2021, 0, 31);

    beforeEach(() => {
      createComponent();
    });

    it('does not render the current day indicator', () => {
      expect(findCurrentDayIndicatorContent().exists()).toBe(false);
    });
  });
});
