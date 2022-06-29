import { shallowMount } from '@vue/test-utils';
import LinkedPipelinesMiniList from 'ee/vue_shared/components/linked_pipelines_mini_list.vue';
import mockData from 'ee_jest/vue_mr_widget/mock_data';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mockLinkedPipelines from '../vue_shared/components/linked_pipelines_mock_data';

describe('MRWidgetPipeline', () => {
  let wrapper;

  const findPipelineInfoContainer = () => wrapper.find('[data-testid="pipeline-info-container"');
  const findPipelinesMiniList = () => wrapper.findComponent(LinkedPipelinesMiniList);

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

      it('should render the linked pipelines mini list', () => {
        expect(findPipelinesMiniList().exists()).toBe(true);
      });

      it('should render the linked pipelines mini list as an upstream list', () => {
        expect(findPipelinesMiniList().classes('is-upstream')).toBe(true);
      });

      it('should add a single triggeredBy into an array', () => {
        const triggeredBy = findPipelinesMiniList().props('triggeredBy');

        expect(triggeredBy).toEqual(expect.any(Array));
        expect(triggeredBy).toHaveLength(1);
        expect(triggeredBy[0]).toBe(mockLinkedPipelines.triggered_by);
      });
    });

    describe('when downstream pipelines are passed', () => {
      beforeEach(() => {
        const pipeline = { ...mockData.pipeline, triggered: mockLinkedPipelines.triggered };

        createWrapper({ pipeline });
      });

      it('should render the linked pipelines mini list', () => {
        expect(findPipelinesMiniList().exists()).toBe(true);
      });

      it('should render the linked pipelines mini list as a downstream list', () => {
        expect(findPipelinesMiniList().classes('is-downstream')).toBe(true);
      });

      it('should pass the triggered pipelines', () => {
        const triggered = findPipelinesMiniList().props('triggered');

        expect(triggered).toBe(mockLinkedPipelines.triggered);
      });
    });
  });
});
