<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlFormGroup,
  GlCollapse,
  GlCollapsibleListbox,
  GlLink,
  GlSprintf,
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
    GlCard,
    GlCollapse,
    GlFormGroup,
    GlCollapsibleListbox,
    GlLink,
    GlSprintf,
    AccessDropdown,
    AddApprovers,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: { accessLevelsData: { default: [] }, apiLink: {}, docsLink: {} },
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
      deployers: [],
      approvers: [],
      disabled: false,
      environment: '',
      environments: [],
      environmentsLoading: false,
      errorMessage: '',
      alertDismissed: false,
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

      const protectedEnvironment = {
        name: this.environment,
        deploy_access_levels: this.deployers,
        approval_rules: this.approvers,
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
    unifiedRulesAlertHeader: s__(
      'ProtectedEnvironments|Unified approval rules have been removed from the settings UI',
    ),
    unifiedRulesAlertText: s__(
      'ProtectedEnvironments|You can still use the %{apiLinkStart}API%{apiLinkEnd} to configure unified approval rules. Consider using %{docsLinkStart}multiple approval rules%{docsLinkEnd} instead, because they provide greater flexibility.',
    ),
    header: s__('ProtectedEnvironment|Protect an environment'),
    environmentLabel: s__('ProtectedEnvironment|Select environment'),
    environmentText: s__('ProtectedEnvironment|Select an environment'),
    approvalLabel: s__('ProtectedEnvironment|Required approvals'),
    deployerLabel: s__('ProtectedEnvironments|Allowed to deploy'),
    deployerHelp: s__(
      'ProtectedEnvironments|Set which groups, access levels or users that are allowed to deploy to this environment',
    ),
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
      <gl-alert
        v-if="!alertDismissed"
        :title="$options.i18n.unifiedRulesAlertHeader"
        class="gl-mb-5"
        @dismiss="alertDismissed = false"
      >
        <p>
          <gl-sprintf :message="$options.i18n.unifiedRulesAlertText">
            <template #apiLink="{ content }">
              <gl-link :href="apiLink">{{ content }}</gl-link>
            </template>
            <template #docsLink="{ content }">
              <gl-link :href="docsLink">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-alert>
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
            :preselected-items="deployers"
            @hidden="updateDeployers"
          />
        </gl-form-group>
        <add-approvers
          :project-id="projectId"
          @change="updateApprovers"
          @error="errorMessage = $event"
        />
      </gl-collapse>
    </template>
    <template #footer>
      <gl-button category="primary" variant="confirm" :disabled="isFormInvalid" @click="submitForm">
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-card>
</template>
