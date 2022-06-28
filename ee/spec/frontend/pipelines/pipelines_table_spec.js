import { mount } from '@vue/test-utils';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import { PipelineKeyOptions } from '~/pipelines/constants';

import { triggeredBy, triggered } from './mock_data';

jest.mock('~/pipelines/event_hub');

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const defaultProps = {
    pipelines: [],
    viewType: 'root',
    pipelineKeyOption: PipelineKeyOptions[0],
  };

  const createMockPipeline = () => {
    // Clone fixture as it could be modified by tests
    const { pipelines } = JSON.parse(JSON.stringify(fixture));
    return pipelines.find((p) => p.user !== null && p.commit !== null);
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

  beforeEach(() => {
    pipeline = createMockPipeline();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Pipelines Table', () => {
    describe('pipeline mini graph', () => {
      beforeEach(() => {
        pipeline = createMockPipeline();
        pipeline.triggered_by = triggeredBy;

        createComponent({ pipelines: [pipeline] });
      });

      it('should render a pipeline mini graph', () => {
        expect(findPipelineMiniGraph().exists()).toBe(true);
      });
    });

    describe('upstream linked pipelines', () => {
      beforeEach(() => {
        pipeline = createMockPipeline();
        pipeline.triggered_by = triggeredBy;

        createComponent({ pipelines: [pipeline] });
      });

      it('should render only a upstream pipeline', () => {
        const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');
        const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');

        expect(upstreamPipeline).toEqual(expect.any(Object));
        expect(downstreamPipelines).toHaveLength(0);
      });

      it('should pass an object of the correct data to the linked pipeline component', () => {
        const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');

        expect(upstreamPipeline).toBe(triggeredBy);
      });
    });

    describe('downstream linked pipelines', () => {
      beforeEach(() => {
        pipeline = createMockPipeline();
        pipeline.triggered = triggered;

        createComponent({ pipelines: [pipeline] });
      });

      it('should pass the pipeline path prop for the counter badge', () => {
        const pipelinePath = findPipelineMiniGraph().props('pipelinePath');
        expect(pipelinePath).toBe(pipeline.path);
      });

      it('should render only a downstream pipeline', () => {
        const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');
        const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');

        expect(downstreamPipelines).toEqual(expect.any(Array));
        expect(upstreamPipeline).toEqual(null);
      });

      it('should pass an array of the correct data to the linked pipeline component', () => {
        const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');

        expect(downstreamPipelines).toEqual(triggered);
      });
    });

    describe('upstream and downstream linked pipelines', () => {
      beforeEach(() => {
        pipeline = createMockPipeline();
        pipeline.triggered = triggered;
        pipeline.triggered_by = triggeredBy;

        createComponent({ pipelines: [pipeline] });
      });

      it('should render both downstream and upstream pipelines', () => {
        const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');
        const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');

        expect(downstreamPipelines).toEqual(triggered);
        expect(upstreamPipeline).toEqual(triggeredBy);
      });
    });
  });
});
