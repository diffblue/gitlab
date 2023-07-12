<script>
import { GlFormInput, GlFormGroup, GlButton, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import {
  GROUP_TOGGLE_TEXT,
  GROUP_HEADER_TEXT,
  FETCH_GROUPS_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import { groupsPath } from '~/vue_shared/components/entity_select/utils';

export const limitExclusionEndpoint = '/api/:version/namespaces/:id/storage/limit_exclusion';
export default {
  name: 'ExcludedNamespacesForm',
  components: {
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlAlert,
    EntitySelect,
  },
  i18n: {
    idLabel: s__('NamespaceLimits|Exclude namespace'),
    reasonLabel: s__('NamespaceLimits|Reason'),
    reasonPlaceholder: s__(`NamespaceLimits|Reason for excluding this namespace`),
    toggleText: GROUP_TOGGLE_TEXT,
    selectGroup: GROUP_HEADER_TEXT,
  },
  data() {
    return {
      excludedId: null,
      excludingReason: '',
      errorMessage: '',
    };
  },
  methods: {
    resetInputs() {
      this.$refs.entitySelect.onReset();
      this.excludingReason = '';
    },
    hasValidInputs() {
      return Boolean(this.excludedId && this.excludingReason);
    },
    submit(event) {
      event.preventDefault();

      // reset any error message before submitting the request
      this.errorMessage = '';

      // validate excludedId and excludingReason before proceeding with actual submission
      if (!this.hasValidInputs()) {
        this.errorMessage = s__(
          'NamespaceLimits|You must select a namespace and add a reason for excluding it',
        );
        return;
      }

      const endpoint = Api.buildUrl(limitExclusionEndpoint).replace(':id', this.excludedId);
      axios
        .post(endpoint, { reason: this.excludingReason })
        .then(() => {
          this.resetInputs();

          this.$emit('added');

          this.$toast.show(s__('NamespaceLimits|Exclusion added successfully'));
        })
        .catch((error) => {
          if (error.response?.data?.message) {
            this.errorMessage = `${error.response?.data?.message}`;
          } else {
            this.errorMessage = error;
          }
        });
    },
    async fetchGroups(searchString = '', page = 1) {
      let groups = [];
      let totalPages = 0;
      try {
        const { data = [], headers } = await axios.get(Api.buildUrl(groupsPath()), {
          params: {
            search: searchString,
            per_page: DEFAULT_PER_PAGE,
            page,
          },
        });
        groups = data.map((group) => ({
          ...group,
          text: group.full_name,
          value: String(group.id),
        }));

        totalPages = parseIntPagination(normalizeHeaders(headers)).totalPages;
      } catch (error) {
        this.errorMessage = FETCH_GROUPS_ERROR;
      }
      return { items: groups, totalPages };
    },
    handleEntitySelectInput({ value }) {
      this.excludedId = value;
    },
  },
};
</script>

<template>
  <form @submit="submit">
    <entity-select
      ref="entitySelect"
      :label="$options.i18n.idLabel"
      input-name="excluded_namespace_id"
      input-id="excluded_namespace_id"
      :header-text="$options.i18n.selectGroup"
      :default-toggle-text="$options.i18n.toggleText"
      :fetch-items="fetchGroups"
      clearable
      @input="handleEntitySelectInput"
    >
      <template #list-item="{ item }">
        <span class="gl-display-block gl-font-weight-bold">
          {{ item.full_name }}
        </span>
        <span class="gl-display-block gl-mt-1 gl-text-gray-300">
          {{ item.full_path }}
        </span>
      </template>
    </entity-select>

    <gl-form-group :label="$options.i18n.reasonLabel">
      <gl-form-input
        v-model="excludingReason"
        :placeholder="$options.i18n.reasonPlaceholder"
        size="xl"
        autocomplete="off"
        required
      />
    </gl-form-group>

    <gl-alert v-if="errorMessage" class="gl-mb-4" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>

    <gl-button variant="confirm" type="submit" class="js-no-auto-disable">{{
      s__('NamespaceLimits|Exclude')
    }}</gl-button>
  </form>
</template>
