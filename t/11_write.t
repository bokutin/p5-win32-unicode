use strict;
use warnings;
use utf8;
use Test::More tests => 15;
use Test::Exception;
use File::Temp qw/tempdir tempfile/;
use Win32::Unicode::Console;

my $wuct = 'Win32::Unicode::Console::Tie';
tie *{Test::More->builder->output}, $wuct;
tie *{Test::More->builder->failure_output}, $wuct;
tie *{Test::More->builder->todo_output}, $wuct;

use Win32::Unicode::File;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

my $dir = tempdir( CLEANUP => 1 ) or die $!;
my $write_file = File::Spec->catfile("$dir/森鷗外.txt");

ok my $wfile = Win32::Unicode::File->new;
isa_ok $wfile, 'Win32::Unicode::File';

# OO test
{
	ok $wfile->open(w => $write_file);
	is $wfile->file_name, $write_file;
	ok $wfile->binmode(':utf8');
	ok $wfile->write('0123456789');
	ok $wfile->seek(0, 2);
	is $wfile->tell, 10;
	ok $wfile->close;
}

# tie test
{
	ok open $wfile, '<', $write_file;
	ok binmode $wfile, ':utf8';
	TODO: {
		local $TODO = 'todo';
		ok print $wfile '0123456789';
	};
	ok seek($wfile, 0, 2);
	is tell $wfile, 10;
	ok close $wfile;
};