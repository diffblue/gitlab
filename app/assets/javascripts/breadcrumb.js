import $ from 'jquery';
import { hide } from '~/tooltips';

export const addTooltipToEl = (el) => {
  const textEl = el.querySelector('.js-breadcrumb-item-text');

  if (textEl && textEl.scrollWidth > textEl.offsetWidth) {
    el.setAttribute('title', el.textContent);
    el.setAttribute('data-container', 'body');
    el.classList.add('has-tooltip');
  }
};

export default () => {
  const breadcrumbs = document.querySelector('.js-breadcrumbs-list');

  if (breadcrumbs) {
    const topLevelLinks = [...breadcrumbs.children]
      .filter((el) => !el.classList.contains('dropdown'))
      .map((el) => el.querySelector('a'))
      .filter((el) => el);
    const $expander = $('.js-breadcrumbs-collapsed-expander');
    const $expanderInline = $('.js-breadcrumbs-collapsed-expander.inline-list');

    topLevelLinks.forEach((el) => addTooltipToEl(el));

    $expander.closest('.dropdown').on('show.bs.dropdown hide.bs.dropdown', (e) => {
      const $el = $('.js-breadcrumbs-collapsed-expander', e.currentTarget);

      $el.toggleClass('open');

      hide($el);
    });

    $expanderInline.on('click', () => {
      const detailItems = $('.breadcrumbs-detail-item');
      const hiddenClass = 'gl-display-none!';

      $.each(detailItems, (_key, item) => {
        $(item).toggleClass(hiddenClass);
      });

      // remove the ellipsis
      $('li.expander').remove();

      // set focus on first breadcrumb item
      $('.breadcrumb-item-text').first().focus();
    });
  }
};
