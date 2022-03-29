<script>
import { GlButton, GlFormInput } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, n__ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  i18n: {
    wipLimitText: __('Work in progress Limit'),
    editLinkText: __('Edit'),
    noneText: __('None'),
    inputPlaceholderText: __('Enter number of issues'),
    removeLimitText: __('Remove limit'),
  },
  components: {
    GlButton,
    GlFormInput,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    maxIssueCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      currentWipLimit: null,
      edit: false,
      updating: false,
    };
  },
  computed: {
    ...mapState(['activeId']),
    wipLimitTypeText() {
      return n__('%d issue', '%d issues', this.maxIssueCount);
    },
    wipLimitIsSet() {
      return this.maxIssueCount !== 0;
    },
    activeListWipLimit() {
      return this.wipLimitIsSet ? this.wipLimitTypeText : this.$options.i18n.noneText;
    },
  },
  methods: {
    ...mapActions(['unsetActiveId', 'updateListWipLimit', 'setError']),
    showInput() {
      this.edit = true;
      this.currentWipLimit = this.maxIssueCount > 0 ? this.maxIssueCount : null;
    },
    handleWipLimitChange(wipLimit) {
      if (wipLimit === '') {
        this.currentWipLimit = null;
      } else {
        this.currentWipLimit = Number(wipLimit);
      }
    },
    onEnter() {
      this.offFocus();
    },
    resetStateAfterUpdate() {
      this.edit = false;
      this.updating = false;
      this.currentWipLimit = null;
    },
    offFocus() {
      if (this.currentWipLimit !== this.maxIssueCount && this.currentWipLimit !== null) {
        this.updating = true;
        // need to reassign bc were clearing the ref in resetStateAfterUpdate.
        const wipLimit = this.currentWipLimit;
        const id = this.activeId;

        this.updateListWipLimit({ maxIssueCount: wipLimit, listId: id })
          .catch(() => {
            this.unsetActiveId();
            this.setError({
              message: __('Something went wrong while updating your list settings'),
            });
          })
          .finally(() => {
            this.resetStateAfterUpdate();
          });
      } else {
        this.edit = false;
      }
    },
    clearWipLimit() {
      this.updateListWipLimit({ maxIssueCount: 0, listId: this.activeId })
        .catch(() => {
          this.unsetActiveId();
          this.setError({
            message: __('Something went wrong while updating your list settings'),
          });
        })
        .finally(() => {
          this.resetStateAfterUpdate();
        });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-space-between gl-flex-direction-column">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-mb-2">
      <label class="m-0">{{ $options.i18n.wipLimitText }}</label>
      <gl-button
        class="gl-h-full gl-border-0 text-dark"
        variant="link"
        data-testid="edit-button"
        @click="showInput"
        >{{ $options.i18n.editLinkText }}</gl-button
      >
    </div>
    <gl-form-input
      v-if="edit"
      v-autofocusonshow
      :value="currentWipLimit"
      :disabled="updating"
      :placeholder="$options.i18n.inputPlaceholderText"
      trim
      number
      type="number"
      min="0"
      @input="handleWipLimitChange"
      @keydown.enter.native="onEnter"
      @blur="offFocus"
    />
    <div v-else class="gl-display-flex gl-align-items-center">
      <p class="bold gl-m-0 text-secondary" data-testid="wip-limit">{{ activeListWipLimit }}</p>
      <template v-if="wipLimitIsSet">
        <span class="m-1">-</span>
        <gl-button
          class="gl-h-full gl-border-0 text-secondary"
          variant="link"
          data-testid="remove-limit"
          @click="clearWipLimit"
          >{{ $options.i18n.removeLimitText }}</gl-button
        >
      </template>
    </div>
  </div>
</template>
