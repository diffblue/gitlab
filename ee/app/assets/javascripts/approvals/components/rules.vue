<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { __, s__ } from '~/locale';

const HEADERS = {
  name: s__('ApprovalRule|Name'),
  members: s__('ApprovalRule|Approvers'),
  approvalsRequired: s__('ApprovalRule|Approvals required'),
  branches: __('Target branch'),
};

export default {
  props: {
    rules: {
      type: Array,
      required: true,
    },
  },
  HEADERS,
};
</script>

<template>
  <table class="table b-table gl-table b-table-stacked-md gl-m-0">
    <thead class="text-nowrap">
      <slot name="thead" v-bind="$options.HEADERS"></slot>
    </thead>
    <tbody>
      <slot name="tbody" :rules="rules"></slot>
    </tbody>
  </table>
</template>
