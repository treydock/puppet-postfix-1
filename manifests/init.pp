#
# == Class: postfix
#
# This class provides a basic setup of postfix with local and remote
# delivery and an SMTP server listening on the loopback interface.
#
# === Parameters
#
# [*alias_maps*]          - (string)
#
# [*inet_interfaces*]     - (string)
#
# [*inet_protocols*]      - (string)
#
# [*ldap*]                - (boolean) Whether to use LDAP
#
# [*ldap_base*]           - (string)
#
# [*ldap_host*]           - (string)
#
# [*ldap_options*]        - (string)
#
# [*mail_user*]           - (string) The mail user
#
# [*mailman*]             - (boolean)
#
# [*maincf_source*]       - (string)
#
# [*manage_conffiles*]    - (boolean) Whether config files are to be replaced
#
# [*manage_mailx*]        - (boolean) Whether to manage mailx package.
#
# [*mastercf_source*]     - (string)
#
# [*master_smtp*]         - (string)
#
# [*master_smtps*]        - (string)
#
# [*master_submission*]   - (string)
#
# [*master_entries*]      - (array of strings)
#
# [*master_bounce_command*] - (string)
#
# [*master_defer_command*]  - (string)
#
# [*mta*]                 - (boolean) Configure postfix minimally, as a simple MTA
#
# [*mydestination*]       - (string)
#
# [*mynetworks*]          - (string)
#
# [*myorigin*]            - (string)
#
# [*relayhost*]           - (string)
#
# [*root_mail_recipient*] - (string)
#
# [*chroot*]              - (undef/boolean) Whether postfix should be run in a chroot
#
# [*satellite*]           - (boolean) Whether to use as a satellite
#                           (implies MTA)
#
# [*smtp_listen*]         - (string) The SMTP listen interface
#
# [*use_amavisd*]         - (boolean) Whether to setup for Amavis
#
# [*use_dovecot_lda*]     - (boolean) Whether to setup for Dovecot LDA
#
# [*use_schleuder*]       - (boolean) Whether to setup for Schleuder
#
# [*use_sympa*]           - (boolean) Whether to setup for Sympa
#
# [*postfix_ensure*]      - (string) The ensure value of the postfix package
#
# [*mailx_ensure*]        - (string) The ensure value of the mailx package
#
# === Examples
#
#   class { 'postfix':
#     smtp_listen => '192.168.1.10',
#   }
#
class postfix (
  String                          $alias_maps          = 'hash:/etc/aliases',
  String                          $inet_interfaces     = 'all',
  String                          $inet_protocols      = 'all',
  Boolean                         $ldap                = false,
  Optional[String]                $ldap_base           = undef,
  Optional[String]                $ldap_host           = undef,
  Optional[String]                $ldap_options        = undef,
  String                          $mail_user           = 'vmail',       # postfix_mail_user
  Boolean                         $mailman             = false,
  String                          $maincf_source       = "puppet:///modules/${module_name}/main.cf",
  Boolean                         $manage_conffiles    = true,
  Boolean                         $manage_mailx        = true,
  Optional[String]                $mastercf_source     = undef,
  Optional[String]                $master_smtp         = undef,         # postfix_master_smtp
  Optional[String]                $master_smtps        = undef,         # postfix_master_smtps
  Optional[String]                $master_submission   = undef,         # postfix_master_submission
  Optional[Array[String]]         $master_entries      = undef,         # postfix_master_entries
  String                          $master_bounce_command = 'bounce',
  String                          $master_defer_command  = 'bounce',
  Boolean                         $mta                 = false,
  String                          $mydestination       = '$myorigin',   # postfix_mydestination
  String                          $mynetworks          = '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128', # postfix_mynetworks
  String                          $myorigin            = $::fqdn,
  Optional[String]                $relayhost           = undef,         # postfix_relayhost
  Boolean                         $manage_root_alias   = true,
  Variant[Array[String], String]  $root_mail_recipient = 'nobody',      # root_mail_recipient
  Optional[Boolean]               $chroot              = undef,
  Boolean                         $satellite           = false,
  String                          $smtp_listen         = '127.0.0.1',   # postfix_smtp_listen
  Boolean                         $use_amavisd         = false,         # postfix_use_amavisd
  Boolean                         $use_dovecot_lda     = false,         # postfix_use_dovecot_lda
  Boolean                         $use_schleuder       = false,         # postfix_use_schleuder
  Boolean                         $use_sympa           = false,         # postfix_use_sympa
  String                          $postfix_ensure      = 'present',
  String                          $mailx_ensure        = 'present',
  String                          $service_ensure      = 'running',
  Boolean                         $service_enabled     =  true,
) inherits postfix::params {

  $_smtp_listen = $mailman ? {
    true    => '0.0.0.0',
    default => $smtp_listen,
  }

  $all_alias_maps = $ldap ? {
    false => $alias_maps,
    true  => "${alias_maps}, ldap:/etc/postfix/ldap-aliases.cf",
  }

  anchor { 'postfix::begin': }
  -> class { '::postfix::packages': }
  -> class { '::postfix::files': }
  ~> class { '::postfix::service': }
  -> anchor { 'postfix::end': }

  if $ldap {
    include ::postfix::ldap
  }

  if $mta {
    if $satellite {
      fail('enabling both the $mta and $satellite parameters is not supported. Please disable one.')
    }
    include ::postfix::mta
  }

  if $satellite {
    if $mta {
      fail('enabling both the $mta and $satellite parameters is not supported. Please disable one.')
    }
    include ::postfix::satellite
  }

  if $mailman {
    include ::postfix::mailman
  }
}
