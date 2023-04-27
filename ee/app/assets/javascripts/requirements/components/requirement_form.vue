<script>
import {
  GlDrawer,
  GlButton,
  GlFormCheckbox,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import $ from 'jquery';
import { isEmpty } from 'lodash';
import IssuableBody from '~/vue_shared/issuable/show/components/issuable_body.vue';
import { TAB_KEY_CODE } from '~/lib/utils/keycodes';
import { __ } from '~/locale';
import ZenMode from '~/zen_mode';

import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { TITLE_LENGTH_MAX } from '~/issues/constants';
import {
  I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_TITLE,
  I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_DETAIL,
  STATE_FAILED,
  STATE_PASSED,
} from '../constants';
import RequirementMeta from '../mixins/requirement_meta';
import RequirementStatusBadge from './requirement_status_badge.vue';

export default {
  maxTitleLength: TITLE_LENGTH_MAX,
  events: {
    drawerClose: 'drawer-close',
    disableEdit: 'disable-edit',
    enableEdit: 'enable-edit',
  },
  i18n: {
    legacyReferenceDeprecationTitle: I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_TITLE,
    legacyReferenceDeprecationText: I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_DETAIL,
  },
  components: {
    GlDrawer,
    GlFormCheckbox,
    GlButton,
    RequirementStatusBadge,
    IssuableBody,
    GlSprintf,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [RequirementMeta],
  inject: ['descriptionPreviewPath', 'descriptionHelpPath'],
  props: {
    drawerOpen: {
      type: Boolean,
      required: true,
    },
    requirement: {
      type: Object,
      required: false,
      default: null,
    },
    enableRequirementEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    requirementRequestActive: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      zenModeEnabled: false,
      satisfied: this.requirement?.satisfied || false,
    };
  },
  computed: {
    isCreate() {
      return isEmpty(this.requirement);
    },
    fieldLabel() {
      return this.isCreate ? __('New Requirement') : __('Edit Requirement');
    },
    saveButtonLabel() {
      return this.isCreate ? __('Create requirement') : __('Save changes');
    },
    canEditRequirement() {
      return this.isCreate || (this.canUpdate && !this.isArchived);
    },
    requirementObject() {
      return this.isCreate
        ? {
            iid: '',
            title: '',
            titleHtml: '',
            description: '',
            descriptionHtml: '',
          }
        : this.requirement;
    },
  },
  watch: {
    requirement: {
      handler(value) {
        this.satisfied = value?.satisfied || false;
      },
      deep: true,
    },
    drawerOpen(value) {
      // Clear `title` and `satisfied` value on drawer close.
      if (!value) {
        this.satisfied = false;
      } else {
        document.addEventListener('keydown', this.handleDocumentKeydown);
      }
    },
    enableRequirementEdit(value) {
      this.$nextTick(() => {
        this.lastEl = this.getDrawerLastEl(value);
      });
    },
  },
  mounted() {
    this.handleDocumentKeydown = this.handleDrawerKeydown.bind(this);
    this.zenMode = new ZenMode();
    renderGFM(this.$refs.gfmContainer);
    $(document).on('zen_mode:enter', () => {
      this.zenModeEnabled = true;
    });
    $(document).on('zen_mode:leave', () => {
      this.zenModeEnabled = false;
    });
  },
  beforeDestroy() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    $(document).off('zen_mode:enter');
    // eslint-disable-next-line @gitlab/no-global-event-off
    $(document).off('zen_mode:leave');
  },
  methods: {
    getDrawerHeaderHeight() {
      const wrapperEl = document.querySelector('.js-requirements-container-wrapper');

      if (wrapperEl) {
        return `${wrapperEl.offsetTop}px`;
      }

      return '';
    },
    getDrawerLastEl(isEditMode) {
      return this.$refs.drawerEl.$el?.querySelector(
        isEditMode ? '.js-requirement-cancel' : '.js-issuable-edit',
      );
    },
    newLastTestReportState() {
      // lastTestReportState determines whether a requirement is satisfied or not.
      // Only create a new test report when manually marking/unmarking a requirement as satisfied:

      // when 1) manually marking a requirement as satisfied for the first time.
      const updateCondition1 = this.requirement.lastTestReportState === null && this.satisfied;
      // or when 2) overriding the status in the latest test report.
      const updateCondition2 =
        this.requirement.lastTestReportState !== null &&
        this.satisfied !== this.requirement.satisfied;

      if (updateCondition1 || updateCondition2) {
        return this.satisfied ? STATE_PASSED : STATE_FAILED;
      }

      return null;
    },
    handleDrawerKeydown(e) {
      const { keyCode, shiftKey } = e;

      if (!this.firstEl) {
        this.firstEl = this.$refs.drawerEl.$el?.querySelector('.gl-drawer-close-button');
      }

      if (!this.lastEl) {
        this.lastEl = this.getDrawerLastEl(this.enableRequirementEdit || this.isCreate);
      }

      if (keyCode !== TAB_KEY_CODE) return;

      if (!this.$refs.drawerEl.$el.contains(document.activeElement)) this.firstEl.focus();

      if (shiftKey) {
        if (document.activeElement === this.firstEl) {
          this.lastEl.focus();
          e.preventDefault();
        }
      } else if (document.activeElement === this.lastEl) {
        this.firstEl.focus();
        e.preventDefault();
      }
    },
    handleDrawerClose() {
      this.$emit(this.$options.events.drawerClose);
      document.removeEventListener('keydown', this.handleDocumentKeydown);
      this.firstEl = null;
      this.lastEl = null;
    },
    handleFormInputKeyDown() {
      if (this.zenModeEnabled) {
        // Exit Zen mode, don't close the drawer.
        this.zenModeEnabled = false;
        this.zenMode.exit();
      } else {
        this.handleCancel();
      }
    },
    handleSave({ issuableTitle, issuableDescription }) {
      const eventParams = {
        title: issuableTitle,
        description: issuableDescription,
      };

      if (!this.isCreate) {
        eventParams.iid = this.requirement.iid;
        eventParams.lastTestReportState = this.newLastTestReportState();
      }

      this.$emit('save', eventParams);
    },
    handleCancel() {
      this.$emit(
        this.isCreate ? this.$options.events.drawerClose : this.$options.events.disableEdit,
      );
    },
  },
};
</script>

<template>
  <gl-drawer
    ref="drawerEl"
    :open="drawerOpen"
    :header-height="getDrawerHeaderHeight()"
    :class="{ 'zen-mode gl-absolute': zenModeEnabled }"
    class="requirement-form-drawer gl-drawer-responsive"
    @close="handleDrawerClose"
  >
    <template #title>
      <h4 v-if="isCreate" class="gl-m-0">{{ __('New Requirement') }}</h4>
      <div v-else class="gl-display-flex gl-align-items-center">
        <strong class="gl-text-gray-500">{{ reference }}</strong>
        <requirement-status-badge
          v-if="testReport"
          :test-report="testReport"
          :last-test-report-manually-created="requirement.lastTestReportManuallyCreated"
          class="gl-ml-3"
        />
      </div>
    </template>
    <issuable-body
      :issuable="requirementObject"
      :enable-edit="canEditRequirement"
      :enable-autocomplete="false"
      :enable-autosave="false"
      :enable-zen-mode="false"
      :edit-form-visible="enableRequirementEdit || isCreate"
      :show-field-title="true"
      :description-preview-path="descriptionPreviewPath"
      :description-help-path="descriptionHelpPath"
      status-icon="issue-open-m"
      @edit-issuable="$emit($options.events.enableEdit, $event)"
      @keydown-title.escape.exact.stop="handleFormInputKeyDown"
      @keydown-description.escape.exact.stop="handleFormInputKeyDown"
      @keydown-title.meta.enter="handleSave(arguments[1])"
      @keydown-title.ctrl.enter="handleSave(arguments[1])"
      @keydown-description.meta.enter="handleSave(arguments[1])"
      @keydown-description.ctrl.enter="handleSave(arguments[1])"
    >
      <template #edit-form-actions="issuableMeta">
        <gl-form-checkbox v-if="!isCreate" v-model="satisfied" class="gl-mt-6">{{
          __('Satisfied')
        }}</gl-form-checkbox>
        <div class="gl-display-flex requirement-form-actions gl-mt-6">
          <gl-button
            :disabled="
              requirementRequestActive ||
              issuableMeta.issuableTitle.length > $options.maxTitleLength ||
              !issuableMeta.issuableTitle.length
            "
            :loading="requirementRequestActive"
            data-testid="requirement-save"
            variant="confirm"
            category="primary"
            class="gl-mr-auto js-requirement-save"
            @click="handleSave(issuableMeta)"
          >
            {{ saveButtonLabel }}
          </gl-button>
          <gl-button
            data-testid="requirement-cancel"
            variant="default"
            category="primary"
            class="js-requirement-cancel"
            @click="handleCancel"
          >
            {{ __('Cancel') }}
          </gl-button>
        </div>
      </template>
      <template #secondary-content>
        <aside>
          <h2 class="gl-font-base">
            <gl-sprintf :message="$options.i18n.legacyReferenceDeprecationTitle">
              <template #legacyId
                ><span class="gl-font-weight-normal">{{ legacyReference }}</span></template
              >
            </gl-sprintf>
          </h2>
          <p class="gl-font-sm gl-line-height-20">
            <gl-sprintf :message="$options.i18n.legacyReferenceDeprecationText">
              <template #id>{{ reference }}</template>
              <template #link="{ content }">
                <gl-link
                  class="gl-font-size-inherit"
                  :href="$options.legacyReferenceDeprecationUrl"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </p>
        </aside>
      </template>
    </issuable-body>
  </gl-drawer>
</template>
