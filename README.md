
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

Many [features](#features) are implemented in this plugin. Here is a brief
summary of the highlights:

  - [Record / representation conceptual model](#records-and-representations)
  - [Restricted access period workflows and controls](#restricted-access-periods-raps)
  - [QSA ids](#qsa-ids)
  - [Agency registration workflows](#agency-registration)
  - [Batches and batch actions](#batches-and-batch-actions)
  - [Functional and storage movement controls and histories](#movements)
  - Assessment / conservation request and treatment workflows
  - Approval workflows
  - Chargeable services and items, and quote generation
  - Item use tracking and reporting
  - Significant item tracking and reporting
  - Bulk ingest and update via speadsheet import
  - Reports
  - CSV exports
  - Support for file storage on Amazon S3
  - Home page notifications
  - Form customizations

Some of these are discussed further below.


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

> This option is used in conjunction with the other `:storage_s3_*` config
> options to set the parameters required to store files using Amazon's S3 cloud
> storage service.

It specifies the access key required to authenticate to the service.

Example:
```ruby
    AppConfig[:storage_s3_access_key] = 'LUCYSNOOPY5F666FOO7Q'
```

### AppConfig[:storage_s3_bucket]

> This option is used in conjunction with the other `:storage_s3_*` config
> options to set the parameters required to store files using Amazon's S3 cloud
> storage service.

It specifies the bucket name.

Example:
```ruby
    AppConfig[:storage_s3_bucket] = 'really-neat-filestore'
```

### AppConfig[:storage_s3_bucket_fallback_ro]

> This option is used in conjunction with the other `:storage_s3_*` config
> options to set the parameters required to store files using Amazon's S3 cloud
> storage service.

It specifies a fallback bucket name for when things go bad and end up readonly.

Example:
```ruby
    AppConfig[:storage_s3_bucket_fallback_ro] = 'really-lame-filestore'
```

### AppConfig[:storage_s3_region]

> This option is used in conjunction with the other `:storage_s3_*` config
> options to set the parameters required to store files using Amazon's S3 cloud
> storage service.

It specifies the region where the bucket resides.

Example:
```ruby
    AppConfig[:storage_s3_region] = 'ap-southeast-2'
```

### AppConfig[:storage_s3_secret_access_key]

> This option is used in conjunction with the other `:storage_s3_*` config
> options to set the parameters required to store files using Amazon's S3 cloud
> storage service.

It specifies the secret access key required to authenticate to the service.

Example:
```ruby
    AppConfig[:storage_s3_secret_access_key] = 'xyzkeepmesecretorelse'
```


## Features

FIXME: write the important ones of these
  - Assessment / conservation request and treatment workflows
  - Functional and storage movement controls and histories
  - Chargeable services and items, and quote generation
  - Item use tracking and reporting
  - Significant item tracking and reporting
  - Bulk ingest and update via speadsheet import
  - Reports
  - CSV exports
  - Support for file storage on Amazon S3
  - Home page notifications
  - Form customizations


### Records and Representations

This is a significant change to the core ArchivesSpace datamodel. The goal was
to give much more emphasis to the relationship between the intellectual entity,
the _record_ and its various manifestations, its _representations_, and to
attach rich data and functionality to the representations.

The ArchivesSpace model:
```
  # physical
  resource > archival_object > instance > sub_container > top_container
  # digital
  resource > archival_object > instance > digital_object
```

The runcorn model:
```
  # physical
  resource > archival_object > physical_representation > top_container
  # digital
  resource > archival_object > digital_representation
```

Note that in the UI `resource` is labeled __Series__ and `archival_object` is
labeled __Item__.

Many of the other changes made in this plugin and others in the suite apply to
representations. And many of the complications, and implementation challenges,
arise from the inheritance rules between series, items and representations.


### Restricted Access Periods (RAPs)

FIXME: write this!


### QSA Ids

Most of the major record types have a QSA Id. This is a legacy identifier scheme
that replaces the various identifiers that ArchivesSpace has.

A QSA Id consists of a prefix (unique for each model) and a sequence number.
Records migrated from the legacy system bring their QSA Id with them. Some
models are new (they weren't represented in the legacy system). These models
just use their database id for the sequence number portion of the id.

Models are registered for QSA Ids in `common/qsa_id_registrations.rb`. The
registrations are defined in `common` because they need to be loaded in the
backend, frontend and indexer. You will see `require_relative` statements
in the `plugin_init.rb` of each of those components. Note that other plugins in
the suite also register models that they define.

Some example registrations:
```ruby
  QSAId.register(:resource, :existing_id_field => :id_0, :prefix => 'S')
  QSAId.register(:function, :prefix => 'F')
  QSAId.register(:assessment, :prefix => 'AS', :use_database_id => true)
```

The first argument to a register call must be a symbol that is the name of a
JSONModel. The call must specify a `:prefix` argument. The convention is that
this is a 1 to 3 character value in all caps, but it can be any valid string.

There are two optional arguments:

  - `:existing_id_field` Specifies the name of an ArcihvesSpace identifier field
                         on the model. If this is set, then the named field will
                         be populated with the QSA Id. This is necessary for
                         existing AS models that have mandatory identifier
                         fields.
  - `:use_database_id`   If set to `true` then the database id will be used
                         instead of a separate sequence. This can be used for
                         new model types - that is those that don't have legacy
                         identifiers that need to be retained.

For models that don't set `:use_database_id`, the identifers will be minted from
an ArchivesSpace sequence named `QSA_ID_{model}`, for example the sequence for
resources is `QSA_ID_RESOURCE`.

Models that are registered for QSA Ids will have two additional properties in
their JSON schema.

```json
    "qsa_id": 123,
    "qsa_id_prefixed": "ITM123",
```

> Note: these properties are added dynamically so they don't appear in the
> schema definition file for the model.

There are various methods on the models themselves and on the `QSAId` class that
help with constructing and parsing QSA Ids. These are defined in the following
files:

```
  common/qsa_id.rb
  backend/model/mixins/qsa_id_prefixer.rb
```

> Note: QSA Ids were designed to provide a prefix for each registered model.
> Unfortunately, it was subsequently discovered that `file_issue` needed a
> different prefix depending on whether it is a physical or digital
> `file_issue`, `FIP` and `FID` respectively. This required a bit of
> retrofitting. The key thing to understand is that the class method on
> FileIssue takes an `:issue_type` argument, like this:
> ```ruby
>   FileIssue.qsa_id_prefixed(row[:qsa_id], :issue_type => 'PHYSICAL')
> ```
> You won't often have to use this. If you have a FileIssue object, you can
> safely use the regular call (because the object knows its `issue_type`) like
> this: `my_file_issue.qsa_id_prefixed`. The exception is where you are dealing
> with rows from the database directly say, in which case you won't have an
> object handy.

QSA Ids are rendered consistently throughout the UI (in a rounded pale yellow
box). This is achieved via calls to a helper method in the erb templates like
this:

```erb
  <%= QSAIdHelper.id(item['qsa_id_prefixed']) %>
  <%= QSAIdHelper.id(item['qsa_id_prefixed'], :link => true) %>
```

The second example shows the optional `:link` argument. If this is set to `true`
then the id will be rendered with a `>` that, when clicked, takes the user to
the record.


### Agency Registration

When Agencies (Agent Corporate Entities) are created they have a `draft` status.

Draft agencies cannot be published. When the draft agency is ready for
registration (and potential publication), the user can `submit` the draft for
approval using the green toolbar dropdown (only visible in read only mode).

Submitted agencies cannot be edited, but they can be `withdrawn` for further
work, before being `submitted` once again.

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

### Batches and Batch Actions

Batches are arbitrary groupings of objects. They can be created from a search
results screen or from the following browse screens:

```
  Create > Batch
  Browse > Items
  Browse > Representations
  Browse > Batches
```

Once a batch has been created and had objects assigned, it can have actions
added. Batch actions are predefined bulk updates that are applied to all of the
objects in a batch. Once added to a batch they can be tested using the `Dry Run`
feature. This will run the action in a database transaction that is immediately
rolled back, after recording the results of the action.

When the action is run a report of the outcome will be saved in the action under
the `Report` section. The batch can now have another action added and then run,
and so on.

Batch actions run synchronously, that is the page won't reload until the action
is complete. We have endeavoured to make sure the actions run quickly, but some
action types (eg Attach RAP) might take a while to respond on large batches.

Once a batch has attached actions it can no longer have objects added or
removed. This is to ensure that the history of the batch remains valid.

It is also possible to download a CSV file for a batch.


#### Implementation notes

Batch actions are defined in handler classes. These can be found in:

```
  backend/lib/batch_action_handlers
```

A handler class registers one or more action types it will handle in statements
like this:

```ruby
  register(:functional_move,
           'Create a movement to a new functional location.',
           [:top_container, :physical_representation],
           :update_resource_record)
```

The arguments to `#register` are:

  - A symbol containing the name of the action type
  - A string containing a description of the action type
  - An array containing the object types that the action supports
  - A symbol containing the name of the permission required approve the action

In addition to registering for action types, a `batch_action_handler` must
implement a few methods as follows:

```ruby
  # mandatory
  self.default_params
  self.validate_params(params)
  self.perform_action(params, user, action_uri, uris)

  # optiional
  self.process_form_params(params)
```

See the current handlers for examples of how to implement. If you are adding a
new action type you will have to, in addition to creating a handler, add an
action parameter template form named after the action type. For the example
above the template is:

```
  frontend/views/batches/action_param_templates/_functional_move.html.erb
```

You will also have to add translations to `frontend/locales/en.yml`, like this:

```yaml
  batch_action_types:
    functional_move:
      label: Functional Move
      location: Functional location
```

This will need an entry for `label` and one for each named parameter that the
action accepts.

Future work on batches may include support for running actions as Background
Jobs. This is entirely doable but wasn't done as part of the initial release.


### Movements

The standard ArchivesSpace mechanisms for tracking the location of containers
has been replaced by movements in this plugin. A `movement` is a nested
subrecord on `top_container` and `physical_representation`. The location of a
`top_container` or `physical_representation` is set automatical based on its
most recent `movement`.

There are two kinds of `movement`. A storage move represents a movement to a new
storage location. A functional move represents a move to a new functional
location. When a model mixes in the `movements` mixin it can explicitly allow
storage moves - see below. Without this declaration, objects using the mixin
will only be permitted to move have functional moves.

```ruby
  # top_containers allow storage moves
  # so in backend/model/top_container.rb:
  include Movements
  move_to_storage_permitted

  # physical_representations do not allow storage moves
  # so in backend/model/physical_representation.rb:
  include Movements
```

A storage move `movement` record looks like this (with the system fields
removed):

```json
  {
    "context_uri": "/repositories/2/batch_actions/317",
    "move_date": "2020-02-06",
    "user":
    {
      "ref": "/agents/people/6"
    },
    "move_context":
    {
      "ref": "/repositories/2/batch_actions/317"
    },
    "storage_location":
    {
      "ref": "/locations/34"
    },
    "move_to_storage_permitted": true
  }
```

And a functional move looks like this:
```json
  {
    "context_uri": "/transfers/197",
    "move_date": "2020-03-04",
    "functional_location": "HOME",
    "user":
      {
        "ref": "/agents/people/5"
      },
    "move_context":
      {
        "ref": "/transfers/197"
      },
    "move_to_storage_permitted": false
  }
```

Every `movement` must have a `move_date`, `user` and either a `storage_location`
or a `functional_location`. It can optionally have a `move_context`. the other
two fields (`context_uri` and `move_to_storage_permitted` are set by the
system).

The `move_context` is a ref to an object that was the reason for the move. Only
some models can be refered to in a `move_context`. By default `assessment` and
`batch_action`). If another plugin wants to add to that list (because it
introduces new models that it wants to be `move_context`s then it makes calls to
the `MovementContextManager`, defined in `common/movement_context_manager.rb`.
For example in `as_cartography` in the `plugin_init.rb` files there are lines
like this:
```ruby
  # add new movement context models
  require_relative '../common/movement_contexts'

```
Which load `common/movement_contexts`, which looks like this:

```ruby
  MovementContextManager.add(:file_issue)
  MovementContextManager.add(:transfer)
  MovementContextManager.add(:agency_reading_room_request)
```

So now those models can be used in `move_context`.

Movements can be added to an object by simply adding them to its json and
calling `#update_from_json`. Alternatively, the movements mixin gives the
objects a `#move` method that takes care of some additional business logic
do to with replacing or removing moves associated with a context.

The location fields, `current_location` for functional locations and
`container_locations` for storage locations, are set automatically on
`#create_from_json` and `#update_from_json` based on the most recent functional
and storage move respectively. See `#set_locations_to_last_moves!(json)` in the
movements mixin `backend/model/mixins/movements.rb`.


