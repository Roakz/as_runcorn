# as_runcorn
An ArchivesSpace plugin for QSA-specific business functions

Developed by Hudson Molonglo in collaboration with GAIA Resources and Recordkeeping Innovation
as part of the Queensland State Archives Digital Archiving Program.

## Functions

### Agency Registration

When Agencies (Agent Corporate Entities) are created they have a 'draft' status.

Draft agencies cannot be published. When the draft agency is ready for registration
(and potential publication), the user can 'submit' the draft for approval using the
green toolbar dropdown (only visible in read only mode).

Submitted agencies cannot be edited, but they can be 'withdrawn' for further work,
before being 'submitted' once again.

A user with the 'manage_agency_registration' permission (by default, members of a
repository's 'repository-managers' group) can then 'approve' the submitted draft for
registration.

Once approved, the workflow is complete for this agency. Approved agencies can be
edited freely and published to the public website.

An overview of the registration workflow for all agencies can be accessed via the
system menu:
```
    System > Agency Registrations
```
