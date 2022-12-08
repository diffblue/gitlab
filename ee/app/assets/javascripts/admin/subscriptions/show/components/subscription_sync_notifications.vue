<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';

export const i18n = Object.freeze({
  CONNECTIVITY_ERROR_TITLE: s__('SuperSonics|There is a connectivity issue.'),
  MANUAL_SYNC_PENDING_TEXT: s__('SuperSonics|Your subscription details will sync shortly.'),
  MANUAL_SYNC_PENDING_TITLE: s__('SuperSonics|Sync subscription request.'),
  MANUAL_SYNC_FAILURE_TEXT: s__(
    'SuperSonics|You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by %{connectivityHelpLinkStart}troubleshooting the activation code%{connectivityHelpLinkEnd}.',
  ),
});

export default {
  name: 'SubscriptionSyncNotifications',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['connectivityHelpURL'],
  computed: {
    ...mapGetters(['didSyncFail', 'isSyncPending']),
  },
  methods: {
    ...mapActions(['dismissAlert']),
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
      @dismiss="dismissAlert"
      >{{ $options.i18n.MANUAL_SYNC_PENDING_TEXT }}</gl-alert
    >
    <gl-alert
      v-else-if="didSyncFail"
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
