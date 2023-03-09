import { GlDropdown, GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapDaterange from 'ee/roadmap/components/roadmap_daterange.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

describe('RoadmapDaterange', () => {
  let wrapper;

  const quarters = { text: 'By quarter', value: PRESET_TYPES.QUARTERS };
  const months = { text: 'By month', value: PRESET_TYPES.MONTHS };
  const weeks = { text: 'By week', value: PRESET_TYPES.WEEKS };

  const createComponent = ({ timeframeRangeType = DATE_RANGES.CURRENT_QUARTER } = {}) => {
    const store = createStore();

    store.dispatch('setInitialData', {
      presetType: PRESET_TYPES.MONTHS,
    });

    wrapper = shallowMountExtended(RoadmapDaterange, {
      store,
      propsData: { timeframeRangeType },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders labels', () => {
      expect(wrapper.find('label').exists()).toBe(true);
      expect(wrapper.find('label').text()).toContain('Date range');
    });

    it('renders dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it.each`
      timeframeRangeType             | hasFormGroup | availablePresets
      ${DATE_RANGES.CURRENT_QUARTER} | ${false}     | ${[]}
      ${DATE_RANGES.CURRENT_YEAR}    | ${true}      | ${[months, weeks]}
      ${DATE_RANGES.THREE_YEARS}     | ${true}      | ${[quarters, months, weeks]}
    `(
      'renders radio group depending on timeframeRangeType',
      async ({ timeframeRangeType, hasFormGroup, availablePresets }) => {
        createComponent({ timeframeRangeType });

        await nextTick();

        expect(findFormGroup().exists()).toBe(hasFormGroup);
        if (hasFormGroup) {
          expect(findFormRadioGroup().props('options')).toEqual(availablePresets);
        }
      },
    );
  });
});
