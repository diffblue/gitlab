<script>
import { GlIcon, GlLoadingIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { createAlert } from '~/alert';
import { STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { s__, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import Tracking from '~/tracking';
import {
  HEALTH_STATUS_I18N_FETCH_ERROR,
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NONE,
  HEALTH_STATUS_I18N_UPDATE_ERROR,
  HEALTH_STATUS_OPEN_DROPDOWN_DELAY,
  healthStatusQueries,
  healthStatusTextMap,
  healthStatusTracking,
} from '../../constants';
import HealthStatusDropdown from './health_status_dropdown.vue';

export default {
  HEALTH_STATUS_I18N_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NONE,
  HEALTH_STATUS_I18N_UPDATE_ERROR,
  healthStatusTracking,
  components: {
    GlIcon,
    GlLoadingIcon,
    HealthStatusDropdown,
    SidebarEditableItem,
    IssueHealthStatus,
  },
  directives: {
    GlTooltip,
  },
  mixins: [Tracking.mixin()],
  inject: ['canUpdate'],
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      isUpdating: false,
    };
  },
  apollo: {
    issuable: {
      query() {
        return healthStatusQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update: (data) => data.workspace?.issuable,
      error(error) {
        createAlert({
          message: sprintf(HEALTH_STATUS_I18N_FETCH_ERROR, { issuableType: this.issuableType }),
        });
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    canEdit() {
      return this.canUpdate && this.isOpen;
    },
    healthStatus() {
      return this.issuable?.healthStatus;
    },
    healthStatusText() {
      return this.healthStatus ? healthStatusTextMap[this.healthStatus] : HEALTH_STATUS_I18N_NONE;
    },
    healthStatusTooltip() {
      const tooltipText = s__('Sidebar|Health status');
      return this.healthStatus ? `${tooltipText}: ${this.healthStatusText}` : tooltipText;
    },
    isLoading() {
      return this.$apollo.queries.issuable.loading || this.isUpdating;
    },
    isOpen() {
      return this.issuable?.state === STATUS_OPEN || this.issuable?.state === STATUS_REOPENED;
    },
  },
  methods: {
    expandSidebar() {
      // Wait for the open sidebar animation to finish before opening the
      // health status dropdown, otherwise the dropdown is misaligned.
      setTimeout(this.$refs.editable.expand, HEALTH_STATUS_OPEN_DROPDOWN_DELAY);
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    updateHealthStatus(healthStatus) {
      this.$refs.editable.collapse();
      if (healthStatus === undefined || healthStatus === this.healthStatus) {
        return;
      }

      this.track('change_health_status', { property: healthStatus });
      this.isUpdating = true;

      this.$apollo
        .mutate({
          mutation: healthStatusQueries[this.issuableType].mutation,
          variables: {
            healthStatus,
            iid: this.iid,
            projectPath: this.fullPath,
          },
        })
        .then(({ data }) => {
          if (data.updateIssue.errors.length) {
            throw new Error(data.updateIssue.errors.join('\n'));
          } else {
            this.$emit('statusUpdated', healthStatus);
          }
        })
        .catch((error) => {
          createAlert({
            message: sprintf(HEALTH_STATUS_I18N_UPDATE_ERROR, { issuableType: this.issuableType }),
          });
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    class="block health-status"
    :can-edit="canEdit"
    :loading="isLoading"
    :title="$options.HEALTH_STATUS_I18N_HEALTH_STATUS"
    :tracking="$options.healthStatusTracking"
    @close="updateHealthStatus"
    @open="showDropdown"
  >
    <template #collapsed>
      <div
        v-gl-tooltip.left.viewport.title="healthStatusTooltip"
        class="sidebar-collapsed-icon"
        @click="expandSidebar"
      >
        <gl-icon name="status-health" />
        <gl-loading-icon v-if="isLoading" />
        <p v-else class="collapse-truncated-title gl-font-sm gl-pt-2 gl-px-3">
          {{ healthStatusText }}
        </p>
      </div>
      <div class="hide-collapsed" :class="{ 'gl-text-secondary': !healthStatus }">
        <issue-health-status v-if="healthStatus" :health-status="healthStatus" />
        <span v-else>{{ $options.HEALTH_STATUS_I18N_NONE }}</span>
      </div>
    </template>
    <template #default>
      <health-status-dropdown
        ref="dropdown"
        :health-status="healthStatus"
        @change="updateHealthStatus"
      />
    </template>
  </sidebar-editable-item>
</template>
