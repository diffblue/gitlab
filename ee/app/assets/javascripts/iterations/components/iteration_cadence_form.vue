<script>
import {
  GlAlert,
  GlButton,
  GlDatepicker,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
} from '@gitlab/ui';
import { TYPE_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__, __ } from '~/locale';
import createCadence from '../queries/cadence_create.mutation.graphql';
import updateCadence from '../queries/cadence_update.mutation.graphql';
import readCadence from '../queries/iteration_cadence.query.graphql';

const i18n = Object.freeze({
  title: {
    label: s__('Iterations|Title'),
    placeholder: s__('Iterations|Cadence name'),
  },
  automatedScheduling: {
    label: s__('Iterations|Automated scheduling'),
    description: s__('Iterations|Iteration scheduling will be handled automatically'),
  },
  startDate: {
    label: s__('Iterations|Start date'),
    placeholder: s__('Iterations|Select start date'),
    description: s__('Iterations|The start date of your first iteration'),
  },
  duration: {
    label: s__('Iterations|Duration'),
    description: s__('Iterations|The duration for each iteration (in weeks)'),
    placeholder: s__('Iterations|Select duration'),
  },
  rollOver: {
    label: s__('Iterations|Roll over issues'),
    description: s__('Iterations|Move incomplete issues to the next iteration'),
  },
  futureIterations: {
    label: s__('Iterations|Future iterations'),
    description: s__('Iterations|Number of future iterations you would like to have scheduled'),
    placeholder: s__('Iterations|Select number'),
  },
  description: {
    label: __('Description'),
  },
  edit: {
    title: s__('Iterations|Edit iteration cadence'),
    save: s__('Iterations|Save cadence'),
  },
  new: {
    title: s__('Iterations|New iteration cadence'),
    save: s__('Iterations|Create cadence'),
  },
  createAndStartIteration: s__('Iterations|Create cadence and start iteration'),
  cancel: __('Cancel'),
  requiredField: __('This field is required.'),
});

export default {
  availableDurations: [{ value: 0, text: i18n.duration.placeholder }, 1, 2, 3, 4, 5, 6],
  availableFutureIterations: [
    { value: 0, text: i18n.futureIterations.placeholder },
    2,
    4,
    6,
    8,
    10,
  ],

  components: {
    GlAlert,
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  inject: ['fullPath', 'cadencesListPath'],
  data() {
    return {
      group: {
        loading: false,
        iterationCadences: {
          nodes: [],
        },
      },
      loading: false,
      errorMessage: '',
      title: '',
      automatic: true,
      rollOver: false,
      startDate: null,
      durationInWeeks: 0,
      iterationsInAdvance: 0,
      description: '',
      validationState: {
        title: null,
        startDate: null,
        durationInWeeks: null,
        iterationsInAdvance: null,
      },
      i18n,
    };
  },
  computed: {
    loadingCadence() {
      return this.$apollo.queries.group.loading;
    },
    cadenceId() {
      return this.$router.currentRoute.params.cadenceId;
    },
    isEdit() {
      return Boolean(this.cadenceId);
    },
    page() {
      return this.isEdit ? 'edit' : 'new';
    },
    showStartIteration() {
      return !this.isEdit && !this.automatic;
    },
    mutation() {
      return this.isEdit ? updateCadence : createCadence;
    },
    valid() {
      return !Object.values(this.validationState).includes(false);
    },
    variables() {
      const id = this.isEdit
        ? convertToGraphQLId(TYPE_ITERATIONS_CADENCE, this.cadenceId)
        : undefined;
      const groupPath = this.isEdit ? undefined : this.fullPath;

      const vars = {
        input: {
          groupPath,
          id,
          title: this.title,
          automatic: this.automatic,
          rollOver: this.rollOver,
          startDate: this.startDate,
          durationInWeeks: this.durationInWeeks,
          active: true,
          iterationsInAdvance: this.iterationsInAdvance,
          description: this.description,
        },
      };

      return vars;
    },
  },
  apollo: {
    group: {
      skip() {
        return !this.isEdit;
      },
      query: readCadence,
      variables() {
        return {
          fullPath: this.fullPath,
          id: this.cadenceId,
        };
      },
      result({ data: { group, errors }, error }) {
        if (error) {
          return;
        }

        if (errors?.length) {
          [this.errorMessage] = errors;
          return;
        }
        const cadence = group?.iterationCadences?.nodes?.[0];

        if (!cadence) {
          this.errorMessage = s__("Iterations|Couldn't find iteration cadence");
          return;
        }

        this.title = cadence.title;
        this.automatic = cadence.automatic;
        this.startDate = cadence.startDate;
        this.durationInWeeks = cadence.durationInWeeks;
        this.rollOver = cadence.rollOver;
        this.iterationsInAdvance = cadence.iterationsInAdvance;
        this.description = cadence.description;
      },
      error(error) {
        this.errorMessage = error;
      },
    },
  },
  methods: {
    validate(field) {
      this.validationState[field] = Boolean(this[field]);
    },
    validateAllFields() {
      Object.keys(this.validationState)
        .filter((field) => {
          if (this.automatic) {
            return true;
          }
          const requiredFieldsForAutomatedScheduling = [
            'iterationsInAdvance',
            'durationInWeeks',
            'startDate',
          ];
          return !requiredFieldsForAutomatedScheduling.includes(field);
        })
        .forEach((field) => {
          this.validate(field);
        });
    },
    clearValidation() {
      this.validationState.startDate = null;
      this.validationState.durationInWeeks = null;
      this.validationState.iterationsInAdvance = null;
    },
    updateAutomatic(value) {
      this.clearValidation();
      if (!value) {
        this.startDate = null;
        this.iterationsInAdvance = 0;
        this.durationInWeeks = 0;
      }
    },
    saveAndCreateIteration() {
      return this.save()
        .then((cadenceId) => {
          this.$router.push({ name: 'newIteration', params: { cadenceId } });
        })
        .catch((error) => {
          this.errorMessage = error ?? s__('Iterations|Unable to save cadence. Please try again.');
        });
    },
    saveAndViewList() {
      return this.save()
        .then((cadenceId) => {
          this.$router.push({
            name: 'index',
            query: { createdCadenceId: getIdFromGraphQLId(cadenceId) },
          });
        })
        .catch((error) => {
          this.errorMessage = error ?? s__('Iterations|Unable to save cadence. Please try again.');
        });
    },
    save() {
      return new Promise((resolve, reject) => {
        this.validateAllFields();

        if (!this.valid) {
          return reject(new Error(s__('Iterations|Cadence configuration is invalid.')));
        }

        return resolve();
      })
        .then(() => {
          this.loading = true;
          return this.saveCadence();
        })
        .finally(() => {
          this.loading = false;
        });
    },
    cancel() {
      this.$router.push({ name: 'index' });
    },
    saveCadence() {
      return this.$apollo
        .mutate({
          mutation: this.mutation,
          variables: this.variables,
        })
        .then(({ data } = {}) => {
          const { iterationCadence, errors } = data?.result || {};

          if (errors?.length > 0) {
            throw new Error(errors);
          }

          return getIdFromGraphQLId(iterationCadence.id);
        });
    },
  },
};
</script>

<template>
  <article>
    <div class="gl-display-flex">
      <h3 ref="pageTitle" class="page-title">
        {{ i18n[page].title }}
      </h3>
    </div>
    <gl-form>
      <gl-alert v-if="errorMessage" class="gl-mb-5" variant="danger" @dismiss="errorMessage = ''">{{
        errorMessage
      }}</gl-alert>

      <gl-form-group
        :label="i18n.title.label"
        :label-cols-md="2"
        label-class="text-right-md gl-pt-3!"
        label-for="cadence-title"
        :invalid-feedback="i18n.requiredField"
        :state="validationState.title"
      >
        <gl-form-input
          id="cadence-title"
          v-model="title"
          autocomplete="off"
          data-qa-selector="iteration_cadence_title_field"
          :placeholder="i18n.title.placeholder"
          size="xl"
          :state="validationState.title"
          :disabled="loadingCadence"
          @blur="validate('title')"
        />
      </gl-form-group>

      <gl-form-group
        :label-cols-md="2"
        label-class="gl-font-weight-bold text-right-md gl-pt-3!"
        label-for="cadence-automated-scheduling"
        :description="i18n.automatedScheduling.description"
      >
        <gl-form-checkbox
          id="cadence-automated-scheduling"
          v-model="automatic"
          data-qa-selector="iteration_cadence_automated_scheduling_checkbox"
          :disabled="loadingCadence"
          @change="updateAutomatic"
        >
          <span class="gl-font-weight-bold">{{ i18n.automatedScheduling.label }}</span>
        </gl-form-checkbox>
      </gl-form-group>

      <gl-form-group
        :label="i18n.startDate.label"
        :label-cols-md="2"
        label-class="text-right-md gl-pt-3!"
        label-for="cadence-start-date"
        :description="i18n.startDate.description"
        :invalid-feedback="i18n.requiredField"
        :state="validationState.startDate"
      >
        <gl-datepicker :target="null">
          <gl-form-input
            id="cadence-start-date"
            v-model="startDate"
            :placeholder="i18n.startDate.placeholder"
            class="datepicker gl-datepicker-input"
            autocomplete="off"
            inputmode="none"
            :required="automatic"
            :disabled="loadingCadence || !automatic"
            :state="validationState.startDate"
            data-qa-selector="iteration_cadence_start_date_field"
            @blur="validate('startDate')"
          />
        </gl-datepicker>
      </gl-form-group>

      <gl-form-group
        :label="i18n.duration.label"
        :label-cols-md="2"
        label-class="text-right-md gl-pt-3!"
        label-for="cadence-duration"
        :description="i18n.duration.description"
        :invalid-feedback="i18n.requiredField"
        :state="validationState.durationInWeeks"
      >
        <gl-form-select
          id="cadence-duration"
          v-model.number="durationInWeeks"
          :options="$options.availableDurations"
          class="gl-form-input-md"
          :required="automatic"
          :disabled="loadingCadence || !automatic"
          @change="validate('durationInWeeks')"
        />
      </gl-form-group>

      <gl-form-group
        :label="i18n.futureIterations.label"
        :label-cols-md="2"
        :content-cols-md="2"
        label-class="text-right-md gl-pt-3!"
        label-for="cadence-schedule-future-iterations"
        :description="i18n.futureIterations.description"
        :invalid-feedback="i18n.requiredField"
        :state="validationState.iterationsInAdvance"
      >
        <gl-form-select
          id="cadence-schedule-future-iterations"
          v-model.number="iterationsInAdvance"
          :disabled="!automatic || loadingCadence"
          :options="$options.availableFutureIterations"
          :required="automatic"
          class="gl-form-input-md"
          @change="validate('iterationsInAdvance')"
        />
      </gl-form-group>

      <gl-form-group
        :label-cols-md="2"
        label-class="gl-font-weight-bold text-right-md gl-pt-3!"
        label-for="cadence-rollover-issues"
        :description="i18n.rollOver.description"
      >
        <gl-form-checkbox id="cadence-rollover-issues" v-model="rollOver" @change="clearValidation">
          <span class="gl-font-weight-bold">{{ i18n.rollOver.label }}</span>
        </gl-form-checkbox>
      </gl-form-group>

      <gl-form-group
        :label="i18n.description.label"
        :label-cols-md="2"
        :content-cols-md="2"
        label-class="text-right-md gl-pt-3!"
        label-for="cadence-description"
      >
        <gl-form-textarea
          id="cadence-description"
          v-model="description"
          class="w-100"
          data-qa-selector="iteration_cadence_description_field"
        />
      </gl-form-group>

      <div class="form-actions gl-display-flex gl-flex-wrap">
        <gl-button
          :loading="loading"
          data-testid="save-cadence"
          variant="confirm"
          data-qa-selector="save_iteration_cadence_button"
          @click="saveAndViewList"
        >
          {{ i18n[page].save }}
        </gl-button>
        <gl-button
          v-if="showStartIteration"
          :loading="loading"
          class="gl-ml-3"
          data-testid="save-cadence-create-iteration"
          variant="confirm"
          category="secondary"
          data-qa-selector="save_cadence_start_iteration_button"
          @click="saveAndCreateIteration"
        >
          {{ i18n.createAndStartIteration }}
        </gl-button>
        <gl-button class="gl-ml-3" data-testid="cancel-create-cadence" @click="cancel">
          {{ i18n.cancel }}
        </gl-button>
      </div>
    </gl-form>
  </article>
</template>
