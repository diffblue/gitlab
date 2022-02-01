import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapProgressTracking from 'ee/roadmap/components/roadmap_progress_tracking.vue';
import { PROGRESS_TRACKING_OPTIONS } from 'ee/roadmap/constants';

describe('RoadmapProgressTracking', () => {
  let wrapper;

  const availableOptions = [
    { text: __('Use issue weight'), value: PROGRESS_TRACKING_OPTIONS.WEIGHT },
    { text: __('Use issue count'), value: PROGRESS_TRACKING_OPTIONS.COUNT },
  ];

  const createComponent = () => {
    const store = createStore();

    store.dispatch('setInitialData', {
      progressTracking: PROGRESS_TRACKING_OPTIONS.WEIGHT,
    });

    wrapper = shallowMountExtended(RoadmapProgressTracking, {
      store,
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders form group', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Progress tracking');
    });

    it('renders radio form group', () => {
      expect(findFormRadioGroup().exists()).toBe(true);
      expect(findFormRadioGroup().props('options')).toEqual(availableOptions);
    });
  });
});
