import { n__ } from '~/locale';

/**
 * Accepts an array of options and an array of selected option IDs.
 *
 * Returns a string with the text of the selected options:
 * - If no options are selected, returns an empty string.
 * - If one option is selected, returns the text of that option.
 * - If more than one option is selected, returns the text of the first option
 *   followed by the text "+X more", where X is the number of additional selected options
 *
 * @param {Array<{ id: number | string }>} options
 * @param {Array<{ id: number | string }>} selected
 * @returns {String}
 */
export const getSelectedOptionsText = (options, selected, placeholder = '') => {
  const selectedOptions = options.filter(({ id }) => selected.includes(id));

  if (selectedOptions.length === 0) {
    return placeholder;
  }

  const [firstSelectedOption] = selectedOptions;
  const { text: firstSelectedOptionText } = firstSelectedOption;

  if (selectedOptions.length < 2) {
    return firstSelectedOptionText;
  }

  // Prevent showing "+-1 more" when the array is empty.
  const additionalItemsCount = selectedOptions.length - 1;
  return `${firstSelectedOptionText} ${n__('+%d more', '+%d more', additionalItemsCount)}`;
};
