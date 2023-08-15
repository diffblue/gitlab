<script>
import { GlCard, GlBadge, GlButton, GlCollapse, GlIcon, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import { n__, s__, __, sprintf } from '~/locale';
import { DEPLOYER_RULE_KEY, APPROVER_RULE_KEY } from './constants';
import CreateProtectedEnvironment from './create_protected_environment.vue';

export default {
  components: {
    GlCard,
    GlBadge,
    GlButton,
    GlCollapse,
    GlIcon,
    GlModal,
    Pagination,
    CreateProtectedEnvironment,
  },
  props: {
    environments: {
      required: true,
      type: Array,
    },
  },
  i18n: {
    title: s__('ProtectedEnvironments|Protected environments'),
    newProtectedEnvironment: s__('ProtectedEnvironments|Protect an environment'),
    emptyMessage: s__('ProtectedEnvironment|No environments in this project are protected.'),
  },
  data() {
    return {
      expanded: {},
      environmentToUnprotect: null,
      isAddFormVisible: false,
    };
  },
  computed: {
    ...mapState(['pageInfo']),
    confirmUnprotectText() {
      return sprintf(
        s__(
          'ProtectedEnvironment|Users with at least the Developer role can write to unprotected environments. Are you sure you want to unprotect %{environment_name}?',
        ),
        { environment_name: this.environmentToUnprotect?.name },
      );
    },
    isUnprotectModalVisible() {
      return Boolean(this.environmentToUnprotect);
    },
    showPagination() {
      return this.pageInfo?.totalPages > 1;
    },
    protectedEnvironmentsCount() {
      return this.environments.length;
    },
    showEmptyMessage() {
      return this.environments.length === 0 && !this.isAddFormVisible;
    },
  },
  methods: {
    ...mapActions(['setPage', 'fetchProtectedEnvironments']),
    isLast(index) {
      return index === this.environments.length - 1;
    },
    isFirst(index) {
      return index === 0;
    },
    toggleCollapse({ name }) {
      this.$set(this.expanded, name, !this.expanded[name]);
    },
    isExpanded({ name }) {
      return this.expanded[name];
    },
    icon(environment) {
      return this.isExpanded(environment) ? 'chevron-up' : 'chevron-down';
    },
    approvalRulesText({ [APPROVER_RULE_KEY]: approvalRules }) {
      return n__(
        'ProtectedEnvironments|%d Approval Rule',
        'ProtectedEnvironments|%d Approval Rules',
        approvalRules.length,
      );
    },
    deploymentRulesText({ [DEPLOYER_RULE_KEY]: deploymentRules }) {
      return n__(
        'ProtectedEnvironments|%d Deployment Rule',
        'ProtectedEnvironments|%d Deployment Rules',
        deploymentRules.length,
      );
    },
    confirmUnprotect(environment) {
      this.environmentToUnprotect = environment;
    },
    unprotect() {
      this.$emit('unprotect', this.environmentToUnprotect);
    },
    clearEnvironment() {
      this.environmentToUnprotect = null;
    },
    showAddForm() {
      this.isAddFormVisible = true;
    },
    hideAddForm() {
      this.isAddFormVisible = false;
    },
    completeAddForm() {
      this.hideAddForm();
      this.fetchProtectedEnvironments();
    },
  },
  modalOptions: {
    modalId: 'confirm-unprotect-environment',
    size: 'sm',
    actionPrimary: {
      text: __('OK'),
      attributes: { variant: 'danger' },
    },
    actionSecondary: {
      text: __('Cancel'),
    },
  },
};
</script>
<template>
  <div class="gl-mb-5">
    <gl-card
      class="gl-new-card"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body gl-px-0"
      data-testid="new-protected-environment"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title">{{ $options.i18n.title }}</h3>
          <span class="gl-new-card-count" data-testid="protected-environments-count">
            <gl-icon name="environment" class="gl-mr-2" />
            {{ protectedEnvironmentsCount }}
          </span>
        </div>
        <div class="gl-new-card-actions">
          <gl-button
            v-if="!isAddFormVisible"
            size="small"
            data-testid="new-environment-button"
            @click="showAddForm"
            >{{ $options.i18n.newProtectedEnvironment }}</gl-button
          >
        </div>
      </template>

      <create-protected-environment
        v-if="isAddFormVisible"
        @success="completeAddForm"
        @cancel="hideAddForm"
      />

      <gl-modal
        :visible="isUnprotectModalVisible"
        v-bind="$options.modalOptions"
        @primary="unprotect"
        @hide="clearEnvironment"
      >
        {{ confirmUnprotectText }}
      </gl-modal>

      <div v-if="showEmptyMessage" class="gl-new-card-empty gl-px-5 gl-py-4">
        {{ $options.i18n.emptyMessage }}
      </div>
      <template v-else>
        <div
          v-for="(environment, index) in environments"
          :key="environment.name"
          :class="{ 'gl-border-b': !isLast(index) }"
        >
          <gl-button
            block
            category="tertiary"
            variant="confirm"
            class="gl-px-5! gl-py-4! gl-rounded-0!"
            button-text-classes="gl-display-flex gl-w-full gl-align-items-baseline"
            :aria-label="environment.name"
            data-testid="protected-environment-item-toggle"
            @click="toggleCollapse(environment)"
          >
            <span class="gl-text-gray-900 gl-py-2">{{ environment.name }}</span>
            <gl-badge v-if="!isExpanded(environment)" class="gl-ml-auto">
              {{ deploymentRulesText(environment) }}
            </gl-badge>
            <gl-badge v-if="!isExpanded(environment)" class="gl-ml-3">
              {{ approvalRulesText(environment) }}
            </gl-badge>
            <gl-icon
              :name="icon(environment)"
              :size="14"
              :class="{
                'gl-ml-3': !isExpanded(environment),
                'gl-ml-auto': isExpanded(environment),
              }"
              class="gl-text-gray-500"
            />
          </gl-button>
          <gl-collapse
            :visible="isExpanded(environment)"
            class="gl-display-flex gl-flex-direction-column gl-mt-3 gl-mx-5 gl-mb-5"
          >
            <slot :environment="environment"></slot>
            <gl-button
              category="secondary"
              variant="danger"
              class="gl-mt-5 gl-align-self-end"
              @click="confirmUnprotect(environment)"
            >
              {{ s__('ProtectedEnvironments|Unprotect') }}
            </gl-button>
          </gl-collapse>
        </div>
      </template>
    </gl-card>
    <pagination
      v-if="showPagination"
      :change="setPage"
      :page-info="pageInfo"
      align="center"
      class="gl-mt-3"
    />
  </div>
</template>
