<script>
import {
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlLink,
  GlFormInput,
} from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import ImportGroupDropdown from '../../components/group_dropdown.vue';
import { STATUSES } from '../../constants';

export default {
  components: {
    ImportGroupDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlLink,
    GlFormInput,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    availableNamespaces: {
      type: Array,
      required: true,
    },
    groupPathRegex: {
      type: RegExp,
      required: true,
    },
    groupUrlErrorMessage: {
      type: String,
      required: true,
    },
  },

  computed: {
    availableNamespaceNames() {
      return this.availableNamespaces.map((ns) => ns.full_path);
    },

    importTarget() {
      return this.group.import_target;
    },

    invalidNameValidationMessage() {
      return this.group.validation_errors.find(({ field }) => field === 'new_name')?.message;
    },

    isInvalid() {
      return Boolean(!this.isNameValid || this.invalidNameValidationMessage);
    },

    isNameValid() {
      return this.groupPathRegex.test(this.importTarget.new_name);
    },

    isAlreadyImported() {
      return this.group.progress.status !== STATUSES.NONE;
    },

    isFinished() {
      return this.group.progress.status === STATUSES.FINISHED;
    },

    fullPath() {
      return `${this.importTarget.target_namespace}/${this.importTarget.new_name}`;
    },

    absolutePath() {
      return joinPaths(gon.relative_url_root || '/', this.fullPath);
    },
  },

  i18n: {
    NAME_ALREADY_EXISTS: s__('BulkImport|Name already exists.'),
  },
};
</script>

<template>
  <gl-link
    v-if="isFinished"
    class="gl-display-flex gl-align-items-center gl-h-7"
    :href="absolutePath"
  >
    {{ fullPath }}
  </gl-link>

  <div
    v-else
    class="import-entities-target-select gl-display-flex gl-align-items-stretch"
    :class="{
      disabled: isAlreadyImported,
    }"
  >
    <import-group-dropdown
      #default="{ namespaces }"
      :text="importTarget.target_namespace"
      :disabled="isAlreadyImported"
      :namespaces="availableNamespaceNames"
      toggle-class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
      class="import-entities-namespace-dropdown gl-h-7 gl-flex-grow-1"
      data-qa-selector="target_namespace_selector_dropdown"
    >
      <gl-dropdown-item @click="$emit('update-target-namespace', '')">{{
        s__('BulkImport|No parent')
      }}</gl-dropdown-item>
      <template v-if="namespaces.length">
        <gl-dropdown-divider />
        <gl-dropdown-section-header>
          {{ s__('BulkImport|Existing groups') }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="ns in namespaces"
          :key="ns"
          data-qa-selector="target_group_dropdown_item"
          :data-qa-group-name="ns"
          @click="$emit('update-target-namespace', ns)"
        >
          {{ ns }}
        </gl-dropdown-item>
      </template>
    </import-group-dropdown>
    <div
      class="import-entities-target-select-separator gl-h-7 gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1"
    >
      /
    </div>
    <div class="gl-flex-grow-1">
      <gl-form-input
        class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
        :class="{ 'is-invalid': isInvalid && !isAlreadyImported }"
        :disabled="isAlreadyImported"
        :value="importTarget.new_name"
        @input="$emit('update-new-name', $event)"
      />
      <p v-if="isInvalid" class="gl-text-red-500 gl-m-0 gl-mt-2">
        <template v-if="!isNameValid">
          {{ groupUrlErrorMessage }}
        </template>
        <template v-else-if="invalidNameValidationMessage">
          {{ invalidNameValidationMessage }}
        </template>
      </p>
    </div>
  </div>
</template>
