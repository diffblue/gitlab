<script>
import { __ } from '~/locale';
import BranchDetails from '../shared/branch_details.vue';
import DrawerSectionHeader from '../shared/drawer_section_header.vue';

export default {
  components: {
    BranchDetails,
    DrawerSectionHeader,
  },
  props: {
    sourceBranch: {
      type: String,
      required: false,
      default: '',
    },
    sourceBranchUri: {
      type: String,
      required: false,
      default: '',
    },
    targetBranch: {
      type: String,
      required: false,
      default: '',
    },
    targetBranchUri: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    header: __('Path'),
  },
  computed: {
    sourceBranchOpts() {
      return {
        name: this.sourceBranch,
        uri: this.sourceBranchUri,
      };
    },
    targeBranchOpts() {
      return {
        name: this.targetBranch,
        uri: this.targetBranchUri,
      };
    },
  },
};
</script>
<template>
  <div>
    <drawer-section-header>{{ $options.i18n.header }}</drawer-section-header>
    <branch-details
      class="gl-justify-content-start gl-text-gray-500"
      :source-branch="sourceBranchOpts"
      :target-branch="targeBranchOpts"
    />
  </div>
</template>
