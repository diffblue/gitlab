<script>
import { logError } from '~/lib/logger';
import getProjectDetailsQuery from '../../graphql/queries/get_project_details.query.graphql';
import getGroupClusterAgentsQuery from '../../graphql/queries/get_group_cluster_agents.query.graphql';
import { DEFAULT_DEVFILE_PATH } from '../../constants';

export default {
  props: {
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    projectDetails: {
      query: getProjectDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          devFilePath: DEFAULT_DEVFILE_PATH,
        };
      },
      skip() {
        return !this.projectFullPath;
      },
      update() {
        return [];
      },
      error(error) {
        logError(error);
      },
      async result(result) {
        if (result.error) {
          this.$emit('error');
          return;
        }

        const { repository, group, id } = result.data.project;

        const hasDevFile = repository
          ? repository.blobs.nodes.some(({ path }) => path === DEFAULT_DEVFILE_PATH)
          : false;
        const rootRef = repository ? repository.rootRef : null;
        const groupPath = group?.fullPath.split('/').shift() || null;
        const clusterAgentsResponse = await this.fetchClusterAgents(groupPath);

        if (clusterAgentsResponse.error) {
          logError(clusterAgentsResponse.error);
          this.$emit('error');
          return;
        }

        this.$emit('result', {
          id,
          clusterAgents: clusterAgentsResponse.result,
          groupPath,
          hasDevFile,
          rootRef,
        });
      },
    },
  },
  methods: {
    async fetchClusterAgents(groupPath) {
      if (!groupPath) {
        return {
          error: null,
          result: [],
        };
      }

      try {
        const { data, error } = await this.$apollo.query({
          query: getGroupClusterAgentsQuery,
          variables: { groupPath },
        });

        if (error) {
          return { error };
        }

        return {
          result: data.group.clusterAgents.nodes.map((agent) => ({
            value: agent.id,
            text: agent.name,
          })),
        };
      } catch (error) {
        return { error };
      }
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
