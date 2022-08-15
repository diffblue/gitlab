<script>
import createFlash from '~/flash';
import { updateGroupSettings } from 'ee/api/groups_api';
import SettingsForm from 'ee_component/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';
import {
  SUCCESS_MESSAGE,
  SAVE_ERROR_MESSAGE,
} from 'ee_component/admin/application_settings/reporting/git_abuse_settings/constants';

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
    groupFullPath: {
      type: String,
      required: true,
    },
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

        await updateGroupSettings(this.groupFullPath, {
          unique_project_download_limit: maxDownloads,
          unique_project_download_limit_interval_in_seconds: timePeriod,
          unique_project_download_limit_allowlist: allowlist,
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
