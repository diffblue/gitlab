<script>
import createFlash from '~/flash';
import Api from 'ee/api';
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
  },
  data: () => ({ isLoading: false }),
  methods: {
    async updateSettings({ maxDownloads, timePeriod, allowlist }) {
      try {
        this.isLoading = true;

        await Api.updateApplicationSettings({
          max_number_of_repository_downloads: maxDownloads,
          max_number_of_repository_downloads_within_time_period: timePeriod,
          git_rate_limit_users_allowlist: allowlist,
        });

        createFlash({
          message: SUCCESS_MESSAGE,
          type: 'notice',
        });
      } catch (error) {
        createFlash({
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
    @submit="updateSettings"
  />
</template>
