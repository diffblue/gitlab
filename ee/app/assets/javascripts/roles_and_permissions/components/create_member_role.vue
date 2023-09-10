<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlFormTextarea,
} from '@gitlab/ui';
import { createMemberRole } from 'ee/rest_api';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_GUEST_INTEGER } from '~/access_level/constants';
import { createAlert, VARIANT_DANGER } from '~/alert';
import {
  I18N_CANCEL,
  I18N_CREATE_ROLE,
  I18N_CREATION_ERROR,
  I18N_FIELD_FORM_ERROR,
  I18N_NEW_ROLE_BASE_ROLE_DESCRIPTION,
  I18N_NEW_ROLE_BASE_ROLE_LABEL,
  I18N_NEW_ROLE_DESCRIPTION_LABEL,
  I18N_NEW_ROLE_NAME_DESCRIPTION,
  I18N_NEW_ROLE_NAME_LABEL,
  I18N_NEW_ROLE_NAME_PLACEHOLDER,
  I18N_NEW_ROLE_PERMISSIONS_LABEL,
  PERMISSIONS,
} from '../constants';

export default {
  name: 'CreateMemberRole',
  components: {
    GlButton,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  props: {
    groupId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      // Remove the default `Guest` role when additional base access roles are supported.
      baseRole: `${ACCESS_LEVEL_GUEST_INTEGER}`,
      baseRoleValid: true,
      description: '',
      name: '',
      nameValid: true,
      permissions: [],
      permissionsValid: null,
    };
  },
  computed: {
    availablePermissions() {
      return this.baseRole ? Object.values(PERMISSIONS[this.baseRole]) : [];
    },
  },
  methods: {
    areFieldsValid() {
      this.baseRoleValid = true;
      this.nameValid = true;
      this.permissionsValid = null;

      if (!this.baseRole) {
        this.baseRoleValid = false;
      }

      if (!this.name) {
        this.nameValid = false;
      }

      if (this.permissions.length === 0) {
        this.permissionsValid = false;
      }

      if (this.baseRoleValid && this.nameValid && this.permissionsValid === null) {
        return true;
      }

      return false;
    },
    cancel() {
      this.$emit('cancel');
    },
    async createMemberRole() {
      this.alert?.dismiss();

      if (!this.areFieldsValid()) {
        return;
      }

      const data = {
        base_access_level: this.baseRole,
        name: this.name,
        description: this.description,
      };
      this.permissions.forEach((permission) => {
        data[permission] = 1;
      });

      try {
        await createMemberRole(this.groupId, data);
        this.$emit('success');
      } catch (error) {
        this.alert = createAlert({
          message: error?.response?.data?.message || I18N_CREATION_ERROR,
          variant: VARIANT_DANGER,
        });
      }
    },
  },
  baseRoleOptions: Object.keys(PERMISSIONS).map((accessLevel) => ({
    text: ACCESS_LEVEL_LABELS[accessLevel],
    value: accessLevel,
  })),
  i18n: {
    baseRole: {
      id: 'group-1',
      label: I18N_NEW_ROLE_BASE_ROLE_LABEL,
      description: I18N_NEW_ROLE_BASE_ROLE_DESCRIPTION,
    },
    cancel: I18N_CANCEL,
    createRole: I18N_CREATE_ROLE,
    description: {
      id: 'group-2',
      label: I18N_NEW_ROLE_DESCRIPTION_LABEL,
    },
    fieldFormError: I18N_FIELD_FORM_ERROR,
    name: {
      id: 'group-3',
      label: I18N_NEW_ROLE_NAME_LABEL,
      placeholder: I18N_NEW_ROLE_NAME_PLACEHOLDER,
      description: I18N_NEW_ROLE_NAME_DESCRIPTION,
    },
    permissions: {
      label: I18N_NEW_ROLE_PERMISSIONS_LABEL,
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="createMemberRole">
    <h4 class="gl-mt-0">{{ $options.i18n.createRole }}</h4>
    <div class="row">
      <gl-form-group
        class="col-md-4"
        :label="$options.i18n.baseRole.label"
        :description="$options.i18n.baseRole.description"
        :invalid-feedback="$options.i18n.fieldFormError"
        :label-for="$options.i18n.baseRole.id"
      >
        <gl-form-select
          :id="$options.i18n.baseRole.id"
          v-model="baseRole"
          :options="$options.baseRoleOptions"
          required
          :state="baseRoleValid"
        />
      </gl-form-group>

      <gl-form-group
        class="col-md-4"
        :label="$options.i18n.name.label"
        :description="$options.i18n.name.description"
        :invalid-feedback="$options.i18n.fieldFormError"
        :label-for="$options.i18n.name.id"
      >
        <gl-form-input
          :id="$options.i18n.name.id"
          v-model="name"
          :placeholder="$options.i18n.name.placeholder"
          :state="nameValid"
        />
      </gl-form-group>

      <gl-form-group
        class="col-lg-8"
        :label="$options.i18n.description.label"
        :label-for="$options.i18n.description.id"
      >
        <gl-form-textarea :id="$options.i18n.description.id" v-model="description" />
      </gl-form-group>
    </div>

    <gl-form-group :label="$options.i18n.permissions.label">
      <gl-form-checkbox-group v-model="permissions" :state="permissionsValid">
        <gl-form-checkbox
          v-for="permission in availablePermissions"
          :key="permission.value"
          :value="permission.value"
        >
          {{ permission.text }}
          <template v-if="permission.help" #help>
            {{ permission.help }}
          </template>
        </gl-form-checkbox>
      </gl-form-checkbox-group>
    </gl-form-group>

    <div class="gl-display-flex gl-flex-wrap gl-gap-3">
      <gl-button
        type="submit"
        data-testid="submit-button"
        variant="confirm"
        class="js-no-auto-disable"
        >{{ $options.i18n.createRole }}</gl-button
      >
      <gl-button type="reset" data-testid="cancel-button" @click="cancel">{{
        $options.i18n.cancel
      }}</gl-button>
    </div>
  </gl-form>
</template>
