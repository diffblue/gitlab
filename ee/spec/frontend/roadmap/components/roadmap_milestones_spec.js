import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapMilestones from 'ee/roadmap/components/roadmap_milestones.vue';
import { MILESTONES_ALL, MILESTONES_OPTIONS } from 'ee/roadmap/constants';

describe('RoadmapMilestones', () => {
  let wrapper;

  const createComponent = ({ isShowingMilestones = true } = {}) => {
    const store = createStore();

    store.dispatch('setInitialData', {
      milestonesType: MILESTONES_ALL,
      isShowingMilestones,
    });

    wrapper = shallowMountExtended(RoadmapMilestones, {
      store,
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders form group', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Milestones');
    });

    it.each`
      isShowingMilestones
      ${true}
      ${false}
    `('displays radio form group depending on isShowingMilestones', ({ isShowingMilestones }) => {
      createComponent({ isShowingMilestones });

      expect(findFormRadioGroup().exists()).toBe(isShowingMilestones);
      if (isShowingMilestones) {
        expect(findFormRadioGroup().props('options')).toEqual(MILESTONES_OPTIONS);
      }
    });
  });
});
