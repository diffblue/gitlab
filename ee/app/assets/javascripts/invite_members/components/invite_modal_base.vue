<script>
import {
  GlFormGroup,
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
  GlFormInput,
} from '@gitlab/ui';
import { unescape } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ACCESS_LEVEL,
  ACCESS_EXPIRE_DATE,
  INVALID_FEEDBACK_MESSAGE_DEFAULT,
  READ_MORE_TEXT,
  INVITE_BUTTON_TEXT,
  CANCEL_BUTTON_TEXT,
  HEADER_CLOSE_LABEL,
} from '~/invite_members/constants';
import { responseMessageFromError } from '~/invite_members/utils/response_message_parser';
import {
  OVERAGE_MODAL_LINK,
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_BACK_BUTTON,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_LINK_TEXT,
  overageModalInfoText,
  overageModalInfoWarning,
} from '../constants';

export default {
  components: {
    GlFormGroup,
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlButton,
    GlFormInput,
  },
  mixins: [glFeatureFlagsMixin()],
  inheritAttrs: false,
  props: {
    modalTitle: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    accessLevels: {
      type: Object,
      required: true,
    },
    defaultAccessLevel: {
      type: Number,
      required: true,
    },
    helpLink: {
      type: String,
      required: true,
    },
    labelIntroText: {
      type: String,
      required: true,
    },
    labelSearchField: {
      type: String,
      required: true,
    },
    formGroupDescription: {
      type: String,
      required: false,
      default: '',
    },
    submitDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    subscriptionSeats: {
      type: Number,
      required: false,
      default: 10, // TODO: pass data from backend https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78287
    },
  },
  data() {
    // Be sure to check out reset!
    return {
      invalidFeedbackMessage: '',
      selectedAccessLevel: this.defaultAccessLevel,
      selectedDate: undefined,
      isLoading: false,
      minDate: new Date(),
      hasOverage: false,
      totalUserCount: null,
    };
  },
  computed: {
    introText() {
      return sprintf(this.labelIntroText, { name: this.name });
    },
    validationState() {
      return this.invalidFeedbackMessage ? false : null;
    },
    selectLabelId() {
      return `${this.modalId}_select`;
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        (key) => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
    },
    showOverageModal() {
      return this.hasOverage && this.enabledOverageCheck;
    },
    enabledOverageCheck() {
      return this.glFeatures.overageMembersModal;
    },
    modalInfo() {
      if (this.totalUserCount) {
        const infoText = this.$options.i18n.infoText(this.subscriptionSeats);
        const infoWarning = this.$options.i18n.infoWarning(this.totalUserCount, this.name);

        return `${infoText} ${infoWarning}`;
      }
      return '';
    },
    modalTitleLabel() {
      return this.showOverageModal ? this.$options.i18n.OVERAGE_MODAL_TITLE : this.modalTitle;
    },
  },
  watch: {
    selectedAccessLevel: {
      immediate: true,
      handler(val) {
        this.$emit('access-level', val);
      },
    },
  },
  methods: {
    showInvalidFeedbackMessage(response) {
      const message = this.unescapeMsg(responseMessageFromError(response));

      this.invalidFeedbackMessage = message || INVALID_FEEDBACK_MESSAGE_DEFAULT;
    },
    reset() {
      // This component isn't necessarily disposed,
      // so we might need to reset it's state.
      this.isLoading = false;
      this.invalidFeedbackMessage = '';
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;

      // don't reopen the overage modal
      this.hasOverage = false;

      this.$emit('reset');
    },
    closeModal() {
      this.reset();
      this.$refs.modal.hide();
    },
    clearValidation() {
      this.invalidFeedbackMessage = '';
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    submit() {
      this.isLoading = true;
      this.invalidFeedbackMessage = '';

      this.$emit('submit', {
        onSuccess: () => {
          this.isLoading = false;
        },
        onError: (...args) => {
          this.isLoading = false;
          this.showInvalidFeedbackMessage(...args);
        },
        data: {
          accessLevel: this.selectedAccessLevel,
          expiresAt: this.selectedDate,
        },
      });
    },
    unescapeMsg(message) {
      return unescape(sanitize(message, { ALLOWED_TAGS: [] }));
    },
    checkOverage() {
      // add a more complex check in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78287
      // totalUserCount should be calculated there
      if (this.enabledOverageCheck) {
        this.totalUserCount = 1;
        this.hasOverage = true;
      } else {
        this.submit();
      }
    },
    handleBack() {
      this.hasOverage = false;
    },
  },
  i18n: {
    HEADER_CLOSE_LABEL,
    ACCESS_EXPIRE_DATE,
    ACCESS_LEVEL,
    READ_MORE_TEXT,
    INVITE_BUTTON_TEXT,
    CANCEL_BUTTON_TEXT,
    OVERAGE_MODAL_TITLE,
    OVERAGE_MODAL_LINK,
    OVERAGE_MODAL_BACK_BUTTON,
    OVERAGE_MODAL_CONTINUE_BUTTON,
    OVERAGE_MODAL_LINK_TEXT,
    infoText: overageModalInfoText,
    infoWarning: overageModalInfoWarning,
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    data-qa-selector="invite_members_modal_content"
    data-testid="invite-modal"
    size="sm"
    :title="modalTitleLabel"
    :header-close-label="$options.i18n.HEADER_CLOSE_LABEL"
    @hidden="reset"
    @close="reset"
    @hide="reset"
  >
    <div class="gl-display-grid">
      <transition name="invite-modal-transition">
        <div
          v-show="!showOverageModal"
          class="invite-modal-content"
          data-testid="invite-modal-initial-content"
        >
          <div class="gl-display-flex" data-testid="modal-base-intro-text">
            <slot name="intro-text-before"></slot>
            <p>
              <gl-sprintf :message="introText">
                <template #strong="{ content }">
                  <strong>{{ content }}</strong>
                </template>
              </gl-sprintf>
            </p>
            <slot name="intro-text-after"></slot>
          </div>

          <gl-form-group
            :invalid-feedback="invalidFeedbackMessage"
            :state="validationState"
            :description="formGroupDescription"
            data-testid="members-form-group"
          >
            <label :id="selectLabelId" class="col-form-label">{{ labelSearchField }}</label>
            <slot
              name="select"
              v-bind="{ clearValidation, validationState, labelId: selectLabelId }"
            ></slot>
          </gl-form-group>

          <label class="gl-font-weight-bold">{{ $options.i18n.ACCESS_LEVEL }}</label>
          <div class="gl-mt-2 gl-w-half gl-xs-w-full">
            <gl-dropdown
              class="gl-shadow-none gl-w-full"
              data-qa-selector="access_level_dropdown"
              v-bind="$attrs"
              :text="selectedRoleName"
            >
              <template v-for="(key, item) in accessLevels">
                <gl-dropdown-item
                  :key="key"
                  active-class="is-active"
                  is-check-item
                  :is-checked="key === selectedAccessLevel"
                  @click="changeSelectedItem(key)"
                >
                  <div>{{ item }}</div>
                </gl-dropdown-item>
              </template>
            </gl-dropdown>
          </div>

          <div class="gl-mt-2 gl-w-half gl-xs-w-full">
            <gl-sprintf :message="$options.i18n.READ_MORE_TEXT">
              <template #link="{ content }">
                <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </div>

          <label class="gl-mt-5 gl-display-block" for="expires_at">{{
            $options.i18n.ACCESS_EXPIRE_DATE
          }}</label>
          <div class="gl-mt-2 gl-w-half gl-xs-w-full gl-display-inline-block">
            <gl-datepicker
              v-model="selectedDate"
              class="gl-display-inline!"
              :min-date="minDate"
              :target="null"
            >
              <template #default="{ formattedDate }">
                <gl-form-input
                  class="gl-w-full"
                  :value="formattedDate"
                  :placeholder="__(`YYYY-MM-DD`)"
                />
              </template>
            </gl-datepicker>
          </div>
          <slot name="form-after"></slot>
        </div>
      </transition>
      <transition name="invite-modal-transition">
        <div
          v-show="showOverageModal"
          class="invite-modal-content"
          data-testid="invite-modal-overage-content"
        >
          {{ modalInfo }}
          <gl-link :href="$options.i18n.OVERAGE_MODAL_LINK" target="_blank">{{
            $options.i18n.OVERAGE_MODAL_LINK_TEXT
          }}</gl-link>
        </div>
      </transition>
    </div>
    <template #modal-footer>
      <template v-if="!showOverageModal">
        <gl-button data-testid="cancel-button" @click="closeModal">
          {{ $options.i18n.CANCEL_BUTTON_TEXT }}
        </gl-button>
        <gl-button
          :disabled="submitDisabled"
          :loading="isLoading"
          variant="success"
          data-qa-selector="invite_button"
          data-testid="invite-button"
          @click="checkOverage"
        >
          {{ $options.i18n.INVITE_BUTTON_TEXT }}
        </gl-button>
      </template>
      <template v-else>
        <gl-button data-testid="overage-back-button" @click="handleBack">
          {{ $options.i18n.OVERAGE_MODAL_BACK_BUTTON }}
        </gl-button>
        <gl-button
          :disabled="submitDisabled"
          :loading="isLoading"
          variant="success"
          data-qa-selector="invite_with_overage_button"
          data-testid="invite-with-overage-button"
          @click="submit"
        >
          {{ $options.i18n.OVERAGE_MODAL_CONTINUE_BUTTON }}
        </gl-button>
      </template>
    </template>
  </gl-modal>
</template>
