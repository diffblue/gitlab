import { nextTick } from 'vue';
import showTooltip from 'ee/registrations/groups_projects/new/show_tooltip';
import * as tooltips from '~/tooltips';

const fixture = `<div class='my-tooltip' title='this is a tooltip!'></div>`;

beforeEach(() => {
  setFixtures(fixture);
});

const findBodyText = () => document.body.innerText;

describe('showTooltip', () => {
  it('renders a tooltip immediately', async () => {
    expect(findBodyText()).toBe('');
    showTooltip('.my-tooltip');
    await nextTick();
    expect(findBodyText()).toBe('this is a tooltip!');
  });

  it('merges config options', () => {
    const addSpy = jest.spyOn(tooltips, 'add');
    showTooltip('.my-tooltip', { placement: 'bottom' });
    expect(addSpy).toHaveBeenCalledWith(expect.any(Array), { placement: 'bottom', show: true });
  });
});
