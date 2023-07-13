import { nextTick } from 'vue';
import { GlModal } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import SettingsInstrumentationInstructions from 'ee/product_analytics/onboarding/settings_instrumentation_instructions.vue';
import InstrumentationInstructions from 'ee/product_analytics/onboarding/components/instrumentation_instructions.vue';

import { stubComponent } from 'helpers/stub_component';

describe('ProductAnalyticsSettingsInstrumentationInstructions', () => {
  let wrapper;
  const dashboardsPath = '/foo/bar/dashboards';
  const onboardingPath = '/foo/bar/dashboards/onboarding';

  const findOnboardingLink = () => wrapper.findByTestId('onboarding-link');
  const findModal = () => wrapper.findComponent(GlModal);
  const findInstrumentationInstructionsButton = () =>
    wrapper.findByRole('button', {
      name: 'View instrumentation instructions',
    });
  const findInstrumentationInstructions = () => wrapper.findComponent(InstrumentationInstructions);

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(SettingsInstrumentationInstructions, {
      provide: {
        collectorHost: TEST_COLLECTOR_HOST,
      },
      propsData: {
        dashboardsPath,
        onboardingPath,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  describe('when project is not yet onboarded', () => {
    beforeEach(() => createWrapper({ trackingKey: null }));

    it('has link to onboarding flow', () => {
      expect(findOnboardingLink().exists()).toBe(true);
    });
  });

  describe('when a project is onboarded', () => {
    beforeEach(() => createWrapper({ trackingKey: TEST_TRACKING_KEY }));

    it('has button to show instrumentation instructions', () => {
      expect(findInstrumentationInstructionsButton().exists()).toBe(true);
    });

    it('shows modal when clicking button', async () => {
      findInstrumentationInstructionsButton().trigger('click');
      await nextTick();

      expect(findModal().props('visible')).toBe(true);
    });

    it('hides modal when it is dismissed', async () => {
      const modal = findModal();

      findInstrumentationInstructionsButton().trigger('click');
      await nextTick();

      modal.vm.$emit('change', false);
      await nextTick();

      expect(findModal().props('visible')).toBe(false);
    });

    it('shows instrumentation instructions in modal', async () => {
      findInstrumentationInstructionsButton().trigger('click');
      await nextTick();

      expect(findInstrumentationInstructions().props()).toMatchObject({
        dashboardsPath,
        trackingKey: TEST_TRACKING_KEY,
      });
    });
  });
});
