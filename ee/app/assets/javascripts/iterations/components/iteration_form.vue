<script>
import { GlAlert, GlButton, GlForm, GlFormInput } from '@gitlab/ui';
import initDatePicker from '~/behaviors/date_picker';
import createFlash from '~/flash';
import { dayAfter, formatDate } from '~/lib/utils/datetime_utility';
import { TYPE_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import readIteration from '../queries/iteration.query.graphql';
import createIteration from '../queries/iteration_create.mutation.graphql';
import readCadence from '../queries/iteration_cadence.query.graphql';
import updateIteration from '../queries/update_iteration.mutation.graphql';
import iterationsInCadence from '../queries/group_iterations_in_cadence.query.graphql';

export default {
  cadencesList: {
    name: 'index',
  },
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormInput,
    MarkdownField,
  },
  apollo: {
    group: {
      query: readIteration,
      skip() {
        return !this.iterationId;
      },
      /* eslint-disable @gitlab/require-i18n-strings */
      variables() {
        return {
          fullPath: this.fullPath,
          id: convertToGraphQLId('Iteration', this.iterationId),
          isGroup: true,
        };
      },
      /* eslint-enable @gitlab/require-i18n-strings */
      result({ data }) {
        const iteration = data.group.iterations?.nodes[0];

        if (!iteration) {
          this.error = s__('Iterations|Unable to find iteration.');
          return null;
        }

        this.title = iteration.title;
        this.description = iteration.description;
        this.startDate = iteration.startDate;
        this.dueDate = iteration.dueDate;

        return iteration;
      },
      error(err) {
        this.error = err.message;
      },
    },
  },
  inject: ['fullPath', 'previewMarkdownPath'],
  data() {
    return {
      loading: false,
      error: '',
      group: { iteration: {} },
      cadence: {},
      title: '',
      description: '',
      startDate: '',
      dueDate: '',
    };
  },
  computed: {
    cadenceId() {
      return this.$router.currentRoute.params.cadenceId;
    },
    iterationId() {
      return this.$router.currentRoute.params.iterationId;
    },
    isEditing() {
      return Boolean(this.iterationId);
    },
    variables() {
      return {
        groupPath: this.fullPath,
        title: this.title,
        description: this.description,
        startDate: this.startDate,
        dueDate: this.dueDate,
      };
    },
  },
  async mounted() {
    // TODO: utilize GlDatepicker instead of relying on this jQuery behavior
    initDatePicker();

    // prefill start date for the New cadence form
    // if there's iterations in the cadence, use last end_date + 1
    // else use cadence startDate
    if (!this.isEditing && this.cadenceId) {
      const { data } = await this.$apollo.query({
        query: iterationsInCadence,
        variables: {
          fullPath: this.fullPath,
          iterationCadenceId: convertToGraphQLId(TYPE_ITERATIONS_CADENCE, this.cadenceId),
          lastPageSize: 1,
          state: 'all',
        },
      });
      const iteration = data.workspace.iterations?.nodes[0];

      if (iteration) {
        this.startDate = formatDate(
          dayAfter(new Date(iteration.dueDate), { utc: true }),
          'yyyy-mm-dd',
        );
      } else {
        const { data: cadenceData } = await this.$apollo.query({
          query: readCadence,
          variables: {
            fullPath: this.fullPath,
            id: this.cadenceId,
          },
        });

        if (cadenceData.group) {
          const cadence = cadenceData.group?.iterationCadences?.nodes[0];

          if (!cadence) {
            this.error = s__('Iterations|Unable to find iteration cadence.');
            return;
          }

          this.startDate = cadence.startDate;
        }
      }
    }
  },
  methods: {
    save() {
      this.loading = true;
      return this.isEditing ? this.updateIteration() : this.createIteration();
    },
    createIteration() {
      return this.$apollo
        .mutate({
          mutation: createIteration,
          variables: {
            input: {
              ...this.variables,
              iterationsCadenceId: convertToGraphQLId('Iterations::Cadence', this.cadenceId),
            },
          },
        })
        .then(({ data }) => {
          const { iteration, errors } = data.iterationCreate;

          if (errors.length > 0) {
            this.loading = false;
            createFlash({
              message: errors[0],
            });
            return;
          }

          this.$router.push({
            name: 'iteration',
            params: {
              cadenceId: this.cadenceId,
              iterationId: getIdFromGraphQLId(iteration.id),
            },
          });
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
              ...this.variables,
              id: this.iterationId,
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

          this.$router.push({
            name: 'iteration',
            params: {
              cadenceId: this.cadenceId,
              iterationId: this.iterationId,
            },
          });
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

    <gl-alert v-if="error" class="gl-mb-5" variant="danger" @dismiss="error = ''">{{
      error
    }}</gl-alert>
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
        variant="confirm"
        data-qa-selector="save_iteration_button"
        @click="save"
      >
        {{ isEditing ? __('Update iteration') : __('Create iteration') }}
      </gl-button>
      <gl-button class="gl-ml-3" data-testid="cancel-iteration" :to="$options.cadencesList">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
