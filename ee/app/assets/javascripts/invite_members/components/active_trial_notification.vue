<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';

import {
  TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_TITLE,
  TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_BODY,
} from '../constants';

export default {
  name: 'EEActiveTrialNotification',
  components: { GlAlert, GlSprintf, GlLink },
  inject: ['name'],
  props: {
    activeTrialDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    showActiveTrialUnlimitedUsersNotification() {
      return !isEmpty(this.activeTrialDataset);
    },
  },
  i18n: {
    TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_TITLE,
    TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_BODY,
  },
};
</script>

<template>
  <gl-alert
    v-if="showActiveTrialUnlimitedUsersNotification"
    class="gl-mb-4"
    :dismissible="false"
    :title="$options.i18n.TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_TITLE"
  >
    <gl-sprintf :message="$options.i18n.TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_BODY">
      <template #groupName>{{ name }}</template>

      <template #dashboardLimit>{{ activeTrialDataset.freeUsersLimit }}</template>

      <template #link="{ content }">
        <gl-link :href="activeTrialDataset.purchasePath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
