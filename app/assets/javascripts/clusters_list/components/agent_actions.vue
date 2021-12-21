<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { DELETE_AGENT_MODAL_ID } from '../constants';
import deleteAgent from '../graphql/mutations/delete_agent.mutation.graphql';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import { removeAgentFromStore } from '../graphql/cache_update';

export default {
  i18n: {
    dropdownText: __('More actions'),
    deleteButton: s__('ClusterAgents|Delete agent'),
    modalTitle: __('Are you sure?'),
    modalBody: s__(
      'ClusterAgents|Are you sure you want to delete this agent? This action cannot be undone.',
    ),
    modalInputLabel: s__('ClusterAgents|To delete the agent, type %{name} to confirm:'),
    modalAction: s__('ClusterAgents|Delete'),
    modalCancel: __('Cancel'),
    successMessage: s__('ClusterAgents|%{name} successfully deleted'),
    defaultError: __('An error occurred. Please try again.'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlSprintf,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['projectPath'],
  props: {
    agent: {
      required: true,
      type: Object,
    },
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
    maxAgents: {
      default: null,
      required: false,
      type: Number,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
      deleteConfirmText: null,
    };
  },
  computed: {
    getAgentsQueryVariables() {
      return {
        defaultBranchName: this.defaultBranchName,
        first: this.maxAgents,
        last: null,
        projectPath: this.projectPath,
      };
    },
    modalId() {
      return sprintf(DELETE_AGENT_MODAL_ID, {
        agentName: this.agent.name,
      });
    },
    primaryModalProps() {
      return {
        text: this.$options.i18n.modalAction,
        attributes: [
          { disabled: this.loading || this.disableModalSubmit, loading: this.loading },
          { variant: 'danger' },
        ],
      };
    },
    cancelModalProps() {
      return {
        text: this.$options.i18n.modalCancel,
        attributes: [],
      };
    },
    disableModalSubmit() {
      return this.deleteConfirmText !== this.agent.name;
    },
  },
  methods: {
    async deleteAgent() {
      this.loading = true;
      this.error = null;

      const successMessage = sprintf(this.$options.i18n.successMessage, { name: this.agent.name });

      try {
        const { errors } = await this.deleteAgentMutation();

        if (errors?.length > 0) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        if (error?.message) {
          this.error = error.message;
        } else {
          this.error = this.$options.i18n.defaultError;
        }
      } finally {
        this.loading = false;

        if (!this.error) {
          this.$toast.show(successMessage);
        } else {
          this.$toast.show(this.error);
        }

        this.$refs.modal.hide();
      }
    },
    deleteAgentMutation() {
      return this.$apollo
        .mutate({
          mutation: deleteAgent,
          variables: {
            input: {
              id: this.agent.id,
            },
          },
          update: (store) => {
            const deleteClusterAgent = this.agent;
            removeAgentFromStore(
              store,
              deleteClusterAgent,
              getAgentsQuery,
              this.getAgentsQueryVariables,
            );
          },
        })

        .then(({ data: { clusterAgentDelete } }) => {
          return clusterAgentDelete;
        });
    },
    hideModal() {
      this.loading = false;
      this.error = null;
      this.deleteConfirmText = null;
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      icon="ellipsis_v"
      right
      :disabled="loading"
      :text="$options.i18n.dropdownText"
      text-sr-only
      category="tertiary"
      no-caret
    >
      <gl-dropdown-item v-gl-modal-directive="modalId">
        {{ $options.i18n.deleteButton }}
      </gl-dropdown-item>
    </gl-dropdown>

    <gl-modal
      ref="modal"
      :modal-id="modalId"
      :title="$options.i18n.modalTitle"
      :action-primary="primaryModalProps"
      :action-cancel="cancelModalProps"
      size="sm"
      @primary="deleteAgent"
      @hide="hideModal"
    >
      <p>{{ $options.i18n.modalBody }}</p>

      <gl-form-group>
        <template #label>
          <gl-sprintf :message="$options.i18n.modalInputLabel">
            <template #name>
              <code>{{ agent.name }}</code>
            </template>
          </gl-sprintf>
        </template>
        <gl-form-input v-model="deleteConfirmText" @keyup.enter="deleteAgent" />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
