import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';

import TriggerField from '~/integrations/edit/components/trigger_field.vue';
import { createStore } from '~/integrations/edit/store';

import { mockIntegrationProps } from '../mock_data';

describe('TriggerField', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore({
      customState: { ...mockIntegrationProps },
    });
    wrapper = shallowMount(TriggerField, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('template', () => {
    it('renders GlFormCheckbox', () => {
      createComponent();

      expect(findGlFormCheckbox().exists()).toBe(true);
    });
  });
});
