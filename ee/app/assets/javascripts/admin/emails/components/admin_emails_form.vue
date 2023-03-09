<script>
import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlButton,
  GlCollapsibleListbox,
  GlAlert,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import { getGroups, getProjects } from '~/rest_api';
import { __, s__ } from '~/locale';
import validation, { initForm } from '~/vue_shared/directives/validation';
import csrf from '~/lib/utils/csrf';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
  },
};

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlButton,
    GlCollapsibleListbox,
    GlAlert,
  },
  directives: {
    validation: validation(feedbackMap),
  },
  csrf,
  inject: ['adminEmailPath', 'adminEmailsAreCurrentlyRateLimited'],
  fields: {
    subject: {
      label: s__('AdminEmail|Subject'),
      validationMessage: s__('AdminEmail|Subject is required.'),
      key: 'subject',
    },
    body: {
      label: s__('AdminEmail|Body'),
      validationMessage: s__('AdminEmail|Body is required.'),
      key: 'body',
    },
    recipients: {
      label: s__('AdminEmail|Recipient group or project'),
      validationMessage: s__('AdminEmail|Recipient group or project is required.'),
      noResultsMessage: s__('AdminEmail|No groups or projects found.'),
      loadingMessage: s__('AdminEmail|Loading groups and projects.'),
      key: 'recipients',
    },
  },
  i18n: {
    submitButton: __('Send message'),
    errorMessage: s__(
      'AdminEmail|An error occurred fetching the groups and projects. Please refresh the page to try again.',
    ),
  },
  data() {
    const form = initForm({
      fields: {
        subject: {
          value: '',
        },
        body: {
          value: '',
        },
        recipients: {
          value: null,
          id: null,
        },
      },
    });

    return {
      form,
      recipientsSearchTerm: '',
      items: [],
      recipientsLoading: false,
      recipientsSearchLoading: false,
      hasError: false,
    };
  },

  computed: {
    listboxToggleText() {
      if (this.form.fields.recipients.value === null) {
        return __('Select group or project');
      }

      return null;
    },
    recipientsValue() {
      return this.form.fields.recipients.value ?? null;
    },
    recipientsNoResultsText() {
      if (this.recipientsLoading) {
        return this.$options.fields.recipients.loadingMessage;
      }

      return this.$options.fields.recipients.noResultsMessage;
    },
  },
  watch: {
    'form.fields.recipients.value': async function watchRecipientsValue(value) {
      if (value === null) {
        return;
      }

      // Wait for `v-validation` to update `this.form.fields.recipients.state`
      await this.$nextTick();

      this.form.fields.recipients.state = null;
    },
  },
  methods: {
    async handleSubmit(event) {
      this.form.showValidation = true;

      // Wait for `v-validation` to update `this.form.state`
      await this.$nextTick();

      if (!this.form.state) {
        event.preventDefault();

        return;
      }

      this.form.showValidation = false;
    },
    async handleListboxSearch(searchTerm) {
      this.recipientsSearchTerm = searchTerm;

      this.recipientsSearchLoading = true;

      this.debouncedSearch();
    },
    debouncedSearch: debounce(async function debouncedSearch() {
      await this.fetchListboxItems();

      this.recipientsSearchLoading = false;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    async handleListboxShown() {
      this.recipientsLoading = true;

      await this.fetchListboxItems();

      this.recipientsLoading = false;
    },
    async fetchListboxItems() {
      const groupsFetch = getGroups(this.recipientsSearchTerm, {});
      const projectsFetch = getProjects(this.recipientsSearchTerm, {
        order_by: 'id',
        membership: false,
      });

      try {
        const [{ data: projects }, groups] = await Promise.all([projectsFetch, groupsFetch]);

        const all = {
          text: __('All groups and projects'),
          value: 'all',
        };

        this.items = [
          ...(this.recipientsSearchTerm === '' ? [all] : []),
          ...groups.map((item) => ({
            text: item.full_name,
            value: `group-${item.id}`,
          })),
          ...projects.map((item) => ({
            text: item.name_with_namespace,
            value: `project-${item.id}`,
          })),
        ];
      } catch (error) {
        this.hasError = true;
      }
    },
  },
};
</script>

<template>
  <gl-form
    class="gl-lg-form-input-xl"
    novalidate
    :action="adminEmailPath"
    method="post"
    @submit="handleSubmit"
  >
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    <gl-form-group
      :label="$options.fields.subject.label"
      :label-for="$options.fields.subject.key"
      :state="form.fields.subject.state"
      :invalid-feedback="form.fields.subject.feedback"
    >
      <gl-form-input
        :id="$options.fields.subject.key"
        v-model="form.fields.subject.value"
        v-validation:[form.showValidation]
        :validation-message="$options.fields.subject.validationMessage"
        :state="form.fields.subject.state"
        :name="$options.fields.subject.key"
        required
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.fields.body.label"
      :label-for="$options.fields.body.key"
      :state="form.fields.body.state"
      :invalid-feedback="form.fields.body.feedback"
    >
      <gl-form-textarea
        :id="$options.fields.body.key"
        v-model="form.fields.body.value"
        v-validation:[form.showValidation]
        :validation-message="$options.fields.body.validationMessage"
        :state="form.fields.body.state"
        :name="$options.fields.body.key"
        required
      />
    </gl-form-group>
    <gl-alert v-if="hasError" class="gl-mb-5" variant="danger" :dismissible="false">{{
      $options.i18n.errorMessage
    }}</gl-alert>
    <gl-form-group
      :label="$options.fields.recipients.label"
      :state="form.fields.recipients.state"
      :invalid-feedback="form.fields.recipients.feedback"
    >
      <gl-form-input
        id="recipients"
        v-validation:[form.showValidation]
        :validation-message="$options.fields.recipients.validationMessage"
        class="gl-display-none"
        name="recipients"
        :value="recipientsValue"
        required
      />
      <gl-collapsible-listbox
        v-model="form.fields.recipients.value"
        searchable
        :loading="recipientsLoading"
        :searching="recipientsSearchLoading"
        :no-results-text="recipientsNoResultsText"
        :toggle-text="listboxToggleText"
        :items="items"
        @shown="handleListboxShown"
        @search="handleListboxSearch"
      />
    </gl-form-group>
    <gl-button
      class="js-no-auto-disable"
      type="submit"
      :disabled="adminEmailsAreCurrentlyRateLimited"
      category="primary"
      variant="confirm"
      >{{ $options.i18n.submitButton }}</gl-button
    >
  </gl-form>
</template>
