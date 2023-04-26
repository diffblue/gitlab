<script>
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { Tracking } from '~/sidebar/constants';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { weightQueries, MAX_DISPLAY_WEIGHT } from '../../constants';

export default {
  tracking: {
    event: Tracking.editEvent,
    label: Tracking.rightSidebarLabel,
    property: 'weight',
  },
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLoadingIcon,
    SidebarEditableItem,
  },
  directives: {
    autofocusonshow,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canUpdate'],
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      issuable: {},
      loading: false,
      oldIid: null,
      localWeight: '',
    };
  },
  apollo: {
    issuable: {
      query() {
        return weightQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable || {};
      },
      error() {
        createAlert({
          message: sprintf(__('Something went wrong while setting %{issuableType} weight.'), {
            issuableType: this.issuableType,
          }),
        });
      },
      result({ data }) {
        this.localWeight = data?.workspace.issuable.weight ?? '';
      },
      subscribeToMore: {
        document() {
          return weightQueries[this.issuableType].subscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return this.skipIssueWeightSubscription;
        },
      },
    },
  },
  computed: {
    weight() {
      return this.issuable.weight ?? null;
    },
    isLoading() {
      return this.$apollo.queries?.issuable?.loading || this.loading;
    },
    hasWeight() {
      return this.weight !== null;
    },
    weightLabel() {
      return this.hasWeight ? this.weight : this.$options.i18n.noWeightLabel;
    },
    tooltipTitle() {
      let tooltipTitle = this.$options.i18n.weight;

      if (this.hasWeight) {
        tooltipTitle += ` ${this.weight}`;
      }

      return tooltipTitle;
    },
    collapsedWeightLabel() {
      return this.hasWeight
        ? this.weight.toString().substr(0, 5)
        : this.$options.i18n.noWeightLabel;
    },
    issuableId() {
      return this.issuable.id;
    },
    skipIssueWeightSubscription() {
      return this.issuableType !== TYPE_ISSUE || !this.issuableId || this.isLoading;
    },
  },
  watch: {
    iid(_, oldVal) {
      this.oldIid = oldVal;
    },
  },
  methods: {
    setWeight(remove) {
      const shouldRemoveWeight = remove || this.localWeight === '';
      const weight = shouldRemoveWeight ? null : this.localWeight;
      const currentIid = shouldRemoveWeight ? this.iid : this.oldIid || this.iid;
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: weightQueries[this.issuableType].mutation,
          variables: {
            input: {
              projectPath: this.fullPath,
              iid: currentIid,
              weight,
            },
          },
        })
        .then(({ data: { issuableSetWeight } }) => {
          if (issuableSetWeight.errors?.length) {
            createAlert({
              message: issuableSetWeight.errors[0],
            });
          } else {
            this.$emit('weightUpdated', {
              weight: issuableSetWeight?.issuable?.weight,
              id: issuableSetWeight?.issuable?.id,
            });
          }
        })
        .catch(() => {
          createAlert({
            message: sprintf(__('Something went wrong while setting %{issuableType} weight.'), {
              issuableType: this.issuableType,
            }),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    expandSidebar() {
      this.$refs.editable.expand();
      this.$emit('expandSidebar');
    },
    handleFormSubmit() {
      this.$refs.editable.collapse({ emitEvent: false });
      this.setWeight();
    },
  },
  i18n: {
    weight: __('Weight'),
    noWeightLabel: __('None'),
    removeWeight: __('remove weight'),
    inputPlaceholder: __('Enter a number'),
  },
  maxDisplayWeight: MAX_DISPLAY_WEIGHT,
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="$options.i18n.weight"
    :tracking="$options.tracking"
    :loading="isLoading"
    class="block weight"
    data-testid="sidebar-weight"
    @open="oldIid = null"
    @close="setWeight()"
  >
    <template #collapsed>
      <div class="gl-display-flex gl-align-items-center hide-collapsed">
        <span
          :class="hasWeight ? 'gl-text-gray-900 gl-font-weight-bold' : 'gl-text-gray-500'"
          data-testid="sidebar-weight-value"
          data-qa-selector="weight_label_value"
        >
          {{ weightLabel }}
        </span>
        <div v-if="hasWeight && canUpdate" class="gl-display-flex">
          <span class="gl-mx-2">-</span>
          <gl-button
            variant="link"
            class="gl-text-gray-500!"
            :disabled="loading"
            @click="setWeight(true)"
          >
            {{ $options.i18n.removeWeight }}
          </gl-button>
        </div>
      </div>
      <div
        v-gl-tooltip.left.viewport
        :title="tooltipTitle"
        class="sidebar-collapsed-icon js-weight-collapsed-block"
        @click="expandSidebar"
      >
        <gl-icon :size="16" name="weight" />
        <gl-loading-icon v-if="isLoading" class="js-weight-collapsed-loading-icon" />
        <span
          v-else
          class="js-weight-collapsed-weight-label collapse-truncated-title gl-pt-2 gl-px-3 gl-font-sm"
        >
          {{ collapsedWeightLabel }}
          <template v-if="weight > $options.maxDisplayWeight">&hellip;</template>
        </span>
      </div>
    </template>
    <template #default>
      <gl-form @submit.prevent="handleFormSubmit()">
        <gl-form-group :label="__('Weight')" label-for="weight-input" label-sr-only>
          <gl-form-input
            id="weight-input"
            v-model.number="localWeight"
            v-autofocusonshow
            type="number"
            min="0"
            :placeholder="$options.i18n.inputPlaceholder"
          />
        </gl-form-group>
      </gl-form>
    </template>
  </sidebar-editable-item>
</template>
