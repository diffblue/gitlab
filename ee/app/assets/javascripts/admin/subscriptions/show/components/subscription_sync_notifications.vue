<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { subscriptionSyncStatus } from '../constants';

export const INFO_ALERT_DISMISSED_EVENT = 'info-alert-dismissed';

export const i18n = Object.freeze({
  CONNECTIVITY_ERROR_TITLE: s__('SuperSonics|There is a connectivity issue.'),
  MANUAL_SYNC_PENDING_TEXT: s__('SuperSonics|Your subscription details will sync shortly.'),
  MANUAL_SYNC_PENDING_TITLE: s__('SuperSonics|Sync subscription request.'),
  MANUAL_SYNC_FAILURE_TEXT: s__(
    'SuperSonics|You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by %{connectivityHelpLinkStart}troubleshooting the activation code%{connectivityHelpLinkEnd}.',
  ),
});

const subscriptionSyncStatusValidator = (value) =>
  !value || Object.values(subscriptionSyncStatus).includes(value);

export default {
  name: 'SubscriptionSyncNotifications',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['connectivityHelpURL'],
  props: {
    syncStatus: {
      type: String,
      required: true,
      validator: subscriptionSyncStatusValidator,
    },
  },
  computed: {
    isSyncPending() {
      return this.syncStatus === subscriptionSyncStatus.SYNC_PENDING;
    },
    syncDidFail() {
      return this.syncStatus === subscriptionSyncStatus.SYNC_FAILURE;
    },
  },
  methods: {
    didDismissInfoAlert() {
      this.$emit(INFO_ALERT_DISMISSED_EVENT);
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="isSyncPending"
      variant="info"
      :title="$options.i18n.MANUAL_SYNC_PENDING_TITLE"
      data-testid="sync-info-alert"
      @dismiss="didDismissInfoAlert"
      >{{ $options.i18n.MANUAL_SYNC_PENDING_TEXT }}</gl-alert
    >
    <gl-alert
      v-else-if="syncDidFail"
      variant="danger"
      :dismissible="false"
      :title="$options.i18n.CONNECTIVITY_ERROR_TITLE"
      data-testid="sync-failure-alert"
    >
      <gl-sprintf :message="$options.i18n.MANUAL_SYNC_FAILURE_TEXT">
        <template #connectivityHelpLink="{ content }">
          <gl-link :href="connectivityHelpURL" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
