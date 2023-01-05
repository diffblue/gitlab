<script>
import { GlModal, GlAlert } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { s__, __ } from '~/locale';
import {
  updateStoreOnEscalationPolicyCreate,
  updateStoreOnEscalationPolicyUpdate,
} from '../graphql/cache_updates';
import createEscalationPolicyMutation from '../graphql/mutations/create_escalation_policy.mutation.graphql';
import updateEscalationPolicyMutation from '../graphql/mutations/update_escalation_policy.mutation.graphql';
import getEscalationPoliciesQuery from '../graphql/queries/get_escalation_policies.query.graphql';
import { isNameFieldValid, getRulesValidationState, serializeRule, getRules } from '../utils';
import AddEditEscalationPolicyForm from './add_edit_escalation_policy_form.vue';

export const i18n = {
  cancel: __('Cancel'),
  addEscalationPolicy: s__('EscalationPolicies|Add escalation policy'),
  editEscalationPolicy: s__('EscalationPolicies|Edit escalation policy'),
  saveChanges: __('Save changes'),
};

export default {
  i18n,
  components: {
    GlModal,
    GlAlert,
    AddEditEscalationPolicyForm,
  },
  inject: ['projectPath'],
  props: {
    escalationPolicy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      form: this.getInitialState(),
      initialState: this.getInitialState(),
      validationState: {
        name: null,
        rules: [],
      },
      error: null,
    };
  },
  computed: {
    title() {
      return this.isEditMode ? i18n.editEscalationPolicy : i18n.addEscalationPolicy;
    },
    primaryBtnText() {
      return this.isEditMode ? i18n.saveChanges : i18n.addEscalationPolicy;
    },
    actionsProps() {
      return {
        primary: {
          text: this.primaryBtnText,
          attributes: {
            variant: 'confirm',
            loading: this.loading,
            disabled: !this.isFormValid || !this.isFormDirty,
          },
        },
        cancel: {
          text: i18n.cancel,
        },
      };
    },
    isFormValid() {
      return (
        this.validationState.name &&
        (this.isEditMode ? true : this.validationState.rules.length) &&
        this.validationState.rules.every(
          ({ isTimeValid, isScheduleValid, isUserValid }) =>
            isTimeValid && isScheduleValid && isUserValid,
        )
      );
    },
    isFormDirty() {
      return (
        this.form.name !== this.initialState.name ||
        this.form.description !== this.initialState.description ||
        !isEqual(getRules(this.form.rules), getRules(this.initialState.rules))
      );
    },
    requestParams() {
      const id = this.isEditMode ? { id: this.escalationPolicy.id } : {};
      return { ...this.form, ...id, rules: getRules(this.form.rules).map(serializeRule) };
    },
  },
  methods: {
    getInitialState() {
      return {
        name: this.escalationPolicy.name ?? '',
        description: this.escalationPolicy.description ?? '',
        rules: this.escalationPolicy.rules ?? [],
      };
    },
    updateForm({ field, value }) {
      this.form = { ...this.form, [field]: value };
      this.validateForm(field);
    },
    createEscalationPolicy() {
      this.loading = true;
      const { projectPath } = this;
      this.$apollo
        .mutate({
          mutation: createEscalationPolicyMutation,
          variables: {
            input: {
              projectPath,
              ...this.requestParams,
            },
          },
          update(store, { data }) {
            updateStoreOnEscalationPolicyCreate(store, getEscalationPoliciesQuery, data, {
              projectPath,
            });
          },
        })
        .then(
          ({
            data: {
              escalationPolicyCreate: {
                errors: [error],
              },
            },
          }) => {
            if (error) {
              throw error;
            }
            this.$refs.addUpdateEscalationPolicyModal.hide();
            this.$emit('policy-created');
            this.resetForm();
          },
        )
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    updateEscalationPolicy() {
      this.loading = true;
      const { projectPath } = this;
      this.$apollo
        .mutate({
          mutation: updateEscalationPolicyMutation,
          variables: {
            input: this.requestParams,
          },
          update(store, { data }) {
            updateStoreOnEscalationPolicyUpdate(store, getEscalationPoliciesQuery, data, {
              projectPath,
            });
          },
        })
        .then(
          ({
            data: {
              escalationPolicyUpdate: {
                errors: [error],
              },
            },
          }) => {
            if (error) {
              throw error;
            }
            this.$refs.addUpdateEscalationPolicyModal.hide();
            this.resetForm();
          },
        )
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    validateForm(field) {
      if (field === 'name') {
        this.validationState.name = isNameFieldValid(this.form.name);
      }
      if (field === 'rules') {
        this.validationState.rules = getRulesValidationState(this.form.rules);
      }
    },
    hideErrorAlert() {
      this.error = null;
    },
    resetForm() {
      this.form = this.getInitialState();

      this.validationState = {
        name: null,
        rules: [],
      };
      this.hideErrorAlert();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="addUpdateEscalationPolicyModal"
    class="escalation-policy-modal"
    :modal-id="modalId"
    :title="title"
    :action-primary="actionsProps.primary"
    :action-cancel="actionsProps.cancel"
    scrollable
    @primary.prevent="isEditMode ? updateEscalationPolicy() : createEscalationPolicy()"
    @canceled="resetForm"
    @close="resetForm"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mt-n3 gl-mb-3" @dismiss="hideErrorAlert">
      {{ error }}
    </gl-alert>
    <add-edit-escalation-policy-form
      :validation-state="validationState"
      :form="form"
      @update-escalation-policy-form="updateForm"
    />
  </gl-modal>
</template>
