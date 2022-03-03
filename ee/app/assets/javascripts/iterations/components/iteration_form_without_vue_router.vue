<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlDatepicker } from '@gitlab/ui';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { formatDate } from '~/lib/utils/datetime_utility';
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
      startDate: this.iteration.startDate,
      dueDate: this.iteration.dueDate,
      isValidTitle: true,
      isValidStartDate: true,
    };
  },
  computed: {
    variables() {
      return {
        input: {
          groupPath: this.groupPath,
          title: this.title,
          description: this.description,
          startDate: this.startDate ? formatDate(this.startDate, 'yyyy-mm-dd') : null,
          dueDate: this.dueDate ? formatDate(this.dueDate, 'yyyy-mm-dd') : null,
        },
      };
    },
    invalidFeedback() {
      return __('This field is required.');
    },
  },
  methods: {
    checkValidations() {
      let isValid = true;

      if (!this.title) {
        this.isValidTitle = false;
        isValid = false;
      } else {
        this.isValidTitle = true;
      }

      if (!this.startDate) {
        this.isValidStartDate = false;
        isValid = false;
      } else {
        this.isValidStartDate = true;
      }
      return isValid;
    },
    save() {
      if (!this.checkValidations()) {
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
      <h3 ref="pageTitle" class="page-title">
        {{ isEditing ? s__('Iterations|Edit iteration') : s__('Iterations|New iteration') }}
      </h3>
    </div>
    <hr class="gl-mt-0" />
    <gl-form class="row common-note-form" novalidate>
      <div class="col-md-6">
        <gl-form-group
          :label="__('Title')"
          class="gl-flex-grow-1"
          label-for="iteration-title"
          :state="isValidTitle"
          :invalid-feedback="invalidFeedback"
        >
          <gl-form-input
            id="iteration-title"
            v-model="title"
            autocomplete="off"
            data-qa-selector="iteration_title_field"
            :state="isValidTitle"
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
          :state="isValidStartDate"
          :invalid-feedback="invalidFeedback"
        >
          <div class="gl-display-inline-block gl-mr-2">
            <gl-datepicker
              id="iteration-start-date"
              v-model="startDate"
              :state="isValidStartDate"
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
        variant="success"
        data-qa-selector="save_iteration_button"
        @click="save"
      >
        {{ isEditing ? __('Update iteration') : __('Create iteration') }}
      </gl-button>
      <gl-button class="ml-auto" data-testid="cancel-iteration" @click="cancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
