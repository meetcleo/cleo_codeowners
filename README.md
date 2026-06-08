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

## Writing your codeowners files

Create YAML files under `.cleo/codeowners/`.

```yaml
# .cleo/codeowners/features.yml
features:
  feature A:
    feature A foo:
  feature B:
```

```yaml
# .cleo/codeowners/owners.yml
owners:
  feature A: team-1
  feature A foo: team-2
  feature B: team-2
```

Child features inherit their parent owner unless they define one.

```yaml
# .cleo/codeowners/files/feature_a.yml
files:
  feature_a:
    - /app/controllers/feature_a/
    - /app/models/feature_a/foo.rb

# .cleo/codeowners/files/feature_b.yml
files:
  feature_b:
    - /app/controllers/feature_b
    - /app/models/feature_b
```

Generate:

```sh
bin/rails codeowners:generate
```

Inspect:

```sh
cleo-codeowners find_feature app/models/feature_a/foo.rb
cleo-codeowners find_owner app/models/feature_a/foo.rb --glob
cleo-codeowners find_unowned_files --pattern='app/**/*.rb' --exit-status-on-match=1
cleo-codeowners find_contributors feature_a --max-commits=100
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
