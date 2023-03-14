import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapEpicsState from 'ee/roadmap/components/roadmap_epics_state.vue';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

describe('RoadmapEpicsState', () => {
  let wrapper;

  const availableStates = [
    { text: __('Show all epics'), value: STATUS_ALL },
    { text: __('Show open epics'), value: STATUS_OPEN },
    { text: __('Show closed epics'), value: STATUS_CLOSED },
  ];

  const createComponent = () => {
    const store = createStore();

    store.dispatch('setInitialData', {
      epicsState: STATUS_ALL,
    });

    wrapper = shallowMountExtended(RoadmapEpicsState, {
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
      expect(findFormGroup().attributes('label')).toBe('Epics');
    });

    it('renders radio form group', () => {
      expect(findFormRadioGroup().exists()).toBe(true);
      expect(findFormRadioGroup().props('options')).toEqual(availableStates);
    });
  });
});
