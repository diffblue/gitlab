<script>
import { GlAvatarLabeled, GlButton, GlFormInput, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';

import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { SEARCH_DEBOUNCE } from '../constants';

export default {
  components: {
    GlAvatarLabeled,
    GlButton,
    GlFormInput,
    GlCollapsibleListbox,
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
    selectedGroupId() {
      return this.selectedGroup?.id || this.parentItem?.numericalId;
    },
    canShowParentGroup() {
      if (!this.searchTerm) {
        return true;
      }

      return fuzzaldrinPlus.filter([this.parentItem.groupName], this.searchTerm).length === 1;
    },
    listBoxItems() {
      const items = [];

      if (this.canShowParentGroup) {
        items.push({
          value: this.parentItem.numericalId,
          text: this.parentItem.groupName,
          name: this.parentItem.groupName,
          path: this.parentItem.fullPath,
        });
      }

      return [
        ...items,
        ...this.descendantGroups.map((group) => ({ value: group.id, text: group.name, ...group })),
      ];
    },
  },
  watch: {
    searchTerm() {
      this.handleDropdownShow();
    },
  },
  created() {
    this.handleSearch = debounce(this.setSearchTerm, SEARCH_DEBOUNCE);
  },
  destroyed() {
    this.handleSearch.cancel();
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
    setSearchTerm(term = '') {
      this.searchTerm = term.trim();
    },
    selectGroup(groupId) {
      this.selectedGroup = this.descendantGroups.find(({ id }) => id === groupId);
    },
  },
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
        <gl-collapsible-listbox
          block
          class="dropdown-descendant-groups"
          searchable
          is-check-centered
          fluid-width
          :items="listBoxItems"
          :searching="descendantGroupsFetchInProgress"
          :selected="selectedGroupId"
          :toggle-text="dropdownPlaceholderText"
          @search="handleSearch"
          @shown="handleDropdownShow"
          @select="selectGroup"
        >
          <template #list-item="{ item }">
            <gl-avatar-labeled
              :entity-name="item.name"
              :label="item.name"
              :sub-label="item.path"
              :src="item.avatar_url"
              :size="32"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            />
          </template>
        </gl-collapsible-listbox>
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
