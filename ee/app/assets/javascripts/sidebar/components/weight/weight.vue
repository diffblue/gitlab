<script>
import { GlLoadingIcon, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import $ from 'jquery';
import { __, s__ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Tracking from '~/tracking';
import { MAX_DISPLAY_WEIGHT } from '../../constants';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin({ label: 'right_sidebar' })],
  props: {
    fetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    weight: {
      type: [String, Number],
      required: false,
      default: '',
    },
    weightNoneValue: {
      type: String,
      required: true,
      default: __('None'),
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    id: {
      type: [String, Number],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      hasValidInput: true,
      shouldShowEditField: false,
      collapsedAfterUpdate: false,
    };
  },
  computed: {
    tracking() {
      return {
        // eslint-disable-next-line no-underscore-dangle
        category: this.$options._componentTag,
      };
    },
    isNoValue() {
      return this.checkIfNoValue(this.weight);
    },
    collapsedWeightLabel() {
      return this.checkIfNoValue(this.weight)
        ? this.noValueLabel
        : this.weight.toString().substr(0, 5);
    },
    noValueLabel() {
      return s__('Sidebar|None');
    },
    dropdownToggleLabel() {
      return this.checkIfNoValue(this.weight) ? s__('Sidebar|Weight') : this.weight;
    },
    shouldShowWeight() {
      return !this.fetching && !this.shouldShowEditField;
    },
    tooltipTitle() {
      let tooltipTitle = s__('Sidebar|Weight');

      if (!this.checkIfNoValue(this.weight)) {
        tooltipTitle += ` ${this.weight}`;
      }

      return tooltipTitle;
    },
  },
  methods: {
    checkIfNoValue(weight) {
      return weight === undefined || weight === null || weight === this.weightNoneValue;
    },
    onEditClick(shouldShowEditField = true) {
      this.showEditField(shouldShowEditField);

      this.track('click_edit_button', { property: 'weight' });
    },
    showEditField(bool = true) {
      this.shouldShowEditField = bool;

      if (this.shouldShowEditField) {
        this.$nextTick(() => {
          this.$refs.editableField.focus();
        });
      }
    },
    onCollapsedClick() {
      if (this.editable) {
        this.showEditField(true);
      }
      this.collapsedAfterUpdate = true;
    },
    onSubmit(e) {
      const { value } = e.target;
      const validatedValue = parseInt(value, 10);
      const isNewValue = validatedValue !== this.weight;

      this.hasValidInput = validatedValue >= 0 || value === '';

      if (!this.loading && this.hasValidInput) {
        $(this.$el).trigger('hidden.gl.dropdown');

        if (isNewValue) {
          eventHub.$emit('updateWeight', { id: this.id, value });
        }

        this.showEditField(false);
      }
    },
    removeWeight() {
      eventHub.$emit('updateWeight', { id: this.id, value: '' });
    },
  },
  maxDisplayWeight: MAX_DISPLAY_WEIGHT,
};
</script>

<template>
  <div :class="{ 'collapse-after-update': collapsedAfterUpdate }" class="block weight">
    <div
      v-gl-tooltip.left.viewport
      :title="tooltipTitle"
      class="sidebar-collapsed-icon js-weight-collapsed-block"
      @click="onCollapsedClick"
    >
      <gl-icon :size="16" name="weight" />
      <gl-loading-icon v-if="fetching" size="sm" class="js-weight-collapsed-loading-icon" />
      <span v-else class="js-weight-collapsed-weight-label">
        {{ collapsedWeightLabel
        }}<template v-if="weight > $options.maxDisplayWeight">&hellip;</template>
      </span>
    </div>
    <div class="hide-collapsed gl-line-height-20 gl-mb-2 gl-text-gray-900">
      {{ s__('Sidebar|Weight') }}
      <gl-loading-icon
        v-if="fetching || loading"
        size="sm"
        :inline="true"
        class="js-weight-loading-icon"
      />
      <a
        v-if="editable"
        class="float-right edit-link js-weight-edit-link"
        data-qa-selector="edit_weight_link"
        href="#"
        @click.prevent="onEditClick(!shouldShowEditField)"
        >{{ __('Edit') }}</a
      >
    </div>
    <div v-if="shouldShowEditField" class="hide-collapsed">
      <input
        ref="editableField"
        :value="weight"
        class="form-control"
        data-qa-selector="weight_input_field"
        type="text"
        :placeholder="__('Enter a number')"
        @blur="onSubmit"
        @keydown.enter="onSubmit"
      />
      <span v-if="!hasValidInput" class="gl-field-error">
        <gl-icon :size="24" name="merge-request-close-m" />
        {{ s__('Sidebar|Only numeral characters allowed') }}
      </span>
    </div>
    <div v-if="shouldShowWeight" class="value hide-collapsed js-weight-weight-label">
      <span v-if="!isNoValue">
        <strong class="js-weight-weight-label-value" data-qa-selector="weight_label_value">{{
          weight
        }}</strong>
        <span v-if="editable">
          -
          <a
            class="btn-default-hover-link js-weight-remove-link"
            data-qa-selector="remove_weight_link"
            href="#"
            @click="removeWeight"
            >{{ __('remove weight') }}</a
          >
        </span>
      </span>
      <span v-else class="no-value" data-qa-selector="weight_no_value_content">{{
        noValueLabel
      }}</span>
    </div>
  </div>
</template>
