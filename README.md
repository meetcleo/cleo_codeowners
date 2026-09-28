# Cleo Codeowners

Manage your github CODEOWNERS files across multiple teams and features.

## Summary

`cleo_codeowners` builds GitHub CODEOWNERS from small YAML files. Keep owners, features, and file globs in `.cleo/codeowners/**/*.yml`; generate `.github/CODEOWNERS` and `.github/CODEOWNERS-HUMAN`.

## Installation

```sh
gem install cleo_codeowners
```

Or add it to your Gemfile:

```ruby
gem "cleo_codeowners"
```

In Rails, the gem adds a rake task:

```sh
bin/rails codeowners:generate
```

## Configuration

Set the GitHub organization name before generating CODEOWNERS.

In a Rails app, add an initializer:

```ruby
# config/initializers/codeowners.rb
Codeowners.configure do |config|
  config.organization_name = "my_org"
end
```

In a non-Rails app, configure Codeowners in the Rakefile while setting up the rake task:

```ruby
# Rakefile
require "cleo_codeowners"

Codeowners.configure do |config|
  config.organization_name = "my_org"
end

task :environment

load Gem.loaded_specs["cleo_codeowners"].full_gem_path + "/lib/tasks/codeowners.rake"
```

## Writing your codeowners files

Create YAML files under `.cleo/codeowners/`.

```yaml
# .cleo/codeowners/features.yml
features:
  session management:
    session administration:
    session expiry:
  billing:
```

Child features inherit their parent's owners, or can override with their own.
An owner can be one or more teams.

```yaml
# .cleo/codeowners/owners.yml
owners:
  session administration:
    - operations
  session management: identity-platform
  billing:
    - payments
    - finance
```

```yaml
# .cleo/codeowners/files/session_management.yml
files:
  session administration:
    - /app/controllers/admin/sessions/
  session expiry:
    - /app/services/session_expiry/
  session management:
    - /app/controllers/sessions/
    - /app/models/session.rb

# .cleo/codeowners/files/billing.yml
files:
  billing:
    - /app/controllers/billing/
    - /app/models/invoice.rb
```

Generate:

```sh
bin/rails codeowners:generate
```

Inspect:

```sh
cleo-codeowners find_feature app/models/session.rb
cleo-codeowners find_owner app/models/session.rb --glob
cleo-codeowners find_unowned_files --pattern='app/**/*.rb' --exit-status-on-match=1
cleo-codeowners find_contributors "session management" --max-commits=100
```

## Development

Requires Ruby `>= 3.2.0`.

Install missing gems:

```sh
gem install rake thor activesupport mocha minitest
```

Run tests:

```sh
rake test
```

## License

MIT
