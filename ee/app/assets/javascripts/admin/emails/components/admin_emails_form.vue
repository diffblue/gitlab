<script>
import {
  GlForm,
  GlFormTextarea,
  GlButton,
  GlCollapsibleListbox,
  GlAlert,
  GlFormFields,
} from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';

import { getGroups, getProjects } from '~/rest_api';
import { __, s__ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export default {
  components: {
    GlForm,
    GlFormFields,
    GlFormTextarea,
    GlButton,
    GlCollapsibleListbox,
    GlAlert,
  },
  csrf,
  inject: ['adminEmailPath', 'adminEmailsAreCurrentlyRateLimited'],
  i18n: {
    submitButton: __('Send message'),
    errorMessage: s__(
      'AdminEmail|An error occurred fetching the groups and projects. Please refresh the page to try again.',
    ),
    noResultsMessage: s__('AdminEmail|No groups or projects found.'),
    loadingMessage: s__('AdminEmail|Loading groups and projects.'),
  },
  data() {
    return {
      recipientsSearchTerm: '',
      items: [],
      recipientsLoading: false,
      recipientsSearchLoading: false,
      hasError: false,
      formValues: {},
    };
  },
  computed: {
    listboxToggleText() {
      if (!this.formValues.recipients) {
        return __('Select group or project');
      }

      return null;
    },
    recipientsNoResultsText() {
      if (this.recipientsLoading) {
        return this.$options.i18n.loadingMessage;
      }

      return this.$options.i18n.noResultsMessage;
    },
  },
  methods: {
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
  fields: {
    subject: {
      label: s__('AdminEmail|Subject'),
      validators: [formValidators.required(s__('AdminEmail|Subject is required.'))],
      inputAttrs: { name: 'subject' },
    },
    body: {
      label: s__('AdminEmail|Body'),
      validators: [formValidators.required(s__('AdminEmail|Body is required.'))],
      inputAttrs: { name: 'body' },
    },
    recipients: {
      label: s__('AdminEmail|Recipient group or project'),
      validators: [
        formValidators.required(s__('AdminEmail|Recipient group or project is required.')),
      ],
      inputAttrs: { name: 'recipients' },
    },
  },
  formId: 'admin-emails-form',
};
</script>

<template>
  <gl-form
    :id="$options.formId"
    ref="form"
    class="gl-lg-form-input-xl"
    :action="adminEmailPath"
    method="post"
  >
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    <gl-form-fields
      v-model="formValues"
      :fields="$options.fields"
      :form-id="$options.formId"
      @submit="$refs.form.$el.submit()"
    >
      <template #input(body)="{ id, value, input, blur, validation }">
        <gl-form-textarea
          :id="id"
          :value="value"
          :state="validation.state"
          :name="$options.fields.body.inputAttrs.name"
          @input="input"
          @blur="blur"
        />
      </template>
      <template #input(recipients)="{ id, value, input, blur }">
        <gl-alert v-if="hasError" class="gl-mb-5" variant="danger" :dismissible="false">{{
          $options.i18n.errorMessage
        }}</gl-alert>
        <input type="hidden" :name="$options.fields.recipients.inputAttrs.name" :value="value" />
        <gl-collapsible-listbox
          :id="id"
          :selected="value"
          searchable
          :loading="recipientsLoading"
          :searching="recipientsSearchLoading"
          :no-results-text="recipientsNoResultsText"
          :toggle-text="listboxToggleText"
          :items="items"
          @shown="handleListboxShown"
          @search="handleListboxSearch"
          @select="input"
          @hidden="blur"
        />
      </template>
    </gl-form-fields>
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
