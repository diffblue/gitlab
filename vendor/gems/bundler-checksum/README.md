# bundler-checksum

Bundler plugin for verifying local gem checksums

## Install

```
bundle plugin install bundler-checksum \
  --git https://gitlab.com/gitlab-org/distribution/bundler-checksum.git --branch initial-push2
```

Note that you can add bundler-checksum to your Gemfile, but bundler hooks will be fired only on second run of `bundle install`.

## Usage

Once the plugin is installed, bundler hooks are used to verify gems before installation.

If a new or updated gem is to be installed, the remote checksum of that gem is stored in `Gemfile.checksum`.
Checksum entries for other versions of the gem are removed from `Gemfile.checksum`.

If a version of a gem is to be installed that is already present in `Gemfile.checksum`, the remote and local
checksums are compared and an error is prompted if they do not match.

Gem checksums for all platforms are stored in `Gemfile.checksum`.
When `bundler-checksum` runs it will only verify the checksum for the platform that `bundle` wants to download.


## Development

Add `plugin 'bundler-checksum', path: '.'` to the Gemfile of this repository.
