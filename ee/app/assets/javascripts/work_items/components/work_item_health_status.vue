<script>
import { GlDropdown, GlDropdownItem, GlFormGroup, GlBadge } from '@gitlab/ui';

import * as Sentry from '@sentry/browser';
import workItemHealthStatusSubscription from 'ee/work_items/graphql/work_item_health_status.subscription.graphql';
import { s__ } from '~/locale';
import {
  HEALTH_STATUS_I18N_NONE,
  HEALTH_STATUS_I18N_NO_STATUS,
  healthStatusDropdownOptions,
  healthStatusTextMap,
} from 'ee/sidebar/constants';
import { issueHealthStatusVariantMapping } from 'ee/related_items_tree/constants';
import {
  i18n,
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import Tracking from '~/tracking';

export default {
  HEALTH_STATUS_I18N_NO_STATUS,
  healthStatusDropdownOptions,
  i18n: {
    HEALTH_STATUS: s__('WorkItem|Health status'),
  },
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlBadge,
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
    healthStatusText() {
      if (this.healthStatus === null) {
        return HEALTH_STATUS_I18N_NONE;
      }
      return healthStatusTextMap[this.healthStatus];
    },
    healthStatusVariant() {
      if (this.healthStatus === null) {
        return null;
      }

      return issueHealthStatusVariantMapping[this.healthStatus];
    },
    dropdownToggleClasses() {
      return {
        'is-not-focused': !this.isFocused,
      };
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItems.nodes[0];
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      subscribeToMore: {
        document: workItemHealthStatusSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
      },
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
        });
    },
  },
};
</script>

<template>
  <gl-form-group
    v-if="hasIssuableHealthStatusFeature"
    class="work-item-dropdown"
    :label="$options.i18n.HEALTH_STATUS"
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break gl-display-flex gl-align-items-center"
    label-cols="3"
    label-cols-lg="2"
  >
    <div v-if="!canUpdate" class="gl-ml-4 gl-mt-3">
      <gl-badge v-if="healthStatus" :variant="healthStatusVariant">
        {{ healthStatusText }}
      </gl-badge>
      <span v-else class="gl-text-secondary gl-display-inline-block gl-py-2">{{
        healthStatusText
      }}</span>
    </div>
    <gl-dropdown
      v-else
      :disabled="!canUpdate"
      :text="healthStatusText"
      class="gl-mt-3"
      data-testid="work-item-health-status-dropdown"
      :toggle-class="dropdownToggleClasses"
      @shown="onDropdownShown"
      @hide="onDropdownHide"
      @change="updateHealthStatus"
    >
      <template #button-text>
        <gl-badge v-if="healthStatus" :variant="healthStatusVariant">
          {{ healthStatusText }}
        </gl-badge>
        <span v-else class="gl-text-secondary gl-display-inline-block gl-py-2">{{
          healthStatusText
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
