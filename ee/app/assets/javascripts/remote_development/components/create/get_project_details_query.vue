<script>
import { logError } from '~/lib/logger';
import getProjectDetails from '../../graphql/queries/get_project_details.query.graphql';
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
      query: getProjectDetails,
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
      result(result) {
        if (result.error) {
          this.$emit('error');
          return;
        }

        const { repository, group, id } = result.data.project;

        const hasDevFile =
          repository.blobs.nodes.some(({ path }) => path === DEFAULT_DEVFILE_PATH) || false;
        const clusterAgents =
          group?.clusterAgents.nodes.map((agent) => ({
            value: agent.id,
            text: agent.name,
          })) || [];
        const groupPath = group?.fullPath;

        this.$emit('result', {
          hasDevFile,
          clusterAgents,
          groupPath,
          id,
        });
      },
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
