<script>
import { GlFormGroup, GlButton } from '@gitlab/ui';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import updateStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/update_active_step.mutation.graphql';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import stepListQuery from 'ee/vue_shared/purchase_flow/graphql/queries/step_list.query.graphql';
import createFlash from '~/flash';
import { convertToSnakeCase, dasherize } from '~/lib/utils/text_utility';
import { GENERAL_ERROR_MESSAGE } from '../constants';
import StepHeader from './step_header.vue';
import StepSummary from './step_summary.vue';

export default {
  components: {
    GlFormGroup,
    GlButton,
    StepHeader,
    StepSummary,
  },
  props: {
    stepId: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    isValid: {
      type: Boolean,
      required: true,
    },
    nextStepButtonText: {
      type: String,
      required: false,
      default: '',
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['nextStep', 'stepEdit'],
  data() {
    return {
      activeStep: {},
      stepList: [],
      loading: false,
    };
  },
  apollo: {
    activeStep: {
      query: activeStepQuery,
      error(error) {
        this.handleError(error);
      },
    },
    stepList: {
      query: stepListQuery,
    },
  },
  computed: {
    isActive() {
      return this.activeStep.id === this.stepId;
    },
    isFinished() {
      return this.isValid && !this.isActive;
    },
    isEditable() {
      const index = this.stepList.findIndex(({ id }) => id === this.stepId);
      const activeIndex = this.stepList.findIndex(({ id }) => id === this.activeStep.id);
      return this.isFinished && index < activeIndex;
    },
    dasherizedStep() {
      return dasherize(convertToSnakeCase(this.stepId));
    },
  },
  methods: {
    handleError(error) {
      createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
    },
    async nextStep() {
      if (!this.isValid) {
        return;
      }
      this.loading = true;
      await this.$apollo
        .mutate({
          mutation: activateNextStepMutation,
        })
        .catch((error) => {
          this.handleError(error);
        })
        .finally(() => {
          this.loading = false;
          this.$emit('nextStep');
        });
    },
    async edit() {
      this.loading = true;
      this.$emit('stepEdit', this.stepId);
      await this.$apollo
        .mutate({
          mutation: updateStepMutation,
          variables: { id: this.stepId },
        })
        .catch((error) => {
          this.handleError(error);
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>
<template>
  <div class="mb-3 mb-lg-5 gl-w-full">
    <step-header :title="title" :is-finished="isFinished" />
    <div class="card" :class="dasherizedStep">
      <div v-show="isActive" @keyup.enter="nextStep">
        <slot name="body" :active="isActive"></slot>
        <gl-form-group
          v-if="nextStepButtonText"
          :invalid-feedback="errorMessage"
          :state="isValid"
          :class="[!isValid && errorMessage ? 'gl-mb-5' : 'gl-mb-0', 'gl-mt-3']"
        />
        <gl-button
          v-if="nextStepButtonText"
          variant="success"
          category="primary"
          :disabled="!isValid"
          @click="nextStep"
        >
          {{ nextStepButtonText }}
        </gl-button>
      </div>
      <step-summary v-if="isFinished" :is-editable="isEditable" :edit="edit">
        <slot name="summary"></slot>
      </step-summary>
    </div>
  </div>
</template>
