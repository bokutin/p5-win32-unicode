package Win32::Unicode::Define;

use strict;
use warnings;
use Win32::API ();
use Exporter 'import';

our @EXPORT = grep { !/import|BEGIN|EXPORT/ && Win32::Unicode::Define->can($_) } keys %Win32::Unicode::Define::;

use constant +{
    GetFileInformationByHandle => Win32::API->new('kernel32', 'GetFileInformationByHandle', 'NS'        , 'N'),
    CreateProcess              => Win32::API->new('kernel32', 'CreateProcessW'            , 'PPPPNNPPSS', 'I'),
};

Win32::API::Struct->typedef('FILETIME', qw(
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
));

Win32::API::Struct->typedef('BY_HANDLE_FILE_INFORMATION', qw{
    DWORD    dwFileAttributes;
    FILETIME ctime;
    FILETIME atime;
    FILETIME mtime;
    DWORD    dwVolumeSerialNumber;
    DWORD    size_high;
    DWORD    size_low;
    DWORD    nNumberOfLinks;
    DWORD    nFileIndexHigh;
    DWORD    nFileIndexLow;
});

Win32::API::Struct->typedef('PROCESS_INFORMATION', qw(
    HANDLE hProcess;
    HANDLE hThread;
    DWORD  dwProcessId;
    DWORD  dwThreadId;
));

Win32::API::Struct->typedef('STARTUPINFO', qw{
    DWORD  cb;
    LPWSTR lpReserved;
    LPWSTR lpDesktop;
    LPWSTR lpTitle;
    DWORD  dwX;
    DWORD  dwY;
    DWORD  dwXSize;
    DWORD  dwYSize;
    DWORD  dwXCountChars;
    DWORD  dwYCountChars;
    DWORD  dwFillAttribute;
    DWORD  dwFlags;
    WORD   wShowWindow;
    WORD   cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
});

1;
