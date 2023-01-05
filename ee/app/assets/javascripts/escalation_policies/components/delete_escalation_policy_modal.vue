<script>
import { GlSprintf, GlModal, GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { updateStoreAfterEscalationPolicyDelete } from '../graphql/cache_updates';
import destroyEscalationPolicyMutation from '../graphql/mutations/destroy_escalatiion_policy.mutation.graphql';
import getEscalationPoliciesQuery from '../graphql/queries/get_escalation_policies.query.graphql';

export const i18n = {
  deleteEscalationPolicy: s__('EscalationPolicies|Delete escalation policy'),
  deleteEscalationPolicyMessage: s__(
    'EscalationPolicies|Are you sure you want to delete the "%{escalationPolicy}" escalation policy? This action cannot be undone.',
  ),
};

export default {
  i18n,
  components: {
    GlSprintf,
    GlModal,
    GlAlert,
  },
  inject: ['projectPath'],
  props: {
    escalationPolicy: {
      type: Object,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
    };
  },
  computed: {
    primaryProps() {
      return {
        text: this.$options.i18n.deleteEscalationPolicy,
        attributes: { category: 'primary', variant: 'danger', loading: this.loading },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    deleteEscalationPolicy() {
      const {
        escalationPolicy: { id },
        projectPath,
      } = this;

      this.loading = true;
      this.$apollo
        .mutate({
          mutation: destroyEscalationPolicyMutation,
          variables: {
            input: {
              id,
            },
          },
          update(store, { data }) {
            updateStoreAfterEscalationPolicyDelete(store, getEscalationPoliciesQuery, data, {
              projectPath,
            });
          },
        })
        .then(({ data: { escalationPolicyDestroy } = {} } = {}) => {
          const error = escalationPolicyDestroy.errors[0];
          if (error) {
            throw error;
          }
          this.$refs.deleteEscalationPolicyModal.hide();
        })
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    hideErrorAlert() {
      this.error = null;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="deleteEscalationPolicyModal"
    :modal-id="modalId"
    size="sm"
    :title="$options.i18n.deleteEscalationPolicy"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary.prevent="deleteEscalationPolicy"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mt-n3 gl-mb-3" @dismiss="hideErrorAlert">
      {{ error || $options.i18n.errorMsg }}
    </gl-alert>
    <gl-sprintf :message="$options.i18n.deleteEscalationPolicyMessage">
      <template #escalationPolicy>{{ escalationPolicy.name }}</template>
    </gl-sprintf>
  </gl-modal>
</template>
