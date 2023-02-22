<script>
import { GlFormGroup, GlCollapse, GlAvatar, GlLink, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { uniqueId } from 'lodash';
import Api from 'ee/api';
import { getUser } from '~/rest_api';
import { s__ } from '~/locale';
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
    GlFormGroup,
    GlCollapse,
    GlAvatar,
    GlLink,
    GlFormInput,
    AccessDropdown,
  },
  inject: { accessLevelsData: { default: [] } },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      approvers: [],
      approverInfo: [],
      uniqueId: uniqueId('deployment-approvers-'),
    };
  },
  computed: {
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
    hasSelectedApprovers() {
      return Boolean(this.approvers.length);
    },
  },
  watch: {
    async approvers() {
      try {
        this.$emit('error', '');
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
        this.$emit(
          'error',
          s__(
            'ProtectedEnvironments|An error occurred while fetching information on the selected approvers.',
          ),
        );
      }
    },
    approvalRules() {
      this.$emit('change', this.approvalRules);
    },
  },
  methods: {
    updateApprovers(permissions) {
      this.approvers = permissions;
    },
    isApprovalValid(approvals) {
      const count = parseFloat(approvals);
      return count >= MIN_APPROVALS_COUNT && count <= MAX_APPROVALS_COUNT;
    },
    approvalsId(index) {
      return `${this.uniqueId}-${index}`;
    },
  },
  i18n: {
    approverLabel: s__('ProtectedEnvironment|Approvers'),
    approverHelp: s__(
      'ProtectedEnvironments|Set which groups, access levels or users are required to approve.',
    ),
    approvalRulesLabel: s__('ProtectedEnvironments|Approval rules'),
    approvalsInvalid: s__('ProtectedEnvironments|Number of approvals must be between 1 and 5'),
  },
};
</script>
<template>
  <div>
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
            :label="$options.i18n.approverLabel"
            :label-for="approvalsId(index)"
            label-sr-only
          >
            <gl-form-input
              :id="approvalsId(index)"
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
  </div>
</template>
