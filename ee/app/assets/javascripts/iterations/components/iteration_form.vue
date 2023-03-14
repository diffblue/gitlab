<script>
import { GlAlert, GlButton, GlDatepicker, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { STATUS_ALL } from '~/issues/constants';
import { dayAfter, formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { TYPENAME_ITERATION, TYPENAME_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import readIteration from '../queries/iteration.query.graphql';
import createIteration from '../queries/iteration_create.mutation.graphql';
import readCadence from '../queries/iteration_cadence.query.graphql';
import updateIteration from '../queries/update_iteration.mutation.graphql';
import iterationsInCadence from '../queries/group_iterations_in_cadence.query.graphql';

export default {
  i18n: {
    title: {
      edit: s__('Iterations|Edit iteration'),
      new: s__('Iterations|New iteration'),
    },
    form: {
      title: s__('Iterations|Title'),
      startDate: s__('Iterations|Start date'),
      dueDate: s__('Iterations|Due date'),
      description: s__('Iterations|Description'),
    },
    submitButton: {
      save: s__('Iterations|Save changes'),
      create: s__('Iterations|Create iteration'),
    },
    cancelButton: s__('Iterations|Cancel'),
  },
  cadencesList: {
    name: 'index',
  },
  components: {
    GlAlert,
    GlDatepicker,
    GlButton,
    GlForm,
    GlFormInput,
    GlFormGroup,
    MarkdownField,
  },
  apollo: {
    group: {
      query: readIteration,
      skip() {
        return !this.iterationId;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          id: convertToGraphQLId(TYPENAME_ITERATION, this.iterationId),
          isGroup: true,
        };
      },
      result({ data }) {
        const iteration = data.group.iterations?.nodes[0];

        if (!iteration) {
          this.error = s__('Iterations|Unable to find iteration.');
          return null;
        }

        this.title = iteration.title;
        this.description = iteration.description;
        this.startDate = parsePikadayDate(iteration.startDate);
        this.dueDate = parsePikadayDate(iteration.dueDate);
        this.automatic = iteration.iterationCadence.automatic;

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
      startDate: null,
      dueDate: null,
      automatic: null,
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
    isAutoModeEdit() {
      return this.isEditing && this.automatic;
    },
    formattedStartDate() {
      return formatDate(this.startDate, 'yyyy-mm-dd');
    },
    formattedDueDate() {
      return formatDate(this.dueDate, 'yyyy-mm-dd');
    },
    formattedDates() {
      return {
        startDate: this.formattedStartDate,
        dueDate: this.formattedDueDate,
      };
    },
    createVariables() {
      return {
        groupPath: this.fullPath,
        title: this.title,
        description: this.description,
        ...this.formattedDates,
      };
    },
    updateVariables() {
      const baseVariables = {
        id: this.iterationId,
        groupPath: this.fullPath,
        description: this.description,
      };

      return this.automatic
        ? baseVariables
        : { ...baseVariables, title: this.title, ...this.formattedDates };
    },
  },
  async mounted() {
    // prefill start date for the New cadence form
    // if there's iterations in the cadence, use last end_date + 1
    // else use cadence startDate
    if (!this.isEditing && this.cadenceId) {
      const { data } = await this.$apollo.query({
        query: iterationsInCadence,
        variables: {
          fullPath: this.fullPath,
          iterationCadenceId: convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, this.cadenceId),
          lastPageSize: 1,
          state: STATUS_ALL,
        },
      });
      const iteration = data.workspace.iterations?.nodes[0];

      if (iteration) {
        this.startDate = dayAfter(new Date(iteration.dueDate), { utc: true });
      } else {
        const { data: cadenceData } = await this.$apollo.query({
          query: readCadence,
          variables: {
            fullPath: this.fullPath,
            id: convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, this.cadenceId),
          },
        });

        if (cadenceData.group) {
          const cadence = cadenceData.group?.iterationCadences?.nodes[0];

          if (!cadence) {
            this.error = s__('Iterations|Unable to find iteration cadence.');
            return;
          }

          this.startDate = cadence.startDate ? new Date(cadence.startDate) : null;
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
              ...this.createVariables,
              iterationsCadenceId: convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, this.cadenceId),
            },
          },
        })
        .then(({ data }) => {
          const { iteration, errors } = data.iterationCreate;

          if (errors.length > 0) {
            this.loading = false;
            createAlert({
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
          createAlert({
            message: __('Unable to save iteration. Please try again'),
          });
        });
    },
    updateIteration() {
      return this.$apollo
        .mutate({
          mutation: updateIteration,
          variables: {
            input: this.updateVariables,
          },
        })
        .then(({ data }) => {
          const { errors } = data.updateIteration;
          if (errors.length > 0) {
            createAlert({
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
          createAlert({
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
        {{ isEditing ? $options.i18n.title.edit : $options.i18n.title.new }}
      </h1>
    </div>
    <hr class="gl-mt-0" />

    <gl-alert v-if="error" class="gl-mb-5" variant="danger" @dismiss="error = ''">{{
      error
    }}</gl-alert>
    <gl-form class="common-note-form">
      <p v-if="isAutoModeEdit && title">
        <span class="gl-font-weight-bold gl-display-block gl-pb-3">{{
          $options.i18n.form.title
        }}</span>
        <span>{{ title }}</span>
      </p>
      <gl-form-group
        v-else-if="!automatic || !isEditing"
        :label="$options.i18n.form.title"
        label-for="iteration-title"
      >
        <gl-form-input
          id="iteration-title"
          v-model="title"
          autocomplete="off"
          data-qa-selector="iteration_title_field"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.form.startDate" label-for="iteration-start-date">
        <span v-if="isAutoModeEdit">{{ formattedStartDate }}</span>
        <gl-datepicker
          v-else
          input-id="iteration-start-date"
          data-testid="start-date"
          :value="startDate"
          show-clear-button
          autocomplete="off"
          data-qa-selector="iteration_start_date_field"
          @input="updateStartDate"
          @clear="updateStartDate(null)"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.form.dueDate" label-for="iteration-due-date">
        <span v-if="isAutoModeEdit">{{ formattedDueDate }}</span>
        <gl-datepicker
          v-else
          input-id="iteration-due-date"
          data-testid="due-date"
          :value="dueDate"
          show-clear-button
          autocomplete="off"
          data-qa-selector="iteration_due_date_field"
          @input="updateDueDate"
          @clear="updateDueDate(null)"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.form.description" label-for="iteration-description">
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
              :aria-label="$options.i18n.form.description"
              data-qa-selector="iteration_description_field"
            >
            </textarea>
          </template>
        </markdown-field>
      </gl-form-group>
    </gl-form>
    <div class="form-actions d-flex">
      <gl-button
        :loading="loading"
        data-testid="save-iteration"
        variant="confirm"
        data-qa-selector="save_iteration_button"
        @click="save"
      >
        {{ isEditing ? $options.i18n.submitButton.save : $options.i18n.submitButton.create }}
      </gl-button>
      <gl-button class="gl-ml-3" data-testid="cancel-iteration" :to="$options.cadencesList">
        {{ $options.i18n.cancelButton }}
      </gl-button>
    </div>
  </div>
</template>
