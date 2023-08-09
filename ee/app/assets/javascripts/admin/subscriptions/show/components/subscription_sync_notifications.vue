<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';

export const i18n = Object.freeze({
  CONNECTIVITY_ERROR_TITLE: s__('SuperSonics|There is a connectivity issue'),
  MANUAL_SYNC_SUCCESS_TEXT: s__(
    'SuperSonics|Subscription detail synchronization has started and will complete soon.',
  ),
  MANUAL_SYNC_SUCCESS_TITLE: s__('SuperSonics|Synchronization started'),
  MANUAL_SYNC_FAILURE_TEXT: s__(
    'SuperSonics|Subscription details did not synchronize due to a possible connectivity issue with GitLab servers. %{connectivityHelpLinkStart}How do I check connectivity%{connectivityHelpLinkEnd}?',
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
    ...mapGetters(['didSyncFail', 'didSyncSucceed']),
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
      v-if="didSyncSucceed"
      variant="info"
      :title="$options.i18n.MANUAL_SYNC_SUCCESS_TITLE"
      data-testid="sync-success-alert"
      @dismiss="dismissAlert"
      >{{ $options.i18n.MANUAL_SYNC_SUCCESS_TEXT }}</gl-alert
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
