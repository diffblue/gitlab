<script>
import { createAlert, VARIANT_INFO } from '~/alert';
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

        await updateGroupSettings(this.groupFullPath, {
          unique_project_download_limit: maxDownloads,
          unique_project_download_limit_interval_in_seconds: timePeriod,
          unique_project_download_limit_allowlist: allowlist,
          unique_project_download_limit_alertlist: alertlist,
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
    scope="namespace"
    @submit="updateSettings"
  />
</template>
