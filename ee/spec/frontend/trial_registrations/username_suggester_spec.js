import MockAdapter from 'axios-mock-adapter';
import UsernameSuggester from 'ee/trial_registrations/username_suggester';
import { setHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';

describe('UsernameSuggester', () => {
  let axiosMock;
  let suggester;
  let firstName;
  let lastName;
  let username;
  const usernameEndPoint = '/-/username';
  const expectedUsername = 'foo_bar';

  const setupSuggester = (dstElement, srcElementIds) => {
    suggester = new UsernameSuggester(dstElement, srcElementIds);
  };

  beforeEach(() => {
    setHTMLFixture(`
      <div class="flash-container"></div>
      <input type="text" id="first_name">
      <input type="text" id="last_name">

      <input type="text" id="username" data-api-path="${usernameEndPoint}">
    `);
    firstName = document.getElementById('first_name');
    lastName = document.getElementById('last_name');
    username = document.getElementById('username');
  });
  describe('constructor', () => {
    it('sets isLoading to false', () => {
      setupSuggester('username', ['first_name']);

      expect(suggester.isLoading).toBe(false);
    });

    it(`sets the apiPath to ${usernameEndPoint}`, () => {
      setupSuggester('username', ['first_name']);

      expect(suggester.apiPath).toBe(usernameEndPoint);
    });

    it('throws an error if target element is missing', () => {
      expect(() => {
        setupSuggester('id_with_that_id_does_not_exist', ['first_name']);
      }).toThrow('The target element is missing.');
    });

    it('throws an error if api path is missing', () => {
      setHTMLFixture(`
        <input type="text" id="first_name">
        <input type="text" id="last_name">

        <input type="text" id="username">
      `);

      expect(() => {
        setupSuggester('username', ['first_name']);
      }).toThrow('The API path was not specified.');
    });

    it('throws an error when no arguments were provided', () => {
      expect(() => {
        setupSuggester();
      }).toThrow("Required argument 'targetElement' is missing");
    });
  });

  describe('joinSources', () => {
    it('does not add `_` (underscore) with the only input specified', () => {
      setupSuggester('username', ['first_name']);

      firstName.value = 'foo';

      const name = suggester.joinSources();

      expect(name).toBe('foo');
    });

    it('joins values from multiple inputs specified by `_` (underscore)', () => {
      setupSuggester('username', ['first_name', 'last_name']);

      firstName.value = 'foo';
      lastName.value = 'bar';

      const name = suggester.joinSources();

      expect(name).toBe(expectedUsername);
    });

    it('returns an empty string if 0 inputs specified', () => {
      setupSuggester('username', []);

      const name = suggester.joinSources();

      expect(name).toBe('');
    });
  });

  describe('suggestUsername', () => {
    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
      setupSuggester('username', ['first_name', 'last_name']);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('does not suggests username if suggester is already running', () => {
      suggester.isLoading = true;

      expect(axiosMock.history.get).toHaveLength(0);
      expect(username).toHaveValue('');
    });

    it('suggests username successfully', () => {
      axiosMock
        .onGet(usernameEndPoint, { param: { name: expectedUsername } })
        .reply(200, { username: expectedUsername });

      expect(suggester.isLoading).toBe(false);

      firstName.value = 'foo';
      lastName.value = 'bar';

      suggester.suggestUsername();

      setImmediate(() => {
        expect(axiosMock.history.get).toHaveLength(1);
        expect(suggester.isLoading).toBe(false);
        expect(username).toHaveValue(expectedUsername);
      });
    });

    it('shows a flash message if request fails', (done) => {
      axiosMock.onGet(usernameEndPoint).replyOnce(500);

      expect(suggester.isLoading).toBe(false);

      firstName.value = 'foo';
      lastName.value = 'bar';

      suggester.suggestUsername();

      setImmediate(() => {
        expect(axiosMock.history.get).toHaveLength(1);
        expect(suggester.isLoading).toBe(false);
        expect(username).toHaveValue('');
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          'An error occurred while generating a username. Please try again.',
        );

        done();
      });
    });
  });
});
