import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectPipeline from 'ee/vue_shared/dashboards/components/project_pipeline.vue';
import { mockPipelineData } from 'ee_jest/vue_shared/dashboards/mock_data';

describe('project pipeline component', () => {
  let wrapper;

  const mountComponent = (propsData = {}) =>
    mountExtended(ProjectPipeline, {
      propsData,
    });

  describe('current pipeline only', () => {
    it('should render success badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData(),
        hasPipelineFailed: false,
      });

      expect(wrapper.findByTestId('status_success-icon').exists()).toBe(true);
    });

    it('should render failed badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData('failed'),
        hasPipelineFailed: true,
      });

      expect(wrapper.findByTestId('status_failed-icon').exists()).toBe(true);
    });

    it('should render running badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData('running'),
        hasPipelineFailed: false,
      });

      expect(wrapper.findByTestId('status_running-icon').exists()).toBe(true);
    });
  });

  describe('upstream pipeline', () => {
    it('should render upstream success badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered_by = mockPipelineData('success');
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(
        wrapper.find('.js-upstream-pipeline-status [data-testid="status_success-icon"]').exists(),
      ).toBe(true);
    });
  });

  describe('downstream pipeline', () => {
    it('should render downstream success badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('success')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(
        wrapper.find('.js-downstream-pipeline-status [data-testid="status_success-icon"]').exists(),
      ).toBe(true);
    });

    it('should render downstream failed badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('failed')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(
        wrapper.find('.js-downstream-pipeline-status [data-testid="status_failed-icon"]').exists(),
      ).toBe(true);
    });

    it('should render downstream running badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('running')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(
        wrapper.find('.js-downstream-pipeline-status [data-testid="status_running-icon"]').exists(),
      ).toBe(true);
    });

    it('should render extra downstream icon', () => {
      const lastPipeline = mockPipelineData('success');
      // 5 is the max we can show, so put 6 in the array
      lastPipeline.triggered = Array.from(new Array(6), (val, index) =>
        mockPipelineData('running', index),
      );
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.find('.js-downstream-extra-icon').exists()).toBe(true);
    });
  });
});
