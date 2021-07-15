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
import createFlash from '~/flash';
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
      weight: null,
      loading: false,
    };
  },
  apollo: {
    weight: {
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
        return data.workspace?.issuable?.weight;
      },
      result({ data }) {
        this.$emit('weightUpdated', data.workspace?.issuable?.weight);
      },
      error() {
        createFlash({
          message: sprintf(__('Something went wrong while setting %{issuableType} weight.'), {
            issuableType: this.issuableType,
          }),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries?.weight?.loading || this.loading;
    },
    hasWeight() {
      return this.weight != null;
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
  },
  methods: {
    setWeight(remove) {
      const shouldRemoveWeight = remove || this.weight === '';
      const weight = shouldRemoveWeight ? null : this.weight;
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: weightQueries[this.issuableType].mutation,
          variables: {
            input: {
              projectPath: this.fullPath,
              iid: this.iid,
              weight,
            },
          },
        })
        .then(
          ({
            data: {
              issuableSetWeight: { errors },
            },
          }) => {
            if (errors.length) {
              createFlash({
                message: errors[0],
              });
            }
          },
        )
        .catch(() => {
          createFlash({
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
        <span v-else class="js-weight-collapsed-weight-label">
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
            v-model.number="weight"
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
