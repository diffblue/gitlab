import $ from 'jquery';
import Labels from '~/labels/labels';
import { isScopedLabel } from '~/lib/utils/common_utils';

class LabelsEE extends Labels {
  addBinding() {
    $(document).on('input', 'input.js-label-title', this.showSuggestedText);
    super.addBinding();
  }

  showSuggestedText() {
    const title = $(this).val();

    const $parentEl = $('.label-form');
    const hasScoped = $parentEl.find('.js-has-scoped-labels');
    const useScoped = $parentEl.find('.js-use-scoped-labels');

    const isScoped = isScopedLabel({ title });
    hasScoped.toggleClass('hidden', !isScoped);
    useScoped.toggleClass('hidden', isScoped);
  }
}

export default LabelsEE;
