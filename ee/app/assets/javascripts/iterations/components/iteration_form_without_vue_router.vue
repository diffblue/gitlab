<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlDatepicker } from '@gitlab/ui';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import createIteration from '../queries/create_iteration.mutation.graphql';
import updateIteration from '../queries/update_iteration.mutation.graphql';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    MarkdownField,
    GlDatepicker,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    previewMarkdownPath: {
      type: String,
      required: false,
      default: '',
    },
    iterationsListPath: {
      type: String,
      required: false,
      default: '',
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    iteration: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      iterations: [],
      loading: false,
      title: this.iteration.title,
      description: this.iteration.description ?? '',
      startDate: this.iteration.startDate ? parsePikadayDate(this.iteration.startDate) : null,
      dueDate: this.iteration.dueDate ? parsePikadayDate(this.iteration.dueDate) : null,
      showValidation: false,
    };
  },
  computed: {
    variables() {
      return {
        input: {
          groupPath: this.groupPath,
          title: this.title,
          description: this.description,
          startDate: this.formattedDate(this.startDate),
          dueDate: this.formattedDate(this.dueDate),
        },
      };
    },
    invalidFeedback() {
      return __('This field is required.');
    },
    isValid() {
      return this.titleState && this.startDateState;
    },
    titleState() {
      return !this.showValidation || Boolean(this.title);
    },
    startDateState() {
      return !this.showValidation || Boolean(this.startDate);
    },
  },
  methods: {
    formattedDate(date) {
      return date ? formatDate(date, 'yyyy-mm-dd') : null;
    },
    save() {
      this.showValidation = true;

      if (!this.isValid) {
        return {};
      }

      this.loading = true;
      return this.isEditing ? this.updateIteration() : this.createIteration();
    },
    cancel() {
      if (this.iterationsListPath) {
        visitUrl(this.iterationsListPath);
      } else {
        this.$emit('cancel');
      }
    },
    createIteration() {
      return this.$apollo
        .mutate({
          mutation: createIteration,
          variables: this.variables,
        })
        .then(({ data }) => {
          const { errors, iteration } = data.createIteration;
          if (errors.length > 0) {
            this.loading = false;
            createFlash({
              message: errors[0],
            });
            return;
          }

          visitUrl(iteration.webUrl);
        })
        .catch(() => {
          this.loading = false;
          createFlash({
            message: __('Unable to save iteration. Please try again'),
          });
        });
    },
    updateIteration() {
      return this.$apollo
        .mutate({
          mutation: updateIteration,
          variables: {
            input: {
              ...this.variables.input,
              id: this.iteration.id,
            },
          },
        })
        .then(({ data }) => {
          const { errors } = data.updateIteration;
          if (errors.length > 0) {
            createFlash({
              message: errors[0],
            });
            return;
          }

          this.$emit('updated');
        })
        .catch(() => {
          createFlash({
            message: __('Unable to save iteration. Please try again'),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    updateDueDate(val) {
      this.dueDate = val;
    },
    updateStartDate(val) {
      this.startDate = val;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex">
      <h1 ref="pageTitle" class="page-title gl-font-size-h-display">
        {{ isEditing ? s__('Iterations|Edit iteration') : s__('Iterations|New iteration') }}
      </h1>
    </div>
    <hr class="gl-mt-0" />
    <gl-form class="row common-note-form" novalidate>
      <div class="col-md-6">
        <gl-form-group
          :label="__('Title')"
          class="gl-flex-grow-1"
          label-for="iteration-title"
          :state="titleState"
          :invalid-feedback="invalidFeedback"
        >
          <gl-form-input
            id="iteration-title"
            v-model="title"
            autocomplete="off"
            data-qa-selector="iteration_title_field"
            :state="titleState"
            required
          />
        </gl-form-group>

        <gl-form-group :label="__('Description')" label-for="iteration-description">
          <markdown-field
            :markdown-preview-path="previewMarkdownPath"
            :can-attach-file="false"
            :enable-autocomplete="true"
            label="__('Description')"
            :textarea-value="description"
            markdown-docs-path="/help/user/markdown"
            :add-spacing-classes="false"
            class="md-area"
          >
            <template #textarea>
              <textarea
                id="iteration-description"
                v-model="description"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="__('Description')"
                data-qa-selector="iteration_description_field"
              >
              </textarea>
            </template>
          </markdown-field>
        </gl-form-group>
      </div>

      <div class="col-md-6">
        <gl-form-group
          :label="__('Start date')"
          :state="startDateState"
          :invalid-feedback="invalidFeedback"
        >
          <div class="gl-display-inline-block gl-mr-2">
            <gl-datepicker
              id="iteration-start-date"
              v-model="startDate"
              :state="startDateState"
              required
            />
          </div>
          <gl-button
            v-show="startDate"
            variant="link"
            class="gl-white-space-nowrap"
            @click="updateStartDate(null)"
          >
            {{ __('Clear start date') }}
          </gl-button>
        </gl-form-group>

        <gl-form-group :label="__('Due date')">
          <div class="gl-display-inline-block gl-mr-2">
            <gl-datepicker id="iteration-due-date" v-model="dueDate" />
          </div>
          <gl-button
            v-show="dueDate"
            variant="link"
            class="gl-white-space-nowrap"
            @click="updateDueDate(null)"
          >
            {{ __('Clear due date') }}
          </gl-button>
        </gl-form-group>
      </div>
    </gl-form>

    <div class="form-actions d-flex">
      <gl-button
        :loading="loading"
        data-testid="save-iteration"
        variant="confirm"
        data-qa-selector="save_iteration_button"
        @click="save"
      >
        {{ isEditing ? __('Save changes') : __('Create iteration') }}
      </gl-button>
      <gl-button class="ml-auto" data-testid="cancel-iteration" @click="cancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
