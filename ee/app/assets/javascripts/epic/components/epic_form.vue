<script>
import {
  GlButton,
  GlDatepicker,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { formatDate } from '~/lib/utils/datetime_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import LabelsSelectVue from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import createEpic from '../queries/createEpic.mutation.graphql';

export default {
  components: {
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckbox,
    GlFormInput,
    GlFormGroup,
    MarkdownField,
    LabelsSelectVue,
  },
  inject: [
    'groupPath',
    'groupEpicsPath',
    'labelsFetchPath',
    'labelsManagePath',
    'markdownPreviewPath',
    'markdownDocsPath',
  ],
  data() {
    return {
      title: '',
      description: '',
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
  },
  i18n: {
    confidentialityLabel: s__(`
      Epics|This epic and any containing child epics are confidential
      and should only be visible to team members with at least Reporter access.
    `),
    epicDatesHint: s__('Epics|Leave empty to inherit from milestone dates'),
  },
  methods: {
    save() {
      this.loading = true;

      return this.$apollo
        .mutate({
          mutation: createEpic,
          variables: {
            input: {
              addLabelIds: this.labelIds,
              groupPath: this.groupPath,
              title: this.title,
              description: this.description,
              confidential: this.confidential,
              startDateFixed: this.startDateFixed
                ? formatDate(this.startDateFixed, 'yyyy-mm-dd')
                : null,
              startDateIsFixed: Boolean(this.startDateFixed),
              dueDateFixed: this.dueDateFixed ? formatDate(this.dueDateFixed, 'yyyy-mm-dd') : null,
              dueDateIsFixed: Boolean(this.dueDateFixed),
            },
          },
        })
        .then(({ data }) => {
          const { errors, epic } = data.createEpic;
          if (errors?.length > 0) {
            createFlash({
              message: errors[0],
            });
            this.loading = false;
            return;
          }

          visitUrl(epic.webUrl);
        })
        .catch(() => {
          this.loading = false;
          createFlash({
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
      const ids = [];
      const allLabels = [...labels, ...this.labels];

      this.labels = allLabels.filter((label) => {
        const exists = ids.includes(label.id);
        ids.push(label.id);

        return !exists && label.set;
      });
    },
  },
};
</script>

<template>
  <div>
    <h3 class="page-title gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-5 gl-mb-6">
      {{ __('New Epic') }}
    </h3>
    <gl-form class="common-note-form new-epic-form" @submit.prevent="save">
      <gl-form-group :label="__('Title')" label-for="epic-title">
        <gl-form-input
          id="epic-title"
          v-model="title"
          data-testid="epic-title"
          data-qa-selector="epic_title_field"
          :placeholder="s__('Epics|Enter a title for your epic')"
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
              v-model="description"
              data-testid="epic-description"
              class="note-textarea js-gfm-input js-autosize markdown-area"
              dir="auto"
              data-supports-quick-actions="true"
              :placeholder="__('Write a comment or drag your files here…')"
              :aria-label="__('Description')"
            >
            </textarea>
          </template>
        </markdown-field>
      </gl-form-group>
      <gl-form-group :label="__('Confidentiality')" label-for="epic-confidentiality">
        <gl-form-checkbox
          id="epic-confidentiality"
          v-model="confidential"
          data-qa-selector="confidential_epic_checkbox"
          data-testid="epic-confidentiality"
        >
          {{ $options.i18n.confidentialityLabel }}
        </gl-form-checkbox>
      </gl-form-group>
      <hr />
      <gl-form-group :label="__('Labels')">
        <labels-select-vue
          :allow-label-edit="false"
          :allow-label-create="true"
          :allow-multiselect="true"
          :allow-scoped-labels="false"
          :selected-labels="labels"
          :labels-fetch-path="labelsFetchPath"
          :labels-manage-path="labelsManagePath"
          :labels-filter-base-path="groupEpicsPath"
          :labels-list-title="__('Select label')"
          :dropdown-button-text="__('Choose labels')"
          variant="embedded"
          class="block labels js-labels-block"
          @updateSelectedLabels="handleUpdateSelectedLabels"
        >
          {{ __('None') }}
        </labels-select-vue>
      </gl-form-group>
      <gl-form-group :label="__('Start date')" :description="$options.i18n.epicDatesHint">
        <div class="gl-display-inline-block gl-mr-2">
          <gl-datepicker v-model="startDateFixed" data-testid="epic-start-date" />
        </div>
        <gl-button
          v-show="startDateFixed"
          variant="link"
          class="gl-white-space-nowrap"
          data-testid="clear-start-date"
          @click="updateStartDate(null)"
        >
          {{ __('Clear start date') }}
        </gl-button>
      </gl-form-group>
      <gl-form-group
        class="gl-pb-4"
        :label="__('Due date')"
        :description="$options.i18n.epicDatesHint"
      >
        <div class="gl-display-inline-block gl-mr-2">
          <gl-datepicker v-model="dueDateFixed" data-testid="epic-due-date" />
        </div>
        <gl-button
          v-show="dueDateFixed"
          variant="link"
          class="gl-white-space-nowrap"
          data-testid="clear-due-date"
          @click="updateDueDate(null)"
        >
          {{ __('Clear due date') }}
        </gl-button>
      </gl-form-group>

      <div class="footer-block row-content-block gl-display-flex">
        <gl-button
          type="submit"
          variant="confirm"
          :loading="loading"
          :disabled="!title"
          data-testid="save-epic"
          data-qa-selector="create_epic_button"
        >
          {{ __('Create epic') }}
        </gl-button>
        <gl-button
          type="button"
          class="gl-ml-auto"
          data-testid="cancel-epic"
          :href="groupEpicsPath"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
