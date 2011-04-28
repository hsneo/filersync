#!/usr/bin/perl -w

#for testing
#df -h
#mount /dev/sdb1 /backup/exthdd
#cd /backup/exthdd/test
#rm -r /backup at the root
#umount /backup/exthdd
# perl rsyncScript.pl
#cd /etc/udev/rules.d
#vi 95-usbplugin.rules
# this script is at /home/neohs

#cat /proc/bus/usb/devices | grep -i product

#SUBSYSTEM=="usb", ATTR{serial}=="M6116018VF16", PROGRAM="/home/neohs/rsyncScript.pl %k", SYMLINK+="%c" NAME="%c{1}", SYMLINK+="%c{2+}"

use strict;
use Mail::Mailer;
use File::Find;

my $to_address = "hsneo\@mindmedia.com.sg";
my $from_address = "test\@mindmedia.com.sg";
my $subject = "Backup";
my $body = "Failure to rsync files to external hdd.";
my $mailer = Mail::Mailer->new("sendmail");

my $sourcedir="/home/neohs/Documents";
my $backupdir="/backup/exthdd";
my $backupdir2="/test";

# make sure we're running as root
unless ($> == 0 || $< == 0) { die "You must be root";exit;}

# get the serial number of external hard disk
#my $query = qx{hdparm -i /dev/sdb1} or die $!;

#print "HDD serial number is: $1\n" if $query =~ m/SerialNo=([^,\s]+)/s;

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
(my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek) = localtime();
my $year = 1900 + $yearOffset;
my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";

if ($month == 12) {$month = 1} else {$month = $month + 1;}
if ($month < 10) { $month = "0$month"; }
if ($dayOfMonth < 10) { $dayOfMonth = "0$dayOfMonth"; }

my $theDate = "$year"."$month"."$dayOfMonth";


# to check if the serial number matches
#if ($1 eq 'Y3MRSW1E') {
        #check if the backup/exthdd dir exists. Otherwise, create the dir    
        if (! -d $backupdir) {
		system("mkdir -p $backupdir$backupdir2");}
      
        #mount the backup dir
        system("mount /dev/sdb1 $backupdir");
               
        #use rsync to copy files and subdirectories from the source dir to the /test subdirectory of backup dir
   	system("rsync -avz --log-file=${sourcedir}/backup.log --exclude=backup.log --progress  $sourcedir  $backupdir$backupdir2");

#rsync -avz --log-file=/home/neohs/Documents/backup.log  --bwlimit=7000 --progress  /home/neohs/Documents  /backup/exthdd

        # print "rsync -avz --progress  $sourcedir  $backupdir"."/test\n";

        #Append the run results to the run textfile
        open (myfile1, '>>rundata'.$theDate.'.txt') or die "Can't write to file data.txt [$!]\n";
   
        print myfile1 "START RUN\n";
        print myfile1 "Run date is  $theTime \n";

        #Print out in the run textfile all the files copied to an external hard disk
	my $localdir = $backupdir.$backupdir2.'/';

	find(
		sub { print myfile1 $File::Find::name, "\n" },
	$localdir);
        
        print myfile1 "END RUN\n\n";
        close myfile1;

        system("mv rundata$theDate.txt $sourcedir");
        #unmount the backup 
        system("umount -l $backupdir");
        
        $body = "Backup to external hdd has been done successfully on $theTime.";

#}
#else {print "Sorry, the serial number of your hard disk does not match\n";}

	$mailer->open({
        	From    => $from_address,
                To      => $to_address,
                Subject => $subject
        }) or die "Cannot send mail";

        print $mailer $body;
        $mailer->close();

exit;

