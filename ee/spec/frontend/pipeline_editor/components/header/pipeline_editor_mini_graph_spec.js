import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import PipelineEditorMiniGraph from '~/pipeline_editor/components/header/pipeline_editor_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import { mockLinkedPipelines, mockProjectFullPath, mockProjectPipeline } from '../../mock_data';

Vue.use(VueApollo);

describe('Pipeline Status', () => {
  let wrapper;
  let mockApollo;
  let mockLinkedPipelinesQuery;

  const createComponent = ({ hasStages = true, options } = {}) => {
    wrapper = shallowMount(PipelineEditorMiniGraph, {
      provide: {
        dataMethod: 'graphql',
        projectFullPath: mockProjectFullPath,
      },
      propsData: {
        pipeline: mockProjectPipeline({ hasStages }).pipeline,
      },
      ...options,
    });
  };

  const createComponentWithApollo = (hasStages = true) => {
    const handlers = [[getLinkedPipelinesQuery, mockLinkedPipelinesQuery]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      hasStages,
      options: {
        apolloProvider: mockApollo,
      },
    });
  };

  const findUpstream = () => wrapper.find('[data-testid="pipeline-editor-mini-graph-upstream"]');
  const findDownstream = () =>
    wrapper.find('[data-testid="pipeline-editor-mini-graph-downstream"]');

  beforeEach(() => {
    mockLinkedPipelinesQuery = jest.fn();
  });

  afterEach(() => {
    mockLinkedPipelinesQuery.mockReset();
    wrapper.destroy();
  });

  describe('when querying upstream and downstream pipelines', () => {
    describe('when query succeeds', () => {
      beforeEach(() => {
        mockLinkedPipelinesQuery.mockResolvedValue(mockLinkedPipelines());
        createComponentWithApollo();
      });

      describe('linked pipeline rendering based on given data', () => {
        it.each`
          hasDownstream | hasUpstream | downstreamRenderAction | upstreamRenderAction
          ${true}       | ${true}     | ${'renders'}           | ${'renders'}
          ${true}       | ${false}    | ${'renders'}           | ${'hides'}
          ${false}      | ${true}     | ${'hides'}             | ${'renders'}
          ${false}      | ${false}    | ${'hides'}             | ${'hides'}
        `(
          '$downstreamRenderAction downstream and $upstreamRenderAction upstream',
          async ({ hasDownstream, hasUpstream }) => {
            mockLinkedPipelinesQuery.mockResolvedValue(
              mockLinkedPipelines({ hasDownstream, hasUpstream }),
            );
            createComponentWithApollo();
            await waitForPromises();

            expect(findUpstream().exists()).toBe(hasUpstream);
            expect(findDownstream().exists()).toBe(hasDownstream);
          },
        );
      });
    });
  });
});
