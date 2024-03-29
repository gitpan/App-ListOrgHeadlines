
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'An application to list headlines in Org files',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'App-ListOrgHeadlines',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'App::ListOrgHeadlines',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Org::Parser' => '0.14',
    'Sub::Spec::CmdLine' => '0.26',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => [
    'bin/list-org-todos',
    'bin/list-org-headlines'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
