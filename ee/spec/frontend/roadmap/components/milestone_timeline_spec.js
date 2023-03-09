import { shallowMount } from '@vue/test-utils';

import MilestoneItem from 'ee/roadmap/components/milestone_item.vue';
import MilestoneTimelineComponent from 'ee/roadmap/components/milestone_timeline.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockMilestone2, mockGroupId } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('MilestoneTimelineComponent', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(MilestoneTimelineComponent, {
      propsData: {
        presetType: PRESET_TYPES.MONTHS,
        timeframe: mockTimeframeMonths,
        milestones: [mockMilestone2],
        currentGroupId: mockGroupId,
        milestonesExpanded: true,
        ...props,
      },
    });
  };

  const findMilestoneItem = () => wrapper.findComponent(MilestoneItem);

  describe.each`
    props                            | hasMilestoneItem
    ${{}}                            | ${true}
    ${{ milestonesExpanded: false }} | ${false}
  `('with $props', ({ props, hasMilestoneItem }) => {
    beforeEach(() => {
      createWrapper(props);
    });

    it(`renders MilestoneItem component = ${hasMilestoneItem}`, () => {
      expect(findMilestoneItem().exists()).toBe(hasMilestoneItem);
    });
  });
});
