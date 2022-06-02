<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
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
  <div class="js-approval-rules">
    <gl-loading-icon v-if="!hasLoaded" size="lg" />
    <template v-else>
      <div class="border-bottom">
        <slot name="rules"></slot>
      </div>
      <div v-if="settings.canEdit && settings.allowMultiRule" class="border-bottom py-3 px-3">
        <div class="gl-display-flex">
          <gl-button
            :class="{ 'gl-mr-3': targetBranch, 'gl-mr-0': !targetBranch }"
            :disabled="isLoading"
            category="secondary"
            variant="confirm"
            size="small"
            data-qa-selector="add_approvers_button"
            data-testid="add-approval-rule"
            @click="openCreateModal(null)"
          >
            {{ __('Add approval rule') }}
          </gl-button>
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
  </div>
</template>
