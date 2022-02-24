import { __ } from '~/locale';

const baseCSSClass = 'gl-spinner';

/**
 * Returns a loading icon/spinner element.
 *
 * This should *only* be used in existing legacy areas of code where Vue is not
 * in use, as part of the migration strategy defined in
 * https://gitlab.com/groups/gitlab-org/-/epics/7626.
 *
 * @param {object} props - The props to configure the spinner.
 * @param {boolean} inline - Display the spinner inline; otherwise, as a block.
 * @param {string} color - The color of the spinner ('dark' or 'light')
 * @param {string} size - The size of the spinner ('sm', 'md', 'lg', 'xl')
 * @param {string[]} classes - Additional classes to apply to the element.
 * @param {string} label - The ARIA label to apply to the spinner.
 * @returns {HTMLElement}
 */
export const loadingIconForLegacyJS = ({
  inline = false,
  color = 'dark',
  size = 'sm',
  classes = [],
  label = __('Loading'),
} = {}) => {
  const container = document.createElement(inline ? 'span' : 'div');
  container.classList.add(`${baseCSSClass}-container`, ...classes);
  container.setAttribute('role', 'status');

  const spinner = document.createElement('span');
  spinner.classList.add(baseCSSClass, `${baseCSSClass}-${color}`, `${baseCSSClass}-${size}`);
  spinner.setAttribute('aria-label', label);

  container.appendChild(spinner);

  return container;
};
