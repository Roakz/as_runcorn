$(document).ready(function() {
  var $link = $('.repository-header .repo-container .dropdown-menu li a[href="/jobs/new?job_type=report_job"]');
  $link.attr('href', '/runcorn_reports');
});