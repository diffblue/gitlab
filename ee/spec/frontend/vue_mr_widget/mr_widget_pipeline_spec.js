import { shallowMount } from '@vue/test-utils';
import mockData from 'ee_jest/vue_mr_widget/mock_data';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import mockLinkedPipelines from '../vue_shared/components/linked_pipelines_mock_data';

describe('MRWidgetPipeline', () => {
  let wrapper;

  const findPipelineInfoContainer = () => wrapper.find('[data-testid="pipeline-info-container"');
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);

  const createWrapper = (props) => {
    wrapper = shallowMount(MrWidgetPipeline, {
      propsData: {
        pipeline: mockData,
        pipelineCoverageDelta: undefined,
        hasCi: true,
        ciStatus: 'success',
        sourceBranchLink: undefined,
        sourceBranch: undefined,
        mrTroubleshootingDocsPath: 'help',
        ciTroubleshootingDocsPath: 'help2',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('for each type of pipeline', () => {
    let pipeline;

    beforeEach(() => {
      ({ pipeline } = JSON.parse(JSON.stringify(mockData)));

      pipeline.ref.tag = false;
      pipeline.ref.branch = false;
    });

    describe('for a merge train pipeline', () => {
      it('renders a pipeline widget that reads "Merge train pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merge train pipeline';
        pipeline.merge_request_event_type = 'merge_train';

        createWrapper({ pipeline });

        const expected = `Merge train pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;

        expect(findPipelineInfoContainer().text()).toMatchInterpolatedText(expected);
      });
    });

    describe('for a merged result pipeline', () => {
      it('renders a pipeline widget that reads "Merged result pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merged result pipeline';
        pipeline.merge_request_event_type = 'merged_result';

        createWrapper({ pipeline });

        const expected = `Merged result pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;

        expect(findPipelineInfoContainer().text()).toMatchInterpolatedText(expected);
      });
    });
  });

  describe('pipeline graph', () => {
    describe('when upstream pipelines are passed', () => {
      beforeEach(() => {
        const pipeline = { ...mockData.pipeline, triggered_by: mockLinkedPipelines.triggered_by };

        createWrapper({ pipeline });
      });

      it('should render the pipeline mini graph', () => {
        expect(findPipelineMiniGraph().exists()).toBe(true);
      });

      it('should send upstream pipeline', () => {
        const upstreamPipeline = findPipelineMiniGraph().props('upstreamPipeline');

        expect(upstreamPipeline).toBe(mockLinkedPipelines.triggered_by);
      });
    });

    describe('when downstream pipelines are passed', () => {
      beforeEach(() => {
        const pipeline = { ...mockData.pipeline, triggered: mockLinkedPipelines.triggered };

        createWrapper({ pipeline });
      });

      it('should render the pipeline mini graph', () => {
        expect(findPipelineMiniGraph().exists()).toBe(true);
      });

      it('should render the linked pipelines mini list as a downstream list', () => {
        const downstreamPipelines = findPipelineMiniGraph().props('downstreamPipelines');

        expect(downstreamPipelines).toBe(mockLinkedPipelines.triggered);
      });
    });
  });
});
