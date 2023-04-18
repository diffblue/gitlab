<script>
import {
  GlAvatar,
  GlButton,
  GlFormInput,
  GlDropdown,
  GlSearchBoxByType,
  GlDropdownItem,
  GlLoadingIcon,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { mapState, mapActions } from 'vuex';

import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { SEARCH_DEBOUNCE } from '../constants';

export default {
  components: {
    GlButton,
    GlFormInput,
    GlDropdown,
    GlSearchBoxByType,
    GlDropdownItem,
    GlAvatar,
    GlLoadingIcon,
  },
  props: {
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      inputValue: '',
      searchTerm: '',
      selectedGroup: null,
    };
  },
  computed: {
    ...mapState([
      'descendantGroupsFetchInProgress',
      'itemCreateInProgress',
      'descendantGroups',
      'parentItem',
    ]),
    isSubmitButtonDisabled() {
      return this.inputValue.length === 0 || this.isSubmitting;
    },
    buttonLabel() {
      return this.isSubmitting ? __('Creating epic') : __('Create epic');
    },
    dropdownPlaceholderText() {
      return this.selectedGroup?.name || this.parentItem?.groupName || __('Search a group');
    },
    canRenderNoResults() {
      return !this.descendantGroupsFetchInProgress && !this.descendantGroups?.length;
    },
    canRenderSearchResults() {
      return !this.descendantGroupsFetchInProgress;
    },
    canShowParentGroup() {
      if (!this.searchTerm) {
        return true;
      }

      return fuzzaldrinPlus.filter([this.parentItem.groupName], this.searchTerm).length === 1;
    },
  },
  watch: {
    searchTerm() {
      this.handleDropdownShow();
    },

    descendantGroupsFetchInProgress(value) {
      if (!value) {
        this.$nextTick(() => {
          this.$refs.searchInputField.focusInput();
        });
      }
    },
  },
  mounted() {
    this.$nextTick()
      .then(() => {
        this.$refs.input.focus();
      })
      .catch(() => {});
  },

  methods: {
    ...mapActions(['fetchDescendantGroups']),
    onFormSubmit() {
      const groupFullPath = this.selectedGroup?.full_path;
      this.$emit('createEpicFormSubmit', { value: this.inputValue.trim(), groupFullPath });
    },
    onFormCancel() {
      this.$emit('createEpicFormCancel');
    },
    handleDropdownShow() {
      const {
        parentItem: { groupId },
        searchTerm,
      } = this;
      this.fetchDescendantGroups({ groupId, search: searchTerm });
    },
  },
  debounce: SEARCH_DEBOUNCE,
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <div class="row mb-3">
      <div class="col-sm">
        <label class="label-bold">{{ s__('Issue|Title') }}</label>
        <gl-form-input
          ref="input"
          v-model="inputValue"
          :placeholder="
            parentItem.confidential ? __('New confidential epic title ') : __('New epic title')
          "
          type="text"
          class="form-control"
          @keyup.escape.exact="onFormCancel"
        />
      </div>
      <div class="col-sm">
        <label class="label-bold">{{ __('Group') }}</label>

        <gl-dropdown
          block
          :text="dropdownPlaceholderText"
          class="dropdown-descendant-groups"
          menu-class="w-100 gl-pt-0"
          @show="handleDropdownShow"
        >
          <gl-search-box-by-type
            ref="searchInputField"
            v-model.trim="searchTerm"
            :disabled="descendantGroupsFetchInProgress"
            :debounce="$options.debounce"
          />

          <gl-loading-icon
            v-show="descendantGroupsFetchInProgress"
            class="projects-fetch-loading align-items-center p-2"
            size="lg"
          />

          <template v-if="canRenderSearchResults">
            <gl-dropdown-item
              v-if="canShowParentGroup"
              data-testid="parent-group-item"
              class="w-100"
              @click="selectedGroup = null"
            >
              <gl-avatar
                :entity-name="parentItem.groupName"
                :shape="$options.AVATAR_SHAPE_OPTION_RECT"
                :size="32"
                class="d-inline-flex"
              />
              <div class="d-inline-flex flex-column">
                {{ parentItem.groupName }}
                <div class="text-secondary">{{ parentItem.fullPath }}</div>
              </div>
            </gl-dropdown-item>

            <gl-dropdown-item
              v-for="group in descendantGroups"
              :key="group.id"
              class="w-100"
              @click="selectedGroup = group"
            >
              <gl-avatar
                :src="group.avatar_url"
                :entity-name="group.name"
                :shape="$options.AVATAR_SHAPE_OPTION_RECT"
                :size="32"
                class="d-inline-flex"
              />
              <div class="d-inline-flex flex-column">
                {{ group.name }}
                <div class="text-secondary">{{ group.path }}</div>
              </div>
            </gl-dropdown-item>
          </template>

          <gl-dropdown-item v-if="canRenderNoResults && !canShowParentGroup">{{
            __('No matching results')
          }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
    </div>

    <div class="gl-mt-5">
      <gl-button
        :disabled="isSubmitButtonDisabled"
        :loading="isSubmitting"
        variant="confirm"
        category="primary"
        type="submit"
        size="small"
        class="gl-mr-2"
      >
        {{ buttonLabel }}
      </gl-button>
      <gl-button size="small" @click="onFormCancel">{{ __('Cancel') }}</gl-button>
    </div>
  </form>
</template>
