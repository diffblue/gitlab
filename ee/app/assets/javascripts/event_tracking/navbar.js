import { mergeUrlParams } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';

const TRACKING_CATEGORY = 'navbar_top';
const NAVSOURCE_KEY = 'nav_source';
const NAVSOURCE_VALUE = 'navbar';

/**
 * intercepts clicks on navbar links
 * and adds the 'nav_source=navbar' query parameter
 */
const appendLinkParam = (e) => {
  const target = e.currentTarget;

  // get closest link in case the target is a wrapping DOM node
  const link = target.tagName === 'A' ? target : target.closest('a');

  if (link && link.href && link.href.indexOf(`${NAVSOURCE_KEY}=${NAVSOURCE_VALUE}`) === -1) {
    const url = mergeUrlParams({ [NAVSOURCE_KEY]: NAVSOURCE_VALUE }, link.href);
    link.setAttribute('href', url);
  }
};

export default function trackNavbarEvents() {
  if (!Tracking.enabled()) return;

  const navbar = document.querySelector('.navbar-gitlab');
  if (!navbar) return;

  // track search inputs within frequent-items component
  navbar.querySelectorAll(`.frequent-items-dropdown-container input`).forEach((el) => {
    el.addEventListener('click', (e) => {
      const parentDropdown = e.currentTarget.closest('li.dropdown');

      Tracking.event(TRACKING_CATEGORY, 'activate_form_input', {
        label: `${parentDropdown.dataset.trackLabel}_search`,
        property: '',
        value: '',
      });
    });
  });

  if (navbar) {
    navbar.addEventListener('click', appendLinkParam);
    navbar.addEventListener('contextmenu', appendLinkParam);
  }
}
