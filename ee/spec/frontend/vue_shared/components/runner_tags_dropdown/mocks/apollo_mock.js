import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createApolloProvider from 'helpers/mock_apollo_helper';
import projectRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/vue_shared/components/runner_tags_dropdown/graphql/get_group_runner_tags.query.graphql';
import { RUNNER_TAG_LIST_MOCK } from './mocks';

export const PROJECT_ID = 'gid://gitlab/Project/20';

const defaultHandlerValue = (type = 'project') =>
  jest.fn().mockResolvedValue({
    data: {
      [type]: {
        id: PROJECT_ID,
        runners: {
          nodes: RUNNER_TAG_LIST_MOCK,
        },
      },
    },
  });

export const createMockApolloProvider = ({ handlers = undefined }) => {
  Vue.use(VueApollo);

  const REQUEST_HANDLERS = handlers || {
    projectRequestHandler: defaultHandlerValue('project'),
    groupRequestHandler: defaultHandlerValue('group'),
  };

  const apolloProvider = createApolloProvider([
    [projectRunnerTags, REQUEST_HANDLERS.projectRequestHandler],
    [groupRunnerTags, REQUEST_HANDLERS.groupRequestHandler],
  ]);

  return {
    requestHandlers: REQUEST_HANDLERS,
    apolloProvider,
  };
};
