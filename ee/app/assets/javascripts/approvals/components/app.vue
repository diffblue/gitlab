<script>
import { GlButton, GlCard, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { __ } from '~/locale';
import showToast from '~/vue_shared/plugins/global_toast';
import ModalRuleCreate from './modal_rule_create.vue';
import ModalRuleRemove from './modal_rule_remove.vue';

export default {
  components: {
    ModalRuleCreate,
    ModalRuleRemove,
    GlButton,
    GlCard,
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    ...mapState({
      settings: 'settings',
      rules: (state) => state.approvals.rules,
      isLoading: (state) => state.approvals.isLoading,
      hasLoaded: (state) => state.approvals.hasLoaded,
      targetBranch: (state) => state.approvals.targetBranch,
    }),
    createModalId() {
      return `${this.settings.prefix}-approvals-create-modal`;
    },
    removeModalId() {
      return `${this.settings.prefix}-approvals-remove-modal`;
    },
    checkShowResetButton() {
      return this.targetBranch && this.settings.canEdit && this.settings.allowMultiRule;
    },
    rulesLength() {
      return this.rules?.length || 0;
    },
  },
  mounted() {
    return this.fetchRules({ targetBranch: this.targetBranch });
  },
  methods: {
    ...mapActions(['fetchRules', 'undoRulesChange']),
    ...mapActions({ openCreateModal: 'createModal/open' }),
    resetToProjectDefaults() {
      const { targetBranch } = this;

      return this.fetchRules({ targetBranch, resetToDefault: true }).then(() => {
        showToast(__('Approval rules reset to project defaults'), {
          action: {
            text: __('Undo'),
            onClick: (_, toast) => {
              this.undoRulesChange();
              toast.hide();
            },
          },
        });
      });
    },
  },
};
</script>

<template>
  <gl-card
    class="gl-new-card js-approval-rules"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0 gl-overflow-hidden"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h5 class="gl-new-card-title">
          {{ __('Approval rules') }}
          <span class="gl-new-card-count">
            <gl-icon name="approval" class="gl-mr-2" />
            <span data-testid="rules-count">{{ rulesLength }}</span>
          </span>
        </h5>
      </div>
      <div v-if="settings.allowMultiRule" class="gl-new-card-actions">
        <gl-button
          :class="{ 'gl-mr-3': targetBranch, 'gl-mr-0': !targetBranch }"
          :disabled="isLoading"
          category="secondary"
          size="small"
          data-qa-selector="add_approvers_button"
          data-testid="add-approval-rule"
          @click="openCreateModal(null)"
        >
          {{ __('Add approval rule') }}
        </gl-button>
      </div>
    </template>

    <gl-loading-icon v-if="!hasLoaded" size="sm" class="gl-m-5" />
    <template v-else>
      <slot name="rules"></slot>
      <div v-if="checkShowResetButton" class="border-bottom py-3 px-3">
        <div class="gl-display-flex">
          <gl-button
            v-if="targetBranch"
            :disabled="isLoading"
            size="small"
            data-testid="reset-to-defaults"
            @click="resetToProjectDefaults"
          >
            {{ __('Reset to project defaults') }}
          </gl-button>
        </div>
      </div>
      <slot name="footer"></slot>
    </template>
    <modal-rule-create :modal-id="createModalId" :is-mr-edit="isMrEdit" />
    <modal-rule-remove :modal-id="removeModalId" />
  </gl-card>
</template>
