#!/usr/bin/perl 

# Usage:
#  ./release-tools/release-branch-cut.pl ORG  BRANCH TOKEN 
#  e.g ./release-tools/release-branch-cut.pl SlackRecruiting master  1234abcd 
#


use strict;
use warnings;
use XML::Simple;
use Data::Dumper;

# Build array of repos
my ($org,  $branch, $token) = @ARGV; 
my $cmd="curl https://api.github.com/orgs/$org/repos?access_token=$token 2>/dev/null";
my @repos = `$cmd`;
@repos = grep (/"html_url"/, @repos);
@repos = grep (/\/$org\//, @repos);
# cleanup repo array
my @tmp = map { 
    (my $tmp = $_) =~ s/^.*\s+"(.*)".*$/$1/;
    $tmp;
} @repos;
@repos = @tmp;
my $num = scalar @repos;
print "\nFound $num repos.\n";
print @repos;

#foreach repo;  Load release data files; Cut Branch; Update release data files
foreach (@repos) {
    s/\n+$//g;
    my $rawsite = $_;
    $rawsite =~ s/github\.com/raw.githubusercontent.com/g; 
    $cmd="curl --header 'Authorization: token $token'  --header 'Accept: application/vnd.github.v3.raw'  --remote-name  --location $rawsite/$branch/release.plist 2>/dev/null";
    print "\n$cmd\n";
    system($cmd);
    $cmd="curl --header 'Authorization: token $token'  --header 'Accept: application/vnd.github.v3.raw'  --remote-name  --location $rawsite/$branch/releng/release_info.csv  2>/dev/null";
    print "\n$cmd\n";
    system($cmd);

    #move temp files to tmp
    $cmd="cp -f release.plist /var/tmp/";
    system($cmd);
    $cmd="mv -f release_info.csv /var/tmp/";
    system($cmd);


    # Determine repo name
    my $repo_name = $_;
    $repo_name =~ s/^.*\/$org\///;

    # Determine Release branch to cut
    open my $handle, '<', "/var/tmp/release.plist";
    chomp(my @release_plist = <$handle>);
    close $handle;

    # Remove empty elements
    @release_plist = grep { $_ ne '' } @release_plist;
    # Save header for later
    my @header  = @release_plist[0..1];
    #rewrire plist
    open $handle, '>', "/var/tmp/release.plist";
    print $handle @release_plist;
    close $handle;
 

    my $xml = new XML::Simple;
    my $data = $xml->XMLin("/var/tmp/release.plist");
    my $release="$data->{dict}{string}[3]";
    my $version="$data->{dict}{string}[2]";
    my $branch_cut="$release/$version";

    # Get previous release branches
    $cmd="curl https://api.github.com/repos/$org/$repo_name/branches?access_token=$token 2>/dev/null";
    my @tmp = `$cmd`;
    @tmp = grep (/"name": "$release\//, @tmp);
    my @branches = map { 
        (my $tmp = $_) =~ s/^.*\s+"(.*)".*$/$1/;
        $tmp;
    } @tmp;
    my $num = scalar @branches;
    print "\nFound $num versions of release-- $release.\n";
    print @branches;

    # exit if release branch already exists
    if ( grep (/$branch_cut/, @branches) ) {
        $cmd="git checkout release.plist";
        system($cmd);
        die "\nBranch $branch_cut already exists!.  Exiting!.\n\n";
    }

    $cmd="curl --header 'Authorization: token $token'  --header 'Accept: application/vnd.github.v3.raw'  --remote-name  --location $rawsite/$branch/featureflags/FF.csv 2>/dev/null";
    print "\n$cmd\n";
    system($cmd);
    $cmd="mv -f FF.csv /var/tmp";
    system($cmd);
    if ( $num == 0 ) {
    # Get Feature Flag settings
        print "\nThis is the first release of $release and will include Feature Flags ... \n";
        system("cat /var/tmp/FF.csv");
    } else {
       # Generate Feature Flag updates since last release branch cut
       print "\nFeature switch updates included in branch --- $branch_cut ...\n";
       my $b=$branches[$#branches];
       $b =~ s/\n+//g;
       $cmd="git diff origin/$branch origin/$b featureflags/FF.csv";
       my $tmp = `$cmd`;
       print "\n$tmp\n";
    } 
       

    # Get latest SHA on parent branch 
    $cmd="curl https://api.github.com/repos/$org/$repo_name/git/refs/heads/$branch?access_token=$token 2>/dev/null";
    my @sha = `$cmd`;
    @sha = grep (/"sha": "/, @sha);
    @tmp = map { 
        (my $tmp = $_) =~ s/^.*\s+"(.*)".*$/$1/;
        $tmp;
    } @sha;
    my $sha = join('',@tmp);
    $sha =~ s/\s+$//g;
    print "\n\nBranching $branch_cut from SHA -- $sha\n";

    # Cut Branch from SHA
    $cmd="curl -d '{\"ref\": \"refs/heads/$branch_cut\", \"sha\": \"$sha\"}' https://api.github.com/repos/$org/$repo_name/git/refs?access_token=$token >/dev/null 2>&1";
    print "\nExecuting commanmd -- $cmd\n";
    system($cmd);

    #Update data  with next release version.  Content of release.plist
    my $next_release_version ="$data->{dict}{string}[2]";
    my $major = $next_release_version;
    my $minor = $next_release_version;
    $major =~ s/^(.*)\.(.*)$/$1/;
    $minor =~ s/^(.*)\.(.*)$/$2/;
    $minor++;
    $data->{dict}{string}[2] = "$major.$minor";
    print "\nNext release version -- $data->{dict}{string}[2]\n";

    # Update file release.plist
    open $handle, '>', "release.plist";
    #Add header.
    my $tmp = join("\n",@header);
    print $handle "$tmp\n";
    close $handle;
   
    open $handle, '>>', "release.plist";
    my @xml_data = XMLout($data);
    print $handle @xml_data;
    close $handle;
   
    
    #Update releng/release_info.csv  with released version 
    my $file = '/var/tmp/release_info.csv';
    my @csv_data;
    open(my $fh, '<', $file) or die "Can't read file '$file' [$!]\n";
    while (my $line = <$fh>) {
        $line =~ s/$release\,.*/$release,$major.$minor/;
        push @csv_data, $line;
    }
    print @csv_data;
    open $handle, '>', "release_info.csv";
    print $handle @csv_data;

    # Upload updated files -- release.plist releng/release_info.csv
    # I had difficulty uploading new file versions.  I'll use git client to upadte the reop
    if (0) {
    $cmd="curl -d {\"message\": \"Release Version update\", \"content\": \"@csv_data\"} --header 'Authorization: token $token'  --location $_/$branch/contents/release.plist 2>/dev/null";
    print "\n$cmd\n";
    system($cmd);
    $cmd="curl --header 'Authorization: token $token'  --header 'Accept: application/vnd.github.v3.raw'  --remote-name  --location $rawsite/$branch/releng/release_info.csv  2>/dev/null";
    print "\n$cmd\n";
    system($cmd);
    }

    # Update using Git client
    $cmd="mv -f release_info.csv releng/release_info.csv";
    system($cmd);
    $cmd="git add release.plist  releng/release_info.csv";
    system($cmd);
    $cmd="git commit -m \"New release version updates\"";
    system($cmd);
    $cmd="git fetch";
    system($cmd);
    $cmd="git pull origin $branch";
    system($cmd);
    $cmd="git push origin $branch";
    system($cmd);
   }

