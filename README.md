
# as_runcorn

An ArchivesSpace plugin for QSA-specific business functions

Developed by Hudson Molonglo in collaboration with GAIA Resources and
Recordkeeping Innovation as part of the Queensland State Archives Digital
Archiving Program project.


## DISCLAIMER

__This plugin contains the core of the ArchivesSpace customizations for the QSA
instance. It modifies the behavour of ArchivesSpace extensively and adds many
new features. It was not designed to be run in any context other than that for
which it was built. It may include some approaches that others might find useful
when considering their own customization, but we strongly discourage any attempt
to use it.__


## Overview

Many features are implemented in this plugin. Here is a brief summary of the
highlights:

  - things


## Installation

To install the `as_runcorn` plugin follow this procedure:

  1. Download the latest version of the `as_runcorn` plugin into your
     `archivesspace/plugins/` directory
  2. Add `as_runcorn` to `AppConfig[:plugins]` in `config.rb`
  3. Run `scripts/setup-database.sh` (or `.bat` on windows)
  4. Add the required configuration options to `config.rb` (see below)


## Configuration

The following configuration options are supported:

```ruby
    AppConfig[:as_runcorn_forever_closed_access_categories]
    AppConfig[:create_big_series]
    AppConfig[:create_big_series_with_representations]
    AppConfig[:qsa_skip_rap_provisioning]
    AppConfig[:significant_items_page_size]
    AppConfig[:storage_file_path]
    AppConfig[:storage_s3_access_key]
    AppConfig[:storage_s3_bucket]
    AppConfig[:storage_s3_bucket_fallback_ro]
    AppConfig[:storage_s3_region]
    AppConfig[:storage_s3_secret_access_key]
```

### AppConfig[:as_runcorn_forever_closed_access_categories]

This option specifies an array containing the access categories that are treated
as permanently closed. These values control some important business logic and so
should not be changed without being tested thoroughly.

As of the initial production release it should contain the following values:

```ruby
    AppConfig[:as_runcorn_forever_closed_access_categories] = [
        'Overriding Legislation - Births, Deaths and Marriages Registration Act 2003',
        'Overriding Legislation - Adoption Act 2009',
        'Non-Publication Order',
        'Sealed by Court'
    ]
```

### AppConfig[:create_big_series]

__NOT FOR PRODUCTION USE__

This option takes an integer value. If it is set then on start up a series
(resource) will be created with the specified number of items
(archival_objects).

This is intended for testing purposes only. If you want to test a feature
against a very large series, then this option is your friend.

Example:
```ruby
    AppConfig[:create_big_series] = 250000
```

This will cause a series with two hundred and fifty thousand items to be created
at system start up.

### AppConfig[:create_big_series_with_representations]

__NOT FOR PRODUCTION USE__

This option is used in conjunction with `AppConfig[:create_big_series]`. It
takes a boolean value. If it is set to true then each of the items created will
get a physicial_representation attached to it.

Example:
```ruby
    AppConfig[:create_big_series_with_representations] = true
```

### AppConfig[:qsa_skip_rap_provisioning]

This option takes a boolean value. If it is set to true it causes RAP
provisioning to be skipped on system start up. If it is not set, or is set to
false, then RAP provisioning will run on start up.

RAP provisioning (discussed below in the RAPs section) can take a while on a
large dataset. This can slow down restarts, and is not required unless the data
is changed while the system is down, perhaps due to a migration.

So, it is safe to set it to `true` if a quick restart is being performed,
otherwise it should be set to `false` or left unset.

Example:
```ruby
    AppConfig[:qsa_skip_rap_provisioning] = true
```

### AppConfig[:significant_items_page_size]

This option takes an integer which specifies the numer of items to show per page
on the `Significant Items` browse screen. The default is `100`.

Example:
```ruby
    AppConfig[:significant_items_page_size] = 200
```

### AppConfig[:storage_file_path]

This option specifies a path where uploaded files will be stored. This can be
used instead of `AppConfig[:storage_s3_bucket]` for non-production deployments.

Example:
```ruby
    AppConfig[:storage_file_path] = '/tmp/qsa_dev'
```

### AppConfig[:storage_s3_access_key]

This option is used in conjunction with the other `:storage_s3_*` configuration
options to set the parameters required to store files using Amazon's S3 cloud
storage service.

It specifies the access key required to authenticate to the service.

Example:
```ruby
    AppConfig[:storage_s3_access_key] = 'LUCYSNOOPY5F666FOO7Q'
```

### AppConfig[:storage_s3_bucket]

This option is used in conjunction with the other `:storage_s3_*` configuration
options to set the parameters required to store files using Amazon's S3 cloud
storage service.

It specifies the bucket name.

Example:
```ruby
    AppConfig[:storage_s3_bucket] = 'really-neat-filestore'
```

### AppConfig[:storage_s3_bucket_fallback_ro]

This option is used in conjunction with the other `:storage_s3_*` configuration
options to set the parameters required to store files using Amazon's S3 cloud
storage service.

It specifies a fallback bucket name for when things go bad and end up readonly.

Example:
```ruby
    AppConfig[:storage_s3_bucket_fallback_ro] = 'really-lame-filestore'
```

### AppConfig[:storage_s3_region]

This option is used in conjunction with the other `:storage_s3_*` configuration
options to set the parameters required to store files using Amazon's S3 cloud
storage service.

It specifies the region where the bucket resides.

Example:
```ruby
    AppConfig[:storage_s3_region] = 'ap-southeast-2'
```

### AppConfig[:storage_s3_secret_access_key]

This option is used in conjunction with the other `:storage_s3_*` configuration
options to set the parameters required to store files using Amazon's S3 cloud
storage service.

It specifies the secret access key required to authenticate to the service.

Example:
```ruby
    AppConfig[:storage_s3_secret_access_key] = 'xyzkeepmesecretorelse'
```


## Functions

### Agency Registration

When Agencies (Agent Corporate Entities) are created they have a 'draft' status.

Draft agencies cannot be published. When the draft agency is ready for
registration (and potential publication), the user can 'submit' the draft for
approval using the green toolbar dropdown (only visible in read only mode).

Submitted agencies cannot be edited, but they can be 'withdrawn' for further
work, before being 'submitted' once again.

A user with the `manage_agency_registration` permission (by default, members of
a repository's `repository-managers` group) can then `approve` the submitted
draft for registration.

Once approved, the workflow is complete for this agency. Approved agencies can
be edited freely and published to the public website.

An overview of the registration workflow for all agencies can be accessed via
the system menu:
```
    System > Agency Registrations
```
