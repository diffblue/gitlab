import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { logError } from '~/lib/logger';
import getProjectDetailsQuery from 'ee/remote_development/graphql/queries/get_project_details.query.graphql';
import getGroupClusterAgentsQuery from 'ee/remote_development/graphql/queries/get_group_cluster_agents.query.graphql';
import GetProjectDetailsQuery from 'ee/remote_development/components/create/get_project_details_query.vue';
import { DEFAULT_DEVFILE_PATH } from 'ee/remote_development/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  GET_PROJECT_DETAILS_QUERY_RESULT,
  GET_GROUP_CLUSTER_AGENTS_QUERY_RESULT,
} from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/logger');

describe('remote_development/components/create/get_project_details_query', () => {
  let mockApollo;
  let getProjectDetailsQueryHandler;
  let getGroupClusterAgentsQueryHandler;
  let wrapper;
  const projectFullPathFixture = 'gitlab-org/gitlab';

  const buildMockApollo = () => {
    getProjectDetailsQueryHandler = jest.fn();
    getGroupClusterAgentsQueryHandler = jest.fn();
    getProjectDetailsQueryHandler.mockResolvedValueOnce(GET_PROJECT_DETAILS_QUERY_RESULT);
    getGroupClusterAgentsQueryHandler.mockResolvedValueOnce(GET_GROUP_CLUSTER_AGENTS_QUERY_RESULT);
    mockApollo = createMockApollo([
      [getProjectDetailsQuery, getProjectDetailsQueryHandler],
      [getGroupClusterAgentsQuery, getGroupClusterAgentsQueryHandler],
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

      expect(getProjectDetailsQueryHandler).toHaveBeenCalledWith({
        projectFullPath: projectFullPathFixture,
        devFilePath: DEFAULT_DEVFILE_PATH,
      });
    });

    it('executes get_group_cluster_agents query', async () => {
      await buildWrapper();

      expect(getGroupClusterAgentsQueryHandler).toHaveBeenCalledWith({
        groupPath: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
      });
    });

    it('emits result event with fetched cluster agents, project id, project group, and root files', async () => {
      await buildWrapper();

      expect(wrapper.emitted('result')[0][0]).toMatchObject({
        clusterAgents: GET_GROUP_CLUSTER_AGENTS_QUERY_RESULT.data.group.clusterAgents.nodes.map(
          ({ id, name, project }) => ({
            text: `${project.nameWithNamespace} / ${name}`,
            value: id,
          }),
        ),
        id: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
        groupPath: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.group.fullPath,
        rootRef: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.repository.rootRef,
        hasDevFile: false,
      });
    });

    describe('when the project repository has .devfile in the root repository', () => {
      beforeEach(() => {
        const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

        customMockData.data.project.repository.blobs.nodes.push({
          id: DEFAULT_DEVFILE_PATH,
          path: DEFAULT_DEVFILE_PATH,
        });

        getProjectDetailsQueryHandler.mockReset();
        getProjectDetailsQueryHandler.mockResolvedValueOnce(customMockData);
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

        getProjectDetailsQueryHandler.mockReset();
        getProjectDetailsQueryHandler.mockResolvedValueOnce(customMockData);
      });

      it('emits result event with hasDevFile property that equals false', async () => {
        await buildWrapper();

        expect(wrapper.emitted('result')[0][0]).toMatchObject({
          hasDevFile: false,
        });
      });
    });
  });

  describe('when the project does not have a repository', () => {
    beforeEach(() => {
      const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

      customMockData.data.project.repository = null;

      getProjectDetailsQueryHandler.mockReset();
      getProjectDetailsQueryHandler.mockResolvedValueOnce(customMockData);
    });

    it('emits result event with hasDevFile property that equals false and rootRef null', async () => {
      await buildWrapper();

      expect(wrapper.emitted('result')[0][0]).toMatchObject({
        hasDevFile: false,
        rootRef: null,
      });
    });
  });

  describe('when project full path is not provided', () => {
    it('does not execute get_project_details query', async () => {
      await buildWrapper({ projectFullPath: null });

      expect(getProjectDetailsQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when a project does not belong to a group', () => {
    beforeEach(async () => {
      const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

      customMockData.data.project.group = null;

      getProjectDetailsQueryHandler.mockReset();
      getProjectDetailsQueryHandler.mockResolvedValueOnce(customMockData);

      await buildWrapper();
    });

    it('does not execute the getGroupClusterAgents query', () => {
      expect(getProjectDetailsQueryHandler).toHaveBeenCalled();
      expect(getGroupClusterAgentsQueryHandler).not.toHaveBeenCalled();
    });

    it('emits result event with the project data', () => {
      expect(wrapper.emitted('result')[0][0]).toMatchObject({
        clusterAgents: [],
        id: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
        groupPath: null,
        hasDevFile: false,
        rootRef: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.repository.rootRef,
      });
    });
  });

  describe('when the project full path changes', () => {
    it('fetches the project root group', async () => {
      const customMockData = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);

      await buildWrapper();

      expect(getGroupClusterAgentsQueryHandler).toHaveBeenCalledTimes(1);

      customMockData.data.project.group.fullPath = 'new';

      getProjectDetailsQueryHandler.mockResolvedValueOnce(customMockData);

      await wrapper.setProps({ projectFullPath: 'new/path' });

      await waitForPromises();

      expect(getGroupClusterAgentsQueryHandler).toHaveBeenCalledTimes(2);
    });
  });

  describe('when the project full path changes from group to not group', () => {
    it('emits empty clusters', async () => {
      await buildWrapper();

      expect(getGroupClusterAgentsQueryHandler).toHaveBeenCalledTimes(1);

      const projectWithoutGroup = cloneDeep(GET_PROJECT_DETAILS_QUERY_RESULT);
      projectWithoutGroup.data.project.group = null;
      getProjectDetailsQueryHandler.mockResolvedValueOnce(projectWithoutGroup);

      // assert that we've only emitted once
      expect(wrapper.emitted('result')).toHaveLength(1);
      await wrapper.setProps({ projectFullPath: 'new/path' });

      await waitForPromises();

      // assert against the last emitted result
      expect(wrapper.emitted('result')).toHaveLength(2);
      expect(wrapper.emitted('result')[1]).toEqual([
        {
          clusterAgents: [],
          groupPath: null,
          hasDevFile: false,
          id: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.id,
          rootRef: GET_PROJECT_DETAILS_QUERY_RESULT.data.project.repository.rootRef,
        },
      ]);
    });
  });

  describe.each`
    queryName                       | queryHandlerFactory
    ${'getProjectDetailsQuery'}     | ${() => getProjectDetailsQueryHandler}
    ${'getGroupClusterAgentsQuery'} | ${() => getGroupClusterAgentsQueryHandler}
  `('when the $queryName query fails', ({ queryHandlerFactory }) => {
    const error = new Error();

    beforeEach(() => {
      const queryHandler = queryHandlerFactory();

      queryHandler.mockReset();
      queryHandler.mockRejectedValueOnce(error);
    });

    it('logs the error', async () => {
      expect(logError).not.toHaveBeenCalled();

      await buildWrapper();

      expect(logError).toHaveBeenCalledWith(error);
    });

    it('does not emit result event', async () => {
      await buildWrapper();

      expect(wrapper.emitted('result')).toBe(undefined);
    });

    it('emits error event', async () => {
      await buildWrapper();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });
});
