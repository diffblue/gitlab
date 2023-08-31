<script>
import { GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import {
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_NONE,
  healthStatusDropdownOptions,
} from 'ee/sidebar/constants';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import Tracking from '~/tracking';

export default {
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_NONE,
  healthStatusDropdownOptions,
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    IssueHealthStatus,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath', 'hasIssuableHealthStatusFeature'],
  props: {
    healthStatus: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isFocused: false,
      isLoading: false,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_health_status',
        property: `type_${this.workItemType}`,
      };
    },
    dropdownToggleClasses() {
      return {
        'is-not-focused': !this.isFocused,
      };
    },
  },
  methods: {
    isSelected(healthStatus) {
      return this.healthStatus === healthStatus;
    },
    onDropdownShown() {
      this.isFocused = true;
    },
    onDropdownHide() {
      this.isFocused = false;
    },
    updateHealthStatus(healthStatus) {
      if (!this.canUpdate) {
        return;
      }

      this.track('updated_health_status');

      this.isLoading = true;

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              healthStatusWidget: {
                healthStatus,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
        })
        .catch((error) => {
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-form-group
    v-if="hasIssuableHealthStatusFeature"
    class="work-item-dropdown"
    :label="$options.HEALTH_STATUS_I18N_HEALTH_STATUS"
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break gl-display-flex gl-align-items-center work-item-field-label"
    label-cols="3"
    label-cols-lg="2"
  >
    <div v-if="!canUpdate" class="gl-ml-4 gl-mt-3 work-item-field-value">
      <issue-health-status v-if="healthStatus" :health-status="healthStatus" />
      <span v-else class="gl-text-secondary gl-display-inline-block">{{
        $options.HEALTH_STATUS_I18N_NONE
      }}</span>
    </div>
    <gl-dropdown
      v-else
      :disabled="!canUpdate"
      class="gl-mt-3 work-item-field-value"
      data-testid="work-item-health-status-dropdown"
      :loading="isLoading"
      :toggle-class="dropdownToggleClasses"
      @shown="onDropdownShown"
      @hide="onDropdownHide"
      @change="updateHealthStatus"
    >
      <template #button-text>
        <issue-health-status v-if="healthStatus" :health-status="healthStatus" />
        <span v-else class="gl-text-secondary gl-display-inline-block work-item-field-value">{{
          $options.HEALTH_STATUS_I18N_NONE
        }}</span>
      </template>
      <gl-dropdown-item
        is-check-item
        :is-checked="isSelected(null)"
        @click="updateHealthStatus(null)"
      >
        {{ $options.HEALTH_STATUS_I18N_NO_STATUS }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-for="option in $options.healthStatusDropdownOptions"
        :key="option.value"
        is-check-item
        :is-checked="isSelected(option.value)"
        @click="updateHealthStatus(option.value)"
      >
        {{ option.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
