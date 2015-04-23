#!/usr/bin/perl
use warnings;
use strict;
use CGI;

$ENV{REQUEST_METHOD}="GET";
$ENV{QUERY_STRING}=shift @ARGV;

my $q = CGI->new;
my $email = $q->param("email");
my $shard = $q->param("shard");
my $pubkey = $q->param("pubkey");
my $uuid = $q->param("uuid");
if ($shard !~ /^SHARD\d+$/) {
	oops("bad SHARD $shard");
}
$pubkey=~s/_/+/g; # + is space in CGI..
my ($sanitized_pubkey)=$pubkey=~/^(ssh-rsa [^\s]+)/;
my ($sanitized_email)=$email=~/^([^\s]+)/;
my ($sanitized_uuid)=$uuid=~/^([-A-Za-z0-9]+)$/;
if ($sanitized_pubkey eq "" || $sanitized_email eq "" || $sanitized_uuid eq "") {
	oops("bad inputs");
}

chdir("/home/registrar/users/") || oops("chdir: $!");
system("git pull");
if (! -d $shard) {
	mkdir("$shard") || oops("mkdir: $!");
}
open (OUT, ">>$shard/pubkeys") || oops("open: $!");
print OUT "$sanitized_pubkey $sanitized_email $sanitized_uuid\n";
close OUT;

my ($name)=$email=~/(.*)@/;
my $msg="registration of $name on $shard";
system("git", "add", "$shard/pubkeys");
system("git", "-c", "user.email=registrar\@iabak", "-c", "user.name=registrar", "commit", "-m", "$msg");
system("git", "push", "origin", "master");
print "** REGISTRATION SUCCEEDED **";
exit 0;

sub oops {
	my $msg=shift;
	print "REGISRATION FAILED: $msg\n";
	print "";
	print "Please contact the #internetarchive.bak IRC channel on irc.efnet.org for support!";
	exit 1;
}
