import $ from 'jquery';
import GfmAutoCompleteEE from 'ee/gfm_auto_complete';
import { TEST_HOST } from 'helpers/test_constants';
import GfmAutoComplete from '~/gfm_auto_complete';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { iterationsMock } from 'ee_jest/gfm_auto_complete/mock_data';

describe('GfmAutoCompleteEE', () => {
  const dataSources = {
    labels: `${TEST_HOST}/autocomplete_sources/labels`,
    iterations: `${TEST_HOST}/autocomplete_sources/iterations`,
  };

  let instance;

  it('should have enableMap', () => {
    instance = new GfmAutoCompleteEE(dataSources);
    instance.setup($('<input type="text" />'));

    expect(instance.enableMap).not.toBeNull();

    instance.destroy();
  });

  describe('Issues.templateFunction', () => {
    it('should return html with id and title', () => {
      expect(GfmAutoComplete.Issues.templateFunction({ id: 42, title: 'Sample Epic' })).toBe(
        '<li><small>42</small> Sample Epic</li>',
      );
    });

    it('should replace id with reference if reference is set', () => {
      expect(
        GfmAutoComplete.Issues.templateFunction({
          id: 42,
          title: 'Another Epic',
          reference: 'foo&42',
        }),
      ).toBe('<li><small>foo&amp;42</small> Another Epic</li>');
    });
  });

  describe('Iterations', () => {
    let $textarea;

    beforeEach(() => {
      setHTMLFixture('<textarea></textarea>');
      $textarea = $('textarea');
      instance = new GfmAutoCompleteEE(dataSources);
      instance.setup($textarea, { iterations: true });
    });

    afterEach(() => {
      instance.destroy();
      resetHTMLFixture();
    });

    const triggerDropdown = (text) => {
      $textarea.trigger('focus').val(text).caret('pos', -1);
      $textarea.trigger('keyup');

      jest.runOnlyPendingTimers();
    };

    const getDropdownItems = () => {
      const dropdown = document.getElementById('at-view-iterations');
      const items = dropdown.getElementsByTagName('li');
      return [].map.call(items, (item) => item.textContent.trim());
    };

    it("should list iterations when '/iteration *iteration:' is typed", () => {
      instance.cachedData['*iteration:'] = [...iterationsMock];

      const { id, title } = iterationsMock[0];
      const expectedDropdownItems = [`*iteration:${id} ${title}`];

      triggerDropdown('/iteration *iteration:');

      expect(getDropdownItems()).toEqual(expectedDropdownItems);
    });

    describe('templateFunction', () => {
      const { templateFunction } = GfmAutoCompleteEE.Iterations;

      it('should return html with id and title', () => {
        expect(templateFunction({ id: 42, title: 'Foobar Iteration' })).toBe(
          '<li><small>*iteration:42</small> Foobar Iteration</li>',
        );
      });

      it.each`
        xssPayload                                           | escapedPayload
        ${'<script>alert(1)</script>'}                       | ${'&lt;script&gt;alert(1)&lt;/script&gt;'}
        ${'%3Cscript%3E alert(1) %3C%2Fscript%3E'}           | ${'&lt;script&gt; alert(1) &lt;/script&gt;'}
        ${'%253Cscript%253E alert(1) %253C%252Fscript%253E'} | ${'&lt;script&gt; alert(1) &lt;/script&gt;'}
      `('escapes title correctly', ({ xssPayload, escapedPayload }) => {
        expect(templateFunction({ id: 42, title: xssPayload })).toBe(
          `<li><small>*iteration:42</small> ${escapedPayload}</li>`,
        );
      });
    });
  });
});
