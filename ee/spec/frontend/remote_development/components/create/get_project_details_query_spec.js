import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { logError } from '~/lib/logger';
import getProjectDetailsQuery from 'ee/remote_development/graphql/queries/get_project_details.query.graphql';
import GetProjectDetailsQuery from 'ee/remote_development/components/create/get_project_details_query.vue';
import { DEFAULT_DEVFILE_PATH } from 'ee/remote_development/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { GET_PROJECT_DETAILS_QUERY_RESULT } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/logger');

describe('remote_development/components/create/get_project_details_query', () => {
  let mockApollo;
  let getProjectAgentsAndRootFilesQueryHandler;
  let wrapper;
  const projectFullPathFixture = 'gitlab-org/gitlab';

  const buildMockApollo = () => {
    getProjectAgentsAndRootFilesQueryHandler = jest.fn();
    getProjectAgentsAndRootFilesQueryHandler.mockResolvedValueOnce(
      GET_PROJECT_DETAILS_QUERY_RESULT,
    );
    mockApollo = createMockApollo([
      [getProjectDetailsQuery, getProjectAgentsAndRootFilesQueryHandler],
    ]);
  };
  const buildWrapper = async ({ projectFullPath = projectFullPathFixture } = {}) => {
    wrapper = shallowMountExtended(GetProjectDetailsQuery, {
      apolloProvider: mockApollo,
      propsData: {
        projectFullPath,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => {
    buildMockApollo();
  });

  describe('when project full path is provided', () => {
    it('executes get_project_details query', async () => {
      await buildWrapper();

      expect(getProjectAgentsAndRootFilesQueryHandler).toHaveBeenCalledWith({
        projectFullPath: projectFullPathFixture,
        devFilePath: DEFAULT_DEVFILE_PATH,
      });
    });

    it('emits result event with fetched cluster agents, project id, project group, and root files', async () => {
      await buildWrapper();

      expect(wrapper.emitted('result')[0][0]).toMatchObject({
        clusterAgents: [
          {
            text: 'default-agent',
            value: 'agents/1',
          },
        ],
        id: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
        groupPath: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
      });
    });

    describe('when the project repository has .devfile in the root repository', () => {
      beforeEach(() => {
        const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

        customMockData.data.project.repository.blobs.nodes.push({
          id: DEFAULT_DEVFILE_PATH,
          path: DEFAULT_DEVFILE_PATH,
        });

        getProjectAgentsAndRootFilesQueryHandler.mockReset();
        getProjectAgentsAndRootFilesQueryHandler.mockResolvedValueOnce(customMockData);
      });

      it('emits result event with hasDevFile property that equals true', async () => {
        await buildWrapper();

        expect(wrapper.emitted('result')[0][0]).toMatchObject({
          hasDevFile: true,
        });
      });
    });

    describe('when the project repository does not have .devfile in the root repository', () => {
      beforeEach(() => {
        const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

        customMockData.data.project.repository.blobs.nodes = customMockData.data.project.repository.blobs.nodes.filter(
          (blob) => blob.path !== DEFAULT_DEVFILE_PATH,
        );

        getProjectAgentsAndRootFilesQueryHandler.mockReset();
        getProjectAgentsAndRootFilesQueryHandler.mockResolvedValueOnce(customMockData);
      });

      it('emits result event with hasDevFile property that equals false', async () => {
        await buildWrapper();

        expect(wrapper.emitted('result')[0][0]).toMatchObject({
          hasDevFile: false,
        });
      });
    });
  });

  describe('when project full path is not provided', () => {
    it('does not execute get_project_details query', async () => {
      await buildWrapper({ projectFullPath: null });

      expect(getProjectAgentsAndRootFilesQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when a graphql query error occurs', () => {
    const error = new Error();

    beforeEach(() => {
      getProjectAgentsAndRootFilesQueryHandler.mockReset();
      getProjectAgentsAndRootFilesQueryHandler.mockRejectedValueOnce(error);
    });
    it('logs the error', async () => {
      expect(logError).not.toHaveBeenCalled();

      await buildWrapper();

      expect(logError).toHaveBeenCalledWith(error);
    });

    it('emits error event', async () => {
      await buildWrapper();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });
});
