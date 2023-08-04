<script>
import { GlToggle, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/seats/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import userAddOnAssignmentCreateMutation from 'ee/usage_quotas/graphql/queries/user_addon_assignment_create.mutation.graphql';
import userAddOnAssignmentRemoveMutation from 'ee/usage_quotas/graphql/queries/user_addon_assignment_remove.mutation.graphql';

export default {
  name: 'CodeSuggestionsAddonAssignment',
  i18n: {
    toggleLabel: __('Code Suggestions add-on status'),
    addOnUnavailableTooltipText: __('The Code Suggestions add-on is not available.'),
  },
  components: {
    GlToggle,
    GlTooltip,
  },
  props: {
    userId: {
      type: Number,
      required: true,
    },
    addOns: {
      type: Object,
      required: false,
      default: () => {},
    },
    addOnPurchaseId: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      isLoading: false,
      isAssigned: Boolean(
        this.addOns?.assigned?.find((assigned) => assigned.name === ADD_ON_CODE_SUGGESTIONS),
      ),
      toggleId: `toggle-${this.userId}`,
    };
  },
  computed: {
    isAssignable() {
      return Boolean(
        this.addOns?.assignable?.find((assignable) => assignable.name === ADD_ON_CODE_SUGGESTIONS),
      );
    },
    globalUserId() {
      return convertToGraphQLId(TYPENAME_USER, this.userId);
    },
    addOnAssignmentQueryVariables() {
      return {
        input: {
          userId: this.globalUserId,
          addOnPurchaseId: this.addOnPurchaseId,
        },
      };
    },
  },
  methods: {
    async onToggle() {
      this.isLoading = true;

      try {
        const { errors } = this.isAssigned ? await this.unassignAddOn() : await this.assignAddOn();
        if (errors.length) {
          // Will be handled in a follow-up MR
        } else {
          this.isAssigned = !this.isAssigned;
        }
      } catch (error) {
        // Will be handled in a follow-up MR
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
      :disabled="!isAssignable"
      label-position="hidden"
      @change="onToggle"
    />
    <gl-tooltip v-if="!isAssignable" :target="toggleId">
      {{ $options.i18n.addOnUnavailableTooltipText }}
    </gl-tooltip>
  </div>
</template>
