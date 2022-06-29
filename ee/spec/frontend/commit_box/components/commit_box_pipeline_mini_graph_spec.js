import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import CommitBoxPipelineMiniGraph from '~/projects/commit_box/info/components/commit_box_pipeline_mini_graph.vue';
import { COMMIT_BOX_POLL_INTERVAL } from '~/projects/commit_box/info/constants';
import getLinkedPipelinesQuery from '~/projects/commit_box/info/graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '~/projects/commit_box/info/graphql/queries/get_pipeline_stages.query.graphql';
import * as graphQlUtils from '~/pipelines/components/graph/utils';
import {
  mockDownstreamQueryResponse,
  mockUpstreamQueryResponse,
  mockUpstreamDownstreamQueryResponse,
  mockStages,
  mockPipelineStagesQueryResponse,
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
  const stagesHandler = jest.fn().mockResolvedValue(mockPipelineStagesQueryResponse);

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMiniGraph = () => wrapper.findByTestId('commit-box-mini-graph');
  const findUpstream = () => wrapper.findByTestId('commit-box-mini-graph-upstream');
  const findDownstream = () => wrapper.findByTestId('commit-box-mini-graph-downstream');

  const advanceToNextFetch = () => {
    jest.advanceTimersByTime(COMMIT_BOX_POLL_INTERVAL);
  };

  const createMockApolloProvider = (handler = downstreamHandler) => {
    const requestHandlers = [
      [getLinkedPipelinesQuery, handler],
      [getPipelineStagesQuery, stagesHandler],
    ];

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
          graphqlResourceEtag: '/api/graphql:pipelines/id/320',
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
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findMiniGraph().exists()).toBe(false);
    });
  });

  describe('loaded state', () => {
    it('should not display loading state after the query is resolved', async () => {
      createComponent();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findMiniGraph().exists()).toBe(true);
    });

    it('should pass the pipeline path prop for the counter badge', async () => {
      createComponent();

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

    it('formatted stages should be passed to the pipeline mini graph', async () => {
      const stage = mockStages[0];
      const expectedStages = [
        {
          name: stage.name,
          status: {
            id: stage.status.id,
            icon: stage.status.icon,
            group: stage.status.group,
          },
          dropdown_path: stage.dropdown_path,
          title: stage.title,
        },
      ];

      createComponent();

      await waitForPromises();

      expect(findMiniGraph().props('stages')).toEqual(expectedStages);
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

  describe('polling', () => {
    it('polling interval is set for linked pipelines', () => {
      createComponent();

      const expectedInterval = wrapper.vm.$apollo.queries.pipeline.options.pollInterval;

      expect(expectedInterval).toBe(COMMIT_BOX_POLL_INTERVAL);
    });

    it('polling interval is set for pipeline stages', () => {
      createComponent();

      const expectedInterval = wrapper.vm.$apollo.queries.pipelineStages.options.pollInterval;

      expect(expectedInterval).toBe(COMMIT_BOX_POLL_INTERVAL);
    });

    it('polls for stages and linked pipelines', async () => {
      createComponent();

      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(1);
      expect(downstreamHandler).toHaveBeenCalledTimes(1);

      advanceToNextFetch();
      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(2);
      expect(downstreamHandler).toHaveBeenCalledTimes(2);

      advanceToNextFetch();
      await waitForPromises();

      expect(stagesHandler).toHaveBeenCalledTimes(3);
      expect(downstreamHandler).toHaveBeenCalledTimes(3);
    });

    it('toggles query polling with visibility check', async () => {
      jest.spyOn(graphQlUtils, 'toggleQueryPollingByVisibility');

      createComponent();

      await waitForPromises();

      expect(graphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipelineStages,
      );
      expect(graphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipeline,
      );
    });
  });
});
