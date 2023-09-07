<script>
import { createAlert, VARIANT_INFO } from '~/alert';
import { updateApplicationSettings } from '~/rest_api';
import { SUCCESS_MESSAGE, SAVE_ERROR_MESSAGE } from '../constants';
import SettingsForm from './settings_form.vue';

export default {
  name: 'SettingsFormContainer',
  components: {
    SettingsForm,
  },
  i18n: {
    SUCCESS_MESSAGE,
    SAVE_ERROR_MESSAGE,
  },
  props: {
    maxDownloads: {
      type: Number,
      required: false,
      default: 0,
    },
    timePeriod: {
      type: Number,
      required: false,
      default: 0,
    },
    allowlist: {
      type: Array,
      required: false,
      default: () => [],
    },
    alertlist: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoBanUsers: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data: () => ({ isLoading: false }),
  methods: {
    async updateSettings({ maxDownloads, timePeriod, allowlist, alertlist, autoBanUsers }) {
      try {
        this.isLoading = true;

        await updateApplicationSettings({
          max_number_of_repository_downloads: maxDownloads,
          max_number_of_repository_downloads_within_time_period: timePeriod,
          git_rate_limit_users_allowlist: allowlist,
          git_rate_limit_users_alertlist: alertlist,
          auto_ban_user_on_excessive_projects_download: autoBanUsers,
        });

        createAlert({
          message: SUCCESS_MESSAGE,
          variant: VARIANT_INFO,
        });
      } catch (error) {
        createAlert({
          message: SAVE_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
<template>
  <settings-form
    :is-loading="isLoading"
    :max-downloads="maxDownloads"
    :time-period="timePeriod"
    :allowlist="allowlist"
    :alertlist="alertlist"
    :auto-ban-users="autoBanUsers"
    scope="application"
    @submit="updateSettings"
  />
</template>
