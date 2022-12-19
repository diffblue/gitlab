<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlFormGroup,
  GlCollapse,
  GlCollapsibleListbox,
  GlAvatar,
  GlLink,
  GlFormInput,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api from 'ee/api';
import { getUser } from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from './constants';

const mapUserToApprover = (user) => ({
  name: user.name,
  entityName: user.name,
  webUrl: user.web_url,
  avatarUrl: user.avatar_url,
  id: user.id,
  avatarShape: 'circle',
  approvals: 1,
  inputDisabled: true,
  type: 'user',
});

const mapGroupToApprover = (group) => ({
  name: group.full_name,
  entityName: group.name,
  webUrl: group.web_url,
  avatarUrl: group.avatar_url,
  id: group.id,
  avatarShape: 'rect',
  approvals: 1,
  type: 'group',
});

const MIN_APPROVALS_COUNT = 1;

const MAX_APPROVALS_COUNT = 5;

export default {
  ACCESS_LEVELS,
  components: {
    GlAlert,
    GlAvatar,
    GlButton,
    GlCard,
    GlCollapse,
    GlFormGroup,
    GlCollapsibleListbox,
    GlLink,
    GlFormInput,
    AccessDropdown,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: { accessLevelsData: { default: [] } },
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
      approverInfo: [],
    };
  },
  computed: {
    isFormInvalid() {
      return !this.deployers.length || !this.hasSelectedEnvironment;
    },
    environmentText() {
      return this.environment || this.$options.i18n.environmentText;
    },
    canCreateMultipleRules() {
      return this.glFeatures.multipleEnvironmentApprovalRulesFe;
    },
    hasSelectedEnvironment() {
      return Boolean(this.environment);
    },
    hasSelectedApprovers() {
      return Boolean(this.approvers.length);
    },
    approvalRules() {
      return this.approverInfo.map((info) => {
        switch (info.type) {
          case 'user':
            return { user_id: info.id, required_approvals: info.approvals };
          case 'group':
            return { group_id: info.id, required_approvals: info.approvals };
          case 'access':
            return { access_level: info.accessLevel, required_approvals: info.approvals };
          default:
            return {};
        }
      });
    },
  },
  watch: {
    async approvers() {
      try {
        this.errorMessage = '';
        this.approverInfo = await Promise.all(
          this.approvers.map((approver) => {
            if (approver.user_id) {
              return getUser(approver.user_id).then(({ data }) => mapUserToApprover(data));
            }

            if (approver.group_id) {
              return Api.group(approver.group_id).then(mapGroupToApprover);
            }

            return Promise.resolve({
              accessLevel: approver.access_level,
              name: this.accessLevelsData.find(({ id }) => id === approver.access_level).text,
              approvals: 1,
              type: 'access',
            });
          }),
        );
      } catch (e) {
        Sentry.captureException(e);
        this.errorMessage = s__(
          'ProtectedEnvironments|An error occurred while fetching information on the selected approvers.',
        );
      }
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
        ...(this.canCreateMultipleRules
          ? { approval_rules: this.approvalRules }
          : { required_approval_count: this.approvals }),
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
    isApprovalValid(approvals) {
      const count = parseFloat(approvals);
      return count >= MIN_APPROVALS_COUNT && count <= MAX_APPROVALS_COUNT;
    },
  },
  i18n: {
    header: s__('ProtectedEnvironment|Protect an environment'),
    environmentLabel: s__('ProtectedEnvironment|Select environment'),
    environmentText: s__('ProtectedEnvironment|Select an environment'),
    approvalLabel: s__('ProtectedEnvironment|Required approvals'),
    approverLabel: s__('ProtectedEnvironment|Approvers'),
    approverHelp: s__(
      'ProtectedEnvironments|Set which groups, access levels or users are required to approve.',
    ),
    deployerLabel: s__('ProtectedEnvironments|Allowed to deploy'),
    deployerHelp: s__(
      'ProtectedEnvironments|Set which groups, access levels or users that are allowed to deploy to this environment',
    ),
    approvalRulesLabel: s__('ProtectedEnvironments|Approval rules'),
    approvalsInvalid: s__('ProtectedEnvironments|Number of approvals must be between 1 and 5'),
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
      <template v-if="canCreateMultipleRules">
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
          <gl-form-group
            data-testid="create-approver-dropdown"
            label-for="create-approver-dropdown"
            :label="$options.i18n.approverLabel"
          >
            <template #label-description>
              {{ $options.i18n.approverHelp }}
            </template>
            <access-dropdown
              id="create-approver-dropdown"
              :access-levels-data="accessLevelsData"
              :access-level="$options.ACCESS_LEVELS.DEPLOY"
              :disabled="disabled"
              :preselected-items="approvers"
              @hidden="updateApprovers"
            />
          </gl-form-group>
          <gl-collapse :visible="hasSelectedApprovers">
            <span class="gl-font-weight-bold">{{ $options.i18n.approvalRulesLabel }}</span>
            <div
              data-testid="approval-rules"
              class="protected-environment-approvers gl-display-grid gl-gap-5 gl-align-items-center"
            >
              <span class="protected-environment-approvers-label">{{ __('Approvers') }}</span>
              <span>{{ __('Approvals required') }}</span>
              <template v-for="(approver, index) in approverInfo">
                <gl-avatar
                  v-if="approver.avatarShape"
                  :key="`${index}-avatar`"
                  :src="approver.avatarUrl"
                  :size="24"
                  :entity-id="approver.id"
                  :entity-name="approver.entityName"
                  :shape="approver.avatarShape"
                />
                <span v-else :key="`${index}-avatar`" class="gl-w-6"></span>
                <gl-link v-if="approver.webUrl" :key="`${index}-name`" :href="approver.webUrl">
                  {{ approver.name }}
                </gl-link>
                <span v-else :key="`${index}-name`">{{ approver.name }}</span>

                <gl-form-group
                  :key="`${index}-approvals`"
                  :state="isApprovalValid(approver.approvals)"
                >
                  <gl-form-input
                    v-model="approver.approvals"
                    :disabled="approver.inputDisabled"
                    :state="isApprovalValid(approver.approvals)"
                    :name="`approval-count-${approver.name}`"
                    type="number"
                  />
                  <template #invalid-feedback>
                    {{ $options.i18n.approvalsInvalid }}
                  </template>
                </gl-form-group>
              </template>
            </div>
          </gl-collapse>
        </gl-collapse>
      </template>
      <template v-else>
        <gl-form-group
          data-testid="create-deployer-dropdown"
          label-for="create-deployer-dropdown"
          :label="$options.i18n.deployerLabel"
        >
          <access-dropdown
            id="create-deployer-dropdown"
            :access-levels-data="accessLevelsData"
            :access-level="$options.ACCESS_LEVELS.DEPLOY"
            :disabled="disabled"
            @hidden="updateDeployers"
          />
        </gl-form-group>
        <gl-form-group
          label-for="create-approval-count"
          data-testid="create-approval-count"
          :label="$options.i18n.approvalLabel"
        >
          <gl-collapsible-listbox
            id="create-approval-count"
            v-model="approvals"
            :toggle-text="approvals"
            :items="$options.APPROVAL_COUNT_OPTIONS"
          />
        </gl-form-group>
      </template>
    </template>
    <template #footer>
      <gl-button category="primary" variant="confirm" :disabled="isFormInvalid" @click="submitForm">
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-card>
</template>
<style>
.protected-environment-approvers {
  grid-template-columns: repeat(3, max-content);
}

.protected-environment-approvers-label {
  grid-column: span 2;
}
</style>
