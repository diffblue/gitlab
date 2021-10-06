<script>
import {
  GlButton,
  GlCard,
  GlFormGroup,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlTooltipDirective,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { s__ } from '~/locale';

export default {
  i18n: {
    editProfileLabel: s__('DastProfiles|Edit profile'),
  },
  name: 'OnDemandScansProfileSelector',
  components: {
    GlButton,
    GlCard,
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    libraryPath: {
      type: String,
      required: true,
    },
    newProfilePath: {
      type: String,
      required: true,
    },
    profiles: {
      type: Array,
      required: false,
      default: () => [],
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return { searchTerm: '' };
  },
  computed: {
    selectedProfile() {
      return this.value ? this.profiles.find(({ id }) => this.value === id) : null;
    },
    filteredProfiles() {
      if (this.searchTerm) {
        return fuzzaldrinPlus.filter(this.profiles, this.searchTerm, {
          key: ['profileName'],
        });
      }
      return this.profiles;
    },
    filteredProfilesEmpty() {
      return this.filteredProfiles.length === 0;
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <div class="row">
        <div class="col-7 gl-display-flex gl-align-items-center">
          <h3 class="gl-font-lg gl-my-0">
            <slot name="title"></slot>
          </h3>
        </div>
      </div>
    </template>
    <gl-form-group v-if="profiles.length">
      <template #label>
        <slot name="label"></slot>
      </template>

      <gl-dropdown
        :text="
          selectedProfile
            ? selectedProfile.dropdownLabel
            : s__('OnDemandScans|Select one of the existing profiles')
        "
        class="mw-460"
        data-testid="profiles-dropdown"
      >
        <template #header>
          <gl-search-box-by-type v-model.trim="searchTerm" />
        </template>
        <gl-dropdown-item
          v-for="profile in filteredProfiles"
          :key="profile.id"
          :is-checked="value === profile.id"
          is-check-item
          @click="$emit('input', profile.id)"
        >
          {{ profile.profileName }}
        </gl-dropdown-item>
        <div v-show="filteredProfilesEmpty" class="gl-p-3 gl-text-center">
          {{ __('No matching results...') }}
        </div>
        <template #footer>
          <gl-dropdown-item :href="newProfilePath" data-testid="create-profile-option">
            <slot name="new-profile"></slot>
          </gl-dropdown-item>
          <gl-dropdown-item :href="libraryPath" data-testid="manage-profiles-option">
            <slot name="manage-profile"></slot>
          </gl-dropdown-item>
        </template>
      </gl-dropdown>

      <div
        v-if="selectedProfile && $scopedSlots.summary"
        data-testid="selected-profile-summary"
        class="gl-mt-6 gl-pt-6 gl-border-t-solid gl-border-gray-100 gl-border-t-1"
      >
        <gl-button
          v-if="selectedProfile"
          v-gl-tooltip
          category="primary"
          icon="pencil"
          :title="$options.i18n.editProfileLabel"
          :aria-label="$options.i18n.editProfileLabel"
          :href="selectedProfile.editPath"
          class="gl-absolute gl-right-7 gl-z-index-1"
        />
        <slot name="summary"></slot>
      </div>
    </gl-form-group>
    <template v-else>
      <p class="gl-text-gray-700">
        <slot name="no-profiles"></slot>
      </p>
      <gl-button
        :href="newProfilePath"
        variant="confirm"
        category="secondary"
        data-testid="create-profile-link"
      >
        <slot name="new-profile"></slot>
      </gl-button>
    </template>
  </gl-card>
</template>
