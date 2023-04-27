<script>
import {
  GlButton,
  GlDatepicker,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import Autosave from '~/autosave';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import ColorSelectDropdown from '~/vue_shared/components/color_select_dropdown/color_select_root.vue';
import { DEFAULT_COLOR } from '~/vue_shared/components/color_select_dropdown/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import createEpic from '../queries/create_epic.mutation.graphql';

export default {
  WORKSPACE_GROUP,
  components: {
    ColorSelectDropdown,
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    LabelsSelectWidget,
    MarkdownField,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['groupPath', 'groupEpicsPath', 'markdownPreviewPath', 'markdownDocsPath'],
  data() {
    return {
      title: '',
      description: '',
      color: DEFAULT_COLOR,
      confidential: false,
      labels: [],
      startDateFixed: null,
      dueDateFixed: null,
      loading: false,
    };
  },
  computed: {
    labelIds() {
      return this.labels.map((label) => label.id);
    },
    isEpicColorEnabled() {
      return this.glFeatures.epicColorHighlight;
    },
  },
  i18n: {
    confidentialityLabel: s__(`
      Epics|This epic and any containing child epics are confidential
      and should only be visible to team members with at least Reporter access.
    `),
    epicDatesHint: s__('Epics|Leave empty to inherit from milestone dates'),
    colorHelp: s__(
      `Epics|The color for the epic when it's visualized, such as on roadmap timeline bars.`,
    ),
  },
  mounted() {
    this.initAutosave();
  },
  methods: {
    initAutosave() {
      const { titleInput, descriptionInput } = this.$refs;
      const { pathname, search } = document.location;

      if (!titleInput || !descriptionInput) return;

      /**
       * We'd need to update Autosave to work with plain HTML elements instead of
       * jQuery instance, but until then, we'd have to rely on jQuery.
       */
      this.autosaveTitle = new Autosave(titleInput.$el, [pathname, search, 'title']);
      this.autosaveDescription = new Autosave(descriptionInput, [pathname, search, 'description']);
    },
    resetAutosave() {
      this.autosaveTitle.reset();
      this.autosaveDescription.reset();
    },
    save() {
      this.loading = true;

      const input = {
        addLabelIds: this.labelIds,
        groupPath: this.groupPath,
        title: this.title,
        description: this.description,
        confidential: this.confidential,
        startDateFixed: this.startDateFixed ? formatDate(this.startDateFixed, 'yyyy-mm-dd') : null,
        startDateIsFixed: Boolean(this.startDateFixed),
        dueDateFixed: this.dueDateFixed ? formatDate(this.dueDateFixed, 'yyyy-mm-dd') : null,
        dueDateIsFixed: Boolean(this.dueDateFixed),
      };

      if (this.isEpicColorEnabled && this.color?.color !== '') {
        input.color = this.color.color;
      }

      return this.$apollo
        .mutate({
          mutation: createEpic,
          variables: { input },
        })
        .then(({ data }) => {
          const { errors, epic } = data.createEpic;
          if (errors?.length > 0) {
            createAlert({
              message: errors[0],
            });
            this.loading = false;
            return;
          }

          this.resetAutosave();
          visitUrl(epic.webUrl);
        })
        .catch(() => {
          this.loading = false;
          createAlert({
            message: s__('Epics|Unable to save epic. Please try again'),
          });
        });
    },
    updateDueDate(val) {
      this.dueDateFixed = val;
    },
    updateStartDate(val) {
      this.startDateFixed = val;
    },
    handleUpdateSelectedLabels(labels) {
      this.labels = labels.map((label) => ({ ...label, id: getIdFromGraphQLId(label.id) }));
    },
    handleUpdateSelectedColor({ color }) {
      this.color = color;
    },
  },
};
</script>

<template>
  <div>
    <h1 class="page-title gl-font-size-h-display gl-pb-5">
      {{ __('New Epic') }}
    </h1>
    <gl-form class="common-note-form new-epic-form" @submit.prevent="save">
      <gl-form-group :label="__('Title (required)')" label-for="epic-title">
        <gl-form-input
          id="epic-title"
          ref="titleInput"
          v-model="title"
          data-testid="epic-title"
          data-qa-selector="epic_title_field"
          autocomplete="off"
          autofocus
        />
      </gl-form-group>

      <gl-form-group :label="__('Description')" label-for="epic-description">
        <markdown-field
          :markdown-preview-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocsPath"
          :can-suggest="false"
          :can-attach-file="true"
          :enable-autocomplete="true"
          :add-spacing-classes="false"
          :textarea-value="description"
          :label="__('Description')"
          class="md-area"
        >
          <template #textarea>
            <textarea
              id="epic-description"
              ref="descriptionInput"
              v-model="description"
              data-testid="epic-description"
              class="note-textarea js-gfm-input js-autosize markdown-area"
              dir="auto"
              data-supports-quick-actions="true"
              :placeholder="__('Write a comment or drag your files here…')"
              :aria-label="__('Description')"
            ></textarea>
          </template>
        </markdown-field>
      </gl-form-group>
      <gl-form-group :label="__('Confidentiality')" label-for="epic-confidentiality">
        <gl-form-checkbox
          id="epic-confidentiality"
          v-model="confidential"
          data-qa-selector="confidential_epic_checkbox"
          data-testid="epic-confidentiality"
          >{{ $options.i18n.confidentialityLabel }}</gl-form-checkbox
        >
      </gl-form-group>

      <gl-form-group :label="__('Labels')">
        <labels-select-widget
          class="block labels js-labels-block"
          :full-path="groupPath"
          :allow-label-create="true"
          :allow-multiselect="true"
          :allow-scoped-labels="false"
          :labels-filter-base-path="groupEpicsPath"
          :attr-workspace-path="groupPath"
          workspace-type="group"
          :label-create-type="$options.WORKSPACE_GROUP"
          issuable-type="epic"
          variant="embedded"
          data-qa-selector="labels_block"
          @updateSelectedLabels="handleUpdateSelectedLabels($event.labels)"
          >{{ __('None') }}</labels-select-widget
        >
      </gl-form-group>
      <gl-form-group :label="__('Start date')" :description="$options.i18n.epicDatesHint">
        <div class="gl-display-inline-block gl-xs-mb-3">
          <gl-datepicker
            v-model="startDateFixed"
            :max-date="dueDateFixed"
            :default-date="dueDateFixed"
            data-testid="epic-start-date"
          />
        </div>
        <gl-button
          v-show="startDateFixed"
          variant="tertiary"
          class="gl-white-space-nowrap"
          data-testid="clear-start-date"
          @click="updateStartDate(null)"
          >{{ __('Clear start date') }}</gl-button
        >
      </gl-form-group>
      <gl-form-group :label="__('Due date')" :description="$options.i18n.epicDatesHint">
        <div class="gl-display-inline-block gl-xs-mb-3">
          <gl-datepicker
            v-model="dueDateFixed"
            :min-date="startDateFixed"
            :default-date="startDateFixed"
            data-testid="epic-due-date"
          />
        </div>
        <gl-button
          v-show="dueDateFixed"
          variant="tertiary"
          class="gl-white-space-nowrap"
          data-testid="clear-due-date"
          @click="updateDueDate(null)"
          >{{ __('Clear due date') }}</gl-button
        >
      </gl-form-group>

      <gl-form-group
        v-if="isEpicColorEnabled"
        label-for="epic-color"
        :description="$options.i18n.colorHelp"
        :label="__('Color')"
      >
        <color-select-dropdown
          class="block colors js-colors-block"
          :full-path="groupPath"
          :attr-workspace-path="groupPath"
          workspace-type="group"
          :label-create-type="$options.WORKSPACE_GROUP"
          :default-color="color"
          issuable-type="epic"
          variant="embedded"
          @updateSelectedColor="handleUpdateSelectedColor($event)"
        >
          {{ __('Select a color') }}
        </color-select-dropdown>
      </gl-form-group>

      <div class="footer-block gl-pt-4">
        <gl-button
          type="submit"
          variant="confirm"
          :loading="loading"
          :disabled="!title"
          data-testid="save-epic"
          data-qa-selector="create_epic_button"
          class="gl-mr-2"
          >{{ __('Create epic') }}</gl-button
        >
        <gl-button
          type="button"
          class="gl-ml-auto"
          data-testid="cancel-epic"
          :href="groupEpicsPath"
          >{{ __('Cancel') }}</gl-button
        >
      </div>
    </gl-form>
  </div>
</template>
