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
import { s__, __, sprintf } from '~/locale';
import { getDayName } from '~/lib/utils/datetime_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import createCadence from '../queries/cadence_create.mutation.graphql';
import updateCadence from '../queries/cadence_update.mutation.graphql';
import readCadence from '../queries/iteration_cadence.query.graphql';
import iterationsInCadence from '../queries/group_iterations_in_cadence.query.graphql';
import { iterationStates } from '../constants';

const i18n = Object.freeze({
  automatedScheduling: {
    heading: s__('Iterations|Automatic scheduling'),
    text: s__('Iterations|Create iterations automatically on a regular schedule.'),
  },
  title: {
    label: s__('Iterations|Title'),
    placeholder: s__('Iterations|Cadence name'),
  },
  effectiveDate: {
    label: s__('Iterations|First iteration start date'),
    placeholder: s__('Iterations|Select start date'),
    labelDescription: s__(
      'Iterations|The start date of the first iteration determines when your cadence begins.',
    ),
    description: s__('Iterations|Iterations are scheduled to start on %{weekday}s.'),
  },
  duration: {
    label: s__('Iterations|Duration'),
    labelDescription: s__('Iterations|The duration of each iteration (in weeks).'),
    placeholder: s__('Iterations|Select duration'),
  },
  rollOver: {
    label: s__('Iterations|Roll over issues'),
    checkboxLabel: s__('Iterations|Enable roll over'),
    description: s__('Iterations|Move incomplete issues to the next iteration.'),
  },
  upcomingIterations: {
    label: s__('Iterations|Upcoming iterations'),
    labelDescription: s__(
      'Iterations|Number of upcoming iterations that should be scheduled at a time.',
    ),
    placeholder: s__('Iterations|Select number'),
  },
  description: {
    label: __('Description'),
    optional: __('(optional)'),
  },
  edit: {
    title: s__('Iterations|Edit iteration cadence'),
    save: s__('Iterations|Save changes'),
  },
  new: {
    title: s__('Iterations|New iteration cadence'),
    save: s__('Iterations|Create cadence'),
  },
  cancel: __('Cancel'),
  requiredField: __('This field is required.'),
  deprecationAlert: {
    title: s__('Iterations|This cadence can be converted to use automated scheduling'),
    message: s__(
      'Iterations|To convert this cadence to automatic scheduling, add a duration and number of upcoming iterations. The upgrade is irreversible.',
    ),
    primaryButtonText: s__('Iterations|Learn more about automatic scheduling'),
  },
});

export default {
  iterationCadencesHelpPagePath: helpPagePath('user/group/iterations/index.md', {
    anchor: 'iteration-cadences',
  }),
  availableDurations: [{ value: 0, text: i18n.duration.placeholder }, 1, 2, 3, 4],
  availableUpcomingIterations: [
    { value: 0, text: i18n.upcomingIterations.placeholder },
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
      iterations: [],
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
    effectiveDateDescription() {
      if (this.startDate === null) return '';

      return sprintf(this.i18n.effectiveDate.description, {
        effectiveDate: this.effectiveDate,
        weekday: getDayName(new Date(this.startDate)),
      });
    },
    loadingCadence() {
      return this.$apollo.queries.group.loading;
    },
    cadenceId() {
      return this.$router.currentRoute.params.cadenceId;
    },
    isEdit() {
      return Boolean(this.cadenceId);
    },
    startDateEditable() {
      if (this.iterations.length === 0) {
        return true;
      }

      const firstIterationUpcoming = this.iterations[0].state === iterationStates.upcoming;
      if (firstIterationUpcoming) return true;

      return false;
    },
    isStartDateDisabled() {
      if (this.loadingCadence) return true;

      return this.isEdit && !this.startDateEditable;
    },
    page() {
      return this.isEdit ? 'edit' : 'new';
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
          automatic: true,
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
  mounted() {
    this.$apollo.queries.iterations.refetch();
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
          id: convertToGraphQLId(TYPE_ITERATIONS_CADENCE, this.cadenceId),
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

        if (!cadence.automatic) {
          this.validateAllFields();
        }
      },
      error(error) {
        this.errorMessage = error;
      },
    },
    iterations: {
      query: iterationsInCadence,
      skip() {
        return !this.isEdit || this.loadingCadence;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iterationCadenceId: convertToGraphQLId(TYPE_ITERATIONS_CADENCE, this.cadenceId),
          firstPageSize: 1,
          state: iterationStates.all,
        };
      },
      update({ workspace } = {}) {
        if (!workspace) return [];

        return workspace.iterations?.nodes || [];
      },
      result() {
        if (!this.automatic) {
          this.startDate = this.iterations[0].startDate;
        }
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
      Object.keys(this.validationState).forEach((field) => {
        this.validate(field);
      });
    },
    clearValidation() {
      this.validationState.startDate = null;
      this.validationState.durationInWeeks = null;
      this.validationState.iterationsInAdvance = null;
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
          reject(new Error(s__('Iterations|Cadence configuration is invalid.')));
        }

        resolve();
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
      <h1 ref="pageTitle" class="page-title gl-font-size-h-display">
        {{ i18n[page].title }}
      </h1>
    </div>
    <hr class="gl-mt-0" />

    <gl-form>
      <gl-alert
        v-if="isEdit && !automatic"
        :dismissible="false"
        class="gl-mb-5"
        variant="danger"
        :title="i18n.deprecationAlert.title"
        :primary-button-text="i18n.deprecationAlert.primaryButtonText"
        :primary-button-link="$options.iterationCadencesHelpPagePath"
        >{{ i18n.deprecationAlert.message }}</gl-alert
      >
      <gl-alert v-if="errorMessage" class="gl-mb-5" variant="danger" @dismiss="errorMessage = ''">{{
        errorMessage
      }}</gl-alert>

      <gl-form-group
        class="gl-pt-3"
        :label="i18n.title.label"
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
          :state="validationState.title"
          :disabled="loadingCadence"
          @blur="validate('title')"
        />
      </gl-form-group>

      <gl-form-group
        class="gl-pt-3"
        :label="i18n.description.label"
        :content-cols-md="2"
        :optional-text="i18n.optional"
        label-for="cadence-description"
        optional
      >
        <gl-form-textarea
          id="cadence-description"
          v-model="description"
          data-qa-selector="iteration_cadence_description_field"
        />
      </gl-form-group>

      <h4 class="gl-pt-3">{{ i18n.automatedScheduling.heading }}</h4>
      <p>{{ i18n.automatedScheduling.text }}</p>

      <div class="gl-pt-4 gl-px-4 gl-border gl-rounded-base gl-mt-4 gl-mb-6">
        <gl-form-group
          class="gl-pt-3"
          :label="i18n.effectiveDate.label"
          :label-description="i18n.effectiveDate.labelDescription"
          label-for="cadence-start-date"
          :description="effectiveDateDescription"
          :invalid-feedback="i18n.requiredField"
          :state="validationState.startDate"
        >
          <gl-datepicker :target="null">
            <gl-form-input
              id="cadence-start-date"
              v-model="startDate"
              :placeholder="i18n.effectiveDate.placeholder"
              class="gl-datepicker-input"
              autocomplete="off"
              inputmode="none"
              :disabled="isStartDateDisabled"
              :state="validationState.startDate"
              data-qa-selector="iteration_cadence_start_date_field"
              @blur="validate('startDate')"
            />
          </gl-datepicker>
        </gl-form-group>

        <gl-form-group
          class="gl-pt-3"
          :label="i18n.duration.label"
          :label-description="i18n.duration.labelDescription"
          label-for="cadence-duration"
          :invalid-feedback="i18n.requiredField"
          :state="validationState.durationInWeeks"
        >
          <gl-form-select
            id="cadence-duration"
            v-model.number="durationInWeeks"
            :options="$options.availableDurations"
            class="gl-form-input-md"
            :disabled="loadingCadence"
            data-qa-selector="iteration_cadence_duration_field"
            @change="validate('durationInWeeks')"
          />
        </gl-form-group>

        <gl-form-group
          class="gl-pt-3"
          :label="i18n.upcomingIterations.label"
          :label-description="i18n.upcomingIterations.labelDescription"
          label-for="cadence-schedule-upcoming-iterations"
          :invalid-feedback="i18n.requiredField"
          :state="validationState.iterationsInAdvance"
        >
          <gl-form-select
            id="cadence-schedule-upcoming-iterations"
            v-model.number="iterationsInAdvance"
            :disabled="loadingCadence"
            :options="$options.availableUpcomingIterations"
            class="gl-form-input-md"
            data-qa-selector="iteration_cadence_upcoming_iterations_field"
            @change="validate('iterationsInAdvance')"
          />
        </gl-form-group>

        <gl-form-group
          class="gl-pt-3"
          :label="i18n.rollOver.label"
          label-class="gl-font-weight-bold"
          label-for="cadence-rollover-issues"
          :description="i18n.rollOver.description"
        >
          <gl-form-checkbox
            id="cadence-rollover-issues"
            v-model="rollOver"
            @change="clearValidation"
          >
            <span>{{ i18n.rollOver.checkboxLabel }}</span>
          </gl-form-checkbox>
        </gl-form-group>
      </div>

      <div class="gl-display-flex gl-flex-wrap">
        <gl-button
          :loading="loading"
          data-testid="save-cadence"
          variant="confirm"
          data-qa-selector="save_iteration_cadence_button"
          :disabled="!valid"
          @click="saveAndViewList"
        >
          {{ i18n[page].save }}
        </gl-button>
        <gl-button class="gl-ml-3" data-testid="cancel-create-cadence" @click="cancel">
          {{ i18n.cancel }}
        </gl-button>
      </div>
    </gl-form>
  </article>
</template>
