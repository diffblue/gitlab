<script>
import * as Sentry from '@sentry/browser';
import { GlToggle } from '@gitlab/ui';
import produce from 'immer';
import { __ } from '~/locale';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import {
  CANNOT_ASSIGN_ADDON_ERROR_CODE,
  CANNOT_UNASSIGN_ADDON_ERROR_CODE,
  ADD_ON_ERROR_DICTIONARY,
} from 'ee/usage_quotas/error_constants';
import getAddOnEligibleUsers from 'ee/usage_quotas/add_on/graphql/add_on_eligible_users.query.graphql';
import userAddOnAssignmentCreateMutation from 'ee/usage_quotas/add_on/graphql/user_add_on_assignment_create.mutation.graphql';
import userAddOnAssignmentRemoveMutation from 'ee/usage_quotas/add_on/graphql/user_add_on_assignment_remove.mutation.graphql';

export default {
  name: 'CodeSuggestionsAddonAssignment',
  i18n: {
    toggleLabel: __('Code Suggestions add-on status'),
  },
  components: {
    GlToggle,
  },
  props: {
    userId: {
      type: String,
      required: true,
    },
    addOnAssignments: {
      type: Array,
      required: false,
      default: () => [],
    },
    addOnPurchaseId: {
      type: String,
      required: true,
    },
    addOnEligibleUsersQueryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      toggleId: `toggle-${this.userId}`,
    };
  },
  computed: {
    isAssigned() {
      return Boolean(
        this.addOnAssignments?.find(
          (assignment) => assignment.addOnPurchase?.name === ADD_ON_CODE_SUGGESTIONS,
        ),
      );
    },
    addOnAssignmentQueryVariables() {
      return {
        userId: this.userId,
        addOnPurchaseId: this.addOnPurchaseId,
      };
    },
  },
  methods: {
    async onToggle() {
      this.isLoading = true;
      this.$emit('clearAddOnAssignmentError');

      try {
        const response = this.isAssigned ? await this.unassignAddOn() : await this.assignAddOn();

        // Null response here means it didn't error but we're trying unassign an already unassigned user
        // https://gitlab.com/gitlab-org/gitlab/-/issues/426175 should take care of returning a response
        // instead of null value similar to how assignment mutation works when assigning an already assigned user
        if (!response) {
          return;
        }

        const errors = response.errors || [];
        if (errors.length) {
          this.handleError(errors[0]);
        }
      } catch (e) {
        this.handleError(e);
        Sentry.captureException(e);
      } finally {
        this.isLoading = false;
      }
    },
    handleError(error) {
      let errorCode = error;
      if (!this.isKnownErrorCode(error)) {
        errorCode = this.isAssigned
          ? CANNOT_UNASSIGN_ADDON_ERROR_CODE
          : CANNOT_ASSIGN_ADDON_ERROR_CODE;
      }
      this.$emit('handleAddOnAssignmentError', errorCode);
    },
    async assignAddOn() {
      const {
        data: { userAddOnAssignmentCreate },
      } = await this.$apollo.mutate({
        mutation: userAddOnAssignmentCreateMutation,
        variables: this.addOnAssignmentQueryVariables,
        update: (store, { data: { userAddOnAssignmentCreate: response } }) => {
          this.updateStore(store, response);
        },
      });
      return userAddOnAssignmentCreate;
    },
    async unassignAddOn() {
      const {
        data: { userAddOnAssignmentRemove },
      } = await this.$apollo.mutate({
        mutation: userAddOnAssignmentRemoveMutation,
        variables: this.addOnAssignmentQueryVariables,
        update: (store, { data: { userAddOnAssignmentRemove: response } }) => {
          this.updateStore(store, response);
        },
      });
      return userAddOnAssignmentRemove;
    },
    updateStore(store, updatedAssignment) {
      if (!updatedAssignment || updatedAssignment.errors?.length) {
        return;
      }

      store.updateQuery(
        { query: getAddOnEligibleUsers, variables: this.addOnEligibleUsersQueryVariables },
        (sourceData) =>
          produce(sourceData, (draftData) => {
            if (updatedAssignment?.user) {
              draftData.namespace.addOnEligibleUsers.edges.find(
                (edge) => edge.node.id === this.userId,
              ).node.addOnAssignments.nodes = updatedAssignment.user.addOnAssignments.nodes;
            }
          }),
      );
    },
    isKnownErrorCode(errorCode) {
      if (errorCode instanceof String || typeof errorCode === 'string') {
        return Object.keys(ADD_ON_ERROR_DICTIONARY).includes(errorCode.toLowerCase());
      }

      return false;
    },
  },
};
</script>
<template>
  <div>
    <gl-toggle
      :id="toggleId"
      :value="isAssigned"
      :label="$options.i18n.toggleLabel"
      :is-loading="isLoading"
      class="gl-display-inline-block gl-vertical-align-middle"
      label-position="hidden"
      @change="onToggle"
    />
  </div>
</template>
