<script>
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';
import workspaceUpdateMutation from '../../graphql/mutations/workspace_update.mutation.graphql';

export const i18n = {
  updateWorkspaceFailedMessage: s__('Workspaces|Failed to update workspace'),
};

export default {
  methods: {
    async update(id, state = {}) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: workspaceUpdateMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPE_WORKSPACE, id),
              ...state,
            },
          },
        });

        const {
          errors: [error],
        } = data.workspaceUpdate;

        if (error) {
          this.$emit('updateFailed', { error });
        } else {
          this.$emit('updateSucceed');
        }
      } catch (e) {
        logError(e);
        this.$emit('updateFailed', { error: i18n.updateWorkspaceFailedMessage });
      }
    },
  },
  render() {
    return this.$scopedSlots.default({ update: this.update });
  },
};
</script>
