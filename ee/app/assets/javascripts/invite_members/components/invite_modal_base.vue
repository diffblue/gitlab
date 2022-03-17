<script>
import { GlLink, GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import {
  OVERAGE_MODAL_LINK,
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_BACK_BUTTON,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_LINK_TEXT,
  overageModalInfoText,
  overageModalInfoWarning,
} from '../constants';

const OVERAGE_CONTENT_SLOT = 'overage-content';
const EXTRA_SLOTS = [
  {
    key: OVERAGE_CONTENT_SLOT,
    attributes: {
      class: 'invite-modal-content',
      'data-testid': 'invite-modal-overage-content',
    },
  },
];

export default {
  components: {
    GlLink,
    GlButton,
    InviteModalBase,
  },
  mixins: [glFeatureFlagsMixin()],
  inheritAttrs: false,
  props: {
    name: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
    subscriptionSeats: {
      type: Number,
      required: false,
      default: 10, // TODO: pass data from backend https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78287
    },
  },
  data() {
    return {
      hasOverage: false,
      totalUserCount: null,
    };
  },
  computed: {
    currentSlot() {
      if (this.showOverageModal) {
        return OVERAGE_CONTENT_SLOT;
      }

      // Use CE default
      return undefined;
    },
    showOverageModal() {
      return this.hasOverage && this.enabledOverageCheck;
    },
    enabledOverageCheck() {
      return this.glFeatures.overageMembersModal;
    },
    modalInfo() {
      if (this.totalUserCount) {
        const infoText = overageModalInfoText(this.subscriptionSeats);
        const infoWarning = overageModalInfoWarning(this.totalUserCount, this.name);

        return `${infoText} ${infoWarning}`;
      }
      return '';
    },
    modalTitleOverride() {
      return this.showOverageModal ? OVERAGE_MODAL_TITLE : this.modalTitle;
    },
    submitButtonText() {
      if (this.showOverageModal) {
        return OVERAGE_MODAL_CONTINUE_BUTTON;
      }

      // Use CE default
      return undefined;
    },
  },
  methods: {
    getPassthroughListeners() {
      // This gets the listeners we don't manually handle here
      // so we can pass them through to the CE invite_modal_base.vue
      const { reset, submit, ...listeners } = this.$listeners;

      return listeners;
    },
    onReset(...args) {
      // don't reopen the overage modal
      this.hasOverage = false;

      this.$emit('reset', ...args);
    },
    onSubmit(...args) {
      if (this.enabledOverageCheck && !this.hasOverage) {
        this.totalUserCount = 1;
        this.hasOverage = true;
      } else {
        this.$emit('submit', ...args);
      }
    },
    handleBack() {
      this.hasOverage = false;
    },
    passthroughSlotNames() {
      return Object.keys(this.$scopedSlots || {});
    },
  },
  i18n: {
    OVERAGE_MODAL_TITLE,
    OVERAGE_MODAL_LINK,
    OVERAGE_MODAL_BACK_BUTTON,
    OVERAGE_MODAL_CONTINUE_BUTTON,
    OVERAGE_MODAL_LINK_TEXT,
  },
  OVERAGE_CONTENT_SLOT,
  EXTRA_SLOTS,
};
</script>

<template>
  <invite-modal-base
    v-bind="$attrs"
    :name="name"
    :submit-button-text="submitButtonText"
    :modal-title="modalTitleOverride"
    :current-slot="currentSlot"
    :extra-slots="$options.EXTRA_SLOTS"
    @reset="onReset"
    @submit="onSubmit"
    v-on="getPassthroughListeners()"
  >
    <template #[$options.OVERAGE_CONTENT_SLOT]>
      {{ modalInfo }}
      <gl-link :href="$options.i18n.OVERAGE_MODAL_LINK" target="_blank">{{
        $options.i18n.OVERAGE_MODAL_LINK_TEXT
      }}</gl-link>
    </template>
    <template v-if="enabledOverageCheck && hasOverage" #cancel-button>
      <gl-button data-testid="overage-back-button" @click="handleBack">
        {{ $options.i18n.OVERAGE_MODAL_BACK_BUTTON }}
      </gl-button>
    </template>
    <template v-for="(_, slot) of $scopedSlots" #[slot]="scope">
      <slot :name="slot" v-bind="scope"></slot>
    </template>
  </invite-modal-base>
</template>
