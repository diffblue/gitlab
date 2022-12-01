<script>
import { GlAlert, GlButton, GlCard, GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from './constants';

export default {
  ACCESS_LEVELS,
  accessLevelsData: gon?.deploy_access_levels?.roles ?? [],
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlFormGroup,
    GlCollapsibleListbox,
    AccessDropdown,
  },
  props: {
    searchUnprotectedEnvironmentsUrl: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      approvals: '0',
      selected: [],
      disabled: false,
      environment: '',
      environments: [],
      environmentsLoading: false,
      errorMessage: '',
    };
  },
  computed: {
    isFormInvalid() {
      return !this.selected.length || !this.environment;
    },
    environmentText() {
      return this.environment || this.$options.i18n.environmentText;
    },
  },
  methods: {
    updatePermissions(permissions) {
      this.selected = permissions;
    },
    fetchEnvironments() {
      this.getProtectedEnvironments();
    },
    getProtectedEnvironments(query = '') {
      this.environmentsLoading = true;
      this.errorMessage = '';
      return axios
        .get(this.searchUnprotectedEnvironmentsUrl, { params: { query } })
        .then(({ data }) => {
          const environments = [].concat(data);
          this.environments = environments.map((environment) => ({
            value: environment,
            text: environment,
          }));
        })
        .catch((error) => {
          Sentry.captureException(error);
          this.environments = [];
          this.errorMessage = __('An error occurred while fetching environments.');
        })
        .finally(() => {
          this.environmentsLoading = false;
        });
    },
    submitForm() {
      this.errorMessage = '';

      const protectedEnvironment = {
        name: this.environment,
        required_approval_count: this.approvals,
        deploy_access_levels: this.selected,
      };

      Api.createProtectedEnvironment(this.projectId, protectedEnvironment)
        .then(() => {
          window.location.reload();
        })
        .catch((error) => {
          Sentry.captureException(error);
          this.errorMessage = __('Failed to protect the environment');
        });
    },
  },
  i18n: {
    header: s__('ProtectedEnvironment|Protect an environment'),
    environmentLabel: s__('ProtectedEnvironment|Environment'),
    environmentText: s__('ProtectedEnvironment|Select an environment'),
    approvalLabel: s__('ProtectedEnvironment|Required approvals'),
    allowedLabel: s__('ProtectedEnvironment|Allowed to deploy'),
    buttonText: s__('ProtectedEnvironment|Protect'),
  },
  APPROVAL_COUNT_OPTIONS: ['0', '1', '2', '3', '4', '5'].map((value) => ({ value, text: value })),
};
</script>
<template>
  <gl-card data-testid="new-protected-environment">
    <template #header>
      {{ $options.i18n.header }}
    </template>
    <template #default>
      <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-5" @dismiss="errorMessage = ''">
        {{ errorMessage }}
      </gl-alert>
      <gl-form-group label-for="environment" :label="$options.i18n.environmentLabel">
        <gl-collapsible-listbox
          id="create-environment"
          v-model="environment"
          :toggle-text="environmentText"
          :items="environments"
          :searching="environmentsLoading"
          searchable
          @shown="fetchEnvironments"
          @search="getProtectedEnvironments"
        />
      </gl-form-group>
      <gl-form-group label-for="create-access-dropdown" :label="$options.i18n.allowedLabel">
        <access-dropdown
          id="create-access-dropdown"
          :access-levels-data="$options.accessLevelsData"
          :access-level="$options.ACCESS_LEVELS.DEPLOY"
          :disabled="disabled"
          @hidden="updatePermissions"
        />
      </gl-form-group>
      <gl-form-group label-for="create-approval-count" :label="$options.i18n.approvalLabel">
        <gl-collapsible-listbox
          id="create-approval-count"
          v-model="approvals"
          :toggle-text="approvals"
          :items="$options.APPROVAL_COUNT_OPTIONS"
        />
      </gl-form-group>
    </template>
    <template #footer>
      <gl-button category="primary" variant="confirm" :disabled="isFormInvalid" @click="submitForm">
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-card>
</template>
