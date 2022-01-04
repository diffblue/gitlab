<script>
import { GlButton, GlForm, GlFormInput } from '@gitlab/ui';
import initDatePicker from '~/behaviors/date_picker';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import createIteration from '../queries/create_iteration.mutation.graphql';
import updateIteration from '../queries/update_iteration.mutation.graphql';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormInput,
    MarkdownField,
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
    };
  },
  computed: {
    variables() {
      return {
        input: {
          groupPath: this.groupPath,
          title: this.title,
          description: this.description,
          startDate: this.startDate,
          dueDate: this.dueDate,
        },
      };
    },
  },
  mounted() {
    // TODO: utilize GlDatepicker instead of relying on this jQuery behavior
    initDatePicker();
  },
  methods: {
    save() {
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
    <gl-form class="row common-note-form">
      <div class="col-md-6">
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-title">{{ __('Title') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="iteration-title"
              v-model="title"
              autocomplete="off"
              data-qa-selector="iteration_title_field"
            />
          </div>
        </div>

        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-description">{{ __('Description') }}</label>
          </div>
          <div class="col-sm-10">
            <markdown-field
              :markdown-preview-path="previewMarkdownPath"
              :can-attach-file="false"
              :enable-autocomplete="true"
              label="Description"
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
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-start-date">{{ __('Start date') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="iteration-start-date"
              v-model="startDate"
              class="datepicker form-control"
              :placeholder="__('Select start date')"
              autocomplete="off"
              data-qa-selector="iteration_start_date_field"
              @change="updateStartDate"
            />
            <a class="inline float-right gl-mt-2 js-clear-start-date" href="#">{{
              __('Clear start date')
            }}</a>
          </div>
        </div>
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-due-date">{{ __('Due date') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="iteration-due-date"
              v-model="dueDate"
              class="datepicker form-control"
              :placeholder="__('Select due date')"
              autocomplete="off"
              data-qa-selector="iteration_due_date_field"
              @change="updateDueDate"
            />
            <a class="inline float-right gl-mt-2 js-clear-due-date" href="#">{{
              __('Clear due date')
            }}</a>
          </div>
        </div>
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
