import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import {
  mockDownstreamQueryResponse,
  mockUpstreamQueryResponse,
  mockUpstreamDownstreamQueryResponse,
  mockStages,
} from '../mock_data';

const fullPath = 'gitlab-org/gitlab';
const iid = '315';
Vue.use(VueApollo);

jest.mock('~/flash');

describe('Commit box pipeline mini graph', () => {
  let wrapper;

  const downstreamHandler = jest.fn().mockResolvedValue(mockDownstreamQueryResponse);
  const upstreamHandler = jest.fn().mockResolvedValue(mockUpstreamQueryResponse);
  const upstreamDownstreamHandler = jest
    .fn()
    .mockResolvedValue(mockUpstreamDownstreamQueryResponse);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMiniGraph = () => wrapper.findByTestId('commit-box-mini-graph');
  const findUpstream = () => wrapper.findByTestId('commit-box-mini-graph-upstream');
  const findDownstream = () => wrapper.findByTestId('commit-box-mini-graph-downstream');

  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[getLinkedPipelinesQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (handler) => {
    wrapper = extendedWrapper(
      shallowMount(CommitBoxPipelineMiniGraph, {
        propsData: {
          stages: mockStages,
        },
        provide: {
          fullPath,
          iid,
          dataMethod: 'graphql',
        },
        apolloProvider: createMockApolloProvider(handler),
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('should display loading state when loading', () => {
      createComponent(downstreamHandler);

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loaded state', () => {
    it('should not display loading state after the query is resolved', async () => {
      createComponent(downstreamHandler);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMiniGraph().exists()).toBe(true);
    });

    it('should pass the pipeline path prop for the counter badge', async () => {
      createComponent(downstreamHandler);

      await waitForPromises();

      const expectedPath = mockDownstreamQueryResponse.data.project.pipeline.path;

      expect(findDownstream().props('pipelinePath')).toBe(expectedPath);
    });

    describe.each`
      handler                      | downstreamRenders | upstreamRenders
      ${downstreamHandler}         | ${true}           | ${false}
      ${upstreamHandler}           | ${false}          | ${true}
      ${upstreamDownstreamHandler} | ${true}           | ${true}
    `('given a linked pipeline', ({ handler, downstreamRenders, upstreamRenders }) => {
      it('should render the correct linked pipelines', async () => {
        createComponent(handler);

        await waitForPromises();

        expect(findDownstream().exists()).toBe(downstreamRenders);
        expect(findUpstream().exists()).toBe(upstreamRenders);
      });
    });
  });

  describe('error state', () => {
    it('createFlash should show if there is an error fetching the data', async () => {
      createComponent({ handler: failedHandler });

      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: 'There was a problem fetching linked pipelines.',
      });
    });
  });
});
