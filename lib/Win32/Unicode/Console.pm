package Win32::Unicode::Console;

use strict;
use warnings;
use 5.008003;
use utf8;
use Carp ();
use Win32::API ();
use Exporter 'import';

use Win32::Unicode::Util;
use Win32::Unicode::Define;
use Win32::Unicode::Constant;
use Win32::Unicode::XS qw{
    get_std_handle
    write_console
};

# export subs
our @EXPORT = qw/printW printfW warnW sayW dieW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.19';

# default std handle
my $STD_HANDLE = {
    STD_OUTPUT_HANDLE, get_std_handle(STD_OUTPUT_HANDLE),
    STD_ERROR_HANDLE,  get_std_handle(STD_ERROR_HANDLE)
};

# ConsoleOut
sub _ConsoleOut {
    my $out_handle = shift;
    my $handle = $STD_HANDLE->{$out_handle};
    my $console_handle = shift;
    return unless @_;
    
    unless ($console_handle->{$handle}) {
        return warn @_ if $handle == $STD_HANDLE->{&STD_ERROR_HANDLE};
        if (tied *STDOUT and ref tied *STDOUT eq 'Win32::Unicode::Console::Tie') {
            no warnings 'untie';
            untie *STDOUT;
            print @_;
            tie *STDOUT, 'Win32::Unicode::Console::Tie';
            return 1;
        }
        return print @_;
    }
    
    my $separator = defined $\ ? $\ : '';
    my $str = join '', @_, $separator;
    
    while ($str) {
        my $tmp_str = substr($str, 0, MAX_BUFFER_SIZE);
        substr($str, 0, MAX_BUFFER_SIZE) = '';
        
        my $buff = 0;
        write_console($handle, utf8_to_utf16($tmp_str) . NULL);
    }
};

# print Unicode to Console
sub printW {
    my $res = _is_file_handle($_[0]);
    if ($res == 1) {
        my $fh = shift;
        _syntax_error() unless scalar @_;
        return print {$fh} join "", @_;
    }
    elsif ($res == -1) {
        shift;
        _syntax_error() unless scalar @_;
    }
    
    _ConsoleOut(STD_OUTPUT_HANDLE, CONSOLE_OUTPUT_HANDLE, @_);
    
    return 1;
}

# printf Unicode to Console
sub printfW {
    my $res = _is_file_handle($_[0]);
    if ($res == 1) {
        my $fh = shift;
        _syntax_error() unless scalar @_;
        return printW($fh, sprintf shift, @_);
    }
    elsif ($res == -1) {
        shift;
        _syntax_error() unless scalar @_;
    }
    
    printW(sprintf shift, @_);
}

sub _is_file_handle {
    return 0 unless defined $_[0];
    my $fileno = ref $_[0] eq 'GLOB' ? fileno $_[0] : undef;
    return -1 if defined $fileno and $fileno == fileno select; # default out through.
    defined $fileno and ref(*{$_[0]}{IO}) =~ /^IO::/ ? 1 : 0;
}

sub _syntax_error {
    local $Carp::CarpLevel = 1;
    Carp::croak "No comma allowed after filehandle";
}

# say Unicode to Console
sub sayW {
    printW(@_, "\n");
}

# warn Unicode to Console
sub warnW {
    my $str = join q{}, @_;
    $str .= $str =~ s/\n$// ? "\n" : Carp::shortmess('');
    
    if ($SIG{__WARN__} && ref $SIG{__WARN__} eq 'CODE') {
        return $SIG{__WARN__}->($str);
    }
    
    _row_warn($str);
    return 1;
}

# die Unicode to Console
sub dieW {
    my $str = join q{}, @_;
    $str .= $str =~ s/\n$// ? "\n" : Carp::shortmess('');
    
    if ($SIG{__DIE__} && ref $SIG{__DIE__} eq 'CODE') {
        $SIG{__DIE__}->($str);
    }
    local $SIG{__DIE__};
    
    $str =~ s/\n$//;
    _row_warn($str);
    CORE::die("\n");
    return;
}

sub _row_warn {
    _ConsoleOut(STD_ERROR_HANDLE, CONSOLE_ERROR_HANDLE, @_);
}

# Handle OO calls
*IO::Handle::printW = \&printW unless defined &IO::Handle::printW;
*IO::Handle::printfW = \&printfW unless defined &IO::Handle::printfW;
*IO::Handle::sayW = \&sayW unless defined &IO::Handle::sayW;


package Win32::Unicode::Console::Tie;

sub TIEHANDLE {
    my $class = shift;
    bless {}, $class;
}

sub PRINT {
    my $self = shift;
    Win32::Unicode::Console::printW(@_);
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    $self->PRINT(sprintf $format, @_);
}

sub BINMODE {
    # TODO...?
}

sub FILENO {}

1;
__END__
=head1 NAME

Win32::Unicode::Console.pm - Unicode string to console out

=head1 SYNOPSIS

  use Win32::Unicode::Console;
  
  my $flaged_utf8_str = "I \x{2665} Perl";
  
  printW $flaged_utf8_str;
  printfW "[ %s ] :P", $flaged_utf8_str;
  sayW $flaged_utf8_str;
  warnW $flaged_utf8_str;
  dieW $flaged_utf8_str;
  
  # write file
  printW $fh, $str;
  printfW $fh, $str;
  sayW $fh, $str;

=head1 DESCRIPTION

Win32::Unicode::Console provides Unicode String to console out.
This module is by default C<printW> and C<warnW> export functions.

This module PerlIO-proof.
However, when the file is redirected to the C<CORE:: print> and C<CORE:: warn> switches.

=head1 FUNCTIONS

=over

=item B<printW([$fh ,] @str)>

Flagged utf8 string to console out.
Like print.

=item B<printfW([$fh ,] @str)>

Flagged utf8 string to console out.
Like printf.

=item B<sayW([$fh ,] @str)>

Flagged utf8 string to console out.
Like Perl6 say.

=item B<warnW(@str)>

Flagged utf8 string to console out.
Like warn.

=item B<dieW(@str)>

Flagged utf8 string to console out.
Like die.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::API>

=cut
