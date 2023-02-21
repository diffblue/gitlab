import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import RunnerPerformanceStat from 'ee_component/ci/runner/components/stat/runner_performance_stat.vue';
import RunnerPerformanceModal from 'ee_component/ci/runner/components/stat/runner_performance_modal.vue';

describe('RunnerPerformanceStat', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findModal = () => wrapper.findComponent(RunnerPerformanceModal);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(RunnerPerformanceStat, {
      propsData: {
        ...props,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      ...options,
    });
  };

  describe('when runnerPerformanceInsights is enabled', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          glFeatures: {
            runnerPerformanceInsights: true,
          },
        },
      });
    });

    it('shows a link to the performance modal', () => {
      const linkModalDirective = getBinding(findLink().element, 'gl-modal');
      const modalId = findModal().props('modalId');

      expect(linkModalDirective.value).toBe(modalId);
    });
  });

  describe('when runnerPerformanceInsights is disabled', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          glFeatures: {
            runnerPerformanceInsights: false,
          },
        },
      });
    });

    it('shows no content', () => {
      expect(wrapper.html()).toBe('');
    });
  });
});
