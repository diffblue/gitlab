<script>
import { GlToggle } from '@gitlab/ui';
import { __ } from '~/locale';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import {
  CANNOT_ASSIGN_ADDON_ERROR_CODE,
  CANNOT_UNASSIGN_ADDON_ERROR_CODE,
  ADD_ON_ERROR_DICTIONARY,
} from 'ee/usage_quotas/error_constants';
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
  },
  data() {
    return {
      isLoading: false,
      isAssigned: Boolean(
        this.addOnAssignments?.find(
          (assignment) => assignment.addOnPurchase?.name === ADD_ON_CODE_SUGGESTIONS,
        ),
      ),
      toggleId: `toggle-${this.userId}`,
    };
  },
  computed: {
    addOnAssignmentQueryVariables() {
      return {
        input: {
          userId: this.userId,
          addOnPurchaseId: this.addOnPurchaseId,
        },
      };
    },
  },
  methods: {
    async onToggle() {
      this.isLoading = true;
      this.$emit('clearAddOnAssignmentError');

      try {
        const { errors } = this.isAssigned ? await this.unassignAddOn() : await this.assignAddOn();
        if (errors.length) {
          const errorCode = errors[0];
          if (!this.isKnownErrorCode(errorCode)) {
            throw errors;
          }
          this.$emit('handleAddOnAssignmentError', errorCode);
        } else {
          this.isAssigned = !this.isAssigned;
        }
      } catch (e) {
        const error = this.isAssigned
          ? CANNOT_UNASSIGN_ADDON_ERROR_CODE
          : CANNOT_ASSIGN_ADDON_ERROR_CODE;
        this.$emit('handleAddOnAssignmentError', error);
      } finally {
        this.isLoading = false;
      }
    },
    async assignAddOn() {
      const {
        data: { userAddOnAssignmentCreate },
      } = await this.$apollo.mutate({
        mutation: userAddOnAssignmentCreateMutation,
        variables: this.addOnAssignmentQueryVariables,
      });
      return userAddOnAssignmentCreate;
    },
    async unassignAddOn() {
      const {
        data: { userAddOnAssignmentRemove },
      } = await this.$apollo.mutate({
        mutation: userAddOnAssignmentRemoveMutation,
        variables: this.addOnAssignmentQueryVariables,
      });
      return userAddOnAssignmentRemove;
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
