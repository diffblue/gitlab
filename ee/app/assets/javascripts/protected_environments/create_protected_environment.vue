<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlCollapse,
  GlCollapsibleListbox,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import AddApprovers from './add_approvers.vue';
import { ACCESS_LEVELS } from './constants';

export default {
  ACCESS_LEVELS,
  components: {
    GlAlert,
    GlButton,
    GlCollapse,
    GlForm,
    GlFormGroup,
    GlCollapsibleListbox,
    AccessDropdown,
    AddApprovers,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    accessLevelsData: { default: [] },
    apiLink: {},
    docsLink: {},
    projectId: { default: '' },
    searchUnprotectedEnvironmentsUrl: { default: '' },
  },
  data() {
    return {
      approvals: '0',
      deployers: [],
      approvers: [],
      disabled: false,
      environment: '',
      environments: [],
      environmentsLoading: false,
      errorMessage: '',
      loading: false,
    };
  },
  computed: {
    isFormInvalid() {
      return !this.deployers.length || !this.hasSelectedEnvironment;
    },
    environmentText() {
      return this.environment || this.$options.i18n.environmentText;
    },
    hasSelectedEnvironment() {
      return Boolean(this.environment);
    },
  },
  methods: {
    updateDeployers(permissions) {
      this.deployers = permissions;
    },
    updateApprovers(permissions) {
      this.approvers = permissions;
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
      this.loading = true;

      const protectedEnvironment = {
        name: this.environment,
        deploy_access_levels: this.deployers,
        approval_rules: this.approvers,
      };
      Api.createProtectedEnvironment(this.projectId, protectedEnvironment)
        .then(() => {
          this.$emit('success');
          this.deployers = [];
          this.approvers = [];
          this.environment = '';
        })
        .catch((error) => {
          Sentry.captureException(error);
          this.errorMessage = __('Failed to protect the environment');
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
  i18n: {
    header: s__('ProtectedEnvironment|Protect an environment'),
    addText: s__('ProtectedEnvironment|Add new protected environment'),
    environmentLabel: s__('ProtectedEnvironment|Select environment'),
    environmentText: s__('ProtectedEnvironment|Select an environment'),
    approvalLabel: s__('ProtectedEnvironment|Required approvals'),
    deployerLabel: s__('ProtectedEnvironments|Allowed to deploy'),
    deployerHelp: s__(
      'ProtectedEnvironments|Set which groups, access levels or users that are allowed to deploy to this environment',
    ),
    buttonText: s__('ProtectedEnvironment|Protect'),
    buttonTextCancel: __('Cancel'),
  },
};
</script>
<template>
  <gl-form class="gl-new-card-add-form gl-m-4" @submit.prevent="submitForm">
    <div data-testid="new-protected-environment">
      <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-5" @dismiss="errorMessage = ''">
        {{ errorMessage }}
      </gl-alert>

      <h4 class="gl-mt-0">{{ $options.i18n.addText }}</h4>

      <gl-form-group
        label-for="environment"
        data-testid="create-environment"
        :label="$options.i18n.environmentLabel"
      >
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

      <gl-collapse :visible="hasSelectedEnvironment">
        <gl-form-group
          data-testid="create-deployer-dropdown"
          label-for="create-deployer-dropdown"
          :label="$options.i18n.deployerLabel"
        >
          <template #label-description>
            {{ $options.i18n.deployerHelp }}
          </template>
          <access-dropdown
            id="create-deployer-dropdown"
            :access-levels-data="accessLevelsData"
            :access-level="$options.ACCESS_LEVELS.DEPLOY"
            :disabled="disabled"
            :items="deployers"
            @select="updateDeployers"
          />
        </gl-form-group>
        <add-approvers
          :project-id="projectId"
          :approval-rules="approvers"
          @change="updateApprovers"
          @error="errorMessage = $event"
        />
      </gl-collapse>

      <div class="gl-display-flex gl-mt-5">
        <gl-button
          type="submit"
          category="primary"
          variant="confirm"
          :loading="loading"
          :disabled="isFormInvalid"
          class="js-no-auto-disable gl-mr-3"
        >
          {{ $options.i18n.buttonText }}
        </gl-button>
        <gl-button
          type="button"
          category="secondary"
          variant="default"
          data-testid="cancel-button"
          @click="$emit('cancel')"
        >
          {{ $options.i18n.buttonTextCancel }}
        </gl-button>
      </div>
    </div>
  </gl-form>
</template>
